import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';

/// AuthService handles all Firebase Authentication operations.
/// Includes email verification, email/password auth, and user profile management.
class AuthService {
  // Keep Firebase access lazy so a setup error can be shown instead of
  // crashing while the app's providers are being constructed.
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  /// Get current Firebase user.
  User? get currentUser => _auth.currentUser;

  /// Get current user's UID.
  String? get currentUid => _auth.currentUser?.uid;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── UNIQUENESS CHECKS ───────────────────────────────────────────────

  // ─── EMAIL VERIFICATION ──────────────────────────────────────────────

  /// Register user with email/password, create Firestore profile, and send verification email.
  Future<UserCredential> registerAndSendEmailVerification({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    User? createdUser;
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      createdUser = userCredential.user;
      if (createdUser == null) {
        throw const AuthServiceException('Account creation failed.');
      }

      // Send first, so a mail failure does not leave a profile document.
      await createdUser.sendEmailVerification();

      final userModel = UserModel(
        uid: createdUser.uid,
        fullName: fullName.trim(),
        email: email.trim().toLowerCase(),
        phoneNumber: phoneNumber.trim(),
        isEmailVerified: false,
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection('users')
          .doc(createdUser.uid)
          .set(userModel.toMap());

      return userCredential;
    } on FirebaseAuthException catch (e) {
      await _rollbackRegistration(createdUser);
      throw _handleAuthException(e);
    } catch (e) {
      await _rollbackRegistration(createdUser);
      if (e is AuthServiceException) rethrow;
      if (e is FirebaseException) {
        throw AuthServiceException(
          'Could not create your profile (${e.code}). Please try again.',
        );
      }
      throw const AuthServiceException(
        'Could not finish account creation. Please try again.',
      );
    }
  }

  Future<void> _rollbackRegistration(User? user) async {
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).delete();
    } catch (_) {
      // The profile may not have been created yet.
    }
    try {
      await user.delete();
    } catch (_) {
      // Preserve the original registration error.
    }
  }

  /// Resend email verification to the current user.
  Future<void> resendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Check if the current user's email is verified.
  /// Reloads the user to get the latest status from Firebase.
  Future<bool> checkEmailVerified() async {
    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;
      final verified = user?.emailVerified ?? false;
      if (verified) {
        await user!.getIdToken(true);
      }
      return verified;
    } catch (e) {
      return false;
    }
  }

  // ─── COMPLETE REGISTRATION ───────────────────────────────────────────

  /// Update user profile to mark email as verified.
  Future<UserModel> completeRegistration({
    required String fullName,
    required String email,
    required String phoneNumber,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthServiceException('No authenticated user found.');
    }
    await user.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null || !refreshedUser.emailVerified) {
      throw const AuthServiceException(
        'Email not verified yet. Please open the verification link first.',
      );
    }
    // Refresh token claims so Firestore rules see email_verified == true.
    await refreshedUser.getIdToken(true);

    final fallbackProfile = UserModel(
      uid: refreshedUser.uid,
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      phoneNumber: phoneNumber.trim(),
      isEmailVerified: true,
      createdAt: DateTime.now(),
    );

    final profileRef = _firestore.collection('users').doc(refreshedUser.uid);
    final profileSnapshot = await profileRef.get();
    if (profileSnapshot.exists && profileSnapshot.data() != null) {
      await profileRef.update({'isEmailVerified': true});
      return UserModel.fromMap(
        profileSnapshot.data()!,
        refreshedUser.uid,
      ).copyWith(isEmailVerified: true);
    }

    // Recover an older partial account that has Auth but no profile document.
    await profileRef.set(fallbackProfile.toMap());
    return fallbackProfile;
  }

  // ─── LOGIN ───────────────────────────────────────────────────────────

  /// Login user with email and password.
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with email and password
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      await userCredential.user?.reload();
      final user = _auth.currentUser;
      if (user == null) {
        throw const AuthServiceException('Login failed.');
      }
      if (!user.emailVerified) {
        try {
          await user.sendEmailVerification();
        } finally {
          await _auth.signOut();
        }
        throw const AuthServiceException(
          'Please verify your email before logging in. A new verification email was sent.',
        );
      }
      await user.getIdToken(true);

      // Fetch user profile from Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) {
        await _auth.signOut();
        throw const AuthServiceException(
          'Your account profile is missing. Please contact support or register again.',
        );
      }

      var profile = UserModel.fromMap(doc.data()!, user.uid);
      if (!profile.isEmailVerified) {
        await doc.reference.update({'isEmailVerified': true});
        profile = profile.copyWith(isEmailVerified: true);
      }
      return profile;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ─── USER PROFILE ────────────────────────────────────────────────────

  /// Get user profile from Firestore.
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }

  /// Update user profile in Firestore.
  Future<void> updateUserProfile(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }

  /// Upload profile photo to Firebase Storage and return download URL.
  Future<String> uploadProfilePhoto(String uid, File imageFile) async {
    try {
      debugPrint(
          '📸 Storage: Starting upload for uid=$uid, file=${imageFile.path}');
      debugPrint(
          '📸 Storage: File exists=${imageFile.existsSync()}, size=${imageFile.lengthSync()} bytes');

      final ref = _storage.ref().child('profile_photos').child('$uid.jpg');
      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await uploadTask.ref.getDownloadURL();
      debugPrint('📸 Storage: Upload complete. Download URL: $url');
      return url;
    } on FirebaseException catch (e) {
      debugPrint(
          '📸 Storage FirebaseException: code=${e.code}, message=${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('📸 Storage unexpected error: $e');
      rethrow;
    }
  }

  /// Update specific fields of user profile.
  Future<void> updateUserFields(String uid, Map<String, dynamic> fields) async {
    await _firestore.collection('users').doc(uid).update(fields);
  }

  /// Change user password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No authenticated user found.');
      }
      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ─── PASSWORD RESET ───────────────────────────────────────────────────

  /// Send a password reset email to the given address.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ─── LOGOUT ──────────────────────────────────────────────────────────

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── DELETE UNVERIFIED USER ──────────────────────────────────────────

  /// Delete the current user if they didn't complete verification.
  Future<void> deleteCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).delete();
    } catch (_) {
      // The profile may not exist.
    }
    try {
      await user.delete();
    } catch (_) {
      // User may already be deleted or session expired
    }
  }

  // ─── ERROR HANDLING ──────────────────────────────────────────────────

  /// Convert Firebase auth exceptions to user-friendly messages.
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check and try again.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}

/// A user-facing authentication failure without Dart's `Exception:` prefix.
class AuthServiceException implements Exception {
  final String message;

  const AuthServiceException(this.message);

  @override
  String toString() => message;
}
