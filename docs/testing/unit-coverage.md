# Unit test scope and coverage

Target: at least 95% executable-line coverage of deterministic production logic. Coverage is a gap-finding tool, not proof that assertions are correct or that macOS accepted an operation. This target supplements every existing integration, UI, signed-helper, and hardware gate.

## What is unit-testable

- Core values, revision changes, edit validation, replacement/preservation policy, and fixed command argument construction.
- CLI parsing, JSON/human output, exit codes, and orchestration with injected reads/helper replies.
- pmset and property-list parsing, plus read/write orchestration with injected process results and privilege state.
- Service authorization decisions, account grant policy, serialized mutations, fresh reads, and uncertain results using in-memory dependencies.
- IPC message size/schema/error handling, signing-requirement construction, and one-shot callback completion. Actual signed peer authentication remains an integration gate.
- Editor state, dirty drafts, conflicts, permission/error states, authorization lifetime, and actions with injected platform/helper/read dependencies and calendar.

## Separate evidence

OS adapters are not inherently untestable; their real contracts require integration tests. Process launch/pipes/timeouts and isolated on-disk grant permissions use a separate safe adapter suite. Code-signing inspection, Authorization Services, OpenDirectory, NSXPC listener/connection wiring, ServiceManagement approval, SwiftUI rendering, and executable composition require macOS integration or UI validation. Physical cold startup, wake, and normal shutdown require attended hardware evidence. None is proved by injecting a fake.

The [coverage manifest](../../Tools/unit-coverage-scope.json) classifies every production Swift file in `Package/Sources`, includes logic extracted from mixed adapter files, and states each exclusion's reason. New unclassified files and missing coverage entries fail the report. It reports the scoped numerator/denominator, each module/file, and whole-package unit-run coverage; never silently shrink the denominator to meet the target. The thin App/Helper/CLI executable entry points are outside this package metric and require build/integration validation. No per-line suppression, generated successful replies in production, or relaxed signing/authorization is permitted.

## Commands and enforcement

- `make test-unit`: deterministic package unit tests with injected external dependencies; excludes adapter and snapshot suites.
- `make test-adapters`: safe real process and temporary-filesystem tests; no privileged operations.
- `make test-coverage`: fresh instrumented unit run, failing if aggregate executable-line coverage of the declared unit scope is below 95%. Uses LLVM line counters, weighted by executable lines rather than averaging file percentages. Reports module percentages without separate module thresholds.
- `make coverage-report`: regenerate reports from the latest retained binary/profile without building or running tests. Use `COVERAGE_RUN=.build/Coverage/unit-...` to select a specific retained input run. Reuse fails if package Swift sources, tests, manifest, binary or profile hashes changed; it never silently runs tests instead.
- `make check`: lint, the coverage gate, adapter tests, tooling tests, SwiftUI snapshots, Debug build and static analysis.
- `make test-strict`: unit, adapter and tooling tests, SwiftUI snapshots and the read-only CLI subprocess contract. A coverage pass cannot substitute for this command.

The Xcode-bundled `llvm-cov` owns file filtering and report generation: `export` produces `unit.json` and `package.json`, `report` produces `unit.txt`, and `show -format=html` produces `html/index.html` with per-source drill-down. The manifest's exact unit file list is passed through `--sources`. The Python wrapper validates classification/provenance, checks LLVM's filtered total against the 95% floor, and provides a compact summary. No external package or hosted service is required.

The latest summary is `.build/Coverage/latest.md`, linking the native HTML report, with machine-readable `.build/Coverage/latest.json`. Each fresh run retains its test log, LLVM exports, summary, matching test binary/profile and SHA-256 input record under `.build/Coverage/unit-*/`; large temporary build intermediates are removed after success or failure. Re-rendered reports record `reused: true` and their original `inputDirectory`, rather than claiming fresh tests. A failed scope check, LLVM command or test run replaces the latest summary with a failure. Prior integration profiles cannot inflate a fresh measurement because it builds in a new scratch directory. The retained binary is about 4.6 MB and its profile about 92 KB for the observed build, instead of retaining the whole 171 MB build tree.

The R2 unit suite measured **991/1,014 executable lines (97.73%)** on 2026-09-27: Core 100%, CLI 96.17%, IPC 97.32%, Service 98.37%, System 99.06%, and editor/UI logic 95.67%. Whole-package coverage from that unit-only run is **991/2,033 (48.75%)**, including excluded adapters and views. The previous 48.82% denominator was 2,030; splitting the SwiftUI lifecycle from content added three executable lines outside unit scope. Snapshot execution does not inflate this metric. These are execution metrics, not branch coverage or whole-app validation. Current command outcomes and limitations belong in the [progress ledger](../plans/initial-release/progress.md).

## Test design

Assert externally observable results and prohibited side effects, including exact error categories, unchanged state after denial, argument arrays, revision propagation, and authorization-before-write ordering. Use parameterized boundary cases, fresh fixtures per test, and awaitable signals rather than sleeps. Keep tests parallel-safe. Prefer focused initializer injection and pure transformations over exposing private implementation solely for coverage. Preserve production defaults and authentication checks.

SwiftUI components can also be tested in a host view, even though they are outside the current deterministic unit gate. See [open-source SwiftUI testing findings](swiftui-testing-research.md) for snapshot, layout/binding and full-app interaction examples and the adopted snapshot layer for this project.

## Primary sources reviewed (2026-09-27)

- [Apple: Determining how much code your tests cover](https://developer.apple.com/documentation/xcode/determining-how-much-code-your-tests-cover): coverage identifies missing execution but must be paired with strong tests. Apple does not prescribe a universal 95% threshold; that is this project's chosen target.
- [Apple: Testing Tips & Tricks, WWDC18](https://developer.apple.com/videos/play/wwdc2018/417/): separate input/output transformations from external dependencies; use focused unit tests, a smaller integration layer, and end-to-end tests. The testability principles also apply to Swift Testing.
- [Apple: Go further with Swift Testing, WWDC24](https://developer.apple.com/videos/play/wwdc2024/10195/): assert outcomes, parameterize cases, isolate tests for parallel execution, and await async work/confirmations.
- [Swift Testing: ParallelizationTrait](https://docs.swift.org/latest/documentation/testing/parallelizationtrait/): serialization affects a parameterized test's cases or a suite's descendants, not unrelated suites. Fix shared mutable fixtures rather than globally serializing the suite.
- [Apple: Organizing tests into test plans](https://developer.apple.com/documentation/xcode/organizing-tests-to-improve-feedback): separate test kinds and cadences; retain sanitizers and platform configurations as complementary validation.

Baseline: the existing 26 Swift test functions pass with coverage enabled. CLI execution is 50/78 lines (64.1%), editor state 173/201 (86.1%), and service policy 79/92 (85.9%). This baseline includes the existing process/filesystem tests and is not yet a unit-only metric. Raw baseline remains under ignored `.build/coverage-baseline.json`.
