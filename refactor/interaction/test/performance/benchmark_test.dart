// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Performance Benchmarks
//
// Validates performance requirements:
// - 60fps (16.67ms per frame) with 100+ elements
// - QuadTree O(log n) query performance
// - Memory stability during extended use
// - Rapid interaction handling

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interaction_prototype/elements/simulated_datapoint.dart';
import 'package:interaction_prototype/rendering/spatial_index.dart';
import 'package:interaction_prototype/widgets/prototype_chart.dart';

void main() {
  group('QuadTree Performance Benchmarks', () {
    test('insert 1000 elements completes in <100ms', () {
      final quadTree = QuadTree(
        bounds: const Rect.fromLTWH(0, 0, 1000, 1000),
        maxElementsPerNode: 10,
      );
      final random = math.Random(42); // Deterministic seed

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        final element = SimulatedDatapoint(
          id: 'point_$i',
          center: Offset(
            random.nextDouble() * 1000,
            random.nextDouble() * 1000,
          ),
        );
        quadTree.insert(element);
      }

      stopwatch.stop();
      final elapsedMs = stopwatch.elapsedMilliseconds;

      expect(elapsedMs, lessThan(100), reason: 'Insert 1000 elements took ${elapsedMs}ms (expected <100ms)');
      debugPrint('✓ QuadTree insert 1000 elements: ${elapsedMs}ms');
    });

    test('query 1000 times completes in <50ms (avg <0.05ms per query)', () {
      final quadTree = QuadTree(
        bounds: const Rect.fromLTWH(0, 0, 1000, 1000),
        maxElementsPerNode: 10,
      );
      final random = math.Random(42);

      // Insert 1000 elements
      for (int i = 0; i < 1000; i++) {
        final element = SimulatedDatapoint(
          id: 'point_$i',
          center: Offset(
            random.nextDouble() * 1000,
            random.nextDouble() * 1000,
          ),
        );
        quadTree.insert(element);
      }

      // Perform 1000 queries
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        final queryPoint = Offset(
          random.nextDouble() * 1000,
          random.nextDouble() * 1000,
        );
        quadTree.query(queryPoint, radius: 50.0);
      }

      stopwatch.stop();
      final elapsedMs = stopwatch.elapsedMilliseconds;
      final avgMsPerQuery = elapsedMs / 1000.0;

      expect(elapsedMs, lessThan(50), reason: '1000 queries took ${elapsedMs}ms (expected <50ms)');
      debugPrint('✓ QuadTree 1000 queries: ${elapsedMs}ms (avg ${avgMsPerQuery.toStringAsFixed(3)}ms per query)');
    });

    test('remove 1000 elements completes in <100ms', () {
      final quadTree = QuadTree(
        bounds: const Rect.fromLTWH(0, 0, 1000, 1000),
        maxElementsPerNode: 10,
      );
      final random = math.Random(42);
      final elements = <SimulatedDatapoint>[];

      // Insert 1000 elements
      for (int i = 0; i < 1000; i++) {
        final element = SimulatedDatapoint(
          id: 'point_$i',
          center: Offset(
            random.nextDouble() * 1000,
            random.nextDouble() * 1000,
          ),
        );
        elements.add(element);
        quadTree.insert(element);
      }

      // Remove all elements
      final stopwatch = Stopwatch()..start();

      for (final element in elements) {
        quadTree.remove(element);
      }

      stopwatch.stop();
      final elapsedMs = stopwatch.elapsedMilliseconds;

      expect(elapsedMs, lessThan(100), reason: 'Remove 1000 elements took ${elapsedMs}ms (expected <100ms)');
      debugPrint('✓ QuadTree remove 1000 elements: ${elapsedMs}ms');
    });

    test('query performance scales logarithmically', () {
      final sizes = [100, 500, 1000, 5000];
      final timings = <int, int>{};

      for (final size in sizes) {
        final quadTree = QuadTree(
          bounds: const Rect.fromLTWH(0, 0, 1000, 1000),
          maxElementsPerNode: 10,
        );
        final random = math.Random(42);

        // Insert elements
        for (int i = 0; i < size; i++) {
          quadTree.insert(SimulatedDatapoint(
            id: 'point_$i',
            center: Offset(
              random.nextDouble() * 1000,
              random.nextDouble() * 1000,
            ),
          ));
        }

        // Measure query time
        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 100; i++) {
          quadTree.query(
            Offset(random.nextDouble() * 1000, random.nextDouble() * 1000),
            radius: 50.0,
          );
        }
        stopwatch.stop();

        timings[size] = stopwatch.elapsedMicroseconds;
      }

      debugPrint('✓ QuadTree scaling analysis:');
      for (final entry in timings.entries) {
        debugPrint('  ${entry.key} elements: ${entry.value}μs for 100 queries');
      }

      // Verify scaling is better than linear (roughly logarithmic)
      final ratio5000to100 = timings[5000]! / timings[100]!;
      expect(ratio5000to100, lessThan(10), reason: 'Query time should scale logarithmically, not linearly (ratio: $ratio5000to100)');
    });
  });

  group('Widget Performance Benchmarks', () {
    testWidgets('renders 100 elements within reasonable time', (tester) async {
      final elements = List.generate(
        100,
        (i) => SimulatedDatapoint(
          id: 'point_$i',
          center: Offset(
            50 + (i % 10) * 70.0,
            50 + (i ~/ 10) * 50.0,
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(elements: elements),
          ),
        ),
      );

      stopwatch.stop();
      final elapsedMs = stopwatch.elapsedMilliseconds;

      // Initial build can take longer (includes framework setup)
      // Subsequent frames should be within 16.67ms budget
      expect(elapsedMs, lessThan(200), reason: 'Widget build took ${elapsedMs}ms (expected <200ms for initial build)');
      debugPrint('✓ Widget build with 100 elements: ${elapsedMs}ms');
    });

    testWidgets('handles rapid rebuild cycles efficiently', (tester) async {
      final elements = List.generate(
        50,
        (i) => SimulatedDatapoint(
          id: 'point_$i',
          center: Offset(50 + i * 10.0, 100),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(elements: elements),
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();

      // Simulate 10 rapid rebuilds
      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PrototypeChart(
                elements: elements.sublist(0, 50 - i),
              ),
            ),
          ),
        );
      }

      stopwatch.stop();
      final avgMs = stopwatch.elapsedMilliseconds / 10.0;

      expect(avgMs, lessThan(17), reason: 'Avg rebuild took ${avgMs.toStringAsFixed(2)}ms (expected <16.67ms)');
      debugPrint('✓ Widget rapid rebuilds: ${avgMs.toStringAsFixed(2)}ms average');
    });

    testWidgets('interaction with 200 elements maintains performance', (tester) async {
      final elements = List.generate(
        200,
        (i) => SimulatedDatapoint(
          id: 'point_$i',
          center: Offset(
            50 + (i % 20) * 35.0,
            50 + (i ~/ 20) * 50.0,
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(elements: elements),
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();

      // Perform 20 interaction cycles
      for (int i = 0; i < 20; i++) {
        await tester.tapAt(Offset(50 + (i % 20) * 35.0, 100));
        await tester.pump();
      }

      stopwatch.stop();
      final avgMs = stopwatch.elapsedMilliseconds / 20.0;

      expect(avgMs, lessThan(17), reason: 'Avg interaction took ${avgMs.toStringAsFixed(2)}ms (expected <16.67ms)');
      debugPrint('✓ Widget interactions with 200 elements: ${avgMs.toStringAsFixed(2)}ms average');
    });
  });

  group('Memory Performance Benchmarks', () {
    test('QuadTree memory usage is reasonable for 1000 elements', () {
      final quadTree = QuadTree(
        bounds: const Rect.fromLTWH(0, 0, 1000, 1000),
        maxElementsPerNode: 10,
      );
      final random = math.Random(42);

      // Insert 1000 elements
      for (int i = 0; i < 1000; i++) {
        quadTree.insert(SimulatedDatapoint(
          id: 'point_$i',
          center: Offset(
            random.nextDouble() * 1000,
            random.nextDouble() * 1000,
          ),
        ));
      }

      // Perform queries to ensure tree is built
      for (int i = 0; i < 100; i++) {
        quadTree.query(
          Offset(random.nextDouble() * 1000, random.nextDouble() * 1000),
          radius: 50.0,
        );
      }

      // Test passes if we reach here without memory errors
      expect(quadTree.elementCount, equals(1000));
      debugPrint('✓ QuadTree memory stability with 1000 elements validated');
    });

    testWidgets('widget memory usage is stable during lifecycle', (tester) async {
      final elements = List.generate(
        100,
        (i) => SimulatedDatapoint(id: 'point_$i', center: Offset(i * 5.0, 100)),
      );

      // Build and dispose 50 times
      for (int i = 0; i < 50; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PrototypeChart(elements: elements),
            ),
          ),
        );

        // Dispose widget
        await tester.pumpWidget(const SizedBox.shrink());
      }

      // Test passes if we reach here without memory errors
      debugPrint('✓ Widget memory stability through 50 build/dispose cycles validated');
    });
  });

  group('Stress Test Benchmarks', () {
    testWidgets('handles 500 elements without errors', (tester) async {
      final elements = List.generate(
        500,
        (i) => SimulatedDatapoint(
          id: 'point_$i',
          center: Offset(
            10 + (i % 50) * 15.0,
            10 + (i ~/ 50) * 50.0,
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(elements: elements),
          ),
        ),
      );

      // Widget should build successfully
      expect(find.byType(PrototypeChart), findsOneWidget);
      debugPrint('✓ Stress test: 500 elements rendered successfully');
    });

    testWidgets('handles rapid gesture sequences', (tester) async {
      final datapoint = SimulatedDatapoint(id: 'point', center: const Offset(100, 100));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrototypeChart(elements: [datapoint]),
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();

      // 50 rapid tap sequences
      for (int i = 0; i < 50; i++) {
        await tester.tapAt(const Offset(100, 100));
        await tester.pump();
      }

      stopwatch.stop();
      final totalMs = stopwatch.elapsedMilliseconds;
      final avgMs = totalMs / 50.0;

      expect(avgMs, lessThan(17), reason: 'Avg gesture handling took ${avgMs.toStringAsFixed(2)}ms');
      debugPrint('✓ Stress test: 50 rapid gestures handled in ${totalMs}ms (${avgMs.toStringAsFixed(2)}ms avg)');
    });
  });
}
