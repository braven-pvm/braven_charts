/// Example annotation layer implementation.
///
/// Demonstrates integration with text rendering system:
/// - [TextLayoutCache] for cached text measurement and rendering
/// - [ObjectPool] for TextPainter reuse
/// - Positioned text labels as chart overlays
///
/// This layer renders text annotations at specified positions, caching
/// layout results for performance.
///
/// ## Usage Example
///
/// ```dart
/// final annotations = AnnotationLayer(
///   labels: ['Peak', 'Valley', 'Trend'],
///   positions: [
///     Offset(100, 50),
///     Offset(200, 150),
///     Offset(300, 100),
///   ],
///   textStyle: TextStyle(
///     fontSize: 12,
///     color: Colors.black,
///   ),
///   zIndex: 1,  // Render on top of data
/// );
///
/// pipeline.addLayer(annotations);
/// ```
///
/// ## Performance Characteristics
///
/// - Text layout cached by (text, style) key
/// - Cache hit: <0.01ms per label (no layout)
/// - Cache miss: ~0.5-2ms per label (layout + cache)
/// - Target cache hit rate: >70% (NFR-003)
/// - Zero allocations on cache hit
library;

import 'dart:ui' show Offset;

import 'package:flutter/rendering.dart' show TextSpan, TextPainter, TextDirection, TextStyle;

import '../render_layer.dart' show RenderLayer;
import '../render_context.dart' show RenderContext;
import '../text_layout_cache.dart' show TextLayoutCache;

/// A layer that renders positioned text annotations.
///
/// Demonstrates:
/// - [RenderLayer] contract implementation
/// - [TextLayoutCache] integration for performance
/// - Text rendering with cached layout
/// - Data-driven isEmpty optimization
///
/// Each label is positioned at a screen coordinate and rendered using
/// cached [TextPainter] layout (if available) or fresh layout (cache miss).
final class AnnotationLayer extends RenderLayer {
  /// Text labels to display.
  final List<String> labels;

  /// Screen positions for each label (must match labels.length).
  final List<Offset> positions;

  /// Text styling for all labels.
  final TextStyle textStyle;

  /// Creates an annotation layer with text labels and positions.
  ///
  /// The [labels] and [positions] lists must have the same length.
  /// Each label is rendered at its corresponding position.
  /// The [textStyle] applies to all labels.
  /// The [zIndex] should typically be positive for overlay rendering.
  AnnotationLayer({
    required this.labels,
    required this.positions,
    required this.textStyle,
    required int zIndex,
  })  : assert(labels.length == positions.length,
            'labels and positions must have same length'),
        super(zIndex: zIndex);

  /// Returns true when no labels to render.
  ///
  /// This optimization allows pipeline to skip render() when layer is empty.
  @override
  bool get isEmpty => labels.isEmpty;

  /// Renders text annotations at specified positions.
  ///
  /// Steps:
  /// 1. For each label:
  ///    a. Check text cache for existing layout
  ///    b. If cache miss: create TextPainter, layout, cache result
  ///    c. If cache hit: reuse cached layout
  ///    d. Paint text at position
  ///
  /// This demonstrates correct text cache usage pattern.
  @override
  void render(RenderContext context) {
    if (isEmpty) return;

    final cache = context.textCache;

    for (int i = 0; i < labels.length; i++) {
      final label = labels[i];
      final position = positions[i];

      // Step 1: Try cache lookup
      TextPainter? painter = cache.get(label, textStyle);

      if (painter == null) {
        // Step 2: Cache miss - create and layout TextPainter
        painter = _createAndLayoutTextPainter(label, textStyle);

        // Step 3: Store in cache for future frames
        cache.put(label, textStyle, painter);
      }

      // Step 4: Paint text at position
      painter.paint(context.canvas, position);
    }
  }

  /// Create and layout a TextPainter for the given text and style.
  ///
  /// This is called only on cache miss. Layout is expensive (~0.5-2ms),
  /// so caching is critical for performance.
  TextPainter _createAndLayoutTextPainter(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );

    // Layout with unlimited width (text wraps at natural boundaries)
    painter.layout();

    return painter;
  }
}
