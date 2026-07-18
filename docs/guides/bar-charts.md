# Bar charts

`BarChartSeries` renders categorical values from a configurable baseline. The
current bar system supports vertical and horizontal orientation; grouped,
overlaid, stacked, 100% stacked, floating range, and waterfall bars; fixed or
category-relative widths, target tracks, lollipop marks, rounded ends,
gradients, borders, minimum visible lengths, connectors, and bar-native value
labels.

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
- `BarLayoutMode.divergingStacked` normalizes the complete category total,
  centers one neutral response, and stacks negative and positive roles outward.

## Diverging and Likert composition

Use positive source magnitudes for every response series and assign its side
with `divergingRole`. One optional neutral series spans the baseline; the
remaining series preserve legend order while the strongest negative and
positive responses occupy the outer ends:

```dart
BarChartSeries(
  id: 'disagree',
  name: 'Disagree',
  points: disagreeShares,
  orientation: BarOrientation.horizontal,
  layoutMode: BarLayoutMode.divergingStacked,
  groupId: 'responses',
  divergingRole: BarDivergingRole.negative,
  barWidthPercent: 0.68,
  divergingStyle: const BarDivergingStyle(
    showCenterLine: true,
    centerLineWidth: 1.25,
  ),
  labelStyle: const BarLabelStyle(
    show: true,
    position: BarLabelPosition.insideCenter,
    valueMode: BarLabelValueMode.percentage,
  ),
)
```

All series in a diverging group share a baseline and at most one may use the
neutral role. Values must be finite magnitudes at or above that baseline.
Braven Charts normalizes the full response total to 100%, derives symmetric
automatic value-axis bounds, and retains raw point values in tooltips,
semantics, and workbench tables. The portable tool contract uses
`bar_layout: diverging_stacked`, per-series `bar_diverging_role`, and the
`bar_diverging_center_line_*` style fields.

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

## Lollipop marks

Use `BarLollipopStyle` when the exact endpoint matters more than the visual
mass of a filled rectangle. The bar keeps its categorical slot, baseline,
labels, animation, tooltips, targets, uncertainty intervals, and interaction
identity while the visible mark becomes a stem and circular endpoint:

```dart
BarChartSeries(
  id: 'activation',
  name: 'Current',
  points: activationScores,
  barWidthPercent: 0.48,
  barGap: 12,
  lollipopStyle: const BarLollipopStyle(
    stemWidth: 3,
    headRadius: 8,
    stemColor: Color(0xFF67AFC0),
    headColor: Color(0xFF168AAD),
    headBorder: BarBorderStyle(
      color: Color(0xFF0F5F73),
      width: 1.5,
    ),
  ),
  labelStyle: const BarLabelStyle(
    show: true,
    position: BarLabelPosition.outsideEnd,
  ),
)
```

Lollipop marks support grouped and overlaid layouts in both orientations.
Their canonical geometry expands paint and hit bounds around the marker,
while focus, hover, press, and selection follow the visible head instead of
an invisible bar rectangle. Stacked, normalized, diverging, waterfall, and
bullet compositions reject lollipop styling because their segment geometry
would make stems ambiguous.

## Pareto compositions

`ParetoChartData` prepares one ranked categorical dataset for a conventional
Pareto view: descending bars show the raw contribution and a line on an
independent 0–100% axis shows the cumulative share. Equal values retain their
source order and the final cumulative point is pinned to exactly 100%.

```dart
final pareto = ParetoChartData(
  categories: const [
    ParetoCategory(label: 'Billing mismatch', value: 53),
    ParetoCategory(label: 'Missing profile data', value: 126),
    ParetoCategory(label: 'Password reset', value: 84),
  ],
);

final series = <ChartSeries>[
  BarChartSeries(
    id: 'issues',
    name: 'Issues',
    points: pareto.valuePoints,
    barWidthPercent: 0.62,
  ),
  LineChartSeries(
    id: 'cumulative',
    name: 'Cumulative share',
    points: pareto.cumulativePoints,
    unit: '%',
    showDataPointMarkers: true,
    yAxisConfig: YAxisConfig(
      position: YAxisPosition.right,
      label: 'Cumulative share',
      unit: '%',
      min: 0,
      max: 100,
    ),
  ),
];
```

