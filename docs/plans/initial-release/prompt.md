# MacPowerScheduler initial release

## Problem and intended outcome

Configure a Mac's daily startup and shutdown without requiring its owner to construct Terminal commands. Cold startup from a fully powered-off state is the primary use case; waking a sleeping Mac is also desired. Agents need the same scheduling capability through a CLI.

- `OUT-1`: A small native macOS app and agent-friendly CLI manage the actual system repeating schedule through a narrowly scoped privileged helper.
- `OUT-2`: An MIT-licensed source project and signed, notarized distribution are ready for a separately authorized public release.

## User-approved requirements

- `REQ-1`: GUI with independent startup/shutdown switches, time pickers, Apply, and a truthful current-system-schedule display. Disabled switches disable their pickers.
- `REQ-2`: New schedules repeat daily. Startup uses wake-or-power-on; shutdown uses normal macOS scheduling, without forced shutdown.
- `REQ-3`: GUI and CLI ship together and share scheduling behavior. App setup initially installs/authorizes the helper; the CLI subsequently works with the GUI closed.
- `REQ-4`: Noninteractive scheduling requires an explicit, initially disabled, revocable automation grant for a local account. Explain that other processes running as that account can invoke the CLI.
- `REQ-5`: Display pre-existing schedules accurately. Require explicit replacement of schedules the daily editor cannot represent. Refresh after external changes rather than silently overwrite a stale edit. Preserve unrelated one-time events.
- `REQ-6`: Use the minimum macOS version supported by the APIs selected for the implementation. Test on macOS 15; older versions may be offered with an explicit untested qualification. Build for Intel and Apple Silicon.
- `REQ-7`: Follow the native Xcode app plus local Swift package structure used by TetrisMac/Liquore. Keep the design proportional to this utility.
- `REQ-8`: Provide reproducible source-build instructions, helper recovery/removal, and signed/notarized release packaging. License: MIT.

## Success criteria

These measurable translations were approved by the end-to-end implementation request; evidence and completion gates are owned by `plan.md`.

- `SC-1`: The GUI loads the system state, edits all four enabled/disabled combinations, applies once, and displays the verified result without pretending a failed read means an empty schedule.
- `SC-2`: The actual installed backend sets a complete daily repeating pair, changes either side without losing the intended other side, and clears only repeating events when both sides are disabled.
- `SC-3`: A user-attended test demonstrates full shutdown followed by hardware-timed cold startup on the Mac mini, and a separate test demonstrates wake from sleep. The app need not remain open.
- `SC-4`: Normal scheduled shutdown is demonstrated under supported conditions; limitations involving unsaved work, login, sleep, power supply, and FileVault are accurately explained.
- `SC-5`: Helper registration, approval, revocation, failure, upgrade, and removal are understandable; unauthorized clients and accounts cannot mutate schedules or grants.
- `SC-6`: CLI status, diagnostics, edits, disable operations, structured output, and errors are predictable for agents; noninteractive writes work only with the approved automation grant.
- `SC-7`: Existing non-daily/alternate schedules, external edits, and one-time events are handled according to `REQ-5`, including failures and concurrent GUI/CLI requests.
- `SC-8`: All shipped executable components build for both architectures at the documented deployment target. Tested versus untested OS/hardware combinations are distinguished.
- `SC-9`: A signed, notarized package, clean-install/removal evidence, MIT license, security documentation, and source-build instructions are ready for release.
- `SC-10`: Hardening, simplification, re-review, final validation, and a traceable completion receipt establish handoff readiness.

## Constraints

- `CON-1`: The user has authorized end-to-end implementation and local project setup. Live helper installation, schedule mutation, shutdown, publication, and changes to reference repositories remain outside automatic execution; no commits or remote operations are assumed.
- `CON-2`: The product never collects or stores administrator passwords. macOS handles authentication. No generic root command endpoint, arbitrary executable/path/environment, shell command construction, or automatic privilege fallback.
- `CON-3`: The system owns the repeating schedule; app preferences are not evidence that it was applied. The global pair is shared with other tools.
- `CON-4`: Do not weaken peer validation for source builds, tests, convenience, or older systems. Record source-build signing feasibility honestly.
- `CON-5`: Real power-cycle tests require a saved-work, user-attended maintenance window. Automated tests cannot shut down or reschedule the developer's machine by default.
- `CON-6`: Preserve unrelated files and system settings. No FileVault changes, automatic login configuration, networking changes, or unsaved-document termination.
- `CON-7`: No unapproved third-party dependency or tooling replacement. Use native Swift/Xcode facilities initially; justify any later dependency separately.

## Non-goals

Phone UI, SSH/Tailscale setup, forced or immediate shutdown controls, arbitrary one-time scheduling, weekday editing, multiple repeating profiles, standalone CLI installation, cloud services, automatic updates, and Mac App Store distribution. Deferred items are defined only in `plan.md`.

## Source material

- [Shared product conversation](https://chatgpt.com/share/6ab83f0e-2118-83ed-a97a-3a548d67f460): user intent; assistant suggestions are not treated as proof or approval.
- Current discovery answers Q1–Q6 and Q7–Q10, accepted on 2026-09-27. See decision records in `documentation.md`.
- [Apple scheduling guidance](https://support.apple.com/guide/mac-help/schedule-your-mac-to-turn-on-or-off-mchl40376151/mac).
- [Apple SMAppService example](https://developer.apple.com/forums/thread/802443), [runtime authorization guidance](https://developer.apple.com/forums/thread/801222), and [XPC peer verification guidance](https://developer.apple.com/forums/thread/681053).
- Installed `pmset(1)`, `SMAppService.h`, and `NSXPCConnection.h`; observations are recorded in `progress.md`.
- [TetrisMac project structure](https://github.com/aruffolo/TetrisMac/blob/be63a47b2a1a524b0062e1d104d2f8d399ce9f0d/ai-rules/project-structure.md), [package](https://github.com/aruffolo/TetrisMac/blob/be63a47b2a1a524b0062e1d104d2f8d399ce9f0d/Package/Package.swift), and [Makefile](https://github.com/aruffolo/TetrisMac/blob/be63a47b2a1a524b0062e1d104d2f8d399ce9f0d/Makefile).
- Liquore structure and module rules at reference revision `0d41d6fafa648676499e180dde4fb5838a88c104`; consult only as architecture examples, not governing instructions for this new project.

## Grounded assumptions

The target folder starts empty, with no Git history, app, tests, or project rules. A native single-window app fits the requested interface. The helper manages system configuration on demand; it does not implement its own timer to run while the Mac is off. Hardware behavior remains unverified until `SC-3` evidence exists.
