// Copyright 2025 the braven_charts authors. All rights reserved.
// Use of this source code is governed by a MIT-style license
// that can be found in the LICENSE file.

import '../models/data_range.dart';

/// Calculates the ratio between two [DataRange] spans.
///
/// The ratio is always >= 1.0, representing how many times larger the
/// bigger range is compared to the smaller one. This is used for
/// automatic multi-axis normalization detection.
///
/// ## Usage
///
/// ```dart
/// final ratio = RangeRatioCalculator.calculateRatio(
///   DataRange(min: 0, max: 10),    // span = 10
///   DataRange(min: 0, max: 1000),  // span = 1000
/// );
/// // Returns 100.0 (1000/10)
/// ```
///
/// ## Edge Cases
///
/// - Zero-span range vs non-zero: returns `double.infinity`
/// - Two zero-span ranges: returns 1.0
/// - Negative ranges: uses absolute span values
/// - Order-independent: `calculateRatio(a, b) == calculateRatio(b, a)`
abstract final class RangeRatioCalculator {
  /// Calculates the ratio between two data range spans.
  ///
  /// Returns a value >= 1.0 representing how many times larger
  /// the bigger range span is compared to the smaller one.
  ///
  /// [range1] First data range to compare
  /// [range2] Second data range to compare
  ///
  /// Returns:
  /// - `double.infinity` if one range has zero span and the other doesn't
  /// - `1.0` if both ranges have zero span
  /// - The ratio (larger/smaller) otherwise, always >= 1.0
  static double calculateRatio(DataRange range1, DataRange range2) {
    final span1 = range1.span;
    final span2 = range2.span;

    // Handle zero-span edge cases
    if (span1 == 0 && span2 == 0) {
      return 1.0;
    }
    if (span1 == 0 || span2 == 0) {
      return double.infinity;
    }

    // Return ratio >= 1.0 (larger / smaller)
    if (span1 >= span2) {
      return span1 / span2;
    }
    return span2 / span1;
  }
}
