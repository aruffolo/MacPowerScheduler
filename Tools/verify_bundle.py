#!/usr/bin/env python3
"""Inspect exact bundle architectures without launching or installing components."""
import argparse
import plistlib
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("app", type=Path)
parser.add_argument("--variant", choices=["universal", "arm64"], default="universal")
options = parser.parse_args()
app = options.app.resolve()
expected_architectures = {"arm64", "x86_64"} if options.variant == "universal" else {"arm64"}


def verify_code(path):
    architectures = subprocess.run(["lipo", str(path), "-archs"], capture_output=True, text=True, check=True).stdout.split()
    if set(architectures) != expected_architectures:
        raise SystemExit(f"Unexpected architecture set in {path.name}; expected {options.variant}")
    subprocess.run(["codesign", "--verify", "--all-architectures", "--strict", str(path)], check=True)


executables = [app / "Contents/MacOS" / name for name in ["MacPowerScheduler", "MacPowerSchedulerHelper", "powerschedulectl"]]
for executable in executables:
    verify_code(executable)
    metadata = subprocess.run(["xcrun", "vtool", "-show-build", str(executable)], capture_output=True, text=True, check=True).stdout
    minimums = [line.split()[-1] for line in metadata.splitlines() if line.strip().startswith("minos ")]
    if not (minimums and all((value == '14.0' for value in minimums))):
        raise SystemExit('Unexpected executable deployment target')
for library in (app / "Contents/Frameworks").rglob("*"):
    if not library.is_file() or library.is_symlink():
        continue
    kind = subprocess.run(["file", "-b", str(library)], capture_output=True, text=True, check=True).stdout
    if "Mach-O" in kind:
        verify_code(library)
with (app / "Contents/Library/LaunchDaemons/com.antonioruffolo.MacPowerScheduler.helper.plist").open("rb") as stream:
    daemon = plistlib.load(stream)
if not (daemon['BundleProgram'] == 'Contents/MacOS/MacPowerSchedulerHelper'):
    raise SystemExit("Verification failed: daemon['BundleProgram'] == 'Contents/MacOS/MacPowerSchedulerHelper'")
if not (daemon['MachServices'] == {'com.antonioruffolo.MacPowerScheduler.helper': True}):
    raise SystemExit("Verification failed: daemon['MachServices'] == {'com.antonioruffolo.MacPowerScheduler.helper': True}")
subprocess.run(["codesign", "--verify", "--all-architectures", "--strict", str(app)], check=True)
print(f"PASS: {options.variant} executable slices, macOS 14 deployment, signatures, and embedded daemon layout.")
print("This check does not establish Developer ID trust, notarization, or runtime behavior on untested systems.")
