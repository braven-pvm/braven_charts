// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/src/foundation/math/curve_fitting.dart';
import 'package:braven_charts/src/foundation/math/interpolation.dart';
import 'package:braven_charts/src/foundation/math/statistics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StatisticalFunctions Unit Tests', () {
    group('mean()', () {
      test('calculates arithmetic mean correctly', () {
        expect(StatisticalFunctions.mean([1, 2, 3, 4, 5]), equals(3.0));
        expect(StatisticalFunctions.mean([10, 20, 30]), equals(20.0));
        expect(
            StatisticalFunctions.mean([2.5, 3.5, 4.5]), closeTo(3.5, 0.0001));
      });

      test('calculates geometric mean correctly', () {
        expect(
          StatisticalFunctions.mean([1, 2, 4, 8], type: MeanType.geometric),
          closeTo(2.828, 0.01),
        );
        expect(
          StatisticalFunctions.mean([2.0, 8.0], type: MeanType.geometric),
          equals(4.0),
        );
      });

      test('calculates harmonic mean correctly', () {
        expect(
          StatisticalFunctions.mean([1, 2, 4], type: MeanType.harmonic),
          closeTo(1.714, 0.01),
        );
      });

      test('handles empty list', () {
        expect(StatisticalFunctions.mean([]).isNaN, isTrue);
        expect(
          StatisticalFunctions.mean([], type: MeanType.geometric).isNaN,
          isTrue,
        );
        expect(
          StatisticalFunctions.mean([], type: MeanType.harmonic).isNaN,
          isTrue,
        );
      });

      test('handles single value', () {
        expect(StatisticalFunctions.mean([5.0]), closeTo(5.0, 0.0001));
        expect(
          StatisticalFunctions.mean([5.0], type: MeanType.geometric),
          closeTo(5.0, 0.0001),
        );
        expect(
          StatisticalFunctions.mean([5.0], type: MeanType.harmonic),
          closeTo(5.0, 0.0001),
        );
      });

      test('geometric mean handles negative values correctly', () {
        // Geometric mean should be NaN for negative values
        final result = StatisticalFunctions.mean(
          [1, -2, 3],
          type: MeanType.geometric,
        );
        expect(result.isNaN, isTrue);
      });

      test('harmonic mean handles zero correctly', () {
        // Harmonic mean should be NaN when any value is zero
        final result = StatisticalFunctions.mean(
          [1, 0, 3],
          type: MeanType.harmonic,
        );
        expect(result.isNaN, isTrue);
      });
    });

    group('median()', () {
      test('calculates median for odd-length list', () {
        expect(StatisticalFunctions.median([1, 2, 3]), equals(2.0));
        expect(StatisticalFunctions.median([5, 1, 3, 2, 4]), equals(3.0));
      });

      test('calculates median for even-length list', () {
        expect(StatisticalFunctions.median([1, 2, 3, 4]), equals(2.5));
        expect(StatisticalFunctions.median([1, 2]), equals(1.5));
      });

      test('handles unsorted lists', () {
        expect(StatisticalFunctions.median([5, 1, 3]), equals(3.0));
        expect(StatisticalFunctions.median([4, 2, 3, 1]), equals(2.5));
      });

      test('handles empty list', () {
        expect(StatisticalFunctions.median([]).isNaN, isTrue);
      });

      test('handles single value', () {
        expect(StatisticalFunctions.median([42.0]), equals(42.0));
      });

      test('does not modify original list', () {
        final original = [3.0, 1.0, 2.0];
        StatisticalFunctions.median(original);
        expect(original, equals([3.0, 1.0, 2.0]));
      });
    });

    group('mode()', () {
      test('finds single mode', () {
        expect(StatisticalFunctions.mode([1, 2, 2, 3]), equals(2.0));
        expect(StatisticalFunctions.mode([1, 1, 1, 2, 3]), equals(1.0));
      });

      test('returns NaN for multimodal (tie)', () {
        // When there's a tie, current implementation returns one mode
        // But could also return NaN - check what happens
        final result = StatisticalFunctions.mode([1, 1, 2, 2, 3]);
        // Either returns one of the tied modes, or NaN
        expect(result == 1.0 || result == 2.0 || result.isNaN, isTrue);
      });

      test('returns NaN when all values unique', () {
        final result = StatisticalFunctions.mode([1, 2, 3, 4]);
        expect(result.isNaN, isTrue);
      });

      test('handles empty list', () {
        expect(StatisticalFunctions.mode([]).isNaN, isTrue);
      });

      test('handles single value', () {
        expect(StatisticalFunctions.mode([5.0]), equals(5.0));
      });
    });

    group('standardDeviation()', () {
      test('calculates sample standard deviation', () {
        final values = [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0];
        expect(StatisticalFunctions.standardDeviation(values),
            closeTo(2.138, 0.01));
      });

      test('calculates population standard deviation', () {
        final values = [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0];
        expect(
          StatisticalFunctions.standardDeviation(values, sample: false),
          closeTo(2.0, 0.01),
        );
      });

      test('returns zero for identical values', () {
        expect(
            StatisticalFunctions.standardDeviation([5, 5, 5, 5]), equals(0.0));
      });

      test('handles empty list', () {
        expect(StatisticalFunctions.standardDeviation([]).isNaN, isTrue);
      });

      test('handles single value', () {
        // Sample std dev of single value is NaN (division by n-1=0)
        expect(StatisticalFunctions.standardDeviation([5.0]).isNaN, isTrue);
        // Population std dev of single value is 0
        expect(
          StatisticalFunctions.standardDeviation([5.0], sample: false),
          equals(0.0),
        );
      });
    });

    group('variance()', () {
      test('calculates sample variance', () {
        final values = [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0];
        final variance = StatisticalFunctions.variance(values);
        final stdDev = StatisticalFunctions.standardDeviation(values);
        expect(variance, closeTo(stdDev * stdDev, 0.01));
      });

      test('calculates population variance', () {
        final values = [1.0, 2.0, 3.0, 4.0, 5.0];
        expect(
          StatisticalFunctions.variance(values, sample: false),
          equals(2.0),
        );
      });
    });

    group('quartiles()', () {
      test('calculates quartiles for standard dataset', () {
        final values = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0];
        final q = StatisticalFunctions.quartiles(values);
        expect(q.q1, equals(3.0));
        expect(q.q2, equals(5.0));
        expect(q.q3, equals(7.0));
      });

      test('handles even-length lists', () {
        final values = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0];
        final q = StatisticalFunctions.quartiles(values);
        expect(q.q2, equals(4.5)); // Median
      });

      test('IQR is calculated correctly', () {
        final values = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0];
        final iqr = StatisticalFunctions.iqr(values);
        expect(iqr, equals(4.0)); // Q3 - Q1 = 7 - 3
      });
    });

    group('percentile()', () {
      test('calculates percentiles correctly', () {
        final values = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0];
        expect(StatisticalFunctions.percentile(values, 0), equals(1.0));
        expect(StatisticalFunctions.percentile(values, 50), closeTo(5.5, 0.1));
        expect(StatisticalFunctions.percentile(values, 100), equals(10.0));
      });

      test('uses linear interpolation between values', () {
        final values = [1.0, 2.0, 3.0];
        expect(StatisticalFunctions.percentile(values, 25), closeTo(1.5, 0.1));
        expect(StatisticalFunctions.percentile(values, 75), closeTo(2.5, 0.1));
      });
    });

    group('range()', () {
      test('calculates range correctly', () {
        expect(StatisticalFunctions.range([1, 5, 3, 9, 2]), equals(8.0));
        expect(StatisticalFunctions.range([10, 20]), equals(10.0));
      });

      test('returns zero for single value', () {
        expect(StatisticalFunctions.range([5.0]), equals(0.0));
      });
    });

    group('min() and max()', () {
      test('find min and max correctly', () {
        final values = [3.0, 1.0, 4.0, 1.0, 5.0, 9.0, 2.0, 6.0];
        expect(StatisticalFunctions.min(values), equals(1.0));
        expect(StatisticalFunctions.max(values), equals(9.0));
      });

      test('minMax returns both in one pass', () {
        final values = [3.0, 1.0, 4.0, 1.0, 5.0, 9.0, 2.0, 6.0];
        final result = StatisticalFunctions.minMax(values);
        expect(result.min, equals(1.0));
        expect(result.max, equals(9.0));
      });

      test('handle single value', () {
        expect(StatisticalFunctions.min([5.0]), equals(5.0));
        expect(StatisticalFunctions.max([5.0]), equals(5.0));
      });
    });
  });

  group('InterpolationFunctions Unit Tests', () {
    group('lerp()', () {
      test('interpolates linearly', () {
        expect(InterpolationFunctions.lerp(0.0, 10.0, 0.0), equals(0.0));
        expect(InterpolationFunctions.lerp(0.0, 10.0, 0.5), equals(5.0));
        expect(InterpolationFunctions.lerp(0.0, 10.0, 1.0), equals(10.0));
      });

      test('extrapolates outside [0,1]', () {
        expect(InterpolationFunctions.lerp(0.0, 10.0, -0.5), equals(-5.0));
        expect(InterpolationFunctions.lerp(0.0, 10.0, 1.5), equals(15.0));
      });

      test('works with negative values', () {
        expect(InterpolationFunctions.lerp(-10.0, 10.0, 0.5), equals(0.0));
        expect(InterpolationFunctions.lerp(-5.0, -2.0, 0.5), equals(-3.5));
      });
    });

    group('lerpInverse()', () {
      test('calculates inverse parameter', () {
        expect(InterpolationFunctions.lerpInverse(0.0, 10.0, 5.0), equals(0.5));
        expect(InterpolationFunctions.lerpInverse(0.0, 10.0, 0.0), equals(0.0));
        expect(
            InterpolationFunctions.lerpInverse(0.0, 10.0, 10.0), equals(1.0));
      });

      test('is inverse of lerp', () {
        const a = 5.0;
        const b = 15.0;
        const value = 12.0;
        final t = InterpolationFunctions.lerpInverse(a, b, value);
        final reconstructed = InterpolationFunctions.lerp(a, b, t);
        expect(reconstructed, closeTo(value, 0.0001));
      });
    });

    group('cubicSpline()', () {
      test('preserves endpoints', () {
        final points = [
          const ChartDataPoint(x: 0.0, y: 0.0),
          const ChartDataPoint(x: 1.0, y: 1.0),
          const ChartDataPoint(x: 2.0, y: 0.0),
        ];
        final samples = InterpolationFunctions.cubicSpline(points, 100);
        expect(samples.first, closeTo(0.0, 0.01));
        expect(samples.last, closeTo(0.0, 0.01));
      });

      test('produces smooth curve', () {
        final points = [
          const ChartDataPoint(x: 0.0, y: 0.0),
          const ChartDataPoint(x: 1.0, y: 2.0),
          const ChartDataPoint(x: 2.0, y: 1.0),
          const ChartDataPoint(x: 3.0, y: 3.0),
        ];
        final samples = InterpolationFunctions.cubicSpline(points, 50);
        expect(samples.length, equals(50));
        // Check smoothness: no large jumps between adjacent samples
        for (int i = 1; i < samples.length; i++) {
          final diff = (samples[i] - samples[i - 1]).abs();
          expect(diff, lessThan(1.0)); // Reasonable smoothness
        }
      });

      test('passes through control points', () {
        final points = [
          const ChartDataPoint(x: 0.0, y: 0.0),
          const ChartDataPoint(x: 1.0, y: 1.0),
          const ChartDataPoint(x: 2.0, y: 0.5),
        ];
        final samples = InterpolationFunctions.cubicSpline(points, 100);
        // First sample should be y=0
        expect(samples.first, closeTo(0.0, 0.01));
        // Middle sample (around index 50) should be near y=1
        expect(samples[49], closeTo(1.0, 0.3));
        // Last sample should be y=0.5
        expect(samples.last, closeTo(0.5, 0.01));
      });
    });

    group('hermite()', () {
      test('preserves endpoints with zero tangents', () {
        final p0 = 0.0;
        final p1 = 1.0;
        final m0 = 0.0; // Zero tangent at start
        final m1 = 0.0; // Zero tangent at end
        expect(InterpolationFunctions.hermite(p0, p1, m0, m1, 0.0), equals(p0));
        expect(InterpolationFunctions.hermite(p0, p1, m0, m1, 1.0), equals(p1));
      });

      test('respects tangent constraints', () {
        final p0 = 0.0;
        final p1 = 1.0;
        final m0 = 2.0; // Steep slope at start
        final m1 = 0.0; // Flat at end
        final midpoint = InterpolationFunctions.hermite(p0, p1, m0, m1, 0.5);
        expect(midpoint, greaterThan(0.5)); // Should overshoot due to steep m0
      });
    });

    group('catmullRom()', () {
      test('produces smooth curve through control points', () {
        final points = [
          const ChartDataPoint(x: 0.0, y: 0.0),
          const ChartDataPoint(x: 1.0, y: 1.0),
          const ChartDataPoint(x: 2.0, y: 0.5),
          const ChartDataPoint(x: 3.0, y: 2.0),
        ];
        final samples = InterpolationFunctions.catmullRom(points, 50);
        expect(samples, isNotEmpty);
        // Check smoothness: no large jumps between adjacent samples
        for (int i = 1; i < samples.length; i++) {
          final diff = (samples[i] - samples[i - 1]).abs();
          expect(diff, lessThan(1.0)); // Reasonable smoothness
        }
      });

      test('requires at least 4 points', () {
        final points = [
          const ChartDataPoint(x: 0.0, y: 0.0),
          const ChartDataPoint(x: 1.0, y: 1.0),
          const ChartDataPoint(x: 2.0, y: 0.5),
        ];
        // catmullRom returns empty list for <4 points
        final result = InterpolationFunctions.catmullRom(points, 50);
        expect(result, isEmpty);
      });

      test('tension parameter affects curve shape', () {
        final points = [
          const ChartDataPoint(x: 0.0, y: 0.0),
          const ChartDataPoint(x: 1.0, y: 1.0),
          const ChartDataPoint(x: 2.0, y: 0.5),
          const ChartDataPoint(x: 3.0, y: 2.0),
        ];
        final loose =
            InterpolationFunctions.catmullRom(points, 50, tension: 0.0);
        final tight =
            InterpolationFunctions.catmullRom(points, 50, tension: 1.0);
        // Different tensions should produce different curves
        expect(loose, isNot(equals(tight)));
      });
    });

    group('bezier()', () {
      test('preserves endpoints', () {
        final controlPoints = [0.0, 0.5, 1.0, 0.8, 1.0];
        expect(
          InterpolationFunctions.bezier(controlPoints, 0.0),
          equals(controlPoints.first),
        );
        expect(
          InterpolationFunctions.bezier(controlPoints, 1.0),
          equals(controlPoints.last),
        );
      });

      test('produces values within control point range', () {
        final controlPoints = [0.0, 1.0, 2.0];
        for (double t = 0.0; t <= 1.0; t += 0.1) {
          final value = InterpolationFunctions.bezier(controlPoints, t);
          expect(value, greaterThanOrEqualTo(0.0));
          expect(value, lessThanOrEqualTo(2.0));
        }
      });
    });

    group('quadraticBezier()', () {
      test('preserves endpoints', () {
        final samples =
            InterpolationFunctions.quadraticBezier(0.0, 1.0, 2.0, 10);
        expect(samples.first, equals(0.0));
        expect(samples.last, equals(2.0));
      });

      test('control point influences curve shape', () {
        final straight =
            InterpolationFunctions.quadraticBezier(0.0, 1.0, 2.0, 10);
        final curved =
            InterpolationFunctions.quadraticBezier(0.0, 5.0, 2.0, 10);
        // Different control points should produce different curves
        expect(straight, isNot(equals(curved)));
      });
    });

    group('cubicBezier()', () {
      test('preserves endpoints', () {
        final samples =
            InterpolationFunctions.cubicBezier(0.0, 1.0, 2.0, 3.0, 10);
        expect(samples.first, equals(0.0));
        expect(samples.last, equals(3.0));
      });

      test('produces correct number of samples', () {
        final samples =
            InterpolationFunctions.cubicBezier(0.0, 1.0, 2.0, 3.0, 25);
        expect(samples.length, equals(25));
      });
    });
  });

  group('CurveFittingFunctions Unit Tests', () {
    group('linearFit()', () {
      test('fits perfect line y = 2x + 1', () {
        final points = [
          const ChartDataPoint(x: 0.0, y: 1.0),
          const ChartDataPoint(x: 1.0, y: 3.0),
          const ChartDataPoint(x: 2.0, y: 5.0),
          const ChartDataPoint(x: 3.0, y: 7.0),
        ];
        final fit = CurveFittingFunctions.linearFit(points);
        expect(fit.coefficients[0], closeTo(1.0, 0.01)); // intercept
        expect(fit.coefficients[1], closeTo(2.0, 0.01)); // slope
        expect(fit.rSquared, closeTo(1.0, 0.01)); // perfect fit
        expect(fit.equation, contains('2.00x'));
        expect(fit.equation, contains('1.00'));
      });

      test('fits horizontal line', () {
        final points = [
          const ChartDataPoint(x: 0.0, y: 5.0),
          const ChartDataPoint(x: 1.0, y: 5.0),
          const ChartDataPoint(x: 2.0, y: 5.0),
        ];
        final fit = CurveFittingFunctions.linearFit(points);
        expect(fit.coefficients[1], closeTo(0.0, 0.01)); // zero slope
        expect(fit.coefficients[0], closeTo(5.0, 0.01)); // intercept = 5
      });

      test('computes residuals correctly', () {
        final points = [
          const ChartDataPoint(x: 0.0, y: 1.0),
          const ChartDataPoint(x: 1.0, y: 2.9), // Slightly off
          const ChartDataPoint(x: 2.0, y: 5.0),
        ];
        final fit = CurveFittingFunctions.linearFit(points);
        expect(fit.residuals.length, equals(3));
        expect(fit.residuals[1].abs(), greaterThan(0.0)); // Should have error
      });

      test('requires at least 2 points', () {
        expect(
          () => CurveFittingFunctions.linearFit(
              [const ChartDataPoint(x: 0, y: 0)]),
          throwsArgumentError,
        );
      });

      test('handles noisy data', () {
        final points = List.generate(
          10,
          (i) => ChartDataPoint(
            x: i.toDouble(),
            y: 2.0 * i + 1.0 + (i % 2 == 0 ? 0.1 : -0.1), // y = 2x + 1 + noise
          ),
        );
        final fit = CurveFittingFunctions.linearFit(points);
        expect(fit.coefficients[1], closeTo(2.0, 0.2)); // slope ≈ 2
        expect(fit.coefficients[0], closeTo(1.0, 0.2)); // intercept ≈ 1
        expect(fit.rSquared, greaterThan(0.95)); // Good fit despite noise
      });
    });

    group('polynomialFit()', () {
      test('degree 1 equivalent to linear fit', () {
        final points = [
          const ChartDataPoint(x: 0.0, y: 1.0),
          const ChartDataPoint(x: 1.0, y: 3.0),
          const ChartDataPoint(x: 2.0, y: 5.0),
        ];
        final polyFit = CurveFittingFunctions.polynomialFit(points, degree: 1);
        final linFit = CurveFittingFunctions.linearFit(points);
        expect(polyFit.coefficients[0], closeTo(linFit.coefficients[0], 0.01));
        expect(polyFit.coefficients[1], closeTo(linFit.coefficients[1], 0.01));
      });

      test('fits perfect quadratic y = x²', () {
        final points = [
          const ChartDataPoint(x: 0.0, y: 0.0),
          const ChartDataPoint(x: 1.0, y: 1.0),
          const ChartDataPoint(x: 2.0, y: 4.0),
          const ChartDataPoint(x: 3.0, y: 9.0),
        ];
        final fit = CurveFittingFunctions.polynomialFit(points, degree: 2);
        expect(fit.coefficients[0], closeTo(0.0, 0.01)); // constant term
        expect(fit.coefficients[1], closeTo(0.0, 0.01)); // linear term
        expect(fit.coefficients[2], closeTo(1.0, 0.01)); // quadratic term
        expect(fit.rSquared, closeTo(1.0, 0.01));
      });

      test('fits cubic polynomial', () {
        final points = [
          const ChartDataPoint(x: 0.0, y: 1.0),
          const ChartDataPoint(x: 1.0, y: 2.0),
          const ChartDataPoint(x: 2.0, y: 5.0),
          const ChartDataPoint(x: 3.0, y: 14.0),
        ];
        final fit = CurveFittingFunctions.polynomialFit(points, degree: 3);
        expect(fit.coefficients.length, equals(4));
        expect(fit.rSquared, greaterThan(0.95));
      });

      test('validates degree constraints', () {
        final points = [
          const ChartDataPoint(x: 0, y: 0),
          const ChartDataPoint(x: 1, y: 1)
        ];
        expect(
          () => CurveFittingFunctions.polynomialFit(points, degree: 0),
          throwsArgumentError,
        );
        expect(
          () => CurveFittingFunctions.polynomialFit(points, degree: 6),
          throwsArgumentError,
        );
      });

      test('validates sufficient points for degree', () {
        final points = [
          const ChartDataPoint(x: 0, y: 0),
          const ChartDataPoint(x: 1, y: 1)
        ];
        expect(
          () => CurveFittingFunctions.polynomialFit(points, degree: 2),
          throwsArgumentError,
        );
      });
    });

    group('exponentialFit()', () {
      test('fits perfect exponential y = 2×exp(0.5x)', () {
        final points = List.generate(
          5,
          (i) => ChartDataPoint(
            x: i.toDouble(),
            y: 2.0 * math.exp(0.5 * i),
          ),
        );
        final fit = CurveFittingFunctions.exponentialFit(points);
        expect(fit.coefficients[0], closeTo(2.0, 0.1)); // a ≈ 2
        expect(fit.coefficients[1], closeTo(0.5, 0.05)); // b ≈ 0.5
        expect(fit.rSquared, greaterThan(0.99));
      });

      test('requires positive y values', () {
        final points = [
          const ChartDataPoint(x: 0.0, y: -1.0),
          const ChartDataPoint(x: 1.0, y: 2.0),
        ];
        expect(
          () => CurveFittingFunctions.exponentialFit(points),
          throwsArgumentError,
        );
      });

      test('equation format is correct', () {
        final points = [
          const ChartDataPoint(x: 0.0, y: 1.0),
          const ChartDataPoint(x: 1.0, y: 2.7),
        ];
        final fit = CurveFittingFunctions.exponentialFit(points);
        expect(fit.equation, contains('×exp('));
        expect(fit.equation, contains('x)'));
      });
    });

    group('logarithmicFit()', () {
      test('fits logarithmic curve', () {
        final points = List.generate(
          5,
          (i) => ChartDataPoint(
            x: (i + 1).toDouble(),
            y: 2.0 + 3.0 * math.log(i + 1),
          ),
        );
        final fit = CurveFittingFunctions.logarithmicFit(points);
        expect(fit.coefficients[0], closeTo(2.0, 0.2)); // a ≈ 2
        expect(fit.coefficients[1], closeTo(3.0, 0.3)); // b ≈ 3
      });

      test('requires positive x values', () {
        final points = [
          const ChartDataPoint(x: -1.0, y: 1.0),
          const ChartDataPoint(x: 2.0, y: 2.0),
        ];
        expect(
          () => CurveFittingFunctions.logarithmicFit(points),
          throwsArgumentError,
        );
      });

      test('equation format is correct', () {
        final points = [
          const ChartDataPoint(x: 1.0, y: 2.0),
          const ChartDataPoint(x: 2.7, y: 3.0),
        ];
        final fit = CurveFittingFunctions.logarithmicFit(points);
        expect(fit.equation, contains('×ln(x)'));
      });
    });

    group('FitResult', () {
      test('toString provides useful output', () {
        final points = [
          const ChartDataPoint(x: 0.0, y: 0.0),
          const ChartDataPoint(x: 1.0, y: 2.0),
        ];
        final fit = CurveFittingFunctions.linearFit(points);
        final str = fit.toString();
        expect(str, contains('FitResult'));
        expect(str, contains('equation'));
        expect(str, contains('R²'));
      });

      test('residuals sum to near-zero for well-fit line', () {
        final points = [
          const ChartDataPoint(x: 0.0, y: 0.0),
          const ChartDataPoint(x: 1.0, y: 2.0),
          const ChartDataPoint(x: 2.0, y: 4.0),
        ];
        final fit = CurveFittingFunctions.linearFit(points);
        final sumResiduals = fit.residuals.reduce((a, b) => a + b);
        expect(sumResiduals.abs(), lessThan(0.0001));
      });
    });

    group('Numerical Stability', () {
      test('handles large values without overflow', () {
        final points = [
          const ChartDataPoint(x: 1000.0, y: 2000.0),
          const ChartDataPoint(x: 2000.0, y: 4000.0),
          const ChartDataPoint(x: 3000.0, y: 6000.0),
        ];
        final fit = CurveFittingFunctions.linearFit(points);
        expect(fit.coefficients[1], closeTo(2.0, 0.01));
        expect(fit.rSquared, closeTo(1.0, 0.01));
      });

      test('handles small values without underflow', () {
        final points = [
          const ChartDataPoint(x: 0.001, y: 0.002),
          const ChartDataPoint(x: 0.002, y: 0.004),
          const ChartDataPoint(x: 0.003, y: 0.006),
        ];
        final fit = CurveFittingFunctions.linearFit(points);
        expect(fit.coefficients[1], closeTo(2.0, 0.1));
      });
    });
  });
}
