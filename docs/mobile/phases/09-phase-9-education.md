# HepaSense Mobile — Phase 9 Planning Record: Education & General Nutrition

> **COMPLETED.** The executed scope and final validation are documented in `09-phase-9-education-nutrition-help.md` and the single Phase 9 report. Help/FAQ remains Phase 10 per the authoritative screen map.

## 1. Objective

Implement the Education surfaces: article list (by type: education/nutrition/help), category browsing, article detail, and featured content. Provide loading/empty/error/retry states. Render article content safely as trusted admin-authored Markdown/plain text — never as executable HTML/script. Do NOT implement personalized clinical nutrition or diet prescriptions from Screening results.

## 2. Why This Phase Exists

The app exposes Help/Supporting content (PRD §254 screen map). Backend Phase 8 provides a public, published-only, read-only Education API. Phase 9 integrates it from the verified contract. Phase 9 is reachable from Home and/or Account shortcuts and does not depend on Phase 8 (FCM).

## 3. Required Reading

- `docs/mobile/00-mobile-prd.md`: §§44–49, 1229–1313, 1250–1272 (Saran Gizi), 1274–1294 (Tanya AI deferred).
- `docs/mobile/02-api-integration-contract.md` §9 (missing/available contracts).
- Backend `docs/backend/14-phase-8-education-content.md` (verified contract — READ FIRST).
- Backend `docs/backend/15-phase-9-security-hardening.md` §125 (search >200 chars rejected; public throttling).
- Figma Education/Nutrition/Help screens (if available).

## 4. Preconditions

- Phase 7 complete (or reachable from Account/Settings). Backend Education is public read-only but mobile still authenticates per app policy; Education may be shown pre-login if product decides (currently gated behind authenticated shell for MVP consistency unless Figma dictates otherwise).
- Backend Phase 8 Education COMPLETED.

## 5. Repository Audit Before Editing

- Confirm no Education Flutter code exists yet (greenfield + Phase 0).
- Inspect Phase 1 components (list, StateView, etc.) and theme for reuse.
- Inspect `docs/mobile/03-ui-screen-map.md` Education entries.

## 6. In Scope

- [ ] **Education list** (`GET /api/v1/education/articles/`): filter by `type=education|nutrition|help`; category; featured; search (title/summary). Reuse page-number pagination (20/page), default `-published_at,-id`.
- [ ] **Categories** (`GET /api/v1/education/categories/` and `/{slug}/`): active categories with public-content counts.
- [ ] **Article detail** (`GET /api/v1/education/articles/{slug}/`): published content only; 404 for draft/archived/future/inactive.
- [ ] **Content rendering**: article body is admin-authored Markdown/plain text (Backend Phase 8 §48–51). Render via a safe Markdown renderer; **never** execute as HTML/script; **never** render raw HTML from content. Use a vetted `flutter_markdown` or plain-text path (dependency justified in report).
- [ ] **Featured content** surfaced where present (PRD §1235).
- [ ] **States**: loading, success, empty, error, retry, pagination end (PRD §1390, §2327).
- [ ] **Saran Gizi**: surfaced via `type=nutrition` — general nutrition only (PRD §1255, §1260–1268). Do NOT map `high_risk → diet X`.
- [ ] **Navigation**: list → detail; category → filtered list.
- [ ] **Reuse** Phase 1 components; markdown rendered safely.

## 7. Out of Scope

- Personalized clinical nutrition / diet prescription from Screening (PRD §1260–1268).
- Tanya AI / ChatGPT / Gemini / RAG / vector DB (PRD §1286–1294; task §16 hard boundary).
- Analytics / Crashlytics (PRD §70, §71).
- Creating/updating Education content from mobile (read-only API; Backend Phase 8 §31: POST/PUT/PATCH/DELETE → 405).
- Healthcare `/api/v1/healthcare/*` (PRD §69).
- Inventing any endpoint.

## 8. Backend Contract (verified, Backend Phase 8)

| Method | Path | Auth | Filters / Body | Response |
|---|---|---|---|---|
| GET | `/api/v1/education/articles/` | AllowAny (public) | type=education\|nutrition\|help, category=<slug>, featured=true\|false, search(title/summary, ≤200 chars) | paginated list (20/page), `-published_at,-id` |
| GET | `/api/v1/education/articles/{slug}/` | AllowAny (public) | — | article detail (content + meta) |
| GET | `/api/v1/education/categories/` | AllowAny (public) | — | active categories + public-content counts |
| GET | `/api/v1/education/categories/{slug}/` | AllowAny (public) | — | active public category detail |

