import 'package:equatable/equatable.dart';

import 'data_point.dart';
import 'enums.dart';

/// Configuration for a single data series in a chart.
///
/// Represents a complete series with data points and styling options.
/// Uses [EquatableMixin] for value equality comparisons.
///
/// ## Example
///
/// ```dart
/// final series = SeriesConfig(
///   id: 'temperature',
///   data: [DataPoint(x: 0, y: 20), DataPoint(x: 1, y: 22)],
///   name: 'Temperature',
///   color: '#FF5733',
///   strokeWidth: 2.0,
/// );
/// ```
///
/// ## JSON Serialization
///
/// ```dart
/// final json = series.toJson();
/// final restored = SeriesConfig.fromJson(json);
/// ```
class SeriesConfig with EquatableMixin {
  /// Unique identifier for this series.
  final String id;

  /// Optional display name for the series.
  final String? name;

  /// The data points in this series.
  final List<DataPoint> data;

  /// Color for the series line/fill (hex string or named color).
  final String? color;

  /// Width of the stroke line in pixels.
  final double strokeWidth;

  /// Dash pattern for the stroke line.
  ///
  /// Example: `[5, 3]` creates a dashed line with 5px dashes and 3px gaps.
  final List<double>? strokeDash;

  /// Opacity of the fill area (0.0 to 1.0).
  ///
  /// Only applies to area charts. 0.0 means no fill, 1.0 means fully opaque.
  final double fillOpacity;

  /// Style of markers displayed at data points.
  final MarkerStyle markerStyle;

  /// Size of markers in pixels.
  final double markerSize;

  /// Interpolation mode for connecting data points.
  final Interpolation interpolation;

  /// Tension parameter for bezier/monotone interpolation.
  ///
  /// Values typically range from 0.0 to 1.0.
  final double tension;

  /// Whether to show individual data points.
  final bool showPoints;

  /// Position for an INLINE Y-axis created specifically for this series.
  ///
  /// Use this with [yAxisLabel], [yAxisUnit], [yAxisColor], [yAxisMin], [yAxisMax]
  /// to define a dedicated Y-axis for this series inline.
  ///
  /// MUTUALLY EXCLUSIVE with [yAxisId] - use one or the other:
  /// - Use [yAxisId] to reference a SHARED axis defined in the chart's yAxes array.
  /// - Use [yAxisPosition] (with its companions) to define an INLINE axis.
  ///
  /// Values: 'left', 'right', 'leftOuter', 'rightOuter'
  final String? yAxisPosition;

  /// Label for the INLINE Y-axis (used with [yAxisPosition]).
  ///
  /// Ignored if [yAxisId] is set.
  final String? yAxisLabel;

  /// Unit string for the INLINE Y-axis (used with [yAxisPosition]).
  ///
  /// Ignored if [yAxisId] is set.
  final String? yAxisUnit;

  /// Color for the INLINE Y-axis (used with [yAxisPosition]).
  ///
  /// Ignored if [yAxisId] is set.
  final String? yAxisColor;

  /// Minimum value for the INLINE Y-axis range (used with [yAxisPosition]).
  ///
  /// Ignored if [yAxisId] is set.
  final double? yAxisMin;

  /// Maximum value for the INLINE Y-axis range (used with [yAxisPosition]).
  ///
  /// Ignored if [yAxisId] is set.
  final double? yAxisMax;

  /// Bar width as a percentage of available space (0.0 to 1.0).
  ///
  /// Only applies to bar charts.
  final double? barWidthPercent;

  /// Fixed bar width in pixels.
  ///
  /// Only applies to bar charts. Overrides [barWidthPercent] if set.
  final double? barWidthPixels;

  /// Minimum bar width in pixels.
  ///
  /// Only applies to bar charts.
  final double? barMinWidth;

  /// Maximum bar width in pixels.
  ///
  /// Only applies to bar charts.
  final double? barMaxWidth;

