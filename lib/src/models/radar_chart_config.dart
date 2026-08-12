import 'dart:ui' show Color, Offset;

import 'package:flutter/foundation.dart';

import '../meta/chart_surface.dart';
import '../theming/components/series_theme.dart' show SeriesMarkerShape;
import 'polar_chart_config.dart';

/// Shape used to draw the shared radial grid.
enum RadarGridShape { polygon, circle }

/// Entrance treatment for Radar profiles.
enum RadarAnimationMode { none, radial, fade }

/// Shader geometry used to fill one Radar profile.
enum RadarGradientType { linear, radial }

/// Serializable gradient painted inside one Radar profile.
///
/// Null colors are derived from the series color so palette identity remains
/// intact when the same style is shared by several profiles.
@immutable
@chartSurface
class RadarGradientStyle {
  const RadarGradientStyle({
    this.enabled = true,
    this.type = RadarGradientType.radial,
    this.startColor,
    this.endColor,
    this.startLightnessShift = 0.2,
    this.endLightnessShift = -0.14,
    this.angleDegrees = 0,
  });

  final bool enabled;
  final RadarGradientType type;
  final Color? startColor;
  final Color? endColor;
  final double startLightnessShift;
  final double endLightnessShift;
  final double angleDegrees;

  void validate() {
    for (final (name, value) in <(String, double)>[
      ('startLightnessShift', startLightnessShift),
      ('endLightnessShift', endLightnessShift),
    ]) {
      if (!value.isFinite || value < -1 || value > 1) {
        throw ArgumentError.value(
          value,
          'radarStyle.gradient.$name',
          'Value must be finite and in [-1, 1]',
        );
      }
    }
    if (!angleDegrees.isFinite) {
      throw ArgumentError.value(
        angleDegrees,
        'radarStyle.gradient.angleDegrees',
        'Value must be finite',
      );
    }
  }

  RadarGradientStyle copyWith({
    bool? enabled,
    RadarGradientType? type,
    Color? startColor,
    bool clearStartColor = false,
    Color? endColor,
    bool clearEndColor = false,
    double? startLightnessShift,
    double? endLightnessShift,
    double? angleDegrees,
  }) => RadarGradientStyle(
    enabled: enabled ?? this.enabled,
    type: type ?? this.type,
    startColor: clearStartColor ? null : (startColor ?? this.startColor),
    endColor: clearEndColor ? null : (endColor ?? this.endColor),
    startLightnessShift: startLightnessShift ?? this.startLightnessShift,
    endLightnessShift: endLightnessShift ?? this.endLightnessShift,
    angleDegrees: angleDegrees ?? this.angleDegrees,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadarGradientStyle &&
          enabled == other.enabled &&
          type == other.type &&
          startColor == other.startColor &&
          endColor == other.endColor &&
          startLightnessShift == other.startLightnessShift &&
          endLightnessShift == other.endLightnessShift &&
          angleDegrees == other.angleDegrees;

  @override
  int get hashCode => Object.hash(
    enabled,
    type,
    startColor,
    endColor,
    startLightnessShift,
    endLightnessShift,
    angleDegrees,
  );
}

/// Blurred elevation painted beneath one Radar profile.
@immutable
@chartSurface
class RadarShadowStyle {
  const RadarShadowStyle({
    this.color,
    this.blurRadius = 0,
    this.spreadRadius = 0,
    this.offset = Offset.zero,
    this.opacity = 0.28,
  });

  final Color? color;
  final double blurRadius;
  final double spreadRadius;
  final Offset offset;
  final double opacity;

  bool get isVisible =>
      opacity > 0 &&
      (blurRadius > 0 || spreadRadius > 0 || offset != Offset.zero);

  void validate() {
    _nonNegative(blurRadius, 'radarStyle.shadow.blurRadius');
    _nonNegative(spreadRadius, 'radarStyle.shadow.spreadRadius');
    if (!offset.dx.isFinite || !offset.dy.isFinite) {
      throw ArgumentError.value(
        offset,
        'radarStyle.shadow.offset',
        'Components must be finite',
      );
    }
    _unit(opacity, 'radarStyle.shadow.opacity');
  }

