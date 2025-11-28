// Performance Benchmark: BarChartLayer
// Feature: 005-chart-types
// Task: T058
// Purpose: Validate <16ms frame time for 1,000 bars in bar charts
//
// Constitutional Requirement: Performance benchmarks must pass before merge

import 'dart:ui' as ui;

import 'package:braven_charts/legacy/src/charts/bar/bar_chart_config.dart';
import 'package:braven_charts/legacy/src/charts/bar/bar_chart_layer.dart';
import 'package:braven_charts/legacy/src/charts/base/chart_layer.dart';
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
  group('BarChartLayer Performance Benchmarks', () {
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
        viewport: const ui.Rect.fromLTWH(0, 0, 1000, 100),
        culler: const ViewportCuller(),
        paintPool: paintPool,
        pathPool: pathPool,
        textPainterPool: textPainterPool,
        textCache: textCache,
        performanceMonitor: perfMonitor,
      );
    }

    test('Renders 1,000 vertical bars (grouped) in <16ms', () {
      // Generate 1,000 bars across 500 categories with 2 series
      final series1 = ChartSeries(
        id: 'series1',
        points: List.generate(
          500,
          (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
        ),
      );
      final series2 = ChartSeries(
        id: 'series2',
        points: List.generate(
          500,
          (i) =>
              ChartDataPoint(x: i.toDouble(), y: ((i + 50) % 100).toDouble()),
        ),
      );

      final layer = BarChartLayer(
        series: [series1, series2],
        config: const BarChartConfig(
          orientation: BarOrientation.vertical,
          groupingMode: BarGroupingMode.grouped,
          barWidthRatio: 0.8,
          barSpacing: 2.0,
          groupSpacing: 8.0,
          cornerRadius: 0.0,
          borderWidth: 0.0,
          useGradient: false,
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
          reason:
              'Vertical grouped bars render took ${elapsedMs}ms, exceeds 16ms budget');
    });

    test('Renders 1,000 horizontal bars (grouped) in <16ms', () {
      final series1 = ChartSeries(
        id: 'series1',
        points: List.generate(
          500,
          (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
        ),
      );
      final series2 = ChartSeries(
        id: 'series2',
        points: List.generate(
          500,
          (i) =>
              ChartDataPoint(x: i.toDouble(), y: ((i + 50) % 100).toDouble()),
        ),
      );

      final layer = BarChartLayer(
        series: [series1, series2],
        config: const BarChartConfig(
          orientation: BarOrientation.horizontal,
          groupingMode: BarGroupingMode.grouped,
          barWidthRatio: 0.8,
          barSpacing: 2.0,
          groupSpacing: 8.0,
          cornerRadius: 0.0,
          borderWidth: 0.0,
          useGradient: false,
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
              'Horizontal grouped bars render took ${elapsedMs}ms, exceeds 16ms budget');
    });

    test('Renders 1,000 stacked bars (vertical) in <16ms', () {
      // 3 series with ~333 points each = ~1,000 bars total
      final series1 = ChartSeries(
        id: 'series1',
        points: List.generate(
          333,
          (i) => ChartDataPoint(x: i.toDouble(), y: (i % 30).toDouble()),
        ),
      );
      final series2 = ChartSeries(
        id: 'series2',
        points: List.generate(
          333,
          (i) => ChartDataPoint(x: i.toDouble(), y: (i % 40).toDouble()),
        ),
      );
      final series3 = ChartSeries(
        id: 'series3',
        points: List.generate(
          334,
          (i) => ChartDataPoint(x: i.toDouble(), y: (i % 50).toDouble()),
        ),
      );

      final layer = BarChartLayer(
        series: [series1, series2, series3],
        config: const BarChartConfig(
          orientation: BarOrientation.vertical,
          groupingMode: BarGroupingMode.stacked,
          barWidthRatio: 0.9,
          barSpacing: 0.0,
          groupSpacing: 4.0,
          cornerRadius: 2.0,
          borderWidth: 0.0,
          useGradient: false,
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
              'Stacked bars render took ${elapsedMs}ms, exceeds 16ms budget');
    });

    test('Renders 1,000 bars with rounded corners and borders in <16ms', () {
      final series1 = ChartSeries(
        id: 'series1',
        points: List.generate(
          500,
          (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
        ),
      );
      final series2 = ChartSeries(
        id: 'series2',
        points: List.generate(
          500,
          (i) =>
              ChartDataPoint(x: i.toDouble(), y: ((i + 50) % 100).toDouble()),
        ),
      );

      final layer = BarChartLayer(
        series: [series1, series2],
        config: const BarChartConfig(
          orientation: BarOrientation.vertical,
          groupingMode: BarGroupingMode.grouped,
          barWidthRatio: 0.8,
          barSpacing: 2.0,
          groupSpacing: 8.0,
          cornerRadius: 4.0,
          borderWidth: 1.0,
          borderColor: 0xFF000000,
          useGradient: false,
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
              'Rounded bars with borders render took ${elapsedMs}ms, exceeds 16ms budget');
    });

    test('Renders 1,000 bars with gradient fill in <16ms', () {
      final series1 = ChartSeries(
        id: 'series1',
        points: List.generate(
          500,
          (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
        ),
      );
      final series2 = ChartSeries(
        id: 'series2',
        points: List.generate(
          500,
          (i) =>
              ChartDataPoint(x: i.toDouble(), y: ((i + 50) % 100).toDouble()),
        ),
      );

      final layer = BarChartLayer(
        series: [series1, series2],
        config: const BarChartConfig(
          orientation: BarOrientation.vertical,
          groupingMode: BarGroupingMode.grouped,
          barWidthRatio: 0.8,
          barSpacing: 2.0,
          groupSpacing: 8.0,
          cornerRadius: 0.0,
          borderWidth: 0.0,
          useGradient: true,
          gradientStart: 0xFF0000FF,
          gradientEnd: 0xFF00FFFF,
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
              'Gradient bars render took ${elapsedMs}ms, exceeds 16ms budget');
    });

    test('Paint pool hit rate > 90%', () {
      final series1 = ChartSeries(
        id: 'series1',
        points: List.generate(
          500,
          (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
        ),
      );
      final series2 = ChartSeries(
        id: 'series2',
        points: List.generate(
          500,
          (i) =>
              ChartDataPoint(x: i.toDouble(), y: ((i + 50) % 100).toDouble()),
        ),
      );

      final layer = BarChartLayer(
        series: [series1, series2],
        config: const BarChartConfig(
          orientation: BarOrientation.vertical,
          groupingMode: BarGroupingMode.grouped,
          barWidthRatio: 0.8,
          barSpacing: 2.0,
          groupSpacing: 8.0,
          cornerRadius: 0.0,
          borderWidth: 0.0,
          useGradient: false,
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
  void drawRect(Rect rect, Paint paint) {}

  @override
  void drawRRect(RRect rrect, Paint paint) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
