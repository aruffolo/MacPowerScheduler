"""Check snapshot selection and failure propagation without running Swift."""
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

MAKEFILE = Path(__file__).resolve().parents[2] / "Makefile"


class SnapshotWorkflowTests(unittest.TestCase):
    def run_workflow(self, target="test-snapshots", exit_code=0, inherited_record=None):
        with tempfile.TemporaryDirectory(prefix="snapshot workflow ") as directory:
            root = Path(directory)
            stub = root / "swift"
            stub.write_text('''#!/usr/bin/env python3
import json, os, sys
with open(os.environ["MPS_TEST_COMMAND_LOG"], "w") as stream:
    json.dump({"args": sys.argv[1:], "record": os.getenv("MPS_RECORD_SNAPSHOTS")}, stream)
sys.exit(int(os.environ["MPS_TEST_EXIT"]))
''')
            stub.chmod(0o755)
            log = root / "command.json"
            environment = dict(os.environ, PATH=str(root) + os.pathsep + os.environ["PATH"],
                               MPS_TEST_COMMAND_LOG=str(log), MPS_TEST_EXIT=str(exit_code))
            environment.pop("MPS_RECORD_SNAPSHOTS", None)
            if inherited_record is not None:
                environment["MPS_RECORD_SNAPSHOTS"] = inherited_record
            result = subprocess.run(["make", "-f", str(MAKEFILE), target], cwd=root,
                                    env=environment, capture_output=True, text=True)
            return result, json.loads(log.read_text())

    def test_snapshot_failure_is_not_masked(self):
        result, _ = self.run_workflow(exit_code=1)
        self.assertNotEqual(result.returncode, 0)

    def test_verification_selects_snapshots_without_recording(self):
        result, call = self.run_workflow()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(call["args"], ["test", "--package-path", "Package", "--filter",
                                        "PowerScheduleSnapshotTests"])
        self.assertEqual(call["record"], "0")

    def test_verification_overrides_inherited_recording(self):
        result, call = self.run_workflow(inherited_record="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(call["record"], "0")

    def test_recording_requires_explicit_target(self):
        result, call = self.run_workflow("record-snapshots")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(call["record"], "1")


if __name__ == "__main__":
    unittest.main()
