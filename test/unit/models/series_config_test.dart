library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

/// T006: TDD Red Phase - Core ChartSeries.yAxisConfig serialization tests.
///
/// These tests verify that ChartSeries has toJson/fromJson methods for
/// proper serialization of yAxisConfig. The core library already has
/// yAxisConfig on ChartSeries, but serialization needs to be verified.
///
/// Tests FAIL because:
/// - ChartSeries does not have toJson() implemented yet
/// - ChartSeries does not have fromJson() implemented yet
void main() {
  group('ChartSeries.yAxisConfig', () {
    group('yAxisConfig accessibility', () {
      test('yAxisConfig is accessible on ChartSeries', () {
        // This test PASSES - yAxisConfig field exists
        final series = ChartSeries(
          id: 'power',
          points: const [
            ChartDataPoint(x: 0, y: 100),
            ChartDataPoint(x: 1, y: 150),
          ],
          yAxisConfig: YAxisConfig(
            position: YAxisPosition.left,
            label: 'Power',
            unit: 'W',
          ),
        );

        expect(series.yAxisConfig, isNotNull);
        expect(series.yAxisConfig!.label, equals('Power'));
        expect(series.yAxisConfig!.unit, equals('W'));
      });

      test('yAxisId is accessible on ChartSeries', () {
        // This test PASSES - yAxisId field exists
        const series = ChartSeries(
          id: 'temperature',
          points: [ChartDataPoint(x: 0, y: 20)],
          yAxisId: 'shared-temp-axis',
        );

        expect(series.yAxisId, equals('shared-temp-axis'));
      });
    });

    group('serialization support', () {
      test('ChartSeries has toJson method for serialization', () {
        final series = ChartSeries(
          id: 'power',
          points: const [ChartDataPoint(x: 0, y: 100)],
          yAxisConfig: YAxisConfig(
            position: YAxisPosition.left,
            label: 'Power',
            unit: 'W',
          ),
        );

        // Check if toJson method exists
        // This test FAILS because toJson is not implemented
        final hasToJson = _hasMethod(series, 'toJson');
        expect(
          hasToJson,
          isTrue,
          reason:
              'ChartSeries must have toJson() for yAxisConfig serialization',
        );
      });

      test('ChartSeries class has fromJson static method', () {
        // Check if fromJson exists as a static method
        // This test FAILS because fromJson is not implemented
        final hasFromJson = _hasStaticMethod(ChartSeries, 'fromJson');
        expect(
          hasFromJson,
          isTrue,
          reason:
              'ChartSeries must have fromJson() for yAxisConfig deserialization',
        );
      });
    });

    group('yAxisConfig serialization format', () {
      test('toJson should include yAxisConfig as nested object', () {
        final series = ChartSeries(
          id: 'power',
          points: const [ChartDataPoint(x: 0, y: 100)],
          yAxisConfig: YAxisConfig(
            position: YAxisPosition.left,
            label: 'Power',
            unit: 'W',
            min: 0,
            max: 500,
          ),
        );

        // This test FAILS because toJson doesn't exist
        final hasToJson = _hasMethod(series, 'toJson');
        expect(
          hasToJson,
          isTrue,
          reason:
              'ChartSeries must have toJson() - prerequisite for format check',
        );

        // If we get here, verify the format
        if (hasToJson) {
          final json = (series as dynamic).toJson() as Map<String, dynamic>;
          expect(
            json.containsKey('yAxisConfig'),
            isTrue,
            reason: 'yAxisConfig must be serialized as nested object',
          );
        }
      });

      test('toJson should include yAxisId when set', () {
        const series = ChartSeries(
          id: 'temperature',
          points: [ChartDataPoint(x: 0, y: 20)],
          yAxisId: 'shared-axis',
        );

        final hasToJson = _hasMethod(series, 'toJson');
        expect(
          hasToJson,
          isTrue,
          reason:
              'ChartSeries must have toJson() - prerequisite for format check',
        );

        if (hasToJson) {
          final json = (series as dynamic).toJson() as Map<String, dynamic>;
          expect(json['yAxisId'], equals('shared-axis'));
        }
      });
    });
  });
}

/// Helper function to check if an object has a specific instance method.
bool _hasMethod(Object obj, String methodName) {
  try {
    switch (methodName) {
      case 'toJson':
        (obj as dynamic).toJson();
        return true;
      default:
        return false;
    }
  } on NoSuchMethodError {
    return false;
  } catch (_) {
    return true;
  }
}

/// Helper function to check if a type has a specific static method.
/// Note: Dart doesn't support dynamic static method calls on Type objects,
/// so we test specific classes directly.
bool _hasStaticMethod(Type type, String methodName) {
  try {
    switch (methodName) {
      case 'fromJson':
        // For ChartSeries, call the static method directly
        // (Dart doesn't support (Type as dynamic).staticMethod())
        if (type == ChartSeries) {
          ChartSeries.fromJson(<String, dynamic>{'id': 'test', 'points': []});
          return true;
        }
        return false;
      default:
        return false;
    }
  } on NoSuchMethodError {
    return false;
  } catch (_) {
    // Method exists but might fail for other reasons (e.g., invalid input)
    return true;
  }
}
