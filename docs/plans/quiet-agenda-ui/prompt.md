# Quiet Agenda UI

## Problem and outcome

The maintainer dislikes the current interface and selected concept 06, Quiet Agenda, with the explicit instruction: “I want it 1:1.” The subsequent discussion settled where setup and permission controls belong.

- `OUT-1`: Deliver the selected agenda design as the working native Mac interface, retaining the existing scheduling and authorization behavior.
- `OUT-2`: Make required setup visible on the main screen and occasional permission/automation management accessible through the gear's Settings sheet.

## Requirements

- `REQ-1`: Match [concept 06](../../design/ui-concepts/06-quiet-agenda.png): warm light surface, title and subtitle, connected sun/moon agenda nodes, stacked time fields, right-aligned switches, saved-system section, blue bottom action bar (Deep Sapphire, DEC-3), and top-right gear. Do not substitute concept 01 or blend alternative layouts.
- `REQ-2`: Keep independent daily startup/shutdown controls, locale-aware native time input, disabled pickers for disabled events, and explicit Apply Schedule. Show actual saved state separately from draft edits.
- `REQ-3`: Show a compact setup banner below the introductory text only when attention is needed. Offer the action appropriate to the actual state, including enabling scheduling or opening System Settings for pending approval. Remove the setup banner when ready.
- `REQ-4`: The gear opens a native Settings sheet containing scheduling status/setup, Allow Automation or Revoke Automation, and a separate Remove Helper section. Keep macOS-managed authentication and existing confirmation explanations.
- `REQ-5`: Retain refresh, external-change/reload handling, unreadable-state errors, explicit replacement of unsupported schedules, truthful dirty/success/busy states, and shutdown/power/FileVault guidance. Closing Settings must preserve the draft.
- `REQ-6`: Support the existing macOS 14 deployment target, native keyboard and accessibility behavior, resizing/scrolling, and both light and dark appearance. The selected light image is the visual reference; dark mode retains its structure.

## Success criteria

- `SC-1`: A rendered production screen matches concept 06's composition, relative spacing, colors, typography hierarchy, symbols, controls, and footer at the calibrated reference size. Material visual discrepancies are resolved or explicitly approved, not renamed as interpretation.
- `SC-2`: All four schedule combinations work through the existing model; draft and saved values remain distinct, invalid/unavailable/conflicting states cannot apply, and success follows verified readback.
- `SC-3`: Setup states present truthful status and the correct next action; a configured app shows the unobstructed reference layout.
- `SC-4`: Settings exposes every existing permission action, preserves confirmations and grant/removal semantics, displays action failures accessibly, and opens/closes without losing edits.
- `SC-5`: Light/dark and failure-state snapshots, deterministic regressions, keyboard/VoiceOver and resize checks, and repository-required gates establish a reviewable UI change.
- `SC-6`: Documentation, reviewed evidence, hardening and the final receipt describe the actual result and any remaining production-validation limits.

## Constraints and non-goals

- `CON-1`: SwiftUI production views, Swift 6.2 strict concurrency, existing modules/tooling, no new dependencies. Follow the [central architecture](../../architecture/overview.md) and [module rules](../../../Package/ModuleRules.md).
- `CON-2`: Preserve system ownership of schedules, authenticated helper boundaries, explicit account automation consent, normal shutdown, one-time events, and draft/conflict protections. No security bypasses or privileged writes from views.
- `CON-3`: The maintainer's “Go” authorizes supervised implementation of this plan. The later “apply, update tests then commit” authorizes a local commit of the completed UI with Deep Sapphire. No push, publication, live helper registration/removal, account changes, or power operation is authorized. Preserve unrelated working-tree edits.
- `CON-4`: Use synthetic fixtures for automatic validation. Existing attended helper/hardware/release gates remain owned by the [initial-release plan](../initial-release/plan.md); this UI plan does not waive or satisfy them.
- `CON-5`: The image's desktop background, concept caption and artificial outer shadow are presentation framing, not application content. Actual state, native titlebar behavior, localization and accessibility must remain functional; record unavoidable renderer differences rather than claiming pixel identity.

No calendar/weekday editor, profiles, timeline/dial, menu-bar-only mode, forced shutdown, new backend/CLI behavior, or release work is requested. Deferred scope is owned by `plan.md`.

## Sources

- Maintainer selected concept 06 and accepted the Settings-sheet/setup-banner explanation in this task, 2026-09-28; see `DEC-1` and `DEC-2` in [documentation.md](documentation.md).
- [Selected image](../../design/ui-concepts/06-quiet-agenda.png), [concept research](../../design/ui-concepts/README.md), and [generation prompts](../../design/ui-concepts/prompts.md).
- [Initial product contract](../initial-release/prompt.md), [decisions](../initial-release/documentation.md), [testing procedures](../../testing/README.md), and [coverage scope](../../testing/unit-coverage.md).

Existing source and tests establish the behavior to preserve; they do not override the selected visual design.
