# Grammar Radial/Polar Marks — Design

**Date:** 2026-07-23
**Status:** Approved (brainstorming). Next: implementation plan (writing-plans).
**Programme:** Fluent/Grammar-of-Graphics, Theme A — Breadth. Second Breadth item (after faceting).

## Goal

Make Pie / Donut / Concentric Donut / Polar Column authorable through the `BravenChart` grammar via dedicated radial geoms (`geomPie`/`geomDonut`/`geomPolar`), lowering to the existing rich radial config families. This closes the grammar's geometry gap — after this, `BravenChart.of(rows)` can express every chart family.

## Approach (chosen: A — dedicated radial geoms, the Vega-Lite lineage)

GoG has two schools on radial: Wilkinson/ggplot2 treat it as a **coordinate transform** (`coord_polar`; a pie is a stacked bar in polar coords); Vega-Lite treats it as a dedicated **`arc` mark** with `theta`/`radius` channels. We take the Vega-Lite path (A): dedicated radial geoms carrying their own channels. Rationale specific to this codebase: the radial families (`PieChartSeries`/`DonutChartSeries`/`PolarColumnChartSeries`, `ConcentricDonutConfig`) are feature-rich dedicated widgets (callouts, center content, rings, variable radius, selection), NOT "bars in polar coordinates" — a `coord_polar` transform would translate a bar spec into them and lose their native features. Approach A keeps θ/radius as first-class channels *and* preserves every native radial feature. (B, a separate `BravenChart.radial(...)` entry, was rejected as API fragmentation.)

## Coordinate model & geoms

Three geoms on the existing `BravenChart<T>` builder, each carrying its own channels:

```dart
// value → angle-share (RadialCategorySeries):
BravenChart<T> geomPie(  {required FieldAccessor<T, Object?> category,
                          required FieldAccessor<T, num> value,
                          FieldAccessor<T, num>? radius,
                          PieChartStyle? style, ... });
BravenChart<T> geomDonut({required FieldAccessor<T, Object?> category,
                          required FieldAccessor<T, num> value,
                          FieldAccessor<T, num>? radius,
                          FieldAccessor<T, Object?>? ring,   // concentric
                          DonutChartStyle? style,
                          DonutCenterContent? center, ... });
// category → angular position, value → radius (magnitude):
BravenChart<T> geomPolar({required FieldAccessor<T, Object?> category,
                          required FieldAccessor<T, num> value,
                          PolarColumnStyle? style, ... });
```
- **`geomPie`/`geomDonut`** — each row is a slice; **value → angle-share**; optional `radius` gives variable-radius/Nightingale.
- **`geomDonut(ring:)`** — the `ring` channel partitions rows into **concentric rings** (one `DonutChartSeries` per distinct ring value → `ConcentricDonutConfig`); a GoG grouping channel, exactly like `color`/`group`. Absent `ring` = a single donut.
- **`geomPolar`** — **category → angular position, value → radius (magnitude)** → `PolarColumnChartSeries`.

