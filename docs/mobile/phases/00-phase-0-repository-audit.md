# HepaSense Mobile — Phase 0: Repository Audit & Architecture Baseline

## 1. Objective

Establish the authoritative baseline of the HepaSense Flutter mobile repository and produce the foundational mobile documentation before any feature implementation begins. Record what exists, what is missing, what the backend actually provides, and the recommended architecture that reuses the PRD-proposed structure when the repository is greenfield.

No production Flutter feature code is written in this phase.

## 2. Why This Phase Exists

Every subsequent mobile phase depends on an accurate audit of the existing Flutter project. If architecture is designed from assumptions (e.g., inventing a different state-management library, router, or network layer), later phases silently diverge from what the repository already contains. This phase guarantees that:

- The implementation agent reads the real repository before modifying it.
- Missing files are recorded rather than guessed.
- The backend contract is validated against the actual backend phase reports.
- A concrete, conservative architecture direction is documented for reuse by Phases 1–12.

## 3. Required Reading

The implementation agent MUST inspect, in this order:

1. `prd.md` (the actual mobile PRD) — repo root. NOTE: the PRD references `docs/mobile/00-mobile-prd.md`, which does **NOT** exist; the real PRD file is the repo-root `prd.md`. This discrepancy is recorded as a finding.
2. `<backend-root>/docs/backend/00-backend-audit.md`
3. `<backend-root>/docs/backend/04-api-contract-draft.md` (proposal; superseded by phase reports below)
4. `<backend-root>/docs/backend/05-data-model-draft.md`
5. `<backend-root>/docs/backend/06-phase-1-auth-implementation.md`
6. `<backend-root>/docs/backend/08-phase-2-patient-identity.md`
7. `<backend-root>/docs/backend/10-phase-4-screening-query-api.md`
8. `<backend-root>/docs/backend/11-phase-5-notifications.md`
9. `<backend-root>/docs/backend/13-phase-7-fcm-push-notifications.md`
10. `<backend-root>/docs/backend/01-architecture.md` and `<backend-root>/docs/backend/02-gap-analysis.md`

Backend root path: `/home/yoga/Data/TFS/hepasense_backend/`. The mobile PRD refers to these by relative name (`docs/backend/...`); the agent must resolve that path to the sibling repository above.

## 4. Preconditions

- A local copy of the mobile repository is present at the working directory.
- The related backend repository is present at `/home/yoga/Data/TFS/hepasense_backend/`.
- No Flutter/Dart SDK assumptions are made; the agent must detect the toolchain availability itself.

## 5. Repository Audit Before Editing

### 5.1 What actually exists in the mobile repo

Inventory of `/home/yoga/Data/TFS/hepasense_mobile/` at audit time:

| Path | Status |
| --- | --- |
| `prd.md` | EXISTS (mobile PRD, 2516 lines) |
| `pubspec.yaml` | **MISSING** |
| `lib/` | **MISSING** |
| `android/` | **MISSING** |
| `ios/` | **MISSING** |
| `test/` | **MISSING** |
| `analysis_options.yaml` | **MISSING** |
| `.opencode/` | **MISSING** |
| `AGENTS.md` | **MISSING** |
| `README.md` | **MISSING** |
| `docs/` | **MISSING** (created in this phase for planning docs only) |

### 5.2 Version control

- The mobile directory is **NOT** a Git repository (`Is directory a git repo: no`).
- Per PRD §88 (SOURCE CONTROL SAFETY), the agent must **NOT** run `git init`, `git reset --hard`, or `git clean -fd` automatically. Report the condition instead.

### 5.3 Toolchain / language expectations

- Flutter/Dart SDK: not declared by any existing manifest (no `pubspec.yaml` or `.metadata`).
- Per PRD §79 (BUILD VALIDATION), the target platform is **Android only** initially; iOS completion is **not** required unless separately requested.
- The agent must detect the installed Flutter version during Phase 0 execution and record it in the Phase 0 report. Do **not** install or upgrade Flutter automatically.

### 5.4 Existing architecture

None. The repository is **greenfield** for Flutter code. Per PRD §10 (MOBILE ARCHITECTURE PRINCIPLES), the recommended feature-oriented structure applies:

