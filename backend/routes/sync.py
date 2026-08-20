"""Mobile-only sync endpoints for MediHive Marathi.

Consolidated sync module with clinic_id isolation,
incremental upload/download, and disaster recovery.
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.patient import Patient
from models.opd_record import OPDRecord
from models.appointment import Appointment
from models.deleted_entity import DeletedEntity
from models.clinic import Clinic
from models.device_registry import DeviceRegistry
import os
import tempfile
from database import get_db
from datetime import datetime, timezone
from pathlib import Path
from config import IMAGE_STORAGE_PATH, IS_CLOUD
from services.log_service import get_logger
from routes.opd import save_images_locally, build_sheet_row_data, _ImageRecord

logger = get_logger(__name__)

sync_bp = Blueprint('sync', __name__)


def _parse_ts(value):
    """Parse an ISO-8601 timestamp into a naive UTC datetime.

    Naive values (no timezone info) are treated as UTC, matching how the
    server stores timestamps. Returns None for unparseable/empty input.
    """
    if not value:
        return None
    try:
        dt = datetime.fromisoformat(str(value).replace('Z', '+00:00'))
    except (ValueError, TypeError):
        return None
    if dt.tzinfo is not None:
        dt = dt.astimezone(timezone.utc).replace(tzinfo=None)
    return dt


def _norm_utc(value):
    """Normalize a timestamp to a naive UTC ISO-8601 string, or None."""
    dt = _parse_ts(value)
    return dt.isoformat() if dt else None


def _remote_newer_or_equal(remote_updated, local_updated):
    """Last-write-wins comparison (timezone-safe).

    Returns True when the remote record may be written (remote is newer than
    or equal to local). Missing timestamps are treated as 'older'; when both
    are missing the remote wins so data is never silently dropped.
    """
    if not remote_updated:
        return not local_updated
    remote_dt = _parse_ts(remote_updated)
    if remote_dt is None:
        return not local_updated
    if not local_updated:
        return True
    local_dt = _parse_ts(local_updated)
    return local_dt is None or remote_dt >= local_dt


def _get_user_clinic_id(user_id):
    with get_db() as db:
        user = db.execute(
            "SELECT clinic_id FROM users WHERE id = %s", (user_id,)
        ).fetchone()
    return user['clinic_id'] if user and user['clinic_id'] else None


def _sync_opd_to_sheets(opd, image_links=None):
    opd_id = opd.get('id', 'UNKNOWN')
    patient_id = opd.get('patient_id', 'UNKNOWN')
    logger.info(
        "SHEET SYNC START: OPD=%s patient_id=%s has_images=%s",
        opd_id, patient_id, bool(image_links),
    )

    patient = Patient.get(patient_id)
    if not patient:
        logger.warning(
            "Patient %s not found in PostgreSQL, creating placeholder for sheet sync for OPD %s",
            patient_id, opd_id,
        )
        now = datetime.utcnow().isoformat()
        clinic_id = opd.get('clinic_id', '')
        with get_db() as db:
            db.execute("""
                INSERT INTO patients
                    (id, full_name, mobile_number, gender, created_at, updated_at, clinic_id)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT DO NOTHING
            """, (
                patient_id, 'Unknown (Auto-created)',
                '', 'Not Specified', now, now, clinic_id,
            ))
            db.commit()
        patient = Patient.get(patient_id)
        if not patient:
            logger.error(
                "Could not create placeholder patient %s for OPD %s",
                patient_id, opd_id,
            )
            patient = {
                'id': patient_id,
                'name': 'Unknown',
                'mobile': '',
                'gender': 'Not Specified',
                'dob': '',
                'age': 0,
                'blood_group': '',
                'address': '',
            }

    row_data = build_sheet_row_data(opd, patient, image_links or [])
    try:
        from sheets_utils import upsert_opd_row_in_sheet
        upsert_opd_row_in_sheet(opd_id, row_data)
        logger.info("SHEET SYNC END: OPD=%s", opd_id)
        return None
    except RuntimeError as e:
        logger.warning("Sheet sync skipped for OPD %s: %s", opd_id, e)
        return f"Sheet sync skipped: {e}"
    except Exception as e:
        logger.warning("Sheet sync error for OPD %s: %s", opd_id, e)
        return f"Sheet sync error: {e}"


def _format_patient(p):
    if not p:
        return p
    res = dict(p)
    if 'full_name' in res:
        res['name'] = res['full_name']
    if 'mobile_number' in res:
        res['mobile'] = res['mobile_number']
    return res


def _format_opd(r):
    if not r:
        return r
    res = dict(r)
    if 'opd_type' in res:
        res['type'] = res['opd_type']
    if 'visit_datetime' in res:
        res['visit_date'] = res['visit_datetime']
    if 'discount_value' in res:
        res['discount'] = str(res['discount_value'])
    if 'next_visit_date' in res:
        res['next_visit'] = res['next_visit_date']
        res['previous_visit_date'] = res['next_visit_date']
    if 'followup_status' in res:
        res['follow_up_reason'] = res['followup_status']
    return res


_CLINIC_SETTINGS_FIELDS = [
    'doctor_name', 'doctor_email', 'doctor_contact', 'doctor_license_no',
    'doctor_photo_path', 'clinic_name', 'clinic_logo_path', 'clinic_address',
    'clinic_phone', 'website', 'operating_hours',
]


def _upsert_clinic_settings(clinic_id, payload, now):
    """Upsert the single clinic_settings row for a clinic (last-write-wins).

    Returns (row_dict_or_None, conflict_message_or_None).
    """
    remote_updated = _norm_utc(payload.get('updated_at')) or now
    with get_db() as db:
        row = db.execute(
            "SELECT * FROM clinic_settings WHERE clinic_id = %s ORDER BY id ASC LIMIT 1",
            (clinic_id,),
        ).fetchone()

        fields = {f: payload.get(f, '') or '' for f in _CLINIC_SETTINGS_FIELDS}
        if row is not None:
            local_updated = row.get('updated_at') or row.get('created_at') or ''
            if not _remote_newer_or_equal(remote_updated, local_updated):
                return dict(row), (
                    f"clinic_settings update skipped: local record is newer "
                    f"(local={local_updated}, remote={remote_updated})"
                )
            assignments = ", ".join(f"{k} = %s" for k in fields)
            db.execute(
                f"UPDATE clinic_settings SET {assignments}, updated_at = %s WHERE id = %s",
                (*fields.values(), remote_updated, row['id']),
            )
        else:
            columns = ', '.join(fields.keys())
            placeholders = ', '.join(['%s'] * len(fields))
            db.execute(
                f"INSERT INTO clinic_settings ({columns}, created_at, updated_at, clinic_id) "
                f"VALUES ({placeholders}, %s, %s, %s)",
                (*fields.values(), now, remote_updated, clinic_id),
            )
        db.commit()

        result = db.execute(
            "SELECT * FROM clinic_settings WHERE clinic_id = %s ORDER BY id ASC LIMIT 1",
            (clinic_id,),
        ).fetchone()
    return (dict(result) if result else None), None


def _upsert_calendar_note(clinic_id, user_id, payload, now):
    """Upsert or delete a calendar note for a clinic (last-write-wins).

    Empty / '[]' note_text is treated as a delete.  Returns
    (row_dict_or_None, conflict_message_or_None).
    """
    note_date = (payload.get('note_date') or '').strip()
    if not note_date:
        return None, None

    note_text = payload.get('note_text', '[]')
    with get_db() as db:
        if note_text is None or str(note_text) == '[]' or not str(note_text).strip():
            db.execute(
                "DELETE FROM calendar_notes WHERE note_date = %s AND clinic_id = %s",
                (note_date, clinic_id),
            )
            db.commit()
            DeletedEntity.record('calendar_note', note_date, user_id=user_id, clinic_id=clinic_id)
            return {'note_date': note_date, 'deleted': True}, None

        remote_created = _norm_utc(payload.get('created_at')) or now
        remote_updated = _norm_utc(payload.get('updated_at')) or now
        row = db.execute(
            "SELECT * FROM calendar_notes WHERE note_date = %s AND clinic_id = %s",
            (note_date, clinic_id),
        ).fetchone()
        if row is not None:
            local_updated = row.get('updated_at') or row.get('created_at') or ''
            if not _remote_newer_or_equal(remote_updated, local_updated):
                return dict(row), (
                    f"calendar_note {note_date} update skipped: local record is newer "
                    f"(local={local_updated}, remote={remote_updated})"
                )
            db.execute(
                "UPDATE calendar_notes SET note_text = %s, updated_at = %s WHERE note_date = %s AND clinic_id = %s",
                (str(note_text), remote_updated, note_date, clinic_id),
            )
        else:
            db.execute(
                "INSERT INTO calendar_notes (note_date, note_text, created_at, updated_at, user_id, clinic_id) "
                "VALUES (%s, %s, %s, %s, %s, %s) "
                "ON CONFLICT (note_date) DO UPDATE "
                "SET note_text = EXCLUDED.note_text, updated_at = EXCLUDED.updated_at "
                "WHERE calendar_notes.clinic_id = EXCLUDED.clinic_id",
                (note_date, str(note_text), remote_created, remote_updated, user_id, clinic_id),
            )
        db.commit()

        result = db.execute(
            "SELECT * FROM calendar_notes WHERE note_date = %s AND clinic_id = %s",
            (note_date, clinic_id),
        ).fetchone()
    return (dict(result) if result else {'note_date': note_date, 'deleted': True}), None


def _upsert_master_item(table, name):
    """Ensure a master-list item (medicines / symptoms_master) exists."""
    name = (name or '').strip()
    if not name:
        return None
    with get_db() as db:
        db.execute(
            f"INSERT INTO {table} (name) VALUES (%s) "
            f"ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name",
            (name,),
        )
        db.commit()
    return {'name': name}


def _latest_clinic_settings(clinic_id):
    with get_db() as db:
        row = db.execute(
            "SELECT * FROM clinic_settings WHERE clinic_id = %s ORDER BY id ASC LIMIT 1",
            (clinic_id,),
        ).fetchone()
    return dict(row) if row else None


def _calendar_notes_since(clinic_id, last_sync):
    with get_db() as db:
        rows = db.execute(
            "SELECT * FROM calendar_notes WHERE clinic_id = %s "
            "AND COALESCE(NULLIF(updated_at, ''), created_at) > %s ORDER BY updated_at",
            (clinic_id, last_sync),
        ).fetchall()
    return [dict(r) for r in rows]


def _all_master_items(table):
    with get_db() as db:
        rows = db.execute(f"SELECT name FROM {table} ORDER BY name").fetchall()
    return [dict(r) for r in rows]


# ── Device Registration ─────────────────────────────

@sync_bp.route('/register-device', methods=['POST'])
def register_device():
    data = request.get_json() or {}
    device_id = data.get('device_id', '').strip()
    if not device_id:
        return jsonify({'error': 'device_id is required'}), 400

    device = DeviceRegistry.register({
        'device_id': device_id,
        'device_name': data.get('device_name', ''),
        'clinic_id': data.get('clinic_id', ''),
        'fcm_token': data.get('fcm_token', ''),
        'app_version': data.get('app_version', ''),
    })
    logger.info("Device registered: %s for clinic %s", device_id, data.get('clinic_id', ''))
    return jsonify({'device': device, 'message': 'Device registered'}), 200


@sync_bp.route('/heartbeat', methods=['POST'])
def heartbeat():
    data = request.get_json() or {}
    device_id = data.get('device_id', '')
    if device_id:
        DeviceRegistry.update_heartbeat(device_id)
    return jsonify({'message': 'ok'}), 200


# ── Incremental Sync Upload ──────────────────────────

@sync_bp.route('/upload', methods=['POST'])
@jwt_required()
def sync_upload():
    user_id = get_jwt_identity()
    clinic_id = _get_user_clinic_id(user_id)
    if not clinic_id:
        return jsonify({'error': 'No clinic assigned to this user'}), 403

    data = request.get_json() or {}
    device_id = data.get('device_id', '')
    now = datetime.utcnow().isoformat()

    logger.info(
        "UPLOAD clinic=%s device=%s patients=%d opd_records=%d appointments=%d "
        "settings=%d notes=%d medicines=%d symptoms=%d deleted=%d",
        clinic_id, device_id,
        len(data.get('patients', [])),
        len(data.get('opd_records', [])),
        len(data.get('appointments', [])),
        len(data.get('clinic_settings', [])),
        len(data.get('calendar_notes', [])),
        len(data.get('medicines', [])),
        len(data.get('symptoms', [])),
        len(data.get('deleted_entities', [])),
    )

    results = {
        'patients': [],
        'opd_records': [],
        'appointments': [],
        'clinic_settings': [],
        'calendar_notes': [],
        'medicines': [],
        'symptoms': [],
    }
    sheet_sync_errors = []
    temp_id_map = {}
    conflicts = []
    missing_patients = []
    events_to_enqueue = []

    # ── Patients (last-write-wins) ──
    for p in data.get('patients', []):
        p['clinic_id'] = clinic_id
        p['device_id'] = device_id
        p['sync_status'] = 'synced'
        p['last_synced_at'] = now
        
        # Backward compatibility translation:
        if 'name' in p and 'full_name' not in p:
            p['full_name'] = p['name']
        if 'mobile' in p and 'mobile_number' not in p:
            p['mobile_number'] = p['mobile']

        old_id = p.get('id', '')
        is_temp = old_id.startswith('TEMP_')
        if is_temp:
            p['id'] = Patient.assign_next_id(clinic_id=clinic_id)
            temp_id_map[old_id] = p['id']

        existing = Patient.get(p['id'], clinic_id=clinic_id) or Patient.get(p['id'])
        if existing:
            remote_updated = p.get('updated_at', '')
            local_updated = existing.get('updated_at', '')
            if _remote_newer_or_equal(remote_updated, local_updated):
                # If existing row is under a different clinic, use create (ON
                # CONFLICT) to reassign clinic_id — the clinic-filtered update
                # would silently no-op on 0 rows.
                if existing.get('clinic_id') and existing['clinic_id'] != clinic_id:
                    Patient.create(p)
                else:
                    Patient.update(p['id'], p, clinic_id=clinic_id)
                results['patients'].append(_format_patient(Patient.get(p['id'])))
                events_to_enqueue.append(('patient', p['id'], 'upsert'))
            else:
                results['patients'].append(_format_patient(existing))
                conflicts.append(f"Patient {p['id']} update skipped: local record is newer (local={local_updated}, remote={remote_updated})")
        else:
            Patient.create(p)
            results['patients'].append(_format_patient(Patient.get(p['id'])))
            events_to_enqueue.append(('patient', p['id'], 'upsert'))

    # ── OPD Records (last-write-wins) ──
    for r in data.get('opd_records', []):
        r['clinic_id'] = clinic_id
        r['device_id'] = device_id
        r['sync_status'] = 'synced'
        r['last_synced_at'] = now

        # Backward compatibility translation:
        if 'type' in r and 'opd_type' not in r:
            r['opd_type'] = r['type']
        if 'visit_date' in r and 'visit_datetime' not in r:
            r['visit_datetime'] = r['visit_date']
        if 'discount' in r and 'discount_value' not in r:
            r['discount_value'] = r['discount']
        if 'next_visit' in r and 'next_visit_date' not in r:
            r['next_visit_date'] = r['next_visit']
        if 'follow_up_reason' in r and 'followup_status' not in r:
            r['followup_status'] = r['follow_up_reason']
        if 'opd_id' not in r or not r['opd_id']:
            r['opd_id'] = r['id']

        pat_id = r.get('patient_id', '')
        if pat_id in temp_id_map:
            r['patient_id'] = temp_id_map[pat_id]

        existing = OPDRecord.get(r['id'], clinic_id=clinic_id) or OPDRecord.get(r['id'])
        if existing:
            remote_updated = r.get('updated_at', '')
            local_updated = existing.get('updated_at', '')
            if _remote_newer_or_equal(remote_updated, local_updated):
                # If existing row is under a different clinic, use create (ON
                # CONFLICT) to reassign clinic_id — the clinic-filtered update
                # would silently no-op on 0 rows.
                if existing.get('clinic_id') and existing['clinic_id'] != clinic_id:
                    OPDRecord.create(r)
                else:
                    OPDRecord.update(r['id'], r, clinic_id=clinic_id)
                result = OPDRecord.get(r['id'])
                events_to_enqueue.append(('opd_visit', r['id'], 'upsert'))
            else:
                result = existing
                conflicts.append(f"OPD Visit {r['id']} update skipped: local record is newer (local={local_updated}, remote={remote_updated})")
        else:
            OPDRecord.create(r)
            result = OPDRecord.get(r['id'])
            events_to_enqueue.append(('opd_visit', r['id'], 'upsert'))

        results['opd_records'].append(_format_opd(result))

        # Check if referenced patient exists, if not, queue for self-healing
        pat_id = r.get('patient_id', '')
        if pat_id:
            p_exist = Patient.get(pat_id, clinic_id=clinic_id) or Patient.get(pat_id)
            if not p_exist and pat_id not in missing_patients:
                missing_patients.append(pat_id)

    # ── Appointments (last-write-wins) ──
    for a in data.get('appointments', []):
        a['clinic_id'] = clinic_id
        a['device_id'] = device_id
        a['sync_status'] = 'synced'
        a['last_synced_at'] = now

        # Backward compatibility translation:
        if 'appointment_date' in a and 'date_time' not in a:
            a['date_time'] = a['appointment_date']
        if 'date_time' not in a or not a['date_time']:
            a['date_time'] = now

        pat_id = a.get('patient_id', '')
        if pat_id in temp_id_map:
            a['patient_id'] = temp_id_map[pat_id]

        existing = Appointment.get(a['id'], clinic_id=clinic_id) or Appointment.get(a['id'])
        if existing:
            remote_updated = a.get('updated_at', '')
            local_updated = existing.get('updated_at', '')
            if _remote_newer_or_equal(remote_updated, local_updated):
                # If existing row is under a different clinic, use create (ON
                # CONFLICT) to reassign clinic_id — the clinic-filtered update
                # would silently no-op on 0 rows.
                if existing.get('clinic_id') and existing['clinic_id'] != clinic_id:
                    Appointment.create(a)
                else:
                    Appointment.update(a['id'], a, clinic_id=clinic_id)
                results['appointments'].append(Appointment.get(a['id']))
                events_to_enqueue.append(('appointment', a['id'], 'upsert'))
            else:
                results['appointments'].append(existing)
                conflicts.append(f"Appointment {a['id']} update skipped: local record is newer (local={local_updated}, remote={remote_updated})")
        else:
            Appointment.create(a)
            results['appointments'].append(Appointment.get(a['id']))
            events_to_enqueue.append(('appointment', a['id'], 'upsert'))

        # Check if referenced patient exists, if not, queue for self-healing
        pat_id = a.get('patient_id', '')
        if pat_id:
            p_exist = Patient.get(pat_id, clinic_id=clinic_id) or Patient.get(pat_id)
            if not p_exist and pat_id not in missing_patients:
                missing_patients.append(pat_id)

    # ── Deleted Entities ──
    for entry in data.get('deleted_entities', []):
        etype = entry.get('entity_type')
        eid = entry.get('entity_id')
        try:
            if etype == 'patient':
                Patient.delete(eid, clinic_id=clinic_id)
                events_to_enqueue.append((etype, eid, 'delete'))
            elif etype == 'opd_visit':
                OPDRecord.delete(eid, clinic_id=clinic_id)
                events_to_enqueue.append((etype, eid, 'delete'))
            elif etype == 'appointment':
                Appointment.delete(eid, clinic_id=clinic_id)
                events_to_enqueue.append((etype, eid, 'delete'))
        except Exception as exc:
            logger.warning("Delete sync failed for %s %s: %s", etype, eid, exc)

    # ── Clinic Settings (single row per clinic, last-write-wins) ──
    for s in data.get('clinic_settings', []):
        s['clinic_id'] = clinic_id
        result, conflict = _upsert_clinic_settings(clinic_id, s, now)
        if result:
            results['clinic_settings'].append(result)
        if conflict:
            conflicts.append(conflict)

    # ── Calendar Notes (per-date, last-write-wins; empty text = delete) ──
    for n in data.get('calendar_notes', []):
        result, conflict = _upsert_calendar_note(clinic_id, user_id, n, now)
        if conflict:
            conflicts.append(conflict)
        if result is not None:
            results['calendar_notes'].append(result)

    # ── Medicines & Symptoms Master Lists (global, dedup by name) ──
    for m in data.get('medicines', []):
        item = _upsert_master_item('medicines', m.get('name'))
        if item:
            results['medicines'].append(item)
    for sym in data.get('symptoms', []):
        item = _upsert_master_item('symptoms_master', sym.get('name'))
        if item:
            results['symptoms'].append(item)

    # ── Write sync log to cloud_sync_log ──
    try:
        with get_db() as db:
            status_val = 'conflict' if conflicts else 'success'
            err_msg = "; ".join(conflicts) if conflicts else ''
            db.execute("""
                INSERT INTO cloud_sync_log 
                    (clinic_id, device_id, direction, patients_count, opd_count, 
                     appointments_count, deleted_count, status, error_message, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                clinic_id, device_id, 'upload',
                len(data.get('patients', [])),
                len(data.get('opd_records', [])),
                len(data.get('appointments', [])),
                len(data.get('deleted_entities', [])),
                status_val, err_msg, now
            ))
            db.commit()
    except Exception as e:
        logger.error("Failed to write cloud_sync_log: %s", e)

    # ── Enqueue Sync Events to sync_queue for Background Worker ──
    from services.sync_worker import enqueue_sync_event
    for etype, eid, op in events_to_enqueue:
        try:
            enqueue_sync_event(etype, eid, operation=op, clinic_id=clinic_id, origin_device_id=device_id)
        except Exception as e:
            logger.error("Failed to enqueue event (%s, %s, %s): %s", etype, eid, op, e)

    response = {
        'results': results,
        'server_time': now,
        'clinic_id': clinic_id,
    }
    if temp_id_map:
        response['temp_ids_mapped'] = temp_id_map
    if sheet_sync_errors:
        response['sheet_sync_errors'] = sheet_sync_errors
    if conflicts:
        response['conflicts'] = conflicts
    if missing_patients:
        response['missing_patients'] = missing_patients

    return jsonify(response), 200


