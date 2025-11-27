/// Multi-axis Y value normalization for charts.
///
/// Normalizes Y values to a 0-1 range based on per-axis bounds,
/// enabling series with vastly different scales to share a common
/// chart area while maintaining their original values for display.
///
/// This is the core of multi-axis visualization - each series is
/// normalized to its own axis scale, ensuring every series spans
/// the full vertical height regardless of absolute data range.
///
/// See also:
/// - [AxisBoundsCalculator] for computing per-axis bounds
/// - [SeriesAxisResolver] for binding series to axes
/// - [NormalizationMode] for controlling normalization behavior
library;

import 'dart:ui' show Offset;

import '../models/normalization_mode.dart';

/// Normalizer for converting Y values between original and 0-1 normalized scales.
///
/// The normalizer handles:
/// - Basic Y value normalization (value → 0-1 range)
/// - Denormalization (0-1 → original value)
/// - Point and series normalization (preserving X coordinates)
/// - Clamping options for out-of-bounds values
/// - NormalizationMode-aware processing
///
/// Example:
/// ```dart
/// final normalizer = MultiAxisNormalizer();
///
/// // Power data: 0-400 W
/// final powerNormalized = normalizer.normalizeY(200, 0, 400); // 0.5
///
/// // Heart rate: 60-180 bpm
/// final hrNormalized = normalizer.normalizeY(120, 60, 180); // 0.5
///
/// // Both are at 0.5 despite different absolute values
/// ```
class MultiAxisNormalizer {
  /// Creates a multi-axis normalizer.
  const MultiAxisNormalizer();

  /// Normalizes a Y value to the 0-1 range based on axis bounds.
  ///
  /// [value] is the original Y value.
  /// [axisMin] is the axis minimum value.
  /// [axisMax] is the axis maximum value.
  /// [clamp] if true, clamps result to 0-1 range (default: false).
  ///
  /// Returns:
  /// - 0.0 when value equals axisMin
  /// - 1.0 when value equals axisMax
  /// - 0.5 when value is at midpoint
  /// - Values outside 0-1 if not clamped
  ///
  /// Special cases:
  /// - If axisMin == axisMax, returns 0.5 (centered)
  ///
  /// Example:
  /// ```dart
  /// final norm = normalizer.normalizeY(50, 0, 100); // 0.5
  /// final norm2 = normalizer.normalizeY(150, 0, 100, clamp: true); // 1.0
  /// ```
  double normalizeY(
    double value,
    double axisMin,
    double axisMax, {
    bool clamp = false,
  }) {
    // Handle zero range (all values same)
    final range = axisMax - axisMin;
    if (range == 0) return 0.5;

    // Normalize to 0-1
    final normalized = (value - axisMin) / range;

    // Apply clamping if requested
    if (clamp) {
      if (normalized < 0.0) return 0.0;
      if (normalized > 1.0) return 1.0;
    }

    return normalized;
  }

  /// Converts a normalized (0-1) value back to the original scale.
  ///
  /// [normalizedValue] is the value in 0-1 range.
  /// [axisMin] is the axis minimum value.
  /// [axisMax] is the axis maximum value.
  ///
  /// This is the inverse of [normalizeY].
  ///
  /// Example:
  /// ```dart
  /// final original = normalizer.denormalizeY(0.5, 0, 100); // 50.0
  /// ```
  double denormalizeY(
    double normalizedValue,
    double axisMin,
    double axisMax,
  ) {
    final range = axisMax - axisMin;
    return axisMin + (normalizedValue * range);
  }

  /// Normalizes a data point, preserving the X coordinate.
  ///
  /// [point] is the original data point (x, y).
  /// [axisMin] is the Y-axis minimum value.
  /// [axisMax] is the Y-axis maximum value.
  /// [clamp] if true, clamps Y to 0-1 range.
  ///
  /// Returns a new Offset with:
  /// - dx unchanged (X coordinate preserved)
  /// - dy normalized to 0-1 range
  ///
  /// Example:
  /// ```dart
  /// final point = Offset(timestamp, 50.0);
  /// final normalized = normalizer.normalizePoint(point, 0, 100);
  /// // normalized.dx == timestamp, normalized.dy == 0.5
  /// ```
  Offset normalizePoint(
    Offset point,
    double axisMin,
    double axisMax, {
    bool clamp = false,
  }) {
    return Offset(
      point.dx,
      normalizeY(point.dy, axisMin, axisMax, clamp: clamp),
    );
  }

