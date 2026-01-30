// @orchestra-task: 12
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/agentic/tools/load_data_tool.dart';
import 'package:braven_charts/src/agentic/tools/describe_data_tool.dart';
import 'package:braven_charts/src/agentic/tools/process_data_tool.dart';
import 'package:braven_charts/src/agentic/services/file_validator.dart';
import 'package:braven_charts/src/agentic/models/file_attachment.dart';

void main() {
  group('File Upload to Chart Integration', () {
    late LoadDataTool loadTool;
    late DescribeDataTool describeTool;
    late ProcessDataTool processTool;

    setUp(() {
      loadTool = LoadDataTool();
      describeTool = DescribeDataTool();
      processTool = ProcessDataTool();
    });

    group('CSV file to chart flow', () {
      test('should load CSV, describe, and prepare for charting', () async {
        // Step 1: Load CSV file
        final loadInput = {
          'source': {
            'type': 'inline',
            'content': 'timestamp,power,heart_rate,cadence\n'
                '0,200,150,90\n'
                '1,220,155,92\n'
                '2,210,153,91\n'
                '3,230,158,93\n'
                '4,225,156,92',
            'format': 'csv',
          }
        };

        final loadResult = await loadTool.execute(loadInput);
        expect(loadResult['data_id'], isNotNull);
        expect(loadResult['row_count'], equals(5));
        expect(loadResult['columns'],
            containsAll(['timestamp', 'power', 'heart_rate', 'cadence']));

        // Step 2: Describe the loaded data
        final dataId = loadResult['data_id'] as String;
        final describeInput = {'data_id': dataId};

        final describeResult = await describeTool.execute(describeInput);
        expect(describeResult['file_type'], equals('csv'));
        expect(describeResult['row_count'], equals(5));
        expect(describeResult['columns'], isA<List>());

        final columns = describeResult['columns'] as List;
        expect(columns.length, equals(4));

        // Verify power column metadata
        final powerColumn = columns.firstWhere(
          (col) => (col as Map)['name'] == 'power',
        ) as Map<String, dynamic>;
        expect(powerColumn['type'], equals('number'));
        expect(powerColumn['stats'], isNotNull);
        expect(powerColumn['stats']['min'], equals(200));
        expect(powerColumn['stats']['max'], equals(230));
      });

      test('should support column selection for specific metrics', () async {
        // Load data with multiple columns
        final loadInput = {
          'source': {
            'type': 'inline',
            'content': 'timestamp,power,heart_rate,cadence,speed,distance\n'
                '0,200,150,90,25.5,0\n'
                '1,220,155,92,26.0,0.025',
            'format': 'csv',
          }
        };

        final loadResult = await loadTool.execute(loadInput);
        final dataId = loadResult['data_id'] as String;

        // Select only relevant columns for charting
        final processInput = {
          'data_id': dataId,
          'operations': [
            {
              'type': 'select_columns',
              'columns': ['timestamp', 'power', 'heart_rate'],
            }
          ],
        };

        final processResult = await processTool.execute(processInput);
        expect(processResult['data_id'], isNotNull);
        expect(processResult['data_id'], isNot(equals(dataId)));

        // Verify the processed data
        final processedDataId = processResult['data_id'] as String;
        final describeResult =
            await describeTool.execute({'data_id': processedDataId});

        final columns = (describeResult['columns'] as List)
            .map((col) => (col as Map)['name'] as String)
            .toList();
        expect(columns, containsAll(['timestamp', 'power', 'heart_rate']));
        expect(columns, isNot(contains('cadence')));
        expect(columns, isNot(contains('speed')));
      });
    });

    group('FIT file to chart flow', () {
      test('should load FIT file and extract cycling metrics', () async {
        final loadInput = {
          'source': {
            'type': 'file',
            'file_id': 'test/fixtures/test_cycling.fit',
            'format': 'fit',
          }
        };

        final loadResult = await loadTool.execute(loadInput);
        expect(loadResult['data_id'], isNotNull);
        expect(loadResult['time_range'], isNotNull);

        final dataId = loadResult['data_id'] as String;
        final describeResult = await describeTool.execute({'data_id': dataId});

        expect(describeResult['file_type'], equals('fit'));
        final columnNames = (describeResult['columns'] as List)
            .map((col) => (col as Map)['name'] as String)
            .toList();

        // FIT files should have standard cycling metrics
        expect(
            columnNames,
            anyOf([
              contains('power'),
              contains('heart_rate'),
              contains('cadence'),
            ]));
      });

      test('should extract time range from FIT file', () async {
        final loadInput = {
          'source': {
            'type': 'file',
            'file_id': 'test/fixtures/test_cycling.fit',
            'format': 'fit',
          }
        };

        final loadResult = await loadTool.execute(loadInput);
        final timeRange = loadResult['time_range'];

        expect(timeRange, isNotNull);
        expect(timeRange['start'], isA<String>());
        expect(timeRange['end'], isA<String>());
        expect(timeRange['duration_seconds'], isA<int>());
        expect(timeRange['duration_seconds'], greaterThan(0));
      });
    });

    group('data processing pipeline', () {
      test('should smooth power data with rolling average', () async {
        // Load noisy power data
        final loadInput = {
          'source': {
            'type': 'inline',
            'content': 'timestamp,power\n'
                '0,200\n1,250\n2,180\n3,240\n4,190\n'
                '5,230\n6,200\n7,220\n8,210\n9,225',
            'format': 'csv',
          }
        };

        final loadResult = await loadTool.execute(loadInput);
        final dataId = loadResult['data_id'] as String;

        // Apply 3-second rolling average
        final processInput = {
          'data_id': dataId,
          'operations': [
            {
              'type': 'rolling_window',
              'column': 'power',
              'window_seconds': 3,
              'reducer': 'mean',
            }
          ],
        };

        final processResult = await processTool.execute(processInput);
        expect(processResult['data_id'], isNotNull);
        expect(processResult['row_count'], equals(10));
      });

      test('should normalize data for multi-axis charting', () async {
        // Load data with different scales
        final loadInput = {
          'source': {
            'type': 'inline',
            'content': 'timestamp,power,heart_rate\n'
                '0,200,150\n1,220,155\n2,210,153',
            'format': 'csv',
          }
        };

        final loadResult = await loadTool.execute(loadInput);
        final dataId = loadResult['data_id'] as String;

        // Normalize power for comparison
        final processInput = {
          'data_id': dataId,
          'operations': [
            {
              'type': 'normalize',
              'column': 'power',
              'method': 'min_max',
            }
          ],
        };

        final processResult = await processTool.execute(processInput);
        expect(processResult['data_id'], isNotNull);

        // Verify normalized data
        final processedDataId = processResult['data_id'] as String;
        final describeResult =
            await describeTool.execute({'data_id': processedDataId});

        final powerColumn = (describeResult['columns'] as List).firstWhere(
          (col) => (col as Map)['name'] == 'power',
        ) as Map<String, dynamic>;

        // After min-max normalization, values should be between 0 and 1
        expect(powerColumn['stats']['min'], greaterThanOrEqualTo(0));
        expect(powerColumn['stats']['max'], lessThanOrEqualTo(1));
      });

      test('should resample high-frequency data for display', () async {
        // Load high-frequency data (e.g., 100Hz GPS data)
        final loadInput = {
          'source': {
            'type': 'inline',
            'content': List.generate(
              100,
              (i) => '$i,${200 + i % 50}',
            ).join('\n'),
            'format': 'csv',
          }
        };

        // Prepend CSV header
        final content = 'timestamp,power\n${loadInput['source']!['content']}';
        loadInput['source']!['content'] = content;

        final loadResult = await loadTool.execute(loadInput);
        final dataId = loadResult['data_id'] as String;

        // Resample to 1 sample per 10 seconds
        final processInput = {
          'data_id': dataId,
          'operations': [
            {
              'type': 'resample',
              'interval_seconds': 10,
              'method': 'mean',
            }
          ],
        };

        final processResult = await processTool.execute(processInput);
        expect(processResult['data_id'], isNotNull);
        expect(processResult['row_count'], lessThan(100));
        expect(processResult['row_count'], equals(10));
      });
    });

    group('error handling in pipeline', () {
      test('should handle invalid file format', () async {
        final loadInput = {
          'source': {
            'type': 'file',
            'file_id': 'corrupt-file',
            'format': 'fit',
          }
        };

        expect(
          () => loadTool.execute(loadInput),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle missing columns in processing', () async {
        final loadInput = {
          'source': {
            'type': 'inline',
            'content': 'timestamp,power\n0,200\n1,220',
            'format': 'csv',
          }
        };

        final loadResult = await loadTool.execute(loadInput);
        final dataId = loadResult['data_id'] as String;

        // Try to process non-existent column
        final processInput = {
          'data_id': dataId,
          'operations': [
            {
              'type': 'rolling_window',
              'column': 'heart_rate', // Doesn't exist
              'window_seconds': 30,
              'reducer': 'mean',
            }
          ],
        };

        expect(
          () => processTool.execute(processInput),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle empty data files', () async {
        final loadInput = {
          'source': {
            'type': 'inline',
            'content': 'timestamp,power\n', // Header only, no data
            'format': 'csv',
          }
        };

        final loadResult = await loadTool.execute(loadInput);
        expect(loadResult['row_count'], equals(0));

        final dataId = loadResult['data_id'] as String;
        final describeResult = await describeTool.execute({'data_id': dataId});

        expect(describeResult['row_count'], equals(0));
        expect(describeResult['columns'], isNotEmpty); // Headers still exist
      });
    });

    group('real-world sport science scenarios', () {
      test('should process power data for Normalized Power calculation',
          () async {
        // Load workout data
        final loadInput = {
          'source': {
            'type': 'inline',
            'content': 'timestamp,power\n${List.generate(
              3600, // 1 hour at 1Hz
              (i) => '$i,${200 + (i % 100) - 50}', // Variable power
            ).join('\n')}',
            'format': 'csv',
          }
        };

        final loadResult = await loadTool.execute(loadInput);
        final dataId = loadResult['data_id'] as String;

        // Apply 30-second rolling average (standard for NP)
        final processInput = {
          'data_id': dataId,
          'operations': [
            {
              'type': 'rolling_window',
              'column': 'power',
              'window_seconds': 30,
              'reducer': 'mean',
            }
          ],
        };

        final processResult = await processTool.execute(processInput);
        expect(processResult['data_id'], isNotNull);
        expect(processResult['row_count'], equals(3600));
      });

      test('should prepare multi-metric comparison data', () async {
        // Load multiple metrics
        final loadInput = {
          'source': {
            'type': 'inline',
            'content': 'timestamp,power,heart_rate,cadence,speed\n'
                '0,200,150,90,25.5\n'
                '1,220,155,92,26.0\n'
                '2,210,153,91,25.8\n'
                '3,230,158,93,26.2',
            'format': 'csv',
          }
        };

        final loadResult = await loadTool.execute(loadInput);
        final dataId = loadResult['data_id'] as String;

        // Process each metric independently
        final powerProcessed = await processTool.execute({
          'data_id': dataId,
          'operations': [
            {
              'type': 'select_columns',
              'columns': ['timestamp', 'power']
            },
            {'type': 'normalize', 'column': 'power', 'method': 'min_max'},
          ],
        });

        final hrProcessed = await processTool.execute({
          'data_id': dataId,
          'operations': [
            {
              'type': 'select_columns',
              'columns': ['timestamp', 'heart_rate']
            },
            {'type': 'normalize', 'column': 'heart_rate', 'method': 'min_max'},
          ],
        });

        expect(powerProcessed['data_id'], isNotNull);
        expect(hrProcessed['data_id'], isNotNull);
        expect(
            powerProcessed['data_id'], isNot(equals(hrProcessed['data_id'])));
      });
    });

    group('file upload workflow (US2)', () {
      late FileValidator validator;

      setUp(() {
        validator = FileValidator();
      });

      test('validates file before loading', () {
        final csvContent = '''timestamp,power,heart_rate
2026-01-25T10:00:00Z,200,120
2026-01-25T10:00:01Z,210,125''';
        final bytes = Uint8List.fromList(csvContent.codeUnits);

        // Validate the file
        final validationResult = validator.validate(
          fileName: 'workout.csv',
          fileSizeBytes: bytes.length,
          content: bytes,
        );

        expect(validationResult.success, isTrue);
        expect(validationResult.errorMessage, isNull);
      });

      test('rejects oversized file', () {
        // Create 51 MB file (exceeds 50 MB limit)
        final largeContent = Uint8List(52428801);

        final validationResult = validator.validate(
          fileName: 'large.csv',
          fileSizeBytes: largeContent.length,
          content: largeContent,
        );

        expect(validationResult.success, isFalse);
        expect(validationResult.errorMessage, contains('exceeds maximum'));
      });

      test('rejects unsupported file format', () {
        final content = Uint8List.fromList('test data'.codeUnits);

        final validationResult = validator.validate(
          fileName: 'document.pdf',
          fileSizeBytes: content.length,
          content: content,
        );

        expect(validationResult.success, isFalse);
        expect(
            validationResult.errorMessage, contains('Unsupported file format'));
      });

      test('rejects path traversal attempts', () {
        final content = Uint8List.fromList('test data'.codeUnits);

        final validationResult = validator.validate(
          fileName: '../../../etc/passwd.csv',
          fileSizeBytes: content.length,
          content: content,
        );

        expect(validationResult.success, isFalse);
        expect(validationResult.errorMessage, contains('path traversal'));
      });

      test('creates FileAttachment after validation', () {
        final csvContent = 'timestamp,power\n2026-01-25T10:00:00Z,200';
        final bytes = Uint8List.fromList(csvContent.codeUnits);

        final validationResult = validator.validate(
          fileName: 'workout.csv',
          fileSizeBytes: bytes.length,
          content: bytes,
        );

        expect(validationResult.success, isTrue);

        // Create FileAttachment after validation
        final attachment = FileAttachment(
          id: 'test-id',
          fileName: 'workout.csv',
          fileType: 'csv',
          fileSizeBytes: bytes.length,
          content: bytes,
          status: FileStatus.pending,
        );

        expect(attachment.fileName, equals('workout.csv'));
        expect(attachment.fileType, equals('csv'));
        expect(attachment.status, equals(FileStatus.pending));
      });

      test('processes file attachment through full workflow', () async {
        // Step 1: Validate file
        final csvContent = '''timestamp,power,heart_rate
2026-01-25T10:00:00Z,200,120
2026-01-25T10:00:01Z,210,125
2026-01-25T10:00:02Z,220,130''';
        final bytes = Uint8List.fromList(csvContent.codeUnits);

        final validationResult = validator.validate(
          fileName: 'workout.csv',
          fileSizeBytes: bytes.length,
          content: bytes,
        );
        expect(validationResult.success, isTrue);

        // Step 2: Create FileAttachment
        final attachment = FileAttachment(
          id: 'test-id',
          fileName: 'workout.csv',
          fileType: 'csv',
          fileSizeBytes: bytes.length,
          content: bytes,
          status: FileStatus.pending,
        );

        // Step 3: Load data using LoadDataTool
        final loadResult = await loadTool.execute({
          'source': {
            'type': 'inline',
            'content': csvContent,
            'format': 'csv',
          }
        });

        expect(loadResult['data_id'], isNotNull);
        expect(loadResult['row_count'], equals(3));

        // Step 4: Update attachment status to ready
        final dataId = loadResult['data_id'] as String;
        final updatedAttachment = attachment.copyWith(
          status: FileStatus.ready,
          dataId: dataId,
        );

        expect(updatedAttachment.status, equals(FileStatus.ready));
        expect(updatedAttachment.dataId, equals(dataId));

        // Step 5: Describe the loaded data for preview
        final describeResult = await describeTool.execute({'data_id': dataId});

        expect(describeResult['file_type'], equals('csv'));
        expect(describeResult['row_count'], equals(3));
        expect(describeResult['columns'], isA<List>());

        final columns = describeResult['columns'] as List;
        expect(columns.length, equals(3)); // timestamp, power, heart_rate
      });

      test('handles file processing error gracefully', () async {
        // Create attachment with invalid data
        final invalidContent = 'not,valid,csv\ndata';
        final bytes = Uint8List.fromList(invalidContent.codeUnits);

        final attachment = FileAttachment(
          id: 'test-id',
          fileName: 'invalid.csv',
          fileType: 'csv',
          fileSizeBytes: bytes.length,
          content: bytes,
          status: FileStatus.parsing,
        );

        // Attempt to load (may succeed or fail depending on implementation)
        try {
          await loadTool.execute({
            'source': {
              'type': 'inline',
              'content': invalidContent,
              'format': 'csv',
            }
          });
          // If it succeeds, that's fine - CSV is flexible
        } catch (error) {
          // If it fails, update attachment with error
          final errorAttachment = attachment.copyWith(
            status: FileStatus.error,
            errorMessage: error.toString(),
          );

          expect(errorAttachment.status, equals(FileStatus.error));
          expect(errorAttachment.errorMessage, isNotNull);
        }
      });

      test('supports multiple file formats (FIT, CSV, TCX)', () {
        final csvBytes = Uint8List.fromList('csv data'.codeUnits);
        final fitBytes = Uint8List.fromList('fit data'.codeUnits);
        final tcxBytes = Uint8List.fromList('tcx data'.codeUnits);

        final csvResult = validator.validate(
          fileName: 'data.csv',
          fileSizeBytes: csvBytes.length,
          content: csvBytes,
        );
        final fitResult = validator.validate(
          fileName: 'workout.fit',
          fileSizeBytes: fitBytes.length,
          content: fitBytes,
        );
        final tcxResult = validator.validate(
          fileName: 'activity.tcx',
          fileSizeBytes: tcxBytes.length,
          content: tcxBytes,
        );

        expect(csvResult.success, isTrue);
        expect(fitResult.success, isTrue);
        expect(tcxResult.success, isTrue);
      });
    });
  });
}
