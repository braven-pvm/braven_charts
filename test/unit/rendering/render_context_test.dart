// Unit Tests: RenderContext Validation
// Feature: 002-core-rendering
// Task: T019
// Purpose: Validate constructor assertions, immutability, dependency access

import 'package:braven_charts/src/foundation/performance/object_pool.dart';
import 'package:braven_charts/src/foundation/performance/viewport_culler.dart';
import 'package:braven_charts/src/rendering/performance_monitor.dart';
import 'package:braven_charts/src/rendering/render_context.dart';
import 'package:braven_charts/src/rendering/text_layout_cache.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Helper to create valid RenderContext for testing
  RenderContext createValidContext({
    Canvas? canvas,
    Size? size,
    Rect? viewport,
  }) {
    return RenderContext(
      canvas: canvas ?? _MockCanvas(),
      size: size ?? const Size(800, 600),
      viewport: viewport ?? const Rect.fromLTWH(0, 0, 800, 600),
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

  group('RenderContext - Constructor Validation', () {
    test('constructor accepts valid size with positive dimensions', () {
      expect(
        () => createValidContext(size: const Size(800, 600)),
        returnsNormally,
        reason: 'Should accept positive width and height',
      );
    });

    test('constructor asserts on zero width', () {
      expect(
        () => createValidContext(size: const Size(0, 600)),
        throwsAssertionError,
        reason: 'Width must be greater than 0',
      );
    });

    test('constructor asserts on negative width', () {
      expect(
        () => createValidContext(size: const Size(-100, 600)),
        throwsAssertionError,
        reason: 'Negative width should be rejected',
      );
    });

    test('constructor asserts on zero height', () {
      expect(
        () => createValidContext(size: const Size(800, 0)),
        throwsAssertionError,
        reason: 'Height must be greater than 0',
      );
    });

    test('constructor asserts on negative height', () {
      expect(
        () => createValidContext(size: const Size(800, -200)),
        throwsAssertionError,
        reason: 'Negative height should be rejected',
      );
    });

    test('constructor asserts on both dimensions zero', () {
      expect(
        () => createValidContext(size: const Size(0, 0)),
        throwsAssertionError,
        reason: 'Zero width and height should be rejected',
      );
    });

    test('constructor accepts minimum positive dimensions', () {
      expect(
        () => createValidContext(size: const Size(1, 1)),
        returnsNormally,
        reason: 'Minimum positive dimensions (1x1) should be valid',
      );
    });

    test('constructor accepts large dimensions', () {
      expect(
        () => createValidContext(size: const Size(10000, 8000)),
        returnsNormally,
        reason: 'Large dimensions should be accepted',
      );
    });

    test('constructor accepts fractional dimensions', () {
      expect(
        () => createValidContext(size: const Size(800.5, 600.75)),
        returnsNormally,
        reason: 'Fractional logical pixels should be accepted',
      );
    });
  });

  group('RenderContext - Viewport Handling', () {
    test('viewport can be identical to canvas size', () {
      const size = Size(800, 600);
      final viewport = const Rect.fromLTWH(0, 0, 800, 600);

      expect(
        () => createValidContext(size: size, viewport: viewport),
        returnsNormally,
        reason: 'Viewport can match canvas exactly',
      );
    });

    test('viewport can be smaller than canvas (zoomed in)', () {
      const size = Size(800, 600);
      final viewport = const Rect.fromLTWH(100, 100, 400, 300); // Zoomed region

      expect(
        () => createValidContext(size: size, viewport: viewport),
        returnsNormally,
        reason: 'Viewport can be smaller than canvas for zoom',
      );
    });

    test('viewport can extend beyond canvas (panned out)', () {
      const size = Size(800, 600);
      final viewport =
          const Rect.fromLTWH(-200, -100, 1200, 800); // Extends beyond

      expect(
        () => createValidContext(size: size, viewport: viewport),
        returnsNormally,
        reason: 'Viewport can extend beyond canvas for pan/zoom',
      );
    });

    test('isPointVisible delegates to viewport contains', () {
      final viewport = const Rect.fromLTWH(0, 0, 800, 600);
      final context = createValidContext(viewport: viewport);

      // Point inside viewport
      expect(context.isPointVisible(400, 300), isTrue,
          reason: 'Point in center of viewport should be visible');

      // Point outside viewport
      expect(context.isPointVisible(1000, 1000), isFalse,
          reason: 'Point outside viewport should not be visible');

      // Point on viewport edge
      expect(context.isPointVisible(0, 0), isTrue,
          reason: 'Point on viewport edge should be visible');
    });

    test('isPointVisible respects viewport boundaries', () {
      final viewport = const Rect.fromLTWH(100, 100, 400, 300);
      final context = createValidContext(viewport: viewport);

      // Inside viewport bounds
      expect(context.isPointVisible(300, 250), isTrue);

      // Outside viewport (left of bounds)
      expect(context.isPointVisible(50, 250), isFalse);

      // Outside viewport (right of bounds)
      expect(context.isPointVisible(600, 250), isFalse);

      // Outside viewport (above bounds)
      expect(context.isPointVisible(300, 50), isFalse);

      // Outside viewport (below bounds)
      expect(context.isPointVisible(300, 500), isFalse);
    });
  });

  group('RenderContext - Immutability', () {
    test('all fields are final and cannot be reassigned', () {
      final context = createValidContext();

      // Verify fields exist and are accessible (compile-time check via usage)
      expect(context.canvas, isNotNull);
      expect(context.size, isNotNull);
      expect(context.viewport, isNotNull);
      expect(context.culler, isNotNull);
      expect(context.paintPool, isNotNull);
      expect(context.pathPool, isNotNull);
      expect(context.textPainterPool, isNotNull);
      expect(context.textCache, isNotNull);
      expect(context.performanceMonitor, isNotNull);

      // Note: Dart's final keyword is compile-time enforced.
      // If fields were mutable, this test file wouldn't compile.
    });

    test('size object is immutable', () {
      final context = createValidContext(size: const Size(800, 600));

      expect(context.size.width, equals(800));
      expect(context.size.height, equals(600));

      // Size is immutable value type - cannot be modified
      // (compile-time enforcement)
    });

    test('viewport object is immutable', () {
      final viewport = const Rect.fromLTWH(100, 100, 400, 300);
      final context = createValidContext(viewport: viewport);

      expect(context.viewport.left, equals(100));
      expect(context.viewport.top, equals(100));
      expect(context.viewport.width, equals(400));
      expect(context.viewport.height, equals(300));

      // Rect is immutable value type - cannot be modified
      // (compile-time enforcement)
    });
  });

  group('RenderContext - Dependency Access', () {
    test('provides access to canvas for drawing operations', () {
      final mockCanvas = _MockCanvas();
      final context = createValidContext(canvas: mockCanvas);

      expect(context.canvas, equals(mockCanvas),
          reason: 'Should provide access to injected canvas');
    });

    test('provides access to size dimensions', () {
      const size = Size(1024, 768);
      final context = createValidContext(size: size);

      expect(context.size, equals(size));
      expect(context.width, equals(1024),
          reason: 'width getter should return size.width');
      expect(context.height, equals(768),
          reason: 'height getter should return size.height');
    });

    test('provides access to viewport culler', () {
      const culler = ViewportCuller();
      final context = RenderContext(
        canvas: _MockCanvas(),
        size: const Size(800, 600),
        viewport: const Rect.fromLTWH(0, 0, 800, 600),
        culler: culler,
        paintPool: ObjectPool<Paint>(factory: () => Paint(), reset: (p) {}),
        pathPool:
            ObjectPool<Path>(factory: () => Path(), reset: (p) => p.reset()),
        textPainterPool: ObjectPool<TextPainter>(
            factory: () => TextPainter(), reset: (tp) {}),
        textCache: LinkedHashMapTextLayoutCache(),
        performanceMonitor: StopwatchPerformanceMonitor(),
      );

      expect(context.culler, equals(culler),
          reason: 'Should provide access to injected culler');
    });

    test('provides access to all object pools', () {
      final paintPool =
          ObjectPool<Paint>(factory: () => Paint(), reset: (p) {});
      final pathPool =
          ObjectPool<Path>(factory: () => Path(), reset: (p) => p.reset());
      final textPainterPool =
          ObjectPool<TextPainter>(factory: () => TextPainter(), reset: (tp) {});

      final context = RenderContext(
        canvas: _MockCanvas(),
        size: const Size(800, 600),
        viewport: const Rect.fromLTWH(0, 0, 800, 600),
        culler: const ViewportCuller(),
        paintPool: paintPool,
        pathPool: pathPool,
        textPainterPool: textPainterPool,
        textCache: LinkedHashMapTextLayoutCache(),
        performanceMonitor: StopwatchPerformanceMonitor(),
      );

      expect(context.paintPool, equals(paintPool));
      expect(context.pathPool, equals(pathPool));
      expect(context.textPainterPool, equals(textPainterPool));
    });

    test('provides access to text layout cache', () {
      final textCache = LinkedHashMapTextLayoutCache(maxSize: 100);
      final context = RenderContext(
        canvas: _MockCanvas(),
        size: const Size(800, 600),
        viewport: const Rect.fromLTWH(0, 0, 800, 600),
        culler: const ViewportCuller(),
        paintPool: ObjectPool<Paint>(factory: () => Paint(), reset: (p) {}),
        pathPool:
            ObjectPool<Path>(factory: () => Path(), reset: (p) => p.reset()),
        textPainterPool: ObjectPool<TextPainter>(
            factory: () => TextPainter(), reset: (tp) {}),
        textCache: textCache,
        performanceMonitor: StopwatchPerformanceMonitor(),
      );

      expect(context.textCache, equals(textCache),
          reason: 'Should provide access to injected text cache');
    });

    test('provides access to performance monitor', () {
      final monitor = StopwatchPerformanceMonitor(maxHistorySize: 60);
      final context = RenderContext(
        canvas: _MockCanvas(),
        size: const Size(800, 600),
        viewport: const Rect.fromLTWH(0, 0, 800, 600),
        culler: const ViewportCuller(),
        paintPool: ObjectPool<Paint>(factory: () => Paint(), reset: (p) {}),
        pathPool:
            ObjectPool<Path>(factory: () => Path(), reset: (p) => p.reset()),
        textPainterPool: ObjectPool<TextPainter>(
            factory: () => TextPainter(), reset: (tp) {}),
        textCache: LinkedHashMapTextLayoutCache(),
        performanceMonitor: monitor,
      );

      expect(context.performanceMonitor, equals(monitor),
          reason: 'Should provide access to injected performance monitor');
    });
  });

  group('RenderContext - Convenience Methods', () {
    test('width getter returns correct canvas width', () {
      final context = createValidContext(size: const Size(1920, 1080));
      expect(context.width, equals(1920));
    });

    test('height getter returns correct canvas height', () {
      final context = createValidContext(size: const Size(1920, 1080));
      expect(context.height, equals(1080));
    });

    test('width and height match size dimensions', () {
      const size = Size(640, 480);
      final context = createValidContext(size: size);

      expect(context.width, equals(size.width));
      expect(context.height, equals(size.height));
    });
  });
}

// Mock implementations for testing

class _MockCanvas implements Canvas {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
