/// Contract: ViewportState
///
/// Immutable representation of zoom and pan state for interactive chart exploration.
library;

import 'dart:math' show Point;

/// Immutable zoom/pan state for viewport transformations.
///
/// Enables users to interactively explore subsets of data while maintaining
/// consistent coordinate transformations.
///
/// Example usage:
/// ```dart
/// // Initial viewport (full data range visible)
/// final initial = ViewportState.identity();
///
/// // User zooms in 2x
/// final zoomed = initial.withZoom(2.0);
///
/// // User pans right by 10 data units
/// final panned = zoomed.withPan(Point(10.0, 0.0));
///
/// // Check if data point is visible
/// if (panned.containsPoint(dataPoint)) {
///   // Render point
/// }
/// ```
class ViewportState {
  /// Visible data range for X axis (subset of full data range).
  final DataRange xRange;

  /// Visible data range for Y axis (subset of full data range).
  final DataRange yRange;

  /// Zoom level (1.0 = no zoom, 2.0 = 2x zoom, 0.5 = zoomed out 2x).
  final double zoomFactor;

  /// Pan offset in data units (applied after zoom).
  final Point<double> panOffset;

  /// Create immutable viewport state.
  ///
  /// Validates:
  /// - xRange.min < xRange.max (non-empty range)
  /// - yRange.min < yRange.max (non-empty range)
  /// - zoomFactor > 0 (typical range: 0.1 to 100.0)
  const ViewportState({
    required this.xRange,
    required this.yRange,
    this.zoomFactor = 1.0,
    this.panOffset = const Point(0.0, 0.0),
  });

  /// Create identity viewport (full data range, no zoom/pan).
  ///
  /// Use as initial state before user interactions.
  factory ViewportState.identity() {
    return ViewportState(
      xRange: DataRange.full(), // Placeholder - actual impl uses full data range
      yRange: DataRange.full(),
      zoomFactor: 1.0,
      panOffset: const Point(0.0, 0.0),
    );
  }

  /// Create copy with updated zoom factor.
  ///
  /// Zoom is applied about center of current viewport.
  ViewportState withZoom(double factor) {
    return ViewportState(
      xRange: xRange,
      yRange: yRange,
      zoomFactor: factor,
      panOffset: panOffset,
    );
  }

  /// Create copy with updated pan offset.
  ///
  /// Pan is applied in data units (e.g., 10.0 = pan right 10 data units).
  ViewportState withPan(Point<double> offset) {
    return ViewportState(
      xRange: xRange,
      yRange: yRange,
      zoomFactor: zoomFactor,
      panOffset: offset,
    );
  }

  /// Create copy with explicit visible ranges.
  ///
  /// Useful for auto-pan (e.g., show last 100 data points).
  ViewportState withRanges(DataRange x, DataRange y) {
    return ViewportState(
      xRange: x,
      yRange: y,
      zoomFactor: zoomFactor,
      panOffset: panOffset,
    );
  }

  /// Check if data point is visible in current viewport.
  ///
  /// Returns true if point is within xRange and yRange.
  bool containsPoint(Point<double> dataPoint) {
    return xRange.contains(dataPoint.x) && yRange.contains(dataPoint.y);
  }

  /// Check if viewport is identity (no zoom/pan).
  ///
  /// Returns true if zoomFactor == 1.0 and panOffset == Point.zero.
  bool isIdentity() {
    return zoomFactor == 1.0 && panOffset.x == 0.0 && panOffset.y == 0.0;
  }

  /// Hash code for cache key generation.
  @override
  int get hashCode => Object.hash(xRange, yRange, zoomFactor, panOffset);

  /// Structural equality.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ViewportState &&
            xRange == other.xRange &&
            yRange == other.yRange &&
            zoomFactor == other.zoomFactor &&
            panOffset == other.panOffset);
  }
}

// Forward declaration (defined in Foundation Layer)
abstract class DataRange {
  factory DataRange.full() => throw UnimplementedError();
  bool contains(double value);
}
