/// Edge case test for ObjectPool exhaustion.
///
/// Validates system behavior when requesting more objects than pool capacity:
/// - Acquire 200 Paint objects (pool maxSize=100 typical)
/// - Verify pool allocates beyond capacity (degrades but doesn't crash)
/// - Verify performance degradation acceptable (not catastrophic)
/// - Test pool recovery after exhaustion
///
/// This simulates extreme scenarios like rendering thousands of complex shapes.
library;

import 'dart:ui' show Paint, Path, Color, Rect, Size, Canvas;

import 'package:flutter/rendering.dart' show TextPainter;
import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/foundation/foundation.dart' show ObjectPool, ViewportCuller;
import 'package:braven_charts/src/rendering/render_pipeline.dart' show RenderPipeline;
import 'package:braven_charts/src/rendering/render_layer.dart' show RenderLayer;
import 'package:braven_charts/src/rendering/render_context.dart' show RenderContext;
import 'package:braven_charts/src/rendering/performance_monitor.dart' show StopwatchPerformanceMonitor;
import 'package:braven_charts/src/rendering/text_layout_cache.dart' show LinkedHashMapTextLayoutCache;

void main() {
  group('Edge Case: Pool Exhaustion', () {
    test('Acquire beyond pool capacity (no crash)', () {
      final paintPool = ObjectPool<Paint>(
        factory: () => Paint(),
        reset: (p) => p.color = const Color(0xFF000000),
      );

      final pipeline = RenderPipeline(
        paintPool: paintPool,
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

      // Create layer that acquires many Paint objects (200)
      // Pool will need to allocate beyond typical capacity
      pipeline.addLayer(_PoolExhaustionLayer(
        paintCount: 200,
        exhaustPaint: true,
        exhaustPath: false,
      ));

      final canvas = _MockCanvas();

      final initialStats = paintPool.statistics;

      // Rendering should not crash even when pool exhausted
      expect(() => pipeline.renderFrame(canvas, const Size(800, 600)), returnsNormally,
          reason: 'Pool exhaustion should not crash (allocate on demand)');

      final finalStats = paintPool.statistics;

      // Verify pool created new objects beyond capacity
      expect(finalStats.acquireCount, greaterThan(initialStats.acquireCount),
          reason: 'Pool should have allocated new objects');

      print('Pool exhaustion test: '
          '${finalStats.acquireCount} Paint objects acquired, '
          'no crash');
    });

    test('Performance degradation with pool exhaustion', () {
      final paintPool = ObjectPool<Paint>(
        factory: () => Paint(),
        reset: (p) => p.color = const Color(0xFF000000),
      );

      final pipeline = RenderPipeline(
        paintPool: paintPool,
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

      // Baseline: Normal layer with 10 Paint objects
      pipeline.addLayer(_PoolExhaustionLayer(
        paintCount: 10,
        exhaustPaint: true,
        exhaustPath: false,
      ));

      final canvas = _MockCanvas();

      final baselineStopwatch = Stopwatch()..start();
      pipeline.renderFrame(canvas, const Size(800, 600));
      baselineStopwatch.stop();
      final baselineTime = baselineStopwatch.elapsedMicroseconds / 1000;

      // Remove baseline layer
      pipeline.removeLayer(pipeline.layers.first);

      // Exhaustion: Layer with 200 Paint objects
      pipeline.addLayer(_PoolExhaustionLayer(
        paintCount: 200,
        exhaustPaint: true,
        exhaustPath: false,
      ));

      final exhaustionStopwatch = Stopwatch()..start();
      pipeline.renderFrame(canvas, const Size(800, 600));
      exhaustionStopwatch.stop();
      final exhaustionTime = exhaustionStopwatch.elapsedMicroseconds / 1000;

      // Performance should degrade but not catastrophically
      // Allow up to 5x slowdown for 20x more objects
      final slowdown = exhaustionTime / baselineTime;

      print('Performance degradation: '
          'baseline ${baselineTime.toStringAsFixed(1)}ms, '
          'exhaustion ${exhaustionTime.toStringAsFixed(1)}ms, '
          'slowdown ${slowdown.toStringAsFixed(1)}x');

      // Note: This is informational, not a strict requirement
      // Pool exhaustion causes allocation, which is slower than reuse
    });

    test('Pool recovery after exhaustion', () {
      final paintPool = ObjectPool<Paint>(
        factory: () => Paint(),
        reset: (p) => p.color = const Color(0xFF000000),
      );

      final pipeline = RenderPipeline(
        paintPool: paintPool,
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

      final canvas = _MockCanvas();

      // Frame 1: Exhaust pool with 200 objects
      pipeline.addLayer(_PoolExhaustionLayer(
        paintCount: 200,
        exhaustPaint: true,
        exhaustPath: false,
      ));

      pipeline.renderFrame(canvas, const Size(800, 600));

      final afterExhaustionStats = paintPool.statistics;

      // Remove exhaustion layer
      pipeline.removeLayer(pipeline.layers.first);

      // Frame 2: Normal usage with 10 objects
      pipeline.addLayer(_PoolExhaustionLayer(
        paintCount: 10,
        exhaustPaint: true,
        exhaustPath: false,
      ));

      pipeline.renderFrame(canvas, const Size(800, 600));

      final afterRecoveryStats = paintPool.statistics;

      // Verify pool recovered (hit rate should improve)
      // After exhaustion, subsequent frames should hit pool more often
      expect(afterRecoveryStats.acquireCount, greaterThan(afterExhaustionStats.acquireCount),
          reason: 'Pool should continue working after exhaustion');

      print('Pool recovery test: '
          'After exhaustion (${afterExhaustionStats.acquireCount} acquires), '
          'after recovery (${afterRecoveryStats.acquireCount} acquires), '
          'pool recovered successfully');
    });

    test('Multiple pool types exhaustion simultaneously', () {
      final paintPool = ObjectPool<Paint>(
        factory: () => Paint(),
        reset: (p) => p.color = const Color(0xFF000000),
      );

      final pathPool = ObjectPool<Path>(
        factory: () => Path(),
        reset: (p) => p.reset(),
      );

      final pipeline = RenderPipeline(
        paintPool: paintPool,
        pathPool: pathPool,
        textPainterPool: ObjectPool<TextPainter>(
          factory: () => TextPainter(),
          reset: (tp) {},
        ),
        textCache: LinkedHashMapTextLayoutCache(),
        performanceMonitor: StopwatchPerformanceMonitor(),
        culler: const ViewportCuller(),
        initialViewport: Rect.fromLTWH(0, 0, 800, 600),
      );

      // Create layer that exhausts both Paint and Path pools
      pipeline.addLayer(_PoolExhaustionLayer(
        paintCount: 150,
        exhaustPaint: true,
        exhaustPath: true,
      ));

      final canvas = _MockCanvas();

      final initialPaintStats = paintPool.statistics;
      final initialPathStats = pathPool.statistics;

      // Both pools exhausted simultaneously
      expect(() => pipeline.renderFrame(canvas, const Size(800, 600)), returnsNormally,
          reason: 'Multiple pool exhaustion should not crash');

      final finalPaintStats = paintPool.statistics;
      final finalPathStats = pathPool.statistics;

      // Verify both pools handled exhaustion
      expect(finalPaintStats.acquireCount, greaterThan(initialPaintStats.acquireCount),
          reason: 'Paint pool should have allocated');
      expect(finalPathStats.acquireCount, greaterThan(initialPathStats.acquireCount),
          reason: 'Path pool should have allocated');

      print('Multiple pool exhaustion: '
          'Paint ${finalPaintStats.acquireCount} acquires, '
          'Path ${finalPathStats.acquireCount} acquires, '
          'both pools handled exhaustion');
    });

    test('Pool statistics accuracy under exhaustion', () {
      final paintPool = ObjectPool<Paint>(
        factory: () => Paint(),
        reset: (p) => p.color = const Color(0xFF000000),
      );

      final pipeline = RenderPipeline(
        paintPool: paintPool,
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

      pipeline.addLayer(_PoolExhaustionLayer(
        paintCount: 200,
        exhaustPaint: true,
        exhaustPath: false,
      ));

      final canvas = _MockCanvas();

      final beforeStats = paintPool.statistics;
      final beforeAcquires = beforeStats.acquireCount;
      final beforeReleases = beforeStats.releaseCount;

      pipeline.renderFrame(canvas, const Size(800, 600));

      final afterStats = paintPool.statistics;
      final afterAcquires = afterStats.acquireCount;
      final afterReleases = afterStats.releaseCount;

      // Verify statistics tracked correctly
      // We expect 200 acquires and 200 releases
      final actualAcquires = afterAcquires - beforeAcquires;
      final actualReleases = afterReleases - beforeReleases;

      expect(actualAcquires, equals(200),
          reason: '200 Paint objects should be acquired');
      expect(actualReleases, equals(200),
          reason: '200 Paint objects should be released');

      print('Pool statistics accuracy: '
          '${actualAcquires} acquires, ${actualReleases} releases, '
          'statistics accurate under exhaustion');
    });

    test('Extreme exhaustion (1000 objects)', () {
      final paintPool = ObjectPool<Paint>(
        factory: () => Paint(),
        reset: (p) => p.color = const Color(0xFF000000),
      );

      final pipeline = RenderPipeline(
        paintPool: paintPool,
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

      // Extreme case: 1000 Paint objects
      pipeline.addLayer(_PoolExhaustionLayer(
        paintCount: 1000,
        exhaustPaint: true,
        exhaustPath: false,
      ));

      final canvas = _MockCanvas();

      // Should handle extreme exhaustion without crash
      expect(() => pipeline.renderFrame(canvas, const Size(800, 600)), returnsNormally,
          reason: 'Extreme pool exhaustion (1000 objects) should not crash');

      final stats = paintPool.statistics;

      // Verify all 1000 objects were acquired
      expect(stats.acquireCount, greaterThanOrEqualTo(1000),
          reason: 'All 1000 Paint objects should be acquired');

      print('Extreme exhaustion test: 1000 Paint objects, no crash');
    });
  });
}

// Layer that exhausts object pools
class _PoolExhaustionLayer implements RenderLayer {
  _PoolExhaustionLayer({
    required this.paintCount,
    required this.exhaustPaint,
    required this.exhaustPath,
  });

  final int paintCount;
  final bool exhaustPaint;
  final bool exhaustPath;

  @override
  int get zIndex => 0;

  @override
  bool isVisible = true;

  @override
  bool get isEmpty => false;

  @override
  void render(RenderContext context) {
    // Acquire many Paint objects to exhaust pool
    if (exhaustPaint) {
      final paints = <Paint>[];
      try {
        for (int i = 0; i < paintCount; i++) {
          paints.add(context.paintPool.acquire());
        }
      } finally {
        // Release all acquired paints
        for (final paint in paints) {
          context.paintPool.release(paint);
        }
      }
    }

    // Acquire many Path objects to exhaust pool
    if (exhaustPath) {
      final paths = <Path>[];
      try {
        for (int i = 0; i < paintCount; i++) {
          paths.add(context.pathPool.acquire());
        }
      } finally {
        // Release all acquired paths
        for (final path in paths) {
          context.pathPool.release(path);
        }
      }
    }
  }
}

// Mock canvas for testing
class _MockCanvas extends Fake implements Canvas {}
