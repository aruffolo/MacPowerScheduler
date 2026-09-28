# Active phase runbook

## Runbook control

- Contract: `R2` from [plan.md](plan.md), implementation authorized 2026-09-27.
- Active phase/task: `P7`, evidence reconciliation. Implementation and automated checks are complete; detailed binary-release proof remains partial.
- Current source, counts, maintainer testing and remaining evidence: [progress.md — Resume Here](progress.md#resume-here). Keep that summary authoritative rather than duplicating it here.
- Updated: 2026-09-28.

## Canonical references

Requirements: [prompt.md](prompt.md). Contracts, validations and guardrails: [plan.md](plan.md). Decisions: [documentation.md](documentation.md). Boundaries: [architecture overview](../../architecture/overview.md). Current presentation: [Quiet Agenda decisions](../quiet-agenda-ui/documentation.md). Evidence: [progress.md](progress.md).

## Current execution sequence

The draft-preservation fix, Quiet Agenda/Deep Sapphire UI, Settings alignment, README and contributor guidance are committed. The maintainer reports successful functional testing on this Mac. Snapshot replacement and palette implementation are finished, not active tasks.

For a future authorized binary-release task:

1. Reconcile existing maintainer results with the named signed-helper, account-authorization, lifecycle and physical-power matrices. Record the actual tested build and scope; collect missing cases without treating a broad success report as either no testing or proof of every case.
2. Complete the specific remaining UI evidence in the [Quiet Agenda runbook](../quiet-agenda-ui/implement.md), including attended VoiceOver speech and Escape dismissal. Keep deterministic snapshots separate from interaction and hardware proof.
3. Build and validate a current signed/notarized candidate using the [release procedure](../../release/README.md). The earlier successful notarized artifact predates the UI changes. Re-run required source gates for changed code and bind release evidence to the actual candidate.
4. Retain review fixes and strict failure reporting. Re-review any security changes; never weaken peer checks to make an unsigned build privileged.

## Dependencies and recovery

Live helper, account and power checks require the approved setup and applicable authorization. Follow the [testing guide](../../testing/README.md) and [power-cycle protocol](../../testing/power-cycle.md). Preserve external schedule edits; never restore a stale snapshot. Any new disruptive check must stay within the explicitly approved setup and scope.

## Before stopping

Update progress with actual outcomes, evidence gaps and a concrete next action. Preserve historical receipts and distinguish maintainer reports from agent-executed checks. The maintainer authorized a local commit of this documentation reconciliation; push, publication and live system operations remain outside this task.
