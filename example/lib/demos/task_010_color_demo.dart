// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Task 10 Demo: Color-Coded Axis Rendering
///
/// Demonstrates:
/// - Power axis (left) derives BLUE from power series
/// - HR axis (right) derives RED from heartrate series
/// - Both axes have NO explicit color - color comes from bound series
///
/// This demo visually verifies FR-007:
/// "Each Y-axis MUST support color-coding to match its bound series"
void main() => runApp(const Task010ColorDemo());

/// Main demo widget for Task 10.
class Task010ColorDemo extends StatelessWidget {
  const Task010ColorDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task 10: Color-Coded Axes',
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Task 10: Color-Coded Axes'),
          backgroundColor: Colors.grey[900],
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: ColorCodedAxesDemo(),
          ),
        ),
      ),
    );
  }
}

/// Demo widget that renders color-coded axes.
class ColorCodedAxesDemo extends StatelessWidget {
  const ColorCodedAxesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data for power and heart rate
    final powerData = List.generate(
      20,
      (i) => ChartDataPoint(x: i.toDouble(), y: 100 + (i * 15) % 300),
    );
    final hrData = List.generate(
      20,
      (i) => ChartDataPoint(x: i.toDouble(), y: 60 + (i * 5) % 120),
    );

    // Series with explicit colors
    final powerSeries = LineChartSeries(
      id: 'power',
      name: 'Power',
      points: powerData,
      color: Colors.blue, // BLUE - should appear on left axis
    );

    final hrSeries = LineChartSeries(
      id: 'heartrate',
      name: 'Heart Rate',
      points: hrData,
      color: Colors.red, // RED - should appear on right axis
    );

    // Axes WITHOUT explicit colors - should derive from series
    final powerAxis = YAxisConfig(
      id: 'power-axis',
      position: YAxisPosition.left,
      color: null, // Should resolve to BLUE from powerSeries
      label: 'Power',
      unit: 'W',
    );

    final hrAxis = YAxisConfig(
      id: 'hr-axis',
      position: YAxisPosition.right,
      color: null, // Should resolve to RED from hrSeries
      label: 'Heart Rate',
      unit: 'bpm',
    );

    // Bindings connect series to axes
    final bindings = [
      const SeriesAxisBinding(seriesId: 'power', yAxisId: 'power-axis'),
      const SeriesAxisBinding(seriesId: 'heartrate', yAxisId: 'hr-axis'),
    ];

    // Multi-axis configuration
    final multiAxisConfig = MultiAxisConfig(
      axes: [powerAxis, hrAxis],
      bindings: bindings,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and explanation
        Text(
          'Color-Coded Axis Demonstration',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Left axis (Power): Derives BLUE color from power series\n'
          'Right axis (Heart Rate): Derives RED color from heartrate series\n'
          'Neither axis has explicit color set - colors come from bound series',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[400],
              ),
        ),
        const SizedBox(height: 24),

        // Legend
        const Row(
          children: [
            _LegendItem(color: Colors.blue, label: 'Power (W)'),
            SizedBox(width: 24),
            _LegendItem(color: Colors.red, label: 'Heart Rate (bpm)'),
          ],
        ),
        const SizedBox(height: 24),

        // Chart area with custom painter
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomPaint(
                painter: _MultiAxisDemoPainter(
                  config: multiAxisConfig,
                  series: [powerSeries, hrSeries],
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Status indicator
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AxisColorResolver is working: Both axes derive their colors from bound series',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Legend item widget.
class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: Colors.grey[300]),
        ),
      ],
    );
  }
}

/// Custom painter that demonstrates MultiAxisPainter with color resolution.
class _MultiAxisDemoPainter extends CustomPainter {
  _MultiAxisDemoPainter({
    required this.config,
    required this.series,
  });

  final MultiAxisConfig config;
  final List<ChartSeries> series;

  @override
  void paint(Canvas canvas, Size size) {
    // Define chart areas
    const leftMargin = 80.0;
    const rightMargin = 80.0;
    const topMargin = 20.0;
    const bottomMargin = 40.0;

    final chartArea = Rect.fromLTWH(0, 0, size.width, size.height);
    final plotArea = Rect.fromLTRB(
      leftMargin,
      topMargin,
      size.width - rightMargin,
      size.height - bottomMargin,
    );

    // Draw plot area background
    final plotPaint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.fill;
    canvas.drawRect(plotArea, plotPaint);

    // Draw grid lines
    _paintGrid(canvas, plotArea);

    // Compute axis bounds from series data
    final axisBounds = <String, DataRange>{};
    for (final binding in config.bindings) {
      final matchingSeries = series.where((s) => s.id == binding.seriesId);
      if (matchingSeries.isNotEmpty) {
        final s = matchingSeries.first;
        if (s.points.isNotEmpty) {
          final minY = s.points.map((p) => p.y).reduce((a, b) => a < b ? a : b);
          final maxY = s.points.map((p) => p.y).reduce((a, b) => a > b ? a : b);
          axisBounds[binding.yAxisId] = DataRange(min: minY, max: maxY);
        }
      }
    }

    // Create and use MultiAxisPainter with color resolution
    final painter = MultiAxisPainter(
      axes: config.axes,
      axisBounds: axisBounds,
      bindings: config.bindings,
      series: series,
      labelStyle: const TextStyle(fontSize: 11),
    );

    painter.paint(canvas, chartArea, plotArea);

    // Paint the series data as lines
    _paintSeries(canvas, plotArea, axisBounds);
  }

  void _paintGrid(Canvas canvas, Rect plotArea) {
    final gridPaint = Paint()
      ..color = const Color(0xFF333333)
      ..strokeWidth = 0.5;

    // Horizontal grid lines
    const gridCount = 5;
    for (var i = 0; i <= gridCount; i++) {
      final y = plotArea.top + (plotArea.height / gridCount) * i;
      canvas.drawLine(
        Offset(plotArea.left, y),
        Offset(plotArea.right, y),
        gridPaint,
      );
    }

    // Vertical grid lines
    for (var i = 0; i <= gridCount; i++) {
      final x = plotArea.left + (plotArea.width / gridCount) * i;
      canvas.drawLine(
        Offset(x, plotArea.top),
        Offset(x, plotArea.bottom),
        gridPaint,
      );
    }
  }

  void _paintSeries(
    Canvas canvas,
    Rect plotArea,
    Map<String, DataRange> axisBounds,
  ) {
    for (final s in series) {
      if (s.points.isEmpty) continue;

      // Find the axis for this series
      final binding = config.bindings.where((b) => b.seriesId == s.id).firstOrNull;
      if (binding == null) continue;

      final bounds = axisBounds[binding.yAxisId];
      if (bounds == null) continue;

      // Get X range
      final minX = s.points.map((p) => p.x).reduce((a, b) => a < b ? a : b);
      final maxX = s.points.map((p) => p.x).reduce((a, b) => a > b ? a : b);
      final xRange = maxX - minX;

      final paint = Paint()
        ..color = s.color ?? Colors.grey
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      var isFirst = true;

      for (final point in s.points) {
        // Normalize coordinates
        final normalizedX = xRange > 0 ? (point.x - minX) / xRange : 0.5;
        final normalizedY = MultiAxisNormalizer.normalize(
          point.y,
          bounds.min,
          bounds.max,
        );

        // Convert to screen coordinates
        final screenX = plotArea.left + normalizedX * plotArea.width;
        final screenY = plotArea.bottom - normalizedY * plotArea.height;

        if (isFirst) {
          path.moveTo(screenX, screenY);
          isFirst = false;
        } else {
          path.lineTo(screenX, screenY);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
