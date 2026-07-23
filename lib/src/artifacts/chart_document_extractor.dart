import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../meta/chart_surface.dart';
import '../models/axis_swap_mode.dart';
import '../models/cartesian_value_summary_config.dart';
import '../models/candlestick_data_point.dart';
import '../models/chart_annotation.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';
import '../models/chart_selection_expression.dart';
import '../models/chart_theme.dart';
import '../models/concentric_donut_config.dart';
import '../models/grid_config.dart';
import '../models/interaction_config.dart';
import '../models/legend_style.dart';
import '../models/normalization_mode.dart';
import '../models/polar_chart_config.dart';
import '../models/range_area_data_point.dart';
import '../models/x_axis_config.dart';
import '../models/y_axis_config.dart';
import '../layout/polar_column_composition.dart';
import '../utils/interpolation_geometry.dart';
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
import 'radial_formatter_document_descriptors.dart';

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

  /// Only data represented by the chart's current durable selection.
  ///
  /// [ChartDocumentExtractOptions.selectionProjection] controls whether the
  /// result keeps exact selected points or complete participating series.
  selection,
}

/// Controls how participating series are projected for selection extraction.
enum ChartSelectionSeriesProjection {
  /// Keep complete series selections and only the selected points elsewhere.
  selectedPointsOnly,

  /// Keep every point from each series which participates in the selection.
  completeParticipatingSeries,
}

/// Controls how annotations are projected into a selection-scoped document.
enum ChartSelectionAnnotationProjection {
  /// Omit every chart annotation from the detached document.
  omitAll,

  /// Retain only annotations fully represented by the selected data.
  retainContained,

  /// Retain compatible annotations and clip data-space ranges to the selection.
  clipToSelectionBounds,
}

/// Controls whether a selected continuous interval includes exact boundaries.
enum ChartSelectionIntervalBoundaryProjection {
  /// Retain only source observations enclosed by the selection.
  sourcePointsOnly,

  /// Add synthetic Line/Area boundary observations using renderer geometry.
  interpolateContinuousSeries,
}

/// Selection-specific document projection policy.
@immutable
class ChartSelectionProjectionOptions {
  const ChartSelectionProjectionOptions({
    this.seriesProjection = ChartSelectionSeriesProjection.selectedPointsOnly,
    this.annotationProjection =
        ChartSelectionAnnotationProjection.clipToSelectionBounds,
    this.intervalBoundaryProjection =
        ChartSelectionIntervalBoundaryProjection.sourcePointsOnly,
  });

  final ChartSelectionSeriesProjection seriesProjection;

  final ChartSelectionAnnotationProjection annotationProjection;

  final ChartSelectionIntervalBoundaryProjection intervalBoundaryProjection;
}

/// Controls synchronous extraction of a live chart document.
@chartSurface
@immutable
class ChartDocumentExtractOptions {
  const ChartDocumentExtractOptions({
    this.documentId = 'chart-document',
    this.dataScope = ChartDataScope.effectiveFull,
    this.selectionProjection = const ChartSelectionProjectionOptions(),
    this.includeViewState = true,
    this.dataStorage = ChartDataStorage.inlinePoints,
    this.themeMode = ChartThemeCaptureMode.referenceAndResolved,
    this.themeReference,
    this.xAxisFormatterDescriptor,
    this.yAxisFormatterDescriptors = const {},
    this.interactionBindingDescriptors = const {},
    this.radialFormatterDescriptors = const {},
    this.concentricCenterFormatterDescriptor,
    this.maxSnapshotAttempts = 3,
  }) : assert(documentId != ''),
       assert(maxSnapshotAttempts > 0);

  /// Stable document identity used by table and cache consumers.
  final String documentId;

  /// Effective data projection copied into the document.
  final ChartDataScope dataScope;

  /// Projection policy used only when [dataScope] is
  /// [ChartDataScope.selection].
  final ChartSelectionProjectionOptions selectionProjection;

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

  /// Portable numeric formatter descriptors keyed by radial series ID.
  ///
  /// A descriptor is required for each custom radial formatter present on the
  /// source series. Extraction fails closed instead of serializing callbacks.
  final Map<String, RadialFormatterDocumentDescriptors>
  radialFormatterDescriptors;

  /// Portable formatter descriptor for the plot-owned Concentric Donut center.
  final JsonObjectValue? concentricCenterFormatterDescriptor;

  /// Maximum stable-snapshot attempts before returning an unstable revision.
  final int maxSnapshotAttempts;

