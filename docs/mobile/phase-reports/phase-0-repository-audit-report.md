# Phase 0 — Repository Audit & Architecture Baseline (EXECUTION REPORT)

**Date:** 2026-08-12 (execution)
**Mobile repo:** `/home/yoga/Data/TFS/hepasense_mobile/`
**Backend repo:** `/home/yoga/Data/TFS/hepasense_backend/` (verified present, NOT modified)

This is the **actual execution report**, replacing the planning-era report. It distinguishes planning assumptions from verified repository facts.

## A. Repository inventory (verified)

`find . -type f` in the mobile repo returns **only**:

- `prd.md` (original mobile PRD, 2516 lines)
- `docs/mobile/00-mobile-prd.md` (canonical copy written by planning)
- `docs/mobile/01-mobile-architecture.md`
- `docs/mobile/01-mobile-phase-plan.md`
- `docs/mobile/02-api-integration-contract.md`
- `docs/mobile/03-ui-screen-map.md`
- `docs/mobile/04-design-system.md`
- `docs/mobile/phase-reports/phase-0-repository-audit-report.md` (this file, planning-era)
- `docs/mobile/phases/00-…12-phase-*.md` (13 planning phase documents)

**Greenfield confirmation (verified):**

| Asset | Exists? |
|---|---|
| `pubspec.yaml` | NO |
| `pubspec.lock` | NO |
| `lib/` | NO |
| `test/` | NO |
| `integration_test/` | NO |
| `android/` | NO |
| `ios/` | NO |
| `web/` | NO |
| `assets/` | NO |
| `fonts/` | NO |
| `analysis_options.yaml` | NO |
| `.env` / `.env.example` | NO |
| `firebase.json` | NO |
| `android/app/google-services.json` | NO (no android/ at all) |
| `lib/firebase_options.dart` | NO |

**Conclusion:** The mobile repository is greenfield. No Flutter project exists. Phase 0 did **not** run `flutter create` (per rule §27). Flutter project creation belongs to Phase 1.

## B. Git / source-control state (verified)

- `git status` → `fatal: not a git repository`.
- **Not a Git repository.** Per PRD §88/§2224-2227, the agent did **NOT** run `git init`, `git reset --hard`, `git clean -fd`, `git checkout`, `git restore`, or `rm -rf .git`.
- Git status recorded as a condition for the team; no repair performed automatically.

## C. Flutter toolchain (verified — FOUND)

```text
Flutter 3.44.4 • channel stable
Framework • revision ad70ec4617 (7 weeks ago) • 2026-06-24
Engine • hash 700aebeca4c0e610f109a3979ee3e71b69d666bc
Tools • Dart 3.12.2 • DevTools 2.57.0
Dart SDK version: 3.12.2 (stable) (Tue Jun 9 2026) on "linux_x64"
```

- `flutter --version` and `dart --version` executed successfully.
- Per rules: did **NOT** install/upgrade Flutter, did **NOT** install Android SDK, did **NOT** accept Android licenses, did **NOT** modify PATH.
- Android toolchain details were not queried (rule §6 forbids installing/accepting licenses; safe toolchain inspection was limited to version).

Because the Flutter project does not exist yet, the validation commands `flutter pub get`, `flutter analyze`, and `flutter test` are reported as **NOT APPLICABLE** for this Phase 0 (rule §26). Recording real results would require the Phase 1 project scaffold.

## D. PRD divergence check (verified)

- Original `prd.md` (mobile) compared with `docs/mobile/00-mobile-prd.md` (canonical copy).
- **PRD DIVERGENCE: NONE.** Identical content (2516 lines). `docs/mobile/00-mobile-prd.md` is the implementation-oriented canonical mobile PRD going forward.

## E. Backend contract review (verified, NOT modified)

Backend source and docs are present at `/home/yoga/Data/TFS/hepasense_backend/`. Verified backend phases (all COMPLETED 2026-08-12) and their reports:

