# CLI contract (schema 1)

Invoke the bundled `MacPowerScheduler.app/Contents/MacOS/powerschedulectl`. App setup is required for writes; `status` works without a helper. The CLI never asks for a password or grants itself automation permission.

```
powerschedulectl status [--json]
powerschedulectl doctor [--json]
powerschedulectl set --startup 07:30 --shutdown 23:00 [--json]
powerschedulectl set --no-startup [--json]
powerschedulectl set --startup 07:30 --no-shutdown --replace-existing [--json]
powerschedulectl disable startup|shutdown|all [--json]
```

Set preserves omitted sides. An unrepresentable system schedule requires a complete `set` with both sides specified and `--replace-existing`. Times are strictly HH:mm, daily in the Mac's local timezone; identical enabled times are rejected, overnight pairs allowed. Mutations also accept `--if-current REVISION` using a revision from status; a mismatch fails without writing. Otherwise the CLI reads the system state immediately before calling the helper. External tools can still race pmset; readback verification detects resulting mismatches.

`--json` emits exactly one JSON object on stdout, including on errors. Fields: `schemaVersion: 1`, optional `schedule` (`startup`/`shutdown` event objects with `kind`, `days`, `time` components), optional `revision`, optional `automationEnabled`, optional `error` (`code`, `message`). Missing event keys mean disabled; an absent schedule on error is not an empty schedule. Human output goes to stdout on success, stderr on failure. Help is text (or a JSON `help` string with `--json`). Diagnostics omit serial numbers, account identifiers, and unrelated one-time event owners.

Exit codes: 0 success; 2 invalid input; 3 authorization required; 4 helper unavailable/signing required; 5 conflict/replacement required; 6 unreadable schedule/system failure; 7 uncertain result. Doctor requires the helper to answer and returns its error when unavailable. Status is read-only and does not require helper approval.

After a code 7 result, read status before deciding whether to retry. Do not blindly retry schedule writes. A granted account permits any process under that account to invoke this CLI; revoke the grant in the app to stop future noninteractive writes.
