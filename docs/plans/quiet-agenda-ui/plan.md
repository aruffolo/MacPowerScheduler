# Quiet Agenda UI plan

## Plan control and scope

- Revision: `R2`, approved by the maintainer's selection of Deep Sapphire and “apply, update tests then commit” on 2026-09-28; DEC-1/2 layout and behavior preserved, DEC-3 replaces only the accent palette.
- Execution mode: supervised phased execution. The existing completion/validation proposal is accepted; no Goal mode or live-operation authority is added.
- Sources: [prompt](prompt.md), [decisions](documentation.md), [progress](progress.md), [runbook](implement.md), [repository rules](../../../AGENTS.md), [central architecture](../../architecture/overview.md).
- This feature set owns the UI redesign. Initial-release R2 and its open operational gates remain intact. IDs here are scoped to this folder.
- Increment the revision for material scope/contract/validation/guardrail changes and obtain approval of the changed fields. Routine evidence updates do not change revision.

## Goal suitability

**Optional; supervised execution recommended.** Model tests and snapshots provide useful iteration signals, but fidelity and accessibility require visual/manual judgment. Proposed progress means passing phase gates and closing observed mismatches; failed evidence selects the owning defect and the smallest relevant recheck. Assume the documented macOS/toolchain fixture environment and configured signing remain available. No live mutation is implied. The user can choose Goal mode later; no operational Goal extension is active.

## Completion contract

- Outcome: `OUT-1`/`OUT-2`, `SC-1`–`SC-6`. A working concept-06 screen plus Settings and setup states, with preserved scheduling semantics and evidence-backed visual fidelity.
- Proof: production-view snapshots, matched reference comparison, model regressions, actual non-mutating window/keyboard/accessibility checks, both full repository suites, review/simplification and a final receipt. Generated concepts and compilation alone do not prove completion.
- Preserve: all `CON-*`; initial-release daily-pair, account-consent, stale-draft, replacement, readback and one-time-event behavior. All existing public CLI/helper contracts remain unchanged.
- Boundaries: App window setup, PowerScheduleUI views/model/platform presentation seam, affected tests/coverage classification and UI documentation. No new module/dependency, privilege-policy changes, host mutations, publication or pushes; a local UI commit is now authorized. Scope-expanding discoveries require a decision.
- Iteration: map each mismatch/failure to `SC-*`/`REG-*`, fix the owning code, rerun the focused check, then repeat invalidated phase/final gates. Never silently change the target image or expected behavior to obtain a pass.
- Blocked stop: record the exact missing dependency, unresolved design conflict, unavailable manual environment or failed gate; continue independent work. Resume dependent work only after the prerequisite is satisfied. Do not convert a blocked gate into a pass.

## Validation contract

Unit tests apply to readiness/state/action decisions; production SwiftUI rendering uses snapshots, and window behavior uses manual checks. Existing test-only SnapshotTesting and Swift Testing remain the only test frameworks. No app UI automation target is introduced.

Use the pinned environment from [testing procedures](../../testing/README.md): Intel macOS 15.7.4, Xcode 26.3 / Swift 6.2.4, synthetic readers/helper replies, UTC Gregorian calendar, fixed locale and scale, no animation. Record the actual environment. Freeze new reference dimensions through `P0-T3` before production work. Add a 24-hour synthetic reference fixture to match the concept without forcing real users into that locale. Retain existing locale-sensitive coverage.

Focused checks follow affected edits; phase gates precede advancement; Hardening re-evaluates the actual diff; final checks run after the last relevant change. Store command, exit status, timestamp, code state, fixture, result and limitations in `progress.md`. Classification changes in `Tools/unit-coverage-scope.json` must include every new production file with justified rendering/platform exclusions; deterministic state belongs in the measured scope.

### Regression impact

