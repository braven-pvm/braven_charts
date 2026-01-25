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

/// Represents a time range for time-series data.
///
/// Contains start and end timestamps plus the duration in seconds.
class TimeRange {
  /// Start timestamp of the range
  final DateTime start;

  /// End timestamp of the range
  final DateTime end;

  /// Duration of the range in seconds
  final int durationSeconds;

  /// Creates a new TimeRange instance
  TimeRange({
    required this.start,
    required this.end,
    required this.durationSeconds,
  }) : assert(durationSeconds >= 0, 'durationSeconds cannot be negative');

  /// Creates a TimeRange from JSON
  factory TimeRange.fromJson(Map<String, dynamic> json) {
    return TimeRange(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      durationSeconds: json['durationSeconds'] as int,
    );
  }

  /// Converts TimeRange to JSON
  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'durationSeconds': durationSeconds,
    };
  }

  /// Creates a copy with modified values
  TimeRange copyWith({
    DateTime? start,
    DateTime? end,
    int? durationSeconds,
  }) {
    return TimeRange(
      start: start ?? this.start,
      end: end ?? this.end,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }
}

/// Statistical information about a data column.
///
/// Contains min, max, mean, and null count for numeric columns.
class ColumnStats {
  /// Minimum value in the column
  final double? min;

  /// Maximum value in the column
  final double? max;

  /// Mean (average) value in the column
  final double? mean;

  /// Number of null values in the column
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
    return ColumnStats(
      min: json['min'] as double?,
      max: json['max'] as double?,
      mean: json['mean'] as double?,
      nullCount: json['nullCount'] as int?,
    );
  }

  /// Converts ColumnStats to JSON
  Map<String, dynamic> toJson() {
    return {
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      if (mean != null) 'mean': mean,
      if (nullCount != null) 'nullCount': nullCount,
    };
  }

  /// Creates a copy with modified values
  ColumnStats copyWith({
    double? min,
    double? max,
    double? mean,
    int? nullCount,
  }) {
    return ColumnStats(
      min: min ?? this.min,
      max: max ?? this.max,
      mean: mean ?? this.mean,
      nullCount: nullCount ?? this.nullCount,
    );
  }
}

/// Describes the structure and metadata of a data column.
///
/// Contains column name, type, nullability, statistics, and sample values.
class ColumnDescriptor {
  /// Name of the column
  final String name;

  /// Data type of the column
  final ColumnType type;

  /// Whether the column can contain null values
  final bool nullable;

  /// Statistical information about the column (for numeric columns)
  final ColumnStats? stats;

  /// Sample values from the column
  final List<dynamic> sampleValues;

  /// Creates a new ColumnDescriptor instance
  ColumnDescriptor({
    required this.name,
    required this.type,
    bool? nullable,
    this.stats,
    List<dynamic>? sampleValues,
  })  : nullable = nullable ?? false,
        sampleValues = sampleValues ?? [],
        assert(name.isNotEmpty, 'Column name cannot be empty');

  /// Creates a ColumnDescriptor from JSON
  factory ColumnDescriptor.fromJson(Map<String, dynamic> json) {
    return ColumnDescriptor(
      name: json['name'] as String,
      type: ColumnType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      nullable: json['nullable'] as bool? ?? false,
      stats: json['stats'] != null ? ColumnStats.fromJson(json['stats'] as Map<String, dynamic>) : null,
      sampleValues: json['sampleValues'] as List<dynamic>? ?? [],
    );
  }

  /// Converts ColumnDescriptor to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name,
      'nullable': nullable,
      if (stats != null) 'stats': stats!.toJson(),
      'sampleValues': sampleValues,
    };
  }

  /// Creates a copy with modified values
  ColumnDescriptor copyWith({
    String? name,
    ColumnType? type,
    bool? nullable,
    ColumnStats? stats,
    List<dynamic>? sampleValues,
  }) {
    return ColumnDescriptor(
      name: name ?? this.name,
      type: type ?? this.type,
      nullable: nullable ?? this.nullable,
      stats: stats ?? this.stats,
      sampleValues: sampleValues ?? this.sampleValues,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColumnDescriptor && other.name == name && other.type == type && other.nullable == nullable;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      type,
      nullable,
    );
  }
}

