// Copyright 2026 Braven Charts - Chart Grammar Page
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

// ============================================================================
// Row type and accessors
// ============================================================================

/// One sample of the showcase ride.
///
/// A single row type carries every field the six presets read, so every
/// preset builds a `BravenChart<GrammarSample>` and the page never has to
/// juggle two generic instantiations.
class GrammarSample {
  const GrammarSample({
    required this.minute,
    this.power = 0,
    this.heartRate = 0,
    this.effort = 0,
    this.minutes = 0,
    this.zone = '',
    this.open = 0,
    this.high = 0,
    this.low = 0,
    this.close = 0,
    this.group = '',
  });

  /// Elapsed minutes — also the bar preset's zone ordinal and the
  /// candlestick preset's session index.
  final double minute;
  final double power;
  final double heartRate;
  final double effort;

  /// Minutes spent in this row's training zone (bar preset).
  final double minutes;
  final String zone;
  final double open;
  final double high;
  final double low;
  final double close;

  /// The concentric-ring group for the radial preset (e.g. a season).
  final String group;
}

// Accessors are TOP-LEVEL TEAR-OFFS, never inline closures: `Mark` and
// `PlotSpec` have value equality, and a closure compares by identity, so
// `(row) => row.power` written twice would produce two different marks. Tear
// offs also keep marks const-constructible.
double sampleMinute(GrammarSample row) => row.minute;
double samplePower(GrammarSample row) => row.power;
double sampleHeartRate(GrammarSample row) => row.heartRate;
double sampleEffort(GrammarSample row) => row.effort;
double sampleMinutes(GrammarSample row) => row.minutes;
Object sampleZone(GrammarSample row) => row.zone;
double sampleOpen(GrammarSample row) => row.open;
double sampleHigh(GrammarSample row) => row.high;
double sampleLow(GrammarSample row) => row.low;
double sampleClose(GrammarSample row) => row.close;
Object sampleGroup(GrammarSample row) => row.group;

/// The ride the line, multi-axis and scatter presets read.
const List<GrammarSample> rideRows = <GrammarSample>[
  GrammarSample(
    minute: 0,
    power: 168,
    heartRate: 112,
    effort: 2,
    zone: 'Endurance',
  ),
  GrammarSample(
    minute: 5,
    power: 186,
    heartRate: 124,
    effort: 3,
    zone: 'Endurance',
  ),
  GrammarSample(
    minute: 10,
    power: 204,
    heartRate: 133,
    effort: 4,
    zone: 'Endurance',
  ),
  GrammarSample(
    minute: 15,
    power: 232,
    heartRate: 145,
    effort: 5,
    zone: 'Tempo',
  ),
  GrammarSample(
    minute: 20,
    power: 226,
    heartRate: 149,
    effort: 5,
    zone: 'Tempo',
  ),
  GrammarSample(
    minute: 25,
    power: 251,
    heartRate: 156,
    effort: 6,
    zone: 'Tempo',
  ),
  GrammarSample(
    minute: 30,
    power: 268,
    heartRate: 162,
    effort: 7,
    zone: 'Tempo',
  ),
  GrammarSample(
    minute: 35,
    power: 289,
    heartRate: 169,
    effort: 8,
    zone: 'Threshold',
  ),
  GrammarSample(
    minute: 40,
    power: 278,
    heartRate: 172,
    effort: 8,
    zone: 'Threshold',
  ),
  GrammarSample(
    minute: 45,
    power: 301,
    heartRate: 178,
    effort: 9,
    zone: 'Threshold',
  ),
  GrammarSample(
    minute: 50,
    power: 312,
    heartRate: 183,
    effort: 10,
    zone: 'Threshold',
  ),
  GrammarSample(
    minute: 55,
    power: 264,
    heartRate: 171,
    effort: 6,
    zone: 'Tempo',
  ),
  GrammarSample(
    minute: 60,
    power: 198,
    heartRate: 141,
    effort: 3,
    zone: 'Endurance',
  ),
];

/// Time in each training zone — the transposed bar preset's rows.
const List<GrammarSample> zoneRows = <GrammarSample>[
  GrammarSample(minute: 1, minutes: 42, zone: 'Recovery'),
  GrammarSample(minute: 2, minutes: 68, zone: 'Endurance'),
  GrammarSample(minute: 3, minutes: 35, zone: 'Tempo'),
  GrammarSample(minute: 4, minutes: 18, zone: 'Threshold'),
  GrammarSample(minute: 5, minutes: 9, zone: 'VO2max'),
];

/// Ten trading sessions — the candlestick preset's rows.
///
/// Candlestick lowering rejects out-of-order rows and invalid candles with
/// `invalidCandlestickRow`, so `minute` is strictly increasing here and every
/// row keeps `low <= min(open, close)` and `high >= max(open, close)`.
const List<GrammarSample> candleRows = <GrammarSample>[
  GrammarSample(minute: 1, open: 118, high: 124, low: 116, close: 122),
  GrammarSample(minute: 2, open: 122, high: 129, low: 121, close: 127),
  GrammarSample(minute: 3, open: 127, high: 128, low: 119, close: 120),
  GrammarSample(minute: 4, open: 120, high: 126, low: 118, close: 125),
  GrammarSample(minute: 5, open: 125, high: 134, low: 124, close: 133),
  GrammarSample(minute: 6, open: 133, high: 136, low: 128, close: 129),
  GrammarSample(minute: 7, open: 129, high: 131, low: 122, close: 124),
  GrammarSample(minute: 8, open: 124, high: 132, low: 123, close: 131),
  GrammarSample(minute: 9, open: 131, high: 139, low: 130, close: 138),
  GrammarSample(minute: 10, open: 138, high: 141, low: 133, close: 135),
];

/// Harvest counts by fruit and season — the radial preset's rows. `zone`
/// carries the category label and `group` the concentric-ring season.
const List<GrammarSample> harvestRows = <GrammarSample>[
  GrammarSample(minute: 0, minutes: 42, zone: 'Apple', group: 'Winter'),
  GrammarSample(minute: 1, minutes: 31, zone: 'Pear', group: 'Winter'),
  GrammarSample(minute: 2, minutes: 17, zone: 'Plum', group: 'Summer'),
  GrammarSample(minute: 3, minutes: 10, zone: 'Fig', group: 'Summer'),
];

/// The categorical palette the scatter preset's `categoryBy` channel needs.
///
/// The package ships NO categorical palette, so a `categoryBy` channel
/// without `categories` is rejected at lowering time — this list is the
/// template the channel resolves against.
const List<ScatterCategoryStyle> zoneStyles = <ScatterCategoryStyle>[
  ScatterCategoryStyle(key: 'Endurance', color: Color(0xFF16A34A)),
  ScatterCategoryStyle(key: 'Tempo', color: Color(0xFFF59E0B)),
  ScatterCategoryStyle(key: 'Threshold', color: Color(0xFFDC2626)),
];

/// Rising-effort intervals — the scale-driven-channels preset's rows.
///
/// `minute` is the interval index (x), `minutes` the load a bar or line draws
/// (y), and `effort` the field a colour ramp or a width multiplier reads. The
/// effort domain is `[1, 10]`, which the colour and width maps resolve against.
const List<GrammarSample> channelRows = <GrammarSample>[
  GrammarSample(minute: 0, minutes: 22, effort: 1),
  GrammarSample(minute: 1, minutes: 34, effort: 3),
  GrammarSample(minute: 2, minutes: 29, effort: 5),
  GrammarSample(minute: 3, minutes: 46, effort: 7),
  GrammarSample(minute: 4, minutes: 38, effort: 9),
  GrammarSample(minute: 5, minutes: 53, effort: 10),
];

/// The blue→red ramp the channels preset's colour families resolve against.
///
/// A colour ramp has no default — the package ships none — so this encoding is
/// always supplied alongside the `colorBy` channel.
const ScatterColorEncoding channelRamp = ScatterColorEncoding(
  colors: <Color>[Color(0xFF2563EB), Color(0xFFDC2626)],
  label: 'Effort',
);

/// The bar-width channel's multiplier range: `minimumRadius`/`maximumRadius`
/// are reinterpreted as width multipliers, so a domain-min bar is 0.4x the base
/// width and a domain-max bar is full width.
const ScatterSizeEncoding channelWidthEncoding = ScatterSizeEncoding(
  minimumRadius: 0.4,
  maximumRadius: 1,
);

