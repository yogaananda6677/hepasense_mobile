# HepaSense Mobile — API Integration Contract

> Backend Phases 1–11 are COMPLETED, core is CLOSED, and the contract is FROZEN. Authority: `docs/backend/20-final-api-contract.md`; Flutter subset: `docs/backend/21-flutter-integration-contract.md`. Backend validation: 145 tests + 18 subtests.

**Purpose:** Single canonical source of truth for the mobile↔backend API contract. Mobile code must **never** invent endpoints (PRD §14, §86). This file summarizes the backend phase reports; if it conflicts with backend code, **stop and report** (PRD §451, §2162).

Backend root: `/home/yoga/Data/TFS/hepasense_backend/` — mobile must not modify it.

## Base URL

- Configuration-driven (PRD §15). Environments: `development`, `staging`, `production`. No hardcoded host/secret/token in code.

## Authentication header & error envelope

- Bearer JWT access token for human APIs.
- Response envelope (Backend Phase 1 §31):
  ```json
  { "detail": "Data yang diberikan tidak valid.", "errors": { "field": ["message"] } }
  ```
- Uniform backend error includes `error.code`, `error.message`, `error.details` (where provided), `error.request_id` (API Contract Draft §11).

## 1. Authentication (Backend Phase 1 — COMPLETED)

| Method | Path | Auth | Request | Response | Notes |
|---|---|---|---|---|---|
| POST | `/api/v1/auth/register/` | none | email, password, confirm, first_name, last_name, phone; optional birth_date, gender | user + access/refresh JWTs | name/phone required; PRD §657 |
| POST | `/api/v1/auth/login/` | none | email, password | JWTs, or `{ requires_2fa: true, challenge: "<signed cached challenge>" }` | MFA-first-factor returns challenge, not tokens (Backend Phase 1 §40–51) |
| POST | `/api/v1/auth/token/` | none | alias of login | same as login | MFA-aware alias; never bypass MFA (Backend Phase 1 §66) |
| POST | `/api/v1/auth/token/refresh/` | none | refresh token | new access/refresh JWTs | enforces MFA state |
| POST | `/api/v1/auth/2fa/login/` | none | challenge, otp_code | final JWTs (mfa_verified=true) | 5-min one-time challenge, TOTPDevice |
| POST | `/api/v1/auth/logout/` | JWT | refresh token | 204/blacklist | revokes supplied refresh token only (Backend Phase 1 §74) |
| GET/PUT/PATCH | `/api/v1/accounts/profile/` | JWT | current-user fields (email/roles/2FA immutable) | profile | PRD §40 |
| POST | `/api/v1/accounts/change-password/` | JWT | old_password, new_password, confirm | 200/204 | invalidates existing JWT sessions server-side (PRD §41, §1186) |

**MFA rules:** Never bypass MFA. Never use another token endpoint to skip 2FA. The app must treat `challenge` as sensitive temporary material and not log it (PRD §1153, §54).

## 2. Patient identity (Backend Phase 2 — COMPLETED)

| Method | Path | Auth | Response | Notes |
|---|---|---|---|---|
| GET | `/api/v1/patients/me/` | JWT | linked Patient summary, or 404 | 404 = no linked Patient; message: `No patient profile is linked to this account.` (PRD §23, §696) |

- `Patient` ≠ `User` (PRD §23). A User may have no linked Patient.
- Patient code format: `HPS-<16 uppercase hex>`, immutable.
- No self-claim endpoint exists; do not create/link Patient from Flutter (PRD §707, Backend Phase 2 §111).

## 3. Screening query (Backend Phase 4 — COMPLETED, read-only)

| Method | Path | Auth | Response | Notes |
|---|---|---|---|---|
| GET | `/api/v1/screenings/` | JWT (MFA) | paginated list (page-number, 20/page) | order `-measured_at,-created_at,-id`; filters: status, measured_from, measured_to, ordering=measured_at\|\-measured_at |
| GET | `/api/v1/screenings/latest/` | JWT (MFA) | latest linked-Patient Screening, or 404 | 404 = no result; message `No screening result is available yet.` (PRD §768) |
| GET | `/api/v1/screenings/{id}/` | JWT (MFA) | Screening detail | scoped to `request.user -> Patient -> Screening`; cross-patient → 404; read-only (POST/PUT/PATCH/DELETE denied) |

### Detail response shape (Backend Phase 4 §48–72)

```json
{
  "id": 15,
  "screening_uid": "1d191d7b-9a30-46a1-9994-3df626ee8ea4",
  "measured_at": "2026-08-12 10:15:00",
  "status": "warning",
  "sample_valid": true,
  "measurement": {
    "nh3_corrected": "0.280000",
    "nh3_unit": "ppm",
    "temperature_celsius": "34.400",
    "humidity_percent": "86.200",
    "flow_quality": "0.910000",
    "expiration_duration_seconds": "5.300"
  },
  "result": { "classification": "warning", "confidence_score": null }
}
```

### Status mapping (Backend Phase 4 §33–40; PRD §26, §780)

