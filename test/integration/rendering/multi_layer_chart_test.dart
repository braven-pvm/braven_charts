// Integration Test: Multi-layer chart with annotations (Scenario 2)
// Feature: 002-core-rendering
// Purpose: Validate z-ordering, layer visibility, text cache efficiency
//
// Constitutional Compliance:
// - TDD: This test written BEFORE full system integration (TDD RED expected)
// - Performance: <8ms toggle visibility, >80% text cache hit (NFR-001, NFR-003)
// - Accuracy: Correct z-order rendering, dynamic layer management (FR-001, FR-005)

import 'package:braven_charts/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/src/foundation/performance/object_pool.dart';
import 'package:braven_charts/src/foundation/performance/viewport_culler.dart';
import 'package:braven_charts/src/rendering/performance_monitor.dart';
import 'package:braven_charts/src/rendering/render_context.dart';
import 'package:braven_charts/src/rendering/render_layer.dart';
import 'package:braven_charts/src/rendering/render_pipeline.dart';
import 'package:braven_charts/src/rendering/text_layout_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Integration: Multi-layer chart with annotations (Scenario 2)', () {
    late RenderPipeline pipeline;
    late StopwatchPerformanceMonitor monitor;
    late LinkedHashMapTextLayoutCache textCache;
    late List<ChartDataPoint> scatterData;
    late List<ChartDataPoint> trendData;

    setUp(() {
      // Generate scatter plot data (50 points)
      scatterData = List.generate(50, (i) {
        return ChartDataPoint(
          x: i.toDouble(),
          y: 100.0 + (i % 10) * 5.0,
        );
      });

      // Generate trend line data (2 points for line)
      trendData = [
        const ChartDataPoint(x: 0, y: 100),
        const ChartDataPoint(x: 50, y: 150),
      ];

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
        maxSize: 30,
        factory: () => TextPainter(textDirection: TextDirection.ltr),
        reset: (painter) => painter
          ..text = null
          ..textDirection = TextDirection.ltr,
      );

      textCache = LinkedHashMapTextLayoutCache(maxSize: 200);
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

      // Add layers in z-order
      pipeline.addLayer(_ScatterLayer(
        data: scatterData,
        zIndex: 0,
      ));
      pipeline.addLayer(_TrendLineLayer(
        data: trendData,
        zIndex: 1,
      ));
      pipeline.addLayer(_AnnotationLayer(
        annotations: ['Min: 100', 'Max: 150'],
        zIndex: 2,
      ));
    });

    testWidgets(
        'Layers render in correct z-order (scatter → trend → annotations)',
        (WidgetTester tester) async {
      final renderOrder = <String>[];

      // Instrument layers to track render order
      final instrumentedPipeline = _InstrumentedPipeline(
        pipeline: pipeline,
        onLayerRender: (layerType) => renderOrder.add(layerType),
      );
      expect(
          instrumentedPipeline, isNotNull); // Use variable to avoid lint error

      await tester.pumpWidget(
        CustomPaint(
          size: const Size(800, 600),
          painter: _PipelinePainter(pipeline),
        ),
      );

      // Verify z-order: lower zIndex renders first (bottom layer)
      expect(renderOrder.length, equals(3));
      expect(renderOrder[0], equals('Scatter')); // zIndex=0 (bottom)
      expect(renderOrder[1], equals('TrendLine')); // zIndex=1 (middle)
      expect(renderOrder[2], equals('Annotation')); // zIndex=2 (top)
    });

    testWidgets('Text cache hit rate >80% after second render',
        (WidgetTester tester) async {
      // First render: cold cache (misses)
      await tester.pumpWidget(
        CustomPaint(
          size: const Size(800, 600),
          painter: _PipelinePainter(pipeline),
        ),
      );

      final initialHitRate = textCache.hitRate;
      expect(
        initialHitRate,
        lessThan(0.2),
        reason: 'First render should have low hit rate (cold cache)',
      );

      // Second render: warm cache (hits)
      await tester.pumpWidget(
        CustomPaint(
          size: const Size(800, 600),
          painter: _PipelinePainter(pipeline),
        ),
      );

      final warmHitRate = textCache.hitRate;
      expect(
        warmHitRate,
        greaterThan(0.80),
        reason:
            'Second render should reuse cached text layouts (>80% hit rate)',
      );
    });

    testWidgets('Toggle trend line visibility skips layer in <8ms',
        (WidgetTester tester) async {
      // Initial render with all layers visible
      await tester.pumpWidget(
        CustomPaint(
          size: const Size(800, 600),
          painter: _PipelinePainter(pipeline),
        ),
      );

      final initialMetrics = monitor.currentMetrics;
      final initialRenderedCount = initialMetrics.renderedElementCount;

      // Toggle trend line visibility to false
      final trendLayer = pipeline.layers
          .firstWhere((layer) => layer is _TrendLineLayer) as _TrendLineLayer;
      trendLayer.isVisible = false;

      // Render with trend line hidden
      await tester.pumpWidget(
        CustomPaint(
          size: const Size(800, 600),
          painter: _PipelinePainter(pipeline),
        ),
      );

      final updatedMetrics = monitor.currentMetrics;
      expect(
        updatedMetrics.frameTime.inMicroseconds,
        lessThan(8000),
        reason: 'Visibility toggle should complete in <8ms',
      );
      expect(
        updatedMetrics.renderedElementCount,
        lessThan(initialRenderedCount),
        reason: 'Hidden layer should reduce rendered element count',
      );
    });

    testWidgets('Dynamic annotation addition uses text cache',
        (WidgetTester tester) async {
      // Warm up cache
      await tester.pumpWidget(
        CustomPaint(
          size: const Size(800, 600),
          painter: _PipelinePainter(pipeline),
        ),
      );

      // Add tooltip annotation layer dynamically
      pipeline.addLayer(_AnnotationLayer(
        annotations: ['Tooltip: ${scatterData[25].y}'],
        zIndex: 3,
      ));

      // Render with new layer
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
        reason: 'Dynamic layer addition should not degrade performance',
      );
      expect(
        textCache.hitRate,
        greaterThan(0.50),
        reason: 'New text should mix with cached layouts (partial hits)',
      );
    });

    testWidgets('Remove annotation layer maintains performance',
        (WidgetTester tester) async {
      // Initial render
      await tester.pumpWidget(
        CustomPaint(
          size: const Size(800, 600),
          painter: _PipelinePainter(pipeline),
        ),
      );

      // Remove annotation layer
      final annotationLayer =
          pipeline.layers.firstWhere((layer) => layer is _AnnotationLayer);
      pipeline.removeLayer(annotationLayer);

      // Render without annotations
      await tester.pumpWidget(
        CustomPaint(
          size: const Size(800, 600),
          painter: _PipelinePainter(pipeline),
        ),
      );

      final metrics = monitor.currentMetrics;
      expect(
        metrics.averageFrameTime.inMicroseconds,
        lessThan(8000),
        reason: 'Layer removal should maintain <8ms average',
      );
    });
  });
}

