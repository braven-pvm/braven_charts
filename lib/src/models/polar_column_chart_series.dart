import 'dart:ui' show Color;

import 'chart_annotation.dart';
import 'chart_data_point.dart';
import 'chart_series.dart';
import 'radial_selection_style.dart';
import 'segment_style.dart';
import 'y_axis_config.dart';

/// Named interpretation applied to one Polar Column series.
enum PolarColumnPreset {
  /// Linear-radius Polar Column unless the radial axis overrides it.
  standard,

  /// Equal-angle Rose/Nightingale presentation with area-correct radial
  /// scaling unless the radial axis explicitly overrides it.
  rose,
}

/// Mark appearance for one Polar Column series.
class PolarColumnStyle {
  const PolarColumnStyle({
    this.cornerRadius = 4,
    this.opacity = 1,
    this.borderColor,
    this.borderWidth = 1,
    this.showDataLabels = true,
  });

  final double cornerRadius;
  final double opacity;
  final Color? borderColor;
  final double borderWidth;
  final bool showDataLabels;

  void validate() {
    if (!cornerRadius.isFinite || cornerRadius < 0) {
      throw ArgumentError.value(
        cornerRadius,
        'polarStyle.cornerRadius',
        'Value must be finite and non-negative',
      );
    }
    if (!opacity.isFinite || opacity < 0 || opacity > 1) {
      throw ArgumentError.value(
        opacity,
        'polarStyle.opacity',
        'Value must be finite and in [0, 1]',
      );
    }
    if (!borderWidth.isFinite || borderWidth < 0) {
      throw ArgumentError.value(
        borderWidth,
        'polarStyle.borderWidth',
        'Value must be finite and non-negative',
      );
    }
  }

  PolarColumnStyle copyWith({
    double? cornerRadius,
    double? opacity,
    Color? borderColor,
    bool clearBorderColor = false,
    double? borderWidth,
    bool? showDataLabels,
  }) => PolarColumnStyle(
    cornerRadius: cornerRadius ?? this.cornerRadius,
    opacity: opacity ?? this.opacity,
    borderColor: clearBorderColor ? null : (borderColor ?? this.borderColor),
    borderWidth: borderWidth ?? this.borderWidth,
    showDataLabels: showDataLabels ?? this.showDataLabels,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolarColumnStyle &&
          cornerRadius == other.cornerRadius &&
          opacity == other.opacity &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          showDataLabels == other.showDataLabels;

  @override
  int get hashCode => Object.hash(
    cornerRadius,
    opacity,
    borderColor,
    borderWidth,
    showDataLabels,
  );
}

/// One non-negative, category-based series rendered against polar axes.
///
/// Angle communicates category position. Radius communicates [ChartDataPoint.y]
/// against an explicit numeric axis; values are not converted into Pie shares.
class PolarColumnChartSeries extends ChartSeries {
  PolarColumnChartSeries({
    required super.id,
    super.name,
    required super.points,
    super.color,
    super.metadata,
    super.unit,
    this.preset = PolarColumnPreset.standard,
    this.polarStyle = const PolarColumnStyle(),
    this.selectionStyle = const RadialSelectionStyle(),
  }) : super(style: SeriesStyle.polarColumn, isXOrdered: true) {
    _validate();
  }

  /// Creates stable ordinal points from insertion-ordered categories.
  factory PolarColumnChartSeries.fromMap({
    required String id,
    String? name,
    required Map<String, num> values,
    Map<String, Color> columnColors = const {},
    Color? color,
    Map<String, dynamic>? metadata,
    String? unit,
    PolarColumnStyle polarStyle = const PolarColumnStyle(),
    RadialSelectionStyle selectionStyle = const RadialSelectionStyle(),
  }) => PolarColumnChartSeries._fromMap(
    id: id,
    name: name,
    values: values,
    columnColors: columnColors,
    color: color,
    metadata: metadata,
    unit: unit,
    preset: PolarColumnPreset.standard,
    polarStyle: polarStyle,
    selectionStyle: selectionStyle,
  );

