import 'package:equatable/equatable.dart';

import 'data_point.dart';
import 'enums.dart';
import 'y_axis_config.dart';

/// Configuration for a single data series in a chart (V2 Schema).
///
/// Represents a complete series with data points, styling options, and
/// per-series axis configuration. Uses [EquatableMixin] for value equality.
///
/// ## V2 Schema: Nested yAxis Configuration
///
/// In the V2 schema, each series defines its own y-axis through the nested
/// [yAxis] property (a [YAxisConfig] object). This replaces the legacy
/// `yAxisId` reference pattern and enables:
///
/// - **Per-series normalization**: Each series has independent min/max scaling
/// - **Multi-axis charts**: Multiple series with different units and scales
/// - **Deep merge updates**: Partial yAxis updates preserve unspecified properties
///
/// ## Example: Basic Series with Nested yAxis
///
/// ```dart
/// final series = SeriesConfig(
///   id: 'temperature',
///   data: [DataPoint(x: 0, y: 20), DataPoint(x: 1, y: 22)],
///   name: 'Temperature',
///   color: '#FF5733',
///   strokeWidth: 2.0,
///   yAxis: YAxisConfig(
///     position: AxisPosition.left,
///     label: 'Temperature',
///     unit: '°C',
///     min: 0,
///     max: 50,
///   ),
/// );
/// ```
///
/// ## Example: Multi-Series Chart with Different Axes
///
/// ```dart
/// final tempSeries = SeriesConfig(
///   id: 'temp',
///   data: tempData,
///   yAxis: YAxisConfig(position: AxisPosition.left, label: 'Temp', unit: '°C'),
/// );
///
/// final humiditySeries = SeriesConfig(
///   id: 'humidity',
///   data: humidityData,
///   yAxis: YAxisConfig(position: AxisPosition.right, label: 'Humidity', unit: '%'),
/// );
/// ```
///
/// ## JSON Serialization
///
/// ```dart
/// final json = series.toJson();
/// // Output includes nested yAxis: { "yAxis": { "position": "left", ... } }
/// final restored = SeriesConfig.fromJson(json);
/// ```
///
/// See also:
/// - [YAxisConfig] for y-axis configuration options
/// - [ChartConfiguration] for the complete chart structure
class SeriesConfig with EquatableMixin {
  /// Unique identifier for this series.
  final String id;

  /// The type of chart to render for this series.
  ///
  /// Each series can have its own type, enabling mixed charts
  /// (e.g., one series as line, another as bar).
  /// Defaults to [ChartType.line].
  final ChartType type;

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

