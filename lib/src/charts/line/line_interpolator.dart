/// Line interpolation utilities for smooth curve generation
library;

import 'dart:ui' show Offset;

/// Represents an intermediate point during smooth line interpolation.
///
/// Used internally by LineInterpolator for bezier curve generation.
/// Each point can be either a data point or a control point, with optional
/// bezier control points for smooth curve rendering.
class InterpolatedPoint {
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

  /// Creates an interpolated point.
  const InterpolatedPoint({
    required this.position,
    this.controlPoint1,
    this.controlPoint2,
    required this.isControlPoint,
  });

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
