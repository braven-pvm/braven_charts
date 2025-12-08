// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui';

import 'chart_data_point.dart';
import 'chart_series.dart';

// =============================================================================
// SegmentStyle - For Line and Area Charts
// =============================================================================

/// Styling override for a line segment.
///
/// When applied to a [ChartDataPoint], this style affects the segment
/// from that point to the next point in the series. This enables
/// per-segment color and stroke width customization.
///
/// **Applies to**: [LineChartSeries], [AreaChartSeries]
///
/// **Rendering behavior**:
/// - Color and strokeWidth override series defaults for this segment only
/// - Null values inherit from series/theme defaults
/// - Style on last point is ignored (no segment follows it)
/// - Bezier curves remain smooth at color boundaries
///
/// **Performance**:
/// - Fast path: Charts without any segment styles use optimized single-path rendering
/// - Batching: Consecutive same-style segments are batched into single draw calls
///
/// Example:
/// ```dart
/// // Highlight a single segment in red
/// ChartDataPoint(
///   x: 10.0,
///   y: 50.0,
///   segmentStyle: SegmentStyle(color: Colors.red, strokeWidth: 3.0),
/// )
///
/// // Using convenience constructor
/// ChartDataPoint(
///   x: 15.0,
///   y: 60.0,
///   segmentStyle: SegmentStyle.color(Colors.orange),
/// )
/// ```
///
/// See also:
/// - [PointStyle] for styling individual points in scatter/bar charts
class SegmentStyle {
  /// Creates a segment style with optional color and stroke width overrides.
  ///
  /// Both parameters are optional. Null values mean "use series default".
  const SegmentStyle({
    this.color,
    this.strokeWidth,
  });

  /// Creates a segment style with only a color override.
  ///
  /// Stroke width will inherit from series default.
  const SegmentStyle.color(Color this.color) : strokeWidth = null;

  /// Creates a segment style with only a stroke width override.
  ///
  /// Color will inherit from series default.
  const SegmentStyle.strokeWidth(double this.strokeWidth) : color = null;

  /// Color override for this segment.
  ///
  /// If null, uses the series color or theme default.
  final Color? color;

  /// Stroke width override for this segment.
  ///
  /// If null, uses the series stroke width or theme default.
  final double? strokeWidth;

  /// Whether this style has any overrides.
  ///
  /// Returns false if both color and strokeWidth are null.
  bool get hasOverrides => color != null || strokeWidth != null;

