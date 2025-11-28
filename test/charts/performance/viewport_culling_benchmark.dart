// Performance Benchmark: Viewport Culling
// Feature: 005-chart-types
// Task: T060
// Purpose: Validate <1ms culling overhead for 10,000 points
//
// Constitutional Requirement: Performance benchmarks must pass before merge
// FR-034: Viewport culling must complete in <1ms for 10,000 points

import 'package:braven_charts/legacy/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/legacy/src/foundation/data_models/data_range.dart';
import 'package:braven_charts/legacy/src/foundation/performance/viewport_culler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Viewport Culling Performance Benchmarks', () {
    late ViewportCuller culler;

    setUp(() {
      culler = const ViewportCuller(margin: 0.1);
    });

    test('Culls 10,000 ordered points in <1ms', () {
      // Generate 10,000 ordered points (x from 0 to 9999)
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
      );

      // Viewport showing 10% of data (1000 points visible)
      final viewportX = const DataRange(min: 4000.0, max: 5000.0);
      final viewportY = const DataRange(min: 0.0, max: 100.0);

      // Warm up
      culler.cull(
        points: points,
        viewportX: viewportX,
        viewportY: viewportY,
        isXOrdered: true,
      );

      // Benchmark culling time
      final stopwatch = Stopwatch()..start();
      final visible = culler.cull(
        points: points,
        viewportX: viewportX,
        viewportY: viewportY,
        isXOrdered: true,
      );
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMicroseconds / 1000;

      // Verify some points were culled
      expect(visible.length, lessThan(points.length),
          reason: 'Expected some points to be culled');

      // Constitutional requirement: <1ms
      expect(elapsedMs, lessThan(1.0),
          reason: 'Ordered culling took ${elapsedMs}ms, exceeds 1ms budget');
    });

    test('Culls 10,000 unordered points in <1ms', () {
      // Generate 10,000 unordered points (random x values)
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(
          x: (i * 37 % 10000).toDouble(), // Pseudo-random x ordering
          y: (i % 100).toDouble(),
        ),
      );

      final viewportX = const DataRange(min: 4000.0, max: 5000.0);
      final viewportY = const DataRange(min: 0.0, max: 100.0);

      // Warm up
      culler.cull(
        points: points,
        viewportX: viewportX,
        viewportY: viewportY,
        isXOrdered: false,
      );

      // Benchmark culling time
      final stopwatch = Stopwatch()..start();
      final visible = culler.cull(
        points: points,
        viewportX: viewportX,
        viewportY: viewportY,
        isXOrdered: false,
      );
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMicroseconds / 1000;

      // Verify some points were culled
      expect(visible.length, lessThan(points.length),
          reason: 'Expected some points to be culled');

      // Constitutional requirement: <1ms
      expect(elapsedMs, lessThan(1.0),
          reason: 'Unordered culling took ${elapsedMs}ms, exceeds 1ms budget');
    });

    test('Culls with different viewport sizes efficiently', () {
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
      );

      // Test various viewport sizes: 1%, 10%, 50%
      // Note: Larger viewports take longer as more points pass through
      final viewportSizes = [
        (100.0, '1%', 1.0), // <1ms for small viewport
        (1000.0, '10%', 1.0), // <1ms for medium viewport
        (
          5000.0,
          '50%',
          2.0
        ), // <2ms for large viewport (more points to process)
      ];

      for (final (size, label, threshold) in viewportSizes) {
        final viewportX = DataRange(min: 0.0, max: size);
        final viewportY = const DataRange(min: 0.0, max: 100.0);

        final stopwatch = Stopwatch()..start();
        culler.cull(
          points: points,
          viewportX: viewportX,
          viewportY: viewportY,
          isXOrdered: true,
        );
        stopwatch.stop();

        final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
        expect(elapsedMs, lessThan(threshold),
            reason:
                'Culling $label viewport took ${elapsedMs}ms, exceeds ${threshold}ms budget');
      }
    });

    test('Margin calculation adds minimal overhead', () {
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
      );

      final viewportX = const DataRange(min: 4000.0, max: 5000.0);
      final viewportY = const DataRange(min: 0.0, max: 100.0);

      // Test with different margin values
      final margins = [0.0, 0.1, 0.2, 0.5];

      for (final marginValue in margins) {
        final cullerWithMargin = ViewportCuller(margin: marginValue);

        final stopwatch = Stopwatch()..start();
        cullerWithMargin.cull(
          points: points,
          viewportX: viewportX,
          viewportY: viewportY,
          isXOrdered: true,
        );
        stopwatch.stop();

        final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
        expect(elapsedMs, lessThan(1.0),
            reason:
                'Culling with margin=$marginValue took ${elapsedMs}ms, exceeds 1ms budget');
      }
    });

    test('Binary search optimization for ordered data', () {
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(x: i.toDouble(), y: (i % 100).toDouble()),
      );

      // Small viewport showing only 100 points
      final viewportX = const DataRange(min: 5000.0, max: 5100.0);
      final viewportY = const DataRange(min: 0.0, max: 100.0);

      final stopwatch = Stopwatch()..start();
      final visible = culler.cull(
        points: points,
        viewportX: viewportX,
        viewportY: viewportY,
        isXOrdered: true,
      );
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMicroseconds / 1000;

      // Binary search should make this very fast (<0.1ms typically)
      expect(elapsedMs, lessThan(1.0),
          reason:
              'Binary search culling took ${elapsedMs}ms, exceeds 1ms budget');

      // Verify we got approximately the right number of visible points
      // With 10% margin on each side, should be roughly 120-140 points
      expect(visible.length, greaterThan(100),
          reason: 'Expected at least 100 visible points');
      expect(visible.length, lessThan(200),
          reason: 'Expected fewer than 200 visible points with margin');
    });

    test('Empty dataset has zero overhead', () {
      final points = <ChartDataPoint>[];
      final viewportX = const DataRange(min: 0.0, max: 100.0);
      final viewportY = const DataRange(min: 0.0, max: 100.0);

      final stopwatch = Stopwatch()..start();
      final visible = culler.cull(
        points: points,
        viewportX: viewportX,
        viewportY: viewportY,
        isXOrdered: true,
      );
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMicroseconds / 1000;

      expect(visible, isEmpty);
      expect(elapsedMs, lessThan(0.1),
          reason:
              'Empty dataset culling took ${elapsedMs}ms, should be near-zero');
    });
  });
}
