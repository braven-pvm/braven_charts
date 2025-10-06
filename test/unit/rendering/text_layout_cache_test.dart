// Unit Tests: TextLayoutCache LRU Eviction
// Feature: 002-core-rendering
// Task: T017
// Purpose: Validate LRU eviction, cache key handling, hit/miss tracking

import 'package:braven_charts/src/rendering/text_layout_cache.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinkedHashMapTextLayoutCache - LRU Eviction', () {
    test('evicts oldest entry when maxSize exceeded', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 3);
      final style = const TextStyle(fontSize: 14);

      // Fill cache to capacity
      final painter1 = TextPainter(
        text: const TextSpan(text: 'First'),
        textDirection: TextDirection.ltr,
      );
      final painter2 = TextPainter(
        text: const TextSpan(text: 'Second'),
        textDirection: TextDirection.ltr,
      );
      final painter3 = TextPainter(
        text: const TextSpan(text: 'Third'),
        textDirection: TextDirection.ltr,
      );

      cache.put('First', style, painter1);
      cache.put('Second', style, painter2);
      cache.put('Third', style, painter3);

      expect(cache.length, equals(3));

      // Add fourth entry - should evict 'First' (oldest)
      final painter4 = TextPainter(
        text: const TextSpan(text: 'Fourth'),
        textDirection: TextDirection.ltr,
      );
      cache.put('Fourth', style, painter4);

      expect(cache.length, equals(3),
          reason: 'Cache size should remain at maxSize');
      expect(cache.get('First', style), isNull,
          reason: 'Oldest entry should be evicted');
      expect(cache.get('Second', style), isNotNull,
          reason: 'Second entry should remain');
      expect(cache.get('Third', style), isNotNull,
          reason: 'Third entry should remain');
      expect(cache.get('Fourth', style), isNotNull,
          reason: 'New entry should be cached');
    });

    test('evicts multiple entries as cache fills beyond capacity', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 2);
      final style = const TextStyle(fontSize: 14);

      // Add entries in sequence
      for (int i = 0; i < 5; i++) {
        final painter = TextPainter(
          text: TextSpan(text: 'Entry$i'),
          textDirection: TextDirection.ltr,
        );
        cache.put('Entry$i', style, painter);
      }

      // Cache should only contain last 2 entries (Entry3, Entry4)
      expect(cache.length, equals(2));
      expect(cache.get('Entry0', style), isNull);
      expect(cache.get('Entry1', style), isNull);
      expect(cache.get('Entry2', style), isNull);
      expect(cache.get('Entry3', style), isNotNull);
      expect(cache.get('Entry4', style), isNotNull);
    });

    test('get() after eviction returns null for evicted key', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 1);
      final style = const TextStyle(fontSize: 14);

      final painter1 = TextPainter(
        text: const TextSpan(text: 'Evicted'),
        textDirection: TextDirection.ltr,
      );
      cache.put('Evicted', style, painter1);
      expect(cache.get('Evicted', style), isNotNull,
          reason: 'Entry should exist before eviction');

      // Add second entry, evicting first
      final painter2 = TextPainter(
        text: const TextSpan(text: 'Retained'),
        textDirection: TextDirection.ltr,
      );
      cache.put('Retained', style, painter2);

      expect(cache.get('Evicted', style), isNull,
          reason: 'Evicted entry should return null');
      expect(cache.get('Retained', style), isNotNull,
          reason: 'Current entry should exist');
    });

    test('accessing entry moves it to most recently used position', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 3);
      final style = const TextStyle(fontSize: 14);

      // Fill cache
      final painter1 = TextPainter(
          text: const TextSpan(text: 'Old'), textDirection: TextDirection.ltr);
      final painter2 = TextPainter(
          text: const TextSpan(text: 'Middle'),
          textDirection: TextDirection.ltr);
      final painter3 = TextPainter(
          text: const TextSpan(text: 'Recent'),
          textDirection: TextDirection.ltr);

      cache.put('Old', style, painter1);
      cache.put('Middle', style, painter2);
      cache.put('Recent', style, painter3);

      // Access 'Old' to move it to end (most recently used)
      cache.get('Old', style);

      // Add new entry - should evict 'Middle' (now oldest)
      final painter4 = TextPainter(
          text: const TextSpan(text: 'New'), textDirection: TextDirection.ltr);
      cache.put('New', style, painter4);

      expect(cache.get('Old', style), isNotNull,
          reason: 'Accessed entry should be retained');
      expect(cache.get('Middle', style), isNull,
          reason: 'Least recently used should be evicted');
      expect(cache.get('Recent', style), isNotNull,
          reason: 'Recent entry should be retained');
      expect(cache.get('New', style), isNotNull,
          reason: 'New entry should be cached');
    });
  });

  group('LinkedHashMapTextLayoutCache - Cache Key Handling', () {
    test('put() updates existing key without creating duplicate', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 5);
      final style = const TextStyle(fontSize: 14);

      final painter1 = TextPainter(
        text: const TextSpan(text: 'Version1'),
        textDirection: TextDirection.ltr,
      );
      cache.put('Label', style, painter1);
      expect(cache.length, equals(1));

      // Update same key with new painter
      final painter2 = TextPainter(
        text: const TextSpan(text: 'Version2'),
        textDirection: TextDirection.ltr,
      );
      cache.put('Label', style, painter2);

      expect(cache.length, equals(1),
          reason: 'Should update existing key, not add duplicate');

      final retrieved = cache.get('Label', style);
      expect(retrieved, equals(painter2),
          reason: 'Should return most recent painter');
    });

    test('different text with same style creates separate cache entries', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 10);
      final style = const TextStyle(fontSize: 14);

      final painter1 = TextPainter(
          text: const TextSpan(text: 'A'), textDirection: TextDirection.ltr);
      final painter2 = TextPainter(
          text: const TextSpan(text: 'B'), textDirection: TextDirection.ltr);

      cache.put('A', style, painter1);
      cache.put('B', style, painter2);

      expect(cache.length, equals(2),
          reason: 'Different text should create separate entries');
      expect(cache.get('A', style), equals(painter1));
      expect(cache.get('B', style), equals(painter2));
    });

    test('same text with different styles creates separate cache entries', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 10);
      final style1 = const TextStyle(fontSize: 14);
      final style2 = const TextStyle(fontSize: 16); // Different style

      final painter1 = TextPainter(
          text: const TextSpan(text: 'Label'),
          textDirection: TextDirection.ltr);
      final painter2 = TextPainter(
          text: const TextSpan(text: 'Label'),
          textDirection: TextDirection.ltr);

      cache.put('Label', style1, painter1);
      cache.put('Label', style2, painter2);

      expect(cache.length, equals(2),
          reason: 'Different styles should create separate entries');
      expect(cache.get('Label', style1), equals(painter1));
      expect(cache.get('Label', style2), equals(painter2));
    });

    test('updating existing key moves it to most recently used position', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 3);
      final style = const TextStyle(fontSize: 14);

      // Fill cache
      cache.put(
          'First',
          style,
          TextPainter(
              text: const TextSpan(text: 'F'),
              textDirection: TextDirection.ltr));
      cache.put(
          'Second',
          style,
          TextPainter(
              text: const TextSpan(text: 'S'),
              textDirection: TextDirection.ltr));
      cache.put(
          'Third',
          style,
          TextPainter(
              text: const TextSpan(text: 'T'),
              textDirection: TextDirection.ltr));

      // Update 'First' (should move to end)
      final updated = TextPainter(
          text: const TextSpan(text: 'Updated'),
          textDirection: TextDirection.ltr);
      cache.put('First', style, updated);

      // Add new entry - should evict 'Second' (now oldest)
      cache.put(
          'Fourth',
          style,
          TextPainter(
              text: const TextSpan(text: 'Fo'),
              textDirection: TextDirection.ltr));

      expect(cache.get('First', style), equals(updated),
          reason: 'Updated entry should be retained');
      expect(cache.get('Second', style), isNull,
          reason: 'Least recently used should be evicted');
      expect(cache.get('Third', style), isNotNull);
      expect(cache.get('Fourth', style), isNotNull);
    });
  });

  group('LinkedHashMapTextLayoutCache - Hit Rate Tracking', () {
    test('hitRate returns 0.0 when no lookups performed', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 10);
      expect(cache.hitRate, equals(0.0));
    });

    test('hitRate calculates correctly after all misses', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 10);
      final style = const TextStyle(fontSize: 14);

      // All misses
      cache.get('A', style);
      cache.get('B', style);
      cache.get('C', style);

      expect(cache.hitRate, equals(0.0),
          reason: 'hitRate should be 0% with all misses');
    });

    test('hitRate calculates correctly after all hits', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 10);
      final style = const TextStyle(fontSize: 14);

      // Add entry
      final painter = TextPainter(
          text: const TextSpan(text: 'Label'),
          textDirection: TextDirection.ltr);
      cache.put('Label', style, painter);

      // All hits (3 successful lookups)
      cache.get('Label', style);
      cache.get('Label', style);
      cache.get('Label', style);

      expect(cache.hitRate, equals(1.0),
          reason: 'hitRate should be 100% with all hits');
    });

    test('hitRate calculates correctly with mixed hits and misses', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 10);
      final style = const TextStyle(fontSize: 14);

      final painter = TextPainter(
          text: const TextSpan(text: 'Cached'),
          textDirection: TextDirection.ltr);
      cache.put('Cached', style, painter);

      // 2 hits
      cache.get('Cached', style);
      cache.get('Cached', style);

      // 3 misses
      cache.get('Miss1', style);
      cache.get('Miss2', style);
      cache.get('Miss3', style);

      // hitRate = 2 / (2 + 3) = 0.4
      expect(cache.hitRate, equals(0.4));
    });

    test('hitRate updates dynamically as hits and misses accumulate', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 10);
      final style = const TextStyle(fontSize: 14);

      final painter = TextPainter(
          text: const TextSpan(text: 'Label'),
          textDirection: TextDirection.ltr);
      cache.put('Label', style, painter);

      // Initial: 1 hit
      cache.get('Label', style);
      expect(cache.hitRate, equals(1.0), reason: '1 hit / 1 lookup = 100%');

      // Add miss
      cache.get('Unknown', style);
      expect(cache.hitRate, equals(0.5), reason: '1 hit / 2 lookups = 50%');

      // Add 2 more hits
      cache.get('Label', style);
      cache.get('Label', style);
      expect(cache.hitRate, equals(0.75), reason: '3 hits / 4 lookups = 75%');
    });

    test('hitRate precision with large number of lookups', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 10);
      final style = const TextStyle(fontSize: 14);

      final painter = TextPainter(
          text: const TextSpan(text: 'Label'),
          textDirection: TextDirection.ltr);
      cache.put('Label', style, painter);

      // 70 hits
      for (int i = 0; i < 70; i++) {
        cache.get('Label', style);
      }

      // 30 misses
      for (int i = 0; i < 30; i++) {
        cache.get('Miss$i', style);
      }

      // hitRate = 70 / 100 = 0.70 (70%)
      expect(cache.hitRate, closeTo(0.70, 0.001),
          reason: 'hitRate should be 70% ±0.1%');
    });
  });

  group('LinkedHashMapTextLayoutCache - Clear Behavior', () {
    test('clear() empties cache completely', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 10);
      final style = const TextStyle(fontSize: 14);

      // Add multiple entries
      for (int i = 0; i < 5; i++) {
        final painter = TextPainter(
            text: TextSpan(text: 'Entry$i'), textDirection: TextDirection.ltr);
        cache.put('Entry$i', style, painter);
      }
      expect(cache.length, equals(5));

      cache.clear();

      expect(cache.length, equals(0),
          reason: 'Cache should be empty after clear()');
      expect(cache.get('Entry0', style), isNull,
          reason: 'All entries should be removed');
    });

    test('clear() resets hit and miss counters to zero', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 10);
      final style = const TextStyle(fontSize: 14);

      final painter = TextPainter(
          text: const TextSpan(text: 'Label'),
          textDirection: TextDirection.ltr);
      cache.put('Label', style, painter);

      // Generate hits and misses
      cache.get('Label', style); // hit
      cache.get('Unknown', style); // miss
      expect(cache.hitRate, equals(0.5),
          reason: 'Should have 50% hit rate before clear');

      cache.clear();

      expect(cache.hitRate, equals(0.0),
          reason: 'Hit rate should reset to 0% after clear');
    });

    test('clear() allows cache to be reused normally', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 10);
      final style = const TextStyle(fontSize: 14);

      // Use cache
      final painter1 = TextPainter(
          text: const TextSpan(text: 'Before'),
          textDirection: TextDirection.ltr);
      cache.put('Before', style, painter1);
      cache.get('Before', style);

      cache.clear();

      // Reuse cache
      final painter2 = TextPainter(
          text: const TextSpan(text: 'After'),
          textDirection: TextDirection.ltr);
      cache.put('After', style, painter2);
      final retrieved = cache.get('After', style);

      expect(retrieved, equals(painter2),
          reason: 'Cache should work normally after clear');
      expect(cache.length, equals(1));
      expect(cache.hitRate, equals(1.0),
          reason: 'New hit rate should calculate correctly');
    });
  });

  group('LinkedHashMapTextLayoutCache - Edge Cases', () {
    test('maxSize=1 cache evicts on every put', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 1);
      final style = const TextStyle(fontSize: 14);

      final painter1 = TextPainter(
          text: const TextSpan(text: 'A'), textDirection: TextDirection.ltr);
      cache.put('A', style, painter1);
      expect(cache.length, equals(1));

      final painter2 = TextPainter(
          text: const TextSpan(text: 'B'), textDirection: TextDirection.ltr);
      cache.put('B', style, painter2);
      expect(cache.length, equals(1));
      expect(cache.get('A', style), isNull,
          reason: 'Previous entry should be evicted');
      expect(cache.get('B', style), equals(painter2));
    });

    test('empty text and style are valid cache keys', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 10);
      final style = const TextStyle();

      final painter = TextPainter(
          text: const TextSpan(text: ''), textDirection: TextDirection.ltr);
      cache.put('', style, painter);

      expect(cache.length, equals(1));
      expect(cache.get('', style), equals(painter),
          reason: 'Empty string should be valid key');
    });

    test('cache handles unicode and special characters in text', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 10);
      final style = const TextStyle(fontSize: 14);

      final texts = ['emoji 😀', '中文字符', 'العربية', 'Ñoño', '\n\t\r'];

      for (final text in texts) {
        final painter = TextPainter(
            text: TextSpan(text: text), textDirection: TextDirection.ltr);
        cache.put(text, style, painter);
      }

      expect(cache.length, equals(texts.length),
          reason: 'All special character texts should be cached');

      for (final text in texts) {
        expect(cache.get(text, style), isNotNull,
            reason: 'Should retrieve: $text');
      }
    });

    test('large maxSize does not affect correctness', () {
      final cache = LinkedHashMapTextLayoutCache(maxSize: 10000);
      final style = const TextStyle(fontSize: 14);

      // Add 100 entries (well below maxSize)
      for (int i = 0; i < 100; i++) {
        final painter = TextPainter(
            text: TextSpan(text: 'Entry$i'), textDirection: TextDirection.ltr);
        cache.put('Entry$i', style, painter);
      }

      expect(cache.length, equals(100));

      // All entries should be retrievable
      for (int i = 0; i < 100; i++) {
        expect(cache.get('Entry$i', style), isNotNull,
            reason: 'Entry$i should exist');
      }
    });
  });
}
