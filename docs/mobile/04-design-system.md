# HepaSense Mobile — Design System (Phase 1)

> **Phase 1 implemented.** Design tokens provisionally based on Material 3 defaults. Figma extraction deferred — exact values to be confirmed from Figma in a follow-up.

## Visual source of truth

Figma: `https://www.figma.com/design/h9MvTHL7CoVAZ2HYh92Jp0/Untitled?node-id=0-1&t=qeEMe4iZTSquHRFv-1` (PRD §3, §6).

## Figma access status

**FIGMA ACCESS:** NOT AVAILABLE (no MCP server configured).

**FIGMA EXTRACTION:** BLOCKED — tokens are provisional Material 3 defaults. Exact values to be confirmed from Figma in a follow-up pass.

Phase 4 reference file `kIutNKXVzAlNjBkQO97ZWj`, frame `27:1309`, was rate-limited by Figma MCP. Its plant-care domain is not HepaSense product truth. Only the known Home hierarchy was used; all token values remain PROVISIONAL.

Phase 5 History reference frame `27:1470` was also rate-limited. The known 20px content margin, compact row hierarchy, subtle border, chip area, and bottom-navigation proportions informed the responsive layout, but remain PROVISIONAL rather than Figma-confirmed.

Phase 6 Screening Detail frame `27:1400` was rate-limited by the Figma Starter plan. The implementation reuses the established cards, status badge, 20px margin, measurement hierarchy, responsive wrapping, and bottom navigation; strict frame parity remains PROVISIONAL.

## Tokens (confirmed in Phase 1)

### Colors

| Token | Purpose | Phase 1 Value | Status |
|---|---|---|---|
| primary / onPrimary | brand / text on brand | #1B7A3D / #FFFFFF | PROVISIONAL |
| secondary / onSecondary | secondary actions | #4F6354 / #FFFFFF | PROVISIONAL |
| tertiary / onTertiary | tertiary | #3A656E / #FFFFFF | PROVISIONAL |
| error / onError | errors | #BA1A1A / #FFFFFF | PROVISIONAL |
| surface / onSurface | screen / card background | #F8FBF5 / #1A1C19 | PROVISIONAL |
| surfaceContainer | card background | #ECF0E6 | PROVISIONAL |
| outline / outlineVariant | borders/dividers | #727970 / #C2C9BE | PROVISIONAL |

### Status colors (PRD §59, §26)

Color is support, never the sole communicator of status (PRD §59).

| Status | Color token | Icon | Badge text (ID) | Status |
|---|---|---|---|---|
| healthy | status.healthy #1B7A3D | check_circle | Hasil Skrining Baik | PROVISIONAL |
| warning | status.warning #E8A317 | warning | Waspada | PROVISIONAL |
| high_risk | status.highRisk #BA1A1A | error | Risiko Tinggi | PROVISIONAL |
| invalid | status.invalid #727970 | help_outline | Pemeriksaan Tidak Valid | PROVISIONAL |

### Typography

| Token | Role | Phase 1 Value | Status |
|---|---|---|---|
| displayLarge | screen titles | Roboto 57px w400 | PROVISIONAL |
| headlineMedium | card titles | Roboto 28px w400 | PROVISIONAL |
| titleLarge | list item titles | Roboto 22px w500 | PROVISIONAL |
| bodyLarge / bodyMedium | body copy, messages | Roboto 16/14px w400 | PROVISIONAL |
| labelLarge | form labels | Roboto 14px w500 | PROVISIONAL |

CUSTOM FONT: PENDING FIGMA/ASSET VERIFICATION. Using system Roboto for now.

### Spacing & layout (PRD §229, §719)

| Token | Value | Status |
|---|---|---|
| xs | 4.0 | PROVISIONAL |
| sm | 8.0 | PROVISIONAL |
| md | 16.0 | PROVISIONAL |
| lg | 24.0 | PROVISIONAL |
| xl | 32.0 | PROVISIONAL |

### Border radius

| Token | Value | Status |
|---|---|---|
| sm | 4.0 | PROVISIONAL |
| md | 8.0 | PROVISIONAL |
| lg | 12.0 | PROVISIONAL |
| xl | 16.0 | PROVISIONAL |

Touch-target sizes (>=48dp) confirmed: AppButton minimum height 48dp (PRD §248).

## Reusable components (PRD §1537)

| Component | File | Phase 1 Status | Notes |
|---|---|---|---|
| AppButton | `core/widgets/app_button.dart` | IMPLEMENTED | primary/secondary/outline, loading/disabled |
| AppTextField | `core/widgets/app_text_field.dart` | IMPLEMENTED | label/hint/error/obscureText/password-toggle |
| AppAppBar | `core/widgets/app_bar.dart` | IMPLEMENTED | title/back button/actions |
| StateView | `core/widgets/state_view.dart` | IMPLEMENTED | loading/empty/error/retry |
| StatusBadge | `core/widgets/status_badge.dart` | IMPLEMENTED | 4 statuses with text+icon |
| SectionHeader | `core/widgets/section_header.dart` | IMPLEMENTED | title + optional action |

Feature-specific components (ScreeningCard, NotificationItem, etc.) belong to their respective phases.

Phase 7 implements compact notification cards with the established 20px list
margin, 12px radius, semantic icon hierarchy, and flexible row height. Unread
state uses bold title, a textual accessibility label, indicator dot, and border
emphasis rather than color alone. The targeted Figma MCP attempt was rate
limited, so strict frame parity remains provisional.

## Responsive & accessibility (PRD §229, §60)

- SafeArea, status bar, navigation bar, keyboard, small-phone heights, text scaling (PRD §229).
- Semantic labels for important controls; sufficient contrast; large touch targets (PRD §59, §1584).
- Touch targets >= 48dp (PRD §248) enforced via AppButton min height.
- Icons representing health status always have accompanying text (PRD §1593) — StatusBadge never uses color alone.

## Design-system rules

- Do not recreate identical components (PRD §1529).
- Avoid premature abstraction for components used only once (PRD §1550).
- Colors must not be the only communicator of medical status (PRD §59) — StatusBadge always pairs color with text+icon.
- Do not redesign screens simply because an alternative UI seems useful (PRD §223).

## Environment strategy

Compile-time `--dart-define` for `APP_ENV` and `API_BASE_URL`:

```bash
flutter run --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://...
```

No `.env` files. No dotenv package. No hardcoded URLs in feature code.

## Application ID status

ANDROID APPLICATION ID: TEMPORARY — MUST BE FINALIZED BEFORE FIREBASE PHASE 8.

Android application ID and namespace are finalized as
`com.yogaananda.hepasense`. Firebase registration has not yet been executed.
