// Implementation: AreaChartLayer
// Feature: 005-chart-types
// Purpose: Area chart RenderLayer implementation
//
// Constitutional Compliance:
// - Performance: Must render 10,000 points in <16ms (Performance First)
// - Uses AreaStacking for multi-series stacking
// - Uses ChartRenderer for gradient fills
// - Uses object pooling from RenderContext (zero allocations goal)

import 'dart:ui';

import 'package:braven_charts/legacy/src/charts/area/area_chart_config.dart';
import 'package:braven_charts/legacy/src/charts/area/area_stacking.dart';
import 'package:braven_charts/legacy/src/charts/base/chart_layer.dart';
import 'package:braven_charts/legacy/src/charts/base/chart_renderer.dart';
import 'package:braven_charts/legacy/src/charts/line/line_chart_config.dart'
    show LineStyle;
import 'package:braven_charts/legacy/src/charts/line/line_interpolator.dart';
import 'package:braven_charts/legacy/src/rendering/render_context.dart';

/// Area chart layer implementation.
///
/// Renders one or more data series as filled areas with optional stacking.
/// Supports:
/// - Single series: Simple area fill
/// - Multiple series: Stacked areas with cumulative values
/// - Gradient fills: Vertical or horizontal gradients
/// - Optional line overlay on top of area
///
/// Performance: Renders 10,000 points in <16ms per contract requirement.
///
/// Example:
/// ```dart
/// final layer = AreaChartLayer(
///   series: [
///     ChartSeries(id: 's1', points: [...]),
///     ChartSeries(id: 's2', points: [...]),
///   ],
///   config: AreaChartConfig(...),
///   theme: theme,
///   animationConfig: animConfig,
///   zIndex: 0,
/// );
/// ```
class AreaChartLayer extends ChartLayer {
  /// Constructs an area chart layer.
  ///
  /// [series] is the data to render.
  /// [config] defines stacking mode and area styling.
  /// [theme] provides color palette and styling.
  /// [animationConfig] controls data update animations.
  /// [zIndex] determines rendering order.
  AreaChartLayer({
    required super.series,
    required this.config,
    required super.theme,
    required super.animationConfig,
    required super.zIndex,
    super.isVisible,
  })  : _stacker = const AreaStacking(),
        _interpolator = LineInterpolator(
            config.lineConfig?.lineStyle ?? LineStyle.straight),
        _renderer = ChartRenderer();

  /// Configuration for area rendering (stacking, fill opacity, etc.)
  final AreaChartConfig config;

  /// Area stacking algorithm for multi-series.
  final AreaStacking _stacker;

  /// Line interpolator for area boundaries and optional line overlay.
  final LineInterpolator _interpolator;

  /// Shared renderer for gradients.
  final ChartRenderer _renderer;

  @override
  void render(RenderContext context) {
    if (isEmpty) return;

    // Acquire pooled paint object
    final paint = context.paintPool.acquire();

    try {
      // TODO: When theming layer is integrated, use theme.seriesTheme.colors
      // For now, use default colors
      final colors = _defaultColors;

      // Convert series to stacked areas if needed
      final List<List<Offset>> stackedAreas;

      if (series.length > 1 && config.stacked) {
        // Multi-series stacking enabled
        // Convert ChartSeries to List<List<Offset>> for stacker
        final seriesPoints = series.map((s) {
          return s.points.map((p) => Offset(p.x, p.y)).toList();
        }).toList();

        // Stack the series
        stackedAreas = _stacker.stack(
          seriesPoints,
          baseline: config.baseline,
        );
      } else {
        // Single series or stacking disabled
        // Convert each series to Offset list
        stackedAreas = series.map((s) {
          return s.points.map((p) => Offset(p.x, p.y)).toList();
        }).toList();
      }

      // Render each area (from bottom to top for stacked)
      for (int i = 0; i < stackedAreas.length; i++) {
        final areaPoints = stackedAreas[i];
        if (areaPoints.isEmpty) continue;

        // Set color (cycle through available colors)
        final color = colors[i % colors.length];

        // Create area path
        final areaPath = _createAreaPath(areaPoints, context);

        // Apply gradient if configured
        if (config.fillStyle == AreaFillStyle.gradient) {
          final bounds = areaPath.getBounds();
          final shader = _renderer.createGradientShader(
            bounds: bounds,
            startColor: color.withValues(alpha: config.fillOpacity),
            endColor: color.withValues(alpha: 0.1),
            vertical: true,
          );
          paint.shader = shader;
        } else {
          paint.color = color.withValues(alpha: config.fillOpacity);
          paint.shader = null;
        }

        paint.style = PaintingStyle.fill;

        // Draw the filled area
        context.canvas.drawPath(areaPath, paint);

        // Draw line on top if configured
        if (config.showLine && config.lineConfig != null) {
          _drawLineOverlay(context, areaPoints, color, paint);
        }
      }
    } finally {
      // Always release pooled paint
      context.paintPool.release(paint);
    }
  }

  /// Creates an area path from points.
  ///
  /// The path goes through the points, then closes back to baseline.
  Path _createAreaPath(List<Offset> points, RenderContext context) {
    if (points.isEmpty) {
      return Path();
    }

    // Get interpolated path through points
    final topPath = _interpolator.interpolate(points);

    // Create full area path
    final areaPath = Path.from(topPath);

    // Close the path to baseline
    // For now, close to bottom (y = max of viewport)
    // TODO: Use proper baseline from config when coordinate system integrated
    final lastPoint = points.last;
    final firstPoint = points.first;

    areaPath.lineTo(lastPoint.dx, 0); // Go down from last point
    areaPath.lineTo(firstPoint.dx, 0); // Go to bottom of first point
    areaPath.close(); // Close back to start

    return areaPath;
  }

  /// Draws a line overlay on top of the area.
  void _drawLineOverlay(
      RenderContext context, List<Offset> points, Color color, Paint paint) {
    final lineConfig = config.lineConfig!;

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = lineConfig.lineWidth;
    paint.color = color;
    paint.shader = null;
    paint.strokeCap = StrokeCap.round;
    paint.strokeJoin = StrokeJoin.round;

    final linePath = _interpolator.interpolate(points);
    context.canvas.drawPath(linePath, paint);
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
      'AreaChartLayer(series: ${series.length}, stacked: ${config.stacked}, zIndex: $zIndex)';

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
