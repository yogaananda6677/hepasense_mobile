# HepaSense Mobile — Architecture & Decisions

## Phase 10 account and support module

Phase 10 composes the existing Phase 3 `ProfileController`, `PatientController`, Edit Profile route, Phase 2 logout, and Phase 8 push-device logout behavior. It adds a narrowly scoped password repository/controller with no password values in Riverpod state or storage. Successful password change shows feedback, clears local password controllers, invalidates tokens, and returns through the existing auth guard. Help reuses the Phase 9 Education API model/repository with `type=help`; Privacy and About are dependency-free static product information.

## Phase 9 education module

`features/education` follows the existing data/domain/presentation split. `EducationRepository` uses the shared Dio client for the frozen public read-only API; Riverpod Notifiers own list/filter/pagination and detail state. The authenticated router exposes `/education` and `/education/:slug`, with a Home shortcut and the existing application navigation. Article bodies use a centralized dependency-free safe text renderer that recognizes only headings and list markers and never executes HTML, scripts, remote images, or links.

> Backend Phases 1–11 are COMPLETED, core is CLOSED, and the API contract is FROZEN. Use backend `20-final-api-contract.md` and `21-flutter-integration-contract.md`.

**Status:** Baseline, established by Phase 0 (repository audit).
**Source of truth for visuals:** Figma (see `docs/mobile/00-mobile-prd.md` §3, §6).
**Source of truth for API/data:** backend `docs/backend/*-implementation.md` (Phase 1/2/4/5/7 reports).

This document records the architecture direction adopted for mobile development and is refined by subsequent phases. It is **not** a wholesale rewrite; it codifies the PRD-proposed structure because the Flutter repository is greenfield (only `prd.md` exists at audit time).

Phase 3 adds separate session-memory `PatientController` and `ProfileController` ownership. Auth remains authoritative for tokens/session; Patient 404 is an unlinked domain state, and auth loss invalidates all Patient/profile state to prevent account-switch leakage.

Phase 4 adds a session-memory `HomeController` over a reusable `ScreeningRepository`. It observes linked Patient state before requesting latest Screening, maps latest-only 404 to an empty state, and is disposed with Patient/auth lifecycle changes.

Phase 5 extends the shared Screening repository with DRF page-number history. `HistoryController` owns page/filter/in-flight state, deduplicates IDs, retains page 1 on pagination errors, and is invalidated with Patient/auth lifecycle changes.

Phase 6 extends that repository with patient-scoped Screening Detail. `DetailController` owns explicit loading/loaded/not-found/error state, prevents duplicate requests, rejects stale responses, and resets with Patient/auth lifecycle changes. Detail remains in memory only.

Phase 7 adds a database-backed Notification Center. `NotificationController`
owns DRF pagination, refresh, server-confirmed read mutations, deduplication,
and stale-response protection. `UnreadCountController` shares the authoritative
backend count with the Home badge. Both are session-memory only and are
invalidated on auth loss to prevent account-switch leakage. Database
Notification remains the source of truth; Firebase push is not implemented.

Phase 8 source preparation adds a `PushService` boundary, canonical
`PushDeviceRepository`, and `PushCoordinator`. The coordinator activates only
for authenticated sessions, deduplicates FID sync, defers push-open signals
until auth is ready, refreshes database Notification state on foreground push,
and revokes only its current backend PushDevice on logout. The production
adapter uses native Android default Firebase initialization from the genuine
`google-services.json`, Firebase Messaging streams, and
`FirebaseInstallations.instance.getId()`. Firebase failure remains non-fatal.
No FID, FCM token, medical push payload, or fake Notification is persisted or
logged.

## 1. Repository baseline

- Path: `/home/yoga/Data/TFS/hepasense_mobile/`
- Contents at audit: only `prd.md` (mobile PRD). No `pubspec.yaml`, `lib/`, `android/`, `test/`, or `analysis_options.yaml`.
- Version control: **not** a Git repository. No `git init` is performed automatically (PRD §88).
- Backend: lives in the sibling repository `/home/yoga/Data/TFS/hepasense_backend/`. The mobile agent **must not modify** the backend (PRD §86).

