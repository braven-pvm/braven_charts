# Braven Charts

[![Pub version](https://img.shields.io/pub/v/braven_charts.svg)](https://pub.dev/packages/braven_charts)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.35-02569B.svg)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/license-MIT-0F766E.svg)](https://github.com/braven-pvm/braven_charts/blob/master/LICENSE)

Braven Charts is a pure Dart charting library for Flutter applications. Chart
rendering and interaction use a custom `RenderBox` and Flutter `Canvas`; the
package does not embed a JavaScript charting engine.

`BravenChartPlus` supports line, area, typed low/high Range Area, bar, scatter,
typed OHLC Candlestick, mixed Cartesian series, Pie, Donut, multi-ring
Concentric Donut, and axis-based Polar Column/Rose charts; multiple independent
axes and normalization; zoom, pan, scrollbars, tracking, tooltips, persistent
value summaries, and editable
annotations; full-domain Cartesian navigators shared across Line, Area, Bar,
Scatter, and Candlestick charts; frame-coalesced live data; configurable themes
and state views; chart, table, split, and generated Dart source modes; and
portable chart artifacts. Rendering, input handling, and streaming updates
remain inside the Flutter rendering pipeline.

Charts can be authored directly with immutable configuration objects or with
the typed `BravenChart.of(rows)` grammar. The Workbench can capture a mounted
chart and emit either effective `BravenChartPlus` configuration or a
fidelity-checked Grammar chain. An opt-in generated fluent barrel adds chained
modifiers to the existing configuration model without expanding the core
import.

For update-heavy charts, the implementation uses cached series layers, a
spatial hit-test index, frame-coalesced point delivery, and a direct render-box
streaming path so each sample does not require a widget-tree rebuild.

[Live showcase and runnable examples](https://braven-pvm.github.io/braven_charts/)

## Current highlights

- **Typed Chart Grammar:** describe data accessors, marks, encodings, axes,
  references, titles, legends, themes, and interaction through a checked
  `BravenChart.of(rows)` chain that lowers onto the standard renderer.
- **Round-trip source from mounted charts:** switch the Workbench Source pane
  between Config and Grammar forms; Grammar output is emitted only after its
  lowered chart passes a structural fidelity comparison.
- **Generated fluent configuration:** opt into approximately 1,160 immutable
  modifier verbs across 98 public configuration types through
  `braven_charts_fluent.dart`, generated and drift-checked from the same
  annotated surface model used by tooling.
- **Typed Range Area charts:** keep low/high intervals atomic through bounds,
  fill and boundary geometry, tracking, gaps, nested forecast fans, motion,
  tables, artifacts, Workbench, and generated Source.
- **Typed Candlestick charts:** render OHLC data with elapsed or ordinal time,
  rising/falling/doji styles, live latest-candle revision, dense-data grouping,
  mixed analytical overlays, tracking, native tables, artifacts, and Source.
- **Polar Column and Rose:** compose linear-radius or area-correct radial
  columns with layering, grouping, diverging stacks, targets, thresholds,
  uncertainty intervals, density controls, gradients, elevation, and motion.
- **One Cartesian navigator contract:** a reusable full-domain overview controls
  synchronized Line, Area, Bar, Scatter, and Candlestick viewports. It supports
  panning, edge resizing, snapping, keyboard and semantic actions, external
  domain growth, and retained-history navigation during live ingest.
- **Persistent Cartesian value summaries:** show the policy-resolved current
  datum as a fixed or draggable in-chart panel, including mixed series,
  multi-axis units, Scatter encodings, and Candlestick OHLC values.
- **Host-extensible chart actions:** add typed context commands or a compact,
  themeable in-chart action while using the same stable Workbench handle for
  artifact capture and application workflows.

[Open the Range Area guide](https://braven-pvm.github.io/braven_charts/?page=range-area-charts),
[open the Candlestick guide](https://braven-pvm.github.io/braven_charts/?page=candlestick-charts),
[open the Polar Column guide](https://braven-pvm.github.io/braven_charts/?page=polar-column),
[open the Chart Grammar guide](https://braven-pvm.github.io/braven_charts/?page=chart-grammar),
[inspect the value summary](https://braven-pvm.github.io/braven_charts/?page=value-summary),
or review the [0.12.0 changelog](https://github.com/braven-pvm/braven_charts/blob/master/CHANGELOG.md#0120---2026-07-22)
for the complete API-level release notes.

## Typed authoring and generated source

The Grammar is an authoring layer, not a second renderer. It lowers to the same
series, annotations, axes, themes, interaction configuration, artifacts, data
tables, and rendering pipeline used by `BravenChartPlus`. Workbench source
generation travels in the opposite direction: it captures the mounted chart,
reconstructs a typed chain, lowers that chain, and refuses to emit it if the
result is not structurally equivalent.

[![Typed Braven Chart Grammar code beside the chart it renders](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/grammar_authoring.png)](https://braven-pvm.github.io/braven_charts/?page=chart-grammar)

[![Workbench Source mode showing its Config and Grammar forms](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/grammar_workbench_source.png)](https://braven-pvm.github.io/braven_charts/?page=chart-grammar)

```dart
final chart = BravenChart.of(samples)
    .x(sampleMinute, label: 'Elapsed (min)')
    .y(samplePower, label: 'Power (W)')
    .geomArea(name: 'Power', fillOpacity: 0.16)
    .geomLine(
      name: 'Sampled power',
      interpolation: LineInterpolation.monotone,
      showDataPointMarkers: true,
    )
    .threshold(value: 285, color: Colors.red)
    .grid(const GridConfig(vertical: false))
    .title('Ride power', subtitle: 'Area, markers and FTP threshold')
    .build();
```

For generated immutable modifiers, import the opt-in barrel instead of the core
barrel:

```dart
import 'package:braven_charts/braven_charts_fluent.dart';

final crosshair = const CrosshairConfig()
    .withMode(CrosshairMode.vertical)
    .withSnapRadius(24);
```

## Rendered examples

Every image below opens the matching interactive example and configuration
surface in the public showcase. The compact grid provides a visual index of the
package rather than treating a single composition as representative.

### Chart types

| Line | Area | Range Area |
| --- | --- | --- |
| [![Line chart family](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/chart_type_line.png)](https://braven-pvm.github.io/braven_charts/?page=line-charts) | [![Area chart family](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/chart_type_area.png)](https://braven-pvm.github.io/braven_charts/?page=area-charts) | [![Range Area chart family](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/chart_type_range_area.png)](https://braven-pvm.github.io/braven_charts/?page=range-area-charts) |
| **Bar** | **Scatter** | **Candlestick** |
| [![Bar chart family](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/chart_type_bar.png)](https://braven-pvm.github.io/braven_charts/?page=bar-charts) | [![Scatter chart family](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/chart_type_scatter.png)](https://braven-pvm.github.io/braven_charts/?page=scatter-charts) | [![Candlestick chart family](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/chart_type_candlestick.png)](https://braven-pvm.github.io/braven_charts/?page=candlestick-charts) |
| **Pie** | **Donut** | **Concentric Donut** |
| [![Pie chart family](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/chart_type_pie.png)](https://braven-pvm.github.io/braven_charts/?page=pie-charts) | [![Donut chart family](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/chart_type_donut.png)](https://braven-pvm.github.io/braven_charts/?page=donut-charts) | [![Concentric Donut chart family](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/chart_type_concentric.png)](https://braven-pvm.github.io/braven_charts/?page=concentric-donut) |
| **Polar Column / Rose** |  |  |
| [![Polar Column and Rose chart family](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/chart_type_polar_column.png)](https://braven-pvm.github.io/braven_charts/?page=polar-column) |  |  |

### Range Area compositions

Range Area preserves one paired low/high interval at each X position. Use the
[Temperature envelope](https://braven-pvm.github.io/braven_charts/?page=range-area-charts&preset=temperature),
[nested Forecast fan](https://braven-pvm.github.io/braven_charts/?page=range-area-charts&preset=forecastFan),
and [Gaps & steps](https://braven-pvm.github.io/braven_charts/?page=range-area-charts&preset=gapsAndSteps)
presets to compare range-only, Range Area plus Line, nested bands, typed
tracking, explicit gaps, styling, motion, and Chart/Data/Split/Source behavior.

| Temperature envelope | Nested forecast fan | Volatility envelope |
| --- | --- | --- |
| [![Daily temperature Range Area with observed mean and typed low/high tracking](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/range_area_temperature.png)](https://braven-pvm.github.io/braven_charts/?page=range-area-charts&preset=temperature) | [![Nested 80% and 50% demand forecast intervals with a median line](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/range_area_forecast_fan.png)](https://braven-pvm.github.io/braven_charts/?page=range-area-charts&preset=forecastFan) | [![Dark rolling volatility Range Area combined with a tracked close line](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/range_area_volatility.png)](https://braven-pvm.github.io/braven_charts/?page=technical-indicators) |

### Concentric Donut compositions

Each ring retains its own total and category shares. Ring order, thickness,
gaps, sweep, labels, legends, center content, and selection are configurable at
the composition or series level.

| Period comparison | Service-level health | Portfolio allocation |
| --- | --- | --- |
| [![Three revenue periods compared as independently weighted Concentric Donut rings](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/concentric_revenue_mix.png)](https://braven-pvm.github.io/braven_charts/?page=concentric-donut) | [![Three service regions compared as partial-sweep status rings](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/concentric_service_health.png)](https://braven-pvm.github.io/braven_charts/?page=concentric-donut) | [![Three portfolio mandates compared as weighted rings on a dark chart theme](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/concentric_portfolio.png)](https://braven-pvm.github.io/braven_charts/?page=concentric-donut) |

### Polar Column compositions

Polar Column uses angular categories and a numeric radial scale. Standard
columns compare radius directly, Rose uses area-correct scaling, partial panes
preserve the same value-only data contract, and compatible series can either
layer a reference behind observed values or divide each category into grouped
angular sub-bands or form diverging stacks on one shared scale. Per-category
target ticks and pane-wide threshold arcs add absolute references without
changing source values into shares. Absolute lower/upper intervals can render
as radial whiskers or compact annular range bands. Deterministic label, value,
and grid-spoke limits keep dense panes readable without removing marks from
interaction, accessibility, tables, exports, artifacts, or generated source.
Category, value, and radial-axis labels can be positioned and styled
independently; columns support palette-derived or fixed gradients, configurable
elevation, and baseline-grow, angular-sweep, or fade entrance motion.

| Channel demand | Seasonal Rose | Lifecycle arc |
| --- | --- | --- |
| [![Channel demand compared as linear-radius Polar Columns](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/polar_channel_demand.png)](https://braven-pvm.github.io/braven_charts/?page=polar-column) | [![Monthly request volume shown as an area-correct Nightingale Rose](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/polar_seasonal_rose.png)](https://braven-pvm.github.io/braven_charts/?page=polar-column) | [![Lifecycle conversion shown on a partial annular Polar pane](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/polar_lifecycle_arc.png)](https://braven-pvm.github.io/braven_charts/?page=polar-column) |

### Candlestick and Cartesian interaction

The same Cartesian infrastructure now serves typed OHLC charts, persistent
value summaries, synchronized independent plots, and full-domain navigation.
Each surface remains available through the package API, Workbench, artifacts,
native data tables, and generated Dart source.

| Candlestick market structure | Persistent value summary | Synchronized navigator |
| --- | --- | --- |
| [![Typed OHLC Candlesticks with a moving average, event range, threshold, and tracking](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/candlestick_market_structure.png)](https://braven-pvm.github.io/braven_charts/?page=candlestick-charts) | [![Persistent value summary over a layered Line and Area chart](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/value_summary_panel.png)](https://braven-pvm.github.io/braven_charts/?page=value-summary) | [![Three independently scaled route metrics sharing one data-X cursor, viewport, and navigator](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/synchronized_route_profile.png)](https://braven-pvm.github.io/braven_charts/?page=line-charts&preset=synchronized) |

### Scatter encodings

Scatter keeps X/Y position independent from marker area, colour, opacity, and
shape. The same values remain inspectable in the chart, legend, tracking
surface, table, artifact, and generated Source.

| Bubble area and shape | Continuous colour | Piecewise risk bands |
| --- | --- | --- |
| [![Market opportunity Scatter chart using area-correct bubbles and distinct marker shapes](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/scatter_market_opportunity.png)](https://braven-pvm.github.io/braven_charts/?page=scatter-charts&preset=bubble) | [![Athlete Scatter chart mapping recovery readiness to a continuous colour scale](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/scatter_athlete_readiness.png)](https://braven-pvm.github.io/braven_charts/?page=scatter-charts&preset=color%20scale) | [![Dark equipment Scatter chart with named piecewise risk bands](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/scatter_equipment_risk.png)](https://braven-pvm.github.io/braven_charts/?page=scatter-charts&preset=bands) |
| **Line motion workbench** | **Area motion workbench** | **Chart family overview** |
| [![Line motion example in the resizable Chart and Data workbench](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/line_motion_workbench.png)](https://braven-pvm.github.io/braven_charts/?page=line-charts&preset=motion&view=split) | [![Area motion example in the resizable Chart and Data workbench](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/area_motion_workbench.png)](https://braven-pvm.github.io/braven_charts/?page=area-charts&preset=motion&view=split) | [![Built-in chart families rendered by Braven Charts](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/chart_type_strip.png)](https://braven-pvm.github.io/braven_charts/?page=chart-types) |

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
| Interaction | Pointer and touch zoom, pan, X/Y scrollbars, hover tooltips, crosshairs, tracking panels, opt-in data-X synchronization across independent Cartesian charts, and a native full-domain navigator for Line, Area, Bar, Scatter, and Candlestick charts |
| Data series | Line and Area with explicit per-series entrance/update timing; typed Range Area with atomic low/high intervals, explicit gaps, nested bands, independent boundaries, typed tracking, and motion; Bar with accessible patterns, lollipop, Pareto and histogram compositions, bullet ranges and targets, and centered diverging/Likert stacks; Scatter with point styling plus independent size, colour, and opacity encodings; typed OHLC Candlestick with rising/falling/doji styling, density grouping, live revision, and analytical overlays; mixed Cartesian series; category-based Pie, Donut, and Concentric Donut charts with labels, positioned legends, solid/gradient fills, three corner treatments, variable radii, center content, partial sweeps, elevation, selection, and animation; and value-based Polar Column/Rose charts with angular categories, a signed numeric radial scale, layered/grouped/diverging stacked comparisons, category targets, pane thresholds, absolute uncertainty/range intervals, independent label placement/style, gradients, elevation, entrance motion, and bounded visual density |
| Axes | Configurable X axis, multiple independent Y axes, shared axes, automatic or per-series normalization, visible-axis slots, and dedicated angular-category/radial-value Polar axes |
| Annotations | Point, range, text, threshold, trend, chord, pin, and legend annotations with interactive editing |
| Live data | Frame-coalesced point ingestion, bounded buffers, follow-latest viewports, pause/resume, and buffered catch-up |
| Display | Light/dark and custom themes, inherited right-to-left canvas text and semantics, legends, labels, persistent fixed or draggable Cartesian value summaries, package-owned Chart/Data/Split/Source workbenches, loading skeletons, progress indicators, and empty states |
| Developer tooling | Deterministic Dart generation from effective chart documents, selectable dark source viewport, bounded-data and runtime-callback diagnostics, exact copy, and configurable refresh policies |
| Application control | Controllers, callbacks, runtime series selection, annotation management, axis-slot state, synchronized Workbench presentation, synchronized Cartesian interaction, host-defined context and overlay actions, and serializable chart configuration |
| Portable artifacts | Capture effective chart state, persist canonical JSON, render exact-X or category/share data tables with native copy/CSV actions, attach previews, and hydrate fresh interactive charts |
| Document comparison | Explicit semantic series mapping, exact-X or timestamp alignment, safe units, missing values, deltas, and source-preserving CSV export |

The [live showcase](https://braven-pvm.github.io/braven_charts/) provides
runnable examples and configuration controls for these APIs. See the
[showcase guide](https://github.com/braven-pvm/braven_charts/blob/master/example/README.md)
for the feature-to-page map and local run instructions.
[Open Chart Workbench directly](https://braven-pvm.github.io/braven_charts/?page=chart-workbench)
to try the package-owned Chart/Data/Split/Source workflow, copy generated Dart,
link point selection, capture artifacts, control freshness, and compare documents.
[Open Candlestick Charts directly](https://braven-pvm.github.io/braven_charts/?page=candlestick-charts)
to inspect typed OHLC geometry, overlays, live revision, density grouping,
synchronized panes, tables, artifacts, and generated Source.
[Open Range Area Charts directly](https://braven-pvm.github.io/braven_charts/?page=range-area-charts)
to compare temperature, seasonal, confidence, nested forecast, volatility, and
stepped-gap intervals with live styling, tracking, motion, Data, and Source.
[Open Tracking & Value Display directly](https://braven-pvm.github.io/braven_charts/?page=value-summary)
to combine persistent summaries with independently configurable crosshair,
tooltip, tracking, coordinate-label, selection, and pinning layers.
[Open Polar Column directly](https://braven-pvm.github.io/braven_charts/?page=polar-column)
to compare standard, Rose, partial, layered, grouped, stacked, target,
threshold, uncertainty, density, styling, and animation configurations.
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
  braven_charts: ^0.12.0
```

Then fetch dependencies:

```bash
flutter pub get
```

Braven Charts 0.12.0 requires Dart 3.9 or later and Flutter 3.35 or later.

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

## Cartesian navigator

`CartesianNavigator` renders a compact Line or Area overview over the complete
X domain and controls every Cartesian chart attached to the same caller-owned
`ChartInteractionGroupController`. Drag the window to pan, resize either edge,
or use keyboard and semantic actions. Fixed-interval and ordered-value snapping
support regular samples and irregular timestamps without adding chart-family
logic to the navigator.

```dart
final interactionGroup = ChartInteractionGroupController();

Column(
  children: [
    Expanded(
      child: BravenChartPlus(
        series: [detailSeries],
        interactionGroupController: interactionGroup,
      ),
    ),
    CartesianNavigator(
      interactionGroupController: interactionGroup,
      overviewSeries: AreaChartSeries(
        id: 'overview',
        points: overviewPoints,
      ),
      fullDomain: const ChartXViewport(min: 0, max: 240),
      initialViewport: const ChartXViewport(min: 60, max: 120),
      snapPolicy: CartesianNavigatorSnapPolicy.interval(5),
    ),
  ],
)
```

The controller is the sole viewport authority and must be disposed by its
owner. The overview stays full-domain and opts out of cursor and viewport
synchronization. See the [Cartesian navigator contract](https://github.com/braven-pvm/braven_charts/blob/master/doc/cartesian_navigator.md)
for initialization precedence, accessibility, styling, snapping, and external
viewport reconciliation.

## Cartesian value summary

`InteractionConfig.valueSummary` keeps the current policy-resolved datum in a
persistent in-plot panel for Line, Area, Bar, Scatter, Candlestick, mixed, and
multi-axis charts. The summary can be a pointer-transparent fixed overlay or a
draggable annotation-style panel, and remains independent from crosshair lines,
tooltips, axis labels, and the classic tracking panel.

```dart
BravenChartPlus(
  series: series,
  interactionConfig: InteractionConfig(
    valueSummary: CartesianValueSummaryConfig(
      enabled: true,
      valuePolicy:
          CartesianValueSummaryValuePolicy.selectionThenTrackingThenLatest,
      presentation: CartesianValueSummaryPresentation.overlay(
        placement: ChartOverlayPlacement.topLeft,
      ),
    ),
  ),
)
```

Automatic family-aware content includes regular values, Scatter encodings,
grouped context, and Candlestick OHLC/change rows. Applications can instead
provide custom content, styling, semantics, value policies, or programmatic
pinning. See the [Cartesian value summary guide](https://github.com/braven-pvm/braven_charts/blob/master/doc/value_summary.md).

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

For a live chart with a full-domain navigator, set
`LiveStreamController.manageViewport` to `false` and attach both the detail
chart and `CartesianNavigator` to one `ChartInteractionGroupController`. The
stream retains its direct, frame-coalesced render path while the host decides
when to follow the newest samples or preserve a historical viewport. See the
[Cartesian navigator guide](https://github.com/braven-pvm/braven_charts/blob/master/doc/cartesian_navigator.md#live-ingestion).
External viewport hosts can observe `dataRevision` and read `oldestPoint`,
`latestPoint`, and `pointCount` without allocating a full point snapshot.

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
  contextActionsBuilder: (context, handle, invocation) => [
    ChartContextAction(
      id: 'host.addToReport',
      label: 'Add to report',
      icon: Icons.bookmark_add_outlined,
      onSelected: () => addToReport(handle),
    ),
  ],
  chartActionButtonBuilder: (context, handle) => ChartOverlayAction(
    id: 'host.addToReport',
    tooltip: 'Add chart to report',
    icon: Icons.bookmark_add_outlined,
    enabled: !handle.isExtractingArtifact,
    onPressed: () => addToReport(handle),
  ),
)
```

The compact chart button, visible Workbench action, and typed context action
are independent opt-ins backed by the same stable Workbench handle. The chart
button's alignment, margin, target size, icon size, and style are configurable
with `ChartOverlayActionButtonConfig`; it can also be attached directly to
`BravenChartPlus` outside a Workbench. Its default is a translucent,
zero-elevation surface derived from the current `ColorScheme`; pass a
`ButtonStyle` to match a product-specific theme, or use `actionsBuilder` for a
completely external button.

The typed context action is available from secondary click and keyboard on all
platforms. Touch/stylus long press can be enabled explicitly with
`ChartContextMenuConfig(enableLongPress: true)` on `BravenChartPlus`. The
invocation exposes stable background, series, point, or annotation identity;
it never exposes renderer internals.

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

The showcase is responsive: desktop and tablet use the complete feature rail,
while phones automatically receive a focused, touch-friendly browser with
three vertically scrolling, production-shaped examples for every chart family.
These retain representative features such as forecast segments, baseline
fills, nested intervals, diverging bars, bubble encodings, financial overlays,
and radial compositions with phone-sized data. Vivid, Midnight, and Calm style
presets update the complete chart treatment, and every example uses
reduced-motion-aware entrance animation. The full showcase includes
gallery-ready examples and focused pages for chart types, interaction,
tracking, annotations, streaming, theming, performance, multi-axis layouts,
scientific data, baseline fills, and state UX.

## Documentation

- [Live interactive showcase](https://braven-pvm.github.io/braven_charts/)
- [Showcase and examples](https://github.com/braven-pvm/braven_charts/blob/master/example/README.md)
- [Public API overview](https://github.com/braven-pvm/braven_charts/blob/master/doc/api_reference.md)
- [Chart grammar and the fluent surface](https://github.com/braven-pvm/braven_charts/blob/master/doc/chart_grammar.md)
- [Line and Area charts](https://github.com/braven-pvm/braven_charts/blob/master/doc/line_area_charts.md)
- [Range Area charts](https://github.com/braven-pvm/braven_charts/blob/master/doc/range_area_charts.md)
- [Synchronized Cartesian charts](https://github.com/braven-pvm/braven_charts/blob/master/doc/synchronized_charts.md)
- [Cartesian value summary](https://github.com/braven-pvm/braven_charts/blob/master/doc/value_summary.md)
- [Cartesian navigator](https://github.com/braven-pvm/braven_charts/blob/master/doc/cartesian_navigator.md)
- [Candlestick charts](https://github.com/braven-pvm/braven_charts/blob/master/doc/candlestick_charts.md)
- [Pie charts](https://github.com/braven-pvm/braven_charts/blob/master/doc/pie_charts.md)
- [Donut charts](https://github.com/braven-pvm/braven_charts/blob/master/doc/donut_charts.md)
- [Concentric Donut charts](https://github.com/braven-pvm/braven_charts/blob/master/doc/concentric_donut_charts.md)
- [Polar Column and Rose charts](https://github.com/braven-pvm/braven_charts/blob/master/doc/polar_column_charts.md)
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
