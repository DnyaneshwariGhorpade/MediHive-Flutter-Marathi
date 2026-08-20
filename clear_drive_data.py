"""
clear_drive_data.py
===================
Standalone script to purge all files from the MediHive Google Drive folder.
Deletes all files inside DRIVE_ROOT_FOLDER_ID.

Usage:
  python clear_drive_data.py --yes
"""

import sys
import os

# Add backend directory to sys.path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))

def clear_google_drive():
    print("\nPurging Google Drive folder...")
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
                    print(f"  -> Deleted Drive file: {file_name} ({file_id})")
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
    print("  MediHive — Clear Google Drive Data")
    print("=" * 60)

    if '--yes' not in sys.argv:
        confirm = input("Type 'YES' to proceed with wiping all files from Google Drive: ")
        if confirm != "YES":
            print("Aborted.")
            return

    clear_google_drive()
    print("\n" + "=" * 60)
    print("  GOOGLE DRIVE PURGE COMPLETE!")
    print("=" * 60)

if __name__ == '__main__':
    main()
