# HepaSense Mobile

## Product Requirements Document

**Document:** Mobile Application PRD
**Platform:** Flutter / Dart
**Primary Client:** Android mobile application
**Primary User:** HepaSense patient / application user
**Backend:** Django REST Framework — `/api/v1/`
**Design Reference:** Figma HepaSense
**Status:** Implementation source of truth for phased mobile development

Figma reference:

```text
https://www.figma.com/design/h9MvTHL7CoVAZ2HYh92Jp0/Untitled?node-id=0-1&t=qeEMe4iZTSquHRFv-1
```

---

# 1. IMPORTANT INSTRUCTION FOR OPENCODE

This document is a **Product Requirements Document**, not a one-shot implementation prompt.

Do **NOT** attempt to build the entire HepaSense mobile application from this document in one execution.

Implementation will be performed incrementally through separately approved mobile phases.

For every implementation phase:

1. audit the existing Flutter repository first;
2. read this PRD;
3. read the latest mobile architecture documentation;
4. read the latest backend API contract;
5. inspect the actual existing source code;
6. implement only the explicitly requested phase;
7. run tests and static analysis;
8. stop and return a report.

Never automatically begin the next phase.

---

# 2. PRODUCT OVERVIEW

HepaSense Mobile is the patient-facing application for the HepaSense ecosystem.

HepaSense is a non-invasive IoT-based early liver-function screening system.

The physical HepaSense device acquires respiratory measurements and processes a screening result. The backend stores that screening result and exposes authorized information to the user's mobile application.

The mobile application does **not** perform the HepaSense sensor measurement itself.

Conceptual system flow:

```text
HepaSense IoT Device
        ↓
Breath Screening
        ↓
Backend Screening Record
        ↓
Database Notification
        ↓
REST API / Push Notification
        ↓
HepaSense Flutter App
```

The patient application allows users to:

* securely access their account;
* view their latest screening result;
* view screening history;
* inspect screening details;
* receive and manage notifications;
* manage their account/profile;
* access educational/supporting information;
* access general nutritional information when the backend domain becomes available;
* access help, privacy, and supporting content.

---

# 3. MEDICAL POSITIONING

HepaSense must consistently be presented as:

> an early screening / screening-support system.

It must NOT be presented as:

```text
a confirmed diagnosis system
a medical diagnostic replacement
a treatment-prescription system
a definitive liver disease detector
```

Mobile copy must avoid claims such as:

```text
"Anda menderita penyakit hati."
"Anda positif penyakit hati."
"Anda pasti sehat."
```

Prefer wording such as:

```text
"Hasil skrining menunjukkan..."
"Hasil pemeriksaan awal..."
"Disarankan melakukan pemeriksaan lebih lanjut..."
"Hasil ini bukan diagnosis medis."
```

The application must make it clear that screening results should not replace evaluation by qualified healthcare professionals.

---

# 4. PRODUCT USERS

## 4.1 Primary Mobile User

The primary mobile role is:

```text
Patient / application user
```

represented by the existing backend account and Patient relationship.

---

## 4.2 Healthcare / Clinician

Healthcare workers already have a separate backend authorization domain.

Endpoints under:

```text
/api/v1/healthcare/*
```

are **NOT part of the patient mobile application**.

Do not use healthcare APIs in this application.

A future clinician-specific mobile application may be considered separately.

---

## 4.3 IoT Device

HepaSense physical device authentication is completely separate from human authentication.

The Flutter application must NEVER use:

```text
Authorization: HepaSense <device_code>:<device_secret>
```

Device credentials must never exist in the mobile application.

---

# 5. PRODUCT LANGUAGE

Primary application language:

```text
Bahasa Indonesia
```

UI copy should be:

* understandable for general users;
* concise;
* non-technical where possible;
* medically conservative;
* reassuring without guaranteeing health outcomes.

Technical sensor terminology may appear in detailed screening information where appropriate.

---

# 6. DESIGN SOURCE OF TRUTH

The visual source of truth is the HepaSense Figma design:

```text
https://www.figma.com/design/h9MvTHL7CoVAZ2HYh92Jp0/Untitled?node-id=0-1&t=qeEMe4iZTSquHRFv-1
```

The implementation must preserve, where available:

```text
visual hierarchy
layout
spacing
typography
colors
border radius
cards
buttons
inputs
navigation
icons
illustrations
component consistency
screen relationships
```

Do not redesign screens simply because OpenCode prefers another UI style.

If Figma and implementation requirements conflict:

* preserve the product behavior from this PRD;
* preserve actual backend contract;
* adapt the visual implementation with the smallest possible change.

If Figma cannot be accessed directly:

* use provided screenshots/assets/specifications;
* do not invent an unrelated design system;
* report missing design information.

---

# 7. RESPONSIVE MOBILE DESIGN

The app must support typical Android phone dimensions.

Every screen should account for:

```text
SafeArea
status bar
navigation bar
keyboard
small phone heights
different phone widths
text scaling
scrollable content
```

