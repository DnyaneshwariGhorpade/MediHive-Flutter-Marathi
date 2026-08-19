from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.opd_record import OPDRecord
from models.patient import Patient
from database import get_db
from datetime import datetime
from pathlib import Path
from config import IMAGE_STORAGE_PATH, GOOGLE_SHEET_ID, IS_CLOUD
from drive_utils import upload_images_to_drive, upload_image_fileobj_to_drive
from sheets_utils import upsert_opd_row_in_sheet, _get_client, _get_opd_worksheet
from services.log_service import get_logger

logger = get_logger(__name__)

opd_bp = Blueprint('opd', __name__)


def _get_clinic_id(user_id):
    with get_db() as db:
        user = db.execute(
            "SELECT clinic_id FROM users WHERE id = %s", (user_id,)
        ).fetchone()
    return user['clinic_id'] if user and user['clinic_id'] else None


@opd_bp.route('', methods=['GET'])
@jwt_required()
def list_opd():
    user_id = get_jwt_identity()
    clinic_id = _get_clinic_id(user_id)
    patient_id = request.args.get('patient_id')
    records = OPDRecord.all(patient_id=patient_id, clinic_id=clinic_id)
    return jsonify({'records': records}), 200


@opd_bp.route('/<record_id>', methods=['GET'])
@jwt_required()
def get_opd(record_id):
    user_id = get_jwt_identity()
    clinic_id = _get_clinic_id(user_id)
    record = OPDRecord.get(record_id, clinic_id=clinic_id)
    if record is None:
        return jsonify({'error': 'Record not found'}), 404
    return jsonify({'record': record}), 200


@opd_bp.route('', methods=['POST'])
@jwt_required()
def create_opd():
    user_id = get_jwt_identity()
    clinic_id = _get_clinic_id(user_id)
    data = request.get_json()
    if not data or not data.get('id') or not data.get('patient_id'):
        return jsonify({'error': 'id and patient_id required'}), 400

    data['clinic_id'] = clinic_id
    data['user_id'] = user_id
    record = OPDRecord.create(data)

    patient = Patient.get(data['patient_id'], clinic_id=clinic_id)
    return jsonify({'record': record}), 201


@opd_bp.route('/<record_id>', methods=['PUT'])
@jwt_required()
def update_opd(record_id):
    user_id = get_jwt_identity()
    clinic_id = _get_clinic_id(user_id)
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body required'}), 400
    record = OPDRecord.update(record_id, data, clinic_id=clinic_id)
    if record is None:
        return jsonify({'error': 'Record not found'}), 404
    return jsonify({'record': record}), 200


@opd_bp.route('/<record_id>', methods=['DELETE'])
@jwt_required()
def delete_opd(record_id):
    user_id = get_jwt_identity()
    clinic_id = _get_clinic_id(user_id)
    OPDRecord.delete(record_id, clinic_id=clinic_id)
    return jsonify({'message': 'Deleted'}), 200


# ─────────────────────────────────────────────
# Image sync endpoint
# ─────────────────────────────────────────────

class _ImageRecord:
    def __init__(self, path):
        self.file_path = str(path)


def save_images_locally(opd_id, files):
    opd_dir = Path(IMAGE_STORAGE_PATH) / str(opd_id)
    opd_dir.mkdir(parents=True, exist_ok=True)
    saved = []
    for i, f in enumerate(files, 1):
        ext = Path(f.filename).suffix or '.jpg'
        dest = opd_dir / f"image_{i}{ext}"
        f.save(str(dest))
        saved.append(dest)
    return saved


