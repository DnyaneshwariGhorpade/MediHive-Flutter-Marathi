const int databaseVersion = 7;

const String tablePatients = 'patients';
const String tableOpdVisits = 'opd_visits';
const String tableCalendarNotes = 'calendar_notes';
const String tableClinicSettings = 'clinic_settings';
const String tableUsers = 'users';
const String tableMedicines = 'medicines';
const String tableSymptomsMaster = 'symptoms_master';
const String tablePatientImages = 'patient_images';
const String tableSyncQueue = 'sync_queue';
const String tableCloudSyncQueue = 'cloud_sync_queue';
const String tableDeviceRegistration = 'device_registration';

String get createPatientsTable => '''
  CREATE TABLE $tablePatients (
    id INTEGER NOT NULL,
    sync_id TEXT,
    full_name VARCHAR NOT NULL,
    mobile_number VARCHAR NOT NULL,
    alternate_mobile VARCHAR,
    gender VARCHAR NOT NULL,
    dob DATE,
    age INTEGER,
    blood_group VARCHAR,
    address VARCHAR,
    clinic_id TEXT,
    device_id TEXT,
    sync_status TEXT DEFAULT 'pending',
    last_synced_at DATETIME,
    created_at DATETIME,
    updated_at DATETIME,
    weight FLOAT,
    PRIMARY KEY (id)
  )
''';

String get createOpdVisitsTable => '''
  CREATE TABLE $tableOpdVisits (
    id INTEGER NOT NULL,
    opd_id VARCHAR NOT NULL,
    patient_id INTEGER NOT NULL,
    visit_datetime DATETIME NOT NULL,
    opd_type VARCHAR,
    charge_type VARCHAR,
    diagnosis VARCHAR,
    symptoms VARCHAR,
    clinical_notes VARCHAR,
    consultation_fee FLOAT,
    medicine_fee FLOAT,
    panchakarma_fee FLOAT,
    total_fee FLOAT,
    discount_type VARCHAR,
    discount_value FLOAT,
    payment_mode VARCHAR,
    next_visit_date DATE,
    followup_status VARCHAR,
    clinic_id TEXT,
    device_id TEXT,
    user_id TEXT,
    blood_group VARCHAR,
    image_links TEXT,
    sync_status TEXT DEFAULT 'pending',
    last_synced_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME,
    medicines TEXT,
    panchakarma_notes TEXT,
    PRIMARY KEY (id),
    FOREIGN KEY (patient_id) REFERENCES $tablePatients (id)
  )
''';

String get createCalendarNotesTable => '''
  CREATE TABLE $tableCalendarNotes (
    id INTEGER NOT NULL,
    note_date DATE NOT NULL,
    note_text TEXT,
    user_id TEXT,
    clinic_id TEXT,
    created_at DATETIME,
    updated_at DATETIME,
    PRIMARY KEY (id),
    UNIQUE (note_date)
  )
''';

String get createClinicSettingsTable => '''
  CREATE TABLE $tableClinicSettings (
    id INTEGER NOT NULL,
    doctor_name VARCHAR(255),
    doctor_email VARCHAR(255),
    doctor_contact VARCHAR(50),
    doctor_license_no VARCHAR(100),
    doctor_photo_path VARCHAR(500),
    clinic_name VARCHAR(255),
    clinic_logo_path VARCHAR(500),
    clinic_address TEXT,
    clinic_phone VARCHAR(50),
    website VARCHAR(255),
    operating_hours VARCHAR(255),
    smtp_email VARCHAR(255),
    smtp_password VARCHAR(255),
    smtp_server VARCHAR(255),
    smtp_port VARCHAR(10),
    clinic_id TEXT,
    created_at DATETIME,
    updated_at DATETIME,
    PRIMARY KEY (id)
  )
''';

String get createUsersTable => '''
  CREATE TABLE $tableUsers (
    id INTEGER NOT NULL,
    username VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR,
    email VARCHAR(255) NOT NULL,
    clinic_id TEXT,
    role VARCHAR DEFAULT 'doctor',
    device_id TEXT,
    sync_status TEXT DEFAULT 'pending',
    last_synced_at DATETIME,
    created_at DATETIME,
    reset_otp VARCHAR(10),
    otp_expiry DATETIME,
    PRIMARY KEY (id),
    UNIQUE (username)
  )
''';

