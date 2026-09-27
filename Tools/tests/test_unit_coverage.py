"""Coverage must fail closed instead of silently shrinking the denominator."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import subprocess

SPEC = importlib.util.spec_from_file_location("unit_coverage", Path(__file__).parents[1] / "unit_coverage.py")
coverage = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(coverage)


class UnitCoverageTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.source = self.root / "Package/Sources"
        (self.source / "Module").mkdir(parents=True)
        (self.source / "Module/Logic.swift").write_text("func logic() {}\n")
        (self.source / "Module/Adapter.swift").write_text("func adapter() {}\n")
        (self.root / "Package/Package.swift").write_text("// test manifest\n")
        self.scope = {"minimumLinePercent": 95, "unit": ["Module/Logic.swift"],
                      "integration": {"Module/Adapter.swift": "Real OS adapter"}}
        (self.root / "Tools").mkdir()
        self.scope_path = self.root / "Tools/unit-coverage-scope.json"
        self.scope_path.write_text(json.dumps(self.scope))

    def test_new_file_requires_classification(self):
        coverage.load_scope(self.scope_path, self.source)
        (self.source / "Module/New.swift").write_text("func new() {}\n")
        with self.assertRaisesRegex(ValueError, "unclassified=.*New.swift"):
            coverage.load_scope(self.scope_path, self.source)

    def test_duplicate_stale_or_empty_scope_is_rejected(self):
        for update in [
            {"unit": ["Module/Logic.swift", "Module/Logic.swift"]},
            {"unit": ["Module/Missing.swift"]},
            {"integration": {"Module/Adapter.swift": ""}},
            {"minimumLinePercent": float("nan")},
        ]:
            with self.subTest(update=update):
                self.scope_path.write_text(json.dumps(self.scope | update))
                with self.assertRaises(ValueError):
                    coverage.load_scope(self.scope_path, self.source)

    def test_missing_export_entry_fails(self):
        export = self.export([("Module/Logic.swift", 100, 100)])
        with self.assertRaisesRegex(ValueError, "absent=.*Adapter.swift"):
            coverage.read_metrics(export, self.source, {"Module/Logic.swift", "Module/Adapter.swift"})

    def test_invalid_counters(self):
        for entries in [
            [("Module/Logic.swift", 100, 100), ("Module/Logic.swift", 100, 100)],
            [("Module/Logic.swift", 1, 2)],
            [("Module/Logic.swift", -1, 0)],
        ]:
            with self.subTest(entries=entries), self.assertRaises(ValueError):
                coverage.read_metrics(self.export(entries), self.source, {"Module/Logic.swift"})

    def test_threshold_uses_exact_fraction_and_weighted_lines(self):
        for covered, expected in [(9499, False), (9500, True), (9501, True)]:
            metrics = {"Module/Logic.swift": {"count": 10000, "covered": covered},
                       "Module/Adapter.swift": {"count": 10000, "covered": 0}}
            result = coverage.report(self.scope, metrics)
            self.assertEqual(result["passed"], expected)
            self.assertEqual(result["unit"]["covered"], covered)
            self.assertEqual(result["unit"]["count"], 10000)
            self.assertEqual(result["wholePackageUnitRun"]["count"], 20000)
        self.assertEqual(coverage.aggregate(iter([{"count": 9, "covered": 9}, {"count": 1, "covered": 0}]))["percent"], 90)
        with self.assertRaises(ValueError):
            coverage.aggregate([])

    def test_failed_swift_suite_cannot_produce_success_report(self):
        with patch.object(coverage, "ROOT", self.root), patch.object(coverage, "SOURCE", self.source), \
                patch.object(coverage.subprocess, "run", side_effect=subprocess.CalledProcessError(1, "swift")) as run:
            with self.assertRaises(subprocess.CalledProcessError):
                coverage.main([])
        self.assertTrue(run.call_args.kwargs["check"])
        self.assertIn("--enable-code-coverage", run.call_args.args[0])
        self.assertIn("PowerSchedule(Adapter|Snapshot)Tests", run.call_args.args[0])
        latest = json.loads((self.root / ".build/Coverage/latest.json").read_text())
        self.assertFalse(latest["passed"])
        self.assertEqual(latest["status"], "failed")
        self.assertEqual(list((self.root / latest["runDirectory"]).glob("build-*")), [])

    def test_success_retains_evidence_and_removes_build_intermediates(self):
        export = self.export([("Module/Logic.swift", 100, 95), ("Module/Adapter.swift", 100, 0)])
        with patch.object(coverage, "ROOT", self.root), patch.object(coverage, "SOURCE", self.source), \
                patch.object(coverage.subprocess, "run", side_effect=self.fake_run) as commands, patch("builtins.print"):
            coverage.main([])
        latest = json.loads((self.root / ".build/Coverage/latest.json").read_text())
        self.assertTrue(latest["passed"])
        self.assertEqual(latest["unit"]["percent"], 95)
        run = self.root / latest["runDirectory"]
        self.assertEqual((run / "coverage.json").read_bytes(), export.read_bytes())
        self.assertEqual((run / "tests.log").read_text(), "test evidence\n")
        self.assertEqual(json.loads((run / "summary.json").read_text()), latest)
        self.assertIn("95.00%", (run / "summary.md").read_text())
        self.assertEqual(list(run.glob("build-*")), [])
        self.assertTrue((run / "inputs.json").exists())
        self.assertTrue((run / "html/index.html").exists())
        exports = [call.args[0] for call in commands.call_args_list if call.args[0][:3] == ["xcrun", "llvm-cov", "export"]]
        self.assertEqual(len(exports), 2)
        self.assertEqual(exports[0][exports[0].index("--sources") + 1:], [str(self.source / "Module/Logic.swift")])

    def test_reuse_never_runs_swift_and_rejects_changed_sources_or_profiles(self):
        with patch.object(coverage, "ROOT", self.root), patch.object(coverage, "SOURCE", self.source), \
                patch.object(coverage.subprocess, "run", side_effect=self.fake_run) as commands, patch("builtins.print"):
            coverage.main([])
            first = json.loads((self.root / ".build/Coverage/latest.json").read_text())
            inputs_run = self.root / first["inputDirectory"]
            commands.reset_mock()
            coverage.main(["--reuse", "latest"])
            self.assertTrue(all(call.args[0][:2] == ["xcrun", "llvm-cov"] for call in commands.call_args_list))
            reused = json.loads((self.root / ".build/Coverage/latest.json").read_text())
            self.assertTrue(reused["reused"])
            self.assertEqual(reused["unit"], first["unit"])
            self.assertEqual(reused["inputDirectory"], first["inputDirectory"])
            source = self.source / "Module/Logic.swift"
            original = source.read_bytes()
            source.write_text("func different() {}\n")
            commands.reset_mock()
            with self.assertRaisesRegex(ValueError, "changed since measurement"):
                coverage.main(["--reuse", str(inputs_run)])
            commands.assert_not_called()
            source.write_bytes(original)
            (inputs_run / "default.profdata").write_text("modified profile")
            with self.assertRaisesRegex(ValueError, "Coverage input changed"):
                coverage.main(["--reuse", str(inputs_run)])
            commands.assert_not_called()

    def test_llvm_failure_replaces_passing_report(self):
        with patch.object(coverage, "ROOT", self.root), patch.object(coverage, "SOURCE", self.source), \
                patch.object(coverage.subprocess, "run", side_effect=self.fake_run), patch("builtins.print"):
            coverage.main([])
            with patch.object(coverage.subprocess, "run", side_effect=subprocess.CalledProcessError(1, "llvm-cov")):
                with self.assertRaises(subprocess.CalledProcessError):
                    coverage.main(["--reuse", "latest"])
        latest = json.loads((self.root / ".build/Coverage/latest.json").read_text())
        self.assertFalse(latest["passed"])

    def test_invalid_scope_replaces_previous_passing_report(self):
        output = self.root / ".build/Coverage"
        output.mkdir(parents=True)
        (output / "latest.json").write_text('{"passed": true}')
        (self.source / "Module/New.swift").write_text("func new() {}\n")
        with patch.object(coverage, "ROOT", self.root), patch.object(coverage, "SOURCE", self.source), \
                patch.object(coverage.subprocess, "run") as run:
            with self.assertRaisesRegex(ValueError, "unclassified"):
                coverage.main([])
        run.assert_not_called()
        latest = json.loads((output / "latest.json").read_text())
        self.assertFalse(latest["passed"])
        self.assertIn("New.swift", latest["error"])

    def export(self, entries):
        data = {"type": "llvm.coverage.json.export", "data": [{"files": [
            {"filename": str(self.source / name), "summary": {"lines": {"count": count, "covered": covered}}}
            for name, count, covered in entries
        ]}]}
        path = self.root / "export.json"
        path.write_text(json.dumps(data))
        return path

    def fake_run(self, command, **kwargs):
        entries = [("Module/Logic.swift", 100, 95), ("Module/Adapter.swift", 100, 0)]
        if command[0] == "swift":
            scratch = Path(command[command.index("--scratch-path") + 1])
            codecov = scratch / "test-platform/debug/codecov"
            codecov.mkdir(parents=True)
            (codecov / "MacPowerScheduler.json").write_bytes(self.export(entries).read_bytes())
            (codecov / "default.profdata").write_text("profile")
            binary = scratch / "test-platform/debug/MacPowerSchedulerPackageTests.xctest/Contents/MacOS/MacPowerSchedulerPackageTests"
            binary.parent.mkdir(parents=True)
            binary.write_text("binary")
            kwargs["stdout"].write("test evidence\n")
        elif command[:3] == ["xcrun", "llvm-cov", "export"]:
            selected = command[command.index("--sources") + 1:]
            data = json.loads(self.export([e for e in entries if str(self.source / e[0]) in selected]).read_text())
            counters = [f["summary"]["lines"] for f in data["data"][0]["files"]]
            data["data"][0]["totals"] = {"lines": coverage.aggregate(counters)}
            kwargs["stdout"].write(json.dumps(data))
        elif command[:3] == ["xcrun", "llvm-cov", "report"]:
            kwargs["stdout"].write("LLVM report\n")
        elif command[:3] == ["xcrun", "llvm-cov", "show"]:
            directory = Path(next(arg.split("=", 1)[1] for arg in command if arg.startswith("-output-dir=")))
            directory.mkdir()
            (directory / "index.html").write_text("<html>coverage</html>")
        else:
            self.fail(f"Unexpected command: {command}")


if __name__ == "__main__":
    unittest.main()
