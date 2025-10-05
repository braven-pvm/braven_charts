// Integration Test: Text-heavy chart (Scenario 4)
// Feature: 002-core-rendering
// Purpose: Validate text layout caching, memory bounds, cache eviction
//
// Constitutional Compliance:
// - TDD: This test written BEFORE full system integration (TDD RED expected)
// - Performance: <50ms initial layout, >70% cache hit rate (NFR-003, FR-003)
// - Memory: Bounded cache eviction, no unbounded growth

import 'package:braven_charts/src/foundation/chart_data_point.dart';
import 'package:braven_charts/src/foundation/object_pool.dart';
import 'package:braven_charts/src/foundation/viewport_culler.dart';
import 'package:braven_charts/src/rendering/performance_monitor.dart';
import 'package:braven_charts/src/rendering/render_context.dart';
import 'package:braven_charts/src/rendering/render_layer.dart';
import 'package:braven_charts/src/rendering/render_pipeline.dart';
import 'package:braven_charts/src/rendering/text_layout_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Integration: Text-heavy chart (Scenario 4)', () {
    late RenderPipeline pipeline;
    late LinkedHashMapTextLayoutCache textCache;
    late StopwatchPerformanceMonitor monitor;
    late List<ChartDataPoint> barData;
    late List<String> categoryNames;

    setUp(() {
      // Generate bar chart data (50 bars with value labels)
      barData = List.generate(50, (i) {
        return ChartDataPoint(
          x: i.toDouble(),
          y: 50.0 + (i % 20) * 2.5,
        );
      });

      // Generate legend category names (10 categories)
      categoryNames = List.generate(10, (i) => 'Category ${i + 1}');

      // Initialize rendering infrastructure
      final paintPool = ObjectPool<Paint>(
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
        maxSize: 100,
        factory: () => TextPainter(textDirection: TextDirection.ltr),
        reset: (painter) => painter
          ..text = null
          ..textDirection = TextDirection.ltr,
      );

      textCache = LinkedHashMapTextLayoutCache(maxSize: 200);
      monitor = StopwatchPerformanceMonitor(maxHistorySize: 120);
      final culler = ViewportCuller();

      pipeline = RenderPipeline(
        paintPool: paintPool,
        pathPool: pathPool,
        textPainterPool: textPainterPool,
        textCache: textCache,
        performanceMonitor: monitor,
        culler: culler,
        initialViewport: const Rect.fromLTWH(0, 0, 800, 600),
      );

      // Add bar chart layer with value labels (50 text labels)
      pipeline.addLayer(_BarChartLayer(
        data: barData,
        zIndex: 0,
      ));

      // Add legend layer with category names (10 text labels)
      pipeline.addLayer(_LegendLayer(
        categories: categoryNames,
        zIndex: 1,
      ));
    });

    testWidgets('Initial text layout completes in <50ms', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        CustomPaint(
          size: const Size(800, 600),
          painter: _PipelinePainter(pipeline),
        ),
      );

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'Initial text layout (60 labels) should complete in <50ms',
      );
    });

    testWidgets('Text cache hit rate >70% on second frame', (WidgetTester tester) async {
      // First render: cold cache (all misses)
      await tester.pumpWidget(
        CustomPaint(
          size: const Size(800, 600),
          painter: _PipelinePainter(pipeline),
        ),
      );

      final initialHitRate = textCache.hitRate;
      expect(
        initialHitRate,
        lessThan(0.1),
        reason: 'Cold cache should have low hit rate (initial layout)',
      );

      // Second render: warm cache (hits on repeated text)
      await tester.pumpWidget(
        CustomPaint(
          size: const Size(800, 600),
          painter: _PipelinePainter(pipeline),
        ),
      );

      final warmHitRate = textCache.hitRate;
      expect(
        warmHitRate,
        greaterThan(0.70),
        reason: 'Second render should have >70% cache hit rate (NFR-003)',
      );
    });

    testWidgets('Cached layouts reused for repeated text after pan', (WidgetTester tester) async {
      // Initial render
      await tester.pumpWidget(
        CustomPaint(
          size: const Size(800, 600),
          painter: _PipelinePainter(pipeline),
        ),
      );

      // Simulate pan (labels change positions but text same)
      pipeline.updateViewport(const Rect.fromLTWH(100, 0, 800, 600));

      await tester.pumpWidget(
        CustomPaint(
          size: const Size(800, 600),
          painter: _PipelinePainter(pipeline),
        ),
      );

      final hitRateAfterPan = textCache.hitRate;
      expect(
        hitRateAfterPan,
        greaterThan(0.50),
        reason: 'Pan should reuse cached text layouts (partial hits)',
      );
    });

    testWidgets('Cache eviction maintains bounded memory', (WidgetTester tester) async {
      // Render initial frame (populate cache)
      await tester.pumpWidget(
        CustomPaint(
          size: const Size(800, 600),
          painter: _PipelinePainter(pipeline),
        ),
      );

      final initialCacheSize = textCache.length;
      expect(
        initialCacheSize,
        greaterThan(0),
        reason: 'Cache should have entries after first render',
      );
      expect(
        initialCacheSize,
        lessThanOrEqualTo(textCache.maxSize),
        reason: 'Cache should not exceed maxSize',
      );

      // Add many new text labels to trigger eviction
      final newCategories = List.generate(300, (i) => 'NewCat $i');
      pipeline.addLayer(_LegendLayer(
        categories: newCategories,
        zIndex: 2,
      ));

      await tester.pumpWidget(
        CustomPaint(
          size: const Size(800, 600),
          painter: _PipelinePainter(pipeline),
        ),
      );

      final finalCacheSize = textCache.length;
      expect(
        finalCacheSize,
        lessThanOrEqualTo(textCache.maxSize),
        reason: 'Cache should evict old entries to maintain maxSize bound',
      );
    });

    testWidgets('Performance remains stable with text-heavy rendering', (WidgetTester tester) async {
      // Render 30 frames with text-heavy content
      for (int i = 0; i < 30; i++) {
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
        reason: 'Text-heavy rendering should maintain <8ms average',
      );
      expect(
        metrics.jankCount,
        equals(0),
        reason: 'No frames should jank with text caching',
      );
    });
  });
}

