# Phase 8 — Firebase Push / FID Report

## Status

COMPLETED. Genuine `android/app/google-services.json` is present and its Android
client package matches the final `com.yogaananda.hepasense` application ID.

## Firebase Integration

- Google Services Gradle plugin `4.5.0` uses the Kotlin plugin DSL and is
  applied only to the Android app module.
- Native Android default configuration is used: `Firebase.initializeApp()`
  consumes resources generated from `google-services.json`. No duplicate
  `firebase_options.dart` was generated or hand-authored.
- Added only `firebase_core 4.13.0`, `firebase_messaging 16.5.0`, and
  `firebase_app_installations 0.4.2+7`.
- The production adapter initializes Firebase before resolving Messaging or
  Installations singletons; failures remain non-fatal to the core app.
- Android notification permission is declared and requested once only after a
  Django-authenticated session. Denial is non-fatal.
- No custom background handler is required: FCM/Android handles background
  notification display, while open/cold-start events are handled after auth.

## Frozen Backend Contract

- FID source: `FirebaseInstallations.instance.getId()`.
- Register: `POST /api/v1/notifications/push-devices/` with exactly
  `{ "fid": "...", "platform": "android" }`.
- Device logout: `DELETE /api/v1/notifications/push-devices/{id}/` before auth
  tokens are cleared.
- Legacy `token`: never read or sent.
- Same FID is deduplicated; changed FID and account switch resync safely.
- Backend Firebase Admin project alignment could not be verified from local
  non-secret configuration and remains an operational check.

## Push Trust and Navigation

- Database Notification remains the source of truth. Foreground push only
  invalidates Notification state and refreshes authoritative unread count.
- Minimal payload validation uses positive `notification_id` and non-empty
  `type`; malformed payloads are dropped and unknown types remain safe.
- Medical payload extras are ignored, never displayed or persisted.
- Open and initial messages are deferred until authentication is ready and then
  route through the guarded Notification Center.
- The frozen payload has no Screening ID, so direct push-to-detail is not
  supported. Users open Detail from the authorized Notification row.
- No FID, FCM token, JWT, or medical push payload is logged.

## Validation

- `flutter clean`: PASS.
- `flutter pub get`: PASS.
- `dart format .`: PASS; 91 files unchanged.
- `flutter analyze`: PASS; 0 errors, warnings, or info.
- `flutter test`: PASS; 148 tests.
- `flutter build apk --debug`: PASS with generated Google Services resources.
- APK: `build/app/outputs/flutter-apk/app-debug.apk`.
- Connected Android device/emulator: unavailable (Linux desktop only).
- FID retrieval/local Firebase smoke: NOT EXECUTED.
- Real FCM delivery: NOT EXECUTED.

## Safety and Scope

- Backend modified: NO.
- API contract modified: NO.
- Migration: NO.
- Firebase Auth and unrelated Firebase products: NOT ADDED.
- Local notification package/custom alarm channel: NOT ADDED.
- Medical push data persistence: NONE.
- Phase 9: NOT STARTED.

## Known External Validation

- Confirm backend Firebase Admin credentials use the same Firebase project.
- On an Android device/emulator with Google Play Services, validate real FID
  retrieval and authenticated backend sync without printing the identifier.
- Send and receive a genuine FCM message to close end-to-end delivery evidence.

These external checks do not block source completion under the approved Phase
8 criteria.
