# Mobile Phase 18 — Screening Report

The Screening Detail page exposes **Lihat / Unduh PDF**, **Bagikan**, and **Kirim ke Email** without adding a bottom-navigation destination or transition animation.

## Data flow

Flutter does not calculate report classifications, conclusions, or confidence semantics. It downloads the canonical PDF from `GET /api/v1/screenings/{id}/report/`. Email uses `POST /api/v1/screenings/{id}/email-report/` with an empty body, so an arbitrary recipient cannot be supplied.

For view/share, PDF bytes are written to the application temporary directory using only the sanitized backend filename. The previous file created in the same service session is removed when replaced. Android storage remains app-private and no broad storage permission is requested. Viewing delegates to an installed PDF-capable application; sharing delegates to the Android system share sheet through `share_plus`.

All three actions share one controller state, disable repeated taps while active, and expose safe success/network/failure feedback. Email requires confirmation that the destination is the registered account email; the address itself is not displayed.

## Runtime limitations

PDF generation requires the authenticated backend and is not generated from cached screening data. Real email is unavailable while the backend uses its local console email transport. Android share/view validation requires a connected physical device or emulator with suitable target applications installed.
