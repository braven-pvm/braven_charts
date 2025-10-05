/// Example background grid layer implementation.
///
/// Demonstrates the RenderLayer contract by drawing a simple grid pattern.
/// This layer sits behind chart content (zIndex = -1) to provide visual reference.
///
/// ## Usage Example
///
/// ```dart
/// final pipeline = RenderPipeline(
///   paintPool: ObjectPool<Paint>(...),
///   pathPool: ObjectPool<Path>(...),
///   textPainterPool: ObjectPool<TextPainter>(...),
///   textCache: LinkedHashMapTextLayoutCache(),
///   performanceMonitor: StopwatchPerformanceMonitor(),
///   culler: const ViewportCuller(),
///   initialViewport: Rect.fromLTWH(0, 0, 800, 600),
/// );
///
/// // Add grid layer as background (negative zIndex)
/// pipeline.addLayer(GridLayer(
///   gridLineCount: 10,
///   lineColor: Colors.grey.withOpacity(0.3),
///   zIndex: -1,
/// ));
///
/// // Render frame
/// final canvas = ...;
/// pipeline.renderFrame(canvas, const Size(800, 600));
/// ```
///
/// ## Performance Characteristics
///
/// - Acquires 1 Paint and 1 Path from object pools per frame
/// - O(gridLineCount) draw operations per frame
/// - Zero allocations if pools have available objects
/// - Always renders (isEmpty = false)
library;

import 'dart:ui' show Paint, Path, Color, PaintingStyle, StrokeCap;

import '../../foundation/foundation.dart' show ObjectPool;
import '../render_context.dart' show RenderContext;
import '../render_layer.dart' show RenderLayer;

/// A background layer that draws a grid pattern.
///
/// This is an example implementation demonstrating:
/// - [RenderLayer] contract compliance
/// - Object pool usage ([ObjectPool] for [Paint] and [Path])
/// - Simple geometry rendering
///
/// The grid draws horizontal and vertical lines evenly spaced across
/// the viewport. Line count and color are configurable.
final class GridLayer extends RenderLayer {
  /// Number of horizontal and vertical grid lines to draw.
  final int gridLineCount;

  /// Color of the grid lines.
  final Color lineColor;

  /// Creates a grid layer with specified line count and color.
  ///
  /// The [gridLineCount] determines spacing between lines.
  /// The [lineColor] should typically have low opacity for subtle background.
  /// The [zIndex] should typically be negative to render behind content.
  GridLayer({
    required this.gridLineCount,
    required this.lineColor,
    required super.zIndex,
  }) : assert(gridLineCount > 0, 'gridLineCount must be positive');

  /// Always returns false - grid is always rendered.
  ///
  /// Grid provides visual reference regardless of viewport state.
  @override
  bool get isEmpty => false;

  /// Renders the grid pattern on the canvas.
  ///
  /// Acquires [Paint] and [Path] from [RenderContext] pools,
  /// draws horizontal and vertical lines, then releases objects back to pools.
  ///
  /// This demonstrates proper pool usage:
  /// 1. Acquire objects from context pools
  /// 2. Configure and use objects
  /// 3. Release objects back to pools (in finally block for exception safety)
  @override
  void render(RenderContext context) {
    final viewport = context.viewport;
    final width = viewport.width;
    final height = viewport.height;

    // Acquire pooled objects
    final paint = context.paintPool.acquire();
    final path = context.pathPool.acquire();

    try {
      // Configure paint for grid lines
      paint.color = lineColor;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1.0;
      paint.strokeCap = StrokeCap.round;

      final horizontalSpacing = height / (gridLineCount + 1);
      final verticalSpacing = width / (gridLineCount + 1);

      // Draw horizontal lines
      for (int i = 1; i <= gridLineCount; i++) {
        final y = viewport.top + (i * horizontalSpacing);
        path.moveTo(viewport.left, y);
        path.lineTo(viewport.right, y);
      }

      // Draw vertical lines
      for (int i = 1; i <= gridLineCount; i++) {
        final x = viewport.left + (i * verticalSpacing);
        path.moveTo(x, viewport.top);
        path.lineTo(x, viewport.bottom);
      }

      // Render grid
      context.canvas.drawPath(path, paint);
    } finally {
      // Always release pooled objects (even if exception occurs)
      context.pathPool.release(path);
      context.paintPool.release(paint);
    }
  }
}
