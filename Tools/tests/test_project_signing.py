"""Check generated production signing without accessing accounts or private keys."""
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


class ProjectSigningTests(unittest.TestCase):
    def test_production_targets_preserve_shared_signing(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            tools = root / "Tools"
            tools.mkdir()
            generator = tools / "generate_project.py"
            shutil.copyfile(Path(__file__).resolve().parents[1] / generator.name, generator)
            subprocess.run([sys.executable, str(generator)], check=True, capture_output=True)
            result = subprocess.run(
                ["plutil", "-convert", "json", "-o", "-",
                 str(root / "MacPowerScheduler.xcodeproj/project.pbxproj")],
                check=True, capture_output=True,
            )
            objects = json.loads(result.stdout)["objects"]
            targets = [obj for obj in objects.values() if obj["isa"] == "PBXNativeTarget"]
            self.assertEqual({target["name"] for target in targets}, {"Helper", "CLI", "MacPowerScheduler"})
            for target in targets:
                configurations = objects[target["buildConfigurationList"]]["buildConfigurations"]
                for reference in configurations:
                    configuration = objects[reference]
                    settings = configuration["buildSettings"]
                    with self.subTest(target=target["name"], mode=configuration["name"]):
                        self.assertNotIn("DEVELOPMENT_TEAM", settings)
                        for key in ["TEST_TARGET_NAME", "CODE_SIGN_STYLE", "CODE_SIGN_IDENTITY",
                                    "PROVISIONING_PROFILE_REQUIRED", "ENABLE_HARDENED_RUNTIME",
                                    "CODE_SIGN_INJECT_BASE_ENTITLEMENTS"]:
                            self.assertNotIn(key, settings)



if __name__ == "__main__":
    unittest.main()
