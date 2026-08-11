import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import '../meta/chart_surface.dart';
import 'polar_chart_config.dart';

/// Shape used to draw the shared radial grid.
enum RadarGridShape { polygon, circle }

/// Entrance treatment for Radar profiles.
enum RadarAnimationMode { none, radial, fade }

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
    this.showMarkers = true,
    this.markerRadius = 3,
    this.showDataLabels = false,
    this.animationMode = RadarAnimationMode.none,
  });

  final double strokeWidth;
  final double strokeOpacity;
  final List<double> strokeDashPattern;
  final Color? fillColor;
  final double fillOpacity;
  final bool showMarkers;
  final double markerRadius;
  final bool showDataLabels;
  final RadarAnimationMode animationMode;

  void validate() {
    _positive(strokeWidth, 'radarStyle.strokeWidth');
    _unit(strokeOpacity, 'radarStyle.strokeOpacity');
    _unit(fillOpacity, 'radarStyle.fillOpacity');
    _nonNegative(markerRadius, 'radarStyle.markerRadius');
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
    bool? showMarkers,
    double? markerRadius,
    bool? showDataLabels,
    RadarAnimationMode? animationMode,
  }) => RadarSeriesStyle(
    strokeWidth: strokeWidth ?? this.strokeWidth,
    strokeOpacity: strokeOpacity ?? this.strokeOpacity,
    strokeDashPattern: strokeDashPattern ?? this.strokeDashPattern,
    fillColor: clearFillColor ? null : (fillColor ?? this.fillColor),
    fillOpacity: fillOpacity ?? this.fillOpacity,
    showMarkers: showMarkers ?? this.showMarkers,
    markerRadius: markerRadius ?? this.markerRadius,
    showDataLabels: showDataLabels ?? this.showDataLabels,
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
          showMarkers == other.showMarkers &&
          markerRadius == other.markerRadius &&
          showDataLabels == other.showDataLabels &&
          animationMode == other.animationMode;

  @override
  int get hashCode => Object.hash(
    strokeWidth,
    strokeOpacity,
    Object.hashAll(strokeDashPattern),
    fillColor,
    fillOpacity,
    showMarkers,
    markerRadius,
    showDataLabels,
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
  });

  final PolarPaneConfig pane;
  final RadarCategoryAxisConfig categoryAxis;
  final RadarNumericAxisConfig radialAxis;

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
  }

  RadarChartConfig copyWith({
    PolarPaneConfig? pane,
    RadarCategoryAxisConfig? categoryAxis,
    RadarNumericAxisConfig? radialAxis,
  }) => RadarChartConfig(
    pane: pane ?? this.pane,
    categoryAxis: categoryAxis ?? this.categoryAxis,
    radialAxis: radialAxis ?? this.radialAxis,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadarChartConfig &&
          pane == other.pane &&
          categoryAxis == other.categoryAxis &&
          radialAxis == other.radialAxis;

  @override
  int get hashCode => Object.hash(pane, categoryAxis, radialAxis);
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
