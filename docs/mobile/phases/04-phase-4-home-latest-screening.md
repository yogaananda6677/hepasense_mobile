# HepaSense Mobile — Phase 4: Home Dashboard & Latest Screening

## 1. Objective

Implement the authenticated Home/Beranda dashboard: greeting/profile summary, Patient linkage state, the latest Screening card (`GET /api/v1/screenings/latest/`), centralized screening-status presentation (healthy/warning/high_risk/invalid), invalid-sample presentation, the no-screening state, refresh, error/retry, and the notification unread badge (`GET /api/v1/notifications/unread-count/`).

## 2. Why This Phase Exists

Home is the primary authenticated screen (PRD §24) and the first place real screening data reaches the user. It depends on Phase 2 (session) and Phase 3 (Patient linkage). It introduces the centralized screening-status mapping that Phases 5–7 reuse.

## 3. Required Reading

- `docs/mobile/00-mobile-prd.md`: §§24–27, 420–426, 547–603, 742–839, 1390–1651.
- `docs/mobile/02-api-integration-contract.md` §§3–4 (screening latest/detail).
- `docs/mobile/phases/02-phase-2-authentication-mfa.md` and 03-phase-3-patient-profile.md.
- Backend `docs/backend/10-phase-4-screening-query-api.md` (including 404 semantics and patient-safe serializer).
- Backend `docs/backend/05-data-model-draft.md` §37–58 (status derivation).
- Figma Home/Beranda, latest-screening card, notification badge.

## 4. Preconditions

- Phase 2 complete: authenticated session, protected routes.
- Phase 3 complete: Patient linkage resolution available.
- Backend Phase 4 (screenings latest) COMPLETED.

## 5. Repository Audit Before Editing

- Inspect Phase 1 `status_mapping.dart` (refine, do not replace) — Phase 4 centralizes the canonical status→label/color/badge mapping here.
- Inspect Phase 1 `StateView`, `StatusBadge`, theme tokens.
- Inspect Phase 2 `AuthNotifier`/session and Phase 3 `PatientRepository`/linkage result for Home composition.
- Inspect `docs/mobile/02-api-integration-contract.md` §3 for the exact latest response shape and 404 message.

## 6. In Scope

- [ ] **Authenticated Home shell**: greeting + profile/patient summary; reuse Phase 3 patient-linkage fetch (linked vs. unlinked).
- [ ] **Latest Screening** (`GET /api/v1/screenings/latest/`): success card (status, time/date, corrected NH3+unit, measurement summary), navigation to Screening Detail.
- [ ] **UI states for latest**: loading, success, no-screening (`sample_valid`/`status` absent or 404), unlinked-Patient, network failure, session expired, server error (PRD §750, §1370).
- [ ] **Invalid-sample presentation**: `sample_valid=false`, `classification=null` → `status=invalid` → dedicated "Pemeriksaan Tidak Valid" state; do NOT manufacture healthy/warning/high_risk (PRD §817, §826, §830).
- [ ] **Status presentation**: centralized mapping `healthy|warning|high_risk|invalid` → label/icon/copy; color is support only, never sole communicator (PRD §59, §26); copy is screening language, not diagnosis (PRD §3).
- [ ] **Date/time formatting**: parse ISO `measured_at`, display local; preserve original instant (PRD §64, §664).
- [ ] **Number formatting/units**: NH3 corrected + unit (ppm), temperature Celsius, humidity %, flow quality, expiration seconds — retain units, no false precision (PRD §65, §678).
- [ ] **Refresh**: pull-to-refresh + app-resume freshness for latest + unread count (PRD §59, §1597, §1615).
- [ ] **Notification unread badge** (`GET /api/v1/notifications/unread-count/`): badge count; refresh after mark-read/mark-all (cross-screen) (PRD §63, §1632).
- [ ] **Navigation**: latest card → Screening Detail (id from the latest response); history shortcut → History (Phase 5); notifications → Notification Center (Phase 7); account → Account (Phase 3) (PRD §24, §254, §2485).
- [ ] **Safe copy**: medically conservative Indonesian; "Hasil skrining menunjukkan…", "Disarankan melakukan pemeriksaan lebih lanjut…" (PRD §109–113).

## 7. Out of Scope

- History (Phase 5), Screening Detail (Phase 6), Notification Center (Phase 7), Firebase (Phase 8), Education (Phase 9).
- Creating/guessing Patient (Phase 3 rule; PRD §707).
- Displaying raw NH3, device metadata, credential verifier, digest, fingerprint references (Backend Phase 4 §74, PRD §924).
- Presenting confidence as a calibrated probability (PRD §32, §951).

## 8. Backend Contract

| Method | Path | Auth | Response (key fields) |
|---|---|---|---|
| GET | `/api/v1/screenings/latest/` | JWT (MFA) | `{ id, screening_uid, measured_at, status, sample_valid, measurement{nh3_corrected,nh3_unit,temperature_celsius,humidity_percent,flow_quality,expiration_duration_seconds}, result{classification,confidence_score} }` |
| GET | `/api/v1/notifications/unread-count/` | JWT | `{ unread_count: N }` |
| GET | `/api/v1/patients/me/` | JWT | linked Patient summary or 404 (Phase 3) |

- `status` is derived: `invalid` when `sample_valid=false`; otherwise the classification (Backend Phase 4 §40, PRD §780). A 404 on latest means "no screening yet", **not** a generic error (PRD §768, §772).
- `confidence_score` returned as stored; do not label as probability (PRD §32, §951).
- Machine auth (`HepaSense`) cannot read patient screenings; only MFA-enforcing human JWT (Backend Phase 4 §17).

## 9. Data / Domain Rules