  /// Creates an equal-angle Rose/Nightingale series.
  factory PolarColumnChartSeries.rose({
    required String id,
    String? name,
    required Map<String, num> values,
    Map<String, Color> columnColors = const {},
    Color? color,
    Map<String, dynamic>? metadata,
    String? unit,
    PolarColumnStyle polarStyle = const PolarColumnStyle(),
    RadialSelectionStyle selectionStyle = const RadialSelectionStyle(),
  }) => PolarColumnChartSeries._fromMap(
    id: id,
    name: name,
    values: values,
    columnColors: columnColors,
    color: color,
    metadata: metadata,
    unit: unit,
    preset: PolarColumnPreset.rose,
    polarStyle: polarStyle,
    selectionStyle: selectionStyle,
  );

  factory PolarColumnChartSeries._fromMap({
    required String id,
    required String? name,
    required Map<String, num> values,
    required Map<String, Color> columnColors,
    required Color? color,
    required Map<String, dynamic>? metadata,
    required String? unit,
    required PolarColumnPreset preset,
    required PolarColumnStyle polarStyle,
    required RadialSelectionStyle selectionStyle,
  }) {
    final points = <ChartDataPoint>[];
    for (final (index, entry) in values.entries.indexed) {
      final pointColor = columnColors[entry.key];
      points.add(
        ChartDataPoint(
          x: index.toDouble(),
          y: entry.value.toDouble(),
          label: entry.key,
          pointStyle: pointColor == null ? null : PointStyle.color(pointColor),
        ),
      );
    }
    return PolarColumnChartSeries(
      id: id,
      name: name,
      points: points,
      color: color,
      metadata: metadata,
      unit: unit,
      preset: preset,
      polarStyle: polarStyle,
      selectionStyle: selectionStyle,
    );
  }

  final PolarColumnPreset preset;
  final PolarColumnStyle polarStyle;
  final RadialSelectionStyle selectionStyle;

  List<String> get categories =>
      List<String>.unmodifiable(points.map((point) => point.label!));

  void _validate() {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Series ID cannot be blank');
    }
    if (points.isEmpty) {
      throw ArgumentError.value(
        points,
        'points',
        'Polar Column requires at least one category',
      );
    }
    final categories = <String>{};
    for (final (index, point) in points.indexed) {
      if (!point.x.isFinite || point.x != index.toDouble()) {
        throw ArgumentError.value(
          point.x,
          'points[$index].x',
          'Polar Column X values must be stable zero-based ordinals',
        );
      }
      if (!point.y.isFinite || point.y < 0) {
        throw ArgumentError.value(
          point.y,
          'points[$index].y',
          'Polar Column V1 values must be finite and non-negative',
        );
      }
      final category = point.label?.trim();
      if (category == null || category.isEmpty || !categories.add(category)) {
        throw ArgumentError.value(
          point.label,
          'points[$index].label',
          'Categories must be visible and unique',
        );
      }
    }
    polarStyle.validate();
  }

  @override
  PolarColumnChartSeries copyWith({
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
    PolarColumnPreset? preset,
    PolarColumnStyle? polarStyle,
    RadialSelectionStyle? selectionStyle,
  }) {
    if (style != null && style != SeriesStyle.polarColumn) {
      throw ArgumentError.value(
        style,
        'style',
        'Polar Column series style is fixed',
      );
    }
    if (isXOrdered == false) {
      throw ArgumentError.value(
        isXOrdered,
        'isXOrdered',
        'Polar category order must remain stable',
      );
    }
    if (annotations != null || yAxisId != null || yAxisConfig != null) {
      throw ArgumentError(
        'Polar Column uses its PolarChartConfig axes and does not support '
        'Cartesian series annotations',
      );
    }
    return PolarColumnChartSeries(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      color: color ?? this.color,
      metadata: metadata ?? this.metadata,
      unit: unit ?? this.unit,
      preset: preset ?? this.preset,
      polarStyle: polarStyle ?? this.polarStyle,
      selectionStyle: selectionStyle ?? this.selectionStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolarColumnChartSeries &&
          super == other &&
          preset == other.preset &&
          polarStyle == other.polarStyle &&
          selectionStyle == other.selectionStyle;

  @override
  int get hashCode =>
      Object.hash(super.hashCode, preset, polarStyle, selectionStyle);
}
