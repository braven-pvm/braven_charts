/// Y-axis configuration for multi-axis charts.
///
/// Defines the appearance, position, bounds, and formatting for a single Y-axis.
///
/// See also:
/// - [YAxisPosition] for axis positioning options
/// - [MultiAxisState] for runtime axis state
/// - [NormalizationMode] for normalization behavior control
library;

import 'package:flutter/painting.dart' show Color;

import '../models/y_axis_position.dart';

/// Configuration for a single Y-axis in multi-axis charts.
///
/// Each Y-axis can be configured with:
/// - Unique identifier for series binding
/// - Position relative to the plot area
/// - Optional color, labels, and formatting
/// - Explicit or auto-computed bounds
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
/// final heartRateAxis = YAxisConfig(
///   id: 'heartRate',
///   position: YAxisPosition.right,
///   color: Colors.red,
///   label: 'Heart Rate',
///   unit: 'bpm',
/// );
/// ```
class YAxisConfig {
  /// Creates a Y-axis configuration.
  ///
  /// [id] must be non-empty and unique within the chart's axis list.
  /// [position] determines where the axis appears relative to the plot area.
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
  })  : assert(id.length > 0, 'id must be non-empty'),
        assert(minWidth > 0, 'minWidth must be positive'),
        assert(maxWidth >= minWidth, 'maxWidth must be >= minWidth'),
        assert(
          min == null || max == null || min < max,
          'min must be less than max when both are specified',
        ),
        assert(
          tickCount == null || tickCount >= 2,
          'tickCount must be >= 2 when specified',
        );

  /// Unique identifier for axis binding.
  ///
  /// Series reference this ID via their `yAxisId` property.
  /// Must be unique within the chart's [yAxes] list.
  final String id;

  /// Position of axis relative to the plot area.
  ///
  /// Determines whether the axis appears on the left or right side,
  /// and whether it's adjacent to or offset from the plot area.
  final YAxisPosition position;

  /// Axis color for line, ticks, and labels.
  ///
  /// If null, defaults to the color of the first series bound to this axis.
  /// This creates automatic visual association between series and axes.
  final Color? color;

  /// Axis label text displayed alongside the axis.
  ///
  /// For example: "Power", "Heart Rate", "Temperature"
  final String? label;

  /// Unit suffix appended to tick labels.
  ///
  /// For example: "W", "bpm", "°C", "L/min"
  final String? unit;

  /// Explicit minimum value for the axis.
  ///
  /// If null, the minimum is computed from the data of all series
  /// bound to this axis.
  final double? min;

  /// Explicit maximum value for the axis.
  ///
  /// If null, the maximum is computed from the data of all series
  /// bound to this axis.
  final double? max;

  /// Whether to show tick marks along the axis.
  final bool showTicks;

  /// Whether to show the main axis line.
  final bool showAxisLine;

  /// Whether to show numeric labels at tick positions.
  final bool showLabels;

  /// Minimum axis width in pixels.
  ///
  /// The axis will not shrink below this width even if labels are short.
  final double minWidth;

  /// Maximum axis width in pixels.
  ///
  /// The axis will not grow beyond this width even if labels are long.
  /// Labels exceeding this width may be truncated.
  final double maxWidth;

  /// Preferred number of ticks to display.
  ///
  /// If null, the tick count is computed automatically based on
  /// the available height and font size.
  final int? tickCount;

  /// Custom function to format tick label values.
  ///
  /// If null, uses default number formatting with appropriate precision.
  ///
  /// Example:
  /// ```dart
  /// labelFormatter: (value) => '${value.toStringAsFixed(1)} W',
  /// ```
  final String Function(double value)? labelFormatter;

  /// Whether explicit bounds are configured for this axis.
  bool get hasExplicitBounds => min != null && max != null;

  /// Whether this axis has a custom color configured.
  bool get hasExplicitColor => color != null;

  /// Creates a copy with modified properties.
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YAxisConfig &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          position == other.position &&
          color == other.color &&
          label == other.label &&
          unit == other.unit &&
          min == other.min &&
          max == other.max &&
          showTicks == other.showTicks &&
          showAxisLine == other.showAxisLine &&
          showLabels == other.showLabels &&
          minWidth == other.minWidth &&
          maxWidth == other.maxWidth &&
          tickCount == other.tickCount;

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
      );

  @override
  String toString() => 'YAxisConfig(id: $id, position: $position)';
}
