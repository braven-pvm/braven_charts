# Synchronized Cartesian charts

`ChartInteractionGroupController` coordinates transient data-X interaction
across independently mounted `BravenChartPlus` widgets. Use it for aligned
small multiples that need a shared cursor or horizontal viewport but retain
their own units and Y scales.

This is intentionally separate from `ChartWorkbenchGroupController`:

- `ChartInteractionGroupController` shares data-X cursor and viewport state;
- `ChartWorkbenchGroupController` shares Chart/Data/Split/Source presentation;
- each chart keeps local Y bounds, axes, series visibility, annotations,
  tooltips, focus, and selection; and
- each chart still extracts and hydrates as its own artifact.

## Basic composition

Create and dispose one controller in the host, then pass it to every chart:

```dart
class DistanceChartsState extends State<DistanceCharts> {
  final interactions = ChartInteractionGroupController();

  @override
  void dispose() {
    interactions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const synchronizedYAxisWidth = 56.0;
    return Column(
      children: [
        Expanded(
          child: BravenChartPlus(
            interactionGroupController: interactions,
            series: [speedLine],
            yAxis: YAxisConfig(
              position: YAxisPosition.left,
              label: 'Speed',
              unit: 'km/h',
              minWidth: synchronizedYAxisWidth,
              maxWidth: synchronizedYAxisWidth,
            ),
          ),
        ),
        Expanded(
          child: BravenChartPlus(
            interactionGroupController: interactions,
            series: [elevationArea],
            yAxis: YAxisConfig(
              position: YAxisPosition.left,
              label: 'Elevation',
              unit: 'm',
              minWidth: synchronizedYAxisWidth,
              maxWidth: synchronizedYAxisWidth,
            ),
          ),
        ),
      ],
    );
  }
}
```

All participants must use the same semantic X domain. They may have different
widths, plot insets, sample counts, interpolation modes, and Y ranges. The
controller publishes data values rather than pixels, and every chart performs
its own coordinate mapping and rendered-path intersection lookup.

Data synchronization does not force independent charts to use the same screen
insets. For a vertically stacked composition where crosshairs must form one
continuous visual line, reserve equal left and right axis gutters. Setting the
same `YAxisConfig.minWidth` and `maxWidth` on peer axes prevents different tick
label lengths from shifting their plot rectangles. Charts that are arranged
side by side or intentionally use different plot widths do not need this.

## Cursor behavior

Mouse hover and touch scrub publish one finite data-X value. Every participating
chart paints a vertical crosshair and resolves its local Line and Area values
through the same linear, stepped, Bezier, or monotone geometry used to paint
the paths. Intersection markers therefore remain on both the shared crosshair
and each visible curve. Pointer exit, focus loss, touch completion, touch
cancellation, detach, and controller changes clear the transient cursor.

Synchronized crosshair rendering is paint-only. It does not rebuild the widget
tree, change a chart document revision, create durable point selection, or add
shared cursor state to an artifact. Local point tooltips remain local.

## Viewport behavior

Pan, zoom, reset, scrollbar, and keyboard viewport changes publish resulting X
bounds. Recipients apply only X min and max, preserve their current Y min and
max, and update their own durable view-state revision. Controller and chart
guards prevent a received viewport from being broadcast again.

Continuous viewport updates use the renderer's transform-only path and settle
geometry and hit-test state once interaction pauses. This avoids rebuilding
every participant's elements for every pointer event.

## Participant opt-outs

Disable one synchronization channel without leaving the group:

```dart
BravenChartPlus(
  interactionGroupController: interactions,
  interactionGroupOptions: const ChartInteractionGroupOptions(
    synchronizeCursor: true,
    synchronizeViewport: false,
  ),
  series: [overviewSeries],
)
```

An opted-out channel neither publishes nor receives that state. Use this for a
fixed overview plot or for a chart whose X domain is related but not identical.

Call `interactions.reset()` before reusing the controller for a different
composition. It clears remembered cursor and viewport state; mounted chart
viewports remain local and should be reset or remounted separately.

## Runnable example

[Open the synchronized Speed, Elevation, and Heart-rate stack](https://braven-pvm.github.io/braven_charts/?page=line-charts&preset=synchronized).
