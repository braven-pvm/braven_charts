# Chart types

Braven Charts renders line, area, Range Area, bar, scatter, Candlestick, Pie,
Donut, Polar Column, and Radial Bar as first-class series through
`BravenChartPlus`. Two or more Donut series form the Concentric Donut
composition. Line, area, Range Area, bar, scatter, and Candlestick use the
Cartesian layout. Pie and standalone Donut are single-series partition-radial
charts; Concentric Donut is multi-series; Polar Column uses angular categories
and a numeric radial axis; Radial Bar uses concentric categories and an
explicit angular numeric scale.

Import only the public package entrypoint:

```dart
import 'package:braven_charts/braven_charts.dart';
```

## Choose the right series

| Series | Use it for | Key configuration |
| --- | --- | --- |
| `LineChartSeries` | Trends and ordered measurements | interpolation, stroke, markers, labels, glow, path motion |
| `AreaChartSeries` | Trends where magnitude or distance from a baseline matters | interpolation, solid or gradient fill, baseline colors, path motion |
| `RangeAreaChartSeries` | Paired low/high envelopes and uncertainty | atomic intervals, gaps, boundaries, gradient fill, typed tracking and motion |
| `BarChartSeries` | Discrete comparisons and grouped values | relative or fixed bar width |
| `ScatterChartSeries` | Relationships, distributions, and unconnected observations | marker radius and point styling |
| `CandlestickChartSeries` | Ordered open-high-low-close observations | body and wick geometry, direction theme, OHLC motion, density grouping |
| `PieChartSeries` | Parts of one meaningful whole | slice geometry, labels, legend, selection |
| `DonutChartSeries` | Parts of one whole with a meaningful center | inner radius, partial sweep, center content, selection |
| two or more `DonutChartSeries` | Compare several independent wholes | ring allocation, weights, grouped legend, shared center |
| `PolarColumnChartSeries` | Cyclical categories whose magnitude grows outwards | angular categories, radial scale, composition |
| `RadialBarChartSeries` | Independent category progress or signed values on concentric tracks | explicit domain and baseline, pane, track geometry, thresholds |

Use pie only when every category contributes to the same total. Use bars when
precise comparison matters more than contribution to a whole, when values may
be negative, or when the number of categories is too dense for readable
slices.

Use Radial Bar when every ring is an independent absolute value on the same
known scale. It is not a multi-ring Donut: values are not divided by a
per-ring total. See the complete
[Radial Bar guide](radial-bar-charts.md) and runnable `?page=radial-bar`
showcase.

## Shared data model

Every series uses stable `ChartDataPoint` values:

```dart
const points = [
  ChartDataPoint(x: 1, y: 42, label: 'January'),
  ChartDataPoint(x: 2, y: 51, label: 'February'),
  ChartDataPoint(x: 3, y: 47, label: 'March'),
];
```

`x` and `y` are the plotted Cartesian coordinates. For Pie, Donut, and Radial
Bar, `x` is a stable ordering ordinal and `label` is the category. Pie and
Donut interpret `y` as a contribution; Radial Bar interprets `y` as an
absolute value inside its explicit numeric domain.
`ChartPointRef(seriesId, pointIndex)` remains the portable identity across
charts, tables, artifacts, and restored runtimes.

## Durable selection and extraction

Selection separates acquisition geometry from semantic meaning. A direct
point, X/Y interval, rectangle, or lasso first acquires rendered marks;
`ChartSelectionScope` then resolves those hits as individual data marks, a
shared category, one compatible composition stack, or a complete series.
`markOrWholeSeries` permits either a nearby mark or the surrounding Line/Area
path to win, but never selects both from one action.

```dart
final controller = BravenChartController();

BravenChartPlus(
  bravenChartController: controller,
  interactionConfig: const InteractionConfig(
    selection: ChartSelectionConfig(
      acquisitionMode: ChartSelectionAcquisitionMode.point,
      scope: ChartSelectionScope.markOrWholeSeries,
    ),
  ),
  series: series,
);
```

