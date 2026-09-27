# swift.md

## Swift instructions (macOS 14)
- Use Swift 6.2 strict concurrency. Avoid new APIs unless availability-guarded (deployment target: macOS 14).
- Prefer structured concurrency (`async/await`) over GCD. If you must hop to main, prefer `@MainActor`.
- Avoid force unwraps / force `try` unless unrecoverable.
- Prefer value types + pure functions for schedule values, validation, and edit policy.
- Prefer intention-revealing names; helpers <~25 LOC unless glue.

## Foundation compatibility
- `URL.documentsDirectory` / `appending(path:)` (macOS 13+) are available at the deployment target. Keep system executable and privileged storage paths fixed as defined in `docs/security.md`.

## ARC & Ownership
- Model ownership explicitly before choosing `strong`, `weak`, or `unowned`.
- Delegates, data sources, host-owned providers, child-to-parent links, listener callbacks, and bridge/provider back-references are `weak` by default when class-bound.
- Use `unowned` only when the referenced object is guaranteed to outlive the holder; avoid it for async callbacks, tasks, timers, notifications, external SDK callbacks, and host-provided dependencies.
- Stored closures, long-lived `Task`s, async streams, timers, observers, and subscriptions must be reviewed for retain cycles and explicit cancellation/cleanup.
- When changing ownership semantics, add a focused deallocation/lifetime test where practical.
