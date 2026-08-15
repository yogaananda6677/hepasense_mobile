# HepaSense Mobile — Phased Implementation Plan

> Backend Phases 1–11 are COMPLETED, core is CLOSED, and the API contract is FROZEN (145 tests + 18 subtests). Authoritative contracts: backend `20-final-api-contract.md` and `21-flutter-integration-contract.md`.

**Execution status:** Mobile Phase 8 (Firebase Push/FID integration) is COMPLETED. Mobile Phase 9 is READY and not started.

**Date:** 2026-08-12 (plan generation)
**Mobile repo:** `/home/yoga/Data/TFS/hepasense_mobile/` (greenfield — contains only `prd.md` at audit)
**Backend repo:** `/home/yoga/Data/TFS/hepasense_backend/` (authoritative API source; not modified by mobile)
**Visual source of truth:** Figma
**API/data source of truth:** backend `docs/backend/*-implementation.md` reports
**Product behavior source of truth:** `docs/mobile/00-mobile-prd.md`

This is a planning document only. **No application features are implemented by this task.** Per PRD §86/§2162, if a required backend API is missing, the affected phase is marked `BLOCKED — BACKEND CONTRACT REQUIRED` and the agent never invents endpoints.

## 1. Repository baseline (Phase 0 findings)

The mobile repository is **greenfield**: at audit time it contains only `prd.md` (the mobile PRD). There is no `pubspec.yaml`, `lib/`, `android/`, `test/`, or `analysis_options.yaml`, and the directory is **not** a Git repository. Per PRD §88, the agent will **not** run `git init`, `git reset --hard`, or `git clean -fd` automatically.

- The PRD references `docs/mobile/00-mobile-prd.md`, which did not exist; Phase 0 wrote the canonical copy there.
- The PRD references backend docs as `docs/backend/*`; these actually live in the sibling backend repo. Each phase document lists the exact backend file to inspect.
- Flutter/Dart toolchain is not declared by any manifest (greenfield); Phase 1 detects the installed version and **does not** install or upgrade Flutter (PRD §79).

## 2. Backend readiness (verified against actual reports)

All backend implementation phases were COMPLETED on 2026-08-12. The mobile agent must re-read each report before implementing the corresponding mobile phase.

| Backend Phase | Report | Mobile-relevant status |
|---|---|---|
| Phase 1 | `docs/backend/06-phase-1-auth-implementation.md` | Auth/MFA/profile/password/logout — COMPLETED |
| Phase 2 | `docs/backend/08-phase-2-patient-identity.md` | Patient identity, `GET /api/v1/patients/me/` — COMPLETED |
| Phase 3 | `docs/backend/09-phase-3-device-screening-iot.md` | Device ingestion — COMPLETED (IoT-side, **not** used by patient mobile directly) |
| Phase 4 | `docs/backend/10-phase-4-screening-query-api.md` | Screenings list/latest/detail — COMPLETED |
| Phase 5 | `docs/backend/11-phase-5-notifications.md` | Database notifications — COMPLETED |
| Phase 6 | `docs/backend/12-phase-6-healthcare-screening-api.md` | Clinician reads — OUT OF SCOPE for patient mobile (PRD §69) |
| Phase 7 | `docs/backend/13-phase-7-fcm-push-notifications.md` | FCM delivery, **FID-based** contract — COMPLETED/FINAL |

**FCM reconciliation:** PRD §36/§80 listed FCM registration as "WAIT — contract under final verification." The backend Phase 7 report (`docs/backend/13-phase-7-fcm-push-notifications.md`, COMPLETED 2026-08-12) **finalizes** the FID-based contract: registration uses `FirebaseInstallations.instance.getId()` (FID, write-only, returns 8-char `fid_hint`), and the endpoint **rejects** the legacy `token` field. Mobile Phase 8 is **READY — BACKEND CONTRACT FINAL** (corrected from planning-era CONDITIONAL). Implementation order is unchanged: Phase 8 is executed only after Phase 7 + required mobile foundations, and the implementer must re-inspect the backend Phase 7 report before adding FlutterFire packages. Genuine FID receipt is an external staging requirement (Backend Phase 10 §8 / `18-staging-smoke-checklist.md`).

**Education:** Backend Phase 8 (`docs/backend/14-phase-8-education-content.md`, COMPLETED 2026-08-12) implements a public read-only Education API. Mobile Phase 9 is **READY — BACKEND CONTRACT AVAILABLE** (corrected from planning-era BLOCKED). Nutrition is general education only; no Screening-based personalization.

## 3. Recommended architecture direction

