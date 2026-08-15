# HepaSense Mobile — Phase 3: Patient Identity, Profile & Account

## 1. Objective

Implement the authenticated account/profile area: current User profile display, edit of supported profile fields only, change password, and the Patient linkage lookup (`GET /api/v1/patients/me/`) with explicit handling of the **linked** and **unlinked Patient** states. Phase 3 must never create, guess, or self-claim a Patient.

## 2. Why This Phase Exists

Phase 2 established authenticated sessions with MFA. Mobile users may exist without a linked Patient (PRD §23, §707). The Home screen (Phase 4) and screening flows depend on knowing whether a Patient is linked, so Phase 3 resolves Patient linkage and provides the Profile/Account editing surfaces the MVP requires.

## 3. Required Reading

- `docs/mobile/00-mobile-prd.md`: §§23, 40, 41, 50, 720–746, 1199–1216.
- `docs/mobile/02-api-integration-contract.md` §§1–2.
- `docs/mobile/phases/02-phase-2-authentication-mfa.md`.
- Backend `docs/backend/06-phase-1-auth-implementation.md` (profile + change-password).
- Backend `docs/backend/08-phase-2-patient-identity.md` (patient linkage, `patients/me`, 404 semantics).
- Figma Account/Profile/Edit/Edit Profile/Change Password screens.

## 4. Preconditions

- Phase 2 complete: authenticated sessions, secure token storage, protected routes.
- Backend Phase 1 (profile, change-password) and Phase 2 (patients/me, patient link) COMPLETED.
- API client carries a valid JWT; 401 → refresh/logout already handled by Phase 2.

## 5. Repository Audit Before Editing

- Inspect Phase 2 `TokenRepository`, `AuthInterceptor`, `AuthNotifier`, `SecureStorage` keys — reuse for session checks.
- Inspect `docs/mobile/02-api-integration-contract.md` for exact field mutability (email/roles/2FA immutable on profile).
- Reuse Phase 1 theme/components/buttons/text-field/dialog.
- Do **not** reuse the Phase 2 auth-guard to claim Patient state; patient linkage is data, not auth.

## 6. In Scope

- [x] **Profile display & edit** (`GET|PATCH /api/v1/accounts/profile/`): view current profile; edit supported mutable fields only. Email/roles/2FA state are read-only.
- [ ] **Profile edit form**: client validation + backend validation; save state; success/failure feedback (PRD §40, §1162). Prevent duplicate-submission while mutating (PRD §1399, §2349).
- [x] **Patient linkage lookup** (`GET /api/v1/patients/me/`) from home/profile: determine linked vs. unlinked.
- [x] **Linked Patient state**: display safe summary (no fields beyond the self serializer).
- [x] **Unlinked Patient state**: dedicated safe UI with support guidance and no create/claim action.
- [ ] **Change password** (`POST /api/v1/accounts/change-password/`): old + new + confirm; validates old password, confirmation, Django policy; backend invalidates JWT sessions (Backend Phase 1 §73, PRD §41, §1186).
- [ ] **Post-password-change handling**: if the backend invalidation causes subsequent 401 (Phase 2 refresh-failure → logout), the app must clear auth and return to Login (PRD §1190, §1197).
- [ ] **Account UI**: Account entry from Home; Profile/Edit/Change Password/Privacy/Help/Logout entries (PRD §42, §720).
- [ ] **Logout** wired from Account (reuse Phase 2 logout action).

## 7. Out of Scope

- Creating, guessing, or self-claiming a Patient from Flutter (PRD §707). `patients/link-user` etc. are operator-only endpoints (Backend Phase 2 §44) — never call from patient mobile.
- Patient creation/edit endpoints from mobile (none are patient-accessible).
- Healthcare `/api/v1/healthcare/*` (PRD §69).
- Full Settings/Help/Privacy polish (Phase 10).

## 8. Backend Contract

| Method | Path | Auth | Body | Response |
|---|---|---|---|---|
| GET | `/api/v1/accounts/profile/` | JWT | — | current-user profile fields |
| PUT / PATCH | `/api/v1/accounts/profile/` | JWT | mutable fields only | updated profile |
| POST | `/api/v1/accounts/change-password/` | JWT | old_password, new_password, confirm | 200/204 |
| GET | `/api/v1/patients/me/` | JWT | — | linked Patient summary, **or 404** |

- `GET /api/v1/patients/me/` returns 404 with `No patient profile is linked to this account.` when unlinked (Backend Phase 2 §50, PRD §696). Treat as a **domain state**, not an error snackbar (PRD §50, §1372).
- Profile PATCH must not send email/roles/2FA fields to the backend mutator (Backend Phase 1 §72); ignore server rejection gracefully.
- Change password invalidates existing JWT sessions server-side (Backend Phase 1 §73).

## 9. Data / Domain Rules

