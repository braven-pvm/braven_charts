# Polar pane and Polar Column API design

## Status and scope

Approved family boundary; focused Phase 2 API design written during Phase 0.
The Phase 0 foundation and Concentric Donut review gates are complete. Phase 2
implementation is complete for the V1 boundary and ready for PR review. The
pane geometry, coordinate transforms, public series and axis
configuration, renderer, controller selection, native table, artifact and
hydration codecs, Workbench, generated source, and showcase route now implement
the contract below. Chart Types, a three-composition Gallery, deterministic
pub.dev media, and public documentation are also in place. Local regression,
native media capture, release-web verification, and pub archive dry-run are
green. Compact, constrained, high-contrast, large-text, reduced-motion, and
deterministic label-density hardening is also complete. Final visual acceptance
was recorded on 2026-07-19 after reconciliation with the published `0.9.0`
mainline; PR review and merge remain pending.

This design establishes axis-based polar charts. It does not add axes to Pie or
Donut, and it does not make Cartesian bars responsible for radial geometry.

## Coordinate semantics

The pane has two independent dimensions:

- an angular dimension, which may be categorical or numeric;
- a radial dimension, which may be categorical or numeric.

Polar Column V1 uses an angular category scale and radial numeric scale. Radial
Bar later reverses those roles. Radar and polar line/area can reuse the pane in
a future lane.

## Public composition

The provisional surface is:

```dart
BravenChartPlus(
  series: [
    PolarColumnChartSeries.fromMap(
      id: 'requests',
      name: 'Requests',
      values: requestsByChannel,
    ),
  ],
  polarChartConfig: const PolarChartConfig(
    pane: PolarPaneConfig(
      startAngleDegrees: -90,
      sweepAngleDegrees: 360,
    ),
    angularAxis: PolarCategoryAxisConfig(),
    radialAxis: PolarNumericAxisConfig(minimum: 0),
  ),
)
```

`PolarChartConfig` groups pane and axis concerns so `BravenChartPlus` does not
accumulate unrelated top-level polar arguments. Series retain their data and
mark styling.

## Pane contract

```dart
class PolarPaneConfig {
  const PolarPaneConfig({
    this.startAngleDegrees = -90,
    this.sweepAngleDegrees = 360,
    this.clockwise = true,
    this.innerRadiusFactor = 0,
    this.outerRadiusFactor = 1,
    this.clipMarks = true,
  });
}
```

Validation requires finite values, a sweep in `(0, 360]`, and
`0 <= inner < outer <= 1`. Label and selection overflow is measured separately
from the mark clipping radius so selected marks do not leave the viewport.

The pane resolves a `RadialPaneGeometry` containing center, radii, angular
range, direction, plot bounds, and reserved label insets. It is a layout
primitive, not a data series.

## Axis contracts

Polar axes are dedicated immutable models rather than aliases for current
Cartesian X/Y widgets.

`PolarCategoryAxisConfig` owns:

- deterministic category ordering;
- label placement, skipping, rotation, and collision policy;
- category bandwidth and inner/outer padding;
- angular grid lines and tick marks;
- semantic description and formatter binding.

`PolarNumericAxisConfig` owns:

- explicit or derived min/max;
- zero/baseline and domain padding;
- ticks, labels, rings, and grid shape;
- linear and area-correct square-root scale modes;
- thresholds and portable formatter descriptors;
- rejection of unsupported negative domains in V1.

Low-level numeric-domain and tick utilities may be shared with Cartesian axes.
Pixel geometry, label orientation, and rendering remain polar-specific.

## `PolarColumnChartSeries`

The series is a distinct public model with validated category/value points.
Each mark receives a fixed angular category band and grows radially from the
configured baseline.

Provisional style concerns are:

- band fraction and category padding;
- fill, gradient, border, corners, opacity, shadow, and selection elevation;
- data labels and tooltip formatting;
- animation baseline and duration;
- optional per-point color/style override.

V1 supports one non-negative series. Multiple series, grouping, stacking,
targets, errors, and negative baselines are Phase 3 features and must not be
smuggled into the first model as partially working flags.

## Rose / Nightingale preset

Rose is a named Polar Column preset, not a separate renderer:

```dart
PolarColumnChartSeries.rose(
  id: 'population-density',
  values: densityByCountry,
)
```

The preset uses:

- equal angular category bands;
- sector marks that occupy the configured band;
- an area-correct square-root radial scale by default;
- labels and legend copy that describe magnitude, not part-to-whole share.

A linear-radius option is explicit. Variable-radius Pie remains different
because its angle still encodes a second, primary contribution measure.

## Geometry and rendering

The implementation composes:

1. `RadialPaneGeometry` for the angular frame and available radii;
2. angular/radial scale transforms;
3. `AnnularSectorGeometry` for each rendered mark;
4. polar-specific grid, axis, label, semantics, and interaction elements.

`SeriesElement` Cartesian bar geometry is not reused. Shared colors, borders,
gradients, numeric-domain utilities, and animation timing may be factored into
neutral helpers where doing so preserves existing behavior.

## Selection and controller

Flat points continue to use `ChartPointRef(seriesId, pointIndex)`.

- controller, chart, table, and legend selection remain bidirectional;
- keyboard traversal follows angular category order;
- tooltip anchors follow the selected sector through resize and pane changes;
- focus and selection never change pane allocation;
- zoom/pan are disabled in V1 unless a separate polar interaction design
  defines useful, accessible behavior.

## Table, artifacts, and hydration

The native V1 table is:

```text
Category | Series | Value
```

It does not invent Share. Later target/error fields become explicit columns.
Copy, CSV, formatting, and selection use the source point identity.

The artifact declares `series.polar.column.v1` and stores pane, angular axis,
radial axis, series, styles, formatters, and view state deterministically.
Runtime label/legend/widget builders require rebinding and portable text
fallbacks. Unsupported runtimes fail explicitly instead of hydrating the data
as Cartesian Bar or Pie.

## Radial Bar dependency boundary

`RadialBarChartSeries` will reuse the pane and scales but swaps their roles:

- radial category scale selects a concentric track;
- angular numeric scale maps value to sweep;
- explicit min/max, background track, threshold, and progress semantics belong
  to that type.

It is not implemented as `PolarColumnChartSeries(rotation: 90)` because its
axis labels, baselines, track layout, tables, animations, and accessibility
describe a different user question.

## V1 exclusions

- no multi-series composition;
- no grouping or stacking;
- no targets, uncertainty, or floating ranges;
- no negative radial values;
- no mixed Cartesian/polar plot;
- no zoom/pan;
- no Gauge or Sunburst behavior;
- no generic angle/radius data-point API.

## Acceptance tests

- pane validation, direction, partial/full sweep, and constrained layout;
- category bandwidth and radial value mapping;
- area-correct Rose scaling;
- zero, equal, maximum, and invalid domains;
- path/hit/tooltip anchor agreement through resize;
- controller/table/chart selection parity;
- deterministic artifact, hydration, preview, and formatter fallback;
- keyboard, semantics, reduced motion, high contrast, and dense labels;
- release web route, Chart Types, Gallery, documentation, and pub.dev media.
