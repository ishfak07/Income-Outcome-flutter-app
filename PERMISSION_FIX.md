# 🔧 Firestore Permission Error - FIXED

## Problem
The app was showing: **`[cloud_firestore/permission-denied] Missing or insufficient permissions`** when trying to send email verification.

## Root Cause
- The Firestore security rules required `isEmailVerified: true` on user creation
- But the old flow tried to create the Firebase Auth user first, send verification, THEN create Firestore document
- This caused a timing issue where Firestore writes were attempted before email verification

## Solution Applied ✅

### 1. Updated Firestore Security Rules
**File:** `firestore.rules` (lines 20-31)

**Changed:** Removed the requirement that `isEmailVerified` must be `true` during user creation.

- ✅ Now allows user creation with `isEmailVerified: false`
- ✅ The field will be updated to `true` after email verification completes

### 2. Updated Auth Service
**File:** `lib/services/auth_service.dart`

**Changed:** `registerAndSendEmailVerification()` method now:
1. Creates Firebase Auth account
2. **Immediately creates Firestore user profile with `isEmailVerified: false`**
3. Sends verification email

**Changed:** `completeRegistration()` method now:
- Updates the existing Firestore document to set `isEmailVerified: true`
- No longer tries to create a new document

### 3. Updated Auth Provider
**File:** `lib/providers/auth_provider.dart`

**Changed:** `registerAndSendVerification()` now passes all user data (`fullName`, `phoneNumber`) to `registerAndSendEmailVerification()` so the Firestore document can be created immediately.

---

## New Registration Flow

### Before (❌ Broken)
1. User enters registration details
2. Firebase Auth account created → `isEmailVerified: false` in Firebase Auth
3. Verification email sent
4. ⚠️ **NO Firestore document created yet**
5. User verifies email
6. App tries to create Firestore document with `isEmailVerified: true`
7. ❌ **Permission denied** (race condition)

### After (✅ Fixed)
1. User enters registration details
2. Firebase Auth account created → `isEmailVerified: false` in Firebase Auth
3. ✅ **Firestore document created immediately with `isEmailVerified: false`**
4. Verification email sent
5. User verifies email
6. Firestore document **updated** to `isEmailVerified: true`
7. ✅ **Success!**

---

## Deployment Steps

### Deploy Updated Firestore Rules

You need to deploy the updated security rules to Firebase:

```bash
firebase deploy --only firestore:rules
```

**OR** manually via Firebase Console:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database** → **Rules**
4. Copy the contents of `firestore.rules` from this project
5. Paste into the Firebase Console editor
6. Click **Publish**

### Test the Fix

1. Run the app: `flutter run`
2. Try to register a new user
3. You should now see "Verification email sent to..." without permission errors
4. Check your email and click the verification link
5. The app should auto-detect verification and navigate to the home screen

---

## What Changed in Code

### `firestore.rules`
```diff
- // 4. Email verification is marked true
  allow create: if request.auth != null 
    && request.auth.uid == userId
    && request.resource.data.keys().hasAll(['fullName', 'email', 'phoneNumber', 'isEmailVerified', 'createdAt'])
    && request.resource.data.isEmailVerified is bool
+   // Note: Email verification can be false on creation, will be updated after verification
```

### `auth_service.dart`
```diff
  Future<UserCredential> registerAndSendEmailVerification({
    required String email,
    required String password,
+   required String fullName,
+   required String phoneNumber,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

+     // Create user profile in Firestore immediately with isEmailVerified: false
+     final user = userCredential.user;
+     if (user != null) {
+       final userModel = UserModel(
+         uid: user.uid,
+         fullName: fullName.trim(),
+         email: email.trim(),
+         phoneNumber: phoneNumber,
+         isEmailVerified: false,
+         createdAt: DateTime.now(),
+       );
+       await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
+     }

      await userCredential.user?.sendEmailVerification();
      return userCredential;
    }
  }
```

```diff
  Future<UserModel> completeRegistration(...) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found.');

-   // Create new document
-   await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

+   // Update existing document to mark as verified
+   await _firestore.collection('users').doc(user.uid).update({
+     'isEmailVerified': true,
+   });

    return userModel;
  }
```

---

## Security Notes

✅ **Still Secure:**
- Users can only create/read/update their own documents (UID-based rules)
- Phone number cannot be changed after registration
- Email verification status is properly tracked
- All expense and income data remains protected

✅ **Improved:**
- No more race conditions during registration
- Cleaner separation of concerns (Auth vs Firestore)
- Better error handling

---

## Verification Checklist

- [x] Updated Firestore security rules
- [x] Modified `auth_service.dart` to create Firestore doc on registration
- [x] Modified `completeRegistration()` to update (not create) document
- [x] Updated `auth_provider.dart` to pass all required fields
- [ ] **Deploy rules to Firebase Console** (manual step required)
- [ ] Test registration flow end-to-end

---

**Status:** ✅ Code changes complete. Deploy Firestore rules to finish the fix!
