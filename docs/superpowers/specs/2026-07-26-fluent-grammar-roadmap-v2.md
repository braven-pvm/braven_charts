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
| Pie | `PieChartSeries` | ✅ `PieMark` | ✅ (1a, 1a″) | `PieChartsPage` emits, asserted on the **mounted page** (`isComplete: false` — its label-formatter callbacks are an honest placeholder). `sliceColors` reverses as `sliceColor:` (1a″) |
| Donut | `DonutChartSeries` | ✅ `DonutMark` | ✅ (1a, 1a″) | `DonutChartsPage` emits, asserted on the **mounted page** (`isComplete: false` on **TWO** `runtimeValueOmitted` warnings, not one — its centre `valueFormatter`, and its two radial label formatters under one warning; three placeholder comments in all, and the gate pins the whole set). `sliceColors` → `sliceColor:`, and the captured `DonutCenterContent` rides the mark verbatim, so a styled centre survives (1a″) |
| Concentric Donut | N × `DonutChartSeries` + `ConcentricDonutConfig` | ✅ `DonutMark(ring:, concentric:)` | ✅ (1a, 1a′, 1a″) | non-default `ConcentricDonutConfig` round-trips (1a′); `ConcentricDonutPage` and the selection lab's concentric family emit **complete, warning-free** chains, asserted on the **mounted pages** (1a″) — but on DIFFERENT carries, and **neither emits `ringIds:`**, which both gates assert is absent. `ConcentricDonutPage` exercises `sliceColor:` and `dataLabelsByRing:`; the selection lab's family exercises **none** of the three — no per-slice colours, uniform ring labels — and emits purely because its ring ids were conformed to `'<markId>-<ring name>'` (plus the `interactiveAnnotations` page fix recorded under 1a″). `ringIds:` is the carry for compositions that did NOT conform; it is exercised by the emitter round-trip tests, not by a showcase page, and a conforming page emitting it would mean the arbitrary-id fallback had silently taken over. Still refused — the RING PRECONDITIONS: every ring must share one `donutStyle`, `selectionStyle`, `unit`, `sliceRadiusConfig` and `sliceGroupingConfig` (divergence is refused; a shared non-default value is fine), carry no per-ring series `color` at all (`_lowerConcentricRings` never passes `mark.color`, unlike `_lowerDonut`), carry no centre of its own, and have a distinct non-empty name. Only the name and the centre are refused BY NAME; the five divergences and the ring colour fall into the round-trip proof's catch-all |
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

### 1a″ — Per-slice colour, donut centre parity, per-ring labels and ring identity — ✅ DELIVERED (branch `feature/grammar-radial-slice-colour`, not yet merged)
Spec `2026-07-28-grammar-radial-slice-colour-design.md`, plan `2026-07-28-grammar-radial-slice-colour.md`, register BC-0032. **Discovered while verifying 1a′ against the real pages, and it predates 1a′.** The roadmap recorded **three** blockers; design reconnaissance that MOUNTED the pages found a **fourth** — the donut centre, unrecorded, and the one `DonutChartsPage` tripped in every knob state. Four independent carries plus a rename closed all of them:
1. **Per-slice colour.** `PieMark.sliceColor` / `DonutMark.sliceColor` (`FieldAccessor<T, Color?>?`), mirroring `PolarMark.columnColor`: a `sliceColor:` builder param on `geomPie`/`geomDonut`, a lowering helper that SKIPS null returns, per-ring-bucket resolution for concentric compositions, and emitter reversal from `point.pointStyle?.color`. Colour and radius compose on one point.
2. **The donut centre, carried verbatim.** `_markCenter` used to rebuild a centre from four of its fields and drop `labelStyle`/`valueStyle`/`valueFormatter`; it now carries the captured `DonutCenterContent` unchanged, and `center:` is written by the config emitter's own centre renderer (the shared full-fidelity one, parameterised on argument name), so a styled centre emits and a live formatter degrades to a `// valueFormatter:` placeholder with a `runtimeValueOmitted` warning.
3. **Per-ring data labels.** `DonutMark.dataLabelsByRing`, keyed by the bare ring key with `dataLabels` as the base, resolved on BOTH lowering paths (including the single-ring collapse), projected by the emitter only for rings that DIFFER from the base, and written by a new UNCONDITIONAL, sorted-key seam — so a uniform composition emits exactly what it did before.
4. **Ring identity, from both ends.** The showcase pages now id every ring `'<markId>-<ring name>'` (atomically with their `ringWeights` keys), AND `DonutMark.ringIds` carries an explicit ring-key→series-id map for compositions whose ids are decoupled from their ring names. The emitter consults the map ONLY when the `'<markId>-<ring>'` pattern fails, so conforming charts emit byte-identically. New diagnostics: `unknownRingKey`, `partialRingIds`, `perRingOverrideOnRinglessDonut`.

