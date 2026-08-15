# Phase 7 — Notification Center Report

## Status

COMPLETED. Database Notification is the source of truth. Firebase Push, FCM,
and Firebase Installation ID registration were not implemented.

## Contract and API Integration

Verified against frozen backend contracts:

- `GET /api/v1/notifications/?page={page}` — DRF-paginated current-user list.
- `GET /api/v1/notifications/unread-count/` — authoritative unread badge count.
- `POST /api/v1/notifications/{id}/read/` — idempotent owned-item read.
- `POST /api/v1/notifications/read-all/` — one scoped bulk update.

There is no public Notification detail, create, arbitrary update, or delete API.
The exact safe fields are `id`, `type`, `title`, `message`, nullable
`screening_id`, `is_read`, nullable `read_at`, and `created_at`.

## Implementation

- Added exact contract models, repository, explicit Riverpod states, paginated
  center controller, and shared unread-count controller.
- Added initial/loading/loaded/empty/error, refresh, next-page, mutation, and
  non-disruptive mutation-error behavior.
- Added duplicate request protection, ID deduplication, and generation-based
  stale-response protection.
- Read state changes only after backend success; failure preserves server truth.
- Mark-all uses the single backend bulk endpoint, never one request per row.
- Home header now opens Notification Center and renders only the authoritative
  unread count. No count is fabricated during loading/failure.
- Nullable `screening_id` renders safely; present IDs open the existing Phase 6
  detail route, whose neutral 404 behavior remains authoritative.
- Known types have semantic icons; future unknown types use a generic fallback.
- Jakarta wall-time uses the existing formatter without UTC conversion.
- Notification state is memory-only and invalidated on logout/account loss.

## UI and Accessibility

- Reuses Phase 4–6 AppBar, 20px list margin, card radius, typography, StateView,
  NavigationBar, error/retry, and pull-to-refresh patterns.
- Unread state is not color-only: it has stronger text weight, semantic
  “Belum dibaca” text, a dot, and border emphasis.
- Rows grow for long Indonesian messages and pass 360px width at 1.4× text.
- The mark-all AppBar action uses an icon plus full Indonesian tooltip to avoid
  narrow-width overflow.

## Validation

- `flutter pub get`: PASS; no dependency additions.
- `dart format .`: PASS; 85 files, no changes required.
- `flutter analyze`: PASS; 0 errors, 0 warnings, 0 info.
- `flutter test`: PASS; 124 tests.
- `flutter build apk --debug`: PASS.
- APK: `build/app/outputs/flutter-apk/app-debug.apk`.

## Safety and Scope

- Backend modified: NO.
- API contract modified: NO.
- Migration: NO.
- Healthcare API used: NO.
- Notification data persisted locally: NO.
- Firebase/FCM/FID/local notifications: NOT IMPLEMENTED.
- Android application ID: `com.yogaananda.hepasense` (FINAL).
- Firebase registration: NOT YET EXECUTED.
- No N+1 requests; one list request per page and one Screening detail request
  only after explicit user interaction.

## Visual and Runtime Review

- Figma file: `kIutNKXVzAlNjBkQO97ZWj`.
- Figma MCP: RATE LIMITED on the one targeted attempt.
- Visual consistency: PARTIAL against the established Phase 4–6 system; strict
  source-frame inspection was unavailable.
- Runtime emulator review: NOT EXECUTED.
- Local backend smoke: NOT EXECUTED.

## Known Limitations and Readiness

- No Firebase delivery behavior exists until Phase 8.
- Runtime visual and local backend smoke reviews were optional and not run.
- Android application ID prerequisite is complete; Firebase registration has
  not yet been executed.

There are no Mobile API contract blockers. The Android application ID is final,
and the validated project is ready for Phase 8. Phase 8 was not started.