# ── Incremental Sync Download ────────────────────────

@sync_bp.route('/download', methods=['POST'])
@jwt_required()
def sync_download():
    user_id = get_jwt_identity()
    clinic_id = _get_user_clinic_id(user_id)
    if not clinic_id:
        return jsonify({'error': 'No clinic assigned to this user'}), 403

    data = request.get_json() or {}
    last_sync = data.get('last_sync', '2000-01-01T00:00:00')

    patients = Patient.updated_since(last_sync, clinic_id=clinic_id)
    opd_records = OPDRecord.updated_since(last_sync, clinic_id=clinic_id)
    appointments = Appointment.updated_since(last_sync, clinic_id=clinic_id)
    deleted_entities = DeletedEntity.since(last_sync, clinic_id=clinic_id)

    formatted_patients = [_format_patient(p) for p in patients]
    formatted_opd = [_format_opd(o) for o in opd_records]

    clinic_settings = _latest_clinic_settings(clinic_id)
    calendar_notes = _calendar_notes_since(clinic_id, last_sync)
    medicines = _all_master_items('medicines')
    symptoms = _all_master_items('symptoms_master')

    logger.info(
        "DOWNLOAD clinic=%s since=%s patients=%d opd=%d appts=%d settings=%s notes=%d medicines=%d symptoms=%d deleted=%d",
        clinic_id, last_sync,
        len(formatted_patients), len(formatted_opd),
        len(appointments),
        'present' if clinic_settings else 'none',
        len(calendar_notes), len(medicines), len(symptoms),
        len(deleted_entities),
    )

    return jsonify({
        'patients': formatted_patients,
        'opd_records': formatted_opd,
        'appointments': appointments,
        'clinic_settings': [clinic_settings] if clinic_settings else [],
        'calendar_notes': calendar_notes,
        'medicines': medicines,
        'symptoms': symptoms,
        'deleted_entities': deleted_entities,
        'server_time': datetime.utcnow().isoformat(),
    }), 200