  /// Nested Y-axis configuration for this series (V2 Schema).
  ///
  /// Contains all y-axis properties (position, label, unit, color, min, max, etc.)
  /// in a single nested [YAxisConfig] object.
  ///
  /// ## V2 Schema Benefits
  ///
  /// - **Self-contained**: All axis config lives with the series data
  /// - **Deep merge**: Partial updates preserve unspecified properties
  /// - **Per-series normalization**: Works with `normalizationMode: perSeries`
  ///
  /// ## Validation Warnings
  ///
  /// - **V002**: Warning if using `perSeries` normalization without yAxis config
  ///
  /// ## Example
  ///
  /// ```dart
  /// SeriesConfig(
  ///   id: 'power',
  ///   data: [...],
  ///   yAxis: YAxisConfig(
  ///     position: AxisPosition.left,
  ///     label: 'Power',
  ///     unit: 'W',
  ///     min: 0,
  ///     max: 500,
  ///     color: '#2196F3',
  ///   ),
  /// )
  /// ```
  ///
  /// See also:
  /// - [YAxisConfig] for all available axis properties
  /// - [SchemaValidator] for validation rules V001, V002
  final YAxisConfig? yAxis;

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
    this.type = ChartType.line,
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
    this.yAxis,
    this.barWidthPercent,
    this.barWidthPixels,
    this.barMinWidth,
    this.barMaxWidth,
    this.visible = true,
    this.legendVisible = true,
    this.unit,
  });

  /// Creates a [SeriesConfig] from a JSON map.
  ///
  /// Parses all fields including the nested [DataPoint] list and enum values.
  /// Supports nested 'yAxis' object for y-axis configuration per FR-001.
  factory SeriesConfig.fromJson(Map<String, dynamic> json) {
    // Parse nested yAxis object if present
    YAxisConfig? yAxis;
    if (json['yAxis'] != null && json['yAxis'] is Map<String, dynamic>) {
      yAxis = YAxisConfig.fromJson(json['yAxis'] as Map<String, dynamic>);
    }

    return SeriesConfig(
      id: json['id'] as String,
      type: json['type'] != null
          ? ChartType.values.byName(json['type'] as String)
          : ChartType.line,
      name: json['name'] as String?,
      data: (json['data'] as List<dynamic>)
          .map((e) => DataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      color: json['color'] as String?,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      strokeDash: (json['strokeDash'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      fillOpacity: (json['fillOpacity'] as num?)?.toDouble() ?? 0.0,
      markerStyle: json['markerStyle'] != null
          ? MarkerStyle.values.byName(json['markerStyle'] as String)
          : MarkerStyle.none,
      markerSize: (json['markerSize'] as num?)?.toDouble() ?? 4.0,
      interpolation: json['interpolation'] != null
          ? Interpolation.values.byName(json['interpolation'] as String)
          : Interpolation.linear,
      tension: (json['tension'] as num?)?.toDouble() ?? 0.4,
      showPoints: json['showPoints'] as bool? ?? false,
      yAxis: yAxis,
      barWidthPercent: (json['barWidthPercent'] as num?)?.toDouble(),
      barWidthPixels: (json['barWidthPixels'] as num?)?.toDouble(),
      barMinWidth: (json['barMinWidth'] as num?)?.toDouble(),
      barMaxWidth: (json['barMaxWidth'] as num?)?.toDouble(),
      visible: json['visible'] as bool? ?? true,
      legendVisible: json['legendVisible'] as bool? ?? true,
      unit: json['unit'] as String?,
    );
  }

  /// Converts this [SeriesConfig] to a JSON map.
  ///
  /// Includes all properties. Enum values are serialized as their names.
  /// Y-axis configuration is output as nested 'yAxis' object per FR-001/FR-002.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
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
      if (yAxis != null) 'yAxis': yAxis!.toJson(),
      if (barWidthPercent != null) 'barWidthPercent': barWidthPercent,
      if (barWidthPixels != null) 'barWidthPixels': barWidthPixels,
      if (barMinWidth != null) 'barMinWidth': barMinWidth,
      if (barMaxWidth != null) 'barMaxWidth': barMaxWidth,
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
    ChartType? type,
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
    YAxisConfig? yAxis,
    double? barWidthPercent,
    double? barWidthPixels,
    double? barMinWidth,
    double? barMaxWidth,
    bool? visible,
    bool? legendVisible,
    String? unit,
  }) {
    return SeriesConfig(
      id: id ?? this.id,
      type: type ?? this.type,
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
      yAxis: yAxis ?? this.yAxis,
      barWidthPercent: barWidthPercent ?? this.barWidthPercent,
      barWidthPixels: barWidthPixels ?? this.barWidthPixels,
      barMinWidth: barMinWidth ?? this.barMinWidth,
      barMaxWidth: barMaxWidth ?? this.barMaxWidth,
      visible: visible ?? this.visible,
      legendVisible: legendVisible ?? this.legendVisible,
      unit: unit ?? this.unit,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
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
        yAxis,
        barWidthPercent,
        barWidthPixels,
        barMinWidth,
        barMaxWidth,
        visible,
        legendVisible,
        unit,
      ];

  @override
  String toString() =>
      'SeriesConfig(id: $id, name: $name, data: ${data.length} points)';
}
