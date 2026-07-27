# Grammar Radial Source-Emitter Recognition — Design

**Date:** 2026-07-26
**Status:** Approved (brainstorming). Next: implementation plan.
**Programme:** Fluent/Grammar-of-Graphics **Roadmap v2.0, Theme 1 — Universal Coverage, item 1a** (the opener).

## Goal

Make the workbench **Grammar Source** pane emit a faithful `BravenChart.of(rows)….build()` chain for **Pie / Donut / Concentric Donut / Polar Column** charts. These families already have grammar marks (`PieMark`/`DonutMark`/`PolarMark`) that lower correctly via `spec.lower()` — they are refused **only by the source emitter**, which still declares the grammar "Cartesian-only in V1." This is an **emitter-only** slice: no new marks, no new grammar, no new config surface, no drift-gate change.

## Scope boundary (decided)

The forward lowering discards most radial *chart-level config*: `_lowerPolar` sets `polar = const PolarChartConfig()` unconditionally, and concentric lowering reconstructs only `centerContent`. So this slice emits the **common** radial charts — pie, plain donut, concentric-by-center, default-polar — and **honestly refuses** a chart carrying a customised `PolarChartConfig` or a non-default `ConcentricDonutConfig` (`ringGap`/`ringWeights`/`order`/…) with an **accurate named reason**, replacing today's stale "Cartesian-only V1" message. Making customised radial configs emit requires the grammar to *carry* those config objects (new mark fields) — that is a later Theme-1d/2 "radial config passthrough" item, explicitly **out of scope** here. Radial-Bar (`RadialBarChartSeries`) and Gauge (`GaugeChartSeries`) stay fully refused — they have neither a `RadialMark` subtype nor a `geom*` verb.

## Architecture — mirror the Cartesian reversal

The emitter (`lib/src/source/chart_grammar_source_generator.dart`) reverses a config `ChartSeries` into a chain by: (1) a family gate, (2) `_planGeometry` building a `Mark` + synthesised row *fields*, (3) synthesising a `GrammarRow` class + row-list literal with `(row) => row.<field>` accessors, (4) a round-trip proof that rebuilds a `PlotSpec`, lowers it, and refuses anything that does not reproduce the captured config field-for-field. Radial mirrors each step:

| Step | Cartesian site (file:line) | Radial mirror |
|---|---|---|
| **Family gate** | `_isCartesianFamily` (`:565-572`) recognises Line/Scatter/Area/Bar/Candlestick | Recognise `PieChartSeries`/`DonutChartSeries`/`PolarColumnChartSeries`. Leave `RadialBarChartSeries`/`GaugeChartSeries` refused. (Rename to `_isEmittableFamily` for accuracy.) |
| **Per-series plan** | `_planGeometry` arms (`:1087-1241`) → `LineMark`/`BarMark`/… reading a synthesised `y` number field; scatter's category = **string field + `CategoryChannel`** (`:1159-1170`) | New arms → `PieMark`/`DonutMark`/`PolarMark`, reading **category = string field from `point.label`, value = number field from `point.y`, optional radius = number field from `point.pointStyle?.size`**. Concentric → `DonutMark(ring:)` (see below). |
| **Row fill** | `_fillRows` reads `point.y`/`magnitude`/… (`:1345-1374`) | Read `point.label` (category), `point.y` (value), `point.pointStyle?.size` (radius); ring key from `DonutChartSeries.name` |
| **Verb emission** | `_emitGeometry` verb switch (`:1584-1602`); today `RadialMark => throw` (`:1598-1601`) | Emit `geomPie`/`geomDonut`/`geomPolar` with category/value accessors + optional radius, `ring:` (donut), `center:`, `style:`, `dataLabels:` |
| **Round-trip proof** | `_firstMismatch` (`:679-751`) compares series/annotations/axes/theme/grid/title/… ; proof spec built at `:513-524` forwarding `xAxis/axes/grid` | **Add `concentricDonutConfig` + `polarChartConfig` comparisons**; build the radial proof spec with `xAxis: null, yAxes: const [], grid: null, transposed: false` (radial lowering throws `axisOptionOnRadialSpec` otherwise, `plot_lowering.dart:933-944`) |
| **Chart-option gate** | `_unsupportedChartOptions` (`:583-620`) lists `concentricDonutConfig`/`polarChartConfig`/`radialBarChartConfig` as lost | Remove the concentric + polar lines (carried inside the mark now + verified by the proof); **leave `radialBarChartConfig` gated** |
| **Stale copy** | 3 sites | Delete/rewrite: the emitter "Cartesian-only V1 … no V1 mark" message (`:361-366`), the file-header matrix (`:35`), and the `mark.dart:33-37` "Marks are Cartesian only … Radial … deliberately V2" docstring |