```text
lib/
├── app/           # app bootstrap, theme, localization holder
├── core/
│   ├── config/    # environment/base URL, app config
│   ├── network/   # centralized API client (Dio) + interceptors
│   ├── storage/   # flutter_secure_storage wrapper
│   ├── errors/    # error types, status mapping
│   ├── routing/   # go_router configuration + auth guards
│   ├── theme/     # color tokens, typography, design system
│   └── widgets/   # reusable components
└── features/
    ├── splash/
    ├── auth/
    ├── profile/
    ├── home/
    ├── screenings/
    ├── notifications/
    ├── education/
    └── settings/
```

### 5.5 Routing assessment

No routing exists. Recommendation (PRD §12): `go_router`, providing authentication gate, authenticated shell, MFA intermediate state, detail navigation, notification navigation, and logout reset. Protected routes must not remain accessible after logout.

### 5.6 State-management assessment

No state management exists. Recommendation (PRD §11): **Riverpod** (2.x). Do not introduce multiple competing libraries (no Bloc + Riverpod + Provider mix). State must represent `initial`, `loading`, `success`, `empty`, `failure` where relevant.

### 5.7 Network / HTTP assessment

No network layer exists. Recommendation (PRD §13): **Dio** with a centralized client. Never make direct HTTP calls inside screens. Flow: UI → controller/provider → repository → API client → Django.

### 5.8 Secure-storage assessment

No secure storage exists. Recommendation (PRD §18): `flutter_secure_storage` for access/refresh tokens, MFA challenge material, and the `fid_hint`/FID registration metadata. Never log access/refresh tokens, MFA challenge, passwords, TOTP codes, or full FIDs (PRD §54, §1055–1063).

### 5.9 Theme / design-system assessment

No theme or design tokens exist. The mobile PRD delegates visual fidelity to Figma (PRD §3, §6). Phase 0 produces `docs/mobile/04-design-system.md` as a skeleton to be refined from Figma during Phase 1 UI implementation. Do not invent an unrelated design system (PRD §6, §224).

### 5.10 Assets / fonts / localization

None exist. Localization target is **Bahasa Indonesia** (PRD §5, §7). Assets and fonts will be added in Phase 1 from Figma. The PRD §728–729 navigation concept and §254 screen map define the required set. Do not add localization packages before Phase 1 inspects Figma/language needs.

### 5.11 Environment / configuration

No environment handling exists. Recommendation (PRD §15): configuration-driven API base URL with `development`, `staging`, `production` environments. Never hardcode `localhost`, private developer IPs, production secrets, Firebase credentials, or API keys into UI/domain code (PRD §15, §91).

### 5.12 Firebase configuration

None exists in the mobile repo. **Firebase is NOT introduced before the approved phase** (PRD §523, §1054–1063, §2301). See §7 (Backend Contract) of this Phase 0 and Phase 8 for the FCM contract status.

### 5.13 Tests

No tests exist. Baseline = empty. PRD §72 (TESTING STRATEGY) and §77 (TEST NETWORK POLICY) require mock/fake API boundaries and no production credentials in tests. Test architecture will follow the repository once established; Phase 12 mandates full coverage of the test scenarios in PRD §73–76.

### 5.14 Analyzer / lint baseline

No `analysis_options.yaml` exists. Baseline = none. PRD §78 (STATIC QUALITY) requires `flutter analyze` to be clean by the end of each phase. Phase 0 recommends adopting `flutter_lints` (standard `package:flutter_lints/flutter_lints.dart`) and the `lints` package in Phase 1, with no global warning suppression (PRD §78).

### 5.15 Existing screens / placeholders / dead code

None exist (greenfield). No duplicate or dead Flutter code. No hardcoded URLs, hardcoded secrets, or mock medical data in the Flutter tree yet. Any mock data introduced in later phases for UI development must be removed once production data exists (PRD §11).

### 5.16 Backend integration mapping (verified)

The backend is in a **separate sibling repository** and must NOT be modified by the mobile agent (PRD §86). Verified backend contracts available for mobile:

