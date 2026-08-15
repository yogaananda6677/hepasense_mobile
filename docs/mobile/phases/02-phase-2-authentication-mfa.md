# HepaSense Mobile — Phase 2: Authentication, Registration & MFA

## 1. Objective

Implement the full authenticated identity flow: Splash/session restoration, Login, Registration, secure token storage, access/refresh token handling with single coordinated refresh, MFA challenge handling, MFA/TOTP verification, logout, protected-route behavior, and auth error states. This phase does **not** implement any post-auth feature (Patient/Screening/Notification data are Phase 3+).

## 2. Why This Phase Exists

Phase 1 produced the bootstrap, routing shell, theme, secure-storage wrapper, and network stubs. Phase 2 wires real authentication into those foundations so the auth gate can actually determine authenticated vs. unauthenticated state and the API client can carry a valid JWT. It is the dependency root for every authenticated phase.

## 3. Required Reading

- `docs/mobile/00-mobile-prd.md`: §§16–23, 320–636, 1199–1216, 1807–1831, 2197–2224.
- `docs/mobile/01-mobile-architecture.md` (D2, D6, D7, D11).
- `docs/mobile/02-api-integration-contract.md` §1 (auth endpoints), §2 (patient 404), §6 (FCM — do NOT implement yet).
- `docs/mobile/phases/01-phase-1-foundation-design-system.md`.
- Backend `docs/backend/20-final-api-contract.md` and `docs/backend/21-flutter-integration-contract.md` (frozen contract of record).
- Figma Login/Register/MFA/OTP screens.

## 4. Preconditions

- Phase 1 complete: bootstrap, routing, theme, secure-storage wrapper, network client stubs, auth-guard stub.
- `flutter analyze` and `flutter build apk --debug` pass (from Phase 1).
- Backend Phase 1 auth contract is COMPLETED (verified).

## 5. Repository Audit Before Editing

- Inspect Phase 1-produced `lib/core/network/`, `lib/core/storage/`, `lib/core/routing/app_router.dart`, `lib/core/routing/auth_guard.dart` (stub), `lib/core/errors/status_mapping.dart`.
- Inspect `pubspec.yaml` for the Riverpod/go_router versions added in Phase 1; reuse them.
- Inspect `android/` for flavor/build-config wiring; reuse.
- If any real auth code already exists from a prior attempt, reuse/extend it rather than replacing (PRD §317, task §13).

## 6. In Scope

- [ ] **Splash / session restoration**: on cold start, read access+refresh tokens from secure storage; if a valid recoverable session exists (refresh token present), attempt one refresh to obtain a fresh access token; otherwise route to Login. Do not flash Home before auth state is known (PRD §17, §541).
- [x] **Secure token storage**: keep access JWT in memory and refresh JWT in `flutter_secure_storage`; never log tokens.
- [ ] **Login** (`POST /api/v1/auth/login/`): email + password, password-visibility toggle, input validation, backend validation errors, network failure state, MFA transition. Do not reveal account existence beyond what backend returns (PRD §21, §1490).
- [x] **MFA challenge**: if backend returns `{requires_2fa: true, challenge: "<temporary challenge>"}`, route to OTP; keep the challenge in memory only and never log it.
- [ ] **MFA/TOTP verification** (`POST /api/v1/auth/2fa/login/`): challenge + otp_code → final JWTs (mfa_verified). Never bypass MFA or use another token endpoint (PRD §632, Backend Phase 1 §51).
- [ ] **Register** (`POST /api/v1/auth/register/`): fields per contract (email, password/confirm, first/last name, phone; optional birth_date/gender). Do not assume a Patient is created (PRD §22, §671).
- [ ] **Access/refresh handling + coordinated refresh**: wire Dio 401 → single refresh (queued) → retry once; on refresh failure, clear auth and route to Login (PRD §19, §573–601).
- [ ] **Logout** (`POST /api/v1/auth/logout/`): call backend, clear local access/refresh tokens, clear sensitive in-memory data (including MFA challenge), reset protected navigation to Login (PRD §42, §1201).
- [ ] **Protected routes**: auth guard redirects unauthenticated users to Login; routes not accessible after logout (PRD §12, §395).
- [ ] **Auth error states**: distinct UI for invalid login, MFA required, MFA invalid, session expired, network failure (PRD §50, §1807–1831).
- [ ] Replace the Phase 1 auth-guard stub with real session logic wired to a TokenRepository.

