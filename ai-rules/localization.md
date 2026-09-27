# localization.md

## Localization (native frameworks)

This project uses native SwiftUI/Foundation text and formatting. No SwiftGen inputs or generation step exist.

### Add / edit strings
- Update user-facing strings in their owning UI or CLI layer; preserve the stable CLI schema and error categories in `docs/cli.md`.
- Use locale-appropriate GUI formatting; CLI times remain `HH:mm` as defined by its contract.

### Generate
- No localization generation command is required. Do not add SwiftGen or another dependency without approval.

### Use in code
- Use native localization APIs when adding localized resources.
- Keep localisation usage in UI/CLI and adapters (not `PowerScheduleCore`).
