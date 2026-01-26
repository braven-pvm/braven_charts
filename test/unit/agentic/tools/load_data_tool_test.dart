// @orchestra-task: 21
@Tags(['tdd-red'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/agentic/services/url_fetcher.dart';
import 'package:braven_charts/src/agentic/tools/load_data_tool.dart';

void main() {
  group('LoadDataTool', () {
    late LoadDataTool tool;

    setUp(() {
      tool = LoadDataTool();
    });

    group('constructor and metadata', () {
      test('should have correct tool name', () {
        expect(tool.name, equals('load_data'));
      });

      test('should have description', () {
        expect(tool.description, isNotEmpty);
        expect(
          tool.description,
          contains('Load data from a file attachment, URL, or inline content'),
        );
      });

      test('should have input schema', () {
        expect(tool.inputSchema, isNotNull);
        expect(tool.inputSchema['type'], equals('object'));
        expect(tool.inputSchema['required'], contains('source'));
      });

      test('should have output schema', () {
        expect(tool.outputSchema, isNotNull);
        expect(tool.outputSchema['type'], equals('object'));
        expect(
          tool.outputSchema['properties'],
          containsPair('data_id', anything),
        );
      });
    });

    group('file source loading', () {
      test('should load CSV file from file_id', () async {
        final input = {
          'source': {
            'type': 'file',
            'file_id': 'test/fixtures/test_data.csv',
            'format': 'csv',
          }
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isNotNull);
        expect(result['data_id'], isA<String>());
        expect(result['row_count'], isA<int>());
        expect(result['column_count'], isA<int>());
        expect(result['columns'], isA<List>());
      });

      test('should load FIT file from file_id', () async {
        final input = {
          'source': {
            'type': 'file',
            'file_id': 'test/fixtures/test_cycling.fit',
            'format': 'fit',
          }
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isNotNull);
        expect(result['row_count'], greaterThan(0));
        expect(result['time_range'], isNotNull);
      });

      test('should auto-detect format when not specified', () async {
        final input = {
          'source': {
            'type': 'file',
            'file_id': 'test/fixtures/test_data.csv',
            'format': 'auto',
          }
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isNotNull);
        expect(result['columns'], isNotEmpty);
      });
    });

    group('url data source', () {
      test('should load URL data using UrlFetcherService', () async {
        final input = {
          'source': {
            'type': 'url',
            'url': 'https://example.com/data.csv',
            'format': 'csv',
          }
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isNotNull);
        expect(result['row_count'], greaterThan(0));
        expect(result['columns'], isNotEmpty);
      });

      test('should propagate URL fetch errors with context', () async {
        final input = {
          'source': {
            'type': 'url',
            'url': 'https://example.com/unreachable.csv',
            'format': 'csv',
          }
        };

        expect(
          () => tool.execute(input),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('inline source loading', () {
      test('should load inline CSV content', () async {
        final input = {
          'source': {
            'type': 'inline',
            'content': 'timestamp,power,heart_rate\n0,200,150\n1,220,155',
            'format': 'csv',
          }
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isNotNull);
        expect(result['row_count'], equals(2));
        expect(result['columns'], containsAll(['timestamp', 'power', 'heart_rate']));
      });

      test('should load inline JSON content', () async {
        final input = {
          'source': {
            'type': 'inline',
            'content': '[{"time": 0, "watts": 200}, {"time": 1, "watts": 220}]',
            'format': 'json',
          }
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isNotNull);
        expect(result['row_count'], equals(2));
        expect(result['columns'], containsAll(['time', 'watts']));
      });
    });

    group('inline data source', () {
      test('should parse inline JSON array of numbers', () async {
        final input = {
          'source': {
            'type': 'inline',
            'content': '[1,2,3,4,5]',
            'format': 'json',
          }
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isNotNull);
        expect(result['row_count'], equals(5));
        expect(result['column_count'], equals(1));
      });

      test('should parse inline CSV string data', () async {
        final input = {
          'source': {
            'type': 'inline',
            'content': 'x,y\n1,2\n3,4',
            'format': 'csv',
          }
        };

        final result = await tool.execute(input);

        expect(result['data_id'], isNotNull);
        expect(result['row_count'], equals(2));
        expect(result['columns'], isA<List<Map<String, dynamic>>>());
        expect(
          result['columns'],
          containsAll([
            containsPair('name', 'x'),
            containsPair('name', 'y'),
          ]),
        );
      });

      test('should throw on malformed inline data', () async {
        final input = {
          'source': {
            'type': 'inline',
            'content': '{not-json}',
            'format': 'json',
          }
        };

        expect(
          () => tool.execute(input),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('time range extraction', () {
      test('should extract time_range from time-series data', () async {
        final input = {
          'source': {
            'type': 'inline',
            'content': 'timestamp,value\n2026-01-25T10:00:00Z,100\n2026-01-25T10:01:00Z,110',
            'format': 'csv',
          }
        };

        final result = await tool.execute(input);

        expect(result['time_range'], isNotNull);
        expect(result['time_range']['start'], isA<String>());
        expect(result['time_range']['end'], isA<String>());
        expect(result['time_range']['duration_seconds'], isA<int>());
      });

      test('should return null time_range for non-temporal data', () async {
        final input = {
          'source': {
            'type': 'inline',
            'content': 'category,value\nA,10\nB,20',
            'format': 'csv',
          }
        };

        final result = await tool.execute(input);

        expect(result['time_range'], isNull);
      });
    });

    group('error handling', () {
      test('should throw on missing source parameter', () async {
        final input = <String, dynamic>{};

        expect(
          () => tool.execute(input),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw on invalid source type', () async {
        final input = {
          'source': {
            'type': 'invalid',
          }
        };

        expect(
          () => tool.execute(input),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw on missing file_id for file source', () async {
        final input = {
          'source': {
            'type': 'file',
            'format': 'csv',
          }
        };

        expect(
          () => tool.execute(input),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw on missing url for URL source', () async {
        final input = {
          'source': {
            'type': 'url',
            'format': 'csv',
          }
        };

        expect(
          () => tool.execute(input),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw on missing content for inline source', () async {
        final input = {
          'source': {
            'type': 'inline',
            'format': 'csv',
          }
        };

        expect(
          () => tool.execute(input),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw on unsupported format', () async {
        final input = {
          'source': {
            'type': 'inline',
            'content': 'data',
            'format': 'unsupported',
          }
        };

        expect(
          () => tool.execute(input),
          throwsA(isA<UnsupportedError>()),
        );
      });
    });

    group('data_id generation', () {
      test('should generate unique data_id for each load', () async {
        final input = {
          'source': {
            'type': 'inline',
            'content': 'x,y\n1,2',
            'format': 'csv',
          }
        };

        final result1 = await tool.execute(input);
        final result2 = await tool.execute(input);

        expect(result1['data_id'], isNot(equals(result2['data_id'])));
      });

      test('data_id should be valid UUID format', () async {
        final input = {
          'source': {
            'type': 'inline',
            'content': 'x,y\n1,2',
            'format': 'csv',
          }
        };

        final result = await tool.execute(input);
        final dataId = result['data_id'] as String;

        // UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
        final uuidPattern = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        );
        expect(dataId, matches(uuidPattern));
      });
    });
  });
}