## 7. Out of Scope

- Patient lookup / Patient linkage UI (Phase 3).
- Home/Screening/Notification/account data calls (Phase 4+).
- Firebase/FCM (Phase 8).
- Password change from this phase (it belongs to Phase 3 account flow) — do not call change-password here; logout only.
- Biometric login / phone auth / social login (PRD §90, §1490).
- Analytics (PRD §70).

## 8. Backend Contract

Verified from Backend Phase 1 report (`docs/backend/06-phase-1-auth-implementation.md`) and `docs/mobile/02-api-integration-contract.md` §1:

| Method | Path | Auth | Body | Response | Error states |
|---|---|---|---|---|---|
| POST | `/api/v1/auth/register/` | none | email, password, password_confirm, first_name, last_name, phone; optional birth_date, gender | user + access/refresh JWTs | duplicate email → 400/validation; invalid fields → 400 |
| POST | `/api/v1/auth/login/` | none | email, password | JWTs, **or** `{requires_2fa:true, challenge:"..."}` | invalid → 401; MFA-enabled → challenge (no tokens) |
| POST | `/api/v1/auth/token/` | none | same as login | MFA-aware alias of login | same |
| POST | `/api/v1/auth/token/refresh/` | none | refresh | new access/refresh | invalid/expired → 401 |
| POST | `/api/v1/auth/2fa/login/` | none | challenge, otp_code | final JWTs (mfa_verified=true) | invalid OTP, expired/invalid challenge → 401 |
| POST | `/api/v1/auth/logout/` | Bearer JWT | refresh token | 204/blacklist | 401 if invalid |

- Login envelope error: `{ detail, errors }` (Backend Phase 1 §31).
- Logout revokes only the supplied refresh token (Backend Phase 1 §74).
- Registration enforces name/phone (Backend Phase 1 §139).

**Do not** use device credentials (`Authorization: HepaSense`) anywhere (PRD §53, §585, §91).

## 9. Data / Domain Rules

- `User ≠ Patient` (PRD §23). After registration, do **not** assume a linked Patient (PRD §671); Phase 3 handles `GET /api/v1/patients/me/` 404.
- `mfa_verified` is server-asserted; the client must not forge or bypass MFA (Backend Phase 1 §49).
- Access token is short-lived; refresh is the durable state. Refresh failure ⇒ clear session ⇒ Login (PRD §19, §597, §1186).
- Do not reveal whether an account exists beyond backend responses (PRD §1490).

## 10. UI / Figma Requirements

- Login: email, password, password visibility toggle, loading, validation, backend errors, MFA transition (PRD §21, §638).
- Register: contract fields only (PRD §22, §657). Do not invent profile fields.
- MFA/OTP: TOTP code entry + verify; error states for invalid/expired challenge/OTP (PRD §20, §605).
- Reuse Phase 1 buttons, text fields, `StateView`, app bar (PRD §1529).
- Bahasa Indonesia copy; medically conservative (PRD §5).
- Account for SafeArea/keyboard/small phones/text scaling (PRD §229).

## 11. State Requirements

Auth flow states:

- Splash: `restoring | no_session | has_session (refreshing) | refreshed | refresh_failed → Login`.
- Login button: `idle | submitting | success | mfa_required | error`.
- Register button: `idle | submitting | success | error`.
- MFA form: `idle | verifying | success | invalid_code | expired_challenge | error`.
- Token refresh coordination: `idle | refreshing (single in-flight) | success | failed`.
- Auth guard: `loading | authenticated | unauthenticated`.

## 12. Architecture Requirements

- Auth state held in a Riverpod `TokenRepository` (or `AuthNotifier` with `AsyncNotifier`) that is the **single** source of auth truth for the guard/router.
- API client (Dio) interceptor reads the memory-only access token; 401 triggers the single coordinated refresh (D6, D7).
- Secure storage wrapper from Phase 1 is reused only for the refresh token. MFA challenge does not survive process death and the user returns safely to Login.
- Repository → API client → Django (PRD §13, §419).

