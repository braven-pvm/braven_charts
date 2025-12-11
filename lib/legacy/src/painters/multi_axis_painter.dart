// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// CustomPainter for rendering multiple Y-axes on a chart.
///
/// Renders Y-axes at positions defined by [YAxisConfig], with support for:
/// - Four axis positions (leftOuter, left, right, rightOuter)
/// - Per-axis colors for visual identification
/// - Tick marks with formatted labels
/// - Optional axis labels and unit suffixes
///
/// Example:
/// ```dart
/// final painter = MultiAxisPainter(
///   axes: [
///     YAxisConfig(id: 'power', position: YAxisPosition.left, color: Colors.blue),
///     YAxisConfig(id: 'hr', position: YAxisPosition.right, color: Colors.red),
///   ],
///   chartRect: Rect.fromLTWH(60, 10, 300, 200),
/// );
/// ```
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../axis/y_axis_config.dart';
import '../axis/y_axis_position.dart';

/// CustomPainter that renders multiple Y-axes with independent configurations.
///
/// Each axis is positioned according to its [YAxisConfig.position] and
/// rendered with its configured color, tick marks, and labels.
class MultiAxisPainter extends CustomPainter {
  /// Creates a multi-axis painter.
  ///
  /// - [axes]: List of Y-axis configurations to render
  /// - [chartRect]: The rectangle defining the chart content area
  /// - [defaultColor]: Fallback color for axes without explicit colors
  /// - [tickCount]: Target number of tick marks per axis (default: 5)
  /// - [axisWidth]: Width reserved for each axis (default: 50)
  /// - [tickLength]: Length of tick marks in pixels (default: 6)
  const MultiAxisPainter({
    required this.axes,
    required this.chartRect,
    this.defaultColor = const Color(0xFF666666),
    this.tickCount = 5,
    this.axisWidth = 50.0,
    this.tickLength = 6.0,
  });

  /// List of Y-axis configurations to render.
  final List<YAxisConfig> axes;

  /// The rectangle defining the chart content area.
  ///
  /// Axes are positioned relative to this rect:
  /// - Left axes are to the left of chartRect.left
  /// - Right axes are to the right of chartRect.right
  final Rect chartRect;

  /// Default color for axes that don't specify a color.
  final Color defaultColor;

  /// Target number of tick marks per axis.
  final int tickCount;

  /// Width reserved for each axis (includes ticks and labels).
  final double axisWidth;

  /// Length of tick marks in pixels.
  final double tickLength;

  @override
  void paint(Canvas canvas, Size size) {
    if (axes.isEmpty) return;

    for (final axis in axes) {
      _paintAxis(canvas, axis);
    }
  }

  /// Paints a single Y-axis.
  void _paintAxis(Canvas canvas, YAxisConfig axis) {
    final color = getAxisColor(axis);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final x = getAxisX(axis.position);
    final top = chartRect.top;
    final bottom = chartRect.bottom;

    // Draw axis line
    canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);

    // Draw ticks and labels
    final ticks = getTickValues(axis);
    final isLeftSide = axis.position == YAxisPosition.left ||
        axis.position == YAxisPosition.leftOuter;

    for (final tickValue in ticks) {
      final normalizedY = _normalizeValue(tickValue, axis);
      final y = bottom - (normalizedY * chartRect.height);

      // Draw tick mark
      final tickStart = isLeftSide ? x : x;
      final tickEnd = isLeftSide ? x - tickLength : x + tickLength;
      canvas.drawLine(Offset(tickStart, y), Offset(tickEnd, y), paint);

      // Draw label
      final label = formatTickLabel(tickValue, axis);
      _paintLabel(canvas, label, x, y, isLeftSide, color);
    }