Avoid fixed layouts that overflow on smaller devices.

Interactive controls should have reasonable touch targets.

Avoid text that becomes unreadable when system text scaling is increased.

---

# 8. HIGH-LEVEL MOBILE SCREEN MAP

The intended patient application includes:

```text
Splash
Login
Register
MFA / OTP Verification
Home / Beranda

Screening History
Screening Detail

Notifications

Education
Nutrition Education / Saran Gizi
FAQ / Help

Account
Edit Profile
Change Password
Privacy Policy
Help
Logout
```

A future feature may include:

```text
Tanya AI
```

but AI is NOT part of the current mobile implementation contract until the backend AI domain is separately designed and approved.

---

# 9. NAVIGATION CONCEPT

The exact navigation must follow Figma where defined.

Conceptually, the main authenticated application should provide easy access to:

```text
Home
History
Notifications / supporting feature
Account
```

Do not create excessive nested navigation.

Deep links from notifications should only be implemented when the backend contract exposes sufficient authorized identifiers.

---

# 10. MOBILE ARCHITECTURE PRINCIPLES

Before creating architecture, OpenCode MUST audit the existing Flutter project.

Reuse existing architecture when it is coherent and maintainable.

Do not rewrite an existing working Flutter architecture only to introduce a preferred pattern.

If the project is effectively greenfield, prefer a feature-oriented structure conceptually similar to:

```text
lib/
├── app/
│
├── core/
│   ├── config/
│   ├── network/
│   ├── storage/
│   ├── errors/
│   ├── routing/
│   ├── theme/
│   └── widgets/
│
└── features/
    ├── auth/
    ├── profile/
    ├── home/
    ├── screenings/
    ├── notifications/
    ├── education/
    └── settings/
```

Avoid excessive clean-architecture boilerplate if it provides no meaningful benefit.

---

# 11. STATE MANAGEMENT

First inspect the repository.

If no suitable state-management solution already exists, Riverpod is acceptable.

Do not introduce multiple competing state-management libraries.

Avoid combining unrelated approaches such as:

```text
Bloc + Riverpod + Provider
```

without a genuine existing requirement.

State should clearly represent at minimum:

```text
initial
loading
success
empty
failure
```

where relevant.

---

# 12. ROUTING

First inspect the current routing implementation.

If there is no established router, `go_router` is acceptable.

Routing must support:

```text
authentication gate
authenticated shell
MFA intermediate state
screening detail navigation
notification navigation
logout reset
```

Protected routes must not remain accessible after logout.

---

# 13. NETWORK LAYER

The mobile application communicates with:

```text
Django REST API
```

using:

```text
/api/v1/
```

If no established HTTP client exists, Dio is acceptable.

Centralize network configuration.

Do not make direct HTTP calls independently inside every screen.

Conceptual flow:

```text
UI
 ↓
state/controller/provider
 ↓
repository
 ↓
API client
 ↓
Django backend
```

---

# 14. API CONTRACT RULE

The mobile application must **never invent backend endpoints**.

Before implementing an endpoint integration, inspect the latest:

```text
docs/backend/04-api-contract-draft.md
```

and relevant backend phase documentation/source.

If this PRD and actual current backend contract differ:

```text
STOP
```

and report the mismatch.

Do not silently invent a request or response schema.

---

# 15. API BASE URL

Base URLs must be configuration-driven.

Support separate environments where practical:

```text
development
staging
production
```

Never permanently hardcode:

```text
localhost
private developer IP
production secret
Firebase credentials
API key
```

into UI/domain code.

Production backend communication must use HTTPS.

---

# 16. AUTHENTICATION

The backend currently provides authentication under:

```text
/api/v1/auth/*
```

Relevant current APIs include:

```http
POST /api/v1/auth/register/

POST /api/v1/auth/login/

POST /api/v1/auth/2fa/login/

POST /api/v1/auth/token/refresh/

POST /api/v1/auth/logout/
```

Also:

```http
GET/PATCH /api/v1/accounts/profile/

POST /api/v1/accounts/change-password/
```

Actual current backend contract must always be inspected before implementation.

---

# 17. SPLASH / SESSION RESTORATION

Splash is responsible for determining initial application state.

Conceptually:

```text
App Start
   ↓
check local authentication state
   ↓
valid recoverable session?
 ┌────────────┴────────────┐
 YES                       NO
 ↓                         ↓
restore                  Login
 ↓
Home
```

Do not display Home temporarily before authentication state is known.

Avoid visual flashing between authenticated and unauthenticated screens.

---

# 18. TOKEN STORAGE

Authentication credentials must not be stored in ordinary plaintext preferences.

Use secure storage compatible with the existing project.

If no implementation exists:

```text
flutter_secure_storage
```

is acceptable.

Do not log:

```text
access token
refresh token
MFA challenge
password
TOTP code
```

---

# 19. ACCESS TOKEN REFRESH

The network layer must support refresh-token behavior.

Conceptually:

```text
API request
   ↓
401
   ↓
attempt one valid refresh
   ↓
 ┌──────── success ────────┐
 ↓                         │
retry request              │
                           │
refresh fails              │
 ↓                         │
clear authenticated state ←┘
 ↓
Login
```

Avoid an infinite retry loop.

If multiple simultaneous requests return 401, avoid generating a refresh storm.

Prefer a single coordinated refresh operation with queued/retried requests.

---

# 20. MFA LOGIN FLOW

Existing backend MFA/TOTP must be respected.

Password authentication for MFA-enabled accounts may result in a temporary challenge rather than JWT issuance.

Conceptually:

```text
Login
  ↓
email + password
  ↓
POST /auth/login/
  ↓
┌──────────────────┬────────────────────┐
│ JWT issued       │ MFA challenge      │
↓                  ↓
Home            OTP Screen
                   ↓
             POST /auth/2fa/login/
                   ↓
                  JWT
                   ↓
                  Home
```

The application must NEVER attempt to bypass MFA using another token endpoint.

MFA challenge values must be treated as sensitive temporary authentication material.

---

# 21. LOGIN SCREEN

Login must support:

```text
email
password
password visibility toggle
loading state
input validation
backend validation errors
network failure state
MFA transition
```

Do not reveal whether an account exists beyond what the backend intentionally returns.

---

# 22. REGISTRATION

Registration uses the current backend contract:

```http
POST /api/v1/auth/register/
```

Fields must follow the actual serializer contract.

Do not invent profile fields.

After successful registration, follow backend-approved behavior.

Do not automatically assume that every newly created application User already has a Patient record.

---

# 23. USER AND PATIENT ARE DIFFERENT CONCEPTS

The backend distinguishes:

```text
User
```

from:

```text
Patient
```

A User may exist without an associated Patient.

Mobile must understand this state.

Patient lookup:

```http
GET /api/v1/patients/me/
```

If the backend returns that no Patient is linked, display a dedicated safe state such as:

```text
"Akun Anda belum terhubung dengan data pasien HepaSense."
```

Provide appropriate support guidance.

Do NOT:

```text
automatically create a Patient
guess a patient_code
automatically link an account
call an undocumented self-claim endpoint
```

The current backend does not provide an approved patient self-claim flow.

---

# 24. HOME / BERANDA

Home is the primary authenticated patient dashboard.

The screen should follow Figma and may contain:

```text
user greeting
patient/profile summary
latest screening summary
screening status
screening time/date
navigation to detail
history shortcut
notification status/badge
education/support shortcuts
```

Exact card arrangement follows the design.

---

# 25. LATEST SCREENING

Use:

```http
GET /api/v1/screenings/latest/
```

Possible UI states must be implemented:

```text
loading

success

no screening yet

User exists but Patient not linked

network failure

session expired

server error
```

A 404 must not automatically be shown as a generic technical error.

Determine whether the 404 means:

```text
no screening
```

or another documented domain condition.

---

# 26. SCREENING STATUS

Current domain statuses:

```text
healthy
warning
high_risk
invalid
```

Display mapping must be centralized.

Do not spread hardcoded status translations across multiple widgets.

Conceptual Indonesian labels may be:

```text
healthy
→ Hasil Skrining Baik / Sehat

warning
→ Waspada

high_risk
→ Risiko Tinggi

invalid
→ Pemeriksaan Tidak Valid
```

Final copy should follow approved UI/product wording.

Do not translate `high_risk` into confirmed disease.

---

# 27. INVALID SCREENING

An invalid sample is not a positive or negative screening result.

When:

```text
sample_valid = false
classification = null
```

mobile must display an invalid-measurement state.

Do not manufacture:

```text
healthy
warning
high_risk
```

when the backend classification is null.

Provide understandable guidance such as repeating the screening according to device/operator procedure where appropriate.

---

# 28. SCREENING HISTORY

Use:

```http
GET /api/v1/screenings/
```

The backend currently supports paginated results.

Supported filters include:

```text
status
measured_from
measured_to
ordering
```

Do not assume every filter must immediately appear in the UI.

Figma and phase scope determine visible controls.

The data layer should remain compatible with backend pagination.

---

# 29. HISTORY STATES

History must support:

```text
initial loading
pagination loading
pull-to-refresh
empty history
network error
retry
pagination end
```

Avoid fetching the entire medical history at once.

Do not duplicate records during pagination.

---

# 30. SCREENING DETAIL

Use:

```http
GET /api/v1/screenings/{id}/
```

Current patient-safe Screening information may include:

```text
screening ID
screening UID
measurement timestamp
status
sample validity

corrected NH3
NH3 unit

temperature
humidity
flow quality
expiration duration

classification
classifier score when present
```

Actual fields must follow the current backend serializer.

---

# 31. SCREENING DETAIL — FORBIDDEN ASSUMPTIONS

Do NOT display or request internal values that the patient API intentionally excludes, including:

```text
raw NH3 acquisition value
payload digest
device credential
device secret
device secret hash
raw fingerprint data
TOTP data
internal idempotency metadata
```

The mobile client should not need them.

