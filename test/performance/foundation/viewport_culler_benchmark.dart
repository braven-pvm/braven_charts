// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:braven_charts/legacy/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/legacy/src/foundation/data_models/data_range.dart';
import 'package:braven_charts/legacy/src/foundation/performance/viewport_culler.dart';

/// Benchmark for ViewportCuller with ordered data.
///
/// Target: <1ms for 10k points (FR-005.4)
/// Test: Cull 10k ordered points multiple times
class ViewportCullerOrderedBenchmark extends BenchmarkBase {
  ViewportCullerOrderedBenchmark() : super('ViewportCuller Ordered Data');

  static const int iterations = 100;
  static const int pointCount = 10000;
  late List<ChartDataPoint> _points;
  late ViewportCuller _culler;
  late DataRange _viewportX;
  late DataRange _viewportY;

  @override
  void setup() {
    // Create ordered points 0..9999
    _points = List.generate(
      pointCount,
      (i) => ChartDataPoint(x: i.toDouble(), y: i * 2.0),
    );
    _culler = const ViewportCuller();
    // Viewport: middle 20% (4000-6000)
    _viewportX = const DataRange(min: 4000, max: 6000);
    _viewportY = const DataRange(min: 0, max: 20000);
  }

  @override
  void run() {
    for (int i = 0; i < iterations; i++) {
      final result = _culler.cull(
        points: _points,
        viewportX: _viewportX,
        viewportY: _viewportY,
        isXOrdered: true,
      );
      // Prevent optimization
      if (result.isEmpty) throw StateError('unexpected');
    }
  }
}

/// Benchmark for ViewportCuller with unordered data.
class ViewportCullerUnorderedBenchmark extends BenchmarkBase {
  ViewportCullerUnorderedBenchmark() : super('ViewportCuller Unordered Data');

  static const int iterations = 100;
  static const int pointCount = 10000;
  late List<ChartDataPoint> _points;
  late ViewportCuller _culler;
  late DataRange _viewportX;
  late DataRange _viewportY;

  @override
  void setup() {
    // Create shuffled points
    final ordered = List.generate(
      pointCount,
      (i) => ChartDataPoint(x: i.toDouble(), y: i * 2.0),
    );
    _points = List.from(ordered)..shuffle();
    _culler = const ViewportCuller();
    _viewportX = const DataRange(min: 4000, max: 6000);
    _viewportY = const DataRange(min: 0, max: 20000);
  }

  @override
  void run() {
    for (int i = 0; i < iterations; i++) {
      final result = _culler.cull(
        points: _points,
        viewportX: _viewportX,
        viewportY: _viewportY,
        isXOrdered: false,
      );
      if (result.isEmpty) throw StateError('unexpected');
    }
  }
}

/// Benchmark for ViewportCuller with small viewport (stress test).
class ViewportCullerSmallViewportBenchmark extends BenchmarkBase {
  ViewportCullerSmallViewportBenchmark()
      : super('ViewportCuller Small Viewport');

  static const int iterations = 100;
  static const int pointCount = 10000;
  late List<ChartDataPoint> _points;
  late ViewportCuller _culler;
  late DataRange _viewportX;
  late DataRange _viewportY;

  @override
  void setup() {
    _points = List.generate(
      pointCount,
      (i) => ChartDataPoint(x: i.toDouble(), y: i * 2.0),
    );
    _culler = const ViewportCuller();
    // Very small viewport: only 1% of data (4950-5050)
    _viewportX = const DataRange(min: 4950, max: 5050);
    _viewportY = const DataRange(min: 0, max: 20000);
  }

  @override
  void run() {
    for (int i = 0; i < iterations; i++) {
      _culler.cull(
        points: _points,
        viewportX: _viewportX,
        viewportY: _viewportY,
        isXOrdered: true,
      );
    }
  }
}

void main() {
  print('=== ViewportCuller Performance Benchmarks ===\n');

  // Ordered data benchmark
  final orderedBench = ViewportCullerOrderedBenchmark();
  orderedBench.report();

  final orderedTimeMs = orderedBench.measure();
  final msPerCull = orderedTimeMs / ViewportCullerOrderedBenchmark.iterations;

  print('');
  print('Results (10k ordered points):');
  print('  Time:   ${msPerCull.toStringAsFixed(3)} ms/cull');
  print('  Target: <1.000 ms/cull');
  print('  Status: ${msPerCull < 1.0 ? "✅ PASS" : "❌ FAIL"}');
  print('');

  // Unordered data benchmark
  final unorderedBench = ViewportCullerUnorderedBenchmark();
  unorderedBench.report();

  final unorderedTimeMs = unorderedBench.measure();
  final msPerCullUnordered =
      unorderedTimeMs / ViewportCullerUnorderedBenchmark.iterations;

  print('');
  print('Results (10k unordered points):');
  print('  Time:   ${msPerCullUnordered.toStringAsFixed(3)} ms/cull');
  print('  Target: <1.000 ms/cull');
  print('  Status: ${msPerCullUnordered < 1.0 ? "✅ PASS" : "❌ FAIL"}');
  print('');

  // Small viewport benchmark
  final smallBench = ViewportCullerSmallViewportBenchmark();
  smallBench.report();

  final smallTimeMs = smallBench.measure();
  final msPerCullSmall =
      smallTimeMs / ViewportCullerSmallViewportBenchmark.iterations;

  print('');
  print('Results (10k points, 1% viewport):');
  print('  Time:   ${msPerCullSmall.toStringAsFixed(3)} ms/cull');
  print('  Target: <1.000 ms/cull');
  print('  Status: ${msPerCullSmall < 1.0 ? "✅ PASS" : "❌ FAIL"}');
  print('');

  // Summary
  print('=== Summary ===');
  final allPass =
      msPerCull < 1.0 && msPerCullUnordered < 1.0 && msPerCullSmall < 1.0;
  print('Overall: ${allPass ? "✅ ALL TARGETS MET" : "❌ SOME TARGETS FAILED"}');
  print('');
  print('Analysis:');
  print(
      '  Ordered speedup: ${(msPerCullUnordered / msPerCull).toStringAsFixed(2)}x faster than unordered');
  print(
      '  Algorithm:       ${msPerCull < msPerCullUnordered ? "Binary search optimization active" : "Linear scan"}');
}
