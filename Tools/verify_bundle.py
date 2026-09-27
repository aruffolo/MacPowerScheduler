#!/usr/bin/env python3
"""Inspect a universal bundle without launching or installing any component."""
import plistlib
import subprocess
import sys
from pathlib import Path

app = Path(sys.argv[1]).resolve()
executables = [app / "Contents/MacOS" / name for name in ["MacPowerScheduler", "MacPowerSchedulerHelper", "powerschedulectl"]]
for executable in executables:
    subprocess.run(["lipo", str(executable), "-verify_arch", "arm64", "x86_64"], check=True)
    subprocess.run(["codesign", "--verify", "--strict", str(executable)], check=True)
    metadata = subprocess.run(["xcrun", "vtool", "-show-build", str(executable)], capture_output=True, text=True, check=True).stdout
    minimums = [line.split()[-1] for line in metadata.splitlines() if line.strip().startswith("minos ")]
    if not (minimums and all((value == '14.0' for value in minimums))):
        raise SystemExit('Unexpected executable deployment target')
for library in (app / "Contents/Frameworks").rglob("*"):
    if not library.is_file() or library.is_symlink():
        continue
    kind = subprocess.run(["file", "-b", str(library)], capture_output=True, text=True, check=True).stdout
    if "Mach-O" in kind:
        subprocess.run(["lipo", str(library), "-verify_arch", "arm64", "x86_64"], check=True)
        subprocess.run(["codesign", "--verify", "--strict", str(library)], check=True)
with (app / "Contents/Library/LaunchDaemons/com.antonioruffolo.MacPowerScheduler.helper.plist").open("rb") as stream:
    daemon = plistlib.load(stream)
if not (daemon['BundleProgram'] == 'Contents/MacOS/MacPowerSchedulerHelper'):
    raise SystemExit("Verification failed: daemon['BundleProgram'] == 'Contents/MacOS/MacPowerSchedulerHelper'")
if not (daemon['MachServices'] == {'com.antonioruffolo.MacPowerScheduler.helper': True}):
    raise SystemExit("Verification failed: daemon['MachServices'] == {'com.antonioruffolo.MacPowerScheduler.helper': True}")
subprocess.run(["codesign", "--verify", "--strict", str(app)], check=True)
print("PASS: universal executable slices, macOS 14 deployment, signatures, and embedded daemon layout.")
print("This check does not establish Developer ID trust, notarization, or runtime behavior on untested systems.")
