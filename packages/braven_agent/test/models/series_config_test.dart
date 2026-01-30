// @orchestra-task: 2
@Tags(['tdd-red'])
library;

import 'package:braven_agent/src/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// T009: TDD Red Phase - Agent SeriesConfig nested yAxis field tests.
///
/// According to FR-001 and FR-002:
/// - FR-001: Series must support nested yAxis object containing all y-axis properties
/// - FR-002: Flat y-axis fields (yAxisPosition, yAxisLabel, etc.) are prohibited
///
/// These tests use JSON serialization to verify the structure without requiring
/// the actual yAxis field to exist yet. Tests FAIL because the new structure
/// isn't implemented.
void main() {
  group('SeriesConfig nested yAxis field', () {
    group('yAxis in JSON serialization (FR-001)', () {
      test('toJson() should include nested yAxis object (not flat fields)', () {
        // Arrange: Create a series with y-axis info using existing flat fields
        const series = SeriesConfig(
          id: 'power',
          data: [DataPoint(x: 0, y: 100)],
          yAxisPosition: 'left',
          yAxisLabel: 'Power',
          yAxisUnit: 'W',
        );

        // Act: Serialize to JSON
        final json = series.toJson();

        // Assert: Per FR-001, should have nested 'yAxis', not flat fields
        // This test FAILS because current implementation uses flat fields
        expect(json.containsKey('yAxis'), isTrue,
            reason: 'FR-001: yAxis must be a nested object');
        expect(json['yAxis'], isA<Map<String, dynamic>>(),
            reason: 'FR-001: yAxis must be a Map, not flat fields');
      });

      test('fromJson() should parse nested yAxis object', () {
        // Arrange: JSON with nested yAxis (new format per FR-001)
        final json = {
          'id': 'heart-rate',
          'data': [
            {'x': 0.0, 'y': 120.0}
          ],
          'yAxis': {
            'position': 'right',
            'label': 'Heart Rate',
            'unit': 'bpm',
            'min': 50,
            'max': 200,
          },
        };

        // Act: Parse from JSON
        final series = SeriesConfig.fromJson(json);

        // Assert: After serializing back, should preserve nested structure
        final outputJson = series.toJson();

        // This test FAILS because current fromJson doesn't parse nested yAxis
        expect(outputJson.containsKey('yAxis'), isTrue,
            reason: 'FR-001: yAxis must be preserved as nested object');
        expect(outputJson['yAxis'], isA<Map<String, dynamic>>());
        expect(outputJson['yAxis']['label'], equals('Heart Rate'),
            reason: 'FR-001: nested yAxis properties must be preserved');
      });

      test('round-trip should preserve nested yAxis structure', () {
        // Arrange: JSON with nested yAxis
        final inputJson = {
          'id': 'cadence',
          'data': [
            {'x': 0.0, 'y': 85.0}
          ],
          'yAxis': {
            'position': 'right',
            'label': 'Cadence',
            'unit': 'rpm',
            'min': 0,
            'max': 120,
          },
        };

        // Act: Round-trip
        final series = SeriesConfig.fromJson(inputJson);
        final outputJson = series.toJson();

        // Assert: Nested structure preserved
        // This test FAILS because nested yAxis is not supported
        expect(outputJson['yAxis'], isA<Map<String, dynamic>>());
        expect(outputJson['yAxis']['label'], equals('Cadence'));
        expect(outputJson['yAxis']['unit'], equals('rpm'));
      });
    });

    group('flat y-axis fields prohibited (FR-002)', () {
      test('toJson() should NOT include flat yAxisPosition field', () {
        // Arrange: Even if constructed with flat fields (old API)
        const series = SeriesConfig(
          id: 'test',
          data: [DataPoint(x: 0, y: 0)],
          yAxisPosition: 'left',
        );

        // Act
        final json = series.toJson();

        // Assert: Flat fields should NOT appear in output per FR-002
        // This test FAILS because current implementation outputs flat fields
        expect(json.containsKey('yAxisPosition'), isFalse,
            reason: 'FR-002: yAxisPosition flat field is prohibited');
      });

      test('toJson() should NOT include flat yAxisLabel field', () {
        const series = SeriesConfig(
          id: 'test',
          data: [DataPoint(x: 0, y: 0)],
          yAxisLabel: 'Test Label',
        );

        final json = series.toJson();

        // This test FAILS because yAxisLabel is currently serialized
        expect(json.containsKey('yAxisLabel'), isFalse,
            reason: 'FR-002: yAxisLabel flat field is prohibited');
      });

      test('toJson() should NOT include flat yAxisUnit field', () {
        const series = SeriesConfig(
          id: 'test',
          data: [DataPoint(x: 0, y: 0)],
          yAxisUnit: 'W',
        );

        final json = series.toJson();

        expect(json.containsKey('yAxisUnit'), isFalse,
            reason: 'FR-002: yAxisUnit flat field is prohibited');
      });

      test('toJson() should NOT include flat yAxisMin/yAxisMax fields', () {
        const series = SeriesConfig(
          id: 'test',
          data: [DataPoint(x: 0, y: 0)],
          yAxisMin: 0,
          yAxisMax: 100,
        );

        final json = series.toJson();

        expect(json.containsKey('yAxisMin'), isFalse,
            reason: 'FR-002: yAxisMin flat field is prohibited');
        expect(json.containsKey('yAxisMax'), isFalse,
            reason: 'FR-002: yAxisMax flat field is prohibited');
      });

      test('toJson() should NOT include flat yAxisColor field', () {
        const series = SeriesConfig(
          id: 'test',
          data: [DataPoint(x: 0, y: 0)],
          yAxisColor: '#FF0000',
        );

        final json = series.toJson();

        expect(json.containsKey('yAxisColor'), isFalse,
            reason: 'FR-002: yAxisColor flat field is prohibited');
      });
    });

    group('yAxisId reference prohibited (FR-003)', () {
      test('toJson() should NOT include yAxisId field', () {
        const series = SeriesConfig(
          id: 'test',
          data: [DataPoint(x: 0, y: 0)],
          yAxisId: 'shared-axis',
        );

        final json = series.toJson();

        // This test FAILS because yAxisId is currently serialized
        expect(json.containsKey('yAxisId'), isFalse,
            reason: 'FR-003: yAxisId reference field is prohibited');
      });

      test('fromJson() should ignore yAxisId if present', () {
        // Arrange: Legacy JSON with yAxisId
        final json = {
          'id': 'test',
          'data': [
            {'x': 0.0, 'y': 0.0}
          ],
          'yAxisId': 'legacy-axis-ref',
        };

        // Act
        final series = SeriesConfig.fromJson(json);
        final outputJson = series.toJson();

        // Assert: yAxisId should not appear in output
        expect(outputJson.containsKey('yAxisId'), isFalse,
            reason: 'FR-003: yAxisId should be ignored/not serialized');
      });
    });
  });
}
