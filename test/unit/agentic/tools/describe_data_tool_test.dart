// @orchestra-task: 12
@Tags(['tdd-red'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/agentic/tools/describe_data_tool.dart';

void main() {
  group('DescribeDataTool', () {
    late DescribeDataTool tool;

    setUp(() {
      tool = DescribeDataTool();
    });

    group('constructor and metadata', () {
      test('should have correct tool name', () {
        expect(tool.name, equals('describe_data'));
      });

      test('should have description', () {
        expect(tool.description, isNotEmpty);
        expect(
          tool.description,
          contains('Analyze loaded data to discover available columns'),
        );
      });

      test('should have input schema', () {
        expect(tool.inputSchema, isNotNull);
        expect(tool.inputSchema['type'], equals('object'));
        expect(tool.inputSchema['required'], contains('data_id'));
      });

      test('should have output schema', () {
        expect(tool.outputSchema, isNotNull);
        expect(
            tool.outputSchema['properties'], containsPair('columns', anything));
        expect(tool.outputSchema['properties'],
            containsPair('row_count', anything));
      });
    });

    group('basic metadata retrieval', () {
      test('should return file_name and file_type', () async {
        final input = {
          'data_id': 'test-data-uuid-123',
        };

        final result = await tool.execute(input);

        expect(result['file_name'], isA<String>());
        expect(result['file_type'], isIn(['fit', 'csv', 'json']));
      });

      test('should return row_count', () async {
        final input = {
          'data_id': 'test-data-uuid-456',
        };

        final result = await tool.execute(input);

        expect(result['row_count'], isA<int>());
        expect(result['row_count'], greaterThanOrEqualTo(0));
      });

      test('should return columns array', () async {
        final input = {
          'data_id': 'test-data-uuid-789',
        };

        final result = await tool.execute(input);

        expect(result['columns'], isA<List>());
        expect(result['columns'], isNotEmpty);
      });
    });

    group('column metadata', () {
      test('should provide column name', () async {
        final input = {
          'data_id': 'test-data-with-columns',
        };

        final result = await tool.execute(input);
        final columns = result['columns'] as List;
        final firstColumn = columns.first as Map<String, dynamic>;

        expect(firstColumn['name'], isA<String>());
        expect(firstColumn['name'], isNotEmpty);
      });

      test('should provide column type', () async {
        final input = {
          'data_id': 'test-data-with-types',
        };

        final result = await tool.execute(input);
        final columns = result['columns'] as List;
        final firstColumn = columns.first as Map<String, dynamic>;

        expect(firstColumn['type'], isA<String>());
        expect(
          firstColumn['type'],
          isIn(['number', 'string', 'datetime', 'boolean']),
        );
      });

      test('should indicate if column is nullable', () async {
        final input = {
          'data_id': 'test-data-nullable',
        };

        final result = await tool.execute(input);
        final columns = result['columns'] as List;
        final firstColumn = columns.first as Map<String, dynamic>;

        expect(firstColumn['nullable'], isA<bool>());
      });

      test('should provide sample_values', () async {
        final input = {
          'data_id': 'test-data-samples',
        };

        final result = await tool.execute(input);
        final columns = result['columns'] as List;
        final firstColumn = columns.first as Map<String, dynamic>;

        expect(firstColumn['sample_values'], isA<List>());
        expect(firstColumn['sample_values'], isNotEmpty);
      });
    });

    group('numeric column statistics', () {
      test('should provide min/max/mean for numeric columns', () async {
        final input = {
          'data_id': 'test-numeric-data',
        };

        final result = await tool.execute(input);
        final columns = result['columns'] as List;
        final numericColumn = columns.firstWhere(
          (col) => (col as Map)['type'] == 'number',
        ) as Map<String, dynamic>;

        expect(numericColumn['stats'], isNotNull);
        expect(numericColumn['stats']['min'], isA<num>());
        expect(numericColumn['stats']['max'], isA<num>());
        expect(numericColumn['stats']['mean'], isA<num>());
      });

      test('should provide null_count for all columns', () async {
        final input = {
          'data_id': 'test-nulls-data',
        };

        final result = await tool.execute(input);
        final columns = result['columns'] as List;
        final firstColumn = columns.first as Map<String, dynamic>;

        expect(firstColumn['stats']['null_count'], isA<int>());
        expect(firstColumn['stats']['null_count'], greaterThanOrEqualTo(0));
      });

      test('should not provide min/max/mean for non-numeric columns', () async {
        final input = {
          'data_id': 'test-string-data',
        };

        final result = await tool.execute(input);
        final columns = result['columns'] as List;
        final stringColumn = columns.firstWhere(
          (col) => (col as Map)['type'] == 'string',
        ) as Map<String, dynamic>;

        expect(stringColumn['stats']['min'], isNull);
        expect(stringColumn['stats']['max'], isNull);
        expect(stringColumn['stats']['mean'], isNull);
      });
    });

    group('time range extraction', () {
      test('should provide time_range for temporal data', () async {
        final input = {
          'data_id': 'test-temporal-data',
        };

        final result = await tool.execute(input);

        expect(result['time_range'], isNotNull);
        expect(result['time_range']['start'], isA<String>());
        expect(result['time_range']['end'], isA<String>());
        expect(result['time_range']['duration_seconds'], isA<int>());
      });

      test('should return null time_range for non-temporal data', () async {
        final input = {
          'data_id': 'test-non-temporal-data',
        };

        final result = await tool.execute(input);

        expect(result['time_range'], isNull);
      });

      test('time_range start should be ISO 8601 format', () async {
        final input = {
          'data_id': 'test-iso-dates',
        };

        final result = await tool.execute(input);

        if (result['time_range'] != null) {
          final start = result['time_range']['start'] as String;
          // ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ
          final isoPattern = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}');
          expect(start, matches(isoPattern));
        }
      });
    });

    group('FIT file specific metadata', () {
      test('should recognize FIT record types', () async {
        final input = {
          'data_id': 'test-fit-file',
        };

        final result = await tool.execute(input);

        expect(result['file_type'], equals('fit'));
        expect(result['columns'], isNotEmpty);
        // FIT files typically have power, heart_rate, cadence, etc.
      });

      test('should extract sport-specific columns from FIT', () async {
        final input = {
          'data_id': 'test-cycling-fit',
        };

        final result = await tool.execute(input);
        final columnNames = (result['columns'] as List)
            .map((col) => (col as Map)['name'] as String)
            .toList();

        // Common cycling metrics
        expect(
            columnNames,
            anyOf([
              contains('power'),
              contains('heart_rate'),
              contains('cadence'),
              contains('speed'),
            ]));
      });
    });

    group('CSV file specific metadata', () {
      test('should parse CSV headers as column names', () async {
        final input = {
          'data_id': 'test-csv-file',
        };

        final result = await tool.execute(input);

        expect(result['file_type'], equals('csv'));
        expect(result['columns'], isNotEmpty);
      });

      test('should infer column types from CSV values', () async {
        final input = {
          'data_id': 'test-csv-mixed-types',
        };

        final result = await tool.execute(input);
        final columns = result['columns'] as List;

        final types = columns.map((col) => (col as Map)['type']).toList();
        expect(types, containsAll(['number', 'string']));
      });
    });

    group('error handling', () {
      test('should throw on missing data_id parameter', () async {
        final input = <String, dynamic>{};

        expect(
          () => tool.execute(input),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw on invalid data_id (not found)', () async {
        final input = {
          'data_id': 'non-existent-uuid',
        };

        expect(
          () => tool.execute(input),
          throwsA(isA<StateError>()),
        );
      });

      test('should throw on empty data_id string', () async {
        final input = {
          'data_id': '',
        };

        expect(
          () => tool.execute(input),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('integration with LoadDataTool', () {
      test('should describe data loaded by LoadDataTool', () async {
        // This test assumes LoadDataTool returns a valid data_id
        // In red phase, we're just defining the expected behavior
        final loadedDataId = 'uuid-from-load-tool';

        final result = await tool.execute({'data_id': loadedDataId});

        expect(result['file_name'], isNotNull);
        expect(result['columns'], isNotEmpty);
      });
    });
  });
}