| ID | Preserved surface and consumers | Existing coverage / gap | Required validation | Owner |
| --- | --- | --- | --- | --- |
| `REG-1` | Draft/current distinction, all toggle combinations, verified apply, conflict and failed-read recovery | ModelTests, InitialModelTests, snapshots; add pictured dirty fixture | `VAL-MODEL`, `VAL-SNAPSHOT`, `VAL-INTERACTION`, `VAL-CHECKS` | P2 |
| `REG-2` | Registration/approval, signing, account grants, removal, busy exclusion | ModelBoundaryTests/ModelTests; add typed setup transitions and Settings visibility | `VAL-MODEL`, `VAL-SNAPSHOT`, `VAL-INTERACTION`, `VAL-CHECKS` | P1 |
| `REG-3` | Locale/timezone, disabled fields, light/dark, focus, sheet dismissal, resizing | Calendar unit test and existing snapshots; manual interaction gap | `VAL-SNAPSHOT`, `VAL-VISUAL`, `VAL-INTERACTION` | P2 |
| `REG-4` | Non-daily summaries/replacement, one-time-event preservation, shared CLI/helper contracts | Core/service/CLI tests and replacement snapshot; preserve dialogs | `VAL-MODEL`, `VAL-SNAPSHOT`, `VAL-INTERACTION`, `VAL-CHECKS` | P1/P2 |
| `REG-5` | Foreground refresh, readable failures and retained explanatory guidance | Existing lifecycle wiring and model tests; review new sheet ownership | `VAL-SNAPSHOT`, `VAL-INTERACTION`, `VAL-DOCS` | P2 |

### Validation definitions

- **`VAL-0` — Baseline and technical readiness.** Purpose: both; covers all SC/REG prerequisites. Existing tests plus read-only discovery. Inspect the source/test paths named in documentation; run `swift test --package-path Package --filter PowerScheduleUITests` and `make test-snapshots` before implementation. Expect existing behavior/references to pass; separate environmental/pre-existing failures. `P0-T3` records exact image/content bounds, anchor coordinates, default/minimum window sizes and new fixture dimensions, plus the typed setup/action truth table derived from SDK/source. No vague geometry or readiness placeholder may enter P1. Environment: current pinned host and unchanged synthetic fixtures. Cadence: P0; repeat if inputs change.
- **`VAL-MODEL` — Decisions and regressions.** Purpose: both; covers SC-2/3/4, REG-1/2/4. Existing/new unit tests in `Package/Tests/PowerScheduleUITests/`; command `swift test --package-path Package --filter PowerScheduleUITests`. Preserve existing cases. Add table-driven checking/unsigned/not-configured/approval/ready/unavailable states; transitions after refresh/register/revoke/remove/failure; no automatic registration, grant or write on refresh or sheet presentation. Assert unavailable is not success, failed actions retain errors, drafts survive Settings and refresh, busy actions do not overlap, and system-settings routing has no privileged side effect. Use fake platform/helper counters; never call live mutation APIs. Baseline existing tests pass; new cases initially expose absent presentation state. Cadence: P1/P2 edits, phase exits, Hardening/final through full suites.
- **`VAL-SNAPSHOT` — Production presentation states.** Purpose: both; covers SC-1/3/4/5, REG-1–5. Extend `Package/Tests/PowerScheduleSnapshotTests/ScreenSnapshots.swift`, splitting fixture/render helpers only as needed. Commands `make record-snapshots` for intentional recording, followed by individual PNG inspection and `make test-snapshots`. Recording's expected failure is not verification. Preserve the ten current scene meanings in both appearances; add clean configured state, concept dirty draft (saved 08:00/23:00, draft 07:30/23:00), setup needed, helper connection failure, and Settings content for ready automation off/on, approval, read-only and error. Render the actual shared Settings view, not a test facsimile; stable busy presentation can be captured but animation is a manual check. Sizes from VAL-0 include reference and minimum content area; long-message/time-format fixture must expose clipping. Mutations remain rejected by snapshot fakes. Baseline old references pass; visual changes require reviewed new baselines with unchanged tolerance. Cadence: P1/P2, Hardening/final.
- **`VAL-VISUAL` — Concept fidelity.** Purpose: feature; covers SC-1/5, REG-3. New visual comparison using rendered production content and the immutable concept image. Measure comparable app/content regions at one scale; compare header/gear placement, sun/moon colors/circles/connector, font hierarchy, time-field and switch alignment, section divider/saved rows, footer tint/height and Apply position. Use side-by-side captures or an overlay with native chrome assessed separately. Record every discrepancy and its resolution; no material unapproved mismatch may remain. Inspect light reference, dark adaptation, resize/long text. Raster antialiasing is not functional proof. Environment/sizes: frozen by VAL-0. Cadence: P2 and after visual fixes, Hardening/final.
- **`VAL-INTERACTION` — Real UI wiring and accessibility.** Purpose: both; covers SC-2–5, REG-1–5. New manual non-mutating checks of the signed Debug app built by `make build`: opening/closing gear sheet, repeated presentation, keyboard Tab/Shift-Tab navigation, accessible labels/values in VoiceOver, time-field edits and independent switches, scrolling/minimum/resized window, foreground refresh and draft retention. Verify destructive/automation confirmation presentation and cancel only when reachable in the authorized environment; never approve mutation. Code/model checks cover injected action dispatch. Native macOS authorization, actual service approval and privileged apply/removal remain separately gated by initial-release VAL-HELPER/VAL-GUI; do not fabricate coverage for unreachable live states. Safe synthetic captures cover their presentation, not OS integration. Evidence must identify any inaccessible manual path. Cadence: P2 and final, repeat affected interactions after fixes.
- **`VAL-CHECKS` — Required broad gates.** Purpose: both; covers SC-2–6, REG-1–5. Existing `make check` and `make test-strict`, run sequentially with preserved exit codes on the documented host. Expect lint, fresh >=95% scoped deterministic coverage, adapters/tooling/snapshots, Debug build/static analysis and read-only CLI smoke to pass. No fallback, silent skip, tolerance increase, signing weakening or baseline auto-recording. Cadence: Hardening and final; reuse only an identical final-state run explicitly recorded as such.
- **`VAL-DOCS` — Contract, guidance and evidence.** Purpose: both; covers SC-6, REG-5. New bounded review of this folder, README setup/screenshot guidance, docs/testing reference dimensions and coverage classification. Check local Markdown links, named Make targets, no stale button placement, and `git diff --check`; record UI release-note context locally, update changelog only at authorized landing. Preserve concurrent README edits. Cadence: planning checkpoint, P2, final.
- **`VAL-HARDEN` — Review and simplify.** Purpose: both; covers all SC/REG. Inspect the complete owned diff and direct/indirect consumers, invoke `review-and-simplify-changes`, fix actionable findings, and re-review the simplified result. Verify `UI-*`/`AG-*` individually and rerun VAL-MODEL/SNAPSHOT/VISUAL/INTERACTION/CHECKS as affected. Existing module/security boundaries and test realism are mandatory. Cadence: P3 and after material final fixes.
- **`VAL-FINAL` — Reconcile delivery.** Purpose: both; covers all SC/REG. Full owned-diff and repository review; require current passing VAL-MODEL/SNAPSHOT/VISUAL/INTERACTION/CHECKS/DOCS/HARDEN evidence, no major open findings, complete guardrail ledger, and a receipt with remaining initial-release operational limits explicitly separated. No feature completion with a required UI check unexecuted. Cadence: P4 after last change.

