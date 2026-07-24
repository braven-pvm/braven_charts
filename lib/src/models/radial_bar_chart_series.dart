import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show immutable;

import '../meta/chart_surface.dart';
import 'chart_annotation.dart';
import 'chart_data_point.dart';
import 'chart_series.dart';
import 'radial_selection_style.dart';
import 'segment_style.dart';
import 'y_axis_config.dart';

/// Appearance of Radial Bar marks and their background category tracks.
@immutable
@chartSurface
class RadialBarStyle {
  const RadialBarStyle({
    this.cornerRadius = 8,
    this.opacity = 1,
    this.borderColor,
    this.borderWidth = 0,
    this.trackColor,
    this.trackOpacity = 0.12,
    this.showDataLabels = true,
  });

  final double cornerRadius;
  final double opacity;
  final Color? borderColor;
  final double borderWidth;
  final Color? trackColor;
  final double trackOpacity;
  final bool showDataLabels;

  void validate() {
    if (!cornerRadius.isFinite || cornerRadius < 0) {
      throw ArgumentError.value(
        cornerRadius,
        'radialBarStyle.cornerRadius',
        'Value must be finite and non-negative',
      );
    }
    if (!opacity.isFinite || opacity < 0 || opacity > 1) {
      throw ArgumentError.value(
        opacity,
        'radialBarStyle.opacity',
        'Value must be finite and in [0, 1]',
      );
    }
    if (!borderWidth.isFinite || borderWidth < 0) {
      throw ArgumentError.value(
        borderWidth,
        'radialBarStyle.borderWidth',
        'Value must be finite and non-negative',
      );
    }
    if (!trackOpacity.isFinite || trackOpacity < 0 || trackOpacity > 1) {
      throw ArgumentError.value(
        trackOpacity,
        'radialBarStyle.trackOpacity',
        'Value must be finite and in [0, 1]',
      );
    }
  }

  RadialBarStyle copyWith({
    double? cornerRadius,
    double? opacity,
    Color? borderColor,
    bool clearBorderColor = false,
    double? borderWidth,
    Color? trackColor,
    bool clearTrackColor = false,
    double? trackOpacity,
    bool? showDataLabels,
  }) => RadialBarStyle(
    cornerRadius: cornerRadius ?? this.cornerRadius,
    opacity: opacity ?? this.opacity,
    borderColor: clearBorderColor ? null : (borderColor ?? this.borderColor),
    borderWidth: borderWidth ?? this.borderWidth,
    trackColor: clearTrackColor ? null : (trackColor ?? this.trackColor),
    trackOpacity: trackOpacity ?? this.trackOpacity,
    showDataLabels: showDataLabels ?? this.showDataLabels,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadialBarStyle &&
          cornerRadius == other.cornerRadius &&
          opacity == other.opacity &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          trackColor == other.trackColor &&
          trackOpacity == other.trackOpacity &&
          showDataLabels == other.showDataLabels;

  @override
  int get hashCode => Object.hash(
    cornerRadius,
    opacity,
    borderColor,
    borderWidth,
    trackColor,
    trackOpacity,
    showDataLabels,
  );
}

/// One category-track Radial Bar series.
///
/// Category identity follows stable declaration order. Values map to angular
/// sweep inside the explicit [minimum], [maximum], and [baseline] domain.
/// Values are never normalized into shares unless the caller explicitly
/// supplies percentage data and labels it as such.
@ChartSurface(
  excluded: ['id', 'points'],
  bodyValidated: [
    BodyValidated(
      '_validate() re-runs radialBarStyle.validate() on every construction, '
      'so withRadialBarStyle rejects a nested style that is invalid in this '
      'series.',
    ),
  ],
)
class RadialBarChartSeries extends ChartSeries {
  RadialBarChartSeries({
    required super.id,
    super.name,
    required super.points,
    super.color,
    super.metadata,
    super.unit,
    this.minimum = 0,
    this.maximum = 100,
    this.baseline = 0,
    this.radialBarStyle = const RadialBarStyle(),
    this.selectionStyle = const RadialSelectionStyle(),
  }) : super(style: SeriesStyle.radialBar, isXOrdered: true) {
    _validate();
  }

