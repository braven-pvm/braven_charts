import 'package:flutter/foundation.dart';

import '../artifacts/chart_view_state.dart';
import 'chart_data_point.dart';
import 'chart_series.dart';

/// Portable identity of one keyed point in a chart series.
///
/// [ChartPointRef] remains the fastest identity inside one effective document
/// revision. This key-based reference is used when identity must survive point
/// reorder, insertion, or bounded-stream eviction between revisions.
@immutable
class ChartPointKeyRef {
  const ChartPointKeyRef({required this.seriesId, required this.pointKey})
    : assert(seriesId != '', 'seriesId must not be empty'),
      assert(pointKey != '', 'pointKey must not be empty');

  final String seriesId;
  final String pointKey;

  Map<String, Object?> toJson() => {'seriesId': seriesId, 'pointKey': pointKey};

  factory ChartPointKeyRef.fromJson(Map<String, Object?> json) {
    String readIdentity(String field) {
      final value = json[field];
      if (value is! String || value.isEmpty) {
        throw FormatException('$field must be a non-empty string');
      }
      return value;
    }

    return ChartPointKeyRef(
      seriesId: readIdentity('seriesId'),
      pointKey: readIdentity('pointKey'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ChartPointKeyRef &&
      other.seriesId == seriesId &&
      other.pointKey == pointKey;

  @override
  int get hashCode => Object.hash(seriesId, pointKey);

  @override
  String toString() => 'ChartPointKeyRef($seriesId, $pointKey)';
}

/// Lazily constructed stable-key lookup for one immutable chart series.
///
/// Duplicate keys are rejected when the index is requested because remapping
/// an ambiguous identity would silently select the wrong observation.
@immutable
class ChartPointKeyIndex {
  ChartPointKeyIndex(ChartSeries series)
    : seriesId = series.id,
      _points = series.points;

  final String seriesId;
  final List<ChartDataPoint> _points;

  late final Map<String, int> _pointIndexByKey = _buildIndex();

  int? pointIndexFor(String pointKey) => _pointIndexByKey[pointKey];

  ChartPointRef? resolve(ChartPointKeyRef reference) {
    if (reference.seriesId != seriesId) return null;
    final pointIndex = pointIndexFor(reference.pointKey);
    return pointIndex == null
        ? null
        : ChartPointRef(seriesId: seriesId, pointIndex: pointIndex);
  }

  ChartPointKeyRef? keyFor(ChartPointRef reference) {
    if (reference.seriesId != seriesId ||
        reference.pointIndex < 0 ||
        reference.pointIndex >= _points.length) {
      return null;
    }
    final pointKey = _points[reference.pointIndex].pointKey;
    return pointKey == null
        ? null
        : ChartPointKeyRef(seriesId: seriesId, pointKey: pointKey);
  }

  Map<String, int> _buildIndex() {
    final result = <String, int>{};
    for (var pointIndex = 0; pointIndex < _points.length; pointIndex++) {
      final pointKey = _points[pointIndex].pointKey;
      if (pointKey == null) continue;
      final previousIndex = result[pointKey];
      if (previousIndex != null) {
        throw ArgumentError.value(
          pointKey,
          'pointKey',
          'Duplicate point key in series "$seriesId" at indexes '
              '$previousIndex and $pointIndex',
        );
      }
      result[pointKey] = pointIndex;
    }
    return Map.unmodifiable(result);
  }
}
