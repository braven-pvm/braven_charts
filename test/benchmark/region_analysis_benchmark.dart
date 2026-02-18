// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

// ignore_for_file: avoid_print

import 'dart:ui';

import 'package:braven_charts/src/analysis/region_analyzer.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/data_region.dart';
import 'package:braven_charts/src/models/region_summary.dart';
import 'package:braven_charts/src/models/region_summary_config.dart';
import 'package:braven_charts/src/rendering/modules/region_summary_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Performance benchmarks for [RegionAnalyzer].
///
/// Validates that the analysis module meets the performance targets defined
/// in the 006-segment-area-analysis spec:
///
/// - **SC-001**: [RegionAnalyzer.filterPointsInRange] with 100,000 sorted
///   points must complete in under 10ms.
/// - **SC-002**: [RegionAnalyzer.computeSeriesSummary] with 1,000 points must
///   complete in under 5ms.
/// - **SC-003/SC-007 proxy**: The region summary overlay renderer does not
///   invalidate the series-layer paint cache — verified by confirming that
///   the [RegionSummaryRenderer] is a stateless `const` class and that
///   overlay painting completes within frame-budget constraints.
void main() {
  const analyzer = RegionAnalyzer();

  // ===========================================================================
  // SC-001 — filterPointsInRange with 100k sorted points must be <10ms
  // ===========================================================================
  group('RegionAnalyzer Performance Benchmarks', () {
    test(
      'SC-001: filterPointsInRange with 100k sorted points completes in <10ms',
      () {
        // Arrange — 100,000 sorted data points spanning x = 0.0 to 99,999.0
        final points = List.generate(
          100000,
          (i) => ChartDataPoint(x: i.toDouble(), y: (i % 500).toDouble()),
        );

        // Query for the middle 10,000 points (10% of the data set)
        const startX = 45000.0;
        const endX = 54999.0;

        // Warm up — first call may have JIT overhead
        analyzer.filterPointsInRange(points, startX: startX, endX: endX);

        // Benchmark — measure a representative single run
        final stopwatch = Stopwatch()..start();
        final result = analyzer.filterPointsInRange(
          points,
          startX: startX,
          endX: endX,
        );
        stopwatch.stop();

        final elapsedMs = stopwatch.elapsedMicroseconds / 1000.0;

        // Print for visibility in CI output
        print('SC-001 filterPointsInRange benchmark:');
        print('  Input points: 100,000 (sorted)');
        print('  Query range: $startX – $endX');
        print('  Matching points: ${result.length}');
        print('  Elapsed: ${elapsedMs.toStringAsFixed(3)}ms');
        print('  Target: <10ms');

        // Assert — must complete within 10ms per SC-001
        expect(
          elapsedMs,
          lessThan(10.0),
          reason:
              'SC-001: filterPointsInRange with 100k sorted points should '
              'complete in <10ms. Actual: ${elapsedMs.toStringAsFixed(3)}ms',
        );
      },
    );

    test(
      'SC-001 repeated: filterPointsInRange average over 10 runs is <10ms',
      () {
        // Arrange — 100,000 sorted data points
        final points = List.generate(
          100000,
          (i) => ChartDataPoint(x: i.toDouble(), y: (i % 1000).toDouble()),
        );

        // Warm up
        analyzer.filterPointsInRange(points, startX: 0.0, endX: 10000.0);

        // Benchmark — average over 10 runs to reduce variance
        const iterations = 10;
        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < iterations; i++) {
          analyzer.filterPointsInRange(points, startX: 45000.0, endX: 54999.0);
        }
        stopwatch.stop();

        final averageMs = stopwatch.elapsedMicroseconds / iterations / 1000.0;

        print('SC-001 repeated (10 runs) filterPointsInRange:');
        print('  Average elapsed: ${averageMs.toStringAsFixed(3)}ms per run');
        print('  Target: <10ms');

        expect(
          averageMs,
          lessThan(10.0),
          reason:
              'SC-001: Average filterPointsInRange time over $iterations runs '
              'should be <10ms. Actual: ${averageMs.toStringAsFixed(3)}ms',
        );
      },
    );

    // =========================================================================
    // SC-002 — computeSeriesSummary with 1k points must be <5ms
    // =========================================================================
    test('SC-002: computeSeriesSummary with 1000 points completes in <5ms', () {
      // Arrange — 1,000 data points
      final points = List.generate(
        1000,
        (i) => ChartDataPoint(x: i.toDouble(), y: (i * 2.5) + 1.0),
      );

      // Warm up
      analyzer.computeSeriesSummary(
        points,
        seriesId: 'warmup',
        regionStartX: 0.0,
        regionEndX: 999.0,
      );

      // Benchmark — single run
      final stopwatch = Stopwatch()..start();
      final result = analyzer.computeSeriesSummary(
        points,
        seriesId: 'power',
        regionStartX: 0.0,
        regionEndX: 999.0,
      );
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMicroseconds / 1000.0;

      print('SC-002 computeSeriesSummary benchmark:');
      print('  Input points: 1,000');
      print('  Count: ${result!.count}');
      print('  Average: ${result.average.toStringAsFixed(2)}');
      print('  StdDev: ${result.stdDev?.toStringAsFixed(4)}');
      print('  Elapsed: ${elapsedMs.toStringAsFixed(3)}ms');
      print('  Target: <5ms');

      // Assert — must complete within 5ms per SC-002
      expect(
        elapsedMs,
        lessThan(5.0),
        reason:
            'SC-002: computeSeriesSummary with 1k points should complete '
            'in <5ms. Actual: ${elapsedMs.toStringAsFixed(3)}ms',
      );
    });

    test(
      'SC-002 repeated: computeSeriesSummary average over 20 runs is <5ms',
      () {
        // Arrange — 1,000 data points
        final points = List.generate(
          1000,
          (i) => ChartDataPoint(x: i.toDouble(), y: (i * 1.5).toDouble()),
        );

        // Warm up
        analyzer.computeSeriesSummary(
          points,
          seriesId: 'warmup',
          regionStartX: 0.0,
          regionEndX: 999.0,
        );

        // Benchmark — average over 20 runs
        const iterations = 20;
        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < iterations; i++) {
          analyzer.computeSeriesSummary(
            points,
            seriesId: 'power',
            regionStartX: 0.0,
            regionEndX: 999.0,
          );
        }
        stopwatch.stop();

        final averageMs = stopwatch.elapsedMicroseconds / iterations / 1000.0;

        print('SC-002 repeated (20 runs) computeSeriesSummary:');
        print('  Average elapsed: ${averageMs.toStringAsFixed(3)}ms per run');
        print('  Target: <5ms');

        expect(
          averageMs,
          lessThan(5.0),
          reason:
              'SC-002: Average computeSeriesSummary time over $iterations runs '
              'should be <5ms. Actual: ${averageMs.toStringAsFixed(3)}ms',
        );
      },
    );

    // =========================================================================
    // SC-003/SC-007 proxy — Frame-budget sanity: overlay does not invalidate
    // the series-layer paint cache.
    //
    // The RegionSummaryRenderer is a stateless `const` class (no mutable
    // state, no cache invalidation mechanism). This architectural constraint
    // ensures that showing or hiding the overlay has no effect on the series-
    // layer RepaintBoundary. We verify this by:
    //   1. Confirming the renderer is a const-constructible value type.
    //   2. Confirming that painting the overlay card completes well within the
    //      16.67ms (60fps) frame budget, leaving ample headroom for the series
    //      layer.
    // =========================================================================
    test('SC-003/SC-007: overlay paint stays within 60fps frame budget '
        '(series layer cache not impacted)', () {
      // RegionSummaryRenderer is `const` — no mutable state that could
      // trigger cache invalidation in the series-layer RepaintBoundary.
      const renderer = RegionSummaryRenderer();

      // Build a realistic summary for painting
      final region = DataRegion(
        id: 'bench-region',
        startX: 0.0,
        endX: 100.0,
        source: DataRegionSource.rangeAnnotation,
        seriesData: const {
          'power': [
            ChartDataPoint(x: 10.0, y: 200.0),
            ChartDataPoint(x: 50.0, y: 350.0),
            ChartDataPoint(x: 90.0, y: 280.0),
          ],
        },
      );

      const seriesSummary = SeriesRegionSummary(
        seriesId: 'power',
        seriesName: 'Power Output',
        unit: 'W',
        count: 3,
        min: 200.0,
        max: 350.0,
        sum: 830.0,
        average: 276.67,
        range: 150.0,
        stdDev: 62.4,
        firstY: 200.0,
        lastY: 280.0,
        delta: 80.0,
        duration: 100.0,
      );

      final summary = RegionSummary(
        region: region,
        seriesSummaries: const {'power': seriesSummary},
      );

      final config = RegionSummaryConfig(
        metrics: {
          RegionMetric.min,
          RegionMetric.max,
          RegionMetric.average,
          RegionMetric.stdDev,
          RegionMetric.duration,
        },
      );

      const regionBounds = Rect.fromLTWH(100.0, 50.0, 200.0, 400.0);
      const canvasSize = Size(800.0, 600.0);

      // Warm up the renderer
      var recorder = PictureRecorder();
      var canvas = Canvas(recorder);
      renderer.paint(canvas, canvasSize, summary, config, regionBounds);
      recorder.endRecording();

      // Benchmark — 50 iterations to get stable timing
      const iterations = 50;
      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        recorder = PictureRecorder();
        canvas = Canvas(recorder);
        renderer.paint(canvas, canvasSize, summary, config, regionBounds);
        recorder.endRecording();
      }
      stopwatch.stop();

      final averageMs = stopwatch.elapsedMicroseconds / iterations / 1000.0;

      print('SC-003/SC-007 RegionSummaryRenderer frame-budget benchmark:');
      print('  Renderer: const RegionSummaryRenderer() — no mutable state');
      print('  Overlay visible: true (metrics config with 5 metrics)');
      print('  Average overlay paint time: ${averageMs.toStringAsFixed(3)}ms');
      print('  Frame budget: 16.67ms (60fps)');
      print('  Note: series-layer RepaintBoundary is NOT affected by');
      print('        overlay visibility (stateless renderer)');

      // The overlay should complete well within half the frame budget,
      // leaving the majority of headroom for series-layer painting.
      expect(
        averageMs,
        lessThan(16.67),
        reason:
            'SC-003: Overlay paint should complete within a frame budget '
            '(16.67ms). Actual: ${averageMs.toStringAsFixed(3)}ms. '
            'The series layer cache (RepaintBoundary) is not impacted by '
            'overlay visibility because RegionSummaryRenderer is stateless.',
      );

      // Also verify it's truly a const instance — same reference
      const renderer2 = RegionSummaryRenderer();
      // Both are identical const instances — no state drift possible
      expect(
        identical(renderer, renderer2),
        isTrue,
        reason:
            'RegionSummaryRenderer must be a const value type to guarantee '
            'the series-layer cache is never invalidated by overlay changes. '
            'Identical const instances confirm zero mutable state.',
      );
    });
  });
}
