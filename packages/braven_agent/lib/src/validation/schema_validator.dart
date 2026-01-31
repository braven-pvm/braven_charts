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

/// Schema validator for ChartConfiguration (V2 Schema).
///
/// Validates chart configurations against the V2 agentic schema rules.
/// Returns [ValidationResult] containing errors (blocking) and warnings
/// (non-blocking with actionable guidance).
///
/// ## Validation Code Reference
///
/// ### Chart Structure Warnings (V001-V002)
///
/// | Code | Type | Description |
/// |------|------|-------------|
/// | V001 | Warning | Chart-level yAxis ignored in perSeries mode |
/// | V002 | Warning | Series lacks yAxis in perSeries mode |
///
/// ### Uniqueness Errors (V003-V004)
///
/// | Code | Type | Description |
/// |------|------|-------------|
/// | V003 | Error | Duplicate series IDs |
/// | V004 | Error | Duplicate annotation IDs |
///
/// ### Modification Validation (V010-V022)
///
/// | Code | Type | Description |
/// |------|------|-------------|
/// | V010 | Error | update.series[].id not found |
/// | V011 | Error | remove.series contains non-existent ID |
/// | V012 | Error | add.series[].id already exists |
/// | V020 | Error | update.annotations[].id not found |
/// | V021 | Error | remove.annotations contains non-existent ID |
/// | V022 | Warning | Agent supplied annotation ID (ignored) |
///
/// ### Annotation Validation (V030-V044)
///
/// | Code | Type | Description |
/// |------|------|-------------|
/// | V030 | Error | seriesId references non-existent series |
/// | V031 | Error | Point annotation lacks seriesId |
/// | V032 | Error | Marker annotation lacks seriesId |
/// | V033 | Error | Horizontal referenceLine in perSeries mode lacks seriesId |
/// | V034 | Error | Horizontal zone in perSeries mode lacks seriesId |
/// | V040 | Error | ReferenceLine lacks value |
/// | V041 | Error | Zone lacks minValue or maxValue |
/// | V042 | Error | Marker with seriesId lacks dataPointIndex or x/y |
/// | V043 | Error | dataPointIndex out of range |
/// | V044 | Error | TextLabel lacks text |
///
/// ## Usage
///
/// ```dart
/// final result = SchemaValidator.validate(chart);
/// if (!result.isValid) {
///   for (final error in result.errors) {
///     print('${error.code}: ${error.message}');
///   }
/// }
/// ```
///
/// See also:
/// - [CreateChartTool] and [ModifyChartTool] which use this validator
/// - [ValidationResult] for the return type structure
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

    // US4: V030-V044 annotation validation rules
    _validateUS4AnnotationRules(chart, errors);

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

  /// US4: Validates annotation references and type-specific requirements.
  ///
  /// Validates V030-V044 rules:
  /// - V030: Error when annotation's seriesId references non-existent series
  /// - V031: Error when point annotation lacks seriesId
  /// - V032: Error when marker annotation lacks seriesId
  /// - V033: Error when horizontal referenceLine in perSeries mode lacks seriesId
  /// - V034: Error when horizontal zone in perSeries mode lacks seriesId
  /// - V040: Error when referenceLine annotation lacks value
  /// - V041: Error when zone annotation lacks minValue or maxValue
  /// - V042: Error when point-style annotation lacks dataPointIndex
  /// - V043: Error when dataPointIndex is out of range
  /// - V044: Error when textLabel annotation lacks text
  static void _validateUS4AnnotationRules(
    ChartConfiguration chart,
    List<ValidationError> errors,
  ) {
    // Build lookup structures for validation
    final seriesMap = <String, int>{};
    for (final series in chart.series) {
      seriesMap[series.id] = series.data.length;
    }

    final isPerSeriesMode =
        chart.normalizationMode == NormalizationModeConfig.perSeries;

    for (final annotation in chart.annotations) {
      // V030: Error when annotation's seriesId references non-existent series
      if (annotation.seriesId != null &&
          annotation.seriesId!.isNotEmpty &&
          !seriesMap.containsKey(annotation.seriesId)) {
        errors.add(
          ValidationError(
            code: 'V030',
            message:
                "Annotation references non-existent series '${annotation.seriesId}'. "
                'Use get_chart to discover valid series IDs.',
          ),
        );
        // Skip further validation for this annotation since seriesId is invalid
        continue;
      }

      // V031: Error when point annotation (marker with dataPointIndex) lacks seriesId
      if (annotation.type == AnnotationType.marker &&
          annotation.dataPointIndex != null &&
          (annotation.seriesId == null || annotation.seriesId!.isEmpty)) {
        errors.add(
          const ValidationError(
            code: 'V031',
            message:
                'Point annotation with dataPointIndex requires seriesId to identify '
                'which series the data point belongs to.',
          ),
        );
      }

      // V032: Error when marker annotation lacks seriesId
      if (annotation.type == AnnotationType.marker &&
          annotation.dataPointIndex == null &&
          (annotation.seriesId == null || annotation.seriesId!.isEmpty)) {
        errors.add(
          const ValidationError(
            code: 'V032',
            message:
                'Marker annotation requires seriesId for coordinate resolution.',
          ),
        );
      }

      // V033: Error when horizontal referenceLine in perSeries mode lacks seriesId
      if (annotation.type == AnnotationType.referenceLine &&
          annotation.orientation == Orientation.horizontal &&
          isPerSeriesMode &&
          (annotation.seriesId == null || annotation.seriesId!.isEmpty)) {
        errors.add(
          const ValidationError(
            code: 'V033',
            message:
                'Horizontal referenceLine requires seriesId in perSeries normalization mode.',
          ),
        );
      }

      // V034: Error when horizontal zone in perSeries mode lacks seriesId
      if (annotation.type == AnnotationType.zone &&
          annotation.orientation == Orientation.horizontal &&
          isPerSeriesMode &&
          (annotation.seriesId == null || annotation.seriesId!.isEmpty)) {
        errors.add(
          const ValidationError(
            code: 'V034',
            message:
                'Horizontal zone requires seriesId in perSeries normalization mode.',
          ),
        );
      }

      // V040: Error when referenceLine annotation lacks value
      if (annotation.type == AnnotationType.referenceLine &&
          annotation.value == null) {
        errors.add(
          const ValidationError(
            code: 'V040',
            message: 'ReferenceLine requires value property.',
          ),
        );
      }

      // V041: Error when zone annotation lacks minValue or maxValue
      if (annotation.type == AnnotationType.zone &&
          (annotation.minValue == null || annotation.maxValue == null)) {
        errors.add(
          const ValidationError(
            code: 'V041',
            message: 'Zone requires both minValue and maxValue properties.',
          ),
        );
      }

      // V042: Error when marker with seriesId lacks dataPointIndex and x/y coordinates
      if (annotation.type == AnnotationType.marker &&
          annotation.seriesId != null &&
          annotation.seriesId!.isNotEmpty &&
          annotation.dataPointIndex == null &&
          annotation.x == null &&
          annotation.y == null) {
        errors.add(
          const ValidationError(
            code: 'V042',
            message:
                'Marker annotation with seriesId requires dataPointIndex or x/y coordinates.',
          ),
        );
      }

      // V043: Error when dataPointIndex is out of range
      if (annotation.dataPointIndex != null && annotation.seriesId != null) {
        final dataLength = seriesMap[annotation.seriesId];
        if (dataLength != null) {
          if (annotation.dataPointIndex! < 0) {
            errors.add(
              ValidationError(
                code: 'V043',
                message:
                    'dataPointIndex ${annotation.dataPointIndex} is invalid. '
                    'Index must be >= 0.',
              ),
            );
          } else if (annotation.dataPointIndex! >= dataLength) {
            errors.add(
              ValidationError(
                code: 'V043',
                message:
                    'dataPointIndex ${annotation.dataPointIndex} out of range for series '
                    "'${annotation.seriesId}' which has $dataLength points.",
              ),
            );
          }
        }
      }

      // V044: Error when textLabel annotation lacks text
      if (annotation.type == AnnotationType.textLabel &&
          (annotation.text == null || annotation.text!.isEmpty)) {
        errors.add(
          const ValidationError(
            code: 'V044',
            message: 'TextLabel requires text property.',
          ),
        );
      }
    }
  }

  /// Validates a modification request against an existing chart.
  ///
  /// Validates V010-V022 rules for update/add/remove operations:
  /// - V010: Error when update.series[].id not found
  /// - V011: Error when remove.series contains non-existent ID
  /// - V012: Error when add.series[].id already exists
  /// - V020: Error when update.annotations[].id not found
  /// - V021: Error when remove.annotations contains non-existent ID
  /// - V022: Warning when agent supplies id on add.annotations
  ///
  /// [TDD RED PHASE STUB] This method will be implemented in the GREEN phase.
  static ValidationResult validateModification(
    ChartConfiguration chart,
    ModificationRequest request,
  ) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];

    final existingSeriesIds = chart.series.map((s) => s.id).toSet();
    final existingAnnotationIds = chart.annotations
        .map((a) => a.id)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    final removeSeriesIds = request.remove?.series?.toSet() ?? <String>{};
    final removeAnnotationIds =
        request.remove?.annotations?.toSet() ?? <String>{};

    // V011: Error when remove.series contains non-existent ID
    for (final id in removeSeriesIds) {
      if (!existingSeriesIds.contains(id)) {
        errors.add(
          ValidationError(
            code: 'V011',
            message: "Cannot remove series '$id' because it does not exist.",
          ),
        );
      }
    }

    // V021: Error when remove.annotations contains non-existent ID
    for (final id in removeAnnotationIds) {
      if (!existingAnnotationIds.contains(id)) {
        errors.add(
          ValidationError(
            code: 'V021',
            message:
                "Cannot remove annotation '$id' because it does not exist.",
          ),
        );
      }
    }

    // Effective IDs after remove (remove -> add -> update order)
    final effectiveSeriesIds = existingSeriesIds.difference(removeSeriesIds);
    final effectiveAnnotationIds =
        existingAnnotationIds.difference(removeAnnotationIds);

    // V012: Error when add.series[].id already exists
    final addSeries = request.add?.series ?? const <SeriesAddition>[];
    for (final series in addSeries) {
      if (effectiveSeriesIds.contains(series.id)) {
        errors.add(
          ValidationError(
            code: 'V012',
            message:
                "Cannot add series '${series.id}' because it already exists.",
          ),
        );
      } else {
        effectiveSeriesIds.add(series.id);
      }
    }

    // V022: Warning when agent supplies id on add.annotations
    final addAnnotations =
        request.add?.annotations ?? const <AnnotationAddition>[];
    for (final annotation in addAnnotations) {
      if (annotation.id != null && annotation.id!.isNotEmpty) {
        warnings.add(
          const ValidationWarning(
            code: 'V022',
            message:
                'Annotation IDs are system-generated; the supplied id will be ignored.',
          ),
        );
      }
    }

    // V010: Error when update.series[].id not found
    final updateSeries = request.update?.series ?? const <SeriesModification>[];
    for (final update in updateSeries) {
      if (!effectiveSeriesIds.contains(update.id)) {
        errors.add(
          ValidationError(
            code: 'V010',
            message:
                "Cannot update series '${update.id}' because it does not exist.",
          ),
        );
      }
    }

    // V020: Error when update.annotations[].id not found
    final updateAnnotations =
        request.update?.annotations ?? const <AnnotationModification>[];
    for (final update in updateAnnotations) {
      if (!effectiveAnnotationIds.contains(update.id)) {
        errors.add(
          ValidationError(
            code: 'V020',
            message:
                "Cannot update annotation '${update.id}' because it does not exist.",
          ),
        );
      }
    }

    return ValidationResult(errors: errors, warnings: warnings);
  }
}

