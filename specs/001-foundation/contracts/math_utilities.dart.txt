// Contract: Math Utilities (FR-004)
// This file defines API contracts for mathematical functions.
//
// NOTE: This is a CONTRACT file, not an implementation.
// All implementations will use pure Dart (no external packages).

import 'dart:math' show sqrt;

/// StatisticalFunctions Contract (FR-004.1)
///
/// Common statistical calculations on numeric data.
///
/// MUST:
/// - Support multiple mean types (arithmetic, geometric, harmonic)
/// - Calculate median, mode, standard deviation, variance
/// - Compute quartiles and percentiles
/// - Handle empty lists gracefully (return NaN)
/// - Follow IEEE 754 for NaN/infinity handling
///
/// Performance Targets:
/// - All operations: <10ms for 10,000 values (FR-005.5)
abstract class StatisticalFunctions {
  // Central tendency

  /// Calculate mean (average) of values.
  /// Empty list returns NaN.
  /// Performance: <10ms for 10k values (FR-005.5)
  static double mean(
    List<double> values, {
    MeanType type = MeanType.arithmetic,
  }) =>
      throw UnimplementedError('Contract only');

  /// Calculate median (middle value).
  /// Empty list returns NaN.
  /// Performance: O(n) average with quickselect
  static double median(List<double> values) =>
      throw UnimplementedError('Contract only');

  /// Calculate mode (most frequent value).
  /// Returns NaN if no clear mode.
  static double mode(List<double> values) =>
      throw UnimplementedError('Contract only');

  // Dispersion

  /// Calculate standard deviation.
  /// sample=true uses (n-1) denominator, false uses n.
  /// Empty list returns NaN.
  static double standardDeviation(
    List<double> values, {
    bool sample = true,
  }) =>
      throw UnimplementedError('Contract only');

  /// Calculate variance.
  /// sample=true uses (n-1) denominator, false uses n.
  /// Empty list returns NaN.
  static double variance(
    List<double> values, {
    bool sample = true,
  }) =>
      throw UnimplementedError('Contract only');

  /// Calculate range (max - min).
  /// Empty list returns NaN.
  static double range(List<double> values) =>
      throw UnimplementedError('Contract only');

  // Quantiles

  /// Calculate percentile (0-100).
  /// Empty list returns NaN.
  /// p=50 is equivalent to median.
  static double percentile(List<double> values, double p) =>
      throw UnimplementedError('Contract only');

  /// Calculate quartiles (Q1, Q2, Q3).
  /// Empty list returns all NaN.
  static Quartiles quartiles(List<double> values) =>
      throw UnimplementedError('Contract only');

  /// Calculate interquartile range (Q3 - Q1).
  /// Empty list returns NaN.
  static double iqr(List<double> values) =>
      throw UnimplementedError('Contract only');

  // Extremes

  /// Find minimum value.
  /// Empty list returns double.infinity.
  static double min(List<double> values) =>
      throw UnimplementedError('Contract only');

  /// Find maximum value.
  /// Empty list returns double.negativeInfinity.
  static double max(List<double> values) =>
      throw UnimplementedError('Contract only');

  /// Find min and max in single pass.
  /// More efficient than calling min() and max() separately.
  static MinMax minMax(List<double> values) =>
      throw UnimplementedError('Contract only');
}

/// Mean type options
enum MeanType {
  arithmetic, // Sum / count
  geometric, // Nth root of product
  harmonic, // n / sum(1/x)
}

/// Quartile values (Q1, Q2/median, Q3)
class Quartiles {
  final double q1; // 25th percentile
  final double q2; // 50th percentile (median)
  final double q3; // 75th percentile

  const Quartiles({
    required this.q1,
    required this.q2,
    required this.q3,
  });

  double get iqr => q3 - q1; // Interquartile range

  @override
  String toString() => 'Quartiles(Q1: $q1, Q2: $q2, Q3: $q3)';
}

/// Min/Max pair
class MinMax {
  final double min;
  final double max;

  const MinMax({required this.min, required this.max});

  double get range => max - min;

  @override
  String toString() => 'MinMax(min: $min, max: $max)';
}

/// InterpolationFunctions Contract (FR-004.2)
///
/// Interpolate between data points for smooth curves.
///
/// MUST:
/// - Support linear, cubic spline, Hermite, Catmull-Rom, Bezier
/// - Validate parameter ranges
/// - Return empty lists for invalid input
///
/// Performance Targets:
/// - Interpolation: <1ms for 1000 samples
/// - Curve generation: <10ms for complex splines
abstract class InterpolationFunctions {
  // Linear interpolation

  /// Linear interpolate between a and b.
  /// t should be in [0, 1] range.
  /// t=0 returns a, t=1 returns b.
  static double lerp(double a, double b, double t) =>
      throw UnimplementedError('Contract only');

  /// Inverse linear interpolation.
  /// Find t such that lerp(a, b, t) == value.
  static double lerpInverse(double a, double b, double value) =>
      throw UnimplementedError('Contract only');

  // Cubic spline

