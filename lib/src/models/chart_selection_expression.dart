import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../artifacts/chart_document_extractor.dart';
import '../artifacts/chart_view_state.dart';
import 'chart_data_point.dart';
import 'chart_point_identity.dart';
import 'chart_selection_result.dart';
import 'chart_series.dart';

/// One compact, renderer-neutral clause in a chart selection expression.
///
/// Clauses describe durable selection intent. They are resolved against one
/// effective chart revision only when a consumer requests concrete points.
@immutable
sealed class ChartSelectionClause {
  const ChartSelectionClause();
}

/// Selects every source point owned by [seriesId].
@immutable
final class ChartSelectionWholeSeriesClause extends ChartSelectionClause {
  const ChartSelectionWholeSeriesClause({required this.seriesId})
    : assert(seriesId != '', 'seriesId must not be empty');

  final String seriesId;

  @override
  bool operator ==(Object other) =>
      other is ChartSelectionWholeSeriesClause && other.seriesId == seriesId;

  @override
  int get hashCode => seriesId.hashCode;
}

/// Selects one inclusive contiguous source-index span in [seriesId].
@immutable
final class ChartSelectionPointIndexSpanClause extends ChartSelectionClause {
  const ChartSelectionPointIndexSpanClause({
    required this.seriesId,
    required this.startPointIndexInclusive,
    required this.endPointIndexInclusive,
  }) : assert(seriesId != '', 'seriesId must not be empty'),
       assert(
         startPointIndexInclusive >= 0,
         'startPointIndexInclusive must be non-negative',
       ),
       assert(
         endPointIndexInclusive >= startPointIndexInclusive,
         'endPointIndexInclusive must not precede the start',
       );

  final String seriesId;
  final int startPointIndexInclusive;
  final int endPointIndexInclusive;

  @override
  bool operator ==(Object other) =>
      other is ChartSelectionPointIndexSpanClause &&
      other.seriesId == seriesId &&
      other.startPointIndexInclusive == startPointIndexInclusive &&
      other.endPointIndexInclusive == endPointIndexInclusive;

  @override
  int get hashCode =>
      Object.hash(seriesId, startPointIndexInclusive, endPointIndexInclusive);
}

/// Selects explicitly keyed observations in one series.
///
/// Keys resolve against the current series topology, so this clause survives
/// point reorder, insertion, and bounded-stream eviction.
@immutable
final class ChartSelectionPointKeysClause extends ChartSelectionClause {
  ChartSelectionPointKeysClause({
    required this.seriesId,
    required Iterable<String> pointKeys,
  }) : assert(seriesId != '', 'seriesId must not be empty'),
       assert(pointKeys.every((key) => key.isNotEmpty)),
       pointKeys = Set.unmodifiable(pointKeys);

  final String seriesId;
  final Set<String> pointKeys;

  @override
  bool operator ==(Object other) =>
      other is ChartSelectionPointKeysClause &&
      other.seriesId == seriesId &&
      setEquals(other.pointKeys, pointKeys);

  @override
  int get hashCode => Object.hash(seriesId, Object.hashAllUnordered(pointKeys));
}

/// Selects finite points whose X value is inside an inclusive interval.
///
/// A null [seriesIds] applies to every series in the resolved chart. An empty
/// set deliberately resolves no points.
@immutable
final class ChartSelectionXIntervalClause extends ChartSelectionClause {
  ChartSelectionXIntervalClause({
    required this.minimumXInclusive,
    required this.maximumXInclusive,
    Set<String>? seriesIds,
  }) : assert(minimumXInclusive.isFinite),
       assert(maximumXInclusive.isFinite),
       assert(minimumXInclusive <= maximumXInclusive),
       seriesIds = seriesIds == null ? null : Set.unmodifiable(seriesIds);

  final double minimumXInclusive;
  final double maximumXInclusive;
  final Set<String>? seriesIds;

  @override
  bool operator ==(Object other) =>
      other is ChartSelectionXIntervalClause &&
      other.minimumXInclusive == minimumXInclusive &&
      other.maximumXInclusive == maximumXInclusive &&
      setEquals(other.seriesIds, seriesIds);

