// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import '../models/bar_chart_style.dart';
import '../models/bar_group_info.dart';
import '../models/chart_series.dart';

/// Resolves bar-series composition before plot-space geometry is calculated.
///
/// Grouped series each occupy their own category slot. Stacked and overlaid
/// series sharing a [BarChartSeries.groupId] occupy one slot, allowing several
/// named compositions to sit side-by-side in the same category.
abstract final class BarCompositionEngine {
  static Map<String, BarGroupInfo> resolve(List<BarChartSeries> series) {
    if (series.isEmpty) return const {};

    final orientation = series.first.orientation;
    if (series.any((current) => current.orientation != orientation)) {
      throw ArgumentError(
        'All bar series in one chart must use the same orientation',
      );
    }

    final gap = series.fold<double>(
      0,
      (largest, current) => current.barGap > largest ? current.barGap : largest,
    );
    final slots = <String, List<BarChartSeries>>{};
    for (final current in series) {
      current.validateConfiguration();
      final key = _slotKey(current);
      slots.putIfAbsent(key, () => []).add(current);
    }

    final result = <String, BarGroupInfo>{};
    final orderedSlots = slots.entries.toList(growable: false);
    for (var slotIndex = 0; slotIndex < orderedSlots.length; slotIndex++) {
      final slotSeries = orderedSlots[slotIndex].value;
      final first = slotSeries.first;
      if (first.layoutMode == BarLayoutMode.grouped) {
        result[first.id] = BarGroupInfo(
          index: slotIndex,
          count: orderedSlots.length,
          gap: gap,
          groupId: first.groupId,
        );
        continue;
      }
      if (first.layoutMode == BarLayoutMode.overlaid) {
        _resolveOverlay(
          slotSeries,
          slotIndex: slotIndex,
          slotCount: orderedSlots.length,
          gap: gap,
          result: result,
        );
        continue;
      }
      if (first.layoutMode == BarLayoutMode.waterfall) {
        _resolveWaterfall(
          first,
          slotIndex: slotIndex,
          slotCount: orderedSlots.length,
          gap: gap,
          result: result,
        );
        continue;
      }

      if (first.layoutMode == BarLayoutMode.divergingStacked) {
        _resolveDivergingStack(
          slotSeries,
          slotIndex: slotIndex,
          slotCount: orderedSlots.length,
          gap: gap,
          result: result,
        );
        continue;
      }

      _resolveStack(
        slotSeries,
        slotIndex: slotIndex,
        slotCount: orderedSlots.length,
        gap: gap,
        result: result,
      );
    }
    return result;
  }