  /// Creates stable ordinal points from insertion-ordered categories.
  factory RadialBarChartSeries.fromMap({
    required String id,
    String? name,
    required Map<String, num> values,
    Map<String, Color> barColors = const {},
    Color? color,
    Map<String, dynamic>? metadata,
    String? unit,
    double minimum = 0,
    double maximum = 100,
    double baseline = 0,
    RadialBarStyle radialBarStyle = const RadialBarStyle(),
    RadialSelectionStyle selectionStyle = const RadialSelectionStyle(),
  }) => RadialBarChartSeries(
    id: id,
    name: name,
    points: [
      for (final (index, entry) in values.entries.indexed)
        ChartDataPoint(
          x: index.toDouble(),
          y: entry.value.toDouble(),
          label: entry.key,
          pointStyle: barColors[entry.key] == null
              ? null
              : PointStyle.color(barColors[entry.key]!),
        ),
    ],
    color: color,
    metadata: metadata,
    unit: unit,
    minimum: minimum,
    maximum: maximum,
    baseline: baseline,
    radialBarStyle: radialBarStyle,
    selectionStyle: selectionStyle,
  );

  /// Explicit minimum on the angular numeric scale.
  final double minimum;

  /// Explicit maximum on the angular numeric scale.
  final double maximum;

  /// Absolute value from which every category mark begins.
  final double baseline;

  final RadialBarStyle radialBarStyle;
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
        'Radial Bar requires at least one category',
      );
    }
    if (!minimum.isFinite || !maximum.isFinite || minimum >= maximum) {
      throw ArgumentError.value(
        '$minimum / $maximum',
        'minimum / maximum',
        'Bounds must be finite and maximum must be greater than minimum',
      );
    }
    if (!baseline.isFinite || baseline < minimum || baseline > maximum) {
      throw ArgumentError.value(
        baseline,
        'baseline',
        'Baseline must be finite and inside the explicit domain',
      );
    }
    final categories = <String>{};
    for (final (index, point) in points.indexed) {
      if (!point.x.isFinite || point.x != index.toDouble()) {
        throw ArgumentError.value(
          point.x,
          'points[$index].x',
          'Radial Bar X values must be stable zero-based ordinals',
        );
      }
      if (!point.y.isFinite || point.y < minimum || point.y > maximum) {
        throw ArgumentError.value(
          point.y,
          'points[$index].y',
          'Radial Bar values must be finite and inside the explicit domain',
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
    radialBarStyle.validate();
  }

  @override
  RadialBarChartSeries copyWith({
    String? id,
    String? name,
    bool clearName = false,
    List<ChartDataPoint>? points,
    Color? color,
    bool clearColor = false,
    SeriesStyle? style,
    bool? isXOrdered,
    Map<String, dynamic>? metadata,
    bool clearMetadata = false,
    List<ChartAnnotation>? annotations,
    String? yAxisId,
    YAxisConfig? yAxisConfig,
    String? unit,
    bool clearUnit = false,
    double? minimum,
    double? maximum,
    double? baseline,
    RadialBarStyle? radialBarStyle,
    RadialSelectionStyle? selectionStyle,
  }) {
    if (style != null && style != SeriesStyle.radialBar) {
      throw ArgumentError.value(
        style,
        'style',
        'Radial Bar series style is fixed',
      );
    }
    if (isXOrdered == false) {
      throw ArgumentError.value(
        isXOrdered,
        'isXOrdered',
        'Radial Bar category order must remain stable',
      );
    }
    if (annotations != null || yAxisId != null || yAxisConfig != null) {
      throw ArgumentError(
        'Radial Bar owns its angular numeric scale and does not support '
        'Cartesian series annotations or Y axes',
      );
    }
    return RadialBarChartSeries(
      id: id ?? this.id,
      name: clearName ? null : (name ?? this.name),
      points: points ?? this.points,
      color: clearColor ? null : (color ?? this.color),
      metadata: clearMetadata ? null : (metadata ?? this.metadata),
      unit: clearUnit ? null : (unit ?? this.unit),
      minimum: minimum ?? this.minimum,
      maximum: maximum ?? this.maximum,
      baseline: baseline ?? this.baseline,
      radialBarStyle: radialBarStyle ?? this.radialBarStyle,
      selectionStyle: selectionStyle ?? this.selectionStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadialBarChartSeries &&
          super == other &&
          minimum == other.minimum &&
          maximum == other.maximum &&
          baseline == other.baseline &&
          radialBarStyle == other.radialBarStyle &&
          selectionStyle == other.selectionStyle;

  @override
  int get hashCode => Object.hash(
    super.hashCode,
    minimum,
    maximum,
    baseline,
    radialBarStyle,
    selectionStyle,
  );
}
