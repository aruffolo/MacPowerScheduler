# Continuous integration

[CI workflow](../../.github/workflows/ci.yml) runs on pull requests targeting `main`, pushes to `main`, and manual dispatch. The stable job name is `macOS validation`. It uses GitHub's Intel macOS 15 runner and explicitly selects Xcode 26.3. SwiftLint 0.65.1 and SwiftFormat 0.63.0 are downloaded from versioned upstream releases and checked against SHA-256 digests.

The job runs `make check`, `make test-strict`, and `make build-universal`. Shell pipeline failures propagate through log capture. Tests use the default ad-hoc build configuration; no signing secrets, helper registration, live mutation, or notarization is needed. A tracked-file diff check catches accidental reference recording or other changes made by validation.

Logs, coverage summaries and failed snapshot images are retained for seven days. Uploads use explicit paths; credentials, local configuration, whole build directories and release bundles are not collected. Actions are pinned to commit revisions, the token is read-only, and checkout credentials are not persisted. Public PR execution belongs on disposable hosted runners, not a maintainer's personal Mac.

## Snapshot environment

The current reviewed references were recorded on Intel macOS 15.7.4 with Xcode 26.3. GitHub updates the OS behind `macos-15-intel`; selecting that label does not pin an exact OS patch or runner image. CI logs the actual OS/toolchain/image, and uses unchanged references with recording disabled.

The [first hosted run](https://github.com/aruffolo/MacPowerScheduler/actions/runs/36434752282) passed all three Make gates at `9385c35` on Intel macOS 15.7.9, Xcode 26.3 / Swift 6.2.4, image `20260824.0482.1`. All 50 snapshot cases matched the unchanged references, and scoped coverage was 97.80%. The artifact action was subsequently updated to v7.0.1 to use its supported Node 24 runtime; see [workflow runs](https://github.com/aruffolo/MacPowerScheduler/actions/workflows/ci.yml) for results at each later revision.

An environment mismatch remains a failed check. Inspect failure images before proposing an explicitly reviewed baseline migration; never automatically record references or relax comparison tolerance. A hosted CI pass does not prove physical startup, helper authorization or accessibility behavior. See the [validation procedures](README.md).

## Protection for main

The active `Protect main` ruleset (ID 24172205) applies to `main`:

- Require a pull request, with zero required approving reviews while the project has one maintainer. Contributors still need a maintainer to merge; this avoids requiring a second person to approve the maintainer's own PRs.
- Require `macOS validation` from GitHub Actions and require the branch to be up to date before merging.
- Require review conversations to be resolved.
- Block force pushes and branch deletion, with no routine bypass actors.

The required check was verified against successful hosted runs before enabling protection. Additional approval requirements can be added when another active maintainer is available. These rules apply to maintainers too: use a pull request for subsequent changes to `main`.

The maintainer authorized making `aruffolo/MacPowerScheduler` public on 2026-09-29. GitHub then accepted the ruleset; readback confirmed active enforcement, no bypass actors, and `main` marked protected. The required check is `macOS validation`, from the `github-actions` app (ID 15368). Private-repository plan restrictions previously blocked this setup; that limitation no longer applies to the public repository.