  RadarShadowStyle copyWith({
    Color? color,
    bool clearColor = false,
    double? blurRadius,
    double? spreadRadius,
    Offset? offset,
    double? opacity,
  }) => RadarShadowStyle(
    color: clearColor ? null : (color ?? this.color),
    blurRadius: blurRadius ?? this.blurRadius,
    spreadRadius: spreadRadius ?? this.spreadRadius,
    offset: offset ?? this.offset,
    opacity: opacity ?? this.opacity,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadarShadowStyle &&
          color == other.color &&
          blurRadius == other.blurRadius &&
          spreadRadius == other.spreadRadius &&
          offset == other.offset &&
          opacity == other.opacity;

  @override
  int get hashCode =>
      Object.hash(color, blurRadius, spreadRadius, offset, opacity);
}

/// Independent appearance overrides for Radar rings, spokes, and boundary.
///
/// Null colors and widths inherit the active chart theme. Empty dash patterns
/// render solid lines; non-empty lists contain painted-gap pairs.
@immutable
@chartSurface
class RadarWebStyle {
  const RadarWebStyle({
    this.ringColor,
    this.ringWidth,
    this.ringDashPattern,
    this.spokeColor,
    this.spokeWidth,
    this.spokeDashPattern,
    this.boundaryColor,
    this.boundaryWidth,
    this.boundaryDashPattern,
  });

  final Color? ringColor;
  final double? ringWidth;
  final List<double>? ringDashPattern;
  final Color? spokeColor;
  final double? spokeWidth;
  final List<double>? spokeDashPattern;
  final Color? boundaryColor;
  final double? boundaryWidth;
  final List<double>? boundaryDashPattern;

  void validate() {
    if (ringWidth case final value?) {
      _positive(value, 'webStyle.ringWidth');
    }
    if (spokeWidth case final value?) {
      _positive(value, 'webStyle.spokeWidth');
    }
    if (boundaryWidth case final value?) {
      _positive(value, 'webStyle.boundaryWidth');
    }
    if (ringDashPattern case final values?) {
      _dashPattern(values, 'webStyle.ringDashPattern');
    }
    if (spokeDashPattern case final values?) {
      _dashPattern(values, 'webStyle.spokeDashPattern');
    }
    if (boundaryDashPattern case final values?) {
      _dashPattern(values, 'webStyle.boundaryDashPattern');
    }
  }

