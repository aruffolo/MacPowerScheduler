"""Exercise release rejection paths with synthetic codesign output, never keys."""
import contextlib
import io
import plistlib
import runpy
import subprocess
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / "verify_release_identity.py"


class ReleaseVerifierTests(unittest.TestCase):
    def verify(self, *, flags="0x10000(runtime)", team="AAAAAAAAAA", bad_identifier=False,
               entitlements=None, adhoc=False):
        def command(args, **kwargs):
            target = str(args[-1])
            if "--verify" in args:
                return subprocess.CompletedProcess(args, 0)
            if "--entitlements" in args:
                return subprocess.CompletedProcess(args, 0, stdout=plistlib.dumps(entitlements or {}))
            suffix = ".helper" if target.endswith("Helper") else ".cli" if target.endswith("powerschedulectl") else ""
            identifier = "unexpected" if bad_identifier else "com.antonioruffolo.MacPowerScheduler" + suffix
            current_team = team if suffix else "AAAAAAAAAA"
            authority = "Signature=adhoc" if adhoc else "Authority=Developer ID Application: Test"
            details = f"Executable={target}\nIdentifier={identifier}\nCodeDirectory v=20500 size=100 flags={flags} hashes=1\n{authority}\nTeamIdentifier={current_team}\n"
            return subprocess.CompletedProcess(args, 0, stdout="", stderr=details)

        with patch.object(sys, "argv", [str(SCRIPT), "/synthetic/runtime/App.app"]), patch(
            "subprocess.run", side_effect=command
        ), contextlib.redirect_stdout(io.StringIO()):
            runpy.run_path(str(SCRIPT), run_name="__main__")

    def test_valid_metadata(self):
        self.verify()

    def test_runtime_in_path_is_not_a_runtime_flag(self):
        with self.assertRaisesRegex(SystemExit, "Hardened runtime"):
            self.verify(flags="0x0(none)")

    def test_identifier_and_team_rejections(self):
        with self.assertRaisesRegex(SystemExit, "identifier"):
            self.verify(bad_identifier=True)
        with self.assertRaisesRegex(SystemExit, "matching signing teams"):
            self.verify(team="BBBBBBBBBB")

    def test_adhoc_and_debug_entitlements_rejected(self):
        with self.assertRaisesRegex(SystemExit, "Developer ID"):
            self.verify(adhoc=True)
        with self.assertRaisesRegex(SystemExit, "Unsafe release entitlement"):
            self.verify(entitlements={"com.apple.security.get-task-allow": True})


if __name__ == "__main__":
    unittest.main()
