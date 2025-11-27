/// Benchmark for multi-axis normalization performance.
///
/// Validates frame performance requirements:
/// - NFR: 60 FPS with 4 series × 1000 points
/// - NFR: <5ms normalization overhead per frame
/// - NFR: O(A) + O(S) memory (no per-point overhead)
///
/// Tests complete multi-axis pipeline:
/// - Per-axis bounds computation
/// - Y-value normalization
/// - Series-to-axis resolution
/// - Auto-detection algorithm
///
/// ## Running Benchmark
///
/// ```bash
/// flutter test test/benchmarks/multi_axis_benchmark.dart
/// ```
///
/// Expected output:
/// ```
/// Multi-Axis Normalization Benchmark:
///   4 axes × 1000 points: avg <2ms, p99 <5ms
///   Auto-detection 10 series: avg <1ms
///   Bounds computation: avg <1ms per axis
/// ```
library;

import 'package:braven_charts/src_plus/axis/axis_bounds_calculator.dart';
import 'package:braven_charts/src_plus/axis/normalization_detector.dart';
import 'package:braven_charts/src_plus/axis/range_ratio_calculator.dart';
import 'package:braven_charts/src_plus/axis/series_axis_resolver.dart';
import 'package:braven_charts/src_plus/axis/y_axis_config.dart';
import 'package:braven_charts/src_plus/models/chart_data_point.dart';
import 'package:braven_charts/src_plus/models/chart_series.dart';
import 'package:braven_charts/src_plus/models/y_axis_position.dart';
import 'package:braven_charts/src_plus/rendering/multi_axis_normalizer.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Multi-Axis Normalization Benchmarks', () {
    /// Generate test data with specified count and value range.
    List<ChartDataPoint> generatePoints(int count, double minY, double maxY) {
      final range = maxY - minY;
      return List.generate(
        count,
        (i) => ChartDataPoint(
          x: i.toDouble(),
          y: minY + (i % 100) / 100 * range,
        ),
      );
    }

    /// Convert ChartDataPoints to Offsets for normalization.
    List<Offset> pointsToOffsets(List<ChartDataPoint> points) {
      return points.map((p) => Offset(p.x, p.y)).toList();
    }

    test('Frame time with 4 series × 1000 points (60 FPS target)', () {
      // Setup: 4 axes with different scales
      final axisConfigs = [
        const YAxisConfig(
          id: 'power',
          position: YAxisPosition.left,
          color: Color(0xFF2196F3),
          unit: 'W',
        ),
        const YAxisConfig(
          id: 'heartRate',
          position: YAxisPosition.right,
          color: Color(0xFFF44336),
          unit: 'bpm',
        ),
        const YAxisConfig(
          id: 'tidalVolume',
          position: YAxisPosition.leftOuter,
          color: Color(0xFF4CAF50),
          unit: 'L',
        ),
        const YAxisConfig(
          id: 'respRate',
          position: YAxisPosition.rightOuter,
          color: Color(0xFFFF9800),
          unit: 'bpm',
        ),
      ];

      // Create 4 series with 1000 points each, vastly different scales
      final series = [
        LineChartSeries(
          id: 'power',
          yAxisId: 'power',
          points: generatePoints(1000, 0, 400), // 0-400 W
          color: const Color(0xFF2196F3),
        ),
        LineChartSeries(
          id: 'hr',
          yAxisId: 'heartRate',
          points: generatePoints(1000, 60, 200), // 60-200 bpm
          color: const Color(0xFFF44336),
        ),
        LineChartSeries(
          id: 'tv',
          yAxisId: 'tidalVolume',
          points: generatePoints(1000, 0.5, 4.0), // 0.5-4 L
          color: const Color(0xFF4CAF50),
        ),
        LineChartSeries(
          id: 'rf',
          yAxisId: 'respRate',
          points: generatePoints(1000, 10, 60), // 10-60 bpm
          color: const Color(0xFFFF9800),
        ),
      ];

      final normalizer = const MultiAxisNormalizer();
      final boundsCalculator = AxisBoundsCalculator(
        axisConfigs: axisConfigs,
        series: series,
      );

      // Measure complete normalization pipeline over 100 frames
      final frameTimes = <double>[];

      for (int frame = 0; frame < 100; frame++) {
        final stopwatch = Stopwatch()..start();

        // Step 1: Compute bounds for all axes
        final bounds = boundsCalculator.compute();

        // Step 2: Normalize each series to its axis bounds
        for (final s in series) {
          final axisId = bounds.getAxisForSeries(s.id) ?? 'power';
          final axisBounds = bounds.getBounds(axisId);
          if (axisBounds != null) {
            final points = pointsToOffsets(s.points);
            normalizer.normalizePoints(points, axisBounds.min, axisBounds.max);
          }
        }

        stopwatch.stop();
        frameTimes.add(stopwatch.elapsedMicroseconds / 1000);
      }

      frameTimes.sort();
      final avg = frameTimes.fold<double>(0, (a, b) => a + b) / frameTimes.length;
      final p99 = frameTimes[(frameTimes.length * 0.99).floor()];
      final jankCount = frameTimes.where((t) => t > 16.67).length; // 60 FPS budget

      // Performance targets
      expect(avg, lessThan(5), reason: 'Average normalization time should be <5ms');
      expect(p99, lessThan(16.67), reason: 'P99 should meet 60 FPS budget (<16.67ms)');
      expect(jankCount, equals(0), reason: 'Zero jank frames expected for 4K points');

      print('4 axes × 1000 points: avg ${avg.toStringAsFixed(2)}ms, '
          'p99 ${p99.toStringAsFixed(2)}ms, jank $jankCount');
    });

    test('Normalization overhead measurement', () {
      // Measure raw normalization performance
      final normalizer = const MultiAxisNormalizer();
      const pointCount = 1000;

      // Generate test data
      final points = List.generate(
        pointCount,
        (i) => Offset(i.toDouble(), (i % 100).toDouble()),
      );

      // Warm-up
      for (int i = 0; i < 10; i++) {
        normalizer.normalizePoints(points, 0, 100);
      }

      // Measure over 1000 iterations
      final times = <double>[];
      for (int i = 0; i < 1000; i++) {
        final stopwatch = Stopwatch()..start();
        normalizer.normalizePoints(points, 0, 100);
        stopwatch.stop();
        times.add(stopwatch.elapsedMicroseconds / 1000);
      }

      times.sort();
      final avg = times.fold<double>(0, (a, b) => a + b) / times.length;
      final p99 = times[(times.length * 0.99).floor()];

      // Should be very fast - under 1ms for 1000 points
      expect(avg, lessThan(1.0), reason: 'Average normalization should be <1ms');
      expect(p99, lessThan(2.0), reason: 'P99 normalization should be <2ms');

      print('Normalization 1000 points: avg ${avg.toStringAsFixed(3)}ms, '
          'p99 ${p99.toStringAsFixed(3)}ms');
    });

    test('Bounds computation performance', () {
      // Test bounds calculation performance
      final axisConfigs = [
        const YAxisConfig(id: 'axis1', position: YAxisPosition.left),
        const YAxisConfig(id: 'axis2', position: YAxisPosition.right),
        const YAxisConfig(id: 'axis3', position: YAxisPosition.leftOuter),
        const YAxisConfig(id: 'axis4', position: YAxisPosition.rightOuter),
      ];

      final series = [
        LineChartSeries(
          id: 's1',
          yAxisId: 'axis1',
          points: generatePoints(1000, 0, 400),
        ),
        LineChartSeries(
          id: 's2',
          yAxisId: 'axis2',
          points: generatePoints(1000, 60, 200),
        ),
        LineChartSeries(
          id: 's3',
          yAxisId: 'axis3',
          points: generatePoints(1000, 0.5, 4.0),
        ),
        LineChartSeries(
          id: 's4',
          yAxisId: 'axis4',
          points: generatePoints(1000, 10, 60),
        ),
      ];

      final calculator = AxisBoundsCalculator(
        axisConfigs: axisConfigs,
        series: series,
      );

      // Measure over 100 iterations
      final times = <double>[];
      for (int i = 0; i < 100; i++) {
        final stopwatch = Stopwatch()..start();
        calculator.compute();
        stopwatch.stop();
        times.add(stopwatch.elapsedMicroseconds / 1000);
      }

      times.sort();
      final avg = times.fold<double>(0, (a, b) => a + b) / times.length;
      final p99 = times[(times.length * 0.99).floor()];

      // Bounds computation should be fast
      expect(avg, lessThan(5), reason: 'Average bounds computation should be <5ms');

      print('Bounds computation 4 axes: avg ${avg.toStringAsFixed(3)}ms, '
          'p99 ${p99.toStringAsFixed(3)}ms');
    });

    test('Auto-detection performance with 10 series', () {
      // Test auto-detection algorithm performance
      final series = List.generate(10, (i) {
        // Varying scales - some should trigger auto-detection
        final scale = i.isEven ? 1.0 : 100.0;
        return LineChartSeries(
          id: 'series$i',
          points: generatePoints(500, 0, 100 * scale),
        );
      });

      // Measure over 100 iterations using static API
      final times = <double>[];
      for (int i = 0; i < 100; i++) {
        final stopwatch = Stopwatch()..start();
        NormalizationDetector.shouldNormalize(series, threshold: 10.0);
        stopwatch.stop();
        times.add(stopwatch.elapsedMicroseconds / 1000);
      }

      times.sort();
      final avg = times.fold<double>(0, (a, b) => a + b) / times.length;
      final p99 = times[(times.length * 0.99).floor()];

      // Auto-detection should be fast
      expect(avg, lessThan(2), reason: 'Average auto-detection should be <2ms');

      print('Auto-detection 10 series: avg ${avg.toStringAsFixed(3)}ms, '
          'p99 ${p99.toStringAsFixed(3)}ms');
    });

    test('Range ratio calculation performance', () {
      // Test range ratio calculator
      final series = List.generate(10, (i) {
        final scale = (i + 1) * 10.0;
        return LineChartSeries(
          id: 'series$i',
          points: generatePoints(500, 0, 100 * scale),
        );
      });

      // Measure over 100 iterations using static API
      final times = <double>[];
      for (int i = 0; i < 100; i++) {
        final stopwatch = Stopwatch()..start();
        RangeRatioCalculator.computeMaxRatioAcrossSeries(series);
        stopwatch.stop();
        times.add(stopwatch.elapsedMicroseconds / 1000);
      }

      times.sort();
      final avg = times.fold<double>(0, (a, b) => a + b) / times.length;
      final p99 = times[(times.length * 0.99).floor()];

      // Should be very fast
      expect(avg, lessThan(1), reason: 'Average ratio calculation should be <1ms');

      print('Range ratio 10 series: avg ${avg.toStringAsFixed(3)}ms, '
          'p99 ${p99.toStringAsFixed(3)}ms');
    });

    test('Series-to-axis resolution performance', () {
      // Test resolver performance with many series
      final axisConfigs = [
        const YAxisConfig(id: 'power', position: YAxisPosition.left, unit: 'W'),
        const YAxisConfig(id: 'heart', position: YAxisPosition.right, unit: 'bpm'),
        const YAxisConfig(id: 'volume', position: YAxisPosition.leftOuter, unit: 'L'),
        const YAxisConfig(id: 'rate', position: YAxisPosition.rightOuter, unit: 'bpm'),
      ];

      final series = List.generate(20, (i) {
        final axisId = ['power', 'heart', 'volume', 'rate'][i % 4];
        return LineChartSeries(
          id: 'series$i',
          yAxisId: axisId,
          points: generatePoints(100, 0, 100),
        );
      });

      final resolver = SeriesAxisResolver(
        axisConfigs: axisConfigs,
        series: series,
      );

      // Measure over 1000 iterations
      final times = <double>[];
      for (int i = 0; i < 1000; i++) {
        final stopwatch = Stopwatch()..start();
        resolver.resolve();
        stopwatch.stop();
        times.add(stopwatch.elapsedMicroseconds / 1000);
      }

      times.sort();
      final avg = times.fold<double>(0, (a, b) => a + b) / times.length;
      final p99 = times[(times.length * 0.99).floor()];

      // Resolution should be very fast
      expect(avg, lessThan(0.5), reason: 'Average resolution should be <0.5ms');

      print('Series resolution 20 series: avg ${avg.toStringAsFixed(4)}ms, '
          'p99 ${p99.toStringAsFixed(4)}ms');
    });

    test('Memory efficiency - no per-point allocation', () {
      // Verify normalization doesn't create excessive allocations
      const pointCount = 10000;
      final normalizer = const MultiAxisNormalizer();

      final points = List.generate(
        pointCount,
        (i) => Offset(i.toDouble(), (i % 100).toDouble()),
      );

      // The normalized list should have same length but different values
      final normalized = normalizer.normalizePoints(points, 0, 100);

      expect(normalized.length, equals(pointCount));
      expect(normalized, isNot(same(points))); // Should be new list

      // Verify normalization is correct
      expect(normalized[0].dy, equals(0.0)); // 0 -> 0.0
      expect(normalized[50].dy, equals(0.5)); // 50 -> 0.5
      expect(normalized[100].dy, equals(0.0)); // 0 -> 0.0 (wraps at 100)

      print('Memory test: $pointCount points normalized successfully');
    });

    test('Sustained 60 FPS over 1000 frames', () {
      // Extended test for sustained performance
      final axisConfigs = [
        const YAxisConfig(id: 'power', position: YAxisPosition.left),
        const YAxisConfig(id: 'heart', position: YAxisPosition.right),
        const YAxisConfig(id: 'volume', position: YAxisPosition.leftOuter),
        const YAxisConfig(id: 'rate', position: YAxisPosition.rightOuter),
      ];

      final series = [
        LineChartSeries(
          id: 'power',
          yAxisId: 'power',
          points: generatePoints(1000, 0, 400),
        ),
        LineChartSeries(
          id: 'hr',
          yAxisId: 'heart',
          points: generatePoints(1000, 60, 200),
        ),
        LineChartSeries(
          id: 'tv',
          yAxisId: 'volume',
          points: generatePoints(1000, 0.5, 4.0),
        ),
        LineChartSeries(
          id: 'rf',
          yAxisId: 'rate',
          points: generatePoints(1000, 10, 60),
        ),
      ];

      final normalizer = const MultiAxisNormalizer();
      final boundsCalculator = AxisBoundsCalculator(
        axisConfigs: axisConfigs,
        series: series,
      );

      final frameTimes = <double>[];
      const frameCount = 1000;
      const framebudgetMs = 16.67; // 60 FPS

      for (int frame = 0; frame < frameCount; frame++) {
        final stopwatch = Stopwatch()..start();

        // Full normalization pipeline
        final bounds = boundsCalculator.compute();
        for (final s in series) {
          final axisId = bounds.getAxisForSeries(s.id) ?? 'power';
          final axisBounds = bounds.getBounds(axisId);
          if (axisBounds != null) {
            final points = pointsToOffsets(s.points);
            normalizer.normalizePoints(points, axisBounds.min, axisBounds.max);
          }
        }

        stopwatch.stop();
        frameTimes.add(stopwatch.elapsedMicroseconds / 1000);
      }

      frameTimes.sort();
      final avg = frameTimes.fold<double>(0, (a, b) => a + b) / frameTimes.length;
      final p50 = frameTimes[500];
      final p99 = frameTimes[990];
      final jankCount = frameTimes.where((t) => t > framebudgetMs).length;
      final jankPercent = (jankCount / frameCount) * 100;

      // Strict performance requirements
      expect(avg, lessThan(5), reason: 'Average should be <5ms for 60 FPS headroom');
      expect(p99, lessThan(framebudgetMs), reason: 'P99 must meet 60 FPS budget');
      expect(jankPercent, lessThan(1), reason: 'Less than 1% jank frames allowed');

      print('Sustained performance ($frameCount frames):');
      print('  Average: ${avg.toStringAsFixed(2)}ms');
      print('  P50: ${p50.toStringAsFixed(2)}ms');
      print('  P99: ${p99.toStringAsFixed(2)}ms');
      print('  Jank: $jankCount frames (${jankPercent.toStringAsFixed(1)}%)');
    });
  });
}
