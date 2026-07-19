import 'dart:math' as math;

import 'package:braven_charts/src/axis/polar_numeric_scale.dart';
import 'package:braven_charts/src/layout/radial_pane_geometry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PolarNumericScale', () {
    late RadialPaneGeometry pane;

    setUp(() {
      pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
        innerRadiusFactor: 0.2,
        outerRadiusFactor: 0.8,
      );
    });

    test('maps a linear domain directly across the pane radii', () {
      final scale = PolarNumericScale(pane: pane, minimum: 0, maximum: 100);

      expect(scale.valueToRadius(0), 20);
      expect(scale.valueToRadius(50), 50);
      expect(scale.valueToRadius(100), 80);
      expect(scale.radiusToValue(20), 0);
      expect(scale.radiusToValue(50), 50);
      expect(scale.radiusToValue(80), 100);
    });

    test('area-correct mode maps values to sector area, not linear radius', () {
      final solidPane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
      );
      final scale = PolarNumericScale(
        pane: solidPane,
        minimum: 0,
        maximum: 100,
        mode: PolarNumericScaleMode.areaCorrect,
      );

      expect(scale.valueToRadius(25), closeTo(50, 1e-12));
      expect(scale.valueToRadius(50), closeTo(math.sqrt(5000), 1e-12));
      expect(scale.radiusToValue(math.sqrt(5000)), closeTo(50, 1e-12));
    });

    test('area-correct mode includes a non-zero pane opening', () {
      final scale = PolarNumericScale(
        pane: pane,
        minimum: 0,
        maximum: 100,
        mode: PolarNumericScaleMode.areaCorrect,
      );
      final radius = scale.valueToRadius(50);
      final representedArea = radius * radius - 20 * 20;
      final availableArea = 80 * 80 - 20 * 20;

      expect(representedArea / availableArea, closeTo(0.5, 1e-12));
      expect(scale.radiusToValue(radius), closeTo(50, 1e-12));
    });

    test('radial fractions round-trip through either scale mode', () {
      for (final mode in PolarNumericScaleMode.values) {
        final scale = PolarNumericScale(
          pane: pane,
          minimum: 10,
          maximum: 90,
          mode: mode,
        );
        final fraction = scale.valueToRadialFraction(42);

        expect(fraction, inInclusiveRange(0, 1));
        expect(scale.radialFractionToValue(fraction), closeTo(42, 1e-10));
      }
    });

    test('clamps finite values and radii to the configured domain', () {
      final scale = PolarNumericScale(pane: pane, minimum: 20, maximum: 80);

      expect(scale.valueToRadius(0), pane.innerRadius);
      expect(scale.valueToRadius(120), pane.outerRadius);
      expect(scale.radiusToValue(0), 20);
      expect(scale.radiusToValue(120), 80);
      expect(() => scale.valueToRadius(-1), throwsArgumentError);
    });

    test('derives a zero-based domain and stabilizes empty or zero data', () {
      final derived = PolarNumericScale.fromValues(
        pane: pane,
        values: const [5, 10, 7],
      );
      final zero = PolarNumericScale.fromValues(
        pane: pane,
        values: const [0, 0],
      );
      final empty = PolarNumericScale.fromValues(pane: pane, values: const []);

      expect(derived.minimum, 0);
      expect(derived.maximum, 10);
      expect(zero.minimum, 0);
      expect(zero.maximum, 1);
      expect(empty.minimum, 0);
      expect(empty.maximum, 1);
    });

    test('rejects negative, non-finite, equal, or reversed domains', () {
      expect(
        () => PolarNumericScale(pane: pane, minimum: -1, maximum: 10),
        throwsArgumentError,
      );
      expect(
        () => PolarNumericScale(pane: pane, minimum: 10, maximum: 10),
        throwsArgumentError,
      );
      expect(
        () => PolarNumericScale(pane: pane, minimum: 10, maximum: 5),
        throwsArgumentError,
      );
      expect(
        () =>
            PolarNumericScale(pane: pane, minimum: 0, maximum: double.infinity),
        throwsArgumentError,
      );
      expect(
        () => PolarNumericScale.fromValues(pane: pane, values: const [1, -1]),
        throwsArgumentError,
      );
      expect(
        () => PolarNumericScale.fromValues(
          pane: pane,
          values: const [double.nan],
        ),
        throwsArgumentError,
      );

      final scale = PolarNumericScale(pane: pane, minimum: 0, maximum: 10);
      expect(() => scale.valueToRadius(double.nan), throwsArgumentError);
      expect(() => scale.radiusToValue(-1), throwsArgumentError);
      expect(() => scale.radialFractionToValue(1.1), throwsArgumentError);
    });
  });
}
