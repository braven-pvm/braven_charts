import 'package:flutter/foundation.dart';

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
class ChartPointRef {
  const ChartPointRef({required this.seriesId, required this.pointIndex});

  final String seriesId;
  final int pointIndex;

  Map<String, Object?> toJson() => {
    'seriesId': seriesId,
    'pointIndex': pointIndex,
  };

  factory ChartPointRef.fromJson(Map<String, Object?> json) => ChartPointRef(
    seriesId: readRequiredString(json, 'seriesId'),
    pointIndex: readRequiredInt(json, 'pointIndex'),
  );
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

@immutable
class ChartViewState {
  ChartViewState({
    this.visibleBounds,
    Set<String> hiddenSeriesIds = const {},
    this.selectedSeriesId,
    Iterable<ChartPointRef> selectedPointRefs = const [],
    Iterable<String> visibleAxisIds = const [],
    Iterable<String> overflowAxisIds = const [],
    this.selectedAnnotationId,
    this.legendPosition,
  }) : hiddenSeriesIds = Set.unmodifiable(hiddenSeriesIds),
       selectedPointRefs = List.unmodifiable(selectedPointRefs),
       visibleAxisIds = List.unmodifiable(visibleAxisIds),
       overflowAxisIds = List.unmodifiable(overflowAxisIds);

  final ChartBoundsDocument? visibleBounds;
  final Set<String> hiddenSeriesIds;
  final String? selectedSeriesId;
  final List<ChartPointRef> selectedPointRefs;
  final List<String> visibleAxisIds;
  final List<String> overflowAxisIds;
  final String? selectedAnnotationId;
  final ChartPositionDocument? legendPosition;

  Map<String, Object?> toJson() => {
    if (visibleBounds != null) 'visibleBounds': visibleBounds!.toJson(),
    'hiddenSeriesIds': hiddenSeriesIds.toList()..sort(),
    if (selectedSeriesId != null) 'selectedSeriesId': selectedSeriesId,
    'selectedPointRefs': selectedPointRefs.map((ref) => ref.toJson()).toList(),
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
    selectedPointRefs: readOptionalList(json, 'selectedPointRefs').map(
      (item) => ChartPointRef.fromJson(readStringMap(item, 'point reference')),
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
