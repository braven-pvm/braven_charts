/// Benchmarks for style cache performance.
///
/// Measures cache hit rate and lookup time.
/// Targets:
/// - Cache hit rate: >95% (FR-008)
/// - Lookup time: <0.1ms (FR-008)
library;

import 'package:braven_charts/legacy/src/theming/utilities/style_cache.dart';

void main() {
  print('=== Style Cache Benchmark ===\n');

  print('Benchmark 1: Cache hit performance (realistic rendering pattern)');
  _benchmarkHitPerformance();
  print('');

  print('Benchmark 2: Cache miss performance (first access)');
  _benchmarkMissPerformance();
  print('');

  print('Benchmark 3: Cache hit rate (realistic rendering)');
  _benchmarkHitRate();
  print('');

  print('Benchmark 4: LRU eviction performance');
  _benchmarkEviction();
  print('');

  print('Benchmark 5: Concurrent access patterns');
  _benchmarkConcurrentAccess();
  print('');

  print('=== Performance Summary ===');
  print('Target hit rate: >95%');
  print('Target lookup time: <0.1ms');
  print(_allBenchmarksPassed
      ? 'All benchmarks PASSED'
      : 'Some benchmarks FAILED');
}

bool _allBenchmarksPassed = true;

void _benchmarkHitPerformance() {
  final cache = StyleCache();
  const themeHash = 12345;

  // Warm up cache with common styles
  const elementTypes = ['axis', 'grid', 'series', 'legend', 'tooltip'];
  for (final type in elementTypes) {
    cache.put(
      StyleCacheKey(themeHash: themeHash, elementType: type),
      'cached-$type',
    );
  }

  const iterations = 100000;
  final sw = Stopwatch()..start();

  for (var i = 0; i < iterations; i++) {
    cache.get(StyleCacheKey(
      themeHash: themeHash,
      elementType: elementTypes[i % elementTypes.length],
    ));
  }

  sw.stop();
  final avgUs = sw.elapsedMicroseconds / iterations;
  final avgMs = avgUs / 1000;

  print('  Iterations: $iterations (all cache hits)');
  print('  Total time: ${sw.elapsedMilliseconds}ms');
  print(
      '  Average: ${avgUs.toStringAsFixed(3)}μs (${avgMs.toStringAsFixed(4)}ms)');
  print('  Status: ${avgMs < 0.1 ? "PASS" : "FAIL"}');

  if (avgMs >= 0.1) _allBenchmarksPassed = false;
}

void _benchmarkMissPerformance() {
  final cache = StyleCache();
  const themeHash = 12345;

  const iterations = 100000;
  final sw = Stopwatch()..start();

  for (var i = 0; i < iterations; i++) {
    cache.get(StyleCacheKey(
      themeHash: themeHash,
      elementType: 'element-$i', // All misses
    ));
  }

  sw.stop();
  final avgUs = sw.elapsedMicroseconds / iterations;
  final avgMs = avgUs / 1000;

  print('  Iterations: $iterations (all cache misses)');
  print('  Total time: ${sw.elapsedMilliseconds}ms');
  print(
      '  Average: ${avgUs.toStringAsFixed(3)}μs (${avgMs.toStringAsFixed(4)}ms)');
  print('  Status: ${avgMs < 0.1 ? "PASS" : "FAIL"}');

  if (avgMs >= 0.1) _allBenchmarksPassed = false;
}

