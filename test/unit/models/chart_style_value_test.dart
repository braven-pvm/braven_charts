import 'dart:ui' show Color;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

/// Compiles only while the [ChartStyleValue] hierarchy stays sealed and the
/// switch below remains exhaustive without a wildcard case.
String _describe(ChartStyleValue<double> value) => switch (value) {
  ChartStyleInherit<double>() => 'inherit',
  ChartStyleExplicit<double>() => 'value',
  ChartStyleNone<double>() => 'none',
};

void main() {
  group('ChartStyleValue', () {
    group('resolve', () {
      test('inherit resolves to the theme default when one is present', () {
        const style = ChartStyleValue<double>.inherit();

        expect(style.resolve(4), 4);
      });

      test('inherit resolves to null when the theme default is null', () {
        const style = ChartStyleValue<double>.inherit();

        expect(style.resolve(null), isNull);
      });

      test('value resolves to the explicit value over a theme default', () {
        const style = ChartStyleValue<double>.value(2.5);

        expect(style.resolve(4), 2.5);
      });

      test('value resolves to the explicit value without a theme default', () {
        const style = ChartStyleValue<double>.value(2.5);

        expect(style.resolve(null), 2.5);
      });

      test('none resolves to null even when a theme default is present', () {
        const style = ChartStyleValue<Color>.none();

        expect(style.resolve(const Color(0xFF112233)), isNull);
      });

      test('none resolves to null without a theme default', () {
        const style = ChartStyleValue<Color>.none();

        expect(style.resolve(null), isNull);
      });
    });

    group('variant flags', () {
      test('inherit reports isInherit and not isNone', () {
        const style = ChartStyleValue<Color>.inherit();

        expect(style.isInherit, isTrue);
        expect(style.isNone, isFalse);
      });

      test('value reports neither isInherit nor isNone', () {
        const style = ChartStyleValue<Color>.value(Color(0xFF112233));

        expect(style.isInherit, isFalse);
        expect(style.isNone, isFalse);
      });

      test('none reports isNone and not isInherit', () {
        const style = ChartStyleValue<Color>.none();

        expect(style.isInherit, isFalse);
        expect(style.isNone, isTrue);
      });
    });

    group('equality', () {
      test('const none instances are equal', () {
        expect(
          const ChartStyleValue<Color>.none(),
          const ChartStyleValue<Color>.none(),
        );
        expect(
          const ChartStyleValue<Color>.none().hashCode,
          const ChartStyleValue<Color>.none().hashCode,
        );
      });

      test('const inherit instances are equal', () {
        expect(
          const ChartStyleValue<Color>.inherit(),
          const ChartStyleValue<Color>.inherit(),
        );
        expect(
          const ChartStyleValue<Color>.inherit().hashCode,
          const ChartStyleValue<Color>.inherit().hashCode,
        );
      });

      test('non-const instances use value equality, not identity', () {
        // ignore: prefer_const_constructors
        final left = ChartStyleValue<Color>.none();
        // ignore: prefer_const_constructors
        final right = ChartStyleValue<Color>.none();

        expect(identical(left, right), isFalse);
        expect(left, right);
        expect(left.hashCode, right.hashCode);
      });

      test('explicit values are equal when the payload is equal', () {
        expect(
          const ChartStyleValue<Color>.value(Color(0xFF112233)),
          const ChartStyleValue<Color>.value(Color(0xFF112233)),
        );
        expect(
          const ChartStyleValue<Color>.value(Color(0xFF112233)).hashCode,
          const ChartStyleValue<Color>.value(Color(0xFF112233)).hashCode,
        );
        // ignore: prefer_const_constructors
        final left = ChartStyleValue<double>.value(12);
        // ignore: prefer_const_constructors
        final right = ChartStyleValue<double>.value(12);
        expect(identical(left, right), isFalse);
        expect(left, right);
      });

      test('explicit values differ when the payload differs', () {
        expect(
          const ChartStyleValue<Color>.value(Color(0xFF112233)),
          isNot(const ChartStyleValue<Color>.value(Color(0xFF445566))),
        );
      });

      test('the three variants are mutually unequal', () {
        const inherit = ChartStyleValue<double>.inherit();
        const explicit = ChartStyleValue<double>.value(1);
        const none = ChartStyleValue<double>.none();

        expect(inherit, isNot(explicit));
        expect(inherit, isNot(none));
        expect(explicit, isNot(none));
      });
    });

    test('switch over the sealed hierarchy is exhaustive', () {
      expect(_describe(const ChartStyleValue<double>.inherit()), 'inherit');
      expect(_describe(const ChartStyleValue<double>.value(3)), 'value');
      expect(_describe(const ChartStyleValue<double>.none()), 'none');
    });
  });
}
