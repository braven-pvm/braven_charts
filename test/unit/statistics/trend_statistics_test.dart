// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrendStatisticsCalculator', () {
    test('matches a perfect fixed linear reference dataset', () {
      const points = [
        ChartDataPoint(x: 1, y: 3),
        ChartDataPoint(x: 2, y: 5),
        ChartDataPoint(x: 3, y: 7),
        ChartDataPoint(x: 4, y: 9),
      ];

      final result = TrendStatisticsCalculator.calculate(
        points: points,
        predict: (x) => 2 * x + 1,
        equation: 'y = 2x + 1',
      );

      expect(result.sampleCount, 4);
      expect(result.equation, 'y = 2x + 1');
      expect(result.rSquared, closeTo(1, 1e-12));
      expect(result.pearsonCorrelation, closeTo(1, 1e-12));
      expect(result.spearmanCorrelation, closeTo(1, 1e-12));
    });

    test('filters non-finite values and returns null for degenerate axes', () {
      const points = [
        ChartDataPoint(x: 2, y: 4),
        ChartDataPoint(x: 2, y: 4),
        ChartDataPoint(x: double.nan, y: 8),
        ChartDataPoint(x: 3, y: double.infinity),
      ];

      final result = TrendStatisticsCalculator.calculate(
        points: points,
        predict: (_) => 4,
      );

      expect(result.sampleCount, 2);
      expect(result.rSquared, 1);
      expect(result.pearsonCorrelation, isNull);
      expect(result.spearmanCorrelation, isNull);
    });

    test('uses average ranks for tied Spearman observations', () {
      const points = [
        ChartDataPoint(x: 1, y: 1),
        ChartDataPoint(x: 2, y: 2),
        ChartDataPoint(x: 2, y: 3),
        ChartDataPoint(x: 3, y: 4),
      ];

      final result = TrendStatisticsCalculator.calculate(
        points: points,
        predict: (x) => x,
      );

      expect(result.spearmanCorrelation, closeTo(0.9486832981, 1e-9));
    });

    test('reports inverse Pearson and Spearman relationships', () {
      const points = [
        ChartDataPoint(x: 1, y: 8),
        ChartDataPoint(x: 2, y: 6),
        ChartDataPoint(x: 3, y: 4),
        ChartDataPoint(x: 4, y: 2),
      ];

      final result = TrendStatisticsCalculator.calculate(
        points: points,
        predict: (x) => 10 - 2 * x,
      );

      expect(result.pearsonCorrelation, closeTo(-1, 1e-12));
      expect(result.spearmanCorrelation, closeTo(-1, 1e-12));
    });
  });

  group('TrendEquationFormatter', () {
    test('formats linear signs without redundant trailing zeroes', () {
      expect(TrendEquationFormatter.linear(2, 1), 'y = 2x + 1');
      expect(TrendEquationFormatter.linear(-0.5, -3), 'y = -0.5x - 3');
    });

    test('formats polynomial terms from highest degree to intercept', () {
      expect(
        TrendEquationFormatter.polynomial(const [1, -2, 0.5]),
        'y = 0.5x² - 2x + 1',
      );
    });
  });
}