# ── Disaster Recovery: Full Restore ──────────────────

@sync_bp.route('/full-restore', methods=['GET'])
@jwt_required()
def full_restore():
    user_id = get_jwt_identity()
    clinic_id = _get_user_clinic_id(user_id)
    if not clinic_id:
        return jsonify({'error': 'No clinic assigned to this user'}), 403

    patients = Patient.full_restore(clinic_id)
    opd_records = OPDRecord.full_restore(clinic_id)
    appointments = Appointment.full_restore(clinic_id)

    formatted_patients = [_format_patient(p) for p in patients]
    formatted_opd = [_format_opd(o) for o in opd_records]

    with get_db() as db:
        deleted_entities_rows = db.execute(
            "SELECT entity_type, entity_id, deleted_at FROM deleted_entities "
            "WHERE clinic_id = %s ORDER BY deleted_at",
            (clinic_id,)
        ).fetchall()
    deleted_entities = [dict(r) for r in deleted_entities_rows]

    clinic = Clinic.get(clinic_id)

    clinic_settings = _latest_clinic_settings(clinic_id)
    calendar_notes = _calendar_notes_since(clinic_id, '2000-01-01T00:00:00')
    medicines = _all_master_items('medicines')
    symptoms = _all_master_items('symptoms_master')

    return jsonify({
        'clinic': clinic,
        'patients': formatted_patients,
        'opd_records': formatted_opd,
        'appointments': appointments,
        'clinic_settings': [clinic_settings] if clinic_settings else [],
        'calendar_notes': calendar_notes,
        'medicines': medicines,
        'symptoms': symptoms,
        'deleted_entities': deleted_entities,
        'server_time': datetime.utcnow().isoformat(),
    }), 200