Use the labels from `pareto.categories` in a `CategoryAxisConfig`, and use
`firstIndexAtOrAbove(80)` when the UI needs to identify the category where an
80% threshold is reached. The prepared result renders with ordinary bar and
line series, so Chart/Data/Split views and portable artifacts require no
Pareto-specific renderer or document codec.

## Histograms

`HistogramChartData` transforms continuous numeric samples into equal-width
intervals before they reach the renderer. Choose Freedman–Diaconis for a
robust automatic default, Sturges or square-root for simpler sample-count
rules, or an explicit fixed bin count:

```dart
final histogram = HistogramChartData(
  samples: responseTimes,
  method: HistogramBinningMethod.freedmanDiaconis,
);

BarChartSeries(
  id: 'response-time-histogram',
  name: 'Count',
  points: histogram.pointsFor(HistogramValueMode.count),
  barWidthPercent: 1,
  barGap: 0,
  barStyle: const BarChartStyle(
    cornerRadius: 0,
    cornerRadiusPolicy: BarCornerRadiusPolicy.all,
  ),
)
```

Each `HistogramBin` exposes its lower and upper bounds, count, percentage,
density, center, width, and compact interval label. All bins are left-closed
and right-open except the final bin, which includes the dataset maximum.
Constant samples resolve to one visible bin; empty inputs produce an empty
result; non-finite values are rejected.

Use `HistogramValueMode.count`, `percentage`, or `density` to change the bar
height without repeating the binning step. The prepared points and labels use
ordinary categorical bar-series contracts, so Chart/Data/Split views and
portable artifacts work without a histogram-specific renderer or codec.

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

In Chart/Data/Split presentations, the primary value column preserves each
source delta or total placeholder and an adjacent `Running total` column shows
the cumulative value used by the rendered bridge.

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

Chart/Data/Split tables retain each regular stack contribution as the primary
value and add `Stack start` and `Stack end` columns for the cumulative segment
bounds rendered by the chart.

For normalized stacks, use
`BarLabelStyle(valueMode: BarLabelValueMode.percentage)` to show the resolved
segment share. Tooltips, crosshairs, data tables, and portable artifacts retain
the original source value. Chart/Data/Split tables add an adjacent `Share (%)`
column so the normalized value rendered by the chart remains visible without
replacing that source value.

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

For diverging stacks, the shared track spans both sides of the center line.
An explicit `value` defines one capacity endpoint and is mirrored around the
stack baseline; omitting it spans both visible value-axis boundaries.

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

## Bullet charts

`BarBulletStyle` adds ordered qualitative ranges behind the actual measure.
Pair it with `targetValues` to build a compact bullet chart without creating
synthetic background or benchmark series:

```dart
BarChartSeries(
  id: 'delivery',
  name: 'Actual',
  points: delivery,
  orientation: BarOrientation.horizontal,
  barWidthPercent: 0.34,
  bulletStyle: const BarBulletStyle(
    measureThicknessFactor: 0.42,
    cornerRadius: 4,
    ranges: [
      BarBulletRange(endValue: 55, color: Color(0xFFE2E8F0)),
      BarBulletRange(endValue: 75, color: Color(0xFFCBD5E1)),
      BarBulletRange(endValue: 100, color: Color(0xFF94A3B8)),
    ],
  ),
  targetValues: const [88, 70, 85, 78, 65, 90],
  targetMarkerStyle: const BarTargetMarkerStyle(
    color: Color(0xFF111827),
    width: 2.5,
    lengthFactor: 2.2,
  ),
)
```

Range endpoints are finite, strictly increasing values measured from the
series baseline. The outermost range expands value-axis bounds; ranges remain
passive while the actual bar owns hit testing, focus, selection, labels, and
table rows. Bullet ranges support both orientations, artifact round-tripping,
and the public tool contract through `bar_bullet_ranges`,
`bar_bullet_measure_thickness`, and `bar_bullet_corner_radius`. They require
grouped layout and cannot be combined with floating range bars or capacity
tracks.

## Uncertainty and error bars

Use `errorLowerValues` and `errorUpperValues` for absolute value-axis
endpoints around each estimate. Both lists align with `points`; a null pair
omits the interval for that category:

```dart
BarChartSeries(
  id: 'estimate',
  name: 'Estimate',
  points: estimates,
  errorLowerValues: const [58, 65, 71, 52],
  errorUpperValues: const [70, 80, 86, 65],
  errorBarStyle: const BarErrorBarStyle(
    width: 1.5,
    capLengthFactor: 0.6,
  ),
)
```

