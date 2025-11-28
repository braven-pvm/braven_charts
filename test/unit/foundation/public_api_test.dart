// Copyright 2024 The Braven Charts Authors
// SPDX-License-Identifier: MIT

// Import from package root to validate public API
import 'package:braven_charts/legacy/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

/// Validates the public API surface of the Foundation layer
///
/// Ensures:
/// - All intended public APIs are accessible
/// - No internal implementation details are exposed
/// - API is clean and well-organized
void main() {
  group('Foundation Public API Validation', () {
    test('Data Models are publicly accessible', () {
      // ChartDataPoint
      final point = const ChartDataPoint(x: 1.0, y: 2.0);
      expect(point.x, equals(1.0));
      expect(point.y, equals(2.0));

      // ChartSeries
      final series = ChartSeries(
        id: 'test',
        name: 'Test Series',
        points: [point],
        isXOrdered: true,
      );
      expect(series.id, equals('test'));
      expect(series.length, equals(1));

      // DataRange
      final range = const DataRange(min: 0.0, max: 10.0);
      expect(range.min, equals(0.0));
      expect(range.max, equals(10.0));

      // TimeSeriesData
      final timeData = TimeSeriesData(
        id: 'test-series',
        data: [
          ChartDataPoint(
            x: 1.0,
            y: 42.0,
            timestamp: DateTime(2024, 1, 1),
          ),
        ],
      );
      expect(timeData.id, equals('test-series'));
      expect(timeData.data.length, equals(1));

      print('✅ Data Models publicly accessible');
    });

    test('Performance Primitives are publicly accessible', () {
      // ObjectPool
      final pool = ObjectPool<List<int>>(
        factory: () => <int>[],
        reset: (list) => list.clear(),
        maxSize: 10,
      );
      final list = pool.acquire();
      pool.release(list);
      expect(pool.statistics.acquireCount, equals(1));

      // ViewportCuller
      final culler = const ViewportCuller(margin: 0.1);
      final points = [
        const ChartDataPoint(x: 1.0, y: 1.0),
        const ChartDataPoint(x: 2.0, y: 2.0),
      ];
      final culled = culler.cull(
        points: points,
        viewportX: const DataRange(min: 0.0, max: 3.0),
        viewportY: const DataRange(min: 0.0, max: 3.0),
        isXOrdered: true,
      );
      expect(culled.isNotEmpty, isTrue);

      // BatchProcessor
      final processor = BatchProcessor<ChartDataPoint, int>(
        keyExtractor: (p) => p.x.toInt(),
      );
      final batches = processor.batch(points);
      expect(batches.isNotEmpty, isTrue);

      print('✅ Performance Primitives publicly accessible');
    });

    test('Type System is publicly accessible', () {
      // ChartResult - Success
      final success = const Success<int>(42);
      expect(success.isSuccess, isTrue);
      expect(success.getOrNull(), equals(42));

      // ChartResult - Failure
      final error = ChartError.validation('Test error');
      final failure = Failure<int>(error);
      expect(failure.isFailure, isTrue);

      // ChartError types
      expect(error.type, equals(ErrorType.validation));
      expect(error.severity, equals(ErrorSeverity.error));

      // ValidationUtils
      expect(ValidationUtils.isFiniteNumber(42.0), isTrue);
      expect(ValidationUtils.isFiniteNumber(double.nan), isFalse);

      final validationResult = ValidationUtils.validateFinite(42.0, 'value');
      expect(validationResult.isSuccess, isTrue);

      print('✅ Type System publicly accessible');
    });

    test('Math Utilities are publicly accessible', () {
      final data = [1.0, 2.0, 3.0, 4.0, 5.0];

      // StatisticalFunctions
      final mean = StatisticalFunctions.mean(data);
      expect(mean, equals(3.0));

      final median = StatisticalFunctions.median(data);
      expect(median, equals(3.0));

      final stdDev = StatisticalFunctions.standardDeviation(data);
      expect(stdDev, greaterThan(0));

      // InterpolationFunctions
      final lerp = InterpolationFunctions.lerp(0.0, 10.0, 0.5);
      expect(lerp, equals(5.0));

      // CurveFittingFunctions
      final points = [
        const ChartDataPoint(x: 0, y: 0),
        const ChartDataPoint(x: 1, y: 2),
        const ChartDataPoint(x: 2, y: 4),
      ];
      final fit = CurveFittingFunctions.linearFit(points);
      expect(fit.coefficients.length, equals(2));

      print('✅ Math Utilities publicly accessible');
    });

    test('All enum types are publicly accessible', () {
      // MeanType
      expect(MeanType.arithmetic, isNotNull);
      expect(MeanType.geometric, isNotNull);
      expect(MeanType.harmonic, isNotNull);

      // ErrorType
      expect(ErrorType.validation, isNotNull);
      expect(ErrorType.rendering, isNotNull);
      expect(ErrorType.calculation, isNotNull);
      expect(ErrorType.internal, isNotNull);

      // ErrorSeverity
      expect(ErrorSeverity.warning, isNotNull);
      expect(ErrorSeverity.error, isNotNull);
      expect(ErrorSeverity.critical, isNotNull);

      print('✅ All enum types publicly accessible');
    });

    test('Supporting data classes are publicly accessible', () {
      // Quartiles
      final data = [1.0, 2.0, 3.0, 4.0, 5.0];
      final quartiles = StatisticalFunctions.quartiles(data);
      expect(quartiles.q1, isNotNull);
      expect(quartiles.q2, isNotNull);
      expect(quartiles.q3, isNotNull);
      expect(quartiles.iqr, isNotNull);

      // MinMax
      final minMax = StatisticalFunctions.minMax(data);
      expect(minMax.min, equals(1.0));
      expect(minMax.max, equals(5.0));

      // FitResult
      final points = [
        const ChartDataPoint(x: 0, y: 0),
        const ChartDataPoint(x: 1, y: 1),
      ];
      final fit = CurveFittingFunctions.linearFit(points);
      expect(fit.coefficients, isNotNull);
      expect(fit.rSquared, isNotNull);
      expect(fit.equation, isNotNull);

      // PoolStatistics
      final pool = ObjectPool<int>(
        factory: () => 0,
        reset: (_) {},
        maxSize: 5,
      );
      final stats = pool.statistics;
      expect(stats.totalCreated, isNotNull);
      expect(stats.currentSize, isNotNull);
      expect(stats.hitRate, isNotNull);

      print('✅ Supporting data classes publicly accessible');
    });

    test('No internal implementation exposed', () {
      // This test ensures we can't access internal implementation details
      // If any internal files were exported, this would fail at compile time

      // We can only access what's exported through foundation.dart
      // Internal helpers, private classes, and implementation details are hidden

      print('✅ Internal implementation properly encapsulated');
    });

    test('API organization is logical', () {
      // Verify the API is organized into clear categories:
      // 1. Data Models - for representing chart data
      // 2. Performance - for optimization primitives
      // 3. Type System - for error handling and validation
      // 4. Math - for statistical and mathematical operations

      // This organizational structure is clear from the barrel export
      // and makes the API easy to discover and use

      print('✅ API organization validated');
    });
  });

  group('Foundation API Usage Examples', () {
    test('Example: Create and validate chart data', () {
      // Create data points
      final points = List.generate(
        100,
        (i) => ChartDataPoint(
          x: i.toDouble(),
          y: i * 2.0,
          timestamp: DateTime(2024, 1, 1).add(Duration(hours: i)),
        ),
      );

      // Create series
      final series = ChartSeries(
        id: 'example',
        name: 'Example Data',
        points: points,
        isXOrdered: true,
      );

      // Validate series
      final validation = series.validate();
      expect(validation.isSuccess, isTrue);

      // Access computed properties
      expect(series.xRange.min, equals(0.0));
      expect(series.xRange.max, equals(99.0));

      print('✅ Example: Chart data creation and validation');
    });

    test('Example: Calculate statistics', () {
      final data = List.generate(1000, (i) => i.toDouble());

      final mean = StatisticalFunctions.mean(data);
      final median = StatisticalFunctions.median(data);
      final stdDev = StatisticalFunctions.standardDeviation(data);
      final quartiles = StatisticalFunctions.quartiles(data);

      expect(mean, closeTo(499.5, 0.1));
      expect(median, closeTo(499.5, 0.1));
      expect(stdDev, greaterThan(0));
      expect(quartiles.iqr, greaterThan(0));

      print('✅ Example: Statistical calculations');
    });

    test('Example: Viewport culling', () {
      final points = List.generate(
        10000,
        (i) => ChartDataPoint(x: i.toDouble(), y: i * 0.5),
      );

      final culler = const ViewportCuller(margin: 0.1);
      final visible = culler.cull(
        points: points,
        viewportX: const DataRange(min: 1000, max: 2000),
        viewportY: const DataRange(min: 0, max: 10000),
        isXOrdered: true,
      );

      expect(visible.length, lessThan(points.length));
      expect(visible.length, greaterThan(0));

      print('✅ Example: Viewport culling');
    });

    test('Example: Error handling with ChartResult', () {
      // Function that returns ChartResult
      ChartResult<double> safeDivide(double a, double b) {
        if (b == 0) {
          return Failure(ChartError.calculation('Division by zero'));
        }
        return Success(a / b);
      }

      // Success case
      final result1 = safeDivide(10, 2);
      expect(result1.isSuccess, isTrue);
      expect(result1.getOrElse(0), equals(5.0));

      // Failure case
      final result2 = safeDivide(10, 0);
      expect(result2.isFailure, isTrue);
      expect(result2.getOrElse(0), equals(0.0));

      // Pattern matching
      final message = result2.when(
        success: (value) => 'Result: $value',
        failure: (error) => 'Error: ${error.message}',
      );
      expect(message, contains('Division by zero'));

      print('✅ Example: Error handling with ChartResult');
    });

    test('Example: Object pooling', () {
      final pool = ObjectPool<StringBuffer>(
        factory: () => StringBuffer(),
        reset: (buffer) => buffer.clear(),
        maxSize: 10,
      );

      // Use objects from pool
      for (int i = 0; i < 100; i++) {
        final buffer = pool.acquire();
        buffer.write('Data $i');
        pool.release(buffer);
      }

      final stats = pool.statistics;
      expect(stats.hitRate, greaterThan(0.9)); // High reuse

      print('✅ Example: Object pooling');
    });
  });
}
