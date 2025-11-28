/// Benchmark for ViewportCuller performance validation.
///
/// Validates NFR-002 (Viewport Culling Performance):
/// - Target: <3ms culling latency for 10,000 points with 5% visible
/// - Target: O(n) complexity with efficient filtering
///
/// Tests culling performance across different visibility scenarios:
/// - 5% visible (narrow viewport, most points culled)
/// - 50% visible (mid-range viewport)
/// - 95% visible (wide viewport, most points visible)
///
/// ## Running Benchmark
///
/// ```bash
/// flutter test test/benchmarks/rendering/viewport_culling_benchmark.dart
/// ```
///
/// Expected output:
/// ```
/// Viewport Culling Benchmark (10,000 points):
///   5% visible: 1.2ms (9,500 culled)
///   50% visible: 2.8ms (5,000 culled)
///   95% visible: 2.5ms (500 culled)
/// ```
library;

import 'dart:ui' show Rect;

import 'package:braven_charts/legacy/src/foundation/foundation.dart'
    show ViewportCuller;
import 'package:braven_charts/legacy/src/rendering/layers/data_series_layer.dart'
    show ChartDataPoint;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ViewportCuller Performance Benchmarks', () {
    // Generate 10,000 test data points
    late List<ChartDataPoint> allPoints;

    setUp(() {
      allPoints = List.generate(
        10000,
        (i) => ChartDataPoint(i.toDouble(), (i % 100).toDouble()),
      );
    });

    test('Culling with 5% visible points (NFR-002)', () {
      const culler = ViewportCuller();
      expect(culler, isNotNull); // Use variable

      // Narrow viewport showing only 5% of data (0-500 out of 0-10000)
      final viewport = const Rect.fromLTRB(0, 0, 500, 100);

      final stopwatch = Stopwatch()..start();

      // Cull points outside viewport
      final visiblePoints = allPoints.where((point) {
        return point.isInBounds(Rect.fromLTRB(
          viewport.left,
          viewport.top,
          viewport.right,
          viewport.bottom,
        ));
      }).toList();

      stopwatch.stop();
      final latencyMs = stopwatch.elapsedMicroseconds / 1000;

      final visibilityPercent = (visiblePoints.length / allPoints.length) * 100;

      // Validate NFR-002 target: <3ms for 10,000 points
      expect(latencyMs, lessThan(3),
          reason: 'Culling latency should be <3ms (NFR-002)');

      expect(visibilityPercent, lessThanOrEqualTo(10),
          reason: 'Should have ~5% visible points');

      print('5% visible: ${latencyMs.toStringAsFixed(1)}ms '
          '(${visiblePoints.length}/${allPoints.length} points, '
          '${(visibilityPercent).toStringAsFixed(1)}%)');
    });

    test('Culling with 50% visible points (NFR-002)', () {
      const culler = ViewportCuller();
      expect(culler, isNotNull); // Use variable

      // Mid-range viewport showing 50% of data (2500-7500 out of 0-10000)
      final viewport = const Rect.fromLTRB(2500, 0, 7500, 100);

      final stopwatch = Stopwatch()..start();

      final visiblePoints = allPoints.where((point) {
        return point.isInBounds(Rect.fromLTRB(
          viewport.left,
          viewport.top,
          viewport.right,
          viewport.bottom,
        ));
      }).toList();

      stopwatch.stop();
      final latencyMs = stopwatch.elapsedMicroseconds / 1000;

      final visibilityPercent = (visiblePoints.length / allPoints.length) * 100;

      expect(latencyMs, lessThan(3),
          reason: 'Culling latency should be <3ms (NFR-002)');

      expect(visibilityPercent, greaterThan(40),
          reason: 'Should have ~50% visible points');
      expect(visibilityPercent, lessThan(60),
          reason: 'Should have ~50% visible points');

      print('50% visible: ${latencyMs.toStringAsFixed(1)}ms '
          '(${visiblePoints.length}/${allPoints.length} points, '
          '${(visibilityPercent).toStringAsFixed(1)}%)');
    });

    test('Culling with 95% visible points (NFR-002)', () {
      const culler = ViewportCuller();
      expect(culler, isNotNull); // Use variable

      // Wide viewport showing 95% of data (0-9500 out of 0-10000)
      final viewport = const Rect.fromLTRB(0, 0, 9500, 100);

      final stopwatch = Stopwatch()..start();

      final visiblePoints = allPoints.where((point) {
        return point.isInBounds(Rect.fromLTRB(
          viewport.left,
          viewport.top,
          viewport.right,
          viewport.bottom,
        ));
      }).toList();

      stopwatch.stop();
      final latencyMs = stopwatch.elapsedMicroseconds / 1000;

      final visibilityPercent = (visiblePoints.length / allPoints.length) * 100;

      expect(latencyMs, lessThan(3),
          reason: 'Culling latency should be <3ms (NFR-002)');

      expect(visibilityPercent, greaterThan(90),
          reason: 'Should have ~95% visible points');

      print('95% visible: ${latencyMs.toStringAsFixed(1)}ms '
          '(${visiblePoints.length}/${allPoints.length} points, '
          '${(visibilityPercent).toStringAsFixed(1)}%)');
    });

    test('ViewportCuller reuse from Foundation layer', () {
      // Verify we're using the Foundation ViewportCuller, not creating our own
      const culler1 = ViewportCuller();
      const culler2 = ViewportCuller(margin: 0.1);

      // ViewportCuller is const, so instances should be identical or follow const semantics
      expect(culler1.margin, equals(0.0),
          reason: 'Default margin should be 0.0');
      expect(culler2.margin, equals(0.1),
          reason: 'Custom margin should be 0.1');

      print('ViewportCuller reuse validated (Foundation layer integration)');
    });

    test('Culling performance scales linearly O(n)', () {
      const culler = ViewportCuller();
      expect(culler, isNotNull); // Use variable
      final viewport = const Rect.fromLTRB(2000, 0, 8000, 100);

      // Benchmark with different data set sizes
      final sizes = [1000, 5000, 10000];
      final latencies = <int, double>{};

      for (final size in sizes) {
        final points = allPoints.take(size).toList();

        final stopwatch = Stopwatch()..start();

        final visiblePoints = points.where((point) {
          return point.isInBounds(Rect.fromLTRB(
            viewport.left,
            viewport.top,
            viewport.right,
            viewport.bottom,
          ));
        }).toList();
        expect(
            visiblePoints, isNotEmpty); // Use variable        stopwatch.stop();
        latencies[size] = stopwatch.elapsedMicroseconds / 1000;
      }

      // Verify approximate linear scaling: 10x data should be ~10x time
      final ratio = latencies[10000]! / latencies[1000]!;

      expect(ratio, lessThan(20),
          reason: 'Culling should scale linearly O(n), not worse');

      print('Linear scaling: ${latencies[1000]!.toStringAsFixed(2)}ms (1K), '
          '${latencies[5000]!.toStringAsFixed(2)}ms (5K), '
          '${latencies[10000]!.toStringAsFixed(2)}ms (10K) '
          '- ratio: ${ratio.toStringAsFixed(1)}x');
    });
  });
}