Shift adds, Ctrl/Command toggles, Alt subtracts, and an unmodified action uses
the configured `ChartSelectionOperation`. Enter or Space commits through the
same semantic resolver as pointer input, so Bar category/stack, complete
series, Candlestick OHLC, Range Area tuples, Scatter marks, radial slices, and
Polar columns retain the same meaning from either input path. Shift+Space
extends an ordered Line, Area, Bar, Candlestick, Range Area, radial, or Polar
selection from its keyboard anchor. Ctrl/Command+A selects every mark only
when the result is bounded (2,000 ordinary observations, or 200 Scatter
observations), while complete-series scope selects every series compactly.

Line and Area use Left/Right to move between valid points and Up/Down to move
between series. Bar arrows follow visual category and series directions,
Scatter arrows choose the nearest point in the requested plot direction,
Candlestick and Range Area use Left/Right, and radial families traverse their
visible category order. Escape clears both focus and durable point/series
selection. Screen-reader semantics announce the family, series, observation,
formatted value, ordinal, and current selection state.

The mounted controller exposes durable references, compact expression intent,
extents, and statistics. It can also produce a detached chart document from
the current selection:

```dart
final selectedChart = controller.extractDocument(
  const ChartDocumentExtractOptions(
    dataScope: ChartDataScope.selection,
    selectionProjection: ChartSelectionProjectionOptions(
      annotationProjection:
          ChartSelectionAnnotationProjection.clipToSelectionBounds,
    ),
  ),
);
```

Line and Area interval extraction retains the selected source observations by
default, so a created chart matches the Workbench data selection exactly.
Set `intervalBoundaryProjection` to `interpolateContinuousSeries` when the
detached chart must reproduce the drag interval's exact rendered boundaries.
Candlestick OHLC tuples and Range Area low/high intervals remain atomic. The
Selection Lab (`?page=selection`) provides one comparable test surface for
every built-in family.

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
        entranceTiming: PathAnimationTiming(
          delay: Duration(milliseconds: 80),
        ),
        dataUpdateTiming: PathAnimationTiming(
          delay: Duration(milliseconds: 80),
        ),
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
geometry used for hit testing, tooltips, crosshairs, and labels. A null
`PathAnimationTiming.duration` inherits
`ChartTheme.animationTheme.dataUpdateDuration`; a series may add an explicit
non-negative delay and duration for each phase. The theme curve is applied to
each local series window. Configure each stable series ID directly rather than
deriving timing from list or paint order.

Updates interpolate only when the series ID, series type, interpolation mode,
and ordered point identities remain compatible. Equal-length values move in
place. Stable-identity appends, boundary removals, and rolling windows grow or
collapse at the nearest retained edge. Interior edits and reordered identities
fall back to the configured entrance reveal. Reduced-motion preferences and a
zero-duration theme always render the final frame immediately, even when a
series declares a non-zero delay or duration. An explicit zero series duration
also renders that series immediately and ignores its delay.

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

For a graduated fill, set `fillGradient: AreaGradient(...)`. Its `colors`,
optional normalized `stops`, and `begin`/`end` alignments are portable through
chart artifacts. `fillOpacity` multiplies each stop's alpha. Baseline fills
remain the higher-precedence mode when `baselineValue` is configured.

Avoid overlapping many opaque areas. Lower the opacity or use a line when the
overlap makes individual series hard to read.

Area fill, stroke, glow, markers, and labels share one reveal boundary. During
compatible value or boundary-topology updates, the fill and outline
interpolate as one canonical series rather than as independent paint effects.
Multiple Area layers can use independent `entranceTiming` and
`dataUpdateTiming` windows while sharing one chart-level orchestration clock.

## Range Area charts

Range Area owns one typed low/high interval per X value. Low and high drive
bounds, rendering, tracking, tables, artifacts, and semantics; the canonical
inherited Y value is the interval midpoint. Missing values use an explicit
gap rather than zero or NaN.

