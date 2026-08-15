# HepaSense Mobile — Phase 1: Flutter Foundation, Theme, Routing & Design System

## 1. Objective

Bootstrap a minimal, runnable Flutter Android project and establish the reusable foundations the rest of the app depends on: app bootstrap, environment/config structure, centralized API base configuration, theme/color tokens/typography, reusable components (buttons, inputs, app bar, loading/empty/error states), routing foundation, and an authentication-route-guard foundation. Full Authentication is **not** implemented in this phase.

## 2. Why This Phase Exists

The mobile repository is greenfield (Phase 0). Without a bootstrap, routing, theme, and shared widgets, every feature phase would re-create these or diverge in style. Phase 1 produces the shared shell so Phases 2–12 add features against a stable foundation. It must not yet implement login/register/MFA (that is Phase 2) and must not yet add Firebase.

## 3. Required Reading

- `docs/mobile/00-mobile-prd.md` (canonical PRD): §§6, 10, 11, 12, 13, 15, 18, 50, 51, 58, 60, 72, 78, 79, 88, 89, 91, 1502, 2204–2221.
- `docs/mobile/01-mobile-architecture.md` (decisions D1–D12).
- `docs/mobile/02-api-integration-contract.md` (base URL, header, envelope).
- `docs/mobile/03-ui-screen-map.md`.
- `docs/mobile/04-design-system.md` (skeleton to be refined from Figma).
- `docs/mobile/phases/00-phase-0-repository-audit.md`.
- Figma: `https://www.figma.com/design/h9MvTHL7CoVAZ2HYh92Jp0/Untitled?node-id=0-1&t=qeEMe4iZTSquHRFv-1` (visual tokens).
- Backend reports: `docs/backend/06-phase-1-auth-implementation.md` (for token shape & guard semantics), `docs/backend/13-phase-7-fcm-push-notifications.md` (must NOT be implemented yet).

## 4. Preconditions

- Phase 0 planning documents exist.
- Flutter SDK is installed on the build machine (detect/version with `flutter --version`); do **not** install/upgrade (PRD §79, Phase 0 §16).
- Android toolchain available (PRD §79; Android-only first).

## 5. Repository Audit Before Editing

- Confirm `pubspec.yaml` still absent (greenfield). If an existing Flutter project somehow exists, adapt instead of overwriting (PRD §89).
- Inspect any existing `lib/`, `android/`, `analysis_options.yaml` — none are expected (Phase 0).
- **Do not** run `git init`, `git reset --hard`, or `git clean -fd` (PRD §88, §2224). Preserve unrelated user changes; here there are none to preserve.
- Determine the Flutter/Dart version actually present and record in the Phase 1 report.

## 6. In Scope

- [ ] `flutter create .` (or minimal equivalent) to establish the Android project. Keep PRD §89 (no unnecessary regeneration).
- [ ] Adopt `analysis_options.yaml` with `package:flutter_lints/flutter_lints.dart` (PRD §78). Do not globally suppress warnings.
- [ ] App bootstrap (`lib/app/bootstrap.dart`): ensure Flutter bindings initialized before runApp.
- [ ] App entry (`lib/app/app.dart`): MaterialApp with placeholder theme + placeholder home.
- [ ] Environment/config structure (`lib/core/config/`): enum dev/staging/prod, base-URL resolution, app config holder. **No hardcoded host or secret** (PRD §15, §91).
- [ ] Centralized API base configuration stub in `lib/core/network/`: base Dio options, interceptor slots for access-token injection (stub) and 401 refresh coordination (stub). Do not implement real auth flows here.
- [ ] Theme: `lib/core/theme/` — color tokens, typography, ThemeData, spacing tokens (refined from Figma; smallest consistent UI if Figma unavailable).
- [ ] Reusable widgets: primary/secondary buttons, text field + password-toggle, top app bar, `StateView` (loading/empty/error/retry), section header (PRD §1537, §58).
- [ ] Status mapping skeleton: `lib/core/errors/status_mapping.dart` for healthy/warning/high_risk/invalid with placeholder copy and a guard that status is not color-only (PRD §59, §26).
- [ ] go_router foundation: `lib/core/routing/` — route constants, `app_router.dart` with a placeholder `ShellRoute`, and an `AuthGuard` stub that guards protected routes (auth state is stubbed to "unknown" so Home is not flashed before auth state is known — PRD §17, §12).
- [ ] `SecureStorage`/`SecureKeys` wrapper stub (`lib/core/storage/`) with key-name constants only (no values); do not store tokens yet (Phase 2).
- [ ] `flavor`/`environmentFlavor.dart` wiring via build config, **no** committed secrets (PRD §15, §907).
- [ ] Polish `docs/mobile/04-design-system.md` with Figma-derived concrete tokens where accessible; report if not.

## 7. Out of Scope

- Login/register/MFA/session restoration (Phase 2).
- Patient/Screening/Notification APIs (Phase 3+).
- Firebase / FCM (Phase 8 only, after final contract).
- Production build signing config (deferred to Phase 12; do not commit keystores).
- Analytics / Crashlytics / Crash-reporting SDK (PRD §70, §71).
- Any backend endpoint call against a live backend (no credentials in tests — PRD §77).

## 8. Backend Contract

Phase 1 consumes **no** backend endpoints for runtime behavior. It stubs the shape of the contract from `docs/mobile/02-api-integration-contract.md`:

- Base URL (config-driven).
- `Authorization: Bearer <access JWT>` header (to be injected by the interceptor; access token stored securely in Phase 2).
- 401 trigger → refresh coordination slot (Phase 2 implements; Phase 1 provides the interception hook only).

## 9. Data / Domain Rules