| Backend Phase | Report | Mobile-relevant availability |
|---|---|---|
| Phase 1 | `docs/backend/06-phase-1-auth-implementation.md` | Auth/MFA/profile/change-password/logout — COMPLETED |
| Phase 2 | `docs/backend/08-phase-2-patient-identity.md` | `GET /api/v1/patients/me/` — COMPLETED |
| Phase 3 | `docs/backend/09-phase-3-device-screening-iot.md` | IoT ingestion (device-only, not patient) — COMPLETED |
| Phase 4 | `docs/backend/10-phase-4-screening-query-api.md` | Screenings list/latest/detail — COMPLETED |
| Phase 5 | `docs/backend/11-phase-5-notifications.md` | Notifications CRUD — COMPLETED |
| Phase 6 | `docs/backend/12-phase-6-healthcare-screening-api.md` | Clinician reads — OUT OF SCOPE (PRD §69) |
| Phase 7 | `docs/backend/13-phase-7-fcm-push-notifications.md` | FCM push, **FID-based, FINAL** — COMPLETED |
| Phase 8 | `docs/backend/14-phase-8-education-content.md` | Education/nutrition/help — COMPLETED |
| Phase 9 | `docs/backend/15-phase-9-security-hardening.md` | Security hardening; MFA challenge now DB-backed (`MFALoginChallenge`); password-reset finalized; throttling; health probes; logging — COMPLETED |
| Phase 10 | `docs/backend/17-phase-10-integration-hardening.md` | Integration tests (145 tests + 18 subtests baseline) — COMPLETED |
| Staging | `docs/backend/18-staging-smoke-checklist.md` | Staging procedure (incl. genuine FID receipt as external requirement) |

The updated `docs/backend/04-api-contract-draft.md` (re-read) confirms:
- FCM Phase 7 finalized (FID-based).
- Education Phase 8 resolved (public read-only contract).
- **Phase 9 security & operational endpoints** finalized:
  - `POST /api/v1/auth/password/reset/` (generic success for existing/unknown email — anti-enumeration)
  - `POST /api/v1/auth/password/reset/confirm/` (`uid` + composite token + new_password + new_password_confirm)
  - `GET /health/live/` → `{"status":"ok"}`; `GET /health/ready/` → DB `SELECT 1`; `/health/` alias.

### Status corrections applied to the phase plan (see §G)

- **Phase 8 (FCM):** backend contract is FINAL (FID-based). Corrected from CONDITIONAL/BLOCKED to **READY — BACKEND CONTRACT FINAL**. Execution order unchanged: implemented only after Phase 7 + mobile foundations (per execution prompt).
- **Phase 9 (Education):** backend contract is IMPLEMENTED and available. Corrected from BLOCKED to **READY — BACKEND CONTRACT AVAILABLE**.
- **Password-reset + health probes:** verified as available endpoints; not in the current mobile PRD screen map (no "Forgot Password" screen in PRD §254). Documented as available-but-not-currently-scoped in the API contract (no invention).

## F. Architecture baseline (greenfield → recommendations; TO BE EVIDENCE-BASED when Phase 1 inspects real code)

Because there is no existing Flutter code, the architecture is a **recommendation** matching PRD §10 (feature-oriented) and the PRD's stated acceptable choices (Riverpod, go_router, Dio, flutter_secure_storage):

```text
lib/
├── app/                 # bootstrap, MaterialApp, theme wiring
├── core/
│   ├── config/          # environment enum, base-URL, flavors
│   ├── network/         # Dio client + interceptors (auth inject + 401 single refresh)
│   ├── storage/         # flutter_secure_storage wrapper + key constants
│   ├── errors/          # error types, centralized status mapping (healthy/warning/high_risk/invalid)
│   ├── routing/         # go_router config + auth guard + MFA guard
│   ├── theme/           # color tokens, typography, spacing
│   ├── widgets/         # reusable buttons/inputs/app bar/StateView/status badge
│   └── utils/           # date/number formatting
└── features/
    ├── splash/ auth/ account/ patient/ home/ screenings/{latest,history,detail}/
    ├── notifications/ education/ settings/
```

Architecture decisions (to be locked when Phase 1 finds real code, not assumptions):

| Decision | Choice | Basis |
|---|---|---|
| Project structure | feature-oriented `core/` + `features/` | PRD §10 (greenfield default) |
| State management | Riverpod 2.x (proposed) | PRD §11; none present |
| Routing | go_router (proposed) | PRD §12; none present |
| HTTP client | Dio (proposed) | PRD §13; none present |
| Secure storage | flutter_secure_storage (proposed) | PRD §18; none present |
| Auth state owner | Riverpod TokenRepository (single source) | PRD §11,§12 |
| JWT refresh | single coordinated refresh, queued retries | PRD §19 |
| MFA challenge state | opaque to mobile; store in secure storage, never log | Backend Phase 9 §15 (DB `MFALoginChallenge`, SHA-256 nonce, no secret) |
| API error model | envelope `{detail, errors}` + `error.code/message/details/request_id` | Backend Phase 1 §31; API Contract Draft §11 |
| Environment | config-driven base URL; `--dart-define` or flavor; no hardcoded host/secret | PRD §15 |
| Platform | Android first | PRD §79 |
| Firebase boundary | NOT before Phase 8; FID via `FirebaseInstallations.instance.getId()` only | Backend Phase 7 §111; PRD §36 |
| Education boundary | public read-only; treat article body as trusted Markdown/plain text, never execute as HTML/script | Backend Phase 8 §48–51 |
| Healthcare API | excluded from patient app | PRD §69; Backend Phase 6 |

