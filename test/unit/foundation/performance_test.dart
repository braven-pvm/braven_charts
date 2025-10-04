import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/foundation/performance/object_pool.dart';
import 'package:braven_charts/src/foundation/performance/viewport_culler.dart';
import 'package:braven_charts/src/foundation/performance/batch_processor.dart';
import 'package:braven_charts/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/src/foundation/data_models/data_range.dart' as dr;

void main() {
  group('ObjectPool<T> Unit Tests', () {
    group('Constructor', () {
      test('creates pool with factory and reset functions', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
        );
        expect(pool, isNotNull);
        expect(pool.maxSize, equals(100)); // Default
      });

      test('accepts custom maxSize', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
          maxSize: 50,
        );
        expect(pool.maxSize, equals(50));
      });

      test('throws assertion error for invalid maxSize', () {
        expect(
          () => ObjectPool<String>(
            factory: () => 'test',
            reset: (s) {},
            maxSize: 0,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('acquire()', () {
      test('creates new object when pool is empty', () {
        int createCount = 0;
        final pool = ObjectPool<int>(
          factory: () => ++createCount,
          reset: (i) {},
        );

        final obj = pool.acquire();
        expect(obj, equals(1));
        expect(createCount, equals(1));
      });

      test('reuses released object', () {
        int createCount = 0;
        final pool = ObjectPool<int>(
          factory: () => ++createCount,
          reset: (i) {},
        );

        final obj1 = pool.acquire();
        pool.release(obj1);

        final obj2 = pool.acquire();
        expect(obj2, equals(obj1));
        expect(createCount, equals(1)); // No new creation
      });

      test('tracks objects in use', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
        );

        final obj = pool.acquire();
        expect(pool.isTracked(obj), isTrue);
      });

      test('increments acquire count', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
        );

        pool.acquire();
        pool.acquire();
        pool.acquire();

        expect(pool.statistics.acquireCount, equals(3));
      });

      test('increments total created for new objects', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
        );

        pool.acquire();
        pool.acquire();

        expect(pool.statistics.totalCreated, equals(2));
      });

      test('does not increment total created for reused objects', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
        );

        final obj = pool.acquire();
        pool.release(obj);
        pool.acquire(); // Reuse

        expect(pool.statistics.totalCreated, equals(1));
      });
    });

    group('release()', () {
      test('returns object to pool', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
        );

        final obj = pool.acquire();
        pool.release(obj);

        expect(pool.isTracked(obj), isFalse);
      });

      test('calls reset function', () {
        int resetCount = 0;
        final pool = ObjectPool<int>(
          factory: () => 42,
          reset: (i) {
            resetCount++;
          },
        );

        final obj = pool.acquire();
        pool.release(obj);

        expect(resetCount, equals(1));
      });

      test('increments release count', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
        );

        final obj = pool.acquire();
        pool.release(obj);

        expect(pool.statistics.releaseCount, equals(1));
      });

      test('adds to available pool', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
        );

        final obj = pool.acquire();
        pool.release(obj);

        final stats = pool.statistics;
        expect(stats.currentSize, equals(1));
        expect(stats.currentInUse, equals(0));
      });

      test('respects maxSize limit', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
          maxSize: 2,
        );

        // Acquire and release sequentially
        final obj1 = pool.acquire();
        pool.release(obj1);

        final obj2 = pool.acquire();
        pool.release(obj2);

        final obj3 = pool.acquire();
        pool.release(obj3);

        // Pool should only hold maxSize objects
        expect(pool.statistics.currentSize, equals(1)); // Only last release kept
      });

      test('throws assertion error for untracked object', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
        );

        expect(
          () => pool.release('untracked'),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('clear()', () {
      test('empties available pool', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
        );

        final obj = pool.acquire();
        pool.release(obj);
        pool.clear();

        expect(pool.statistics.currentSize, equals(0));
      });

      test('clears in-use tracking', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
        );

        final obj = pool.acquire();
        pool.clear();

        expect(pool.statistics.currentInUse, equals(0));
      });

      test('resets statistics counters', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
        );

        pool.acquire();
        pool.clear();

        final stats = pool.statistics;
        expect(stats.totalCreated, equals(0));
        expect(stats.acquireCount, equals(0));
        expect(stats.releaseCount, equals(0));
      });
    });

    group('isTracked()', () {
      test('returns true for acquired object', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
        );

        final obj = pool.acquire();
        expect(pool.isTracked(obj), isTrue);
      });

      test('returns false for released object', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
        );

        final obj = pool.acquire();
        pool.release(obj);
        expect(pool.isTracked(obj), isFalse);
      });

      test('returns false for unknown object', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
        );

        expect(pool.isTracked('unknown'), isFalse);
      });
    });

    group('statistics', () {
      test('tracks totalCreated correctly', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
        );

        pool.acquire();
        pool.acquire();
        pool.acquire();

        expect(pool.statistics.totalCreated, equals(3));
      });

      test('tracks currentSize correctly', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
        );

        final obj1 = pool.acquire();
        pool.release(obj1);

        final obj2 = pool.acquire(); // Reuses obj1
        pool.release(obj2);

        expect(pool.statistics.currentSize, equals(1)); // Only one object in pool
      });

      test('tracks currentInUse correctly', () {
        int counter = 0;
        final pool = ObjectPool<String>(
          factory: () => 'test-${counter++}', // Unique strings
          reset: (s) {},
        );

        pool.acquire();
        pool.acquire();

        expect(pool.statistics.currentInUse, equals(2));
      });

      test('calculates hit rate correctly', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
        );

        final obj = pool.acquire();
        pool.release(obj); // 1 release
        pool.acquire(); // 2 acquires total

        final stats = pool.statistics;
        expect(stats.hitRate, equals(0.5)); // 1/2
      });

      test('hit rate is 0 when no releases', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
        );

        pool.acquire();

        expect(pool.statistics.hitRate, equals(0.0));
      });

      test('hit rate is 0 when no acquires', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
        );

        expect(pool.statistics.hitRate, equals(0.0));
      });
    });

    group('Generic Types', () {
      test('works with int type', () {
        final pool = ObjectPool<int>(
          factory: () => 42,
          reset: (i) {},
        );

        final obj = pool.acquire();
        expect(obj, equals(42));
      });

      test('works with custom class', () {
        final pool = ObjectPool<ChartDataPoint>(
          factory: () => const ChartDataPoint(x: 0.0, y: 0.0),
          reset: (p) {},
        );

        final obj = pool.acquire();
        expect(obj, isA<ChartDataPoint>());
      });

      test('works with List type', () {
        final pool = ObjectPool<List<int>>(
          factory: () => [],
          reset: (list) => list.clear(),
        );

        final list = pool.acquire();
        list.add(1);
        pool.release(list);

        final list2 = pool.acquire();
        expect(list2.isEmpty, isTrue); // Reset was called
      });
    });

    group('Edge Cases', () {
      test('handles maxSize of 1', () {
        final pool = ObjectPool<String>(
          factory: () => 'test',
          reset: (s) {},
          maxSize: 1,
        );

        final obj1 = pool.acquire();
        pool.release(obj1);

        final obj2 = pool.acquire(); // Reuses obj1
        pool.release(obj2);

        expect(pool.statistics.currentSize, equals(1));
        expect(pool.statistics.totalCreated, equals(1)); // Only created once
      });

      test('handles many acquire/release cycles', () {
        final pool = ObjectPool<int>(
          factory: () => 0,
          reset: (i) {},
        );

        for (int i = 0; i < 1000; i++) {
          final obj = pool.acquire();
          pool.release(obj);
        }

        final stats = pool.statistics;
        expect(stats.acquireCount, equals(1000));
        expect(stats.releaseCount, equals(1000));
        expect(stats.totalCreated, equals(1)); // Only created once
      });
    });
  });

  group('ViewportCuller Unit Tests', () {
    group('Constructor', () {
      test('creates culler with default margin', () {
        final culler = const ViewportCuller();
        expect(culler.margin, equals(0.1));
      });

      test('accepts custom margin', () {
        final culler = const ViewportCuller(margin: 0.2);
        expect(culler.margin, equals(0.2));
      });
    });

    group('calculateBounds()', () {
      test('applies margin to viewport', () {
        final culler = const ViewportCuller(margin: 0.1);
        final viewportX = const dr.DataRange(min: 0.0, max: 10.0);
        final viewportY = const dr.DataRange(min: 0.0, max: 10.0);

        final bounds = culler.calculateBounds(
          viewportX: viewportX,
          viewportY: viewportY,
        );

        expect(bounds.xRange.paddedMin, equals(-1.0));
        expect(bounds.xRange.paddedMax, equals(11.0));
      });

      test('handles different x and y margins', () {
        final culler = const ViewportCuller(margin: 0.1);
        final viewportX = const dr.DataRange(min: 0.0, max: 100.0);
        final viewportY = const dr.DataRange(min: 0.0, max: 10.0);

        final bounds = culler.calculateBounds(
          viewportX: viewportX,
          viewportY: viewportY,
        );

        expect(bounds.xRange.paddedMin, equals(-10.0)); // 10% of 100
        expect(bounds.yRange.paddedMin, equals(-1.0)); // 10% of 10
      });

      test('handles zero margin', () {
        final culler = const ViewportCuller(margin: 0.0);
        final viewport = const dr.DataRange(min: 5.0, max: 15.0);

        final bounds = culler.calculateBounds(
          viewportX: viewport,
          viewportY: viewport,
        );

        expect(bounds.xRange.paddedMin, equals(5.0));
        expect(bounds.xRange.paddedMax, equals(15.0));
      });
    });

    group('cull() - Unordered Data', () {
      test('filters points outside viewport', () {
        final culler = const ViewportCuller(margin: 0.0);
        final points = [
          const ChartDataPoint(x: 0.0, y: 0.0), // Outside
          const ChartDataPoint(x: 5.0, y: 5.0), // Inside
          const ChartDataPoint(x: 10.0, y: 10.0), // Inside
          const ChartDataPoint(x: 20.0, y: 20.0), // Outside
        ];

        final viewport = const dr.DataRange(min: 4.0, max: 11.0);
        final visible = culler.cull(
          points: points,
          viewportX: viewport,
          viewportY: viewport,
          isXOrdered: false,
        );

        expect(visible.length, equals(2));
        expect(visible[0].x, equals(5.0));
        expect(visible[1].x, equals(10.0));
      });

      test('returns empty list when no points visible', () {
        final culler = const ViewportCuller(margin: 0.0);
        final points = [
          const ChartDataPoint(x: 0.0, y: 0.0),
          const ChartDataPoint(x: 1.0, y: 1.0),
        ];

        final viewport = const dr.DataRange(min: 10.0, max: 20.0);
        final visible = culler.cull(
          points: points,
          viewportX: viewport,
          viewportY: viewport,
          isXOrdered: false,
        );

        expect(visible.isEmpty, isTrue);
      });

      test('returns all points when all visible', () {
        final culler = const ViewportCuller(margin: 0.0);
        final points = [
          const ChartDataPoint(x: 5.0, y: 5.0),
          const ChartDataPoint(x: 6.0, y: 6.0),
          const ChartDataPoint(x: 7.0, y: 7.0),
        ];

        final viewport = const dr.DataRange(min: 0.0, max: 10.0);
        final visible = culler.cull(
          points: points,
          viewportX: viewport,
          viewportY: viewport,
          isXOrdered: false,
        );

        expect(visible.length, equals(3));
      });

      test('handles empty points list', () {
        final culler = const ViewportCuller();
        final viewport = const dr.DataRange(min: 0.0, max: 10.0);

        final visible = culler.cull(
          points: [],
          viewportX: viewport,
          viewportY: viewport,
          isXOrdered: false,
        );

        expect(visible.isEmpty, isTrue);
      });

      test('applies margin correctly', () {
        final culler = const ViewportCuller(margin: 0.5); // 50% margin for clear math
        final points = [
          const ChartDataPoint(x: 4.0, y: 5.0), // Should be visible with margin
          const ChartDataPoint(x: 10.0, y: 5.0),
          const ChartDataPoint(x: 16.0, y: 5.0), // Should be visible with margin
        ];

        final viewport = const dr.DataRange(min: 8.0, max: 12.0); // Range of 4, center at 10
        // With 50% padding: paddedMin = 8 - (4 * 0.5) = 6, paddedMax = 12 + (4 * 0.5) = 14
        final visible = culler.cull(
          points: points,
          viewportX: viewport,
          viewportY: const dr.DataRange(min: 0.0, max: 10.0),
          isXOrdered: false,
        );

        // Points at x=4 (< 6) and x=16 (> 14) should be filtered out
        expect(visible.length, equals(1)); // Only middle point
      });
    });

    group('cull() - Ordered Data', () {
      test('uses binary search optimization', () {
        final culler = const ViewportCuller(margin: 0.0);
        final points = List.generate(
          1000,
          (i) => ChartDataPoint(x: i.toDouble(), y: i.toDouble()),
        );

        final viewport = const dr.DataRange(min: 100.0, max: 200.0);
        final visible = culler.cull(
          points: points,
          viewportX: viewport,
          viewportY: viewport,
          isXOrdered: true,
        );

        expect(visible.length, equals(101)); // 100-200 inclusive
        expect(visible.first.x, equals(100.0));
        expect(visible.last.x, equals(200.0));
      });

      test('handles viewport before all points', () {
        final culler = const ViewportCuller(margin: 0.0);
        final points = List.generate(
          10,
          (i) => ChartDataPoint(x: (i + 10).toDouble(), y: 0.0),
        );

        final viewport = const dr.DataRange(min: 0.0, max: 5.0);
        final visible = culler.cull(
          points: points,
          viewportX: viewport,
          viewportY: viewport,
          isXOrdered: true,
        );

        expect(visible.isEmpty, isTrue);
      });

      test('handles viewport after all points', () {
        final culler = const ViewportCuller(margin: 0.0);
        final points = List.generate(
          10,
          (i) => ChartDataPoint(x: i.toDouble(), y: 0.0),
        );

        final viewport = const dr.DataRange(min: 20.0, max: 30.0);
        final visible = culler.cull(
          points: points,
          viewportX: viewport,
          viewportY: viewport,
          isXOrdered: true,
        );

        expect(visible.isEmpty, isTrue);
      });

      test('handles single point visible', () {
        final culler = const ViewportCuller(margin: 0.0);
        final points = List.generate(
          10,
          (i) => ChartDataPoint(x: i.toDouble(), y: i.toDouble()),
        );

        final viewport = const dr.DataRange(min: 5.0, max: 5.0);
        final visible = culler.cull(
          points: points,
          viewportX: viewport,
          viewportY: viewport,
          isXOrdered: true,
        );

        expect(visible.length, equals(1));
        expect(visible.first.x, equals(5.0));
      });

      test('handles viewport at boundaries', () {
        final culler = const ViewportCuller(margin: 0.0);
        final points = List.generate(
          10,
          (i) => ChartDataPoint(x: i.toDouble(), y: 0.0),
        );

        final viewport = const dr.DataRange(min: 0.0, max: 9.0);
        final visible = culler.cull(
          points: points,
          viewportX: viewport,
          viewportY: viewport,
          isXOrdered: true,
        );

        expect(visible.length, equals(10)); // All points
      });
    });

    group('ViewportBounds', () {
      test('contains() returns true for point in bounds', () {
        final culler = const ViewportCuller(margin: 0.0);
        final viewport = const dr.DataRange(min: 0.0, max: 10.0);
        final bounds = culler.calculateBounds(
          viewportX: viewport,
          viewportY: viewport,
        );

        final point = const ChartDataPoint(x: 5.0, y: 5.0);
        expect(bounds.contains(point), isTrue);
      });

      test('contains() returns false for point outside bounds', () {
        final culler = const ViewportCuller(margin: 0.0);
        final viewport = const dr.DataRange(min: 0.0, max: 10.0);
        final bounds = culler.calculateBounds(
          viewportX: viewport,
          viewportY: viewport,
        );

        final point = const ChartDataPoint(x: 15.0, y: 5.0);
        expect(bounds.contains(point), isFalse);
      });

      test('contains() checks both x and y', () {
        final culler = const ViewportCuller(margin: 0.0);
        final viewportX = const dr.DataRange(min: 0.0, max: 10.0);
        final viewportY = const dr.DataRange(min: 0.0, max: 5.0);
        final bounds = culler.calculateBounds(
          viewportX: viewportX,
          viewportY: viewportY,
        );

        expect(bounds.contains(const ChartDataPoint(x: 5.0, y: 3.0)), isTrue);
        expect(bounds.contains(const ChartDataPoint(x: 15.0, y: 3.0)), isFalse);
        expect(bounds.contains(const ChartDataPoint(x: 5.0, y: 10.0)), isFalse);
      });
    });

    group('Edge Cases', () {
      test('handles points with same x values', () {
        final culler = const ViewportCuller(margin: 0.0);
        final points = [
          const ChartDataPoint(x: 5.0, y: 1.0),
          const ChartDataPoint(x: 5.0, y: 2.0),
          const ChartDataPoint(x: 5.0, y: 3.0),
        ];

        final viewport = const dr.DataRange(min: 5.0, max: 5.0);
        final visible = culler.cull(
          points: points,
          viewportX: viewport,
          viewportY: const dr.DataRange(min: 0.0, max: 10.0),
          isXOrdered: true,
        );

        expect(visible.length, equals(3));
      });

      test('handles large datasets efficiently', () {
        final culler = const ViewportCuller(margin: 0.0);
        final points = List.generate(
          10000,
          (i) => ChartDataPoint(x: i.toDouble(), y: i.toDouble()),
        );

        final viewport = const dr.DataRange(min: 4000.0, max: 6000.0);
        final visible = culler.cull(
          points: points,
          viewportX: viewport,
          viewportY: viewport,
          isXOrdered: true,
        );

        expect(visible.length, equals(2001)); // 4000-6000 inclusive
      });
    });
  });

  group('BatchProcessor<T,K> Unit Tests', () {
    group('Constructor', () {
      test('creates processor with key extractor', () {
        final processor = BatchProcessor<String, int>(
          keyExtractor: (s) => s.length,
        );
        expect(processor.batchSize, equals(100)); // Default
      });

      test('accepts custom batch size', () {
        final processor = BatchProcessor<String, int>(
          keyExtractor: (s) => s.length,
          batchSize: 50,
        );
        expect(processor.batchSize, equals(50));
      });
    });

    group('batch()', () {
      test('groups items by key', () {
        final processor = BatchProcessor<String, int>(
          keyExtractor: (s) => s.length,
        );

        final items = ['a', 'bb', 'ccc', 'dd', 'e'];
        final batches = processor.batch(items);

        expect(batches.keys.length, equals(3));
        expect(batches[1], equals(['a', 'e']));
        expect(batches[2], equals(['bb', 'dd']));
        expect(batches[3], equals(['ccc']));
      });

      test('preserves item order within batches', () {
        final processor = BatchProcessor<int, int>(
          keyExtractor: (i) => i % 2, // Even/odd
        );

        final items = [1, 2, 3, 4, 5, 6];
        final batches = processor.batch(items);

        expect(batches[1], equals([1, 3, 5])); // Odd in order
        expect(batches[0], equals([2, 4, 6])); // Even in order
      });

      test('handles empty list', () {
        final processor = BatchProcessor<String, int>(
          keyExtractor: (s) => s.length,
        );

        final batches = processor.batch([]);
        expect(batches.isEmpty, isTrue);
      });

      test('handles single item', () {
        final processor = BatchProcessor<String, int>(
          keyExtractor: (s) => s.length,
        );

        final batches = processor.batch(['test']);
        expect(batches.keys.length, equals(1));
        expect(batches[4], equals(['test']));
      });

      test('handles all items with same key', () {
        final processor = BatchProcessor<String, int>(
          keyExtractor: (s) => 1, // Always return 1
        );

        final items = ['a', 'b', 'c'];
        final batches = processor.batch(items);

        expect(batches.keys.length, equals(1));
        expect(batches[1], equals(['a', 'b', 'c']));
      });

      test('handles all items with different keys', () {
        final processor = BatchProcessor<String, String>(
          keyExtractor: (s) => s, // Each item is its own key
        );

        final items = ['a', 'b', 'c'];
        final batches = processor.batch(items);

        expect(batches.keys.length, equals(3));
        expect(batches['a'], equals(['a']));
        expect(batches['b'], equals(['b']));
        expect(batches['c'], equals(['c']));
      });
    });

    group('processBatches()', () {
      test('calls processor for each batch', () {
        final processor = BatchProcessor<String, int>(
          keyExtractor: (s) => s.length,
        );

        final processed = <int, List<String>>{};
        processor.processBatches(
          ['a', 'bb', 'ccc'],
          (key, batch) => processed[key] = batch,
        );

        expect(processed.keys.length, equals(3));
        expect(processed[1], equals(['a']));
        expect(processed[2], equals(['bb']));
        expect(processed[3], equals(['ccc']));
      });

      test('handles empty list', () {
        final processor = BatchProcessor<String, int>(
          keyExtractor: (s) => s.length,
        );

        int callCount = 0;
        processor.processBatches(
          [],
          (key, batch) => callCount++,
        );

        expect(callCount, equals(0));
      });

      test('passes correct batches to callback', () {
        final processor = BatchProcessor<int, int>(
          keyExtractor: (i) => i % 2,
        );

        final results = <int, List<int>>{};
        processor.processBatches(
          [1, 2, 3, 4, 5],
          (key, batch) => results[key] = batch,
        );

        expect(results[1], equals([1, 3, 5]));
        expect(results[0], equals([2, 4]));
      });
    });

    group('Generic Types', () {
      test('works with int key and String items', () {
        final processor = BatchProcessor<String, int>(
          keyExtractor: (s) => s.length,
        );

        final batches = processor.batch(['a', 'bb']);
        expect(batches, isA<Map<int, List<String>>>());
      });

      test('works with String key and int items', () {
        final processor = BatchProcessor<int, String>(
          keyExtractor: (i) => i.isEven ? 'even' : 'odd',
        );

        final batches = processor.batch([1, 2, 3]);
        expect(batches, isA<Map<String, List<int>>>());
        expect(batches['odd'], equals([1, 3]));
        expect(batches['even'], equals([2]));
      });

      test('works with custom class keys', () {
        final processor = BatchProcessor<ChartDataPoint, bool>(
          keyExtractor: (p) => p.x > 5.0,
        );

        final points = [
          const ChartDataPoint(x: 1.0, y: 1.0),
          const ChartDataPoint(x: 10.0, y: 10.0),
        ];
        final batches = processor.batch(points);

        expect(batches[false]?.length, equals(1));
        expect(batches[true]?.length, equals(1));
      });
    });

    group('Use Cases', () {
      test('groups by color for rendering', () {
        final processor = BatchProcessor<Map<String, dynamic>, String>(
          keyExtractor: (item) => item['color'] as String,
        );

        final items = [
          {'color': 'red', 'data': 1},
          {'color': 'blue', 'data': 2},
          {'color': 'red', 'data': 3},
        ];

        final batches = processor.batch(items);
        expect(batches['red']?.length, equals(2));
        expect(batches['blue']?.length, equals(1));
      });

      test('groups by style for rendering', () {
        final processor = BatchProcessor<ChartDataPoint, String>(
          keyExtractor: (p) => p.metadata?['style'] as String? ?? 'default',
        );

        final points = [
          const ChartDataPoint(x: 1.0, y: 1.0, metadata: {'style': 'solid'}),
          const ChartDataPoint(x: 2.0, y: 2.0, metadata: {'style': 'dashed'}),
          const ChartDataPoint(x: 3.0, y: 3.0, metadata: {'style': 'solid'}),
        ];

        final batches = processor.batch(points);
        expect(batches['solid']?.length, equals(2));
        expect(batches['dashed']?.length, equals(1));
      });
    });

    group('Edge Cases', () {
      test('handles large batch sizes', () {
        final processor = BatchProcessor<int, int>(
          keyExtractor: (i) => i % 10,
          batchSize: 10000,
        );

        expect(processor.batchSize, equals(10000));
      });

      test('handles many unique keys', () {
        final processor = BatchProcessor<int, int>(
          keyExtractor: (i) => i,
        );

        final items = List.generate(1000, (i) => i);
        final batches = processor.batch(items);

        expect(batches.keys.length, equals(1000));
      });

      test('handles null keys', () {
        final processor = BatchProcessor<String, String?>(
          keyExtractor: (s) => s.isEmpty ? null : s,
        );

        final items = ['', 'a', '', 'b'];
        final batches = processor.batch(items);

        expect(batches[null], equals(['', '']));
        expect(batches['a'], equals(['a']));
        expect(batches['b'], equals(['b']));
      });
    });
  });
}
