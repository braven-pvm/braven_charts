# Bar charts

`BarChartSeries` renders categorical values from a configurable baseline. The
current bar system supports vertical and horizontal orientation; grouped,
overlaid, stacked, 100% stacked, floating range, and waterfall bars; fixed or category-relative widths, target tracks,
rounded ends, gradients, borders, minimum visible lengths, connectors, and
bar-native value labels.

```dart
BarChartSeries(
  id: 'current',
  name: 'Current',
  points: const [
    ChartDataPoint(x: 0, y: 42),
    ChartDataPoint(x: 1, y: 61),
    ChartDataPoint(x: 2, y: 88),
  ],
  color: const Color(0xFF168AAD),
  barWidthPercent: 0.72,
  barGap: 4,
  minBarLength: 4,
  barStyle: const BarChartStyle(
    cornerRadius: 8,
    cornerRadiusPolicy: BarCornerRadiusPolicy.valueEnd,
    gradient: BarGradient(
      colors: [Color(0xFF34D399), Color(0xFF168AAD)],
    ),
    border: BarBorderStyle(color: Color(0xFF0E7490), width: 1),
  ),
  trackStyle: const BarTrackStyle(
    color: Color(0xFFDCEFF3),
    value: 100,
  ),
  labelStyle: const BarLabelStyle(
    show: true,
    position: BarLabelPosition.auto,
  ),
)
```

## Grouped, overlaid, and stacked composition

`layoutMode` selects how a series shares each category slot:

- `BarLayoutMode.grouped` gives every series a separate side-by-side slot.
- `BarLayoutMode.overlaid` centers series in the same named group on one slot
  while preserving each series value and width.
- `BarLayoutMode.stacked` adds contributions for series in the same named
  stack.
- `BarLayoutMode.normalizedStacked` converts each positive and negative stack
  independently to 100% while preserving the original point values.

## Horizontal orientation

Set `orientation` without exchanging your data fields. X values remain
categories and Y values remain measurements; Braven Charts transposes the
transform, axes, grid, geometry, and interaction layer together:

```dart
BarChartSeries(
  id: 'revenue',
  name: 'Current',
  points: const [
    ChartDataPoint(x: 0, y: 96),
    ChartDataPoint(x: 1, y: 84),
    ChartDataPoint(x: 2, y: 73),
  ],
  orientation: BarOrientation.horizontal,
  barWidthPercent: 0.72,
  barStyle: const BarChartStyle(
    cornerRadius: 6,
    cornerRadiusPolicy: BarCornerRadiusPolicy.valueEnd,
  ),
  labelStyle: const BarLabelStyle(
    show: true,
    position: BarLabelPosition.outsideEnd,
  ),
)
```

The semantic X-axis configuration is painted vertically on the left, while
the semantic Y-axis is painted horizontally below the plot. Category order
runs from top to bottom. Positive value-end corners round on the right and
negative value-end corners round on the left. Gradients, tracks, labels,
range endpoints, stacks, overlays, waterfall connectors, hit testing,
tooltips, and crosshairs follow the same transposed geometry.

Every series in a horizontal chart must be a horizontal `BarChartSeries`.
Mixed vertical/horizontal series and mixed chart types fail early because
axis transposition is a chart-level operation.

### Multiple horizontal value axes

Horizontal bars preserve the existing series-to-axis contract. Add an inline
`yAxisConfig` or shared `yAxisId` to each series and use
`NormalizationMode.perSeries` when the measurements need independent scales:

```dart
BarChartSeries(
  id: 'revenue',
  name: 'Revenue',
  points: revenue,
  orientation: BarOrientation.horizontal,
  yAxisConfig: YAxisConfig(
    position: YAxisPosition.left,
    label: 'Revenue',
    unit: r'$k',
    showCrosshairLabel: true,
  ),
),
BarChartSeries(
  id: 'conversion',
  name: 'Conversion',
  points: conversion,
  orientation: BarOrientation.horizontal,
  yAxisConfig: YAxisConfig(
    position: YAxisPosition.right,
    label: 'Conversion',
    unit: '%',
    showCrosshairLabel: true,
  ),
),
```

