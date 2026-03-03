import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';

/// AuthService handles all Firebase Authentication operations.
/// Includes email verification, email/password auth, and user profile management.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Get current Firebase user.
  User? get currentUser => _auth.currentUser;

  /// Get current user's UID.
  String? get currentUid => _auth.currentUser?.uid;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── UNIQUENESS CHECKS ───────────────────────────────────────────────

  /// Check if a phone number is already registered.
  Future<bool> isPhoneNumberRegistered(String phoneNumber) async {
    final query = await _firestore
        .collection('users')
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  /// Check if an email is already registered in Firestore.
  Future<bool> isEmailRegistered(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // ─── EMAIL VERIFICATION ──────────────────────────────────────────────

  /// Register user with email/password and send verification email.
  Future<UserCredential> registerAndSendEmailVerification({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Send verification email
      await userCredential.user?.sendEmailVerification();

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
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
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      return false;
    }
  }

  // ─── COMPLETE REGISTRATION ───────────────────────────────────────────

  /// Save user profile to Firestore after email verification.
  Future<UserModel> completeRegistration({
    required String fullName,
    required String email,
    required String phoneNumber,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found.');

    final userModel = UserModel(
      uid: user.uid,
      fullName: fullName.trim(),
      email: email.trim(),
      phoneNumber: phoneNumber,
      isEmailVerified: true,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

    return userModel;
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
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Login failed.');

      // Fetch user profile from Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) {
        throw Exception('User profile not found.');
      }

      return UserModel.fromMap(doc.data()!, user.uid);
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
      debugPrint('📸 Storage: Starting upload for uid=$uid, file=${imageFile.path}');
      debugPrint('📸 Storage: File exists=${imageFile.existsSync()}, size=${imageFile.lengthSync()} bytes');

      final ref = _storage.ref().child('profile_photos').child('$uid.jpg');
      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await uploadTask.ref.getDownloadURL();
      debugPrint('📸 Storage: Upload complete. Download URL: $url');
      return url;
    } on FirebaseException catch (e) {
      debugPrint('📸 Storage FirebaseException: code=${e.code}, message=${e.message}');
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
    try {
      await _auth.currentUser?.delete();
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
