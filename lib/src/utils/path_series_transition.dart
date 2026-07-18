// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import '../models/chart_data_point.dart';
import '../models/chart_series.dart';

/// Pure transition helpers for Line and Area series.
///
/// The returned series is consumed by the normal renderer, keeping paths,
/// markers, labels, linked points, crosshairs, and hit testing on one geometry.
abstract final class PathSeriesTransition {
  /// Whether [from] and [to] can be interpolated without inventing topology.
  static bool isCompatible(ChartSeries from, ChartSeries to) {
    if (from.id != to.id || from.runtimeType != to.runtimeType) return false;
    if (from.points.length != to.points.length) return false;
    if (from is LineChartSeries && to is LineChartSeries) {
      if (from.interpolation != to.interpolation) return false;
    } else if (from is AreaChartSeries && to is AreaChartSeries) {
      if (from.interpolation != to.interpolation) return false;
    } else {
      return false;
    }
    return _sourceIndices(from.points, to.points) != null;
  }

  /// Interpolates compatible point coordinates while retaining target style.
  static ChartSeries interpolate({
    required ChartSeries from,
    required ChartSeries to,
    required double progress,
  }) {
    final sourceIndices = _sourceIndices(from.points, to.points);
    if (sourceIndices == null || !isCompatible(from, to)) return to;
    final t = progress.clamp(0.0, 1.0);
    if (t >= 1) return to;

    final points = <ChartDataPoint>[
      for (var index = 0; index < to.points.length; index++)
        to.points[index].copyWith(
          x: _lerp(from.points[sourceIndices[index]].x, to.points[index].x, t),
          y: _lerp(from.points[sourceIndices[index]].y, to.points[index].y, t),
        ),
    ];
    return switch (to) {
      LineChartSeries() => to.copyWith(points: points),
      AreaChartSeries() => to.copyWith(points: points),
      _ => to,
    };
  }

  static List<int>? _sourceIndices(
    List<ChartDataPoint> from,
    List<ChartDataPoint> to,
  ) {
    if (from.length != to.length) return null;
    final unused = <int>{
      for (var index = 0; index < from.length; index++) index,
    };
    final result = <int>[];
    for (var targetIndex = 0; targetIndex < to.length; targetIndex++) {
      final target = to[targetIndex];
      int? sourceIndex;
      if (target.timestamp != null) {
        for (final index in unused) {
          if (from[index].timestamp == target.timestamp) {
            sourceIndex = index;
            break;
          }
        }
      }
      if (sourceIndex == null) {
        for (final index in unused) {
          final source = from[index];
          if (source.x == target.x && source.label == target.label) {
            sourceIndex = index;
            break;
          }
        }
      }
      sourceIndex ??= unused.contains(targetIndex) ? targetIndex : null;
      if (sourceIndex == null) return null;
      unused.remove(sourceIndex);
      result.add(sourceIndex);
    }
    return result;
  }

  static double _lerp(double from, double to, double t) =>
      from + (to - from) * t;
}
