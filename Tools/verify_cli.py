#!/usr/bin/env python3
"""Read-only subprocess contract check. Never invokes a valid mutation."""
import json
import subprocess
import sys

cli = sys.argv[1]


def run(args, expected):
    result = subprocess.run([cli, *args], capture_output=True, text=True, timeout=25)
    if not (result.returncode == expected):
        raise SystemExit((args, result.returncode, result.stderr))
    if not (result.stderr == ''):
        raise SystemExit((args, result.stderr))
    return json.loads(result.stdout)


status = run(["status", "--json"], 0)
if not (status['schemaVersion'] == 1 and 'schedule' in status and (len(status['revision']) == 64)):
    raise SystemExit("Verification failed: status['schemaVersion'] == 1 and 'schedule' in status and (len(status['revision']) == 64)")
invalid = run(["set", "--startup", "99:00", "--json"], 2)
if not (invalid['error']['code'] == 'invalidInput'):
    raise SystemExit("Verification failed: invalid['error']['code'] == 'invalidInput'")
invalid = run(["disable", "unknown", "--json"], 2)
if not (invalid['error']['code'] == 'invalidInput'):
    raise SystemExit("Verification failed: invalid['error']['code'] == 'invalidInput'")
help_result = run(["--help", "--json"], 0)
if not ('powerschedulectl' in help_result['help']):
    raise SystemExit("Verification failed: 'powerschedulectl' in help_result['help']")
print("PASS: actual CLI read-only status, JSON errors/exit codes, and help; no mutations attempted.")
