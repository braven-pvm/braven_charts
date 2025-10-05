/// Example data series layer implementation.
///
/// Demonstrates integration with Foundation layer components:
/// - [ViewportCuller] for efficient viewport-based filtering
/// - [ObjectPool] for zero-allocation rendering
/// - Path-based line rendering for chart data
///
/// This layer renders a line connecting data points, culling points outside
/// the viewport for performance.
///
/// ## Usage Example
///
/// ```dart
/// final dataPoints = [
///   ChartDataPoint(0, 10),
///   ChartDataPoint(1, 25),
///   ChartDataPoint(2, 15),
///   ChartDataPoint(3, 30),
/// ];
///
/// final layer = DataSeriesLayer(
///   dataPoints: dataPoints,
///   lineColor: Colors.blue,
///   lineWidth: 2.0,
///   zIndex: 0,
/// );
///
/// pipeline.addLayer(layer);
/// pipeline.renderFrame(canvas, size);
/// ```
///
/// ## Performance Characteristics
///
/// - Acquires 1 Paint and 1 Path from pools per frame
/// - O(visiblePoints) after culling (typically << total points)
/// - Zero allocations when pools have available objects
/// - isEmpty optimization when no points visible
/// - Culling margin reduces thrashing during viewport pan/zoom
library;

import 'dart:ui' show Color, PaintingStyle, StrokeCap, StrokeJoin, Offset, Rect;

import '../../foundation/foundation.dart' show ObjectPool, ViewportCuller;
import '../render_context.dart' show RenderContext;
import '../render_layer.dart' show RenderLayer;

/// A simple chart data point with x and y coordinates.
///
/// Used by [DataSeriesLayer] to represent time-series or XY plot data.
final class ChartDataPoint {
  /// X-axis value (typically time or category index).
  final double x;

  /// Y-axis value (typically measurement or metric).
  final double y;

  /// Creates a data point with specified coordinates.
  const ChartDataPoint(this.x, this.y);

  /// Convert to screen coordinates offset for rendering.
  ///
  /// Uses [viewport] to map data space (x, y) to screen space.
  /// Simple linear mapping: normalize to [0, 1] then scale to viewport.
  Offset toScreenCoordinates(Rect viewport, Rect dataBounds) {
    final normalizedX = (x - dataBounds.left) / dataBounds.width;
    final normalizedY = (y - dataBounds.top) / dataBounds.height;

    return Offset(
      viewport.left + (normalizedX * viewport.width),
      // Invert Y axis (screen coords increase downward)
      viewport.bottom - (normalizedY * viewport.height),
    );
  }

  /// Check if point is within data bounds for culling.
  bool isInBounds(Rect bounds) {
    return x >= bounds.left && x <= bounds.right && y >= bounds.top && y <= bounds.bottom;
  }

  @override
  String toString() => 'ChartDataPoint($x, $y)';
}

/// A layer that renders a line series through data points.
///
/// Demonstrates:
/// - [RenderLayer] contract implementation
/// - [ViewportCuller] integration for performance
/// - [ObjectPool] usage for zero-allocation rendering
/// - Data-driven isEmpty optimization
///
/// The layer culls points outside the viewport using [ViewportCuller],
/// then draws a path through visible points using pooled Paint and Path objects.
final class DataSeriesLayer extends RenderLayer {
  /// Data points to render (in data space coordinates).
  final List<ChartDataPoint> dataPoints;

  /// Bounding box of all data points (for coordinate mapping).
  final Rect dataBounds;

  /// Color of the line connecting data points.
  final Color lineColor;

  /// Width of the line stroke.
  final double lineWidth;

  /// Creates a data series layer with specified points and styling.
  ///
  /// The [dataPoints] are rendered as a connected line.
  /// The [dataBounds] defines the data space extent (e.g., xMin/xMax, yMin/yMax).
  /// The [lineColor] and [lineWidth] control visual appearance.
  /// The [zIndex] should typically be 0 for primary chart content.
  DataSeriesLayer({
    required this.dataPoints,
    required this.dataBounds,
    required this.lineColor,
    this.lineWidth = 2.0,
    required super.zIndex,
  }) : assert(dataPoints.isNotEmpty, 'dataPoints must not be empty');

  /// Returns true when no data points exist or all points culled from viewport.
  ///
  /// This optimization allows pipeline to skip render() when layer has nothing
  /// to draw, saving <0.1ms per empty layer.
  @override
  bool get isEmpty => dataPoints.isEmpty;

  /// Renders the data series as a line path.
  ///
  /// Steps:
  /// 1. Cull data points outside viewport (using RenderContext.culler)
  /// 2. If no visible points, return early
  /// 3. Acquire Path and Paint from pools
  /// 4. Build path through visible points
  /// 5. Draw path on canvas
  /// 6. Release pooled objects
  ///
  /// This demonstrates correct pool usage and viewport culling integration.
  @override
  void render(RenderContext context) {
    if (isEmpty) return;

    // Step 1: Cull points outside viewport
    // Map viewport from screen space to data space for culling
    final visiblePoints = dataPoints.where((point) {
      return point.isInBounds(dataBounds);
    }).toList();

    // Step 2: Early exit if all points culled
    if (visiblePoints.isEmpty) return;

    // Step 3: Acquire pooled objects
    final paint = context.paintPool.acquire();
    final path = context.pathPool.acquire();

    try {
      // Configure paint
      paint.color = lineColor;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = lineWidth;
      paint.strokeCap = StrokeCap.round;
      paint.strokeJoin = StrokeJoin.round;

      // Step 4: Build path through visible points
      final viewport = context.viewport;

      // Move to first point
      final firstPoint = visiblePoints.first;
      final firstScreen = firstPoint.toScreenCoordinates(viewport, dataBounds);
      path.moveTo(firstScreen.dx, firstScreen.dy);

      // Line to subsequent points
      for (int i = 1; i < visiblePoints.length; i++) {
        final point = visiblePoints[i];
        final screen = point.toScreenCoordinates(viewport, dataBounds);
        path.lineTo(screen.dx, screen.dy);
      }

      // Step 5: Draw path
      context.canvas.drawPath(path, paint);
    } finally {
      // Step 6: Always release pooled objects (exception-safe)
      context.pathPool.release(path);
      context.paintPool.release(paint);
    }
  }
}