For a transposed chart, `YAxisPosition.left` maps to a value axis below the
plot and `YAxisPosition.right` maps above it. Repeated positions stack outward
in declaration order. The normal `maxAxesPerSide`, hidden-axis, overflow,
selection-promotion, formatter, color, unit, and crosshair-label rules still
apply. Bars, value labels, tooltips, intersection markers, and crosshair values
all resolve through their bound axis.

## Overlaid comparisons

Overlay bars are useful when a wide reference or target should remain visible
behind a narrower actual value. Give both series the same `groupId`, keep the
wide series first in the chart's series list, and inset later layers with
`overlayWidthFactor`:

```dart
BarChartSeries(
  id: 'target',
  name: 'Target',
  points: target,
  barWidthPercent: 0.8,
  layoutMode: BarLayoutMode.overlaid,
  groupId: 'performance',
),
BarChartSeries(
  id: 'actual',
  name: 'Actual',
  points: actual,
  barWidthPercent: 0.8,
  layoutMode: BarLayoutMode.overlaid,
  groupId: 'performance',
  overlayWidthFactor: 0.58,
),
```

For equal-width bars that overlap without fully covering one another, shift
the reference left and the result right with `overlayOffsetFactor`:

```dart
reference.copyWith(
  layoutMode: BarLayoutMode.overlaid,
  groupId: 'medals',
  overlayWidthFactor: 1,
  overlayOffsetFactor: -0.15,
),
result.copyWith(
  layoutMode: BarLayoutMode.overlaid,
  groupId: 'medals',
  overlayWidthFactor: 1,
  overlayOffsetFactor: 0.15,
),
```

The factor is measured against the resolved category-slot width. Negative
values move left and positive values move right; `0` keeps the original
centered overlay behavior.

Overlaid series retain independent values, labels, styles, hit geometry, and
crosshair entries. Later series paint in front of earlier series. Several
named overlay groups can sit side-by-side in one category, just like named
stacks. Only the first series in an overlay group owns its shared capacity
track. When layers can cross, label only the front series or provide enough
width separation to keep background labels unobscured.

## Floating and range bars

Supply `rangeStartValues` to make each point span an explicit start and end.
The list aligns with `points`; each point's existing `y` remains the end value:

```dart
BarChartSeries(
  id: 'temperature-range',
  name: 'Observed',
  points: const [
    ChartDataPoint(x: 0, y: 25),
    ChartDataPoint(x: 1, y: 29),
    ChartDataPoint(x: 2, y: 27),
  ],
  rangeStartValues: const [14, 17, 15],
  unit: '°C',
  barWidthPercent: 0.64,
  barStyle: const BarChartStyle(
    cornerRadius: 8,
    cornerRadiusPolicy: BarCornerRadiusPolicy.all,
  ),
  labelStyle: const BarLabelStyle(
    show: true,
    position: BarLabelPosition.rangeEnds,
    valueMode: BarLabelValueMode.range,
    showUnit: true,
  ),
)
```

An empty `rangeStartValues` list preserves ordinary bars. Null entries fall
back to `baselineValue`, allowing a series to mix floating and baseline bars.
Reversed ranges are supported and retain their direction for end-aware styling.
Range bars participate in bounds, hit testing, selection, labels, and portable
artifacts through the same canonical geometry as ordinary bars.

`BarLabelPosition.rangeEnds` separates the lower and upper values below and
above the bar. In dense grouped charts, endpoint labels first wrap their unit
onto a second line and rotate vertically only when the wrapped label still
cannot fit between adjacent bar centres.

Grouped and overlaid range bars are supported. Stacking is intentionally
rejected because a point-defined start conflicts with an accumulated stack
start.

## Waterfall bridges

`BarLayoutMode.waterfall` treats ordinary point `y` values as sequential
deltas in list order. Mark total columns with `waterfallTotalIndices`; their
source `y` is retained for artifacts and tables but ignored by geometry, which
draws the resolved running total from `baselineValue`:

