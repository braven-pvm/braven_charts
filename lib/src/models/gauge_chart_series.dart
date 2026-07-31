import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show immutable, listEquals;

import '../meta/chart_surface.dart';
import 'chart_annotation.dart';
import 'chart_data_point.dart';
import 'chart_series.dart';
import 'y_axis_config.dart';

/// One operational band on a Gauge's explicit numeric domain.
///
/// Zones are interpreted as half-open `[from, to)` intervals. A zone ending
/// at the series maximum also owns that final endpoint.
@immutable
@chartSurface
class GaugeZone {
  const GaugeZone({
    required this.from,
    required this.to,
    required this.status,
    this.color,
  });

  final double from;
  final double to;
  final String status;
  final Color? color;

  bool contains(double value, {required double maximum}) =>
      value >= from && (value < to || (value == maximum && to == maximum));

  void validate({
    required double minimum,
    required double maximum,
    String argumentName = 'zone',
  }) {
    if (!from.isFinite || !to.isFinite || from >= to) {
      throw ArgumentError.value(
        '$from / $to',
        '$argumentName.from / to',
        'Bounds must be finite and from must be smaller than to',
      );
    }
    if (from < minimum || to > maximum) {
      throw ArgumentError.value(
        '$from / $to',
        '$argumentName.from / to',
        'Zone must stay inside the explicit Gauge domain',
      );
    }
    if (status.trim().isEmpty) {
      throw ArgumentError.value(
        status,
        '$argumentName.status',
        'Status must be visible text',
      );
    }
  }

  GaugeZone copyWith({
    double? from,
    double? to,
    String? status,
    Color? color,
    bool clearColor = false,
  }) => GaugeZone(
    from: from ?? this.from,
    to: to ?? this.to,
    status: status ?? this.status,
    color: clearColor ? null : (color ?? this.color),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GaugeZone &&
          from == other.from &&
          to == other.to &&
          status == other.status &&
          color == other.color;

  @override
  int get hashCode => Object.hash(from, to, status, color);
}

/// The one preferred or expected measurement on a Gauge.
@immutable
@chartSurface
class GaugeTarget {
  const GaugeTarget({
    required this.value,
    this.label,
    this.color,
    this.width = 3,
  });

  final double value;
  final String? label;
  final Color? color;
  final double width;

  void validate({
    required double minimum,
    required double maximum,
    String argumentName = 'target',
  }) {
    _validateReference(
      value: value,
      label: label,
      width: width,
      minimum: minimum,
      maximum: maximum,
      argumentName: argumentName,
    );
  }

  GaugeTarget copyWith({
    double? value,
    String? label,
    bool clearLabel = false,
    Color? color,
    bool clearColor = false,
    double? width,
  }) => GaugeTarget(
    value: value ?? this.value,
    label: clearLabel ? null : (label ?? this.label),
    color: clearColor ? null : (color ?? this.color),
    width: width ?? this.width,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GaugeTarget &&
          value == other.value &&
          label == other.label &&
          color == other.color &&
          width == other.width;

  @override
  int get hashCode => Object.hash(value, label, color, width);
}

/// One additional absolute reference on a Gauge domain.
@immutable
@chartSurface
class GaugeThreshold {
  const GaugeThreshold({
    required this.value,
    this.label,
    this.color,
    this.width = 1.5,
    this.dashPattern = const <double>[6, 4],
  });

  final double value;
  final String? label;
  final Color? color;
  final double width;
  final List<double> dashPattern;

  void validate({
    required double minimum,
    required double maximum,
    String argumentName = 'threshold',
  }) {
    _validateReference(
      value: value,
      label: label,
      width: width,
      minimum: minimum,
      maximum: maximum,
      argumentName: argumentName,
    );
    if (dashPattern.length.isOdd) {
      throw ArgumentError.value(
        dashPattern,
        '$argumentName.dashPattern',
        'Dash patterns must contain painted-gap pairs',
      );
    }
    for (final (index, interval) in dashPattern.indexed) {
      if (!interval.isFinite || interval <= 0) {
        throw ArgumentError.value(
          interval,
          '$argumentName.dashPattern[$index]',
          'Intervals must be finite and positive',
        );
      }
    }
  }

