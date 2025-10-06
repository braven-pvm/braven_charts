// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/src/foundation/math/curve_fitting.dart';
import 'package:braven_charts/src/foundation/math/interpolation.dart';
// These imports will fail until implementation exists - that's expected for TDD
import 'package:braven_charts/src/foundation/math/statistics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StatisticalFunctions Contract Tests', () {
    test('StatisticalFunctions.mean() exists', () {
      final values = [1.0, 2.0, 3.0, 4.0, 5.0];
      final avg = StatisticalFunctions.mean(values);
      expect(avg, equals(3.0));
    });

    test('StatisticalFunctions supports geometric mean', () {
      final values = [2.0, 8.0];
      final geoMean = StatisticalFunctions.mean(
        values,
        type: MeanType.geometric,
      );
      expect(geoMean, closeTo(4.0, 0.01)); // Square root of 16
    });

    test('StatisticalFunctions.median() exists', () {
      expect(StatisticalFunctions.median([1, 2, 3, 4, 5]), equals(3.0));
      expect(StatisticalFunctions.median([1, 2, 3, 4]), equals(2.5));
    });

    test('StatisticalFunctions.standardDeviation() exists', () {
      final values = [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0];
      final sd = StatisticalFunctions.standardDeviation(values);
      expect(sd, closeTo(2.138, 0.01)); // Actual sample std dev
    });

    test('StatisticalFunctions.quartiles() exists', () {
      final values = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0];
      final q = StatisticalFunctions.quartiles(values);
      expect(q.q1, equals(3.0)); // 25th percentile at index 2
      expect(q.q2, equals(5.0)); // Median
      expect(q.q3, equals(7.0)); // 75th percentile at index 6
    });

    test('StatisticalFunctions handles empty lists', () {
      expect(StatisticalFunctions.mean([]).isNaN, isTrue);
      expect(StatisticalFunctions.median([]).isNaN, isTrue);
    });

    test('StatisticalFunctions.minMax() is efficient', () {
      final values = [3.0, 1.0, 4.0, 1.0, 5.0, 9.0, 2.0, 6.0];
      final mm = StatisticalFunctions.minMax(values);
      expect(mm.min, equals(1.0));
      expect(mm.max, equals(9.0));
      expect(mm.range, equals(8.0));
    });

    test('StatisticalFunctions performance <10ms for 10k values', () {
      // This will be verified in performance benchmarks (T028)
      // For now, just verify the API exists
      final values = List.generate(100, (i) => i.toDouble());
      final avg = StatisticalFunctions.mean(values);
      expect(avg, isNotNull);
    });
  });

  group('InterpolationFunctions Contract Tests', () {
    test('InterpolationFunctions.lerp() exists', () {
      expect(InterpolationFunctions.lerp(0.0, 10.0, 0.0), equals(0.0));
      expect(InterpolationFunctions.lerp(0.0, 10.0, 0.5), equals(5.0));
      expect(InterpolationFunctions.lerp(0.0, 10.0, 1.0), equals(10.0));
    });

    test('InterpolationFunctions.lerpInverse() exists', () {
      final t = InterpolationFunctions.lerpInverse(0.0, 10.0, 5.0);
      expect(t, equals(0.5));
    });

    test('InterpolationFunctions.cubicSpline() exists', () {
      final points = [
        const ChartDataPoint(x: 0.0, y: 0.0),
        const ChartDataPoint(x: 1.0, y: 1.0),
        const ChartDataPoint(x: 2.0, y: 0.0),
      ];
      final samples = InterpolationFunctions.cubicSpline(points, 100);
      expect(samples.length, equals(100));
      expect(samples.first, closeTo(0.0, 0.01));
      expect(samples.last, closeTo(0.0, 0.01));
    });

    test('InterpolationFunctions.hermite() exists', () {
      final val = InterpolationFunctions.hermite(0.0, 1.0, 0.0, 0.0, 0.5);
      expect(val, isA<double>());
    });

    test('InterpolationFunctions.catmullRom() exists', () {
      final points = [
        const ChartDataPoint(x: 0.0, y: 0.0),
        const ChartDataPoint(x: 1.0, y: 1.0),
        const ChartDataPoint(x: 2.0, y: 0.0),
        const ChartDataPoint(x: 3.0, y: 1.0),
      ];
      final samples = InterpolationFunctions.catmullRom(points, 100);
      expect(samples.isNotEmpty, isTrue);
    });

    test('InterpolationFunctions.bezier() exists', () {
      final controlPoints = [0.0, 1.0, 1.0, 0.0];
      final val = InterpolationFunctions.bezier(controlPoints, 0.5);
      expect(val, isA<double>());
    });

    test('Interpolation endpoints are preserved', () {
      // cubicBezier should preserve endpoints
      final samples =
          InterpolationFunctions.cubicBezier(0.0, 1.0, 1.0, 2.0, 10);
      expect(samples.first, equals(0.0));
      expect(samples.last, equals(2.0));
    });
  });

  group('CurveFittingFunctions Contract Tests', () {
    test('CurveFittingFunctions.linearFit() exists', () {
      final points = [
        const ChartDataPoint(x: 0.0, y: 0.0),
        const ChartDataPoint(x: 1.0, y: 2.0),
        const ChartDataPoint(x: 2.0, y: 4.0),
        const ChartDataPoint(x: 3.0, y: 6.0),
      ];
      final fit = CurveFittingFunctions.linearFit(points);
      expect(fit.coefficients.length, equals(2)); // y = mx + b
      expect(fit.coefficients[0], closeTo(0.0, 0.01)); // b (intercept)
      expect(fit.coefficients[1], closeTo(2.0, 0.01)); // m (slope)
      expect(fit.rSquared, closeTo(1.0, 0.01)); // Perfect fit
    });

    test('CurveFittingFunctions.polynomialFit() exists', () {
      final points = [
        const ChartDataPoint(x: 0.0, y: 1.0),
        const ChartDataPoint(x: 1.0, y: 2.0),
        const ChartDataPoint(x: 2.0, y: 5.0),
      ];
      final fit = CurveFittingFunctions.polynomialFit(points, degree: 2);
      expect(fit.coefficients.length, equals(3)); // Quadratic
    });

    test('CurveFittingFunctions.exponentialFit() exists', () {
      final points = [
        const ChartDataPoint(x: 0.0, y: 1.0),
        const ChartDataPoint(x: 1.0, y: 2.7),
        const ChartDataPoint(x: 2.0, y: 7.4),
      ];
      final fit = CurveFittingFunctions.exponentialFit(points);
      expect(fit, isA<FitResult>());
    });

    test('CurveFittingFunctions.logarithmicFit() exists', () {
      final points = [
        const ChartDataPoint(x: 1.0, y: 2.0),
        const ChartDataPoint(x: 2.7, y: 3.0),
        const ChartDataPoint(x: 7.4, y: 4.0),
      ];
      final fit = CurveFittingFunctions.logarithmicFit(points);
      expect(fit, isA<FitResult>());
    });

    test('FitResult includes R² and residuals', () {
      final points = [
        const ChartDataPoint(x: 0.0, y: 0.0),
        const ChartDataPoint(x: 1.0, y: 2.0),
        const ChartDataPoint(x: 2.0, y: 4.0),
      ];
      final fit = CurveFittingFunctions.linearFit(points);
      expect(fit.rSquared, isA<double>());
      expect(fit.residuals, isA<List<double>>());
      expect(fit.equation, isA<String>());
    });

    test('Curve fitting performance <50ms for polynomial', () {
      // This will be verified in performance benchmarks (T028)
      // Basic smoke test: ensure polynomial fit completes
      final points = List.generate(
        100,
        (i) => ChartDataPoint(x: i.toDouble(), y: i * i.toDouble()),
      );
      final fit = CurveFittingFunctions.polynomialFit(points, degree: 2);
      expect(fit.coefficients.length, equals(3));
    });
  });
}
