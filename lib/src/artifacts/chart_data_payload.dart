import 'package:flutter/foundation.dart';

import 'artifact_json_readers.dart';
import 'chart_annotation_document.dart';
import 'json_value.dart';

/// Reversible chart-number representation for JSON-incompatible doubles.
@immutable
class ChartNumberDocument {
  const ChartNumberDocument._(this.value, this.kind);

  factory ChartNumberDocument.fromDouble(double value) {
    if (value.isNaN) return const ChartNumberDocument._(null, 'nan');
    if (value == double.infinity) {
      return const ChartNumberDocument._(null, 'positiveInfinity');
    }
    if (value == double.negativeInfinity) {
      return const ChartNumberDocument._(null, 'negativeInfinity');
    }
    return ChartNumberDocument._(value, 'finite');
  }

  factory ChartNumberDocument.fromJson(Object? json) {
    if (json is num) return ChartNumberDocument.fromDouble(json.toDouble());
    final map = readStringMap(json, 'chart number');
    return switch (readRequiredString(map, 'kind')) {
      'nan' => const ChartNumberDocument._(null, 'nan'),
      'positiveInfinity' => const ChartNumberDocument._(
        null,
        'positiveInfinity',
      ),
      'negativeInfinity' => const ChartNumberDocument._(
        null,
        'negativeInfinity',
      ),
      final kind => throw FormatException('Unsupported chart number: $kind'),
    };
  }

  final double? value;
  final String kind;

  double get asDouble => switch (kind) {
    'finite' => value!,
    'nan' => double.nan,
    'positiveInfinity' => double.infinity,
    'negativeInfinity' => double.negativeInfinity,
    _ => throw StateError('Unsupported chart number kind: $kind'),
  };

  Object toJson() => kind == 'finite' ? value! : {'kind': kind};
}

@immutable
class ChartPointDocument {
  ChartPointDocument({
    required this.x,
    required this.y,
    this.timestamp,
    this.label,
    this.metadata,
    this.segmentStyle,
    this.pointStyle,
    Map<String, JsonValue> extensions = const {},
  }) : extensions = Map.unmodifiable(extensions);

  final ChartNumberDocument x;
  final ChartNumberDocument y;
  final DateTime? timestamp;
  final String? label;
  final JsonObjectValue? metadata;
  final JsonObjectValue? segmentStyle;
  final JsonObjectValue? pointStyle;
  final Map<String, JsonValue> extensions;

  Map<String, Object?> toJson() => {
    'x': x.toJson(),
    'y': y.toJson(),
    if (timestamp != null) 'timestamp': timestamp!.toUtc().toIso8601String(),
    if (label != null) 'label': label,
    if (metadata != null) 'metadata': metadata!.toJson(),
    if (segmentStyle != null) 'segmentStyle': segmentStyle!.toJson(),
    if (pointStyle != null) 'pointStyle': pointStyle!.toJson(),
    if (extensions.isNotEmpty) 'extensions': jsonValueMap(extensions),
  };

  factory ChartPointDocument.fromJson(Map<String, Object?> json) =>
      ChartPointDocument(
        x: ChartNumberDocument.fromJson(json['x']),
        y: ChartNumberDocument.fromJson(json['y']),
        timestamp: readOptionalDateTime(json, 'timestamp'),
        label: readOptionalString(json, 'label'),
        metadata: readOptionalJsonObject(json, 'metadata'),
        segmentStyle: readOptionalJsonObject(json, 'segmentStyle'),
        pointStyle: readOptionalJsonObject(json, 'pointStyle'),
        extensions: readOptionalJsonValueMap(json, 'extensions'),
      );
}

sealed class ChartDataPayload {
  const ChartDataPayload();

  String get storage;
  int get pointCount;
  Map<String, Object?> toJson();

  factory ChartDataPayload.fromJson(Map<String, Object?> json) {
    return switch (readRequiredString(json, 'storage')) {
      'inlinePoints' => InlinePointPayload.fromJson(json),
      final storage => throw FormatException(
        'Unsupported chart data storage: $storage',
      ),
    };
  }
}

/// Schema-v1 inline point payload.
///
/// Additional payload strategies can implement [ChartDataPayload] without
/// changing the artifact or document envelope.
@immutable
final class InlinePointPayload extends ChartDataPayload {
  InlinePointPayload(Iterable<ChartPointDocument> points)
    : points = List.unmodifiable(points);

  final List<ChartPointDocument> points;

  @override
  String get storage => 'inlinePoints';

  @override
  int get pointCount => points.length;

  @override
  Map<String, Object?> toJson() => {
    'storage': storage,
    'points': points.map((point) => point.toJson()).toList(),
  };

  factory InlinePointPayload.fromJson(Map<String, Object?> json) =>
      InlinePointPayload(
        readRequiredList(json, 'points').map(
          (point) => ChartPointDocument.fromJson(readStringMap(point, 'point')),
        ),
      );
}

@immutable
class ChartSeriesDocument {
  ChartSeriesDocument({
    required this.type,
    required this.id,
    required this.data,
    this.name,
    this.unit,
    this.axisId,
    this.inlineAxis,
    this.style,
    this.metadata,
    Iterable<ChartAnnotationDocument> annotations = const [],
    Set<String> requiredCapabilities = const {},
    Map<String, JsonValue> extensions = const {},
  }) : annotations = List.unmodifiable(annotations),
       requiredCapabilities = Set.unmodifiable(requiredCapabilities),
       extensions = Map.unmodifiable(extensions);

  final String type;
  final String id;
  final String? name;
  final String? unit;
  final String? axisId;
  final JsonObjectValue? inlineAxis;
  final JsonObjectValue? style;
  final JsonObjectValue? metadata;
  final List<ChartAnnotationDocument> annotations;
  final ChartDataPayload data;
  final Set<String> requiredCapabilities;
  final Map<String, JsonValue> extensions;

  Map<String, Object?> toJson() => {
    'type': type,
    'id': id,
    if (name != null) 'name': name,
    if (unit != null) 'unit': unit,
    if (axisId != null) 'axisId': axisId,
    if (inlineAxis != null) 'inlineAxis': inlineAxis!.toJson(),
    if (style != null) 'style': style!.toJson(),
    if (metadata != null) 'metadata': metadata!.toJson(),
    if (annotations.isNotEmpty)
      'annotations': annotations.map((item) => item.toJson()).toList(),
    'data': data.toJson(),
    if (requiredCapabilities.isNotEmpty)
      'requiredCapabilities': requiredCapabilities.toList()..sort(),
    if (extensions.isNotEmpty) 'extensions': jsonValueMap(extensions),
  };

  factory ChartSeriesDocument.fromJson(
    Map<String, Object?> json,
  ) => ChartSeriesDocument(
    type: readRequiredString(json, 'type'),
    id: readRequiredString(json, 'id'),
    name: readOptionalString(json, 'name'),
    unit: readOptionalString(json, 'unit'),
    axisId: readOptionalString(json, 'axisId'),
    inlineAxis: readOptionalJsonObject(json, 'inlineAxis'),
    style: readOptionalJsonObject(json, 'style'),
    metadata: readOptionalJsonObject(json, 'metadata'),
    annotations: readOptionalList(json, 'annotations').map(
      (item) =>
          ChartAnnotationDocument.fromJson(readStringMap(item, 'annotation')),
    ),
    data: ChartDataPayload.fromJson(readRequiredMap(json, 'data')),
    requiredCapabilities: readOptionalStringSet(json, 'requiredCapabilities'),
    extensions: readOptionalJsonValueMap(json, 'extensions'),
  );
}