void _benchmarkHitRate() {
  final cache = StyleCache();
  const themeHash = 12345;

  // Simulate realistic rendering pattern:
  // - 10 unique style types
  // - Multiple frames re-using same styles
  const styleTypes = [
    'axis',
    'grid',
    'series',
    'legend',
    'tooltip',
    'crosshair',
    'marker',
    'label',
    'title',
    'background'
  ];

  // First pass: populate cache (all misses)
  for (final type in styleTypes) {
    cache.put(
      StyleCacheKey(themeHash: themeHash, elementType: type),
      'cached-$type',
    );
  }

  // Subsequent passes: simulate 100 frames of rendering
  const framesPerType = 100; // Each style accessed 100 times
  var hits = 0;
  var total = 0;

  final sw = Stopwatch()..start();

  for (var frame = 0; frame < framesPerType; frame++) {
    for (final type in styleTypes) {
      final result = cache.get(
        StyleCacheKey(themeHash: themeHash, elementType: type),
      );
      total++;
      if (result != null) hits++;
    }
  }

  sw.stop();

  final hitRate = (hits / total) * 100;
  final avgLookupUs = sw.elapsedMicroseconds / total;

  print('  Total lookups: $total');
  print('  Hits: $hits');
  print('  Misses: ${total - hits}');
  print('  Hit rate: ${hitRate.toStringAsFixed(2)}%');
  print('  Average lookup: ${avgLookupUs.toStringAsFixed(3)}μs');
  print('  Status: ${hitRate > 95 ? "PASS" : "FAIL"}');

  if (hitRate <= 95) _allBenchmarksPassed = false;
}

void _benchmarkEviction() {
  final cache = StyleCache();

  // Fill cache to capacity
  for (var i = 0; i < StyleCache.maxSize; i++) {
    cache.put(
      StyleCacheKey(themeHash: i, elementType: 'style'),
      'value-$i',
    );
  }

  const iterations = 10000;
  final sw = Stopwatch()..start();

  // Trigger evictions by adding more items
  for (var i = StyleCache.maxSize; i < StyleCache.maxSize + iterations; i++) {
    cache.put(
      StyleCacheKey(themeHash: i, elementType: 'style'),
      'value-$i',
    );
  }

  sw.stop();
  final avgUs = sw.elapsedMicroseconds / iterations;
  final avgMs = avgUs / 1000;

  print('  Iterations: $iterations (with LRU eviction)');
  print('  Cache size: ${cache.size}/${StyleCache.maxSize}');
  print('  Total time: ${sw.elapsedMilliseconds}ms');
  print(
      '  Average put time: ${avgUs.toStringAsFixed(3)}μs (${avgMs.toStringAsFixed(4)}ms)');
  print('  Status: ${avgMs < 0.1 ? "PASS" : "FAIL"}');

  if (avgMs >= 0.1) _allBenchmarksPassed = false;
}

void _benchmarkConcurrentAccess() {
  final cache = StyleCache();
  const themeHash = 12345;

  // Simulate rendering multiple chart elements concurrently
  const elementTypes = [
    'axis',
    'grid',
    'series',
    'legend',
    'tooltip',
    'crosshair',
    'marker',
    'label',
    'title',
    'background'
  ];

  // Populate cache
  for (final type in elementTypes) {
    cache.put(
      StyleCacheKey(themeHash: themeHash, elementType: type),
      'cached-$type',
    );
  }

  const iterations = 50000;
  final sw = Stopwatch()..start();

  // Interleaved read/write pattern (more realistic)
  for (var i = 0; i < iterations; i++) {
    final type = elementTypes[i % elementTypes.length];

    // 80% reads, 20% writes
    if (i % 5 == 0) {
      cache.put(
        StyleCacheKey(themeHash: themeHash + (i ~/ 100), elementType: type),
        'updated-$type-$i',
      );
    } else {
      cache.get(
        StyleCacheKey(themeHash: themeHash, elementType: type),
      );
    }
  }

  sw.stop();
  final avgUs = sw.elapsedMicroseconds / iterations;
  final avgMs = avgUs / 1000;

  print('  Iterations: $iterations (80% read, 20% write)');
  print('  Cache size: ${cache.size}');
  print('  Total time: ${sw.elapsedMilliseconds}ms');
  print(
      '  Average operation time: ${avgUs.toStringAsFixed(3)}μs (${avgMs.toStringAsFixed(4)}ms)');
  print('  Status: ${avgMs < 0.1 ? "PASS" : "FAIL"}');

  if (avgMs >= 0.1) _allBenchmarksPassed = false;
}