**Acceptance, verified against the MOUNTED pages** (each test pumps the real page, reads the live document off the chart's own controller and runs the generator on it — no fixture to drift): `ConcentricDonutPage` and the selection lab's concentric family emit **complete, warning-free** chains; `DonutChartsPage` and `PieChartsPage` emit with `isComplete: false`, for live formatter callbacks that have no literal form. The two counts are NOT the same and each gate pins its own whole warning set: `PieChartsPage` carries **one** `runtimeValueOmitted` (its two radial label formatters, under one warning); `DonutChartsPage` carries **two** — one for the `valueFormatter` on its centre, one for its two radial label formatters — leaving three placeholder comments. `PolarColumnPage` stays 8/8. Every pinned known-gap refusal was **CONVERTED** into a stronger round-trip acceptance test, never deleted, each keeping a byte-identity control that the un-overridden shape emits no new argument. Marks hold functions and config objects only, so **no new drift-gate surface**. Cartesian, polar, pie and uniform-label/default-centre donut and concentric emission byte-identical.

Recorded as part of delivery, because it was NOT in the plan: the selection lab also authored `interactiveAnnotations: false` unconditionally — a flag `BravenPlot` cannot express — so the id rename alone would not have unblocked it. The page now authors the non-default only while an annotation exists for it to govern, and the refusal for the genuinely-annotated case is still pinned.

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

**How to measure it honestly (lesson banked from 1a′, and re-learned the hard way on 2026-07-29):** assert against the **real showcase page** — mount it, read the live `BravenChartPlus` document off the workbench, and run the generator on that — never against a hand-built stand-in. 1a′'s first acceptance pass used transcribed fixtures and reported "every polar + concentric pane emits" while the real `ConcentricDonutPage` was still refusing; a sleuth caught it by mounting the page. Hand-transcribed fixtures also need a sync guard (a test that fails when the page's presentation enum changes), or they drift silently.

**And measure EVERY page, not the ones the current slice touches.** Sampling is how the entry below stayed wrong for three slices: every acceptance gate built by 1a/1a′/1a″ is radial, and every round-trip test in `test/unit/source/` authors its original via `BravenChart.of(...)` — which always produces explicit axes — so nothing ever exercised a config-authored Cartesian chart.

**Measured position (2026-07-31 re-census, after 1c′). The census is now a COMMITTED TEST — `example/test/showcase/grammar_emission_census_test.dart` — so this section is re-derivable rather than re-discoverable.** It mounts all 16 pages behind the 15 `BravenChartWorkbench` mount sites, walks every state each page's own picker offers, reads each chart's live document off that chart's own controller with the workbench's OWN `documentOptions`, and runs the generator. Every number below is an assertion in that file, per page and per family, so drift fails a test instead of ageing quietly.

| | Tuples | With a verdict | Emitting | Refused |
|---|---|---|---|---|
| **All** | **181** | **166** | **59** | **107** |
| Cartesian | — | 111 | **28** | 83 |
| Radial | — | 55 | **31** | 24 |

