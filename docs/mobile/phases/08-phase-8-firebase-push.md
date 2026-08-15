# HepaSense Mobile — Phase 8: Firebase Push Notification Integration

> **COMPLETED.** Genuine Android Firebase configuration matches
> `com.yogaananda.hepasense`; Google Services and the three required
> FlutterFire packages are integrated. Production initialization, Messaging,
> permission, FID sync/revoke, foreground refresh, and guarded open/cold-start
> behavior are implemented. Database Notification stays canonical. Real device
> FID retrieval and end-to-end FCM delivery remain external validation items.

## 1. Objective

Add Firebase push notification delivery for the patient app using the finalized backend Phase 7 contract: register a **Firebase Installation ID (FID)** with the backend, handle foreground/background notification presentation, notification-tap navigation, refresh the unread-count badge, and soft-revoke the current device only on logout. Do **not** use `FirebaseMessaging.instance.getToken()` for registration — the backend rejects it (Backend Phase 7 §111).

## 2. Why This Phase Exists

The Notification Center (Phase 7) shows database Notification state. Users also need push delivery of new notifications. The backend Phase 7 report finalizes the registration contract (`FirebaseInstallations.instance.getId()` → `POST /api/v1/notifications/push-devices/{fid}>`). Phase 7 UI is usable without push, so this phase is the only place FCM/FlutterFire is introduced.

## 3. Required Reading

- `docs/mobile/00-mobile-prd.md`: §§36–39, 1029–1071, 1221–1227, 1298–1331, 1367–1379.
- `docs/mobile/02-api-integration-contract.md` §6 (FCM contract; FID registration; logout revocation; payload minimalism).
- `docs/mobile/phases/07-phase-7-notifications.md` (badge integration).
- **Backend** `docs/backend/13-phase-7-fcm-push-notifications.md` (FINAL — READ IN FULL BEFORE adding FlutterFire).
- Figma notification icons/illustrations (if any) for foreground UI.

## 4. Preconditions

- Phase 2 session; Phase 7 Notification Center complete and badge works via REST.
- Backend Phase 7 COMPLETED; the FID-based registration contract is final.
- Android project exists (Phase 1) with `google-services.json` to be added ONLY after FID verification (see Security §13).

## 5. Repository Audit Before Editing

- Inspect Phase 1 `pubspec.yaml` for any existing Firebase packages (none expected).
- Inspect Phase 1 `android/` for existing Firebase config (none expected).
- Inspect Phase 2 logout action (extend with FID revocation).
- Inspect Phase 7 badge/unread-count provider (refresh after push).
- Confirm NO existing `FirebaseMessaging`/FCM code exists (PRD §1054: do NOT hardcode `getToken` until contract finalized).

## 6. In Scope

- [ ] **Verify final contract**: re-read Backend Phase 7 report; confirm registration uses `FirebaseInstallations.instance.getId()`, body `{fid, platform}`, returns 8-char `fid_hint` (Backend Phase 7 §102–111).
- [ ] **Add FlutterFire dependencies** only after verification: `firebase_core`, `firebase_installations`, `firebase_messaging` (minimal set). Add `package:` only justified here (PRD §1502, task §14).
- [ ] **Android `google-services.json`** + Gradle config; service-account JSON never committed (Backend Phase 7 §115, PRD §91).
- [ ] **Registration**: on app start after auth, obtain FID via `FirebaseInstallations.instance.getId()`; `POST /api/v1/notifications/push-devices/` `{fid, platform:"android"}`; store `fid_hint` securely; refresh on login/ID change.
- [ ] **`POST|GET /api/v1/notifications/push-devices/` list** integration (scoped to current user) as required by product; at minimum the registration is needed.
- [ ] **Foreground handling**: show in-app notification banner/dialog when app in foreground (minimal content from Phase 7 data payload is `{notification_id, type}` only — Backend Phase 7 §83); refresh unread count.
- [ ] **Background/tap handling**: on notification open, route to Notification Center, and when the notification carries a safe `screening_id` (Backend Phase 5 §69), offer navigation to Screening Detail; never guess identifiers (PRD §35, §1014).
- [ ] **Token/FID rotation**: re-register when Firebase changes the installation ID; handle `onIdChange` (Backend Phase 7 §104, PRD §107).
- [ ] **App-resume / push-received refresh**: refresh unread-count badge (PRD §63, §1646).
- [ ] **Logout revocation**: soft-revoke the **current** device only — `DELETE /api/v1/notifications/push-devices/{id}/` — NOT all devices (PRD §1223, §43, Backend Phase 7 §34).
- [ ] **Refresh-token interaction**: keep FID registration valid after refresh; re-register if needed.

