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
/// A single row type carries every field the five presets read, so every
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

  @override
  void dispose() {
    _optionsController.dispose();
    _chartController.dispose();
    _workbenchController.dispose();
    super.dispose();
  }

  ChartTheme? get _theme => _optionsController.options.theme;

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
      .theme(_theme ?? ChartTheme.light)
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
      .theme(_theme ?? ChartTheme.light)
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
      .theme(_theme ?? ChartTheme.light)
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
      .theme(_theme ?? ChartTheme.light)
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
        .theme(_theme ?? ChartTheme.light)
        .interaction(_interaction);
    return _transposed ? chart.transposed() : chart;
  }

  BravenChart<GrammarSample> get _activeChart => switch (_preset) {
    _GrammarPreset.lineTrend => _lineTrendChart(),
    _GrammarPreset.multiAxis => _multiAxisChart(),
    _GrammarPreset.scatterChannels => _scatterChannelsChart(),
    _GrammarPreset.candlestick => _candlestickChart(),
    _GrammarPreset.barTransposed => _barTransposedChart(),
  };

  // ==========================================================================
  // Hand-built equivalents — what the spec above lowers to
  // ==========================================================================

  /// The axis the lowering synthesizes when a chain declares none: a left
  /// axis carrying the `.y` label, with the default `axis-0` id.
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

  Widget _buildHandBuilt(BravenChartController controller) => switch (_preset) {
    _GrammarPreset.lineTrend => _handBuiltLineTrend(controller),
    _GrammarPreset.multiAxis => _handBuiltMultiAxis(controller),
    _GrammarPreset.scatterChannels => _handBuiltScatter(controller),
    _GrammarPreset.candlestick => _handBuiltCandlestick(controller),
    _GrammarPreset.barTransposed => _handBuiltBar(controller),
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
      optionsChildren: _buildOptionsChildren(),
      chart: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPresetPicker(),
          const SizedBox(height: 12),
          Expanded(flex: 3, child: _buildStage()),
          const SizedBox(height: 12),
          Expanded(flex: 2, child: _buildAuthoringCard()),
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
          subtitle: _compareHandBuilt
              ? 'Hand-built BravenChartPlus — the config the spec lowers to'
              : _preset.stageSubtitle,
          padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
          child: _buildWorkbench(),
        );
      },
    );
  }

  /// The Chart / Data / Split / Source workbench every preset renders inside.
  ///
  /// The Source tab is the point of the page: the workbench extracts a chart
  /// document from the mounted chart and generates Dart from it, and it has
  /// no idea whether the chart came from a `PlotSpec` or from hand-written
  /// series — because after lowering there is no difference.
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

  /// The exact facade chain for the active preset.
  ///
  /// The strings are consts declared next to the preset builders and marked
  /// as paired with this card; they show each chain at its DEFAULT knob
  /// values, and the note under the card names the parameters the options
  /// panel is currently driving.
  Widget _buildAuthoringCard() {
    final theme = Theme.of(context);
    return ChartCard(
      key: const ValueKey('chart-grammar-authoring-card'),
      title: 'Authoring code',
      subtitle:
          'The chain that builds the chart above — no ChartSeries anywhere',
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    _preset.authoringCode,
                    key: const ValueKey('chart-grammar-authoring-code'),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _liveParameterNote,
            key: const ValueKey('chart-grammar-live-parameters'),
            style: TextStyle(fontSize: 10, color: theme.hintColor),
          ),
        ],
      ),
    );
  }

  /// Names the chain parameters the options panel is currently driving, so
  /// the const chain above is never read as a claim about the live values.
  String get _liveParameterNote => switch (_preset) {
    _GrammarPreset.lineTrend =>
      'Live: method: TrendType.${_trendMethod.name}, '
          'windowSize: ${_trendWindow.round()}, '
          'showConfidenceBand: $_confidenceBand.',
    _GrammarPreset.multiAxis =>
      'Live: the bpm axis is at YAxisPosition.${_heartRateAxisSide.name}.',
    _GrammarPreset.scatterChannels =>
      'Live: maximumRadius: ${_maximumMarkerRadius.toStringAsFixed(0)}, '
          'categoryBy: ${_categoryChannel ? 'Zone' : 'null'}.',
    _GrammarPreset.candlestick =>
      'A candle is a unit: open, high, low and close are required together, '
          'so this chain has no per-channel knobs to drive.',
    _GrammarPreset.barTransposed =>
      'Live: barWidthPercent: ${_barWidthPercent.toStringAsFixed(2)}, '
          '.transposed() ${_transposed ? 'applied' : 'omitted'}.',
  };

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
            _GrammarPreset.candlestick => const <Widget>[],
          },
        ),
      StandardChartOptions(
        controller: _optionsController,
        // A PlotSpec carries data, marks, transposition, theme, interaction
        // and axis configs — and nothing else. Grid, axis lines, series
        // markers, scrollbars, the legend and line style are widget- or
        // series-level options the grammar does not model in V1, so those
        // controls are hidden rather than shown inert on every preset.
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
                'Chart Options shows only what a PlotSpec can express: the '
                'theme and the interaction config, both chain verbs. Grid, '
                'axis lines, markers, scrollbars, legend and line style are '
                'widget- or series-level options the grammar does not model '
                'in V1, so they are hidden here instead of shown inert.',
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
}

// ============================================================================
// Presets
// ============================================================================