String get createMedicinesTable => '''
  CREATE TABLE $tableMedicines (
    id INTEGER NOT NULL,
    name VARCHAR NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (name)
  )
''';

String get createSymptomsMasterTable => '''
  CREATE TABLE $tableSymptomsMaster (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
  )
''';

String get createPatientImagesTable => '''
  CREATE TABLE $tablePatientImages (
    id INTEGER NOT NULL,
    patient_id INTEGER NOT NULL,
    opd_visit_id INTEGER NOT NULL,
    file_path VARCHAR NOT NULL,
    image_type VARCHAR,
    sync_status VARCHAR,
    uploaded_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    drive_url TEXT,
    user_id TEXT,
    clinic_id TEXT,
    PRIMARY KEY (id),
    FOREIGN KEY (patient_id) REFERENCES $tablePatients (id),
    FOREIGN KEY (opd_visit_id) REFERENCES $tableOpdVisits (id)
  )
''';

String get createSyncQueueTable => '''
  CREATE TABLE $tableSyncQueue (
    id INTEGER NOT NULL,
    entity_type VARCHAR(20) NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    operation VARCHAR(20) DEFAULT 'upsert',
    status VARCHAR(20),
    retry_count INTEGER,
    last_error TEXT,
    clinic_id TEXT,
    created_at DATETIME,
    last_attempt DATETIME,
    PRIMARY KEY (id)
  )
''';

String get createCloudSyncQueueTable => '''
  CREATE TABLE $tableCloudSyncQueue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    table_name TEXT NOT NULL,
    operation TEXT NOT NULL,
    record_id TEXT NOT NULL,
    payload TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    sync_status TEXT DEFAULT 'pending',
    retry_count INTEGER DEFAULT 0
  )
''';

String get createDeviceRegistrationTable => '''
  CREATE TABLE $tableDeviceRegistration (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id TEXT NOT NULL UNIQUE,
    device_name TEXT,
    clinic_id TEXT,
    fcm_token TEXT,
    app_version TEXT,
    last_seen TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
''';

String get createixPatientsId => '''
  CREATE INDEX ix_patients_id ON $tablePatients (id)
''';

String get createixPatientsSyncId => '''
  CREATE INDEX ix_patients_sync_id ON $tablePatients (sync_id)
''';

String get createixOpdVisitsId => '''
  CREATE INDEX ix_opd_visits_id ON $tableOpdVisits (id)
''';

String get createixOpdVisitsOpdId => '''
  CREATE UNIQUE INDEX ix_opd_visits_opd_id ON $tableOpdVisits (opd_id)
''';

String get createixPatientImagesId => '''
  CREATE INDEX ix_patient_images_id ON $tablePatientImages (id)
''';

String get createixSyncQueueId => '''
  CREATE INDEX ix_sync_queue_id ON $tableSyncQueue (id)
''';

String get createixUsersId => '''
  CREATE INDEX ix_users_id ON $tableUsers (id)
''';

String get createixClinicSettingsId => '''
  CREATE INDEX ix_clinic_settings_id ON $tableClinicSettings (id)
''';

String get createixCloudSyncQueueStatus => '''
  CREATE INDEX ix_cloud_sync_queue_status ON $tableCloudSyncQueue (sync_status)
''';

String get createixDeviceRegistrationDeviceId => '''
  CREATE UNIQUE INDEX ix_device_registration_device_id ON $tableDeviceRegistration (device_id)
''';

List<String> get createStatements => [
  createPatientsTable,
  createOpdVisitsTable,
  createCalendarNotesTable,
  createClinicSettingsTable,
  createUsersTable,
  createMedicinesTable,
  createSymptomsMasterTable,
  createPatientImagesTable,
  createSyncQueueTable,
  createCloudSyncQueueTable,
  createDeviceRegistrationTable,
  createixPatientsId,
  createixPatientsSyncId,
  createixOpdVisitsId,
  createixOpdVisitsOpdId,
  createixPatientImagesId,
  createixSyncQueueId,
  createixUsersId,
  createixClinicSettingsId,
  createixCloudSyncQueueStatus,
  createixDeviceRegistrationDeviceId,
];
