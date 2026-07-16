import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/axis_swap_mode.dart';
import '../models/chart_annotation.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';
import '../models/chart_theme.dart';
import '../models/grid_config.dart';
import '../models/interaction_config.dart';
import '../models/legend_style.dart';
import '../models/normalization_mode.dart';
import '../models/x_axis_config.dart';
import '../models/y_axis_config.dart';
import 'chart_annotation_document_codec.dart';
import 'chart_artifact_diagnostics.dart';
import 'chart_axis_document_codec.dart';
import 'chart_configuration_document_codec.dart';
import 'chart_configuration_documents.dart';
import 'chart_data_payload.dart';
import 'chart_data_storage.dart';
import 'chart_document.dart';
import 'chart_interaction_document_codec.dart';
import 'chart_series_document_codec.dart';
import 'chart_theme_document_codec.dart';
import 'chart_view_state.dart';
import 'json_value.dart';

/// Selects which resolved data projection is copied into a chart document.
enum ChartDataScope {
  /// Every effective series and point, with visibility stored in view state.
  effectiveFull,

  /// Only series that are currently visible.
  visibleSeries,

  /// Only points in the current viewport.
  ///
  /// Continuous line and area series retain the immediately adjacent logical
  /// point on each side of the inclusive X range for visual continuity.
  visibleViewport,

  /// Declarative widget series without controller or streaming additions.
  declaredSource,

  /// Capture configuration and view state without series data.
  configurationOnly,
}

/// Controls synchronous extraction of a live chart document.
@immutable
class ChartDocumentExtractOptions {
  const ChartDocumentExtractOptions({
    this.documentId = 'chart-document',
    this.dataScope = ChartDataScope.effectiveFull,
    this.includeViewState = true,
    this.dataStorage = ChartDataStorage.inlinePoints,
    this.themeMode = ChartThemeCaptureMode.referenceAndResolved,
    this.themeReference,
    this.xAxisFormatterDescriptor,
    this.yAxisFormatterDescriptors = const {},
    this.interactionBindingDescriptors = const {},
    this.maxSnapshotAttempts = 3,
  }) : assert(documentId != ''),
       assert(maxSnapshotAttempts > 0);

  /// Stable document identity used by table and cache consumers.
  final String documentId;

  /// Effective data projection copied into the document.
  final ChartDataScope dataScope;

  /// Whether durable visibility, selection, viewport, and axis-slot state is
  /// included in the returned snapshot.
  final bool includeViewState;

  /// Self-contained point-object or columnar storage projection.
  final ChartDataStorage dataStorage;

  /// Theme fields captured into the document.
  final ChartThemeCaptureMode themeMode;

  /// Optional host theme reference retained as metadata.
  final String? themeReference;

  /// JSON-safe descriptor for the X-axis formatter.
  final JsonObjectValue? xAxisFormatterDescriptor;

  /// JSON-safe descriptors keyed by axis ID for Y-axis formatters.
  final Map<String, JsonObjectValue> yAxisFormatterDescriptors;

  /// Stable IDs for interaction callbacks resolved during hydration.
  final Map<String, JsonObjectValue> interactionBindingDescriptors;

  /// Maximum stable-snapshot attempts before returning an unstable revision.
  final int maxSnapshotAttempts;
}

/// Opaque identity for one effective mounted-chart source revision.
///
/// Compare revisions with `==`. Their representation is deliberately hidden;
/// callers must not infer ordering or attempt to recreate a matching value.
@immutable
class ChartDocumentRevision {
  const ChartDocumentRevision._(this._identity);

  final Object _identity;

  /// Creates a new package-owned opaque identity.
  ///
  /// This member is internal infrastructure and is not a host revision API.
  @internal
  static ChartDocumentRevision next() =>
      ChartDocumentRevision._(_ChartDocumentRevisionIdentity());

  @override
  bool operator ==(Object other) =>
      other is ChartDocumentRevision && identical(_identity, other._identity);

  @override
  int get hashCode => identityHashCode(_identity);

  @override
  String toString() => 'ChartDocumentRevision(opaque)';
}

class _ChartDocumentRevisionIdentity {
  _ChartDocumentRevisionIdentity();
}

/// An immutable document and optional view state captured at one revision.
@immutable
class ChartDocumentSnapshot {
  ChartDocumentSnapshot({
    required this.document,
    this.viewState,
    ChartDocumentRevision? revision,
  }) : revision = revision ?? ChartDocumentRevision.next();

  final ChartDocument document;
  final ChartViewState? viewState;

  /// Effective mounted-source revision represented by this snapshot.
  final ChartDocumentRevision revision;
}

