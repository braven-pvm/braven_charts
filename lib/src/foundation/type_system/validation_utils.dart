// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'chart_error.dart';
import 'chart_result.dart';

/// Static validation utilities returning ChartResult for composable validation.
///
/// All methods return ChartResult<T> to enable chaining and composition.
/// Failed validations return Failure with descriptive ChartError.
///
/// Example:
/// ```dart
/// final result = ValidationUtils.validateAll([
///   ValidationUtils.validateFinite(x, 'x'),
///   ValidationUtils.validateFinite(y, 'y'),
///   ValidationUtils.requireNonNull(label, 'label'),
/// ]);
/// ```
class ValidationUtils {
  // Private constructor - static utility class
  ValidationUtils._();

  /// Check if a number is finite (not NaN or Infinity).
  static bool isFiniteNumber(double value) => !value.isNaN && !value.isInfinite;

  /// Validate that a number is finite.
  ///
  /// Returns Success(value) if finite, Failure if NaN or Infinity.
  static ChartResult<double> validateFinite(double value, String fieldName) {
    if (!isFiniteNumber(value)) {
      return Failure(
        ChartError.validation(
          '$fieldName must be a finite number',
          code: 'INVALID_NUMBER',
          context: {'field': fieldName, 'value': value},
        ),
      );
    }
    return Success(value);
  }

  /// Sanitize a number by replacing NaN/Infinity with a default value.
  ///
  /// Returns the original value if finite, otherwise returns defaultValue.
  static double sanitizeNumber(double value, double defaultValue) => isFiniteNumber(value) ? value : defaultValue;

  /// Validate that a value is non-null.
  ///
  /// Returns Success(value) if non-null, Failure if null.
  static ChartResult<T> requireNonNull<T>(T? value, String fieldName) {
    if (value == null) {
      return Failure(
        ChartError.validation(
          '$fieldName must not be null',
          code: 'NULL_VALUE',
          context: {'field': fieldName},
        ),
      );
    }
    return Success(value);
  }

  /// Validate that a list is not empty.
  ///
  /// Returns Success(list) if non-empty, Failure if empty.
  static ChartResult<List<T>> validateNotEmpty<T>(
    List<T> list,
    String fieldName,
  ) {
    if (list.isEmpty) {
      return Failure(
        ChartError.validation(
          '$fieldName must not be empty',
          code: 'EMPTY_LIST',
          context: {'field': fieldName},
        ),
      );
    }
    return Success(list);
  }

  /// Validate that a collection size is within bounds.
  ///
  /// Returns Success(list) if size is valid, Failure otherwise.
  static ChartResult<List<T>> validateSize<T>(
    List<T> list, {
    int? min,
    int? max,
  }) {
    final size = list.length;

    if (min != null && size < min) {
      return Failure(
        ChartError.validation(
          'Collection size ($size) is less than minimum ($min)',
          code: 'SIZE_TOO_SMALL',
          context: {'size': size, 'min': min},
        ),
      );
    }

    if (max != null && size > max) {
      return Failure(
        ChartError.validation(
          'Collection size ($size) exceeds maximum ($max)',
          code: 'SIZE_TOO_LARGE',
          context: {'size': size, 'max': max},
        ),
      );
    }

    return Success(list);
  }

  /// Validate that all elements in a list are unique.
  ///
  /// Returns Success(list) if all elements are unique, Failure if duplicates found.
  static ChartResult<List<T>> validateUnique<T>(
    List<T> list,
    String fieldName,
  ) {
    final seen = <T>{};
    for (final item in list) {
      if (!seen.add(item)) {
        return Failure(
          ChartError.validation(
            '$fieldName contains duplicate values',
            code: 'DUPLICATE_VALUES',
            context: {'field': fieldName, 'duplicate': item},
          ),
        );
      }
    }
    return Success(list);
  }

  /// Validate using a custom predicate.
  ///
  /// Returns Success(value) if predicate returns true, Failure otherwise.
  static ChartResult<T> validate<T>(
    T value,
    bool Function(T) predicate,
    String errorMessage, {
    String? code,
    Map<String, dynamic>? context,
  }) {
    if (!predicate(value)) {
      return Failure(
        ChartError.validation(
          errorMessage,
          code: code ?? 'VALIDATION_FAILED',
          context: context,
        ),
      );
    }
    return Success(value);
  }

  /// Chain multiple validations together.
  ///
  /// Returns Success(void) if all validations pass, first Failure otherwise.
  ///
  /// Example:
  /// ```dart
  /// ValidationUtils.validateAll([
  ///   ValidationUtils.validateFinite(x, 'x'),
  ///   ValidationUtils.validateFinite(y, 'y'),
  /// ])
  /// ```
  static ChartResult<void> validateAll(List<ChartResult<dynamic>> validations) {
    for (final validation in validations) {
      if (validation.isFailure) {
        final failure = validation as Failure;
        return Failure(failure.error);
      }
    }
    return const Success(null);
  }

  /// Validate a list of values using a predicate.
  ///
  /// Returns Success(list) if all values pass, Failure on first failure.
  static ChartResult<List<T>> validateList<T>(
    List<T> list,
    ChartResult<T> Function(T) validator,
  ) {
    for (final item in list) {
      final result = validator(item);
      if (result.isFailure) {
        return Failure((result as Failure).error);
      }
    }
    return Success(list);
  }
}
