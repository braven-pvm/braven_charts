# Cartesian Emission Foundation — Design

**Date:** 2026-07-30
**Status:** Approved (brainstorming). Next: implementation plan.
**Programme:** Fluent/Grammar-of-Graphics **Roadmap v2.0, Theme 1 — item 1c′**, inserted ahead of 1b.
**Register:** BC-0040 (lane `chart-grammar`).
**Worktree/branch:** `F:\Repositories\braven_charts-cartesian-foundation`, `feature/grammar-cartesian-foundation` (off `origin/master` `4d5687a9`).

## Goal

A chart authored the normal way — `BravenChartPlus` with config objects — can be reversed into a `BravenChart` chain when it is Cartesian, as it already can when it is radial.

## Why this item exists

A census on 2026-07-29 mounted every Workbench-bearing showcase page, read each chart's live document off its own controller, and ran the generator. **Of 104 states with a verdict, 4 emit — and all four are radial.** No config-authored Cartesian chart has ever emitted a grammar chain.

Nothing detected this for three slices because nothing tested it: every acceptance gate built by 1a/1a′/1a″ is radial, and every round-trip test authors its original via `BravenChart.of(...)`, which always produces explicit axes. A test at `chart_grammar_source_generator_test.dart:6980` even pins the *opposite* — that a single-axis config chart is refused.

Item 1b (new marks) was deferred behind this one: `geomRangeArea` would close 9 of ~100 states, and those 9 would still refuse behind `unit`, `fillGradient`, `pathAnimation` and the axis binding.

## Measured payoff (this is what the design is sized against)

Measured by patching the proof and re-running the same census instrument:

| Configuration | Cartesian emitting (of 100) | Δ |
|---|---|---|
| Baseline | **0** | — |
| `unit` alone | **0** | **+0** |
| axis binding alone | 4 | +4 |
| axis + per-point metadata | 13 | +9 |
| **full 1c′** | **21** | **+8** |

**`unit` alone unblocks nothing** — every unit-blocked state is also axis-blocked. The three parts are only worth 21 *together*, which is why they are one slice and not three.

## Owner decisions (settled at brainstorm)

- **Document-faithful, not merely render-faithful.** The axis fix must make the emitted chain reproduce the captured *document*, not just render identically — so the existing `expectRoundTrip` document-equality harness gates these charts unchanged, the same bar every radial slice was held to.
- **Side findings registered, not fixed here:** `ValueSummaryPage`'s extraction failure is **BC-0044**; per-candle `candlestickStyle` is recorded in the roadmap's blocker distribution.

## Architecture

### A. `unit` — hoist onto a new `SeriesMark<T>` intermediate

`ChartSeries.unit` already lives on the **base** series class, so the series layer made this decision long ago; per-mark would be six declarations of one concept (five new, plus the copy on `RadialMark`), each free to drift. Per-family staging also buys nothing: no unit-bearing showcase chart is single-family — `chart_workbench_page.dart` puts Area + Line + 2×Bar + Scatter in one series list, all carrying units — so a per-family increment unblocks **zero pages** until all five land.

**But `unit` must not go on `Mark` itself.** `Mark` also parents `TrendMark`/`ThresholdMark`/`BandMark`/`PointMark`, which lower to `ChartAnnotation`s, and **no annotation type in this package has a `unit`**. The field would be accepted and silently discarded, and `_sameAnnotation` does not read it, so **the round-trip proof would never catch the loss** — precisely the silent degradation this codebase forbids.

So: introduce `sealed class SeriesMark<T> extends Mark<T>` carrying `unit`, mirroring the existing `RadialMark` precedent for a sealed intermediate holding sub-family fields. `LineMark`/`AreaMark`/`BarMark`/`ScatterMark`/`CandlestickMark` and `RadialMark` extend it; the four reference marks stay on `Mark` and structurally cannot carry a unit.

**`RadialMark.unit` must be deleted, not left.** Probe-verified: leaving it shadows the base field, compiles silently, and leaves the base's storage slot dead and always null.

Blast radius is small: `unit` is an optional named param, so **zero construction sites change** (21 in `lib/`, ~393 in `test/`). No `const` breakage, no exhaustive-switch impact, and no drift-gate surface — `unit` is a plain `String?`, marks have no `copyWith`, and no meta test enumerates mark fields.

### B. The legacy single-axis binding — Option D (proof + `BravenPlot` seam)

Pages author `BravenChartPlus(yAxis: ...)`, so their series carry `yAxisId: null, yAxisConfig: null`. Lowering always binds (`_bindAxis` does `mark.yAxisId ?? axes.first.id`) and stamps every lowered series, so `ChartSeries ==` fails and the proof reports the axis sentence.

**Two halves, and both are needed for document fidelity:**

1. **Proof normalisation**, gated strictly: normalise only when **every** captured series is unbound (`series.every((s) => s.yAxisId == null && s.yAxisConfig == null)`), with `axes.length == 1` asserted as defence in depth.
2. **`BravenPlot` seam**: when the lowered plot declares exactly one axis and no mark bound explicitly, mount the legacy shape — pass `yAxis:` and strip the per-series binding. `BravenPlot` currently passes no Y axis at all, so the declared axis reaches the chart *only* through each series' `yAxisConfig`; that is why half 1 alone leaves an `axisId` + `inlineAxis` delta in the document.

