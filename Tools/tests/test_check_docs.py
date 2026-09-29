"""Offline documentation checks do not depend on remote website availability."""
import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "check_docs.py"
spec = importlib.util.spec_from_file_location("check_docs", SCRIPT)
docs = importlib.util.module_from_spec(spec)
spec.loader.exec_module(docs)


class DocumentationTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.document = self.root / "README.md"
        (self.root / "docs").mkdir()
        (self.root / "docs" / "a file.md").write_text("# Target\n")

    def errors(self, content):
        self.document.write_text(content)
        return docs.check_document(self.document, self.root)

    def test_local_links_images_and_reference_definitions(self):
        self.assertEqual(self.errors(
            "[Link](docs/a%20file.md#target)\n"
            "[Space](<docs/a file.md>)\n"
            "[Root](/docs/a%20file.md)\n"
            "[ref]: docs/a%20file.md\n"), [])
        for content in ("[Bad](missing.md)\n", "![Image](missing.png)\n",
                        "[ref]: missing.md\n"):
            with self.subTest(content=content):
                self.assertIn("missing", " ".join(self.errors(content)))

    def test_ignores_external_links_fragments_and_code(self):
        self.assertEqual(self.errors(
            "[Web](https://example.invalid/page) [Mail](mailto:example@example.invalid)\n"
            "[Anchor](#heading) [Web](//example.invalid/page)\n"
            "`[Example](missing.md)`\n"
            "```markdown\n[Example](missing.md)\n```\n"
            "~~~markdown\n[Example](missing.md)\n~~~\n"), [])

    def test_requires_closed_matching_fences(self):
        for content in ("```sh\necho example\n", "~~~md\n```\n", "````md\n```\n"):
            with self.subTest(content=content):
                self.assertIn("unclosed", " ".join(self.errors(content)))

    def test_matching_longer_closing_fence_and_nested_example(self):
        self.assertEqual(self.errors("````md\n```sh\nexample\n```\n`````\n"), [])

    def test_paths_must_stay_inside_repository(self):
        self.assertIn("outside", " ".join(self.errors("[Bad](../outside.md)\n")))

    def test_cli_checks_unchanged_documents_after_target_deletion(self):
        self.document.write_text("[Target](docs/a%20file.md)\n")
        subprocess.run(["git", "init", "-q"], cwd=self.root, check=True)
        subprocess.run(["git", "add", "."], cwd=self.root, check=True)
        command = [sys.executable, str(SCRIPT)]
        good = subprocess.run(command, cwd=self.root, capture_output=True, text=True)
        self.assertEqual(good.returncode, 0, good.stderr)
        subprocess.run(["git", "rm", "-f", "docs/a file.md"], cwd=self.root,
                       check=True, capture_output=True)
        bad = subprocess.run(command, cwd=self.root, capture_output=True, text=True)
        self.assertNotEqual(bad.returncode, 0)
        self.assertIn("missing link target", bad.stderr)


if __name__ == "__main__":
    unittest.main()
