// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'chart_data_point.dart';

/// Strategy used to choose the number of equal-width histogram bins.
enum HistogramBinningMethod {
  /// Uses the interquartile range and sample count to resist outliers.
  freedmanDiaconis,

  /// Uses `ceil(log2(n) + 1)` bins.
  sturges,

  /// Uses `ceil(sqrt(n))` bins.
  squareRoot,

  /// Uses the caller-provided [HistogramChartData.requestedBinCount].
  fixedCount,
}

/// Value encoded by the height of a histogram bar.
enum HistogramValueMode { count, percentage, density }

/// One equal-width interval in a prepared histogram.
@immutable
class HistogramBin {
  const HistogramBin({
    required this.lowerBound,
    required this.upperBound,
    required this.count,
    required this.sampleCount,
    required this.isLast,
  });

  final double lowerBound;
  final double upperBound;
  final int count;
  final int sampleCount;

  /// Whether this bin includes its upper bound.
  final bool isLast;

  double get center => (lowerBound + upperBound) / 2;
  double get width => upperBound - lowerBound;
  double get percentage => sampleCount == 0 ? 0 : count / sampleCount * 100;
  double get density =>
      sampleCount == 0 || width == 0 ? 0 : count / (sampleCount * width);

  /// Compact interval label suitable for a categorical axis.
  String get label =>
      '${_formatBoundary(lowerBound)}–${_formatBoundary(upperBound)}';

  bool contains(double value) =>
      value >= lowerBound &&
      (value < upperBound || isLast && value <= upperBound);

  static String _formatBoundary(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    if (value.abs() < 1) return value.toStringAsFixed(2);
    return value.toStringAsFixed(1);
  }
}

/// Immutable equal-width bins prepared from continuous numeric samples.
///
/// The result renders with an ordinary [BarChartSeries]. Binning remains a
/// data transformation so histogram data can also be inspected in tables,
/// exported, or composed with other Cartesian series.
@immutable
class HistogramChartData {
  factory HistogramChartData({
    required Iterable<double> samples,
    HistogramBinningMethod method = HistogramBinningMethod.freedmanDiaconis,
    int requestedBinCount = 10,
    int maxBinCount = 100,
  }) {
    if (requestedBinCount < 1) {
      throw ArgumentError.value(
        requestedBinCount,
        'requestedBinCount',
        'Bin count must be at least 1',
      );
    }
    if (maxBinCount < 1) {
      throw ArgumentError.value(
        maxBinCount,
        'maxBinCount',
        'Maximum bin count must be at least 1',
      );
    }

    final sorted = samples.toList(growable: false);
    for (final sample in sorted) {
      if (!sample.isFinite) {
        throw ArgumentError.value(
          sample,
          'samples',
          'Histogram samples must be finite',
        );
      }
    }
    sorted.sort();
    if (sorted.isEmpty) {
      return HistogramChartData._(
        samples: const [],
        bins: const [],
        method: method,
        requestedBinCount: requestedBinCount,
        binWidth: 0,
      );
    }

    final minimum = sorted.first;
    final maximum = sorted.last;
    if (minimum == maximum) {
      final halfWidth = minimum == 0 ? 0.5 : minimum.abs() * 0.05;
      final width = halfWidth == 0 ? 1.0 : halfWidth * 2;
      return HistogramChartData._(
        samples: List.unmodifiable(sorted),
        bins: List.unmodifiable([
          HistogramBin(
            lowerBound: minimum - width / 2,
            upperBound: maximum + width / 2,
            count: sorted.length,
            sampleCount: sorted.length,
            isLast: true,
          ),
        ]),
        method: method,
        requestedBinCount: requestedBinCount,
        binWidth: width,
      );
    }

    final resolvedCount = _resolveBinCount(
      sorted,
      method: method,
      requestedBinCount: requestedBinCount,
      maxBinCount: maxBinCount,
    );
    final width = (maximum - minimum) / resolvedCount;
    final counts = List<int>.filled(resolvedCount, 0);
    for (final sample in sorted) {
      final index = ((sample - minimum) / width).floor().clamp(
        0,
        resolvedCount - 1,
      );
      counts[index]++;
    }

    return HistogramChartData._(
      samples: List.unmodifiable(sorted),
      bins: List.unmodifiable([
        for (var index = 0; index < resolvedCount; index++)
          HistogramBin(
            lowerBound: minimum + width * index,
            upperBound: index == resolvedCount - 1
                ? maximum
                : minimum + width * (index + 1),
            count: counts[index],
            sampleCount: sorted.length,
            isLast: index == resolvedCount - 1,
          ),
      ]),
      method: method,
      requestedBinCount: requestedBinCount,
      binWidth: width,
    );
  }

  const HistogramChartData._({
    required this.samples,
    required this.bins,
    required this.method,
    required this.requestedBinCount,
    required this.binWidth,
  });

  final List<double> samples;
  final List<HistogramBin> bins;
  final HistogramBinningMethod method;
  final int requestedBinCount;
  final double binWidth;

  int get sampleCount => samples.length;
  double? get minimum => samples.isEmpty ? null : samples.first;
  double? get maximum => samples.isEmpty ? null : samples.last;

  List<ChartDataPoint> pointsFor(HistogramValueMode mode) => List.unmodifiable([
    for (var index = 0; index < bins.length; index++)
      ChartDataPoint(
        x: index.toDouble(),
        y: switch (mode) {
          HistogramValueMode.count => bins[index].count.toDouble(),
          HistogramValueMode.percentage => bins[index].percentage,
          HistogramValueMode.density => bins[index].density,
        },
        label: bins[index].label,
      ),
  ]);

  static int _resolveBinCount(
    List<double> sorted, {
    required HistogramBinningMethod method,
    required int requestedBinCount,
    required int maxBinCount,
  }) {
    final sampleCount = sorted.length;
    final range = sorted.last - sorted.first;
    final count = switch (method) {
      HistogramBinningMethod.fixedCount => requestedBinCount,
      HistogramBinningMethod.squareRoot => math.sqrt(sampleCount).ceil(),
      HistogramBinningMethod.sturges =>
        (math.log(sampleCount) / math.ln2 + 1).ceil(),
      HistogramBinningMethod.freedmanDiaconis => () {
        final q1 = _quantile(sorted, 0.25);
        final q3 = _quantile(sorted, 0.75);
        final width = 2 * (q3 - q1) / math.pow(sampleCount, 1 / 3);
        if (!width.isFinite || width <= 0) {
          return (math.log(sampleCount) / math.ln2 + 1).ceil();
        }
        return (range / width).ceil();
      }(),
    };
    return count.clamp(1, maxBinCount);
  }

  static double _quantile(List<double> sorted, double probability) {
    final position = (sorted.length - 1) * probability;
    final lower = position.floor();
    final upper = position.ceil();
    if (lower == upper) return sorted[lower];
    final fraction = position - lower;
    return sorted[lower] + (sorted[upper] - sorted[lower]) * fraction;
  }
}
