// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import '../data_models/chart_data_point.dart';

/// Interpolation functions for smooth curves between data points.
///
/// Supports linear, cubic spline, Hermite, Catmull-Rom, and Bezier interpolation.
///
/// Performance: <1ms for 1000 samples, <10ms for complex splines (FR-004.2)
///
/// Example:
/// ```dart
/// // Linear interpolation
/// final mid = InterpolationFunctions.lerp(0.0, 10.0, 0.5); // 5.0
///
/// // Cubic spline through points
/// final points = [
///   ChartDataPoint(x: 0.0, y: 0.0),
///   ChartDataPoint(x: 1.0, y: 2.0),
///   ChartDataPoint(x: 2.0, y: 1.0),
/// ];
/// final curve = InterpolationFunctions.cubicSpline(points, 50);
/// ```
class InterpolationFunctions {
  // Prevent instantiation
  InterpolationFunctions._();

  // ==================== Linear Interpolation ====================

  /// Linear interpolate between a and b.
  ///
  /// t should be in [0, 1] range:
  /// - t=0 returns a
  /// - t=0.5 returns midpoint
  /// - t=1 returns b
  ///
  /// Works outside [0, 1] for extrapolation.
  /// Performance: O(1)
  static double lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  /// Inverse linear interpolation.
  ///
  /// Find t such that lerp(a, b, t) == value.
  /// Returns 0.0 if a == b (undefined).
  ///
  /// Performance: O(1)
  static double lerpInverse(double a, double b, double value) {
    if (a == b) return 0.0;
    return (value - a) / (b - a);
  }

  // ==================== Cubic Spline ====================

  /// Generate cubic spline interpolation.
  ///
  /// Returns list of sampled y-values at evenly-spaced x positions.
  /// Uses natural cubic spline (zero curvature at endpoints).
  ///
  /// Algorithm:
  /// 1. Solve tridiagonal system for second derivatives
  /// 2. Evaluate spline segments using cubic polynomials
  ///
  /// Requires at least 2 points.
  /// Returns empty list for invalid input.
  ///
  /// Performance: O(n + samples) where n = number of points
  static List<double> cubicSpline(
    List<ChartDataPoint> points,
    int samples,
  ) {
    if (points.length < 2 || samples < 2) {
      return [];
    }

    // Sort points by x coordinate
    final sortedPoints = List<ChartDataPoint>.from(points)
      ..sort((a, b) => a.x.compareTo(b.x));

    // Calculate second derivatives using Thomas algorithm
    final secondDerivatives = _calculateSecondDerivatives(sortedPoints);

    // Sample the spline
    final result = <double>[];
    final xMin = sortedPoints.first.x;
    final xMax = sortedPoints.last.x;
    final xStep = (xMax - xMin) / (samples - 1);

    for (int i = 0; i < samples; i++) {
      final x = xMin + i * xStep;
      final y = _evaluateSpline(sortedPoints, secondDerivatives, x);
      result.add(y);
    }

    return result;
  }

  /// Calculate second derivatives for natural cubic spline.
  /// Uses Thomas algorithm to solve tridiagonal system.
  static List<double> _calculateSecondDerivatives(List<ChartDataPoint> points) {
    final n = points.length;
    final h = List<double>.filled(n - 1, 0.0);
    final alpha = List<double>.filled(n, 0.0);
    final l = List<double>.filled(n, 0.0);
    final mu = List<double>.filled(n, 0.0);
    final z = List<double>.filled(n, 0.0);
    final c = List<double>.filled(n, 0.0);

    // Calculate h values (x differences)
    for (int i = 0; i < n - 1; i++) {
      h[i] = points[i + 1].x - points[i].x;
    }

    // Calculate alpha values
    for (int i = 1; i < n - 1; i++) {
      alpha[i] = (3.0 / h[i]) * (points[i + 1].y - points[i].y) -
          (3.0 / h[i - 1]) * (points[i].y - points[i - 1].y);
    }

    // Solve tridiagonal system (Thomas algorithm forward elimination)
    l[0] = 1.0;
    mu[0] = 0.0;
    z[0] = 0.0;

    for (int i = 1; i < n - 1; i++) {
      l[i] = 2.0 * (points[i + 1].x - points[i - 1].x) - h[i - 1] * mu[i - 1];
      mu[i] = h[i] / l[i];
      z[i] = (alpha[i] - h[i - 1] * z[i - 1]) / l[i];
    }

    l[n - 1] = 1.0;
    z[n - 1] = 0.0;
    c[n - 1] = 0.0;

    // Back substitution
    for (int j = n - 2; j >= 0; j--) {
      c[j] = z[j] - mu[j] * c[j + 1];
    }

    return c;
  }

  /// Evaluate cubic spline at given x position.
  static double _evaluateSpline(
    List<ChartDataPoint> points,
    List<double> secondDerivatives,
    double x,
  ) {
    final n = points.length;

    // Find interval containing x
    int i = 0;
    for (i = 0; i < n - 1; i++) {
      if (x <= points[i + 1].x) break;
    }
    if (i == n - 1) i = n - 2; // Clamp to last interval

    final h = points[i + 1].x - points[i].x;
    final a = (points[i + 1].x - x) / h;
    final b = (x - points[i].x) / h;

    final y = a * points[i].y +
        b * points[i + 1].y +
        ((a * a * a - a) * secondDerivatives[i] +
                (b * b * b - b) * secondDerivatives[i + 1]) *
            (h * h) /
            6.0;

    return y;
  }