// ============================================================================
// Page
// ============================================================================

/// First-class guide to the grammar-of-graphics authoring layer.
///
/// Braven Charts has two authoring layers above the config API. The generated
/// FLUENT modifiers (`package:braven_charts/braven_charts_fluent.dart`) chain
/// `withX` / `withoutX` / `inheritX` / `clearX` / `updateX` verbs over the
/// existing config classes. The GRAMMAR — `PlotSpec`, `Mark`, `Channel`, the
/// `BravenPlot` widget and the chained `BravenChart` facade — describes a
/// chart in terms of data, geometries and encodings, then LOWERS onto exactly
/// those config objects.
///
/// Every chart on this page is authored through the chained facade only —
/// there is not one hand-written `ChartSeries` on the spec side. Each preset
/// renders inside the Chart / Data / Split / Source workbench, and the Source
/// tab is the proof of the whole design: a facade-authored chart emits the
/// same ordinary `BravenChartPlus` Dart a hand-written chart does. The
/// "Compare hand-built" toggle swaps in that hand-written equivalent live —
/// the two are indistinguishable, which is what the config-equality and
/// artifact-document parity suites assert in the package tests.
class ChartGrammarPage extends StatefulWidget {
  const ChartGrammarPage({super.key});

  @override
  State<ChartGrammarPage> createState() => _ChartGrammarPageState();
}

class _ChartGrammarPageState extends State<ChartGrammarPage> {
  /// Only the options a `PlotSpec` can express are enabled — see
  /// [_buildOptionsChildren] for why the rest are hidden rather than shown
  /// inert.
  final ChartOptionsController _optionsController = ChartOptionsController(
    const ChartOptions(),
  );

  /// One workbench pair for every preset, so the chosen display mode
  /// (Chart / Data / Split / Source) survives preset switches — the cartesian
  /// and value-summary pages' pattern.
  final BravenChartController _chartController = BravenChartController();
  final ChartWorkbenchController _workbenchController =
      ChartWorkbenchController();

  _GrammarPreset _preset = _GrammarPreset.lineTrend;

  /// Whether the stage renders the hand-written `BravenChartPlus` the active
  /// preset's spec lowers to, instead of the `BravenPlot` over the spec.
  bool _compareHandBuilt = false;

  // Line + Trend knobs.
  TrendType _trendMethod = TrendType.movingAverage;
  double _trendWindow = 5;
  bool _confidenceBand = false;

  // Multi-axis knob.
  YAxisPosition _heartRateAxisSide = YAxisPosition.right;

  // Scatter channel knobs.
  double _maximumMarkerRadius = 14;
  bool _categoryChannel = true;

  // Bar knobs.
  bool _transposed = true;
  double _barWidthPercent = 0.7;

  // Reference-lines knobs — the V2.0 verbs (.threshold / per-mark markers).
  bool _showDataPointMarkers = true;
  double _thresholdWatts = 285;

  // Faceting knobs.
  FacetScales _facetScales = FacetScales.fixed;
  double _facetColumns = 2;
  // Radial preset knob.
  _RadialFamily _radialFamily = _RadialFamily.pie;
  // Scale-driven-channels preset knob.
  _ChannelFamily _channelFamily = _ChannelFamily.colourBar;

  @override
  void dispose() {
    _optionsController.dispose();
    _chartController.dispose();
    _workbenchController.dispose();
    super.dispose();
  }

  /// The theme BOTH sides of the comparison use.
  ///
  /// The options panel's theme is nullable, and null is NOT the same input as
  /// `ChartTheme.light`: `BravenChartPlus` falls back to a bare `TextStyle`
  /// that names no font family for axis labels, which measures to a different
  /// Y-axis strip width than the light theme's Roboto. Resolving the fallback
  /// ONCE, here, is what keeps the spec chain and the hand-built chart from
  /// silently rendering their axes at different widths.
  ChartTheme get _theme => _optionsController.options.theme ?? ChartTheme.light;

  InteractionConfig get _interaction {
    final options = _optionsController.options;
    return InteractionConfig(
      enableZoom: options.enableZoom,
      enablePan: options.enablePan,
      crosshair: const CrosshairConfig(
        displayMode: CrosshairDisplayMode.tracking,
      ),
    );
  }

  void _applyPreset(_GrammarPreset preset) {
    if (_preset == preset) return;
    setState(() => _preset = preset);
  }

  // ==========================================================================
  // Presets — authored through the chained facade ONLY
  // ==========================================================================

  /// Line + moving-average trend.
  ///
  /// `.x` / `.y` set the chain defaults every later geometry inherits, and
  /// their labels name the axes because this chain configures none
  /// explicitly. `.trend()` defaults its source to the geometry appended
  /// immediately before it.
  BravenChart<GrammarSample> _lineTrendChart() => BravenChart.of(rideRows)
      .x(sampleMinute, label: 'Elapsed (min)')
      .y(samplePower, label: 'Power')
      .geomLine(
        name: 'Power',
        color: const Color(0xFF2563EB),
        strokeWidth: 2.4,
        interpolation: LineInterpolation.monotone,
      )
      .trend(
        method: _trendMethod,
        windowSize: _trendWindow.round(),
        name: 'Trend',
        color: const Color(0xFFDC2626),
        showConfidenceBand: _confidenceBand,
        dashPattern: const <double>[6, 4],
      )
      .theme(_theme)
      .interaction(_interaction);

  /// Two independently scaled measures on two declared axis slots.
  ///
  /// No chain-level `.y` here: each geometry names its own accessor, and
  /// `yAxisId` is the join key that binds it to a declared slot.
  BravenChart<GrammarSample> _multiAxisChart() => BravenChart.of(rideRows)
      .x(sampleMinute, label: 'Elapsed (min)')
      .yAxis(
        YAxisConfig(
          position: YAxisPosition.left,
          label: 'Power',
          unit: 'W',
        ).copyWith(id: 'watts'),
      )
      .yAxis(
        YAxisConfig(
          position: _heartRateAxisSide,
          label: 'Heart rate',
          unit: 'bpm',
        ).copyWith(id: 'bpm'),
      )
      .geomArea(
        id: 'power',
        y: samplePower,
        name: 'Power',
        yAxisId: 'watts',
        color: const Color(0xFF2563EB),
        fillOpacity: 0.18,
      )
      .geomLine(
        id: 'hr',
        y: sampleHeartRate,
        name: 'Heart rate',
        yAxisId: 'bpm',
        color: const Color(0xFFDC2626),
        strokeWidth: 2.2,
      )
      .theme(_theme)
      .interaction(_interaction);

  /// Scatter, the only V1 geometry with scale-driven channels.
  ///
  /// A channel says WHICH field to read; the matching `Scatter*Encoding` says
  /// how the scale is configured. `size` has a usable all-default template;
  /// `categoryBy` does not, so it is rejected without [zoneStyles].
  BravenChart<GrammarSample> _scatterChannelsChart() => BravenChart.of(rideRows)
      .x(samplePower, label: 'Power (W)')
      .y(sampleHeartRate, label: 'Heart rate (bpm)')
      .geomPoint(
        name: 'Efforts',
        size: const Channel<GrammarSample>(sampleEffort, label: 'Effort'),
        sizeEncoding: ScatterSizeEncoding(
          minimumRadius: 4,
          maximumRadius: _maximumMarkerRadius,
        ),
        categoryBy: _categoryChannel
            ? const CategoryChannel<GrammarSample>(sampleZone, label: 'Zone')
            : null,
        categories: _categoryChannel
            ? zoneStyles
            : const <ScatterCategoryStyle>[],
      )
      .theme(_theme)
      .interaction(_interaction);

  /// Open-high-low-close as ONE mark.
  ///
  /// The four accessors are required together because a candle is a unit —
  /// there is no per-channel candlestick geometry to compose.
  BravenChart<GrammarSample> _candlestickChart() => BravenChart.of(candleRows)
      .x(sampleMinute, label: 'Session')
      .yAxis(
        YAxisConfig(
          position: YAxisPosition.right,
          label: 'Price',
          unit: 'USD',
        ).copyWith(id: 'price'),
      )
      .geomCandlestick(
        open: sampleOpen,
        high: sampleHigh,
        low: sampleLow,
        close: sampleClose,
        name: 'Price',
        yAxisId: 'price',
      )
      .theme(_theme)
      .interaction(_interaction);

