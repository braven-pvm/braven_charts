// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/legacy/src/foundation/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartResult<T> Sealed Class Contract Tests', () {
    test('ChartResult has Success and Failure variants', () {
      final success = const Success<int>(42);
      expect(success.isSuccess, isTrue);
      expect(success.isFailure, isFalse);

      final failure = Failure<int>(ChartError.validation('Test error'));
      expect(failure.isSuccess, isFalse);
      expect(failure.isFailure, isTrue);
    });

    test('ChartResult.when() provides pattern matching', () {
      final success = const Success<int>(42);
      final result = success.when(
        success: (value) => 'Got: $value',
        failure: (error) => 'Error: ${error.message}',
      );
      expect(result, equals('Got: 42'));
    });

    test('ChartResult.getOrNull() returns value or null', () {
      final success = const Success<int>(42);
      expect(success.getOrNull(), equals(42));

      final failure = Failure<int>(ChartError.validation('Test'));
      expect(failure.getOrNull(), isNull);
    });

    test('ChartResult.getOrElse() provides default', () {
      final failure = Failure<int>(ChartError.validation('Test'));
      expect(failure.getOrElse(99), equals(99));
    });

    test('ChartResult.map() transforms success values', () {
      final success = const Success<int>(42);
      final mapped = success.map((v) => v * 2);
      expect(mapped.getOrNull(), equals(84));

      final failure = Failure<int>(ChartError.validation('Test'));
      final mappedFailure = failure.map((v) => v * 2);
      expect(mappedFailure.isFailure, isTrue);
    });

    test('ChartResult.flatMap() chains operations', () {
      final success = const Success<int>(42);
      final chained = success.flatMap((v) => Success(v * 2));
      expect(chained.getOrNull(), equals(84));
    });

    test('ChartResult.fold() handles both cases', () {
      final success = const Success<int>(42);
      final result = success.fold(
        onSuccess: (v) => v * 2,
        onFailure: (e) => 0,
      );
      expect(result, equals(84));
    });

    test('Pattern matching is exhaustive (compile-time check)', () {
      // This test verifies that Dart analyzer enforces exhaustiveness
      // If you remove one case from when(), it should be a compile error
      final result = const Success<int>(42);
      final value = result.when(
        success: (v) => v,
        failure: (e) => 0,
      );
      expect(value, equals(42));
    });
  });

  group('ChartError Contract Tests', () {
    test('ChartError has required properties', () {
      final error = const ChartError(
        type: ErrorType.validation,
        severity: ErrorSeverity.error,
        message: 'Test error',
        code: 'TEST_001',
      );
      expect(error.type, equals(ErrorType.validation));
      expect(error.severity, equals(ErrorSeverity.error));
      expect(error.message, equals('Test error'));
      expect(error.code, equals('TEST_001'));
    });

    test('ChartError.validation() factory works', () {
      final error = ChartError.validation('Invalid data');
      expect(error.type, equals(ErrorType.validation));
      expect(error.severity, equals(ErrorSeverity.error));
      expect(error.message, equals('Invalid data'));
    });

    test('ChartError.rendering() factory works', () {
      final error = ChartError.rendering('Render failed');
      expect(error.type, equals(ErrorType.rendering));
    });

    test('ChartError.calculation() factory works', () {
      final error = ChartError.calculation('Math error');
      expect(error.type, equals(ErrorType.calculation));
    });

    test('ChartError.internal() factory works', () {
      final error = ChartError.internal('Internal error');
      expect(error.type, equals(ErrorType.internal));
      expect(error.severity, equals(ErrorSeverity.critical));
    });

    test('ChartError supports context map', () {
      final error = ChartError.validation(
        'Invalid range',
        context: {'min': 0, 'max': -1},
      );
      expect(error.context?['min'], equals(0));
      expect(error.context?['max'], equals(-1));
    });

    test('ErrorType enum has all expected values', () {
      expect(ErrorType.values, contains(ErrorType.validation));
      expect(ErrorType.values, contains(ErrorType.rendering));
      expect(ErrorType.values, contains(ErrorType.calculation));
      expect(ErrorType.values, contains(ErrorType.configuration));
      expect(ErrorType.values, contains(ErrorType.internal));
    });

    test('ErrorSeverity enum has all expected values', () {
      expect(ErrorSeverity.values, contains(ErrorSeverity.warning));
      expect(ErrorSeverity.values, contains(ErrorSeverity.error));
      expect(ErrorSeverity.values, contains(ErrorSeverity.critical));
    });
  });

  group('ValidationUtils Contract Tests', () {
    test('ValidationUtils.isFiniteNumber() exists', () {
      expect(ValidationUtils.isFiniteNumber(1.0), isTrue);
      expect(ValidationUtils.isFiniteNumber(double.nan), isFalse);
      expect(ValidationUtils.isFiniteNumber(double.infinity), isFalse);
    });

    test('ValidationUtils.validateFinite() returns ChartResult', () {
      final result = ValidationUtils.validateFinite(1.0, 'test');
      expect(result.isSuccess, isTrue);

      final nanResult = ValidationUtils.validateFinite(double.nan, 'test');
      expect(nanResult.isFailure, isTrue);
    });

    test('ValidationUtils.sanitizeNumber() handles NaN/Infinity', () {
      expect(ValidationUtils.sanitizeNumber(1.0, 0.0), equals(1.0));
      expect(ValidationUtils.sanitizeNumber(double.nan, 0.0), equals(0.0));
      expect(ValidationUtils.sanitizeNumber(double.infinity, 0.0), equals(0.0));
    });

    test('ValidationUtils.requireNonNull() validates non-null', () {
      final result = ValidationUtils.requireNonNull<int>(42, 'value');
      expect(result.isSuccess, isTrue);
      expect(result.getOrNull(), equals(42));

      final nullResult = ValidationUtils.requireNonNull<int>(null, 'value');
      expect(nullResult.isFailure, isTrue);
    });

    test('ValidationUtils.validateNotEmpty() validates lists', () {
      final result = ValidationUtils.validateNotEmpty([1, 2, 3], 'list');
      expect(result.isSuccess, isTrue);

      final emptyResult = ValidationUtils.validateNotEmpty([], 'list');
      expect(emptyResult.isFailure, isTrue);
    });

    test('ValidationUtils.validateSize() validates collection size', () {
      final result = ValidationUtils.validateSize([1, 2, 3], min: 1, max: 5);
      expect(result.isSuccess, isTrue);
    });

    test('ValidationUtils.validateUnique() validates uniqueness', () {
      final result = ValidationUtils.validateUnique([1, 2, 3], 'list');
      expect(result.isSuccess, isTrue);

      final dupResult = ValidationUtils.validateUnique([1, 2, 2], 'list');
      expect(dupResult.isFailure, isTrue);
    });

    test('ValidationUtils.validate() supports custom validation', () {
      final result = ValidationUtils.validate(
        10,
        (v) => v > 0,
        'Value must be positive',
      );
      expect(result.isSuccess, isTrue);
    });

    test('ValidationUtils.validateAll() chains validations', () {
      final result = ValidationUtils.validateAll([
        ValidationUtils.validateFinite(1.0, 'x'),
        ValidationUtils.validateFinite(2.0, 'y'),
      ]);
      expect(result.isSuccess, isTrue);
    });
  });
}
