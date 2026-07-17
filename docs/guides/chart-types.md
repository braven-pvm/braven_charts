# Chart types

Braven Charts renders five first-class series types through
`BravenChartPlus`: line, area, bar, scatter, and pie. Line, area, bar, and
scatter use the Cartesian layout and may share one chart. Pie uses the radial
layout and is intentionally a single-series chart.

Import only the public package entrypoint:

```dart
import 'package:braven_charts/braven_charts.dart';
```

## Choose the right series

| Series | Use it for | Key configuration |
| --- | --- | --- |
| `LineChartSeries` | Trends and ordered measurements | interpolation, stroke, markers, labels, glow |
| `AreaChartSeries` | Trends where magnitude or distance from a baseline matters | interpolation, fill opacity, baseline colors |
| `BarChartSeries` | Discrete comparisons and grouped values | relative or fixed bar width |
| `ScatterChartSeries` | Relationships, distributions, and unconnected observations | marker radius and point styling |
| `PieChartSeries` | Parts of one meaningful whole | slice geometry, labels, legend, selection |

Use pie only when every category contributes to the same total. Use bars when
precise comparison matters more than contribution to a whole, when values may
be negative, or when the number of categories is too dense for readable
slices.

## Shared data model

Every series uses stable `ChartDataPoint` values:

```dart
const points = [
  ChartDataPoint(x: 1, y: 42, label: 'January'),
  ChartDataPoint(x: 2, y: 51, label: 'February'),
  ChartDataPoint(x: 3, y: 47, label: 'March'),
];
```

`x` and `y` are the plotted Cartesian coordinates. For pie, `x` is a stable
ordering ordinal, `y` is the contribution, and `label` is the category.
`ChartPointRef(seriesId, pointIndex)` remains the portable identity across
charts, tables, artifacts, and restored runtimes.

## Line charts

Line series support linear, Bezier, stepped, and monotone interpolation.

```dart
BravenChartPlus(
  series: const [
    LineChartSeries(
      id: 'revenue',
      name: 'Revenue',
      unit: 'USD',
      points: points,
      interpolation: LineInterpolation.monotone,
      strokeWidth: 2.5,
      showDataPointMarkers: true,
    ),
  ],
  xAxisConfig: const XAxisConfig(label: 'Month'),
  yAxis: const YAxisConfig(label: 'Revenue', unit: 'USD'),
)
```

Use monotone interpolation when the curve must not overshoot the source
values. Use stepped interpolation for state changes. Markers and data labels
are useful for small datasets but add visual and rendering cost at scale.

## Area charts

Area series share line interpolation and add a fill. A baseline can split the
fill into above/below colors.

```dart
AreaChartSeries(
  id: 'variance',
  name: 'Variance',
  points: points,
  interpolation: LineInterpolation.bezier,
  fillOpacity: 0.28,
  baselineValue: 0,
  aboveBaselineFillColor: Color(0x6634A853),
  belowBaselineFillColor: Color(0x66EA4335),
)
```

Avoid overlapping many opaque areas. Lower the opacity or use a line when the
overlap makes individual series hard to read.

## Bar charts

Bar series compare discrete values. `barWidthPercent` uses the available X
spacing; `barWidthPixels` requests a fixed width. Supply one of them.

```dart
BarChartSeries(
  id: 'completed',
  name: 'Completed',
  points: points,
  barWidthPercent: 0.64,
)
```

Multiple bar series at the same X values are grouped automatically. Preserve
the same X domain across grouped series so the comparison remains meaningful.

## Scatter charts

Scatter series render independent markers without connecting lines.

```dart
ScatterChartSeries(
  id: 'samples',
  name: 'Samples',
  points: points,
  markerRadius: 5,
)
```

Use point-level styles when individual observations need distinct colors or
shapes. Use segment styling on line, area, or bar series when the style follows
a rule across values.

## Pie charts

`PieChartSeries.fromMap` is the shortest safe constructor. Dart map insertion
order becomes stable slice order.

