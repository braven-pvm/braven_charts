import 'package:flutter/foundation.dart';

import 'artifact_json_readers.dart';
import 'chart_annotation_document.dart';
import 'chart_data_storage.dart';
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
    this.pointKey,
    this.magnitude,
    this.colorValue,
    this.opacityValue,
    this.categoryValue,
    this.timestamp,
    this.label,
    this.metadata,
    this.segmentStyle,
    this.pointStyle,
    Map<String, JsonValue> extensions = const {},
  }) : extensions = Map.unmodifiable(extensions);

  final ChartNumberDocument x;
  final ChartNumberDocument y;
  final String? pointKey;
  final ChartNumberDocument? magnitude;
  final ChartNumberDocument? colorValue;
  final ChartNumberDocument? opacityValue;
  final String? categoryValue;
  final DateTime? timestamp;
  final String? label;
  final JsonObjectValue? metadata;
  final JsonObjectValue? segmentStyle;
  final JsonObjectValue? pointStyle;
  final Map<String, JsonValue> extensions;

  Map<String, Object?> toJson() => {
    'x': x.toJson(),
    'y': y.toJson(),
    if (pointKey != null) 'pointKey': pointKey,
    if (magnitude != null) 'magnitude': magnitude!.toJson(),
    if (colorValue != null) 'colorValue': colorValue!.toJson(),
    if (opacityValue != null) 'opacityValue': opacityValue!.toJson(),
    if (categoryValue != null) 'categoryValue': categoryValue,
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
        pointKey: readOptionalString(json, 'pointKey'),
        magnitude: json.containsKey('magnitude') && json['magnitude'] != null
            ? ChartNumberDocument.fromJson(json['magnitude'])
            : null,
        colorValue: json.containsKey('colorValue') && json['colorValue'] != null
            ? ChartNumberDocument.fromJson(json['colorValue'])
            : null,
        opacityValue:
            json.containsKey('opacityValue') && json['opacityValue'] != null
            ? ChartNumberDocument.fromJson(json['opacityValue'])
            : null,
        categoryValue: readOptionalString(json, 'categoryValue'),
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
      'inlineColumns' => InlineColumnarPayload.fromJson(json),
      ReferencedPayload.storageName => ReferencedPayload.fromJson(json),
      final storage => throw FormatException(
        'Unsupported chart data storage: $storage',
      ),
    };
  }
}

/// Host-resolved reference to one self-contained chart data payload blob.
///
/// The package validates this manifest but never performs network or file I/O.
/// A host-authorized resolver supplies the bytes when requested.
@immutable
final class ReferencedPayload extends ChartDataPayload {
  ReferencedPayload({
    required this.contentType,
    required this.byteLength,
    required this.checksum,
    required this.pointCount,
    this.resolverKey,
    this.uri,
  }) {
    if (!_contentTypePattern.hasMatch(contentType)) {
      throw ArgumentError.value(
        contentType,
        'contentType',
        'Invalid MIME type',
      );
    }
    if (byteLength <= 0) {
      throw ArgumentError.value(byteLength, 'byteLength', 'Must be positive');
    }
    if (!_checksumPattern.hasMatch(checksum)) {
      throw ArgumentError.value(
        checksum,
        'checksum',
        'Must be a lowercase sha256 digest',
      );
    }
    if (pointCount < 0) {
      throw ArgumentError.value(pointCount, 'pointCount', 'Cannot be negative');
    }
    if (resolverKey != null && resolverKey!.trim().isEmpty) {
      throw ArgumentError.value(resolverKey, 'resolverKey', 'Cannot be blank');
    }
    final hasResolverKey = resolverKey != null;
    final hasUri = uri != null;
    if (hasResolverKey == hasUri) {
      throw ArgumentError(
        'Exactly one of resolverKey or uri must be provided.',
      );
    }
    if (uri case final value?) {
      if (!value.isAbsolute || value.hasFragment || value.userInfo.isNotEmpty) {
        throw ArgumentError.value(
          value,
          'uri',
          'Must be absolute and contain no user info or fragment',
        );
      }
    }
  }

  static final RegExp _contentTypePattern = RegExp(
    r'^[a-z0-9][a-z0-9!#$&^_.+-]*/[a-z0-9][a-z0-9!#$&^_.+-]*$',
    caseSensitive: false,
  );
  static final RegExp _checksumPattern = RegExp(r'^sha256:[0-9a-f]{64}$');
  static const storageName = 'referenced';