  @override
  int get hashCode => Object.hash(
    minimumXInclusive,
    maximumXInclusive,
    _nullableSetHash(seriesIds),
  );
}

/// Selects finite points whose Y value is inside an inclusive interval.
///
/// A null [seriesIds] applies to every series in the resolved chart. An empty
/// set deliberately resolves no points.
@immutable
final class ChartSelectionYIntervalClause extends ChartSelectionClause {
  ChartSelectionYIntervalClause({
    required this.minimumYInclusive,
    required this.maximumYInclusive,
    Set<String>? seriesIds,
  }) : assert(minimumYInclusive.isFinite),
       assert(maximumYInclusive.isFinite),
       assert(minimumYInclusive <= maximumYInclusive),
       seriesIds = seriesIds == null ? null : Set.unmodifiable(seriesIds);

  final double minimumYInclusive;
  final double maximumYInclusive;
  final Set<String>? seriesIds;

  @override
  bool operator ==(Object other) =>
      other is ChartSelectionYIntervalClause &&
      other.minimumYInclusive == minimumYInclusive &&
      other.maximumYInclusive == maximumYInclusive &&
      setEquals(other.seriesIds, seriesIds);

  @override
  int get hashCode => Object.hash(
    minimumYInclusive,
    maximumYInclusive,
    _nullableSetHash(seriesIds),
  );
}

/// Selects explicit source identities that cannot be represented compactly.
@immutable
final class ChartSelectionExplicitPointRefsClause extends ChartSelectionClause {
  ChartSelectionExplicitPointRefsClause({
    required Iterable<ChartPointRef> pointRefs,
  }) : pointRefs = Set.unmodifiable(pointRefs);

  final Set<ChartPointRef> pointRefs;

  @override
  bool operator ==(Object other) =>
      other is ChartSelectionExplicitPointRefsClause &&
      setEquals(other.pointRefs, pointRefs);

  @override
  int get hashCode => Object.hashAllUnordered(pointRefs);
}

/// Compact durable intent for one chart selection.
@immutable
class ChartSelectionExpression {
  const ChartSelectionExpression.empty() : clauses = const [];

  ChartSelectionExpression({required Iterable<ChartSelectionClause> clauses})
    : clauses = List.unmodifiable(clauses);

  /// Compresses already-resolved identities into whole-series, point-span,
  /// and explicit-reference clauses.
  factory ChartSelectionExpression.fromResolvedIdentities({
    Iterable<String> wholeSeriesIds = const [],
    Iterable<ChartPointRef> pointRefs = const [],
    Iterable<ChartSeries> series = const [],
  }) {
    final selectedSeries = wholeSeriesIds.where((id) => id.isNotEmpty).toSet();
    final seriesById = <String, ChartSeries>{
      for (final candidate in series) candidate.id: candidate,
    };
    final refsBySeries = <String, SplayTreeSet<int>>{};
    final pointKeysBySeries = <String, SplayTreeSet<String>>{};
    for (final ref in pointRefs) {
      if (selectedSeries.contains(ref.seriesId) || ref.pointIndex < 0) continue;
      final candidate = seriesById[ref.seriesId];
      if (candidate != null && ref.pointIndex < candidate.points.length) {
        final pointKey = candidate.points[ref.pointIndex].pointKey;
        if (pointKey != null) {
          pointKeysBySeries
              .putIfAbsent(ref.seriesId, SplayTreeSet<String>.new)
              .add(pointKey);
          continue;
        }
      }
      refsBySeries
          .putIfAbsent(ref.seriesId, SplayTreeSet<int>.new)
          .add(ref.pointIndex);
    }

    final clauses = <ChartSelectionClause>[
      for (final seriesId in selectedSeries.toList()..sort())
        ChartSelectionWholeSeriesClause(seriesId: seriesId),
    ];
    final keyedSeriesIds = pointKeysBySeries.keys.toList()..sort();
    for (final seriesId in keyedSeriesIds) {
      clauses.add(
        ChartSelectionPointKeysClause(
          seriesId: seriesId,
          pointKeys: pointKeysBySeries[seriesId]!,
        ),
      );
    }
    final explicitRefs = <ChartPointRef>{};
    final orderedSeriesIds = refsBySeries.keys.toList()..sort();
    for (final seriesId in orderedSeriesIds) {
      final indices = refsBySeries[seriesId]!.toList(growable: false);
      var spanStart = indices.first;
      var spanEnd = spanStart;
      for (var offset = 1; offset <= indices.length; offset++) {
        final next = offset < indices.length ? indices[offset] : null;
        if (next != null && next == spanEnd + 1) {
          spanEnd = next;
          continue;
        }
        if (spanStart == spanEnd) {
          explicitRefs.add(
            ChartPointRef(seriesId: seriesId, pointIndex: spanStart),
          );
        } else {
          clauses.add(
            ChartSelectionPointIndexSpanClause(
              seriesId: seriesId,
              startPointIndexInclusive: spanStart,
              endPointIndexInclusive: spanEnd,
            ),
          );
        }
        if (next != null) {
          spanStart = next;
          spanEnd = next;
        }
      }
    }
    if (explicitRefs.isNotEmpty) {
      clauses.add(
        ChartSelectionExplicitPointRefsClause(pointRefs: explicitRefs),
      );
    }
    return clauses.isEmpty
        ? const ChartSelectionExpression.empty()
        : ChartSelectionExpression(clauses: clauses);
  }

