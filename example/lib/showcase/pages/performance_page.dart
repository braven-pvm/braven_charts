// Copyright 2025 Braven Charts - Performance Page
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../data/data_generator.dart';
import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// Demonstrates performance with large datasets:
/// - Varying data point counts
/// - Render performance metrics
/// - Optimization techniques
class PerformancePage extends StatefulWidget {
  const PerformancePage({super.key});

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  final ChartOptionsController _optionsController = ChartOptionsController();

  // Performance options
  int _dataPointCount = 1000;
  int _seriesCount = 1;
  bool _useSmoothing = false;

  // Performance metrics
  int _lastRenderTimeMs = 0;
  int _renderCount = 0;
  Stopwatch? _renderStopwatch;

  // Generated data
  List<List<ChartDataPoint>> _allSeriesData = [];

  @override
  void initState() {
    super.initState();
    _regenerateData();
  }

  void _regenerateData() {
    final stopwatch = Stopwatch()..start();

    _allSeriesData = List.generate(_seriesCount, (seriesIndex) {
      return DataGenerator.generateRandomWalk(
        count: _dataPointCount,
        startY: 50.0 + seriesIndex * 10,
        stepSize: 3.0,
      );
    });

    stopwatch.stop();
    setState(() {
      _lastRenderTimeMs = stopwatch.elapsedMilliseconds;
      _renderCount++;
    });
  }

  @override
  void dispose() {
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Performance',
      subtitle: 'Test with large datasets',
      optionsChildren: _buildOptionsChildren(),
      chart: _buildChart(),
      bottomPanel: _buildStatusPanel(),
    );
  }

  List<Widget> _buildOptionsChildren() {
    return [
      // Standard display options
      StandardChartOptions(controller: _optionsController),

      // Performance options
      OptionSection(
        title: 'Data Size',
        icon: Icons.data_usage,
        children: [
          EnumOption<int>(
            label: 'Data Points',
            value: _dataPointCount,
            values: const [100, 500, 1000, 5000, 10000],
            labelBuilder: (v) => '$v points',
            onChanged: (v) {
              setState(() => _dataPointCount = v);
              _regenerateData();
            },
          ),
          EnumOption<int>(
            label: 'Series Count',
            value: _seriesCount,
            values: const [1, 2, 3, 5],
            labelBuilder: (v) => '$v ${v == 1 ? 'series' : 'series'}',
            onChanged: (v) {
              setState(() => _seriesCount = v);
              _regenerateData();
            },
          ),
          BoolOption(
            label: 'Smooth Lines',
            value: _useSmoothing,
            onChanged: (v) => setState(() => _useSmoothing = v),
            subtitle: 'Uses more CPU for bezier curves',
          ),
        ],
      ),

      // Actions
      OptionSection(
        title: 'Actions',
        children: [
          ActionButton(
            label: 'Regenerate Data',
            icon: Icons.refresh,
            onPressed: _regenerateData,
          ),
          const SizedBox(height: 8),
          ActionButton(
            label: 'Stress Test (10K)',
            icon: Icons.speed,
            onPressed: () {
              setState(() => _dataPointCount = 10000);
              _regenerateData();
            },
          ),
        ],
      ),

      // Info
      InfoBox(
        message: 'Total data points: ${_dataPointCount * _seriesCount}. '
            'Generation time: ${_lastRenderTimeMs}ms.',
        type: _dataPointCount > 5000 ? InfoBoxType.warning : InfoBoxType.info,
      ),
    ];
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
          title: 'Performance Test',
          subtitle: '${_dataPointCount * _seriesCount} total points',
          child: BravenChartPlus(
            series: List.generate(_allSeriesData.length, (i) {
              return LineChartSeries(
                id: 'series_$i',
                name: 'Series ${i + 1}',
                points: _allSeriesData[i],
                color: colors[i % colors.length],
                interpolation: _useSmoothing
                    ? LineInterpolation.bezier
                    : LineInterpolation.linear,
                strokeWidth: 1.5,
                showDataPointMarkers: _optionsController.showDataMarkers &&
                    _dataPointCount <= 100,
              );
            }),
            theme: _optionsController.theme,
            showLegend: _seriesCount > 1 && _optionsController.showLegend,
            showXScrollbar: _optionsController.showXScrollbar,
            showYScrollbar: _optionsController.showYScrollbar,
            scrollbarTheme:
                ScrollbarConfig.defaultLight.copyWith(autoHide: false),
            xAxis: AxisConfig(
              showAxis: _optionsController.showAxisLines,
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
    final totalPoints = _dataPointCount * _seriesCount;
    final performanceLevel = totalPoints < 1000
        ? 'Excellent'
        : totalPoints < 5000
            ? 'Good'
            : totalPoints < 10000
                ? 'Moderate'
                : 'Intensive';

    return StatusPanel(
      items: [
        StatusItem(
          label: 'Points/Series',
          value: '$_dataPointCount',
        ),
        StatusItem(
          label: 'Total Points',
          value: '$totalPoints',
        ),
        StatusItem(
          label: 'Gen Time',
          value: '${_lastRenderTimeMs}ms',
        ),
        StatusItem(
          label: 'Performance',
          value: performanceLevel,
          color: totalPoints < 5000 ? Colors.green : Colors.orange,
        ),
      ],
    );
  }
}
