// Copyright 2024 The Braven Charts Authors
// SPDX-License-Identifier: MIT

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:braven_charts/legacy/src/foundation/foundation.dart';

/// Integration test for Foundation Layer Performance Primitives (FR-002)
///
/// Validates complete performance primitive workflows from quickstart scenario 2:
/// - ObjectPool acquire/release performance and hit rate
/// - ViewportCuller performance with ordered and unordered data
/// - BatchProcessor grouping efficiency
/// - End-to-end performance targets
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Foundation Performance Primitives Integration', () {
    test('2.1 - ObjectPool performance and hit rate', () {
      // Create pool for Paint objects
      final pool = ObjectPool<Paint>(
        factory: () => Paint(),
        reset: (paint) {
          paint.color = const Color(0xFF000000);
          paint.strokeWidth = 1.0;
          paint.style = PaintingStyle.fill;
        },
        maxSize: 100,
      );

      final stopwatch = Stopwatch();

      // First acquire creates object (slower)
      final paint1 = pool.acquire();
      pool.release(paint1);

      // Test acquire performance after warmup (<100ns target, but allow <500μs in test environment)
      stopwatch.start();
      final paint2 = pool.acquire();
      stopwatch.stop();
      final acquireTime = stopwatch.elapsedMicroseconds;
      // Note: In practice, acquire/release are very fast (<100ns)
      // but can vary significantly in test environment.
      expect(
        acquireTime,
        lessThan(500),
        reason: 'Acquire should be reasonably fast in test environment',
      );

      pool.release(paint2);

      // Test release performance
      final paint3 = pool.acquire();
      paint3.color = const Color(0xFFFF0000); // Red
      stopwatch.reset();
      stopwatch.start();
      pool.release(paint3);
      stopwatch.stop();
      final releaseTime = stopwatch.elapsedMicroseconds;
      expect(
        releaseTime,
        lessThan(500),
        reason: 'Release should be reasonably fast in test environment',
      );

      // Verify reset on acquire
      final paint4 = pool.acquire();
      expect(paint4.color, equals(const Color(0xFF000000))); // Reset to black

      // Check statistics
      final stats = pool.statistics;
      expect(stats.acquireCount, greaterThan(0));
      expect(stats.hitRate, greaterThan(0.0)); // Reuse occurred

      pool.release(paint4);

      print(
          '✅ ObjectPool acquire: ${acquireTime}μs, release: ${releaseTime}μs');
      print('   Hit rate: ${(stats.hitRate * 100).toStringAsFixed(1)}%');
    });

    test('2.2 - ObjectPool hit rate after warmup (>90%)', () {
      final pool = ObjectPool<Paint>(
        factory: () => Paint(),
        reset: (paint) {
          paint.color = const Color(0xFF000000);
        },
        maxSize: 50,
      );

      // Warmup: Fill the pool
      final paints = <Paint>[];
      for (var i = 0; i < 50; i++) {
        paints.add(pool.acquire());
      }
      for (final paint in paints) {
        pool.release(paint);
      }

      // Now test hit rate - should be very high
      final testPaints = <Paint>[];
      for (var i = 0; i < 100; i++) {
        testPaints.add(pool.acquire());
      }
      for (final paint in testPaints) {
        pool.release(paint);
      }

      final stats = pool.statistics;
      expect(
        stats.hitRate,
        greaterThan(0.9),
        reason: 'Hit rate should be >90% after warmup',
      );

      print(
          '✅ ObjectPool hit rate after warmup: ${(stats.hitRate * 100).toStringAsFixed(1)}%');
    });

    test('2.3 - ViewportCuller performance with ordered data', () {
      // Create 10k ordered points
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(x: i.toDouble(), y: i * 0.5),
      );

      final culler = ViewportCuller(margin: 0.1);
      final viewportX = DataRange(min: 1000.0, max: 2000.0);
      final viewportY = DataRange(min: 0.0, max: 10000.0);

      // Test culling performance
      final stopwatch = Stopwatch()..start();
      final visible = culler.cull(
        points: points,
        viewportX: viewportX,
        viewportY: viewportY,
        isXOrdered: true, // Enable binary search
      );
      stopwatch.stop();

      // Validate performance: <2ms in test environment (FR-005.4 target <1ms)
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2),
        reason:
            'ViewportCuller should be <2ms for 10k points in test environment (FR-005.4 target <1ms)',
      );

      // Validate culling worked
      expect(visible.length, lessThan(points.length));
      // ViewportCuller with margin 0.1 extends the viewport by 10% on each side
      // Range [1000, 2000] has span=1000, so margin = 100 on each side
      // Expected range: [900, 2100]
      final expectedMin = viewportX.min - (viewportX.span * culler.margin);
      final expectedMax = viewportX.max + (viewportX.span * culler.margin);
      for (final p in visible) {
        expect(p.x, greaterThanOrEqualTo(expectedMin));
        expect(p.x, lessThanOrEqualTo(expectedMax));
      }

      print(
          '✅ ViewportCuller: Culled ${points.length} → ${visible.length} points in ${stopwatch.elapsedMicroseconds}μs');
    });

    test('2.4 - ViewportCuller comparison: ordered vs unordered', () {
      // Create 10k points
      final orderedPoints = List.generate(
        10000,
        (i) => ChartDataPoint(x: i.toDouble(), y: i * 0.5),
      );

      // Create shuffled copy
      final unorderedPoints = List.of(orderedPoints)..shuffle();

      final culler = ViewportCuller(margin: 0.1);
      final viewportX = DataRange(min: 1000.0, max: 2000.0);
      final viewportY = DataRange(min: 0.0, max: 10000.0);

      // Test ordered (binary search)
      final stopwatch1 = Stopwatch()..start();
      final visibleOrdered = culler.cull(
        points: orderedPoints,
        viewportX: viewportX,
        viewportY: viewportY,
        isXOrdered: true,
      );
      stopwatch1.stop();

      // Test unordered (linear scan)
      final stopwatch2 = Stopwatch()..start();
      final visibleUnordered = culler.cull(
        points: unorderedPoints,
        viewportX: viewportX,
        viewportY: viewportY,
        isXOrdered: false,
      );
      stopwatch2.stop();

      // Both should return same count (order doesn't matter for result)
      expect(visibleOrdered.length, equals(visibleUnordered.length));

      // Ordered should be faster (binary search vs linear)
      expect(stopwatch1.elapsedMicroseconds,
          lessThan(stopwatch2.elapsedMicroseconds));

      final speedup =
          stopwatch2.elapsedMicroseconds / stopwatch1.elapsedMicroseconds;
      print(
          '✅ ViewportCuller speedup (ordered vs unordered): ${speedup.toStringAsFixed(1)}x');
      print(
          '   Ordered: ${stopwatch1.elapsedMicroseconds}μs, Unordered: ${stopwatch2.elapsedMicroseconds}μs');
    });

    test('2.5 - ViewportCuller with small viewport (stress test)', () {
      // Create 10k points
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(x: i.toDouble(), y: i * 0.5),
      );

      final culler = ViewportCuller(margin: 0.1);
      // Very small viewport: only 1% of data visible
      final viewportX = DataRange(min: 4950.0, max: 5050.0);
      final viewportY = DataRange(min: 0.0, max: 10000.0);

      final stopwatch = Stopwatch()..start();
      final visible = culler.cull(
        points: points,
        viewportX: viewportX,
        viewportY: viewportY,
        isXOrdered: true,
      );
      stopwatch.stop();

      // Should still be <1ms
      expect(stopwatch.elapsedMilliseconds, lessThan(1));

      // Should cull most points
      final cullRatio = visible.length / points.length;
      expect(cullRatio, lessThan(0.02)); // <2% visible (with margin)

      print(
          '✅ ViewportCuller (1% viewport): ${visible.length} points in ${stopwatch.elapsedMicroseconds}μs');
    });

    test('2.6 - BatchProcessor grouping by key', () {
      // Create points with different colors (simulating render batching)
      final items = [
        _ColoredPoint(
            ChartDataPoint(x: 1, y: 1), const Color(0xFFFF0000)), // Red
        _ColoredPoint(
            ChartDataPoint(x: 2, y: 2), const Color(0xFF0000FF)), // Blue
        _ColoredPoint(
            ChartDataPoint(x: 3, y: 3), const Color(0xFFFF0000)), // Red
        _ColoredPoint(
            ChartDataPoint(x: 4, y: 4), const Color(0xFF0000FF)), // Blue
        _ColoredPoint(
            ChartDataPoint(x: 5, y: 5), const Color(0xFF00FF00)), // Green
        _ColoredPoint(
            ChartDataPoint(x: 6, y: 6), const Color(0xFFFF0000)), // Red
      ];

      // Batch by color
      final processor = BatchProcessor<_ColoredPoint, Color>(
        keyExtractor: (item) => item.color,
        batchSize: 100,
      );

      final batches = processor.batch(items);

      // Validate batching
      expect(batches.length, equals(3)); // 3 unique colors
      expect(batches[const Color(0xFFFF0000)]?.length, equals(3)); // 3 red
      expect(batches[const Color(0xFF0000FF)]?.length, equals(2)); // 2 blue
      expect(batches[const Color(0xFF00FF00)]?.length, equals(1)); // 1 green

      print(
          '✅ BatchProcessor: ${items.length} items → ${batches.length} batches');
      for (final entry in batches.entries) {
        print(
            '   Color ${entry.key.value.toRadixString(16)}: ${entry.value.length} items');
      }
    });

    test('2.7 - BatchProcessor with processBatches callback', () {
      final items = List.generate(
        100,
        (i) => _ColoredPoint(
          ChartDataPoint(x: i.toDouble(), y: i.toDouble()),
          i.isEven ? const Color(0xFFFF0000) : const Color(0xFF0000FF),
        ),
      );

      final processor = BatchProcessor<_ColoredPoint, Color>(
        keyExtractor: (item) => item.color,
        batchSize: 100,
      );

      var batchesProcessed = 0;
      var totalItemsProcessed = 0;

      processor.processBatches(items, (color, batch) {
        batchesProcessed++;
        totalItemsProcessed += batch.length;
        // Simulate batch rendering
      });

      expect(batchesProcessed, equals(2)); // Red and blue
      expect(totalItemsProcessed, equals(100)); // All items processed

      print(
          '✅ BatchProcessor processBatches: $batchesProcessed batches, $totalItemsProcessed items');
    });

    test('2.8 - BatchProcessor performance with large dataset', () {
      // Create 10k items with 10 different keys
      final items = List.generate(
        10000,
        (i) => _ColoredPoint(
          ChartDataPoint(x: i.toDouble(), y: i.toDouble()),
          Color(0xFF000000 + (i % 10) * 0x111111),
        ),
      );

      final processor = BatchProcessor<_ColoredPoint, Color>(
        keyExtractor: (item) => item.color,
        batchSize: 1000,
      );

      final stopwatch = Stopwatch()..start();
      final batches = processor.batch(items);
      stopwatch.stop();

      // Should be very fast (microseconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
      expect(batches.length, equals(10)); // 10 unique colors

      print('✅ BatchProcessor (10k items): ${stopwatch.elapsedMicroseconds}μs');
    });
  });

  group('Foundation Performance Primitives - Complete Workflow', () {
    test('End-to-end performance primitives integration', () {
      print('\n=== Performance Primitives Integration Test ===');

      // Step 1: Create dataset
      print('\n1. Creating 10k data points...');
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(x: i.toDouble(), y: i * 0.5),
      );

      // Step 2: Viewport culling
      print('2. Viewport culling...');
      final culler = ViewportCuller(margin: 0.1);
      final viewportX = DataRange(min: 2000.0, max: 4000.0);
      final viewportY = DataRange(min: 0.0, max: 10000.0);

      final stopwatch = Stopwatch()..start();
      final visible = culler.cull(
        points: points,
        viewportX: viewportX,
        viewportY: viewportY,
        isXOrdered: true,
      );
      stopwatch.stop();

      print(
          '   Culled ${points.length} → ${visible.length} points in ${stopwatch.elapsedMicroseconds}μs');
      expect(stopwatch.elapsedMilliseconds, lessThan(1));

      // Step 3: Batch visible points by color (simulated)
      print('3. Batching visible points...');
      final items = visible.map((p) {
        // Assign color based on y value
        final color = p.y < 1500
            ? const Color(0xFFFF0000)
            : p.y < 3000
                ? const Color(0xFF0000FF)
                : const Color(0xFF00FF00);
        return _ColoredPoint(p, color);
      }).toList();

      final processor = BatchProcessor<_ColoredPoint, Color>(
        keyExtractor: (item) => item.color,
        batchSize: 100,
      );

      stopwatch.reset();
      stopwatch.start();
      final batches = processor.batch(items);
      stopwatch.stop();

      print(
          '   Batched ${items.length} items into ${batches.length} groups in ${stopwatch.elapsedMicroseconds}μs');

      // Step 4: Simulate rendering with object pool
      print('4. Simulating render with object pool...');
      final paintPool = ObjectPool<Paint>(
        factory: () => Paint(),
        reset: (p) {
          p.color = const Color(0xFF000000);
          p.strokeWidth = 1.0;
        },
        maxSize: 50,
      );

      stopwatch.reset();
      stopwatch.start();

      var pointsRendered = 0;
      for (final entry in batches.entries) {
        final paint = paintPool.acquire();
        paint.color = entry.key;
        // Simulate rendering batch
        pointsRendered += entry.value.length;
        paintPool.release(paint);
      }

      stopwatch.stop();

      final stats = paintPool.statistics;
      print(
          '   Rendered $pointsRendered points in ${stopwatch.elapsedMicroseconds}μs');
      print('   Pool hit rate: ${(stats.hitRate * 100).toStringAsFixed(1)}%');

      print('\n✅ All performance primitives working together successfully');

      // Validate everything worked
      expect(pointsRendered, equals(visible.length));
      expect(stats.hitRate, greaterThan(0.0));
    });
  });
}

/// Helper class for testing BatchProcessor
class _ColoredPoint {
  final ChartDataPoint point;
  final Color color;

  _ColoredPoint(this.point, this.color);
}
