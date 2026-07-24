# Grammar Scale-Driven Channels (non-scatter families) — Design

**Date:** 2026-07-23
**Status:** Approved (brainstorming). Next: implementation plan — **but hold planning until radial PR #99 merges** (it touches the same grammar files; build off the new master to avoid a second parallel-branch rebase).
**Programme:** Fluent/Grammar-of-Graphics, Theme A — Breadth. Third Breadth item (after faceting #92 and radial #99).

## Goal

Extend scale-driven grammar channels beyond scatter. Today `ScatterMark` is the only geometry carrying channels (`size`/`colorBy`/`opacityBy`/`categoryBy`) — a deliberately COMPILE-TIME validity fact (`channel.dart` header). This slice adds:

- **colour** channel on `geomBar`, `geomLine`, `geomArea`, and
- **size (width)** channel on `geomBar`,

each authored exactly like scatter's channels (`colorBy: Channel(...)`, `colorEncoding: ScatterColorEncoding(...)`), lowering to the per-element style slots the renderer **already paints** — so this slice needs **zero render-pipeline changes**.

## Feasibility basis (why grammar-only works)

The shared `ChartDataPoint` already carries `magnitude`/`colorValue`/`opacityValue`/`categoryValue` for every family, but only scatter's paint path reads them. The non-scatter renderers instead honour per-element STYLE slots that already exist:

| family × channel | render slot already painted | file:line |
|---|---|---|
| Bar colour | `pointStyle.color` per bar (`_resolvedBarColor`) | `series_element.dart:5480` |
| Bar size → width | `pointStyle.size` = width multiplier | `bar_geometry.dart:388` |
| Line colour | `segmentStyle.color` per outgoing segment (`_analyzeStyleRegions`) | `series_element.dart:171` |
| Area colour | `segmentStyle.color` per **edge** segment | `segment_style.dart:475` |

Because these slots take an explicit `Color`/multiplier (not a value+encoding), the channel is resolved by **baking at lowering time**: compute the domain, resolve each element's visual, write the explicit value into the slot.

## Architecture — bake at lowering

Unlike scatter (encoding travels to the series; colour resolved per point at PAINT time against the live domain), the non-scatter families have no per-element encoding field. The lowering therefore:

1. **Computes the domain** — the finite `[min, max]` of the channel accessor over `spec.data` (skips non-finite; if `min == max`, the ramp collapses to a single colour / the size range midpoint).
2. **Resolves per element** — reuses the tested scatter math: `ScatterColorEncoding.colorFor(value, min, max)` for colour, and a **linear** map into the size range for bar width (see Size below). Writes the explicit `Color` into `pointStyle.color` (bar) / `segmentStyle.color` (line, area edge), and the width multiplier into `pointStyle.size` (bar).
3. **Builds the colour legend** — constructs a `LegendAnnotation(colorScale: LegendColorScale(...))` from the same ramp + domain (existing renderable types) and attaches it, honouring `ScatterColorEncoding.showLegend`. Mirrors the label/min/mid/max + piecewise-vs-continuous logic of `_buildAutomaticColorLegends` (`braven_chart_plus.dart:3712`).

Non-finite channel values on an element are skipped: that element falls back to the series/base colour (bar/marker) or leaves its segment unstyled (line/area), exactly as scatter drops non-finite.

## Author-facing API (identical to scatter)

```dart
// colour by a value — bar (per-bar fill), line (per-segment stroke), area (edge):
BravenChart.of(rows).x(t).y(v)
  .geomBar(colorBy: Channel((r) => r.load, label: 'Load'),
           colorEncoding: ScatterColorEncoding(colors: [c1, c2, c3]))
  .build();

// variable-width bars — size drives width:
BravenChart.of(rows).x(t).y(v)
  .geomBar(sizeBy: Channel((r) => r.weight, label: 'Weight'),
           sizeEncoding: ScatterSizeEncoding(minRadius: 0.4, maxRadius: 1.0))
  .build();
```

`geomBar` gains `colorBy`/`colorEncoding`/`sizeBy`/`sizeEncoding`; `geomLine`/`geomArea` gain `colorBy`/`colorEncoding`. Channel code is copy-paste consistent with `geomScatter`. **No `channel.dart` change** — reuses `Channel<T>` + `ScatterColorEncoding`/`ScatterSizeEncoding`.

## Two documented reinterpretations

- **Area colour is the top EDGE, not the fill.** The grammar-only slot on area is `segmentStyle.color` (the outline). A value-driven area FILL is render work (deferred). The `geomArea(colorBy:)` dartdoc states this explicitly so it is not surprising.
- **Bar `sizeEncoding` min/max are width MULTIPLIERS, mapped LINEARLY.** `ScatterSizeEncoding` natively produces a marker radius in pixels via a sqrt/area map — wrong units and wrong curve for bar width (a bar twice the weight should be twice as wide). For the bar size channel, `minRadius`/`maxRadius` are interpreted as the width-multiplier bounds and the value is mapped **linearly** (bar-size native scale = `ChannelScale.linear`; naming `ChannelScale.sqrt` raises `unsupportedChannelScale`). The `geomBar(sizeBy:)` dartdoc states this reinterpretation.

## Colour-per-segment mapping (line / area)

A line of N points has N−1 outgoing segments. The outgoing segment from point *i* takes point *i*'s channel value → ramp colour (leading-point rule, matching how `segmentStyle` already attaches to a point's outgoing segment). The final point has no outgoing segment and contributes no colour.

