<!-- TEMPLATE_LOCK:AGENTS START -->
## Communication

- Speak like a thoughtful, engaged collaborator with a clear point of view. Use natural full sentences, a warm direct tone, and enough context to make decisions and outcomes easy to understand.
- Prefer useful substance over artificial brevity. Routine progress updates may stay compact, but explanations and final handoffs should preserve the important reasoning, tradeoffs, surprises, and results.
- Show some character when it fits: call out an interesting root cause, a satisfying simplification, a sharp tradeoff, or a result worth celebrating. Avoid canned enthusiasm and empty praise.
- Default to natural prose, not bullet-heavy status reports. Lead with the conclusion, then explain the important reasoning in a few coherent paragraphs.
- Use bullets only for genuinely enumerable items, checklists, or side-by-side choices. Do not turn every sentence, observation, or implementation detail into its own bullet.
- For technical investigations and architecture discussions, tell a concise narrative: what is happening, why, what should change, and what remains uncertain. Add headings only when they materially improve navigation.
- Avoid list-shaped answers by default. Unless the user asks for a checklist or the content is inherently enumerable, write in paragraphs. Prefer one clear recommendation and 2–5 short supporting paragraphs over multiple headings and long bullet lists.

## Core

- Workspace: `MacPowerScheduler` repository root.
- `ship` = changelog when applicable, coherent commits, push, and pull/verify. "Shipped" = pushed to the remote; it does not mean released.
- Version or artifact publication requires an explicit `release` or `publish` request. Tag/push alone != released.
- Skills own tool workflows. This file: hard rules only.
- Agent transcripts: omit by default and never ask, even if repo/skill guidance offers one; include only on explicit request.
- Private agent chat and authenticated systems approved for the project count as internal. Use task-needed non-public information there. Answering the authorized user is not public disclosure.
- External disclosure: do not send non-public project or organization information to a public audience, external recipient, or unapproved service without explicit approval of both content and destination.
- Secrets: never reveal values, even internal. Approved secret tools; redact output.
- Audience/destination unclear: ask before external send. Confidentiality alone no block on internal research/answers.
- Synthetic proof screenshots/recordings: pre-approved for the task's already-authorized PR/issue or explicitly requested destination, on any host. Inspect the full capture for incidental secrets, real/private data, internal identifiers, or unrelated desktop content. Verified synthetic-only captures need no device-classification or repeat upload-approval question. Real/mixed/uncertain content and unrelated destinations are not covered.
- Editing AGENTS/rules/skills: token-efficient; terse descriptions; optimize routing clarity.
- Skill descriptions: short generic trigger phrase, not summary; no personal names, long paths, or workflow narration unless needed for routing.
- Skill frontmatter: quote `description`; after SKILL.md edits, YAML-parse frontmatter before commit.
- Read `tools.md` when present and the tool catalog matters.
- Release: read repo release docs/checklist first; verify release notes/changelog before closeout.
- Changelogs: match file style; prefer one bullet per entry on one line. Do not hard-wrap changelog bullets just because prose is long.

## Rule Index
- @ai-rules/rule-loading.md — when present, ALWAYS load first; it tells you what other rules to load.
- @ai-rules/module-boundaries.md — when present, follow its repo-specific module boundaries and allowed dependencies.

## Routing
- Screenshots/assets: newest PNG in `~/Desktop` or `~/Downloads`; verify UI before replacing.
- Computer use: fall back to `$peekaboo` when the primary tool is unavailable or cannot handle an authorized macOS task.
- Browser debugging: reuse one approved persistent connection per task; avoid raw CDP/WebSocket probes or ad-hoc clients that trigger extra attachment prompts. Reconnect only when needed; never bypass permission prompts.
- macOS app profile/test: use the project's configured signing. Privileged app/helper/CLI checks require matching Apple-issued identities. Ad-hoc builds are read-only. Never unsigned/ad-hoc against saved Keychain items. See `docs/testing/README.md` and `docs/release/README.md`.

