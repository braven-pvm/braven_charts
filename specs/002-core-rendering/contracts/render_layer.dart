// Contract: RenderLayer Interface
// Feature: 002-core-rendering
// Purpose: Define the abstract interface for all visual layer implementations
//
// Constitutional Compliance:
// - TDD: This contract must have failing tests BEFORE implementation
// - Performance: Implementations must meet <8ms frame time budget
// - SOLID: Single Responsibility (render only), Open-Closed (extend via subclass)

import 'package:braven_charts/legacy/src/rendering/render_context.dart';
import 'package:flutter/widgets.dart';

/// Abstract base class for all rendering layers in the chart visualization.
///
/// A [RenderLayer] represents a distinct visual element (data series, grid,
/// annotations, etc.) with independent rendering logic. Layers are composable,
/// z-ordered, and can be toggled visible/invisible.
///
/// ## Contract Requirements
///
/// 1. **Rendering**: Implementations MUST override [render] to execute
///    layer-specific drawing operations using the provided [RenderContext].
///
/// 2. **Z-Ordering**: [zIndex] determines rendering order. Lower values render
///    first (bottom/background), higher values render last (top/foreground).
///    Negative indices allowed for backgrounds.
///
/// 3. **Visibility**: [isVisible] controls whether layer participates in
///    rendering. False skips render() call entirely.
///
/// 4. **Emptiness**: [isEmpty] allows layers to short-circuit when no visible
///    elements exist (e.g., data series with no points in viewport).
///    Implementations SHOULD override if emptiness is detectable.
///
/// 5. **Idempotence**: [render] MUST be idempotent. Calling render() multiple
///    times with same context must produce identical visual output.
///
/// 6. **Performance**: Implementations MUST acquire objects from context pools,
///    release them after use. Direct allocation (new Paint()) violates contract.
///
/// 7. **State**: Layers SHOULD be stateless. All rendering data passed via
///    constructor or context. No frame-to-frame state accumulation.
///
/// ## Example Usage
///
/// ```dart
/// class GridLayer extends RenderLayer {
///   final int gridLineCount;
///
///   const GridLayer({
///     required this.gridLineCount,
///     required super.zIndex,
///     super.isVisible,
///   });
///
///   @override
///   void render(RenderContext context) {
///     if (isEmpty) return;
///
///     final paint = context.paintPool.acquire();
///     try {
///       paint.color = Colors.grey.withOpacity(0.3);
///       paint.strokeWidth = 1.0;
///
///       for (int i = 0; i < gridLineCount; i++) {
///         final y = (i / gridLineCount) * context.size.height;
///         context.canvas.drawLine(
///           Offset(0, y),
///           Offset(context.size.width, y),
///           paint,
///         );
///       }
///     } finally {
///       context.paintPool.release(paint);
///     }
///   }
///
///   @override
///   bool get isEmpty => gridLineCount == 0;
/// }
/// ```
///
/// ## Testing Contract
///
/// Implementations MUST pass these contract tests:
///
/// 1. **Visibility Respect**: When `isVisible = false`, render() must not draw
///    (verify canvas.drawCalls == 0).
///
/// 2. **Pool Usage**: render() must acquire from pools, release after use
///    (verify pool statistics: acquires == releases).
///
/// 3. **Z-Order Correctness**: Multiple layers sorted by zIndex must render in
///    correct order (visual validation or canvas call sequence).
///
/// 4. **Idempotence**: Calling render() twice with same context produces
///    identical output (pixel comparison or call recording).
///
/// 5. **Empty Short-Circuit**: When isEmpty == true, render() completes in
///    <0.1ms (performance benchmark).
abstract class RenderLayer {
  /// Rendering order index. Lower values render first (bottom layer),
  /// higher values render last (top layer).
  ///
  /// Convention:
  /// - Negative (e.g., -10): Background elements (grid, axes)
  /// - Zero (0): Primary data visualization
  /// - Positive (e.g., 10): Overlays (annotations, tooltips)
  ///
  /// Layers with identical zIndex render in insertion order (stable sort).
  final int zIndex;

  /// Visibility flag. When false, layer is skipped during rendering.
  ///
  /// Toggling visibility at runtime allows dynamic layer show/hide without
  /// removing layer from pipeline. Useful for interactive features
  /// (legend toggles, data series visibility).
  bool isVisible;

  /// Construct a render layer with specified z-order and visibility.
  ///
  /// [zIndex] determines rendering order (lower = earlier/bottom).
  /// [isVisible] defaults to true (layer renders by default).
  const RenderLayer({
    required this.zIndex,
    this.isVisible = true,
  });

  /// Execute layer-specific rendering operations.
  ///
  /// Implementations draw to [context.canvas] using pooled objects from
  /// [context.paintPool], [context.pathPool], [context.textPainterPool].
  ///
  /// **MUST** acquire pooled objects and release them (try-finally pattern):
  /// ```dart
  /// final paint = context.paintPool.acquire();
  /// try {
  ///   context.canvas.drawCircle(..., paint);
  /// } finally {
  ///   context.paintPool.release(paint);
  /// }
  /// ```
  ///
  /// **MUST** be idempotent. Multiple calls with same context produce
  /// identical visual output.
  ///
  /// **SHOULD** short-circuit if [isEmpty] is true:
  /// ```dart
  /// if (isEmpty) return;
  /// ```
  ///
  /// **SHOULD** use [context.culler] for viewport culling:
  /// ```dart
  /// final visiblePoints = context.culler.cullPoints(allPoints, context.viewport);
  /// ```
  ///
  /// [context] provides all rendering resources: canvas, viewport, pools, etc.
  void render(RenderContext context);

  /// Check if layer has no visible elements.
  ///
  /// Returns true when layer has nothing to render (e.g., data series with
  /// no points, grid with zero lines). Allows pipeline to skip render() call.
  ///
  /// Default implementation returns false (assume layer always has content).
  /// Implementations SHOULD override if emptiness is detectable and
  /// performance-critical.
  ///
  /// **Performance**: Checking isEmpty should be O(1) or very fast (e.g.,
  /// `dataPoints.isEmpty`). Do NOT perform expensive computation here.
  ///
  /// **Pipeline Optimization**: When isEmpty == true, pipeline skips render()
  /// entirely, saving <0.1ms per empty layer per spec §FR-002.
  bool get isEmpty => false;

  @override
  String toString() => 'RenderLayer(zIndex: $zIndex, isVisible: $isVisible)';
}

/// Contract test helper: Mock layer for testing pipeline behavior.
///
/// This implementation is used in contract tests to verify pipeline
/// orchestration, z-ordering, visibility toggling, etc.
///
/// NOT for production use. Production code implements concrete layers
/// (DataSeriesLayer, GridLayer, AnnotationLayer, etc.).
class MockRenderLayer extends RenderLayer {
  /// Callback invoked when render() called. Allows test verification.
  final void Function(RenderContext)? onRender;

  /// Override isEmpty for testing empty layer behavior.
  @override
  final bool isEmpty;

  /// Construct mock layer with test hooks.
  const MockRenderLayer({
    required super.zIndex,
    super.isVisible,
    this.onRender,
    this.isEmpty = false,
  });

  @override
  void render(RenderContext context) {
    if (onRender != null) {
      onRender!(context);
    }
  }
}
