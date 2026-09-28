# Rule Loading Guide

Load rules from `ai-rules/` based on what you are doing. Always start here.

## Always load
Route: baseline

Required:
- @ai-rules/general.md
- @ai-rules/swift.md (unless the task is purely docs/meta with no code)

Optional:
- None

## Load by task / context

### SwiftUI / UI work
Route: swiftui-ui-work

Load when:
- Editing SwiftUI views, view modifiers, design system, layout, animations
- Touching `App/` or any `*View.swift`

Required:
- @docs/plans/initial-release/prompt.md
- @docs/plans/initial-release/documentation.md
- @docs/plans/quiet-agenda-ui/prompt.md
- @docs/plans/quiet-agenda-ui/documentation.md
- @ai-rules/swiftui.md
- @ai-rules/ui-styling.md

Optional:
- @ai-rules/project-structure.md only if moving files across module/target boundaries

Use `swiftui-pro` for UI review, `swiftui-ui-patterns` for component/state patterns, and `swiftui-view-refactor` for focused view refactors. The project's macOS 14 target and existing architecture override iOS-oriented skill defaults. Use `swiftui-liquid-glass` only for explicitly requested glass work after checking macOS API availability.

### Visual design / visual assets
Route: visual-design-assets

Load when:
- Creating or reviewing screen concepts, design tokens, visual components, raster assets, or visual QA evidence
- Changing palette, typography, spacing, shapes, image treatment, or interaction-state styling

Required:
- @docs/plans/initial-release/prompt.md
- @docs/plans/initial-release/documentation.md
- @docs/plans/quiet-agenda-ui/prompt.md
- @docs/plans/quiet-agenda-ui/documentation.md
- @ai-rules/ui-styling.md

Optional:
- @ai-rules/tooling.md when screenshots, UI inspection, accessibility inspection, or GUI automation are needed
- @ai-rules/configuration-assets.md when release resources or generated assets change

### Architecture / data flow
Route: architecture-data-flow

Load when:
- Editing state models, helper/IPC wiring, app composition
- Introducing new modules or cross-layer dependencies

Required:
- @ai-rules/architecture.md
- @ai-rules/module-boundaries.md

Optional:
- @ai-rules/dependencies-testing.md only if tests/mocks or dependency overrides are involved

Use `swift-concurrency-pro` for dedicated concurrency review or compiler-error remediation.

### Concurrency / async work
Route: concurrency-async-work

Load when:
- Touching `async/await`, `Task`, `TaskGroup`, actors, `@MainActor`
- Dealing with cancellation, thread-safety, data races, or performance issues
- Debugging deadlocks or blocking behavior in async code

Required:
- @ai-rules/swift.md

Optional:
- @ai-rules/architecture.md only if state, helper/IPC wiring, or app composition is involved
- @ai-rules/testing.md only when adding or changing async tests

Use `swift-concurrency-pro` for dedicated concurrency review or compiler-error remediation.

For observed performance problems, use `swiftui-performance-audit` for view updates/layout and `native-app-performance` for native Time Profiler evidence. Profiling does not authorize helper registration or power-schedule changes.

### Project structure & modules
Route: project-structure-modules

Load when:
- Creating/moving files across module or target boundaries
- Adding modules/targets, changing package manifests, or changing dependency/import boundaries
- Touching `Package/` manifests or explicit module-boundary rules

Required:
- @ai-rules/project-structure.md
- @ai-rules/module-boundaries.md

Optional:
- @ai-rules/architecture.md only when module changes affect helper/IPC wiring, storage, or app composition

### Build / test / release / ZIP
Route: build-test-release-zip

Load when:
- Running or fixing builds/tests, CI failures, packaging, or ZIP release work

Required:
- @ai-rules/build-and-dev.md

Optional:
- @ai-rules/testing.md only if tests are touched or test failures are being debugged
- @ai-rules/configuration-assets.md only if Info.plist, assets, signing, packaging, or ZIP config are touched
- @ai-rules/project-structure.md only if build/test failures involve targets, packages, or module imports
- @ai-docs/macos-signing-tcc.md when signing, provisioning, permissions, or release validation are involved
- @docs/testing/README.md when running or debugging tests
- @docs/release/README.md when packaging or verifying release artifacts

### Writing or modifying tests
Route: test-writing

Load when:
- Adding unit tests, fixtures, fakes, or test-only helpers

Required:
- @ai-rules/testing.md
- @ai-rules/dependencies-testing.md

Optional:
- @ai-rules/project-structure.md only if adding/moving test targets or crossing module boundaries

Use `swift-testing-expert` for package tests, including Point-Free SwiftUI snapshots. App UI automation was replaced by snapshots at the user's request. Live helper/power checks follow `docs/testing/README.md` and `docs/testing/power-cycle.md` and require the approved setup.

### Logging
Route: logging

Load when:
- Adding/changing logs or debug output

Required:
- @ai-rules/logging.md

Optional:
- None

### Localization
Route: localization

Load when:
- Introducing or changing user-facing text, localized resources, or locale-sensitive formatting

Required:
- @ai-rules/localization.md

Optional:
- @ai-rules/configuration-assets.md only when changing generated resources or asset/config wiring

### Commits / PR hygiene
Route: commits-pr-hygiene

Load when:
- About to commit, writing commit messages, or preparing PR text

Required:
- @ai-rules/commits.md

Optional:
- None

### Configuration & assets
Route: configuration-assets

Load when:
- Editing config files, assets catalogs, resources, build settings, Info.plist, signing, or ZIP release scripts

Required:
- @ai-rules/configuration-assets.md

Optional:
- @ai-rules/localization.md only when changing localized resources or formatters
- @ai-rules/build-and-dev.md only when config changes require build verification

### Tooling / UI inspection / accessibility
Route: tooling-ui-accessibility

Load when:
- You need screenshots, UI inspection, accessibility audits, or GUI automation

Required:
- @ai-rules/tooling.md

Optional:
- @ai-rules/swiftui.md only when tooling findings lead to SwiftUI implementation changes
- @ai-rules/ui-styling.md only when tooling findings lead to visual styling changes

Use `peekaboo` for native macOS inspection when the primary tool cannot handle it; preserve project test-safety boundaries.

### Privileged helper / system schedule
Route: helper-system-schedule

Load when:
- Changing helper lifecycle, XPC identity, authorization/grants, process execution, or system schedule reads/writes

Required:
- @docs/security.md
- @docs/architecture/overview.md
- @Package/ModuleRules.md
- @docs/testing/README.md

Optional:
- @docs/testing/power-cycle.md only for explicitly approved physical power checks
- @ai-docs/macos-signing-tcc.md when signing or system approval is involved
