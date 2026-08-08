import 'dart:async';
import 'package:flutter/foundation.dart';
import 'sync_manager.dart';

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
  bool _isRunning = false;
  int _syncCount = 0;
  final String _lastError = '';

  final SyncManager _syncManager = SyncManager();

  static final CloudSyncManager _instance = CloudSyncManager._internal();
  factory CloudSyncManager() => _instance;
  CloudSyncManager._internal();

  CloudSyncState get state => _state;
  bool get isSyncing => _state == CloudSyncState.syncing;
  bool get isConfigured => _cloudBaseUrl.isNotEmpty;
  String get lastError => _lastError;
  int get syncCount => _syncCount;
  int get lastSyncApplied => _syncManager.lastSyncApplied;

  static String get _cloudBaseUrl =>
      ''; // Backward compat: cloud URLs now hit same Flask backend

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    // Listen to SyncManager state (single source of sync status; no
    // separate heartbeat/registration needed here).
    _syncManager.addListener(_onSyncStateChange);

    _state = CloudSyncState.idle;
    notifyListeners();
    debugPrint('CLOUD SYNC: started');
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

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