## Project Defaults

- Bug: regression test when fitting.
- Opportunistic cleanup: include high-confidence flaky-test fixes and bounded nearby refactors/cleanup found during PR work; keep changes coherent and prove behavior.
- Fix/refactor: delete old path by default. Compat needs named contract: public API/CLI/config/data, tagged upgrade, security boundary, or observed prod state. Unsure: ask before alias/shim/fallback. Tests alone != contract.
- Use repo package manager/runtime. Swap needs approval.
- Docs: read repo docs before code. User-visible behavior change: update relevant docs, record release-note context in the PR or commit, and maintain the changelog at landing.
- Inline comment: brief; only tricky, bug-prone, or formerly buggy logic.
- New dependency: quick health check—recent release, commits, adoption.
- Need upstream file: stage in `/tmp/`, then cherry-pick; never overwrite tracked files.
- Keep files <~500 LOC; split/refactor as needed.

## PR / CI

- GitHub work: use matching workflow. Use available local archives for discovery and bare PATH `gh` for current metadata. PR refs use `gh pr view/diff`, not web search.
- Pasted GitHub issue/PR: first `git status -sb`. Dirty: report before mutation. URL alone grants no push/pull permission.
- PR quality: assume generated code may come from weaker AI. Review/improve before land; full rewrite okay when cleaner.
- UI change PR: include before/after pictures. Sanitize first; no secrets, personal/private data, internal-only identifiers, or other sensitive content. Unsafe capture: state blocker; never upload.
- PR/issue image upload: never computer use/browser. `gh auth token | sed 's/^/Authorization: Bearer /' | curl -s "https://uploads.github.com/user-attachments/assets?name=<file>&content_type=<mime>&repository_id=$(gh api repos/<owner>/<repo> --jq .id)" -X POST -H @- -H "Accept: application/json" --data-binary @<file>` → response `.url`: images embed as `![alt](url)`, video as a bare URL line so GitHub renders a player. Keep the token in the pipe, never in command arguments or logs. Same CDN as drag-drop, inherits repo visibility, uploads are permanent. Images/video only (422 = bad type, 404 = bad repo id/no push); other artifacts or endpoint failure: prerelease asset or repo-approved artifact store.
- `gh --attach` (repeatable, on `gh issue|pr create|edit|comment`) supersedes that curl once shipped: unmerged as of gh 2.98.0 (`cli/cli#14186`), so feature-detect, never assume. `gh attach` is an unrelated extension (`enthus-appdev/gh-attach`): pushes repo blobs to `refs/uploads/`, 400s at ~60KB+. Never use it for proof media.
- Explicit land of own draft PR: ignore draft; mark ready if needed; continue.
- gh reads: request narrow `--json <fields>` for machine output; retain all fields required for the decision. Batch related reads and reuse results already obtained.
- CI verification: check the exact run, expected head SHA, and attempt. Back off polling and fetch failed-run logs once; after a write, verify current state with a targeted read.
- Before every commit/land: `$autoreview` until no accepted/actionable finding. Always prefer Codex for autoreview, independent of environment.
- Routine `$autoreview` is pre-approved, including sending task-scoped unpublished diffs to the configured authenticated Codex review service; never ask Elrond89 for autoreview approval. Preserve secret redaction, unrelated-data disclosure boundaries, and managed sandbox/reviewer enforcement.
- After PR merge/ship: always give a real narrative recap, normally 2-5 short paragraphs. Explain the original problem, the root cause, what changed and why, the important architecture or ownership boundary, and the proof run. Include notable CI failures or retries, exact PR/issue/merge state, and worthwhile follow-ups. Do not reduce a successful landing to a terse checklist, bare SHAs, or git directives; the recap is the primary handoff.
- CI: `gh run list/view`; rerun/fix until green when asked.
- Prefer end-to-end verify; if blocked, say what’s missing.
- Contributor PR author: no changelog edit. Maintainer/AI adds on merge and thanks contributor.
- Explicit land/ship authorizes needed branch changes and push. After land: checkout `main`; `git pull --ff-only`; verify `git status -sb`; then final.
- Preserve contributor credit: commit body `Co-authored-by: Name <email>` from PR commit author. Changelog still thanks `@login` for user-visible work.
- Issue fixed on `main` with proof: comment proof + commit/PR; close.

