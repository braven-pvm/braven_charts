import 'dart:ui' show Color;

import 'y_axis_position.dart';

/// Configuration for a Y-axis in a multi-axis chart.
///
/// Each Y-axis can have its own position, color, label, unit suffix,
/// and optional explicit data bounds. This configuration is immutable
/// and used to define how an axis should be rendered and scaled.
///
/// Example:
/// ```dart
/// final config = YAxisConfig(
///   id: 'power',
///   position: YAxisPosition.left,
///   color: Color(0xFF2196F3), // Blue
///   label: 'Power Output',
///   unitSuffix: 'W',
/// );
/// ```
class YAxisConfig {
  /// Creates a Y-axis configuration.
  ///
  /// The [id] and [position] are required. All other properties are optional.
  ///
  /// - [id]: Unique identifier for this axis, used to bind series to axes
  /// - [position]: Where to render the axis (outerLeft, left, right, outerRight)
  /// - [color]: Color for axis line, ticks, and labels (defaults to theme color)
  /// - [label]: Optional title text displayed alongside the axis
  /// - [unitSuffix]: Unit to append to tick values (e.g., "W", "bpm", "L/min")
  /// - [minValue]: Explicit minimum bound (auto-computed from data if null)
  /// - [maxValue]: Explicit maximum bound (auto-computed from data if null)
  const YAxisConfig({
    required this.id,
    required this.position,
    this.color,
    this.label,
    this.unitSuffix,
    this.minValue,
    this.maxValue,
  });

  /// Unique identifier for this axis.
  ///
  /// Used to bind data series to this specific axis configuration.
  /// Must be unique within a chart's axis configurations.
  final String id;

  /// Position where this axis should be rendered.
  ///
  /// Determines which side of the chart the axis appears on:
  /// - [YAxisPosition.outerLeft]: Furthest left position
  /// - [YAxisPosition.left]: Standard left position
  /// - [YAxisPosition.right]: Standard right position
  /// - [YAxisPosition.outerRight]: Furthest right position
  final YAxisPosition position;

  /// Color for the axis line, ticks, and labels.
  ///
  /// When null, the axis uses the chart theme's default axis color.
  /// For multi-axis charts, it's recommended to color-code each axis
  /// to match its bound series for easy visual identification.
  final Color? color;

  /// Optional title text displayed alongside the axis.
  ///
  /// Typically rendered rotated 90° adjacent to the axis.
  /// Example: "Power Output", "Heart Rate", "Temperature"
  final String? label;

  /// Unit suffix appended to tick values.
  ///
  /// Displayed after each tick label value.
  /// Examples: "W" for watts, "bpm" for beats per minute, "°C" for Celsius
  final String? unitSuffix;

  /// Explicit minimum bound for this axis.
  ///
  /// When null, the minimum is auto-computed from the bound series data.
  /// Use explicit bounds when you need consistent axis ranges across
  /// multiple chart views or when the data doesn't include the desired minimum.
  final double? minValue;

  /// Explicit maximum bound for this axis.
  ///
  /// When null, the maximum is auto-computed from the bound series data.
  /// Use explicit bounds when you need consistent axis ranges across
  /// multiple chart views or when the data doesn't include the desired maximum.
  final double? maxValue;

  /// Creates a copy of this configuration with the given fields replaced.
  YAxisConfig copyWith({
    String? id,
    YAxisPosition? position,
    Color? color,
    String? label,
    String? unitSuffix,
    double? minValue,
    double? maxValue,
  }) {
    return YAxisConfig(
      id: id ?? this.id,
      position: position ?? this.position,
      color: color ?? this.color,
      label: label ?? this.label,
      unitSuffix: unitSuffix ?? this.unitSuffix,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
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
        other.unitSuffix == unitSuffix &&
        other.minValue == minValue &&
        other.maxValue == maxValue;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      position,
      color,
      label,
      unitSuffix,
      minValue,
      maxValue,
    );
  }

  @override
  String toString() {
    return 'YAxisConfig(id: $id, position: $position, color: $color, '
        'label: $label, unitSuffix: $unitSuffix, '
        'minValue: $minValue, maxValue: $maxValue)';
  }
}
