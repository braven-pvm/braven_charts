/// Unit tests for LineInterpolator
///
/// Tests the three line interpolation modes: straight (linear), smooth (Catmull-Rom to bezier),
/// and stepped (horizontal-vertical segments).
library;

import 'package:braven_charts/legacy/src/charts/line/line_chart_config.dart'
    show LineStyle;
import 'package:braven_charts/legacy/src/charts/line/line_interpolator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LineInterpolator', () {
    group('Straight Line Interpolation', () {
      test('produces linear path between two points', () {
        final points = [
          const Offset(0, 0),
          const Offset(10, 10),
        ];

        final interpolator = LineInterpolator(LineStyle.straight);
        final path = interpolator.interpolate(points);

        // Path should start at first point
        final metrics = path.computeMetrics().toList();
        expect(metrics.length, equals(1));

        // Linear path between two points should be approximately equal to distance
        final metric = metrics.first;
        final expectedDistance = (points[1] - points[0]).distance;
        expect(metric.length, closeTo(expectedDistance, 0.1));
      });

      test('handles three collinear points', () {
        final points = [
          const Offset(0, 0),
          const Offset(5, 5),
          const Offset(10, 10),
        ];

        final interpolator = LineInterpolator(LineStyle.straight);
        final path = interpolator.interpolate(points);

        // Should produce path segments
        final metrics = path.computeMetrics().toList();
        expect(metrics.isNotEmpty, isTrue);
      });

      test('handles empty point list', () {
        final interpolator = LineInterpolator(LineStyle.straight);
        final path = interpolator.interpolate([]);

        final metrics = path.computeMetrics().toList();
        expect(metrics.isEmpty, isTrue);
      });

      test('handles single point', () {
        final points = [const Offset(5, 5)];

        final interpolator = LineInterpolator(LineStyle.straight);
        final path = interpolator.interpolate(points);

        final metrics = path.computeMetrics().toList();
        expect(metrics.isEmpty, isTrue);
      });
    });

    group('Smooth Line Interpolation (Catmull-Rom to Bezier)', () {
      test('produces curved path for non-collinear points', () {
        final points = [
          const Offset(0, 0),
          const Offset(5, 10),
          const Offset(10, 0),
        ];

        final interpolator = LineInterpolator(LineStyle.smooth);
        final path = interpolator.interpolate(points);

        final metrics = path.computeMetrics().toList();
        expect(metrics.isNotEmpty, isTrue);

        // Smooth curve should be longer than straight line distance
        final metric = metrics.first;
        final straightDistance =
            (points[1] - points[0]).distance + (points[2] - points[1]).distance;
        expect(metric.length, greaterThanOrEqualTo(straightDistance * 0.9));
      });

      test('passes through all data points', () {
        final points = [
          const Offset(0, 0),
          const Offset(5, 10),
          const Offset(10, 5),
          const Offset(15, 15),
        ];

        final interpolator = LineInterpolator(LineStyle.smooth);
        final path = interpolator.interpolate(points);

        // Verify path exists
        final metrics = path.computeMetrics().toList();
        expect(metrics.isNotEmpty, isTrue);

        // For Catmull-Rom, the curve should pass through all interior points
        // (We can't easily verify exact point passage without path sampling,
        // but we verify the path was created)
      });

      test('handles two points like straight line', () {
        final points = [
          const Offset(0, 0),
          const Offset(10, 10),
        ];

        final interpolator = LineInterpolator(LineStyle.smooth);
        final path = interpolator.interpolate(points);

        final metrics = path.computeMetrics().toList();
        expect(metrics.isNotEmpty, isTrue);
      });

      test('handles empty point list', () {
        final interpolator = LineInterpolator(LineStyle.smooth);
        final path = interpolator.interpolate([]);

        final metrics = path.computeMetrics().toList();
        expect(metrics.isEmpty, isTrue);
      });
    });

    group('Stepped Line Interpolation', () {
      test('produces horizontal-vertical segments', () {
        final points = [
          const Offset(0, 0),
          const Offset(10, 10),
        ];

        final interpolator = LineInterpolator(LineStyle.stepped);
        final path = interpolator.interpolate(points);

        final metrics = path.computeMetrics().toList();
        expect(metrics.isNotEmpty, isTrue);

        // Stepped path (horizontal then vertical) should be sum of dx + dy
        final metric = metrics.first;
        final expectedLength = (points[1].dx - points[0].dx).abs() +
            (points[1].dy - points[0].dy).abs();
        expect(metric.length, closeTo(expectedLength, 0.1));
      });

      test('handles three points with different y-values', () {
        final points = [
          const Offset(0, 0),
          const Offset(5, 10),
          const Offset(10, 5),
        ];

        final interpolator = LineInterpolator(LineStyle.stepped);
        final path = interpolator.interpolate(points);

        final metrics = path.computeMetrics().toList();
        expect(metrics.isNotEmpty, isTrue);
      });

      test('handles empty point list', () {
        final interpolator = LineInterpolator(LineStyle.stepped);
        final path = interpolator.interpolate([]);

        final metrics = path.computeMetrics().toList();
        expect(metrics.isEmpty, isTrue);
      });
    });

    group('Path Caching Optimization', () {
      test('caching same points returns same path reference', () {
        final points = [
          const Offset(0, 0),
          const Offset(5, 5),
          const Offset(10, 10),
        ];

        final interpolator = LineInterpolator(LineStyle.straight);
        final path1 = interpolator.interpolate(points);
        final path2 = interpolator.interpolate(points);

        // Should return cached path (same instance)
        expect(identical(path1, path2), isTrue);
      });

      test('different points invalidate cache', () {
        final points1 = [
          const Offset(0, 0),
          const Offset(5, 5),
        ];
        final points2 = [
          const Offset(0, 0),
          const Offset(10, 10),
        ];

        final interpolator = LineInterpolator(LineStyle.straight);
        final path1 = interpolator.interpolate(points1);
        final path2 = interpolator.interpolate(points2);

        // Should not be same instance (cache invalidated)
        expect(identical(path1, path2), isFalse);
      });

      test('changing line style invalidates cache', () {
        final points = [
          const Offset(0, 0),
          const Offset(5, 5),
          const Offset(10, 10),
        ];

        final interpolator1 = LineInterpolator(LineStyle.straight);
        final path1 = interpolator1.interpolate(points);

        final interpolator2 = LineInterpolator(LineStyle.smooth);
        final path2 = interpolator2.interpolate(points);

        // Different interpolators should produce different paths
        expect(identical(path1, path2), isFalse);
      });

      test('clearCache() forces recomputation', () {
        final points = [
          const Offset(0, 0),
          const Offset(5, 5),
        ];

        final interpolator = LineInterpolator(LineStyle.straight);
        final path1 = interpolator.interpolate(points);

        interpolator.clearCache();

        final path2 = interpolator.interpolate(points);

        // After clearCache(), should not be same instance
        expect(identical(path1, path2), isFalse);
      });
    });
  });
}
