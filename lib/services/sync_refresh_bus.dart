import 'package:flutter/foundation.dart';

/// Broadcasts "sync pull applied new remote data" so in-memory providers can
/// reload from local storage and the UI updates live, without an app restart.
///
/// Fired from `SyncManager` after a successful pull that changed rows. Listen
/// in provider constructors and remove the listener in `dispose()`.
class SyncRefreshBus extends ChangeNotifier {
  static final SyncRefreshBus _instance = SyncRefreshBus._internal();
  factory SyncRefreshBus() => _instance;
  SyncRefreshBus._internal();

  /// Notifies all registered providers to reload their data.
  void notifyDataChanged() {
    notifyListeners();
  }
}
