"""
clear_cloud_and_sheet_data.py
==============================
Standalone cleanup script for MediHive Marathi.
Deletes ALL previous patient and OPD data from:
  1. Google Sheet tabs ('opd_visits' and 'calendar_notes' — keeping headers intact)
  2. Cloud PostgreSQL database (patients, opd_visits, appointments, deleted_entities, sync_queue, cloud_sync_log)
  3. Local backend SQLite database (patients, opd_records/opd_visits, appointments, deleted_entities, sync_queue, cloud_sync_log)

PRESERVED TABLES (NOT deleted):
  - users (admin account)
  - clinics (clinic info)
  - clinic_settings (doctor and clinic preferences)
  - medicines & symptoms_master (master lists)

Usage:
  python clear_cloud_and_sheet_data.py --yes
"""

import sys
import os
import json
import sqlite3

# Add backend directory to sys.path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))

def clear_google_sheets():
    print("\n[1/3] Clearing Google Sheets data rows...")
    try:
        from sheets_utils import (
            _get_client,
            _get_opd_worksheet,
            _get_calendar_worksheet,
            _apply_opd_formatting,
            HEADERS,
            CALENDAR_HEADERS,
            _col_letter,
        )

        client = _get_client()

        # 1. Clear OPD Visits tab
        opd_ws = _get_opd_worksheet(client)
        all_opd_values = opd_ws.get_all_values()
        if len(all_opd_values) > 1:
            row_count = len(all_opd_values) - 1
            for r in range(len(all_opd_values), 1, -1):
                opd_ws.delete_rows(r)
            print(f"  -> Cleared {row_count} data rows from 'opd_visits' tab.")
        else:
            print("  -> 'opd_visits' tab is already empty.")

        end_col = _col_letter(len(HEADERS) - 1)
        opd_ws.update(range_name=f"A1:{end_col}1", values=[HEADERS])
        try:
            _apply_opd_formatting(opd_ws)
        except Exception as e:
            print(f"  -> Note on formatting: {e}")

        # 2. Clear Calendar Notes tab
        try:
            cal_ws = _get_calendar_worksheet(client)
            cal_values = cal_ws.get_all_values()
            if len(cal_values) > 1:
                cal_row_count = len(cal_values) - 1
                for r in range(len(cal_values), 1, -1):
                    cal_ws.delete_rows(r)
                print(f"  -> Cleared {cal_row_count} data rows from 'calendar_notes' tab.")
            else:
                print("  -> 'calendar_notes' tab is already empty.")
            cal_ws.update(range_name="A1:B1", values=[CALENDAR_HEADERS])
        except Exception as e:
            print(f"  -> Calendar tab clear note: {e}")

        print("  -> Google Sheets cleared successfully.")
    except Exception as e:
        print(f"  [WARNING] Google Sheets cleanup error: {e}")


def clear_postgresql():
    print("\n[2/3] Clearing PostgreSQL database...")
    try:
        from database import get_db

        db = get_db()
        tables_to_clear = [
            'sync_queue',
            'cloud_sync_log',
            'opd_visits',
            'patients',
            'appointments',
            'deleted_entities',
        ]

        for table in tables_to_clear:
            try:
                db.execute(f"DELETE FROM {table}")
                print(f"  -> Cleared table '{table}' in PostgreSQL.")
            except Exception as te:
                print(f"  -> Could not clear table '{table}' (might not exist): {te}")
                db.rollback()

        # Also try clearing patient_images or calendar_notes if needed
        try:
            db.execute("DELETE FROM calendar_notes")
            print("  -> Cleared table 'calendar_notes' in PostgreSQL.")
        except Exception:
            db.rollback()

        db.commit()
        db.close()
        print("  -> PostgreSQL tables cleared successfully.")
    except Exception as e:
        print(f"  [WARNING] PostgreSQL cleanup error: {e}")


def clear_local_sqlite():
    print("\n[3/3] Clearing local SQLite database (if present)...")
    db_path = os.path.join(os.path.dirname(__file__), 'backend', 'medihive.db')
    if not os.path.exists(db_path):
        print("  -> Local backend medihive.db not found (skipped).")
        return

    try:
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()
        for t in ['patients', 'opd_records', 'opd_visits', 'appointments', 'deleted_entities', 'sync_queue', 'cloud_sync_log']:
            try:
                cur.execute(f'DELETE FROM "{t}"')
                print(f"  -> Cleared local SQLite table '{t}'.")
            except Exception:
                pass
        conn.commit()
        conn.close()
        print("  -> Local SQLite database cleared successfully.")
    except Exception as e:
        print(f"  [WARNING] SQLite cleanup error: {e}")


def clear_google_drive():
    print("\n[4/4] Clearing Google Drive folder...")
    try:
        from drive_utils import get_drive_service
        from config import DRIVE_ROOT_FOLDER_ID

        if not DRIVE_ROOT_FOLDER_ID:
            print("  [WARNING] DRIVE_ROOT_FOLDER_ID is not configured.")
            return

        service = get_drive_service()
        query = f"'{DRIVE_ROOT_FOLDER_ID}' in parents and trashed = false"
        page_token = None
        deleted_count = 0

        while True:
            response = service.files().list(
                q=query,
                spaces='drive',
                fields='nextPageToken, files(id, name)',
                pageToken=page_token
            ).execute()

            files = response.get('files', [])
            for f in files:
                file_id = f.get('id')
                file_name = f.get('name')
                try:
                    service.files().delete(fileId=file_id).execute()
                    print(f"  -> Deleted Drive file: {file_name}")
                    deleted_count += 1
                except Exception as de:
                    print(f"  -> Could not delete {file_name}: {de}")

            page_token = response.get('nextPageToken', None)
            if page_token is None:
                break

        if deleted_count == 0:
            print("  -> Google Drive folder is already empty.")
        else:
            print(f"  -> Successfully deleted {deleted_count} file(s) from Google Drive folder.")

    except Exception as e:
        print(f"  [WARNING] Google Drive cleanup error: {e}")


def main():
    print("=" * 60)
    print("  MediHive — Clear Cloud, Google Sheet & Drive Data")
    print("=" * 60)

    if '--yes' not in sys.argv:
        confirm = input("Type 'YES' to proceed with wiping all patient/OPD data: ")
        if confirm != "YES":
            print("Aborted.")
            return

    clear_google_sheets()
    clear_postgresql()
    clear_local_sqlite()
    clear_google_drive()

    print("\n" + "=" * 60)
    print("  CLEANUP COMPLETE: Fresh start ready!")
    print("=" * 60)


if __name__ == '__main__':
    main()