## Concentric-donut detection (decided — reliable, non-heuristic)

`configuration.concentricDonutConfig != null` is the authoritative discriminator: the forward path sets `LoweredPlot.concentricDonutConfig` non-null **only** inside `DonutMark.ring != null` lowering. So:
- `concentricDonutConfig != null` + donut series ⇒ emit `geomDonut(ring:)`; the ring key per series is recovered from `DonutChartSeries.name` (forward sets `name: key`, `id: '$markId-$key'`), concatenated into one row list with a synthesised `ring` string field.
- lone `DonutChartSeries` + null concentric config ⇒ plain `geomDonut` (no ring).
- The single-distinct-ring collapse (one donut carrying the center, default concentric config present) is still a `ring:` chart — the **config field**, not the series count, is the discriminator.

Any error in the ring reconstruction is caught by the extended round-trip proof (buckets/order/ids/center must reproduce), never silently shipped.

## Emitted-value fidelity

`PieChartSeries.fromMap`/`DonutChartSeries.fromMap` store each slice as `ChartDataPoint(x: index.toDouble(), y: value, label: category, pointStyle: size = radiusValue)`. The reverse reads exactly those: category ← `label`, value ← `y`, radius ← `pointStyle.size`. `_radialValues` keys the forward map by `category.toString()` (raising `duplicateRadialCategory` on repeats), so the emitted row order is first-seen category order — reproduced by emitting rows in `series.points` order.

## Testing

- **Per family:** a captured Pie/Donut/Polar chart document emits a chain containing `geomPie`/`geomDonut`/`geomPolar` with the right category/value accessors; a concentric donut emits `geomDonut(ring:)` with the recovered ring keys.
- **Round-trip ("emitted == faithful"):** the emitted chain, re-lowered, reproduces the captured config (series + `concentricDonutConfig` + `polarChartConfig`) exactly — asserted by the extended `_firstMismatch`.
- **Honest refusal:** a chart with a non-default `ConcentricDonutConfig` (e.g. custom `ringGap`) or a non-default `PolarChartConfig` is refused with a **named** reason (not the stale copy); radial-bar + gauge still refused.
- **No regression:** every existing golden unchanged; the Cartesian emission is byte-identical (the radial arms are additive; the family gate only widens); the workbench golden that captured a radial "not emitted" pane updates to the emitted chain.
- **Showcase:** the Pie/Donut/Concentric/Polar workbench pages' Grammar panes now show a real chain (manual + the existing workbench tests).

## Files

- **Modify** `lib/src/source/chart_grammar_source_generator.dart` — family gate, `_planGeometry` arms, `_fillRows`, `_emitGeometry`, `_firstMismatch` (+ radial proof spec), `_unsupportedChartOptions`, file-header.
- **Modify** `lib/src/grammar/mark.dart` — delete the stale "Cartesian only / deliberately V2" docstring.
- **Tests** under `test/unit/source/` (emitter) + any workbench golden that captured a radial "not emitted" pane.

## Invariants

- **Emitter-only:** no new `Mark`, no new config class, **no drift-gate change** (the 4 gates untouched).
- **Parity ("emitted == faithful"):** enforced by the extended proof — customised radial configs fail loudly, never silently degrade.
- **Existing render + Cartesian emission byte-identical:** the radial path is purely additive.

## Out of scope (future — Theme 1d/2)

- Radial **config passthrough** (carry `PolarChartConfig`/`ConcentricDonutConfig` in the grammar so customised radial charts emit).
- Radial-Bar and Gauge emission (need new marks + verbs — Theme 1b).