// ============================================================
// Modification Request Types
// ============================================================
// These types represent modification operations for validateModification.

/// Request object for chart modifications.
///
/// Contains optional [update], [add], and [remove] operations that are
/// applied in the order: remove → add → update.
///
/// Used by [SchemaValidator.validateModification] to validate operations
/// before they are applied by [ModifyChartTool].
class ModificationRequest {
  final UpdateOperation? update;
  final AddOperation? add;
  final RemoveOperation? remove;

  const ModificationRequest({
    this.update,
    this.add,
    this.remove,
  });
}

/// Update operation containing series and annotation modifications.
///
/// Each item in [series] or [annotations] must have an `id` field
/// identifying the existing item to update. Validated by V010/V020.
class UpdateOperation {
  final List<SeriesModification>? series;
  final List<AnnotationModification>? annotations;

  const UpdateOperation({
    this.series,
    this.annotations,
  });
}

/// Add operation containing new series and annotations.
///
/// New series must have unique IDs (validated by V012).
/// Annotation IDs are system-generated (V022 warns if supplied).
class AddOperation {
  final List<SeriesAddition>? series;
  final List<AnnotationAddition>? annotations;

  const AddOperation({
    this.series,
    this.annotations,
  });
}

/// Remove operation containing series and annotation IDs to remove.
///
/// IDs must reference existing items (validated by V011/V021).
class RemoveOperation {
  final List<String>? series;
  final List<String>? annotations;

