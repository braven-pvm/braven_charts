// Contract Test: TextLayoutCache Interface
// Feature: 002-core-rendering
// Purpose: Verify TextLayoutCache contract compliance
//
// TDD Phase: RED - These tests MUST fail before implementation exists
//
// Expected initial state: COMPILATION ERROR
// - TextLayoutCache not fully implemented yet (will be created in T011)
// - This is intentional per TDD workflow

import 'package:braven_charts/src/rendering/text_layout_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextLayoutCache Contract Tests', () {
    late TextLayoutCache cache;
    late TextStyle testStyle1;
    late TextStyle testStyle2;

    setUp(() {
      // Will fail until T011 implements LinkedHashMapTextLayoutCache
      cache = LinkedHashMapTextLayoutCache(maxSize: 5);

      testStyle1 = const TextStyle(fontSize: 14, color: Colors.black);
      testStyle2 = const TextStyle(fontSize: 16, color: Colors.blue);
    });

    group('Contract Requirement 1: Cache Key Uniqueness', () {
      test('same text with different styles have different keys', () {
        final painter1 = TextPainter(
          text: TextSpan(text: 'Label', style: testStyle1),
          textDirection: TextDirection.ltr,
        )..layout();

        final painter2 = TextPainter(
          text: TextSpan(text: 'Label', style: testStyle2),
          textDirection: TextDirection.ltr,
        )..layout();

        cache.put('Label', testStyle1, painter1);
        cache.put('Label', testStyle2, painter2);

        final retrieved1 = cache.get('Label', testStyle1);
        final retrieved2 = cache.get('Label', testStyle2);

        expect(retrieved1, same(painter1), reason: 'Should retrieve painter for style1');
        expect(retrieved2, same(painter2), reason: 'Should retrieve painter for style2');
        expect(retrieved1, isNot(same(retrieved2)), reason: 'Different styles should have different cache entries');
      });

      test('different text with same style have different keys', () {
        final painter1 = TextPainter(
          text: TextSpan(text: 'Label1', style: testStyle1),
          textDirection: TextDirection.ltr,
        )..layout();

        final painter2 = TextPainter(
          text: TextSpan(text: 'Label2', style: testStyle1),
          textDirection: TextDirection.ltr,
        )..layout();

        cache.put('Label1', testStyle1, painter1);
        cache.put('Label2', testStyle1, painter2);

        final retrieved1 = cache.get('Label1', testStyle1);
        final retrieved2 = cache.get('Label2', testStyle1);

        expect(retrieved1, same(painter1));
        expect(retrieved2, same(painter2));
        expect(retrieved1, isNot(same(retrieved2)));
      });
    });

    group('Contract Requirement 2: Hit Performance', () {
      test('cache hits complete in <0.5ms', () {
        final painter = TextPainter(
          text: TextSpan(text: 'Test', style: testStyle1),
          textDirection: TextDirection.ltr,
        )..layout();

        cache.put('Test', testStyle1, painter);

        final stopwatch = Stopwatch()..start();

        // Perform 100 cache hits
        for (int i = 0; i < 100; i++) {
          final _ = cache.get('Test', testStyle1);
        }

        stopwatch.stop();

        final avgHitMicros = stopwatch.elapsedMicroseconds / 100;

        expect(avgHitMicros, lessThan(500), reason: 'Cache hit must be <500 microseconds (0.5ms)');
      });
    });

    group('Contract Requirement 3: Miss Performance', () {
      test('cache misses return null in <0.5ms', () {
        final stopwatch = Stopwatch()..start();

        // Perform 100 cache misses
        for (int i = 0; i < 100; i++) {
          final result = cache.get('NonExistent$i', testStyle1);
          expect(result, isNull);
        }

        stopwatch.stop();

        final avgMissMicros = stopwatch.elapsedMicroseconds / 100;

        expect(avgMissMicros, lessThan(500), reason: 'Cache miss must be <500 microseconds (0.5ms)');
      });

      test('get() returns null for non-existent key', () {
        final result = cache.get('NonExistent', testStyle1);

        expect(result, isNull, reason: 'Cache miss should return null');
      });
    });

    group('Contract Requirement 4: Bounded Size', () {
      test('cache enforces maxSize limit', () {
        final smallCache = LinkedHashMapTextLayoutCache(maxSize: 3);

        // Add 10 entries (exceeds maxSize of 3)
        for (int i = 0; i < 10; i++) {
          final painter = TextPainter(
            text: TextSpan(text: 'Label$i', style: testStyle1),
            textDirection: TextDirection.ltr,
          )..layout();

          smallCache.put('Label$i', testStyle1, painter);
        }

        // Cache length should not exceed maxSize
        expect(smallCache.length, lessThanOrEqualTo(3), reason: 'Cache must respect maxSize boundary');
      });

      test('default maxSize is 500', () {
        final defaultCache = LinkedHashMapTextLayoutCache();

        expect(defaultCache.maxSize, equals(500), reason: 'Default maxSize should be 500 per contract');
      });
    });

    group('Contract Requirement 5: LRU Eviction', () {
      test('oldest entry evicted when cache at capacity', () {
        final smallCache = LinkedHashMapTextLayoutCache(maxSize: 3);

        final painter1 = TextPainter(
          text: TextSpan(text: 'First', style: testStyle1),
          textDirection: TextDirection.ltr,
        )..layout();

        final painter2 = TextPainter(
          text: TextSpan(text: 'Second', style: testStyle1),
          textDirection: TextDirection.ltr,
        )..layout();

        final painter3 = TextPainter(
          text: TextSpan(text: 'Third', style: testStyle1),
          textDirection: TextDirection.ltr,
        )..layout();

        final painter4 = TextPainter(
          text: TextSpan(text: 'Fourth', style: testStyle1),
          textDirection: TextDirection.ltr,
        )..layout();

        // Fill cache to capacity
        smallCache.put('First', testStyle1, painter1);
        smallCache.put('Second', testStyle1, painter2);
        smallCache.put('Third', testStyle1, painter3);

        expect(smallCache.length, equals(3));

        // Add fourth entry (should evict 'First')
        smallCache.put('Fourth', testStyle1, painter4);

        expect(smallCache.length, equals(3), reason: 'Cache should still be at maxSize');

        expect(smallCache.get('First', testStyle1), isNull, reason: 'Oldest entry (First) should be evicted');

        expect(smallCache.get('Second', testStyle1), isNotNull, reason: 'Second entry should still exist');
        expect(smallCache.get('Third', testStyle1), isNotNull, reason: 'Third entry should still exist');
        expect(smallCache.get('Fourth', testStyle1), isNotNull, reason: 'Fourth entry should exist');
      });

      test('put() on existing key does not create duplicate', () {
        final painter1 = TextPainter(
          text: TextSpan(text: 'Label', style: testStyle1),
          textDirection: TextDirection.ltr,
        )..layout();

        final painter2 = TextPainter(
          text: TextSpan(text: 'Label', style: testStyle1),
          textDirection: TextDirection.ltr,
        )..layout();

        cache.put('Label', testStyle1, painter1);
        final initialLength = cache.length;

        cache.put('Label', testStyle1, painter2);

        expect(cache.length, equals(initialLength), reason: 'Overwriting existing key should not increase length');

        final retrieved = cache.get('Label', testStyle1);
        expect(retrieved, same(painter2), reason: 'Should retrieve most recently put painter');
      });
    });

    group('Contract Requirement 6: Hit Rate Tracking', () {
      test('hitRate calculation is correct', () {
        cache.clear(); // Start with clean state

        final painter = TextPainter(
          text: TextSpan(text: 'Test', style: testStyle1),
          textDirection: TextDirection.ltr,
        )..layout();

        cache.put('Test', testStyle1, painter);

        // Execute 7 hits, 3 misses
        for (int i = 0; i < 7; i++) {
          cache.get('Test', testStyle1); // Hit
        }

        for (int i = 0; i < 3; i++) {
          cache.get('NonExistent$i', testStyle1); // Miss
        }

        final hitRate = cache.hitRate;

        expect(hitRate, closeTo(0.7, 0.01), reason: '7 hits / 10 lookups = 0.7 hit rate');
      });

      test('hitRate handles division by zero (no lookups yet)', () {
        final freshCache = LinkedHashMapTextLayoutCache();

        expect(freshCache.hitRate, equals(0.0), reason: 'Hit rate should be 0.0 when no lookups performed');
      });

      test('hitRate is in range [0.0, 1.0]', () {
        final painter = TextPainter(
          text: TextSpan(text: 'Test', style: testStyle1),
          textDirection: TextDirection.ltr,
        )..layout();

        cache.put('Test', testStyle1, painter);

        // Some hits and misses
        cache.get('Test', testStyle1);
        cache.get('NonExistent', testStyle1);

        final hitRate = cache.hitRate;

        expect(hitRate, greaterThanOrEqualTo(0.0));
        expect(hitRate, lessThanOrEqualTo(1.0));
      });
    });

    group('Contract Requirement 7: Invalidation', () {
      test('clear() removes all cached entries', () {
        final painter1 = TextPainter(
          text: TextSpan(text: 'Label1', style: testStyle1),
          textDirection: TextDirection.ltr,
        )..layout();

        final painter2 = TextPainter(
          text: TextSpan(text: 'Label2', style: testStyle1),
          textDirection: TextDirection.ltr,
        )..layout();

        cache.put('Label1', testStyle1, painter1);
        cache.put('Label2', testStyle1, painter2);

        expect(cache.length, greaterThan(0));

        cache.clear();

        expect(cache.length, equals(0), reason: 'Cache should be empty after clear()');

        expect(cache.get('Label1', testStyle1), isNull, reason: 'Cleared entries should return null');
        expect(cache.get('Label2', testStyle1), isNull, reason: 'Cleared entries should return null');
      });

      test('clear() resets hit/miss counters', () {
        final painter = TextPainter(
          text: TextSpan(text: 'Test', style: testStyle1),
          textDirection: TextDirection.ltr,
        )..layout();

        cache.put('Test', testStyle1, painter);
        cache.get('Test', testStyle1); // Hit
        cache.get('NonExistent', testStyle1); // Miss

        expect(cache.hitRate, greaterThan(0.0));

        cache.clear();

        expect(cache.hitRate, equals(0.0), reason: 'Hit rate should reset to 0.0 after clear()');
      });
    });

    group('length property', () {
      test('length reflects current cache size', () {
        expect(cache.length, equals(0), reason: 'Empty cache should have length 0');

        final painter1 = TextPainter(
          text: TextSpan(text: 'Label1', style: testStyle1),
          textDirection: TextDirection.ltr,
        )..layout();

        cache.put('Label1', testStyle1, painter1);
        expect(cache.length, equals(1));

        final painter2 = TextPainter(
          text: TextSpan(text: 'Label2', style: testStyle1),
          textDirection: TextDirection.ltr,
        )..layout();

        cache.put('Label2', testStyle1, painter2);
        expect(cache.length, equals(2));

        cache.clear();
        expect(cache.length, equals(0));
      });

      test('length never exceeds maxSize', () {
        final smallCache = LinkedHashMapTextLayoutCache(maxSize: 5);

        for (int i = 0; i < 100; i++) {
          final painter = TextPainter(
            text: TextSpan(text: 'Label$i', style: testStyle1),
            textDirection: TextDirection.ltr,
          )..layout();

          smallCache.put('Label$i', testStyle1, painter);

          expect(smallCache.length, lessThanOrEqualTo(5), reason: 'Length should never exceed maxSize');
        }
      });
    });

    group('Performance validation (target: >70% hit rate)', () {
      test('typical label-heavy chart achieves >70% hit rate', () {
        // Simulate bar chart with repeated labels
        final labelCache = LinkedHashMapTextLayoutCache(maxSize: 100);

        final commonLabels = ['Q1', 'Q2', 'Q3', 'Q4'];
        final years = ['2021', '2022', '2023'];

        // First render: populate cache (all misses)
        for (final year in years) {
          for (final label in commonLabels) {
            final text = '$label $year';
            var painter = labelCache.get(text, testStyle1);

            if (painter == null) {
              painter = TextPainter(
                text: TextSpan(text: text, style: testStyle1),
                textDirection: TextDirection.ltr,
              )..layout();
              labelCache.put(text, testStyle1, painter);
            }
          }
        }

        // Second render: mostly hits
        for (final year in years) {
          for (final label in commonLabels) {
            final text = '$label $year';
            final painter = labelCache.get(text, testStyle1);
            expect(painter, isNotNull);
          }
        }

        // Hit rate should be ≥50% (12 misses + 12 hits = 50%)
        expect(labelCache.hitRate, greaterThanOrEqualTo(0.5), reason: 'Repeated labels should achieve good hit rate');
      });
    });
  });
}
