POCKETLY ACCOUNT-DELETION MERGE
================================

READY-MERGED FILES
------------------
Copy the contents of this ZIP into your project root:

D:\Income-Outcome-flutter-app

The included paths are already correct.

WHAT CHANGED
------------
1. lib/screens/settings_screen.dart
   - Added a Pocketly-styled Delete Account tile under Account.
   - It opens AccountDeletionRequestScreen directly.

2. lib/screens/account_deletion_request_screen.dart
   - New in-app deletion request screen.
   - Opens the public deletion webpage.
   - Can open an email request with the signed-in Firebase email prefilled.

3. lib/config/account_deletion_config.dart
   - Holds the public deletion URL and support email.

4. docs/delete-account/index.html
   - Public account deletion request page for Google Play.

5. main.dart
   - Included unchanged. No route edit was needed.

6. pubspec.yaml
   - Included unchanged. Your project already has url_launcher ^6.2.5.

REQUIRED BEFORE RELEASE
-----------------------
Search the project for:

REPLACE_WITH_SUPPORT_EMAIL

and replace it in BOTH:

lib/config/account_deletion_config.dart
docs/delete-account/index.html

Use a real monitored support inbox.

GITHUB PAGES
------------
After committing the docs folder, enable GitHub Pages:
Settings -> Pages -> Deploy from a branch -> main -> /docs

Expected URL:
https://ishfak07.github.io/Income-Outcome-flutter-app/delete-account/

TEST
----
From the project root run:

flutter pub get
flutter analyze
flutter run

Then test:
Settings -> Account -> Delete Account

IMPORTANT
---------
This merge creates the request pathway. It does NOT automatically delete Firebase data.
For each verified request, actually delete the user's Firestore subcollections/data, profile photo in Storage, profile document, and Firebase Authentication user.
