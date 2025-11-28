// Copyright 2024 The Braven Charts Authors
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:braven_charts/legacy/src/foundation/foundation.dart';

/// Integration test for Foundation Layer Math Utilities (FR-004)
///
/// Validates complete math utilities workflows:
/// - Statistical calculations (mean, median, std dev, quartiles)
/// - Interpolation functions (linear, cubic spline, bezier)
/// - Curve fitting (linear, polynomial regression)
/// - Performance requirements (FR-005.5, FR-005.6)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Foundation Math Utilities - Statistics', () {
    test('4.1 - Statistical central tendency calculations', () {
      final data = [10.0, 20.0, 30.0, 40.0, 50.0];

      // Arithmetic mean
      final mean = StatisticalFunctions.mean(data);
      expect(mean, equals(30.0));

      // Median
      final median = StatisticalFunctions.median(data);
      expect(median, equals(30.0));

      // Geometric mean
      final geometricMean = StatisticalFunctions.mean(
        data,
        type: MeanType.geometric,
      );
      expect(geometricMean, greaterThan(25.0));
      expect(geometricMean, lessThan(30.0)); // Geometric mean < arithmetic mean

      // Harmonic mean
      final harmonicMean = StatisticalFunctions.mean(
        data,
        type: MeanType.harmonic,
      );
      expect(harmonicMean, greaterThan(20.0));
      expect(harmonicMean,
          lessThan(geometricMean)); // Harmonic < geometric < arithmetic

      print('✅ Statistical central tendency calculations work correctly');
      print('   Mean: $mean, Median: $median');
      print(
          '   Geometric: ${geometricMean.toStringAsFixed(2)}, Harmonic: ${harmonicMean.toStringAsFixed(2)}');
    });

    test('4.2 - Statistical dispersion calculations', () {
      final data = [10.0, 20.0, 30.0, 40.0, 50.0];

      // Standard deviation
      final stdDev = StatisticalFunctions.standardDeviation(data);
      expect(stdDev, greaterThan(15.0));
      expect(stdDev, lessThan(16.0)); // ~15.81

      // Variance
      final variance = StatisticalFunctions.variance(data);
      expect(variance, closeTo(250.0, 1.0)); // stdDev² ≈ 250

      // Range
      final range = StatisticalFunctions.range(data);
      expect(range, equals(40.0)); // 50 - 10

      print('✅ Statistical dispersion calculations work correctly');
      print(
          '   StdDev: ${stdDev.toStringAsFixed(2)}, Variance: ${variance.toStringAsFixed(2)}, Range: $range');
    });

    test('4.3 - Quartiles and percentiles', () {
      final data = [10.0, 20.0, 30.0, 40.0, 50.0];

      // Quartiles
      final quartiles = StatisticalFunctions.quartiles(data);
      expect(quartiles.q1, equals(20.0));
      expect(quartiles.q2, equals(30.0)); // Median
      expect(quartiles.q3, equals(40.0));
      expect(quartiles.iqr, equals(20.0)); // Q3 - Q1

      // Percentiles
      final p25 = StatisticalFunctions.percentile(data, 25);
      expect(p25, equals(quartiles.q1));

      final p50 = StatisticalFunctions.percentile(data, 50);
      expect(p50, equals(quartiles.q2));

      final p75 = StatisticalFunctions.percentile(data, 75);
      expect(p75, equals(quartiles.q3));

      print('✅ Quartiles and percentiles work correctly');
      print(
          '   Q1: ${quartiles.q1}, Q2: ${quartiles.q2}, Q3: ${quartiles.q3}, IQR: ${quartiles.iqr}');
    });

    test('4.4 - Statistical calculations performance (FR-005.5)', () {
      // Generate 10k values
      final largeData = List.generate(10000, (i) => i.toDouble());

      // Test mean performance
      final stopwatch = Stopwatch()..start();
      final largeMean = StatisticalFunctions.mean(largeData);
      stopwatch.stop();

      expect(largeMean, equals(4999.5)); // (0 + 9999) / 2
      expect(stopwatch.elapsedMilliseconds, lessThan(10)); // <10ms (FR-005.5)

      print('✅ Statistical calculations performance validated');
      print(
          '   Calculated mean of 10k values in ${stopwatch.elapsedMilliseconds}ms (target: <10ms)');
    });

    test('4.5 - Statistical edge cases', () {
      // Empty list
      expect(StatisticalFunctions.mean([]), isNaN);
      expect(StatisticalFunctions.median([]), isNaN);
      expect(StatisticalFunctions.standardDeviation([]), isNaN);

      // Single value
      expect(StatisticalFunctions.mean([42.0]), equals(42.0));
      expect(StatisticalFunctions.median([42.0]), equals(42.0));
      expect(StatisticalFunctions.standardDeviation([42.0]),
          isNaN); // Single value -> NaN

      // All same values
      final constant = [5.0, 5.0, 5.0, 5.0];
      expect(StatisticalFunctions.mean(constant), equals(5.0));
      expect(StatisticalFunctions.standardDeviation(constant), equals(0.0));

      print('✅ Statistical edge cases handled correctly');
    });
  });

  group('Foundation Math Utilities - Interpolation', () {
    test('4.6 - Linear interpolation', () {
      // Basic lerp
      final lerp1 = InterpolationFunctions.lerp(0.0, 100.0, 0.5);
      expect(lerp1, equals(50.0));

      final lerp2 = InterpolationFunctions.lerp(10.0, 20.0, 0.25);
      expect(lerp2, equals(12.5));

      // Edge cases
      final lerp3 = InterpolationFunctions.lerp(0.0, 100.0, 0.0);
      expect(lerp3, equals(0.0)); // Start point

      final lerp4 = InterpolationFunctions.lerp(0.0, 100.0, 1.0);
      expect(lerp4, equals(100.0)); // End point

      // Extrapolation
      final lerp5 = InterpolationFunctions.lerp(0.0, 100.0, 1.5);
      expect(lerp5, equals(150.0)); // Beyond range

      print('✅ Linear interpolation works correctly');
    });

    test('4.7 - Cubic spline interpolation', () {
      // Create quadratic data points: y = x²
      final points = [
        ChartDataPoint(x: 0, y: 0),
        ChartDataPoint(x: 1, y: 1),
        ChartDataPoint(x: 2, y: 4),
        ChartDataPoint(x: 3, y: 9),
      ];

      final spline = InterpolationFunctions.cubicSpline(points, 100);

      expect(spline.length, equals(100));
      expect(spline.first, equals(0.0)); // First point preserved
      expect((spline.last - 9.0).abs(), lessThan(0.1)); // Last point preserved

      // Check interpolation produces smooth curve
      for (int i = 1; i < spline.length; i++) {
        expect(spline[i],
            greaterThanOrEqualTo(spline[i - 1])); // Monotonically increasing
      }

      print('✅ Cubic spline interpolation works correctly');
      print('   Generated ${spline.length} samples, endpoints preserved');
    });

    test('4.8 - Bezier curve interpolation', () {
      // Create bezier curve with 10 samples
      final bezier = InterpolationFunctions.cubicBezier(0, 33, 67, 100, 10);

      expect(bezier.length, equals(10));
      expect(bezier.first, equals(0.0)); // Start point
      expect(bezier.last, equals(100.0)); // End point

      // Check curve smoothness (no drastic jumps)
      for (int i = 1; i < bezier.length; i++) {
        final diff = (bezier[i] - bezier[i - 1]).abs();
        expect(diff, lessThan(50.0)); // Reasonable step size
      }

      print('✅ Bezier curve interpolation works correctly');
    });

    test('4.9 - Interpolation edge cases', () {
      // Empty points - returns empty list
      final emptyResult = InterpolationFunctions.cubicSpline([], 10);
      expect(emptyResult.isEmpty, isTrue);

      // Single point - returns empty list (need at least 2 points)
      final singlePoint = [ChartDataPoint(x: 5, y: 10)];
      final result = InterpolationFunctions.cubicSpline(singlePoint, 5);
      expect(result.isEmpty, isTrue);

      print('✅ Interpolation edge cases handled correctly');
    });
  });

  group('Foundation Math Utilities - Curve Fitting', () {
    test('4.10 - Linear regression fit', () {
      // Perfect linear data: y = 2x + 5
      final points = [
        ChartDataPoint(x: 0, y: 5),
        ChartDataPoint(x: 1, y: 7),
        ChartDataPoint(x: 2, y: 9),
        ChartDataPoint(x: 3, y: 11),
        ChartDataPoint(x: 4, y: 13),
      ];

      final stopwatch = Stopwatch()..start();
      final fit = CurveFittingFunctions.linearFit(points);
      stopwatch.stop();

      // Validate coefficients
      expect(
          (fit.coefficients[0] - 5.0).abs(), lessThan(0.01)); // Intercept ≈ 5
      expect((fit.coefficients[1] - 2.0).abs(), lessThan(0.01)); // Slope ≈ 2
      expect(fit.rSquared, greaterThan(0.99)); // Perfect fit
      expect(stopwatch.elapsedMilliseconds, lessThan(50)); // Fast computation

      print('✅ Linear regression fit works correctly');
      print('   Equation: ${fit.equation}');
      print('   R² = ${fit.rSquared.toStringAsFixed(4)}');
      print('   Computed in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('4.11 - Polynomial regression fit', () {
      // Quadratic data: y = x²
      final quadratic = [
        ChartDataPoint(x: 0, y: 0),
        ChartDataPoint(x: 1, y: 1),
        ChartDataPoint(x: 2, y: 4),
        ChartDataPoint(x: 3, y: 9),
        ChartDataPoint(x: 4, y: 16),
      ];

      final polyFit = CurveFittingFunctions.polynomialFit(quadratic, degree: 2);

      expect(polyFit.coefficients.length, equals(3)); // a₀, a₁, a₂
      expect(polyFit.rSquared, greaterThan(0.99)); // y = x²

      // Check coefficients approximately: y = 0 + 0x + 1x²
      expect(polyFit.coefficients[0].abs(), lessThan(0.01)); // Constant ≈ 0
      expect(polyFit.coefficients[1].abs(), lessThan(0.01)); // Linear ≈ 0
      expect((polyFit.coefficients[2] - 1.0).abs(),
          lessThan(0.01)); // Quadratic ≈ 1

      print('✅ Polynomial regression fit works correctly');
      print('   Equation: ${polyFit.equation}');
      print('   R² = ${polyFit.rSquared.toStringAsFixed(4)}');
    });

    test('4.12 - Curve fitting performance (FR-005.6)', () {
      // Generate large dataset for performance testing
      final largeData = List.generate(
        10000,
        (i) => ChartDataPoint(
          x: i.toDouble(),
          y: i * 2.0 + 5.0, // Linear: y = 2x + 5
        ),
      );

      final stopwatch = Stopwatch()..start();
      final fit = CurveFittingFunctions.linearFit(largeData);
      stopwatch.stop();

      expect(fit.coefficients[0], closeTo(5.0, 0.1)); // Intercept
      expect(fit.coefficients[1], closeTo(2.0, 0.01)); // Slope
      expect(stopwatch.elapsedMilliseconds, lessThan(50)); // <50ms (FR-005.6)

      print('✅ Curve fitting performance validated');
      print(
          '   Linear fit of 10k points in ${stopwatch.elapsedMilliseconds}ms (target: <50ms)');
    });

    test('4.13 - Curve fitting with noisy data', () {
      // Linear data with noise
      final noisyData = [
        ChartDataPoint(x: 0, y: 5.2),
        ChartDataPoint(x: 1, y: 6.8),
        ChartDataPoint(x: 2, y: 9.3),
        ChartDataPoint(x: 3, y: 10.7),
        ChartDataPoint(x: 4, y: 13.1),
      ];

      final fit = CurveFittingFunctions.linearFit(noisyData);

      // Should still approximate y = 2x + 5 reasonably well
      expect(fit.coefficients[0], greaterThan(4.0));
      expect(fit.coefficients[0], lessThan(6.0)); // Intercept ~5
      expect(fit.coefficients[1], greaterThan(1.5));
      expect(fit.coefficients[1], lessThan(2.5)); // Slope ~2
      expect(fit.rSquared, greaterThan(0.95)); // Good fit despite noise

      print('✅ Curve fitting handles noisy data correctly');
      print('   R² = ${fit.rSquared.toStringAsFixed(4)} with noisy data');
    });

    test('4.14 - Curve fitting edge cases', () {
      // Insufficient points for linear fit
      expect(
        () => CurveFittingFunctions.linearFit([]),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => CurveFittingFunctions.linearFit([ChartDataPoint(x: 1, y: 2)]),
        throwsA(isA<ArgumentError>()),
      );

      // Vertical line (undefined slope) - should handle gracefully
      final verticalData = [
        ChartDataPoint(x: 5, y: 1),
        ChartDataPoint(x: 5, y: 2),
        ChartDataPoint(x: 5, y: 3),
      ];
      final verticalFit = CurveFittingFunctions.linearFit(verticalData);
      expect(verticalFit.rSquared, isNaN); // R² undefined for vertical line

      print('✅ Curve fitting edge cases handled correctly');
    });
  });

  group('Foundation Math Utilities - Complete Workflow', () {
    test('End-to-end math utilities integration', () {
      print('\n=== Math Utilities Integration Test ===');

      // Step 1: Generate sample dataset
      print('\n1. Generating sample dataset...');
      final rawData = List.generate(
        1000,
        (i) => i * 0.5 + (i % 10 - 5), // Linear with periodic noise
      );

      // Step 2: Calculate statistics
      print('2. Calculating statistics...');
      final mean = StatisticalFunctions.mean(rawData);
      final median = StatisticalFunctions.median(rawData);
      final stdDev = StatisticalFunctions.standardDeviation(rawData);
      final quartiles = StatisticalFunctions.quartiles(rawData);

      print('   Mean: ${mean.toStringAsFixed(2)}');
      print('   Median: ${median.toStringAsFixed(2)}');
      print('   StdDev: ${stdDev.toStringAsFixed(2)}');
      print('   IQR: ${quartiles.iqr.toStringAsFixed(2)}');

      expect(mean.isFinite, isTrue);
      expect(median.isFinite, isTrue);
      expect(stdDev, greaterThan(0));

      // Step 3: Create data points for curve fitting
      print('3. Creating data points...');
      final points = List.generate(
        100,
        (i) => ChartDataPoint(x: i.toDouble(), y: rawData[i]),
      );

      // Step 4: Fit curve to data
      print('4. Fitting curve to data...');
      final fit = CurveFittingFunctions.linearFit(points);
      print('   Equation: ${fit.equation}');
      print('   R²: ${fit.rSquared.toStringAsFixed(4)}');

      expect(fit.rSquared, greaterThan(0.5)); // Reasonable fit despite noise

      // Step 5: Generate smooth interpolation
      print('5. Generating smooth interpolation...');
      final smoothPoints = points.take(20).toList();
      final interpolated = InterpolationFunctions.cubicSpline(
        smoothPoints,
        100,
      );
      print('   Generated ${interpolated.length} interpolated points');

      expect(interpolated.length, equals(100));
      expect(interpolated.first, closeTo(smoothPoints.first.y, 0.1));

      print('\n✅ All math utilities components working together successfully');
    });

    test('Complex statistical analysis workflow', () {
      print('\n=== Complex Statistical Analysis ===');

      // Generate bimodal distribution (two peaks)
      final data1 = List.generate(500, (i) => 10.0 + (i % 20 - 10).toDouble());
      final data2 = List.generate(500, (i) => 50.0 + (i % 20 - 10).toDouble());
      final bimodal = [...data1, ...data2];

      print('Analyzing bimodal distribution (${bimodal.length} points)...');

      // Calculate all statistics
      final stats = {
        'Mean': StatisticalFunctions.mean(bimodal),
        'Median': StatisticalFunctions.median(bimodal),
        'StdDev': StatisticalFunctions.standardDeviation(bimodal),
        'Range': StatisticalFunctions.range(bimodal),
      };

      final quartiles = StatisticalFunctions.quartiles(bimodal);

      print('Statistics:');
      stats.forEach((key, value) {
        print('  $key: ${value.toStringAsFixed(2)}');
      });
      print('  Q1: ${quartiles.q1.toStringAsFixed(2)}');
      print('  Q2: ${quartiles.q2.toStringAsFixed(2)}');
      print('  Q3: ${quartiles.q3.toStringAsFixed(2)}');
      print('  IQR: ${quartiles.iqr.toStringAsFixed(2)}');

      // Verify statistics are sensible
      expect(stats['Mean']!, greaterThan(20.0));
      expect(stats['Mean']!, lessThan(40.0)); // Between the two modes
      expect(stats['Range']!, greaterThan(40.0));
      expect(quartiles.iqr, greaterThan(20.0));

      print('✅ Complex statistical analysis completed successfully');
    });
  });
}
