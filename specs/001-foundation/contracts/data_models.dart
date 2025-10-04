// Contract: Data Models (FR-001)
// This file defines the API contracts for core data structures.
// Tests MUST verify these contracts before implementation.
// 
// NOTE: This is a CONTRACT file, not an implementation.
// Compile errors are expected - this defines the API surface.
// Implementation classes will be created during Phase 3-4.

/// ChartDataPoint Contract (FR-001.1)
/// 
/// A ChartDataPoint represents a single (x, y) coordinate with optional metadata.
/// 
/// MUST:
/// - Be immutable after creation
/// - Support double precision x and y values
/// - Support optional timestamp for time-series data
/// - Support optional label for tooltips
/// - Implement efficient equality comparison
/// 
/// Performance Targets:
/// - Creation time: <1μs (FR-005.1)
/// - Memory size: <1KB per instance (FR-005.7)
/// - Equality check: <100ns
abstract class ChartDataPoint {
  // Required fields
  double get x;
  double get y;
  
  // Optional fields
  DateTime? get timestamp;
  String? get label;
  Map<String, dynamic>? get metadata;
  
  // Factory constructors
  const factory ChartDataPoint({
    required double x,
    required double y,
    DateTime? timestamp,
    String? label,
    Map<String, dynamic>? metadata,
  }) = _ChartDataPointImpl;
  
  // Copy with mutation
  ChartDataPoint copyWith({
    double? x,
    double? y,
    DateTime? timestamp,
    String? label,
    Map<String, dynamic>? metadata,
  });
  
  // Equality (excluding metadata for performance)
  @override
  bool operator ==(Object other);
  
  @override
  int get hashCode;
  
  // Validation
  /// Returns true if x and y are finite numbers (not NaN or infinity)
  bool get isValid;
  
  /// Returns true if this point has a timestamp
  bool get hasTimestamp;
  
  /// Returns true if this point has a label
  bool get hasLabel;
}

/// ChartSeries Contract (FR-001.2)
/// 
/// A ChartSeries represents a collection of related ChartDataPoint objects.
/// 
/// MUST:
/// - Have unique series identifier
/// - Maintain ordered list of ChartDataPoint objects
/// - Store series metadata (name, color, style)
/// - Be immutable after creation
/// - Support efficient iteration and access
/// 
/// Performance Targets:
/// - 10,000 points MUST occupy <10MB (FR-005.2)
/// - Iteration: O(n) with minimal overhead
/// - Index access: O(1)
abstract class ChartSeries {
  // Required fields
  String get id;
  List<ChartDataPoint> get points;
  bool get isXOrdered;
  
  // Optional fields
  String? get name;
  Color? get color;
  SeriesStyle? get style;
  Map<String, dynamic>? get metadata;
  
  // Factory constructor
  const factory ChartSeries({
    required String id,
    required List<ChartDataPoint> points,
    String? name,
    Color? color,
    SeriesStyle? style,
    bool isXOrdered = false,
    Map<String, dynamic>? metadata,
  }) = _ChartSeriesImpl;
  
  // Copy with mutation
  ChartSeries copyWith({
    String? id,
    List<ChartDataPoint>? points,
    String? name,
    Color? color,
    SeriesStyle? style,
    bool? isXOrdered,
    Map<String, dynamic>? metadata,
  });
  
  // Computed properties (cached)
  DataRange get xRange;
  DataRange get yRange;
  bool get isEmpty;
  int get length;
  
  // Validation
  /// Validates that if isXOrdered is true, points are actually sorted by x
  bool validateOrdering();
  
  /// Returns ChartResult with validation errors if any
  ChartResult<void> validate();
}

/// SeriesStyle enum - Rendering style hints
enum SeriesStyle {
  line,      // Line chart
  bar,       // Bar chart
  area,      // Area chart
  scatter,   // Scatter plot
  candlestick, // Candlestick chart
}

