# Chart types

Braven Charts renders six first-class series types through
`BravenChartPlus`: line, area, bar, scatter, Pie, and Donut. Line, area, bar,
and scatter use the Cartesian layout and may share one chart. Pie and Donut use
the radial layout and are intentionally single-series charts.

Import only the public package entrypoint:

```dart
import 'package:braven_charts/braven_charts.dart';
```

## Choose the right series

| Series | Use it for | Key configuration |
| --- | --- | --- |
| `LineChartSeries` | Trends and ordered measurements | interpolation, stroke, markers, labels, glow, path motion |
| `AreaChartSeries` | Trends where magnitude or distance from a baseline matters | interpolation, fill opacity, baseline colors, path motion |
| `BarChartSeries` | Discrete comparisons and grouped values | relative or fixed bar width |
| `ScatterChartSeries` | Relationships, distributions, and unconnected observations | marker radius and point styling |
| `PieChartSeries` | Parts of one meaningful whole | slice geometry, labels, legend, selection |
| `DonutChartSeries` | Parts of one whole with a meaningful center | inner radius, partial sweep, center content, selection |

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

`x` and `y` are the plotted Cartesian coordinates. For Pie and Donut, `x` is a
stable ordering ordinal, `y` is the contribution, and `label` is the category.
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
      pathAnimation: PathAnimationStyle(
        entranceMode: PathEntranceAnimationMode.reveal,
        dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
      ),
    ),
  ],
  xAxisConfig: const XAxisConfig(label: 'Month'),
  yAxis: const YAxisConfig(label: 'Revenue', unit: 'USD'),
)
```

Use monotone interpolation when the curve must not overshoot the source
values. Use stepped interpolation for state changes. Markers and data labels
are useful for small datasets but add visual and rendering cost at scale.

Path motion is opt-in. `reveal` clips the normal Line renderer from the leading
edge, while `interpolate` moves compatible point updates through the same
geometry used for hit testing, tooltips, crosshairs, and labels. Timing and
easing come from `ChartTheme.animationTheme.dataUpdateDuration` and
`dataUpdateCurve`.

Updates interpolate only when the series ID, series type, interpolation mode,
point count, and point identities remain compatible. Topology changes fall
back to the configured entrance reveal. Reduced-motion preferences and a
zero-duration theme always render the final frame immediately.

Attach a `BravenChartController` to replay the configured entrance:

```dart
final controller = BravenChartController();

BravenChartPlus(
  bravenChartController: controller,
  series: series,
);

controller.replaySeriesEntrance();
```

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
  pathAnimation: PathAnimationStyle(
    entranceMode: PathEntranceAnimationMode.reveal,
    dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
  ),
)
```

Avoid overlapping many opaque areas. Lower the opacity or use a line when the
overlap makes individual series hard to read.

Area fill, stroke, glow, markers, and labels share one reveal boundary. During
compatible value updates, the fill and outline interpolate as one canonical
series rather than as independent paint effects.

## Chart and data workbench

Line and Area work with the package-owned Chart/Data/Split surface. The chart
stays mounted as users inspect the native table, and the wide Split divider is
pointer- and keyboard-resizable.

```dart
final chartController = BravenChartController();

BravenChartWorkbench(
  chartController: chartController,
  splitBreakpoint: 760,
  autoFitTablePane: true,
  tableRefreshPolicy: ChartTableRefreshPolicy.onDocumentRevision,
  chartBuilder: (context, controller) => BravenChartPlus(
    bravenChartController: controller,
    series: series,
  ),
)
```

The table and extracted artifacts use target data while an animation is in
progress; transient frames are strictly a rendering concern.

The showcase routes accept review-friendly query parameters. For example,
`?page=line-charts&preset=motion&view=split` and
`?page=area-charts&preset=motion&view=split` open the complete motion and
workbench surfaces directly.

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
      cornerTreatment: PieCornerTreatment.circularCenter,
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

To compare a second metric, provide one `radiusValues` entry per category and
a `PieSliceRadiusConfig`. Angular share remains driven by `values`; radius is
normalized independently, shown in tooltips and the native table, and
transported with capability `series.pie.variable-radius.v1`.

See the complete [Pie chart guide](../../doc/pie_charts.md) for labels,
palettes, solid or gradient fills, callouts, tooltips, legends,
three corner treatments, translucent slices, elevation, animation, selection,
tables,
artifacts, variable radii, AI configuration, and accessibility.