  GaugeThreshold copyWith({
    double? value,
    String? label,
    bool clearLabel = false,
    Color? color,
    bool clearColor = false,
    double? width,
    List<double>? dashPattern,
  }) => GaugeThreshold(
    value: value ?? this.value,
    label: clearLabel ? null : (label ?? this.label),
    color: clearColor ? null : (color ?? this.color),
    width: width ?? this.width,
    dashPattern: dashPattern ?? this.dashPattern,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GaugeThreshold &&
          value == other.value &&
          label == other.label &&
          color == other.color &&
          width == other.width &&
          listEquals(dashPattern, other.dashPattern);

  @override
  int get hashCode =>
      Object.hash(value, label, color, width, Object.hashAll(dashPattern));
}

/// Presentation boundary shared by needle and solid Gauge indicators.
@immutable
sealed class GaugeIndicatorStyle {
  const GaugeIndicatorStyle();

  void validate();
}

/// Direction used to shade a Solid Gauge progress arc.
enum GaugeGradientType {
  /// Follows the progress arc from the domain minimum towards the value.
  sweep,

  /// Runs across the arc thickness from the inner to the outer edge.
  radial,
}

/// Serializable gradient applied to a Solid Gauge progress arc.
///
/// Null colors are derived from the resolved indicator color so gradients
/// preserve theme and active-zone identity unless fixed colors are requested.
@immutable
@chartSurface
class GaugeGradientStyle {
  const GaugeGradientStyle({
    this.enabled = true,
    this.type = GaugeGradientType.sweep,
    this.startColor,
    this.endColor,
    this.startLightnessShift = 0.18,
    this.endLightnessShift = -0.12,
  });

  final bool enabled;
  final GaugeGradientType type;
  final Color? startColor;
  final Color? endColor;
  final double startLightnessShift;
  final double endLightnessShift;

  void validate() {
    for (final (name, value) in <(String, double)>[
      ('startLightnessShift', startLightnessShift),
      ('endLightnessShift', endLightnessShift),
    ]) {
      if (!value.isFinite || value < -1 || value > 1) {
        throw ArgumentError.value(
          value,
          'solidGaugeStyle.gradient.$name',
          'Value must be finite and in [-1, 1]',
        );
      }
    }
  }

  GaugeGradientStyle copyWith({
    bool? enabled,
    GaugeGradientType? type,
    Color? startColor,
    bool clearStartColor = false,
    Color? endColor,
    bool clearEndColor = false,
    double? startLightnessShift,
    double? endLightnessShift,
  }) => GaugeGradientStyle(
    enabled: enabled ?? this.enabled,
    type: type ?? this.type,
    startColor: clearStartColor ? null : (startColor ?? this.startColor),
    endColor: clearEndColor ? null : (endColor ?? this.endColor),
    startLightnessShift: startLightnessShift ?? this.startLightnessShift,
    endLightnessShift: endLightnessShift ?? this.endLightnessShift,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GaugeGradientStyle &&
          enabled == other.enabled &&
          type == other.type &&
          startColor == other.startColor &&
          endColor == other.endColor &&
          startLightnessShift == other.startLightnessShift &&
          endLightnessShift == other.endLightnessShift;

  @override
  int get hashCode => Object.hash(
    enabled,
    type,
    startColor,
    endColor,
    startLightnessShift,
    endLightnessShift,
  );
}

/// Needle, pivot, and passive axis appearance.
@immutable
@chartSurface
final class NeedleGaugeStyle extends GaugeIndicatorStyle {
  const NeedleGaugeStyle({
    this.needleLengthFactor = 0.88,
    this.needleWidth = 3,
    this.needleTipWidth = 0,
    this.needleColor,
    this.pivotRadius = 6,
    this.pivotColor,
    this.pivotBorderColor,
    this.pivotBorderWidth = 0,
    this.axisThickness = 12,
    this.axisColor,
    this.axisOpacity = 0.16,
  });