  ChartDocumentExtractOptions copyWith({
    String? documentId,
    ChartDataScope? dataScope,
    ChartSelectionProjectionOptions? selectionProjection,
    bool? includeViewState,
    ChartDataStorage? dataStorage,
    ChartThemeCaptureMode? themeMode,
    String? themeReference,
    JsonObjectValue? xAxisFormatterDescriptor,
    Map<String, JsonObjectValue>? yAxisFormatterDescriptors,
    Map<String, JsonObjectValue>? interactionBindingDescriptors,
    Map<String, RadialFormatterDocumentDescriptors>? radialFormatterDescriptors,
    JsonObjectValue? concentricCenterFormatterDescriptor,
    int? maxSnapshotAttempts,
    bool clearThemeReference = false,
    bool clearXAxisFormatterDescriptor = false,
    bool clearConcentricCenterFormatterDescriptor = false,
  }) => ChartDocumentExtractOptions(
    documentId: documentId ?? this.documentId,
    dataScope: dataScope ?? this.dataScope,
    selectionProjection: selectionProjection ?? this.selectionProjection,
    includeViewState: includeViewState ?? this.includeViewState,
    dataStorage: dataStorage ?? this.dataStorage,
    themeMode: themeMode ?? this.themeMode,
    themeReference: clearThemeReference
        ? null
        : (themeReference ?? this.themeReference),
    xAxisFormatterDescriptor: clearXAxisFormatterDescriptor
        ? null
        : (xAxisFormatterDescriptor ?? this.xAxisFormatterDescriptor),
    yAxisFormatterDescriptors:
        yAxisFormatterDescriptors ?? this.yAxisFormatterDescriptors,
    interactionBindingDescriptors:
        interactionBindingDescriptors ?? this.interactionBindingDescriptors,
    radialFormatterDescriptors:
        radialFormatterDescriptors ?? this.radialFormatterDescriptors,
    concentricCenterFormatterDescriptor:
        clearConcentricCenterFormatterDescriptor
        ? null
        : (concentricCenterFormatterDescriptor ??
              this.concentricCenterFormatterDescriptor),
    maxSnapshotAttempts: maxSnapshotAttempts ?? this.maxSnapshotAttempts,
  );
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
    this.concentricDonutConfig,
    this.polarChartConfig,
    this.selectionSnapshot,
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
  final ConcentricDonutConfig? concentricDonutConfig;
  final PolarChartConfig? polarChartConfig;
  final Color backgroundColor;
  final bool showToolbar;
  final bool interactiveAnnotations;
  final int maxAxesPerSide;
  final AxisSwapMode axisSwapMode;
  final ChartViewState viewState;
  final ChartSelectionSnapshot? selectionSnapshot;
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
      final selectionProjection = options.dataScope == ChartDataScope.selection
          ? _selectionProjection(source, options.selectionProjection, warnings)
          : null;
      final sourceSeries = switch (options.dataScope) {
        ChartDataScope.effectiveFull => source.allSeries,
        ChartDataScope.visibleSeries => source.visibleSeries,
        ChartDataScope.declaredSource => source.declaredSeries,
        ChartDataScope.configurationOnly => const <ChartSeries>[],
        ChartDataScope.visibleViewport => _visibleViewportSeries(source),
        ChartDataScope.selection => selectionProjection!.series,
      };
      final seriesDocuments = [
        for (final series in sourceSeries)
          _requireValue(
            ChartSeriesDocumentCodec.encode(
              series,
              inlineAxisFormatter: _seriesAxisFormatter(series, options),
              radialFormatterDescriptors:
                  options.radialFormatterDescriptors[series.id],
              dataStorage: options.dataStorage,
            ),
            warnings,
          ),
      ];
      final projectedAnnotations = selectionProjection == null
          ? source.annotations
          : _selectionAnnotations(
              source.annotations,
              selectionProjection,
              options.selectionProjection.annotationProjection,
              warnings,
            );
      final annotationDocuments = [
        for (final annotation in projectedAnnotations)
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
      final projectedAxes = selectionProjection == null
          ? source.axes
          : _selectionAxes(source.axes, selectionProjection.series);
      final axes = [
        for (final axis in projectedAxes)
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
              ChartThemeDocumentCodec.builtInReference(source.theme),
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
      final configurationValues = <String, JsonValue>{};
      if (source.concentricDonutConfig case final concentricConfig?) {
        configurationValues.addAll(
          _requireValue(
            ChartConfigurationDocumentCodec.encodeConcentricDonut(
              concentricConfig,
              centerFormatterDescriptor:
                  options.concentricCenterFormatterDescriptor,
            ),
            warnings,
          ).values,
        );
      }
      if (source.polarChartConfig case final polarConfig?) {
        configurationValues.addAll(
          _requireValue(
            ChartConfigurationDocumentCodec.encodePolarChart(polarConfig),
            warnings,
          ).values,
        );
      }
      final configuration = JsonObjectValue(configurationValues);
      final requiredCapabilities = <String>{
        for (final series in seriesDocuments) ...series.requiredCapabilities,
        for (final annotation in annotationDocuments)
          ...annotation.requiredCapabilities,
        if (source.concentricDonutConfig != null) 'series.donut.concentric.v1',
        if (source.polarChartConfig != null) 'chart.polar.config.v1',
        if (source.polarChartConfig?.thresholds.isNotEmpty == true)
          'chart.polar.thresholds.v1',
        if (source.polarChartConfig?.hasCustomLabelAppearance == true)
          PolarChartConfig.labelAppearanceCapability,
        if (source.polarChartConfig != null &&
            seriesDocuments
                    .where((series) => series.type == 'polarColumn')
                    .length >
                1)
          PolarColumnComposition.multipleSeriesCapability,
        if (source.polarChartConfig?.composition.mode ==
            PolarColumnCompositionMode.grouped)
          PolarColumnComposition.groupedSeriesCapability,
        if (source.polarChartConfig?.composition.mode ==
            PolarColumnCompositionMode.stacked)
          PolarColumnComposition.stackedSeriesCapability,
        if (options.concentricCenterFormatterDescriptor != null)
          'series.radial.formatters.v1',
        if (source.interaction.valueSummary !=
            const CartesianValueSummaryConfig())
          'chart.cartesian.value-summary.v1',
      };
      final viewState = options.includeViewState
          ? options.dataScope == ChartDataScope.selection
                ? _selectionViewState(
                    source.viewState,
                    sourceSeries,
                    projectedAxes,
                  )
                : source.viewState
          : null;

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
            configuration: configuration,
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

  static _SelectionProjection _selectionProjection(
    ChartDocumentExtractionSource source,
    ChartSelectionProjectionOptions projection,
    List<ChartArtifactWarning> warnings,
  ) {
    final expression = source.selectionSnapshot?.expression;
    final selectedSeriesIds = expression == null
        ? source.viewState.selectedSeriesIds
        : <String>{
            for (final clause in expression.clauses)
              if (clause is ChartSelectionWholeSeriesClause) clause.seriesId,
          };
    final selectedPointRefsBySeries = <String, Set<int>>{};
    final seriesById = <String, ChartSeries>{
      for (final series in source.allSeries) series.id: series,
    };

    final selectedPointRefs =
        source.selectionSnapshot?.pointRefs ??
        source.viewState.selectedPointRefs;
    for (final reference in selectedPointRefs) {
      final series = seriesById[reference.seriesId];
      if (series == null ||
          reference.pointIndex < 0 ||
          reference.pointIndex >= series.points.length) {
        warnings.add(
          ChartArtifactWarning(
            code: ChartArtifactDiagnosticCodes.stalePointReference,
            message:
                'A selected point no longer exists in the effective chart and was omitted.',
            path:
                r'$.viewState.selectedPointRefs['
                '${reference.seriesId}:${reference.pointIndex}]',
          ),
        );
        continue;
      }
      selectedPointRefsBySeries
          .putIfAbsent(reference.seriesId, () => <int>{})
          .add(reference.pointIndex);
    }

    final participatingSeriesIds = <String>{
      ...selectedSeriesIds.where(seriesById.containsKey),
      ...selectedPointRefsBySeries.keys,
      if (projection.intervalBoundaryProjection ==
          ChartSelectionIntervalBoundaryProjection.interpolateContinuousSeries)
        for (final series in source.allSeries)
          if (_hasTargetedContinuousXInterval(series, expression)) series.id,
    };
    if (participatingSeriesIds.isEmpty) {
      throw const _ExtractionFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.selectionEmpty,
          message:
              'Selection-scoped extraction requires at least one selected series or point.',
          path: r'$.options.dataScope',
        ),
        [],
      );
    }

    final projectedSeries = <ChartSeries>[];
    final projectedIndexBySourceIndex = <String, Map<int, int>>{};
    final fullyRetainedSeriesIds = <String>{};
    for (final series in source.allSeries) {
      if (!participatingSeriesIds.contains(series.id)) continue;
      final retainComplete =
          projection.seriesProjection ==
              ChartSelectionSeriesProjection.completeParticipatingSeries ||
          selectedSeriesIds.contains(series.id);
      final sourceIndices =
          retainComplete
                ? [
                    for (var index = 0; index < series.points.length; index++)
                      index,
                  ]
                : (selectedPointRefsBySeries[series.id]?.toList() ?? <int>[])
            ..sort();
      final projected = retainComplete
          ? _ProjectedSeriesPoints.complete(series)
          : _projectSelectedSeriesPoints(
              series,
              sourceIndices,
              expression,
              projection.intervalBoundaryProjection,
            );
      projectedIndexBySourceIndex[series.id] = projected.sourceIndexMap;
      if (retainComplete) fullyRetainedSeriesIds.add(series.id);
      projectedSeries.add(
        retainComplete ? series : series.copyWith(points: projected.points),
      );
    }
    final boundsBySeriesId = <String, _SelectionBounds>{};
    for (final series in projectedSeries) {
      final bounds = _selectionBounds([series]);
      if (bounds != null) boundsBySeriesId[series.id] = bounds;
    }
    return _SelectionProjection(
      series: projectedSeries,
      sourceFirstSeriesId: source.allSeries.isEmpty
          ? null
          : source.allSeries.first.id,
      projectedIndexBySourceIndex: projectedIndexBySourceIndex,
      fullyRetainedSeriesIds: fullyRetainedSeriesIds,
      bounds: _selectionBounds(projectedSeries),
      boundsBySeriesId: boundsBySeriesId,
    );
  }

