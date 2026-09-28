#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
variant="${2:-universal}"
case "$variant" in
  universal) architectures='arm64 x86_64' ;;
  arm64) architectures='arm64' ;;
  *) printf '%s\n' 'Variant must be universal or arm64.' >&2; exit 2 ;;
esac
release_dir=".build/Release/$variant"
archive_path="$release_dir/MacPowerScheduler.xcarchive"
release_app="$archive_path/Products/Applications/MacPowerScheduler.app"

case "${1:-}" in
  archive)
    : "${MPS_SIGNING_IDENTITY:?Set an approved Developer ID Application signing identity}"
    : "${MPS_DEVELOPMENT_TEAM:?Set your signing team identifier}"
    if [[ -e "$archive_path" ]]; then
      printf '%s\n' "Archive already exists: $archive_path; preserve or move it before rebuilding." >&2
      exit 1
    fi
    mkdir -p "$release_dir"
    # Published debug symbols use a stable source root instead of the maintainer's home directory.
    swift_flags="\$(inherited) -debug-prefix-map \"$PWD=/MacPowerScheduler\""
    xcodebuild -workspace MacPowerScheduler.xcworkspace -scheme MacPowerScheduler \
      -configuration Release -destination 'generic/platform=macOS' \
      -archivePath "$archive_path" -derivedDataPath "$release_dir/DerivedData" \
      ARCHS="$architectures" ONLY_ACTIVE_ARCH=NO \
      OTHER_SWIFT_FLAGS="$swift_flags" SWIFT_SERIALIZE_DEBUGGING_OPTIONS=NO \
      CODE_SIGN_IDENTITY="$MPS_SIGNING_IDENTITY" DEVELOPMENT_TEAM="$MPS_DEVELOPMENT_TEAM" archive
    bash Tools/release.sh verify "$variant"
    ;;
  verify)
    python3 Tools/verify_bundle.py "$release_app" --variant "$variant"
    python3 Tools/verify_release_identity.py "$release_app"
    ;;
  notarize)
    : "${MPS_NOTARY_PROFILE:?Set an existing approved notarytool Keychain profile}"
    bash Tools/release.sh verify "$variant"
    ditto -c -k --keepParent "$release_app" "$release_dir/submission.zip"
    xcrun notarytool submit "$release_dir/submission.zip" \
      --keychain-profile "$MPS_NOTARY_PROFILE" --wait --output-format json > "$release_dir/notarization.json"
    python3 -c 'import json, sys; sys.exit(0 if json.load(open(sys.argv[1]))["status"] == "Accepted" else "Notarization was not accepted")' "$release_dir/notarization.json"
    xcrun stapler staple "$release_app"
    bash Tools/release.sh package "$variant"
    ;;
  package)
    # An Xcode Organizer export can be supplied instead of the original archive app.
    python3 Tools/package_release.py "${3:-$release_app}" \
      --archive "$archive_path" --variant "$variant" --output .build/Release/dist
    ;;
  *) printf '%s\n' 'Usage: bash Tools/release.sh archive|verify|notarize|package [universal|arm64] [exported-app-for-package]' >&2; exit 2 ;;
esac
