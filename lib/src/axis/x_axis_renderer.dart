// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Axis System

import 'dart:ui';

import 'package:flutter/material.dart'
    show TextPainter, TextSpan, TextDirection;

import '../models/chart_theme.dart';
import '../models/enums.dart';
import 'axis.dart';

/// Renders the X-axis on the canvas.
///
/// **Purpose**: Paint X-axis line, tick marks, tick labels, and axis label.
///
/// **Usage**:
/// ```dart
/// final renderer = XAxisRenderer(axis, theme: chartTheme);
/// renderer.paint(canvas, chartSize, plotArea);
/// ```
///
/// **Note**: Grid lines are now rendered by GridRenderer (Task 6).
/// Y-axes are rendered by MultiAxisPainter.
class XAxisRenderer {
  XAxisRenderer(this.axis, {this.theme});
  final Axis axis;
  final ChartTheme? theme;

  /// Paints the X-axis on the canvas.
  ///
  /// [canvas] is the canvas to draw on.
  /// [chartSize] is the total size of the chart widget.
  /// [plotArea] is the rectangle where chart elements are rendered.
  void paint(Canvas canvas, Size chartSize, Rect plotArea) {
    _paintHorizontalAxis(canvas, chartSize, plotArea);
  }

  /// Paints a horizontal axis (X-axis).
  void _paintHorizontalAxis(Canvas canvas, Size chartSize, Rect plotArea) {
    final config = axis.config;
    final scale = axis.scale;
    final ticks = axis.ticks;

    // Determine Y position of axis
    final axisY =
        config.position == AxisPosition.bottom ? plotArea.bottom : plotArea.top;

    // Draw axis line
    if (config.showAxisLine) {
      final axisStyle = theme?.axisStyle;
      canvas.drawLine(
        Offset(plotArea.left, axisY),
        Offset(plotArea.right, axisY),
        Paint()
          ..color = axisStyle?.lineColor ?? config.axisColor
          ..strokeWidth = axisStyle?.lineWidth ?? 1,
      );
    }

    // Draw ticks and labels
    for (final tick in ticks) {
      final x = scale.dataToPixel(tick.value);

      // Skip if outside plot area
      if (x < plotArea.left || x > plotArea.right) continue;

      // Draw tick mark (only if axis line is also visible)
      if (config.showTickMarks && config.showAxisLine) {
        final axisStyle = theme?.axisStyle;
        final tickY1 = config.position == AxisPosition.bottom
            ? axisY
            : axisY - config.tickLength;
        final tickY2 = config.position == AxisPosition.bottom
            ? axisY + config.tickLength
            : axisY;

        canvas.drawLine(
          Offset(x, tickY1),
          Offset(x, tickY2),
          Paint()
            ..color = axisStyle?.tickColor ?? config.axisColor
            ..strokeWidth = axisStyle?.tickWidth ?? 1,
        );
      }

      // Draw tick label (only if axis is visible)
      if (config.showAxisLine) {
        // Use cached TextPainter from tick (avoids layout() every frame)
        final textPainter = tick.getTextPainter(config.tickLabelStyle);

        final labelY = config.position == AxisPosition.bottom
            ? axisY + config.tickLength + config.labelPadding
            : axisY -
                config.tickLength -
                config.labelPadding -
                textPainter.height;

        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, labelY),
        );
      }
    }

    // Draw axis label
    if (config.label.isNotEmpty) {
      final labelPainter = TextPainter(
        text: TextSpan(text: config.label, style: config.labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      // Position label between tick labels and scrollbar
      // For bottom axis: place after tick labels with spacing
      // For top axis: place above at top of chart
      final labelY = config.position == AxisPosition.bottom
          ? axisY +
              config.tickLength +
              config.labelPadding +
              20 // Between tick labels and scrollbar
          : 12.0; // Top of chart

      labelPainter.paint(
        canvas,
        Offset(
          plotArea.left + (plotArea.width - labelPainter.width) / 2,
          labelY,
        ),
      );
    }
  }
}
