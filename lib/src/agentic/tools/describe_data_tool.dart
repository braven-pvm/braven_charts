// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

import 'data_store.dart';

/// Tool for analyzing and describing loaded data
class DescribeDataTool {
  final DataStore _store = DataStore();

  String get name => 'describe_data';

  String get description =>
      'Analyze loaded data to discover available columns, types, and statistics';

  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'required': ['data_id'],
        'properties': {
          'data_id': {'type': 'string'},
        }
      };

  Map<String, dynamic> get outputSchema => {
        'type': 'object',
        'properties': {
          'file_name': {'type': 'string'},
          'file_type': {'type': 'string'},
          'row_count': {'type': 'integer'},
          'columns': {'type': 'array'},
          'time_range': {'type': 'object', 'nullable': true},
        }
      };

  Future<Map<String, dynamic>> execute(Map<String, dynamic> input) async {
    // Validate input
    if (!input.containsKey('data_id')) {
      throw ArgumentError('Missing required parameter: data_id');
    }

    final dataId = input['data_id'] as String;

    if (dataId.isEmpty) {
      throw ArgumentError('data_id cannot be empty');
    }

    // Retrieve data from store
    final frame = _store.get(dataId);
    if (frame == null) {
      throw StateError('Data not found for id: $dataId');
    }

    // Build column metadata
    final columns = frame.columns.map((col) {
      return {
        'name': col.name,
        'type': col.type,
        'nullable': col.nullable,
        'sample_values': col.sampleValues,
        'stats': {
          'null_count': col.stats.nullCount,
          'min': col.stats.min,
          'max': col.stats.max,
          'mean': col.stats.mean,
        }
      };
    }).toList();

    return {
      'success': true,
      'file_name': frame.fileName,
      'file_type': frame.fileType,
      'row_count': frame.rowCount,
      'columns': columns,
      'time_range': frame.timeRange?.toJson(),
    };
  }
}
