// Copyright 2025 Braven Charts - Scientific Data Visualization Example
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/src_plus/axis/axis_config.dart';
import 'package:braven_charts/src_plus/axis/y_axis_config.dart';
import 'package:braven_charts/src_plus/controllers/annotation_controller.dart';
import 'package:braven_charts/src_plus/models/chart_annotation.dart';
import 'package:braven_charts/src_plus/models/chart_data_point.dart';
import 'package:braven_charts/src_plus/models/chart_series.dart';
import 'package:braven_charts/src_plus/models/chart_theme.dart';
import 'package:braven_charts/src_plus/models/chart_type.dart';
import 'package:braven_charts/src_plus/models/enums.dart';
import 'package:braven_charts/src_plus/models/interaction_config.dart';
import 'package:braven_charts/src_plus/models/normalization_mode.dart';
import 'package:braven_charts/src_plus/models/y_axis_position.dart';
import 'package:braven_charts/src_plus/widgets/braven_chart_plus.dart';
import 'package:flutter/material.dart';

/// Demonstrates high-density scientific/athletic performance data visualization.
class ScientificDataPage extends StatefulWidget {
  const ScientificDataPage({super.key});

  @override
  State<ScientificDataPage> createState() => _ScientificDataPageState();
}

class _ScientificDataPageState extends State<ScientificDataPage> {
  bool _showRawData = true;
  bool _selectionMode = false;
  bool _multiAxisMode = false;
  bool _autoDetectMode = false; // New: Auto-detection mode toggle
  bool _derivedColors = false; // New: Derived colors mode (axis colors from series)
  String _selectedTheme = 'Light';
  LineStyle _lineStyle = LineStyle.straight;
  final AnnotationController _annotationController = AnnotationController();

  @override
  void initState() {
    super.initState();
    _generateAnnotations();
  }

  @override
  void dispose() {
    _annotationController.dispose();
    super.dispose();
  }

  /// Generate realistic power data similar to cycling/running metrics
  List<ChartDataPoint> _generatePowerData() {
    final random = math.Random(42);
    final points = <ChartDataPoint>[];

    // Simulate ~23 hours of data with 1-minute intervals (1380 points)
    const totalMinutes = 1380;

    for (int i = 0; i < totalMinutes; i++) {
      final x = i / 60.0; // Convert to hours
      double basePower = 140.0;

      if (i < 120) {
        basePower = 180.0 + random.nextDouble() * 40;
      } else if (i < 240) {
        basePower = 160.0 + random.nextDouble() * 30;
      } else if (i < 480) {
        basePower = 170.0 + random.nextDouble() * 25;
      } else if (i < 720) {
        final phase = (i % 60) / 60.0;
        basePower = phase < 0.3 ? 200.0 + random.nextDouble() * 30 : 140.0 + random.nextDouble() * 20;
      } else if (i < 960) {
        basePower = 150.0 + random.nextDouble() * 30;
      } else if (i < 1200) {
        basePower = 130.0 + random.nextDouble() * 25;
      } else {
        basePower = 100.0 + random.nextDouble() * 30;
      }

      final noise = (random.nextDouble() - 0.5) * 15;
      final spike = random.nextDouble() < 0.02 ? random.nextDouble() * 30 : 0;
      final y = (basePower + noise + spike).clamp(60.0, 240.0);
      points.add(ChartDataPoint(x: x, y: y));
    }

    return points;
  }

  List<ChartDataPoint> _generateSmoothedData(List<ChartDataPoint> rawData) {
    final smoothed = <ChartDataPoint>[];
    const windowSize = 10;

    for (int i = 0; i < rawData.length; i++) {
      final start = math.max(0, i - windowSize ~/ 2);
      final end = math.min(rawData.length, i + windowSize ~/ 2 + 1);
      double sum = 0;
      for (int j = start; j < end; j++) {
        sum += rawData[j].y;
      }
      smoothed.add(ChartDataPoint(x: rawData[i].x, y: sum / (end - start)));
    }

    return smoothed;
  }

