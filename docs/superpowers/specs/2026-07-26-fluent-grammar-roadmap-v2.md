# Fluent / Grammar-of-Graphics — Roadmap v2.0

**Date:** 2026-07-26
**Status:** Approved (brainstorming). Each roadmap item below gets its OWN spec → plan → build cycle (like the v1 slices); this document is the strategic plan and ordering, not a single implementation spec.
**Supersedes-as-next-phase:** `docs/superpowers/specs/2026-07-22-fluent-grammar-roadmap.md` (v1).

## Where v1 left us

The v1 roadmap's three themes are **feature-complete and merged**:
- **Breadth:** faceting (#92), radial marks (#99), scale-driven channels (#104), log/time scale types (#116).
- **Convergence:** every config mirror model-driven + drift-gated (AI schema, artifact codec, Config-source emitter).
- **Depth:** nullable-clear + `YAxisConfig.withId`; the `augment`-declarations tail remains blocked on the Dart language feature.

`BravenChart.of(rows)….build()` can now author line/area/bar/scatter/candlestick + pie/donut/concentric/polar, with faceting, colour/size channels, and log/time/date axes. The GoG/Fluent surface is marked **Beta** throughout.

**But "grammar-complete" it is not.** The workbench's Grammar Source pane still shows *"the grammar chain was not emitted for this chart"* for any chart whose series family has no grammar mark **— and, tellingly, for radial families that DO have marks but that the emitter was never taught to recognise.** Roadmap v2.0 closes that gap.

## The grounded coverage gap (as of master + #113 radial-bar + #117 gauge)

`ChartSeries` is a concrete base (`lib/src/models/chart_series.dart:59`), not sealed. The full family inventory and its grammar status:

| Family | Class (file) | Grammar mark | Source-emitted today | The gap |
|---|---|---|---|---|
| Line | `LineChartSeries` | ✅ `LineMark` | ✅ | — |
| Area | `AreaChartSeries` | ✅ `AreaMark` | ✅ | — |
| Candlestick | `CandlestickChartSeries` | ✅ `CandlestickMark` | ✅ | — |
| Bar | `BarChartSeries` | ✅ `BarMark` | ⚠️ partial | mark carries no `barStyle`/waterfall/lollipop/bullet/diverging/error-bar/range/track fields → round-trip proof refuses those configs (`chart_grammar_source_generator.dart:844`) |
| Scatter | `ScatterChartSeries` | ✅ `ScatterMark` | ⚠️ partial | mark drops `jitter`/`renderMode`/`cluster`/`bin`/`density`/`interactionStyle` → refused (`:849`) |
| Pie | `PieChartSeries` | ✅ `PieMark` | ❌ **not emitted** | mark + lowering exist and round-trip; **emitter refuses radial** |
| Donut | `DonutChartSeries` | ✅ `DonutMark` | ❌ **not emitted** | same |
| Concentric Donut | N × `DonutChartSeries` + `ConcentricDonutConfig` | ✅ `DonutMark(ring:)` | ❌ **not emitted** | same |
| Polar Column | `PolarColumnChartSeries` | ✅ `PolarMark` | ❌ **not emitted** | same |
| Radial Bar | `RadialBarChartSeries` (#113) | ❌ **NONE** | ❌ | no mark at all |
| Range Area | `RangeAreaChartSeries` | ❌ **NONE** | ❌ | no mark at all |
| Gauge | `GaugeChartSeries` (#117) | ❌ **NONE** | ❌ | no mark at all |

Bar "sub-families" (waterfall, lollipop, bullet, diverging, error-bar, range/floating, track) are **config modes of `BarChartSeries`**, not classes — they need mark *fields* or dedicated verbs, not new series lowering.

**The "not emitted" mechanism** — `_isCartesianFamily` (`chart_grammar_source_generator.dart:565`) recognises only line/scatter/area/bar/candlestick; everything else hits the family gate at `:354` whose message is **stale and triplicated**:
1. the emitter message "the grammar layer is Cartesian-only in V1 … no V1 mark" (`:361`),
2. the emitter file-header matrix (`:35`),
3. the `mark.dart` docstring "Marks are Cartesian only … Radial and polar … are deliberately V2" (`mark.dart:33`) — contradicted by the `RadialMark` hierarchy 800 lines below it.
Radial chart-level configs are also independently gated as "unsupported chart options" (`_unsupportedChartOptions:583` — `concentricDonutConfig`/`polarChartConfig`/`radialBarChartConfig`).

**Workbench surface** — `BravenChartWorkbench._generateSource` (`braven_chart_workbench.dart:247`) calls `ChartGrammarSourceGenerator.generate` per chart, on demand, when the Config|Grammar toggle is on Grammar. `BravenChartWorkbench(` is instantiated at **15 example call sites**, including every radial + range-area page — so those Grammar panes render the "not emitted" comment *today*. Closing the matrix turns them all into faithful chains.

## Theme 1 — Universal Coverage (the near-term focus)

**Goal:** every chart family is grammar-authorable AND its workbench Grammar pane emits a faithful chain — "emitted == faithful" for every chart. Ordered by cost, cheapest first.

### 1a — Radial emitter recognition (no new grammar) — ✅ DELIVERED (PR #124)
Pie/Donut/Concentric/Polar already have marks (`PieMark`/`DonutMark`/`PolarMark`) that lower correctly via `spec.lower()`; they were refused only by the **emitter**. Taught the emitter about radial: widened `_isCartesianFamily`→`_isEmittableFamily`, added `_planRadial` arms + `geomPie`/`geomDonut(ring:)`/`geomPolar` emission, extended the round-trip proof (`_firstRadialMismatch`) to rebuild a radial `PlotSpec` and re-lower it, moved `concentricDonutConfig`/`polarChartConfig` out of `_unsupportedChartOptions` into the radial path, and **deleted the stale "Cartesian-only V1" copy in all four places**. Grew (owner-approved) past emitter-only into a **bounded grammar carry** — series styling (`pieStyle`/`donutStyle`/`polarStyle`/`dataLabels`/`center`) plus `unit`/`selectionStyle`/`sliceRadiusConfig`/`sliceGroupingConfig` now ride the marks — so the *rich, styled* showcase radial charts emit + round-trip exactly (marks carry the config; fidelity never relaxed; no new drift-gate surface). Acceptance met for **Pie / Donut / Concentric**. **Polar carved out → item 1a′** below. Drift gates 57/57, Cartesian emission byte-identical, full suite 3901/0.

### 1a′ — Multi-series radial + `PolarChartConfig` passthrough (the polar follow-up)
The showcase **Polar Column** chart is a 9+-series layered composition with a customised `PolarChartConfig`, so it legitimately still refuses under 1a for two structural reasons: (1) the grammar admits **one radial geom per spec** (`multipleRadialGeoms` diagnostic) — a multi-series polar/donut composition can't be expressed as a single `geomPolar`; and (2) `_lowerPolar` **discards** the chart-level `PolarChartConfig` (`polar = const PolarChartConfig()` unconditionally), so even a single-series polar with a customised config can't round-trip. Closing both needs genuine new grammar capability, not an emitter tweak: a **multi-radial-geom spec** (or a layer/series channel on the radial mark) plus **radial chart-config passthrough** (carry `PolarChartConfig`/non-default `ConcentricDonutConfig` on the mark or spec, threaded through lowering, mirroring the 1a series-config carry). Its own spec → plan → build cycle. Acceptance: the Polar showcase Grammar pane emits a faithful, round-tripping chain (no "not emitted"), and a customised-`PolarChartConfig` single-series polar round-trips exactly. **This is the last "not emitted" radial pane after 1a.**

### 1b — New geometry marks (mark → lowering → emitter → parity, one family per slice)
Families with no mark at all, each a full vertical slice like the v1 radial/channels work:
- **Range Area** — `geomRangeArea(low:, high:)` → `RangeAreaChartSeries`.
- **Radial Bar** — `geomRadialBar(...)` → `RadialBarChartSeries` (#113); a radial-family mark alongside pie/donut/polar.
- **Gauge** — `geomGauge(value:, ...)` → `GaugeChartSeries` (#117) + `GaugeChartConfig` (needle/solid indicator styles). Note gauge is a single-value/threshold-oriented family; the mark's channel model (value + ranges/thresholds) needs its own brainstorm.

### 1c — Bar sub-families
Bring `BarChartSeries`' config modes into the grammar: waterfall, lollipop, bullet, diverging, error-bar, range/floating, track. Per-slice design decision (deferred to each slice's spec): **enrich `BarMark`** with the fields/config objects vs **dedicated verbs** (`geomWaterfall`/`geomBullet`/…) that lower to a configured `BarMark`. Acceptance: a waterfall/bullet/etc. chart's Grammar pane emits a faithful chain.

### 1d — Advanced-field completeness
Close the "partial emission" gaps so the round-trip proof stops refusing configured Bar/Scatter charts: bar `barStyle`/`minBarLength`/overlay factors; scatter `jitter`/`renderMode`/`cluster`/`bin`/`density`/`interactionStyle`/`dataPointLabels`. Each field either becomes a mark field (entering the drift gates if it's a config object) or is proven inert. Acceptance: the `_firstUncarriedField` refusals (`chart_grammar_source_generator.dart:685`) are eliminated for the showcase charts.

### Theme-1 acceptance gate
Every showcase workbench page (all 15) shows a **faithful, round-tripping** grammar chain in its Grammar pane — no "not emitted" comment anywhere. This is the measurable "universal coverage" bar.

## Theme 2 — Grammar Depth (deferred v1 backlog, sequenced after coverage)

Each is a v1 slice's explicit "Out of scope (future)":
- **Channels:** opacity channels on line/area/bar (needs a per-element opacity slot — render work); area **fill**-by-value (today only the edge); line/area **per-point marker** colour+size (uniform today); candlestick channels; channel value in tooltips/tables.
- **Scales:** symlog / other non-log scales; timezone-aware time axes (UTC-epoch storage today); per-tick custom date formats; log/time on **radial or faceted** axes.
- **Faceting:** radial faceting (`.facet()` over a radial geom — the dormant `facetedRadialUnsupported` guard becomes real support).

## Theme 3 — Docs & Polish

- Full prose docs for faceting, radial, channels, and log/time in `doc/chart_grammar.md` (move each out of any "Not in V1 / deferred" section; add a section + a feature-map row) — beyond the one-line Beta notes already added.
- The 4 `prefer_const` hints in the faceting golden test.
- Refresh the Beta framing if/when the grammar graduates from Beta.

## Blocked (noted, not scheduled)

- The `augment`-declarations Depth tail — awaits the Dart language feature; revisit when it ships.

## Invariants carried from v1 (every item honours these)

- **Parity discipline ("emitted == faithful"):** the lowered config equals the hand-built config; whole-config `==` where practical.
- **Drift gates stay green:** any new config-surface field flows through @chartSurface fluent regen (`missing=0`), artifact codec, Config-source emitter, and AI schema.
- **Linear/existing render byte-identical:** new render behaviour is gated so existing charts and goldens never change.
- **Marks hold functions** (accessors) → no `copyWith`/`@chartSurface`/drift-gate cost, unless a mark carries a config object (then it enters the gates).
- **Beta:** the surface stays marked Beta until the owner graduates it.
- **Sequencing lesson (v1):** grammar items touch the same files (`mark.dart`, `chart_builder.dart`, `plot_lowering.dart`, the emitter) — do design/spec while a PR is in review (rebase-safe), build off fresh master after it merges.

## Ordering summary

1. **Theme 1 first, in order 1a → 1a′ → 1b → 1c → 1d**, with the workbench parity gate as the running acceptance test. 1a shipped (PR #124, pie/donut/concentric); 1a′ (multi-series radial + `PolarChartConfig` passthrough) closes the last radial pane; then the new-mark and advanced-field slices.
2. **Theme 2** after coverage, most-requested first (opacity channels, area fill-by-value).
3. **Theme 3** docs — sequenced after (or interleaved per-family if the owner later prefers).
