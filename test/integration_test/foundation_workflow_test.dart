// Copyright 2024 The Braven Charts Authors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:braven_charts/src/foundation/foundation.dart';

/// Integration test for Foundation Layer Complete Workflow
///
/// Validates all components working together in realistic scenario:
/// - 50k points → series → statistics → culling → curve fitting → pooling
/// - Performance requirements met across entire pipeline
/// - Memory usage reasonable
/// - No errors or exceptions
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Foundation Complete Workflow Integration', () {
    test('5.1 - Full chart data pipeline (50k points)', () {
      print('\n=== Foundation Layer Integration Test ===\n');

      // Step 1: Generate large dataset
      print('1. Generating 50k data points...');
      final stopwatch = Stopwatch()..start();

      final random = math.Random(42); // Fixed seed for reproducibility
      final rawData = List.generate(
        50000,
        (i) => ChartDataPoint(
          x: i.toDouble(),
          y: (i * 0.5) + (random.nextDouble() * 10 - 5), // Line + noise
          timestamp: DateTime(2024, 1, 1).add(Duration(hours: i)),
        ),
      );

      stopwatch.stop();
      print('   Generated in ${stopwatch.elapsedMilliseconds}ms');
      expect(rawData.length, equals(50000));

      // Step 2: Create series with validation
      print('\n2. Creating ChartSeries...');
      stopwatch.reset();
      stopwatch.start();

      final series = ChartSeries(
        id: 'integration-test',
        name: 'Test Dataset',
        points: rawData,
        isXOrdered: true,
      );

      final validationResult = series.validate();
      stopwatch.stop();

      expect(validationResult.isSuccess, isTrue);
      print(
          '   Series created and validated in ${stopwatch.elapsedMilliseconds}ms');

      // Step 3: Calculate statistics
      print('\n3. Computing statistics...');
      stopwatch.reset();
      stopwatch.start();

      final yValues = rawData.map((p) => p.y).toList();
      final mean = StatisticalFunctions.mean(yValues);
      final stdDev = StatisticalFunctions.standardDeviation(yValues);
      final minMaxResult = StatisticalFunctions.minMax(yValues);

      stopwatch.stop();
      print('   Mean: ${mean.toStringAsFixed(2)}');
      print('   StdDev: ${stdDev.toStringAsFixed(2)}');
      print(
          '   Range: [${minMaxResult.min.toStringAsFixed(2)}, ${minMaxResult.max.toStringAsFixed(2)}]');
      print('   Computed in ${stopwatch.elapsedMilliseconds}ms');

      expect(mean.isFinite, isTrue);
      expect(stdDev, greaterThan(0));

      // Step 4: Viewport culling
      print('\n4. Viewport culling (simulated pan)...');
      final viewport = DataRange(min: 10000.0, max: 20000.0);
      final culler = ViewportCuller(margin: 0.1);

      stopwatch.reset();
      stopwatch.start();

      final visible = culler.cull(
        points: rawData,
        viewportX: viewport,
        viewportY: DataRange(min: minMaxResult.min, max: minMaxResult.max),
        isXOrdered: true,
      );

      stopwatch.stop();
      print(
          '   Culled ${rawData.length} → ${visible.length} points in ${stopwatch.elapsedMicroseconds}μs');
      expect(stopwatch.elapsedMilliseconds,
          lessThan(5)); // <5ms in test environment
      expect(visible.length, greaterThan(0));
      expect(visible.length, lessThan(rawData.length));

      // Step 5: Curve fitting
      print('\n5. Fitting trend line...');
      stopwatch.reset();
      stopwatch.start();

      // Sample every 100th point for faster fitting
      final sample = <ChartDataPoint>[];
      for (var i = 0; i < rawData.length; i += 100) {
        sample.add(rawData[i]);
      }

      final fit = CurveFittingFunctions.linearFit(sample);
      stopwatch.stop();

      print('   ${fit.equation}');
      print('   R² = ${fit.rSquared.toStringAsFixed(4)}');
      print('   Fitted in ${stopwatch.elapsedMilliseconds}ms');

      expect(fit.rSquared, greaterThan(0.5)); // Reasonable fit despite noise
      expect(fit.coefficients.length, equals(2)); // Intercept + slope

      // Step 6: Object pooling (render simulation)
      print('\n6. Simulating render with object pool...');
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

      for (final point in visible.take(100)) {
        final paint = paintPool.acquire();
        paint.color = const Color(0xFF0000FF);
        // Simulate rendering...
        paintPool.release(paint);
      }

      stopwatch.stop();
      final stats = paintPool.statistics;
      print('   Pool hit rate: ${(stats.hitRate * 100).toStringAsFixed(1)}%');
      print('   Simulated render in ${stopwatch.elapsedMicroseconds}μs');

      expect(stats.hitRate, greaterThan(0.9)); // >90% hit rate after warmup

      print('\n✅ All Integration Tests PASSED');
    });

    test('5.2 - Data validation and error handling workflow', () {
      print('\n=== Data Validation Workflow ===\n');

      // Step 1: Create mixed valid/invalid data
      print('1. Creating dataset with validation issues...');
      final mixedData = [
        ChartDataPoint(x: 1.0, y: 10.0), // Valid
        ChartDataPoint(x: 2.0, y: 20.0), // Valid
        ChartDataPoint(x: double.nan, y: 30.0), // Invalid x
        ChartDataPoint(x: 4.0, y: double.infinity), // Invalid y
        ChartDataPoint(x: 5.0, y: 50.0), // Valid
      ];

      // Step 2: Validate each point
      print('2. Validating data points...');
      final validPoints = <ChartDataPoint>[];
      final errors = <ChartError>[];

      for (final point in mixedData) {
        final validation = ValidationUtils.validateAll([
          ValidationUtils.validateFinite(point.x, 'x'),
          ValidationUtils.validateFinite(point.y, 'y'),
        ]);

        validation.fold(
          onSuccess: (_) => validPoints.add(point),
          onFailure: (error) => errors.add(error),
        );
      }

      print('   Valid points: ${validPoints.length}');
      print('   Invalid points: ${errors.length}');

      expect(validPoints.length, equals(3));
      expect(errors.length, equals(2));

      // Step 3: Create series with validated data
      print('3. Creating series with validated data...');
      final seriesResult = validPoints.isNotEmpty
          ? Success<ChartSeries>(
              ChartSeries(
                id: 'validated',
                name: 'Validated Data',
                points: validPoints,
                isXOrdered: true,
              ),
            )
          : Failure<ChartSeries>(
              ChartError.validation('No valid points'),
            );

      expect(seriesResult.isSuccess, isTrue);

      // Step 4: Process validated series
      print('4. Processing validated series...');
      final result = seriesResult.map((series) {
        final yValues = series.points.map((p) => p.y).toList();
        return StatisticalFunctions.mean(yValues);
      });

      expect(result.isSuccess, isTrue);
      final meanValue = result.getOrNull();
      expect(meanValue, isNotNull);
      print('   Mean of valid points: ${meanValue!.toStringAsFixed(2)}');

      print('\n✅ Data validation workflow completed successfully');
    });

    test('5.3 - Performance optimization workflow', () {
      print('\n=== Performance Optimization Workflow ===\n');

      // Step 1: Generate large ordered dataset
      print('1. Generating 100k ordered points...');
      final stopwatch = Stopwatch()..start();

      final largeData = List.generate(
        100000,
        (i) => ChartDataPoint(x: i.toDouble(), y: i * 0.5),
      );

      stopwatch.stop();
      print('   Generated in ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // <100ms (FR-005.1)

      // Step 2: Viewport culling with margin
      print('2. Testing viewport culling performance...');
      final viewport = DataRange(min: 40000.0, max: 60000.0);
      final culler = ViewportCuller(margin: 0.05);

      stopwatch.reset();
      stopwatch.start();

      final culled = culler.cull(
        points: largeData,
        viewportX: viewport,
        viewportY: DataRange(min: 0, max: 100000),
        isXOrdered: true,
      );

      stopwatch.stop();
      print(
          '   Culled ${largeData.length} → ${culled.length} points in ${stopwatch.elapsedMicroseconds}μs');
      expect(stopwatch.elapsedMilliseconds,
          lessThan(5)); // <5ms in test environment

      // Step 3: Batch processing
      print('3. Testing batch processor...');
      final processor = BatchProcessor<ChartDataPoint, int>(
        keyExtractor: (point) => (point.x ~/ 1000),
      );

      // Group points by thousands
      final grouped = processor.batch(
        largeData.take(10000).toList(),
      );

      print('   Grouped ${grouped.length} batches');
      expect(grouped.length, greaterThan(0));

      // Step 4: Object pool efficiency
      print('4. Testing object pool efficiency...');
      final pool = ObjectPool<List<double>>(
        factory: () => <double>[],
        reset: (list) => list.clear(),
        maxSize: 100,
      );

      stopwatch.reset();
      stopwatch.start();

      // Simulate heavy reuse
      for (int i = 0; i < 10000; i++) {
        final list = pool.acquire();
        list.add(i.toDouble());
        pool.release(list);
      }

      stopwatch.stop();
      final poolStats = pool.statistics;
      print('   10k acquire/release in ${stopwatch.elapsedMilliseconds}ms');
      print('   Hit rate: ${(poolStats.hitRate * 100).toStringAsFixed(1)}%');
      print('   Current pool size: ${poolStats.currentSize}');

      expect(poolStats.hitRate, greaterThan(0.95)); // Very high reuse

      print('\n✅ Performance optimization workflow validated');
    });

    test('5.4 - Memory efficiency workflow', () {
      print('\n=== Memory Efficiency Workflow ===\n');

      // Step 1: Create series with minimal memory footprint
      print('1. Testing memory-efficient data structures...');

      // Immutable data points share structure
      final basePoint = ChartDataPoint(x: 0, y: 0);
      final points = List.generate(
        1000,
        (i) => basePoint.copyWith(x: i.toDouble(), y: i * 2.0),
      );

      expect(points.length, equals(1000));
      print('   Created 1000 points using copyWith');

      // Step 2: Series with automatic ordering detection
      print('2. Testing series optimization...');
      final series = ChartSeries(
        id: 'optimized',
        name: 'Optimized Series',
        points: points,
        isXOrdered: true, // Enables optimized algorithms
      );

      expect(series.isXOrdered, isTrue);
      print('   Series configured for optimized culling');

      // Step 3: Efficient range calculations
      print('3. Testing range calculations...');
      final stopwatch = Stopwatch()..start();

      final xRange = series.xRange;
      final yRange = series.yRange;

      stopwatch.stop();
      print('   Calculated ranges in ${stopwatch.elapsedMicroseconds}μs');
      expect(xRange.min, equals(0.0));
      expect(xRange.max, equals(999.0));
      expect(yRange.min, equals(0.0));
      expect(yRange.max, equals(1998.0));

      // Step 4: Reuse via object pooling
      print('4. Testing object reuse...');
      final paintPool = ObjectPool<Paint>(
        factory: () => Paint(),
        reset: (p) => p.color = const Color(0xFF000000),
        maxSize: 10,
      );

      // Reuse same Paint objects
      for (int i = 0; i < 100; i++) {
        final paint = paintPool.acquire();
        paintPool.release(paint);
      }

      final stats = paintPool.statistics;
      print(
          '   Reused ${stats.currentSize} Paint objects (${stats.acquireCount} acquires)');
      expect(stats.currentSize, lessThanOrEqualTo(10));

      print('\n✅ Memory efficiency workflow validated');
    });

    test('5.5 - Real-world chart rendering simulation', () {
      print('\n=== Real-World Chart Rendering Simulation ===\n');

      // Simulate a real chart scenario:
      // 1. User loads data
      // 2. Chart displays initial view
      // 3. User pans/zooms multiple times
      // 4. Chart updates statistics

      print('1. Loading chart data (10k points)...');
      final random = math.Random(123);
      final chartData = List.generate(
        10000,
        (i) => ChartDataPoint(
          x: i.toDouble(),
          y: 100 + (50 * math.sin(i * 0.01)) + (random.nextDouble() * 20 - 10),
          timestamp: DateTime(2024, 1, 1).add(Duration(minutes: i)),
        ),
      );

      final series = ChartSeries(
        id: 'chart-1',
        name: 'Sensor Data',
        points: chartData,
        isXOrdered: true,
      );

      print('   Loaded ${series.length} points');

      // Initial view
      print('\n2. Rendering initial view...');
      final initialViewport = DataRange(min: 0, max: 1000);
      final culler = ViewportCuller(margin: 0.1);

      final stopwatch = Stopwatch()..start();
      var visiblePoints = culler.cull(
        points: chartData,
        viewportX: initialViewport,
        viewportY: series.yRange,
        isXOrdered: true,
      );
      stopwatch.stop();

      print('   Visible: ${visiblePoints.length} points');
      print('   Culling took: ${stopwatch.elapsedMicroseconds}μs');

      // Simulate pan operations
      print('\n3. Simulating pan operations...');
      final panStopwatch = Stopwatch()..start();

      for (int i = 0; i < 10; i++) {
        final panViewport = DataRange(
          min: i * 1000.0,
          max: (i + 1) * 1000.0,
        );

        visiblePoints = culler.cull(
          points: chartData,
          viewportX: panViewport,
          viewportY: series.yRange,
          isXOrdered: true,
        );
      }

      panStopwatch.stop();
      print('   10 pan operations in ${panStopwatch.elapsedMilliseconds}ms');
      print('   Average: ${panStopwatch.elapsedMilliseconds / 10}ms per pan');

      // Calculate statistics
      print('\n4. Calculating visible data statistics...');
      final statsStopwatch = Stopwatch()..start();

      final yValues = visiblePoints.map((p) => p.y).toList();
      final stats = {
        'mean': StatisticalFunctions.mean(yValues),
        'median': StatisticalFunctions.median(yValues),
        'stdDev': StatisticalFunctions.standardDeviation(yValues),
      };

      final quartiles = StatisticalFunctions.quartiles(yValues);
      statsStopwatch.stop();

      print(
          '   Statistics computed in ${statsStopwatch.elapsedMilliseconds}ms:');
      print('     Mean: ${stats['mean']!.toStringAsFixed(2)}');
      print('     Median: ${stats['median']!.toStringAsFixed(2)}');
      print('     StdDev: ${stats['stdDev']!.toStringAsFixed(2)}');
      print('     IQR: ${quartiles.iqr.toStringAsFixed(2)}');

      // Fit trend line
      print('\n5. Fitting trend line to visible data...');
      final fitStopwatch = Stopwatch()..start();

      final fit =
          CurveFittingFunctions.linearFit(visiblePoints.take(500).toList());
      fitStopwatch.stop();

      print('   ${fit.equation}');
      print('   R² = ${fit.rSquared.toStringAsFixed(4)}');
      print('   Fitted in ${fitStopwatch.elapsedMilliseconds}ms');

      print('\n✅ Real-world chart rendering simulation completed successfully');
    });
  });
}
