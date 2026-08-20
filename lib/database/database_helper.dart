import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'schema.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on web.');
    }

    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDir.path, 'medihive.db');
    debugPrint('DATABASE PATH: $dbPath');

    return await openDatabase(
      dbPath,
      version: databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    for (final stmt in createStatements) {
      await db.execute(stmt);
    }

    debugPrint('SQLite database created. Version: $version');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('SQLite migration: $oldVersion → $newVersion');

    for (int v = oldVersion + 1; v <= newVersion; v++) {
      await _applyMigration(db, v);
    }
  }

  Future<void> _applyMigration(Database db, int targetVersion) async {
    switch (targetVersion) {
      case 2:
        await db.execute("ALTER TABLE patients ADD COLUMN updated_at DATETIME");
        await db.execute("ALTER TABLE opd_visits ADD COLUMN updated_at DATETIME");
        debugPrint('Applied migration v2: added updated_at to patients and opd_visits');
        break;
      case 3:
        await db.execute("ALTER TABLE patients ADD COLUMN sync_id TEXT");
        await db.execute("CREATE INDEX ix_patients_sync_id ON patients (sync_id)");
        await db.execute("UPDATE patients SET sync_id = 'P' || SUBSTR('000' || CAST(id AS TEXT), -3, 3) WHERE sync_id IS NULL");
        await db.execute("ALTER TABLE sync_queue ADD COLUMN operation TEXT DEFAULT 'upsert'");
        debugPrint('Applied migration v3: added sync_id to patients and operation to sync_queue');
        break;
      case 4:
        await db.execute(createCloudSyncQueueTable);
        await db.execute(createDeviceRegistrationTable);
        await db.execute(createixCloudSyncQueueStatus);
        await db.execute(createixDeviceRegistrationDeviceId);
        try { await db.execute("ALTER TABLE patients ADD COLUMN clinic_id TEXT"); } catch (_) {}
        try { await db.execute("ALTER TABLE opd_visits ADD COLUMN clinic_id TEXT"); } catch (_) {}
        try { await db.execute("ALTER TABLE sync_queue ADD COLUMN clinic_id TEXT"); } catch (_) {}
        try { await db.execute("ALTER TABLE clinic_settings ADD COLUMN clinic_id TEXT"); } catch (_) {}
        debugPrint('Applied migration v4: added cloud_sync_queue, device_registration, clinic_id columns');
        break;
      case 5:
        try { await db.execute("ALTER TABLE patients ADD COLUMN device_id TEXT"); } catch (_) {}
        try { await db.execute("ALTER TABLE patients ADD COLUMN sync_status TEXT DEFAULT 'pending'"); } catch (_) {}
        try { await db.execute("ALTER TABLE patients ADD COLUMN last_synced_at DATETIME"); } catch (_) {}
        try { await db.execute("ALTER TABLE opd_visits ADD COLUMN device_id TEXT"); } catch (_) {}
        try { await db.execute("ALTER TABLE opd_visits ADD COLUMN sync_status TEXT DEFAULT 'pending'"); } catch (_) {}
        try { await db.execute("ALTER TABLE opd_visits ADD COLUMN last_synced_at DATETIME"); } catch (_) {}
        debugPrint('Applied migration v5: added device_id, sync_status, last_synced_at to patients and opd_visits');
        break;
      case 6:
        try { await db.execute("ALTER TABLE patients ADD COLUMN weight FLOAT"); } catch (_) {}
        debugPrint('Applied migration v6: added weight column to patients');
        break;
      case 7:
        try { await db.execute("ALTER TABLE opd_visits ADD COLUMN blood_group VARCHAR"); } catch (_) {}
        try { await db.execute("ALTER TABLE opd_visits ADD COLUMN image_links TEXT"); } catch (_) {}
        try { await db.execute("ALTER TABLE opd_visits ADD COLUMN user_id TEXT"); } catch (_) {}
        try { await db.execute("ALTER TABLE patient_images ADD COLUMN user_id TEXT"); } catch (_) {}
        try { await db.execute("ALTER TABLE patient_images ADD COLUMN clinic_id TEXT"); } catch (_) {}
        try { await db.execute("ALTER TABLE calendar_notes ADD COLUMN user_id TEXT"); } catch (_) {}
        try { await db.execute("ALTER TABLE calendar_notes ADD COLUMN clinic_id TEXT"); } catch (_) {}
        try { await db.execute("ALTER TABLE clinic_settings ADD COLUMN clinic_id TEXT"); } catch (_) {}
        try { await db.execute("ALTER TABLE users ADD COLUMN name VARCHAR"); } catch (_) {}
        try { await db.execute("ALTER TABLE users ADD COLUMN clinic_id TEXT"); } catch (_) {}
        try { await db.execute("ALTER TABLE users ADD COLUMN role VARCHAR DEFAULT 'doctor'"); } catch (_) {}
        try { await db.execute("ALTER TABLE users ADD COLUMN device_id TEXT"); } catch (_) {}
        try { await db.execute("ALTER TABLE users ADD COLUMN sync_status TEXT DEFAULT 'pending'"); } catch (_) {}
        try { await db.execute("ALTER TABLE users ADD COLUMN last_synced_at DATETIME"); } catch (_) {}
        debugPrint('Applied migration v7: aligned all tables to 100% cloud parity (blood_group, image_links, user_id, clinic_id, users fields)');
        break;
      default:
        debugPrint('No migration defined for version $targetVersion');
    }
  }

  Future<bool> isInitialized() async {
    try {
      await database;
      return true;
    } catch (e) {
      debugPrint('DatabaseHelper.isInitialized error: $e');
      return false;
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
