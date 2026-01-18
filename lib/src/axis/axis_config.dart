// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Axis System
//
// INTERNAL USE ONLY - This class is for internal axis rendering.
// For public API, use XAxisConfig or YAxisConfig.

import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/x_axis_config.dart';

/// Internal configuration for axis rendering.
///
/// **INTERNAL USE ONLY** - This class is used by the axis rendering system.
/// For public API configuration, use [XAxisConfig] or [YAxisConfig].
///
/// This class is created from public configs via [fromXAxisConfig] or
/// [fromYAxisConfig].
class InternalAxisConfig {
  const InternalAxisConfig({
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

  /// Creates an internal config from the public XAxisConfig.
  ///
  /// Maps public API properties to internal rendering properties:
  /// - [XAxisConfig.showAxisLine] → [showAxisLine]
  /// - [XAxisConfig.showTicks] → [showTickMarks]
  /// - [XAxisConfig.visible] → [showAxisLine]/[showTickMarks] gating
  factory InternalAxisConfig.fromXAxisConfig(XAxisConfig config) {
    return InternalAxisConfig(
      label: config.label ?? '',
      orientation: AxisOrientation.horizontal,
      position: AxisPosition.bottom,
      labelStyle: const TextStyle(fontSize: 12, color: Colors.black87),
      tickLabelStyle: const TextStyle(fontSize: 10, color: Colors.black54),
      axisColor: config.color ?? Colors.black87,
      gridColor: const Color(0xFFE0E0E0),
      showGrid: false,
      showAxisLine: config.visible && config.showAxisLine,
      showTickMarks: config.visible && config.showTicks,
      tickLength: 6,
      labelPadding: 8,
    );
  }

  /// Creates an internal config from the public YAxisConfig.
  ///
  /// Maps public API properties to internal rendering properties:
  /// - [YAxisConfig.showAxisLine] → [showAxisLine]
  /// - [YAxisConfig.showTicks] → [showTickMarks]
  /// - [YAxisConfig.visible] → [showAxisLine]/[showTickMarks] gating
  factory InternalAxisConfig.fromYAxisConfig(YAxisConfig config) {
    return InternalAxisConfig(
      label: config.label ?? '',
      orientation: AxisOrientation.vertical,
      position: _mapYAxisPosition(config.position),
      labelStyle: const TextStyle(fontSize: 12, color: Colors.black87),
      tickLabelStyle: const TextStyle(fontSize: 10, color: Colors.black54),
      axisColor: config.color ?? Colors.black87,
      gridColor: const Color(0xFFE0E0E0),
      showGrid: false,
      showAxisLine: config.visible && config.showAxisLine,
      showTickMarks: config.visible && config.showTicks,
      tickLength: 6,
      labelPadding: 8,
    );
  }

  /// Maps YAxisPosition to internal AxisPosition with sensible defaults.
  static AxisPosition _mapYAxisPosition(YAxisPosition position) {
    switch (position) {
      case YAxisPosition.right:
      case YAxisPosition.rightOuter:
        return AxisPosition.right;
      case YAxisPosition.left:
      case YAxisPosition.leftOuter:
        return AxisPosition.left;
    }
  }

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

  InternalAxisConfig copyWith({
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
    return InternalAxisConfig(
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
