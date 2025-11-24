// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Axis System

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart' show TextPainter, TextSpan, TextDirection;

import '../models/enums.dart';
import 'axis.dart';
import 'axis_config.dart';

/// Renders an axis on the canvas.
///
/// **Purpose**: Paint axis line, tick marks, tick labels, grid lines, and axis label.
///
/// **Usage**:
/// ```dart
/// final renderer = AxisRenderer(axis);
/// renderer.paint(canvas, chartSize, plotArea);
/// ```
class AxisRenderer {
  AxisRenderer(this.axis);
  final Axis axis;

  /// Paints the axis on the canvas.
  ///
  /// [canvas] is the canvas to draw on.
  /// [chartSize] is the total size of the chart widget.
  /// [plotArea] is the rectangle where chart elements are rendered.
  void paint(Canvas canvas, Size chartSize, Rect plotArea) {
    if (axis.config.orientation == AxisOrientation.horizontal) {
      _paintHorizontalAxis(canvas, chartSize, plotArea);
    } else {
      _paintVerticalAxis(canvas, chartSize, plotArea);
    }
  }

  /// Paints a horizontal axis (X-axis).
  void _paintHorizontalAxis(Canvas canvas, Size chartSize, Rect plotArea) {
    final config = axis.config;
    final scale = axis.scale;
    final ticks = axis.ticks;

    // Determine Y position of axis
    final axisY = config.position == AxisPosition.bottom ? plotArea.bottom : plotArea.top;

    // Draw axis line
    if (config.showAxisLine) {
      canvas.drawLine(
        Offset(plotArea.left, axisY),
        Offset(plotArea.right, axisY),
        Paint()
          ..color = config.axisColor
          ..strokeWidth = 1,
      );
    }

    // Draw ticks, labels, and grid
    for (final tick in ticks) {
      final x = scale.dataToPixel(tick.value);

      // Skip if outside plot area
      if (x < plotArea.left || x > plotArea.right) continue;

      // Draw grid line
      if (config.showGrid) {
        canvas.drawLine(
          Offset(x, plotArea.top),
          Offset(x, plotArea.bottom),
          Paint()
            ..color = config.gridColor
            ..strokeWidth = 0.5,
        );
      }

      // Draw tick mark
      if (config.showTickMarks) {
        final tickY1 = config.position == AxisPosition.bottom ? axisY : axisY - config.tickLength;
        final tickY2 = config.position == AxisPosition.bottom ? axisY + config.tickLength : axisY;

        canvas.drawLine(
          Offset(x, tickY1),
          Offset(x, tickY2),
          Paint()
            ..color = config.axisColor
            ..strokeWidth = 1,
        );
      }

      // Draw tick label (only if axis is visible)
      if (config.showAxisLine) {
        final textPainter = TextPainter(
          text: TextSpan(text: tick.label, style: config.tickLabelStyle),
          textDirection: TextDirection.ltr,
        )..layout();

        final labelY = config.position == AxisPosition.bottom
            ? axisY + config.tickLength + config.labelPadding
            : axisY - config.tickLength - config.labelPadding - textPainter.height;

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
          ? axisY + config.tickLength + config.labelPadding + 20 // Between tick labels and scrollbar
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

  /// Paints a vertical axis (Y-axis).
  void _paintVerticalAxis(Canvas canvas, Size chartSize, Rect plotArea) {
    final config = axis.config;
    final scale = axis.scale;
    final ticks = axis.ticks;

    // Determine X position of axis
    final axisX = config.position == AxisPosition.left ? plotArea.left : plotArea.right;

    // Draw axis line
    if (config.showAxisLine) {
      canvas.drawLine(
        Offset(axisX, plotArea.top),
        Offset(axisX, plotArea.bottom),
        Paint()
          ..color = config.axisColor
          ..strokeWidth = 1,
      );
    }

    // Draw ticks, labels, and grid
    for (final tick in ticks) {
      final y = scale.dataToPixel(tick.value);

      // Skip if outside plot area
      if (y < plotArea.top || y > plotArea.bottom) continue;

      // Draw grid line
      if (config.showGrid) {
        canvas.drawLine(
          Offset(plotArea.left, y),
          Offset(plotArea.right, y),
          Paint()
            ..color = config.gridColor
            ..strokeWidth = 0.5,
        );
      }

      // Draw tick mark
      if (config.showTickMarks) {
        final tickX1 = config.position == AxisPosition.left ? axisX - config.tickLength : axisX;
        final tickX2 = config.position == AxisPosition.left ? axisX : axisX + config.tickLength;

        canvas.drawLine(
          Offset(tickX1, y),
          Offset(tickX2, y),
          Paint()
            ..color = config.axisColor
            ..strokeWidth = 1,
        );
      }

      // Draw tick label (only if axis is visible)
      if (config.showAxisLine) {
        final textPainter = TextPainter(
          text: TextSpan(text: tick.label, style: config.tickLabelStyle),
          textDirection: TextDirection.ltr,
        )..layout();

        final labelX = config.position == AxisPosition.left
            ? axisX - config.tickLength - config.labelPadding - textPainter.width
            : axisX + config.tickLength + config.labelPadding;

        textPainter.paint(
          canvas,
          Offset(labelX, y - textPainter.height / 2),
        );
      }
    }

    // Draw axis label (rotated 90°)
    if (config.label.isNotEmpty) {
      canvas.save();

      final labelX = (config.position == AxisPosition.left ? 12.0 : chartSize.width - 12).toDouble();
      final labelY = plotArea.top + plotArea.height / 2;

      canvas.translate(labelX, labelY.toDouble());
      canvas.rotate(-math.pi / 2);

      final labelPainter = TextPainter(
        text: TextSpan(text: config.label, style: config.labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      labelPainter.paint(canvas, Offset(-labelPainter.width / 2, 0));

      canvas.restore();
    }
  }
}