    // Draw axis label (title) if provided
    if (axis.label != null) {
      _paintAxisLabel(canvas, axis.label!, x, isLeftSide, color);
    }
  }

  /// Paints a tick label at the specified position.
  void _paintLabel(
    Canvas canvas,
    String label,
    double axisX,
    double y,
    bool isLeftSide,
    Color color,
  ) {
    final textStyle = TextStyle(
      color: color,
      fontSize: 10,
    );
    final textSpan = TextSpan(text: label, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final offsetX = isLeftSide
        ? axisX - tickLength - textPainter.width - 4
        : axisX + tickLength + 4;
    final offsetY = y - textPainter.height / 2;

    textPainter.paint(canvas, Offset(offsetX, offsetY));
  }

  /// Paints the axis title label rotated 90 degrees.
  void _paintAxisLabel(
    Canvas canvas,
    String label,
    double axisX,
    bool isLeftSide,
    Color color,
  ) {
    final textStyle = TextStyle(
      color: color,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );
    final textSpan = TextSpan(text: label, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    canvas.save();

    // Position at the center of the axis
    final centerY = chartRect.top + chartRect.height / 2;
    final offsetX =
        isLeftSide ? axisX - axisWidth + 12 : axisX + axisWidth - 12;

    canvas.translate(offsetX, centerY);
    canvas.rotate(isLeftSide ? -math.pi / 2 : math.pi / 2);
    canvas.translate(-textPainter.width / 2, -textPainter.height / 2);

    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  /// Returns the X coordinate for an axis at the given position.
  double getAxisX(YAxisPosition position) {
    switch (position) {
      case YAxisPosition.leftOuter:
        return chartRect.left - axisWidth - axisWidth / 2;
      case YAxisPosition.left:
        return chartRect.left - axisWidth / 2;
      case YAxisPosition.right:
        return chartRect.right + axisWidth / 2;
      case YAxisPosition.rightOuter:
        return chartRect.right + axisWidth + axisWidth / 2;
    }
  }

  /// Returns the color for an axis, using the configured color or default.
  Color getAxisColor(YAxisConfig axis) {
    return axis.color ?? defaultColor;
  }

  /// Generates tick values for an axis.
  ///
  /// Uses the axis's minValue/maxValue if provided, otherwise defaults
  /// to 0-100 range for demonstration purposes.
  List<double> getTickValues(YAxisConfig axis) {
    final minValue = axis.minValue ?? 0;
    final maxValue = axis.maxValue ?? 100;

    if (maxValue <= minValue) {
      return [minValue];
    }

    final range = maxValue - minValue;
    final interval = _calculateNiceInterval(range, tickCount);
    final ticks = <double>[];

    // Start at a nice round number at or below minValue
    var current = (minValue / interval).floor() * interval;
    if (current < minValue) {
      current += interval;
    }

    while (current <= maxValue) {
      ticks.add(current);
      current += interval;
    }

    // Ensure we have at least min and max
    if (ticks.isEmpty) {
      ticks.add(minValue);
      ticks.add(maxValue);
    }

    return ticks;
  }

  /// Calculates a "nice" interval for tick marks.
  double _calculateNiceInterval(double range, int targetTicks) {
    if (range <= 0 || targetTicks <= 0) return 1;

    final rawInterval = range / targetTicks;
    final magnitude = math.pow(10, (math.log(rawInterval) / math.ln10).floor());
    final normalized = rawInterval / magnitude;

    double niceNormalized;
    if (normalized <= 1) {
      niceNormalized = 1;
    } else if (normalized <= 2) {
      niceNormalized = 2;
    } else if (normalized <= 5) {
      niceNormalized = 5;
    } else {
      niceNormalized = 10;
    }

    return niceNormalized * magnitude;
  }

  /// Normalizes a value to the 0.0-1.0 range based on axis bounds.
  double _normalizeValue(double value, YAxisConfig axis) {
    final minValue = axis.minValue ?? 0;
    final maxValue = axis.maxValue ?? 100;
    final range = maxValue - minValue;

    if (range == 0) return 0.5;
    return (value - minValue) / range;
  }

  /// Formats a tick value with optional unit suffix.
  String formatTickLabel(double value, YAxisConfig axis) {
    // Format the number (remove unnecessary decimals)
    String formatted;
    if (value == value.roundToDouble()) {
      formatted = value.round().toString();
    } else if (value.abs() < 10) {
      formatted = value.toStringAsFixed(1);
    } else {
      formatted = value.round().toString();
    }

    // Append unit suffix if provided
    if (axis.unitSuffix != null) {
      formatted += axis.unitSuffix!;
    }

    return formatted;
  }

  @override
  bool shouldRepaint(covariant MultiAxisPainter oldDelegate) {
    // Check if axes list changed
    if (axes.length != oldDelegate.axes.length) return true;

    for (var i = 0; i < axes.length; i++) {
      if (axes[i] != oldDelegate.axes[i]) return true;
    }

    // Check if chartRect changed
    if (chartRect != oldDelegate.chartRect) return true;

    // Check other properties
    if (defaultColor != oldDelegate.defaultColor) return true;
    if (tickCount != oldDelegate.tickCount) return true;
    if (axisWidth != oldDelegate.axisWidth) return true;
    if (tickLength != oldDelegate.tickLength) return true;

    return false;
  }

  @override
  String toString() {
    return 'MultiAxisPainter(axes: ${axes.length}, chartRect: $chartRect)';
  }
}
