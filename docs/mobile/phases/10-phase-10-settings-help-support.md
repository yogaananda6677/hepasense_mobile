# HepaSense Mobile — Phase 10 Planning Record: Account & Support

## 1. Objective

Completed supporting surfaces: the Account hub reuses Phase 3 profile/edit state; password change is implemented here from the frozen contract; Help is backend-backed; Privacy and app information are conservative static content; Logout reuses the existing lifecycle. The executed scope is recorded in `10-phase-10-settings-account.md` and the single Phase 10 report.

## 2. Why This Phase Exists

After the core authenticated flows, the app needs a complete, consistent Account/Help/Privacy shell. Phase 10 reuses profile/logout contracts and the completed Phase 9 Education repository for `type=help`.

## 3. Required Reading

- `docs/mobile/00-mobile-prd.md`: §§41–49, 615–727, 1298–1354, 944–965, 2243–2281.
- `docs/mobile/phases/03-phase-3-patient-profile.md` (profile, change-password, logout already implemented).
- `docs/mobile/phases/07-phase-7-notifications.md` (Help/Privacy entry may live on Home/Account).
- Backend `docs/backend/06-phase-1-auth-implementation.md` (profile/logout contract).

## 4. Preconditions

- Phases 2, 3 complete (auth session, profile, change-password, logout).
- Home/Notifications functional (Phase 4, 7) so Account/Help can be navigated.

## 5. Repository Audit Before Editing

- Inspect Phase 3 Account/Profile/Edit/Change Password screens and reuse/adjust (do not rebuild).
- Inspect Phase 1 components for settings list items.
- Inspect any existing static assets (none — greenfield).

## 6. In Scope

- [ ] **Account screen completion**: ensure Profile / Edit Profile / Change Password / Logout entries exist and are consistent with Phase 3 (reuse).
- [ ] **Help screen**: static or backend-approved content — common questions, how screening works, how to interpret app states, contact/support guidance. **No fabricated production support contacts** (PRD §1298, §1329).
- [ ] **Privacy Policy screen**: approved content only; must accurately reflect implemented behavior; do not claim "data is never stored", "fully anonymous", or specific compliance certification (PRD §1317, §1321–1330).
- [ ] **App information**: app name/version/build (from package_info or `pubspec` version), not medical claims.
- [ ] **Logout** action wired from Account (reuse Phase 2/3 logout).
- [ ] **Report-by-email**: **DEFERRED** unless a backend mail contract is later approved (PRD §1334–1354). Do not invent a backend mail endpoint. If implemented later, confirm open-email-client vs. backend-generated (PRD §1340–1343).
- [ ] Consistent `loading/empty/error/retry` on Help/Privacy where content loads (PRD §1390, §2327).

## 7. Out of Scope

- Education / Nutrition / FAQ dynamic backend (Phase 9, blocked).
- Analytics / Crashlytics (PRD §70, §71, §2263).
- AI / Tanya AI (PRD §1286, §1294; task §16 hard boundary).
- Maps / location tracking / payments / social login / biometrics / phone-auth (PRD §90, §1254, task §16).
- Creating any new backend endpoint.

## 8. Backend Contract

Phase 10 reuses already-implemented (Phase 1/3) contracts only:

- `GET|PATCH /api/v1/accounts/profile/` (Backend Phase 1 §72)
- `POST /api/v1/accounts/change-password/` (Backend Phase 1 §73)
- `POST /api/v1/auth/logout/` (Backend Phase 1 §74)

Help/Privacy content is static or backend-approved. Report-by-email has **no** backend contract (PRD §1334–1354) → deferred. No new endpoints.

## 9. Data / Domain Rules

- Static content must be medically conservative (PRD §3, §99–113).
- Help must not fabricate support contacts (PRD §1329, §1298).
- Privacy must reflect implemented behavior (PRD §1317, §1321–1330).
- Logout resets protected navigation to Login; protected routes inaccessible after logout (PRD §12, §42, §395).

## 10. UI / Figma Requirements

- Settings/Account list per Figma.
- Help/Privacy app bars + content per Figma.
- Reuse Phase 1 components (PRD §1529).
- SafeArea/keyboard/text-scaling (PRD §229).

## 11. State Requirements

- Settings screen: `ready | error`.
- Help/Privacy: `loading | success | error` if content loads.
- Logout: `idle | performing | completed`.

## 12. Architecture Requirements

- Reuse Phase 3 Profile/Account screens; Phase 2 logout.
- New `SettingsViewModel` (Riverpod) for app info + static content loading (if any).
- Reuse `StateView` for loading/empty/error.

## 13. Security & Privacy Requirements

- No secrets in settings/about (PRD §91, §2285).
- Logout clears tokens + sensitive in-memory data (Phase 2/3).
- Static content reviewed; no medical-diagnosis claims (PRD §3, §99).
- Privacy wording accurate (PRD §1317, §1321–1330).

## 14. Implementation Tasks

- [ ] Inspect Phase 3 Account/Profile/Edit/Change Password; confirm/logout wires.
- [ ] Confirm/reuse Phase 2 logout.
- [ ] Implement Help screen (static/backend-approved content; no fabricated contacts).
- [ ] Implement Privacy Policy screen (accurate, conservative).
- [ ] Implement App Information screen (name/version/build; no medical claims).
- [ ] Wire Settings/Account list entries + navigation.
- [ ] Document report-by-email as deferred (no backend contract).
- [ ] Add Phase 10 report.
- [ ] Run `dart format .`, `flutter analyze`, `flutter test`.

## 15. Tests Required

- Widget: Account/Settings list shows expected entries + logout.
- Widget: Help renders static content; no fabricated contact injected.
- Widget: Privacy screen renders (content present).
- Widget: logout clears session and navigates to Login (mock boundary).
- Regression: no Education/AI/analytics endpoints or packages added.

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

- [ ] Account/Settings/Help/Privacy/App-Info screens present and consistent with Phase 3.
- [ ] Help uses only approved/static content; no fabricated contacts (PRD §1329).
- [ ] Privacy reflects implemented behavior (PRD §1317, §1321).
- [ ] Logout reuses Phase 2/3 and resets navigation.
- [ ] Report-by-email explicitly documented as deferred (no invented endpoint).
- [ ] No Education/AI/analytics/Firebase added here (Phases 8/9).
- [ ] `flutter analyze` clean; `flutter test` passes; `flutter build apk --debug` passes.

## 18. Stop Conditions / Blockers

- STOP if a help/privacy content contract is missing — use static placeholders only and report; never fabricate.
- STOP on any backend modification.

## 19. Required Documentation Output

`docs/mobile/phase-reports/phase-10-settings-support-report.md`: files changed, APIs reused (profile/change-password/logout), tests + results, analyzer/build, help/privacy content source, report-by-email deferral note, known limitations, blockers, readiness for Phase 11.

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

Then STOP. Do not begin Phase 11 automatically.