  // ==================== Hermite Interpolation ====================

  /// Hermite interpolation with explicit tangents.
  ///
  /// p0, p1: endpoint values
  /// m0, m1: tangent vectors at endpoints
  /// t: parameter in [0, 1]
  ///
  /// Uses cubic Hermite polynomial:
  /// h(t) = h00(t)×p0 + h10(t)×m0 + h01(t)×p1 + h11(t)×m1
  ///
  /// Performance: O(1)
  static double hermite(
    double p0,
    double p1,
    double m0,
    double m1,
    double t,
  ) {
    final t2 = t * t;
    final t3 = t2 * t;

    // Hermite basis functions
    final h00 = 2 * t3 - 3 * t2 + 1;
    final h10 = t3 - 2 * t2 + t;
    final h01 = -2 * t3 + 3 * t2;
    final h11 = t3 - t2;

    return h00 * p0 + h10 * m0 + h01 * p1 + h11 * m1;
  }

  // ==================== Catmull-Rom Spline ====================

  /// Catmull-Rom spline (auto-computed tangents).
  ///
  /// Generates smooth curve through all control points.
  /// Tangents are automatically computed from neighboring points.
  ///
  /// Requires at least 4 points for proper curve.
  /// tension: 0.0 = loose, 1.0 = tight (default 0.5)
  ///
  /// Returns empty list for invalid input.
  /// Performance: O(points × samples)
  static List<double> catmullRom(
    List<ChartDataPoint> points,
    int samples, {
    double tension = 0.5,
  }) {
    if (points.length < 4 || samples < 2) {
      return [];
    }

    final result = <double>[];
    final n = points.length;
    final segmentSamples = samples ~/ (n - 3);

    // Interpolate between each pair of interior points
    for (int i = 1; i < n - 2; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = points[i + 2];

      // Calculate tangents
      final m1 = (1.0 - tension) * (p2.y - p0.y) / 2.0;
      final m2 = (1.0 - tension) * (p3.y - p1.y) / 2.0;

      // Sample this segment
      for (int j = 0; j < segmentSamples; j++) {
        final t = j / segmentSamples;
        final y = hermite(p1.y, p2.y, m1, m2, t);
        result.add(y);
      }
    }

    // Add final point
    result.add(points[n - 2].y);

    return result;
  }

  // ==================== Bezier Curves ====================

  /// Generic Bezier curve (arbitrary degree).
  ///
  /// controlPoints: list of control point values
  /// t: parameter in [0, 1]
  ///
  /// Uses De Casteljau's algorithm for numerical stability.
  ///
  /// Performance: O(n²) where n = number of control points
  static double bezier(List<double> controlPoints, double t) {
    if (controlPoints.isEmpty) return 0.0;
    if (controlPoints.length == 1) return controlPoints[0];

    // De Casteljau's algorithm
    final points = List<double>.from(controlPoints);

    for (int r = 1; r < controlPoints.length; r++) {
      for (int i = 0; i < controlPoints.length - r; i++) {
        points[i] = (1.0 - t) * points[i] + t * points[i + 1];
      }
    }

    return points[0];
  }

  /// Quadratic Bezier curve (3 control points).
  ///
  /// More efficient than generic bezier() for degree 2.
  /// Uses explicit formula: B(t) = (1-t)²p0 + 2(1-t)t×p1 + t²p2
  ///
  /// Returns list of sampled y-values.
  /// Performance: O(samples)
  static List<double> quadraticBezier(
    double p0,
    double p1,
    double p2,
    int samples,
  ) {
    if (samples < 2) return [];

    final result = <double>[];
    for (int i = 0; i < samples; i++) {
      final t = i / (samples - 1);
      final oneMinusT = 1.0 - t;
      final y =
          oneMinusT * oneMinusT * p0 + 2.0 * oneMinusT * t * p1 + t * t * p2;
      result.add(y);
    }

    return result;
  }

  /// Cubic Bezier curve (4 control points).
  ///
  /// More efficient than generic bezier() for degree 3.
  /// Uses explicit formula:
  /// B(t) = (1-t)³p0 + 3(1-t)²t×p1 + 3(1-t)t²p2 + t³p3
  ///
  /// Returns list of sampled y-values.
  /// Performance: O(samples)
  static List<double> cubicBezier(
    double p0,
    double p1,
    double p2,
    double p3,
    int samples,
  ) {
    if (samples < 2) return [];

    final result = <double>[];
    for (int i = 0; i < samples; i++) {
      final t = i / (samples - 1);
      final oneMinusT = 1.0 - t;
      final t2 = t * t;
      final t3 = t2 * t;
      final oneMinusT2 = oneMinusT * oneMinusT;
      final oneMinusT3 = oneMinusT2 * oneMinusT;

      final y = oneMinusT3 * p0 +
          3.0 * oneMinusT2 * t * p1 +
          3.0 * oneMinusT * t2 * p2 +
          t3 * p3;

      result.add(y);
    }

    return result;
  }
}
