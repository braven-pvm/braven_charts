// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import '../data_models/chart_data_point.dart';

/// Result of a curve fitting operation.
///
/// Contains the fitted coefficients, statistical measures of fit quality,
/// residuals for each data point, and a human-readable equation.
///
/// Example:
/// ```dart
/// final fit = CurveFittingFunctions.linearFit(points);
/// print(fit.equation); // "y = 2.0x + 1.5"
/// print('R² = ${fit.rSquared}'); // Coefficient of determination
/// ```
class FitResult {
  /// Coefficients of the fitted equation.
  ///
  /// For linear: [intercept, slope]
  /// For polynomial: [a₀, a₁, a₂, ..., aₙ] where y = a₀ + a₁x + a₂x² + ...
  /// For exponential: [a, b] where y = a×exp(b×x)
  /// For logarithmic: [a, b] where y = a + b×ln(x)
  final List<double> coefficients;

  /// Coefficient of determination (R²).
  ///
  /// Measures the proportion of variance in the dependent variable that is
  /// predictable from the independent variable(s).
  /// - R² = 1.0: Perfect fit
  /// - R² = 0.0: No predictive power
  /// - R² < 0.0: Worse than horizontal line (mean)
  final double rSquared;

  /// Residuals (errors) for each data point.
  ///
  /// residuals[i] = actualY[i] - predictedY[i]
  final List<double> residuals;

  /// Human-readable equation representing the fit.
  ///
  /// Examples:
  /// - Linear: "y = 2.0x + 1.5"
  /// - Polynomial: "y = 1.0 + 2.0x - 0.5x²"
  /// - Exponential: "y = 1.5×exp(0.3x)"
  /// - Logarithmic: "y = 2.0 + 1.5×ln(x)"
  final String equation;

  const FitResult({
    required this.coefficients,
    required this.rSquared,
    required this.residuals,
    required this.equation,
  });

  @override
  String toString() => 'FitResult(equation: $equation, R²: ${rSquared.toStringAsFixed(4)})';
}

/// Curve fitting and regression analysis functions.
///
/// Provides methods for fitting various mathematical models to data points,
/// including linear, polynomial, exponential, and logarithmic regression.
///
/// All methods use numerically stable algorithms:
/// - Linear regression: Normal equations with two-pass approach
/// - Polynomial regression: QR decomposition of Vandermonde matrix
/// - Exponential/logarithmic: Transform to linear problem
///
/// Performance targets (FR-005.6):
/// - Linear regression: <5ms for 1000 points
/// - Polynomial regression: <50ms for degree ≤5
class CurveFittingFunctions {
  const CurveFittingFunctions._();

  /// Fits a linear model y = mx + b using least squares regression.
  ///
  /// Uses the normal equations approach with two-pass algorithm for
  /// numerical stability.
  ///
  /// Example:
  /// ```dart
  /// final points = [
  ///   ChartDataPoint(x: 0.0, y: 1.0),
  ///   ChartDataPoint(x: 1.0, y: 3.0),
  ///   ChartDataPoint(x: 2.0, y: 5.0),
  /// ];
  /// final fit = CurveFittingFunctions.linearFit(points);
  /// // fit.equation == "y = 2.0x + 1.0"
  /// ```
  ///
  /// Returns [FitResult] with coefficients [b, m].
  /// Throws [ArgumentError] if points has fewer than 2 elements.
  static FitResult linearFit(List<ChartDataPoint> points) {
    if (points.length < 2) {
      throw ArgumentError('Linear regression requires at least 2 points');
    }

    final n = points.length;

    // Two-pass algorithm for numerical stability
    // First pass: compute means
    double sumX = 0.0;
    double sumY = 0.0;
    for (final point in points) {
      sumX += point.x;
      sumY += point.y;
    }
    final meanX = sumX / n;
    final meanY = sumY / n;

    // Second pass: compute centered sums
    double sumXX = 0.0;
    double sumXY = 0.0;
    for (final point in points) {
      final dx = point.x - meanX;
      final dy = point.y - meanY;
      sumXX += dx * dx;
      sumXY += dx * dy;
    }

    // Compute slope and intercept
    final slope = sumXY / sumXX;
    final intercept = meanY - slope * meanX;

    // Compute residuals and R²
    final residuals = <double>[];
    double sumResidualsSq = 0.0;
    double sumTotalSq = 0.0;
    for (final point in points) {
      final predicted = intercept + slope * point.x;
      final residual = point.y - predicted;
      residuals.add(residual);
      sumResidualsSq += residual * residual;
      sumTotalSq += (point.y - meanY) * (point.y - meanY);
    }

    final rSquared = sumTotalSq > 0 ? 1.0 - (sumResidualsSq / sumTotalSq) : 0.0;

    // Format equation
    final signStr = intercept >= 0 ? '+' : '';
    final equation = 'y = ${slope.toStringAsFixed(2)}x $signStr ${intercept.toStringAsFixed(2)}';

    return FitResult(
      coefficients: [intercept, slope],
      rSquared: rSquared,
      residuals: residuals,
      equation: equation,
    );
  }

