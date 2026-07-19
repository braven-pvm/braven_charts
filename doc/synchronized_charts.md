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

Each participant keeps its own `CrosshairConfig`. A synchronized cursor forces
only the continuous data-X tracking mechanics; it does not replace the chart's
configured crosshair mode, coordinate labels, tracking tooltip, or intersection
marker visibility. Use `CrosshairMode.both` and enable crosshair labels on the X
and Y axes when each chart should show its local value at the shared X:

```dart
BravenChartPlus(
  interactionGroupController: interactions,
  series: [metricSeries],
  xAxisConfig: const XAxisConfig(showCrosshairLabel: true),
  yAxis: const YAxisConfig(showCrosshairLabel: true),
  interactionConfig: const InteractionConfig(
    crosshair: CrosshairConfig(
      enabled: true,
      mode: CrosshairMode.both,
      displayMode: CrosshairDisplayMode.tracking,
      interpolateValues: true,
    ),
  ),
)
```

The horizontal guide follows the participant's first local series value using
the transform already used to paint that series. This remains a paint-only
path: it does not rescan axis bounds, rebuild geometry or widgets, change a
chart document revision, create durable selection, or add shared cursor state
to an artifact. Local point tooltips remain local.

In the Line showcase, **Crosshair tracking** toggles the complete overlay as
one behavior: synchronized X, local Y, both axis-value labels, intersection
marker, and the floating tracking tooltip. Turning it off disables that
crosshair overlay without disabling viewport synchronization.

## Dynamic membership and sizing

Membership is the normal widget lifecycle. Adding a `BravenChartPlus` with the
shared controller attaches it; removing that widget detaches it immediately.
No separate mutable member list is required. This makes filtered small
multiples straightforward:

```dart
Column(
  children: [
    for (final metric in metrics.where((metric) => metric.visible))
      SizedBox(
        height: metric.height,
        child: BravenChartPlus(
          interactionGroupController: interactions,
          series: [metric.series],
        ),
      ),
  ],
)
```

Call `interactions.reset()` before a composition change if a cursor or viewport
may currently be active. The Line showcase exposes membership and independent
176-400 px height controls and includes a supported zero-chart empty state.

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

The example also shows rolling `FrameTiming` diagnostics (active charts,
visible points, sample count, p95 build/raster time, and frames over 16.7 ms).
These values describe the current device, browser, and build mode and should be
used for same-session comparisons, not as portable package benchmarks. The
diagnostics subtree refreshes at most twice per second and does not rebuild the
chart participants.

Use **Dataset profile** for a same-device scaling comparison:

- **Normal** keeps the 52 original samples across the three metrics.
- **Dense** uses 500 deterministic samples per chart (1,500 total).
- **Stress** uses 5,000 deterministic samples per chart (15,000 total).

Dense and Stress preserve the original domains and endpoints. Their immutable
point lists are generated once when first selected and then reused across chart
rebuilds, participant removal/restoration, tracking, theme, and layout changes.
Reset the frame samples after switching profiles if you want a clean interaction
window, then scrub, pan, and zoom the same way in each profile.
