import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// LocalAuthService manages local authentication methods:
/// - 4-digit PIN code
/// - Fingerprint / biometric authentication
///
/// Stores settings per-user (keyed by Firebase UID) in SharedPreferences.
class LocalAuthService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _pinKeyPrefix = 'user_pin_';
  static const String _authMethodKeyPrefix = 'auth_method_';
  static const String _biometricEnabledKeyPrefix = 'biometric_enabled_';
  static const String _pinEnabledKeyPrefix = 'pin_enabled_';
  static const String _linkedEmailKeyPrefix = 'linked_email_';
  static const String _credEmailKey = 'quick_login_email';
  static const String _credPasswordKey = 'quick_login_password';

  /// Auth method types
  static const String methodNone = 'none';
  static const String methodPin = 'pin';
  static const String methodBiometric = 'biometric';

  // ─── BIOMETRIC SUPPORT ──────────────────────────────────────────────

  /// Check if the device supports biometric authentication.
  static Future<bool> isBiometricAvailable() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canAuthenticate && isDeviceSupported;
    } on PlatformException catch (e) {
      debugPrint('Biometric check failed: $e');
      return false;
    }
  }

  /// Get available biometric types.
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('Get biometrics failed: $e');
      return [];
    }
  }

  /// Authenticate using biometrics (fingerprint/face).
  static Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Rumi Ishi',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric auth failed: $e');
      return false;
    }
  }

  // ─── PIN MANAGEMENT ─────────────────────────────────────────────────

  /// Hash a PIN for secure storage (simple hash for local use).
  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin + 'rumi_ishi_salt_2024');
    // Simple hash — for local storage only
    int hash = 0;
    for (final byte in bytes) {
      hash = ((hash << 5) - hash + byte) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  /// Save a 4-digit PIN for a user.
  static Future<void> savePin(String uid, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_pinKeyPrefix$uid', _hashPin(pin));
  }

  /// Verify a PIN against stored hash.
  static Future<bool> verifyPin(String uid, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString('$_pinKeyPrefix$uid');
    if (storedHash == null) return false;
    return storedHash == _hashPin(pin);
  }

  /// Check if a PIN is set for a user.
  static Future<bool> hasPinSet(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_pinKeyPrefix$uid');
  }

  /// Remove PIN for a user.
  static Future<void> removePin(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_pinKeyPrefix$uid');
  }

  // ─── AUTH METHOD SETTINGS ───────────────────────────────────────────

  /// Save the quick auth method for a user.
  static Future<void> setAuthMethod(String uid, String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_authMethodKeyPrefix$uid', method);
  }

  /// Get the quick auth method for a user.
  static Future<String> getAuthMethod(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_authMethodKeyPrefix$uid') ?? methodNone;
  }

  /// Enable/disable biometric for a user.
  static Future<void> setBiometricEnabled(String uid, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_biometricEnabledKeyPrefix$uid', enabled);
  }

  /// Check if biometric is enabled for a user.
  static Future<bool> isBiometricEnabled(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_biometricEnabledKeyPrefix$uid') ?? false;
  }

  /// Enable/disable PIN for a user.
  static Future<void> setPinEnabled(String uid, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_pinEnabledKeyPrefix$uid', enabled);
  }

  /// Check if PIN is enabled for a user.
  static Future<bool> isPinEnabled(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_pinEnabledKeyPrefix$uid') ?? false;
  }

  // ─── LINKED EMAIL STORAGE ──────────────────────────────────────────

  /// Store the email linked to quick auth (so we know which account to log in).
  static Future<void> setLinkedEmail(String uid, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_linkedEmailKeyPrefix$uid', email);
  }

  /// Get the email linked to this user's quick auth.
  static Future<String?> getLinkedEmail(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_linkedEmailKeyPrefix$uid');
  }

  // ─── LAST LOGGED IN USER ───────────────────────────────────────────

  /// Store the last logged-in user UID for quick login detection.
  static Future<void> setLastLoggedInUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_logged_in_uid', uid);
  }

  /// Get the last logged-in user UID.
  static Future<String?> getLastLoggedInUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_logged_in_uid');
  }

  /// Store the last logged-in user's email.
  static Future<void> setLastLoggedInEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_logged_in_email', email);
  }

  /// Get the last logged-in user's email.
  static Future<String?> getLastLoggedInEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_logged_in_email');
  }

  /// Store the last logged-in user's display name.
  static Future<void> setLastLoggedInName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_logged_in_name', name);
  }

  /// Get the last logged-in user's display name.
  static Future<String?> getLastLoggedInName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_logged_in_name');
  }

  // ─── CLEAR ALL ──────────────────────────────────────────────────────

  /// Clear all quick-auth data for a user (e.g., on logout/disable).
  static Future<void> clearUserAuthData(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_pinKeyPrefix$uid');
    await prefs.remove('$_authMethodKeyPrefix$uid');
    await prefs.remove('$_biometricEnabledKeyPrefix$uid');
    await prefs.remove('$_pinEnabledKeyPrefix$uid');
    await prefs.remove('$_linkedEmailKeyPrefix$uid');
  }

  /// Clear last logged-in info (full logout).
  static Future<void> clearLastLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_logged_in_uid');
    await prefs.remove('last_logged_in_email');
    await prefs.remove('last_logged_in_name');
  }

  /// Check if any quick login method is configured for last user.
  static Future<bool> hasQuickLoginAvailable() async {
    final uid = await getLastLoggedInUid();
    if (uid == null) return false;
    final method = await getAuthMethod(uid);
    return method != methodNone;
  }

  // ─── SECURE CREDENTIAL STORAGE ────────────────────────────────────

  /// Store login credentials securely for quick login re-authentication.
  static Future<void> saveCredentials(String email, String password) async {
    try {
      await _secureStorage.write(key: _credEmailKey, value: email);
      await _secureStorage.write(key: _credPasswordKey, value: password);
    } catch (e) {
      debugPrint('Failed to save credentials: $e');
    }
  }

  /// Retrieve stored email credential.
  static Future<String?> getSavedEmail() async {
    try {
      return await _secureStorage.read(key: _credEmailKey);
    } catch (e) {
      debugPrint('Failed to read email: $e');
      return null;
    }
  }

  /// Retrieve stored password credential.
  static Future<String?> getSavedPassword() async {
    try {
      return await _secureStorage.read(key: _credPasswordKey);
    } catch (e) {
      debugPrint('Failed to read password: $e');
      return null;
    }
  }

  /// Clear stored credentials (on full logout with quick login disabled).
  static Future<void> clearCredentials() async {
    try {
      await _secureStorage.delete(key: _credEmailKey);
      await _secureStorage.delete(key: _credPasswordKey);
    } catch (e) {
      debugPrint('Failed to clear credentials: $e');
    }
  }
}
