/// Benchmark for empty layer short-circuit optimization.
///
/// Validates isEmpty optimization performance:
/// - Target: <0.1ms per empty layer (overhead from check + skip)
/// - Target: 50 empty layers should add <5ms total overhead
/// - Target: Verify isEmpty is faster than rendering
///
/// Tests empty layer performance:
/// - 50 layers with isEmpty=true (should skip render())
/// - 50 layers with isEmpty=false (should call render())
/// - Frame time difference validates optimization effectiveness
///
/// ## Running Benchmark
///
/// ```bash
/// flutter test test/benchmarks/rendering/empty_layer_benchmark.dart
/// ```
///
/// Expected output:
/// ```
/// Empty Layer Benchmark:
///   50 empty layers: 2.5ms total (0.05ms per layer)
///   50 non-empty layers: 8.3ms total (0.166ms per layer)
///   Speedup: 3.3x (isEmpty optimization effective)
/// ```
library;

import 'dart:ui' show Paint, Path, Color, Rect, Size, Canvas;

import 'package:flutter/rendering.dart' show TextPainter;
import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/legacy/src/foundation/foundation.dart'
    show ObjectPool, ViewportCuller;
import 'package:braven_charts/legacy/src/rendering/render_pipeline.dart'
    show RenderPipeline;
import 'package:braven_charts/legacy/src/rendering/performance_monitor.dart'
    show StopwatchPerformanceMonitor;
import 'package:braven_charts/legacy/src/rendering/text_layout_cache.dart'
    show LinkedHashMapTextLayoutCache;
import 'package:braven_charts/legacy/src/rendering/render_layer.dart' show RenderLayer;
import 'package:braven_charts/legacy/src/rendering/render_context.dart'
    show RenderContext;

