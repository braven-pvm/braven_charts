import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinearRegressionIntervalCalculator', () {
    test('matches a fixed OLS reference dataset', () {
      final result = LinearRegressionIntervalCalculator.calculate(
        points: const [
          ChartDataPoint(x: 1, y: 2),
          ChartDataPoint(x: 2, y: 4),
          ChartDataPoint(x: 3, y: 5),
          ChartDataPoint(x: 4, y: 4),
          ChartDataPoint(x: 5, y: 5),
        ],
        confidenceLevel: 0.95,
        sampleCount: 5,
      )!;

      expect(result.slope, closeTo(0.6, 1e-12));
      expect(result.intercept, closeTo(2.2, 1e-12));
      expect(result.residualStandardError, closeTo(0.8944271909999, 1e-10));
      expect(result.criticalValue, closeTo(3.182446, 0.015));
      final center = result.points[2];
      expect(center.x, 3);
      expect(center.fitted, 4);
      expect(center.confidenceLower, closeTo(2.727, 0.01));
      expect(center.confidenceUpper, closeTo(5.273, 0.01));
      expect(center.predictionLower, closeTo(0.882, 0.02));
      expect(center.predictionUpper, closeTo(7.118, 0.02));
    });

    test('filters invalid observations and rejects degenerate X domains', () {
      expect(
        LinearRegressionIntervalCalculator.calculate(
          points: const [
            ChartDataPoint(x: 2, y: 1),
            ChartDataPoint(x: 2, y: 2),
            ChartDataPoint(x: 2, y: 3),
            ChartDataPoint(x: double.nan, y: 4),
          ],
        ),
        isNull,
      );
    });
  });
}
