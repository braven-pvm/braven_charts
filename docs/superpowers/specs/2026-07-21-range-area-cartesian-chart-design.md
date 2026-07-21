# Range Area Cartesian Chart — Research and Product Design

**Date:** 2026-07-21
**Status:** Implemented and release-verified on `spec/ranged-area-chart`
**Public name:** Range Area
**Coordinate family:** Cartesian
**Depends on:** `doc/chart_family_integration.md`

## Executive decision

Range Area becomes a first-class built-in Cartesian series in
`BravenChartPlus`.

It is not implemented as two independent Area or Line series, and it is not a
normal Area series with a synthetic baseline. One logical sample owns one X
coordinate and one ordered low/high interval. That atomic identity must survive
geometry, interpolation, tracking, animation, artifacts, native Data mode,
generated Dart, and accessibility.

The public family is:

- `RangeAreaDataPoint` for one `(x, low, high)` interval or an explicit gap;
- `RangeAreaChartSeries` for the filled band and its two boundaries;
- an ordinary `LineChartSeries` when the chart also needs a mean, median,
  forecast, or other centre line.

This keeps overlays independently styleable, trackable, selectable, animated,
and visible in the legend while letting the band reuse Braven's Cartesian
axes, annotations, viewports, navigator, synchronization, motion timeline, and
Workbench.

## Research basis

### What established systems agree on

The established contract is one ranged series with two Y values per X:

- Highcharts defines Area Range as a Cartesian series with a high and low for
  every point and shades the area between them. Its default nearest-point
  search is by X, and it exposes null connection, fill, line, marker, data
  label, and `trackByArea` choices.
- Syncfusion Flutter exposes a dedicated `RangeAreaSeries` with independent
  `lowValueMapper` and `highValueMapper`. It treats boundary drawing as an
  explicit choice and supports gradients, animation, empty points, and
  sorting.
- Vega-Lite creates ranged areas by providing the second quantitative channel
  (`y2` or `x2`) on one Area mark. It applies the selected interpolation to the
  mark and layers separate lines or points when they are required.
- Matplotlib `fill_between` accepts shared X plus `y1` and `y2`, producing one
  or more filled polygons. It also makes missing sections, step semantics, and
  true curve-intersection handling explicit rather than silently inventing
  values.

Primary sources:

- [Highcharts Area Range API](https://api.highcharts.com/highcharts/plotOptions.arearange)
- [Syncfusion Flutter Range Area chart](https://help.syncfusion.com/flutter/cartesian-charts/chart-types/range-area-chart)
- [Vega-Lite Area and ranged-area marks](https://vega.github.io/vega-lite/docs/area.html)
- [Matplotlib `fill_between`](https://matplotlib.org/stable/api/_as_gen/matplotlib.pyplot.fill_between.html)

### Product conclusions from the research

1. Low and high belong to one datum. Two independent series cannot guarantee
   matching X identity, gaps, interpolation, selection, or animation.
2. Both boundaries use the same interpolation mode, but they remain distinct
   paths and may be styled independently.
3. A centre line is a separate overlay. It may represent a mean, median,
   observation, forecast, or another metric and must not be fabricated from
   the band.
4. Gaps are data, not zero-valued ranges. The model and portable document must
   encode them explicitly.
5. Low/high crossing is a different visualization problem. Range Area v1
   requires `low <= high`; crossing-series fills and colour-at-intersection are
   deferred.
6. Tracking resolves the interval atomically at one X and reports low, high,
   midpoint, and span from the same interpolation result.
7. Boundary-only versus closed-border painting is a legitimate presentation
   choice and belongs in the series style.

### Naming

The public API uses **Range Area**, matching Highcharts, Syncfusion, and common
charting terminology:

- `SeriesStyle.rangeArea`
- `RangeAreaDataPoint`
- `RangeAreaChartSeries`
- `RangeAreaTheme`

The documentation may use “ranged area” descriptively, but public type names
do not use `RangedArea`.

## Repository findings

### Existing foundations that should be reused

- `ChartLayoutKind.cartesian` already permits mixed Line, Area, Scatter, and
  Candlestick compositions.
- `ChartTransform` and the multi-axis manager already map shared X and
  series-specific Y axes into plot space.
- `SeriesElement` is the correct native Cartesian paint, hit-test, focus, and
  selection surface.
- `InterpolationGeometry` is the source of truth for Line and Area linear,
  Bezier, monotone, and stepped geometry.
- `AreaGradient`, `PathAnimationStyle`, Cartesian entrance reveal, legend,
  annotations, controller selection, viewport, synchronization, and navigator
  infrastructure are reusable.
- `BravenChartWorkbench` is family-neutral after the mounted chart can produce
  a complete effective document.
- Point extensions already preserve family-specific typed data for
  Candlestick without flattening it into generic `y`.

### Explicit seams that must be extended

A new enum value or subclass alone is insufficient. The current repository
enumerates built-in families in these areas:

- `SeriesStyle` and concrete-model validation;
- `DataConverter.seriesToElements()` and `computeDataBounds()`;
- `SeriesElement` paint, hit testing, focus, semantics, and legend behavior;
- crosshair tracking, tooltip rendering, value summaries, and interaction
  details;
- path update motion and canonical target-point mapping;
- `ChartSeriesDocumentCodec`, capability negotiation, hydration, and source
  capture;
- `ChartTableModel`, Data mode, CSV, and clipboard export;
- `ChartDartSourceGenerator`;
- agentic schema and `ChartConfigBuilder`;
- public barrel exports, documentation, Workbench, chart-type catalogue, and
  direct showcase route.

### Geometry constraint discovered in the current renderer

The existing Area painter closes one interpolated upper path against a fixed
baseline. Range Area instead needs an upper path followed by the exact reverse
of an independently interpolated lower path.

Simply reversing the lower input points is not sufficient for every
interpolation. Cubic control points must also be reversed correctly, and
monotone interpolation assumes ordered X input. The implementation therefore
needs reusable interpolation segment descriptors rather than duplicating
Bezier/monotone mathematics in a Range Area painter.

### Canonical Y compatibility anchor

`ChartSeries` and `ChartDataPoint` still expose one primary `y`. Candlestick
uses close as its compatibility anchor. Range Area will use the interval
midpoint:

```text
y = (low + high) / 2
```

This is useful for generic point identity, focus, and fallback callbacks, but
Range Area-aware surfaces must use typed low/high values. The renderer,
bounds, tooltips, table, artifacts, and source generator must never mistake the
midpoint for the complete interval.

## Public model

### Typed datum

```dart
final class RangeAreaDataPoint extends ChartDataPoint {
  RangeAreaDataPoint({
    required double x,
    required double low,
    required double high,
    DateTime? timestamp,
    String? label,
    Map<String, dynamic>? metadata,
  }) : low = low,
       high = high,
       isGap = false,
       super(
         x: x,
         y: (low + high) / 2,
         timestamp: timestamp,
         label: label,
         metadata: metadata,
       );

  RangeAreaDataPoint.gap({
    required double x,
    DateTime? timestamp,
    String? label,
    Map<String, dynamic>? metadata,
  }) : low = null,
       high = null,
       isGap = true,
       super(
         x: x,
         y: 0,
         timestamp: timestamp,
         label: label,
         metadata: metadata,
       );

  final double? low;
  final double? high;
  final bool isGap;

  double? get midpoint => isGap ? null : (low! + high!) / 2;
  double? get span => isGap ? null : high! - low!;

  @override
  bool get isValid =>
      x.isFinite &&
      (isGap ||
          (low!.isFinite && high!.isFinite && low! <= high!));
}
```

The exact constructor implementation may avoid storing a redundant `isGap`
flag, but the public semantics are fixed:

- both low and high exist, or neither exists;
- a gap is explicit and never contributes `0` to bounds, tracking, tables, or
  geometry;
- callers cannot set inherited `y` independently;
- `copyWith()` preserves the typed class and keeps canonical `y` synchronized;
- `atTime()` may map UTC epoch milliseconds consistently with other temporal
  series.

The internal placeholder `y` for a gap is ignored by every Range Area-aware
surface and is only present because the base point contract requires a double.
Portable documents additionally carry an explicit gap bit, so no consumer
needs to infer missingness from that placeholder.

### Boundary style

```dart
@immutable
class RangeAreaBoundaryStyle {
  const RangeAreaBoundaryStyle({
    this.visible = true,
    this.color,
    this.strokeWidth = 1.5,
    this.dashPattern = const [],
    this.glowRadius = 0,
  });

  final bool visible;
  final Color? color;
  final double strokeWidth;
  final List<double> dashPattern;
  final double glowRadius;
}

enum RangeAreaBorderMode {
  none,
  boundaries,
  closed,
}
```

`boundaries` paints the low and high paths but not vertical start/end sides.
It is the default because side walls are usually a polygon-construction detail
rather than meaningful data. `closed` adds both sides. `none` paints only the
fill.

Upper and lower boundary styles are independent. Their default colours resolve
from the series colour and theme, while nullable explicit colours allow common
single-colour bands without redundant configuration.

### Series

```dart
final class RangeAreaChartSeries extends ChartSeries {
  RangeAreaChartSeries({
    required super.id,
    super.name,
    required List<RangeAreaDataPoint> points,
    super.metadata,
    super.annotations,
    super.yAxisId,
    super.yAxisConfig,
    super.unit,
    super.color,
    this.interpolation = LineInterpolation.linear,
    this.tension = 0.3,
    this.fillOpacity = 0.28,
    this.fillGradient,
    this.borderMode = RangeAreaBorderMode.boundaries,
    this.upperBoundaryStyle = const RangeAreaBoundaryStyle(),
    this.lowerBoundaryStyle = const RangeAreaBoundaryStyle(),
    this.connectGaps = false,
    this.showBoundaryMarkers = false,
    this.markerRadius = 3,
    this.dataPointLabels,
    this.pathAnimation = const PathAnimationStyle(),
  }) : super(
         points: points,
         style: SeriesStyle.rangeArea,
         isXOrdered: true,
       );
}
```

The precise field names should follow existing Line/Area naming during
implementation, but the capability surface is fixed:

- linear, Bezier, monotone, and stepped interpolation;
- solid or gradient fill and explicit opacity;
- independent low/high boundary visibility, colour, width, dash, and glow;
- boundary-only, closed, or fill-only border mode;
- explicit gap bridging;
- optional paired boundary markers;
- low, high, both, midpoint, or span data-label modes;
- native entrance and data-update motion.

### Label configuration

Generic `DataPointLabelConfig` assumes one Y value. Range Area requires typed
semantics:

```dart
enum RangeAreaLabelValue { low, high, both, midpoint, span }
```

The Range Area label configuration reuses existing typography, background,
border, collision, formatter-descriptor, and placement infrastructure while
adding:

- selected value mode;
- upper/lower offsets when both are displayed;
- a typed formatter payload containing low, high, midpoint, span, X, unit,
  timestamp, and label.

Labels default off. Tracking is the primary dense-data inspection surface.

## Validation contract

Construction, artifact hydration, source generation fixtures, and agentic
input apply the same rules:

1. X must be finite for every sample, including gaps.
2. A non-gap point requires finite low and high values.
3. `low <= high`; equal values are valid zero-width intervals.
4. A gap has neither low nor high. Half-defined intervals fail closed.
5. X values are strictly increasing and unique.
6. Empty and single-point series are valid.
7. Style widths, radii, opacity, tension, and glow are finite and within their
   documented ranges.
8. Dash patterns use the existing portable dash validation.
9. A normal centre/mean line is never inferred from low/high.
10. Range Area may share a Cartesian plot with Line, Area, Scatter, and one
    Candlestick series. Existing Candlestick/Bar restrictions remain intact.
11. Multiple Range Area series are allowed when their IDs are unique.
12. Invalid points are not silently swapped, clamped, sorted, or converted to
    gaps.

Index-specific diagnostics identify the first failing point and field.

## Geometry and rendering

### Pure geometry result

Introduce a renderer-independent `RangeAreaGeometry` result containing:

- upper and lower interpolated boundary paths;
- one or more closed fill paths, split at non-connected gaps;
- optional start/end side paths;
- original source point indices for every visible run;
- per-point upper/lower screen coordinates;
- fill and stroke bounds;
- binary-searchable X interval metadata for hit testing and tracking.

The geometry helper accepts typed points, `ChartTransform`, plot bounds,
interpolation, tension, gap mode, and viewport overscan. It contains no
`BuildContext`, widget state, theme resolution, tooltip creation, or artifact
logic.

### Shared interpolation descriptors

Refactor `InterpolationGeometry` to expose immutable segment descriptors for
linear, stepped, Bezier, and monotone paths. Each segment records the start,
end, and any cubic control points.

Those descriptors support:

- appending a boundary in forward order;
- appending it in exact reverse order by swapping cubic controls;
- evaluating the exact rendered Y at an arbitrary X;
- using identical math in paint, tracking, and update motion;
- deterministic geometry tests without canvas screenshots.

Line and Area continue to consume the same helper, so this refactor must be
behavior-preserving and protected by existing geometry goldens.

### Fill construction

For each contiguous valid run:

1. append the complete high boundary from left to right;
2. append the complete low boundary from right to left using reversed segment
   descriptors;
3. close the path;
4. paint the fill once;
5. paint low/high boundaries from their independent forward paths;
6. paint vertical sides only in `RangeAreaBorderMode.closed`.

Do not use `Path.combine()` in the warm path. It adds avoidable allocation and
platform-dependent boolean geometry work.

### Curves and interval invariants

The point contract guarantees `low <= high` at samples, but cubic curves may
overshoot between samples. The renderer does not silently clamp independent
curves because that would make paint differ from tracking and motion.

Instead:

- monotone interpolation uses the existing shape-preserving algorithm on each
  boundary;
- linear and stepped interpolation cannot introduce crossings when endpoints
  remain ordered;
- Bezier documentation warns that high tension can visually overshoot;
- geometry tests detect actual boundary crossings;
- a future `RangeAreaCurveConstraint` may add constrained Bezier controls if
  product testing proves it necessary.

V1 does not implement crossing-dependent fill colours or actual intersection
splitting. That is a separately specified crossing-series feature.

### Gaps

With `connectGaps == false`, each gap terminates the current fill run. No
boundary or fill is painted across it. With `connectGaps == true`, gap points
are omitted and the nearest valid neighbours are connected using the selected
interpolation.

Leading, trailing, repeated, and all-gap inputs are valid. They produce no
spurious side wall, marker, hit target, or bounds contribution.

### Viewport and culling

Strict ordered X allows binary search for the first and last visible source
indices. Include one valid neighbour on either side for curve continuity and
scan only the small adjacent gap region required to establish a complete run.

Pan and zoom must not rebuild typed data or allocate per-point paints. Cached
geometry is invalidated by data, transform, plot size, interpolation, tension,
gap mode, or geometry-affecting style—not by hover movement.

### Paint order

Within one Range Area series:

1. optional fill glow;
2. fill;
3. optional upper/lower boundary glow;
4. upper/lower boundaries and optional sides;
5. boundary markers;
6. selection/focus presentation;
7. data labels and inline labels.

Series ordering still controls composition with ordinary Line, Area,
Candlestick, annotations, and other overlays.

### Fill and theme behavior

`AreaGradient` is reused and resolves against the complete plot bounds, not the
temporary visible band bounds. `fillOpacity` composes with gradient stop alpha
using the existing Area rule.

Add `RangeAreaTheme` to `ChartTheme`, with light/dark defaults for:

- fill opacity;
- boundary width and derived boundary colour treatment;
- marker fill/stroke;
- selection and focus presentation;
- paired tracking markers;
- label defaults.

The default remains readable without relying on hue alone: a translucent band
plus visible boundary strokes communicates the interval shape.

## Bounds, axes, and composition

### Bounds

`DataConverter.computeDataBounds()` must use every valid low and high value.
Midpoint-only bounds are a correctness failure.

- gaps contribute no Y value;
- a zero-span single-point interval receives normal degenerate-range padding;
- X padding follows Line/Area behavior;
- explicit axis bounds remain authoritative;
- gradients always use stable target plot bounds during motion.

### Axes

Range Area uses the normal Cartesian X axis and binds both boundaries to one
Y axis. Low and high cannot be assigned to different axes because they form
one interval in one unit.

The family participates in multi-axis layouts like Line/Area. Axis labels,
annotations, synchronization, scrollbars, zoom, pan, and navigator viewport
commands remain normal Cartesian concerns.

### Mixed compositions

Supported examples include:

- temperature low/high Range Area plus observed mean Line;
- confidence interval Range Area plus model estimate Line and point markers;
- Bollinger band Range Area plus price Line;
- Candlestick plus volatility band and moving-average Line;
- multiple percentile bands ordered broad-to-narrow.

The chart does not automatically derive any overlay from the interval. Derived
statistics belong in application data preparation or an explicitly future
transform layer.

## Interaction

### Typed details

Add `RangeAreaInteractionDetails`:

```dart
@immutable
class RangeAreaInteractionDetails {
  const RangeAreaInteractionDetails({
    required this.low,
    required this.high,
    required this.midpoint,
    required this.span,
  });

  final double low;
  final double high;
  final double midpoint;
  final double span;
}
```

`ChartDataHit`, `CrosshairSeriesValue`, value-summary rows, callback payloads,
and semantics carry the typed details rather than reconstructing them from
display strings.

### Crosshair tracking

Nearest tracking finds one original sample by ordered X. Interpolated tracking
evaluates both rendered boundaries at the same target X using the exact shared
interpolation descriptors.

The tracking result contains:

- source point identity or bracketing source identities;
- whether the value is interpolated;
- low, high, midpoint, and span;
- unit, timestamp/label, and formatted values;
- canonical midpoint as the inherited `y` only for compatibility.

When the crosshair is within a non-connected gap, the Range Area contributes no
value. It does not snap across the gap unless the tracker is explicitly in
nearest-sample mode.

### Markers and axis values

Range Area tracking paints two intersection markers, one on each boundary.
Selection/focus uses the same paired presentation.

When crosshair Y-axis values are enabled, the Range Area contributes two
labels, low and high. The existing horizontal guide remains governed by the
chart's crosshair mode:

- vertical mode: no horizontal line or single synthetic Y coordinate;
- both/horizontal mode: a horizontal line follows the pointer, not the
  interval midpoint;
- paired low/high labels remain attached to their real boundary coordinates.

This avoids implying that the midpoint is the measured value.

### Tooltip and pinned value summary

Default Range Area rows are:

```text
Series name
X / time
Low       3.20 °C
High     12.80 °C
Range     9.60 °C
```

Midpoint is optional because a separately plotted mean line is not necessarily
the interval midpoint. Floating tooltips, crosshair panels, overlay cards, and
chart annotations consume one shared typed value-summary model.

All default numeric output uses existing axis/unit formatters. The showcase
uses two decimals where the surrounding page contract requires it; the public
library does not hard-code financial or weather precision.

### Hit testing and selection

The default hit policy is nearest X plus a vertical tolerance that covers the
filled interval. A pointer inside the band can identify the series even when
it is far from both strokes. The resolved point is the nearest original X
sample.

Expose:

```dart
enum RangeAreaHitTestMode { band, nearestBoundary }
```

- `band` is the default for conventional range inspection;
- `nearestBoundary` requires proximity to low/high strokes and is useful when
  several bands overlap.

Selection retains one point reference and highlights both boundaries plus a
subtle connector at its X. No synthetic low/high child points are exposed to
the controller.

### Keyboard and accessibility

Left/right traversal follows source X order and skips gaps. Enter/Space
activates the selected interval. Semantic descriptions include series, X/time,
low, high, span, position, selection, and hidden state.

Example:

```text
Expected temperature, May 12, low 3.20 degrees Celsius,
high 12.80 degrees Celsius, range 9.60 degrees Celsius,
point 11 of 30.
```

Focus remains visible in light, dark, high-contrast, and reduced-motion modes.

## Motion

### Entrance reveal

Range Area reuses the Cartesian X-ordered reveal clip. Fill, both boundaries,
markers, labels, selection, and glow share one reveal edge. Reduced motion and
zero-duration themes resolve synchronously.

### Data-update motion

Introduce `RangeAreaSeriesTransition` or generalize the path transition around
typed paired values. A generic midpoint-only `ChartDataPoint.copyWith(y: ...)`
is forbidden because it would lose the interval.

For compatible point identities, interpolate atomically:

```text
x    = lerp(from.x,    to.x)
low  = lerp(from.low,  to.low)
high = lerp(from.high, to.high)
y    = (low + high) / 2
```

The frame remains valid because linear interpolation preserves `low <= high`
when both endpoints are valid. Gap entry/exit collapses to the nearest retained
boundary using the same topology rules as Line/Area, while never inventing a
visible zero interval.

Target bounds, target formatter decisions, and canonical target point mapping
remain fixed for the entire animation. The source and target documents are
immutable.

## Artifacts, hydration, and portability

### Series and point identity

Add portable series type `rangeArea` and explicit capabilities:

- `series.range-area.interval.v1`
- `series.range-area.style.v1`
- existing path-motion, dash-pattern, gradient, label, axis, and annotation
  capabilities where their contracts are unchanged.

Each typed point uses extension `range-area.interval.v1`:

```json
{
  "low": 3.2,
  "high": 12.8,
  "gap": false
}
```

For a gap, low/high are absent and `gap` is true. For a valid point, canonical
document `y` must equal `(low + high) / 2` within the codec's exact numeric
contract. Hydration rejects mismatches rather than trusting one representation
silently.

### Style transport

The series style document preserves:

- interpolation and tension;
- solid fill, gradient, and opacity;
- border mode;
- complete upper and lower boundary styles;
- gap connection;
- marker and label configuration;
- hit-test mode;
- path animation.

Unknown Range Area capabilities fail closed on older runtimes. They never
degrade to a midpoint-only Line or baseline Area.

### Inline and columnar data

Both inline points and columnar payloads preserve X, low, high, gap,
timestamp, label, metadata, and canonical point identity. Columnar storage
uses aligned low/high values plus an explicit gap bitmap; missingness is not
encoded as NaN because the artifact is portable JSON.

Round-trip tests cover inline, columnar, empty, all-gap, temporal, styled,
annotated, multi-axis, and mixed-overlay documents.

## Native Data mode and export

Range Area remains a normal Cartesian long/wide projection rather than gaining
a finance-specific table.

Add auxiliary fields:

- `rangeLow` — Low;
- `rangeHigh` — High;
- `rangeSpan` — Range.

The main series column is explicitly labelled **Midpoint** for Range Area, not
the generic **Value**. This keeps the base one-Y projection honest while the
adjacent low/high columns remain the source of truth. Gaps display em dashes
and export empty fields; they never export `0`.

CSV and copy surfaces include X/time, label, midpoint, low, high, span, unit,
valid/gap state, and metadata according to existing options. Span is labelled
derived. Sorting, focus, selection, controller linking, and exact-X overlay
alignment use the canonical point reference.

## Generated Dart and agentic input

`ChartDartSourceGenerator` emits `RangeAreaChartSeries` and
`RangeAreaDataPoint` / `.gap` constructors, including all non-default styles,
formatters, axis bindings, annotations, and path motion. Generated source must
parse, format deterministically, compile in the fixture, and reconstruct an
equivalent effective document.

The agentic schema accepts `type: rangeArea` with ordered `x`, `low`, and
`high`, or an explicit gap. Generic `(x, y)` input is insufficient and fails
with a clear diagnostic. The builder applies the same validation as direct
construction and hydration.

## Workbench and showcase

### Dedicated chart-type page

Add **Range Area Charts** to Chart Type Guides with a direct route and built-in
Workbench. The page is simultaneously:

- the renderer test surface;
- the property and theme lab;
- the public feature showcase;
- the Chart/Data/Split/Source validation surface.

Recommended presets:

1. **Temperature envelope** — daily low/high band plus an independent observed
   mean Line with markers.
2. **Seasonal variation** — dense yearly min/max band with vertical gradient
   and no centre line.
3. **Confidence interval** — 95% interval, estimate Line, event annotation,
   and paired range tracking.
4. **Forecast fan** — nested 50% and 90% bands plus forecast Line, demonstrating
   multiple bands and legend order.
5. **Volatility band** — price or Candlestick composition with a Range Area
   band and moving-average Line.
6. **Gaps and steps** — missing intervals, `connectGaps`, stepped boundaries,
   labels, keyboard focus, and dark theme.

### Controls

The Options panel exposes enough of the actual public contract to test it:

- interpolation and tension;
- fill colour, gradient stops/direction, and opacity;
- upper/lower boundary visibility, colour, width, dash, and glow;
- border mode;
- connect gaps;
- boundary markers and radius;
- range label mode and placement;
- hit-test mode;
- tracking mode, paired intersections, axis values, tooltip, and pinned
  summary;
- entrance direction, duration, easing, replay, update motion, and reduced
  motion;
- point count/density, interval width/variation, gap frequency, and overlay
  visibility;
- theme, grid, axes, legend, navigator/scrollbars, zoom, and pan.

Use the shared optional-colour palette component from annotation dialogs, with
clear-first behavior and select-again-to-clear semantics.

### Workbench contract

Every preset provides Chart, Data, Split, and Source. Source warnings must be
actionable, and family-specific formatters must be registered rather than
falling back silently in a first-party example. Controller state survives mode
changes without remounting the chart.

The later Financial Technical Indicators integration is a composition
consumer, not a prerequisite for the native family. It is rebased after the
financial showcase branch lands and uses the same Range Area implementation
for volatility bands or clouds.

## Performance budget

Range Area builds two boundary geometries plus one fill; its budget should be
measured relative to native Area on the same machine and dataset.

Required benchmarks:

- cold geometry for 5,000 and 50,000 ordered points;
- visible-window geometry for 1,000 points from a 50,000-point source;
- warm paint for solid and gradient fills;
- dashed/glowing independent-boundary slow path;
- nearest and interpolated tracking over 50,000 points;
- compatible 5,000-point data-update frames;
- gap-heavy and multiple-band compositions;
- artifact encode/decode and source generation for dense data.

Acceptance targets:

- cached hover/tracking work remains below 1 ms p95;
- warm full-frame paint remains within 16.7 ms p95 on the reference harness;
- visible-window geometry scales with visible points plus small overscan, not
  total source count;
- uniform solid Range Area paint is no more than 1.8× the corresponding Area
  benchmark median;
- pan does not allocate one object per off-screen point;
- hover does not invalidate geometry or trigger widget `setState` in the hot
  path;
- all benchmark results record device, build mode, point count, visible count,
  interpolation, gradient, gaps, and boundary style.

Performance failures are investigated before adding sampling or grouping.
Range Area must not silently alter source data to meet a frame budget.

## Test strategy

### Model and validation

- valid, zero-span, single, empty, temporal, and multiple-series inputs;
- finite values, ordering, duplicates, half-gaps, low/high inversion;
- `copyWith()`, equality, hash, midpoint/span, and gap behavior;
- mixed Cartesian composition rules.

### Geometry

- linear, stepped, Bezier, and monotone boundaries;
- exact reverse cubic controls and closed fill winding;
- plot clipping, overscan, irregular X, single point, zero span;
- leading, interior, trailing, repeated, and connected gaps;
- boundary-only, closed, fill-only, dash, glow, markers, and gradients;
- DPR/crisp-stroke behavior and off-viewport culling;
- behavior-preserving Line/Area regression tests after interpolation refactor.

### Interaction and semantics

- nearest and exact rendered interpolation for both boundaries;
- no value inside disconnected gaps;
- paired markers and low/high axis labels;
- band and nearest-boundary hit policies;
- mouse, touch, keyboard, focus, selection, activation, and semantics;
- floating, crosshair, pinned-overlay, and chart-annotation summaries;
- multi-axis and synchronized-pane coordinate alignment.

### Motion

- entrance reveal for all directions and styles;
- reduced motion and zero duration;
- equal-length, boundary insertion/removal, and compatible topology updates;
- low/high invariant throughout every frame;
- target bounds, identity, source immutability, and exact completion.

### Portable surfaces

- inline and columnar artifact round trips;
- capability rejection and malformed point extensions;
- hydration and controller identity;
- long/wide Data mode, CSV, clipboard, gaps, focus, and selection;
- deterministic generated source plus parse and compile fixture;
- agentic schema happy/error paths.

### Showcase and release

- each preset and option group at desktop and compact widths;
- light, dark, high contrast, gradients, and reduced motion;
- direct route, navigation/catalogue, reset, URL preset, and source registration;
- release web build and browser smoke;
- pub.dev dry run, package API docs, README, changelog, example, and full E2E.

Golden changes require visual review; they are never accepted only because the
test command can update baselines.

## Non-goals for v1

- deriving mean, median, confidence intervals, Bollinger bands, or weather
  ranges from raw samples;
- stacking Range Area series;
- horizontal range areas (`xLow` / `xHigh`);
- low/high values on different Y axes;
- crossing-series fills or automatic colour changes at intersections;
- 3D, polar, radial, or geographic range areas;
- a family-specific navigator overview renderer;
- automatic dense-data aggregation or smoothing;
- editing range values by dragging boundaries.

These exclusions keep the initial family honest and composable without closing
future extension points.

## Completion contract

Range Area is ready only when:

1. one typed interval survives construction, rendering, tracking, motion,
   artifacts, hydration, Data mode, CSV, generated source, and semantics;
2. low and high—not midpoint—drive bounds and visible geometry;
3. exact render interpolation also drives tracking and reversed fill geometry;
4. gaps remain gaps everywhere;
5. a separate Line overlay composes, tracks, animates, and appears in the
   legend independently;
6. every showcase preset exposes Chart/Data/Split/Source and useful controls;
7. direct routes, compact/desktop layouts, release web, package tests, docs,
   and performance gates pass;
8. no regression is introduced in Line, Area, Candlestick, synchronization,
   navigator, or Workbench behavior.

Until all eight conditions hold, Range Area is an implementation lane, not a
released built-in chart family.