## 7. Out of Scope

- Notification Center UI (Phase 7) — reuse, do not rebuild.
- Implementing push without re-inspecting the final backend Phase 7 contract.
- Using `FirebaseMessaging.instance.getToken()` as the registration source (backend rejects it).
- Push payload carrying medical detail (PRD §38, §1018–1029; Backend Phase 7 §83): data is `{notification_id, type}` only.
- Auto-marking Notification read on push receipt (Backend Phase 5 §1, PRD §1335).
- Firebase Analytics / Crashlytics (PRD §70, §71).
- Local notifications plugin for displaying device-notification UI beyond minimal foreground banner (keep scope minimal; do not over-add packages).

## 8. Backend Contract (FINAL — Backend Phase 7)

| Method | Path | Auth | Body | Response | Notes |
|---|---|---|---|---|---|
| POST | `/api/v1/notifications/push-devices/` | JWT | `{ fid, platform }` | 201 new / 200 refresh | FID write-only; returns 8-char `fid_hint`; rejects legacy `token` field → 400 |
| GET | `/api/v1/notifications/push-devices/` | JWT | — | paginated list (FIDs masked) | scoped to current user |
| DELETE | `/api/v1/notifications/push-devices/{id}/` | JWT | — | 204/soft-revoke | current device only; cross-user → 404 |

- Registration identifier = `FirebaseInstallations.instance.getId()` (FID), **not** `FirebaseMessaging.instance.getToken()` (Backend Phase 7 §111).
- Backend derives ownership from `request.user`; no `user_id` sent (Backend Phase 7 §32, PRD §102, §111).
- Cross-user FID registration reassigns ownership atomically; Flutter must register fresh FIDs after backend `0004_invalidate_legacy_push_targets` migration (Backend Phase 7 §117).
- FCM data payload (Backend Phase 7 §83): `{ notification_id, type }` — no medical detail.
- Service-account JSON never in repo (Backend Phase 7 §81, PRD §91).

## 9. Data / Domain Rules

- Push delivery ≠ Notification read state (Backend Phase 5 §1, PRD §1335). Receiving a push must NOT mark read.
- Unread count backend-authoritative (Backend Phase 5 §69, PRD §1649).
- No PHI/medical detail in push payload (PRD §1018–1029, §1126; Backend Phase 7 §83).
- Device ownership derived server-side from authentication (PRD §102, §111).

## 10. UI / Figma Requirements

- Foreground banner uses the notification `type` + backend title/message snapshot (Backend Phase 5 §69); never raw measurements (PRD §1126).
- Tap → Notification Center or Screening Detail via safe `screening_id` (Backend Phase 5 §69, PRD §35).
- Reuse Phase 7 components (PRD §1529).
- SafeArea/text-scaling for any foreground overlay (PRD §229).

## 11. State Requirements

- Registration: `idle | checking | registering | registered | error`.
- Foreground banner: shown/hidden.
- Badge: refresh on push-received + app-resume + mark-read (Phase 7).

## 12. Architecture Requirements