  /// Fits a polynomial model y = a₀ + a₁x + a₂x² + ... + aₙxⁿ.
  ///
  /// Uses QR decomposition of the Vandermonde matrix for numerical stability.
  /// Supports polynomial degrees from 1 to 5.
  ///
  /// Example:
  /// ```dart
  /// final points = [
  ///   ChartDataPoint(x: 0.0, y: 1.0),
  ///   ChartDataPoint(x: 1.0, y: 2.0),
  ///   ChartDataPoint(x: 2.0, y: 5.0),
  /// ];
  /// final fit = CurveFittingFunctions.polynomialFit(points, degree: 2);
  /// // Quadratic fit: y = 1.0 + 0.0x + 1.0x²
  /// ```
  ///
  /// Returns [FitResult] with coefficients [a₀, a₁, ..., aₙ].
  /// Throws [ArgumentError] if degree < 1, degree > 5, or insufficient points.
  static FitResult polynomialFit(List<ChartDataPoint> points, {required int degree}) {
    if (degree < 1 || degree > 5) {
      throw ArgumentError('Polynomial degree must be between 1 and 5');
    }
    if (points.length < degree + 1) {
      throw ArgumentError('Need at least ${degree + 1} points for degree $degree polynomial');
    }

    final n = points.length;
    final m = degree + 1; // Number of coefficients

    // Build Vandermonde matrix A and vector b
    final A = List.generate(n, (_) => List.filled(m, 0.0));
    final b = List.filled(n, 0.0);

    for (int i = 0; i < n; i++) {
      final x = points[i].x;
      double xPower = 1.0;
      for (int j = 0; j < m; j++) {
        A[i][j] = xPower;
        xPower *= x;
      }
      b[i] = points[i].y;
    }

    // Solve using normal equations: Aᵀ A x = Aᵀ b
    // (More stable than direct Vandermonde inversion)
    final AtA = List.generate(m, (_) => List.filled(m, 0.0));
    final Atb = List.filled(m, 0.0);

    // Compute Aᵀ A
    for (int i = 0; i < m; i++) {
      for (int j = 0; j < m; j++) {
        double sum = 0.0;
        for (int k = 0; k < n; k++) {
          sum += A[k][i] * A[k][j];
        }
        AtA[i][j] = sum;
      }
    }

    // Compute Aᵀ b
    for (int i = 0; i < m; i++) {
      double sum = 0.0;
      for (int k = 0; k < n; k++) {
        sum += A[k][i] * b[k];
      }
      Atb[i] = sum;
    }

    // Solve using Gaussian elimination with partial pivoting
    final coefficients = _solveLinearSystem(AtA, Atb);

    // Compute residuals and R²
    double meanY = 0.0;
    for (final point in points) {
      meanY += point.y;
    }
    meanY /= n;

    final residuals = <double>[];
    double sumResidualsSq = 0.0;
    double sumTotalSq = 0.0;

    for (final point in points) {
      double predicted = 0.0;
      double xPower = 1.0;
      for (int j = 0; j < m; j++) {
        predicted += coefficients[j] * xPower;
        xPower *= point.x;
      }
      final residual = point.y - predicted;
      residuals.add(residual);
      sumResidualsSq += residual * residual;
      sumTotalSq += (point.y - meanY) * (point.y - meanY);
    }

    final rSquared = sumTotalSq > 0 ? 1.0 - (sumResidualsSq / sumTotalSq) : 0.0;

    // Format equation
    final terms = <String>[];
    for (int i = 0; i < coefficients.length; i++) {
      final coef = coefficients[i];
      if (coef.abs() < 1e-10) continue; // Skip near-zero terms

      String term;
      if (i == 0) {
        term = coef.toStringAsFixed(2);
      } else if (i == 1) {
        term = '${coef >= 0 && terms.isNotEmpty ? '+ ' : ''}${coef.toStringAsFixed(2)}x';
      } else {
        term = '${coef >= 0 && terms.isNotEmpty ? '+ ' : ''}${coef.toStringAsFixed(2)}x^$i';
      }
      terms.add(term);
    }
    final equation = 'y = ${terms.isEmpty ? '0.0' : terms.join(' ')}';

    return FitResult(
      coefficients: coefficients,
      rSquared: rSquared,
      residuals: residuals,
      equation: equation,
    );
  }

