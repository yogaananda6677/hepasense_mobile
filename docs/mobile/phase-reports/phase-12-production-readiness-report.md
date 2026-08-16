# Mobile Phase 12 — Final Production Readiness Report

## Verdict

Phase 12 source work is COMPLETED. SOURCE READY: YES. MOBILE SOURCE FREEZE: YES.
PRODUCTION READY: NO because device/backend/Firebase delivery validation,
official production API configuration, legitimate distribution signing, and
branding-asset review remain open.

Open source findings: Critical 0, High 0, Medium 0, Low 2. The two Low findings
are the unchanged default Flutter launcher icon and default native splash; no
approved HepaSense replacement assets were available, so Phase 12 did not
invent branding. External validation items: 5. Deployment requirements: 4.

## Release defects corrected

- Changed Android label from the template `hepasense_mobile` to `HepaSense`.
- Added release `INTERNET` permission, without which production API access would fail.
- Explicitly disallowed cleartext in main/release configuration and isolated the emulator HTTP exception to the debug manifest.
- Removed unverified staging/production hostname fallbacks. Non-development builds now require an explicit `API_BASE_URL`; the development-only `10.0.2.2` fallback remains isolated.
- Removed unused direct dependency `cupertino_icons`.
- Added release configuration regression tests.

## Identity, Firebase, and Android

- Namespace/application ID/MainActivity/Firebase Android client all match `com.yogaananda.hepasense`; old active `com.example` references: 0.
- `google-services.json` is present. Its secrets/client identifiers were not printed.
- Backend Firebase Admin project match is NOT VERIFIED: no local backend project configuration is present.
- `flutter devices` found Linux only. Firebase initialization, FID retrieval/sync, real FCM, visual runtime review, and APK installation were NOT EXECUTED.
- Local backend health at `127.0.0.1:8000` was unavailable; authenticated smoke was NOT EXECUTED.
- Main permissions: INTERNET and POST_NOTIFICATIONS. Firebase/Google Play manifest merge adds WAKE_LOCK, ACCESS_NETWORK_STATE, C2DM RECEIVE, and the application-scoped dynamic-receiver permission. No camera, microphone, location, contacts, or storage permission exists.
- Production cleartext is false. No custom trust manager, certificate bypass, or bad-certificate callback exists.

## Security and privacy

- No private key, service-account credential, JWT, password, API secret, hardcoded test credential, or Firebase Admin credential was found in production source.
- No production logging call exposes password, OTP, JWT, refresh token, FID, FCM token, authorization header, Patient data, or Screening values.
- Access token and account/medical state remain memory-only. Refresh token alone uses `flutter_secure_storage`. Password and OTP remain widget-controller memory and are cleared/disposed.
- No general database/cache persists Patient, Screening, History, Detail, Notification, or push medical payload data.
- No screenshot/recents privacy policy exists. `FLAG_SECURE` was not added without product approval; this remains a deployment privacy decision.
- Root detection, Play Integrity, and code obfuscation are not configured and are not source blockers for this MVP.

## Contract and medical safety

All production repository paths match backend contracts for auth/accounts,
Patient self, Screening latest/history/detail, Notifications/read state,
FID devices, and Education/Help. Request fields match, including `fid`; legacy
`token` is unused. Decimal fields remain JSON strings and use safe parsing.
Backend timestamps are parsed exactly as Asia/Jakarta local text without `Z`,
offset conversion, or double +7 adjustment.

Database Notification and backend Screening data remain authoritative. Push
extras cannot become medical UI. Invalid sample remains separate from
healthy/warning/high-risk. High risk is not diagnosis; confidence is not
disease probability. Nutrition is general backend education and receives no
NH3/classification/confidence personalization. No unsupported compliance,
clinical-validation, regulatory, treatment, or cure claim was found.

## Dependency and performance audit

Direct runtime dependencies are each used: Riverpod, go_router, Dio,
flutter_secure_storage, firebase_core, firebase_messaging, and
firebase_app_installations. Flutter test/lint/mock packages remain under
`dev_dependencies`. No broad upgrade was performed.

