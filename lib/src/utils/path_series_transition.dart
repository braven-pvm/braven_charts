// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import '../models/chart_data_point.dart';
import '../models/chart_series.dart';

/// Pure transition helpers for Line and Area series.
///
/// The returned series is consumed by the normal renderer, keeping paths,
/// markers, labels, linked points, crosshairs, and hit testing on one geometry.
abstract final class PathSeriesTransition {
  /// Whether [from] and [to] have compatible value or boundary topology.
  ///
  /// In addition to equal-length ordered updates, Line and Area series may add
  /// or remove points at either boundary when at least one retained point can
  /// be matched by timestamp or `x + label` identity. Interior edits and
  /// reordered retained identities are deliberately incompatible.
  static bool isCompatible(ChartSeries from, ChartSeries to) {
    return _plan(from, to) != null;
  }

  /// Interpolates compatible geometry while retaining target series style.
  ///
  /// Entering points grow from the nearest retained boundary. Exiting points
  /// remain in the temporary series while collapsing into that boundary, then
  /// disappear when the exact target series is returned at completion.
  static ChartSeries interpolate({
    required ChartSeries from,
    required ChartSeries to,
    required double progress,
  }) {
    return frame(from: from, to: to, progress: progress).series;
  }

  /// Builds interpolated geometry and its canonical target-point mapping.
  static PathSeriesTransitionFrame frame({
    required ChartSeries from,
    required ChartSeries to,
    required double progress,
  }) {
    final plan = _plan(from, to);
    final identityMap = PathSeriesPointMap.identity(to.points.length);
    if (plan == null) {
      return PathSeriesTransitionFrame(series: to, pointMap: identityMap);
    }
    final t = progress.clamp(0.0, 1.0);
    if (t >= 1) {
      return PathSeriesTransitionFrame(series: to, pointMap: identityMap);
    }

    final points = <ChartDataPoint>[
      for (final point in plan.points)
        point.to.copyWith(
          x: _lerp(point.from.x, point.to.x, t),
          y: _lerp(point.from.y, point.to.y, t),
        ),
    ];
    final series = switch (to) {
      LineChartSeries() => to.copyWith(points: points),
      AreaChartSeries() => to.copyWith(points: points),
      _ => to,
    };
    return PathSeriesTransitionFrame(
      series: series,
      pointMap: PathSeriesPointMap(
        targetPointIndices: [
          for (final point in plan.points) point.targetIndex,
        ],
        targetPointCount: to.points.length,
      ),
    );
  }

  /// Resolves a source point to its stable canonical target index.
  ///
  /// Returns null when the point exits or the series are incompatible.
  static int? targetIndexForSource(
    ChartSeries from,
    ChartSeries to,
    int sourceIndex,
  ) {
    final plan = _plan(from, to);
    if (plan == null ||
        sourceIndex < 0 ||
        sourceIndex >= plan.sourceTargetIndices.length) {
      return null;
    }
    return plan.sourceTargetIndices[sourceIndex];
  }

  static _PathTransitionPlan? _plan(ChartSeries from, ChartSeries to) {
    if (from.id != to.id || from.runtimeType != to.runtimeType) return null;
    if (from is LineChartSeries && to is LineChartSeries) {
      if (from.interpolation != to.interpolation) return null;
    } else if (from is AreaChartSeries && to is AreaChartSeries) {
      if (from.interpolation != to.interpolation) return null;
    } else {
      return null;
    }

    final source = from.points;
    final target = to.points;
    final matches = _stableMatches(source, target);

    final isEqualLengthOrderedUpdate =
        source.length == target.length &&
        matches.every((match) => match.sourceIndex == match.targetIndex);
    if (isEqualLengthOrderedUpdate) {
      return _PathTransitionPlan(
        [
          for (var index = 0; index < target.length; index++)
            _PathTransitionPoint(
              from: source[index],
              to: target[index],
              targetIndex: index,
            ),
        ],
        sourceTargetIndices: [for (var i = 0; i < source.length; i++) i],
      );
    }

    if (matches.length == target.length && source.length == target.length) {
      if (!_isStrictlyIncreasing(matches.map((match) => match.sourceIndex))) {
        return null;
      }
      return _PathTransitionPlan([
        for (final match in matches)
          _PathTransitionPoint(
            from: source[match.sourceIndex],
            to: target[match.targetIndex],
            targetIndex: match.targetIndex,
          ),
      ], sourceTargetIndices: _sourceTargetIndices(source.length, matches));
    }

    if (matches.isEmpty ||
        !_isStrictlyIncreasing(matches.map((match) => match.sourceIndex))) {
      return null;
    }

    final matchedSourceIndices = matches
        .map((match) => match.sourceIndex)
        .toSet();
    final matchedTargetIndices = matches
        .map((match) => match.targetIndex)
        .toSet();
    if (!_containsOnlyBoundaryGaps(source.length, matchedSourceIndices) ||
        !_containsOnlyBoundaryGaps(target.length, matchedTargetIndices)) {
      return null;
    }

    final firstMatch = matches.first;
    final lastMatch = matches.last;
    final matchByTarget = <int, _PointMatch>{
      for (final match in matches) match.targetIndex: match,
    };
    final firstTargetBoundary = target[firstMatch.targetIndex];
    final lastTargetBoundary = target[lastMatch.targetIndex];
    final points = <_PathTransitionPoint>[];

    for (var index = 0; index < firstMatch.sourceIndex; index++) {
      points.add(
        _PathTransitionPoint(
          from: source[index],
          to: source[index].copyWith(
            x: firstTargetBoundary.x,
            y: firstTargetBoundary.y,
          ),
          targetIndex: null,
        ),
      );
    }

    for (var index = 0; index < target.length; index++) {
      final match = matchByTarget[index];
      if (match != null) {
        points.add(
          _PathTransitionPoint(
            from: source[match.sourceIndex],
            to: target[index],
            targetIndex: index,
          ),
        );
        continue;
      }
      final anchor = index < firstMatch.targetIndex
          ? source[firstMatch.sourceIndex]
          : source[lastMatch.sourceIndex];
      points.add(
        _PathTransitionPoint(
          from: anchor,
          to: target[index],
          targetIndex: index,
        ),
      );
    }

    for (
      var index = lastMatch.sourceIndex + 1;
      index < source.length;
      index++
    ) {
      points.add(
        _PathTransitionPoint(
          from: source[index],
          to: source[index].copyWith(
            x: lastTargetBoundary.x,
            y: lastTargetBoundary.y,
          ),
          targetIndex: null,
        ),
      );
    }

    return _PathTransitionPlan(
      points,
      sourceTargetIndices: _sourceTargetIndices(source.length, matches),
    );
  }

