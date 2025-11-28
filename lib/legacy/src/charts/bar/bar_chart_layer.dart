// Implementation: BarChartLayer
// Feature: 005-chart-types
// Purpose: Bar chart RenderLayer implementation
//
// Constitutional Compliance:
// - Performance: Must render 1,000 bars in <16ms (Performance First)
// - Uses BarPositioner for grouped/stacked bar layout
// - Uses ChartRenderer for gradient fills
// - Uses object pooling from RenderContext (zero allocations goal)

import 'dart:ui';

import 'package:braven_charts/legacy/src/charts/bar/bar_chart_config.dart';
import 'package:braven_charts/legacy/src/charts/bar/bar_positioner.dart';
import 'package:braven_charts/legacy/src/charts/base/chart_layer.dart';
import 'package:braven_charts/legacy/src/charts/base/chart_renderer.dart';
import 'package:braven_charts/legacy/src/rendering/render_context.dart';

/// Bar chart layer implementation.
///
/// Renders one or more data series as vertical or horizontal bars.
/// Supports:
/// - Grouped bars: Side-by-side bars for each series
/// - Stacked bars: Cumulative bars (positive up, negative down)
/// - Vertical orientation: Bars grow upward from baseline
/// - Horizontal orientation: Bars grow rightward from baseline
/// - Rounded corners, borders, gradient fills
///
/// Performance: Renders 1,000 bars in <16ms per contract requirement.
///
/// Example:
/// ```dart
/// final layer = BarChartLayer(
///   series: [
///     ChartSeries(id: 's1', points: [...]),
///     ChartSeries(id: 's2', points: [...]),
///   ],
///   config: BarChartConfig(...),
///   theme: theme,
///   animationConfig: animConfig,
///   zIndex: 0,
/// );
/// ```
class BarChartLayer extends ChartLayer {
  /// Constructs a bar chart layer.
  ///
  /// [series] is the data to render.
  /// [config] defines grouping mode, orientation, and styling.
  /// [theme] provides color palette and styling.
  /// [animationConfig] controls data update animations.
  /// [zIndex] determines rendering order.
  BarChartLayer({
    required super.series,
    required this.config,
    required super.theme,
    required super.animationConfig,
    required super.zIndex,
    super.isVisible,
  })  : _positioner = BarPositioner(
          orientation: config.orientation,
          groupingMode: config.groupingMode,
          barWidthRatio: config.barWidthRatio,
          barSpacing: config.barSpacing,
          groupSpacing: config.groupSpacing,
        ),
        _renderer = ChartRenderer();

  /// Configuration for bar rendering (grouping, orientation, styling, etc.)
  final BarChartConfig config;

  /// Bar positioner for layout calculation.
  final BarPositioner _positioner;

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

      // Convert series to bar data format
      final seriesData = series.map((s) {
        return s.points.map((p) => p.y).toList(); // Bar values
      }).toList();

      // TODO: Use actual chart height from context when coordinate system integrated
      const chartHeight = 500.0; // Placeholder

      // Calculate bar layout using BarPositioner
      final barLayouts = _positioner.calculateLayout(
        seriesData: seriesData,
        categoryWidth: _calculateCategoryWidth(
            series.isNotEmpty ? series.first.length : 0),
        chartHeight: chartHeight,
        baseline:
            0.0, // TODO: Use proper baseline when coordinate system integrated
      );

      // Render each bar (need series index to get color)
      var globalBarIndex = 0;
      for (var seriesIndex = 0; seriesIndex < series.length; seriesIndex++) {
        for (var categoryIndex = 0;
            categoryIndex < series[seriesIndex].length;
            categoryIndex++) {
          if (globalBarIndex >= barLayouts.length) break;

          final barLayout = barLayouts[globalBarIndex];
          globalBarIndex++;

          // Get color for this series (cycle through available colors)
          final color = colors[seriesIndex % colors.length];

          // Create bar rectangle
          final barRect = _createBarRect(barLayout, context);

          // Apply gradient if configured
          if (config.useGradient &&
              config.gradientStart != null &&
              config.gradientEnd != null) {
            final shader = _renderer.createGradientShader(
              bounds: barRect,
              startColor: Color(config.gradientStart!),
              endColor: Color(config.gradientEnd!),
              vertical: config.orientation == BarOrientation.vertical,
            );
            paint.shader = shader;
          } else {
            paint.color = color;
            paint.shader = null;
          }

          paint.style = PaintingStyle.fill;

          // Draw the bar with optional rounded corners
          if (config.cornerRadius > 0) {
            final rrect = RRect.fromRectAndRadius(
              barRect,
              Radius.circular(config.cornerRadius),
            );
            context.canvas.drawRRect(rrect, paint);
          } else {
            context.canvas.drawRect(barRect, paint);
          }

          // Draw border if configured
          if (config.borderWidth > 0) {
            paint.style = PaintingStyle.stroke;
            paint.strokeWidth = config.borderWidth;
            paint.color =
                config.borderColor != null ? Color(config.borderColor!) : color;
            paint.shader = null;

            if (config.cornerRadius > 0) {
              final rrect = RRect.fromRectAndRadius(
                barRect,
                Radius.circular(config.cornerRadius),
              );
              context.canvas.drawRRect(rrect, paint);
            } else {
              context.canvas.drawRect(barRect, paint);
            }
          }
        }
      }
    } finally {
      // Always release pooled paint
      context.paintPool.release(paint);
    }
  }

  /// Creates a bar rectangle from layout info.
  ///
  /// Converts BarLayoutInfo bounds to Rect.
  /// TODO: Apply coordinate transformation when coordinate system integrated.
  Rect _createBarRect(BarLayoutInfo barLayout, RenderContext context) {
    // For now, use bounds directly
    // TODO: Transform using context.transformer.dataToScreen()
    return barLayout.bounds;
  }

  /// Calculates the width of each category.
  ///
  /// Divides available width by number of categories.
  /// TODO: Use viewport width from context when coordinate system integrated.
  double _calculateCategoryWidth(int categoryCount) {
    if (categoryCount == 0) return 0.0;

    // For now, use a fixed width
    // TODO: Calculate from viewport: context.viewport.width / categoryCount
    return 100.0; // Placeholder value
  }

  @override
  bool get isEmpty {
    // Layer is empty if no series or all series are empty
    if (series.isEmpty) return true;
    return series.every((s) => s.isEmpty);
  }

  @override
  void dispose() {
    // Clear renderer caches
    _renderer.clearCache();
    _renderer.clearPathPool();

    super.dispose();
  }

  @override
  String toString() =>
      'BarChartLayer(series: ${series.length}, mode: ${config.groupingMode}, orientation: ${config.orientation}, zIndex: $zIndex)';

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