## Integrity and anti-gaming contract

- `UI-1` Required-check integrity: do not weaken, delete, skip, or falsely report required checks.
- `UI-2` Behavior integrity: do not change expected behavior to match faulty code or silently reduce approved scope.
- `UI-3` Production-path integrity: do not hardcode expected output, bypass production paths, or hide errors.
- `UI-4` Validation realism: do not substitute mocks, fixtures, or screenshots for required production implementation or realistic validation.
- `UI-5` Environment integrity: do not use unrealistic environments or data to claim completion.
- `UI-6` Evidence integrity: do not treat compilation, partial behavior, or unevidenced claims as completion.
- `UI-7` Regression-evidence integrity: do not claim regression safety solely from new-feature tests, happy-path tests, coverage percentage, compilation, or an unrelated passing suite.

- `AG-1`: Do not implement a static image, fixed times/status, or a second fake UI solely for snapshots. Verify shared production views and live bindings in VAL-MODEL/SNAPSHOT/INTERACTION; applies P1–P4.
- `AG-2`: Do not replace the approved visual with a merely similar design or overwrite the reference to match code. Verify image hash, measured comparison and discrepancy ledger in VAL-0/VISUAL; applies all phases.
- `AG-3`: Do not infer automation consent from helper readiness, guess setup state from strings, hide errors behind Settings, or remove confirmation/limitations copy to match the clean image. Verify source, state tests and presentation across VAL-MODEL/SNAPSHOT/INTERACTION/DOCS; applies P1–P4.
- `AG-4`: Tests/screenshots never mutate the host, and no signing or authorization check is weakened. Verify mutation-rejecting fixtures, commands and full diff in VAL-0/CHECKS/HARDEN/FINAL; applies all phases.
- `AG-5`: Do not auto-accept changed images, drop scene coverage, raise tolerances, or change the coverage denominator for convenience. Verify explicit recording/review/verification and new-file classification in VAL-SNAPSHOT/CHECKS/HARDEN; applies P1–P4.