  final double needleLengthFactor;

  /// Width of the needle where it meets the pivot.
  final double needleWidth;

  /// Width of the needle tip. Zero preserves the original pointed triangle.
  final double needleTipWidth;
  final Color? needleColor;
  final double pivotRadius;
  final Color? pivotColor;
  final Color? pivotBorderColor;
  final double pivotBorderWidth;
  final double axisThickness;
  final Color? axisColor;
  final double axisOpacity;

  @override
  void validate() {
    _requireRange(
      needleLengthFactor,
      'needleGaugeStyle.needleLengthFactor',
      minimum: 0,
      maximum: 1,
      minimumInclusive: false,
    );
    _requirePositive(needleWidth, 'needleGaugeStyle.needleWidth');
    _requireNonNegative(needleTipWidth, 'needleGaugeStyle.needleTipWidth');
    if (needleTipWidth > needleWidth) {
      throw ArgumentError.value(
        needleTipWidth,
        'needleGaugeStyle.needleTipWidth',
        'Needle tip width cannot exceed its base width',
      );
    }
    _requireNonNegative(pivotRadius, 'needleGaugeStyle.pivotRadius');
    _requireNonNegative(pivotBorderWidth, 'needleGaugeStyle.pivotBorderWidth');
    _requirePositive(axisThickness, 'needleGaugeStyle.axisThickness');
    _requireRange(
      axisOpacity,
      'needleGaugeStyle.axisOpacity',
      minimum: 0,
      maximum: 1,
    );
  }

  NeedleGaugeStyle copyWith({
    double? needleLengthFactor,
    double? needleWidth,
    double? needleTipWidth,
    Color? needleColor,
    bool clearNeedleColor = false,
    double? pivotRadius,
    Color? pivotColor,
    bool clearPivotColor = false,
    Color? pivotBorderColor,
    bool clearPivotBorderColor = false,
    double? pivotBorderWidth,
    double? axisThickness,
    Color? axisColor,
    bool clearAxisColor = false,
    double? axisOpacity,
  }) => NeedleGaugeStyle(
    needleLengthFactor: needleLengthFactor ?? this.needleLengthFactor,
    needleWidth: needleWidth ?? this.needleWidth,
    needleTipWidth: needleTipWidth ?? this.needleTipWidth,
    needleColor: clearNeedleColor ? null : (needleColor ?? this.needleColor),
    pivotRadius: pivotRadius ?? this.pivotRadius,
    pivotColor: clearPivotColor ? null : (pivotColor ?? this.pivotColor),
    pivotBorderColor: clearPivotBorderColor
        ? null
        : (pivotBorderColor ?? this.pivotBorderColor),
    pivotBorderWidth: pivotBorderWidth ?? this.pivotBorderWidth,
    axisThickness: axisThickness ?? this.axisThickness,
    axisColor: clearAxisColor ? null : (axisColor ?? this.axisColor),
    axisOpacity: axisOpacity ?? this.axisOpacity,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NeedleGaugeStyle &&
          needleLengthFactor == other.needleLengthFactor &&
          needleWidth == other.needleWidth &&
          needleTipWidth == other.needleTipWidth &&
          needleColor == other.needleColor &&
          pivotRadius == other.pivotRadius &&
          pivotColor == other.pivotColor &&
          pivotBorderColor == other.pivotBorderColor &&
          pivotBorderWidth == other.pivotBorderWidth &&
          axisThickness == other.axisThickness &&
          axisColor == other.axisColor &&
          axisOpacity == other.axisOpacity;

  @override
  int get hashCode => Object.hash(
    needleLengthFactor,
    needleWidth,
    needleTipWidth,
    needleColor,
    pivotRadius,
    pivotColor,
    pivotBorderColor,
    pivotBorderWidth,
    axisThickness,
    axisColor,
    axisOpacity,
  );
}

/// Progress arc and passive track appearance.
@immutable
@chartSurface
final class SolidGaugeStyle extends GaugeIndicatorStyle {
  const SolidGaugeStyle({
    this.trackColor,
    this.trackOpacity = 0.14,
    this.cornerRadius = 8,
    this.borderColor,
    this.borderWidth = 0,
    this.opacity = 1,
    this.gradient,
  });