/// DataRange Contract (FR-001.3)
/// 
/// Represents minimum and maximum bounds for a data axis.
/// 
/// MUST:
/// - Enforce min <= max
/// - Support padding/margin for visual spacing
/// - Handle NaN and infinity gracefully
/// - Be immutable after creation
abstract class DataRange {
  // Required fields
  double get min;
  double get max;
  
  // Optional fields
  double? get padding;
  
  // Factory constructors
  const factory DataRange({
    required double min,
    required double max,
    double? padding,
  }) = _DataRangeImpl;
  
  factory DataRange.fromValues(List<double> values, {double? padding});
  
  factory DataRange.fromPoints(
    List<ChartDataPoint> points,
    Axis axis, {
    double? padding,
  });
  
  factory DataRange.symmetric(double center, double radius);
  
  // Copy with mutation
  DataRange copyWith({
    double? min,
    double? max,
    double? padding,
  });
  
  // Computed properties
  double get span; // max - min
  double get center; // (max + min) / 2
  double get paddedMin; // min - (span × padding)
  double get paddedMax; // max + (span × padding)
  
  // Operations
  bool contains(double value);
  bool overlaps(DataRange other);
  DataRange merge(DataRange other);
  
  // Validation
  ChartResult<void> validate();
}

/// Axis enum - X or Y axis identifier
enum Axis { x, y }

/// TimeSeriesData Contract (FR-001.4)
/// 
/// Specialized container for time-based datasets.
/// 
/// MUST:
/// - Support DateTime-based x-axis
/// - Maintain sorted order by timestamp
/// - Handle time zone conversions
/// - Support sampling and aggregation
abstract class TimeSeriesData {
  // Required fields
  String get id;
  List<TimeSeriesPoint> get dataPoints;
  
  // Optional fields
  String? get name;
  String? get timeZone; // IANA time zone (e.g., "America/New_York")
  Duration? get samplingRate;
  
  // Factory constructor
  const factory TimeSeriesData({
    required String id,
    required List<TimeSeriesPoint> dataPoints,
    String? name,
    String? timeZone,
    Duration? samplingRate,
  }) = _TimeSeriesDataImpl;
  
  // Computed properties
  DateTimeRange get timeRange;
  DataRange get valueRange;
  Duration get duration;
  Duration get averageSamplingRate;
  
  // Conversions
  ChartSeries toChartSeries();
  
  // Aggregation operations
  TimeSeriesData sampleByDuration(Duration interval);
  TimeSeriesData aggregateByPeriod(Period period, Aggregation aggregation);
  TimeSeriesData interpolateGaps(Duration maxGap);
  
  // Validation
  ChartResult<void> validate();
}

/// TimeSeriesPoint - Individual time-based data point
class TimeSeriesPoint {
  final DateTime timestamp;
  final double value;
  final String? label;
  
  const TimeSeriesPoint({
    required this.timestamp,
    required this.value,
    this.label,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSeriesPoint &&
          timestamp == other.timestamp &&
          value == other.value;
  
  @override
  int get hashCode => Object.hash(timestamp, value);
}

/// Period enum - Time aggregation periods
enum Period {
  minute,
  hour,
  day,
  week,
  month,
  quarter,
  year,
}

/// Aggregation enum - Aggregation functions
enum Aggregation {
  sum,
  average,
  min,
  max,
  first,
  last,
  count,
}

/// DateTimeRange - Time range bounds
class DateTimeRange {
  final DateTime min;
  final DateTime max;
  
  const DateTimeRange({required this.min, required this.max});
  
  Duration get duration => max.difference(min);
  
  bool contains(DateTime time) =>
      !time.isBefore(min) && !time.isAfter(max);
}

// Supporting types (referenced but not implemented in this contract)
class Color {
  final int value;
  const Color(this.value);
}

class ChartResult<T> {
  // Defined in type_system.dart contract
}
