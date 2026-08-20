import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleAuthService {
  GoogleSignIn? _googleSignIn;

  static const String _defaultServerClientId =
      '644148878993-5hagauhlr9lsi9isv17um1kek0utbo53.apps.googleusercontent.com';

  GoogleSignIn _buildGoogleSignIn({bool useServerClientId = true}) {
    final serverClientId = useServerClientId
        ? (dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? _defaultServerClientId)
        : null;
    return GoogleSignIn(
      serverClientId: (serverClientId != null && serverClientId.isNotEmpty) ? serverClientId : null,
      scopes: const [
        'email',
        'https://www.googleapis.com/auth/userinfo.profile',
        'https://www.googleapis.com/auth/drive.file',
      ],
    );
  }

  GoogleSignIn get _signIn {
    _googleSignIn ??= _buildGoogleSignIn(useServerClientId: true);
    return _googleSignIn!;
  }

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _keyAccessToken = 'google_drive_access_token';
  static const String _keyIdToken = 'google_drive_id_token';

  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  StreamSubscription? _silentSignInSub;

  final StreamController<GoogleSignInAccount?> _authController =
      StreamController<GoogleSignInAccount?>.broadcast();

  Stream<GoogleSignInAccount?> get onAuthStateChanged => _authController.stream;

  Future<void> init() async {
    try {
      await _signIn.signInSilently();
    } catch (e) {
      debugPrint('GoogleAuthService init silent sign-in skipped: $e');
    }
  }

  GoogleSignInAccount? get currentUser => _signIn.currentUser;

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      GoogleSignInAccount? account;
      try {
        debugPrint('GoogleAuthService: Attempting Google sign-in with serverClientId...');
        account = await _signIn.signIn();
      } catch (firstError) {
        debugPrint('GoogleAuthService: Primary sign-in error ($firstError), retrying with basic client...');
        try {
          final fallbackSignIn = _buildGoogleSignIn(useServerClientId: false);
          _googleSignIn = fallbackSignIn;
          account = await fallbackSignIn.signIn();
        } catch (secondError) {
          debugPrint('GoogleAuthService: Fallback sign-in error ($secondError)');
          throw firstError;
        }
      }

      if (account != null) {
        debugPrint('GoogleAuthService: Sign-in successful for ${account.email}');
        final auth = await account.authentication;
        if (auth.accessToken != null) {
          await _secureStorage.write(key: _keyAccessToken, value: auth.accessToken);
        }
        if (auth.idToken != null) {
          await _secureStorage.write(key: _keyIdToken, value: auth.idToken);
        }
      } else {
        debugPrint('GoogleAuthService: Sign-in cancelled by user.');
      }
      _authController.add(account);
      return account;
    } catch (e) {
      debugPrint('GoogleAuthService.signInWithGoogle error: $e');
      _authController.add(null);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _signIn.signOut();
    } catch (_) {}
    await _secureStorage.delete(key: _keyAccessToken);
    await _secureStorage.delete(key: _keyIdToken);
    _authController.add(null);
  }

  Future<bool> isSignedIn() async {
    if (kIsWeb) return false;
    if (_signIn.currentUser != null) {
      return true;
    }
    try {
      final account = await _signIn.signInSilently();
      if (account != null) {
        final auth = await account.authentication;
        if (auth.accessToken != null) {
          await _secureStorage.write(key: _keyAccessToken, value: auth.accessToken);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<Map<String, String>> getAuthHeaders() async {
    if (kIsWeb) throw UnsupportedError('Google Auth not supported on web');
    var account = _signIn.currentUser;
    account ??= await _signIn.signInSilently();
    if (account == null) {
      throw Exception('Session expired. Please reconnect Google Drive in Settings.');
    }

    final auth = await account.authentication;
    final headers = await account.authHeaders;

    if (auth.accessToken != null) {
      await _secureStorage.write(key: _keyAccessToken, value: auth.accessToken);
    }

    return headers;
  }

  Future<bool> tryRefreshAuth() async {
    if (kIsWeb) return false;
    try {
      final account = await _signIn.signInSilently();
      if (account == null) return false;
      final auth = await account.authentication;
      if (auth.accessToken != null) {
        await _secureStorage.write(key: _keyAccessToken, value: auth.accessToken);
      }
      _authController.add(account);
      return true;
    } catch (e) {
      debugPrint('GoogleAuthService.tryRefreshAuth error: $e');
      return false;
    }
  }

  Future<String?> getCachedAccessToken() async {
    return await _secureStorage.read(key: _keyAccessToken);
  }

  void dispose() {
    _silentSignInSub?.cancel();
    _authController.close();
  }
}
