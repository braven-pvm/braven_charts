// Contract: Type System (FR-003)
// This file defines API contracts for type-safe error handling and validation.
//
// NOTE: This is a CONTRACT file, not an implementation.
// Implementation will use Dart 3.0 sealed classes for exhaustive pattern matching.

/// ChartResult<T> Contract (FR-003.1)
///
/// Type-safe success/failure result wrapper (no exceptions).
///
/// MUST:
/// - Use sealed class pattern (Dart 3.0)
/// - Support Success and Failure variants
/// - Enable exhaustive pattern matching
/// - Provide chainable operations (map, flatMap)
/// - Not throw exceptions for expected failures
sealed class ChartResult<T> {
  const ChartResult();

  /// Pattern match on result type
  R when<R>({
    required R Function(T value) success,
    required R Function(ChartError error) failure,
  });

  /// Get value or null if failure
  T? getOrNull();

  /// Get value or default if failure
  T getOrElse(T defaultValue);

  /// Get value or compute from error if failure
  T getOrElseGet(T Function(ChartError) onFailure);

  /// Transform success value
  ChartResult<R> map<R>(R Function(T value) transform);

  /// Chain operations (flatMap/bind)
  ChartResult<R> flatMap<R>(ChartResult<R> Function(T value) transform);

  /// Fold both cases
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(ChartError error) onFailure,
  });

  /// Check if this is a success
  bool get isSuccess;

  /// Check if this is a failure
  bool get isFailure;
}

/// Success variant - Holds the successful value
final class Success<T> extends ChartResult<T> {
  final T value;

  const Success(this.value);

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(ChartError error) failure,
  }) =>
      success(value);

  @override
  T? getOrNull() => value;

  @override
  T getOrElse(T defaultValue) => value;

  @override
  T getOrElseGet(T Function(ChartError) onFailure) => value;

  @override
  ChartResult<R> map<R>(R Function(T value) transform) => Success(transform(value));

  @override
  ChartResult<R> flatMap<R>(ChartResult<R> Function(T value) transform) => transform(value);

  @override
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(ChartError error) onFailure,
  }) =>
      onSuccess(value);

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Success<T> && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Failure variant - Holds the error information
final class Failure<T> extends ChartResult<T> {
  final ChartError error;

  const Failure(this.error);

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(ChartError error) failure,
  }) =>
      failure(error);

  @override
  T? getOrNull() => null;

  @override
  T getOrElse(T defaultValue) => defaultValue;

  @override
  T getOrElseGet(T Function(ChartError) onFailure) => onFailure(error);

  @override
  ChartResult<R> map<R>(R Function(T value) transform) => Failure(error);

  @override
  ChartResult<R> flatMap<R>(ChartResult<R> Function(T value) transform) => Failure(error);

  @override
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(ChartError error) onFailure,
  }) =>
      onFailure(error);

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Failure<T> && error == other.error;

  @override
  int get hashCode => error.hashCode;
}

/// ChartError Contract (FR-003.2)
///
/// Categorized error representation with context.
///
/// MUST:
/// - Categorize errors by type
/// - Indicate severity level
/// - Provide human-readable messages
/// - Include machine-readable codes
/// - Preserve stack traces for debugging
class ChartError {
  final ErrorType type;
  final ErrorSeverity severity;
  final String message;
  final String code;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;

  const ChartError({
    required this.type,
    required this.severity,
    required this.message,
    required this.code,
    this.stackTrace,
    this.context,
  });

  /// Factory: Validation error
  factory ChartError.validation(
    String message, {
    String? code,
    Map<String, dynamic>? context,
  }) =>
      ChartError(
        type: ErrorType.validation,
        severity: ErrorSeverity.error,
        message: message,
        code: code ?? 'VAL_UNKNOWN_001',
        context: context,
      );

  /// Factory: Rendering error
  factory ChartError.rendering(
    String message, {
    String? code,
    Map<String, dynamic>? context,
  }) =>
      ChartError(
        type: ErrorType.rendering,
        severity: ErrorSeverity.error,
        message: message,
        code: code ?? 'REN_UNKNOWN_001',
        context: context,
      );

  /// Factory: Calculation error
  factory ChartError.calculation(
    String message, {
    String? code,
    Map<String, dynamic>? context,
  }) =>
      ChartError(
        type: ErrorType.calculation,
        severity: ErrorSeverity.error,
        message: message,
        code: code ?? 'CAL_UNKNOWN_001',
        context: context,
      );

  /// Factory: Internal error
  factory ChartError.internal(
    String message, {
    String? code,
    StackTrace? stackTrace,
  }) =>
      ChartError(
        type: ErrorType.internal,
        severity: ErrorSeverity.critical,
        message: message,
        code: code ?? 'INT_UNKNOWN_001',
        stackTrace: stackTrace,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartError && type == other.type && severity == other.severity && message == other.message && code == other.code;

  @override
  int get hashCode => Object.hash(type, severity, message, code);

  @override
  String toString() => '[$code] $message (${type.name}/${severity.name})';
}

/// Error type categorization
enum ErrorType {
  validation, // Invalid input data
  rendering, // Rendering failure
  calculation, // Math/computation error
  configuration, // Invalid configuration
  internal, // Internal library error
}

/// Error severity levels
enum ErrorSeverity {
  warning, // Non-fatal issue
  error, // Operation failed
  critical, // System integrity issue
}

/// ValidationUtils Contract (FR-003.3)
///
/// Data validation utilities for input checking.
///
/// All methods return ChartResult for composable validation.
abstract class ValidationUtils {
  // Range validation
  static ChartResult<void> validateRange(
    double value,
    double min,
    double max, {
    String? fieldName,
  }) =>
      throw UnimplementedError('Contract only');

  static ChartResult<void> validatePositive(
    double value, {
    String? fieldName,
  }) =>
      throw UnimplementedError('Contract only');

  // Null safety
  static ChartResult<T> requireNonNull<T>(
    T? value,
    String fieldName,
  ) =>
      throw UnimplementedError('Contract only');

  static ChartResult<List<T>> validateList<T>(
    List<T>? list, {
    String? fieldName,
  }) =>
      throw UnimplementedError('Contract only');

  // NaN/Infinity detection
  static bool isFiniteNumber(double value) => throw UnimplementedError('Contract only');

  static ChartResult<double> validateFinite(
    double value, {
    String? fieldName,
  }) =>
      throw UnimplementedError('Contract only');

  static double sanitizeNumber(
    double value, {
    double fallback = 0.0,
  }) =>
      throw UnimplementedError('Contract only');

  // Collection validation
  static ChartResult<void> validateNotEmpty<T>(
    List<T> list, {
    String? fieldName,
  }) =>
      throw UnimplementedError('Contract only');

  static ChartResult<void> validateSize<T>(
    List<T> list,
    int maxSize, {
    String? fieldName,
  }) =>
      throw UnimplementedError('Contract only');

  static ChartResult<void> validateUnique<T>(
    List<T> list, {
    String? fieldName,
  }) =>
      throw UnimplementedError('Contract only');

  // Custom validation
  static ChartResult<T> validate<T>(
    T value,
    bool Function(T) predicate,
    String errorMessage,
  ) =>
      throw UnimplementedError('Contract only');

  // Composable validation chain
  static ChartResult<T> validateAll<T>(
    T value,
    List<ChartResult<void> Function(T)> validators,
  ) =>
      throw UnimplementedError('Contract only');
}