With both, the emitted chain reproduces the captured document **exactly**, and `expectRoundTrip` gates these charts unchanged.

**The too-broad normalisation is proven dangerous and must not be written.** Normalising "a null `yAxisId` binds to `axes.first`" is wrong: `getEffectiveYAxes` ignores the widget-level `yAxis` once any series carries an inline config, and in exactly that case `getEffectiveBindings` binds an unbound series to the synthetic `'primary_axis'` — there is no primary axis left to join — not to `axes.first`. A document with one series bound inline and another unbound is reachable, and binding the second to the first's axis **renders a different chart** — 4,265 of 960,000 pixels differ under `normalizationMode.perSeries`. The strict all-unbound gate costs nothing: re-running the census with it produced the identical emitting count.

**As built — the seam needed a third piece, and the invariant needed a stronger gate.** Document equality turned out to be necessary but *not sufficient*: two charts with byte-identical documents were measured drawing different pixels. Two corrections stand in the code:

- **The mount hands the fallback axis id back the way it was authored.** A chain reversed from a config chart always spells `id: 'y'` (the id extraction stamps on an anonymous widget-level axis), so the mount unwinds it to the empty id. An author-NAMED axis keeps its name. The document is unaffected either way, because extraction re-stamps the fallback.
- **The dangling binding was fixed at its root, in `MultiAxisManager`, not in the grammar.** `getEffectiveBindings` named the synthetic `'primary_axis'` literally, and that id exists only when the widget-level axis carries none — so any axis with an id of its own had *nothing* bound to it: `computeAxisBounds` fell through to its `0..100` no-data fallback and `AxisColorResolver` used its default grey. It was never a grammar-only defect (a hand-written spec mounts `'axis-0'`; a `BravenChartPlus` with a `YAxisConfig.withId` widget-level axis was hit identically), so fixing it in `BravenPlot` would have papered over two thirds of it. A chart whose series carries an inline `yAxisConfig` is deliberately excluded, which is the same boundary the paragraph above draws.

**The invariant is now gated in pixels.** `test/widgets/braven_plot_pixel_parity_test.dart` renders eight shapes at a fixed 600x400 host and compares raw RGBA against the config chart each claims to be, with a determinism control and a discrimination control so the zeroes cannot be vacuous. Document equality stays; it is no longer the whole claim.

**Those zeroes answer parity, NOT before-vs-after — keep the two apart.** "A chain reversed from a config chart renders like that chart" is true at 0 of 240,000 pixels. It says nothing about whether an AUTHORED spec renders like it did *before* the mount changed, and for six shapes it does not, because the legacy chart honours axis settings the inline mount dropped. Measured by reverting `braven_plot.dart` and `multi_axis_manager.dart` to `origin/master` and re-capturing at the same host:

| authored single-axis shape | changed (of 240,000) | in plot area | filed under |
|---|---|---|---|
| `min` AND `max` | 25,885 | 20,770 | Fixed |
| `min` only | 25,126 | 20,284 | Fixed |
| `max` only | 23,196 | 17,854 | Fixed |
| `scaleType: AxisScaleType.log` | 11,948 | 11,745 | Fixed |
| `position: YAxisPosition.hidden` | 9,721 | 8,532 | Changed |
| `visible: false` | 9,721 | 8,532 | Changed |
| no axis / plain labelled axis / named axis | 0 | 0 | unchanged |

The four `Fixed` rows are settings the previous mount ignored outright: a ranged axis drew the byte-identical frame to the same axis carrying *no* range, and a `log` axis drew log tick labels over linearly-mapped data (`BravenChartPlus` reads `widget.yAxis?.scaleType ?? AxisScaleType.linear`, and the previous mount set no `widget.yAxis`) — a mislabelled chart, not merely a linear one. The hidden pair is a plain behaviour change: both mounts hide the axis and lay the plot area out identically, and the entire difference is the hidden axis' horizontal grid, which the previous mount kept drawing. Confirmed by removing it — with `GridConfig(horizontal: false)` the two mounts draw the identical frame.

The pixel-parity file now owns this as a **mount divergence table**: every shape asserts both the parity zero and the size of its before/after change, against a `previousMount` helper that rebuilds the old mount in process from `spec.lower()`. That helper was validated against an actual revert — 0 differing pixels on all nine shapes — so "which shapes change appearance" is asserted rather than rediscovered.

### C. Per-point metadata

