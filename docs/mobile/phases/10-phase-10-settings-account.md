# HepaSense Mobile — Phase 10: Account + Password + Privacy + Help

Status: **COMPLETED**

## Actual scope

- Cohesive Account hub using existing Phase 3 profile, patient-link state, and Edit Profile.
- Password change through `POST /api/v1/accounts/change-password/` with server-required confirmation and post-success session invalidation.
- Concise static privacy information and About HepaSense content.
- Backend-backed Help using `GET /api/v1/education/articles/?type=help` and existing safe article detail.
- Confirmed logout through the existing auth and Phase 8 current-device revocation lifecycle.

## Unsupported features intentionally omitted

Notification preferences, language selection, PDF reports, account deletion, premium membership, user statistics, fake support contacts, chatbot/symptom checking, and legal/compliance certifications have no approved Phase 10 contract.

## Security

Passwords exist only in screen-local `TextEditingController`s, are never logged or persisted, and are cleared after success and disposal. Riverpod state contains only lifecycle status and safe response/error messages. Backend success invalidates JWT sessions; the client clears its tokens and returns to login.

## Visual reference

- Figma file: `kIutNKXVzAlNjBkQO97ZWj`
- Account frame: `27:1685`
- Edit Profile frame: `27:1818` (not called because the first permitted Figma request was rate-limited)
- Plant-care semantics are excluded; only the documented visual hierarchy is adapted.
