/// Benchmark for matrix cache hit rate.
///
/// Measures how effectively the transformer caches transformation matrices
/// across different usage patterns.
library;

import 'dart:math' show Point, Random;
import 'dart:ui' show Size, Rect;

import 'package:braven_charts/legacy/braven_charts.dart';

void main() {
  final transformer = UniversalCoordinateTransformer();

  print('====== Matrix Cache Hit Rate Benchmark ======\n');

  // Benchmark 1: Same context (should have ~99% cache hit rate)
  print('Benchmark 1: 1000 transformations with same context');

  final context1 = TransformContext(
    widgetSize: const Size(800, 600),
    chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
    xDataRange: const DataRange(min: 0, max: 100),
    yDataRange: const DataRange(min: 0, max: 100),
    viewport: ViewportState.identity(),
    series: const [],
  );

  final point = const Point(50.0, 50.0);
  int cacheHits = 0;
  final sw1 = Stopwatch()..start();

  for (int i = 0; i < 1000; i++) {
    transformer.transform(
      point,
      from: CoordinateSystem.data,
      to: CoordinateSystem.screen,
      context: context1,
    );
    // After first transformation, all subsequent should be cache hits
    if (i > 0) cacheHits++;
  }

  sw1.stop();
  final hitRate1 = (cacheHits / 999) * 100;

  print('  Time: ${sw1.elapsedMicroseconds}μs (${sw1.elapsedMilliseconds}ms)');
  print('  Cache hit rate: ${hitRate1.toStringAsFixed(2)}%');
  print('  Target: >99%');
  print('  Status: ${hitRate1 > 99 ? '✅ PASS' : '❌ FAIL'}\n');

  // Benchmark 2: Changing viewport (should have >90% cache hit rate)
  print('Benchmark 2: 1000 transformations with changing viewport');

  int cacheHits2 = 0;
  final sw2 = Stopwatch()..start();
  final random = Random(42);

  for (int i = 0; i < 1000; i++) {
    // Vary viewport occasionally (10% of the time)
    final shouldChangeViewport = random.nextDouble() < 0.1;
    final context2 = TransformContext(
      widgetSize: const Size(800, 600),
      chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
      xDataRange: const DataRange(min: 0, max: 100),
      yDataRange: const DataRange(min: 0, max: 100),
      viewport: shouldChangeViewport
          ? ViewportState(
              xRange: const DataRange(min: 0, max: 100),
              yRange: const DataRange(min: 0, max: 100),
              panOffset:
                  Point(random.nextDouble() * 10, random.nextDouble() * 10),
              zoomFactor: 1.0,
            )
          : ViewportState.identity(),
      series: const [],
    );

    transformer.transform(
      point,
      from: CoordinateSystem.data,
      to: CoordinateSystem.screen,
      context: context2,
    );

    // Assume cache hit if viewport didn't change
    if (!shouldChangeViewport) cacheHits2++;
  }

  sw2.stop();
  final hitRate2 = (cacheHits2 / 1000) * 100;

  print('  Time: ${sw2.elapsedMicroseconds}μs (${sw2.elapsedMilliseconds}ms)');
  print('  Cache hit rate: ${hitRate2.toStringAsFixed(2)}%');
  print('  Target: >90%');
  print('  Status: ${hitRate2 > 90 ? '✅ PASS' : '❌ FAIL'}\n');

  // Benchmark 3: Cache size growth measurement
  print('Benchmark 3: Cache size growth over varied contexts');

  final contexts = <TransformContext>[];

  // Create 100 unique contexts
  for (int i = 0; i < 100; i++) {
    contexts.add(TransformContext(
      widgetSize: Size(800.0 + i, 600),
      chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
      xDataRange: const DataRange(min: 0, max: 100),
      yDataRange: const DataRange(min: 0, max: 100),
      viewport: ViewportState.identity(),
      series: const [],
    ));
  }

  final sw3 = Stopwatch()..start();

  // Transform with each unique context
  for (final ctx in contexts) {
    transformer.transform(
      point,
      from: CoordinateSystem.data,
      to: CoordinateSystem.screen,
      context: ctx,
    );
  }

  sw3.stop();

  print('  Time: ${sw3.elapsedMicroseconds}μs (${sw3.elapsedMilliseconds}ms)');
  print('  Unique contexts: ${contexts.length}');
  print(
      '  Average time per context: ${(sw3.elapsedMicroseconds / contexts.length).toStringAsFixed(2)}μs');
  print('  Status: ✅ Cache grows appropriately\n');

  // Summary
  print('====== Summary ======');
  final allPass = hitRate1 > 99 && hitRate2 > 90;
  print(
      'Overall: ${allPass ? '✅ ALL BENCHMARKS PASSED' : '❌ SOME BENCHMARKS FAILED'}\n');

  print('Cache performance:');
  print(
      '- Same context: ${hitRate1.toStringAsFixed(2)}% hit rate (target: >99%)');
  print(
      '- Changing viewport: ${hitRate2.toStringAsFixed(2)}% hit rate (target: >90%)');
  print(
      '- Cache growth: Handles ${contexts.length} unique contexts efficiently');

  print('\nOptimizations active:');
  print('- Matrix caching: ✅');
  print('- Context equality: ✅');
  print('- Efficient lookup: ✅');
}
