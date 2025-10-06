// Implementation: LineChartLayer
// Feature: 005-chart-types
// Purpose: Line chart RenderLayer implementation
//
// Constitutional Compliance:
// - Performance: Must render 10,000 points in <16ms (Performance First)
// - Uses LineInterpolator for smooth/stepped interpolation
// - Uses ChartRenderer for marker rendering
// - Uses object pooling from RenderContext (zero allocations goal)

import 'dart:ui';

import 'package:braven_charts/src/charts/base/chart_layer.dart';
import 'package:braven_charts/src/charts/base/chart_renderer.dart';
import 'package:braven_charts/src/charts/line/line_chart_config.dart';
import 'package:braven_charts/src/charts/line/line_interpolator.dart';
import 'package:braven_charts/src/rendering/render_context.dart';

/// Line chart layer implementation.
///
/// Renders one or more data series as connected lines with optional markers.
/// Supports three interpolation modes:
/// - Straight: Linear segments between points
/// - Smooth: Catmull-Rom spline curves
/// - Stepped: Horizontal-then-vertical segments
///
/// Performance: Renders 10,000 points in <16ms per contract requirement.
///
/// Example:
/// ```dart
/// final layer = LineChartLayer(
///   series: [
///     ChartSeries(id: 's1', points: [...]),
///     ChartSeries(id: 's2', points: [...]),
///   ],
///   config: LineChartConfig(),
///   theme: theme,
///   animationConfig: animConfig,
///   zIndex: 0,
/// );
/// ```
class LineChartLayer extends ChartLayer {
  /// Configuration for line rendering (interpolation mode, markers, etc.)
  final LineChartConfig config;

  /// Line interpolator for path generation.
  final LineInterpolator _interpolator;

  /// Shared renderer for markers and gradients.
  final ChartRenderer _renderer;

  /// Constructs a line chart layer.
  ///
  /// [series] is the data to render.
  /// [config] defines line style and rendering options.
  /// [theme] provides color palette and styling.
  /// [animationConfig] controls data update animations.
  /// [zIndex] determines rendering order.
  LineChartLayer({
    required super.series,
    required this.config,
    required super.theme,
    required super.animationConfig,
    required super.zIndex,
    super.isVisible,
  })  : _interpolator = LineInterpolator(config.lineStyle),
        _renderer = ChartRenderer();

  @override
  void render(RenderContext context) {
    if (isEmpty) return;

    // Acquire pooled paint object
    final paint = context.paintPool.acquire();
    
    try {
      // Configure paint for line drawing
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = config.lineWidth;
      paint.strokeCap = StrokeCap.round;
      paint.strokeJoin = StrokeJoin.round;

      // TODO: When theming layer is integrated, use theme.seriesTheme.colors
      // For now, use default colors
      final colors = _defaultColors;

      // Render each series
      for (int i = 0; i < series.length; i++) {
        final chartSeries = series[i];
        if (chartSeries.isEmpty) continue;

        // Set color (cycle through available colors)
        paint.color = colors[i % colors.length];

        // Apply dash pattern if configured
        if (config.dashPattern != null && config.dashPattern!.isNotEmpty) {
          // TODO: Implement dash pattern when Flutter API supports it
          // For now, render as solid line
        }

        // Convert ChartDataPoint to Offset for interpolation
        // TODO: Use context.transformer when coordinate system is integrated
        // For now, use direct x,y as screen coordinates (temporary)
        final points = chartSeries.points
            .map((p) => Offset(p.x, p.y))
            .toList();

        // TODO: Implement viewport culling using context.culler
        // For now, render all points (will be optimized later)

        // Get interpolated path from LineInterpolator
        final path = _interpolator.interpolate(points);

        // Draw the line
        context.canvas.drawPath(path, paint);

        // Note: LineInterpolator manages its own cache, no need to return path

        // Render markers if enabled
        if (config.showMarkers) {
          _renderMarkers(context, points, paint.color);
        }
      }
    } finally {
      // Always release pooled paint
      context.paintPool.release(paint);
    }
  }

  /// Renders markers at each data point.
  void _renderMarkers(RenderContext context, List<Offset> points, Color color) {
    final paint = context.paintPool.acquire();
    
    try {
      paint.color = color;
      paint.style = PaintingStyle.fill;

      for (final point in points) {
        _renderer.drawMarker(
          canvas: context.canvas,
          shape: config.markerShape,
          position: point,
          size: config.markerSize,
          paint: paint,
        );
      }
    } finally {
      context.paintPool.release(paint);
    }
  }

  @override
  bool get isEmpty {
    // Layer is empty if no series or all series are empty
    if (series.isEmpty) return true;
    return series.every((s) => s.isEmpty);
  }

  @override
  void dispose() {
    // Clear interpolator cache
    _interpolator.clearCache();
    
    // Clear renderer caches
    _renderer.clearCache();
    _renderer.clearPathPool();
    
    super.dispose();
  }

  @override
  String toString() =>
      'LineChartLayer(series: ${series.length}, lineStyle: ${config.lineStyle}, zIndex: $zIndex)';

  // Default color palette (will be replaced by theme colors)
  static final List<Color> _defaultColors = [
    const Color(0xFF2196F3), // Blue
    const Color(0xFFF44336), // Red
    const Color(0xFF4CAF50), // Green
    const Color(0xFFFFC107), // Amber
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFFF9800), // Orange
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFFE91E63), // Pink
  ];
}
