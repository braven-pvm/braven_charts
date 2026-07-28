import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/widgets.dart' show FontWeight;

import '../meta/chart_surface.dart';
import 'polar_chart_config.dart';

/// Portable center-label configuration for Gauge artifacts and previews.
@immutable
@chartSurface
class GaugeCenterConfig {
  const GaugeCenterConfig({
    this.showMetric = true,
    this.showValue = true,
    this.showTarget = false,
    this.showStatus = true,
    this.metricStyle = const PolarLabelStyle(),
    this.valueStyle = const PolarLabelStyle(),
    this.targetStyle = const PolarLabelStyle(),
    this.statusStyle = const PolarLabelStyle(),
    this.horizontalOffset = 0,
    this.verticalOffset = 0,
    this.lineSpacing = 3,
  });

  final bool showMetric;
  final bool showValue;
  final bool showTarget;
  final bool showStatus;
  final PolarLabelStyle metricStyle;
  final PolarLabelStyle valueStyle;
  final PolarLabelStyle targetStyle;
  final PolarLabelStyle statusStyle;
  final double horizontalOffset;
  final double verticalOffset;
  final double lineSpacing;

  void validate() {
    metricStyle.validate(argumentName: 'center.metricStyle');
    valueStyle.validate(argumentName: 'center.valueStyle');
    targetStyle.validate(argumentName: 'center.targetStyle');
    statusStyle.validate(argumentName: 'center.statusStyle');
    _requireFinite(horizontalOffset, 'center.horizontalOffset');
    _requireFinite(verticalOffset, 'center.verticalOffset');
    _requireNonNegative(lineSpacing, 'center.lineSpacing');
  }

  GaugeCenterConfig copyWith({
    bool? showMetric,
    bool? showValue,
    bool? showTarget,
    bool? showStatus,
    PolarLabelStyle? metricStyle,
    PolarLabelStyle? valueStyle,
    PolarLabelStyle? targetStyle,
    PolarLabelStyle? statusStyle,
    double? horizontalOffset,
    double? verticalOffset,
    double? lineSpacing,
  }) => GaugeCenterConfig(
    showMetric: showMetric ?? this.showMetric,
    showValue: showValue ?? this.showValue,
    showTarget: showTarget ?? this.showTarget,
    showStatus: showStatus ?? this.showStatus,
    metricStyle: metricStyle ?? this.metricStyle,
    valueStyle: valueStyle ?? this.valueStyle,
    targetStyle: targetStyle ?? this.targetStyle,
    statusStyle: statusStyle ?? this.statusStyle,
    horizontalOffset: horizontalOffset ?? this.horizontalOffset,
    verticalOffset: verticalOffset ?? this.verticalOffset,
    lineSpacing: lineSpacing ?? this.lineSpacing,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GaugeCenterConfig &&
          showMetric == other.showMetric &&
          showValue == other.showValue &&
          showTarget == other.showTarget &&
          showStatus == other.showStatus &&
          metricStyle == other.metricStyle &&
          valueStyle == other.valueStyle &&
          targetStyle == other.targetStyle &&
          statusStyle == other.statusStyle &&
          horizontalOffset == other.horizontalOffset &&
          verticalOffset == other.verticalOffset &&
          lineSpacing == other.lineSpacing;

  @override
  int get hashCode => Object.hash(
    showMetric,
    showValue,
    showTarget,
    showStatus,
    metricStyle,
    valueStyle,
    targetStyle,
    statusStyle,
    horizontalOffset,
    verticalOffset,
    lineSpacing,
  );
}

/// Tick and numeric scale-label presentation for one Gauge pane.
///
/// Null colors inherit the active chart theme. The geometry values are logical
/// pixels and therefore remain stable across artifact hydration and generated
/// Dart source.
@immutable
@chartSurface
class GaugeScaleStyle {
  const GaugeScaleStyle({
    this.tickColor,
    this.tickWidth,
    this.tickLength,
    this.labelStyle = const PolarLabelStyle(fontSize: 9),
    this.labelOffset = 10,
    this.labelMaxWidth = 72,
  });

  final Color? tickColor;

  /// Null inherits [AxisStyle.tickWidth] from the active chart theme.
  final double? tickWidth;

  /// Null inherits [AxisStyle.tickLength] from the active chart theme.
  final double? tickLength;

  final PolarLabelStyle labelStyle;

  /// Edge-to-edge radial gap from the outer tick endpoint to the nearest
  /// scale-label edge.
  ///
  /// A value of zero keeps the label touching the endpoint without centering
  /// the label over the tick or Gauge arc.
  final double labelOffset;
  final double labelMaxWidth;

