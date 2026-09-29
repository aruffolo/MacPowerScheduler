#!/usr/bin/env python3
"""Conservative changed-file routing and the required GitHub Actions result."""
import json
import os
import re
import subprocess
import sys
from pathlib import Path, PurePosixPath

ROOT_DOCS = {"README.md", "CONTRIBUTING.md", "CHANGELOG.md", "SECURITY.md"}


def is_documentation(path):
    parts = PurePosixPath(path).parts
    return path in ROOT_DOCS or (
        len(parts) > 1 and parts[0] == "docs" and path.endswith(".md")
        and ".." not in parts)


def requires_macos(paths):
    return not paths or any(not is_documentation(path) for path in paths)


def git(*args):
    return subprocess.check_output(["git", *args], stderr=subprocess.PIPE)


def comparison(event_name, event):
    if event_name == "pull_request":
        base = event["pull_request"]["base"]["sha"]
        head = event["pull_request"]["head"]["sha"]
    elif event_name == "push":
        base, head = event["before"], event["after"]
    else:
        return None
    if any(not isinstance(ref, str) or not re.fullmatch(r"[0-9a-f]{40}", ref)
           or ref == "0" * 40 for ref in (base, head)):
        return None
    if event_name == "pull_request":
        base = git("merge-base", base, head).decode().strip()
    # Verify both objects even for push events before accepting an empty diff.
    for ref in (base, head):
        git("cat-file", "-e", ref + "^{commit}")
    return base, head


def classify():
    event = json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_text())
    try:
        refs = comparison(os.environ["GITHUB_EVENT_NAME"], event)
    except (KeyError, TypeError, subprocess.CalledProcessError):
        refs = None
    full = True
    if refs:
        # No rename detection: both the removed and added paths affect routing.
        paths = os.fsdecode(git("diff", "--no-renames", "--name-only", "-z", *refs, "--"))
        paths = paths.rstrip("\0").split("\0") if paths else []
        full = requires_macos(paths)
        subprocess.run(["git", "diff", "--check", *refs, "--"], check=True)
        print(f"Classified {len(paths)} changed paths.")
    else:
        print("Manual/unknown event or unavailable comparison; require full validation.")
    value = str(full).lower()
    with open(os.environ["GITHUB_OUTPUT"], "a") as output:
        output.write(f"full_validation={value}\n")
    print(f"Full macOS validation required: {value}")


def verify_result(needs):
    changes = needs.get("changes", {})
    full = changes.get("outputs", {}).get("full_validation")
    macos = needs.get("macos", {}).get("result")
    if changes.get("result") != "success" or full not in ("true", "false"):
        raise ValueError("Change classification/documentation checks did not succeed.")
    expected = "success" if full == "true" else "skipped"
    if macos != expected:
        raise ValueError(f"Expected macOS result {expected!r}, got {macos!r}.")
    print("Required CI checks passed" + (" (documentation-only)." if full == "false" else "."))


if __name__ == "__main__":
    try:
        if sys.argv[1:] == ["classify"]:
            classify()
        elif sys.argv[1:] == ["result"]:
            verify_result(json.loads(os.environ["CI_NEEDS"]))
        else:
            raise ValueError("Usage: python3 Tools/ci.py {classify|result}")
    except (ValueError, KeyError, TypeError, AttributeError, OSError, subprocess.CalledProcessError) as error:
        sys.exit(str(error))
