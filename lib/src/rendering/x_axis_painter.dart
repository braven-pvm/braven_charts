// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:ui'
    show Canvas, Color, Offset, Paint, PaintingStyle, Rect, TextDirection;

import 'package:flutter/painting.dart'
    show FontWeight, TextPainter, TextSpan, TextStyle;

import '../models/chart_series.dart';
import '../models/data_range.dart';
import '../models/x_axis_config.dart';

/// Paints the X-axis with tick marks and labels.
///
/// This painter handles the visual rendering of the horizontal X-axis.
/// It displays tick marks and labels, using the configuration provided
/// via [XAxisConfig].
///
/// Example:
/// ```dart
/// final painter = XAxisPainter(
///   config: xAxisConfig,
///   axisBounds: DataRange(min: 0.0, max: 100.0),
///   labelStyle: TextStyle(fontSize: 12),
/// );
/// painter.paint(canvas, chartArea, plotArea);
/// ```
class XAxisPainter {
  /// Creates an X-axis painter.
  ///
  /// [config] is the X-axis configuration.
  /// [axisBounds] is the data range for the X-axis.
  /// [labelStyle] is the text style for tick labels.
  /// [series] is optional list of data series for color resolution.
  XAxisPainter({
    required this.config,
    required this.axisBounds,
    required this.labelStyle,
    this.series,
  });

  /// X-axis configuration.
  final XAxisConfig config;

  /// Data range for the X-axis.
  final DataRange axisBounds;

  /// Text style for tick labels.
  final TextStyle labelStyle;

  /// Optional list of data series for color resolution.
  final List<ChartSeries>? series;