  /// Normalizes a list of data points.
  ///
  /// [points] is the list of original data points.
  /// [axisMin] is the Y-axis minimum value.
  /// [axisMax] is the Y-axis maximum value.
  /// [clamp] if true, clamps Y values to 0-1 range.
  ///
  /// Returns a new list with all Y values normalized.
  /// Original list is not modified.
  ///
  /// Example:
  /// ```dart
  /// final points = [Offset(1, 0), Offset(2, 50), Offset(3, 100)];
  /// final normalized = normalizer.normalizePoints(points, 0, 100);
  /// // normalized[0].dy == 0.0
  /// // normalized[1].dy == 0.5
  /// // normalized[2].dy == 1.0
  /// ```
  List<Offset> normalizePoints(
    List<Offset> points,
    double axisMin,
    double axisMax, {
    bool clamp = false,
  }) {
    return points.map((p) => normalizePoint(p, axisMin, axisMax, clamp: clamp)).toList();
  }

  /// Denormalizes a data point back to original scale.
  ///
  /// [point] is the normalized point (x, normalized y).
  /// [axisMin] is the Y-axis minimum value.
  /// [axisMax] is the Y-axis maximum value.
  ///
  /// Returns a new Offset with:
  /// - dx unchanged
  /// - dy converted from 0-1 to original scale
  Offset denormalizePoint(
    Offset point,
    double axisMin,
    double axisMax,
  ) {
    return Offset(
      point.dx,
      denormalizeY(point.dy, axisMin, axisMax),
    );
  }

  /// Applies normalization based on the specified mode.
  ///
  /// [value] is the original Y value.
  /// [mode] determines normalization behavior.
  /// [axisMin] is the axis minimum value.
  /// [axisMax] is the axis maximum value.
  ///
  /// Returns:
  /// - [NormalizationMode.none]: value unchanged
  /// - [NormalizationMode.auto]: value normalized
  /// - [NormalizationMode.perSeries]: value normalized
  ///
  /// Example:
  /// ```dart
  /// final result = normalizer.applyNormalizationMode(
  ///   50, NormalizationMode.auto, 0, 100,
  /// ); // 0.5
  ///
  /// final unchanged = normalizer.applyNormalizationMode(
  ///   50, NormalizationMode.none, 0, 100,
  /// ); // 50.0
  /// ```
  double applyNormalizationMode(
    double value,
    NormalizationMode mode,
    double axisMin,
    double axisMax,
  ) {
    switch (mode) {
      case NormalizationMode.none:
        // No normalization - pass through unchanged
        return value;
      case NormalizationMode.auto:
      case NormalizationMode.perSeries:
        // Both auto and perSeries normalize values
        return normalizeY(value, axisMin, axisMax);
    }
  }

  /// Applies normalization to a point based on the specified mode.
  ///
  /// Similar to [applyNormalizationMode] but for Offset points.
  Offset applyNormalizationModeToPoint(
    Offset point,
    NormalizationMode mode,
    double axisMin,
    double axisMax,
  ) {
    switch (mode) {
      case NormalizationMode.none:
        return point;
      case NormalizationMode.auto:
      case NormalizationMode.perSeries:
        return normalizePoint(point, axisMin, axisMax);
    }
  }

  /// Applies normalization to multiple points based on the specified mode.
  ///
  /// Similar to [applyNormalizationMode] but for lists of Offset points.
  List<Offset> applyNormalizationModeToPoints(
    List<Offset> points,
    NormalizationMode mode,
    double axisMin,
    double axisMax,
  ) {
    switch (mode) {
      case NormalizationMode.none:
        return points;
      case NormalizationMode.auto:
      case NormalizationMode.perSeries:
        return normalizePoints(points, axisMin, axisMax);
    }
  }

  /// Normalizes Y value using axis bounds record.
  ///
  /// Convenience method for use with bounds from [AxisBoundsCalculator].
  ///
  /// Example:
  /// ```dart
  /// final axisBounds = {'temp': (min: 20.0, max: 80.0)};
  /// final normalized = normalizer.normalizeYWithBounds(
  ///   50, axisBounds['temp']!,
  /// ); // 0.5
  /// ```
  double normalizeYWithBounds(
    double value,
    ({double min, double max}) bounds, {
    bool clamp = false,
  }) {
    return normalizeY(value, bounds.min, bounds.max, clamp: clamp);
  }

  /// Denormalizes Y value using axis bounds record.
  ///
  /// Convenience method for use with bounds from [AxisBoundsCalculator].
  double denormalizeYWithBounds(
    double normalizedValue,
    ({double min, double max}) bounds,
  ) {
    return denormalizeY(normalizedValue, bounds.min, bounds.max);
  }

  /// Checks if a value is within the axis bounds.
  ///
  /// Returns true if axisMin <= value <= axisMax.
  bool isWithinBounds(double value, double axisMin, double axisMax) {
    return value >= axisMin && value <= axisMax;
  }

  /// Clamps a value to the axis bounds.
  ///
  /// Returns:
  /// - axisMin if value < axisMin
  /// - axisMax if value > axisMax
  /// - value otherwise
  double clampToBounds(double value, double axisMin, double axisMax) {
    if (value < axisMin) return axisMin;
    if (value > axisMax) return axisMax;
    return value;
  }
}
