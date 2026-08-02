// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import 'heatmap_data_point.dart';

/// Value encoded by a cell produced from a 2D histogram.
enum HeatmapHistogramValueMode {
  /// Number of observations in the bin.
  count,

  /// Sum of the observation weights in the bin.
  weight,
}

/// How bins without observations are represented in canonical Heatmap data.
enum HeatmapHistogramEmptyBinMode {
  /// Emit a measured cell whose value is zero.
  zero,

  /// Emit an explicit missing Heatmap cell.
  missing,

  /// Do not emit a cell for the empty bin.
  omit,
}

/// One raw observation supplied to a 2D histogram transform.
@immutable
final class HeatmapHistogramObservation {
  HeatmapHistogramObservation({
    required this.x,
    required this.y,
    this.weight = 1,
    this.pointKey,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata == null ? null : Map.unmodifiable(metadata) {
    if (!x.isFinite) {
      throw ArgumentError.value(x, 'x', 'must be finite');
    }
    if (!y.isFinite) {
      throw ArgumentError.value(y, 'y', 'must be finite');
    }
    if (!weight.isFinite || weight < 0) {
      throw ArgumentError.value(
        weight,
        'weight',
        'must be finite and non-negative',
      );
    }
    if (pointKey != null && pointKey!.isEmpty) {
      throw ArgumentError.value(pointKey, 'pointKey', 'must not be empty');
    }
  }

  /// Horizontal numeric observation.
  final double x;

  /// Vertical numeric observation.
  final double y;

  /// Non-negative contribution used by [HeatmapHistogramValueMode.weight].
  final double weight;

  /// Optional durable raw-observation identity.
  final String? pointKey;

  /// Optional host data retained with the raw observation.
  final Map<String, dynamic>? metadata;
}

/// One numeric interval on a 2D histogram axis.
@immutable
final class HeatmapHistogramInterval {
  const HeatmapHistogramInterval({
    required this.index,
    required this.lowerBound,
    required this.upperBound,
    required this.isLast,
    required this.label,
  });

  final int index;
  final double lowerBound;
  final double upperBound;

  /// Whether this interval includes [upperBound].
  final bool isLast;

  /// Display label suitable for a categorical Heatmap axis.
  final String label;

  double get center => (lowerBound + upperBound) / 2;
  double get width => upperBound - lowerBound;

  bool contains(double value) =>
      value >= lowerBound &&
      (value < upperBound || isLast && value <= upperBound);
}

/// Explicit bin boundaries and labels for one 2D histogram axis.
@immutable
final class HeatmapHistogramAxis {
  HeatmapHistogramAxis({required List<double> boundaries, List<String>? labels})
    : boundaries = List.unmodifiable(boundaries),
      labels = List.unmodifiable(
        labels ??
            [
              for (var index = 0; index < boundaries.length - 1; index++)
                '${_formatBoundary(boundaries[index])}–'
                    '${_formatBoundary(boundaries[index + 1])}',
            ],
      ) {
    if (boundaries.length < 2) {
      throw ArgumentError.value(
        boundaries,
        'boundaries',
        'must contain at least two values',
      );
    }
    for (var index = 0; index < boundaries.length; index++) {
      final value = boundaries[index];
      if (!value.isFinite) {
        throw ArgumentError.value(
          value,
          'boundaries[$index]',
          'must be finite',
        );
      }
      if (index > 0 && value <= boundaries[index - 1]) {
        throw ArgumentError.value(
          value,
          'boundaries[$index]',
          'must be greater than the preceding boundary',
        );
      }
    }
    if (this.labels.length != binCount) {
      throw ArgumentError.value(
        labels,
        'labels',
        'must contain exactly $binCount entries',
      );
    }
    for (var index = 0; index < this.labels.length; index++) {
      if (this.labels[index].isEmpty) {
        throw ArgumentError.value(
          this.labels[index],
          'labels[$index]',
          'must not be empty',
        );
      }
    }
  }

  final List<double> boundaries;
  final List<String> labels;

  int get binCount => boundaries.length - 1;

  HeatmapHistogramInterval intervalAt(int index) {
    RangeError.checkValidIndex(index, boundaries, 'index', binCount);
    return HeatmapHistogramInterval(
      index: index,
      lowerBound: boundaries[index],
      upperBound: boundaries[index + 1],
      isLast: index == binCount - 1,
      label: labels[index],
    );
  }

  /// Returns the containing bin, or `null` when [value] is outside the domain.
  int? indexOf(double value) {
    if (!value.isFinite ||
        value < boundaries.first ||
        value > boundaries.last) {
      return null;
    }
    if (value == boundaries.last) return binCount - 1;

    var low = 0;
    var high = binCount;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      if (value < boundaries[middle]) {
        high = middle;
      } else if (value >= boundaries[middle + 1]) {
        low = middle + 1;
      } else {
        return middle;
      }
    }
    return null;
  }

  static String _formatBoundary(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    if (value.abs() < 1) return value.toStringAsFixed(2);
    return value.toStringAsFixed(1);
  }
}

/// Aggregated contents of one X/Y bin.
@immutable
final class HeatmapHistogramBin {
  const HeatmapHistogramBin({
    required this.xInterval,
    required this.yInterval,
    required this.count,
    required this.totalWeight,
    required this.sourceIndices,
    required this.sourcePointKeys,
  });

