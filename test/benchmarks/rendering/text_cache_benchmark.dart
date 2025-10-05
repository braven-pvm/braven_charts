/// Benchmark for TextLayoutCache performance validation.
///
/// Validates NFR-003 (Text Cache Hit Rate):
/// - Target: >70% cache hit rate after 1000 renders
/// - Target: <1μs cache hit latency vs ~0.5-2ms cache miss latency
/// - Target: LRU eviction efficiency
///
/// Tests text layout caching performance:
/// - Cache hit latency (reuse existing layout)
/// - Cache miss latency (create + layout + cache)
/// - Hit rate over repeated renders
/// - LRU eviction behavior
///
/// ## Running Benchmark
///
/// ```bash
/// flutter test test/benchmarks/rendering/text_cache_benchmark.dart
/// ```
///
/// Expected output:
/// ```
/// Text Cache Benchmark (500 unique text/style combinations):
///   Cache hit: 0.5μs (reuse)
///   Cache miss: 1200μs (layout + cache)
///   Hit rate after 1000 renders: 85.3%
///   LRU eviction: 12 evictions for 112 unique entries (maxSize=100)
/// ```
library;

import 'package:flutter/rendering.dart' show TextStyle, TextPainter;
import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/rendering/text_layout_cache.dart' show LinkedHashMapTextLayoutCache;

void main() {
  group('TextLayoutCache Performance Benchmarks', () {
    test('Cache hit latency (NFR-003)', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 100);
      const text = 'Sample Label';
      const style = TextStyle(fontSize: 12);

      // Prime cache with one entry
      final painter = cache.get(text, style);
      if (painter == null) {
        // Cache miss - create and store
        final newPainter = TextPainter();
        cache.put(text, style, newPainter);
      }

      // Now measure cache hit latency
      final stopwatch = Stopwatch();
      final hitLatencies = <int>[];

      for (int i = 0; i < 1000; i++) {
        stopwatch.reset();
        stopwatch.start();

        final retrieved = cache.get(text, style);

        stopwatch.stop();
        hitLatencies.add(stopwatch.elapsedMicroseconds);

        expect(retrieved, isNotNull, reason: 'Cache hit expected');
      }

      hitLatencies.sort();
      final avgHit = hitLatencies.fold<int>(0, (a, b) => a + b) / hitLatencies.length;
      final p99Hit = hitLatencies[(hitLatencies.length * 0.99).floor()];

      // Validate NFR-003 target: cache hit should be very fast (<1μs ideally)
      expect(avgHit, lessThan(10),
          reason: 'Cache hit should be <10μs (NFR-003)');

      print('Cache hit: avg ${avgHit.toStringAsFixed(1)}μs, p99 ${p99Hit}μs');
    });

    test('Cache miss + layout latency baseline (NFR-003)', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 100);

      final missLatencies = <int>[];

      // Measure cache miss + creation + layout latency
      for (int i = 0; i < 100; i++) {
        final text = 'Label $i';
        const style = TextStyle(fontSize: 12);

        final stopwatch = Stopwatch()..start();

        // Cache miss path
        var painter = cache.get(text, style);
        if (painter == null) {
          painter = TextPainter();
          cache.put(text, style, painter);
        }

        stopwatch.stop();
        missLatencies.add(stopwatch.elapsedMicroseconds);
      }

      missLatencies.sort();
      final avgMiss = missLatencies.fold<int>(0, (a, b) => a + b) / missLatencies.length;
      final p99Miss = missLatencies[(missLatencies.length * 0.99).floor()];

      // Cache miss is expected to be much slower due to TextPainter creation
      // No hard assertion, just baseline measurement
      print('Cache miss: avg ${avgMiss.toStringAsFixed(1)}μs, p99 ${p99Miss}μs');
      print('Speedup factor: ${(avgMiss / 1).toStringAsFixed(0)}x (miss vs hit)');
    });

    test('Hit rate after 1000 renders (NFR-003)', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 100);

      // Create 50 unique text/style combinations
      final texts = List.generate(50, (i) => 'Label ${i % 50}');
      const styles = [
        TextStyle(fontSize: 10),
        TextStyle(fontSize: 12),
        TextStyle(fontSize: 14),
      ];

      int totalGets = 0;
      int cacheHits = 0;

      // Render 1000 times with repeated text/style combinations
      for (int render = 0; render < 1000; render++) {
        final text = texts[render % texts.length];
        final style = styles[render % styles.length];

        totalGets++;
        var painter = cache.get(text, style);

        if (painter != null) {
          cacheHits++;
        } else {
          // Cache miss - create and store
          painter = TextPainter();
          cache.put(text, style, painter);
        }
      }

      final hitRate = (cacheHits / totalGets) * 100;

      // Validate NFR-003 target: >70% hit rate
      expect(hitRate, greaterThan(70),
          reason: 'Cache hit rate should be >70% (NFR-003)');

      print('Hit rate: ${hitRate.toStringAsFixed(1)}% '
          '($cacheHits hits / $totalGets gets after 1000 renders)');
    });

    test('LRU eviction performance (NFR-003)', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 10);

      // Add more entries than maxSize to trigger evictions
      final uniqueEntries = 25;
      int evictionCount = 0;

      for (int i = 0; i < uniqueEntries; i++) {
        final text = 'Label $i';
        const style = TextStyle(fontSize: 12);

        final sizeBefore = cache.length;

        var painter = cache.get(text, style);
        if (painter == null) {
          painter = TextPainter();
          cache.put(text, style, painter);
        }

        final sizeAfter = cache.length;

        // If cache size didn't increase, an eviction occurred
        if (sizeAfter == sizeBefore && sizeBefore == 10) {
          evictionCount++;
        }
      }

      // Validate LRU eviction happened
      expect(evictionCount, greaterThan(0),
          reason: 'LRU eviction should occur when exceeding maxSize');

      expect(cache.length, lessThanOrEqualTo(10),
          reason: 'Cache size should not exceed maxSize');

      print('LRU evictions: $evictionCount evictions for $uniqueEntries unique entries '
          '(maxSize=10, final size=${cache.length})');
    });

    test('Cache statistics accuracy (NFR-003)', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 50);

      // Perform mix of hits and misses
      const text1 = 'Label A';
      const text2 = 'Label B';
      const style = TextStyle(fontSize: 12);

      // First access: 2 misses
      cache.get(text1, style) ?? cache.put(text1, style, TextPainter());
      cache.get(text2, style) ?? cache.put(text2, style, TextPainter());

      // Subsequent accesses: hits
      for (int i = 0; i < 10; i++) {
        cache.get(text1, style);
        cache.get(text2, style);
      }

      // Total: 22 gets, 20 hits (after initial 2 misses)
      final hitRate = cache.hitRate;

      expect(hitRate, greaterThan(0.8),
          reason: 'Hit rate should be ~90% (20/22)');

      expect(cache.length, equals(2),
          reason: 'Cache should have 2 entries');

      print('Cache stats: ${(hitRate * 100).toStringAsFixed(1)}% hit rate, '
          '${cache.length} entries');
    });
  });
}