  void validate() {
    if (tickWidth case final value?) {
      _requirePositive(value, 'scale.tickWidth');
    }
    if (tickLength case final value?) {
      _requireNonNegative(value, 'scale.tickLength');
    }
    labelStyle.validate(argumentName: 'scale.labelStyle');
    _requireNonNegative(labelOffset, 'scale.labelOffset');
    _requirePositive(labelMaxWidth, 'scale.labelMaxWidth');
  }

  GaugeScaleStyle copyWith({
    Color? tickColor,
    bool clearTickColor = false,
    double? tickWidth,
    bool clearTickWidth = false,
    double? tickLength,
    bool clearTickLength = false,
    PolarLabelStyle? labelStyle,
    double? labelOffset,
    double? labelMaxWidth,
  }) => GaugeScaleStyle(
    tickColor: clearTickColor ? null : (tickColor ?? this.tickColor),
    tickWidth: clearTickWidth ? null : (tickWidth ?? this.tickWidth),
    tickLength: clearTickLength ? null : (tickLength ?? this.tickLength),
    labelStyle: labelStyle ?? this.labelStyle,
    labelOffset: labelOffset ?? this.labelOffset,
    labelMaxWidth: labelMaxWidth ?? this.labelMaxWidth,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GaugeScaleStyle &&
          tickColor == other.tickColor &&
          tickWidth == other.tickWidth &&
          tickLength == other.tickLength &&
          labelStyle == other.labelStyle &&
          labelOffset == other.labelOffset &&
          labelMaxWidth == other.labelMaxWidth;

  @override
  int get hashCode => Object.hash(
    tickColor,
    tickWidth,
    tickLength,
    labelStyle,
    labelOffset,
    labelMaxWidth,
  );
}

/// Shared outside-label and radial-callout presentation for Gauge references.
///
/// Target and threshold stroke colors and widths remain owned by
/// [GaugeTarget] and [GaugeThreshold]. This config controls where those
/// reference lines begin/end and how their optional labels are presented.
@immutable
@chartSurface
class GaugeReferenceStyle {
  const GaugeReferenceStyle({
    this.showLabels = true,
    this.innerLineOffset = 4,
    this.outerLineOffset = 6,
    this.labelStyle = const PolarLabelStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
    ),
    this.labelOffset = 8,
    this.labelMaxWidth = 100,
    this.showLabelPanel = false,
    this.panelColor,
    this.panelBorderColor,
    this.panelBorderWidth = 1,
    this.panelBorderRadius = 4,
    this.panelPadding = 4,
  });

  final bool showLabels;
  final double innerLineOffset;
  final double outerLineOffset;
  final PolarLabelStyle labelStyle;

  /// Edge-to-edge radial gap from the reference-line endpoint to the nearest
  /// label or label-panel edge.
  ///
  /// A value of zero keeps the label touching the line endpoint without
  /// centering the label over the Gauge pane.
  final double labelOffset;
  final double labelMaxWidth;
  final bool showLabelPanel;
  final Color? panelColor;
  final Color? panelBorderColor;
  final double panelBorderWidth;
  final double panelBorderRadius;
  final double panelPadding;

  void validate() {
    _requireNonNegative(innerLineOffset, 'references.innerLineOffset');
    _requireNonNegative(outerLineOffset, 'references.outerLineOffset');
    labelStyle.validate(argumentName: 'references.labelStyle');
    _requireNonNegative(labelOffset, 'references.labelOffset');
    _requirePositive(labelMaxWidth, 'references.labelMaxWidth');
    _requireNonNegative(panelBorderWidth, 'references.panelBorderWidth');
    _requireNonNegative(panelBorderRadius, 'references.panelBorderRadius');
    _requireNonNegative(panelPadding, 'references.panelPadding');
  }

