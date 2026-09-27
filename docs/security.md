# Privilege and trust model

The daemon accepts a small typed, versioned request: status, schedule apply, automation enrollment/revocation, or grant cleanup before removal. There is no generic root command API. Only `/usr/bin/pmset` with internally constructed `repeat` arguments can change schedules; the app and CLI never launch sudo or accept passwords.

The listener requires an Apple-anchored signature, its own signing team, and the precise app or CLI identifier. The client also requires the precise helper identity from the same team. Ad-hoc/unsigned builds cannot derive an eligible team and fail closed. No private audit-token API or PID-based signature lookup is used. Runtime signed-peer rejection tests remain required before release; the presence of this code is not evidence that those tests ran.

The helper derives the caller UID from NSXPCConnection. OpenDirectory resolves the account's stable GeneratedUID, so recycling a numeric UID does not inherit another account's automation grant. A valid binary signature does not by itself authorize a schedule mutation. Without an automation grant, the helper requires a valid short-lived Authorization Services `system.privilege.admin` right. Only the GUI requests interactive authorization. Enrollment/revocation always requires authorization, even for an already-granted account.

Grants are stored in a root-owned, mode-0700 app directory under `/Library/Application Support/MacPowerScheduler`, with a mode-0600 JSON file. Reads reject symlinks, unsafe ownership/permissions, oversized/corrupt data. Writes use an exclusive temporary file and rename within the protected directory. Grants are account-specific, initially absent, survive normal restarts/updates, and are checked for each mutation. Built-in helper removal first clears all grants. Manual app deletion or disabling the background item alone does not clear the persisted grants.

The service serializes read/compare/validate/write/readback and grant changes on one queue. A stale revision is rejected. External tools are outside that queue: pmset has no compare-and-swap, so a concurrent external write remains a race. A failed/mismatched/timeout response requires fresh status inspection, never blind retry or automatic stale rollback.

The process adapter supplies a fixed minimal environment, no shell, no stdin, bounded output storage and a termination deadline. User-visible errors avoid raw one-time event owners. Authorization references live only for the operation and are never saved. Release verification requires matching Developer ID identities, hardened runtime, no debugging/library-validation exemptions, and notarization.

The app is not sandboxed because its narrowly scoped daemon changes system settings. Root compromise and malicious software already able to execute as an automation-enabled user are outside the protection supplied by this tool. Granting automation explicitly accepts the latter account-level scheduling capability.
