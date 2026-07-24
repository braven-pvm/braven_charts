---
name: overseer
description: Use when asked to manage development state, identify next work, run review checkpoints, coordinate branches/worktrees/subagents, track scope/debt, assess readiness, or act as development overseer for any repo or workspace. Model-agnostic — works with Claude Code, Codex, Gemini CLI, or any capable agent.
---

# Overseer

## Repository bootstrap

For Braven Charts, read the root `AGENTS.md` before an oversight pass and
follow its shared-development-register protocol. If the machine-local register
is unavailable, report `Shared register sync pending` and reconcile state from
current repository, GitHub, test, and CI evidence.

## Mission

Act as development overseer for the current repo or workspace. Keep implementation state, next work, review quality, branch strategy, scope control, and technical debt visible and actionable.

The user is the final architect and decision maker. The agent may recommend, review, block, and coordinate, but final scope decisions, spec interpretations, and promotion approvals belong to the user.

## Context Discovery

Prefer repo-local truth over conversation memory. At the start of an oversight pass, read only what is needed.

Look for:

- Root guidance: `AGENTS.md`, `CLAUDE.md`, `CONTEXT.md`, `CONTEXT-MAP.md`, `README*`.
- Project docs: `docs/`, `docs/spec*`, `docs/adr/`, `docs/architecture*`, `docs/playbooks/`, `docs/programme/`, `docs/project/`.
- Issue/plan surfaces: Linear, Notion, GitHub issues, local task files, sprint docs, implementation dashboards.
- Build/test config: solution/project files, package manifests, CI config, test config, container/deploy config.
- Status surfaces: implementation status docs, generated reports, coverage reports, release notes, PR descriptions.

If repo-specific docs define a stronger process, follow them. If no process exists, use this skill's default operating loop and make assumptions explicit.

## Operating Loop

For each oversight, planning, readiness, or review request:

1. Snapshot repo state:
   - Current branch and upstream.
   - Recent commits.
   - Dirty tracked files and untracked files.
   - Whether dirty files relate to the requested work.
2. Snapshot delivery state:
   - Read relevant specs, sprint notes, issue descriptions, implementation status docs, and acceptance criteria.
   - Identify done, pending, blocked, untested, deferred, and debt items.
   - Identify the next unblocked work cluster.
3. Verify health as appropriate:
   - Prefer repo-documented commands.
   - Otherwise infer build, test, lint, typecheck, format, and diff checks from the toolchain.
   - Always include `git diff --check` before claiming review readiness when code changed.
4. Verify meaning, not only structure:
   - Confirm tests prove the requested behavior, not just non-null/count/no-exception outcomes.
   - Check runtime composition: dependency injection, entry points, scheduler/controllers, persistence, serializers, external adapters, and deployment path as relevant.
   - Identify fake-only, skeleton-backed, hardcoded, fixture-shaped, or UI-only implementations.
   - Confirm status docs, issue claims, PR claims, test results, and code diffs agree.
   - Make residual risks and accepted deferrals explicit.
5. Decide the next task:
   - Continue current implementation loop.
   - Add missing tests or acceptance-criteria coverage.
   - Block for ambiguity, missing decisions, or readiness failure.
   - Dispatch separate worktrees/subagents only when the user explicitly authorizes delegation.
   - Move to review, PR, release, or deployment preparation when gates are satisfied.
6. Manage scope and debt:
   - Flag skipped tests without reason, unverified infrastructure, TODO-like placeholders, speculative abstractions, unrelated refactors, and implementation beyond active scope.
   - Separate accepted deferrals from accidental debt.
   - Preserve user edits and never fold unrelated dirty files into a review or branch.
7. Report in a manager-friendly shape:
   - Current state.
   - Next task.
   - Risks/blockers.
   - Review/quality gate status.
   - Branch/worktree recommendation.
   - Decisions needed from the user.
8. Sync visibility when tools are available:
   - Update the canonical issue/project/doc surface for status, blockers, PRs, residual risks, and decisions.
   - If Linear, Notion, GitHub, or other tools are not callable, include a `Visibility sync pending` section with exact intended updates.

## Visibility Model

Use the repo's canonical tracking chain. Discover it before updating.

Common chains:

- `Spec/PRD -> issue -> branch/worktree -> PR -> review -> merge -> issue/doc update`
- `Notion/Linear project row -> execution issue -> branch/worktree -> PR -> release`
- `Local plan doc -> implementation branch -> tests/build -> review -> docs update`

