# Braven Charts showcase

This Flutter application is the runnable product tour for Braven Charts. It is
also the source for pub.dev screenshots and the public web demo.

[**Open the public Braven Charts showcase →**](https://braven-pvm.github.io/braven_charts/)

[**Open Chart Workbench directly →**](https://braven-pvm.github.io/braven_charts/?page=chart-workbench)

[**Open Pie Charts directly →**](https://braven-pvm.github.io/braven_charts/?page=pie-charts)

[**Open the chart-family overview →**](https://braven-pvm.github.io/braven_charts/?page=chart-types)

[**Open Donut Charts directly →**](https://braven-pvm.github.io/braven_charts/?page=donut-charts)

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
| Gallery | Start with a native-rendered six-family sampler, then compare a readable multi-axis session profile, a dense analytical composition, and production-shaped Pie, Donut, Cartesian, and mixed-series examples |
| Chart Types | Choose between line, area, bar, scatter, Pie, and Donut from a concise visual overview; each family links to its own runnable guide |
| Line Charts | Compare the workhorse composition, four interpolation modes, and independently scaled multi-axis signals; tune stroke, glow, markers, labels, tracking, zoom, and pan |
| Area Charts | Compare layered magnitude, positive and negative baseline fills, and observed-versus-forecast compositions; tune opacity and baseline behavior |
| Bar Charts | Explore grouped, stacked, normalized, overlaid, horizontal, range, waterfall, tracked, target-marked, uncertainty-aware, animated, and precision-styled bars through the complete Bar API |
| Scatter Charts | Compare cohorts, correlation with a trend annotation, and explicit outlier styling; tune marker size and point-level inspection |
| Pie Charts | Apply complete simple, editorial, compact, elevated, or high-contrast presentations; compare category stories; refine palettes, solid/linear/radial fills, labels, geometry, callouts, tooltips, legends, and motion; select linked rows; and capture or restore a portable artifact |
| Donut Charts | Compare full, partial, and variable-radius rings; switch Chart/Data/Split views; replace legend items with host-built Flutter widgets; link center content to slice, legend, table, and controller selection; then capture JSON and PNG and restore a fresh runtime |
| Interaction | Zoom and pan with pointer, touch, toolbar, and keyboard input; compare crosshair modes, snap-to-point behavior, tracking panels, and styled tooltips |
| Annotations | Point, range, text, threshold, trend, pin, legend, and editing workflows |
| Live Stream | Follow-latest viewports, frame-coalesced ingestion, pause/resume, buffering, and catch-up |
| Theming | Light, dark, accessible, and custom chart themes |
| Axes | Labels, formatting, minor ticks, explicit ranges, spacing, and render bounds |
| Multi-Axis | Independent Y units, shared axes, normalization, visible slots, overflow, and runtime series selection |
| Scientific | Dense measurement data and scientific formatting |
| Series Styling | Conditional colors, per-segment styles, gradients, markers, point labels, glow, and alert thresholds |
| Baseline Fill | Positive/negative and above/below-target area fills |
| Loading States | Animated chart skeleton, circular/linear progress, empty results, and custom state content |
| Performance | Large data sets and rendering diagnostics |
| Chart Artifacts | Capture effective chart state, switch between chart/table/restored views, inspect canonical JSON, and restore an independent chart |
| Chart Workbench | Keep one chart mounted across Chart/Data/Split views, link rows to points, inspect captured JSON and diagnostics, recover table failures, refresh a bounded-stream snapshot deliberately, and prove three hydrated charts remain independent |

The chart-family hierarchy is intentionally extensible. A new family joins the
overview and nested navigation only when its package API and full runnable
guide are ready, avoiding placeholder public pages.

## Interaction shortcuts

- Hover a series or marker for its tooltip.
- Move across a tracking chart to inspect synchronized series values.
- Drag to pan; hold Shift while using the wheel to zoom around the pointer.
- Use scrollbars where enabled to inspect a constrained viewport.
- Select a legend entry or series in multi-axis demos to exercise axis slots.
- Select a pie slice, legend item, or table row and confirm all three surfaces stay linked.
- Select a Donut slice, legend item, or table row and confirm the center follows the same identity.
- Pause live streams, allow points to buffer, then resume.
- Open annotation controls to create, edit, drag, or remove overlays.

## Responsive navigation

Desktop and tablet layouts use a scrollable feature rail. Narrow layouts use a
drawer so every demo remains reachable without an oversized bottom navigation
bar.

## Screenshot routes

The Gallery is designed as the primary pub.dev image. Focused screenshots can
also be captured from Pie Charts, Donut Charts, Bar Charts, Multi-Axis, Live
Stream, Annotations, and Loading States to show radial rendering, categorical
composition, the interaction engine, and application states in more detail.

See the repository [release checklist](../doc/release_checklist.md) for capture
sizes and the public deployment workflow. For the API contract behind the
Chart Artifacts page, see [Portable chart artifacts](../doc/chart_artifacts.md).
For the reusable Chart/Data/Split composition shown by Chart Workbench, see
[Chart Workbench](../doc/chart_workbench.md) and
[Chart Document Comparison](../doc/chart_comparison.md).
For radial series contracts, see [Pie charts](../doc/pie_charts.md) and
[Donut charts](../doc/donut_charts.md).
