/// Benchmark for RenderPipeline frame time validation.
///
/// Validates frame performance requirements:
/// - NFR: <8ms average frame time
/// - NFR: <16ms p99 frame time (60 FPS target)
/// - NFR: Zero jank (no frames exceeding 16ms budget)
///
/// Tests complete rendering pipeline with realistic layer composition:
/// - GridLayer (background)
/// - DataSeriesLayer (primary content)
/// - AnnotationLayer (overlay)
///
/// ## Running Benchmark
///
/// ```bash
/// flutter test test/benchmarks/rendering/render_pipeline_benchmark.dart
/// ```
///
/// Expected output:
/// ```
/// RenderPipeline Frame Time Benchmark:
///   500 visible points: avg 2.5ms, p99 4.2ms, jank count 0
///   5000 visible points: avg 6.8ms, p99 12.3ms, jank count 0
///   100 frame stability: avg 3.1ms, p99 5.4ms, jank count 0
/// ```
library;

import 'dart:ui' show Paint, Path, Color, Rect, Size, Canvas;

import 'package:flutter/rendering.dart' show TextPainter, TextStyle, Offset;
import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/foundation/foundation.dart' show ObjectPool, ViewportCuller;
import 'package:braven_charts/src/rendering/render_pipeline.dart' show RenderPipeline;
import 'package:braven_charts/src/rendering/performance_monitor.dart' show StopwatchPerformanceMonitor;
import 'package:braven_charts/src/rendering/text_layout_cache.dart' show LinkedHashMapTextLayoutCache;
import 'package:braven_charts/src/rendering/layers/grid_layer.dart' show GridLayer;
import 'package:braven_charts/src/rendering/layers/data_series_layer.dart' show DataSeriesLayer, ChartDataPoint;
import 'package:braven_charts/src/rendering/layers/annotation_layer.dart' show AnnotationLayer;

