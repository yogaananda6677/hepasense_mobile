# Phase 15 — Real Android Visual QA

## Execution status

No Android target was available to the execution environment. The ADB daemon could not access USB or open its host listener in the sandbox, and the most recent successful Flutter discovery exposed only the Linux desktop target. Therefore no APK installation, Android screenshots, keyboard interaction, system-bar inspection, Firebase lifecycle observation, or real FCM delivery was executed. This report does not infer runtime visual quality from widget tests.

## Source-proven auth completion

The Phase 14 source audit showed an evident component inconsistency: Login and Register used the shared `AppCard`, while MFA did not; the in-app splash still used an unframed generic loading composition. The minimal Phase 15 correction was:

- wrap MFA fields/actions in the same shared auth surface while preserving OTP submission, validation, errors, loading state, back behavior, and route semantics;
- place both in-app splash implementations in a SafeArea and shared rounded surface while preserving session restoration;
- extend source regression coverage so Login, Register, MFA, and Splash must retain shared visual primitives and auth-controller wiring.

No auth payload, secure storage, routing, patient state, backend behavior, or medical copy changed.

## Screen-by-screen runtime report

| Screen | Runtime | Stitch fidelity | Overflow | Clipping | Text scale safe | Navigation | Visual issue | Fix applied |
|---|---|---|---|---|---|---|---|---|
| Splash | NOT EXECUTED | Source-aligned | NOT EXECUTED | NOT EXECUTED | NOT EXECUTED | NOT EXECUTED | Generic source composition | Shared SafeArea card |
| Login | NOT EXECUTED | Source-aligned | NOT EXECUTED | NOT EXECUTED | Supplementary widget coverage only | NOT EXECUTED | None proven | None |
| Register | NOT EXECUTED | Source-aligned | NOT EXECUTED | NOT EXECUTED | Supplementary widget coverage only | NOT EXECUTED | None proven | None |
| MFA | NOT EXECUTED | Source-aligned | NOT EXECUTED | NOT EXECUTED | NOT EXECUTED | NOT EXECUTED | Shared auth surface missing | Shared form card |
| Home | NOT EXECUTED | Source-aligned | NOT EXECUTED | NOT EXECUTED | Supplementary widget coverage only | NOT EXECUTED | None proven | None |
| Notifications | NOT EXECUTED | Source-aligned | NOT EXECUTED | NOT EXECUTED | Existing widget coverage | NOT EXECUTED | None proven | None |
| History | NOT EXECUTED | Source-aligned | NOT EXECUTED | NOT EXECUTED | Existing widget coverage | NOT EXECUTED | None proven | None |
| Screening Detail | NOT EXECUTED | Source-aligned | NOT EXECUTED | NOT EXECUTED | Existing widget coverage | NOT EXECUTED | None proven | None |
| Education | NOT EXECUTED | Source-aligned | NOT EXECUTED | NOT EXECUTED | Existing widget coverage | NOT EXECUTED | None proven | None |
| Article Detail | NOT EXECUTED | Source-aligned | NOT EXECUTED | NOT EXECUTED | Existing widget coverage | NOT EXECUTED | None proven | None |
| Account | NOT EXECUTED | Source-aligned | NOT EXECUTED | NOT EXECUTED | Existing widget coverage | NOT EXECUTED | None proven | None |
| Edit Profile | NOT EXECUTED | Source-aligned | NOT EXECUTED | NOT EXECUTED | Existing widget coverage | NOT EXECUTED | None proven | None |
| Change Password | NOT EXECUTED | Source-aligned | NOT EXECUTED | NOT EXECUTED | Existing widget coverage | NOT EXECUTED | None proven | None |
| Privacy | NOT EXECUTED | Source-aligned | NOT EXECUTED | NOT EXECUTED | NOT EXECUTED | NOT EXECUTED | None proven | None |
| Help | NOT EXECUTED | Source-aligned | NOT EXECUTED | NOT EXECUTED | NOT EXECUTED | NOT EXECUTED | None proven | None |
| About | NOT EXECUTED | Source-aligned | NOT EXECUTED | NOT EXECUTED | NOT EXECUTED | NOT EXECUTED | None proven | None |
| Bottom navigation | NOT EXECUTED | Source-aligned | NOT EXECUTED | NOT EXECUTED | Supplementary widget coverage only | NOT EXECUTED | None proven | None |
| Unlinked Patient | NOT REPRODUCED | Source-aligned | NOT EXECUTED | NOT EXECUTED | Existing widget coverage | NOT EXECUTED | None proven | None |

`Source-aligned` is not a runtime fidelity grade. It records only that the screen consumes the approved Phase 14 tokens/components.

## Accessibility and responsiveness

Supplementary widget tests cover 360×800, 390×844, and 412×915 at 1.3× text scale. Existing regression coverage also exercises long notification content, compact history rows at larger text, account layout at 360 px, and auth validation. These checks passed but do not replace real-device keyboard, cutout, gesture-navigation, or Android font-scale testing.

Keyboard QA, status/navigation bars, physical safe areas, 1.0×/1.3×/larger Android font settings, and touch behavior remain not executed.

## Firebase / FCM observations

Source and automated tests retain the established Firebase initialization boundary, FID retrieval adapter, push-device synchronization, foreground/opened/initial-message listeners, logout revocation, and safe unavailable behavior. None was observed on Android in this phase. Real FCM delivery remains not executed because no device received a notification.

## Remaining gaps

- Real Android installation and screen-by-screen visual review.
- Real keyboard, system-bar, safe-area, gesture navigation, and large-font testing.
- Runtime Firebase initialization, FID, push-device sync, permission, foreground/background/tap lifecycle, and actual FCM delivery.
- AI Chat, AI History, Voice AI, PDF Report, Email Report, and Share Report remain unimplemented as carried from Phase 14.

## Next action

Connect an authorized Android device with USB debugging, rerun this checklist, and record actual screen observations before treating Phase 15 as complete. Once the runtime gate passes, Phase 16 should define the AI Assistant backend contract and safe provider architecture (`Flutter → HepaSense backend → AI provider`), never a provider secret embedded in Flutter.