## 2. Proposed structure

```text
lib/
├── app/
│   ├── app.dart              # root MaterialApp / widget app, theme wiring
│   ├── bootstrap.dart        # entry point: widget binding,FlutterError, DI scope
│   └── l10n/                 # arb/localization (Bahasa Indonesia) — added Phase 1/10
core/
│   ├── config/
│   │   ├── app_environment.dart   # dev/staging/prod enum + base URL resolution
│   │   ├── app_config.dart        # runtime config holder
│   │   └── environment_flavor.dart  # flavor wiring (do not hardcode secrets)
│   ├── network/
│   │   ├── api_client.dart        # Dio instance + base options
│   │   ├── auth_interceptor.dart   # access token injection
│   │   ├── refresh_interceptor.dart # 401 -> single coordinated refresh, queued retries
│   │   ├── api_error.dart         # uniform error envelope
│   │   └── api_result.dart        # success/error result wrapper
│   ├── storage/
│   │   ├── secure_storage.dart     # flutter_secure_storage wrapper
│   │   ├── secure_keys.dart        # key names only (no values)
│   │   └── auth_session.dart       # read/write access + refresh tokens, mfa challenge, fid_hint
│   ├── errors/
│   │   ├── app_error.dart          # domain error types
│   │   └── status_mapping.dart     # centralized healthy/warning/high_risk/invalid mapping + messages
│   ├── routing/
│   │   ├── app_router.dart         # go_router configuration
│   │   ├── auth_guard.dart          # authentication gate
│   │   ├── mfa_guard.dart           # MFA intermediate state
│   │   └── routes.dart              # route name/path constants
│   ├── theme/
│   │   ├── app_theme.dart           # ThemeData + color tokens
│   │   ├── app_text_styles.dart     # typography tokens
│   │   ├── app_colors.dart          # color palette
│   │   └── spacing.dart             # layout tokens
│   └── widgets/
│       ├── app_button.dart          # primary/secondary button
│       ├── app_text_field.dart      # input + password-toggle
│       ├── app_bar.dart             # top app bar
│       ├── state_view.dart          # loading/empty/error/retry components
│       └── status_badge.dart        # screening status badge (reused)
features/
├── splash/
├── auth/
├── profile/
├── home/
├── screenings/
│   ├── history/
│   ├── detail/
│   └── latest/
├── notifications/
├── education/
└── settings/
```

Reuse principle (PRD §13): **Reuse > Extend > Refactor > Replace.** This structure is the greenfield default and is only changed when a later phase's audit finds a concrete reuse/maintainability reason.

## 3. Decisions

| # | Decision | Rationale | Source |
|---|----------|-----------|--------|
| D1 | Feature-oriented `core/` + `features/` layout | PRD §10 recommended; greenfield repo | PRD §10 |
| D2 | State management: Riverpod 2.x | Not present; PRD §11 permits Riverpod; avoid mixing libraries | PRD §11 |
| D3 | Routing: go_router | Not present; PRD §12 permits go_router | PRD §12 |
| D4 | HTTP client: Dio | Not present; PRD §13 permits Dio; centralize config | PRD §13 |
| D5 | Secure storage: flutter_secure_storage | Not present; PRD §18 permits it | PRD §18 |
| D6 | JWT access/refresh tokens, stored securely | Backend Phase 1 uses SimpleJWT; MFA-enforcing | Backend Phase 1 |
| D7 | Single coordinated token refresh (queued) | PRD §19 — avoid refresh storms | PRD §19 |
| D8 | Platform: Android first | PRD §79 — Android only unless otherwise requested | PRD §79 |
| D9 | No Firebase / FCM before Phase 8 | PRD §36, §523, §91 | PRD §36 |
| D10 | FID-based push registration (finalized) | Backend Phase 7 contract is finalized | Backend 13 |
| D11 | Bahasa Indonesia UI | PRD §5 | PRD §5 |
| D12 | Centralized status→UI mapping | PRD §59, §26 | PRD §59 |