## G. Auth / token / MFA architecture (reference for Phase 2)

- Access token: short-lived JWT (Backend Phase 9 §127: HS256, short-lived, rotation+blacklist).
- Refresh token: rotatable JWT with blacklist (Backend Phase 1 §68).
- MFA (corrected): password login → backend returns `{requires_2fa:true, challenge:"<signed/ DB challenge>"}`; OTP screen → `POST /api/v1/auth/2fa/login/` `{challenge, otp_code}` → final JWTs (`mfa_verified=true`). Backend Phase 9 hardened the challenge to a DB-backed `MFALoginChallenge` (SHA-256 nonce, no OTP/TOTP secret); the client treats `challenge` as opaque sensitive material (store securely, never log — PRD §54, §1055).
- Logout: `POST /api/v1/auth/logout/` (revokes supplied refresh token) + clear local tokens/challenge + reset nav (PRD §42).
- Password reset: `POST /api/v1/auth/password/reset/` → `POST /api/v1/auth/password/reset/confirm/` (Backend Phase 9 §15); not in PRD screen map — available, not scoped to MVP unless product approves.
- Health probes: `/health/live/`, `/health/ready/` — available (not a mobile feature, but confirms backend availability).

## H. JWT refresh architecture (reference for Phase 2)

```text
API request → 401 → single coordinated refresh (queued) → retry (success) OR clear auth → Login
```
No multiple simultaneous refreshes; no infinite loops (PRD §19).

## I. Data / domain rules (carried into all phases)

- `User ≠ Patient`; `GET /api/v1/patients/me/` 404 = unlinked, not an error (PRD §23,§696).
- `invalid` (sample_valid=false) ≠ healthy/warning/high_risk; never manufactured (PRD §27,§826).
- `high_risk` ≠ confirmed disease (PRD §26,§813).
- `confidence_score` ≠ calibrated probability (PRD §32,§951).
- Notification read ≠ push delivery; DB Notification is source of truth (Backend Phase 5 §1, PRD §1335).
- No device credentials/fingerprint templates/secrets in Flutter (PRD §53,§55,§56,§91).
- Medical status must not be color-only (PRD §59).

## J. Figma reference (verified access status)

- Figma URL: `https://www.figma.com/design/h9MvTHL7CoVAZ2HYh92Jp0/Untitled?node-id=0-1&t=qeEMe4iZTSquHRFv-1`
- **FIGMA DIRECT ACCESS: NOT AVAILABLE** — the only connected MCP is `graphify-jeejak` (code-graph tooling); no Figma MCP server is present.
- Per PRD §6/§87: when Figma cannot be accessed, the agent must NOT invent colors, font sizes, spacing, components, or screens. Design-token extraction is deferred to Phase 1; `docs/mobile/04-design-system.md` is marked as a skeleton with CONFIRMED/UNCONFIRMED split.

## K. Design-system verification status

- `docs/mobile/04-design-system.md`: tokens skeleton only. No tokens were extracted from Figma (no access). Marked UNCONFIRMED; to be populated in Phase 1 from Figma.

## L. API contract status (verified)

`docs/mobile/02-api-integration-contract.md` is updated during Phase 0 to reflect verified contracts:
- Auth (Phase 1): register/login/2fa-login/refresh/logout/profile/change-password — READY.
- Patient identity (Phase 2): `GET /api/v1/patients/me/` — READY.
- Screening (Phase 4): list/latest/detail — READY.
- Notifications (Phase 5): list/unread-count/read/read-all — READY.
- FCM (Phase 7): push-devices FID registration — FINAL.
- Education (Phase 8): education/articles/categories — READY.
- Health probes — available (not a mobile feature).
- Password-reset — available; not in PRD screen map (documented, not scoped).
- No endpoints invented (PRD §14,§86,§2162).

## M. Backend readiness summary

- READY: Auth+MFA, Patient identity, Screening query, Notifications, FCM (finalized), Education.
- OUT OF SCOPE: Healthcare `/api/v1/healthcare/*`, IoT ingestion device auth (not for patient client).
- Deferred: AI/Tanya AI (PRD §1276), analytics, Crashlytics (PRD §70,§71), maps, payments, social/phone/biometric login (PRD §90,§1254).

