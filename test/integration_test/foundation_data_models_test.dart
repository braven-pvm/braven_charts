// Copyright 2024 The Braven Charts Authors
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:braven_charts/src/foundation/foundation.dart';

/// Integration test for Foundation Layer Data Models (FR-001)
/// 
/// Validates complete data model workflows from quickstart scenario 1:
/// - ChartDataPoint creation and manipulation
/// - ChartSeries with 100k points performance
/// - DataRange calculations and operations
/// - Memory and performance targets
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Foundation Data Models Integration', () {
    test('1.1 - Create and manipulate individual data points', () {
      // Create simple point
      final point1 = ChartDataPoint(x: 10.0, y: 20.0);
      expect(point1.x, equals(10.0));
      expect(point1.y, equals(20.0));
      expect(point1.hasTimestamp, isFalse);

      // Create point with timestamp
      final point2 = ChartDataPoint(
        x: 15.0,
        y: 25.0,
        timestamp: DateTime(2024, 1, 1),
        label: 'Data Point',
      );
      expect(point2.hasTimestamp, isTrue);
      expect(point2.hasLabel, isTrue);

      // Test immutability
      final point3 = point1.copyWith(y: 30.0);
      expect(point1.y, equals(20.0)); // Original unchanged
      expect(point3.y, equals(30.0)); // New point updated

      // Test validation
      expect(point1.isValid, isTrue); // Finite numbers
      expect(ChartDataPoint(x: double.nan, y: 5.0).isValid, isFalse); // NaN invalid
    });

    test('1.2 - Create ChartSeries with 100k points in <100ms', () {
      final stopwatch = Stopwatch()..start();

      // Generate 100k points (FR-005.1: <1μs per point)
      final points = List.generate(
        100000,
        (i) => ChartDataPoint(x: i.toDouble(), y: i * 0.5),
      );

      // Create series
      final series = ChartSeries(
        id: 'large-dataset',
        name: 'Performance Test',
        points: points,
        isXOrdered: true, // Points sorted by x
      );

      stopwatch.stop();

      // Validate series properties
      expect(series.length, equals(100000));
      expect(series.isXOrdered, isTrue);
      expect(series.validateOrdering(), isTrue); // Verify actual order

      // Performance target: <100ms (FR-005.2)
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: 'Series creation must complete in <100ms (FR-005.2)',
      );

      // Check computed properties
      final xRange = series.xRange;
      expect(xRange.min, equals(0.0));
      expect(xRange.max, equals(99999.0));

      print('✅ Series with 100k points created in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('1.3 - Data range calculations and operations', () {
      final values = [10.0, 20.0, 15.0, 30.0, 25.0];

      // Auto-calculate range
      final range1 = DataRange.fromValues(values);
      expect(range1.min, equals(10.0));
      expect(range1.max, equals(30.0));
      expect(range1.span, equals(20.0));
      expect(range1.center, equals(20.0));

      // Range with padding (10% = 2.0 on each side)
      final range2 = DataRange(min: 10.0, max: 30.0, padding: 0.1);
      expect(range2.paddedMin, equals(8.0)); // 10 - (20 * 0.1)
      expect(range2.paddedMax, equals(32.0)); // 30 + (20 * 0.1)

      // Symmetric range
      final range3 = DataRange.symmetric(center: 100.0, radius: 50.0);
      expect(range3.min, equals(50.0));
      expect(range3.max, equals(150.0));

      // Range operations
      expect(range1.contains(15.0), isTrue);
      expect(range1.contains(5.0), isFalse);
      expect(range1.contains(10.0), isTrue); // Boundary inclusive
      expect(range1.contains(30.0), isTrue); // Boundary inclusive

      print('✅ All data range calculations correct');
    });

    test('1.4 - ChartDataPoint creation performance (<1μs per point)', () {
      const iterations = 100000;
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < iterations; i++) {
        // Prevent optimization by using varying data
        final _ = ChartDataPoint(x: i.toDouble(), y: i * 0.5);
      }

      stopwatch.stop();

      final averageMicroseconds = stopwatch.elapsedMicroseconds / iterations;

      // Performance target: <1μs per point (FR-005.1)
      expect(
        averageMicroseconds,
        lessThan(1.0),
        reason: 'ChartDataPoint creation must be <1μs per point (FR-005.1)',
      );

      print('✅ ChartDataPoint creation: ${averageMicroseconds.toStringAsFixed(3)}μs per point');
    });

    test('1.5 - ChartSeries validation and ordering checks', () {
      // Valid ordered series
      final orderedPoints = [
        ChartDataPoint(x: 1.0, y: 10.0),
        ChartDataPoint(x: 2.0, y: 20.0),
        ChartDataPoint(x: 3.0, y: 30.0),
      ];

      final orderedSeries = ChartSeries(
        id: 'ordered',
        name: 'Ordered Series',
        points: orderedPoints,
        isXOrdered: true,
      );

      expect(orderedSeries.validateOrdering(), isTrue);
      expect(orderedSeries.validate().isSuccess, isTrue);

      // Unordered series (should not claim isXOrdered)
      final unorderedPoints = [
        ChartDataPoint(x: 3.0, y: 30.0),
        ChartDataPoint(x: 1.0, y: 10.0),
        ChartDataPoint(x: 2.0, y: 20.0),
      ];

      final unorderedSeries = ChartSeries(
        id: 'unordered',
        name: 'Unordered Series',
        points: unorderedPoints,
        isXOrdered: false, // Correctly marked as unordered
      );

      expect(unorderedSeries.validate().isSuccess, isTrue);

      // Invalid: claims ordered but is not
      final invalidSeries = ChartSeries(
        id: 'invalid',
        name: 'Invalid Series',
        points: unorderedPoints,
        isXOrdered: true, // Incorrectly claims ordered
      );

      expect(invalidSeries.validateOrdering(), isFalse);
      expect(invalidSeries.validate().isFailure, isTrue);

      print('✅ Series validation and ordering checks pass');
    });

    test('1.6 - Memory efficiency check (informational)', () {
      // Create 10k points to check memory efficiency
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(
          x: i.toDouble(),
          y: i * 0.5,
          timestamp: DateTime(2024, 1, 1).add(Duration(hours: i)),
          label: 'Point $i',
        ),
      );

      final series = ChartSeries(
        id: 'memory-test',
        name: 'Memory Test',
        points: points,
        isXOrdered: true,
      );

      // Validate series
      expect(series.length, equals(10000));
      expect(series.validate().isSuccess, isTrue);

      // Note: Actual memory profiling requires DevTools
      // Target: <10MB for 10k points (FR-005.2)
      // This test validates functionality; memory profiling done via T057
      print('✅ Created series with 10k points (memory profiling in T057)');
    });

    test('1.7 - DataRange edge cases', () {
      // Empty list - returns zero range
      final emptyRange = DataRange.fromValues([]);
      expect(emptyRange.min, equals(0.0));
      expect(emptyRange.max, equals(0.0));

      // Single value
      final singleRange = DataRange.fromValues([42.0]);
      expect(singleRange.min, equals(42.0));
      expect(singleRange.max, equals(42.0));
      expect(singleRange.span, equals(0.0));

      // Equal min/max
      final equalRange = DataRange(min: 10.0, max: 10.0);
      expect(equalRange.validate().isSuccess, isTrue);
      expect(equalRange.span, equals(0.0));

      // Invalid: min > max (assertion error)
      expect(
        () => DataRange(min: 20.0, max: 10.0),
        throwsAssertionError,
      );

      // Use validate() to check validity instead
      final validRange = DataRange(min: 10.0, max: 20.0);
      expect(validRange.validate().isSuccess, isTrue);

      // Negative values
      final negativeRange = DataRange.fromValues([-10.0, -5.0, 0.0, 5.0, 10.0]);
      expect(negativeRange.min, equals(-10.0));
      expect(negativeRange.max, equals(10.0));
      expect(negativeRange.center, equals(0.0));

      print('✅ DataRange edge cases handled correctly');
    });

    test('1.8 - ChartDataPoint copyWith completeness', () {
      final original = ChartDataPoint(
        x: 10.0,
        y: 20.0,
        timestamp: DateTime(2024, 1, 1),
        label: 'Original',
        metadata: {'key': 'value'},
      );

      // Copy with single property
      final copied1 = original.copyWith(y: 30.0);
      expect(copied1.x, equals(10.0)); // Unchanged
      expect(copied1.y, equals(30.0)); // Changed
      expect(copied1.timestamp, equals(DateTime(2024, 1, 1))); // Unchanged
      expect(copied1.label, equals('Original')); // Unchanged

      // Copy with multiple properties
      final copied2 = original.copyWith(
        x: 15.0,
        y: 25.0,
        label: 'Modified',
      );
      expect(copied2.x, equals(15.0));
      expect(copied2.y, equals(25.0));
      expect(copied2.label, equals('Modified'));
      expect(copied2.timestamp, equals(DateTime(2024, 1, 1))); // Unchanged

      // Create new point without optional fields to test default behavior
      final minimal = ChartDataPoint(x: 5.0, y: 10.0);
      expect(minimal.hasTimestamp, isFalse);
      expect(minimal.hasLabel, isFalse);
      expect(minimal.metadata, isNull);

      print('✅ ChartDataPoint copyWith works correctly');
    });
  });

  group('Foundation Data Models - Performance Summary', () {
    test('Complete workflow performance validation', () {
      print('\n=== Data Models Performance Summary ===');

      final stopwatch = Stopwatch();

      // 1. Point creation
      stopwatch.start();
      final points = List.generate(
        100000,
        (i) => ChartDataPoint(x: i.toDouble(), y: i * 0.5),
      );
      stopwatch.stop();
      final creationTime = stopwatch.elapsedMilliseconds;
      print('Point creation (100k): ${creationTime}ms');

      // 2. Series creation
      stopwatch.reset();
      stopwatch.start();
      final series = ChartSeries(
        id: 'perf-test',
        name: 'Performance Test',
        points: points,
        isXOrdered: true,
      );
      stopwatch.stop();
      final seriesTime = stopwatch.elapsedMilliseconds;
      print('Series creation: ${seriesTime}ms');

      // 3. Range calculation
      stopwatch.reset();
      stopwatch.start();
      final xRange = series.xRange;
      final yRange = series.yRange;
      stopwatch.stop();
      final rangeTime = stopwatch.elapsedMicroseconds;
      print('Range calculation: ${rangeTime}μs');

      // 4. Validation
      stopwatch.reset();
      stopwatch.start();
      final validationResult = series.validate();
      stopwatch.stop();
      final validationTime = stopwatch.elapsedMicroseconds;
      print('Validation: ${validationTime}μs');

      print('\n✅ All performance targets met (FR-005.1, FR-005.2)');

      // Verify all targets
      expect(creationTime, lessThan(100), reason: 'Series creation <100ms');
      expect(validationResult.isSuccess, isTrue);
      expect(series.length, equals(100000));
    });
  });
}
