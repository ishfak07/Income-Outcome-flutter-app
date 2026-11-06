# Pocketly — Google Play Release Handoff

Last audited: **2026-11-06**  
Repository: `D:\Income-Outcome-flutter-app`  
Git branch: `main`  
Audited commit: `8967a53`  
Remote: `https://github.com/ishfak07/Income-Outcome-flutter-app.git`

This document is the source of truth for the next developer/agent preparing this app for Google Play. Do not upload the current project to production until every P0 item below is complete and a signed release App Bundle has passed internal testing on physical devices.

## 1. Executive summary

Pocketly is a Flutter/Firebase personal finance app. It lets an authenticated user record income and expenses, set a monthly budget, inspect charts and reports, export records, choose a currency/theme, and protect local access with PIN or biometrics.

The earlier startup/authentication failure has been substantially repaired. A debug APK has previously built, installed, and launched on a connected Android phone; live Firebase signup/login/profile/transaction smoke tests and Firestore rule deployment were also previously completed. However, **the app is not ready for Play production**. The largest remaining blockers are:

1. The release build is signed with the debug key.
2. The release/main Android manifest is missing `android.permission.INTERNET`.
3. There is no production account-deletion feature or public deletion web page.
4. There is no privacy policy URL or in-app privacy-policy link.
5. Savings Goals is demo-only, hardcoded, and not persisted.
6. Firebase Storage rules are not declared in `firebase.json` for deployment.
7. No signed release `.aab` has been built and tested.
8. Store listing assets, reviewer credentials, declarations, and support URLs are not prepared.

The dependency update notices are not the direct cause of the earlier Gradle failure. Do not perform an uncontrolled major-version upgrade immediately before release; upgrade deliberately and retest.

## 2. Current technical snapshot

| Item | Current value |
|---|---|
| Framework | Flutter 3.44.2 stable |
| Dart | 3.12.2 |
| Java | 17 (Android Studio JBR) |
| App version | `1.0.0+1` |
| Android application ID | `com.rumiishi.rumi_ishi_expense_tracker` |
| Android namespace | `com.rumiishi.rumi_ishi_expense_tracker` |
| Android display label | `Pocketly` in the current uncommitted worktree |
| Gradle wrapper | 9.1.0 (`all`) |
| Android Gradle Plugin | 9.0.1 |
| Kotlin plugin | 2.3.20 |
| Google Services plugin | 4.5.0 |
| Java/Kotlin target | JVM 17 |
| Firebase project ID | `rumi-ishi-expense-tracker` |
| Firebase project number | `293921789038` |
| Firebase Android app ID | `1:293921789038:android:965859206737a9f4ccc27f` |
| Firebase Storage bucket | `rumi-ishi-expense-tracker.firebasestorage.app` |
| State management | Provider / ChangeNotifier |
| Orientation | Portrait only |
| Ads / IAP | None found |
| Analytics / Crashlytics | None found |

The prior debug package reported `minSdk 24` and `targetSdk 36`. Because Flutter SDK-derived values can change, verify these again from the final release bundle rather than relying only on the Gradle source.

### Important identity decision

The package ID becomes effectively permanent after the first Play upload. Before creating the Play listing, the publisher must decide whether `com.rumiishi.rumi_ishi_expense_tracker` is the final public ID. If it changes, create/register the matching Firebase Android app, replace `google-services.json`, regenerate FlutterFire options, and retest authentication and Firestore. The worktree was concurrently renamed to **Pocketly** across user-facing labels during this audit; those brand edits are currently uncommitted and must be reviewed and preserved.

## 3. Product and feature inventory

### Authentication and account

- Email/password registration with Firebase Authentication.
- Email verification flow with resend/cancel handling.
- Login and logout.
- Password-reset email.
- Change password after reauthentication.
- Firestore user profile creation after verification.
- Profile editing: name, phone, bio, avatar/profile photo, currency, and monthly budget.
- Important: `deleteCurrentUser()` only cleans up an **unverified registration**. It is not a production account-deletion feature.

### Money tracking