```dart
RangeAreaChartSeries(
  id: 'confidence',
  name: '90% confidence',
  points: [
    RangeAreaDataPoint(x: 0, low: 8, high: 14),
    RangeAreaDataPoint(x: 1, low: 9, high: 16),
    RangeAreaDataPoint.gap(x: 2),
    RangeAreaDataPoint(x: 3, low: 10, high: 18),
  ],
  interpolation: LineInterpolation.monotone,
  fillOpacity: 0.28,
)
```

Compose a separate Line series for the mean, median, forecast, or price.
Declare wider and narrower Range Area series in order for a nested forecast
fan. See the complete [Range Area guide](../../doc/range_area_charts.md) and
[runnable showcase](https://braven-pvm.github.io/braven_charts/?page=range-area-charts).

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

Scatter series render independent markers without connecting lines. X and Y
always determine position; optional point channels can independently determine
marker area, colour, and opacity.

```dart
ScatterChartSeries(
  id: 'samples',
  name: 'Samples',
  points: points,
  markerShape: SeriesMarkerShape.diamond,
  markerStyle: const ScatterMarkerStyle(
    strokeColor: Color(0xFF1E3A8A),
    strokeWidth: 1.5,
    width: 12,
    height: 12,
    rotationDegrees: 4,
  ),
)
```

Available marker shapes are circle, square, triangle, inverted triangle,
diamond, cross, plus, star, and none. `ScatterMarkerStyle` controls fill,
outline, opacity, independent width and height, and rotation. A point-level
`PointStyle` can override the series when one observation needs a distinct
marker.

### Quantitative encodings

`ChartDataPoint` has three optional Scatter-specific channels:

- `magnitude` maps to marker area through `ScatterSizeEncoding`;
- `colorValue` maps through a continuous or piecewise
  `ScatterColorEncoding`; and
- `opacityValue` maps through `ScatterOpacityEncoding`.

The channels are independent, so a single observation can carry four measures:
X, Y, area, and colour (or five when opacity is useful). Area interpolation is
perceptually correct: the configured data domain interpolates marker area, not
radius.

```dart
ScatterChartSeries(
  id: 'markets',
  name: 'Markets',
  markerShape: SeriesMarkerShape.circle,
  sizeEncoding: const ScatterSizeEncoding(
    minimumRadius: 5,
    maximumRadius: 22,
    maximumValue: 18000,
    label: 'Active accounts',
  ),
  colorEncoding: const ScatterColorEncoding(
    colors: [Color(0xFFE11D48), Color(0xFFF59E0B), Color(0xFF10B981)],
    minimumValue: 40,
    maximumValue: 95,
    label: 'Readiness',
    unit: '%',
  ),
  points: const [
    ChartDataPoint(
      x: 18,
      y: 84,
      magnitude: 6900,
      colorValue: 73,
      label: 'Partner growth',
    ),
  ],
)
```

For explicit alert categories, use
`ScatterColorScaleType.piecewise`, provide one fewer ordered threshold than
colours, and optionally name each band. Values equal to a threshold enter the
higher band. Fixed domains make charts directly comparable; omit the domain to
derive it from finite series values.

### Interaction and portability

Scatter hover, press, selection, and focus use `ScatterInteractionStyle` and
combine an outline with a geometry change so state does not rely on colour
alone. Hit testing uses the resolved marker path and both data dimensions, not
only nearest X. Unsorted series, overlapping points, rotated/non-circular
markers, encoded radii, and viewport culling retain accurate point identity.

Encoding labels and resolved values appear consistently in tracking tooltips,
quantitative legends, native tables, copy/CSV output, portable artifacts,
hydrated charts, and generated Dart source. Open the public
[Scatter guide](https://braven-pvm.github.io/braven_charts/?page=scatter-charts)
to compare the fixed, styling, stress, unsorted, interaction-state, bubble,
continuous-colour, piecewise-band, and opacity presets.

## Candlestick charts

Candlestick uses typed, strictly X-ordered `CandlestickDataPoint` values so
open, high, low, close, direction, timestamp, and source identity survive
tracking, tables, artifacts, and generated Source.

```dart
CandlestickChartSeries(
  id: 'price',
  name: 'Price',
  unit: 'USD',
  points: candles,
  candlestickStyle: const CandlestickChartStyle(
    bodyFillMode: CandlestickBodyFillMode.hollowRising,
    bodyWidthFactor: 0.72,
  ),
  animation: const CandlestickAnimationStyle(
    mode: CandlestickAnimationMode.reveal,
    dataUpdateMode: CandlestickDataUpdateAnimationMode.interpolate,
  ),
)
```

Tracking snaps to a real OHLC sample rather than interpolating financial data.
Choose elapsed-time X values to retain market gaps or ordinal session values
to collapse them. For dense views, opt-in `CandlestickDensityGrouping`
aggregates first open, maximum high, minimum low, and last close while all
Workbench and portable data remains raw.

One Candlestick series may share a plot with Line, Area, and Scatter overlays.
Volume belongs in a synchronized Bar pane with its own scale; an Area pane can
act as a full-domain navigator. See the complete
[Candlestick guide](../../doc/candlestick_charts.md) and runnable
[Candlestick showcase](https://braven-pvm.github.io/braven_charts/?page=candlestick-charts).

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
    content: PieDataLabelContent.category,
    secondaryContent: PieDataLabelContent.percentage,
    secondaryPosition: PieDataLabelPosition.inside,
    insideOffset: 0, // Positive moves outward; negative moves inward.
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

See the complete [Pie chart guide](../../doc/pie_charts.md) for single and
dual-layer labels,
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

## Concentric Donut charts

Two or more `DonutChartSeries` values activate a Concentric Donut composition.
Each ring keeps its own total; `ConcentricDonutConfig` only allocates bands and
owns the shared center.

```dart
BravenChartPlus(
  series: [currentDonut, previousDonut],
  concentricDonutConfig: const ConcentricDonutConfig(
    innerRadiusFactor: 0.28,
    outerRadiusFactor: 0.92,
    ringGap: 6,
    ringWeights: {'current': 1.25},
    legendMode: ConcentricDonutLegendMode.groupedByRing,
    centerContent: DonutCenterContent(
      label: 'Comparison',
      valueMode: DonutCenterValueMode.custom,
      customValue: '2 periods',
    ),
  ),
)
```

The table adds Ring and within-ring Share columns. Selection, tooltips,
keyboard focus, custom legend items, center builders, artifacts, previews, and
hydration retain exact series and source-point identity. See the complete
[Concentric Donut guide](../../doc/concentric_donut_charts.md).

## Mixed Cartesian charts

Line, area, bar, and scatter series may share one `BravenChartPlus`. One
Candlestick series may instead share its plot with Line, Area, and Scatter
overlays, but not Bar or another Candlestick series. Give every series a unique
ID. Use `yAxisConfig` or `yAxisId` when units or scales differ:

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
Candlestick because one numeric value cannot provide OHLC, and rejects Pie and
Donut because numeric values alone cannot provide accessible category labels.

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

Every built-in series encodes through `ChartSeriesDocumentCodec`. Candlestick
declares `series.candlestick`; Pie declares `series.pie`; Donut declares
`series.donut`. Older readers that do not support the required capability
reject the document rather than interpreting it as another series. Artifact
capture, canonical JSON, previews, hydration, and table export all preserve
point identity and type-specific configuration.

## Runnable examples

- [Chart Types](https://braven-pvm.github.io/braven_charts/?page=chart-types)
  compares all seven Cartesian and partition-radial series types.
- [Candlestick Charts](https://braven-pvm.github.io/braven_charts/?page=candlestick-charts)
  demonstrates typed OHLC, spacing, motion, live revisions, grouping, the
  Workbench, and synchronized stock composition.
- [Pie Charts](https://braven-pvm.github.io/braven_charts/?page=pie-charts)
  demonstrates labels, geometry, linked data, capture, preview, and restore.
- [Donut Charts](https://braven-pvm.github.io/braven_charts/?page=donut-charts)
- [Concentric Donut](https://braven-pvm.github.io/braven_charts/?page=concentric-donut)
  demonstrates center content, partial sweeps, linked data, and transport.
- [Gallery](https://braven-pvm.github.io/braven_charts/) demonstrates radial
  and mixed Cartesian product compositions.
