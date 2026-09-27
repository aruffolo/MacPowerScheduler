# MacPowerScheduler

A small native macOS app and CLI for a daily startup and shutdown routine. Set startup, shutdown, or both, and see the schedule actually configured in macOS. Startup wakes a sleeping Mac or powers on a shut-down Mac where the hardware supports it.

The application is under development. See [current evidence and remaining release gates](docs/plans/initial-release/progress.md). A successful build is not proof of cold startup or signed-helper operation.

## Requirements

- macOS 14 or later; the UI uses Observation. Intel and Apple Silicon build targets.
- Xcode 26.3 / Swift 6.2.4 for the documented source workflow.
- SwiftLint and SwiftFormat for development (`brew install swiftlint swiftformat`).
- Source builds need an Apple-issued signing identity for privileged operation. End users of a future notarized release use the maintainer’s signature and do not need a developer account.

The observed development/test host is an Intel Mac mini on macOS 15.7.4. Other OS/hardware runtime combinations require their own evidence; universal compilation alone does not establish that.

## Build and test

```sh
make install-hooks
make build
make run
make check
make test-strict
make build-universal
```

Open `MacPowerScheduler.xcworkspace` in Xcode. The app is built at `.build/DerivedData/Build/Products/Debug/MacPowerScheduler.app`. The generated Xcode project is checked in; `make generate` regenerates it with Python's standard library when target layout changes. The application has no third-party runtime dependencies; developer linting and formatting use SwiftLint and SwiftFormat. The app icon is original code-drawn artwork; regenerate it with `xcrun swift Tools/generate_icon.swift`.

The [`.gitignore`](.gitignore) adapts GitHub's [Swift](https://github.com/github/gitignore/blob/main/Swift.gitignore), [Xcode](https://github.com/github/gitignore/blob/main/Global/Xcode.gitignore) and [macOS](https://github.com/github/gitignore/blob/main/Global/macOS.gitignore) templates to this SwiftPM project. Commit the generated project/workspace, shared schemes, shared package configuration, app assets and reviewed snapshot references. Keep `Package.resolved` for reproducible dependency versions, as [Apple recommends for app builds](https://developer.apple.com/documentation/xcode/building-swift-packages-or-apps-that-use-them-in-continuous-integration-workflows). Build/test artifacts, user settings, local signing configuration and signing credentials stay out of Git. CocoaPods, Carthage and fastlane rules are omitted because this project does not use them.

`make lint` and Xcode builds run SwiftLint with the app/package rules copied from TetrisMac. `make format` uses its SwiftFormat style, adapted to Swift 6.2. `make install-hooks` enables the repository-local pre-commit hook: it formats and re-stages staged Swift files, and stops on partially staged files so unstaged work cannot enter a commit accidentally. Each clone needs this one-time hook setup. Tetris's SwiftGen step is omitted because this app has no SwiftGen inputs. Tool versions used for verification: SwiftLint 0.65.1 and SwiftFormat 0.63.0.

By default the app is ad-hoc signed and offers read-only schedule inspection. It deliberately does not install a permissive development helper. Package tests use isolated fixtures; default commands never change the real power schedule, register the helper, or shut down the machine. SwiftUI snapshot tests render fixed synthetic states without launching the app or contacting its helper.

`make check` enforces at least 95% executable-line coverage of [the declared unit-testable logic](docs/testing/unit-coverage.md). `make test-unit` runs deterministic tests, `make test-adapters` exercises safe process/filesystem boundaries, and `make test-coverage` produces fresh LLVM HTML/text/JSON reports under `.build/Coverage/`. `make coverage-report` regenerates reports from unchanged saved inputs without rerunning tests. Signed-helper, UI and physical power validation remain separate requirements.

`make test-snapshots` compares twenty SwiftUI reference images using the approved test-only Point-Free SnapshotTesting dependency. Both full test gates require snapshots. Use `make record-snapshots` only for intentional, visually reviewed reference changes. See [snapshot workflow and baseline environment](docs/testing/README.md#swiftui-snapshots); no UI automation runner provisioning is required. Packaged-app launch and interactions remain manual release checks.

For privileged source builds, create the ignored `Configurations/Local.xcconfig` with your `DEVELOPMENT_TEAM` and `CODE_SIGN_IDENTITY`. Sign all three executables with the same Apple Development or Developer ID team. Do not commit this file. Contributor helper installation still requires macOS approval and must be validated with your signing configuration; ad-hoc and unsigned executables remain read-only. Release builds additionally require Developer ID/notarization; see [release procedure](docs/release/README.md).

## Using the app

Move a properly signed distribution to `/Applications` before enabling its helper. Open the app, select **Enable Power Scheduling**, and approve the system-managed request in System Settings if needed. The app never receives your administrator password.

Enable startup and/or shutdown, choose times, and apply. Both disabled clears the repeating schedule only. Existing weekday or alternate-event schedules are displayed accurately and require explicit replacement before conversion to daily. External changes invalidate stale edits. Times follow the Mac's local clock; macOS owns DST execution behavior.

Unsaved editor changes survive temporary schedule-read failures. Apply stays disabled until a successful refresh; if the system schedule changed meanwhile, use **Reload Editor** to explicitly discard the draft and review the current settings.

The helper changes system configuration on demand. Neither the GUI nor CLI needs to remain open for the configured schedule to persist. There is only one system-wide repeating pair; other tools can change the same pair.

## CLI and automation

```sh
/Applications/MacPowerScheduler.app/Contents/MacOS/powerschedulectl status --json
/Applications/MacPowerScheduler.app/Contents/MacOS/powerschedulectl set --startup 07:30 --shutdown 23:00
```

Writes require the app's explicit **Allow Automation** grant for the calling account. This allows other processes under that account to invoke the CLI; revoke it in the app when no longer needed. The CLI never prompts interactively or enables its own grant. See the [CLI schema, commands, errors, and conflict behavior](docs/cli.md).

## Limitations and removal

Normal scheduled shutdown can be blocked by sleep, no logged-in user, or unsaved documents. There is no force-shutdown fallback. Power-on needs connected power and compatible hardware; FileVault may require a person to unlock the Mac before services become reachable. The app does not alter FileVault, automatic login, or networking. See [Apple's scheduling guidance](https://support.apple.com/guide/mac-help/schedule-your-mac-to-turn-on-or-off-mchl40376151/mac).

**Remove Helper** revokes automation grants for all accounts and unregisters the helper. System schedules remain active: if you want to clear the repeating schedule, disable both times and Apply before removing the helper. One-time events are never cleared. Deleting the app manually does not perform this cleanup; reinstall a matching signed app to use the removal flow. Disabling the helper in System Settings prevents it from running but does not itself erase stored automation grants.

## Project and license

Structure follows the Xcode app/local-package pattern used by TetrisMac and Liquore. See [architecture](docs/architecture/overview.md), [module rules](Package/ModuleRules.md), [security](docs/security.md), [testing](docs/testing/README.md), and the [phased plan](docs/plans/initial-release/plan.md).

Agent guidance follows TetrisMac's [AGENTS.md](AGENTS.md), [task-based rule loading](ai-rules/rule-loading.md), and `ai-docs/` reference layout, adapted to this project's deployment target, modules, tooling, and safety rules. The rule router points to the installed Swift and native-app skills; no duplicate skill installation is required.

MIT; see [LICENSE](LICENSE).
