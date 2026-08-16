# Phase 14 — Stitch Design Alignment and Feature Gap Audit

## Source and guardrails

- Stitch project: **Modern Dashboard Home** (`5856414085740584139`), inspected read-only through Stitch MCP.
- Design system asset: **Neo-Minimalist Financial Ecosystem**.
- Functional truth: current Flutter routes/repositories plus the existing Django API contract.
- No backend, API contract, Firebase configuration, or dependency changes were made.
- Financial/Nara content was not copied. Charts, balances, AI controls, and other unsupported interactions were omitted.

## Design-system mapping

| Stitch concept | HepaSense mapping |
|---|---|
| `#f7f9fb` background | App scaffold and primary background |
| `#001736` / `#002b5b` | Brand structure, primary actions, emphasized cards |
| `#006877` / restrained `#00e0ff` | Secondary actions, active navigation indication, focus |
| `#97f5cf` | Supporting accent only |
| Plus Jakarta Sans + Inter | System-safe fallback with the same weight/size hierarchy; no font download or dependency |
| 8 px rhythm, 16 px gutters, 24 px content | Existing spacing tokens retained and applied consistently |
| 24–32 px rounded modules | Central radii and `AppCard` |
| Glass surfaces | Opaque/translucent light surfaces with low-cost ambient shadows; heavy blur intentionally omitted |
| Glass bottom bar | One shared `AppBottomNavigation`, thin icons, active teal dot |

Medical colors remain separate: healthy green, warning amber, high-risk red, and invalid neutral gray. Brand cyan is never used as a disease-risk indicator.

## Screen inventory and design audit

| Screen | Route | Functional source | Visual | Layout | Component | Phase 14 result |
|---|---|---|---|---|---|---|
| Splash | `/splash` | Auth bootstrap | MEDIUM | MEDIUM | MEDIUM | Theme-aligned; native splash unchanged |
| Login | `/login` | Auth API + MFA state | HIGH | HIGH | HIGH | Form placed on shared rounded surface; behavior retained |
| Register | `/register` | Registration API | HIGH | HIGH | HIGH | Shared form surface; payload and validation retained |
| MFA | `/mfa` | MFA verify API | MEDIUM | MEDIUM | HIGH | Shared global theme; flow unchanged |
| Home | `/` | patient + latest screening APIs | HIGH | HIGH | HIGH | Strong identity/status hierarchy, emphasized result, shared cards |
| Notifications | `/notifications` | notification API | MEDIUM | MEDIUM | HIGH | Shared theme; existing behavior retained |
| History | `/screenings` | paginated screening API | HIGH | HIGH | HIGH | Rounded shared result cards; filters/pagination retained |
| Screening Detail | `/screenings/:id` | screening detail API | HIGH | HIGH | HIGH | Emphasized classification and grouped measurements; safety copy retained |
| Education/Nutrition | `/education` | education API | HIGH | HIGH | HIGH | Search/filter/list preserved with shared article cards |
| Article Detail | `/education/:slug` | education detail API | MEDIUM | MEDIUM | HIGH | Shared theme; safe article renderer retained |
| Account | `/account` | profile + patient APIs | HIGH | HIGH | HIGH | Emphasized profile and grouped settings cards |
| Edit Profile | `/account/edit-profile` | profile API | MEDIUM | MEDIUM | HIGH | Shared form/theme |
| Change Password | `/account/change-password` | password API | MEDIUM | MEDIUM | HIGH | Shared form/theme |
| Privacy | `/privacy` | local product copy | MEDIUM | MEDIUM | HIGH | Shared theme |
| Help | `/help` | local + education content | MEDIUM | MEDIUM | HIGH | Shared theme |
| About | `/about` | local product copy | MEDIUM | MEDIUM | HIGH | Shared theme |
| Unlinked Patient | Home gate | patient-profile API state | HIGH | HIGH | HIGH | Safe explanation, `Coba Lagi`, and logout retained |

Before Phase 14 the main mismatches were green brand colors, Roboto hierarchy, 8–16 px corners, default navigation indicators, thin bordered cards, and inconsistent page emphasis. Global tokens and shared surfaces address those mismatches without changing domain behavior.

## Feature-gap matrix