A radial geom makes the spec **radial**. Rules (enforced by diagnostics):
- **One radial geom per spec.**
- **Mixing radial + Cartesian marks** (or two radial geoms) → `mixedCoordinateSystems` diagnostic.
- `.build()` is **reused** — a radial spec lowers to a radial `BravenChartPlus`; **no new terminal** (unlike faceting's `buildFaceted`).

`FieldAccessor<T, V> = V Function(T row)` (`channel.dart`).

## Row → series mapping

Unlike Cartesian (rows → points), a radial geom maps the **whole dataset → one radial series**: each row → one slice/column via the `category`/`value` accessors. `ring` groups rows → one `DonutChartSeries` per ring. This is a different lowering shape from the per-point Cartesian path, but returns a single lowered config, so `.build()` and `BravenPlot` are unchanged.

## Styling & config passthrough (mirrors the Cartesian geoms)

The radial families are feature-rich. Rather than mint a grammar verb per knob, each geom takes its **essential channels + accepts the family's real style/config objects** — exactly how `geomLine` takes a few params and defers rich styling to config/theme:
- `geomPie(..., style: PieChartStyle(...))`, `geomDonut(..., style: DonutChartStyle(...), center: DonutCenterContent(...))`, `geomPolar(..., style: PolarColumnStyle(...))`.
- Slice/data labels, selection, callouts, radius config are authored through those config objects (unchanged config API). The grammar surface stays small (YAGNI on duplicating the config API).

## Chart-level options on a radial spec

The existing `PlotSpec` options honor what applies:
- **`title`/`subtitle`/`legend`/`theme`** → forwarded (radial has titles/legends).
- **`grid`/`xAxis`/`yAxis`/`transposed`** → `axisOptionOnRadialSpec` diagnostic (radial has no Cartesian axes).
- `.facet(...)` over a radial geom → out of scope for this slice (radial faceting is future); a faceted radial spec raises a diagnostic.

## Lowering & diagnostics

`plot_lowering.dart` gains a **radial branch**: detect the radial mark, build the matching config from the channel accessors over `spec.data` —
- `PieMark` → `PieChartSeries.fromMap`-equivalent (category→value entries, optional radiusValues).
- `DonutMark` without `ring` → `DonutChartSeries`; with `ring` → N `DonutChartSeries` (one per ring value, first-seen order) + `ConcentricDonutConfig`.
- `PolarMark` → `PolarColumnChartSeries` (category→angular position, value→radius).
Wrap in a radial `BravenChartPlus`.

New `GrammarDiagnosticCode`s (+ factories, following the existing idiom): `mixedCoordinateSystems`, `multipleRadialGeoms`, `axisOptionOnRadialSpec`, `emptyRadialCategories`, `facetedRadialUnsupported` (a radial spec that also sets `.facet(...)`). A single-value `ring` collapsing to a plain donut is allowed (not an error).

## Architecture / file structure

- **Create** `lib/src/grammar/radial_mark.dart` — sealed `PieMark<T>` / `DonutMark<T>` / `PolarMark<T>` as variants of `Mark<T>`, holding channel accessors + optional style/config. Like the Cartesian marks: **no `copyWith`, no `@chartSurface`** (they hold functions → never enter the config drift gates). One clear job: describe a radial geometry.
- **Modify** `lib/src/grammar/mark.dart` — the sealed `Mark<T>` hierarchy admits the radial variants (or `radial_mark.dart` extends the sealed base — confirm the sealed-class mechanics during planning).
- **Modify** `lib/src/grammar/chart_builder.dart` — the three geom verbs (append a radial mark to the spec).
- **Modify** `lib/src/grammar/plot_lowering.dart` — the radial lowering branch + coordinate-system detection (Cartesian xor radial) + the guard on a mixed/multi-radial/faceted-radial spec.
- **Modify** `lib/src/grammar/grammar_diagnostics.dart` — the new diagnostic codes + factories.
- **Modify** `lib/src/grammar/plot_spec.dart` — coordinate-system helper if needed (`bool get isRadial`).
- **Modify** the core barrel (`lib/braven_charts.dart`) — export the radial marks (the grammar lives in the core barrel).
- **Showcase (deliverable):** a radial preset on the Chart Grammar page — pie + donut + concentric + polar authored via the grammar, proving lowering parity against the config-authored equivalents.

## Testing

- **Per family — channel→series mapping:** `geomPie` values→angle-share slices; `geomDonut(ring:)` → N `DonutChartSeries` in first-seen ring order + `ConcentricDonutConfig`; `geomPolar` category→angular position, value→radius. Assert the concrete lowered config (series count, per-slice values, ring count, styles), not structure.
- **Config parity ("emitted == faithful"):** each radial geom's lowered `BravenChartPlus` config equals the hand-built `PieChartSeries`/`DonutChartSeries`/`PolarColumnChartSeries` equivalent — the discipline that proves the grammar is a faithful front-end to the config.
- **Diagnostics:** mixed coordinate systems, >1 radial geom, an axis/grid option on a radial spec, empty categories, faceted radial spec.
- **Golden:** one per family (pie, donut, concentric, polar), **each with the repo's `_TolerantGoldenFileComparator` from the start** — cross-platform AA lesson banked from the faceting PR (#92).

## Build phasing (planning note)

The design covers all four families; the *build* is phased into sequential sub-slices in one lane for reviewability: **Pie → Donut → Concentric (ring) → Polar**, each a full vertical slice (mark → builder verb → lowering → parity + golden), sharing the coordinate-detection + diagnostics scaffolding from the first sub-slice.

## Invariants preserved
- `PlotSpec` stays the single complete description; radial adds **no config-surface classes** and touches **no drift gate** (radial marks hold functions, like Cartesian marks).
- Non-radial authoring is unaffected (`.build()` unchanged; Cartesian specs never see the radial branch).
- Reuses the real radial config families + `BravenChartPlus` — no new rendering, no coordinate-transform engine.

## Out of scope (future)
- Radial faceting (`.facet()` over a radial geom).
- `coord_polar`-style transform of Cartesian specs (the purist path — rejected for this codebase).
- Scale-driven channels (colour/size/opacity) on radial marks beyond the families' native styling.
- Radial log/nonlinear radius scales.