  /// Reference to a SHARED Y-axis defined in the chart's yAxes array.
  ///
  /// Links to [YAxisConfig.id] for multi-axis charts where multiple series
  /// share the same Y-axis configuration.
  ///
  /// MUTUALLY EXCLUSIVE with [yAxisPosition] - use one or the other:
  /// - Use [yAxisId] to reference a SHARED axis defined in the chart's yAxes array.
  /// - Use [yAxisPosition] (with its companions) to define an INLINE axis.
  final String? yAxisId;

  /// Whether this series is visible on the chart.
  final bool visible;

  /// Whether this series is shown in the legend.
  final bool legendVisible;

  /// Unit string for the series data (e.g., 'W', 'bpm').
  final String? unit;

  /// Creates a [SeriesConfig] with the given parameters.
  ///
  /// [id] and [data] are required. All other parameters have defaults.
  const SeriesConfig({
    required this.id,
    required this.data,
    this.name,
    this.color,
    this.strokeWidth = 2.0,
    this.strokeDash,
    this.fillOpacity = 0.0,
    this.markerStyle = MarkerStyle.none,
    this.markerSize = 4.0,
    this.interpolation = Interpolation.linear,
    this.tension = 0.4,
    this.showPoints = false,
    this.yAxisPosition,
    this.yAxisLabel,
    this.yAxisUnit,
    this.yAxisColor,
    this.yAxisMin,
    this.yAxisMax,
    this.barWidthPercent,
    this.barWidthPixels,
    this.barMinWidth,
    this.barMaxWidth,
    this.yAxisId,
    this.visible = true,
    this.legendVisible = true,
    this.unit,
  });

  /// Creates a [SeriesConfig] from a JSON map.
  ///
  /// Parses all fields including the nested [DataPoint] list and enum values.
  factory SeriesConfig.fromJson(Map<String, dynamic> json) {
    return SeriesConfig(
      id: json['id'] as String,
      name: json['name'] as String?,
      data: (json['data'] as List<dynamic>).map((e) => DataPoint.fromJson(e as Map<String, dynamic>)).toList(),
      color: json['color'] as String?,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      strokeDash: (json['strokeDash'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList(),
      fillOpacity: (json['fillOpacity'] as num?)?.toDouble() ?? 0.0,
      markerStyle: json['markerStyle'] != null ? MarkerStyle.values.byName(json['markerStyle'] as String) : MarkerStyle.none,
      markerSize: (json['markerSize'] as num?)?.toDouble() ?? 4.0,
      interpolation: json['interpolation'] != null ? Interpolation.values.byName(json['interpolation'] as String) : Interpolation.linear,
      tension: (json['tension'] as num?)?.toDouble() ?? 0.4,
      showPoints: json['showPoints'] as bool? ?? false,
      yAxisPosition: json['yAxisPosition'] as String?,
      yAxisLabel: json['yAxisLabel'] as String?,
      yAxisUnit: json['yAxisUnit'] as String?,
      yAxisColor: json['yAxisColor'] as String?,
      yAxisMin: (json['yAxisMin'] as num?)?.toDouble(),
      yAxisMax: (json['yAxisMax'] as num?)?.toDouble(),
      barWidthPercent: (json['barWidthPercent'] as num?)?.toDouble(),
      barWidthPixels: (json['barWidthPixels'] as num?)?.toDouble(),
      barMinWidth: (json['barMinWidth'] as num?)?.toDouble(),
      barMaxWidth: (json['barMaxWidth'] as num?)?.toDouble(),
      yAxisId: json['yAxisId'] as String?,
      visible: json['visible'] as bool? ?? true,
      legendVisible: json['legendVisible'] as bool? ?? true,
      unit: json['unit'] as String?,
    );
  }

  /// Converts this [SeriesConfig] to a JSON map.
  ///
  /// Includes all properties. Enum values are serialized as their names.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      'data': data.map((e) => e.toJson()).toList(),
      if (color != null) 'color': color,
      'strokeWidth': strokeWidth,
      if (strokeDash != null) 'strokeDash': strokeDash,
      'fillOpacity': fillOpacity,
      'markerStyle': markerStyle.name,
      'markerSize': markerSize,
      'interpolation': interpolation.name,
      'tension': tension,
      'showPoints': showPoints,
      if (yAxisPosition != null) 'yAxisPosition': yAxisPosition,
      if (yAxisLabel != null) 'yAxisLabel': yAxisLabel,
      if (yAxisUnit != null) 'yAxisUnit': yAxisUnit,
      if (yAxisColor != null) 'yAxisColor': yAxisColor,
      if (yAxisMin != null) 'yAxisMin': yAxisMin,
      if (yAxisMax != null) 'yAxisMax': yAxisMax,
      if (barWidthPercent != null) 'barWidthPercent': barWidthPercent,
      if (barWidthPixels != null) 'barWidthPixels': barWidthPixels,
      if (barMinWidth != null) 'barMinWidth': barMinWidth,
      if (barMaxWidth != null) 'barMaxWidth': barMaxWidth,
      if (yAxisId != null) 'yAxisId': yAxisId,
      'visible': visible,
      'legendVisible': legendVisible,
      if (unit != null) 'unit': unit,
    };
  }

