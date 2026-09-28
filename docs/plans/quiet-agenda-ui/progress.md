# Quiet Agenda UI progress

## Resume Here

- Status: implementation delivered in the working tree; automated gates passed; attended accessibility/keyboard validation remains partial.
- Plan revision observed: `R2`; execution mode: supervised, no Goal mode.
- Active phase/task: `P4` / final receipt, with open `VAL-INTERACTION` evidence from P1/P2.
- Next action: attended VoiceOver speech and Escape dismissal checks on the signed build; reconcile SC-4/5 and final gate only after that evidence exists.
- Blockers: native automation returns contradictory/stale focused-window receipts for keyboard events; screenshot observations verify some effects, but not Escape dismissal or spoken VoiceOver behavior. Destructive confirmation clicks remain outside authorization under ai-rules/tooling.md. Live operations remain separately gated.
- Validated source: uncommitted implementation over `8cbb629`; final code/tests/reference hashes retained in `.build/QuietAgendaUI/validated-source-sha256.json`. Both required full suites passed; details below.
- Working tree on entry: existing README.md, initial-release implement/progress edits, CONTRIBUTING.md and concept files. Preserved prior work; README received only the additional UI guidance changes described below.
- Updated: 2026-09-28.

## Phase status

| Phase | Status | Exit evidence / next prerequisite |
| --- | --- | --- |
| P0 Discovery and Baseline | completed | E-0–3 baseline plus approved calibration/state mapping; user authorized execution |
| P1 Settings and setup states | implemented; validation partial | Model and Settings snapshots pass; native opening/Done and draft retention verified; Escape/attended confirmation evidence open |
| P2 Faithful Quiet Agenda screen | implemented; validation partial | All 50 snapshots reviewed/passing; reference comparison, time editing, Tab/Shift-Tab and narrow-window scrolling verified; VoiceOver speech open |
| P3 Hardening | review and automated checks completed | Four read-only review roles; accepted fixes re-reviewed; both full suites pass; no material code finding remains |
| P4 Final Verification and Handoff | partial; attended check outstanding | No full-completion claim while required interaction evidence remains open |

## Execution log

### 2026-09-28 — P0-T1/T2 planning checkpoint

Completed repository/code/test inspection and fresh focused baseline. Created the five-file R1 execution proposal, retaining the accepted image and permission placement. No production code, snapshot reference, existing release-plan file, helper or system setting changed. No commit or external action. Technical questions are owned by documentation; remaining tasks are in Resume Here.

## Validation evidence

### E-0 — Source and reference discovery (VAL-0, partial)

- Tools: targeted reads, Git status/log, reference SHA-256, Makefile/coverage manifest inspection.
- State: source `8cbb629` plus pre-existing documentation/concept edits; platform macOS 15.7.4, Swift 6.2.4, Intel. Read existing architecture and initial-release R2 contracts; retain their original operational evidence scope.
- Findings are in DISC-1–4; image identity is in DEC-1. No claim of completed reference calibration or typed readiness mapping yet.
- Retention: this summary and source references; no sensitive raw diagnostics.

### E-1 — Focused model baseline (VAL-0)

- Date: 2026-09-28. Command: `swift test --package-path Package --filter PowerScheduleUITests`.
- First attempt: exit 1 before tests; compiler cache outside sandbox was not writable. Log `.build/QuietAgendaUI/baseline-model.log`.
- Same command retried with approved compiler-cache access: exit 0, **19 tests in 3 suites passed**. Log `.build/QuietAgendaUI/baseline-model-retry.log`.
- Fixture: existing fake platform/helper/readers, no host mutations. Scope: pre-change model behavior; not a full-suite or new-feature pass.
- Retention: ignored logs retained under the plan policy; concise result durable here.

### E-2 — Existing visual baseline (VAL-0)

- Date: 2026-09-28. Command: `make test-snapshots`.
- First attempt: exit 2 before tests for the same compiler-cache sandbox restriction. Log `.build/QuietAgendaUI/baseline-snapshots.log`.
- Same command retried with approved cache access: exit 0; **20 scene/appearance cases passed** in ScreenSnapshots. Log `.build/QuietAgendaUI/baseline-snapshots-retry.log`.
- Fixture: unchanged ten scenes, two appearances, 560 × 800 content, 1×, UTC Gregorian, en_US_POSIX. No recording or reference edits, no helper mutations.
- Scope: existing UI baseline only. Retention: ignored logs retained; reviewed old references remain unchanged.

