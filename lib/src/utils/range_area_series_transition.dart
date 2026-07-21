// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import '../models/range_area_chart_series.dart';
import '../models/range_area_data_point.dart';

/// Pure invariant-preserving transition helpers for Range Area series.
abstract final class RangeAreaSeriesTransition {
  static bool isCompatible(
    RangeAreaChartSeries from,
    RangeAreaChartSeries to,
  ) =>
      from.id == to.id &&
      from.interpolation == to.interpolation &&
      from.points.length == to.points.length;

  /// Interpolates X, low, and high atomically while retaining target style.
  ///
  /// A gap entering or leaving the topology collapses to a zero-span interval
  /// for intermediate frames and becomes the exact target gap only at
  /// completion. Every intermediate point therefore remains a valid interval.
  static RangeAreaChartSeries interpolate({
    required RangeAreaChartSeries from,
    required RangeAreaChartSeries to,
    required double progress,
  }) {
    if (!isCompatible(from, to)) return to;
    final t = progress.clamp(0.0, 1.0);
    if (t >= 1) return to;
    final points = <RangeAreaDataPoint>[
      for (var index = 0; index < to.points.length; index++)
        _interpolatePoint(from.intervalAt(index), to.intervalAt(index), t),
    ];
    return to.copyWith(points: points);
  }

  static RangeAreaDataPoint _interpolatePoint(
    RangeAreaDataPoint from,
    RangeAreaDataPoint to,
    double t,
  ) {
    final x = _lerp(from.x, to.x, t);
    if (from.isGap && to.isGap) {
      return RangeAreaDataPoint.gap(
        x: x,
        timestamp: to.timestamp,
        label: to.label,
        metadata: to.metadata,
      );
    }

    final fromLow = from.isGap ? to.midpoint! : from.low!;
    final fromHigh = from.isGap ? to.midpoint! : from.high!;
    final toLow = to.isGap ? from.midpoint! : to.low!;
    final toHigh = to.isGap ? from.midpoint! : to.high!;
    return RangeAreaDataPoint(
      x: x,
      low: _lerp(fromLow, toLow, t),
      high: _lerp(fromHigh, toHigh, t),
      timestamp: to.timestamp,
      label: to.label,
      metadata: to.metadata,
      segmentStyle: to.segmentStyle,
      pointStyle: to.pointStyle,
    );
  }

  static double _lerp(double from, double to, double t) =>
      from + (to - from) * t;
}
