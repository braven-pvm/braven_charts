// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import '../models/chart_data_point.dart';

/// Statistical diagnostics associated with a rendered trend annotation.
class TrendStatistics {
  const TrendStatistics({
    required this.sampleCount,
    this.equation,
    this.rSquared,
    this.pearsonCorrelation,
    this.spearmanCorrelation,
  });

  /// Number of source observations with finite X and Y values.
  final int sampleCount;

  /// Human-readable parametric equation, when the trend has one.
  final String? equation;

  /// Coefficient of determination for finite observations with predictions.
  final double? rSquared;

  /// Pearson product-moment correlation of finite X/Y observations.
  final double? pearsonCorrelation;

  /// Spearman rank correlation with average ranks for ties.
  final double? spearmanCorrelation;
}

/// Computes trend diagnostics from source observations and a fitted predictor.
abstract final class TrendStatisticsCalculator {
  static TrendStatistics calculate({
    required Iterable<ChartDataPoint> points,
    required double? Function(double x) predict,
    String? equation,
  }) {
    final finite = points
        .where((point) => point.x.isFinite && point.y.isFinite)
        .toList(growable: false);
    final xValues = [for (final point in finite) point.x];
    final yValues = [for (final point in finite) point.y];

    return TrendStatistics(
      sampleCount: finite.length,
      equation: equation,
      rSquared: _rSquared(finite, predict),
      pearsonCorrelation: _correlation(xValues, yValues),
      spearmanCorrelation: _correlation(
        _averageRanks(xValues),
        _averageRanks(yValues),
      ),
    );
  }

  static double? _rSquared(
    List<ChartDataPoint> points,
    double? Function(double x) predict,
  ) {
    final observed = <double>[];
    final predicted = <double>[];
    for (final point in points) {
      final value = predict(point.x);
      if (value == null || !value.isFinite) continue;
      observed.add(point.y);
      predicted.add(value);
    }
    if (observed.length < 2) return null;

    final mean =
        observed.reduce((left, right) => left + right) / observed.length;
    var totalSquares = 0.0;
    var residualSquares = 0.0;
    for (var index = 0; index < observed.length; index++) {
      final centered = observed[index] - mean;
      final residual = observed[index] - predicted[index];
      totalSquares += centered * centered;
      residualSquares += residual * residual;
    }
    if (totalSquares <= 1e-12) {
      return residualSquares <= 1e-12 ? 1 : null;
    }
    return 1 - residualSquares / totalSquares;
  }

  static double? _correlation(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 2) return null;
    final meanX = x.reduce((left, right) => left + right) / x.length;
    final meanY = y.reduce((left, right) => left + right) / y.length;
    var covariance = 0.0;
    var xSquares = 0.0;
    var ySquares = 0.0;
    for (var index = 0; index < x.length; index++) {
      final centeredX = x[index] - meanX;
      final centeredY = y[index] - meanY;
      covariance += centeredX * centeredY;
      xSquares += centeredX * centeredX;
      ySquares += centeredY * centeredY;
    }
    if (xSquares <= 1e-12 || ySquares <= 1e-12) return null;
    return (covariance / math.sqrt(xSquares * ySquares)).clamp(-1.0, 1.0);
  }

  static List<double> _averageRanks(List<double> values) {
    if (values.isEmpty) return const [];
    final ordered = values.indexed.toList()
      ..sort((left, right) {
        final byValue = left.$2.compareTo(right.$2);
        return byValue != 0 ? byValue : left.$1.compareTo(right.$1);
      });
    final ranks = List<double>.filled(values.length, 0);
    var start = 0;
    while (start < ordered.length) {
      var end = start + 1;
      while (end < ordered.length && ordered[end].$2 == ordered[start].$2) {
        end++;
      }
      final averageRank = ((start + 1) + end) / 2;
      for (var index = start; index < end; index++) {
        ranks[ordered[index].$1] = averageRank;
      }
      start = end;
    }
    return ranks;
  }
}

/// Formats compact, stable equations for trend annotation labels.
abstract final class TrendEquationFormatter {
  static String linear(double slope, double intercept) {
    return 'y = ${_number(slope)}x ${_signed(intercept)}';
  }

  static String polynomial(List<double> coefficients) {
    if (coefficients.isEmpty) return 'y = 0';
    final terms = <String>[];
    for (var degree = coefficients.length - 1; degree >= 0; degree--) {
      final coefficient = coefficients[degree];
      if (!coefficient.isFinite || coefficient.abs() < 0.0005) continue;
      final magnitude = _number(coefficient.abs());
      final variable = switch (degree) {
        0 => '',
        1 => 'x',
        2 => 'x²',
        3 => 'x³',
        _ => 'x^$degree',
      };
      final value = '$magnitude$variable';
      if (terms.isEmpty) {
        terms.add(coefficient < 0 ? '-$value' : value);
      } else {
        terms.add(coefficient < 0 ? '- $value' : '+ $value');
      }
    }
    return 'y = ${terms.isEmpty ? '0' : terms.join(' ')}';
  }

  static String _signed(double value) {
    return value < 0 ? '- ${_number(value.abs())}' : '+ ${_number(value)}';
  }

  static String _number(double value) {
    final normalized = value.abs() < 0.0005 ? 0.0 : value;
    final fixed = normalized.toStringAsFixed(3);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
