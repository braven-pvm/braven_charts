/// Contract tests for BarChartConfig
///
/// These tests verify that any implementation of BarChartConfig follows
/// the contract defined in specs/005-chart-types/contracts/bar_chart_config.dart
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/charts/bar/bar_chart_config.dart';

void main() {
  group('BarChartConfig Contract Tests', () {
    group('Validation Rules', () {
      test('barWidthRatio must be > 0.0', () {
        expect(
          () => BarChartConfig(
            orientation: BarOrientation.vertical,
            groupingMode: BarGroupingMode.grouped,
            barWidthRatio: 0.0, // INVALID: must be > 0.0
            barSpacing: 2.0,
            groupSpacing: 4.0,
            cornerRadius: 0.0,
            borderWidth: 0.0,
            useGradient: false,
          ),
          throwsA(isA<AssertionError>()),
          reason: 'barWidthRatio must be > 0.0',
        );
      });

      test('barWidthRatio cannot exceed 1.0', () {
        expect(
          () => BarChartConfig(
            orientation: BarOrientation.vertical,
            groupingMode: BarGroupingMode.grouped,
            barWidthRatio: 1.1, // INVALID: > 1.0
            barSpacing: 2.0,
            groupSpacing: 4.0,
            cornerRadius: 0.0,
            borderWidth: 0.0,
            useGradient: false,
          ),
          throwsA(isA<AssertionError>()),
          reason: 'barWidthRatio must be <= 1.0',
        );
      });

      test('barWidthRatio = 1.0 is valid (inclusive upper bound)', () {
        expect(
          () => BarChartConfig(
            orientation: BarOrientation.vertical,
            groupingMode: BarGroupingMode.grouped,
            barWidthRatio: 1.0, // VALID: maximum
            barSpacing: 2.0,
            groupSpacing: 4.0,
            cornerRadius: 0.0,
            borderWidth: 0.0,
            useGradient: false,
          ),
          returnsNormally,
        );
      });

      test('barSpacing must be >= 0.0', () {
        expect(
          () => BarChartConfig(
            orientation: BarOrientation.vertical,
            groupingMode: BarGroupingMode.grouped,
            barWidthRatio: 0.8,
            barSpacing: -1.0, // INVALID: negative
            groupSpacing: 4.0,
            cornerRadius: 0.0,
            borderWidth: 0.0,
            useGradient: false,
          ),
          throwsA(isA<AssertionError>()),
          reason: 'barSpacing must be non-negative',
        );
      });

      test('groupSpacing must be >= 0.0', () {
        expect(
          () => BarChartConfig(
            orientation: BarOrientation.vertical,
            groupingMode: BarGroupingMode.grouped,
            barWidthRatio: 0.8,
            barSpacing: 2.0,
            groupSpacing: -2.0, // INVALID: negative
            cornerRadius: 0.0,
            borderWidth: 0.0,
            useGradient: false,
          ),
          throwsA(isA<AssertionError>()),
          reason: 'groupSpacing must be non-negative',
        );
      });

      test('cornerRadius must be >= 0.0', () {
        expect(
          () => BarChartConfig(
            orientation: BarOrientation.vertical,
            groupingMode: BarGroupingMode.grouped,
            barWidthRatio: 0.8,
            barSpacing: 2.0,
            groupSpacing: 4.0,
            cornerRadius: -1.0, // INVALID: negative
            borderWidth: 0.0,
            useGradient: false,
          ),
          throwsA(isA<AssertionError>()),
          reason: 'cornerRadius must be non-negative',
        );
      });

      test('borderWidth must be >= 0.0', () {
        expect(
          () => BarChartConfig(
            orientation: BarOrientation.vertical,
            groupingMode: BarGroupingMode.grouped,
            barWidthRatio: 0.8,
            barSpacing: 2.0,
            groupSpacing: 4.0,
            cornerRadius: 4.0,
            borderWidth: -1.0, // INVALID: negative
            useGradient: false,
          ),
          throwsA(isA<AssertionError>()),
          reason: 'borderWidth must be non-negative',
        );
      });

      test('useGradient=true requires gradientStart or gradientEnd', () {
        expect(
          () => BarChartConfig(
            orientation: BarOrientation.vertical,
            groupingMode: BarGroupingMode.grouped,
            barWidthRatio: 0.8,
            barSpacing: 2.0,
            groupSpacing: 4.0,
            cornerRadius: 0.0,
            borderWidth: 0.0,
            useGradient: true, // INVALID: both gradientStart and gradientEnd are null
            gradientStart: null,
            gradientEnd: null,
          ),
          throwsA(isA<AssertionError>()),
          reason: 'useGradient=true requires at least one gradient color',
        );
      });

      test('useGradient=false allows null gradient colors', () {
        expect(
          () => BarChartConfig(
            orientation: BarOrientation.vertical,
            groupingMode: BarGroupingMode.grouped,
            barWidthRatio: 0.8,
            barSpacing: 2.0,
            groupSpacing: 4.0,
            cornerRadius: 0.0,
            borderWidth: 0.0,
            useGradient: false, // VALID: gradient colors can be null
            gradientStart: null,
            gradientEnd: null,
          ),
          returnsNormally,
        );
      });
    });

    group('copyWith() behavior', () {
      test('copyWith creates new instance with modified properties', () {
        final original = BarChartConfig(
          orientation: BarOrientation.vertical,
          groupingMode: BarGroupingMode.grouped,
          barWidthRatio: 0.8,
          barSpacing: 2.0,
          groupSpacing: 4.0,
          cornerRadius: 0.0,
          borderWidth: 0.0,
          useGradient: false,
        );

        final modified = original.copyWith(
          orientation: BarOrientation.horizontal,
          barWidthRatio: 0.6,
        );

        expect(modified.orientation, equals(BarOrientation.horizontal));
        expect(modified.barWidthRatio, equals(0.6));
        expect(modified.groupingMode, equals(original.groupingMode));
        expect(modified.barSpacing, equals(original.barSpacing));
      });

      test('copyWith without arguments returns equivalent instance', () {
        final original = BarChartConfig(
          orientation: BarOrientation.vertical,
          groupingMode: BarGroupingMode.grouped,
          barWidthRatio: 0.8,
          barSpacing: 2.0,
          groupSpacing: 4.0,
          cornerRadius: 0.0,
          borderWidth: 0.0,
          useGradient: false,
        );

        final copy = original.copyWith();

        expect(copy.orientation, equals(original.orientation));
        expect(copy.groupingMode, equals(original.groupingMode));
        expect(copy.barWidthRatio, equals(original.barWidthRatio));
        expect(copy.barSpacing, equals(original.barSpacing));
        expect(copy.groupSpacing, equals(original.groupSpacing));
        expect(copy.cornerRadius, equals(original.cornerRadius));
        expect(copy.borderWidth, equals(original.borderWidth));
        expect(copy.useGradient, equals(original.useGradient));
      });
    });

    group('validate() method', () {
      test('validate() does not throw for valid config', () {
        final config = BarChartConfig(
          orientation: BarOrientation.vertical,
          groupingMode: BarGroupingMode.grouped,
          barWidthRatio: 0.8,
          barSpacing: 2.0,
          groupSpacing: 4.0,
          cornerRadius: 0.0,
          borderWidth: 0.0,
          useGradient: false,
        );

        expect(() => config.validate(), returnsNormally);
      });
    });
  });
}
