// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

/// Chart-level configuration for grid line visibility and styling.
///
/// GridConfig controls the rendering of horizontal and vertical grid lines
/// across the chart's plot area. Horizontal lines typically align with Y-axis
/// ticks, while vertical lines align with X-axis ticks.
///
/// **Visibility:**
/// - [horizontal]: Show/hide horizontal grid lines (default: true)
/// - [vertical]: Show/hide vertical grid lines (default: true)
///
/// **Colors:**
/// - [horizontalColor]: Color for horizontal lines (null = use theme default)
/// - [verticalColor]: Color for vertical lines (null = use theme default)
///
/// **Stroke Widths:**
/// - [horizontalStrokeWidth]: Line width for horizontal lines (default: 0.5)
/// - [verticalStrokeWidth]: Line width for vertical lines (default: 0.5)
///
/// **Example:**
/// ```dart
/// // Use default settings (both grids visible)
/// GridConfig()
///
/// // Show only horizontal grid lines with custom styling
/// GridConfig(
///   horizontal: true,
///   vertical: false,
///   horizontalColor: Colors.grey.withOpacity(0.3),
///   horizontalStrokeWidth: 1.0,
/// )
/// ```
@immutable
class GridConfig {
  /// Creates a grid configuration.
  const GridConfig({
    this.horizontal = true,
    this.vertical = true,
    this.horizontalColor,
    this.verticalColor,
    this.horizontalStrokeWidth = 0.5,
    this.verticalStrokeWidth = 0.5,
  }) : assert(
         horizontalStrokeWidth > 0,
         'horizontalStrokeWidth must be positive',
       ),
       assert(verticalStrokeWidth > 0, 'verticalStrokeWidth must be positive');

  /// Whether to show horizontal grid lines (at Y-axis tick positions).
  ///
  /// When true, horizontal lines are drawn across the plot area at each
  /// Y-axis tick position.
  final bool horizontal;

  /// Whether to show vertical grid lines (at X-axis tick positions).
  ///
  /// When true, vertical lines are drawn across the plot area at each
  /// X-axis tick position.
  final bool vertical;

  /// Color for horizontal grid lines.
  ///
  /// When null, falls back to the theme's default grid line color.
  final Color? horizontalColor;

  /// Color for vertical grid lines.
  ///
  /// When null, falls back to the theme's default grid line color.
  final Color? verticalColor;

  /// Stroke width for horizontal grid lines.
  ///
  /// Must be positive. Default is 0.5 for subtle grid lines.
  final double horizontalStrokeWidth;

  /// Stroke width for vertical grid lines.
  ///
  /// Must be positive. Default is 0.5 for subtle grid lines.
  final double verticalStrokeWidth;

  /// Creates a copy with optional parameter overrides.
  GridConfig copyWith({
    bool? horizontal,
    bool? vertical,
    Color? horizontalColor,
    Color? verticalColor,
    double? horizontalStrokeWidth,
    double? verticalStrokeWidth,
  }) {
    return GridConfig(
      horizontal: horizontal ?? this.horizontal,
      vertical: vertical ?? this.vertical,
      horizontalColor: horizontalColor ?? this.horizontalColor,
      verticalColor: verticalColor ?? this.verticalColor,
      horizontalStrokeWidth:
          horizontalStrokeWidth ?? this.horizontalStrokeWidth,
      verticalStrokeWidth: verticalStrokeWidth ?? this.verticalStrokeWidth,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GridConfig &&
        other.horizontal == horizontal &&
        other.vertical == vertical &&
        other.horizontalColor == horizontalColor &&
        other.verticalColor == verticalColor &&
        other.horizontalStrokeWidth == horizontalStrokeWidth &&
        other.verticalStrokeWidth == verticalStrokeWidth;
  }

  @override
  int get hashCode {
    return Object.hash(
      horizontal,
      vertical,
      horizontalColor,
      verticalColor,
      horizontalStrokeWidth,
      verticalStrokeWidth,
    );
  }

  @override
  String toString() {
    return 'GridConfig('
        'horizontal: $horizontal, '
        'vertical: $vertical, '
        'horizontalColor: $horizontalColor, '
        'verticalColor: $verticalColor, '
        'horizontalStrokeWidth: $horizontalStrokeWidth, '
        'verticalStrokeWidth: $verticalStrokeWidth'
        ')';
  }
}
