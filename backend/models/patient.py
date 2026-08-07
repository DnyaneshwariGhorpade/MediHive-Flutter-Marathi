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
        db = get_db()
        if clinic_id:
            rows = db.execute(
                "SELECT * FROM patients WHERE clinic_id = %s ORDER BY updated_at DESC",
                (clinic_id,)
            ).fetchall()
        else:
            rows = db.execute("SELECT * FROM patients ORDER BY updated_at DESC").fetchall()
        db.close()
        return [Patient.dict_from_row(r) for r in rows]

    @staticmethod
    def get(patient_id, clinic_id=None):
        db = get_db()
        if clinic_id:
            row = db.execute(
                "SELECT * FROM patients WHERE id = %s AND clinic_id = %s",
                (patient_id, clinic_id)
            ).fetchone()
        else:
            row = db.execute("SELECT * FROM patients WHERE id = %s", (patient_id,)).fetchone()
        db.close()
        return Patient.dict_from_row(row)

    @staticmethod
    def create(data):
        now = datetime.utcnow().isoformat()
        db = get_db()
        db.execute("""
            INSERT INTO patients (id, full_name, dob, age, gender, blood_group, mobile_number, alternate_mobile,
                                  address, created_at, updated_at, weight,
                                  user_id, clinic_id, device_id, sync_status, last_synced_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            data['id'], data['full_name'], data.get('dob', ''),
            data.get('age', 0), data.get('gender', 'Not Specified'),
            data.get('blood_group', 'Not Specified'),
            data.get('mobile_number', ''), data.get('alternate_mobile', ''),
            data.get('address', ''), now, now, data.get('weight'),
            data.get('user_id', ''),
            data.get('clinic_id', ''),
            data.get('device_id', ''),
            data.get('sync_status', 'pending'),
            data.get('last_synced_at', ''),
        ))
        db.commit()
        db.close()
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
        if clinic_id:
            values.append(clinic_id)
            db = get_db()
            db.execute(
                f"UPDATE patients SET {', '.join(fields)} WHERE id = %s AND clinic_id = %s",
                values
            )
        else:
            db = get_db()
            db.execute(f"UPDATE patients SET {', '.join(fields)} WHERE id = %s", values)
        db.commit()
        db.close()
        return Patient.get(patient_id, clinic_id=clinic_id)

    @staticmethod
    def assign_next_id(clinic_id=None):
        db = get_db()
        try:
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
        finally:
            db.close()

    @staticmethod
    def delete(patient_id, clinic_id=None):
        from models.deleted_entity import DeletedEntity
        from models.opd_record import OPDRecord
        db = get_db()
        if clinic_id:
            opd_rows = db.execute(
                "SELECT id FROM opd_visits WHERE patient_id = %s AND clinic_id = %s",
                (patient_id, clinic_id)
            ).fetchall()
        else:
            opd_rows = db.execute(
                "SELECT id FROM opd_visits WHERE patient_id = %s", (patient_id,)
            ).fetchall()
        db.close()
        for row in opd_rows:
            OPDRecord.delete(row['id'], clinic_id=clinic_id)
        DeletedEntity.record('patient', patient_id, clinic_id=clinic_id or '')
        db = get_db()
        if clinic_id:
            db.execute(
                "DELETE FROM patients WHERE id = %s AND clinic_id = %s",
                (patient_id, clinic_id)
            )
        else:
            db.execute("DELETE FROM patients WHERE id = %s", (patient_id,))
        db.commit()
        db.close()

    @staticmethod
    def upsert(data, clinic_id=None):
        existing = Patient.get(data['id'], clinic_id=clinic_id)
        if existing:
            return Patient.update(data['id'], data, clinic_id=clinic_id)
        return Patient.create(data)

    @staticmethod
    def by_clinic(clinic_id):
        db = get_db()
        rows = db.execute(
            "SELECT * FROM patients WHERE clinic_id = %s ORDER BY updated_at DESC",
            (clinic_id,)
        ).fetchall()
        db.close()
        return [Patient.dict_from_row(r) for r in rows]

    @staticmethod
    def updated_since(timestamp, clinic_id=None):
        db = get_db()
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
        db.close()
        return [Patient.dict_from_row(r) for r in rows]

    @staticmethod
    def full_restore(clinic_id):
        db = get_db()
        rows = db.execute(
            "SELECT * FROM patients WHERE clinic_id = %s ORDER BY updated_at",
            (clinic_id,)
        ).fetchall()
        db.close()
        return [Patient.dict_from_row(r) for r in rows]

    @staticmethod
    def mark_synced(patient_id, clinic_id, synced_at):
        db = get_db()
        db.execute(
            "UPDATE patients SET sync_status = 'synced', last_synced_at = %s, updated_at = %s "
            "WHERE id = %s AND clinic_id = %s",
            (synced_at, synced_at, patient_id, clinic_id)
        )
        db.commit()
        db.close()
