# HepaSense Mobile — Phase 9: Education + Nutrition Guidance

Status: **COMPLETED**

## Actual scope

- Backend-backed Education browse, categories, featured presentation, supported search, pagination, refresh, empty/error/retry, and article detail.
- Backend-backed Saran Gizi using `type=nutrition`, always general and educational.
- Safe dependency-free Markdown-style/plain-text detail presentation.
- Home shortcut and existing authenticated router integration.
- Help/FAQ is **not in Phase 9** according to the authoritative screen map; it remains Phase 10.

## Contract

The source of truth is the frozen public read-only API:

- `GET /api/v1/education/articles/`
- `GET /api/v1/education/articles/{slug}/`
- `GET /api/v1/education/categories/`

Only documented filters are sent. No Patient, Screening, NH3, classification, confidence, risk, or personalization parameters exist in this implementation.

## Visual reference

- Figma file: `kIutNKXVzAlNjBkQO97ZWj`
- Node: `27:1615`
- Domain: plant-care visual reference only
- Adapted: spacing, header density, intro/rationale hierarchy, stacked card composition, radius, CTA/navigation rhythm.
- Excluded: all plant, fertilizer, product, price, rating, marketplace, shopping, and chatbot semantics.

## Safety

Nutrition is general education, not a diet prescription. No content selection uses a Screening result. HepaSense remains an early-screening support tool, not a diagnostic replacement. Article content is displayed as safe text; executable HTML is not supported.

## Validation

Phase 9 adds 16 tests to the 148-test baseline. Final analyzer, complete test-suite, and fresh debug APK results are recorded in the single Phase 9 report.