# ── Mobile Sync: Upload Images ──────────────────────

@sync_bp.route('/upload-images/<opd_id>', methods=['POST'])
@jwt_required()
def sync_upload_images(opd_id):
    user_id = get_jwt_identity()
    clinic_id = _get_user_clinic_id(user_id)

    logger.info("=== IMAGE UPLOAD START === OPD=%s clinic=%s", opd_id, clinic_id)

    opd = OPDRecord.get(opd_id, clinic_id=clinic_id) if clinic_id else OPDRecord.get(opd_id)
    if opd is None:
        logger.warning("OPD record not found: %s", opd_id)
        return jsonify({'error': 'OPD record not found'}), 404

    if 'images' not in request.files:
        logger.warning("No 'images' field in request for OPD %s", opd_id)
        return jsonify({'error': 'No image files provided'}), 400

    files = request.files.getlist('images')
    files = [f for f in files if f.filename]

    if not files:
        logger.warning("No valid image files for OPD %s", opd_id)
        return jsonify({'error': 'No valid image files provided'}), 400

    drive_urls = []
    direct_upload_success = False

    # 1. Attempt direct upload to Google Drive
    try:
        from drive_utils import upload_image_fileobj_to_drive
        for i, f in enumerate(files, 1):
            url = upload_image_fileobj_to_drive(opd_id, f, i)
            if url:
                drive_urls.append(url)

        if drive_urls:
            direct_upload_success = True
            urls_text = "\n".join(drive_urls)
            OPDRecord.set_image_links(opd_id, urls_text, clinic_id=clinic_id)
            logger.info("Direct Drive upload success for OPD %s: %s", opd_id, drive_urls)

            # 2. Immediately update Google Sheet with new Image Links
            try:
                from sheets_utils import upsert_opd_row_in_sheet
                updated_opd = OPDRecord.get(opd_id, clinic_id=clinic_id) or opd
                pat_id = updated_opd.get('patient_id')
                patient = (Patient.get(pat_id, clinic_id=clinic_id) or Patient.get(pat_id)) if pat_id else {}
                row_data = build_sheet_row_data(updated_opd, patient or {}, drive_urls)
                upsert_opd_row_in_sheet(opd_id, row_data)
                logger.info("Google Sheet row updated with Drive image links for OPD %s", opd_id)
            except Exception as se:
                logger.warning("Failed to update Google Sheet directly for OPD %s: %s", opd_id, se)
    except Exception as e:
        logger.warning("Direct Google Drive upload failed for OPD %s (%s). Falling back to background queue.", opd_id, e)

    # 3. Fallback: Save to temp directory and enqueue background sync worker if direct upload failed
    if not direct_upload_success:
        import tempfile
        import shutil

        local_upload_dir = os.path.join(tempfile.gettempdir(), f"medihive_uploads_{opd_id}")
        if os.path.exists(local_upload_dir):
            try:
                shutil.rmtree(local_upload_dir)
            except Exception:
                pass
        os.makedirs(local_upload_dir, exist_ok=True)

        for i, f in enumerate(files, 1):
            f.seek(0)
            filename = f.filename or f"image_{i}.jpg"
            safe_filename = "".join(c for c in filename if c.isalnum() or c in "._-")
            filepath = os.path.join(local_upload_dir, f"{i:02d}_{safe_filename}")
            f.save(filepath)

        device_id = request.headers.get('X-Device-ID') or request.form.get('device_id')
        from services.sync_worker import enqueue_sync_event
        enqueue_sync_event('opd_visit', opd_id, operation='upload_images', clinic_id=clinic_id, origin_device_id=device_id)

        logger.info("Saved %d image(s) to temp directory for fallback background sync: OPD=%s", len(files), opd_id)

    response = {
        'opd_id': opd_id,
        'image_count': len(drive_urls) if direct_upload_success else len(files),
        'drive_urls': drive_urls,
        'images_uploaded': direct_upload_success,
        'message': 'Images uploaded to Google Drive and Google Sheet updated' if direct_upload_success else 'Images queued for background sync'
    }
    return jsonify(response), 200


