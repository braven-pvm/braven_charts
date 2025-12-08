// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui';

import 'chart_data_point.dart';
import 'chart_series.dart';

/// Styling override for a line segment.
///
/// When applied to a [ChartDataPoint], this style affects the segment
/// from that point to the next point in the series. This enables
/// per-segment color and stroke width customization.
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
