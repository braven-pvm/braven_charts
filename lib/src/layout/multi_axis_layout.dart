// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../models/data_range.dart';
import '../models/y_axis_config.dart';
import '../models/y_axis_position.dart';

/// Computes axis widths based on content requirements.
///
/// This delegate measures the text width needed for tick labels
/// and determines appropriate axis widths within the configured bounds.
///
/// Width computation considers:
/// - Maximum tick label width based on [DataRange] values
/// - Unit suffix width if specified in [YAxisConfig]
/// - Tick mark width
/// - Constrained by [YAxisConfig.minWidth] and [YAxisConfig.maxWidth]
///
/// Example:
/// ```dart
/// const delegate = MultiAxisLayoutDelegate();
/// final widths = delegate.computeAxisWidths(
///   axes: [axis1, axis2],
///   axisBounds: {'axis1': bounds1, 'axis2': bounds2},
///   labelStyle: TextStyle(fontSize: 12),
/// );
/// ```
class MultiAxisLayoutDelegate {
  /// Creates a layout delegate for computing axis widths.
  const MultiAxisLayoutDelegate();

  /// Default tick mark length in logical pixels.
  static const double tickMarkWidth = 6.0;

  /// Default padding between axis elements (used when not overridden by axis config).
  static const double axisPadding = 4.0;

  /// Computes the required width for each axis.
  ///
  /// Returns a map from axis ID to computed width.
  ///
  /// Width is determined by:
  /// - Maximum tick label width (based on [DataRange] values)
  /// - Unit suffix width if specified
  /// - Tick mark width when ticks are shown
  /// - Constrained by [YAxisConfig.minWidth] and [YAxisConfig.maxWidth]
  ///
  /// Parameters:
  /// - [axes]: List of Y-axis configurations
  /// - [axisBounds]: Map from axis ID to [DataRange] for computing label widths
  /// - [labelStyle]: Text style used for measuring label widths
  Map<String, double> computeAxisWidths({
    required List<YAxisConfig> axes,
    required Map<String, DataRange> axisBounds,
    required TextStyle labelStyle,
  }) {
    final result = <String, double>{};

    for (final axis in axes) {
      final bounds = axisBounds[axis.id];
      double computedWidth = 0.0;

      if (bounds != null) {
        // Generate representative tick values (nice round numbers) for width measurement.
        // This ensures we measure what will actually be displayed, not raw bounds.
        final representativeTicks = _generateRepresentativeTicks(bounds.min, bounds.max);

        double maxLabelWidth = 0.0;
        for (final tickValue in representativeTicks) {
          final label = _formatValue(tickValue, axis);
          final width = _measureTextWidth(label, labelStyle);
          if (width > maxLabelWidth) {
            maxLabelWidth = width;
          }
        }

        computedWidth = maxLabelWidth;
      }

      // Add tick mark width (always included)
      computedWidth += tickMarkWidth;

      // Add tick label padding (gap between tick marks and tick labels)
      computedWidth += axis.tickLabelPadding;

      // Add axis margin for spacing from outer edge
      computedWidth += axis.axisMargin;

      // Add space for axis label (title) if shown
      if (axis.shouldShowAxisLabel && axis.label != null) {
        // The axis label is rotated 90°, so we need space for its height
        // (which becomes width when rotated). Measure actual text height.
        final axisLabelHeight = _measureAxisLabelHeight(axis);
        // axisLabelPadding provides gap between label and tick labels
        computedWidth += axisLabelHeight + axis.axisLabelPadding;
      }

      // Clamp to configured min/max
      computedWidth = computedWidth.clamp(axis.minWidth, axis.maxWidth);

      result[axis.id] = computedWidth;
    }

    return result;
  }

  /// Gets total width of left-side axes (leftOuter + left).
  ///
  /// Parameters:
  /// - [axes]: List of all Y-axis configurations
  /// - [widths]: Map from axis ID to computed width
  ///
  /// Returns the sum of widths for axes at [YAxisPosition.leftOuter]
  /// and [YAxisPosition.left] positions. Invisible axes are excluded.
  double getTotalLeftWidth(
    List<YAxisConfig> axes,
    Map<String, double> widths,
  ) {
    var total = 0.0;

    for (final axis in axes) {
      // Skip invisible axes - they should not contribute to layout width
      if (!axis.visible) continue;

      if (axis.position == YAxisPosition.leftOuter || axis.position == YAxisPosition.left) {
        total += widths[axis.id] ?? 0.0;
      }
    }

    return total;
  }

