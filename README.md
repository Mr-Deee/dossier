# THE DOSSIER
### Your Life. Your Wealth. Your Legacy.

Flutter + Firebase app implementing the Master Product Blueprint MVP (§12), with **end-to-end encryption**.
Every record and file is encrypted on the device before it reaches Firestore or Cloud Storage, so only the app (with
the user's passphrase) can decrypt it. See **[SECURITY.md](SECURITY.md)** for the cryptographic design.

## What's included

| Blueprint module | Implementation |
|---|---|
| Account & profile | Email sign-up/in, email verification, separate vault passphrase, recovery key, biometric quick unlock, auto-lock |
| My Life | Profile, education, career, achievements, life events, values, **life timeline**, life scorecard |
| My Wealth | Property, vehicles, financial assets, businesses, valuables, digital assets, liabilities, insurance, **net-worth dashboard** (ownership-share aware, per currency) |
| My Vault | Encrypted document upload, categories, search, expiry dates, link to assets, version history, decrypt & open |
| My Legacy | Beneficiaries, **will builder** (per-asset % allocation, alternates, conditions), executors/guardians, personal wishes, legacy messages, **will health check**, versioned will drafts with legal-status tracking |
| My Family | Family members, **family tree**, family history archive |
| My Succession | Trusted confidants with per-category sealed access, **Life Check**, access-request inbox with objection, **Legacy Switch** (verified, two-verifier release), estate execution dashboard for confidants, audit log |
| Dossier Intelligence | On-device assistant (no data leaves the phone), Legacy Readiness Index, reminders |
| Admin | Verification desk for accounts with the `verifier` claim |

```
lib/
  core/crypto/      crypto_primitives.dart (AES-GCM, Argon2id, X25519, HKDF), key_manager.dart (key hierarchy)
  core/schema/      record_types.dart — every record type & field (add a type here → form/list/detail for free)
  core/services/    session (auth + unlock), vault_repository (encrypted CRUD + files), succession_service
  core/logic/       analysis (net worth, health check, readiness, assistant), will_draft
  ui/               theme, widgets, screens
functions/          Cloud Functions (TypeScript): access requests, release approval, Life Check sweep, account purge
firestore.rules     owner-only + ciphertext-shape enforcement + release gating
storage.rules       encrypted-file storage + evidence uploads
test/               crypto & logic tests
```

## Setup

Requirements: Flutter 3.27+ (Dart 3.6+), Firebase CLI, Node 20, a Firebase project on the **Blaze** plan
(Cloud Functions need it).

```bash
# 1. Packages
flutter pub get

# 2. Firebase project (uses the existing dossier-a8fe7 config; to use another project run:)
dart pub global activate flutterfire_cli
flutterfire configure           # regenerates lib/firebase_options.dart + google-services files

# 3. In the Firebase console enable:
#    Authentication → Email/Password
#    Firestore (Native mode, region e.g. eur3 / europe-west1)
#    Storage
#    (optional) Extensions → "Trigger Email" on collection `mail` for email notifications

# 4. Deploy backend
cd functions && npm install && cd ..
firebase deploy --only firestore:rules,firestore:indexes,storage,functions

# 5. Run tests and the app
flutter test
flutter run
```

### Verification team accounts
Release requires approvals from two different verifiers (set `REQUIRED_APPROVALS=1` in the functions environment for
a pilot). Grant the role with a service-account key:

```bash
cd functions
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json node scripts/set-verifier.js lawyer@firm.com.gh
```
The user signs out and back in, then sees **Verification desk** in the menu.

### Testing the Legacy Switch end-to-end
1. Create accounts A (owner) and B (confidant), and complete vault setup on both.
2. A: My Succession → Add confidant → B's email → tick categories → compare B's fingerprint (B: Settings) → seal.
3. B: Shared with me → Request access (attach a PDF).
4. A sees the request and can **Object**. To test release, temporarily shorten `OBJECTION_DAYS` in
   `functions/src/index.ts`.
5. Two verifier accounts approve on the Verification desk. B taps **Open if released**.

## Notes
* The previous prototype used the Realtime Database with unencrypted data. This version uses **Cloud Firestore**, and
  old RTDB data is not migrated. Delete it from the console once you have moved to this version.
* Android `minSdk` is 23 and iOS deployment target is 15.0 (required by current Firebase SDKs). `MainActivity` is a
  `FlutterFragmentActivity` (required for biometrics) with `FLAG_SECURE`.
* A will draft is **not** a valid will. The app says so wherever drafts appear, and points users to legal review and
  proper execution under the Wills Act, 1971 (Act 360).
