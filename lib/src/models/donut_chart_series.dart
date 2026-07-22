import 'dart:ui' show Color;

import '../meta/chart_surface.dart';
import 'chart_annotation.dart';
import 'chart_data_point.dart';
import 'chart_series.dart';
import 'donut_chart_config.dart';
import 'pie_chart_config.dart';
import 'radial_category_series.dart';
import 'radial_selection_style.dart';
import 'segment_style.dart';
import 'y_axis_config.dart';

/// A single-ring Donut series whose points represent category contributions.
///
/// A chart may contain exactly one [DonutChartSeries] and may not mix it with
/// Pie or Cartesian series. The circular opening is configured by
/// [DonutChartStyle.innerRadiusFactor].
///
/// Every generated verb re-validates the whole series, because the
/// constructor does. As on [PieChartSeries], the legal range of a
/// [DonutChartStyle] NARROWS inside the series — `innerRadiusFactor` must be
/// in `(0, 1)` and `sweepAngleDegrees` in `(0, 360]` — so `withDonutStyle` /
/// `updateDonutStyle` reject a style that is individually constructible. The
/// coupling crosses the nested-config boundary and cannot be expressed as a
/// [CombinedSetter]; it is acknowledged instead.
///
/// There is no generated `withSliceRadiusConfig` verb either. Variable slice
/// radii are a PAIR: the config and a `PointStyle.size` on every point. A
/// setter that supplies only the config threw `ArgumentError` on every series
/// whose points carry no sizes, which is every series built without them.
/// Supply both through [DonutChartSeries.fromMap]'s `radiusValues`, or
/// through the constructor.
// The body mixes an opaque validateRadialConfiguration() call with named
// range checks on donutStyle, sliceRadiusConfig and centerContent, so the
// opaque statement widens the scope to the whole class.
///
/// [id] is force-excluded from the fluent surface: a series id is a JOIN
/// KEY — Y axes, annotations and artifact documents bind to it — so a verb
/// that rewrites it mid-chain silently detaches the series from everything
/// that references it. Construct the series with the id it should carry.
@ChartSurface(
  excluded: ['id', 'sliceRadiusConfig'],
  bodyValidated: [
    BodyValidated(
      'validateRadialConfiguration() re-checks the whole series, and the '
      'body then range-checks donutStyle.innerRadiusFactor, '
      'donutStyle.sweepAngleDegrees, sliceRadiusConfig.minimumFactor and the '
      'centerContent label/value rules. A verb whose argument is '
      'individually valid can therefore throw ArgumentError with the failing '
      'field named.',
    ),
  ],
)
class DonutChartSeries extends RadialCategorySeries {
  /// Creates an explicitly ordered Donut series and validates it in all modes.
  DonutChartSeries({
    required super.id,
    super.name,
    required super.points,
    super.color,
    super.metadata,
    super.unit,
    this.donutStyle = const DonutChartStyle(),
    super.selectionStyle = const RadialSelectionStyle(),
    this.centerContent = DonutCenterContent.hidden,
    super.dataLabels = const PieDataLabelConfig(),
    super.sliceRadiusConfig,
    super.sliceGroupingConfig,
  }) : super(style: SeriesStyle.donut, radialStyle: donutStyle) {
    validateRadialConfiguration(chartName: 'Donut');
    RadialCategorySeries.requireRange(
      donutStyle.innerRadiusFactor,
      'donutStyle.innerRadiusFactor',
      min: 0,
      max: 1,
      minInclusive: false,
      maxInclusive: false,
    );
    RadialCategorySeries.requireRange(
      donutStyle.sweepAngleDegrees,
      'donutStyle.sweepAngleDegrees',
      min: 0,
      max: 360,
      minInclusive: false,
    );
    if (sliceRadiusConfig case final radiusConfig?) {
      RadialCategorySeries.requireRange(
        radiusConfig.minimumFactor,
        'sliceRadiusConfig.minimumFactor',
        min: 0,
        max: 1,
        minInclusive: false,
      );
    }
    final label = centerContent.label?.trim();
    if (centerContent.label != null && (label == null || label.isEmpty)) {
      throw ArgumentError.value(
        centerContent.label,
        'centerContent.label',
        'Center labels must be null or contain visible text',
      );
    }
    final customValue = centerContent.customValue?.trim();
    if (centerContent.valueMode == DonutCenterValueMode.custom &&
        (customValue == null || customValue.isEmpty)) {
      throw ArgumentError.value(
        centerContent.customValue,
        'centerContent.customValue',
        'Custom center content requires a visible custom value',
      );
    }
  }

