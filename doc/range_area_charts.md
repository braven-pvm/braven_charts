# Range Area charts

Range Area is a first-class Cartesian series for an interval between paired
low and high values. Use it for temperature envelopes, confidence intervals,
forecast fans, volatility bands, uncertainty, and other bounded quantities.

Open the runnable
[Range Area showcase](https://braven-pvm.github.io/braven_charts/?page=range-area-charts)

The [Technical Indicators composition](https://braven-pvm.github.io/braven_charts/?page=technical-indicators&preset=volatility)
uses the same native series for a rolling financial volatility envelope behind
Candlestick and Line overlays on a synchronized timeline.
to inspect six configurations and their Chart, Data, Split, and Source views.

## Model one interval atomically

One `RangeAreaDataPoint` owns its low and high values:

```dart
final intervals = <RangeAreaDataPoint>[
  RangeAreaDataPoint(x: 0, low: 8, high: 14),
  RangeAreaDataPoint(x: 1, low: 9.5, high: 15.2),
  RangeAreaDataPoint.gap(x: 2),
  RangeAreaDataPoint(x: 3, low: 10.4, high: 17),
];

final band = RangeAreaChartSeries(
  id: 'temperature-range',
  name: 'Daily low-high',
  unit: '°C',
  points: intervals,
  interpolation: LineInterpolation.monotone,
);
```

Valid intervals require finite, strictly ordered X values and finite
`low <= high` bounds. The inherited `ChartDataPoint.y` is the canonical
midpoint for compatibility, but low and high drive rendering, chart bounds,
tracking, tables, semantics, and portable documents. `span` is derived as
`high - low`.

Do not split one band into unrelated low and high Line series. Independent
series can acquire different interpolation tangents, point identities,
visibility, and missing-data behavior. Range Area computes both boundaries
from one ordered interval sequence.

## Preserve missing intervals

Use `RangeAreaDataPoint.gap()` for missing data. A gap is not a zero interval
and does not contain portable NaN values. With `connectGaps: false` the fill,
boundaries, tracking, keyboard traversal, labels, and summaries remain absent
inside the gap. `connectGaps: true` explicitly joins the nearest valid runs.

Stepped interpolation is useful for interval-valued states:

```dart
RangeAreaChartSeries(
  id: 'service-level-window',
  points: intervals,
  interpolation: LineInterpolation.stepped,
  connectGaps: false,
)
```

## Compose a centre line or nested bands

A mean, median, forecast, or price remains an ordinary Line series. This keeps
the line independently styleable and portable without duplicating the band
data model:

```dart
BravenChartPlus(
  series: [
    RangeAreaChartSeries(
      id: 'confidence',
      name: '90% confidence',
      points: intervals,
      color: const Color(0xFF7C3AED),
      fillOpacity: 0.24,
      interpolation: LineInterpolation.monotone,
    ),
    LineChartSeries(
      id: 'estimate',
      name: 'Estimate',
      points: estimatePoints,
      color: const Color(0xFFDB2777),
      interpolation: LineInterpolation.monotone,
    ),
  ],
)
```

Declare a wider Range Area before a narrower one to create a forecast fan.
Each band retains one typed identity and appears independently in legends,
tracking, Data mode, artifacts, and generated source.

Range Area can share a Cartesian plot with Line, Area, Scatter, Candlestick,
and other Range Area series under the normal layout compatibility rules. Its
low and high values must use the same Y axis.

## Fill and boundary styling

`fillOpacity` and `fillGradient` style the interval interior.
`RangeAreaBorderMode.boundaries` draws upper and lower paths without closing
the vertical sides; `closed` includes the sides; `none` hides the border.

The two boundaries can be configured independently:

```dart
RangeAreaChartSeries(
  id: 'forecast',
  points: intervals,
  fillOpacity: 0.28,
  fillGradient: const AreaGradient(
    colors: [Color(0x334F46E5), Color(0x994F46E5)],
  ),
  upperBoundaryStyle: const RangeAreaBoundaryStyle(
    strokeWidth: 2,
    glowRadius: 2,
  ),
  lowerBoundaryStyle: const RangeAreaBoundaryStyle(
    strokeWidth: 1.5,
    dashPattern: [6, 4],
  ),
  showBoundaryMarkers: true,
  markerRadius: 3,
)
```

Uniform solid paths use the cached fast path. Dash and glow are deliberate
independent-boundary slow paths. Light, dark, high-contrast, and custom chart
themes resolve their defaults through `RangeAreaTheme`.

## Tracking, labels, and summaries

Range Area tracking resolves low, high, midpoint, and span together through
`RangeAreaInteractionDetails`. Nearest and interpolated tracking reuse the
same linear, stepped, Bezier, or monotone segment descriptors used by paint.
Paired intersection markers and paired Y-axis labels therefore describe the
rendered boundaries rather than an unrelated midpoint approximation.

`RangeAreaLabelConfig` can label low, high, both, midpoint, or span. Its
`RangeAreaLabelDetails` formatter input preserves the boundary identity and
source interval. Chart-wide collision policy and edge placement are shared
with other Cartesian labels.

The ordinary `CartesianValueSummaryConfig` automatically produces typed low,
high, midpoint, and span rows. It can use a fixed overlay or draggable chart
annotation presentation. No Range Area-specific overlay widget is required.

Keyboard navigation treats one interval as one focusable value, skips gaps,
and selects both boundaries together. Semantics announce X or timestamp,
low, high, midpoint, span, ordinal position, and selection state. Do not rely
on fill colour alone: keep at least one boundary, marker, label, or textual
legend cue when colour perception is material.

## Motion

Range Area uses `PathAnimationStyle`, like Line and Area. Entrance reveal
clips the fill, both boundaries, markers, labels, selection, and glow at one
leading edge. Compatible updates interpolate X, low, and high atomically and
recompute midpoint every frame, so animation never creates `low > high`.

Motion is opt-in and honors reduced-motion settings and zero-duration themes.
Artifacts, tables, and generated source always describe target values rather
than transient animation frames.

## Workbench, artifacts, and generated source

`BravenChartWorkbench` supports Chart, Data, Split, and Source without a
family-specific wrapper. Data mode exposes midpoint, low, high, derived span,
and explicit gap state. Copy and CSV retain source values.

Portable artifacts use the `rangeArea` series type and the
`range-area.interval.v1` point capability. Inline and columnar storage both
preserve bounds, timestamps, metadata, styles, gaps, and motion. A runtime
without that capability rejects the series instead of rendering midpoint-only
fallback data.

Generated Dart emits `RangeAreaChartSeries`, `RangeAreaDataPoint`, and
`RangeAreaDataPoint.gap` constructors. Tool-driven configuration accepts a
series with `type: rangeArea` and requires either finite `x`, `low`, and `high`
or `x` with `gap: true`; generic `(x, y)` input is rejected.

## Performance behavior

Ordered intervals use a binary-searched viewport index. Geometry resolves the
visible window plus small curve overscan rather than scanning or allocating
for every off-screen point during pan. Resolved fill and boundary paths are
cached until series or transform state changes. Hover reuses cached geometry
and does not rebuild the widget tree.

The permanent benchmark matrix covers 5,000 and 50,000-point geometry,
50,000-point tracking, 1,000 visible intervals from 50,000 source values,
solid and gradient paint, dash/glow, gaps, nested bands, compatible updates,
and dense artifact/source generation. Timing depends on device and build mode;
run the benchmark files on the target platform before setting application
budgets.

## V1 boundaries

Range Area does not derive statistics from raw samples, stack bands, accept
horizontal `xLow`/`xHigh` intervals, use separate axes for low and high,
automatically change fill at crossings, aggregate dense data, or edit bounds
by dragging. Prepare those values in the application and pass the resulting
typed intervals to the chart.

## Related documentation

- [Chart types](../docs/guides/chart-types.md)
- [Line and Area charts](line_area_charts.md)
- [Cartesian value summary](value_summary.md)
- [Portable chart artifacts](chart_artifacts.md)
- [Chart Workbench](chart_workbench.md)
