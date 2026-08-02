import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const blue = Color(0xFF0000FF);
  const white = Color(0xFFFFFFFF);
  const red = Color(0xFFFF0000);
  const missing = Color(0xFFCCCCCC);

  group('HeatmapColorScale sequential', () {
    test('maps endpoints and intermediate values deterministically', () {
      final scale = HeatmapColorScale.sequential(colors: const [blue, white]);

      expect(
        scale.colorFor(0, resolvedMinimumValue: 0, resolvedMaximumValue: 100),
        blue,
      );
      expect(
        scale.colorFor(100, resolvedMinimumValue: 0, resolvedMaximumValue: 100),
        white,
      );
      expect(
        scale.colorFor(50, resolvedMinimumValue: 0, resolvedMaximumValue: 100),
        Color.lerp(blue, white, 0.5),
      );
    });

    test('supports fixed domain, reversal, clamping, and missing color', () {
      final scale = HeatmapColorScale.sequential(
        colors: const [blue, red],
        minimumValue: 10,
        maximumValue: 20,
        reverse: true,
        missingColor: missing,
      );

      expect(
        scale.colorFor(10, resolvedMinimumValue: 0, resolvedMaximumValue: 1),
        red,
      );
      expect(
        scale.colorFor(30, resolvedMinimumValue: 0, resolvedMaximumValue: 1),
        blue,
      );
      expect(
        scale.colorFor(
          null,
          resolvedMinimumValue: 0,
          resolvedMaximumValue: 1,
          isMissing: true,
        ),
        missing,
      );
    });

    test('can reject measured values outside an unclamped domain', () {
      final scale = HeatmapColorScale.sequential(
        colors: const [blue, red],
        minimumValue: 0,
        maximumValue: 10,
        clamp: false,
      );

      expect(
        scale.colorFor(11, resolvedMinimumValue: 0, resolvedMaximumValue: 10),
        isNull,
      );
    });
  });

  group('HeatmapColorScale diverging', () {
    test('uses an explicit semantic midpoint', () {
      final scale = HeatmapColorScale.diverging(
        lowColor: blue,
        midpointColor: white,
        highColor: red,
        minimumValue: -20,
        midpoint: 5,
        maximumValue: 30,
      );

      expect(
        scale.colorFor(-20, resolvedMinimumValue: 0, resolvedMaximumValue: 1),
        blue,
      );
      expect(
        scale.colorFor(5, resolvedMinimumValue: 0, resolvedMaximumValue: 1),
        white,
      );
      expect(
        scale.colorFor(30, resolvedMinimumValue: 0, resolvedMaximumValue: 1),
        red,
      );
      expect(
        scale.colorFor(-7.5, resolvedMinimumValue: 0, resolvedMaximumValue: 1),
        Color.lerp(blue, white, 0.5),
      );
    });
  });

  group('HeatmapColorScale threshold', () {
    test('places values equal to a threshold in the higher band', () {
      final scale = HeatmapColorScale.threshold(
        thresholds: const [10, 20],
        colors: const [blue, white, red],
        bandLabels: const ['Low', 'Medium', 'High'],
      );

      expect(
        scale.colorFor(9.9, resolvedMinimumValue: 0, resolvedMaximumValue: 30),
        blue,
      );
      expect(
        scale.colorFor(10, resolvedMinimumValue: 0, resolvedMaximumValue: 30),
        white,
      );
      expect(
        scale.colorFor(20, resolvedMinimumValue: 0, resolvedMaximumValue: 30),
        red,
      );
      expect(scale.bandLabelFor(20), 'High');
    });

    test('reverses colors without changing value-band semantics', () {
      final scale = HeatmapColorScale.threshold(
        thresholds: const [10],
        colors: const [blue, red],
        bandLabels: const ['Low', 'High'],
        reverse: true,
      );

      expect(
        scale.colorFor(5, resolvedMinimumValue: 0, resolvedMaximumValue: 20),
        red,
      );
      expect(scale.bandLabelFor(5), 'Low');
      expect(() => scale.colors.add(white), throwsUnsupportedError);
      expect(() => scale.thresholds.add(30), throwsUnsupportedError);
    });
  });

  group('HeatmapColorScale validation', () {
    test('rejects incomplete or non-finite domains and ramps', () {
      expect(
        () => HeatmapColorScale.sequential(colors: const [blue]),
        throwsArgumentError,
      );
      expect(
        () => HeatmapColorScale.sequential(
          colors: const [blue, red],
          minimumValue: 4,
          maximumValue: 4,
        ),
        throwsArgumentError,
      );
      expect(
        () => HeatmapColorScale.diverging(
          lowColor: blue,
          midpointColor: white,
          highColor: red,
          minimumValue: 0,
          midpoint: 11,
          maximumValue: 10,
        ),
        throwsArgumentError,
      );
      expect(
        () => HeatmapColorScale.threshold(
          thresholds: const [10, 10],
          colors: const [blue, white, red],
        ),
        throwsArgumentError,
      );
      expect(
        () => HeatmapColorScale.threshold(
          thresholds: const [10],
          colors: const [blue, white, red],
        ),
        throwsArgumentError,
      );
    });

    test('withDomain retains continuous scale semantics', () {
      final source = HeatmapColorScale.diverging(
        lowColor: blue,
        midpointColor: white,
        highColor: red,
        midpoint: 0,
        label: 'Change',
      );

      final resolved = source.withDomain(
        minimumValue: -10,
        maximumValue: 20,
        showLegend: false,
      );

      expect(resolved.minimumValue, -10);
      expect(resolved.maximumValue, 20);
      expect(resolved.midpoint, 0);
      expect(resolved.colors, source.colors);
      expect(resolved.label, 'Change');
      expect(resolved.showLegend, isFalse);
    });
  });
}
