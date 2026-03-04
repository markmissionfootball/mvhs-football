import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._();
  factory BiometricService() => _instance;
  BiometricService._();

  final _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  static const _keyEnabled = 'biometric_enabled';
  static const _keyUid = 'biometric_uid';
  static const _keyUsername = 'biometric_username';

  /// Whether the device supports biometrics (Face ID, Touch ID, fingerprint).
  Future<bool> isAvailable() async {
    // Biometrics not available on web
    if (kIsWeb) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Whether the user has previously enrolled biometric login.
  Future<bool> isEnrolled() async {
    if (kIsWeb) return false;
    try {
      final value = await _storage.read(key: _keyEnabled);
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Prompt the user for biometric authentication.
  /// Returns true if successfully authenticated.
  Future<bool> authenticate() async {
    if (kIsWeb) return false;
    try {
      return await _auth.authenticate(
        localizedReason: 'Sign in to MVHS Football',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Store credentials after a successful password login.
  Future<void> enrollCredentials({
    required String uid,
    required String username,
  }) async {
    await _storage.write(key: _keyEnabled, value: 'true');
    await _storage.write(key: _keyUid, value: uid);
    await _storage.write(key: _keyUsername, value: username);
  }

  /// Retrieve stored credentials for silent login after biometric success.
  Future<({String uid, String username})?> getStoredCredentials() async {
    try {
      final uid = await _storage.read(key: _keyUid);
      final username = await _storage.read(key: _keyUsername);
      if (uid != null && username != null) {
        return (uid: uid, username: username);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Clear biometric enrollment (e.g. on logout or disable).
  Future<void> clearEnrollment() async {
    await _storage.delete(key: _keyEnabled);
    await _storage.delete(key: _keyUid);
    await _storage.delete(key: _keyUsername);
  }
}
