# Braven Charts

[![14 chart families rendered by Braven Charts](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/chart_family_grid.png)](https://braven-pvm.github.io/braven_charts/?page=chart-types)

[![Pub version](https://img.shields.io/pub/v/braven_charts.svg)](https://pub.dev/packages/braven_charts)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.35-02569B.svg)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/license-MIT-0F766E.svg)](https://github.com/braven-pvm/braven_charts/blob/master/LICENSE)

Braven Charts is a native Flutter charting system for focused mobile apps, interactive dashboards, and production-grade data visualization.

Render 14 chart families through one custom `RenderBox` and `Canvas` pipeline. Author charts directly, through the checked typed Grammar of Graphics API, or with fluent modifiers. Then add selection, tracking, live data, multi-axis analysis, generated source, tables, and portable artifacts without leaving Flutter's rendering system.

**[Open the live showcase](https://braven-pvm.github.io/braven_charts/) · [See mobile apps](https://braven-pvm.github.io/braven_charts/?page=mobile-apps) · [Choose a chart family](https://braven-pvm.github.io/braven_charts/?page=chart-types) · [Browse documentation](https://braven-pvm.github.io/braven_charts/?page=docs)**

## Why Braven Charts

<!-- BEGIN GENERATED: FEATURES -->
- **[Fourteen chart families](https://braven-pvm.github.io/braven_charts/?page=chart-types):** Build Cartesian, financial, radial, and polar charts in one native renderer.
- **[Interaction and selection](https://braven-pvm.github.io/braven_charts/?page=selection):** Zoom, pan, track, annotate, select, and manipulate durable interval brushes.
- **[Multi-axis analysis](https://braven-pvm.github.io/braven_charts/?page=multi-axis):** Coordinate independent axes, normalized series, navigators, and summaries.
- **[Typed authoring and source](https://braven-pvm.github.io/braven_charts/?page=chart-grammar):** Choose direct config, checked Grammar, fluent modifiers, or generated Dart.
- **[Live and efficient rendering](https://braven-pvm.github.io/braven_charts/?page=live-stream):** Stream changing data through cached, frame-coalesced rendering.
- **[Product-ready chart surfaces](https://braven-pvm.github.io/braven_charts/?page=chart-workbench):** Add Chart, Data, Split, Source, tables, CSV, themes, and artifacts.
<!-- END GENERATED: FEATURES -->

## Built for real Flutter mobile apps

[![Nine phone-native sports, wellness, finance, weather, habit, energy, and mobility experiences built with Braven Charts](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/mobile_apps_showcase.png)](https://braven-pvm.github.io/braven_charts/?page=mobile-apps)

Building a sports, wellness, health, finance, weather, energy, habit, or mobility app? Compose
focused phone experiences with the same native renderer: minimal axes, clear
primary metrics, touch-safe spacing, and responsive layouts that do not inherit
desktop dashboard chrome.

**[Explore the mobile app showcase](https://braven-pvm.github.io/braven_charts/?page=mobile-apps) · [Review mobile interaction patterns](https://braven-pvm.github.io/braven_charts/?page=mobile-interaction)**

## Choose a chart family

Start with the question your data needs to answer. Every visual opens the exact
runnable guide in the showcase; each guide includes curated presets and the
relevant Chart, Data, Split, and Source views.

<!-- BEGIN GENERATED: FAMILIES -->
| **[Line](https://braven-pvm.github.io/braven_charts/?page=line-charts)** | **[Area](https://braven-pvm.github.io/braven_charts/?page=area-charts)** |
| --- | --- |
| [![Two line series showing continuous trends and Synchronized route profile](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/family_line_pair.png)](https://braven-pvm.github.io/braven_charts/?page=line-charts) | [![Layered area chart showing magnitude and accumulation and Value summary composition](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/family_area_pair.png)](https://braven-pvm.github.io/braven_charts/?page=area-charts) |
| Time series, change over time, and analytical overlays<br>[Line chart family](https://braven-pvm.github.io/braven_charts/?page=line-charts) · [Synchronized route profile](https://braven-pvm.github.io/braven_charts/?page=line-charts&preset=synchronized)<br>[Open all Line examples](https://braven-pvm.github.io/braven_charts/?page=line-charts) · [Line guide](https://braven-pvm.github.io/braven_charts/guides/chart-families/line-area/) | Volume, accumulated values, forecasts, and baseline comparison<br>[Area chart family](https://braven-pvm.github.io/braven_charts/?page=area-charts) · [Value summary composition](https://braven-pvm.github.io/braven_charts/?page=value-summary)<br>[Open all Area examples](https://braven-pvm.github.io/braven_charts/?page=area-charts) · [Area guide](https://braven-pvm.github.io/braven_charts/guides/chart-families/line-area/) |

| **[Range Area](https://braven-pvm.github.io/braven_charts/?page=range-area-charts)** | **[Bar](https://braven-pvm.github.io/braven_charts/?page=bar-charts)** |
| --- | --- |
| [![Range Area chart showing a low-high interval band and Temperature envelope](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/family_range_area_pair.png)](https://braven-pvm.github.io/braven_charts/?page=range-area-charts) | [![Grouped bars comparing category values and Waterfall bridge](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/family_bar_pair.png)](https://braven-pvm.github.io/braven_charts/?page=bar-charts) |
| Low-high envelopes, confidence bands, and bounded ranges<br>[Range Area chart family](https://braven-pvm.github.io/braven_charts/?page=range-area-charts) · [Temperature envelope](https://braven-pvm.github.io/braven_charts/?page=range-area-charts&preset=temperature)<br>[Open all Range Area examples](https://braven-pvm.github.io/braven_charts/?page=range-area-charts) · [Range Area guide](https://braven-pvm.github.io/braven_charts/guides/chart-families/range-area/) | Grouped, stacked, range, waterfall, and ranked data<br>[Bar chart family](https://braven-pvm.github.io/braven_charts/?page=bar-charts) · [Waterfall bridge](https://braven-pvm.github.io/braven_charts/?page=bar-charts&preset=waterfall)<br>[Open all Bar examples](https://braven-pvm.github.io/braven_charts/?page=bar-charts) · [Bar guide](https://braven-pvm.github.io/braven_charts/guides/chart-families/bar/) |

| **[Scatter](https://braven-pvm.github.io/braven_charts/?page=scatter-charts)** | **[Candlestick](https://braven-pvm.github.io/braven_charts/?page=candlestick-charts)** |
| --- | --- |
| [![Scatter plot showing three related observation groups and Market opportunity bubbles](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/family_scatter_pair.png)](https://braven-pvm.github.io/braven_charts/?page=scatter-charts) | [![Candlestick series with a moving-average overlay and Market structure](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/family_candlestick_pair.png)](https://braven-pvm.github.io/braven_charts/?page=candlestick-charts) |
| Correlation, cohorts, distributions, and independent encodings<br>[Scatter chart family](https://braven-pvm.github.io/braven_charts/?page=scatter-charts) · [Market opportunity bubbles](https://braven-pvm.github.io/braven_charts/?page=scatter-charts&preset=bubble)<br>[Open all Scatter examples](https://braven-pvm.github.io/braven_charts/?page=scatter-charts) · [Scatter guide](https://braven-pvm.github.io/braven_charts/guides/api-overview/) | Price action and interval-based financial observations<br>[Candlestick chart family](https://braven-pvm.github.io/braven_charts/?page=candlestick-charts) · [Market structure](https://braven-pvm.github.io/braven_charts/?page=candlestick-charts)<br>[Open all Candlestick examples](https://braven-pvm.github.io/braven_charts/?page=candlestick-charts) · [Candlestick guide](https://braven-pvm.github.io/braven_charts/guides/chart-families/candlestick/) |

| **[Heatmap](https://braven-pvm.github.io/braven_charts/?page=heatmap-charts)** | **[Pie](https://braven-pvm.github.io/braven_charts/?page=pie-charts)** |
| --- | --- |
| [![Diverging Heatmap showing measured activity across a matrix and Calendar temperature matrix](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/family_heatmap_pair.png)](https://braven-pvm.github.io/braven_charts/?page=heatmap-charts) | [![Pie chart showing category contribution to one whole and Revenue contribution](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/family_pie_pair.png)](https://braven-pvm.github.io/braven_charts/?page=pie-charts) |
| Activity patterns, calendars, correlation matrices, and dense measured fields<br>[Heatmap chart family](https://braven-pvm.github.io/braven_charts/?page=heatmap-charts) · [Calendar temperature matrix](https://braven-pvm.github.io/braven_charts/?page=heatmap-charts&preset=calendar)<br>[Open all Heatmap examples](https://braven-pvm.github.io/braven_charts/?page=heatmap-charts) · [Heatmap guide](https://braven-pvm.github.io/braven_charts/guides/chart-families/heatmap/) | Small categorical share datasets with one total<br>[Pie chart family](https://braven-pvm.github.io/braven_charts/?page=pie-charts) · [Revenue contribution](https://braven-pvm.github.io/braven_charts/?page=pie-charts)<br>[Open all Pie examples](https://braven-pvm.github.io/braven_charts/?page=pie-charts) · [Pie guide](https://braven-pvm.github.io/braven_charts/guides/chart-families/pie/) |

| **[Donut](https://braven-pvm.github.io/braven_charts/?page=donut-charts)** | **[Concentric Donut](https://braven-pvm.github.io/braven_charts/?page=concentric-donut)** |
| --- | --- |
| [![Donut chart with a central total and Campaign reach](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/family_donut_pair.png)](https://braven-pvm.github.io/braven_charts/?page=donut-charts) | [![Three concentric donut rings with independent totals and Service-level health](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/family_concentric_donut_pair.png)](https://braven-pvm.github.io/braven_charts/?page=concentric-donut) |
| Part-to-whole data that benefits from a central value<br>[Donut chart family](https://braven-pvm.github.io/braven_charts/?page=donut-charts) · [Campaign reach](https://braven-pvm.github.io/braven_charts/?page=donut-charts)<br>[Open all Donut examples](https://braven-pvm.github.io/braven_charts/?page=donut-charts) · [Donut guide](https://braven-pvm.github.io/braven_charts/guides/chart-families/donut/) | Comparing distributions across periods, cohorts, or groups<br>[Concentric Donut chart family](https://braven-pvm.github.io/braven_charts/?page=concentric-donut) · [Service-level health](https://braven-pvm.github.io/braven_charts/?page=concentric-donut)<br>[Open all Concentric Donut examples](https://braven-pvm.github.io/braven_charts/?page=concentric-donut) · [Concentric Donut guide](https://braven-pvm.github.io/braven_charts/guides/chart-families/concentric-donut/) |

| **[Polar Column / Rose](https://braven-pvm.github.io/braven_charts/?page=polar-column)** | **[Radial Bar](https://braven-pvm.github.io/braven_charts/?page=radial-bar)** |
| --- | --- |
| [![Area-correct rose columns arranged on a polar axis and Lifecycle arc](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/family_polar_column_pair.png)](https://braven-pvm.github.io/braven_charts/?page=polar-column) | [![Radial bars comparing category progress on an explicit numeric scale and Signed baseline comparison](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/family_radial_bar_pair.png)](https://braven-pvm.github.io/braven_charts/?page=radial-bar) |
| Cyclical categories and compact magnitude profiles<br>[Polar Column and Rose chart family](https://braven-pvm.github.io/braven_charts/?page=polar-column) · [Lifecycle arc](https://braven-pvm.github.io/braven_charts/?page=polar-column)<br>[Open all Polar Column / Rose examples](https://braven-pvm.github.io/braven_charts/?page=polar-column) · [Polar Column / Rose guide](https://braven-pvm.github.io/braven_charts/guides/chart-families/polar-column/) | Category progress, targets, signed baselines, and compact KPI tracks<br>[Radial Bar chart family](https://braven-pvm.github.io/braven_charts/?page=radial-bar) · [Signed baseline comparison](https://braven-pvm.github.io/braven_charts/?page=radial-bar)<br>[Open all Radial Bar examples](https://braven-pvm.github.io/braven_charts/?page=radial-bar) · [Radial Bar guide](https://braven-pvm.github.io/braven_charts/guides/chart-families/radial-bar/) |

| **[Radar / Spider](https://braven-pvm.github.io/braven_charts/?page=radar-charts)** | **[Gauge / Solid Gauge](https://braven-pvm.github.io/braven_charts/?page=gauge-charts)** |
| --- | --- |
| [![Two aligned profiles compared across six dimensions on a polygon web and Capability profile](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/family_radar_pair.png)](https://braven-pvm.github.io/braven_charts/?page=radar-charts) | [![Needle and Solid Gauge indicators with zones and targets and a second curated example](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/family_gauge_pair.png)](https://braven-pvm.github.io/braven_charts/?page=gauge-charts) |
| Comparing a small number of profiles across one ordered, shared dimension set<br>[Radar and Spider chart family](https://braven-pvm.github.io/braven_charts/?page=radar-charts) · [Capability profile](https://braven-pvm.github.io/braven_charts/?page=radar-charts)<br>[Open all Radar / Spider examples](https://braven-pvm.github.io/braven_charts/?page=radar-charts) · [Radar / Spider guide](https://braven-pvm.github.io/braven_charts/guides/chart-families/radar/) | Operational state, targets, thresholds, zones, and compact KPI status<br>[Gauge and Solid Gauge family](https://braven-pvm.github.io/braven_charts/?page=gauge-charts)<br>[Open all Gauge / Solid Gauge examples](https://braven-pvm.github.io/braven_charts/?page=gauge-charts) · [Gauge / Solid Gauge guide](https://braven-pvm.github.io/braven_charts/guides/chart-families/gauge/) |
<!-- END GENERATED: FAMILIES -->

## Install

<!-- BEGIN GENERATED: INSTALL -->
```yaml
dependencies:
  braven_charts: ^0.18.0
```

Then run `flutter pub get`.

Compatibility: Dart `>=3.9.0 <4.0.0` and Flutter `>=3.35.0`.
<!-- END GENERATED: INSTALL -->

Import the core package:

```dart
import 'package:braven_charts/braven_charts.dart';
```

## Quick start

Use immutable configuration for direct control:

<!-- BEGIN GENERATED: SNIPPETS -->
### Direct configuration

```dart
class BasicLineChart extends StatelessWidget {
  const BasicLineChart({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 280,
      child: BravenChartPlus(
        title: 'Monthly revenue',
        series: [
          LineChartSeries(
            id: 'revenue',
            name: 'Revenue',
            points: [
              ChartDataPoint(x: 1, y: 42),
              ChartDataPoint(x: 2, y: 48),
              ChartDataPoint(x: 3, y: 45),
              ChartDataPoint(x: 4, y: 57),
              ChartDataPoint(x: 5, y: 63),
            ],
          ),
        ],
      ),
    );
  }
}
```

### Typed Chart Grammar

```dart
final basicGrammarChart = BravenChart.of(revenueSamples)
    .x(sampleMonth, label: 'Month')
    .y(sampleRevenue, label: 'Revenue')
    .geomLine(name: 'Revenue', showDataPointMarkers: true)
    .title('Monthly revenue')
    .build();
```
<!-- END GENERATED: SNIPPETS -->

The Grammar example uses a typed `revenueSamples` list and named accessors. It
lowers to the same `BravenChartPlus` renderer as direct configuration.

> **Grammar / Fluent API (Beta):** The Grammar of Graphics and fluent modifier
> authoring layers are experimental and may change before a stable release. Pin
> a version if you depend on them. See [Chart grammar and the fluent
> surface](https://github.com/braven-pvm/braven_charts/blob/master/doc/chart_grammar.md).

Continue with a runnable example:

- [Mobile touch interaction](https://braven-pvm.github.io/braven_charts/?page=mobile-interaction) — Keep Browse surfaces scroll-first, move inspection to long press, or opt back into short-tap selection.
- [Multi-axis charts and normalization](https://braven-pvm.github.io/braven_charts/?page=multi-axis)
- [Selection and linked brushing](https://braven-pvm.github.io/braven_charts/?page=selection) — Try the opt-in persistent X/Y brush, including initial bounds, styling, drag/resize, controller commands, and touch coexistence.
- [Live data and buffering](https://braven-pvm.github.io/braven_charts/?page=live-stream)
- [Chart, Data, Split, and Source Workbench](https://braven-pvm.github.io/braven_charts/?page=chart-workbench)
- [Portable artifacts, tables, and restoration](https://braven-pvm.github.io/braven_charts/?page=artifact-showcase)

## Documentation

The [documentation home](https://braven-pvm.github.io/braven_charts/?page=docs)
organizes runnable examples, concept guides, recipes, and API reference by
developer task.

<!-- BEGIN GENERATED: GUIDES -->
### Get started

- [Build your first chart](#quick-start) — Install the package and render a small, interactive line chart.
- [Author with Chart Grammar](https://braven-pvm.github.io/braven_charts/?page=chart-grammar) — Describe data accessors and marks through a checked typed chain.
- [Choose a chart family](https://braven-pvm.github.io/braven_charts/?page=chart-types) — Start with the data question and compare all built-in families.
- [Radar and Spider charts](https://braven-pvm.github.io/braven_charts/guides/chart-families/radar/) — Compare aligned multidimensional profiles without confusing a profile with a part-to-whole chart.

### Interaction and display

- [Tracking and value display](https://braven-pvm.github.io/braven_charts/guides/tracking-and-value-display/) — Compose crosshairs, tooltips, markers, and persistent value summaries.
- [Mobile app compositions](https://braven-pvm.github.io/braven_charts/?page=mobile-apps) — See nine focused sports, wellness, finance, weather, training, habit, energy, and mobility layouts built for phone screens.
- [Mobile interaction](https://braven-pvm.github.io/braven_charts/guides/mobile-interaction/) — Keep scrolling natural, inspect with a hold, and opt into short-tap selection only where it fits.
- [Selection and linked brushing](https://braven-pvm.github.io/braven_charts/?page=selection) — Select points, ranges, categories, series, linked data, and persistent X/Y brushes.
- [Series label callouts](https://braven-pvm.github.io/braven_charts/guides/series-label-callouts/) — Anchor, prioritize, style, and selectively hide dense line and area labels.
- [Zoom, pan, and navigators](https://braven-pvm.github.io/braven_charts/guides/zoom-pan-and-navigators/) — Control viewports directly or through a reusable full-domain navigator.
- [Annotations](https://braven-pvm.github.io/braven_charts/?page=annotations) — Add and edit point, range, threshold, text, trend, and pin overlays.
- [Axes and normalization](https://braven-pvm.github.io/braven_charts/?page=multi-axis) — Configure independent axes, visible slots, formatting, and normalization.
- [Themes and accessibility](https://braven-pvm.github.io/braven_charts/?page=theming) — Apply coherent light, dark, accessible, and product-specific chart themes.

### Data, authoring, and live updates

- [Typed Chart Grammar](https://braven-pvm.github.io/braven_charts/guides/chart-grammar/) — Lower typed accessors, encodings, marks, and options to the standard renderer.
- [Generated Dart source](https://braven-pvm.github.io/braven_charts/guides/chart-grammar/) — Capture a mounted chart and inspect checked Config or Grammar output.
- [Live data and buffering](https://braven-pvm.github.io/braven_charts/?page=live-stream) — Ingest changing data without rebuilding the widget tree for every sample.
- [Performance](https://braven-pvm.github.io/braven_charts/?page=performance) — Understand cached layers, spatial indexing, streaming, and large datasets.

### Workbench, artifacts, and export

- [Chart Workbench](https://braven-pvm.github.io/braven_charts/guides/chart-workbench/) — Keep one chart mounted across Chart, Data, Split, and Source views.
- [Portable chart artifacts](https://braven-pvm.github.io/braven_charts/guides/chart-artifacts/) — Capture, validate, store, preview, hydrate, and restore effective chart state.
- [Data tables and CSV](https://braven-pvm.github.io/braven_charts/guides/chart-artifacts/) — Project chart data into exact tables with copy and raw-value CSV export.
- [Chart document comparison](https://braven-pvm.github.io/braven_charts/guides/chart-comparison/) — Align saved chart documents without losing identity, units, or provenance.

### API reference

- [Generated API reference](https://braven-pvm.github.io/braven_charts/api/) — Search public libraries, widgets, series, configuration, controllers, and members.
- [Public API overview](https://braven-pvm.github.io/braven_charts/guides/api-overview/) — Review the supported public surface by capability.
- [Feature coverage matrix](https://braven-pvm.github.io/braven_charts/guides/feature-matrix/) — Compare implemented behavior and public boundaries.
<!-- END GENERATED: GUIDES -->

## Package and support

- [Changelog](https://github.com/braven-pvm/braven_charts/blob/master/CHANGELOG.md)
- [Repository](https://github.com/braven-pvm/braven_charts)
- [Issue tracker](https://github.com/braven-pvm/braven_charts/issues)
- [Contributing](https://github.com/braven-pvm/braven_charts/blob/master/CONTRIBUTING.md)
- [Release and publishing checklist](https://github.com/braven-pvm/braven_charts/blob/master/doc/release_checklist.md)
- [API documentation generated by pub.dev](https://pub.dev/documentation/braven_charts/latest/)

## More visual examples

These examples show combinations rather than another inventory of API options.
Each image opens its exact showcase page or preset.

<!-- BEGIN GENERATED: GALLERY -->
### Analytical compositions

| Power-duration model | Threshold exposure | Technical indicator stack |
| --- | --- | --- |
| [![Dark multi-axis power-duration model with six curves](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/hero_power_duration.png)](https://braven-pvm.github.io/braven_charts/?page=multi-axis) | [![Threshold exposure composition with bars, curves, zones, and tracking](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/hero_threshold.png)](https://braven-pvm.github.io/braven_charts/?page=gallery) | [![Synchronized candlestick, MACD, momentum, and navigator composition](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/technical_indicator_stack.png)](https://braven-pvm.github.io/braven_charts/?page=technical-indicators&preset=terminal) |

### Interaction and live behavior

| Donut selection | Crosshair tracking | Zoom and pan |
| --- | --- | --- |
| [![Animated donut selection updating center content](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/donut_selection_demo.gif)](https://braven-pvm.github.io/braven_charts/?page=donut-charts) | [![Animated crosshair tracking across an analytical chart](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/tracking_demo.gif)](https://braven-pvm.github.io/braven_charts/?page=interaction) | [![Animated chart zoom and pan with a bounded viewport](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/zoom_pan_demo.gif)](https://braven-pvm.github.io/braven_charts/?page=interaction) |

### Density and navigation

| Hexbin density | Density contours | Navigator controller |
| --- | --- | --- |
| [![Fifty thousand observations aggregated into interactive hexagonal bins](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/scatter_hexbin_density.png)](https://braven-pvm.github.io/braven_charts/?page=scatter-charts&preset=hexbin) | [![Gaussian density contours preserving fifty thousand source observations](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/scatter_density_contours.png)](https://braven-pvm.github.io/braven_charts/?page=scatter-charts&preset=density) | [![Line chart with a shared full-domain navigator and selected viewport](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/interaction_navigator.png)](https://braven-pvm.github.io/braven_charts/?page=interaction&mode=navigator) |

### Business and financial

| Waterfall bridge | Market structure | Market opportunity |
| --- | --- | --- |
| [![Waterfall bridge with positive and negative deltas](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/bar_waterfall.png)](https://braven-pvm.github.io/braven_charts/?page=bar-charts&preset=waterfall) | [![Candlestick chart with market window and moving-average overlay](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/candlestick_market_structure.png)](https://braven-pvm.github.io/braven_charts/?page=candlestick-charts) | [![Scatter plot with independent bubble, colour, and shape encodings](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/scatter_market_opportunity.png)](https://braven-pvm.github.io/braven_charts/?page=scatter-charts&preset=bubble) |

### Uncertainty and ranges

| Forecast fan | Temperature envelope | Volatility channel |
| --- | --- | --- |
| [![Nested Range Area confidence intervals around a median forecast](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/range_area_forecast_fan.png)](https://braven-pvm.github.io/braven_charts/?page=range-area-charts&preset=forecast) | [![Temperature range envelope with a tracked midpoint](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/range_area_temperature.png)](https://braven-pvm.github.io/braven_charts/?page=range-area-charts&preset=temperature) | [![Dark volatility channel with tracked price and bounds](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/range_area_volatility.png)](https://braven-pvm.github.io/braven_charts/?page=range-area-charts&preset=volatility) |

### Radial and polar

| Revenue contribution | Campaign reach | Seasonal rose |
| --- | --- | --- |
| [![Pie chart with outside contribution labels](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/pie_revenue_contribution.png)](https://braven-pvm.github.io/braven_charts/?page=pie-charts) | [![Variable-radius donut encoding campaign reach](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/donut_campaign_reach.png)](https://braven-pvm.github.io/braven_charts/?page=donut-charts) | [![Area-correct seasonal rose chart across twelve months](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/polar_seasonal_rose.png)](https://braven-pvm.github.io/braven_charts/?page=polar-column) |

### Race charts in motion

| Championship line race | Population bar race |
| --- | --- |
| [![Animated line race with cumulative championship standings and moving endpoint labels](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/line_race_demo.gif)](https://braven-pvm.github.io/braven_charts/?page=line-charts&preset=race) | [![Animated horizontal bar race with changing population ranks and period indicator](https://raw.githubusercontent.com/braven-pvm/braven_charts/master/doc/screenshots/bar_race_demo.gif)](https://braven-pvm.github.io/braven_charts/?page=bar-charts&preset=race) |
<!-- END GENERATED: GALLERY -->

## License

Braven Charts is available under the
[MIT License](https://github.com/braven-pvm/braven_charts/blob/master/LICENSE).
