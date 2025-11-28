// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:braven_charts/legacy/src/foundation/data_models/chart_data_point.dart';

/// Benchmark for ChartDataPoint creation performance.
///
/// Target: <1μs per point (FR-005.1)
/// Test: Create 100k points and measure average time per point
class ChartDataPointCreationBenchmark extends BenchmarkBase {
  ChartDataPointCreationBenchmark() : super('ChartDataPoint Creation');

  static const int iterations = 100000;
  final List<ChartDataPoint> _points = [];

  @override
  void run() {
    for (int i = 0; i < iterations; i++) {
      _points.add(ChartDataPoint(x: i.toDouble(), y: i * 2.0));
    }
  }

  @override
  void teardown() {
    _points.clear();
    super.teardown();
  }
}

/// Benchmark for ChartDataPoint copyWith performance.
class ChartDataPointCopyWithBenchmark extends BenchmarkBase {
  ChartDataPointCopyWithBenchmark() : super('ChartDataPoint copyWith');

  static const int iterations = 100000;
  late ChartDataPoint _point;

  @override
  void setup() {
    _point = const ChartDataPoint(x: 1.0, y: 2.0);
  }

  @override
  void run() {
    ChartDataPoint result;
    for (int i = 0; i < iterations; i++) {
      result = _point.copyWith(y: i.toDouble());
      // Use result to prevent optimization
      if (result.y < 0) throw StateError('unexpected');
    }
  }
}

void main() {
  print('=== ChartDataPoint Performance Benchmarks ===\n');

  // Run creation benchmark
  final creationBench = ChartDataPointCreationBenchmark();
  creationBench.report();

  // Calculate microseconds per point
  final creationTimeMs = creationBench.measure();
  final usPerPoint =
      (creationTimeMs * 1000) / ChartDataPointCreationBenchmark.iterations;

  print('');
  print('Results:');
  print('  Creation: ${usPerPoint.toStringAsFixed(3)} μs/point');
  print('  Target:   <1.000 μs/point');
  print('  Status:   ${usPerPoint < 1.0 ? "✅ PASS" : "❌ FAIL"}');
  print('');

  // Run copyWith benchmark
  final copyWithBench = ChartDataPointCopyWithBenchmark();
  copyWithBench.report();

  final copyWithTimeMs = copyWithBench.measure();
  final usCopyWith =
      (copyWithTimeMs * 1000) / ChartDataPointCopyWithBenchmark.iterations;

  print('');
  print('Results:');
  print('  copyWith: ${usCopyWith.toStringAsFixed(3)} μs/operation');
  print('  Target:   <1.000 μs/operation');
  print('  Status:   ${usCopyWith < 1.0 ? "✅ PASS" : "❌ FAIL"}');
  print('');

  // Summary
  print('=== Summary ===');
  final allPass = usPerPoint < 1.0 && usCopyWith < 1.0;
  print('Overall: ${allPass ? "✅ ALL TARGETS MET" : "❌ SOME TARGETS FAILED"}');
}
