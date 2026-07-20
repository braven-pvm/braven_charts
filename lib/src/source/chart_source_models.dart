import 'package:flutter/foundation.dart';

import '../artifacts/chart_document_extractor.dart';
import '../artifacts/chart_runtime_bindings.dart';

/// Whether generated Dart fully represents the captured portable chart.
enum ChartGeneratedSourceCompleteness {
  /// Every portable value requested by the source options is represented.
  complete,

  /// The source contains explicit placeholders for omitted data or runtime
  /// values that cannot be represented as Dart configuration.
  portableWithPlaceholders,
}

/// Stable warning codes emitted by chart source generation.
abstract final class ChartSourceWarningCodes {
  static const dataOmitted = 'source_data_omitted';
  static const runtimeValueOmitted = 'source_runtime_value_omitted';
  static const unsupportedPortableValue = 'source_value_unsupported';
}

/// One explicit limitation in generated chart source.
@immutable
class ChartSourceWarning {
  const ChartSourceWarning({
    required this.code,
    required this.message,
    this.path,
  });

  final String code;
  final String message;

  /// Optional document-style path to the affected value.
  final String? path;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartSourceWarning &&
          other.code == code &&
          other.message == message &&
          other.path == path;

  @override
  int get hashCode => Object.hash(code, message, path);
}

/// Controls direct Dart generation for one chart document snapshot.
@immutable
class ChartDartSourceOptions {
  const ChartDartSourceOptions({
    this.includeImports = true,
    this.includeViewState = false,
    this.includeDefaultValues = false,
    this.maxInlinePoints = 250,
    this.variableName = 'chart',
    this.formatters = const ChartFormatterRegistry(),
  }) : assert(maxInlinePoints >= 0, 'maxInlinePoints must be non-negative');

  /// Whether package and Material imports precede the generated declaration.
  final bool includeImports;

  /// Whether durable viewport state is represented when the snapshot has it.
  ///
  /// View-state generation is deliberately disabled by default because the
  /// primary output is a reusable chart configuration.
  final bool includeViewState;

  /// Whether values equal to public constructor defaults are included.
  final bool includeDefaultValues;

  /// Maximum number of chart points written inline across all series.
  ///
  /// A chart above this ceiling receives explicit data placeholders. Source
  /// generation never samples points silently.
  final int maxInlinePoints;

  /// Top-level variable assigned to the generated [BravenChartPlus] widget.
  final String variableName;

  /// Runtime formatter implementations used while hydrating the captured
  /// portable document for source generation.
  ///
  /// Generated Dart still reports callbacks that cannot be represented as
  /// portable configuration, but registered formatter descriptors no longer
  /// produce a false unregistered-formatter warning during hydration.
  final ChartFormatterRegistry formatters;
}

/// Direct Dart source generated from one effective chart revision.
@immutable
class ChartGeneratedSource {
  ChartGeneratedSource({
    required this.source,
    required this.revision,
    required this.completeness,
    required Iterable<ChartSourceWarning> warnings,
    required this.seriesCount,
    required this.pointCount,
    required this.omittedPointCount,
  }) : warnings = List.unmodifiable(warnings);

  final String source;
  final ChartDocumentRevision revision;
  final ChartGeneratedSourceCompleteness completeness;
  final List<ChartSourceWarning> warnings;
  final int seriesCount;
  final int pointCount;
  final int omittedPointCount;

  bool get isComplete =>
      completeness == ChartGeneratedSourceCompleteness.complete;
}