Network work is controller/repository-owned rather than started directly from
widget build. Startup does not block the first frame on Firebase. Firebase
initializes once; FID registration and resume refresh are guarded. History,
Notification, and Education use lazy lists/pagination, prevent parallel page
requests, de-duplicate IDs, and perform no N+1 requests. Remote Education
thumbnails are parsed but intentionally not rendered, avoiding unsafe or
unbounded image work.

## End-to-end matrix

| ID | Scenario | Result |
|---|---|---|
| A | Fresh install / first launch | NOT EXECUTED |
| B | Logged-out launch | AUTOMATED PASS |
| C | Login success | AUTOMATED PASS |
| D | Login failure | AUTOMATED PASS |
| E | MFA | AUTOMATED PASS |
| F | Session restore | AUTOMATED PASS |
| G | Unlinked Patient | AUTOMATED PASS |
| H | Linked Patient | AUTOMATED PASS |
| I | Home no Screening | AUTOMATED PASS |
| J | Home valid Screening | AUTOMATED PASS |
| K | Home invalid Screening | AUTOMATED PASS |
| L | History empty | AUTOMATED PASS |
| M | History pagination | AUTOMATED PASS |
| N | Screening Detail | AUTOMATED PASS |
| O | Notifications | AUTOMATED PASS |
| P | Firebase permission denied | AUTOMATED PASS |
| Q | Education | AUTOMATED PASS |
| R | Nutrition | AUTOMATED PASS |
| S | Account | AUTOMATED PASS |
| T | Change Password | AUTOMATED PASS |
| U | Privacy | AUTOMATED PASS |
| V | Help/About | AUTOMATED PASS |
| W | Logout | AUTOMATED PASS |
| X | Account switch | AUTOMATED PASS |
| Y | Offline/network error | AUTOMATED PASS |
| Z | Expired session | AUTOMATED PASS |

No row is marked runtime pass because no Android target was available.

## Build configuration and validation

- Version: `1.0.0+1`; Android version name `1.0.0`, code `1`.
- Release signing: NOT CONFIGURED. The Gradle release block currently points to debug signing and is not legitimate distribution signing.
- Obfuscation/minification/resource shrinking: NOT CONFIGURED.
- `flutter clean`: PASS.
- `flutter pub get`: PASS.
- `dart format .`: PASS (111 files).
- `flutter analyze`: PASS (0 errors, 0 warnings, 0 info).
- `flutter test`: PASS (197 tests).
- `flutter build apk --debug`: PASS.
- Debug APK: `/home/yoga/Data/TFS/hepasense_mobile/build/app/outputs/flutter-apk/app-debug.apk` (155,918,382 bytes).
- Release APK/AAB: NOT EXECUTED — legitimate signing is not configured.

## Final mobile contract

- AUTH: Django JWT + MFA.
- PATIENT: no self-claim and no auto-create.
- SCREENING: backend source of truth.
- CLASSIFICATION: healthy / warning / high_risk.
- INVALID SAMPLE: distinct from classification.
- CONFIDENCE: not disease probability.
- NOTIFICATIONS: database source of truth.
- PUSH: Firebase delivery signal only.
- FID: `FirebaseInstallations.instance.getId()`; request field `fid`; legacy `token` unused.
- EDUCATION/NUTRITION: backend educational content; no diagnosis from mobile.

## Requirements before production release

1. Supply the official HTTPS production API URL via `--dart-define=APP_ENV=production --dart-define=API_BASE_URL=...`.
2. Configure an owner-controlled release keystore/signing workflow; then build and validate release APK/AAB.
3. Validate fresh install and the complete safe flow on Android, including real Firebase initialization/FID, authenticated FID sync/revoke, project match, and genuine FCM delivery.
4. Review/replace default Flutter launcher/splash assets with approved HepaSense branding and decide the Android recents-preview policy.

No backend, API contract, or migration was modified. No further mobile phase was started.