void main() {
  group('Empty Layer Short-Circuit Benchmarks', () {
    late RenderPipeline pipeline;
    late _MockCanvas canvas;

    setUp(() {
      pipeline = RenderPipeline(
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

      canvas = _MockCanvas();
    });

    test('Frame time with 50 empty layers (target: <5ms overhead)', () {
      // Add 50 layers with isEmpty=true
      for (int i = 0; i < 50; i++) {
        pipeline.addLayer(_EmptyLayer(zIndex: i));
      }

      final frameTimes = <double>[];

      // Render 100 frames
      for (int frame = 0; frame < 100; frame++) {
        final stopwatch = Stopwatch()..start();

        pipeline.renderFrame(canvas, const Size(800, 600));

        stopwatch.stop();
        frameTimes.add(stopwatch.elapsedMicroseconds / 1000);
      }

      frameTimes.sort();
      final avg =
          frameTimes.fold<double>(0, (a, b) => a + b) / frameTimes.length;
      final perLayer = avg / 50;

      // Validate targets
      expect(avg, lessThan(5),
          reason: '50 empty layers should add <5ms overhead');
      expect(perLayer, lessThan(0.1),
          reason: 'Per-layer overhead should be <0.1ms');

      print('50 empty layers: ${avg.toStringAsFixed(1)}ms total, '
          '${perLayer.toStringAsFixed(3)}ms per layer');
    });

    test('Frame time with 50 non-empty layers (comparison baseline)', () {
      // Add 50 layers with isEmpty=false that do minimal work
      for (int i = 0; i < 50; i++) {
        pipeline.addLayer(_NonEmptyLayer(zIndex: i));
      }

      final frameTimes = <double>[];

      for (int frame = 0; frame < 100; frame++) {
        final stopwatch = Stopwatch()..start();

        pipeline.renderFrame(canvas, const Size(800, 600));

        stopwatch.stop();
        frameTimes.add(stopwatch.elapsedMicroseconds / 1000);
      }

      frameTimes.sort();
      final avg =
          frameTimes.fold<double>(0, (a, b) => a + b) / frameTimes.length;
      final perLayer = avg / 50;

      print('50 non-empty layers: ${avg.toStringAsFixed(1)}ms total, '
          '${perLayer.toStringAsFixed(3)}ms per layer');
    });

    test('isEmpty optimization effectiveness', () {
      // Benchmark empty vs non-empty side-by-side
      final emptyPipeline = RenderPipeline(
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

      final nonEmptyPipeline = RenderPipeline(
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

      // Add 50 empty layers
      for (int i = 0; i < 50; i++) {
        emptyPipeline.addLayer(_EmptyLayer(zIndex: i));
      }

      // Add 50 non-empty layers
      for (int i = 0; i < 50; i++) {
        nonEmptyPipeline.addLayer(_NonEmptyLayer(zIndex: i));
      }

      // Benchmark empty
      final emptyStopwatch = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        emptyPipeline.renderFrame(canvas, const Size(800, 600));
      }
      emptyStopwatch.stop();
      final emptyTime = emptyStopwatch.elapsedMicroseconds / 1000 / 100;

      // Benchmark non-empty
      final nonEmptyStopwatch = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        nonEmptyPipeline.renderFrame(canvas, const Size(800, 600));
      }
      nonEmptyStopwatch.stop();
      final nonEmptyTime = nonEmptyStopwatch.elapsedMicroseconds / 1000 / 100;

      final speedup = nonEmptyTime / emptyTime;

      // isEmpty should provide measurable speedup
      expect(speedup, greaterThan(1.5),
          reason: 'isEmpty optimization should provide >1.5x speedup');

      print('Speedup: ${speedup.toStringAsFixed(1)}x '
          '(empty: ${emptyTime.toStringAsFixed(2)}ms, '
          'non-empty: ${nonEmptyTime.toStringAsFixed(2)}ms)');
    });

    test('Mixed empty and non-empty layers', () {
      // Add mix: 25 empty + 25 non-empty
      for (int i = 0; i < 25; i++) {
        pipeline.addLayer(_EmptyLayer(zIndex: i * 2));
        pipeline.addLayer(_NonEmptyLayer(zIndex: i * 2 + 1));
      }

      final frameTimes = <double>[];

      for (int frame = 0; frame < 100; frame++) {
        final stopwatch = Stopwatch()..start();

        pipeline.renderFrame(canvas, const Size(800, 600));

        stopwatch.stop();
        frameTimes.add(stopwatch.elapsedMicroseconds / 1000);
      }

      frameTimes.sort();
      final avg =
          frameTimes.fold<double>(0, (a, b) => a + b) / frameTimes.length;

      // Should be roughly between pure empty (fast) and pure non-empty (slower)
      print(
          'Mixed 25 empty + 25 non-empty: ${avg.toStringAsFixed(1)}ms per frame');
    });

    test('isEmpty check overhead (minimal)', () {
      // Create a layer with very fast render() to isolate isEmpty check overhead
      final fastPipeline = RenderPipeline(
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

      // Add one empty layer
      fastPipeline.addLayer(_EmptyLayer(zIndex: 0));

      final latencies = <double>[];

      for (int i = 0; i < 1000; i++) {
        final stopwatch = Stopwatch()..start();

        fastPipeline.renderFrame(canvas, const Size(800, 600));

        stopwatch.stop();
        latencies.add(stopwatch.elapsedMicroseconds / 1000);
      }

      latencies.sort();
      final avg = latencies.fold<double>(0, (a, b) => a + b) / latencies.length;

      // Single empty layer overhead should be negligible
      expect(avg, lessThan(0.1),
          reason: 'Single empty layer check should be <0.1ms');

      print('Single empty layer overhead: ${avg.toStringAsFixed(4)}ms');
    });
  });
}

// Layer that reports isEmpty=true (should skip render)
class _EmptyLayer extends RenderLayer {
  _EmptyLayer({required super.zIndex});

  @override
  bool get isEmpty => true;

  @override
  void render(RenderContext context) {
    // Should never be called due to isEmpty short-circuit
    throw StateError('render() should not be called on empty layer');
  }
}

// Layer that reports isEmpty=false (should call render)
class _NonEmptyLayer extends RenderLayer {
  _NonEmptyLayer({required super.zIndex});

  @override
  bool get isEmpty => false;

  @override
  void render(RenderContext context) {
    // Minimal work: just acquire and release a Paint object
    final paint = context.paintPool.acquire();
    context.paintPool.release(paint);
  }
}

// Mock canvas for testing
class _MockCanvas extends Fake implements Canvas {}
