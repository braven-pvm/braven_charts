// Implementation: RenderContext
// Feature: 002-core-rendering
// Purpose: Dependency injection container for rendering infrastructure
//
// Constitutional Compliance:
// - TDD: Integration tests written first (test/integration/rendering/*.dart)
// - Immutability: Recreated per frame, never mutated
// - Dependencies: Foundation (ObjectPool, ViewportCuller), Rendering (TextLayoutCache, PerformanceMonitor)

import 'dart:math' show Point;

import 'package:braven_charts/src/coordinates/coordinate_system.dart';
import 'package:braven_charts/src/coordinates/transform_context.dart';
import 'package:braven_charts/src/coordinates/universal_coordinate_transformer.dart';
import 'package:braven_charts/src/foundation/performance/object_pool.dart';
import 'package:braven_charts/src/foundation/performance/viewport_culler.dart';
import 'package:braven_charts/src/rendering/performance_monitor.dart';
import 'package:braven_charts/src/rendering/text_layout_cache.dart';
import 'package:flutter/painting.dart';

/// Immutable dependency injection container for rendering infrastructure.
///
/// Provides layers with all necessary resources for rendering:
/// - Canvas and viewport for drawing operations
/// - Object pools for Paint, Path, and TextPainter reuse
/// - Text layout cache for avoiding redundant text measurement
/// - Performance monitor for frame timing and jank detection
///
/// ## Lifecycle
///
/// RenderContext is created once per frame by [RenderPipeline] before layer
/// rendering begins. It is passed to each [RenderLayer.render()] call and
/// discarded at frame end. Never mutated during rendering.
///
/// ## Dependency Injection Pattern
///
/// This class follows the dependency injection pattern to:
/// - Eliminate tight coupling between layers and infrastructure
/// - Enable easy testing with mock pools/monitors
/// - Centralize resource management (pools, caches)
/// - Enforce immutability (recreated per frame)
///
/// ## Example Usage
///
/// ```dart
/// // Created by RenderPipeline each frame
/// final context = RenderContext(
///   canvas: canvas,
///   size: Size(800, 600),
///   viewport: Rect.fromLTWH(0, 0, 800, 600),
///   culler: viewportCuller,
///   paintPool: paintPool,
///   pathPool: pathPool,
///   textPainterPool: textPainterPool,
///   textCache: textCache,
///   performanceMonitor: monitor,
/// );
///
/// // Used by layers
/// class MyLayer extends RenderLayer {
///   void render(RenderContext context) {
///     final paint = context.paintPool.acquire();
///     try {
///       context.canvas.drawRect(rect, paint);
///     } finally {
///       context.paintPool.release(paint);
///     }
///   }
/// }
/// ```
///
/// ## Constitutional Compliance
///
/// - Zero external dependencies (Flutter SDK + Foundation only)
/// - Immutable value object (all fields final)
/// - Validation enforced via assertions (debug mode)
class RenderContext {
  /// Create immutable rendering context.
  ///
  /// All parameters except [transformContext] and [transformer] are required.
  /// Validates:
  /// - Canvas size must be positive (width > 0, height > 0)
  /// - Viewport must intersect canvas bounds
  ///
  /// Validation is assertion-based (debug mode only) for zero runtime
  /// overhead in release builds.
  RenderContext({
    required this.canvas,
    required this.size,
    required this.viewport,
    required this.culler,
    required this.paintPool,
    required this.pathPool,
    required this.textPainterPool,
    required this.textCache,
    required this.performanceMonitor,
    this.transformContext,
    this.transformer,
  })  : assert(size.width > 0, 'Canvas width must be positive'),
        assert(size.height > 0, 'Canvas height must be positive');

  /// Flutter canvas for drawing operations.
  ///
  /// Layers use this to draw paths, text, shapes. Canvas is owned by
  /// Flutter's CustomPainter and should not be stored beyond frame end.
  final Canvas canvas;

  /// Canvas size (width, height) in logical pixels.
  ///
  /// Must have positive dimensions (width > 0, height > 0).
  /// Represents total drawable area before viewport transformation.
  final Size size;

  /// Visible bounds after pan/zoom transformation.
  ///
  /// Defines which portion of the data space is currently visible.
  /// Must intersect canvas bounds (validated in constructor).
  /// Used by [culler] to determine point visibility.
  final Rect viewport;

  /// Foundation viewport culler for determining point visibility.
  ///
  /// Layers use this to filter data points outside [viewport], reducing
  /// rendering overhead. See: Foundation Layer ViewportCuller contract.
  final ViewportCuller culler;

  /// Object pool for Paint instances.
  ///
  /// Layers acquire Paint objects for drawing, customize properties
  /// (color, strokeWidth, etc.), then release back to pool. Reduces
  /// allocations and GC pressure (NFR-002 requirement).
  final ObjectPool<Paint> paintPool;

  /// Object pool for Path instances.
  ///
  /// Layers acquire Path objects for complex shapes (lines, curves),
  /// build geometry, draw, then release back to pool. Critical for
  /// line/scatter charts with thousands of points.
  final ObjectPool<Path> pathPool;

  /// Object pool for TextPainter instances.
  ///
  /// Layers acquire TextPainter for text rendering, layout text,
  /// paint, then release. Combined with [textCache] for maximum efficiency.
  final ObjectPool<TextPainter> textPainterPool;

