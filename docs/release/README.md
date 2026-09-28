# Release procedure

Release readiness requires the plan's signed-helper, physical, review, and final gates. Current evidence belongs to [progress](../plans/initial-release/progress.md); this procedure is not a completed release receipt. A pre-release must state its remaining validation limits explicitly.

## Variants and artifacts

The release tools support `universal` (arm64 + x86_64, the default) and `arm64` (Apple Silicon only). The app, bundled CLI, helper and Mach-O libraries must all have the exact selected architecture set. Compiling arm64 on an Intel Mac does not establish execution on Apple Silicon.

Each variant uses an independent archive under `.build/Release/<variant>/MacPowerScheduler.xcarchive`. Existing archives are preserved: move a previous archive to a retained location before rebuilding. Final artifacts go to `.build/Release/dist/<version>/`:

- `MacPowerScheduler-macos-universal-<version>.zip`
- `MacPowerScheduler-macos-arm64-<version>.zip`
- Matching `.dSYM.zip` archives for crash debugging.
- `SHA256SUMS`, with portable filenames for the produced ZIPs.

Versioned ZIPs, separate debug symbols, notarization and verification of downloaded/extracted assets follow the useful parts of [CodexBar's release approach](https://github.com/steipete/CodexBar/blob/v0.68.0/docs/RELEASING.md). This project does not use Sparkle or publish a standalone CLI: the CLI remains bundled with its matching app/helper.

## Build, notarize and package

1. Run `make check`, `make test-strict`, and `make build-universal`. Inspect failures, warnings, source changes, docs, compatibility claims, license and release notes. Do not use an ad-hoc build as a privileged distribution.
2. Select existing approved credentials privately: `MPS_SIGNING_IDENTITY` (Developer ID Application), `MPS_DEVELOPMENT_TEAM`, and, when using the command-line notary route, `MPS_NOTARY_PROFILE` (an existing notarytool Keychain profile). Never commit credentials or put identity data in public logs. The tools do not create credentials or change an account.
3. Build both archives:

   ```sh
   make archive RELEASE_VARIANT=universal
   make archive RELEASE_VARIANT=arm64
   ```

   The archive command verifies exact architectures, macOS 14 deployment, signatures, matching Developer ID team/identifiers, hardened runtime and restricted entitlements. Debug symbols use a stable source root; packaged relocation metadata uses portable binary paths and all symbol files are checked for local home paths. `make verify-release RELEASE_VARIANT=arm64` repeats verification without rebuilding.
4. With an existing approved Keychain profile, run `make notarize RELEASE_VARIANT=universal` and `make notarize RELEASE_VARIANT=arm64`. Each command submits that variant to Apple, requires Accepted, staples the ticket, and packages it. Alternatively use the Xcode account workflow below.
5. Packaging requires ticket validation and Gatekeeper acceptance, compares every executable's UUIDs with its archive's dSYM, then creates and extracts the ZIP and re-verifies its app. Neither a submission receipt nor compilation alone can produce a verified release ZIP. Existing final ZIPs are never silently overwritten.
6. Exercise a clean test installation from the actual candidate. Check packaged launch, foreground refresh, keyboard/VoiceOver, text sizing and confirmation/cancellation; snapshots do not exercise these interactions. Follow the approved attended helper/account/lifecycle and physical protocols. Reconcile recorded maintainer results with each required case, and state untested platforms accurately.
7. Record source checkpoint, artifact hashes, environments/results and remaining limits. Verify release notes/changelog, create the intended GitHub release status, upload both app ZIPs, matching symbols and checksums, then download and verify the uploaded assets. Repository visibility is a separate decision from creating a release.

For updates, revoke/unregister the running helper before replacing the app, then register the new embedded daemon. If the old app is unavailable or macOS approval is stuck, restore the matching signed app and inspect ServiceManagement state; do not bypass identity checks or install arbitrary legacy LaunchDaemon files. Removing the helper through the app revokes grants; it leaves schedules intact by design.

## Xcode account workflow

A command-line notarytool credential profile is optional. With the approved Apple Developer account signed into Xcode, open each signed archive in Organizer, select **Distribute App → Direct Distribution**, and submit for notarization. This sends the app to Apple; it does not publish an App Store release. Wait for acceptance, then use **Export Notarized App** into that variant's ignored release directory.

After acceptance, `xcodebuild -exportNotarizedApp -archivePath <accepted-organizer-archive> -exportPath <variant-export-directory>` can also export the result. Select the archive managed by Organizer that contains the accepted submission; an original archive copy without submission metadata cannot be exported with this command.

Package the exported apps against their corresponding original archives:

```sh
bash Tools/release.sh package universal .build/Release/universal/Notarized/MacPowerScheduler.app
bash Tools/release.sh package arm64 .build/Release/arm64/Notarized/MacPowerScheduler.app
```

`make package-release RELEASE_VARIANT=arm64` instead packages the app inside that variant's archive, when it already has a valid stapled ticket. Every packaging path uses the same signature, architecture, symbol, ticket and extracted-ZIP checks. Keep submission identifiers, UI captures and raw distribution logs under ignored `.build/`; retain only sanitized outcomes in progress.
