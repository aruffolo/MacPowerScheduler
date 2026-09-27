# architecture.md

## App Architecture Roles
- `App/`: composition + SwiftUI shell only.
- `Helper/` and `CLI/`: thin executable entry points.
- `Package/`: schedule values/policy, system adapters, typed IPC, helper service, UI, CLI, and tests. See `docs/architecture/overview.md` and `Package/ModuleRules.md`.

## Data flow
- Keep schedule validation and edit policy deterministic; isolate IO (system processes, IPC, authorization, storage) behind protocols.
- Prefer init-injection for dependencies (protocols/closures), not singletons.
- Avoid passing process, XPC, or authorization implementation details through UI layers; expose a small schedule model API instead.

## Decomposition Principles
- A type should have one reason to change; gather together things that change for the same reasons and separate things that change for different reasons.
- Keep schedule values and edit policy in `PowerScheduleCore`; keep process I/O in `PowerScheduleSystem` and privileged orchestration in `PowerScheduleService`.
- Do not let SwiftUI views or executable entry points absorb schedule rules that can be tested as pure package behavior.
- Smells: tests need unrelated UI setup, a UI refactor changes domain rules, IO leaks into pure policy, or one type owns UI, privileged execution, and persistence.
