from database import get_db
from datetime import datetime


class DeletedEntity:

    @staticmethod
    def record(entity_type, entity_id, user_id='', clinic_id=''):
        now = datetime.utcnow().isoformat()
        with get_db() as db:
            db.execute(
                "INSERT INTO deleted_entities (entity_type, entity_id, deleted_at, user_id, clinic_id) "
                "VALUES (%s, %s, %s, %s, %s)",
                (entity_type, entity_id, now, user_id, clinic_id)
            )
            db.commit()

    @staticmethod
    def since(timestamp, clinic_id=None):
        with get_db() as db:
            if clinic_id:
                rows = db.execute(
                    "SELECT entity_type, entity_id, deleted_at FROM deleted_entities "
                    "WHERE deleted_at > %s AND clinic_id = %s "
                    "ORDER BY deleted_at",
                    (timestamp, clinic_id)
                ).fetchall()
            else:
                rows = db.execute(
                    "SELECT entity_type, entity_id, deleted_at FROM deleted_entities "
                    "WHERE deleted_at > %s ORDER BY deleted_at",
                    (timestamp,)
                ).fetchall()
        return [dict(r) for r in rows]