enum _GrammarPreset {
  lineTrend,
  multiAxis,
  scatterChannels,
  candlestick,
  barTransposed,
}

extension on _GrammarPreset {
  String get label => switch (this) {
    _GrammarPreset.lineTrend => 'Line + Trend',
    _GrammarPreset.multiAxis => 'Multi-axis',
    _GrammarPreset.scatterChannels => 'Scatter channels',
    _GrammarPreset.candlestick => 'Candlestick',
    _GrammarPreset.barTransposed => 'Bar transposed',
  };

  IconData get icon => switch (this) {
    _GrammarPreset.lineTrend => Icons.show_chart,
    _GrammarPreset.multiAxis => Icons.align_vertical_bottom,
    _GrammarPreset.scatterChannels => Icons.bubble_chart_outlined,
    _GrammarPreset.candlestick => Icons.candlestick_chart_outlined,
    _GrammarPreset.barTransposed => Icons.bar_chart,
  };

  String get stageTitle => switch (this) {
    _GrammarPreset.lineTrend => 'A line with a fitted trend',
    _GrammarPreset.multiAxis => 'Two measures, two declared axes',
    _GrammarPreset.scatterChannels => 'Scale-driven scatter channels',
    _GrammarPreset.candlestick => 'Open, high, low, close as one mark',
    _GrammarPreset.barTransposed => 'Bars with the plane transposed',
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
  };

  /// The exact chain that builds this preset.
  String get authoringCode => switch (this) {
    _GrammarPreset.lineTrend => _lineTrendChain,
    _GrammarPreset.multiAxis => _multiAxisChain,
    _GrammarPreset.scatterChannels => _scatterChannelsChain,
    _GrammarPreset.candlestick => _candlestickChain,
    _GrammarPreset.barTransposed => _barTransposedChain,
  };
}

// SHOWCASE CHAIN — kept in sync with the authoring-code card
// (_ChartGrammarPageState._lineTrendChart).
const String _lineTrendChain = '''
BravenChart.of(rideRows)
    .x(sampleMinute, label: 'Elapsed (min)')
    .y(samplePower, label: 'Power')
    .geomLine(
      name: 'Power',
      color: const Color(0xFF2563EB),
      strokeWidth: 2.4,
      interpolation: LineInterpolation.monotone,
    )
    .trend(
      method: TrendType.movingAverage,
      windowSize: 5,
      name: 'Trend',
      color: const Color(0xFFDC2626),
      showConfidenceBand: false,
      dashPattern: const <double>[6, 4],
    )
    .theme(ChartTheme.light)
    .interaction(interaction)
    .build(bravenChartController: controller)''';

// SHOWCASE CHAIN — kept in sync with the authoring-code card
// (_ChartGrammarPageState._multiAxisChart).
const String _multiAxisChain = '''
BravenChart.of(rideRows)
    .x(sampleMinute, label: 'Elapsed (min)')
    .yAxis(YAxisConfig(
      position: YAxisPosition.left,
      label: 'Power',
      unit: 'W',
    ).copyWith(id: 'watts'))
    .yAxis(YAxisConfig(
      position: YAxisPosition.right,
      label: 'Heart rate',
      unit: 'bpm',
    ).copyWith(id: 'bpm'))
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
    .theme(ChartTheme.light)
    .interaction(interaction)
    .build(bravenChartController: controller)''';

// SHOWCASE CHAIN — kept in sync with the authoring-code card
// (_ChartGrammarPageState._scatterChannelsChart).
const String _scatterChannelsChain = '''
BravenChart.of(rideRows)
    .x(samplePower, label: 'Power (W)')
    .y(sampleHeartRate, label: 'Heart rate (bpm)')
    .geomPoint(
      name: 'Efforts',
      size: const Channel<GrammarSample>(sampleEffort, label: 'Effort'),
      sizeEncoding: const ScatterSizeEncoding(
        minimumRadius: 4,
        maximumRadius: 14,
      ),
      categoryBy: const CategoryChannel<GrammarSample>(
        sampleZone,
        label: 'Zone',
      ),
      categories: zoneStyles,
    )
    .theme(ChartTheme.light)
    .interaction(interaction)
    .build(bravenChartController: controller)''';

// SHOWCASE CHAIN — kept in sync with the authoring-code card
// (_ChartGrammarPageState._candlestickChart).
const String _candlestickChain = '''
BravenChart.of(candleRows)
    .x(sampleMinute, label: 'Session')
    .yAxis(YAxisConfig(
      position: YAxisPosition.right,
      label: 'Price',
      unit: 'USD',
    ).copyWith(id: 'price'))
    .geomCandlestick(
      open: sampleOpen,
      high: sampleHigh,
      low: sampleLow,
      close: sampleClose,
      name: 'Price',
      yAxisId: 'price',
    )
    .theme(ChartTheme.light)
    .interaction(interaction)
    .build(bravenChartController: controller)''';

// SHOWCASE CHAIN — kept in sync with the authoring-code card
// (_ChartGrammarPageState._barTransposedChart).
const String _barTransposedChain = '''
BravenChart.of(zoneRows)
    .x(sampleMinute, label: 'Zone')
    .y(sampleMinutes, label: 'Minutes')
    .geomBar(
      name: 'Time in zone',
      color: const Color(0xFF7C3AED),
      barWidthPercent: 0.7,
    )
    .theme(ChartTheme.light)
    .interaction(interaction)
    .transposed()
    .build(bravenChartController: controller)''';
