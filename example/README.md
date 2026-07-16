# Braven Charts showcase

This Flutter application is the runnable product tour for Braven Charts. It is
also the source for pub.dev screenshots and the public web demo.

[**Open the public Braven Charts showcase →**](https://braven-pvm.github.io/braven_charts/)

[**Open Chart Workbench directly →**](https://braven-pvm.github.io/braven_charts/?page=chart-workbench)

## Run locally

From the repository root:

```bash
cd example
flutter pub get
flutter run -d chrome
```

For a release build:

```bash
flutter build web --release --base-href /braven_charts/
```

## Feature map

| Showcase page | What to try |
| --- | --- |
| Gallery | Flagship multi-axis analysis, baseline fills, glow, live streaming, small multiples, chart types, annotations, tracking, and real-world compositions |
| Chart Types | Switch among line, area, bar, and scatter series and tune their visual parameters |
| Interaction | Zoom and pan with pointer, touch, toolbar, and keyboard input; reset the viewport |
| Tracking Lab | Crosshair modes, snap-to-point behavior, tracking panels, and styled tooltips |
| Annotations | Point, range, text, threshold, trend, pin, legend, and editing workflows |
| Segment Styling | Conditional colors, per-segment styles, gradients, and alert thresholds |
| Streaming / Live Stream | Follow-latest viewports, frame-coalesced ingestion, pause/resume, buffering, and catch-up |
| Theming | Light, dark, accessible, and custom chart themes |
| Multi-Axis / Axis Slots | Independent Y units, shared axes, normalization, visible slots, overflow, and runtime series selection |
| Scientific | Dense measurement data and scientific formatting |
| Baseline Fill | Positive/negative and above/below-target area fills |
| Loading States | Animated chart skeleton, circular/linear progress, empty results, and custom state content |
| Performance | Large data sets and rendering diagnostics |
| Chart Artifacts | Capture effective chart state, switch between chart/table/restored views, inspect canonical JSON, and restore an independent chart |
| Chart Workbench | Keep one chart mounted across Chart/Data/Split views, link rows to points, inspect captured JSON and diagnostics, recover table failures, refresh a bounded-stream snapshot deliberately, and prove three hydrated charts remain independent |

Additional focused pages cover minor ticks, explicit render ranges, point
labels, series styling, power/lactate analysis, and lactate-threshold chord
annotations.

## Interaction shortcuts

- Hover a series or marker for its tooltip.
- Move across a tracking chart to inspect synchronized series values.
- Drag to pan; hold Shift while using the wheel to zoom around the pointer.
- Use scrollbars where enabled to inspect a constrained viewport.
- Select a legend entry or series in multi-axis demos to exercise axis slots.
- Pause live streams, allow points to buffer, then resume.
- Open annotation controls to create, edit, drag, or remove overlays.

## Responsive navigation

Desktop and tablet layouts use a scrollable feature rail. Narrow layouts use a
drawer so every demo remains reachable without an oversized bottom navigation
bar.

## Screenshot routes

The Gallery is designed as the primary pub.dev image. Focused screenshots can
also be captured from Multi-Axis, Live Stream, Annotations, and Loading States
to show the interaction engine and application states in more detail.

See the repository [release checklist](../doc/release_checklist.md) for capture
sizes and the public deployment workflow. For the API contract behind the
Chart Artifacts page, see [Portable chart artifacts](../doc/chart_artifacts.md).
For the reusable Chart/Data/Split composition shown by Chart Workbench, see
[Chart Workbench](../doc/chart_workbench.md) and
[Chart Document Comparison](../doc/chart_comparison.md).