## Diagnostics — reuse only (no new codes)

The existing symmetric channel diagnostics cover everything, so this slice adds **no `GrammarDiagnosticCode`** (no diagnostics-drift surface):

- `colorBy` set without `colorEncoding` → `missingChannelEncoding` (as scatter).
- `colorEncoding`/`sizeEncoding` set without its channel → `orphanChannelEncoding` (symmetry: an encoding with no channel to drive it is inert).
- A channel naming a non-native scale → `unsupportedChannelScale` (colour native = linear; bar-size native = linear).
- **Unsupported channels stay a COMPILE error, not a runtime throw.** `geomBar`/`geomLine`/`geomArea` simply do not declare `opacityBy` (etc.), preserving the "coordinate × geometry validity is compile-time" invariant.

## Parity ("emitted == faithful")

Each geom's lowered `BarChartSeries`/`LineChartSeries`/`AreaChartSeries` — with baked `pointStyle.color`/`segmentStyle.color`/`pointStyle.size` **and** the attached `LegendAnnotation` — must equal the hand-built config equivalent. This is the discipline every grammar slice holds; the hand-built version bakes the same colours, so parity is exact.

## Architecture / file structure

- **Modify** `lib/src/grammar/mark.dart` — add `colorBy`/`colorEncoding` to `LineMark`/`AreaMark`/`BarMark`; add `sizeBy`/`sizeEncoding` to `BarMark`. Marks hold functions/config → **no `copyWith`, no `@chartSurface`, no drift gate** (like every other mark).
- **Modify** `lib/src/grammar/chart_builder.dart` — the `geomLine`/`geomArea`/`geomBar` verbs gain the channel params.
- **Modify** `lib/src/grammar/plot_lowering.dart` — a shared colour-baking + legend-building helper (domain → per-element resolve → style slot + `LegendAnnotation`), plus the bar-width linear map. Reuses `ScatterColorEncoding.colorFor`. Consider extracting the `LegendColorScale` builder so the grammar path and `_buildAutomaticColorLegends` share one implementation (optional; a ~10-line duplication is acceptable if extraction proves invasive).
- **Showcase (deliverable):** a scale-driven-channels preset on the Chart Grammar page — a colour-by-value bar, a colour-by-value line, an edge-coloured area, and a variable-width bar, each authored through the grammar and shown beside its hand-built equivalent (parity proof).

## Testing

- **Per family — channel→baked-style mapping:** assert the concrete lowered config: bar points' `pointStyle.color` equal `colorFor(value, min, max)`; line/area points' `segmentStyle.color` equal the ramp colour under the leading-point rule; bar `pointStyle.size` equals the linear width multiplier. Assert the values, not structure.
- **Colour legend:** the lowered config carries a `LegendAnnotation` with a `LegendColorScale` whose colours/label/min-mid-max labels match the encoding + domain; absent when `showLegend` is false.
- **Config parity:** each geom's lowered config equals the hand-built `BarChartSeries`/`LineChartSeries`/`AreaChartSeries` + legend annotation.
- **Diagnostics:** `missingChannelEncoding` (colour channel, no encoding), `orphanChannelEncoding` (encoding, no channel), `unsupportedChannelScale` (naming the non-native scale on colour and on bar-size).
- **Non-finite handling:** an element with a non-finite channel value falls back to the base colour / midpoint, no throw.
- **Golden:** one per new family/channel (colour bar, colour line, edge-colour area, variable-width bar), **each with the repo's `_TolerantGoldenFileComparator` from the start** (cross-platform AA lesson from #92/#99).

## Invariants preserved

- `PlotSpec` stays the single complete description; this slice adds **no config-surface classes** and touches **no drift gate** (marks hold functions; encodings are reused, not new).
- Channels remain compile-time per-geom; non-radial/non-channel authoring is unaffected.
- Reuses the real config families + existing render slots — no new rendering, no new encoding types.

## Out of scope (future — all need render-pipeline work per the feasibility map)

- **Area fill-by-value** (current `AreaGradient` is spatial, not data-mapped).
- **All opacity channels** on line/area/bar (no per-element opacity slot; `PointStyle` has no opacity field).
- **Line/area per-POINT marker colour + size** (`_paintDataPointMarkers` is uniform).
- **Candlestick** colour/opacity channels (per-candle colour fights up/down semantics; no opacity slot).
- **Channel value in tooltips/tables** for the baked families (v1 bakes style only; does not populate `colorValue` on non-scatter points).
