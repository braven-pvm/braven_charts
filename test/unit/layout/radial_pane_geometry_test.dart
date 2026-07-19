import 'dart:math' as math;

import 'package:braven_charts/src/layout/radial_pane_geometry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadialPaneGeometry', () {
    test('resolves a centered pane after viewport and label insets', () {
      final geometry = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 400, 300),
        viewportInsets: const EdgeInsets.all(10),
        reservedLabelInsets: const EdgeInsets.fromLTRB(20, 30, 40, 10),
        innerRadiusFactor: 0.25,
        outerRadiusFactor: 0.8,
        startAngle: -math.pi / 2,
        sweepAngle: math.pi * 1.5,
        clockwise: false,
      );

      expect(geometry.availableBounds, const Rect.fromLTRB(30, 40, 350, 280));
      expect(geometry.center, const Offset(190, 160));
      expect(geometry.availableOuterRadius, 120);
      expect(geometry.plotBounds, const Rect.fromLTWH(70, 40, 240, 240));
      expect(geometry.innerRadius, 30);
      expect(geometry.outerRadius, 96);
      expect(geometry.markBounds, const Rect.fromLTWH(94, 64, 192, 192));
      expect(geometry.endAngle, closeTo(-math.pi * 2, 1e-12));
    });

    test('maps angular fractions through the configured direction', () {
      final clockwise = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
        startAngle: -math.pi / 2,
        sweepAngle: math.pi,
      );
      final counterClockwise = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
        startAngle: -math.pi / 2,
        sweepAngle: math.pi,
        clockwise: false,
      );

      expect(clockwise.signedSweepAngle, math.pi);
      expect(clockwise.angleAt(0.5), closeTo(0, 1e-12));
      expect(counterClockwise.signedSweepAngle, -math.pi);
      expect(counterClockwise.angleAt(0.5), closeTo(-math.pi, 1e-12));
    });

    test('rejects invalid bounds, insets, radii, and angular ranges', () {
      RadialPaneGeometry build({
        Rect viewportBounds = const Rect.fromLTWH(0, 0, 200, 160),
        EdgeInsets viewportInsets = EdgeInsets.zero,
        EdgeInsets reservedLabelInsets = EdgeInsets.zero,
        double innerRadiusFactor = 0,
        double outerRadiusFactor = 1,
        double startAngle = 0,
        double sweepAngle = math.pi * 2,
      }) => RadialPaneGeometry.resolve(
        viewportBounds: viewportBounds,
        viewportInsets: viewportInsets,
        reservedLabelInsets: reservedLabelInsets,
        innerRadiusFactor: innerRadiusFactor,
        outerRadiusFactor: outerRadiusFactor,
        startAngle: startAngle,
        sweepAngle: sweepAngle,
      );

      expect(
        () => build(viewportBounds: const Rect.fromLTWH(0, 0, 0, 100)),
        throwsArgumentError,
      );
      expect(
        () => build(
          viewportBounds: const Rect.fromLTWH(0, 0, double.infinity, 100),
        ),
        throwsArgumentError,
      );
      expect(
        () => build(viewportInsets: const EdgeInsets.only(left: -1)),
        throwsArgumentError,
      );
      expect(
        () =>
            build(viewportInsets: const EdgeInsets.symmetric(horizontal: 101)),
        throwsArgumentError,
      );
      expect(() => build(innerRadiusFactor: -0.1), throwsArgumentError);
      expect(
        () => build(innerRadiusFactor: 0.8, outerRadiusFactor: 0.8),
        throwsArgumentError,
      );
      expect(() => build(outerRadiusFactor: 1.1), throwsArgumentError);
      expect(() => build(startAngle: double.nan), throwsArgumentError);
      expect(() => build(sweepAngle: 0), throwsArgumentError);
      expect(() => build(sweepAngle: math.pi * 2 + 0.001), throwsArgumentError);
    });
  });
}