## Checkpoint, recovery and retention contracts

Update progress after meaningful tasks, every validation and before stopping; update decisions when interpretation changes. Resume Here must identify revision, phase/task, exact next action, known-good state, blockers and unlock conditions. Use durable file checkpoints; repository policy prohibits commits without explicit authorization. No PR/push/release is authorized.

At resume, compare Git state and relevant source with retained evidence; rerun VAL-0 when stale. Keep failures visible. A compiler-cache sandbox failure can be retried with scoped approval using the same test; an assertion/snapshot failure requires diagnosis. Do not delete caches or user changes as a shortcut. Recover only owned edits from known checkpoints through reviewable patches; never reset/restore the working tree. No data migration is needed. Stop conflicting edits or missing required environments and identify the exact unlock condition.

Durable evidence: selected concept, this five-file set, reviewed test reference images and concise receipts. Temporary logs/comparison captures belong in ignored `.build/QuietAgendaUI/`; retain until final review and any failure is resolved. Inspect captures for private data, retain synthetic-only evidence in source, and do not upload anything. Cleanup is optional after handoff and limited to identified task-generated disposable artifacts; record cleanup if performed. No raw diagnostics/credentials/signing identities in durable notes.

## Phases and traceability

All phases obey UI-1–UI-7. Phase exits require the referenced evidence, not only code changes.

### P0 — Discovery and Baseline

- Outcome: code/test baseline, exact reference calibration and typed setup mapping ready for delivery. Prerequisite: readable repo/reference and planning authorization.
- `P0-T1`: inspect applicable docs/rules, presentation/model/platform/test seams and working tree; record accepted design and preserved contracts.
- `P0-T2`: run and retain existing model/snapshot baseline; classify environment failures separately.
- `P0-T3`: resolve Q-1/Q-2 by measuring reference geometry and inspecting SDK/state/error mapping; freeze visual tokens, fixture dimensions and setup/action cases before P1. This is a bounded evidence spike, not permission to mutate system settings.
- `P0-T4`: reconcile execution proposal with the user; keep explicit design decisions approved, request approval only for materially inferred/changed criteria. Regenerate runbook for P1 once implementation is requested and prerequisites pass.
- Covers all SC/REG prerequisites; validation VAL-0, VAL-DOCS; guardrails AG-2/4. Risks: missing visual/platform facts; recover with read-only inspection. Exit: exact validations, measurements and action mapping recorded, baseline green, execution scope settled. Checkpoint in progress; unresolved prerequisites block dependent delivery.

### P1 — Settings and setup states

- Outcome: the gear opens working Settings, and main-screen setup presents the correct action. Prerequisite: P0 exit and implementation authorization.
- `P1-T1`: implement minimal typed readiness presentation and platform seam as justified by Q-2; add deterministic transition/action regressions first. Preserve existing authorization and state ownership.
- `P1-T2`: extract native Settings content, share the model, relocate grant/removal confirmations, expose failures in the visible sheet, and add the contextual main banner plus gear. Keep old paths only until replacement wiring is verified, then remove superseded permission layout.
- `P1-T3`: add/review Settings and banner snapshots and check sheet open/close/cancel behavior without privileged execution. Update coverage classification for any new files.
- Covers REQ-3/4/5, SC-3/4/5, REG-2/4/5; VAL-MODEL/SNAPSHOT/INTERACTION; AG-1/3/4/5. Risks: stale readiness or hidden failure; return to state mapping rather than string parsing. Exit: accepted permission paths remain reachable, correct contextual actions, no draft loss or implicit grants, focused evidence passes. Checkpoint in progress; missing fixture/interaction environment blocks corresponding exit.

