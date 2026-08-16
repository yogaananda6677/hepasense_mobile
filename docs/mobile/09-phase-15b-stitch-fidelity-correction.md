# Phase 15B — Stitch Fidelity Correction

## Explicit Google Stitch Design Tokens

The following user-provided Google Stitch output is the authoritative HepaSense mobile theme and supersedes the inferred Phase 14 navy/cyan and Plus Jakarta Sans/Inter hierarchy:

| Token | Value |
|---|---|
| Primary | `#007BFF` |
| Background | `#F7F9FB` |
| Surface | `#FFFFFF` |
| Primary text | `#1A1C1E` |
| Secondary text | `#44474E` |
| Healthy/success surface | `#E8F5E9` |
| Healthy/success foreground | `#2E7D32` |
| Font | Manrope-oriented hierarchy |

Stitch calls `#007BFF` “Primary (Teal)”; the supplied hexadecimal value is implemented unchanged even though it appears blue.

The project has no bundled Manrope assets and no existing font dependency. Phase 15B does not download arbitrary font files or introduce runtime network typography. Exact Manrope loading is therefore deferred; the app uses the platform sans fallback with Manrope-oriented weights, mobile sizes, and hierarchy.

## MCP discrepancy

The Phase 15B MCP recheck of `Modern Dashboard Home` (`5856414085740584139`) still returned the older project theme: primary `#001736`, container `#002B5B`, secondary container `#00E0FF`, Plus Jakarta Sans headings, Inter body/labels, and `ROUND_FULL`. That project metadata conflicts with the explicit corrected Stitch output supplied for this phase. Per the user's correction instruction, production mobile tokens use the explicit values above; the MCP project itself was not modified.

## Corrections applied

- Centralized colors now distinguish the `#F7F9FB` app background from white card/navigation surfaces.
- Primary controls, selected navigation, focus, and interactive icons use `#007BFF` selectively.
- Radius hierarchy is 12 px small, 16 px standard, and 20 px major; large floating shadows were replaced with subtle borders and restrained 8 px shadows.
- Healthy status uses the exact success pair while warning, high-risk, and invalid retain accessible medical semantics.
- Home is denser: compact identity header, safe “Kesehatan Anda Hari Ini” summary, latest-screening section, real supported measurements, conclusion, primary history CTA, backend-backed Tips Kesehatan when available, and a compact disclaimer.
- The no-screening state remains neutral and compact; it never implies the patient is healthy.
- Shared bottom navigation now exposes the four working top-level destinations: Beranda, Riwayat, Gizi, Akun. AI remains absent until the Flutter integration is real.
- Account and Gizi selected indices were updated to the shared four-item information architecture.

No authentication, patient linking, backend contract, medical classification, Firebase, or reporting behavior changed. Template names HaloSehat/Protokol Sehat and Nara/finance content are absent from production UI.