  /// Gets total width of right-side axes (right + rightOuter).
  ///
  /// Parameters:
  /// - [axes]: List of all Y-axis configurations
  /// - [widths]: Map from axis ID to computed width
  ///
  /// Returns the sum of widths for axes at [YAxisPosition.right]
  /// and [YAxisPosition.rightOuter] positions. Invisible axes are excluded.
  double getTotalRightWidth(
    List<YAxisConfig> axes,
    Map<String, double> widths,
  ) {
    var total = 0.0;

    for (final axis in axes) {
      // Skip invisible axes - they should not contribute to layout width
      if (!axis.visible) continue;

      if (axis.position == YAxisPosition.right || axis.position == YAxisPosition.rightOuter) {
        total += widths[axis.id] ?? 0.0;
      }
    }

    return total;
  }

  /// Formats a numeric value for width measurement.
  ///
  /// Uses the same formatting logic as MultiAxisPainter.formatTickLabel()
  /// to ensure consistent width calculations.
  /// Respects [YAxisConfig.shouldShowTickUnit] to determine if unit suffix
  /// should be included in the formatted string.
  String _formatValue(double value, YAxisConfig axis) {
    if (axis.labelFormatter != null) {
      return axis.labelFormatter!(value);
    }

    String formatted;
    if (value == value.roundToDouble()) {
      formatted = value.toInt().toString();
    } else if (value.abs() < 1) {
      // Small decimals - show more precision (matches painter)
      formatted = value.toStringAsFixed(2);
    } else if (value.abs() < 100) {
      // Medium values - show one decimal if needed (matches painter)
      final rounded = _roundToDecimals(value, 1);
      if (rounded == rounded.roundToDouble()) {
        formatted = rounded.toInt().toString();
      } else {
        formatted = rounded.toStringAsFixed(1);
      }
    } else {
      // Large values - show as integer (matches painter)
      formatted = value.round().toString();
    }

    // Only append unit if shouldShowTickUnit is true
    if (axis.shouldShowTickUnit && axis.unit != null) {
      formatted = '$formatted ${axis.unit}';
    }

    return formatted;
  }

  /// Generates representative tick values for width measurement.
  ///
  /// These are "nice" round numbers that match what the painter will
  /// actually display, ensuring accurate width calculations.
  List<double> _generateRepresentativeTicks(double minValue, double maxValue) {
    final range = maxValue - minValue;
    if (range <= 0) return [minValue];

    // Compute a nice tick spacing (same algorithm as MultiAxisPainter)
    final roughTickSpacing = range / 5; // Aim for ~5 ticks
    final niceSpacing = _niceNum(roughTickSpacing, round: true);

    // Round min down and max up to nice values
    final niceMin = (minValue / niceSpacing).floor() * niceSpacing;
    final niceMax = (maxValue / niceSpacing).ceil() * niceSpacing;

    // Generate tick values
    final ticks = <double>[];
    var tick = niceMin;
    while (tick <= niceMax + niceSpacing * 0.5) {
      ticks.add(tick);
      tick += niceSpacing;
      if (ticks.length > 20) break; // Safety limit
    }

    // Always include at least the extremes if no ticks generated
    if (ticks.isEmpty) {
      ticks.add(minValue);
      ticks.add(maxValue);
    }

    return ticks;
  }

  /// Returns a "nice" number that is approximately equal to range.
  ///
  /// A "nice" number is either 1, 2, or 5 times a power of 10.
  /// If [round] is true, rounds to nearest nice number; otherwise rounds up.
  double _niceNum(double range, {bool round = true}) {
    if (range == 0) return 0;

    final exponent = (math.log(range.abs()) / math.ln10).floor();
    final fraction = range / math.pow(10, exponent);

    double niceFraction;
    if (round) {
      if (fraction < 1.5) {
        niceFraction = 1;
      } else if (fraction < 3) {
        niceFraction = 2;
      } else if (fraction < 7) {
        niceFraction = 5;
      } else {
        niceFraction = 10;
      }
    } else {
      if (fraction <= 1) {
        niceFraction = 1;
      } else if (fraction <= 2) {
        niceFraction = 2;
      } else if (fraction <= 5) {
        niceFraction = 5;
      } else {
        niceFraction = 10;
      }
    }

    return niceFraction * math.pow(10, exponent);
  }

  /// Rounds a value to the specified number of decimal places.
  double _roundToDecimals(double value, int decimals) {
    final multiplier = _pow10(decimals);
    return (value * multiplier).round() / multiplier;
  }

  /// Returns 10^n for positive n.
  double _pow10(int n) {
    var result = 1.0;
    for (var i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }

  /// Measures the width of text using TextPainter.
  double _measureTextWidth(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    return textPainter.width;
  }

  /// Measures the height of the axis label text.
  ///
  /// This matches the style used in MultiAxisPainter._paintAxisLabel()
  /// to ensure layout and painting use the same dimensions.
  double _measureAxisLabelHeight(YAxisConfig axis) {
    // Build label text with optional unit suffix (same logic as painter)
    String labelText = axis.label ?? '';
    if (axis.shouldAppendUnitToLabel && axis.unit != null && axis.unit!.isNotEmpty) {
      labelText = '$labelText (${axis.unit})';
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    return textPainter.height;
  }
}
