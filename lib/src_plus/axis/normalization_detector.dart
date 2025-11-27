// Copyright 2025 Braven Charts - Normalization Detector
// SPDX-License-Identifier: MIT

import '../models/chart_series.dart';
import 'range_ratio_calculator.dart';

/// Detects when multi-axis normalization should be applied.
///
/// Analyzes series Y-ranges and determines if they differ enough
/// to warrant separate Y-axes (default threshold: 10x difference).
///
/// ## Usage
///
/// ```dart
/// // Quick check if normalization is needed
/// if (NormalizationDetector.shouldNormalize(seriesList)) {
///   // Enable multi-axis mode
/// }
///
/// // Get detailed detection result
/// final result = NormalizationDetector.detect(seriesList);
/// if (result.shouldNormalize) {
///   print('Detected ${result.maxRatio}x difference between ${result.dominantPairIds}');
/// }
/// ```
class NormalizationDetector {
  /// Private constructor - use static methods.
  const NormalizationDetector._();

  /// Default threshold ratio for auto-detection.
  ///
  /// When the ratio between the largest and smallest series spans
  /// exceeds this threshold, multi-axis normalization is recommended.
  static const double defaultThreshold = 10.0;

  /// Quickly checks if normalization should be applied.
  ///
  /// Returns true if any two series have Y-ranges differing by more
  /// than [threshold] (default: 10x).
  ///
  /// Returns false for 0 or 1 series, as no comparison is possible.
  ///
  /// Example:
  /// ```dart
  /// final series = [powerSeries, microVoltSeries]; // 37000x difference
  /// if (NormalizationDetector.shouldNormalize(series)) {
  ///   // Enable multi-axis mode
  /// }
  /// ```
  static bool shouldNormalize(
    List<ChartSeries> series, {
    double threshold = defaultThreshold,
  }) {
    if (series.length < 2) return false;

    final result = RangeRatioCalculator.computeMaxRatioAcrossSeries(series);
    return result.maxRatio > threshold;
  }

  /// Performs detailed detection analysis.
  ///
  /// Returns a [DetectionResult] with:
  /// - Whether normalization is recommended
  /// - The maximum ratio found
  /// - The pair of series with the max ratio
  /// - Individual ranges for all series
  ///
  /// Example:
  /// ```dart
  /// final result = NormalizationDetector.detect(seriesList);
  /// if (result.shouldNormalize) {
  ///   print('Max ratio: ${result.maxRatio}x');
  ///   print('Between: ${result.dominantPairIds}');
  ///
  ///   // Use ranges for axis configuration
  ///   for (final entry in result.seriesRanges.entries) {
  ///     print('${entry.key}: ${entry.value.min} to ${entry.value.max}');
  ///   }
  /// }
  /// ```
  static DetectionResult detect(
    List<ChartSeries> series, {
    double threshold = defaultThreshold,
  }) {
    final ratioResult = RangeRatioCalculator.computeMaxRatioAcrossSeries(series);

    return DetectionResult(
      shouldNormalize: ratioResult.maxRatio > threshold,
      maxRatio: ratioResult.maxRatio,
      threshold: threshold,
      dominantPairIds: [
        if (ratioResult.series1Id != null) ratioResult.series1Id!,
        if (ratioResult.series2Id != null) ratioResult.series2Id!,
      ],
      seriesRanges: ratioResult.seriesRanges,
    );
  }

  /// Suggests Y-axis configurations based on detection results.
  ///
  /// Returns a list of suggested axis configurations when multi-axis
  /// mode is recommended. Returns empty list if single-axis is sufficient.
  ///
  /// Note: This is a helper for auto-configuration scenarios. Users can
  /// always provide explicit [YAxisConfig] for more control.
  static List<SuggestedAxisConfig> suggestAxes(
    List<ChartSeries> series, {
    double threshold = defaultThreshold,
  }) {
    final result = detect(series, threshold: threshold);
    if (!result.shouldNormalize) return [];

    // Group series by similar ranges (within 2x of each other)
    final groups = _groupSeriesByRange(series, result.seriesRanges);

    return groups.map((group) {
      return SuggestedAxisConfig(
        seriesIds: group.seriesIds,
        range: group.range,
        suggestedLabel: _generateAxisLabel(group),
      );
    }).toList();
  }

  /// Groups series that have similar Y-ranges.
  static List<_SeriesGroup> _groupSeriesByRange(
    List<ChartSeries> series,
    Map<String, SeriesRange> ranges,
  ) {
    final groups = <_SeriesGroup>[];
    final processed = <String>{};

    for (final s in series) {
      if (processed.contains(s.id)) continue;
      if (!ranges.containsKey(s.id)) continue;

      final range = ranges[s.id]!;
      final group = _SeriesGroup(
        seriesIds: [s.id],
        range: range,
      );

      // Find other series with similar ranges
      for (final other in series) {
        if (other.id == s.id || processed.contains(other.id)) continue;
        if (!ranges.containsKey(other.id)) continue;

        final otherRange = ranges[other.id]!;
        final ratio = RangeRatioCalculator.computeRangeRatio(range, otherRange);

        // Group if within 2x of each other
        if (ratio <= 2.0) {
          group.seriesIds.add(other.id);
          processed.add(other.id);
        }
      }

      processed.add(s.id);
      groups.add(group);
    }

    return groups;
  }

  /// Generates a suggested axis label for a group.
  static String _generateAxisLabel(_SeriesGroup group) {
    if (group.seriesIds.length == 1) {
      return group.seriesIds.first;
    }
    return '${group.seriesIds.first} + ${group.seriesIds.length - 1} more';
  }
}

/// Result of normalization detection.
class DetectionResult {
  /// Creates a detection result.
  const DetectionResult({
    required this.shouldNormalize,
    required this.maxRatio,
    required this.threshold,
    required this.dominantPairIds,
    required this.seriesRanges,
  });

  /// Whether multi-axis normalization is recommended.
  final bool shouldNormalize;

  /// The maximum ratio found between any two series.
  final double maxRatio;

  /// The threshold used for detection.
  final double threshold;

  /// IDs of the two series with the maximum ratio.
  final List<String> dominantPairIds;

  /// Computed Y-ranges for all series.
  final Map<String, SeriesRange> seriesRanges;

  @override
  String toString() => 'DetectionResult('
      'shouldNormalize: $shouldNormalize, '
      'maxRatio: ${maxRatio.toStringAsFixed(2)}, '
      'threshold: $threshold, '
      'dominantPair: $dominantPairIds)';
}

/// Suggested axis configuration from auto-detection.
class SuggestedAxisConfig {
  /// Creates a suggested axis config.
  const SuggestedAxisConfig({
    required this.seriesIds,
    required this.range,
    required this.suggestedLabel,
  });

  /// Series IDs that should use this axis.
  final List<String> seriesIds;

  /// The Y-range for this axis.
  final SeriesRange range;

  /// Suggested label for the axis.
  final String suggestedLabel;

  @override
  String toString() => 'SuggestedAxisConfig('
      'series: $seriesIds, '
      'range: ${range.min.toStringAsFixed(2)}-${range.max.toStringAsFixed(2)}, '
      'label: $suggestedLabel)';
}

/// Internal helper class for grouping series.
class _SeriesGroup {
  _SeriesGroup({required this.seriesIds, required this.range});

  final List<String> seriesIds;
  final SeriesRange range;
}