  /// Creates a copy of this style with the given overrides.
  SegmentStyle copyWith({
    Color? color,
    double? strokeWidth,
    bool clearColor = false,
    bool clearStrokeWidth = false,
  }) {
    return SegmentStyle(
      color: clearColor ? null : (color ?? this.color),
      strokeWidth: clearStrokeWidth ? null : (strokeWidth ?? this.strokeWidth),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SegmentStyle && runtimeType == other.runtimeType && color == other.color && strokeWidth == other.strokeWidth;

  @override
  int get hashCode => Object.hash(color, strokeWidth);

  @override
  String toString() => 'SegmentStyle(color: $color, strokeWidth: $strokeWidth)';
}

// =============================================================================
// PointStyle - For Scatter and Bar Charts
// =============================================================================

/// Styling override for an individual data point.
///
/// When applied to a [ChartDataPoint], this style affects how that specific
/// point is rendered in scatter plots or bar charts. Unlike [SegmentStyle]
/// which affects the segment between points, [PointStyle] affects the
/// visual representation of the point itself.
///
/// **Applies to**: [ScatterChartSeries], [BarChartSeries]
///
/// **Rendering behavior**:
/// - For scatter: Affects the marker color and size at this point
/// - For bar: Affects the bar color and width for this data point
/// - Null values inherit from series/theme defaults
///
/// Example:
/// ```dart
/// // Highlight a specific point in a scatter plot
/// ChartDataPoint(
///   x: 10.0,
///   y: 50.0,
///   pointStyle: PointStyle(color: Colors.red, size: 12.0),
/// )
///
/// // Highlight a bar in a bar chart
/// ChartDataPoint(
///   x: 3.0,
///   y: 75.0,
///   pointStyle: PointStyle.color(Colors.green),
/// )
/// ```
///
/// See also:
/// - [SegmentStyle] for styling line segments in line/area charts
class PointStyle {
  /// Creates a point style with optional color and size overrides.
  ///
  /// Both parameters are optional. Null values mean "use series default".
  const PointStyle({
    this.color,
    this.size,
  });

  /// Creates a point style with only a color override.
  ///
  /// Size will inherit from series default.
  const PointStyle.color(Color this.color) : size = null;

  /// Creates a point style with only a size override.
  ///
  /// Color will inherit from series default.
  const PointStyle.size(double this.size) : color = null;

  /// Color override for this point.
  ///
  /// For scatter: The marker fill color.
  /// For bar: The bar fill color.
  /// If null, uses the series color or theme default.
  final Color? color;

  /// Size override for this point.
  ///
  /// For scatter: The marker radius.
  /// For bar: The bar width (as a multiplier of default width).
  /// If null, uses the series default size.
  final double? size;

  /// Whether this style has any overrides.
  ///
  /// Returns false if both color and size are null.
  bool get hasOverrides => color != null || size != null;

  /// Creates a copy of this style with the given overrides.
  PointStyle copyWith({
    Color? color,
    double? size,
    bool clearColor = false,
    bool clearSize = false,
  }) {
    return PointStyle(
      color: clearColor ? null : (color ?? this.color),
      size: clearSize ? null : (size ?? this.size),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PointStyle && runtimeType == other.runtimeType && color == other.color && size == other.size;

  @override
  int get hashCode => Object.hash(color, size);

  @override
  String toString() => 'PointStyle(color: $color, size: $size)';
}

// =============================================================================
// Extension Methods for LineChartSeries
// =============================================================================

/// Extension methods for applying segment styles to [LineChartSeries].
///
/// These helpers make it easy to create series with segment color overrides
/// without manually constructing each [ChartDataPoint].
///
/// Example:
/// ```dart
/// // Highlight segments 5-7 in red
/// final highlighted = series.withSegmentColors({
///   5: Colors.red,
///   6: Colors.red,
///   7: Colors.red,
/// });
///
/// // Or highlight by condition
/// final thresholdHighlight = series.withColorWhere(
///   (point) => point.y > 100,
///   Colors.orange,
/// );
/// ```
extension SegmentColorExtensions on LineChartSeries {
  /// Returns true if any point has a segment style override.
  ///
  /// This is used internally for fast-path optimization. If no points
  /// have overrides, the series is rendered with a single path call.
  bool get hasSegmentOverrides => points.any((p) => p.segmentStyle != null);

  /// Creates a copy with segment styles at specified indices.
  ///
  /// The index refers to the starting point of the segment. For example,
  /// index 5 styles the segment from points[5] to points[6].
  ///
  /// Indices outside the valid range (0 to length-2) are ignored.
  ///
  /// Example:
  /// ```dart
  /// series.withSegmentStyles({
  ///   5: SegmentStyle.color(Colors.red),
  ///   10: SegmentStyle(color: Colors.green, strokeWidth: 4.0),
  /// });
  /// ```
  LineChartSeries withSegmentStyles(Map<int, SegmentStyle> overrides) {
    if (overrides.isEmpty) return this;

    final newPoints = List<ChartDataPoint>.of(points);
    for (final entry in overrides.entries) {
      final index = entry.key;
      // Valid indices are 0 to length-2 (last point has no following segment)
      if (index >= 0 && index < newPoints.length - 1) {
        newPoints[index] = newPoints[index].copyWith(segmentStyle: entry.value);
      }
    }
    return copyWith(points: newPoints);
  }

  /// Creates a copy with segment colors at specified indices.
  ///
  /// Convenience wrapper around [withSegmentStyles] for color-only overrides.
  ///
  /// Example:
  /// ```dart
  /// series.withSegmentColors({
  ///   5: Colors.red,
  ///   6: Colors.red,  // Consecutive = batched for performance
  ///   10: Colors.green,
  /// });
  /// ```
  LineChartSeries withSegmentColors(Map<int, Color> colors) {
    return withSegmentStyles(
      colors.map((index, color) => MapEntry(index, SegmentStyle.color(color))),
    );
  }

  /// Creates a copy with all segments in X-range styled.
  ///
  /// Applies [style] to all segments where the starting point's X value
  /// is within the range [xStart, xEnd) (inclusive start, exclusive end).
  ///
  /// Example:
  /// ```dart
  /// // Highlight X=10 to X=20 in red
  /// series.withStyleInRange(10.0, 20.0, SegmentStyle.color(Colors.red));
  /// ```
  LineChartSeries withStyleInRange(double xStart, double xEnd, SegmentStyle style) {
    final newPoints = <ChartDataPoint>[];
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final inRange = point.x >= xStart && point.x < xEnd;
      if (inRange && i < points.length - 1) {
        // Only apply to non-last points (which have a following segment)
        newPoints.add(point.copyWith(segmentStyle: style));
      } else {
        newPoints.add(point);
      }
    }
    return copyWith(points: newPoints);
  }

  /// Creates a copy with color applied where condition is true.
  ///
  /// Evaluates [condition] for each point. If true, applies [color] to
  /// the segment starting at that point.
  ///
  /// Example:
  /// ```dart
  /// // Color segments red where Y > 100
  /// series.withColorWhere((point) => point.y > 100, Colors.red);
  ///
  /// // Color based on metadata
  /// series.withColorWhere(
  ///   (point) => point.metadata?['anomaly'] == true,
  ///   Colors.orange,
  /// );
  /// ```
  LineChartSeries withColorWhere(
    bool Function(ChartDataPoint point) condition,
    Color color,
  ) {
    final newPoints = <ChartDataPoint>[];
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      // Only apply to non-last points
      if (condition(point) && i < points.length - 1) {
        newPoints.add(point.copyWith(segmentStyle: SegmentStyle.color(color)));
      } else {
        newPoints.add(point);
      }
    }
    return copyWith(points: newPoints);
  }

  /// Creates a copy with style applied where condition is true.
  ///
  /// More flexible version of [withColorWhere] that allows full style override.
  ///
  /// Example:
  /// ```dart
  /// series.withStyleWhere(
  ///   (point) => point.y > 100,
  ///   SegmentStyle(color: Colors.red, strokeWidth: 4.0),
  /// );
  /// ```
  LineChartSeries withStyleWhere(
    bool Function(ChartDataPoint point) condition,
    SegmentStyle style,
  ) {
    final newPoints = <ChartDataPoint>[];
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      if (condition(point) && i < points.length - 1) {
        newPoints.add(point.copyWith(segmentStyle: style));
      } else {
        newPoints.add(point);
      }
    }
    return copyWith(points: newPoints);
  }

  /// Clears all segment style overrides from the series.
  ///
  /// Returns a copy with all points having null segmentStyle.
  LineChartSeries clearSegmentStyles() {
    final newPoints = points.map((p) => p.copyWith(clearSegmentStyle: true)).toList();
    return copyWith(points: newPoints);
  }
}

// =============================================================================
// Extension Methods for AreaChartSeries
// =============================================================================

/// Extension methods for applying segment styles to [AreaChartSeries].
///
/// Area charts use the same segment concept as line charts - the segment
/// between consecutive points can be styled independently.
extension AreaSegmentColorExtensions on AreaChartSeries {
  /// Returns true if any point has a segment style override.
  bool get hasSegmentOverrides => points.any((p) => p.segmentStyle != null);

