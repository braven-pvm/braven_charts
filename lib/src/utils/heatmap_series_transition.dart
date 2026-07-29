// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import '../models/heatmap_chart_series.dart';
import '../models/heatmap_data_point.dart';

/// Stable-identity interpolation for native Heatmap value updates.
///
/// Coordinates are intentionally not interpolated. A keyed cell that moves to
/// another row or column is a removal plus an addition, not the same spatial
/// cell sliding through the matrix.
abstract final class HeatmapSeriesTransition {
  static bool isCompatible(HeatmapChartSeries from, HeatmapChartSeries to) {
    if (from.cells.length != to.cells.length) return false;
    final previousByIdentity = <HeatmapCellIdentity, HeatmapDataPoint>{
      for (final cell in from.cells) cell.identity: cell,
    };
    for (final cell in to.cells) {
      final previous = previousByIdentity[cell.identity];
      if (previous == null || previous.x != cell.x || previous.y != cell.y) {
        return false;
      }
    }
    return true;
  }

  static HeatmapChartSeries interpolate({
    required HeatmapChartSeries from,
    required HeatmapChartSeries to,
    required double progress,
  }) {
    final t = progress.clamp(0.0, 1.0);
    if (t <= 0) return from;
    if (t >= 1 || !isCompatible(from, to)) return to;

    final previousByIdentity = <HeatmapCellIdentity, HeatmapDataPoint>{
      for (final cell in from.cells) cell.identity: cell,
    };
    final cells = <HeatmapDataPoint>[
      for (final target in to.cells)
        _interpolateCell(previousByIdentity[target.identity]!, target, t),
    ];
    return to.copyWith(points: cells);
  }

  static HeatmapDataPoint _interpolateCell(
    HeatmapDataPoint from,
    HeatmapDataPoint to,
    double progress,
  ) {
    final fromValue = from.value;
    final toValue = to.value;
    if (fromValue == null || toValue == null) {
      // Missing cells never receive a fabricated numeric value. The midpoint
      // swaps between the source and target missing-colour states.
      return progress < 0.5 ? from : to;
    }
    return to.copyWith(value: fromValue + (toValue - fromValue) * progress);
  }
}
