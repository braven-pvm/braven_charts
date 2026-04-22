// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui' show Color;

import 'y_axis_config.dart';

/// Typedef for custom X-axis label formatters.
///
/// Takes a numeric value and returns a formatted string representation.
typedef XAxisLabelFormatter = String Function(double value);

/// Configuration for the X-axis in a chart.
///
/// Controls appearance, bounds, visibility, and label formatting for the
/// horizontal (X) axis. Follows the same configuration pattern as [YAxisConfig].
///
/// Example:
/// ```dart
/// const xAxis = XAxisConfig(
///   label: 'Time',
///   unit: 's',
///   min: 0.0,
///   max: 100.0,
///   labelDisplay: AxisLabelDisplay.labelWithUnit,
/// );
/// ```
class XAxisConfig {
  /// Creates an X-axis configuration.
  ///
  /// All parameters are optional with sensible defaults.
  ///
  /// Validation ensures:
  /// - [minHeight] is non-negative
  /// - [maxHeight] >= [minHeight]
  /// - If both [min] and [max] are provided, [min] < [max]
  /// - If [tickCount] is provided, it must be >= 2
  const XAxisConfig({
    this.color,
    this.label,
    this.unit,
    this.min,
    this.max,
    this.renderMin,
    this.renderMax,
    this.visible = true,
    this.showAxisLine = true,
    this.showTicks = true,
    this.showTickLabels = true,
    this.showCrosshairLabel = true,
    this.crosshairLabelPosition = CrosshairLabelPosition.overAxis,
    this.labelDisplay = AxisLabelDisplay.labelWithUnit,
    this.minHeight = 0.0,
    this.maxHeight = 60.0,
    this.tickLabelPadding = 4.0,
    this.axisLabelPadding = 5.0,
    this.axisMargin = 8.0,
    this.tickCount,
    this.labelFormatter,
    this.showMinorTicks = false,
    this.minorTickCount = 4,
    this.minorTickLength = 3.0,
  })  : assert(minHeight >= 0, 'minHeight must be non-negative'),
        assert(maxHeight >= minHeight, 'maxHeight must be >= minHeight'),
        assert(
          min == null || max == null || min < max,
          'min must be less than max',
        ),
        assert(
          tickCount == null || tickCount >= 2,
          'tickCount must be >= 2',
        );

  // ========== Appearance ==========

  /// Color of the axis line, ticks, and labels.
  ///
  /// If null, uses a default axis color or the color of the first series.
  final Color? color;

  /// Axis label text (e.g., "Time", "Distance").
  ///
  /// Displayed alongside the axis to identify what it represents.
  final String? label;

  /// Unit suffix for tick labels (e.g., "s", "m", "km").
  ///
  /// Appended to formatted tick values based on [labelDisplay].
  final String? unit;

  // ========== Bounds ==========

  /// Explicit minimum value for the axis range.
  ///
  /// If null, minimum is computed from the data.
  final double? min;

  /// Explicit maximum value for the axis range.
  ///
  /// If null, maximum is computed from the data.
  final double? max;

  /// Lowest tick value to render. Ticks below this value are skipped.
  ///
  /// Does not affect data scaling — only controls which tick marks and labels
  /// are drawn. If null, defaults to [min] (all ticks rendered).
  final double? renderMin;

  /// Highest tick value to render. Ticks above this value are skipped.
  ///
  /// Does not affect data scaling — only controls which tick marks and labels
  /// are drawn. If null, defaults to [max] (all ticks rendered).
  final double? renderMax;

  // ========== Visibility ==========

  /// Whether the axis should be rendered at all.
  ///
  /// When false, the entire axis (line, ticks, labels, and axis title) is
  /// hidden from display.
  ///
  /// Defaults to true.
  final bool visible;

  /// Whether to show the axis line.
  ///
  /// Defaults to true.
  final bool showAxisLine;

  /// Whether to show tick marks (small lines on axis).
  ///
  /// Defaults to true. Set to false to hide tick marks while
  /// potentially still showing tick labels (controlled by [showTickLabels]).
  final bool showTicks;

  /// Whether to show numeric tick labels (e.g., 0, 2, 4, 6) on the axis.
  ///
  /// Defaults to true. Set to false to hide tick value labels while
  /// keeping the axis label and tick marks visible.
  final bool showTickLabels;

