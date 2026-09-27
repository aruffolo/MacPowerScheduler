# Release procedure

Release readiness requires the plan's signed-helper, physical, review, and final gates. Current evidence belongs to [progress](../plans/initial-release/progress.md); this procedure is not a completed release receipt.

1. Run `make check`, `make test-strict`, and `make build-universal`. Inspect failures, warnings, full source change, docs, compatibility claims, and license. Do not use an ad-hoc build as a privileged distribution.
2. Select existing approved credentials privately: `MPS_SIGNING_IDENTITY` (Developer ID Application), `MPS_DEVELOPMENT_TEAM`, and `MPS_NOTARY_PROFILE` (an existing notarytool Keychain profile). Never commit/export passwords or identity data into public logs. The tools do not create credentials or change an account.
3. `make archive` creates `.build/Release/MacPowerScheduler.xcarchive`, then verifies every executable, daemon embedding, both architectures, minimum OS, matching Developer ID team/identifiers, hardened runtime, and restricted entitlements.
4. `make notarize` verifies again, uploads the archive's ZIP to Apple's notarization service using the selected profile, requires an Accepted result, staples/validates the ticket, assesses Gatekeeper, and creates `.build/Release/MacPowerScheduler.zip` plus `SHA256SUMS`. This is an explicit external submission step; do not run it without approved credential use.
5. Exercise a clean test installation from this candidate. Manually verify packaged-app launch, foreground refresh, keyboard/VoiceOver, text sizing and confirmation/cancellation; snapshots do not exercise these interactions. Put it in `/Applications`; validate service denial/approval, app-closed CLI, account grants/revocation, upgrade, removal, residual schedule disclosure, and source-build instructions using the approved attended setup. Follow the physical test procedure. Reconcile all criteria and qualified untested platforms.
6. Record artifact hash, source checkpoint, actual test environments/results, residual limits, review/simplification evidence, and completion receipt. Keep the artifact for handoff. Publishing a repository, uploading a release, or pushing tags is a separate user action/authorization.

For updates, revoke/unregister the running helper before replacing the app, then register the new embedded daemon. If the old app is unavailable or macOS approval is stuck, restore the matching signed app and inspect ServiceManagement state; do not bypass identity checks or install arbitrary legacy LaunchDaemon files. Removing the helper through the app revokes grants; it leaves schedules intact by design.

## Xcode account workflow

A command-line notarytool credential profile is optional. With the approved Apple Developer account signed into Xcode, open the signed archive in Organizer, select **Distribute App → Direct Distribution**, and submit for notarization. This sends the app to the Apple notary service; it does not publish an App Store release. Wait for acceptance, then use **Export Notarized App** to save the candidate under `.build/Release/`.

Verify the exported app with `Tools/verify_bundle.py` and `Tools/verify_release_identity.py`, then require `xcrun stapler validate` and `spctl --assess --type execute` to pass. Package and hash that verified exported app, since it is the final distribution artifact. Keep submission identifiers, UI captures and raw distribution logs under ignored `.build/`; record only sanitized outcomes in progress. Do not interpret an upload confirmation or Processing status as acceptance.

Alternatively, after acceptance, use `xcodebuild -exportNotarizedApp -archivePath <accepted-organizer-archive> -exportPath .build/Release/Notarized`. Select the archive managed by Organizer that contains the accepted submission; an original archive copy without that submission metadata cannot be exported with this command. Apply the same verification and packaging checks to the exported app.