```dart
BarChartSeries(
  id: 'cash-flow',
  name: 'Cash flow',
  points: const [
    ChartDataPoint(x: 0, y: 82),
    ChartDataPoint(x: 1, y: 28),
    ChartDataPoint(x: 2, y: -18),
    ChartDataPoint(x: 3, y: 0), // total placeholder
  ],
  barWidthPercent: 0.62,
  layoutMode: BarLayoutMode.waterfall,
  waterfallTotalIndices: const {3},
  waterfallStyle: const BarWaterfallStyle(
    increaseColor: Color(0xFF168AAD),
    decreaseColor: Color(0xFFE15B64),
    totalColor: Color(0xFF5149C6),
    connector: BarWaterfallConnectorStyle(
      color: Color(0xFF9CA3AF),
      width: 1.25,
    ),
  ),
  labelStyle: const BarLabelStyle(
    show: true,
    position: BarLabelPosition.outsideEnd,
    valueMode: BarLabelValueMode.waterfall,
  ),
)
```

Waterfall labels show each step's signed delta and each total's cumulative
value. Tooltips and crosshairs resolve total columns to that same cumulative
value, while ordinary steps retain their source delta. Connector lines render
behind columns and can be hidden or restyled. Waterfall points must have
strictly increasing X values because list order defines the bridge.

Use `groupId` to create several named stacks side-by-side:

```dart
BarChartSeries(
  id: 'actual-running',
  name: 'Actual running',
  points: actualRunning,
  barWidthPercent: 0.8,
  layoutMode: BarLayoutMode.stacked,
  groupId: 'actual',
),
BarChartSeries(
  id: 'actual-cycling',
  name: 'Actual cycling',
  points: actualCycling,
  barWidthPercent: 0.8,
  layoutMode: BarLayoutMode.stacked,
  groupId: 'actual',
),
BarChartSeries(
  id: 'planned-total',
  name: 'Planned',
  points: planned,
  barWidthPercent: 0.8,
  layoutMode: BarLayoutMode.stacked,
  groupId: 'planned',
),
```

Positive and negative values accumulate on separate sides of the common
baseline. With `BarCornerRadiusPolicy.valueEnd`, only the exposed positive or
negative segment receives rounded end corners, so internal joins remain
continuous. With `BarCornerRadiusPolicy.all`, every segment receives four
rounded corners. Series with different axes or baselines are intentionally
placed in separate stacks.

For normalized stacks, use
`BarLabelStyle(valueMode: BarLabelValueMode.percentage)` to show the resolved
segment share. Tooltips, crosshairs, data tables, and portable artifacts retain
the original source value.

## Width and spacing

- `barWidthPercent` occupies a proportion of the smallest category interval.
- `barWidthPixels` sets a fixed group width in logical pixels.
- `minWidth` and `maxWidth` constrain the resolved group width.
- `barGap` sets the logical-pixel gap between grouped series.
- `PointStyle.size` remains available as a per-point width multiplier.

When several bar series are present, Braven Charts divides the group width
between them and centers the complete group on each X value.

## Corners, gradients, and borders

`BarCornerRadiusPolicy.valueEnd` rounds the end that encodes the value while
leaving the baseline edge square. It works for both positive and negative
values. Use `BarCornerRadiusPolicy.all` for pill or rod presentations.

Bar gradients follow the value axis from the baseline to the value end. A
per-point `PointStyle.color` deliberately replaces the series gradient for
that point.

## Capacity and target tracks

`BarTrackStyle` draws a passive bar behind each value. Set `value` for a fixed
capacity or target. When `value` is omitted, the track extends to the visible
value-axis boundary in the direction of the bar.

Tracks participate in bar bounds and rendering but not in value hit testing:
the interactive mark remains the actual data bar.

## Benchmark and target markers

Use `targetValues` for a distinct benchmark at each category without modelling
the benchmark as another data series. The marker crosses the actual bar and
automatically transposes with horizontal orientation:

```dart
BarChartSeries(
  id: 'actual',
  name: 'Actual',
  points: actual,
  targetValues: const [72, 78, 85, 68, 84, 95, 76],
  targetMarkerStyle: const BarTargetMarkerStyle(
    width: 2,
    lengthFactor: 1.3,
  ),
)
```

Targets participate in value-axis bounds, artifact round-tripping, tooltips,
keyboard semantics, and animated data updates. They remain passive reference
marks: hit testing, focus, selection, and series counts continue to describe
the actual bar. Set a marker color explicitly or leave it null to derive a
high-contrast color from each bar.