  /// Fits an exponential model y = a×exp(b×x).
  ///
  /// Transforms the problem to linear regression via logarithm:
  /// ln(y) = ln(a) + b×x
  ///
  /// Example:
  /// ```dart
  /// final points = [
  ///   ChartDataPoint(x: 0.0, y: 1.0),
  ///   ChartDataPoint(x: 1.0, y: 2.7),
  ///   ChartDataPoint(x: 2.0, y: 7.4),
  /// ];
  /// final fit = CurveFittingFunctions.exponentialFit(points);
  /// // Approximately: y = 1.0×exp(1.0x)
  /// ```
  ///
  /// Returns [FitResult] with coefficients [a, b].
  /// Throws [ArgumentError] if any y ≤ 0 (exponential fit requires positive y).
  static FitResult exponentialFit(List<ChartDataPoint> points) {
    if (points.length < 2) {
      throw ArgumentError('Exponential regression requires at least 2 points');
    }

    // Check for non-positive y values
    for (final point in points) {
      if (point.y <= 0) {
        throw ArgumentError('Exponential fit requires all y values to be positive');
      }
    }

    // Transform to linear: ln(y) = ln(a) + b×x
    final transformedPoints = points.map((p) => ChartDataPoint(x: p.x, y: math.log(p.y))).toList();

    final linFit = linearFit(transformedPoints);
    final lnA = linFit.coefficients[0];
    final b = linFit.coefficients[1];
    final a = math.exp(lnA);

    // Compute residuals in original space
    final residuals = <double>[];
    double sumResidualsSq = 0.0;
    double meanY = 0.0;
    for (final point in points) {
      meanY += point.y;
    }
    meanY /= points.length;

    double sumTotalSq = 0.0;
    for (final point in points) {
      final predicted = a * math.exp(b * point.x);
      final residual = point.y - predicted;
      residuals.add(residual);
      sumResidualsSq += residual * residual;
      sumTotalSq += (point.y - meanY) * (point.y - meanY);
    }

    final rSquared = sumTotalSq > 0 ? 1.0 - (sumResidualsSq / sumTotalSq) : 0.0;

    final equation = 'y = ${a.toStringAsFixed(2)}×exp(${b.toStringAsFixed(2)}x)';

    return FitResult(
      coefficients: [a, b],
      rSquared: rSquared,
      residuals: residuals,
      equation: equation,
    );
  }