---

# 32. CLASSIFIER SCORE

The backend may expose:

```text
confidence_score
```

The current system does NOT establish that this is a calibrated medical probability.

Therefore do not label it as:

```text
"92% kemungkinan Anda mengalami penyakit hati"
```

unless a later validated backend/product contract explicitly permits such interpretation.

If shown at all, it should be presented as a model/system score with careful terminology.

It is acceptable for the initial UI not to display it.

---

# 33. NOTIFICATION CENTER

Existing backend notification APIs:

```http
GET /api/v1/notifications/

GET /api/v1/notifications/unread-count/

POST /api/v1/notifications/{id}/read/

POST /api/v1/notifications/read-all/
```

The mobile app should support:

```text
notification list
unread indicator
mark individual notification read
mark all read
empty state
pagination where backend provides it
loading/error/retry
```

---

# 34. NOTIFICATION TYPES

Current types include:

```text
invalid_measurement
screening_ready
warning_result
high_risk_result
```

Do not derive diagnosis language from those types.

Use the title/message snapshot provided by the backend wherever appropriate.

---

# 35. NOTIFICATION DEEP LINKING

Do not invent a Screening identifier from Notification data.

Only deep-link to Screening Detail when the final backend Notification contract safely exposes sufficient information.

If only:

```text
notification_id
type
```

is available, mobile should retrieve authorized backend state rather than guessing identifiers.

---

# 36. PUSH NOTIFICATION — CURRENT BLOCKER

The backend has implemented the Phase 7 FCM delivery infrastructure, but the final Firebase-target contract is currently undergoing verification/correction.

Therefore:

```text
MOBILE FIREBASE PUSH REGISTRATION:
BLOCKED UNTIL PHASE 7 FCM CONTRACT IS FINAL
```

OpenCode may implement:

```text
Notification Center UI
Notification REST integration
notification badge
notification state
```

before that contract is finalized.

Do NOT yet hardcode:

```dart
FirebaseMessaging.instance.getToken()
```

or:

```dart
FirebaseInstallations.instance.getId()
```

as the backend registration source.

The backend will explicitly decide whether the contract is:

```text
Firebase Installation ID (FID)
```

or another approved Firebase target identifier.

Once finalized, mobile must follow the backend contract exactly.

---

# 37. FUTURE PUSH DEVICE FLOW

After backend Phase 7 contract approval, the intended flow is:

```text
User logs in
    ↓
Flutter obtains approved Firebase target identifier
    ↓
POST target to backend
    ↓
Backend associates target with request.user
    ↓
New Screening
    ↓
Database Notification
    ↓
Push delivery processor
    ↓
Firebase
    ↓
Flutter receives push
```

The mobile application must never submit arbitrary:

```text
user_id
patient_id
```

for push ownership.

Backend derives ownership from authentication.

---

# 38. PUSH PRIVACY

Push notifications appearing on a device lock screen must not contain detailed medical measurements.

Do not request or create payloads containing:

```text
NH3 measurement
patient name
fingerprint reference
medical history
authentication token
device credential
```

Push is a notification mechanism, not a complete medical record transport.

Full information should be obtained from authorized REST endpoints after the app opens.

---

# 39. PUSH AND READ STATE

Receiving a push must NOT automatically mark the database Notification as read.

Notification read state changes only when the appropriate user interaction/backend API occurs.

These are separate concepts:

```text
push delivered
≠
notification read
```

---

# 40. PROFILE / ACCOUNT

Use the existing account endpoint:

```http
GET /api/v1/accounts/profile/
PATCH /api/v1/accounts/profile/
```

or the exact supported methods from the latest contract.

Account screens should support:

```text
view profile
edit supported profile fields
loading
save state
validation
success feedback
failure feedback
```

Do not allow users to modify server-controlled identity fields if the backend does not allow them.

---

# 41. CHANGE PASSWORD

Use:

```http
POST /api/v1/accounts/change-password/
```

After password change, the backend may invalidate existing JWT sessions.

The mobile flow must correctly handle that behavior.

If the backend requires reauthentication afterward:

```text
clear local authenticated state
→ return to Login
```

Do not continue using invalidated JWTs.

---

# 42. LOGOUT

Use the actual Phase 1 logout contract.

Logout should:

```text
call backend logout where possible
clear local access/refresh authentication state
clear sensitive in-memory data
reset protected navigation
return to Login
```

Do not erase unrelated application preferences unnecessarily.

---

# 43. PUSH DEVICE REVOCATION DURING LOGOUT

Once Phase 7 Firebase target contract is finalized, mobile should revoke only the push registration for the current device/session when appropriate.

Do not revoke all mobile devices belonging to the user's account.

Current backend logout endpoint should not be redesigned from Flutter.

---

# 44. EDUCATION

Education/supporting content is part of the intended HepaSense product, but its production backend domain may not yet be finalized when early mobile phases begin.

Mobile may later provide:

```text
article list
article detail
category
health education
HepaSense usage guidance
FAQ
```

