import 'package:flutter/foundation.dart';

import '../artifacts/chart_artifact_diagnostics.dart';
import '../artifacts/chart_document.dart';
import '../artifacts/chart_runtime_bindings.dart';
import '../artifacts/chart_view_state.dart';

/// One explicitly identified document participating in a comparison.
@immutable
class ChartComparisonInput {
  const ChartComparisonInput({
    required this.inputId,
    required this.label,
    required this.document,
    this.viewState,
  }) : assert(inputId != ''),
       assert(label != '');

  final String inputId;
  final String label;
  final ChartDocument document;
  final ChartViewState? viewState;
}

/// Affine conversion supplied explicitly by the host for one unit boundary.
///
/// The converted value is `source * scale + offset`. Source values remain in
/// every comparison row and export; a conversion only adds a derived value.
@immutable
class ChartComparisonUnitConversion {
  const ChartComparisonUnitConversion({
    required this.sourceUnit,
    required this.targetUnit,
    this.scale = 1,
    this.offset = 0,
  }) : assert(sourceUnit != ''),
       assert(targetUnit != '');

  final String sourceUnit;
  final String targetUnit;
  final double scale;
  final double offset;

  double convert(double source) => source * scale + offset;
}

/// Host-declared semantic identity across document-local series IDs.
///
/// Display names are deliberately absent from matching. A unit conversion is
/// keyed by input ID and is used only when [comparisonUnit] is also explicit.
@immutable
class ChartSeriesMatch {
  ChartSeriesMatch({
    required this.semanticKey,
    required Map<String, String> seriesIdByInputId,
    this.comparisonUnit,
    Map<String, ChartComparisonUnitConversion> unitConversionsByInputId =
        const {},
  }) : assert(semanticKey != ''),
       seriesIdByInputId = Map.unmodifiable(seriesIdByInputId),
       unitConversionsByInputId = Map.unmodifiable(unitConversionsByInputId);

  final String semanticKey;
  final Map<String, String> seriesIdByInputId;
  final String? comparisonUnit;
  final Map<String, ChartComparisonUnitConversion> unitConversionsByInputId;
}

/// How points from different documents are grouped into comparison rows.
enum ChartComparisonAlignmentPolicy {
  /// Align only equal raw or explicitly converted numeric X values.
  exactX,

  /// Match timestamped points one-to-one within an explicit tolerance.
  timestampTolerance,

  /// Preserve independent long rows without cross-document alignment.
  none,
}

/// Explicit policy for duplicate exact-X points within one input series.
enum ChartComparisonDuplicatePolicy {
  /// Fail rather than choosing or pairing duplicate values implicitly.
  reject,

  /// Pair the first occurrence with first, second with second, and so on.
  byOccurrence,

  /// Align the first occurrence and retain later occurrences as unaligned rows.
  keepFirst,

  /// Align the last occurrence and retain earlier occurrences as unaligned rows.
  keepLast,
}

/// Pure comparison rules. No option invents or interpolates source values.
@immutable
class ChartComparisonOptions {
  const ChartComparisonOptions({
    this.alignmentPolicy = ChartComparisonAlignmentPolicy.exactX,
    this.duplicatePolicy = ChartComparisonDuplicatePolicy.reject,
    this.baselineInputId,
    this.timestampTolerance,
    this.comparisonXUnit,
    this.xUnitConversionsByInputId = const {},
    this.formatters = const ChartFormatterRegistry(),
  });

  final ChartComparisonAlignmentPolicy alignmentPolicy;
  final ChartComparisonDuplicatePolicy duplicatePolicy;

  /// Explicit baseline used for absolute and percentage deltas.
  ///
  /// When null, no deltas are calculated.
  final String? baselineInputId;

  /// Required and positive for [ChartComparisonAlignmentPolicy.timestampTolerance].
  final Duration? timestampTolerance;

  /// Optional common numeric X unit used by exact-X alignment.
  final String? comparisonXUnit;

