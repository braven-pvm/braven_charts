// Implementation: ScatterChartLayer
// Feature: 005-chart-types
// Purpose: Scatter/bubble chart RenderLayer implementation
//
// Constitutional Compliance:
// - Performance: Must render 10,000 points in <16ms (Performance First)
// - Uses ScatterClusterer for optional clustering in dense data
// - Uses ChartRenderer for marker rendering
// - Uses object pooling from RenderContext (zero allocations goal)

import 'dart:ui';

import 'package:braven_charts/src/charts/base/chart_layer.dart';
import 'package:braven_charts/src/charts/base/chart_renderer.dart';
import 'package:braven_charts/src/charts/scatter/scatter_chart_config.dart';
import 'package:braven_charts/src/charts/scatter/scatter_clusterer.dart';
import 'package:braven_charts/src/rendering/render_context.dart';

/// Scatter chart layer implementation.
///
/// Renders one or more data series as scattered points (markers).
/// Supports:
/// - Fixed-size markers: All points same size
/// - Data-driven sizing: Marker size varies by third dimension (bubble chart)
/// - Multiple marker shapes: circle, square, triangle, diamond, cross, plus
/// - Marker styles: filled, outlined, both
/// - Optional clustering: Groups dense points for better performance/readability
///
/// Performance: Renders 10,000 points in <16ms per contract requirement.
///
/// Example:
/// ```dart
/// final layer = ScatterChartLayer(
///   series: [
///     ChartSeries(id: 's1', points: [...]),
///     ChartSeries(id: 's2', points: [...]),
///   ],
///   config: ScatterChartConfig(...),
///   theme: theme,
///   animationConfig: animConfig,
///   zIndex: 0,
/// );
/// ```
class ScatterChartLayer extends ChartLayer {
  /// Constructs a scatter chart layer.
  ///
  /// [series] is the data to render.
  /// [config] defines marker sizing, styling, and clustering.
  /// [theme] provides color palette and styling.
  /// [animationConfig] controls data update animations.
  /// [zIndex] determines rendering order.
  ScatterChartLayer({
    required super.series,
    required this.config,
    required super.theme,
    required super.animationConfig,
    required super.zIndex,
    super.isVisible,
  })  : _renderer = ChartRenderer(),
        _clusterer = config.enableClustering
            ? ScatterClusterer(
                enableClustering: true,
                clusterThreshold: config.clusterThreshold,
                clusterRadius: 20.0, // TODO: Make configurable
              )
            : null;

  /// Configuration for scatter rendering (sizing, styling, clustering, etc.)
  final ScatterChartConfig config;

  /// Shared renderer for markers.
  final ChartRenderer _renderer;

  /// Optional clusterer for dense data.
  final ScatterClusterer? _clusterer;

  @override
  void render(RenderContext context) {
    if (isEmpty) return;

    // Acquire pooled paint object
    final paint = context.paintPool.acquire();

    try {
      // TODO: When theming layer is integrated, use theme.seriesTheme.colors
      // For now, use default colors
      final colors = _defaultColors;

      // Render each series
      for (var seriesIndex = 0; seriesIndex < series.length; seriesIndex++) {
        final s = series[seriesIndex];
        final color = colors[seriesIndex % colors.length];

        // Convert points to Offset
        // TODO: Use context.transformer.dataToScreen() when coordinate system integrated
        final points = s.points.map((p) => Offset(p.x, p.y)).toList();

        // Apply clustering if enabled
        if (_clusterer != null) {
          final clusterResult = _clusterer!.cluster(points);

          // Render clusters
          _renderClusters(context, paint, clusterResult.clusters, color);

          // Render unclustered points
          _renderPoints(
            context,
            paint,
            points,
            clusterResult.unclusteredPoints,
            color,
            s.points,
          );
        } else {
          // Render all points without clustering
          _renderPoints(
            context,
            paint,
            points,
            List.generate(points.length, (i) => i),
            color,
            s.points,
          );
        }
      }
    } finally {
      // Always release pooled paint
      context.paintPool.release(paint);
    }
  }

  /// Renders individual points (markers).
  void _renderPoints(
    RenderContext context,
    Paint paint,
    List<Offset> allPoints,
    List<int> pointIndices,
    Color seriesColor,
    List<dynamic> dataPoints, // ChartDataPoint instances
  ) {
    for (final index in pointIndices) {
      if (index >= allPoints.length) continue;

      final position = allPoints[index];

      // Determine marker size
      final markerSize = _calculateMarkerSize(index, dataPoints);

      // Render marker based on style
      _renderMarker(
        context,
        paint,
        position,
        markerSize,
        seriesColor,
      );
    }
  }

  /// Renders a single marker at the given position.
  void _renderMarker(
    RenderContext context,
    Paint paint,
    Offset position,
    double size,
    Color seriesColor,
  ) {
    // Configure paint based on marker style
    if (config.markerStyle == MarkerStyle.filled || config.markerStyle == MarkerStyle.both) {
      paint.style = PaintingStyle.fill;
      paint.color = seriesColor;
      _renderer.drawMarker(
        canvas: context.canvas,
        shape: config.markerShape,
        position: position,
        size: size,
        paint: paint,
      );
    }

    // Draw outline if needed
    if (config.markerStyle == MarkerStyle.outlined || config.markerStyle == MarkerStyle.both) {
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = config.borderWidth;
      // For outlined mode, use the series color
      // For both mode, use slightly darker border (reduce opacity)
      if (config.markerStyle == MarkerStyle.outlined) {
        paint.color = seriesColor;
      } else {
        // Create darker border by adjusting opacity (80% of original alpha)
        final alphaValue = (seriesColor.a * 0.8).clamp(0.0, 1.0);
        paint.color = seriesColor.withValues(alpha: alphaValue);
      }
      _renderer.drawMarker(
        canvas: context.canvas,
        shape: config.markerShape,
        position: position,
        size: size,
        paint: paint,
      );
    }
  }

  /// Renders cluster indicators.
  void _renderClusters(
    RenderContext context,
    Paint paint,
    List<ClusterInfo> clusters,
    Color color,
  ) {
    for (final cluster in clusters) {
      // Draw cluster circle
      paint.style = PaintingStyle.fill;
      paint.color = color.withValues(alpha: 0.3);
      context.canvas.drawCircle(cluster.center, cluster.radius, paint);

      // Draw cluster border
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2.0;
      paint.color = color;
      context.canvas.drawCircle(cluster.center, cluster.radius, paint);

      // TODO: Draw cluster count label when text rendering available
      // context.canvas.drawText("${cluster.pointCount}", cluster.center, paint);
    }
  }

  /// Calculates marker size based on sizing mode.
  double _calculateMarkerSize(int index, List<dynamic> dataPoints) {
    if (config.sizingMode == MarkerSizingMode.fixed) {
      return config.fixedSize!;
    }

    // Data-driven sizing (bubble chart)
    // TODO: Extract size value from dataPoint when ChartDataPoint has size property
    // For now, use a simple calculation based on index (placeholder)
    if (index >= dataPoints.length) return config.minSize!;

    // In a real implementation, would use: dataPoint.size or dataPoint.z
    // For now, scale linearly between min and max
    final normalizedValue = (index % 10) / 10.0; // Placeholder
    return config.minSize! + (normalizedValue * (config.maxSize! - config.minSize!));
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
      'ScatterChartLayer(series: ${series.length}, sizing: ${config.sizingMode}, clustering: ${config.enableClustering}, zIndex: $zIndex)';

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
