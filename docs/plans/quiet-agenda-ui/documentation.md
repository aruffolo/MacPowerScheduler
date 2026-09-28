# Quiet Agenda decisions and discoveries

## Accepted decisions

### DEC-1 — Concept 06 is the design

Accepted by the maintainer on 2026-09-28: “I like 6 … I want it 1:1.” Use the [Quiet Agenda image](../../design/ui-concepts/06-quiet-agenda.png), SHA-256 `599a61ac8fae15cb471f563b1e4f9f56e1a1086f624cb605e0b34c5e1d398e30`. This supersedes the assistant's recommendation of concept 01; no alternative concept is an implementation reference. Revisit only on user direction. Related: `REQ-1`, `SC-1`, `P2`.

### DEC-2 — Setup banner and Settings sheet

Accepted by the maintainer's “ok” after the placement discussion. Required setup appears beneath the main introductory text with the appropriate action. Ready state has no setup banner. The top-right gear opens a native Settings sheet with status/setup, automation grant/revocation, and helper removal. Authentication/approval remains system-managed. This preserves discoverability without making maintenance controls part of the daily editor. Related: `SC-3`, `SC-4`, `P1`.

## Implementation interpretations

### Icon follow-up — Precision Power

The maintainer selected option 2 from the revised Apple-inspired icon proposals and supplied the resized artwork in `AppIcons.zip`. The canonical asset is `App/AppIcon.icon`, with the archive's unmasked 1024px sRGB artwork and Icon Composer configuration. Xcode generates the mask and earlier-macOS renditions; the obsolete teal drawing script and legacy catalog are removed. This is flattened artwork in an Icon Composer bundle, not separately authored glass layers.

### INT-1 — Faithful, functional reproduction

Grounded implementation interpretation: match the selected app window, excluding the image's exterior framing. Derive point-space measurements before implementation; an approximately 580-point-wide window is a starting measurement, not permission to redesign. Use live model state instead of freezing the pictured times or permanently showing “Unsaved changes.” Preserve native input, locale formatting, keyboard access, and dark mode required by repository policy. Any material mismatch with the selected style requires an explicit decision; an approximate resemblance is not the acceptance target. Related: `P0-T3`, `VAL-VISUAL`.

### INT-2 — Keep model ownership and one source of truth

Low-risk, reversible implementation choice grounded in the existing architecture: main screen and Settings share the same `ScheduleModel`. View-local state owns sheet/confirmation presentation only. Expose typed setup presentation state from the model/platform boundary; never branch on English `permissionDescription` strings. Preserve the existing privileged request path and busy guards. Related: `DISC-2`, `P1-T1`, `REG-2`.

### INT-3 — Define supplementary states in the same style

Settings, pending setup, clean/dirty footer, busy, errors and conflicts are not fully illustrated in the image. Use the accepted placement and existing native sheet/dialog patterns, matching concept 06's spacing, palette and typography. Settings errors must remain visible while the sheet is open; do not leave failure feedback hidden behind it. Full power/FileVault limitations remain available even if the main screen uses the reference's shorter shutdown note. Related: `SC-3`–`SC-5`.

## Repository discoveries

### DISC-1 — Existing actions and entry points

`ScheduleContentView` currently owns the complete form, current-system readout, permission buttons, errors and three confirmation dialogs. `PowerScheduleView` owns one model and refreshes initially/on foreground. `App/MacPowerSchedulerApp.swift` configures a 560 × 710 default window. These are the primary presentation surfaces; no new scheduler or backend is needed.

### DISC-2 — Readiness needs structured presentation

`ScheduleModel.refreshPermission()` sets `helperReady`, `signingReady`, automation status and a prose description. `SchedulingPlatform` exposes `requiresApproval`, but the view cannot distinguish all setup/recovery states through a typed value. `MacSchedulingPlatform` already reads `SMAppService` status. A bounded platform-status mapping can distinguish initial registration, approval, ready, read-only and connection failure without treating every helper failure as missing setup. Technical resolution belongs to `P0-T3`; no user interview is needed to look up platform states.

### DISC-3 — State preservation already has useful coverage

`PowerScheduleUITests` covers verified apply, grants/removal, authorization denial, busy overlap, signing loss, unsupported-schedule replacement, read failures, dirty drafts, external edits and injected calendar behavior. `ScreenSnapshots` covers ten scenes in two appearances with mutation-rejecting fixtures. Missing redesign coverage includes the gear/sheet, setup-state mapping, the pictured nonconflicting dirty draft, and the new layout at calibrated sizes. Execution results belong only in `progress.md`.

### DISC-4 — Snapshot fidelity is environment-specific