- New `PushRepository` over the authenticated API client: register/unregister/list FID operations; store only `fid_hint` in secure storage.
- `PushTokenManager` (Riverpod): obtains FID, registers with backend, listens to `FirebaseInstallations.onIdChange`, re-registers on login, soft-revokes on logout (Phase 2 logout extension).
- Foreground notification handler: minimal, reads `{notification_id, type}`, refreshes unread count; does not mark read (Backend Phase 5 §1, PRD §1335).
- Reuse Phase 7 unread-count provider for badge refresh.
- Do not introduce a queue service or worker in Flutter (Backend Phase 7 §58 — scheduling is the deployment's responsibility, not Flutter's).

## 13. Security & Privacy Requirements

- Obtain identifier via `FirebaseInstallations.instance.getId()` **only** (Backend Phase 7 §111; PRD §1061). Never send `getToken()`.
- `google-services.json` (public Firebase options) — OK; **service-account JSON never committed** (Backend Phase 7 §81, PRD §91, §2301).
- Never log FIDs, tokens, or credentials (PRD §54, §1063, §1463).
- Foreground/background payloads contain no medical detail (Backend Phase 7 §83, PRD §1126).
- Read state never mutated by push (Backend Phase 5 §1, PRD §1335).
- Logout revokes current device only (PRD §1223, §43, Backend Phase 7 §34).

## 14. Implementation Tasks

- [ ] Re-inspect Backend Phase 7 report; confirm FID contract before any package add.
- [ ] Add FlutterFire deps (`firebase_core`, `firebase_installations`, `firebase_messaging`); add `package:` justifications to the report (task §14).
- [ ] Add `google-services.json` + Gradle (service-account JSON NOT committed).
- [ ] Implement `PushRepository` (register FID, unregister, list) storing only `fid_hint`.
- [ ] Implement `PushTokenManager`: FID obtain → register → `onIdChange` re-register → login re-register → logout soft-revoke (extend Phase 2 logout).
- [ ] Implement notification-permission request (Android 13+); minimal.
- [ ] Implement foreground banner (no medical detail); refresh unread count.
- [ ] Implement background + tap handling: Notification Center or Screening Detail via safe `screening_id`.
- [ ] Integrate badge refresh on push-received + resume.
- [ ] Add Phase 8 report.
- [ ] Run `dart format .`, `flutter analyze`, `flutter test`, `flutter build apk --debug`.

## 15. Tests Required

- Unit: registration body uses `fid` + `platform`; rejects sending legacy `token` field.
- Unit: logout revokes current device only (calls DELETE for current `fid_hint`/id, not a bulk endpoint).
- Unit: foreground handler refreshes unread count and does NOT mark read.
- Integration (mock boundaries — PRD §77): FID obtained from `FirebaseInstallations`, not `getToken`; payload parsed is `{notification_id, type}` only; no medical fields.
- Regression: receiving a push notification object does not mutate read state.

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

- [ ] Backend Phase 7 contract re-inspected and confirmed FID-based before FlutterFire added.
- [ ] FID registered via `FirebaseInstallations.instance.getId()` only; `getToken` not used for registration.
- [ ] Foreground handling + tap navigation via safe `screening_id`.
- [ ] Badge refresh on push-received/resume; no auto-read.
- [ ] Logout soft-revokes current device only.
- [ ] No service-account JSON in repo; no FID/token logging.
- [ ] Payload contains no medical detail.
- [ ] `flutter analyze` clean; `flutter test` passes; `flutter build apk --debug` passes.

## 18. Stop Conditions / Blockers

- STOP if the backend Phase 7 contract has changed since the 2026-08-12 report — re-audit before adding FlutterFire.
- STOP if adding `firebase_messaging` requires a major Flutter/Dart version upgrade outside this phase’s scope — defer with justification.
- STOP if any service-account JSON is found committed — report immediately.

## 19. Required Documentation Output

`docs/mobile/phase-reports/phase-8-firebase-push-report.md`: files changed, deps added (+ PACKAGE/WHY/VERSION/IMPACT per task §14), APIs (push-devices), tests + results, analyzer/build, assumptions (FID verification), known limitations, blockers, readiness for Phase 9 (non-dependent phases may proceed).

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

Then STOP. Do not begin Phase 9 automatically.
