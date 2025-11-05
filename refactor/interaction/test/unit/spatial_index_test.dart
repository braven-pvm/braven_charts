// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture Tests

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:interaction_prototype/core/chart_element.dart';
import 'package:interaction_prototype/elements/simulated_datapoint.dart';
import 'package:interaction_prototype/rendering/spatial_index.dart';

void main() {
  group('QuadTree', () {
    late QuadTree tree;

    setUp(() {
      // Create tree covering 800x600 space
      tree = QuadTree(
        bounds: const Rect.fromLTWH(0, 0, 800, 600),
        maxElementsPerNode: 4,
      );
    });

    group('Insert Operations', () {
      test('should insert single element', () {
        final element = SimulatedDatapoint(
          id: 'point1',
          center: const Offset(100, 100),
        );

        final result = tree.insert(element);

        expect(result, isTrue);
        expect(tree.elementCount, equals(1));
      });

      test('should insert multiple elements', () {
        final elements = List.generate(
          10,
          (i) => SimulatedDatapoint(
            id: 'point$i',
            center: Offset(i * 50.0, i * 40.0),
          ),
        );

        for (final element in elements) {
          tree.insert(element);
        }

        expect(tree.elementCount, equals(10));
      });

      test('should reject elements outside bounds', () {
        final element = SimulatedDatapoint(
          id: 'outside',
          center: const Offset(1000, 1000), // Outside 800x600
        );

        final result = tree.insert(element);

        expect(result, isFalse);
        expect(tree.elementCount, equals(0));
      });

      test('should split when capacity exceeded', () {
        // Insert 5 elements (capacity is 4) in same region
        final elements = List.generate(
          5,
          (i) => SimulatedDatapoint(
            id: 'point$i',
            center: Offset(100 + i * 10.0, 100 + i * 10.0),
          ),
        );

        for (final element in elements) {
          tree.insert(element);
        }

        // Tree should have split
        expect(tree.isSplit, isTrue);
        expect(tree.elementCount, equals(5));
      });
    });

    group('Query Operations', () {
      late List<ChartElement> testElements;

      setUp(() {
        // Create a grid of test elements
        testElements = [
          SimulatedDatapoint(id: '1', center: const Offset(100, 100)),
          SimulatedDatapoint(id: '2', center: const Offset(200, 100)),
          SimulatedDatapoint(id: '3', center: const Offset(300, 100)),
          SimulatedDatapoint(id: '4', center: const Offset(100, 200)),
          SimulatedDatapoint(id: '5', center: const Offset(200, 200)),
          SimulatedDatapoint(id: '6', center: const Offset(300, 200)),
        ];

        for (final element in testElements) {
          tree.insert(element);
        }
      });

      test('should query elements at point', () {
        final results = tree.query(const Offset(100, 100), radius: 20);

        expect(results.length, equals(1));
        expect(results.first.id, equals('1'));
      });

      test('should query elements in rectangular region', () {
        const rect = Rect.fromLTWH(90, 90, 120, 120);
        final results = tree.queryRect(rect);

        // Should find elements 1, 2, 4, 5 (top-left 2x2 grid)
        expect(results.length, equals(4));
        final ids = results.map((e) => e.id).toSet();
        expect(ids, containsAll(['1', '2', '4', '5']));
      });

      test('should find nearest element', () {
        // Query near point 5 (200, 200)
        final result = tree.queryNearest(const Offset(205, 205));

        expect(result, isNotNull);
        expect(result!.element.id, equals('5'));
        expect(result.distance, lessThan(10.0));
      });

      test('should respect maxDistance in nearest query', () {
        // Query far from any point with small maxDistance
        final result = tree.queryNearest(
          const Offset(400, 400),
          maxDistance: 10.0,
        );

        expect(result, isNull);
      });

      test('should find nearby elements', () {
        // Per conflict resolution scenario 4: find elements within 3px
        final results = tree.queryNearby(
          const Offset(105, 105),
          maxDistance: 20.0,
        );

        expect(results.isNotEmpty, isTrue);
        expect(results.first.element.id, equals('1'));

        // Results should be sorted by distance
        for (int i = 0; i < results.length - 1; i++) {
          expect(
            results[i].distance,
            lessThanOrEqualTo(results[i + 1].distance),
          );
        }
      });

      test('should return empty list for query outside tree', () {
        final results = tree.query(const Offset(900, 700), radius: 10);

        expect(results, isEmpty);
      });
    });

    group('Remove Operations', () {
      late SimulatedDatapoint element1;
      late SimulatedDatapoint element2;

      setUp(() {
        element1 = SimulatedDatapoint(id: '1', center: const Offset(100, 100));
        element2 = SimulatedDatapoint(id: '2', center: const Offset(200, 200));

        tree.insert(element1);
        tree.insert(element2);
      });

      test('should remove existing element', () {
        final result = tree.remove(element1);

        expect(result, isTrue);
        expect(tree.elementCount, equals(1));

        final remaining = tree.query(const Offset(100, 100), radius: 20);
        expect(remaining, isEmpty);
      });

      test('should return false for non-existent element', () {
        final otherElement = SimulatedDatapoint(
          id: '999',
          center: const Offset(500, 500),
        );

        final result = tree.remove(otherElement);

        expect(result, isFalse);
        expect(tree.elementCount, equals(2));
      });

      test('should handle removing all elements', () {
        tree.remove(element1);
        tree.remove(element2);

        expect(tree.elementCount, equals(0));
      });
    });

    group('Clear and Stats', () {
      test('should clear all elements', () {
        for (int i = 0; i < 10; i++) {
          tree.insert(SimulatedDatapoint(
            id: 'point$i',
            center: Offset(i * 50.0, i * 40.0),
          ));
        }

        tree.clear();

        expect(tree.elementCount, equals(0));
        expect(tree.isSplit, isFalse);
      });

      test('should provide accurate stats', () {
        // Insert enough elements to cause splits
        for (int i = 0; i < 20; i++) {
          tree.insert(SimulatedDatapoint(
            id: 'point$i',
            center: Offset(i * 30.0, i * 25.0),
          ));
        }

        final stats = tree.stats;

        expect(stats.elementCount, equals(20));
        expect(stats.nodeCount, greaterThan(1)); // Should have split
        expect(stats.maxDepth, greaterThan(0));
      });
    });

    group('Performance', () {
      test('should handle 100+ elements efficiently', () {
        // Per design requirement: handle 100+ elements
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 150; i++) {
          final x = (i % 20) * 40.0;
          final y = (i ~/ 20) * 40.0;
          tree.insert(SimulatedDatapoint(
            id: 'point$i',
            center: Offset(x, y),
          ));
        }

        stopwatch.stop();

        expect(tree.elementCount, equals(150));
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be fast

        // Test query performance
        stopwatch.reset();
        stopwatch.start();

        for (int i = 0; i < 100; i++) {
          tree.query(Offset(i * 5.0, i * 3.0), radius: 20);
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(50)); // O(log n) queries
      });
    });

    group('Conflict Resolution Scenarios', () {
      test('scenario 4: multiple overlapping datapoints', () {
        // Per scenario 4: find nearest when multiple points close together
        final points = [
          SimulatedDatapoint(id: 'A', center: const Offset(100, 100)),
          SimulatedDatapoint(id: 'B', center: const Offset(103, 102)), // 3px away
          SimulatedDatapoint(id: 'C', center: const Offset(105, 101)), // 5px away
        ];

        for (final point in points) {
          tree.insert(point);
        }

        // Find nearest to click position
        final result = tree.queryNearest(const Offset(101, 101));
        expect(result, isNotNull);
        expect(result!.element.id, equals('A')); // Nearest

        // Find all within ambiguous range (3px per conflict resolution)
        final nearby = tree.queryNearby(const Offset(101, 101), maxDistance: 3.0);
        expect(nearby.length, greaterThanOrEqualTo(2)); // A and B within 3px
      });
    });
  });
}