  final HeatmapHistogramInterval xInterval;
  final HeatmapHistogramInterval yInterval;
  final int count;
  final double totalWeight;

  /// Input-order positions retained for exact host-side source lookup.
  final List<int> sourceIndices;

  /// Durable identities retained for observations that supplied one.
  final List<String> sourcePointKeys;

  bool get isEmpty => count == 0;
}

/// Deterministic 2D-histogram aggregation prepared for a native Heatmap.
///
/// Binning is deliberately a data transform rather than renderer behavior.
/// The resulting [HeatmapDataPoint] list therefore uses the normal Heatmap
/// renderer, table, artifact, interaction, and generated-source paths.
@immutable
final class HeatmapHistogramData {
  factory HeatmapHistogramData({
    required Iterable<HeatmapHistogramObservation> observations,
    required HeatmapHistogramAxis xAxis,
    required HeatmapHistogramAxis yAxis,
  }) {
    final source = List<HeatmapHistogramObservation>.unmodifiable(observations);
    final pointKeys = <String>{};
    for (var index = 0; index < source.length; index++) {
      final pointKey = source[index].pointKey;
      if (pointKey != null && !pointKeys.add(pointKey)) {
        throw ArgumentError.value(
          pointKey,
          'observations[$index].pointKey',
          'duplicates an existing raw observation identity',
        );
      }
    }

    final mutableBins = List.generate(
      xAxis.binCount * yAxis.binCount,
      (_) => _MutableHeatmapHistogramBin(),
    );
    var outsideCount = 0;
    var outsideWeight = 0.0;
    for (var index = 0; index < source.length; index++) {
      final observation = source[index];
      final xIndex = xAxis.indexOf(observation.x);
      final yIndex = yAxis.indexOf(observation.y);
      if (xIndex == null || yIndex == null) {
        outsideCount++;
        outsideWeight += observation.weight;
        continue;
      }
      final bin = mutableBins[yIndex * xAxis.binCount + xIndex];
      bin.count++;
      bin.totalWeight += observation.weight;
      bin.sourceIndices.add(index);
      final pointKey = observation.pointKey;
      if (pointKey != null) bin.sourcePointKeys.add(pointKey);
    }

    return HeatmapHistogramData._(
      observations: source,
      xAxis: xAxis,
      yAxis: yAxis,
      bins: List.unmodifiable([
        for (var yIndex = 0; yIndex < yAxis.binCount; yIndex++)
          for (var xIndex = 0; xIndex < xAxis.binCount; xIndex++)
            () {
              final mutable = mutableBins[yIndex * xAxis.binCount + xIndex];
              return HeatmapHistogramBin(
                xInterval: xAxis.intervalAt(xIndex),
                yInterval: yAxis.intervalAt(yIndex),
                count: mutable.count,
                totalWeight: mutable.totalWeight,
                sourceIndices: List.unmodifiable(mutable.sourceIndices),
                sourcePointKeys: List.unmodifiable(mutable.sourcePointKeys),
              );
            }(),
      ]),
      outsideObservationCount: outsideCount,
      outsideWeight: outsideWeight,
    );
  }

