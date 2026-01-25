// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:uuid/uuid.dart';

import 'data_store.dart';

/// Tool for applying transformations to loaded data
class ProcessDataTool {
  final DataStore _store = DataStore();
  final Uuid _uuid = const Uuid();

  String get name => 'process_data';

  String get description =>
      'Apply transformations to data (rolling windows, normalization, etc.)';

  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'required': ['data_id', 'operations'],
        'properties': {
          'data_id': {'type': 'string'},
          'operations': {'type': 'array'},
        }
      };

  Map<String, dynamic> get outputSchema => {
        'type': 'object',
        'properties': {
          'data_id': {'type': 'string'},
          'row_count': {'type': 'integer'},
        }
      };

  Future<Map<String, dynamic>> execute(Map<String, dynamic> input) async {
    // Validate input
    if (!input.containsKey('data_id')) {
      throw ArgumentError('Missing required parameter: data_id');
    }

    if (!input.containsKey('operations')) {
      throw ArgumentError('Missing required parameter: operations');
    }

    final dataId = input['data_id'] as String;
    final operations = input['operations'] as List<dynamic>;

    if (operations.isEmpty) {
      throw ArgumentError('operations cannot be empty');
    }

    // Retrieve original data
    final frame = _store.get(dataId);
    if (frame == null) {
      throw StateError('Data not found for id: $dataId');
    }

    // Apply each operation
    DataFrame currentFrame = frame;
    for (var operation in operations) {
      currentFrame = await _applyOperation(
          currentFrame, operation as Map<String, dynamic>);
    }

    // Store result with new ID
    final newDataId = _uuid.v4();
    _store.store(newDataId, currentFrame);

    return {
      'success': true,
      'data_id': newDataId,
      'row_count': currentFrame.rowCount,
    };
  }

  Future<DataFrame> _applyOperation(
      DataFrame frame, Map<String, dynamic> operation) async {
    final type = operation['type'] as String?;

    if (type == null) {
      throw ArgumentError('Missing operation type');
    }

    switch (type) {
      case 'select_columns':
        return _selectColumns(frame, operation);
      case 'rolling_window':
      case 'rolling_average': // Alias for rolling_window with mean reducer
        return _applyRollingWindow(frame, operation);
      case 'fixed_window':
        return _applyFixedWindow(frame, operation);
      case 'resample':
        return _resample(frame, operation);
      case 'normalize':
        return _normalize(frame, operation);
      case 'clip':
        return _clip(frame, operation);
      case 'filter':
        return _filter(frame, operation);
      default:
        throw ArgumentError('Invalid operation type: $type');
    }
  }

  DataFrame _selectColumns(DataFrame frame, Map<String, dynamic> operation) {
    final columnNames = (operation['columns'] as List<dynamic>).cast<String>();

    final selectedColumns = <DataColumn>[];
    for (var name in columnNames) {
      final col = frame.getColumn(name);
      if (col == null) {
        throw ArgumentError('Column not found: $name');
      }
      selectedColumns.add(col);
    }

    return frame.copyWith(columns: selectedColumns);
  }

  DataFrame _applyRollingWindow(
      DataFrame frame, Map<String, dynamic> operation) {
    final columnName = operation['column'] as String;
    final windowSeconds = operation['window_seconds'] as int?;
    final windowSize =
        operation['window_size'] as int?; // Support row-based windows
    final reducer = operation['reducer'] as String? ?? 'mean';
    final outputColumn =
        operation['output_column'] as String?; // Support custom output column

    final column = frame.getColumn(columnName);
    if (column == null) {
      throw ArgumentError('Column not found: $columnName');
    }

    final values = column.data.cast<num?>();
    List<num?> result;

    if (windowSize != null) {
      // Row-based rolling window
      result = <num?>[];
      for (var i = 0; i < values.length; i++) {
        final windowStart = (i - windowSize + 1).clamp(0, i + 1);
        final windowValues = <num>[];
        for (var j = windowStart; j <= i; j++) {
          if (values[j] != null) {
            windowValues.add(values[j]!);
          }
        }
        if (windowValues.isEmpty) {
          result.add(null);
        } else {
          result.add(_applyReducer(windowValues, reducer));
        }
      }
    } else if (windowSeconds != null) {
      // Time-based rolling window
      // Find timestamp column
      final timeColumn = frame.columns.firstWhere(
        (col) => col.type == 'datetime',
        orElse: () => throw ArgumentError('No timestamp column found'),
      );

      final times = timeColumn.data.cast<DateTime>();
      result = <num?>[];

      for (var i = 0; i < values.length; i++) {
        final currentTime = times[i];
        final windowStart =
            currentTime.subtract(Duration(seconds: windowSeconds));

        // Collect values in window
        final windowValues = <num>[];
        for (var j = 0; j <= i; j++) {
          if (times[j].isAfter(windowStart) &&
              !times[j].isAfter(currentTime) &&
              values[j] != null) {
            windowValues.add(values[j]!);
          }
        }

        // Apply reducer
        if (windowValues.isEmpty) {
          result.add(null);
        } else {
          result.add(_applyReducer(windowValues, reducer));
        }
      }
    } else {
      throw ArgumentError('Must provide either window_seconds or window_size');
    }

    // Create new column with results
    final targetColumnName = outputColumn ?? columnName;
    final newColumn = DataColumn(
      name: targetColumnName,
      type: 'number',
      nullable: column.nullable,
      data: result,
      stats: _calculateStats(result, 'number'),
      sampleValues: result.take(3).toList(),
    );

    // Add or replace column
    final newColumns = <DataColumn>[];
    bool replaced = false;
    for (var col in frame.columns) {
      if (col.name == targetColumnName) {
        newColumns.add(newColumn);
        replaced = true;
      } else {
        newColumns.add(col);
      }
    }
    if (!replaced) {
      newColumns.add(newColumn);
    }

    return frame.copyWith(columns: newColumns);
  }

  DataFrame _applyFixedWindow(DataFrame frame, Map<String, dynamic> operation) {
    final columnName = operation['column'] as String;
    final windowSeconds = operation['window_seconds'] as int;
    final reducer = operation['reducer'] as String? ?? 'mean';

    final column = frame.getColumn(columnName);
    if (column == null) {
      throw ArgumentError('Column not found: $columnName');
    }

    // Find timestamp column
    final timeColumn = frame.columns.firstWhere(
      (col) => col.type == 'datetime',
      orElse: () => throw ArgumentError('No timestamp column found'),
    );

    final times = timeColumn.data.cast<DateTime>();
    final values = column.data.cast<num?>();

    // Group into fixed windows
    final startTime = times.first;
    final endTime = times.last;
    final totalDuration = endTime.difference(startTime).inSeconds;
    final numWindows = (totalDuration / windowSeconds).ceil();

    final newTimes = <DateTime>[];
    final newValues = <num?>[];

    for (var windowIdx = 0; windowIdx < numWindows; windowIdx++) {
      final windowStart =
          startTime.add(Duration(seconds: windowIdx * windowSeconds));
      final windowEnd =
          startTime.add(Duration(seconds: (windowIdx + 1) * windowSeconds));

      // Collect values in this window
      final windowValues = <num>[];
      for (var i = 0; i < times.length; i++) {
        if (!times[i].isBefore(windowStart) &&
            times[i].isBefore(windowEnd) &&
            values[i] != null) {
          windowValues.add(values[i]!);
        }
      }

      if (windowValues.isNotEmpty) {
        newTimes.add(windowStart);
        newValues.add(_applyReducer(windowValues, reducer));
      }
    }

    // Create new columns
    final newTimeColumn = timeColumn.copyWith(
      data: newTimes,
      stats: ColumnStats(nullCount: 0),
      sampleValues: newTimes.take(3).toList(),
    );

    final newValueColumn = column.copyWith(
      data: newValues,
      stats: _calculateStats(newValues, 'number'),
      sampleValues: newValues.take(3).toList(),
    );

    // Build new column list
    final newColumns = frame.columns.map((col) {
      if (col.type == 'datetime') {
        return newTimeColumn;
      } else if (col.name == columnName) {
        return newValueColumn;
      } else {
        // Other columns need to be downsampled too (take first value in each window)
        return col; // Simplified - would need proper downsampling
      }
    }).toList();

    return frame.copyWith(
      columns: newColumns,
      rowCount: newTimes.length,
    );
  }

  DataFrame _resample(DataFrame frame, Map<String, dynamic> operation) {
    final intervalSeconds = operation['interval_seconds'] as int;
    final method = operation['method'] as String? ?? 'interpolate';

    // Find timestamp column
    final timeColumn = frame.columns.firstWhere(
      (col) => col.type == 'datetime',
      orElse: () => throw ArgumentError('No timestamp column found'),
    );

    final times = timeColumn.data.cast<DateTime>();
    final startTime = times.first;
    final endTime = times.last;

    // Generate new time points
    final newTimes = <DateTime>[];
    var currentTime = startTime;
    while (!currentTime.isAfter(endTime)) {
      newTimes.add(currentTime);
      currentTime = currentTime.add(Duration(seconds: intervalSeconds));
    }

    // Resample each numeric column
    final newColumns = <DataColumn>[];

    for (var col in frame.columns) {
      if (col.type == 'datetime') {
        newColumns.add(col.copyWith(
          data: newTimes,
          stats: ColumnStats(nullCount: 0),
          sampleValues: newTimes.take(3).toList(),
        ));
      } else if (col.type == 'number') {
        final values = col.data.cast<num?>();
        final newValues = <num?>[];

        for (var newTime in newTimes) {
          // Find nearest value or interpolate
          num? value;
          if (method == 'last') {
            // Find last value before or at this time
            for (var i = 0; i < times.length; i++) {
              if (!times[i].isAfter(newTime)) {
                value = values[i];
              } else {
                break;
              }
            }
          } else {
            // Simple interpolation or mean
            value = _interpolateValue(times, values, newTime);
          }
          newValues.add(value);
        }

        newColumns.add(col.copyWith(
          data: newValues,
          stats: _calculateStats(newValues, 'number'),
          sampleValues: newValues.take(3).toList(),
        ));
      } else {
        // Non-numeric columns - just repeat values
        newColumns.add(col);
      }
    }

    return frame.copyWith(
      columns: newColumns,
      rowCount: newTimes.length,
    );
  }

  DataFrame _normalize(DataFrame frame, Map<String, dynamic> operation) {
    final columnName = operation['column'] as String;
    final method = operation['method'] as String? ?? 'min_max';

    final column = frame.getColumn(columnName);
    if (column == null) {
      throw ArgumentError('Column not found: $columnName');
    }

    final values = column.data.cast<num?>().toList();
    final nonNullValues = values.whereType<num>().toList();

    if (nonNullValues.isEmpty) {
      throw ArgumentError('No non-null values to normalize');
    }

    final normalizedValues = <num?>[];

    if (method == 'min_max') {
      final min = nonNullValues.reduce(math.min);
      final max = nonNullValues.reduce(math.max);
      final range = max - min;

      for (var value in values) {
        if (value == null) {
          normalizedValues.add(null);
        } else {
          normalizedValues.add(range == 0 ? 0 : (value - min) / range);
        }
      }
    } else if (method == 'z_score') {
      final mean = nonNullValues.reduce((a, b) => a + b) / nonNullValues.length;
      final variance = nonNullValues
              .map((v) => math.pow(v - mean, 2))
              .reduce((a, b) => a + b) /
          nonNullValues.length;
      final stdDev = math.sqrt(variance);

      for (var value in values) {
        if (value == null) {
          normalizedValues.add(null);
        } else {
          normalizedValues.add(stdDev == 0 ? 0 : (value - mean) / stdDev);
        }
      }
    }

    final newColumn = column.copyWith(
      data: normalizedValues,
      stats: _calculateStats(normalizedValues, 'number'),
    );

    final newColumns = frame.columns.map((col) {
      return col.name == columnName ? newColumn : col;
    }).toList();

    return frame.copyWith(columns: newColumns);
  }

  DataFrame _clip(DataFrame frame, Map<String, dynamic> operation) {
    final columnName = operation['column'] as String;
    final min = operation['min'] as num?;
    final max = operation['max'] as num?;

    final column = frame.getColumn(columnName);
    if (column == null) {
      throw ArgumentError('Column not found: $columnName');
    }

    final values = column.data.cast<num?>().toList();
    final clippedValues = <num?>[];

    for (var value in values) {
      if (value == null) {
        clippedValues.add(null);
      } else {
        var clipped = value;
        if (min != null && clipped < min) clipped = min;
        if (max != null && clipped > max) clipped = max;
        clippedValues.add(clipped);
      }
    }

    final newColumn = column.copyWith(
      data: clippedValues,
      stats: _calculateStats(clippedValues, 'number'),
    );

    final newColumns = frame.columns.map((col) {
      return col.name == columnName ? newColumn : col;
    }).toList();

    return frame.copyWith(columns: newColumns);
  }

  DataFrame _filter(DataFrame frame, Map<String, dynamic> operation) {
    final condition = operation['condition'] as Map<String, dynamic>;
    final columnName = condition['column'] as String;
    final operator = condition['operator'] as String;
    final compareValue = condition['value'];

    final column = frame.getColumn(columnName);
    if (column == null) {
      throw ArgumentError('Column not found: $columnName');
    }

    final values = column.data;
    final keepIndices = <int>[];

    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == null) continue;

      bool keep = false;
      if (operator == '>=' && value is num && compareValue is num) {
        keep = value >= compareValue;
      } else if (operator == '>' && value is num && compareValue is num) {
        keep = value > compareValue;
      } else if (operator == '<=' && value is num && compareValue is num) {
        keep = value <= compareValue;
      } else if (operator == '<' && value is num && compareValue is num) {
        keep = value < compareValue;
      } else if (operator == '==') {
        keep = value == compareValue;
      }

      if (keep) {
        keepIndices.add(i);
      }
    }

    // Filter all columns
    final newColumns = <DataColumn>[];
    for (var col in frame.columns) {
      final filteredData = keepIndices.map((i) => col.data[i]).toList();
      newColumns.add(col.copyWith(
        data: filteredData,
        stats: _calculateStats(filteredData, col.type),
        sampleValues: filteredData.take(3).toList(),
      ));
    }

    return frame.copyWith(
      columns: newColumns,
      rowCount: keepIndices.length,
    );
  }

  num _applyReducer(List<num> values, String reducer) {
    switch (reducer) {
      case 'mean':
        return values.reduce((a, b) => a + b) / values.length;
      case 'max':
        return values.reduce(math.max);
      case 'min':
        return values.reduce(math.min);
      case 'sum':
        return values.reduce((a, b) => a + b);
      default:
        throw ArgumentError('Invalid reducer: $reducer');
    }
  }

  num? _interpolateValue(
      List<DateTime> times, List<num?> values, DateTime targetTime) {
    // Simple linear interpolation
    for (var i = 0; i < times.length - 1; i++) {
      if (!times[i].isAfter(targetTime) && times[i + 1].isAfter(targetTime)) {
        final v1 = values[i];
        final v2 = values[i + 1];
        if (v1 == null || v2 == null) return v1 ?? v2;

        final t1 = times[i].millisecondsSinceEpoch;
        final t2 = times[i + 1].millisecondsSinceEpoch;
        final t = targetTime.millisecondsSinceEpoch;

        final ratio = (t - t1) / (t2 - t1);
        return v1 + (v2 - v1) * ratio;
      }
    }

    // Return last value if after all times
    return values.lastWhere((v) => v != null, orElse: () => null);
  }

  ColumnStats _calculateStats(List<dynamic> data, String type) {
    final int nullCount = data.where((v) => v == null).length;

    if (type != 'number') {
      return ColumnStats(nullCount: nullCount);
    }

    final numbers = data.whereType<num>().toList();
    if (numbers.isEmpty) {
      return ColumnStats(nullCount: nullCount);
    }

    final min = numbers.reduce((a, b) => a < b ? a : b);
    final max = numbers.reduce((a, b) => a > b ? a : b);
    final mean = numbers.reduce((a, b) => a + b) / numbers.length;

    return ColumnStats(
      nullCount: nullCount,
      min: min,
      max: max,
      mean: mean,
    );
  }
}