- `User ≠ Patient`; `GET /api/v1/patients/me/` 404 ≠ authentication failure (PRD §23, §696).
- Do NOT automatically create a Patient, guess `patient_code`, or call an undocumented self-claim endpoint (PRD §707).
- No device credentials in the client (PRD §53, §91).
- Patient summary must not expose raw fingerprint references, device IDs, or internals (Backend Phase 2 §65).

## 10. UI / Figma Requirements

- Account screen list entries: Profile → Edit Profile → Change Password → Privacy Policy → Help → Logout (PRD §254, §720).
- Edit Profile: supported fields per contract only; read-only display of immutable fields (e.g., email).
- Unlinked-Patient safe state with clear, reassuring guidance (PRD §701, §705); no invented support contacts (PRD §1329).
- Reuse Phase 1 buttons/text-field/dialog/`StateView`. Bahasa Indonesia (PRD §5).
- SafeArea/keyboard/small-phone/text-scaling (PRD §229).

## 11. State Requirements

- Profile: `initial | loading | success | saving | saved | error`.
- Patient linkage: `loading | linked | unlinked | error` (404 → `unlinked`, not `error`).
- Change password: `idle | submitting | success | error`.
- Account screen: `loading | ready | auth_error` (session expiry handled by Phase 2 interceptor).

## 12. Architecture Requirements

- Reuse Phase 2 `TokenRepository`/`AuthNotifier` for session validity; do a light profile/patient fetch using the existing authenticated API client.
- New `ProfileRepository` + `PatientRepository` over the shared API client (repository pattern — PRD §13, §419).
- Patient linkage result cached in-memory only for the session; do not cache PHI to disk (PRD §53, §1349, §1432).

## 13. Security & Privacy Requirements

- Profile/edit via authenticated JWT only; backend enforces ownership (Backend Phase 1 §72).
- Passwords never logged (PRD §54, §561). New/old passwords handled in memory; no persistence.
- Patient summary fields minimal and backend-scoped (Backend Phase 2 §65).
- After password change, the server invalidates JWTs; the client relies on Phase 2 refresh-failure handling to log out (PRD §1190, §1197).
- Secure storage already holds tokens (Phase 2); do not add plaintext Patient data.

## 14. Implementation Tasks

- [ ] Inspect Phase 2 auth + API client + profile/patient endpoints.
- [ ] Define `ProfileRepository` (get/update) and `PatientRepository` (me).
- [ ] Implement Profile screen + view-model (get, edit mutable fields, save, validation, backend-error mapping).
- [ ] Implement Edit Profile screen reusing Phase 1 form components.
- [ ] Implement Patient linkage check (`GET /api/v1/patients/me/`); 404 → unlinked safe UI.
- [ ] Implement linked-Patient summary UI (backend-safe fields only).
- [ ] Implement Change Password screen + view-model; handle server-side JWT invalidation → Phase 2 logout path.
- [ ] Implement Account entry list + navigation; wire Logout action (Phase 2).
- [ ] Implement Privacy/Help placeholder entries (static content finalized in Phase 10).
- [ ] Add Phase 3 report.
- [ ] Run `dart format .`, `flutter analyze`, `flutter test`.

## 15. Tests Required

- Unit: `PatientRepository.me()` maps 404 → unlinked; success → linked Patient.
- Widget: Profile screen shows linked/unlinked/Loading/Error states.
- Widget: unlinked state renders the safe copy and no guess/create UI.
- Widget: Edit Profile disables/suppresses immutable fields (email/roles/2FA).
- Widget: Change Password triggers backend; on 401-after-change, Phase 2 logout path is invoked.
- Integration (mock — PRD §77): profile update sends only mutable fields.
- Regression: no Patient-creation or self-claim call exists in the client.

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

- [ ] Profile view/edit works against verified contract; immutable fields protected.
- [ ] Patient linkage resolves; unlinked state is a safe dedicated UI (not an error).
- [ ] No Patient creation/guessing/self-claim from Flutter (PRD §707).
- [ ] Change password works and server-side session invalidation routes to Login.
- [ ] Account screen entries wired; Logout reuses Phase 2.
- [ ] `flutter analyze` clean; `flutter test` passes (profile/patient/password tests).
- [ ] `flutter build apk --debug` passes.

## 18. Stop Conditions / Blockers

- STOP if `GET /api/v1/patients/me/` contract differs from Backend Phase 2 report — re-audit.
- STOP if the backend exposes a patient self-claim endpoint that conflicts with PRD §23/§707 — do not use it; report.
- STOP on any need to modify the backend.

## 19. Required Documentation Output

`docs/mobile/phase-reports/phase-3-patient-profile-report.md`: files changed, APIs integrated (profile, patients/me, change-password), tests + results, analyzer/build results, assumptions (Figma Account match), known limitations, blockers, readiness for Phase 4.

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

Then STOP. Do not begin Phase 4 automatically.
