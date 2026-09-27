"""Exercise index safety in disposable repositories; never commit anything."""
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


class PreCommitTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="hook test ")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.git("init", "--quiet")
        shutil.copyfile(ROOT / ".swiftformat", self.root / ".swiftformat")

    def git(self, *args):
        return subprocess.run(
            ["git", *args], cwd=self.root, check=True, capture_output=True
        ).stdout

    def hook(self):
        return subprocess.run(
            [str(ROOT / "Tools/git-hooks/pre-commit")], cwd=self.root,
            capture_output=True, text=True,
        )

    def test_formats_and_restages_space_filename_only(self):
        source = self.root / "Example File.swift"
        source.write_text("func example(){print(1)}\n")
        self.git("add", "--", source.name)
        unrelated = self.root / "Unstaged.swift"
        unrelated.write_text("// leave this alone\n")
        result = self.hook()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotEqual(source.read_text(), "func example(){print(1)}\n")
        self.assertEqual(self.git("show", ":" + source.name), source.read_bytes())
        self.assertEqual(self.git("diff", "--cached", "--name-only"), b"Example File.swift\n")
        self.assertEqual(unrelated.read_text(), "// leave this alone\n")

    def test_partial_staging_preserves_index_and_worktree(self):
        source = self.root / "Partial.swift"
        staged = "func example(){print(1)}\n"
        source.write_text(staged)
        self.git("add", source.name)
        unstaged = staged + "// an unrelated edit\n"
        source.write_text(unstaged)
        result = self.hook()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unstaged edits", result.stderr)
        self.assertEqual(source.read_text(), unstaged)
        self.assertEqual(self.git("show", ":" + source.name), staged.encode())

    def test_no_swift_changes_leaves_index_unchanged(self):
        (self.root / "note.txt").write_text("note\n")
        self.git("add", "note.txt")
        before = self.git("diff", "--cached")
        result = self.hook()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.git("diff", "--cached"), before)


if __name__ == "__main__":
    unittest.main()
