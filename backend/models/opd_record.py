from database import get_db
from datetime import datetime


class OPDRecord:
    TABLE = 'opd_visits'

    @staticmethod
    def dict_from_row(row):
        if row is None:
            return None
        return dict(row)

    @staticmethod
    def _to_float(val):
        if val is None or str(val).strip() == '':
            return 0.0
        try:
            return float(val)
        except Exception:
            return 0.0

    @staticmethod
    def all(patient_id=None, clinic_id=None):
        with get_db() as db:
            if patient_id and clinic_id:
                rows = db.execute(
                    "SELECT * FROM opd_visits WHERE patient_id = %s AND clinic_id = %s ORDER BY visit_datetime DESC",
                    (patient_id, clinic_id)
                ).fetchall()
            elif patient_id:
                rows = db.execute(
                    "SELECT * FROM opd_visits WHERE patient_id = %s ORDER BY visit_datetime DESC",
                    (patient_id,)
                ).fetchall()
            elif clinic_id:
                rows = db.execute(
                    "SELECT * FROM opd_visits WHERE clinic_id = %s ORDER BY visit_datetime DESC",
                    (clinic_id,)
                ).fetchall()
            else:
                rows = db.execute("SELECT * FROM opd_visits ORDER BY visit_datetime DESC").fetchall()
        return [OPDRecord.dict_from_row(r) for r in rows]

    @staticmethod
    def get(record_id, clinic_id=None):
        with get_db() as db:
            if clinic_id:
                row = db.execute(
                    "SELECT * FROM opd_visits WHERE id = %s AND clinic_id = %s",
                    (record_id, clinic_id)
                ).fetchone()
            else:
                row = db.execute("SELECT * FROM opd_visits WHERE id = %s", (record_id,)).fetchone()
        return OPDRecord.dict_from_row(row)

    @staticmethod
    def create(data):
        now = datetime.utcnow().isoformat()
        with get_db() as db:
            db.execute("""
                INSERT INTO opd_visits (id, opd_id, patient_id, opd_type, symptoms, diagnosis, medicines,
                    visit_datetime, clinical_notes, consultation_fee, medicine_fee, panchakarma_fee,
                    total_fee, discount_type, discount_value, payment_mode, charge_type,
                    followup_status, next_visit_date, blood_group, image_links, panchakarma_notes, created_at, updated_at,
                    user_id, clinic_id, device_id, sync_status, last_synced_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                data['id'], data.get('opd_id', ''), data['patient_id'], data.get('opd_type', 'OPD'),
                data.get('symptoms', ''), data.get('diagnosis', ''),
                data.get('medicines', ''), data.get('visit_datetime', now),
                data.get('clinical_notes', ''), OPDRecord._to_float(data.get('consultation_fee')),
                OPDRecord._to_float(data.get('medicine_fee')), OPDRecord._to_float(data.get('panchakarma_fee')),
                OPDRecord._to_float(data.get('total_fee')), data.get('discount_type', 'None'),
                OPDRecord._to_float(data.get('discount_value')),
                data.get('payment_mode', ''), data.get('charge_type', ''),
                data.get('followup_status', ''), data.get('next_visit_date', ''), data.get('blood_group', ''),
                data.get('image_links', ''), data.get('panchakarma_notes', ''),
                now, now,
                data.get('user_id', ''),
                data.get('clinic_id', ''),
                data.get('device_id', ''),
                data.get('sync_status', 'pending'),
                data.get('last_synced_at', ''),
            ))
            db.commit()
        return OPDRecord.get(data['id'])

    @staticmethod
    def update(record_id, data, clinic_id=None):
        now = datetime.utcnow().isoformat()
        allowed = ('opd_id', 'patient_id', 'opd_type', 'symptoms', 'diagnosis', 'medicines', 'visit_datetime',
                   'clinical_notes', 'consultation_fee', 'medicine_fee',
                   'panchakarma_fee', 'total_fee', 'discount_type', 'discount_value',
                   'payment_mode', 'charge_type', 'followup_status', 'next_visit_date', 'blood_group',
                   'image_links', 'user_id', 'clinic_id',
                   'panchakarma_notes', 'device_id', 'sync_status', 'last_synced_at')
        fields = []
        values = []
        for k in allowed:
            if k in data:
                fields.append(f"{k} = %s")
                if k in ('consultation_fee', 'medicine_fee', 'panchakarma_fee', 'total_fee', 'discount_value'):
                    values.append(OPDRecord._to_float(data[k]))
                else:
                    values.append(data[k])
        if not fields:
            return OPDRecord.get(record_id, clinic_id=clinic_id)
        fields.append("updated_at = %s")
        values.append(now)
        values.append(record_id)
        with get_db() as db:
            if clinic_id:
                values.append(clinic_id)
                db.execute(
                    f"UPDATE opd_visits SET {', '.join(fields)} WHERE id = %s AND clinic_id = %s",
                    values
                )
            else:
                db.execute(f"UPDATE opd_visits SET {', '.join(fields)} WHERE id = %s", values)
            db.commit()
        return OPDRecord.get(record_id, clinic_id=clinic_id)

    @staticmethod
    def delete(record_id, clinic_id=None):
        from models.deleted_entity import DeletedEntity
        DeletedEntity.record('opd_visit', record_id, clinic_id=clinic_id or '')
        with get_db() as db:
            if clinic_id:
                db.execute(
                    "DELETE FROM opd_visits WHERE id = %s AND clinic_id = %s",
                    (record_id, clinic_id)
                )
            else:
                db.execute("DELETE FROM opd_visits WHERE id = %s", (record_id,))
            db.commit()

    @staticmethod
    def upsert(data, clinic_id=None):
        existing = OPDRecord.get(data['id'], clinic_id=clinic_id)
        if existing:
            return OPDRecord.update(data['id'], data, clinic_id=clinic_id)
        return OPDRecord.create(data)

    @staticmethod
    def set_image_links(record_id, links_text, clinic_id=None):
        now = datetime.utcnow().isoformat()
        with get_db() as db:
            if clinic_id:
                db.execute(
                    "UPDATE opd_visits SET image_links = %s, updated_at = %s WHERE id = %s AND clinic_id = %s",
                    (links_text, now, record_id, clinic_id)
                )
            else:
                db.execute(
                    "UPDATE opd_visits SET image_links = %s, updated_at = %s WHERE id = %s",
                    (links_text, now, record_id)
                )
            db.commit()

    @staticmethod
    def by_clinic(clinic_id):
        with get_db() as db:
            rows = db.execute(
                "SELECT * FROM opd_visits WHERE clinic_id = %s ORDER BY updated_at DESC",
                (clinic_id,)
            ).fetchall()
        return [OPDRecord.dict_from_row(r) for r in rows]

    @staticmethod
    def updated_since(timestamp, clinic_id=None):
        with get_db() as db:
            if clinic_id:
                rows = db.execute(
                    "SELECT * FROM opd_visits WHERE updated_at > %s AND clinic_id = %s ORDER BY updated_at",
                    (timestamp, clinic_id)
                ).fetchall()
            else:
                rows = db.execute(
                    "SELECT * FROM opd_visits WHERE updated_at > %s ORDER BY updated_at",
                    (timestamp,)
                ).fetchall()
        return [OPDRecord.dict_from_row(r) for r in rows]

    @staticmethod
    def full_restore(clinic_id):
        with get_db() as db:
            rows = db.execute(
                "SELECT * FROM opd_visits WHERE clinic_id = %s ORDER BY updated_at",
                (clinic_id,)
            ).fetchall()
        return [OPDRecord.dict_from_row(r) for r in rows]

    @staticmethod
    def mark_synced(record_id, clinic_id, synced_at):
        with get_db() as db:
            db.execute(
                "UPDATE opd_visits SET sync_status = 'synced', last_synced_at = %s, updated_at = %s "
                "WHERE id = %s AND clinic_id = %s",
                (synced_at, synced_at, record_id, clinic_id)
            )
            db.commit()