  final Color? trackColor;
  final double trackOpacity;
  final double cornerRadius;
  final Color? borderColor;
  final double borderWidth;
  final double opacity;
  final GaugeGradientStyle? gradient;

  @override
  void validate() {
    _requireRange(
      trackOpacity,
      'solidGaugeStyle.trackOpacity',
      minimum: 0,
      maximum: 1,
    );
    _requireNonNegative(cornerRadius, 'solidGaugeStyle.cornerRadius');
    _requireNonNegative(borderWidth, 'solidGaugeStyle.borderWidth');
    _requireRange(opacity, 'solidGaugeStyle.opacity', minimum: 0, maximum: 1);
    gradient?.validate();
  }

  SolidGaugeStyle copyWith({
    Color? trackColor,
    bool clearTrackColor = false,
    double? trackOpacity,
    double? cornerRadius,
    Color? borderColor,
    bool clearBorderColor = false,
    double? borderWidth,
    double? opacity,
    GaugeGradientStyle? gradient,
    bool clearGradient = false,
  }) => SolidGaugeStyle(
    trackColor: clearTrackColor ? null : (trackColor ?? this.trackColor),
    trackOpacity: trackOpacity ?? this.trackOpacity,
    cornerRadius: cornerRadius ?? this.cornerRadius,
    borderColor: clearBorderColor ? null : (borderColor ?? this.borderColor),
    borderWidth: borderWidth ?? this.borderWidth,
    opacity: opacity ?? this.opacity,
    gradient: clearGradient ? null : (gradient ?? this.gradient),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SolidGaugeStyle &&
          trackColor == other.trackColor &&
          trackOpacity == other.trackOpacity &&
          cornerRadius == other.cornerRadius &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          opacity == other.opacity &&
          gradient == other.gradient;

  @override
  int get hashCode => Object.hash(
    trackColor,
    trackOpacity,
    cornerRadius,
    borderColor,
    borderWidth,
    opacity,
    gradient,
  );
}

/// One operational measurement rendered as a needle or solid Gauge.
///
/// Gauge owns one canonical compatibility point at x=0. Public authors use
/// [metric] and [value]; they do not provide a category or points collection.
@ChartSurface(
  excluded: ['id'],
  bodyValidated: [
    BodyValidated(
      '_validate() enforces the complete Gauge domain, zone, target, '
      'threshold, and indicator-style contract after every reconstruction.',
    ),
  ],
)
class GaugeChartSeries extends ChartSeries {
  GaugeChartSeries({
    required super.id,
    super.name,
    required this.metric,
    required double value,
    required this.minimum,
    required this.maximum,
    super.color,
    super.metadata,
    super.unit,
    super.showInLegend,
    super.showTrackingAxisLabel,
    super.showInTrackingTooltip,
    required this.indicatorStyle,
    this.target,
    List<GaugeZone> zones = const [],
    List<GaugeThreshold> thresholds = const [],
  }) : zones = List<GaugeZone>.unmodifiable(zones),
       thresholds = List<GaugeThreshold>.unmodifiable(thresholds),
       super(
         points: <ChartDataPoint>[
           ChartDataPoint(x: 0, y: value, label: metric),
         ],
         style: SeriesStyle.gauge,
         isXOrdered: true,
       ) {
    _validate();
  }

