# testing.md

## Testing Guidelines (Swift Testing and snapshots)
- Use Swift Testing (`import Testing`) for package tests and Point-Free SnapshotTesting for SwiftUI images. No app UI automation target.
- One behavior per test.
- Deterministic: no sleeps for “waiting”; control time/randomness via injected dependencies.
- Any change to core schedule rules/state should include a unit test.
- Default tests must never change the real power schedule, register a helper, or power-cycle the host. Live checks require an explicitly approved setup; see `docs/testing/README.md` and `docs/testing/power-cycle.md`.

## Running tests
- Required: `make check` and `make test-strict`; never mask failures with a fallback.
- Package-only focused checks: `make test-unit` or `swift test --package-path Package --filter <suite>`.
- `make test-coverage`: fresh unit-only run; require >=95% executable lines in `Tools/unit-coverage-scope.json`. Classify every package production file; keep exclusions justified and whole-package coverage visible. See `docs/testing/unit-coverage.md`.
- `make test-adapters`: safe process/filesystem integration tests; required separately from unit coverage.
- `make test-snapshots`: fixed-fixture SwiftUI images; required in both full gates. Missing/mismatched references fail. Explicit `make record-snapshots` updates references for visual review.
- `make coverage-report`: re-render LLVM reports without tests; source/artifact hashes must match the retained measurement. Report reuse explicitly, never as a fresh validation pass.