  static bool _hasTargetedContinuousXInterval(
    ChartSeries series,
    ChartSelectionExpression? expression,
  ) {
    if (expression == null ||
        (series is! LineChartSeries && series is! AreaChartSeries) ||
        series.points.length < 2) {
      return false;
    }
    for (final clause in expression.clauses) {
      if (clause is! ChartSelectionXIntervalClause ||
          (clause.seriesIds != null &&
              !clause.seriesIds!.contains(series.id))) {
        continue;
      }
      for (var index = 0; index + 1 < series.points.length; index++) {
        final first = series.points[index];
        final second = series.points[index + 1];
        if (!first.isValid || !second.isValid || first.x == second.x) continue;
        final segmentMinimum = math.min(first.x, second.x);
        final segmentMaximum = math.max(first.x, second.x);
        if (clause.maximumXInclusive >= segmentMinimum &&
            clause.minimumXInclusive <= segmentMaximum) {
          return true;
        }
      }
    }
    return false;
  }

  static _ProjectedSeriesPoints _projectSelectedSeriesPoints(
    ChartSeries series,
    List<int> sourceIndices,
    ChartSelectionExpression? expression,
    ChartSelectionIntervalBoundaryProjection boundaryProjection,
  ) {
    if (boundaryProjection ==
            ChartSelectionIntervalBoundaryProjection.sourcePointsOnly ||
        expression == null ||
        (series is! LineChartSeries && series is! AreaChartSeries)) {
      return _ProjectedSeriesPoints.fromSourceIndices(series, sourceIndices);
    }
    final intervals = <ChartSelectionXIntervalClause>[
      for (final clause in expression.clauses)
        if (clause is ChartSelectionXIntervalClause &&
            (clause.seriesIds == null || clause.seriesIds!.contains(series.id)))
          clause,
    ];
    if (intervals.isEmpty || series.points.length < 2) {
      return _ProjectedSeriesPoints.fromSourceIndices(series, sourceIndices);
    }

    final selected = sourceIndices.toSet();
    final boundariesBySegment = <int, Set<double>>{};
    for (final interval in intervals) {
      for (final boundary in <double>[
        interval.minimumXInclusive,
        interval.maximumXInclusive,
      ]) {
        for (var index = 0; index + 1 < series.points.length; index++) {
          final first = series.points[index];
          final second = series.points[index + 1];
          if (!first.isValid || !second.isValid || first.x == second.x) {
            continue;
          }
          final minimum = math.min(first.x, second.x);
          final maximum = math.max(first.x, second.x);
          if (boundary > minimum && boundary < maximum) {
            boundariesBySegment
                .putIfAbsent(index, () => <double>{})
                .add(boundary);
            break;
          }
        }
      }
    }
    if (boundariesBySegment.isEmpty) {
      return _ProjectedSeriesPoints.fromSourceIndices(series, sourceIndices);
    }

    final interpolation = switch (series) {
      LineChartSeries() => series.interpolation,
      AreaChartSeries() => series.interpolation,
      _ => LineInterpolation.linear,
    };
    final tension = switch (series) {
      LineChartSeries() => series.tension,
      AreaChartSeries() => series.tension,
      _ => 0.25,
    };
    final projectedPoints = <ChartDataPoint>[];
    final sourceIndexMap = <int, int>{};
    for (
      var sourceIndex = 0;
      sourceIndex < series.points.length;
      sourceIndex++
    ) {
      if (selected.contains(sourceIndex)) {
        sourceIndexMap[sourceIndex] = projectedPoints.length;
        projectedPoints.add(series.points[sourceIndex]);
      }
      final boundaries = boundariesBySegment[sourceIndex];
      if (boundaries == null) continue;
      final orderedBoundaries = boundaries.toList()
        ..sort(
          (first, second) =>
              series.points[sourceIndex].x < series.points[sourceIndex + 1].x
              ? first.compareTo(second)
              : second.compareTo(first),
        );
      for (final boundary in orderedBoundaries) {
        projectedPoints.add(
          ChartDataPoint(
            x: boundary,
            y: InterpolationGeometry.interpolateYForX<ChartDataPoint>(
              points: series.points,
              startIndex: sourceIndex,
              targetX: boundary,
              interpolation: interpolation,
              getX: (point) => point.x,
              getY: (point) => point.y,
              tension: tension,
            ),
          ),
        );
      }
    }
    return _ProjectedSeriesPoints(
      points: projectedPoints,
      sourceIndexMap: sourceIndexMap,
    );
  }

