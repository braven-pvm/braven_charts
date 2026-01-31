import '../models/chart_configuration.dart';

/// Validation error with code and message.
///
/// Used to report validation failures that prevent chart creation.
class ValidationError {
  /// Error code for categorization (e.g., 'V003', 'V004').
  final String code;

  /// Human-readable error message.
  final String message;

  /// Creates a [ValidationError] with the given code and message.
  const ValidationError({required this.code, required this.message});

  @override
  String toString() => '$code: $message';
}

/// Validation warning with code and message.
///
/// Used to report non-blocking issues that should be addressed.
class ValidationWarning {
  /// Warning code for categorization (e.g., 'V001', 'V002').
  final String code;

  /// Human-readable warning message.
  final String message;

  /// Creates a [ValidationWarning] with the given code and message.
  const ValidationWarning({required this.code, required this.message});

  @override
  String toString() => '$code: $message';
}

/// Result of schema validation.
///
/// Contains lists of errors and warnings, and a convenience property
/// to check if the schema is valid.
class ValidationResult {
  /// List of validation errors.
  final List<ValidationError> errors;

  /// List of validation warnings.
  final List<ValidationWarning> warnings;

  /// Creates a [ValidationResult] with the given errors and warnings.
  const ValidationResult({
    this.errors = const [],
    this.warnings = const [],
  });

  /// Whether the schema is valid (no errors).
  bool get isValid => errors.isEmpty;
}

/// Schema validator for ChartConfiguration.
///
/// Validates chart configurations against the v2 schema rules:
/// - V001: Warning when perSeries mode has chart-level yAxis
/// - V002: Warning when perSeries mode has series without yAxis
/// - V003: Error when duplicate series IDs exist
/// - V004: Error when duplicate annotation IDs exist
///
/// This is a stub implementation that always returns an empty result.
/// The real implementation will be added in the green phase.
class SchemaValidator {
  /// Validates the given chart configuration.
  ///
  /// Returns a [ValidationResult] with any errors and warnings found.
  ///
  /// **STUB IMPLEMENTATION**: Always returns empty result.
  /// Real validation will be implemented in the green phase.
  static ValidationResult validate(ChartConfiguration chart) {
    // TODO: Implement V001-V004 validation rules
    // This stub ensures tests compile but fail at runtime
    return const ValidationResult();
  }
}