  final List<ChartSelectionClause> clauses;

  bool get isEmpty => clauses.isEmpty;
  bool get isNotEmpty => clauses.isNotEmpty;

  /// Resolves this compact intent against [series].
  ///
  /// Ordered-X interval clauses use binary search. Other clauses scan only the
  /// series they target and all invalid or stale identities are ignored.
  Set<ChartPointRef> resolvePointRefs(Iterable<ChartSeries> series) {
    final orderedSeries = series.toList(growable: false);
    final seriesById = <String, ChartSeries>{
      for (final candidate in orderedSeries) candidate.id: candidate,
    };
    final refs = <ChartPointRef>{};
    for (final clause in clauses) {
      switch (clause) {
        case ChartSelectionWholeSeriesClause():
          final candidate = seriesById[clause.seriesId];
          if (candidate == null) continue;
          for (var index = 0; index < candidate.points.length; index++) {
            if (candidate.points[index].isValid) {
              refs.add(
                ChartPointRef(seriesId: candidate.id, pointIndex: index),
              );
            }
          }
        case ChartSelectionPointIndexSpanClause():
          final candidate = seriesById[clause.seriesId];
          if (candidate == null || candidate.points.isEmpty) continue;
          final end = clause.endPointIndexInclusive < candidate.points.length
              ? clause.endPointIndexInclusive
              : candidate.points.length - 1;
          for (
            var index = clause.startPointIndexInclusive;
            index <= end;
            index++
          ) {
            if (candidate.points[index].isValid) {
              refs.add(
                ChartPointRef(seriesId: candidate.id, pointIndex: index),
              );
            }
          }
        case ChartSelectionPointKeysClause():
          final candidate = seriesById[clause.seriesId];
          if (candidate == null) continue;
          final keyIndex = ChartPointKeyIndex(candidate);
          for (final pointKey in clause.pointKeys) {
            final pointIndex = keyIndex.pointIndexFor(pointKey);
            if (pointIndex != null && candidate.points[pointIndex].isValid) {
              refs.add(
                ChartPointRef(seriesId: candidate.id, pointIndex: pointIndex),
              );
            }
          }
        case ChartSelectionXIntervalClause():
          for (final candidate in _targetSeries(
            orderedSeries,
            clause.seriesIds,
          )) {
            _addXIntervalRefs(refs, candidate, clause);
          }
        case ChartSelectionYIntervalClause():
          for (final candidate in _targetSeries(
            orderedSeries,
            clause.seriesIds,
          )) {
            for (var index = 0; index < candidate.points.length; index++) {
              final point = candidate.points[index];
              if (point.isValid &&
                  point.y >= clause.minimumYInclusive &&
                  point.y <= clause.maximumYInclusive) {
                refs.add(
                  ChartPointRef(seriesId: candidate.id, pointIndex: index),
                );
              }
            }
          }
        case ChartSelectionExplicitPointRefsClause():
          for (final ref in clause.pointRefs) {
            final candidate = seriesById[ref.seriesId];
            if (candidate == null ||
                ref.pointIndex < 0 ||
                ref.pointIndex >= candidate.points.length ||
                !candidate.points[ref.pointIndex].isValid) {
              continue;
            }
            refs.add(ref);
          }
      }
    }
    return Set.unmodifiable(refs);
  }

