// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import 'chart_data_point.dart';
import 'histogram_chart_data.dart';

/// Prepared X and Y distributions for a Scatter composition.
///
/// Marginals are derived data, not another Scatter render mode. The original
/// points remain the source of truth while the returned histogram points can
/// be rendered with ordinary [BarChartSeries] instances.
@immutable
class ScatterMarginalData {
  factory ScatterMarginalData({
    required Iterable<ChartDataPoint> points,
    HistogramBinningMethod method = HistogramBinningMethod.freedmanDiaconis,
    int requestedBinCount = 12,
    int maxBinCount = 100,
    double? xMinimum,
    double? xMaximum,
    double? yMinimum,
    double? yMaximum,
  }) {
    if (xMinimum != null && xMaximum != null && xMinimum >= xMaximum) {
      throw ArgumentError('xMinimum must be less than xMaximum');
    }
    if (yMinimum != null && yMaximum != null && yMinimum >= yMaximum) {
      throw ArgumentError('yMinimum must be less than yMaximum');
    }

    var sourcePointCount = 0;
    final visible = <ChartDataPoint>[];
    for (final point in points) {
      sourcePointCount++;
      if (!point.isValid ||
          xMinimum != null && point.x < xMinimum ||
          xMaximum != null && point.x > xMaximum ||
          yMinimum != null && point.y < yMinimum ||
          yMaximum != null && point.y > yMaximum) {
        continue;
      }
      visible.add(point);
    }

    return ScatterMarginalData._(
      sourcePointCount: sourcePointCount,
      visiblePointCount: visible.length,
      xHistogram: HistogramChartData(
        samples: visible.map((point) => point.x),
        method: method,
        requestedBinCount: requestedBinCount,
        maxBinCount: maxBinCount,
      ),
      yHistogram: HistogramChartData(
        samples: visible.map((point) => point.y),
        method: method,
        requestedBinCount: requestedBinCount,
        maxBinCount: maxBinCount,
      ),
    );
  }

  const ScatterMarginalData._({
    required this.sourcePointCount,
    required this.visiblePointCount,
    required this.xHistogram,
    required this.yHistogram,
  });

  /// Number of supplied points, including non-finite and out-of-viewport data.
  final int sourcePointCount;

  /// Number of finite points retained inside the requested two-dimensional
  /// viewport.
  final int visiblePointCount;

  final HistogramChartData xHistogram;
  final HistogramChartData yHistogram;

  /// Numeric X-bin centres and their derived values.
  List<ChartDataPoint> xPointsFor(HistogramValueMode mode) =>
      _pointsFor(xHistogram, mode);

  /// Numeric Y-bin centres and their derived values.
  ///
  /// [invertDomain] is useful when a regular vertical chart is quarter-turned
  /// to form a right-side marginal: the transformed X domain then still grows
  /// from bottom to top on screen.
  List<ChartDataPoint> yPointsFor(
    HistogramValueMode mode, {
    bool invertDomain = false,
  }) => _pointsFor(yHistogram, mode, invertDomain: invertDomain);

  static List<ChartDataPoint> _pointsFor(
    HistogramChartData histogram,
    HistogramValueMode mode, {
    bool invertDomain = false,
  }) => List.unmodifiable([
    for (final bin in histogram.bins)
      ChartDataPoint(
        x: invertDomain ? -bin.center : bin.center,
        y: switch (mode) {
          HistogramValueMode.count => bin.count.toDouble(),
          HistogramValueMode.percentage => bin.percentage,
          HistogramValueMode.density => bin.density,
        },
        label: bin.label,
        metadata: {
          'lowerBound': bin.lowerBound,
          'upperBound': bin.upperBound,
          'count': bin.count,
          'sampleCount': bin.sampleCount,
        },
      ),
  ]);
}
