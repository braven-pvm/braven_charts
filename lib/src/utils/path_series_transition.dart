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
    final plan = _plan(from, to);
    if (plan == null) return to;
    final t = progress.clamp(0.0, 1.0);
    if (t >= 1) return to;

    final points = <ChartDataPoint>[
      for (final point in plan.points)
        point.to.copyWith(
          x: _lerp(point.from.x, point.to.x, t),
          y: _lerp(point.from.y, point.to.y, t),
        ),
    ];
    return switch (to) {
      LineChartSeries() => to.copyWith(points: points),
      AreaChartSeries() => to.copyWith(points: points),
      _ => to,
    };
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
      return _PathTransitionPlan([
        for (var index = 0; index < target.length; index++)
          _PathTransitionPoint(from: source[index], to: target[index]),
      ]);
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
          ),
      ]);
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
          ),
        );
        continue;
      }
      final anchor = index < firstMatch.targetIndex
          ? source[firstMatch.sourceIndex]
          : source[lastMatch.sourceIndex];
      points.add(_PathTransitionPoint(from: anchor, to: target[index]));
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
        ),
      );
    }

    return _PathTransitionPlan(points);
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

class _PathTransitionPlan {
  const _PathTransitionPlan(this.points);

  final List<_PathTransitionPoint> points;
}

class _PathTransitionPoint {
  const _PathTransitionPoint({required this.from, required this.to});

  final ChartDataPoint from;
  final ChartDataPoint to;
}

class _PointMatch {
  const _PointMatch({required this.sourceIndex, required this.targetIndex});

  final int sourceIndex;
  final int targetIndex;
}
