from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.appointment import Appointment
from database import get_db
from services.fcm_service import send_push_to_all_users

appointments_bp = Blueprint('appointments', __name__)


def _get_clinic_id(user_id):
    with get_db() as db:
        user = db.execute(
            "SELECT clinic_id FROM users WHERE id = %s", (user_id,)
        ).fetchone()
    return user['clinic_id'] if user and user['clinic_id'] else None


@appointments_bp.route('', methods=['GET'])
@jwt_required()
def list_appointments():
    user_id = get_jwt_identity()
    clinic_id = _get_clinic_id(user_id)
    date = request.args.get('date')
    appts = Appointment.all(date=date, clinic_id=clinic_id)
    return jsonify({'appointments': appts}), 200


@appointments_bp.route('/<appt_id>', methods=['GET'])
@jwt_required()
def get_appointment(appt_id):
    user_id = get_jwt_identity()
    clinic_id = _get_clinic_id(user_id)
    appt = Appointment.get(appt_id, clinic_id=clinic_id)
    if appt is None:
        return jsonify({'error': 'Appointment not found'}), 404
    return jsonify({'appointment': appt}), 200


@appointments_bp.route('', methods=['POST'])
@jwt_required()
def create_appointment():
    user_id = get_jwt_identity()
    clinic_id = _get_clinic_id(user_id)
    data = request.get_json()
    if not data or not data.get('id') or not data.get('date_time'):
        return jsonify({'error': 'id and date_time required'}), 400
    data['clinic_id'] = clinic_id
    data['user_id'] = user_id
    appt = Appointment.create(data)

    patient_name = data.get('patient_name', 'A patient')
    try:
        send_push_to_all_users(
            title='New Appointment Created',
            body=f'{patient_name} has a new appointment scheduled',
            data={'route': '/app/calendar', 'type': 'appointment'},
        )
    except Exception:
        pass

    return jsonify({'appointment': appt}), 201


@appointments_bp.route('/<appt_id>', methods=['PUT'])
@jwt_required()
def update_appointment(appt_id):
    user_id = get_jwt_identity()
    clinic_id = _get_clinic_id(user_id)
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body required'}), 400
    appt = Appointment.update(appt_id, data, clinic_id=clinic_id)
    if appt is None:
        return jsonify({'error': 'Appointment not found'}), 404
    return jsonify({'appointment': appt}), 200


@appointments_bp.route('/<appt_id>', methods=['DELETE'])
@jwt_required()
def delete_appointment(appt_id):
    user_id = get_jwt_identity()
    clinic_id = _get_clinic_id(user_id)
    Appointment.delete(appt_id, clinic_id=clinic_id)
    return jsonify({'message': 'Deleted'}), 200