/// Test helper: Bar chart layer with value labels.
class _BarChartLayer extends RenderLayer {
  final List<ChartDataPoint> data;

  _BarChartLayer({required this.data, required int zIndex}) : super(zIndex: zIndex);

  @override
  void render(RenderContext context) {
    const textStyle = TextStyle(color: Colors.black, fontSize: 10);
    const barWidth = 10.0;

    for (int i = 0; i < data.length; i++) {
      final point = data[i];

      // Draw bar
      final paint = context.paintPool.acquire();
      try {
        paint.color = Colors.blue;
        paint.style = PaintingStyle.fill;
        final rect = Rect.fromLTWH(point.x, 600 - point.y, barWidth, point.y);
        context.canvas.drawRect(rect, paint);
      } finally {
        context.paintPool.release(paint);
      }

      // Draw value label (with caching)
      final labelText = point.y.toStringAsFixed(1);
      var painter = context.textCache.get(labelText, textStyle);

      if (painter == null) {
        painter = context.textPainterPool.acquire();
        painter.text = TextSpan(text: labelText, style: textStyle);
        painter.layout();
        context.textCache.put(labelText, textStyle, painter);
      }

      painter.paint(
        context.canvas,
        Offset(point.x, 600 - point.y - 15),
      );
    }
  }

  @override
  bool get isEmpty => data.isEmpty;
}

/// Test helper: Legend layer with category names.
class _LegendLayer extends RenderLayer {
  final List<String> categories;

  _LegendLayer({required this.categories, required int zIndex}) : super(zIndex: zIndex);

  @override
  void render(RenderContext context) {
    const textStyle = TextStyle(color: Colors.black, fontSize: 12);

    for (int i = 0; i < categories.length; i++) {
      final text = categories[i];
      var painter = context.textCache.get(text, textStyle);

      if (painter == null) {
        painter = context.textPainterPool.acquire();
        painter.text = TextSpan(text: text, style: textStyle);
        painter.layout();
        context.textCache.put(text, textStyle, painter);
      }

      painter.paint(
        context.canvas,
        Offset(650, 10 + i * 20.0),
      );
    }
  }

  @override
  bool get isEmpty => categories.isEmpty;
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
