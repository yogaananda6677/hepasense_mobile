# HepaSense Mobile — Phase 7: Notification Center

## 1. Objective

Implement the Notification Center: `GET /api/v1/notifications/` paginated list, `GET /api/v1/notifications/unread-count/` for the badge, `POST /api/v1/notifications/{id}/read/` (mark one read), and `POST /api/v1/notifications/read-all/`. Provide loading/empty/error/retry, pagination (where backend supports it), per-item read indicator, mark-one-read, mark-all-read, and cross-screen badge refresh. Database Notification is the source of truth; push delivery is a separate concern (Phase 8).

## 2. Why This Phase Exists

Notifications are the backend source of truth for screening-related alerts (Backend Phase 5 §1). The Center must reflect database Notification state (read/unread) and keep the unread badge synchronized (PRD §63). It depends on Phase 2 session and Phase 4 status mapping/navigation to Screening Detail.

## 3. Required Reading

- `docs/mobile/00-mobile-prd.md`: §§33–39, 63, 983–1008, 1367–1379, 1597, 1632–1649.
- `docs/mobile/02-api-integration-contract.md` §5 (notification endpoints + payload minimalism).
- `docs/mobile/phases/04-phase-4-home-latest-screening.md` (badge integration + status).
- Backend `docs/backend/11-phase-5-notifications.md` (source of truth, ownership, idempotency, types, payload).
- Figma Notification Center.

## 4. Preconditions

- Phase 2 session; Phase 4 badge integration pattern; ScreeningDetail route (notification may deep-link by screening_id).
- Backend Phase 5 notifications COMPLETED.

## 5. Repository Audit Before Editing

- Inspect Phase 4 badge/unread-count fetch pattern (reuse `NotificationsRepository.unreadCount()`).
- Inspect Phase 4 `StateView` + components.
- Inspect Phase 5 history pagination pattern (reuse for notifications).

## 6. In Scope

- [ ] **Notification list** (`GET /api/v1/notifications/`): item per Backend Phase 5 §69 (User-owned; `screening_id` for safe navigation; title/message snapshot; `is_read`/`created_at`; type).
- [ ] **Unread badge** (`GET /api/v1/notifications/unread-count/`): count in Home/Account; refresh after mark-read/mark-all/app-resume/new push (Phase 8) (PRD §63, §1632).
- [ ] **Mark one read** (`POST /api/v1/notifications/{id}/read/`): idempotent; sets read_at (Backend Phase 5 §71).
- [ ] **Mark all read** (`POST /api/v1/notifications/read-all/`): scoped to current user; returns number changed (Backend Phase 5 §71).
- [ ] **Per-item read indicator**: unread styling distinct but not color-only (PRD §59, §1593).
- [ ] **Pagination**: where backend supports page-number pagination (Backend Phase 5 §65 — list is paginated 20/page).
- [ ] **States**: loading, success, empty, error, retry, pagination end (PRD §988, §1390).
- [ ] **Cross-screen badge refresh**: after mark-one/mark-all and app resume (PRD §63, §1632, §1646).
- [ ] **Navigation**: tapping a notification uses only the backend-provided `screening_id` to go to Screening Detail (Backend Phase 5 §69, PRD §35, §1014); if no safe identifier, do not deep-link to another patient's data.

## 7. Out of Scope

- Push delivery / foreground notifications / FCM token registration (Phase 8).
- Receiving push must NOT auto-mark a Notification read (Backend Phase 5 §1, PRD §1337).
- Creating, deleting, or arbitrarily updating Notifications (no public create/update/delete — Backend Phase 5 §71).
- Education (Phase 9).

## 8. Backend Contract

| Method | Path | Auth | Response |
|---|---|---|---|
| GET | `/api/v1/notifications/` | JWT (MFA) | paginated list (20/page), `is_read`+`type`+`title`+`message`+`created_at`+`screening_id` |
| GET | `/api/v1/notifications/unread-count/` | JWT (MFA) | `{ unread_count: N }` |
| POST | `/api/v1/notifications/{id}/read/` | JWT (MFA) | idempotent; 200; 404 for another user's ID |
| POST | `/api/v1/notifications/read-all/` | JWT (MFA) | marks all current-user unread read; count changed |

Filters: `is_read=true|false`, `type=...` (Backend Phase 5 §65). Output is patient-scoped; never embeds Screening internals (Backend Phase 5 §69, PRD §35, §1008). Machine auth rejected (Backend Phase 5 §75).

## 9. Data / Domain Rules

