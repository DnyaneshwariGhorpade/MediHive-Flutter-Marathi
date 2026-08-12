import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/backup_code_service.dart';
import '../services/api_service.dart';
import '../services/sync_manager.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _hasLoadedCredentials = false;
  bool _rememberMe = false;
  String _username = '';
  String _password = '';
  AppUser? _currentUser;
  bool _needs2FA = false;
  String _pendingUsername = '';
  String _loginError = '';
  String _clinicId = '';
  Map<String, dynamic>? _clinicInfo;

  AuthProvider() {
    loadSavedCredentials();
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get hasLoadedCredentials => _hasLoadedCredentials;
  bool get rememberMe => _rememberMe;
  String get username => _username;
  String get password => _password;
  AppUser? get currentUser => _currentUser;
  bool get needs2FA => _needs2FA;
  String get loginError => _loginError;
  String get clinicId => _clinicId;
  Map<String, dynamic>? get clinicInfo => _clinicInfo;

  bool get isLoggedIn => _isAuthenticated;

  Future<void> saveClinicInfo(Map<String, dynamic> data) async {
    _clinicId = data['user']?['clinic_id'] as String? ?? '';
    _clinicInfo = data['clinic'] as Map<String, dynamic>?;
    final prefs = await SharedPreferences.getInstance();
    if (_clinicId.isNotEmpty) await prefs.setString('clinic_id', _clinicId);
  }

  void setUsername(String value) {
    _username = value;
    _loginError = '';
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    _loginError = '';
    notifyListeners();
  }

  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    notifyListeners();
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  Future<bool> signIn() async {
    final username = _username.trim();
    final password = _password.trim();

    _isLoading = true;
    _loginError = '';
    notifyListeners();

    final user = await _authService.login(username, password);

    if (user != null) {
      _needs2FA = await BackupCodeService.is2FAEnabled();

      if (_needs2FA) {
        _pendingUsername = username;
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isAuthenticated = true;
      _currentUser = user;

      _clinicId = user.clinicId;
      debugPrint('LOGIN RESPONSE: clinic_id=$_clinicId');
      final prefs = await SharedPreferences.getInstance();
      if (_clinicId.isNotEmpty) {
        await prefs.setString('clinic_id', _clinicId);
        debugPrint('SAVED clinic_id=$_clinicId');
      } else {
        try {
          final me = await ApiService.getMe();
          _clinicId = me['user']?['clinic_id'] as String? ?? '';
          if (_clinicId.isNotEmpty) {
            await prefs.setString('clinic_id', _clinicId);
          }
          debugPrint('FALLBACK getMe clinic_id=$_clinicId');
        } catch (e) {
          debugPrint('WARNING: getMe failed, clinic_id may be empty: $e');
        }
      }

      await _storageService.setLoggedIn(_rememberMe);

      if (_rememberMe) {
        await _storageService.setRememberMe(true);
        await _storageService.setUsername(username);
      } else {
        await _storageService.clearAuth();
      }

      // Auto-pull existing records from cloud immediately upon login
      SyncManager().forceSyncNow(immediate: true);
    } else {
      _loginError = 'Invalid username or password';
    }

    _isLoading = false;
    notifyListeners();
    return user != null;
  }

  Future<bool> verify2FACode(String code) async {
    final valid = await BackupCodeService.verifyAndConsumeCode(code);
    if (!valid) return false;

    _needs2FA = false;
    _isAuthenticated = true;
    if (_rememberMe) {
      await _storageService.setRememberMe(true);
      await _storageService.setUsername(_pendingUsername);
    } else {
      await _storageService.clearAuth();
    }
    await _storageService.setLoggedIn(true);
    _pendingUsername = '';
    notifyListeners();
    SyncManager().forceSyncNow(immediate: true);
    return true;
  }

  void cancel2FA() {
    _needs2FA = false;
    _pendingUsername = '';
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    final user = await _authService.signInWithGoogle();

    if (user != null) {
      _isAuthenticated = true;
      _currentUser = user;
      await _storageService.setLoggedIn(true);
      SyncManager().forceSyncNow(immediate: true);
    }

    _isLoading = false;
    notifyListeners();
    return user != null;
  }

  Future<void> signOut() async {
    _isAuthenticated = false;
    _currentUser = null;
    _username = '';
    _password = '';
    _needs2FA = false;
    _pendingUsername = '';
    _clinicId = '';
    _clinicInfo = null;
    await _authService.logout();
    await _storageService.clearAuth();
    notifyListeners();
  }

  Future<bool> login() => signIn();
  Future<void> logout() => signOut();

  Future<void> loadSavedCredentials() async {
    _rememberMe = await _storageService.getRememberMe();
    final wasLoggedIn = await _storageService.getLoggedIn();
    final prefs = await SharedPreferences.getInstance();
    _clinicId = prefs.getString('clinic_id') ?? '';
    debugPrint('READ clinic_id=$_clinicId from SharedPreferences');

    if (wasLoggedIn) {
      final user = await _authService.signInSilently();
      if (user != null) {
        _isAuthenticated = true;
        _currentUser = user;
        if (user.clinicId.isNotEmpty && user.clinicId != _clinicId) {
          _clinicId = user.clinicId;
          await prefs.setString('clinic_id', _clinicId);
          debugPrint('REFRESHED clinic_id=$_clinicId from silent sign-in');
        }
      } else if (_rememberMe) {
        _username = await _storageService.getUsername();
        _isAuthenticated = true;
        _currentUser = AppUser(id: '1', name: 'Dr. $_username', email: '$_username@medihive.com');
      }

      if (_clinicId.isEmpty) {
        try {
          final me = await ApiService.getMe();
          _clinicId = me['user']?['clinic_id'] as String? ?? '';
          if (_clinicId.isNotEmpty) {
            await prefs.setString('clinic_id', _clinicId);
            debugPrint('REFRESHED clinic_id=$_clinicId from /auth/me');
          }
        } catch (e) {
          debugPrint('WARNING: Failed to refresh clinic_id on restart: $e');
        }
      }

      // Auto-pull existing records on session restore
      SyncManager().forceSyncNow(immediate: true);
    }
    _hasLoadedCredentials = true;
    notifyListeners();
  }
}