  /// Bars with the plane transposed.
  ///
  /// Bars carry no orientation of their own: transposition is a WHOLE-CHART
  /// operation, so it is a chain verb and a transposed chain may contain bar
  /// marks only.
  BravenChart<GrammarSample> _barTransposedChart() {
    final chart = BravenChart.of(zoneRows)
        .x(sampleMinute, label: 'Zone')
        .y(sampleMinutes, label: 'Minutes')
        .geomBar(
          name: 'Time in zone',
          color: const Color(0xFF7C3AED),
          barWidthPercent: _barWidthPercent,
        )
        .theme(_theme)
        .interaction(_interaction);
    return _transposed ? chart.transposed() : chart;
  }

  /// The V2.0 verbs on one chart: reference annotations and chart-level
  /// options that V1 could only DIAGNOSE, now authored through the facade.
  ///
  /// `.threshold(value:)` lowers to a `ThresholdAnnotation` (a reference mark,
  /// not a series); `.grid(...)` / `.title(...)` are chart-level options now
  /// carried on the spec; and `geomLine(showDataPointMarkers:)` is a per-mark
  /// field. Every one of them round-trips, so this preset's Grammar Source tab
  /// shows a real chain instead of a "not emitted" diagnostic.
  BravenChart<GrammarSample> _referenceLinesChart() => BravenChart.of(rideRows)
      .x(sampleMinute, label: 'Elapsed (min)')
      .y(samplePower, label: 'Power (W)')
      .geomArea(
        name: 'Power',
        color: const Color(0xFF2563EB),
        fillOpacity: 0.14,
      )
      .geomLine(
        name: 'Sampled power',
        color: const Color(0xFF1D4ED8),
        strokeWidth: 2.4,
        interpolation: LineInterpolation.monotone,
        showDataPointMarkers: _showDataPointMarkers,
      )
      .threshold(
        value: _thresholdWatts,
        label: 'FTP',
        color: const Color(0xFFDC2626),
        dashPattern: const <double>[6, 4],
      )
      .grid(const GridConfig(vertical: false))
      .title('Ride power', subtitle: 'Fill, sampled line and an FTP reference')
      .theme(_theme)
      .interaction(_interaction);

  /// One metric faceted across a categorical field — small multiples.
  ///
  /// `.facet(sampleZone)` partitions the ride into one panel per training
  /// zone, in first-seen order. `fixed` scales share both axes so the panels
  /// are directly comparable; `freeY` frees the vertical scale per panel;
  /// `freeX`/`free` also free the horizontal scale, at which point the shared
  /// crosshair is no longer meaningful and the panels interact independently.
  BravenChart<GrammarSample> _facetedChart() => BravenChart.of(rideRows)
      .x(sampleMinute, label: 'Elapsed (min)')
      .y(samplePower, label: 'Power (W)')
      .geomLine(
        name: 'Power',
        color: const Color(0xFF2563EB),
        strokeWidth: 2.2,
        interpolation: LineInterpolation.monotone,
      )
      .facet(
        sampleZone,
        scales: _facetScales,
        columns: _facetColumns.round(),
        label: 'Zone',
      )
      .theme(_theme)
      .interaction(_interaction);

  /// The radial preset, authored through the chained facade only. A radial
  /// geom makes the spec radial: it lowers to the rich radial config family
  /// and honors no Cartesian axis/grid option.
  BravenChart<GrammarSample> _radialChart() {
    final base = BravenChart.of(harvestRows).theme(_theme);
    return switch (_radialFamily) {
      _RadialFamily.pie =>
        base
            .geomPie(
              category: sampleZone,
              value: sampleMinutes,
              name: 'Harvest',
            )
            .title('Harvest share'),
      _RadialFamily.donut =>
        base
            .geomDonut(
              category: sampleZone,
              value: sampleMinutes,
              name: 'Harvest',
              center: const DonutCenterContent(label: 'Total'),
            )
            .title('Harvest share'),
      _RadialFamily.concentric =>
        base
            .geomDonut(
              category: sampleZone,
              value: sampleMinutes,
              ring: sampleGroup,
              dataLabels: const PieDataLabelConfig(isVisible: false),
            )
            .title('Harvest by season')
            .legend(true),
      _RadialFamily.polar =>
        base
            .geomPolar(
              category: sampleZone,
              value: sampleMinutes,
              name: 'Harvest',
            )
            .title('Harvest by fruit'),
    };
  }

  /// Scale-driven channels on the non-scatter families, authored through the
  /// chained facade only.
  ///
  /// A `colorBy` channel binds a data field to colour on bar (per-bar fill),
  /// line (per-segment stroke) and area (the top EDGE per segment, not the
  /// fill), baked at lowering into the point's `pointStyle.color` /
  /// `segmentStyle.color`; a bar `sizeBy` channel maps a field LINEARLY into a
  /// width multiplier. A colour channel also appends a colour-ramp
  /// `LegendAnnotation`. All four reuse scatter's `Scatter*Encoding`.
  BravenChart<GrammarSample> _channelsChart() {
    final base = BravenChart.of(channelRows)
        .x(sampleMinute, label: 'Interval')
        .y(sampleMinutes, label: 'Load (min)')
        .theme(_theme)
        .interaction(_interaction);
    const effort = Channel<GrammarSample>(sampleEffort, label: 'Effort');
    return switch (_channelFamily) {
      _ChannelFamily.colourBar => base.geomBar(
        name: 'Load',
        colorBy: effort,
        colorEncoding: channelRamp,
      ),
      _ChannelFamily.colourLine => base.geomLine(
        name: 'Load',
        strokeWidth: 3,
        colorBy: effort,
        colorEncoding: channelRamp,
      ),
      _ChannelFamily.edgeArea => base.geomArea(
        name: 'Load',
        color: const Color(0xFF2563EB),
        fillOpacity: 0.16,
        colorBy: effort,
        colorEncoding: channelRamp,
      ),
      _ChannelFamily.widthBar => base.geomBar(
        name: 'Load',
        color: const Color(0xFF7C3AED),
        sizeBy: effort,
        sizeEncoding: channelWidthEncoding,
      ),
    };
  }

  BravenChart<GrammarSample> get _activeChart => switch (_preset) {
    _GrammarPreset.lineTrend => _lineTrendChart(),
    _GrammarPreset.multiAxis => _multiAxisChart(),
    _GrammarPreset.scatterChannels => _scatterChannelsChart(),
    _GrammarPreset.candlestick => _candlestickChart(),
    _GrammarPreset.barTransposed => _barTransposedChart(),
    _GrammarPreset.referenceLines => _referenceLinesChart(),
    _GrammarPreset.faceted => _facetedChart(),
    _GrammarPreset.radial => _radialChart(),
    _GrammarPreset.channels => _channelsChart(),
  };

  // ==========================================================================
  // Hand-built equivalents — what the spec above lowers to
  // ==========================================================================

  /// The axis a chain that declares none ends up with.
  ///
  /// Two library steps produce it and this helper spells out BOTH, which is
  /// why it is worth having rather than inlining: `BravenChart.toSpec()`
  /// turns the `.y(label:)` into a left `YAxisConfig` carrying that label
  /// (an explicit `.yAxis()` would have won instead), and the lowering then
  /// numbers the id-less axis `axis-0`. Verified by
  /// `test/unit/grammar/chart_builder_test.dart`
  /// ("the .y label survives lowering onto the synthesized axis").
  YAxisConfig _defaultAxis(String label) => YAxisConfig(
    position: YAxisPosition.left,
    label: label,
  ).copyWith(id: 'axis-0');

  List<ChartDataPoint> _points(
    List<GrammarSample> rows,
    double Function(GrammarSample) x,
    double Function(GrammarSample) y,
  ) => <ChartDataPoint>[
    for (final row in rows) ChartDataPoint(x: x(row), y: y(row)),
  ];

