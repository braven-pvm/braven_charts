// Copyright 2025 Braven Charts - Performance Page
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/data_generator.dart';
import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// An interactive stress lab for exploring large datasets.
///
/// The measurements shown here describe the current showcase session. They are
/// useful diagnostic signals, not portable benchmark claims.
class PerformancePage extends StatefulWidget {
  const PerformancePage({super.key});

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  static const _slowFrameThreshold = Duration(microseconds: 16667);
  static const _maxFrameSamples = 180;

  final ChartOptionsController _optionsController = ChartOptionsController();
  final List<FrameTiming> _frameTimings = [];

  int _dataPointCount = 1000;
  int _seriesCount = 1;
  bool _useSmoothing = false;

  Duration _lastGenerationDuration = Duration.zero;
  Duration? _lastVisualUpdateDuration;
  DateTime _lastMetricsRefresh = DateTime.fromMillisecondsSinceEpoch(0);
  int _visualUpdateToken = 0;

  List<List<ChartDataPoint>> _allSeriesData = [];

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
    _regenerateData();
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (!mounted || timings.isEmpty) return;

    _frameTimings.addAll(timings);
    if (_frameTimings.length > _maxFrameSamples) {
      _frameTimings.removeRange(0, _frameTimings.length - _maxFrameSamples);
    }

