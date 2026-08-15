# HepaSense Mobile — UI Screen Map

Visual source of truth: Figma — `https://www.figma.com/design/h9MvTHL7CoVAZ2HYh92Jp0/Untitled?node-id=0-1&t=qeEMe4iZTSquHRFv-1` (PRD §3, §6).

This map is derived from PRD §254 (screen map) and §447 (product end state). Exact visual fidelity must be confirmed against Figma during Phase 1; this document records the intended screen set and navigation relationships only. **Do not invent screens.**

## Authenticated (app) flow

```text
Splash
  → Login            (unauthenticated)
    → MFA / OTP
      → Home / Beranda
            ├─ Latest Screening card  → Screening Detail
            ├─ History shortcut       → Screening History → Screening Detail
            ├─ Notifications badge    → Notification Center
            └─ Account shortcut       → Account
                                          ├─ Profile / Edit Profile
                                          ├─ Change Password
                                          ├─ Privacy Policy
                                          ├─ Help
                                          └─ Logout
Home also offers Education / Help shortcuts → Education backend contract available (Phase 9)
```

## Screen inventory

| Screen | Phase | Auth required | Backend endpoint | Notes |
|---|---|---|---|---|
| Splash | 2 | no | none | session restoration; PRD §17 |
| Login | 2 | no | `/api/v1/auth/login/` | password toggle, validation, errors, MFA transition |
| Register | 2 | no | `/api/v1/auth/register/` | fields per contract |
| MFA / OTP Verification | 2 | no (transient) | `/api/v1/auth/2fa/login/` | challenge is sensitive; do not log |
| Patient gate / foundation | 3 | yes | `/api/v1/patients/me/` | resolving, linked, unlinked, retry; no Screening content |
| Home / Beranda | 4 | yes | `/api/v1/screenings/latest/` | greeting, linked Patient context, latest/empty/invalid/error states |
| Screening History | 5 | yes | `/api/v1/screenings/` | paginated, status filters, refresh/load-more, compact safe rows |
| Screening Detail | 6 | yes | `/api/v1/screenings/{id}/` | patient-safe fields only |
| Notification Center | 7 | yes | `/api/v1/notifications/`, `/api/v1/notifications/{id}/read/`, `/api/v1/notifications/read-all/` | list, mark read, mark all read, badge |
| Education (articles) | 9 | yes* | `/api/v1/education/articles/` | READY — backend contract available |
| Saran Gizi | 9 | yes* | `/api/v1/education/articles/?type=nutrition` | READY — general nutrition only |
| FAQ / Help | 10 | yes/no | `/api/v1/education/articles/?type=help` | READY — backend contract available |
| Account | 3 | yes | `/api/v1/accounts/profile/` | view supported fields and Patient link status |
| Edit Profile | 3 | yes | `PATCH /api/v1/accounts/profile/` | email/roles/2FA immutable |
| Change Password | 3/10 | yes | `/api/v1/accounts/change-password/` | invalidates JWT sessions |
| Privacy Policy | 10 | yes/no | static | approved content only |
| Help | 10 | yes/no | `/api/v1/education/articles/?type=help` | no fabricated contacts |

*Education/Help may be reachable from Home and/or Account.

## Navigation notes

- Do not create excessive nested navigation (PRD §305).
- Deep links from notifications only when the backend safely exposes sufficient identifiers (PRD §307). Notification output contains `screening_id` (Backend Phase 5 §69), so detail deep-link is supported.
- Logout resets protected navigation to Login; protected routes must not remain accessible after logout (PRD §12, §42, §1201).
- No "Tanya AI" screen (PRD §1286, §2250 — AI deferred/out of scope).
- No clinician dashboard in patient app (PRD §69, §144).

## States per screen (PRD §1390, §1409)

Every primary flow must provide `loading / success / empty / error / retry`:

- Home: loading, success, no-screening, unlinked-patient, network failure, session expired, server error.
- History: initial loading, pagination loading, pull-to-refresh, empty history, network error, retry, pagination end.
- Detail: loading, success, missing/null values, network/retry.
- Notifications: loading, success, empty, network error, retry, pagination (if supported).

## Pending design confirmation

- Final card arrangement and illustrations must be confirmed from Figma in Phase 1.
- If Figma cannot be accessed, use provided screenshots/assets and report missing design info (PRD §6, §225).
