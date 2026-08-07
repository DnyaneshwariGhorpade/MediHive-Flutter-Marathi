import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'sync_manager.dart';
import 'firebase_messaging_service.dart';
import '../repositories/device_registration_repository.dart';
import 'dart:math' show Random;

enum CloudSyncState {
  idle,
  syncing,
  synced,
  error,
  offline,
  notConfigured,
}

class CloudSyncManager extends ChangeNotifier {
  CloudSyncState _state = CloudSyncState.idle;
  Timer? _heartbeatTimer;
  bool _isRunning = false;
  int _syncCount = 0;
  String _lastError = '';
  String? _deviceId;

  final DeviceRegistrationRepository _deviceRegRepo = DeviceRegistrationRepository();
  final SyncManager _syncManager = SyncManager();

  static final CloudSyncManager _instance = CloudSyncManager._internal();
  factory CloudSyncManager() => _instance;
  CloudSyncManager._internal();

  CloudSyncState get state => _state;
  bool get isSyncing => _state == CloudSyncState.syncing;
  bool get isConfigured => _cloudBaseUrl.isNotEmpty;
  String get lastError => _lastError;
  int get syncCount => _syncCount;
  String? get deviceId => _deviceId;

  static String get _cloudBaseUrl =>
      ''; // Backward compat: cloud URLs now hit same Flask backend

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      _deviceId = await _loadOrCreateDeviceId();
    } catch (e) {
      _isRunning = false;
      _state = CloudSyncState.error;
      notifyListeners();
      return;
    }

    // Register device
    await _registerDevice();

    // Heartbeat every 5 minutes
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 5), (_) => _sendHeartbeat());

    // Listen to SyncManager state
    _syncManager.addListener(_onSyncStateChange);

    _state = CloudSyncState.idle;
    notifyListeners();
    debugPrint('CLOUD SYNC: started device=$_deviceId');
  }

  void _onSyncStateChange() {
    final s = _syncManager.syncState;
    if (s == SyncState.synced) {
      _syncCount++;
      _state = CloudSyncState.synced;
    } else if (s == SyncState.syncing) {
      _state = CloudSyncState.syncing;
    } else if (s == SyncState.error) {
      _state = CloudSyncState.error;
    } else if (s == SyncState.offline) {
      _state = CloudSyncState.offline;
    }
    notifyListeners();
  }

  void stop() {
    _isRunning = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _syncManager.removeListener(_onSyncStateChange);
    _state = CloudSyncState.idle;
    notifyListeners();
  }

  Future<void> notifyChange({
    required String tableName,
    required String operation,
    required String recordId,
    Map<String, dynamic>? payload,
  }) async {
    // SyncManager listens to sync_queue directly; no-op here
    debugPrint('CLOUD QUEUE: change recorded $operation $tableName $recordId');
  }

  Future<void> forceSync() async {
    await _syncManager.forceSyncNow();
  }

  Future<void> _registerDevice() async {
    if (_deviceId == null) return;
    try {
      final fcmToken = FirebaseMessagingService().fcmToken;
      await ApiService.cloudRegisterDevice(
        deviceId: _deviceId!,
        deviceName: await _getDeviceName(),
        clinicId: '',
        appVersion: _getAppVersion(),
        fcmToken: fcmToken,
      );
    } catch (_) {}
  }

  Future<void> _sendHeartbeat() async {
    if (_deviceId == null) return;
    try {
      await ApiService.cloudHeartbeat(deviceId: _deviceId!);
    } catch (_) {}
  }

  Future<String> _loadOrCreateDeviceId() async {
    final existing = await _deviceRegRepo.get();
    if (existing != null) return existing['device_id'] as String;
    final newId = 'CLD${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999).toString().padLeft(5, '0')}';
    await _deviceRegRepo.insert({'device_id': newId, 'device_name': '', 'clinic_id': ''});
    return newId;
  }

  Future<String> _getDeviceName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('device_name') ?? 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  String _getAppVersion() {
    try {
      return '1.0.0';
    } catch (_) {
      return '1.0.0';
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