  const HeatmapHistogramData._({
    required this.observations,
    required this.xAxis,
    required this.yAxis,
    required this.bins,
    required this.outsideObservationCount,
    required this.outsideWeight,
  });

  final List<HeatmapHistogramObservation> observations;
  final HeatmapHistogramAxis xAxis;
  final HeatmapHistogramAxis yAxis;
  final List<HeatmapHistogramBin> bins;

  /// Observations outside either explicit axis domain.
  final int outsideObservationCount;

  /// Combined weight of observations outside either explicit axis domain.
  final double outsideWeight;

  int get includedObservationCount =>
      observations.length - outsideObservationCount;

  double get includedWeight =>
      bins.fold(0, (total, bin) => total + bin.totalWeight);

  HeatmapHistogramBin binAt({required int xIndex, required int yIndex}) {
    RangeError.checkValidIndex(xIndex, xAxis.labels, 'xIndex');
    RangeError.checkValidIndex(yIndex, yAxis.labels, 'yIndex');
    return bins[yIndex * xAxis.binCount + xIndex];
  }

  /// Creates canonical Heatmap cells in row-major order.
  List<HeatmapDataPoint> cellsFor({
    HeatmapHistogramValueMode valueMode = HeatmapHistogramValueMode.count,
    HeatmapHistogramEmptyBinMode emptyBinMode =
        HeatmapHistogramEmptyBinMode.zero,
  }) => List.unmodifiable([
    for (final bin in bins)
      if (!bin.isEmpty || emptyBinMode != HeatmapHistogramEmptyBinMode.omit)
        _cellFor(bin, valueMode: valueMode, emptyBinMode: emptyBinMode),
  ]);

  static HeatmapDataPoint _cellFor(
    HeatmapHistogramBin bin, {
    required HeatmapHistogramValueMode valueMode,
    required HeatmapHistogramEmptyBinMode emptyBinMode,
  }) {
    final metadata = <String, dynamic>{
      'histogramXLowerBound': bin.xInterval.lowerBound,
      'histogramXUpperBound': bin.xInterval.upperBound,
      'histogramYLowerBound': bin.yInterval.lowerBound,
      'histogramYUpperBound': bin.yInterval.upperBound,
      'histogramCount': bin.count,
      'histogramWeight': bin.totalWeight,
      'histogramSourceIndices': bin.sourceIndices,
      'histogramSourcePointKeys': bin.sourcePointKeys,
    };
    final x = bin.xInterval.index.toDouble();
    final y = bin.yInterval.index.toDouble();
    final pointKey = 'histogram-${bin.yInterval.index}-${bin.xInterval.index}';
    final label = '${bin.yInterval.label} · ${bin.xInterval.label}';

    if (bin.isEmpty && emptyBinMode == HeatmapHistogramEmptyBinMode.missing) {
      return HeatmapDataPoint.missing(
        x: x,
        y: y,
        pointKey: pointKey,
        label: label,
        metadata: metadata,
      );
    }

    return HeatmapDataPoint(
      x: x,
      y: y,
      value: switch (valueMode) {
        HeatmapHistogramValueMode.count => bin.count.toDouble(),
        HeatmapHistogramValueMode.weight => bin.totalWeight,
      },
      pointKey: pointKey,
      label: label,
      metadata: metadata,
    );
  }
}

final class _MutableHeatmapHistogramBin {
  int count = 0;
  double totalWeight = 0;
  final List<int> sourceIndices = [];
  final List<String> sourcePointKeys = [];
}
