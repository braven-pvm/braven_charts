# Technical Debt Rebaseline

**Package version audited**: 0.13.5

**Repository revision audited**: [`edb9a89c`](https://github.com/braven-pvm/braven_charts/commit/edb9a89c)

**Rebaseline date**: 2026-07-24

**Status**: Historical reconciliation; not an active backlog

> [!IMPORTANT]
> The shared Braven Charts register is authoritative for current status,
> priority, ownership, dependencies, and next actions. Maintainers access it at
> `F:\Repositories\_braven_charts_register`; agents must follow the register
> protocol in [`AGENTS.md`](../AGENTS.md). This page records why the old
> `TD-*` entries were retired and points to successor `BC-*` items. Do not add
> a second active backlog here.

## Current verification baseline

The historical document described a 739-test package with 16 failures and a
missing public widget layer. Those figures and assumptions no longer describe
the package.

At the audited revision, the package-quality workflow for
[PR #109](https://github.com/braven-pvm/braven_charts/pull/109) completed
successfully:

- `flutter analyze lib` passed;
- `flutter test` reported **3,710 passed and 6 skipped**;
- `flutter analyze` in `example/` passed with no issues;
- public-documentation, generated-surface, dartdoc, and publish dry-run checks
  passed.

See the
[package-quality workflow](../.github/workflows/package-quality.yml) and its
[successful run](https://github.com/braven-pvm/braven_charts/actions/runs/30090377846)
for the exact commands and immutable result. Test counts are evidence for this
revision, not a manually maintained quality target.

## Legacy entry audit

| Legacy entry | Current classification | Evidence and successor |
| --- | --- | --- |
| **TD-001 — Performance Metrics Missing Culling Statistics** | **Obsolete; superseded by the current rendering architecture.** | `PerformanceMetrics`, `RenderPipeline`, `ViewportCuller`, `culledElementCount`, and `renderedElementCount` do not exist in current `lib/` or `test/`. Current rendering uses [`ChartRenderBox`](../lib/src/rendering/chart_render_box.dart), [`SeriesCacheManager`](../lib/src/rendering/modules/series_cache_manager.dart), plot transforms, and spatial indexing. The legacy implementation remains only in [`docs/archive_release_1.0`](archive_release_1.0). No active debt was preserved under the old metric contract. |
| **TD-004 — Async Performance Test Timing Precision** | **Obsolete as written; one narrower current cleanup item preserved.** | Every named `PerformanceMonitor` test path and the production type are absent. The remaining unused [`performance_test_utils.dart`](../test/performance/performance_test_utils.dart) still contains delay-based frame collection and synthetic memory values. That current concern is tracked as **BC-0021 — Retire or replace the synthetic performance test utility**. |
| **TD-006 — Golden Tests Require Chart Widget Layer** | **Architecture blocker obsolete; one visual-coverage gap preserved.** | The package now exposes `BravenChartPlus` and ten chart families. Current goldens cover Line, Area, Bar, Candlestick, Range Area, Pie, Donut, Concentric Donut, Polar Column, multi-axis, artifacts, workbench, streaming, and other public surfaces under [`test/golden`](../test/golden). Scatter has extensive behavioral and benchmark coverage but no dedicated visual golden; that narrower gap is tracked as **BC-0022 — Add a dedicated Scatter visual regression golden**. |
| **TD-002 — Mock Canvas Missing `drawRect`** | **Historically resolved, then removed with the legacy harness.** | Commit [`99a75e01`](https://github.com/braven-pvm/braven_charts/commit/99a75e01) fixed the old mock. Its referenced test file no longer exists in the current suite. |
| **TD-005 — `PerformanceMetrics` Immutability Validation** | **Historically resolved, then removed with the legacy metrics model.** | Commit [`99a75e01`](https://github.com/braven-pvm/braven_charts/commit/99a75e01) corrected the old assertion. Neither the named test nor the legacy model exists in the current package. |
| **TD-003 — Text Cache Hit Rate Edge Cases** | **Superseded by the rendering rewrite.** | The four named cache/mock test files and `TextLayoutCache` are absent. The three historical skips therefore are not current skip inventory. Current CI still reports six skips, which must be assessed from the current suite rather than attributed to TD-003. |

## Active successor items

This rebaseline preserved only current, reproducible concerns:

- **BC-0021 — Retire or replace the synthetic performance test utility**:
  remove the unused helper or replace its fake memory and delay-based timing
  with a supported measurement harness.
- **BC-0022 — Add a dedicated Scatter visual regression golden**:
  add one deterministic visual baseline through the current public chart API.

Their priority, owner, status, acceptance criteria, and evidence live only in
the shared register. If either item moves or changes scope, update the register
rather than this historical reconciliation.

## Debt management

When current debt is found:

1. search the shared register for an existing item or dependency;
2. create or update one `BC-*` item with observed evidence, measurable
   acceptance criteria, priority, lane, and next action;
3. claim it before implementation by recording owner, branch, and worktree;
4. keep implementation plans and GitHub issues linked from that item;
5. move it to review or completion only after recording verification and
   residual risk.

Use this page only when a future architectural migration needs to explain the
fate of these six historical `TD-*` identifiers.
