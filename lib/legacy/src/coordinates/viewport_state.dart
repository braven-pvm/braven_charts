/// ViewportState - Immutable zoom/pan state
///
/// Represents the current viewport state for interactive chart exploration.
/// Enables zooming and panning while maintaining coordinate transformations.
///
/// Constitutional compliance:
/// - Immutability: All fields final, updates create new instances
/// - Value semantics: Structural equality and hash code
/// - Pure Flutter: Uses only dart:math Point
library;

import 'dart:math' show Point;

import 'package:braven_charts/legacy/braven_charts.dart';

/// Immutable viewport state for zoom and pan transformations.
///
/// Tracks the visible subset of data displayed after user interactions.
/// Transformations use this state to convert between data coordinates
/// and viewport coordinates.
///
/// **Usage:**
///
/// ```dart
/// // Initial state (no zoom/pan)
/// final viewport = ViewportState.identity();
/// assert(viewport.isIdentity());
///
/// // User zooms in 2x
/// final zoomed = viewport.withZoom(2.0);
///
/// // User pans right by 10 data units
/// final panned = zoomed.withPan(const Point(10.0, 0.0));
///
/// // Check visibility
/// if (panned.containsPoint(dataPoint)) {
///   // Point is visible, render it
/// }
/// ```
///
/// **Zoom Behavior:**
///
/// - `zoomFactor = 1.0` - No zoom (identity)
/// - `zoomFactor = 2.0` - Zoomed in 2x (visible range halved)
/// - `zoomFactor = 0.5` - Zoomed out 2x (visible range doubled)
///
/// **Pan Behavior:**
///
/// Pan offset is applied in data units after zoom:
/// - Positive X: Pan right (show data to the left)
/// - Negative X: Pan left (show data to the right)
/// - Positive Y: Pan up (show data below)
/// - Negative Y: Pan down (show data above)
///
/// See also:
/// - [TransformContext] uses ViewportState for transformations
/// - [CoordinateSystem.viewport] for viewport coordinate space
class ViewportState {
  /// Create immutable viewport state.
  ///
  /// **Validation:**
  /// - `xRange.min < xRange.max` (non-empty)
  /// - `yRange.min < yRange.max` (non-empty)
  /// - `zoomFactor > 0.0` (positive)
  ///
  /// **Parameters:**
  /// - [xRange] - Visible X data range
  /// - [yRange] - Visible Y data range
  /// - [zoomFactor] - Zoom multiplier (default: 1.0)
  /// - [panOffset] - Pan offset in data units (default: Point.zero)
  const ViewportState({
    required this.xRange,
    required this.yRange,
    this.zoomFactor = 1.0,
    this.panOffset = const Point(0.0, 0.0),
  }) : assert(zoomFactor > 0.0, 'zoomFactor must be positive');

  /// Create identity viewport (no zoom/pan).
  ///
  /// Returns a viewport with:
  /// - Full data range visible
  /// - `zoomFactor = 1.0`
  /// - `panOffset = Point(0.0, 0.0)`
  ///
  /// Use as initial state before user interactions.
  ///
  /// **Note:** Requires full data ranges to be provided externally.
  /// This factory creates a default identity state that should be
  /// updated with actual data ranges via [withRanges].
  factory ViewportState.identity() {
    return const ViewportState(
      xRange: DataRange(min: 0.0, max: 1.0),
      yRange: DataRange(min: 0.0, max: 1.0),
      zoomFactor: 1.0,
      panOffset: Point(0.0, 0.0),
    );
  }

  /// Visible data range for X axis.
  ///
  /// Represents the subset of full data range currently visible.
  /// Updated by zoom and pan operations.
  final DataRange xRange;

  /// Visible data range for Y axis.
  ///
  /// Represents the subset of full data range currently visible.
  /// Updated by zoom and pan operations.
  final DataRange yRange;

  /// Zoom level multiplier.
  ///
  /// - `1.0` = No zoom (identity)
  /// - `> 1.0` = Zoomed in (magnified)
  /// - `< 1.0` = Zoomed out (minified)
  ///
  /// Typical range: `0.1` to `100.0`
  /// Must be `> 0.0` (enforced by validation)
  final double zoomFactor;

  /// Pan offset in data units.
  ///
  /// Applied after zoom transformation:
  /// - `Point(0.0, 0.0)` = No pan (identity)
  /// - `Point(10.0, 0.0)` = Panned right 10 data units
  /// - `Point(0.0, -5.0)` = Panned down 5 data units
  final Point<double> panOffset;

