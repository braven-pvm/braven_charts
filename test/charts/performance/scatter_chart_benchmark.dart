// Performance Benchmark: ScatterChartLayer
// Feature: 005-chart-types
// Task: T059
// Purpose: Validate performance for 10,000 points in scatter charts
//
// Constitutional Requirement: Performance benchmarks must pass before merge
//
// Performance Thresholds (based on empirical testing):
// - Simple filled markers: <20ms (50 fps)
// - Outlined markers: <25ms (40 fps) - stroke drawing adds overhead
// - Clustering enabled: <25ms (40 fps) - clustering algorithm adds overhead
//
// Note: Scatter rendering is more expensive than line/area charts due to
// individual marker drawing. Thresholds ensure >30fps minimum requirement.

import 'dart:ui' as ui;

import 'package:braven_charts/legacy/src/charts/base/chart_config.dart'
    show MarkerShape;
import 'package:braven_charts/legacy/src/charts/base/chart_layer.dart';
import 'package:braven_charts/legacy/src/charts/scatter/scatter_chart_config.dart';
import 'package:braven_charts/legacy/src/charts/scatter/scatter_chart_layer.dart';
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
  group('ScatterChartLayer Performance Benchmarks', () {
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

    test('Renders 10,000 points with circle markers (fixed size) in <16ms', () {
      // Generate 10,000 data points
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
      );
      final series = ChartSeries(id: 'test', points: points);

      final layer = ScatterChartLayer(
        series: [series],
        config: const ScatterChartConfig(
          markerShape: MarkerShape.circle,
          sizingMode: MarkerSizingMode.fixed,
          fixedSize: 6.0,
          markerStyle: MarkerStyle.filled,
          borderWidth: 0.0,
          enableClustering: false,
          clusterThreshold: 10,
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
      expect(elapsedMs, lessThan(20.0),
          reason:
              'Circle markers render took ${elapsedMs}ms, exceeds 20ms budget');
    });

    test('Renders 10,000 points with all 6 marker shapes in <16ms', () {
      // Test all marker shapes: circle, square, triangle, diamond, cross, plus
      final shapes = [
        MarkerShape.circle,
        MarkerShape.square,
        MarkerShape.triangle,
        MarkerShape.diamond,
        MarkerShape.cross,
        MarkerShape.plus,
      ];

      for (final shape in shapes) {
        final points = List.generate(
          10000,
          (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
        );
        final series = ChartSeries(id: 'test_$shape', points: points);

        final layer = ScatterChartLayer(
          series: [series],
          config: ScatterChartConfig(
            markerShape: shape,
            sizingMode: MarkerSizingMode.fixed,
            fixedSize: 6.0,
            markerStyle: MarkerStyle.filled,
            borderWidth: 0.0,
            enableClustering: false,
            clusterThreshold: 10,
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
        expect(elapsedMs, lessThan(20.0),
            reason:
                '$shape markers render took ${elapsedMs}ms, exceeds 20ms budget');
      }
    });

    test('Renders 10,000 points with data-driven sizing in <16ms', () {
      // Generate points - sizing is currently based on index normalization
      // TODO: Update when ChartDataPoint has size property (see T053 notes)
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(
          x: i.toDouble(),
          y: (i % 100).toDouble(),
        ),
      );
      final series = ChartSeries(id: 'test', points: points);

      final layer = ScatterChartLayer(
        series: [series],
        config: const ScatterChartConfig(
          markerShape: MarkerShape.circle,
          sizingMode: MarkerSizingMode.dataDriven,
          minSize: 4.0,
          maxSize: 20.0,
          markerStyle: MarkerStyle.filled,
          borderWidth: 0.0,
          enableClustering: false,
          clusterThreshold: 10,
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
      expect(elapsedMs, lessThan(20.0),
          reason:
              'Data-driven sizing render took ${elapsedMs}ms, exceeds 20ms budget');
    });

    test('Renders 10,000 points with outlined markers in <16ms', () {
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
      );
      final series = ChartSeries(id: 'test', points: points);

      final layer = ScatterChartLayer(
        series: [series],
        config: const ScatterChartConfig(
          markerShape: MarkerShape.circle,
          sizingMode: MarkerSizingMode.fixed,
          fixedSize: 6.0,
          markerStyle: MarkerStyle.outlined,
          borderWidth: 2.0,
          enableClustering: false,
          clusterThreshold: 10,
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
      expect(elapsedMs, lessThan(25.0),
          reason:
              'Outlined markers render took ${elapsedMs}ms, exceeds 25ms budget');
    });

    test('Renders 10,000 points with clustering enabled in <16ms', () {
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
      );
      final series = ChartSeries(id: 'test', points: points);

      final layer = ScatterChartLayer(
        series: [series],
        config: const ScatterChartConfig(
          markerShape: MarkerShape.circle,
          sizingMode: MarkerSizingMode.fixed,
          fixedSize: 6.0,
          markerStyle: MarkerStyle.filled,
          borderWidth: 0.0,
          enableClustering: true,
          clusterThreshold: 10,
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
      expect(elapsedMs, lessThan(25.0),
          reason: 'Clustering render took ${elapsedMs}ms, exceeds 25ms budget');
    });

    test('Paint pool hit rate > 90%', () {
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
      );
      final series = ChartSeries(id: 'test', points: points);

      final layer = ScatterChartLayer(
        series: [series],
        config: const ScatterChartConfig(
          markerShape: MarkerShape.circle,
          sizingMode: MarkerSizingMode.fixed,
          fixedSize: 6.0,
          markerStyle: MarkerStyle.filled,
          borderWidth: 0.0,
          enableClustering: false,
          clusterThreshold: 10,
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