  @override
  bool operator ==(Object other) =>
      other is ChartSelectionExpression && listEquals(other.clauses, clauses);

  @override
  int get hashCode => Object.hashAll(clauses);
}

/// One lazily materialized selection bound to an effective chart revision.
///
/// Constructing a snapshot does not expand whole-series, spans, or intervals.
/// Concrete references and statistics are produced once, on first access.
class ChartSelectionSnapshot {
  ChartSelectionSnapshot({
    required this.expression,
    required this.revision,
    required Iterable<ChartSeries> series,
  }) : _series = List.unmodifiable(series);

  final ChartSelectionExpression expression;
  final ChartDocumentRevision revision;
  final List<ChartSeries> _series;

  late final Set<ChartPointRef> pointRefs = expression.resolvePointRefs(
    _series,
  );
  late final Set<ChartPointKeyRef> pointKeyRefs = _buildPointKeyRefs();
  ChartSelectionResult? _result;
  _ChartSelectionSummary? _summary;

  ChartSelectionResult get result => _result ??= _buildResult();

  ChartSelectionDataExtents? get extents =>
      _result?.extents ?? (_summary ??= _buildSummary()).extents;
  ChartSelectionStatistics get statistics =>
      _result?.statistics ?? (_summary ??= _buildSummary()).statistics;
  bool get isEmpty => expression.isEmpty;
  bool get isNotEmpty => expression.isNotEmpty;

  ChartSelectionResult _buildResult() {
    if (pointRefs.isEmpty) return const ChartSelectionResult.empty();
    final seriesById = <String, ChartSeries>{
      for (final candidate in _series) candidate.id: candidate,
    };
    final seriesOrder = <String, int>{
      for (var index = 0; index < _series.length; index++)
        _series[index].id: index,
    };
    final orderedRefs = pointRefs.toList()
      ..sort((first, second) {
        final seriesComparison = (seriesOrder[first.seriesId] ?? 1 << 30)
            .compareTo(seriesOrder[second.seriesId] ?? 1 << 30);
        return seriesComparison != 0
            ? seriesComparison
            : first.pointIndex.compareTo(second.pointIndex);
      });
    return ChartSelectionResult.fromPoints([
      for (final ref in orderedRefs)
        if (seriesById[ref.seriesId] case final candidate?)
          ChartSelectionPoint(
            reference: ref,
            point: candidate.points[ref.pointIndex],
            seriesName: candidate.displayName,
          ),
    ]);
  }

  _ChartSelectionSummary _buildSummary() {
    if (expression.isEmpty) return const _ChartSelectionSummary.empty();
    final accumulator = _ChartSelectionSummaryAccumulator();
    for (final candidate in _series) {
      if (_shouldStreamSummary(expression, candidate)) {
        final predicate = _SeriesSelectionPredicate(
          expression: expression,
          series: candidate,
        );
        for (var index = 0; index < candidate.points.length; index++) {
          final point = candidate.points[index];
          if (point.isValid && predicate.matches(index, point)) {
            accumulator.add(candidate.id, point);
          }
        }
        continue;
      }

      final references = expression.resolvePointRefs([candidate]);
      for (final reference in references) {
        accumulator.add(candidate.id, candidate.points[reference.pointIndex]);
      }
    }
    return accumulator.finish();
  }

  Set<ChartPointKeyRef> _buildPointKeyRefs() {
    final seriesById = <String, ChartSeries>{
      for (final candidate in _series) candidate.id: candidate,
    };
    final indexes = <String, ChartPointKeyIndex>{};
    final result = <ChartPointKeyRef>{};
    for (final reference in pointRefs) {
      final candidate = seriesById[reference.seriesId];
      if (candidate == null) continue;
      final index = indexes.putIfAbsent(
        reference.seriesId,
        () => ChartPointKeyIndex(candidate),
      );
      final key = index.keyFor(reference);
      if (key != null) result.add(key);
    }
    return Set.unmodifiable(result);
  }
}

