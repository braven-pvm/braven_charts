import 'package:braven_charts/src/formatting/multi_axis_value_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MultiAxisValueFormatter', () {
    group('format', () {
      test('formats integer value with unit', () {
        // 250 watts should format as "250 W"
        final result = MultiAxisValueFormatter.format(value: 250.0, unit: 'W');
        expect(result, equals('250 W'));
      });

      test('formats decimal value with appropriate precision', () {
        // 123.456789 should be formatted with reasonable precision
        final result = MultiAxisValueFormatter.format(value: 123.456789);
        expect(result, equals('123.46'));
      });

      test('handles null unit gracefully', () {
        // Without unit, should just return the formatted number
        final result = MultiAxisValueFormatter.format(value: 100.0, unit: null);
        expect(result, equals('100'));
      });

      test('handles negative values', () {
        // Negative values should preserve the sign
        final result = MultiAxisValueFormatter.format(value: -50.5, unit: 'W');
        expect(result, equals('-50.5 W'));
      });

      test('respects explicit precision parameter', () {
        // When precision is explicitly specified, use it
        final result = MultiAxisValueFormatter.format(
          value: 123.456789,
          precision: 3,
        );
        expect(result, equals('123.457'));
      });

      test('cleans trailing zeros after decimal', () {
        // 10.500 should become "10.5", not "10.500"
        final result =
            MultiAxisValueFormatter.format(value: 10.5, precision: 3);
        expect(result, equals('10.5'));
      });

      test('removes decimal point when all decimals are zero', () {
        // 100.00 should become "100", not "100."
        final result =
            MultiAxisValueFormatter.format(value: 100.0, precision: 2);
        expect(result, equals('100'));
      });

      test('formats zero correctly', () {
        final result = MultiAxisValueFormatter.format(value: 0.0, unit: 'W');
        expect(result, equals('0 W'));
      });

      test('formats very small values with unit', () {
        final result =
            MultiAxisValueFormatter.format(value: 0.00123, unit: 'L');
        expect(result, equals('0.0012 L'));
      });
    });

    group('optimalPrecision', () {
      test('returns 0 for very large values (>= 1000)', () {
        expect(MultiAxisValueFormatter.optimalPrecision(1234.5), equals(0));
        expect(MultiAxisValueFormatter.optimalPrecision(1000.0), equals(0));
        expect(MultiAxisValueFormatter.optimalPrecision(9999.999), equals(0));
      });

      test('returns 2 for large values (>= 100, < 1000)', () {
        expect(MultiAxisValueFormatter.optimalPrecision(100.0), equals(2));
        expect(MultiAxisValueFormatter.optimalPrecision(500.5), equals(2));
        expect(MultiAxisValueFormatter.optimalPrecision(999.9), equals(2));
      });

      test('returns 1 for medium-large values (>= 10, < 100)', () {
        expect(MultiAxisValueFormatter.optimalPrecision(10.0), equals(1));
        expect(MultiAxisValueFormatter.optimalPrecision(50.5), equals(1));
        expect(MultiAxisValueFormatter.optimalPrecision(99.9), equals(1));
      });

      test('returns 2 for medium values (>= 1, < 10)', () {
        expect(MultiAxisValueFormatter.optimalPrecision(1.0), equals(2));
        expect(MultiAxisValueFormatter.optimalPrecision(5.5), equals(2));
        expect(MultiAxisValueFormatter.optimalPrecision(9.99), equals(2));
      });

      test('returns 3 for small values (>= 0.1, < 1)', () {
        expect(MultiAxisValueFormatter.optimalPrecision(0.1), equals(3));
        expect(MultiAxisValueFormatter.optimalPrecision(0.5), equals(3));
        expect(MultiAxisValueFormatter.optimalPrecision(0.99), equals(3));
      });

      test('returns 4 for very small values (< 0.1)', () {
        expect(MultiAxisValueFormatter.optimalPrecision(0.00123), equals(4));
        expect(MultiAxisValueFormatter.optimalPrecision(0.01), equals(4));
        expect(MultiAxisValueFormatter.optimalPrecision(0.099), equals(4));
      });

      test('uses absolute value for negative numbers', () {
        // -1234.5 should use same precision as 1234.5
        expect(MultiAxisValueFormatter.optimalPrecision(-1234.5), equals(0));
        expect(MultiAxisValueFormatter.optimalPrecision(-0.5), equals(3));
      });
    });

    group('formatWithDenormalization', () {
      test('formats denormalized value correctly', () {
        // Denormalize 0.5 from range (100, 300) should give 200
        final result = MultiAxisValueFormatter.formatWithDenormalization(
          normalizedValue: 0.5,
          min: 100.0,
          max: 300.0,
        );
        expect(result, equals('200'));
      });

      test('formats denormalized value with unit', () {
        // Denormalize 0.5 from range (0, 500) = 250 W
        final result = MultiAxisValueFormatter.formatWithDenormalization(
          normalizedValue: 0.5,
          min: 0.0,
          max: 500.0,
          unit: 'W',
        );
        expect(result, equals('250 W'));
      });

      test('denormalizes 0.0 to minimum value', () {
        final result = MultiAxisValueFormatter.formatWithDenormalization(
          normalizedValue: 0.0,
          min: 100.0,
          max: 200.0,
          unit: 'bpm',
        );
        expect(result, equals('100 bpm'));
      });

      test('denormalizes 1.0 to maximum value', () {
        final result = MultiAxisValueFormatter.formatWithDenormalization(
          normalizedValue: 1.0,
          min: 100.0,
          max: 200.0,
          unit: 'bpm',
        );
        expect(result, equals('200 bpm'));
      });

      test('respects explicit precision', () {
        final result = MultiAxisValueFormatter.formatWithDenormalization(
          normalizedValue: 0.333,
          min: 0.0,
          max: 100.0,
          precision: 1,
        );
        expect(result, equals('33.3'));
      });

      test('handles negative ranges', () {
        final result = MultiAxisValueFormatter.formatWithDenormalization(
          normalizedValue: 0.5,
          min: -100.0,
          max: 100.0,
        );
        expect(result, equals('0'));
      });

      test('handles values outside 0-1 range', () {
        // Normalized value > 1 means value above max
        final result = MultiAxisValueFormatter.formatWithDenormalization(
          normalizedValue: 1.5,
          min: 0.0,
          max: 100.0,
          unit: 'W',
        );
        expect(result, equals('150 W'));
      });
    });

    group('edge cases', () {
      test('handles very large values without scientific notation', () {
        final result =
            MultiAxisValueFormatter.format(value: 999999.0, unit: 'W');
        expect(result, equals('999999 W'));
      });

      test('handles floating point precision issues', () {
        // This tests that we don't get things like "250.00000001"
        final result = MultiAxisValueFormatter.formatWithDenormalization(
          normalizedValue: 0.5,
          min: 0.0,
          max: 500.0,
        );
        expect(result, equals('250'));
        expect(result.contains('0000'), isFalse);
      });

      test('format with empty unit string treats as null', () {
        // Empty string unit should behave like null
        final result = MultiAxisValueFormatter.format(value: 100.0, unit: '');
        expect(result, equals('100'));
      });

      test('handles zero range correctly', () {
        // When min == max, denormalize returns min
        final result = MultiAxisValueFormatter.formatWithDenormalization(
          normalizedValue: 0.5,
          min: 100.0,
          max: 100.0,
          unit: 'W',
        );
        expect(result, equals('100 W'));
      });
    });
  });
}
