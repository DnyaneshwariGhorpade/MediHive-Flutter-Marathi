from database import get_db
from datetime import datetime


class Appointment:
    TABLE = 'appointments'

    @staticmethod
    def dict_from_row(row):
        if row is None:
            return None
        return dict(row)

    @staticmethod
    def all(date=None, clinic_id=None):
        with get_db() as db:
            if date and clinic_id:
                rows = db.execute(
                    "SELECT * FROM appointments WHERE CAST(date_time AS DATE) = %s AND clinic_id = %s ORDER BY date_time",
                    (date, clinic_id)
                ).fetchall()
            elif date:
                rows = db.execute(
                    "SELECT * FROM appointments WHERE CAST(date_time AS DATE) = %s ORDER BY date_time",
                    (date,)
                ).fetchall()
            elif clinic_id:
                rows = db.execute(
                    "SELECT * FROM appointments WHERE clinic_id = %s ORDER BY date_time DESC",
                    (clinic_id,)
                ).fetchall()
            else:
                rows = db.execute("SELECT * FROM appointments ORDER BY date_time DESC").fetchall()
        return [Appointment.dict_from_row(r) for r in rows]

    @staticmethod
    def get(appt_id, clinic_id=None):
        with get_db() as db:
            if clinic_id:
                row = db.execute(
                    "SELECT * FROM appointments WHERE id = %s AND clinic_id = %s",
                    (appt_id, clinic_id)
                ).fetchone()
            else:
                row = db.execute("SELECT * FROM appointments WHERE id = %s", (appt_id,)).fetchone()
        return Appointment.dict_from_row(row)

    @staticmethod
    def create(data):
        now = datetime.utcnow().isoformat()
        with get_db() as db:
            db.execute("""
                INSERT INTO appointments (id, patient_id, patient_name, date_time, notes,
                                          created_at, updated_at, user_id, clinic_id,
                                          device_id, sync_status, last_synced_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO UPDATE SET
                    patient_id = COALESCE(NULLIF(EXCLUDED.patient_id, ''), appointments.patient_id),
                    patient_name = COALESCE(NULLIF(EXCLUDED.patient_name, ''), appointments.patient_name),
                    date_time = COALESCE(NULLIF(EXCLUDED.date_time, ''), appointments.date_time),
                    notes = COALESCE(NULLIF(EXCLUDED.notes, ''), appointments.notes),
                    clinic_id = COALESCE(NULLIF(EXCLUDED.clinic_id, ''), appointments.clinic_id),
                    device_id = COALESCE(NULLIF(EXCLUDED.device_id, ''), appointments.device_id),
                    sync_status = EXCLUDED.sync_status,
                    last_synced_at = EXCLUDED.last_synced_at,
                    updated_at = EXCLUDED.updated_at
            """, (
                data['id'], data.get('patient_id', ''),
                data.get('patient_name', ''), data.get('date_time') or now,
                data.get('notes', ''), now, now,
                data.get('user_id', ''),
                data.get('clinic_id', ''),
                data.get('device_id', ''),
                data.get('sync_status', 'pending'),
                data.get('last_synced_at', ''),
            ))
            db.commit()
        return Appointment.get(data['id'])

    @staticmethod
    def update(appt_id, data, clinic_id=None):
        now = datetime.utcnow().isoformat()
        allowed = ('patient_id', 'patient_name', 'date_time', 'notes', 'user_id',
                   'clinic_id', 'device_id', 'sync_status', 'last_synced_at')
        fields = []
        values = []
        for k in allowed:
            if k in data:
                fields.append(f"{k} = %s")
                values.append(data[k])
        if not fields:
            return Appointment.get(appt_id, clinic_id=clinic_id)
        fields.append("updated_at = %s")
        values.append(now)
        values.append(appt_id)
        with get_db() as db:
            if clinic_id:
                values.append(clinic_id)
                db.execute(
                    f"UPDATE appointments SET {', '.join(fields)} WHERE id = %s AND clinic_id = %s",
                    values
                )
            else:
                db.execute(f"UPDATE appointments SET {', '.join(fields)} WHERE id = %s", values)
            db.commit()
        return Appointment.get(appt_id, clinic_id=clinic_id)

    @staticmethod
    def delete(appt_id, clinic_id=None):
        from models.deleted_entity import DeletedEntity
        DeletedEntity.record('appointment', appt_id, clinic_id=clinic_id or '')
        with get_db() as db:
            if clinic_id:
                db.execute(
                    "DELETE FROM appointments WHERE id = %s AND clinic_id = %s",
                    (appt_id, clinic_id)
                )
            else:
                db.execute("DELETE FROM appointments WHERE id = %s", (appt_id,))
            db.commit()

    @staticmethod
    def upsert(data, clinic_id=None):
        existing = Appointment.get(data['id'], clinic_id=clinic_id)
        if existing:
            return Appointment.update(data['id'], data, clinic_id=clinic_id)
        return Appointment.create(data)

    @staticmethod
    def by_clinic(clinic_id):
        with get_db() as db:
            rows = db.execute(
                "SELECT * FROM appointments WHERE clinic_id = %s ORDER BY updated_at DESC",
                (clinic_id,)
            ).fetchall()
        return [Appointment.dict_from_row(r) for r in rows]

    @staticmethod
    def updated_since(timestamp, clinic_id=None):
        with get_db() as db:
            if clinic_id:
                rows = db.execute(
                    "SELECT * FROM appointments WHERE updated_at > %s AND clinic_id = %s ORDER BY updated_at",
                    (timestamp, clinic_id)
                ).fetchall()
            else:
                rows = db.execute(
                    "SELECT * FROM appointments WHERE updated_at > %s ORDER BY updated_at",
                    (timestamp,)
                ).fetchall()
        return [Appointment.dict_from_row(r) for r in rows]

    @staticmethod
    def full_restore(clinic_id):
        with get_db() as db:
            rows = db.execute(
                "SELECT * FROM appointments WHERE clinic_id = %s ORDER BY updated_at",
                (clinic_id,)
            ).fetchall()
        return [Appointment.dict_from_row(r) for r in rows]

    @staticmethod
    def mark_synced(appt_id, clinic_id, synced_at):
        with get_db() as db:
            db.execute(
                "UPDATE appointments SET sync_status = 'synced', last_synced_at = %s, updated_at = %s "
                "WHERE id = %s AND clinic_id = %s",
                (synced_at, synced_at, appt_id, clinic_id)
            )
            db.commit()
