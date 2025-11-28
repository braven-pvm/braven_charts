// Copyright 2025 the braven_charts authors. All rights reserved.
// Use of this source code is governed by a MIT-style license
// that can be found in the LICENSE file.

import '../models/data_range.dart';
import 'range_ratio_calculator.dart';

/// Default threshold for automatic normalization detection.
///
/// When the ratio between any two series ranges exceeds this value,
/// multi-axis normalization is recommended.
const double kDefaultNormalizationThreshold = 10.0;

/// Detects when multi-axis normalization should be applied.
///
/// This class analyzes the Y-ranges of multiple data series and determines
/// if their scales differ significantly enough to warrant normalization.
///
/// ## Usage
///
/// ```dart
/// final seriesRanges = {
///   'temperature': DataRange(min: 0, max: 40),
///   'pressure': DataRange(min: 900, max: 1100),
/// };
///
/// if (NormalizationDetector.shouldNormalize(seriesRanges)) {
///   // Apply multi-axis normalization
/// }
///
/// final maxRatio = NormalizationDetector.getMaxRatio(seriesRanges);
/// print('Max ratio: $maxRatio'); // 5.0 (200/40)
/// ```
///
/// ## Algorithm
///
/// The detector compares all pairs of series ranges and checks if any pair
/// has a ratio >= the threshold (default: 10x). The ratio is calculated
/// as `max(span1, span2) / min(span1, span2)`, always yielding a value >= 1.0.
abstract final class NormalizationDetector {
  /// Determines if normalization should be applied to the given series ranges.
  ///
  /// Returns `true` if any pair of series has a range ratio >= [threshold].
  ///
  /// [seriesRanges] Map of series identifiers to their data ranges
  /// [threshold] The ratio threshold (default: 10.0)
  ///
  /// Returns:
  /// - `false` if fewer than 2 series
  /// - `true` if any pair ratio >= threshold
  /// - `false` otherwise
  static bool shouldNormalize(
    Map<String, DataRange> seriesRanges, {
    double threshold = kDefaultNormalizationThreshold,
  }) {
    final ranges = seriesRanges.values.toList();

    // Need at least 2 series to compare
    if (ranges.length < 2) {
      return false;
    }

    // Compare all pairs
    for (int i = 0; i < ranges.length; i++) {
      for (int j = i + 1; j < ranges.length; j++) {
        final ratio = RangeRatioCalculator.calculateRatio(
          ranges[i],
          ranges[j],
        );
        if (ratio >= threshold) {
          return true;
        }
      }
    }

    return false;
  }

  /// Calculates the maximum ratio between any pair of series ranges.
  ///
  /// This is useful for understanding the scale disparity between series,
  /// even when normalization isn't strictly needed.
  ///
  /// [seriesRanges] Map of series identifiers to their data ranges
  ///
  /// Returns:
  /// - `1.0` if fewer than 2 series
  /// - The maximum ratio found among all pairs
  static double getMaxRatio(Map<String, DataRange> seriesRanges) {
    final ranges = seriesRanges.values.toList();

    // Need at least 2 series to compare
    if (ranges.length < 2) {
      return 1.0;
    }

    double maxRatio = 1.0;

    // Compare all pairs
    for (int i = 0; i < ranges.length; i++) {
      for (int j = i + 1; j < ranges.length; j++) {
        final ratio = RangeRatioCalculator.calculateRatio(
          ranges[i],
          ranges[j],
        );
        if (ratio > maxRatio) {
          maxRatio = ratio;
        }
      }
    }

    return maxRatio;
  }
}
