# Line and Area charts

Line and Area are Braven Charts' primary path-series families. They share the
same axes, annotations, tracking, zoom, pan, multi-axis normalization,
streaming, artifact, and workbench contracts. Area adds a fill between the
path and its configured baseline.

## Create a path series

```dart
final series = LineChartSeries(
  id: 'observed',
  name: 'Observed',
  points: const [
    ChartDataPoint(x: 0, y: 30),
    ChartDataPoint(x: 1, y: 38),
    ChartDataPoint(x: 2, y: 35),
  ],
  interpolation: LineInterpolation.monotone,
);

BravenChartPlus(series: [series]);
```

Use `AreaChartSeries` when distance from a baseline is part of the story. A
positive/negative baseline fill can assign distinct styles above and below
zero or another target. Keep overlapping fills translucent so individual
series remain readable.

Area fills are solid by default and can opt into a plot-bound linear gradient:

```dart
const area = AreaChartSeries(
  id: 'throughput',
  points: points,
  fillOpacity: 0.32,
  fillGradient: AreaGradient(
    colors: [Color(0xFF4F46E5), Color(0x1A06B6D4)],
    stops: [0, 1],
  ),
);
```

`fillOpacity` multiplies the alpha of every gradient stop. The gradient is
resolved against stable plot bounds rather than the animated path bounds.
When `baselineValue` is set, the above/below baseline fills take precedence.

## Opt in to motion

Path motion is intentionally disabled by default. Existing analytical,
streaming, and very large charts therefore preserve their current behavior.

```dart
const motion = PathAnimationStyle(
  entranceMode: PathEntranceAnimationMode.reveal,
  dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
  entranceTiming: PathAnimationTiming(
    delay: Duration(milliseconds: 80),
  ),
  dataUpdateTiming: PathAnimationTiming(
    delay: Duration(milliseconds: 80),
  ),
);

final series = AreaChartSeries(
  id: 'forecast',
  name: 'Forecast',
  points: points,
  interpolation: LineInterpolation.monotone,
  pathAnimation: motion,
);
```

Entrance reveal follows the leading edge of the plot for linear, Bezier,
monotone, and stepped paths. Area fill, stroke, glow, markers, and labels share
the same reveal boundary. A null `PathAnimationTiming.duration` inherits the
chart theme's data-update duration. A series may instead declare a
non-negative phase delay and duration. Configure these values explicitly on
stable series IDs; Braven Charts does not infer staggering from list or paint
order. All participating series still share one orchestration clock, and the
theme curve is applied independently within each local window.

Mounted data updates interpolate when the old and new series keep the same
stable series identity and ordered point identities. Equal-length values move
in place. Appended points grow from the retained boundary, removed points
collapse into it, and rolling windows perform both motions together. Identity
uses timestamps first and then corresponding `x + label` values. Interior
insertion or removal, reordered identities, series-type changes, and
interpolation-mode changes remain incompatible and use the existing fallback.

Axis bounds, tables, extracted documents, and artifacts always describe the
target data; transient geometry is confined to the standard renderer. Area
fill and stroke, markers, labels, hit testing, tooltips, and crosshair tracking
therefore stay on the same in-flight geometry.

Replay the entrance phase without changing data:

```dart
final controller = BravenChartController();

BravenChartPlus(
  bravenChartController: controller,
  series: series,
);

controller.replaySeriesEntrance();
```

When the platform requests reduced motion, or the theme duration is zero, the
chart renders its final frame synchronously even if a series has an explicit
override. An explicit zero series duration also ignores its delay and renders
that series immediately.

## Streaming boundary

Controller-fed streaming tails use Braven Charts' dedicated incoming-point
animation. They do not also trigger path data-update interpolation or entrance
reveal. This keeps a live trace responsive and avoids applying two motion
systems to the same point.

## Chart, Data, and Split views

`BravenChartWorkbench` keeps a chart mounted while users inspect its native
data table. Wide Split layouts include a pointer- and keyboard-resizable
divider; compact layouts present one active surface at a time.

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

The workbench table, copy and CSV actions, linked point identity, portable
artifact capture, and hydrated chart behavior are shared with the other chart
families. See [Chart Workbench](chart_workbench.md) and
[Portable chart artifacts](chart_artifacts.md) for the complete contracts.

## Runnable showcase

- [Line motion workbench](https://braven-pvm.github.io/braven_charts/?page=line-charts&preset=motion&view=split)
- [Area motion workbench](https://braven-pvm.github.io/braven_charts/?page=area-charts&preset=motion&view=split)
- [Area gradient](https://braven-pvm.github.io/braven_charts/?page=area-charts&preset=gradient)
- [Line and Area composition](https://braven-pvm.github.io/braven_charts/?page=line-charts&preset=envelope)
- [Line chart family](https://braven-pvm.github.io/braven_charts/?page=line-charts)
- [Area chart family](https://braven-pvm.github.io/braven_charts/?page=area-charts)

The motion routes include an explicit series-delay control plus replay, value
update, add, remove, and rolling-window controls. Switch between Chart, Data,
and Split to verify that visual interpolation never changes the target data
exposed by the table or artifact.