/// Represents data loaded from a file, URL, or inline source.
///
/// Contains the data structure, column descriptors, and metadata.
/// IDs must be valid UUID v4 format and columns must not be empty.
class LoadedData {
  /// Unique identifier (UUID v4 format)
  final String id;

  /// Source type of the data
  final DataSourceType type;

  /// File name if loaded from a file
  final String? fileName;

  /// File type (e.g., 'fit', 'csv', 'tcx')
  final String? fileType;

  /// Number of rows in the data
  final int rowCount;

  /// Column descriptors defining the data structure
  final List<ColumnDescriptor> columns;

  /// The actual data rows
  final List<Map<String, dynamic>> data;

  /// Time range for time-series data
  final TimeRange? timeRange;

  /// Timestamp when the data was loaded
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
  })  : loadedAt = loadedAt ?? DateTime.now(),
        assert(
          _isValidUuidV4(id),
          'LoadedData id must be a valid UUID v4 format',
        ),
        assert(
          columns.isNotEmpty,
          'LoadedData must have at least one column',
        ),
        assert(
          fileType == null || _isValidFileType(fileType),
          'fileType must be fit, csv, json, yaml, or tcx',
        ),
        assert(
          fileType != 'fit' || type == DataSourceType.file,
          'FIT files must be from file source',
        );

  /// Validates file type format
  static bool _isValidFileType(String fileType) {
    final normalized = fileType.toLowerCase();
    return ['fit', 'csv', 'json', 'yaml', 'tcx'].contains(normalized);
  }

  /// Validates UUID v4 format
  static bool _isValidUuidV4(String id) {
    final uuidV4Pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidV4Pattern.hasMatch(id);
  }

  /// Creates a LoadedData from JSON
  factory LoadedData.fromJson(Map<String, dynamic> json) {
    return LoadedData(
      id: json['id'] as String,
      type: DataSourceType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      fileName: json['fileName'] as String?,
      fileType: json['fileType'] as String?,
      rowCount: json['rowCount'] as int,
      columns: (json['columns'] as List).map((e) => ColumnDescriptor.fromJson(e as Map<String, dynamic>)).toList(),
      data: (json['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      timeRange: json['timeRange'] != null ? TimeRange.fromJson(json['timeRange'] as Map<String, dynamic>) : null,
      loadedAt: DateTime.parse(json['loadedAt'] as String),
    );
  }

  /// Converts LoadedData to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      if (fileName != null) 'fileName': fileName,
      if (fileType != null) 'fileType': fileType,
      'rowCount': rowCount,
      'columns': columns.map((c) => c.toJson()).toList(),
      'data': data,
      if (timeRange != null) 'timeRange': timeRange!.toJson(),
      'loadedAt': loadedAt.toIso8601String(),
    };
  }

  /// Creates a copy with modified values
  LoadedData copyWith({
    String? id,
    DataSourceType? type,
    String? fileName,
    String? fileType,
    int? rowCount,
    List<ColumnDescriptor>? columns,
    List<Map<String, dynamic>>? data,
    TimeRange? timeRange,
    DateTime? loadedAt,
  }) {
    return LoadedData(
      id: id ?? this.id,
      type: type ?? this.type,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      rowCount: rowCount ?? this.rowCount,
      columns: columns ?? this.columns,
      data: data ?? this.data,
      timeRange: timeRange ?? this.timeRange,
      loadedAt: loadedAt ?? this.loadedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoadedData && other.id == id && other.type == type && other.rowCount == rowCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      type,
      rowCount,
    );
  }
}