  @override
  String get storage => storageName;

  final String contentType;
  final int byteLength;
  final String checksum;
  @override
  final int pointCount;
  final String? resolverKey;
  final Uri? uri;

  @override
  Map<String, Object?> toJson() => {
    'storage': storage,
    'contentType': contentType,
    'byteLength': byteLength,
    'checksum': checksum,
    'pointCount': pointCount,
    if (resolverKey != null) 'resolverKey': resolverKey,
    if (uri != null) 'uri': uri.toString(),
  };

  factory ReferencedPayload.fromJson(Map<String, Object?> json) {
    final uriValue = readOptionalString(json, 'uri');
    final uri = uriValue == null ? null : Uri.tryParse(uriValue);
    if (uriValue != null && uri == null) {
      throw const FormatException('uri must be a valid URI');
    }
    return ReferencedPayload(
      contentType: readRequiredString(json, 'contentType'),
      byteLength: readRequiredInt(json, 'byteLength'),
      checksum: readRequiredString(json, 'checksum'),
      pointCount: readRequiredInt(json, 'pointCount'),
      resolverKey: readOptionalString(json, 'resolverKey'),
      uri: uri,
    );
  }
}

/// A self-contained payload whose logical points are synchronously available.
sealed class InlineChartDataPayload extends ChartDataPayload {
  const InlineChartDataPayload();

  List<ChartPointDocument> get points;
}

/// Schema-v1 inline point payload.
///
/// Additional payload strategies can implement [ChartDataPayload] without
/// changing the artifact or document envelope.
@immutable
final class InlinePointPayload extends InlineChartDataPayload {
  InlinePointPayload(Iterable<ChartPointDocument> points)
    : points = List.unmodifiable(points);

  @override
  final List<ChartPointDocument> points;

  @override
  String get storage => ChartDataStorage.inlinePoints.wireName;

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

/// Schema-v1 columnar point payload.
///
/// Required X/Y values and optional point properties are stored in parallel
/// arrays. Every populated column has exactly [pointCount] entries so logical
/// point order and sparse optional values remain lossless.
@immutable
final class InlineColumnarPayload extends InlineChartDataPayload {
  InlineColumnarPayload({
    required Iterable<ChartNumberDocument> xValues,
    required Iterable<ChartNumberDocument> yValues,
    Iterable<ChartNumberDocument?>? magnitudes,
    Iterable<ChartNumberDocument?>? colorValues,
    Iterable<ChartNumberDocument?>? opacityValues,
    Iterable<String?>? categoryValues,
    Iterable<DateTime?>? timestamps,
    Iterable<String?>? labels,
    Iterable<String?>? pointKeys,
    Iterable<JsonObjectValue?>? metadata,
    Iterable<JsonObjectValue?>? segmentStyles,
    Iterable<JsonObjectValue?>? pointStyles,
    Iterable<Map<String, JsonValue>?>? pointExtensions,
  }) : xValues = List.unmodifiable(xValues),
       yValues = List.unmodifiable(yValues),
       magnitudes = _immutableOptionalColumn(magnitudes),
       colorValues = _immutableOptionalColumn(colorValues),
       opacityValues = _immutableOptionalColumn(opacityValues),
       categoryValues = _immutableOptionalColumn(categoryValues),
       timestamps = _immutableOptionalColumn(timestamps),
       labels = _immutableOptionalColumn(labels),
       pointKeys = _immutableOptionalColumn(pointKeys),
       metadata = _immutableOptionalColumn(metadata),
       segmentStyles = _immutableOptionalColumn(segmentStyles),
       pointStyles = _immutableOptionalColumn(pointStyles),
       pointExtensions = pointExtensions == null
           ? null
           : List.unmodifiable(
               pointExtensions.map(
                 (values) => values == null
                     ? null
                     : Map<String, JsonValue>.unmodifiable(values),
               ),
             ) {
    _validateColumnLength('y', this.yValues.length);
    _validateColumnLength('timestamps', this.timestamps?.length);
    _validateColumnLength('magnitudes', this.magnitudes?.length);
    _validateColumnLength('colorValues', this.colorValues?.length);
    _validateColumnLength('opacityValues', this.opacityValues?.length);
    _validateColumnLength('categoryValues', this.categoryValues?.length);
    _validateColumnLength('labels', this.labels?.length);
    _validateColumnLength('pointKeys', this.pointKeys?.length);
    _validateColumnLength('metadata', this.metadata?.length);
    _validateColumnLength('segmentStyles', this.segmentStyles?.length);
    _validateColumnLength('pointStyles', this.pointStyles?.length);
    _validateColumnLength('pointExtensions', this.pointExtensions?.length);
  }

