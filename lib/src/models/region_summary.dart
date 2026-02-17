// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:equatable/equatable.dart';

import 'data_region.dart';

/// Statistical metrics that can be computed for a region of chart data.
///
/// Each value has a human-readable [displayLabel] suitable for use in
/// summary overlays, tooltips, and other UI elements.
///
/// Example:
/// ```dart
/// final label = RegionMetric.average.displayLabel; // 'Avg'
/// ```
enum RegionMetric {
  /// Minimum Y value in the region.
  min('Min'),

  /// Maximum Y value in the region.
  max('Max'),

  /// Mean Y value across all points in the region.
  average('Avg'),

  /// Sum of all Y values in the region.
  sum('Sum'),

  /// Number of data points in the region.
  count('Count'),

  /// Difference between max and min Y values.
  range('Range'),

  /// Standard deviation of Y values (requires count >= 2).
  stdDev('Std Dev'),

  /// Change from first to last Y value (requires count >= 2).
  delta('Δ'),

  /// Y value of the first data point in the region.
  firstY('First'),

  /// Y value of the last data point in the region.
  lastY('Last'),

  /// X-axis span of the region (endX - startX).
  duration('Duration');

  const RegionMetric(this.displayLabel);

  /// Human-readable label for this metric, suitable for UI display.
  final String displayLabel;
}

/// Statistical summary for a single series within a [DataRegion].
///
/// Contains computed statistics (min, max, average, etc.) for all data
/// points belonging to one series that fall within a region's X-range.
///
/// **Nullable fields**: [stdDev] and [delta] are typically null when
/// [count] < 2 (insufficient data for meaningful computation). [firstY]
/// and [lastY] are typically null when [count] is 0. These are data
/// constraints enforced by the analyzer, not by this model — the model
/// is a plain data holder.
///
/// Example:
/// ```dart
/// final summary = SeriesRegionSummary(
///   seriesId: 'temperature',
///   seriesName: 'Temperature',
///   unit: '°C',
///   count: 10,
///   min: 18.0,
///   max: 32.0,
///   sum: 250.0,
///   average: 25.0,
///   range: 14.0,
///   stdDev: 4.5,
///   firstY: 20.0,
///   lastY: 28.0,
///   delta: 8.0,
///   duration: 3600.0,
/// );
/// ```
class SeriesRegionSummary extends Equatable {
  /// Creates a [SeriesRegionSummary] with required and optional fields.
  ///
  /// [seriesId] uniquely identifies the series.
  /// [count] is the number of data points in the region for this series.
  /// [min], [max], [sum], [average], [range] are required numeric statistics.
  /// [duration] is the X-axis span covered by the data points.
  /// [seriesName], [unit], [stdDev], [firstY], [lastY], [delta] are optional.
  const SeriesRegionSummary({
    required this.seriesId,
    this.seriesName,
    this.unit,
    required this.count,
    required this.min,
    required this.max,
    required this.sum,
    required this.average,
    required this.range,
    this.stdDev,
    this.firstY,
    this.lastY,
    this.delta,
    required this.duration,
  });

  /// Unique identifier for the series.
  final String seriesId;

  /// Optional human-readable name of the series.
  final String? seriesName;

  /// Optional unit of measurement (e.g., '°C', 'W', 'km/h').
  final String? unit;

  /// Number of data points in the region for this series.
  final int count;

  /// Minimum Y value among the data points.
  final double min;

  /// Maximum Y value among the data points.
  final double max;

  /// Sum of all Y values.
  final double sum;

  /// Mean Y value across all points.
  final double average;

  /// Difference between [max] and [min].
  final double range;

  /// Standard deviation of Y values.
  ///
  /// Typically null when [count] < 2.
  final double? stdDev;

  /// Y value of the first data point in the region.
  ///
  /// Typically null when [count] is 0.
  final double? firstY;

  /// Y value of the last data point in the region.
  ///
  /// Typically null when [count] is 0.
  final double? lastY;

  /// Change from [firstY] to [lastY] (lastY - firstY).
  ///
  /// Typically null when [count] < 2.
  final double? delta;

  /// X-axis span covered by the data points in this region.
  final double duration;

  @override
  List<Object?> get props => [
    seriesId,
    seriesName,
    unit,
    count,
    min,
    max,
    sum,
    average,
    range,
    stdDev,
    firstY,
    lastY,
    delta,
    duration,
  ];
}

/// Aggregated summary for all series within a [DataRegion].
///
/// Contains the [DataRegion] that was analyzed and a map of
/// [SeriesRegionSummary] results keyed by series identifier.
///
/// Example:
/// ```dart
/// final regionSummary = RegionSummary(
///   region: myRegion,
///   seriesSummaries: {
///     'temperature': tempSummary,
///     'humidity': humiditySummary,
///   },
/// );
/// ```
class RegionSummary extends Equatable {
  /// Creates a [RegionSummary] with the analyzed [region] and its
  /// per-series [seriesSummaries].
  const RegionSummary({required this.region, required this.seriesSummaries});

  /// The region that was analyzed.
  final DataRegion region;

  /// Per-series statistical summaries, keyed by series identifier.
  final Map<String, SeriesRegionSummary> seriesSummaries;

  @override
  List<Object?> get props => [region, seriesSummaries];
}
