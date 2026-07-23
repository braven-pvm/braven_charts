import 'package:flutter/foundation.dart';

import '../models/interaction_config.dart';
import 'artifact_json_readers.dart';

@immutable
class ChartBoundsDocument {
  const ChartBoundsDocument({
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
  });

  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;

  Map<String, Object?> toJson() => {
    'xMin': xMin,
    'xMax': xMax,
    'yMin': yMin,
    'yMax': yMax,
  };

  factory ChartBoundsDocument.fromJson(Map<String, Object?> json) =>
      ChartBoundsDocument(
        xMin: readRequiredDouble(json, 'xMin'),
        xMax: readRequiredDouble(json, 'xMax'),
        yMin: readRequiredDouble(json, 'yMin'),
        yMax: readRequiredDouble(json, 'yMax'),
      );
}

@immutable
/// Canonical identity of one point in an effective chart document.
///
/// References are meaningful only with the `ChartDocumentRevision` that
/// issued them. They use value equality so sets, table rows, and hydrated view
/// state can compare identities without retaining runtime objects.
class ChartPointRef {
  const ChartPointRef({required this.seriesId, required this.pointIndex});

  final String seriesId;

  /// Zero-based index in the referenced series' effective point collection.
  final int pointIndex;

  Map<String, Object?> toJson() => {
    'seriesId': seriesId,
    'pointIndex': pointIndex,
  };

  factory ChartPointRef.fromJson(Map<String, Object?> json) => ChartPointRef(
    seriesId: readRequiredString(json, 'seriesId'),
    pointIndex: readRequiredInt(json, 'pointIndex'),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartPointRef &&
          other.seriesId == seriesId &&
          other.pointIndex == pointIndex;

  @override
  int get hashCode => Object.hash(seriesId, pointIndex);

  @override
  String toString() => 'ChartPointRef($seriesId, $pointIndex)';
}

@immutable
class ChartPositionDocument {
  const ChartPositionDocument({required this.x, required this.y});

  final double x;
  final double y;

  Map<String, Object?> toJson() => {'x': x, 'y': y};

  factory ChartPositionDocument.fromJson(Map<String, Object?> json) =>
      ChartPositionDocument(
        x: readRequiredDouble(json, 'x'),
        y: readRequiredDouble(json, 'y'),
      );
}

enum ChartSelectionClauseDocumentKind {
  wholeSeries,
  pointIndexSpan,
  pointKeys,
  xInterval,
  yInterval,
  explicitPointRefs,
}

/// Portable form of one compact selection clause.
///
/// This document belongs to the artifact layer so view state can retain exact
/// selection intent without depending on renderer or controller objects.
@immutable
class ChartSelectionClauseDocument {
  const ChartSelectionClauseDocument._({
    required this.kind,
    this.seriesId,
    this.startPointIndexInclusive,
    this.endPointIndexInclusive,
    this.pointKeys = const {},
    this.minimumInclusive,
    this.maximumInclusive,
    this.seriesIds,
    this.pointRefs = const [],
  });

  const ChartSelectionClauseDocument.wholeSeries({required String seriesId})
    : this._(
        kind: ChartSelectionClauseDocumentKind.wholeSeries,
        seriesId: seriesId,
      );

  const ChartSelectionClauseDocument.pointIndexSpan({
    required String seriesId,
    required int startPointIndexInclusive,
    required int endPointIndexInclusive,
  }) : this._(
         kind: ChartSelectionClauseDocumentKind.pointIndexSpan,
         seriesId: seriesId,
         startPointIndexInclusive: startPointIndexInclusive,
         endPointIndexInclusive: endPointIndexInclusive,
       );

  ChartSelectionClauseDocument.pointKeys({
    required String seriesId,
    required Iterable<String> pointKeys,
  }) : this._(
         kind: ChartSelectionClauseDocumentKind.pointKeys,
         seriesId: seriesId,
         pointKeys: Set.unmodifiable(pointKeys),
       );

