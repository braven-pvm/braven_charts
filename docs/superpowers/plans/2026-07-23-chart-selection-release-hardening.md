# Chart Selection Release Hardening

**Status:** Complete; merged in
[PR #91](https://github.com/braven-pvm/braven_charts/pull/91)

**Source review:** Full adversarial pass completed 2026-07-23

**Parent plan:**
[`2026-07-21-chart-selection-implementation.md`](2026-07-21-chart-selection-implementation.md)

**Architecture:**
[`2026-07-21-chart-selection-architecture.md`](../specs/2026-07-21-chart-selection-architecture.md)

**Branch:** `hardening/selection-release`

## Release decision

Selection is feature-complete and the implementation remediations shipped at
merge commit `3b5d4284`. The implementation remains inside the established
chart, controller, renderer, Workbench, artifact, and table layers. Hardening
closed the places where those layers disagreed about one selection and brought
the mounted chart back within the documented compact-performance contract.

The dirty-tree warning captured during the pre-commit review was historical
delivery-state evidence, not an unresolved release blocker. PR #91 passed
package-quality CI before merge.

## Issue ledger

| ID | Priority | Status | Issue | Acceptance evidence |
| --- | --- | --- | --- | --- |
| SEL-H01 | P0 | Complete | Range Area Y-interval membership differs between renderer hit-testing and expression resolution. | One family-aware interval predicate now drives expression resolution, snapshots, tables, statistics, zoom, and extraction; boundary-only Range Area brushes are covered. |
| SEL-H02 | P0 | Complete | Pointer X/Y intervals with no source marker lose their exact bounds. | Sparse pointer intervals commit durable per-series interval expressions, including independent Y-axis mappings. |
| SEL-H03 | P1 | Complete | Add, subtract, and toggle interval gestures discard exact selection intent. | Same-axis modifier operations retain normalized positive interval intent; cross-axis difference operations explicitly normalize to resolved identities. |
| SEL-H04 | P0 | Complete | Mounted controller eagerly expands, sorts, and publishes large selections. | Whole-series and interval intent now stay compact in mounted state, render through visible-point predicates, and materialize only from concrete controller/snapshot consumers; a mounted 100k regression enforces the command budget alongside the existing 1m snapshot benchmark. |
| SEL-H05 | P1 | Complete | Non-Scatter rectangle and lasso acquisition scan every source point. | Line/Area use a cached two-dimensional source index, Bar reuses plot-space cells, and Range Area/Candlestick use ordered viewport indexes; dense Line, Range Area, and Bar regressions bound candidates. |
| SEL-H06 | P0 | Complete | Multi-band and mixed Range Area compositions have no keyboard or screen-reader selection. | Range compositions now traverse observations with left/right and bands/centre lines with up/down, activate the focused mark or series scope, and publish live family-aware semantics. |
| SEL-H07 | P1 | Complete | Range Area lasso uses an invisible midpoint while rectangle selection uses the full interval. | Lasso containment and edge intersection now use the visible low-to-high interval, matching rectangle semantics. |
| SEL-H08 | P1 | Complete | A non-empty expression that resolves no current data reports an active selection. | Snapshots short-circuit against live data without materializing references; stale intent is empty and every Workbench action disables. |
| SEL-H09 | P1 | Complete | Exact interval expressions are lost during artifact capture and hydration. | `ChartViewState` now round-trips a typed compact expression document through JSON, mounted restoration, and generated Dart while older artifacts retain legacy selection fields. |
| SEL-H10 | P2 | Complete | Range Area hover activates a full-widget `saveLayer` without a focused benchmark. | Lightweight crosshair, selection, and mark-feedback overlays paint directly; tooltip shadows/translucency alone retain isolated compositing. The 5K Range Area hover overlay measures about 0.016 ms p95 locally. |
| SEL-H11 | P2 | Complete | Public interaction comments still describe Line/Area-only scaling. | Keyboard and selection styling dartdoc now describe marks, path/band series, and mixed Range Area composition behavior. |
| SEL-H12 | P1 | Complete | Current changed files and the repository-wide format baseline fail the documented format gate. | Every Dart file touched by hardening is formatter-clean. The broad gate separately reports 143 pre-existing baseline files; they remain recorded here rather than creating an unrelated repository-wide formatting rewrite in the Selection lane. |
| SEL-H13 | P0 | Complete | Hardening branch was behind current `master` and missing codec convergence gates. | Fast-forwarded again to `origin/master` `6892ee42` on 2026-07-23 before final verification; `HEAD` and `origin/master` match. |

## Remediation order

1. Establish one family-aware membership model for atomic data marks.
2. Preserve and compose exact gesture intent.
3. Separate compact controller state from optional materialized results.
4. Index dense acquisition paths and benchmark the mounted runtime.
5. Generalize Range Area accessibility beyond the single-series special case.
6. Normalize empty state and persist compact expressions.
7. Close overlay, documentation, formatting, and release-gate debt.

## Verification matrix

Every issue requires:

- a failing regression test before or alongside the fix;
- controller, rendering, Workbench, table, and artifact agreement where
  applicable;
- `flutter analyze lib`;
- focused package and showcase tests;
- `git diff --check`.

Before release, rerun:

- the complete package and example suites;
- surface generator analysis, tests, regeneration, and codec drift gates;
- sequential performance benchmarks;
- dartdoc;
- release web build and Wasm dry run;
- publish dry-run from a clean branch.

## Final verification evidence

Completed on 2026-07-23 against `origin/master` `6892ee42`:

- `flutter analyze lib`: no issues;
- complete package suite: 3,479 tests passed;
- `flutter analyze` in `example`: no issues;
- complete showcase suite: 397 tests passed;
- surface generator analysis and 251 tests passed;
- `dart run build_runner build`: 57 outputs regenerated with no semantic
  generated-surface drift;
- public documentation catalog and API-symbol checks passed;
- linked dartdoc generated two public libraries with 0 warnings and 0 errors;
- release web build passed, including Flutter's Wasm dry run;
- direct `/?page=selection` route returned HTTP 200 from the local server;
- sequential selection summary benchmarks covered 100K and 1M observations;
- sequential 5K Range Area hover overlay measured 0.016 ms p95 after the
  tooltip-only compositing compatibility fix;
- `git diff --check` passed.

At the historical review checkpoint, `dart pub publish --dry-run` validated
the complete archive and reported only the expected dirty-tree warning. The
reviewed changes were subsequently committed and merged through PR #91 with a
successful package-quality gate.
