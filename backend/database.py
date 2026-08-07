import os
import time
import logging
import hashlib
from datetime import datetime
import psycopg2
from psycopg2 import pool
from psycopg2.extras import RealDictCursor
from config import DATABASE_URL, DB_POOL_MIN, DB_POOL_MAX, CONNECT_TIMEOUT

logger = logging.getLogger(__name__)

_pool = None
_pool_lock = False
_db_initialized = False

DEFAULT_ADMIN_USERNAME = 'admin_medihive'
DEFAULT_ADMIN_PASSWORD = '1234567890'
DEFAULT_ADMIN_NAME = 'Admin'


def _build_connection_kwargs():
    """Build connection keyword arguments with Neon-optimized settings."""
    return {
        'dsn': DATABASE_URL,
        'connect_timeout': CONNECT_TIMEOUT,
        'keepalives': 1,
        'keepalives_idle': 30,
        'keepalives_interval': 10,
        'keepalives_count': 5,
    }


def get_pool():
    global _pool, _pool_lock
    if _pool is None and not _pool_lock:
        _pool_lock = True
        try:
            _pool = pool.ThreadedConnectionPool(
                minconn=0,
                maxconn=DB_POOL_MAX,
                **_build_connection_kwargs(),
            )
        except Exception as e:
            logger.error("Failed to create connection pool: %s", e)
            _pool_lock = False
            raise
        _pool_lock = False
    return _pool


def reset_pool():
    """Close and reset the pool. Used after Neon auto-suspend recovery."""
    global _pool, _pool_lock
    old_pool = _pool
    _pool = None
    _pool_lock = False
    if old_pool is not None:
        try:
            old_pool.closeall()
        except Exception:
            pass


class DBConnection:
    """Wrapper around psycopg2 connection + RealDictCursor
    providing a simple execute/commit/rollback/close interface."""

    def __init__(self, conn):
        self._conn = conn
        self._cursor = conn.cursor(cursor_factory=RealDictCursor)

    def execute(self, sql, params=None):
        try:
            self._cursor.execute(sql, params)
        except (psycopg2.OperationalError, psycopg2.InterfaceError) as e:
            logger.warning("Database connection error, attempting recovery: %s", e)
            reset_pool()
            raise
        return self._cursor

    def commit(self):
        try:
            self._conn.commit()
        except (psycopg2.OperationalError, psycopg2.InterfaceError) as e:
            logger.warning("Commit failed, connection may be stale: %s", e)
            reset_pool()
            raise

    def rollback(self):
        try:
            self._conn.rollback()
        except Exception:
            pass

    def savepoint(self, name):
        self._cursor.execute(f"SAVEPOINT {name}")

    def rollback_to_savepoint(self, name):
        try:
            self._cursor.execute(f"ROLLBACK TO SAVEPOINT {name}")
        except Exception:
            pass

    _savepoint_counter = 0

    def try_execute(self, sql, params=None):
        """Execute a statement inside a savepoint so a failure only
        rolls back that statement, not the surrounding transaction."""
        DBConnection._savepoint_counter += 1
        name = f"sp_mig_{DBConnection._savepoint_counter}"
        self._cursor.execute(f"SAVEPOINT {name}")
        try:
            self._cursor.execute(sql, params)
            self._cursor.execute(f"RELEASE SAVEPOINT {name}")
        except Exception:
            try:
                self._cursor.execute(f"ROLLBACK TO SAVEPOINT {name}")
            except Exception:
                pass

    def close(self):
        try:
            self._cursor.close()
        except Exception:
            pass
        try:
            get_pool().putconn(self._conn)
        except Exception:
            pass


