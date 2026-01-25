// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

// @orchestra-task: 2

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/agentic/models/loaded_data.dart';

@Tags(['tdd-red'])
void main() {
  group('DataSourceType', () {
    test('has all required enum values', () {
      expect(DataSourceType.values.contains(DataSourceType.file), isTrue);
      expect(DataSourceType.values.contains(DataSourceType.url), isTrue);
      expect(DataSourceType.values.contains(DataSourceType.inline), isTrue);
    });
  });

  group('ColumnType', () {
    test('has all required enum values', () {
      expect(ColumnType.values.contains(ColumnType.number), isTrue);
      expect(ColumnType.values.contains(ColumnType.string), isTrue);
      expect(ColumnType.values.contains(ColumnType.datetime), isTrue);
      expect(ColumnType.values.contains(ColumnType.boolean), isTrue);
    });
  });

  group('ColumnDescriptor', () {
    group('constructor', () {
      test('creates instance with valid parameters', () {
        final descriptor = ColumnDescriptor(
          name: 'power',
          type: ColumnType.number,
          nullable: false,
          sampleValues: [250, 260, 270],
        );

        expect(descriptor.name, equals('power'));
        expect(descriptor.type, equals(ColumnType.number));
        expect(descriptor.nullable, isFalse);
        expect(descriptor.sampleValues.length, equals(3));
        expect(descriptor.stats, isNull);
      });

      test('creates instance with statistics', () {
        final stats = ColumnStats(
          min: 100.0,
          max: 400.0,
          mean: 250.0,
          nullCount: 0,
        );

        final descriptor = ColumnDescriptor(
          name: 'heart_rate',
          type: ColumnType.number,
          nullable: false,
          sampleValues: [120, 140, 160],
          stats: stats,
        );

        expect(descriptor.stats, isNotNull);
        expect(descriptor.stats?.min, equals(100.0));
        expect(descriptor.stats?.max, equals(400.0));
        expect(descriptor.stats?.mean, equals(250.0));
      });

      test('creates nullable column', () {
        final descriptor = ColumnDescriptor(
          name: 'optional_field',
          type: ColumnType.string,
          nullable: true,
          sampleValues: ['value1', null, 'value2'],
        );

        expect(descriptor.nullable, isTrue);
        expect(descriptor.sampleValues.contains(null), isTrue);
      });

      test('throws assertion error when name is empty', () {
        expect(
          () => ColumnDescriptor(
            name: '',
            type: ColumnType.number,
            nullable: false,
            sampleValues: [],
          ),
          throwsAssertionError,
        );
      });
    });

    group('JSON serialization', () {
      test('toJson converts to map correctly', () {
        final descriptor = ColumnDescriptor(
          name: 'cadence',
          type: ColumnType.number,
          nullable: false,
          sampleValues: [85, 90, 95],
        );

        final json = descriptor.toJson();

        expect(json['name'], equals('cadence'));
        expect(json['type'], equals('number'));
        expect(json['nullable'], isFalse);
        expect(json['sampleValues'], isA<List>());
      });

      test('fromJson creates instance from map', () {
        final json = {
          'name': 'distance',
          'type': 'number',
          'nullable': false,
          'sampleValues': [10.5, 20.3, 30.1],
        };

        final descriptor = ColumnDescriptor.fromJson(json);

        expect(descriptor.name, equals('distance'));
        expect(descriptor.type, equals(ColumnType.number));
        expect(descriptor.nullable, isFalse);
      });

      test('JSON round-trip preserves data', () {
        final stats = ColumnStats(
          min: 0.0,
          max: 100.0,
          mean: 50.0,
          nullCount: 5,
        );

        final original = ColumnDescriptor(
          name: 'temperature',
          type: ColumnType.number,
          nullable: true,
          sampleValues: [20.5, 21.0, 19.8],
          stats: stats,
        );

        final json = original.toJson();
        final restored = ColumnDescriptor.fromJson(json);

        expect(restored.name, equals(original.name));
        expect(restored.type, equals(original.type));
        expect(restored.nullable, equals(original.nullable));
        expect(restored.stats?.min, equals(original.stats?.min));
      });
    });

    group('equality', () {
      test('equal descriptors have same hash code', () {
        final desc1 = ColumnDescriptor(
          name: 'power',
          type: ColumnType.number,
          nullable: false,
          sampleValues: [250],
        );

        final desc2 = ColumnDescriptor(
          name: 'power',
          type: ColumnType.number,
          nullable: false,
          sampleValues: [250],
        );

        expect(desc1, equals(desc2));
        expect(desc1.hashCode, equals(desc2.hashCode));
      });
    });
  });

  group('ColumnStats', () {
    test('creates instance with statistics', () {
      final stats = ColumnStats(
        min: 0.0,
        max: 500.0,
        mean: 250.0,
        nullCount: 10,
      );

      expect(stats.min, equals(0.0));
      expect(stats.max, equals(500.0));
      expect(stats.mean, equals(250.0));
      expect(stats.nullCount, equals(10));
    });

    test('JSON round-trip preserves data', () {
      final original = ColumnStats(
        min: 10.5,
        max: 99.9,
        mean: 55.2,
        nullCount: 3,
      );

      final json = original.toJson();
      final restored = ColumnStats.fromJson(json);

      expect(restored.min, equals(original.min));
      expect(restored.max, equals(original.max));
      expect(restored.mean, equals(original.mean));
      expect(restored.nullCount, equals(original.nullCount));
    });
  });

  group('TimeRange', () {
    test('creates instance with valid dates', () {
      final timeRange = TimeRange(
        start: DateTime(2026, 1, 25, 10, 0),
        end: DateTime(2026, 1, 25, 11, 0),
        durationSeconds: 3600,
      );

      expect(timeRange.start, equals(DateTime(2026, 1, 25, 10, 0)));
      expect(timeRange.end, equals(DateTime(2026, 1, 25, 11, 0)));
      expect(timeRange.durationSeconds, equals(3600));
    });

    test('throws assertion error when duration is negative', () {
      expect(
        () => TimeRange(
          start: DateTime(2026, 1, 25, 10, 0),
          end: DateTime(2026, 1, 25, 11, 0),
          durationSeconds: -100,
        ),
        throwsAssertionError,
      );
    });

    test('JSON round-trip preserves data', () {
      final original = TimeRange(
        start: DateTime(2026, 1, 25, 9, 30),
        end: DateTime(2026, 1, 25, 10, 45),
        durationSeconds: 4500,
      );

      final json = original.toJson();
      final restored = TimeRange.fromJson(json);

      expect(restored.start, equals(original.start));
      expect(restored.end, equals(original.end));
      expect(restored.durationSeconds, equals(original.durationSeconds));
    });
  });

  group('LoadedData', () {
    group('constructor', () {
      test('creates instance from file source', () {
        final data = LoadedData(
          id: '550e8400-e29b-41d4-a716-446655440000',
          type: DataSourceType.file,
          fileName: 'workout.fit',
          fileType: 'fit',
          rowCount: 1000,
          columns: [
            ColumnDescriptor(
              name: 'power',
              type: ColumnType.number,
              nullable: false,
              sampleValues: [250],
            ),
          ],
          data: [
            {'power': 250, 'timestamp': '2026-01-25T10:00:00Z'},
          ],
          loadedAt: DateTime(2026, 1, 25),
        );

        expect(data.id, equals('550e8400-e29b-41d4-a716-446655440000'));
        expect(data.type, equals(DataSourceType.file));
        expect(data.fileName, equals('workout.fit'));
        expect(data.fileType, equals('fit'));
        expect(data.rowCount, equals(1000));
        expect(data.columns.length, equals(1));
        expect(data.data.length, equals(1));
      });

      test('creates instance with time range for time-series data', () {
        final timeRange = TimeRange(
          start: DateTime(2026, 1, 25, 10, 0),
          end: DateTime(2026, 1, 25, 11, 0),
          durationSeconds: 3600,
        );

        final data = LoadedData(
          id: '550e8400-e29b-41d4-a716-446655440001',
          type: DataSourceType.file,
          fileName: 'training.csv',
          fileType: 'csv',
          rowCount: 3600,
          columns: [],
          data: [],
          timeRange: timeRange,
          loadedAt: DateTime(2026, 1, 25),
        );

        expect(data.timeRange, isNotNull);
        expect(data.timeRange?.durationSeconds, equals(3600));
      });

      test('creates instance from URL source', () {
        final data = LoadedData(
          id: '550e8400-e29b-41d4-a716-446655440002',
          type: DataSourceType.url,
          rowCount: 500,
          columns: [],
          data: [],
          loadedAt: DateTime(2026, 1, 25),
        );

        expect(data.type, equals(DataSourceType.url));
        expect(data.fileName, isNull);
      });

      test('creates instance from inline source', () {
        final data = LoadedData(
          id: '550e8400-e29b-41d4-a716-446655440003',
          type: DataSourceType.inline,
          rowCount: 10,
          columns: [
            ColumnDescriptor(
              name: 'value',
              type: ColumnType.number,
              nullable: false,
              sampleValues: [1, 2, 3],
            ),
          ],
          data: [
            {'value': 1},
            {'value': 2},
            {'value': 3},
          ],
          loadedAt: DateTime(2026, 1, 25),
        );

        expect(data.type, equals(DataSourceType.inline));
        expect(data.data.length, equals(3));
      });

      test('throws assertion error when id is not UUID v4', () {
        expect(
          () => LoadedData(
            id: 'invalid-uuid',
            type: DataSourceType.file,
            rowCount: 100,
            columns: [],
            data: [],
            loadedAt: DateTime(2026, 1, 25),
          ),
          throwsAssertionError,
        );
      });

      test('throws assertion error when rowCount does not match data length',
          () {
        expect(
          () => LoadedData(
            id: '550e8400-e29b-41d4-a716-446655440000',
            type: DataSourceType.file,
            rowCount: 10,
            columns: [],
            data: [
              {'value': 1},
              {'value': 2},
            ], // Only 2 rows, but rowCount is 10
            loadedAt: DateTime(2026, 1, 25),
          ),
          throwsAssertionError,
        );
      });

      test('throws assertion error when columns list is empty', () {
        expect(
          () => LoadedData(
            id: '550e8400-e29b-41d4-a716-446655440000',
            type: DataSourceType.file,
            rowCount: 0,
            columns: [],
            data: [],
            loadedAt: DateTime(2026, 1, 25),
          ),
          throwsAssertionError,
        );
      });

      test('throws assertion error for fit file type without proper format',
          () {
        // FIT files must be from file source
        expect(
          () => LoadedData(
            id: '550e8400-e29b-41d4-a716-446655440000',
            type: DataSourceType.inline,
            fileType: 'fit',
            rowCount: 10,
            columns: [
              ColumnDescriptor(
                name: 'col',
                type: ColumnType.number,
                nullable: false,
                sampleValues: [1],
              ),
            ],
            data: List.filled(10, {'col': 1}),
            loadedAt: DateTime(2026, 1, 25),
          ),
          throwsAssertionError,
        );
      });
    });

    group('JSON serialization', () {
      test('toJson converts to map correctly', () {
        final data = LoadedData(
          id: '550e8400-e29b-41d4-a716-446655440000',
          type: DataSourceType.file,
          fileName: 'data.csv',
          fileType: 'csv',
          rowCount: 2,
          columns: [
            ColumnDescriptor(
              name: 'value',
              type: ColumnType.number,
              nullable: false,
              sampleValues: [10, 20],
            ),
          ],
          data: [
            {'value': 10},
            {'value': 20},
          ],
          loadedAt: DateTime(2026, 1, 25),
        );

        final json = data.toJson();

        expect(json['id'], equals('550e8400-e29b-41d4-a716-446655440000'));
        expect(json['type'], equals('file'));
        expect(json['fileName'], equals('data.csv'));
        expect(json['fileType'], equals('csv'));
        expect(json['rowCount'], equals(2));
        expect(json['columns'], isA<List>());
        expect(json['data'], isA<List>());
      });

      test('fromJson creates instance from map', () {
        final json = {
          'id': '550e8400-e29b-41d4-a716-446655440000',
          'type': 'file',
          'fileName': 'workout.tcx',
          'fileType': 'tcx',
          'rowCount': 1,
          'columns': [
            {
              'name': 'hr',
              'type': 'number',
              'nullable': false,
              'sampleValues': [140],
            },
          ],
          'data': [
            {'hr': 140},
          ],
          'loadedAt': '2026-01-25T00:00:00.000',
        };

        final data = LoadedData.fromJson(json);

        expect(data.id, equals('550e8400-e29b-41d4-a716-446655440000'));
        expect(data.type, equals(DataSourceType.file));
        expect(data.fileName, equals('workout.tcx'));
        expect(data.fileType, equals('tcx'));
        expect(data.rowCount, equals(1));
      });

      test('JSON round-trip preserves data', () {
        final timeRange = TimeRange(
          start: DateTime(2026, 1, 25, 10, 0),
          end: DateTime(2026, 1, 25, 11, 0),
          durationSeconds: 3600,
        );

        final original = LoadedData(
          id: '550e8400-e29b-41d4-a716-446655440000',
          type: DataSourceType.file,
          fileName: 'ride.fit',
          fileType: 'fit',
          rowCount: 3,
          columns: [
            ColumnDescriptor(
              name: 'power',
              type: ColumnType.number,
              nullable: false,
              sampleValues: [200, 250, 300],
            ),
          ],
          data: [
            {'power': 200},
            {'power': 250},
            {'power': 300},
          ],
          timeRange: timeRange,
          loadedAt: DateTime(2026, 1, 25, 12, 0),
        );

        final json = original.toJson();
        final restored = LoadedData.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.type, equals(original.type));
        expect(restored.fileName, equals(original.fileName));
        expect(restored.fileType, equals(original.fileType));
        expect(restored.rowCount, equals(original.rowCount));
        expect(restored.timeRange?.durationSeconds,
            equals(original.timeRange?.durationSeconds));
      });
    });

    group('validation', () {
      test('validates UUID v4 format', () {
        expect(
          () => LoadedData(
            id: '550e8400-e29b-41d4-a716-446655440000',
            type: DataSourceType.file,
            rowCount: 1,
            columns: [
              ColumnDescriptor(
                name: 'col',
                type: ColumnType.number,
                nullable: false,
                sampleValues: [1],
              ),
            ],
            data: [
              {'col': 1},
            ],
            loadedAt: DateTime(2026, 1, 25),
          ),
          returnsNormally,
        );

        expect(
          () => LoadedData(
            id: 'not-a-uuid',
            type: DataSourceType.file,
            rowCount: 1,
            columns: [
              ColumnDescriptor(
                name: 'col',
                type: ColumnType.number,
                nullable: false,
                sampleValues: [1],
              ),
            ],
            data: [
              {'col': 1},
            ],
            loadedAt: DateTime(2026, 1, 25),
          ),
          throwsAssertionError,
        );
      });

      test('validates supported file types', () {
        // FIT file is valid
        expect(
          () => LoadedData(
            id: '550e8400-e29b-41d4-a716-446655440000',
            type: DataSourceType.file,
            fileType: 'fit',
            rowCount: 1,
            columns: [
              ColumnDescriptor(
                name: 'col',
                type: ColumnType.number,
                nullable: false,
                sampleValues: [1],
              ),
            ],
            data: [
              {'col': 1},
            ],
            loadedAt: DateTime(2026, 1, 25),
          ),
          returnsNormally,
        );

        // CSV file is valid
        expect(
          () => LoadedData(
            id: '550e8400-e29b-41d4-a716-446655440001',
            type: DataSourceType.file,
            fileType: 'csv',
            rowCount: 1,
            columns: [
              ColumnDescriptor(
                name: 'col',
                type: ColumnType.number,
                nullable: false,
                sampleValues: [1],
              ),
            ],
            data: [
              {'col': 1},
            ],
            loadedAt: DateTime(2026, 1, 25),
          ),
          returnsNormally,
        );

        // TCX file is valid
        expect(
          () => LoadedData(
            id: '550e8400-e29b-41d4-a716-446655440002',
            type: DataSourceType.file,
            fileType: 'tcx',
            rowCount: 1,
            columns: [
              ColumnDescriptor(
                name: 'col',
                type: ColumnType.number,
                nullable: false,
                sampleValues: [1],
              ),
            ],
            data: [
              {'col': 1},
            ],
            loadedAt: DateTime(2026, 1, 25),
          ),
          returnsNormally,
        );
      });
    });

    group('equality', () {
      test('equal loaded data have same hash code', () {
        final data1 = LoadedData(
          id: '550e8400-e29b-41d4-a716-446655440000',
          type: DataSourceType.file,
          rowCount: 1,
          columns: [
            ColumnDescriptor(
              name: 'col',
              type: ColumnType.number,
              nullable: false,
              sampleValues: [1],
            ),
          ],
          data: [
            {'col': 1},
          ],
          loadedAt: DateTime(2026, 1, 25),
        );

        final data2 = LoadedData(
          id: '550e8400-e29b-41d4-a716-446655440000',
          type: DataSourceType.file,
          rowCount: 1,
          columns: [
            ColumnDescriptor(
              name: 'col',
              type: ColumnType.number,
              nullable: false,
              sampleValues: [1],
            ),
          ],
          data: [
            {'col': 1},
          ],
          loadedAt: DateTime(2026, 1, 25),
        );

        expect(data1, equals(data2));
        expect(data1.hashCode, equals(data2.hashCode));
      });
    });
  });
}