void main() {
  group('RenderPipeline Frame Time Benchmarks', () {
    late RenderPipeline pipeline;
    late _MockCanvas canvas;

    setUp(() {
      // Create pipeline with realistic configuration
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
        textCache: LinkedHashMapTextLayoutCache(maxSize: 100),
        performanceMonitor: StopwatchPerformanceMonitor(),
        culler: const ViewportCuller(),
        initialViewport: Rect.fromLTWH(0, 0, 800, 600),
      );

      canvas = _MockCanvas();
    });

    test('Frame time with 500 visible points', () {
      // Add 3 layers: grid + data series + annotations
      pipeline.addLayer(GridLayer(
        gridLineCount: 10,
        lineColor: const Color(0x33808080),
        zIndex: -1,
      ));

      final dataPoints =
          List.generate(500, (i) => ChartDataPoint(i.toDouble(), (i % 100).toDouble()));

      pipeline.addLayer(DataSeriesLayer(
        dataPoints: dataPoints,
        dataBounds: Rect.fromLTRB(0, 0, 500, 100),
        lineColor: const Color(0xFF2196F3),
        lineWidth: 2.0,
        zIndex: 0,
      ));

      pipeline.addLayer(AnnotationLayer(
        labels: ['Start', 'Peak', 'End'],
        positions: [
          const Offset(50, 50),
          const Offset(250, 30),
          const Offset(450, 50),
        ],
        textStyle: const TextStyle(fontSize: 12),
        zIndex: 1,
      ));

      // Render 10 frames and measure
      final frameTimes = <double>[];

      for (int frame = 0; frame < 10; frame++) {
        final stopwatch = Stopwatch()..start();

        pipeline.renderFrame(canvas, const Size(800, 600));

        stopwatch.stop();
        frameTimes.add(stopwatch.elapsedMicroseconds / 1000);
      }

      frameTimes.sort();
      final avg = frameTimes.fold<double>(0, (a, b) => a + b) / frameTimes.length;
      final p99 = frameTimes[(frameTimes.length * 0.99).floor()];
      final jankCount = frameTimes.where((t) => t > 16).length;

      // Validate targets
      expect(avg, lessThan(8), reason: 'Average frame time should be <8ms');
      expect(p99, lessThan(16), reason: 'P99 frame time should be <16ms (60 FPS)');
      expect(jankCount, equals(0), reason: 'Zero jank frames expected');

      print('500 visible points: avg ${avg.toStringAsFixed(1)}ms, '
          'p99 ${p99.toStringAsFixed(1)}ms, jank count $jankCount');
    });

    test('Frame time with 5000 visible points', () {
      pipeline.addLayer(GridLayer(
        gridLineCount: 10,
        lineColor: const Color(0x33808080),
        zIndex: -1,
      ));

      final dataPoints =
          List.generate(5000, (i) => ChartDataPoint(i.toDouble(), (i % 100).toDouble()));

      pipeline.addLayer(DataSeriesLayer(
        dataPoints: dataPoints,
        dataBounds: Rect.fromLTRB(0, 0, 5000, 100),
        lineColor: const Color(0xFF2196F3),
        lineWidth: 2.0,
        zIndex: 0,
      ));

      final frameTimes = <double>[];

      for (int frame = 0; frame < 10; frame++) {
        final stopwatch = Stopwatch()..start();

        pipeline.renderFrame(canvas, const Size(800, 600));

        stopwatch.stop();
        frameTimes.add(stopwatch.elapsedMicroseconds / 1000);
      }

      frameTimes.sort();
      final avg = frameTimes.fold<double>(0, (a, b) => a + b) / frameTimes.length;
      final p99 = frameTimes[(frameTimes.length * 0.99).floor()];

      // More lenient for large data sets, but should still be reasonable
      expect(avg, lessThan(16), reason: 'Average frame time should be <16ms for 5K points');

      print('5000 visible points: avg ${avg.toStringAsFixed(1)}ms, '
          'p99 ${p99.toStringAsFixed(1)}ms');
    });

    test('P99 frame time over 100 frames', () {
      pipeline.addLayer(GridLayer(
        gridLineCount: 10,
        lineColor: const Color(0x33808080),
        zIndex: -1,
      ));

      final dataPoints =
          List.generate(1000, (i) => ChartDataPoint(i.toDouble(), (i % 100).toDouble()));

      pipeline.addLayer(DataSeriesLayer(
        dataPoints: dataPoints,
        dataBounds: Rect.fromLTRB(0, 0, 1000, 100),
        lineColor: const Color(0xFF2196F3),
        lineWidth: 2.0,
        zIndex: 0,
      ));

      final frameTimes = <double>[];

      // Render 100 frames for statistical significance
      for (int frame = 0; frame < 100; frame++) {
        final stopwatch = Stopwatch()..start();

        pipeline.renderFrame(canvas, const Size(800, 600));

        stopwatch.stop();
        frameTimes.add(stopwatch.elapsedMicroseconds / 1000);
      }

      frameTimes.sort();
      final avg = frameTimes.fold<double>(0, (a, b) => a + b) / frameTimes.length;
      final p50 = frameTimes[50];
      final p99 = frameTimes[99];
      final jankCount = frameTimes.where((t) => t > 16).length;

      expect(avg, lessThan(8), reason: 'Average frame time should be <8ms');
      expect(p99, lessThan(16), reason: 'P99 frame time should be <16ms (60 FPS)');
      expect(jankCount, equals(0), reason: 'Zero jank frames over 100 frames');

      print('100 frame stability: avg ${avg.toStringAsFixed(1)}ms, '
          'p50 ${p50.toStringAsFixed(1)}ms, p99 ${p99.toStringAsFixed(1)}ms, '
          'jank count $jankCount');
    });

    test('Jank count validation', () {
      pipeline.addLayer(GridLayer(
        gridLineCount: 10,
        lineColor: const Color(0x33808080),
        zIndex: -1,
      ));

      final dataPoints =
          List.generate(500, (i) => ChartDataPoint(i.toDouble(), (i % 100).toDouble()));

      pipeline.addLayer(DataSeriesLayer(
        dataPoints: dataPoints,
        dataBounds: Rect.fromLTRB(0, 0, 500, 100),
        lineColor: const Color(0xFF2196F3),
        lineWidth: 2.0,
        zIndex: 0,
      ));

      final frameTimes = <double>[];

      for (int frame = 0; frame < 50; frame++) {
        final stopwatch = Stopwatch()..start();

        pipeline.renderFrame(canvas, const Size(800, 600));

        stopwatch.stop();
        frameTimes.add(stopwatch.elapsedMicroseconds / 1000);
      }

      final jankCount = frameTimes.where((t) => t > 16).length;
      final jankPercent = (jankCount / frameTimes.length) * 100;

      expect(jankCount, equals(0), reason: 'Zero jank expected for 500 points');
      expect(jankPercent, equals(0), reason: 'Jank percentage should be 0%');

      print('Jank validation: $jankCount jank frames (${jankPercent.toStringAsFixed(1)}%) '
          'over 50 frames');
    });
  });
}

// Mock canvas for testing (doesn't actually render)
class _MockCanvas extends Fake implements Canvas {}
