/// Edge case test for extreme zoom out.
///
/// Validates system behavior when viewport shows all data points:
/// - Set viewport to show all 10,000 points simultaneously
/// - Assert frame time degrades gracefully (may exceed 16ms budget)
/// - Verify no crashes or rendering artifacts
/// - Verify pool exhaustion handled correctly
///
/// This simulates extreme zoom-out scenarios where user wants overview of entire dataset.
library;

import 'dart:ui' show Paint, Path, Color, Rect, Size, Canvas, Paragraph;

import 'package:flutter/rendering.dart' show TextPainter;
import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/foundation/foundation.dart' show ObjectPool, ViewportCuller;
import 'package:braven_charts/src/rendering/render_pipeline.dart' show RenderPipeline;
import 'package:braven_charts/src/rendering/performance_monitor.dart' show StopwatchPerformanceMonitor;
import 'package:braven_charts/src/rendering/text_layout_cache.dart' show LinkedHashMapTextLayoutCache;
import 'package:braven_charts/src/rendering/layers/data_series_layer.dart' show DataSeriesLayer, ChartDataPoint;

void main() {
  group('Edge Case: Extreme Zoom Out', () {
    test('Viewport shows all 10,000 points (graceful degradation)', () {
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
        initialViewport: const Rect.fromLTWH(0, 0, 10000, 100), // Show all data
      );

      // Create 10,000 data points
      final dataPoints = List.generate(10000, (i) => ChartDataPoint(i.toDouble(), (i % 100).toDouble()));

      pipeline.addLayer(DataSeriesLayer(
        dataPoints: dataPoints,
        dataBounds: const Rect.fromLTRB(0, 0, 10000, 100),
        lineColor: const Color(0xFF2196F3),
        lineWidth: 2.0,
        zIndex: 0,
      ));

      final canvas = _MockCanvas();

      // Render frame with all points visible
      final stopwatch = Stopwatch()..start();

      expect(() => pipeline.renderFrame(canvas, const Size(800, 600)), returnsNormally, reason: 'Should not crash when rendering all 10,000 points');

      stopwatch.stop();
      final frameTime = stopwatch.elapsedMicroseconds / 1000;

      // Frame time may exceed budget, but should still complete
      // We allow up to 50ms for this extreme case (graceful degradation)
      expect(frameTime, lessThan(50), reason: 'Frame time should degrade gracefully (<50ms for 10K points)');

      print('Extreme zoom (10,000 points visible): ${frameTime.toStringAsFixed(1)}ms');
    });

    test('No crashes with maximum data set', () {
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
        initialViewport: const Rect.fromLTWH(0, 0, 10000, 100),
      );

      final dataPoints = List.generate(10000, (i) => ChartDataPoint(i.toDouble(), (i % 100).toDouble()));

      pipeline.addLayer(DataSeriesLayer(
        dataPoints: dataPoints,
        dataBounds: const Rect.fromLTRB(0, 0, 10000, 100),
        lineColor: const Color(0xFF2196F3),
        lineWidth: 2.0,
        zIndex: 0,
      ));

      final canvas = _MockCanvas();

      // Render multiple frames to check stability
      for (int i = 0; i < 10; i++) {
        expect(() => pipeline.renderFrame(canvas, const Size(800, 600)), returnsNormally, reason: 'Frame $i should not crash');
      }

      print('Stability test: 10 frames with 10,000 points, all successful');
    });

    test('Frame time comparison: zoomed in vs zoomed out', () {
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
        initialViewport: const Rect.fromLTWH(0, 0, 800, 100),
      );

      final dataPoints = List.generate(10000, (i) => ChartDataPoint(i.toDouble(), (i % 100).toDouble()));

      pipeline.addLayer(DataSeriesLayer(
        dataPoints: dataPoints,
        dataBounds: const Rect.fromLTRB(0, 0, 10000, 100),
        lineColor: const Color(0xFF2196F3),
        lineWidth: 2.0,
        zIndex: 0,
      ));

      final canvas = _MockCanvas();

      // Measure zoomed in (small viewport, few visible points)
      pipeline.updateViewport(const Rect.fromLTWH(0, 0, 800, 100)); // ~800 points visible

      final zoomedInStopwatch = Stopwatch()..start();
      pipeline.renderFrame(canvas, const Size(800, 600));
      zoomedInStopwatch.stop();
      final zoomedInTime = zoomedInStopwatch.elapsedMicroseconds / 1000;

      // Measure zoomed out (large viewport, all points visible)
      pipeline.updateViewport(const Rect.fromLTWH(0, 0, 10000, 100)); // All 10,000 points

      final zoomedOutStopwatch = Stopwatch()..start();
      pipeline.renderFrame(canvas, const Size(800, 600));
      zoomedOutStopwatch.stop();
      final zoomedOutTime = zoomedOutStopwatch.elapsedMicroseconds / 1000;

      // Zoomed out should be slower, but not catastrophically
      final slowdown = zoomedOutTime / zoomedInTime;

      // We expect ~12.5x slowdown (10000/800), allow up to 20x
      expect(slowdown, lessThan(20), reason: 'Slowdown should be roughly proportional to visible points');

      print('Frame time comparison: '
          'zoomed in ${zoomedInTime.toStringAsFixed(1)}ms, '
          'zoomed out ${zoomedOutTime.toStringAsFixed(1)}ms, '
          'slowdown ${slowdown.toStringAsFixed(1)}x');
    });

    test('Pool statistics under extreme load', () {
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
        initialViewport: const Rect.fromLTWH(0, 0, 10000, 100),
      );

      final dataPoints = List.generate(10000, (i) => ChartDataPoint(i.toDouble(), (i % 100).toDouble()));

      pipeline.addLayer(DataSeriesLayer(
        dataPoints: dataPoints,
        dataBounds: const Rect.fromLTRB(0, 0, 10000, 100),
        lineColor: const Color(0xFF2196F3),
        lineWidth: 2.0,
        zIndex: 0,
      ));

      final canvas = _MockCanvas();

      final initialPaintStats = paintPool.statistics;
      final initialPathStats = pathPool.statistics;

      // Render frame with extreme load
      pipeline.renderFrame(canvas, const Size(800, 600));

      final finalPaintStats = paintPool.statistics;
      final finalPathStats = pathPool.statistics;

      // Verify pools handled load (may have created new objects)
      expect(finalPaintStats.acquireCount, greaterThan(initialPaintStats.acquireCount), reason: 'Paint pool should have been used');
      expect(finalPathStats.acquireCount, greaterThan(initialPathStats.acquireCount), reason: 'Path pool should have been used');

      print('Pool usage under extreme load: '
          'Paint acquires ${finalPaintStats.acquireCount}, '
          'Path acquires ${finalPathStats.acquireCount}');
    });

    test('Rendering artifacts validation (basic sanity check)', () {
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
        initialViewport: const Rect.fromLTWH(0, 0, 10000, 100),
      );

      final dataPoints = List.generate(10000, (i) => ChartDataPoint(i.toDouble(), (i % 100).toDouble()));

      pipeline.addLayer(DataSeriesLayer(
        dataPoints: dataPoints,
        dataBounds: const Rect.fromLTRB(0, 0, 10000, 100),
        lineColor: const Color(0xFF2196F3),
        lineWidth: 2.0,
        zIndex: 0,
      ));

      final canvas = _MockCanvas();

      // Basic check: rendering completes without throwing
      expect(() {
        pipeline.renderFrame(canvas, const Size(800, 600));
      }, returnsNormally, reason: 'Rendering should complete without artifacts/crashes');

      // Verify pipeline state remains valid after extreme load
      expect(pipeline.viewport, equals(const Rect.fromLTWH(0, 0, 10000, 100)), reason: 'Viewport should remain unchanged');

      expect(pipeline.layers.length, equals(1), reason: 'Layer count should remain unchanged');

      print('Rendering artifacts check: No crashes or state corruption');
    });
  });
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
