#!/usr/bin/env python3
"""Fail closed on ad-hoc, development-only, mismatched, or debugging signatures."""
import plistlib
import re
import subprocess
import sys
from pathlib import Path

app = Path(sys.argv[1])
items = [(app, "com.antonioruffolo.MacPowerScheduler"),
         (app / "Contents/MacOS/MacPowerSchedulerHelper", "com.antonioruffolo.MacPowerScheduler.helper"),
         (app / "Contents/MacOS/powerschedulectl", "com.antonioruffolo.MacPowerScheduler.cli")]
teams = set()
for path, identifier in items:
    subprocess.run(["codesign", "--verify", "--strict", str(path)], check=True, capture_output=True)
    result = subprocess.run(["codesign", "-d", "--verbose=4", str(path)], capture_output=True, text=True, check=True)
    details = result.stderr
    if not ('Authority=Developer ID Application:' in details):
        raise SystemExit('Developer ID Application signing is required')
    if not (f'Identifier={identifier}\n' in details):
        raise SystemExit('Unexpected code identifier')
    match = re.search(r"^TeamIdentifier=([A-Z0-9]{10})$", details, re.M)
    if not (match):
        raise SystemExit('Missing signing team')
    teams.add(match.group(1))
    flags = re.search(r"^CodeDirectory .*?flags=(0x[0-9a-fA-F]+)", details, re.M)
    if not flags or not (int(flags.group(1), 16) & 0x10000):
        raise SystemExit('Hardened runtime required')
    entitlements = subprocess.run(["codesign", "-d", "--entitlements", ":-", str(path)], capture_output=True, check=True).stdout
    if entitlements.strip():
        values = plistlib.loads(entitlements)
        for unsafe in ["com.apple.security.get-task-allow", "com.apple.security.cs.disable-library-validation", "com.apple.security.cs.allow-dyld-environment-variables"]:
            if not (not values.get(unsafe)):
                raise SystemExit(f'Unsafe release entitlement: {unsafe}')
if not (len(teams) == 1):
    raise SystemExit('App, CLI, and helper must have matching signing teams')
print("PASS: Developer ID, identifiers, matching team, hardened runtime, and restricted entitlements.")
