#!/usr/bin/env python3
"""Package a verified notarized app and matching symbols, then verify extraction."""
import argparse
import hashlib
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
EXECUTABLES = ["MacPowerScheduler", "MacPowerSchedulerHelper", "powerschedulectl"]


def uuids(path):
    output = subprocess.run(["dwarfdump", "--uuid", str(path)], capture_output=True,
                            text=True, check=True).stdout
    identifiers = set(re.findall(r"UUID: ([A-Fa-f0-9-]{36}) \(([^)]+)\)", output))
    if not identifiers:
        raise ValueError(f"No debug UUIDs in {path.name}")
    return identifiers


def verify_symbols(app, archive):
    for name in EXECUTABLES:
        expected = uuids(app / "Contents/MacOS" / name)
        candidates = list((archive / "dSYMs").glob(f"*.dSYM/Contents/Resources/DWARF/{name}"))
        if len(candidates) != 1 or uuids(candidates[0]) != expected:
            raise ValueError(f"Missing or mismatched debug symbols for {name}")
        if str(Path.home()).encode() in candidates[0].read_bytes():
            raise ValueError(f"Debug symbols contain a local home path for {name}")


def verify_app(app, variant):
    subprocess.run([sys.executable, str(TOOLS / "verify_bundle.py"), str(app),
                    "--variant", variant], check=True)
    subprocess.run([sys.executable, str(TOOLS / "verify_release_identity.py"), str(app)], check=True)
    subprocess.run(["xcrun", "stapler", "validate", str(app)], check=True)
    subprocess.run(["spctl", "--assess", "--type", "execute", str(app)], check=True)


def stage_symbols(archive, destination):
    shutil.copytree(archive / "dSYMs", destination)
    # dsymutil's relocation metadata retains the original build path independently of DWARF mappings.
    for metadata in destination.glob("*.dSYM/Contents/Resources/Relocations/*/*.yml"):
        metadata.write_text(re.sub(r"(?m)^binary-path:[^\n]*$",
                                   f"binary-path: '/MacPowerScheduler/{metadata.stem}'", metadata.read_text()))
    for path in destination.rglob("*"):
        if path.is_file() and str(Path.home()).encode() in path.read_bytes():
            raise ValueError(f"Debug symbol files contain a local home path in {path.name}")


def package(app, archive, variant, output):
    with (app / "Contents/Info.plist").open("rb") as stream:
        version = plistlib.load(stream)["CFBundleShortVersionString"]
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+(?:-[A-Za-z0-9.-]+)?", version):
        raise ValueError("Unexpected release version")
    destination = output / version
    name = f"MacPowerScheduler-macos-{variant}-{version}"
    app_zip = destination / f"{name}.zip"
    symbols_zip = destination / f"{name}.dSYM.zip"
    if app_zip.exists() or symbols_zip.exists():
        raise ValueError("Release artifacts already exist; preserve them before repackaging")
    verify_app(app, variant)
    verify_symbols(app, archive)
    destination.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="package-", dir=destination) as temporary:
        staging = Path(temporary)
        candidate = staging / app_zip.name
        subprocess.run(["ditto", "-c", "-k", "--keepParent", str(app), str(candidate)], check=True)
        extracted = staging / "extracted"
        subprocess.run(["ditto", "-x", "-k", str(candidate), str(extracted)], check=True)
        verify_app(extracted / app.name, variant)
        symbols = staging / "dSYMs"
        stage_symbols(archive, symbols)
        staged_symbols = staging / symbols_zip.name
        subprocess.run(["ditto", "-c", "-k", "--keepParent", str(symbols),
                        str(staged_symbols)], check=True)
        candidate.rename(app_zip)
        staged_symbols.rename(symbols_zip)
    artifacts = []
    for architecture in ["universal", "arm64"]:
        for suffix in [".zip", ".dSYM.zip"]:
            artifact = destination / f"MacPowerScheduler-macos-{architecture}-{version}{suffix}"
            if artifact.exists():
                artifacts.append(artifact)
    manifest = "".join(f"{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.name}\n" for path in artifacts)
    (destination / "SHA256SUMS").write_text(manifest)
    print(f"PASS: notarized {variant} ZIP, matching dSYMs, extracted verification and checksums in {destination}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", type=Path)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--variant", choices=["universal", "arm64"], required=True)
    parser.add_argument("--output", type=Path, required=True)
    arguments = parser.parse_args()
    package(arguments.app.resolve(), arguments.archive.resolve(), arguments.variant, arguments.output.resolve())


if __name__ == "__main__":
    main()