- **Cartesian: 28 of 111 emit, up from 0 before 1c′.** On the exact denominator 1c′ was sized against — 100 Cartesian states, `ValueSummaryPage` and `ChartGrammarPage` both outside it — the number is **20 of 100 against a prediction of 21**, reproduced exactly by this instrument.
- **The one-state shortfall is `Selection|candlestick`**, confirmed by re-measurement: it refuses on `series "price"` for a per-candle field `CandlestickMark` does not carry. Per-point `pointKey` was carried on the four Cartesian *geometry* marks only; `CandlestickMark` was out of the slice's scope. The 21 was measured by patching the PROOF alone, which normalised that away too — an upper bound that assumed emission would follow, and it did everywhere else.
- **Radial: 31 of 55 emit.** Pie (6/6), Donut (5/5), Concentric Donut (6/6) and Polar Column (9/9) all emit on the mounted pages, plus the selection lab's four radial families. `RadialBarPage` (0/12) and `GaugeChartsPage` (0/12) refuse uniformly — no mark reverses those families.
- **`ChartGrammarPage` emits on 8 of its 9 states with a verdict**, its `channels` preset refusing on a `LegendAnnotation` with no chain verb. Its `faceted` preset renders the grid directly rather than through the workbench, by design, so it has no Grammar pane and no verdict.
- **`ValueSummaryPage` reaches the generator**, as re-stated on 2026-07-30: 6 of its 7 states get a verdict and **4 emit**. The earlier "never reaches the generator" note was an artefact of extracting with default `ChartDocumentExtractOptions` rather than the page's own. **BC-0044 needs re-stating, not closing.**

**The 2026-07-30 headline this replaces was 110 with a verdict and 28 emitting, and it was wrong because it covered 8 of the 15 mount sites.** Its own arithmetic shows it: it reported 106 of those 110 as Cartesian, leaving 4 radial states — the selection lab's — when the six radial pages carry 50 between them. `ChartGrammarPage` was absent entirely. Its *Cartesian* figure was right on its own terms and reproduces exactly here (24 of 106, with the three hydration tiles admitted); the headline that contained it was not. Delta: **+59 states with a verdict, +34 emitting**, all of it on pages that run never visited — `ChartGrammarPage` 8, Pie 6, Donut 5, Concentric Donut 6, Polar Column 9.

**Charts with no Grammar pane are recorded, not dropped** — 15 tuples: 13 mounted outside any workbench and 2 with no controller. Three of the 13 are `ChartWorkbenchPage`'s hydration tiles, restored copies of the primary chart's captured document mounted beside the workbench; the old headline counted them as emitting. The census pins them as a SHADOW column instead: admitting them reads 169 with a verdict / 62 emitting, and that is the whole of the difference.

Blocker distribution over the **83** Cartesian states still refusing:

| Blocker | States | Home |
|---|---|---|
| bar style | 26 | 1c/1d |
| shared-x alignment — series whose x domains differ | 21 | needs its own design (one row list + total accessors) |
| no range-area mark | 8 | 1b |
| annotations with no chain verb (Range/Legend) | 5 | mixed |
| fill gradient | 4 | 1d |
| unnamed residual loss — the proof knows the reconstruction differs but no clause names why (`reference-ohlc` ×2, `price`, `work-stage`, `campaign-response-loess`) | 5 | 1d, mixed |
| an axis no mark measures against | 2 | mixed |
| data-point marker radius | 2 | 1d |
| `normalizationMode: perSeries` | 2 | mixed |
| path animation | 2 | 1d |
| split baseline fill / line glow / marker style / jitter / render mode / `legendStyle` | 6 (1 each) | 1d, mixed |

And over the **24** radial states still refusing: no gauge mark 12, no radial-bar mark 12.

**The next blockers are unchanged in rank by 1c′: `bar style` (26) and shared-x alignment (21)** — together ~57% of everything Cartesian still refusing. `unit`, the legacy axis binding and the per-point metadata are all now at zero. Shared-x needs its own design: one row list plus *total* accessors genuinely cannot express series with divergent x domains. The largest *mark-shaped* gaps are now radial-bar (12) and gauge (12), then range-area (8) — a re-ranking the 2026-07-30 entry could not see, because it never counted those two pages.

**The min/max decline declined during the render-fidelity work costs the census nothing**, measured rather than reasoned: applying the decline to `_legacySingleAxisSeries` *and* the matching clause in `_firstMismatch`, then re-running this census, leaves all 166 verdicts byte-identical — not one state gained or lost. That measurement is what makes the 25,885-pixel cost recorded on `braven_plot.dart` a pure loss.

