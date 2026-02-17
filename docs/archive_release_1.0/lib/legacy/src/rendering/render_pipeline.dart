// Implementation: RenderPipeline
// Feature: 002-core-rendering
// Purpose: Orchestrates layer rendering with z-ordering, visibility, and performance monitoring
//
// Constitutional Compliance:
// - TDD: Integration tests written first (test/integration/rendering/*.dart)
// - Performance: <8ms frame time budget, pool usage mandatory
// - Dependencies: Foundation (ObjectPool, ViewportCuller), Rendering (all entities)

import 'package:braven_charts/legacy/src/coordinates/transform_context.dart';
import 'package:braven_charts/legacy/src/coordinates/universal_coordinate_transformer.dart';
import 'package:braven_charts/legacy/src/foundation/performance/object_pool.dart';
import 'package:braven_charts/legacy/src/foundation/performance/viewport_culler.dart';
import 'package:braven_charts/legacy/src/rendering/performance_metrics.dart';
import 'package:braven_charts/legacy/src/rendering/performance_monitor.dart';
import 'package:braven_charts/legacy/src/rendering/render_context.dart';
import 'package:braven_charts/legacy/src/rendering/render_layer.dart';
import 'package:braven_charts/legacy/src/rendering/text_layout_cache.dart';
import 'package:flutter/painting.dart';

/// Orchestrates rendering of multiple layers with z-ordering and performance monitoring.
///
/// RenderPipeline manages the complete rendering workflow:
/// 1. Maintains collection of [RenderLayer]s with dynamic add/remove
/// 2. Sorts layers by z-index for correct rendering order
/// 3. Filters invisible layers for performance
/// 4. Creates [RenderContext] per frame for dependency injection
/// 5. Tracks performance metrics via [PerformanceMonitor]
///
/// ## Lifecycle
///
/// ```dart
/// // Creation: Initialize once per chart
/// final pipeline = RenderPipeline(
///   paintPool: paintPool,
///   pathPool: pathPool,
///   textPainterPool: textPainterPool,
///   textCache: textCache,
///   performanceMonitor: monitor,
///   culler: culler,
///   initialViewport: Rect.fromLTWH(0, 0, 800, 600),
/// );
///
/// // Add layers (dynamic)
/// pipeline.addLayer(DataSeriesLayer(data: points, zIndex: 0));
/// pipeline.addLayer(GridLayer(zIndex: -1)); // Background
/// pipeline.addLayer(AnnotationLayer(zIndex: 1)); // Overlay
///
/// // Rendering: 60fps in CustomPainter.paint()
/// @override
/// void paint(Canvas canvas, Size size) {
///   pipeline.renderFrame(canvas, size);
/// }
///
/// // Pan/Zoom: Update viewport
/// pipeline.updateViewport(Rect.fromLTWH(100, 0, 800, 600));
///
/// // Performance: Access metrics
/// final metrics = pipeline.performanceMonitor.currentMetrics;
/// if (!metrics.meetsTargets) {
///   debugPrint('Frame time: ${metrics.averageFrameTimeMs}ms');
/// }
/// ```
///
/// ## Performance Characteristics
///
/// - Layer sorting: O(n log n) per addLayer(), O(1) per renderFrame() (pre-sorted)
/// - Visibility filtering: O(n) per frame
/// - Empty layer skip: <0.1ms saved per empty layer
/// - Total overhead: <1ms (per NFR-001 requirement)
///
/// ## Constitutional Compliance
///
/// - Zero external dependencies (Foundation + Rendering only)
/// - Mutable state (layers, viewport) for runtime updates
/// - Immutable context (recreated per frame)
class RenderPipeline {
  /// Create rendering pipeline with shared infrastructure.
  ///
  /// All parameters except [transformer] and [transformContextFactory] are required.
  /// Infrastructure (pools, cache, monitor) typically created once and shared
  /// across charts/widgets.
  ///
  /// [initialViewport] sets starting visible bounds. Call [updateViewport]
  /// to change viewport at runtime (pan/zoom operations).
  ///
  /// **Coordinate Transformation (Optional)**:
  /// - [transformer]: UniversalCoordinateTransformer instance (from Layer 2)
  /// - [transformContextFactory]: Function to create TransformContext each frame
  ///
  /// If both are provided, RenderContext will include coordinate transformation
  /// support, enabling layers to use `dataToScreen()`, `screenToData()`, etc.
  RenderPipeline({
    required this.paintPool,
    required this.pathPool,
    required this.textPainterPool,
    required this.textCache,
    required this.performanceMonitor,
    required this.culler,
    required Rect initialViewport,
    this.transformer,
    this.transformContextFactory,
  }) : _viewport = initialViewport;