  static List<YAxisConfig> _selectionAxes(
    List<YAxisConfig> sourceAxes,
    List<ChartSeries> projectedSeries,
  ) {
    if (sourceAxes.isEmpty) return const [];
    final retainedAxisIds = <String>{};
    if (projectedSeries.any(
      (series) => series.yAxisId == null && series.yAxisConfig == null,
    )) {
      retainedAxisIds.add(sourceAxes.first.id);
    }
    for (final series in projectedSeries) {
      if (series.yAxisId case final axisId?) retainedAxisIds.add(axisId);
      if (series.yAxisConfig case final axis?) {
        retainedAxisIds.add(axis.id.isEmpty ? '${series.id}_axis' : axis.id);
      }
    }
    return [
      for (final axis in sourceAxes)
        if (retainedAxisIds.contains(axis.id)) axis,
    ];
  }

  static List<ChartAnnotation> _selectionAnnotations(
    List<ChartAnnotation> sourceAnnotations,
    _SelectionProjection projection,
    ChartSelectionAnnotationProjection policy,
    List<ChartArtifactWarning> warnings,
  ) {
    if (policy == ChartSelectionAnnotationProjection.omitAll) return const [];
    final projected = <ChartAnnotation>[];
    for (final annotation in sourceAnnotations) {
      final result = _selectionAnnotation(
        annotation,
        projection,
        policy,
        warnings,
      );
      if (result != null) projected.add(result);
    }
    return projected;
  }