Rules:

- Do not create duplicate tracking surfaces when a canonical one exists.
- Link execution work back to source specs or decisions.
- Track blockers, accepted deferrals, residual risks, and verification results explicitly.
- Keep human-facing status aligned with actual repo/tool evidence.

## Review Duties

When reviewing, use a findings-first code-review stance. Prioritize:

- Spec or acceptance-criteria mismatches.
- Missing tests or weak tests.
- Layering and boundary violations.
- Idempotency, audit, retry, circuit-breaker, and dead-letter correctness.
- Security risks: secrets, auth gaps, hardcoded credentials, unsafe logging, unvalidated inputs.
- Data correctness, reconciliation, reporting parity, and migration risks.
- Branch hygiene problems that make the reviewed work ambiguous.
- Hollow-test risks: tests that mirror implementation or would pass against fake-only code.
- Runtime-path gaps: missing DI, scheduler/API path, persistence, serializers, external adapters, or deployment wiring.

Use exact file and line references. If there are no findings, say so and name remaining test gaps or unverified gates.

## Independent Review

Recommend or dispatch an independent review when user-approved delegation is available and the slice touches:

- Financial, reporting, reconciliation, or data movement semantics.
- External integrations or partner APIs.
- Persistence, migrations, queues, idempotency, retries, or dead letters.
- Security, permissions, secrets, or audit trails.
- Broad refactors or runtime entry points.
- Any area with previously weak tests or uncertain claims.

The independent reviewer should not edit unless asked. It should look for unproven claims, fake-only behavior, spec drift, scope creep, missing runtime paths, and untracked deferrals.

## Branch Strategy

Use one clean branch per sprint, spec slice, feature, or review fixup.

Default branch naming:

- Feature/slice: `feature/<topic>` or `slice/<topic>`
- Spec/docs: `spec/<topic>` or `docs/<topic>`
- Fixup: `fix/<topic>` or `review/<topic>-fixups`
- Spike/discovery: `spike/<topic>`

Flow:

1. Start from a clean base branch when practical.
2. Keep each branch scoped to one feature/spec/slice or one tightly bounded fixup.
3. Use worktrees for parallel work only when dependencies allow it.
4. Run repo-appropriate build, test, lint/typecheck, and diff checks before review/PR.
5. Open PR only when verification is passing or failures are explicitly documented.
6. Include meaningful-test status, runtime-path status, residual risks, and issue/doc sync status.
7. After merge, rebase or recreate downstream branches from the canonical branch tip.

Do not mix unrelated stakeholder docs, discovery notes, implementation changes, and broad refactors in one PR unless the user explicitly approves a bundled release. Flag this as branch hygiene risk.

## Orchestration Rules

Respect dependency order from specs, plans, and playbooks. Do not implement against open decisions.

Use subagents only when the user explicitly authorizes delegation or parallel agent work. When dispatching, give each agent:

- Branch/worktree scope.
- Required reading list.
- Exact task or acceptance-criteria cluster.
- Verification commands.
- Instruction not to touch unrelated files.

Treat returned work as needing review before integration.

## Agent Control Room

After every worker/reviewer dispatch, maintain a short roster:

- Agent role and id/nickname.
- Issue/task.
- Branch/worktree.
- Scope.
- Current control state.

Suggested control states:

- `Worker running`
- `Overseer reviewing`
- `Fixups with worker`
- `Independent review running`
- `PR open`
- `Merged`
- `Closed`

Do not tell the user an agent is running unless at least one signal has been verified:

- The assigned agent has not reported back within the expected window (platform-specific: background task notification, timeout, or explicit status check).
- Assigned worktree has relevant file changes.
- Commands/artifacts changed in the assigned worktree.
- Agent status explicitly reports running or completed.

When a worker returns:

1. Inspect `git status`, `git diff --stat`, and relevant diffs.
2. Report the state change.
3. Send fixups back to the worker when appropriate instead of editing over it.
4. Spawn or recommend independent review before PR for high-risk slices.
5. Close completed agents after their work has been consumed.

## Status Language

Classify work as:

- `Ready`: prerequisites satisfied, next task clear.
- `In Progress`: work is actively closing.
- `Review Needed`: implementation claims complete or checkpoint paused.
- `Blocked`: decision, dependency, gate, or ambiguity prevents safe progress.
- `Deferred`: intentionally postponed with named phase or reason.
- `Debt`: unplanned gap that must be tracked.

When unsure, choose the more conservative status and explain why.
