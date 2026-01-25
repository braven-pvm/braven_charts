// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

/// In-memory data store for loaded datasets
/// Maps data_id (UUID) to loaded DataFrame instances
class DataStore {
  static final DataStore _instance = DataStore._internal();
  factory DataStore() => _instance;
  DataStore._internal();

  final Map<String, DataFrame> _dataFrames = {};

  void store(String dataId, DataFrame frame) {
    _dataFrames[dataId] = frame;
  }

  DataFrame? get(String dataId) {
    return _dataFrames[dataId];
  }

  bool contains(String dataId) {
    return _dataFrames.containsKey(dataId);
  }

  void remove(String dataId) {
    _dataFrames.remove(dataId);
  }

  void clear() {
    _dataFrames.clear();
  }
}

/// Represents a loaded dataset with metadata
class DataFrame {
  final String fileName;
  final String fileType; // 'csv', 'fit', 'json'
  final List<DataColumn> columns;
  final int rowCount;
  final TimeRange? timeRange;
  final String? timezone;

  DataFrame({
    required this.fileName,
    required this.fileType,
    required this.columns,
    required this.rowCount,
    this.timeRange,
    this.timezone,
  });

  /// Get a column by name
  DataColumn? getColumn(String name) {
    try {
      return columns.firstWhere((col) => col.name == name);
    } catch (_) {
      return null;
    }
  }

  /// Check if column exists
  bool hasColumn(String name) {
    return columns.any((col) => col.name == name);
  }

  /// Create a new DataFrame with different columns (for processing)
  DataFrame copyWith({
    String? fileName,
    String? fileType,
    List<DataColumn>? columns,
    int? rowCount,
    TimeRange? timeRange,
    String? timezone,
  }) {
    return DataFrame(
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      columns: columns ?? this.columns,
      rowCount: rowCount ?? this.rowCount,
      timeRange: timeRange ?? this.timeRange,
      timezone: timezone ?? this.timezone,
    );
  }
}

/// Represents a single column in a DataFrame
class DataColumn {
  final String name;
  final String type; // 'number', 'string', 'datetime', 'boolean'
  final bool nullable;
  final List<dynamic> data;
  final ColumnStats stats;
  final List<dynamic> sampleValues;

  DataColumn({
    required this.name,
    required this.type,
    required this.nullable,
    required this.data,
    required this.stats,
    required this.sampleValues,
  });

  /// Create a typed copy for processing
  DataColumn copyWith({
    String? name,
    String? type,
    bool? nullable,
    List<dynamic>? data,
    ColumnStats? stats,
    List<dynamic>? sampleValues,
  }) {
    return DataColumn(
      name: name ?? this.name,
      type: type ?? this.type,
      nullable: nullable ?? this.nullable,
      data: data ?? this.data,
      stats: stats ?? this.stats,
      sampleValues: sampleValues ?? this.sampleValues,
    );
  }
}

/// Column statistics
class ColumnStats {
  final int nullCount;
  final num? min;
  final num? max;
  final num? mean;

  ColumnStats({
    required this.nullCount,
    this.min,
    this.max,
    this.mean,
  });
}

/// Time range information
class TimeRange {
  final DateTime start;
  final DateTime end;
  final int durationSeconds;

  TimeRange({
    required this.start,
    required this.end,
    required this.durationSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'duration_seconds': durationSeconds,
    };
  }
}
