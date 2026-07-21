import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/utils/interpolation_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InterpolationGeometry segments', () {
    for (final interpolation in LineInterpolation.values) {
      test('$interpolation preserves existing forward path geometry', () {
        const points = [
          Offset(0, 8),
          Offset(12, 2),
          Offset(25, 11),
          Offset(40, 4),
        ];
        final existing = Path()..moveTo(points.first.dx, points.first.dy);
        InterpolationGeometry.addPathSegments(
          path: existing,
          points: points,
          interpolation: interpolation,
          getX: (point) => point.dx,
          getY: (point) => point.dy,
          tension: 0.3,
        );

        final descriptorPath = Path()..moveTo(points.first.dx, points.first.dy);
        final segments = InterpolationGeometry.segmentsFor(
          points: points,
          interpolation: interpolation,
          getX: (point) => point.dx,
          getY: (point) => point.dy,
          tension: 0.3,
        );
        for (final segment in segments) {
          segment.appendForward(descriptorPath);
        }

        final existingMetric = existing.computeMetrics().single;
        final descriptorMetric = descriptorPath.computeMetrics().single;
        expect(descriptorMetric.length, closeTo(existingMetric.length, 1e-5));
        for (final fraction in const [0.0, 0.2, 0.5, 0.8, 1.0]) {
          final existingPosition = existingMetric
              .getTangentForOffset(existingMetric.length * fraction)!
              .position;
          final descriptorPosition = descriptorMetric
              .getTangentForOffset(descriptorMetric.length * fraction)!
              .position;
          expect(descriptorPosition.dx, closeTo(existingPosition.dx, 1e-5));
          expect(descriptorPosition.dy, closeTo(existingPosition.dy, 1e-5));
        }
      });
    }

    test('reverses cubic endpoints and control points exactly', () {
      const source = CubicSegment(
        startX: 1,
        startY: 2,
        control1X: 3,
        control1Y: 4,
        control2X: 5,
        control2Y: 6,
        endX: 7,
        endY: 8,
      );

      final reversed = source.reversed();
      expect(reversed.startX, source.endX);
      expect(reversed.startY, source.endY);
      expect(reversed.control1X, source.control2X);
      expect(reversed.control1Y, source.control2Y);
      expect(reversed.control2X, source.control1X);
      expect(reversed.control2Y, source.control1Y);
      expect(reversed.endX, source.startX);
      expect(reversed.endY, source.startY);

      final roundTrip = reversed.reversed();
      expect(roundTrip.startX, source.startX);
      expect(roundTrip.control1X, source.control1X);
      expect(roundTrip.control2X, source.control2X);
      expect(roundTrip.endX, source.endX);
    });
  });
}