  static ChartAnnotation? _selectionAnnotation(
    ChartAnnotation annotation,
    _SelectionProjection projection,
    ChartSelectionAnnotationProjection policy,
    List<ChartArtifactWarning> warnings,
  ) {
    switch (annotation) {
      case PointAnnotation():
        final index = projection.projectedIndex(
          annotation.seriesId,
          annotation.dataPointIndex,
        );
        if (index == null) {
          _warnAnnotationOmitted(annotation, warnings, 'point is not selected');
          return null;
        }
        return annotation.copyWith(dataPointIndex: index);
      case ChordAnnotation():
        final start = projection.projectedIndex(
          annotation.seriesId,
          annotation.startIndex,
        );
        final end = projection.projectedIndex(
          annotation.seriesId,
          annotation.endIndex,
        );
        if (start == null || end == null) {
          _warnAnnotationOmitted(
            annotation,
            warnings,
            'both chord endpoints are not selected',
          );
          return null;
        }
        final perpendicular = annotation.perpendicularIndex == null
            ? null
            : projection.projectedIndex(
                annotation.seriesId,
                annotation.perpendicularIndex!,
              );
        if (annotation.perpendicularIndex != null && perpendicular == null) {
          warnings.add(
            ChartArtifactWarning(
              code: ChartArtifactDiagnosticCodes
                  .selectionAnnotationComponentOmitted,
              message:
                  'The perpendicular component of chord "${annotation.id}" was omitted because its point is not selected.',
              path: _annotationPath(annotation),
            ),
          );
        }
        return _copyChord(
          annotation,
          startIndex: start,
          endIndex: end,
          perpendicularIndex: perpendicular,
        );
      case ErrorBarAnnotation():
        if (!projection.containsSeries(annotation.seriesId)) {
          _warnAnnotationOmitted(
            annotation,
            warnings,
            'its series is not selected',
          );
          return null;
        }
        final values = <ErrorBarDatum>[];
        for (final value in annotation.values) {
          final index = projection.projectedIndex(
            annotation.seriesId,
            value.pointIndex,
          );
          if (index != null) {
            values.add(
              ErrorBarDatum(
                pointIndex: index,
                xNegative: value.xNegative,
                xPositive: value.xPositive,
                yNegative: value.yNegative,
                yPositive: value.yPositive,
              ),
            );
          }
        }
        if (values.isEmpty) {
          _warnAnnotationOmitted(
            annotation,
            warnings,
            'none of its uncertainty points are selected',
          );
          return null;
        }
        return annotation.copyWith(values: values);
      case TrendAnnotation():
        if (!projection.fullyRetainsSeries(annotation.seriesId)) {
          _warnAnnotationOmitted(
            annotation,
            warnings,
            'derived annotations require a complete retained source series',
          );
          return null;
        }
        return annotation;
      case RangeAnnotation():
        final bounds = projection.boundsFor(annotation.seriesId);
        if (!_seriesReferenceIsCompatible(annotation.seriesId, projection)) {
          _warnAnnotationOmitted(
            annotation,
            warnings,
            'its referenced series is not selected',
          );
          return null;
        }
        if (bounds == null || !_rangeIntersects(annotation, bounds)) {
          _warnAnnotationOmitted(
            annotation,
            warnings,
            'its data range does not intersect the selected data',
          );
          return null;
        }
        if (policy == ChartSelectionAnnotationProjection.retainContained) {
          if (!_rangeIsContained(annotation, bounds)) {
            _warnAnnotationOmitted(
              annotation,
              warnings,
              'its data range is not fully contained by the selected data',
            );
            return null;
          }
          return annotation;
        }
        final clipped = _clipRange(annotation, bounds);
        if (clipped == null) {
          _warnAnnotationOmitted(
            annotation,
            warnings,
            'clipping would collapse its range to zero width or height',
          );
        }
        return clipped;
      case ThresholdAnnotation():
        final bounds = projection.boundsFor(annotation.seriesId);
        if (!_seriesReferenceIsCompatible(annotation.seriesId, projection) ||
            bounds == null ||
            !_thresholdIsContained(annotation, bounds)) {
          _warnAnnotationOmitted(
            annotation,
            warnings,
            'its value or referenced series is outside the selected data',
          );
          return null;
        }
        return annotation;
      case PinAnnotation():
        final bounds = projection.bounds;
        if (bounds == null || !bounds.contains(annotation.x, annotation.y)) {
          _warnAnnotationOmitted(
            annotation,
            warnings,
            'its position is outside the selected data',
          );
          return null;
        }
        return annotation;
      case LegendAnnotation():
        final projectedById = {
          for (final series in projection.series) series.id: series,
        };
        final trends = <TrendAnnotation>[];
        for (final trend in annotation.trendAnnotations) {
          final projectedTrend = _selectionAnnotation(
            trend,
            projection,
            policy,
            warnings,
          );
          if (projectedTrend is TrendAnnotation) trends.add(projectedTrend);
        }
        final errorBars = <ErrorBarAnnotation>[];
        for (final errorBar in annotation.errorBarAnnotations) {
          final projectedErrorBar = _selectionAnnotation(
            errorBar,
            projection,
            policy,
            warnings,
          );
          if (projectedErrorBar is ErrorBarAnnotation) {
            errorBars.add(projectedErrorBar);
          }
        }
        return annotation.copyWith(
          series: [
            for (final series in annotation.series)
              if (projectedById[series.id]
                  case final ChartSeries projectedSeries)
                projectedSeries,
          ],
          trendAnnotations: trends,
          errorBarAnnotations: errorBars,
          hiddenSeriesIds: annotation.hiddenSeriesIds
              .where(projectedById.containsKey)
              .toSet(),
        );
      case TextAnnotation():
        return annotation;
    }
  }