  factory InlineColumnarPayload.fromPoints(
    Iterable<ChartPointDocument> source,
  ) {
    final points = List<ChartPointDocument>.unmodifiable(source);
    return InlineColumnarPayload(
      xValues: [for (final point in points) point.x],
      yValues: [for (final point in points) point.y],
      magnitudes: _optionalPointColumn(points, (point) => point.magnitude),
      colorValues: _optionalPointColumn(points, (point) => point.colorValue),
      opacityValues: _optionalPointColumn(
        points,
        (point) => point.opacityValue,
      ),
      categoryValues: _optionalPointColumn(
        points,
        (point) => point.categoryValue,
      ),
      timestamps: _optionalPointColumn(points, (point) => point.timestamp),
      labels: _optionalPointColumn(points, (point) => point.label),
      pointKeys: _optionalPointColumn(points, (point) => point.pointKey),
      metadata: _optionalPointColumn(points, (point) => point.metadata),
      segmentStyles: _optionalPointColumn(
        points,
        (point) => point.segmentStyle,
      ),
      pointStyles: _optionalPointColumn(points, (point) => point.pointStyle),
      pointExtensions: _optionalPointColumn(
        points,
        (point) => point.extensions.isEmpty ? null : point.extensions,
      ),
    );
  }

  final List<ChartNumberDocument> xValues;
  final List<ChartNumberDocument> yValues;
  final List<ChartNumberDocument?>? magnitudes;
  final List<ChartNumberDocument?>? colorValues;
  final List<ChartNumberDocument?>? opacityValues;
  final List<String?>? categoryValues;
  final List<DateTime?>? timestamps;
  final List<String?>? labels;
  final List<String?>? pointKeys;
  final List<JsonObjectValue?>? metadata;
  final List<JsonObjectValue?>? segmentStyles;
  final List<JsonObjectValue?>? pointStyles;
  final List<Map<String, JsonValue>?>? pointExtensions;

  @override
  String get storage => ChartDataStorage.inlineColumns.wireName;

  @override
  int get pointCount => xValues.length;

  @override
  late final List<ChartPointDocument> points = List.unmodifiable([
    for (var index = 0; index < pointCount; index++)
      ChartPointDocument(
        x: xValues[index],
        y: yValues[index],
        magnitude: magnitudes?[index],
        colorValue: colorValues?[index],
        opacityValue: opacityValues?[index],
        categoryValue: categoryValues?[index],
        timestamp: timestamps?[index],
        label: labels?[index],
        pointKey: pointKeys?[index],
        metadata: metadata?[index],
        segmentStyle: segmentStyles?[index],
        pointStyle: pointStyles?[index],
        extensions: pointExtensions?[index] ?? const {},
      ),
  ]);

  @override
  Map<String, Object?> toJson() => {
    'storage': storage,
    'x': [for (final value in xValues) value.toJson()],
    'y': [for (final value in yValues) value.toJson()],
    if (magnitudes != null)
      'magnitudes': [for (final value in magnitudes!) value?.toJson()],
    if (colorValues != null)
      'colorValues': [for (final value in colorValues!) value?.toJson()],
    if (opacityValues != null)
      'opacityValues': [for (final value in opacityValues!) value?.toJson()],
    if (categoryValues != null) 'categoryValues': categoryValues,
    if (timestamps != null)
      'timestamps': [
        for (final value in timestamps!) value?.toUtc().toIso8601String(),
      ],
    if (labels != null) 'labels': labels,
    if (pointKeys != null) 'pointKeys': pointKeys,
    if (metadata != null)
      'metadata': [for (final value in metadata!) value?.toJson()],
    if (segmentStyles != null)
      'segmentStyles': [for (final value in segmentStyles!) value?.toJson()],
    if (pointStyles != null)
      'pointStyles': [for (final value in pointStyles!) value?.toJson()],
    if (pointExtensions != null)
      'pointExtensions': [
        for (final value in pointExtensions!)
          value == null ? null : jsonValueMap(value),
      ],
  };

