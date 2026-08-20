import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'api_service.dart';
import 'connectivity_service.dart';
import 'sync_refresh_bus.dart';
import '../utils/sync_id_generator.dart';
import '../models/appointment_model.dart';
import '../repositories/patient_repository.dart';
import '../repositories/opd_record_repository.dart';
import '../repositories/sync_queue_repository.dart';
import '../repositories/patient_images_repository.dart';
import '../repositories/device_registration_repository.dart';
import '../repositories/clinic_settings_repository.dart';
import '../repositories/calendar_notes_repository.dart';
import '../repositories/medicines_repository.dart';
import '../repositories/symptoms_master_repository.dart';
import '../database/database_helper.dart';
import 'event_notification_service.dart';
import 'local_notification_service.dart';
import '../providers/notification_provider.dart';
import 'dart:math' show Random;

enum SyncState {
  offline,
  syncing,
  synced,
  error,
}

class SyncManager extends ChangeNotifier {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  final ConnectivityService _connectivity = ConnectivityService();
  final PatientRepository _patientRepo = PatientRepository();
  final OpdRecordRepository _opdRepo = OpdRecordRepository();
  final SyncQueueRepository _syncQueueRepo = SyncQueueRepository();
  final PatientImagesRepository _imagesRepo = PatientImagesRepository();
  final DeviceRegistrationRepository _deviceRegRepo = DeviceRegistrationRepository();
  final ClinicSettingsRepository _settingsRepo = ClinicSettingsRepository();
  final CalendarNotesRepository _notesRepo = CalendarNotesRepository();
  final MedicinesRepository _medicinesRepo = MedicinesRepository();
  final SymptomsMasterRepository _symptomsRepo = SymptomsMasterRepository();

  SyncState _syncState = SyncState.synced;
  bool _pendingSyncRequested = false;
  Timer? _debounceTimer;
  Timer? _pollTimer;
  Timer? _forceDebounce;
  StreamSubscription<bool>? _connectivitySubscription;
  int _syncCount = 0;
  int _lastSyncApplied = 0;
  String? _deviceId;

  SyncState get syncState => _syncState;
  bool get isSyncing => _syncState == SyncState.syncing;
  int get syncCount => _syncCount;
  int get lastSyncApplied => _lastSyncApplied;
  String? get deviceId => _deviceId;

  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal() {
    _init();
  }