  /// Explicit numeric X conversions keyed by input ID.
  final Map<String, ChartComparisonUnitConversion> xUnitConversionsByInputId;

  /// Runtime formatter bindings used to retain document display values.
  final ChartFormatterRegistry formatters;
}

/// One source point or explicit missing cell in a comparison row.
@immutable
class ChartComparisonValue {
  const ChartComparisonValue({
    required this.inputId,
    required this.inputLabel,
    required this.semanticKey,
    required this.isMissing,
    required this.isValid,
    required this.isDerived,
    required this.hiddenInSource,
    this.sourceSeriesId,
    this.reference,
    this.rawX,
    this.xDisplay,
    this.rawY,
    this.yDisplay,
    this.timestamp,
    this.sourceUnit,
    this.comparisonValue,
    this.comparisonUnit,
  });

  final String inputId;
  final String inputLabel;
  final String semanticKey;
  final String? sourceSeriesId;
  final ChartPointRef? reference;
  final double? rawX;
  final String? xDisplay;
  final double? rawY;
  final String? yDisplay;
  final DateTime? timestamp;
  final String? sourceUnit;

  /// Raw Y after an explicit conversion, or raw Y itself when units agree.
  final double? comparisonValue;
  final String? comparisonUnit;
  final bool isMissing;
  final bool isValid;

  /// Whether [comparisonValue] was produced by a host-supplied conversion.
  final bool isDerived;
  final bool hiddenInSource;
}

/// Why a delta is present, partial, or unavailable.
enum ChartComparisonDeltaStatus {
  available,
  baseline,
  missingValue,
  invalidValue,
  incompatibleUnit,

  /// Absolute delta is available; percentage is undefined against zero.
  baselineZero,
}

/// Derived comparison values for one input against the explicit baseline.
@immutable
class ChartComparisonDelta {
  const ChartComparisonDelta({
    required this.inputId,
    required this.baselineInputId,
    required this.status,
    this.absolute,
    this.percentage,
  });

  final String inputId;
  final String baselineInputId;
  final double? absolute;
  final double? percentage;
  final ChartComparisonDeltaStatus status;

  /// Deltas are always derived and never replace source values.
  bool get isDerived => true;
}

/// One deterministic comparison row for one semantic series mapping.
@immutable
class ChartComparisonRow {
  ChartComparisonRow({
    required this.rowId,
    required this.semanticKey,
    required this.isAligned,
    required Map<String, ChartComparisonValue> valuesByInputId,
    Map<String, ChartComparisonDelta> deltasByInputId = const {},
    this.alignmentX,
    this.alignmentTimestamp,
    this.occurrence = 0,
  }) : valuesByInputId = Map.unmodifiable(valuesByInputId),
       deltasByInputId = Map.unmodifiable(deltasByInputId);

  final String rowId;
  final String semanticKey;
  final bool isAligned;
  final double? alignmentX;
  final DateTime? alignmentTimestamp;
  final int occurrence;
  final Map<String, ChartComparisonValue> valuesByInputId;
  final Map<String, ChartComparisonDelta> deltasByInputId;
}

/// Pure, immutable result of comparing two or more chart documents.
@immutable
class ChartComparisonModel {
  ChartComparisonModel({
    required Iterable<ChartComparisonInput> inputs,
    required Iterable<ChartSeriesMatch> seriesMatches,
    required this.options,
    required Iterable<ChartComparisonRow> rows,
    Iterable<ChartArtifactWarning> warnings = const [],
  }) : inputs = List.unmodifiable(inputs),
       seriesMatches = List.unmodifiable(seriesMatches),
       rows = List.unmodifiable(rows),
       warnings = List.unmodifiable(warnings);

  final List<ChartComparisonInput> inputs;
  final List<ChartSeriesMatch> seriesMatches;
  final ChartComparisonOptions options;
  final List<ChartComparisonRow> rows;
  final List<ChartArtifactWarning> warnings;

  Iterable<ChartComparisonRow> rowsFor(String semanticKey) =>
      rows.where((row) => row.semanticKey == semanticKey);
}