The documented baseline is Intel macOS 15.7.4, Xcode 26.3 / Swift 6.2.4, UTC Gregorian, `en_US_POSIX`, 1× captures, no animations. Existing snapshots render 560 × 800 points of content, excluding a native titlebar. The selected raster includes titlebar and exterior framing; direct full-image pixel equality would be a false test. Calibration must separate content geometry, system chrome and image framing before recording new references.

## Open technical questions

| ID | Classification | Resolution and exit condition | Status |
| --- | --- | --- | --- |
| `Q-1` | Technical: reference calibration | Calibration below freezes reference-space dimensions and anchors. | Resolved |
| `Q-2` | Technical: setup mapping | SDK inspection and truth table below define the mapping. | Resolved |

No unresolved product decision currently requires a discovery interview. The only approved visual change to concept 06 is the Deep Sapphire palette in DEC-3; no feature-specific guardrail exception is approved. No Goal-mode execution has been requested.

## P0 calibration and state mapping — 2026-09-28

The 1402 × 1122 image's app window occupies approximately x306–1096, y84–1066. Content starts at y135; exterior framing is excluded. Normalize the 790-pixel window width to 580 points (scale 1.362). Content target: 580 × 684 points; native titlebar approximately 38 points. Main horizontal inset 46 points; header top 28, title 34 bold, subtitle 16. Agenda icon centers x72 at content y142 and y306, diameter54; connector lies between their circles. Text column starts x134; switches end at x534. Title22, detail15, time22; first/second event start y116/y280. Saved separator y454; saved header y473, helper text y496, row centers y539/y573. Footer starts y604, height80; Apply approximately166 ×40 points. Native chrome is inspected separately. Default content size580 ×684; minimum520 ×620 with scrolling; resize fixture760 ×800; minimum fixture520 ×620; Settings fixture520 ×580. The 24-hour reference fixture uses en_GB/UTC; retain en_US_POSIX baseline meaning for existing scenes. Optical adjustments must improve measured fidelity, not redesign it.

| Condition, in precedence order | Presentation | Primary action |
| --- | --- | --- |
| No permission result yet | Checking scheduling access | None |
| Signing preflight fails | Read-only development build | None; signing explanation |
| Checked helper status succeeds | Ready; no main banner | Settings management only |
| Status call fails; registration notRegistered | Setup needed | Enable Power Scheduling |
| Status call fails; registration requiresApproval | Approval needed | Open System Settings |
| Status call fails; registration enabled | Unavailable, preserve error context | Retry read/status |
| Status call fails; registration notFound/unknown | Helper could not be located | Retry plus installation guidance |

Opening System Settings is injected at the existing platform boundary and triggered only by a button. Refresh never registers, grants or changes schedules. Registration/removal results update readiness only through observed state; settings and main screen share one model. Automation remains independent of readiness. A clean footer describes saved state; a dirty footer uses the reference's Unsaved changes treatment. Apply retains its existing model contract.

## Implemented presentation — 2026-09-28

`ScheduleContentView` now composes `AgendaEventRow`, `SavedScheduleView`, `ScheduleFooter` and the shared `ScheduleSetupBanner`. Settings uses the same model, preserving draft ownership and existing confirmation/action methods. Typed `SchedulingSetup` determines action and message; `HelperRegistration` resides with the injected platform protocol. Unknown automation status is explicitly unavailable; an unrepresentable saved schedule uses an existing-schedule footer rather than claiming the pictured daily draft is saved.

`AgendaTimePicker` bridges native `NSDatePicker`: SwiftUI's macOS picker ignored the reference font size. The bridge preserves locale/calendar/timezone, enabled state, native segment editing/stepper, and an explicit accessibility label. It owns only a binding coordinator; the model continues to own schedule decisions. The rounded field surround, spacing and typography follow the measured image. Native switch/stepper glyphs and antialiasing remain OS-rendered, not raster substitutes. Main errors/conflict guidance appear above the editor so they remain visible at minimum size; supplementary states retain scrolling.

Release-note context for an authorized landing: replaces the old form with Quiet Agenda, adds contextual setup/recovery actions and a gear-accessed Settings sheet, and clearly separates unsaved daily edits from actual saved events. README setup/automation/removal guidance and testing fixture documentation reflect this placement. No changelog landing or release is performed by this task.

### DEC-3 — Deep Sapphire accent (R2)

The maintainer selected blue option 1 and explicitly requested applying it, updating tests, and committing. Use #2457A6 for the primary button and light-mode accent, #8EB5F1 for dark-mode accent text/switch tint, #EDF2FA for the light footer and #1B273B for the dark footer. The warm neutral surface and sun/moon colors stay unchanged. This supersedes the original concept’s teal hue only; geometry, controls and scheduling semantics remain the accepted design. White button text contrast is approximately 7.03:1 against the specified sapphire fill. Native switches retain platform rendering.