## N. Dependencies recommended (NOT added in Phase 0)

| Package | Purpose | Phase to add | Why | Alternative considered |
|---|---|---|---|---|
| flutter_riverpod | state management | Phase 1 | PRD §11 permits; none present | Provider (rejected: mixing libs discouraged) |
| go_router | routing | Phase 1 | PRD §12 permits; none present | auto_route/beam (rejected: extra codegen/complexity) |
| dio | HTTP client | Phase 1 | PRD §13 permits; none present | http (rejected: no built-in refresh/interceptors) |
| flutter_secure_storage | secure token/MFA-challenge/FID-hint storage | Phase 2 | PRD §18 permits; none present | plain SharedPreferences (rejected: insecure) |
| flutter_lints | analyzer lints | Phase 1 | PRD §78 standard baseline | hand-written rules (rejected: maintenance) |
| firebase_core / firebase_installations / firebase_messaging | FID push | Phase 8 only (after Phase 7 foundation + FID verification) | Backend Phase 7 finalized FID contract | none (FCM required for push) |

No package versions are pinned (rule §11: do not select versions until verified against the installed toolchain).

## O. Phase 1 prerequisites

1. Flutter SDK detected: **3.44.4 / Dart 3.12.2 stable** (present).
2. Android toolchain available for debug builds (PRD §79) — to be confirmed at Phase 1 execution.
3. Greenfield scaffold: `flutter create .` then apply the Phase 1 structure; replace default main.dart with bootstrap/app.dart.
4. Figma access to be re-attempted in Phase 1 to populate design tokens.

## P. Blockers

- **No Flutter project exists** — this is by design for Phase 0 (project creation is Phase 1). It blocks only build/test validation in this phase, not Phase 1.
- **Figma direct access unavailable** — defers design-token extraction to Phase 1 (must not invent tokens).
- **No Phase 1 project scaffold** — `flutter analyze`/`flutter test` not runnable against a non-existent project.

Phase 0 itself is NOT blocked: the audit and architecture baseline are complete.

## Q. Files changed in this Phase 0 execution

Documentation updates only (no Flutter source, no backend changes, no deps added, no Git init):

- `docs/mobile/02-api-integration-contract.md` — corrected FCM→FINAL, Education→READY, added password-reset + health probes + Education contract.
- `docs/mobile/01-mobile-phase-plan.md` — corrected Phase 8/9 statuses to READY; updated blockers/conditional notes; added backend docs 14–18.
- `docs/mobile/phases/08-phase-8-firebase-push.md` — corrected status to READY (backend final); kept implementer re-verification guard.
- `docs/mobile/phases/09-phase-9-education.md` — corrected status to READY (backend contract available); added real Education scope.
- `docs/mobile/04-design-system.md` — marked FIGMA access unavailable; CONFIRMED/UNCONFIRMED split.
- `docs/mobile/01-mobile-architecture.md` — added Education/FID/password-reset/health-probe decisions.
- `docs/mobile/03-ui-screen-map.md` — added Education/Nutrition/Help (backend ready); noted password-reset available but not in PRD screen map.
- `docs/mobile/phase-reports/phase-0-repository-audit-report.md` — this file (execution report).

## R. Verification of Phase 0 rules (§35)

1. Documentation files exist: ✓ (20 under docs/mobile/).
2. No production Flutter code created: ✓ (NO — greenfield, no `flutter create`).
3. No dependency added: ✓ (NO).
4. Backend NOT modified: ✓ (NO — inspected docs/source read-only).
5. Git NOT initialized: ✓ (NO — `git status` confirms not a repo; `git init` not run).
6. Stale FCM + Education statuses corrected: ✓ (Phase 8→READY/FINAL; Phase 9→READY).
7. Architecture document matches actual repo state: ✓ (document states greenfield/no code; recommendations clearly marked as proposals pending Phase 1 evidence).
8. API contract does not invent endpoints: ✓ (all from verified backend reports).

## S. Final verdict

PHASE 0 STATUS: COMPLETED
REPOSITORY TYPE: NOT GIT
FLUTTER PROJECT EXISTS: NO
PUBSPEC EXISTS: NO
FLUTTER TOOLCHAIN: 3.44.4 (Dart 3.12.2, stable)
FLUTTER PROJECT CREATED: NO
PRODUCTION FLUTTER CODE CHANGED: NO
DEPENDENCIES ADDED: NO
BACKEND MODIFIED: NO
GIT INITIALIZED: NO

Ready for Phase 1.
