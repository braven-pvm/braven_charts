import 'dart:math' as math;

import 'package:braven_charts/src/axis/polar_category_scale.dart';
import 'package:braven_charts/src/axis/polar_numeric_scale.dart';
import 'package:braven_charts/src/coordinates/polar_transform.dart';
import 'package:braven_charts/src/layout/radial_pane_geometry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PolarTransform', () {
    test('maps normalized pane coordinates into plot space', () {
      final transform = PolarTransform(
        RadialPaneGeometry.resolve(
          viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
          innerRadiusFactor: 0.2,
          outerRadiusFactor: 0.8,
          startAngle: -math.pi / 2,
          sweepAngle: math.pi,
        ),
      );

      expect(
        transform.normalizedToPlot(angularFraction: 0, radialFraction: 0),
        const Offset(100, 80),
      );
      expect(
        transform.normalizedToPlot(angularFraction: 0.5, radialFraction: 0.5),
        const Offset(150, 100),
      );
      expect(
        transform.normalizedToPlot(angularFraction: 1, radialFraction: 1),
        const Offset(100, 180),
      );
    });

    test('honors counter-clockwise panes', () {
      final transform = PolarTransform(
        RadialPaneGeometry.resolve(
          viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
          outerRadiusFactor: 0.8,
          startAngle: 0,
          sweepAngle: math.pi / 2,
          clockwise: false,
        ),
      );

      expect(
        transform.normalizedToPlot(angularFraction: 1, radialFraction: 1),
        const Offset(100, 20),
      );
    });

    test('round-trips raw polar coordinates with normalized angles', () {
      final transform = PolarTransform(
        RadialPaneGeometry.resolve(
          viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
        ),
      );
      final point = transform.toPlot(angle: math.pi * 1.75, radius: 50);
      final polar = transform.fromPlot(point);

      expect(polar.angle, closeTo(math.pi * 1.75, 1e-12));
      expect(polar.radius, closeTo(50, 1e-12));
    });

    test('converts plot hits into pane fractions and rejects misses', () {
      final transform = PolarTransform(
        RadialPaneGeometry.resolve(
          viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
          innerRadiusFactor: 0.2,
          outerRadiusFactor: 0.8,
          startAngle: 0,
          sweepAngle: math.pi / 2,
        ),
      );
      final hitPoint = transform.normalizedToPlot(
        angularFraction: 0.25,
        radialFraction: 0.75,
      );

      final hit = transform.plotToPane(hitPoint);
      expect(hit, isNotNull);
      expect(hit!.angularFraction, closeTo(0.25, 1e-12));
      expect(hit.radialFraction, closeTo(0.75, 1e-12));
      expect(hit.angle, closeTo(math.pi / 8, 1e-12));
      expect(hit.radius, closeTo(65, 1e-12));
      expect(transform.contains(hitPoint), isTrue);

      expect(
        transform.plotToPane(
          const Offset(100, 100) + Offset.fromDirection(-math.pi / 4, 50),
        ),
        isNull,
      );
      expect(transform.plotToPane(const Offset(110, 100)), isNull);
      expect(transform.plotToPane(const Offset(190, 100)), isNull);
    });

    test('round-trips full-sweep fractions across the angle seam', () {
      final transform = PolarTransform(
        RadialPaneGeometry.resolve(
          viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
          startAngle: -math.pi / 2,
          sweepAngle: math.pi * 2,
          clockwise: false,
        ),
      );
      final point = transform.normalizedToPlot(
        angularFraction: 0.875,
        radialFraction: 0.6,
      );
      final hit = transform.plotToPane(point);

      expect(hit, isNotNull);
      expect(hit!.angularFraction, closeTo(0.875, 1e-12));
      expect(hit.radialFraction, closeTo(0.6, 1e-12));
    });

    test('composes category and numeric scales for inverse hit conversion', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 240, 240),
        innerRadiusFactor: 0.2,
        outerRadiusFactor: 0.9,
        startAngle: -math.pi / 2,
        sweepAngle: math.pi * 1.5,
      );
      final categories = PolarCategoryScale(
        pane: pane,
        categories: const ['A', 'B', 'C'],
        innerPadding: 0.1,
      );
      final values = PolarNumericScale(
        pane: pane,
        minimum: 0,
        maximum: 100,
        mode: PolarNumericScaleMode.areaCorrect,
      );
      final transform = PolarTransform(pane);
      final point = transform.toPlot(
        angle: categories.bandForCategory('B')!.centerAngle,
        radius: values.valueToRadius(36),
      );
      final polar = transform.fromPlot(point);

      expect(categories.categoryForAngle(polar.angle), 'B');
      expect(values.radiusToValue(polar.radius), closeTo(36, 1e-10));
    });

    test('rejects non-finite coordinates and out-of-range fractions', () {
      final transform = PolarTransform(
        RadialPaneGeometry.resolve(
          viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
        ),
      );

      expect(
        () => transform.toPlot(angle: double.nan, radius: 20),
        throwsArgumentError,
      );
      expect(() => transform.toPlot(angle: 0, radius: -1), throwsArgumentError);
      expect(
        () => transform.normalizedToPlot(
          angularFraction: 1.1,
          radialFraction: 0.5,
        ),
        throwsArgumentError,
      );
      expect(
        () => transform.normalizedToPlot(
          angularFraction: 0.5,
          radialFraction: double.infinity,
        ),
        throwsArgumentError,
      );
      expect(
        () => transform.fromPlot(const Offset(double.nan, 0)),
        throwsArgumentError,
      );
    });
  });
}
