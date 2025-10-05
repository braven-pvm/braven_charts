/// Edge case test for rapid viewport panning.
///
/// Validates system behavior under rapid viewport updates:
/// - Simulate 100 viewport updates in 1 second (10ms per update)
/// - Assert no frame drops (all frames <16ms for 60 FPS)
/// - Assert viewport state updates correctly each frame
/// - Verify no memory leaks (pool sizes remain stable)
///
/// This simulates aggressive user panning/dragging interactions.
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
  group('Edge Case: Rapid Viewport Panning', () {
    late RenderPipeline pipeline;
    late _MockCanvas canvas;
    late ObjectPool<Paint> paintPool;
    late ObjectPool<Path> pathPool;
    late ObjectPool<TextPainter> textPainterPool;

    setUp(() {
      paintPool = ObjectPool<Paint>(
        factory: () => Paint(),
        reset: (p) => p.color = const Color(0xFF000000),
      );

      pathPool = ObjectPool<Path>(
        factory: () => Path(),
        reset: (p) => p.reset(),
      );

      textPainterPool = ObjectPool<TextPainter>(
        factory: () => TextPainter(),
        reset: (tp) {},
      );

      pipeline = RenderPipeline(
        paintPool: paintPool,
        pathPool: pathPool,
        textPainterPool: textPainterPool,
        textCache: LinkedHashMapTextLayoutCache(),
        performanceMonitor: StopwatchPerformanceMonitor(),
        culler: const ViewportCuller(),
        initialViewport: const Rect.fromLTWH(0, 0, 800, 600),
      );

      canvas = _MockCanvas();

      // Add a data series layer for realistic rendering
      final dataPoints = List.generate(1000, (i) => ChartDataPoint(i.toDouble(), (i % 100).toDouble()));

      pipeline.addLayer(DataSeriesLayer(
        dataPoints: dataPoints,
        dataBounds: const Rect.fromLTRB(0, 0, 1000, 100),
        lineColor: const Color(0xFF2196F3),
        lineWidth: 2.0,
        zIndex: 0,
      ));
    });

    test('100 viewport updates in 1 second (no frame drops)', () {
      final frameTimes = <double>[];
      final viewportStates = <Rect>[];

      // Simulate 100 rapid viewport updates (panning from left to right)
      for (int i = 0; i < 100; i++) {
        final panOffset = i * 10.0; // Pan 10 units per update

        final viewport = Rect.fromLTWH(panOffset, 0, 800, 600);
        pipeline.updateViewport(viewport);

        final stopwatch = Stopwatch()..start();

        pipeline.renderFrame(canvas, const Size(800, 600));

        stopwatch.stop();
        final frameTime = stopwatch.elapsedMicroseconds / 1000;
        frameTimes.add(frameTime);

        // Capture viewport state to verify updates
        viewportStates.add(pipeline.viewport);
      }

      // Validate: No frame drops (all <16ms)
      final droppedFrames = frameTimes.where((t) => t >= 16).length;
      expect(droppedFrames, equals(0), reason: 'No frames should exceed 16ms during rapid panning');

      // Validate: Average frame time still within budget
      final avgFrameTime = frameTimes.fold<double>(0, (a, b) => a + b) / frameTimes.length;
      expect(avgFrameTime, lessThan(8), reason: 'Average frame time should remain <8ms');

      // Validate: Viewport states updated correctly
      for (int i = 0; i < 100; i++) {
        final expectedLeft = i * 10.0;
        expect(viewportStates[i].left, equals(expectedLeft), reason: 'Viewport should update correctly for frame $i');
      }

      print('Rapid pan test: 100 updates, '
          'avg ${avgFrameTime.toStringAsFixed(1)}ms, '
          '$droppedFrames frame drops');
    });

    test('Viewport state updates correctly each frame', () {
      final viewportHistory = <Rect>[];

      // Pan with varying speeds
      for (int i = 0; i < 50; i++) {
        final panOffset = i * i * 0.5; // Accelerating pan

        final viewport = Rect.fromLTWH(panOffset, 0, 800, 600);
        pipeline.updateViewport(viewport);

        pipeline.renderFrame(canvas, const Size(800, 600));

        viewportHistory.add(pipeline.viewport);
      }

      // Verify each viewport state matches what we set
      for (int i = 0; i < 50; i++) {
        final expectedLeft = i * i * 0.5;
        expect(viewportHistory[i].left, equals(expectedLeft), reason: 'Viewport left should be $expectedLeft at frame $i');
        expect(viewportHistory[i].width, equals(800), reason: 'Viewport width should remain constant');
        expect(viewportHistory[i].height, equals(600), reason: 'Viewport height should remain constant');
      }

      print('Viewport state validation: 50 frames, all states correct');
    });

    test('No memory leaks (pool sizes stable)', () {
      final initialPaintSize = paintPool.statistics.currentSize;
      final initialPathSize = pathPool.statistics.currentSize;
      final initialTextPainterSize = textPainterPool.statistics.currentSize;

      // Perform 200 rapid viewport updates with rendering
      for (int i = 0; i < 200; i++) {
        final viewport = Rect.fromLTWH(i * 5.0, 0, 800, 600);
        pipeline.updateViewport(viewport);
        pipeline.renderFrame(canvas, const Size(800, 600));
      }

      final finalPaintSize = paintPool.statistics.currentSize;
      final finalPathSize = pathPool.statistics.currentSize;
      final finalTextPainterSize = textPainterPool.statistics.currentSize;

      // Pool sizes should be stable (may grow initially, but not unbounded)
      // Allow some growth but not linear with frame count
      expect(finalPaintSize, lessThan(initialPaintSize + 50), reason: 'Paint pool should not grow unbounded');
      expect(finalPathSize, lessThan(initialPathSize + 50), reason: 'Path pool should not grow unbounded');
      expect(finalTextPainterSize, lessThan(initialTextPainterSize + 50), reason: 'TextPainter pool should not grow unbounded');

      print('Memory leak check: Paint pool $initialPaintSize -> $finalPaintSize, '
          'Path pool $initialPathSize -> $finalPathSize, '
          'TextPainter pool $initialTextPainterSize -> $finalTextPainterSize');
    });

    test('Performance remains stable over extended panning', () {
      final firstHalfFrameTimes = <double>[];
      final secondHalfFrameTimes = <double>[];

      // Render first 50 frames
      for (int i = 0; i < 50; i++) {
        final viewport = Rect.fromLTWH(i * 10.0, 0, 800, 600);
        pipeline.updateViewport(viewport);

        final stopwatch = Stopwatch()..start();
        pipeline.renderFrame(canvas, const Size(800, 600));
        stopwatch.stop();

        firstHalfFrameTimes.add(stopwatch.elapsedMicroseconds / 1000);
      }

      // Render second 50 frames
      for (int i = 50; i < 100; i++) {
        final viewport = Rect.fromLTWH(i * 10.0, 0, 800, 600);
        pipeline.updateViewport(viewport);

        final stopwatch = Stopwatch()..start();
        pipeline.renderFrame(canvas, const Size(800, 600));
        stopwatch.stop();

        secondHalfFrameTimes.add(stopwatch.elapsedMicroseconds / 1000);
      }

      final firstHalfAvg = firstHalfFrameTimes.fold<double>(0, (a, b) => a + b) / firstHalfFrameTimes.length;
      final secondHalfAvg = secondHalfFrameTimes.fold<double>(0, (a, b) => a + b) / secondHalfFrameTimes.length;

      // Performance should not degrade significantly
      final degradation = secondHalfAvg / firstHalfAvg;
      expect(degradation, lessThan(1.2), reason: 'Performance should not degrade >20% over extended panning');

      print('Performance stability: first 50 frames ${firstHalfAvg.toStringAsFixed(1)}ms, '
          'second 50 frames ${secondHalfAvg.toStringAsFixed(1)}ms, '
          'degradation ${((degradation - 1) * 100).toStringAsFixed(1)}%');
    });

    test('Bidirectional panning (left-right-left)', () {
      final frameTimes = <double>[];

      // Pan right for 50 frames
      for (int i = 0; i < 50; i++) {
        final viewport = Rect.fromLTWH(i * 10.0, 0, 800, 600);
        pipeline.updateViewport(viewport);

        final stopwatch = Stopwatch()..start();
        pipeline.renderFrame(canvas, const Size(800, 600));
        stopwatch.stop();

        frameTimes.add(stopwatch.elapsedMicroseconds / 1000);
      }

      // Pan left for 50 frames
      for (int i = 49; i >= 0; i--) {
        final viewport = Rect.fromLTWH(i * 10.0, 0, 800, 600);
        pipeline.updateViewport(viewport);

        final stopwatch = Stopwatch()..start();
        pipeline.renderFrame(canvas, const Size(800, 600));
        stopwatch.stop();

        frameTimes.add(stopwatch.elapsedMicroseconds / 1000);
      }

      final droppedFrames = frameTimes.where((t) => t >= 16).length;
      expect(droppedFrames, equals(0), reason: 'Bidirectional panning should not drop frames');

      print('Bidirectional pan test: 100 frames, $droppedFrames drops');
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