- Create, edit, delete, and list expenses.
- Create, edit, delete, and list income.
- Dashboard totals and recent activity.
- Combined transaction history.
- Statistics/charts and financial reports.
- Monthly budget persisted on the user profile.
- Financial-health calculations.
- CSV and PDF export through the device share sheet.
- Recurring income processing exists.
- Expense records contain recurring fields, but no complete recurring-expense processor was found.

### Personalization and local security

- Currency/country selection.
- Light/dark theme.
- Local PIN and biometric quick login.
- Secure storage is used for quick-login credentials.
- Portrait orientation.

### Incomplete/demo feature

`lib/screens/savings_goals_screen.dart` seeds hardcoded sample goals into an in-memory list. Changes disappear when the screen/app restarts. A `SavingsGoal` model exists, but there is no Firestore service, provider, or rule for it. Before production, either:

- implement per-user persistence, validation, rules, empty states, edit/delete, and tests; or
- remove/hide Savings Goals and all navigation to it.

Do not market Savings Goals until it is real and tested.

## 4. App navigation and source map

The routes are assembled in `lib/main.dart`. Main screens include:

- Splash, login, registration, verification, forgot password.
- Dashboard.
- Add/edit expense and expense history.
- Add/edit income and income history.
- Combined transaction history.
- Profile and edit profile.
- Statistics, budget, reports, savings goals, and financial health.
- Settings, change password, security settings, PIN setup, and quick login.

Key implementation areas:

| Concern | Files |
|---|---|
| Startup/routes/providers | `lib/main.dart` |
| Firebase config | `lib/firebase_options.dart`, `android/app/google-services.json`, `firebase.json` |
| Authentication/profile/storage | `lib/services/auth_service.dart`, `lib/providers/auth_provider.dart` |
| Expenses | `lib/services/expense_service.dart`, `lib/providers/expense_provider.dart`, `lib/models/expense_model.dart` |
| Income | `lib/services/income_service.dart`, `lib/providers/income_provider.dart`, `lib/models/income_model.dart` |
| PIN/biometric/quick login | `lib/services/local_auth_service.dart` and security screens |
| Export | `lib/services/export_service.dart` |
| Theme/currency | `lib/providers/theme_provider.dart`, `lib/providers/currency_provider.dart` |
| Firebase access rules | `firestore.rules`, `storage.rules` |
| Android build | `android/settings.gradle`, `android/build.gradle`, `android/app/build.gradle`, `android/gradle/wrapper/gradle-wrapper.properties` |

## 5. Data model and backend paths

### Firestore paths

```text
/users/{uid}
/users/{uid}/expenses/{expenseId}
/users/{uid}/incomes/{incomeId}
```

### Storage path

```text
/profile_photos/{uid}.jpg
```

### User profile fields

- `uid`
- `fullName`
- `email`
- `phoneNumber`
- `isEmailVerified`
- `createdAt`
- `profilePhotoUrl`
- `avatarId`
- `bio`
- `currency`
- `monthlyBudget`

### Expense fields

- `id`, `userId`, `amount`, `category`, `description`
- `date`, `time`, `paymentMethod`
- `isRecurring`, `recurringFrequency`, `nextRecurringDate`
- `createdAt`

Expense categories: Food, Transport, Bills, Shopping, Entertainment, Health, Education, Travel, Groceries, Subscriptions, Other.

### Income fields

- `id`, `userId`, `amount`, `category`, `description`
- `date`, `time`, `paymentMethod`
- `isRecurring`, `recurringFrequency`, `nextRecurringDate`
- `createdAt`

Income categories: Salary, Freelance, Investments, Rental Income, Business, Gifts, Refunds, Side Hustle, Dividends, Other.

### Firestore rules status

Current rules restrict profiles and transaction subcollections to the authenticated owner. Create operations validate ownership, a positive amount, and category allowlists. Update validation is less strict than create validation and should be brought to the same schema/allowlist standard before production.

The current rules deny everything else, so a future `savingsGoals` collection will fail until explicitly designed and permitted.

Earlier work successfully deployed the revised Firestore rules to the live project. The local Firebase CLI currently has no active project alias, so future commands should use `--project rumi-ishi-expense-tracker` or add a reviewed `.firebaserc`.

