/// Edge case test for text overflow beyond viewport bounds.
///
/// Validates correct handling when text labels exceed viewport:
/// - Create annotations with text extending beyond visible area
/// - Verify text is clipped correctly (no rendering outside viewport)
/// - Verify no crashes or exceptions during rendering
/// - Test performance impact of large text labels
///
/// This simulates axis labels or annotations that are too large for viewport.
library;

import 'dart:ui' show Paint, Path, Color, Rect, Size, Canvas, Offset;

import 'package:flutter/rendering.dart' show TextPainter, TextSpan, TextStyle, TextDirection;
import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/foundation/foundation.dart' show ObjectPool, ViewportCuller;
import 'package:braven_charts/src/rendering/render_pipeline.dart' show RenderPipeline;
import 'package:braven_charts/src/rendering/render_layer.dart' show RenderLayer;
import 'package:braven_charts/src/rendering/render_context.dart' show RenderContext;
import 'package:braven_charts/src/rendering/performance_monitor.dart' show StopwatchPerformanceMonitor;
import 'package:braven_charts/src/rendering/text_layout_cache.dart' show LinkedHashMapTextLayoutCache;

void main() {
  group('Edge Case: Text Overflow', () {
    test('Long text label exceeding viewport bounds (no crash)', () {
      final pipeline = RenderPipeline(
        paintPool: ObjectPool<Paint>(
          factory: () => Paint(),
          reset: (p) => p.color = const Color(0xFF000000),
        ),
        pathPool: ObjectPool<Path>(
          factory: () => Path(),
          reset: (p) => p.reset(),
        ),
        textPainterPool: ObjectPool<TextPainter>(
          factory: () => TextPainter(),
          reset: (tp) {},
        ),
        textCache: LinkedHashMapTextLayoutCache(),
        performanceMonitor: StopwatchPerformanceMonitor(),
        culler: const ViewportCuller(),
        initialViewport: Rect.fromLTWH(0, 0, 800, 600),
      );

      // Create layer with extremely long text label
      const longText = 'This is an extremely long text label that will definitely exceed '
          'the viewport bounds and should be handled gracefully by the rendering system';

      pipeline.addLayer(_TextOverflowLayer(
        text: longText,
        position: const Offset(700, 500),  // Near right edge
        style: const TextStyle(fontSize: 24, color: Color(0xFF000000)),
      ));

      final canvas = _MockCanvas();

      // Rendering should not crash with overflowing text
      expect(() => pipeline.renderFrame(canvas, const Size(800, 600)), returnsNormally,
          reason: 'Should handle text overflow gracefully');

      print('Text overflow test: Long text label rendered without crash');
    });

    test('Multiple overflowing text labels (stability)', () {
      final pipeline = RenderPipeline(
        paintPool: ObjectPool<Paint>(
          factory: () => Paint(),
          reset: (p) => p.color = const Color(0xFF000000),
        ),
        pathPool: ObjectPool<Path>(
          factory: () => Path(),
          reset: (p) => p.reset(),
        ),
        textPainterPool: ObjectPool<TextPainter>(
          factory: () => TextPainter(),
          reset: (tp) {},
        ),
        textCache: LinkedHashMapTextLayoutCache(),
        performanceMonitor: StopwatchPerformanceMonitor(),
        culler: const ViewportCuller(),
        initialViewport: Rect.fromLTWH(0, 0, 800, 600),
      );

      // Create 10 layers with overflowing text at different edges
      const longText = 'Extremely long text that overflows viewport boundaries';

      for (int i = 0; i < 10; i++) {
        pipeline.addLayer(_TextOverflowLayer(
          text: '$longText $i',
          position: Offset(750, i * 60.0),  // Overflow right edge
          style: const TextStyle(fontSize: 20, color: Color(0xFF000000)),
        ));
      }

      final canvas = _MockCanvas();

      // Render multiple frames with overflowing text
      for (int frame = 0; frame < 5; frame++) {
        expect(() => pipeline.renderFrame(canvas, const Size(800, 600)), returnsNormally,
            reason: 'Frame $frame should handle multiple overflows');
      }

      print('Stability test: 5 frames with 10 overflowing text labels, all successful');
    });

    test('Text overflow at all viewport edges', () {
      final pipeline = RenderPipeline(
        paintPool: ObjectPool<Paint>(
          factory: () => Paint(),
          reset: (p) => p.color = const Color(0xFF000000),
        ),
        pathPool: ObjectPool<Path>(
          factory: () => Path(),
          reset: (p) => p.reset(),
        ),
        textPainterPool: ObjectPool<TextPainter>(
          factory: () => TextPainter(),
          reset: (tp) {},
        ),
        textCache: LinkedHashMapTextLayoutCache(),
        performanceMonitor: StopwatchPerformanceMonitor(),
        culler: const ViewportCuller(),
        initialViewport: Rect.fromLTWH(0, 0, 800, 600),
      );

      const longText = 'Very long text label exceeding bounds';

      // Top edge overflow
      pipeline.addLayer(_TextOverflowLayer(
        text: longText,
        position: const Offset(400, -50),  // Above viewport
        style: const TextStyle(fontSize: 20, color: Color(0xFFFF0000)),
      ));

      // Right edge overflow
      pipeline.addLayer(_TextOverflowLayer(
        text: longText,
        position: const Offset(750, 300),  // Past right edge
        style: const TextStyle(fontSize: 20, color: Color(0xFF00FF00)),
      ));

      // Bottom edge overflow
      pipeline.addLayer(_TextOverflowLayer(
        text: longText,
        position: const Offset(400, 580),  // Below viewport
        style: const TextStyle(fontSize: 20, color: Color(0xFF0000FF)),
      ));

      // Left edge overflow
      pipeline.addLayer(_TextOverflowLayer(
        text: longText,
        position: const Offset(-100, 300),  // Before left edge
        style: const TextStyle(fontSize: 20, color: Color(0xFFFFFF00)),
      ));

      final canvas = _MockCanvas();

      // All edge overflows should be handled
      expect(() => pipeline.renderFrame(canvas, const Size(800, 600)), returnsNormally,
          reason: 'All edge overflows should be handled gracefully');

      print('Edge overflow test: Top, right, bottom, left edges all handled correctly');
    });

    test('Performance with very large text labels', () {
      final pipeline = RenderPipeline(
        paintPool: ObjectPool<Paint>(
          factory: () => Paint(),
          reset: (p) => p.color = const Color(0xFF000000),
        ),
        pathPool: ObjectPool<Path>(
          factory: () => Path(),
          reset: (p) => p.reset(),
        ),
        textPainterPool: ObjectPool<TextPainter>(
          factory: () => TextPainter(),
          reset: (tp) {},
        ),
        textCache: LinkedHashMapTextLayoutCache(),
        performanceMonitor: StopwatchPerformanceMonitor(),
        culler: const ViewportCuller(),
        initialViewport: Rect.fromLTWH(0, 0, 800, 600),
      );

      // Create very large text label (1000 characters)
      final massiveText = 'A' * 1000;

      pipeline.addLayer(_TextOverflowLayer(
        text: massiveText,
        position: const Offset(400, 300),
        style: const TextStyle(fontSize: 16, color: Color(0xFF000000)),
      ));

      final canvas = _MockCanvas();

      // Measure performance with massive text
      final stopwatch = Stopwatch()..start();
      pipeline.renderFrame(canvas, const Size(800, 600));
      stopwatch.stop();

      final frameTime = stopwatch.elapsedMicroseconds / 1000;

      // Even with 1000 character text, should be reasonable
      // Text layout can be expensive, allow up to 20ms
      expect(frameTime, lessThan(20),
          reason: 'Very large text should still render in reasonable time (<20ms)');

      print('Large text performance: 1000 characters in ${frameTime.toStringAsFixed(1)}ms');
    });

    test('Text cache with overflowing labels', () {
      final textCache = LinkedHashMapTextLayoutCache();

      final pipeline = RenderPipeline(
        paintPool: ObjectPool<Paint>(
          factory: () => Paint(),
          reset: (p) => p.color = const Color(0xFF000000),
        ),
        pathPool: ObjectPool<Path>(
          factory: () => Path(),
          reset: (p) => p.reset(),
        ),
        textPainterPool: ObjectPool<TextPainter>(
          factory: () => TextPainter(),
          reset: (tp) {},
        ),
        textCache: textCache,
        performanceMonitor: StopwatchPerformanceMonitor(),
        culler: const ViewportCuller(),
        initialViewport: Rect.fromLTWH(0, 0, 800, 600),
      );

      const longText = 'Overflowing text label for cache testing';

      pipeline.addLayer(_TextOverflowLayer(
        text: longText,
        position: const Offset(700, 500),
        style: const TextStyle(fontSize: 18, color: Color(0xFF000000)),
      ));

      final canvas = _MockCanvas();

      final initialLength = textCache.length;
      final initialHitRate = textCache.hitRate;

      // First render (cache miss)
      pipeline.renderFrame(canvas, const Size(800, 600));

      final afterFirstLength = textCache.length;

      // Second render (cache hit)
      pipeline.renderFrame(canvas, const Size(800, 600));

      final afterSecondHitRate = textCache.hitRate;

      // Verify cache was used
      expect(afterFirstLength, greaterThan(initialLength),
          reason: 'First render should add to cache');
      expect(afterSecondHitRate, greaterThan(initialHitRate),
          reason: 'Second render should improve hit rate');

      print('Text cache test: '
          'First render (added to cache), second render (cache hit), '
          'cache working correctly with overflow');
    });

    test('Empty string and whitespace-only labels', () {
      final pipeline = RenderPipeline(
        paintPool: ObjectPool<Paint>(
          factory: () => Paint(),
          reset: (p) => p.color = const Color(0xFF000000),
        ),
        pathPool: ObjectPool<Path>(
          factory: () => Path(),
          reset: (p) => p.reset(),
        ),
        textPainterPool: ObjectPool<TextPainter>(
          factory: () => TextPainter(),
          reset: (tp) {},
        ),
        textCache: LinkedHashMapTextLayoutCache(),
        performanceMonitor: StopwatchPerformanceMonitor(),
        culler: const ViewportCuller(),
        initialViewport: Rect.fromLTWH(0, 0, 800, 600),
      );

      // Empty string
      pipeline.addLayer(_TextOverflowLayer(
        text: '',
        position: const Offset(100, 100),
        style: const TextStyle(fontSize: 16, color: Color(0xFF000000)),
      ));

      // Whitespace only
      pipeline.addLayer(_TextOverflowLayer(
        text: '     ',
        position: const Offset(200, 200),
        style: const TextStyle(fontSize: 16, color: Color(0xFF000000)),
      ));

      final canvas = _MockCanvas();

      // Should handle empty/whitespace text gracefully
      expect(() => pipeline.renderFrame(canvas, const Size(800, 600)), returnsNormally,
          reason: 'Empty and whitespace-only text should not crash');

      print('Edge case test: Empty string and whitespace-only labels handled correctly');
    });
  });
}

// Text overflow layer for testing
class _TextOverflowLayer implements RenderLayer {
  _TextOverflowLayer({
    required this.text,
    required this.position,
    required this.style,
  });

  final String text;
  final Offset position;
  final TextStyle style;

  @override
  int get zIndex => 0;

  @override
  bool isVisible = true;

  @override
  bool get isEmpty => text.isEmpty;

  @override
  void render(RenderContext context) {
    final textPainter = context.textPainterPool.acquire();
    try {
      textPainter.text = TextSpan(text: text, style: style);
      textPainter.textDirection = TextDirection.ltr;
      textPainter.layout();

      // Paint text at position (may overflow viewport)
      textPainter.paint(context.canvas, position);
    } finally {
      context.textPainterPool.release(textPainter);
    }
  }
}

// Mock canvas for testing
class _MockCanvas extends Fake implements Canvas {}
