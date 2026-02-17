// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'chart_error.dart';

/// Sealed class for type-safe error handling using Result pattern.
///
/// Provides compile-time exhaustive pattern matching and functional operations
/// for composable error handling throughout the charting library.
///
/// Example:
/// ```dart
/// ChartResult<DataRange> validateRange(double min, double max) {
///   if (min > max) {
///     return Failure(ChartError.validation('min must be <= max'));
///   }
///   return Success(DataRange(min, max));
/// }
///
/// final result = validateRange(0, 100);
/// final display = result.when(
///   success: (range) => 'Range: ${range.min}-${range.max}',
///   failure: (error) => 'Error: ${error.message}',
/// );
/// ```
sealed class ChartResult<T> {
  const ChartResult();

  /// Returns true if this is a Success variant.
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a Failure variant.
  bool get isFailure => this is Failure<T>;

  /// Pattern match on Success or Failure with exhaustive checking.
  ///
  /// The Dart compiler ensures both cases are handled.
  R when<R>({
    required R Function(T value) success,
    required R Function(ChartError error) failure,
  }) {
    final self = this;
    if (self is Success<T>) {
      return success(self.value);
    } else if (self is Failure<T>) {
      return failure(self.error);
    }
    // Unreachable due to sealed class, but required for exhaustiveness
    throw StateError('Unreachable: ChartResult must be Success or Failure');
  }

  /// Returns the success value or null if this is a Failure.
  T? getOrNull() => when(success: (value) => value, failure: (_) => null);

  /// Returns the success value or the provided default if this is a Failure.
  T getOrElse(T defaultValue) =>
      when(success: (value) => value, failure: (_) => defaultValue);

  /// Transform the success value while preserving failures.
  ///
  /// Example:
  /// ```dart
  /// Success(5).map((x) => x * 2) // Success(10)
  /// Failure(error).map((x) => x * 2) // Failure(error)
  /// ```
  ChartResult<R> map<R>(R Function(T value) transform) => when(
    success: (value) => Success(transform(value)),
    failure: (error) => Failure(error),
  );

  /// Chain operations that return ChartResult.
  ///
  /// Example:
  /// ```dart
  /// Success(5)
  ///   .flatMap((x) => x > 0 ? Success(x * 2) : Failure(...))
  /// ```
  ChartResult<R> flatMap<R>(ChartResult<R> Function(T value) transform) => when(
    success: (value) => transform(value),
    failure: (error) => Failure(error),
  );

  /// Fold both cases into a single value.
  ///
  /// Similar to when() but both branches must return the same type.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(ChartError error) onFailure,
  }) => when(success: onSuccess, failure: onFailure);
}

/// Success variant containing a valid value.
final class Success<T> extends ChartResult<T> {
  /// The successful result value.
  final T value;

  const Success(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// Failure variant containing an error.
final class Failure<T> extends ChartResult<T> {
  /// The error that caused the failure.
  final ChartError error;

  const Failure(this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure($error)';
}
