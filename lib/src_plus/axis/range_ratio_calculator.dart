// Copyright 2025 Braven Charts - Range Ratio Calculator
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import '../models/chart_data_point.dart';
import '../models/chart_series.dart';

/// Computes Y-range ratios between series for auto-detection.
///
/// Used to determine when series have vastly different Y-ranges
/// that would benefit from multi-axis normalization.
///
/// ## Usage
///
/// ```dart
/// // Compute range for a single series
/// final range = RangeRatioCalculator.computeRange(series.points);
/// print('Min: ${range.min}, Max: ${range.max}, Span: ${range.span}');
///
/// // Compute ratio between two ranges
/// final ratio = RangeRatioCalculator.computeRangeRatio(range1, range2);
/// if (ratio > 10) {
///   print('Ranges differ by more than 10x - multi-axis recommended');
/// }
///
/// // Find max ratio across all series
/// final result = RangeRatioCalculator.computeMaxRatioAcrossSeries(seriesList);
/// print('Max ratio: ${result.maxRatio} between ${result.series1Id} and ${result.series2Id}');
/// ```
class RangeRatioCalculator {
  /// Private constructor - use static methods.
  const RangeRatioCalculator._();

  /// Computes the Y-range (min, max, span) for a list of data points.
  ///
  /// Returns null if the points list is empty.
  static SeriesRange? computeRange(List<ChartDataPoint> points) {
    if (points.isEmpty) return null;

    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final point in points) {
      if (point.y.isFinite) {
        minY = math.min(minY, point.y);
        maxY = math.max(maxY, point.y);
      }
    }

    // If no finite values found
    if (minY == double.infinity || maxY == double.negativeInfinity) {
      return null;
    }

    return SeriesRange(min: minY, max: maxY);
  }

  /// Computes the ratio between two ranges.
  ///
  /// Returns the ratio of larger span to smaller span, always >= 1.0.
  /// Returns [double.infinity] if either span is zero.
  ///
  /// Example:
  /// - Range1 span: 150, Range2 span: 120 → ratio = 1.25
  /// - Range1 span: 150, Range2 span: 0.004 → ratio = 37500
  static double computeRangeRatio(SeriesRange range1, SeriesRange range2) {
    final span1 = range1.span;
    final span2 = range2.span;

    // Handle zero spans
    if (span1 == 0 && span2 == 0) return 1.0;
    if (span1 == 0 || span2 == 0) return double.infinity;

    // Always return larger/smaller to ensure ratio >= 1
    return span1 >= span2 ? span1 / span2 : span2 / span1;
  }

  /// Finds the maximum range ratio across all series pairs.
  ///
  /// Compares every pair of series and returns the maximum ratio found,
  /// along with the IDs of the two series with that ratio.
  ///
  /// Returns a result with maxRatio = 1.0 for 0 or 1 series.
  static MaxRatioResult computeMaxRatioAcrossSeries(List<ChartSeries> seriesList) {
    if (seriesList.length < 2) {
      return const MaxRatioResult(
        maxRatio: 1.0,
        series1Id: null,
        series2Id: null,
        seriesRanges: {},
      );
    }

    // Compute ranges for all series
    final Map<String, SeriesRange> ranges = {};
    for (final series in seriesList) {
      final range = computeRange(series.points);
      if (range != null) {
        ranges[series.id] = range;
      }
    }

    if (ranges.length < 2) {
      return MaxRatioResult(
        maxRatio: 1.0,
        series1Id: null,
        series2Id: null,
        seriesRanges: ranges,
      );
    }

    // Find maximum ratio
    double maxRatio = 1.0;
    String? maxSeries1;
    String? maxSeries2;

    final seriesIds = ranges.keys.toList();
    for (int i = 0; i < seriesIds.length; i++) {
      for (int j = i + 1; j < seriesIds.length; j++) {
        final id1 = seriesIds[i];
        final id2 = seriesIds[j];
        final ratio = computeRangeRatio(ranges[id1]!, ranges[id2]!);

        if (ratio > maxRatio) {
          maxRatio = ratio;
          maxSeries1 = id1;
          maxSeries2 = id2;
        }
      }
    }

    return MaxRatioResult(
      maxRatio: maxRatio,
      series1Id: maxSeries1,
      series2Id: maxSeries2,
      seriesRanges: ranges,
    );
  }
}

/// Represents the Y-range of a series.
class SeriesRange {
  /// Creates a series range with min and max values.
  const SeriesRange({required this.min, required this.max});

  /// Minimum Y value in the series.
  final double min;

  /// Maximum Y value in the series.
  final double max;

  /// The span (difference) between max and min.
  double get span => max - min;

  @override
  String toString() => 'SeriesRange(min: $min, max: $max, span: $span)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SeriesRange && runtimeType == other.runtimeType && min == other.min && max == other.max;

  @override
  int get hashCode => Object.hash(min, max);
}

/// Result of computing the maximum ratio across series.
class MaxRatioResult {
  /// Creates a max ratio result.
  const MaxRatioResult({
    required this.maxRatio,
    required this.series1Id,
    required this.series2Id,
    required this.seriesRanges,
  });

  /// The maximum ratio found between any two series.
  final double maxRatio;

  /// ID of the first series in the pair with max ratio.
  final String? series1Id;

  /// ID of the second series in the pair with max ratio.
  final String? series2Id;

  /// Computed ranges for all series (by ID).
  final Map<String, SeriesRange> seriesRanges;

  @override
  String toString() => 'MaxRatioResult(maxRatio: $maxRatio, pair: $series1Id/$series2Id)';
}