  /// Object pool for Paint instances (shared across layers).
  final ObjectPool<Paint> paintPool;

  /// Object pool for Path instances (shared across layers).
  final ObjectPool<Path> pathPool;

  /// Object pool for TextPainter instances (shared across layers).
  final ObjectPool<TextPainter> textPainterPool;

  /// Text layout cache for avoiding redundant text measurement.
  final TextLayoutCache textCache;

  /// Performance monitor for frame timing and jank detection.
  final PerformanceMonitor performanceMonitor;

  /// Viewport culler from Foundation layer.
  final ViewportCuller culler;

  /// Optional universal coordinate transformer for Layer 2 integration.
  ///
  /// If provided, will be passed to RenderContext for layers to use.
  /// Null if coordinate transformations are not needed.
  final UniversalCoordinateTransformer? transformer;

  /// Optional transformation context factory function.
  ///
  /// Called each frame to create TransformContext if coordinate
  /// transformations are enabled. Receives widget size and viewport.
  ///
  /// Example:
  /// ```dart
  /// transformContextFactory: (size, viewport) => TransformContext(
  ///   widgetSize: size,
  ///   chartAreaBounds: Rect.fromLTWH(50, 30, size.width - 100, size.height - 80),
  ///   xDataRange: DataRange(min: 0, max: 100),
  ///   yDataRange: DataRange(min: 0, max: 50),
  ///   viewport: ViewportState.identity(),
  ///   series: chartSeries,
  /// ),
  /// ```
  final TransformContext? Function(Size size, Rect viewport)?
  transformContextFactory;

  /// Current viewport bounds (mutable via [updateViewport]).
  Rect _viewport;

  /// Registered rendering layers (mutable via [addLayer]/[removeLayer]).
  final List<RenderLayer> _layers = [];

  /// Flag to track if layers need z-order sorting.
  bool _needsSort = false;

  /// Get current viewport bounds.
  Rect get viewport => _viewport;

  /// Get list of all registered layers (read-only).
  ///
  /// Returns unmodifiable view of internal layers list. Use [addLayer]
  /// and [removeLayer] to modify.
  List<RenderLayer> get layers => List.unmodifiable(_layers);

  /// Add layer to rendering pipeline.
  ///
  /// Layer will be inserted into z-order sorted position. Multiple layers
  /// with same z-index render in insertion order (stable sort).
  ///
  /// Duplicate layer additions are allowed (same instance can exist multiple
  /// times if needed, though typically not recommended).
  void addLayer(RenderLayer layer) {
    _layers.add(layer);
    _needsSort = true; // Mark for sorting before next render
  }

  /// Remove layer from rendering pipeline.
  ///
  /// Removes first occurrence of [layer] (identity check). No-op if layer
  /// not found. If layer added multiple times, only first instance removed.
  void removeLayer(RenderLayer layer) {
    _layers.remove(layer);
  }

  /// Update viewport bounds (pan/zoom operation).
  ///
  /// New viewport takes effect on next [renderFrame] call. Layers use
  /// updated viewport for culling and coordinate transformation.
  ///
  /// Example:
  /// ```dart
  /// // Pan right by 100 pixels
  /// final current = pipeline.viewport;
  /// pipeline.updateViewport(current.translate(100, 0));
  ///
  /// // Zoom in 2x (halve viewport dimensions)
  /// pipeline.updateViewport(Rect.fromLTWH(
  ///   current.left,
  ///   current.top,
  ///   current.width / 2,
  ///   current.height / 2,
  /// ));
  /// ```
  void updateViewport(Rect newViewport) {
    _viewport = newViewport;
  }

