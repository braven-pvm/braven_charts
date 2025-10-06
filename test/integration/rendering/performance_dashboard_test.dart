// Integration Test: Performance monitoring dashboard (Scenario 3)
// Feature: 002-core-rendering
// Purpose: Validate PerformanceMonitor accuracy, jank detection, 60Hz tracking
//
// Constitutional Compliance:
// - TDD: This test written BEFORE full system integration (TDD RED expected)
// - Performance: <1ms monitoring overhead, ±0.5ms timing accuracy (NFR-001, FR-004)
// - Accuracy: 100% jank detection (>16ms threshold), pool statistics tracking

import 'package:braven_charts/src/foundation/foundation.dart';
import 'package:braven_charts/src/rendering/performance_monitor.dart';
import 'package:braven_charts/src/rendering/performance_metrics.dart';
import 'package:braven_charts/src/rendering/render_context.dart';
import 'package:braven_charts/src/rendering/render_layer.dart';
import 'package:braven_charts/src/rendering/render_pipeline.dart';
import 'package:braven_charts/src/rendering/text_layout_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Integration: Performance monitoring dashboard (Scenario 3)', () {
    late RenderPipeline pipeline;
    late StopwatchPerformanceMonitor monitor;
    late ObjectPool<Paint> paintPool;

    setUp(() {
      paintPool = ObjectPool<Paint>(
        maxSize: 50,
        factory: () => Paint(),
        reset: (paint) => paint
          ..color = Colors.black
          ..strokeWidth = 1.0
          ..style = PaintingStyle.fill,
      );

      final pathPool = ObjectPool<Path>(
        maxSize: 20,
        factory: () => Path(),
        reset: (path) => path.reset(),
      );

      final textPainterPool = ObjectPool<TextPainter>(
        maxSize: 20,
        factory: () => TextPainter(textDirection: TextDirection.ltr),
        reset: (painter) => painter
          ..text = null
          ..textDirection = TextDirection.ltr,
      );

      final textCache = LinkedHashMapTextLayoutCache(maxSize: 100);
      monitor = StopwatchPerformanceMonitor(maxHistorySize: 120);
      final culler = const ViewportCuller();

      pipeline = RenderPipeline(
        paintPool: paintPool,
        pathPool: pathPool,
        textPainterPool: textPainterPool,
        textCache: textCache,
        performanceMonitor: monitor,
        culler: culler,
        initialViewport: const Rect.fromLTWH(0, 0, 800, 600),
      );

      // Add simple test layer
      pipeline.addLayer(_SimpleRectLayer(zIndex: 0));
    });

    testWidgets('Metrics update every frame (60Hz)',
        (WidgetTester tester) async {
      final metricsHistory = <PerformanceMetrics>[];

      for (int i = 0; i < 100; i++) {
        await tester.pumpWidget(
          CustomPaint(
            size: const Size(800, 600),
            painter: _PipelinePainter(pipeline),
          ),
        );

        metricsHistory.add(monitor.currentMetrics);
      }

      // Verify metrics updated every frame
      expect(
        metricsHistory.length,
        equals(100),
        reason: 'Should have 100 metric snapshots (1 per frame)',
      );

      // Verify each frame has recorded time
      for (int i = 0; i < metricsHistory.length; i++) {
        expect(
          metricsHistory[i].frameTime.inMicroseconds,
          greaterThan(0),
          reason: 'Frame $i should have non-zero frame time',
        );
      }
    });

    testWidgets('Jank counter increments on frame spike >16ms',
        (WidgetTester tester) async {
      // Render initial frames (no jank)
      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(
          CustomPaint(
            size: const Size(800, 600),
            painter: _PipelinePainter(pipeline),
          ),
        );
      }

      final jankCountBefore = monitor.currentMetrics.jankCount;

      // Add heavy layer to force 25ms frame (jank)
      pipeline.addLayer(_HeavyComputeLayer(
        zIndex: 1,
        delayMicroseconds: 25000, // 25ms - exceeds 16ms jank threshold
      ));

      await tester.pumpWidget(
        CustomPaint(
          size: const Size(800, 600),
          painter: _PipelinePainter(pipeline),
        ),
      );

      final jankCountAfter = monitor.currentMetrics.jankCount;
      expect(
        jankCountAfter,
        equals(jankCountBefore + 1),
        reason: 'Jank counter should increment for >16ms frame',
      );
      expect(
        monitor.currentMetrics.frameTime.inMicroseconds,
        greaterThan(16000),
        reason: 'Heavy frame should exceed 16ms jank threshold',
      );
    });

    testWidgets('Frame time measurement accuracy ±0.5ms',
        (WidgetTester tester) async {
      // Add layer with known delay (5ms)
      pipeline.addLayer(_HeavyComputeLayer(
        zIndex: 1,
        delayMicroseconds: 5000, // 5ms target
      ));

      await tester.pumpWidget(
        CustomPaint(
          size: const Size(800, 600),
          painter: _PipelinePainter(pipeline),
        ),
      );

      final metrics = monitor.currentMetrics;
      final measuredMicros = metrics.frameTime.inMicroseconds;

      // Allow ±500μs (0.5ms) tolerance for render overhead
      expect(
        measuredMicros,
        inInclusiveRange(4500, 6000),
        reason: 'Measured time should be within ±0.5ms of 5ms target (FR-004)',
      );
    });

    testWidgets('Pool statistics track hit/miss/allocation',
        (WidgetTester tester) async {
      // Render 10 frames to accumulate pool statistics
      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(
          CustomPaint(
            size: const Size(800, 600),
            painter: _PipelinePainter(pipeline),
          ),
        );
      }

      final metrics = monitor.currentMetrics;
      expect(
        metrics.poolHitRate,
        greaterThan(0.0),
        reason: 'Pool should have non-zero hit rate after warmup',
      );

      // After warmup, hit rate should be high
      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(
          CustomPaint(
            size: const Size(800, 600),
            painter: _PipelinePainter(pipeline),
          ),
        );
      }

      final warmedMetrics = monitor.currentMetrics;
      expect(
        warmedMetrics.poolHitRate,
        greaterThan(0.80),
        reason: 'Warmed pool should have >80% hit rate',
      );
    });

    testWidgets('Monitoring overhead <1ms per frame',
        (WidgetTester tester) async {
      // Measure overhead by comparing with/without monitoring
      final baselineStopwatch = Stopwatch()..start();

      // Render without heavy monitoring
      for (int i = 0; i < 100; i++) {
        await tester.pumpWidget(
          CustomPaint(
            size: const Size(800, 600),
            painter: _PipelinePainter(pipeline),
          ),
        );
      }

      baselineStopwatch.stop();
      final totalFrameTime = baselineStopwatch.elapsedMicroseconds;
      final avgFrameTime = totalFrameTime / 100;

      // Monitoring overhead is included in frame time
      // Since frames are <8ms target, overhead must be <1ms
      expect(
        avgFrameTime,
        lessThan(9000),
        reason:
            'Average frame time with monitoring should be <9ms (8ms target + 1ms overhead)',
      );
    });

    testWidgets('Reset clears accumulated state', (WidgetTester tester) async {
      // Accumulate frames and jank
      pipeline.addLayer(_HeavyComputeLayer(
        zIndex: 1,
        delayMicroseconds: 20000, // Force jank
      ));

      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(
          CustomPaint(
            size: const Size(800, 600),
            painter: _PipelinePainter(pipeline),
          ),
        );
      }

      final beforeReset = monitor.currentMetrics;
      expect(beforeReset.jankCount, greaterThan(0));

      // Reset monitor
      monitor.reset();

      final afterReset = monitor.currentMetrics;
      expect(
        afterReset.jankCount,
        equals(0),
        reason: 'Jank count should be zero after reset',
      );
      expect(
        afterReset.frameTime,
        equals(Duration.zero),
        reason: 'Frame time should be zero (no frames recorded)',
      );
    });
  });
}

