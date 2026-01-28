import 'package:equatable/equatable.dart';

import 'enums.dart';

/// Configuration for a Y-axis of a chart.
///
/// Provides settings for axis position, range, ticks, and visual appearance.
/// Supports multi-axis charts through the optional [id] field.
/// Uses [EquatableMixin] for value equality comparisons.
///
/// ## Example
///
/// ```dart
/// final yAxis = YAxisConfig(
///   id: 'temperature',
///   label: 'Temperature',
///   unit: '°C',
///   position: AxisPosition.left,
///   includeZero: true,
/// );
/// ```
///
/// ## JSON Serialization
///
/// ```dart
/// final json = yAxis.toJson();
/// final restored = YAxisConfig.fromJson(json);
/// ```
class YAxisConfig with EquatableMixin {
  /// Unique identifier for this Y-axis.
  ///
  /// Used for multi-axis charts to associate series with specific axes.
  final String? id;

  /// Label displayed alongside the axis.
  final String? label;

  /// Unit string for axis values (e.g., '°C', 'km/h').
  final String? unit;

  /// Position of the axis (left or right side of the chart).
  final AxisPosition position;

  /// Minimum value for the axis range.
  final double? min;

  /// Maximum value for the axis range.
  final double? max;

  /// Whether to automatically calculate the range from data.
  final bool autoRange;

  /// Whether to include zero in the axis range.
  final bool includeZero;

  /// Padding percentage to add to the axis range (0.0 to 1.0).
  final double paddingPercent;

  /// Number of ticks to display on the axis.
  final int? tickCount;

  /// Format string for tick labels (e.g., '%.2f' for 2 decimal places).
  final String? tickFormat;

  /// Whether to show tick marks on the axis.
  final bool showTicks;

  /// Whether to show the axis line.
  final bool showAxisLine;

  /// Whether to show grid lines extending from the axis.
  final bool showGridLines;

  /// Color for grid lines (hex string or named color).
  final String? gridColor;

  /// Color for the axis line and labels (hex string or named color).
  final String? color;

  /// Creates a [YAxisConfig] with the given parameters.
  ///
  /// All parameters have sensible defaults for common use cases.
  const YAxisConfig({
    this.id,
    this.label,
    this.unit,
    this.position = AxisPosition.left,
    this.min,
    this.max,
    this.autoRange = true,
    this.includeZero = false,
    this.paddingPercent = 0.0,
    this.tickCount,
    this.tickFormat,
    this.showTicks = true,
    this.showAxisLine = true,
    this.showGridLines = true,
    this.gridColor,
    this.color,
  });

  /// Creates a [YAxisConfig] from a JSON map.
  ///
  /// Parses all fields including enum values.
  factory YAxisConfig.fromJson(Map<String, dynamic> json) {
    return YAxisConfig(
      id: json['id'] as String?,
      label: json['label'] as String?,
      unit: json['unit'] as String?,
      position: json['position'] != null ? AxisPosition.values.byName(json['position'] as String) : AxisPosition.left,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      autoRange: json['autoRange'] as bool? ?? true,
      includeZero: json['includeZero'] as bool? ?? false,
      paddingPercent: (json['paddingPercent'] as num?)?.toDouble() ?? 0.0,
      tickCount: json['tickCount'] as int?,
      tickFormat: json['tickFormat'] as String?,
      showTicks: json['showTicks'] as bool? ?? true,
      showAxisLine: json['showAxisLine'] as bool? ?? true,
      showGridLines: json['showGridLines'] as bool? ?? true,
      gridColor: json['gridColor'] as String?,
      color: json['color'] as String?,
    );
  }

  /// Converts this [YAxisConfig] to a JSON map.
  ///
  /// Includes all properties. Enum values are serialized as their names.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (unit != null) 'unit': unit,
      'position': position.name,
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      'autoRange': autoRange,
      'includeZero': includeZero,
      'paddingPercent': paddingPercent,
      if (tickCount != null) 'tickCount': tickCount,
      if (tickFormat != null) 'tickFormat': tickFormat,
      'showTicks': showTicks,
      'showAxisLine': showAxisLine,
      'showGridLines': showGridLines,
      if (gridColor != null) 'gridColor': gridColor,
      if (color != null) 'color': color,
    };
  }

  /// Creates a copy of this [YAxisConfig] with optionally overridden values.
  ///
  /// If a parameter is not provided, the original value is preserved.
  YAxisConfig copyWith({
    String? id,
    String? label,
    String? unit,
    AxisPosition? position,
    double? min,
    double? max,
    bool? autoRange,
    bool? includeZero,
    double? paddingPercent,
    int? tickCount,
    String? tickFormat,
    bool? showTicks,
    bool? showAxisLine,
    bool? showGridLines,
    String? gridColor,
    String? color,
  }) {
    return YAxisConfig(
      id: id ?? this.id,
      label: label ?? this.label,
      unit: unit ?? this.unit,
      position: position ?? this.position,
      min: min ?? this.min,
      max: max ?? this.max,
      autoRange: autoRange ?? this.autoRange,
      includeZero: includeZero ?? this.includeZero,
      paddingPercent: paddingPercent ?? this.paddingPercent,
      tickCount: tickCount ?? this.tickCount,
      tickFormat: tickFormat ?? this.tickFormat,
      showTicks: showTicks ?? this.showTicks,
      showAxisLine: showAxisLine ?? this.showAxisLine,
      showGridLines: showGridLines ?? this.showGridLines,
      gridColor: gridColor ?? this.gridColor,
      color: color ?? this.color,
    );
  }

  @override
  List<Object?> get props => [
        id,
        label,
        unit,
        position,
        min,
        max,
        autoRange,
        includeZero,
        paddingPercent,
        tickCount,
        tickFormat,
        showTicks,
        showAxisLine,
        showGridLines,
        gridColor,
        color,
      ];

  @override
  String toString() => 'YAxisConfig(id: $id, label: $label, position: $position)';
}
