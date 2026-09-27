# project-structure.md

## Project Structure & Module Organization
- `MacPowerScheduler.xcworkspace`: main entrypoint (app + local Swift package).
- `MacPowerScheduler.xcodeproj`: app, helper, and CLI targets.
- `App/`: minimal SwiftUI app host and app icon.
- `Helper/` and `CLI/`: minimal daemon and CLI entry points.
- `Package/`: Swift Package containing schedule core, system adapters, IPC, service, UI, CLI, and tests.
- `Configurations/`: shared build/signing configuration; `Local.xcconfig` stays private and ignored.
- `Tools/`: repo tools (project generation, validation, release, lint, and pre-commit hook).
- Module boundaries: see `ai-rules/module-boundaries.md`.

## Tests
- Swift Package tests live in `Package/Tests/` (Swift Testing), including `PowerScheduleSnapshotTests` and its reviewed PNG references.

## Resources
- App assets live under `App/Assets.xcassets/`. Add package-owned resources to their owning target only when needed; do not duplicate resources across targets.