  /// Generate heart rate data correlated with power but on different scale (60-180 bpm)
  List<ChartDataPoint> _generateHeartRateData() {
    final random = math.Random(43); // Different seed for variety
    final points = <ChartDataPoint>[];

    // Simulate ~23 hours of data with 1-minute intervals (1380 points)
    const totalMinutes = 1380;

    for (int i = 0; i < totalMinutes; i++) {
      final x = i / 60.0; // Convert to hours
      double baseHR = 100.0; // Resting + activity baseline

      // HR correlates with power phases but with physiological lag
      if (i < 120) {
        // Warm-up: HR ramps up
        baseHR = 110.0 + (i / 120.0) * 30 + random.nextDouble() * 10;
      } else if (i < 240) {
        // Moderate effort
        baseHR = 135.0 + random.nextDouble() * 15;
      } else if (i < 480) {
        // Steady state
        baseHR = 145.0 + random.nextDouble() * 10;
      } else if (i < 720) {
        // Intervals (HR spikes during high power)
        final phase = (i % 60) / 60.0;
        baseHR = phase < 0.3
            ? 165.0 + random.nextDouble() * 15 // High intensity
            : 125.0 + random.nextDouble() * 10; // Recovery
      } else if (i < 960) {
        // Moderate fatigue
        baseHR = 140.0 + random.nextDouble() * 12;
      } else if (i < 1200) {
        // Decreasing effort
        baseHR = 125.0 + random.nextDouble() * 10;
      } else {
        // Cool down
        baseHR = 100.0 + (1380 - i) / 180.0 * 20 + random.nextDouble() * 8;
      }

      // Add realistic HR variability
      final hrv = (random.nextDouble() - 0.5) * 6;
      final y = (baseHR + hrv).clamp(60.0, 185.0);
      points.add(ChartDataPoint(x: x, y: y));
    }

    return points;
  }

  /// Generate cadence data (pedaling rate 60-120 rpm)
  List<ChartDataPoint> _generateCadenceData() {
    final random = math.Random(44);
    final points = <ChartDataPoint>[];

    const totalMinutes = 1380;

    for (int i = 0; i < totalMinutes; i++) {
      final x = i / 60.0;
      double baseCadence = 85.0; // Typical cycling cadence

      if (i < 120) {
        baseCadence = 75.0 + random.nextDouble() * 15;
      } else if (i < 720) {
        // Intervals affect cadence
        final phase = (i % 60) / 60.0;
        baseCadence = phase < 0.3 ? 95.0 + random.nextDouble() * 15 : 80.0 + random.nextDouble() * 10;
      } else {
        baseCadence = 82.0 + random.nextDouble() * 12;
      }

      final noise = (random.nextDouble() - 0.5) * 8;
      final y = (baseCadence + noise).clamp(50.0, 120.0);
      points.add(ChartDataPoint(x: x, y: y));
    }

    return points;
  }

  void _generateAnnotations() {
    final annotations = <ChartAnnotation>[
      ThresholdAnnotation(
        axis: AnnotationAxis.y,
        value: 190,
        label: 'FTP Threshold',
        lineColor: Colors.red.withValues(alpha: 0.5),
        lineWidth: 2.0,
        dashPattern: [8, 4],
      ),
    ];

    for (int lap = 0; lap < 11; lap++) {
      annotations.add(
        RangeAnnotation(
          startX: lap * 2.0,
          endX: lap * 2.0 + 1.8,
          startY: 60,
          endY: 240,
          fillColor: lap.isEven ? Colors.grey.withValues(alpha: 0.1) : Colors.transparent,
          borderColor: Colors.transparent,
          label: lap.isEven ? 'Lap ${lap ~/ 2 + 1}' : null,
        ),
      );
    }

    _annotationController.addAll(annotations);
  }

