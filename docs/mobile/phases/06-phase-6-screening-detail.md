# HepaSense Mobile — Phase 6: Screening Detail

## 1. Objective

Implement the Screening Detail screen: `GET /api/v1/screenings/{id}/` for the authenticated user's own linked-Patient Screening. Display measurement timestamp/date/time, sample validity, classification/status, corrected NH3 + unit, temperature, humidity, flow quality, expiration duration, and the optional classifier confidence score (with conservative, non-probabilistic copy). Handle missing/null values, network/retry state, and server-side ownership enforcement (404 for non-owned IDs).

## 2. Why This Phase Exists

History (Phase 5) navigates to detail by Screening ID. Detail surfaces the full patient-safe Screening representation from Backend Phase 4 §72. It must never display excluded internal fields (raw NH3, device metadata, credential verifier, digest, fingerprint references) and must keep confidence/score non-diagnostic.

## 3. Required Reading

- `docs/mobile/00-mobile-prd.md`: §§30–32, 64–65, 780–815, 843–965, 920–941.
- `docs/mobile/02-api-integration-contract.md` §3 (detail response shape + excluded fields).
- `docs/mobile/phases/04-phase-4-home-latest-screening.md` (status mapping, safe fields, formatting).
- Backend `docs/backend/10-phase-4-screening-query-api.md` §48–72 (detail serializer, exclusions, confidence handling, invalid representation).
- Figma Screening Detail.

## 4. Preconditions

- Phase 2 session; Phase 4 status mapping + formatting helpers; Phase 5 navigation target exists.
- Backend Phase 4 detail endpoint COMPLETED.

## 5. Repository Audit Before Editing

- Inspect Phase 4 `ScreeningsRepository` detail method (reuse/adapt).
- Inspect Phase 4 date/number formatting helpers (reuse).
- Inspect Phase 4 `StatusMapping`/`StatusBadge` (reuse — non-color status).

## 6. In Scope

- [ ] **Detail fetch** (`GET /api/v1/screenings/{id}/`): parse patient-safe fields (Backend Phase 4 §50–72).
- [ ] **Measurement timestamp**: parse ISO, display local, preserve original instant (PRD §64, §664). Distinguish measurement date vs. notification date where shown (PRD §669).
- [ ] **Sample validity + status**: `sample_valid`, `status` (invalid/healthy/warning/high_risk) via centralized mapping (PRD §27, §805, §817).
- [ ] **Invalid sample**: `sample_valid=false`, `classification=null` → dedicated invalid-measurement state with guidance (e.g., repeat screening per device procedure); do NOT manufacture healthy/warning/high_risk (PRD §817, §826, §830, §840).
- [ ] **Measurements display**: corrected NH3 + unit (ppm), temperature Celsius, humidity %, flow quality, expiration duration seconds — retain units, no false precision (PRD §65, §678).
- [ ] **Classification**: healthy/warning/high_risk labels with screening-safe (not diagnostic) copy (PRD §3, §99–113, §813).
- [ ] **Confidence score** (if present): present as a model/system score with careful terminology; never a calibrated disease probability (PRD §32, §951, §959); acceptable to omit initially.
- [ ] **Missing/null values**: render a safe placeholder rather than a null crash (Backend Phase 4 §74; confidence may be null).
- [ ] **States**: loading, success, empty/missing, network failure, session expired, server error (PRD §1390, §1373).
- [ ] **Retry** (PRD §1376).
- [ ] **Reuse** Phase 4 status mapping + components + formatting (PRD §1529).

## 7. Out of Scope

- Creating/editing Screenings (read-only API; Backend Phase 4 §13).
- Raw NH3, device metadata, credential verifier, payload digest, patient IDs, fingerprint references, JWT/TOTP (Backend Phase 4 §74, PRD §924).
- Classifying high_risk as confirmed disease (PRD §26, §813).
- Presenting confidence as probability (PRD §32, §951).
- Firebase (Phase 8), Education (Phase 9).

## 8. Backend Contract

| Method | Path | Auth | Response |
|---|---|---|---|
| GET | `/api/v1/screenings/{id}/` | JWT (MFA) | full detail (Backend Phase 4 §72) |

Detail shape:
```json
{
  "id": 15,
  "screening_uid": "...",
  "measured_at": "2026-08-12 10:15:00",
  "status": "warning",
  "sample_valid": true,
  "measurement": {
    "nh3_corrected": "0.280000",
    "nh3_unit": "ppm",
    "temperature_celsius": "34.400",
    "humidity_percent": "86.200",
    "flow_quality": "0.910000",
    "expiration_duration_seconds": "5.300"
  },
  "result": { "classification": "warning", "confidence_score": null }
}
```

