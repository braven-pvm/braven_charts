// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT
//
// Axis Unification Demo - Feature 013
// Demonstrates unified Y-axis configuration with YAxisConfig and GridConfig.

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Demo showcasing unified axis configuration APIs.
///
/// Features demonstrated:
/// 1. Multi-axis positioning (left, right, leftOuter, rightOuter)
/// 2. CrosshairLabelPosition modes (overAxis vs insidePlot)
/// 3. GridConfig for independent horizontal/vertical grid control
/// 4. AxisLabelDisplay options (labelWithUnit, tickUnitOnly, etc.)
class AxisUnificationDemo extends StatefulWidget {
  const AxisUnificationDemo({super.key});

  @override
  State<AxisUnificationDemo> createState() => _AxisUnificationDemoState();
}

class _AxisUnificationDemoState extends State<AxisUnificationDemo> {
  String _selectedDemo = 'multi-axis';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Axis Unification Demo'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedDemo,
            onSelected: (value) => setState(() => _selectedDemo = value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'multi-axis',
                child: Text('Multi-Axis Positioning'),
              ),
              const PopupMenuItem(
                value: 'crosshair-modes',
                child: Text('Crosshair Label Modes'),
              ),
              const PopupMenuItem(
                value: 'grid-config',
                child: Text('Grid Configuration'),
              ),
              const PopupMenuItem(
                value: 'label-display',
                child: Text('Axis Label Display'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getDemoTitle(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _getDemoDescription(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildChart(),
            ),
          ],
        ),
      ),
    );
  }

  String _getDemoTitle() {
    switch (_selectedDemo) {
      case 'multi-axis':
        return 'Multi-Axis Positioning';
      case 'crosshair-modes':
        return 'Crosshair Label Positioning Modes';
      case 'grid-config':
        return 'Independent Grid Configuration';
      case 'label-display':
        return 'Axis Label Display Options';
      default:
        return 'Axis Unification';
    }
  }

  String _getDemoDescription() {
    switch (_selectedDemo) {
      case 'multi-axis':
        return 'YAxisConfig allows multiple Y-axes at different positions: left, right, leftOuter, rightOuter. Each series can have its own axis with independent scaling.';
      case 'crosshair-modes':
        return 'CrosshairLabelPosition controls where Y-value labels appear: overAxis (in axis strip) vs insidePlot (near axis edge inside plot area).';
      case 'grid-config':
        return 'GridConfig provides independent control of horizontal and vertical grid lines with custom colors and visibility.';
      case 'label-display':
        return 'AxisLabelDisplay options control how axis labels and tick units are displayed: labelWithUnit (default), tickUnitOnly, labelOnly, etc.';
      default:
        return '';
    }
  }

  Widget _buildChart() {
    final seriesList = _buildSeriesList();
    final gridConfig = _buildGridConfig();

    return BravenChartPlus(
      series: seriesList,
      grid: gridConfig,
      showLegend: true,
      interactionConfig: const InteractionConfig(
        enableZoom: true,
        enablePan: true,
        crosshair: CrosshairConfig(enabled: true),
      ),
    );
  }

  GridConfig? _buildGridConfig() {
    // Custom grid config only for the grid-config demo
    if (_selectedDemo == 'grid-config') {
      return GridConfig(
        horizontal: true,
        vertical: false, // Vertical grid disabled
        horizontalColor: Colors.blue.withValues(alpha: 0.3),
        horizontalStrokeWidth: 1.0,
      );
    }
    return null; // Use default grid
  }

  List<ChartSeries> _buildSeriesList() {
    switch (_selectedDemo) {
      case 'multi-axis':
        return _buildMultiAxisDemo();
      case 'crosshair-modes':
        return _buildCrosshairModesDemo();
      case 'grid-config':
        return _buildGridConfigDemo();
      case 'label-display':
        return _buildLabelDisplayDemo();
      default:
        return _buildMultiAxisDemo();
    }
  }

  // Generate sine wave data
  List<ChartDataPoint> _generateSineData(int count,
      {double amplitude = 40, double offset = 50, double frequency = 0.1}) {
    return List.generate(count, (i) {
      final x = i.toDouble();
      final y = offset + amplitude * math.sin(x * frequency);
      return ChartDataPoint(x: x, y: y);
    });
  }

  // Generate cosine wave data
  List<ChartDataPoint> _generateCosineData(int count,
      {double amplitude = 30, double offset = 150, double frequency = 0.15}) {
    return List.generate(count, (i) {
      final x = i.toDouble();
      final y = offset + amplitude * math.cos(x * frequency);
      return ChartDataPoint(x: x, y: y);
    });
  }

  List<ChartSeries> _buildMultiAxisDemo() {
    // Demonstrate multiple Y-axes at different positions
    return [
      LineChartSeries(
        id: 'power',
        name: 'Power (W)',
        points: _generateSineData(100, amplitude: 50, offset: 200),
        color: Colors.blue,
        strokeWidth: 2.5,
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.left,
          label: 'Power',
          unit: 'W',
          color: Colors.blue,
          showAxisLine: true,
          showCrosshairLabel: true,
        ),
      ),
      LineChartSeries(
        id: 'heart_rate',
        name: 'Heart Rate (bpm)',
        points: _generateSineData(100, amplitude: 20, offset: 150),
        color: Colors.red,
        strokeWidth: 2.5,
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.right,
          label: 'Heart Rate',
          unit: 'bpm',
          color: Colors.red,
          showAxisLine: true,
          showCrosshairLabel: true,
        ),
      ),
      LineChartSeries(
        id: 'cadence',
        name: 'Cadence (rpm)',
        points: _generateCosineData(100, amplitude: 15, offset: 85),
        color: Colors.green,
        strokeWidth: 2.5,
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.leftOuter,
          label: 'Cadence',
          unit: 'rpm',
          color: Colors.green,
          showAxisLine: true,
          showCrosshairLabel: true,
        ),
      ),
    ];
  }

  List<ChartSeries> _buildCrosshairModesDemo() {
    // Demonstrate different crosshair label positions
    return [
      LineChartSeries(
        id: 'over_axis',
        name: 'Over Axis (default)',
        points: _generateSineData(100, amplitude: 40, offset: 100),
        color: Colors.purple,
        strokeWidth: 2.5,
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.left,
          label: 'Over Axis',
          unit: 'units',
          color: Colors.purple,
          crosshairLabelPosition: CrosshairLabelPosition.overAxis,
          showAxisLine: true,
          showCrosshairLabel: true,
        ),
      ),
      LineChartSeries(
        id: 'inside_plot',
        name: 'Inside Plot',
        points: _generateCosineData(100, amplitude: 30, offset: 70),
        color: Colors.orange,
        strokeWidth: 2.5,
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.right,
          label: 'Inside Plot',
          unit: 'units',
          color: Colors.orange,
          crosshairLabelPosition: CrosshairLabelPosition.insidePlot,
          showAxisLine: true,
          showCrosshairLabel: true,
        ),
      ),
    ];
  }

  List<ChartSeries> _buildGridConfigDemo() {
    // Simple demo showing grid configuration (grid config set at widget level)
    return [
      LineChartSeries(
        id: 'horizontal_grid',
        name: 'Data with Horizontal Grid Only',
        points: _generateSineData(100, amplitude: 40, offset: 60),
        color: Colors.blue,
        strokeWidth: 2.5,
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.left,
          label: 'Value',
          unit: 'units',
          showAxisLine: true,
          showCrosshairLabel: true,
        ),
      ),
    ];
  }

  List<ChartSeries> _buildLabelDisplayDemo() {
    // Demonstrate different AxisLabelDisplay options
    return [
      LineChartSeries(
        id: 'label_with_unit',
        name: 'Label With Unit',
        points: _generateSineData(100, amplitude: 30, offset: 150),
        color: Colors.teal,
        strokeWidth: 2.5,
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.left,
          label: 'Temperature',
          unit: '°C',
          color: Colors.teal,
          labelDisplay: AxisLabelDisplay
              .labelWithUnit, // "Temperature (°C)" label, "25", "50" ticks
          showAxisLine: true,
        ),
      ),
      LineChartSeries(
        id: 'tick_unit_only',
        name: 'Tick Unit Only',
        points: _generateCosineData(100, amplitude: 20, offset: 100),
        color: Colors.indigo,
        strokeWidth: 2.5,
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.right,
          label: 'Humidity',
          unit: '%',
          color: Colors.indigo,
          labelDisplay:
              AxisLabelDisplay.tickUnitOnly, // No label, "75 %", "80 %" ticks
          showAxisLine: true,
        ),
      ),
    ];
  }
}

/// Entry point for standalone demo.
void main() {
  runApp(const MaterialApp(
    title: 'Axis Unification Demo',
    home: AxisUnificationDemo(),
  ));
}
