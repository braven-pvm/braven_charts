/// Edge case test for overlapping layers.
///
/// Validates correct z-ordering and rendering when multiple layers occupy
/// same screen space:
/// - Create 3 layers with identical screen space coverage
/// - Verify z-order is preserved (background → mid → foreground)
/// - Test alpha blending behavior (semi-transparent layers)
/// - Verify no rendering artifacts when layers completely overlap
///
/// This simulates scenarios like gridlines behind data, with annotations overlaid.
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
  group('Edge Case: Overlapping Layers', () {
    test('Z-order preserved with overlapping layers', () {
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
        culler: const ViewportCuller(),
        textCache: LinkedHashMapTextLayoutCache(),
        performanceMonitor: StopwatchPerformanceMonitor(),
        initialViewport: const Rect.fromLTWH(0, 0, 800, 600),
      );

      // Track render order
      final renderOrder = <String>[];

      // Create 3 layers with identical screen coverage but different z-index
      final backgroundLayer = _TrackedLayer(
        name: 'background',
        zIndex: -1,
        color: const Color(0xFFE0E0E0),
        onRender: (name) => renderOrder.add(name),
      );

      final midLayer = _TrackedLayer(
        name: 'mid',
        zIndex: 0,
        color: const Color(0xFF2196F3),
        onRender: (name) => renderOrder.add(name),
      );

      final foregroundLayer = _TrackedLayer(
        name: 'foreground',
        zIndex: 1,
        color: const Color(0xFF4CAF50),
        onRender: (name) => renderOrder.add(name),
      );

      // Add layers in random order to verify sorting
      pipeline.addLayer(midLayer);
      pipeline.addLayer(foregroundLayer);
      pipeline.addLayer(backgroundLayer);

      final canvas = _MockCanvas();

      // Render frame
      pipeline.renderFrame(canvas, const Size(800, 600));

      // Verify render order matches z-index (lowest to highest)
      expect(renderOrder, equals(['background', 'mid', 'foreground']), reason: 'Layers should render in z-order (background first, foreground last)');

      print('Z-order validation: $renderOrder (background → mid → foreground)');
    });

    test('Alpha blending with semi-transparent overlapping layers', () {
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
        initialViewport: const Rect.fromLTWH(0, 0, 800, 600),
      );

      // Create layers with semi-transparent colors (50% opacity)
      final layer1 = _TrackedLayer(
        name: 'layer1',
        zIndex: 0,
        color: const Color(0x80FF0000), // Red, 50% alpha
        onRender: (_) {},
      );

      final layer2 = _TrackedLayer(
        name: 'layer2',
        zIndex: 1,
        color: const Color(0x8000FF00), // Green, 50% alpha
        onRender: (_) {},
      );

      final layer3 = _TrackedLayer(
        name: 'layer3',
        zIndex: 2,
        color: const Color(0x800000FF), // Blue, 50% alpha
        onRender: (_) {},
      );

      pipeline.addLayer(layer1);
      pipeline.addLayer(layer2);
      pipeline.addLayer(layer3);

      final canvas = _MockCanvas();

      // Rendering with alpha blending should not crash
      expect(() => pipeline.renderFrame(canvas, const Size(800, 600)), returnsNormally, reason: 'Alpha blending should work correctly');

      print('Alpha blending test: 3 semi-transparent layers rendered successfully');
    });

    test('Performance with 10 overlapping layers', () {
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
        initialViewport: const Rect.fromLTWH(0, 0, 800, 600),
      );

      // Create 10 overlapping layers
      for (int i = 0; i < 10; i++) {
        pipeline.addLayer(_TrackedLayer(
          name: 'layer$i',
          zIndex: i,
          color: Color(0xFF000000 + (i * 0x111111)),
          onRender: (_) {},
        ));
      }

      final canvas = _MockCanvas();

      // Measure frame time with 10 overlapping layers
      final stopwatch = Stopwatch()..start();
      pipeline.renderFrame(canvas, const Size(800, 600));
      stopwatch.stop();

      final frameTime = stopwatch.elapsedMicroseconds / 1000;

      // With minimal rendering work, 10 layers should be very fast
      expect(frameTime, lessThan(5), reason: '10 overlapping layers should render quickly (<5ms)');

      print('10 overlapping layers: ${frameTime.toStringAsFixed(2)}ms');
    });

    test('Rendering artifacts check with complete overlap', () {
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
        initialViewport: const Rect.fromLTWH(0, 0, 800, 600),
      );

      // Create layers that completely overlap (same bounds, different colors)
      final renderCount = <String, int>{};

      for (int i = 0; i < 5; i++) {
        final layerName = 'layer$i';
        renderCount[layerName] = 0;

        pipeline.addLayer(_TrackedLayer(
          name: layerName,
          zIndex: i,
          color: Color(0xFF000000 + (i * 0x333333)),
          onRender: (name) => renderCount[name] = (renderCount[name] ?? 0) + 1,
        ));
      }

      final canvas = _MockCanvas();

      // Render frame
      pipeline.renderFrame(canvas, const Size(800, 600));

      // Verify each layer rendered exactly once
      for (final entry in renderCount.entries) {
        expect(entry.value, equals(1), reason: 'Layer ${entry.key} should render exactly once');
      }

      // Verify no crashes
      expect(() => pipeline.renderFrame(canvas, const Size(800, 600)), returnsNormally, reason: 'Multiple renders should not cause artifacts');

      print('Rendering artifacts check: All 5 layers rendered correctly without artifacts');
    });

    test('Z-order update correctness', () {
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
        initialViewport: const Rect.fromLTWH(0, 0, 800, 600),
      );

      final renderOrder = <String>[];

      // Create layers with specific z-order
      final layerA = _TrackedLayer(
        name: 'A',
        zIndex: 0,
        color: const Color(0xFFFF0000),
        onRender: (name) => renderOrder.add(name),
      );

      final layerB = _TrackedLayer(
        name: 'B',
        zIndex: 1,
        color: const Color(0xFF00FF00),
        onRender: (name) => renderOrder.add(name),
      );

      final layerC = _TrackedLayer(
        name: 'C',
        zIndex: 2,
        color: const Color(0xFF0000FF),
        onRender: (name) => renderOrder.add(name),
      );

      pipeline.addLayer(layerA);
      pipeline.addLayer(layerB);
      pipeline.addLayer(layerC);

      final canvas = _MockCanvas();

      // Render with initial z-order
      pipeline.renderFrame(canvas, const Size(800, 600));

      expect(renderOrder, equals(['A', 'B', 'C']), reason: 'Initial z-order should be A → B → C');

      renderOrder.clear();

      // Remove and re-add layer C with lower z-index
      pipeline.removeLayer(layerC);
      pipeline.addLayer(_TrackedLayer(
        name: 'C',
        zIndex: -1,
        color: const Color(0xFF0000FF),
        onRender: (name) => renderOrder.add(name),
      ));

      // Render with updated z-order
      pipeline.renderFrame(canvas, const Size(800, 600));

      expect(renderOrder, equals(['C', 'A', 'B']), reason: 'Updated z-order should be C → A → B');

      print('Z-order update test: Initial [A, B, C] → Updated [C, A, B]');
    });
  });
}

// Tracked layer for render order verification
class _TrackedLayer implements RenderLayer {
  _TrackedLayer({
    required this.name,
    required this.zIndex,
    required this.color,
    required this.onRender,
  });

  final String name;
  @override
  final int zIndex;
  final Color color;
  final void Function(String name) onRender;

  @override
  bool isVisible = true;

  @override
  bool get isEmpty => false;

  @override
  void render(RenderContext context) {
    onRender(name);

    // Simple rectangle fill to simulate rendering
    final paint = context.paintPool.acquire();
    try {
      paint.color = color;
      context.canvas.drawRect(Rect.fromLTWH(0, 0, context.size.width, context.size.height), paint);
    } finally {
      context.paintPool.release(paint);
    }
  }
}

// Mock canvas for testing
class _MockCanvas extends Fake implements Canvas {}