  static List<int?> _sourceTargetIndices(
    int sourceLength,
    List<_PointMatch> matches,
  ) {
    final result = List<int?>.filled(sourceLength, null);
    for (final match in matches) {
      result[match.sourceIndex] = match.targetIndex;
    }
    return result;
  }

  static List<_PointMatch> _stableMatches(
    List<ChartDataPoint> source,
    List<ChartDataPoint> target,
  ) {
    final unused = <int>{
      for (var index = 0; index < source.length; index++) index,
    };
    final result = <_PointMatch>[];
    for (var targetIndex = 0; targetIndex < target.length; targetIndex++) {
      final targetPoint = target[targetIndex];
      int? sourceIndex;
      if (targetPoint.timestamp != null) {
        for (final index in unused) {
          if (source[index].timestamp == targetPoint.timestamp) {
            sourceIndex = index;
            break;
          }
        }
      }
      if (sourceIndex == null) {
        for (final index in unused) {
          final sourcePoint = source[index];
          if (sourcePoint.x == targetPoint.x &&
              sourcePoint.label == targetPoint.label) {
            sourceIndex = index;
            break;
          }
        }
      }
      if (sourceIndex == null) continue;
      unused.remove(sourceIndex);
      result.add(
        _PointMatch(sourceIndex: sourceIndex, targetIndex: targetIndex),
      );
    }
    return result;
  }

  static bool _isStrictlyIncreasing(Iterable<int> indices) {
    int? previous;
    for (final index in indices) {
      if (previous != null && index <= previous) return false;
      previous = index;
    }
    return true;
  }

  static bool _containsOnlyBoundaryGaps(int length, Set<int> retained) {
    if (retained.isEmpty) return false;
    final first = retained.reduce((a, b) => a < b ? a : b);
    final last = retained.reduce((a, b) => a > b ? a : b);
    for (var index = first; index <= last; index++) {
      if (!retained.contains(index)) return false;
    }
    return first >= 0 && last < length;
  }

  static double _lerp(double from, double to, double t) =>
      from + (to - from) * t;
}

/// One private-runtime Line/Area transition frame.
class PathSeriesTransitionFrame {
  PathSeriesTransitionFrame({required this.series, required this.pointMap});

  /// Interpolated geometry consumed by the standard series renderer.
  final ChartSeries series;

  /// Mapping from temporary render indices to canonical target indices.
  final PathSeriesPointMap pointMap;

  /// Convenience view of [pointMap]'s render-to-target mapping.
  List<int?> get targetPointIndices => pointMap.targetPointIndices;

  /// Number of points in the canonical target snapshot.
  int get targetPointCount => pointMap.targetPointCount;
}

/// Maps temporary rendered Line/Area points to canonical target points.
class PathSeriesPointMap {
  PathSeriesPointMap({
    required List<int?> targetPointIndices,
    required this.targetPointCount,
  }) : targetPointIndices = List<int?>.unmodifiable(targetPointIndices);

  /// Creates an identity mapping for a completed target series.
  factory PathSeriesPointMap.identity(int pointCount) => PathSeriesPointMap(
    targetPointIndices: [
      for (var index = 0; index < pointCount; index++) index,
    ],
    targetPointCount: pointCount,
  );

  /// Canonical target index for each render index; exits map to null.
  final List<int?> targetPointIndices;

  /// Number of points in the canonical target snapshot.
  final int targetPointCount;

  /// Returns the canonical target index for [renderIndex].
  int? targetIndexForRenderIndex(int renderIndex) {
    if (renderIndex < 0 || renderIndex >= targetPointIndices.length) {
      return null;
    }
    return targetPointIndices[renderIndex];
  }

  /// Returns the temporary render index for [targetIndex].
  int? renderIndexForTargetIndex(int targetIndex) {
    if (targetIndex < 0 || targetIndex >= targetPointCount) return null;
    final renderIndex = targetPointIndices.indexOf(targetIndex);
    return renderIndex < 0 ? null : renderIndex;
  }
}

class _PathTransitionPlan {
  const _PathTransitionPlan(this.points, {required this.sourceTargetIndices});

  final List<_PathTransitionPoint> points;
  final List<int?> sourceTargetIndices;
}

class _PathTransitionPoint {
  const _PathTransitionPoint({
    required this.from,
    required this.to,
    required this.targetIndex,
  });

  final ChartDataPoint from;
  final ChartDataPoint to;
  final int? targetIndex;
}

class _PointMatch {
  const _PointMatch({required this.sourceIndex, required this.targetIndex});

  final int sourceIndex;
  final int targetIndex;
}