def get_db():
    """Get a database connection from the pool.
    Lazily initializes the database schema on first call.
    Retries once if the pool needs re-creation (e.g., after Neon auto-suspend)."""
    _init_db()
    for attempt in range(2):
        try:
            pool_obj = get_pool()
            if pool_obj is None:
                if attempt == 0:
                    reset_pool()
                    time.sleep(1)
                    continue
                raise RuntimeError("Connection pool not available")
            conn = pool_obj.getconn()
            return DBConnection(conn)
        except (psycopg2.OperationalError, psycopg2.InterfaceError) as e:
            logger.warning("get_db attempt %d failed: %s", attempt + 1, e)
            if attempt == 0:
                reset_pool()
                time.sleep(1)
                continue
            raise


def _init_db():
    """Lazy initialization: called on first get_db() call.
    Creates all database tables if they don't exist and seeds the default admin user.
    Idempotent — safe to call multiple times.
    Only marks initialization complete AFTER successful commit."""
    global _db_initialized
    if _db_initialized:
        return

    logger.critical("MIGRATION_TEST: init_db executed with panchakarma migration")
    pool_obj = get_pool()
    conn = pool_obj.getconn()
    db = DBConnection(conn)
    db.rollback()
    try:
        # Rename legacy table if it exists
        db.try_execute("ALTER TABLE opd_records RENAME TO opd_visits")

        # Aligned Table: patients (matches source of truth + sync columns)
        db.execute("""
            CREATE TABLE IF NOT EXISTS patients (
                id                  TEXT PRIMARY KEY,
                full_name           TEXT NOT NULL,
                mobile_number       TEXT DEFAULT '',
                alternate_mobile    TEXT DEFAULT '',
                gender              TEXT DEFAULT 'Not Specified',
                dob                 TEXT DEFAULT '',
                age                 INTEGER DEFAULT 0,
                blood_group         TEXT DEFAULT 'Not Specified',
                address             TEXT DEFAULT '',
                created_at          TEXT NOT NULL,
                updated_at          TEXT NOT NULL,
                weight              DOUBLE PRECISION DEFAULT NULL,
                user_id             TEXT DEFAULT '',
                clinic_id           TEXT DEFAULT '',
                device_id           TEXT DEFAULT '',
                sync_status         TEXT DEFAULT 'pending',
                last_synced_at      TEXT DEFAULT ''
            );
        """)

        # Aligned Table: opd_visits (matches source of truth + sync columns)
        db.execute("""
            CREATE TABLE IF NOT EXISTS opd_visits (
                id                  TEXT PRIMARY KEY,
                opd_id              TEXT UNIQUE NOT NULL,
                patient_id          TEXT NOT NULL,
                visit_datetime      TEXT NOT NULL,
                opd_type            TEXT DEFAULT 'OPD',
                charge_type         TEXT DEFAULT '',
                diagnosis           TEXT DEFAULT '',
                symptoms            TEXT DEFAULT '',
                clinical_notes      TEXT DEFAULT '',
                consultation_fee    DOUBLE PRECISION DEFAULT 0.0,
                medicine_fee        DOUBLE PRECISION DEFAULT 0.0,
                panchakarma_fee     DOUBLE PRECISION DEFAULT 0.0,
                total_fee           DOUBLE PRECISION DEFAULT 0.0,
                discount_type       TEXT DEFAULT 'None',
                discount_value      DOUBLE PRECISION DEFAULT 0.0,
                payment_mode        TEXT DEFAULT '',
                next_visit_date     TEXT DEFAULT '',
                followup_status     TEXT DEFAULT '',
                created_at          TEXT NOT NULL,
                updated_at          TEXT NOT NULL,
                medicines           TEXT DEFAULT '',
                panchakarma_notes   TEXT DEFAULT '',
                blood_group         TEXT DEFAULT '',
                image_links         TEXT DEFAULT '',
                user_id             TEXT DEFAULT '',
                clinic_id           TEXT DEFAULT '',
                device_id           TEXT DEFAULT '',
                sync_status         TEXT DEFAULT 'pending',
                last_synced_at      TEXT DEFAULT ''
            );
        """)

        # Create Table: calendar_notes (matches source of truth)
        db.execute("""
            CREATE TABLE IF NOT EXISTS calendar_notes (
                id                  SERIAL PRIMARY KEY,
                note_date           TEXT NOT NULL UNIQUE,
                note_text           TEXT DEFAULT '',
                created_at          TEXT,
                updated_at          TEXT,
                user_id             TEXT DEFAULT '',
                clinic_id           TEXT DEFAULT ''
            );
        """)

        # Create Table: clinic_settings (matches source of truth)
        db.execute("""
            CREATE TABLE IF NOT EXISTS clinic_settings (
                id                  SERIAL PRIMARY KEY,
                doctor_name         TEXT DEFAULT '',
                doctor_email        TEXT DEFAULT '',
                doctor_contact      TEXT DEFAULT '',
                doctor_license_no   TEXT DEFAULT '',
                doctor_photo_path   TEXT DEFAULT '',
                clinic_name         TEXT DEFAULT '',
                clinic_logo_path    TEXT DEFAULT '',
                clinic_address      TEXT DEFAULT '',
                clinic_phone        TEXT DEFAULT '',
                website             TEXT DEFAULT '',
                operating_hours     TEXT DEFAULT '',
                smtp_email          TEXT DEFAULT '',
                smtp_password       TEXT DEFAULT '',
                smtp_server         TEXT DEFAULT '',
                smtp_port           TEXT DEFAULT '',
                created_at          TEXT DEFAULT '',
                updated_at          TEXT DEFAULT '',
                clinic_id           TEXT DEFAULT ''
            );
        """)

        # Create Table: medicines (matches source of truth)
        db.execute("""
            CREATE TABLE IF NOT EXISTS medicines (
                id                  SERIAL PRIMARY KEY,
                name                TEXT UNIQUE NOT NULL
            );
        """)

        # Create Table: patient_images (matches source of truth)
        db.execute("""
            CREATE TABLE IF NOT EXISTS patient_images (
                id                  TEXT PRIMARY KEY,
                patient_id          TEXT NOT NULL,
                opd_visit_id        TEXT NOT NULL,
                file_path           TEXT NOT NULL,
                image_type          TEXT DEFAULT '',
                sync_status         TEXT DEFAULT 'pending',
                uploaded_at         TEXT,
                created_at          TEXT NOT NULL,
                drive_url           TEXT DEFAULT '',
                user_id             TEXT DEFAULT '',
                clinic_id           TEXT DEFAULT ''
            );
        """)

        # Create Table: symptoms_master (matches source of truth)
        db.execute("""
            CREATE TABLE IF NOT EXISTS symptoms_master (
                id                  SERIAL PRIMARY KEY,
                name                TEXT UNIQUE NOT NULL
            );
        """)

        # Create Table: sync_queue (matches source of truth)
        db.execute("""
            CREATE TABLE IF NOT EXISTS sync_queue (
                id                  SERIAL PRIMARY KEY,
                entity_type         TEXT NOT NULL,
                entity_id           TEXT NOT NULL,
                operation           TEXT DEFAULT 'upsert',
                status              TEXT DEFAULT 'pending',
                retry_count         INTEGER DEFAULT 0,
                last_error          TEXT DEFAULT '',
                created_at          TEXT,
                last_attempt        TEXT,
                clinic_id           TEXT DEFAULT ''
            );
        """)

        # Dynamic postgres columns and table rename migrations:
        db.try_execute("ALTER TABLE patients RENAME COLUMN name TO full_name")
        db.try_execute("ALTER TABLE patients RENAME COLUMN mobile TO mobile_number")
        db.try_execute("ALTER TABLE patients ADD COLUMN alternate_mobile TEXT DEFAULT ''")
        db.try_execute("ALTER TABLE patients ADD COLUMN weight DOUBLE PRECISION DEFAULT NULL")
        db.try_execute("ALTER TABLE patients DROP COLUMN IF EXISTS last_diagnosis")
        db.try_execute("ALTER TABLE patients DROP COLUMN IF EXISTS last_visit_date")

        # Migrating opd_visits columns
        db.try_execute("ALTER TABLE opd_visits RENAME COLUMN visit_date TO visit_datetime")
        db.try_execute("ALTER TABLE opd_visits RENAME COLUMN type TO opd_type")
        db.try_execute("ALTER TABLE opd_visits RENAME COLUMN discount TO discount_value")
        db.try_execute("ALTER TABLE opd_visits ALTER COLUMN discount_value TYPE DOUBLE PRECISION USING (COALESCE(NULLIF(discount_value, ''), '0')::double precision)")
        db.try_execute("ALTER TABLE opd_visits RENAME COLUMN next_visit TO next_visit_date")
        db.try_execute("ALTER TABLE opd_visits RENAME COLUMN follow_up_reason TO followup_status")
        db.try_execute("ALTER TABLE opd_visits ADD COLUMN IF NOT EXISTS image_links TEXT DEFAULT ''")
        db.try_execute("ALTER TABLE opd_visits DROP COLUMN IF EXISTS previous_visit_date")

        # Sync and role columns migration for users and appointments
        for col in ['device_id', 'sync_status', 'last_synced_at']:
            db.try_execute(f"ALTER TABLE patients ADD COLUMN {col} TEXT DEFAULT ''")
            db.try_execute(f"ALTER TABLE opd_visits ADD COLUMN {col} TEXT DEFAULT ''")
            db.try_execute(f"ALTER TABLE appointments ADD COLUMN {col} TEXT DEFAULT ''")
        db.try_execute("ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'doctor'")
        db.execute("""
            CREATE TABLE IF NOT EXISTS appointments (
                id          TEXT PRIMARY KEY,
                patient_id  TEXT DEFAULT '',
                patient_name TEXT DEFAULT '',
                date_time   TEXT NOT NULL,
                notes       TEXT DEFAULT '',
                created_at  TEXT NOT NULL,
                updated_at  TEXT NOT NULL,
                user_id     TEXT DEFAULT '',
                clinic_id   TEXT DEFAULT '',
                device_id   TEXT DEFAULT '',
                sync_status TEXT DEFAULT 'pending',
                last_synced_at TEXT DEFAULT ''
            );
        """)
        db.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id          SERIAL PRIMARY KEY,
                username    TEXT UNIQUE NOT NULL,
                password    TEXT NOT NULL,
                name        TEXT DEFAULT 'Doctor',
                created_at  TEXT NOT NULL,
                clinic_id   TEXT DEFAULT '',
                role        TEXT DEFAULT 'doctor'
            );
        """)
        default_admin_password_hash = hashlib.sha256(
            DEFAULT_ADMIN_PASSWORD.encode()
        ).hexdigest()

        default_clinic_id = 'CLIDEFAULT001'
        now_iso = datetime.utcnow().isoformat()
        db.execute("""
            CREATE TABLE IF NOT EXISTS clinics (
                id          TEXT PRIMARY KEY,
                name        TEXT NOT NULL,
                email       TEXT DEFAULT '',
                phone       TEXT DEFAULT '',
                address     TEXT DEFAULT '',
                created_at  TEXT NOT NULL,
                updated_at  TEXT NOT NULL
            );
        """)
        db.execute("""
            INSERT INTO clinics (id, name, email, phone, address, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (id) DO NOTHING
        """, (default_clinic_id, 'MediHive Clinic', '', '', '', now_iso, now_iso))

        db.execute(
            """
            INSERT INTO users (username, password, name, created_at, clinic_id)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (username) DO UPDATE SET
                password = EXCLUDED.password,
                name = EXCLUDED.name,
                clinic_id = COALESCE(NULLIF(users.clinic_id, ''), EXCLUDED.clinic_id)
            """,
            (
                DEFAULT_ADMIN_USERNAME,
                default_admin_password_hash,
                DEFAULT_ADMIN_NAME,
                now_iso,
                default_clinic_id,
            ),
        )
        db.execute("""
            CREATE TABLE IF NOT EXISTS fcm_tokens (
                id          SERIAL PRIMARY KEY,
                fcm_token   TEXT NOT NULL,
                user_id     TEXT DEFAULT '',
                created_at  TEXT NOT NULL,
                updated_at  TEXT NOT NULL
            );
        """)
        db.execute("""
            CREATE UNIQUE INDEX IF NOT EXISTS idx_fcm_token ON fcm_tokens(fcm_token);
        """)
        db.execute("""
            CREATE INDEX IF NOT EXISTS idx_opd_patient ON opd_visits(patient_id);
        """)
        db.execute("""
            CREATE INDEX IF NOT EXISTS idx_opd_visit ON opd_visits(visit_datetime);
        """)
        db.execute("""
            CREATE INDEX IF NOT EXISTS idx_appt_date ON appointments(date_time);
        """)
        # Source of Truth Indices
        db.execute("""
            CREATE UNIQUE INDEX IF NOT EXISTS ix_opd_visits_opd_id ON opd_visits(opd_id);
        """)
        db.execute("""
            CREATE INDEX IF NOT EXISTS ix_clinic_settings_id ON clinic_settings(id);
        """)
        db.execute("""
            CREATE INDEX IF NOT EXISTS ix_patient_images_id ON patient_images(id);
        """)
        db.execute("""
            CREATE INDEX IF NOT EXISTS ix_sync_queue_id ON sync_queue(id);
        """)
        db.execute("""
            CREATE INDEX IF NOT EXISTS ix_users_id ON users(id);
        """)
        db.execute("""
            CREATE TABLE IF NOT EXISTS deleted_entities (
                id          SERIAL PRIMARY KEY,
                entity_type TEXT NOT NULL,
                entity_id   TEXT NOT NULL,
                deleted_at  TEXT NOT NULL,
                user_id     TEXT DEFAULT '',
                clinic_id   TEXT DEFAULT ''
            );
        """)
        db.execute("""
            CREATE INDEX IF NOT EXISTS idx_deleted_at ON deleted_entities(deleted_at);
        """)
        db.execute("""
            CREATE INDEX IF NOT EXISTS idx_deleted_type_id ON deleted_entities(entity_type, entity_id);
        """)
        db.execute("""
            CREATE TABLE IF NOT EXISTS settings (
                key         TEXT PRIMARY KEY,
                value       TEXT NOT NULL
            );
        """)
        db.execute("""
            CREATE TABLE IF NOT EXISTS device_registry (
                id          SERIAL PRIMARY KEY,
                device_id   TEXT NOT NULL UNIQUE,
                device_name TEXT DEFAULT '',
                clinic_id   TEXT NOT NULL,
                fcm_token   TEXT DEFAULT '',
                app_version TEXT DEFAULT '',
                last_seen   TEXT DEFAULT '',
                created_at  TEXT NOT NULL,
                updated_at  TEXT NOT NULL
            );
        """)
        db.execute("""
            CREATE INDEX IF NOT EXISTS idx_device_registry_clinic ON device_registry(clinic_id);
        """)
        db.execute("""
            CREATE TABLE IF NOT EXISTS cloud_sync_log (
                id              SERIAL PRIMARY KEY,
                clinic_id       TEXT NOT NULL,
                device_id       TEXT DEFAULT '',
                direction       TEXT NOT NULL,
                patients_count  INTEGER DEFAULT 0,
                opd_count       INTEGER DEFAULT 0,
                appointments_count INTEGER DEFAULT 0,
                deleted_count   INTEGER DEFAULT 0,
                status          TEXT DEFAULT 'success',
                error_message   TEXT DEFAULT '',
                created_at      TEXT NOT NULL
            );
        """)
        db.commit()
        _db_initialized = True
    except Exception as e:
        import traceback
        logger.critical("INIT_DB ERROR: %s", str(e))
        logger.critical(traceback.format_exc())
        raise
    finally:
        db.close()


def init_db():
    """Public wrapper for explicit initialization (used by tests and scripts).
    Idempotent — safe to call multiple times."""
    _init_db()
