// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Demo screen showcasing MultiAxisPainter integration with BravenChart.
///
/// This demonstrates:
/// - Multiple Y-axes with different colors
/// - Axes positioned at left, right, outerLeft, outerRight
/// - Different value ranges on each axis
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Screen demonstrating multi-axis rendering on BravenChart.
class MultiAxisDemoScreen extends StatelessWidget {
  const MultiAxisDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Axis Demo'),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFF1E1E1E),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTitle(),
            const SizedBox(height: 16),
            Expanded(child: _buildMultiAxisChart()),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Multi-Axis Chart: Power, Heart Rate & Speed',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMultiAxisChart() {
    // Sample data series
    final powerSeries = ChartSeries(
      id: 'power',
      name: 'Power',
      points: _generatePowerData(),
      color: Colors.blue,
    );

    final heartRateSeries = ChartSeries(
      id: 'heartRate',
      name: 'Heart Rate',
      points: _generateHeartRateData(),
      color: Colors.red,
    );

    final speedSeries = ChartSeries(
      id: 'speed',
      name: 'Speed',
      points: _generateSpeedData(),
      color: Colors.green,
    );

    // Multi-axis configuration with 3 different axes
    final multiAxisConfig = const MultiAxisConfig(
      axes: [
        // Left axis: Power (0-400W) - Blue
        YAxisConfig(
          id: 'powerAxis',
          position: YAxisPosition.left,
          color: Colors.blue,
          label: 'Power',
          unitSuffix: 'W',
          minValue: 0,
          maxValue: 400,
        ),
        // Right axis: Heart Rate (100-200 bpm) - Red
        YAxisConfig(
          id: 'hrAxis',
          position: YAxisPosition.right,
          color: Colors.red,
          label: 'HR',
          unitSuffix: 'bpm',
          minValue: 100,
          maxValue: 200,
        ),
        // Outer Right axis: Speed (0-50 km/h) - Green
        YAxisConfig(
          id: 'speedAxis',
          position: YAxisPosition.outerRight,
          color: Colors.green,
          label: 'Speed',
          unitSuffix: 'km/h',
          minValue: 0,
          maxValue: 50,
        ),
      ],
      bindings: [
        SeriesAxisBinding(seriesId: 'power', axisId: 'powerAxis'),
        SeriesAxisBinding(seriesId: 'heartRate', axisId: 'hrAxis'),
        SeriesAxisBinding(seriesId: 'speed', axisId: 'speedAxis'),
      ],
      mode: NormalizationMode.always,
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      padding: const EdgeInsets.all(16),
      child: BravenChart(
        series: [powerSeries, heartRateSeries, speedSeries],
        multiAxisConfig: multiAxisConfig,
        chartType: ChartType.line,
        lineStyle: LineStyle.smooth,
        theme: ChartTheme.defaultDark,
        xAxis: const AxisConfig(
          showAxis: true,
          showLabels: true,
          showGrid: true,
        ),
        yAxis: const AxisConfig(
          showAxis: false, // Disable default Y-axis, using multiAxisConfig instead
          showLabels: false,
          showGrid: true,
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.blue, 'Power (W)'),
        const SizedBox(width: 24),
        _buildLegendItem(Colors.red, 'Heart Rate (bpm)'),
        const SizedBox(width: 24),
        _buildLegendItem(Colors.green, 'Speed (km/h)'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Generate sample power data (0-400W range)
  List<ChartDataPoint> _generatePowerData() {
    final points = <ChartDataPoint>[];
    for (var i = 0; i <= 60; i++) {
      final x = i.toDouble();
      // Simulate power varying between 150-350W
      final y = 200 + 100 * _sinWave(i, 12) + 50 * _sinWave(i, 5);
      points.add(ChartDataPoint(x: x, y: y.clamp(100, 380)));
    }
    return points;
  }

  // Generate sample heart rate data (100-200 bpm range)
  List<ChartDataPoint> _generateHeartRateData() {
    final points = <ChartDataPoint>[];
    for (var i = 0; i <= 60; i++) {
      final x = i.toDouble();
      // Simulate HR varying between 130-180 bpm
      final y = 155 + 25 * _sinWave(i, 15) + 10 * _cosWave(i, 8);
      points.add(ChartDataPoint(x: x, y: y.clamp(120, 190)));
    }
    return points;
  }

  // Generate sample speed data (0-50 km/h range)
  List<ChartDataPoint> _generateSpeedData() {
    final points = <ChartDataPoint>[];
    for (var i = 0; i <= 60; i++) {
      final x = i.toDouble();
      // Simulate speed varying between 20-45 km/h
      final y = 30 + 10 * _cosWave(i, 20) + 5 * _sinWave(i, 7);
      points.add(ChartDataPoint(x: x, y: y.clamp(15, 48)));
    }
    return points;
  }

  double _sinWave(int x, int period) {
    return (x % period) < (period / 2) ? 1.0 : -1.0;
  }

  double _cosWave(int x, int period) {
    final phase = (x + period ~/ 4) % period;
    return phase < (period / 2) ? 1.0 : -1.0;
  }
}