  static bool _seriesReferenceIsCompatible(
    String? seriesId,
    _SelectionProjection projection,
  ) => seriesId == null || projection.containsSeries(seriesId);

  static bool _thresholdIsContained(
    ThresholdAnnotation annotation,
    _SelectionBounds bounds,
  ) => switch (annotation.axis) {
    AnnotationAxis.x =>
      annotation.value >= bounds.xMin && annotation.value <= bounds.xMax,
    AnnotationAxis.y =>
      annotation.value >= bounds.yMin && annotation.value <= bounds.yMax,
  };

  static bool _rangeIntersects(
    RangeAnnotation annotation,
    _SelectionBounds bounds,
  ) =>
      _intervalIntersects(
        annotation.startX,
        annotation.endX,
        bounds.xMin,
        bounds.xMax,
      ) &&
      _intervalIntersects(
        annotation.startY,
        annotation.endY,
        bounds.yMin,
        bounds.yMax,
      );

  static bool _rangeIsContained(
    RangeAnnotation annotation,
    _SelectionBounds bounds,
  ) =>
      _intervalIsContained(
        annotation.startX,
        annotation.endX,
        bounds.xMin,
        bounds.xMax,
      ) &&
      _intervalIsContained(
        annotation.startY,
        annotation.endY,
        bounds.yMin,
        bounds.yMax,
      );