  /// Render complete frame with all visible, non-empty layers.
  ///
  /// Execution flow:
  /// 1. Begin performance monitoring
  /// 2. Sort layers by z-index if needed
  /// 3. Create immutable RenderContext for this frame
  /// 4. Filter visible layers (isVisible == true)
  /// 5. Render each layer (skip if isEmpty == true)
  /// 6. End performance monitoring
  ///
  /// Called by CustomPainter.paint() typically at 60fps. Must complete in
  /// <8ms average (NFR-001 requirement).
  ///
  /// [canvas] is Flutter's drawing canvas (owned by CustomPainter).
  /// [size] is the canvas size in logical pixels.
  void renderFrame(Canvas canvas, Size size) {
    // Step 1: Begin frame timing
    performanceMonitor.beginFrame();

    try {
      // Step 2: Sort layers by z-index if needed
      if (_needsSort) {
        _sortLayers();
        _needsSort = false;
      }

      // Step 3: Create immutable context for this frame
      //
      // If coordinate transformation is enabled (transformer and factory provided),
      // create TransformContext and include in RenderContext.
      TransformContext? transformContext;
      if (transformer != null && transformContextFactory != null) {
        transformContext = transformContextFactory!(size, _viewport);
      }

      final context = RenderContext(
        canvas: canvas,
        size: size,
        viewport: _viewport,
        culler: culler,
        paintPool: paintPool,
        pathPool: pathPool,
        textPainterPool: textPainterPool,
        textCache: textCache,
        performanceMonitor: performanceMonitor,
        transformer: transformer,
        transformContext: transformContext,
      );

      // Step 4-5: Render visible, non-empty layers in z-order
      int renderedCount = 0;
      int culledCount = 0;

      for (final layer in _layers) {
        if (!layer.isVisible) {
          culledCount++;
          continue;
        }

        if (layer.isEmpty) {
          culledCount++;
          continue;
        }

        layer.render(context);
        renderedCount++;
      }

      // Update pool metrics for performance monitoring
      if (performanceMonitor is StopwatchPerformanceMonitor) {
        final monitor = performanceMonitor as StopwatchPerformanceMonitor;
        final paintStats = paintPool.statistics;
        final pathStats = pathPool.statistics;
        final textStats = textPainterPool.statistics;

        final totalPoolOperations =
            paintStats.acquireCount +
            pathStats.acquireCount +
            textStats.acquireCount;
        final totalPoolReleases =
            paintStats.releaseCount +
            pathStats.releaseCount +
            textStats.releaseCount;

        monitor.updatePoolMetrics(
          poolHitRate: totalPoolOperations > 0
              ? totalPoolReleases / totalPoolOperations
              : 1.0,
          culledElementCount: culledCount,
          renderedElementCount: renderedCount,
        );
      }
    } finally {
      // Step 6: End frame timing (always called, even if exception)
      performanceMonitor.endFrame();
    }
  }

  /// Sort layers by z-index (ascending order).
  ///
  /// Lower z-index renders first (background), higher z-index renders last
  /// (foreground). Stable sort preserves insertion order for equal z-indices.
  void _sortLayers() {
    _layers.sort((a, b) => a.zIndex.compareTo(b.zIndex));
  }

  /// Get current performance metrics snapshot.
  ///
  /// Convenience accessor for `performanceMonitor.currentMetrics`.
  /// Use for debugging, validation, or displaying performance stats.
  PerformanceMetrics get currentMetrics => performanceMonitor.currentMetrics;

  /// Clear all layers from pipeline.
  ///
  /// Useful for chart destruction or complete layer reset.
  void clearLayers() {
    _layers.clear();
  }
}