  /// Creates a copy with segment styles at specified indices.
  AreaChartSeries withSegmentStyles(Map<int, SegmentStyle> overrides) {
    if (overrides.isEmpty) return this;

    final newPoints = List<ChartDataPoint>.of(points);
    for (final entry in overrides.entries) {
      final index = entry.key;
      if (index >= 0 && index < newPoints.length - 1) {
        newPoints[index] = newPoints[index].copyWith(segmentStyle: entry.value);
      }
    }
    return copyWith(points: newPoints);
  }

  /// Creates a copy with segment colors at specified indices.
  AreaChartSeries withSegmentColors(Map<int, Color> colors) {
    return withSegmentStyles(
      colors.map((index, color) => MapEntry(index, SegmentStyle.color(color))),
    );
  }

  /// Creates a copy with all segments in X-range styled.
  AreaChartSeries withStyleInRange(double xStart, double xEnd, SegmentStyle style) {
    final newPoints = <ChartDataPoint>[];
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final inRange = point.x >= xStart && point.x < xEnd;
      if (inRange && i < points.length - 1) {
        newPoints.add(point.copyWith(segmentStyle: style));
      } else {
        newPoints.add(point);
      }
    }
    return copyWith(points: newPoints);
  }

  /// Creates a copy with color applied where condition is true.
  AreaChartSeries withColorWhere(
    bool Function(ChartDataPoint point) condition,
    Color color,
  ) {
    final newPoints = <ChartDataPoint>[];
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      if (condition(point) && i < points.length - 1) {
        newPoints.add(point.copyWith(segmentStyle: SegmentStyle.color(color)));
      } else {
        newPoints.add(point);
      }
    }
    return copyWith(points: newPoints);
  }

  /// Clears all segment style overrides from the series.
  AreaChartSeries clearSegmentStyles() {
    final newPoints = points.map((p) => p.copyWith(clearSegmentStyle: true)).toList();
    return copyWith(points: newPoints);
  }
}

// =============================================================================
// Extension Methods for ScatterChartSeries
// =============================================================================

/// Extension methods for applying point styles to [ScatterChartSeries].
///
/// Scatter charts display individual points, so styling applies to
/// each point rather than segments between points.
extension ScatterPointStyleExtensions on ScatterChartSeries {
  /// Returns true if any point has a point style override.
  bool get hasPointOverrides => points.any((p) => p.pointStyle != null);

