#!/bin/bash
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"
cd "$(dirname "$0")/.."

if ! command -v swiftlint >/dev/null 2>&1; then
    echo "SwiftLint not installed. Install via 'brew install swiftlint'." >&2
    exit 1
fi

swiftlint lint --cache-path .build/SwiftLintCache --config .swiftlint.yml App Helper CLI Tools
swiftlint lint --cache-path .build/SwiftLintCache --config Package/.swiftlint.yml Package
