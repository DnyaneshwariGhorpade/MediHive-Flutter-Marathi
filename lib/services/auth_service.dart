import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'google_auth_service.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String clinicId;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.clinicId = '',
  });
}

class AuthService {
  Future<AppUser?> login(String username, String password) async {
    try {
      final data = await ApiService.login(username, password);
      final user = data['user'] as Map<String, dynamic>;
      final clinicId = user['clinic_id']?.toString() ?? '';
      debugPrint('AuthService.login: clinic_id=$clinicId');
      return AppUser(
        id: user['id']?.toString() ?? '',
        name: user['name']?.toString() ?? 'Doctor',
        email: user['email']?.toString() ?? '$username@medihive.com',
        clinicId: clinicId,
      );
    } catch (e) {
      debugPrint('AuthService.login: API failed, falling back to local auth: $e');
      final envUser = dotenv.env['LOCAL_USERNAME'];
      final envPass = dotenv.env['LOCAL_PASSWORD'];
      if (username == envUser && password == envPass) {
        return AppUser(
          id: dotenv.env['GOOGLE_USER_ID'] ?? '1',
          name: 'Dr. $username',
          email: dotenv.env['LOCAL_USERNAME'] ?? '$username@medihive.com',
        );
      }
      final prefs = await SharedPreferences.getInstance();
      final savedPass = prefs.getString('app_password');
      final savedUser = prefs.getString('app_username');
      if (username == (savedUser ?? envUser) && password == savedPass) {
        return AppUser(
          id: dotenv.env['GOOGLE_USER_ID'] ?? '1',
          name: 'Dr. $username',
          email: '$username@medihive.com',
        );
      }
      return null;
    }
  }

  Future<AppUser?> register(String username, String password, {String name = 'Doctor', String? email}) async {
    try {
      final data = await ApiService.register(username, password, name: name, email: email);
      final user = data['user'] as Map<String, dynamic>;
      return AppUser(
        id: user['id']?.toString() ?? '',
        name: user['name']?.toString() ?? 'Doctor',
        email: user['email']?.toString() ?? '',
      );
    } catch (e) {
      debugPrint('AuthService.register: API failed, saving locally: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_username', username);
      await prefs.setString('app_password', password);
      return AppUser(
        id: '1',
        name: name,
        email: '$username@medihive.com',
      );
    }
  }

  /// Google Sign In — authenticates Google on device (for Drive/Sheets access),
  /// then logs into the backend or gracefully falls back to local authenticated session.
  Future<AppUser?> signInWithGoogle() async {
    try {
      final account = await GoogleAuthService().signInWithGoogle();
      if (account == null) return null;

      final envUser = dotenv.env['GOOGLE_USERNAME'] ?? dotenv.env['LOCAL_USERNAME'] ?? '';
      final envPass = dotenv.env['LOCAL_PASSWORD'] ?? '';
      final defaultClinicId = dotenv.env['CLINIC_ID'] ?? '';

      // Try logging in to backend API if credentials are configured
      if (envUser.isNotEmpty && envPass.isNotEmpty) {
        try {
          final data = await ApiService.login(envUser, envPass);
          final user = data['user'] as Map<String, dynamic>;
          final clinicId = user['clinic_id']?.toString() ?? defaultClinicId;
          debugPrint('AuthService: Google login -> backend user_id=${user['id']}, clinic_id=$clinicId');
          return AppUser(
            id: user['id']?.toString() ?? dotenv.env['GOOGLE_USER_ID'] ?? '1',
            name: user['name']?.toString() ?? (account.displayName?.isNotEmpty == true ? account.displayName! : 'Doctor'),
            email: user['email']?.toString() ?? account.email,
            photoUrl: account.photoUrl,
            clinicId: clinicId,
          );
        } catch (apiError) {
          debugPrint('AuthService.signInWithGoogle: Backend API login failed ($apiError), using offline/local session');
        }
      }

      // Offline / Local fallback: create session from Google Account
      return AppUser(
        id: dotenv.env['GOOGLE_USER_ID'] ?? '1',
        name: account.displayName?.isNotEmpty == true ? account.displayName! : 'Doctor',
        email: account.email,
        photoUrl: account.photoUrl,
        clinicId: defaultClinicId,
      );
    } catch (e) {
      debugPrint('AuthService.signInWithGoogle error: $e');
      rethrow;
    }
  }

  Future<AppUser?> signInSilently() async {
    try {
      final signedIn = await GoogleAuthService().isSignedIn();
      if (!signedIn) return null;

      final account = GoogleAuthService().currentUser;
      final envUser = dotenv.env['GOOGLE_USERNAME'] ?? dotenv.env['LOCAL_USERNAME'] ?? '';
      final envPass = dotenv.env['LOCAL_PASSWORD'] ?? '';
      final defaultClinicId = dotenv.env['CLINIC_ID'] ?? '';

      if (envUser.isNotEmpty && envPass.isNotEmpty) {
        try {
          final data = await ApiService.login(envUser, envPass);
          final user = data['user'] as Map<String, dynamic>;
          final clinicId = user['clinic_id']?.toString() ?? defaultClinicId;
          return AppUser(
            id: user['id']?.toString() ?? dotenv.env['GOOGLE_USER_ID'] ?? '1',
            name: user['name']?.toString() ?? account?.displayName ?? 'Doctor',
            email: user['email']?.toString() ?? account?.email ?? '$envUser@medihive.com',
            photoUrl: account?.photoUrl,
            clinicId: clinicId,
          );
        } catch (apiError) {
          debugPrint('AuthService.signInSilently: Backend login failed ($apiError), using local session');
        }
      }

      if (account != null) {
        return AppUser(
          id: dotenv.env['GOOGLE_USER_ID'] ?? '1',
          name: account.displayName?.isNotEmpty == true ? account.displayName! : 'Doctor',
          email: account.email,
          photoUrl: account.photoUrl,
          clinicId: defaultClinicId,
        );
      }
    } catch (e) {
      debugPrint('AuthService.signInSilently error: $e');
    }
    return null;
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    try {
      await GoogleAuthService().signOut();
    } catch (e) {
      debugPrint('AuthService.logout: Google sign-out error: $e');
    }
  }
}