### Storage rules status

`storage.rules` allows the owner to write their profile image, but any authenticated user can currently read all profile photos. Confirm whether photos are intended to be public-to-authenticated-users; otherwise restrict reads to the owner.

More importantly, `firebase.json` currently declares only Firestore rules. Add:

```json
"storage": {
  "rules": "storage.rules"
}
```

Then validate and deploy with:

```powershell
firebase deploy --only firestore:rules,storage --project rumi-ishi-expense-tracker
```

Never deploy permissive test-mode rules to production.

## 6. Work already completed and verified

Commit `8967a53` contains the most recent authentication/Firestore repair. Its message is:

> Refactor authentication flow to fix Firestore permission issues during user registration; update security rules and service methods for improved email verification handling

Previous verification during the repair effort included:

- `flutter test --no-pub`: **5/5 tests passed**.
- A debug APK built successfully.
- The debug APK installed and launched on a connected Android phone.
- The Android process remained alive with no fatal startup log.
- Live Firebase smoke testing previously passed registration, verification/profile handling, login, and transaction create/delete flows.
- Revised Firestore rules were previously deployed.
- Flutter web build/run also previously passed.

These results are useful but do **not** substitute for a signed release-bundle test. The current test suite contains only five lightweight tests and no widget, integration, Firebase Emulator, rules, migration, or account-deletion tests.

`flutter analyze --no-pub` currently reports approximately 325 diagnostics. No error-level diagnostics were observed in the audit, but the warnings include deprecated APIs, unused imports, `BuildContext` across async gaps, and many style/const issues. Triage all functional and lifecycle warnings; do not merely suppress them.

## 7. P0 blockers — required before any production upload

### P0.1 Add release Internet permission

`android/app/src/main/AndroidManifest.xml` lacks:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Debug/profile manifests add it automatically, which is why debug can communicate with Firebase. A release built from the current main manifest can lose network access. Add the permission to the main manifest and verify it in the merged **release** manifest and bundle.

### P0.2 Configure secure release signing

`android/app/build.gradle` currently contains:

```groovy
signingConfig = signingConfigs.debug
```

Create a private upload keystore, add a gitignored `android/key.properties`, load it from Gradle, define `signingConfigs.release`, and use it for release. Never commit the keystore, passwords, or `key.properties`. Back up the upload key and credentials in a secure password/secret manager.

Example key creation (publisher chooses secure values):

