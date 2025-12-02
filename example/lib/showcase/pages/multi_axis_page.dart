// Copyright 2025 Braven Charts - Multi-Axis Page
// SPDX-License-Identifier: MIT

import 'dart:math';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../data/data_generator.dart';
import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// Demonstrates multi-axis features:
/// - Dual Y-axis charts
/// - Different scales on each axis
/// - Series-to-axis binding
/// - Normalization modes
class MultiAxisPage extends StatefulWidget {
  const MultiAxisPage({super.key});

  @override
  State<MultiAxisPage> createState() => _MultiAxisPageState();
}

class _MultiAxisPageState extends State<MultiAxisPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();

  // Multi-axis demo selection
  int _selectedDemo = 0;

  // Generated data for different demos
  late List<ChartDataPoint> _powerData;
  late List<ChartDataPoint> _heartRateData;
  late List<ChartDataPoint> _cadenceData;
  late List<ChartDataPoint> _temperatureData;
  late List<ChartDataPoint> _pressureData;

  // Test data - specific ranges for multi-axis testing
  late List<ChartDataPoint> _testSmallRangeData; // 0-100
  late List<ChartDataPoint> _testLargeRangeData; // 250-1500
  late List<ChartDataPoint> _testMediumRangeData; // 500-800 (right axis)

  @override
  void initState() {
    super.initState();
    _regenerateData();
  }

  void _regenerateData() {
    setState(() {
      // Athletic data - Power, HR, Cadence
      _powerData = DataGenerator.generatePowerData(count: 200);
      _heartRateData = DataGenerator.generateHeartRateData(count: 200);
      _cadenceData = DataGenerator.generateCadenceData(count: 200);

      // Scientific data - Temperature, Pressure
      _temperatureData = DataGenerator.generateTemperatureData(count: 100);
      _pressureData = DataGenerator.generateLinear(
        count: 100,
        slope: 0.5,
        intercept: 1013,
        noise: 5,
      );

      // Test data - specific ranges for multi-axis testing with randomness
      _testSmallRangeData = _generateSmallRangeData();
      _testLargeRangeData = _generateLargeRangeData();
      _testMediumRangeData = _generateMediumRangeData();
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
      title: 'Multi-Axis',
      subtitle: 'Display multiple scales in one chart',
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
        icon: Icons.category,
        children: [
          SegmentedOption<int>(
            value: _selectedDemo,
            options: const [0, 1, 2],
            labelBuilder: (v) => v == 0
                ? 'Athletic'
                : v == 1
                    ? 'Scientific'
                    : 'Test',
            onChanged: (v) => setState(() => _selectedDemo = v),
          ),
          const SizedBox(height: 8),
          InfoBox(
            message: _selectedDemo == 0
                ? 'Power, Heart Rate, and Cadence on different scales'
                : _selectedDemo == 1
                    ? 'Temperature and Pressure with different units'
                    : 'Test: Series 1 (0-100) vs Series 2 (250-1500) vs Series 3 (500-800)',
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
        ],
      ),
    ];
  }

  Widget _buildChart() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        if (_selectedDemo == 0) {
          return _buildAthleticChart();
        } else if (_selectedDemo == 1) {
          return _buildScientificChart();
        } else {
          return _buildTestChart();
        }
      },
    );
  }

  Widget _buildAthleticChart() {
    return ChartCard(
      title: 'Athletic Performance',
      subtitle: 'Power (W), Heart Rate (bpm), Cadence (rpm)',
      child: BravenChartPlus(
        chartType: ChartType.line,
        lineStyle: LineStyle.smooth,
        series: [
          LineChartSeries(
            id: 'power',
            name: 'Power (W)',
            points: _powerData,
            color: Colors.blue,
            interpolation: LineInterpolation.bezier,
            strokeWidth: 2.0,
            yAxisId: 'power_axis',
            unit: 'W',
          ),
          LineChartSeries(
            id: 'heart_rate',
            name: 'Heart Rate (bpm)',
            points: _heartRateData,
            color: Colors.red,
            interpolation: LineInterpolation.bezier,
            strokeWidth: 2.0,
            yAxisId: 'hr_axis',
            unit: 'bpm',
          ),
          LineChartSeries(
            id: 'cadence',
            name: 'Cadence (rpm)',
            points: _cadenceData,
            color: Colors.green,
            interpolation: LineInterpolation.bezier,
            strokeWidth: 2.0,
            yAxisId: 'cadence_axis',
            unit: 'rpm',
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
        yAxes: [
          YAxisConfig(
            id: 'power_axis',
            position: YAxisPosition.left,
            label: 'Power',
            unit: 'W',
            showAxisLine: true,
          ),
          YAxisConfig(
            id: 'hr_axis',
            position: YAxisPosition.right,
            label: 'Heart Rate',
            unit: 'bpm',
            showAxisLine: true,
          ),
        ],
        interactionConfig: InteractionConfig(
          enableZoom: _optionsController.enableZoom,
          enablePan: _optionsController.enablePan,
          crosshair: const CrosshairConfig(enabled: true),
          tooltip: const TooltipConfig(enabled: true),
        ),
      ),
    );
  }

  Widget _buildScientificChart() {
    return ChartCard(
      title: 'Environmental Monitoring',
      subtitle: 'Temperature (°C) and Pressure (hPa)',
      child: BravenChartPlus(
        chartType: ChartType.line,
        lineStyle: LineStyle.smooth,
        series: [
          LineChartSeries(
            id: 'temperature',
            name: 'Temperature (°C)',
            points: _temperatureData,
            color: Colors.orange,
            interpolation: LineInterpolation.bezier,
            strokeWidth: 2.0,
            yAxisId: 'temp_axis',
            unit: '°C',
          ),
          LineChartSeries(
            id: 'pressure',
            name: 'Pressure (hPa)',
            points: _pressureData,
            color: Colors.purple,
            interpolation: LineInterpolation.linear,
            strokeWidth: 2.0,
            yAxisId: 'pressure_axis',
            unit: 'hPa',
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
        yAxes: [
          YAxisConfig(
            id: 'temp_axis',
            position: YAxisPosition.left,
            label: 'Temperature',
            unit: '°C',
            showAxisLine: true,
          ),
          YAxisConfig(
            id: 'pressure_axis',
            position: YAxisPosition.right,
            label: 'Pressure',
            unit: 'hPa',
            showAxisLine: true,
          ),
        ],
        interactionConfig: InteractionConfig(
          enableZoom: _optionsController.enableZoom,
          enablePan: _optionsController.enablePan,
          crosshair: const CrosshairConfig(enabled: true),
          tooltip: const TooltipConfig(enabled: true),
        ),
      ),
    );
  }

  Widget _buildTestChart() {
    return ChartCard(
      title: 'Multi-Axis Test',
      subtitle: 'Series 1: 0-100  |  Series 2: 250-1500  |  Series 3: 500-800',
      child: BravenChartPlus(
        chartType: ChartType.line,
        lineStyle: LineStyle.smooth,
        series: [
          LineChartSeries(
            id: 'small_range',
            name: 'Small Range (0-100)',
            points: _testSmallRangeData,
            color: Colors.blue,
            interpolation: LineInterpolation.linear,
            strokeWidth: 2.0,
            yAxisId: 'small_axis',
            unit: "RMP",
          ),
          LineChartSeries(
            id: 'large_range',
            name: 'Large Range (250-1500)',
            points: _testLargeRangeData,
            color: Colors.red,
            interpolation: LineInterpolation.linear,
            strokeWidth: 2.0,
            yAxisId: 'large_axis',
            unit: "Watts(W)",
          ),
          LineChartSeries(
            id: 'medium_range',
            name: 'Medium Range (500-800)',
            points: _testMediumRangeData,
            color: Colors.green,
            interpolation: LineInterpolation.linear,
            strokeWidth: 2.0,
            yAxisId: 'medium_axis',
            unit: "BPM",
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
          label: "Time(M)",
          // labelStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
        yAxis: AxisConfig(
          showGrid: _optionsController.showGrid,
          showAxis: _optionsController.showAxisLines,
          label: "Y-axis",
        ),
        yAxes: [
          YAxisConfig(
            id: 'small_axis',
            position: YAxisPosition.left,
            label: 'Small',
            axisMargin: 5,
            axisLabelPadding: 5,
            tickLabelPadding: 0,
            minWidth: 0,
            showAxisLine: true,
            unit: 'RPM',
            labelDisplay: AxisLabelDisplay.labelWithUnit, // "Small (RPM)" + tick values without unit
            labelFormatter: (value) {
              return value.toStringAsFixed(2);
              // return "$value";
            },
            
          ),
          YAxisConfig(
            id: 'large_axis',
            position: YAxisPosition.leftOuter,
            label: 'Large',
            showAxisLine: true,
            unit: 'W',
            labelDisplay: AxisLabelDisplay.labelWithUnit, // "Large (W)" + tick values without unit
          ),
          YAxisConfig(
            id: 'medium_axis',
            position: YAxisPosition.right,
            label: 'Medium',
            showAxisLine: true,
            unit: 'BPM',
            labelDisplay: AxisLabelDisplay.tickOnly, // "Medium (BPM)" + tick values without unit
            // tickLabelPadding: 50,
          ),
        ],
        axisBindings: const [
          SeriesAxisBinding(seriesId: 'small_range', yAxisId: 'small_axis'),
          SeriesAxisBinding(seriesId: 'large_range', yAxisId: 'large_axis'),
          SeriesAxisBinding(seriesId: 'medium_range', yAxisId: 'medium_axis'),
        ],
        normalizationMode: NormalizationMode.perSeries,
        interactionConfig: InteractionConfig(
          enableZoom: _optionsController.enableZoom,
          enablePan: _optionsController.enablePan,
          crosshair: const CrosshairConfig(
            enabled: true,
            displayMode: CrosshairDisplayMode.tracking, // Force tracking mode for unified tooltip
          ),
          tooltip: const TooltipConfig(enabled: true),
        ),
      ),
    );
  }

  Widget _buildStatusPanel() {
    if (_selectedDemo == 0) {
      return StatusPanel(
        items: [
          StatusItem(label: 'Power Pts', value: '${_powerData.length}'),
          StatusItem(label: 'HR Pts', value: '${_heartRateData.length}'),
          StatusItem(label: 'Cadence Pts', value: '${_cadenceData.length}'),
          const StatusItem(label: 'Axes', value: '3', color: Colors.blue),
        ],
      );
    } else if (_selectedDemo == 1) {
      return StatusPanel(
        items: [
          StatusItem(label: 'Temp Pts', value: '${_temperatureData.length}'),
          StatusItem(label: 'Pressure Pts', value: '${_pressureData.length}'),
          const StatusItem(label: 'Axes', value: '2', color: Colors.blue),
        ],
      );
    } else {
      return StatusPanel(
        items: [
          const StatusItem(label: 'Small Range', value: '0-100'),
          const StatusItem(label: 'Large Range', value: '250-1500'),
          const StatusItem(label: 'Medium Range', value: '500-800'),
          StatusItem(label: 'Points', value: '${_testSmallRangeData.length}'),
          const StatusItem(label: 'Axes', value: '3', color: Colors.orange),
        ],
      );
    }
  }

  // ============================================================
  // Randomized Test Data Generators
  // ============================================================

  static final Random _random = Random();

  /// Generates randomized data in the 0-100 range with realistic patterns
  List<ChartDataPoint> _generateSmallRangeData() {
    final points = <ChartDataPoint>[];
    double value = 50 + _random.nextDouble() * 20; // Start between 50-70

    for (var i = 0; i < 50; i++) {
      final x = i.toDouble();

      // Random walk with mean reversion
      final delta = (_random.nextDouble() - 0.5) * 15;
      value += delta;

      // Add occasional jumps
      if (_random.nextDouble() < 0.08) {
        value += (_random.nextBool() ? 1 : -1) * _random.nextDouble() * 20;
      }

      // Keep in range 0-100
      value = value.clamp(0.0, 100.0);

      points.add(ChartDataPoint(x: x, y: value));
    }
    return points;
  }

  /// Generates randomized data in the 250-1500 range with realistic patterns
  List<ChartDataPoint> _generateLargeRangeData() {
    final points = <ChartDataPoint>[];
    double value = 800 + _random.nextDouble() * 200; // Start between 800-1000

    for (var i = 0; i < 50; i++) {
      final x = i.toDouble();

      // Random walk with larger steps for larger range
      final delta = (_random.nextDouble() - 0.5) * 150;
      value += delta;

      // Add occasional spikes
      if (_random.nextDouble() < 0.1) {
        value += (_random.nextBool() ? 1 : -1) * _random.nextDouble() * 200;
      }

      // Keep in range 250-1500
      value = value.clamp(250.0, 1500.0);

      points.add(ChartDataPoint(x: x, y: value));
    }
    return points;
  }

  /// Generates randomized data in the 500-800 range (right axis test)
  List<ChartDataPoint> _generateMediumRangeData() {
    final points = <ChartDataPoint>[];
    double value = 620 + _random.nextDouble() * 60; // Start between 620-680

    for (var i = 0; i < 50; i++) {
      final x = i.toDouble();

      // Random walk with medium steps
      final delta = (_random.nextDouble() - 0.5) * 40;
      value += delta;

      // Add occasional jumps
      if (_random.nextDouble() < 0.1) {
        value += (_random.nextBool() ? 1 : -1) * _random.nextDouble() * 50;
      }

      // Keep in range 500-800
      value = value.clamp(500.0, 800.0);

      points.add(ChartDataPoint(x: x, y: value));
    }
    return points;
  }
}