Do NOT invent production endpoints.

Wait for an approved backend Education API contract.

---

# 45. SARAN GIZI

"Saran Gizi" should initially be treated as:

```text
general educational nutritional information
```

not personalized clinical nutrition.

Do not implement logic such as:

```text
high_risk → prescribe diet X
warning → prescribe food Y
NH3 value → generate diet automatically
```

without a separately reviewed clinical/backend specification.

General content may be provided under the Education domain later.

---

# 46. TANYA AI

Tanya AI is visible in the wider HepaSense product concept but is:

```text
DEFERRED
```

until there is an approved backend AI architecture.

Do not:

```text
call ChatGPT directly from Flutter
embed LLM API keys in Flutter
invent an AI backend endpoint
add RAG
add vector database
```

as part of the base mobile application.

---

# 47. HELP

The Help screen may include static or backend-supported information such as:

```text
common questions
how screening works
how to interpret app states
contact/support guidance
```

Do not fabricate production support contact information.

Use approved content only.

---

# 48. PRIVACY POLICY

The app should expose a Privacy Policy screen according to the final content/design.

It must accurately reflect implemented behavior.

Do not claim:

```text
data is never stored
data is fully anonymous
medical diagnosis is performed
specific legal compliance certification
```

unless confirmed by project policy.

---

# 49. REPORT VIA EMAIL

The research/product concept may contain a report-by-email function.

Do not invent a backend mail endpoint.

If such a feature is implemented later, it must first determine whether the approved behavior is:

```text
open device email client
```

or:

```text
backend-generated report/email
```

This remains deferred until the contract is defined.

---

# 50. ERROR STATE DESIGN

The app must distinguish major domain states instead of showing the same generic snackbar for everything.

Important states include:

```text
no internet connection
server unavailable
request timeout

invalid login
MFA required
MFA invalid
session expired

User not linked to Patient
Patient has no Screening yet

invalid Screening sample

empty Notification list

backend validation error
unexpected server error
```

Provide clear Indonesian user-facing messages.

Do not expose raw backend stack traces.

---

# 51. LOADING UX

Avoid blocking the entire application unnecessarily.

Use appropriate:

```text
screen loading
skeleton/loading card
button progress state
pagination loader
pull-to-refresh
```

depending on the Figma design.

Prevent duplicate submissions while a mutation request is still processing.

---

# 52. ONLINE / OFFLINE BEHAVIOR

Initial HepaSense Mobile should be treated as:

```text
online-first
```

The backend remains the medical screening source of truth.

Do not build a complex offline synchronization engine without separate approval.

Limited local caching for improved UX may be considered later, but:

```text
cached medical status must not masquerade as fresh data
```

If stale data is displayed, its timestamp/state must remain clear.

---

# 53. LOCAL DATA SECURITY

Avoid persisting unnecessary medical data.

Authentication secrets belong in secure storage.

Do not store sensitive patient or screening information in:

```text
plain SharedPreferences
debug logs
analytics events
crash breadcrumbs
temporary text files
```

unless specifically designed and reviewed.

---

# 54. LOGGING

Development logging must never print:

```text
password
access token
refresh token
MFA challenge
OTP/TOTP
full Firebase target identifier
patient private data
raw fingerprint reference
device secret
```

API logging should redact sensitive headers.

Do not leave verbose sensitive HTTP-body logging enabled in production.

---

# 55. BIOMETRIC DATA

The HepaSense physical device uses fingerprint identification, but mobile must NEVER process or store raw HepaSense fingerprint templates.

The mobile app may receive the authorized Patient relationship resulting from backend identification.

Do not add fingerprint-template handling to Flutter.

Phone biometric authentication is a different feature and is not part of this PRD unless separately approved.

---

# 56. IoT DEVICE SECRETS

The Flutter repository must contain no:

```text
HepaSense device secret
device credential hash
firmware credential
IoT provisioning secret
```

Those belong to the device/backend domain.

---

# 57. DEPENDENCY POLICY

Before adding a Flutter package:

1. inspect existing dependencies;
2. reuse an existing equivalent dependency where appropriate;
3. add only what the current phase genuinely needs;
4. avoid broad package upgrades unrelated to the task.

Do not add packages merely because they are popular.

Potential libraries such as:

```text
Dio
Riverpod
go_router
flutter_secure_storage
Firebase packages
```

are recommendations only when the repository does not already have an equivalent solution.

Firebase packages must not be introduced before the corresponding approved phase.

---

# 58. DESIGN SYSTEM / REUSABLE COMPONENTS

UI should not repeatedly recreate identical components.

Where the Figma design supports them, create reusable:

```text
primary button
secondary button
text field
password field
top app bar
bottom navigation
status badge
screening card
notification item
empty state
error state
loading state
section header
dialog/modal
```

Avoid premature abstraction for components used only once.

---

# 59. STATUS DESIGN TOKENS

Screening status presentation should be centralized.

Conceptually:

```text
healthy
warning
high_risk
invalid
```

may map to:

```text
label
icon
visual emphasis
supporting copy
```

