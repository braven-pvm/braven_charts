# Braven Charts Agent Instructions

These instructions apply to the complete repository.

## Shared development register

The branch-independent roadmap, debt, review, decision, and release register
lives outside Git at:

`F:\Repositories\_braven_charts_register`

Before planning work, choosing a next task, reviewing readiness, starting a
lane, or editing an existing registered item:

1. Read `F:\Repositories\_braven_charts_register\README.md`.
2. Run:

   ```powershell
   & 'F:\Repositories\_braven_charts_register\register.ps1' list
   ```

3. Read the complete authoritative file under the register's `items\`
   directory.
4. Reconcile the item against current Git, GitHub, code, tests, and CI before
   relying on drift-prone status.
5. Claim active work using the register's ownership protocol before editing.
6. Run `register.ps1 validate` and `register.ps1 refresh` after updating an
   item.

The item files are the current cross-lane tracking source. `CURRENT.md` is
generated and must not be edited manually. The register tracks intent and
delivery state; it is not proof that implementation or verification is
current.

Do not copy or vendor the register into this repository. Repository plans,
issues, branches, PRs, and release evidence must link back to the relevant
`BC-####` item when one exists.

If the external path is unavailable, do not fabricate its contents or block
unrelated build/test work. Use current repository and GitHub evidence, report
`Shared register sync pending`, and ask a maintainer to reconcile the register.
External contributors are not expected to have access to this machine-local
path.

## Required repository reading

Before changing code or documentation:

1. Read `docs/agent_onboarding.md`.
2. For issue-driven work, read `docs/issue_workflow.md`, the complete issue,
   and linked specifications.
3. Follow narrower `AGENTS.md` files if any are added below this directory.

## Worktree and delivery rules

- Preserve unrelated dirty changes.
- Use a dedicated branch/worktree from current `master` for a scoped lane.
- Verify current Git and CI state rather than relying on remembered status.
- Do not call work complete without meaningful tests and runtime-path evidence.
- Record accepted deferrals and residual risk in the shared register.
- Open a PR only when requested or when the active delivery contract explicitly
  requires it.
