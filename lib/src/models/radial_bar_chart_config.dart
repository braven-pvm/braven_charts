import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import '../meta/chart_surface.dart';
import 'polar_chart_config.dart';

/// Radial ordering of category tracks.
enum RadialBarTrackOrder {
  /// The first category owns the outside track.
  outerToInner,

  /// The first category owns the inside track.
  innerToOuter,
}

/// One absolute reference on a Radial Bar angular value scale.
@immutable
@chartSurface
class RadialBarThreshold {
  const RadialBarThreshold({
    required this.value,
    this.label,
    this.color,
    this.width = 1.5,
    this.dashPattern = const <double>[6, 4],
  });

  /// Absolute value on the shared angular numeric scale.
  final double value;

  /// Optional compact label painted beside the reference guide.
  final String? label;

  /// Explicit guide color. Null resolves through the chart theme.
  final Color? color;

  /// Guide width in logical pixels.
  final double width;

  /// Alternating painted and skipped lengths. Empty renders a solid guide.
  final List<double> dashPattern;

  void validate() {
    if (!value.isFinite) {
      throw ArgumentError.value(
        value,
        'threshold.value',
        'Value must be finite',
      );
    }
    if (label != null && label!.trim().isEmpty) {
      throw ArgumentError.value(
        label,
        'threshold.label',
        'Label must be null or visible text',
      );
    }
    if (!width.isFinite || width <= 0) {
      throw ArgumentError.value(
        width,
        'threshold.width',
        'Value must be finite and positive',
      );
    }
    if (dashPattern.length.isOdd) {
      throw ArgumentError.value(
        dashPattern,
        'threshold.dashPattern',
        'Dash patterns must contain painted-gap pairs',
      );
    }
    for (final (index, interval) in dashPattern.indexed) {
      if (!interval.isFinite || interval <= 0) {
        throw ArgumentError.value(
          interval,
          'threshold.dashPattern[$index]',
          'Intervals must be finite and positive',
        );
      }
    }
  }

  RadialBarThreshold copyWith({
    double? value,
    String? label,
    bool clearLabel = false,
    Color? color,
    bool clearColor = false,
    double? width,
    List<double>? dashPattern,
  }) => RadialBarThreshold(
    value: value ?? this.value,
    label: clearLabel ? null : (label ?? this.label),
    color: clearColor ? null : (color ?? this.color),
    width: width ?? this.width,
    dashPattern: dashPattern ?? this.dashPattern,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadialBarThreshold &&
          value == other.value &&
          label == other.label &&
          color == other.color &&
          width == other.width &&
          listEquals(dashPattern, other.dashPattern);

  @override
  int get hashCode =>
      Object.hash(value, label, color, width, Object.hashAll(dashPattern));
}

/// Plot-level geometry and guides for one Radial Bar chart.
///
/// Radial Bar is an axis-based family: categories occupy concentric tracks and
/// source values map to angular sweep. It never derives Pie-style shares.
@immutable
@chartSurface
class RadialBarChartConfig {
  const RadialBarChartConfig({
    this.pane = const PolarPaneConfig(
      innerRadiusFactor: 0.22,
      outerRadiusFactor: 0.82,
    ),
    this.trackGap = 6,
    this.trackOrder = RadialBarTrackOrder.outerToInner,
    this.showCategoryLabels = true,
    this.showScaleLabels = true,
    this.showGridLines = true,
    this.tickCount = 5,
    this.thresholds = const <RadialBarThreshold>[],
  });

  final PolarPaneConfig pane;

  /// Requested physical gap between adjacent category tracks.
  ///
  /// Compact panes reduce this value as needed so every category remains
  /// visible and interactable.
  final double trackGap;

  final RadialBarTrackOrder trackOrder;
  final bool showCategoryLabels;
  final bool showScaleLabels;
  final bool showGridLines;
  final int tickCount;
  final List<RadialBarThreshold> thresholds;

  void validate() {
    pane.validate();
    if (!trackGap.isFinite || trackGap < 0) {
      throw ArgumentError.value(
        trackGap,
        'trackGap',
        'Value must be finite and non-negative',
      );
    }
    if (tickCount < 2 || tickCount > 12) {
      throw ArgumentError.value(
        tickCount,
        'tickCount',
        'Tick count must be between 2 and 12',
      );
    }
    for (final threshold in thresholds) {
      threshold.validate();
    }
  }

  RadialBarChartConfig copyWith({
    PolarPaneConfig? pane,
    double? trackGap,
    RadialBarTrackOrder? trackOrder,
    bool? showCategoryLabels,
    bool? showScaleLabels,
    bool? showGridLines,
    int? tickCount,
    List<RadialBarThreshold>? thresholds,
  }) => RadialBarChartConfig(
    pane: pane ?? this.pane,
    trackGap: trackGap ?? this.trackGap,
    trackOrder: trackOrder ?? this.trackOrder,
    showCategoryLabels: showCategoryLabels ?? this.showCategoryLabels,
    showScaleLabels: showScaleLabels ?? this.showScaleLabels,
    showGridLines: showGridLines ?? this.showGridLines,
    tickCount: tickCount ?? this.tickCount,
    thresholds: thresholds ?? this.thresholds,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadialBarChartConfig &&
          pane == other.pane &&
          trackGap == other.trackGap &&
          trackOrder == other.trackOrder &&
          showCategoryLabels == other.showCategoryLabels &&
          showScaleLabels == other.showScaleLabels &&
          showGridLines == other.showGridLines &&
          tickCount == other.tickCount &&
          listEquals(thresholds, other.thresholds);

  @override
  int get hashCode => Object.hash(
    pane,
    trackGap,
    trackOrder,
    showCategoryLabels,
    showScaleLabels,
    showGridLines,
    tickCount,
    Object.hashAll(thresholds),
  );
}
