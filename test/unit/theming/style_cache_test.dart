// StyleCache Tests
// Feature: 004-theming-system
// Phase 4: Utilities (T032)

import 'package:braven_charts/src/theming/utilities/style_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StyleCacheKey', () {
    test('equality works correctly', () {
      final key1 = const StyleCacheKey(themeHash: 123, elementType: 'axis', overridesHash: 456);
      final key2 = const StyleCacheKey(themeHash: 123, elementType: 'axis', overridesHash: 456);
      final key3 = const StyleCacheKey(themeHash: 999, elementType: 'axis', overridesHash: 456);

      expect(key1, equals(key2));
      expect(key1, isNot(equals(key3)));
    });

    test('hashCode is consistent', () {
      final key1 = const StyleCacheKey(themeHash: 123, elementType: 'axis', overridesHash: 456);
      final key2 = const StyleCacheKey(themeHash: 123, elementType: 'axis', overridesHash: 456);

      expect(key1.hashCode, equals(key2.hashCode));
    });

    test('null overridesHash works correctly', () {
      final key1 = const StyleCacheKey(themeHash: 123, elementType: 'axis');
      final key2 = const StyleCacheKey(themeHash: 123, elementType: 'axis');
      final key3 = const StyleCacheKey(themeHash: 123, elementType: 'axis', overridesHash: 456);

      expect(key1, equals(key2));
      expect(key1, isNot(equals(key3)));
    });

    test('different element types are not equal', () {
      final key1 = const StyleCacheKey(themeHash: 123, elementType: 'axis');
      final key2 = const StyleCacheKey(themeHash: 123, elementType: 'grid');

      expect(key1, isNot(equals(key2)));
    });
  });

  group('StyleCache - Basic Operations', () {
    late StyleCache cache;

    setUp(() {
      cache = StyleCache();
    });

    test('get() returns null for missing key', () {
      final key = const StyleCacheKey(themeHash: 123, elementType: 'axis');
      final result = cache.get<String>(key);

      expect(result, isNull);
      expect(cache.misses, equals(1));
      expect(cache.hits, equals(0));
    });

    test('put() and get() work correctly', () {
      final key = const StyleCacheKey(themeHash: 123, elementType: 'axis');
      const value = 'test-style';

      cache.put(key, value);
      final result = cache.get<String>(key);

      expect(result, equals(value));
      expect(cache.size, equals(1));
      expect(cache.hits, equals(1));
    });

    test('put() updates existing entry', () {
      final key = const StyleCacheKey(themeHash: 123, elementType: 'axis');

      cache.put(key, 'first');
      cache.put(key, 'second');

      expect(cache.get<String>(key), equals('second'));
      expect(cache.size, equals(1)); // Still only one entry
    });

    test('clear() empties the cache', () {
      final key1 = const StyleCacheKey(themeHash: 123, elementType: 'axis');
      final key2 = const StyleCacheKey(themeHash: 456, elementType: 'grid');

      cache.put(key1, 'value1');
      cache.put(key2, 'value2');
      expect(cache.size, equals(2));

      cache.clear();

      expect(cache.size, equals(0));
      expect(cache.isEmpty, isTrue);
      expect(cache.get<String>(key1), isNull);
      expect(cache.get<String>(key2), isNull);
    });

    test('clear() resets hit/miss counters', () {
      final key = const StyleCacheKey(themeHash: 123, elementType: 'axis');

      cache.put(key, 'value');
      cache.get<String>(key); // hit
      cache.get<String>(const StyleCacheKey(themeHash: 999, elementType: 'other')); // miss

      expect(cache.hits, equals(1));
      expect(cache.misses, equals(1));

      cache.clear();

      expect(cache.hits, equals(0));
      expect(cache.misses, equals(0));
    });

    test('containsKey() works correctly', () {
      final key = const StyleCacheKey(themeHash: 123, elementType: 'axis');

      expect(cache.containsKey(key), isFalse);

      cache.put(key, 'value');

      expect(cache.containsKey(key), isTrue);
    });

    test('containsKey() does not affect hit rate', () {
      final key = const StyleCacheKey(themeHash: 123, elementType: 'axis');
      cache.put(key, 'value');

      cache.containsKey(key);
      cache.containsKey(key);

      expect(cache.hits, equals(0));
      expect(cache.misses, equals(0));
    });
  });

  group('StyleCache - LRU Eviction', () {
    late StyleCache cache;

    setUp(() {
      cache = StyleCache();
    });

    test('evicts oldest entry when maxSize exceeded', () {
      // Fill cache to max
      for (int i = 0; i < StyleCache.maxSize; i++) {
        final key = StyleCacheKey(themeHash: i, elementType: 'test');
        cache.put(key, 'value-$i');
      }

      expect(cache.size, equals(StyleCache.maxSize));
      expect(cache.isFull, isTrue);

      // Add one more - should evict first entry
      final newKey = const StyleCacheKey(themeHash: 9999, elementType: 'new');
      cache.put(newKey, 'new-value');

      expect(cache.size, equals(StyleCache.maxSize)); // Still at max
      expect(cache.get<String>(const StyleCacheKey(themeHash: 0, elementType: 'test')), isNull); // First entry evicted
      expect(cache.get<String>(newKey), equals('new-value')); // New entry exists
    });

    test('get() moves entry to end (most recently used)', () {
      // Add three entries
      final key1 = const StyleCacheKey(themeHash: 1, elementType: 'test');
      final key2 = const StyleCacheKey(themeHash: 2, elementType: 'test');
      final key3 = const StyleCacheKey(themeHash: 3, elementType: 'test');

      cache.put(key1, 'value1');
      cache.put(key2, 'value2');
      cache.put(key3, 'value3');

      // Access key1 to move it to end
      cache.get<String>(key1);

      // Now order is: key2, key3, key1 (key1 is newest)

      // Fill cache to max-3 (leaving room for our 3 keys)
      for (int i = 4; i <= StyleCache.maxSize; i++) {
        cache.put(StyleCacheKey(themeHash: i, elementType: 'test'), 'value-$i');
      }

      // Cache is full. Next put should evict key2 (oldest unreferenced)
      final newKey = const StyleCacheKey(themeHash: 99999, elementType: 'new');
      cache.put(newKey, 'new-value');

      // key2 should be evicted, key3 and key1 should still exist
      expect(cache.get<String>(key2), isNull); // Evicted
      expect(cache.get<String>(key3), isNotNull); // Still exists
      expect(cache.get<String>(key1), equals('value1')); // Still exists
    });

    test('put() on existing key moves it to end', () {
      // Add two entries
      final key1 = const StyleCacheKey(themeHash: 1, elementType: 'test');
      final key2 = const StyleCacheKey(themeHash: 2, elementType: 'test');

      cache.put(key1, 'value1');
      cache.put(key2, 'value2');

      // Update key1 - should move to end
      cache.put(key1, 'value1-updated');

      // Now order is: key2, key1 (key1 is newest)

      // Fill cache to max-2 (leaving room for our 2 keys)
      for (int i = 3; i <= StyleCache.maxSize; i++) {
        cache.put(StyleCacheKey(themeHash: i, elementType: 'test'), 'value-$i');
      }

      // Cache is full. Next put should evict key2 (oldest)
      final newKey = const StyleCacheKey(themeHash: 99999, elementType: 'new');
      cache.put(newKey, 'new-value');

      // key1 should still exist (was moved to end on update)
      expect(cache.get<String>(key1), equals('value1-updated'));
      // key2 should be evicted
      expect(cache.get<String>(key2), isNull);
    });
  });

  group('StyleCache - Hit Rate Calculation', () {
    late StyleCache cache;

    setUp(() {
      cache = StyleCache();
    });

    test('hitRate is 0.0 initially', () {
      expect(cache.hitRate, equals(0.0));
    });

    test('hitRate is 1.0 with all hits', () {
      final key = const StyleCacheKey(themeHash: 123, elementType: 'axis');
      cache.put(key, 'value');

      cache.get<String>(key); // hit
      cache.get<String>(key); // hit
      cache.get<String>(key); // hit

      expect(cache.hitRate, equals(1.0));
      expect(cache.hits, equals(3));
      expect(cache.misses, equals(0));
    });

    test('hitRate is 0.0 with all misses', () {
      cache.get<String>(const StyleCacheKey(themeHash: 1, elementType: 'a')); // miss
      cache.get<String>(const StyleCacheKey(themeHash: 2, elementType: 'b')); // miss
      cache.get<String>(const StyleCacheKey(themeHash: 3, elementType: 'c')); // miss

      expect(cache.hitRate, equals(0.0));
      expect(cache.hits, equals(0));
      expect(cache.misses, equals(3));
    });

    test('hitRate calculates correctly with mixed hits/misses', () {
      final key1 = const StyleCacheKey(themeHash: 1, elementType: 'test');
      final key2 = const StyleCacheKey(themeHash: 2, elementType: 'test');

      cache.put(key1, 'value');

      cache.get<String>(key1); // hit
      cache.get<String>(key2); // miss
      cache.get<String>(key1); // hit
      cache.get<String>(key2); // miss

      expect(cache.hits, equals(2));
      expect(cache.misses, equals(2));
      expect(cache.hitRate, equals(0.5));
    });

    test('hitRate updates after clear', () {
      final key = const StyleCacheKey(themeHash: 123, elementType: 'axis');
      cache.put(key, 'value');
      cache.get<String>(key); // hit

      expect(cache.hitRate, equals(1.0));

      cache.clear();

      expect(cache.hitRate, equals(0.0));
    });
  });

  group('StyleCache - Type Safety', () {
    late StyleCache cache;

    setUp(() {
      cache = StyleCache();
    });

    test('generic get() returns correct type', () {
      final key = const StyleCacheKey(themeHash: 123, elementType: 'test');
      const value = 'string-value';

      cache.put(key, value);
      final result = cache.get<String>(key);

      expect(result, isA<String>());
      expect(result, equals(value));
    });

    test('can store different types', () {
      final key1 = const StyleCacheKey(themeHash: 1, elementType: 'string');
      final key2 = const StyleCacheKey(themeHash: 2, elementType: 'int');
      final key3 = const StyleCacheKey(themeHash: 3, elementType: 'bool');

      cache.put(key1, 'text');
      cache.put(key2, 42);
      cache.put(key3, true);

      expect(cache.get<String>(key1), equals('text'));
      expect(cache.get<int>(key2), equals(42));
      expect(cache.get<bool>(key3), equals(true));
    });
  });

  group('StyleCache - Properties', () {
    late StyleCache cache;

    setUp(() {
      cache = StyleCache();
    });

    test('isEmpty works correctly', () {
      expect(cache.isEmpty, isTrue);

      cache.put(const StyleCacheKey(themeHash: 1, elementType: 'test'), 'value');

      expect(cache.isEmpty, isFalse);

      cache.clear();

      expect(cache.isEmpty, isTrue);
    });

    test('isFull works correctly', () {
      expect(cache.isFull, isFalse);

      // Fill to max
      for (int i = 0; i < StyleCache.maxSize; i++) {
        cache.put(StyleCacheKey(themeHash: i, elementType: 'test'), 'value-$i');
      }

      expect(cache.isFull, isTrue);

      cache.clear();

      expect(cache.isFull, isFalse);
    });

    test('size reflects number of entries', () {
      expect(cache.size, equals(0));

      for (int i = 0; i < 10; i++) {
        cache.put(StyleCacheKey(themeHash: i, elementType: 'test'), 'value-$i');
        expect(cache.size, equals(i + 1));
      }
    });
  });
}
