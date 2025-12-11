// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

/// Represents minimum and maximum bounds for a data axis.
///
/// DataRange is an immutable structure defining the boundaries of data
/// along an axis, with optional padding for visual spacing.
///
/// Example:
/// ```dart
/// final range = DataRange(min: 0.0, max: 100.0, padding: 0.1);
/// print(range.span); // 100.0
/// print(range.paddedMin); // -10.0 (0 - 100 * 0.1)
/// print(range.contains(50.0)); // true
/// ```
class DataRange {
  /// Creates a data range with validation.
  ///
  /// [min] must be less than or equal to [max].
  /// [padding] must be between 0.0 and 1.0 if provided.
  const DataRange({
    required this.min,
    required this.max,
    this.padding = 0.0,
  }) : assert(min <= max, 'min must be <= max');

  /// Creates a range from a list of values.
  ///
  /// Returns a range spanning from the minimum to maximum value in the list.
  /// Returns zero range if the list is empty or contains only NaN/infinity values.
  factory DataRange.fromValues(List<double> values) {
    if (values.isEmpty) {
      return const DataRange(min: 0.0, max: 0.0);
    }

    var min = double.infinity;
    var max = double.negativeInfinity;

    for (final value in values) {
      if (value.isFinite) {
        if (value < min) min = value;
        if (value > max) max = value;
      }
    }

    // If no finite values found, return zero range
    if (min.isInfinite || max.isInfinite) {
      return const DataRange(min: 0.0, max: 0.0);
    }

    return DataRange(min: min, max: max);
  }

  /// Creates a symmetric range around a center point.
  ///
  /// Example:
  /// ```dart
  /// final range = DataRange.symmetric(center: 50.0, radius: 10.0);
  /// // Returns DataRange(min: 40.0, max: 60.0)
  /// ```
  factory DataRange.symmetric({
    required double center,
    required double radius,
  }) {
    return DataRange(
      min: center - radius,
      max: center + radius,
    );
  }

  /// Minimum value (lower bound).
  final double min;

  /// Maximum value (upper bound).
  final double max;

  /// Optional padding factor (0.0-1.0) for visual spacing.
  ///
  /// When provided, [paddedMin] and [paddedMax] extend the range
  /// by this percentage of the span.
  final double padding;

  /// The total span of the range (max - min).
  double get span => max - min;

  /// The center point of the range ((max + min) / 2).
  double get center => (max + min) / 2;

  /// Minimum value with padding applied.
  ///
  /// Extends the minimum by [padding] × [span] if padding is provided.
  double get paddedMin => min - (span * padding);

  /// Maximum value with padding applied.
  ///
  /// Extends the maximum by [padding] × [span] if padding is provided.
  double get paddedMax => max + (span * padding);

  /// Returns true if the value is within [min, max] (inclusive).
  bool contains(double value) => value >= min && value <= max;

  /// Returns true if this range overlaps with [other].
  ///
  /// Ranges overlap if they share any common values.
  bool overlaps(DataRange other) {
    return !(max < other.min || min > other.max);
  }

  /// Merges this range with [other], returning a range that encompasses both.
  ///
  /// Example:
  /// ```dart
  /// final r1 = DataRange(min: 0.0, max: 10.0);
  /// final r2 = DataRange(min: 5.0, max: 15.0);
  /// final merged = r1.merge(r2);
  /// // Returns DataRange(min: 0.0, max: 15.0)
  /// ```
  DataRange merge(DataRange other) {
    return DataRange(
      min: math.min(min, other.min),
      max: math.max(max, other.max),
      padding: math.max(padding, other.padding),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataRange &&
          runtimeType == other.runtimeType &&
          min == other.min &&
          max == other.max &&
          padding == other.padding;

  @override
  int get hashCode => Object.hash(min, max, padding);

  @override
  String toString() => 'DataRange(min: $min, max: $max, padding: $padding)';
}
