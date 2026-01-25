/// Data source type enumeration
enum DataSourceType {
  file,
  url,
  inline,
}

/// Column type enumeration
enum ColumnType {
  number,
  string,
  datetime,
  boolean,
}

/// Stub implementation for TimeRange model
class TimeRange {
  final DateTime start;
  final DateTime end;
  final int durationSeconds;

  /// Creates a new TimeRange instance
  TimeRange({
    required this.start,
    required this.end,
    required this.durationSeconds,
  });

  /// Creates a TimeRange from JSON
  factory TimeRange.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('TimeRange.fromJson not yet implemented');
  }

  /// Converts TimeRange to JSON
  Map<String, dynamic> toJson() {
    throw UnimplementedError('TimeRange.toJson not yet implemented');
  }
}

/// Stub implementation for ColumnStats model
class ColumnStats {
  final double? min;
  final double? max;
  final double? mean;
  final int? nullCount;

  /// Creates a new ColumnStats instance
  ColumnStats({
    this.min,
    this.max,
    this.mean,
    this.nullCount,
  });

  /// Creates a ColumnStats from JSON
  factory ColumnStats.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('ColumnStats.fromJson not yet implemented');
  }

  /// Converts ColumnStats to JSON
  Map<String, dynamic> toJson() {
    throw UnimplementedError('ColumnStats.toJson not yet implemented');
  }
}

/// Stub implementation for ColumnDescriptor model
class ColumnDescriptor {
  final String name;
  final ColumnType type;
  final bool nullable;
  final ColumnStats? stats;
  final List<dynamic> sampleValues;

  /// Creates a new ColumnDescriptor instance
  ColumnDescriptor({
    required this.name,
    required this.type,
    bool? nullable,
    this.stats,
    List<dynamic>? sampleValues,
  })  : nullable = nullable ?? false,
        sampleValues = sampleValues ?? [];

  /// Creates a ColumnDescriptor from JSON
  factory ColumnDescriptor.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('ColumnDescriptor.fromJson not yet implemented');
  }

  /// Converts ColumnDescriptor to JSON
  Map<String, dynamic> toJson() {
    throw UnimplementedError('ColumnDescriptor.toJson not yet implemented');
  }
}

/// Stub implementation for LoadedData model
/// This will be implemented in the green phase of TDD
class LoadedData {
  final String id;
  final DataSourceType type;
  final String? fileName;
  final String? fileType;
  final int rowCount;
  final List<ColumnDescriptor> columns;
  final List<Map<String, dynamic>> data;
  final TimeRange? timeRange;
  final DateTime loadedAt;

  /// Creates a new LoadedData instance
  LoadedData({
    required this.id,
    required this.type,
    this.fileName,
    this.fileType,
    required this.rowCount,
    required this.columns,
    required this.data,
    this.timeRange,
    DateTime? loadedAt,
  }) : loadedAt = loadedAt ?? DateTime.now();

  /// Creates a LoadedData from JSON
  factory LoadedData.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('LoadedData.fromJson not yet implemented');
  }

  /// Converts LoadedData to JSON
  Map<String, dynamic> toJson() {
    throw UnimplementedError('LoadedData.toJson not yet implemented');
  }
}