  factory GaugeChartSeries.needle({
    required String id,
    String? name,
    required String metric,
    required double value,
    required double minimum,
    required double maximum,
    Color? color,
    Map<String, dynamic>? metadata,
    String? unit,
    bool showInLegend = true,
    bool showTrackingAxisLabel = true,
    bool showInTrackingTooltip = true,
    GaugeTarget? target,
    List<GaugeZone> zones = const [],
    List<GaugeThreshold> thresholds = const [],
    NeedleGaugeStyle style = const NeedleGaugeStyle(),
  }) => GaugeChartSeries(
    id: id,
    name: name,
    metric: metric,
    value: value,
    minimum: minimum,
    maximum: maximum,
    color: color,
    metadata: metadata,
    unit: unit,
    showInLegend: showInLegend,
    showTrackingAxisLabel: showTrackingAxisLabel,
    showInTrackingTooltip: showInTrackingTooltip,
    target: target,
    zones: zones,
    thresholds: thresholds,
    indicatorStyle: style,
  );

  factory GaugeChartSeries.solid({
    required String id,
    String? name,
    required String metric,
    required double value,
    required double minimum,
    required double maximum,
    Color? color,
    Map<String, dynamic>? metadata,
    String? unit,
    bool showInLegend = true,
    bool showTrackingAxisLabel = true,
    bool showInTrackingTooltip = true,
    GaugeTarget? target,
    List<GaugeZone> zones = const [],
    List<GaugeThreshold> thresholds = const [],
    SolidGaugeStyle style = const SolidGaugeStyle(),
  }) => GaugeChartSeries(
    id: id,
    name: name,
    metric: metric,
    value: value,
    minimum: minimum,
    maximum: maximum,
    color: color,
    metadata: metadata,
    unit: unit,
    showInLegend: showInLegend,
    showTrackingAxisLabel: showTrackingAxisLabel,
    showInTrackingTooltip: showInTrackingTooltip,
    target: target,
    zones: zones,
    thresholds: thresholds,
    indicatorStyle: style,
  );

  final String metric;
  final double minimum;
  final double maximum;
  final GaugeIndicatorStyle indicatorStyle;
  final GaugeTarget? target;
  final List<GaugeZone> zones;
  final List<GaugeThreshold> thresholds;

  double get value => points.single.y;
  double get normalizedProgress => (value - minimum) / (maximum - minimum);

  GaugeZone? get activeZone {
    for (final zone in zones) {
      if (zone.contains(value, maximum: maximum)) return zone;
    }
    return null;
  }

  String? get status => activeZone?.status;

  void _validate() {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Series ID cannot be blank');
    }
    if (metric.trim().isEmpty) {
      throw ArgumentError.value(
        metric,
        'metric',
        'Metric must be visible text',
      );
    }
    if (!minimum.isFinite || !maximum.isFinite || minimum >= maximum) {
      throw ArgumentError.value(
        '$minimum / $maximum',
        'minimum / maximum',
        'Bounds must be finite and maximum must be greater than minimum',
      );
    }
    if (!value.isFinite || value < minimum || value > maximum) {
      throw ArgumentError.value(
        value,
        'value',
        'Measurement must be finite and inside the explicit domain',
      );
    }
    GaugeZone? previous;
    for (final (index, zone) in zones.indexed) {
      zone.validate(
        minimum: minimum,
        maximum: maximum,
        argumentName: 'zones[$index]',
      );
      if (previous != null && zone.from < previous.to) {
        throw ArgumentError.value(
          zone.from,
          'zones[$index].from',
          'Zones must be declared in ascending non-overlapping order',
        );
      }
      previous = zone;
    }
    target?.validate(minimum: minimum, maximum: maximum);
    for (final (index, threshold) in thresholds.indexed) {
      threshold.validate(
        minimum: minimum,
        maximum: maximum,
        argumentName: 'thresholds[$index]',
      );
    }
    indicatorStyle.validate();
  }

