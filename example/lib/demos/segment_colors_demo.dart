// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT
//
// Segment Colors Demo - Feature 012
// Demonstrates per-segment/point color overrides on all chart types.

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Demo showcasing segment and point color overrides.
///
/// Features demonstrated:
/// 1. Line charts: Threshold-based coloring (Y > 70 = red)
/// 2. Area charts: X-range based coloring
/// 3. Scatter charts: Per-point coloring
/// 4. Bar charts: Per-bar coloring
/// 5. Bezier curves with color transitions
class SegmentColorsDemo extends StatefulWidget {
  const SegmentColorsDemo({super.key});

  @override
  State<SegmentColorsDemo> createState() => _SegmentColorsDemoState();
}

class _SegmentColorsDemoState extends State<SegmentColorsDemo> {
  String _selectedDemo = 'line-threshold';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Segment Colors Demo'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedDemo,
            onSelected: (value) => setState(() => _selectedDemo = value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'line-threshold',
                child: Text('Line: Threshold Coloring'),
              ),
              const PopupMenuItem(
                value: 'line-indices',
                child: Text('Line: Index-based'),
              ),
              const PopupMenuItem(
                value: 'line-bezier',
                child: Text('Line: Bezier with Colors'),
              ),
              const PopupMenuItem(
                value: 'area-range',
                child: Text('Area: X-Range Coloring'),
              ),
              const PopupMenuItem(
                value: 'scatter-highlight',
                child: Text('Scatter: Highlight Points'),
              ),
              const PopupMenuItem(
                value: 'bar-categories',
                child: Text('Bar: Category Colors'),
              ),
              const PopupMenuItem(
                value: 'all-types',
                child: Text('All Types Combined'),
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
      case 'line-threshold':
        return 'Line Chart: Threshold-Based Coloring';
      case 'line-indices':
        return 'Line Chart: Index-Based Segment Colors';
      case 'line-bezier':
        return 'Line Chart: Bezier Curves with Color Transitions';
      case 'area-range':
        return 'Area Chart: X-Range Based Coloring';
      case 'scatter-highlight':
        return 'Scatter Chart: Highlighted Points';
      case 'bar-categories':
        return 'Bar Chart: Category Colors';
      case 'all-types':
        return 'All Chart Types with Styling';
      default:
        return 'Segment Colors';
    }
  }

  String _getDemoDescription() {
    switch (_selectedDemo) {
      case 'line-threshold':
        return 'Line segments where Y > 70 are colored red using segmentStyle. Uses withColorWhere() helper.';
      case 'line-indices':
        return 'Line segments 5-8 are colored orange. Uses withSegmentColors() helper.';
      case 'line-bezier':
        return 'Bezier interpolation with colored segments. Curve remains smooth at color boundaries.';
      case 'area-range':
        return 'Area chart stroke in X range [30, 60) is green. Fill remains uniform.';
      case 'scatter-highlight':
        return 'Scatter points above Y=70 are red and larger. Uses pointStyle on each point.';
      case 'bar-categories':
        return 'Individual bars colored by value: red (high), green (medium), blue (low).';
      case 'all-types':
        return 'Multiple chart types showing different styling approaches.';
      default:
        return '';
    }
  }

  Widget _buildChart() {
    final seriesList = _buildSeriesList();
    return BravenChartPlus(
      series: seriesList,
    );
  }

  List<ChartSeries> _buildSeriesList() {
    switch (_selectedDemo) {
      case 'line-threshold':
        return [_buildLineThreshold()];
      case 'line-indices':
        return [_buildLineIndices()];
      case 'line-bezier':
        return [_buildLineBezier()];
      case 'area-range':
        return [_buildAreaRange()];
      case 'scatter-highlight':
        return [_buildScatterHighlight()];
      case 'bar-categories':
        return [_buildBarCategories()];
      case 'all-types':
        return [
          _buildLineThreshold(),
          _buildScatterHighlightSmall(),
        ];
      default:
        return [_buildLineThreshold()];
    }
  }

  // Generate sine wave data points
  List<ChartDataPoint> _generateSinePoints(int count) {
    return List.generate(count, (i) {
      final x = i.toDouble();
      final y = 50 + 40 * math.sin(x * 0.1);
      return ChartDataPoint(x: x, y: y);
    });
  }

  LineChartSeries _buildLineThreshold() {
    final points = _generateSinePoints(100);
    return LineChartSeries(
      id: 'line-threshold',
      name: 'Line Threshold',
      points: points,
      color: Colors.blue,
      strokeWidth: 2.5,
    ).withColorWhere(
      (point) => point.y > 70,
      Colors.red,
    );
  }

  LineChartSeries _buildLineIndices() {
    final points = _generateSinePoints(100);
    return LineChartSeries(
      id: 'line-indices',
      name: 'Line Indices',
      points: points,
      color: Colors.blue,
      strokeWidth: 2.5,
    ).withSegmentColors({
      5: Colors.orange,
      6: Colors.orange,
      7: Colors.orange,
      8: Colors.orange,
    });
  }

  LineChartSeries _buildLineBezier() {
    final points = _generateSinePoints(100);
    return LineChartSeries(
      id: 'line-bezier',
      name: 'Line Bezier',
      points: points,
      color: Colors.blue,
      interpolation: LineInterpolation.bezier,
      strokeWidth: 2.5,
    ).withColorWhere(
      (point) => point.y > 70,
      Colors.purple,
    );
  }

  AreaChartSeries _buildAreaRange() {
    final points = _generateSinePoints(100);
    return AreaChartSeries(
      id: 'area-range',
      name: 'Area Range',
      points: points,
      color: Colors.blue,
      fillOpacity: 0.3,
      strokeWidth: 2.5,
    ).withStyleInRange(
      30.0,
      60.0,
      const SegmentStyle.color(Colors.green),
    );
  }

  ScatterChartSeries _buildScatterHighlight() {
    final points = _generateSinePoints(50);
    // Apply pointStyle to high-value points
    final styledPoints = points.map((point) {
      if (point.y > 70) {
        return point.copyWith(
          pointStyle: const PointStyle(color: Colors.red, size: 8.0),
        );
      }
      return point;
    }).toList();

    return ScatterChartSeries(
      id: 'scatter-highlight',
      name: 'Scatter Highlight',
      points: styledPoints,
      color: Colors.blue,
      markerRadius: 4.0,
    );
  }

  ScatterChartSeries _buildScatterHighlightSmall() {
    final points = _generateSinePoints(30);
    final styledPoints = points.map((point) {
      if (point.y > 70) {
        return point.copyWith(
          pointStyle: const PointStyle(color: Colors.orange, size: 6.0),
        );
      }
      return point;
    }).toList();

    return ScatterChartSeries(
      id: 'scatter-small',
      name: 'Scatter',
      points: styledPoints,
      color: Colors.grey,
      markerRadius: 3.0,
    );
  }

  BarChartSeries _buildBarCategories() {
    // Generate bar data with category-based coloring
    final points = <ChartDataPoint>[];
    for (int i = 0; i < 12; i++) {
      final y = 20 + 60 * math.sin(i * 0.5).abs();
      Color? barColor;
      if (y > 60) {
        barColor = Colors.red;
      } else if (y > 40) {
        barColor = Colors.green;
      } else {
        barColor = Colors.blue;
      }
      points.add(ChartDataPoint(
        x: i.toDouble(),
        y: y,
        pointStyle: PointStyle.color(barColor),
      ));
    }

    return BarChartSeries(
      id: 'bar-categories',
      name: 'Bar Categories',
      points: points,
      color: Colors.grey, // Default color (overridden by pointStyle)
      barWidthPercent: 0.7,
    );
  }
}

/// Entry point for standalone demo.
void main() {
  runApp(const MaterialApp(
    title: 'Segment Colors Demo',
    home: SegmentColorsDemo(),
  ));
}
