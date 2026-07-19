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
| `polarStyle` | Corners, opacity, border, and direct value-label visibility |
| `selectionStyle` | Explode or lift treatment for durable point selection |

The `fromMap` and `rose` constructors create the required ordinal X values and
copy each map key into the point label. The direct constructor remains useful
when points carry metadata or explicit per-point styles.

V1 accepts one non-empty series with finite, non-negative values. It rejects
duplicate or blank category labels, unstable ordinals, Cartesian/polar mixing,
and multi-series composition instead of guessing a layout.

## Polar pane and axes

`PolarChartConfig` groups plot-level concerns so they do not leak into Pie,
Donut, or Cartesian configuration.

### Pane

`PolarPaneConfig` controls:

- `startAngleDegrees` and `sweepAngleDegrees`;
- clockwise or counter-clockwise category order;
- inner and outer radius factors;
- whether marks are clipped to the allocated pane.

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

When `scaleMode` is omitted, standard Polar Column uses linear radius and the
Rose preset uses area-correct scaling. Set an explicit minimum/maximum when
several independently mounted charts must share a comparison domain.

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
    opacity: 0.94,
    borderColor: Color(0xFF312E81),
    borderWidth: 0.8,
    showDataLabels: true,
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
the resolved column luminance.

Selection identity is not a paint-only state. Pointer activation, keyboard
activation, a Workbench table row, and `BravenChartController` all use the same
`ChartPointRef(seriesId, pointIndex)`. Tooltip anchors and hit paths follow the
current selected geometry.

## Native Data and Workbench

The native table is deliberately value-based:

```text
# | Category | Series | Value (unit)
```

It does not invent a Share column. Sorting, row copy, full-data copy, CSV,
focus, and activation preserve the original category/value model.

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
`series.polar.column.v1`. The document stores:

- every source category, value, color, unit, and stable point identity;
- series preset, column style, and selection presentation;
- pane, angular axis, and radial numeric axis configuration;
- portable view state, including durable point selection when requested.

`ChartArtifactJsonCodec` produces deterministic JSON and
`ChartDocumentHydrator` restores a fresh `BravenChartPlus` with the same polar
configuration. Unsupported multi-series or mixed-family documents fail
explicitly rather than hydrating as Bar or Pie.

The Workbench Source view uses `ChartDartSourceGenerator`. Generated Polar
Dart includes the public constructor, pane, both axes, styles, and literal
integer tick counts, and is compile-checked by the package test suite.

## Interaction and accessibility

- pointer hover resolves the exact annular-sector path and tooltip anchor;
- pointer, table, and controller activation share durable selection;
- arrow keys traverse stable angular category order;
- Enter or Space selects the focused column;
- Escape clears selection;
- semantics expose category, formatted value/unit, ordinal position, focus,
  and selection without describing a percentage share;
- disabling axis labels does not remove the table or semantic data.
- angular axis labels are thinned in stable ordinal order when the available
  arc cannot fit every label at the active text scale;
- direct value labels render only when the mark has enough radial and
  tangential room, while tooltips, semantics, tables, and exports retain every
  value.

Use visible category labels or a nearby explanatory table for unfamiliar
categories. For dense cycles, keep labels short, retain meaningful units, and
verify both compact and large-text layouts.

## V1 boundaries

Polar Column V1 intentionally excludes:

- multiple Polar series, grouping, and stacking;
- negative or floating radial ranges;
- targets, uncertainty intervals, and thresholds;
- mixed Cartesian/polar plots;
- zoom and pan;
- Radial Bar, Gauge, Radar, and Sunburst semantics.

Those features require their own polar-scale and table contracts. They are not
enabled by repurposing Pie shares or rotating Cartesian Bar geometry.
