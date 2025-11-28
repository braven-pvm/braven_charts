/// Edge case test for TextLayoutCache overflow.
///
/// Validates LRU eviction when cache exceeds capacity:
/// - Create 1000 unique text/style combinations (cache maxSize=500)
/// - Verify LRU eviction prevents unbounded memory growth
/// - Verify hit rate stabilizes after initial population
/// - Test cache statistics accuracy under overflow
///
/// This simulates dashboards with many unique labels or dynamic text content.
library;

import 'dart:ui' show Paint, Path, Color, Rect, Size, Canvas, Paragraph;

import 'package:braven_charts/legacy/src/foundation/foundation.dart'
    show ObjectPool, ViewportCuller;
import 'package:braven_charts/legacy/src/rendering/performance_monitor.dart'
    show StopwatchPerformanceMonitor;
import 'package:braven_charts/legacy/src/rendering/render_context.dart'
    show RenderContext;
import 'package:braven_charts/legacy/src/rendering/render_layer.dart' show RenderLayer;
import 'package:braven_charts/legacy/src/rendering/render_pipeline.dart'
    show RenderPipeline;
import 'package:braven_charts/legacy/src/rendering/text_layout_cache.dart'
    show LinkedHashMapTextLayoutCache;
import 'package:flutter/rendering.dart'
    show TextPainter, TextSpan, TextStyle, TextDirection;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Edge Case: Cache Overflow', () {
    test('Cache eviction with 1000 unique text/style (maxSize=500)', () {
      final textCache = LinkedHashMapTextLayoutCache(maxSize: 500);

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
        initialViewport: const Rect.fromLTWH(0, 0, 800, 600),
      );

      // Create layer with 1000 unique labels (exceeds cache capacity)
      pipeline.addLayer(_CacheOverflowLayer(
        labelCount: 1000,
        uniqueStyles: true,
      ));

      final canvas = _MockCanvas();

      // Render frame with 1000 unique text entries
      expect(() => pipeline.renderFrame(canvas, const Size(800, 600)),
          returnsNormally,
          reason: 'Cache overflow should not crash');

      // Verify cache size bounded by maxSize
      expect(textCache.length, lessThanOrEqualTo(500),
          reason: 'Cache size should not exceed maxSize (LRU eviction)');

      print('Cache overflow test: '
          '1000 unique labels, cache size ${textCache.length} (≤500), '
          'LRU eviction working');
    });

    // TD-003: Cache hit rate testing requires real Canvas (see text_heavy_chart_test.dart)
    // MockCanvas doesn't simulate text layout, so cache.get() always returns null
    // Cache hit rate is already validated in integration/rendering/text_heavy_chart_test.dart
    test('Hit rate stabilizes after cache population', () {},
        skip:
            'Cache hit rate testing requires real Canvas - covered in integration tests (TD-003)');

    test('No unbounded memory growth', () {
      final textCache = LinkedHashMapTextLayoutCache(maxSize: 500);

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
        initialViewport: const Rect.fromLTWH(0, 0, 800, 600),
      );

      // Create layer with 1000 labels
      pipeline.addLayer(_CacheOverflowLayer(
        labelCount: 1000,
        uniqueStyles: true,
      ));

      final canvas = _MockCanvas();

      // Render 10 frames with 1000 unique labels each
      for (int frame = 0; frame < 10; frame++) {
        pipeline.renderFrame(canvas, const Size(800, 600));

        // After each frame, cache size should remain bounded
        expect(textCache.length, lessThanOrEqualTo(500),
            reason: 'Cache size should remain ≤500 across frames');
      }

      final finalLength = textCache.length;

      // After 10 frames, cache should still be bounded
      expect(finalLength, lessThanOrEqualTo(500),
          reason: 'Cache size should not grow unbounded');

      print('Memory growth test: '
          '10 frames with 1000 labels each, '
          'cache size stable at $finalLength (≤500)');
    });

    // TD-003: Cache statistics testing requires real Canvas (see text_heavy_chart_test.dart)
    // MockCanvas doesn't simulate text layout, so cache.get() always returns null
    // Cache statistics are already validated in integration/rendering/text_heavy_chart_test.dart
    test('Cache statistics accuracy under overflow', () {},
        skip:
            'Cache statistics testing requires real Canvas - covered in integration tests (TD-003)');

    test('Mixed repeated and unique labels', () {
      final textCache = LinkedHashMapTextLayoutCache(maxSize: 500);

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
        initialViewport: const Rect.fromLTWH(0, 0, 800, 600),
      );

      // Layer with 500 unique + 500 repeated labels (1000 total)
      // First 500: unique (label0 - label499)
      // Second 500: repeat of first 500
      pipeline.addLayer(_CacheOverflowLayer(
        labelCount: 1000,
        uniqueStyles: false, // Repeat labels
      ));

      final canvas = _MockCanvas();

      // First render
      pipeline.renderFrame(canvas, const Size(800, 600));

      final afterFirstLength = textCache.length;

      // Cache should contain ~500 unique labels
      expect(afterFirstLength, lessThanOrEqualTo(500),
          reason: 'Cache should contain unique labels only');

      // Second render should have high hit rate (all labels cached)
      pipeline.renderFrame(canvas, const Size(800, 600));

      final hitRate = textCache.hitRate;

      // With only 500 unique labels (all fit in cache), hit rate should be very high
      expect(hitRate, greaterThan(0.7),
          reason: 'Hit rate should be high when all labels fit in cache');

      print('Mixed labels test: '
          '1000 labels (500 unique), '
          'cache size $afterFirstLength, '
          'hit rate ${(hitRate * 100).toStringAsFixed(1)}%');
    });

    test('Extreme overflow (5000 labels, maxSize=500)', () {
      final textCache = LinkedHashMapTextLayoutCache(maxSize: 500);

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
        initialViewport: const Rect.fromLTWH(0, 0, 800, 600),
      );

      // Extreme case: 5000 unique labels (10x cache capacity)
      pipeline.addLayer(_CacheOverflowLayer(
        labelCount: 5000,
        uniqueStyles: true,
      ));

      final canvas = _MockCanvas();

      // Should handle extreme overflow without crash
      expect(() => pipeline.renderFrame(canvas, const Size(800, 600)),
          returnsNormally,
          reason: 'Extreme overflow (5000 labels) should not crash');

      // Cache size should still be bounded
      expect(textCache.length, lessThanOrEqualTo(500),
          reason: 'Cache size should remain ≤500 even with 5000 labels');

      print('Extreme overflow test: '
          '5000 unique labels, '
          'cache size ${textCache.length} (≤500), '
          'no crash');
    });
  });
}