  /// Whether to show a crosshair X-value label positioned over this axis.
  ///
  /// When enabled, displays the X-value at the crosshair's position.
  ///
  /// Defaults to true.
  final bool showCrosshairLabel;

  /// Controls where the crosshair X-value label appears.
  ///
  /// Only applicable when [showCrosshairLabel] is true.
  /// Defaults to [CrosshairLabelPosition.overAxis].
  ///
  /// See [CrosshairLabelPosition] for available positions.
  final CrosshairLabelPosition crosshairLabelPosition;

  // ========== Layout ==========

  /// Controls how axis labels and units are displayed.
  ///
  /// See [AxisLabelDisplay] for available options.
  ///
  /// Defaults to [AxisLabelDisplay.labelWithUnit].
  final AxisLabelDisplay labelDisplay;

  /// Minimum height reserved for the X-axis area in pixels.
  ///
  /// Must be non-negative.
  /// Defaults to 0.0.
  final double minHeight;

  /// Maximum height allowed for the X-axis area in pixels.
  ///
  /// Must be >= [minHeight].
  /// Defaults to 60.0.
  final double maxHeight;

  /// Padding between tick marks and tick labels in pixels.
  ///
  /// Defaults to 4.0.
  final double tickLabelPadding;

  /// Padding between tick labels and axis label in pixels.
  ///
  /// Defaults to 5.0.
  final double axisLabelPadding;

  /// Margin around the axis area in pixels.
  ///
  /// Defaults to 8.0.
  final double axisMargin;

  /// Explicit number of tick marks to display.
  ///
  /// If null, tick count is computed automatically based on available space.
  /// If provided, must be >= 2.
  final int? tickCount;

  /// Custom formatter for tick labels.
  ///
  /// If provided, overrides default number formatting.
  final XAxisLabelFormatter? labelFormatter;

  // ========== Minor Ticks ==========

  /// Whether to show minor (unlabelled) tick marks between major ticks.
  ///
  /// Defaults to false.
  final bool showMinorTicks;

  /// Number of minor ticks to draw between each adjacent pair of major ticks.
  ///
  /// For example, 4 minor ticks between major ticks at 0 and 10 produces
  /// unlabelled marks at 2, 4, 6, 8. Defaults to 4.
  final int minorTickCount;

  /// Length of minor tick marks in pixels.
  ///
  /// Should be shorter than the major tick length (6px). Defaults to 3.0.
  final double minorTickLength;

  // ========== Computed Properties ==========

  /// Whether to show the axis label (e.g., "Time").
  ///
  /// Returns false only for tickUnitOnly, tickOnly, and none modes.
  bool get shouldShowAxisLabel =>
      labelDisplay != AxisLabelDisplay.tickUnitOnly &&
      labelDisplay != AxisLabelDisplay.tickOnly &&
      labelDisplay != AxisLabelDisplay.none;

  /// Whether to append unit to the axis label (e.g., "Time (s)").
  ///
  /// Returns true only for labelWithUnit and labelWithUnitAndTickUnit modes.
  bool get shouldAppendUnitToLabel =>
      labelDisplay == AxisLabelDisplay.labelWithUnit ||
      labelDisplay == AxisLabelDisplay.labelWithUnitAndTickUnit;

  /// Whether to show unit suffix on tick labels (e.g., "10 s", "20 s").
  ///
  /// Returns true for labelAndTickUnit, labelWithUnitAndTickUnit, and
  /// tickUnitOnly modes.
  bool get shouldShowTickUnit =>
      labelDisplay == AxisLabelDisplay.labelAndTickUnit ||
      labelDisplay == AxisLabelDisplay.labelWithUnitAndTickUnit ||
      labelDisplay == AxisLabelDisplay.tickUnitOnly;

  /// Whether to show tick labels at all.
  ///
  /// Returns false when [showTickLabels] is false or [labelDisplay] is none.
  bool get shouldShowTickLabels =>
      showTickLabels && labelDisplay != AxisLabelDisplay.none;

  // ========== Methods ==========

