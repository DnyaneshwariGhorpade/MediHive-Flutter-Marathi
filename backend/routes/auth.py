from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from database import get_db
from datetime import datetime
import hashlib
import time
import uuid

auth_bp = Blueprint('auth', __name__)

# Simple in-memory rate limiter: max attempts per IP within a window
_rate_limit_store = {}
_MAX_ATTEMPTS = 10
_WINDOW_SECONDS = 300  # 5 minutes


def _rate_limit_check(ip):
    now = time.time()
    key = ip
    attempts = _rate_limit_store.get(key, [])
    attempts = [t for t in attempts if now - t < _WINDOW_SECONDS]
    if len(attempts) >= _MAX_ATTEMPTS:
        return False
    attempts.append(now)
    _rate_limit_store[key] = attempts
    return True


@auth_bp.route('/login', methods=['POST'])
def login():
    if not _rate_limit_check(request.remote_addr):
        return jsonify({'error': 'Too many attempts. Try again later.'}), 429

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
            "SELECT * FROM users WHERE (username = %s OR LOWER(email) = LOWER(%s)) AND password = %s",
            (username, username, hashed)
        ).fetchone()

    if user is None:
        return jsonify({'error': 'Invalid credentials'}), 401

    token = create_access_token(identity=str(user['id']))
    return jsonify({
        'token': token,
        'user': {
            'id': str(user['id']),
            'username': user['username'],
            'email': user.get('email') or '',
            'name': user['name'],
            'clinic_id': user['clinic_id'] or '',
            'role': user.get('role', 'doctor'),
        }
    }), 200


@auth_bp.route('/register', methods=['POST'])
def register():
    if not _rate_limit_check(request.remote_addr):
        return jsonify({'error': 'Too many attempts. Try again later.'}), 429

    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body required'}), 400

    username = data.get('username', '').strip()
    password = data.get('password', '')
    name = data.get('name', 'Doctor')
    email = data.get('email', '').strip() or None

    if not username or not password:
        return jsonify({'error': 'Username and password required'}), 400

    with get_db() as db:
        existing = db.execute("SELECT id FROM users WHERE username = %s", (username,)).fetchone()
        if existing:
            return jsonify({'error': 'Username already exists'}), 409

        if email:
            email_taken = db.execute("SELECT id FROM users WHERE LOWER(email) = LOWER(%s)", (email,)).fetchone()
            if email_taken:
                return jsonify({'error': 'Email already exists'}), 409

        clinic_id = f'CLI{uuid.uuid4().hex[:8].upper()}'
        now = datetime.utcnow().isoformat()

        db.execute("""
            INSERT INTO clinics (id, name, email, phone, address, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (id) DO NOTHING
        """, (clinic_id, f"{name}'s Clinic", '', '', '', now, now))

        hashed = hashlib.sha256(password.encode()).hexdigest()
        row = db.execute(
            "INSERT INTO users (username, password, name, email, created_at, clinic_id) VALUES (%s, %s, %s, %s, %s, %s) RETURNING id",
            (username, hashed, name, email, now, clinic_id)
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
            'email': email or '',
            'name': name,
            'clinic_id': clinic_id,
            'role': 'doctor',
        },
        'clinic': dict(clinic) if clinic else None,
    }), 201


@auth_bp.route('/register-clinic', methods=['POST'])
def register_clinic():
    if not _rate_limit_check(request.remote_addr):
        return jsonify({'error': 'Too many attempts. Try again later.'}), 429

    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body required'}), 400

    username = data.get('username', '').strip()
    password = data.get('password', '')
    name = data.get('name', 'Doctor')
    email = data.get('email', '').strip() or None
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

        if email:
            email_taken = db.execute("SELECT id FROM users WHERE LOWER(email) = LOWER(%s)", (email,)).fetchone()
            if email_taken:
                return jsonify({'error': 'Email already exists'}), 409

        import uuid
        clinic_id = f'CLI{uuid.uuid4().hex[:8].upper()}'
        now = datetime.utcnow().isoformat()

        db.execute("""
            INSERT INTO clinics (id, name, email, phone, address, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (id) DO NOTHING
        """, (clinic_id, clinic_name, clinic_email, clinic_phone, clinic_address, now, now))

        hashed = hashlib.sha256(password.encode()).hexdigest()
        row = db.execute(
            "INSERT INTO users (username, password, name, email, created_at, clinic_id) VALUES (%s, %s, %s, %s, %s, %s) RETURNING id",
            (username, hashed, name, email, now, clinic_id)
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
            'email': email or '',
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
            "SELECT id, username, email, name, created_at, clinic_id, role FROM users WHERE id = %s",
            (user_id,)
        ).fetchone()
    if user is None:
        return jsonify({'error': 'User not found'}), 404
    return jsonify({'user': dict(user)}), 200


@auth_bp.route('/change-password', methods=['POST'])
@jwt_required()
def change_password():
    user_id = get_jwt_identity()
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body required'}), 400

    current_password = data.get('current_password', '')
    new_password = data.get('new_password', '')

    if not current_password or not new_password:
        return jsonify({'error': 'Current and new password required'}), 400

    if len(new_password) < 4:
        return jsonify({'error': 'New password must be at least 4 characters'}), 400

    hashed_current = hashlib.sha256(current_password.encode()).hexdigest()
    hashed_new = hashlib.sha256(new_password.encode()).hexdigest()

    with get_db() as db:
        user = db.execute(
            "SELECT id, password FROM users WHERE id = %s",
            (user_id,)
        ).fetchone()

        if user is None:
            return jsonify({'error': 'User not found'}), 404

        if user['password'] != hashed_current:
            return jsonify({'error': 'Current password is incorrect'}), 400

        db.execute(
            "UPDATE users SET password = %s WHERE id = %s",
            (hashed_new, user_id)
        )
        db.commit()

    return jsonify({'message': 'Password updated successfully'}), 200
