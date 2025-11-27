/// Chart painter utilities for multi-axis rendering.
///
/// Provides helper functions for painting multi-axis charts,
/// coordinating axis layout, normalization, and rendering.
///
/// See also:
/// - [ChartRenderBox] for the main render object
/// - [YAxisRenderer] for individual axis rendering
/// - [MultiAxisNormalizer] for coordinate normalization
/// - [AxisLayoutManager] for axis positioning
library;

import 'dart:ui' show Canvas, Color, Offset, Paint, Rect, Size;

import '../axis/y_axis_config.dart';
import '../layout/axis_layout_manager.dart';
import '../models/chart_series.dart';
import 'multi_axis_normalizer.dart';
import 'y_axis_renderer.dart';

/// Paints multiple Y-axes for a multi-axis chart.
///
/// Computes layout positions and renders each axis at its correct position.
/// Supports up to 4 axes: leftOuter, left, right, rightOuter.
///
/// Example:
/// ```dart
/// final painter = MultiAxisPainter(
///   axisConfigs: [powerAxis, heartRateAxis],
///   chartSize: size,
///   plotArea: plotRect,
/// );
///
/// painter.paintAxes(canvas);
/// ```
class MultiAxisPainter {
  /// Creates a multi-axis painter.
  ///
  /// [axisConfigs] defines the axes to render (max 4).
  /// [chartSize] is the total available size.
  /// [plotArea] is the area where chart data is rendered.
  /// [series] provides the data for computing axis bounds.
  MultiAxisPainter({
    required this.axisConfigs,
    required this.chartSize,
    required this.plotArea,
    this.series = const [],
    this.topPadding = 20.0,
    this.bottomPadding = 40.0,
    this.axisColor,
    this.labelColor,
    this.gridColor,
    this.showGrid = false,
  });

  /// The axis configurations.
  final List<YAxisConfig> axisConfigs;

  /// Total chart size.
  final Size chartSize;

  /// The plot area rectangle.
  final Rect plotArea;

  /// Chart series for computing axis bounds.
  final List<ChartSeries> series;

  /// Padding at the top of the chart.
  final double topPadding;

  /// Padding at the bottom (for X-axis).
  final double bottomPadding;

  /// Color for axis lines (optional).
  final Color? axisColor;

  /// Color for axis labels (optional).
  final Color? labelColor;

  /// Color for grid lines (optional).
  final Color? gridColor;

  /// Whether to show grid lines (typically false for multi-axis).
  final bool showGrid;

  /// Cached layout manager.
  AxisLayoutManager? _layoutManager;

  /// Gets the layout manager, creating it if needed.
  AxisLayoutManager get layoutManager {
    _layoutManager ??= AxisLayoutManager(
      axisConfigs: axisConfigs,
      chartSize: chartSize,
      topPadding: topPadding,
      bottomPadding: bottomPadding,
    );
    return _layoutManager!;
  }

  /// Computes the axis bounds from series data.
  Map<String, ({double min, double max})> computeAxisBounds() {
    final bounds = <String, ({double min, double max})>{};

    for (final config in axisConfigs) {
      // Find series bound to this axis
      final axisSeries = series.where((s) => s.yAxisId == config.id).toList();

      // If no series bound, use config bounds or defaults
      if (axisSeries.isEmpty) {
        bounds[config.id] = (
          min: config.min ?? 0.0,
          max: config.max ?? 100.0,
        );
        continue;
      }

      // Compute min/max from series data
      double min = double.infinity;
      double max = double.negativeInfinity;

      for (final s in axisSeries) {
        for (final point in s.points) {
          if (point.y < min) min = point.y;
          if (point.y > max) max = point.y;
        }
      }

      // Add padding for visual margin
      final range = max - min;
      final padding = range * 0.05;

      // Use config bounds if specified, otherwise computed bounds
      bounds[config.id] = (
        min: config.min ?? (min - padding),
        max: config.max ?? (max + padding),
      );
    }

    return bounds;
  }

  /// Paints all Y-axes.
  ///
  /// [canvas] is the canvas to paint on.
  /// [axisBounds] provides optional pre-computed bounds for each axis.
  void paintAxes(
    Canvas canvas, {
    Map<String, ({double min, double max})>? axisBounds,
  }) {
    final bounds = axisBounds ?? computeAxisBounds();
    final layout = layoutManager.computeAxisRects(axisBounds: bounds);

    for (final config in axisConfigs) {
      final rect = layout.getRect(config.id);
      if (rect == null) continue;

      final axisMin = bounds[config.id]?.min ?? config.min ?? 0.0;
      final axisMax = bounds[config.id]?.max ?? config.max ?? 100.0;

      final renderer = YAxisRenderer(
        config: config,
        plotArea: plotArea,
        axisRect: rect,
        minValue: axisMin,
        maxValue: axisMax,
        axisColor: axisColor,
        labelColor: labelColor,
        gridColor: gridColor,
        showGrid: showGrid,
      );

      renderer.paint(canvas);
    }
  }

  /// Gets normalized Y coordinate for a data value on a specific axis.
  ///
  /// Returns the Y coordinate in plot space (0 = top, plotHeight = bottom).
  double normalizeY(double value, String axisId) {
    final config = axisConfigs.firstWhere(
      (c) => c.id == axisId,
      orElse: () => throw ArgumentError('Unknown axis ID: $axisId'),
    );

    final bounds = computeAxisBounds()[axisId];
    final min = bounds?.min ?? config.min ?? 0.0;
    final max = bounds?.max ?? config.max ?? 100.0;

    // Normalize to 0-1 range
    final normalized = (value - min) / (max - min);

    // Convert to plot coordinates (inverted Y: 0 at bottom)
    return plotArea.height * (1 - normalized);
  }

  /// Creates a normalizer for transforming series data to plot coordinates.
  MultiAxisNormalizer createNormalizer() {
    final bounds = computeAxisBounds();
    return MultiAxisNormalizer.fromConfigs(
      configs: axisConfigs,
      series: series,
      plotHeight: plotArea.height,
      axisBounds: bounds,
    );
  }
}

/// Extension for painting multi-axis charts on a Canvas.
extension MultiAxisCanvasExtension on Canvas {
  /// Paints a vertical axis line.
  void paintAxisLine({
    required double x,
    required double top,
    required double bottom,
    Color color = const Color(0xFF666666),
    double strokeWidth = 1.0,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;

    drawLine(Offset(x, top), Offset(x, bottom), paint);
  }
}

/// Result of normalizing a point for multi-axis display.
class NormalizedPoint {
  /// Creates a normalized point.
  const NormalizedPoint({
    required this.x,
    required this.y,
    required this.originalY,
    required this.axisId,
  });

  /// X coordinate in plot space.
  final double x;

  /// Y coordinate in plot space (normalized).
  final double y;

  /// Original Y value (for tooltips).
  final double originalY;

  /// Axis ID this point belongs to.
  final String axisId;

  @override
  String toString() => 'NormalizedPoint(x: $x, y: $y, original: $originalY, axis: $axisId)';
}