    // Refresh at most twice per second. Updating on every timing callback would
    // create a feedback loop where the metrics UI continually measures itself.
    final now = DateTime.now();
    if (now.difference(_lastMetricsRefresh) >=
        const Duration(milliseconds: 500)) {
      _lastMetricsRefresh = now;
      setState(() {});
    }
  }

  void _regenerateData({int? dataPointCount, int? seriesCount}) {
    final nextPointCount = dataPointCount ?? _dataPointCount;
    final nextSeriesCount = seriesCount ?? _seriesCount;
    final generationStopwatch = Stopwatch()..start();

    final generatedData = List.generate(nextSeriesCount, (seriesIndex) {
      return DataGenerator.generateRandomWalk(
        count: nextPointCount,
        startY: 50.0 + seriesIndex * 10,
        stepSize: 3.0,
      );
    });

    generationStopwatch.stop();
    _measureVisualUpdate(() {
      _dataPointCount = nextPointCount;
      _seriesCount = nextSeriesCount;
      _allSeriesData = generatedData;
      _lastGenerationDuration = generationStopwatch.elapsed;
    });
  }

  void _measureVisualUpdate(VoidCallback change) {
    final stopwatch = Stopwatch()..start();
    final token = ++_visualUpdateToken;
    setState(change);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || token != _visualUpdateToken) return;
      stopwatch.stop();
      setState(() => _lastVisualUpdateDuration = stopwatch.elapsed);
    });
  }

  void _resetSessionMetrics() {
    _visualUpdateToken++;
    setState(() {
      _frameTimings.clear();
      _lastVisualUpdateDuration = null;
      _lastMetricsRefresh = DateTime.now();
    });
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Performance Lab',
      subtitle: 'Interactive stress testing with live session frame timings',
      optionsChildren: _buildOptionsChildren(),
      chart: _buildChartArea(),
      bottomPanel: _buildStatusPanel(),
    );
  }

  List<Widget> _buildOptionsChildren() {
    return [
      StandardChartOptions(controller: _optionsController),
      OptionSection(
        title: 'Dataset',
        icon: Icons.data_usage,
        children: [
          EnumOption<int>(
            label: 'Points per series',
            value: _dataPointCount,
            values: const [100, 500, 1000, 5000, 10000],
            labelBuilder: (value) => '$value points',
            onChanged: (value) => _regenerateData(dataPointCount: value),
          ),
          EnumOption<int>(
            label: 'Series count',
            value: _seriesCount,
            values: const [1, 2, 3, 5],
            labelBuilder: (value) => '$value series',
            onChanged: (value) => _regenerateData(seriesCount: value),
          ),
          BoolOption(
            label: 'Smooth lines',
            value: _useSmoothing,
            onChanged: (value) =>
                _measureVisualUpdate(() => _useSmoothing = value),
            subtitle: 'Compare linear and Bezier interpolation work',
          ),
        ],
      ),
      OptionSection(
        title: 'Lab actions',
        children: [
          ActionButton(
            label: 'Regenerate dataset',
            icon: Icons.refresh,
            onPressed: _regenerateData,
          ),
          const SizedBox(height: 8),
          ActionButton(
            label: 'Run 10K stress case',
            icon: Icons.speed,
            onPressed: () => _regenerateData(dataPointCount: 10000),
          ),
          const SizedBox(height: 8),
          ActionButton(
            label: 'Reset session metrics',
            icon: Icons.restart_alt,
            onPressed: _resetSessionMetrics,
          ),
        ],
      ),
      InfoBox(
        message:
            'Measurements reflect this device, browser, build mode, and the '
            'latest ${_frameTimings.length} UI frames. Use them to compare '
            'settings in this session, not as package-wide guarantees.',
        type: InfoBoxType.info,
      ),
    ];
  }

  Widget _buildChartArea() {
    return Column(
      children: [
        const _SessionMeasurementNotice(),
        const SizedBox(height: 12),
        Expanded(child: _buildChart()),
      ],
    );
  }

  Widget _buildChart() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        final colors = [
          Colors.blue,
          Colors.red,
          Colors.green,
          Colors.orange,
          Colors.purple,
        ];

        return ChartCard(
          title: 'Dataset Stress Test',
          subtitle: '${_dataPointCount * _seriesCount} total points',
          child: BravenChartPlus(
            series: List.generate(_allSeriesData.length, (index) {
              return LineChartSeries(
                id: 'series_$index',
                name: 'Series ${index + 1}',
                points: _allSeriesData[index],
                color: colors[index % colors.length],
                interpolation: _useSmoothing
                    ? LineInterpolation.bezier
                    : LineInterpolation.linear,
                strokeWidth: 1.5,
                showDataPointMarkers:
                    _optionsController.showDataMarkers &&
                    _dataPointCount <= 100,
              );
            }),
            theme: _optionsController.theme,
            showLegend: _seriesCount > 1 && _optionsController.showLegend,
            showXScrollbar: _optionsController.showXScrollbar,
            showYScrollbar: _optionsController.showYScrollbar,
            scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(
              autoHide: false,
            ),
            xAxisConfig: XAxisConfig(
              showAxisLine: _optionsController.showAxisLines,
            ),
            yAxis: YAxisConfig(
              position: YAxisPosition.left,
              showAxisLine: _optionsController.showAxisLines,
            ),
            interactionConfig: InteractionConfig(
              enableZoom: _optionsController.enableZoom,
              enablePan: _optionsController.enablePan,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusPanel() {
    final p95Build = _percentileMs(
      _frameTimings.map((timing) => timing.buildDuration),
      0.95,
    );
    final p95Raster = _percentileMs(
      _frameTimings.map((timing) => timing.rasterDuration),
      0.95,
    );
    final slowFrames = _frameTimings
        .where((timing) => timing.totalSpan > _slowFrameThreshold)
        .length;

    return StatusPanel(
      items: [
        StatusItem(
          label: 'Total points',
          value: '${_dataPointCount * _seriesCount}',
        ),
        StatusItem(
          label: 'Data generation',
          value: _formatDuration(_lastGenerationDuration),
        ),
        StatusItem(
          label: 'Visual update',
          value: _lastVisualUpdateDuration == null
              ? '—'
              : _formatDuration(_lastVisualUpdateDuration!),
        ),
        StatusItem(label: 'p95 build', value: _formatMilliseconds(p95Build)),
        StatusItem(label: 'p95 raster', value: _formatMilliseconds(p95Raster)),
        StatusItem(
          label: 'Slow frames',
          value: '$slowFrames / ${_frameTimings.length}',
          color: slowFrames == 0
              ? Colors.green.shade700
              : Colors.orange.shade800,
        ),
      ],
    );
  }

  double? _percentileMs(Iterable<Duration> durations, double percentile) {
    final values = durations.map((duration) => duration.inMicroseconds).toList()
      ..sort();
    if (values.isEmpty) return null;

    final index = ((values.length - 1) * percentile).ceil();
    return values[index] / 1000;
  }

  String _formatDuration(Duration duration) {
    if (duration.inMicroseconds < 100) return '<0.1ms';
    return '${(duration.inMicroseconds / 1000).toStringAsFixed(1)}ms';
  }

  String _formatMilliseconds(double? value) {
    if (value == null) return '—';
    if (value < 0.1) return '<0.1ms';
    return '${value.toStringAsFixed(1)}ms';
  }
}

class _SessionMeasurementNotice extends StatelessWidget {
  const _SessionMeasurementNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.monitor_heart_outlined, size: 20, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live session measurements',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Results vary by device, browser, and build mode. Compare '
                  'configurations here; do not treat these values as package '
                  'benchmark guarantees.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