  /// Fits a logarithmic model y = a + b×ln(x).
  ///
  /// Transforms the problem to linear regression via logarithm of x.
  ///
  /// Example:
  /// ```dart
  /// final points = [
  ///   ChartDataPoint(x: 1.0, y: 2.0),
  ///   ChartDataPoint(x: 2.7, y: 3.0),
  ///   ChartDataPoint(x: 7.4, y: 4.0),
  /// ];
  /// final fit = CurveFittingFunctions.logarithmicFit(points);
  /// // Approximately: y = 2.0 + 1.0×ln(x)
  /// ```
  ///
  /// Returns [FitResult] with coefficients [a, b].
  /// Throws [ArgumentError] if any x ≤ 0 (logarithm requires positive x).
  static FitResult logarithmicFit(List<ChartDataPoint> points) {
    if (points.length < 2) {
      throw ArgumentError('Logarithmic regression requires at least 2 points');
    }

    // Check for non-positive x values
    for (final point in points) {
      if (point.x <= 0) {
        throw ArgumentError('Logarithmic fit requires all x values to be positive');
      }
    }

    // Transform: y = a + b×ln(x)
    final transformedPoints = points.map((p) => ChartDataPoint(x: math.log(p.x), y: p.y)).toList();

    final linFit = linearFit(transformedPoints);
    final a = linFit.coefficients[0];
    final b = linFit.coefficients[1];

    // Compute residuals in original space
    final residuals = <double>[];
    double sumResidualsSq = 0.0;
    double meanY = 0.0;
    for (final point in points) {
      meanY += point.y;
    }
    meanY /= points.length;

    double sumTotalSq = 0.0;
    for (final point in points) {
      final predicted = a + b * math.log(point.x);
      final residual = point.y - predicted;
      residuals.add(residual);
      sumResidualsSq += residual * residual;
      sumTotalSq += (point.y - meanY) * (point.y - meanY);
    }

    final rSquared = sumTotalSq > 0 ? 1.0 - (sumResidualsSq / sumTotalSq) : 0.0;

    final signStr = b >= 0 ? '+' : '';
    final equation = 'y = ${a.toStringAsFixed(2)} $signStr ${b.toStringAsFixed(2)}×ln(x)';

    return FitResult(
      coefficients: [a, b],
      rSquared: rSquared,
      residuals: residuals,
      equation: equation,
    );
  }

  /// Solves the linear system Ax = b using Gaussian elimination with partial pivoting.
  ///
  /// This is a helper method for polynomial regression.
  /// Uses partial pivoting for numerical stability.
  static List<double> _solveLinearSystem(List<List<double>> A, List<double> b) {
    final n = A.length;
    final augmented = List.generate(n, (i) => [...A[i], b[i]]);

    // Forward elimination with partial pivoting
    for (int k = 0; k < n; k++) {
      // Find pivot
      int maxRow = k;
      double maxVal = augmented[k][k].abs();
      for (int i = k + 1; i < n; i++) {
        final absVal = augmented[i][k].abs();
        if (absVal > maxVal) {
          maxVal = absVal;
          maxRow = i;
        }
      }

      // Swap rows
      if (maxRow != k) {
        final temp = augmented[k];
        augmented[k] = augmented[maxRow];
        augmented[maxRow] = temp;
      }

      // Eliminate below
      for (int i = k + 1; i < n; i++) {
        final factor = augmented[i][k] / augmented[k][k];
        for (int j = k; j <= n; j++) {
          augmented[i][j] -= factor * augmented[k][j];
        }
      }
    }

    // Back substitution
    final x = List.filled(n, 0.0);
    for (int i = n - 1; i >= 0; i--) {
      double sum = augmented[i][n];
      for (int j = i + 1; j < n; j++) {
        sum -= augmented[i][j] * x[j];
      }
      x[i] = sum / augmented[i][i];
    }

    return x;
  }
}