Do not use color as the only way to communicate medical status.

---

# 60. ACCESSIBILITY

Implement reasonable accessibility support:

```text
semantic labels for important controls
sufficient contrast
text scaling
large touch targets
clear input errors
screen-reader-friendly important status labels
```

Icons representing health status should have accompanying text.

---

# 61. REFRESH BEHAVIOR

Medical information should be refreshable.

Important screens such as:

```text
Home
Screening History
Notifications
```

should provide suitable refresh behavior.

Avoid displaying an old result indefinitely after the user returns to the app.

---

# 62. APP RESUME

When returning from background, do not aggressively refetch every endpoint at once.

Refresh time-sensitive state where appropriate, for example:

```text
latest Screening
unread Notification count
```

Use a sensible freshness policy.

Do not cause duplicate network storms.

---

# 63. NOTIFICATION BADGE

Unread count may use:

```http
GET /api/v1/notifications/unread-count/
```

The badge should update after:

```text
mark-one read
mark-all read
refresh
new push / app resume when implemented
```

Do not maintain a permanently independent local unread count that drifts from the backend.

---

# 64. DATE AND TIME

The backend remains authoritative for measurement timestamps.

Mobile should:

```text
parse ISO timestamps safely
display appropriate local time
preserve original instant
```

Do not alter `measured_at` values.

Clearly distinguish:

```text
measurement date
notification date
```

where applicable.

---

# 65. NUMBER FORMATTING

Sensor values must retain their correct units.

Do not silently transform:

```text
ppm
temperature
humidity
flow quality
duration
```

without a documented requirement.

Avoid presenting precision that falsely implies stronger medical accuracy.

---

# 66. CLIENT-SIDE VALIDATION

Client validation improves UX but does not replace backend validation.

For mutation forms:

```text
validate obvious required fields locally
send request
respect backend validation response
```

Do not attempt to duplicate every backend business rule.

---

# 67. SECURITY BOUNDARY

The Flutter app is an untrusted API client from the backend's perspective.

Never rely on:

```text
hidden button
hidden route
local role flag
disabled control
```

as the primary security mechanism.

Backend authorization remains authoritative.

---

# 68. PATIENT OWNERSHIP

Patient-screening endpoints already enforce ownership.

Mobile must use the authenticated user's endpoints.

Do not send arbitrary:

```text
patient_id
user_id
```

to access another patient's screening history.

---

# 69. HEALTHCARE API EXCLUSION

These endpoints are outside this mobile application's scope:

```text
/api/v1/healthcare/patients/*
/api/v1/healthcare/screenings/*
```

Do not integrate them into the patient app.

---

# 70. ANALYTICS

Firebase Analytics or another analytics SDK is not required for the initial product.

Do not add analytics automatically when adding Firebase push infrastructure.

Analytics requires separate product/privacy approval.

---

# 71. CRASH REPORTING

Do not automatically add a crash-reporting SDK.

If added later, sensitive medical and authentication data must be redacted before transmission.

---

# 72. TESTING STRATEGY

Mobile development must include tests incrementally.

The precise test architecture should follow the existing repository.

At minimum, final mobile coverage should include important behavior around:

```text
authentication
MFA flow
token refresh
Patient linkage
Home/latest Screening
Screening history
Screening detail
invalid sample
Notification Center
read/unread
profile
logout
error states
```

---

# 73. AUTH TEST SCENARIOS

Required eventually:

```text
successful login

failed login

MFA-required login

invalid MFA

successful MFA

session restoration

access-token expiry + successful refresh

refresh failure → logout

password change invalidates session correctly

logout clears authentication
```

---

# 74. PATIENT TEST SCENARIOS

Required eventually:

```text
linked Patient loads correctly

User without Patient linkage
→ safe dedicated UI state

no unauthorized self-link behavior
```

---

# 75. SCREENING TEST SCENARIOS

Required eventually:

```text
latest Screening success

no Screening

history success

history empty

history pagination

history refresh

healthy result

warning result

high-risk result

invalid sample

Screening detail failure

network failure
```

---

# 76. NOTIFICATION TEST SCENARIOS

Required eventually:

```text
list loads

empty list

unread count

mark one read

mark all read

cross-screen badge refresh

pagination

network error

push received without auto-read
```

once push integration is implemented.

---

# 77. TEST NETWORK POLICY

Automated tests should not require a live production backend.

Use:

```text
mock/fake API boundaries
test fixtures
controlled staging integration tests
```

as appropriate.

Never place production credentials in test code.

---

# 78. STATIC QUALITY

Every completed implementation phase should leave:

```text
flutter analyze
```

clean unless a documented pre-existing issue prevents it.

Also run the repository's existing tests and formatting commands.

Do not suppress analyzer warnings globally simply to obtain a green result.

---

# 79. BUILD VALIDATION

Before declaring the complete mobile app production-ready, verify at minimum:

```text
Flutter analyze PASS
Flutter tests PASS
Android debug build PASS
Android release-compatible configuration reviewed
```