def build_sheet_row_data(opd, patient, drive_urls):
    def safe_int(val):
        try:
            return int(float(val)) if val else 0
        except (ValueError, TypeError):
            return 0

    consultation_fee = safe_int(opd.get('consultation_fee'))
    medicine_fee = safe_int(opd.get('medicine_fee'))
    panchakarma_fee = safe_int(opd.get('panchakarma_fee'))
    discount_value = safe_int(opd.get('discount_value') or opd.get('discount'))
    discount_type = opd.get('discount_type', 'None')

    subtotal = consultation_fee + medicine_fee + panchakarma_fee
    if discount_type == '₹':
        total_fee = max(0, subtotal - discount_value)
    elif discount_type == '%':
        total_fee = max(0, int(subtotal - (subtotal * discount_value / 100)))
    elif discount_value > 0:
        # Backward compatibility: old records have discount but no discount_type
        total_fee = max(0, subtotal - discount_value)
    else:
        total_fee = subtotal

    pk_val = opd.get('panchakarma_notes', '')
    logger.info("SHEET DEBUG: build_sheet_row_data for OPD %s panchakarma_notes=%r", opd.get('id') or opd.get('opd_id'), pk_val)

    # Preserve existing image_links from PostgreSQL when no new drive_urls provided.
    # This prevents sync push from overwriting uploaded image links with empty.
    if not drive_urls:
        existing_links = opd.get('image_links', '') or ''
        if existing_links:
            drive_urls = existing_links.split('\n')
            logger.info("SHEET PRESERVED image_links for OPD %s: %s", opd.get('id') or opd.get('opd_id'), drive_urls)

    return {
        'OPD ID': opd.get('id') or opd.get('opd_id'),
        'Patient ID': opd.get('patient_id'),
        'Patient Name': patient.get('full_name') or patient.get('name', ''),
        'Mobile': patient.get('mobile_number') or patient.get('mobile', ''),
        'Gender': patient.get('gender', ''),
        'DOB': patient.get('dob', ''),
        'Age': patient.get('age', 0),
        'Weight': patient.get('weight'),
        'Blood Group': patient.get('blood_group', '') or opd.get('blood_group', ''),
        'Address': patient.get('address', ''),
        'Visit Date': opd.get('visit_datetime') or opd.get('visit_date', ''),
        'OPD Type': opd.get('opd_type') or opd.get('type', 'OPD'),
        'Charge Type': opd.get('charge_type', ''),
        'Diagnosis': opd.get('diagnosis', ''),
        'Symptoms': opd.get('symptoms', ''),
        'Clinical Notes': opd.get('clinical_notes', ''),
        'Panchakarma Notes': pk_val,
        'Medicines': opd.get('medicines', ''),
        'Consultation Fee': str(consultation_fee),
        'Medicine Fee': str(medicine_fee),
        'Panchakarma Fee': str(panchakarma_fee),
        'Total Fee': str(int(total_fee)),
        'Discount Type': discount_type if discount_type != 'None' else 'NA',
        'Discount Value': str(discount_value),
        'Payment Mode': opd.get('payment_mode', ''),
        'Next Visit Date': opd.get('next_visit_date') or opd.get('next_visit', ''),
        'Follow-up Status': opd.get('followup_status') or opd.get('follow_up_reason') or
            ('Scheduled' if (opd.get('next_visit_date') or opd.get('next_visit', '')) else 'No Follow-up'),
        'Image Links': drive_urls,
    }


@opd_bp.route('/<opd_id>/debug-sheet', methods=['GET'])
@jwt_required()
def debug_opd_sheet(opd_id):
    """
    Debug endpoint: returns the PostgreSQL state of an OPD + patient,
    what the sheet row WOULD look like, and the current Google Sheet state.
    Call this after editing an OPD to see if the push data is correct.
    """
    user_id = get_jwt_identity()
    clinic_id = _get_clinic_id(user_id)
    if not clinic_id:
        return jsonify({'error': 'No clinic assigned'}), 403

    opd = OPDRecord.get(opd_id, clinic_id=clinic_id)
    if opd is None:
        return jsonify({'error': 'OPD not found in PostgreSQL'}), 404

    patient = Patient.get(opd['patient_id'], clinic_id=clinic_id)

    # Build the sheet row as it would be written
    sheet_row_data = build_sheet_row_data(opd, patient or {}, [])

    # Check the current Google Sheet state for this OPD ID
    sheet_state = None
    try:
        client = _get_client()
        ws = _get_opd_worksheet(client)
        col_a = ws.col_values(1)
        row_found = None
        for i, existing_id in enumerate(col_a):
            if i == 0:
                continue
            if existing_id == opd_id:
                row_found = i + 1
                break
        sheet_state = {
            'row_found': row_found,
            'column_a_count': len(col_a),
            'column_a_header': col_a[0] if col_a else '',
        }
    except Exception as e:
        sheet_state = {'error': str(e)}

    return jsonify({
        'opd_id': opd_id,
        'postgresql_opd': {k: str(v) if not isinstance(v, (str, int, float, bool, type(None))) else v for k, v in opd.items()},
        'postgresql_patient': {k: str(v) if not isinstance(v, (str, int, float, bool, type(None))) else v for k, v in (patient or {}).items()},
        'sheet_row_data': sheet_row_data,
        'sheet_state': sheet_state,
    }), 200


