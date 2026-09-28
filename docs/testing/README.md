# Validation procedures

`make check` runs SwiftLint, a fresh unit test run enforcing 95% coverage of the declared deterministic logic, safe process/filesystem adapter tests, optimized-mode tooling tests (including pre-commit index safety), SwiftUI snapshots, Debug build, and Xcode static analysis. SwiftLint uses the separate app/package settings copied from TetrisMac and also runs in the Xcode app build phase; its configured errors fail the build and warnings remain warnings, as in the reference. `make format` and the pre-commit hook use SwiftFormat instead of Apple’s `swift-format`. Install both tools with `brew install swiftlint swiftformat`, then enable the local hook with `make install-hooks`. `make test-strict` runs unit, adapter and tooling tests, SwiftUI snapshots, and an actual CLI subprocess smoke with no mutation. It propagates failures. `make build-universal` builds both architectures and checks embedded executable slices, deployment metadata, signatures, and daemon layout; ad-hoc signatures are permitted for this build-only check.

## SwiftUI snapshots

`make test-snapshots` runs `PowerScheduleSnapshotTests` with Swift Testing and Point-Free SnapshotTesting 1.19.6. Both `make check` and `make test-strict` require it. The dependency is test-only; production views remain SwiftUI. `PowerScheduleView` owns live refresh lifecycle, while the shared `ScheduleContentView` accepts a model. The test harness renders that same content through `NSHostingView`, using synthetic readers/helper replies and platform fakes that reject mutations.

Fifty reference images cover thirteen main-screen states, seven Settings states, and five layout fixtures, each in light/dark appearance. Main states preserve all four schedule combinations, automation enabled, read-only signing, pending helper approval, read failure, an existing weekday schedule requiring replacement, and a dirty draft conflicting with external changes; they add registration needed, helper unavailable, and a draft differing from saved times. Settings fixtures cover access and automation status without invoking mutations. Unit tests continue to prove model decisions and actions. Animated busy indicators, system dialogs and actual click/keyboard/VoiceOver behavior are outside this image suite.

References live in `Package/Tests/PowerScheduleSnapshotTests/__Snapshots__/`. Normal tests use `.never` recording: missing or different images fail and cannot approve themselves. `make test-snapshots` explicitly disables recording even if the shell inherited a recording flag. To intentionally change references, run `make record-snapshots`, inspect every changed PNG against the intended UI, then run `make test-snapshots` without recording. Point-Free reports recording as a test failure to require that second verification. Do not bulk accept references to make a failure disappear.

Baseline environment: Intel macOS 15.7.4, Xcode 26.3 / Swift 6.2.4, content captured at 1×, UTC Gregorian calendar, explicit Aqua/Dark Aqua appearance and no view animation. Main fixtures use 580 × 684 points and `en_US_POSIX`; Settings uses 520 × 580. The `en_GB` layout fixtures include the concept's 24-hour reference (580 × 684), minimum viewport (520 × 620), minimum-width expanded content (520 × 800), resized content (760 × 800), and a visible long error at minimum size. Native titlebar/gear placement is checked in the signed app, outside hosted content snapshots. Compare on the same OS/toolchain/display scale; rendering differences on another environment need reviewed baselines, not a relaxed pixel tolerance. This environment pin is a test requirement, not an increase to the app's macOS 14 deployment target.

There is no app UI automation target, generated runner, UI Automation authorization step or runner provisioning command. Snapshots do not launch the packaged app. Before release, manually verify the signed packaged app launches, refreshes on foreground, supports keyboard/VoiceOver, and presents/cancels confirmations correctly. Privileged interactions still require the separately approved installed-helper setup.

## Coverage

See [unit scope, exclusions, measurement and Apple/Swift guidance](unit-coverage.md). `make test-unit` excludes real process/filesystem tests and snapshots; `make test-adapters` runs those separately. All three layers remain mandatory through `make check` and `make test-strict`. `make test-coverage` reports scoped and whole-package execution separately, and fails on unclassified production package files or missing coverage data.

LLVM produces the selected-file HTML/text/JSON reports. `make coverage-report` reuses verified saved inputs without rerunning tests; a changed source or input artifact requires a fresh measurement. See [SwiftUI testing research](swiftui-testing-research.md) for hosted macOS snapshots, the adopted snapshot approach and its limits.