## Donut charts

Donut keeps Pie's ordered category contract and adds a validated shared inner
radius, optional partial sweep, and portable center content.

```dart
final donut = DonutChartSeries.fromMap(
  id: 'revenue-share',
  name: 'Revenue share',
  unit: 'USD',
  values: const {
    'Subscriptions': 42,
    'Services': 31,
    'Hardware': 27,
  },
  donutStyle: const DonutChartStyle(
    innerRadiusFactor: 0.58,
    sweepAngleDegrees: 360,
    sliceGap: 2,
    cornerRadius: 8,
  ),
  centerContent: const DonutCenterContent(
    label: 'Revenue',
    valueMode: DonutCenterValueMode.selectedOrTotal,
  ),
);

BravenChartPlus(series: [donut]);
```

The center supports total, selected value, selected-or-total, and custom text.
It follows the same `ChartPointRef` selected from a slice, legend, native table,
keyboard, or `BravenChartController`. Center text is measured inside the real
opening and is included in preview images and portable artifacts.

Donut documents declare `series.donut` plus `series.donut.style.v1`. Visible
center content declares `series.donut.center-content.v1`; a second radius
metric declares `series.donut.variable-radius.v1`.

See the complete [Donut chart guide](../../doc/donut_charts.md) for geometry,
center styling, selection, tables, artifacts, AI configuration, theming,
validation, and accessibility.

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

Do not add a Pie or Donut series to this list. Mixed radial/Cartesian composition fails
explicitly instead of silently dropping or misrendering data.

## Convenience factories

`BravenChartPlus.fromValues` accepts line, area, bar, and scatter. It rejects
Pie and Donut because numeric values alone cannot provide accessible category labels.

`BravenChartPlus.fromMap` treats keys as numeric X values for Cartesian chart
types. With `chartType: ChartType.pie` or `ChartType.donut`, keys become
category strings and map insertion order becomes slice order.

`BravenChartPlus.fromJson` accepts point objects with `x`, `y`, and optional
`label`. Pie and Donut JSON must provide a non-empty label on every point.

For product code, explicit series constructors are usually clearer because
they expose the full type-specific configuration.

## Interaction and data tables

Cartesian charts may use pan, zoom, scrollbars, crosshairs, tracking, and point
tooltips. Pie and Donut use slice hover, tooltip, tap selection, legend selection,
arrow-key traversal, Enter/Space activation, and Escape clear.

`ChartTableModel.fromDocument` projects Cartesian documents into exact-X wide
or lossless long rows. A Pie or Donut document automatically becomes:

```text
# | Category      | Value (USD) | Share
1 | Subscriptions | 42.00       | 42.00%
```

Pass the chart controller's `selectedPointRefs` to `ChartDataTable` and use
row callbacks with the same document revision to link selection in both
directions. `BravenChartWorkbench` provides this linking by default.

## Themes, responsiveness, and accessibility

All series inherit `ChartTheme` colors unless a series or point provides an
override. Pie and Donut resolve one palette color per visible slice and keep category
text in labels or the legend, so color is never the only cue.

Radial outside labels are lane-managed and may hide the lowest-priority labels
when a compact viewport cannot fit all text. The legend and native data table
remain complete. Inside labels are omitted when the text does not fit the
slice. `MediaQuery.disableAnimationsOf` removes selection motion, and slice
semantics announce category, formatted value, share, ordinal, and state.

## Portable documents

Every built-in series encodes through `ChartSeriesDocumentCodec`. Pie declares
`series.pie`; Donut declares `series.donut`. Older readers that do not support
the required capability reject the document rather than interpreting it as a Cartesian series. Artifact capture,
canonical JSON, previews, hydration, and table export all preserve point
identity and type-specific configuration.

## Runnable examples

- [Chart Types](https://braven-pvm.github.io/braven_charts/?page=chart-types)
  compares all six series types.
- [Pie Charts](https://braven-pvm.github.io/braven_charts/?page=pie-charts)
  demonstrates labels, geometry, linked data, capture, preview, and restore.
- [Donut Charts](https://braven-pvm.github.io/braven_charts/?page=donut-charts)
  demonstrates center content, partial sweeps, linked data, and transport.
- [Gallery](https://braven-pvm.github.io/braven_charts/) demonstrates radial
  and mixed Cartesian product compositions.