@opd_bp.route('/<opd_id>/images', methods=['POST'])
@jwt_required()
def upload_opd_images(opd_id):
    logger.info("Image sync requested for OPD %s", opd_id)

    opd = OPDRecord.get(opd_id)
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

    try:
        visit_date = datetime.fromisoformat(opd.get('visit_datetime') or opd.get('visit_date', ''))
    except (ValueError, TypeError):
        logger.warning("Could not parse visit_datetime/visit_date '%s', using current time", opd.get('visit_datetime') or opd.get('visit_date'))
        visit_date = datetime.utcnow()

    if IS_CLOUD:
        logger.info("Cloud mode: uploading %d image(s) directly to Drive for OPD %s", len(files), opd_id)
        drive_urls = []
        for i, f in enumerate(files, 1):
            url = upload_image_fileobj_to_drive(opd_id, f, i)
            if url:
                drive_urls.append(url)
        logger.info("Uploaded %d image(s) to Drive for OPD %s", len(drive_urls), opd_id)
    else:
        logger.info("Saving %d image(s) locally for OPD %s", len(files), opd_id)
        saved_paths = save_images_locally(opd_id, files)
        logger.info("Saved %d image(s) at %s", len(saved_paths), IMAGE_STORAGE_PATH)
        image_records = [_ImageRecord(p) for p in saved_paths]
        logger.info("Uploading %d image(s) to Google Drive for OPD %s", len(image_records), opd_id)
        drive_urls = upload_images_to_drive(opd_id, image_records, visit_date)
        logger.info("Uploaded %d image(s) to Drive for OPD %s", len(drive_urls), opd_id)

    patient = Patient.get(opd['patient_id'])
    if patient is None:
        logger.error("Patient not found for OPD %s (patient_id=%s)", opd_id, opd['patient_id'])
        return jsonify({'error': 'Patient not found'}), 404

    urls_text = "\n".join(drive_urls)
    OPDRecord.set_image_links(opd_id, urls_text)
    logger.info("Image links persisted in opd_records for OPD %s", opd_id)

    sheet_update_ok = True
    row_data = build_sheet_row_data(opd, patient, drive_urls)
    try:
        upsert_opd_row_in_sheet(opd_id, row_data)
        logger.info("Sheet append complete for OPD %s", opd_id)
    except RuntimeError as e:
        logger.error("Sheet write blocked (no new sheet created): %s", e)
        sheet_update_ok = False

    response = {
        'opd_id': opd_id,
        'image_count': len(drive_urls),
        'drive_urls': drive_urls,
    }

    if sheet_update_ok:
        response['message'] = 'Images synced successfully'
        return jsonify(response), 200
    else:
        response['message'] = (
            'Images uploaded to Drive, but the Google Sheet was not updated. '
            'Grant the service account Editor access to the sheet, then re-sync.'
        )
        response['error'] = (
            f'Sheet ID {GOOGLE_SHEET_ID} is not accessible. '
            f'Add medihive-service@medihive-500611.iam.gserviceaccount.com '
            f'as Editor on the sheet.'
        )
        return jsonify(response), 207