  static void _resolveDivergingStack(
    List<BarChartSeries> series, {
    required int slotIndex,
    required int slotCount,
    required double gap,
    required Map<String, BarGroupInfo> result,
  }) {
    final neutralSeries = series
        .where((current) => current.divergingRole == BarDivergingRole.neutral)
        .toList(growable: false);
    if (neutralSeries.length > 1) {
      throw ArgumentError(
        'A diverging stack can contain at most one neutral series',
      );
    }

    final stackBaseline = series.first.baselineValue;
    final totals = <double, double>{};
    for (final current in series) {
      for (final point in current.points) {
        final magnitude = point.y - current.baselineValue;
        totals[point.x] = (totals[point.x] ?? 0) + magnitude;
      }
    }

    final shares = <String, Map<int, double>>{};
    for (final current in series) {
      shares[current.id] = {
        for (final (pointIndex, point) in current.points.indexed)
          pointIndex: (totals[point.x] ?? 0) == 0
              ? 0
              : _stablePercentage(
                  point.y - current.baselineValue,
                  totals[point.x]!,
                ),
      };
    }

    final starts = <String, Map<int, double>>{
      for (final current in series) current.id: <int, double>{},
    };
    final ends = <String, Map<int, double>>{
      for (final current in series) current.id: <int, double>{},
    };
    final outer = <String, Set<int>>{
      for (final current in series) current.id: <int>{},
    };

    final xValues = <double>{
      for (final current in series)
        for (final point in current.points) point.x,
    };
    for (final x in xValues) {
      final neutral = neutralSeries.firstOrNull;
      final neutralPointIndex = neutral?.points.indexWhere(
        (point) => point.x == x,
      );
      final neutralShare =
          neutral == null || neutralPointIndex == null || neutralPointIndex < 0
          ? 0.0
          : shares[neutral.id]![neutralPointIndex]!;
      var negativeOffset = -neutralShare / 2;
      var positiveOffset = neutralShare / 2;

      if (neutral != null &&
          neutralPointIndex != null &&
          neutralPointIndex >= 0) {
        starts[neutral.id]![neutralPointIndex] =
            stackBaseline - neutralShare / 2;
        ends[neutral.id]![neutralPointIndex] = stackBaseline + neutralShare / 2;
      }

      final negative = series
          .where(
            (current) => current.divergingRole == BarDivergingRole.negative,
          )
          .toList(growable: false)
          .reversed;
      _PointRef? outerNegative;
      for (final current in negative) {
        final pointIndex = current.points.indexWhere((point) => point.x == x);
        if (pointIndex < 0) continue;
        final share = shares[current.id]![pointIndex]!;
        starts[current.id]![pointIndex] = stackBaseline + negativeOffset;
        negativeOffset -= share;
        ends[current.id]![pointIndex] = stackBaseline + negativeOffset;
        outerNegative = _PointRef(current.id, pointIndex);
      }
      if (outerNegative != null) {
        outer[outerNegative.seriesId]!.add(outerNegative.pointIndex);
      }

      _PointRef? outerPositive;
      for (final current in series.where(
        (candidate) => candidate.divergingRole == BarDivergingRole.positive,
      )) {
        final pointIndex = current.points.indexWhere((point) => point.x == x);
        if (pointIndex < 0) continue;
        final share = shares[current.id]![pointIndex]!;
        starts[current.id]![pointIndex] = stackBaseline + positiveOffset;
        positiveOffset += share;
        ends[current.id]![pointIndex] = stackBaseline + positiveOffset;
        outerPositive = _PointRef(current.id, pointIndex);
      }
      if (outerPositive != null) {
        outer[outerPositive.seriesId]!.add(outerPositive.pointIndex);
      }
    }

    for (var seriesIndex = 0; seriesIndex < series.length; seriesIndex++) {
      final current = series[seriesIndex];
      result[current.id] = BarGroupInfo(
        index: slotIndex,
        count: slotCount,
        gap: gap,
        layoutMode: BarLayoutMode.divergingStacked,
        groupId: current.groupId,
        stackBaseline: stackBaseline,
        startValues: starts[current.id]!,
        endValues: ends[current.id]!,
        percentages: shares[current.id]!,
        outerPointIndices: outer[current.id]!,
        drawTrack: seriesIndex == 0,
      );
    }
  }

  static double _stablePercentage(double value, double total) {
    final percentage = value / total * 100;
    final rounded = percentage.roundToDouble();
    return (percentage - rounded).abs() < 1e-10 ? rounded : percentage;
  }

  static void _resolveOverlay(
    List<BarChartSeries> series, {
    required int slotIndex,
    required int slotCount,
    required double gap,
    required Map<String, BarGroupInfo> result,
  }) {
    for (var seriesIndex = 0; seriesIndex < series.length; seriesIndex++) {
      final current = series[seriesIndex];
      result[current.id] = BarGroupInfo(
        index: slotIndex,
        count: slotCount,
        gap: gap,
        layoutMode: BarLayoutMode.overlaid,
        groupId: current.groupId,
        stackBaseline: current.baselineValue,
        drawTrack: seriesIndex == 0,
      );
    }
  }