  static bool _intervalIntersects(
    double? start,
    double? end,
    double minimum,
    double maximum,
  ) => (end == null || end >= minimum) && (start == null || start <= maximum);

  static bool _intervalIsContained(
    double? start,
    double? end,
    double minimum,
    double maximum,
  ) => (start == null || start >= minimum) && (end == null || end <= maximum);

  static RangeAnnotation? _clipRange(
    RangeAnnotation annotation,
    _SelectionBounds bounds,
  ) {
    final startX = annotation.startX
        ?.clamp(bounds.xMin, bounds.xMax)
        .toDouble();
    final endX = annotation.endX?.clamp(bounds.xMin, bounds.xMax).toDouble();
    final startY = annotation.startY
        ?.clamp(bounds.yMin, bounds.yMax)
        .toDouble();
    final endY = annotation.endY?.clamp(bounds.yMin, bounds.yMax).toDouble();
    if ((startX != null && endX != null && startX >= endX) ||
        (startY != null && endY != null && startY >= endY)) {
      return null;
    }
    return RangeAnnotation(
      id: annotation.id,
      label: annotation.label,
      style: annotation.style,
      allowDragging: annotation.allowDragging,
      allowEditing: annotation.allowEditing,
      zIndex: annotation.zIndex,
      snapToValue: annotation.snapToValue,
      snapIncrement: annotation.snapIncrement,
      snapTolerance: annotation.snapTolerance,
      startX: startX,
      endX: endX,
      startY: startY,
      endY: endY,
      seriesId: annotation.seriesId,
      fillColor: annotation.fillColor,
      borderColor: annotation.borderColor,
      labelPosition: annotation.labelPosition,
      labelMargin: annotation.labelMargin,
    );
  }

  static ChordAnnotation _copyChord(
    ChordAnnotation annotation, {
    required int startIndex,
    required int endIndex,
    required int? perpendicularIndex,
  }) => ChordAnnotation(
    id: annotation.id,
    label: annotation.label,
    style: annotation.style,
    allowDragging: annotation.allowDragging,
    allowEditing: annotation.allowEditing,
    zIndex: annotation.zIndex,
    seriesId: annotation.seriesId,
    startIndex: startIndex,
    endIndex: endIndex,
    lineColor: annotation.lineColor,
    lineWidth: annotation.lineWidth,
    dashPattern: annotation.dashPattern,
    elevation: annotation.elevation,
    perpendicularIndex: perpendicularIndex,
    perpendicularLabel: perpendicularIndex == null
        ? null
        : annotation.perpendicularLabel,
    perpendicularLabelOffset: annotation.perpendicularLabelOffset,
    perpendicularLabelStyle: annotation.perpendicularLabelStyle,
    perpendicularLineColor: annotation.perpendicularLineColor,
    perpendicularLineWidth: annotation.perpendicularLineWidth,
    perpendicularDashPattern: annotation.perpendicularDashPattern,
    perpendicularElevation: annotation.perpendicularElevation,
  );

  static void _warnAnnotationOmitted(
    ChartAnnotation annotation,
    List<ChartArtifactWarning> warnings,
    String reason,
  ) {
    warnings.add(
      ChartArtifactWarning(
        code: ChartArtifactDiagnosticCodes.selectionAnnotationOmitted,
        message:
            'Annotation "${annotation.id}" was omitted from the selection-scoped chart because $reason.',
        path: _annotationPath(annotation),
      ),
    );
  }

  static String _annotationPath(ChartAnnotation annotation) =>
      '\$.annotations[${annotation.id}]';

