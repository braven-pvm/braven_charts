// Integration Test: Real-time Stock Chart with 10K+ points (Scenario 1)
// Feature: 002-core-rendering
// Purpose: Validate viewport culling, pool efficiency, and <8ms frame time
//
// Constitutional Compliance:
// - TDD: This test written BEFORE full system integration (TDD RED expected)
// - Performance: <16ms initial render, <8ms average over 60 frames (NFR-001)
// - Accuracy: Pool hit rate >90%, culling reduces visible points (FR-002, FR-003)

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:braven_charts/src/foundation/chart_data_point.dart';
import 'package:braven_charts/src/foundation/object_pool.dart';
import 'package:braven_charts/src/foundation/viewport_culler.dart';
import 'package:braven_charts/src/rendering/render_context.dart';
import 'package:braven_charts/src/rendering/render_layer.dart';
import 'package:braven_charts/src/rendering/render_pipeline.dart';
import 'package:braven_charts/src/rendering/performance_monitor.dart';
import 'package:braven_charts/src/rendering/text_layout_cache.dart';

void main() {
  group('Integration: Real-time Stock Chart with 10K+ points (Scenario 1)', () {
    late List<ChartDataPoint> stockData;
    late RenderPipeline pipeline;
    late StopwatchPerformanceMonitor monitor;
    late ObjectPool<Paint> paintPool;
    late ObjectPool<Path> pathPool;
    late ObjectPool<TextPainter> textPainterPool;
    late TextLayoutCache textCache;
    late ViewportCuller culler;

    setUp(() {
      // Generate 10,000 stock price data points
      stockData = List.generate(10000, (i) {
        return ChartDataPoint(
          x: i.toDouble(),
          y: 100.0 + (i % 100) * 0.5, // Simulated price variation
        );
      });

      // Initialize pools with realistic sizes
      paintPool = ObjectPool<Paint>(
        maxSize: 100,
        factory: () => Paint(),
        reset: (paint) => paint
          ..color = Colors.black
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke,
      );

      pathPool = ObjectPool<Path>(
        maxSize: 50,
        factory: () => Path(),
        reset: (path) => path.reset(),
      );

      textPainterPool = ObjectPool<TextPainter>(
        maxSize: 50,
        factory: () => TextPainter(
          textDirection: TextDirection.ltr,
        ),
        reset: (painter) => painter
          ..text = null
          ..textDirection = TextDirection.ltr,
      );

      textCache = LinkedHashMapTextLayoutCache(maxSize: 500);
      culler = ViewportCuller();
      monitor = StopwatchPerformanceMonitor(maxHistorySize: 120);

      // Create pipeline with initial viewport showing first 500 points
      final initialViewport = Rect.fromLTWH(0, 0, 500, 200);
      pipeline = RenderPipeline(
        paintPool: paintPool,
        pathPool: pathPool,
        textPainterPool: textPainterPool,
        textCache: textCache,
        performanceMonitor: monitor,
        culler: culler,
        initialViewport: initialViewport,
      );

      // Add stock data layer
      final stockLayer = _StockDataLayer(
        data: stockData,
        zIndex: 0,
      );
      pipeline.addLayer(stockLayer);
    });

    testWidgets('Initial render with 500 visible points completes in <16ms (no jank)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        CustomPaint(
          size: const Size(800, 600),
          painter: _PipelinePainter(pipeline),
        ),
      );

      final metrics = monitor.currentMetrics;
      expect(
        metrics.frameTime.inMicroseconds,
        lessThan(16000),
        reason: 'Initial render must not jank (60fps = 16.67ms budget)',
      );
      expect(
        metrics.jankCount,
        equals(0),
        reason: 'No frames should exceed 16ms threshold',
      );
    });

    testWidgets('Viewport culling reduces render to ~500 points after pan',
        (WidgetTester tester) async {
      // Initial render
      await tester.pumpWidget(
        CustomPaint(
          size: const Size(800, 600),
          painter: _PipelinePainter(pipeline),
        ),
      );

      // Pan left by 1000 units (shift viewport to x=1000-1500)
      pipeline.updateViewport(Rect.fromLTWH(1000, 0, 500, 200));

      await tester.pumpWidget(
        CustomPaint(
          size: const Size(800, 600),
          painter: _PipelinePainter(pipeline),
        ),
      );

      final metrics = monitor.currentMetrics;
      expect(
        metrics.culledElementCount,
        greaterThan(9000),
        reason: 'Should cull ~9500 points outside viewport (10K - 500 visible)',
      );
      expect(
        metrics.renderedElementCount,
        lessThan(1000),
        reason: 'Should render ~500 visible points + margins',
      );
    });

    testWidgets('Zoom in to 50 visible points maintains <8ms frame time',
        (WidgetTester tester) async {
      // Initial render
      await tester.pumpWidget(
        CustomPaint(
          size: const Size(800, 600),
          painter: _PipelinePainter(pipeline),
        ),
      );

      // Zoom in: reduce viewport width to show only 50 points
      pipeline.updateViewport(Rect.fromLTWH(0, 0, 50, 200));

      await tester.pumpWidget(
        CustomPaint(
          size: const Size(800, 600),
          painter: _PipelinePainter(pipeline),
        ),
      );

      final metrics = monitor.currentMetrics;
      expect(
        metrics.frameTime.inMicroseconds,
        lessThan(8000),
        reason: 'Zoomed render with 50 points should be <8ms (target: <8ms avg)',
      );
    });

    testWidgets('Pool hit rate >90% over 60 frames', (WidgetTester tester) async {
      for (int i = 0; i < 60; i++) {
        await tester.pumpWidget(
          CustomPaint(
            size: const Size(800, 600),
            painter: _PipelinePainter(pipeline),
          ),
        );

        // Simulate slight pan each frame (realistic interaction)
        pipeline.updateViewport(Rect.fromLTWH(i * 5.0, 0, 500, 200));
      }

      final metrics = monitor.currentMetrics;
      expect(
        metrics.poolHitRate,
        greaterThan(0.90),
        reason: 'Pool reuse should exceed 90% after warmup (NFR-002)',
      );
    });

    testWidgets('Average frame time <8ms over 60 frames', (WidgetTester tester) async {
      for (int i = 0; i < 60; i++) {
        await tester.pumpWidget(
          CustomPaint(
            size: const Size(800, 600),
            painter: _PipelinePainter(pipeline),
          ),
        );
      }

      final metrics = monitor.currentMetrics;
      expect(
        metrics.averageFrameTime.inMicroseconds,
        lessThan(8000),
        reason: 'Average frame time must meet <8ms target (NFR-001)',
      );
      expect(
        metrics.p99FrameTime.inMicroseconds,
        lessThan(16000),
        reason: 'P99 frame time should not jank (60fps budget)',
      );
    });
  });
}

/// Test helper: Minimal stock data layer for integration testing.
class _StockDataLayer extends RenderLayer {
  final List<ChartDataPoint> data;

  _StockDataLayer({
    required this.data,
    required int zIndex,
  }) : super(zIndex: zIndex);

  @override
  void render(RenderContext context) {
    // Cull points outside viewport
    final visiblePoints = context.culler.cullPoints(
      points: data,
      viewport: context.viewport,
    );

    if (visiblePoints.isEmpty) return;

    // Acquire paint from pool
    final paint = context.paintPool.acquire();
    try {
      paint.color = Colors.blue;
      paint.strokeWidth = 2.0;
      paint.style = PaintingStyle.stroke;

      // Acquire path from pool
      final path = context.pathPool.acquire();
      try {
        // Build line path through visible points
        path.moveTo(visiblePoints.first.x, visiblePoints.first.y);
        for (int i = 1; i < visiblePoints.length; i++) {
          path.lineTo(visiblePoints[i].x, visiblePoints[i].y);
        }

        context.canvas.drawPath(path, paint);
      } finally {
        context.pathPool.release(path);
      }
    } finally {
      context.paintPool.release(paint);
    }
  }

  @override
  bool get isEmpty => data.isEmpty;
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