  ChartSelectionClauseDocument.xInterval({
    required double minimumInclusive,
    required double maximumInclusive,
    Iterable<String>? seriesIds,
  }) : this._(
         kind: ChartSelectionClauseDocumentKind.xInterval,
         minimumInclusive: minimumInclusive,
         maximumInclusive: maximumInclusive,
         seriesIds: seriesIds == null ? null : Set.unmodifiable(seriesIds),
       );

  ChartSelectionClauseDocument.yInterval({
    required double minimumInclusive,
    required double maximumInclusive,
    Iterable<String>? seriesIds,
  }) : this._(
         kind: ChartSelectionClauseDocumentKind.yInterval,
         minimumInclusive: minimumInclusive,
         maximumInclusive: maximumInclusive,
         seriesIds: seriesIds == null ? null : Set.unmodifiable(seriesIds),
       );

  ChartSelectionClauseDocument.explicitPointRefs({
    required Iterable<ChartPointRef> pointRefs,
  }) : this._(
         kind: ChartSelectionClauseDocumentKind.explicitPointRefs,
         pointRefs: List.unmodifiable(pointRefs),
       );

  final ChartSelectionClauseDocumentKind kind;
  final String? seriesId;
  final int? startPointIndexInclusive;
  final int? endPointIndexInclusive;
  final Set<String> pointKeys;
  final double? minimumInclusive;
  final double? maximumInclusive;
  final Set<String>? seriesIds;
  final List<ChartPointRef> pointRefs;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    if (seriesId != null) 'seriesId': seriesId,
    if (startPointIndexInclusive != null)
      'startPointIndexInclusive': startPointIndexInclusive,
    if (endPointIndexInclusive != null)
      'endPointIndexInclusive': endPointIndexInclusive,
    if (pointKeys.isNotEmpty) 'pointKeys': pointKeys.toList()..sort(),
    if (minimumInclusive != null) 'minimumInclusive': minimumInclusive,
    if (maximumInclusive != null) 'maximumInclusive': maximumInclusive,
    if (seriesIds != null) 'seriesIds': seriesIds!.toList()..sort(),
    if (pointRefs.isNotEmpty)
      'pointRefs': pointRefs.map((ref) => ref.toJson()).toList(),
  };

  factory ChartSelectionClauseDocument.fromJson(Map<String, Object?> json) {
    final kindName = readRequiredString(json, 'kind');
    final kind = ChartSelectionClauseDocumentKind.values
        .where((candidate) => candidate.name == kindName)
        .firstOrNull;
    if (kind == null) {
      throw FormatException('Unsupported selection clause kind "$kindName".');
    }
    return switch (kind) {
      ChartSelectionClauseDocumentKind.wholeSeries =>
        ChartSelectionClauseDocument.wholeSeries(
          seriesId: readRequiredString(json, 'seriesId'),
        ),
      ChartSelectionClauseDocumentKind.pointIndexSpan =>
        ChartSelectionClauseDocument.pointIndexSpan(
          seriesId: readRequiredString(json, 'seriesId'),
          startPointIndexInclusive: readRequiredInt(
            json,
            'startPointIndexInclusive',
          ),
          endPointIndexInclusive: readRequiredInt(
            json,
            'endPointIndexInclusive',
          ),
        ),
      ChartSelectionClauseDocumentKind.pointKeys =>
        ChartSelectionClauseDocument.pointKeys(
          seriesId: readRequiredString(json, 'seriesId'),
          pointKeys: readOptionalStringSet(json, 'pointKeys'),
        ),
      ChartSelectionClauseDocumentKind.xInterval ||
      ChartSelectionClauseDocumentKind.yInterval =>
        (kind == ChartSelectionClauseDocumentKind.xInterval
            ? ChartSelectionClauseDocument.xInterval
            : ChartSelectionClauseDocument.yInterval)(
          minimumInclusive: readRequiredDouble(json, 'minimumInclusive'),
          maximumInclusive: readRequiredDouble(json, 'maximumInclusive'),
          seriesIds: json.containsKey('seriesIds')
              ? readOptionalStringSet(json, 'seriesIds')
              : null,
        ),
      ChartSelectionClauseDocumentKind.explicitPointRefs =>
        ChartSelectionClauseDocument.explicitPointRefs(
          pointRefs: readOptionalList(json, 'pointRefs').map(
            (item) =>
                ChartPointRef.fromJson(readStringMap(item, 'point reference')),
          ),
        ),
    };
  }
}