  /// Creates a Donut series from insertion-ordered category/value pairs.
  factory DonutChartSeries.fromMap({
    required String id,
    String? name,
    required Map<String, num> values,
    Map<String, Color> sliceColors = const {},
    Map<String, num> radiusValues = const {},
    RadialSliceRadiusConfig? sliceRadiusConfig,
    RadialSliceGroupingConfig? sliceGroupingConfig,
    Color? color,
    Map<String, dynamic>? metadata,
    String? unit,
    DonutChartStyle donutStyle = const DonutChartStyle(),
    RadialSelectionStyle selectionStyle = const RadialSelectionStyle(),
    DonutCenterContent centerContent = DonutCenterContent.hidden,
    PieDataLabelConfig dataLabels = const PieDataLabelConfig(),
  }) {
    if (radiusValues.isNotEmpty &&
        (radiusValues.length != values.length ||
            !radiusValues.keys.toSet().containsAll(values.keys) ||
            !values.keys.toSet().containsAll(radiusValues.keys))) {
      throw ArgumentError.value(
        radiusValues,
        'radiusValues',
        'Variable Donut radii require exactly one value for every category',
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
    return DonutChartSeries(
      id: id,
      name: name,
      points: points,
      color: color,
      metadata: metadata,
      unit: unit,
      donutStyle: donutStyle,
      selectionStyle: selectionStyle,
      centerContent: centerContent,
      dataLabels: dataLabels,
      sliceRadiusConfig: radiusValues.isEmpty
          ? null
          : (sliceRadiusConfig ?? const RadialSliceRadiusConfig()),
      sliceGroupingConfig: sliceGroupingConfig,
    );
  }

  /// Donut-specific geometry plus the shared radial appearance contract.
  final DonutChartStyle donutStyle;

  /// Portable text content shown inside the shared center opening.
  final DonutCenterContent centerContent;

  @override
  double get innerRadiusFactor => donutStyle.innerRadiusFactor;

  @override
  double get sweepAngleDegrees => donutStyle.sweepAngleDegrees;

  /// Returns a validated copy with selected fields replaced.
  @override
  DonutChartSeries copyWith({
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
    DonutChartStyle? donutStyle,
    RadialSelectionStyle? selectionStyle,
    DonutCenterContent? centerContent,
    PieDataLabelConfig? dataLabels,
    RadialSliceRadiusConfig? sliceRadiusConfig,
    bool clearSliceRadiusConfig = false,
    RadialSliceGroupingConfig? sliceGroupingConfig,
    bool clearSliceGroupingConfig = false,
  }) {
    if (style != null && style != SeriesStyle.donut) {
      throw ArgumentError.value(style, 'style', 'Donut series style is fixed');
    }
    if (isXOrdered == false) {
      throw ArgumentError.value(
        isXOrdered,
        'isXOrdered',
        'Donut slice order must remain stable',
      );
    }
    if (yAxisId != null || yAxisConfig != null || annotations != null) {
      throw ArgumentError(
        'Donut series do not support Cartesian axes or series annotations',
      );
    }
    final copiedPoints = points ?? this.points;
    return DonutChartSeries(
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
      donutStyle: donutStyle ?? this.donutStyle,
      selectionStyle: selectionStyle ?? this.selectionStyle,
      centerContent: centerContent ?? this.centerContent,
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
      other is DonutChartSeries &&
          super == other &&
          donutStyle == other.donutStyle &&
          selectionStyle == other.selectionStyle &&
          centerContent == other.centerContent &&
          dataLabels == other.dataLabels &&
          sliceRadiusConfig == other.sliceRadiusConfig &&
          sliceGroupingConfig == other.sliceGroupingConfig;

  @override
  int get hashCode => Object.hash(
    super.hashCode,
    donutStyle,
    selectionStyle,
    centerContent,
    dataLabels,
    sliceRadiusConfig,
    sliceGroupingConfig,
  );

  @override
  String toString() =>
      'DonutChartSeries(id: $id, slices: ${points.length}, total: $total)';
}
