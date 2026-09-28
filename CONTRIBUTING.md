# Contributing

Pull requests are welcome for bug fixes, documentation, and substantial new features. No issue or advance approval is required to submit a PR. If you want feedback before investing time in a larger change, you are welcome to start a discussion in an issue.

Keep each PR focused on a coherent problem. Larger changes are fine when their purpose, design, and validation are clear. Submitting a PR does not guarantee it will be merged; changes are reviewed for correctness, maintainability, and fit with the project.

## Development setup

Use Xcode 26.3 / Swift 6.2.4. The deployment target is macOS 14. After cloning the repository:

```sh
brew install swiftlint swiftformat
make install-hooks
make build
```

Open `MacPowerScheduler.xcworkspace` in Xcode, or use `make run` to build and open the Debug app. Build products live under `.build/DerivedData/`.

Default source builds are ad-hoc signed and support read-only schedule inspection. You can work on scheduling logic, editor state, parsing, CLI behavior, and snapshots without installing the helper or configuring a signing identity.

### Signing for helper development

Privileged operation requires the app, helper, and CLI to use Apple-issued signing certificates from the same development team. Create the ignored `Configurations/Local.xcconfig` with your `DEVELOPMENT_TEAM` and `CODE_SIGN_IDENTITY`; never commit that file or signing credentials.

Apple Development or Developer ID signing can be configured for source builds. Helper setup still requires macOS approval and validation with your signing configuration. Unsigned and ad-hoc builds remain read-only; preserve peer identity and account authorization checks.

For live schedule changes, helper lifecycle checks, or physical startup/shutdown tests, follow the attended procedures in [testing](docs/testing/README.md) and [power-cycle testing](docs/testing/power-cycle.md). Release signing and notarization are handled separately through the [release procedure](docs/release/README.md).

## Tests and formatting

For code changes, run:

```sh
make format
make check
make test-strict
```

`make check` runs lint, fresh unit coverage, adapter/tooling/snapshot tests, a Debug build, and static analysis. `make test-strict` runs the test suites and the built CLI's read-only subprocess checks. Default tests never install the helper, change the real power schedule, or shut down the machine.

Pull requests are intended to run the same gates in [GitHub Actions](docs/testing/ci.md), plus the universal build check. The workflow's initial hosted verification and branch protection are still pending; snapshot environment differences remain failures requiring review.

For focused work:

| Command | Purpose |
| --- | --- |
| `make test-unit` | Deterministic package logic and model tests |
| `make test-adapters` | Safe process and filesystem tests |
| `make test-snapshots` | Verify reviewed SwiftUI reference images |
| `make test-tools` | Build/release/coverage/hook tooling tests |
| `make test-coverage` | Fresh unit run and the 95% scoped line-coverage gate |
| `make coverage-report` | Regenerate reports from unchanged retained coverage inputs |
| `make build-universal` | Build Release for Intel and Apple Silicon and verify the bundle |

See [coverage scope](docs/testing/unit-coverage.md) for exclusions and report locations. Add deterministic regression coverage for bug fixes when practical; an increased coverage percentage alone does not prove a fix.

Snapshots use an Intel macOS 15.7.4 / Xcode 26.3 baseline with fixed appearance, locale, timezone, and display scale. If your environment cannot reproduce it, include the platform and failure details in your PR. Do not change reference images just to make tests pass. For intentional visual changes, use `make record-snapshots`, inspect each changed image, and verify again without recording. See the [snapshot workflow](docs/testing/README.md#swiftui-snapshots).

SwiftLint runs in Make and Xcode builds. The pre-commit hook formats and re-stages staged Swift files, and refuses partially staged files to avoid including unstaged edits. Verified tool versions are SwiftLint 0.65.1 and SwiftFormat 0.63.0. Lint and formatting conventions are adapted from TetrisMac.

## Preparing a pull request

- Explain the problem, the resulting behavior, and any significant design tradeoffs.
- List the checks you actually ran, including failures or environment limitations. Documentation-only changes need relevant link and example checks, not a full app test run.
- Include before/after images for visible UI changes, using synthetic data and excluding personal information.
- For helper, signing, authorization, or system-schedule changes, explain the affected trust boundary and distinguish fixture tests from live validation.

You do not need to edit a changelog; the maintainer handles release notes when landing changes. Never include credentials, local signing configuration, or raw diagnostics containing account identifiers or unrelated scheduled-event owners.

## Project structure

`App/`, `Helper/`, and `CLI/` are thin executable entry points. Shared code lives in `Package/Sources/`: Core owns schedule values and policy; System owns parsing and process execution; IPC owns requests and client authentication; Service owns privileged operations and grants; UI and CLI own their application logic. Tests live in `Package/Tests/` and tooling in `Tools/`.

Read the [architecture](docs/architecture/overview.md), [module boundaries](Package/ModuleRules.md), and [security model](docs/security.md) before changing cross-process behavior. Production code uses native frameworks; Point-Free SnapshotTesting is a test-only dependency. Explain the need for any proposed dependency in your PR.

The generated Xcode project and workspace are checked in. Run `make generate` when target layout changes; it uses Python's standard library. The original app icon is generated with `xcrun swift Tools/generate_icon.swift`.

Commit shared schemes, shared package configuration, app assets, reviewed snapshot references, and `Package/Package.resolved`. Keep build/test artifacts, Xcode user state, local signing configuration, and credentials out of Git. The [ignore policy](.gitignore) is adapted from GitHub's [Swift](https://github.com/github/gitignore/blob/main/Swift.gitignore), [Xcode](https://github.com/github/gitignore/blob/main/Global/Xcode.gitignore), and [macOS](https://github.com/github/gitignore/blob/main/Global/macOS.gitignore) templates.

Agent-specific instructions live in [AGENTS.md](AGENTS.md); no AI tools or personal skill installations are required to contribute.
