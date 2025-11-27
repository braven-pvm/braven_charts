// Copyright 2025 Braven Charts - TDD Unit Tests for Value Formatter
// SPDX-License-Identifier: MIT
//
// T040 [US4] Unit tests for value formatting with units
// TDD: These tests are written FIRST and should FAIL until implementation is complete.

import 'package:braven_charts/src_plus/formatting/multi_axis_value_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MultiAxisValueFormatter', () {
    group('formatValue - basic formatting', () {
      test('formats integer values without decimal places', () {
        // Given: An integer value with no unit
        // When: Formatting the value
        final formatted = MultiAxisValueFormatter.formatValue(value: 240.0);

        // Then: Should format as integer
        expect(formatted, equals('240'));
      });

      test('formats value with unit suffix', () {
        // Given: A value with a unit
        // When: Formatting the value with unit
        final formatted = MultiAxisValueFormatter.formatValue(
          value: 240.0,
          unit: 'W',
        );

        // Then: Should format as "value unit"
        expect(formatted, equals('240 W'));
      });

      test('formats decimal values with appropriate precision', () {
        // Given: A decimal value
        // When: Formatting the value
        final formatted = MultiAxisValueFormatter.formatValue(
          value: 2.345,
          unit: 'L',
        );

        // Then: Should show reasonable decimal places (not over-precise)
        expect(formatted, equals('2.3 L'));
      });

      test('formats very small values with appropriate precision', () {
        // Given: A micro-scale value
        // When: Formatting the value
        final formatted = MultiAxisValueFormatter.formatValue(
          value: 0.00123,
          unit: 'µV',
        );

        // Then: Should format appropriately for small values
        expect(
            formatted,
            anyOf([
              equals('0.001 µV'),
              equals('0.0012 µV'),
              equals('0.00123 µV'),
            ]));
      });

      test('formats large values appropriately', () {
        // Given: A large value
        // When: Formatting the value
        final formatted = MultiAxisValueFormatter.formatValue(
          value: 12345.0,
          unit: 'steps',
        );

        // Then: Should format as integer
        expect(formatted, equals('12345 steps'));
      });
    });

    group('formatValue - edge cases', () {
      test('handles zero value', () {
        final formatted = MultiAxisValueFormatter.formatValue(
          value: 0.0,
          unit: 'W',
        );

        expect(formatted, equals('0 W'));
      });

      test('handles negative values', () {
        final formatted = MultiAxisValueFormatter.formatValue(
          value: -15.5,
          unit: '°C',
        );

        expect(formatted, equals('-15.5 °C'));
      });

      test('handles empty unit string', () {
        final formatted = MultiAxisValueFormatter.formatValue(
          value: 100.0,
          unit: '',
        );

        expect(formatted, equals('100'));
      });

      test('handles null unit', () {
        final formatted = MultiAxisValueFormatter.formatValue(
          value: 100.0,
          unit: null,
        );

        expect(formatted, equals('100'));
      });
    });

    group('formatValue - precision control', () {
      test('respects explicit decimal places parameter', () {
        final formatted = MultiAxisValueFormatter.formatValue(
          value: 123.456789,
          unit: 'kg',
          decimalPlaces: 2,
        );

        expect(formatted, equals('123.46 kg'));
      });

      test('auto-determines precision based on range', () {
        // Given: A value and its data range
        // When: Using auto-precision based on range
        final formatted = MultiAxisValueFormatter.formatValueForRange(
          value: 155.3,
          minValue: 100.0,
          maxValue: 200.0,
          unit: 'W',
        );

        // Then: For 100-unit range, should show integer or 1 decimal
        expect(formatted, anyOf([equals('155 W'), equals('155.3 W')]));
      });

      test('increases precision for small ranges', () {
        // Given: A value within a small range
        // When: Using auto-precision
        final formatted = MultiAxisValueFormatter.formatValueForRange(
          value: 0.00234,
          minValue: 0.001,
          maxValue: 0.005,
          unit: 'µV',
        );

        // Then: Should show enough decimal places to distinguish values
        expect(formatted, contains('0.002'));
      });
    });

    group('determinePrecision', () {
      test('returns 0 for ranges > 100', () {
        final precision = MultiAxisValueFormatter.determinePrecision(
          range: 150.0,
        );
        expect(precision, equals(0));
      });

      test('returns 1 for ranges 10-100', () {
        final precision = MultiAxisValueFormatter.determinePrecision(
          range: 50.0,
        );
        expect(precision, equals(1));
      });

      test('returns 2 for ranges 1-10', () {
        final precision = MultiAxisValueFormatter.determinePrecision(
          range: 5.0,
        );
        expect(precision, equals(2));
      });

      test('returns more precision for ranges < 1', () {
        final precision = MultiAxisValueFormatter.determinePrecision(
          range: 0.005,
        );
        expect(precision, greaterThan(2));
      });
    });

    group('formatSeriesValue - multi-axis context', () {
      test('formats value with series name and unit', () {
        final formatted = MultiAxisValueFormatter.formatSeriesValue(
          value: 165.0,
          seriesName: 'Heart Rate',
          unit: 'bpm',
        );

        expect(formatted, equals('Heart Rate: 165 bpm'));
      });

      test('formats multiple series values for tooltip', () {
        final seriesValues = [
          (name: 'Power', value: 240.0, unit: 'W'),
          (name: 'Heart Rate', value: 165.0, unit: 'bpm'),
          (name: 'Cadence', value: 95.0, unit: 'rpm'),
        ];

        final formatted = MultiAxisValueFormatter.formatMultipleSeriesValues(
          seriesValues: seriesValues,
        );

        // Then: Should format as multi-line string
        expect(formatted, contains('Power: 240 W'));
        expect(formatted, contains('Heart Rate: 165 bpm'));
        expect(formatted, contains('Cadence: 95 rpm'));
      });
    });

    group('roundToSignificantFigures', () {
      test('rounds to specified significant figures', () {
        final rounded = MultiAxisValueFormatter.roundToSignificantFigures(
          12345.6789,
          3,
        );
        expect(rounded, closeTo(12300, 100));
      });

      test('handles very small numbers', () {
        final rounded = MultiAxisValueFormatter.roundToSignificantFigures(
          0.00012345,
          2,
        );
        expect(rounded, closeTo(0.00012, 0.00001));
      });
    });
  });
}
