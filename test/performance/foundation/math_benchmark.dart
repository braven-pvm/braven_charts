// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:braven_charts/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/src/foundation/math/curve_fitting.dart';
import 'package:braven_charts/src/foundation/math/interpolation.dart';
import 'package:braven_charts/src/foundation/math/statistics.dart';

/// Benchmark for StatisticalFunctions performance.
///
/// Target: <10ms for 10k values (FR-005.5)
class StatisticsBenchmark extends BenchmarkBase {
  StatisticsBenchmark() : super('Statistics (10k values)');

  static const int valueCount = 10000;
  late List<double> _values;

  @override
  void setup() {
    _values = List.generate(valueCount, (i) => i.toDouble());
  }

  @override
  void run() {
    StatisticalFunctions.mean(_values);
    StatisticalFunctions.median(_values);
    StatisticalFunctions.standardDeviation(_values);
    StatisticalFunctions.quartiles(_values);
    StatisticalFunctions.minMax(_values);
  }
}

/// Benchmark for InterpolationFunctions performance.
class InterpolationBenchmark extends BenchmarkBase {
  InterpolationBenchmark() : super('Interpolation (cubic spline, 1k samples)');

  late List<ChartDataPoint> _points;

  @override
  void setup() {
    _points = List.generate(
      20,
      (i) => ChartDataPoint(x: i.toDouble(), y: i * i.toDouble()),
    );
  }

  @override
  void run() {
    InterpolationFunctions.cubicSpline(_points, 1000);
  }
}

/// Benchmark for polynomial curve fitting.
///
/// Target: <50ms for polynomial (FR-005.6)
class PolynomialFitBenchmark extends BenchmarkBase {
  PolynomialFitBenchmark() : super('Polynomial Fit (degree 3, 100 points)');

  late List<ChartDataPoint> _points;

  @override
  void setup() {
    _points = List.generate(
      100,
      (i) => ChartDataPoint(x: i.toDouble(), y: i * i * i.toDouble()),
    );
  }

  @override
  void run() {
    CurveFittingFunctions.polynomialFit(_points, degree: 3);
  }
}

/// Benchmark for linear curve fitting.
class LinearFitBenchmark extends BenchmarkBase {
  LinearFitBenchmark() : super('Linear Fit (1000 points)');

  late List<ChartDataPoint> _points;

  @override
  void setup() {
    _points = List.generate(
      1000,
      (i) => ChartDataPoint(x: i.toDouble(), y: 2 * i.toDouble() + 5),
    );
  }

  @override
  void run() {
    CurveFittingFunctions.linearFit(_points);
  }
}

void main() {
  print('=== Math Functions Performance Benchmarks ===\n');

  // Statistics benchmark
  final statsBench = StatisticsBenchmark();
  statsBench.report();

  final statsTimeMs = statsBench.measure();
  print('');
  print('Results:');
  print('  Time:   ${statsTimeMs.toStringAsFixed(2)} ms');
  print('  Target: <10.00 ms');
  print('  Status: ${statsTimeMs < 10.0 ? "✅ PASS" : "❌ FAIL"}');
  print('');

  // Interpolation benchmark
  final interpBench = InterpolationBenchmark();
  interpBench.report();

  final interpTimeMs = interpBench.measure();
  print('');
  print('Results:');
  print('  Time:   ${interpTimeMs.toStringAsFixed(2)} ms');
  print('  Target: <10.00 ms (1000 samples)');
  print('  Status: ${interpTimeMs < 10.0 ? "✅ PASS" : "❌ FAIL"}');
  print('');

  // Linear fit benchmark
  final linearBench = LinearFitBenchmark();
  linearBench.report();

  final linearTimeMs = linearBench.measure();
  print('');
  print('Results:');
  print('  Time:   ${linearTimeMs.toStringAsFixed(2)} ms');
  print('  Target: <5.00 ms');
  print('  Status: ${linearTimeMs < 5.0 ? "✅ PASS" : "❌ FAIL"}');
  print('');

  // Polynomial fit benchmark
  final polyBench = PolynomialFitBenchmark();
  polyBench.report();

  final polyTimeMs = polyBench.measure();
  print('');
  print('Results:');
  print('  Time:   ${polyTimeMs.toStringAsFixed(2)} ms');
  print('  Target: <50.00 ms');
  print('  Status: ${polyTimeMs < 50.0 ? "✅ PASS" : "❌ FAIL"}');
  print('');

  // Summary
  print('=== Summary ===');
  final allPass = statsTimeMs < 10.0 &&
      interpTimeMs < 10.0 &&
      linearTimeMs < 5.0 &&
      polyTimeMs < 50.0;
  print('Overall: ${allPass ? "✅ ALL TARGETS MET" : "❌ SOME TARGETS FAILED"}');
}
