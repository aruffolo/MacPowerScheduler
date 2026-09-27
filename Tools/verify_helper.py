#!/usr/bin/env python3
"""Explicit installed-helper security probes; never submits a valid schedule write.

Requires a signed, approved test installation and approved use of a signing identity.
This does not replace attended mutation/account/lifecycle or physical tests.
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--app", required=True, type=Path)
parser.add_argument("--allow-installed-helper-probes", action="store_true")
args = parser.parse_args()
if not args.allow_installed_helper_probes:
    parser.error("Explicit --allow-installed-helper-probes is required")
identity = os.environ.get("MPS_SIGNING_IDENTITY")
if not identity:
    parser.error("Configure MPS_SIGNING_IDENTITY with an approved Apple signing identity")

root = Path(__file__).resolve().parent.parent
cli = args.app.resolve() / "Contents/MacOS/powerschedulectl"
details = subprocess.run(["codesign", "-d", "--verbose=4", str(cli)], capture_output=True, text=True, check=True).stderr
match = re.search(r"^TeamIdentifier=([A-Z0-9]{10})$", details, re.M)
if not match:
    raise SystemExit("Installed CLI must have an Apple signing team")
team = match.group(1)
subprocess.run(["swift", "build", "--package-path", str(root / "Package"), "--product", "HelperIntegrationProbe"], check=True)
binary_dir = subprocess.run(["swift", "build", "--package-path", str(root / "Package"), "--show-bin-path"], capture_output=True, text=True, check=True).stdout.strip()
probe_dir = root / ".build/HelperProbes"
probe_dir.mkdir(parents=True, exist_ok=True)
probes = {}
for name, signing, identifier in [
    ("accepted", identity, "com.antonioruffolo.MacPowerScheduler.cli"),
    ("wrong-identifier", identity, "com.antonioruffolo.MacPowerScheduler.probe-rejected"),
    ("ad-hoc", "-", "com.antonioruffolo.MacPowerScheduler.cli"),
]:
    destination = probe_dir / name
    shutil.copy2(Path(binary_dir) / "HelperIntegrationProbe", destination)
    subprocess.run(["codesign", "--force", "--sign", signing, "--identifier", identifier,
                    "--options", "runtime", str(destination)], check=True, capture_output=True)
    probes[name] = destination


def system_fingerprint():
    # Compare privately, including one-time owners, without retaining raw values.
    state = subprocess.run(["/usr/bin/pmset", "-g", "sched"], capture_output=True, check=True).stdout
    return hashlib.sha256(state).digest()


def probe(name, mode, expected, code=None):
    before = system_fingerprint()
    result = subprocess.run([str(probes[name]), team, mode], capture_output=True, text=True, timeout=20)
    if result.returncode != expected:
        raise SystemExit(f"FAIL {name}/{mode}: expected exit {expected}, got {result.returncode}")
    if name != "accepted" and result.stdout.strip():
        raise SystemExit(f"FAIL {name}/{mode}: received an application reply; listener rejection was not proven")
    if code is not None and json.loads(result.stdout).get("error", {}).get("code") != code:
        raise SystemExit(f"FAIL {name}/{mode}: wrong structured error")
    if system_fingerprint() != before:
        raise SystemExit("System schedule changed during probe; stop and reconcile (no automatic restore)")
    print(f"PASS {name}/{mode}")


# A live accepted control before/after each negative prevents a dead helper being
# mistaken for a successful security rejection. Timeout (7) is never accepted.
probe("accepted", "status", 0)
for mode, expected, code in [
    ("malformed", 2, "invalidInput"),
    ("oversized", 2, "invalidInput"),
    ("version", 4, "helperUnavailable"),
    ("grant-denied", 3, "authorizationRequired"),
]:
    probe("accepted", mode, expected, code)
    probe("accepted", "status", 0)
for rejected in ["wrong-identifier", "ad-hoc"]:
    probe(rejected, "status", 4)
    probe("accepted", "status", 0)
print("PASS: installed-helper peer/payload probes. Mutation, second-team/account, revocation, lifecycle and power gates remain separate.")
