import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/agentic/tools/process_data_tool.dart';
import 'package:braven_charts/src/agentic/tools/load_data_tool.dart';

void main() {
  group('ProcessDataTool', () {
    late ProcessDataTool tool;
    late LoadDataTool loadTool;
    late String testDataId;
    late String temporalDataId;
    late String testData100Rows;
    late String testData3600Seconds;

    setUp(() async {
      tool = ProcessDataTool();
      loadTool = LoadDataTool();

      // Load basic test data
      final basicResult = await loadTool.execute({
        'source': {
          'type': 'inline',
          'content': 'timestamp,power,heart_rate\n'
              '2026-01-25T10:00:00Z,150,120\n'
              '2026-01-25T10:00:01Z,155,122\n'
              '2026-01-25T10:00:02Z,160,125',
          'format': 'csv',
        }
      });
      testDataId = basicResult['data_id'] as String;

      // Load temporal data for time-based operations
      final temporalResult = await loadTool.execute({
        'source': {
          'type': 'inline',
          'content': 'timestamp,power\n'
              '2026-01-25T10:00:00Z,150\n'
              '2026-01-25T10:00:30Z,160\n'
              '2026-01-25T10:01:00Z,155',
          'format': 'csv',
        }
      });
      temporalDataId = temporalResult['data_id'] as String;

      // Create 100-row dataset
      final rows100 = StringBuffer('timestamp,value\n');
      for (var i = 0; i < 100; i++) {
        rows100.write('2026-01-25T10:00:${i.toString().padLeft(2, '0')}Z,$i\n');
      }
      final result100 = await loadTool.execute({
        'source': {
          'type': 'inline',
          'content': rows100.toString(),
          'format': 'csv'
        }
      });
      testData100Rows = result100['data_id'] as String;

      // Create 3600-second (1 hour) dataset
      final rows3600 = StringBuffer('timestamp,power\n');
      final startTime = DateTime.parse('2026-01-25T10:00:00Z');
      for (var i = 0; i < 3600; i++) {
        final time = startTime.add(Duration(seconds: i));
        rows3600.write('${time.toIso8601String()},${150 + (i % 50)}\n');
      }
      final result3600 = await loadTool.execute({
        'source': {
          'type': 'inline',
          'content': rows3600.toString(),
          'format': 'csv'
        }
      });
      testData3600Seconds = result3600['data_id'] as String;
    });

    group('constructor and metadata', () {
      test('should have correct tool name', () {
        expect(tool.name, equals('process_data'));
      });

      test('should have description', () {
        expect(tool.description, isNotEmpty);
        expect(
          tool.description,
          contains('Apply transformations to data'),
        );
      });

      test('should have input schema', () {
        expect(tool.inputSchema, isNotNull);
        expect(tool.inputSchema['required'],
            containsAll(['data_id', 'operations']));
      });

      test('should have output schema', () {
        expect(tool.outputSchema, isNotNull);
        expect(
            tool.outputSchema['properties'], containsPair('data_id', anything));
        expect(tool.outputSchema['properties'],
            containsPair('row_count', anything));
      });
    });

    group('select_columns operation', () {
      test('should select specified columns', () async {
        final input = {
          'data_id': testDataId,
          'operations': [
            {
              'type': 'select_columns',
              'columns': ['power', 'heart_rate'],
            }
          ],
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isA<String>());
        expect(result['data_id'], isNot(equals(input['data_id'])));
        expect(result['row_count'], isA<int>());
      });

      test('should maintain row count after column selection', () async {
        final input = {
          'data_id': testData100Rows,
          'operations': [
            {
              'type': 'select_columns',
              'columns': ['timestamp', 'value'],
            }
          ],
        };

        final result = await tool.execute(input);

        expect(result['row_count'], equals(100));
      });
    });

    group('rolling_window operation', () {
      test('should apply rolling mean', () async {
        final input = {
          'data_id': testDataId,
          'operations': [
            {
              'type': 'rolling_window',
              'column': 'power',
              'window_seconds': 30,
              'reducer': 'mean',
            }
          ],
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isA<String>());
        expect(result['row_count'], isA<int>());
      });

      test('should apply rolling max', () async {
        final input = {
          'data_id': testDataId,
          'operations': [
            {
              'type': 'rolling_window',
              'column': 'heart_rate',
              'window_seconds': 60,
              'reducer': 'max',
            }
          ],
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isNotNull);
      });

      test('should apply rolling min', () async {
        final input = {
          'data_id': testDataId,
          'operations': [
            {
              'type': 'rolling_window',
              'column': 'power',
              'window_seconds': 20,
              'reducer': 'min',
            }
          ],
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isNotNull);
      });

      test('should apply rolling sum', () async {
        final input = {
          'data_id': testDataId,
          'operations': [
            {
              'type': 'rolling_window',
              'column': 'power',
              'window_seconds': 10,
              'reducer': 'sum',
            }
          ],
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isNotNull);
      });
    });

    group('fixed_window operation', () {
      test('should apply fixed window mean', () async {
        final input = {
          'data_id': testData3600Seconds,
          'operations': [
            {
              'type': 'fixed_window',
              'column': 'power',
              'window_seconds': 300,
              'reducer': 'mean',
            }
          ],
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isNotNull);
        expect(result['row_count'], lessThan(1000)); // Should reduce rows
      });

      test('should reduce row count with fixed windows', () async {
        final input = {
          'data_id': testData3600Seconds,
          'operations': [
            {
              'type': 'fixed_window',
              'column': 'power',
              'window_seconds': 60,
              'reducer': 'mean',
            }
          ],
        };

        final result = await tool.execute(input);

        // 3600 seconds / 60 second windows = 60 rows
        expect(result['row_count'], equals(60));
      });
    });

    group('resample operation', () {
      test('should resample with interpolation', () async {
        final input = {
          'data_id': testData3600Seconds,
          'operations': [
            {
              'type': 'resample',
              'interval_seconds': 5,
              'method': 'interpolate',
            }
          ],
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isNotNull);
        expect(result['row_count'], greaterThan(0));
      });

      test('should resample with last method', () async {
        final input = {
          'data_id': testData3600Seconds,
          'operations': [
            {
              'type': 'resample',
              'interval_seconds': 10,
              'method': 'last',
            }
          ],
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isNotNull);
      });

      test('should resample with mean method', () async {
        final input = {
          'data_id': testData3600Seconds,
          'operations': [
            {
              'type': 'resample',
              'interval_seconds': 2,
              'method': 'mean',
            }
          ],
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isNotNull);
      });
    });

    group('normalize operation', () {
      test('should normalize with min_max method', () async {
        final input = {
          'data_id': testData3600Seconds,
          'operations': [
            {
              'type': 'normalize',
              'column': 'power',
              'method': 'min_max',
            }
          ],
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isNotNull);
        // Normalized values should be between 0 and 1
      });

      test('should normalize with z_score method', () async {
        final input = {
          'data_id': testData3600Seconds,
          'operations': [
            {
              'type': 'normalize',
              'column': 'power',
              'method': 'z_score',
            }
          ],
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isNotNull);
        // Z-score normalized values have mean 0, stddev 1
      });
    });

    group('clip operation', () {
      test('should clip values to min/max range', () async {
        final input = {
          'data_id': testData3600Seconds,
          'operations': [
            {
              'type': 'clip',
              'column': 'power',
              'min': 0,
              'max': 400,
            }
          ],
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isNotNull);
      });

      test('should clip with only min value', () async {
        final input = {
          'data_id': testData3600Seconds,
          'operations': [
            {
              'type': 'clip',
              'column': 'power',
              'min': 60,
            }
          ],
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isNotNull);
      });

      test('should clip with only max value', () async {
        final input = {
          'data_id': testData3600Seconds,
          'operations': [
            {
              'type': 'clip',
              'column': 'power',
              'max': 500,
            }
          ],
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isNotNull);
      });
    });

    group('multiple operations chaining', () {
      test('should apply multiple operations in sequence', () async {
        final input = {
          'data_id': testData3600Seconds,
          'operations': [
            {
              'type': 'select_columns',
              'columns': ['timestamp', 'power'],
            },
            {
              'type': 'rolling_window',
              'column': 'power',
              'window_seconds': 30,
              'reducer': 'mean',
            },
            {
              'type': 'normalize',
              'column': 'power',
              'method': 'min_max',
            },
          ],
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isNotNull);
        expect(result['row_count'], isA<int>());
      });

      test('should chain resampling and rolling window', () async {
        final input = {
          'data_id': testData3600Seconds,
          'operations': [
            {
              'type': 'resample',
              'interval_seconds': 1,
              'method': 'interpolate',
            },
            {
              'type': 'rolling_window',
              'column': 'power',
              'window_seconds': 30,
              'reducer': 'mean',
            },
          ],
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isNotNull);
      });
    });

    group('error handling', () {
      test('should throw on missing data_id', () async {
        final input = {
          'operations': [
            {
              'type': 'select_columns',
              'columns': ['power']
            },
          ],
        };

        expect(
          () => tool.execute(input),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw on missing operations', () async {
        final input = {
          'data_id': testDataId,
        };

        expect(
          () => tool.execute(input),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw on empty operations array', () async {
        final input = {
          'data_id': testDataId,
          'operations': [],
        };

        expect(
          () => tool.execute(input),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw on invalid operation type', () async {
        final input = {
          'data_id': testDataId,
          'operations': [
            {'type': 'invalid_operation'},
          ],
        };

        expect(
          () => tool.execute(input),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw on non-existent data_id', () async {
        final input = {
          'data_id': 'non-existent-uuid',
          'operations': [
            {
              'type': 'select_columns',
              'columns': ['power']
            },
          ],
        };

        expect(
          () => tool.execute(input),
          throwsA(isA<StateError>()),
        );
      });

      test('should throw on non-existent column in operation', () async {
        final input = {
          'data_id': testDataId,
          'operations': [
            {
              'type': 'rolling_window',
              'column': 'non_existent_column',
              'window_seconds': 30,
              'reducer': 'mean',
            },
          ],
        };

        expect(
          () => tool.execute(input),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('data immutability', () {
      test('should not modify original data', () async {
        // Use existing loaded data
        final originalDataId = testData3600Seconds;
        final input = {
          'data_id': originalDataId,
          'operations': [
            {
              'type': 'rolling_window',
              'column': 'power',
              'window_seconds': 30,
              'reducer': 'mean',
            },
          ],
        };

        final result = await tool.execute(input);

        // New data_id should be different from original
        expect(result['data_id'], isNot(equals(originalDataId)));
      });

      test('should allow reusing original data after processing', () async {
        // Use existing loaded data
        final originalDataId = testData3600Seconds;

        // First processing
        final input1 = {
          'data_id': originalDataId,
          'operations': [
            {
              'type': 'select_columns',
              'columns': ['power']
            },
          ],
        };
        await tool.execute(input1);

        // Second processing from same original
        final input2 = {
          'data_id': originalDataId,
          'operations': [
            {
              'type': 'select_columns',
              'columns': ['timestamp']
            },
          ],
        };
        final result2 = await tool.execute(input2);

        expect(result2['data_id'], isNotNull);
      });
    });
  });
}