| Domain | Backend Phase | Auth | Endpoints | Mobile Status |
| --- | --- | --- | --- | --- |
| Authentication / MFA | Phase 1 | JWT + TOTP | `POST /api/v1/auth/register/`, `POST /api/v1/auth/login/`, `POST /api/v1/auth/token/refresh/`, `POST /api/v1/auth/2fa/login/`, `POST /api/v1/auth/logout/`; `GET\|PUT\|PATCH /api/v1/accounts/profile/`, `POST /api/v1/accounts/change-password/` | READY |
| Patient identity | Phase 2 | JWT | `GET /api/v1/patients/me/` (404 if unlinked) | READY |
| Screening query | Phase 4 | JWT (MFA-enforcing) | `GET /api/v1/screenings/`, `GET /api/v1/screenings/latest/`, `GET /api/v1/screenings/{id}/` (read-only) | READY |
| Database notifications | Phase 5 | JWT | `GET /api/v1/notifications/`, `GET /api/v1/notifications/unread-count/`, `POST /api/v1/notifications/{id}/read/`, `POST /api/v1/notifications/read-all/` | READY |
| Firebase push | Phase 7 | JWT | `POST/GET /api/v1/notifications/push-devices/`, `DELETE /api/v1/notifications/push-devices/{id}/` (FID-based) | FINALIZED (see note) |
| Healthcare (clinician) | Phase 6 | JWT (doctor) | `/api/v1/healthcare/*` | OUT OF SCOPE (PRD §69) |

**FCM note:** The mobile PRD §36/§80 state FCM registration is "WAIT — contract under final verification." The backend Phase 7 report (13-phase-7-fcm-push-notifications.md), dated 2026-08-12 and **COMPLETED**, explicitly finalizes the contract: registration uses `FirebaseInstallations.instance.getId()` (the **FID**, write-only; the endpoint **rejects** the legacy `token` field with 400), and the response returns only an 8-char `fid_hint`. This is the final mobile-side contract for Phase 8. The Phase 8 mobile document still requires the implementer to re-inspect backend document `13-phase-7-fcm-push-notifications.md` before adding FlutterFire packages.

**Conditional/missing backends** (do NOT invent endpoints):

| Domain | Backend Status | Mobile Status |
| --- | --- | --- |
| Education / Nutrition / FAQ | Not finalized; articles exist as candidate only | BLOCKED (Phase 9) |
| Report-by-email | Not defined | DEFERRED (Phase 10) |
| AI / Tanya AI | Not implemented | DEFERRED (Phase 9 / out of scope) |

### 5.17 Proposed architecture that reuses existing code

Because the Flutter tree is greenfield, "reuse" means reusing the **backend contracts already implemented** and the **PRD-proposed structure**. Specifically:

- Reuse the implemented Django REST contract (Phases 1, 2, 4, 5, 7) as-is; never invent endpoints (PRD §86, §14).
- Adopt the PRD feature structure (PRD §10) with `core/` cross-cutting + `features/` per-domain.
- Adopt Riverpod + go_router + Dio + flutter_secure_storage (all recommended by the PRD and none present, so no replacement of existing working code).
- Reuse a single status→UI mapping for `healthy`/`warning`/`high_risk`/`invalid` (PRD §59, centralized) across Home, History, Detail, and Notifications.
- Reuse a single centralized error/status envelope and loading/empty/error components (PRD §50, §51, §58).
- Do **not** replace the backend's JWT MFA enforcement on the client; mirror its behavior (MFA challenge → 2FA screen → JWTs with `mfa_verified`).

### 5.18 Known technical debt / blockers for mobile

1. Mobile repo is greenfield — no baseline code to preserve; the first phase builds the foundation.
2. `docs/mobile/00-mobile-prd.md` is referenced by convention but does not exist; the PRD is at repo root `prd.md`. Phase 0 copies/relocates a canonical reference or records the canonical path.
3. No Flutter SDK is declared; the toolchain version is unknown until Phase 0 execution detects it.
4. Figma: the agent may not have direct Figma access; per PRD §6, when Figma cannot be accessed, use provided screenshots/assets/specifications, do not invent a design system, and report missing design information. Phase 1 should record whether Figma was directly inspected.
5. FCM: the backend contract is finalized, but the mobile agent must still re-verify the Phase 7 report before FlutterFire integration (PRD §36 guard).

