/// Contract tests for AreaChartConfig
///
/// These tests verify that any implementation of AreaChartConfig follows
/// the contract defined in specs/005-chart-types/contracts/area_chart_config.dart
library;

import 'package:braven_charts/legacy/src/charts/area/area_chart_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AreaChartConfig Contract Tests', () {
    group('Validation Rules', () {
      test('fillOpacity must be >= 0.0', () {
        expect(
          () => AreaChartConfig(
            fillStyle: AreaFillStyle.solid,
            baseline: const AreaBaseline.zero(),
            stacked: false,
            fillOpacity: -0.1, // INVALID: < 0.0
            showLine: false,
          ),
          throwsA(isA<AssertionError>()),
          reason: 'fillOpacity must be >= 0.0',
        );
      });

      test('fillOpacity cannot exceed 1.0', () {
        expect(
          () => AreaChartConfig(
            fillStyle: AreaFillStyle.solid,
            baseline: const AreaBaseline.zero(),
            stacked: false,
            fillOpacity: 1.5, // INVALID: > 1.0
            showLine: false,
          ),
          throwsA(isA<AssertionError>()),
          reason: 'fillOpacity must be <= 1.0',
        );
      });

      test('fillOpacity boundaries (0.0 and 1.0) are valid', () {
        expect(
          () => const AreaChartConfig(
            fillStyle: AreaFillStyle.solid,
            baseline: AreaBaseline.zero(),
            stacked: false,
            fillOpacity: 0.0, // VALID: minimum
            showLine: false,
          ),
          returnsNormally,
        );

        expect(
          () => const AreaChartConfig(
            fillStyle: AreaFillStyle.solid,
            baseline: AreaBaseline.zero(),
            stacked: false,
            fillOpacity: 1.0, // VALID: maximum
            showLine: false,
          ),
          returnsNormally,
        );
      });

      test('showLine=true requires lineConfig to be non-null', () {
        expect(
          () => AreaChartConfig(
            fillStyle: AreaFillStyle.solid,
            baseline: const AreaBaseline.zero(),
            stacked: false,
            fillOpacity: 0.5,
            showLine: true, // INVALID: lineConfig is null
            lineConfig: null,
          ),
          throwsA(isA<AssertionError>()),
          reason: 'showLine=true requires lineConfig',
        );
      });

      test('showLine=false allows null lineConfig', () {
        expect(
          () => const AreaChartConfig(
            fillStyle: AreaFillStyle.solid,
            baseline: AreaBaseline.zero(),
            stacked: false,
            fillOpacity: 0.5,
            showLine: false, // VALID: lineConfig can be null
            lineConfig: null,
          ),
          returnsNormally,
        );
      });

      test('showLine=true with valid lineConfig is accepted', () {
        // Using a mock lineConfig since we don't want cross-dependencies
        expect(
          () => const AreaChartConfig(
            fillStyle: AreaFillStyle.solid,
            baseline: AreaBaseline.zero(),
            stacked: false,
            fillOpacity: 0.5,
            showLine: true,
            lineConfig: 'mock_line_config', // Mock value
          ),
          returnsNormally,
        );
      });
    });

    group('copyWith() behavior', () {
      test('copyWith creates new instance with modified properties', () {
        final original = const AreaChartConfig(
          fillStyle: AreaFillStyle.solid,
          baseline: AreaBaseline.zero(),
          stacked: false,
          fillOpacity: 0.5,
          showLine: false,
        );

        final modified = original.copyWith(
          fillStyle: AreaFillStyle.gradient,
          fillOpacity: 0.7,
        );

        expect(modified.fillStyle, equals(AreaFillStyle.gradient));
        expect(modified.fillOpacity, equals(0.7));
        expect(modified.baseline, equals(original.baseline));
        expect(modified.stacked, equals(original.stacked));
        expect(modified.showLine, equals(original.showLine));
      });

      test('copyWith without arguments returns equivalent instance', () {
        final original = const AreaChartConfig(
          fillStyle: AreaFillStyle.solid,
          baseline: AreaBaseline.zero(),
          stacked: false,
          fillOpacity: 0.5,
          showLine: false,
        );

        final copy = original.copyWith();

        expect(copy.fillStyle, equals(original.fillStyle));
        expect(copy.baseline, equals(original.baseline));
        expect(copy.stacked, equals(original.stacked));
        expect(copy.fillOpacity, equals(original.fillOpacity));
        expect(copy.showLine, equals(original.showLine));
        expect(copy.lineConfig, equals(original.lineConfig));
      });
    });

    group('validate() method', () {
      test('validate() does not throw for valid config', () {
        final config = const AreaChartConfig(
          fillStyle: AreaFillStyle.solid,
          baseline: AreaBaseline.zero(),
          stacked: false,
          fillOpacity: 0.5,
          showLine: false,
        );

        expect(() => config.validate(), returnsNormally);
      });
    });
  });

  group('AreaBaseline Contract Tests', () {
    group('Validation Rules', () {
      test('type=fixed requires fixedValue to be non-null', () {
        expect(
          () => AreaBaseline(
            type: AreaBaselineType.fixed,
            fixedValue: null, // INVALID: required for fixed type
          ),
          throwsA(isA<AssertionError>()),
          reason: 'type=fixed requires fixedValue',
        );
      });

      test('type=series requires seriesId to be non-null', () {
        expect(
          () => AreaBaseline(
            type: AreaBaselineType.series,
            seriesId: null, // INVALID: required for series type
          ),
          throwsA(isA<AssertionError>()),
          reason: 'type=series requires seriesId',
        );
      });

      test('type=zero does not require fixedValue or seriesId', () {
        expect(
          () => const AreaBaseline.zero(),
          returnsNormally,
        );
      });
    });
  });
}