  /// Paints the X-axis on the canvas.
  ///
  /// [canvas] is the canvas to draw on.
  /// [chartArea] is the total chart area.
  /// [plotArea] is the data rendering area (axis aligns to this).
  void paint(Canvas canvas, Rect chartArea, Rect plotArea) {
    // Early return if not visible
    if (!config.visible) {
      return;
    }

    final axisColor = resolveAxisColor();
    final paint = Paint()
      ..color = axisColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw axis line at bottom of plot area
    if (config.showAxisLine) {
      canvas.drawLine(
        Offset(plotArea.left, plotArea.bottom),
        Offset(plotArea.right, plotArea.bottom),
        paint,
      );
    }

    // Generate ticks and draw them
    final ticks = generateTicks(axisBounds);

    for (final tickValue in ticks) {
      // Calculate X position for this tick
      final ratio = axisBounds.span == 0
          ? 0.0
          : (tickValue - axisBounds.min) / axisBounds.span;
      final x = plotArea.left + ratio * plotArea.width;

      // Draw tick mark
      if (config.showTicks) {
        const tickLength = 6.0;
        canvas.drawLine(
          Offset(x, plotArea.bottom),
          Offset(x, plotArea.bottom + tickLength),
          paint,
        );
      }

      // Draw tick label
      final label = formatTickLabel(tickValue);
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: labelStyle.copyWith(color: axisColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      const tickLength = 6.0;
      textPainter.paint(
        canvas,
        Offset(
          x - textPainter.width / 2,
          plotArea.bottom + tickLength + config.tickLabelPadding,
        ),
      );
    }

    // Draw axis label if configured
    if (config.shouldShowAxisLabel && config.label != null) {
      final axisLabelText =
          config.shouldAppendUnitToLabel && config.unit != null
              ? '${config.label} (${config.unit})'
              : config.label!;

      final axisLabelPainter = TextPainter(
        text: TextSpan(
          text: axisLabelText,
          style: labelStyle.copyWith(
            color: axisColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Position the axis label centered below the tick labels
      const tickLength = 6.0;
      // Estimate tick label height (approximately fontSize * 1.2)
      final tickLabelHeight = labelStyle.fontSize ?? 12.0 * 1.2;
      final axisLabelY = plotArea.bottom +
          tickLength +
          config.tickLabelPadding +
          tickLabelHeight +
          config.axisLabelPadding;

      axisLabelPainter.paint(
        canvas,
        Offset(
          plotArea.left + (plotArea.width - axisLabelPainter.width) / 2,
          axisLabelY,
        ),
      );
    }
  }

  /// Generates tick values for the axis.
  ///
  /// [bounds] is the data range for tick generation.
  /// [maxTicks] is the optional maximum number of ticks to generate.
  ///
  /// Returns a list of tick values within the bounds.
  List<double> generateTicks(DataRange bounds, {int? maxTicks}) {
    maxTicks ??= 10;

    if (bounds.span == 0) {
      return [bounds.min];
    }

    final range = bounds.span;
    final roughStep = range / (maxTicks - 1);
    final nicedStep = _niceNum(roughStep, round: true);

    final niceMin = (bounds.min / nicedStep).floor() * nicedStep;
    final niceMax = (bounds.max / nicedStep).ceil() * nicedStep;

    final ticks = <double>[];
    for (var tick = niceMin; tick <= niceMax; tick += nicedStep) {
      if (tick >= bounds.min && tick <= bounds.max) {
        ticks.add(_roundToDecimals(tick, 10));
      }
    }

    if (ticks.isEmpty) {
      ticks.add(bounds.min);
      if (bounds.min != bounds.max) {
        ticks.add(bounds.max);
      }
    }

    // If we exceeded maxTicks, thin out the results
    if (ticks.length > maxTicks) {
      final thinned = <double>[];
      final step = (ticks.length - 1) / (maxTicks - 1);

      // Include first tick
      thinned.add(ticks.first);

      // Include evenly spaced middle ticks
      for (var i = 1; i < maxTicks - 1; i++) {
        final index = (i * step).round();
        thinned.add(ticks[index]);
      }

      // Include last tick
      thinned.add(ticks.last);

      return thinned;
    }

    return ticks;
  }

  /// Formats a tick value for display.
  ///
  /// [value] is the tick value to format.
  ///
  /// Returns a formatted string representation of the value.
  String formatTickLabel(double value) {
    // Try custom formatter first
    if (config.labelFormatter != null) {
      try {
        return config.labelFormatter!(value);
      } catch (_) {
        // Fall through to default formatting
      }
    }

    // Default formatting
    String formatted;
    if (value == value.roundToDouble()) {
      formatted = value.toInt().toString();
    } else if (value.abs() < 1) {
      formatted = value.toStringAsFixed(2);
    } else if (value.abs() < 100) {
      final rounded = _roundToDecimals(value, 1);
      formatted = rounded == rounded.roundToDouble()
          ? rounded.toInt().toString()
          : rounded.toStringAsFixed(1);
    } else {
      formatted = value.round().toString();
    }

    // Append unit if configured
    if (config.shouldShowTickUnit &&
        config.unit != null &&
        config.unit!.isNotEmpty) {
      formatted = '$formatted ${config.unit}';
    }

    return formatted;
  }

  /// Resolves the color to use for the axis.
  ///
  /// Returns [config.color] if provided, otherwise returns a default axis color.
  Color resolveAxisColor() {
    // Priority 1: Explicit config color
    if (config.color != null) {
      return config.color!;
    }

    // Priority 2: First series color
    if (series != null && series!.isNotEmpty && series![0].color != null) {
      return series![0].color!;
    }

    // Priority 3: Default
    return const Color(0xFF333333);
  }

  /// Returns a "nice" number that is approximately equal to range.
  ///
  /// A "nice" number is either 1, 2, or 5 times a power of 10.
  /// If [round] is true, rounds to nearest nice number; otherwise rounds up.
  double _niceNum(double range, {bool round = true}) {
    final exponent = math.log(range) / math.ln10;
    final fraction = range / math.pow(10, exponent.floor());

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

    return niceFraction * math.pow(10, exponent.floor());
  }

  /// Rounds a value to the specified number of decimal places.
  double _roundToDecimals(double value, int decimals) {
    final factor = math.pow(10, decimals);
    return (value * factor).round() / factor;
  }
}
