# HepaSense Mobile — Phase 11: Integration, Error Handling, Resilience & UX Hardening

## 1. Objective

Harden the integrated app for consistent, non-diagnostic patient UX: consistent API error handling, timeouts, offline/network-unavailable states, session-expiry behavior, retry behavior, pull-to-refresh consistency, pagination robustness, app-resume freshness, duplicate-request prevention, refresh-token race prevention, loading/empty-state consistency, accessibility, responsive layout, small-device overflow, text scaling, and removal of mock data where production data exists. No major new product features.

## 2. Why This Phase Exists

MVP features exist after Phase 10. Phase 11 makes them robust and consistent before declaring production readiness (PRD §50, §933, §106). It is a cross-cutting pass over Phases 2–10, not a new feature phase.

## 3. Required Reading

- `docs/mobile/00-mobile-prd.md`: §§36–65, 50–52, 60–64, 1199–1216, 1597–1651, 1995–2011, 2325–2349.
- `docs/mobile/02-api-integration-contract.md` (error envelope).
- `docs/mobile/phases/` 1–10 reports (to audit actual state + mock data).
- Backend `docs/backend/06-phase-1-auth-implementation.md` (error envelope, session).

## 4. Preconditions

- Phases 1–10 implemented (or placeholders for blocked Phase 8/9).
- `flutter analyze` clean and tests green from Phase 10.

## 5. Repository Audit Before Editing

- Audit all repositories/interceptors for duplicate/simultaneous requests (PRD §92, §2343).
- Audit 401/refresh handling for race prevention (PRD §19, §598–601).
- Audit every screen for the `loading/success/empty/error/retry` states (PRD §1390, §2327).
- Audit for any remaining mock medical data (PRD §11: removal when production data exists).
- Audit any hardcoded URLs/secrets (PRD §15, §91, §2285).
- Audit accessibility: semantic labels, contrast, touch targets, text scaling (PRD §60, §1584–1593).
- Audit small-device overflow (PRD §229, §246–250).
- Audit logging for sensitive data (PRD §54, §1453–1469).

## 6. In Scope

- [ ] **Consistent API errors**: map backend envelope `{detail, errors}` and stable `error.code` to Indonesian user-facing messages; never expose raw stack traces (PRD §50, §1385, §2197).
- [ ] **Timeouts**: network timeout handling with user-facing timeout state (PRD §1366, §1379).
- [ ] **Offline/network-unavailable**: distinct UI for no internet (PRD §1363, §1379).
- [ ] **Session expiry**: 401 after refresh failure → clear auth, return to Login (Phase 2 already; harden + test).
- [ ] **Retry behavior**: consistent retry across Home, History, Detail, Notifications (PRD §1370, §1802).
- [ ] **Pull-to-refresh consistency** on Home, History, Notifications (PRD §1597, §1615).
- [ ] **Pagination robustness**: no duplicates; stable pagination end (PRD §29, §887, §2348).
- [ ] **App-resume freshness**: refresh latest Screening + unread count on resume without duplicate storms (PRD §1615, §1626).
- [ ] **Duplicate-request prevention**: prevent double submits during mutations (profile/password/read/mark-read) (PRD §1399, §1405).
- [ ] **Refresh-token race prevention**: single coordinated refresh (Phase 2); verify no refresh storm under concurrent 401s.
- [ ] **Loading/empty-state consistency** across all screens (PRD §1390, §2327).
- [ ] **Accessibility**: semantic labels, contrast, text scaling, large touch targets, color-not-only (PRD §60, §1593, §59).
- [ ] **Responsive / small-device**: overflow review, text scaling (PRD §229, §246–250).
- [ ] **Centralized status mapping** usage audited (PRD §59, §791).
- [ ] **Removal of mock data** where production data exists (PRD §11, §2339).
- [ ] **Audit logging**: ensure no secrets logged (PRD §54, §1461–1469).
- [ ] **Hardcoded URL/secret audit** across `lib/` (PRD §15, §91, §2285).

## 7. Out of Scope

- New product features / new screens / new backend endpoints.
- Architecture rewrite (refactor only for concrete reasons — PRD §317, task §13).
- Firebase re-architecture (Phase 8 already finalized).
- AI/analytics additions (task §16 hard boundaries).

## 8. Backend Contract

No new endpoints. Consistency pass over existing contracts (auth/profile/patients/me/screenings*/notifications*). Error envelope: `{ error.code, error.message, error.details, error.request_id }` (API Contract Draft §11) and the validation envelope `{detail, errors}` (Backend Phase 1 §31).