  RadarWebStyle copyWith({
    Color? ringColor,
    bool clearRingColor = false,
    double? ringWidth,
    bool clearRingWidth = false,
    List<double>? ringDashPattern,
    bool clearRingDashPattern = false,
    Color? spokeColor,
    bool clearSpokeColor = false,
    double? spokeWidth,
    bool clearSpokeWidth = false,
    List<double>? spokeDashPattern,
    bool clearSpokeDashPattern = false,
    Color? boundaryColor,
    bool clearBoundaryColor = false,
    double? boundaryWidth,
    bool clearBoundaryWidth = false,
    List<double>? boundaryDashPattern,
    bool clearBoundaryDashPattern = false,
  }) => RadarWebStyle(
    ringColor: clearRingColor ? null : (ringColor ?? this.ringColor),
    ringWidth: clearRingWidth ? null : (ringWidth ?? this.ringWidth),
    ringDashPattern: clearRingDashPattern
        ? null
        : (ringDashPattern ?? this.ringDashPattern),
    spokeColor: clearSpokeColor ? null : (spokeColor ?? this.spokeColor),
    spokeWidth: clearSpokeWidth ? null : (spokeWidth ?? this.spokeWidth),
    spokeDashPattern: clearSpokeDashPattern
        ? null
        : (spokeDashPattern ?? this.spokeDashPattern),
    boundaryColor: clearBoundaryColor
        ? null
        : (boundaryColor ?? this.boundaryColor),
    boundaryWidth: clearBoundaryWidth
        ? null
        : (boundaryWidth ?? this.boundaryWidth),
    boundaryDashPattern: clearBoundaryDashPattern
        ? null
        : (boundaryDashPattern ?? this.boundaryDashPattern),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadarWebStyle &&
          ringColor == other.ringColor &&
          ringWidth == other.ringWidth &&
          listEquals(ringDashPattern, other.ringDashPattern) &&
          spokeColor == other.spokeColor &&
          spokeWidth == other.spokeWidth &&
          listEquals(spokeDashPattern, other.spokeDashPattern) &&
          boundaryColor == other.boundaryColor &&
          boundaryWidth == other.boundaryWidth &&
          listEquals(boundaryDashPattern, other.boundaryDashPattern);

  @override
  int get hashCode => Object.hash(
    ringColor,
    ringWidth,
    ringDashPattern == null ? null : Object.hashAll(ringDashPattern!),
    spokeColor,
    spokeWidth,
    spokeDashPattern == null ? null : Object.hashAll(spokeDashPattern!),
    boundaryColor,
    boundaryWidth,
    boundaryDashPattern == null ? null : Object.hashAll(boundaryDashPattern!),
  );
}

/// Appearance of one Radar profile.
@immutable
@chartSurface
class RadarSeriesStyle {
  const RadarSeriesStyle({
    this.strokeWidth = 2,
    this.strokeOpacity = 1,
    this.strokeDashPattern = const <double>[],
    this.fillColor,
    this.fillOpacity = 0.12,
    this.gradient,
    this.shadow = const RadarShadowStyle(),
    this.showMarkers = true,
    this.markerShape = SeriesMarkerShape.circle,
    this.markerRadius = 3,
    this.markerFillColor,
    this.markerBorderColor,
    this.markerBorderWidth = 0,
    this.showDataLabels = false,
    this.maximumVisibleDataLabels = 24,
    this.dataLabelOffset = 8,
    this.dataLabelStyle = const PolarLabelStyle(),
    this.animationMode = RadarAnimationMode.none,
  });

  final double strokeWidth;
  final double strokeOpacity;
  final List<double> strokeDashPattern;
  final Color? fillColor;
  final double fillOpacity;
  final RadarGradientStyle? gradient;
  final RadarShadowStyle shadow;
  final bool showMarkers;
  final SeriesMarkerShape markerShape;
  final double markerRadius;
  final Color? markerFillColor;
  final Color? markerBorderColor;
  final double markerBorderWidth;
  final bool showDataLabels;
  final int maximumVisibleDataLabels;
  final double dataLabelOffset;
  final PolarLabelStyle dataLabelStyle;
  final RadarAnimationMode animationMode;

  void validate() {
    _positive(strokeWidth, 'radarStyle.strokeWidth');
    _unit(strokeOpacity, 'radarStyle.strokeOpacity');
    _unit(fillOpacity, 'radarStyle.fillOpacity');
    gradient?.validate();
    shadow.validate();
    _nonNegative(markerRadius, 'radarStyle.markerRadius');
    _nonNegative(markerBorderWidth, 'radarStyle.markerBorderWidth');
    if (maximumVisibleDataLabels < 1) {
      throw ArgumentError.value(
        maximumVisibleDataLabels,
        'radarStyle.maximumVisibleDataLabels',
        'Value must be positive',
      );
    }
    if (!dataLabelOffset.isFinite) {
      throw ArgumentError.value(
        dataLabelOffset,
        'radarStyle.dataLabelOffset',
        'Value must be finite',
      );
    }
    dataLabelStyle.validate(argumentName: 'radarStyle.dataLabelStyle');
    if (strokeDashPattern.length.isOdd) {
      throw ArgumentError.value(
        strokeDashPattern,
        'radarStyle.strokeDashPattern',
        'Dash patterns must contain painted-gap pairs',
      );
    }
    for (final (index, value) in strokeDashPattern.indexed) {
      _positive(value, 'radarStyle.strokeDashPattern[$index]');
    }
  }