### E-3 — Plan audit (VAL-DOCS)

- Passed, 2026-09-28: standard-library Python audit confirmed all five core files and local Markdown links, the seven universal integrity constraints verbatim from the installed template, five lifecycle phases, nine validation definitions, R1/P0/P0-T3 runbook alignment, mandatory full-suite/coverage gates, balanced code fences and files below 500 lines. `git diff --check` passed for the existing tracked diff; new plan files were separately inspected.
- Manual plan review checked SC-1–6 and REG-1–5 mappings, preserved confirmation/security/draft contracts, actual production-view snapshot requirements, and honest separation of UI proof from initial-release operational gates.
- SDK/source follow-up confirmed four ServiceManagement statuses (not registered, enabled, requires approval, not found) and a macOS-13-available System Settings navigation API. Helper transport maps status unavailability and interrupted/timed-out calls to distinct errors. This narrows Q-2; the final presentation/action truth table remains P0-T3 work.
- Planning deliverable complete; no final implementation validation has run. `make check`/`make test-strict` remain required at delivery. No production edit, snapshot update, commit or push.

## Integrity and guardrail evidence

UI-1–UI-7 and AG-1–AG-5: automated/source/visual checks reconciled in E-4–8; attended interaction gap explicitly retained. No tolerance, coverage threshold, suite, signing policy, helper/CLI contract or privileged behavior was weakened. References were intentionally recorded and individually reviewed, followed by non-recording verification. Real production views render the fixtures; synthetic results are not claimed as live authorization or hardware proof. No host schedule/grant mutation, Git write or publication occurred. No approved exception to the final gate exists.

## Hardening and completion receipt

Implementation, actual-diff review, simplification and re-review completed; code and all automated gates pass. SC-1–3 and automated portions of SC-4–6 have evidence below. Full completion remains **unclaimed** because VAL-INTERACTION is partial. Initial-release authorization/helper/hardware/release gates remain separate and untouched. No commit, push or release.

### 2026-09-28 — P0 exit / P1 start

User authorized the proposed supervised implementation. Source baseline remains unchanged from E-1/E-2. Q-1/Q-2 are resolved in documentation using image measurement and installed SDK/source inspection. No contract scope change; R1 remains current.

### 2026-09-28 — P1 delivery checkpoint

Typed readiness, injected Settings routing, shared Settings sheet, banner and confirmations implemented. 21 model tests passed; 14 intentional Settings recordings reviewed in representative light/dark/error/approval states and verification passed. All reference images still require the final visual sweep. Debug build initially failed on one overlong source line; fixed without behavior changes and rebuild passed. Native signed app launched with configured signing; Command-comma opened Settings (observed accessible Done/automation/removal controls). Background keyboard receipt could not verify Escape against the sheet; use direct native AX actions for the remaining checks and retain that limitation until resolved. No permission action was invoked. Logs under .build/QuietAgendaUI; source mutation checks remain pending broad validation.

### E-4 — Implementation and focused regressions (VAL-MODEL)

2026-09-28; uncommitted UI implementation over the baseline. `swift test --package-path Package --filter PowerScheduleUITests` passed 21 tests in 4 suites, including table-driven registration/approval/ready/read-only/unavailable mapping, injected System Settings routing, draft preservation and no implicit grants/writes. Existing calendar, authorization denial, replacement, removal failure, busy overlap and read-failure recovery coverage remains. Busy exclusion now also covers the new setup action. Logs: `setup-tests.log`, `settings-build.log`, `agenda-build.log` under `.build/QuietAgendaUI/`. No real helper mutation was used.

### E-5 — Visual evidence (VAL-SNAPSHOT / VAL-VISUAL)

Final fixture set: 26 main, 14 Settings, 10 layout images, individually inspected in light and dark appearance. Reviewer passes inspected each family, and the main agent compared the reference, native fields, minimum-width rows, replacement and long-error views. Concept composition/anchors match the P0 calibration; the native switch/stepper glyphs and native chrome are OS-rendered. No material hosted-content mismatch remains. The 24-hour dirty fixture correctly shows draft 07:30 and saved 08:00, with saved shutdown 23:00. Existing en_US_POSIX cases retain 12-hour rendering.