- `invalid` ≠ healthy/warning/high_risk (PRD §27, §826). Never fabricate a classification from an invalid sample.
- `high_risk` ≠ confirmed disease (PRD §26, §813).
- `confidence_score` ≠ calibrated medical probability (PRD §32, §951).
- `measured_at` displayed local; original instant preserved (PRD §664, §678).
- Unread count is backend-authoritative; do not maintain a drifting local count (PRD §1649).
- Screening ownership is server-enforced; never send arbitrary `patient_id`/`user_id` (PRD §741).

## 10. UI / Figma Requirements

- Home screen per Figma: greeting, patient/profile summary, latest screening card, navigation shortcuts.
- Reusable `StatusBadge` + centralized `StatusMapping` from Phase 1 (refined here).
- Reusable `StateView` for loading/empty/error.
- Medically conservative copy only (PRD §3, §99–113).
- SafeArea/keyboard/small-phone/text-scaling (PRD §229).

## 11. State Requirements

- Latest screening: `initial | loading | success | no_screening | invalid_sample | unlinked_patient | error | session_expired`.
- Patient state: `loading | linked | unlinked | error`.
- Unread badge: `loading | ready | error`.
- Home overall: `loading | ready | error | auth_error`.
- Refresh: in-flight single request; pull-to-refresh.

## 12. Architecture Requirements

- New `ScreeningsRepository` + `LatestScreeningRepository` over the shared API client (PRD §13, §419).
- Centralized `StatusMapping` in `core/errors/status_mapping.dart` — the single source for healthy/warning/high_risk/invalid labels/icons/copy across Home, History, Detail, Notifications.
- `HomeViewModel` (Riverpod) composes Patient linkage + latest screening + unread count; single coordinator prevents duplicate parallel latest requests and refresh storms (PRD §92, §1626).
- Date/number formatting helpers in `core/utils/` (parse ISO safely; format local).

## 13. Security & Privacy Requirements

- No raw/internal screening fields displayed (Backend Phase 4 §74, PRD §924).
- No device credentials (PRD §53, §91).
- Unread-count calls reuse the authenticated JWT interceptor (Phase 2).
- No PHI cached to disk beyond tokens (PRD §53, §1349).

## 14. Implementation Tasks

- [x] Inspect Phase 1 status mapping + StateView/StatusBadge; Phase 2 session; Phase 3 patient linkage.
- [x] Reuse centralized `StatusMapping` (labels/icons/copy, invalid ≠ classification, color-not-only).
- [x] Implement `ScreeningRepository.latest()`; parse safe fields.
- [ ] Implement `NotificationsRepository.unreadCount()`.
- [ ] Implement `HomeViewModel` (compose patient state + latest + badge; coordinate refresh).
- [ ] Implement Home screen UI: greeting, patient summary, latest card, shortcuts, badge.
- [ ] Implement latest-screening states (success/no-screening/invalid/unlinked/error/session-expired).
- [ ] Implement status presentation + safe copy (screening language).
- [ ] Implement date/time + number/unit formatting helpers.
- [ ] Wire pull-to-refresh + app-resume freshness for latest + badge.
- [ ] Wire navigation: latest card → Detail(id), history → History, notifications → Notifications, account → Account.
- [ ] Add Phase 4 report.
- [ ] Run `dart format .`, `flutter analyze`, `flutter test`.

## 15. Tests Required

- Unit: `StatusMapping` maps all four statuses; `invalid` never returns a classification label; confidence not labeled as probability.
- Unit: latest 404 → `no_screening`; `sample_valid=false`/`status=invalid` → `invalid_sample` (not manufactured).
- Widget: Home renders loading/success/no-screening/invalid/unlinked/error states.
- Widget: `StatusBadge` renders all statuses with non-color text.
- Integration (mock — PRD §77): latest response maps to the safe card fields; no raw/credential fields parsed.
- Regression: invalid sample never displays healthy/warning/high_risk.

## 16. Validation Commands

```bash
cd /home/yoga/Data/TFS/hepasense_mobile
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

## 17. Definition of Done

- [ ] Home renders authenticated shell with greeting + patient summary + latest card + shortcuts + badge.
- [ ] Latest Screening states all implemented and distinct (PRD §750, §1370).
- [ ] Invalid sample presented correctly; no classification manufactured (PRD §817, §826).
- [ ] Status mapping centralized and reused; non-diagnostic copy only (PRD §3, §26).
- [ ] Date/time + units preserved, no false precision (PRD §64, §65).
- [ ] Refresh + badge sync implemented (PRD §59, §63, §1597, §1632).
- [ ] `flutter analyze` clean; `flutter test` passes.
- [ ] `flutter build apk --debug` passes.

## 18. Stop Conditions / Blockers

- STOP if backend latest contract/response shape differs from Backend Phase 4 §49–72 — re-audit.
- STOP if the latest 404 is implemented as a generic error instead of "no screening yet" (PRD §768).

## 19. Required Documentation Output

`docs/mobile/phase-reports/phase-4-home-latest-screening-report.md`: files changed, APIs integrated (screenings/latest, notifications/unread-count, patients/me), tests + results, analyzer/build, reuse of Phase 1 status mapping, known limitations, blockers, readiness for Phase 5.

## 20. Required Final Response

```text
PHASE:
STATUS:
IMPLEMENTED:
FILES CHANGED:
API INTEGRATION:
TESTS:
FLUTTER ANALYZE:
BUILD:
DEPENDENCIES:
SECURITY NOTES:
KNOWN LIMITATIONS:
BLOCKERS:
READY FOR NEXT PHASE: YES / NO
```

Then STOP. Do not begin Phase 5 automatically.
