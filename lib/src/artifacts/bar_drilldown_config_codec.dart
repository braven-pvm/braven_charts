import '../models/bar_drilldown.dart';
import '../models/chart_series.dart';
import 'chart_artifact_diagnostics.dart';
import 'chart_data_payload.dart';
import 'chart_series_document_codec.dart';
import 'json_value.dart';

/// Versioned, JSON-safe codec for a static [BarDrilldownConfig] hierarchy.
abstract final class BarDrilldownConfigCodec {
  static const int schemaVersion = 1;

  static ChartArtifactResult<Map<String, Object?>> encode(
    BarDrilldownConfig config,
  ) {
    try {
      final ids = <String>{};
      final root = _encodeNode(config.root, ids: ids, depth: 0);
      if (root case final ChartArtifactFailure<Map<String, Object?>> failure) {
        return failure;
      }
      return ChartArtifactSuccess(
        value: <String, Object?>{
          'type': 'barDrilldown',
          'schemaVersion': schemaVersion,
          'root': (root as ChartArtifactSuccess<Map<String, Object?>>).value,
          'activation': config.activation.name,
          'transition': config.transition.name,
          'showBreadcrumbs': config.showBreadcrumbs,
          'selectionPolicy': config.selectionPolicy.name,
          if (config.lazyResolverBinding != null)
            'lazyResolverBinding': config.lazyResolverBinding,
        },
      );
    } on FormatException catch (error) {
      return _failure(error.message);
    }
  }

  static ChartArtifactResult<BarDrilldownConfig> decode(
    Map<String, Object?> json,
  ) {
    try {
      if (json['type'] != 'barDrilldown') {
        throw const FormatException('Expected a barDrilldown document.');
      }
      if (_integer(json, 'schemaVersion') != schemaVersion) {
        throw const FormatException('Unsupported drill-down schema version.');
      }
      final ids = <String>{};
      final root = _decodeNode(_requiredMap(json, 'root'), ids: ids, depth: 0);
      if (root case final ChartArtifactFailure<BarDrillNode> failure) {
        return _retypeFailure(failure);
      }
      return ChartArtifactSuccess(
        value: BarDrilldownConfig(
          root: (root as ChartArtifactSuccess<BarDrillNode>).value,
          activation: BarDrillActivation.values.byName(
            _string(json, 'activation'),
          ),
          transition: BarDrillTransition.values.byName(
            _string(json, 'transition'),
          ),
          showBreadcrumbs: _boolean(json, 'showBreadcrumbs'),
          selectionPolicy: BarDrillSelectionPolicy.values.byName(
            _string(json, 'selectionPolicy'),
          ),
          lazyResolverBinding: _optionalString(json, 'lazyResolverBinding'),
        ),
      );
    } on Object catch (error) {
      return _failure(error is FormatException ? error.message : '$error');
    }
  }

  static ChartArtifactResult<Map<String, Object?>> _encodeNode(
    BarDrillNode node, {
    required Set<String> ids,
    required int depth,
  }) {
    if (depth > 64) return _failure('Hierarchy depth exceeds 64 levels.');
    if (!ids.add(node.id)) return _failure('Duplicate node ID "${node.id}".');
    final encodedSeries = <Object?>[];
    for (final series in node.series) {
      final encoded = ChartSeriesDocumentCodec.encode(series);
      if (encoded
          case final ChartArtifactFailure<ChartSeriesDocument> failure) {
        return _retypeFailure(failure);
      }
      encodedSeries.add(
        (encoded as ChartArtifactSuccess<ChartSeriesDocument>).value.toJson(),
      );
    }
    final children = <Object?>[];
    for (final child in node.children) {
      final encoded = _encodeNode(child, ids: ids, depth: depth + 1);
      if (encoded
          case final ChartArtifactFailure<Map<String, Object?>> failure) {
        return failure;
      }
      children.add(
        (encoded as ChartArtifactSuccess<Map<String, Object?>>).value,
      );
    }
    final safeMetadata = JsonValue.fromJson(node.metadata).toJson();
    return ChartArtifactSuccess(
      value: <String, Object?>{
        'id': node.id,
        'label': node.label,
        'series': encodedSeries,
        'children': children,
        'metadata': safeMetadata,
        'mayHaveLazyChildren': node.mayHaveLazyChildren,
      },
    );
  }

  static ChartArtifactResult<BarDrillNode> _decodeNode(
    Map<String, Object?> json, {
    required Set<String> ids,
    required int depth,
  }) {
    if (depth > 64) return _failure('Hierarchy depth exceeds 64 levels.');
    final id = _string(json, 'id');
    if (!ids.add(id)) return _failure('Duplicate node ID "$id".');
    final series = <ChartSeries>[];
    for (final value in _list(json, 'series')) {
      final document = ChartSeriesDocument.fromJson(_map(value, 'series'));
      final decoded = ChartSeriesDocumentCodec.decode(document);
      if (decoded case final ChartArtifactFailure<ChartSeries> failure) {
        return _retypeFailure(failure);
      }
      series.add((decoded as ChartArtifactSuccess<ChartSeries>).value);
    }
    final children = <BarDrillNode>[];
    for (final value in _list(json, 'children')) {
      final decoded = _decodeNode(
        _map(value, 'child'),
        ids: ids,
        depth: depth + 1,
      );
      if (decoded case final ChartArtifactFailure<BarDrillNode> failure) {
        return failure;
      }
      children.add((decoded as ChartArtifactSuccess<BarDrillNode>).value);
    }
    final rawMetadata = _requiredMap(json, 'metadata');
    final metadata = _map(
      (JsonValue.fromJson(rawMetadata) as JsonObjectValue).toJson(),
      'metadata',
    );
    return ChartArtifactSuccess(
      value: BarDrillNode(
        id: id,
        label: _string(json, 'label'),
        series: List.unmodifiable(series),
        children: List.unmodifiable(children),
        metadata: metadata,
        mayHaveLazyChildren: _boolean(json, 'mayHaveLazyChildren'),
      ),
    );
  }

  static ChartArtifactFailure<T> _failure<T>(String message) =>
      ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: message,
        ),
      );

  static ChartArtifactFailure<T> _retypeFailure<T, S>(
    ChartArtifactFailure<S> failure,
  ) => ChartArtifactFailure(error: failure.error, warnings: failure.warnings);
}

Map<String, Object?> _requiredMap(Map<String, Object?> source, String key) =>
    _map(source[key], key);

Map<String, Object?> _map(Object? value, String name) {
  if (value is! Map) throw FormatException('$name must be an object.');
  return value.map((key, value) => MapEntry(key.toString(), value));
}

List<Object?> _list(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value is! List) throw FormatException('$key must be an array.');
  return value.cast<Object?>();
}

String _string(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}

String? _optionalString(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value == null) return null;
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be a non-empty string when present.');
  }
  return value;
}

int _integer(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value is! num || value.toInt() != value) {
    throw FormatException('$key must be an integer.');
  }
  return value.toInt();
}

bool _boolean(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value is! bool) throw FormatException('$key must be a boolean.');
  return value;
}