The stem follows the value axis and its caps cross the bar, so the geometry
automatically transposes in horizontal charts. Endpoints expand axis bounds,
round-trip through artifacts, animate with data updates, and appear in
tooltips and keyboard semantics. Whiskers remain passive: the estimate is the
only hit-tested and selectable data mark. When `color` is omitted, the default
dark line receives a light halo so it remains visible across bars and light or
dark plot backgrounds.

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

Labels can also participate in one chart-wide layout pass. Set
`collisionPolicy` to `BarLabelCollisionPolicy.reposition` to try the requested
placement, semantic inside/outside fallbacks, and then a small displacement.
Use `hide` when preserving the marks is more important than showing every
label. `plotEdgeAware` keeps boxes inside the visible plot in either vertical
or horizontal orientation.

```dart
labelStyle: const BarLabelStyle(
  show: true,
  position: BarLabelPosition.outsideEnd,
  collisionPolicy: BarLabelCollisionPolicy.reposition,
  collisionPadding: 3,
  backgroundColor: Color(0xEEFFFFFF),
  borderColor: Color(0x44334155),
  borderWidth: 1,
  callout: BarLabelCalloutStyle(show: true),
  showStackTotal: true,
),
```

Backgrounds, borders, and callouts are optional and serialize with the series.
`showStackTotal` paints one resolved total from the outer segment of each named
stack; segment labels remain independently configurable. Range-end labels use
the same collision registry and edge-aware fallbacks.

## Tool and agent configuration

`ChartConfigBuilder` and `ChartToolSchema.createChartTool` expose the same bar
model to OpenAI-, Anthropic-, or host-driven tool calls. Structural settings
live in `style`, composition identity lives on each series, and analytical
references live beside their source point:

```dart
final configured = ChartConfigBuilder.fromJson({
  'chart_type': 'bar',
  'x_axis': {
    'categories': ['Enterprise', 'Online'],
    'category_minimum_extent': 72,
  },
  'series': [
    {
      'id': 'actual',
      'bar_group_id': 'current',
      'data': [
        {
          'x': 0,
          'y': 88,
          'bar_target': 92,
          'bar_error_lower': 82,
          'bar_error_upper': 94,
        },
      ],
    },
  ],
  'style': {
    'bar_layout': 'grouped',
    'bar_orientation': 'vertical',
    'bar_corner_radius': 8,
    'bar_labels_show': true,
    'bar_label_position': 'outside_end',
    'bar_label_collision': 'reposition',
  },
});
```

The contract covers grouped, overlaid, stacked, normalized, diverging/Likert, range, waterfall,
vertical, and horizontal composition; capacity tracks, gradients, patterns,
borders, bullet ranges, benchmarks, uncertainty, interaction feedback, native category axes, and the
complete bar-label model. Builder output uses the normal `BarChartSeries` and
`XAxisConfig` types, so workbench tables and portable artifact extraction do
not require an agent-specific path. Series-level `bar_gradient_colors`,
`bar_pattern`, `bar_pattern_color`, `bar_border_color`, `bar_track_color`, and
`bar_label_color` override shared style values when each series needs to retain
its own visual identity.

## Accessible pattern fills

Colour does not have to carry series identity alone. Add a clipped line
pattern to each series and repeat that encoding in the legend:

```dart
BarChartSeries(
  id: 'forecast',
  name: 'Forecast',
  points: points,
  color: const Color(0xFF386A78),
  barStyle: const BarChartStyle(
    pattern: BarPatternStyle(
      pattern: BarFillPattern.diagonalDown,
      spacing: 8,
      strokeWidth: 1.5,
      opacity: 0.58,
    ),
  ),
)
```

Available patterns are `diagonalUp`, `diagonalDown`, `crosshatch`,
`horizontal`, and `vertical`. The renderer chooses a contrasting black or
white line colour from the resolved bar fill unless `BarPatternStyle.color`
is supplied. Patterns are clipped to the same rounded geometry used by paint,
animation, labels, and hit testing; dimmed bars also dim their pattern.

