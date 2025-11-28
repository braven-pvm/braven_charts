/// Configuration model for individual Y-axes in multi-axis charts.
///
/// This library provides the [YAxisConfig] class for configuring Y-axes
/// that can appear at different positions in a multi-axis chart layout.
library;

import 'dart:ui' show Color;

import 'y_axis_position.dart';

/// Typedef for custom Y-axis label formatters.
typedef YAxisLabelFormatter = String Function(double value);

/// Configuration for a Y-axis in a multi-axis chart.
///
/// Each Y-axis needs configuration for identity, position, appearance,
/// bounds, and formatting. Multiple Y-axes can be displayed simultaneously
/// at different positions around the chart area.
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
///
/// final hrAxis = YAxisConfig(
///   id: 'heartrate',
///   position: YAxisPosition.right,
///   color: Colors.red,
///   label: 'Heart Rate',
///   unit: 'bpm',
/// );
/// ```
class YAxisConfig {
  /// Creates a Y-axis configuration.
  ///
  /// [id] and [position] are required. All other parameters are optional
  /// with sensible defaults.
  ///
  /// Validation ensures:
  /// - [id] is non-empty
  /// - [minWidth] is positive
  /// - [maxWidth] >= [minWidth]
  /// - If both [min] and [max] are provided, [min] < [max]
  /// - If [tickCount] is provided, it must be >= 2
  YAxisConfig({
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
        assert(
          min == null || max == null || min < max,
          'min must be less than max',
        ),
        assert(
          tickCount == null || tickCount >= 2,
          'tickCount must be >= 2',
        );

  // ========== Identity ==========

  /// Unique identifier for axis binding.
  ///
  /// Used to associate data series with this axis. Must be non-empty.
  final String id;

  /// Physical position of the axis relative to the chart area.
  ///
  /// See [YAxisPosition] for available positions.
  final YAxisPosition position;

  // ========== Appearance ==========

  /// Color of the axis line, ticks, and labels.
  ///
  /// If null, uses the color of the first bound series.
  final Color? color;

  /// Axis label text (e.g., "Power", "Heart Rate").
  ///
  /// Displayed alongside the axis to identify what it represents.
  final String? label;

  /// Unit suffix for tick labels (e.g., "W", "bpm", "L").
  ///
  /// Appended to formatted tick values.
  final String? unit;

  // ========== Bounds ==========

  /// Explicit minimum value for the axis range.
  ///
  /// If null, minimum is computed from the data of bound series.
  final double? min;

  /// Explicit maximum value for the axis range.
  ///
  /// If null, maximum is computed from the data of bound series.
  final double? max;

  // ========== Visibility ==========

  /// Whether to show tick marks on the axis.
  final bool showTicks;

  /// Whether to show the axis line.
  final bool showAxisLine;

  /// Whether to show tick labels.
  final bool showLabels;

  // ========== Sizing ==========

  /// Minimum width of the axis area in logical pixels.
  ///
  /// Must be positive.
  final double minWidth;

  /// Maximum width of the axis area in logical pixels.
  ///
  /// Must be >= [minWidth].
  final double maxWidth;

  // ========== Formatting ==========

  /// Preferred number of tick marks.
  ///
  /// If null, tick count is computed automatically based on available space.
  /// If provided, must be >= 2.
  final int? tickCount;

  /// Custom formatter for tick labels.
  ///
  /// If null, uses default number formatting with [unit] suffix if provided.
  final YAxisLabelFormatter? labelFormatter;

  // ========== Methods ==========

  /// Creates a copy of this configuration with specified properties overridden.
  ///
  /// All parameters are optional. Properties not specified retain their
  /// current values.
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
    YAxisLabelFormatter? labelFormatter,
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
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is YAxisConfig &&
        other.id == id &&
        other.position == position &&
        other.color == color &&
        other.label == label &&
        other.unit == unit &&
        other.min == min &&
        other.max == max &&
        other.showTicks == showTicks &&
        other.showAxisLine == showAxisLine &&
        other.showLabels == showLabels &&
        other.minWidth == minWidth &&
        other.maxWidth == maxWidth &&
        other.tickCount == tickCount &&
        other.labelFormatter == labelFormatter;
  }

  @override
  int get hashCode => Object.hash(
        id,
        position,
        color,
        label,
        unit,
        min,
        max,
        showTicks,
        showAxisLine,
        showLabels,
        minWidth,
        maxWidth,
        tickCount,
        labelFormatter,
      );

  @override
  String toString() {
    return 'YAxisConfig('
        'id: $id, '
        'position: $position, '
        'color: $color, '
        'label: $label, '
        'unit: $unit, '
        'min: $min, '
        'max: $max, '
        'showTicks: $showTicks, '
        'showAxisLine: $showAxisLine, '
        'showLabels: $showLabels, '
        'minWidth: $minWidth, '
        'maxWidth: $maxWidth, '
        'tickCount: $tickCount'
        ')';
  }
}
