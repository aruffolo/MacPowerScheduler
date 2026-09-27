# Decisions and discoveries

## Accepted product decisions

All accepted decisions below derive from the user's current discovery answers, not from suggestions in the linked conversation. Dates: 2026-09-27. No decisions are superseded.

| ID | Decision and evidence | Consequences / revisit trigger |
|---|---|---|
| `DEC-1` | GUI and CLI ship together; Q1 recommendation accepted. | Share behavior; phone/SSH setup is outside the first release. Revisit only if the user changes scope. |
| `DEC-2` | New schedules are daily; Q2. | No weekday editor. Existing schedules still need truthful representation. |
| `DEC-3` | Wake-or-power-on; actual cold startup is the priority; Q3. | A sleep-only demonstration cannot establish the primary outcome. |
| `DEC-4` | Normal shutdown only; Q4. | Explain system limitations; no force-shutdown fallback. |
| `DEC-5` | Minimum OS follows APIs selected; macOS 15 is the physical test environment, older releases can remain untested; Q5. | No arbitrary macOS 15 floor and no universal hardware claims. Revisit if a required API raises the minimum. |
| `DEC-6` | Release-ready, publicly usable open-source app with signing/notarization; Q6. | Credentials and release validation are dependencies, not presumed available. Actual publication is separate. |
| `DEC-7` | Explicit, initially disabled, revocable account-level automation grant; Q7. | Other processes under that account can invoke CLI writes. Peer signing alone is insufficient authorization. |
| `DEC-8` | App installs/authorizes helper initially; CLI works with GUI closed; Q8. | No standalone CLI installer required in v1. |
| `DEC-9` | Accurate existing-state display, explicit replacement of unrepresentable schedules, refresh on external change, preserve one-time events; Q9. | A simple daily editor must not silently flatten a weekday schedule. |
| `DEC-10` | MIT license; Q10 accepted as “meat,” interpreted in context as MIT. | Add standard MIT license during repository setup; no license file created by this planning-only task. |

## Accepted execution interpretations

### INT-1 — Small daily editor and safe edits

Accepted under `R1` by the end-to-end implementation request: one native window; 24-hour `HH:mm` CLI input, locale-appropriate GUI display, minute precision for new values, local-system timezone. Overnight schedules are valid; simultaneous enabled startup/shutdown times are rejected rather than guessing ordering. Existing non-daily, different-event-type, or sub-minute schedules remain visible and require acknowledgement before full conversion. Parse failures prohibit mutation. Related: `SC-1`, `SC-2`, `SC-7`; `P1`, `P3`, `P4`.

### INT-2 — CLI contract and removal behavior

Accepted under `R1` by the end-to-end implementation request: `powerschedulectl status`, `doctor`, `set`, `disable startup|shutdown|all`, and `--json`. `set` accepts `--startup HH:mm`, `--shutdown HH:mm`, `--no-startup`, and `--no-shutdown`; omitted sides are preserved. A full replacement of an unrepresentable schedule requires both sides to be specified plus `--replace-existing`. A partial edit of an unrepresentable pair fails with instructions to supply a complete replacement. Read/status need no elevation; noninteractive writes do not trigger surprise authentication UI. Removal preserves schedules unless explicitly cleared first. Related: `SC-5`, `SC-6`, `SC-7`, `SC-9`.

### INT-3 — Delivery evidence and execution mode

Accepted under `R1` by the end-to-end implementation request: supervised phases, unit/integration/UI gates, real helper security tests, attended cold-start/wake/shutdown tests, dual-architecture builds, and a verified signed/notarized artifact before release readiness. Goal mode is optional after contract approval; it is not enabled. No physical tests on older systems are required under `DEC-5`; runtime claims must disclose that limit. Apple Silicon runtime testing is also not available in the observed environment and is proposed as an explicit release qualification rather than invented evidence. Related: all success criteria and the plan contracts.

## Discoveries

### DISC-1 — Greenfield baseline

The target directory was empty and not a Git repository. There are no existing application tests or behavior to preserve. Regression concerns apply instead to host power settings, other schedule consumers, and newly established behavior. Evidence: `E-0` in `progress.md`. No plan revision change.

### DISC-2 — Reference structure

TetrisMac has the appropriately sized workspace/App/Package/Configurations/Tools/Makefile spine. Liquore illustrates interface/adapter separation but has a larger feature graph. Neither inspected tree provided an equivalent five-file planning set. Use the new core under `docs/plans/initial-release/` and a central architecture proposal. Evidence: `E-2`. Proposed architecture, not inherited project policy.

### DISC-3 — Shared pair and actual host baseline

