// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Axis System

import 'package:flutter/material.dart';

/// Configuration for axis appearance and behavior.
class AxisConfig {
  /// Label for the entire axis (e.g., "Time", "Price").
  final String label;

  /// Orientation of the axis.
  final AxisOrientation orientation;

  /// Position of the axis relative to the chart.
  final AxisPosition position;

  /// Text style for the axis label.
  final TextStyle labelStyle;

  /// Text style for tick labels.
  final TextStyle tickLabelStyle;

  /// Color of the axis line and tick marks.
  final Color axisColor;

  /// Color of the grid lines.
  final Color gridColor;

  /// Whether to show grid lines.
  final bool showGrid;

  /// Whether to show the axis line.
  final bool showAxisLine;

  /// Whether to show tick marks.
  final bool showTickMarks;

  /// Length of tick marks in pixels.
  final double tickLength;

  /// Padding between tick mark and label.
  final double labelPadding;

  const AxisConfig({
    this.label = '',
    required this.orientation,
    required this.position,
    this.labelStyle = const TextStyle(fontSize: 12, color: Colors.black87),
    this.tickLabelStyle = const TextStyle(fontSize: 10, color: Colors.black54),
    this.axisColor = Colors.black87,
    this.gridColor = const Color(0xFFE0E0E0),
    this.showGrid = true,
    this.showAxisLine = true,
    this.showTickMarks = true,
    this.tickLength = 6,
    this.labelPadding = 8,
  });

  AxisConfig copyWith({
    String? label,
    AxisOrientation? orientation,
    AxisPosition? position,
    TextStyle? labelStyle,
    TextStyle? tickLabelStyle,
    Color? axisColor,
    Color? gridColor,
    bool? showGrid,
    bool? showAxisLine,
    bool? showTickMarks,
    double? tickLength,
    double? labelPadding,
  }) {
    return AxisConfig(
      label: label ?? this.label,
      orientation: orientation ?? this.orientation,
      position: position ?? this.position,
      labelStyle: labelStyle ?? this.labelStyle,
      tickLabelStyle: tickLabelStyle ?? this.tickLabelStyle,
      axisColor: axisColor ?? this.axisColor,
      gridColor: gridColor ?? this.gridColor,
      showGrid: showGrid ?? this.showGrid,
      showAxisLine: showAxisLine ?? this.showAxisLine,
      showTickMarks: showTickMarks ?? this.showTickMarks,
      tickLength: tickLength ?? this.tickLength,
      labelPadding: labelPadding ?? this.labelPadding,
    );
  }
}

/// Orientation of an axis.
enum AxisOrientation {
  /// Horizontal axis (X-axis).
  horizontal,

  /// Vertical axis (Y-axis).
  vertical,
}

/// Position of an axis relative to the chart.
enum AxisPosition {
  /// Bottom of chart (typical for X-axis).
  bottom,

  /// Top of chart.
  top,

  /// Left side of chart (typical for Y-axis).
  left,

  /// Right side of chart.
  right,
}
