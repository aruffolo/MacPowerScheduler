# logging.md

## Logging
- Prefer `Logger` (os) over `print`.
- No noisy logs in refresh, process-output, or IPC loops. Keep credentials and raw user diagnostics out of logs.
- Gate debug-only logs behind a flag or `#if DEBUG`.
- CLI result output follows `docs/cli.md`; stdout/JSON is a public command contract, not diagnostic logging.
