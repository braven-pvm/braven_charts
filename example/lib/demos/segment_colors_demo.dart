// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT
//
// Segment Colors Demo - Feature 012
// Demonstrates per-segment color overrides on line charts.

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Demo showcasing segment color overrides.
///
/// Features demonstrated:
/// 1. Threshold-based coloring (Y > 70 = red)
/// 2. Index-based coloring (specific segments)
/// 3. X-range based coloring
/// 4. Bezier curves with color transitions
class SegmentColorsDemo extends StatefulWidget {
  const SegmentColorsDemo({super.key});

  @override
  State<SegmentColorsDemo> createState() => _SegmentColorsDemoState();
}

class _SegmentColorsDemoState extends State<SegmentColorsDemo> {
  String _selectedDemo = 'threshold';

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
                value: 'threshold',
                child: Text('Threshold Coloring'),
              ),
              const PopupMenuItem(
                value: 'indices',
                child: Text('Index-based Coloring'),
              ),
              const PopupMenuItem(
                value: 'range',
                child: Text('X-Range Coloring'),
              ),
              const PopupMenuItem(
                value: 'bezier',
                child: Text('Bezier with Colors'),
              ),
              const PopupMenuItem(
                value: 'multi',
                child: Text('Multiple Styles'),
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
      case 'threshold':
        return 'Threshold-Based Coloring';
      case 'indices':
        return 'Index-Based Segment Colors';
      case 'range':
        return 'X-Range Based Coloring';
      case 'bezier':
        return 'Bezier Curves with Color Transitions';
      case 'multi':
        return 'Multiple Style Overrides';
      default:
        return 'Segment Colors';
    }
  }

  String _getDemoDescription() {
    switch (_selectedDemo) {
      case 'threshold':
        return 'Segments where Y > 70 are colored red. Notice smooth color transitions at data points.';
      case 'indices':
        return 'Segments 5-8 are colored orange. Uses withSegmentColors() helper.';
      case 'range':
        return 'Segments in X range [30, 60) are colored green. Uses withStyleInRange() helper.';
      case 'bezier':
        return 'Bezier interpolation with colored segments. Curve remains smooth at color boundaries.';
      case 'multi':
        return 'Multiple segment styles: red threshold + green range + orange indices.';
      default:
        return '';
    }
  }

  Widget _buildChart() {
    final series = _buildSeries();
    return BravenChartPlus(
      series: [series],
    );
  }

  LineChartSeries _buildSeries() {
    // Generate sine wave data
    final points = List.generate(100, (i) {
      final x = i.toDouble();
      final y = 50 + 40 * math.sin(x * 0.1);
      return ChartDataPoint(x: x, y: y);
    });

    var series = LineChartSeries(
      id: 'demo',
      name: 'Demo Series',
      points: points,
      color: Colors.blue,
      interpolation: _selectedDemo == 'bezier' ? LineInterpolation.bezier : LineInterpolation.linear,
      strokeWidth: 2.5,
    );

    switch (_selectedDemo) {
      case 'threshold':
        // Color red where Y > 70
        series = series.withColorWhere(
          (point) => point.y > 70,
          Colors.red,
        );
        break;

      case 'indices':
        // Color specific segments orange
        series = series.withSegmentColors({
          5: Colors.orange,
          6: Colors.orange,
          7: Colors.orange,
          8: Colors.orange,
        });
        break;

      case 'range':
        // Color X range green
        series = series.withStyleInRange(
          30.0,
          60.0,
          const SegmentStyle.color(Colors.green),
        );
        break;

      case 'bezier':
        // Bezier with threshold coloring
        series = series.withColorWhere(
          (point) => point.y > 70,
          Colors.purple,
        );
        break;

      case 'multi':
        // Apply multiple styles (last applied takes precedence for overlap)
        series = series
            .withColorWhere((point) => point.y > 70, Colors.red)
            .withStyleInRange(30.0, 60.0, const SegmentStyle.color(Colors.green))
            .withSegmentColors({20: Colors.orange, 21: Colors.orange});
        break;
    }

    return series;
  }
}

/// Entry point for standalone demo.
void main() {
  runApp(const MaterialApp(
    title: 'Segment Colors Demo',
    home: SegmentColorsDemo(),
  ));
}