- Database Notification is the source of truth (Backend Phase 5 §1, PRD §1343).
- Read state ≠ push delivery (PRD §1335, §1143); reading does not affect push, receiving push does not auto-read.
- Do NOT derive diagnosis language from notification type; use backend title/message snapshot (PRD §1006, §1008).
- Unread count backend-authoritative; do not drift a local independent count (PRD §1649).
- No Patient/device/fingerprint internals in output (Backend Phase 5 §69).

## 10. UI / Figma Requirements

- Notification Center list per Figma; unread indicator not color-only (PRD §59).
- Empty state + retry (PRD §988, §1390).
- Pull-to-refresh (PRD §1597).
- Reuse `StateView`, theme (PRD §1529).
- Bahasa Indonesia (PRD §5, §1008).
- SafeArea/keyboard/text-scaling (PRD §229).

## 11. State Requirements

- List: `initial | loading | success | empty | error | paginating | refreshing`.
- Badge: `loading | ready | error`; refreshes after mark-read/mark-all/resume.
- Mark-one/mark-all: `idle | mutating | success | error`; optimistic or server-then-UI per Figma.

## 12. Architecture Requirements

- Reuse `NotificationsRepository` from Phase 4 (list + unreadCount).
- Add `NotificationRepository.markRead(id)` and `readAll()`.
- `NotificationCenterViewModel` (Riverpod): owns list, unread count, pagination, mutation state; emits badge-change events to a shared unread-count provider so Home/Account refresh (PRD §1644).
- Single in-flight guards to prevent duplicate requests / refresh storms (PRD §92, §1626).

## 13. Security & Privacy Requirements

- JWT (MFA-enforcing) via Phase 2 interceptor; machine auth rejected by backend.
- Output contains `screening_id` for navigation only — no Screening internals (Backend Phase 5 §69, PRD §35).
- No raw biometric/Patient/device/fingerprint/JWT/TOTP in output (Backend Phase 5 §75, PRD §924, §55).
- Receiving push never auto-reads (PRD §1335, §1143).
- Cross-user IDs return 404 (Backend Phase 5 §71).

## 14. Implementation Tasks

- [ ] Inspect Phase 4 `NotificationsRepository.unreadCount()` + badge pattern; Phase 5 pagination pattern.
- [ ] Implement `NotificationRepository.list(page, filters)`, `markRead(id)`, `readAll()`.
- [ ] Implement `NotificationCenterViewModel` (list, unread count, pagination, mutations, badge events).
- [ ] Implement Notification Center screen (list, item, read indicator, mark-one, mark-all, empty/error/retry, pagination, pull-to-refresh).
- [ ] Integrate badge refresh into Home (Phase 4) and Account.
- [ ] Wire navigation: notification → Screening Detail only when `screening_id` is safely present and owned.
- [ ] Add Phase 7 report.
- [ ] Run `dart format .`, `flutter analyze`, `flutter test`.

## 15. Tests Required

- Unit: unread-count fetch; list pagination; mark-one/mark-all idempotency; cross-user 404.
- Unit: read action does not call any push endpoint.
- Widget: Center renders loading/success/empty/error + pagination; unread badge updates after mark-read/mark-all.
- Integration (mock — PRD §77): list maps to safe fields only; no internals parsed.
- Regression: receiving a notification object never marks it read; no Patient/device/fingerprint fields.

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

- [ ] Notification list (paginated) + mark-one-read + mark-all-read + unread badge.
- [ ] Cross-screen badge refresh; pull-to-refresh (PRD §63, §1597, §1632).
- [ ] All states implemented (PRD §988, §1390); safe navigation via `screening_id`.
- [ ] Reuses Phase 4 repository/badge + Components.
- [ ] No push/Firebase code; no auto-read on notification receipt (Backend Phase 5 §1, PRD §1335).
- [ ] No internals in output (Backend Phase 5 §69, PRD §924).
- [ ] `flutter analyze` clean; `flutter test` passes.
- [ ] `flutter build apk --debug` passes.

## 18. Stop Conditions / Blockers

- STOP if backend notification output shape differs from Backend Phase 5 §69 — re-audit.
- STOP if a push-delivery endpoint is conflated with Notification read state (Backend Phase 5 §1, PRD §1335).

## 19. Required Documentation Output

`docs/mobile/phase-reports/phase-7-notifications-report.md`: files changed, APIs (notifications/*), tests + results, analyzer/build, reuse of Phase 4 badge, known limitations, blockers, readiness for Phase 8 (and non-dependent Phase 9+).

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

Then STOP. Do not begin Phase 8 automatically.
