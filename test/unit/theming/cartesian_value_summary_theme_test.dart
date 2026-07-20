import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CartesianValueSummaryTheme', () {
    group('presets', () {
      test('light and dark differ on background and text colors', () {
        const light = CartesianValueSummaryTheme.light;
        const dark = CartesianValueSummaryTheme.dark;

        expect(light.background, isNot(dark.background));
        expect(light.titleStyle.color, isNot(dark.titleStyle.color));
        expect(light.valueStyle.color, isNot(dark.valueStyle.color));
        expect(light.labelStyle.color, isNot(dark.labelStyle.color));
      });

      test('high contrast strengthens border and removes transparency', () {
        const light = CartesianValueSummaryTheme.light;
        const highContrast = CartesianValueSummaryTheme.highContrast;

        expect(highContrast.borderWidth, greaterThan(light.borderWidth));
        expect(highContrast.backgroundOpacity, 1.0);
        expect(highContrast.titleStyle.fontWeight, FontWeight.bold);
        expect(highContrast.valueStyle.fontWeight, FontWeight.bold);
        expect(highContrast.shadow, isNull);
      });

      test('color-blind-safe preset uses a distinct accessible border', () {
        expect(
          CartesianValueSummaryTheme.colorBlindSafe.border,
          isNot(CartesianValueSummaryTheme.light.border),
        );
      });

      test('all presets are pairwise distinct', () {
        const presets = [
          CartesianValueSummaryTheme.light,
          CartesianValueSummaryTheme.dark,
          CartesianValueSummaryTheme.highContrast,
          CartesianValueSummaryTheme.colorBlindSafe,
        ];

        for (var i = 0; i < presets.length; i++) {
          for (var j = i + 1; j < presets.length; j++) {
            expect(presets[i], isNot(presets[j]));
          }
        }
      });

      test('light preset mirrors the prototype visual density', () {
        const light = CartesianValueSummaryTheme.light;

        expect(light.minWidth, 168.0);
        expect(light.padding, const EdgeInsets.all(8));
        expect(light.labelStyle.fontSize, 11.0);
        expect(light.valueStyle.fontSize, 11.0);
        expect(light.accentSize, 8.0);
      });
    });

    group('lerp', () {
      test('returns the first theme at t = 0', () {
        expect(
          CartesianValueSummaryTheme.lerp(
            CartesianValueSummaryTheme.light,
            CartesianValueSummaryTheme.dark,
            0.0,
          ),
          CartesianValueSummaryTheme.light,
        );
      });

      test('returns the second theme at t = 1', () {
        expect(
          CartesianValueSummaryTheme.lerp(
            CartesianValueSummaryTheme.light,
            CartesianValueSummaryTheme.dark,
            1.0,
          ),
          CartesianValueSummaryTheme.dark,
        );
      });

      test('interpolates numeric fields at the midpoint', () {
        final mid = CartesianValueSummaryTheme.lerp(
          CartesianValueSummaryTheme.light,
          CartesianValueSummaryTheme.highContrast,
          0.5,
        );

        // light borderWidth 1.0 -> highContrast 2.0.
        expect(mid.borderWidth, closeTo(1.5, 1e-9));
      });

      test('fades a shadow toward a shadowless preset instead of popping', () {
        final mid = CartesianValueSummaryTheme.lerp(
          CartesianValueSummaryTheme.light,
          CartesianValueSummaryTheme.highContrast,
          0.5,
        );
        final end = CartesianValueSummaryTheme.lerp(
          CartesianValueSummaryTheme.light,
          CartesianValueSummaryTheme.highContrast,
          1.0,
        );

        expect(mid.shadow, isNotNull);
        expect(end.shadow, isNull);
      });
    });

    group('copyWith', () {
      const base = CartesianValueSummaryTheme.light;

      test('replaces each field independently', () {
        const color = Color(0xFF123456);
        const style = TextStyle(color: Color(0xFF654321), fontSize: 17);
        const shadow = BoxShadow(color: Color(0x80000000), blurRadius: 9);

        expect(base.copyWith(background: color).background, color);
        expect(base.copyWith(backgroundOpacity: 0.42).backgroundOpacity, 0.42);
        expect(base.copyWith(border: color).border, color);
        expect(base.copyWith(borderWidth: 3.5).borderWidth, 3.5);
        expect(
          base.copyWith(borderRadius: BorderRadius.circular(12)).borderRadius,
          BorderRadius.circular(12),
        );
        expect(
          base.copyWith(padding: const EdgeInsets.all(20)).padding,
          const EdgeInsets.all(20),
        );
        expect(base.copyWith(titleStyle: style).titleStyle, style);
        expect(base.copyWith(labelStyle: style).labelStyle, style);
        expect(base.copyWith(valueStyle: style).valueStyle, style);
        expect(base.copyWith(accentSize: 14.0).accentSize, 14.0);
        expect(base.copyWith(shadow: shadow).shadow, shadow);
        expect(base.copyWith(minWidth: 200.0).minWidth, 200.0);
        expect(base.copyWith(maxWidth: 400.0).maxWidth, 400.0);
        expect(base.copyWith(rowGap: 9.0).rowGap, 9.0);
      });

      test('keeps every other field when replacing one', () {
        final copy = base.copyWith(borderWidth: 7.0);

        expect(copy.background, base.background);
        expect(copy.backgroundOpacity, base.backgroundOpacity);
        expect(copy.border, base.border);
        expect(copy.borderRadius, base.borderRadius);
        expect(copy.padding, base.padding);
        expect(copy.titleStyle, base.titleStyle);
        expect(copy.labelStyle, base.labelStyle);
        expect(copy.valueStyle, base.valueStyle);
        expect(copy.accentSize, base.accentSize);
        expect(copy.shadow, base.shadow);
        expect(copy.minWidth, base.minWidth);
        expect(copy.maxWidth, base.maxWidth);
        expect(copy.rowGap, base.rowGap);
      });

      test('with no arguments returns an equal theme', () {
        expect(base.copyWith(), base);
        expect(base.copyWith().hashCode, base.hashCode);
      });
    });

    group('equality', () {
      test('equal values are equal with matching hash codes', () {
        const a = CartesianValueSummaryTheme.light;
        final b = CartesianValueSummaryTheme.light.copyWith();

        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('a single changed field breaks equality', () {
        expect(
          CartesianValueSummaryTheme.light.copyWith(accentSize: 99.0),
          isNot(CartesianValueSummaryTheme.light),
        );
      });
    });
  });

  group('ChartTheme integration', () {
    test('light preset carries the light summary theme', () {
      expect(
        ChartTheme.light.cartesianValueSummaryTheme,
        CartesianValueSummaryTheme.light,
      );
    });

    test('dark preset carries the dark summary theme', () {
      expect(
        ChartTheme.dark.cartesianValueSummaryTheme,
        CartesianValueSummaryTheme.dark,
      );
    });

    test('high contrast preset carries the high contrast summary theme', () {
      expect(
        ChartTheme.highContrast.cartesianValueSummaryTheme,
        CartesianValueSummaryTheme.highContrast,
      );
    });

    test('colorblind friendly preset carries the color-blind-safe theme', () {
      expect(
        ChartTheme.colorblindFriendly.cartesianValueSummaryTheme,
        CartesianValueSummaryTheme.colorBlindSafe,
      );
    });

    test('light-surface presets default to the light summary theme', () {
      for (final theme in [
        ChartTheme.corporateBlue,
        ChartTheme.vibrant,
        ChartTheme.minimal,
      ]) {
        expect(
          theme.cartesianValueSummaryTheme,
          CartesianValueSummaryTheme.light,
        );
      }
    });

    test('copyWith overrides and preserves the summary theme', () {
      final custom = CartesianValueSummaryTheme.light.copyWith(minWidth: 220.0);

      final overridden = ChartTheme.light.copyWith(
        cartesianValueSummaryTheme: custom,
      );
      expect(overridden.cartesianValueSummaryTheme, custom);

      final untouched = ChartTheme.dark.copyWith(backgroundColor: Colors.red);
      expect(
        untouched.cartesianValueSummaryTheme,
        CartesianValueSummaryTheme.dark,
      );
    });

    test('equality is sensitive to the summary theme', () {
      final changed = ChartTheme.light.copyWith(
        cartesianValueSummaryTheme: CartesianValueSummaryTheme.dark,
      );

      expect(changed, isNot(ChartTheme.light));
    });

    group('lerp', () {
      test('endpoints resolve to each theme component', () {
        expect(
          ChartTheme.lerp(ChartTheme.light, ChartTheme.dark, 0.0)
              .cartesianValueSummaryTheme,
          CartesianValueSummaryTheme.light,
        );
        expect(
          ChartTheme.lerp(ChartTheme.light, ChartTheme.dark, 1.0)
              .cartesianValueSummaryTheme,
          CartesianValueSummaryTheme.dark,
        );
      });

      test('midpoint interpolates the summary component continuously', () {
        final mid = ChartTheme.lerp(
          ChartTheme.light,
          ChartTheme.highContrast,
          0.5,
        );

        // light borderWidth 1.0 -> highContrast 2.0.
        expect(
          mid.cartesianValueSummaryTheme.borderWidth,
          closeTo(1.5, 1e-9),
        );
      });
    });
  });
}
