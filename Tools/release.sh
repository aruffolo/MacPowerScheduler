#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
release_dir=.build/Release
archive_path="$release_dir/MacPowerScheduler.xcarchive"
release_app="$archive_path/Products/Applications/MacPowerScheduler.app"

case "${1:-}" in
  archive)
    : "${MPS_SIGNING_IDENTITY:?Set an approved Developer ID Application signing identity}"
    : "${MPS_DEVELOPMENT_TEAM:?Set your signing team identifier}"
    mkdir -p "$release_dir"
    xcodebuild -workspace MacPowerScheduler.xcworkspace -scheme MacPowerScheduler \
      -configuration Release -destination 'generic/platform=macOS' \
      -archivePath "$archive_path" ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO \
      CODE_SIGN_IDENTITY="$MPS_SIGNING_IDENTITY" DEVELOPMENT_TEAM="$MPS_DEVELOPMENT_TEAM" archive
    bash Tools/release.sh verify
    ;;
  verify)
    python3 Tools/verify_bundle.py "$release_app"
    python3 Tools/verify_release_identity.py "$release_app"
    ;;
  notarize)
    : "${MPS_NOTARY_PROFILE:?Set an existing approved notarytool Keychain profile}"
    bash Tools/release.sh verify
    ditto -c -k --keepParent "$release_app" "$release_dir/MacPowerScheduler-submission.zip"
    xcrun notarytool submit "$release_dir/MacPowerScheduler-submission.zip" \
      --keychain-profile "$MPS_NOTARY_PROFILE" --wait --output-format json > "$release_dir/notarization.json"
    python3 -c 'import json, sys; sys.exit(0 if json.load(open(".build/Release/notarization.json"))["status"] == "Accepted" else "Notarization was not accepted")'
    xcrun stapler staple "$release_app"
    xcrun stapler validate "$release_app"
    spctl --assess --type execute "$release_app"
    ditto -c -k --keepParent "$release_app" "$release_dir/MacPowerScheduler.zip"
    shasum -a 256 "$release_dir/MacPowerScheduler.zip" > "$release_dir/SHA256SUMS"
    printf '%s\n' 'Notarized ZIP prepared locally; nothing published.'
    ;;
  *) printf '%s\n' 'Usage: bash Tools/release.sh archive|verify|notarize' >&2; exit 2 ;;
esac
