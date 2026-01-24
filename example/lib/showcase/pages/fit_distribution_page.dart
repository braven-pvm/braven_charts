// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:io';
import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_data/braven_data.dart' as bd;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

enum DistributionMetric {
  time,
  work,
}

/// Loads FIT files and visualizes power distribution using braven_data.
class FitDistributionPage extends StatefulWidget {
  const FitDistributionPage({super.key});

  @override
  State<FitDistributionPage> createState() => _FitDistributionPageState();
}

class _FitDistributionPageState extends State<FitDistributionPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();

  bool _loading = true;
  String? _error;
  List<String> _fitFiles = [];
  String? _selectedFile;

  bd.DistributionResult? _result;
  List<String> _bandLabels = [];
  List<ChartDataPoint> _timePoints = [];
  List<ChartDataPoint> _workPoints = [];

  double _bandWidth = 20.0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _optionsController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    if (kIsWeb) {
      await _loadSyntheticDistribution();
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final dataDir = _findDataDirectory();
    if (dataDir == null) {
      setState(() {
        _loading = false;
        _error = 'Unable to locate data directory containing .FIT files.';
      });
      return;
    }

    final fitFiles = _listFitFiles(dataDir);
    if (fitFiles.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No .FIT files found in $dataDir.';
      });
      return;
    }

    _fitFiles = fitFiles;
    _selectedFile ??= _fitFiles.first;

    await _loadDistribution();
  }

  String? _findDataDirectory() {
    var dir = Directory.current;
    for (var i = 0; i < 6; i++) {
      final candidate = Directory(_join(dir.path, 'data'));
      if (candidate.existsSync()) {
        return candidate.path;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) {
        break;
      }
      dir = parent;
    }
    return null;
  }

  List<String> _listFitFiles(String dataDir) {
    return Directory(dataDir).listSync().whereType<File>().map((file) => file.path).where((path) => path.toLowerCase().endsWith('.fit')).toList()
      ..sort();
  }

  Future<void> _loadDistribution() async {
    if (_selectedFile == null) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final df = await bd.FitLoader.load(
        _selectedFile!,
        bd.FitMessageType.records,
      );

      final column = _resolveMetricColumn(df);

      final series = df.toSeries(column);
      final result = bd.DistributionCalculator.calculate(
        series,
        _bandWidth,
        minVal: 0,
        maxGap: 10.0,
      );
      _applyDistributionResult(result);
    } catch (error) {
      setState(() {
        _loading = false;
        _error = 'Failed to load FIT data: $error';
      });
    }
  }

  String _resolveMetricColumn(bd.DataFrame df) {
    const preferred = ['power', 'heart_rate', 'cadence'];
    for (final name in preferred) {
      if (df.columnNames.contains(name)) {
        return name;
      }
    }

    for (final name in df.columnNames) {
      final values = df.columns[name];
      if (values == null || values.isEmpty) {
        continue;
      }
      if (values.first is num) {
        return name;
      }
    }

    return df.columnNames.first;
  }

  Future<void> _loadSyntheticDistribution() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final random = math.Random(42);
    final xValues = List<double>.generate(1200, (i) => i.toDouble());
    final yValues = List<double>.generate(
      1200,
      (i) => 180 + 40 * math.sin(i / 35) + random.nextDouble() * 30,
    );

    final series = bd.Series<double, double>.fromTypedData(
      meta: const bd.SeriesMeta(name: 'Synthetic Power', unit: 'W'),
      xValues: xValues,
      yValues: yValues,
    );

    final result = bd.DistributionCalculator.calculate(
      series,
      _bandWidth,
      minVal: 0,
      maxGap: 10.0,
    );

    _applyDistributionResult(result);
  }

  void _applyDistributionResult(bd.DistributionResult result) {
    final timeSeries = result.toTimeSeries();
    final workSeries = result.toWorkSeries();

    final labels = <String>[];
    final timePoints = <ChartDataPoint>[];
    final workPoints = <ChartDataPoint>[];

    for (var i = 0; i < timeSeries.length; i++) {
      final label = timeSeries.getX(i);
      final timeSeconds = timeSeries.getY(i);
      final workKj = workSeries.getY(i) / 1000.0;

      labels.add(label);
      timePoints.add(
        ChartDataPoint(
          x: i.toDouble(),
          y: timeSeconds,
          label: label,
        ),
      );
      workPoints.add(
        ChartDataPoint(
          x: i.toDouble(),
          y: workKj,
          label: label,
        ),
      );
    }

    setState(() {
      _result = result;
      _bandLabels = labels;
      _timePoints = timePoints;
      _workPoints = workPoints;
      _loading = false;
    });
  }

  String _fileName(String path) {
    final separator = Platform.pathSeparator;
    final parts = path.split(separator);
    return parts.isNotEmpty ? parts.last : path;
  }

  String _join(String a, String b) {
    if (a.endsWith(Platform.pathSeparator)) {
      return '$a$b';
    }
    return '$a${Platform.pathSeparator}$b';
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'FIT Distribution Analysis',
      subtitle: 'Loads FIT files via braven_data and charts distribution bands',
      optionsChildren: _buildOptions(),
      chart: _buildChart(),
      bottomPanel: _buildStatusPanel(),
    );
  }

  List<Widget> _buildOptions() {
    return [
      StandardChartOptions(controller: _optionsController),
      OptionSection(
        title: 'Dataset',
        icon: Icons.folder_open,
        children: [
          if (_fitFiles.isNotEmpty)
            DropdownButton<String>(
              value: _selectedFile,
              isExpanded: true,
              onChanged: (value) {
                setState(() => _selectedFile = value);
                _loadDistribution();
              },
              items: _fitFiles
                  .map(
                    (file) => DropdownMenuItem(
                      value: file,
                      child: Text(
                        _fileName(file),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
      OptionSection(
        title: 'Distribution',
        icon: Icons.bar_chart,
        children: [
          SliderOption(
            label: 'Band Width (W)',
            value: _bandWidth,
            min: 10,
            max: 100,
            divisions: 9,
            onChanged: (value) {
              setState(() => _bandWidth = value);
              _loadDistribution();
            },
          ),
        ],
      ),
    ];
  }

  Widget _buildChart() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_timePoints.isEmpty) {
      return const Center(child: Text('No distribution data available.'));
    }

    final tickCount = _bandLabels.length >= 2 ? (_bandLabels.length < 8 ? _bandLabels.length : 8) : null;

    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        return BravenChartPlus(
          series: [
            BarChartSeries(
              id: 'time_distribution',
              name: 'Time in band',
              points: _timePoints,
              barWidthPercent: 0.7,
              color: Colors.indigo,
              isXOrdered: true,
              yAxisConfig: YAxisConfig(
                position: YAxisPosition.left,
                label: 'Time',
                unit: 's',
                labelFormatter: (value) => value.toStringAsFixed(0),
              ),
            ),
            BarChartSeries(
              id: 'work_distribution',
              name: 'Work in band',
              points: _workPoints,
              color: Colors.orange,
              barWidthPercent: 0.7,
              isXOrdered: true,
              yAxisConfig: YAxisConfig(
                position: YAxisPosition.right,
                label: 'Work',
                unit: 'kJ',
                labelFormatter: (value) => value.toStringAsFixed(1),
              ),
            ),
            BarChartSeries(
              id: 'work_distribution_2',
              name: 'Work in band',
              points: _workPoints,
              color: Colors.red,
              barWidthPercent: 0.7,
              isXOrdered: true,
              yAxisConfig: YAxisConfig(
                position: YAxisPosition.right,
                label: 'Work',
                unit: 'kJ',
                labelFormatter: (value) => value.toStringAsFixed(1),
              ),
            ),
          ],
          theme: _optionsController.theme,
          showLegend: _optionsController.showLegend,
          showXScrollbar: _optionsController.showXScrollbar,
          showYScrollbar: _optionsController.showYScrollbar,
          scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(autoHide: false),
          xAxisConfig: XAxisConfig(
            label: 'Band (W)',
            tickCount: tickCount,
            showAxisLine: _optionsController.showAxisLines,
            labelFormatter: (value) {
              final index = value.round();
              if (index < 0 || index >= _bandLabels.length) {
                return '';
              }
              return _bandLabels[index];
            },
          ),
          normalizationMode: NormalizationMode.perSeries,
          interactionConfig: InteractionConfig(
            enableZoom: _optionsController.enableZoom,
            enablePan: _optionsController.enablePan,
          ),
        );
      },
    );
  }

  Widget _buildStatusPanel() {
    if (_result == null) {
      return const SizedBox.shrink();
    }

    final totalSeconds = _result!.timeInBand.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final totalWork = _result!.workInBand.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildStat('Bands', _bandLabels.length.toString()),
            _buildStat('Total Time', '${(totalSeconds / 60).toStringAsFixed(1)} min'),
            _buildStat(
              'Total Work',
              '${(totalWork / 1000).toStringAsFixed(1)} kJ',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