const int _streamingSummaryThreshold = 4096;

bool _shouldStreamSummary(
  ChartSelectionExpression expression,
  ChartSeries series,
) {
  for (final clause in expression.clauses) {
    switch (clause) {
      case ChartSelectionWholeSeriesClause():
        if (clause.seriesId == series.id) return true;
      case ChartSelectionPointIndexSpanClause():
        if (clause.seriesId == series.id &&
            clause.endPointIndexInclusive -
                    clause.startPointIndexInclusive +
                    1 >
                _streamingSummaryThreshold) {
          return true;
        }
      case ChartSelectionXIntervalClause():
        if (!_targetsSeries(clause.seriesIds, series.id)) continue;
        if (!series.isXOrdered) return true;
        final start = _lowerBoundX(series.points, clause.minimumXInclusive);
        final end = _upperBoundX(series.points, clause.maximumXInclusive);
        if (end - start > _streamingSummaryThreshold) return true;
      case ChartSelectionYIntervalClause():
        if (_targetsSeries(clause.seriesIds, series.id)) return true;
      case ChartSelectionPointKeysClause() ||
          ChartSelectionExplicitPointRefsClause():
        break;
    }
  }
  return false;
}

bool _targetsSeries(Set<String>? seriesIds, String seriesId) =>
    seriesIds == null || seriesIds.contains(seriesId);

class _SeriesSelectionPredicate {
  _SeriesSelectionPredicate({
    required ChartSelectionExpression expression,
    required this.series,
  }) {
    for (final clause in expression.clauses) {
      switch (clause) {
        case ChartSelectionWholeSeriesClause():
          if (clause.seriesId == series.id) _wholeSeries = true;
        case ChartSelectionPointIndexSpanClause():
          if (clause.seriesId == series.id) _spans.add(clause);
        case ChartSelectionPointKeysClause():
          if (clause.seriesId != series.id) continue;
          final keyIndex = ChartPointKeyIndex(series);
          for (final key in clause.pointKeys) {
            final index = keyIndex.pointIndexFor(key);
            if (index != null) _explicitIndices.add(index);
          }
        case ChartSelectionXIntervalClause():
          if (_targetsSeries(clause.seriesIds, series.id)) {
            _xIntervals.add(clause);
          }
        case ChartSelectionYIntervalClause():
          if (_targetsSeries(clause.seriesIds, series.id)) {
            _yIntervals.add(clause);
          }
        case ChartSelectionExplicitPointRefsClause():
          for (final reference in clause.pointRefs) {
            if (reference.seriesId == series.id && reference.pointIndex >= 0) {
              _explicitIndices.add(reference.pointIndex);
            }
          }
      }
    }
  }

  final ChartSeries series;
  bool _wholeSeries = false;
  final List<ChartSelectionPointIndexSpanClause> _spans = [];
  final List<ChartSelectionXIntervalClause> _xIntervals = [];
  final List<ChartSelectionYIntervalClause> _yIntervals = [];
  final Set<int> _explicitIndices = {};

  bool matches(int index, ChartDataPoint point) {
    if (_wholeSeries || _explicitIndices.contains(index)) return true;
    for (final span in _spans) {
      if (index >= span.startPointIndexInclusive &&
          index <= span.endPointIndexInclusive) {
        return true;
      }
    }
    for (final interval in _xIntervals) {
      if (point.x >= interval.minimumXInclusive &&
          point.x <= interval.maximumXInclusive) {
        return true;
      }
    }
    for (final interval in _yIntervals) {
      if (point.y >= interval.minimumYInclusive &&
          point.y <= interval.maximumYInclusive) {
        return true;
      }
    }
    return false;
  }
}

class _ChartSelectionSummaryAccumulator {
  final Set<String> _seriesIds = {};
  final _MetricSummaryAccumulator _x = _MetricSummaryAccumulator();
  final _MetricSummaryAccumulator _y = _MetricSummaryAccumulator();
  final _MetricSummaryAccumulator _magnitude = _MetricSummaryAccumulator();
  final _MetricSummaryAccumulator _colorValue = _MetricSummaryAccumulator();
  final _MetricSummaryAccumulator _opacityValue = _MetricSummaryAccumulator();
  final Map<String, int> _categoryCounts = {};
  var _pointCount = 0;