  /// Creates a copy of this [SeriesConfig] with optionally overridden values.
  ///
  /// If a parameter is not provided, the original value is preserved.
  SeriesConfig copyWith({
    String? id,
    String? name,
    List<DataPoint>? data,
    String? color,
    double? strokeWidth,
    List<double>? strokeDash,
    double? fillOpacity,
    MarkerStyle? markerStyle,
    double? markerSize,
    Interpolation? interpolation,
    double? tension,
    bool? showPoints,
    String? yAxisPosition,
    String? yAxisLabel,
    String? yAxisUnit,
    String? yAxisColor,
    double? yAxisMin,
    double? yAxisMax,
    double? barWidthPercent,
    double? barWidthPixels,
    double? barMinWidth,
    double? barMaxWidth,
    String? yAxisId,
    bool? visible,
    bool? legendVisible,
    String? unit,
  }) {
    return SeriesConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      data: data ?? this.data,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeDash: strokeDash ?? this.strokeDash,
      fillOpacity: fillOpacity ?? this.fillOpacity,
      markerStyle: markerStyle ?? this.markerStyle,
      markerSize: markerSize ?? this.markerSize,
      interpolation: interpolation ?? this.interpolation,
      tension: tension ?? this.tension,
      showPoints: showPoints ?? this.showPoints,
      yAxisPosition: yAxisPosition ?? this.yAxisPosition,
      yAxisLabel: yAxisLabel ?? this.yAxisLabel,
      yAxisUnit: yAxisUnit ?? this.yAxisUnit,
      yAxisColor: yAxisColor ?? this.yAxisColor,
      yAxisMin: yAxisMin ?? this.yAxisMin,
      yAxisMax: yAxisMax ?? this.yAxisMax,
      barWidthPercent: barWidthPercent ?? this.barWidthPercent,
      barWidthPixels: barWidthPixels ?? this.barWidthPixels,
      barMinWidth: barMinWidth ?? this.barMinWidth,
      barMaxWidth: barMaxWidth ?? this.barMaxWidth,
      yAxisId: yAxisId ?? this.yAxisId,
      visible: visible ?? this.visible,
      legendVisible: legendVisible ?? this.legendVisible,
      unit: unit ?? this.unit,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        data,
        color,
        strokeWidth,
        strokeDash,
        fillOpacity,
        markerStyle,
        markerSize,
        interpolation,
        tension,
        showPoints,
        yAxisPosition,
        yAxisLabel,
        yAxisUnit,
        yAxisColor,
        yAxisMin,
        yAxisMax,
        barWidthPercent,
        barWidthPixels,
        barMinWidth,
        barMaxWidth,
        yAxisId,
        visible,
        legendVisible,
        unit,
      ];

  @override
  String toString() => 'SeriesConfig(id: $id, name: $name, data: ${data.length} points)';
}