Do not require iOS completion if the project scope is currently Android-only unless separately requested.

---

# 80. CURRENT BACKEND INTEGRATION STATUS

The mobile team may currently treat these domains as available for integration:

```text
Authentication + MFA           AVAILABLE
Account/Profile                AVAILABLE
Patient identity lookup        AVAILABLE
Patient Screening APIs         AVAILABLE
Database Notification APIs     AVAILABLE
```

Healthcare clinician APIs exist but are:

```text
NOT USED BY PATIENT MOBILE
```

Push backend infrastructure exists, but mobile Firebase registration is:

```text
WAITING FOR FINAL PHASE 7 TARGET CONTRACT
```

Education backend:

```text
NOT YET FINALIZED
```

AI backend:

```text
NOT AVAILABLE
```

---

# 81. FEATURE READINESS MATRIX

| Mobile Feature               | Backend Status                    | Mobile Implementation                  |
| ---------------------------- | --------------------------------- | -------------------------------------- |
| Splash/session               | Ready                             | May implement                          |
| Login                        | Ready                             | May implement                          |
| Register                     | Ready                             | May implement                          |
| MFA/TOTP                     | Ready                             | May implement                          |
| Profile                      | Ready                             | May implement                          |
| Change password              | Ready                             | May implement                          |
| Patient linkage state        | Ready                             | May implement                          |
| Home/latest Screening        | Ready                             | May implement                          |
| Screening history            | Ready                             | May implement                          |
| Screening detail             | Ready                             | May implement                          |
| Notification Center          | Ready                             | May implement                          |
| Notification unread count    | Ready                             | May implement                          |
| FCM REST registration        | Contract under final verification | WAIT                                   |
| Firebase receive integration | Contract under final verification | WAIT                                   |
| Education                    | Backend pending                   | UI later / production integration WAIT |
| Saran Gizi                   | Backend pending                   | WAIT for approved content contract     |
| FAQ backend                  | Backend pending                   | WAIT                                   |
| Tanya AI                     | Not implemented                   | DEFER                                  |
| Clinician dashboard          | Separate application/domain       | OUT OF SCOPE                           |

---

# 82. MOBILE IMPLEMENTATION PHASE PLAN

The project should be implemented using separate approved prompts.

Recommended sequence:

```text
MOBILE PHASE 0
Repository Audit & Mobile Architecture Baseline

MOBILE PHASE 1
Flutter Foundation, Routing, Theme & Design System

MOBILE PHASE 2
Authentication, Registration & MFA

MOBILE PHASE 3
Patient Identity, Profile & Account

MOBILE PHASE 4
Home Dashboard & Latest Screening

MOBILE PHASE 5
Screening History

MOBILE PHASE 6
Screening Detail

MOBILE PHASE 7
Notification Center

MOBILE PHASE 8
Firebase Push Integration
ONLY after backend Phase 7 contract is approved

MOBILE PHASE 9
Education, General Nutrition & FAQ
ONLY after corresponding backend contract exists

MOBILE PHASE 10
Settings, Help, Privacy & Account Completion

MOBILE PHASE 11
Integration, Error Handling, Resilience & UX Hardening

MOBILE PHASE 12
Testing, Performance, Security & Production Hardening
```

The exact phase structure may be adjusted after Mobile Phase 0 repository audit.

Do not merge phases automatically.

---

# 83. MOBILE PHASE 0 MUST COME FIRST

OpenCode must not immediately begin designing architecture from assumptions.

Mobile Phase 0 must inspect:

```text
Flutter version
Dart version

pubspec.yaml

existing directory structure
routing
state management
networking
secure storage
theme/design tokens
assets
existing screens
Firebase configuration
Android configuration
environment handling
tests
lint/analyzer state
```

It must also identify:

```text
existing reusable components
dead/placeholder screens
duplicated architecture
existing API integration
mock data
hardcoded URLs
hardcoded secrets
```

No major feature implementation should occur during Phase 0.

---

# 84. DOCUMENTATION STRUCTURE

Recommended documentation:

```text
docs/mobile/
├── 00-mobile-prd.md
├── 01-mobile-architecture.md
├── 02-api-integration-contract.md
├── 03-ui-screen-map.md
├── 04-design-system.md
└── phase-reports/
```

Do not create all documents without a reason.

Phase 0 should determine which are necessary.

---

# 85. SHARED API CONTRACT

Backend and mobile must share the same conceptual API contract.

Mobile documentation may summarize the backend API, but it must not become a divergent second API specification.

If backend contract changes:

```text
backend contract
    ↓
mobile integration contract updated
    ↓
mobile implementation updated
```

Never silently adapt mobile to an undocumented backend behavior.

---

# 86. BACKEND MODIFICATION RULE

The mobile OpenCode agent must NOT modify the Django backend.

If a required API is missing:

```text
STOP
```

and report:

```text
MISSING BACKEND CONTRACT
```

with:

```text
required user flow
required data
existing closest endpoint
proposed backend requirement
```

Then backend work must be handled separately.

