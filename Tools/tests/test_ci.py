"""Portable CI routing and required-result regressions, using real Git histories."""
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "ci.py"
spec = importlib.util.spec_from_file_location("ci", SCRIPT)
ci = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ci)


class RoutingTests(unittest.TestCase):
    def test_only_explicit_documentation_paths_can_skip_macos(self):
        for path in ("README.md", "CONTRIBUTING.md", "CHANGELOG.md", "SECURITY.md",
                     "docs/testing/ci.md", "docs/a file\nwith newline.md"):
            with self.subTest(path=path):
                self.assertFalse(ci.requires_macos([path]))
        for path in ("App/Main.swift", "Makefile", "Package/Package.resolved",
                     "Package/Tests/fixture.md", "App/AppIcon.icon/icon.json",
                     "docs/script.py", "docs/design/reference.png", "AGENTS.md",
                     ".github/workflows/ci.yml", "Tools/ci.py", "unknown.md"):
            with self.subTest(path=path):
                self.assertTrue(ci.requires_macos(["README.md", path]))
        self.assertTrue(ci.requires_macos([]))

    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="ci history ")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.git("init", "-q")
        self.git("config", "user.email", "fixture@example.invalid")
        self.git("config", "user.name", "CI fixture")
        self.write("README.md", "# Example\n")
        self.base = self.commit()

    def git(self, *args):
        return subprocess.check_output(["git", *args], cwd=self.root, text=True).strip()

    def write(self, path, content):
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content)

    def commit(self):
        self.git("add", ".")
        self.git("commit", "-qm", "fixture")
        return self.git("rev-parse", "HEAD")

    def classify(self, event_name, event):
        # Keep event/output outside the fixture repository's tracked files.
        with tempfile.TemporaryDirectory() as directory:
            event_file = Path(directory) / "event.json"
            output = Path(directory) / "output"
            event_file.write_text(json.dumps(event))
            result = subprocess.run(
                [sys.executable, str(SCRIPT), "classify"], cwd=self.root,
                env=dict(os.environ, GITHUB_EVENT_NAME=event_name,
                         GITHUB_EVENT_PATH=str(event_file), GITHUB_OUTPUT=str(output)),
                capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            return output.read_text().strip()

    def test_docs_push_and_pr_skip_full_suite(self):
        self.write("docs/a space\nand newline.md", "Documentation\n")
        head = self.commit()
        self.assertEqual(self.classify("push", {"before": self.base, "after": head}),
                         "full_validation=false")
        self.assertEqual(self.classify("pull_request", {"pull_request": {
            "base": {"sha": self.base}, "head": {"sha": head}}}), "full_validation=false")

    def test_pr_uses_whole_branch_and_excludes_base_only_changes(self):
        self.git("checkout", "-qb", "feature")
        self.write("README.md", "# Updated\n")
        head = self.commit()
        self.git("checkout", "--detach", self.base)
        self.write("App/new.swift", "// base-only change\n")
        base = self.commit()
        self.assertEqual(self.classify("pull_request", {"pull_request": {
            "base": {"sha": base}, "head": {"sha": head}}}), "full_validation=false")
        self.git("checkout", "feature")
        self.write("App/feature.swift", "// feature\n")
        self.commit()
        self.write("README.md", "# Last commit is only docs\n")
        head = self.commit()
        self.assertEqual(self.classify("pull_request", {"pull_request": {
            "base": {"sha": base}, "head": {"sha": head}}}), "full_validation=true")

    def test_rename_from_code_to_docs_and_code_deletion_require_macos(self):
        self.write("App/code.swift", "// same content\n")
        base = self.commit()
        self.git("mv", "App/code.swift", "renamed.md")
        self.git("mv", "renamed.md", "CHANGELOG.md")
        head = self.commit()
        self.assertEqual(self.classify("push", {"before": base, "after": head}),
                         "full_validation=true")
        self.assertTrue(ci.requires_macos(["App/deleted.swift"]))

    def test_push_compares_all_commits_and_deleted_paths(self):
        self.write("App/code.swift", "// implementation\n")
        base = self.commit()
        self.git("rm", "App/code.swift")
        self.commit()
        self.write("README.md", "# Documentation follow-up\n")
        head = self.commit()
        self.assertEqual(self.classify("push", {"before": base, "after": head}),
                         "full_validation=true")
        self.git("rm", "README.md")
        deletion = self.commit()
        self.assertEqual(self.classify("push", {"before": head, "after": deletion}),
                         "full_validation=false")

    def test_manual_empty_missing_and_unknown_events_run_full_suite(self):
        for name, event in (("workflow_dispatch", {}), ("unknown", {}),
                            ("push", {"before": self.base, "after": self.base}),
                            ("push", {"before": "0" * 40, "after": self.base}),
                            ("push", {"before": "f" * 40, "after": self.base}),
                            ("pull_request", {})):
            with self.subTest(name=name, event=event):
                self.assertEqual(self.classify(name, event), "full_validation=true")


class GateTests(unittest.TestCase):
    def needs(self, full="true", changes="success", macos="success"):
        return {"changes": {"result": changes, "outputs": {"full_validation": full}},
                "macos": {"result": macos}}

    def test_only_successful_full_or_intentionally_skipped_docs_pass(self):
        ci.verify_result(self.needs())
        ci.verify_result(self.needs(full="false", macos="skipped"))
        for outcome in ("failure", "cancelled", "skipped", "", None):
            with self.subTest(outcome=outcome):
                with self.assertRaises(ValueError):
                    ci.verify_result(self.needs(macos=outcome))
        for full in ("", None, "True", "garbage"):
            with self.assertRaises(ValueError):
                ci.verify_result(self.needs(full=full, macos="skipped"))
        for outcome in ("failure", "cancelled", "skipped"):
            with self.assertRaises(ValueError):
                ci.verify_result(self.needs(full="false", changes=outcome, macos="skipped"))
        for outcome in ("success", "failure", "cancelled"):
            with self.assertRaises(ValueError):
                ci.verify_result(self.needs(full="false", macos=outcome))
        for needs in ({}, {"changes": {"result": "success"}}):
            with self.assertRaises(ValueError):
                ci.verify_result(needs)

    def test_cli_propagates_failure(self):
        result = subprocess.run([sys.executable, str(SCRIPT), "result"],
                                env=dict(os.environ, CI_NEEDS=json.dumps(
                                    self.needs(macos="failure"))), capture_output=True)
        self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
