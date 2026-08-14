from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from database import get_db
from datetime import datetime
import hashlib
import uuid

auth_bp = Blueprint('auth', __name__)


@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body required'}), 400

    username = data.get('username', '').strip()
    password = data.get('password', '')

    if not username or not password:
        return jsonify({'error': 'Username and password required'}), 400

    hashed = hashlib.sha256(password.encode()).hexdigest()
    with get_db() as db:
        user = db.execute(
            "SELECT * FROM users WHERE username = %s AND password = %s",
            (username, hashed)
        ).fetchone()

    if user is None:
        return jsonify({'error': 'Invalid credentials'}), 401

    token = create_access_token(identity=str(user['id']))
    return jsonify({
        'token': token,
        'user': {
            'id': str(user['id']),
            'username': user['username'],
            'name': user['name'],
            'clinic_id': user['clinic_id'] or '',
            'role': user.get('role', 'doctor'),
        }
    }), 200


@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body required'}), 400

    username = data.get('username', '').strip()
    password = data.get('password', '')
    name = data.get('name', 'Doctor')

    if not username or not password:
        return jsonify({'error': 'Username and password required'}), 400

    with get_db() as db:
        existing = db.execute("SELECT id FROM users WHERE username = %s", (username,)).fetchone()
        if existing:
            return jsonify({'error': 'Username already exists'}), 409

        clinic_id = f'CLI{uuid.uuid4().hex[:8].upper()}'
        now = datetime.utcnow().isoformat()

        db.execute("""
            INSERT INTO clinics (id, name, email, phone, address, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (id) DO NOTHING
        """, (clinic_id, f"{name}'s Clinic", '', '', '', now, now))

        hashed = hashlib.sha256(password.encode()).hexdigest()
        row = db.execute(
            "INSERT INTO users (username, password, name, created_at, clinic_id) VALUES (%s, %s, %s, %s, %s) RETURNING id",
            (username, hashed, name, now, clinic_id)
        ).fetchone()
        db.commit()
        user_id = row['id']

        clinic = db.execute("SELECT * FROM clinics WHERE id = %s", (clinic_id,)).fetchone()

    token = create_access_token(identity=str(user_id))

    return jsonify({
        'token': token,
        'user': {
            'id': str(user_id),
            'username': username,
            'name': name,
            'clinic_id': clinic_id,
            'role': 'doctor',
        },
        'clinic': dict(clinic) if clinic else None,
    }), 201


@auth_bp.route('/register-clinic', methods=['POST'])
def register_clinic():
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body required'}), 400

    username = data.get('username', '').strip()
    password = data.get('password', '')
    name = data.get('name', 'Doctor')
    clinic_name = data.get('clinic_name', '').strip()
    clinic_email = data.get('clinic_email', '').strip()
    clinic_phone = data.get('clinic_phone', '').strip()
    clinic_address = data.get('clinic_address', '').strip()

    if not username or not password or not clinic_name:
        return jsonify({'error': 'Username, password, and clinic_name required'}), 400

    with get_db() as db:
        existing = db.execute("SELECT id FROM users WHERE username = %s", (username,)).fetchone()
        if existing:
            return jsonify({'error': 'Username already exists'}), 409

        clinic_id = data.get('clinic_id', '').strip() or f'CLI{uuid.uuid4().hex[:8].upper()}'
        now = datetime.utcnow().isoformat()

        db.execute("""
            INSERT INTO clinics (id, name, email, phone, address, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (id) DO NOTHING
        """, (clinic_id, clinic_name, clinic_email, clinic_phone, clinic_address, now, now))

        hashed = hashlib.sha256(password.encode()).hexdigest()
        row = db.execute(
            "INSERT INTO users (username, password, name, created_at, clinic_id) VALUES (%s, %s, %s, %s, %s) RETURNING id",
            (username, hashed, name, now, clinic_id)
        ).fetchone()
        db.commit()
        user_id = row['id']

        clinic = db.execute("SELECT * FROM clinics WHERE id = %s", (clinic_id,)).fetchone()

    token = create_access_token(identity=str(user_id))

    return jsonify({
        'token': token,
        'user': {
            'id': str(user_id),
            'username': username,
            'name': name,
            'clinic_id': clinic_id,
            'role': 'doctor',
        },
        'clinic': dict(clinic) if clinic else None,
    }), 201


@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def me():
    user_id = get_jwt_identity()
    with get_db() as db:
        user = db.execute(
            "SELECT id, username, name, created_at, clinic_id, role FROM users WHERE id = %s",
            (user_id,)
        ).fetchone()
    if user is None:
        return jsonify({'error': 'User not found'}), 404
    return jsonify({'user': dict(user)}), 200