| Feature | Current mobile | Backend support | Design present | Status | Next action |
|---|---|---|---|---|---|
| Splash | Auth bootstrap/loading | N/A | In-app | IMPLEMENTED | Optional native-brand asset phase |
| Login | Email/password + errors | Yes | Yes | IMPLEMENTED | Runtime regression review |
| Register | Patient self-registration | Yes | Yes | IMPLEMENTED | Runtime regression review |
| MFA | Challenge verification | Yes | Yes | IMPLEMENTED | Runtime regression review |
| Home | Identity + latest result + education link | Yes | Yes | IMPLEMENTED | Runtime visual review |
| Patient Link | Read-only linked/unlinked state; retry | Operator-managed linking | Yes | IMPLEMENTED | Keep no-auto-claim policy |
| History | Filter, pagination, refresh | Yes | Yes | IMPLEMENTED | Runtime visual review |
| Screening Detail | Classification, validity, measurements | Yes | Yes | IMPLEMENTED | Runtime visual review |
| Nutrition/Education | Search, categories, pagination, detail | Yes | Yes | IMPLEMENTED | Runtime content review |
| Notifications | In-app list/read/unread and push-device adapter | Yes | Yes | IMPLEMENTED | Validate real-device FCM delivery |
| AI Chat | No route/repository/UI | No contract found | Stitch reference only | MISSING — BACKEND REQUIRED | Define safety-governed backend contract |
| AI History | None | No contract found | Reference only | MISSING — BACKEND REQUIRED | Design retention/privacy contract first |
| Voice AI | None | No contract found | Stitch reference only | MISSING — BACKEND REQUIRED | Defer until safe text AI is proven |
| Profile | View profile and patient-link state | Yes | Yes | IMPLEMENTED | Runtime visual review |
| Edit Profile | Supported profile fields | Yes | Yes | IMPLEMENTED | Preserve server validation |
| Password | Change password | Yes | Yes | IMPLEMENTED | Preserve secure-session behavior |
| Privacy | Product privacy guidance | No dedicated endpoint required | Yes | IMPLEMENTED | Legal/content review before release |
| Help | Help and education links | Partial/content-backed | Yes | IMPLEMENTED | Add support channel only with approved contract |
| About | App information | Not required | Yes | IMPLEMENTED | Maintain release metadata |
| PDF Report | No control or repository | No report endpoint found | No | MISSING | Define signed, privacy-safe report API if required |
| Email Report | No control or repository | General SMTP is not a report contract | No | MISSING | Define consent, recipient, and audit contract |
| Share Report | No control or repository | No export/share artifact | No | MISSING | Implement only after report contract exists |

## Notification and AI status

The app contains Firebase Core, Messaging, and Installations integration, device registration, foreground/opened/initial signal handling, authenticated notification-list refresh, and notification tap routing. The backend contains notification persistence, push-device registration, delivery outbox processing, and a Firebase provider. Real FCM delivery was not executed in Phase 14 and is not claimed.

No AI route, Flutter repository, mobile API call, or backend AI/chat endpoint was found. AI chat, history, and voice are therefore backend-blocked. No local fake chatbot and no client-side model key were added.

## Intentional differences from Stitch

- Healthcare hierarchy and safe explanatory copy take precedence over financial dashboard density.
- No percentage, trend, chart, or confidence visualization is presented as disease probability.
- Heavy full-screen blur, continuous glow, and decorative animation are omitted for performance and clarity.
- The navigation exposes only working destinations: Beranda, Riwayat, and Akun. Education remains a working Home action; AI has no dead tab.
- Exact fonts were not bundled because the project has no matching font assets and this phase forbids unnecessary font dependencies.

## Recommended next phases

1. **Phase 15:** real-device visual/accessibility regression review at 360×800, 390×844, 412×915 and large text; address only observed supported-UX gaps.
2. **Phase 16:** design a medically safe AI backend contract, privacy model, refusal/escalation rules, logging policy, and evaluation plan.
3. **Phase 17:** implement Flutter AI chat only after the backend contract and safety acceptance tests exist.
4. **Phase 18:** execute real FCM delivery/tap lifecycle on physical Android and decide whether privacy-safe reporting is a required product capability.

## Validation notes

- Static tests include centralized theme loading, shared card/navigation, selected navigation state, redesigned screen adoption, preserved medical copy, unlinked retry behavior, auth wiring, and prohibited Nara/business labels.
- Runtime visual review must be recorded as not executed unless a connected Android device is available and the actual build is exercised.