  Widget _handBuiltLineTrend(BravenChartController controller) =>
      BravenChartPlus(
        key: const ValueKey('chart-grammar-stage-chart'),
        bravenChartController: controller,
        theme: _theme,
        interactionConfig: _interaction,
        xAxisConfig: const XAxisConfig(label: 'Elapsed (min)'),
        series: <ChartSeries>[
          LineChartSeries(
            id: 'mark-0',
            name: 'Power',
            points: _points(rideRows, sampleMinute, samplePower),
            color: const Color(0xFF2563EB),
            strokeWidth: 2.4,
            interpolation: LineInterpolation.monotone,
            yAxisId: 'axis-0',
            yAxisConfig: _defaultAxis('Power'),
          ),
        ],
        annotations: <ChartAnnotation>[
          TrendAnnotation(
            id: 'mark-1',
            label: 'Trend',
            seriesId: 'mark-0',
            trendType: _trendMethod,
            windowSize: _trendWindow.round(),
            showConfidenceBand: _confidenceBand,
            lineColor: const Color(0xFFDC2626),
            dashPattern: const <double>[6, 4],
          ),
        ],
      );

  Widget _handBuiltMultiAxis(BravenChartController controller) {
    final watts = YAxisConfig(
      position: YAxisPosition.left,
      label: 'Power',
      unit: 'W',
    ).copyWith(id: 'watts');
    final bpm = YAxisConfig(
      position: _heartRateAxisSide,
      label: 'Heart rate',
      unit: 'bpm',
    ).copyWith(id: 'bpm');
    return BravenChartPlus(
      key: const ValueKey('chart-grammar-stage-chart'),
      bravenChartController: controller,
      theme: _theme,
      interactionConfig: _interaction,
      xAxisConfig: const XAxisConfig(label: 'Elapsed (min)'),
      series: <ChartSeries>[
        AreaChartSeries(
          id: 'power',
          name: 'Power',
          points: _points(rideRows, sampleMinute, samplePower),
          color: const Color(0xFF2563EB),
          fillOpacity: 0.18,
          yAxisId: 'watts',
          yAxisConfig: watts,
        ),
        LineChartSeries(
          id: 'hr',
          name: 'Heart rate',
          points: _points(rideRows, sampleMinute, sampleHeartRate),
          color: const Color(0xFFDC2626),
          strokeWidth: 2.2,
          yAxisId: 'bpm',
          yAxisConfig: bpm,
        ),
      ],
    );
  }

  Widget _handBuiltScatter(BravenChartController controller) => BravenChartPlus(
    key: const ValueKey('chart-grammar-stage-chart'),
    bravenChartController: controller,
    theme: _theme,
    interactionConfig: _interaction,
    xAxisConfig: const XAxisConfig(label: 'Power (W)'),
    series: <ChartSeries>[
      ScatterChartSeries(
        id: 'mark-0',
        name: 'Efforts',
        points: <ChartDataPoint>[
          for (final row in rideRows)
            ChartDataPoint(
              x: row.power,
              y: row.heartRate,
              magnitude: row.effort,
              categoryValue: _categoryChannel ? row.zone : null,
            ),
        ],
        yAxisId: 'axis-0',
        yAxisConfig: _defaultAxis('Heart rate (bpm)'),
        // The channel's label is authoritative, so the lowering rebuilds the
        // size template with it — hand-writing it means spelling it out.
        sizeEncoding: ScatterSizeEncoding(
          minimumRadius: 4,
          maximumRadius: _maximumMarkerRadius,
          label: 'Effort',
        ),
        categoryEncoding: _categoryChannel
            ? const ScatterCategoryEncoding(
                categories: zoneStyles,
                label: 'Zone',
              )
            : null,
      ),
    ],
  );

  Widget _handBuiltCandlestick(BravenChartController controller) {
    final price = YAxisConfig(
      position: YAxisPosition.right,
      label: 'Price',
      unit: 'USD',
    ).copyWith(id: 'price');
    return BravenChartPlus(
      key: const ValueKey('chart-grammar-stage-chart'),
      bravenChartController: controller,
      theme: _theme,
      interactionConfig: _interaction,
      xAxisConfig: const XAxisConfig(label: 'Session'),
      series: <ChartSeries>[
        CandlestickChartSeries(
          id: 'mark-0',
          name: 'Price',
          points: <CandlestickDataPoint>[
            for (final row in candleRows)
              CandlestickDataPoint(
                x: row.minute,
                open: row.open,
                high: row.high,
                low: row.low,
                close: row.close,
              ),
          ],
          yAxisId: 'price',
          yAxisConfig: price,
        ),
      ],
    );
  }

  Widget _handBuiltBar(BravenChartController controller) => BravenChartPlus(
    key: const ValueKey('chart-grammar-stage-chart'),
    bravenChartController: controller,
    theme: _theme,
    interactionConfig: _interaction,
    xAxisConfig: const XAxisConfig(label: 'Zone'),
    series: <ChartSeries>[
      BarChartSeries(
        id: 'mark-0',
        name: 'Time in zone',
        points: _points(zoneRows, sampleMinute, sampleMinutes),
        color: const Color(0xFF7C3AED),
        barWidthPercent: _barWidthPercent,
        orientation: _transposed
            ? BarOrientation.horizontal
            : BarOrientation.vertical,
        yAxisId: 'axis-0',
        yAxisConfig: _defaultAxis('Minutes'),
      ),
    ],
  );

  Widget _handBuiltReferenceLines(BravenChartController controller) =>
      BravenChartPlus(
        key: const ValueKey('chart-grammar-stage-chart'),
        bravenChartController: controller,
        theme: _theme,
        interactionConfig: _interaction,
        xAxisConfig: const XAxisConfig(label: 'Elapsed (min)'),
        // Chart-level options the V2.0 grammar now carries on the spec.
        grid: const GridConfig(vertical: false),
        title: 'Ride power',
        subtitle: 'Fill, sampled line and an FTP reference',
        series: <ChartSeries>[
          AreaChartSeries(
            id: 'mark-0',
            name: 'Power',
            points: _points(rideRows, sampleMinute, samplePower),
            color: const Color(0xFF2563EB),
            fillOpacity: 0.14,
            yAxisId: 'axis-0',
            yAxisConfig: _defaultAxis('Power (W)'),
          ),
          LineChartSeries(
            id: 'mark-1',
            name: 'Sampled power',
            points: _points(rideRows, sampleMinute, samplePower),
            color: const Color(0xFF1D4ED8),
            strokeWidth: 2.4,
            interpolation: LineInterpolation.monotone,
            showDataPointMarkers: _showDataPointMarkers,
            yAxisId: 'axis-0',
            yAxisConfig: _defaultAxis('Power (W)'),
          ),
        ],
        annotations: <ChartAnnotation>[
          ThresholdAnnotation(
            id: 'mark-2',
            label: 'FTP',
            axis: AnnotationAxis.y,
            value: _thresholdWatts,
            lineColor: const Color(0xFFDC2626),
            dashPattern: const <double>[6, 4],
          ),
        ],
      );

  Map<String, num> _harvestValues() => <String, num>{
    for (final row in harvestRows) row.zone: row.minutes,
  };

