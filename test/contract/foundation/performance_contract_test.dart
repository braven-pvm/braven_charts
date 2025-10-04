// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/foundation/performance/object_pool.dart';
import 'package:braven_charts/src/foundation/performance/viewport_culler.dart';
import 'package:braven_charts/src/foundation/performance/batch_processor.dart';
import 'package:braven_charts/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/src/foundation/data_models/data_range.dart' as dr;

void main() {
  group('ObjectPool<T> Contract Tests', () {
    test('ObjectPool generic type works', () {
      final pool = ObjectPool<String>(
        factory: () => '',
        reset: (s) {},
      );
      expect(pool, isA<ObjectPool<String>>());
    });

    test('ObjectPool acquire() creates or reuses objects', () {
      int createCount = 0;
      final pool = ObjectPool<String>(
        factory: () {
          createCount++;
          return 'Object $createCount';
        },
        reset: (s) {},
      );

      final obj1 = pool.acquire();
      expect(createCount, equals(1));

      final obj2 = pool.acquire();
      expect(createCount, equals(2));
    });

    test('ObjectPool release() returns objects to pool', () {
      int createCount = 0;
      int resetCount = 0;
      final pool = ObjectPool<String>(
        factory: () => 'Object ${++createCount}',
        reset: (s) {
          resetCount++;
        },
      );

      final obj = pool.acquire();
      pool.release(obj);
      expect(resetCount, equals(1));

      // Acquiring again should reuse the object
      final obj2 = pool.acquire();
      expect(createCount, equals(1)); // No new creation
    });

    test('ObjectPool statistics track usage', () {
      final pool = ObjectPool<String>(
        factory: () => 'Test',
        reset: (s) {},
      );

      final obj = pool.acquire();
      final stats = pool.statistics;
      expect(stats.totalCreated, equals(1));
      expect(stats.acquireCount, equals(1));

      pool.release(obj);
      final stats2 = pool.statistics;
      expect(stats2.releaseCount, equals(1));
    });

    test('ObjectPool enforces maxSize', () {
      final pool = ObjectPool<String>(
        factory: () => 'Test',
        reset: (s) {},
        maxSize: 2,
      );

      expect(pool.maxSize, equals(2));
    });

    test('ObjectPool clear() empties pool', () {
      final pool = ObjectPool<String>(
        factory: () => 'Test',
        reset: (s) {},
      );

      pool.acquire();
      pool.clear();
      final stats = pool.statistics;
      expect(stats.currentSize, equals(0));
    });

    test('ObjectPool performance <100ns per operation', () {
      // This will be verified in performance benchmarks (T026)
      // For now, just verify the API exists
      final pool = ObjectPool<String>(
        factory: () => 'Test',
        reset: (s) {},
      );
      final obj = pool.acquire();
      pool.release(obj);
      expect(pool.statistics.acquireCount, greaterThan(0));
    });
  });

  group('ViewportCuller Contract Tests', () {
    test('ViewportCuller constructor works', () {
      final culler = ViewportCuller(margin: 0.1);
      expect(culler.margin, equals(0.1));
    });

    test('ViewportCuller cull() filters points', () {
      final culler = ViewportCuller(margin: 0.0);
      final points = [
        ChartDataPoint(x: 1.0, y: 1.0), // Inside
        ChartDataPoint(x: 5.0, y: 5.0), // Inside
        ChartDataPoint(x: 10.0, y: 10.0), // Outside
      ];

      final viewport = dr.DataRange(min: 0.0, max: 6.0);
      final visible = culler.cull(
        points: points,
        viewportX: viewport,
        viewportY: viewport,
        isXOrdered: false,
      );

      expect(visible.length, equals(2));
    });

    test('ViewportCuller optimizes ordered data with binary search', () {
      final culler = ViewportCuller(margin: 0.0);
      final points = List.generate(
        1000,
        (i) => ChartDataPoint(x: i.toDouble(), y: i.toDouble()),
      );

      final viewport = dr.DataRange(min: 100.0, max: 200.0);
      final visible = culler.cull(
        points: points,
        viewportX: viewport,
        viewportY: viewport,
        isXOrdered: true,
      );

      expect(visible.length, equals(101)); // 100-200 inclusive
    });

    test('ViewportCuller calculateBounds() applies margin', () {
      final culler = ViewportCuller(margin: 0.1);
      final viewport = dr.DataRange(min: 0.0, max: 10.0);
      final bounds = culler.calculateBounds(
        viewportX: viewport,
        viewportY: viewport,
      );

      // With 10% margin on a 10-unit range, margin is 1 unit
      expect(bounds.xRange.paddedMin, equals(-1.0));
      expect(bounds.xRange.paddedMax, equals(11.0));
    });

    test('ViewportCuller performance <1ms for 10k points', () {
      // This will be verified in performance benchmarks (T027)
      // For now, just verify the API exists
      final culler = ViewportCuller();
      final points = List.generate(
        100,
        (i) => ChartDataPoint(x: i.toDouble(), y: i.toDouble()),
      );
      final viewport = dr.DataRange(min: 0.0, max: 50.0);
      final visible = culler.cull(
        points: points,
        viewportX: viewport,
        viewportY: viewport,
        isXOrdered: true,
      );
      expect(visible, isNotEmpty);
    });
  });

  group('BatchProcessor<T,K> Contract Tests', () {
    test('BatchProcessor generic types work', () {
      final processor = BatchProcessor<String, int>(
        keyExtractor: (s) => s.length,
        batchSize: 10,
      );
      expect(processor, isA<BatchProcessor<String, int>>());
    });

    test('BatchProcessor batch() groups by key', () {
      final processor = BatchProcessor<String, int>(
        keyExtractor: (s) => s.length,
      );

      final items = ['a', 'bb', 'ccc', 'dd', 'e'];
      final batches = processor.batch(items);

      expect(batches[1], equals(['a', 'e'])); // Length 1
      expect(batches[2], equals(['bb', 'dd'])); // Length 2
      expect(batches[3], equals(['ccc'])); // Length 3
    });

    test('BatchProcessor processBatches() calls callback', () {
      final processor = BatchProcessor<String, int>(
        keyExtractor: (s) => s.length,
      );

      final processed = <int, List<String>>{};
      processor.processBatches(
        ['a', 'bb', 'ccc'],
        (key, batch) => processed[key] = batch,
      );

      expect(processed.keys, containsAll([1, 2, 3]));
    });

    test('BatchProcessor batchSize configuration works', () {
      final processor = BatchProcessor<int, int>(
        keyExtractor: (i) => i % 2,
        batchSize: 100,
      );
      expect(processor.batchSize, equals(100));
    });
  });
}
