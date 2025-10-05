// Unit Tests: RenderPipeline Layer Management
// Feature: 002-core-rendering
// Task: T021
// Purpose: Validate layer management (add/remove), z-ordering, visibility

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/src/foundation/performance/object_pool.dart';
import '../../../lib/src/foundation/performance/viewport_culler.dart';
import '../../../lib/src/rendering/performance_monitor.dart';
import '../../../lib/src/rendering/render_context.dart';
import '../../../lib/src/rendering/render_layer.dart';
import '../../../lib/src/rendering/render_pipeline.dart';
import '../../../lib/src/rendering/text_layout_cache.dart';

void main() {
  // Helper to create test pipeline
  RenderPipeline createPipeline() {
    return RenderPipeline(
      paintPool: ObjectPool<Paint>(factory: () => Paint(), reset: (p) {}),
      pathPool: ObjectPool<Path>(factory: () => Path(), reset: (p) => p.reset()),
      textPainterPool: ObjectPool<TextPainter>(factory: () => TextPainter(), reset: (tp) {}),
      textCache: LinkedHashMapTextLayoutCache(),
      performanceMonitor: StopwatchPerformanceMonitor(),
      culler: const ViewportCuller(),
      initialViewport: Rect.fromLTWH(0, 0, 800, 600),
    );
  }

  group('RenderPipeline - Layer Management', () {
    test('addLayer adds layer to pipeline', () {
      final pipeline = createPipeline();
      final layer = _TestLayer(zIndex: 0);

      pipeline.addLayer(layer);

      expect(pipeline.layers.length, equals(1));
      expect(pipeline.layers.first, equals(layer));
    });

    test('addLayer multiple layers increases count', () {
      final pipeline = createPipeline();
      final layer1 = _TestLayer(zIndex: 0);
      final layer2 = _TestLayer(zIndex: 1);
      final layer3 = _TestLayer(zIndex: 2);

      pipeline.addLayer(layer1);
      pipeline.addLayer(layer2);
      pipeline.addLayer(layer3);

      expect(pipeline.layers.length, equals(3));
    });

    test('addLayer maintains z-order sort', () {
      final pipeline = createPipeline();
      final layer1 = _TestLayer(zIndex: 5, name: 'Layer5');
      final layer2 = _TestLayer(zIndex: 1, name: 'Layer1');
      final layer3 = _TestLayer(zIndex: 3, name: 'Layer3');

      pipeline.addLayer(layer1);
      pipeline.addLayer(layer2);
      pipeline.addLayer(layer3);

      // Render to trigger sort
      final canvas = _RecordingCanvas();
      pipeline.renderFrame(canvas, const Size(800, 600));

      // Verify render order (sorted by zIndex)
      expect(canvas.renderOrder.length, equals(3));
      expect(canvas.renderOrder[0], equals('Layer1')); // zIndex=1
      expect(canvas.renderOrder[1], equals('Layer3')); // zIndex=3
      expect(canvas.renderOrder[2], equals('Layer5')); // zIndex=5
    });

    test('removeLayer removes correct layer', () {
      final pipeline = createPipeline();
      final layer1 = _TestLayer(zIndex: 0, name: 'Keep1');
      final layer2 = _TestLayer(zIndex: 1, name: 'Remove');
      final layer3 = _TestLayer(zIndex: 2, name: 'Keep2');

      pipeline.addLayer(layer1);
      pipeline.addLayer(layer2);
      pipeline.addLayer(layer3);

      pipeline.removeLayer(layer2);

      expect(pipeline.layers.length, equals(2));
      expect(pipeline.layers.contains(layer1), isTrue);
      expect(pipeline.layers.contains(layer2), isFalse);
      expect(pipeline.layers.contains(layer3), isTrue);
    });

    test('removeLayer on empty pipeline is no-op', () {
      final pipeline = createPipeline();
      final layer = _TestLayer(zIndex: 0);

      expect(() => pipeline.removeLayer(layer), returnsNormally);
      expect(pipeline.layers.length, equals(0));
    });

    test('removeLayer with non-existent layer is no-op', () {
      final pipeline = createPipeline();
      final layer1 = _TestLayer(zIndex: 0);
      final layer2 = _TestLayer(zIndex: 1);

      pipeline.addLayer(layer1);

      expect(() => pipeline.removeLayer(layer2), returnsNormally);
      expect(pipeline.layers.length, equals(1));
    });

    test('clearLayers removes all layers', () {
      final pipeline = createPipeline();
      pipeline.addLayer(_TestLayer(zIndex: 0));
      pipeline.addLayer(_TestLayer(zIndex: 1));
      pipeline.addLayer(_TestLayer(zIndex: 2));

      expect(pipeline.layers.length, equals(3));

      pipeline.clearLayers();

      expect(pipeline.layers.length, equals(0));
    });

    test('layers getter returns unmodifiable list', () {
      final pipeline = createPipeline();
      pipeline.addLayer(_TestLayer(zIndex: 0));

      final layers = pipeline.layers;

      // Attempting to modify should throw
      expect(() => layers.add(_TestLayer(zIndex: 1)), throwsUnsupportedError);
    });
  });

  group('RenderPipeline - Z-Ordering', () {
    test('layers with different z-indices render in correct order', () {
      final pipeline = createPipeline();
      final canvas = _RecordingCanvas();

      // Add in random order
      pipeline.addLayer(_TestLayer(zIndex: 10, name: 'Top'));
      pipeline.addLayer(_TestLayer(zIndex: -5, name: 'Bottom'));
      pipeline.addLayer(_TestLayer(zIndex: 0, name: 'Middle'));

      pipeline.renderFrame(canvas, const Size(800, 600));

      expect(canvas.renderOrder, equals(['Bottom', 'Middle', 'Top']));
    });

    test('layers with duplicate z-index render in insertion order', () {
      final pipeline = createPipeline();
      final canvas = _RecordingCanvas();

      // All same z-index
      pipeline.addLayer(_TestLayer(zIndex: 0, name: 'First'));
      pipeline.addLayer(_TestLayer(zIndex: 0, name: 'Second'));
      pipeline.addLayer(_TestLayer(zIndex: 0, name: 'Third'));

      pipeline.renderFrame(canvas, const Size(800, 600));

      // Should render in insertion order (stable sort)
      expect(canvas.renderOrder, equals(['First', 'Second', 'Third']));
    });

    test('negative z-indices render before zero', () {
      final pipeline = createPipeline();
      final canvas = _RecordingCanvas();

      pipeline.addLayer(_TestLayer(zIndex: 0, name: 'Zero'));
      pipeline.addLayer(_TestLayer(zIndex: -1, name: 'NegOne'));
      pipeline.addLayer(_TestLayer(zIndex: -10, name: 'NegTen'));

      pipeline.renderFrame(canvas, const Size(800, 600));

      expect(canvas.renderOrder, equals(['NegTen', 'NegOne', 'Zero']));
    });

    test('positive z-indices render after zero', () {
      final pipeline = createPipeline();
      final canvas = _RecordingCanvas();

      pipeline.addLayer(_TestLayer(zIndex: 0, name: 'Zero'));
      pipeline.addLayer(_TestLayer(zIndex: 1, name: 'One'));
      pipeline.addLayer(_TestLayer(zIndex: 10, name: 'Ten'));

      pipeline.renderFrame(canvas, const Size(800, 600));

      expect(canvas.renderOrder, equals(['Zero', 'One', 'Ten']));
    });

    test('mixed z-indices render in correct ascending order', () {
      final pipeline = createPipeline();
      final canvas = _RecordingCanvas();

      pipeline.addLayer(_TestLayer(zIndex: 100, name: 'Overlay'));
      pipeline.addLayer(_TestLayer(zIndex: -100, name: 'Background'));
      pipeline.addLayer(_TestLayer(zIndex: 0, name: 'Data'));
      pipeline.addLayer(_TestLayer(zIndex: 50, name: 'Annotation'));
      pipeline.addLayer(_TestLayer(zIndex: -50, name: 'Grid'));

      pipeline.renderFrame(canvas, const Size(800, 600));

      expect(canvas.renderOrder, equals(['Background', 'Grid', 'Data', 'Annotation', 'Overlay']));
    });
  });

  group('RenderPipeline - Visibility Toggle', () {
    test('isVisible=false excludes layer from rendering', () {
      final pipeline = createPipeline();
      final canvas = _RecordingCanvas();
      final layer = _TestLayer(zIndex: 0, name: 'Hidden');
      layer.isVisible = false;

      pipeline.addLayer(layer);
      pipeline.renderFrame(canvas, const Size(800, 600));

      expect(canvas.renderOrder, isEmpty,
          reason: 'Invisible layer should not render');
    });

    test('isVisible=true includes layer in rendering', () {
      final pipeline = createPipeline();
      final canvas = _RecordingCanvas();
      final layer = _TestLayer(zIndex: 0, name: 'Visible');
      layer.isVisible = true;

      pipeline.addLayer(layer);
      pipeline.renderFrame(canvas, const Size(800, 600));

      expect(canvas.renderOrder, equals(['Visible']),
          reason: 'Visible layer should render');
    });

    test('toggling visibility affects subsequent renders', () {
      final pipeline = createPipeline();
      final layer = _TestLayer(zIndex: 0, name: 'Toggle');
      pipeline.addLayer(layer);

      // Initially visible
      layer.isVisible = true;
      final canvas1 = _RecordingCanvas();
      pipeline.renderFrame(canvas1, const Size(800, 600));
      expect(canvas1.renderOrder, equals(['Toggle']));

      // Toggle to invisible
      layer.isVisible = false;
      final canvas2 = _RecordingCanvas();
      pipeline.renderFrame(canvas2, const Size(800, 600));
      expect(canvas2.renderOrder, isEmpty);

      // Toggle back to visible
      layer.isVisible = true;
      final canvas3 = _RecordingCanvas();
      pipeline.renderFrame(canvas3, const Size(800, 600));
      expect(canvas3.renderOrder, equals(['Toggle']));
    });

    test('mixed visibility only renders visible layers', () {
      final pipeline = createPipeline();
      final canvas = _RecordingCanvas();

      final layer1 = _TestLayer(zIndex: 0, name: 'Visible1');
      final layer2 = _TestLayer(zIndex: 1, name: 'Hidden');
      final layer3 = _TestLayer(zIndex: 2, name: 'Visible2');

      layer1.isVisible = true;
      layer2.isVisible = false;
      layer3.isVisible = true;

      pipeline.addLayer(layer1);
      pipeline.addLayer(layer2);
      pipeline.addLayer(layer3);

      pipeline.renderFrame(canvas, const Size(800, 600));

      expect(canvas.renderOrder, equals(['Visible1', 'Visible2']),
          reason: 'Only visible layers should render');
    });

    test('all invisible layers renders nothing', () {
      final pipeline = createPipeline();
      final canvas = _RecordingCanvas();

      final layer1 = _TestLayer(zIndex: 0, name: 'Hidden1');
      final layer2 = _TestLayer(zIndex: 1, name: 'Hidden2');

      layer1.isVisible = false;
      layer2.isVisible = false;

      pipeline.addLayer(layer1);
      pipeline.addLayer(layer2);

      pipeline.renderFrame(canvas, const Size(800, 600));

      expect(canvas.renderOrder, isEmpty,
          reason: 'No layers should render when all invisible');
    });
  });

  group('RenderPipeline - isEmpty Optimization', () {
    test('isEmpty=true skips layer rendering', () {
      final pipeline = createPipeline();
      final canvas = _RecordingCanvas();
      final layer = _EmptyTestLayer(zIndex: 0, name: 'Empty');

      pipeline.addLayer(layer);
      pipeline.renderFrame(canvas, const Size(800, 600));

      expect(canvas.renderOrder, isEmpty,
          reason: 'Empty layer should be skipped');
    });

    test('isEmpty=false renders layer normally', () {
      final pipeline = createPipeline();
      final canvas = _RecordingCanvas();
      final layer = _TestLayer(zIndex: 0, name: 'NotEmpty');

      pipeline.addLayer(layer);
      pipeline.renderFrame(canvas, const Size(800, 600));

      expect(canvas.renderOrder, equals(['NotEmpty']),
          reason: 'Non-empty layer should render');
    });

    test('mixed empty and non-empty layers only renders non-empty', () {
      final pipeline = createPipeline();
      final canvas = _RecordingCanvas();

      pipeline.addLayer(_TestLayer(zIndex: 0, name: 'HasContent'));
      pipeline.addLayer(_EmptyTestLayer(zIndex: 1, name: 'Empty'));
      pipeline.addLayer(_TestLayer(zIndex: 2, name: 'AlsoHasContent'));

      pipeline.renderFrame(canvas, const Size(800, 600));

      expect(canvas.renderOrder, equals(['HasContent', 'AlsoHasContent']),
          reason: 'Only non-empty layers should render');
    });
  });

  group('RenderPipeline - Combined Conditions', () {
    test('invisible AND empty layer does not render', () {
      final pipeline = createPipeline();
      final canvas = _RecordingCanvas();
      final layer = _EmptyTestLayer(zIndex: 0, name: 'InvisibleAndEmpty');
      layer.isVisible = false;

      pipeline.addLayer(layer);
      pipeline.renderFrame(canvas, const Size(800, 600));

      expect(canvas.renderOrder, isEmpty);
    });

    test('invisible but non-empty layer does not render', () {
      final pipeline = createPipeline();
      final canvas = _RecordingCanvas();
      final layer = _TestLayer(zIndex: 0, name: 'InvisibleNotEmpty');
      layer.isVisible = false;

      pipeline.addLayer(layer);
      pipeline.renderFrame(canvas, const Size(800, 600));

      expect(canvas.renderOrder, isEmpty,
          reason: 'Invisible layer should not render regardless of isEmpty');
    });

    test('visible but empty layer does not render', () {
      final pipeline = createPipeline();
      final canvas = _RecordingCanvas();
      final layer = _EmptyTestLayer(zIndex: 0, name: 'VisibleButEmpty');
      layer.isVisible = true;

      pipeline.addLayer(layer);
      pipeline.renderFrame(canvas, const Size(800, 600));

      expect(canvas.renderOrder, isEmpty,
          reason: 'Empty layer should not render regardless of visibility');
    });

    test('visible AND non-empty layer renders', () {
      final pipeline = createPipeline();
      final canvas = _RecordingCanvas();
      final layer = _TestLayer(zIndex: 0, name: 'VisibleAndNotEmpty');
      layer.isVisible = true;

      pipeline.addLayer(layer);
      pipeline.renderFrame(canvas, const Size(800, 600));

      expect(canvas.renderOrder, equals(['VisibleAndNotEmpty']),
          reason: 'Visible and non-empty layer should render');
    });
  });

  group('RenderPipeline - Viewport Update (T022)', () {
    test('updateViewport updates internal viewport state', () {
      final pipeline = createPipeline();
      final initialViewport = pipeline.viewport;

      expect(initialViewport, equals(Rect.fromLTWH(0, 0, 800, 600)));

      final newViewport = Rect.fromLTWH(100, 50, 400, 300);
      pipeline.updateViewport(newViewport);

      expect(pipeline.viewport, equals(newViewport),
          reason: 'Viewport should be updated to new value');
    });

    test('viewport passed to RenderContext during renderFrame', () {
      final pipeline = createPipeline();
      final layer = _ViewportCaptureLayer(zIndex: 0);
      pipeline.addLayer(layer);

      final canvas = _RecordingCanvas();
      final newViewport = Rect.fromLTWH(200, 100, 600, 400);
      pipeline.updateViewport(newViewport);

      pipeline.renderFrame(canvas, const Size(800, 600));

      expect(layer.capturedViewport, equals(newViewport),
          reason: 'RenderContext should receive updated viewport');
    });

    test('viewport changes take effect immediately on next render', () {
      final pipeline = createPipeline();
      final layer = _ViewportCaptureLayer(zIndex: 0);
      pipeline.addLayer(layer);

      final canvas1 = _RecordingCanvas();
      pipeline.renderFrame(canvas1, const Size(800, 600));
      final firstViewport = layer.capturedViewport;

      expect(firstViewport, equals(Rect.fromLTWH(0, 0, 800, 600)));

      final newViewport = Rect.fromLTWH(50, 50, 700, 500);
      pipeline.updateViewport(newViewport);

      final canvas2 = _RecordingCanvas();
      pipeline.renderFrame(canvas2, const Size(800, 600));

      expect(layer.capturedViewport, equals(newViewport),
          reason: 'Updated viewport should be used in next frame');
    });

    test('multiple viewport updates only use last value', () {
      final pipeline = createPipeline();
      final layer = _ViewportCaptureLayer(zIndex: 0);
      pipeline.addLayer(layer);

      pipeline.updateViewport(Rect.fromLTWH(100, 100, 200, 200));
      pipeline.updateViewport(Rect.fromLTWH(200, 200, 300, 300));
      final finalViewport = Rect.fromLTWH(300, 300, 400, 400);
      pipeline.updateViewport(finalViewport);

      final canvas = _RecordingCanvas();
      pipeline.renderFrame(canvas, const Size(800, 600));

      expect(layer.capturedViewport, equals(finalViewport),
          reason: 'Only last viewport update should be used');
    });

    test('viewport getter returns current viewport value', () {
      final pipeline = createPipeline();

      expect(pipeline.viewport, equals(Rect.fromLTWH(0, 0, 800, 600)));

      pipeline.updateViewport(Rect.fromLTWH(10, 20, 30, 40));
      expect(pipeline.viewport, equals(Rect.fromLTWH(10, 20, 30, 40)));
    });
  });

  group('RenderPipeline - Performance Monitoring (T023)', () {
    test('beginFrame called before rendering', () {
      final monitor = StopwatchPerformanceMonitor();
      final pipeline = RenderPipeline(
        paintPool: ObjectPool<Paint>(factory: () => Paint(), reset: (p) {}),
        pathPool: ObjectPool<Path>(factory: () => Path(), reset: (p) => p.reset()),
        textPainterPool: ObjectPool<TextPainter>(factory: () => TextPainter(), reset: (tp) {}),
        textCache: LinkedHashMapTextLayoutCache(),
        performanceMonitor: monitor,
        culler: const ViewportCuller(),
        initialViewport: Rect.fromLTWH(0, 0, 800, 600),
      );

      final canvas = _RecordingCanvas();
      pipeline.renderFrame(canvas, const Size(800, 600));

      // If beginFrame wasn't called, currentMetrics would show zero frame time
      final metrics = monitor.currentMetrics;
      expect(metrics.frameTime.inMicroseconds, greaterThan(0),
          reason: 'beginFrame should have been called to start timing');
    });

    test('endFrame called after all layers rendered', () {
      final monitor = StopwatchPerformanceMonitor();
      final pipeline = RenderPipeline(
        paintPool: ObjectPool<Paint>(factory: () => Paint(), reset: (p) {}),
        pathPool: ObjectPool<Path>(factory: () => Path(), reset: (p) => p.reset()),
        textPainterPool: ObjectPool<TextPainter>(factory: () => TextPainter(), reset: (tp) {}),
        textCache: LinkedHashMapTextLayoutCache(),
        performanceMonitor: monitor,
        culler: const ViewportCuller(),
        initialViewport: Rect.fromLTWH(0, 0, 800, 600),
      );

      pipeline.addLayer(_TestLayer(zIndex: 0));
      pipeline.addLayer(_TestLayer(zIndex: 1));

      final canvas = _RecordingCanvas();
      pipeline.renderFrame(canvas, const Size(800, 600));

      // If endFrame wasn't called, metrics wouldn't be recorded
      final metrics = monitor.currentMetrics;
      expect(metrics.frameTime.inMicroseconds, greaterThan(0),
          reason: 'endFrame should have been called to record timing');
    });

    test('frame time recorded even if layer throws exception', () {
      final monitor = StopwatchPerformanceMonitor();
      final pipeline = RenderPipeline(
        paintPool: ObjectPool<Paint>(factory: () => Paint(), reset: (p) {}),
        pathPool: ObjectPool<Path>(factory: () => Path(), reset: (p) => p.reset()),
        textPainterPool: ObjectPool<TextPainter>(factory: () => TextPainter(), reset: (tp) {}),
        textCache: LinkedHashMapTextLayoutCache(),
        performanceMonitor: monitor,
        culler: const ViewportCuller(),
        initialViewport: Rect.fromLTWH(0, 0, 800, 600),
      );

      pipeline.addLayer(_ThrowingLayer(zIndex: 0));

      final canvas = _RecordingCanvas();

      // Render frame (layer will throw)
      expect(() => pipeline.renderFrame(canvas, const Size(800, 600)), throwsException);

      // endFrame should still have been called (finally block)
      final metrics = monitor.currentMetrics;
      expect(metrics.frameTime.inMicroseconds, greaterThan(0),
          reason: 'endFrame should be called in finally block even after exception');
    });

    test('currentMetrics accessible via pipeline', () {
      final pipeline = createPipeline();
      pipeline.addLayer(_TestLayer(zIndex: 0));

      final canvas = _RecordingCanvas();
      pipeline.renderFrame(canvas, const Size(800, 600));

      final metrics = pipeline.currentMetrics;
      expect(metrics, isNotNull);
      expect(metrics.frameTime.inMicroseconds, greaterThan(0));
    });

    test('performance metrics update with each frame', () {
      final pipeline = createPipeline();
      pipeline.addLayer(_TestLayer(zIndex: 0));

      final canvas1 = _RecordingCanvas();
      pipeline.renderFrame(canvas1, const Size(800, 600));
      final metrics1 = pipeline.currentMetrics;

      final canvas2 = _RecordingCanvas();
      pipeline.renderFrame(canvas2, const Size(800, 600));
      final metrics2 = pipeline.currentMetrics;

      // Both frames should have timing data
      expect(metrics1.frameTime.inMicroseconds, greaterThan(0));
      expect(metrics2.frameTime.inMicroseconds, greaterThan(0));
    });
  });
}