List fields: `id, type, title, slug, summary, thumbnail, is_featured, read_time_minutes, published_at, category`. Detail adds `content, updated_at`. Excluded: editor identity, management state, SEO internals, view statistics, credentials, all patient/screening/biometric/notification/Firebase data (Backend Phase 8 §44–46). POST/PUT/PATCH/DELETE → 405 (Backend Phase 8 §31). Personalization parameters rejected (Backend Phase 8 §48, §125). Invalid `type`/boolean → 400. `search` >200 chars rejected (Backend Phase 9 §125).

Education is public (`AllowAny`) and contains no user or medical data (Backend Phase 8 §19). The mobile client should still render via the authenticated app shell for MVP consistency unless Figma dictates guest access.

## 9. Data / Domain Rules

- Article body is trusted admin-authored Markdown/plain text; render safely, never as executable HTML/script (Backend Phase 8 §48–51, PRD §3).
- Nutrition is general education only; no Screening-based diet prescription (PRD §1255, §1260–1268).
- No Patient/Screening/classification/NH3/confidence used for content selection (Backend Phase 8 §70–74).
- No medical diagnosis/treatment claims in content (PRD §3, §99–113).
- Read-only; no create/update/delete from mobile (Backend Phase 8 §31).

## 10. UI / Figma Requirements

- Education list/detail/category per Figma.
- Safe rendering of Markdown/plain text only (no raw HTML).
- Featured content surfaced where shown.
- Reuse Phase 1 components (PRD §1529).
- Bahasa Indonesia (PRD §5).
- SafeArea/keyboard/text-scaling (PRD §229).

## 11. State Requirements

- Article list: `initial | loading | success | empty | error | paginating | refreshing`.
- Category list: `initial | loading | success | empty | error`.
- Article detail: `loading | success | empty | error`.

## 12. Architecture Requirements

- New `EducationRepository` over the shared API client.
- `EducationListViewModel`, `ArticleDetailViewModel` (Riverpod).
- Reuse Phase 1 `StateView`/components.
- Markdown rendering via a single safe renderer (dependency justified in report).

## 13. Security & Privacy Requirements

- Content rendered as trusted Markdown/plain text only (Backend Phase 8 §48–51); never execute HTML/script.
- No medical content selection from Patient/Screening (Backend Phase 8 §70–74).
- No credentials/patient/screening data in Education output (Backend Phase 8 §44–46).
- No personalization parameters sent (Backend Phase 9 §125).
- Public read-only; no mutations attempted (Backend Phase 8 §31).

## 14. Implementation Tasks

- [ ] Inspect Backend Phase 8 report + Phase 1 components.
- [ ] Add `education` model classes (published-only fields); do not include excluded meta.
- [ ] Implement `EducationRepository` (list, categories, detail).
- [ ] Implement `EducationListViewModel` (type/category/featured/search, pagination).
- [ ] Implement `ArticleDetailViewModel`.
- [ ] Implement Education list screen + category screen + detail screen.
- [ ] Implement safe Markdown/plain-text rendering (single renderer; dependency justified).
- [ ] Implement states (loading/empty/error/retry/paginating/refreshing).
- [ ] Wire Home/Account Education shortcuts (only if Figma places them here).
- [ ] Add Phase 9 report.
- [ ] Run `dart format .`, `flutter analyze`, `flutter test`.

## 15. Tests Required

- Unit: list maps to published-only fields; excluded fields never parsed.
- Unit: invalid `type`/boolean → error mapping (400).
- Unit: detail 404 (draft/archived/future/inactive) handled.
- Widget: list/detail render loading/empty/error; Markdown renders as text, no HTML execution.
- Integration (mock boundaries — PRD §77): safe-field mapping; no personalization params sent.
- Regression: no Screening-result-driven diet logic; body never rendered as raw HTML.

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

- [ ] Education list/category/detail integrated against verified Backend Phase 8 contract.
- [ ] Safe Markdown/plain-text rendering only (no HTML/script).
- [ ] General-nutrition only; no Screening-based personalization (PRD §1255, §1260).
- [ ] Read-only; no create/update/delete attempted.
- [ ] All states implemented; pull-to-refresh where applicable.
- [ ] Markdown renderer dependency justified per task §14 format.
- [ ] `flutter analyze` clean; `flutter test` passes; `flutter build apk --debug` passes.

## 18. Stop Conditions / Blockers

- STOP if the backend Education contract changes after Backend Phase 8 — re-audit before displaying.
- STOP if content selection is driven by Screening/Patient data — reject; report.
- STOP on any backend modification.

## 19. Required Documentation Output

`docs/mobile/phase-reports/phase-9-education-report.md`: files changed, APIs (education/*), tests + results, analyzer/build, Markdown renderer dependency justification (PACKAGE/WHY/VERSION/IMPACT), assumptions (Figma), known limitations (search >200 char handling), blockers, readiness for Phase 10.

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

Then STOP. Do not begin Phase 10 automatically.
