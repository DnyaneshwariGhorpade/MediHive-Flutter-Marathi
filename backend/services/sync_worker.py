import os
import io
import json
import time
import logging
import tempfile
import threading
import shutil
from datetime import datetime

from database import get_db, close_thread_connections
from models.patient import Patient
from models.opd_record import OPDRecord
from models.appointment import Appointment
from services.log_service import get_logger

logger = get_logger(__name__)

_worker_thread = None
_running = False


class LocalFileWrapper:
    """Wrapper to make local files behave like Flask FileStorage for drive_utils."""
    def __init__(self, filepath, filename, content_type='image/jpeg'):
        self.filepath = filepath
        self.filename = filename
        self.content_type = content_type

    def read(self):
        with open(self.filepath, 'rb') as f:
            return f.read()


def enqueue_sync_event(entity_type, entity_id, operation='upsert', clinic_id='', origin_device_id=None):
    """Enqueue an event to PostgreSQL sync_queue."""
    now = datetime.utcnow().isoformat()
    last_attempt = f"origin_device_id:{origin_device_id}" if origin_device_id else None
    
    # Initialize task state as pending
    initial_state = {
        "device_notify": "pending",
        "sheets_update": "pending",
        "drive_update": "pending"
    }
    
    with get_db() as db:
        db.execute("""
            INSERT INTO sync_queue 
                (entity_type, entity_id, operation, status, retry_count, last_error, created_at, last_attempt, clinic_id)
            VALUES (%s, %s, %s, 'pending', 0, %s, %s, %s, %s)
        """, (entity_type, entity_id, operation, json.dumps(initial_state), now, last_attempt, clinic_id))
        db.commit()
    logger.info("Enqueued sync event: entity_type=%s entity_id=%s operation=%s clinic_id=%s",
                entity_type, entity_id, operation, clinic_id)