  Widget _handBuiltRadial(BravenChartController controller) {
    switch (_radialFamily) {
      case _RadialFamily.pie:
        return BravenChartPlus(
          key: const ValueKey('chart-grammar-stage-chart'),
          bravenChartController: controller,
          theme: _theme,
          title: 'Harvest share',
          series: <ChartSeries>[
            PieChartSeries.fromMap(
              id: 'mark-0',
              name: 'Harvest',
              values: _harvestValues(),
            ),
          ],
        );
      case _RadialFamily.donut:
        return BravenChartPlus(
          key: const ValueKey('chart-grammar-stage-chart'),
          bravenChartController: controller,
          theme: _theme,
          title: 'Harvest share',
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'mark-0',
              name: 'Harvest',
              values: _harvestValues(),
              centerContent: const DonutCenterContent(label: 'Total'),
            ),
          ],
        );
      case _RadialFamily.concentric:
        final order = <String>[];
        final buckets = <String, Map<String, num>>{};
        for (final row in harvestRows) {
          buckets.putIfAbsent(row.group, () {
            order.add(row.group);
            return <String, num>{};
          })[row.zone] = row.minutes;
        }
        return BravenChartPlus(
          key: const ValueKey('chart-grammar-stage-chart'),
          bravenChartController: controller,
          theme: _theme,
          title: 'Harvest by season',
          showLegend: true,
          series: <ChartSeries>[
            for (final group in order)
              DonutChartSeries.fromMap(
                id: 'mark-0-$group',
                name: group,
                values: buckets[group]!,
                dataLabels: const PieDataLabelConfig(isVisible: false),
              ),
          ],
        );
      case _RadialFamily.polar:
        return BravenChartPlus(
          key: const ValueKey('chart-grammar-stage-chart'),
          bravenChartController: controller,
          theme: _theme,
          title: 'Harvest by fruit',
          series: <ChartSeries>[
            PolarColumnChartSeries.fromMap(
              id: 'mark-0',
              name: 'Harvest',
              values: _harvestValues(),
            ),
          ],
        );
    }
  }

  // The scale-driven-channels preset's hand-built side spells out the baking
  // the grammar automates: the finite effort domain, then each point's colour
  // (ScatterColorEncoding.colorFor over that domain) or width (a LINEAR map
  // into the multiplier range), plus the colour-ramp LegendAnnotation the
  // lowering appends. These mirror plot_lowering's helpers exactly, so the
  // two renders are indistinguishable.

  /// The finite `[min, max]` of the effort channel over [channelRows].
  ({double min, double max}) _channelDomain() {
    var lo = double.infinity;
    var hi = double.negativeInfinity;
    for (final row in channelRows) {
      final value = row.effort;
      if (!value.isFinite) continue;
      if (value < lo) lo = value;
      if (value > hi) hi = value;
    }
    return (min: lo, max: hi);
  }

  /// Per-row baked colour: `colorFor(effort)` over the finite domain.
  List<Color?> _channelColours() {
    final domain = _channelDomain();
    return <Color?>[
      for (final row in channelRows)
        channelRamp.colorFor(
          row.effort,
          resolvedMinimumValue: domain.min,
          resolvedMaximumValue: domain.max,
        ),
    ];
  }

  /// Per-row baked width multiplier: effort mapped LINEARLY into the encoding's
  /// `[minimumRadius, maximumRadius]` range.
  List<double?> _channelWidths() {
    final domain = _channelDomain();
    final span = domain.max - domain.min;
    final low = channelWidthEncoding.minimumRadius;
    final high = channelWidthEncoding.maximumRadius;
    return <double?>[
      for (final row in channelRows)
        span <= 0
            ? low + 0.5 * (high - low)
            : low +
                  ((row.effort - domain.min) / span).clamp(0.0, 1.0) *
                      (high - low),
    ];
  }

  /// The colour-ramp legend the lowering appends for a baked colour channel.
  LegendAnnotation _channelColourLegend() {
    final domain = _channelDomain();
    final midpoint = (domain.min + domain.max) / 2;
    return LegendAnnotation(
      colorScale: LegendColorScale(
        label: 'Effort',
        colors: channelRamp.colors,
        minimumLabel: channelRamp.format(domain.min),
        midpointLabel: domain.min == domain.max
            ? null
            : channelRamp.format(midpoint),
        maximumLabel: channelRamp.format(domain.max),
      ),
    );
  }

  Widget _channelsScaffold(
    BravenChartController controller, {
    required List<ChartSeries> series,
    List<ChartAnnotation> annotations = const <ChartAnnotation>[],
  }) => BravenChartPlus(
    key: const ValueKey('chart-grammar-stage-chart'),
    bravenChartController: controller,
    theme: _theme,
    interactionConfig: _interaction,
    xAxisConfig: const XAxisConfig(label: 'Interval'),
    series: series,
    annotations: annotations,
  );

  Widget _handBuiltChannels(BravenChartController controller) {
    final axis = _defaultAxis('Load (min)');
    switch (_channelFamily) {
      case _ChannelFamily.colourBar:
        final colours = _channelColours();
        return _channelsScaffold(
          controller,
          series: <ChartSeries>[
            BarChartSeries(
              id: 'mark-0',
              name: 'Load',
              points: <ChartDataPoint>[
                for (var i = 0; i < channelRows.length; i++)
                  ChartDataPoint(
                    x: channelRows[i].minute,
                    y: channelRows[i].minutes,
                    pointStyle: colours[i] == null
                        ? null
                        : PointStyle(color: colours[i]),
                  ),
              ],
              barWidthPercent: 0.8,
              yAxisId: 'axis-0',
              yAxisConfig: axis,
            ),
          ],
          annotations: <ChartAnnotation>[_channelColourLegend()],
        );
      case _ChannelFamily.colourLine:
        final colours = _channelColours();
        return _channelsScaffold(
          controller,
          series: <ChartSeries>[
            LineChartSeries(
              id: 'mark-0',
              name: 'Load',
              points: <ChartDataPoint>[
                for (var i = 0; i < channelRows.length; i++)
                  ChartDataPoint(
                    x: channelRows[i].minute,
                    y: channelRows[i].minutes,
                    segmentStyle: colours[i] == null
                        ? null
                        : SegmentStyle.color(colours[i]!),
                  ),
              ],
              strokeWidth: 3,
              yAxisId: 'axis-0',
              yAxisConfig: axis,
            ),
          ],
          annotations: <ChartAnnotation>[_channelColourLegend()],
        );
      case _ChannelFamily.edgeArea:
        final colours = _channelColours();
        return _channelsScaffold(
          controller,
          series: <ChartSeries>[
            AreaChartSeries(
              id: 'mark-0',
              name: 'Load',
              points: <ChartDataPoint>[
                for (var i = 0; i < channelRows.length; i++)
                  ChartDataPoint(
                    x: channelRows[i].minute,
                    y: channelRows[i].minutes,
                    segmentStyle: colours[i] == null
                        ? null
                        : SegmentStyle.color(colours[i]!),
                  ),
              ],
              color: const Color(0xFF2563EB),
              fillOpacity: 0.16,
              yAxisId: 'axis-0',
              yAxisConfig: axis,
            ),
          ],
          annotations: <ChartAnnotation>[_channelColourLegend()],
        );
      case _ChannelFamily.widthBar:
        final widths = _channelWidths();
        return _channelsScaffold(
          controller,
          series: <ChartSeries>[
            BarChartSeries(
              id: 'mark-0',
              name: 'Load',
              points: <ChartDataPoint>[
                for (var i = 0; i < channelRows.length; i++)
                  ChartDataPoint(
                    x: channelRows[i].minute,
                    y: channelRows[i].minutes,
                    pointStyle: widths[i] == null
                        ? null
                        : PointStyle(size: widths[i]),
                  ),
              ],
              color: const Color(0xFF7C3AED),
              barWidthPercent: 0.8,
              yAxisId: 'axis-0',
              yAxisConfig: axis,
            ),
          ],
        );
    }
  }

  Widget _buildHandBuilt(BravenChartController controller) => switch (_preset) {
    _GrammarPreset.lineTrend => _handBuiltLineTrend(controller),
    _GrammarPreset.multiAxis => _handBuiltMultiAxis(controller),
    _GrammarPreset.scatterChannels => _handBuiltScatter(controller),
    _GrammarPreset.candlestick => _handBuiltCandlestick(controller),
    _GrammarPreset.barTransposed => _handBuiltBar(controller),
    _GrammarPreset.referenceLines => _handBuiltReferenceLines(controller),
    // Unreachable: the faceted preset renders its BravenFacetPlot grid directly
    // (a facet grid is N configs, so there is no single hand-built equivalent
    // and no workbench round-trip).
    _GrammarPreset.faceted => const SizedBox.shrink(),
    _GrammarPreset.radial => _handBuiltRadial(controller),
    _GrammarPreset.channels => _handBuiltChannels(controller),
  };

  // ==========================================================================
  // Build
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Chart Grammar',
      subtitle:
          'Author charts as data, geometries and encodings with the chained '
          'BravenChart facade — then read the ordinary config Dart it lowers '
          'to in the Source tab',
      // The grammar-of-graphics + fluent authoring layers are still Beta, so
      // the page header carries a small "work in progress" pill.
      actions: const [_BetaBadge()],
      optionsChildren: _buildOptionsChildren(),
      chart: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPresetPicker(),
          const SizedBox(height: 12),
          // The workbench stage takes the full remaining height: the Source
          // tab's Grammar form is now the single place the chain is shown, so
          // there is no authoring-code card competing for the space.
          Expanded(child: _buildStage()),
        ],
      ),
    );
  }

  Widget _buildPresetPicker() {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final chips = <Widget>[
              for (final preset in _GrammarPreset.values)
                ChoiceChip(
                  key: ValueKey('chart-grammar-preset-${preset.name}'),
                  showCheckmark: false,
                  selected: preset == _preset,
                  onSelected: (_) => _applyPreset(preset),
                  avatar: Icon(
                    preset.icon,
                    size: 17,
                    color: preset == _preset
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  label: Text(preset.label),
                  labelStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: preset == _preset
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: preset == _preset
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  selectedColor: theme.colorScheme.secondaryContainer,
                  backgroundColor: theme.colorScheme.surface,
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ];
            if (constraints.maxWidth < 900) {
              return SingleChildScrollView(
                key: const ValueKey('chart-grammar-preset-scroll'),
                scrollDirection: Axis.horizontal,
                child: Row(spacing: 6, children: chips),
              );
            }
            return Wrap(
              key: const ValueKey('chart-grammar-preset-wrap'),
              spacing: 6,
              runSpacing: 6,
              children: chips,
            );
          },
        ),
      ),
    );
  }

  Widget _buildStage() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        return ChartCard(
          title: _preset.stageTitle,
          subtitle: _preset == _GrammarPreset.faceted
              ? _preset.stageSubtitle
              : _compareHandBuilt
              ? 'Hand-built BravenChartPlus — the config the spec lowers to'
              : _preset.stageSubtitle,
          padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
          child: _preset == _GrammarPreset.faceted
              ? _buildFacetStage()
              : _buildWorkbench(),
        );
      },
    );
  }

  /// The faceted preset renders its grid directly: a facet grid is N configs,
  /// so it does not round-trip the single-document workbench.
  Widget _buildFacetStage() => _facetedChart().buildFaceted(
    key: const ValueKey('chart-grammar-facet-plot'),
  );

  /// The Chart / Data / Split / Source workbench every preset renders inside.
  ///
  /// The Source tab is the point of the page, and it now reads the chart TWO
  /// ways. In Config it extracts a chart document and writes the ordinary
  /// `BravenChartPlus` Dart, with no idea whether the chart came from a
  /// `PlotSpec` or from hand-written series — because after lowering there is
  /// no difference. In Grammar it writes the chain back out over a SYNTHESISED
  /// row type, which is the honest limit of that direction: a document keeps
  /// the numbers a chart was built from, never the objects they came out of.
  Widget _buildWorkbench() {
    return BravenChartWorkbench(
      key: const ValueKey('chart-grammar-workbench'),
      chartController: _chartController,
      workbenchController: _workbenchController,
      availableDisplayModes: const {
        ChartDisplayMode.chart,
        ChartDisplayMode.data,
        ChartDisplayMode.split,
        ChartDisplayMode.source,
      },
      documentOptions: const ChartDocumentExtractOptions(
        documentId: 'chart-grammar-showcase',
        includeViewState: true,
      ),
      sourceOptions: const ChartDartSourceOptions(variableName: 'grammarChart'),
      // The Source pane's Config / Grammar toggle is a PACKAGE feature: these
      // options only name what the grammar form emits, they do not enable it.
      grammarSourceOptions: const ChartGrammarSourceOptions(
        variableName: 'grammarChart',
        rowClassName: 'GrammarRow',
        rowsVariableName: 'rows',
      ),
      tableRefreshPolicy: ChartTableRefreshPolicy.onDocumentRevision,
      splitBreakpoint: 760,
      autoFitTablePane: true,
      minimumChartPaneExtent: 320,
      minimumTablePaneExtent: 320,
      maximumAutoTablePaneExtent: 520,
      chartBuilder: (context, controller) => _compareHandBuilt
          ? _buildHandBuilt(controller)
          : _activeChart.build(
              key: const ValueKey('chart-grammar-stage-chart'),
              bravenChartController: controller,
            ),
    );
  }

  // ==========================================================================
  // Options panel
  // ==========================================================================

  List<Widget> _buildOptionsChildren() {
    return [
      OptionSection(
        title: 'Grammar',
        icon: Icons.auto_awesome_motion_outlined,
        children: [
          const InfoBox(
            message:
                'Every chart here is authored with BravenChart.of(rows) and '
                'nothing else — no ChartSeries, no ChartDataPoint. The spec '
                'lowers onto the ordinary config API, which is why the Data '
                'and Source tabs work unchanged.',
          ),
          const SizedBox(height: 8),
          BoolOption(
            key: const ValueKey('chart-grammar-compare'),
            label: 'Compare hand-built',
            subtitle:
                'Swap in the hand-written BravenChartPlus the spec lowers to',
            value: _compareHandBuilt,
            onChanged: (value) => setState(() => _compareHandBuilt = value),
          ),
          InfoBox(
            key: const ValueKey('chart-grammar-compare-readout'),
            type: _compareHandBuilt ? InfoBoxType.success : InfoBoxType.info,
            message: _compareHandBuilt
                ? 'Showing the hand-built BravenChartPlus. Toggle back and '
                      'forth: the two renders are indistinguishable, and the '
                      'package parity suites assert their configs and their '
                      'extracted chart documents are equal.'
                : 'Showing BravenPlot over the PlotSpec the chain builds. '
                      'Turn this on to render the hand-written equivalent '
                      'instead.',
          ),
        ],
      ),
      // OWNER RULE: a control that cannot apply to the active preset is
      // hidden, never shown inert. The candlestick preset therefore has no
      // Preset Controls section at all — a candle is a unit, so its mark
      // exposes no per-channel parameter to drive.
      if (_preset.hasControls)
        OptionSection(
          title: 'Preset Controls',
          icon: Icons.tune,
          children: switch (_preset) {
            _GrammarPreset.lineTrend => _lineTrendControls(),
            _GrammarPreset.multiAxis => _multiAxisControls(),
            _GrammarPreset.scatterChannels => _scatterControls(),
            _GrammarPreset.barTransposed => _barControls(),
            _GrammarPreset.referenceLines => _referenceLinesControls(),
            _GrammarPreset.faceted => _facetControls(),
            _GrammarPreset.radial => _radialControls(),
            _GrammarPreset.channels => _channelControls(),
            _GrammarPreset.candlestick => const <Widget>[],
          },
        ),
      StandardChartOptions(
        controller: _optionsController,
        // These StandardChartOptions controls drive a WIDGET-level ChartOptions
        // uniformly across every preset. The grammar models the theme and
        // interaction as chain verbs (kept on), and V2.0 added .grid(), the
        // legend toggle and per-mark markers to the spec too — but those are
        // exercised per-preset (see the Reference lines preset's own controls),
        // not through this global panel, so the panel's grid / marker / legend /
        // axis / scrollbar / line-style controls stay hidden rather than inert.
        showGridOption: false,
        showAxisOption: false,
        showMarkerOption: false,
        showScrollbarOptions: false,
        showLegendOption: false,
        showLineStyleOption: false,
      ),
      OptionSection(
        title: 'How to Explore',
        icon: Icons.info_outline,
        children: [
          InfoBox(message: _preset.guide),
          const SizedBox(height: 8),
          const InfoBox(
            key: ValueKey('chart-grammar-options-scope'),
            message:
                'Chart Options here drives the theme and the interaction '
                'config, both chain verbs. V2.0 also lets the grammar express '
                'a grid, the legend toggle and per-mark markers — the Reference '
                'lines preset authors those with .grid(), .legend() and '
                'showDataPointMarkers — so the global grid / legend / marker / '
                'axis / scrollbar controls are hidden here rather than shown '
                'inert.',
          ),
          const SizedBox(height: 8),
          const InfoBox(
            key: ValueKey('chart-grammar-source-forms'),
            message:
                'The Source tab has a Config / Grammar toggle, and the Grammar '
                'form is the single place the facade chain is shown. Config '
                'writes the BravenChartPlus this chart IS; Grammar writes a '
                'chain that rebuilds it, over a synthesised GrammarRow — a '
                'document keeps the numbers a chart was built from, never the '
                'GrammarSample objects they were read out of. A chart the '
                'chain cannot reproduce exactly emits a named diagnostic '
                'instead of code.',
          ),
        ],
      ),
    ];
  }

  List<Widget> _lineTrendControls() => [
    Text(
      'Trend method',
      style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
    ),
    const SizedBox(height: 4),
    SegmentedOption<TrendType>(
      key: const ValueKey('chart-grammar-trend-method'),
      value: _trendMethod,
      options: const [TrendType.linear, TrendType.movingAverage],
      labelBuilder: (method) => switch (method) {
        TrendType.movingAverage => 'Moving average',
        _ => 'Linear',
      },
      onChanged: (method) => setState(() => _trendMethod = method),
    ),
    const SizedBox(height: 8),
    // windowSize is only read by a moving average — the lowering raises
    // invalidTrendWindow for a moving average without one, and ignores it
    // entirely for a linear fit — so the slider hides on Linear.
    if (_trendMethod == TrendType.movingAverage)
      SliderOption(
        key: const ValueKey('chart-grammar-trend-window'),
        label: 'Window size',
        value: _trendWindow,
        min: 2,
        max: 9,
        divisions: 7,
        suffix: ' samples',
        decimalPlaces: 0,
        onChanged: (value) => setState(() => _trendWindow = value),
      ),
    BoolOption(
      key: const ValueKey('chart-grammar-confidence-band'),
      label: 'Confidence band',
      subtitle: 'TrendMark.showConfidenceBand',
      value: _confidenceBand,
      onChanged: (value) => setState(() => _confidenceBand = value),
    ),
  ];

  List<Widget> _multiAxisControls() => [
    Text(
      'Heart-rate axis side',
      style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
    ),
    const SizedBox(height: 4),
    SegmentedOption<YAxisPosition>(
      key: const ValueKey('chart-grammar-hr-axis-side'),
      value: _heartRateAxisSide,
      options: const [YAxisPosition.left, YAxisPosition.right],
      labelBuilder: (position) =>
          position == YAxisPosition.left ? 'Left' : 'Right',
      onChanged: (position) => setState(() => _heartRateAxisSide = position),
    ),
    const SizedBox(height: 4),
    const InfoBox(
      message:
          'The chain declares two axis slots with .yAxis(...); each geometry '
          'binds to one by id. Declaration order is axis order.',
    ),
  ];

  List<Widget> _scatterControls() => [
    SliderOption(
      key: const ValueKey('chart-grammar-marker-radius'),
      label: 'Maximum marker radius',
      value: _maximumMarkerRadius,
      min: 6,
      max: 24,
      suffix: 'px',
      decimalPlaces: 0,
      onChanged: (value) => setState(() => _maximumMarkerRadius = value),
    ),
    BoolOption(
      key: const ValueKey('chart-grammar-category-channel'),
      label: 'Category channel',
      subtitle: 'categoryBy: CategoryChannel(sampleZone) with its palette',
      value: _categoryChannel,
      onChanged: (value) => setState(() => _categoryChannel = value),
    ),
    const InfoBox(
      message:
          'The size channel defaults to ScatterSizeEncoding(); the category '
          'channel has no default — the package ships no categorical '
          'palette, so a categoryBy without categories is rejected when the '
          'spec is lowered.',
    ),
  ];

  List<Widget> _barControls() => [
    BoolOption(
      key: const ValueKey('chart-grammar-transposed'),
      label: 'Transposed',
      subtitle: 'The chain verb .transposed() — a whole-chart operation',
      value: _transposed,
      onChanged: (value) => setState(() => _transposed = value),
    ),
    SliderOption(
      key: const ValueKey('chart-grammar-bar-width'),
      label: 'Bar width',
      value: _barWidthPercent,
      min: 0.2,
      max: 1,
      decimalPlaces: 2,
      onChanged: (value) => setState(() => _barWidthPercent = value),
    ),
    const InfoBox(
      message:
          'Bars have no orientation of their own. Transposition is expressed '
          'once for the chart, and a transposed chain may contain bar marks '
          'only — anything else raises unsupportedTransposition.',
    ),
  ];

  List<Widget> _referenceLinesControls() => [
    BoolOption(
      key: const ValueKey('chart-grammar-markers'),
      label: 'Data-point markers',
      subtitle: 'geomLine(showDataPointMarkers:) — a V2.0 per-mark field',
      value: _showDataPointMarkers,
      onChanged: (value) => setState(() => _showDataPointMarkers = value),
    ),
    SliderOption(
      key: const ValueKey('chart-grammar-threshold'),
      label: 'FTP threshold',
      value: _thresholdWatts,
      min: 200,
      max: 320,
      suffix: ' W',
      decimalPlaces: 0,
      onChanged: (value) => setState(() => _thresholdWatts = value),
    ),
    const InfoBox(
      message:
          'A threshold is a reference mark: .threshold(value:) lowers to a '
          'ThresholdAnnotation, not a series. .grid(), .title() and the '
          'per-point markers are the other V2.0 verbs this preset exercises — '
          'each one round-trips, so the Grammar Source tab emits a chain.',
    ),
  ];

  List<Widget> _facetControls() => [
    Text(
      'Scales',
      style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
    ),
    const SizedBox(height: 4),
    SegmentedOption<FacetScales>(
      key: const ValueKey('chart-grammar-facet-scales'),
      value: _facetScales,
      options: const <FacetScales>[
        FacetScales.fixed,
        FacetScales.freeX,
        FacetScales.freeY,
        FacetScales.free,
      ],
      labelBuilder: (scales) => switch (scales) {
        FacetScales.fixed => 'fixed',
        FacetScales.freeX => 'freeX',
        FacetScales.freeY => 'freeY',
        FacetScales.free => 'free',
      },
      onChanged: (scales) => setState(() => _facetScales = scales),
    ),
    const SizedBox(height: 8),
    SliderOption(
      key: const ValueKey('chart-grammar-facet-columns'),
      label: 'Columns',
      value: _facetColumns,
      min: 1,
      max: 3,
      divisions: 2,
      decimalPlaces: 0,
      onChanged: (value) => setState(() => _facetColumns = value),
    ),
    const InfoBox(
      message:
          'Faceting partitions the ride by training zone — one panel per zone, '
          'in first-seen order. fixed shares both axes so the panels are '
          'directly comparable; freeY frees the vertical scale; freeX / free '
          'free the horizontal scale too, and a shared crosshair only makes '
          'sense when x is shared, so under those the panels interact '
          'independently.',
    ),
  ];

  List<Widget> _radialControls() => [
    Text(
      'Radial family',
      style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
    ),
    const SizedBox(height: 4),
    SegmentedOption<_RadialFamily>(
      key: const ValueKey('chart-grammar-radial-family'),
      value: _radialFamily,
      options: _RadialFamily.values,
      labelBuilder: (family) => switch (family) {
        _RadialFamily.pie => 'Pie',
        _RadialFamily.donut => 'Donut',
        _RadialFamily.concentric => 'Concentric',
        _RadialFamily.polar => 'Polar',
      },
      onChanged: (family) => setState(() => _radialFamily = family),
    ),
    const SizedBox(height: 4),
    const InfoBox(
      message:
          'geomPie/geomDonut/geomPolar carry their own channels. The donut '
          'ring channel partitions rows into concentric DonutChartSeries. A '
          'radial spec honors title, legend and theme, but a grid or axis '
          'option raises axisOptionOnRadialSpec.',
    ),
  ];

  List<Widget> _channelControls() => [
    Text(
      'Channel family',
      style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
    ),
    const SizedBox(height: 4),
    SegmentedOption<_ChannelFamily>(
      key: const ValueKey('chart-grammar-channel-family'),
      value: _channelFamily,
      options: _ChannelFamily.values,
      labelBuilder: (family) => switch (family) {
        _ChannelFamily.colourBar => 'Bar',
        _ChannelFamily.colourLine => 'Line',
        _ChannelFamily.edgeArea => 'Area',
        _ChannelFamily.widthBar => 'Width',
      },
      onChanged: (family) => setState(() => _channelFamily = family),
    ),
    const SizedBox(height: 4),
    const InfoBox(
      message:
          'A scale-driven channel binds a data field to colour or width, baked '
          'at lowering into the per-point style the renderer already paints. '
          'Bar/Line/Area take colorBy — the bar fill, the line stroke, the '
          'area top EDGE (not the fill) — and a colour channel also appends a '
          'colour-ramp legend. Width takes the bar sizeBy channel: the value '
          'maps LINEARLY into a width multiplier (not scatter\'s area radius).',
    ),
  ];
}

