# HepaSense Mobile — Phase 12: Testing, Security, Performance & Production Readiness

## 1. Objective

Achieve full mobile MVP production readiness: full analyzer cleanup, unit/widget/critical integration tests for every PRD-required scenario, authentication & MFA regression, token-refresh regression, Patient-state regression, screening regression, notification regression, secure-storage review, logging/redaction audit, hardcoded-secret/hardcoded-URL audit, Android release-compatible configuration review, dependency review, final API-contract verification, final Figma consistency review, and a final MVP verdict.

## 2. Why This Phase Exists

Phases 1–11 deliver features and hardening. Phase 12 is the gate that certifies the MVP is production-ready (PRD §74, §79, §958–959). It is verification-focused; avoid major new features.

## 3. Required Reading

- `docs/mobile/00-mobile-prd.md`: §§72–77, 79–80, 91–95, 139–142, 1501–1525, 2285–2337, 2365–2389.
- `docs/mobile/02-api-integration-contract.md`.
- `docs/mobile/phases/11-phase-11-ux-hardening.md`.
- All prior phase reports.
- Backend reports Phase 1/2/4/5/7 (final contract verification).

## 4. Preconditions

- Phases 1–11 complete; `flutter analyze` clean; tests green from Phase 11.

## 5. Repository Audit Before Editing

- Audit dependency list (`pubspec.yaml`) for unused/obsolete deps, Firebase packages introduced only in Phase 8 (PRD §523, §70, §71).
- Audit `android/` for release config (signing, minification, proguard rules for sensitive classes — but do NOT commit keystores) (PRD §79, §2301).
- Audit `assets/` for fonts/images; confirm none contain secrets (PRD §91).
- Audit `lib/` for any remaining hardcoded host/secret/URL (PRD §15, §91, §2285).
- Audit logging calls for sensitive data (PRD §54, §1461–1469).
- Audit tests for production credentials (PRD §77, §1924).

## 6. In Scope

- [ ] **Analyzer cleanup**: ensure `flutter analyze` is fully clean; no global suppression (PRD §78, §935).
- [ ] **Full test suite** for PRD-required scenarios (PRD §72–76):
  - Auth: successful login; failed login; MFA-required; invalid MFA; successful MFA; session restoration; access-token expiry + successful refresh; refresh failure → logout; password change invalidates session; logout clears auth (PRD §73).
  - Patient: linked Patient loads; User-without-Patient → safe UI; no self-link behavior (PRD §74).
  - Screening: latest success; no screening; history success; history empty; history pagination; history refresh; healthy; warning; high-risk; invalid sample; detail failure; network failure (PRD §75).
  - Notifications: list loads; empty list; unread count; mark one read; mark all read; cross-screen badge refresh; pagination; network error; push-received without auto-read (PRD §76, once push implemented).
- [ ] **Secure-storage review**: tokens/challenge/fid_hint stored; nothing sensitive in plaintext prefs (PRD §53, §1432).
- [ ] **Logging/redaction audit**: no password/token/TOTP/FID/device-secret/patient-private/raw-fingerprint in logs (PRD §54, §1055–1063).
- [ ] **Hardcoded secret audit**: no Django SECRET_KEY, DB password, Firebase service-account JSON, device secret, LLM key, API key in repo (PRD §91, §2285–2301, §1498).
- [ ] **Hardcoded URL audit**: no `localhost`/private-IP/production-secret in UI/domain code (PRD §15, §16, §471–479).
- [ ] **Android build validation**: debug build PASS (Phase 1–11); release-compatible config reviewed (PRD §79, §946–955). Do NOT commit keystores (PRD §907 deferred to Phase 12, §930).
- [ ] **Performance review**: no unnecessary rebuilds; no duplicate API requests; no loading entire history at once; images optimized; no blocking UI work (PRD §92, §106, §2308–2316).
- [ ] **Dependency review**: justify every package; no unrelated upgrades; FlutterFire only in Phase 8 (PRD §1502, §1516, task §14).
- [ ] **Final API-contract verification**: re-verify each used endpoint against Backend Phase 1/2/4/5/7 reports; no invented endpoints (PRD §14, §437, §86, §2162, §2285).
- [ ] **Final Figma consistency review**: confirm screens match Figma; report gaps (PRD §6, §87, §223).
- [ ] **Final verdict**: MOBILE MVP READY: YES / NO (PRD §944).

## 7. Out of Scope

- New product features.
- Backend modification (PRD §86, §2162).
- iOS completion unless separately requested (PRD §79).

## 8. Backend Contract

No new endpoints. Final verification only: re-confirm each endpoint used is in a COMPLETED backend phase report (Phase 1 auth/profile/password/logout; Phase 2 patients/me; Phase 4 screenings; Phase 5 notifications; Phase 7 push-devices if Phase 8 done). Mark any missing → `MISSING BACKEND CONTRACT` (PRD §2162).