  const RemoveOperation({
    this.series,
    this.annotations,
  });
}

/// Modification for an existing series.
///
/// The [id] field identifies the series to update. Other fields are
/// optional and only specified fields are updated (deep merge for yAxis).
class SeriesModification {
  final String id;
  final String? name;
  final String? color;
  final Map<String, dynamic>? yAxis;

  const SeriesModification({
    required this.id,
    this.name,
    this.color,
    this.yAxis,
  });
}

/// Modification for an existing annotation.
///
/// The [id] field identifies the annotation to update. Use [GetChartTool]
/// to discover annotation IDs before calling modify_chart.
class AnnotationModification {
  final String id;
  final String? label;
  final String? color;
  final double? value;

  const AnnotationModification({
    required this.id,
    this.label,
    this.color,
    this.value,
  });
}

/// New series to add.
///
/// The [id] must be unique (validated by V012). The [data] array
/// contains [DataPoint] objects.
class SeriesAddition {
  final String id;
  final List<dynamic> data;
  final String? name;
  final String? color;

  const SeriesAddition({
    required this.id,
    required this.data,
    this.name,
    this.color,
  });
}

/// New annotation to add.
///
/// The [id] field is ignored if supplied (V022 warning); the system
/// generates a unique UUID for each new annotation.
class AnnotationAddition {
  final String? id;
  final AnnotationType type;
  final double? value;
  final Orientation? orientation;
  final String? label;

  const AnnotationAddition({
    this.id,
    required this.type,
    this.value,
    this.orientation,
    this.label,
  });
}
