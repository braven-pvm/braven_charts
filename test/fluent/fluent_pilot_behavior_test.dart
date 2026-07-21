/// Behavior tests for the generated fluent extensions on the three pilot
/// classes, imported ONLY through the opt-in barrel
/// `package:braven_charts/braven_charts_fluent.dart` (resolving here is
/// itself part of the contract).
///
/// Covered per the plan's Task 3 Step 3:
/// - fluent result equality against the equivalent `copyWith` call;
/// - tri-state three-verb round-trip (value / none / inherit);
/// - a chain of modifiers equals one combined `copyWith`;
/// - chains never mutate the receiver.
library;

import 'package:braven_charts/braven_charts_fluent.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CrosshairConfig fluent modifiers', () {
    test('withMode equals the copyWith equivalent', () {
      expect(
        const CrosshairConfig().withMode(CrosshairMode.vertical),
        const CrosshairConfig(mode: CrosshairMode.vertical),
      );
    });

    test('withSnapRadius equals the copyWith equivalent', () {
      const base = CrosshairConfig();
      expect(base.withSnapRadius(32), base.copyWith(snapRadius: 32));
    });

    test('withCoordinateLabelStyle sets a real payload', () {
      const style = TextStyle(fontSize: 11);
      expect(
        const CrosshairConfig().withCoordinateLabelStyle(style),
        const CrosshairConfig(coordinateLabelStyle: style),
      );
    });

    test('chain of modifiers equals one combined copyWith', () {
      const base = CrosshairConfig();
      expect(
        base
            .withMode(CrosshairMode.horizontal)
            .withSnapToDataPoint(false)
            .withTrackingModeThreshold(500),
        base.copyWith(
          mode: CrosshairMode.horizontal,
          snapToDataPoint: false,
          trackingModeThreshold: 500,
        ),
      );
    });

    test('chains do not mutate the receiver', () {
      const base = CrosshairConfig();
      final modified = base.withEnabled(false).withSnapRadius(1);
      expect(base, const CrosshairConfig());
      expect(modified, isNot(equals(base)));
    });
  });

  group('CartesianValueSummaryStyle tri-state verbs', () {
    const accent = Color(0xFF3366CC);

    test('withBackgroundColor resolves to the explicit value', () {
      final style = const CartesianValueSummaryStyle()
          .withBackgroundColor(accent);
      expect(
        style.backgroundColor,
        const ChartStyleValue<Color>.value(accent),
      );
      expect(style.backgroundColor.resolve(const Color(0xFF000000)), accent);
    });

    test('clearBackgroundColor resolves to none', () {
      final style = const CartesianValueSummaryStyle()
          .withBackgroundColor(accent)
          .clearBackgroundColor();
      expect(style.backgroundColor.isNone, isTrue);
      expect(style.backgroundColor.resolve(const Color(0xFF000000)), isNull);
    });

    test('inheritBackgroundColor restores theme inheritance', () {
      final style = const CartesianValueSummaryStyle()
          .withBackgroundColor(accent)
          .clearBackgroundColor()
          .inheritBackgroundColor();
      expect(style.backgroundColor.isInherit, isTrue);
      // The full three-verb round-trip lands back on the default style.
      expect(style, const CartesianValueSummaryStyle());
    });

    test('verbs equal their copyWith equivalents', () {
      const base = CartesianValueSummaryStyle();
      expect(
        base.withRowGap(8),
        base.copyWith(rowGap: const ChartStyleValue<double>.value(8)),
      );
      expect(
        base.clearShadow(),
        base.copyWith(shadow: const ChartStyleValue<BoxShadow>.none()),
      );
      expect(
        base.inheritPadding(),
        base.copyWith(padding: const ChartStyleValue<EdgeInsets>.inherit()),
      );
    });

    test('chains do not mutate the receiver', () {
      const base = CartesianValueSummaryStyle();
      final modified = base.withBorderWidth(2).clearBorderColor();
      expect(base, const CartesianValueSummaryStyle());
      expect(modified, isNot(equals(base)));
    });
  });

  group('LineChartSeries fluent modifiers', () {
    const points = [ChartDataPoint(x: 0, y: 1), ChartDataPoint(x: 1, y: 3)];
    const base = LineChartSeries(id: 'power', points: points);

    test('withStrokeWidth equals the copyWith equivalent', () {
      expect(base.withStrokeWidth(4), base.copyWith(strokeWidth: 4));
    });

    test('chain of three modifiers equals one combined copyWith', () {
      expect(
        base
            .withStrokeWidth(4)
            .withInterpolation(LineInterpolation.monotone)
            .withDashPattern(const [2, 6]),
        base.copyWith(
          strokeWidth: 4,
          interpolation: LineInterpolation.monotone,
          dashPattern: const [2, 6],
        ),
      );
    });

    test('modifiers preserve unrelated state', () {
      final modified = base.withColor(const Color(0xFFAA0000)).withUnit('W');
      expect(modified.id, 'power');
      expect(modified.points, points);
      expect(modified.color, const Color(0xFFAA0000));
      expect(modified.unit, 'W');
    });

    test('chains do not mutate the receiver', () {
      final modified = base.withLineGlow(1.5).withShowDataPointMarkers(true);
      expect(base, const LineChartSeries(id: 'power', points: points));
      expect(modified, isNot(equals(base)));
      expect(identical(base, modified), isFalse);
    });
  });
}
