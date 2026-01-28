import 'package:equatable/equatable.dart';

import 'enums.dart';

/// Configuration for the X-axis of a chart.
///
/// Provides settings for axis type, range, ticks, and visual appearance.
/// Uses [EquatableMixin] for value equality comparisons.
///
/// ## Example
///
/// ```dart
/// final xAxis = XAxisConfig(
///   label: 'Time',
///   unit: 'seconds',
///   type: AxisType.time,
///   showGridLines: true,
/// );
/// ```
///
/// ## JSON Serialization
///
/// ```dart
/// final json = xAxis.toJson();
/// final restored = XAxisConfig.fromJson(json);
/// ```
class XAxisConfig with EquatableMixin {
  /// Label displayed alongside the axis.
  final String? label;

  /// Unit string for axis values (e.g., 'km', 'sec').
  final String? unit;

  /// Type of axis data representation.
  final AxisType type;

  /// Minimum value for the axis range.
  final double? min;

  /// Maximum value for the axis range.
  final double? max;

  /// Whether to automatically calculate the range from data.
  final bool autoRange;

  /// Padding percentage to add to the axis range (0.0 to 1.0).
  final double paddingPercent;

  /// Number of ticks to display on the axis.
  final int? tickCount;

  /// Format string for tick labels (e.g., '%.2f' for 2 decimal places).
  final String? tickFormat;

  /// Rotation angle in degrees for tick labels.
  final double tickRotation;

  /// Whether to show tick marks on the axis.
  final bool showTicks;

  /// Whether to show the axis line.
  final bool showAxisLine;

  /// Whether to show grid lines extending from the axis.
  final bool showGridLines;

  /// Color for grid lines (hex string or named color).
  final String? gridColor;

  /// Dash pattern for grid lines.
  ///
  /// Example: `[5, 3]` creates dashed grid lines.
  final List<double>? gridDash;

  /// Creates an [XAxisConfig] with the given parameters.
  ///
  /// All parameters have sensible defaults for common use cases.
  const XAxisConfig({
    this.label,
    this.unit,
    this.type = AxisType.numeric,
    this.min,
    this.max,
    this.autoRange = true,
    this.paddingPercent = 0.0,
    this.tickCount,
    this.tickFormat,
    this.tickRotation = 0.0,
    this.showTicks = true,
    this.showAxisLine = true,
    this.showGridLines = true,
    this.gridColor,
    this.gridDash,
  });

  /// Creates an [XAxisConfig] from a JSON map.
  ///
  /// Parses all fields including enum values and optional lists.
  factory XAxisConfig.fromJson(Map<String, dynamic> json) {
    return XAxisConfig(
      label: json['label'] as String?,
      unit: json['unit'] as String?,
      type: json['type'] != null
          ? AxisType.values.byName(json['type'] as String)
          : AxisType.numeric,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      autoRange: json['autoRange'] as bool? ?? true,
      paddingPercent: (json['paddingPercent'] as num?)?.toDouble() ?? 0.0,
      tickCount: json['tickCount'] as int?,
      tickFormat: json['tickFormat'] as String?,
      tickRotation: (json['tickRotation'] as num?)?.toDouble() ?? 0.0,
      showTicks: json['showTicks'] as bool? ?? true,
      showAxisLine: json['showAxisLine'] as bool? ?? true,
      showGridLines: json['showGridLines'] as bool? ?? true,
      gridColor: json['gridColor'] as String?,
      gridDash: (json['gridDash'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  /// Converts this [XAxisConfig] to a JSON map.
  ///
  /// Includes all properties. Enum values are serialized as their names.
  Map<String, dynamic> toJson() {
    return {
      if (label != null) 'label': label,
      if (unit != null) 'unit': unit,
      'type': type.name,
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      'autoRange': autoRange,
      'paddingPercent': paddingPercent,
      if (tickCount != null) 'tickCount': tickCount,
      if (tickFormat != null) 'tickFormat': tickFormat,
      'tickRotation': tickRotation,
      'showTicks': showTicks,
      'showAxisLine': showAxisLine,
      'showGridLines': showGridLines,
      if (gridColor != null) 'gridColor': gridColor,
      if (gridDash != null) 'gridDash': gridDash,
    };
  }

  /// Creates a copy of this [XAxisConfig] with optionally overridden values.
  ///
  /// If a parameter is not provided, the original value is preserved.
  XAxisConfig copyWith({
    String? label,
    String? unit,
    AxisType? type,
    double? min,
    double? max,
    bool? autoRange,
    double? paddingPercent,
    int? tickCount,
    String? tickFormat,
    double? tickRotation,
    bool? showTicks,
    bool? showAxisLine,
    bool? showGridLines,
    String? gridColor,
    List<double>? gridDash,
  }) {
    return XAxisConfig(
      label: label ?? this.label,
      unit: unit ?? this.unit,
      type: type ?? this.type,
      min: min ?? this.min,
      max: max ?? this.max,
      autoRange: autoRange ?? this.autoRange,
      paddingPercent: paddingPercent ?? this.paddingPercent,
      tickCount: tickCount ?? this.tickCount,
      tickFormat: tickFormat ?? this.tickFormat,
      tickRotation: tickRotation ?? this.tickRotation,
      showTicks: showTicks ?? this.showTicks,
      showAxisLine: showAxisLine ?? this.showAxisLine,
      showGridLines: showGridLines ?? this.showGridLines,
      gridColor: gridColor ?? this.gridColor,
      gridDash: gridDash ?? this.gridDash,
    );
  }

  @override
  List<Object?> get props => [
        label,
        unit,
        type,
        min,
        max,
        autoRange,
        paddingPercent,
        tickCount,
        tickFormat,
        tickRotation,
        showTicks,
        showAxisLine,
        showGridLines,
        gridColor,
        gridDash,
      ];

  @override
  String toString() => 'XAxisConfig(label: $label, type: $type)';
}