typedef ChartDocumentExtractionHandler =
    ChartArtifactResult<ChartDocumentSnapshot> Function(
      ChartDocumentExtractOptions options,
    );

/// Package-internal, renderer-independent values captured from a mounted chart.
@internal
@immutable
class ChartDocumentExtractionSource {
  ChartDocumentExtractionSource({
    required Iterable<ChartSeries> allSeries,
    required Iterable<ChartSeries> visibleSeries,
    required Iterable<ChartSeries> declaredSeries,
    required Iterable<ChartAnnotation> annotations,
    required this.xAxis,
    required Iterable<YAxisConfig> axes,
    required this.theme,
    required this.interaction,
    required this.legendVisible,
    required this.legendStyle,
    required this.grid,
    required this.normalizationMode,
    required this.backgroundColor,
    required this.showToolbar,
    required this.interactiveAnnotations,
    required this.maxAxesPerSide,
    required this.axisSwapMode,
    required this.viewState,
    this.themeReference,
    this.title,
    this.subtitle,
    this.width,
    this.height,
  }) : allSeries = List.unmodifiable(allSeries),
       visibleSeries = List.unmodifiable(visibleSeries),
       declaredSeries = List.unmodifiable(declaredSeries),
       annotations = List.unmodifiable(annotations),
       axes = List.unmodifiable(axes);

  final List<ChartSeries> allSeries;
  final List<ChartSeries> visibleSeries;
  final List<ChartSeries> declaredSeries;
  final List<ChartAnnotation> annotations;
  final XAxisConfig xAxis;
  final List<YAxisConfig> axes;
  final ChartTheme theme;
  final String? themeReference;
  final InteractionConfig interaction;
  final bool legendVisible;
  final LegendStyle legendStyle;
  final GridConfig grid;
  final NormalizationMode normalizationMode;
  final String? title;
  final String? subtitle;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final bool showToolbar;
  final bool interactiveAnnotations;
  final int maxAxesPerSide;
  final AxisSwapMode axisSwapMode;
  final ChartViewState viewState;
}

/// Pure document assembler for one stable effective-source snapshot.
abstract final class ChartDocumentExtractor {
  static ChartArtifactResult<ChartDocumentSnapshot> extract({
    required ChartDocumentExtractionSource source,
    required ChartDocumentExtractOptions options,
    required int revision,
    ChartDocumentRevision? effectiveRevision,
  }) {
    final warnings = <ChartArtifactWarning>[];
    try {
      final sourceSeries = switch (options.dataScope) {
        ChartDataScope.effectiveFull => source.allSeries,
        ChartDataScope.visibleSeries => source.visibleSeries,
        ChartDataScope.declaredSource => source.declaredSeries,
        ChartDataScope.configurationOnly => const <ChartSeries>[],
        ChartDataScope.visibleViewport => _visibleViewportSeries(source),
      };
      final seriesDocuments = [
        for (final series in sourceSeries)
          _requireValue(
            ChartSeriesDocumentCodec.encode(
              series,
              inlineAxisFormatter: _seriesAxisFormatter(series, options),
              dataStorage: options.dataStorage,
            ),
            warnings,
          ),
      ];
      final annotationDocuments = [
        for (final annotation in source.annotations)
          _requireValue(
            ChartAnnotationDocumentCodec.encode(
              annotation,
              dataStorage: options.dataStorage,
            ),
            warnings,
          ),
      ];
      final xAxis = _requireValue(
        ChartAxisDocumentCodec.encodeXAxis(
          source.xAxis,
          formatter: options.xAxisFormatterDescriptor,
        ),
        warnings,
      );
      final axes = [
        for (final axis in source.axes)
          _requireValue(
            ChartAxisDocumentCodec.encodeYAxis(
              axis,
              formatter: options.yAxisFormatterDescriptors[axis.id],
            ),
            warnings,
          ),
      ];
      final theme = _requireValue(
        ChartThemeDocumentCodec.encode(
          source.theme,
          captureMode: options.themeMode,
          reference:
              options.themeReference ??
              source.themeReference ??
              _builtInThemeReference(source.theme),
        ),
        warnings,
      );
      final interaction = _requireValue(
        ChartInteractionDocumentCodec.encode(
          source.interaction,
          runtimeBindingDescriptors: options.interactionBindingDescriptors,
        ),
        warnings,
      );
      final legend = _requireValue(
        ChartConfigurationDocumentCodec.encodeLegend(
          visible: source.legendVisible,
          style: source.legendStyle,
        ),
        warnings,
      );
      final requiredCapabilities = <String>{
        for (final series in seriesDocuments) ...series.requiredCapabilities,
        for (final annotation in annotationDocuments)
          ...annotation.requiredCapabilities,
      };
      final viewState = options.includeViewState ? source.viewState : null;

      return ChartArtifactSuccess(
        value: ChartDocumentSnapshot(
          document: ChartDocument(
            documentId: options.documentId,
            revision: revision,
            title: source.title,
            subtitle: source.subtitle,
            series: seriesDocuments,
            xAxis: xAxis,
            axes: axes,
            theme: theme,
            interaction: interaction,
            annotations: annotationDocuments,
            legend: legend,
            grid: ChartConfigurationDocumentCodec.encodeGrid(source.grid),
            layout: ChartLayoutDocument(
              width: source.width == null
                  ? null
                  : ChartNumberDocument.fromDouble(source.width!),
              height: source.height == null
                  ? null
                  : ChartNumberDocument.fromDouble(source.height!),
              backgroundColor: source.backgroundColor.toARGB32(),
              showToolbar: source.showToolbar,
              interactiveAnnotations: source.interactiveAnnotations,
              maxAxesPerSide: source.maxAxesPerSide,
              axisSwapMode: source.axisSwapMode.name,
            ),
            normalization: ChartConfigurationDocumentCodec.encodeNormalization(
              source.normalizationMode,
            ),
            requiredCapabilities: requiredCapabilities,
            extensions: {'dataScope': JsonStringValue(options.dataScope.name)},
          ),
          viewState: viewState,
          revision: effectiveRevision,
        ),
        warnings: warnings,
      );
    } on _ExtractionFailure catch (failure) {
      return ChartArtifactFailure(
        error: failure.error,
        warnings: [...warnings, ...failure.warnings],
      );
    }
  }