  RadarSeriesStyle copyWith({
    double? strokeWidth,
    double? strokeOpacity,
    List<double>? strokeDashPattern,
    Color? fillColor,
    bool clearFillColor = false,
    double? fillOpacity,
    RadarGradientStyle? gradient,
    bool clearGradient = false,
    RadarShadowStyle? shadow,
    bool? showMarkers,
    SeriesMarkerShape? markerShape,
    double? markerRadius,
    Color? markerFillColor,
    bool clearMarkerFillColor = false,
    Color? markerBorderColor,
    bool clearMarkerBorderColor = false,
    double? markerBorderWidth,
    bool? showDataLabels,
    int? maximumVisibleDataLabels,
    double? dataLabelOffset,
    PolarLabelStyle? dataLabelStyle,
    RadarAnimationMode? animationMode,
  }) => RadarSeriesStyle(
    strokeWidth: strokeWidth ?? this.strokeWidth,
    strokeOpacity: strokeOpacity ?? this.strokeOpacity,
    strokeDashPattern: strokeDashPattern ?? this.strokeDashPattern,
    fillColor: clearFillColor ? null : (fillColor ?? this.fillColor),
    fillOpacity: fillOpacity ?? this.fillOpacity,
    gradient: clearGradient ? null : (gradient ?? this.gradient),
    shadow: shadow ?? this.shadow,
    showMarkers: showMarkers ?? this.showMarkers,
    markerShape: markerShape ?? this.markerShape,
    markerRadius: markerRadius ?? this.markerRadius,
    markerFillColor: clearMarkerFillColor
        ? null
        : (markerFillColor ?? this.markerFillColor),
    markerBorderColor: clearMarkerBorderColor
        ? null
        : (markerBorderColor ?? this.markerBorderColor),
    markerBorderWidth: markerBorderWidth ?? this.markerBorderWidth,
    showDataLabels: showDataLabels ?? this.showDataLabels,
    maximumVisibleDataLabels:
        maximumVisibleDataLabels ?? this.maximumVisibleDataLabels,
    dataLabelOffset: dataLabelOffset ?? this.dataLabelOffset,
    dataLabelStyle: dataLabelStyle ?? this.dataLabelStyle,
    animationMode: animationMode ?? this.animationMode,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadarSeriesStyle &&
          strokeWidth == other.strokeWidth &&
          strokeOpacity == other.strokeOpacity &&
          listEquals(strokeDashPattern, other.strokeDashPattern) &&
          fillColor == other.fillColor &&
          fillOpacity == other.fillOpacity &&
          gradient == other.gradient &&
          shadow == other.shadow &&
          showMarkers == other.showMarkers &&
          markerShape == other.markerShape &&
          markerRadius == other.markerRadius &&
          markerFillColor == other.markerFillColor &&
          markerBorderColor == other.markerBorderColor &&
          markerBorderWidth == other.markerBorderWidth &&
          showDataLabels == other.showDataLabels &&
          maximumVisibleDataLabels == other.maximumVisibleDataLabels &&
          dataLabelOffset == other.dataLabelOffset &&
          dataLabelStyle == other.dataLabelStyle &&
          animationMode == other.animationMode;

  @override
  int get hashCode => Object.hash(
    strokeWidth,
    strokeOpacity,
    Object.hashAll(strokeDashPattern),
    fillColor,
    fillOpacity,
    gradient,
    shadow,
    showMarkers,
    markerShape,
    markerRadius,
    markerFillColor,
    markerBorderColor,
    markerBorderWidth,
    showDataLabels,
    maximumVisibleDataLabels,
    dataLabelOffset,
    dataLabelStyle,
    animationMode,
  );
}

/// Category-axis presentation for Radar and Spider charts.
@immutable
@chartSurface
class RadarCategoryAxisConfig {
  const RadarCategoryAxisConfig({
    this.showLabels = true,
    this.showSpokes = true,
    this.maximumVisibleLabels = 24,
    this.labelOffset = 8,
    this.labelStyle = const PolarLabelStyle(),
  });