- Detail lookup is inside the scoped queryset `request.user -> Patient -> Screening`; another Patient's `id` → 404 (Backend Phase 4 §17, PRD §68, §69, §858).
- 404 for another patient means access-denied/empty, not a screen rendering another patient's data.
- `confidence_score` returned as stored; never described as probability (PRD §32, §951).
- Machine auth cannot read (Backend Phase 4 §17).

## 9. Data / Domain Rules

- `invalid` (sample_valid=false, classification=null) ≠ healthy/warning/high_risk (PRD §27, §826).
- `high_risk` ≠ confirmed disease (PRD §26, §813).
- `confidence_score` ≠ calibrated probability (PRD §32, §951).
- `measured_at` displayed local; original instant preserved (PRD §664, §678).
- No raw/internal fields (Backend Phase 4 §74, PRD §924).
- Ownership server-enforced; mobile must not send arbitrary `patient_id`/`user_id` to access other records (PRD §68, §741).

## 10. UI / Figma Requirements

- Detail screen per Figma; measurement block, status badge, validity, guidance copy.
- Reuse `StatusBadge`, `StateView`, formatting (Phase 4).
- Medically conservative copy (PRD §3, §99–113).
- SafeArea/keyboard/text-scaling (PRD §229).

## 11. State Requirements

- Detail: `initial | loading | success | empty | error | session_expired`.
- Confidence null handled (not a crash).
- Retry surfaces on error (PRD §1376).

## 12. Architecture Requirements

- Reuse/adapt `ScreeningsRepository.detail(id)` from Phase 4.
- Reuse Phase 4 date/number formatting + `StatusMapping`.
- `ScreeningDetailViewModel` (Riverpod) holds the fetched Screening; single in-flight fetch guard (no duplicate requests — PRD §92, §2343).
- Route: `/screenings/{id}` from Phase 4 router (Phase 5 navigates here).

## 13. Security & Privacy Requirements

- JWT (MFA-enforcing) via Phase 2 interceptor; machine auth rejected by backend.
- No raw/credential/digest/fingerprint fields displayed or requested (Backend Phase 4 §74, PRD §924, §56).
- No PHI cached to disk beyond tokens (PRD §53, §1349).
- No device credentials in Flutter (PRD §53, §91).

## 14. Implementation Tasks

- [ ] Inspect Phase 4 `ScreeningsRepository.detail`, status mapping, formatting.
- [ ] Implement/adjust `ScreeningsRepository.detail(id)`; parse safe fields; map 404 (non-owned) to empty/access-denied.
- [ ] Implement `ScreeningDetailViewModel` (single in-flight fetch guard).
- [ ] Implement Detail screen UI: measured-at, validity, status badge, measurements + units, classification, optional confidence (conservative copy), invalid guidance.
- [ ] Implement states (loading/success/empty/error/session-expired) + retry.
- [ ] Reuse Phase 4 components; ensure no raw/credential fields.
- [ ] Add Phase 6 report.
- [ ] Run `dart format .`, `flutter analyze`, `flutter test`.

## 15. Tests Required

- Unit: detail response maps to safe fields; raw/credential/digest/fingerprint fields absent from parsing.
- Unit: 404 (non-owned) → empty/access-denied state, not another patient's data.
- Unit: `sample_valid=false` → invalid state; no classification manufactured.
- Widget: Detail renders loading/success/empty/error; invalid-sample guidance shown.
- Integration (mock — PRD §77): confidence null handled; no probability labeling.
- Regression: high_risk copy is "Risiko Tinggi"/screening language, never "confirmed disease".

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

- [ ] Detail renders patient-safe fields only (Backend Phase 4 §50–72, §74).
- [ ] Invalid sample → dedicated invalid state; no classification manufactured (PRD §817, §826).
- [ ] Status non-diagnostic; confidence not a probability (PRD §26, §32, §813, §951).
- [ ] Measurements retain units; no false precision (PRD §64, §65, §678).
- [ ] All states + retry; 404 handled as access-denied/empty (Backend Phase 4 §17, PRD §768).
- [ ] Reuses Phase 4 mapping/components; no raw/credential fields (PRD §924).
- [ ] `flutter analyze` clean; `flutter test` passes.
- [ ] `flutter build apk --debug` passes.

## 18. Stop Conditions / Blockers

- STOP if backend detail serializer changes to include a previously-excluded raw/internal field — re-audit before displaying.
- STOP if confidence is re-described as a probability by backend — do not relabel locally; report.

## 19. Required Documentation Output

`docs/mobile/phase-reports/phase-6-screening-detail-report.md`: files changed, API (screenings/{id}/), tests + results, analyzer/build, reuse of Phase 4 mapping, known limitations, blockers, readiness for Phase 7.

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

Then STOP. Do not begin Phase 7 automatically.