```dart
final pie = PieChartSeries.fromMap(
  id: 'revenue-share',
  name: 'Revenue share',
  unit: 'USD',
  values: const {
    'Subscriptions': 42,
    'Services': 31,
    'Hardware': 27,
  },
  pieStyle: const PieChartStyle(
    startAngleDegrees: -90,
    clockwise: true,
    radiusFactor: 0.86,
    sliceGap: 2,
    borderWidth: 1,
    gradient: PieGradientStyle(
      type: PieGradientType.radial,
      startLightnessShift: 0.18,
      endLightnessShift: -0.12,
    ),
    selectionExplodeOffset: 10,
  ),
  dataLabels: const PieDataLabelConfig(
    position: PieDataLabelPosition.outside,
    content: PieDataLabelContent.categoryAndPercentage,
    outsideOffset: 0,
    collisionStrategy: PieDataLabelCollisionStrategy.shiftAndHide,
  ),
);

BravenChartPlus(
  series: [pie],
  showLegend: true,
  theme: ChartTheme.light.copyWith(
    legendStyle: ChartTheme.light.legendStyle.copyWith(
      position: LegendPosition.centerRight,
      orientation: LegendOrientation.vertical,
    ),
    pieChartTheme: const PieChartTheme(
      cornerRadius: 10,
      selectedElevation: PieElevationStyle(
        blurRadius: 12,
        spreadRadius: 2,
        opacity: 0.5,
      ),
    ),
  ),
  interactionConfig: const InteractionConfig(
    tooltip: TooltipConfig(enabled: true),
  ),
)
```

Pie has these enforced boundaries:

- exactly one `PieChartSeries` per chart;
- no Cartesian series, axes, crosshair, pan, zoom, or scrollbars;
- finite, non-negative contributions and non-empty category labels;
- zero values remain portable but do not paint a slice;
- an all-zero series uses `ChartEmptyStateConfig`;
- duplicate category labels are allowed because point index, not label, is the
  stable identity.

See the complete [Pie chart guide](../../doc/pie_charts.md) for labels,
palettes, solid or gradient fills, callouts, tooltips, legends,
rounded/translucent slices, elevation, animation, selection, tables,
artifacts, AI configuration, and accessibility.

## Mixed Cartesian charts

Line, area, bar, and scatter series may share one `BravenChartPlus`. Give every
series a unique ID. Use `yAxisConfig` or `yAxisId` when units or scales differ:

```dart
BravenChartPlus(
  normalizationMode: NormalizationMode.perSeries,
  series: [
    LineChartSeries(
      id: 'power',
      name: 'Power',
      unit: 'W',
      points: powerPoints,
      yAxisConfig: const YAxisConfig(label: 'Power', unit: 'W'),
    ),
    ScatterChartSeries(
      id: 'events',
      name: 'Events',
      points: eventPoints,
      yAxisId: 'power',
    ),
  ],
)
```

Do not add a pie series to this list. Mixed radial/Cartesian composition fails
explicitly instead of silently dropping or misrendering data.

## Convenience factories

`BravenChartPlus.fromValues` accepts line, area, bar, and scatter. It rejects
pie because numeric values alone cannot provide accessible category labels.

`BravenChartPlus.fromMap` treats keys as numeric X values for Cartesian chart
types. With `chartType: ChartType.pie`, keys become category strings and map
insertion order becomes slice order.

`BravenChartPlus.fromJson` accepts point objects with `x`, `y`, and optional
`label`. Pie JSON must provide a non-empty label on every point.

For product code, explicit series constructors are usually clearer because
they expose the full type-specific configuration.

## Interaction and data tables

Cartesian charts may use pan, zoom, scrollbars, crosshairs, tracking, and point
tooltips. Pie uses slice hover, tooltip, tap selection, legend selection,
arrow-key traversal, Enter/Space activation, and Escape clear.

`ChartTableModel.fromDocument` projects Cartesian documents into exact-X wide
or lossless long rows. A pie document automatically becomes:

```text
# | Category      | Value (USD) | Share
1 | Subscriptions | 42.00       | 42.00%
```

Pass the chart controller's `selectedPointRefs` to `ChartDataTable` and use
row callbacks with the same document revision to link selection in both
directions. `BravenChartWorkbench` provides this linking by default.

## Themes, responsiveness, and accessibility

All series inherit `ChartTheme` colors unless a series or point provides an
override. Pie resolves one palette color per visible slice and keeps category
text in labels or the legend, so color is never the only cue.

Pie outside labels are lane-managed and may hide the lowest-priority labels
when a compact viewport cannot fit all text. The legend and native data table
remain complete. Inside labels are omitted when the text does not fit the
slice. `MediaQuery.disableAnimationsOf` removes selection motion, and slice
semantics announce category, formatted value, share, ordinal, and state.

## Portable documents

Every built-in series encodes through `ChartSeriesDocumentCodec`. Pie declares
the `series.pie` capability. Older readers that do not support it reject the
document rather than interpreting it as a Cartesian series. Artifact capture,
canonical JSON, previews, hydration, and table export all preserve point
identity and type-specific configuration.

## Runnable examples

- [Chart Types](https://braven-pvm.github.io/braven_charts/?page=chart-types)
  compares all five series types.
- [Pie Charts](https://braven-pvm.github.io/braven_charts/?page=pie-charts)
  demonstrates labels, geometry, linked data, capture, preview, and restore.
- [Gallery](https://braven-pvm.github.io/braven_charts/) demonstrates mixed
  Cartesian product compositions.
