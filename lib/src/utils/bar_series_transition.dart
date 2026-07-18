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
    final collapsedTargets = target.targetValues.isEmpty
        ? const <double?>[]
        : <double?>[
            for (var index = 0; index < target.points.length; index++)
              target.targetValueFor(index) == null
                  ? null
                  : target.rangeStartValueFor(index),
          ];
    return target.copyWith(
      points: points,
      targetValues: collapsedTargets,
      errorLowerValues: collapsedErrorLower,
      errorUpperValues: collapsedErrorUpper,
    );
  }

  /// Adds points that only exist in [previous] to a transient target series.
  ///
  /// Exiting points retain their category and presentation metadata, but their
  /// values, targets, and uncertainty intervals collapse to the point's own
  /// baseline. The returned series can therefore travel through the normal bar
  /// geometry engine until the transition completes.
  static BarChartSeries withExitingPoints({
    required BarChartSeries previous,
    required BarChartSeries next,
  }) {
    final nextIndexByX = <double, int>{};
    for (var index = 0; index < next.points.length; index++) {
      nextIndexByX.putIfAbsent(next.points[index].x, () => index);
    }
    final exitingIndices = <int>[
      for (var index = 0; index < previous.points.length; index++)
        if (!nextIndexByX.containsKey(previous.points[index].x)) index,
    ];
    if (exitingIndices.isEmpty) return next;

    final nextAnchorByPreviousIndex = List<int?>.filled(
      previous.points.length,
      null,
    );
    int? nextAnchor;
    for (var index = previous.points.length - 1; index >= 0; index--) {
      final matchingNextIndex = nextIndexByX[previous.points[index].x];
      if (matchingNextIndex != null) {
        nextAnchor = matchingNextIndex;
      } else {
        nextAnchorByPreviousIndex[index] = nextAnchor;
      }
    }
    final exitingByNextAnchor = <int?, List<int>>{};
    for (final previousIndex in exitingIndices) {
      (exitingByNextAnchor[nextAnchorByPreviousIndex[previousIndex]] ??= [])
          .add(previousIndex);
    }
    final slots = <_TransitionPointSlot>[];
    for (var nextIndex = 0; nextIndex < next.points.length; nextIndex++) {
      for (final previousIndex
          in exitingByNextAnchor[nextIndex] ?? const <int>[]) {
        slots.add(_TransitionPointSlot.exiting(previousIndex));
      }
      slots.add(_TransitionPointSlot.next(nextIndex));
    }
    for (final previousIndex in exitingByNextAnchor[null] ?? const <int>[]) {
      slots.add(_TransitionPointSlot.exiting(previousIndex));
    }

    final points = <ChartDataPoint>[];
    final rangeStarts = <double?>[];
    final targets = <double?>[];
    final errorLower = <double?>[];
    final errorUpper = <double?>[];
    final waterfallTotals = <int>{};
    final hasRangeStarts =
        next.rangeStartValues.isNotEmpty ||
        previous.rangeStartValues.isNotEmpty;
    final hasTargets =
        next.targetValues.isNotEmpty || previous.targetValues.isNotEmpty;
    final hasErrors =
        next.errorLowerValues.isNotEmpty ||
        previous.errorLowerValues.isNotEmpty;

    for (var slotIndex = 0; slotIndex < slots.length; slotIndex++) {
      final slot = slots[slotIndex];
      final nextIndex = slot.nextIndex;
      if (nextIndex != null) {
        points.add(next.points[nextIndex]);
        if (hasRangeStarts) {
          rangeStarts.add(
            nextIndex < next.rangeStartValues.length
                ? next.rangeStartValues[nextIndex]
                : null,
          );
        }
        if (hasTargets) targets.add(next.targetValueFor(nextIndex));
        if (hasErrors) {
          errorLower.add(next.errorLowerValueFor(nextIndex));
          errorUpper.add(next.errorUpperValueFor(nextIndex));
        }
        if (next.isWaterfallTotal(nextIndex)) waterfallTotals.add(slotIndex);
        continue;
      }

      final previousIndex = slot.previousIndex!;
      final previousPoint = previous.points[previousIndex];
      final baseline = previous.layoutMode == BarLayoutMode.waterfall
          ? 0.0
          : previous.rangeStartValueFor(previousIndex);
      points.add(previousPoint.copyWith(y: baseline));
      if (hasRangeStarts) {
        rangeStarts.add(
          previousIndex < previous.rangeStartValues.length
              ? previous.rangeStartValues[previousIndex]
              : null,
        );
      }
      if (hasTargets) {
        targets.add(
          previous.targetValueFor(previousIndex) == null ? null : baseline,
        );
      }
      if (hasErrors) {
        final hadInterval =
            previous.errorLowerValueFor(previousIndex) != null &&
            previous.errorUpperValueFor(previousIndex) != null;
        errorLower.add(hadInterval ? baseline : null);
        errorUpper.add(hadInterval ? baseline : null);
      }
    }

    return next.copyWith(
      points: points,
      rangeStartValues: rangeStarts,
      clearRangeStartValues: !hasRangeStarts,
      targetValues: targets,
      clearTargetValues: !hasTargets,
      errorLowerValues: errorLower,
      errorUpperValues: errorUpper,
      clearErrorValues: !hasErrors,
      waterfallTotalIndices: waterfallTotals,
      clearWaterfallTotalIndices: waterfallTotals.isEmpty,
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
    final sourceIndexByIdentity = <(double, String?), int>{};
    final sourceIndexByX = <double, int>{};
    for (var index = 0; index < from.points.length; index++) {
      final point = from.points[index];
      sourceIndexByIdentity.putIfAbsent((point.x, point.label), () => index);
      sourceIndexByX.putIfAbsent(point.x, () => index);
    }
    for (var index = 0; index < to.points.length; index++) {
      final pointProgress = _pointProgress(
        progress: t,
        pointIndex: index,
        pointCount: to.points.length,
        motion: to.barStyle.motion,
      );
      final targetPoint = to.points[index];
      final sourceIndex =
          sourceIndexByIdentity[(targetPoint.x, targetPoint.label)] ??
          sourceIndexByX[targetPoint.x];
      final sourcePoint = sourceIndex == null
          ? targetPoint.copyWith(
              y: to.layoutMode == BarLayoutMode.waterfall
                  ? 0
                  : to.rangeStartValueFor(index),
            )
          : from.points[sourceIndex];
      animatedPoints.add(
        targetPoint.copyWith(
          x: _lerp(sourcePoint.x, targetPoint.x, pointProgress),
          y: _lerp(sourcePoint.y, targetPoint.y, pointProgress),
        ),
      );

      if (to.rangeStartValues.isNotEmpty) {
        final targetStart = to.rangeStartValueFor(index);
        final sourceStart = sourceIndex == null
            ? targetStart
            : from.rangeStartValueFor(sourceIndex);
        animatedStarts.add(_lerp(sourceStart, targetStart, pointProgress));
      }
      if (to.targetValues.isNotEmpty) {
        final targetValue = to.targetValueFor(index);
        if (targetValue == null) {
          animatedTargets.add(null);
        } else {
          final sourceTarget = sourceIndex == null
              ? targetValue
              : from.targetValueFor(sourceIndex) ?? targetValue;
          animatedTargets.add(_lerp(sourceTarget, targetValue, pointProgress));
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
          animatedErrorLower.add(
            _lerp(sourceLower, targetLower, pointProgress),
          );
          animatedErrorUpper.add(
            _lerp(sourceUpper, targetUpper, pointProgress),
          );
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

  static double _lerp(double from, double to, double t) =>
      from + (to - from) * t;

  static double _pointProgress({
    required double progress,
    required int pointIndex,
    required int pointCount,
    required BarMotionStyle motion,
  }) {
    if (motion.order == BarAnimationOrder.together ||
        motion.staggerFraction <= 0 ||
        pointCount <= 1) {
      return progress;
    }
    final sequencePosition = _sequencePosition(
      pointIndex: pointIndex,
      pointCount: pointCount,
      order: motion.order,
    );
    final start = sequencePosition * motion.staggerFraction;
    final activeFraction = 1 - motion.staggerFraction;
    return ((progress - start) / activeFraction).clamp(0.0, 1.0);
  }

  static double _sequencePosition({
    required int pointIndex,
    required int pointCount,
    required BarAnimationOrder order,
  }) {
    final lastIndex = pointCount - 1;
    return switch (order) {
      BarAnimationOrder.together => 0,
      BarAnimationOrder.forward => pointIndex / lastIndex,
      BarAnimationOrder.reverse => (lastIndex - pointIndex) / lastIndex,
      BarAnimationOrder.centerOut => _centerDistancePosition(
        pointIndex,
        pointCount,
      ),
      BarAnimationOrder.edgesIn =>
        1 - _centerDistancePosition(pointIndex, pointCount),
    };
  }

  static double _centerDistancePosition(int pointIndex, int pointCount) {
    final center = (pointCount - 1) / 2;
    final minimumDistance = pointCount.isEven ? 0.5 : 0.0;
    final maximumDistance = center;
    final distanceRange = maximumDistance - minimumDistance;
    if (distanceRange <= 0) return 0;
    return ((pointIndex - center).abs() - minimumDistance) / distanceRange;
  }
}

class _TransitionPointSlot {
  const _TransitionPointSlot.next(this.nextIndex) : previousIndex = null;

  const _TransitionPointSlot.exiting(this.previousIndex) : nextIndex = null;

  final int? nextIndex;
  final int? previousIndex;
}