  /// Creates a copy of this config with specified properties overridden.
  ///
  /// All parameters are optional. Properties not specified retain their
  /// current values.
  XAxisConfig copyWith({
    Color? color,
    String? label,
    String? unit,
    double? min,
    double? max,
    double? renderMin,
    double? renderMax,
    bool? visible,
    bool? showAxisLine,
    bool? showTicks,
    bool? showTickLabels,
    bool? showCrosshairLabel,
    CrosshairLabelPosition? crosshairLabelPosition,
    AxisLabelDisplay? labelDisplay,
    double? minHeight,
    double? maxHeight,
    double? tickLabelPadding,
    double? axisLabelPadding,
    double? axisMargin,
    int? tickCount,
    XAxisLabelFormatter? labelFormatter,
    bool? showMinorTicks,
    int? minorTickCount,
    double? minorTickLength,
  }) {
    return XAxisConfig(
      color: color ?? this.color,
      label: label ?? this.label,
      unit: unit ?? this.unit,
      min: min ?? this.min,
      max: max ?? this.max,
      renderMin: renderMin ?? this.renderMin,
      renderMax: renderMax ?? this.renderMax,
      visible: visible ?? this.visible,
      showAxisLine: showAxisLine ?? this.showAxisLine,
      showTicks: showTicks ?? this.showTicks,
      showTickLabels: showTickLabels ?? this.showTickLabels,
      showCrosshairLabel: showCrosshairLabel ?? this.showCrosshairLabel,
      crosshairLabelPosition:
          crosshairLabelPosition ?? this.crosshairLabelPosition,
      labelDisplay: labelDisplay ?? this.labelDisplay,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
      tickLabelPadding: tickLabelPadding ?? this.tickLabelPadding,
      axisLabelPadding: axisLabelPadding ?? this.axisLabelPadding,
      axisMargin: axisMargin ?? this.axisMargin,
      tickCount: tickCount ?? this.tickCount,
      labelFormatter: labelFormatter ?? this.labelFormatter,
      showMinorTicks: showMinorTicks ?? this.showMinorTicks,
      minorTickCount: minorTickCount ?? this.minorTickCount,
      minorTickLength: minorTickLength ?? this.minorTickLength,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XAxisConfig &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          label == other.label &&
          unit == other.unit &&
          min == other.min &&
          max == other.max &&
          renderMin == other.renderMin &&
          renderMax == other.renderMax &&
          visible == other.visible &&
          showAxisLine == other.showAxisLine &&
          showTicks == other.showTicks &&
          showTickLabels == other.showTickLabels &&
          showCrosshairLabel == other.showCrosshairLabel &&
          crosshairLabelPosition == other.crosshairLabelPosition &&
          labelDisplay == other.labelDisplay &&
          minHeight == other.minHeight &&
          maxHeight == other.maxHeight &&
          tickLabelPadding == other.tickLabelPadding &&
          axisLabelPadding == other.axisLabelPadding &&
          axisMargin == other.axisMargin &&
          tickCount == other.tickCount &&
          labelFormatter == other.labelFormatter &&
          showMinorTicks == other.showMinorTicks &&
          minorTickCount == other.minorTickCount &&
          minorTickLength == other.minorTickLength;

  @override
  int get hashCode => Object.hashAll([
        color,
        label,
        unit,
        min,
        max,
        renderMin,
        renderMax,
        visible,
        showAxisLine,
        showTicks,
        showTickLabels,
        showCrosshairLabel,
        crosshairLabelPosition,
        labelDisplay,
        minHeight,
        maxHeight,
        tickLabelPadding,
        axisLabelPadding,
        axisMargin,
        tickCount,
        labelFormatter,
        showMinorTicks,
        minorTickCount,
        minorTickLength,
      ]);

  @override
  String toString() {
    return 'XAxisConfig('
        'color: $color, '
        'label: $label, '
        'unit: $unit, '
        'min: $min, '
        'max: $max, '
        'renderMin: $renderMin, '
        'renderMax: $renderMax, '
        'visible: $visible, '
        'showAxisLine: $showAxisLine, '
        'showTicks: $showTicks, '
        'showCrosshairLabel: $showCrosshairLabel, '
        'crosshairLabelPosition: $crosshairLabelPosition, '
        'labelDisplay: $labelDisplay, '
        'minHeight: $minHeight, '
        'maxHeight: $maxHeight, '
        'tickLabelPadding: $tickLabelPadding, '
        'axisLabelPadding: $axisLabelPadding, '
        'axisMargin: $axisMargin, '
        'tickCount: $tickCount, '
        'labelFormatter: $labelFormatter, '
        'showMinorTicks: $showMinorTicks, '
        'minorTickCount: $minorTickCount, '
        'minorTickLength: $minorTickLength'
        ')';
  }
}
