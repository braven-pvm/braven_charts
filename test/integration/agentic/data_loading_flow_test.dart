// @orchestra-task: 12
@Tags(['tdd-red'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/agentic/tools/load_data_tool.dart';
import 'package:braven_charts/src/agentic/tools/describe_data_tool.dart';
import 'package:braven_charts/src/agentic/tools/process_data_tool.dart';

/// Integration test for data loading workflow
///
/// Tests the complete flow: load → describe → process
///
/// This is a TDD RED phase test - it will FAIL until the feature is implemented
void main() {
  group('[tdd-red] Data Loading Flow Integration', () {
    test('should complete full data pipeline: load → describe → process',
        () async {
      // ARRANGE: Create tool instances
      final loadTool = LoadDataTool();
      final describeTool = DescribeDataTool();
      final processTool = ProcessDataTool();

      // ACT: Load sample CSV data
      final loadResult = await loadTool.execute({
        'source': {
          'type': 'inline',
          'content': 'timestamp,power,hr\n0,150,120\n1,160,125\n2,155,122',
          'format': 'csv',
        },
      });

      expect(loadResult['success'], isTrue, reason: 'Load should succeed');
      final dataId = loadResult['data_id'] as String;
      expect(dataId, isNotEmpty, reason: 'Should return valid data_id');

      // ACT: Describe the loaded data
      final describeResult = await describeTool.execute({
        'data_id': dataId,
      });

      expect(describeResult['success'], isTrue,
          reason: 'Describe should succeed');
      expect(describeResult['row_count'], equals(3),
          reason: 'Should have 3 rows');
      expect(describeResult['columns'], hasLength(3),
          reason: 'Should have 3 columns');

      final columns = describeResult['columns'] as List;
      expect(columns.map((c) => c['name']),
          containsAll(['timestamp', 'power', 'hr']),
          reason: 'Should identify all columns');

      // ACT: Process the data (rolling average)
      final processResult = await processTool.execute({
        'data_id': dataId,
        'operations': [
          {
            'type': 'rolling_average',
            'column': 'power',
            'window_size': 2,
            'output_column': 'power_avg',
          }
        ],
      });

      expect(processResult['success'], isTrue,
          reason: 'Process should succeed');
      final processedDataId = processResult['data_id'] as String;
      expect(processedDataId, isNot(equals(dataId)),
          reason: 'Should return new data_id for processed data');

      // ACT: Describe processed data to verify transformation
      final describeProcessedResult = await describeTool.execute({
        'data_id': processedDataId,
      });

      expect(describeProcessedResult['success'], isTrue);
      final processedColumns = describeProcessedResult['columns'] as List;
      expect(processedColumns.map((c) => c['name']), contains('power_avg'),
          reason: 'Should include new rolling average column');
    });

    test('should handle errors gracefully in pipeline', () async {
      // ARRANGE
      final describeTool = DescribeDataTool();

      // ACT: Try to describe non-existent data
      final describeResult = await describeTool.execute({
        'data_id': 'invalid-uuid-12345',
      });

      // ASSERT: Should return error, not throw
      expect(describeResult['success'], isFalse,
          reason: 'Should fail gracefully with invalid data_id');
      expect(describeResult['error'], isNotNull,
          reason: 'Should provide error message');
    });

    test('should maintain data integrity through pipeline', () async {
      // ARRANGE
      final loadTool = LoadDataTool();
      final describeTool = DescribeDataTool();
      final processTool = ProcessDataTool();

      // ACT: Load data with specific values
      final loadResult = await loadTool.execute({
        'source': {
          'type': 'inline',
          'content': 'x,y\n1,10\n2,20\n3,30',
          'format': 'csv',
        },
      });

      final dataId = loadResult['data_id'] as String;

      // ACT: Filter to only rows where y >= 20
      final processResult = await processTool.execute({
        'data_id': dataId,
        'operations': [
          {
            'type': 'filter',
            'condition': {
              'column': 'y',
              'operator': '>=',
              'value': 20,
            }
          }
        ],
      });

      final filteredDataId = processResult['data_id'] as String;

      // ACT: Describe filtered data
      final describeResult = await describeTool.execute({
        'data_id': filteredDataId,
      });

      // ASSERT: Should have 2 rows (y=20 and y=30)
      expect(describeResult['row_count'], equals(2),
          reason: 'Filter should reduce to 2 rows');
      expect(describeResult['columns'], hasLength(2),
          reason: 'Should maintain original columns');
    });
  });
}
