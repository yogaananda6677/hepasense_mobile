# Phase 4 Report: Home Dashboard + Latest Screening

**Date:** 2026-08-13  
**Status:** COMPLETED

## Figma reference

- Figma file: `kIutNKXVzAlNjBkQO97ZWj`
- Home frame: `27:1309` (`Redesign / Dashboard Home`)
- MCP status: RATE LIMITED on the connected Starter plan
- Design context inspected: NO; the required design-context call was attempted first
- Domain: PLANT-CARE VISUAL REFERENCE ONLY
- HepaSense business source: frozen backend contracts plus Mobile PRD

No plant-care content, weather, AI, scanning, scores, marketplace, or fabricated metrics were copied. The known greeting → primary card → informational callout → bottom-navigation hierarchy was adapted with existing provisional HepaSense tokens; no design value is marked Figma-confirmed.

## Implementation

- Integrated only `GET /api/v1/screenings/latest/` through the shared authenticated Dio client.
- Added reusable Screening detail-domain models with exact patient-safe fields and nullable result fields.
- Decimal wire values remain strings and expose safe explicit parse helpers only where needed.
- Backend timestamps are parsed as Asia/Jakarta wall time without UTC reinterpretation and displayed with `WIB`.
- Latest 404 maps to a deliberate no-screening state; other errors remain safe and retryable.
- Home loads latest Screening only after Patient state is linked. Unlinked/unresolved Patients never trigger the Screening repository.
- Added loading, latest, no-screening, invalid-sample, and error/retry presentations.
- Reused centralized `StatusMapping` and `StatusBadge`; invalid samples never render a valid classification.
- Home shows no confidence percentage or disease-probability wording.
- Added pull-to-refresh and a constrained navigation bar exposing only implemented Beranda and Akun destinations.
- Home medical state follows the Patient provider lifecycle and is invalidated on session loss.

## Scope

No Screening History API or full Screening Detail feature was implemented. The existing detail route remains a Phase 1 navigation placeholder. Notifications, Firebase, Education, Healthcare, IoT, AI, and weather were not added. Backend and API contract files were not modified.

## Validation

- `flutter pub get`: PASS
- `dart format .`: PASS
- `flutter analyze`: PASS, 0 errors / 0 warnings / 0 info
- `flutter test`: PASS, 77 tests
- `flutter build apk --debug`: PASS
- Local Screening backend smoke: NOT EXECUTED

## Known limitations

- Figma context could not be inspected because the MCP plan limit was reached; visual tokens remain provisional.
- The Detail action targets the existing route contract, whose full content belongs to Phase 6.
- Local backend smoke was not executed; automated tests mock the API boundary.

Mobile Phase 5 is ready but was not started.