// ============================================================================
// Presets
// ============================================================================

enum _GrammarPreset {
  lineTrend,
  multiAxis,
  scatterChannels,
  candlestick,
  referenceLines,
  faceted,
  radial,
  channels,
  // barTransposed is kept LAST: BravenChartPlus retains exiting horizontal bars
  // through a cross-fade, and unioning those with a non-bar chart's entering
  // series trips its all-horizontal bounds check. Keeping the transposed preset
  // terminal means the page (and the preset-sweep tests) never animate FROM a
  // just-shown horizontal-bar chart INTO a Cartesian one. (The channels preset
  // above uses only VERTICAL bars, so it does not trip that check.)
  barTransposed,
}

enum _RadialFamily { pie, donut, concentric, polar }

/// The scale-driven-channels preset's family toggle: a colour channel on each
/// non-scatter family, plus the bar width channel.
enum _ChannelFamily { colourBar, colourLine, edgeArea, widthBar }

extension on _GrammarPreset {
  String get label => switch (this) {
    _GrammarPreset.lineTrend => 'Line + Trend',
    _GrammarPreset.multiAxis => 'Multi-axis',
    _GrammarPreset.scatterChannels => 'Scatter channels',
    _GrammarPreset.candlestick => 'Candlestick',
    _GrammarPreset.barTransposed => 'Bar transposed',
    _GrammarPreset.referenceLines => 'Reference lines',
    _GrammarPreset.faceted => 'Faceting',
    _GrammarPreset.radial => 'Radial',
    _GrammarPreset.channels => 'Scale-driven channels',
  };

