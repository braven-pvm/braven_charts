// Performance Benchmark: AreaChartLayer
// Feature: 005-chart-types
// Task: T057
// Purpose: Validate <16ms frame time for 10,000 points in area charts
//
// Constitutional Requirement: Performance benchmarks must pass before merge

import 'dart:ui' as ui;

import 'package:braven_charts/src/charts/area/area_chart_config.dart';
import 'package:braven_charts/src/charts/area/area_chart_layer.dart';
import 'package:braven_charts/src/charts/base/chart_layer.dart';
import 'package:braven_charts/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/src/foundation/data_models/chart_series.dart';
import 'package:braven_charts/src/foundation/performance/object_pool.dart';
import 'package:braven_charts/src/foundation/performance/viewport_culler.dart';
import 'package:braven_charts/src/rendering/performance_monitor.dart';
import 'package:braven_charts/src/rendering/render_context.dart';
import 'package:braven_charts/src/rendering/text_layout_cache.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AreaChartLayer Performance Benchmarks', () {
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

    test('Renders 10,000 points with solid fill in <16ms', () {
      // Generate 10,000 data points
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
      );
      final series = ChartSeries(id: 'test', points: points);

      // Create area chart layer with solid fill
      final layer = AreaChartLayer(
        series: [series],
        config: const AreaChartConfig(
          fillStyle: AreaFillStyle.solid,
          baseline: AreaBaseline.zero(),
          stacked: false,
          fillOpacity: 0.7,
          showLine: false,
        ),
        theme: const ChartTheme(),
        animationConfig: const ChartAnimationConfig(),
        zIndex: 0,
      );

      final context = createContext();

      // Warm up
      layer.render(context);

      // Benchmark render time
      final stopwatch = Stopwatch()..start();
      layer.render(context);
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
      expect(elapsedMs, lessThan(16.0),
          reason: 'Solid fill render took ${elapsedMs}ms, exceeds 16ms budget');
    });

    test('Renders 10,000 points with gradient fill in <16ms', () {
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
      );
      final series = ChartSeries(id: 'test', points: points);

      final layer = AreaChartLayer(
        series: [series],
        config: const AreaChartConfig(
          fillStyle: AreaFillStyle.gradient,
          baseline: AreaBaseline.zero(),
          stacked: false,
          fillOpacity: 0.7,
          showLine: false,
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
              'Gradient fill render took ${elapsedMs}ms, exceeds 16ms budget');
    });

    test('Renders 10,000 points with pattern fill in <16ms', () {
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
      );
      final series = ChartSeries(id: 'test', points: points);

      final layer = AreaChartLayer(
        series: [series],
        config: const AreaChartConfig(
          fillStyle: AreaFillStyle.pattern,
          baseline: AreaBaseline.zero(),
          stacked: false,
          fillOpacity: 0.7,
          showLine: false,
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
              'Pattern fill render took ${elapsedMs}ms, exceeds 16ms budget');
    });

    test('Renders 3 stacked series (30K total points) in <16ms', () {
      // Create 3 series with 10,000 points each
      final series1 = ChartSeries(
        id: 'series1',
        points: List.generate(
          10000,
          (i) => ChartDataPoint(x: i.toDouble(), y: (i % 30).toDouble()),
        ),
      );
      final series2 = ChartSeries(
        id: 'series2',
        points: List.generate(
          10000,
          (i) => ChartDataPoint(x: i.toDouble(), y: (i % 40).toDouble()),
        ),
      );
      final series3 = ChartSeries(
        id: 'series3',
        points: List.generate(
          10000,
          (i) => ChartDataPoint(x: i.toDouble(), y: (i % 50).toDouble()),
        ),
      );

      final layer = AreaChartLayer(
        series: [series1, series2, series3],
        config: const AreaChartConfig(
          fillStyle: AreaFillStyle.solid,
          baseline: AreaBaseline.zero(),
          stacked: true,
          fillOpacity: 0.7,
          showLine: false,
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
              'Stacked areas (30K points) render took ${elapsedMs}ms, exceeds 16ms budget');
    });

    test('Paint pool hit rate > 90%', () {
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
      );
      final series = ChartSeries(id: 'test', points: points);

      final layer = AreaChartLayer(
        series: [series],
        config: const AreaChartConfig(
          fillStyle: AreaFillStyle.solid,
          baseline: AreaBaseline.zero(),
          stacked: false,
          fillOpacity: 0.7,
          showLine: false,
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
