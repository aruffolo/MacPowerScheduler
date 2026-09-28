# Active phase runbook

## Runbook control

- Targets `R2` from [plan.md](plan.md), implementation authorized 2026-09-27.
- Derived active phase/task: `P3` / `VAL-GUI`, replace UI automation with fixed-fixture snapshots under the user-approved R2 contract; P0 signed-helper integration remains open.
- Earlier phase signed runtime gates remain open; see [progress.md](progress.md).
- Updated: 2026-09-28.

## Canonical references

Requirements: [prompt.md](prompt.md). Contracts, validations and guardrails: [plan.md](plan.md). Decisions: [documentation.md](documentation.md). Boundaries: [architecture overview](../../architecture/overview.md). Evidence and blockers: [progress.md](progress.md).

## Current execution sequence

Current request: the maintainer reports successful testing on this Mac and has selected open PR submissions without a prerequisite issue. README and CONTRIBUTING.md are prepared for the explicitly authorized local documentation commit; the 2026-09-28 progress receipt records the documentation checks. The earlier validation sequence below retains its detailed evidence requirements; the maintainer's high-level report does not supply a new artifact hash or itemized matrix.

1. R2 snapshot replacement is complete: twenty reviewed light/dark images pass; `make check` and `make test-strict` passed. The subsequent draft-preservation fix passed TDD red/green verification and both full gates with 98 unit tests and 97.74% scoped coverage; snapshots remain excluded from its numerator. Negative checks proved missing/mismatched references fail without recording. Review fixed inherited recording mode and stale runner guidance; the strict suite includes 22 tooling tests. See the R2 and draft-preservation receipts in progress for logs and counts.
   The next work is the approved isolated installed-helper setup. Packaged launch, foreground refresh, keyboard/VoiceOver, text sizing and confirmation/cancellation remain manual release checks. Earlier off-console runner failures are historical R1 evidence, superseded by the user's explicit R2 gate replacement.
2. Signing and Apple notarization passed. The exported candidate passed component verification, ticket validation, Gatekeeper assessment and read-only CLI checks; its ZIP and hash are recorded in progress. No credentials go in chat or tracked files.
3. Preserve closed review findings and tests; re-review security changes made during signed integration. Keep checks strict; failed/blocked checks stay visible.
4. Run the signed-helper spike and negative/positive integration protocol once the isolated test setup is approved. Never weaken peer checks to make an unsigned build privileged.
5. Execute clean-install/lifecycle and attended physical power protocols only when their actual environment and approvals are available. Never treat elapsed time as approval.

## Dependencies and recovery

The approved Developer ID identity is installed and local signing succeeded after Keychain approval. Apple accepted the candidate; the exported app has a valid stapled ticket and Gatekeeper reports Notarized Developer ID. Current R2 source passed snapshot/check/strict validation. Installed XPC/runtime validation, manual packaged-app/accessibility checks and attended physical checks remain open. No helper or live power schedule has been changed. The real cold-start/shutdown protocol remains in [power-cycle.md](../../testing/power-cycle.md). Preserve external schedule edits; do not restore stale snapshots.

## Before stopping

Update progress with actual outcomes, pending gates and a concrete next action; keep the active task and revision synchronized. Do not claim final completion, publish, or commit without the applicable authorization.
