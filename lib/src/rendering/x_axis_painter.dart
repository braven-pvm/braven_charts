// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui' show Canvas, Color, Rect;

import 'package:flutter/painting.dart' show TextStyle;

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
    // Stub - full implementation in later phase
  }

  /// Generates tick values for the axis.
  ///
  /// [bounds] is the data range for tick generation.
  /// [maxTicks] is the optional maximum number of ticks to generate.
  ///
  /// Returns a list of tick values within the bounds.
  List<double> generateTicks(DataRange bounds, {int? maxTicks}) {
    return []; // Stub
  }

  /// Formats a tick value for display.
  ///
  /// [value] is the tick value to format.
  ///
  /// Returns a formatted string representation of the value.
  String formatTickLabel(double value) {
    return value.toString(); // Minimal implementation
  }

  /// Resolves the color to use for the axis.
  ///
  /// Returns [config.color] if provided, otherwise returns a default axis color.
  Color resolveAxisColor() {
    return config.color ?? const Color(0xFF333333); // Default axis color
  }
}