Package tests cover malformed times and decoded values, complete/partial edits, stale revisions, replacement, parser errors, process bounds, isolated authorization/grant behavior, concurrent service requests, grant storage protections, editor refresh/conflicts, and JSON output. They never instantiate a privileged live mutation path. Test-file cleanup is restricted to each test's random temporary directory.

Live helper validation is a distinct attended gate. On a specifically approved signed test installation, record the baseline and test identity/authorization matrix: approved app/CLI, wrong identifier/team, unapproved account, granted account, revoked grant on an existing connection, invalid authorization, malformed/version-mismatched requests, and parallel requests. Denied operations must leave the schedule unchanged. Demonstrate all four desired pairs and a partial CLI edit with readback, GUI closed CLI use, pending/revoked macOS service approval, update/re-registration, and removal. Compare one-time events without retaining personal owner strings. Restore only if current state is still the test's last written state; otherwise reconcile with the user. This matrix is not replaced by the in-memory unit tests.

Live commands are deliberately not included in default test targets. The test-only `HelperIntegrationProbe` product is never embedded in the app. On an approved installed helper, run:

```sh
MPS_SIGNING_IDENTITY='your approved signing identity' python3 Tools/verify_helper.py \
  --app /Applications/MacPowerScheduler.app --allow-installed-helper-probes
```

The script signs isolated test copies, checks accepted/incorrect identifier/ad-hoc peers, malformed/oversized/version-mismatched requests and unauthenticated grant denial. Accepted controls bracket negative tests; a dead helper or timeout cannot pass as peer rejection. It privately compares all scheduled events before/after without retaining owner details. It submits no valid schedule mutation. A distinct second-team identity, second account, open-connection revocation, valid writes and lifecycle tests still need the attended matrix below and their own observed evidence before `VAL-HELPER` passes. Missing signing or other-account fixtures must be recorded as blocked, not silently omitted.

Use [power-cycle.md](power-cycle.md) for hardware evidence. Reviewed snapshot reference PNGs belong in source control; failure images, manual captures, build logs and release artifacts stay under ignored `.build/`; retain concise sanitized results in the plan's progress ledger. Inspect keyboard/VoiceOver behavior, light/dark appearance, and text sizing manually before release in addition to the automated snapshot suite.

## Attended mutation/account matrix

Use the actual bundled CLI with the GUI closed and a future, approved pair of times safely outside the test window. Capture `status --json` and one-time-event fingerprints before testing. Keep the current expected revision from each successful response.

1. With automation disabled, `set --startup HH:mm --if-current REV --json` must return authorizationRequired and leave all events unchanged.
2. Grant only the primary test account in the GUI. Apply startup-only, shutdown-only, both and neither using complete `set` commands with expected revisions. Each successful response must equal a separate `status` read. A startup-only partial edit must preserve shutdown.
3. Resubmit a stale revision: conflict with no change. Send simultaneous edits using the same revision: exactly one success, one conflict. Verify one-time events remain unchanged.
4. From a second ungranted account, mutation must fail. Revoke the primary account in the GUI, including while a raw test connection remains open; its next valid mutation must fail. No client-supplied UID can change this identity.
5. Verify invalid/tampered schedule ranges fail even for the granted account; record the test-only payload and expected rejection. A second-team signed peer must fail authentication while the accepted control still succeeds.
6. Before restoration, require actual state to equal the test's last verified state; restore the approved baseline with that revision. If any external edit or uncertain result occurred, stop and reconcile first. Never overwrite an unexpected state.

The script does not automate these valid writes, administrator prompts or account switching. This preserves the need to agree on concrete future times and a recoverable test baseline before using the real host.

## Fixture provenance

Parser fixtures include the minimized development-host repeating shutdown output and independently written examples of Apple's published [pmset formatter](https://github.com/apple-oss-distributions/PowerManagement/blob/main/pmset/pmset.m): `0:00AM`, `weekdays only`, `weekends only`, `Some days`, and `No scheduled events.`. Custom-day plist fixtures follow Apple's repeating-event keys/day bit masks and the storage path documented in the installed `pmset(1)` FILES section. Malformed text, explicit weekday names, seconds, concurrency and failure cases are synthetic tests, not captured hardware evidence. Real custom schedules are not claimed tested.

The test-only probe deliberately bypasses the production client's self-signing preflight so an ad-hoc or incorrectly identified process reaches the real listener. It still authenticates the server. No such bypass exists in shipped targets.