### P2 — Faithful Quiet Agenda screen

- Outcome: production scheduling screen matches the selected design and behaves correctly across states. Prerequisite: P1 exit.
- `P2-T1`: implement measured agenda layout, native titlebar gear, symbol circles/connector, aligned switches/time fields, saved rows, separator and fixed bottom action area; adapt window sizing without drawing fake macOS chrome.
- `P2-T2`: integrate live clean/dirty/busy/error/conflict/read-only/replacement states, refresh/reload, disabled controls, full limitations access, locale/timezone and dark/resize/accessibility behavior. Keep Apply semantics and existing shortcuts.
- `P2-T3`: extend/review snapshots, compare the reference, resolve discrepancies, perform non-mutating interaction checks, update README/testing guidance while preserving prior edits.
- Covers REQ-1/2/5/6, SC-1/2/5/6, REG-1/3/4/5; VAL-MODEL/SNAPSHOT/VISUAL/INTERACTION/DOCS; all AG. Risks: superficial fidelity, hardcoded state, clipped native controls; fix measured discrepancies in owned views. Exit: no material unresolved mismatch, full state coverage and focused proof. Checkpoint in progress; material design conflict goes to user before altering the target.

### P3 — Hardening

- Outcome: reviewed, simplified, behavior-preserving diff with no major actionable finding. Prerequisite: P1/P2 exits.
- `P3-T1`: recompute actual regression surface and inspect affected consumers/failure paths; close gaps, invoke review-and-simplify-changes, fix and re-review.
- `P3-T2`: run broader required gates and verify all guardrails against actual evidence.
- Covers all SC/REG; VAL-HARDEN/CHECKS plus affected focused gates; all AG. Recover failed evidence in its owning phase and repeat invalidated checks. Checkpoint findings/fixes/evidence; exit only after review, simplification, re-review and green checks. Missing manual evidence remains an explicit blocker, not a waived requirement.

### P4 — Final Verification and Handoff

- Outcome: locally reviewable complete redesign and receipt. Prerequisite: P3 exit.
- `P4-T1`: inspect full owned diff; run final required gates on final code and refresh visual/manual evidence invalidated by changes.
- `P4-T2`: reconcile every SC/REG/VAL/UI/AG, decisions/questions/deviations, docs, pending external operational limits and repository state; write completion receipt.
- Covers all SC/REG; VAL-FINAL; all AG. Return failures to owning phase and re-harden; checkpoint exact evidence and state. Exit: every required UI criterion proved, no major unapproved deviation, limitations truthful, files preserved. Local commit authorized by R2; no push/release.

| Criteria/risk | Delivery tasks | Proof | Guardrails |
| --- | --- | --- | --- |
| SC-1, REG-3 | P2-T1/T3 | VAL-VISUAL/SNAPSHOT/INTERACTION | UI-1–7, AG-1/2/5 |
| SC-2, REG-1/4 | P1-T1/T2, P2-T2 | VAL-MODEL/SNAPSHOT/INTERACTION/CHECKS | UI-1–7, AG-1/3/4/5 |
| SC-3/4, REG-2 | P1-T1/T2/T3 | VAL-MODEL/SNAPSHOT/INTERACTION | UI-1–7, AG-1/3/4 |
| SC-5, REG-3/5 | P2-T2/T3, P3-T1/T2 | VAL-SNAPSHOT/INTERACTION/CHECKS/HARDEN | UI-1–7, all AG |
| SC-6, REG-5 | P2-T3, P4-T1/T2 | VAL-DOCS/HARDEN/FINAL | UI-1–7, all AG |

## Deferred backlog

- `DEF-1`: Alternate concepts, new scheduling features and platform modernization are outside the selected redesign; revisit only with a new request.
- `DEF-2`: Live helper/account/physical/release validation remains in initial-release R2, with its existing approvals and gates. This is an ownership boundary, not a declaration that those checks passed or a waiver of UI interaction evidence.

## Delivery protocol

Read current plan/progress/runbook and decisions before each session. Execute one phase at a time, replace technical unknowns with evidence before dependent work, preserve failed results, and complete Hardening/Final Verification before declaring feature completion. Draft plan readiness is not feature completion.