## 4. Architecture boundaries (data flow)

```text
UI
  → state/controller (Riverpod)
  → repository
  → API client (Dio)
  → Django REST API (JWT + MFA)
```

- The UI never calls the network directly (PRD §13).
- The repository owns data-source decisions (remote + in-memory only; limited local caching deferred — PRD §13, §1195).
- The API client owns base URL, headers, interceptors, refresh coordination, and the uniform error envelope (PRD §419).

## 5. Auth boundary

- Access token: short-lived JWT, held in process memory only.
- Refresh token: rotatable JWT with blacklist, stored in `flutter_secure_storage`.
- MFA: password login may return a signed, cached, 5-minute one-time challenge with `requires_2fa=true` instead of JWTs; the app routes to the OTP screen; `POST /api/v1/auth/2fa/login/` exchanges `{challenge, otp_code}` for final JWTs carrying `mfa_verified=true` (Backend Phase 1 §40–51).
  - The MFA challenge is sensitive temporary material held only for the active in-memory login attempt; it is cleared on completion/reset and never logged.
- Logout: call `POST /api/v1/auth/logout/`, clear local access/refresh state, clear sensitive in-memory data, reset protected navigation to Login (PRD §42, §1201).
- Protected routes: auth guard redirects to Login when no valid session exists (PRD §12).
- Password change invalidates JWT sessions server-side (Backend Phase 1 §73); the app clears local auth state and returns to Login if the backend returns 401 (PRD §41, §1190).

## 6. Token refresh contract

```text
API request → 401 → attempt one valid refresh → retry (success) OR clear auth → Login
```

- One coordinated refresh at a time; concurrent 401s queue behind it (PRD §19, §597).
- Never retry refresh on refresh-failure → go to Login.
- Machine credentials (`Authorization: HepaSense ...`) are never used by the mobile app (PRD §53, §56, §91).

## 7. Cross-feature reuse points

- `StatusBadge` + `StatusMapping` (`core/errors/status_mapping.dart`): shared by Home, History, Detail, Notifications.
- `StateView` (loading/empty/error/retry): shared by Home, History, Notifications.
- `AppButton`, `AppTextField`, `AppAppBar`: shared by Auth, Profile, Settings.
- `ApiClient`: single Dio instance with interceptors used by all repositories.

## 8. Environment & secrets

- Base URL is configuration-driven (PRD §15): `development`, `staging`, `production`.
- No hardcoded `localhost`, private IPs, production secrets, Firebase credentials, or API keys in UI/domain code (PRD §15, §91).
- Android `local.properties` is ignored; environment is wired via Gradle manifestPlaceholders/productFlavors or a config file generated from build config — decided in Phase 1 (PRD §459).

## 9. Backend contract ownership

- The backend is the source of truth for identity, Patient relationship, Screening records, Screening classification, Notification records, and authorization (PRD §73, §2505).
- Mobile never invents endpoints; if a contract is missing, the affected phase is marked `BLOCKED — BACKEND CONTRACT REQUIRED` (PRD §86, §14, §2162).
- Full contract is in `docs/mobile/02-api-integration-contract.md`.

## 10. Medical safety boundary

- `User ≠ Patient` (PRD §23).
- `invalid` ≠ healthy/warning/high_risk (PRD §27, §826).
- `high_risk` ≠ confirmed disease (PRD §26, §813).
- `confidence_score` ≠ calibrated probability (PRD §32, §951).
- Push payloads contain only `{notification_id, type}` — no medical detail (Backend Phase 7 §83, PRD §38).
- The app displays only patient-safe fields (Backend Phase 4 §48; raw NH3, device metadata, credentials, digest, fingerprint references excluded).