## 9. Data / Domain Rules

Same medical-safety rules; verified in tests (PRD §3, §26, §27, §32, §59, §780, §826, §840, §924, §1335).

## 10. UI / Figma Requirements

- Final consistency pass against Figma (PRD §6, §223).
- All loading/empty/error/retry UI present (PRD §36–65).

## 11. State Requirements

- Every screen tested across its states (PRD §365).

## 12. Architecture Requirements

- Reuse established architecture (no rewrite — PRD §317, task §13).
- Tests use mock/fake boundaries; no live production backend; no production credentials in tests (PRD §77, §72, §1910).

## 13. Security & Privacy Requirements

- Full secure-storage review (PRD §18, §53, §1349).
- Full logging/redaction audit (PRD §54, §1055–1063, §1461–1469).
- Hardcoded secret + URL audit (PRD §15, §91, §2285).
- No secrets in repo (PRD §91, §2285–2301, §1498).
- Android release config reviewed, keystores not committed (PRD §79, §907, §930).

## 14. Implementation Tasks

- [ ] Audit deps + `android/` + `assets/` + `lib/` + logging for secrets/URLs.
- [ ] Write/complete unit tests for all auth/MFA/token-refresh scenarios.
- [ ] Write/complete unit tests for Patient linkage states.
- [ ] Write/complete unit tests for screening latest/history/detail + invalid sample.
- [ ] Write/complete unit tests for notification read/unread/pagination.
- [ ] Write widget tests for all screens × states.
- [ ] Write critical integration tests (mock boundaries) — no live backend (PRD §77).
- [ ] Run secure-storage review.
- [ ] Run logging/redaction audit.
- [ ] Run hardcoded-secret + hardcoded-URL audit.
- [ ] Run Android release config review (no committed keystores).
- [ ] Run performance review (rebuilds, duplicates, history size, images, blocking work).
- [ ] Run dependency review (justify packages; FlutterFire only Phase 8).
- [ ] Run final API-contract verification against backend reports.
- [ ] Run final Figma consistency review.
- [ ] Produce final verdict document: MOBILE MVP READY YES/NO.
- [ ] Run `dart format .`, `flutter analyze`, `flutter test`, `flutter build apk --debug`, `flutter build apk --release` (config reviewed; signing deferred if no keystore — note in report).

## 15. Tests Required

All scenarios in Phase 12 §6, mapped to PRD §73–76. At minimum:

- Auth: login success/fail/MFA-required/invalid-MFA/success-MFA/session-restore/expiry+refresh/refresh-fail→logout/password-change-invalidates/logout-clears.
- Patient: linked loads; unlinked safe UI; no self-link.
- Screening: latest success; no screening; history success/empty/pagination/refresh; healthy/warning/high-risk/invalid; detail failure; network failure.
- Notifications: list/empty/unread-count/mark-one/mark-all/cross-screen-badge/pagination/error/push-without-auto-read.
- Error mapping: all backend codes → domain messages (PRD §50).
- No secrets in logs; no hardcoded secrets/URLs.

## 16. Validation Commands

```bash
cd /home/yoga/Data/TFS/hepasense_mobile
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release   # config review; signing deferred if no keystore
```

## 17. Definition of Done

- [ ] `flutter analyze` fully clean (no global suppression).
- [ ] `flutter test` passes for the full PRD-required scenario matrix.
- [ ] Secure-storage, logging, hardcoded-secret, hardcoded-URL audits complete (report).
- [ ] Android release config reviewed; keystores not committed.
- [ ] Dependency review complete (every package justified; Firebase only Phase 8).
- [ ] Final API-contract verification: no invented endpoints; all used endpoints in COMPLETED backend reports.
- [ ] Final Figma consistency review (report gaps).
- [ ] MVP verdict documented: MOBILE MVP READY YES/NO with blockers (PRD §2389).
- [ ] Phase 12 report written.

## 18. Stop Conditions / Blockers

- STOP if a required test scenario cannot be satisfied without inventing a backend endpoint — report `MISSING BACKEND CONTRACT`, mark NO.
- STOP if a hardcoded secret is found in repo — report immediately; do not ship.
- STOP if `flutter analyze`/`flutter test` cannot be made green without global suppression (PRD §78, §935).
- STOP if Phase 8/9 status changed (re-evaluate MVP readiness: FCM is required for MVP per PRD §2378).

## 19. Required Documentation Output

`docs/mobile/phase-reports/phase-12-production-readiness-report.md`: files changed, test matrix results, analyzer/build results, secure-storage/logging/secret/URL audit results, dependency review, final API-contract verification, Figma review, performance review, final MVP verdict (READY YES/NO) with blockers.

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

Then STOP. This is the final phase; the final response also carries the overall MOBILE MVP READY verdict.
