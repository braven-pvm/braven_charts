import 'dart:ui' show Color;

import '../meta/chart_surface.dart';
import 'chart_annotation.dart';
import 'chart_data_point.dart';
import 'chart_series.dart';
import 'pie_chart_config.dart';
import 'radial_category_series.dart';
import 'radial_selection_style.dart';
import 'segment_style.dart';
import 'y_axis_config.dart';

/// A single-ring pie series whose points represent category contributions.
///
/// A chart may contain exactly one [PieChartSeries] and may not mix it with
/// Cartesian series. Each point requires a finite ordering [ChartDataPoint.x],
/// a non-negative finite [ChartDataPoint.y], and a non-empty category label.
/// Zero-valued points remain transportable but do not produce visible slices.
///
/// Every generated verb re-validates the whole series, because the
/// constructor does. In particular the legal range of a [PieChartStyle]
/// NARROWS inside a pie series: `PieChartStyle(radiusFactor: 2)` is a
/// perfectly constructible style, and `withPieStyle` / `updatePieStyle`
/// reject it with `ArgumentError` because a pie's radius factor must be in
/// `(0, 1]`. That coupling crosses the nested-config boundary, so no
/// [CombinedSetter] can express it and excluding `pieStyle` would remove the
/// most useful verb on the class; it is acknowledged instead.
///
/// There is no generated `withSliceRadiusConfig` verb either. Variable slice
/// radii are a PAIR: the config and a `PointStyle.size` on every point. A
/// setter that supplies only the config threw `ArgumentError` on every series
/// whose points carry no sizes, which is every series built without them.
/// Supply both through [PieChartSeries.fromMap]'s `radiusValues`, or through
/// the constructor.
// validateRadialConfiguration() reads FIELDS (radialStyle, selectionStyle,
// points), never the constructor's own parameter names, so surface_gen
// cannot narrow the scope below the whole class.
///
/// [id] is force-excluded from the fluent surface: a series id is a JOIN
/// KEY — Y axes, annotations and artifact documents bind to it — so a verb
/// that rewrites it mid-chain silently detaches the series from everything
/// that references it. Construct the series with the id it should carry.
@ChartSurface(
  excluded: ['id', 'sliceRadiusConfig'],
  bodyValidated: [
    BodyValidated(
      'validateRadialConfiguration() re-checks the whole series on every '
      'construction: finite non-negative point values with non-empty labels, '
      'radialStyle.radiusFactor in (0, 1], non-negative sliceGap and '
      'borderWidth, and the selectionStyle lift/blur ranges. A verb whose '
      'argument is individually valid — a PieChartStyle with '
      'radiusFactor 2 — therefore throws ArgumentError with the failing '
      'field named.',
    ),
  ],
)
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
    super.selectionStyle = const RadialSelectionStyle(),
    super.dataLabels = const PieDataLabelConfig(),
    super.sliceRadiusConfig,
    super.sliceGroupingConfig,
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
    RadialSliceGroupingConfig? sliceGroupingConfig,
    Color? color,
    Map<String, dynamic>? metadata,
    String? unit,
    PieChartStyle pieStyle = const PieChartStyle(),
    RadialSelectionStyle selectionStyle = const RadialSelectionStyle(),
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
      selectionStyle: selectionStyle,
      dataLabels: dataLabels,
      sliceRadiusConfig: radiusValues.isEmpty
          ? null
          : (sliceRadiusConfig ?? const PieSliceRadiusConfig()),
      sliceGroupingConfig: sliceGroupingConfig,
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
    RadialSelectionStyle? selectionStyle,
    PieDataLabelConfig? dataLabels,
    PieSliceRadiusConfig? sliceRadiusConfig,
    bool clearSliceRadiusConfig = false,
    RadialSliceGroupingConfig? sliceGroupingConfig,
    bool clearSliceGroupingConfig = false,
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
      selectionStyle: selectionStyle ?? this.selectionStyle,
      dataLabels: dataLabels ?? this.dataLabels,
      sliceRadiusConfig: clearSliceRadiusConfig
          ? null
          : (sliceRadiusConfig ?? this.sliceRadiusConfig),
      sliceGroupingConfig: clearSliceGroupingConfig
          ? null
          : (sliceGroupingConfig ?? this.sliceGroupingConfig),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PieChartSeries &&
          super == other &&
          pieStyle == other.pieStyle &&
          selectionStyle == other.selectionStyle &&
          dataLabels == other.dataLabels &&
          sliceRadiusConfig == other.sliceRadiusConfig &&
          sliceGroupingConfig == other.sliceGroupingConfig;

  @override
  int get hashCode => Object.hash(
    super.hashCode,
    pieStyle,
    selectionStyle,
    dataLabels,
    sliceRadiusConfig,
    sliceGroupingConfig,
  );

  @override
  String toString() =>
      'PieChartSeries(id: $id, slices: ${points.length}, total: $total)';
}