// Test layer implementations

class _TestLayer extends RenderLayer {
  final String name;

  _TestLayer({required super.zIndex, this.name = 'TestLayer'});

  @override
  void render(RenderContext context) {
    // Record render call on canvas
    if (context.canvas is _RecordingCanvas) {
      (context.canvas as _RecordingCanvas).recordRender(name);
    }
  }
}

class _EmptyTestLayer extends RenderLayer {
  final String name;

  _EmptyTestLayer({required super.zIndex, this.name = 'EmptyLayer'});

  @override
  bool get isEmpty => true;

  @override
  void render(RenderContext context) {
    // Should never be called due to isEmpty
    if (context.canvas is _RecordingCanvas) {
      (context.canvas as _RecordingCanvas).recordRender(name);
    }
  }
}

class _ViewportCaptureLayer extends RenderLayer {
  Rect? capturedViewport;

  _ViewportCaptureLayer({required super.zIndex});

  @override
  void render(RenderContext context) {
    capturedViewport = context.viewport;
  }
}

class _ThrowingLayer extends RenderLayer {
  _ThrowingLayer({required super.zIndex});

  @override
  void render(RenderContext context) {
    throw Exception('Layer rendering failed');
  }
}

// Mock canvas that records render calls
class _RecordingCanvas implements Canvas {
  final List<String> renderOrder = [];

  void recordRender(String layerName) {
    renderOrder.add(layerName);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
