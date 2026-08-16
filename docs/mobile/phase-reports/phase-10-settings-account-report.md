# HepaSense Mobile — Phase 10 Report

## Actual scope

Account hub; existing Edit Profile linkage; frozen-contract password change; static Privacy and About; backend-backed Help; confirmed existing logout lifecycle.

## API integration

- Reused `GET /api/v1/accounts/profile/` and `PATCH /api/v1/accounts/profile/` from Phase 3.
- Added `POST /api/v1/accounts/change-password/` with exactly `old_password`, `new_password`, and `new_password_confirm`.
- Reused `GET /api/v1/education/articles/?type=help` and article detail.
- Reused `POST /api/v1/auth/logout/` and current push-device revocation lifecycle.

## Security and safety

- Password persisted: NO.
- Password logged: NO.
- Password state cleared: YES, after success and disposal.
- Successful change invalidates local auth after visible feedback because the backend blacklists all JWT sessions.
- No Screening details, tokens, Firebase identifiers, internal IDs, or device identifiers appear in Account UI.
- No fabricated support contact, compliance claim, medical diagnosis, notification preference, language option, PDF report, or account deletion.

## Figma

- File: `kIutNKXVzAlNjBkQO97ZWj`
- Account frame: `27:1685`
- Edit Profile frame: `27:1818`
- MCP: RATE LIMITED on the single focused Account request; no retries and no secondary call.
- Conceptual consistency: grouped cards, centered identity, 20 px margins, consistent rows/chevrons, separated logout, existing BottomNav.

Intentional deviations: Premium Member, My Plants, Total Scans, Garden Management, Download Reports, Language, unsupported Notification Settings, and PlantCare About were removed/replaced according to HepaSense contract truth.

## Validation

- Phase 9 baseline: 164 tests, analyzer clean, debug APK pass.
- Phase 10 focused tests: 16 pass.
- Final validation: `flutter pub get` PASS; `dart format .` PASS; analyzer PASS with 0 errors, 0 warnings, and 0 info; all 180 tests PASS.
- Debug APK: PASS; fresh artifact verified at `/home/yoga/Data/TFS/hepasense_mobile/build/app/outputs/flutter-apk/app-debug.apk` (177,545,848 bytes; 2026-08-15 09:26:29 +07:00).
- Runtime visual review: NOT EXECUTED; no Android device/emulator is available.

## Dependencies

NONE.

## Boundaries

- Existing Phase 3 profile reused: YES.
- Edit Profile duplicated: NO.
- Firebase modified: NO.
- Backend modified: NO.
- API contract modified: NO.
- Migration: NO.
- Phase 11 implemented early: NO.

## Known limitations

- No Android runtime visual review.
- App version is read from the current `pubspec.yaml` contract and displayed as `1.0.0 (1)`; no new package was added solely for runtime package metadata.
- Report-by-email remains deferred because no backend mail contract exists.