Intentional recording reports expected snapshot failures; it is not counted as verification. Intermediate recordings exposed the undersized SwiftUI time control and a long error below the fold; replaced the control with native NSDatePicker and moved feedback above the editor. Added a minimum-width expanded fixture to expose both saved rows. One intermediate compile failed after adding a second toolbar item; corrected the missing ToolbarContentBuilder. Final recording: `reviewed-record-retry.log`, 50 expected recording issues; subsequent non-recording snapshot runs passed all 50 cases in both full suites, unchanged tolerance. Raw logs and native captures remain ignored; only synthetic reference PNGs are delivery artifacts.

### E-6 — Hardening and re-review (VAL-HARDEN)

Invoked `review-and-simplify-changes` with four read-only roles (reuse, quality, efficiency, clarity; the fourth followed after a slot became free). Main agent applied all accepted findings: shared the snapshot hosting pipeline, made unknown automation status explicit, distinguished an existing unsupported schedule in the footer, corrected fake connection-failure wording, and made long-error/minimum-row visual evidence observable. Re-review confirmed fixes and no residual material source/visual finding. Reviewed SwiftUI/AppKit ownership, platform routing, unchanged helper/CLI contracts, affected consumers and coverage classification. No model decisions moved into the native picker.

### E-7 — Required full gates (VAL-CHECKS)

2026-09-28, same macOS/toolchain fixture pin as baseline, final production/test/reference state retained in `.build/QuietAgendaUI/validated-source-sha256.json`.

- Initial `make check`: exit 2, LLVM export lacked the enum-only HelperRegistration.swift (no executable lines). Moved the enum beside SchedulingPlatform, removed only its now-deleted standalone-file classification, and reran the complete gate. No thresholds or expected-file enforcement relaxed. Log `make-check.log`.
- `make check`: **exit 0**. SwiftLint zero violations; fresh scoped deterministic coverage **1024/1047 lines, 97.80%** (UI 232/241, 96.27%; whole-package unit-only 44.25%, explicitly not the acceptance metric); safe adapter/tooling tests; all 50 snapshots; configured-signature Debug build and static analysis passed. Logs `make-check-retry.log`, `.build/Coverage/unit-avd9dsse/`.
- `make test-strict`: **exit 0**. 100 unit tests/15 suites, 4 adapter tests/2 suites, tooling tests, 50 snapshot cases/3 parameterized tests, Debug build and actual read-only CLI status/JSON-error/help smoke passed. Log `make-test-strict.log`. No fallback, auto-recording, helper registration or power mutation.

### E-8 — Native interaction evidence and remaining limits (VAL-INTERACTION)

Signed Debug app launched using configured signing. Native Settings opened with Command-comma; AX exposed Done, scheduling status, automation and removal controls. Done dismissed the sheet, and a startup-off draft remained off, dirty, and distinct from the still-saved startup. The startup time field became disabled while shutdown remained enabled. A foreground click selected the shutdown hour; a keyboard down-arrow changed only the draft hour, followed by Tab selecting minutes and Shift-Tab returning to hours. Screenshots—not the indeterminate command receipts—verified those changes. At a 520 × 658 total window (620-point content plus native chrome), scrolling exposed both complete saved rows above the pinned footer. All draft changes were discarded by closing only the task-launched app; Apply was never invoked.

Tool limitations: background key dispatch often returned stale or contradictory exact-window receipts; foreground key setup also failed focus confirmation. Each uncertain action was observed before proceeding. Escape dismissal and spoken VoiceOver output have **not** been verified. Accessibility-tree inspection confirmed named switches/date-time controls, enabled states, saved-row combined labels, Settings and Apply identifiers, but is not claimed as a VoiceOver speech test. No automation grant/revoke/removal control was clicked. Destructive confirmation checks need their separately authorized attended path; existing model tests and source review do not substitute for that path. These limitations keep VAL-INTERACTION and the final completion gate partial.

### E-9 — Documentation and guardrails (VAL-DOCS / VAL-FINAL partial)

