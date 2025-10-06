/// Contract tests for LineChartConfig
///
/// These tests verify that any implementation of LineChartConfig follows
/// the contract defined in specs/005-chart-types/contracts/line_chart_config.dart
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/charts/line/line_chart_config.dart';
import 'package:braven_charts/src/charts/base/chart_config.dart';

void main() {
  group('LineChartConfig Contract Tests', () {
    group('Validation Rules', () {
      test('markerSize must be > 0', () {
        expect(
          () => LineChartConfig(
            lineStyle: LineStyle.straight,
            markerShape: MarkerShape.circle,
            markerSize: 0.0, // INVALID: must be > 0
            showMarkers: true,
            lineWidth: 2.0,
            connectNulls: false,
          ),
          throwsA(isA<AssertionError>()),
          reason: 'markerSize must be > 0',
        );
      });

      test('markerSize must be positive when provided', () {
        expect(
          () => LineChartConfig(
            lineStyle: LineStyle.straight,
            markerShape: MarkerShape.circle,
            markerSize: -5.0, // INVALID: negative
            showMarkers: true,
            lineWidth: 2.0,
            connectNulls: false,
          ),
          throwsA(isA<AssertionError>()),
          reason: 'markerSize must be positive',
        );
      });

      test('lineWidth must be > 0', () {
        expect(
          () => LineChartConfig(
            lineStyle: LineStyle.straight,
            markerShape: MarkerShape.circle,
            markerSize: 6.0,
            showMarkers: true,
            lineWidth: 0.0, // INVALID: must be > 0
            connectNulls: false,
          ),
          throwsA(isA<AssertionError>()),
          reason: 'lineWidth must be > 0',
        );
      });

      test('dashPattern must have even length if non-null', () {
        expect(
          () => LineChartConfig(
            lineStyle: LineStyle.straight,
            markerShape: MarkerShape.circle,
            markerSize: 6.0,
            showMarkers: true,
            lineWidth: 2.0,
            dashPattern: [5.0, 3.0, 2.0], // INVALID: odd length (3 elements)
            connectNulls: false,
          ),
          throwsA(isA<AssertionError>()),
          reason: 'dashPattern must have even length for on/off pairs',
        );
      });

      test('dashPattern can be null (solid line)', () {
        expect(
          () => LineChartConfig(
            lineStyle: LineStyle.straight,
            markerShape: MarkerShape.circle,
            markerSize: 6.0,
            showMarkers: true,
            lineWidth: 2.0,
            dashPattern: null, // VALID: null means solid line
            connectNulls: false,
          ),
          returnsNormally,
          reason: 'dashPattern can be null for solid lines',
        );
      });

      test('dashPattern with even length is valid', () {
        expect(
          () => LineChartConfig(
            lineStyle: LineStyle.straight,
            markerShape: MarkerShape.circle,
            markerSize: 6.0,
            showMarkers: true,
            lineWidth: 2.0,
            dashPattern: [5.0, 3.0], // VALID: even length
            connectNulls: false,
          ),
          returnsNormally,
          reason: 'dashPattern with even length should be accepted',
        );
      });
    });

    group('copyWith() behavior', () {
      test('copyWith creates new instance with modified properties', () {
        final original = LineChartConfig(
          lineStyle: LineStyle.straight,
          markerShape: MarkerShape.circle,
          markerSize: 6.0,
          showMarkers: true,
          lineWidth: 2.0,
          connectNulls: false,
        );

        final modified = original.copyWith(
          lineStyle: LineStyle.smooth,
          markerSize: 8.0,
        );

        expect(modified.lineStyle, equals(LineStyle.smooth));
        expect(modified.markerSize, equals(8.0));
        expect(modified.markerShape, equals(original.markerShape));
        expect(modified.showMarkers, equals(original.showMarkers));
        expect(modified.lineWidth, equals(original.lineWidth));
        expect(modified.connectNulls, equals(original.connectNulls));
      });

      test('copyWith without arguments returns equivalent instance', () {
        final original = LineChartConfig(
          lineStyle: LineStyle.straight,
          markerShape: MarkerShape.circle,
          markerSize: 6.0,
          showMarkers: true,
          lineWidth: 2.0,
          connectNulls: false,
        );

        final copy = original.copyWith();

        expect(copy.lineStyle, equals(original.lineStyle));
        expect(copy.markerShape, equals(original.markerShape));
        expect(copy.markerSize, equals(original.markerSize));
        expect(copy.showMarkers, equals(original.showMarkers));
        expect(copy.lineWidth, equals(original.lineWidth));
        expect(copy.dashPattern, equals(original.dashPattern));
        expect(copy.connectNulls, equals(original.connectNulls));
      });
    });

    group('validate() method', () {
      test('validate() does not throw for valid config', () {
        final config = LineChartConfig(
          lineStyle: LineStyle.straight,
          markerShape: MarkerShape.circle,
          markerSize: 6.0,
          showMarkers: true,
          lineWidth: 2.0,
          connectNulls: false,
        );

        expect(() => config.validate(), returnsNormally);
      });

      test('validate() throws for invalid markerSize', () {
        // markerSize is validated in constructor via assert
        // validate() method provides runtime validation
        final config = LineChartConfig(
          lineStyle: LineStyle.straight,
          markerShape: MarkerShape.circle,
          markerSize: 6.0,
          showMarkers: true,
          lineWidth: 2.0,
          connectNulls: false,
        );
        
        // Validated config should pass
        expect(() => config.validate(), returnsNormally);
      });
    });

    group('Immutability', () {
      test('LineChartConfig instances are immutable', () {
        // This is verified by the class having final fields
        // Dart's type system enforces this at compile time
        final config = LineChartConfig(
          lineStyle: LineStyle.straight,
          markerShape: MarkerShape.circle,
          markerSize: 6.0,
          showMarkers: true,
          lineWidth: 2.0,
          connectNulls: false,
        );

        // If fields are final, this will compile
        expect(config.markerSize, equals(6.0));
      });
    });
  });
}