The installed manual documents one repeating power-on/power-off pair. The observed host has only a daily shutdown entry. Schedule ownership cannot be inferred from a repeating-event owner tag; one-time owner metadata does not create a private repeating pair. Evidence: `E-1`. Preserve this state during discovery and re-read it before any later test.

### DISC-4 — Privilege APIs and compatibility

Installed SDK headers expose the principal helper and XPC requirement APIs from macOS 13. Some conveniences, including the exported SMAppService error-domain constant, have newer availability. An API audit must inspect all used symbols rather than infer compatibility from the framework name. ServiceManagement headers require code signing and describe notarization for daemon-containing apps. Evidence: `E-3` and Apple sources in `prompt.md`.

### DISC-5 — Build success and hardware success differ

No physical cold-start, wake, scheduled-shutdown, helper, or release-signing test has run. Apple documents shutdown and FileVault limitations. Local toolchain access does not establish availability of signing credentials, a clean-install test environment, or another architecture. Evidence: `E-0`/`E-3`.

## Open technical and contract questions

| ID | Classification / impact | Resolution path and unlock condition | Status |
|---|---|---|---|
| `Q-1` | Contract: inferred edge behavior, validation floor, execution mode. | User reviews `R1`, including `INT-1`–`INT-3`, and explicitly authorizes implementation before production work. | Resolved: user authorized end-to-end implementation on 2026-09-27. |
| `Q-2` | Technical: helper trust, account authorization/grant persistence, contributor signing. Blocks privileged delivery. | `P0-T2` spike proves approved/denied/revoked paths and a documented signing approach without weakened trust. | Partial: local signing and the signed archive are verified; installed signed runtime spike remains unexecuted. |
| `Q-3` | Technical: cold startup/wake behavior and normal shutdown on target hardware. Blocks hardware claims. | `P0-T3` defines procedure; `VAL-POWER` supplies attended real-device evidence in P5. Failure triggers investigation or explicit scope revision. | Open; maintenance window not booked. |
| `Q-4` | Technical/environment: exact minimum OS, signed distribution credentials, notarization access, clean-install test environment. | `P0-T2`/`P0-T4` confirm capabilities without dumping identities/secrets, lock API/build requirements, record any exact external blocker. | Partial: macOS 14 deployment, both architectures, Developer ID signing, Apple notarization and Gatekeeper acceptance verified; clean-install evidence remains open. |

## Deviations and behavioral notes

No approved deviations. Do not interpret absent test evidence as a passing exception. The architecture favors one on-demand helper and system-owned scheduling. Changing a schedule does not guarantee shutdown execution, login completion, or remote service reachability after startup.

Future user decisions and material technical changes must be added here with stable IDs; contracts change only through a new approved plan revision.

## Execution update — 2026-09-27

The user authorized implementation of the full plan. Signing inspection found zero usable Apple Development/Developer ID identities. Do not weaken trust: installed-helper and notarization gates remain pending. Continue independent implementation and nonprivileged validation under the plan’s independent-work rule; phase exits remain open until their required live evidence exists. No live power changes or helper installation have been authorized. Git initialized for local change tracking; no commit or remote created.

### Implementation refinements — 2026-09-27

