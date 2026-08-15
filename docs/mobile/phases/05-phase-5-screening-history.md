# HepaSense Mobile — Phase 5: Screening History

## 1. Objective

Implement the Screening History screen: `GET /api/v1/screenings/` paginated history, pull-to-refresh, pagination (infinite scroll / load-more), loading/empty/error/retry states, status filter UI (when Figma requires it), and navigation to Screening Detail. Never fetch the entire history at once.

## 2. Why This Phase Exists

Home shows the latest result only. Patients need their screening history in measurement-time order (PRD §28, §742). Phase 5 adds the paginated list and reuses the Phase 4 status mapping and detail navigation (Phase 6). It is gated on Phase 2 session + Phase 4 latest (to share repositories/status mapping and navigation target).

## 3. Required Reading

- `docs/mobile/00-mobile-prd.md`: §§28–29, 64, 844–891, 920–965, 1597–1628, 2345–2348.
- `docs/mobile/02-api-integration-contract.md` §3 (history list + filters).
- `docs/mobile/phases/04-phase-4-home-latest-screening.md` (status mapping, repository patterns).
- Backend `docs/backend/10-phase-4-screening-query-api.md` (page-number pagination, 20/page, filters, ordering).
- Figma History screen + status filter UI (if present).

## 4. Preconditions

- Phase 2 complete; Phase 4 complete (status mapping + ScreeningDetail route exists).
- Backend Phase 4 history endpoint COMPLETED.

## 5. Repository Audit Before Editing

- Inspect Phase 4 `ScreeningsRepository` (reuse/adapt).
- Inspect Phase 1 `StateView`, `StatusBadge`, theme.
- Inspect Phase 4 `HomeViewModel` refresh coordination pattern (reuse to avoid duplicate parallel requests — PRD §2343, §1626).

## 6. In Scope

- [x] **History list** (`GET /api/v1/screenings/`): compact item with frozen safe fields.
- [x] **Pagination**: page-number, load-more, pagination-end detection, and ID deduplication.
- [ ] **Ordering**: default newest-first by `measured_at` (Backend Phase 4 §31); respect backend ordering.
- [x] **Status filter**: truthful server-side filters for healthy/warning/high_risk/invalid.
- [ ] **States**: initial loading, pagination loading, pull-to-refresh, empty history, network error, retry, pagination end (PRD §28, §29).
- [ ] **Navigation**: tap item → Screening Detail by `id` (Phase 6) (PRD §851, §254).
- [ ] **Refresh**: pull-to-refresh; app-resume freshness (PRD §1597, §1615).
- [ ] **Reuse** centralized status mapping + `StatusBadge` (Phase 4).

## 7. Out of Scope

- Screening Detail UI (Phase 6).
- Date/measurements entry — history is read-only.
- Status filters not present in Figma (PRD §863).
- Firebase (Phase 8), Education (Phase 9).

## 8. Backend Contract

| Method | Path | Auth | Params | Response |
|---|---|---|---|---|
| GET | `/api/v1/screenings/` | JWT (MFA) | page, status={healthy\|warning\|high_risk\|invalid}, measured_from, measured_to, ordering={measured_at\|-measured_at} | paginated list (20/page), compact fields + links |

- Default order `-measured_at,-created_at,-id` (Backend Phase 4 §31).
- `status=invalid` maps to `sample_valid=false` (Backend Phase 4 §39, PRD §772); unsupported values → 400.
- History is read-only (POST/PUT/PATCH/DELETE denied) (Backend Phase 4 §13).

Compact history item (Backend Phase 4 §49): `id, screening_uid, measured_at, status, sample_valid, measurement.nh3_corrected, measurement.nh3_unit`.

## 9. Data / Domain Rules

- `invalid` ≠ classification (PRD §27, §826).
- Do not fetch unlimited history (PRD §885, §2343).
- No duplicate records during pagination (PRD §887).
- No raw/internal fields (Backend Phase 4 §74, PRD §924).
- Status mapping reused from Phase 4; color not sole communicator (PRD §59).

## 10. UI / Figma Requirements

- History list per Figma; compact item matching Phase 4 status presentation.
- Pull-to-refresh; load-more footer at pagination end.
- Empty state (no history) and error/retry (PRD §879, §1370, §1390).
- Reuse `StatusBadge`, `StateView`, theme (PRD §1529).
- SafeArea/keyboard/text-scaling (PRD §229).

## 11. State Requirements

- History: `initial | loading | success(list+pagination) | empty | error | refreshing | paginating | pagination_end`.
- Each item: status via centralized mapping.
- Retry surfaces for error + empty (where appropriate) (PRD §1370).

## 12. Architecture Requirements

- Reuse/extend `ScreeningsRepository` from Phase 4 with a paged list method.
- `HistoryViewModel` (Riverpod): owns `page`, `hasNext`, `items`, `loading/paginating/refreshing` flags; guards duplicate in-flight page requests.
- Reuse centralized `StatusMapping` and Phase 1 components.

## 13. Security & Privacy Requirements

- Auth JWT via Phase 2 interceptor.
- No PHI cached to disk (PRD §53, §1349).
- No device credentials (PRD §53, §91).
- Read-only; never send mutations to screenings (Backend Phase 4 §13).

## 14. Implementation Tasks

- [ ] Inspect Phase 4 repository + status mapping + refresh pattern.
- [ ] Implement `ScreeningsRepository.list(page, filters)` returning paginated items + next/has-next.
- [ ] Implement `HistoryViewModel` (items, page, hasNext, loading/paginating/refreshing/error/empty).
- [ ] Implement History screen UI (list, item, pull-to-refresh, load-more, empty/error/retry).
- [ ] If Figma requires, implement status filter UI (data layer already filter-compatible).
- [ ] Wire navigation: item → Screening Detail by `id`.
- [ ] Add Phase 5 report.
- [ ] Run `dart format .`, `flutter analyze`, `flutter test`.

## 15. Tests Required

- Unit: pagination parsing; `hasNext` determination; duplicate-page guard (no duplicate records).
- Unit: status filter compatibility; 400 on unsupported status value.
- Widget: History renders loading/empty/error/retry + pagination-end; pull-to-refresh.
- Integration (mock — PRD §77): list maps to compact item fields only.
- Regression: no full-history fetch; no raw/credential fields.

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

- [ ] History paginated list (20/page) with load-more + pagination-end.
- [ ] Pull-to-refresh + app-resume freshness.
- [ ] All states (loading/empty/error/refreshing/paginating) implemented and distinct (PRD §29).
- [ ] Status mapping reused; no raw/credential fields (Backend Phase 4 §49, §74).
- [ ] No duplicate records; no full-history fetch (PRD §885, §887).
- [ ] Navigation to Detail wired.
- [ ] `flutter analyze` clean; `flutter test` passes.
- [ ] `flutter build apk --debug` passes.

## 18. Stop Conditions / Blockers

- STOP if backend pagination/filter shape differs from Backend Phase 4 §31–39 — re-audit.
- STOP if the history endpoint is writable (should be read-only) — report.

## 19. Required Documentation Output

`docs/mobile/phase-reports/phase-5-screening-history-report.md`: files changed, APIs (screenings/), tests + results, analyzer/build, reuse notes, known limitations, blockers, readiness for Phase 6.

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

Then STOP. Do not begin Phase 6 automatically.
