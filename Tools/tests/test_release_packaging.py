"""Test release rejection and artifact integrity with disposable app fixtures."""
import importlib.util
import hashlib
import plistlib
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location("package_release", Path(__file__).resolve().parents[1] / "package_release.py")
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class ReleasePackagingTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.app = self.root / "MacPowerScheduler.app"
        (self.app / "Contents").mkdir(parents=True)
        (self.app / "Contents/Info.plist").write_bytes(plistlib.dumps({"CFBundleShortVersionString": "0.1.0"}))
        self.archive = self.root / "Archive.xcarchive"
        (self.archive / "dSYMs").mkdir(parents=True)
        (self.archive / "dSYMs/example.txt").write_text("synthetic symbols")
        self.output = self.root / "output"

    def package(self, variant="arm64"):
        MODULE.package(self.app, self.archive, variant, self.output)

    def test_failed_extraction_verification_publishes_no_zip(self):
        with patch.object(MODULE, "verify_app", side_effect=[None, ValueError("invalid extracted ticket")]), patch.object(
            MODULE, "verify_symbols"
        ), self.assertRaisesRegex(ValueError, "extracted ticket"):
            self.package()
        self.assertEqual(list(self.output.rglob("*.zip")), [])
        self.assertFalse((self.output / "0.1.0/SHA256SUMS").exists())

    def test_two_variants_have_distinct_assets_and_verifiable_checksums(self):
        with patch.object(MODULE, "verify_app"), patch.object(MODULE, "verify_symbols"):
            self.package("universal")
            self.package("arm64")
            with self.assertRaisesRegex(ValueError, "already exist"):
                self.package("arm64")
        destination = self.output / "0.1.0"
        lines = (destination / "SHA256SUMS").read_text().splitlines()
        self.assertEqual(len(lines), 4)
        for line in lines:
            digest, name = line.split("  ")
            self.assertEqual(digest, hashlib.sha256((destination / name).read_bytes()).hexdigest())
        self.assertTrue((destination / "MacPowerScheduler-macos-universal-0.1.0.zip").exists())
        self.assertTrue((destination / "MacPowerScheduler-macos-arm64-0.1.0.zip").exists())

    def test_symbols_from_another_build_are_rejected(self):
        for name in MODULE.EXECUTABLES:
            symbol = self.archive / f"dSYMs/{name}.dSYM/Contents/Resources/DWARF/{name}"
            symbol.parent.mkdir(parents=True)
            symbol.touch()
        def identifiers(path):
            return {("different" if "dSYMs" in path.parts else "original", "arm64")}
        with patch.object(MODULE, "uuids", side_effect=identifiers), self.assertRaisesRegex(ValueError, "mismatched"):
            MODULE.verify_symbols(self.app, self.archive)

    def test_symbols_with_local_home_paths_are_rejected(self):
        for name in MODULE.EXECUTABLES:
            symbol = self.archive / f"dSYMs/{name}.dSYM/Contents/Resources/DWARF/{name}"
            symbol.parent.mkdir(parents=True)
            symbol.write_bytes(b"/Users/synthetic/private/source.swift")
        with patch.object(MODULE, "uuids", return_value={("matching", "arm64")}), patch.object(
            MODULE.Path, "home", return_value=Path("/Users/synthetic")
        ), self.assertRaisesRegex(ValueError, "local home path"):
            MODULE.verify_symbols(self.app, self.archive)

    def test_packaged_relocations_use_portable_binary_paths(self):
        relative = "example.dSYM/Contents/Resources/Relocations/aarch64/example.yml"
        metadata = self.archive / "dSYMs" / relative
        metadata.parent.mkdir(parents=True)
        original = f"---\nbinary-path: '{Path.home()}/build/example'\nrelocations: []\n"
        metadata.write_text(original)
        with patch.object(MODULE, "verify_app"), patch.object(MODULE, "verify_symbols"):
            self.package()
        with zipfile.ZipFile(next(self.output.rglob("*.dSYM.zip"))) as symbols:
            actual = symbols.read("dSYMs/" + relative).decode()
        self.assertEqual(actual, "---\nbinary-path: '/MacPowerScheduler/example'\nrelocations: []\n")
        self.assertEqual(metadata.read_text(), original)

    def test_other_symbol_files_with_local_paths_prevent_publication(self):
        (self.archive / "dSYMs/example.txt").write_text(str(Path.home()) + "/private")
        with patch.object(MODULE, "verify_app"), patch.object(MODULE, "verify_symbols"), self.assertRaisesRegex(
            ValueError, "local home path"
        ):
            self.package()
        self.assertEqual(list(self.output.rglob("*.zip")), [])


if __name__ == "__main__":
    unittest.main()
