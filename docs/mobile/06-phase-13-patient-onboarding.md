# Phase 13 — Patient account linking

Mobile registration continues to create only the application `User`. An
authenticated account without a medical Patient relation receives 404 from
`GET /api/v1/patients/me/` and remains signed in.

The home screen explains that a healthcare worker must connect the account
using the exact registration email. **Coba Lagi** calls the same `/patients/me/`
endpoint: another 404 stays unlinked, while 200 immediately transitions to the
normal linked Patient home. A network failure is retryable and does not destroy
authentication. When the app resumes while unlinked, it performs one safe
refresh; there is no polling or timer.

No self-claim, automatic Patient creation, broad account search, or mobile call
to the clinician onboarding endpoint exists.