- Selected macOS 14 deployment for Observation; macOS 15 remains the tested host, older OS/Apple Silicon runtime untested. No API requires macOS 15.
- Read-only supplemental custom-day metadata uses the storage file documented in `pmset(1)` because Apple pmset prints custom day masks as `Some days`. Validate it fail-closed; all writes still use fixed `/usr/bin/pmset repeat` arguments. Sources: [Apple pmset implementation](https://github.com/apple-oss-distributions/PowerManagement/blob/main/pmset/pmset.m) and installed `pmset(1)` FILES section.
- Replaced blocking interactive authorization with `AuthorizationCopyRightsAsync`; platform/lifecycle/authorization dependencies are injected for GUI model tests. Production peer requirements remain mandatory.

### Tetris lint and formatting workflow — 2026-09-27

- User explicitly requested Tetris's settings and pre-commit hook, authorizing SwiftLint and SwiftFormat as development tools. No runtime dependency was added.
- Retain Tetris's app/package lint rules and formatter options; adapt the excluded project name and formatter Swift version to this project. SwiftLint runs in Make and Xcode. SwiftFormat replaces the earlier Apple formatter so the hook and manual formatting agree.
- Omit the reference's game-specific SwiftGen step. Preserve its format/re-stage behavior with quoted file arrays and a preflight refusal for partially staged files, preventing unrelated edits from entering the index. Hook installation is repository-local.

### Tetris agent guidance — 2026-09-27

- User requested copying TetrisMac's `AGENTS.md`, `ai-rules/`, and `ai-docs/` verbatim, changing only project differences. Copied all 17 rule files and four reference docs; preserved the original MacPowerScheduler rules beneath the shared AGENTS block and synchronized its reference copy.
- Adaptations cover macOS 14 / Swift 6.2 / Observation, the existing six-module app/helper/CLI architecture, Swift Testing plus XCTest UI tests, strict Make targets, native localization/assets/UI, ZIP release tooling, signing/provisioning, and power-safety boundaries. Shared communication, ownership, review, and runtime-safety guidance remains intact; existing commit authorization is preserved.
- Task routes use the installed SwiftUI, concurrency, testing, native profiling, and Peekaboo skills. No skills, runtime dependencies, game tooling, or reference-repository changes were added. Document discovery uses existing `rg` and frontmatter rather than introducing Tetris's Node-based docs-list script.
- This guidance adoption does not revise the product contract, validation gates, or live-operation approvals in R1.

### Unit-test scope and 95% gate — 2026-09-27

- User requested research into Swift/macOS testing practices, >=95% coverage of realistically unit-testable logic, and refactoring where needed. Added a supplemental coverage requirement to R1 without removing any existing integration/UI/hardware gate. [Scope, command details and primary Apple/Swift sources](../../testing/unit-coverage.md) define the denominator.
- Deterministic core, parser, CLI, service policy, IPC message handling and editor state belong in unit scope. Real OS execution, signature verification, XPC connections, Authorization Services, OpenDirectory, ServiceManagement and SwiftUI rendering need integration/UI evidence. Existing safe process/filesystem tests move to a separately required adapter suite, not the unit numerator.
- Extracted pure signing/grant-metadata policy and small internal process/transport/account-resolution seams. Public production defaults retain mandatory identity and authorization checks. Calendar injection keeps clock assertions deterministic; production still uses the current calendar. No dependencies or privileged test bypasses were added.
- New editor regressions cover clearing a stale conflict notice, losing signing readiness, and helper unregistration failing after grants were already cleared. The model now clears the corresponding stale notice/automation state while retaining accurate helper registration state. These corrections need no live schedule change.
- The manifest classifies every production package Swift file. Fresh coverage runs fail below 95%, on missing/unclassified files, or when tests fail; they preserve raw evidence and remove temporary build intermediates. Unit coverage does not prove branch completeness, signed helper acceptance or physical behavior. The earlier notarized artifact predates these source changes.

### Native LLVM reports and SwiftUI research — 2026-09-27

- User accepted native LLVM reporting and requested reusing the existing test run if possible. File filtering, JSON/text and HTML reports now come directly from `llvm-cov`; the wrapper retains scope, input-integrity and threshold checks. `make coverage-report` re-renders only, while `make test-coverage` and `make check` retain fresh measurement behavior. Matching binaries/profiles are retained with hashes, without keeping the full temporary build tree.
- Reused the retained 96-test unit run after checking its source timestamps and matching file counters against the latest verified result. No Swift tests/builds were rerun for this reporting change. Reporting-tool checks are separate from prior app validation; the strict UI off-console blocker remains open.
- Inspected CodeEdit, Kingfisher, Hwp-Swift, Sentry's iOS sample and SnapshotTesting source. [Findings](../../testing/swiftui-testing-research.md) support a separate hosted SwiftUI component layer: macOS snapshots, binding/layout assertions and full-app XCTest interactions. Existing model tests remain appropriate but do not prove view wiring. No snapshot package or production view changes were introduced.

### R2: replace app UI automation with snapshots — 2026-09-27

- User explicitly requested: “Remove the ui automation and let’s use only the snapshots,” after discussing Point-Free's test-only dependency. This authorizes SnapshotTesting 1.19.6 and replaces the former app automation gate; production UI stays SwiftUI and model unit tests remain.
- Remove the AppUITests target/source, runner provisioning and test-ui workflow. Add a separate Swift Testing snapshot target, reviewed light/dark PNGs and required `make test-snapshots` in both full gates. Explicit recording and normal verification are separate commands.
- `PowerScheduleView` retains live lifecycle; `ScheduleContentView` accepts the model for synthetic rendering. NSHostingView exists only in the harness. Scope excludes snapshots from the unit numerator, preserving the >=95% deterministic threshold.
- Snapshots compare appearance, not packaged launch, interaction/accessibility, authorization or physical effects. Manual release checks and attended helper/power gates remain. The earlier UI-runner failures remain in history and are superseded by the user-approved contract change, not declared fixed.
