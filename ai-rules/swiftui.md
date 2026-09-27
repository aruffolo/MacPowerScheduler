# swiftui.md

## SwiftUI instructions (macOS)
- Prefer `Button` over `onTapGesture()` for clickable UI.
- Prefer `foregroundStyle()` over `foregroundColor()` where available.
- Prefer `clipShape(.rect(cornerRadius:))` over `cornerRadius()` (when available).
- Split large `body` implementations into smaller sections.
  - OK: small computed view sections (e.g. `private var header: some View`).
  - Extract into dedicated `View` types when stateful, heavily-branching, or reused.
- Avoid `AnyView` unless absolutely required.
- ViewModels: `@Observable` + `@MainActor` (macOS 14); owning views use `@State`.
- Keep SwiftUI view bodies simple; delegate to view models/state objects.

## View file ordering (top → bottom)
- Environment
- `private` / `public` `let`
- `@State` / other stored properties
- computed `var` (non-view)
- `init`
- `body`
- computed view sections / view helpers
- helper functions