  /// Creates a copy with point styles at specified indices.
  ///
  /// Example:
  /// ```dart
  /// series.withPointStyles({
  ///   5: PointStyle.color(Colors.red),
  ///   10: PointStyle(color: Colors.green, size: 12.0),
  /// });
  /// ```
  ScatterChartSeries withPointStyles(Map<int, PointStyle> overrides) {
    if (overrides.isEmpty) return this;

    final newPoints = List<ChartDataPoint>.of(points);
    for (final entry in overrides.entries) {
      final index = entry.key;
      if (index >= 0 && index < newPoints.length) {
        newPoints[index] = newPoints[index].copyWith(pointStyle: entry.value);
      }
    }
    return copyWith(points: newPoints);
  }

  /// Creates a copy with point colors at specified indices.
  ScatterChartSeries withPointColors(Map<int, Color> colors) {
    return withPointStyles(
      colors.map((index, color) => MapEntry(index, PointStyle.color(color))),
    );
  }

  /// Creates a copy with all points in X-range styled.
  ScatterChartSeries withStyleInRange(double xStart, double xEnd, PointStyle style) {
    final newPoints = <ChartDataPoint>[];
    for (final point in points) {
      final inRange = point.x >= xStart && point.x < xEnd;
      if (inRange) {
        newPoints.add(point.copyWith(pointStyle: style));
      } else {
        newPoints.add(point);
      }
    }
    return copyWith(points: newPoints);
  }

  /// Creates a copy with color applied where condition is true.
  ScatterChartSeries withColorWhere(
    bool Function(ChartDataPoint point) condition,
    Color color,
  ) {
    final newPoints = points.map((point) {
      if (condition(point)) {
        return point.copyWith(pointStyle: PointStyle.color(color));
      }
      return point;
    }).toList();
    return copyWith(points: newPoints);
  }

  /// Clears all point style overrides from the series.
  ScatterChartSeries clearPointStyles() {
    final newPoints = points.map((p) => p.copyWith(clearPointStyle: true)).toList();
    return copyWith(points: newPoints);
  }
}

// =============================================================================
// Extension Methods for BarChartSeries
// =============================================================================

/// Extension methods for applying point styles to [BarChartSeries].
///
/// Bar charts display individual bars for each data point, so styling
/// applies to each bar rather than segments between points.
extension BarPointStyleExtensions on BarChartSeries {
  /// Returns true if any point has a point style override.
  bool get hasPointOverrides => points.any((p) => p.pointStyle != null);

  /// Creates a copy with point styles at specified indices.
  ///
  /// Example:
  /// ```dart
  /// series.withPointStyles({
  ///   2: PointStyle.color(Colors.red),  // Third bar is red
  ///   5: PointStyle.color(Colors.green),
  /// });
  /// ```
  BarChartSeries withPointStyles(Map<int, PointStyle> overrides) {
    if (overrides.isEmpty) return this;

    final newPoints = List<ChartDataPoint>.of(points);
    for (final entry in overrides.entries) {
      final index = entry.key;
      if (index >= 0 && index < newPoints.length) {
        newPoints[index] = newPoints[index].copyWith(pointStyle: entry.value);
      }
    }
    return copyWith(points: newPoints);
  }

  /// Creates a copy with point colors at specified indices.
  BarChartSeries withPointColors(Map<int, Color> colors) {
    return withPointStyles(
      colors.map((index, color) => MapEntry(index, PointStyle.color(color))),
    );
  }

  /// Creates a copy with all bars in X-range styled.
  BarChartSeries withStyleInRange(double xStart, double xEnd, PointStyle style) {
    final newPoints = <ChartDataPoint>[];
    for (final point in points) {
      final inRange = point.x >= xStart && point.x < xEnd;
      if (inRange) {
        newPoints.add(point.copyWith(pointStyle: style));
      } else {
        newPoints.add(point);
      }
    }
    return copyWith(points: newPoints);
  }

  /// Creates a copy with color applied where condition is true.
  ///
  /// Example:
  /// ```dart
  /// // Highlight bars above threshold
  /// series.withColorWhere((point) => point.y > 100, Colors.red);
  /// ```
  BarChartSeries withColorWhere(
    bool Function(ChartDataPoint point) condition,
    Color color,
  ) {
    final newPoints = points.map((point) {
      if (condition(point)) {
        return point.copyWith(pointStyle: PointStyle.color(color));
      }
      return point;
    }).toList();
    return copyWith(points: newPoints);
  }

  /// Clears all point style overrides from the series.
  BarChartSeries clearPointStyles() {
    final newPoints = points.map((p) => p.copyWith(clearPointStyle: true)).toList();
    return copyWith(points: newPoints);
  }
}
