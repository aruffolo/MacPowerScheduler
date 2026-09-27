# Attended physical power tests

These are manual tests on a specifically approved machine and maintenance window. They are not performed by `make test`, nor authorized merely by building the application.

1. Save all work. Confirm continuous power and local access. Record OS, model, time zone, expected times, and current repeating pair. Keep one-time event comparisons local and minimize retained data.
2. Cold startup: with a properly signed app/helper, set a daily wake-or-power-on sufficiently in the future to allow shutdown (for example, ten minutes). Disable the test shutdown side unless separately agreed. Verify the current system schedule via the app and CLI, then close the app. The user performs normal full Shut Down. Observe a cold boot at the event without touching the power button; record the actual time and whether login/unlock is required.
3. Wake: in a separate run, program a near-future startup, close the app, and let the user put the Mac to sleep. Observe wake at the configured time. This is separate evidence, not a substitute for cold startup.
4. Normal scheduled shutdown: in another run with saved documents, awake and logged in, configure a near-future shutdown and observe it. Do not force termination, alter FileVault/automatic login, or deliberately risk unsaved documents to test a limitation.
5. Re-read the current schedule on return. Restore the original repeating pair only if no outside edit occurred. If the original pair was not representable by the daily editor, prepare the exact restoration with the user before testing; never flatten it to daily. Compare unrelated events and explain external changes.
6. Record success/failure for each observation, source/build identity, expected/actual timing, environment and baseline restoration. Failure requires investigation. A recorded event, successful command, restart, or wake alone does not prove cold startup.

FileVault can stop boot at an unlock screen; this app does not promise unattended login or remote network reachability. macOS owns timezone/DST event execution. Repeat relevant physical evidence when backend/packaging behavior changes before release.
