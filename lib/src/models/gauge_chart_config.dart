import 'package:flutter/foundation.dart' show immutable;

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
  });

  final bool showMetric;
  final bool showValue;
  final bool showTarget;
  final bool showStatus;
  final PolarLabelStyle metricStyle;
  final PolarLabelStyle valueStyle;
  final PolarLabelStyle targetStyle;
  final PolarLabelStyle statusStyle;

  void validate() {
    metricStyle.validate(argumentName: 'center.metricStyle');
    valueStyle.validate(argumentName: 'center.valueStyle');
    targetStyle.validate(argumentName: 'center.targetStyle');
    statusStyle.validate(argumentName: 'center.statusStyle');
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
  }) => GaugeCenterConfig(
    showMetric: showMetric ?? this.showMetric,
    showValue: showValue ?? this.showValue,
    showTarget: showTarget ?? this.showTarget,
    showStatus: showStatus ?? this.showStatus,
    metricStyle: metricStyle ?? this.metricStyle,
    valueStyle: valueStyle ?? this.valueStyle,
    targetStyle: targetStyle ?? this.targetStyle,
    statusStyle: statusStyle ?? this.statusStyle,
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
          statusStyle == other.statusStyle;

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
    this.center = const GaugeCenterConfig(),
  });

  final PolarPaneConfig pane;
  final int tickCount;
  final bool showAxis;
  final bool showTicks;
  final bool showTickLabels;
  final bool showZones;
  final bool colorIndicatorByActiveZone;
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
    center,
  );
}
