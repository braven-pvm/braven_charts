/// Contract: YAxisConfig
///
/// Configuration for a single Y-axis in multi-axis charts.
/// Defines position, appearance, bounds, and formatting.
library;

import 'dart:ui' show Color;

/// Position of Y-axis relative to plot area.
///
/// Layout order (left to right):
/// [leftOuter] [left] [PLOT AREA] [right] [rightOuter]
enum YAxisPosition {
  /// Leftmost axis (far left of plot area).
  leftOuter,

  /// Primary left axis (adjacent to plot area left edge).
  left,

  /// Primary right axis (adjacent to plot area right edge).
  right,

  /// Rightmost axis (far right of plot area).
  rightOuter,
}

/// Configuration for a single Y-axis.
///
/// Example:
/// ```dart
/// final powerAxis = YAxisConfig(
///   id: 'power',
///   position: YAxisPosition.left,
///   color: Colors.blue,
///   label: 'Power',
///   unit: 'W',
///   min: 0,
///   max: 400,
/// );
/// ```
class YAxisConfig {
  const YAxisConfig({
    required this.id,
    required this.position,
    this.color,
    this.label,
    this.unit,
    this.min,
    this.max,
    this.showTicks = true,
    this.showAxisLine = true,
    this.showLabels = true,
    this.minWidth = 40.0,
    this.maxWidth = 80.0,
    this.tickCount,
    this.labelFormatter,
  })  : assert(id.isNotEmpty, 'id must be non-empty'),
        assert(minWidth > 0, 'minWidth must be positive'),
        assert(maxWidth >= minWidth, 'maxWidth must be >= minWidth'),
        assert(min == null || max == null || min < max,
            'min must be less than max'),
        assert(tickCount == null || tickCount >= 2, 'tickCount must be >= 2');

  /// Unique identifier for axis binding.
  ///
  /// Series reference this ID via [ChartSeries.yAxisId].
  final String id;

  /// Position of axis relative to plot area.
  final YAxisPosition position;

  /// Axis color for line, ticks, and labels.
  ///
  /// If null, defaults to the color of the first bound series.
  final Color? color;

  /// Axis label text (e.g., "Power", "Heart Rate").
  final String? label;

  /// Unit suffix for tick labels (e.g., "W", "bpm", "L/min").
  final String? unit;

  /// Explicit minimum value.
  ///
  /// If null, computed from bound series data.
  final double? min;

  /// Explicit maximum value.
  ///
  /// If null, computed from bound series data.
  final double? max;

  /// Whether to show tick marks.
  final bool showTicks;

  /// Whether to show the axis line.
  final bool showAxisLine;

  /// Whether to show tick labels.
  final bool showLabels;

  /// Minimum axis width in pixels.
  final double minWidth;

  /// Maximum axis width in pixels.
  final double maxWidth;

  /// Preferred number of ticks.
  ///
  /// If null, computed automatically based on available height.
  final int? tickCount;

  /// Custom label formatting function.
  ///
  /// If null, uses default number formatting.
  final String Function(double value)? labelFormatter;

  /// Create a copy with modified properties.
  YAxisConfig copyWith({
    String? id,
    YAxisPosition? position,
    Color? color,
    String? label,
    String? unit,
    double? min,
    double? max,
    bool? showTicks,
    bool? showAxisLine,
    bool? showLabels,
    double? minWidth,
    double? maxWidth,
    int? tickCount,
    String Function(double)? labelFormatter,
  }) {
    return YAxisConfig(
      id: id ?? this.id,
      position: position ?? this.position,
      color: color ?? this.color,
      label: label ?? this.label,
      unit: unit ?? this.unit,
      min: min ?? this.min,
      max: max ?? this.max,
      showTicks: showTicks ?? this.showTicks,
      showAxisLine: showAxisLine ?? this.showAxisLine,
      showLabels: showLabels ?? this.showLabels,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      tickCount: tickCount ?? this.tickCount,
      labelFormatter: labelFormatter ?? this.labelFormatter,
    );
  }

  @override
  String toString() => 'YAxisConfig(id: $id, position: $position)';
}