```powershell
keytool -genkeypair -v -keystore "$env:USERPROFILE\upload-keystore.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Use Google Play App Signing. The locally held key should be the upload key, not a casually shared production signing secret.

### P0.3 Implement complete account and data deletion

Google Play requires apps that let users create accounts to offer:

- a prominent in-app deletion path; and
- an external web deletion-request resource linked in Play Console.

Deletion must cover all associated data. Deleting `/users/{uid}` does **not** delete Firestore subcollections. The implementation must explicitly delete/batch:

1. `/users/{uid}/expenses/*`
2. `/users/{uid}/incomes/*`
3. future savings-goal data
4. `/profile_photos/{uid}.jpg`
5. `/users/{uid}`
6. the Firebase Authentication user
7. local PIN, quick-login credentials, preferences, and caches

Handle recent-login/reauthentication requirements, partial failures, retries, and user confirmation. For stronger reliability, use a trusted backend/Cloud Function or Firebase's official account-deletion approach rather than trusting only a client-side sequence.

Create a public HTTPS deletion page that identifies the app/developer, explains how to request deletion, lists deleted/retained data, and states any retention period.

### P0.4 Publish a complete privacy policy

There is no privacy policy in the repository or app. Publish an accessible, non-geofenced HTTPS page and link it:

- in Play Console;
- inside the app (Settings/About or registration); and
- preferably near account creation/consent.

It must accurately describe data collected, purposes, Firebase/service providers, security, sharing, retention, deletion, children/age position, international processing if applicable, and contact details. The developer/publisher named in the policy must match the store listing.

### P0.5 Resolve Savings Goals

Implement it completely with per-user persistence/rules/tests or remove it. Hardcoded sample financial goals presented as real user data are not release-ready and would make the listing misleading.

### P0.6 Build and test the signed App Bundle

After fixes:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

Expected artifact:

```text
build/app/outputs/bundle/release/app-release.aab
```

Upload first to Play Internal testing, install through Play, and test the actual distributed split APKs. Verify signing certificate fingerprints and add required SHA-1/SHA-256 fingerprints to Firebase if any configured services require them.

## 8. P1 engineering and security work

1. Review and commit the current cross-platform brand rename to `Pocketly`; confirm icons, splash branding, exported report text, documentation, and store metadata all match.
2. Confirm the final package ID before the first upload.
3. Increment `versionCode` for every Play upload; use a deliberate release version, not indefinitely `1.0.0+1`.
4. Add Storage configuration to `firebase.json`, review its privacy model, and deploy rules.
5. Apply equally strict schema/category/ownership checks to Firestore updates, not only creates.
6. Add Firebase App Check and monitor enforcement before enabling it fully.
7. Remove or release-guard `debugPrint` output that exposes local paths/download URLs.
8. Review the quick-login design. The password is stored in platform secure storage; document this honestly and consider a token/session-oriented approach.
9. Replace the local PIN's custom weak/fixed-salt hash with secure storage and a standard password KDF or a design that does not depend on a reusable password hash.
10. Add Crashlytics or another privacy-reviewed production error-monitoring system, with disclosures updated accordingly.
11. Test Firebase Authentication email templates, sender/support identity, authorized domains, resend limits, expired links, offline behavior, and verified/unverified transitions.
12. Upgrade dependencies carefully. Earlier `pub get` reported 108 newer versions outside current constraints. Prioritize Firebase and Android plugins, then regression-test. Major upgrades should be isolated from the first stable release if possible.
13. Address Android plugin/build warnings, including older plugin manifests/Kotlin plugin usage and deprecated AGP compatibility settings.
14. Confirm export files are cleaned up, contain only selected user data, and do not remain broadly accessible.
15. Add a Terms of Use if appropriate for the publisher/jurisdiction, and clearly state this is a personal record-keeping tool—not financial advice or a bank.

## 9. Required test expansion

At minimum add automated tests for:

- Registration, verification, cancellation, login, logout, reset password, and wrong-password paths.
- Firestore profile creation/reconciliation after verification.
- Expense/income create, update, delete, validation, and ownership isolation.
- Firestore and Storage security rules using Firebase Emulator Suite/rules-unit-testing.
- Full account deletion, including subcollections, photo, auth record, and local data.
- PIN/biometric fallback, device without biometrics, lockout, and credential clearing.
- Currency/amount/date calculations and timezone boundaries.
- Monthly budget and financial-health calculations.
- Recurring-income idempotency and duplicate prevention.
- CSV/PDF exports, special characters, empty state, large data, and share cancellation.
- Offline/no-network Firebase errors.
- Widget/navigation tests for critical screens.
- Integration test on at least one real Android device and one emulator/API level.

Manual release regression must include fresh install, upgrade from the previous version, background/restore, process death, denied permissions, no network, poor network, password reset, email verification, account deletion, and reinstall after deletion.

## 10. Google Play requirements relevant on 2026-11-06

The publishing agent must re-check policy immediately before submission because Google changes deadlines.

### Target Android API

New apps and updates must target Android 16 / API 36 from 31 August 2026. The current debug build reported target 36, but confirm it in the final AAB.  
Official source: [Google Play target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878)

### Android developer verification

Play packages and developer identity are subject to Android developer verification/package registration. Google Play may auto-register packages, but the developer identity and console tasks must be complete.  
Official source: [Android developer verification for Play developers](https://support.google.com/googleplay/android-developer/answer/16984799)

### Personal-account production access

If this is a personal developer account created after 13 November 2023, production access generally requires a closed test with at least 12 opted-in testers continuously for 14 days, followed by an application for production access.  
Official source: [App testing requirements for new personal developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465)

### App Bundle and Play App Signing

Publish an Android App Bundle and enroll/use Play App Signing.  
Official sources: [App Bundle publishing](https://support.google.com/googleplay/android-developer/answer/9859348), [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)

### Account deletion, privacy, and Data safety

Official sources:

- [Account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111)
- [User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311)
- [Data safety form guidance](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Privacy policy requirements](https://support.google.com/googleplay/android-developer/answer/18265346)

### Financial features declaration

All published apps must complete the financial-features declaration, including apps that declare they provide no financial features. This app tracks personal money but does not appear to offer banking, payments, lending, investment transactions, or financial advice. The publisher must review the exact Play form and make the accurate selection; do not guess or misrepresent it.  
Official source: [Financial features declaration](https://support.google.com/googleplay/android-developer/answer/13849271)

### App access for reviewers

Because almost all functionality is login-gated and uses email verification, provide Play reviewers with working reusable credentials and clear access instructions. Do not depend on a reviewer creating an account and accessing a private inbox.  
Official source: [App access requirements](https://support.google.com/googleplay/android-developer/answer/9859455)

### 16 KB page-size support

The target-API rules make 16 KB native page compatibility relevant. AGP 9 meets modern packaging expectations, but verify the final bundle/native libraries with Play pre-launch reporting, bundletool, and a 16 KB emulator/device.  
Official source: [Android 16 KB page-size guidance](https://developer.android.com/guide/practices/page-sizes)

### Other Play Console declarations

- Content rating questionnaire.
- Target audience and age groups.
- Ads declaration: currently expected to be **No**, if no ad SDK is added.
- App category: likely **Finance**.
- Country/region availability.
- News declaration if prompted: expected **No**.
- Government-app declaration if prompted: expected **No**.
- Data safety and deletion URL.
- Privacy policy and support contact.

Official content-rating source: [Play content ratings](https://support.google.com/googleplay/android-developer/answer/9859655)

## 11. Draft Data safety inventory — legal/publisher review required

This is a technical inventory, not a final legal answer. The publisher must reconcile it against every SDK, server log, backup, Firebase setting, support workflow, and the current Play questionnaire.

### Data the current app appears to collect

| Play-style category | Examples in this app | Required/optional | Primary purpose |
|---|---|---|---|
| Personal info — name | Full name | Required at registration | Account/app functionality |
| Personal info — email | Login/verification email | Required | Authentication/account management |
| Personal info — phone | Phone number | Currently requested | Profile/account functionality |
| User IDs | Firebase UID | Required/system-generated | Associate private data with account |
| Other personal info | Optional bio/avatar selection | Optional | Profile personalization |
| Photos | Optional profile photo | Optional | Profile personalization |
| Financial info | User-entered income, expenses, amounts, budgets, categories | Optional but core to app | Expense/budget functionality |
| User-generated content | Descriptions/notes attached to transactions | Optional | App functionality |
| Authentication info | Password handled by Firebase; quick login stores credentials in secure storage | Required for account | Authentication/security |

### Preliminary handling answers

- Sold: no evidence of sale.
- Advertising: no ad SDK found.
- Encrypted in transit: Firebase uses HTTPS/TLS; confirm all external links/services.
- Shared: Firebase may qualify as a service provider depending on contract/configuration and Play definitions. The publisher must review Google/Firebase terms and the current form. Do not automatically answer “not shared” without that analysis.
- User-initiated export: CSV/PDF is transferred through the Android share sheet at the user's request; assess it under Play's user-initiated transfer guidance.
- Deletion: currently not compliant for verified accounts; do not claim deletion support until implemented and tested.
- Retention: define a real retention schedule, including server backups/logs and legally required retention. Suggested product behavior is account lifetime plus the documented deletion/backup window.
- Security review: accurately answer only after release signing, rules, deletion, and security testing are complete.

## 12. Draft Play Store listing

The publisher owns the final brand, claims, spelling, localization, and contact details.

### Suggested title

**Pocketly**

### Suggested short description

**Track income, expenses, budgets and financial insights securely in one app.**

### Suggested full description

Pocketly helps you understand where your money comes from and where it goes.

Record everyday expenses and income, organize transactions by category, set a monthly budget, and review clear summaries of your finances. Charts and reports help you see patterns over time, while CSV and PDF export lets you keep or share a copy of your records when you choose.

Key features:

- Track income and expenses
- Organize transactions by category and date
- Set and monitor a monthly budget
- View statistics, reports, and financial-health insights
- Export records to CSV or PDF
- Choose your preferred currency and theme
- Secure account access with email verification
- Optional PIN and biometric quick access on supported devices

Your records are associated with your account so you can manage your personal finance information in one place.

Pocketly is a personal record-keeping tool. It does not provide banking services, payment processing, investment services, lending, or financial advice.

Do not mention Savings Goals in the listing unless it is fully implemented. Avoid unsupported claims such as “bank-grade security,” “100% secure,” or guaranteed financial improvement.

### Listing metadata

| Field | Draft |
|---|---|
| Category | Finance |
| Pricing | Free |
| Ads | No |
| In-app purchases | None |
| Primary language | Publisher decision |
| Support email | **Required — not yet supplied** |
| Website | **Recommended — not yet supplied** |
| Privacy policy URL | **Required — not yet supplied** |
| Account deletion URL | **Required — not yet supplied** |
| Target audience | Publisher must choose accurately; app is not child-directed |

## 13. Required Play listing assets

No dedicated Play Store asset set was found. Prepare:

- High-resolution icon: 512 × 512, 32-bit PNG, max 1 MB.
- Feature graphic: 1024 × 500, JPEG or 24-bit PNG without alpha.
- At least two phone screenshots; four polished portrait screenshots are recommended.
- Recommended phone screenshot size: 1080 × 1920 portrait (or eligible equivalent).
- Optional tablet/Chromebook screenshots only after those layouts are tested.
- App icon/adaptive icon tested on real launchers; current launcher icon must be reviewed for branding and safe zones.

Suggested screenshot sequence:

1. Dashboard — “See your money at a glance”
2. Add transaction — “Record income and expenses quickly”
3. Statistics — “Understand your spending patterns”
4. Budget/report — “Stay close to your monthly plan”

Use realistic fictional data, never real user information. The screenshots must match the shipping UI and must not imply unavailable features.

Official asset specifications: [Play preview assets](https://support.google.com/googleplay/android-developer/answer/9866151)

## 14. Release engineering procedure

### A. Prepare configuration

1. Decide final package ID and public app name.
2. Add Internet permission to the main manifest.
3. Create the upload key and release signing configuration.
4. Ensure keystore/key properties are ignored by Git.
5. Add Storage rules to `firebase.json` and deploy reviewed rules.
6. Implement deletion, privacy links, and the Savings Goals decision.
7. Set release version in `pubspec.yaml`, incrementing build number.
8. Review `google-services.json` and `firebase_options.dart` for the final package/project.
9. Configure Firebase App Check and production monitoring if adopted.

### B. Quality gate

```powershell
flutter doctor -v
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

Do not use `flutter pub upgrade --major-versions` as a release-fix shortcut. Commit dependency upgrades separately with tests.

### C. Inspect the release

- Confirm the AAB is signed with the upload certificate, not Android debug.
- Inspect merged release manifest for INTERNET, biometric permissions, package ID, label, and exported components.
- Confirm target SDK 36 and expected minimum SDK.
- Inspect Play Console App Bundle Explorer for unexpected permissions/native libraries.
- Run pre-launch report and address crashes, ANRs, accessibility, security, and compatibility findings.
- Test 16 KB page-size compatibility.
- Confirm obfuscation/minification choices and preserve mapping/native symbols if enabled later.

### D. Internal and closed testing

1. Upload to Internal testing.
2. Install from Play—not via local `adb install`—on a real phone.
3. Run the complete release regression checklist.
4. Fix issues and upload a higher version code.
5. If the developer account requires it, complete the 12-testers/14-day closed test.
6. Only then request production access or stage a production rollout.

### E. Production rollout

- Prefer a staged rollout.
- Monitor crashes, ANRs, Firebase errors, auth failures, and reviews.
- Keep a rollback/forward-fix plan and never reuse a version code.
- Do not delete or lose the upload key; follow Play's recovery process if compromised.

## 15. Play Console submission checklist

### App setup

- [ ] Final app name and package ID approved.
- [ ] Developer identity/organization details verified.
- [ ] App created in Play Console.
- [ ] Play App Signing enabled.
- [ ] Signed AAB accepted without errors.

### Store presence

- [ ] Title, short description, and full description finalized.
- [ ] 512 × 512 icon.
- [ ] 1024 × 500 feature graphic.
- [ ] At least two compliant screenshots; preferably four.
- [ ] Category/tags selected.
- [ ] Support email and optional website supplied.
- [ ] Privacy-policy URL live and linked in app.

### Policy declarations

- [ ] Data safety completed from verified data flows.
- [ ] Account-deletion URL live and in-app deletion tested.
- [ ] App access credentials/instructions supplied.
- [ ] Ads declaration completed.
- [ ] Target audience and content selected accurately.
- [ ] Content rating completed.
- [ ] Financial-features declaration completed.
- [ ] Any device/data/permission declarations completed.

### Testing/release

- [ ] Internal test passed from Play-distributed build.
- [ ] Pre-launch report reviewed.
- [ ] Physical-device critical-path test passed.
- [ ] 16 KB compatibility checked.
- [ ] Closed testing requirement completed if applicable.
- [ ] Production rollout and monitoring plan approved.

## 16. Definition of done

The app is ready for production only when all of the following are true:

1. A signed release AAB builds reproducibly and uses the private upload key.
2. The release can access Firebase because INTERNET is in the release manifest.
3. Registration, verification, login, reset, and profile creation pass on a Play-installed build.
4. Firestore/Storage rules are deployed, least-privilege, and tested against cross-user access.
5. Expense, income, budget, reports, and exports pass release regression.
6. Savings Goals is either real and persisted or absent.
7. Verified users can delete their account and associated data from the app, and a public deletion page exists.
8. Privacy policy, Data safety, financial declaration, app access, content rating, and audience answers are complete and accurate.
9. Store assets and listing match actual behavior.
10. Internal/pre-launch testing has no unresolved crash, ANR, security, or policy blocker.

## 17. Copy/paste prompt for the next coding agent

```text
You are preparing the Flutter project at D:\Income-Outcome-flutter-app for Google Play production. Read PLAY_STORE_HANDOFF.md completely before editing. Preserve the existing user commits and inspect the current git diff before each change.

Implement and verify the P0 items first: add INTERNET to the main/release manifest; replace debug release signing with a safe key.properties-based upload-key configuration without committing secrets; implement complete verified-account/data deletion (including Firestore subcollections, Storage photo, Firebase Auth, and local credentials) plus an in-app entry point; add in-app privacy/deletion links with configurable production URLs; add storage.rules to firebase.json and strengthen rules/tests; and either fully persist Savings Goals per user or remove it from production navigation.

Then improve the app label/versioning, address functional flutter analyze warnings, expand automated tests, and build a signed release AAB. Validate the merged release manifest, signing certificate, target SDK, Firebase flows, Play-installed internal test behavior, and 16 KB compatibility. Do not claim completion merely because a debug APK runs. Do not invent privacy/support URLs, legal declarations, keystore passwords, or publisher identity—leave explicit placeholders and request those owner decisions when needed. Update PLAY_STORE_HANDOFF.md as work is completed and report exact commands/results and remaining owner actions.
```

## 18. Owner decisions/information still needed

The coding agent cannot safely invent these:

- Final public app name and whether the current package ID is permanent.
- Legal developer/publisher name and country/jurisdiction.
- Play developer account type/date and verification status.
- Support email, website, privacy-policy URL, and deletion URL/domain.
- Final target audience/age groups and available countries.
- Whether phone number is genuinely required at registration.
- Data retention/backup periods and support deletion workflow.
- Whether profile photos should be readable by other authenticated users.
- Whether Savings Goals should be implemented or removed.
- Test-account credentials reserved for Play review.
- Secure custody location for upload key and credentials.

Until those decisions are supplied, the next agent should complete all safe code/test work, leave clear configuration placeholders, and stop before making legal or identity claims on the publisher's behalf.
