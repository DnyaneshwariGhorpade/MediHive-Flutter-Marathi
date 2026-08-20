import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  bool _isConnectedCached = true; // Default to optimistic true until resolved
  Future<bool>? _inFlightProbe;

  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  ConnectivityService._internal() {
    // Keep cached state updated in real-time
    _connectivity.onConnectivityChanged.listen((results) {
      final connected = results.any((r) => r != ConnectivityResult.none);
      if (connected) {
        _isConnectedCached = true;
      } else {
        // A single "none" result may be wrong (missing ACCESS_NETWORK_STATE,
        // VPN, captive portal). Verify with a real probe before going offline.
        probeReachability();
      }
    });
    // Query initial state
    _connectivity.checkConnectivity().then((results) {
      final connected = results.any((r) => r != ConnectivityResult.none);
      if (connected) {
        _isConnectedCached = true;
      } else {
        probeReachability();
      }
    }).catchError((_) {
      _isConnectedCached = true;
    });
  }

  /// Broadcasts connection status (true = connected, false = disconnected)
  Stream<bool> get isConnected {
    return _connectivity.onConnectivityChanged.map((results) {
      return results.any((r) => r != ConnectivityResult.none);
    });
  }

  /// Synchronously checks the cached network connectivity status
  bool get currentStatus => _isConnectedCached;

  /// Performs a real network reachability check (backend health endpoint,
  /// falling back to a neutral endpoint) and updates the cached status.
  Future<bool> probeReachability({Duration timeout = const Duration(seconds: 6)}) async {
    if (_inFlightProbe != null) {
      return _inFlightProbe!;
    }

    final probe = _executeProbe(timeout);
    _inFlightProbe = probe;
    try {
      final result = await probe;
      _isConnectedCached = result;
      return result;
    } finally {
      _inFlightProbe = null;
    }
  }

  Future<bool> _executeProbe(Duration timeout) async {
    // 1. Prefer the backend health endpoint — proves we can actually sync.
    try {
      final res = await http
          .get(Uri.parse('${ApiService.baseUrl}/health'))
          .timeout(timeout);
      if (res.statusCode >= 200 && res.statusCode < 500) {
        return true;
      }
    } catch (_) {}

    // 2. Fallback: neutral endpoint to distinguish "no internet" from backend hiccup.
    try {
      final res = await http
          .get(Uri.parse('https://www.google.com/generate_204'))
          .timeout(timeout);
      if (res.statusCode == 204 || (res.statusCode >= 200 && res.statusCode < 400)) {
        return true;
      }
    } catch (_) {}

    // If both failed, return false but keep it non-sticky
    return false;
  }
}