README now points to the gear/Settings, setup banner, Saved on this Mac section, automation and helper-removal locations. Updated test documentation records all 50 fixtures and dimensions. Preserved pre-existing README material, CONTRIBUTING and initial-release planning edits; no initial-release gate changed. Relevant Swift sources formatted with the existing SwiftFormat configuration; final `git diff --check` passed. No new dependency, changed CLI/helper contract, signing weakening, live schedule/grant mutation, commit, push or publication. Final feature-completion claim remains withheld solely where required attended evidence is absent.

Final documentation audit: all local Markdown links in the feature plan, README and testing guide resolve; tracked whitespace check passes; all 70 retained production/test/reference hashes still match the state that passed both suites. Final signed-app native capture verifies centered title and top-right gear at the calibrated 580 × 722 total window (684-point content); system appearance/accessibility preferences are respected. No synthetic claim is made for that private native capture.

Final build gear click exposed the Settings sheet's Done and management controls in its native accessibility tree; Done dismissed it again. A final app-targeted Escape attempt was refused before dispatch by the native tool's foreground-intent requirement; earlier exact-window keyboard routes had unresolved focus receipts. Escape remains unverified. The validated app is left open at the calibrated window size with its real saved schedule and no test draft. The synthetic reference image is opened in Codex for review.

### R2 — Deep Sapphire / local commit authorization

User selected option 1 and authorized applying the palette, updating tests and committing. Target remains main; owner boundary is App/PowerScheduleUI presentation, its tests and UI documentation. The commit includes the previously authorized uncommitted Quiet Agenda implementation with this palette. Scheduler, CLI, helper authorization, signing and live host state remain unchanged. Unrelated README rewrite, CONTRIBUTING and initial-release planning edits remain outside the commit. Scope baseline: all UI production/test changes plus coverage classifications, concept references and this plan; file/LOC measurements are recorded in the review bundle rather than treated as scope caps. R2 alters only the approved colors and local Git authorization, not the unverified manual gates.

### R2 closeout evidence — 2026-09-28

Deep Sapphire applied exactly as DEC-3. `make record-snapshots` recorded 50 cases (expected recording exit failure); all 36 changed main/layout PNGs were individually inspected in light/dark, including enabled/disabled, dirty/clean, setup/unavailable, conflict/replacement, long error and resized/minimum fixtures. The 14 Settings PNGs are byte-identical to their prior reviewed references. Geometry and sun/moon colors are preserved.

Fresh final `make check` and `make test-strict` both exited 0. This includes 50 non-recording snapshot cases, 100 deterministic tests, safe adapters/tooling, Debug build, static analysis and read-only CLI smoke. Scoped unit coverage remains 97.80% (1024/1047 executable lines), UI 96.27%. Logs are under `.build/QuietAgendaBlue/` (`record.log`, `check.log`, `strict.log`). No suite, coverage classification, tolerance or signing policy was weakened.

Pre-commit command: installed `autoreview --mode local --engine codex`, run in an isolated checkout containing only the task-owned diff and a bounded README patch. Initial attempt refused binary diffs before model invocation; retained that failure in `autoreview.log`. The source lane then included an explicit manifest of final PNG hashes and their separate visual-review evidence. All original repository PNGs remained intact. Final `autoreview-source.log` / JSON: exit 0, no accepted/actionable findings, patch judged correct. No review-triggered code fix or rejected actionable finding.

`behavior-validator` / `peekaboo` palette pass used the prewritten `.build/QuietAgendaBlue/behavior-contract.md`, then only running-app images/accessibility and generated artifacts as evidence. Visible blue controls/footer, readable sun/moon/editor/saved rows, gear opening Settings and Done returning to the agenda passed. Enabled/disabled and dirty/error artifact probes passed. No mutation was invoked. Report: `behavior-report.md`; captures remain ignored. Existing VoiceOver speech, Escape and privileged-operation validation gaps remain out of this palette pass, not declared fixed. The latest built app is open with its actual saved schedule and no test draft.

Local commit scope is the complete authorized Quiet Agenda UI plus selected blue palette, its tests/references, concept/design and feature-plan docs, coverage classifications and relevant README/testing guidance. The prior README rewrite is preserved through partial staging; CONTRIBUTING and initial-release planning edits are excluded. No push, publication or live schedule/grant change is authorized or performed.
