# build-and-dev.md

## Build, Test, and Development Commands
- `open "MacPowerScheduler.xcworkspace"` – open workspace in Xcode.
- `make build` – build debug app (`.build/DerivedData`).
- `make run` – build then run the app (`open` on built `.app`).
- `make check` – lint, 95% scoped unit-coverage gate, adapter/tooling/snapshot tests, Debug build, and static analysis.
- `make test-unit` / `make test-adapters` / `make test-coverage` – deterministic logic, safe OS adapters, and fresh measured unit coverage; see `docs/testing/unit-coverage.md`.
- `make coverage-report` – native LLVM HTML/text/JSON from unchanged saved binary/profile; no tests. Optional `COVERAGE_RUN=<retained-run>`.
- `make test-strict` – unit/adapter/tooling/snapshot tests and read-only CLI checks; no fallback.
- `make test-snapshots` / `make record-snapshots` – verify reviewed SwiftUI images / explicitly update references for review.
- `make build-universal` – build and verify Release for Intel and Apple Silicon.
- `make archive` / `make verify-release` – archive and verify the signed candidate; see `docs/release/README.md` for notarization and ZIP packaging.

## Notes
- Prefer `make ...` over raw `xcodebuild`; it standardizes DerivedData + cache paths.
- Snapshots need no UI automation runner provisioning; default tests never install the helper or change power schedules. See `docs/testing/README.md` for baseline environment requirements.
