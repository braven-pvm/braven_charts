import 'dart:ui';

import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/utils/interpolation_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InterpolationGeometry', () {
    test(
      'bezier interpolation solves cubic x instead of assuming linear t',
      () {
        final points = const [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(x: 1, y: 1),
          ChartDataPoint(x: 4, y: 9),
          ChartDataPoint(x: 6, y: 2),
        ];

        final segment = InterpolationGeometry.cubicSegmentFor<ChartDataPoint>(
          points: points,
          startIndex: 1,
          interpolation: LineInterpolation.bezier,
          getX: (point) => point.x,
          getY: (point) => point.y,
          tension: 0.25,
        );

        expect(segment, isNotNull);
        final resolvedT = segment!.solveTForX(2.0);
        final linearT = (2.0 - points[1].x) / (points[2].x - points[1].x);

        expect(resolvedT, isNot(closeTo(linearT, 0.01)));
        expect(segment.evaluateX(resolvedT), closeTo(2.0, 1e-6));
      },
    );

    test('bezier close-point clusters remain x-monotonic at every tension', () {
      final points = const [
        ChartDataPoint(x: 14, y: 48),
        ChartDataPoint(x: 19, y: 55),
        ChartDataPoint(x: 24, y: 62),
        ChartDataPoint(x: 28.5, y: 82),
        ChartDataPoint(x: 32.8, y: 94),
        ChartDataPoint(x: 35.9, y: 116),
        ChartDataPoint(x: 36, y: 138),
        ChartDataPoint(x: 36.08, y: 136),
        ChartDataPoint(x: 57.5, y: 113),
      ];

      for (final tension in const [0.0, 0.1, 0.25, 0.7, 1.0]) {
        for (var startIndex = 0; startIndex < points.length - 1; startIndex++) {
          final segment = InterpolationGeometry.cubicSegmentFor<ChartDataPoint>(
            points: points,
            startIndex: startIndex,
            interpolation: LineInterpolation.bezier,
            getX: (point) => point.x,
            getY: (point) => point.y,
            tension: tension,
          );

          expect(segment, isNotNull);
          final cubic = segment!;
          expect(cubic.control1X, inInclusiveRange(cubic.startX, cubic.endX));
          expect(cubic.control2X, inInclusiveRange(cubic.startX, cubic.endX));
          expect(cubic.control1X, lessThanOrEqualTo(cubic.control2X));

          var previousX = cubic.startX;
          for (var step = 1; step <= 100; step++) {
            final x = cubic.evaluateX(step / 100);
            expect(
              x,
              greaterThanOrEqualTo(previousX - 1e-10),
              reason:
                  'segment $startIndex reversed X at tension $tension and step $step',
            );
            previousX = x;
          }
        }
      }
    });

    test('monotone interpolation stays within the segment y-range', () {
      final points = const [
        ChartDataPoint(x: 0, y: 0),
        ChartDataPoint(x: 1, y: 2),
        ChartDataPoint(x: 2, y: 3),
        ChartDataPoint(x: 3, y: 5),
      ];

      final y = InterpolationGeometry.interpolateYForX<ChartDataPoint>(
        points: points,
        startIndex: 1,
        targetX: 1.5,
        interpolation: LineInterpolation.monotone,
        getX: (point) => point.x,
        getY: (point) => point.y,
      );

      expect(y, greaterThanOrEqualTo(points[1].y));
      expect(y, lessThanOrEqualTo(points[2].y));
    });

    test('path building emits cubic segments for monotone interpolation', () {
      final path = Path()..moveTo(0, 0);
      final points = const [
        Offset(0, 0),
        Offset(10, 8),
        Offset(20, 10),
        Offset(30, 16),
      ];

      InterpolationGeometry.addPathSegments<Offset>(
        path: path,
        points: points,
        interpolation: LineInterpolation.monotone,
        getX: (point) => point.dx,
        getY: (point) => point.dy,
      );

      expect(path.computeMetrics().single.length, greaterThan(0));
    });
  });
}
