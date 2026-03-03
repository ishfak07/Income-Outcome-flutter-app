# 🔥 Firebase Setup Guide - Rumi Ishi Expense Tracker

## Prerequisites
- Flutter SDK (latest stable)
- Firebase CLI (`npm install -g firebase-tools`)
- A Google account

---

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/).
2. Click **"Add Project"** → Name it `rumi-ishi-expense-tracker`.
3. Enable Google Analytics (optional) → Click **"Create Project"**.

---

## Step 2: Add Android App

1. In Firebase Console → **Project Settings** → **Add App** → **Android**.
2. Enter package name: `com.rumiishi.rumi_ishi_expense_tracker`
3. Enter app nickname: `Rumi Ishi Expense Tracker`
4. Download `google-services.json`.
5. Place it in: `android/app/google-services.json`.

### Configure Android Gradle files:

This project uses the **new Gradle plugin DSL** (Flutter's current Android template). You **do not** need to add the Firebase Android BoM or `firebase-analytics` manually for a Flutter app — the Flutter Firebase packages (`firebase_core`, `firebase_auth`, `cloud_firestore`) bring the correct native dependencies.

Verify these two files match:

**`android/settings.gradle`** (project-level plugin versions):
```gradle
plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.google.gms.google-services" version "4.4.2" apply false
    id "com.android.application" version "7.3.0" apply false
    id "org.jetbrains.kotlin.android" version "1.7.10" apply false
}
```

**`android/app/build.gradle`** (app-level plugin applied):
```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"
}

android {
    defaultConfig {
        minSdk = 23 // Required for Firebase Auth
    }
}
```

---

## Step 3: Add iOS App (Optional)

1. In Firebase Console → **Add App** → **iOS**.
2. Enter bundle ID: `com.rumiishi.rumiIshiExpenseTracker`
3. Download `GoogleService-Info.plist`.
4. Place it in: `ios/Runner/GoogleService-Info.plist` (via Xcode).

---

## Step 4: Enable Authentication

1. In Firebase Console → **Authentication** → **Sign-in method**.
2. Enable **Email/Password**.
3. Enable **Phone** sign-in provider.
4. Add your test phone numbers under **Phone numbers for testing** (optional).

---

## Step 5: Setup Cloud Firestore

1. In Firebase Console → **Firestore Database** → **Create Database**.
2. Choose **Production mode**.
3. Select your preferred region.
4. Once created, go to **Rules** tab.
5. Copy and paste rules from `firestore.rules` in this project.
6. Click **Publish**.

### Create Firestore Index:

In Firebase Console → **Firestore** → **Indexes** → **Add Index**:

| Collection Group | Fields | Query Scope |
|---|---|---|
| `expenses` | `date` (ASC), `__name__` (ASC) | Collection |
| `expenses` | `date` (DESC), `__name__` (DESC) | Collection |

---

## Step 6: Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

Then configure:
```bash
flutterfire configure --project=rumi-ishi-expense-tracker
```

This automatically generates `firebase_options.dart`.

### Alternative (Manual Setup):
If not using FlutterFire CLI, update `lib/main.dart`:

```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_AUTH_DOMAIN",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_STORAGE_BUCKET",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_APP_ID",
  ),
);
```

---

## Step 7: Phone Auth Setup (Android)

### SHA Fingerprint:
```bash
cd android
./gradlew signingReport
```

Copy the **SHA-1** and **SHA-256** fingerprints.
Add them in Firebase Console → **Project Settings** → **Your Apps** → **Android** → **SHA certificate fingerprints**.

### Enable SafetyNet / Play Integrity:
1. Go to [Google Cloud Console](https://console.cloud.google.com/).
2. Make sure the Firebase project is selected.
3. Enable **Android Device Verification** API.

---

## Step 8: Run the App

```bash
# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Build release APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

---

## Project Structure

```
lib/
├── main.dart                  # App entry point, Firebase init, routes
├── models/
│   ├── user_model.dart        # User data model
│   └── expense_model.dart     # Expense data model
├── services/
│   ├── auth_service.dart      # Firebase Auth operations
│   ├── expense_service.dart   # Firestore CRUD for expenses
│   └── export_service.dart    # CSV/PDF export functionality
├── providers/
│   ├── auth_provider.dart     # Auth state management
│   ├── expense_provider.dart  # Expense state management
│   └── theme_provider.dart    # Theme mode management
├── screens/
│   ├── splash_screen.dart     # Animated splash screen
│   ├── login_screen.dart      # Phone + password login
│   ├── register_screen.dart   # Registration form
│   ├── otp_screen.dart        # OTP verification
│   ├── home_dashboard.dart    # Main dashboard
│   ├── add_expense_screen.dart    # Add new expense
│   ├── edit_expense_screen.dart   # Edit/delete expense
│   ├── expense_history_screen.dart # History with filters
│   └── profile_screen.dart    # User profile & settings
├── widgets/
│   ├── glass_card.dart        # Glassmorphism card widget
│   ├── animated_button.dart   # Gradient animated button
│   ├── expense_card.dart      # Expense list item card
│   └── empty_state.dart       # Empty state placeholder
└── utils/
    ├── app_theme.dart         # Theme configuration
    ├── constants.dart         # App-wide constants
    └── validators.dart        # Form validators
```

---

## Security Features

- ✅ Firebase Auth with phone OTP verification
- ✅ UID-based Firestore access control
- ✅ Phone number uniqueness enforcement
- ✅ Password encryption (Firebase default)
- ✅ Strict Firestore security rules
- ✅ Input validation on all forms
- ✅ No cross-user data access

---

## Troubleshooting

### "No Firebase App" Error
Make sure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is properly placed and `Firebase.initializeApp()` is called before `runApp()`.

### Phone Auth Not Working
1. Ensure SHA fingerprints are added to Firebase.
2. Enable Play Integrity API.
3. For testing, add test phone numbers in Firebase Console.

### Firestore Permission Denied
Check that Firestore rules are published and the user is authenticated.
