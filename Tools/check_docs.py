#!/usr/bin/env python3
"""Check documentation fences and local Markdown link/image file targets offline.

This is a small check for the repository's Markdown conventions, not a complete
Markdown renderer. URL availability, heading anchors and prose need review.
"""
import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

DESTINATION = r"(?:<([^>]+)>|([^\s)]+))"
INLINE_LINK = re.compile(r"\]\(\s*" + DESTINATION)
REFERENCE_LINK = re.compile(r"^\s{0,3}\[[^]]+\]:\s*" + DESTINATION)
FENCE = re.compile(r"^\s{0,3}(`{3,}|~{3,})(.*)$")


def check_document(document, root):
    errors = []
    fence = None
    for number, line in enumerate(document.read_text(encoding="utf-8").splitlines(), 1):
        marker = FENCE.match(line)
        if fence:
            if (marker and marker[1][0] == fence[0] and len(marker[1]) >= len(fence)
                    and not marker[2].strip()):
                fence = None
            continue
        if marker:
            fence = marker[1]
            continue
        line = re.sub(r"(`+).*?\1", "", line)
        matches = list(INLINE_LINK.finditer(line)) + list(REFERENCE_LINK.finditer(line))
        for match in matches:
            destination = match[1] or match[2]
            url = urlsplit(destination)
            if url.scheme or url.netloc or not url.path:
                continue
            path = unquote(url.path)
            target = (root / path.lstrip("/") if path.startswith("/")
                      else document.parent / path).resolve()
            if not target.is_relative_to(root.resolve()):
                errors.append(f"{document}:{number}: link outside repository: {destination}")
            elif not target.exists():
                errors.append(f"{document}:{number}: missing link target: {destination}")
    if fence:
        errors.append(f"{document}: unclosed code fence")
    return errors


def main():
    from ci import is_documentation

    root = Path(subprocess.check_output(["git", "rev-parse", "--show-toplevel"],
                                       text=True).strip())
    tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=root).decode().split("\0")
    documents = [root / path for path in tracked if is_documentation(path)]
    errors = [error for document in documents for error in check_document(document, root)]
    if errors:
        sys.exit("\n".join(errors))
    print(f"Checked {len(documents)} documentation files: local links/images and code fences.")


if __name__ == "__main__":
    main()