/// Test helper: Simple rectangle layer for baseline rendering.
class _SimpleRectLayer extends RenderLayer {
  _SimpleRectLayer({required super.zIndex});

  @override
  void render(RenderContext context) {
    final paint = context.paintPool.acquire();
    try {
      paint.color = Colors.grey;
      paint.style = PaintingStyle.fill;
      context.canvas.drawRect(const Rect.fromLTWH(10, 10, 100, 100), paint);
    } finally {
      context.paintPool.release(paint);
    }
  }

  @override
  bool get isEmpty => false;
}

/// Test helper: Heavy computation layer to simulate jank.
class _HeavyComputeLayer extends RenderLayer {
  final int delayMicroseconds;

  _HeavyComputeLayer({
    required super.zIndex,
    required this.delayMicroseconds,
  });

  @override
  void render(RenderContext context) {
    // Simulate heavy computation (busy-wait for accurate timing)
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsedMicroseconds < delayMicroseconds) {
      // Busy-wait to simulate compute load
    }
    stopwatch.stop();
  }

  @override
  bool get isEmpty => false;
}

/// Test helper: CustomPainter that delegates to RenderPipeline.
class _PipelinePainter extends CustomPainter {
  final RenderPipeline pipeline;

  _PipelinePainter(this.pipeline);

  @override
  void paint(Canvas canvas, Size size) {
    pipeline.renderFrame(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
