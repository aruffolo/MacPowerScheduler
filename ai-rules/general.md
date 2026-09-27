# general.md

Core repo-wide engineering principles.

## Core Instructions
- Target macOS 14: avoid macOS 15+ APIs unless guarded with availability checks.
- Prefer small, testable units: pure logic in `Package/`, UI glue in `App/`.
- No business logic in SwiftUI views: keep it in model/state objects and call them from views.
- Fix root cause, not band-aids.