class SyncWorkerThread(threading.Thread):
    def __init__(self):
        super().__init__(name="SyncWorkerThread", daemon=True)
        self.stop_event = threading.Event()

    def stop(self):
        self.stop_event.set()

    def run(self):
        logger.info("Sync background worker thread started.")
        while not self.stop_event.is_set():
            try:
                self.process_next_event()
            except Exception as e:
                logger.exception("Error in sync worker iteration: %s", e)
            finally:
                # Return any DB connections the iteration opened but did not
                # close (e.g. exception paths). Prevents pool exhaustion in
                # the long-running worker thread.
                close_thread_connections()
            # Poll every 5 seconds
            self.stop_event.wait(5.0)
        logger.info("Sync background worker thread stopped.")

    def process_next_event(self):
        db = get_db()
        # Fetch next pending event using FOR UPDATE SKIP LOCKED
        # Supports exponential backoff (retry after 15 * 2^retry_count seconds)
        row = db.execute("""
            SELECT id, entity_type, entity_id, operation, clinic_id, retry_count, last_error, last_attempt, created_at
            FROM sync_queue
            WHERE status = 'pending'
              AND (
                retry_count = 0 
                OR last_attempt IS NULL 
                OR last_attempt LIKE 'origin_device_id:%%'
                OR (
                    CASE 
                        WHEN last_attempt NOT LIKE 'origin_device_id:%%' 
                        THEN EXTRACT(EPOCH FROM timezone('utc', now())) - EXTRACT(EPOCH FROM last_attempt::timestamp)
                        ELSE 999999
                    END
                ) > POWER(2, retry_count) * 15
              )
            ORDER BY id ASC
            LIMIT 1
            FOR UPDATE SKIP LOCKED
        """).fetchone()

        if not row:
            db.close()
            return

        queue_id = row['id']
        entity_type = row['entity_type']
        entity_id = row['entity_id']
        operation = row['operation']
        clinic_id = row['clinic_id']
        retry_count = row['retry_count'] or 0
        last_error = row['last_error'] or ''
        last_attempt = row['last_attempt'] or ''

        # Mark as processing
        db.execute("""
            UPDATE sync_queue 
            SET status = 'processing', last_attempt = %s 
            WHERE id = %s
        """, (datetime.utcnow().isoformat(), queue_id))
        db.commit()
        db.close()

        logger.info("Processing sync event %d: type=%s, id=%s, op=%s", queue_id, entity_type, entity_id, operation)

        # Parse origin_device_id if present
        origin_device_id = None
        if last_attempt and last_attempt.startswith("origin_device_id:"):
            origin_device_id = last_attempt.replace("origin_device_id:", "")

        # Parse sub-task state
        try:
            state = json.loads(last_error) if last_error.startswith("{") else {}
        except Exception:
            state = {}

        if not state or not isinstance(state, dict):
            state = {
                "device_notify": "pending",
                "sheets_update": "pending",
                "drive_update": "pending"
            }

        # Check if local image uploads exist for this OPD record
        local_upload_dir = os.path.join(tempfile.gettempdir(), f"medihive_uploads_{entity_id}")
        has_local_images = False
        image_files = []
        if entity_type == 'opd_visit' and os.path.exists(local_upload_dir):
            image_files = [
                os.path.join(local_upload_dir, f) 
                for f in os.listdir(local_upload_dir) 
                if os.path.isfile(os.path.join(local_upload_dir, f))
            ]
            if image_files:
                has_local_images = True

        if not has_local_images:
            state["drive_update"] = "skipped"

        # Execute Handlers
        # 1. Drive update (must happen before Sheets update so URLs are ready)
        drive_urls = []
        if state.get("drive_update") == "pending":
            try:
                logger.info("SyncWorker: Uploading images to Google Drive for OPD %s", entity_id)
                from drive_utils import upload_image_fileobj_to_drive
                for i, filepath in enumerate(image_files, 1):
                    filename = os.path.basename(filepath)
                    wrapper = LocalFileWrapper(filepath, filename)
                    url = upload_image_fileobj_to_drive(entity_id, wrapper, i)
                    if url:
                        drive_urls.append(url)
                
                if drive_urls:
                    urls_text = "\n".join(drive_urls)
                    OPDRecord.set_image_links(entity_id, urls_text, clinic_id=clinic_id)
                    logger.info("SyncWorker: Successfully uploaded images and saved links: %s", urls_text)
                    state["drive_update"] = "success"
                    
                    # Clean up local temporary files
                    try:
                        shutil.rmtree(local_upload_dir)
                    except Exception as ex:
                        logger.warning("SyncWorker: Failed to clean up temp files for OPD %s: %s", entity_id, ex)
                else:
                    state["drive_update"] = "failed: No Drive URLs generated"
            except Exception as e:
                logger.exception("SyncWorker: Drive upload failed for OPD %s", entity_id)
                state["drive_update"] = f"failed: {e}"

        # 2. Sheets update
        if state.get("sheets_update") == "pending":
            try:
                from routes.opd import build_sheet_row_data
                from sheets_utils import upsert_opd_row_in_sheet, _get_client, _get_opd_worksheet, _fmt
                
                if entity_type == 'opd_visit':
                    logger.info("SyncWorker: Upserting OPD record %s in Sheets", entity_id)
                    opd = OPDRecord.get(entity_id, clinic_id=clinic_id)
                    if opd:
                        patient = Patient.get(opd.get('patient_id'), clinic_id=clinic_id) or {}
                        row_data = build_sheet_row_data(opd, patient, drive_urls)
                        upsert_opd_row_in_sheet(entity_id, row_data)
                        state["sheets_update"] = "success"
                    else:
                        logger.warning("SyncWorker: OPD record %s not found in DB, skipping sheets update", entity_id)
                        state["sheets_update"] = "skipped"

                elif entity_type == 'patient':
                    logger.info("SyncWorker: Propagating patient %s updates to Sheets", entity_id)
                    patient = Patient.get(entity_id, clinic_id=clinic_id)
                    if patient:
                        db = get_db()
                        opd_rows = db.execute(
                            "SELECT id FROM opd_visits WHERE patient_id = %s AND clinic_id = %s",
                            (entity_id, clinic_id)
                        ).fetchall()
                        db.close()
                        opd_ids = {r['id'] for r in opd_rows}

                        client = _get_client()
                        ws = _get_opd_worksheet(client)
                        records = ws.get_all_values()
                        updated_rows = 0
                        for i, existing_row in enumerate(records):
                            if i == 0:
                                continue
                            row_opd_id = existing_row[0] if len(existing_row) > 0 else ''
                            row_patient_id = existing_row[1] if len(existing_row) > 1 else ''
                            if row_patient_id == entity_id or (row_opd_id and row_opd_id in opd_ids):
                                sheet_row = i + 1
                                ws.update(
                                    range_name=f"B{sheet_row}:J{sheet_row}",
                                    values=[[
                                        entity_id,
                                        _fmt(patient.get('full_name') or patient.get('name', '')),
                                        _fmt(patient.get('mobile_number') or patient.get('mobile', '')),
                                        _fmt(patient.get('gender', '')),
                                        _fmt(patient.get('dob', '')),
                                        _fmt(patient.get('age', 0)),
                                        _fmt(patient.get('weight')),
                                        _fmt(patient.get('blood_group', '')),
                                        _fmt(patient.get('address', ''))
                                    ]]
                                )
                                updated_rows += 1
                        logger.info("SyncWorker: Updated patient details in %d sheets rows", updated_rows)
                        state["sheets_update"] = "success"
                    else:
                        state["sheets_update"] = "skipped"

                elif entity_type == 'appointment':
                    logger.info("SyncWorker: Propagating appointment %s updates to Sheets", entity_id)
                    appt = Appointment.get(entity_id, clinic_id=clinic_id)
                    if appt:
                        patient_id = appt.get('patient_id')
                        db = get_db()
                        # Find latest OPD visit for this patient
                        latest_opd = db.execute("""
                            SELECT id FROM opd_visits 
                            WHERE patient_id = %s AND clinic_id = %s 
                            ORDER BY visit_datetime DESC, id DESC 
                            LIMIT 1
                        """, (patient_id, clinic_id)).fetchone()
                        db.close()
                        
                        if latest_opd:
                            opd_id = latest_opd['id']
                            client = _get_client()
                            ws = _get_opd_worksheet(client)
                            col_a = ws.col_values(1)
                            for i, row_id in enumerate(col_a):
                                if i == 0:
                                    continue
                                if row_id == opd_id:
                                    sheet_row = i + 1
                                    next_visit_date = appt.get('date_time', '')
                                    follow_up_status = appt.get('notes', '') or 'Scheduled'
                                    ws.update(
                                        range_name=f"Z{sheet_row}:AA{sheet_row}",
                                        values=[[
                                            _fmt(next_visit_date),
                                            _fmt(follow_up_status)
                                        ]]
                                    )
                                    logger.info("SyncWorker: Updated appointment details in row %d", sheet_row)
                                    break
                        state["sheets_update"] = "success"
                    else:
                        state["sheets_update"] = "skipped"
            except Exception as e:
                logger.exception("SyncWorker: Sheets update failed for entity %s", entity_id)
                state["sheets_update"] = f"failed: {e}"

        # 3. Device notify
        if state.get("device_notify") == "pending":
            try:
                from models.device_registry import DeviceRegistry
                from services.fcm_service import send_silent_push_notification
                
                devices = DeviceRegistry.get_notifiable(clinic_id)
                other_devices = [d for d in devices if d and d.get('device_id') != origin_device_id]
                logger.info("SyncWorker: Sending silent push to other devices count: %d", len(other_devices))
                
                fcm_errors = []
                sent_count = 0
                for d in other_devices:
                    token = d.get('fcm_token')
                    dest_device_id = d.get('device_id')
                    if token:
                        success = send_silent_push_notification(
                            token=token,
                            data={
                                "type": "sync_trigger",
                                "origin_device_id": origin_device_id or ""
                            }
                        )
                        if success:
                            sent_count += 1
                        else:
                            fcm_errors.append(f"Failed to send to {dest_device_id}")
                
                if fcm_errors:
                    state["device_notify"] = f"failed: {'; '.join(fcm_errors)}"
                else:
                    state["device_notify"] = "success"
            except Exception as e:
                logger.exception("SyncWorker: Device notification failed")
                state["device_notify"] = f"failed: {e}"

        # Final Status Resolution
        any_failed = any(
            isinstance(v, str) and v.startswith("failed") 
            for v in state.values()
        )
        
        db = get_db()
        if not any_failed:
            # Everything succeeded or skipped
            db.execute("UPDATE sync_queue SET status = 'success', last_error = %s WHERE id = %s",
                       (json.dumps(state), queue_id))
            logger.info("SyncWorker: Event %d completed successfully.", queue_id)
        else:
            # Something failed, decide retry vs manual review
            new_retry_count = retry_count + 1
            if new_retry_count >= 5:
                db.execute("UPDATE sync_queue SET status = 'failed', retry_count = %s, last_error = %s WHERE id = %s",
                           (new_retry_count, json.dumps(state), queue_id))
                logger.error("SyncWorker: Event %d failed permanently after max retries.", queue_id)
            else:
                db.execute("UPDATE sync_queue SET status = 'pending', retry_count = %s, last_error = %s WHERE id = %s",
                           (new_retry_count, json.dumps(state), queue_id))
                logger.warning("SyncWorker: Event %d failed and will be retried (attempt %d).", queue_id, new_retry_count)
        
        db.commit()
        
        # Log to cloud_sync_log
        try:
            db.execute("""
                INSERT INTO cloud_sync_log 
                    (clinic_id, device_id, direction, patients_count, opd_count, 
                     appointments_count, deleted_count, status, error_message, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                clinic_id, origin_device_id or 'backend', 'background_fanout',
                1 if entity_type == 'patient' else 0,
                1 if entity_type == 'opd_visit' else 0,
                1 if entity_type == 'appointment' else 0,
                1 if operation == 'delete' else 0,
                'success' if not any_failed else 'failed',
                json.dumps(state), datetime.utcnow().isoformat()
            ))
            db.commit()
        except Exception as le:
            logger.error("SyncWorker: Failed to write to cloud_sync_log: %s", le)
            
        db.close()


def start_worker():
    global _worker_thread, _running
    if _running:
        return
    _running = True
    _worker_thread = SyncWorkerThread()
    _worker_thread.start()
    logger.info("Background sync worker daemon started.")


def stop_worker():
    global _worker_thread, _running
    if not _running:
        return
    _running = False
    if _worker_thread:
        _worker_thread.stop()
        _worker_thread.join()
    logger.info("Background sync worker daemon stopped.")