| `status` | `sample_valid` | `classification` | Meaning |
|---|---|---|---|
| healthy | true | healthy | screening result |
| warning | true | warning | screening result |
| high_risk | true | high_risk | screening result |
| invalid | false | null | invalid sample (NOT a classification) |

- `confidence_score` is returned exactly as stored; do **not** present as a calibrated probability (PRD §32, §950).
- History compact serializer: id, screening_uid, measured_at, status, sample_valid, corrected NH3 + unit (Backend Phase 4 §49).

### Excluded fields (do not request/display; PRD §30, §924)

- raw NH3, device metadata, credential verifier, payload digest, Patient identifiers, ingestion internals, raw biometric data, JWTs, TOTP.

## 4. Patient-safe screening data

`measured_at` is ISO-8601 with timezone; server stores UTC, client localizes (PRD §64, API Contract Draft §7). NH3 unit is mandatory (`ppm` in current contract). Temperature Celsius, humidity percent, flow quality, expiration duration seconds — decimals (Backend Phase 3 §57, Phase 4 §48).

## 5. Notifications (Backend Phase 5 — COMPLETED, database source of truth)

| Method | Path | Auth | Response | Notes |
|---|---|---|---|---|
| GET | `/api/v1/notifications/` | JWT | paginated list (20/page), order `-created_at,-id` | filters: is_read, type |
| GET | `/api/v1/notifications/unread-count/` | JWT | `{ unread_count: N }` | for badge (PRD §63) |
| POST | `/api/v1/notifications/{id}/read/` | JWT | idempotent; sets read_at | cross-user → 404 |
| POST | `/api/v1/notifications/read-all/` | JWT | marks all current-user unread read | scoped update |

- Notification belongs to `User`; output contains `screening_id` for safe Phase 4 navigation only — no Screening internals (Backend Phase 5 §69, PRD §35).
- Read state ≠ push delivery (Backend Phase 5 §1, PRD §39). Marking read does not affect push.
- No public create/delete/detail endpoints (Backend Phase 5 §71).

## 6. Firebase / FCM push (Backend Phase 7 — COMPLETED, FID-based, FINAL)

> The mobile PRD §36/§80 previously listed FCM as "WAIT — contract under final verification." The backend Phase 7 report (`13-phase-7-fcm-push-notifications.md`, COMPLETED 2026-08-12) finalizes the contract. Mobile Phase 8 must re-inspect this report before adding FlutterFire packages.

| Method | Path | Auth | Body | Response | Notes |
|---|---|---|---|---|---|
| POST | `/api/v1/notifications/push-devices/` | JWT | `{ fid, platform }` | 201 new / 200 refresh / 400 old `token` field | FID write-only; returns 8-char `fid_hint` only |
| GET | `/api/v1/notifications/push-devices/` | JWT | — | paginated devices (FIDs masked) | scoped to current user |
| DELETE | `/api/v1/notifications/push-devices/{id}/` | JWT | — | 204/soft-revoke owned | cross-user → 404 |

- Mobile obtains the FID via **`FirebaseInstallations.instance.getId()`**, NOT `FirebaseMessaging.instance.getToken()` (PRD §1061, Backend Phase 7 §111).
- Backend rejects the legacy `token` field with HTTP 400.
- Logout: Flutter should soft-revoke the current device only, not all devices (PRD §1223, Backend Phase 7 §34).
- FCM payload data is minimal: `{ notification_id, type }` only — no medical detail (Backend Phase 7 §83, PRD §38).
- Migration `0004_invalidate_legacy_push_targets` revokes all pre-existing PushDevice rows; Flutter must register a fresh FID after backend deployment (Backend Phase 7 §117).
- Firebase service-account JSON must never be committed to the repo (Backend Phase 7 §81, PRD §91).

**Mobile Phase 8 implementation:** Android uses the finalized package
`com.yogaananda.hepasense` and native default initialization from the genuine
`android/app/google-services.json`. Authenticated sync obtains only the FID via
`FirebaseInstallations.instance.getId()` and sends the documented `fid` field.
The FCM registration token is neither read nor sent to Django.

## 7. Healthcare / clinician APIs — OUT OF SCOPE

`/api/v1/healthcare/*` (Backend Phase 6) is for clinicians and is **not** integrated into the patient mobile app (PRD §69, §144).

## 8. Endpoints explicitly forbidden in mobile

| Endpoint family | Reason |
|---|---|
| `/api/v1/healthcare/*` | clinician domain (PRD §69) |
| `/api/v1/iot/screenings/` | device-only ingestion; machine auth (PRD §53, §782) |
| any `Authorization: HepaSense <device>:<secret>` | device credentials never in client (PRD §53, §56, §585) |
| device secret / payload digest / raw NH3 / fingerprint templates | excluded fields (PRD §30, §924) |
| any self-claim / patient-create endpoint | none exists (PRD §707) |

## 9. Missing backend contracts (block later phases, do not invent)

- Education / Nutrition / FAQ API: **READY — backend contract available** (Backend Phase 8, `docs/backend/14-phase-8-education-content.md`, COMPLETED 2026-08-12). Public read-only API.
- Report-by-email backend: not defined → PRD §49 deferred.
- AI / Tanya AI: not implemented → PRD §1278 DEFERRED, out of scope.