  void add(String seriesId, ChartDataPoint point) {
    _pointCount++;
    _seriesIds.add(seriesId);
    _x.add(point.x);
    _y.add(point.y);
    _magnitude.add(point.magnitude);
    _colorValue.add(point.colorValue);
    _opacityValue.add(point.opacityValue);
    final category = point.categoryValue;
    if (category != null && category.isNotEmpty) {
      _categoryCounts.update(category, (count) => count + 1, ifAbsent: () => 1);
    }
  }

  _ChartSelectionSummary finish() {
    final x = _x.finish();
    final y = _y.finish();
    final statistics = ChartSelectionStatistics(
      pointCount: _pointCount,
      seriesCount: _seriesIds.length,
      x: x,
      y: y,
      magnitude: _magnitude.finish(),
      colorValue: _colorValue.finish(),
      opacityValue: _opacityValue.finish(),
      categoryCounts: Map.unmodifiable(_categoryCounts),
    );
    return _ChartSelectionSummary(
      statistics: statistics,
      extents: x == null || y == null
          ? null
          : ChartSelectionDataExtents(
              minimumX: x.minimum,
              maximumX: x.maximum,
              minimumY: y.minimum,
              maximumY: y.maximum,
            ),
    );
  }
}

class _MetricSummaryAccumulator {
  var _count = 0;
  var _minimum = double.infinity;
  var _maximum = double.negativeInfinity;
  var _sum = 0.0;

  void add(double? value) {
    if (value == null || !value.isFinite) return;
    _count++;
    _minimum = value < _minimum ? value : _minimum;
    _maximum = value > _maximum ? value : _maximum;
    _sum += value;
  }

  ChartSelectionMetricSummary? finish() => _count == 0
      ? null
      : ChartSelectionMetricSummary(
          count: _count,
          minimum: _minimum,
          maximum: _maximum,
          sum: _sum,
          mean: _sum / _count,
        );
}

class _ChartSelectionSummary {
  const _ChartSelectionSummary({required this.statistics, this.extents});

  const _ChartSelectionSummary.empty()
    : statistics = const ChartSelectionStatistics(
        pointCount: 0,
        seriesCount: 0,
      ),
      extents = null;

  final ChartSelectionStatistics statistics;
  final ChartSelectionDataExtents? extents;
}

Iterable<ChartSeries> _targetSeries(
  List<ChartSeries> series,
  Set<String>? seriesIds,
) sync* {
  if (seriesIds == null) {
    yield* series;
    return;
  }
  for (final candidate in series) {
    if (seriesIds.contains(candidate.id)) yield candidate;
  }
}

void _addXIntervalRefs(
  Set<ChartPointRef> refs,
  ChartSeries series,
  ChartSelectionXIntervalClause clause,
) {
  final points = series.points;
  if (points.isEmpty) return;
  if (!series.isXOrdered) {
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      if (point.isValid &&
          point.x >= clause.minimumXInclusive &&
          point.x <= clause.maximumXInclusive) {
        refs.add(ChartPointRef(seriesId: series.id, pointIndex: index));
      }
    }
    return;
  }

  final start = _lowerBoundX(points, clause.minimumXInclusive);
  final endExclusive = _upperBoundX(points, clause.maximumXInclusive);
  for (var index = start; index < endExclusive; index++) {
    if (points[index].isValid) {
      refs.add(ChartPointRef(seriesId: series.id, pointIndex: index));
    }
  }
}

int _lowerBoundX(List<ChartDataPoint> points, double value) {
  var low = 0;
  var high = points.length;
  while (low < high) {
    final middle = low + ((high - low) >> 1);
    if (points[middle].x < value) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  return low;
}

int _upperBoundX(List<ChartDataPoint> points, double value) {
  var low = 0;
  var high = points.length;
  while (low < high) {
    final middle = low + ((high - low) >> 1);
    if (points[middle].x <= value) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  return low;
}

int _nullableSetHash(Set<String>? values) =>
    values == null ? 0 : Object.hashAllUnordered(values);