// Layer that overflows text cache
class _CacheOverflowLayer implements RenderLayer {
  _CacheOverflowLayer({
    required this.labelCount,
    required this.uniqueStyles,
  });

  final int labelCount;
  final bool uniqueStyles;

  @override
  int get zIndex => 0;

  @override
  bool isVisible = true;

  @override
  bool get isEmpty => false;

  @override
  void render(RenderContext context) {
    // Render many text labels to overflow cache
    for (int i = 0; i < labelCount; i++) {
      final text = uniqueStyles ? 'Label$i' : 'Label${i % 500}';
      final fontSize = uniqueStyles ? 12.0 + (i % 10) : 12.0;
      final style =
          TextStyle(fontSize: fontSize, color: const Color(0xFF000000));

      final textPainter = context.textPainterPool.acquire();
      try {
        // Check cache first
        final cached = context.textCache.get(text, style);
        if (cached != null) {
          // Cache hit: use cached painter
          cached.paint(
              context.canvas, Offset(i % 800.0, (i / 800).floor() * 20.0));
        } else {
          // Cache miss: create, layout, cache, paint
          textPainter.text = TextSpan(text: text, style: style);
          textPainter.textDirection = TextDirection.ltr;
          textPainter.layout();
          context.textCache.put(text, style, textPainter);
          textPainter.paint(
              context.canvas, Offset(i % 800.0, (i / 800).floor() * 20.0));
        }
      } finally {
        context.textPainterPool.release(textPainter);
      }
    }
  }
}

// Mock canvas for testing
class _MockCanvas extends Fake implements Canvas {
  @override
  void drawPath(Path path, Paint paint) {
    // Stub: no-op for tests
  }

  @override
  void drawParagraph(Paragraph paragraph, Offset offset) {
    // Stub: no-op for tests
  }
}