  /// Generate cubic spline interpolation.
  /// Returns list of sampled y-values.
  /// Uses natural cubic spline (zero curvature at endpoints).
  /// Requires at least 2 points.
  static List<double> cubicSpline(
    List<ChartDataPoint> points,
    int samples,
  ) =>
      throw UnimplementedError('Contract only');

  // Hermite interpolation

  /// Hermite interpolation with explicit tangents.
  /// p0, p1: endpoint values
  /// m0, m1: tangent vectors at endpoints
  /// t: parameter in [0, 1]
  static double hermite(
    double p0,
    double p1,
    double m0,
    double m1,
    double t,
  ) =>
      throw UnimplementedError('Contract only');

  // Catmull-Rom spline

  /// Catmull-Rom spline (auto-computed tangents).
  /// Requires at least 4 points for proper curve.
  /// tension: 0.0 = loose, 1.0 = tight (default 0.5)
  static List<double> catmullRom(
    List<ChartDataPoint> points,
    int samples, {
    double tension = 0.5,
  }) =>
      throw UnimplementedError('Contract only');

  // Bezier curves

  /// Generic Bezier curve (arbitrary degree).
  /// controlPoints: list of control point values
  /// t: parameter in [0, 1]
  /// Uses De Casteljau's algorithm.
  static double bezier(List<double> controlPoints, double t) =>
      throw UnimplementedError('Contract only');

  /// Quadratic Bezier curve (3 control points).
  /// More efficient than generic bezier() for degree 2.
  static List<double> quadraticBezier(
    double p0,
    double p1,
    double p2,
    int samples,
  ) =>
      throw UnimplementedError('Contract only');

  /// Cubic Bezier curve (4 control points).
  /// More efficient than generic bezier() for degree 3.
  static List<double> cubicBezier(
    double p0,
    double p1,
    double p2,
    double p3,
    int samples,
  ) =>
      throw UnimplementedError('Contract only');
}

/// CurveFittingFunctions Contract (FR-004.3)
///
/// Fit mathematical curves to data for trend analysis.
///
/// MUST:
/// - Support linear, polynomial, exponential, logarithmic regression
/// - Calculate R² (coefficient of determination)
/// - Compute residuals for error analysis
/// - Provide human-readable equations
///
/// Performance Targets:
/// - Linear fit: <5ms for 10,000 points
/// - Polynomial fit: <50ms for degree ≤ 3 (FR-005.6)
/// - Exponential/Logarithmic: <50ms (FR-005.6)
abstract class CurveFittingFunctions {
  /// Linear regression (y = a + b×x).
  /// Uses least squares method.
  /// Returns coefficients [a, b] (intercept, slope).
  /// Requires at least 2 points.
  /// Performance: <5ms for 10k points
  static FitResult linearFit(List<ChartDataPoint> points) =>
      throw UnimplementedError('Contract only');

  /// Polynomial regression (y = a₀ + a₁×x + a₂×x² + ... + aₙ×xⁿ).
  /// Returns coefficients [a₀, a₁, ..., aₙ].
  /// degree MUST be >= 1 and <= 5 (stability limit).
  /// Requires at least (degree + 1) points.
  /// Performance: <50ms for degree ≤ 3 (FR-005.6)
  static FitResult polynomialFit(
    List<ChartDataPoint> points,
    int degree,
  ) =>
      throw UnimplementedError('Contract only');

  /// Exponential regression (y = a × e^(b×x)).
  /// Returns coefficients [a, b].
  /// Requires all y > 0 (transforms to linear via ln).
  /// Performance: <50ms (FR-005.6)
  static FitResult exponentialFit(List<ChartDataPoint> points) =>
      throw UnimplementedError('Contract only');

  /// Logarithmic regression (y = a + b×ln(x)).
  /// Returns coefficients [a, b].
  /// Requires all x > 0.
  /// Performance: <50ms (FR-005.6)
  static FitResult logarithmicFit(List<ChartDataPoint> points) =>
      throw UnimplementedError('Contract only');
}

/// Curve fitting result
class FitResult {
  final List<double> coefficients;
  final double rSquared; // Coefficient of determination (0-1)
  final List<double> residuals; // Error per point
  final String equation; // Human-readable equation

  const FitResult({
    required this.coefficients,
    required this.rSquared,
    required this.residuals,
    required this.equation,
  });

  /// Calculate predicted y-value for given x.
  /// Implementation depends on fit type.
  double predict(double x) => throw UnimplementedError('Contract only');

  /// Root mean square error
  double get rmse {
    final sumSquared = residuals.fold(0.0, (sum, r) => sum + r * r);
    return sqrt(sumSquared / residuals.length);
  }

  /// Mean absolute error
  double get mae {
    final sumAbs = residuals.fold(0.0, (sum, r) => sum + r.abs());
    return sumAbs / residuals.length;
  }

  @override
  String toString() =>
      'FitResult(equation: $equation, R²: ${rSquared.toStringAsFixed(4)}, RMSE: ${rmse.toStringAsFixed(4)})';
}

// Supporting types
class ChartDataPoint {
  final double x;
  final double y;
  const ChartDataPoint({required this.x, required this.y});
}
