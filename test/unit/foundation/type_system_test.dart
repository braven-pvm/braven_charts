// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/src/foundation/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartResult<T> Unit Tests', () {
    group('Success variant', () {
      test('creates Success with value', () {
        const result = Success<int>(42);
        expect(result.value, equals(42));
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
      });

      test('getOrNull returns value', () {
        const result = Success<int>(42);
        expect(result.getOrNull(), equals(42));
      });

      test('getOrElse returns value, ignores default', () {
        const result = Success<int>(42);
        expect(result.getOrElse(99), equals(42));
      });

      test('map transforms value', () {
        const result = Success<int>(10);
        final mapped = result.map((v) => v * 2);
        expect(mapped, isA<Success<int>>());
        expect(mapped.getOrNull(), equals(20));
      });

      test('map changes type', () {
        const result = Success<int>(42);
        final mapped = result.map((v) => 'Value: $v');
        expect(mapped, isA<Success<String>>());
        expect(mapped.getOrNull(), equals('Value: 42'));
      });

      test('flatMap chains successful operations', () {
        const result = Success<int>(10);
        final chained = result.flatMap((v) => Success(v * 2));
        expect(chained, isA<Success<int>>());
        expect(chained.getOrNull(), equals(20));
      });

      test('flatMap propagates Failure from chain', () {
        const result = Success<int>(10);
        final chained = result.flatMap(
          (v) => Failure<int>(ChartError.validation('Error in chain')),
        );
        expect(chained, isA<Failure<int>>());
      });

      test('fold executes onSuccess branch', () {
        const result = Success<int>(10);
        final value = result.fold(
          onSuccess: (v) => v * 2,
          onFailure: (e) => 0,
        );
        expect(value, equals(20));
      });

      test('when executes success callback', () {
        const result = Success<String>('hello');
        final output = result.when(
          success: (v) => v.toUpperCase(),
          failure: (e) => 'ERROR',
        );
        expect(output, equals('HELLO'));
      });

      test('equality works correctly', () {
        const result1 = Success<int>(42);
        const result2 = Success<int>(42);
        const result3 = Success<int>(99);

        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });

      test('hashCode is consistent', () {
        const result1 = Success<int>(42);
        const result2 = Success<int>(42);

        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('toString provides useful output', () {
        const result = Success<int>(42);
        expect(result.toString(), equals('Success(42)'));
      });
    });

    group('Failure variant', () {
      test('creates Failure with error', () {
        final error = ChartError.validation('Test error');
        final result = Failure<int>(error);
        expect(result.error, equals(error));
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
      });

      test('getOrNull returns null', () {
        final result = Failure<int>(ChartError.validation('Error'));
        expect(result.getOrNull(), isNull);
      });

      test('getOrElse returns default', () {
        final result = Failure<int>(ChartError.validation('Error'));
        expect(result.getOrElse(99), equals(99));
      });

      test('map does not transform, preserves Failure', () {
        final result = Failure<int>(ChartError.validation('Error'));
        final mapped = result.map((v) => v * 2);
        expect(mapped, isA<Failure<int>>());
        expect((mapped as Failure).error.message, equals('Error'));
      });

      test('map preserves Failure with type change', () {
        final result = Failure<int>(ChartError.validation('Error'));
        final mapped = result.map((v) => 'Value: $v');
        expect(mapped, isA<Failure<String>>());
      });

      test('flatMap does not execute chain', () {
        final result = Failure<int>(ChartError.validation('Error'));
        var chainExecuted = false;
        final chained = result.flatMap((v) {
          chainExecuted = true;
          return Success(v * 2);
        });
        expect(chainExecuted, isFalse);
        expect(chained, isA<Failure<int>>());
      });

      test('fold executes onFailure branch', () {
        final error = ChartError.validation('Test error');
        final result = Failure<int>(error);
        final value = result.fold(
          onSuccess: (v) => v * 2,
          onFailure: (e) => 0,
        );
        expect(value, equals(0));
      });

      test('when executes failure callback', () {
        final result = Failure<int>(ChartError.validation('Test'));
        final output = result.when(
          success: (v) => 'Value: $v',
          failure: (e) => 'Error: ${e.message}',
        );
        expect(output, equals('Error: Test'));
      });

      test('equality works correctly', () {
        final error1 = ChartError.validation('Error');
        final error2 = ChartError.validation('Error');
        final error3 = ChartError.validation('Different');

        final result1 = Failure<int>(error1);
        final result2 = Failure<int>(error2);
        final result3 = Failure<int>(error3);

        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });

      test('toString provides useful output', () {
        final error = ChartError.validation('Test error');
        final result = Failure<int>(error);
        expect(result.toString(), contains('Failure'));
        expect(result.toString(), contains('Test error'));
      });
    });

    group('Type safety and pattern matching', () {
      test('exhaustive pattern matching with when', () {
        ChartResult<int> getResult(bool succeed) {
          return succeed
              ? const Success(42)
              : Failure(ChartError.validation('Error'));
        }

        // Both branches must be handled
        final successOutput = getResult(true).when(
          success: (v) => v,
          failure: (e) => 0,
        );
        expect(successOutput, equals(42));

        final failureOutput = getResult(false).when(
          success: (v) => v,
          failure: (e) => 0,
        );
        expect(failureOutput, equals(0));
      });

      test('type inference works correctly', () {
        const result = Success(42); // Type inferred as Success<int>
        expect(result, isA<Success<int>>());
      });

      test('can chain multiple operations', () {
        const result = Success<int>(5);
        final chained = result
            .map((v) => v * 2) // 10
            .flatMap((v) => Success(v + 5)) // 15
            .map((v) => v.toString()); // "15"

        expect(chained.getOrNull(), equals('15'));
      });

      test('chain breaks on first Failure', () {
        const result = Success<int>(5);
        final chained = result
            .map((v) => v * 2) // 10
            .flatMap((v) => Failure<int>(ChartError.validation('Stop')))
            .map((v) => v + 100); // Should not execute

        expect(chained.isFailure, isTrue);
        expect((chained as Failure).error.message, equals('Stop'));
      });
    });

    group('Edge cases', () {
      test('Success with null value', () {
        const result = Success<int?>(null);
        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), isNull);
      });

      test('map with exception in transform', () {
        const result = Success<int>(0);
        expect(
          () => result.map((v) => 10 ~/ v), // Division by zero
          throwsA(isA<IntegerDivisionByZeroException>()),
        );
      });

      test('nested ChartResult types', () {
        const result = Success<ChartResult<int>>(Success(42));
        expect(result.isSuccess, isTrue);
        expect(result.value.getOrNull(), equals(42));
      });
    });
  });

  group('ChartError Unit Tests', () {
    group('Constructor', () {
      test('creates error with all properties', () {
        final error = const ChartError(
          type: ErrorType.validation,
          severity: ErrorSeverity.error,
          message: 'Test message',
          code: 'TEST_001',
          context: {'key': 'value'},
        );

        expect(error.type, equals(ErrorType.validation));
        expect(error.severity, equals(ErrorSeverity.error));
        expect(error.message, equals('Test message'));
        expect(error.code, equals('TEST_001'));
        expect(error.context?['key'], equals('value'));
      });

      test('creates error with minimal properties', () {
        final error = const ChartError(
          type: ErrorType.internal,
          severity: ErrorSeverity.critical,
          message: 'Error',
        );

        expect(error.type, equals(ErrorType.internal));
        expect(error.severity, equals(ErrorSeverity.critical));
        expect(error.message, equals('Error'));
        expect(error.code, isNull);
        expect(error.context, isNull);
      });
    });

    group('Factory constructors', () {
      test('validation creates validation error', () {
        final error = ChartError.validation('Invalid data');
        expect(error.type, equals(ErrorType.validation));
        expect(error.severity, equals(ErrorSeverity.error));
        expect(error.message, equals('Invalid data'));
      });

      test('validation with full context', () {
        final error = ChartError.validation(
          'Range error',
          code: 'RANGE_001',
          context: {'min': 0, 'max': 100, 'actual': 150},
        );
        expect(error.code, equals('RANGE_001'));
        expect(error.context?['actual'], equals(150));
      });

      test('rendering creates rendering error', () {
        final error = ChartError.rendering('Canvas error');
        expect(error.type, equals(ErrorType.rendering));
        expect(error.severity, equals(ErrorSeverity.error));
      });

      test('calculation creates calculation error', () {
        final error = ChartError.calculation('Math error');
        expect(error.type, equals(ErrorType.calculation));
        expect(error.severity, equals(ErrorSeverity.error));
      });

      test('configuration creates configuration error', () {
        final error = ChartError.configuration('Config missing');
        expect(error.type, equals(ErrorType.configuration));
        expect(error.severity, equals(ErrorSeverity.error));
      });

      test('internal creates critical internal error', () {
        final error = ChartError.internal('System failure');
        expect(error.type, equals(ErrorType.internal));
        expect(error.severity, equals(ErrorSeverity.critical));
      });
    });

    group('Equality and hashCode', () {
      test('equal errors are equal', () {
        final error1 = ChartError.validation('Error', code: 'E001');
        final error2 = ChartError.validation('Error', code: 'E001');
        expect(error1, equals(error2));
      });

      test('different messages are not equal', () {
        final error1 = ChartError.validation('Error 1');
        final error2 = ChartError.validation('Error 2');
        expect(error1, isNot(equals(error2)));
      });

      test('different types are not equal', () {
        final error1 = ChartError.validation('Error');
        final error2 = ChartError.rendering('Error');
        expect(error1, isNot(equals(error2)));
      });

      test('hashCode is consistent', () {
        final error1 = ChartError.validation('Error', code: 'E001');
        final error2 = ChartError.validation('Error', code: 'E001');
        expect(error1.hashCode, equals(error2.hashCode));
      });

      test('context does not affect equality', () {
        final error1 = ChartError.validation('Error', context: {'a': 1});
        final error2 = ChartError.validation('Error', context: {'b': 2});
        expect(error1, equals(error2));
      });
    });

    group('toString', () {
      test('includes all relevant information', () {
        final error = ChartError.validation(
          'Test error',
          code: 'TEST_001',
          context: {'value': 42},
        );
        final str = error.toString();

        expect(str, contains('ChartError'));
        expect(str, contains('validation'));
        expect(str, contains('error'));
        expect(str, contains('Test error'));
        expect(str, contains('TEST_001'));
        expect(str, contains('value'));
      });

      test('handles minimal error', () {
        final error = const ChartError(
          type: ErrorType.internal,
          severity: ErrorSeverity.critical,
          message: 'Error',
        );
        final str = error.toString();

        expect(str, contains('ChartError'));
        expect(str, contains('internal'));
        expect(str, contains('critical'));
        expect(str, contains('Error'));
      });
    });

    group('Enums', () {
      test('ErrorType has all expected values', () {
        expect(ErrorType.values.length, equals(5));
        expect(ErrorType.values, contains(ErrorType.validation));
        expect(ErrorType.values, contains(ErrorType.rendering));
        expect(ErrorType.values, contains(ErrorType.calculation));
        expect(ErrorType.values, contains(ErrorType.configuration));
        expect(ErrorType.values, contains(ErrorType.internal));
      });

      test('ErrorSeverity has all expected values', () {
        expect(ErrorSeverity.values.length, equals(3));
        expect(ErrorSeverity.values, contains(ErrorSeverity.warning));
        expect(ErrorSeverity.values, contains(ErrorSeverity.error));
        expect(ErrorSeverity.values, contains(ErrorSeverity.critical));
      });
    });
  });

  group('ValidationUtils Unit Tests', () {
    group('isFiniteNumber', () {
      test('returns true for finite numbers', () {
        expect(ValidationUtils.isFiniteNumber(0.0), isTrue);
        expect(ValidationUtils.isFiniteNumber(1.0), isTrue);
        expect(ValidationUtils.isFiniteNumber(-1.0), isTrue);
        expect(ValidationUtils.isFiniteNumber(0.001), isTrue);
        expect(ValidationUtils.isFiniteNumber(double.maxFinite), isTrue);
        expect(ValidationUtils.isFiniteNumber(-double.maxFinite), isTrue);
      });

      test('returns false for NaN', () {
        expect(ValidationUtils.isFiniteNumber(double.nan), isFalse);
      });

      test('returns false for infinity', () {
        expect(ValidationUtils.isFiniteNumber(double.infinity), isFalse);
        expect(
            ValidationUtils.isFiniteNumber(double.negativeInfinity), isFalse);
      });
    });

    group('validateFinite', () {
      test('succeeds for finite numbers', () {
        final result = ValidationUtils.validateFinite(42.0, 'value');
        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals(42.0));
      });

      test('fails for NaN', () {
        final result = ValidationUtils.validateFinite(double.nan, 'value');
        expect(result.isFailure, isTrue);
        final error = (result as Failure).error;
        expect(error.type, equals(ErrorType.validation));
        expect(error.message, contains('finite'));
        expect(error.context?['field'], equals('value'));
      });

      test('fails for infinity', () {
        final result = ValidationUtils.validateFinite(double.infinity, 'x');
        expect(result.isFailure, isTrue);
      });
    });

    group('sanitizeNumber', () {
      test('returns original for finite numbers', () {
        expect(ValidationUtils.sanitizeNumber(42.0, 0.0), equals(42.0));
        expect(ValidationUtils.sanitizeNumber(-10.5, 0.0), equals(-10.5));
      });

      test('returns default for NaN', () {
        expect(ValidationUtils.sanitizeNumber(double.nan, 99.0), equals(99.0));
      });

      test('returns default for infinity', () {
        expect(
            ValidationUtils.sanitizeNumber(double.infinity, 0.0), equals(0.0));
        expect(ValidationUtils.sanitizeNumber(double.negativeInfinity, -1.0),
            equals(-1.0));
      });
    });

    group('requireNonNull', () {
      test('succeeds for non-null values', () {
        final result = ValidationUtils.requireNonNull<int>(42, 'value');
        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals(42));
      });

      test('succeeds for zero', () {
        final result = ValidationUtils.requireNonNull<int>(0, 'value');
        expect(result.isSuccess, isTrue);
      });

      test('succeeds for empty string', () {
        final result = ValidationUtils.requireNonNull<String>('', 'value');
        expect(result.isSuccess, isTrue);
      });

      test('fails for null', () {
        final result = ValidationUtils.requireNonNull<int>(null, 'value');
        expect(result.isFailure, isTrue);
        final error = (result as Failure).error;
        expect(error.message, contains('null'));
        expect(error.context?['field'], equals('value'));
      });
    });

    group('validateNotEmpty', () {
      test('succeeds for non-empty list', () {
        final result = ValidationUtils.validateNotEmpty([1, 2, 3], 'list');
        expect(result.isSuccess, isTrue);
      });

      test('fails for empty list', () {
        final result = ValidationUtils.validateNotEmpty([], 'list');
        expect(result.isFailure, isTrue);
        final error = (result as Failure).error;
        expect(error.message, contains('empty'));
      });
    });

    group('validateSize', () {
      test('succeeds when size in range', () {
        final result = ValidationUtils.validateSize([1, 2, 3], min: 1, max: 5);
        expect(result.isSuccess, isTrue);
      });

      test('succeeds when size equals min', () {
        final result = ValidationUtils.validateSize([1, 2], min: 2, max: 5);
        expect(result.isSuccess, isTrue);
      });

      test('succeeds when size equals max', () {
        final result = ValidationUtils.validateSize([1, 2, 3], min: 1, max: 3);
        expect(result.isSuccess, isTrue);
      });

      test('fails when size below min', () {
        final result = ValidationUtils.validateSize([1], min: 2, max: 5);
        expect(result.isFailure, isTrue);
        final error = (result as Failure).error;
        expect(error.message, contains('minimum'));
        expect(error.context?['size'], equals(1));
        expect(error.context?['min'], equals(2));
      });

      test('fails when size above max', () {
        final result =
            ValidationUtils.validateSize([1, 2, 3, 4], min: 1, max: 3);
        expect(result.isFailure, isTrue);
        final error = (result as Failure).error;
        expect(error.message, contains('maximum'));
      });

      test('works with only min constraint', () {
        final result = ValidationUtils.validateSize([1, 2], min: 2);
        expect(result.isSuccess, isTrue);

        final failResult = ValidationUtils.validateSize([1], min: 2);
        expect(failResult.isFailure, isTrue);
      });

      test('works with only max constraint', () {
        final result = ValidationUtils.validateSize([1, 2, 3], max: 5);
        expect(result.isSuccess, isTrue);

        final failResult =
            ValidationUtils.validateSize([1, 2, 3, 4, 5, 6], max: 5);
        expect(failResult.isFailure, isTrue);
      });
    });

    group('validateUnique', () {
      test('succeeds for unique elements', () {
        final result = ValidationUtils.validateUnique([1, 2, 3, 4], 'list');
        expect(result.isSuccess, isTrue);
      });

      test('succeeds for empty list', () {
        final result = ValidationUtils.validateUnique([], 'list');
        expect(result.isSuccess, isTrue);
      });

      test('succeeds for single element', () {
        final result = ValidationUtils.validateUnique([42], 'list');
        expect(result.isSuccess, isTrue);
      });

      test('fails for duplicate elements', () {
        final result = ValidationUtils.validateUnique([1, 2, 2, 3], 'list');
        expect(result.isFailure, isTrue);
        final error = (result as Failure).error;
        expect(error.message, contains('duplicate'));
        expect(error.context?['duplicate'], equals(2));
      });

      test('works with strings', () {
        final result = ValidationUtils.validateUnique(['a', 'b', 'c'], 'list');
        expect(result.isSuccess, isTrue);

        final dupResult =
            ValidationUtils.validateUnique(['a', 'b', 'a'], 'list');
        expect(dupResult.isFailure, isTrue);
      });
    });

    group('validate', () {
      test('succeeds when predicate returns true', () {
        final result = ValidationUtils.validate(
          10,
          (v) => v > 0,
          'Value must be positive',
        );
        expect(result.isSuccess, isTrue);
      });

      test('fails when predicate returns false', () {
        final result = ValidationUtils.validate(
          -5,
          (v) => v > 0,
          'Value must be positive',
        );
        expect(result.isFailure, isTrue);
        final error = (result as Failure).error;
        expect(error.message, equals('Value must be positive'));
      });

      test('supports custom error code', () {
        final result = ValidationUtils.validate(
          0,
          (v) => v != 0,
          'Value cannot be zero',
          code: 'ZERO_VALUE',
        );
        expect(result.isFailure, isTrue);
        expect((result as Failure).error.code, equals('ZERO_VALUE'));
      });

      test('supports custom context', () {
        final result = ValidationUtils.validate(
          150,
          (v) => v <= 100,
          'Value out of range',
          context: {'max': 100, 'actual': 150},
        );
        expect(result.isFailure, isTrue);
        expect((result as Failure).error.context?['max'], equals(100));
      });
    });

    group('validateAll', () {
      test('succeeds when all validations pass', () {
        final result = ValidationUtils.validateAll([
          ValidationUtils.validateFinite(1.0, 'x'),
          ValidationUtils.validateFinite(2.0, 'y'),
          ValidationUtils.requireNonNull<int>(42, 'value'),
        ]);
        expect(result.isSuccess, isTrue);
      });

      test('fails on first validation failure', () {
        final result = ValidationUtils.validateAll([
          ValidationUtils.validateFinite(1.0, 'x'),
          ValidationUtils.validateFinite(double.nan, 'y'),
          ValidationUtils.validateFinite(3.0, 'z'), // Should not evaluate
        ]);
        expect(result.isFailure, isTrue);
        final error = (result as Failure).error;
        expect(error.context?['field'], equals('y'));
      });

      test('succeeds for empty list', () {
        final result = ValidationUtils.validateAll([]);
        expect(result.isSuccess, isTrue);
      });
    });

    group('validateList', () {
      test('succeeds when all items pass validation', () {
        final result = ValidationUtils.validateList<double>(
          [1.0, 2.0, 3.0],
          (v) => ValidationUtils.validateFinite(v, 'item'),
        );
        expect(result.isSuccess, isTrue);
      });

      test('fails on first invalid item', () {
        final result = ValidationUtils.validateList<double>(
          [1.0, double.nan, 3.0],
          (v) => ValidationUtils.validateFinite(v, 'item'),
        );
        expect(result.isFailure, isTrue);
      });

      test('succeeds for empty list', () {
        final result = ValidationUtils.validateList<int>(
          [],
          (v) => ValidationUtils.requireNonNull(v, 'item'),
        );
        expect(result.isSuccess, isTrue);
      });
    });

    group('Integration scenarios', () {
      test('combine multiple validations', () {
        final value = 42.0;
        final result = ValidationUtils.validateAll([
          ValidationUtils.requireNonNull(value, 'value'),
          ValidationUtils.validateFinite(value, 'value'),
          ValidationUtils.validate(
            value,
            (v) => v >= 0 && v <= 100,
            'Value must be 0-100',
          ),
        ]);
        expect(result.isSuccess, isTrue);
      });

      test('validation chain stops at first failure', () {
        var validationCount = 0;

        // Create validations that track execution
        final validations = [
          ValidationUtils.validate(
            10,
            (v) {
              validationCount++;
              return v > 0;
            },
            'Must be positive',
          ),
          ValidationUtils.validate(
            10,
            (v) {
              validationCount++;
              return v < 5; // This fails
            },
            'Must be less than 5',
          ),
          ValidationUtils.validate(
            10,
            (v) {
              validationCount++;
              return v != 10; // Should not execute
            },
            'Must not be 10',
          ),
        ];

        final result = ValidationUtils.validateAll(validations);

        expect(result.isFailure, isTrue);
        // All validations are evaluated upfront, so count should be 3
        expect(validationCount, equals(3));
      });
    });
  });
}