  IconData get icon => switch (this) {
    _GrammarPreset.lineTrend => Icons.show_chart,
    _GrammarPreset.multiAxis => Icons.align_vertical_bottom,
    _GrammarPreset.scatterChannels => Icons.bubble_chart_outlined,
    _GrammarPreset.candlestick => Icons.candlestick_chart_outlined,
    _GrammarPreset.barTransposed => Icons.bar_chart,
    _GrammarPreset.referenceLines => Icons.stacked_line_chart,
    _GrammarPreset.faceted => Icons.grid_view,
    _GrammarPreset.radial => Icons.pie_chart_outline,
    _GrammarPreset.channels => Icons.gradient,
  };

  String get stageTitle => switch (this) {
    _GrammarPreset.lineTrend => 'A line with a fitted trend',
    _GrammarPreset.multiAxis => 'Two measures, two declared axes',
    _GrammarPreset.scatterChannels => 'Scale-driven scatter channels',
    _GrammarPreset.candlestick => 'Open, high, low, close as one mark',
    _GrammarPreset.barTransposed => 'Bars with the plane transposed',
    _GrammarPreset.referenceLines => 'Reference marks and chart-level options',
    _GrammarPreset.faceted => 'One metric across small-multiple panels',
    _GrammarPreset.radial => 'Radial geoms: pie, donut, concentric, polar',
    _GrammarPreset.channels => 'Colour and width driven by a data field',
  };

