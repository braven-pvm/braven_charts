// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

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
/// - Tick mark width when [YAxisConfig.showTicks] is true
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
        // Compute maximum label width from min and max values
        final minLabel = _formatValue(bounds.min, axis);
        final maxLabel = _formatValue(bounds.max, axis);

        final minWidth = _measureTextWidth(minLabel, labelStyle);
        final maxWidth = _measureTextWidth(maxLabel, labelStyle);

        computedWidth = minWidth > maxWidth ? minWidth : maxWidth;
      }

      // Add tick mark width if ticks are shown
      if (axis.showTicks) {
        computedWidth += tickMarkWidth;
      }

      // Add tick label padding (gap between tick marks and tick labels)
      computedWidth += axis.tickLabelPadding;

      // Add space for axis label (title) if shown
      if (axis.shouldShowAxisLabel && axis.label != null) {
        // The axis label is rotated 90°, so we need space for its height
        // (which becomes width when rotated). Estimate ~14px for 12pt font.
        const axisLabelHeight = 14.0;
        computedWidth += axisLabelHeight + axis.axisLabelPadding;
      }

      // Add axis margin for spacing between axes
      computedWidth += axis.axisMargin;

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
  /// and [YAxisPosition.left] positions.
  double getTotalLeftWidth(
    List<YAxisConfig> axes,
    Map<String, double> widths,
  ) {
    var total = 0.0;

    for (final axis in axes) {
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
  /// and [YAxisPosition.rightOuter] positions.
  double getTotalRightWidth(
    List<YAxisConfig> axes,
    Map<String, double> widths,
  ) {
    var total = 0.0;

    for (final axis in axes) {
      if (axis.position == YAxisPosition.right || axis.position == YAxisPosition.rightOuter) {
        total += widths[axis.id] ?? 0.0;
      }
    }

    return total;
  }

  /// Formats a numeric value for width measurement.
  ///
  /// Respects [YAxisConfig.shouldShowTickUnit] to determine if unit suffix
  /// should be included in the formatted string.
  String _formatValue(double value, YAxisConfig axis) {
    if (axis.labelFormatter != null) {
      return axis.labelFormatter!(value);
    }

    String formatted;
    if (value == value.roundToDouble()) {
      formatted = value.toInt().toString();
    } else {
      formatted = value.toStringAsFixed(2);
    }

    // Only append unit if shouldShowTickUnit is true
    if (axis.shouldShowTickUnit && axis.unit != null) {
      formatted = '$formatted ${axis.unit}';
    }

    return formatted;
  }

  /// Measures the width of text using TextPainter.
  double _measureTextWidth(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    return textPainter.width;
  }
}
