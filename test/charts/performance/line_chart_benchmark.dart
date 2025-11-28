// Performance Benchmark: LineChartLayer
// Feature: 005-chart-types
// Task: T056
// Purpose: Validate <16ms frame time for 10,000 points
//
// Constitutional Requirement: Performance benchmarks must pass before merge

import 'dart:ui' as ui;

// Import MarkerShape from chart_config.dart
import 'package:braven_charts/legacy/src/charts/base/chart_config.dart'
    show MarkerShape;
import 'package:braven_charts/legacy/src/charts/base/chart_layer.dart';
import 'package:braven_charts/legacy/src/charts/line/line_chart_config.dart';
import 'package:braven_charts/legacy/src/charts/line/line_chart_layer.dart';
import 'package:braven_charts/legacy/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/legacy/src/foundation/data_models/chart_series.dart';
import 'package:braven_charts/legacy/src/foundation/performance/object_pool.dart';
import 'package:braven_charts/legacy/src/foundation/performance/viewport_culler.dart';
import 'package:braven_charts/legacy/src/rendering/performance_monitor.dart';
import 'package:braven_charts/legacy/src/rendering/render_context.dart';
import 'package:braven_charts/legacy/src/rendering/text_layout_cache.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LineChartLayer Performance Benchmarks', () {
    late ObjectPool<Paint> paintPool;
    late ObjectPool<Path> pathPool;
    late ObjectPool<TextPainter> textPainterPool;
    late TextLayoutCache textCache;
    late PerformanceMonitor perfMonitor;

    setUp(() {
      paintPool = ObjectPool<Paint>(factory: () => Paint(), reset: (p) {});
      pathPool =
          ObjectPool<Path>(factory: () => Path(), reset: (p) => p.reset());
      textPainterPool =
          ObjectPool<TextPainter>(factory: () => TextPainter(), reset: (tp) {});
      textCache = LinkedHashMapTextLayoutCache();
      perfMonitor = StopwatchPerformanceMonitor();
    });

    RenderContext createContext() {
      return RenderContext(
        canvas: _MockCanvas(),
        size: const ui.Size(800, 600),
        viewport: const ui.Rect.fromLTWH(0, 0, 10000, 100),
        culler: const ViewportCuller(),
        paintPool: paintPool,
        pathPool: pathPool,
        textPainterPool: textPainterPool,
        textCache: textCache,
        performanceMonitor: perfMonitor,
      );
    }

    test('Renders 10,000 points with straight lines in <16ms', () {
      // Generate 10,000 data points
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
      );
      final series = ChartSeries(id: 'test', points: points);

      // Create line chart layer
      final layer = LineChartLayer(
        series: [series],
        config: const LineChartConfig(
          lineStyle: LineStyle.straight,
          markerShape: MarkerShape.circle,
          markerSize: 4.0,
          showMarkers: true,
          lineWidth: 2.0,
          connectNulls: false,
        ),
        theme: const ChartTheme(),
        animationConfig: const ChartAnimationConfig(),
        zIndex: 0,
      );

      final context = createContext();

      // Warm up (run once to prime pools)
      layer.render(context);

      // Benchmark render time
      final stopwatch = Stopwatch()..start();
      layer.render(context);
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMicroseconds / 1000;

      // Constitutional requirement: <16ms frame time
      expect(elapsedMs, lessThan(16.0),
          reason:
              'Straight line render took ${elapsedMs}ms, exceeds 16ms budget');
    });

    test('Renders 10,000 points with smooth bezier in <16ms', () {
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
      );
      final series = ChartSeries(id: 'test', points: points);

      final layer = LineChartLayer(
        series: [series],
        config: const LineChartConfig(
          lineStyle: LineStyle.smooth,
          markerShape: MarkerShape.circle,
          markerSize: 4.0,
          showMarkers: true,
          lineWidth: 2.0,
          connectNulls: false,
        ),
        theme: const ChartTheme(),
        animationConfig: const ChartAnimationConfig(),
        zIndex: 0,
      );

      final context = createContext();
      layer.render(context);

      final stopwatch = Stopwatch()..start();
      layer.render(context);
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
      expect(elapsedMs, lessThan(16.0),
          reason:
              'Smooth bezier render took ${elapsedMs}ms, exceeds 16ms budget');
    });

    test('Renders 10,000 points with stepped lines in <16ms', () {
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
      );
      final series = ChartSeries(id: 'test', points: points);

      final layer = LineChartLayer(
        series: [series],
        config: const LineChartConfig(
          lineStyle: LineStyle.stepped,
          markerShape: MarkerShape.circle,
          markerSize: 4.0,
          showMarkers: true,
          lineWidth: 2.0,
          connectNulls: false,
        ),
        theme: const ChartTheme(),
        animationConfig: const ChartAnimationConfig(),
        zIndex: 0,
      );

      final context = createContext();
      layer.render(context);

      final stopwatch = Stopwatch()..start();
      layer.render(context);
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
      expect(elapsedMs, lessThan(16.0),
          reason:
              'Stepped line render took ${elapsedMs}ms, exceeds 16ms budget');
    });

    test('Renders with all 6 marker shapes in <16ms', () {
      final markerShapes = [
        MarkerShape.circle,
        MarkerShape.square,
        MarkerShape.triangle,
        MarkerShape.diamond,
        MarkerShape.cross,
        MarkerShape.plus,
      ];

      for (final shape in markerShapes) {
        final points = List.generate(
          10000,
          (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
        );
        final series = ChartSeries(id: 'test-$shape', points: points);

        final layer = LineChartLayer(
          series: [series],
          config: LineChartConfig(
            lineStyle: LineStyle.straight,
            markerShape: shape,
            markerSize: 4.0,
            showMarkers: true,
            lineWidth: 2.0,
            connectNulls: false,
          ),
          theme: const ChartTheme(),
          animationConfig: const ChartAnimationConfig(),
          zIndex: 0,
        );

        final context = createContext();
        layer.render(context);

        final stopwatch = Stopwatch()..start();
        layer.render(context);
        stopwatch.stop();

        final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
        expect(elapsedMs, lessThan(16.0),
            reason:
                'Marker shape $shape render took ${elapsedMs}ms, exceeds 16ms budget');
      }
    });

    test('Object pool hit rate > 90%', () {
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
      );
      final series = ChartSeries(id: 'test', points: points);

      final layer = LineChartLayer(
        series: [series],
        config: const LineChartConfig(
          lineStyle: LineStyle.straight,
          markerShape: MarkerShape.circle,
          markerSize: 4.0,
          showMarkers: true,
          lineWidth: 2.0,
          connectNulls: false,
        ),
        theme: const ChartTheme(),
        animationConfig: const ChartAnimationConfig(),
        zIndex: 0,
      );

      final context = createContext();

      // Render multiple times to build up pool statistics
      for (var i = 0; i < 10; i++) {
        layer.render(context);
      }

      // Check paint pool statistics
      final paintStats = paintPool.statistics;

      // Constitutional requirement: >90% hit rate
      // Note: LineInterpolator uses internal path caching, not the RenderContext path pool,
      // so we only check paint pool hit rate here.
      expect(paintStats.hitRate, greaterThan(0.9),
          reason: 'Paint pool hit rate ${paintStats.hitRate} < 90%');
    });
  });
}

// Mock canvas for performance testing (does nothing)
class _MockCanvas implements Canvas {
  @override
  void drawPath(Path path, Paint paint) {}

  @override
  void drawCircle(Offset c, double radius, Paint paint) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
