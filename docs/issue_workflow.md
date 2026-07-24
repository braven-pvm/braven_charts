# Issue and delivery workflow

GitHub issues are the execution contract between reporters, maintainers, implementation agents, and reviewers. An issue should preserve the problem and desired result while leaving room for the implementer to choose the smallest sound solution.

## Shared portfolio register

Maintainer and agent work also uses the branch-independent register at:

`F:\Repositories\_braven_charts_register`

The register answers which roadmap, debt, verification, decision, and release
items exist across concurrent lanes. GitHub remains the execution contract for
issue-driven implementation. A register item should link its issue/branch/PR;
the issue and PR should name the corresponding `BC-####` ID.

Before triage, planning, readiness review, or implementation:

```powershell
& 'F:\Repositories\_braven_charts_register\register.ps1' list
```

Read the complete item, then verify its status against current GitHub, Git,
code, tests, and CI. Claim or update it using the protocol in the register's
`README.md`. After delivery, record exact evidence and residual risks and run
`validate` plus `refresh`.

If the path is unavailable, continue from current GitHub/repository evidence
and record `Shared register sync pending`; never invent or silently duplicate
the missing register state. External contributors do not need access.

## Choose the right issue type

| Type | Use it for | Minimum useful evidence |
| --- | --- | --- |
| Bug report | Reproducible incorrect behavior | Environment, deterministic reproduction, expected result, actual result |
| Feature or API proposal | A missing developer capability or supported use case | Real-world use case, desired outcome, scope, acceptance criteria |
| Scoped engineering task | Maintainer-approved implementation work | Objective, source context, scope boundaries, acceptance criteria, verification |
| Usage or API question | Help applying existing documented behavior | Goal, attempted configuration, versions, reduced code |

Do not use an implementation task to bypass unresolved product or API decisions. Keep the originating bug or proposal linked when a separate task is needed.

Security vulnerabilities must be submitted through
[GitHub private vulnerability reporting](https://github.com/braven-pvm/braven_charts/security/advisories/new),
not a public issue.

## Lifecycle

1. **Intake** — the issue form captures the reporter's evidence and automatically applies its type plus `status: needs-triage`.
2. **Triage** — a maintainer confirms the issue type, searches for duplicates, validates the reproduction or use case, sets priority, and identifies dependencies or required decisions.
3. **Ready** — the issue meets the readiness definition below. Replace `status: needs-triage` with `status: ready`.
4. **In progress** — an assignee records the working branch and links the issue from commits and the pull request. Remove `status: ready`; assignment and the linked PR are the source of truth for active ownership.
5. **Blocked** — add `status: blocked` and comment with the exact decision, dependency, or external change required. Remove the label when work can continue.
6. **Review** — the pull request closes the issue, maps the implementation to acceptance criteria, and records exact verification results and residual risks.
7. **Done** — merge closes the issue. Release-specific follow-up remains linked as a separate issue when publication or migration work is still required.

Avoid ad hoc parallel status documents that can drift from GitHub and the
shared register. Link durable specifications and architecture decisions from
the issue and register item instead of duplicating them. If the two disagree,
current implementation/CI evidence and the issue's approved scope determine
the correction; update the stale surface explicitly.

## Definition of ready

An issue is ready for implementation only when:

- the current problem or objective is concrete;
- the affected user or developer workflow is named;
- reproduction evidence exists for a bug, or the use case is validated for a feature;
- in-scope and out-of-scope boundaries are explicit;
- acceptance criteria are observable and testable;
- public API, persisted artifact, platform, accessibility, and performance constraints are recorded where relevant;
- dependencies, blockers, and unresolved decisions are visible; and
- required automated and manual verification can be performed.

If implementation would require guessing at any of these, keep the issue in triage and ask a focused question.

## Agent execution protocol

Before editing:

1. Read `docs/agent_onboarding.md`, this workflow, the complete issue, and linked specifications.
2. Read and reconcile the matching shared-register item; create one when
   maintainer-approved work has no existing item.
3. Confirm the issue is ready and that no newer comment changes its scope.
4. Claim the register item and record the planned branch/worktree.
5. Refresh from the latest `master` and work on a dedicated issue branch/worktree.
6. Snapshot the existing dirty state and preserve unrelated changes.
7. Comment with the register ID, branch name, intended acceptance-criteria
   slice, and any immediate blocker.

During implementation:

- treat the issue's acceptance criteria and scope boundaries as the contract;
- report new decisions or necessary scope changes on the issue instead of silently expanding the diff;
- add meaningful tests that would fail against the previous behavior;
- verify runtime composition, serialization, controllers, callbacks, and deployment paths when they are part of the issue; and
- create follow-up issues for accepted deferrals rather than hiding them in code comments.

Use this compact progress comment when a handoff or blocker must be visible:

```markdown
Status: In progress | Blocked | Review ready
Branch: feature/example
Completed: <acceptance criteria or verified outcome>
Verification: <exact commands and results>
Blockers or residual risk: <none or exact condition>
Next: <single next action>
```

## Pull request handoff

Every implementation pull request should:

- use `Closes #<issue>` for the execution issue;
- name the shared-register `BC-####` item, or state why it is not applicable;
- describe the delivered outcome rather than listing commits;
- confirm what remained out of scope;
- explain important runtime or API decisions;
- record exact analyzer, test, build, manual, and visual results;
- identify skipped gates with reasons;
- call out compatibility changes and residual risks; and
- link follow-up issues for deferred work; and
- update the register's status, evidence, PR, next action, and residual risks.

The repository pull request template provides this structure automatically.

## Label taxonomy

Keep labels small and composable:

- type: existing `bug`, `enhancement`, `documentation`, and `question` labels plus `type: task`;
- state: `status: needs-triage`, `status: ready`, and `status: blocked`;
- priority: `priority: p0` through `priority: p3`, assigned during triage based on impact and urgency.

Area is captured as structured issue content instead of generating a large set of labels. Add an area label only if issue volume makes that routing automation worthwhile.

### Priority guide

| Priority | Meaning |
| --- | --- |
| `priority: p0` | Release blocker, data loss/corruption, security issue, or widespread unusable core path |
| `priority: p1` | High-impact core defect or committed release capability without a practical workaround |
| `priority: p2` | Normal planned work, meaningful defect with a workaround, or additive feature |
| `priority: p3` | Low-impact polish, opportunistic improvement, or non-urgent documentation work |