  /// Codec-facing constructor for decoded numeric columns plus JSON sidecars.
  factory InlineColumnarPayload.fromDecodedColumns({
    required Iterable<ChartNumberDocument> xValues,
    required Iterable<ChartNumberDocument> yValues,
    required Map<String, Object?> optionalColumns,
  }) => InlineColumnarPayload(
    xValues: xValues,
    yValues: yValues,
    magnitudes: _readOptionalColumn(
      optionalColumns,
      'magnitudes',
      (value, path) =>
          value == null ? null : ChartNumberDocument.fromJson(value),
    ),
    colorValues: _readOptionalColumn(
      optionalColumns,
      'colorValues',
      (value, path) =>
          value == null ? null : ChartNumberDocument.fromJson(value),
    ),
    opacityValues: _readOptionalColumn(
      optionalColumns,
      'opacityValues',
      (value, path) =>
          value == null ? null : ChartNumberDocument.fromJson(value),
    ),
    categoryValues: _readOptionalColumn(optionalColumns, 'categoryValues', (
      value,
      path,
    ) {
      if (value == null) return null;
      if (value is! String) {
        throw FormatException('$path must be a string or null');
      }
      return value;
    }),
    timestamps: _readOptionalColumn(optionalColumns, 'timestamps', (
      value,
      path,
    ) {
      if (value == null) return null;
      if (value is! String) {
        throw FormatException('$path must be an ISO-8601 string or null');
      }
      final parsed = DateTime.tryParse(value);
      if (parsed == null) {
        throw FormatException('$path must be an ISO-8601 string or null');
      }
      return parsed.toUtc();
    }),
    labels: _readOptionalColumn(optionalColumns, 'labels', (value, path) {
      if (value == null) return null;
      if (value is! String) {
        throw FormatException('$path must be a string or null');
      }
      return value;
    }),
    pointKeys: _readOptionalColumn(optionalColumns, 'pointKeys', (value, path) {
      if (value == null) return null;
      if (value is! String || value.isEmpty) {
        throw FormatException('$path must be a non-empty string or null');
      }
      return value;
    }),
    metadata: _readOptionalJsonObjectColumn(optionalColumns, 'metadata'),
    segmentStyles: _readOptionalJsonObjectColumn(
      optionalColumns,
      'segmentStyles',
    ),
    pointStyles: _readOptionalJsonObjectColumn(optionalColumns, 'pointStyles'),
    pointExtensions: _readOptionalColumn(optionalColumns, 'pointExtensions', (
      value,
      path,
    ) {
      if (value == null) return null;
      final object = JsonValue.fromJson(value, path: path);
      if (object is! JsonObjectValue) {
        throw FormatException('$path must be an object or null');
      }
      return object.values;
    }),
  );

  factory InlineColumnarPayload.fromJson(Map<String, Object?> json) =>
      InlineColumnarPayload.fromDecodedColumns(
        xValues: readRequiredList(json, 'x').map(ChartNumberDocument.fromJson),
        yValues: readRequiredList(json, 'y').map(ChartNumberDocument.fromJson),
        optionalColumns: json,
      );

  void _validateColumnLength(String name, int? length) {
    if (length != null && length != pointCount) {
      throw ArgumentError.value(
        length,
        name,
        'Column length must equal the X column length $pointCount',
      );
    }
  }
}

List<T>? _immutableOptionalColumn<T>(Iterable<T>? values) =>
    values == null ? null : List.unmodifiable(values);

List<T?>? _optionalPointColumn<T>(
  List<ChartPointDocument> points,
  T? Function(ChartPointDocument point) read,
) {
  final values = [for (final point in points) read(point)];
  return values.any((value) => value != null) ? values : null;
}

List<T>? _readOptionalColumn<T>(
  Map<String, Object?> json,
  String key,
  T Function(Object? value, String path) parse,
) {
  if (!json.containsKey(key) || json[key] == null) return null;
  final values = readRequiredList(json, key);
  return [
    for (var index = 0; index < values.length; index++)
      parse(values[index], '\$.$key[$index]'),
  ];
}

List<JsonObjectValue?>? _readOptionalJsonObjectColumn(
  Map<String, Object?> json,
  String key,
) => _readOptionalColumn(json, key, (value, path) {
  if (value == null) return null;
  final object = JsonValue.fromJson(value, path: path);
  if (object is! JsonObjectValue) {
    throw FormatException('$path must be an object or null');
  }
  return object;
});

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