  GaugeReferenceStyle copyWith({
    bool? showLabels,
    double? innerLineOffset,
    double? outerLineOffset,
    PolarLabelStyle? labelStyle,
    double? labelOffset,
    double? labelMaxWidth,
    bool? showLabelPanel,
    Color? panelColor,
    bool clearPanelColor = false,
    Color? panelBorderColor,
    bool clearPanelBorderColor = false,
    double? panelBorderWidth,
    double? panelBorderRadius,
    double? panelPadding,
  }) => GaugeReferenceStyle(
    showLabels: showLabels ?? this.showLabels,
    innerLineOffset: innerLineOffset ?? this.innerLineOffset,
    outerLineOffset: outerLineOffset ?? this.outerLineOffset,
    labelStyle: labelStyle ?? this.labelStyle,
    labelOffset: labelOffset ?? this.labelOffset,
    labelMaxWidth: labelMaxWidth ?? this.labelMaxWidth,
    showLabelPanel: showLabelPanel ?? this.showLabelPanel,
    panelColor: clearPanelColor ? null : (panelColor ?? this.panelColor),
    panelBorderColor: clearPanelBorderColor
        ? null
        : (panelBorderColor ?? this.panelBorderColor),
    panelBorderWidth: panelBorderWidth ?? this.panelBorderWidth,
    panelBorderRadius: panelBorderRadius ?? this.panelBorderRadius,
    panelPadding: panelPadding ?? this.panelPadding,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GaugeReferenceStyle &&
          showLabels == other.showLabels &&
          innerLineOffset == other.innerLineOffset &&
          outerLineOffset == other.outerLineOffset &&
          labelStyle == other.labelStyle &&
          labelOffset == other.labelOffset &&
          labelMaxWidth == other.labelMaxWidth &&
          showLabelPanel == other.showLabelPanel &&
          panelColor == other.panelColor &&
          panelBorderColor == other.panelBorderColor &&
          panelBorderWidth == other.panelBorderWidth &&
          panelBorderRadius == other.panelBorderRadius &&
          panelPadding == other.panelPadding;

  @override
  int get hashCode => Object.hash(
    showLabels,
    innerLineOffset,
    outerLineOffset,
    labelStyle,
    labelOffset,
    labelMaxWidth,
    showLabelPanel,
    panelColor,
    panelBorderColor,
    panelBorderWidth,
    panelBorderRadius,
    panelPadding,
  );
}

/// Pane, axes, zones, and direct-display behavior for one Gauge.
@immutable
@chartSurface
class GaugeChartConfig {
  const GaugeChartConfig({
    this.pane = const PolarPaneConfig(
      startAngleDegrees: -135,
      sweepAngleDegrees: 270,
      innerRadiusFactor: 0.56,
      outerRadiusFactor: 0.88,
    ),
    this.tickCount = 6,
    this.showAxis = true,
    this.showTicks = true,
    this.showTickLabels = true,
    this.showZones = true,
    this.colorIndicatorByActiveZone = true,
    this.scale = const GaugeScaleStyle(),
    this.references = const GaugeReferenceStyle(),
    this.center = const GaugeCenterConfig(),
  });

  final PolarPaneConfig pane;
  final int tickCount;
  final bool showAxis;
  final bool showTicks;
  final bool showTickLabels;
  final bool showZones;
  final bool colorIndicatorByActiveZone;
  final GaugeScaleStyle scale;
  final GaugeReferenceStyle references;
  final GaugeCenterConfig center;

  void validate() {
    pane.validate();
    if (tickCount < 2 || tickCount > 12) {
      throw ArgumentError.value(
        tickCount,
        'tickCount',
        'Tick count must be between 2 and 12',
      );
    }
    scale.validate();
    references.validate();
    center.validate();
  }

  GaugeChartConfig copyWith({
    PolarPaneConfig? pane,
    int? tickCount,
    bool? showAxis,
    bool? showTicks,
    bool? showTickLabels,
    bool? showZones,
    bool? colorIndicatorByActiveZone,
    GaugeScaleStyle? scale,
    GaugeReferenceStyle? references,
    GaugeCenterConfig? center,
  }) => GaugeChartConfig(
    pane: pane ?? this.pane,
    tickCount: tickCount ?? this.tickCount,
    showAxis: showAxis ?? this.showAxis,
    showTicks: showTicks ?? this.showTicks,
    showTickLabels: showTickLabels ?? this.showTickLabels,
    showZones: showZones ?? this.showZones,
    colorIndicatorByActiveZone:
        colorIndicatorByActiveZone ?? this.colorIndicatorByActiveZone,
    scale: scale ?? this.scale,
    references: references ?? this.references,
    center: center ?? this.center,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GaugeChartConfig &&
          pane == other.pane &&
          tickCount == other.tickCount &&
          showAxis == other.showAxis &&
          showTicks == other.showTicks &&
          showTickLabels == other.showTickLabels &&
          showZones == other.showZones &&
          colorIndicatorByActiveZone == other.colorIndicatorByActiveZone &&
          scale == other.scale &&
          references == other.references &&
          center == other.center;

  @override
  int get hashCode => Object.hash(
    pane,
    tickCount,
    showAxis,
    showTicks,
    showTickLabels,
    showZones,
    colorIndicatorByActiveZone,
    scale,
    references,
    center,
  );
}

void _requireFinite(double value, String argumentName) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, argumentName, 'Value must be finite');
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

void _requirePositive(double value, String argumentName) {
  if (!value.isFinite || value <= 0) {
    throw ArgumentError.value(
      value,
      argumentName,
      'Value must be finite and positive',
    );
  }
}