## 9. Data / Domain Rules

- invalid ≠ classification (PRD §27).
- high_risk ≠ diagnosis (PRD §26).
- confidence ≠ probability (PRD §32).
- Notification read ≠ push (PRD §1335).
- Backend authoritative for identity/screening/notification (PRD §2505).

## 10. UI / Figma Requirements

- Consistent error/empty/loading per Figma (PRD §36–65, §1597).
- Reusable `StateView` everywhere; consistent retry (PRD §1589).
- Text scaling + small-device overflow (PRD §229, §1609).

## 11. State Requirements

- All screens re-audited for `initial | loading | success | empty | failure` (PRD §365).
- Mutation buttons: `idle | submitting | success | error` (no double-submit).
- Refresh: single in-flight; no storms (PRD §1626).
- App resume: freshness for time-sensitive state only (PRD §1619).

## 12. Architecture Requirements

- Reuse the single `ApiClient` + interceptor stack (PRD §13, §419).
- Centralize error-to-message mapping in `core/errors/app_error.dart`.
- Centralize status mapping (PRD §59).
- Reuse `StateView` and components (PRD §1529).

## 13. Security & Privacy Requirements

- No secrets in logs; redact Authorization headers in dev logging (PRD §54, §1461–1469).
- No hardcoded URLs/secrets (PRD §15, §91, §2285).
- No medical data in disk cache beyond tokens (PRD §53, §1349).
- No device credentials (PRD §53, §91).
- Session expiry clears auth (Phase 2).

## 14. Implementation Tasks

- [ ] Audit repositories/interceptors for duplicate & race patterns; fix.
- [ ] Centralize API error→message mapping; replace generic snackbars with domain messages (PRD §1358, §1383–1386).
- [ ] Add timeout + offline states to repositories/UI.
- [ ] Harden session-expiry → Login path; add tests.
- [ ] Make retry consistent + pull-to-refresh consistent across Home/History/Notifications.
- [ ] Harden pagination (dedup, end detection).
- [ ] Add app-resume freshness for latest + unread count without storms.
- [ ] Add duplicate-submit guards on mutations.
- [ ] Audit accessibility (labels, contrast, text scaling, touch targets).
- [ ] Audit small-device overflow + responsive layout (PRD §229).
- [ ] Remove mock medical data where production data exists; document any retained mock-only-for-UI placeholders.
- [ ] Audit logging for sensitive data; redact.
- [ ] Audit hardcoded URLs/secrets across `lib/`.
- [ ] Ensure centralized status mapping used everywhere (PRD §59, §791).
- [ ] Add Phase 11 report.
- [ ] Run `dart format .`, `flutter analyze`, `flutter test`.

## 15. Tests Required

- Unit: error→message mapping for backend codes; 401 refresh-failure → logout.
- Unit: concurrent 401s → exactly one refresh (no storm).
- Unit: timeout/offline mapping.
- Unit: pagination dedup + end detection.
- Widget: consistent loading/empty/error/retry across Home/History/Detail/Notifications.
- Widget: mutation buttons disable while submitting (no double submit).
- Regression: no secrets logged; no hardcoded host/secret in code; status mapping centralized; mock medical data removed where production exists.

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

- [ ] Consistent API error handling; domain messages; no raw traces (PRD §50, §1385).
- [ ] Timeout + offline states implemented.
- [ ] Session expiry → Login; refresh race prevented.
- [ ] Pull-to-refresh + pagination consistent + robust.
- [ ] App-resume freshness without storms.
- [ ] Mutation double-submit prevented.
- [ ] Loading/empty/error/retry consistent everywhere.
- [ ] Accessibility + small-device overflow addressed.
- [ ] Mock medical data removed where production data exists.
- [ ] Logging audited; no secrets; no hardcoded host/secret.
- [ ] Status mapping centralized and reused.
- [ ] `flutter analyze` clean; `flutter test` passes.

## 18. Stop Conditions / Blockers

- STOP if a hardened behavior requires a backend change — do not modify the backend; report.
- STOP if a generic snackbar remains where a domain error state is required (PRD §1358).

## 19. Required Documentation Output

`docs/mobile/phase-reports/phase-11-ux-hardening-report.md`: files changed, behaviors hardened, mock-data audit result, hardcoded-URL/secret audit result, logging redaction audit, accessibility/pagination/audit-test results, analyzer/test/build, known limitations, blockers, readiness for Phase 12.

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

Then STOP. Do not begin Phase 12 automatically.
