// Copyright 2025 Braven Charts - Scientific Charts Page
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../data/data_generator.dart';
import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// Demonstrates scientific/mathematical charting:
/// - Mathematical functions
/// - Signal processing visualizations
/// - Scatter plots with regression
/// - Gaussian distributions
class ScientificPage extends StatefulWidget {
  const ScientificPage({super.key});

  @override
  State<ScientificPage> createState() => _ScientificPageState();
}

class _ScientificPageState extends State<ScientificPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();

  // Demo selection
  int _selectedDemo = 0;

  // Function parameters
  double _frequency = 0.2;
  double _amplitude = 30.0;
  double _phase = 0.0;
  int _harmonics = 1;

  // Generated data
  late List<ChartDataPoint> _functionData;
  late List<ChartDataPoint> _secondaryData;
  late List<ChartDataPoint> _gaussianData;

  @override
  void initState() {
    super.initState();
    _regenerateData();
  }

  void _regenerateData() {
    setState(() {
      switch (_selectedDemo) {
        case 0: // Sine waves
          _functionData = _generateSineWithHarmonics();
          _secondaryData = DataGenerator.generateCosineWave(
            count: 100,
            frequency: _frequency,
            amplitude: _amplitude * 0.7,
            yOffset: 50,
          );
        case 1: // Gaussian
          _functionData = DataGenerator.generateGaussian(
            count: 100,
            mean: 50,
            stdDev: 15,
            amplitude: 50,
          );
          _gaussianData = DataGenerator.generateGaussian(
            count: 100,
            mean: 60,
            stdDev: 10,
            amplitude: 40,
          );
        case 2: // Scatter with noise
          _functionData = _generateScatterData();
          _secondaryData = _generateTrendLine();
      }
    });
  }

  List<ChartDataPoint> _generateSineWithHarmonics() {
    final points = <ChartDataPoint>[];
    for (int i = 0; i < 200; i++) {
      final x = i.toDouble();
      double y = 50; // Center

      // Add fundamental and harmonics
      for (int h = 1; h <= _harmonics; h++) {
        y += (_amplitude / h) * math.sin(_frequency * h * x + _phase);
      }

      points.add(ChartDataPoint(x: x, y: y));
    }
    return points;
  }

  List<ChartDataPoint> _generateScatterData() {
    final random = math.Random(42);
    final points = <ChartDataPoint>[];
    for (int i = 0; i < 50; i++) {
      final x = i * 2.0;
      // Linear trend with noise
      final y = 20 + x * 0.5 + (random.nextDouble() - 0.5) * 30;
      points.add(ChartDataPoint(x: x, y: y));
    }
    return points;
  }

  List<ChartDataPoint> _generateTrendLine() {
    return List.generate(50, (i) {
      final x = i * 2.0;
      final y = 20 + x * 0.5; // Linear trend without noise
      return ChartDataPoint(x: x, y: y);
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
      title: 'Scientific Charts',
      subtitle: 'Mathematical functions and analysis',
      optionsChildren: _buildOptionsChildren(),
      chart: _buildChart(),
      bottomPanel: _buildStatusPanel(),
    );
  }

  List<Widget> _buildOptionsChildren() {
    return [
      // Standard display options
      StandardChartOptions(controller: _optionsController),

      // Demo selection
      OptionSection(
        title: 'Demo Selection',
        icon: Icons.science,
        children: [
          SegmentedOption<int>(
            value: _selectedDemo,
            options: const [0, 1, 2],
            labelBuilder: (v) => switch (v) {
              0 => 'Waves',
              1 => 'Gaussian',
              _ => 'Scatter',
            },
            onChanged: (v) {
              setState(() => _selectedDemo = v);
              _regenerateData();
            },
          ),
        ],
      ),

      // Demo-specific options
      if (_selectedDemo == 0)
        OptionSection(
          title: 'Wave Parameters',
          children: [
            SliderOption(
              label: 'Frequency',
              value: _frequency,
              min: 0.05,
              max: 0.5,
              divisions: 9,
              onChanged: (v) {
                setState(() => _frequency = v);
                _regenerateData();
              },
            ),
            SliderOption(
              label: 'Amplitude',
              value: _amplitude,
              min: 10,
              max: 40,
              divisions: 6,
              onChanged: (v) {
                setState(() => _amplitude = v);
                _regenerateData();
              },
            ),
            SliderOption(
              label: 'Phase (rad)',
              value: _phase,
              min: 0,
              max: 2 * math.pi,
              divisions: 12,
              onChanged: (v) {
                setState(() => _phase = v);
                _regenerateData();
              },
            ),
            IntSliderOption(
              label: 'Harmonics',
              value: _harmonics,
              min: 1,
              max: 5,
              onChanged: (v) {
                setState(() => _harmonics = v);
                _regenerateData();
              },
            ),
          ],
        ),

      // Actions
      OptionSection(
        title: 'Actions',
        children: [
          ActionButton(
            label: 'Regenerate',
            icon: Icons.refresh,
            onPressed: _regenerateData,
          ),
        ],
      ),

      // Info
      InfoBox(
        message: switch (_selectedDemo) {
          0 => 'Sine wave with configurable harmonics for Fourier-like synthesis',
          1 => 'Gaussian/Normal distributions with different parameters',
          _ => 'Scatter plot with linear regression trend line',
        },
      ),
    ];
  }

  Widget _buildChart() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        return ChartCard(
          title: switch (_selectedDemo) {
            0 => 'Wave Analysis',
            1 => 'Gaussian Distribution',
            _ => 'Scatter Plot with Trend',
          },
          subtitle: switch (_selectedDemo) {
            0 => 'f=${_frequency.toStringAsFixed(2)}, A=${_amplitude.toStringAsFixed(0)}, harmonics=$_harmonics',
            1 => 'Normal distributions',
            _ => 'Linear regression',
          },
          child: _buildChartWidget(),
        );
      },
    );
  }

  Widget _buildChartWidget() {
    switch (_selectedDemo) {
      case 0: // Waves
        return BravenChartPlus(
          lineStyle: LineStyle.smooth,
          series: [
            LineChartSeries(
              id: 'sine',
              name: 'Sine + Harmonics',
              points: _functionData,
              color: Colors.blue,
              interpolation: LineInterpolation.bezier,
              strokeWidth: 2.0,
            ),
            LineChartSeries(
              id: 'cosine',
              name: 'Cosine',
              points: _secondaryData,
              color: Colors.orange.withValues(alpha: 0.7),
              interpolation: LineInterpolation.bezier,
              strokeWidth: 1.5,
            ),
          ],
          theme: _optionsController.theme,
          showLegend: _optionsController.showLegend,
          showXScrollbar: _optionsController.showXScrollbar,
          showYScrollbar: _optionsController.showYScrollbar,
          scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(autoHide: false),
          xAxis: AxisConfig(
            showGrid: _optionsController.showGrid,
            showAxis: _optionsController.showAxisLines,
          ),
          yAxis: AxisConfig(
            showGrid: _optionsController.showGrid,
            showAxis: _optionsController.showAxisLines,
          ),
          interactionConfig: InteractionConfig(
            enableZoom: _optionsController.enableZoom,
            enablePan: _optionsController.enablePan,
          ),
        );

      case 1: // Gaussian
        return BravenChartPlus(
          lineStyle: LineStyle.smooth,
          series: [
            AreaChartSeries(
              id: 'gaussian1',
              name: 'Distribution A',
              points: _functionData,
              color: Colors.blue,
              interpolation: LineInterpolation.bezier,
              fillOpacity: 0.3,
              strokeWidth: 2.0,
            ),
            AreaChartSeries(
              id: 'gaussian2',
              name: 'Distribution B',
              points: _gaussianData,
              color: Colors.green,
              interpolation: LineInterpolation.bezier,
              fillOpacity: 0.3,
              strokeWidth: 2.0,
            ),
          ],
          theme: _optionsController.theme,
          showLegend: _optionsController.showLegend,
          showXScrollbar: _optionsController.showXScrollbar,
          showYScrollbar: _optionsController.showYScrollbar,
          scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(autoHide: false),
          xAxis: AxisConfig(
            showGrid: _optionsController.showGrid,
            showAxis: _optionsController.showAxisLines,
          ),
          yAxis: AxisConfig(
            showGrid: _optionsController.showGrid,
            showAxis: _optionsController.showAxisLines,
          ),
          interactionConfig: InteractionConfig(
            enableZoom: _optionsController.enableZoom,
            enablePan: _optionsController.enablePan,
          ),
        );

      case 2: // Scatter
      default:
        return BravenChartPlus(
          series: [
            ScatterChartSeries(
              id: 'scatter',
              name: 'Data Points',
              points: _functionData,
              color: Colors.blue,
              markerRadius: 5.0,
            ),
            LineChartSeries(
              id: 'trend',
              name: 'Trend Line',
              points: _secondaryData,
              color: Colors.red,
              interpolation: LineInterpolation.linear,
              strokeWidth: 2.0,
            ),
          ],
          theme: _optionsController.theme,
          showLegend: _optionsController.showLegend,
          showXScrollbar: _optionsController.showXScrollbar,
          showYScrollbar: _optionsController.showYScrollbar,
          scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(autoHide: false),
          xAxis: AxisConfig(
            showGrid: _optionsController.showGrid,
            showAxis: _optionsController.showAxisLines,
          ),
          yAxis: AxisConfig(
            showGrid: _optionsController.showGrid,
            showAxis: _optionsController.showAxisLines,
          ),
          interactionConfig: InteractionConfig(
            enableZoom: _optionsController.enableZoom,
            enablePan: _optionsController.enablePan,
          ),
        );
    }
  }

  Widget _buildStatusPanel() {
    return StatusPanel(
      items: [
        StatusItem(
          label: 'Demo',
          value: switch (_selectedDemo) {
            0 => 'Waves',
            1 => 'Gaussian',
            _ => 'Scatter',
          },
        ),
        StatusItem(
          label: 'Data Points',
          value: '${_functionData.length}',
        ),
        if (_selectedDemo == 0) ...[
          StatusItem(label: 'Frequency', value: _frequency.toStringAsFixed(2)),
          StatusItem(label: 'Harmonics', value: '$_harmonics'),
        ],
      ],
    );
  }
}