/// Portable compact selection intent captured with chart view state.
@immutable
class ChartSelectionExpressionDocument {
  ChartSelectionExpressionDocument({
    required Iterable<ChartSelectionClauseDocument> clauses,
  }) : clauses = List.unmodifiable(clauses);

  final List<ChartSelectionClauseDocument> clauses;

  bool get isEmpty => clauses.isEmpty;
  bool get isNotEmpty => clauses.isNotEmpty;

  Map<String, Object?> toJson() => {
    'clauses': clauses.map((clause) => clause.toJson()).toList(),
  };

  factory ChartSelectionExpressionDocument.fromJson(
    Map<String, Object?> json,
  ) => ChartSelectionExpressionDocument(
    clauses: readOptionalList(json, 'clauses').map(
      (item) => ChartSelectionClauseDocument.fromJson(
        readStringMap(item, 'selection clause'),
      ),
    ),
  );
}

/// Portable runtime state for an opt-in persistent interval-selection brush.
///
/// A cleared state is encoded explicitly so hydration can distinguish an
/// intentional clear from an older view-state document that predates brushes.
@immutable
class ChartSelectionBrushViewState {
  const ChartSelectionBrushViewState({
    required this.acquisitionMode,
    required this.range,
    required this.visible,
  }) : assert(acquisitionMode != null),
       assert(range != null),
       assert(
         acquisitionMode == ChartSelectionAcquisitionMode.xInterval ||
             acquisitionMode == ChartSelectionAcquisitionMode.yInterval,
       );

  const ChartSelectionBrushViewState.cleared()
    : acquisitionMode = null,
      range = null,
      visible = false;

  final ChartSelectionAcquisitionMode? acquisitionMode;
  final ChartSelectionBrushRange? range;
  final bool visible;

  bool get isCleared => acquisitionMode == null || range == null;

  Map<String, Object?> toJson() {
    if (isCleared) return const {'cleared': true};
    return {
      'acquisitionMode': acquisitionMode!.name,
      'minimum': range!.minimum,
      'maximum': range!.maximum,
      if (range!.referenceSeriesId != null)
        'referenceSeriesId': range!.referenceSeriesId,
      'visible': visible,
    };
  }

  factory ChartSelectionBrushViewState.fromJson(Map<String, Object?> json) {
    if (json['cleared'] == true) {
      return const ChartSelectionBrushViewState.cleared();
    }
    final modeName = readRequiredString(json, 'acquisitionMode');
    final mode = ChartSelectionAcquisitionMode.values.firstWhere(
      (value) => value.name == modeName,
      orElse: () => throw FormatException(
        'Unsupported selection brush acquisition mode "$modeName".',
      ),
    );
    if (mode != ChartSelectionAcquisitionMode.xInterval &&
        mode != ChartSelectionAcquisitionMode.yInterval) {
      throw const FormatException(
        'Selection brush acquisition mode must be xInterval or yInterval.',
      );
    }
    return ChartSelectionBrushViewState(
      acquisitionMode: mode,
      range: ChartSelectionBrushRange(
        minimum: readRequiredDouble(json, 'minimum'),
        maximum: readRequiredDouble(json, 'maximum'),
        referenceSeriesId: readOptionalString(json, 'referenceSeriesId'),
      ),
      visible: readRequiredBool(json, 'visible'),
    );
  }
}

@immutable
class ChartViewState {
  ChartViewState({
    this.visibleBounds,
    Set<String> hiddenSeriesIds = const {},
    this.selectedSeriesId,
    Iterable<String>? selectedSeriesIds,
    Iterable<ChartPointRef> selectedPointRefs = const [],
    this.selectionExpression,
    this.selectionBrush,
    Iterable<String> visibleAxisIds = const [],
    Iterable<String> overflowAxisIds = const [],
    this.selectedAnnotationId,
    this.legendPosition,
  }) : hiddenSeriesIds = Set.unmodifiable(hiddenSeriesIds),
       selectedSeriesIds = Set.unmodifiable(
         selectedSeriesIds ??
             (selectedSeriesId == null
                 ? const <String>{}
                 : <String>{selectedSeriesId}),
       ),
       selectedPointRefs = List.unmodifiable(selectedPointRefs),
       visibleAxisIds = List.unmodifiable(visibleAxisIds),
       overflowAxisIds = List.unmodifiable(overflowAxisIds);