  String get stageSubtitle => switch (this) {
    _GrammarPreset.lineTrend =>
      'The trend defaults its source to the geometry appended before it',
    _GrammarPreset.multiAxis =>
      'Each geometry names its own accessor and binds to an axis slot by id',
    _GrammarPreset.scatterChannels =>
      'Scatter is the only V1 geometry with channels — a compile-time fact',
    _GrammarPreset.candlestick =>
      'The four accessors are required together; a candle is not composable',
    _GrammarPreset.barTransposed =>
      'Transposition is a chain verb, not a per-mark property',
    _GrammarPreset.referenceLines =>
      'The V2.0 verbs: .threshold, .grid, .title and per-point markers',
    _GrammarPreset.faceted =>
      'Partition by a categorical field; fixed / free scales and synced x',
    _GrammarPreset.radial =>
      'A radial geom makes the spec radial — one geom, no Cartesian axes',
    _GrammarPreset.channels =>
      'colorBy on bar/line/area and sizeBy width on bar, baked at lowering',
  };

  /// Whether this preset has any genuinely applicable per-preset control.
  bool get hasControls => this != _GrammarPreset.candlestick;

  String get guide => switch (this) {
    _GrammarPreset.lineTrend =>
      'Switch to the Source tab: the generated Dart is an ordinary '
          'BravenChartPlus with a LineChartSeries and a TrendAnnotation — no '
          'trace of the spec. Then turn on "Compare hand-built" and watch the '
          'chart not change.',
    _GrammarPreset.multiAxis =>
      'Two .yAxis(...) declarations create two slots; the area binds to '
          '"watts" and the line to "bpm". Move the heart-rate axis to the '
          'left and both axes stack on the same side — the chain never '
          'mentions series.',
    _GrammarPreset.scatterChannels =>
      'The size channel scales marker AREA (a sqrt scale — the perceptually '
          'correct one), and the category channel resolves against an '
          'explicit palette. Turn the category channel off to see the marks '
          'fall back to the series color.',
    _GrammarPreset.candlestick =>
      'geomCandlestick takes open, high, low and close together because a '
          'candle is a unit. The lowering also validates every row: an '
          'out-of-order session or an impossible candle raises '
          'invalidCandlestickRow naming the row index, instead of leaking an '
          'ArgumentError from deeper in the pipeline.',
    _GrammarPreset.barTransposed =>
      'Toggle Transposed: .transposed() flips the whole plane, because that '
          'is how this package implements horizontal bars. Adding a line mark '
          'to a transposed chain would raise unsupportedTransposition rather '
          'than render half the chart rotated.',
    _GrammarPreset.referenceLines =>
      'Open the Source tab and pick Grammar: the chain carries '
          '.threshold(value: ...), .grid(...), .title(...) and '
          'showDataPointMarkers — the three V2.0 additions. Each one '
          'round-trips through the lowering, so the tab shows a real chain '
          'rather than the "not emitted" diagnostic these shapes drew in V1. '
          'Drag the FTP slider and toggle the markers to watch the emitted '
          'chain track the chart.',
    _GrammarPreset.faceted =>
      'Switch the Scales control: fixed shares both axes so the panels are '
          'directly comparable, freeY frees the vertical scale per panel, and '
          'freeX / free free the horizontal scale — at which point the shared '
          'crosshair is turned off because it is only meaningful when x is '
          'shared. Drag Columns to relayout the grid.',
    _GrammarPreset.radial =>
      'Switch families with the segmented control. Each is '
          'BravenChart.of(rows).geomPie/geomDonut/geomPolar — the ring channel '
          'splits a donut into concentric rings. Turn on "Compare hand-built" '
          'to see the PieChartSeries.fromMap / ConcentricDonutConfig the chain '
          'lowers to.',
    _GrammarPreset.channels =>
      'Switch the Channel family. Bar / Line / Area bind effort to colour with '
          'colorBy + a ScatterColorEncoding ramp — the bar fill, the line '
          'stroke, the area top EDGE (value-driven fill is deferred) — and each '
          'appends a colour-ramp legend. Width binds effort to the bar sizeBy '
          'channel, a LINEAR map into a width multiplier. Turn on "Compare '
          'hand-built" to see the same baked pointStyle / segmentStyle and '
          'legend written by hand — the work the channel automates.',
  };
}

/// A small "work in progress" pill for the Chart Grammar page header.
///
/// The grammar-of-graphics and fluent authoring APIs are still Beta, so the
/// page flags that plainly. Styled after the existing showcase badge/InfoBox
/// widgets — a rounded warning-tone pill using `labelSmall` — so it reads as
/// part of the same design system.
class _BetaBadge extends StatelessWidget {
  const _BetaBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = Colors.orange.shade900;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.science_outlined, size: 14, color: foreground),
          const SizedBox(width: 5),
          Text(
            'Beta · Work in progress',
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
