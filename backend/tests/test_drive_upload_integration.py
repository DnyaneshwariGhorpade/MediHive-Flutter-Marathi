"""
Integration test: Google Drive OPD image upload + Google Sheets image links.

Uploads a sample image to DRIVE_ROOT_FOLDER_ID via
upload_image_fileobj_to_drive(), verifies the file exists in the folder,
verifies the canonical share URL, then deletes the file.

Also verifies build_sheet_row_data() maps image links into the
"Image Links" column (AA) of the OPD sheet row.

Requires live Google credentials (drive_token.json / DRIVE_TOKEN_JSON or
GOOGLE_CREDENTIALS_JSON / credentials.json) — skipped otherwise.

Run with: python -m pytest backend/tests/test_drive_upload_integration.py -v
"""

import io
import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from drive_utils import get_drive_service, upload_image_fileobj_to_drive
from config import DRIVE_ROOT_FOLDER_ID


def _google_available():
    try:
        get_drive_service()
        return True
    except Exception:
        return False


@unittest.skipUnless(_google_available(), "Google Drive credentials not available")
class TestDriveUploadIntegration(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.service = get_drive_service()

    def test_01_upload_verify_delete_sample_image(self):
        self.assertTrue(DRIVE_ROOT_FOLDER_ID, "DRIVE_ROOT_FOLDER_ID is empty")

        sample_bytes = b"\xff\xd8\xff\xe0" + b"\x00" * 512 + b"\xff\xd9"
        upload_token = f"itest_{os.getpid()}_{int(__import__('time').time() * 1000)}.jpg"

        class _FakeFileStorage:
            filename = upload_token
            content_type = 'image/jpeg'

            def read(self):
                return sample_bytes

        url = upload_image_fileobj_to_drive("ITEST-OPD-001", _FakeFileStorage(), 1)
        self.assertIsNotNone(url, "upload_image_fileobj_to_drive returned None")
        self.assertIn("https://drive.google.com/file/d/", url)
        self.assertIn("view?usp=sharing", url)

        file_id = url.split("/file/d/")[1].split("/")[0]
        self.assertGreater(len(file_id), 5)

        try:
            # Verify the file exists inside DRIVE_ROOT_FOLDER_ID.
            # upload_image_fileobj_to_drive prefixes names as {opd}_{index:02d}_{filename}.
            expected_name = f"ITEST-OPD-001_01_{upload_token}"
            files = self.service.files().list(
                q=f"name = '{expected_name}' and '{DRIVE_ROOT_FOLDER_ID}' in parents and trashed = false",
                fields="files(id, name, webViewLink)",
            ).execute().get("files", [])
            self.assertEqual(len(files), 1, f"Expected 1 file in Drive folder, got {len(files)}")
            self.assertEqual(files[0]["name"], expected_name)
            self.assertEqual(files[0]["id"], file_id)

            # Verify public permission (anyone:reader)
            perms = self.service.permissions().list(fileId=file_id, fields="permissions(type, role)").execute()
            self.assertTrue(
                any(p["type"] == "anyone" and p["role"] == "reader" for p in perms.get("permissions", [])),
                "File does not have anyone:reader permission",
            )
        finally:
            self.service.files().delete(fileId=file_id).execute()

    def test_02_sheet_row_data_includes_image_links(self):
        from routes.opd import build_sheet_row_data

        opd = {
            'id': 'ITEST-OPD-002',
            'patient_id': 'P001',
            'visit_datetime': '2026-08-20T10:00:00',
            'opd_type': 'consultation',
            'consultation_fee': 100,
            'diagnosis': 'Test',
        }
        patient = {'full_name': 'Test Patient', 'mobile': '9999999999', 'gender': 'Male', 'age': 30}
        urls = ["https://drive.google.com/file/d/ABC123/view?usp=sharing"]

        row = build_sheet_row_data(opd, patient, urls)
        self.assertEqual(row['Image Links'], urls)

        # Preserves existing DB image_links when no new drive_urls are passed
        opd_with_links = dict(opd, image_links="https://drive.google.com/file/d/ABC123/view?usp=sharing\n")
        row2 = build_sheet_row_data(opd_with_links, patient, [])
        self.assertEqual(row2['Image Links'], ["https://drive.google.com/file/d/ABC123/view?usp=sharing"])

    def test_03_upload_requires_root_folder(self):
        import drive_utils as du
        original = du.DRIVE_ROOT_FOLDER_ID
        try:
            du.DRIVE_ROOT_FOLDER_ID = ""

            class _FakeFileStorage:
                filename = "x.jpg"
                content_type = 'image/jpeg'

                def read(self):
                    return b"data"

            with self.assertRaises(ValueError):
                upload_image_fileobj_to_drive("ITEST-OPD-003", _FakeFileStorage(), 1)
        finally:
            du.DRIVE_ROOT_FOLDER_ID = original


if __name__ == "__main__":
    unittest.main()