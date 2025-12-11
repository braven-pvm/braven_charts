// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Axis System
//
// INTERNAL USE ONLY - This class is for internal axis rendering.
// For public API, use AxisConfig from models/axis_config.dart

import 'package:flutter/material.dart';

import '../models/axis_config.dart' as public_config;
import '../models/enums.dart';

/// Internal configuration for axis rendering.
///
/// **INTERNAL USE ONLY** - This class is used by the axis rendering system.
/// For public API configuration, use [public_config.AxisConfig] from models/axis_config.dart.
///
/// This class is created from the public AxisConfig via [fromPublicConfig].
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

  /// Creates an internal config from the public AxisConfig.
  ///
  /// Maps public API properties to internal rendering properties:
  /// - [public_config.AxisConfig.showAxis] → [showAxisLine]
  /// - [public_config.AxisConfig.showTicks] → [showTickMarks]
  /// - [public_config.AxisConfig.axisPosition] → [position]
  /// - [public_config.AxisConfig.tickLength] → [tickLength]
  ///
  /// The [isXAxis] parameter determines the axis orientation and default position.
  factory InternalAxisConfig.fromPublicConfig(
    public_config.AxisConfig config, {
    required bool isXAxis,
  }) {
    // Determine orientation based on axis type
    final orientation =
        isXAxis ? AxisOrientation.horizontal : AxisOrientation.vertical;

    // Determine position from public config or use default based on axis type
    final position = _mapAxisPosition(config.axisPosition, isXAxis);

    return InternalAxisConfig(
      label: config.label ?? '',
      orientation: orientation,
      position: position,
      labelStyle: config.labelStyle ??
          const TextStyle(fontSize: 12, color: Colors.black87),
      tickLabelStyle: config.labelStyle ??
          const TextStyle(fontSize: 10, color: Colors.black54),
      axisColor: config.axisColor ?? Colors.black87,
      gridColor: config.gridColor ?? const Color(0xFFE0E0E0),
      showGrid: config.showGrid,
      showAxisLine: config.showAxis,
      showTickMarks: config.showTicks,
      tickLength: config.tickLength,
      labelPadding: 8, // Not exposed in public API, use default
    );
  }

  /// Maps public AxisPosition to internal AxisPosition with sensible defaults.
  static AxisPosition _mapAxisPosition(
      AxisPosition publicPosition, bool isXAxis) {
    // The public AxisPosition uses the same enum as internal,
    // but we need to validate the position makes sense for the axis type
    if (isXAxis) {
      // X-axis should be top or bottom
      if (publicPosition == AxisPosition.left ||
          publicPosition == AxisPosition.right) {
        return AxisPosition.bottom; // Default for X-axis
      }
    } else {
      // Y-axis should be left or right
      if (publicPosition == AxisPosition.top ||
          publicPosition == AxisPosition.bottom) {
        return AxisPosition.left; // Default for Y-axis
      }
    }
    return publicPosition;
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