  final ChartBoundsDocument? visibleBounds;
  final Set<String> hiddenSeriesIds;

  /// Legacy singular series activation used by Y-axis slot promotion.
  ///
  /// New consumers should use [selectedSeriesIds] for durable chart
  /// selection. The field remains portable so older artifacts and axis-slot
  /// restoration keep their established behavior.
  final String? selectedSeriesId;

  /// Durable semantic series selection captured and restored with this view.
  final Set<String> selectedSeriesIds;

  /// Durable linked-point selection captured and restored with this view.
  final List<ChartPointRef> selectedPointRefs;

  /// Exact compact selection intent.
  ///
  /// Older artifacts omit this field and continue restoring
  /// [selectedSeriesIds] and [selectedPointRefs].
  final ChartSelectionExpressionDocument? selectionExpression;

  /// Current persistent brush position and visibility.
  ///
  /// Null means the source view-state document predates brush persistence.
  /// [ChartSelectionBrushViewState.cleared] records an intentional clear.
  final ChartSelectionBrushViewState? selectionBrush;
  final List<String> visibleAxisIds;
  final List<String> overflowAxisIds;
  final String? selectedAnnotationId;
  final ChartPositionDocument? legendPosition;

  Map<String, Object?> toJson() => {
    if (visibleBounds != null) 'visibleBounds': visibleBounds!.toJson(),
    'hiddenSeriesIds': hiddenSeriesIds.toList()..sort(),
    if (selectedSeriesId != null) 'selectedSeriesId': selectedSeriesId,
    if (selectedSeriesIds.isNotEmpty || selectedSeriesId != null)
      'selectedSeriesIds': selectedSeriesIds.toList()..sort(),
    'selectedPointRefs': selectedPointRefs.map((ref) => ref.toJson()).toList(),
    if (selectionExpression?.isNotEmpty ?? false)
      'selectionExpression': selectionExpression!.toJson(),
    if (selectionBrush != null) 'selectionBrush': selectionBrush!.toJson(),
    'visibleAxisIds': visibleAxisIds,
    'overflowAxisIds': overflowAxisIds,
    if (selectedAnnotationId != null)
      'selectedAnnotationId': selectedAnnotationId,
    if (legendPosition != null) 'legendPosition': legendPosition!.toJson(),
  };

  factory ChartViewState.fromJson(Map<String, Object?> json) => ChartViewState(
    visibleBounds: json['visibleBounds'] == null
        ? null
        : ChartBoundsDocument.fromJson(readRequiredMap(json, 'visibleBounds')),
    hiddenSeriesIds: readOptionalStringSet(json, 'hiddenSeriesIds'),
    selectedSeriesId: readOptionalString(json, 'selectedSeriesId'),
    selectedSeriesIds: json.containsKey('selectedSeriesIds')
        ? readOptionalStringSet(json, 'selectedSeriesIds')
        : null,
    selectedPointRefs: readOptionalList(json, 'selectedPointRefs').map(
      (item) => ChartPointRef.fromJson(readStringMap(item, 'point reference')),
    ),
    selectionExpression: json['selectionExpression'] == null
        ? null
        : ChartSelectionExpressionDocument.fromJson(
            readRequiredMap(json, 'selectionExpression'),
          ),
    selectionBrush: json['selectionBrush'] == null
        ? null
        : ChartSelectionBrushViewState.fromJson(
            readRequiredMap(json, 'selectionBrush'),
          ),
    visibleAxisIds: readOptionalStringList(json, 'visibleAxisIds'),
    overflowAxisIds: readOptionalStringList(json, 'overflowAxisIds'),
    selectedAnnotationId: readOptionalString(json, 'selectedAnnotationId'),
    legendPosition: json['legendPosition'] == null
        ? null
        : ChartPositionDocument.fromJson(
            readRequiredMap(json, 'legendPosition'),
          ),
  );
}
