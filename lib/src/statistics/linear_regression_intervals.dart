// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import '../models/chart_data_point.dart';

/// One sampled point from an ordinary least-squares uncertainty envelope.
class LinearRegressionIntervalPoint {
  const LinearRegressionIntervalPoint({
    required this.x,
    required this.fitted,
    required this.confidenceLower,
    required this.confidenceUpper,
    required this.predictionLower,
    required this.predictionUpper,
  });

  final double x;
  final double fitted;
  final double confidenceLower;
  final double confidenceUpper;
  final double predictionLower;
  final double predictionUpper;
}

/// Ordinary least-squares fit and its two-sided uncertainty envelopes.
///
/// The intervals assume independent observations, a linear mean response,
/// constant residual variance, approximately normal residuals, and fixed X
/// values. Confidence intervals describe the fitted mean response; prediction
/// intervals describe a future individual observation.
class LinearRegressionIntervals {
  const LinearRegressionIntervals({
    required this.sampleCount,
    required this.degreesOfFreedom,
    required this.slope,
    required this.intercept,
    required this.residualStandardError,
    required this.criticalValue,
    required this.points,
  });

  final int sampleCount;
  final int degreesOfFreedom;
  final double slope;
  final double intercept;
  final double residualStandardError;
  final double criticalValue;
  final List<LinearRegressionIntervalPoint> points;
}

/// Calculates OLS confidence and prediction envelopes for finite observations.
abstract final class LinearRegressionIntervalCalculator {
  static LinearRegressionIntervals? calculate({
    required Iterable<ChartDataPoint> points,
    double confidenceLevel = 0.95,
    int sampleCount = 96,
  }) {
    assert(confidenceLevel > 0 && confidenceLevel < 1);
    assert(sampleCount >= 2);
    final finite = points
        .where((point) => point.x.isFinite && point.y.isFinite)
        .toList(growable: false);
    if (finite.length < 3) return null;

    final n = finite.length;
    final meanX = finite.fold<double>(0, (sum, point) => sum + point.x) / n;
    final meanY = finite.fold<double>(0, (sum, point) => sum + point.y) / n;
    var sxx = 0.0;
    var sxy = 0.0;
    var minX = finite.first.x;
    var maxX = finite.first.x;
    for (final point in finite) {
      final centeredX = point.x - meanX;
      sxx += centeredX * centeredX;
      sxy += centeredX * (point.y - meanY);
      minX = math.min(minX, point.x);
      maxX = math.max(maxX, point.x);
    }
    if (sxx <= 1e-12 || maxX <= minX) return null;

    final slope = sxy / sxx;
    final intercept = meanY - slope * meanX;
    var residualSquares = 0.0;
    for (final point in finite) {
      final residual = point.y - (intercept + slope * point.x);
      residualSquares += residual * residual;
    }
    final degreesOfFreedom = n - 2;
    final residualStandardError = math.sqrt(residualSquares / degreesOfFreedom);
    final tailProbability = 0.5 + confidenceLevel / 2;
    final criticalValue = _studentTQuantile(tailProbability, degreesOfFreedom);
    if (!criticalValue.isFinite || !residualStandardError.isFinite) {
      return null;
    }

    final sampled = <LinearRegressionIntervalPoint>[];
    for (var index = 0; index < sampleCount; index++) {
      final fraction = index / (sampleCount - 1);
      final x = minX + (maxX - minX) * fraction;
      final fitted = intercept + slope * x;
      final leverage = 1 / n + math.pow(x - meanX, 2) / sxx;
      final confidenceHalfWidth =
          criticalValue * residualStandardError * math.sqrt(leverage);
      final predictionHalfWidth =
          criticalValue * residualStandardError * math.sqrt(1 + leverage);
      sampled.add(
        LinearRegressionIntervalPoint(
          x: x,
          fitted: fitted,
          confidenceLower: fitted - confidenceHalfWidth,
          confidenceUpper: fitted + confidenceHalfWidth,
          predictionLower: fitted - predictionHalfWidth,
          predictionUpper: fitted + predictionHalfWidth,
        ),
      );
    }

    return LinearRegressionIntervals(
      sampleCount: n,
      degreesOfFreedom: degreesOfFreedom,
      slope: slope,
      intercept: intercept,
      residualStandardError: residualStandardError,
      criticalValue: criticalValue,
      points: List.unmodifiable(sampled),
    );
  }

  // Acklam's inverse-normal approximation followed by a Cornish-Fisher
  // expansion for Student's t. The approximation is highly accurate for the
  // charting confidence levels and sample sizes supported by this feature.
  static double _studentTQuantile(double probability, int degreesOfFreedom) {
    final z = _inverseNormal(probability);
    final v = degreesOfFreedom.toDouble();
    final z2 = z * z;
    final z3 = z2 * z;
    final z5 = z3 * z2;
    final z7 = z5 * z2;
    final z9 = z7 * z2;
    return z +
        (z3 + z) / (4 * v) +
        (5 * z5 + 16 * z3 + 3 * z) / (96 * v * v) +
        (3 * z7 + 19 * z5 + 17 * z3 - 15 * z) / (384 * v * v * v) +
        (79 * z9 + 776 * z7 + 1482 * z5 - 1920 * z3 - 945 * z) /
            (92160 * v * v * v * v);
  }

  static double _inverseNormal(double probability) {
    const a = [
      -39.69683028665376,
      220.9460984245205,
      -275.9285104469687,
      138.3577518672690,
      -30.66479806614716,
      2.506628277459239,
    ];
    const b = [
      -54.47609879822406,
      161.5858368580409,
      -155.6989798598866,
      66.80131188771972,
      -13.28068155288572,
    ];
    const c = [
      -0.007784894002430293,
      -0.3223964580411365,
      -2.400758277161838,
      -2.549732539343734,
      4.374664141464968,
      2.938163982698783,
    ];
    const d = [
      0.007784695709041462,
      0.3224671290700398,
      2.445134137142996,
      3.754408661907416,
    ];
    const low = 0.02425;
    const high = 1 - low;
    if (probability < low) {
      final q = math.sqrt(-2 * math.log(probability));
      return (((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q +
              c[5]) /
          ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
    }
    if (probability > high) {
      final q = math.sqrt(-2 * math.log(1 - probability));
      return -(((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q +
              c[5]) /
          ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
    }
    final q = probability - 0.5;
    final r = q * q;
    return (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r +
            a[5]) *
        q /
        (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1);
  }
}