Patterns supplement rather than replace series names, value labels, and
tooltips. This keeps the chart understandable in monochrome, under common
colour-vision differences, and when a printed or projected palette loses
contrast. Tool calls expose the same settings through `bar_pattern`,
`bar_pattern_color`, `bar_pattern_spacing`, `bar_pattern_stroke_width`, and
`bar_pattern_opacity`, globally or per series.

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
points and fully removed series collapse to their baseline before leaving the
render tree. Point identity is keyed by `x`, so changing a label does not turn
one update into an unrelated exit and entrance. Structural changes such as
orientation or layout mode replay in their new geometry instead of morphing
between incompatible coordinate systems. Flutter's reduced-motion setting
always renders the final geometry immediately.

`BarMotionStyle` can sequence categories while keeping one shared completion
time. `staggerFraction` reserves the opening portion of that timeline for
distributed starts; it does not multiply the total duration. Available orders
are together, first-to-last, last-to-first, center-out, and edges-in:

```dart
barStyle: const BarChartStyle(
  motion: BarMotionStyle(
    order: BarAnimationOrder.forward,
    staggerFraction: 0.45,
  ),
),
```

Sequencing applies to entrance and keyed data updates and exits through the
canonical bar geometry. Range starts, benchmark markers, uncertainty
endpoints, labels, hit testing, axes, and tooltips therefore remain aligned
throughout the transition. Exiting points retain their category slot and
collapse markers and uncertainty intervals with the bar; a removed series
retains its previous paint order until the shared timeline completes.
The same options are available to tool calls as `bar_animation_order` and
`bar_animation_stagger`, globally or as per-series overrides.

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

### Chart, Data, and Split views

`BravenChartWorkbench` keeps the mounted bar chart linked to its native data
table. The table preserves one canonical row reference per chart point while
exposing passive bar measures as adjacent sortable columns:

- floating bars add `Start`;
- benchmark markers add `Target`;
- uncertainty intervals add `Lower bound` and `Upper bound`.
- regular stacks add `Stack start` and `Stack end`.
- normalized stacks add `Share (%)`.
- waterfalls add `Running total`.

These fields flow through row copy and CSV export without creating synthetic
chart series, so legends, selection, focus, and series counts continue to
describe only the rendered data series. Null target or interval entries appear
as `No value`; a null floating-range start resolves to the series baseline,
matching the renderer.

The linked views are bidirectional. Table hover and keyboard focus apply the
chart's transient point-focus treatment, while chart-controller focus reveals
and highlights the matching virtualized row without claiming table keyboard
focus. Durable chart selection separately reveals the row and uses selected
styling and semantics. Either automatic reveal policy can be disabled on a
standalone `ChartDataTable` when its host owns scrolling.

Data and Split rows use the same multi-selection convention as bars:
Ctrl/Command-click or Ctrl/Command-Enter adds a row's points to the durable
selection, and repeating the modified activation removes the complete row.
For shared-X rows this toggles every populated series point together.
Shift-click or Shift-Enter selects the contiguous range from the last ordinary
activation in the current sorted order. Add Ctrl/Command to preserve the
existing selection while applying that complete range.
The table summary reports the selected point count and keeps a compact Clear
selection action beside Copy and Export, including at narrow Split widths.
With a row focused, Ctrl/Command+A selects every point in the current sorted
table projection and Escape clears selection without moving keyboard focus.
Home and End jump to the first or last displayed row; Page Up and Page Down
move focus by one visible table page while preserving chart-point linking.

## Right-to-left charts

`BravenChartPlus` inherits the nearest Flutter `Directionality`. Category-axis
labels, bar value labels, chart-owned tooltips, crosshair content, and data-hit
semantics therefore use the same reading direction as the surrounding app.
Wrap the chart in `Directionality(textDirection: TextDirection.rtl)` when it is
not already inside an RTL application shell. Numeric geometry is not reversed:
the data domain keeps its configured order while Arabic and Hebrew text is laid
out correctly in both vertical and horizontal orientations.

Use the maintained `?page=bar-lab&preset=rtl` preset to verify Arabic labels,
interactions, and orientation changes together.

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
`?page=bar-lab&preset=bullet`, `?page=bar-lab&preset=likert`,
`?page=bar-lab&preset=targets`, `?page=bar-lab&preset=uncertainty`,
`?page=bar-lab&preset=patterns`, `?page=bar-lab&preset=motion`,
`?page=bar-lab&preset=rtl`,
`?page=bar-lab&preset=states`,
`?page=bar-lab&preset=stacked`, or `?page=bar-lab&preset=normalized`.
Append `&view=data` or `&view=split` to open the corresponding workbench
presentation directly.
