// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'chart_data_point.dart';
import 'histogram_chart_data.dart';

/// Visual layers commonly composed around a Scatter chart.
enum ScatterMarginalMode {
  histogram,
  density,
  rug,
  histogramAndDensity,
  densityAndRug;

  bool get showsHistogram => this == histogram || this == histogramAndDensity;

  bool get showsDensity =>
      this == density || this == histogramAndDensity || this == densityAndRug;

  bool get showsRug => this == rug || this == densityAndRug;
}

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

    final xSamples = visible.map((point) => point.x).toList()..sort();
    final ySamples = visible.map((point) => point.y).toList()..sort();

    return ScatterMarginalData._(
      sourcePointCount: sourcePointCount,
      visiblePointCount: visible.length,
      xSamples: List.unmodifiable(xSamples),
      ySamples: List.unmodifiable(ySamples),
      xMinimum: xMinimum,
      xMaximum: xMaximum,
      yMinimum: yMinimum,
      yMaximum: yMaximum,
      xHistogram: HistogramChartData(
        samples: xSamples,
        method: method,
        requestedBinCount: requestedBinCount,
        maxBinCount: maxBinCount,
      ),
      yHistogram: HistogramChartData(
        samples: ySamples,
        method: method,
        requestedBinCount: requestedBinCount,
        maxBinCount: maxBinCount,
      ),
    );
  }

  const ScatterMarginalData._({
    required this.sourcePointCount,
    required this.visiblePointCount,
    required this.xSamples,
    required this.ySamples,
    required this.xMinimum,
    required this.xMaximum,
    required this.yMinimum,
    required this.yMaximum,
    required this.xHistogram,
    required this.yHistogram,
  });

  /// Number of supplied points, including non-finite and out-of-viewport data.
  final int sourcePointCount;

  /// Number of finite points retained inside the requested two-dimensional
  /// viewport.
  final int visiblePointCount;

  /// Sorted finite X values retained inside the requested viewport.
  final List<double> xSamples;

  /// Sorted finite Y values retained inside the requested viewport.
  final List<double> ySamples;

  /// Requested viewport bounds. Null means the visible sample extent.
  final double? xMinimum;
  final double? xMaximum;
  final double? yMinimum;
  final double? yMaximum;

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

  /// Gaussian kernel-density estimate across the visible X domain.
  List<ChartDataPoint> xDensityPoints({
    int resolution = 96,
    double bandwidthMultiplier = 1,
  }) => _densityPoints(
    xSamples,
    domainMinimum: xMinimum,
    domainMaximum: xMaximum,
    resolution: resolution,
    bandwidthMultiplier: bandwidthMultiplier,
  );

  /// Gaussian kernel-density estimate across the visible Y domain.
  List<ChartDataPoint> yDensityPoints({
    int resolution = 96,
    double bandwidthMultiplier = 1,
    bool invertDomain = false,
  }) => _densityPoints(
    ySamples,
    domainMinimum: yMinimum,
    domainMaximum: yMaximum,
    resolution: resolution,
    bandwidthMultiplier: bandwidthMultiplier,
    invertDomain: invertDomain,
  );

  /// One baseline mark per visible X observation.
  List<ChartDataPoint> xRugPoints() => _rugPoints(xSamples);

  /// One baseline mark per visible Y observation.
  List<ChartDataPoint> yRugPoints({bool invertDomain = false}) =>
      _rugPoints(ySamples, invertDomain: invertDomain);

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

  static List<ChartDataPoint> _densityPoints(
    List<double> samples, {
    required double? domainMinimum,
    required double? domainMaximum,
    required int resolution,
    required double bandwidthMultiplier,
    bool invertDomain = false,
  }) {
    if (resolution < 2) {
      throw ArgumentError.value(
        resolution,
        'resolution',
        'Density resolution must be at least 2',
      );
    }
    if (!bandwidthMultiplier.isFinite || bandwidthMultiplier <= 0) {
      throw ArgumentError.value(
        bandwidthMultiplier,
        'bandwidthMultiplier',
        'Bandwidth multiplier must be positive and finite',
      );
    }
    if (samples.isEmpty) return const [];

    var minimum = domainMinimum ?? samples.first;
    var maximum = domainMaximum ?? samples.last;
    if (minimum == maximum) {
      final padding = minimum == 0 ? 0.5 : minimum.abs() * 0.05;
      minimum -= padding;
      maximum += padding;
    }

    final range = maximum - minimum;
    final bandwidth = _automaticBandwidth(samples, range) * bandwidthMultiplier;
    final normalization = samples.length * bandwidth * math.sqrt(2 * math.pi);
    final step = range / (resolution - 1);
    final points = <ChartDataPoint>[];
    for (var index = 0; index < resolution; index++) {
      final value = minimum + step * index;
      var kernelSum = 0.0;
      for (final sample in samples) {
        final z = (value - sample) / bandwidth;
        kernelSum += math.exp(-0.5 * z * z);
      }
      final density = kernelSum / normalization;
      points.add(
        ChartDataPoint(
          x: invertDomain ? -value : value,
          y: density,
          metadata: {
            'density': density,
            'sampleCount': samples.length,
            'bandwidth': bandwidth,
          },
        ),
      );
    }
    if (invertDomain) return List.unmodifiable(points.reversed);
    return List.unmodifiable(points);
  }

  static double _automaticBandwidth(List<double> samples, double range) {
    if (samples.length == 1) return math.max(range / 8, 0.000001);
    final mean = samples.reduce((left, right) => left + right) / samples.length;
    var squaredDifference = 0.0;
    for (final sample in samples) {
      final difference = sample - mean;
      squaredDifference += difference * difference;
    }
    final standardDeviation = math.sqrt(
      squaredDifference / (samples.length - 1),
    );
    final silverman = 1.06 * standardDeviation * math.pow(samples.length, -0.2);
    final fallback = math.max(range / math.sqrt(samples.length), 0.000001);
    if (!silverman.isFinite || silverman <= 0) return fallback;
    return math.max(silverman, range / 1000);
  }

  static List<ChartDataPoint> _rugPoints(
    List<double> samples, {
    bool invertDomain = false,
  }) {
    final values = invertDomain ? samples.reversed : samples;
    return List.unmodifiable([
      for (final sample in values)
        ChartDataPoint(
          x: invertDomain ? -sample : sample,
          y: 0,
          metadata: {'sample': sample},
        ),
    ]);
  }
}