- `User ≠ Patient` (PRD §23). Phase 1 must not assume a linked Patient.
- `invalid` ≠ healthy/warning/high_risk (PRD §27).
- Status mapping centralized; color not the sole communicator (PRD §59).
- App is online-first; no offline sync engine (PRD §13, §1195).
- No medical data persisted locally in this phase (Phase 0 §13).

## 10. UI / Figma Requirements

- Refine design tokens from Figma; smallest consistent UI where a design element is missing (PRD §6, §225).
- Reusable components must be consistent across screens (PRD §1529).
- Account for SafeArea, keyboard, small phones, text scaling (PRD §229).
- Touch targets ≥ 48dp (PRD §248).

## 11. State Requirements

Foundation scaffolding for later concrete states:

- Auth gate state: `loading | authenticated | unauthenticated` (stubbed to `loading` so Home never flashes — PRD §17).
- Router `redirect`: `loading → none` until Phase 2 supplies real session.
- Shared UI states: `initial | loading | success | empty | failure` (PRD §365, §1390) provided by `StateView`.

## 12. Architecture Requirements

- Reuse `lib/core/` + `lib/features/` structure (architecture D1).
- Single `ApiClient` (Dio) instance used by all repositories (PRD §13, §419).
- Reuse > Extend > Refactor > Replace (PRD §13, task §13).
- No premature abstraction for single-use components (PRD §1550).

## 13. Security & Privacy Requirements

- No hardcoded secrets/host (PRD §15, §91).
- Placeholder `SecureStorage` wrapper: key-name constants only; values never logged (PRD §54).
- No device credentials in the client (PRD §53, §56, §91).
- No medical data persisted in this phase (PRD §53, §56).
- Logging hooks redact-sensitive by default (Phase 1 provides no logging of secrets).

## 14. Implementation Tasks

Ordered checklist:

- [ ] Run `flutter --version`; record SDK version.
- [ ] `flutter create .` (Android) if no project exists; confirm `pubspec.yaml`, `lib/main.dart`, `android/` created.
- [ ] Replace default `main.dart` with `lib/app/bootstrap.dart` + `lib/app/app.dart` (minimal MaterialApp).
- [ ] Add `analysis_options.yaml` with `package:flutter_lints/flutter_lints.dart`.
- [ ] Add deps: `flutter_riverpod`, `go_router`, `dio`, `flutter_secure_storage`, `flutter_lints` (and dev `mocktail`, `build_runner`/`json_serial`, etc. only if used this phase).
- [ ] Create `lib/core/config/` (environment enum, base URL resolver, config holder, flavor wiring).
- [ ] Create `lib/core/network/` (api_client.dart, interceptors stubs, api_error.dart, api_result.dart).
- [ ] Create `lib/core/storage/` (secure_storage.dart wrapper, secure_keys.dart constants).
- [ ] Create `lib/core/theme/` (app_colors.dart, app_text_styles.dart, app_theme.dart, spacing.dart).
- [ ] Create `lib/core/widgets/` (app_button.dart, app_text_field.dart, app_bar.dart, state_view.dart, section_header.dart, status_badge.dart).
- [ ] Create `lib/core/errors/status_mapping.dart` (mapping + guard copy).
- [ ] Create `lib/core/routing/` (routes.dart, app_router.dart with stub ShellRoute + AuthGuard stub).
- [ ] Polish `docs/mobile/04-design-system.md` from Figma.
- [ ] Add Phase 1 report to `docs/mobile/phase-reports/`.
- [ ] Run `dart format .`, `flutter analyze`, `flutter test` (baseline empty).
- [ ] Run `flutter build apk --debug` to confirm the shell runs on Android.

## 15. Tests Required

- Widget test: `StateView` renders loading/empty/error states.
- Widget test: `StatusBadge` renders all four statuses with non-color text.
- Unit test: `StatusMapping` maps backend `status` string → safe label + guard that `invalid` never returns a classification label.
- Unit test: environment resolver returns base URL per environment; never returns an empty/secret URL.
- Unit test: `SecureStorage` key constants exist; value-read path is a stub returning null (no real storage writes of secrets).
- No tests against a live backend (PRD §77).

## 16. Validation Commands

```bash
cd /home/yoga/Data/TFS/hepasense_mobile
flutter --version
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

Do **not** install/upgrade Flutter. If the SDK is absent, record it as a blocker and stop (PRD §79).

## 17. Definition of Done

- [ ] Project is buildable and runs on Android emulator/device (debug build passes).
- [ ] `flutter analyze` is clean (no new warnings).
- [ ] `flutter test` passes (baseline + the tests above).
- [ ] `dart format .` is clean.
- [ ] Environment/config structure exists; no hardcoded host/secret.
- [ ] API client + interceptor stubs + refresh hook exist.
- [ ] Theme + design tokens refined from Figma (or assumption reported).
- [ ] Reusable components exist and are tested.
- [ ] Routing foundation + auth-guard stub exist.
- [ ] No backend call implemented; no Firebase added.
- [ ] Phase 1 report written.

## 18. Stop Conditions / Blockers

- STOP if Flutter SDK is not installed and cannot be made available without violating "do not install Flutter" — report and wait.
- STOP if an existing Flutter project is discovered that was not captured by Phase 0 — adapt instead of creating.
- STOP if Figma access is required to resolve a token that would otherwise be guessed — report the missing design info.
- STOP if a needed dependency requires a Flutter/Dart version newer than installed without an approved migration (PRD §1506).

## 19. Required Documentation Output

`docs/mobile/phase-reports/phase-1-foundation-report.md` containing files changed, dependencies added (+ justification), analyzer result, test result, build result, assumptions (Figma access, SDK version), and whether the auth-guard stub is ready for Phase 2.

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

Then STOP. Do not begin Phase 2 automatically.
