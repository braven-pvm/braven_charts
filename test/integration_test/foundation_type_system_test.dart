// Copyright 2024 The Braven Charts Authors
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:braven_charts/src/foundation/foundation.dart';

/// Integration test for Foundation Layer Type System (FR-003)
/// 
/// Validates complete type system workflows:
/// - ChartResult pattern matching and operations  
/// - ChartError creation and handling
/// - ValidationUtils validation chains
/// - Type-safe error handling throughout
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Foundation Type System Integration', () {
    test('3.1 - ChartResult Success/Failure handling', () {
      // Success case
      final result1 = Success<int>(42);
      expect(result1.isSuccess, isTrue);
      expect(result1.isFailure, isFalse);
      expect(result1.getOrNull(), equals(42));
      expect(result1.getOrElse(0), equals(42));

      // Failure case
      final error = ChartError.validation('Invalid data');
      final result2 = Failure<int>(error);
      expect(result2.isFailure, isTrue);
      expect(result2.isSuccess, isFalse);
      expect(result2.getOrNull(), isNull);
      expect(result2.getOrElse(0), equals(0));

      print('✅ ChartResult Success/Failure handling works correctly');
    });

    test('3.2 - ChartResult pattern matching with when()', () {
      final successResult = Success<int>(42);
      final failureResult = Failure<int>(
        ChartError.validation('Invalid'),
      );

      // Pattern match success
      final successValue = successResult.when(
        success: (val) => 'Got: $val',
        failure: (err) => 'Error: ${err.message}',
      );
      expect(successValue, equals('Got: 42'));

      // Pattern match failure
      final failureValue = failureResult.when(
        success: (val) => 'Got: $val',
        failure: (err) => 'Error: ${err.message}',
      );
      expect(failureValue, equals('Error: Invalid'));

      print('✅ ChartResult pattern matching works correctly');
    });

    test('3.3 - ChartResult map and flatMap operations', () {
      final result = Success<int>(42);

      // Map operation
      final mapped = result.map((x) => x * 2);
      expect(mapped.getOrNull(), equals(84));

      // FlatMap operation
      final flatMapped = result.flatMap((x) => Success(x + 10));
      expect(flatMapped.getOrNull(), equals(52));

      // Map on failure propagates failure
      final failureResult = Failure<int>(
        ChartError.validation('Error'),
      );
      final mappedFailure = failureResult.map((x) => x * 2);
      expect(mappedFailure.isFailure, isTrue);

      print('✅ ChartResult map and flatMap operations work correctly');
    });

    test('3.4 - ChartResult fold operation', () {
      final success = Success<int>(42);
      final failure = Failure<int>(
        ChartError.validation('Error'),
      );

      // Fold success
      final successFolded = success.fold(
        onSuccess: (val) => val * 2,
        onFailure: (err) => -1,
      );
      expect(successFolded, equals(84));

      // Fold failure
      final failureFolded = failure.fold(
        onSuccess: (val) => val * 2,
        onFailure: (err) => -1,
      );
      expect(failureFolded, equals(-1));

      print('✅ ChartResult fold operation works correctly');
    });

    test('3.5 - ChartResult chaining operations', () {
      final result = Success<int>(42);

      // Chain multiple operations
      final chained = result
          .map((x) => x * 2) // 84
          .flatMap((x) => Success(x + 10)) // 94
          .map((x) => x ~/ 2); // 47

      expect(chained.getOrNull(), equals(47));

      // Chaining with failure
      final failedChain = result
          .map((x) => x * 2)
          .flatMap((x) => Failure<int>(
                ChartError.validation('Mid-chain error'),
              ))
          .map((x) => x + 10); // This won't execute

      expect(failedChain.isFailure, isTrue);
      expect(
        failedChain.fold(
          onSuccess: (_) => '',
          onFailure: (err) => err.message,
        ),
        equals('Mid-chain error'),
      );

      print('✅ ChartResult chaining operations work correctly');
    });

    test('3.6 - ChartError factory constructors', () {
      // Validation error
      final validationError = ChartError.validation('Invalid input');
      expect(validationError.type, equals(ErrorType.validation));
      expect(validationError.severity, equals(ErrorSeverity.error));
      expect(validationError.message, equals('Invalid input'));

      // Rendering error
      final renderingError = ChartError.rendering('Failed to render');
      expect(renderingError.type, equals(ErrorType.rendering));

      // Calculation error
      final calculationError = ChartError.calculation('Math overflow');
      expect(calculationError.type, equals(ErrorType.calculation));

      // Internal error
      final internalError = ChartError.internal('Unexpected state');
      expect(internalError.type, equals(ErrorType.internal));
      expect(internalError.severity, equals(ErrorSeverity.critical));

      print('✅ ChartError factory constructors work correctly');
    });

    test('3.7 - ValidationUtils finite number validation', () {
      // Valid finite numbers
      expect(ValidationUtils.isFiniteNumber(42.0), isTrue);
      expect(ValidationUtils.isFiniteNumber(0.0), isTrue);
      expect(ValidationUtils.isFiniteNumber(-42.0), isTrue);

      // Invalid: NaN and infinity
      expect(ValidationUtils.isFiniteNumber(double.nan), isFalse);
      expect(ValidationUtils.isFiniteNumber(double.infinity), isFalse);
      expect(ValidationUtils.isFiniteNumber(double.negativeInfinity), isFalse);

      // Validate finite
      expect(ValidationUtils.validateFinite(42.0, 'x').isSuccess, isTrue);
      expect(ValidationUtils.validateFinite(double.nan, 'x').isFailure, isTrue);

      // Sanitize number
      final sanitized1 = ValidationUtils.sanitizeNumber(double.nan, 0.0);
      expect(sanitized1, equals(0.0));

      final sanitized2 = ValidationUtils.sanitizeNumber(42.0, 0.0);
      expect(sanitized2, equals(42.0));

      print('✅ ValidationUtils finite number validation works correctly');
    });

    test('3.8 - ValidationUtils collection validation', () {
      final validList = [1.0, 2.0, 3.0];
      final emptyList = <double>[];

      // Not empty validation
      expect(ValidationUtils.validateNotEmpty(validList, 'data').isSuccess, isTrue);
      expect(ValidationUtils.validateNotEmpty(emptyList, 'data').isFailure, isTrue);

      // Size validation
      expect(
        ValidationUtils.validateSize(validList, min: 2, max: 5).isSuccess,
        isTrue,
      );
      expect(
        ValidationUtils.validateSize(validList, min: 5).isFailure,
        isTrue,
      );
      expect(
        ValidationUtils.validateSize(validList, max: 2).isFailure,
        isTrue,
      );

      // Unique validation
      final uniqueList = [1.0, 2.0, 3.0];
      final duplicateList = [1.0, 2.0, 1.0];
      expect(ValidationUtils.validateUnique(uniqueList, 'data').isSuccess, isTrue);
      expect(ValidationUtils.validateUnique(duplicateList, 'data').isFailure, isTrue);

      print('✅ ValidationUtils collection validation works correctly');
    });

    test('3.9 - ValidationUtils composable validation chains', () {
      // Custom validation
      final value = 5.0;
      final result1 = ValidationUtils.validate(
        value,
        (val) => val > 0,
        'Value must be positive',
      );
      expect(result1.isSuccess, isTrue);

      // Multiple validations with validateAll
      final result2 = ValidationUtils.validateAll([
        ValidationUtils.validateFinite(value, 'value'),
        ValidationUtils.validate(value, (v) => v > 0, 'Must be positive'),
        ValidationUtils.validate(value, (v) => v < 100, 'Must be < 100'),
      ]);
      expect(result2.isSuccess, isTrue);

      // Validation chain with failure
      final result3 = ValidationUtils.validateAll([
        ValidationUtils.validateFinite(15.0, 'value'),
        ValidationUtils.validate(15.0, (v) => v < 10, 'Must be < 10'), // Fail
      ]);
      expect(result3.isFailure, isTrue);

      print('✅ ValidationUtils composable validation chains work correctly');
    });

    test('3.10 - ValidationUtils requireNonNull', () {
      // Non-null value
      expect(ValidationUtils.requireNonNull(42, 'value').isSuccess, isTrue);
      expect(ValidationUtils.requireNonNull('text', 'label').isSuccess, isTrue);

      // Null value
      expect(ValidationUtils.requireNonNull(null, 'value').isFailure, isTrue);

      print('✅ ValidationUtils requireNonNull works correctly');
    });

    test('3.11 - Real-world validation scenario', () {
      // Validate chart data point coordinates
      ChartResult<void> validateCoordinate(double value, String field) {
        return ValidationUtils.validateAll([
          ValidationUtils.validateFinite(value, field),
          ValidationUtils.validate(
            value,
            (v) => v >= -1000 && v <= 1000,
            '$field must be in range [-1000, 1000]',
          ),
        ]);
      }

      // Valid coordinates
      expect(validateCoordinate(42.0, 'x').isSuccess, isTrue);
      expect(validateCoordinate(0.0, 'y').isSuccess, isTrue);
      expect(validateCoordinate(-500.0, 'x').isSuccess, isTrue);

      // Invalid coordinates
      expect(validateCoordinate(double.nan, 'x').isFailure, isTrue);
      expect(validateCoordinate(1500.0, 'x').isFailure, isTrue);
      expect(validateCoordinate(double.infinity, 'y').isFailure, isTrue);

      print('✅ Real-world validation scenario works correctly');
    });
  });

  group('Foundation Type System - Complete Workflow', () {
    test('End-to-end type system integration', () {
      print('\n=== Type System Integration Test ===');

      // Step 1: Create and validate data
      print('\n1. Creating and validating data...');
      final rawData = [
        ChartDataPoint(x: 10.0, y: 20.0),
        ChartDataPoint(x: 15.0, y: 25.0),
        ChartDataPoint(x: double.nan, y: 30.0), // Invalid!
        ChartDataPoint(x: 20.0, y: 35.0),
      ];

      // Step 2: Filter valid points using type system
      print('2. Filtering valid points...');
      final validPoints = <ChartDataPoint>[];
      final errors = <ChartError>[];

      for (final point in rawData) {
        final validation = ValidationUtils.validateAll([
          ValidationUtils.validateFinite(point.x, 'x'),
          ValidationUtils.validate(
            point.x,
            (v) => v >= 0 && v <= 100,
            'x must be in range [0, 100]',
          ),
        ]);

        validation.fold(
          onSuccess: (_) => validPoints.add(point),
          onFailure: (err) => errors.add(err),
        );
      }

      print('   Valid points: ${validPoints.length}');
      print('   Invalid points: ${errors.length}');
      expect(validPoints.length, equals(3)); // 3 valid, 1 invalid
      expect(errors.length, equals(1));

      // Step 3: Create series with validation
      print('3. Creating series with validation...');
      final seriesResult = validPoints.isNotEmpty
          ? Success<ChartSeries>(
              ChartSeries(
                id: 'validated-series',
                name: 'Validated Data',
                points: validPoints,
                isXOrdered: true,
              ),
            )
          : Failure<ChartSeries>(
              ChartError.validation('No valid points'),
            );

      expect(seriesResult.isSuccess, isTrue);

      // Step 4: Chain operations with ChartResult
      print('4. Chaining operations...');
      final finalResult = seriesResult
          .map((series) => series.length)
          .flatMap((length) {
        return length > 0
            ? Success<String>('Created series with $length points')
            : Failure<String>(ChartError.validation('Empty series'));
      });

      expect(finalResult.isSuccess, isTrue);
      final message = finalResult.getOrElse('Failed');
      print('   $message');

      // Step 5: Error handling demonstration
      print('5. Demonstrating error handling...');
      final errorScenario = Failure<int>(
        ChartError.calculation('Division by zero'),
      );

      final handled = errorScenario.when(
        success: (val) => 'Success: $val',
        failure: (err) {
          print('   Caught error: ${err.type} - ${err.message}');
          return 'Handled gracefully';
        },
      );

      expect(handled, equals('Handled gracefully'));

      print('\n✅ All type system components working together successfully');
    });

    test('Complex validation chain with data processing', () {
      print('\n=== Complex Validation Chain ===');

      // Simulate processing a dataset
      final dataset = List.generate(
        100,
        (i) => ChartDataPoint(
          x: i.toDouble(),
          y: i % 10 == 0 ? double.nan : i * 0.5, // Some invalid data
        ),
      );

      print('Processing ${dataset.length} points...');

      // Validation pipeline
      final validationResults = dataset.map((point) {
        return ValidationUtils.validateAll([
          ValidationUtils.validateFinite(point.y, 'y'),
          ValidationUtils.validate(
            point.y,
            (v) => v >= 0 && v <= 100,
            'y must be in range [0, 100]',
          ),
        ]).map((_) => point);
      }).toList();

      // Count successes and failures
      final successes = validationResults.where((r) => r.isSuccess).length;
      final failures = validationResults.where((r) => r.isFailure).length;

      print('Validation results: $successes valid, $failures invalid');

      expect(successes, equals(90)); // 10 invalid (multiples of 10)
      expect(failures, equals(10));

      // Extract valid points
      final validPoints = validationResults
          .where((r) => r.isSuccess)
          .map((r) => r.getOrNull()!)
          .toList();

      expect(validPoints.length, equals(90));

      print('✅ Complex validation chain completed successfully');
    });
  });
}
