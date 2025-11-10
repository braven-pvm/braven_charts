// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Represents a single (x, y) coordinate with optional metadata.
///
/// ChartDataPoint is an immutable data structure representing a point
/// in 2D space, with optional timestamp and label for rich data visualization.
///
/// Equality is based on x, y, timestamp, and label. Metadata is excluded
/// from equality comparisons for performance optimization.
///
/// Example:
/// ```dart
/// final point = ChartDataPoint(
///   x: 10.0,
///   y: 20.0,
///   timestamp: DateTime.now(),
///   label: 'Data Point 1',
/// );
/// ```
class ChartDataPoint {
  /// Creates a chart data point with required x and y coordinates.
  ///
  /// [x] and [y] can be NaN or infinity, but use [isValid] to check
  /// for finite values before rendering.
  const ChartDataPoint({
    required this.x,
    required this.y,
    this.timestamp,
    this.label,
    this.metadata,
  });

  /// X-axis value (horizontal position).
  final double x;

  /// Y-axis value (vertical position).
  final double y;

  /// Optional timestamp for time-series data.
  final DateTime? timestamp;

  /// Optional label for tooltips and annotations.
  final String? label;

  /// Optional custom metadata (excluded from equality).
  final Map<String, dynamic>? metadata;

  /// Returns true if this point has a timestamp.
  bool get hasTimestamp => timestamp != null;

  /// Returns true if this point has a label.
  bool get hasLabel => label != null && label!.isNotEmpty;

  /// Returns true if both x and y are finite numbers.
  ///
  /// Points with NaN or infinity values are considered invalid
  /// for rendering purposes.
  bool get isValid => x.isFinite && y.isFinite;

  /// Creates a copy of this point with optional property overrides.
  ///
  /// Example:
  /// ```dart
  /// final modified = point.copyWith(y: 30.0);
  /// ```
  ChartDataPoint copyWith({
    double? x,
    double? y,
    DateTime? timestamp,
    String? label,
    Map<String, dynamic>? metadata,
  }) {
    return ChartDataPoint(
      x: x ?? this.x,
      y: y ?? this.y,
      timestamp: timestamp ?? this.timestamp,
      label: label ?? this.label,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartDataPoint &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          timestamp == other.timestamp &&
          label == other.label;
  // Note: metadata is intentionally excluded from equality

  @override
  int get hashCode => Object.hash(x, y, timestamp, label);

  @override
  String toString() {
    final buffer = StringBuffer('ChartDataPoint(');
    buffer.write('x: $x, y: $y');
    if (hasTimestamp) {
      buffer.write(', timestamp: $timestamp');
    }
    if (hasLabel) {
      buffer.write(', label: "$label"');
    }
    buffer.write(')');
    return buffer.toString();
  }
}
