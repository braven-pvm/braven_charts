// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'segment_style.dart';

/// Represents a single (x, y) coordinate with optional metadata.
///
/// ChartDataPoint is an immutable data structure representing a point
/// in 2D space, with optional timestamp and label for rich data visualization.
///
/// Equality is based on x, y, timestamp, label, segmentStyle, and pointStyle.
/// Metadata is excluded from equality comparisons for performance optimization.
///
/// Example:
/// ```dart
/// final point = ChartDataPoint(
///   x: 10.0,
///   y: 20.0,
///   timestamp: DateTime.now(),
///   label: 'Data Point 1',
/// );
///
/// // With segment style override (for line/area charts)
/// final linePoint = ChartDataPoint(
///   x: 15.0,
///   y: 25.0,
///   segmentStyle: SegmentStyle.color(Colors.red),
/// );
///
/// // With point style override (for scatter/bar charts)
/// final scatterPoint = ChartDataPoint(
///   x: 20.0,
///   y: 30.0,
///   pointStyle: PointStyle.color(Colors.green),
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
    this.segmentStyle,
    this.pointStyle,
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

  /// Optional style override for the segment starting at this point.
  ///
  /// This affects the line segment from this point to the next point
  /// in the series. If null, the series default style is used.
  ///
  /// **Important**: Setting this on the last point in a series has no
  /// effect, as there is no segment following the last point.
  ///
  /// **Performance**: Charts detect if any points have segment styles.
  /// If none do, rendering uses an optimized single-path code path.
  ///
  /// Example:
  /// ```dart
  /// // Highlight segment from this point to the next in red
  /// ChartDataPoint(
  ///   x: 5.0,
  ///   y: 10.0,
  ///   segmentStyle: SegmentStyle.color(Colors.red),
  /// )
  /// ```
  final SegmentStyle? segmentStyle;

  /// Optional style override for this specific point.
  ///
  /// This affects how the point itself is rendered in scatter plots
  /// or bar charts. Unlike [segmentStyle] which affects the line between
  /// points, [pointStyle] affects the visual representation of this point.
  ///
  /// **Applies to**: [ScatterChartSeries], [BarChartSeries]
  ///
  /// **Performance**: Charts detect if any points have point styles.
  /// If none do, rendering uses an optimized single-color code path.
  ///
  /// Example:
  /// ```dart
  /// // Highlight this scatter point in red with larger size
  /// ChartDataPoint(
  ///   x: 5.0,
  ///   y: 10.0,
  ///   pointStyle: PointStyle(color: Colors.red, size: 12.0),
  /// )
  /// ```
  final PointStyle? pointStyle;

  /// Returns true if this point has a timestamp.
  bool get hasTimestamp => timestamp != null;

  /// Returns true if this point has a label.
  bool get hasLabel => label != null && label!.isNotEmpty;

  /// Returns true if this point has a segment style override.
  bool get hasSegmentStyle => segmentStyle != null;

  /// Returns true if this point has a point style override.
  bool get hasPointStyle => pointStyle != null;

  /// Returns true if both x and y are finite numbers.
  ///
  /// Points with NaN or infinity values are considered invalid
  /// for rendering purposes.
  bool get isValid => x.isFinite && y.isFinite;

  /// Creates a copy of this point with optional property overrides.
  ///
  /// Use [clearSegmentStyle] to explicitly remove a segment style.
  /// Use [clearPointStyle] to explicitly remove a point style.
  ///
  /// Example:
  /// ```dart
  /// final modified = point.copyWith(y: 30.0);
  /// final highlighted = point.copyWith(segmentStyle: SegmentStyle.color(Colors.red));
  /// final cleared = point.copyWith(clearSegmentStyle: true);
  /// ```
  ChartDataPoint copyWith({
    double? x,
    double? y,
    DateTime? timestamp,
    String? label,
    Map<String, dynamic>? metadata,
    SegmentStyle? segmentStyle,
    bool clearSegmentStyle = false,
    PointStyle? pointStyle,
    bool clearPointStyle = false,
  }) {
    return ChartDataPoint(
      x: x ?? this.x,
      y: y ?? this.y,
      timestamp: timestamp ?? this.timestamp,
      label: label ?? this.label,
      metadata: metadata ?? this.metadata,
      segmentStyle:
          clearSegmentStyle ? null : (segmentStyle ?? this.segmentStyle),
      pointStyle: clearPointStyle ? null : (pointStyle ?? this.pointStyle),
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
          label == other.label &&
          segmentStyle == other.segmentStyle &&
          pointStyle == other.pointStyle;
  // Note: metadata is intentionally excluded from equality

  @override
  int get hashCode =>
      Object.hash(x, y, timestamp, label, segmentStyle, pointStyle);

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
    if (hasSegmentStyle) {
      buffer.write(', segmentStyle: $segmentStyle');
    }
    if (hasPointStyle) {
      buffer.write(', pointStyle: $pointStyle');
    }
    buffer.write(')');
    return buffer.toString();
  }
}