  final bool showLabels;
  final bool showSpokes;
  final int maximumVisibleLabels;
  final double labelOffset;
  final PolarLabelStyle labelStyle;

  void validate() {
    if (maximumVisibleLabels < 1) {
      throw ArgumentError.value(
        maximumVisibleLabels,
        'categoryAxis.maximumVisibleLabels',
        'Value must be positive',
      );
    }
    if (!labelOffset.isFinite) {
      throw ArgumentError.value(
        labelOffset,
        'categoryAxis.labelOffset',
        'Value must be finite',
      );
    }
    labelStyle.validate(argumentName: 'categoryAxis.labelStyle');
  }

  RadarCategoryAxisConfig copyWith({
    bool? showLabels,
    bool? showSpokes,
    int? maximumVisibleLabels,
    double? labelOffset,
    PolarLabelStyle? labelStyle,
  }) => RadarCategoryAxisConfig(
    showLabels: showLabels ?? this.showLabels,
    showSpokes: showSpokes ?? this.showSpokes,
    maximumVisibleLabels: maximumVisibleLabels ?? this.maximumVisibleLabels,
    labelOffset: labelOffset ?? this.labelOffset,
    labelStyle: labelStyle ?? this.labelStyle,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadarCategoryAxisConfig &&
          showLabels == other.showLabels &&
          showSpokes == other.showSpokes &&
          maximumVisibleLabels == other.maximumVisibleLabels &&
          labelOffset == other.labelOffset &&
          labelStyle == other.labelStyle;

  @override
  int get hashCode => Object.hash(
    showLabels,
    showSpokes,
    maximumVisibleLabels,
    labelOffset,
    labelStyle,
  );
}

/// Shared linear radial-axis presentation for Radar and Spider charts.
@immutable
@chartSurface
class RadarNumericAxisConfig {
  const RadarNumericAxisConfig({
    this.minimum = 0,
    this.maximum,
    this.tickCount = 5,
    this.showLabels = true,
    this.showGridLines = true,
    this.gridShape = RadarGridShape.polygon,
    this.labelPosition = PolarRadialLabelPosition.start,
    this.labelAngleOffsetDegrees = 0,
    this.labelOffset = 4,
    this.labelStyle = const PolarLabelStyle(fontSize: 10),
  });

  final double minimum;
  final double? maximum;
  final int tickCount;
  final bool showLabels;
  final bool showGridLines;
  final RadarGridShape gridShape;
  final PolarRadialLabelPosition labelPosition;
  final double labelAngleOffsetDegrees;
  final double labelOffset;
  final PolarLabelStyle labelStyle;

  void validate() {
    if (!minimum.isFinite || minimum < 0) {
      throw ArgumentError.value(
        minimum,
        'radialAxis.minimum',
        'Radar minimum must be finite and non-negative',
      );
    }
    if (maximum case final value? when !value.isFinite || value <= minimum) {
      throw ArgumentError.value(
        value,
        'radialAxis.maximum',
        'Maximum must be finite and greater than minimum',
      );
    }
    if (tickCount < 2 || tickCount > 12) {
      throw ArgumentError.value(
        tickCount,
        'radialAxis.tickCount',
        'Tick count must be between 2 and 12',
      );
    }
    if (!labelAngleOffsetDegrees.isFinite || !labelOffset.isFinite) {
      throw ArgumentError('Radar radial label offsets must be finite');
    }
    labelStyle.validate(argumentName: 'radialAxis.labelStyle');
  }

