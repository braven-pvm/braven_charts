// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Error type categorization for charting operations.
enum ErrorType {
  /// Validation errors (invalid data, constraints violated).
  validation,

  /// Rendering errors (canvas operations, layout failures).
  rendering,

  /// Calculation errors (math operations, statistical computations).
  calculation,

  /// Configuration errors (invalid settings, missing required config).
  configuration,

  /// Internal errors (unexpected state, system failures).
  internal,
}

/// Error severity levels for error handling and logging.
enum ErrorSeverity {
  /// Warning - operation can continue with degraded functionality.
  warning,

  /// Error - operation failed but system is stable.
  error,

  /// Critical - system is in invalid state, immediate action required.
  critical,
}

/// Immutable error representation for chart operations.
///
/// Provides structured error information with categorization, severity,
/// and optional context for debugging and error reporting.
///
/// Example:
/// ```dart
/// final error = ChartError.validation(
///   'Data range invalid',
///   code: 'RANGE_001',
///   context: {'min': 10, 'max': 5},
/// );
/// ```
class ChartError {
  /// The category of error.
  final ErrorType type;

  /// The severity level of the error.
  final ErrorSeverity severity;

  /// Human-readable error message.
  final String message;

  /// Optional error code for programmatic handling.
  final String? code;

  /// Optional context map for debugging (e.g., invalid values, stack traces).
  final Map<String, dynamic>? context;

  /// Optional stack trace for debugging.
  final StackTrace? stackTrace;

  const ChartError({
    required this.type,
    required this.severity,
    required this.message,
    this.code,
    this.context,
    this.stackTrace,
  });

  /// Create a validation error (invalid data, constraints).
  ///
  /// Default severity: error
  factory ChartError.validation(
    String message, {
    String? code,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) =>
      ChartError(
        type: ErrorType.validation,
        severity: ErrorSeverity.error,
        message: message,
        code: code,
        context: context,
        stackTrace: stackTrace,
      );

  /// Create a rendering error (canvas operations, layout).
  ///
  /// Default severity: error
  factory ChartError.rendering(
    String message, {
    String? code,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) =>
      ChartError(
        type: ErrorType.rendering,
        severity: ErrorSeverity.error,
        message: message,
        code: code,
        context: context,
        stackTrace: stackTrace,
      );

  /// Create a calculation error (math, statistics).
  ///
  /// Default severity: error
  factory ChartError.calculation(
    String message, {
    String? code,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) =>
      ChartError(
        type: ErrorType.calculation,
        severity: ErrorSeverity.error,
        message: message,
        code: code,
        context: context,
        stackTrace: stackTrace,
      );

  /// Create a configuration error (invalid settings).
  ///
  /// Default severity: error
  factory ChartError.configuration(
    String message, {
    String? code,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) =>
      ChartError(
        type: ErrorType.configuration,
        severity: ErrorSeverity.error,
        message: message,
        code: code,
        context: context,
        stackTrace: stackTrace,
      );

  /// Create an internal error (unexpected state, system failure).
  ///
  /// Default severity: critical
  factory ChartError.internal(
    String message, {
    String? code,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) =>
      ChartError(
        type: ErrorType.internal,
        severity: ErrorSeverity.critical,
        message: message,
        code: code,
        context: context,
        stackTrace: stackTrace,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartError &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          severity == other.severity &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => Object.hash(type, severity, message, code);

  @override
  String toString() {
    final buffer = StringBuffer('ChartError(');
    buffer.write('type: $type, ');
    buffer.write('severity: $severity, ');
    buffer.write('message: "$message"');
    if (code != null) {
      buffer.write(', code: $code');
    }
    if (context != null && context!.isNotEmpty) {
      buffer.write(', context: $context');
    }
    buffer.write(')');
    return buffer.toString();
  }
}
