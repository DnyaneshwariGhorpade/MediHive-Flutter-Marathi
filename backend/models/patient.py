from database import get_db
from datetime import datetime


class Patient:
    TABLE = 'patients'

    @staticmethod
    def dict_from_row(row):
        if row is None:
            return None
        return dict(row)

    @staticmethod
    def all(clinic_id=None):
        with get_db() as db:
            if clinic_id:
                rows = db.execute(
                    "SELECT * FROM patients WHERE clinic_id = %s ORDER BY updated_at DESC",
                    (clinic_id,)
                ).fetchall()
            else:
                rows = db.execute("SELECT * FROM patients ORDER BY updated_at DESC").fetchall()
        return [Patient.dict_from_row(r) for r in rows]

    @staticmethod
    def get(patient_id, clinic_id=None):
        with get_db() as db:
            if clinic_id:
                row = db.execute(
                    "SELECT * FROM patients WHERE id = %s AND clinic_id = %s",
                    (patient_id, clinic_id)
                ).fetchone()
            else:
                row = db.execute("SELECT * FROM patients WHERE id = %s", (patient_id,)).fetchone()
        return Patient.dict_from_row(row)

    @staticmethod
    def create(data):
        now = datetime.utcnow().isoformat()
        with get_db() as db:
            db.execute("""
                INSERT INTO patients (id, full_name, dob, age, gender, blood_group, mobile_number, alternate_mobile,
                                      address, created_at, updated_at, weight,
                                      user_id, clinic_id, device_id, sync_status, last_synced_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO UPDATE SET
                    full_name = COALESCE(NULLIF(EXCLUDED.full_name, ''), patients.full_name),
                    dob = COALESCE(NULLIF(EXCLUDED.dob, ''), patients.dob),
                    age = COALESCE(EXCLUDED.age, patients.age),
                    gender = COALESCE(NULLIF(EXCLUDED.gender, ''), patients.gender),
                    blood_group = COALESCE(NULLIF(EXCLUDED.blood_group, ''), patients.blood_group),
                    mobile_number = COALESCE(NULLIF(EXCLUDED.mobile_number, ''), patients.mobile_number),
                    alternate_mobile = COALESCE(NULLIF(EXCLUDED.alternate_mobile, ''), patients.alternate_mobile),
                    address = COALESCE(NULLIF(EXCLUDED.address, ''), patients.address),
                    weight = COALESCE(EXCLUDED.weight, patients.weight),
                    clinic_id = COALESCE(NULLIF(EXCLUDED.clinic_id, ''), patients.clinic_id),
                    device_id = COALESCE(NULLIF(EXCLUDED.device_id, ''), patients.device_id),
                    sync_status = EXCLUDED.sync_status,
                    last_synced_at = EXCLUDED.last_synced_at,
                    updated_at = EXCLUDED.updated_at
            """, (
                data['id'], data.get('full_name') or data.get('name', ''), data.get('dob', ''),
                data.get('age', 0), data.get('gender', 'Not Specified'),
                data.get('blood_group', 'Not Specified'),
                data.get('mobile_number') or data.get('mobile', ''), data.get('alternate_mobile', ''),
                data.get('address', ''), now, now, data.get('weight'),
                data.get('user_id', ''),
                data.get('clinic_id', ''),
                data.get('device_id', ''),
                data.get('sync_status', 'pending'),
                data.get('last_synced_at', ''),
            ))
            db.commit()
        return Patient.get(data['id'])

    @staticmethod
    def update(patient_id, data, clinic_id=None):
        now = datetime.utcnow().isoformat()
        allowed = ('full_name', 'dob', 'age', 'gender', 'blood_group', 'mobile_number',
                   'alternate_mobile', 'address', 'weight', 'user_id',
                   'clinic_id', 'device_id', 'sync_status', 'last_synced_at')
        fields = []
        values = []
        for k in allowed:
            if k in data:
                fields.append(f"{k} = %s")
                values.append(data[k])
        if not fields:
            return Patient.get(patient_id, clinic_id=clinic_id)
        fields.append("updated_at = %s")
        values.append(now)
        values.append(patient_id)
        with get_db() as db:
            if clinic_id:
                values.append(clinic_id)
                db.execute(
                    f"UPDATE patients SET {', '.join(fields)} WHERE id = %s AND clinic_id = %s",
                    values
                )
            else:
                db.execute(f"UPDATE patients SET {', '.join(fields)} WHERE id = %s", values)
            db.commit()
        return Patient.get(patient_id, clinic_id=clinic_id)

    @staticmethod
    def assign_next_id(clinic_id=None):
        with get_db() as db:
            if clinic_id:
                result = db.execute(
                    "SELECT COALESCE(MAX(CAST(SUBSTR(TRIM(id), 2) AS INTEGER)), 0) + 1 AS nid "
                    "FROM patients WHERE SUBSTR(id, 1, 1) = 'P' AND clinic_id = %s",
                    (clinic_id,)
                ).fetchone()
            else:
                result = db.execute(
                    "SELECT COALESCE(MAX(CAST(SUBSTR(TRIM(id), 2) AS INTEGER)), 0) + 1 AS nid "
                    "FROM patients WHERE SUBSTR(id, 1, 1) = 'P'"
                ).fetchone()
            next_num = result['nid']
        return f'P{next_num:03d}'

    @staticmethod
    def delete(patient_id, clinic_id=None):
        from models.deleted_entity import DeletedEntity
        from models.opd_record import OPDRecord
        with get_db() as db:
            if clinic_id:
                opd_rows = db.execute(
                    "SELECT id FROM opd_visits WHERE patient_id = %s AND clinic_id = %s",
                    (patient_id, clinic_id)
                ).fetchall()
            else:
                opd_rows = db.execute(
                    "SELECT id FROM opd_visits WHERE patient_id = %s", (patient_id,)
                ).fetchall()
        for row in opd_rows:
            OPDRecord.delete(row['id'], clinic_id=clinic_id)
        DeletedEntity.record('patient', patient_id, clinic_id=clinic_id or '')
        with get_db() as db:
            if clinic_id:
                db.execute(
                    "DELETE FROM patients WHERE id = %s AND clinic_id = %s",
                    (patient_id, clinic_id)
                )
            else:
                db.execute("DELETE FROM patients WHERE id = %s", (patient_id,))
            db.commit()

    @staticmethod
    def upsert(data, clinic_id=None):
        existing = Patient.get(data['id'], clinic_id=clinic_id)
        if existing:
            return Patient.update(data['id'], data, clinic_id=clinic_id)
        return Patient.create(data)

    @staticmethod
    def by_clinic(clinic_id):
        with get_db() as db:
            rows = db.execute(
                "SELECT * FROM patients WHERE clinic_id = %s ORDER BY updated_at DESC",
                (clinic_id,)
            ).fetchall()
        return [Patient.dict_from_row(r) for r in rows]

    @staticmethod
    def updated_since(timestamp, clinic_id=None):
        with get_db() as db:
            if clinic_id:
                rows = db.execute(
                    "SELECT * FROM patients WHERE updated_at > %s AND clinic_id = %s ORDER BY updated_at",
                    (timestamp, clinic_id)
                ).fetchall()
            else:
                rows = db.execute(
                    "SELECT * FROM patients WHERE updated_at > %s ORDER BY updated_at",
                    (timestamp,)
                ).fetchall()
        return [Patient.dict_from_row(r) for r in rows]

    @staticmethod
    def full_restore(clinic_id):
        with get_db() as db:
            rows = db.execute(
                "SELECT * FROM patients WHERE clinic_id = %s ORDER BY updated_at",
                (clinic_id,)
            ).fetchall()
        return [Patient.dict_from_row(r) for r in rows]

    @staticmethod
    def mark_synced(patient_id, clinic_id, synced_at):
        with get_db() as db:
            db.execute(
                "UPDATE patients SET sync_status = 'synced', last_synced_at = %s, updated_at = %s "
                "WHERE id = %s AND clinic_id = %s",
                (synced_at, synced_at, patient_id, clinic_id)
            )
            db.commit()
