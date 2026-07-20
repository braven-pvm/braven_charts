# Polar Column and Rose charts

Polar Column compares category magnitudes on real angular and radial axes.
Each category owns one angular band; its value maps to radius against an
explicit numeric scale. Values are never converted into shares of a total.

Use this family when the question is “how large is each category around a
cycle?” Typical examples include demand by hour, incidents by weekday,
seasonality by month, and magnitude by compass direction.

- use `PolarColumnChartSeries.fromMap` for direct linear-radius comparison;
- use `PolarColumnChartSeries.rose` for an equal-angle Nightingale/Rose view;
- use Pie or Donut when angle must encode contribution to one total;
- use the future Radial Bar family when categories occupy radial tracks and a
  value controls angular sweep.

[Open the live Polar Column showcase](https://braven-pvm.github.io/braven_charts/?page=polar-column)

## Quick start

```dart
final series = PolarColumnChartSeries.fromMap(
  id: 'channel-demand',
  name: 'Requests',
  unit: 'k requests',
  values: const {
    'Search': 86,
    'Social': 58,
    'Partners': 72,
    'Email': 44,
  },
  columnColors: const {
    'Search': Color(0xFF2563EB),
    'Social': Color(0xFF0284C7),
    'Partners': Color(0xFF0D9488),
    'Email': Color(0xFFF59E0B),
  },
);

BravenChartPlus(
  series: [series],
  polarChartConfig: const PolarChartConfig(
    pane: PolarPaneConfig(
      startAngleDegrees: -90,
      sweepAngleDegrees: 360,
      outerRadiusFactor: 0.86,
    ),
    angularAxis: PolarCategoryAxisConfig(innerPadding: 0.12),
    radialAxis: PolarNumericAxisConfig(
      minimum: 0,
      maximum: 100,
      tickCount: 5,
    ),
  ),
)
```

Map insertion order is the visible category, keyboard traversal, table, CSV,
artifact, and restored order. Use stable, unique labels.

## Series contract

`PolarColumnChartSeries` owns source data and mark appearance:

| Property | Meaning |
| --- | --- |
| `id` | Stable series identity used by controllers and artifacts |
| `name` | Human-readable series name used by tables and tooltips |
| `points` | Zero-based ordinal points with a visible unique category label |
| `unit` | Optional value unit; it does not change numeric scale semantics |
| `preset` | `standard` or `rose` |
| `polarStyle` | Fill, gradient, elevation, corners, border, value labels, and entrance motion |
| `targetValues` | Optional absolute target aligned one-for-one with source categories |
| `targetMarkerStyle` | Target color, width, opacity, and angular length |
| `selectionStyle` | Explode or lift treatment for durable point selection |

The `fromMap` and `rose` constructors create the required ordinal X values and
copy each map key into the point label. The direct constructor remains useful
when points carry metadata or explicit per-point styles.

Each series must be non-empty with finite, signed values. The family rejects
duplicate or blank category labels, unstable ordinals, and Cartesian/polar
mixing instead of guessing a layout.

## Layered comparison

Multiple compatible series can share the same polar axes. They paint in
declaration order, so a broad reference or capacity layer can sit behind a
more prominent observed layer:

```dart
final capacity = PolarColumnChartSeries.fromMap(
  id: 'capacity',
  name: 'Capacity',
  unit: 'orders',
  values: const {'Search': 92, 'Social': 70, 'Partners': 84},
  color: const Color(0xFF94A3B8),
  polarStyle: const PolarColumnStyle(
    opacity: 0.32,
    showDataLabels: false,
  ),
);

final observed = PolarColumnChartSeries.fromMap(
  id: 'observed',
  name: 'Observed',
  unit: 'orders',
  values: const {'Search': 72, 'Social': 48, 'Partners': 68},
  color: const Color(0xFF2563EB),
);

BravenChartPlus(
  series: [capacity, observed],
  polarChartConfig: const PolarChartConfig(),
);
```

Every series in the composition must have:

- a unique series ID;
- the same category labels in the same order;
- the same `PolarColumnPreset`;
- the same normalized unit.

The scale domain is derived from every value in the composition. Grid and axis
labels paint once, while pointer and keyboard interaction retain the selected
series ID as well as the category index.

## Grouped comparison

Grouped composition keeps the same category axis and radial value scale, but
divides every visible category band into one stable angular sub-band per
series:

```dart
BravenChartPlus(
  series: [north, south, west],
  polarChartConfig: const PolarChartConfig(
    composition: PolarColumnCompositionConfig(
      mode: PolarColumnCompositionMode.grouped,
      groupInnerPadding: 0.12,
    ),
  ),
);
```

Series retain declaration order within every category. A
`groupInnerPadding` of `0` fills each series slot; larger values reserve a
fraction of each slot as a symmetric gap. The setting must be finite and in
`[0, 1)`. It does not discard or merge source values: the table, CSV export,
artifact, controller, and Source view retain one row and stable identity for
every series/category pair.

Use layered composition when values should occupy the same angular band, such
as capacity behind observed volume. Use grouped composition when side-by-side
angular comparison is the primary reading task. Both modes share one global
radial domain. Neither mode stacks values.

## Diverging stacked comparison

Stacked composition preserves the same category and series contracts while
accumulating each raw contributor along the radial value axis:

```dart
final newAccounts = PolarColumnChartSeries.fromMap(
  id: 'new',
  unit: 'accounts',
  values: const {'Search': 34, 'Social': 26, 'Partners': 31},
);

final churn = PolarColumnChartSeries.fromMap(
  id: 'churn',
  unit: 'accounts',
  values: const {'Search': -13, 'Social': -21, 'Partners': -12},
);

BravenChartPlus(
  series: [newAccounts, churn],
  polarChartConfig: const PolarChartConfig(
    pane: PolarPaneConfig(innerRadiusFactor: 0.14),
    composition: PolarColumnCompositionConfig(
      mode: PolarColumnCompositionMode.stacked,
    ),
  ),
);
```

Every category has two independent accumulators that begin at zero. Positive
values stack outward on the positive side; negative values stack toward the
negative side. Opposite signs do not cancel or change each other's visible
depth. Series declaration order is the stack order on each side.

Automatic domains include zero and the most extreme cumulative endpoints. If
you set explicit bounds for stacked composition, those bounds must contain
zero. The renderer uses cumulative start/end values only for geometry: direct
labels, tooltips, semantics, table rows, CSV, controller references, artifacts,
and generated Dart all retain the original signed source value.

## Targets and thresholds

Targets and thresholds are absolute values on the shared radial numeric axis.
They never change a category's angular band or convert a value into a share.

Use `targets` for a category-specific benchmark and `PolarThreshold` for one
reference value that applies across the whole pane:

```dart
final actual = PolarColumnChartSeries.fromMap(
  id: 'actual',
  name: 'Actual',
  unit: 'orders',
  values: const {'Search': 74, 'Social': 56, 'Partners': 83},
  targets: const {'Search': 78, 'Social': 62, 'Partners': 80},
  targetMarkerStyle: const PolarColumnTargetMarkerStyle(
    color: Color(0xFFF59E0B),
    width: 3,
    lengthFactor: 0.68,
  ),
);

BravenChartPlus(
  series: [actual],
  polarChartConfig: const PolarChartConfig(
    thresholds: [
      PolarThreshold(
        value: 80,
        label: 'Capacity',
        color: Color(0xFFDC2626),
        dashPattern: [7, 4],
      ),
    ],
  ),
);
```

`targets` may omit categories; omitted categories have no marker. Supplying an
unknown category is rejected so a target cannot silently drift to the wrong
column. In grouped composition, each target occupies its own series sub-band.
In stacked composition, targets remain absolute axis references rather than
cumulative stack contributions.

Automatic radial domains include every finite target and threshold. With an
explicit radial domain, an out-of-range reference remains available to tables,
artifacts, and generated Source but is not painted outside the pane. Target
ticks remain fixed when a selected column explodes or lifts, preserving the
visual comparison.

## Polar pane and axes

`PolarChartConfig` groups plot-level concerns so they do not leak into Pie,
Donut, or Cartesian configuration.

### Pane

`PolarPaneConfig` controls:

- `startAngleDegrees` and `sweepAngleDegrees`;
- clockwise or counter-clockwise category order;
- inner and outer radius factors;
- whether marks are clipped to the allocated pane.

A 360-degree pane paints radial grid, baseline, and threshold references as
closed circles. Partial panes paint those references as arcs that follow the
configured start angle, sweep, and direction.

A full sweep uses `360`. Partial sweeps retain a real start and end boundary.
The inner radius changes the baseline into an annular opening; it does not turn
the chart into a Donut because angle still represents category position, not
share.

### Angular category axis

`PolarCategoryAxisConfig` owns stable category bands:

- `innerPadding` removes a fraction of each category step between columns;
- `outerPadding` reserves step fractions before and after the collection;
- category labels and angular grid lines can be shown independently.

Padding changes available mark width only. It never changes category order or
value.

### Radial numeric axis

`PolarNumericAxisConfig` owns the numeric domain, tick count, label/grid
visibility, and scale mode.

- `linear` maps equal value differences to equal radial distances;
- `areaCorrect` maps equal value proportions to equal annular-sector areas.

Polar rings and angular grid spokes use `ChartTheme.gridStyle`: set
`majorColor`, `majorLineWidth`, and `majorDashPattern` to style them together.
An empty dash pattern is solid; values such as `[7, 4]` or `[2, 3]` create
dashed or dotted treatments. Pane boundaries and the numeric axis continue to
use `ChartTheme.axisStyle`, so decorative grid patterns do not weaken the
structural frame.

When `scaleMode` is omitted, standard Polar Column uses linear radius and the
Rose preset uses area-correct scaling. Set an explicit minimum/maximum when
several independently mounted charts must share a comparison domain.
Automatic domains always include zero. Ordinary signed columns diverge from
that zero baseline; when an ordinary explicit domain excludes zero, the mark
uses the nearest domain edge as its baseline. Stacked explicit domains must
contain zero.

## Nightingale/Rose preset

```dart
final seasonal = PolarColumnChartSeries.rose(
  id: 'seasonal-volume',
  name: 'Monthly volume',
  unit: 'k requests',
  values: const {
    'Jan': 42,
    'Feb': 58,
    'Mar': 76,
    'Apr': 63,
    'May': 88,
    'Jun': 54,
  },
);
```

Rose is a preset of the same axis-based family, not a Pie renderer. Every
category receives equal angular bandwidth. Area-correct scaling prevents a
radius from visually exaggerating the encoded magnitude.

## Styling and selection

```dart
final styled = PolarColumnChartSeries.fromMap(
  id: 'conversion',
  values: const {'Discover': 84, 'Trial': 73, 'Adopt': 91},
  polarStyle: const PolarColumnStyle(
    cornerRadius: 8,
    cornerRadiusMode: PolarColumnCornerRadiusMode.stackExterior,
    opacity: 0.94,
    borderColor: Color(0xFF312E81),
    borderWidth: 0.8,
    showDataLabels: true,
    dataLabelRadialPosition: 0.68,
    dataLabelStyle: PolarLabelStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
    gradient: PolarColumnGradientStyle(
      startLightnessShift: 0.18,
      endLightnessShift: -0.14,
    ),
    shadow: PolarColumnShadowStyle(
      blurRadius: 10,
      offset: Offset(0, 4),
      opacity: 0.28,
    ),
    animationMode: PolarColumnAnimationMode.grow,
  ),
  selectionStyle: const RadialSelectionStyle(
    effect: RadialSelectionEffect.lift,
    liftScale: 1.07,
    liftOffset: 7,
    backdropBlur: 1,
  ),
);
```

Per-category colors come from `columnColors` or each point's `PointStyle`.
Otherwise the series color and chart theme palette provide deterministic
fallbacks. Direct value labels automatically choose black or white text from
the resolved column luminance when `dataLabelStyle.color` is null.

`dataLabelRadialPosition` moves a direct value label through its own physical
column depth: `0` is the edge nearest the chart center, `0.5` centers it, and
`1` is the edge nearest the pane boundary. This convention stays stable for
negative and stacked values and does not alter value or mark geometry.

`PolarColumnGradientStyle` runs from the numeric baseline to the represented
value. Omitted colors derive lighter and darker variants from each resolved
category/series color, so grouped and stacked identity remains intact. Supply
`startColor` or `endColor` for a fixed gradient. `PolarColumnShadowStyle`
paints configurable color, blur, spread, offset, and opacity beneath each
mark; null color derives a darker shade from the mark.

`PolarColumnAnimationMode.grow` reveals geometry from the numeric baseline;
`sweep` reveals final mark geometry continuously from the configured pane start
angle in its configured direction; `fade` retains final geometry while fading
its mark appearance; `none` renders
the final frame immediately. Call
`BravenChartController.replayRadialEntrance()` to replay the configured mode.
Reduced-motion environments and zero-duration animation themes still resolve
directly to the final frame.

### Label placement and appearance

Category, direct-value, and radial-axis labels use separate public settings:

```dart
const config = PolarChartConfig(
  angularAxis: PolarCategoryAxisConfig(
    labelOffset: 12,
    labelStyle: PolarLabelStyle(
      color: Color(0xFF334155),
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  ),
  radialAxis: PolarNumericAxisConfig(
    labelPosition: PolarRadialLabelPosition.end,
    labelAngleOffsetDegrees: -15,
    labelOffset: 6,
    labelStyle: PolarLabelStyle(
      color: Color(0xFF0D9488),
      fontSize: 11,
    ),
  ),
);
```

`PolarCategoryAxisConfig.labelOffset` is an outward radial distance from the
compact default category-label anchor. `PolarNumericAxisConfig.labelPosition`
chooses the start, middle, or end ray of the configured sweep;
`labelAngleOffsetDegrees` rotates that ray and `labelOffset` moves labels along
it. Null `PolarLabelStyle` properties inherit the active chart theme.

`PolarColumnCornerRadiusMode` makes corner placement explicit:

- `bothEnds` rounds the inner- and outer-radius ends of every column;
- `outerEnd` rounds only each mark's geometric outer-radius end and preserves
  the original/default Polar Column appearance;
- `stackExterior` keeps internal stacked seams square and rounds only the
  exposed signed-stack boundary. The terminal positive contributor rounds
  outward; the terminal negative contributor rounds inward. On a non-stacked
  chart it rounds the value end.

The corner mode, radius, and stack-terminal identity survive generated source,
artifact transport, and hydration. A non-default mode declares
`series.polar.column.corner-radius-mode.v1` so an older runtime cannot silently
substitute a different shape.

Non-default fill/elevation/value-label/motion properties declare
`series.polar.column.appearance.v1`. Non-default category or radial-axis label
appearance declares `chart.polar.labels.v1`. Hydration requires those
capabilities before interpreting the corresponding portable configuration.

Selection identity is not a paint-only state. Pointer activation, keyboard
activation, a Workbench table row, and `BravenChartController` all use the same
`ChartPointRef(seriesId, pointIndex)`. Tooltip anchors and hit paths follow the
current selected geometry.

## Uncertainty and range intervals

Intervals are absolute endpoints on the same radial scale as the column. They
do not represent deltas and do not change the source column value.

```dart
final forecast = PolarColumnChartSeries.fromMap(
  id: 'forecast',
  unit: 'orders',
  values: const {'Search': 72, 'Social': 58, 'Partners': 81},
  intervals: const {
    'Search': PolarColumnInterval(lower: 63, upper: 84),
    'Social': PolarColumnInterval(lower: 49, upper: 69),
    'Partners': PolarColumnInterval(lower: 70, upper: 94),
  },
  intervalStyle: const PolarColumnIntervalStyle(
    display: PolarColumnIntervalDisplay.whisker,
    width: 2,
    capLengthFactor: 0.62,
  ),
);
```

`PolarColumnIntervalDisplay.whisker` draws a radial stem with tangential caps.
`band` draws a compact annular sector between the endpoints. Automatic domains
include exact interval endpoints. Explicit domains clip the visible geometry
to the pane while tables, artifacts, tooltips, and generated source retain the
original values. Intervals are valid on ordinary, layered, and grouped
columns. They are deliberately rejected on stacked contributors because an
absolute source interval has no unambiguous cumulative stack position.

## Native Data and Workbench

The native table is deliberately value-based:

```text
# | Category | Series | Value (unit) | Target (unit) | Lower (unit) | Upper (unit)
```

Target and interval columns appear only when at least one series carries the
corresponding values.
The table does not invent a Share column. Sorting, row copy, full-data copy,
CSV, focus, and activation preserve the original category/value model.

```dart
BravenChartWorkbench(
  availableDisplayModes: const {
    ChartDisplayMode.chart,
    ChartDisplayMode.data,
    ChartDisplayMode.split,
    ChartDisplayMode.source,
  },
  chartBuilder: (context, controller) => BravenChartPlus(
    bravenChartController: controller,
    series: [series],
    polarChartConfig: config,
  ),
)
```

The chart supplied by `chartBuilder` remains mounted while the Workbench
projects Data or Source from its effective document. Split mode uses the same
resizable, revision-safe table surface as the other built-in families.

## Artifacts, hydration, and generated source

Polar Column uses the stable artifact capability
`series.polar.column.v1`. A document with more than one compatible series also
declares `chart.polar.multiple-series.v1`, allowing older runtimes to fail
capability negotiation before attempting an unsupported composition. A grouped
document additionally declares `chart.polar.grouped-series.v1`; a stacked
document declares `chart.polar.stacked-series.v1`. The document stores:

- every source category, value, color, unit, and stable point identity;
- series preset, column style, and selection presentation;
- pane, angular axis, radial numeric axis, and composition configuration;
- per-category targets, target-marker style, pane thresholds, exact lower/upper
  intervals, and their whisker or annular-band presentation;
- portable view state, including durable point selection when requested.

`ChartArtifactJsonCodec` produces deterministic JSON and
`ChartDocumentHydrator` restores a fresh `BravenChartPlus` with the same polar
configuration. Incompatible multi-series or mixed-family documents fail
explicitly rather than hydrating as Bar or Pie.

The Workbench Source view uses `ChartDartSourceGenerator`. Generated Polar
Dart includes the public constructor, pane, both axes, styles, and literal
integer tick counts, and is compile-checked by the package test suite.

Documents containing targets declare `series.polar.column.targets.v1`.
Documents containing pane thresholds declare `chart.polar.thresholds.v1`.
Documents containing intervals declare `series.polar.column.intervals.v1`.
Documents containing the appearance or label-placement additions declare
`series.polar.column.appearance.v1` or `chart.polar.labels.v1` respectively.
Hydration requires those capabilities before interpreting the corresponding
configuration.

## Interaction and accessibility

- pointer hover resolves the exact annular-sector path and tooltip anchor;
- pointer, table, and controller activation share durable selection;
- arrow keys traverse stable angular category order across each declared
  series;
- Enter or Space selects the focused column;
- Escape clears selection;
- semantics expose category, formatted value/unit, ordinal position, focus,
  and selection without describing a percentage share;
- disabling axis labels does not remove the table or semantic data.
- angular axis labels are thinned in stable ordinal order when the available
  arc cannot fit every label at the active text scale, with
  `PolarCategoryAxisConfig.maximumVisibleLabels` providing an explicit upper
  bound (24 by default);
- angular grid spokes use the same deterministic ordinal thinning through
  `maximumVisibleGridLines` (72 by default);
- direct value labels render only when the mark has enough radial and
  tangential room and remain within
  `PolarColumnStyle.maximumVisibleDataLabels` (24 by default), while tooltips,
  semantics, tables, exports, artifacts, and generated source retain every
  value.

The renderer resolves those visible-label sets once when constructing the
series element and uses a cheap geometric fit check before measuring text.
The regression benchmark paints a 512-category element in under one 60 Hz
frame on the package's test host. Treat that as a deterministic regression
envelope rather than a universal device limit; profile the target platform
when presenting unusually dense or heavily styled panes.

Use visible category labels or a nearby explanatory table for unfamiliar
categories. For dense cycles, keep labels short, retain meaningful units,
choose caps appropriate to the pane, and verify compact, large-text, table,
keyboard, and screen-reader paths.

## Current boundaries

Polar Column currently excludes:

- mixed Cartesian/polar plots;
- zoom and pan;
- Radial Bar, Gauge, Radar, and Sunburst semantics.

Those features require their own polar-scale and table contracts. They are not
enabled by repurposing Pie shares or rotating Cartesian Bar geometry.
