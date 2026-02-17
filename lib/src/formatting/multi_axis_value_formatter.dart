/// Multi-axis value formatting utilities.
///
/// Provides formatting for numeric values with optional unit suffixes,
/// optimized for chart display including tooltips and axis labels.
library;

import '../rendering/multi_axis_normalizer.dart';

/// Formats numeric values with optional units for chart display.
///
/// This is a utility class with static methods for formatting values
/// in charts, particularly for multi-axis scenarios where normalized
/// values need to be converted back to original values for display.
///
/// Key features:
/// - Automatic precision detection based on value magnitude
/// - Clean trailing zero removal
/// - Unit suffix support (e.g., "250 W", "120 bpm")
/// - Integration with [MultiAxisNormalizer] for denormalization
///
/// Example:
/// ```dart
/// // Format a value with unit
/// final text = MultiAxisValueFormatter.format(value: 250.0, unit: 'W');
/// // text == '250 W'
///
/// // Format a denormalized value
/// final text = MultiAxisValueFormatter.formatWithDenormalization(
///   normalizedValue: 0.5,
///   min: 0.0,
///   max: 500.0,
///   unit: 'W',
/// );
/// // text == '250 W'
/// ```
class MultiAxisValueFormatter {
  /// Private constructor - this is a utility class with static methods only.
  const MultiAxisValueFormatter._();

  /// Formats a value with optional unit suffix.
  ///
  /// The value is formatted with appropriate decimal precision (either
  /// auto-detected via [optimalPrecision] or explicitly specified).
  /// Trailing zeros are cleaned from the result.
  ///
  /// Parameters:
  /// - [value]: The numeric value to format
  /// - [unit]: Optional unit suffix (e.g., 'W', 'bpm', 'L')
  /// - [precision]: Optional explicit decimal precision (auto-detected if null)
  ///
  /// Returns a formatted string like "250 W" or "123.46".
  ///
  /// Example:
  /// ```dart
  /// format(value: 250.0, unit: 'W')      // '250 W'
  /// format(value: 123.456789)            // '123.46'
  /// format(value: -50.5, unit: 'W')      // '-50.5 W'
  /// format(value: 100.0, precision: 2)   // '100'
  /// ```
  static String format({required double value, String? unit, int? precision}) {
    final p = precision ?? optimalPrecision(value);
    final formatted = value.toStringAsFixed(p);
    final clean = _cleanTrailingZeros(formatted);

    // Treat empty string as null for unit
    if (unit != null && unit.isNotEmpty) {
      return '$clean $unit';
    }
    return clean;
  }

  /// Formats a value with fixed decimal places (preserves trailing zeros).
  ///
  /// Unlike [format], this method does NOT clean trailing zeros, ensuring
  /// consistent string width for labels that update dynamically (e.g.,
  /// crosshair Y-value labels). This prevents visual jitter from label resizing.
  ///
  /// Parameters:
  /// - [value]: The numeric value to format
  /// - [unit]: Optional unit suffix (e.g., 'W', 'bpm', 'L')
  /// - [precision]: Decimal precision (defaults to 2)
  ///
  /// Returns a formatted string like "250.00 W" or "123.46".
  ///
  /// Example:
  /// ```dart
  /// formatFixed(value: 250.0, unit: 'W')           // '250.00 W'
  /// formatFixed(value: 100.0, precision: 2)       // '100.00'
  /// formatFixed(value: 123.456, precision: 1)     // '123.5'
  /// ```
  static String formatFixed({
    required double value,
    String? unit,
    int precision = 2,
  }) {
    final formatted = value.toStringAsFixed(precision);

    // Treat empty string as null for unit
    if (unit != null && unit.isNotEmpty) {
      return '$formatted $unit';
    }
    return formatted;
  }

  /// Determines optimal decimal precision based on value magnitude.
  ///
  /// Uses the absolute value to determine precision:
  /// - Values >= 1000: 0 decimal places
  /// - Values >= 100: 2 decimal places
  /// - Values >= 10: 1 decimal place
  /// - Values >= 1: 2 decimal places
  /// - Values >= 0.1: 3 decimal places
  /// - Values < 0.1: 4 decimal places
  ///
  /// This ensures large values don't show unnecessary decimals while
  /// small values retain enough precision to be meaningful.
  ///
  /// Example:
  /// ```dart
  /// optimalPrecision(1234.5)   // 0
  /// optimalPrecision(123.456)  // 2
  /// optimalPrecision(50.5)     // 1
  /// optimalPrecision(5.5)      // 2
  /// optimalPrecision(0.5)      // 3
  /// optimalPrecision(0.00123)  // 4
  /// ```
  static int optimalPrecision(double value) {
    final abs = value.abs();
    if (abs >= 1000) return 0;
    if (abs >= 100) return 2;
    if (abs >= 10) return 1;
    if (abs >= 1) return 2;
    if (abs >= 0.1) return 3;
    return 4;
  }

  /// Denormalizes a 0-1 value and formats it with unit.
  ///
  /// Combines [MultiAxisNormalizer.denormalize] with [format] for
  /// convenient formatting of normalized chart values.
  ///
  /// Parameters:
  /// - [normalizedValue]: Value in 0-1 range (can be outside for clipped values)
  /// - [min]: Original data range minimum
  /// - [max]: Original data range maximum
  /// - [unit]: Optional unit suffix
  /// - [precision]: Optional explicit decimal precision
  ///
  /// Example:
  /// ```dart
  /// formatWithDenormalization(
  ///   normalizedValue: 0.5,
  ///   min: 0.0,
  ///   max: 500.0,
  ///   unit: 'W',
  /// )
  /// // Returns '250 W'
  /// ```
  static String formatWithDenormalization({
    required double normalizedValue,
    required double min,
    required double max,
    String? unit,
    int? precision,
  }) {
    final original = MultiAxisNormalizer.denormalize(normalizedValue, min, max);
    return format(value: original, unit: unit, precision: precision);
  }

  /// Removes trailing zeros and unnecessary decimal point from a string.
  ///
  /// Examples:
  /// - "10.500" → "10.5"
  /// - "100.00" → "100"
  /// - "100" → "100" (no change)
  static String _cleanTrailingZeros(String s) {
    if (!s.contains('.')) return s;

    var result = s;
    while (result.endsWith('0')) {
      result = result.substring(0, result.length - 1);
    }
    if (result.endsWith('.')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