  RadarNumericAxisConfig copyWith({
    double? minimum,
    double? maximum,
    bool clearMaximum = false,
    int? tickCount,
    bool? showLabels,
    bool? showGridLines,
    RadarGridShape? gridShape,
    PolarRadialLabelPosition? labelPosition,
    double? labelAngleOffsetDegrees,
    double? labelOffset,
    PolarLabelStyle? labelStyle,
  }) => RadarNumericAxisConfig(
    minimum: minimum ?? this.minimum,
    maximum: clearMaximum ? null : (maximum ?? this.maximum),
    tickCount: tickCount ?? this.tickCount,
    showLabels: showLabels ?? this.showLabels,
    showGridLines: showGridLines ?? this.showGridLines,
    gridShape: gridShape ?? this.gridShape,
    labelPosition: labelPosition ?? this.labelPosition,
    labelAngleOffsetDegrees:
        labelAngleOffsetDegrees ?? this.labelAngleOffsetDegrees,
    labelOffset: labelOffset ?? this.labelOffset,
    labelStyle: labelStyle ?? this.labelStyle,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadarNumericAxisConfig &&
          minimum == other.minimum &&
          maximum == other.maximum &&
          tickCount == other.tickCount &&
          showLabels == other.showLabels &&
          showGridLines == other.showGridLines &&
          gridShape == other.gridShape &&
          labelPosition == other.labelPosition &&
          labelAngleOffsetDegrees == other.labelAngleOffsetDegrees &&
          labelOffset == other.labelOffset &&
          labelStyle == other.labelStyle;

  @override
  int get hashCode => Object.hash(
    minimum,
    maximum,
    tickCount,
    showLabels,
    showGridLines,
    gridShape,
    labelPosition,
    labelAngleOffsetDegrees,
    labelOffset,
    labelStyle,
  );
}

/// Plot-level contract for one full-circle Radar pane.
@immutable
@chartSurface
class RadarChartConfig {
  const RadarChartConfig({
    this.pane = const PolarPaneConfig(),
    this.categoryAxis = const RadarCategoryAxisConfig(),
    this.radialAxis = const RadarNumericAxisConfig(),
    this.webStyle = const RadarWebStyle(),
  });

  final PolarPaneConfig pane;
  final RadarCategoryAxisConfig categoryAxis;
  final RadarNumericAxisConfig radialAxis;
  final RadarWebStyle webStyle;

  void validate() {
    pane.validate();
    if ((pane.sweepAngleDegrees - 360).abs() > 1e-9) {
      throw ArgumentError.value(
        pane.sweepAngleDegrees,
        'pane.sweepAngleDegrees',
        'Radar V1 requires a full 360-degree pane',
      );
    }
    if (pane.innerRadiusFactor != 0) {
      throw ArgumentError.value(
        pane.innerRadiusFactor,
        'pane.innerRadiusFactor',
        'Radar V1 requires a zero inner radius',
      );
    }
    categoryAxis.validate();
    radialAxis.validate();
    webStyle.validate();
  }

  RadarChartConfig copyWith({
    PolarPaneConfig? pane,
    RadarCategoryAxisConfig? categoryAxis,
    RadarNumericAxisConfig? radialAxis,
    RadarWebStyle? webStyle,
  }) => RadarChartConfig(
    pane: pane ?? this.pane,
    categoryAxis: categoryAxis ?? this.categoryAxis,
    radialAxis: radialAxis ?? this.radialAxis,
    webStyle: webStyle ?? this.webStyle,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadarChartConfig &&
          pane == other.pane &&
          categoryAxis == other.categoryAxis &&
          radialAxis == other.radialAxis &&
          webStyle == other.webStyle;

  @override
  int get hashCode => Object.hash(pane, categoryAxis, radialAxis, webStyle);
}

void _dashPattern(List<double> values, String name) {
  if (values.length.isOdd) {
    throw ArgumentError.value(
      values,
      name,
      'Dash patterns must contain painted-gap pairs',
    );
  }
  for (final (index, value) in values.indexed) {
    _positive(value, '$name[$index]');
  }
}

void _positive(double value, String name) {
  if (!value.isFinite || value <= 0) {
    throw ArgumentError.value(value, name, 'Value must be finite and positive');
  }
}

void _nonNegative(double value, String name) {
  if (!value.isFinite || value < 0) {
    throw ArgumentError.value(
      value,
      name,
      'Value must be finite and non-negative',
    );
  }
}

void _unit(double value, String name) {
  if (!value.isFinite || value < 0 || value > 1) {
    throw ArgumentError.value(
      value,
      name,
      'Value must be finite and in [0, 1]',
    );
  }
}
