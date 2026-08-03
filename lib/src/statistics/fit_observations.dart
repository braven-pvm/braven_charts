// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import '../models/chart_data_point.dart';
import '../models/range_area_data_point.dart';

/// Whether [point] is a real observation that a curve fit may be trained on.
///
/// Finiteness alone is not enough. [RangeAreaDataPoint.gap] carries a finite
/// `y` of `0` purely because [ChartDataPoint] has no nullable Y — the value is
/// a placeholder for "no interval here", not a measurement at zero. A gap that
/// survives into a regression, a moving average or a LOESS window drags the
/// fitted curve toward the axis and inflates the sample count behind the
/// reported R², so every fit filters its input through this predicate rather
/// than through a bare `isFinite` pair.
///
/// A plain [ChartDataPoint] at `y == 0` is a genuine observation and is kept.
bool isFitObservation(ChartDataPoint point) {
  if (point is RangeAreaDataPoint && point.isGap) return false;
  return point.x.isFinite && point.y.isFinite;
}

/// The subset of [points] that a curve fit may be trained on, in source order.
List<ChartDataPoint> fitObservations(Iterable<ChartDataPoint> points) =>
    points.where(isFitObservation).toList(growable: false);
