import 'dart:ui' show Color;

import 'chart_annotation.dart';
import 'chart_data_point.dart';
import 'chart_series.dart';
import 'pie_chart_config.dart';
import 'radial_category_series.dart';
import 'segment_style.dart';
import 'y_axis_config.dart';

/// A single-ring pie series whose points represent category contributions.
///
/// A chart may contain exactly one [PieChartSeries] and may not mix it with
/// Cartesian series. Each point requires a finite ordering [ChartDataPoint.x],
/// a non-negative finite [ChartDataPoint.y], and a non-empty category label.
/// Zero-valued points remain transportable but do not produce visible slices.
class PieChartSeries extends RadialCategorySeries {
  /// Creates an explicitly ordered pie series and validates it in all modes.
  PieChartSeries({
    required super.id,
    super.name,
    required super.points,
    super.color,
    super.metadata,
    super.unit,
    PieChartStyle pieStyle = const PieChartStyle(),
    super.dataLabels = const PieDataLabelConfig(),
    super.sliceRadiusConfig,
  }) : super(style: SeriesStyle.pie, radialStyle: pieStyle) {
    validateRadialConfiguration(chartName: 'Pie');
  }

  /// Creates a pie series from insertion-ordered category/value pairs.
  ///
  /// The generated X values are stable zero-based ordinals. Use [sliceColors]
  /// to attach optional per-category color overrides through [PointStyle].
  /// Supply [radiusValues] plus an optional [sliceRadiusConfig] to encode a
  /// second metric as variable slice radii.
  factory PieChartSeries.fromMap({
    required String id,
    String? name,
    required Map<String, num> values,
    Map<String, Color> sliceColors = const {},
    Map<String, num> radiusValues = const {},
    PieSliceRadiusConfig? sliceRadiusConfig,
    Color? color,
    Map<String, dynamic>? metadata,
    String? unit,
    PieChartStyle pieStyle = const PieChartStyle(),
    PieDataLabelConfig dataLabels = const PieDataLabelConfig(),
  }) {
    if (radiusValues.isNotEmpty &&
        (radiusValues.length != values.length ||
            !radiusValues.keys.toSet().containsAll(values.keys) ||
            !values.keys.toSet().containsAll(radiusValues.keys))) {
      throw ArgumentError.value(
        radiusValues,
        'radiusValues',
        'Variable Pie radii require exactly one value for every category',
      );
    }
    if (radiusValues.isEmpty && sliceRadiusConfig != null) {
      throw ArgumentError.value(
        sliceRadiusConfig,
        'sliceRadiusConfig',
        'A radius config requires radiusValues',
      );
    }
    final points = <ChartDataPoint>[];
    for (final (index, entry) in values.entries.indexed) {
      final sliceColor = sliceColors[entry.key];
      final radiusValue = radiusValues[entry.key]?.toDouble();
      points.add(
        ChartDataPoint(
          x: index.toDouble(),
          y: entry.value.toDouble(),
          label: entry.key,
          pointStyle: sliceColor == null && radiusValue == null
              ? null
              : PointStyle(color: sliceColor, size: radiusValue),
        ),
      );
    }
    return PieChartSeries(
      id: id,
      name: name,
      points: points,
      color: color,
      metadata: metadata,
      unit: unit,
      pieStyle: pieStyle,
      dataLabels: dataLabels,
      sliceRadiusConfig: radiusValues.isEmpty
          ? null
          : (sliceRadiusConfig ?? const PieSliceRadiusConfig()),
    );
  }

  /// Geometry and border configuration shared by every slice.
  PieChartStyle get pieStyle => radialStyle as PieChartStyle;

  @override
  double get innerRadiusFactor => 0;

  @override
  double get sweepAngleDegrees => 360;

  /// Returns a validated copy with selected fields replaced.
  @override
  PieChartSeries copyWith({
    String? id,
    String? name,
    List<ChartDataPoint>? points,
    Color? color,
    SeriesStyle? style,
    bool? isXOrdered,
    Map<String, dynamic>? metadata,
    List<ChartAnnotation>? annotations,
    String? yAxisId,
    YAxisConfig? yAxisConfig,
    String? unit,
    PieChartStyle? pieStyle,
    PieDataLabelConfig? dataLabels,
    PieSliceRadiusConfig? sliceRadiusConfig,
    bool clearSliceRadiusConfig = false,
  }) {
    if (style != null && style != SeriesStyle.pie) {
      throw ArgumentError.value(style, 'style', 'Pie series style is fixed');
    }
    if (isXOrdered == false) {
      throw ArgumentError.value(
        isXOrdered,
        'isXOrdered',
        'Pie slice order must remain stable',
      );
    }
    if (yAxisId != null || yAxisConfig != null || annotations != null) {
      throw ArgumentError(
        'Pie series do not support Cartesian axes or series annotations',
      );
    }
    final copiedPoints = points ?? this.points;
    return PieChartSeries(
      id: id ?? this.id,
      name: name ?? this.name,
      points: clearSliceRadiusConfig
          ? [
              for (final point in copiedPoints)
                RadialCategorySeries.withoutSliceRadius(point),
            ]
          : copiedPoints,
      color: color ?? this.color,
      metadata: metadata ?? this.metadata,
      unit: unit ?? this.unit,
      pieStyle: pieStyle ?? this.pieStyle,
      dataLabels: dataLabels ?? this.dataLabels,
      sliceRadiusConfig: clearSliceRadiusConfig
          ? null
          : (sliceRadiusConfig ?? this.sliceRadiusConfig),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PieChartSeries &&
          super == other &&
          pieStyle == other.pieStyle &&
          dataLabels == other.dataLabels &&
          sliceRadiusConfig == other.sliceRadiusConfig;

  @override
  int get hashCode =>
      Object.hash(super.hashCode, pieStyle, dataLabels, sliceRadiusConfig);

  @override
  String toString() =>
      'PieChartSeries(id: $id, slices: ${points.length}, total: $total)';
}
