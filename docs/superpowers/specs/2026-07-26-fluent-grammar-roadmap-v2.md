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
| Pie | `PieChartSeries` | ✅ `PieMark` | ✅ (1a) | `PieChartsPage` emits; a live label-formatter callback is an honest placeholder. A chart using `sliceColors` refuses → **1a″** |
| Donut | `DonutChartSeries` | ✅ `DonutMark` | ⚠️ partial (1a) | grammar-authored donuts emit; `DonutChartsPage` refuses because it sets `sliceColors` and the mark has no per-slice colour channel → **1a″** |
| Concentric Donut | N × `DonutChartSeries` + `ConcentricDonutConfig` | ✅ `DonutMark(ring:, concentric:)` | ⚠️ partial (1a, 1a′) | non-default `ConcentricDonutConfig` round-trips (1a′); `ConcentricDonutPage` refuses on per-slice colour + per-ring labels + ring-id contract → **1a″** |
| Polar Column | `PolarColumnChartSeries` | ✅ `PolarMark` | ✅ (1a′) | **all 8 showcase presentations emit + round-trip**, verified against the real page; multi-series + `PolarChartConfig` + advanced per-series fields all carried |
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

### 1a′ — Multi-series polar + radial config passthrough — ✅ DELIVERED
Spec `2026-07-27-grammar-multi-series-polar-design.md`, plan `2026-07-27-grammar-multi-series-polar.md`. Two structural blockers closed: (1) the grammar admitted **one radial geom per spec**, so a layered/grouped/stacked polar composition could not be expressed — `multipleRadialGeoms` is now repurposed to fire only for multiple **non-polar** radial marks, and `_lowerRadial` loops N `PolarMark`s into N `PolarColumnChartSeries`; (2) `_lowerPolar` **discarded** the chart-level `PolarChartConfig` — it now rides `PlotSpec.polar`, set by the new `.polarConfig(...)` verb, and is validated above the empty-data guard as `invalidPolarComposition`. Owner chose **full coverage**, so `PolarMark` also carries `columnColor`/`target`/`targetMarkerStyle`/`intervalLow`/`intervalHigh`/`intervalStyle`/`preset`, and `DonutMark` carries `concentric` (non-default `ConcentricDonutConfig`, with a `center` precedence rule). New diagnostics: `polarConfigOnNonPolarSpec`, `conflictingConcentricCenter`, `incompletePolarInterval`, `invalidPolarComposition`, `invalidConcentricComposition`.

**Acceptance, verified against the real showcase pages** (agents mounted each page and ran the generator on the live chart document, not on hand-built stand-ins): **`PolarColumnPage` emits all EIGHT presentations** — standard, rose, **partial**, layered, grouped, stacked, references, intervals — each `isComplete: true`; `PieChartsPage` emits. Marks hold functions/config objects only, so **no new drift-gate surface**. Cartesian + pie/donut/concentric/single-polar emission byte-identical.

### 1a″ — Per-slice colour + per-ring labels on Pie/Donut marks (the last radial gap)
**Discovered while verifying 1a′ against the real pages, and it predates 1a′.** `ConcentricDonutPage` and `DonutChartsPage` still show "not emitted", for three named blockers proven by mutate-one-thing-at-a-time probes:
1. **No per-slice colour channel on `PieMark`/`DonutMark`.** The pages pass `sliceColors`, which `DonutChartSeries.fromMap` turns into a per-point `PointStyle(color:)`; the round-trip proof compares points deeply, so any pie/donut chart with `sliceColors` is unreversible. Only `PolarMark` got a colour channel (`columnColor`) in 1a′. **The fix is the same shape as that one** — add `sliceColor: FieldAccessor<T, Color?>?` to both marks, thread it through lowering + emitter + proof.
2. **One `dataLabels` for every ring.** `ConcentricDonutPage`'s `hierarchy` layout gives the outer ring `outside/categoryAndPercentage` and inner rings `inside/category`, but `DonutMark` carries a single `dataLabels` that lowering stamps onto every ring (and the emitter reverses from `donuts.first`). Needs per-ring labels — a map keyed by ring, or a label accessor.
3. **Ring ids must follow `<markId>-<ringKey>`.** This is a hard requirement of the forward lowering (`_lowerConcentricRings` ids each ring `'$markId-$key'`), not a reversal heuristic, and the reversal is its exact inverse. Either the showcase page adopts the contract or the grammar gains another way to carry ring identity — an owner-facing choice, since changing page ids touches saved artifacts/goldens.

Acceptance: `ConcentricDonutPage` and `DonutChartsPage` Grammar panes emit faithful, round-tripping chains. **Sequenced before 1b** — it is the same well-understood shape as the 1a′ colour channel and closes the last two radial "not emitted" panes, whereas 1b opens new families.

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

**How to measure it honestly (lesson banked from 1a′):** assert against the **real showcase page** — mount it, read the live `BravenChartPlus` document off the workbench, and run the generator on that — never against a hand-built stand-in. 1a′'s first acceptance pass used transcribed fixtures and reported "every polar + concentric pane emits" while the real `ConcentricDonutPage` was still refusing; a sleuth caught it by mounting the page. Hand-transcribed fixtures also need a sync guard (a test that fails when the page's presentation enum changes), or they drift silently.

**Progress:** ✅ Cartesian · ✅ Pie · ✅ Polar Column (8/8 presentations) · ⚠️ Donut + Concentric Donut (→ 1a″) · ❌ Radial Bar, Range Area, Gauge (→ 1b) · ⚠️ Bar/Scatter advanced configs (→ 1c/1d).

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

1. **Theme 1 first, in order 1a → 1a′ → 1a″ → 1b → 1c → 1d**, with the workbench parity gate as the running acceptance test. 1a shipped (PR #124, pie/donut/concentric); 1a′ shipped (multi-series polar + radial config passthrough — polar verified 8/8 against the real page); 1a″ closes the last two radial panes (pie/donut per-slice colour + per-ring labels); then the new-mark and advanced-field slices.
2. **Theme 2** after coverage, most-requested first (opacity channels, area fill-by-value).
3. **Theme 3** docs — sequenced after (or interleaved per-family if the owner later prefers).