**Acceptance gates for the Cartesian half now exist**: `example/test/showcase/line_charts_page_grammar_test.dart` and `area_charts_page_grammar_test.dart` mount the real pages, choose presets through the real picker, read the live document off each chart's own controller, pin every emitted mark's WHOLE argument list, assert `unit:` inside the mark's own argument list (it is a `YAxisConfig` field too, so a whole-file `contains` proves nothing), and hold the `dart format` + `dart analyze` compile floor. Both mutations kill them: deleting the `unit` emission fails 3 of the 6, and disabling the legacy-axis normalisation fails all 6.

**The 2026-07-29 entry these replace**, for the record: 0 of 117 Cartesian states emitting, with `unit` (31), the legacy single-axis binding (17) and the per-point metadata as the top 1c′ blockers. Those counts came from a run that reported `ValueSummaryPage` as unreachable and, like the 2026-07-30 one, never visited the radial pages or `ChartGrammarPage`.

### 1c′ — Cartesian emission foundation (BC-0040, inserted before 1b) — **delivered 2026-07-30**
Sequenced **ahead of the new marks**, because a new mark lands on a base where its own page still cannot emit: `geomRangeArea` would close 8 of the Cartesian states, and those 8 would still have refused behind `unit`, `fillGradient`, `pathAnimation` and the axis binding. This item took the widest-reach blockers instead — `unit` on the Cartesian marks, reconstruction of the legacy single-axis binding, and the per-point `pointKey`/`label`/`isXOrdered` metadata that a temporary axis patch exposed as the second-order blocker.

Delivered in four slices: a `SeriesMark<T>` sealed intermediate carrying `unit` (which structurally cannot reach the four annotation marks, so "accepted then silently discarded" is unrepresentable); the legacy single-axis binding reconciled on BOTH sides — a strictly-gated proof normalisation *and* a `BravenPlot` mount change — so the emitted chain reproduces the captured **document**, not merely the same pixels; `label`/`pointKey` accessors, an `isXOrdered` flag and an honest named refusal for per-point `segmentStyle`; and the two mounted-page acceptance gates. **Result: 0 → 20 of the 100 Cartesian states the item was sized against, against a prediction of 21** — and 0 → 28 of the 111 Cartesian states the census actually reaches, a denominator the item's own sizing never included (see the measured position above for both, the one-state shortfall, and why the two differ). `segmentStyle` was deliberately not carried: measured, it unblocks zero states.

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

1. **Theme 1 first, in order 1a → 1a′ → 1a″ → 1c′ → 1b → 1c → 1d**, with the workbench parity gate as the running acceptance test. 1a shipped (PR #124, pie/donut/concentric); 1a′ shipped (multi-series polar + radial config passthrough — polar verified 8/8 against the real page); 1a″ shipped (PR #142 — per-slice colour, donut centre parity, per-ring labels and ring identity), closing Theme 1's whole **radial** set on the mounted pages.

   **1c′ was inserted ahead of 1b on 2026-07-29**, after the emission census showed 0 of 117 Cartesian states emit. New marks were deferred because they would land on a base where their own pages still cannot emit — `geomRangeArea` closed 9 of 117 by that count, all 9 still refusing behind `unit`, `fillGradient`, `pathAnimation` and the axis binding. Widest-reach blockers first (1c′), then the new-mark (1b) and remaining advanced-field (1c/1d) slices.

   **1c′ delivered on 2026-07-30; census re-measured properly on 2026-07-31** and committed as a test. The Cartesian half is 20 of 100 on the item's own denominator (prediction 21) and 28 of 111 on the one the census actually reaches. `geomRangeArea` closes 8 Cartesian states, none of which still refuse behind `unit` or the axis binding — but it is **not** the largest mark-shaped gap: radial-bar (12) and gauge (12) are each larger, and both were invisible until the radial pages entered the denominator. **1b is next by sequencing, not by size; re-check that against the numbers before committing to it.**
2. **Theme 2** after coverage, most-requested first (opacity channels, area fill-by-value).
3. **Theme 3** docs — sequenced after (or interleaved per-family if the owner later prefers).
