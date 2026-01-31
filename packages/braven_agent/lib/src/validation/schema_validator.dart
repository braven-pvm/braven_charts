import '../models/chart_configuration.dart';
import '../models/enums.dart';

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
class SchemaValidator {
  /// Validates the given chart configuration.
  ///
  /// Returns a [ValidationResult] with any errors and warnings found.
  static ValidationResult validate(ChartConfiguration chart) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];

    // V001: Warning when perSeries mode has chart-level yAxis
    _validateV001(chart, warnings);

    // V002: Warning when perSeries mode has series without yAxis
    _validateV002(chart, warnings);

    // V003: Error when duplicate series IDs exist
    _validateV003(chart, errors);

    // V004: Error when duplicate annotation IDs exist
    _validateV004(chart, errors);

    return ValidationResult(errors: errors, warnings: warnings);
  }

  /// V001: Warning when perSeries mode has chart-level yAxis.
  ///
  /// In perSeries normalization mode, chart-level yAxes[] is ignored
  /// because each series defines its own axis. Emit a warning to alert
  /// the user that their chart-level yAxis configuration will be ignored.
  static void _validateV001(
    ChartConfiguration chart,
    List<ValidationWarning> warnings,
  ) {
    if (chart.normalizationMode == NormalizationModeConfig.perSeries &&
        chart.yAxes.isNotEmpty) {
      warnings.add(
        const ValidationWarning(
          code: 'V001',
          message:
              'Chart-level yAxis is ignored in perSeries normalization mode. '
              'Use series[].yAxis to configure per-series axes instead.',
        ),
      );
    }
  }

  /// V002: Warning when perSeries mode has series without yAxis.
  ///
  /// In perSeries normalization mode, each series should have its own
  /// yAxis configuration. If a series lacks yAxis, it will use a default
  /// axis which may not be the user's intent. Emit a warning for each
  /// series missing yAxis.
  static void _validateV002(
    ChartConfiguration chart,
    List<ValidationWarning> warnings,
  ) {
    if (chart.normalizationMode != NormalizationModeConfig.perSeries) {
      return;
    }

    for (final series in chart.series) {
      if (series.yAxis == null) {
        warnings.add(
          ValidationWarning(
            code: 'V002',
            message:
                "Series '${series.id}' has no yAxis config in perSeries mode. "
                'It will use a default axis. Consider adding a yAxis configuration.',
          ),
        );
      }
    }
  }

  /// V003: Error when duplicate series IDs exist.
  ///
  /// All series must have unique IDs for proper identification and
  /// annotation targeting. Duplicate IDs will cause undefined behavior.
  static void _validateV003(
    ChartConfiguration chart,
    List<ValidationError> errors,
  ) {
    final seenIds = <String>{};
    final duplicates = <String>{};

    for (final series in chart.series) {
      if (seenIds.contains(series.id)) {
        duplicates.add(series.id);
      } else {
        seenIds.add(series.id);
      }
    }

    for (final id in duplicates) {
      errors.add(
        ValidationError(
          code: 'V003',
          message: "Duplicate series ID: '$id'. Each series must have a "
              'unique ID for proper identification.',
        ),
      );
    }
  }

  /// V004: Error when duplicate annotation IDs exist.
  ///
  /// All annotations with IDs must have unique IDs. Annotations without
  /// IDs are fine (system will generate them). Duplicate IDs among
  /// annotations with explicit IDs cause undefined behavior.
  static void _validateV004(
    ChartConfiguration chart,
    List<ValidationError> errors,
  ) {
    final seenIds = <String>{};
    final duplicates = <String>{};

    for (final annotation in chart.annotations) {
      final id = annotation.id;
      if (id == null || id.isEmpty) {
        // No ID is fine - system will generate one
        continue;
      }

      if (seenIds.contains(id)) {
        duplicates.add(id);
      } else {
        seenIds.add(id);
      }
    }

    for (final id in duplicates) {
      errors.add(
        ValidationError(
          code: 'V004',
          message: "Duplicate annotation ID: '$id'. Each annotation must have "
              'a unique ID for proper identification.',
        ),
      );
    }
  }
}
