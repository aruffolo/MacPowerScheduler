# MacPowerScheduler progress

## Resume Here

- Current request (2026-09-28): create Universal and arm64 app releases, using CodexBar as a reference. Both current candidates are signed, Apple-notarized, packaged, uploaded to a draft and verified again after GitHub download. The intended status is pre-release; the [GitHub release](https://github.com/aruffolo/MacPowerScheduler/releases/tag/v0.1.0) is authoritative for publication status. The repository remains private. Branch protection is blocked by GitHub's private-repository plan requirement; making it public remains a separate decision.
- App-source checkpoint: `51f5495`, including draft preservation (`8cbb629`), Quiet Agenda/Deep Sapphire (`d48cd36`), Settings refresh alignment (`16c722c`), and public README/contributor guidance (`3ba85ee`). PRs of any size are welcome without an issue first.
- Automated validation: fresh `make check` and `make test-strict` passed for this release change: 100 unit tests, 4 adapter tests, 33 tooling tests, 50 snapshot cases, build/static analysis and actual read-only CLI checks. Scoped unit coverage is 1024/1047 executable lines (97.80%); it excludes live integration and UI rendering. See the readiness-review receipt below.
- Functional testing: the maintainer reports that testing is complete and the app works on this Intel Mac mini / macOS 15.7.4. This is successful maintainer-reported testing, not an itemized signed-peer, lifecycle or physical-power receipt. Do not describe that testing as unperformed or infer results for unreported cases or other hardware.
- Remaining evidence: reconcile the maintainer's results with the release matrices before claiming every release gate passed. The redesigned UI still has explicit VoiceOver speech and Escape-dismissal evidence gaps in [Quiet Agenda progress](../quiet-agenda-ui/progress.md). The two new 0.1.0 artifacts include the current UI and draft-preservation fix; artifact verification does not close the remaining attended/runtime evidence gaps.
- Plan revision observed: `R2`, user-approved replacement of app UI automation with Point-Free snapshots on 2026-09-27.
- Execution mode: supervised; Goal mode not enabled.
- Active phase/task: `P7` evidence reconciliation; implementation and automated UI work are complete, with detailed release proof still partial.
- Next stable/public-release action: reconcile the remaining named runtime/accessibility evidence and decide repository visibility separately. This pre-release does not claim every stable-release gate passed. Exact source/ref and hosted checks are available from the GitHub release and Actions history.
- Documentation reconciliation was committed as `ca62f46`; private-repository CI is green at `51f5495`. The maintainer now authorized both binary release variants and explicitly approved uploading both to Apple. Public visibility and new live system operations remain outside this task.
- Updated: 2026-09-28.

Native LLVM selected-file HTML/text/JSON remains available through `make coverage-report` for unchanged retained inputs. A later source change requires fresh coverage; a documentation-only edit does not invalidate this checkpoint's measurement.

## Phase status

| Phase | Status | Exit evidence / remaining work |
|---|---|---|
| P0 Discovery and Baseline | partial evidence | Contracts accepted; signing verified; itemized installed XPC trust evidence not recorded |
| P1 Project foundation and scheduling core | implemented; independent gates passed | CORE/SYSTEM/Debug+universal BUILD passed |
| P2 Privileged helper and account authorization | implemented; partial evidence | Injected service/grant tests pass; itemized signed-peer/account matrix not recorded |
| P3 Minimal native application | implemented; partial evidence | Current model tests and 50 snapshot cases pass; Quiet Agenda interaction gaps are tracked separately |
| P4 CLI for agents | implemented; partial evidence | Parser/runner and actual read-only process checks pass; itemized signed-write results not recorded |
| P5 Release packaging and physical validation | partial evidence | Current Universal/arm64 artifacts notarized and download-verified; maintainer reports functional success; lifecycle/POWER details remain to reconcile |
| P6 Hardening | automated checks and reviews complete; partial runtime evidence | Review fixes and re-reviews complete; detailed signed/runtime matrix not recorded |
| P7 Final Verification and Handoff | active; partial evidence | Current source checks and maintainer report summarized above; full binary-release completion contract not yet evidenced |

Completed means passed exit evidence, not simply code written. Independent work continues under the plan's blocked-work rule; this does not waive prerequisites or certify a later phase complete.

## Execution log

The following entries are historical receipts as of their dates and source revisions. Earlier pending work, counts and authorization limits are not the current status; use Resume Here above.

### 2026-09-26–27 — P0-T1 read-only discovery

- Status: partial.
- Read the full shared conversation through the browser, current skill instructions/templates, relevant Apple material, local SDK headers/man page, reference architecture/docs/code/test findings, and current host baseline.
- Two discovery rounds settled ten product questions; accepted answers are owned by `DEC-1`–`DEC-10`.
- Reference inspection included a bounded read-only subagent. No reference repository was changed.
- No product code, app tests, helper, live schedule mutation, or power cycle was attempted.

### 2026-09-27 — P0-T1 draft checkpoint

- Status: completed for draft preparation; execution contracts remain unapproved.
- Added the five-file core and central architecture proposal. Proposed future commands/paths are explicitly distinguished from existing artifacts.
- References: `INT-1`–`INT-3`, `Q-1`–`Q-4`, all planned phases/validations.
- Checkpoint: documentation files only; no Git repository or commit.

## Validation evidence

`VAL-0` and later receipts are recorded below. Their results apply to their stated checkpoints; current evidence gaps are summarized in Resume Here.

### E-0 — Empty-project and host baseline

- Date: 2026-09-26–27; phase: P0; tools: `pwd`, `ls -la`, targeted `rg --files`, `git status --short`, `git remote -v`, parent-rule checks, `sw_vers`, `xcodebuild -version`, `sysctl -n hw.model`.
- Result: directory initially empty; Git reports it is not a repository. No tracked project instructions/build/tests existed. Host: Macmini8,1, macOS 15.7.4 (24G517), Xcode 26.3 (17C529).
- Meaning: there is no existing app test baseline. Build/test commands cannot yet run; this is absence of implementation, not a pre-existing test failure.
- Evidence/retention: concise record committed with future planning docs; no personal identifiers or raw environment dump retained.

### E-1 — Current schedule and documented command semantics

- Date: refreshed 2026-09-27; tools: `man pmset` scheduled-event section and `pmset -g sched` limited to the repeating section.
- Observed repeating state: `shutdown at 11:00PM every day`; no repeating startup entry. One-time event details were not retained.
- Manual: `repeat` supports one power-on/off pair; `schedule` is for one-time events; supported types include sleep, wake, poweron, shutdown, wakeorpoweron.
- Meaning: read-only factual baseline, not evidence of successful scheduled shutdown or cold startup. Re-read before future tests because the system is mutable.
- Retention: this minimized summary only; no snapshot authorizes restoring over later external edits.

### E-2 — Reference structure and workflow

- Date: 2026-09-26–27; tools: local targeted reads and GitHub API file/tree reads through `gh`, plus bounded subagent inspection.
- TetrisMac revision: `be63a47b2a1a524b0062e1d104d2f8d399ce9f0d`; Liquore revision: `0d41d6fafa648676499e180dde4fb5838a88c104`.
- Verified reference spine: Xcode workspace/project, thin app, local Package, Configurations, Tools, Makefile; tests under package Tests and `.build` artifacts. Liquore uses a broader interface/adapter/module graph. Tetris reference Makefile has a fallback test target; the planned strict gate deliberately preserves original failures.
- Sources: immutable Tetris links in prompt; Liquore `ai-rules/project-structure.md`, `Package/ModuleRules.md`, package and representative composition/view-model/tests inspected read-only.
- Meaning: supports the proposed layout, not a claim that game/app-specific code is reusable scheduler code. No reference tests were run.
- Retention: concise findings and source revisions only.

### E-3 — Platform API and Apple guidance

- Date: 2026-09-26–27; tools: installed SDK header reads, Apple Support/Developer pages linked in prompt.
- SDK observations: `SMAppService` registration/daemon APIs and NSXPC connection/listener signing requirement APIs have macOS 13 availability. The exported `SMAppServiceErrorDomain` constant has macOS 15 availability. ServiceManagement documentation requires signing and describes daemon-containing app notarization.
- Apple guidance: scheduled shutdown has awake/logged-in/unsaved-document limitations; FileVault requires login. Helper installation and runtime user authorization are separate responsibilities. XPC peers need explicit verification.
- Meaning: supports an oldest-API audit beginning at 13, not a finalized deployment target or a verified unsigned privileged-source-build path.
- Retention: concise observations and public citations; no identity or credential inventory collected.

### E-4 — Development tooling

- Date: 2026-09-27; commands: `xcrun swift --version`, `xcrun swift-format --version`.
- Result: Swift 6.2.4, target x86_64-apple-macosx15.0; bundled swift-format 6.2.3.
- Meaning: native compiler and formatter are available. No additional dependencies were installed and no application compilation occurred.
- Retention: this summary only.

### E-5 — Planning-document audit

- Status: passed, 2026-09-27; planning-only scope.
- Tool: read-only Python audit of the six Markdown files, supplemented by a contract/traceability review.
- Result: all relative Markdown links resolve; eight lifecycle phases and twelve named validation definitions exist; named validation references resolve; all seven universal integrity constraints match the installed template verbatim; no unused template markers or machine-specific absolute paths found; runbook and resume state agree on R1/P0/P0-T1.
- Review: user answers remain accepted while new edge semantics and execution evidence remain proposed; no existing source/test/build artifact or approval is implied by a planned command. No product completion is claimed.
- Retention: this concise audit record; no additional QA artifact needed and no files were changed by the audit itself.
- This is documentation verification, not `VAL-FINAL` or product test evidence.

### Unexecuted validation ledger

See current phase table and implementation evidence below. Historical planning observations remain dated; they are not the current implementation state.

## Integrity and anti-gaming evidence

| Constraint | Current evidence and remaining verification |
|---|---|
| UI-1 | Required gates preserved; XCTest failures and blocked signed/physical checks remain visible. No fallback marks the strict suite passed. |
| UI-2 | Daily/normal shutdown, explicit replacement, partial intent and account consent retained. No scope reduction or exception. |
| UI-3 | Production uses real pmset/XPC paths; fixture injection only in test composition. Test-only raw probe is excluded from shipped bundle. |
| UI-4 | Unit/model/visual results are separately labeled; none is substituted for signed or physical evidence. |
| UI-5 | Intel macOS 15.7.4 host only; arm64/macOS 14 compatibility is compilation evidence, not runtime evidence. |
| UI-6 | Application implementation delivered as a partial handoff; release/full-product completion explicitly not claimed. |
| UI-7 | Regression tests cover stale/concurrent edits, unsupported replacement, decoded invalid values, parser drift, output bounds, grant isolation/storage, dirty drafts, transport uncertainty and release rejection. Signed runtime regressions remain open. |
| AG-1 | Cold startup, wake and shutdown not claimed; VAL-POWER pending. |
| AG-2 | Fixed repeat arguments, one-time separation, fail-closed parsing, explicit replacement and revisions tested; live preservation gate open. Supplemental metadata is read-only system storage documented by pmset, not an app-owned state cache. |
| AG-3 | Mandatory bidirectional signing and per-account authorization remain; ad-hoc builds cannot use helper. Signed rejection still requires real evidence. |
| AG-4 | Default tests read or use fixtures; no real schedule/helper/grant changes. Release verifier rejects the actual ad-hoc artifact, including under Python optimization. |

No exceptions approved. These records preserve integrity of a partial delivery; they do not certify release completion.

## Review and hardening record

Applied `review-and-simplify-changes` with four independent read-only reviews: reuse, quality, efficiency and clarity. Closed findings for GUI platform injection, async authorization and callback isolation, actual Apple midnight/day/empty formatting, uncertain write readback/transport, custom-day metadata, and verification checks disappearing under optimization. Re-review then closed runtime-flag substring matching and probe false-positive/executor issues. Compile-only SIL verified authorization/probe callbacks are nonisolated. Optimized Python regression tests verify release rejection. No remaining material findings were reported in those review scopes; absence of signed/physical evidence remains an explicit release blocker.

## Deferred events

`DEF-1`–`DEF-5` remain the original exclusions. No failed gate, major finding or requested feature was retroactively deferred. Signing, XCTest and physical gates are open work, not removed scope.

## Partial handoff receipt — 2026-09-27

- Product outcome achieved: implementation and local development artifact; **full release-ready outcome not achieved**.
- Plan: R1 approved; no Goal session, commit, push or publication.
- `SC-8`: passed build/compatibility disclosure. `SC-1/2/5/6/7`: implementation and isolated/read-only evidence, signed production validation pending. `SC-3/4`: physical tests pending. `SC-9/10`: documentation/tooling/review implemented; release/final gates pending.
- Remaining blockers: usable Apple signing identity and approved installed-helper setup; notarization access; XCTest runner fails before establishing connection; attended cold-start/wake/shutdown window. Minimum macOS 14 and Apple Silicon runtime remain openly untested as permitted.
- Development artifact: `.build/Artifacts/MacPowerScheduler-development-universal.zip`, containing the ad-hoc universal app. Privileged features are disabled without valid Apple-issued signing. It is not notarized or a public release.
- SHA-256: `a7a8e1db91e56172384280f45167a6d4872419a37d0342a49292c6a0f34eeeb2`.
- Executable app: `.build/DerivedData/Build/Products/Release/MacPowerScheduler.app`; default Debug build remains available.
- No actual power schedule changes, helper registration, administrator authorization requests, account grants, shutdowns or wake tests were performed.
- Source checkpoint: all project files are present in an initialized Git working tree, untracked/uncommitted. Review `git status` before the next change; preserve files. Artifact hash identifies the built candidate without inventing a commit.

## Implementation evidence — 2026-09-27

- User requested end-to-end implementation. Created the reference-shaped workspace, three executables, six library modules, native UI, strict CLI, serialized helper policy, per-account grants, build/release tooling, and user/security/test docs. No dependencies added.
- Initial `swift test --package-path Package`: 20 tests in five suites passed. `make build`: Debug build passed. `make test-cli`: real read-only status, invalid arguments, JSON exits and help passed.
- Signing inspection returned zero usable Apple Development/Developer ID Application identities; only counts retained. No authentication secrets printed. No production trust fallback introduced.
- Four read-only reviews (reuse, quality, efficiency, clarity) found real pmset midnight/day formatting, post-write uncertainty, synchronous GUI authorization, model dependency injection, and optimizable Python assertions. Fixes and additional regression tests subsequently passed as recorded in the final ledger.
- Deployment target is macOS 14 because the native model uses Observation; macOS 15.7.4 is the runtime test host. Older OS and Apple Silicon runtime remain untested.
- Apple pmset source reveals custom weekdays print only `Some days`; read-only supplemental metadata comes from the storage file documented by `pmset(1)`, with bounds, schema/type/day/time checks. No private IOKit API or preference writes are used.
- No full-product completion claimed. Signed peer rejection, installed-helper lifecycle, notarization, cold startup and normal shutdown remain mandatory open gates.

## Final independent validation ledger — 2026-09-27

| Validation | Observed result |
|---|---|
| VAL-0 | Read-only baseline and accepted requirements documented; signed feasibility still open. |
| VAL-SPIKE | Blocked: no usable Apple signing identity. No privileged source-build success claimed. |
| VAL-CORE | Passed as part of 26 Swift tests, including four pair combinations, invalid decoded ranges, partial edits, stale revisions and replacement. |
| VAL-SYSTEM | Passed parser/process suite and real read-only CLI; tests cover Apple output variants, one-time separation, stderr/status, timeout and oversized output. Actual custom-day schedule runtime untested. |
| VAL-BUILD | `make check` passed lint, 26 Swift tests, four optimized Python tests, Debug build and Xcode analysis; `make build-universal` passed both slices, deployment, signatures/layout/runtime library inspection. No new dependencies. |
| VAL-HELPER | Policy, concurrency and grant-storage tests passed; test-only signed probes compile. Installed signed peer/mutation/account/lifecycle matrix unexecuted. |
| VAL-GUI | Model apply/grant/remove/conflict/replacement tests passed; launched native app and inspected screenshot/accessibility tree. XCTest failed before runner connection, both initially and after test signing/debugger corrections; no tests executed in those UI attempts. Full VoiceOver/light/dark/signed-write matrix remains open. |
| VAL-CLI | Parser/JSON/error tests and `make test-cli` passed; actual universal Release CLI checked too. Installed helper-backed writes remain unexecuted. |
| VAL-POWER | Unexecuted; attended protocol documented. |
| VAL-RELEASE | Tooling and four synthetic verifier rejection tests passed. Actual ad-hoc candidate rejected by identity verifier under `PYTHONOPTIMIZE=1` as expected. No Developer ID archive/notarization/clean-install proof. |
| VAL-HARDEN | Code review, fixes/re-review and independent checks complete. Runtime/GUI gate failures remain open. |
| VAL-FINAL | Not passed: signed, physical and full UI evidence missing. Partial handoff only. |

Retained ignored evidence: `.build/final-check.log`, `.build/final-cli.log`, `.build/final-universal.log`, `.build/ui-test.log`, `.build/ui-test-retry.log`, `.build/ui-test-no-debugger.log`, `.build/TestResults/UI-20260927-004605.xcresult`, `.build/TestResults/UI-20260927-010000.xcresult`, `.build/app-window.png`. Last UI error: “The test runner hung before establishing connection.” Initial run failed; the signing retry was interrupted after reproducing the startup hang; final no-debugger attempt independently failed with exit 65. A targeted sample showed the runner at `_dyld_start`; Developer Tools mode was enabled. Root cause remains unresolved; no host permissions were changed.

Project/workspace/scheme regeneration is hash-stable. Python sources compile and the release shell passes syntax checking. `git diff --check` sees no tracked diff because this repository has no commit; it is not used as proof that untracked files were reviewed. Full new source was inspected by path, formatter, compiler and review passes.

## Signing resumed — 2026-09-27

- User confirmed the certificate/private key was imported and authorized signing. A targeted Keychain identity query finds the expected valid Developer ID Application identity.
- Created ignored, owner-only `Configurations/Local.xcconfig` for the approved identity/team. Bundle IDs and entitlements are unchanged; no private key was exported and no broad Keychain ACL was granted.
- Compiled a disposable signing probe under `.build/SigningProbe/`. Local codesign opened a SecurityAgent window and waited for interactive approval. The initial 90-second attempt timed out; a second attempt is pending without that short timeout so the user can approve locally. No signing success is claimed yet.
- Asked the user to approve the Keychain prompt on the Mac mini and enter any password only in macOS. Signed archive destination is available; archive/verification will follow successful key access.
- Historical records of no installed signing identity describe the earlier implementation turn and are superseded by this update. No helper installation or schedule mutation was performed.

## Signed candidate verified — 2026-09-27

- User approved the local Keychain prompt. The pending disposable probe completed: Developer ID signing, strict signature verification and execution all passed.
- Ran `make archive` with the approved identity/team. Archive succeeded; bundle verification passed arm64/x86_64 slices, macOS 14 deployment, daemon layout and signatures. Release identity verification passed matching Developer ID team, expected identifiers, hardened runtime and restricted entitlements for app, helper and CLI. All three components have secure signing timestamps.
- Ran the actual archived CLI contract check: read-only status, JSON error/exit handling and help passed. No schedule writes or helper registration occurred.
- `spctl --assess --type execute --verbose=2` rejected the candidate with `source=Unnotarized Developer ID` (exit 3). This is an open notarization gate, not a successful Gatekeeper assessment.
- Archive: `.build/Release/MacPowerScheduler.xcarchive`; signed candidate ZIP: `.build/Artifacts/MacPowerScheduler-signed-unnotarized.zip`; SHA-256: `d0431f38682989b96416ec531dad8076083fa878d720b898981a03e80ceeaf2b`. Retained local build evidence: `.build/signed-archive.log`.
- Notarization was not submitted. User did not know the command-line credential-profile terminology; explained separate Apple authentication and opened the signed archive in Xcode for the normal account/distribution interface. No account password or private key requested in chat.
- Signing availability blocker is resolved. `VAL-SPIKE`/`VAL-HELPER` still require approved installed runtime tests; `VAL-RELEASE` has signed build proof but no notarization/clean-install proof. XCTest startup and physical power gates remain open. No full release completion claimed.

## Apple notarization submitted — 2026-09-27

- User confirmed Xcode account sign-in. Used Xcode Organizer → Distribute App → Direct Distribution on the verified archive. No App Store publication was selected.
- Xcode reported the app uploaded successfully to Apple notary service; the current notarization status is Processing. Acceptance, ticket stapling and Gatekeeper approval are not yet claimed.
- The signed-in Xcode account supplied authentication; no account password, API key or exported credential was read or stored in project files. No notarytool Keychain profile was necessary for this GUI workflow.
- Local UI evidence remains under ignored `.build/`; no helper installation or schedule changes occurred.

## Notarized candidate verified — 2026-09-27

- Apple accepted the submission; Xcode Organizer reported Ready to distribute. Exported its accepted archive using `xcodebuild -exportNotarizedApp`; export succeeded. The original workspace archive lacks Organizer submission metadata, so exporting that original copy failed before selecting the accepted Organizer archive. No re-signing workaround or trust relaxation was used.
- The exported app passed `Tools/verify_bundle.py`, `Tools/verify_release_identity.py`, deep strict codesign verification, `xcrun stapler validate`, and Gatekeeper assessment: accepted, source Notarized Developer ID. The actual exported CLI passed read-only status, JSON error/exit handling and help checks. Sandbox-restricted signature checks initially failed; the same unchanged files passed normal host validation outside the sandbox.
- Candidate: `.build/Release/Notarized/MacPowerScheduler.app`; packaged artifact: `.build/Release/MacPowerScheduler.zip`; checksum file: `.build/Release/SHA256SUMS`.
- SHA-256: `9f033a7283678a54cae171345651e275d017d5618c412969e492b94b15520e0d`. Re-extracted the final ZIP and independently passed deep strict signatures, ticket validation and Gatekeeper assessment on that copy.
- Local ignored evidence includes `.build/notarized-export.log` and `.build/Release/notarization-xcode.json`. No credentials or submission identifiers are included in tracked documentation.
- Signing and notarization blockers are resolved. `VAL-RELEASE` now has signed/notarized packaging proof; clean installation and helper lifecycle remain unexecuted. `VAL-SPIKE`, installed `VAL-HELPER`, full `VAL-GUI`, `VAL-POWER` and `VAL-FINAL` remain open. Earlier dated pending-signing/notarization statements are historical, superseded by this receipt.
- No helper installation, account grant, schedule mutation, power cycle, Git commit, push or public release occurred. Runtime compatibility remains tested on Intel macOS 15.7.4 only; macOS 14 and arm64 have compilation/packaging evidence only.

## UI test investigation and repair — 2026-09-27

- User requested cloning TetrisMac into the Developer folder and fixing tests before other work. Cloned the repository at `be63a47b2a1a524b0062e1d104d2f8d399ce9f0d`; its working tree remains clean. Read its Makefile, test plans, signing configuration and prior validation records. Its default Xcode plan runs `TetrisMacKitTests` package tests, not an `XCUIApplication` UI-runner target. Its ordinary `make test` also permits a package fallback; its strict target preserves Xcode failures. The comparison does not claim a fresh local run of the entire Tetris suite.
- Reproduced the original pre-XCTest startup stall outside the execution sandbox. Absolute DerivedData paths and standard LLDB launch settings alone did not fix it. Process samples initially stopped at `_dyld_start`; macOS logs separately identified ad-hoc signature rejection and missing eligible provisioning profiles.
- The generated UI target had forced ad-hoc signing and an empty team. Changed only the test target to automatic Apple Development signing with `PROVISIONING_PROFILE_REQUIRED=YES`, inheriting the private team setting. Xcode's runner claims an application identifier; requiring its profile makes missing test-device registration a clear build error. Restored the standard LLDB TestAction after the earlier no-debugger experiment. App/helper/CLI production signing and authorization settings are unchanged.
- With the configured Xcode account, obtained a development identity and matching profile and registered this test Mac. Boolean checks verified profile expiration, application-ID coverage, installed-certificate match and hardware coverage. No credentials, certificate values or device identifiers are included here. Added explicit `make configure-ui-testing` for this one-time setup; ordinary tests do not automatically register devices.
- Found a second wait in sandbox initialization: the old test-only container belonged to the earlier ad-hoc identity. Preserved that container in a timestamped backup and preserved the old DerivedData directory. The per-user sandbox service remained waiting for an abandoned container-consent response; normally quitting the notification app released the request, confirmed by a subsequent idle service sample. A service restart was refused by macOS SIP; SIP and security policies were not changed. No production app data was removed.
- An untouched copy of the provisioned runner reached XCTest while the original build-directory executable with the same SHA-256 still stalled before `main`. Xcode's supported `.xctestproducts` packaging workflow also reached XCTest. The precise cause of that host/toolchain path-specific behavior is unresolved; no binary patch, signature bypass, sleep or manual resume is part of the workflow.
- Updated `make test-ui` to build fresh native test products, then execute them with `test-without-building`, retaining products and xcresults. A new failure-propagation regression caught macOS Make 3.81 ignoring `.SHELLFLAGS` in the multi-command recipe; explicit shell error handling now prevents execution after a failed build. Tests cover build failure, test failure, matching product paths with spaces, and generated test-only provisioning settings. Eight Python checks pass under `PYTHONOPTIMIZE=1`.
- Packaged run evidence: `.build/ui-investigation-packaged-run.log` and `.build/TestResults/UI-Packaged.xcresult`. It printed Running tests, then failed initialization with Timed out while enabling automation mode. A test-daemon sample showed LocalAuthentication waiting on the UI Automation authorization request; `automationmodetool` reports disabled mode with authentication required. Asked the user to approve the system prompt locally. No UI test case has passed yet; no authentication requirement was disabled.
- Final `make check` passed after the workflow/regression additions: lint, 26 Swift tests, eight optimized Python tests, Debug build and static analysis. Actual read-only `make test-cli` also passed. Evidence: `.build/test-fix-check-final.log`, `.build/test-fix-cli-final.log`; documentation link audit passed. `make test-strict` was attempted and remains failed/blocked by UI initialization; no fallback is accepted as a pass. Local logs, samples and prompt metadata remain under ignored `.build/`.
- No helper registration, scheduling grant, schedule mutation, shutdown, commit, push or publication occurred. The previously notarized product artifact is unchanged; this repair changes only test/build workflow and documentation.

- Located the pending local-authentication UI agent and brought it to the foreground. The user’s approval reply is pending; enter passwords only in the macOS dialog. Resume with the normal `make test-strict`, not another signing change.

## Test repair verified after local approval — 2026-09-27

- User confirmed Done. Ran the normal `make test-strict`; command exited 0. All 26 Swift tests in five suites, eight optimized Python tooling tests, the actual XCTest UI case and read-only CLI verification passed. No fallback or skipped suite was used.
- `AppUITests.testReadOnlyLaunchAndControls` launched the app, found the schedule headings, both schedule controls and Apply button, captured the window, and terminated the app. It passed in 7.226 seconds. Independent xcresult summary reports Passed, one passed test, zero failures and zero skipped tests on Intel macOS 15.7.4.
- Evidence: `.build/test-fix-strict-approved.log`, `.build/TestResults/UI-20260927-135702-5740.xcresult` and its matching `.build/TestProducts/UI-20260927-135702-5740.xctestproducts`. Earlier initialization failures remain historical evidence; this successful run supersedes their pending authorization status. No authentication requirement was disabled.
- Together with the prior final `make check` pass, this closes the requested test-repair checkpoint. It does not complete the broader `VAL-GUI` accessibility/appearance/signed-write matrix or installed-helper/physical validation. No helper registration, account grant, schedule mutation, power cycle, commit, push or publication occurred.

## Tetris lint, formatting and pre-commit adoption — 2026-09-27

- User explicitly requested the reference's settings and hook. Copied both SwiftLint configurations unchanged except the project-name exclusion; copied SwiftFormat options with the project-name exclusion and Swift 6.2 adaptation. Installed SwiftLint 0.65.1 and SwiftFormat 0.63.0 via Homebrew; no app runtime dependency was added. Reference repository remains unchanged.
- `make lint` and the generated Xcode app build phase run both SwiftLint configurations. `make format` and the hook use SwiftFormat; removed the conflicting Apple formatter command. Existing rule severities are preserved, with no baseline, suppression or relaxed threshold. SwiftLint reports zero violations across the five outer Swift files and 22 package files; SwiftFormat lint passes. Project generation is stable.
- Installed the hook with repository-local `core.hooksPath=Tools/git-hooks`. It formats/re-stages staged Swift files as in Tetris, handles spaces safely, and refuses partially staged files before modification. Omitted the game-specific SwiftGen step because this app has no matching resource generator. Three real temporary-index regression tests passed: formatting/re-staging a spaced filename, preserving partial staging, and leaving non-Swift staging unchanged. No project files were staged and no commit was made.
- Applied the reference style throughout Swift sources/tests. Split long CLI parsing, pmset parsing, service apply, XPC callback and process handling functions to meet the unchanged function-size limit; preserved authorization order, serialized transactions, one-shot continuations and bounded process handling. Removed icon-generation force unwraps and made JSON text conversion explicitly checked. Existing 26 behavioral tests pass.
- `make check` passed with 26 Swift tests, 11 optimized Python tests, Debug build and static analysis. Evidence: `.build/tetris-tooling-check.log`, `.build/tetris-format-check.log`, `.build/tetris-lint-formatted.log`. Shell syntax and reference-config comparisons passed.
- `make test-strict` failed at UI initialization after its package/tooling tests and test build passed: macOS LocalAuthentication returned “Can’t authenticate off console.” No UI assertion ran in this attempt. Evidence: `.build/tetris-tooling-strict.log`, `.build/TestResults/UI-20260927-171449-13441.xcresult`. Asked the user to unlock and leave the desktop active; no authentication requirement was disabled. The earlier successful UI run remains historical evidence, not validation of this newer source state.
- The existing notarized ZIP remains unchanged and predates these source refactorings; a future release candidate must be rebuilt and validated from current sources. No helper registration, schedule/grant changes, power cycle, push or publication occurred.

- Independent `make test-cli` also passed against the current Debug build: actual read-only status, JSON error/exit contracts and help. Evidence: `.build/tetris-tooling-cli.log`. Documentation links resolve. This does not substitute for the blocked UI retest.

## Tetris guidance copied and verified — 2026-09-27

- User requested a verbatim copy with only project-specific differences. Copied `AGENTS.md`, all 17 `ai-rules/` files, and all four `ai-docs/` files from TetrisMac. Adapted platform, modules, tests, tools, UI, signing, and helper boundaries; preserved the previous MacPowerScheduler rules intact and synchronized the locked-block reference. Added routes for the already-installed Swift/native-app skills. This task changed no application code, dependencies, signing settings, reference-repository files, or host power configuration; concurrent tooling work was preserved.
- Reviewed the source-to-copy comparison. All 22 guidance files passed route-target, code-fence, whitespace, locked-block parity, and original-rule preservation checks. All four reference documents passed YAML frontmatter parsing. Relative Markdown links passed after excluding literal link examples inside inline code.
- `make check` initially failed in the sandbox because Swift could not write its normal module cache. The unchanged command with normal host access passed: lint, 26 Swift tests, 11 tooling tests, Debug build, and static analysis. Logs: `.build/guidance-copy-check.log` and `.build/guidance-copy-check-host.log`.
- `make test-strict` with normal host access passed 26 Swift tests, 11 tooling tests, and the test-products build, then failed with exit 2 / Xcode exit 65 before UI test execution. LocalAuthentication reported `Can't authenticate off console` (error -1004), matching the current tooling-validation blocker. No fallback or permission/signing workaround was used; the dependent CLI stage was not reached. This run is failed, not a substitute for the earlier passing strict result.
- Evidence: `.build/guidance-copy-strict.log`, `.build/TestResults/UI-20260927-173745-15089.xcresult`, and matching `.build/TestProducts/UI-20260927-173745-15089.xctestproducts`. Unlock: an active, authorized local GUI session for the normal strict rerun. Installed-helper and physical approvals remain separate and unchanged. No commit, push, or publication was performed.

## Unit-testability and coverage expansion — 2026-09-27

- User requested Swift/macOS best-practice research, >=95% coverage of realistic unit scope, and necessary testability refactoring. Reviewed primary Apple and Swift guidance; sources and scope live in `docs/testing/unit-coverage.md`. Coverage measures execution, not assertion strength, branch completeness or OS acceptance.
- Extracted deterministic policies and small internal process, transport and account-resolution seams; injected the editor calendar. Actual signing, caller UID derivation, root checks, authorization and fixed pmset execution remain in production adapters. Separated four real process/filesystem tests into an adapter target that remains required. No new package dependencies or live privilege bypasses.
- Expanded to 96 unit functions in 14 suites, covering malformed/schema/size boundaries, authorization-before-write, revision/error contracts, exactly-once continuation races, CLI command/output combinations, permissions, editor drafts/conflicts and async operation lifetimes. Parameterized cases increase exercised inputs beyond the function count. Added eight tooling regressions for coverage classification, missing data, exact thresholds, failure propagation, stale-report prevention and evidence retention/cleanup.
- New tests reproduced stale automation state after signing readiness disappears and after helper unregistration fails following successful grant clearing. Fixed those model transitions and clearing an obsolete conflict notice after a successful reload. Red-run evidence: `.build/unit-model-regressions.log`; expanded passing evidence: `.build/unit-coverage-expanded.log` and the fresh run below.
- Fresh unit-only LLVM coverage: **991/1,014 executable lines, 97.73%**. Core 100%; CLI 96.17%; IPC 97.32%; Service 98.37%; System 99.06%; editor/UI logic 95.67%. Whole-package unit-run coverage is **991/2,030, 48.82%**. The declared scope covers 19 logic files and explicitly classifies nine integration/UI files; executable entry points are outside this package metric. `make check` now enforces the aggregate 95% floor and complete file classification. No per-line exclusions or removed required checks.
- `make check` exited 0: lint, fresh 96-test coverage run, four safe adapter tests, 19 optimized Python tests, Debug build and static analysis. Evidence: `.build/unit-coverage-check.log`, `.build/Coverage/latest.{json,md}`, and `.build/Coverage/unit-grp_ic4v/{tests.log,coverage.json,summary.json,summary.md}`. Verified that the retained run contains evidence only; its temporary build tree was removed. Prior baseline/fresh-run logs remain historical evidence.
- Four read-only review passes checked reuse, quality, efficiency and clarity/local standards. Addressed the retained build-cache growth finding with temporary scratch cleanup and tests. All reviewers finished with no remaining actionable findings; reviewer inspection does not substitute for test execution.
- `make test-strict` exited 2 / Xcode 65: all 96 unit, four adapter and 19 tooling tests passed, and test products built, but UI initialization failed with LocalAuthentication -1004, `Can't authenticate off console`. No UI case ran and the dependent CLI stage was not reached. Evidence: `.build/unit-coverage-strict.log`, `.build/TestResults/UI-20260927-180930-18918.xcresult`. This is a failed strict result; the earlier UI pass predates these changes.
- Separate `make test-cli` exited 0 against the current Debug build, validating actual read-only status, JSON errors/exit codes and help. Evidence: `.build/unit-coverage-cli.log`. It does not replace the blocked UI gate. Next: active unlocked desktop for the normal strict rerun, then separately approved signed-helper/hardware work.
- No helper installation, grant change, schedule mutation, power cycle, commit, push or publication occurred. The previously notarized ZIP remains unchanged and does not contain this refactoring. Current runtime evidence remains Intel macOS 15.7.4; this turn did not refresh universal packaging or claim another OS/architecture runtime pass.

## Native coverage reporting without a test rerun — 2026-09-27

- User accepted the recommended LLVM tool and requested avoiding another test run, plus research into SwiftUI testing in the referenced projects. Replaced custom-only presentation with `llvm-cov export/report/show`, passing the manifest's exact 19 source paths. LLVM now generates selected-file JSON/text/HTML and a separate whole-package JSON export. The wrapper verifies scope, input hashes, native totals and the existing 95% gate; no dependency was installed.
- The latest fresh run had intentionally removed its build intermediates, but the earlier `.build/Coverage/unit-_o9p6o91` retained its original binary/profile. Verified its successful 96-test log, matching per-file coverage counters against the latest verified run, and that all package Swift source/test/manifest timestamps predated the binary. Preserved that binary/profile with input hashes for report-only reuse; no coverage was fabricated from JSON and no test executable was run.
- Added `make coverage-report` with optional `COVERAGE_RUN=<retained-input-run>`. It uses saved inputs only and rejects changed Swift sources/tests/manifest or altered binary/profile hashes. Fresh `make test-coverage` still runs the unit suite, retains a roughly 4.6 MB binary plus 92 KB profile, and removes the much larger build tree. Reuse metadata points to the original input directory and explicitly says tests were not rerun.
- Actual report-only export succeeded twice, including the default latest-input selection. The final result remains **991/1,014 lines (97.73%)**, with whole-package unit-run coverage **991/2,030 (48.82%)**. Native HTML: `.build/Coverage/unit-8pwp4anu/html/index.html`; selected JSON/text and whole-package JSON sit alongside it. Verified exactly 19 source pages plus the index, no excluded SwiftUI view page, valid HTML parsing, and parity with prior counters. Logs: `.build/llvm-report-migration.log`, `.build/llvm-report-reuse.log`.
- Ten optimized Python coverage-tool tests passed, including selected-file command arguments, reuse without Swift execution, stale source/artifact rejection, failure propagation and retained evidence/cleanup. Python compilation passed. Log: `.build/llvm-report-tool-tests.log`. These exercise the reporting tool, not application behavior.
- Inspected actual CodeEdit macOS snapshots and app interactions, Kingfisher hosted SwiftUI layout/lifecycle tests and binder tests, Hwp-Swift host/binding tests, Sentry's UIKit sample, and SnapshotTesting's macOS strategy. Findings and a bounded recommendation are in `docs/testing/swiftui-testing-research.md`. Hosted views are testable; our current launch screenshot is not a snapshot assertion. No SwiftUI refactoring, new app tests or snapshot dependency was added.
- Per the user's request, no Swift tests, `make check`, `make test-strict`, app builds or live helper/power checks were rerun. The earlier off-console strict failure remains open. No commit, push or publication occurred.

### 2026-09-27 — R2 snapshot replacement

- Authorization: user explicitly requested removal of UI automation in favor of the discussed Point-Free snapshots. Plan/VAL-GUI revised to R2; no extra live-operation or release authorization inferred.
- Removed AppUITests source/target, Xcode scheme test reference, runner-only provisioning settings and test-ui/configure-ui-testing workflows. Kept app/helper/CLI signing configurations and model/unit/adapter/CLI tests intact. Project regeneration is deterministic.
- Added pinned test-only SnapshotTesting 1.19.6 with its resolved dependency graph. Production content remains SwiftUI; a small lifecycle wrapper owns live refresh, and the shared content accepts a model. NSHostingView is limited to the test harness; synthetic dependencies reject mutations.
- Recorded and visually inspected all 20 references: four enabled combinations, automation, read-only, approval, read error, replacement and conflict, each light/dark. Intel macOS 15.7.4, Xcode 26.3 / Swift 6.2.4, 560×800 at 1×, UTC/en_US_POSIX. No cropped/blank captures or real schedule data in references. Recording deliberately exits nonzero; subsequent comparison-only runs passed.
- `make check` passed: zero SwiftLint violations, 96 unit tests/14 suites, 4 adapter tests/2 suites, 21 tooling tests, 20 snapshot cases, Debug build and static analysis. Scoped coverage: 991/1,014 (97.73%); whole-package unit-only coverage: 991/2,033 (48.75%). The lifecycle/content split adds three excluded executable lines; snapshots do not inflate unit scope. Fresh report: `.build/Coverage/unit-k08n8g36/html/index.html`; log: `.build/snapshot-check.log`. Xcode emitted its non-fatal no-AppIntents metadata warning.
- Negative proof: temporarily withheld one reference and substituted the wrong appearance for another; exactly those two cases failed, neither baseline was created/rewritten, and original bytes were restored in a finally block. Log: `.build/snapshot-negative-proof.log`.
- Four read-only review roles found one recording-environment leak and one stale provisioning sentence. Verification now forces MPS_RECORD_SNAPSHOTS=0, with an inherited-1 regression; active signing guidance was corrected. No material reuse/efficiency findings.
- After those fixes, `make test-strict` passed: 96 unit tests, 4 adapter tests, 22 tooling tests, all 20 snapshots, Debug build and actual CLI read-only status/error/help checks. Log: `.build/snapshot-strict.log`. No app automation runner or UI Automation authentication was used.
- Remaining limits: snapshots prove image comparison only. Busy animation/system dialogs, packaged launch, actual control interactions, keyboard/VoiceOver and signed helper effects retain their manual/attended gates. Earlier R1 automation failures remain historical failures superseded by the explicit R2 contract, not retroactively passed. Earlier notarized artifacts predate this source change.
- No helper registration, grants, schedule mutation, power cycle, commit, push or publication. Snapshot references belong in source control; build/failure logs remain ignored.

### 2026-09-27 — Initial local commit and Swift/Xcode ignore policy

- User authorized a local commit after researching Swift/iOS/macOS gitignore practices. Adapted the current GitHub Swift, Xcode and macOS templates; retained Package.resolved per Apple's app-build guidance. Sources and rationale are linked in README.
- Ignored Xcode/SwiftPM products, user state, profiling/test artifacts, macOS metadata, local signing configuration, credential formats and tool caches. Preserved generated Xcode project/workspace/shared schemes, shared package configuration, source/assets, lockfile and all 20 snapshot references. No unused CocoaPods/Carthage/fastlane policy added.
- Proof: 25 ignored-path cases and 13 retained-path cases passed git check-ignore. SwiftFormat lint passed with no changes. All 22 tooling tests passed. The earlier R2 make check/test-strict results remain the app validation evidence; the ignore policy changes no app behavior.
- Codex autoreview (`autoreview --mode local --engine codex`) completed in two bounded passes with zero findings. The helper cannot accept PNG binary content, so its input was an isolated byte-for-byte copy of all 118 text files, with a hash inventory for 30 separately inspected images. Verified every copied file and image hash against the actual commit candidates. Review reports remain outside the repository; logs are ignored.
- Secret scanning identified a Python test method name as a false credential match. Confirmed the match was exactly the identifier, shortened the method name without changing assertions, and reran tooling tests and review successfully. No credential was added or exposed.
- Staged 148 intended project files, including all snapshot references and the lockfile. Existing formatter-compatible whitespace notices in copied guidance/configuration and the CLI multiline help string were left unchanged. The source checkpoint is not a release-readiness claim: signed-helper, manual UI and physical gates remain open. No push, publication or live power operation authorized.

### 2026-09-27 — Preserve editor drafts through read failures

- User requested verification and a TDD fix for the suspected loss of unsaved edits. Added deterministic Swift Testing sequences using the real ScheduleModel and injected readers/helper/platform fixtures; no real scheduling or authorization occurs.
- Red: before production changes, the new recovery regression failed in both parameter cases. A failed read cleared the editor revision/dirty state; recovery reset 08:00 to 07:30, or discarded the draft and conflict when the system schedule changed. Clean-editor and explicit-discard controls already passed. Evidence: `.build/DraftPreservation/red.log`.
- Fix: retain the draft's baseline independently of the latest readable system snapshot, derive editRevision from that baseline, and compare unsaved changes against it. Unreadable state still clears current and disables Apply. Successful recovery preserves edits and stale-revision detection; explicit reload and successful apply establish a new baseline. README documents the behavior; this is release-note context for a future landing.
- Green: all 19 model tests passed, including four new parameter cases covering unchanged/changed recovery and clean/explicit-discard behavior. Evidence: `.build/DraftPreservation/green.log`.
- Full verification: `make check` and `make test-strict` passed with 98 unit tests, four adapter tests, 22 tooling tests, 20 unchanged snapshots, Debug build, static analysis and actual read-only CLI checks. Fresh scoped coverage: 993/1,016 (97.74%). Logs: `.build/DraftPreservation/check.log` and `strict.log`; coverage: `.build/Coverage/unit-7y847md4/`. Xcode's no-AppIntents metadata warning remains non-fatal. SwiftFormat and diff whitespace checks passed.
- Signed-helper, manual packaged-app/accessibility and physical gates remain open. No helper registration, real schedule/grant changes, commit, push or publication; the earlier notarized candidate predates this fix.

### 2026-09-28 — Public README and contributor guidance

- Maintainer reports tests completed successfully on this Mac. Confirmed the host remains Intel / macOS 15.7.4; the existing hardware record identifies the Mac mini. This is a maintainer-reported functional result, not a new agent-executed trust/lifecycle/power matrix or release-artifact validation.
- Rewrote README around capabilities, an existing synthetic screenshot, setup, CLI use, limitations, removal, source builds, and license. Moved detailed development workflow out of the introduction and preserved signing/automation/removal explanations. No download URL or published-release claim was invented; this checkout has no origin remote.
- Maintainer selected an open contribution policy: accept PR submissions freely, including substantial features, without requiring an issue first. Added CONTRIBUTING.md with build/signing instructions, check commands, snapshot-environment limitations, review expectations, project structure, and repository maintenance. Submission does not promise acceptance; no required AI tooling was introduced.
- Documentation validation passed local-link/image-path checks, Make-target checks, code-fence balance, and diff whitespace checks. Application code, snapshots, build configuration, and dependencies are unchanged; the previous passing check/strict evidence remains applicable and suites were not rerun for this documentation-only change.
- No commit, push, publication, helper operation, or power-schedule change performed.

### 2026-09-28 — Local documentation commit authorization

- User explicitly requested committing all pending work and leaving Git clean, with separate commits where appropriate. The README rewrite, CONTRIBUTING.md and their planning notes form one documentation change; the Settings refresh alignment fix is separate.
- Rechecked README/CONTRIBUTING local links and screenshot paths, documented Make targets and code-fence balance against the current checkout. All pass. No external publication or live system operation is included.
- Pre-commit Codex autoreview covered the complete pending text changes and returned no actionable findings. The concurrent Settings fix also passed fresh `make check` and `make test-strict`; its separate evidence receipt lives in the Quiet Agenda progress file. Local commit authorization does not close the outstanding attended release gates.

### 2026-09-28 — Readiness review at `3ba85ee`

- Reviewed the committed draft fix, Quiet Agenda/Deep Sapphire UI, Settings alignment and contributor documentation. Fresh `make check` and `make test-strict` passed at `3ba85ee`: 100 unit tests in 15 suites, 4 adapter tests, 22 tooling tests, 50 snapshot cases, Debug build/static analysis and actual CLI read-only status/error/help checks.
- Fresh scoped coverage: 1024/1047 executable lines, 97.80%. Inputs: `.build/Coverage/unit-n41pzgou/`; snapshots and live integration remain outside the deterministic unit numerator. Logs retained locally in `.build/ReadinessReview/check.log` and `.build/ReadinessReview/strict.log`; these ignored artifacts are not public documentation attachments.
- Maintainer-reported functional success on this Intel Mac mini / macOS 15.7.4 remains valid evidence at its stated scope. This review performed no new helper registration, grant change, schedule mutation or power cycle. It did not create or validate a new release artifact.
- Documentation reconciliation updates current status, committed-work references, UI routing and architecture guidance while retaining historical receipts. The approved current accent is Deep Sapphire. Detailed release matrices and the remaining attended UI checks are tracked as evidence gaps, not as a claim that the maintainer did no testing.
- Documentation validation: all 31 local Markdown links/anchors across the nine changed files, rule-loading paths, code fences, file lengths and `git diff --check` passed. Application suites were not repeated for these documentation-only edits; the source checkpoint above is unchanged. No commit or push performed.

### 2026-09-28 — Pull-request CI preparation

- Added a hosted Intel macOS 15 / Xcode 26.3 workflow for PRs, main pushes and manual dispatch, running the existing check, strict and universal-build targets. Actions use verified upstream commit pins; lint/format tools use versioned archives with verified SHA-256 digests. Read-only token, no persisted checkout credentials, no release secrets or helper operations, and seven-day evidence retention.
- Preserved current snapshot references and strict failure behavior. The hosted OS may differ from the recorded baseline; its first run must establish reproducibility or produce reviewed mismatch evidence. No hosted result is claimed.
- Recommended main ruleset: PR required, zero mandatory approvals for the single maintainer, required up-to-date CI from GitHub Actions, resolved conversations, force-push/deletion blocks and no routine bypass. These settings are documented, not applied. Repository URL/creation choice is pending; no Git remote is configured.
- Local workflow checks passed: actionlint 1.7.12, YAML and embedded Bash syntax, upstream archive checksums/layout/version execution, and failure propagation through the same Bash/tee pipeline used by Actions. Initial `make check` was blocked by compiler-cache sandbox access; the unchanged required targets were retried with approved access.
- Fresh `make check`, `make test-strict` and `make build-universal` all passed locally. Scoped coverage remains 1024/1047 (97.80%); retained inputs are `.build/Coverage/unit-__vdjcdd/`. Logs are under `.build/CI-local/`, including the original sandbox failure and successful retry. Local builds retained the project's configured signing; this does not claim execution of the hosted ad-hoc configuration or certify a notarized release candidate.

### 2026-09-28 — Private repository and first hosted CI

- Created `aruffolo/MacPowerScheduler` as private, connected `origin`, and pushed the reviewed CI setup in `9385c35`. Verified private visibility and the exact run head SHA. TruffleHog history scan completed with zero findings; no local signing configuration was tracked.
- Hosted run `36434752282`, attempt 1, passed in 7m52s: check, strict tests/CLI smoke, universal build, unchanged tracked files and evidence upload. Intel macOS 15.7.9, Xcode 26.3 / Swift 6.2.4, image `20260824.0482.1`; scoped coverage 1024/1047 (97.80%), all 50 unchanged snapshot cases passed. Downloaded evidence is retained locally under `.build/CI-hosted/36434752282/`.
- GitHub's successful check is `macOS validation`, emitted by `github-actions` app ID 15368. Ruleset access returned HTTP 403 requiring GitHub Pro or public visibility. No protection or visibility change was applied; public conversion remains a separate authorization.
- The successful run warned that upload-artifact v4's Node 20 runtime was being forced to Node 24. Updated only that action to verified upstream v7.0.1 commit `043fb46d1a93c77aae656e7c1c64a875d1fc6a0a`, whose action manifest specifies Node 24 and preserves the inputs used here. Workflow results for subsequent revisions are linked from the CI guide.

### 2026-09-28 — Universal and arm64 release candidates

- User requested both downloadable app variants and comparison with CodexBar. Adopted versioned ZIP names, separate dSYMs, portable SHA-256 checksums and extracted/downloaded verification. No update framework or new dependency was introduced. App source remains unchanged from `51f5495`; this change owns only release tooling, tests and documentation.
- Added exact-architecture validation for app/helper/CLI and embedded Mach-O libraries, separate variant archives, matching executable/dSYM UUID checks, stapled-ticket and Gatekeeper requirements, and staged ZIP verification before final artifact promotion. Existing archives and final ZIPs are preserved rather than overwritten.
- TDD: the new architecture verifier tests first failed against the original universal-only implementation, then passed. All 33 tooling tests now pass, including both variants, wrong architectures/deployment, mismatched symbols, local-home-path rejection and failed extraction verification publishing no ZIP.
- Fresh `make check`, `make test-strict` and `make build-universal` passed; logs are retained under `.build/Release/validation/`. These include 100 unit tests, 4 adapter tests, 50 snapshots, Debug build/static analysis and read-only CLI checks. Later release-only symbol sanitization was validated with fresh signed archives and the full 33 tooling tests.
- Initial symbol inspection found local source paths in serialized Swift debugging options. Xcode appended its own enabling flag after the attempted frontend override. The final archives instead set `SWIFT_SERIALIZE_DEBUGGING_OPTIONS=NO` and remap the source root; all app/helper/CLI DWARF files now match their binaries and contain no local home path. A full ZIP-content scan then caught local binary paths in relocation YAML outside DWARF. Packaging now normalizes that field in a staged copy and scans every symbol file; two new regressions failed first, then passed. Original archives remain untouched. Earlier candidates remain ignored and are not release assets.
- Explicitly approved Apple uploads completed through Xcode Direct Distribution for both final archives. Exported apps passed exact architectures, macOS 14 deployment, matching Developer ID identities, hardened-runtime/entitlement checks, stapled-ticket validation and Gatekeeper acceptance. Both packaged/extracted ZIPs passed the same checks. The exported Universal CLI passed read-only status/error/help checks.
- Artifacts are under `.build/Release/dist/0.1.0/`: Universal app ZIP 958,918 bytes; arm64 app ZIP 519,606 bytes; matching dSYM ZIPs and SHA256SUMS. App ZIP SHA-256: Universal `bc7565360f3442900202af9e70639974b72553c5ab7030f1c855eba8a9739137`; arm64 `ba7762da4bf259d7536abf66bf4af7b9d11cd6f85975781ff94ee7b28109d3c7`. Raw signing/notarization logs and submission identifiers remain ignored.
- The intended first release is marked pre-release. Apple Silicon runtime, detailed signed-peer/account/lifecycle receipts and attended VoiceOver/Escape evidence remain incomplete; the maintainer's successful Intel functional testing is preserved at its reported scope. No new helper registration, grant/schedule mutation or power cycle occurred. Repository visibility is unchanged.
- Final closeout: Codex autoreview returned no actionable findings before and after the independently discovered metadata fix; both secret scans were clean. Fresh final `make check` and `make test-strict` passed with all 33 tooling tests. All five assets were uploaded to a private draft, downloaded, compared byte-for-byte and verified against SHA256SUMS. Both downloaded app ZIPs passed extracted signature/architecture/ticket/Gatekeeper checks and matched their downloaded dSYMs; the downloaded Universal CLI passed the read-only process suite. Local evidence: `.build/Release/downloaded/verification.log`, `.build/Release/validation/check-final.log` and `strict-final.log`. Publication is gated on exact-head hosted CI; no stable-release or public-visibility claim is implied.

### 2026-09-29 — v0.1.1 pre-release published

- Published [v0.1.1](https://github.com/aruffolo/MacPowerScheduler/releases/tag/v0.1.1) at 2026-09-28 22:06:44 UTC, build 2, tag/source `bf442cb7f60f2d6b0933a9649ae58758ec47de24`. Includes the sapphire Precision Power icon and content-sized main/Settings windows. Release is not a draft; pre-release status and private repository visibility are preserved.
- Fresh local `make check`, `make test-strict` and `make build-universal` passed. [Hosted CI 36489163828](https://github.com/aruffolo/MacPowerScheduler/actions/runs/36489163828), attempt 1, passed on the exact release source, including all 50 updated image snapshots and 41 hosted layout cases. Unit/adapter/tooling counts remain 100/4/33; scoped coverage is 1024/1047 (97.80%). Codex autoreview of the release version/changelog diff returned no actionable findings.
- Preserved both v0.1.0 release workspaces under ignored `.build/Release/retained/0.1.0/`. Both new Developer ID archives were accepted through Xcode Direct Distribution, exported from their accepted Organizer archives and packaged with matching symbols. No credentials were created or signing policy changed.
- All five uploaded assets were downloaded and compared byte-for-byte. Both extracted apps passed exact architectures, macOS 14 deployment, signature/identity/entitlement checks, stapled tickets, Gatekeeper and matching downloaded dSYMs; symbol files contain no local home paths. Downloaded Universal CLI read-only checks passed. Universal app ZIP: 4,167,225 bytes, SHA-256 `a4bc2c09d31cdb6025756f995765b4e35ffbf9a1c64f63a6ba4db7bf91054e40`; arm64 app ZIP: 3,718,236 bytes, SHA-256 `6eec0cce21741e43c1f2992e950c5c4d87b1d5fb92309f561644c33277358824`.
- The notarized Universal candidate launched on Intel macOS 15.7.4. Main window measured 600×730; Settings measured 520×484 with all controls visible and no unnecessary scrollbar. Settings open, read-only Refresh Status and Done dismissal succeeded through local accessibility actions, resolving the earlier bridge-only interaction blocker. Quit only the candidate launched for this check; the existing development app was preserved. No helper registration, grant change, schedule mutation or power cycle occurred.
- Release notes retain incomplete Apple Silicon/macOS 14 runtime, attended helper/account/lifecycle, physical power-cycle and detailed keyboard/VoiceOver evidence. Local receipts, captures and logs remain ignored under `.build/Release/v0.1.1-evidence/`; published assets and downloaded verification copies are under `.build/Release/dist/0.1.1/` and `.build/Release/downloaded/0.1.1/`. Exact-head hosted evidence is retained under `.build/Release/hosted/36489163828/`.
