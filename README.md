# Braven Charts

[![Pub version](https://img.shields.io/pub/v/braven_charts.svg)](https://pub.dev/packages/braven_charts)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.35-02569B.svg)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/license-MIT-0F766E.svg)](https://github.com/braven-pvm/braven_charts/blob/master/LICENSE)

Braven Charts is a pure Dart charting library for Flutter applications. Chart
rendering and interaction use a custom `RenderBox` and Flutter `Canvas`; the
package does not embed a JavaScript charting engine.

`BravenChartPlus` supports line, area, bar, scatter, mixed Cartesian series,
Pie, Donut, and multi-ring Concentric Donut charts; multiple independent axes
and normalization; zoom, pan, scrollbars, tracking, tooltips, and editable annotations;
frame-coalesced live data; configurable themes and state views; chart, table,
split, and generated Dart source modes; and portable chart artifacts. Rendering,
input handling, and streaming updates remain inside the Flutter rendering pipeline.

For update-heavy charts, the implementation uses cached series layers, a
spatial hit-test index, frame-coalesced point delivery, and a direct render-box
streaming path so each sample does not require a widget-tree rebuild.

[Live showcase and runnable examples](https://braven-pvm.github.io/braven_charts/)

## What's new in 0.9.0

- **Expressive Scatter charts:** map independent point values to area-correct
  marker size, continuous or threshold-based colour, and opacity. Configure
  marker shape, fill, outline, dimensions, rotation, hover, press, selection,
  and focus without giving up point-accurate tracking or unsorted data.
- **Portable analytical channels:** Scatter encodings and resolved values flow
  through quantitative legends, tooltips, tables, CSV, artifacts, hydration,
  and deterministic generated Dart source.
- **Synchronized Cartesian composition:** a caller-owned
  `ChartInteractionGroupController` shares a semantic data-X cursor and X-only
  viewport across independent charts while each chart retains its local Y
  scale, tooltip, selection, annotations, and artifact boundary.
- **Deeper public examples:** the Scatter guide now covers fixed markers,
  styling, stress, unsorted data, interaction states, bubbles, colour scales,
  risk bands, and opacity in the common Chart/Data/Split/Source Workbench. The
  Gallery adds three production-shaped Scatter compositions and a synchronized
  route profile.

[Open the Scatter guide](https://braven-pvm.github.io/braven_charts/?page=scatter-charts&preset=bubble),
[open the synchronized example](https://braven-pvm.github.io/braven_charts/?page=line-charts&preset=synchronized),
or review the [0.9.0 changelog](https://github.com/braven-pvm/braven_charts/blob/master/CHANGELOG.md#090---2026-07-19)
for the complete API-level release notes.

## Rendered examples

Every image below opens the matching interactive example and configuration
surface in the public showcase. The compact grid provides a visual index of the
package rather than treating a single composition as representative.

### Chart types

| Line | Area | Bar |
| --- | --- | --- |
| [![Linear, Bezier, stepped, and monotone line interpolation](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/gallery_interpolation.png)](https://braven-pvm.github.io/braven_charts/?page=line-charts) | [![Positive and negative baseline area fill across independently scaled series](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/gallery_baseline.png)](https://braven-pvm.github.io/braven_charts/?page=area-charts) | [![Grouped bars with gradients, targets, uncertainty intervals, and tracking](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/bar_targets_interaction.png)](https://braven-pvm.github.io/braven_charts/?page=bar-charts&preset=targets) |
| **Scatter** | **Pie** | **Donut** |
| [![Scatter chart type with independent point markers](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/chart_type_scatter.png)](https://braven-pvm.github.io/braven_charts/?page=scatter-charts) | [![Pie allocation with gradients, rounded slices, elevation, and a positioned legend](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/pie_portfolio_allocation.png)](https://braven-pvm.github.io/braven_charts/?page=pie-charts) | [![Dark partial-sweep Donut with center content and compact labels](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/donut_release_progress.png)](https://braven-pvm.github.io/braven_charts/?page=donut-charts) |

### Concentric Donut compositions

Each ring retains its own total and category shares. Ring order, thickness,
gaps, sweep, labels, legends, center content, and selection are configurable at
the composition or series level.

| Period comparison | Service-level health | Portfolio allocation |
| --- | --- | --- |
| [![Three revenue periods compared as independently weighted Concentric Donut rings](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/concentric_revenue_mix.png)](https://braven-pvm.github.io/braven_charts/?page=concentric-donut) | [![Three service regions compared as partial-sweep status rings](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/concentric_service_health.png)](https://braven-pvm.github.io/braven_charts/?page=concentric-donut) | [![Three portfolio mandates compared as weighted rings on a dark chart theme](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/concentric_portfolio.png)](https://braven-pvm.github.io/braven_charts/?page=concentric-donut) |

### Cartesian composition and Scatter encodings

Scatter keeps X/Y position independent from marker area, colour, opacity, and
shape. The same values remain inspectable in the chart, legend, tracking
surface, table, artifact, and generated Source. Independent Cartesian charts
can also share a data-X cursor and viewport without merging their local scales.

| Synchronized route profile | Bubble area and shape | Continuous colour |
| --- | --- | --- |
| [![Three independently scaled route metrics sharing one data-X cursor and viewport](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/synchronized_route_profile.png)](https://braven-pvm.github.io/braven_charts/?page=line-charts&preset=synchronized) | [![Market opportunity Scatter chart using area-correct bubbles and distinct marker shapes](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/scatter_market_opportunity.png)](https://braven-pvm.github.io/braven_charts/?page=scatter-charts&preset=bubble) | [![Athlete Scatter chart mapping recovery readiness to a continuous colour scale](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/scatter_athlete_readiness.png)](https://braven-pvm.github.io/braven_charts/?page=scatter-charts&preset=color%20scale) |
| **Piecewise risk bands** | **Line motion workbench** | **Area motion workbench** |
| [![Dark equipment Scatter chart with named piecewise risk bands](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/scatter_equipment_risk.png)](https://braven-pvm.github.io/braven_charts/?page=scatter-charts&preset=bands) | [![Line motion example in the resizable Chart and Data workbench](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/line_motion_workbench.png)](https://braven-pvm.github.io/braven_charts/?page=line-charts&preset=motion&view=split) | [![Area motion example in the resizable Chart and Data workbench](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/area_motion_workbench.png)](https://braven-pvm.github.io/braven_charts/?page=area-charts&preset=motion&view=split) |

### Bar compositions

The Bar API covers comparison, progress, interval, bridge, ranking, stacking,
and overlay layouts without reducing every dataset to another grouped column.
It also supports keyed and category-sequenced updates, durable point selection,
gradients, benchmark markers, and absolute uncertainty intervals.

| Capacity tracks | Waterfall bridge | Floating ranges |
| --- | --- | --- |
| [![Grouped capacity bars with planned and delivered tracks](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/bar_capacity.png)](https://braven-pvm.github.io/braven_charts/?page=bar-charts&preset=capacity) | [![Waterfall bridge with positive and negative deltas, connectors, and a resolved total](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/bar_waterfall.png)](https://braven-pvm.github.io/braven_charts/?page=bar-charts&preset=waterfall) | [![Paired floating temperature ranges with rounded gradient bars](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/bar_range.png)](https://braven-pvm.github.io/braven_charts/?page=bar-charts&preset=range) |
| **Horizontal ranking** | **Normalized stacks** | **Overlaid comparison** |
| [![Horizontal grouped bars ranking revenue channels](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/bar_horizontal.png)](https://braven-pvm.github.io/braven_charts/?page=bar-charts&preset=horizontal) | [![Dark normalized stacks comparing actual and planned channel composition](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/bar_normalized.png)](https://braven-pvm.github.io/braven_charts/?page=bar-charts&preset=normalized) | [![Wide plan bars overlaid with narrower actual completion values](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/bar_overlay.png)](https://braven-pvm.github.io/braven_charts/?page=bar-charts&preset=overlay) |
| **Capsule rods** | **Gradient groups** | **Signed variance** |
| [![Three latency percentiles rendered as slim capsule-shaped bars](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/bar_rods.png)](https://braven-pvm.github.io/braven_charts/?page=bar-charts&preset=rods) | [![Four pipeline stages grouped by quarter with vertical gradient fills](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/bar_gradient.png)](https://braven-pvm.github.io/braven_charts/?page=bar-charts&preset=gradient) | [![Positive and negative forecast variance around a shared zero baseline](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/bar_signed.png)](https://braven-pvm.github.io/braven_charts/?page=bar-charts&preset=signed) |
| **Offset comparison** | **Independent axes** | **Absolute stacks** |
| [![Neutral reference bars offset against per-point coloured qualification scores](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/bar_offset.png)](https://braven-pvm.github.io/braven_charts/?page=bar-charts&preset=offset) | [![Horizontal grouped bars using four independently scaled and coloured axes](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/bar_axes.png)](https://braven-pvm.github.io/braven_charts/?page=bar-charts&preset=axes) | [![Two named revenue stacks retaining absolute component totals](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/bar_stacked.png)](https://braven-pvm.github.io/braven_charts/?page=bar-charts&preset=stacked) |

### Interaction and motion

Each recording demonstrates one behavior rather than compressing the entire
interaction model into a single animation.

| Multi-series tracking | Zoom and drag-to-pan | Live-stream buffering |
| --- | --- | --- |
| [![Crosshair tracking across independently scaled line and area series](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/tracking_demo.gif)](https://braven-pvm.github.io/braven_charts/?page=interaction) | [![Pointer zoom and drag-to-pan on a dark multi-axis chart with a synchronized scrollbar](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/zoom_pan_demo.gif)](https://braven-pvm.github.io/braven_charts/?page=interaction) | [![Live chart pausing while points buffer and resuming with catch-up](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/live_stream_demo.gif)](https://braven-pvm.github.io/braven_charts/?page=live-stream) |
| **Donut selection** | **Live viewport** | **Normalized tracking** |
| [![Animated Donut selection with selection-aware center content](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/donut_selection_demo.gif)](https://braven-pvm.github.io/braven_charts/?page=donut-charts) | [![Live sensor viewport with bounded buffering and a synchronized scrollbar](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/gallery_live_sensor.png)](https://braven-pvm.github.io/braven_charts/?page=live-stream) | [![Normalized pressure and temperature signals with crosshair tracking](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/gallery_multi_sensor.png)](https://braven-pvm.github.io/braven_charts/?page=interaction) |

### Curated Gallery

These are the remaining compositions in the Gallery's curated tour: analytical
workflows, styling treatments, business charts, and radial presentations.

| Training profile | Power-duration model | Annotations |
| --- | --- | --- |
| [![Multi-axis training profile with stage bands, a target threshold, tracking, and a highlighted peak](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/hero_threshold.png)](https://braven-pvm.github.io/braven_charts/?page=gallery) | [![Dark power-duration model with six curves, baseline fill, glow, range sections, and a scrollbar](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/hero_power_duration.png)](https://braven-pvm.github.io/braven_charts/?page=multi-axis) | [![Point, range, and threshold annotations applied to an analysis](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/gallery_annotated.png)](https://braven-pvm.github.io/braven_charts/?page=annotations) |
| **VO2 stages** | **Signal glow** | **Lactate comparison** |
| [![Raw VO2 signal with stage averages, a target range, thresholds, and a VO2max event](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/gallery_vo2_stage.png)](https://braven-pvm.github.io/braven_charts/?page=scientific) | [![Dark chart with a glowing focus series, contextual area, inline labels, and a threshold](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/gallery_glow.png)](https://braven-pvm.github.io/braven_charts/?page=series-styling) | [![Reusable lactate analysis shown as reference and current-session small multiples](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/gallery_lactate.png)](https://braven-pvm.github.io/braven_charts/?page=scientific) |
| **Analytics dashboard** | **Monthly revenue** | **Temperature comparison** |
| [![Layered area and line series in a compact analytics dashboard](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/gallery_dashboard.png)](https://braven-pvm.github.io/braven_charts/?page=gallery) | [![Revenue curve with target annotation, markers, labels, and a themed plot area](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/gallery_monthly_revenue.png)](https://braven-pvm.github.io/braven_charts/?page=line-charts) | [![High and low temperature series with independent styling](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/gallery_temperature.png)](https://braven-pvm.github.io/braven_charts/?page=line-charts) |
| **Revenue forecast** | **Threshold segments** | **Positive and negative area** |
| [![Revenue line layered over a forecast area](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/gallery_revenue_forecast.png)](https://braven-pvm.github.io/braven_charts/?page=area-charts) | [![System load line whose segments change style at a threshold](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/gallery_system_load.png)](https://braven-pvm.github.io/braven_charts/?page=series-styling) | [![Dark profit and loss chart with positive and negative baseline areas](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/gallery_profit_loss.png)](https://braven-pvm.github.io/braven_charts/?page=baseline-fill) |
| **Revenue by product** | **Revenue contribution** | **Release effort** |
| [![Dark Pie chart with linear fills and value-first inside labels](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/pie_revenue_by_product.png)](https://braven-pvm.github.io/braven_charts/?page=pie-charts) | [![Pie chart with outside contribution labels and slice-derived borders](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/pie_revenue_contribution.png)](https://braven-pvm.github.io/braven_charts/?page=pie-charts) | [![Dark Pie chart with rounded slices and compact inside labels](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/pie_release_effort.png)](https://braven-pvm.github.io/braven_charts/?page=pie-charts) |
| **Support request mix** | **Subscription MRR** | **Channel efficiency** |
| [![Dense Pie categories with collision-aware outside callouts](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/pie_support_request_mix.png)](https://braven-pvm.github.io/braven_charts/?page=pie-charts) | [![Donut chart showing subscription mix with selection-aware center content](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/donut_revenue_ring.png)](https://braven-pvm.github.io/braven_charts/?page=donut-charts) | [![Variable-radius Donut chart encoding orders and audience reach](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/donut_campaign_reach.png)](https://braven-pvm.github.io/braven_charts/?page=donut-charts) |

## Feature coverage

| Area | API and behavior |
| --- | --- |
| Rendering | Pure Dart on Flutter's `RenderBox`/`Canvas` pipeline, cached series layers, and no embedded JavaScript chart engine |
| Interaction | Pointer and touch zoom, pan, X/Y scrollbars, hover tooltips, crosshairs, tracking panels, and opt-in data-X synchronization across independent Cartesian charts |
| Data series | Line and Area with explicit per-series entrance/update timing; Bar with accessible patterns, lollipop, Pareto and histogram compositions, bullet ranges and targets, and centered diverging/Likert stacks; Scatter with point styling plus independent size, colour, and opacity encodings; mixed Cartesian series; and category-based Pie, Donut, and Concentric Donut charts with labels, positioned legends, solid/gradient fills, three corner treatments, variable radii, center content, partial sweeps, elevation, selection, and animation |
| Axes | Configurable X axis, multiple independent Y axes, shared axes, automatic or per-series normalization, and visible-axis slots |
| Annotations | Point, range, text, threshold, trend, chord, pin, and legend annotations with interactive editing |
| Live data | Frame-coalesced point ingestion, bounded buffers, follow-latest viewports, pause/resume, and buffered catch-up |
| Display | Light/dark and custom themes, inherited right-to-left canvas text and semantics, legends, labels, package-owned Chart/Data/Split/Source workbenches, loading skeletons, progress indicators, and empty states |
| Developer tooling | Deterministic Dart generation from effective chart documents, selectable dark source viewport, bounded-data and runtime-callback diagnostics, exact copy, and configurable refresh policies |
| Application control | Controllers, callbacks, runtime series selection, annotation management, axis-slot state, synchronized Workbench presentation, synchronized Cartesian interaction, and serializable chart configuration |
| Portable artifacts | Capture effective chart state, persist canonical JSON, render exact-X or category/share data tables with native copy/CSV actions, attach previews, and hydrate fresh interactive charts |
| Document comparison | Explicit semantic series mapping, exact-X or timestamp alignment, safe units, missing values, deltas, and source-preserving CSV export |

The [live showcase](https://braven-pvm.github.io/braven_charts/) provides
runnable examples and configuration controls for these APIs. See the
[showcase guide](https://github.com/braven-pvm/braven_charts/blob/master/example/README.md)
for the feature-to-page map and local run instructions.
[Open Chart Workbench directly](https://braven-pvm.github.io/braven_charts/?page=chart-workbench)
to try the package-owned Chart/Data/Split/Source workflow, copy generated Dart,
link point selection, capture artifacts, control freshness, and compare documents.
[Open Pie Charts directly](https://braven-pvm.github.io/braven_charts/?page=pie-charts)
to try category datasets, inside/outside labels, slice selection, native data
tables, artifact capture, previews, and restored charts.
[Open Donut Charts directly](https://braven-pvm.github.io/braven_charts/?page=donut-charts)
to try full and partial rings, variable outer radii, selection-aware center
content, Chart/Data/Split views, native tables, and portable restoration.
[Open Line motion directly](https://braven-pvm.github.io/braven_charts/?page=line-charts&preset=motion&view=split)
or [open Area motion directly](https://braven-pvm.github.io/braven_charts/?page=area-charts&preset=motion&view=split)
to inspect entrance replay, compatible data updates, target-state tables, and
the resizable package-owned workbench.
[Open Concentric Donut directly](https://braven-pvm.github.io/braven_charts/?page=concentric-donut)
to compare independent totals across weighted rings, linked table rows,
grouped legends, one shared center, and portable restoration.

## Install

Add the package to your app:

```yaml
dependencies:
  braven_charts: ^0.9.0
```

Then fetch dependencies:

```bash
flutter pub get
```

Braven Charts 0.9.0 requires Dart 3.9 or later and Flutter 3.35 or later.

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
      // Optional: provide one second-metric value per category.
      radiusValues: const {
        'Subscriptions': 120,
        'Services': 90,
        'Hardware': 65,
      },
      sliceRadiusConfig: const PieSliceRadiusConfig(
        label: 'Market size',
        unit: 'k users',
      ),
      pieStyle: const PieChartStyle(
        gradient: PieGradientStyle(type: PieGradientType.radial),
      ),
      dataLabels: const PieDataLabelConfig(
        position: PieDataLabelPosition.outside,
        content: PieDataLabelContent.category,
        secondaryContent: PieDataLabelContent.percentage,
        secondaryPosition: PieDataLabelPosition.inside,
        insideOffset: 0, // Positive moves outward; negative moves inward.
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
the configured empty state. Optional radius values must be complete, finite,
and non-negative; they appear in tooltips, the table, CSV, AI input, and
portable artifacts. See the
[Pie chart guide](https://github.com/braven-pvm/braven_charts/blob/master/doc/pie_charts.md)
for fills, labels, selection, tables, artifacts, validation, and
accessibility.

## Donut charts

Donut uses the same ordered category contract as Pie, with a required shared
center opening and optional portable center text. The center can show the
total, the selected category value, a selected-or-total fallback, or custom
status text.

```dart
BravenChartPlus(
  series: [
    DonutChartSeries.fromMap(
      id: 'revenue-share',
      unit: 'USD',
      values: const {
        'Subscriptions': 42,
        'Services': 31,
        'Hardware': 27,
      },
      donutStyle: const DonutChartStyle(
        innerRadiusFactor: 0.58,
        sliceGap: 2,
        cornerRadius: 8,
      ),
      centerContent: const DonutCenterContent(
        label: 'Revenue',
        valueMode: DonutCenterValueMode.selectedOrTotal,
      ),
    ),
  ],
)
```

Slice, legend, table, keyboard, and controller selection share one
`ChartPointRef`, so the center follows selection no matter where it begins.
The complete Donut document—including center content and optional
variable-radius values—round-trips through canonical JSON and PNG previews.
See the [Donut chart guide](https://github.com/braven-pvm/braven_charts/blob/master/doc/donut_charts.md).

### Concentric Donut

Pass two or more `DonutChartSeries` values to compare independent totals in one
pane. `ConcentricDonutConfig` controls ring allocation, order, weights, legend
grouping, and the one portable center without merging any series data.

```dart
BravenChartPlus(
  series: [currentPeriod, previousPeriod],
  concentricDonutConfig: const ConcentricDonutConfig(
    innerRadiusFactor: 0.28,
    ringGap: 6,
    ringWeights: {'current': 1.25},
    legendMode: ConcentricDonutLegendMode.groupedByRing,
    centerContent: DonutCenterContent(
      label: 'Comparison',
      valueMode: DonutCenterValueMode.custom,
      customValue: '2 periods',
    ),
  ),
)
```

Selection identity remains `(seriesId, pointIndex)`, shares use each ring's
own total, and saved artifacts retain every ring plus the chart-level
composition. See the [Concentric Donut guide](https://github.com/braven-pvm/braven_charts/blob/master/doc/concentric_donut_charts.md).

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
one chart runtime mounted while users switch between Chart, Data, responsive
Split, and opt-in generated Dart Source modes, and gives host actions a stable
handle for refresh and artifact capture:

```dart
BravenChartWorkbench(
  initialDisplayMode: ChartDisplayMode.split,
  availableDisplayModes: const {
    ChartDisplayMode.chart,
    ChartDisplayMode.data,
    ChartDisplayMode.split,
    ChartDisplayMode.source,
  },
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

To keep the selector and selected presentation consistent across an
application—or across one chart-family subtree—provide a shared, nestable
presentation scope:

```dart
final presentation = ChartWorkbenchGroupController();

ChartWorkbenchScope(
  controller: presentation,
  child: const AnalyticsDashboard(),
);

presentation.setDisplayMode(ChartDisplayMode.split);
presentation.setShowModeSwitcher(false);
```

Every mounted Workbench in that scope follows the shared mode. Supported modes
are intersected safely, while split sizing, table/source state, selection, and
interaction remain local to each chart. Dispose caller-owned group controllers.

Source is generated from the current effective chart document and teaches the
public `BravenChartPlus` API. Runtime callbacks and bounded-data omissions are
reported explicitly rather than silently discarded. While Source is visible,
its default revision-aware policy automatically regenerates after chart option,
series, axis, annotation, theme, interaction, or durable view-state changes;
hidden Source catches up when opened again. The package manages
chart/table/source lifecycle and structured extraction state; the
workbench also links table focus and activation to revision-safe chart point
focus/selection by default. Wide rows target every populated series at their
exact X value, and a successful linked selection rebases the table snapshot so
the next row remains usable. The host owns action policy, artifact IDs,
persistence, and navigation. Initial and refresh failures retain explicit
recovery actions, and manual refresh is the recommended policy when a bounded
live stream should not rewrite a visible table at sample cadence. Source can
also opt into manual or mode-entry regeneration when a host explicitly needs
retained code snapshots. See the
[Chart Workbench guide](https://github.com/braven-pvm/braven_charts/blob/master/doc/chart_workbench.md)
for shared system/chart-family presentation, source options and limits,
refresh policies, point identity, responsive semantics, status, and controller
ownership.

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
focused pages for chart types, Pie, Donut, and Concentric Donut charts, interaction, tracking, annotations,
streaming, theming, performance, multi-axis layouts, scientific data, baseline
fills, and state UX.

## Documentation

- [Live interactive showcase](https://braven-pvm.github.io/braven_charts/)
- [Showcase and examples](https://github.com/braven-pvm/braven_charts/blob/master/example/README.md)
- [Public API overview](https://github.com/braven-pvm/braven_charts/blob/master/doc/api_reference.md)
- [Line and Area charts](https://github.com/braven-pvm/braven_charts/blob/master/doc/line_area_charts.md)
- [Synchronized Cartesian charts](https://github.com/braven-pvm/braven_charts/blob/master/doc/synchronized_charts.md)
- [Pie charts](https://github.com/braven-pvm/braven_charts/blob/master/doc/pie_charts.md)
- [Donut charts](https://github.com/braven-pvm/braven_charts/blob/master/doc/donut_charts.md)
- [Concentric Donut charts](https://github.com/braven-pvm/braven_charts/blob/master/doc/concentric_donut_charts.md)
- [Portable chart artifacts](https://github.com/braven-pvm/braven_charts/blob/master/doc/chart_artifacts.md)
- [Chart Workbench](https://github.com/braven-pvm/braven_charts/blob/master/doc/chart_workbench.md)
- [Chart family integration](https://github.com/braven-pvm/braven_charts/blob/master/doc/chart_family_integration.md)
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
