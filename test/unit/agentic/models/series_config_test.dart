// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/agentic/models/models.dart';

void main() {
  group('MarkerStyle', () {
    test('has all required enum values', () {
      expect(MarkerStyle.values.contains(MarkerStyle.none), isTrue);
      expect(MarkerStyle.values.contains(MarkerStyle.circle), isTrue);
      expect(MarkerStyle.values.contains(MarkerStyle.square), isTrue);
      expect(MarkerStyle.values.contains(MarkerStyle.triangle), isTrue);
      expect(MarkerStyle.values.contains(MarkerStyle.diamond), isTrue);
    });
  });

  group('Interpolation', () {
    test('has all required enum values', () {
      expect(Interpolation.values.contains(Interpolation.linear), isTrue);
      expect(Interpolation.values.contains(Interpolation.bezier), isTrue);
      expect(Interpolation.values.contains(Interpolation.stepped), isTrue);
      expect(Interpolation.values.contains(Interpolation.monotone), isTrue);
    });
  });

  group('SeriesConfig', () {
    group('constructor', () {
      test('creates instance with minimal required parameters', () {
        final config = SeriesConfig(
          id: 'series-1',
          dataColumn: 'value',
        );

        expect(config.id, equals('series-1'));
        expect(config.name, isNull);
        expect(config.dataColumn, equals('value'));
        expect(config.dataId, isNull);
        expect(config.data, isNull);
      });

      test('creates instance with all parameters', () {
        final config = SeriesConfig(
          id: 'series-1',
          name: 'Power Output',
          dataColumn: 'power',
          dataId: 'data-uuid-123',
          color: '#FF5733',
          strokeWidth: 2.5,
          strokeDash: [5.0, 3.0],
          fillOpacity: 0.3,
          markerStyle: MarkerStyle.circle,
          markerSize: 6.0,
          interpolation: Interpolation.bezier,
          showPoints: true,
          yAxisId: 'y-axis-1',
          unit: 'W',
          visible: true,
          legendVisible: true,
        );

        expect(config.id, equals('series-1'));
        expect(config.name, equals('Power Output'));
        expect(config.dataColumn, equals('power'));
        expect(config.dataId, equals('data-uuid-123'));
        expect(config.color, equals('#FF5733'));
        expect(config.strokeWidth, equals(2.5));
        expect(config.strokeDash, equals([5.0, 3.0]));
        expect(config.fillOpacity, equals(0.3));
        expect(config.markerStyle, equals(MarkerStyle.circle));
        expect(config.markerSize, equals(6.0));
        expect(config.interpolation, equals(Interpolation.bezier));
        expect(config.showPoints, isTrue);
        expect(config.yAxisId, equals('y-axis-1'));
        expect(config.unit, equals('W'));
        expect(config.visible, isTrue);
        expect(config.legendVisible, isTrue);
      });

      test('creates instance with explicit data points', () {
        final config = SeriesConfig(
          id: 'series-2',
          name: 'Heart Rate',
          data: [
            {'x': 0, 'y': 120},
            {'x': 60, 'y': 145},
            {'x': 120, 'y': 160},
          ],
          unit: 'bpm',
        );

        expect(config.id, equals('series-2'));
        expect(config.data, isNotNull);
        expect(config.data!.length, equals(3));
        expect(config.dataColumn, isNull);
        expect(config.dataId, isNull);
      });

      test('creates instance with styling defaults', () {
        final config = SeriesConfig(
          id: 'series-3',
          name: 'Default Styling',
          dataColumn: 'value',
        );

        expect(config.strokeWidth, equals(2.0));
        expect(config.fillOpacity, equals(0.0));
        expect(config.markerStyle, equals(MarkerStyle.none));
        expect(config.markerSize, equals(4.0));
        expect(config.interpolation, equals(Interpolation.linear));
        expect(config.showPoints, isFalse);
        expect(config.visible, isTrue);
        expect(config.legendVisible, isTrue);
      });
    });

    group('validation', () {
      test('rejects empty id', () {
        expect(
          () => SeriesConfig(id: ''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejects negative stroke width', () {
        expect(
          () => SeriesConfig(
            id: 'series-1',
            strokeWidth: -1.0,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejects invalid fill opacity', () {
        expect(
          () => SeriesConfig(
            id: 'series-1',
            fillOpacity: 1.5,
          ),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => SeriesConfig(
            id: 'series-1',
            fillOpacity: -0.1,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejects negative marker size', () {
        expect(
          () => SeriesConfig(
            id: 'series-1',
            markerSize: -2.0,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('validates color format', () {
        // Valid hex colors should work
        final validConfig = SeriesConfig(
          id: 'series-1',
          color: '#FF5733',
          dataColumn: 'value',
        );
        expect(validConfig.color, equals('#FF5733'));

        // Invalid color format should fail
        expect(
          () => SeriesConfig(
            id: 'series-1',
            color: 'not-a-color',
            dataColumn: 'value',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('JSON serialization', () {
      test('toJson converts all fields correctly', () {
        final config = SeriesConfig(
          id: 'series-1',
          name: 'Power',
          dataColumn: 'power',
          dataId: 'data-123',
          color: '#FF5733',
          strokeWidth: 3.0,
          strokeDash: [5.0, 2.0],
          fillOpacity: 0.2,
          markerStyle: MarkerStyle.circle,
          markerSize: 5.0,
          interpolation: Interpolation.bezier,
          showPoints: true,
          yAxisId: 'y-1',
          unit: 'W',
          visible: true,
          legendVisible: false,
        );

        final json = config.toJson();

        expect(json['id'], equals('series-1'));
        expect(json['name'], equals('Power'));
        expect(json['dataColumn'], equals('power'));
        expect(json['dataId'], equals('data-123'));
        expect(json['color'], equals('#FF5733'));
        expect(json['strokeWidth'], equals(3.0));
        expect(json['strokeDash'], equals([5.0, 2.0]));
        expect(json['fillOpacity'], equals(0.2));
        expect(json['markerStyle'], equals('circle'));
        expect(json['markerSize'], equals(5.0));
        expect(json['interpolation'], equals('bezier'));
        expect(json['showPoints'], isTrue);
        expect(json['yAxisId'], equals('y-1'));
        expect(json['unit'], equals('W'));
        expect(json['visible'], isTrue);
        expect(json['legendVisible'], isFalse);
      });

      test('toJson handles null optional fields', () {
        final config = SeriesConfig(id: 'series-1', dataColumn: 'value');
        final json = config.toJson();

        expect(json['id'], equals('series-1'));
        expect(json.containsKey('name'), isFalse);
        expect(json['dataColumn'], equals('value'));
        expect(json.containsKey('dataId'), isFalse);
      });

      test('fromJson reconstructs instance correctly', () {
        final json = {
          'id': 'series-1',
          'name': 'Heart Rate',
          'dataColumn': 'hr',
          'color': '#00FF00',
          'strokeWidth': 2.5,
          'markerStyle': 'square',
          'interpolation': 'monotone',
          'yAxisId': 'y-2',
          'unit': 'bpm',
        };

        final config = SeriesConfig.fromJson(json);

        expect(config.id, equals('series-1'));
        expect(config.name, equals('Heart Rate'));
        expect(config.dataColumn, equals('hr'));
        expect(config.color, equals('#00FF00'));
        expect(config.strokeWidth, equals(2.5));
        expect(config.markerStyle, equals(MarkerStyle.square));
        expect(config.interpolation, equals(Interpolation.monotone));
        expect(config.yAxisId, equals('y-2'));
        expect(config.unit, equals('bpm'));
      });

      test('JSON round-trip preserves all values', () {
        final original = SeriesConfig(
          id: 'series-1',
          name: 'Cadence',
          dataColumn: 'cadence',
          dataId: 'data-456',
          color: '#0000FF',
          strokeWidth: 1.5,
          strokeDash: [3.0, 3.0],
          fillOpacity: 0.15,
          markerStyle: MarkerStyle.triangle,
          markerSize: 4.5,
          interpolation: Interpolation.stepped,
          showPoints: false,
          yAxisId: 'y-3',
          unit: 'rpm',
          visible: false,
          legendVisible: true,
        );

        final json = original.toJson();
        final reconstructed = SeriesConfig.fromJson(json);

        expect(reconstructed.id, equals(original.id));
        expect(reconstructed.name, equals(original.name));
        expect(reconstructed.dataColumn, equals(original.dataColumn));
        expect(reconstructed.dataId, equals(original.dataId));
        expect(reconstructed.color, equals(original.color));
        expect(reconstructed.strokeWidth, equals(original.strokeWidth));
        expect(reconstructed.strokeDash, equals(original.strokeDash));
        expect(reconstructed.fillOpacity, equals(original.fillOpacity));
        expect(reconstructed.markerStyle, equals(original.markerStyle));
        expect(reconstructed.markerSize, equals(original.markerSize));
        expect(reconstructed.interpolation, equals(original.interpolation));
        expect(reconstructed.showPoints, equals(original.showPoints));
        expect(reconstructed.yAxisId, equals(original.yAxisId));
        expect(reconstructed.unit, equals(original.unit));
        expect(reconstructed.visible, equals(original.visible));
        expect(reconstructed.legendVisible, equals(original.legendVisible));
      });
    });

    group('data binding', () {
      test('validates mutually exclusive data sources', () {
        // Can't have both dataColumn and explicit data
        expect(
          () => SeriesConfig(
            id: 'series-1',
            dataColumn: 'power',
            data: [
              {'x': 0, 'y': 100}
            ],
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('requires either dataColumn or data', () {
        // Neither dataColumn nor data provided
        expect(
          () => SeriesConfig(id: 'series-1'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('validates dataId requires dataColumn', () {
        // dataId without dataColumn should fail
        expect(
          () => SeriesConfig(
            id: 'series-1',
            dataId: 'data-123',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('axis binding', () {
      test('allows undefined yAxisId for default axis', () {
        final config = SeriesConfig(
          id: 'series-1',
          dataColumn: 'power',
        );

        expect(config.yAxisId, isNull);
      });

      test('validates yAxisId format', () {
        final validConfig = SeriesConfig(
          id: 'series-1',
          dataColumn: 'power',
          yAxisId: 'y-axis-1',
        );
        expect(validConfig.yAxisId, equals('y-axis-1'));

        // Empty yAxisId should fail
        expect(
          () => SeriesConfig(
            id: 'series-1',
            dataColumn: 'power',
            yAxisId: '',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