  static List<ChartSeries> _visibleViewportSeries(
    ChartDocumentExtractionSource source,
  ) {
    final bounds = source.viewState.visibleBounds;
    if (bounds == null) {
      throw const _ExtractionFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.captureInProgress,
          message:
              'The chart must complete layout before visibleViewport extraction.',
          path: r'$.options.dataScope',
        ),
        [],
      );
    }
    return [
      for (final series in source.visibleSeries)
        series.copyWith(
          points: _pointsInViewport(series, bounds.xMin, bounds.xMax),
        ),
    ];
  }

  static JsonObjectValue? _seriesAxisFormatter(
    ChartSeries series,
    ChartDocumentExtractOptions options,
  ) {
    final axis = series.yAxisConfig;
    if (axis == null) return null;
    final axisId = axis.id.isEmpty ? '${series.id}_axis' : axis.id;
    return options.yAxisFormatterDescriptors[axisId];
  }

  static List<ChartDataPoint> _pointsInViewport(
    ChartSeries series,
    double xMin,
    double xMax,
  ) {
    final included = <int>{};
    for (var index = 0; index < series.points.length; index++) {
      final x = series.points[index].x;
      if (x >= xMin && x <= xMax) included.add(index);
    }
    if (included.isEmpty) return const [];

    if (series is LineChartSeries || series is AreaChartSeries) {
      final first = included.reduce((a, b) => a < b ? a : b);
      final last = included.reduce((a, b) => a > b ? a : b);
      if (first > 0) included.add(first - 1);
      if (last + 1 < series.points.length) included.add(last + 1);
    }
    final indices = included.toList()..sort();
    return [for (final index in indices) series.points[index]];
  }
}

class _ExtractionFailure implements Exception {
  const _ExtractionFailure(this.error, this.warnings);

  final ChartArtifactError error;
  final List<ChartArtifactWarning> warnings;
}

T _requireValue<T>(
  ChartArtifactResult<T> result,
  List<ChartArtifactWarning> warnings,
) => switch (result) {
  ChartArtifactSuccess<T>() => _recordSuccess(result, warnings),
  ChartArtifactFailure<T>() => throw _ExtractionFailure(
    result.error,
    result.warnings,
  ),
};

T _recordSuccess<T>(
  ChartArtifactSuccess<T> result,
  List<ChartArtifactWarning> warnings,
) {
  warnings.addAll(result.warnings);
  return result.value;
}

String? _builtInThemeReference(ChartTheme theme) {
  if (identical(theme, ChartTheme.light)) return 'light';
  if (identical(theme, ChartTheme.dark)) return 'dark';
  if (identical(theme, ChartTheme.corporateBlue)) return 'corporateBlue';
  if (identical(theme, ChartTheme.vibrant)) return 'vibrant';
  if (identical(theme, ChartTheme.minimal)) return 'minimal';
  if (identical(theme, ChartTheme.highContrast)) return 'highContrast';
  if (identical(theme, ChartTheme.colorblindFriendly)) {
    return 'colorblindFriendly';
  }
  return null;
}