## 6. In Scope

- [x] Inventory the mobile repository and record missing files.
- [x] Record the non-Git status; do NOT run `git init`.
- [x] Detect/record the Flutter/Dart toolchain availability and version (do not install/upgrade).
- [x] Map existing (none) architecture, routing, state, network, storage, theme, assets, tests, analyzer.
- [x] Validate every backend domain against the backend phase reports (not just the proposal draft).
- [x] Produce `docs/mobile/00-mobile-prd.md` (canonical copy of the repo-root `prd.md` under `docs/mobile/` so subsequent phases and the API-integration contract can reference the documented path).
- [x] Produce `docs/mobile/01-mobile-architecture.md` (decisions + structure).
- [x] Produce `docs/mobile/02-api-integration-contract.md` (verified mobile↔backend contract).
- [x] Produce `docs/mobile/03-ui-screen-map.md` (screen map from PRD §254).
- [x] Produce `docs/mobile/04-design-system.md` (skeleton; to be refined from Figma in Phase 1).
- [x] Produce `docs/mobile/phase-reports/phase-0-repository-audit-report.md`.
- [x] Produce this Phase 0 planning document (`docs/mobile/phases/00-phase-0-repository-audit.md`).

## 7. Out of Scope

- Implementing any product feature or UI screen.
- Creating the Flutter project skeleton (no `flutter create` of app code here; environment/config bootstrap is Phase 1).
- Installing or upgrading Flutter/Dart.
- Initializing Git.
- Modifying the Django backend.
- Adding Firebase or any production dependency.
- Interpreting FCM as "ready to code" without the Phase 8 re-verification step.

## 8. Backend Contract

Phase 0 consumes **no** backend endpoints for code. It validates the contracts documented in backend Phase 1, 2, 4, 5, and 7 reports. The mobile agent must NOT invent endpoints (PRD §86, §14). If any later phase requires an endpoint not present in a COMPLETED backend phase report, it must be marked `BLOCKED — BACKEND CONTRACT REQUIRED` (Section 18).

## 9. Data / Domain Rules

- `User ≠ Patient` (PRD §23). A User may exist without a linked Patient; `GET /api/v1/patients/me/` returns 404 in that case.
- `invalid` (sample_valid=false, classification=null) ≠ healthy/warning/high_risk (PRD §27). Never fabricate a classification from an invalid sample.
- `high_risk` ≠ confirmed disease (PRD §84, §26).
- `confidence_score` is not a calibrated medical probability (PRD §32, §36, §950). Do not label it as a disease probability.
- Notification read state ≠ push delivery (backend Phase 5 §4, PRD §39). Receiving push must not auto-mark read.
- Device credentials (`Authorization: HepaSense <device_code>:<device_secret>`) belong ONLY to the IoT device domain and must never appear in the Flutter app (PRD §53, §91).
- Healthcare `/api/v1/healthcare/*` is out of scope (PRD §69); do not integrate.

## 10. UI / Figma Requirements

- Figma = visual source of truth (PRD §3, §6, §87). The Figma URL is:
  `https://www.figma.com/design/h9MvTHL7CoVAZ2HYh92Jp0/Untitled?node-id=0-1&t=qeEMe4iZTSquHRFv-1`
- Phase 0 does not render UI. Phase 1 must inspect Figma and refine `docs/mobile/04-design-system.md` with concrete tokens; the smallest consistent UI is used when an exact element is missing (PRD §87).
- No redesign of screens; follow Figma.

## 11. State Requirements

Not applicable for Phase 0 (no feature UI states). This section is inherited by later phases, which must implement `initial/loading/success/empty/failure` (PRD §365, §141, §327).

## 12. Architecture Requirements

- Structure: `lib/app/`, `lib/core/{config,network,storage,errors,routing,theme,widgets}`, `lib/features/*` (PRD §319).
- Single source of truth per feature; reuse cross-cutting widgets (PRD §58).
- Reuse > Extend > Refactor > Replace (PRD §13, task §13).
- Centralize network config, status mapping, error envelope, and design tokens.

