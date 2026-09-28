"""Verify architecture policy using synthetic tool output, never signing keys."""
import contextlib
import io
import plistlib
import runpy
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / "verify_bundle.py"


class BundleVerifierTests(unittest.TestCase):
    def verify(self, variant="universal", architectures="arm64 x86_64", library_architectures=None,
               minimum="14.0"):
        with tempfile.TemporaryDirectory() as directory:
            app = Path(directory) / "App.app"
            daemon = app / "Contents/Library/LaunchDaemons/com.antonioruffolo.MacPowerScheduler.helper.plist"
            daemon.parent.mkdir(parents=True)
            daemon.write_bytes(plistlib.dumps({
                "BundleProgram": "Contents/MacOS/MacPowerSchedulerHelper",
                "MachServices": {"com.antonioruffolo.MacPowerScheduler.helper": True},
            }))
            if library_architectures is not None:
                library = app / "Contents/Frameworks/libExample.dylib"
                library.parent.mkdir(parents=True)
                library.touch()

            def command(args, **kwargs):
                output = ""
                if args[0] == "lipo":
                    actual = library_architectures if str(args[1]).endswith(".dylib") else architectures
                    output = actual
                    if "-verify_arch" in args and not set(args[3:]).issubset(actual.split()):
                        raise subprocess.CalledProcessError(1, args)
                elif args[:2] == ["xcrun", "vtool"]:
                    output = f"minos {minimum}\n"
                elif args[0] == "file":
                    output = "Mach-O dynamically linked shared library"
                return subprocess.CompletedProcess(args, 0, stdout=output, stderr="")

            with patch.object(sys, "argv", [str(SCRIPT), str(app), "--variant", variant]), patch(
                "subprocess.run", side_effect=command
            ), contextlib.redirect_stdout(io.StringIO()):
                runpy.run_path(str(SCRIPT), run_name="__main__")

    def test_universal_and_arm64(self):
        self.verify()
        self.verify("arm64", "arm64")

    def test_arm64_rejects_universal_payload(self):
        with self.assertRaisesRegex(SystemExit, "architecture"):
            self.verify("arm64", "arm64 x86_64")

    def test_universal_rejects_missing_slice(self):
        with self.assertRaisesRegex(SystemExit, "architecture"):
            self.verify("universal", "arm64")

    def test_nested_library_must_match_variant(self):
        with self.assertRaisesRegex(SystemExit, "architecture"):
            self.verify("arm64", "arm64", library_architectures="arm64 x86_64")

    def test_wrong_deployment_target_rejected(self):
        with self.assertRaisesRegex(SystemExit, "deployment"):
            self.verify(minimum="15.0")


if __name__ == "__main__":
    unittest.main()
