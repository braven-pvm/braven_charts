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

  // Annotation controller for reactive, editable annotations
  final AnnotationController _annotationController = AnnotationController();

  // Annotation interaction settings
  bool _interactiveAnnotations = true;
  bool _allowDragging = true;
  bool _allowEditing = true;
  bool _snapToValue = false;
  bool _showAnnotations = true;

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

  // VO2 Max Test data
  late List<ChartDataPoint> _targetPowerData; // Stepped target zones (0-350W)
  late List<ChartDataPoint> _feO2Data; // FeO2% (14-19%)
  late List<ChartDataPoint> _eqO2Data; // EqO2 (20-60)

  @override
  void initState() {
    super.initState();
    _regenerateData();
    _rebuildAnnotations();
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

      // VO2 Max Test data
      _targetPowerData = _generateTargetPowerData();
      _feO2Data = _generateFeO2Data();
      _eqO2Data = _generateEqO2Data();
    });
  }

  /// Rebuilds annotations based on current demo and settings.
  void _rebuildAnnotations() {
    _annotationController.clearAnnotations();
    if (!_showAnnotations) return;

    if (_selectedDemo == 0) {
      // Athletic demo: Power thresholds and zones
      _annotationController.addAnnotation(ThresholdAnnotation(
        id: 'power_threshold_low',
        axis: AnnotationAxis.y,
        value: 200,
        label: 'Zone 2',
        lineColor: Colors.green.withValues(alpha: 0.7),
        labelPosition: AnnotationLabelPosition.bottomLeft,
        allowDragging: _allowDragging,
        allowEditing: _allowEditing,
      ));
      _annotationController.addAnnotation(ThresholdAnnotation(
        id: 'power_threshold_high',
        axis: AnnotationAxis.y,
        value: 300,
        label: 'Zone 4',
        lineColor: Colors.red.withValues(alpha: 0.7),
        labelPosition: AnnotationLabelPosition.topRight,
        allowDragging: _allowDragging,
        allowEditing: _allowEditing,
      ));
      _annotationController.addAnnotation(RangeAnnotation(
        id: 'optimal_zone',
        startX: 50,
        endX: 150,
        label: 'Optimal Window',
        fillColor: Colors.blue.withValues(alpha: 0.15),
        borderColor: Colors.blue.withValues(alpha: 0.5),
        allowDragging: _allowDragging,
        allowEditing: _allowEditing,
        snapToValue: _snapToValue,
      ));
    } else if (_selectedDemo == 1) {
      // Scientific demo: Temperature thresholds
      _annotationController.addAnnotation(ThresholdAnnotation(
        id: 'temp_cold',
        axis: AnnotationAxis.y,
        value: 15,
        label: 'Cold',
        lineColor: Colors.blue.withValues(alpha: 0.7),
        labelPosition: AnnotationLabelPosition.bottomLeft,
        allowDragging: _allowDragging,
        allowEditing: _allowEditing,
      ));
      _annotationController.addAnnotation(ThresholdAnnotation(
        id: 'temp_hot',
        axis: AnnotationAxis.y,
        value: 25,
        label: 'Hot',
        lineColor: Colors.orange.withValues(alpha: 0.7),
        labelPosition: AnnotationLabelPosition.topRight,
        allowDragging: _allowDragging,
        allowEditing: _allowEditing,
      ));
    } else if (_selectedDemo == 2) {
      // Test demo: Range highlight
      _annotationController.addAnnotation(RangeAnnotation(
        id: 'test_range',
        startX: 15,
        endX: 35,
        label: 'Test Window',
        fillColor: Colors.purple.withValues(alpha: 0.15),
        borderColor: Colors.purple.withValues(alpha: 0.5),
        allowDragging: _allowDragging,
        allowEditing: _allowEditing,
        snapToValue: _snapToValue,
      ));
    } else {
      // VO2 demo: VT1/VT2 thresholds
      _annotationController.addAnnotation(ThresholdAnnotation(
        id: 'vt1_threshold',
        axis: AnnotationAxis.x,
        value: 7.0,
        label: 'VT1',
        lineColor: Colors.green.withValues(alpha: 0.7),
        lineWidth: 1.5,
        elevation: 4.0, // Adds subtle glow in default state
        allowDragging: _allowDragging,
        allowEditing: _allowEditing,
      ));
      _annotationController.addAnnotation(ThresholdAnnotation(
        id: 'vt2_threshold',
        axis: AnnotationAxis.x,
        value: 12.5,
        label: 'VT2',
        lineColor: Colors.red.withValues(alpha: 0.7),
        allowDragging: _allowDragging,
        allowEditing: _allowEditing,
      ));
      _annotationController.addAnnotation(RangeAnnotation(
        id: 'exercise_zone',
        startX: 0.0,
        endX: 5.0,
        label: 'Warm-up',
        fillColor: Colors.grey.withValues(alpha: 0.2),
        labelPosition: AnnotationLabelPosition.bottomLeft,
        borderColor: Colors.red,
        allowDragging: _allowDragging,
        allowEditing: _allowEditing,
        snapToValue: _snapToValue,
      ));
    }
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
            options: const [0, 1, 2, 3],
            labelBuilder: (v) => v == 0
                ? 'Athletic'
                : v == 1
                    ? 'Scientific'
                    : v == 2
                        ? 'Test'
                        : 'VO2 Test',
            onChanged: (v) {
              setState(() => _selectedDemo = v);
              _rebuildAnnotations();
            },
          ),
          const SizedBox(height: 8),
          InfoBox(
            message: _selectedDemo == 0
                ? 'Power, Heart Rate, and Cadence on different scales'
                : _selectedDemo == 1
                    ? 'Temperature and Pressure with different units'
                    : _selectedDemo == 2
                        ? 'Test: Series 1 (0-100) vs Series 2 (250-1500) vs Series 3 (500-800)'
                        : 'VO2 Max Test: Stepped power targets with gas exchange metrics',
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

      // Annotation behavior settings
      OptionSection(
        title: 'Annotation Behavior',
        icon: Icons.touch_app,
        children: [
          BoolOption(
            label: 'Show Annotations',
            value: _showAnnotations,
            onChanged: (v) {
              setState(() => _showAnnotations = v);
              _rebuildAnnotations();
            },
            subtitle: 'Display annotations on chart',
          ),
          BoolOption(
            label: 'Interactive Annotations',
            value: _interactiveAnnotations,
            onChanged: (v) => setState(() => _interactiveAnnotations = v),
            subtitle: 'Enable all annotation interactions',
          ),
          BoolOption(
            label: 'Allow Dragging',
            value: _allowDragging,
            onChanged: (v) {
              setState(() => _allowDragging = v);
              _rebuildAnnotations();
            },
            subtitle: 'Drag to reposition annotations',
          ),
          BoolOption(
            label: 'Allow Editing',
            value: _allowEditing,
            onChanged: (v) {
              setState(() => _allowEditing = v);
              _rebuildAnnotations();
            },
            subtitle: 'Double-click to edit properties',
          ),
          BoolOption(
            label: 'Snap to Value',
            value: _snapToValue,
            onChanged: (v) {
              setState(() => _snapToValue = v);
              _rebuildAnnotations();
            },
            subtitle: 'Ranges snap to data values',
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
        } else if (_selectedDemo == 2) {
          return _buildTestChart();
        } else {
          return _buildVO2TestChart();
        }
      },
    );
  }

  Widget _buildAthleticChart() {
    return ChartCard(
      title: 'Athletic Performance',
      subtitle: 'Power (W), Heart Rate (bpm), Cadence (rpm)',
      child: BravenChartPlus(
        key: const ValueKey('athletic'), // Prevent RenderBox reuse across charts
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
            unit: 'W',
            yAxisConfig: YAxisConfig(
              id: 'power_axis',
              position: YAxisPosition.left,
              label: 'Power',
              unit: 'W',
              showAxisLine: true,
              showCrosshairLabel: true, // Show actual value on crosshair
            ),
          ),
          LineChartSeries(
            id: 'heart_rate',
            name: 'Heart Rate (bpm)',
            points: _heartRateData,
            color: Colors.red,
            interpolation: LineInterpolation.bezier,
            strokeWidth: 2.0,
            unit: 'bpm',
            yAxisConfig: YAxisConfig(
              id: 'hr_axis',
              position: YAxisPosition.right,
              label: 'Heart Rate',
              unit: 'bpm',
              showAxisLine: true,
              showCrosshairLabel: true, // Show actual value on crosshair
            ),
          ),
          LineChartSeries(
            id: 'cadence',
            name: 'Cadence (rpm)',
            points: _cadenceData,
            color: Colors.green,
            interpolation: LineInterpolation.bezier,
            strokeWidth: 2.0,
            unit: 'rpm',
            yAxisConfig: YAxisConfig(
              id: 'cadence_axis',
              position: YAxisPosition.leftOuter,
              label: 'Cadence',
              unit: 'rpm',
              visible: false, // Hide entire axis but keep series normalized
            ),
          ),
        ],
        normalizationMode: NormalizationMode.perSeries,
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
          crosshair: const CrosshairConfig(enabled: true),
          tooltip: const TooltipConfig(enabled: true),
        ),
        annotationController: _annotationController,
        interactiveAnnotations: _interactiveAnnotations,
      ),
    );
  }

  Widget _buildScientificChart() {
    return ChartCard(
      title: 'Environmental Monitoring',
      subtitle: 'Temperature (°C) and Pressure (hPa)',
      child: BravenChartPlus(
        key: const ValueKey('scientific'), // Prevent RenderBox reuse across charts
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
            unit: '°C',
            yAxisConfig: YAxisConfig(
              id: 'temp_axis',
              position: YAxisPosition.left,
              label: 'Temperature',
              unit: '°C',
              showAxisLine: true,
            ),
          ),
          LineChartSeries(
            id: 'pressure',
            name: 'Pressure (hPa)',
            points: _pressureData,
            color: Colors.purple,
            interpolation: LineInterpolation.linear,
            strokeWidth: 2.0,
            unit: 'hPa',
            yAxisConfig: YAxisConfig(
              id: 'pressure_axis',
              position: YAxisPosition.right,
              label: 'Pressure',
              unit: 'hPa',
              showAxisLine: true,
            ),
          ),
        ],
        normalizationMode: NormalizationMode.perSeries,
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
          crosshair: const CrosshairConfig(
            enabled: true,
            displayMode: CrosshairDisplayMode.tracking,
          ),
          tooltip: const TooltipConfig(
            enabled: true,
          ),
        ),
        annotationController: _annotationController,
        interactiveAnnotations: _interactiveAnnotations,
      ),
    );
  }

  Widget _buildTestChart() {
    return ChartCard(
      title: 'Multi-Axis Test',
      subtitle: 'Series 1: 0-100  |  Series 2: 250-1500  |  Series 3: 500-800',
      child: BravenChartPlus(
        key: const ValueKey('test'), // Prevent RenderBox reuse across charts
        chartType: ChartType.line,
        lineStyle: LineStyle.smooth,
        series: [
          // NEW API: Inline yAxisConfig directly on series
          LineChartSeries(
            id: 'small_range',
            name: 'Small Range (0-100)',
            points: _testSmallRangeData,
            color: Colors.blue,
            interpolation: LineInterpolation.linear,
            strokeWidth: 2.0,
            unit: "RPM",
            // Inline axis configuration - no separate yAxes/axisBindings needed!
            yAxisConfig: YAxisConfig(
              id: 'small_axis',
              position: YAxisPosition.left,
              label: 'Small',
              axisMargin: 5,
              axisLabelPadding: 5,
              tickLabelPadding: 0,
              minWidth: 0,
              showAxisLine: true,
              showCrosshairLabel: true, // Show actual value on crosshair
              unit: 'RPM',
              labelDisplay: AxisLabelDisplay.labelWithUnit,
              labelFormatter: (value) => value.toStringAsFixed(2),
            ),
          ),
          LineChartSeries(
            id: 'large_range',
            name: 'Large Range (250-1500)',
            points: _testLargeRangeData,
            color: Colors.red,
            interpolation: LineInterpolation.linear,
            strokeWidth: 2.0,
            unit: "Watts(W)",
            yAxisConfig: YAxisConfig(
              id: 'large_axis',
              position: YAxisPosition.leftOuter,
              label: 'Large',
              showAxisLine: true,
              showCrosshairLabel: true, // Show actual value on crosshair
              unit: 'W',
              labelDisplay: AxisLabelDisplay.labelWithUnit,
            ),
          ),
          LineChartSeries(
            id: 'medium_range',
            name: 'Medium Range (500-800)',
            points: _testMediumRangeData,
            color: Colors.green,
            interpolation: LineInterpolation.linear,
            strokeWidth: 2.0,
            unit: "BPM",
            yAxisConfig: YAxisConfig(
              id: 'medium_axis',
              position: YAxisPosition.right,
              label: 'Medium',
              showAxisLine: true,
              showCrosshairLabel: true, // Show actual value on crosshair
              unit: 'BPM',
              labelDisplay: AxisLabelDisplay.tickOnly,
            ),
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
        ),
        yAxis: AxisConfig(
          showGrid: _optionsController.showGrid,
          showAxis: _optionsController.showAxisLines,
          label: "Y-axis",
        ),
        // No yAxes or axisBindings needed - all defined inline on series!
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
        annotationController: _annotationController,
        interactiveAnnotations: _interactiveAnnotations,
      ),
    );
  }

  /// Builds the VO2 Max Test chart - demonstrates stepped area with line overlays.
  ///
  /// This replicates a typical cardiopulmonary exercise test (CPET) display:
  /// - Stepped target power zones (gray area) - Warm-Up, VT1, Test, VT2, VO2 max
  /// - FeO2% line (magenta) - Fraction of expired O2
  /// - EqO2 line (blue) - Ventilatory equivalent for O2
  Widget _buildVO2TestChart() {
    return ChartCard(
      title: 'VO2 Max Test - Gas Exchange',
      subtitle: 'Target Power Zones with FeO2% and EqO2 metrics',
      child: BravenChartPlus(
        annotationController: _annotationController,
        interactiveAnnotations: _interactiveAnnotations,
        key: const ValueKey('vo2_test'),
        chartType: ChartType.line, // Series types define actual rendering
        series: [
          // Stepped target power zones (area chart - painted first/behind)
          AreaChartSeries(
            id: 'target_power',
            name: 'Target[W]',
            points: _targetPowerData,
            color: const Color(0xFF9E9E9E), // Gray
            interpolation: LineInterpolation.linear,
            strokeWidth: 0.1,
            fillOpacity: 0.075,
            yAxisConfig: YAxisConfig(
              id: 'power_axis',
              position: YAxisPosition.right,
              label: 'Target',
              unit: 'W',
              showAxisLine: true,
              labelDisplay: AxisLabelDisplay.labelAndTickUnit,
              showCrosshairLabel: true,
              axisMargin: 0,
              min: 0,
              max: 350,
            ),
          ),
          // FeO2% line (magenta)
          LineChartSeries(
            id: 'feo2',
            name: 'FeO2[%]',
            points: _feO2Data,
            color: const Color(0xFFE040FB), // Magenta/Purple-pink
            interpolation: LineInterpolation.linear,
            strokeWidth: 1.5,
            unit: '%',
            yAxisConfig: YAxisConfig(
              id: 'feo2_axis',
              position: YAxisPosition.rightOuter,
              label: 'FeO2',
              unit: '%',
              showAxisLine: true,
              showCrosshairLabel: true,
              labelDisplay: AxisLabelDisplay.tickOnly,
              // min: 14,
              // max: 19,
            ),
          ),
          // EqO2 line (blue)
          LineChartSeries(
            id: 'eqo2',
            name: 'EqO2',
            points: _eqO2Data,
            color: const Color(0xFF42A5F5), // Blue
            interpolation: LineInterpolation.linear,
            strokeWidth: 1.5,
            unit: '',
            yAxisConfig: YAxisConfig(
              id: 'eqo2_axis',
              position: YAxisPosition.left,
              label: 'Gas Exchange',
              unit: '',
              showAxisLine: true,
              showCrosshairLabel: true,
              labelDisplay: AxisLabelDisplay.labelOnly,
              // min: 0,
              // max: 60,
            ),
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
          label: '',
        ),
        yAxis: AxisConfig(
          showGrid: _optionsController.showGrid,
          showAxis: _optionsController.showAxisLines,
        ),
        normalizationMode: NormalizationMode.perSeries,
        interactionConfig: InteractionConfig(
          enableZoom: _optionsController.enableZoom,
          enablePan: _optionsController.enablePan,
          crosshair: const CrosshairConfig(
            enabled: true,
            displayMode: CrosshairDisplayMode.tracking,
          ),
          tooltip: const TooltipConfig(enabled: true),
        ),
      ),
    );
  }

  Widget _buildStatusPanel() {
    final annotationCount = _annotationController.annotations.length;
    final annotationStatus = _showAnnotations ? '$annotationCount visible' : '$annotationCount hidden';

    if (_selectedDemo == 0) {
      return StatusPanel(
        items: [
          StatusItem(label: 'Power Pts', value: '${_powerData.length}'),
          StatusItem(label: 'HR Pts', value: '${_heartRateData.length}'),
          StatusItem(label: 'Cadence Pts', value: '${_cadenceData.length}'),
          const StatusItem(label: 'Axes', value: '3', color: Colors.blue),
          StatusItem(
            label: 'Annotations',
            value: annotationStatus,
            color: _interactiveAnnotations ? Colors.green : Colors.grey,
          ),
        ],
      );
    } else if (_selectedDemo == 1) {
      return StatusPanel(
        items: [
          StatusItem(label: 'Temp Pts', value: '${_temperatureData.length}'),
          StatusItem(label: 'Pressure Pts', value: '${_pressureData.length}'),
          const StatusItem(label: 'Axes', value: '2', color: Colors.blue),
          StatusItem(
            label: 'Annotations',
            value: annotationStatus,
            color: _interactiveAnnotations ? Colors.green : Colors.grey,
          ),
        ],
      );
    } else if (_selectedDemo == 2) {
      return StatusPanel(
        items: [
          const StatusItem(label: 'Small Range', value: '0-100'),
          const StatusItem(label: 'Large Range', value: '250-1500'),
          const StatusItem(label: 'Medium Range', value: '500-800'),
          StatusItem(label: 'Points', value: '${_testSmallRangeData.length}'),
          const StatusItem(label: 'Axes', value: '3', color: Colors.orange),
          StatusItem(
            label: 'Annotations',
            value: annotationStatus,
            color: _interactiveAnnotations ? Colors.green : Colors.grey,
          ),
        ],
      );
    } else {
      return StatusPanel(
        items: [
          StatusItem(label: 'Target Pts', value: '${_targetPowerData.length}'),
          StatusItem(label: 'FeO2 Pts', value: '${_feO2Data.length}'),
          StatusItem(label: 'EqO2 Pts', value: '${_eqO2Data.length}'),
          const StatusItem(label: 'Axes', value: '3', color: Colors.purple),
          StatusItem(
            label: 'Annotations',
            value: annotationStatus,
            color: _interactiveAnnotations ? Colors.green : Colors.grey,
          ),
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

  // ============================================================
  // VO2 Max Test Data Generators
  // ============================================================

  /// Generates stepped target power data simulating a VO2 max test protocol.
  ///
  /// Uses zone boundary points for clean stepped visualization.
  /// The stepped interpolation automatically draws horizontal-then-vertical steps.
  /// Only need one point per zone transition - the step handles the jump.
  ///
  /// Protocol phases (time in minutes):
  /// - 0:00-5:00: Warm-Up (~75W)
  /// - 5:00-7:00: VT1 Zone (~100W)
  /// - 7:00-10:00: Test Zone (~150W stepping to 200W)
  /// - 10:00-12:30: VT2 Zone (~250W)
  /// - 12:30-15:00: VO2 Max Zone (~300W stepping to 350W)
  List<ChartDataPoint> _generateTargetPowerData() {
    // Stepped interpolation: for each point, draws horizontal to X, then vertical to Y
    // So we only need the END of each zone (step will draw horizontal line)
    return const [
      ChartDataPoint(x: 0.0, y: 75), // Start at warm-up level
      ChartDataPoint(x: 5.0, y: 75), // Start at warm-up level
      ChartDataPoint(x: 5.0, y: 100), // Jump to VT1 at minute 5
      ChartDataPoint(x: 5.0, y: 150), // Jump to VT1 at minute 5
      ChartDataPoint(x: 7.0, y: 150), // Jump to test phase 1 at minute 7
      ChartDataPoint(x: 7.0, y: 200), // Jump to test phase 1 at minute 7
      ChartDataPoint(x: 8.5, y: 200), // Jump to test phase 2 at minute 8.5
      ChartDataPoint(x: 8.5, y: 250), // Jump to test phase 2 at minute 8.5
      ChartDataPoint(x: 10.0, y: 250), // Jump to VT2 phase 1 at minute 10
      ChartDataPoint(x: 10.0, y: 275), // Jump to VT2 phase 1 at minute 10
      ChartDataPoint(x: 11.25, y: 275), // Jump to VT2 phase 2 at minute 11.25
      ChartDataPoint(x: 11.25, y: 300), // Jump to VT2 phase 2 at minute 11.25
      ChartDataPoint(x: 12.5, y: 300), // Jump to VO2 max phase 1 at minute 12.5
      ChartDataPoint(x: 12.5, y: 325), // Jump to VO2 max phase 1 at minute 12.5
      ChartDataPoint(x: 13.75, y: 325), // Jump to VO2 max phase 2 at minute 13.75

      ChartDataPoint(x: 15.0, y: 325), // End point (maintains last level)
    ];
  }

  /// Generates FeO2% data (Fraction of Expired O2) for VO2 max test.
  ///
  /// FeO2 typically:
  /// - Starts around 16-17% at rest/warm-up
  /// - Drops to ~15-15.5% during moderate exercise
  /// - Can drop to ~14-14.5% at VO2 max
  /// - Shows a characteristic "hockey stick" pattern near VO2 max
  List<ChartDataPoint> _generateFeO2Data() {
    final points = <ChartDataPoint>[];
    const totalMinutes = 15.0;
    const samplesPerMinute = 12;

    for (var i = 0; i <= totalMinutes * samplesPerMinute; i++) {
      final minutes = i / samplesPerMinute;

      // Simulate FeO2 response to exercise
      double feo2;
      if (minutes < 5.0) {
        // Warm-up: gradual decrease from 16.8 to 16.2
        feo2 = 16.8 - (minutes / 5.0) * 0.6;
      } else if (minutes < 7.0) {
        // VT1: decrease to ~15.8
        feo2 = 16.2 - ((minutes - 5.0) / 2.0) * 0.4;
      } else if (minutes < 10.0) {
        // Test: decrease to ~15.4
        feo2 = 15.8 - ((minutes - 7.0) / 3.0) * 0.4;
      } else if (minutes < 12.5) {
        // VT2: sharp decrease to ~15.0
        feo2 = 15.4 - ((minutes - 10.0) / 2.5) * 0.4;
      } else {
        // VO2 max: plateau/slight increase (exhaustion)
        feo2 = 15.0 + ((minutes - 12.5) / 2.5) * 0.3;
      }

      // Add noise
      feo2 += (_random.nextDouble() - 0.5) * 0.15;
      feo2 = feo2.clamp(14.0, 19.0);

      points.add(ChartDataPoint(x: minutes, y: feo2));
    }
    return points;
  }

  /// Generates EqO2 data (Ventilatory Equivalent for O2) for VO2 max test.
  ///
  /// EqO2 typically:
  /// - Starts around 25-30 at rest
  /// - Decreases initially as exercise efficiency improves
  /// - Reaches minimum (~20-22) around VT1
  /// - Increases progressively after VT1
  /// - Sharp increase near VO2 max (can reach 40-50+)
  List<ChartDataPoint> _generateEqO2Data() {
    final points = <ChartDataPoint>[];
    const totalMinutes = 15.0;
    const samplesPerMinute = 12;

    for (var i = 0; i <= totalMinutes * samplesPerMinute; i++) {
      final minutes = i / samplesPerMinute;

      // Simulate EqO2 response to exercise
      double eqo2;
      if (minutes < 2.0) {
        // Initial warm-up: starts high, decreasing
        eqo2 = 32 - (minutes / 2.0) * 4;
      } else if (minutes < 5.0) {
        // Rest of warm-up: continues decreasing
        eqo2 = 28 - ((minutes - 2.0) / 3.0) * 5;
      } else if (minutes < 7.0) {
        // VT1: minimum reached (~21-22)
        eqo2 = 23 - ((minutes - 5.0) / 2.0) * 2;
      } else if (minutes < 10.0) {
        // Test: gradual increase
        eqo2 = 21 + ((minutes - 7.0) / 3.0) * 4;
      } else if (minutes < 12.5) {
        // VT2: steeper increase
        eqo2 = 25 + ((minutes - 10.0) / 2.5) * 8;
      } else {
        // VO2 max: sharp exponential-like increase
        final progress = (minutes - 12.5) / 2.5;
        eqo2 = 33 + progress * progress * 15;
      }

      // Add noise
      eqo2 += (_random.nextDouble() - 0.5) * 1.5;
      eqo2 = eqo2.clamp(18.0, 55.0);

      points.add(ChartDataPoint(x: minutes, y: eqo2));
    }
    return points;
  }
}
