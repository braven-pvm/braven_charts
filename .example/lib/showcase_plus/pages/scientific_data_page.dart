// Copyright 2025 Braven Charts - Scientific Data Visualization Example
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
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
                Text('Power Data', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(width: 24),
                _buildToggleButton(label: 'Raw', isSelected: _showRawData, onTap: () => setState(() => _showRawData = true)),
                const SizedBox(width: 8),
                _buildToggleButton(label: 'Lap', isSelected: !_showRawData, onTap: () => setState(() => _showRawData = false)),
                const SizedBox(width: 24),
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
                Text('Selection mode', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                const SizedBox(width: 8),
                Switch(value: _selectionMode, onChanged: (value) => setState(() => _selectionMode = value)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BravenChartPlus(
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
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? Colors.grey[850] : Colors.white,
            child: _buildStatsPanel(rawData, smoothedData, isDark),
          ),
        ],
      ),
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

