// Copyright 2025 Braven Charts - Multi-Axis Value Formatter
// SPDX-License-Identifier: MIT
//
// T042 [US4] Multi-axis value formatter implementation
// Formats values with units and appropriate precision for crosshair/tooltip display.

import 'dart:math' as math;

/// Formats numeric values for display in multi-axis charts.
///
/// Handles:
/// - Value formatting with units
/// - Automatic precision based on data range
/// - Decimal value rounding without over-precision
/// - Series value formatting for tooltips
///
/// Example:
/// ```dart
/// // Basic formatting
/// final text = MultiAxisValueFormatter.formatValue(
///   value: 165.0,
///   unit: 'bpm',
/// ); // "165 bpm"
///
/// // Range-based precision
/// final precise = MultiAxisValueFormatter.formatValueForRange(
///   value: 0.00234,
///   minValue: 0.001,
///   maxValue: 0.005,
///   unit: 'µV',
/// ); // "0.0023 µV"
/// ```
class MultiAxisValueFormatter {
  /// Private constructor - use static methods only
  MultiAxisValueFormatter._();

  /// Formats a numeric value with an optional unit.
  ///
  /// [value] - The numeric value to format
  /// [unit] - Optional unit suffix (e.g., 'W', 'bpm', '°C')
  /// [decimalPlaces] - Optional explicit decimal places (auto-detected if null)
  ///
  /// Returns formatted string like "240 W" or "2.3 L"
  static String formatValue({
    required double value,
    String? unit,
    int? decimalPlaces,
  }) {
    // Determine precision if not explicitly provided
    final precision = decimalPlaces ?? _autoPrecision(value);

    // Format the number
    final formattedNumber = _formatNumber(value, precision);

    // Append unit if provided and non-empty
    if (unit != null && unit.isNotEmpty) {
      return '$formattedNumber $unit';
    }

    return formattedNumber;
  }

  /// Formats a value with precision automatically determined from the data range.
  ///
  /// This is useful for crosshair/tooltip display where precision should
  /// be appropriate for the visible data range.
  ///
  /// [value] - The value to format
  /// [minValue] - Minimum value in the data range
  /// [maxValue] - Maximum value in the data range
  /// [unit] - Optional unit suffix
  static String formatValueForRange({
    required double value,
    required double minValue,
    required double maxValue,
    String? unit,
  }) {
    final range = (maxValue - minValue).abs();
    final precision = determinePrecision(range: range);

    return formatValue(
      value: value,
      unit: unit,
      decimalPlaces: precision,
    );
  }

  /// Determines appropriate decimal precision based on the data range.
  ///
  /// - Range > 100: 0 decimal places
  /// - Range 10-100: 1 decimal place
  /// - Range 1-10: 2 decimal places
  /// - Range < 1: Increase precision to show meaningful digits
  static int determinePrecision({required double range}) {
    if (range <= 0) return 2; // Handle zero/negative range

    if (range > 100) return 0;
    if (range > 10) return 1;
    if (range > 1) return 2;

    // For very small ranges, calculate needed precision
    // to show at least 2 significant digits in the range
    final log10Range = math.log(range) / math.ln10;
    return math.max(2, (-log10Range).ceil() + 1);
  }

  /// Formats a value with series name for tooltip display.
  ///
  /// Returns format: "Series Name: value unit"
  static String formatSeriesValue({
    required double value,
    required String seriesName,
    String? unit,
    int? decimalPlaces,
  }) {
    final formattedValue = formatValue(
      value: value,
      unit: unit,
      decimalPlaces: decimalPlaces,
    );

    return '$seriesName: $formattedValue';
  }

  /// Formats multiple series values for multi-line tooltip display.
  ///
  /// [seriesValues] - List of (name, value, unit) records
  ///
  /// Returns multi-line string with each series on its own line.
  static String formatMultipleSeriesValues({
    required List<({String name, double value, String unit})> seriesValues,
  }) {
    return seriesValues
        .map((sv) => formatSeriesValue(
              value: sv.value,
              seriesName: sv.name,
              unit: sv.unit,
            ))
        .join('\n');
  }

  /// Rounds a value to the specified number of significant figures.
  ///
  /// Example: roundToSignificantFigures(12345.6789, 3) → 12300
  static double roundToSignificantFigures(double value, int sigFigs) {
    if (value == 0) return 0;

    final sign = value.sign;
    final absValue = value.abs();

    // Calculate the magnitude (power of 10)
    final magnitude = (math.log(absValue) / math.ln10).floor();
    final scale = math.pow(10, magnitude - sigFigs + 1);

    return sign * (absValue / scale).round() * scale;
  }

  /// Automatically determines precision based on the value magnitude.
  static int _autoPrecision(double value) {
    final absValue = value.abs();

    if (absValue == 0) return 0;
    if (absValue >= 100) return 0;
    if (absValue >= 10) return 1;
    if (absValue >= 1) return 1;

    // For values < 1, show enough decimals
    final log10Value = math.log(absValue) / math.ln10;
    return math.max(1, (-log10Value).ceil() + 1);
  }

  /// Formats a number with the specified precision.
  static String _formatNumber(double value, int precision) {
    if (precision <= 0) {
      // Round to integer
      return value.round().toString();
    }

    // Format with specified decimal places
    final formatted = value.toStringAsFixed(precision);

    // Remove trailing zeros after decimal point
    if (formatted.contains('.')) {
      var result = formatted;
      while (result.endsWith('0')) {
        result = result.substring(0, result.length - 1);
      }
      if (result.endsWith('.')) {
        result = result.substring(0, result.length - 1);
      }
      return result;
    }

    return formatted;
  }
}
