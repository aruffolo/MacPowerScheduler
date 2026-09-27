# Module Boundaries

Module boundaries for `MacPowerScheduler`. Canonical details: `Package/ModuleRules.md` and `docs/architecture/overview.md`.

## App (Xcode target)
- May import `PowerScheduleUI`.
- Must stay thin: wiring + window setup only.
- No schedule rules/state logic.

## Package
- `PowerScheduleCore`: values and pure scheduling policy; no SwiftUI, ServiceManagement, process, or XPC execution.
- `PowerScheduleSystem`: fixed-path process I/O and parsing; depends on Core.
- `PowerScheduleIPC`: typed requests and client authentication; depends on Core; no command execution.
- `PowerScheduleService`: privileged policy and storage; depends on Core, System, and IPC.
- `PowerScheduleUI` and `PowerScheduleCLI`: presentation/application logic with injected clients; depend on Core, System, and IPC; never execute privileged commands directly.
- Must not import from `App/`.
- Keep UI-agnostic logic separated from platform glue. No global service locator or third-party runtime dependencies. Approved Point-Free SnapshotTesting is linked only to the snapshot test target.

## Helper and CLI (Xcode targets)
- Thin composition roots; Helper imports `PowerScheduleService`, CLI imports `PowerScheduleCLI`. Their package layers own system and IPC wiring.
- Preserve the authenticated, account-authorized helper boundary for all privileged writes.