Do not patch Django from the Flutter task.

---

# 87. FIGMA MODIFICATION RULE

The Flutter implementation should follow Figma.

OpenCode should not modify the Figma source unless explicitly instructed in a separate design task.

When an exact design element is missing, implement the smallest consistent UI and report the assumption.

---

# 88. SOURCE CONTROL SAFETY

Do not execute destructive commands such as:

```text
git reset --hard
git clean -fd
```

without explicit permission.

Do not discard unrelated user changes.

If the repository is not recognized as a Git repository, do not run:

```text
git init
```

automatically.

Report the condition instead.

---

# 89. FILE SAFETY

Do not:

```text
delete unrelated source code
replace the entire Flutter project
regenerate Android project configuration unnecessarily
remove user assets
rewrite dependency lockfiles without cause
```

Only modify files required for the current approved phase.

---

# 90. NO SCOPE CREEP

Without explicit approval, OpenCode must not add:

```text
AI chatbot
OpenAI API
Gemini API
RAG
vector database

maps
location tracking

social login

phone authentication

biometric login

analytics
Crashlytics

ads

payment

chat
video call

IoT control functionality

doctor mobile dashboard

FHIR
SATUSEHAT
```

even if those features appear useful.

---

# 91. NO SECRET IN MOBILE

Never embed:

```text
Django SECRET_KEY
database password
Firebase service-account JSON
Firebase private key
HepaSense device secret
server administrative token
LLM API secret
```

inside the application.

Client-side Firebase configuration may only be handled according to normal Firebase client-app configuration during the approved Firebase phase.

Server service-account credentials never belong in Flutter.

---

# 92. PERFORMANCE EXPECTATIONS

The app should avoid:

```text
unnecessary rebuilds
duplicate API requests
loading entire history at once
large images without optimization
blocking synchronous work on UI thread
```

Performance optimization should remain evidence-driven.

Do not introduce complex caching infrastructure prematurely.

---

# 93. UX CONSISTENCY

All primary flows must consistently provide:

```text
loading
success
empty
error
retry
```

where applicable.

Do not leave technical placeholders such as:

```text
Exception: DioException...
HTTP 500
Null check operator used on null value
```

visible to end users.

---

# 94. DEFINITION OF MVP COMPLETE

The HepaSense patient mobile MVP may be considered functionally complete when:

```text
User can register/login

MFA-enabled User can authenticate correctly

Session refresh/logout works

User can view/manage supported profile fields

Unlinked Patient state is handled safely

Linked Patient can view latest Screening

Patient can view Screening history

Patient can inspect Screening detail

Invalid Screening is represented correctly

Patient can view/manage database Notifications

Notification unread count stays synchronized

FCM push works after final approved contract

Help/privacy/basic supporting screens exist

All critical loading/empty/error states exist

No backend security boundary is bypassed

No secrets are embedded

Analyzer/tests/build are green
```

Education/general nutrition may be included in MVP once the backend content API becomes available.

AI is not required for the base MVP.

---

# 95. DEFINITION OF DONE PER MOBILE PHASE

Every implementation phase must finish with:

```text
requested phase implemented

no unrelated feature implementation

existing behavior preserved

flutter analyze executed

relevant tests executed

build/check executed when appropriate

new dependency justified

no hardcoded secrets

no invented endpoint

documentation updated where appropriate

known limitations reported

next phase NOT automatically started
```

---

# 96. OPENCODE FINAL RULES

For all future HepaSense Mobile implementation tasks:

```text
1. Read this PRD.

2. Read the explicit phase prompt.

3. Audit actual source before modifying it.

4. Reuse existing implementation where appropriate.

5. Follow Figma for visual implementation.

6. Follow backend for API behavior.

7. Never invent missing backend behavior.

8. Never expose sensitive credentials or medical internals.

9. Preserve non-diagnostic medical wording.

10. Keep Patient and clinician domains separated.

11. Implement only the requested phase.

12. Test before reporting completion.

13. Clearly report blockers instead of guessing.

14. Do not automatically begin another phase.
```

---

# 97. PRODUCT END STATE

Target patient flow:

```text
                      APP START
                          │
                        Splash
                          │
                ┌─────────┴─────────┐
                │                   │
             Logged Out         Session Valid
                │                   │
              Login                 │
                │                   │
          MFA if required           │
                └─────────┬─────────┘
                          │
                        HOME
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ↓                 ↓                 ↓
 Latest Screening      History        Notifications
        │                 │                 │
        ↓                 ↓                 ↓
 Screening Detail   Screening Detail     Read/Manage
        │
        │
        ├──────────────→ Education / Help
        │
        └──────────────→ Account
                              │
                     ┌────────┼────────┐
                     ↓        ↓        ↓
                   Profile Password  Privacy/Help
                              │
                            Logout
```

The backend remains the authoritative source for:

```text
identity
Patient relationship
Screening records
Screening classification
Notification records
authorization
```

Flutter is responsible for delivering a secure, understandable, consistent patient experience on top of that contract.