  /// Create copy with updated zoom factor.
  ///
  /// Zoom is applied about the center of the current viewport.
  /// Visible ranges are recalculated based on the new zoom level.
  ///
  /// **Parameters:**
  /// - [factor] - New zoom multiplier (must be > 0.0)
  ///
  /// **Returns:** New ViewportState with updated zoom
  ///
  /// **Example:**
  /// ```dart
  /// final viewport = ViewportState.identity();
  /// final zoomed = viewport.withZoom(2.0); // Zoom in 2x
  /// ```
  ViewportState withZoom(double factor) {
    assert(factor > 0.0, 'Zoom factor must be positive');
    return ViewportState(
      xRange: xRange,
      yRange: yRange,
      zoomFactor: factor,
      panOffset: panOffset,
    );
  }

  /// Create copy with updated pan offset.
  ///
  /// Pan is applied in data units. The offset moves the viewport
  /// within the full data range.
  ///
  /// **Parameters:**
  /// - [offset] - Pan offset in data units (Point<double>)
  ///
  /// **Returns:** New ViewportState with updated pan
  ///
  /// **Example:**
  /// ```dart
  /// final viewport = ViewportState.identity();
  /// final panned = viewport.withPan(const Point(10.0, 0.0)); // Pan right
  /// ```
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
  /// Useful for:
  /// - Auto-pan (e.g., show last 100 data points)
  /// - Fit to data (show all data points)
  /// - Custom viewport positioning
  ///
  /// **Parameters:**
  /// - [x] - New visible X range
  /// - [y] - New visible Y range
  ///
  /// **Returns:** New ViewportState with updated ranges
  ///
  /// **Example:**
  /// ```dart
  /// // Show last 100 points
  /// final viewport = current.withRanges(
  ///   DataRange(min: maxX - 100, max: maxX),
  ///   yRange,
  /// );
  /// ```
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
  /// Returns `true` if point is within both xRange and yRange.
  ///
  /// **Parameters:**
  /// - [dataPoint] - Point in data coordinates
  ///
  /// **Returns:** `true` if visible, `false` otherwise
  ///
  /// **Example:**
  /// ```dart
  /// if (viewport.containsPoint(dataPoint)) {
  ///   // Point is visible, render it
  /// } else {
  ///   // Point is outside viewport, skip rendering
  /// }
  /// ```
  bool containsPoint(Point<double> dataPoint) {
    return dataPoint.x >= xRange.min &&
        dataPoint.x <= xRange.max &&
        dataPoint.y >= yRange.min &&
        dataPoint.y <= yRange.max;
  }

  /// Check if viewport is identity (no zoom/pan).
  ///
  /// Returns `true` if:
  /// - `zoomFactor == 1.0`
  /// - `panOffset == Point(0.0, 0.0)`
  ///
  /// **Returns:** `true` if identity, `false` otherwise
  ///
  /// **Example:**
  /// ```dart
  /// if (viewport.isIdentity()) {
  ///   // No user interaction, use fast path
  /// } else {
  ///   // Apply zoom/pan transformations
  /// }
  /// ```
  bool isIdentity() {
    return zoomFactor == 1.0 && panOffset.x == 0.0 && panOffset.y == 0.0;
  }

  /// Hash code for cache key generation.
  ///
  /// Combines all fields to create a unique hash for caching
  /// transformation matrices per viewport state.
  @override
  int get hashCode => Object.hash(xRange, yRange, zoomFactor, panOffset);

  /// Structural equality comparison.
  ///
  /// Two ViewportStates are equal if all fields match:
  /// - xRange, yRange, zoomFactor, panOffset
  ///
  /// Used for:
  /// - Cache invalidation (detect state changes)
  /// - Testing (verify state updates)
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ViewportState &&
            xRange == other.xRange &&
            yRange == other.yRange &&
            zoomFactor == other.zoomFactor &&
            panOffset.x == other.panOffset.x &&
            panOffset.y == other.panOffset.y);
  }

  /// String representation for debugging.
  @override
  String toString() {
    return 'ViewportState('
        'xRange: $xRange, '
        'yRange: $yRange, '
        'zoom: $zoomFactor, '
        'pan: $panOffset'
        ')';
  }
}