  static void _resolveStack(
    List<BarChartSeries> series, {
    required int slotIndex,
    required int slotCount,
    required double gap,
    required Map<String, BarGroupInfo> result,
  }) {
    final mode = series.first.layoutMode;
    final stackBaseline = series.first.baselineValue;
    final positiveTotals = <double, double>{};
    final negativeTotals = <double, double>{};
    final outerPositive = <double, _PointRef>{};
    final outerNegative = <double, _PointRef>{};

    for (final current in series) {
      for (
        var pointIndex = 0;
        pointIndex < current.points.length;
        pointIndex++
      ) {
        final point = current.points[pointIndex];
        final delta = point.y - current.baselineValue;
        final reference = _PointRef(current.id, pointIndex);
        if (delta >= 0) {
          positiveTotals[point.x] = (positiveTotals[point.x] ?? 0) + delta;
          if (delta > 0) outerPositive[point.x] = reference;
        } else {
          negativeTotals[point.x] =
              (negativeTotals[point.x] ?? 0) + delta.abs();
          outerNegative[point.x] = reference;
        }
      }
    }

    final positiveOffsets = <double, double>{};
    final negativeOffsets = <double, double>{};
    for (var seriesIndex = 0; seriesIndex < series.length; seriesIndex++) {
      final current = series[seriesIndex];
      final startValues = <int, double>{};
      final endValues = <int, double>{};
      final percentages = <int, double>{};
      final outerPointIndices = <int>{};

      for (
        var pointIndex = 0;
        pointIndex < current.points.length;
        pointIndex++
      ) {
        final point = current.points[pointIndex];
        final rawDelta = point.y - current.baselineValue;
        var displayDelta = rawDelta;
        if (mode == BarLayoutMode.normalizedStacked) {
          final total = rawDelta >= 0
              ? positiveTotals[point.x] ?? 0
              : negativeTotals[point.x] ?? 0;
          displayDelta = total == 0 ? 0 : rawDelta / total * 100;
          percentages[pointIndex] = displayDelta;
        }

        final offsets = displayDelta >= 0 ? positiveOffsets : negativeOffsets;
        final start = stackBaseline + (offsets[point.x] ?? 0);
        final end = start + displayDelta;
        startValues[pointIndex] = start;
        endValues[pointIndex] = end;
        offsets[point.x] = end - stackBaseline;

        final reference = _PointRef(current.id, pointIndex);
        final outer = rawDelta >= 0
            ? outerPositive[point.x]
            : outerNegative[point.x];
        if (outer == reference) outerPointIndices.add(pointIndex);
      }

      result[current.id] = BarGroupInfo(
        index: slotIndex,
        count: slotCount,
        gap: gap,
        layoutMode: mode,
        groupId: current.groupId,
        stackBaseline: stackBaseline,
        startValues: startValues,
        endValues: endValues,
        percentages: percentages,
        outerPointIndices: outerPointIndices,
        drawTrack: seriesIndex == 0,
      );
    }
  }

  static void _resolveWaterfall(
    BarChartSeries series, {
    required int slotIndex,
    required int slotCount,
    required double gap,
    required Map<String, BarGroupInfo> result,
  }) {
    final startValues = <int, double>{};
    final endValues = <int, double>{};
    var runningTotal = series.baselineValue;

    for (var pointIndex = 0; pointIndex < series.points.length; pointIndex++) {
      if (series.isWaterfallTotal(pointIndex)) {
        startValues[pointIndex] = series.baselineValue;
        endValues[pointIndex] = runningTotal;
        continue;
      }
      startValues[pointIndex] = runningTotal;
      runningTotal += series.points[pointIndex].y;
      endValues[pointIndex] = runningTotal;
    }

    result[series.id] = BarGroupInfo(
      index: slotIndex,
      count: slotCount,
      gap: gap,
      layoutMode: BarLayoutMode.waterfall,
      groupId: series.groupId,
      stackBaseline: series.baselineValue,
      startValues: startValues,
      endValues: endValues,
    );
  }

  static String _slotKey(BarChartSeries series) {
    if (series.layoutMode == BarLayoutMode.grouped ||
        series.layoutMode == BarLayoutMode.waterfall) {
      return '${series.layoutMode.name}:${series.id}';
    }
    final axisId = series.yAxisId ?? series.yAxisConfig?.id ?? '__default__';
    final groupId = series.groupId ?? '__default__';
    return '${series.layoutMode.name}:$axisId:${series.baselineValue}:$groupId';
  }
}

class _PointRef {
  const _PointRef(this.seriesId, this.pointIndex);

  final String seriesId;
  final int pointIndex;

  @override
  bool operator ==(Object other) =>
      other is _PointRef &&
      other.seriesId == seriesId &&
      other.pointIndex == pointIndex;

  @override
  int get hashCode => Object.hash(seriesId, pointIndex);
}
