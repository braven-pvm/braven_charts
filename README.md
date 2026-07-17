# Braven Charts

[![Pub version](https://img.shields.io/pub/v/braven_charts.svg)](https://pub.dev/packages/braven_charts)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.35-02569B.svg)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/license-MIT-0F766E.svg)](https://github.com/braven-pvm/braven_charts/blob/master/LICENSE)

Braven Charts is a pure Dart charting library for Flutter applications. Chart
rendering and interaction use a custom `RenderBox` and Flutter `Canvas`; the
package does not embed a JavaScript charting engine.

`BravenChartPlus` supports line, area, bar, scatter, mixed Cartesian series,
and single-series pie charts; multiple independent axes and normalization;
zoom, pan, scrollbars, tracking, tooltips, and editable annotations;
frame-coalesced live data; configurable themes and state views; chart/table
display modes; and portable chart artifacts. Rendering, input handling, and
streaming updates remain inside the Flutter rendering pipeline.

For update-heavy charts, the implementation uses cached series layers, a
spatial hit-test index, frame-coalesced point delivery, and a direct render-box
streaming path so each sample does not require a widget-tree rebuild.

[Live showcase and runnable examples](https://braven-pvm.github.io/braven_charts/)

## Rendered examples

| Mixed series, tracking, and annotations | Dark baseline fill, glow, and sections |
| --- | --- |
| [![Threshold exposure chart with styled bars, cardiac drift, LT1 annotations, and a trend line](https://raw.githubusercontent.com/braven-pvm/braven_charts/v0.1.4/doc/screenshots/hero_threshold.png)](https://braven-pvm.github.io/braven_charts/) | [![Power-duration chart with six curves, positive and negative baseline fill, glow, annotations, and a scrollbar](https://raw.githubusercontent.com/braven-pvm/braven_charts/v0.1.4/doc/screenshots/hero_power_duration.png)](https://braven-pvm.github.io/braven_charts/) |

### Multi-axis interaction

The example below combines four independently scaled series with per-series
normalization, range and threshold annotations, tracking tooltips, pointer
zoom, drag-to-pan, and a synchronized X scrollbar.

[![Four-axis chart with annotations, tracking, zoom, pan, and a synchronized scrollbar](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/interaction_demo.gif)](https://braven-pvm.github.io/braven_charts/)

### Live-stream buffering

`LiveStreamController` sends frame-coalesced point updates directly to the
rendering layer. The viewport can follow the latest sample, pause while the
bounded buffer continues receiving data, and resume with buffered catch-up.

[![Live chart data buffering and catching up](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/live_stream_demo.gif)](https://braven-pvm.github.io/braven_charts/?page=live-stream)

## Gallery

The Gallery combines curated and full-catalog views across Pie, line, area,
bar, scatter, and mixed compositions. It covers light and dark Pie treatments,
inside and collision-aware outside labels, dense categories, rounded and
elevated slices, solid and gradient fills, baseline fills, live data,
independent axes, annotations,
interpolation, thresholds, and domain-shaped dashboards.

[![Five themed and configured Pie chart compositions from the public Gallery](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/gallery_pie_collection.png)](https://braven-pvm.github.io/braven_charts/?page=gallery)

The wider Cartesian catalog remains available in the current Gallery mosaic:

[![Varied Braven Charts compositions from the current Gallery](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/gallery_mosaic.png)](https://braven-pvm.github.io/braven_charts/)

## Feature coverage

| Area | API and behavior |
| --- | --- |
| Rendering | Pure Dart on Flutter's `RenderBox`/`Canvas` pipeline, cached series layers, and no embedded JavaScript chart engine |
| Interaction | Pointer and touch zoom, pan, X/Y scrollbars, hover tooltips, crosshairs, and tracking panels |
| Data series | Line, area, bar, scatter, mixed Cartesian series, and category-based pie charts with labels, positioned legends, solid/gradient fills, rounded/translucent slices, elevation, selection, and animation |
| Axes | Configurable X axis, multiple independent Y axes, shared axes, automatic or per-series normalization, and visible-axis slots |
| Annotations | Point, range, text, threshold, trend, chord, pin, and legend annotations with interactive editing |
| Live data | Frame-coalesced point ingestion, bounded buffers, follow-latest viewports, pause/resume, and buffered catch-up |
| Display | Light/dark and custom themes, legends, labels, package-owned Chart/Data/Split workbenches, loading skeletons, progress indicators, and empty states |
| Application control | Controllers, callbacks, runtime series selection, annotation management, axis-slot state, and serializable chart configuration |
| Portable artifacts | Capture effective chart state, persist canonical JSON, render exact-X or category/share data tables with native copy/CSV actions, attach previews, and hydrate fresh interactive charts |
| Document comparison | Explicit semantic series mapping, exact-X or timestamp alignment, safe units, missing values, deltas, and source-preserving CSV export |

The [live showcase](https://braven-pvm.github.io/braven_charts/) provides
runnable examples and configuration controls for these APIs. See the
[showcase guide](https://github.com/braven-pvm/braven_charts/blob/master/example/README.md)
for the feature-to-page map and local run instructions.
[Open Chart Workbench directly](https://braven-pvm.github.io/braven_charts/?page=chart-workbench)
to try the package-owned Chart/Data/Split workflow, linked point selection,
artifact capture, deliberate table freshness, and document comparison.
[Open Pie Charts directly](https://braven-pvm.github.io/braven_charts/?page=pie-charts)
to try category datasets, inside/outside labels, slice selection, native data
tables, artifact capture, previews, and restored charts.

## Install

Add the package to your app:

```yaml
dependencies:
  braven_charts: ^0.4.0
```

Then fetch dependencies:

```bash
flutter pub get
```

Braven Charts 0.4.0 requires Dart 3.9 or later and Flutter 3.35 or later.

## Quick start

```dart
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

class RevenueChart extends StatelessWidget {
  const RevenueChart({super.key});

  @override
  Widget build(BuildContext context) {
    return BravenChartPlus(
      title: 'Revenue',
      subtitle: 'Last 6 months',
      series: const [
        LineChartSeries(
          id: 'revenue',
          name: 'Revenue',
          unit: 'USD',
          color: Color(0xFF0F766E),
          interpolation: LineInterpolation.bezier,
          showDataPointMarkers: true,
          points: [
            ChartDataPoint(x: 1, y: 45000),
            ChartDataPoint(x: 2, y: 52000),
            ChartDataPoint(x: 3, y: 49000),
            ChartDataPoint(x: 4, y: 63000),
            ChartDataPoint(x: 5, y: 71000),
            ChartDataPoint(x: 6, y: 68000),
          ],
        ),
      ],
      xAxisConfig: const XAxisConfig(label: 'Month'),
      yAxis: const YAxisConfig(label: 'Revenue', unit: 'USD'),
      interactionConfig: const InteractionConfig(
        crosshair: CrosshairConfig(
          enabled: true,
          mode: CrosshairMode.both,
          snapToDataPoint: true,
          displayMode: CrosshairDisplayMode.tracking,
        ),
        tooltip: TooltipConfig(enabled: true),
      ),
    );
  }
}
```

## Multi-axis and normalization

Attach a `YAxisConfig` directly to each series when measurements use different
units or scales. Braven Charts can normalize each series for a shared plot while
keeping labels, tracking values, and tooltips in their original units.

```dart
BravenChartPlus(
  normalizationMode: NormalizationMode.perSeries,
  series: [
    LineChartSeries(
      id: 'power',
      name: 'Power',
      unit: 'W',
      points: powerPoints,
      yAxisConfig: const YAxisConfig(
        label: 'Power',
        unit: 'W',
        position: YAxisPosition.left,
      ),
    ),
    LineChartSeries(
      id: 'heart-rate',
      name: 'Heart rate',
      unit: 'bpm',
      points: heartRatePoints,
      yAxisConfig: const YAxisConfig(
        label: 'Heart rate',
        unit: 'bpm',
        position: YAxisPosition.right,
      ),
    ),
  ],
)
```

## Pie charts

Pie charts use one `PieChartSeries`; they do not mix with Cartesian series or
use axes, crosshairs, pan, or zoom. Map insertion order becomes stable slice
order, while the category string becomes the visible and accessible label.

```dart
BravenChartPlus(
  title: 'Revenue contribution',
  series: [
    PieChartSeries.fromMap(
      id: 'revenue-share',
      name: 'Revenue share',
      unit: 'USD',
      values: const {
        'Subscriptions': 42,
        'Services': 31,
        'Hardware': 27,
      },
      pieStyle: const PieChartStyle(
        gradient: PieGradientStyle(type: PieGradientType.radial),
      ),
      dataLabels: const PieDataLabelConfig(
        position: PieDataLabelPosition.outside,
        content: PieDataLabelContent.categoryAndPercentage,
      ),
    ),
  ],
  interactionConfig: const InteractionConfig(
    tooltip: TooltipConfig(enabled: true),
  ),
)
```

Pie values must be finite and non-negative. Zero values remain portable and
appear in the native table but do not paint a slice; an all-zero dataset uses
the configured empty state. See the
[Pie chart guide](https://github.com/braven-pvm/braven_charts/blob/master/doc/pie_charts.md)
for fills, labels, selection, tables, artifacts, validation, and
accessibility.

## Loading and empty states

`isLoading` replaces the plot viewport without changing the surrounding layout.
The default is an animated, theme-aware chart skeleton with reduced-motion
support and soft edge fades. Circular, linear, determinate, and fully custom
states are also available.

```dart
BravenChartPlus(
  series: series,
  isLoading: isLoading,
  loadingConfig: const ChartLoadingConfig.skeleton(),
  emptyStateConfig: const ChartEmptyStateConfig(
    title: 'No workout samples',
    message: 'Import a workout or change the selected date range.',
  ),
)
```

Customize only the skeleton characteristics your product needs:

```dart
loadingConfig: const ChartLoadingConfig.skeleton(
  skeletonStyle: ChartLoadingSkeletonStyle(
    seriesColor: Color(0xFF6D28D9),
    secondarySeriesColor: Color(0xFFEC4899),
    animationDuration: Duration(milliseconds: 1800),
    motionIntensity: 0.8,
    edgeFadeFraction: 0.16,
  ),
),
```

## Live data

`LiveStreamController` accepts individual or batched points without rebuilding
the chart widget for every sample. It exposes pause/resume state, buffered point
counts, bounds, the latest point, and a snapshot of the active buffer.

```dart
final liveController = LiveStreamController(
  seriesId: 'sensor',
  maxPoints: 1000,
);

liveController.addPoint(
  ChartDataPoint(
    x: DateTime.now().millisecondsSinceEpoch.toDouble(),
    y: sensorReading,
  ),
);

BravenChartPlus(
  series: const [
    LineChartSeries(
      id: 'sensor',
      name: 'Sensor',
      points: [],
    ),
  ],
  liveStreamController: liveController,
)
```

Dispose controllers you create when the owning widget is disposed.

## Programmatic control

The package provides focused controller APIs rather than requiring access to
rendering internals:

- `BravenChartController` selects series and exposes visible/overflow Y-axis
  slots.
- `ChartController` manages runtime point collections and annotations.
- `AnnotationController` coordinates interactive annotation workflows.
- `StreamingController` and `LiveStreamController` control viewport and live
  ingestion state.
- `ChartConfigBuilder` and the agent interface support serializable,
  tool-driven chart construction.

See [Public API overview](https://github.com/braven-pvm/braven_charts/blob/master/doc/api_reference.md) for the exported surface and
the API documentation generated by pub.dev for member-level reference.

## Portable chart artifacts

For a reusable product surface, wrap a chart in `BravenChartWorkbench`. It keeps
one chart runtime mounted while users switch between Chart, Data, and responsive
Split modes, and gives host actions a stable handle for refresh and artifact
capture:

```dart
BravenChartWorkbench(
  initialDisplayMode: ChartDisplayMode.split,
  tableRefreshPolicy: ChartTableRefreshPolicy.onDocumentRevision,
  chartBuilder: (context, controller) => BravenChartPlus(
    bravenChartController: controller,
    series: series,
  ),
  actionsBuilder: (context, handle) => [
    FilledButton(
      onPressed: handle.isExtractingArtifact
          ? null
          : () => addToReport(handle),
      child: const Text('Add to report'),
    ),
  ],
)
```

The package manages chart/table lifecycle and structured extraction state; the
workbench also links table focus and activation to revision-safe chart point
focus/selection by default. Wide rows target every populated series at their
exact X value, and a successful linked selection rebases the table snapshot so
the next row remains usable. The host owns action policy, artifact IDs,
persistence, and navigation. Initial and refresh failures retain explicit
recovery actions, and manual refresh is the recommended policy when a bounded
live stream should not rewrite a visible table at sample cadence. See the
[Chart Workbench guide](https://github.com/braven-pvm/braven_charts/blob/master/doc/chart_workbench.md)
for refresh policies, point identity, responsive semantics, status, and
controller ownership.

For two or more saved documents, `ChartComparisonBuilder` provides explicit
series mapping, exact-X or timestamp alignment, missing-value state, safe unit
conversion, optional deltas, and source-preserving CSV export. It never infers
identity from display names or owns a comparison repository/screen. See the
[Chart Document Comparison guide](https://github.com/braven-pvm/braven_charts/blob/master/doc/chart_comparison.md).

### Capture and transport

Capture a mounted chart once and reuse the same effective state for storage,
sharing, previews, data tables, or a restored interactive copy. Artifacts are
validated, deterministic, schema-versioned, and safe by construction: JSON
contains descriptors rather than executable callbacks or class names.

```dart
final result = await chartController.extractArtifact(
  const ChartArtifactExtractOptions(
    includePreview: true,
    documentOptions: ChartDocumentExtractOptions(
      dataStorage: ChartDataStorage.inlineColumns,
    ),
  ),
);

if (result case ChartArtifactSuccess<ChartArtifact>()) {
  final json = ChartArtifactJsonCodec.encode(result.value);
  // Persist json.value when encoding succeeds; inspect warnings as needed.
}
```

`ChartDataTable` includes bounded whole-dataset clipboard copy, per-row copy,
and raw-value CSV export. Web builds download CSV directly; non-web hosts can
provide delivery callbacks for their file or share-sheet workflow.

For the complete capture, table, transport, hydration, resolver, migration,
and runtime-binding contracts, read the
[portable chart artifact guide](https://github.com/braven-pvm/braven_charts/blob/master/doc/chart_artifacts.md).

## Run the showcase

[Open the hosted showcase](https://braven-pvm.github.io/braven_charts/), or run
the same application locally:

```bash
cd example
flutter pub get
flutter run -d chrome
```

The showcase is responsive: desktop uses a persistent feature rail, while
smaller screens use a navigation drawer. It includes gallery-ready examples and
focused pages for chart types, pie charts, interaction, tracking, annotations,
streaming, theming, performance, multi-axis layouts, scientific data, baseline
fills, and state UX.

## Documentation

- [Live interactive showcase](https://braven-pvm.github.io/braven_charts/)
- [Showcase and examples](https://github.com/braven-pvm/braven_charts/blob/master/example/README.md)
- [Public API overview](https://github.com/braven-pvm/braven_charts/blob/master/doc/api_reference.md)
- [Pie charts](https://github.com/braven-pvm/braven_charts/blob/master/doc/pie_charts.md)
- [Portable chart artifacts](https://github.com/braven-pvm/braven_charts/blob/master/doc/chart_artifacts.md)
- [Chart Workbench](https://github.com/braven-pvm/braven_charts/blob/master/doc/chart_workbench.md)
- [Chart Document Comparison](https://github.com/braven-pvm/braven_charts/blob/master/doc/chart_comparison.md)
- [Feature coverage matrix](https://github.com/braven-pvm/braven_charts/blob/master/doc/feature_matrix.md)
- [Release and publishing checklist](https://github.com/braven-pvm/braven_charts/blob/master/doc/release_checklist.md)
- [Issue and delivery workflow](https://github.com/braven-pvm/braven_charts/blob/master/docs/issue_workflow.md)
- [Changelog](https://github.com/braven-pvm/braven_charts/blob/master/CHANGELOG.md)
- [Contributing](https://github.com/braven-pvm/braven_charts/blob/master/CONTRIBUTING.md)

Pub.dev generates and hosts member-level API documentation from the package's
`///` documentation comments for every published version.

## License

Braven Charts is available under the [MIT License](https://github.com/braven-pvm/braven_charts/blob/master/LICENSE).