  @override
  Widget build(BuildContext context) {
    final rawData = _generatePowerData();
    final smoothedData = _generateSmoothedData(rawData);
    final heartRateData = _generateHeartRateData();
    final cadenceData = _generateCadenceData();

    final ChartTheme theme = switch (_selectedTheme) {
      'Dark' => ChartTheme.dark,
      'High Contrast' => ChartTheme.highContrast,
      _ => ChartTheme.light,
    };

    final isDark = _selectedTheme == 'Dark';

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? Colors.grey[850] : Colors.white,
            child: Row(
              children: [
                Text(
                  _multiAxisMode ? 'Multi-Axis View' : 'Power Data',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(width: 24),
                if (!_multiAxisMode) ...[
                  _buildToggleButton(label: 'Raw', isSelected: _showRawData, onTap: () => setState(() => _showRawData = true)),
                  const SizedBox(width: 8),
                  _buildToggleButton(label: 'Lap', isSelected: !_showRawData, onTap: () => setState(() => _showRawData = false)),
                  const SizedBox(width: 24),
                ],
                Text('Theme:', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedTheme,
                  dropdownColor: isDark ? Colors.grey[800] : null,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  items: const [
                    DropdownMenuItem(value: 'Light', child: Text('Light')),
                    DropdownMenuItem(value: 'Dark', child: Text('Dark')),
                    DropdownMenuItem(value: 'High Contrast', child: Text('High Contrast')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedTheme = value);
                    }
                  },
                ),
                const SizedBox(width: 24),
                Text('Style:', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                const SizedBox(width: 8),
                DropdownButton<LineStyle>(
                  value: _lineStyle,
                  dropdownColor: isDark ? Colors.grey[800] : null,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  items: const [
                    DropdownMenuItem(value: LineStyle.straight, child: Text('Straight')),
                    DropdownMenuItem(value: LineStyle.smooth, child: Text('Smooth')),
                    DropdownMenuItem(value: LineStyle.stepped, child: Text('Stepped')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _lineStyle = value);
                    }
                  },
                ),
                const Spacer(),
                // Auto-detect toggle (new)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _autoDetectMode ? Colors.purple[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _autoDetectMode ? Colors.purple : Colors.grey[400]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_fix_high,
                        size: 16,
                        color: _autoDetectMode ? Colors.purple[700] : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Auto-Detect',
                        style: TextStyle(
                          color: _autoDetectMode ? Colors.purple[700] : Colors.grey[600],
                          fontWeight: _autoDetectMode ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: _autoDetectMode,
                        onChanged: (value) => setState(() {
                          _autoDetectMode = value;
                          if (value) _multiAxisMode = false; // Disable explicit multi-axis when auto-detect is on
                        }),
                        activeThumbColor: Colors.purple,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Multi-axis toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _multiAxisMode ? Colors.green[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _multiAxisMode ? Colors.green : Colors.grey[400]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stacked_line_chart,
                        size: 16,
                        color: _multiAxisMode ? Colors.green[700] : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Multi-Axis',
                        style: TextStyle(
                          color: _multiAxisMode ? Colors.green[700] : Colors.grey[600],
                          fontWeight: _multiAxisMode ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: _multiAxisMode,
                        onChanged: (value) => setState(() {
                          _multiAxisMode = value;
                          if (value) _autoDetectMode = false; // Disable auto-detect when explicit multi-axis is on
                        }),
                        activeThumbColor: Colors.green,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Derived Colors toggle (only visible when multi-axis is on)
                if (_multiAxisMode)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _derivedColors ? Colors.amber[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _derivedColors ? Colors.amber : Colors.grey[400]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.palette,
                          size: 16,
                          color: _derivedColors ? Colors.amber[700] : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Derived Colors',
                          style: TextStyle(
                            color: _derivedColors ? Colors.amber[700] : Colors.grey[600],
                            fontWeight: _derivedColors ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Switch(
                          value: _derivedColors,
                          onChanged: (value) => setState(() => _derivedColors = value),
                          activeThumbColor: Colors.amber,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                Text('Selection mode', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                const SizedBox(width: 8),
                Switch(value: _selectionMode, onChanged: (value) => setState(() => _selectionMode = value)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _autoDetectMode
                  ? _buildAutoDetectChart(smoothedData, heartRateData, cadenceData, theme, isDark)
                  : _multiAxisMode
                      ? _buildMultiAxisChart(smoothedData, heartRateData, cadenceData, theme, isDark)
                      : _buildSingleAxisChart(rawData, smoothedData, theme),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? Colors.grey[850] : Colors.white,
            child: (_multiAxisMode || _autoDetectMode)
                ? _buildMultiAxisStatsPanel(smoothedData, heartRateData, cadenceData, isDark)
                : _buildStatsPanel(rawData, smoothedData, isDark),
          ),
        ],
      ),
    );
  }

  /// Builds the original single-axis chart
  Widget _buildSingleAxisChart(
    List<ChartDataPoint> rawData,
    List<ChartDataPoint> smoothedData,
    ChartTheme theme,
  ) {
    return BravenChartPlus(
      chartType: ChartType.line,
      lineStyle: _lineStyle,
      series: [
        if (_showRawData)
          LineChartSeries(
            id: 'raw-power',
            name: 'Raw Power',
            points: rawData,
            color: Colors.blue[400]!,
            strokeWidth: 1.5,
            showDataPointMarkers: false,
            dataPointMarkerRadius: 4,
          ),
        LineChartSeries(
          id: 'smoothed-power',
          name: 'Smoothed',
          points: smoothedData,
          color: Colors.orange[700]!,
          strokeWidth: 2.5,
          showDataPointMarkers: false,
        ),
      ],
      xAxis: const AxisConfig(
        orientation: AxisOrientation.horizontal,
        position: AxisPosition.bottom,
        label: 'Time (hours)',
        showGrid: true,
        showAxisLine: true,
      ),
      yAxis: const AxisConfig(
        orientation: AxisOrientation.vertical,
        position: AxisPosition.left,
        label: 'Watts',
        showGrid: true,
        showAxisLine: true,
      ),
      theme: theme,
      annotationController: _annotationController,
      interactiveAnnotations: true,
      interactionConfig: const InteractionConfig(
        crosshair: CrosshairConfig(
          showCoordinateLabels: true,
          displayMode: CrosshairDisplayMode.auto,
          trackingModeThreshold: 250,
          mode: CrosshairMode.vertical,
          interpolateValues: true,
          showTrackingTooltip: true,
          showIntersectionMarkers: true,
        ),
      ),
    );
  }

  /// Builds the multi-axis chart showing Power (100-250W), Heart Rate (60-180 bpm),
  /// and Cadence (50-120 rpm) - each with its own Y-axis.
  ///
  /// When [_derivedColors] is true, axis colors are automatically derived from
  /// their bound series colors (no explicit color in YAxisConfig).
  /// When [_derivedColors] is false, explicit colors are set on each axis.
  Widget _buildMultiAxisChart(
    List<ChartDataPoint> powerData,
    List<ChartDataPoint> heartRateData,
    List<ChartDataPoint> cadenceData,
    ChartTheme theme,
    bool isDark,
  ) {
    // Series colors - these are the source of truth for derived mode
    final powerColor = Colors.blue[600]!;
    final hrColor = Colors.red[600]!;
    final cadenceColor = Colors.green[600]!;

    return BravenChartPlus(
      chartType: ChartType.line,
      lineStyle: _lineStyle,
      series: [
        // Power: ~100-250W range - bound to 'power' axis (left)
        LineChartSeries(
          id: 'power',
          name: 'Power',
          points: powerData,
          color: powerColor,
          strokeWidth: 2.0,
          showDataPointMarkers: false,
          yAxisId: 'power',
          unit: 'W',
        ),
        // Heart Rate: ~60-185 bpm range - bound to 'hr' axis (right)
        LineChartSeries(
          id: 'heart-rate',
          name: 'Heart Rate',
          points: heartRateData,
          color: hrColor,
          strokeWidth: 2.0,
          showDataPointMarkers: false,
          yAxisId: 'hr',
          unit: 'bpm',
        ),
        // Cadence: ~50-120 rpm range - bound to 'cadence' axis (leftOuter)
        LineChartSeries(
          id: 'cadence',
          name: 'Cadence',
          points: cadenceData,
          color: cadenceColor,
          strokeWidth: 1.5,
          showDataPointMarkers: false,
          yAxisId: 'cadence',
          unit: 'rpm',
        ),
      ],
      // Configure multiple Y-axes
      // When _derivedColors is true, we omit explicit colors and let
      // the AxisColorResolver derive them from the bound series.
      yAxes: _derivedColors
          ? const [
              // No explicit colors - derived from series
              YAxisConfig(
                id: 'power',
                position: YAxisPosition.left,
                label: 'Power (W)',
                // color omitted - will be derived from 'power' series (blue)
              ),
              YAxisConfig(
                id: 'hr',
                position: YAxisPosition.right,
                label: 'Heart Rate (bpm)',
                // color omitted - will be derived from 'heart-rate' series (red)
              ),
              YAxisConfig(
                id: 'cadence',
                position: YAxisPosition.leftOuter,
                label: 'Cadence (rpm)',
                // color omitted - will be derived from 'cadence' series (green)
              ),
            ]
          : [
              // Explicit colors - same as series for visual consistency
              YAxisConfig(
                id: 'power',
                position: YAxisPosition.left,
                label: 'Power (W)',
                color: powerColor,
              ),
              YAxisConfig(
                id: 'hr',
                position: YAxisPosition.right,
                label: 'Heart Rate (bpm)',
                color: hrColor,
              ),
              YAxisConfig(
                id: 'cadence',
                position: YAxisPosition.leftOuter,
                label: 'Cadence (rpm)',
                color: cadenceColor,
              ),
            ],
      // Use per-series normalization for multi-scale data
      normalizationMode: NormalizationMode.perSeries,
      xAxis: const AxisConfig(
        orientation: AxisOrientation.horizontal,
        position: AxisPosition.bottom,
        label: 'Time (hours)',
        showGrid: true,
        showAxisLine: true,
      ),
      // Primary Y-axis (required, but yAxes take precedence in multi-axis mode)
      yAxis: const AxisConfig(
        orientation: AxisOrientation.vertical,
        position: AxisPosition.left,
        label: 'Power (W)',
        showGrid: false, // Grid disabled in multi-axis mode
        showAxisLine: true,
      ),
      theme: theme,
      interactionConfig: const InteractionConfig(
        crosshair: CrosshairConfig(
          showCoordinateLabels: true,
          displayMode: CrosshairDisplayMode.auto,
          trackingModeThreshold: 250,
          mode: CrosshairMode.vertical,
          interpolateValues: true,
          showTrackingTooltip: true,
          showIntersectionMarkers: true,
        ),
      ),
    );
  }

  /// Builds a chart using NormalizationMode.auto to demonstrate auto-detection.
  ///
  /// The system automatically detects when series have vastly different ranges
  /// and enables multi-axis mode without explicit yAxes configuration.
  ///
  /// Power (~100-250W) vs Heart Rate (~60-185 bpm) vs Cadence (~50-120 rpm)
  /// have similar magnitude ranges (<10x ratio) so won't trigger auto-mode.
  ///
  /// To demonstrate auto-detection, we add a micro-scale series (0.001-0.005)
  /// which creates a >10x ratio and triggers auto-normalization.
  Widget _buildAutoDetectChart(
    List<ChartDataPoint> powerData,
    List<ChartDataPoint> heartRateData,
    List<ChartDataPoint> cadenceData,
    ChartTheme theme,
    bool isDark,
  ) {
    // Create a micro-scale series to trigger auto-detection (simulating micro-volts)
    final microData = List.generate(
      powerData.length,
      (i) => ChartDataPoint(
        x: powerData[i].x,
        y: 0.001 + (i % 100) * 0.00004, // 0.001 to 0.005 range
      ),
    );

    return BravenChartPlus(
      chartType: ChartType.line,
      lineStyle: _lineStyle,
      series: [
        // Power: ~100-250W range
        LineChartSeries(
          id: 'power',
          name: 'Power',
          points: powerData,
          color: Colors.blue[600]!,
          strokeWidth: 2.0,
          showDataPointMarkers: false,
          unit: 'W',
        ),
        // Heart Rate: ~60-185 bpm range
        LineChartSeries(
          id: 'heart-rate',
          name: 'Heart Rate',
          points: heartRateData,
          color: Colors.red[600]!,
          strokeWidth: 2.0,
          showDataPointMarkers: false,
          unit: 'bpm',
        ),
        // Micro-scale: ~0.001-0.005 range (simulating micro-volts)
        // This creates a >10x ratio with Power, triggering auto-detection
        LineChartSeries(
          id: 'micro',
          name: 'Micro Scale',
          points: microData,
          color: Colors.orange[600]!,
          strokeWidth: 1.5,
          showDataPointMarkers: false,
          unit: 'µV',
        ),
      ],
      // NO yAxes provided - let auto-detection handle it!
      // The system will detect that Power (150 span) vs Micro (0.004 span)
      // has a ~37,500x ratio, which exceeds the 10x threshold.
      normalizationMode: NormalizationMode.auto,
      xAxis: const AxisConfig(
        orientation: AxisOrientation.horizontal,
        position: AxisPosition.bottom,
        label: 'Time (hours)',
        showGrid: true,
        showAxisLine: true,
      ),
      yAxis: const AxisConfig(
        orientation: AxisOrientation.vertical,
        position: AxisPosition.left,
        label: 'Auto-Detected Axes',
        showGrid: true,
        showAxisLine: true,
      ),
      theme: theme,
      interactionConfig: const InteractionConfig(
        crosshair: CrosshairConfig(
          showCoordinateLabels: true,
          displayMode: CrosshairDisplayMode.auto,
          trackingModeThreshold: 250,
          mode: CrosshairMode.vertical,
          interpolateValues: true,
          showTrackingTooltip: true,
          showIntersectionMarkers: true,
        ),
      ),
    );
  }

  /// Stats panel for multi-axis mode showing all three metrics
  Widget _buildMultiAxisStatsPanel(
    List<ChartDataPoint> power,
    List<ChartDataPoint> hr,
    List<ChartDataPoint> cadence,
    bool isDark,
  ) {
    final avgPower = power.map((p) => p.y).reduce((a, b) => a + b) / power.length;
    final avgHR = hr.map((p) => p.y).reduce((a, b) => a + b) / hr.length;
    final avgCadence = cadence.map((p) => p.y).reduce((a, b) => a + b) / cadence.length;
    final maxPower = power.map((p) => p.y).reduce(math.max);
    final maxHR = hr.map((p) => p.y).reduce(math.max);
    final maxCadence = cadence.map((p) => p.y).reduce(math.max);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildColoredStatItem('Avg Power', '${avgPower.toInt()}W', Colors.blue[600]!, isDark),
            _buildColoredStatItem('Max Power', '${maxPower.toInt()}W', Colors.blue[400]!, isDark),
            _buildColoredStatItem('Avg HR', '${avgHR.toInt()} bpm', Colors.red[600]!, isDark),
            _buildColoredStatItem('Max HR', '${maxHR.toInt()} bpm', Colors.red[400]!, isDark),
            _buildColoredStatItem('Avg Cadence', '${avgCadence.toInt()} rpm', Colors.green[600]!, isDark),
            _buildColoredStatItem('Max Cadence', '${maxCadence.toInt()} rpm', Colors.green[400]!, isDark),
          ],
        ),
        const SizedBox(height: 8),
        // T046: Crosshair info hint for multi-axis mode
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app,
              size: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              'Hover over the chart to see values with units for each series',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColoredStatItem(String label, String value, Color color, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? color.withValues(alpha: 0.9) : color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[600] : Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  Widget _buildStatsPanel(List<ChartDataPoint> raw, List<ChartDataPoint> smoothed, bool isDark) {
    final avgPower = raw.map((p) => p.y).reduce((a, b) => a + b) / raw.length;
    final maxPower = raw.map((p) => p.y).reduce(math.max);
    final minPower = raw.map((p) => p.y).reduce(math.min);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Data Points', '${raw.length}', isDark),
        _buildStatItem('Avg Power', '${avgPower.toInt()}W', isDark),
        _buildStatItem('Max Power', '${maxPower.toInt()}W', isDark),
        _buildStatItem('Min Power', '${minPower.toInt()}W', isDark),
        _buildStatItem('Duration', '23h', isDark),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.blue[300] : Colors.blue)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
      ],
    );
  }
}
