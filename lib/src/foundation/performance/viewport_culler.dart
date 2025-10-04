// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/src/foundation/data_models/data_range.dart' as dr;

/// Efficiently filters data points to visible viewport region.
///
/// ViewportCuller uses spatial filtering to include only points within the
/// visible viewport plus a configurable margin. It optimizes performance by
/// using binary search for x-ordered data.
///
/// Example:
/// ```dart
/// final culler = ViewportCuller(margin: 0.1);
/// final visible = culler.cull(
///   points: allPoints,
///   viewportX: dr.DataRange(min: 0.0, max: 100.0),
///   viewportY: dr.DataRange(min: 0.0, max: 50.0),
///   isXOrdered: true,
/// );
/// ```
///
/// Performance:
/// - Ordered data: O(log n + m) where m = visible points
/// - Unordered data: O(n)
/// - <1ms for 10,000 points (FR-005.4)
class ViewportCuller {
  /// Margin added to viewport (as fraction of range)
  ///
  /// Example: margin = 0.1 adds 10% padding on each side
  final double margin;

  /// Creates a viewport culler with specified margin.
  ///
  /// [margin]: Fraction of viewport to add as padding (default: 0.1)
  const ViewportCuller({this.margin = 0.1}) : assert(margin >= 0.0, 'margin must be non-negative');

  /// Filters points to those visible within the viewport plus margin.
  ///
  /// [points]: All data points to filter
  /// [viewportX]: Visible x-axis range
  /// [viewportY]: Visible y-axis range
  /// [isXOrdered]: True if points are sorted by x-value (enables optimization)
  ///
  /// Returns: List of points within the effective viewport bounds
  ///
  /// Performance: <1ms for 10,000 points (FR-005.4)
  List<ChartDataPoint> cull({
    required List<ChartDataPoint> points,
    required dr.DataRange viewportX,
    required dr.DataRange viewportY,
    required bool isXOrdered,
  }) {
    if (points.isEmpty) return [];

    // Calculate effective bounds with margin
    final bounds = calculateBounds(
      viewportX: viewportX,
      viewportY: viewportY,
    );

    if (isXOrdered) {
      return _cullOrdered(points, bounds);
    } else {
      return _cullUnordered(points, bounds);
    }
  }

  /// Calculates effective viewport bounds with margin applied.
  ///
  /// [viewportX]: Original x-axis viewport
  /// [viewportY]: Original y-axis viewport
  ///
  /// Returns: Viewport bounds expanded by margin
  ViewportBounds calculateBounds({
    required dr.DataRange viewportX,
    required dr.DataRange viewportY,
  }) {
    // Apply margin as padding
    final xRange = dr.DataRange(
      min: viewportX.min,
      max: viewportX.max,
      padding: margin,
    );
    final yRange = dr.DataRange(
      min: viewportY.min,
      max: viewportY.max,
      padding: margin,
    );

    return ViewportBounds(xRange: xRange, yRange: yRange);
  }

  /// Cull ordered data using binary search (O(log n + m))
  List<ChartDataPoint> _cullOrdered(
    List<ChartDataPoint> points,
    ViewportBounds bounds,
  ) {
    // Find first point within x-range using binary search
    final startIndex = _binarySearchStart(
      points,
      bounds.xRange.paddedMin,
    );

    if (startIndex == -1) return [];

    // Collect points until we exit x-range
    final result = <ChartDataPoint>[];
    final maxX = bounds.xRange.paddedMax;
    final minY = bounds.yRange.paddedMin;
    final maxY = bounds.yRange.paddedMax;

    for (var i = startIndex; i < points.length; i++) {
      final point = points[i];

      // Early exit when we pass the x-range
      if (point.x > maxX) break;

      // Check y-range
      if (point.y >= minY && point.y <= maxY) {
        result.add(point);
      }
    }

    return result;
  }

  /// Cull unordered data with linear scan (O(n))
  List<ChartDataPoint> _cullUnordered(
    List<ChartDataPoint> points,
    ViewportBounds bounds,
  ) {
    return points.where((point) => bounds.contains(point)).toList();
  }

  /// Binary search for first point >= target x-value
  ///
  /// Returns index of first point with x >= target, or -1 if none found
  int _binarySearchStart(List<ChartDataPoint> points, double target) {
    if (points.isEmpty) return -1;

    int left = 0;
    int right = points.length - 1;
    int result = -1;

    while (left <= right) {
      final mid = (left + right) ~/ 2;
      final midX = points[mid].x;

      if (midX >= target) {
        result = mid;
        right = mid - 1; // Look for earlier match
      } else {
        left = mid + 1;
      }
    }

    return result;
  }

  @override
  String toString() => 'ViewportCuller(margin: $margin)';
}

/// Viewport bounds with margin applied.
///
/// Represents the effective culling region including padding.
class ViewportBounds {
  /// X-axis range with margin
  final dr.DataRange xRange;

  /// Y-axis range with margin
  final dr.DataRange yRange;

  const ViewportBounds({
    required this.xRange,
    required this.yRange,
  });

  /// Checks if a point is within the bounds.
  ///
  /// Uses paddedMin/paddedMax to include margin.
  bool contains(ChartDataPoint point) {
    return point.x >= xRange.paddedMin && point.x <= xRange.paddedMax && point.y >= yRange.paddedMin && point.y <= yRange.paddedMax;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ViewportBounds && runtimeType == other.runtimeType && xRange == other.xRange && yRange == other.yRange;

  @override
  int get hashCode => Object.hash(xRange, yRange);

  @override
  String toString() => 'ViewportBounds(x: $xRange, y: $yRange)';
}
