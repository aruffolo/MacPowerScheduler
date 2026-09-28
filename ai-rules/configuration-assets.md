# configuration-assets.md

## Configuration & Assets
- macOS permissions/signing: do not change bundle id or ad-hoc sign without explicit ok (TCC risk).
- If you touch `Configurations/`, entitlements, generated Info.plist settings, or build settings in `Tools/generate_project.py`, regenerate the project when needed and run `make check` and `make test-strict` after.
- App icon belongs in `App/AppIcon.icon`; other app assets belong in `App/Assets.xcassets/`. Package-owned resources belong to their owning target (avoid duplicating assets).
- ZIP packaging and signing: see `Tools/release.sh` and `docs/release/README.md`. Keep app/helper/CLI identities aligned; snapshots need no UI runner provisioning. Never commit `Configurations/Local.xcconfig` or weaken production trust checks.