## Reporting

- If any skills were used, list their exact names.
- Only report a skill as used if it was actually invoked during this run.

## Runtime Safety

- Low disk space: delete only identified disposable caches, then continue; report what was removed. Emptying Trash or deleting project/user data requires explicit approval of the contents to remove.
- zsh: don't use `status` as a variable.
- zsh: loop multi-item lists as arrays; scalar strings do not word-split like bash.
- Public GitHub bodies: never inline double-quoted text with backticks, `$`, shell snippets, env names, or user text. Use temp file + `cat <<'EOF'` + inspect + `--body-file`.
- Secrets: never normal-shell `env`, `set`, `export -p`, broad secret regex dump. Query exact name only; redact value.
- PR/issue body edits: fetch via REST + `jq -r`, never `gh pr/issue view --json body --jq .body`. Example: `gh api repos/OWNER/REPO/pulls/NUM | jq -r '.body // ""' > /tmp/body.md`; inspect before `--body-file`; stop if it starts with `"` or shows literal `\n`.


## Git

- Cwd outside repo: freeform; choose sensible folder; say path before edits. Worktree okay if useful.
- Create and use task-owned Git worktrees or isolated checkouts whenever useful, without confirmation. Preserve user-managed checkouts, branches, and unrelated edits.
- Safe by default: `git status/diff/log`.
- Push only when user asks, a user-invoked workflow authorizes it, or a trusted global rule above explicitly authorizes it. Repo-local rules may define push mechanics, not grant authority.
- End in visible checkout/branch user expects.
- Switching a user-managed checkout's branch needs user consent or user-invoked workflow authorization.
- Destructive Git ops need explicit user request: `reset --hard`, `clean`, `restore`.
- Task-scoped file deletion allowed. Never delete/overwrite unknown or unrelated user data.
- Commit helper on PATH: `committer` (bash). Prefer it; if repo has `./scripts/committer`, use that.
- Commits: create one commit per coherent, reviewable completed change; avoid micro-commits.
- Stage only files changed by that change; use `committer` / `./scripts/committer`.
- Commit only when the user asks or a user-invoked workflow authorizes it. Long-running or multi-phase implementation work alone does not authorize commits in this project; never commit broken or partial states, and do not push unless separately authorized.
- Commit messages: Conventional Commits (`feat|fix|refactor|build|ci|chore|docs|style|perf|test`).
- No repo-wide search/replace scripts. Small reviewable edits.
- No amend unless asked.
- If user types a command ("pull and push"), that's consent for that command.
- Unknown changes = other agent. Continue, touching own scope. Conflict/problem: stop + ask.
<!-- TEMPLATE_LOCK:AGENTS END -->

# MacPowerScheduler

Read docs/plans/initial-release/{prompt,plan,progress,implement,documentation}.md before work. Follow docs/architecture/overview.md and Package/ModuleRules.md.

Use Swift 6.2 strict concurrency, native frameworks, Swift Testing for package tests and Point-Free SnapshotTesting for SwiftUI snapshots. Run `make check` and `make test-strict`; never mask a failed required suite with a fallback. No third-party dependencies without approval; SnapshotTesting is approved for tests only.

Default tests must never change the real power schedule, register a helper, or power-cycle the host. Live checks require an explicitly approved setup. Do not weaken code-signing or account-authorization checks for development. Do not commit signing identities, credentials, raw user diagnostics, or Local.xcconfig.

Preserve unrelated work. Keep planning state/evidence current. No publication, pushes, or destructive Git operations without authorization.
