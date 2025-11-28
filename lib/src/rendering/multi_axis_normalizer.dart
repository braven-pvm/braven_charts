import '../models/data_range.dart';
import '../models/series_axis_binding.dart';
import '../models/y_axis_config.dart';

// Re-export DataRange for convenience when importing this file
export '../models/data_range.dart';

/// Normalizes series data values to [0,1] range for rendering while
/// preserving ability to recover original values for display.
///
/// This is the core normalization engine for multi-axis chart rendering.
/// It converts data values between their original range and a normalized
/// [0,1] range, allowing multiple series with vastly different Y-ranges
/// to share the same vertical chart space.
///
/// The normalization formula is standard linear interpolation:
/// ```
/// normalized = (value - min) / (max - min)
/// ```
///
/// See: specs/011-multi-axis-normalization/data-model.md
class MultiAxisNormalizer {
  /// Private constructor - this is a utility class with static methods only.
  const MultiAxisNormalizer._();

  /// Normalizes [value] to [0,1] range based on axis [min] and [max].
  ///
  /// Returns:
  /// - `0.0` when value equals min
  /// - `1.0` when value equals max
  /// - Proportional values between for intermediate values
  /// - Values outside [0,1] when value is outside [min,max] range
  /// - `0.5` when min equals max (zero range edge case)
  ///
  /// Example:
  /// ```dart
  /// // Normalize 50 in range [0, 100]
  /// final result = MultiAxisNormalizer.normalize(50.0, 0.0, 100.0);
  /// // result == 0.5
  /// ```
  static double normalize(double value, double min, double max) {
    // Handle edge case: zero range (min == max)
    // Return 0.5 (middle of normalized range) to avoid division by zero
    final range = max - min;
    if (range == 0) {
      return 0.5;
    }

    // Handle infinite range - value at start of infinite range
    if (range.isInfinite) {
      return 0.0;
    }

    // Standard linear normalization
    return (value - min) / range;
  }

  /// Converts normalized [normalizedValue] back to original data value.
  ///
  /// This is the inverse of [normalize]. Used for tooltip/crosshair display
  /// to show original data values to the user.
  ///
  /// Returns:
  /// - [min] when normalizedValue is 0.0
  /// - [max] when normalizedValue is 1.0
  /// - Proportional values between for intermediate normalized values
  /// - When min equals max, returns that value regardless of normalizedValue
  ///
  /// Example:
  /// ```dart
  /// // Denormalize 0.5 from range [0, 100]
  /// final result = MultiAxisNormalizer.denormalize(0.5, 0.0, 100.0);
  /// // result == 50.0
  /// ```
  static double denormalize(double normalizedValue, double min, double max) {
    // Handle edge case: zero range (min == max)
    // Return the single value since there's no range to interpolate
    if (min == max) {
      return min;
    }

    // Standard linear denormalization (inverse of normalize)
    return normalizedValue * (max - min) + min;
  }

  /// Computes data bounds (min/max) for each Y-axis from series data.
  ///
  /// This method aggregates Y-values from all series bound to each axis
  /// and computes the appropriate min/max bounds for rendering.
  ///
  /// Returns a [Map] from axis ID to [DataRange].
  ///
  /// For each axis:
  /// - Uses explicit [YAxisConfig.min] when specified, otherwise
  ///   computes min from bound series data
  /// - Uses explicit [YAxisConfig.max] when specified, otherwise
  ///   computes max from bound series data
  /// - Returns default bounds [0.0, 1.0] when no data is available
  ///
  /// Parameters:
  /// - [axisConfigs]: List of Y-axis configurations
  /// - [bindings]: List of series-to-axis bindings
  /// - [seriesYValues]: Map from series ID to list of Y values
  /// - [defaultAxisId]: Axis ID to use for unbound series (default: 'primary')
  ///
  /// Example:
  /// ```dart
  /// final bounds = MultiAxisNormalizer.computeAxisBounds(
  ///   axisConfigs: [YAxisConfig(id: 'power', position: YAxisPosition.left)],
  ///   bindings: [SeriesAxisBinding(seriesId: 's1', yAxisId: 'power')],
  ///   seriesYValues: {'s1': [0.0, 50.0, 100.0]},
  /// );
  /// // bounds['power'] == DataRange(0.0, 100.0)
  /// ```
  static Map<String, DataRange> computeAxisBounds({
    required List<YAxisConfig> axisConfigs,
    required List<SeriesAxisBinding> bindings,
    required Map<String, List<double>> seriesYValues,
    String defaultAxisId = 'primary',
  }) {
    final result = <String, DataRange>{};

    // Create a map from series ID to axis ID for quick lookup
    final seriesAxisMap = <String, String>{};
    for (final binding in bindings) {
      seriesAxisMap[binding.seriesId] = binding.yAxisId;
    }

    // Process each axis configuration
    for (final axisConfig in axisConfigs) {
      final axisId = axisConfig.id;

      // Collect all Y values for series bound to this axis
      final allYValues = <double>[];

      for (final entry in seriesYValues.entries) {
        final seriesId = entry.key;
        final yValues = entry.value;

        // Determine which axis this series is bound to
        final boundAxisId = seriesAxisMap[seriesId] ?? defaultAxisId;

        // If this series is bound to the current axis, add its values
        if (boundAxisId == axisId && yValues.isNotEmpty) {
          allYValues.addAll(yValues);
        }
      }

      // Compute bounds based on explicit config or data
      double computedMin;
      double computedMax;

      if (allYValues.isEmpty) {
        // No data - use explicit bounds or defaults
        computedMin = axisConfig.min ?? 0.0;
        computedMax = axisConfig.max ?? 1.0;
      } else {
        // Compute from data, respecting explicit bounds
        final dataMin = allYValues.reduce((a, b) => a < b ? a : b);
        final dataMax = allYValues.reduce((a, b) => a > b ? a : b);

        computedMin = axisConfig.min ?? dataMin;
        computedMax = axisConfig.max ?? dataMax;
      }

      result[axisId] = DataRange(min: computedMin, max: computedMax);
    }

    return result;
  }
}
