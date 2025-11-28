// Unit Tests: RenderLayer isEmpty Optimization
// Feature: 002-core-rendering
// Task: T020
// Purpose: Validate isEmpty short-circuit, visibility toggle, render() contract

import 'package:braven_charts/legacy/src/foundation/performance/object_pool.dart';
import 'package:braven_charts/legacy/src/foundation/performance/viewport_culler.dart';
import 'package:braven_charts/legacy/src/rendering/performance_monitor.dart';
import 'package:braven_charts/legacy/src/rendering/render_context.dart';
import 'package:braven_charts/legacy/src/rendering/render_layer.dart';
import 'package:braven_charts/legacy/src/rendering/text_layout_cache.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Helper to create test render context
  RenderContext createContext() {
    return RenderContext(
      canvas: _RecordingCanvas(),
      size: const Size(800, 600),
      viewport: const Rect.fromLTWH(0, 0, 800, 600),
      culler: const ViewportCuller(),
      paintPool: ObjectPool<Paint>(factory: () => Paint(), reset: (p) {}),
      pathPool:
          ObjectPool<Path>(factory: () => Path(), reset: (p) => p.reset()),
      textPainterPool:
          ObjectPool<TextPainter>(factory: () => TextPainter(), reset: (tp) {}),
      textCache: LinkedHashMapTextLayoutCache(),
      performanceMonitor: StopwatchPerformanceMonitor(),
    );
  }

  group('RenderLayer - isEmpty Optimization', () {
    test('isEmpty=true skips render() call', () {
      final layer = _EmptyTestLayer(zIndex: 0);
      final context = createContext();

      layer.render(context);

      expect((context.canvas as _RecordingCanvas).drawCalls, equals(0),
          reason: 'render() should short-circuit when isEmpty=true');
    });

    test('isEmpty=false executes render() normally', () {
      final layer = _NonEmptyTestLayer(zIndex: 0);
      final context = createContext();

      layer.render(context);

      expect((context.canvas as _RecordingCanvas).drawCalls, greaterThan(0),
          reason: 'render() should execute when isEmpty=false');
    });

    test('default isEmpty implementation returns false', () {
      final layer = _DefaultTestLayer(zIndex: 0);

      expect(layer.isEmpty, isFalse,
          reason: 'Default isEmpty should return false');
    });

    test('isEmpty can be overridden to return true', () {
      final layer = _EmptyTestLayer(zIndex: 0);

      expect(layer.isEmpty, isTrue,
          reason: 'Overridden isEmpty should return true when layer is empty');
    });

    test('isEmpty check is fast (O(1) performance)', () {
      final layer = _FastEmptyCheckLayer(zIndex: 0, pointCount: 10000);
      final stopwatch = Stopwatch()..start();

      // Check isEmpty 1000 times
      for (int i = 0; i < 1000; i++) {
        layer.isEmpty;
      }

      stopwatch.stop();

      // Should complete in <1ms total (1 microsecond per check)
      expect(stopwatch.elapsedMicroseconds, lessThan(1000),
          reason: 'isEmpty checks should be O(1) and very fast');
    });
  });

  group('RenderLayer - Visibility Toggle', () {
    test('isVisible=false skips render() regardless of isEmpty', () {
      final layer = _NonEmptyTestLayer(zIndex: 0);
      layer.isVisible = false;
      final context = createContext();

      // Note: Pipeline is responsible for checking isVisible before calling render()
      // This test verifies the layer respects the flag if checked externally
      if (layer.isVisible) {
        layer.render(context);
      }

      expect((context.canvas as _RecordingCanvas).drawCalls, equals(0),
          reason: 'Should not render when isVisible=false');
    });

    test('isVisible=true allows render() to execute', () {
      final layer = _NonEmptyTestLayer(zIndex: 0);
      layer.isVisible = true;
      final context = createContext();

      if (layer.isVisible) {
        layer.render(context);
      }

      expect((context.canvas as _RecordingCanvas).drawCalls, greaterThan(0),
          reason: 'Should render when isVisible=true');
    });

    test('toggling isVisible changes render behavior', () {
      final layer = _NonEmptyTestLayer(zIndex: 0);
      final context1 = createContext();

      // Initially visible
      layer.isVisible = true;
      if (layer.isVisible) {
        layer.render(context1);
      }
      expect((context1.canvas as _RecordingCanvas).drawCalls, greaterThan(0),
          reason: 'Should render when visible');

      // Toggle to invisible
      layer.isVisible = false;
      final context2 = createContext();
      if (layer.isVisible) {
        layer.render(context2);
      }
      expect((context2.canvas as _RecordingCanvas).drawCalls, equals(0),
          reason: 'Should not render when invisible');

      // Toggle back to visible
      layer.isVisible = true;
      final context3 = createContext();
      if (layer.isVisible) {
        layer.render(context3);
      }
      expect((context3.canvas as _RecordingCanvas).drawCalls, greaterThan(0),
          reason: 'Should render again when visible');
    });

    test('isVisible defaults to true', () {
      final layer = _DefaultTestLayer(zIndex: 0);

      expect(layer.isVisible, isTrue,
          reason: 'isVisible should default to true in constructor');
    });

    test('isVisible can be set to false in constructor', () {
      final layer = _DefaultTestLayer(zIndex: 0, isVisible: false);

      expect(layer.isVisible, isFalse,
          reason: 'isVisible should accept false in constructor');
    });
  });

  group('RenderLayer - Combined Conditions', () {
    test('isEmpty=true AND isVisible=false both prevent rendering', () {
      final layer = _EmptyTestLayer(zIndex: 0);
      layer.isVisible = false;
      final context = createContext();

      if (layer.isVisible && !layer.isEmpty) {
        layer.render(context);
      }

      expect((context.canvas as _RecordingCanvas).drawCalls, equals(0),
          reason: 'Should not render when both conditions are false');
    });

    test('isEmpty=false AND isVisible=true allows rendering', () {
      final layer = _NonEmptyTestLayer(zIndex: 0);
      layer.isVisible = true;
      final context = createContext();

      if (layer.isVisible && !layer.isEmpty) {
        layer.render(context);
      }

      expect((context.canvas as _RecordingCanvas).drawCalls, greaterThan(0),
          reason: 'Should render when both conditions are true');
    });

    test('isEmpty=true overrides isVisible=true', () {
      final layer = _EmptyTestLayer(zIndex: 0);
      layer.isVisible = true;
      final context = createContext();

      // Layer render implementation checks isEmpty first
      layer.render(context);

      expect((context.canvas as _RecordingCanvas).drawCalls, equals(0),
          reason: 'isEmpty should short-circuit even when visible');
    });

    test('isVisible=false overrides isEmpty=false (at pipeline level)', () {
      final layer = _NonEmptyTestLayer(zIndex: 0);
      layer.isVisible = false;
      final context = createContext();

      // Pipeline checks isVisible before calling render()
      if (layer.isVisible) {
        layer.render(context);
      }

      expect((context.canvas as _RecordingCanvas).drawCalls, equals(0),
          reason:
              'isVisible=false should prevent render call at pipeline level');
    });
  });

  group('RenderLayer - Z-Index', () {
    test('zIndex is immutable after construction', () {
      final layer = _DefaultTestLayer(zIndex: 5);

      expect(layer.zIndex, equals(5));
      // Note: zIndex is final, so this is compile-time enforced
    });

    test('zIndex accepts negative values', () {
      final layer = _DefaultTestLayer(zIndex: -10);

      expect(layer.zIndex, equals(-10),
          reason: 'Negative zIndex should be accepted for background layers');
    });

    test('zIndex accepts zero', () {
      final layer = _DefaultTestLayer(zIndex: 0);

      expect(layer.zIndex, equals(0), reason: 'Zero zIndex should be accepted');
    });

    test('zIndex accepts positive values', () {
      final layer = _DefaultTestLayer(zIndex: 100);

      expect(layer.zIndex, equals(100),
          reason: 'Positive zIndex should be accepted for foreground layers');
    });
  });

  group('RenderLayer - toString', () {
    test('toString includes zIndex and isVisible', () {
      final layer = _DefaultTestLayer(zIndex: 5, isVisible: true);
      final result = layer.toString();

      expect(result, contains('zIndex: 5'));
      expect(result, contains('isVisible: true'));
    });

    test('toString reflects changed isVisible state', () {
      final layer = _DefaultTestLayer(zIndex: 0);
      layer.isVisible = false;
      final result = layer.toString();

      expect(result, contains('isVisible: false'));
    });
  });
}

