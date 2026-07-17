// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import '../models/bar_chart_style.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';

/// Pure interpolation helpers for canonical bar-series transitions.
///
/// The returned series is consumed by the normal bar geometry engine. This
/// keeps painting, hit testing, labels, tooltips, and crosshairs on the same
/// in-flight rectangles instead of maintaining a separate visual-only tween.
abstract final class BarSeriesTransition {
  /// Creates the zero-progress form of [target].
  ///
  /// Ordinary and range bars collapse to their own start value. Waterfall
  /// deltas collapse to zero so the cumulative bridge grows in sequence.
  static BarChartSeries collapsed(BarChartSeries target) {
    final points = <ChartDataPoint>[
      for (var index = 0; index < target.points.length; index++)
        target.points[index].copyWith(
          y: target.layoutMode == BarLayoutMode.waterfall
              ? 0
              : target.rangeStartValueFor(index),
        ),
    ];
    final collapsedErrorLower = target.errorLowerValues.isEmpty
        ? const <double?>[]
        : <double?>[
            for (var index = 0; index < target.points.length; index++)
              target.errorLowerValueFor(index) == null
                  ? null
                  : target.rangeStartValueFor(index),
          ];
    final collapsedErrorUpper = target.errorUpperValues.isEmpty
        ? const <double?>[]
        : <double?>[
            for (var index = 0; index < target.points.length; index++)
              target.errorUpperValueFor(index) == null
                  ? null
                  : target.rangeStartValueFor(index),
          ];
    return target.copyWith(
      points: points,
      errorLowerValues: collapsedErrorLower,
      errorUpperValues: collapsedErrorUpper,
    );
  }

  /// Interpolates bar data from [from] to [to].
  ///
  /// Structural presentation comes from [to]. When the composition or
  /// orientation changes, callers should use [collapsed] as [from] so the new
  /// layout enters cleanly rather than attempting to morph incompatible axes.
  static BarChartSeries interpolate({
    required BarChartSeries from,
    required BarChartSeries to,
    required double progress,
  }) {
    final t = progress.clamp(0.0, 1.0);
    if (t >= 1) return to;

    final animatedPoints = <ChartDataPoint>[];
    final animatedStarts = <double?>[];
    final animatedTargets = <double?>[];
    final animatedErrorLower = <double?>[];
    final animatedErrorUpper = <double?>[];
    for (var index = 0; index < to.points.length; index++) {
      final targetPoint = to.points[index];
      final sourceIndex = _sourceIndexFor(
        targetPoint: targetPoint,
        targetIndex: index,
        source: from,
      );
      final sourcePoint = sourceIndex == null
          ? targetPoint.copyWith(
              y: to.layoutMode == BarLayoutMode.waterfall
                  ? 0
                  : to.rangeStartValueFor(index),
            )
          : from.points[sourceIndex];
      animatedPoints.add(
        targetPoint.copyWith(
          x: _lerp(sourcePoint.x, targetPoint.x, t),
          y: _lerp(sourcePoint.y, targetPoint.y, t),
        ),
      );

      if (to.rangeStartValues.isNotEmpty) {
        final targetStart = to.rangeStartValueFor(index);
        final sourceStart = sourceIndex == null
            ? targetStart
            : from.rangeStartValueFor(sourceIndex);
        animatedStarts.add(_lerp(sourceStart, targetStart, t));
      }
      if (to.targetValues.isNotEmpty) {
        final targetValue = to.targetValueFor(index);
        if (targetValue == null) {
          animatedTargets.add(null);
        } else {
          final sourceTarget = sourceIndex == null
              ? targetValue
              : from.targetValueFor(sourceIndex) ?? targetValue;
          animatedTargets.add(_lerp(sourceTarget, targetValue, t));
        }
      }
      if (to.errorLowerValues.isNotEmpty) {
        final targetLower = to.errorLowerValueFor(index);
        final targetUpper = to.errorUpperValueFor(index);
        if (targetLower == null || targetUpper == null) {
          animatedErrorLower.add(null);
          animatedErrorUpper.add(null);
        } else {
          final sourceLower = sourceIndex == null
              ? to.rangeStartValueFor(index)
              : from.errorLowerValueFor(sourceIndex) ?? targetLower;
          final sourceUpper = sourceIndex == null
              ? to.rangeStartValueFor(index)
              : from.errorUpperValueFor(sourceIndex) ?? targetUpper;
          animatedErrorLower.add(_lerp(sourceLower, targetLower, t));
          animatedErrorUpper.add(_lerp(sourceUpper, targetUpper, t));
        }
      }
    }

    return to.copyWith(
      points: animatedPoints,
      rangeStartValues: animatedStarts,
      clearRangeStartValues: to.rangeStartValues.isEmpty,
      targetValues: animatedTargets,
      clearTargetValues: to.targetValues.isEmpty,
      errorLowerValues: animatedErrorLower,
      errorUpperValues: animatedErrorUpper,
      clearErrorValues: to.errorLowerValues.isEmpty,
    );
  }

  /// Whether two series share a layout that can interpolate directly.
  static bool hasCompatibleLayout(BarChartSeries from, BarChartSeries to) =>
      from.orientation == to.orientation &&
      from.layoutMode == to.layoutMode &&
      from.groupId == to.groupId;

  static int? _sourceIndexFor({
    required ChartDataPoint targetPoint,
    required int targetIndex,
    required BarChartSeries source,
  }) {
    for (var index = 0; index < source.points.length; index++) {
      final candidate = source.points[index];
      if (candidate.x == targetPoint.x &&
          candidate.label == targetPoint.label) {
        return index;
      }
    }
    if (targetIndex < source.points.length) return targetIndex;
    return null;
  }

  static double _lerp(double from, double to, double t) =>
      from + (to - from) * t;
}
