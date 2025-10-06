/// Line interpolation utilities for smooth curve generation
library;

import 'dart:ui' show Offset, Path;

import 'line_chart_config.dart' show LineStyle;

/// Represents an intermediate point during smooth line interpolation.
///
/// Used internally by LineInterpolator for bezier curve generation.
/// Each point can be either a data point or a control point, with optional
/// bezier control points for smooth curve rendering.
class InterpolatedPoint {
  /// Creates an interpolated point.
  const InterpolatedPoint({
    required this.position,
    this.controlPoint1,
    this.controlPoint2,
    required this.isControlPoint,
  });

  /// The position of this point.
  final Offset position;

  /// The first bezier control point (optional).
  ///
  /// Used for smooth curve interpolation. Null for linear segments.
  final Offset? controlPoint1;

  /// The second bezier control point (optional).
  ///
  /// Used for smooth curve interpolation. Null for linear segments.
  final Offset? controlPoint2;

  /// Whether this is a control point (true) or a data point (false).
  final bool isControlPoint;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InterpolatedPoint &&
        other.position == position &&
        other.controlPoint1 == controlPoint1 &&
        other.controlPoint2 == controlPoint2 &&
        other.isControlPoint == isControlPoint;
  }

  @override
  int get hashCode => Object.hash(
        position,
        controlPoint1,
        controlPoint2,
        isControlPoint,
      );

  @override
  String toString() {
    return 'InterpolatedPoint('
        'position: $position, '
        'controlPoint1: $controlPoint1, '
        'controlPoint2: $controlPoint2, '
        'isControlPoint: $isControlPoint'
        ')';
  }
}

/// Interpolates line paths for different line styles.
///
/// Supports three interpolation modes:
/// - **Straight**: Linear path between points
/// - **Smooth**: Catmull-Rom spline converted to cubic bezier curves
/// - **Stepped**: Horizontal-vertical segments for discrete data
///
/// Implements path caching for performance optimization.
class LineInterpolator {
  /// Creates a line interpolator with the specified style.
  LineInterpolator(this.lineStyle);

  /// The line interpolation style.
  final LineStyle lineStyle;

  /// Cached path from previous interpolation.
  Path? _cachedPath;

  /// Points used for the cached path.
  List<Offset>? _cachedPoints;

  /// Interpolates a path through the given points.
  ///
  /// Returns a cached path if the points haven't changed, otherwise
  /// computes a new path based on the line style.
  Path interpolate(List<Offset> points) {
    // Check cache
    if (_cachedPath != null && _pointsEqual(_cachedPoints, points)) {
      return _cachedPath!;
    }

    // Compute new path
    final path = _createPath(points);

    // Update cache
    _cachedPath = path;
    _cachedPoints = List.from(points);

    return path;
  }

  /// Clears the cached path, forcing recomputation on next interpolate call.
  void clearCache() {
    _cachedPath = null;
    _cachedPoints = null;
  }

  /// Creates a path based on the line style.
  Path _createPath(List<Offset> points) {
    if (points.isEmpty) {
      return Path();
    }

    switch (lineStyle) {
      case LineStyle.straight:
        return _createStraightPath(points);
      case LineStyle.smooth:
        return _createSmoothPath(points);
      case LineStyle.stepped:
        return _createSteppedPath(points);
    }
  }

  /// Creates a straight line path (linear interpolation).
  Path _createStraightPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    return path;
  }

  /// Creates a smooth path using Catmull-Rom to cubic bezier conversion.
  ///
  /// Algorithm from research.md - converts Catmull-Rom spline to cubic bezier
  /// curves for Canvas.drawPath compatibility.
  Path _createSmoothPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points[0].dx, points[0].dy);

    // Need at least 2 points for a curve
    if (points.length < 2) return path;

    // For only 2 points, use straight line
    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }

    // Catmull-Rom to Bezier conversion
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : points[i + 1];

      // Catmull-Rom to Bezier control points
      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    return path;
  }

  /// Creates a stepped path (horizontal then vertical segments).
  ///
  /// Each step consists of a horizontal line followed by a vertical line,
  /// creating a staircase pattern suitable for discrete data.
  Path _createSteppedPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      // Horizontal line to x of next point
      path.lineTo(points[i].dx, points[i - 1].dy);
      // Vertical line to y of next point
      path.lineTo(points[i].dx, points[i].dy);
    }

    return path;
  }

  /// Checks if two point lists are equal.
  bool _pointsEqual(List<Offset>? a, List<Offset>? b) {
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }
}