  @override
  GaugeChartSeries copyWith({
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
    bool clearYAxisId = false,
    YAxisConfig? yAxisConfig,
    bool clearYAxisConfig = false,
    String? unit,
    bool clearUnit = false,
    bool? showInLegend,
    bool? showTrackingAxisLabel,
    bool? showInTrackingTooltip,
    String? metric,
    double? value,
    double? minimum,
    double? maximum,
    GaugeIndicatorStyle? indicatorStyle,
    GaugeTarget? target,
    bool clearTarget = false,
    List<GaugeZone>? zones,
    bool clearZones = false,
    List<GaugeThreshold>? thresholds,
    bool clearThresholds = false,
  }) {
    if (points != null) {
      throw ArgumentError(
        'Gauge owns one canonical point; use metric and value instead',
      );
    }
    if (style != null && style != SeriesStyle.gauge) {
      throw ArgumentError.value(style, 'style', 'Gauge series style is fixed');
    }
    if (isXOrdered == false) {
      throw ArgumentError.value(
        isXOrdered,
        'isXOrdered',
        'Gauge canonical point order is fixed',
      );
    }
    if (annotations != null ||
        yAxisId != null ||
        clearYAxisId ||
        yAxisConfig != null ||
        clearYAxisConfig) {
      throw ArgumentError(
        'Gauge owns its indicator scale and does not support Cartesian '
        'series annotations or Y axes',
      );
    }
    return GaugeChartSeries(
      id: id ?? this.id,
      name: clearName ? null : (name ?? this.name),
      metric: metric ?? this.metric,
      value: value ?? this.value,
      minimum: minimum ?? this.minimum,
      maximum: maximum ?? this.maximum,
      color: clearColor ? null : (color ?? this.color),
      metadata: clearMetadata ? null : (metadata ?? this.metadata),
      unit: clearUnit ? null : (unit ?? this.unit),
      showInLegend: showInLegend ?? this.showInLegend,
      showTrackingAxisLabel:
          showTrackingAxisLabel ?? this.showTrackingAxisLabel,
      showInTrackingTooltip:
          showInTrackingTooltip ?? this.showInTrackingTooltip,
      indicatorStyle: indicatorStyle ?? this.indicatorStyle,
      target: clearTarget ? null : (target ?? this.target),
      zones: clearZones ? const [] : (zones ?? this.zones),
      thresholds: clearThresholds ? const [] : (thresholds ?? this.thresholds),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GaugeChartSeries &&
          super == other &&
          metric == other.metric &&
          minimum == other.minimum &&
          maximum == other.maximum &&
          indicatorStyle == other.indicatorStyle &&
          target == other.target &&
          listEquals(zones, other.zones) &&
          listEquals(thresholds, other.thresholds);

  @override
  int get hashCode => Object.hash(
    super.hashCode,
    metric,
    minimum,
    maximum,
    indicatorStyle,
    target,
    Object.hashAll(zones),
    Object.hashAll(thresholds),
  );
}

void _validateReference({
  required double value,
  required String? label,
  required double width,
  required double minimum,
  required double maximum,
  required String argumentName,
}) {
  if (!value.isFinite || value < minimum || value > maximum) {
    throw ArgumentError.value(
      value,
      '$argumentName.value',
      'Value must be finite and inside the explicit Gauge domain',
    );
  }
  if (label != null && label.trim().isEmpty) {
    throw ArgumentError.value(
      label,
      '$argumentName.label',
      'Label must be null or visible text',
    );
  }
  _requirePositive(width, '$argumentName.width');
}

void _requirePositive(double value, String argumentName) {
  if (!value.isFinite || value <= 0) {
    throw ArgumentError.value(
      value,
      argumentName,
      'Value must be finite and positive',
    );
  }
}

void _requireNonNegative(double value, String argumentName) {
  if (!value.isFinite || value < 0) {
    throw ArgumentError.value(
      value,
      argumentName,
      'Value must be finite and non-negative',
    );
  }
}

void _requireRange(
  double value,
  String argumentName, {
  required double minimum,
  required double maximum,
  bool minimumInclusive = true,
  bool maximumInclusive = true,
}) {
  final below = minimumInclusive ? value < minimum : value <= minimum;
  final above = maximumInclusive ? value > maximum : value >= maximum;
  if (!value.isFinite || below || above) {
    final left = minimumInclusive ? '[' : '(';
    final right = maximumInclusive ? ']' : ')';
    throw ArgumentError.value(
      value,
      argumentName,
      'Value must be finite and in $left$minimum, $maximum$right',
    );
  }
}