## 13. Security & Privacy Requirements

- No secrets in Flutter (PRD §91, §228).
- Secure storage for tokens/MFA challenge/FID metadata (PRD §18).
- Redacted logs; never log tokens/passwords/OTP/FID (PRD §54).
- Device secrets never enter the client (PRD §53, §55, §56).
- Medical status never transformed into diagnosis (PRD §3, §32, §84, §26).
- App is an untrusted API client; backend authorization remains authoritative (PRD §67).

## 14. Implementation Tasks

- [ ] Confirm exact mobile repo path and record file inventory (done above).
- [ ] Record non-Git status and note `git init` prohibition.
- [ ] Detect Flutter/Dart SDK availability/version; record in Phase 0 report (do not install).
- [ ] Write canonical `docs/mobile/00-mobile-prd.md` (copy of `prd.md`).
- [ ] Write `docs/mobile/01-mobile-architecture.md`.
- [ ] Write `docs/mobile/02-api-integration-contract.md` from backend phase reports.
- [ ] Write `docs/mobile/03-ui-screen-map.md`.
- [ ] Write `docs/mobile/04-design-system.md` skeleton.
- [ ] Write `docs/mobile/phase-reports/phase-0-repository-audit-report.md`.
- [ ] Write this Phase 0 planning document.

## 15. Tests Required

None for Phase 0 (no code). Phase 1 onward must keep `flutter test` green and add tests per PRD §72–76.

## 16. Validation Commands

```bash
flutter --version
dart --version
flutter analyze
flutter test
```

These are recorded as the baseline commands; the agent runs `flutter --version`/`dart --version` to capture the toolchain but does **not** install or upgrade Flutter. If Flutter is not installed, the Phase 0 report records that fact and notes that Phase 1 cannot run `flutter analyze`/`flutter test` until the SDK is available.

## 17. Definition of Done

- [ ] Mobile repo file inventory recorded (greenfield + `prd.md` only).
- [ ] Non-Git status recorded; no `git init` executed.
- [ ] Flutter/Dart toolchain availability + version recorded.
- [ ] `docs/mobile/00-mobile-prd.md` written.
- [ ] `docs/mobile/01-mobile-architecture.md` written.
- [ ] `docs/mobile/02-api-integration-contract.md` written.
- [ ] `docs/mobile/03-ui-screen-map.md` written.
- [ ] `docs/mobile/04-design-system.md` skeleton written.
- [ ] `docs/mobile/phase-reports/phase-0-repository-audit-report.md` written.
- [ ] Backend contract mapping validated against Phase 1/2/4/5/7 reports.
- [ ] This Phase 0 planning document written.

## 18. Stop Conditions / Blockers

- STOP if the mobile repository contains undocumented custom Flutter code not captured by this audit. (It does not — it is greenfield.)
- STOP if backend Phase 1/2/4/5/7 contracts are found to be unimplemented. (They are COMPLETED per the 2026-08-12 reports.)
- STOP if a required backend contract for a later phase is missing — mark that later phase BLOCKED (do not invent endpoints).
- REPORT: `docs/mobile/00-mobile-prd.md` was referenced but missing; canonical PRD is repo-root `prd.md`; resolved by writing the canonical copy in this phase.

## 19. Required Documentation Output

`docs/mobile/phase-reports/phase-0-repository-audit-report.md` containing:

- Files changed (new docs only; no Flutter source).
- Architecture direction adopted.
- APIs verified as available.
- Tests: baseline (empty).
- analyzer result: not applicable (no Dart source yet); toolchain recorded.
- Dependencies: none added.
- Assumptions: mobile repo is greenfield; backend lives in sibling repo; FCM contract finalized per backend Phase 7 report.
- Blockers: none for Phase 0.
- Known limitations: Figma access not yet confirmed; Flutter SDK version recorded but not installed if absent.

## 20. Required Final Response

The Phase 0 implementation must end with:

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

Then STOP. Never automatically execute Phase 1.