# ── Clinic Info ─────────────────────────────────────

@sync_bp.route('/clinic-info', methods=['GET'])
@jwt_required()
def clinic_info():
    user_id = get_jwt_identity()
    with get_db() as db:
        user = db.execute(
            "SELECT clinic_id FROM users WHERE id = %s", (user_id,)
        ).fetchone()

    if user and user['clinic_id']:
        clinic = Clinic.get(user['clinic_id'])
        if clinic:
            return jsonify({'clinic': clinic}), 200
        return jsonify({'error': 'Clinic not found'}), 404

    return jsonify({'error': 'No clinic assigned to this user'}), 404


# ── One-Way Google Sheets Export ────────────────────

@sync_bp.route('/export-sheets', methods=['POST'])
@jwt_required()
def export_sheets():
    user_id = get_jwt_identity()
    clinic_id = _get_user_clinic_id(user_id)
    if not clinic_id:
        return jsonify({'error': 'No clinic assigned to this user'}), 403

    logger.info("SHEET EXPORT: starting bulk export for clinic %s", clinic_id)
    
    # Run in a background thread to return immediately
    import threading
    threading.Thread(target=_run_bulk_sheets_export, args=(clinic_id,)).start()
    
    return jsonify({'message': 'Bulk Google Sheets export started in background'}), 202


def _run_bulk_sheets_export(clinic_id):
    try:
        from models.opd_record import OPDRecord
        records = OPDRecord.full_restore(clinic_id)
        logger.info("SHEET EXPORT: found %d records to export", len(records))
        
        success_count = 0
        error_count = 0
        
        for r in records:
            formatted = _format_opd(r)
            err = _sync_opd_to_sheets(formatted)
            if err:
                logger.error("SHEET EXPORT ERROR for OPD %s: %s", r.get('id'), err)
                error_count += 1
            else:
                success_count += 1
                
        logger.info("SHEET EXPORT COMPLETE: successfully exported %d/%d records (%d errors)", 
                    success_count, len(records), error_count)
    except Exception as e:
        logger.error("SHEET EXPORT CRITICAL FAILED: %s", e)