  Future<void> _init() async {
    _deviceId = await _loadOrCreateDeviceId();
    try {
      _connectivitySubscription = _connectivity.isConnected.listen((connected) {
        if (!connected) {
          _syncState = SyncState.offline;
          notifyListeners();
        } else {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(seconds: 3), _trySync);
        }
      });
    } catch (_) {}
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      SyncRefreshBus().notifyDataChanged();
      _trySync();
    });
    Timer(const Duration(seconds: 5), _trySync);
    await _registerDevice();
  }

  Future<void> _registerDevice() async {
    if (_deviceId == null) return;
    try {
      await ApiService.cloudRegisterDevice(
        deviceId: _deviceId!,
        deviceName: _getDeviceName(),
        clinicId: await _loadClinicId(),
        appVersion: '1.0.0',
        fcmToken: null,
      );
    } catch (_) {}
  }

  // FCM removed — keep method stub so callers don't break.
  Future<void> registerDeviceWithToken(String fcmToken) async {}

  Future<String> _loadClinicId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('clinic_id') ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _trySync() async {
    if (!_connectivity.currentStatus) {
      debugPrint('SYNC SKIP: no connectivity');
      return;
    }
    if (_syncState == SyncState.syncing) {
      debugPrint('SYNC SKIP: already syncing');
      return;
    }

    debugPrint('SYNC START: state=$_syncState');
    _syncState = SyncState.syncing;
    notifyListeners();

    try {
      await ApiService.ensureToken();
      debugPrint('SYNC: token ensured, starting _syncWithBackend');
      await _syncWithBackend();
      _syncCount++;
      _syncState = SyncState.synced;
      debugPrint('SYNC SUCCESS: count=$_syncCount');
      notifyListeners();

      if (_pendingSyncRequested) {
        _pendingSyncRequested = false;
        _trySync();
      }
    } catch (e) {
      debugPrint('SYNC ERROR: $e');
      _syncState = SyncState.error;
      notifyListeners();
    }
  }

  Future<void> _syncWithBackend() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString('last_flask_sync') ?? '';

    // ── Push ──
    final pending = await _syncQueueRepo.getPending();
    debugPrint('SYNC PUSH: ${pending.length} pending queue entries');
    final pushPatients = <Map<String, dynamic>>[];
    final pushOpd = <Map<String, dynamic>>[];
    final pushAppts = <Map<String, dynamic>>[];
    final pushSettings = <Map<String, dynamic>>[];
    final pushNotes = <Map<String, dynamic>>[];
    final pushMedicines = <Map<String, dynamic>>[];
    final pushSymptoms = <Map<String, dynamic>>[];
    final deletedEntities = <Map<String, String>>[];

    for (final entry in pending) {
      final entityType = entry['entity_type'] as String? ?? '';
      final entityId = entry['entity_id'] as String? ?? '';
      final operation = entry['operation'] as String? ?? 'upsert';

      if (operation == 'delete') {
        deletedEntities.add({'entity_type': entityType, 'entity_id': entityId});
        continue;
      }

      if (entityType == 'patient') {
        final row = await _patientRepo.getBySyncId(entityId);
        if (row != null) {
          pushPatients.add(_patientRowToMap(row));
        } else {
          debugPrint('SYNC WARNING: patient sync_id=$entityId not found in DB');
        }
      } else if (entityType == 'opd_visit') {
        final row = await _opdRepo.getByOpdId(entityId);
        if (row != null) {
          final localPatientId = row['patient_id'] as int? ?? 0;
          final patRow = await _patientRepo.getById(localPatientId);
          final patSyncId = patRow != null 
              ? (patRow['sync_id'] as String? ?? 'P${localPatientId.toString().padLeft(3, '0')}') 
              : 'P${localPatientId.toString().padLeft(3, '0')}';
          pushOpd.add(_opdRowToMap(row, patSyncId));
        } else {
          debugPrint('SYNC WARNING: opd_visit opd_id=$entityId not found in DB');
        }
      } else if (entityType == 'clinic_settings') {
        final row = await _settingsRepo.getFirst();
        if (row != null) {
          pushSettings.add(row);
        } else {
          debugPrint('SYNC WARNING: clinic_settings not found in DB');
        }
      } else if (entityType == 'calendar_note') {
        final row = await _notesRepo.getByDate(entityId);
        if (row != null) {
          pushNotes.add(row);
        } else {
          pushNotes.add({
            'note_date': entityId,
            'note_text': '[]',
          });
        }
      } else if (entityType == 'medicine') {
        pushMedicines.add({'name': entityId});
      } else if (entityType == 'symptom') {
        pushSymptoms.add({'name': entityId});
      }
    }

    debugPrint('SYNC PUSH DATA: patients=${pushPatients.length} opd=${pushOpd.length} appts=${pushAppts.length} deleted=${deletedEntities.length} settings=${pushSettings.length} notes=${pushNotes.length} medicines=${pushMedicines.length} symptoms=${pushSymptoms.length}');

    try {
      final apptBox = Hive.box<AppointmentModel>('appointments');
      for (final a in apptBox.values) {
        if (!a.isSynced) {
          pushAppts.add(a.toJson());
        }
      }
    } catch (_) {}

    final pushCount = pushPatients.length +
        pushOpd.length +
        pushAppts.length +
        deletedEntities.length +
        pushSettings.length +
        pushNotes.length +
        pushMedicines.length +
        pushSymptoms.length;

    if (pushPatients.isNotEmpty || pushOpd.isNotEmpty || pushAppts.isNotEmpty || deletedEntities.isNotEmpty || pushSettings.isNotEmpty || pushNotes.isNotEmpty || pushMedicines.isNotEmpty || pushSymptoms.isNotEmpty) {
      debugPrint('SYNC PUSHING to backend...');
      final response = await ApiService.syncPush(
        patients: pushPatients,
        opdRecords: pushOpd,
        appointments: pushAppts,
        deletedEntities: deletedEntities,
        deviceId: _deviceId ?? '',
        clinicSettings: pushSettings,
        calendarNotes: pushNotes,
        medicines: pushMedicines,
        symptoms: pushSymptoms,
      );

      debugPrint('SYNC PUSH response: ${response.keys.toList()}');
      final tempMapped = response['temp_ids_mapped'] as Map<String, dynamic>? ?? {};
      for (final entry in tempMapped.entries) {
        await _patientRepo.updateSyncId(entry.key, entry.value as String);
      }

      final conflicts = response['conflicts'] as List<dynamic>? ?? [];
      if (conflicts.isNotEmpty) {
        debugPrint('SYNC WARNING: Conflicts detected during push sync on server:');
        for (final c in conflicts) {
          debugPrint('  [CONFLICT] $c');
        }
      }

      final missingPatients = response['missing_patients'] as List<dynamic>? ?? [];
      if (missingPatients.isNotEmpty) {
        debugPrint('SYNC WARNING: Server requested self-healing for missing patients: $missingPatients');
        final db = await DatabaseHelper().database;
        bool queuedAny = false;
        for (final pId in missingPatients) {
          final patientIdStr = pId.toString();
          // Check if already pending in the sync queue to avoid duplicates
          final existingQueue = await db.query(
            'sync_queue',
            where: 'entity_type = ? AND entity_id = ? AND (status = ? OR status IS NULL)',
            whereArgs: ['patient', patientIdStr, 'pending'],
          );
          if (existingQueue.isEmpty) {
            await _syncQueueRepo.insert({
              'id': DateTime.now().microsecondsSinceEpoch + Random().nextInt(1000),
              'entity_type': 'patient',
              'entity_id': patientIdStr,
              'operation': 'upsert',
              'status': 'pending',
              'created_at': DateTime.now().toIso8601String(),
            });
            debugPrint('SYNC: Re-queued patient $patientIdStr for self-healing upload.');
            queuedAny = true;
          }
        }
        if (queuedAny) {
          _pendingSyncRequested = true;
        }
      }

      final now = DateTime.now().toIso8601String();
      for (final entry in pending) {
        await _syncQueueRepo.update(entry['id'] as int, {
          'status': 'synced',
          'last_attempt': now,
        });
      }

      try {
        final box = Hive.box<AppointmentModel>('appointments');
        for (final a in pushAppts) {
          final id = a['id'] as String;
          final existing = box.get(id);
          if (existing != null) {
            box.put(id, existing.copyWith(isSynced: true, updatedAt: DateTime.now()));
          }
        }
      } catch (_) {}
    }

    // ── Upload images ──
    await _uploadPendingImages();

    // ── Pull ──
    final pullSync = lastSync.isEmpty ? '2000-01-01T00:00:00' : lastSync;
    try {
      final data = await ApiService.syncPull(pullSync);

      final pullApplied =
          await _applyRemotePatients(data['patients'] as List<dynamic>? ?? []) +
              await _applyRemoteOpdRecords(data['opd_records'] as List<dynamic>? ?? []) +
              await _applyRemoteAppointments(data['appointments'] as List<dynamic>? ?? []) +
              await _applyRemoteClinicSettings(data['clinic_settings'] as List<dynamic>? ?? []) +
              await _applyRemoteCalendarNotes(data['calendar_notes'] as List<dynamic>? ?? []) +
              await _applyRemoteMedicines(data['medicines'] as List<dynamic>? ?? []) +
              await _applyRemoteSymptoms(data['symptoms'] as List<dynamic>? ?? []) +
              await _applyRemoteDeletes(data['deleted_entities'] as List<dynamic>? ?? []);
      _lastSyncApplied = pushCount + pullApplied;

      await prefs.setString(
        'last_flask_sync',
        data['server_time']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
      );

      // Live refresh: when remote changes were applied, tell all in-memory
      // providers to reload from local storage so the UI updates immediately.
      if (pullApplied > 0 || pushCount > 0) {
        SyncRefreshBus().notifyDataChanged();
      }
    } catch (e) {
      debugPrint('SYNC pull failed (non-fatal): $e');
    }
  }

  Future<void> _uploadPendingImages() async {
    try {
      final docBox = Hive.box('opd_documents');
      for (final key in docBox.keys) {
        final opdId = key.toString();
        final raw = docBox.get(opdId);
        if (raw == null) continue;

        try {
          // Decode in-memory bytes and upload directly — works on Web,
          // Android, iOS and Windows without touching the filesystem.
          final bytes = base64Decode(raw.toString());
          final response = await ApiService.cloudUploadImagesBytes(opdId, [bytes]);
          final urls = (response['drive_urls'] as List<dynamic>?)?.map((u) => u.toString()).toList() ?? [];
          if (urls.isNotEmpty) {
            final opdRow = await _opdRepo.getByOpdId(opdId);
            final localOpdId = opdRow?['id'] as int? ?? 0;
            final localPatientId = opdRow?['patient_id'] as int? ?? 0;
            final normUrls = urls.map(_normalizeDriveUrl).toList();
            for (final u in normUrls) {
              final maxImgId = await _imagesRepo.getMaxId();
              await _imagesRepo.insert({
                'id': maxImgId + 1,
                'patient_id': localPatientId,
                'opd_visit_id': localOpdId,
                'file_path': null,
                'image_type': 'document',
                'sync_status': 'synced',
                'uploaded_at': DateTime.now().toIso8601String(),
                'created_at': DateTime.now().toIso8601String(),
                'drive_url': u,
              });
            }
            // Mirror the Drive URLs back into the local OPD record so the
            // patient card/details can render the attachments immediately.
            if (localOpdId > 0) {
              await _opdRepo.update(localOpdId, {'image_links': normUrls.join('\n')});
            }
          }
          await docBox.delete(opdId);
        } catch (e) {
          debugPrint('SYNC image upload failed for $opdId: $e');
        }
      }
    } catch (e) {
      debugPrint('SYNC image upload error: $e');
    }
  }

  Future<int> _applyRemotePatients(List<dynamic> remotePatients) async {
    var applied = 0;
    for (final json in remotePatients) {
      try {
        final map = Map<String, dynamic>.from(json as Map);
        final remoteId = map['id']?.toString() ?? '';
        final remoteUpdated = _parseRemoteTimestamp(map['updated_at']?.toString());
        final existing = await _patientRepo.getBySyncId(remoteId);
        final localUpdated = DateTime.tryParse(
          existing?['updated_at'] as String? ?? existing?['created_at'] as String? ?? '',
        );

        if (existing == null || (remoteUpdated != null && localUpdated != null && remoteUpdated.isAfter(localUpdated))) {
          if (existing != null) {
            await _patientRepo.update(existing['id'] as int, _remotePatientToRow(map, existing['id'] as int, remoteId));
          } else {
            final maxId = await _patientRepo.getMaxId();
            await _patientRepo.insert(_remotePatientToRow(map, maxId + 1, remoteId));
          }
          applied++;
        }
      } catch (_) {}
    }
    return applied;
  }

  Future<int> _applyRemoteOpdRecords(List<dynamic> remoteOpd) async {
    var applied = 0;
    for (final json in remoteOpd) {
      try {
        final map = Map<String, dynamic>.from(json as Map);
        final remoteId = map['id']?.toString() ?? '';
        final remoteUpdated = _parseRemoteTimestamp(map['updated_at']?.toString());
        final existing = await _opdRepo.getByOpdId(remoteId);
        final localUpdated = DateTime.tryParse(
          existing?['updated_at'] as String? ?? existing?['created_at'] as String? ?? '',
        );

        final localId = existing != null ? existing['id'] as int : (await _opdRepo.getMaxId()) + 1;

        if (existing == null || (remoteUpdated != null && localUpdated != null && remoteUpdated.isAfter(localUpdated))) {
          final row = await _remoteOpdToRow(map, localId);
          if (existing != null) {
            await _opdRepo.update(localId, row);
          } else {
            await _opdRepo.insert(row);
            // Cross-device alert for new OPD registration
            try {
              final patientSyncId = map['patient_id']?.toString() ?? '';
              final patient = await _patientRepo.getBySyncId(patientSyncId);
              final patientName = patient?['full_name'] as String? ?? 'Patient';
              final opdType = map['opd_type']?.toString() ?? 'OPD';
              await EventNotificationService.notifyOpdRegistered(
                patientName: patientName,
                type: opdType,
              );
            } catch (_) {}
          }
          applied++;
        }

        await _syncRemoteOpdImages(map, localId);
      } catch (_) {}
    }
    return applied;
  }

  /// Populate the local `patient_images` table from the remote OPD row's
  /// `image_links` (newline-separated Google Drive URLs). Idempotent:
  /// URLs already present for the OPD are skipped.
  Future<void> _syncRemoteOpdImages(Map<String, dynamic> remoteOpd, int localOpdId) async {
    try {
      final linksText = remoteOpd['image_links']?.toString() ?? '';
      if (linksText.trim().isEmpty) return;

      final remotePatientId = remoteOpd['patient_id']?.toString() ?? '';
      int localPatientId = 0;
      if (remotePatientId.isNotEmpty) {
        try {
          final patient = await _patientRepo.getBySyncId(remotePatientId);
          localPatientId = patient?['id'] as int? ?? 0;
        } catch (_) {}
      }

      final existing = await _imagesRepo.getByOpdVisitId(localOpdId);
      final existingUrls = existing
          .map((r) => _normalizeDriveUrl(r['drive_url']?.toString() ?? ''))
          .where((u) => u.isNotEmpty)
          .toSet();

      var nextId = await _imagesRepo.getMaxId();
      for (final link in linksText.split('\n')) {
        final trimmed = link.trim();
        if (trimmed.isEmpty) continue;
        final url = _normalizeDriveUrl(trimmed);
        if (url.isEmpty || existingUrls.contains(url)) continue;
        nextId++;
        await _imagesRepo.insert({
          'id': nextId,
          'patient_id': localPatientId,
          'opd_visit_id': localOpdId,
          'file_path': null,
          'image_type': 'document',
          'sync_status': 'synced',
          'uploaded_at': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'drive_url': url,
        });
      }
    } catch (e) {
      debugPrint('SYNC image link apply failed: $e');
    }
  }

  /// Convert a Google Drive share URL to a directly loadable image URL.
  /// Convert a Google Drive share URL or UC URL to standard view URL.
  /// e.g. https://drive.google.com/file/d/ID/view?usp=sharing
  String _normalizeDriveUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    final fileIdMatch = RegExp(r'(?:/file/d/|id=)([^/&?]+)').firstMatch(trimmed);
    if (fileIdMatch != null) {
      final fileId = fileIdMatch.group(1)!;
      return 'https://drive.google.com/file/d/$fileId/view?usp=sharing';
    }
    return trimmed;
  }

  Future<int> _applyRemoteAppointments(List<dynamic> remoteAppts) async {
    var applied = 0;
    for (final json in remoteAppts) {
      try {
        final map = Map<String, dynamic>.from(json as Map);
        final apptBox = Hive.box<AppointmentModel>('appointments');
        final existing = apptBox.get(map['id']);
        final remoteUpdated = _parseRemoteTimestamp(map['updated_at']?.toString());
        if (existing == null ||
            (remoteUpdated != null && existing.updatedAt.isBefore(remoteUpdated))) {
          apptBox.put(map['id'], AppointmentModel.fromJson(map).copyWith(isSynced: true));
          applied++;
        }
      } catch (_) {}
    }
    return applied;
  }

  Future<int> _applyRemoteDeletes(List<dynamic> remoteDeleted) async {
    var applied = 0;
    for (final del in remoteDeleted) {
      try {
        final d = Map<String, dynamic>.from(del as Map);
        final etype = d['entity_type']?.toString() ?? '';
        final eid = d['entity_id']?.toString() ?? '';

        if (etype == 'patient') {
          final local = await _patientRepo.getBySyncId(eid);
          if (local != null) {
            final localId = local['id'] as int;
            await _opdRepo.deleteByPatientId(localId);
            await _imagesRepo.deleteByPatientId(localId);
            await _patientRepo.delete(localId);
            applied++;
          }
        } else if (etype == 'opd_visit') {
          final local = await _opdRepo.getByOpdId(eid);
          if (local != null) {
            await _imagesRepo.deleteByOpdVisitId(local['id'] as int);
            await _opdRepo.delete(local['id'] as int);
            applied++;
          }
        } else if (etype == 'appointment') {
          try {
            final apptBox = Hive.box<AppointmentModel>('appointments');
            if (apptBox.containsKey(eid)) {
              await apptBox.delete(eid);
              applied++;
            }
          } catch (_) {}
        } else if (etype == 'calendar_note') {
          await _notesRepo.deleteByDate(eid);
          applied++;
        }
      } catch (_) {}
    }
    return applied;
  }

  Future<void> forceSyncNow({bool immediate = true}) async {
    if (_syncState == SyncState.syncing) {
      _pendingSyncRequested = true;
      return;
    }
    _forceDebounce?.cancel();
    if (immediate) {
      await _trySync();
    } else {
      _forceDebounce = Timer(const Duration(milliseconds: 500), () async {
        await _trySync();
      });
    }
  }

  Future<bool> triggerManualSync() async {
    if (_syncState == SyncState.syncing) {
      _pendingSyncRequested = true;
      return false;
    }
    _forceDebounce?.cancel();
    await _trySync();
    SyncRefreshBus().notifyDataChanged();
    return _syncState == SyncState.synced;
  }

  Future<bool> backupToDriveOnly() async {
    if (_syncState == SyncState.syncing) {
      _pendingSyncRequested = true;
      return false;
    }
    _forceDebounce?.cancel();
    await _trySync();
    return _syncState == SyncState.synced;
  }

  int getUnsyncedCount() {
    return _syncState == SyncState.offline ? 1 : 0;
  }

  Future<void> scheduleDailyBackup(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('backup_hour', time.hour);
    await prefs.setInt('backup_minute', time.minute);
  }

  Future<bool> fullRestore() async {
    if (!_connectivity.currentStatus) return false;
    _syncState = SyncState.syncing;
    notifyListeners();

    try {
      await ApiService.ensureToken();
      final data = await ApiService.fullRestore();
      _lastSyncApplied =
          await _applyRemotePatients(data['patients'] as List<dynamic>? ?? []) +
              await _applyRemoteOpdRecords(data['opd_records'] as List<dynamic>? ?? []) +
              await _applyRemoteAppointments(data['appointments'] as List<dynamic>? ?? []) +
              await _applyRemoteClinicSettings(data['clinic_settings'] as List<dynamic>? ?? []) +
              await _applyRemoteCalendarNotes(data['calendar_notes'] as List<dynamic>? ?? []) +
              await _applyRemoteMedicines(data['medicines'] as List<dynamic>? ?? []) +
              await _applyRemoteSymptoms(data['symptoms'] as List<dynamic>? ?? []);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_flask_sync',
        data['server_time']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
      );

      // Live refresh after a full restore so the UI reflects restored data.
      if (_lastSyncApplied > 0) {
        SyncRefreshBus().notifyDataChanged();
      }
      _syncState = SyncState.synced;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('FULL RESTORE error: $e');
      _syncState = SyncState.error;
      notifyListeners();
      return false;
    }
  }

  // ─── Data helpers ──

  Map<String, dynamic> _patientRowToMap(Map<String, dynamic> row) {
    final createdAt = row['created_at'] as String? ?? '';
    final createdDt = DateTime.tryParse(createdAt) ?? DateTime.now();
    final localId = row['id'] as int? ?? 0;
    final fallbackSyncId = 'P${localId.toString().padLeft(3, '0')}';
    final syncId = row['sync_id'] as String? ?? fallbackSyncId;
    return {
      'id': syncId,
      'name': row['full_name'],
      'dob': row['dob'] ?? '',
      'age': row['age'] ?? 0,
      'gender': row['gender'] ?? 'Not Specified',
      'blood_group': row['blood_group'] ?? 'Not Specified',
      'mobile': row['mobile_number'],
      'alternate_mobile': row['alternate_mobile'] ?? '',
      'address': row['address'] ?? '',
      'created_at': createdDt.toIso8601String(),
      'updated_at': _resolveUpdatedAt(row),
      'weight': row['weight'],
    };
  }

  Map<String, dynamic> _opdRowToMap(Map<String, dynamic> row, String patientSyncId) {
    final createdAt = row['created_at'] as String? ?? '';
    final createdDt = DateTime.tryParse(createdAt) ?? DateTime.now();
    final visitDt = row['visit_datetime'] as String? ?? '';
    return {
      'id': row['opd_id']?.toString() ?? 'R${row['id']}',
      'patient_id': patientSyncId,
      'type': row['opd_type'] ?? 'consultation',
      'symptoms': row['symptoms'] ?? '',
      'diagnosis': row['diagnosis'] ?? '',
      'medicines': row['medicines'] ?? '',
      'visit_date': DateTime.tryParse(visitDt)?.toIso8601String() ?? createdDt.toIso8601String(),
      'clinical_notes': row['clinical_notes'] ?? '',
      'panchakarma_notes': row['panchakarma_notes'] ?? '',
      'consultation_fee': (row['consultation_fee'] as num?)?.toString() ?? '',
      'medicine_fee': (row['medicine_fee'] as num?)?.toString() ?? '',
      'panchakarma_fee': (row['panchakarma_fee'] as num?)?.toString() ?? '',
      'total_fee': (row['total_fee'] as num?)?.toString() ?? '',
      'discount': (row['discount_value'] as num?)?.toString() ?? '',
      'discount_type': row['discount_type'] ?? '',
      'payment_mode': row['payment_mode'] ?? '',
      'charge_type': row['charge_type'] ?? '',
      'follow_up_reason': row['followup_status'] ?? '',
      'next_visit': row['next_visit_date'] ?? '',
      'blood_group': row['blood_group'] ?? '',
      'previous_visit_date': row['next_visit_date'] ?? '',
      'created_at': createdDt.toIso8601String(),
      'updated_at': _resolveUpdatedAt(row),
    };
  }

  Map<String, dynamic> _remotePatientToRow(Map<String, dynamic> remote, int sqliteId, String syncId) {
    return {
      'id': sqliteId,
      'sync_id': syncId,
      'full_name': remote['name']?.toString() ?? '',
      'mobile_number': remote['mobile']?.toString() ?? '',
      'alternate_mobile': remote['alternate_mobile']?.toString() ?? '',
      'gender': remote['gender']?.toString() ?? 'Not Specified',
      'dob': remote['dob']?.toString() ?? '',
      'age': int.tryParse(remote['age']?.toString() ?? '') ?? 0,
      'blood_group': remote['blood_group']?.toString() ?? 'Not Specified',
      'address': remote['address']?.toString() ?? '',
      'created_at': remote['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      'updated_at': _asUtcIso(remote['updated_at']?.toString() ?? ''),
      'weight': remote['weight'] != null ? (remote['weight'] as num).toDouble() : null,
    };
  }

  Future<Map<String, dynamic>> _remoteOpdToRow(Map<String, dynamic> remote, int sqliteId) async {
    final remotePatientId = remote['patient_id']?.toString() ?? '';
    int localPatientId = 0;
    try {
      var patient = await _patientRepo.getBySyncId(remotePatientId);
      if (patient == null && remotePatientId.isNotEmpty) {
        final parsed = int.tryParse(remotePatientId.replaceAll(RegExp(r'[^0-9]'), ''));
        if (parsed != null && parsed > 0) {
          final padded = 'P${parsed.toString().padLeft(3, '0')}';
          patient = await _patientRepo.getBySyncId(padded);
          patient ??= await _patientRepo.getById(parsed);
        }
      }
      localPatientId = patient?['id'] as int? ?? 0;
    } catch (_) {
      localPatientId = 0;
    }
    return {
      'id': sqliteId,
      'opd_id': remote['id']?.toString() ?? '',
      'patient_id': localPatientId,
      'visit_datetime': remote['visit_date']?.toString() ?? '',
      'opd_type': remote['type']?.toString() ?? 'consultation',
      'charge_type': remote['charge_type']?.toString() ?? '',
      'diagnosis': remote['diagnosis']?.toString() ?? '',
      'symptoms': remote['symptoms']?.toString() ?? '',
      'clinical_notes': remote['clinical_notes']?.toString() ?? '',
      'panchakarma_notes': remote['panchakarma_notes']?.toString() ?? '',
      'consultation_fee': double.tryParse(remote['consultation_fee']?.toString() ?? '') ?? 0.0,
      'medicine_fee': double.tryParse(remote['medicine_fee']?.toString() ?? '') ?? 0.0,
      'panchakarma_fee': double.tryParse(remote['panchakarma_fee']?.toString() ?? '') ?? 0.0,
      'total_fee': double.tryParse(remote['total_fee']?.toString() ?? '') ?? 0.0,
      'payment_mode': remote['payment_mode']?.toString() ?? '',
      'next_visit_date': remote['next_visit']?.toString() ?? '',
      'followup_status': remote['follow_up_reason']?.toString() ?? '',
      'discount_value': double.tryParse(remote['discount']?.toString() ?? '') ?? 0.0,
      'discount_type': remote['discount_type']?.toString() ?? '',
      'blood_group': remote['blood_group']?.toString() ?? '',
      'created_at': remote['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      'updated_at': _asUtcIso(remote['updated_at']?.toString() ?? ''),
      'medicines': remote['medicines']?.toString() ?? '',
      'image_links': remote['image_links']?.toString() ?? '',
    };
  }

  String _resolveUpdatedAt(Map<String, dynamic> row) {
    final updatedAt = row['updated_at'] as String?;
    if (updatedAt != null && updatedAt.isNotEmpty) return _toUtcIso(updatedAt);
    final createdAt = row['created_at'] as String?;
    if (createdAt != null && createdAt.isNotEmpty) return _toUtcIso(createdAt);
    return DateTime.now().toUtc().toIso8601String();
  }

  /// Converts a locally stored timestamp to UTC-aware ISO-8601. Naive values
  /// (no timezone) are treated as device-local time, matching how local edits
  /// are written, so the pushed timestamp carries the true instant.
  String _toUtcIso(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return DateTime.now().toUtc().toIso8601String();
    final dt = DateTime.tryParse(s);
    return dt?.toUtc().toIso8601String() ?? DateTime.now().toUtc().toIso8601String();
  }

  /// Converts a remote/server timestamp to UTC-aware ISO-8601. Naive values
  /// are treated as UTC (the server stores naive UTC timestamps).
  String _asUtcIso(String raw) {
    if (raw.trim().isEmpty) return DateTime.now().toUtc().toIso8601String();
    final dt = _parseRemoteTimestamp(raw);
    return dt?.toUtc().toIso8601String() ?? DateTime.now().toUtc().toIso8601String();
  }

  DateTime? _parseRemoteTimestamp(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final s = raw.trim();
    final hasTimeZone = s.endsWith('Z') ||
        s.endsWith('z') ||
        RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(s);
    if (hasTimeZone) return DateTime.tryParse(s);
    return DateTime.tryParse('${s}Z');
  }

  Future<String> _loadOrCreateDeviceId() async {
    try {
      final existing = await _deviceRegRepo.get();
      if (existing != null) return existing['device_id'] as String;
      final newId = 'DEV${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999).toString().padLeft(5, '0')}';
      await _deviceRegRepo.insert({'device_id': newId, 'device_name': '', 'clinic_id': ''});
      return newId;
    } catch (e) {
      debugPrint('SYNC WARNING: device registry unavailable ($e) — using in-memory device id');
      return 'DEV${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999).toString().padLeft(5, '0')}';
    }
  }

  String _getDeviceName() {
    try {
      return Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<int> _applyRemoteClinicSettings(List<dynamic> remoteSettings) async {
    var applied = 0;
    for (final json in remoteSettings) {
      try {
        final map = Map<String, dynamic>.from(json as Map);
        final remoteUpdated = _parseRemoteTimestamp(map['updated_at']?.toString());
        final existing = await _settingsRepo.getFirst();
        final localUpdated = DateTime.tryParse(existing?['updated_at'] as String? ?? '');

        if (existing == null || (remoteUpdated != null && localUpdated != null && remoteUpdated.isAfter(localUpdated))) {
          await _settingsRepo.upsert({
            'doctor_name': map['doctor_name']?.toString() ?? '',
            'doctor_email': map['doctor_email']?.toString() ?? '',
            'doctor_contact': map['doctor_contact']?.toString() ?? '',
            'doctor_license_no': map['doctor_license_no']?.toString() ?? '',
            'doctor_photo_path': map['doctor_photo_path']?.toString() ?? '',
            'clinic_name': map['clinic_name']?.toString() ?? '',
            'clinic_logo_path': map['clinic_logo_path']?.toString() ?? '',
            'clinic_address': map['clinic_address']?.toString() ?? '',
            'clinic_phone': map['clinic_phone']?.toString() ?? '',
            'website': map['website']?.toString() ?? '',
            'operating_hours': map['operating_hours']?.toString() ?? '',
            'updated_at': _asUtcIso(map['updated_at']?.toString() ?? ''),
          });
          applied++;
        }
      } catch (_) {}
    }
    return applied;
  }

  Future<int> _applyRemoteCalendarNotes(List<dynamic> remoteNotes) async {
    var applied = 0;
    for (final json in remoteNotes) {
      try {
        final map = Map<String, dynamic>.from(json as Map);
        final date = map['note_date']?.toString() ?? '';
        if (date.isEmpty) continue;

        final remoteUpdated = _parseRemoteTimestamp(map['updated_at']?.toString());
        final existing = await _notesRepo.getByDate(date);
        final localUpdated = DateTime.tryParse(existing?['updated_at'] as String? ?? '');

        if (existing == null || (remoteUpdated != null && localUpdated != null && remoteUpdated.isAfter(localUpdated))) {
          final noteText = map['note_text']?.toString() ?? '[]';
          if (noteText == '[]' || noteText.isEmpty) {
            await _notesRepo.deleteByDate(date);
          } else {
            if (existing != null) {
              await _notesRepo.updateByDate(date, {
                'note_text': noteText,
                'updated_at': _asUtcIso(map['updated_at']?.toString() ?? ''),
              });
            } else {
              await _notesRepo.insert({
                'id': SyncIdGenerator.nextId(),
                'note_date': date,
                'note_text': noteText,
                'created_at': map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
                'updated_at': _asUtcIso(map['updated_at']?.toString() ?? ''),
              });
            }
          }
          applied++;
          // Cross-device alert for new or updated clinic note
          try {
            const notifTitle = 'Clinic Note Updated';
            final notifBody = 'Clinic note for $date was updated on another device.';
            await NotificationProvider.addNotificationSilently(notifTitle, notifBody);
            await LocalNotificationService().showNotification(
              id: date.hashCode & 0x7FFFFFFF,
              title: notifTitle,
              body: notifBody,
            );
          } catch (_) {}
        }
      } catch (_) {}
    }
    return applied;
  }

  Future<int> _applyRemoteMedicines(List<dynamic> remoteMedicines) async {
    var applied = 0;
    for (final json in remoteMedicines) {
      try {
        final map = Map<String, dynamic>.from(json as Map);
        final name = map['name']?.toString().trim() ?? '';
        if (name.isEmpty) continue;
        final existing = await _medicinesRepo.getByName(name);
        if (existing == null) {
          final maxId = await _medicinesRepo.getMaxId();
          await _medicinesRepo.insert({'id': maxId + 1, 'name': name});
          applied++;
        }
      } catch (_) {}
    }
    return applied;
  }

  Future<int> _applyRemoteSymptoms(List<dynamic> remoteSymptoms) async {
    var applied = 0;
    for (final json in remoteSymptoms) {
      try {
        final map = Map<String, dynamic>.from(json as Map);
        final name = map['name']?.toString().trim() ?? '';
        if (name.isEmpty) continue;
        final existing = await _symptomsRepo.getByName(name);
        if (existing == null) {
          await _symptomsRepo.insert({'name': name});
          applied++;
        }
      } catch (_) {}
    }
    return applied;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _debounceTimer?.cancel();
    _pollTimer?.cancel();
    _forceDebounce?.cancel();
    super.dispose();
  }
}