- Structure: `lib/app`, `lib/core/{config,network,storage,errors,routing,theme,widgets}`, `lib/features/*` (PRD §10).
- State: Riverpod 2.x (PRD §11). No competing libraries.
- Routing: go_router with auth guard + MFA intermediate state (PRD §12).
- Network: Dio centralized client + interceptors; single coordinated refresh (PRD §13, §19).
- Storage: flutter_secure_storage for tokens/MFA challenge/FID hint (PRD §18).
- Reuse > Extend > Refactor > Replace (PRD §13, task §13).

## 4. Phase dependency graph

```text
Phase 0 (audit)
    ↓
Phase 1 (foundation, theme, routing, design system)
    ↓
Phase 2 (authentication, registration, MFA)
    ↓
Phase 3 (patient identity, profile, account, change password)
    ↓
Phase 4 (home dashboard & latest screening)
    ↓
Phase 5 (screening history)
    ↓
Phase 6 (screening detail)
    ↓
Phase 7 (notification center)
    ├───────────────┐
    ↓               ↓
Phase 8           Phase 9
(READY)           (READY)
    │               │
    └──────┬────────┘
           ↓
        Phase 10 (settings, help, privacy, account completion)
           ↓
        Phase 11 (integration, error handling, resilience, UX hardening)
           ↓
        Phase 12 (testing, security, performance, production readiness)
```

- Phases 0→1→2→3→4→5→6→7 are strictly sequential.
- Phase 8 (FCM) and Phase 9 (Education) branch from Phase 7. They are **not** required dependencies for Phase 10.
- Phase 10 depends on Phase 3 (account completion) and is reachable without Phase 8/9; Education/Help shortcuts may be placeholders while Phase 9 is blocked.
- Phase 11 depends on Phases 1–10 being implemented (Phase 8/9 as placeholders if still blocked).
- Phase 12 depends on Phase 11 and performs final verification.

## 5. Phase register

| Phase | Scope | Dependency | Backend Ready | Complexity | Status |
|---|---|---|---|---|---|
| 0 | Repository audit & architecture baseline | none | N/A (audit) | LOW | COMPLETED |
| 1 | Foundation, routing, theme, design system | 0 | N/A | HIGH | COMPLETED |
| 2 | Authentication, registration, MFA | 0,1 | Phase 1 COMPLETED | HIGH | **COMPLETED** |
| 3 | Patient identity, profile, account, change password | 0,2 | Phase 1+2 COMPLETED | MEDIUM | READY |
| 4 | Home dashboard & latest screening | 0,2,3 | Phase 2+4 COMPLETED | MEDIUM-HIGH | READY |
| 5 | Screening history | 0,4 | Phase 4 COMPLETED | MEDIUM | READY |
| 6 | Screening detail | 0,4,5 | Phase 4 COMPLETED | MEDIUM | READY |
| 7 | Notification center | 0,4 | Phase 5 COMPLETED | MEDIUM | COMPLETED |
| 8 | Firebase push integration | 0,2,7 | Phase 7 FINALIZED (FID) | HIGH | COMPLETED |
| 9 | Education, nutrition, FAQ | 0,7 | Phase 8 COMPLETED | MEDIUM | READY — BACKEND CONTRACT AVAILABLE |
| 10 | Settings, help, privacy, account completion | 0,3 | Phase 1 COMPLETED | LOW-MEDIUM | READY |
| 11 | Integration, error handling, UX hardening | 0–10 | Phases 1–5 COMPLETED | MEDIUM | READY |
| 12 | Testing, security, performance, production | 0–11 | Phases 1–5 COMPLETED | HIGH | READY |

**Status legend:** READY (backend contract verified & final), BLOCKED (no approved backend contract — must not implement), COMPLETED (planning artifact done). Execution order for Phase 8 is unchanged: implemented only after Phase 7 + mobile foundations, per the implementer re-verification guard in the Phase 8 document.**

## 6. Blockers & conditional notes

- **Phase 8 (FCM):** READY — BACKEND CONTRACT FINAL (Backend Phase 7, FID-based, dated 2026-08-12). Corrected from the planning-era CONDITIONAL. Implementation is still gated by dependency order: Phase 8 is implemented only after Phase 7 + required mobile foundations, and the implementer must re-inspect `docs/backend/13-phase-7-fcm-push-notifications.md` and use `FirebaseInstallations.instance.getId()` (never `getToken`) before adding FlutterFire. PRD §36 guard honored. Genuine FID receipt is an external staging requirement (Backend Phase 10 §8).
- **Phase 9 (Education/Nutrition/FAQ):** READY — BACKEND CONTRACT AVAILABLE (Backend Phase 8, dated 2026-08-12). Corrected from the planning-era BLOCKED. Education API is implemented and public read-only. Nutrition is general education only.
- **Password-reset + health probes:** verified available (`/api/v1/auth/password/reset/` + `/confirm/`, `/health/live/`, `/health/ready/`); not in the PRD screen map (no Forgot-Password screen) — available-but-not-scoped to the MVP screen set; documented, not invented.
- **Phase 10 report-by-email:** deferred (PRD §1334–1354); implemented only if a backend mail contract is later approved.
- **Tanya AI / AI / RAG / LLM:** DEFERRED and OUT OF SCOPE (PRD §1276–1294; task §16 hard boundaries).
- **Clinician dashboard:** OUT OF SCOPE (PRD §69, §144).