| Field | States | Decision |
|---|---|---|
| `label` | 5 | **Accessor** `String? Function(T)?` on the four Cartesian geometry marks. This is the direct Cartesian analogue of the radial `category` channel — `PieChartSeries.fromMap` sets `label: entry.key`, which is exactly why `geomPie(category:)` round-trips. Highest value, lowest risk. |
| `pointKey` | 4 | **Accessor** `String? Function(T)?`. It is the stable selection identity and participates in `ChartDataPoint ==`; all four blocked states are selection demos, where dropping it is a semantic loss. Mind the constructor assert: an empty string must lower to `null`, not throw. Guard against colliding keys within one series. |
| `isXOrdered` | 5 | **Plain `bool` argument on the geom verbs.** It is a series-level data-shape hint, not per-point metadata. **Do not derive it** from the synthesised rows: deriving would silently flip it to `true` on every existing grammar chart whose rows happen to be sorted, changing nearest-point behaviour for charts nobody asked to change. |
| `segmentStyle` | 0 | **Named refusal.** Carrying it unblocks *zero* states — measured: the one censused chart using it (`Line|Forecast`) still refuses on a 1d marker field behind it. It is also the most expensive: it needs a new row-field kind (rows have slots for numbers, strings, stamps and colours only) plus a per-row literal, and it collides with `LineMark.colorBy`, which already bakes `segmentStyle.color` per point. Give it an honest named reason and revisit with 1d. |

Accessors are functions, so they add no `copyWith`/`@chartSurface`/drift-gate cost, and `label`/`pointKey` map onto the `_FieldKind.string` row slot the generator already has.

### D. Emitted text must be asserted explicitly

**The proof does not read the emitted text.** The generator's own docstring records this, verified by mutation: deleting the `.grid(...)` and `.title(...)` emission produces *zero* refusals. So a missing writer line or a missing builder param ships a chain that silently drops a value while every existing test passes.

Every field this slice carries therefore needs an explicit emitted-text assertion (`contains("unit: 'W'")` and equivalents), mirroring how the radial path already guards its own.

## Invariants

- **Document-faithful:** emitted chains reproduce the captured document, gated by the existing `expectRoundTrip` harness — not merely render-identical.
- **No new drift-gate surface:** marks carry plain values and functions.
- **Radial emission byte-identical**; existing goldens unchanged.
- **The fidelity guard stays mutation-killing** — any proof normalisation must be narrow enough that a deliberately over-broad version fails a test.
- **No pinned test deleted** — refusals this slice converts become positive round-trip tests.

## Slices

1. **`SeriesMark` + `unit`** — the intermediate, five marks re-parented, `RadialMark.unit` deleted, five lowering passthroughs, five builder params, emitter reversal + **emitted-text assertions**. Ends green; unblocks 0 states on its own, and the slice says so.
2. **Axis binding** — proof normalisation (strict all-unbound gate) + the `BravenPlot` seam. Converts the pinned refusal test at `:6980` into a positive document-equality round-trip. Unblocks 4.
3. **Per-point metadata** — `label`, `pointKey`, `isXOrdered` accessors/flag; `segmentStyle` named refusal. Unblocks 9 more.
4. **Mounted-page gates + census** — `*_grammar_test.dart` for the Line and Area pages matching the radial four, including the compile floor; re-measure and record the census.

Serialised: 1 and 3 both touch `mark.dart`, `chart_builder.dart`, `plot_lowering.dart` and the emitter.

## Testing

- **Round-trip** per carried field, with document equality, on non-default fixtures.
- **Mounted-page acceptance** for Line and Area — never transcribed fixtures.
- **Over-broad-normalisation guard:** a test with one series bound inline and one unbound must still be refused; a deliberately loosened gate must fail it.
- **Emitted-text assertions** for every carried field (the proof cannot see them).
- **No regression:** radial byte-identical, drift gates, both analyzers, the changed-file format gate, and the fidelity-guard mutation check.

## Files

- `lib/src/grammar/mark.dart` — `SeriesMark`; re-parent five marks; delete `RadialMark.unit`; `label`/`pointKey`/`isXOrdered` on the Cartesian marks.
- `lib/src/grammar/chart_builder.dart` — `unit`, `label`, `pointKey`, `xOrdered` params on the Cartesian geom verbs. **(Holds a NUL sentinel; also invisible to plain ripgrep — use `--text`.)**
- `lib/src/grammar/plot_lowering.dart` — five `unit:` passthroughs; per-point fields; `_lowerTrend`/`_lowerThreshold`/`_lowerBand`/`_lowerPoint` deliberately untouched.
- `lib/src/grammar/braven_plot.dart` — the legacy single-axis mount.
- `lib/src/source/chart_grammar_source_generator.dart` — reversal, emission, proof normalisation, `segmentStyle` named refusal.
- Tests under `test/unit/grammar/`, `test/unit/source/`, plus `example/test/showcase/*_grammar_test.dart`.

## Out of scope (recorded, not oversights)

- **bar style (26 states)** and **shared-x alignment (21)** — together ~60% of what remains after this item. Bar style is 1c/1d; shared-x needs its own design (one row list plus *total* accessors genuinely cannot express divergent domains).
- **Per-candle `candlestickStyle`** (2 states) — new per-point blocker, recorded in the roadmap.
- **`ValueSummaryPage` extraction** (7 states) — **BC-0044**, upstream of grammar entirely.
- New marks — BC-0038 and the rest of 1b, resuming after this item.
