// Copyright (c) 2025, Braven.
// All rights reserved.
// Licensed under the MIT license. See LICENSE file for details.

import 'dart:ui';

import '../axis/axis_bounds_calculator.dart';
import '../axis/y_axis_config.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';

/// Builds tooltip content for multi-axis charts.
///
/// Handles formatting of original Y-values (not normalized) with optional
/// unit suffixes from series configuration.
///
/// ## Usage
///
/// ```dart
/// // Build tooltip for a data point
/// final tooltip = TooltipBuilder.buildMarkerTooltip(
///   seriesName: 'Power Output',
///   dataPoint: ChartDataPoint(x: 5, y: 250),
///   series: powerSeries, // Has unit: 'W'
/// );
/// // Result: "Power Output\nX: 5\nY: 250 W"
///
/// // Build tooltip with axis bounds for denormalization
/// final tooltip = TooltipBuilder.buildMarkerTooltipWithBounds(
///   seriesName: 'Heart Rate',
///   dataPoint: ChartDataPoint(x: 5, y: 0.75), // normalized
///   series: heartRateSeries, // Has unit: 'bpm'
///   axisBounds: AxisBounds(min: 60, max: 180),
/// );
/// // Denormalizes 0.75 → 150, Result: "Heart Rate\nX: 5\nY: 150 bpm"
/// ```
class TooltipBuilder {
  /// Private constructor - use static methods.
  const TooltipBuilder._();

  /// Builds tooltip text for a marker (data point).
  ///
  /// [seriesName] The name of the series (e.g., "Power Output").
  /// [dataPoint] The data point being displayed.
  /// [series] Optional series to get unit from.
  /// [unit] Optional explicit unit override (takes precedence over series.unit).
  ///
  /// Returns formatted tooltip string with optional unit suffix.
  static String buildMarkerTooltip({
    required String seriesName,
    required ChartDataPoint dataPoint,
    ChartSeries? series,
    String? unit,
  }) {
    final effectiveUnit = unit ?? series?.unit;
    final xValue = formatValue(dataPoint.x);
    final yValue = formatValueWithUnit(dataPoint.y, effectiveUnit);

    return '$seriesName\nX: $xValue\nY: $yValue';
  }

  /// Builds tooltip text with denormalization support.
  ///
  /// Use this when displaying tooltips in multi-axis mode where Y values
  /// may be normalized to 0-1 range.
  ///
  /// [seriesName] The name of the series.
  /// [dataPoint] The data point (Y may be normalized).
  /// [axisBounds] The axis bounds for denormalization.
  /// [series] Optional series to get unit from.
  /// [unit] Optional explicit unit override.
  /// [isNormalized] Whether the Y value needs denormalization (default: true).
  ///
  /// Returns formatted tooltip with original Y value and unit.
  static String buildMarkerTooltipWithBounds({
    required String seriesName,
    required ChartDataPoint dataPoint,
    required AxisBounds axisBounds,
    ChartSeries? series,
    String? unit,
    bool isNormalized = true,
  }) {
    final effectiveUnit = unit ?? series?.unit;
    final xValue = formatValue(dataPoint.x);

    // Denormalize Y if needed
    final originalY = isNormalized ? denormalizeY(dataPoint.y, axisBounds.min, axisBounds.max) : dataPoint.y;

    final yValue = formatValueWithUnit(originalY, effectiveUnit);

    return '$seriesName\nX: $xValue\nY: $yValue';
  }

  /// Builds a multi-line tooltip for tracking mode (crosshair).
  ///
  /// [seriesValues] List of (seriesName, yValue, unit, color) tuples.
  /// [dataX] The X value at the crosshair position.
  ///
  /// Returns list of (label, color) pairs for rendering.
  static List<TooltipLine> buildTrackingTooltip({
    required List<SeriesTrackingValue> seriesValues,
    double? dataX,
  }) {
    return seriesValues.map((value) {
      final displayY = formatValueWithUnit(value.y, value.unit);
      return TooltipLine(
        text: '${value.seriesName}: $displayY',
        color: value.color,
      );
    }).toList();
  }

  /// Formats a numeric value for display.
  ///
  /// Uses smart formatting:
  /// - Integers shown without decimals
  /// - Small values use exponential notation
  /// - Medium values use appropriate decimal places
  static String formatValue(double value) {
    // If very close to an integer, show as integer
    if ((value - value.round()).abs() < 0.0001) {
      return value.round().toString();
    }

    // Use exponential for very small values
    if (value.abs() < 0.01 && value != 0) {
      return value.toStringAsExponential(1);
    }

    // Appropriate decimal places based on magnitude
    if (value.abs() < 1) {
      return value.toStringAsFixed(2);
    } else if (value.abs() < 100) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(0);
    }
  }

  /// Formats a value with an optional unit suffix.
  static String formatValueWithUnit(double value, String? unit) {
    final formatted = formatValue(value);
    if (unit != null && unit.isNotEmpty) {
      return '$formatted $unit';
    }
    return formatted;
  }

  /// Denormalizes a Y value from 0-1 range back to original scale.
  ///
  /// [normalizedY] Value in 0-1 range.
  /// [min] Minimum of original scale.
  /// [max] Maximum of original scale.
  ///
  /// Returns value in original scale.
  static double denormalizeY(double normalizedY, double min, double max) {
    return min + normalizedY * (max - min);
  }

  /// Formats axis bounds for display (e.g., in debug tooltips).
  static String formatAxisBounds(AxisBounds bounds, {String? unit}) {
    final min = formatValueWithUnit(bounds.min, unit);
    final max = formatValueWithUnit(bounds.max, unit);
    return '$min - $max';
  }
}

/// A single line in a tracking tooltip.
class TooltipLine {
  /// Creates a tooltip line.
  const TooltipLine({
    required this.text,
    required this.color,
  });

  /// The text to display.
  final String text;

  /// The color for the series indicator.
  final Color color;
}

/// Value information for a series at a tracking position.
class SeriesTrackingValue {
  /// Creates a series tracking value.
  const SeriesTrackingValue({
    required this.seriesName,
    required this.y,
    required this.color,
    this.unit,
    this.yAxisId,
  });

  /// The series name.
  final String seriesName;

  /// The Y value (original, not normalized).
  final double y;

  /// The series color.
  final Color color;

  /// Optional unit suffix.
  final String? unit;

  /// Optional Y-axis binding.
  final String? yAxisId;
}

/// Extension on YAxisConfig for tooltip-related functionality.
extension YAxisConfigTooltipExtension on YAxisConfig {
  /// Gets the display name for this axis in tooltips.
  String get displayName => label ?? id;
}
