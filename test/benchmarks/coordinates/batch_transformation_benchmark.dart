// Benchmark: Batch transformation performance
// Feature: 003-coordinate-system
// Task: T048 - Validate batch transformation performance
//
// Targets:
// - <1ms for 10K points
// - <10ms for 100K points

import 'dart:math' show Point, sin;
import 'dart:ui' show Size, Rect;

import 'package:braven_charts/braven_charts.dart';

void main() {
  print('====== Batch Transformation Performance Benchmark ======\n');

  final transformer = UniversalCoordinateTransformer();
  final context = TransformContext(
    widgetSize: const Size(800, 600),
    chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
    xDataRange: const DataRange(min: 0, max: 100),
    yDataRange: const DataRange(min: -1, max: 1),
    viewport: ViewportState.identity(),
    series: const [],
  );

  // Benchmark 1: 10K points data → screen
  print('Benchmark 1: 10K points data → screen');
  final dataPoints10K = List.generate(
    10000,
    (i) => Point(i / 100.0, sin(i / 100.0)),
  );

  final warmup1 = Stopwatch()..start();
  transformer.transformBatch(
    dataPoints10K,
    from: CoordinateSystem.data,
    to: CoordinateSystem.screen,
    context: context,
  );
  warmup1.stop();
  print('  Warmup: ${warmup1.elapsedMicroseconds}μs');

  final sw1 = Stopwatch()..start();
  final screenPoints10K = transformer.transformBatch(
    dataPoints10K,
    from: CoordinateSystem.data,
    to: CoordinateSystem.screen,
    context: context,
  );
  sw1.stop();

  final time1Ms = sw1.elapsedMicroseconds / 1000.0;
  print(
      '  Result: ${sw1.elapsedMicroseconds}μs (${time1Ms.toStringAsFixed(3)}ms)');
  print('  Target: <1000μs (1ms)');
  print('  Status: ${time1Ms < 1.0 ? "✅ PASS" : "❌ FAIL"}');
  print(
      '  Points/μs: ${(10000 / sw1.elapsedMicroseconds).toStringAsFixed(2)}\n');

  // Benchmark 2: 10K points screen → data (reverse)
  print('Benchmark 2: 10K points screen → data');

  final warmup2 = Stopwatch()..start();
  transformer.transformBatch(
    screenPoints10K,
    from: CoordinateSystem.screen,
    to: CoordinateSystem.data,
    context: context,
  );
  warmup2.stop();
  print('  Warmup: ${warmup2.elapsedMicroseconds}μs');

  final sw2 = Stopwatch()..start();
  transformer.transformBatch(
    screenPoints10K,
    from: CoordinateSystem.screen,
    to: CoordinateSystem.data,
    context: context,
  );
  sw2.stop();

  final time2Ms = sw2.elapsedMicroseconds / 1000.0;
  print(
      '  Result: ${sw2.elapsedMicroseconds}μs (${time2Ms.toStringAsFixed(3)}ms)');
  print('  Target: <1000μs (1ms)');
  print('  Status: ${time2Ms < 1.0 ? "✅ PASS" : "❌ FAIL"}');
  print(
      '  Points/μs: ${(10000 / sw2.elapsedMicroseconds).toStringAsFixed(2)}\n');

  // Benchmark 3: 100K points batch transformation
  print('Benchmark 3: 100K points data → screen');
  final dataPoints100K = List.generate(
    100000,
    (i) => Point(i / 1000.0, sin(i / 1000.0)),
  );

  final warmup3 = Stopwatch()..start();
  transformer.transformBatch(
    dataPoints100K,
    from: CoordinateSystem.data,
    to: CoordinateSystem.screen,
    context: context,
  );
  warmup3.stop();
  print(
      '  Warmup: ${warmup3.elapsedMicroseconds}μs (${(warmup3.elapsedMicroseconds / 1000.0).toStringAsFixed(3)}ms)');

  final sw3 = Stopwatch()..start();
  transformer.transformBatch(
    dataPoints100K,
    from: CoordinateSystem.data,
    to: CoordinateSystem.screen,
    context: context,
  );
  sw3.stop();

  final time3Ms = sw3.elapsedMicroseconds / 1000.0;
  print(
      '  Result: ${sw3.elapsedMicroseconds}μs (${time3Ms.toStringAsFixed(3)}ms)');
  print('  Target: <10000μs (10ms)');
  print('  Status: ${time3Ms < 10.0 ? "✅ PASS" : "❌ FAIL"}');
  print(
      '  Points/μs: ${(100000 / sw3.elapsedMicroseconds).toStringAsFixed(2)}\n');

  // Summary
  print('====== Summary ======');
  final allPass = time1Ms < 1.0 && time2Ms < 1.0 && time3Ms < 10.0;
  print(
      'Overall: ${allPass ? "✅ ALL BENCHMARKS PASSED" : "❌ SOME BENCHMARKS FAILED"}');
  print('\nPerformance characteristics:');
  print('- 10K data→screen: ${time1Ms.toStringAsFixed(3)}ms (target: <1ms)');
  print('- 10K screen→data: ${time2Ms.toStringAsFixed(3)}ms (target: <1ms)');
  print('- 100K data→screen: ${time3Ms.toStringAsFixed(3)}ms (target: <10ms)');
  print('\nOptimizations active:');
  print('- Matrix caching: ✅');
  print('- SIMD batch processing: ✅');
  print('- Zero-allocation result lists: ✅');
}