## 7. Medical-safety guardrails (apply to all phases)

- `User ≠ Patient`; unlinked-Patient is a safe domain state, not an error (PRD §23, §696).
- `invalid` (sample_valid=false) ≠ healthy/warning/high_risk; never manufacture a classification (PRD §27, §817, §826).
- `high_risk` ≠ confirmed disease (PRD §26, §813).
- `confidence_score` ≠ calibrated medical probability (PRD §32, §951).
- Screening result wording is screening-support language, not diagnosis (PRD §3, §99–113).
- Notification types must not derive diagnosis language (PRD §33, §1006).
- Database Notification is source of truth; push delivery ≠ read state (Backend Phase 5 §1, PRD §1335).
- No device credentials, raw fingerprint templates, payload digests, or internal device secrets in Flutter (PRD §53, §55, §56, §924).

## 8. Hard boundaries (never added without later approved PRD)

AI/LLM/RAG/vector DB, maps, location tracking, social login, phone/biometric login, analytics, Crashlytics, ads, payments, chat/video, IoT device control, clinician dashboard, FHIR, SATUSEHAT (PRD §90, §1254, task §16).

## 9. Phase size rule

Each phase is scoped to one OpenCode task. Splits were avoided: Phase 2 (auth+MFA) stays cohesive because its endpoints are tightly coupled; Phase 4–7 are each one data-driven screen + shared mapping; Phase 11/12 are cross-cutting verification passes. No phase mixes frontend+backend changes.

## 10. Source-control safety (reminder)

All phase documents require the implementation agent to: preserve unrelated user changes (none exist in greenfield); never run `git reset --hard`, `git clean -fd`, or `git init`; never commit unless explicitly requested; only modify files required for the current approved phase (PRD §88, §2162, §2224–2229).

## 11. Validation commands (repository-derived)

Standard per-phase commands (the repo is greenfield, so these are the Flutter-native baseline):

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release   # Phase 12 config review; signing deferred if no keystore
```

Do not install or upgrade Flutter automatically (PRD §79, Phase 0 §16).

## 12. Documentation structure

```text
docs/mobile/
├── 00-mobile-prd.md              # canonical copy of the PRD
├── 01-mobile-architecture.md     # architecture + decisions
├── 02-api-integration-contract.md# verified mobile↔backend contract
├── 03-ui-screen-map.md           # screen map from PRD §254
├── 04-design-system.md           # design tokens (skeleton → refined Phase 1)
├── phases/
│   ├── 00-phase-0-repository-audit.md
│   ├── 01-phase-1-foundation-design-system.md
│   ├── 02-phase-2-authentication-mfa.md
│   ├── 03-phase-3-patient-profile.md
│   ├── 04-phase-4-home-latest-screening.md
│   ├── 05-phase-5-screening-history.md
│   ├── 06-phase-6-screening-detail.md
│   ├── 07-phase-7-notifications.md
│   ├── 08-phase-8-firebase-push.md
│   ├── 09-phase-9-education.md
│   ├── 10-phase-10-settings-help-support.md
│   ├── 11-phase-11-ux-hardening.md
│   └── 12-phase-12-production-readiness.md
└── phase-reports/
    └── (one report per implemented phase, produced when each phase is executed)
```

Phase reports are produced **only when a phase is implemented**, not during planning.

## 13. MVP completeness (PRD §940)

The MVP is functionally complete when: register/login; MFA; session refresh/logout; profile management; unlinked-Patient safe state; latest Screening; history; detail; invalid sample; Notification Center + unread sync; (FCM after final contract); Help/privacy/support; all critical loading/empty/error states; no backend boundary bypassed; no secrets embedded; analyzer/tests/build green (PRD §946–955). Education may join MVP once its backend contract is available; AI is not required for base MVP.

---

This concludes the phased implementation plan. Implementation begins only after explicit approval, starting with **Phase 0 (Repository Audit & Architecture Baseline)**.
