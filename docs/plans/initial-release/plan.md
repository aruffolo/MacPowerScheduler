# MacPowerScheduler initial-release plan

## Plan control

- Revision: `R2`, approved 2026-09-27. User explicitly requested replacing app UI automation with snapshots and approved the discussed test-only Point-Free dependency.
- Status: **implementation complete; final release evidence reconciliation remains**. Current results and remaining gates are in [progress.md](progress.md#resume-here).
- Execution mode: supervised phased execution, authorized by the user’s request to start the plan end to end.
- Contract source: current user request, discovery answers Q1–Q10, and the user-authored portions of the shared conversation.
- Approval: product decisions `DEC-1`–`DEC-10` accepted; `INT-1`–`INT-3` and execution contracts accepted by the user’s end-to-end implementation request on 2026-09-27.
- Material revisions change scope, contracts, phases, guardrails, or validation; increment the revision, obtain approval for changed fields, and regenerate the runbook. Ordinary evidence updates do not change the revision.

## Scope anchors

- Stable intent and criteria: [prompt.md](prompt.md).
- Component architecture: [architecture overview](../../architecture/overview.md).
- Decisions and unknowns: [documentation.md](documentation.md).
- Canonical live state and executed evidence: [progress.md](progress.md).
- Active-phase instructions: [implement.md](implement.md).
- Rules: supplied personal instructions and the feature-plan-scaffold quality floor. No tracked project rules existed at discovery. Reference repositories are examples, not governing policy.

## Goal suitability

**Optional after approval.** Deterministic core/CLI tests and staged integration evidence could guide autonomous iteration, but signing, system approval, and physical power tests require user/environment participation. Supervised phases are equally suitable and are the proposed default.

Draft assumptions for considering Goal mode: progress means passing named phase gates and reducing known failures, not lines changed or test counts; failed evidence selects the owning defect/phase; macOS 15, Xcode, approved test fixtures, signing access, and attended hardware windows are real dependencies. Stop dependent work when those dependencies are unavailable. The user may choose supervised execution or request Goal mode with these limits. There is no operational Goal extension or active Goal in `R1`.

## Completion contract

- Outcome: `OUT-1`/`OUT-2` and all `SC-1`–`SC-10` from the prompt. A functioning app/CLI, verified narrow helper, physical startup evidence, and a release-ready artifact are required.
- Proof: mapped unit, process, signed integration, GUI, CLI, hardware, compatibility, packaging, review, and final evidence below. A written plan, compilation, or simulated schedule is not delivery completion.
- Preserve: `CON-1`–`CON-7`; all one-time events; non-target machine settings; accurate existing-state display; account authorization boundaries; global schedule changes made outside the app.
- Boundaries: work in this project only; reference repositories remain read-only. The user authorized end-to-end implementation. This enables code/build/read-only validation work, but does not silently authorize live schedule mutation, shutdown, installation, certificate/account changes, publication, or other external actions. Explicitly establish the test machine and maintenance window before disruptive checks.
- Iteration: attribute each failure to a named criterion/risk, use the smallest reliable reproduction, fix its root cause, re-run affected checks, then resume the phase gate. Do not make expected results follow defective behavior.
- Blocked stop: record exact missing input/credential/device/approval and unlock condition; continue independent authorized work only. Missing signing or physical evidence blocks release readiness, never becomes a pass. A demonstrated platform limitation requires explicit contract revision, not silent removal of the criterion.
- Completion boundary: local handoff/release readiness. Push, public repository creation, PR creation, release publication, and shipping remain separate authorizations.

## Validation contract

### Tooling and cadence

The commands below are now implemented; evidence and remaining gates live in progress. `P1-T1` created the documented tooling. Phase 0 uses read-only system tools and bounded spikes; phase-specific tools must exist and be inspected before their tests can pass. No production Delivery phase starts until its referenced validation definitions and fixtures are concrete.

- Swift Testing covers pure core, parser, authorization policy, editor, and CLI logic. Unit tests are applicable and required; mocks alone cannot prove root execution, peer identity, macOS approval, physical startup, or notarization.
- `make build`: `xcodebuild -workspace MacPowerScheduler.xcworkspace -scheme MacPowerScheduler -configuration Debug -destination 'platform=macOS' -derivedDataPath .build/DerivedData build`.
- `make test-unit`: `swift test --package-path Package --skip 'PowerSchedule(Adapter|Snapshot)Tests'`; named `--filter` runs support focused work. `make test-adapters` separately runs the safe process/filesystem suite; `make test-snapshots` runs the fixed-fixture SwiftUI images.
- User-requested supplemental gate (2026-09-27): `make test-coverage` requires >=95% executable-line coverage of the declared deterministic unit scope, with a fresh unit-only run. All production package files must be classified and exclusions justified; whole-package coverage remains visible. See [scope and rationale](../../testing/unit-coverage.md). This adds evidence without replacing any R1 integration, UI or hardware gate.
- `make coverage-report` re-renders selected-file LLVM HTML/text/JSON from verified saved inputs without tests; it is explicitly report reuse, not a new validation run. Fresh coverage remains mandatory in `make check`.
- `make test-strict`: unit, adapter, tooling and SwiftUI snapshot tests plus the built CLI's read-only subprocess contract. Preserve failure exit codes, with no fallback. R2 removes the app UI automation target and its runner provisioning; snapshots are the only automated visual UI suite.
- `make check`: SwiftLint using the TetrisMac app/package rules (user-requested tooling update on 2026-09-27), the scoped coverage gate, safe adapter/tooling/snapshot tests, build/static analysis and strict Swift concurrency diagnostics. Make target implementations must expose and document their underlying commands.
- `make build-universal`: Release configuration with `ARCHS='arm64 x86_64'`, `ONLY_ACTIVE_ARCH=NO`, and the selected deployment target. Verify all bundled executables and runtime libraries with `lipo`/Mach-O inspection. Compilation does not imply execution on the other architecture.
- Focused checks follow behavior changes; relevant feature and regression gates run at each phase exit. Hardening expands to the actual affected surface; final verification repeats approved gates against the release candidate.
- Pure/default tests never change the host schedule or install a helper. Real-system test scripts require explicit invocation, declared test scope, and user authorization. An absent opt-in must fail/skip only that separately reported manual gate, not report it as passed.
- Evidence in `progress.md`: validation ID, command/tool, timestamp, revision/state, environment, fixture, observed outcome, failure details, and retained artifact location. Keep contract definitions here instead of copying them into evidence.

### Initial regression impact

There is no pre-existing application suite. These risks concern real system consumers and the behavior introduced across phases; do not invent legacy app regressions.

| Risk | Preserved surface / consumers | Existing coverage | Required validation | Owning phase |
|---|---|---|---|---|
| `REG-1` | Global repeating pair; existing weekday/sleep/wake/restart entries and the other enabled side | None | `VAL-CORE`, `VAL-SYSTEM`, `VAL-HELPER`, `VAL-CLI` | P1/P2/P4 |
| `REG-2` | One-time events owned by macOS and other apps; unrelated power settings | None | `VAL-SYSTEM`, `VAL-HELPER`, `VAL-POWER` | P1/P2/P5 |
| `REG-3` | Other users/processes; consent and account grant boundaries | None | `VAL-SPIKE`, `VAL-HELPER`, `VAL-CLI`, `VAL-RELEASE` | P0/P2/P4/P5 |
| `REG-4` | Stale UI, concurrent GUI/CLI/external edits, timeout/uncertain results | None | `VAL-CORE`, `VAL-HELPER`, `VAL-GUI`, `VAL-CLI` | P1–P4 |
| `REG-5` | Locale, clock format, timezone/DST, unknown output, malformed input | None | `VAL-CORE`, `VAL-SYSTEM`, `VAL-GUI`, `VAL-CLI` | P1/P3/P4 |
| `REG-6` | Existing helper installation, approval revocation, update/removal, residual schedules | None | `VAL-SPIKE`, `VAL-HELPER`, `VAL-RELEASE` | P0/P2/P5 |
| `REG-7` | Oldest supported OS, Intel/Apple Silicon executable compatibility, contributor builds | None | `VAL-BUILD`, `VAL-SPIKE`, `VAL-RELEASE` | P0/P1/P5 |
| `REG-8` | User work and machine availability during normal shutdown/startup testing | None | `VAL-GUI`, `VAL-POWER`, `VAL-RELEASE` | P3/P5 |

### Validation definitions

- **`VAL-0` — Discovery and baseline.** Purpose: both; covers all initial `SC-*`/`REG-*` surfaces. Level: read-only inspection; new non-test gate. Location: this plan, applicable rules, architecture and `progress.md`. Tools: directory/Git inspection; `sw_vers`, `xcodebuild -version`, `xcrun swift --version`, `man pmset`, SDK header reads, and a minimized `pmset -g sched` snapshot. Environment: actual macOS host, no fabricated baseline. Expected: explicit current state, rules, tools, coverage gaps, and unknowns; no mutation. Cadence: P0 and when baseline evidence becomes stale. Initial discovery can be partial while spikes remain.

- **`VAL-SPIKE` — Feasibility exit gate.** Purpose: both; covers `SC-3`, `SC-5`, `SC-8`, `SC-9`, `REG-3`, `REG-6`, `REG-7`. Level: API/build inspection plus signed integration proof. New isolated probes under `Tools/Spikes/`, with exact commands/procedure captured before execution in a P0 evidence entry. Establish minimal signed SMAppService registration, expected-peer allow/deny, actual account identity and authorization/grant design, upgrade/unregister behavior, and a viable contributor signing configuration. Audit every selected API availability and confirm distribution prerequisites without exposing identity values or credentials. Environment: macOS 15 with an expressly approved helper test setup; otherwise report the integration portion blocked. Expected: no unsupported APIs below selected target, no relaxed identity checks, reproducible approval/recovery behavior, and a documented path to physical tests. Reject an approach that cannot secure these boundaries; revise before P2. Cadence: P0, then repeat invalidated spike evidence after architectural changes.

- **`VAL-CORE` — Deterministic scheduling semantics.** Purpose: both; covers `SC-1`, `SC-2`, `SC-7`, `REG-1`, `REG-4`, `REG-5`. Level: new unit tests in `Package/Tests/PowerScheduleCoreTests/`. Command: `swift test --package-path Package --filter PowerScheduleCoreTests`. Fixtures: all four switch states, midnight, valid overnight pair, invalid/equal times, day masks/types/seconds, unchanged-side partial edits, stale snapshot and unrepresentable-state replacement. Expected: complete validated intents, one correct argv representation per desired pair, no mutation on invalid/unknown state, and deterministic conflict outcomes. No current tests exist. Cadence: focused changes, P1, affected later phases, Hardening, final.

- **`VAL-SYSTEM` — Parser and process boundary.** Purpose: both; covers `SC-2`, `SC-7`, `REG-1`, `REG-2`, `REG-5`. Level: new unit/process integration plus real read-only smoke. Location: `Package/Tests/PowerScheduleSystemTests/`; command: filtered `swift test`, then shipped `powerschedulectl status --json` when available. Fixtures: independently authored/documented `pmset` outputs plus minimized real output; no repeat, both sides, weekday-only, 12/24-hour output, wakepoweron spelling, alternate event types, future/unknown output, one-time-only section, stderr/nonzero/timeout/oversized output. Test process runner through controlled test executables; inspect production path separately. Expected: exact repeating-state classification, fixed executable and validated argument arrays, bounded completion, distinct errors, no one-time cancellation or shell execution. Cadence: P1, P4 smoke, Hardening, final.

- **`VAL-BUILD` — Toolchain and compatibility.** Purpose: both; covers `SC-8`, `SC-10`, `REG-7`. Level: new build/static gate. Location: workspace/package/Configurations/Makefile. Commands: `make check`, `make test-strict`, `make build-universal`; inspect deployment target and architecture slices of app/helper/CLI. Environment: observed Xcode/Swift on Intel macOS 15; oldest runtime and Apple Silicon runtime remain separately qualified if unavailable. Expected: all required targets/tests pass with no hidden fallback, both release architecture slices exist, API availability matches the recorded target, no compilation-only runtime claims. Cadence: P1 and phase exits for affected targets, Hardening, final.

- **`VAL-HELPER` — Real trust and mutation paths.** Purpose: both; covers `SC-2`, `SC-5`, `SC-7`, `REG-1`–`REG-4`, `REG-6`. Level: new unit policy and signed process integration. Location: `Package/Tests/PowerScheduleServiceTests/`, `Package/Tests/HelperIntegrationProbe/`, `Tools/verify_helper.py` (explicit live-system gate). Run unit policy suite by `swift test --filter PowerScheduleServiceTests`; use the signed integration Xcode scheme/script defined during P2 setup. Fixtures: accepted app/CLI, wrong identifier/signature, missing grant, other account, forged payload, revoked grant on an existing connection, malformed IPC, version mismatch, re-registration, interrupted calls, and parallel requests. Environment: approved test setup with known baseline and recoverable future schedules. Expected: only authenticated/authorized callers change the pair or grants; denial leaves state unchanged; all four configurations read back correctly; grants survive/revoke as documented; one-time events unchanged except independently explained external activity. Test approval-disabled and helper-missing paths. Restore only when current state still matches the test-owned state; otherwise stop for reconciliation. Cadence: P2, P4 integration, P5 lifecycle, Hardening, final.

- **`VAL-GUI` — Observable UI behavior.** Purpose: both; covers `SC-1`, `SC-4`, `SC-5`, `SC-7`, `REG-4`, `REG-5`, `REG-8`. Level: editor unit tests, SwiftUI image snapshots, manual packaged-app/accessibility and production smoke. Location: `Package/Tests/PowerScheduleUITests/`, `Package/Tests/PowerScheduleSnapshotTests/`; command: `make test-unit` plus `make test-snapshots`. Images cover all four schedule combinations, automation enabled, read-only signing, pending approval, read failure, replacement and conflict, in light/dark at fixed locale/calendar/time zone/size. Missing or changed references fail; intentional recordings require visual review followed by verification. Unit tests cover actions, permission failures, apply errors and uncertain responses. Manual release checks cover packaged launch/foreground refresh, keyboard/VoiceOver, text sizing and confirmation/cancellation; system dialogs and animated busy state are not snapshot claims. Expected: accurate current versus edited state, no optimistic success before readback, explicit replacement, intelligible limitations/recovery. Snapshots do not replace signed production apply/readback under `VAL-HELPER`. Cadence: P3, relevant changes, Hardening, final. R2 is the user's explicit replacement of the former XCTest UI automation gate, not a retroactive pass of its failed runs.

- **`VAL-CLI` — Agent contract.** Purpose: both; covers `SC-2`, `SC-5`, `SC-6`, `SC-7`, `REG-1`, `REG-3`–`REG-5`. Level: new parsing/output unit tests plus subprocess and installed CLI integration. Location: `Package/Tests/PowerScheduleCLITests/`, `Tests/CLIIntegrationTests/`; commands: unit suite, `make test-cli`, and bundled `powerschedulectl` against the approved helper setup. Freeze schema version 1, stdout/stderr conventions, exit-code table, and help examples in `docs/cli.md` before production CLI code. Cases: `status`, `doctor`, set/disable, partial preservation, complete replacement, invalid flags/times, unavailable helper, missing/revoked grant, stale state, timeout, and GUI-closed use. Expected: one parseable JSON result for `--json` including errors, stable nonzero error categories, no hidden prompts, no write from read/diagnostic commands, and an actual authorized write/readback through the installed backend. Cadence: P4, Hardening, final.

- **`VAL-POWER` — Physical power behavior.** Purpose: both; covers `SC-3`, `SC-4`, `REG-2`, `REG-8`. Level: new attended manual end-to-end validation; unit tests cannot validate powered-off hardware. Location: `docs/testing/power-cycle.md` and sanitized evidence referenced from progress. Tool: release-candidate app/CLI plus user-operated normal Sleep/Shut Down actions. On the Mac mini with continuous power, save work, record baseline and expected event timestamps, program a near-future daily startup, close the app, shut down fully, observe cold boot without touching the power button; separately observe wake from sleep. Demonstrate normal scheduled shutdown while awake/logged in with saved documents. Record actual times, OS/hardware, and login/FileVault observations without changing security settings. Compare one-time events and restore the prior repeating pair only if no outside edit intervened. Expected: three distinct physical observations and preserved/reconciled baseline; no forced shutdown. Cadence: P5 feasibility/acceptance, repeat against final candidate in P7 if intervening changes invalidate evidence. Failure never becomes a simulated pass.

- **`VAL-RELEASE` — Distribution and lifecycle.** Purpose: both; covers `SC-5`, `SC-8`, `SC-9`, `REG-3`, `REG-6`–`REG-8`. Level: new packaging/security/lifecycle/manual gate. Location: `Tools/release.sh`, `Tools/verify_bundle.py`, `Tools/verify_release_identity.py`, `docs/release/README.md`, `docs/security.md`, `README.md`, `LICENSE`. Commands: `make archive`, `make verify-release`, `make notarize` with existing approved credential references, then `codesign --verify --strict` on each component and final app, `spctl --assess --type execute`, and `xcrun stapler validate` on the shipped artifact. Define exact artifact paths during P5 before executing; never store credentials in logs. Verify embedded daemon plist/executable, hardened runtime/entitlements, identities, architecture/deployment metadata, version compatibility, notarization result, and final artifact hash. Exercise install, denial, approval, app-closed CLI, update, revoke, and removal in an approved clean test setup, including residual-schedule disclosure. Follow source-build instructions with an explicitly documented contributor signing configuration; unsigned unit/read-only builds are labeled accordingly. Expected: usable verified artifact and accurate MIT/build/security/compatibility documentation. Requires available signing/notarization access; absence blocks this gate. Cadence: P5, Hardening for packaging changes, final release candidate.

- **`VAL-HARDEN` — Review, simplify, and broaden.** Purpose: both; covers `SC-1`–`SC-10` and `REG-1`–`REG-8`. Level: new full-diff/code/security review plus broader tests. Location: actual implementation diff and a concise review record in progress. Tools: `review-and-simplify-changes` skill, relevant SwiftUI/concurrency review skills when their surfaces are present, all affected suites above, and `make check`/`make test-strict`. Expected: inspect IPC authorization, lifecycle, global-state races, parser failures, and direct/indirect consumers; update actual regression map; fix major findings; simplify/deduplicate; re-review and retest the simplified result. Coverage is diagnostic only. Cadence: P6; repeat after material final fixes.

- **`VAL-FINAL` — Completion reconciliation.** Purpose: both; covers every `SC-*` and `REG-*`. Level: final artifact/end-to-end/doc/repository review. Location: release candidate, full diff, all evidence, and receipt in progress. Tools: repeat `VAL-BUILD`, `VAL-CORE`, `VAL-SYSTEM`, `VAL-HELPER`, `VAL-GUI`, `VAL-CLI`, `VAL-RELEASE`; validate freshness of physical evidence under `VAL-POWER`, repeating it after relevant changes. Expected: every criterion/risk has current evidence; no major open issue; truthful compatibility and residual-risk statement; complete guardrail ledger; known-good checkpoint and receipt. Cadence: P7, after any gate-invalidating change.

### Final gates

Every `SC-*` and `REG-*` must map to passing evidence. Physical power tests and signed production integration cannot be replaced by mock tests. User-approved untested older-OS coverage is a disclosed limitation, not a failing gate or fabricated runtime pass. Apple Silicon runtime qualification in accepted `INT-3` must remain explicit. Signing/notarization, lifecycle, hardening/re-review, current documentation, and known repository state are mandatory for release readiness.

## Integrity and anti-gaming contract

The following non-waivable constraints always apply:

- `UI-1` Required-check integrity: do not weaken, delete, skip, or falsely report required checks.
- `UI-2` Behavior integrity: do not change expected behavior to match faulty code or silently reduce approved scope.
- `UI-3` Production-path integrity: do not hardcode expected output, bypass production paths, or hide errors.
- `UI-4` Validation realism: do not substitute mocks, fixtures, or screenshots for required production implementation or realistic validation.
- `UI-5` Environment integrity: do not use unrealistic environments or data to claim completion.
- `UI-6` Evidence integrity: do not treat compilation, partial behavior, or unevidenced claims as completion.
- `UI-7` Regression-evidence integrity: do not claim regression safety solely from new-feature tests, happy-path tests, coverage percentage, compilation, or an unrelated passing suite.

Feature-specific constraints:

- `AG-1` Cold-start truth: a recorded event, wake-from-sleep, or successful CLI exit cannot establish cold startup. Verify with `VAL-POWER`; applies P0/P5/P7.
- `AG-2` Real system preservation: never clear one-time events, use a private preference cache as actual state, silently replace unsupported schedules, or restore over an external edit. Verify with `VAL-SYSTEM`, `VAL-HELPER`, `VAL-CLI`, `VAL-POWER`; applies P1–P7.
- `AG-3` Privilege scope: never disable identity/authorization checks for a green test or source build; signed CLI execution is not proof of user consent. Never accept arbitrary root commands or credentials. Verify with `VAL-SPIKE`, `VAL-HELPER`, `VAL-CLI`, `VAL-RELEASE`; applies P0/P2/P4–P7.
- `AG-4` Test and release honesty: normal tests cannot mutate host power settings, and unavailable devices/credentials/approval cannot count as passed hardware/security/release evidence. Verify via test-entrypoint review and `VAL-BUILD`, `VAL-POWER`, `VAL-RELEASE`, `VAL-FINAL`; applies all phases.

Only explicit material plan revisions can approve feature-specific exceptions, which must never be labeled passing evidence. Universal constraints cannot be waived.

## Checkpoint, recovery, and retention contracts

- Update progress at each meaningful task/validation and every stopping point; update decisions when discoveries or interpretation change. Record completed versus remaining work, current revision/mode, active task, exact next action, blockers/unlock conditions, last known-good state, and evidence.
- Local project/Git initialization is authorized by the implementation request. Make coherent local checkpoint commits only when commit permission is established; otherwise use documented file-state checkpoints. Never push/rewrite history/discard unrelated changes.
- At resume, read applicable rules, prompt/plan, progress Resume Here, runbook revision/task, and relevant decisions/evidence. Re-read the current schedule before any live integration. Run the smallest applicable baseline when prior evidence is stale or a new phase starts.
- Recover code through scoped edits/checkpoints. Do not use broad reset or cleanup. For uncertain writes, read back first. Preserve a pre-test snapshot and restore only when its replacement is still test-owned; a differing external state requires reconciliation. Failed helper removal or ambiguous daemon identity blocks further privileged tests until resolved.
- Missing credentials, unusable signing/trust design, unsupported target hardware, or an unapproved maintenance window are explicit dependent-work blockers. Record who/what can unlock them; continue pure or read-only independent tasks when allowed.
- Durable evidence: concise sanitized results, review findings, compatibility matrix, approved protocols, artifact hashes, final receipt. Add `qa/` only when retained artifacts are actually generated. Keep `.xcresult`, temporary signed probes, binaries, full logs, and release products under ignored `.build/` by default.
- Retain temporary evidence through its phase gate and final reconciliation; delete only identified disposable artifacts with safe scoped operations after durable summaries exist. Never remove evidence required by the completion contract. Do not commit credentials, tester account identifiers, serial numbers, personal schedule-owner strings, or machine-specific paths. Record per-artifact retention/cleanup in progress. Release artifacts persist until handoff or explicit cleanup approval.

## Traceability

All rows inherit `UI-1`–`UI-7`.

| Criterion/risk | Delivery tasks | Validation | Additional guardrails |
|---|---|---|---|
| `SC-1` | P1-T2, P3-T1–T3 | CORE, GUI, HELPER | AG-2/4 |
| `SC-2` | P1-T2–T3, P2-T2, P4-T2 | CORE, SYSTEM, HELPER, CLI | AG-2/3/4 |
| `SC-3` | P0-T3, P5-T3 | POWER | AG-1/4 |
| `SC-4` | P3-T2, P5-T3 | GUI, POWER | AG-1/4 |
| `SC-5` | P0-T2, P2-T1–T3, P5-T2 | SPIKE, HELPER, CLI, RELEASE | AG-3/4 |
| `SC-6` | P4-T1–T3 | CLI, HELPER | AG-2/3/4 |
| `SC-7` | P1-T2–T3, P2-T2, P3-T1, P4-T2 | CORE, SYSTEM, HELPER, GUI, CLI | AG-2/4 |
| `SC-8` | P0-T4, P1-T1, P5-T1 | SPIKE, BUILD, RELEASE | AG-4 |
| `SC-9` | P5-T1–T4 | RELEASE | AG-3/4 |
| `SC-10` | P6-T1–T4, P7-T1–T3 | HARDEN, FINAL | All |
| `REG-1`–`REG-8` | Owning tasks in regression table and phases below | Exact `VAL-*` mappings in regression table | AG-2/3/4; AG-1 for physical claims |

Validation names in this table abbreviate their canonical `VAL-` IDs.

## Phase plan

Every phase inherits the contracts above and all `UI-*` constraints. Its checkpoint records evidence and the exact next action; a phase exits only after its named checks pass. Technical uncertainty is resolved with evidence, not expanded scope.

### P0 — Discovery and Baseline

- Outcome: grounded scope, initial regression map, approved contracts, feasible security/compatibility design, and explicit hardware/release dependencies.
- Prerequisites: accessible sources and scope decisions; implementation/spike actions require their applicable authorization.
- Criteria: all initial `SC-*`; risks `REG-1`–`REG-8`; decisions `DEC-1`–`DEC-10`, interpretations `INT-1`–`INT-3`, questions `Q-1`–`Q-4`.
- `P0-T1`: reconcile read-only findings, review/approve proposed contracts and execution mode, and establish permission for the next work. Initial read-only orientation is already recorded, not repeated as new work.
- `P0-T2`: run the bounded signing/XPC/authorization/lifecycle spike. Document rejection/promotion criteria and exact commands before execution; promote only a secure, reproducible design. If blocked, record the missing approval/credential instead of introducing a permissive helper.
- `P0-T3`: define the attended power-cycle protocol and recovery checks; establish the future test window. Do not power-cycle automatically during planning.
- `P0-T4`: audit minimum API availability, toolchain/build targets, contributor signing and notarization prerequisites, and fixture strategy. Lock the regression baseline and exact P1 validation setup.
- Validation: `VAL-0`, `VAL-SPIKE`. Guardrails: AG-1/3/4.
- Recovery/blocked stop: read-only inspection is safe to resume; unregister test probes using the approved procedure. Stop security-dependent work if the trust spike fails; dependency availability must be explicit.
- Exit: contracts approved, security spike passed, baseline/risks/fixtures explicit, P1 checks ready, and no hidden prerequisite. Physical success itself remains a P5 gate.

### P1 — Project foundation and scheduling core

- Outcome: buildable workspace and tested domain/system adapters with truthful read-only schedule inspection.
- Prerequisites: P0 exit, production implementation permission, exact validation readiness.
- Criteria: REQ-2/5/6/7, SC-2/7/8; REG-1/2/4/5/7; INT-1/2; AG-2/4.
- `P1-T1`: create workspace, thin executable targets, local package, build configurations, target dependencies, test schemes, Make targets, gitignore, project rules, README, and MIT license. Specify the selected deployment target and strict concurrency/tooling rules. Do not copy Tetris's masking test fallback or unrelated game tooling.
- `P1-T2`: implement schedule values, daily edit validation, snapshot comparison, partial-intent semantics, and complete command argument construction with deterministic tests first.
- `P1-T3`: implement bounded fixed-path process adapter and parser, real read-only smoke, fixture provenance, unknown-state handling, and separation of repeating/one-time sections.
- Validation: `VAL-CORE`, `VAL-SYSTEM`, `VAL-BUILD`; no host writes.
- Recovery/stop: isolate I/O behind protocols; stop mutation-dependent work if parser semantics or API compatibility cannot be established. Record the exact unsupported case and fixture needed.
- Exit/checkpoint: package tests, build/static gates, universal components, and read-only host state agree; exact P2 integration harness ready.

### P2 — Privileged helper and account authorization

- Outcome: verified narrow helper can apply a complete schedule through authenticated/authorized requests; automation opt-in and revocation work.
- Prerequisites: P1 exit and promoted P0 trust design; expressly approved integration setup. Criteria: REQ-2/4/5, SC-2/5/7; REG-1–4/6; DEC-7/9; AG-2/3/4.
- `P2-T1`: implement typed IPC, bidirectional identity requirements, per-connection caller validation, system-managed authorization, account-bound grants, and lifecycle/version handling.
- `P2-T2`: implement serialized fresh-read/validate/merge/apply/readback flow, explicit replacement, bounded failures, and uncertain-result reconciliation.
- `P2-T3`: implement registration state/recovery/removal interfaces and negative/positive signed integration probes, including revocation on a live connection and other-account denial.
- Validation: `VAL-HELPER`, relevant `VAL-CORE`/`VAL-SYSTEM`, `VAL-BUILD`.
- Recovery/stop: never retry uncertain writes without re-reading. Stop on trust ambiguity, unexpected system change, failed restoration, or unapproved install/write operation; unlock with a reconciled baseline or approved setup.
- Exit/checkpoint: approved real writes/readbacks plus negative trust/grant tests pass, one-time state preserved, helper lifecycle observed, and baseline restored/reconciled.

### P3 — Minimal native application

- Outcome: the requested two-toggle/time-picker interface configures and truthfully displays the system schedule.
- Prerequisites: P2 exit and exact GUI fixtures. Criteria: REQ-1/2/4/5, SC-1/4/5/7; REG-4/5/8; INT-1; AG-2/4.
- `P3-T1`: implement editor state, initial/foreground refresh, enabled controls, Apply, current-state display, replacement/conflict handling, and error/uncertain states.
- `P3-T2`: integrate helper setup/approval/revocation, explicit automation permission UI, concise normal-shutdown/FileVault limitations, and recovery actions.
- `P3-T3`: validate keyboard/VoiceOver, appearance/text sizing, all state combinations, and the signed production path; fix usability failures without expanding into a dashboard.
- Validation: `VAL-GUI`, relevant `VAL-HELPER`, `VAL-BUILD`.
- Recovery/stop: preserve a dirty draft while presenting conflicts; never overwrite real state with a UI fixture. Block production write smoke if approval is absent, continuing only fixture/UI work.
- Exit/checkpoint: observed UI contract and production apply/readback pass; no false empty/success states; P4 CLI contract ready for implementation.

### P4 — CLI for agents

- Outcome: bundled CLI gives stable human/JSON output and noninteractive authorized edits with GUI closed.
- Prerequisites: P3 exit, schema/exit table/help fixture frozen by P4-T1, existing helper integration setup. Criteria: REQ-3/4/5, SC-2/5/6/7; REG-1/3/4/5; INT-2; AG-2/3/4.
- `P4-T1`: specify `docs/cli.md`, schema version 1, error categories, stdout/stderr rules, allowed flag combinations, help and diagnostic privacy. Define schema/command expectations independently of implementation before writing production CLI behavior.
- `P4-T2`: implement status/doctor, partial set, complete replacement, disable, and typed helper requests. CLI cannot noninteractively grant itself automation permission.
- `P4-T3`: bundle/sign the executable, document invocation/PATH setup, and run process-level plus actual helper-backed tests with GUI closed and grants enabled/disabled/revoked.
- Validation: `VAL-CLI`, `VAL-HELPER`, `VAL-BUILD`.
- Recovery/stop: errors are prompt-free and actionable; do not fall back to sudo/password entry. Resolve mismatched schema or authorization failures before phase exit.
- Exit/checkpoint: exact CLI contract and preservation/security paths pass using the distributed executable arrangement.

### P5 — Release packaging and physical validation

- Outcome: a signed/notarized candidate, documented lifecycle/source build, and physical power evidence.
- Prerequisites: P4 exit, approved credential use and clean test setup, attended power-test window. Criteria: REQ-6/8, SC-3/4/5/8/9; REG-2/3/6/7/8; INT-3; all AG-*.
- `P5-T1`: implement reproducible archive/export/bundle verification, versioning, dual-architecture inspection, notarization/stapling, and artifact hashing; no publishing.
- `P5-T2`: exercise install, denial, approval, upgrade, revoke, source-build trust, and removal. Document grant cleanup and surviving schedule behavior.
- `P5-T3`: execute the approved real cold-start, wake, and normal-shutdown protocol, record observations and restore/reconcile prior settings.
- `P5-T4`: complete README, CLI/security/troubleshooting/compatibility/source-build and release documentation; label untested platforms, confirm MIT license.
- Validation: `VAL-RELEASE`, `VAL-POWER`, `VAL-BUILD`, relevant helper/CLI lifecycle checks.
- Recovery/stop: unavailable signing or maintenance window blocks the corresponding gate; continue independent documentation/build checks. Hardware failure returns to targeted investigation and cannot be “fixed” by changing the expected claim. Never change FileVault or force shutdown.
- Exit/checkpoint: all physical/lifecycle/release evidence passes, baseline reconciled, candidate artifact retained with hash and environment details.

### P6 — Hardening

- Outcome: no major known issue, actual-diff regression coverage, simpler reviewed implementation.
- Prerequisites: all Delivery exits. Criteria: SC-10 plus all affected SC/REG; all UI/AG constraints.
- `P6-T1`: inspect full implementation, clients/consumers, authorization and error paths; fix major findings.
- `P6-T2`: recalculate impact from actual diff, update REG/VAL mappings through revision approval if materially changed, and close coverage gaps.
- `P6-T3`: apply the installed `review-and-simplify-changes` skill for simplification/deduplication; review the simplified result.
- `P6-T4`: run broader affected checks, resolve findings, and explicitly record any proposed deferral. Major issues cannot be silently deferred.
- Validation: `VAL-HARDEN` and affected gates.
- Recovery/stop/checkpoint: return defects to their owning phases; keep the last known-good state and exact failures. Exit only with review, simplification, re-review, and required evidence complete.

### P7 — Final Verification and Handoff

- Outcome: demonstrably complete, reviewable release candidate and completion receipt.
- Prerequisites: P6 exit. All SC/REG and UI/AG constraints apply.
- `P7-T1`: inspect full diff/repository state and re-run final approved validations on the candidate; repeat physical checks if relevant changes invalidate earlier observations.
- `P7-T2`: reconcile criteria, regression coverage, guardrails, decisions, deviations, technical questions, deferred work, and documentation/compatibility claims.
- `P7-T3`: record final artifact hash, known-good checkpoint, environment, residual testing limits, and completion receipt. Hand off without pushing or publishing.
- Validation: `VAL-FINAL`.
- Recovery/stop/checkpoint: failed evidence reopens its owning phase, followed by affected hardening. Missing required proof blocks completion. Exit only when the receipt is complete and honest.

## Deferred backlog

- `DEF-1`: Phone UI and SSH/Tailscale configuration; outside requested first release. Revisit after stable local CLI delivery.
- `DEF-2`: Standalone CLI/helper installer; app-based bootstrap accepted. Revisit on concrete headless deployment need.
- `DEF-3`: Weekday editing, multiple profiles, one-time event management; daily pair is the approved product. Revisit only with a new scheduling contract.
- `DEF-4`: Forced/immediate shutdown and unattended-login configuration; explicitly outside normal-shutdown scope. Revisit as a separate product/security decision.
- `DEF-5`: Auto-update system, Mac App Store packaging, and public release automation; not required for local release readiness. Revisit with distribution authorization.

## Delivery protocol

Read the current approved revision and canonical progress before work. Execute one active phase at a time. Keep the runbook aligned, preserve evidence and unrelated state, and do not enter production implementation with vague active-phase validation. Complete Hardening and Final Verification; do not confuse a completed plan with a completed product.