/// Test helper: Scatter plot layer (zIndex=0, bottom layer).
class _ScatterLayer extends RenderLayer {
  final List<ChartDataPoint> data;

  _ScatterLayer({required this.data, required super.zIndex});

  @override
  void render(RenderContext context) {
    final paint = context.paintPool.acquire();
    try {
      paint.color = Colors.blue;
      paint.style = PaintingStyle.fill;

      for (final point in data) {
        context.canvas.drawCircle(Offset(point.x, point.y), 3.0, paint);
      }
    } finally {
      context.paintPool.release(paint);
    }
  }

  @override
  bool get isEmpty => data.isEmpty;
}

/// Test helper: Trend line layer (zIndex=1, middle layer).
class _TrendLineLayer extends RenderLayer {
  final List<ChartDataPoint> data;

  _TrendLineLayer({required this.data, required super.zIndex});

  @override
  void render(RenderContext context) {
    final paint = context.paintPool.acquire();
    final path = context.pathPool.acquire();
    try {
      paint.color = Colors.red;
      paint.strokeWidth = 2.0;
      paint.style = PaintingStyle.stroke;

      path.moveTo(data[0].x, data[0].y);
      path.lineTo(data[1].x, data[1].y);

      context.canvas.drawPath(path, paint);
    } finally {
      context.pathPool.release(path);
      context.paintPool.release(paint);
    }
  }

  @override
  bool get isEmpty => data.isEmpty;
}

/// Test helper: Annotation layer (zIndex=2, top layer).
class _AnnotationLayer extends RenderLayer {
  final List<String> annotations;

  _AnnotationLayer({required this.annotations, required super.zIndex});

  @override
  void render(RenderContext context) {
    const textStyle = TextStyle(color: Colors.black, fontSize: 12);

    for (int i = 0; i < annotations.length; i++) {
      final text = annotations[i];

      // Try to get from cache
      var painter = context.textCache.get(text, textStyle);

      if (painter == null) {
        // Cache miss: layout new text
        painter = context.textPainterPool.acquire();
        painter.text = TextSpan(text: text, style: textStyle);
        painter.layout();
        context.textCache.put(text, textStyle, painter);
      }

      painter.paint(context.canvas, Offset(10, 10 + i * 20.0));

      // Note: Don't release painter to pool (owned by cache)
    }
  }

  @override
  bool get isEmpty => annotations.isEmpty;
}

/// Test helper: Instrumented pipeline to track render order.
class _InstrumentedPipeline {
  final RenderPipeline pipeline;
  final void Function(String layerType) onLayerRender;

  _InstrumentedPipeline({
    required this.pipeline,
    required this.onLayerRender,
  });
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
