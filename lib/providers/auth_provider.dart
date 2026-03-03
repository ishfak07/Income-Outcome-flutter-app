import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/local_auth_service.dart';

/// AuthProvider manages authentication state using Provider pattern.
/// Handles registration, email verification, login, and user profile.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _emailVerificationSent = false;
  bool _emailVerified = false;

  // Registration data stored temporarily during email verification flow
  String? _pendingFullName;
  String? _pendingEmail;
  String? _pendingPhoneNumber;

  // ─── GETTERS ─────────────────────────────────────────────────────────

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get emailVerificationSent => _emailVerificationSent;
  bool get emailVerified => _emailVerified;
  String? get currentUid => _authService.currentUid;

  // ─── STATE HELPERS ───────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void resetVerificationState() {
    _emailVerificationSent = false;
    _emailVerified = false;
    _pendingFullName = null;
    _pendingEmail = null;
    _pendingPhoneNumber = null;
    notifyListeners();
  }

  // ─── INITIALIZE ──────────────────────────────────────────────────────

  /// Check if user is already logged in and load profile.
  Future<void> initialize() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      _user = await _authService.getUserProfile(firebaseUser.uid);
      notifyListeners();
    }
  }

  // ─── PHONE UNIQUENESS CHECK ──────────────────────────────────────────

  /// Check if phone number is already taken.
  Future<bool> isPhoneRegistered(String phoneNumber) async {
    return await _authService.isPhoneNumberRegistered(phoneNumber);
  }

  // ─── EMAIL VERIFICATION ──────────────────────────────────────────────

  /// Register user and send email verification link.
  /// The user's profile will be saved to Firestore after email is verified.
  Future<bool> registerAndSendVerification({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // Check phone uniqueness
      final phoneExists =
          await _authService.isPhoneNumberRegistered(phoneNumber);
      if (phoneExists) {
        _setError('This phone number is already registered.');
        _setLoading(false);
        return false;
      }

      // Register with email/password and send verification email
      await _authService.registerAndSendEmailVerification(
        email: email,
        password: password,
      );

      // Store pending registration data
      _pendingFullName = fullName;
      _pendingEmail = email;
      _pendingPhoneNumber = phoneNumber;
      _emailVerificationSent = true;

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Resend email verification link.
  Future<void> resendVerificationEmail() async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.resendEmailVerification();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Check if email has been verified and complete registration.
  Future<bool> checkVerificationAndComplete() async {
    _setLoading(true);
    _setError(null);

    try {
      final isVerified = await _authService.checkEmailVerified();

      if (!isVerified) {
        _setError(
            'Email not verified yet. Please check your inbox and click the verification link.');
        _setLoading(false);
        return false;
      }

      // Email is verified — complete registration by saving to Firestore
      _emailVerified = true;

      if (_pendingFullName != null &&
          _pendingEmail != null &&
          _pendingPhoneNumber != null) {
        _user = await _authService.completeRegistration(
          fullName: _pendingFullName!,
          email: _pendingEmail!,
          phoneNumber: _pendingPhoneNumber!,
        );
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Cancel registration and delete the unverified Firebase account.
  Future<void> cancelRegistration() async {
    await _authService.deleteCurrentUser();
    resetVerificationState();
  }

  // ─── PASSWORD RESET ───────────────────────────────────────────────────

  /// Send a password reset email.
  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // ─── LOGIN ───────────────────────────────────────────────────────────

  /// Login with email and password.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      _user = await _authService.loginWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store credentials securely for quick login re-authentication
      await LocalAuthService.saveCredentials(email, password);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Re-authenticate using stored credentials (for quick login).
  Future<bool> reAuthenticateWithStoredCredentials() async {
    _setError(null);

    try {
      final email = await LocalAuthService.getSavedEmail();
      final password = await LocalAuthService.getSavedPassword();

      if (email == null || password == null) {
        return false;
      }

      _user = await _authService.loginWithEmailAndPassword(
        email: email,
        password: password,
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Re-authentication failed: $e');
      return false;
    }
  }

  // ─── LOGOUT ──────────────────────────────────────────────────────────

  /// Sign out and clear state.
  /// Preserves stored credentials if quick login is enabled so the user
  /// can re-authenticate via PIN/biometric on next launch.
  Future<void> logout() async {
    // Check if quick login is configured before signing out
    final hasQuickLogin = await LocalAuthService.hasQuickLoginAvailable();

    await _authService.signOut();
    _user = null;
    _emailVerificationSent = false;
    _emailVerified = false;
    _pendingFullName = null;
    _pendingEmail = null;
    _pendingPhoneNumber = null;
    _error = null;

    // If no quick login is configured, clear stored credentials too
    if (!hasQuickLogin) {
      await LocalAuthService.clearCredentials();
      await LocalAuthService.clearLastLoggedIn();
    }

    notifyListeners();
  }

  /// Full logout — clears everything including quick login data.
  Future<void> fullLogout() async {
    final uid = await LocalAuthService.getLastLoggedInUid();
    await _authService.signOut();
    _user = null;
    _emailVerificationSent = false;
    _emailVerified = false;
    _pendingFullName = null;
    _pendingEmail = null;
    _pendingPhoneNumber = null;
    _error = null;

    // Clear all quick login data
    if (uid != null) {
      await LocalAuthService.clearUserAuthData(uid);
    }
    await LocalAuthService.clearCredentials();
    await LocalAuthService.clearLastLoggedIn();
    notifyListeners();
  }

  // ─── PROFILE MANAGEMENT ──────────────────────────────────────────────

  /// Update user profile fields (name, phone, bio, avatarId).
  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? bio,
    String? currency,
    double? monthlyBudget,
    String? avatarId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      if (_user == null) throw Exception('No user logged in.');

      final updatedUser = _user!.copyWith(
        fullName: fullName,
        phoneNumber: phoneNumber,
        bio: bio,
        currency: currency,
        monthlyBudget: monthlyBudget,
        avatarId: avatarId,
      );

      await _authService.updateUserProfile(updatedUser);
      _user = updatedUser;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Update user avatar selection.
  Future<bool> updateAvatar(String avatarId) async {
    _setLoading(true);
    _setError(null);

    try {
      if (_user == null) throw Exception('No user logged in.');

      await _authService.updateUserFields(
        _user!.uid,
        {'avatarId': avatarId},
      );

      _user = _user!.copyWith(avatarId: avatarId);
      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Change user password.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Update monthly budget.
  Future<bool> updateBudget(double budget) async {
    return updateProfile(monthlyBudget: budget);
  }

  /// Refresh user profile from Firestore.
  Future<void> refreshProfile() async {
    if (_user != null) {
      _user = await _authService.getUserProfile(_user!.uid);
      notifyListeners();
    }
  }
}
