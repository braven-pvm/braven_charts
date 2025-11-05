// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import '../foundation/data_models/chart_data_point.dart';

/// Utility class for calculating statistical trend lines from chart data.
///
/// Provides implementations of common trend analysis methods:
/// - Linear regression (least squares method)
/// - Polynomial regression (configurable degree)
/// - Moving averages (simple rolling window)
/// - Exponential smoothing
///
/// All methods use only standard Dart libraries (dart:math) per project constraints.
class TrendCalculator {
  TrendCalculator._(); // Private constructor - static utility class

  /// Calculates linear regression (y = mx + b) using least squares method.
  ///
  /// Returns a [TrendResult] containing:
  /// - coefficients: [slope, intercept]
  /// - rSquared: Correlation coefficient (0-1, higher = better fit)
  /// - trendPoints: Calculated line points spanning the data range
  ///
  /// Requires at least 2 data points. Returns null if insufficient data.
  static TrendResult? linearRegression(List<ChartDataPoint> points) {
    if (points.length < 2) return null;

    final n = points.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    // Calculate sums for least squares formula
    for (final point in points) {
      sumX += point.x;
      sumY += point.y;
      sumXY += point.x * point.y;
      sumX2 += point.x * point.x;
    }

    // Calculate slope (m) and intercept (b)
    // m = (n*Σ(xy) - Σx*Σy) / (n*Σ(x²) - (Σx)²)
    // b = (Σy - m*Σx) / n
    final denominator = (n * sumX2 - sumX * sumX);
    if (denominator.abs() < 1e-10) return null; // Prevent division by zero

    final slope = (n * sumXY - sumX * sumY) / denominator;
    final intercept = (sumY - slope * sumX) / n;

    // Calculate R² (coefficient of determination)
    final meanY = sumY / n;
    double ssTotal = 0, ssResidual = 0;
    for (final point in points) {
      final predicted = slope * point.x + intercept;
      ssTotal += math.pow(point.y - meanY, 2);
      ssResidual += math.pow(point.y - predicted, 2);
    }
    final rSquared = ssTotal > 0 ? 1 - (ssResidual / ssTotal) : 0.0;

    // Generate trend line points (use original x range)
    final minX = points.map((p) => p.x).reduce(math.min);
    final maxX = points.map((p) => p.x).reduce(math.max);

    final trendPoints = <ChartDataPoint>[
      ChartDataPoint(x: minX, y: slope * minX + intercept),
      ChartDataPoint(x: maxX, y: slope * maxX + intercept),
    ];

    return TrendResult(
      coefficients: [slope, intercept],
      rSquared: rSquared.clamp(0.0, 1.0),
      trendPoints: trendPoints,
    );
  }

  /// Calculates simple moving average with specified window size.
  ///
  /// Returns a list of smoothed data points. The first (windowSize - 1) points
  /// are omitted since a full window isn't available. X values are preserved.
  ///
  /// Example: windowSize=3 for data [1,2,3,4,5] returns [(2, avg(1,2,3)), (3, avg(2,3,4)), (4, avg(3,4,5))]
  ///
  /// Returns null if windowSize > data length or windowSize < 1.
  static List<ChartDataPoint>? movingAverage(List<ChartDataPoint> points, int windowSize) {
    if (windowSize < 1 || windowSize > points.length) return null;

    final result = <ChartDataPoint>[];

    for (int i = windowSize - 1; i < points.length; i++) {
      double sum = 0;
      for (int j = 0; j < windowSize; j++) {
        sum += points[i - j].y;
      }
      final average = sum / windowSize;
      result.add(ChartDataPoint(x: points[i].x, y: average));
    }

    return result;
  }

