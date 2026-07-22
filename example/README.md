# Braven Charts showcase

This Flutter application is the runnable product tour for Braven Charts. It is
also the source for pub.dev screenshots and the public web demo.

[**Open the public Braven Charts showcase →**](https://braven-pvm.github.io/braven_charts/)

[**Open Chart Workbench directly →**](https://braven-pvm.github.io/braven_charts/?page=chart-workbench)

[**Open Chart Grammar directly →**](https://braven-pvm.github.io/braven_charts/?page=chart-grammar)

[**Open Pie Charts directly →**](https://braven-pvm.github.io/braven_charts/?page=pie-charts)

[**Open the chart-family overview →**](https://braven-pvm.github.io/braven_charts/?page=chart-types)

[**Open Candlestick Charts directly →**](https://braven-pvm.github.io/braven_charts/?page=candlestick-charts)

[**Open Range Area Charts directly →**](https://braven-pvm.github.io/braven_charts/?page=range-area-charts)

[**Open Tracking & Value Display directly →**](https://braven-pvm.github.io/braven_charts/?page=value-summary)

[**Open Donut Charts directly →**](https://braven-pvm.github.io/braven_charts/?page=donut-charts)

[**Open Concentric Donut directly →**](https://braven-pvm.github.io/braven_charts/?page=concentric-donut)

[**Open Polar Column directly →**](https://braven-pvm.github.io/braven_charts/?page=polar-column)

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
| Gallery | Start with a native-rendered ten-family sampler, then compare a readable multi-axis session profile, three native Range Area compositions, a synchronized Line/Area composition with a reusable full-domain navigator, a dense analytical composition, and production-shaped Cartesian, partition-radial, and Polar Column examples |
| Chart Types | Choose between line, area, Range Area, bar, scatter, Candlestick, Pie, Donut, Concentric Donut, and Polar Column from a concise visual overview; each family links to its own runnable guide |
| Line Charts | Compare the workhorse composition, four interpolation modes, independently scaled multi-axis signals, and explicit three-series entrance/value/append/remove/rolling-window timing; use Synchronized's full-distance navigator across three independent plots; inspect the same mounted chart in resizable Chart/Data/Split/Source views and copy its effective Dart |
| Area Charts | Compare layered magnitude, positive and negative baseline fills, observed-versus-forecast compositions, and explicit two-layer fill/outline value and boundary-topology timing; use Forecast's full-time-domain navigator; inspect the same mounted chart in resizable Chart/Data/Split/Source views and copy its effective Dart |
| Range Area Charts | Compare temperature, seasonal, confidence, nested forecast fan, volatility, and stepped-gap intervals; vary count and breadth; configure fill, boundaries, labels, tracking, summaries, and motion; inspect every preset in Chart/Data/Split/Source |
| Technical Indicators | Compose a native 20-session Range Area volatility envelope with Candlestick and Line overlays, synchronized volume/MACD/momentum panes, and one shared navigator |
| Bar Charts | Explore grouped, stacked, normalized, overlaid, horizontal, range, waterfall, tracked, target-marked, uncertainty-aware, animated, and precision-styled bars through the complete Bar API and generated source; use Categories' snapped navigator across a dense categorical domain |
| Scatter Charts | Compare fixed and point-styled marks, unsorted and stress datasets, interaction states, area-correct bubbles, continuous and piecewise colour scales, and opacity encodings; use Correlation's binned-distribution navigator without reordering its raw points; inspect the same values in Chart/Data/Split/Source modes |
| Candlestick Charts | Explore typed OHLC rendering, elapsed and ordinal spacing, mixed analytical overlays, live latest-candle revision, dense-data grouping, and synchronized price/volume panes controlled by the public Cartesian navigator |
| Pie Charts | Apply complete simple, editorial, compact, elevated, or high-contrast presentations; compare category stories; refine palettes, solid/linear/radial fills, labels, geometry, callouts, tooltips, legends, and motion; select linked rows; inspect generated source; and capture or restore a portable artifact |
| Donut Charts | Compare full, partial, and variable-radius rings; switch Chart/Data/Split/Source views; replace legend items with host-built Flutter widgets; link center content to slice, legend, table, and controller selection; then capture JSON and PNG and restore a fresh runtime |
| Concentric Donut | Compare independent totals across weighted rings; resize Chart/Data/Split panes; inspect exact generated Source; test grouped or flat legends, one shared center, composition-wide lift selection, coordinated labels, and portable capture/restoration |
| Polar Column | Compare standard linear-radius columns, an area-correct Nightingale rose, and a partial annular sweep; tune both Polar axes; then inspect the value-only native table, generated Source, and portable document |
| Interaction | Zoom and pan with pointer, touch, toolbar, and keyboard input; compare crosshair modes, snap-to-point behavior, tracking panels, and styled tooltips; use the Navigator pattern to change point density and drive one shared viewport through either direct manipulation or `ChartInteractionGroupController` commands |
| Tracking & Value Display | Compose every tracking feedback layer independently — crosshair lines, the classic tracking panel, point tooltips, axis value labels, intersection markers, and data point markers — around the flagship value summary: a persistent policy-resolved panel with latest-value fallback, multi-axis units, candlestick OHLC rows, a synchronized pair resolving locally at a shared X, programmatic pinning, and tri-state styling with truly transparent clears |
| Chart Grammar | Author line-plus-trend, multi-axis, channel-encoded scatter, candlestick, and transposed bar charts entirely with the chained `BravenChart` facade — no `ChartSeries` anywhere; read the generated chain in the workbench Source tab's Grammar form, prove the lowering across Chart/Data/Split/Source, and swap in the hand-written `BravenChartPlus` equivalent to see the two are indistinguishable |
| Annotations | Point, range, text, threshold, trend, pin, legend, and editing workflows |
| Live Stream | Compare follow-latest, pause/buffer, expand, and high-frequency strategies; use Live Navigator to keep frame-coalesced ingest active while inspecting retained history and return explicitly to the newest samples |
| Theming | Light, dark, accessible, and custom chart themes |
| Axes | Labels, formatting, minor ticks, explicit ranges, spacing, and render bounds |
| Multi-Axis | Independent Y units, shared axes, normalization, visible slots, overflow, and runtime series selection |
| Scientific | Dense measurement data and scientific formatting |
| Series Styling | Conditional colors, per-segment styles, gradients, markers, point labels, glow, and alert thresholds |
| Baseline Fill | Positive/negative and above/below-target area fills |
| Loading States | Animated chart skeleton, circular/linear progress, empty results, and custom state content |
| Performance | Large data sets and rendering diagnostics |
| Chart Artifacts | Capture effective chart state, switch between chart/table/restored views, inspect canonical JSON, and restore an independent chart |
| Chart Workbench | Keep one chart mounted across Chart/Data/Split/Source views, control the shared showcase-wide mode and selector visibility, copy generated Dart, link rows to points, inspect captured JSON and diagnostics, recover table or source failures, refresh a bounded-stream snapshot deliberately, and prove three hydrated charts remain independent |

The chart-family hierarchy is intentionally extensible. A new family joins the
overview and nested navigation only when its package API and full runnable
guide are ready, avoiding placeholder public pages.

The showcase wraps all chart-family Workbenches in one
`ChartWorkbenchScope`. Choose a presentation on any chart page and the next
chart retains it; use Chart Workbench's Shared presentation controls to change
the mode or show/hide the selector for the entire application.

## Interaction shortcuts

- Hover a series or marker for its tooltip.
- Move across a tracking chart to inspect synchronized series values.
- Drag to pan; hold Shift while using the wheel to zoom around the pointer.
- Use scrollbars where enabled to inspect a constrained viewport.
- Drag a Cartesian navigator window or resize either edge and confirm every
  attached chart follows the same data-X viewport while the overview stays
  full-domain.
- On Chart Workbench, right-click a chart or press Shift+F10 to run native host
  actions, or use its compact top-left chart action. Long press is enabled on
  its focused examples for touch review.
- Select a legend entry or series in multi-axis demos to exercise axis slots.
- Select a pie slice, legend item, or table row and confirm all three surfaces stay linked.
- Select a Donut slice, legend item, or table row and confirm the center follows the same identity.
- Select a Polar column or table row and confirm its category/value identity remains linked without a derived share.
- Pause live streams, allow points to buffer, then resume.
- Open annotation controls to create, edit, drag, or remove overlays.

## Responsive navigation

Desktop and tablet layouts use the complete scrollable feature rail. Phone
layouts automatically switch to a focused chart-family browser with three
production-shaped, vertically scrolling examples per family. The phone-sized
examples preserve representative chart grammar—including forecast segments,
baseline fills, nested intervals, diverging bars, bubble encodings, financial
overlays, and radial compositions—without carrying desktop labs or large
datasets into a narrow viewport. A compact Vivid, Midnight, and Calm selector
demonstrates complete chart treatments, and every example uses
reduced-motion-aware entrance animation. The phone surface covers Line, Area,
Range Area, Bar, Scatter, Candlestick, Pie, Donut, Concentric Donut, and Polar
Column. Direct chart-family links select the matching phone example.

## Screenshot routes

The Gallery is designed as the primary pub.dev image. Focused screenshots can
also be captured from Line Charts, Area Charts, Bar Charts, Scatter Charts,
Range Area Charts, Candlestick Charts, Pie Charts, Donut Charts, Concentric
Donut, Polar Column, Chart Grammar, Tracking & Value Display, Multi-Axis, Live
Stream, Annotations, and Loading States to show path motion, workbench
composition, radial rendering, categorical composition, the interaction engine,
and application states in more detail.

See the repository [release checklist](../doc/release_checklist.md) for capture
sizes and the public deployment workflow. For the API contract behind the
Chart Artifacts page, see [Portable chart artifacts](../doc/chart_artifacts.md).
For the reusable Chart/Data/Split/Source composition shown by Chart Workbench, see
[Chart Workbench](../doc/chart_workbench.md) and
[Chart Document Comparison](../doc/chart_comparison.md).
For radial series contracts, see [Pie charts](../doc/pie_charts.md),
[Donut charts](../doc/donut_charts.md), and
[Concentric Donut charts](../doc/concentric_donut_charts.md).
For axis-based cyclical magnitude, see
[Polar Column and Rose charts](../doc/polar_column_charts.md).
For path-series motion, streaming boundaries, and the Line/Area workbench, see
[Line and Area charts](../doc/line_area_charts.md).
For paired low/high intervals, nested bands, gaps, typed tracking, and portable
surfaces, see [Range Area charts](../doc/range_area_charts.md).
For typed marks and encodings, checked lowering, verified Workbench source, and
the opt-in generated fluent configuration surface, see
[Chart Grammar and fluent configuration](../doc/chart_grammar.md).