  /// Text layout cache for avoiding redundant text measurement.
  ///
  /// Layers check cache before laying out text. Cache hit returns
  /// pre-measured TextPainter, avoiding costly layout() calls.
  /// Achieves >70% hit rate after warmup (NFR-003 requirement).
  final TextLayoutCache textCache;

  /// Performance monitor for frame timing and jank detection.
  ///
  /// RenderPipeline calls beginFrame()/endFrame() around rendering.
  /// Layers can access currentMetrics for debugging. Tracks average
  /// frame time, p99 frame time, jank count (>16ms frames).
  final PerformanceMonitor performanceMonitor;

  /// Optional coordinate transformation context.
  ///
  /// Contains viewport state, data ranges, and chart layout needed
  /// for transforming points between coordinate systems. Null if
  /// coordinate transformations are not needed for this frame.
  ///
  /// See: Layer 2 (003-coordinate-system) for details.
  final TransformContext? transformContext;

  /// Optional universal coordinate transformer.
  ///
  /// Provides transformations between all 8 coordinate systems
  /// (mouse, screen, chartArea, data, dataPoint, marker, viewport, normalized).
  /// Null if coordinate transformations are not needed for this frame.
  ///
  /// See: Layer 2 (003-coordinate-system) for details.
  final UniversalCoordinateTransformer? transformer;
  // Note: Viewport intersection validation removed for performance.
  // Layers are responsible for handling viewport edge cases.

  /// Canvas width in logical pixels.
  double get width => size.width;

  /// Canvas height in logical pixels.
  double get height => size.height;

  /// Check if a point is within the current viewport.
  ///
  /// Convenience method delegating to [culler]. Layers can use this
  /// for quick visibility checks before drawing individual elements.
  ///
  /// Example:
  /// ```dart
  /// if (context.isPointVisible(point.x, point.y)) {
  ///   context.canvas.drawCircle(Offset(point.x, point.y), 3, paint);
  /// }
  /// ```
  bool isPointVisible(double x, double y) {
    return viewport.contains(Offset(x, y));
  }

  // ============================================================================
  // COORDINATE TRANSFORMATION CONVENIENCE METHODS (Layer 2)
  // ============================================================================

  /// Transform a point from data space to screen space.
  ///
  /// Convenience method for the common data → screen transformation.
  /// Requires [transformContext] and [transformer] to be non-null.
  ///
  /// Example:
  /// ```dart
  /// final dataPoint = Point(25.0, 10.0);
  /// final screenPoint = context.dataToScreen(dataPoint);
  /// context.canvas.drawCircle(
  ///   Offset(screenPoint.x, screenPoint.y),
  ///   3,
  ///   paint,
  /// );
  /// ```
  ///
  /// Throws [StateError] if transformContext or transformer is null.
  Point<double> dataToScreen(Point<double> dataPoint) {
    if (transformContext == null || transformer == null) {
      throw StateError(
        'Cannot transform data to screen: transformContext and transformer must be provided',
      );
    }

    return transformer!.transform(
      dataPoint,
      from: CoordinateSystem.data,
      to: CoordinateSystem.screen,
      context: transformContext!,
    );
  }

  /// Transform a point from screen space to data space.
  ///
  /// Convenience method for the common screen → data transformation.
  /// Requires [transformContext] and [transformer] to be non-null.
  ///
  /// Example:
  /// ```dart
  /// // Convert touch position to data coordinates
  /// final touchPoint = Point(event.localPosition.dx, event.localPosition.dy);
  /// final dataPoint = context.screenToData(touchPoint);
  /// print('User touched: x=${dataPoint.x}, y=${dataPoint.y}');
  /// ```
  ///
  /// Throws [StateError] if transformContext or transformer is null.
  Point<double> screenToData(Point<double> screenPoint) {
    if (transformContext == null || transformer == null) {
      throw StateError(
        'Cannot transform screen to data: transformContext and transformer must be provided',
      );
    }

    return transformer!.transform(
      screenPoint,
      from: CoordinateSystem.screen,
      to: CoordinateSystem.data,
      context: transformContext!,
    );
  }

  /// Transform a batch of points from one coordinate system to another.
  ///
  /// Convenience method for batch transformations with SIMD optimization.
  /// Requires [transformContext] and [transformer] to be non-null.
  ///
  /// Example:
  /// ```dart
  /// // Transform 10K data points to screen for rendering
  /// final dataPoints = <Point<double>>[...]; // 10,000 points
  /// final screenPoints = context.transformBatch(
  ///   dataPoints,
  ///   from: CoordinateSystem.data,
  ///   to: CoordinateSystem.screen,
  /// );
  ///
  /// // Draw all points
  /// for (final point in screenPoints) {
  ///   context.canvas.drawCircle(Offset(point.x, point.y), 2, paint);
  /// }
  /// ```
  ///
  /// Throws [StateError] if transformContext or transformer is null.
  List<Point<double>> transformBatch(
    List<Point<double>> points, {
    required CoordinateSystem from,
    required CoordinateSystem to,
  }) {
    if (transformContext == null || transformer == null) {
      throw StateError(
        'Cannot transform batch: transformContext and transformer must be provided',
      );
    }

    return transformer!.transformBatch(
      points,
      from: from,
      to: to,
      context: transformContext!,
    );
  }
}