  /// Calculates polynomial regression of specified degree (2-5).
  ///
  /// Uses least squares method to fit polynomial: y = a₀ + a₁x + a₂x² + ... + aₙxⁿ
  ///
  /// Returns a [TrendResult] containing:
  /// - coefficients: [a₀, a₁, a₂, ..., aₙ] (constant term first)
  /// - rSquared: Goodness of fit (0-1)
  /// - trendPoints: Smooth curve with sufficient resolution
  ///
  /// Requires degree >= 1 and degree <= 5, and at least (degree + 1) data points.
  /// Returns null if requirements not met.
  static TrendResult? polynomialRegression(List<ChartDataPoint> points, int degree) {
    if (degree < 1 || degree > 5 || points.length < degree + 1) return null;

    final n = points.length;

    // Build the system of normal equations: X^T * X * coeffs = X^T * y
    // For polynomial, we need to solve a (degree+1) x (degree+1) system
    final matrix = List.generate(degree + 1, (_) => List.filled(degree + 1, 0.0));
    final vector = List.filled(degree + 1, 0.0);

    // Fill matrix and vector
    for (int i = 0; i <= degree; i++) {
      for (int j = 0; j <= degree; j++) {
        for (final point in points) {
          matrix[i][j] += math.pow(point.x, i + j);
        }
      }
      for (final point in points) {
        vector[i] += point.y * math.pow(point.x, i);
      }
    }

    // Solve using Gaussian elimination
    final coefficients = _gaussianElimination(matrix, vector);
    if (coefficients == null) return null;

    // Calculate R²
    final meanY = points.map((p) => p.y).reduce((a, b) => a + b) / n;
    double ssTotal = 0, ssResidual = 0;

    for (final point in points) {
      double predicted = 0;
      for (int i = 0; i <= degree; i++) {
        predicted += coefficients[i] * math.pow(point.x, i);
      }
      ssTotal += math.pow(point.y - meanY, 2);
      ssResidual += math.pow(point.y - predicted, 2);
    }
    final rSquared = ssTotal > 0 ? 1 - (ssResidual / ssTotal) : 0.0;

    // Generate smooth curve (50 points across range)
    final minX = points.map((p) => p.x).reduce(math.min);
    final maxX = points.map((p) => p.x).reduce(math.max);
    final step = (maxX - minX) / 49; // 50 points total

    final trendPoints = <ChartDataPoint>[];
    for (int i = 0; i < 50; i++) {
      final x = minX + step * i;
      double y = 0;
      for (int j = 0; j <= degree; j++) {
        y += coefficients[j] * math.pow(x, j);
      }
      trendPoints.add(ChartDataPoint(x: x, y: y));
    }

    return TrendResult(
      coefficients: coefficients,
      rSquared: rSquared.clamp(0.0, 1.0),
      trendPoints: trendPoints,
    );
  }

  /// Calculates exponential smoothing with specified alpha parameter.
  ///
  /// Formula: S_t = α * y_t + (1 - α) * S_(t-1)
  /// where α is the smoothing factor (0 < α < 1)
  ///
  /// - α close to 1: More weight on recent data (less smoothing)
  /// - α close to 0: More weight on historical data (more smoothing)
  ///
  /// First smoothed value is set to the first actual value.
  /// Returns null if alpha is not in range (0, 1] or points is empty.
  static List<ChartDataPoint>? exponentialSmoothing(List<ChartDataPoint> points, double alpha) {
    if (points.isEmpty || alpha <= 0 || alpha > 1) return null;

    final result = <ChartDataPoint>[];
    double smoothed = points.first.y; // Initialize with first value

    for (final point in points) {
      smoothed = alpha * point.y + (1 - alpha) * smoothed;
      result.add(ChartDataPoint(x: point.x, y: smoothed));
    }

    return result;
  }

  /// Solves a system of linear equations using Gaussian elimination with partial pivoting.
  ///
  /// Used internally for polynomial regression. Returns coefficients or null if system is singular.
  static List<double>? _gaussianElimination(List<List<double>> matrix, List<double> vector) {
    final n = matrix.length;
    final augmented = List.generate(n, (i) => [...matrix[i], vector[i]]);

    // Forward elimination with partial pivoting
    for (int col = 0; col < n; col++) {
      // Find pivot
      int maxRow = col;
      for (int row = col + 1; row < n; row++) {
        if (augmented[row][col].abs() > augmented[maxRow][col].abs()) {
          maxRow = row;
        }
      }

      // Swap rows
      if (maxRow != col) {
        final temp = augmented[col];
        augmented[col] = augmented[maxRow];
        augmented[maxRow] = temp;
      }

      // Check for singular matrix
      if (augmented[col][col].abs() < 1e-10) return null;

      // Eliminate column
      for (int row = col + 1; row < n; row++) {
        final factor = augmented[row][col] / augmented[col][col];
        for (int j = col; j <= n; j++) {
          augmented[row][j] -= factor * augmented[col][j];
        }
      }
    }

    // Back substitution
    final solution = List.filled(n, 0.0);
    for (int i = n - 1; i >= 0; i--) {
      solution[i] = augmented[i][n];
      for (int j = i + 1; j < n; j++) {
        solution[i] -= augmented[i][j] * solution[j];
      }
      solution[i] /= augmented[i][i];
    }

    return solution;
  }
}

/// Result of a trend calculation containing coefficients, fit quality, and calculated points.
class TrendResult {
  /// Creates a trend result.
  const TrendResult({
    required this.coefficients,
    required this.rSquared,
    required this.trendPoints,
  });

  /// Regression coefficients.
  ///
  /// - Linear: [slope, intercept]
  /// - Polynomial: [a₀, a₁, a₂, ..., aₙ] where y = a₀ + a₁x + a₂x² + ...
  final List<double> coefficients;

  /// Coefficient of determination (R²) measuring goodness of fit.
  ///
  /// Range: 0.0 to 1.0
  /// - 1.0 = Perfect fit
  /// - 0.0 = No correlation
  final double rSquared;

  /// Calculated trend line points ready for rendering.
  final List<ChartDataPoint> trendPoints;

  @override
  String toString() => 'TrendResult(coefficients: $coefficients, R²: ${rSquared.toStringAsFixed(4)}, points: ${trendPoints.length})';
}
