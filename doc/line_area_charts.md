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

## Opt in to motion

Path motion is intentionally disabled by default. Existing analytical,
streaming, and very large charts therefore preserve their current behavior.

```dart
const motion = PathAnimationStyle(
  entranceMode: PathEntranceAnimationMode.reveal,
  dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
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
the same reveal boundary. Timing and easing come from
`ChartTheme.animationTheme`.

Mounted data updates interpolate only when the old and new series are
compatible: they keep the same stable series identity and corresponding point
X values. Incompatible changes render the target state immediately. Axis
bounds, tables, extracted documents, and artifacts always describe the target
data; transient geometry is confined to painting.

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
chart renders its final frame synchronously.

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
- [Line chart family](https://braven-pvm.github.io/braven_charts/?page=line-charts)
- [Area chart family](https://braven-pvm.github.io/braven_charts/?page=area-charts)

The motion routes include replay and compatible data-update controls. Switch
between Chart, Data, and Split to verify that visual interpolation never
changes the target data exposed by the table or artifact.