## Labels

Bar labels use rendered rectangle geometry rather than marker geometry:

- `auto` places the label inside when it fits and outside when it does not.
- `insideEnd` follows the positive or negative value end.
- `insideCenter` centers the label in the bar.
- `outsideEnd` places it beyond the value end.
- `rangeEnds` separates the lower and upper values below and above the bar,
  compacting them automatically in dense groups.

Inside labels automatically select light or dark text from the bar luminance
unless an explicit label color is supplied. `BarLabelStyle.padding` controls
the edge offset for end labels. For `insideEnd`, this is a minimum: rounded
value ends automatically add enough inset to keep text clear of the curve.

## Motion

Bars grow from their baseline on first render and interpolate value changes
through the same canonical geometry used by paint, labels, tooltips, and hit
testing. The duration and easing come from the chart theme:

```dart
final baseTheme = ChartTheme.light;

BravenChartPlus(
  theme: baseTheme.copyWith(
    animationTheme: baseTheme.animationTheme.copyWith(
      dataUpdateDuration: const Duration(milliseconds: 650),
      dataUpdateCurve: Curves.easeInOutCubic,
    ),
  ),
  series: series,
)
```

Set `BarChartStyle.animationMode` to `BarAnimationMode.none` for a series that
must update immediately. New points grow from their target baseline; removed
points leave immediately. Structural changes such as orientation or layout
mode replay in their new geometry instead of morphing between incompatible
coordinate systems. Flutter's reduced-motion setting always renders the final
geometry immediately.

## Interaction and artifacts

Hit testing, focus outlines, durable selection, tooltips, and bounds all use
the same canonical bar rectangles. Crosshair tracking snaps to the nearest
real category and never interpolates values between bars.

Hover applies to the complete bar rectangle rather than a small value-end
target. Primary-button press feedback is transient; clicking a bar creates a
durable point selection, while Ctrl/Command-click toggles additive selection.
When a point is selected, other bars use
`BarInteractionStyle.dimmedOpacity`. Hover, press, focus, selection, and
dimming can be restyled through `BarChartStyle.interaction`:

```dart
barStyle: const BarChartStyle(
  interaction: BarInteractionStyle(
    hoverBorderWidth: 2,
    selectionBorderWidth: 2.5,
    focusGap: 3,
    dimmedOpacity: 0.32,
  ),
),
```

With keyboard focus inside a bar-only chart, arrow keys move between
categories and series, Enter or Space selects the focused bar, and Escape
clears point focus and selection. Hold Alt while using arrow keys to retain
viewport panning. The chart semantics node announces the focused series,
category, value or range, unit, and selection state.

For horizontal bars, panning follows the rendered orientation: horizontal
movement pans the value axes and vertical movement pans categories. Viewport
constraints are applied to those transposed semantic axes, including when the
two directions have different zoom levels.

All declarative bar options round-trip through `ChartSeriesDocumentCodec`.
Runtime label formatter callbacks require a runtime binding and intentionally
fail closed during portable artifact extraction.

## Current boundary

Horizontal orientation is a chart-level transform, so it cannot currently be
mixed with vertical bars or non-bar series in the same plot. Use separate chart
panels when both orientations are required.

Run the interactive showcase at `?page=bar-lab`. Composition states can be
deep-linked, for example `?page=bar-lab&layout=normalizedStacked&series=6&groups=2`.
Overlay composition can be opened directly with
`?page=bar-lab&layout=overlaid&series=4&groups=2`.

The Bar Lab quick-jump selector includes a maintained preset for every shipped
bar capability. Presets can be linked directly with `preset`, for example
`?page=bar-lab&preset=overlay`, `?page=bar-lab&preset=offset`,
`?page=bar-lab&preset=range`, `?page=bar-lab&preset=waterfall`,
`?page=bar-lab&preset=horizontal`, `?page=bar-lab&preset=axes`,
`?page=bar-lab&preset=targets`, `?page=bar-lab&preset=motion`,
`?page=bar-lab&preset=states`,
`?page=bar-lab&preset=stacked`, or `?page=bar-lab&preset=normalized`.