  static _SelectionBounds? _selectionBounds(List<ChartSeries> series) {
    double? xMin;
    double? xMax;
    double? yMin;
    double? yMax;
    void include(double x, double low, double high) {
      if (!x.isFinite || !low.isFinite || !high.isFinite) return;
      xMin = xMin == null || x < xMin! ? x : xMin;
      xMax = xMax == null || x > xMax! ? x : xMax;
      yMin = yMin == null || low < yMin! ? low : yMin;
      yMax = yMax == null || high > yMax! ? high : yMax;
    }

    for (final candidate in series) {
      for (final point in candidate.points) {
        switch (point) {
          case CandlestickDataPoint():
            include(point.x, point.low, point.high);
          case RangeAreaDataPoint(isGap: false):
            include(point.x, point.low!, point.high!);
          case ChartDataPoint(isValid: true):
            include(point.x, point.y, point.y);
          case ChartDataPoint():
            break;
        }
      }
    }
    if (xMin == null || xMax == null || yMin == null || yMax == null) {
      return null;
    }
    return _SelectionBounds(xMin: xMin!, xMax: xMax!, yMin: yMin!, yMax: yMax!);
  }

  static ChartViewState _selectionViewState(
    ChartViewState source,
    List<ChartSeries> projectedSeries,
    List<YAxisConfig> projectedAxes,
  ) {
    final projectedSeriesIds = {
      for (final series in projectedSeries) series.id,
    };
    final projectedAxisIds = {for (final axis in projectedAxes) axis.id};
    return ChartViewState(
      selectedSeriesId: projectedSeriesIds.contains(source.selectedSeriesId)
          ? source.selectedSeriesId
          : null,
      selectionBrush: source.selectionBrush,
      visibleAxisIds: source.visibleAxisIds.where(projectedAxisIds.contains),
      overflowAxisIds: source.overflowAxisIds.where(projectedAxisIds.contains),
      legendPosition: source.legendPosition,
    );
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

@immutable
class _SelectionProjection {
  const _SelectionProjection({
    required this.series,
    required this.sourceFirstSeriesId,
    required this.projectedIndexBySourceIndex,
    required this.fullyRetainedSeriesIds,
    required this.bounds,
    required this.boundsBySeriesId,
  });

  final List<ChartSeries> series;
  final String? sourceFirstSeriesId;
  final Map<String, Map<int, int>> projectedIndexBySourceIndex;
  final Set<String> fullyRetainedSeriesIds;
  final _SelectionBounds? bounds;
  final Map<String, _SelectionBounds> boundsBySeriesId;

  String? resolveSeriesId(String seriesId) =>
      seriesId.isEmpty ? sourceFirstSeriesId : seriesId;

  bool containsSeries(String seriesId) {
    final resolvedSeriesId = resolveSeriesId(seriesId);
    return resolvedSeriesId != null &&
        projectedIndexBySourceIndex.containsKey(resolvedSeriesId);
  }

  bool fullyRetainsSeries(String seriesId) {
    final resolvedSeriesId = resolveSeriesId(seriesId);
    return resolvedSeriesId != null &&
        fullyRetainedSeriesIds.contains(resolvedSeriesId);
  }

  int? projectedIndex(String seriesId, int sourceIndex) {
    final resolvedSeriesId = resolveSeriesId(seriesId);
    return resolvedSeriesId == null
        ? null
        : projectedIndexBySourceIndex[resolvedSeriesId]?[sourceIndex];
  }

  _SelectionBounds? boundsFor(String? seriesId) {
    if (seriesId == null) return bounds;
    final resolvedSeriesId = resolveSeriesId(seriesId);
    return resolvedSeriesId == null ? null : boundsBySeriesId[resolvedSeriesId];
  }
}

@immutable
class _ProjectedSeriesPoints {
  const _ProjectedSeriesPoints({
    required this.points,
    required this.sourceIndexMap,
  });

  factory _ProjectedSeriesPoints.fromSourceIndices(
    ChartSeries series,
    List<int> sourceIndices,
  ) => _ProjectedSeriesPoints(
    points: [
      for (final sourceIndex in sourceIndices) series.points[sourceIndex],
    ],
    sourceIndexMap: {
      for (var index = 0; index < sourceIndices.length; index++)
        sourceIndices[index]: index,
    },
  );

  factory _ProjectedSeriesPoints.complete(ChartSeries series) =>
      _ProjectedSeriesPoints.fromSourceIndices(series, [
        for (var index = 0; index < series.points.length; index++) index,
      ]);

  final List<ChartDataPoint> points;
  final Map<int, int> sourceIndexMap;
}

@immutable
class _SelectionBounds {
  const _SelectionBounds({
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
  });

  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;

  bool contains(double x, double y) =>
      x >= xMin && x <= xMax && y >= yMin && y <= yMax;
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