## 13. Security & Privacy Requirements

- Tokens + MFA challenge in `flutter_secure_storage`; never in plaintext prefs or logs (PRD §18, §54, §558).
- Never log password, access/refresh token, MFA challenge, OTP/TOTP (PRD §54, §561–568).
- Do not store or log raw biometrics (device fingerprint templates stay on the device) (PRD §55, §1483).
- No device credentials in Flutter (PRD §53, §56, §585, §91).
- Access token never used as a bearer for IoT ingestion views (machine auth is separate and unused by mobile).
- Password change (Phase 3) invalidates JWT sessions; logout revokes refresh token only.

## 14. Implementation Tasks

Ordered checklist:

- [ ] Inspect Phase 1 network/storage/routing/audit artifacts.
- [ ] Implement `TokenRepository` (read/write access+refresh, MFA challenge, clear) over `SecureStorage`.
- [ ] Implement `AuthInterceptor` wiring access token injection (reuse Phase 1 stub).
- [ ] Implement coordinated refresh in the API client: single in-flight refresh; queued retries; on failure → clear auth + emit auth-expired event.
- [ ] Implement `AuthNotifier` (Riverpod) exposing `authState` (`loading/authenticated/unauthenticated`).
- [ ] Replace Phase 1 `AuthGuard` stub with real redirect (loading→Login until session known; no Home flash — PRD §17).
- [ ] Implement Splash: restore session + one refresh; route accordingly.
- [ ] Implement Login screen + form/view-model; backend validation + MFA transition.
- [ ] Implement Register screen + form/view-model; contract fields; no Patient assumption.
- [ ] Implement MFA/OTP screen; challenge + otp_code; sensitive challenge handling.
- [ ] Implement Logout action (call backend, clear tokens/challenge, reset nav).
- [ ] Wire auth-protected routes; verify logout resets protected nav.
- [ ] Implement auth error-state UI (invalid login, MFA required/invalid, session expired, network).
- [ ] Add Phase 2 report.
- [ ] Run `dart format .`, `flutter analyze`, `flutter test`.

## 15. Tests Required

- Unit: `TokenRepository` stores/reads/clears tokens; refresh-failure clears session.
- Unit: coordinated refresh — concurrent 401s trigger exactly one refresh; queued requests retry.
- Widget: Login form validation + error display; MFA-required transition.
- Widget: Register form validation + backend error mapping.
- Widget: MFA/OTP screen + invalid/expired handling.
- Widget: Splash routes correctly when session absent vs. refreshable.
- Widget: auth guard blocks protected route when no session.
- Integration-style (mock API boundary, no live backend — PRD §77): logout clears state and navigates to Login.
- Regression: MFA cannot be bypassed (no JWTs issued by login for MFA-enabled accounts).

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

- [ ] Splash/session restoration works; no Home flash before auth known (PRD §17).
- [ ] Login, Register, MFA/OTP all integrated against verified backend contract.
- [ ] Secure token storage + MFA challenge persistence; nothing logged (PRD §54).
- [ ] Single coordinated refresh; refresh failure → Login (PRD §19).
- [ ] Logout clears state and resets navigation to Login (PRD §42).
- [ ] Protected routes inaccessible unauthenticated / after logout (PRD §12).
- [ ] Auth error states have dedicated UI (PRD §50).
- [ ] `flutter analyze` clean; `flutter test` passes (auth + MFA + token-refresh tests).
- [ ] `flutter build apk --debug` passes.
- [ ] No Firebase added; no Patient/Screening/Notification code.

## 18. Stop Conditions / Blockers

- STOP if backend auth contract differs from `docs/mobile/02-api-integration-contract.md` §1 — re-audit, do not invent.
- STOP if 2FA bypass is still present in backend behavior — report; never replicate a bypass.
- STOP on any need to modify the backend.

## 19. Required Documentation Output

`docs/mobile/phase-reports/phase-2-authentication-report.md`: files changed, deps added (+ justification), APIs integrated, tests (scenarios + results), `flutter analyze` result, build result, assumptions (Figma Login/Register/MFA match), known limitations (shared cache for MFA challenge on multi-process deployment is backend concern), blockers, readiness for Phase 3.

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

Then STOP. Do not begin Phase 3 automatically.