// Test layer implementations

/// Test layer with default isEmpty (returns false)
class _DefaultTestLayer extends RenderLayer {
  _DefaultTestLayer({required super.zIndex, super.isVisible});

  @override
  void render(RenderContext context) {
    final paint = context.paintPool.acquire();
    try {
      (context.canvas as _RecordingCanvas).recordDraw();
    } finally {
      context.paintPool.release(paint);
    }
  }
}

/// Test layer that overrides isEmpty to return true
class _EmptyTestLayer extends RenderLayer {
  _EmptyTestLayer({required super.zIndex});

  @override
  bool get isEmpty => true;

  @override
  void render(RenderContext context) {
    if (isEmpty) return; // Short-circuit for empty layer

    final paint = context.paintPool.acquire();
    try {
      (context.canvas as _RecordingCanvas).recordDraw();
    } finally {
      context.paintPool.release(paint);
    }
  }
}

/// Test layer that overrides isEmpty to return false (has content)
class _NonEmptyTestLayer extends RenderLayer {
  _NonEmptyTestLayer({required super.zIndex});

  @override
  bool get isEmpty => false;

  @override
  void render(RenderContext context) {
    if (isEmpty) return;

    final paint = context.paintPool.acquire();
    try {
      (context.canvas as _RecordingCanvas).recordDraw();
    } finally {
      context.paintPool.release(paint);
    }
  }
}

/// Test layer that demonstrates O(1) isEmpty check
class _FastEmptyCheckLayer extends RenderLayer {
  final int pointCount;

  _FastEmptyCheckLayer({required super.zIndex, required this.pointCount});

  @override
  bool get isEmpty => pointCount == 0; // O(1) check

  @override
  void render(RenderContext context) {
    if (isEmpty) return;

    final paint = context.paintPool.acquire();
    try {
      (context.canvas as _RecordingCanvas).recordDraw();
    } finally {
      context.paintPool.release(paint);
    }
  }
}

// Mock canvas that records draw calls
class _RecordingCanvas implements Canvas {
  int drawCalls = 0;

  void recordDraw() {
    drawCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
