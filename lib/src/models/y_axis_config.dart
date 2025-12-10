/// Configuration model for individual Y-axes in multi-axis charts.
///
/// This library provides the [YAxisConfig] class for configuring Y-axes
/// that can appear at different positions in a multi-axis chart layout.
library;

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'y_axis_position.dart';

/// Controls how axis labels and units are displayed on Y-axes.
///
/// This enum provides fine-grained control over the display of axis titles
/// and unit suffixes, enabling space-efficient layouts by consolidating
/// unit information in the axis label rather than repeating it on every tick.
///
/// Example:
/// ```dart
/// // Most space-efficient: "Power (W)" label + "250", "500" ticks
/// YAxisConfig(
///   label: 'Power',
///   unit: 'W',
///   labelDisplay: AxisLabelDisplay.labelWithUnit,
/// )
///
/// // Most verbose: "Power (W)" label + "250 W", "500 W" ticks
/// YAxisConfig(
///   label: 'Power',
///   unit: 'W',
///   labelDisplay: AxisLabelDisplay.labelWithUnitAndTickUnit,
/// )
/// ```
enum AxisLabelDisplay {
  /// Shows axis label only, tick values without unit.
  ///
  /// Example: Label = "Power", Ticks = "250", "500", "750"
  /// Use when: Unit is obvious from context or not needed.
  labelOnly,

  /// Shows axis label with unit appended, tick values without unit.
  ///
  /// Example: Label = "Power (W)", Ticks = "250", "500", "750"
  /// Use when: Space efficiency is important. **Recommended default.**
  labelWithUnit,

  /// Shows axis label only, tick values with unit suffix.
  ///
  /// Example: Label = "Power", Ticks = "250 W", "500 W", "750 W"
  /// Use when: Label context is clear but tick units needed.
  labelAndTickUnit,

  /// Shows axis label with unit AND tick values with unit (most verbose).
  ///
  /// Example: Label = "Power (W)", Ticks = "250 W", "500 W", "750 W"
  /// Use when: Maximum clarity is needed, space is not a concern.
  labelWithUnitAndTickUnit,

  /// Shows no axis label, tick values with unit suffix.
  ///
  /// Example: Label = (none), Ticks = "250 W", "500 W", "750 W"
  /// Use when: Space is very limited, only tick units needed.
  tickUnitOnly,

  /// Shows no axis label, tick values without unit suffix.
  ///
  /// Example: Label = (none), Ticks = "250", "500", "750"
  /// Use when: Maximum space efficiency, values self-explanatory.
  tickOnly,

  /// Hides both axis label and unit suffixes on ticks.
  ///
  /// Example: Label = (none), Ticks = "250", "500", "750"
  /// Use when: Minimal display, unit communicated elsewhere.
  none,
}

/// Typedef for custom Y-axis label formatters.
typedef YAxisLabelFormatter = String Function(double value);

/// Configuration for a Y-axis in a multi-axis chart.
///
/// Each Y-axis needs configuration for position, appearance, bounds, and
/// formatting. Multiple Y-axes can be displayed simultaneously at different
/// positions around the chart area.
///
/// When used inline on a series via [ChartSeries.yAxisConfig], the axis ID
/// is auto-generated from the series ID (`{seriesId}_axis`).
///
/// Example:
/// ```dart
/// // Inline on series (recommended) - ID auto-generated
/// LineChartSeries(
///   id: 'power',
///   yAxisConfig: YAxisConfig(
///     position: YAxisPosition.left,
///     label: 'Power',
///     unit: 'W',
///   ),
/// )
///
/// // Standalone axis with explicit ID (internal use)
/// final hrAxis = YAxisConfig._internal(
///   id: 'heartrate',
///   position: YAxisPosition.right,
///   label: 'Heart Rate',
///   unit: 'bpm',
/// );
/// ```
class YAxisConfig {
  /// Creates a Y-axis configuration.
  ///
  /// [position] is required. All other parameters are optional with sensible
  /// defaults. The axis ID is auto-generated internally when this config is
  /// used inline on a series.
  ///
  /// Validation ensures:
  /// - [minWidth] is positive
  /// - [maxWidth] >= [minWidth]
  /// - If both [min] and [max] are provided, [min] < [max]
  /// - If [tickCount] is provided, it must be >= 2
  YAxisConfig({
    required this.position,
    this.color,
    this.label,
    this.unit,
    this.min,
    this.max,
    this.visible = true,
    this.showAxisLine = true,
    this.showTicks = true,
    this.showCrosshairLabel = false,
    this.labelDisplay = AxisLabelDisplay.labelWithUnit,
    this.minWidth = 0.0,
    this.maxWidth = 80.0,
    this.tickLabelPadding = 4.0,
    this.axisLabelPadding = 5.0,
    this.axisMargin = 8.0,
    this.tickCount,
    this.labelFormatter,
  })  : id = '',
        assert(minWidth >= 0, 'minWidth must be non-negative'),
        assert(maxWidth >= minWidth, 'maxWidth must be >= minWidth'),
        assert(
          min == null || max == null || min < max,
          'min must be less than max',
        ),
        assert(
          tickCount == null || tickCount >= 2,
          'tickCount must be >= 2',
        );

  /// Internal constructor with explicit ID.
  ///
  /// Used by [MultiAxisManager] to create configs with auto-generated IDs.
  /// Not part of the public API.
  const YAxisConfig._internal({
    required this.id,
    required this.position,
    this.color,
    this.label,
    this.unit,
    this.min,
    this.max,
    this.visible = true,
    this.showAxisLine = true,
    this.showTicks = true,
    this.showCrosshairLabel = false,
    this.labelDisplay = AxisLabelDisplay.labelWithUnit,
    this.minWidth = 0.0,
    this.maxWidth = 80.0,
    this.tickLabelPadding = 4.0,
    this.axisLabelPadding = 5.0,
    this.axisMargin = 8.0,
    this.tickCount,
    this.labelFormatter,
  });

  /// Creates a Y-axis configuration with an explicit ID for testing.
  ///
  /// This factory is provided for unit tests that need to verify axis
  /// behavior with known IDs. In production code, use the default
  /// constructor without an ID - the ID will be auto-generated.
  @visibleForTesting
  factory YAxisConfig.withId({
    required String id,
    required YAxisPosition position,
    Color? color,
    String? label,
    String? unit,
    double? min,
    double? max,
    bool visible = true,
    bool showAxisLine = true,
    bool showTicks = true,
    bool showCrosshairLabel = false,
    AxisLabelDisplay labelDisplay = AxisLabelDisplay.labelWithUnit,
    double minWidth = 0.0,
    double maxWidth = 80.0,
    double tickLabelPadding = 4.0,
    double axisLabelPadding = 5.0,
    double axisMargin = 8.0,
    int? tickCount,
    YAxisLabelFormatter? labelFormatter,
  }) {
    // Same validations as public constructor
    assert(id.isNotEmpty, 'id must not be empty when using withId');
    assert(minWidth >= 0, 'minWidth must be non-negative');
    assert(maxWidth >= minWidth, 'maxWidth must be >= minWidth');
    assert(
      min == null || max == null || min < max,
      'min must be less than max',
    );
    assert(
      tickCount == null || tickCount >= 2,
      'tickCount must be >= 2',
    );
    return YAxisConfig._internal(
      id: id,
      position: position,
      color: color,
      label: label,
      unit: unit,
      min: min,
      max: max,
      visible: visible,
      showAxisLine: showAxisLine,
      showTicks: showTicks,
      showCrosshairLabel: showCrosshairLabel,
      labelDisplay: labelDisplay,
      minWidth: minWidth,
      maxWidth: maxWidth,
      tickLabelPadding: tickLabelPadding,
      axisLabelPadding: axisLabelPadding,
      axisMargin: axisMargin,
      tickCount: tickCount,
      labelFormatter: labelFormatter,
    );
  }

  // ========== Identity ==========

  /// Internal identifier for axis binding and map keys.
  ///
  /// Auto-generated from series ID when using inline yAxisConfig.
  /// Empty string until resolved by [MultiAxisManager].
  final String id;

  /// Physical position of the axis relative to the chart area.
  ///
  /// See [YAxisPosition] for available positions.
  final YAxisPosition position;

  // ========== Appearance ==========

  /// Color of the axis line, ticks, and labels.
  ///
  /// If null, uses the color of the first bound series.
  final Color? color;

  /// Axis label text (e.g., "Power", "Heart Rate").
  ///
  /// Displayed alongside the axis to identify what it represents.
  final String? label;

  /// Unit suffix for tick labels (e.g., "W", "bpm", "L").
  ///
  /// Appended to formatted tick values.
  final String? unit;

  // ========== Bounds ==========

  /// Explicit minimum value for the axis range.
  ///
  /// If null, minimum is computed from the data of bound series.
  final double? min;

  /// Explicit maximum value for the axis range.
  ///
  /// If null, maximum is computed from the data of bound series.
  final double? max;

  // ========== Visibility ==========

  /// Whether the axis should be rendered at all.
  ///
  /// When false, the entire axis (line, ticks, labels, and axis title) is
  /// hidden from display. However, the axis is still used for normalization
  /// calculations if the series references it via [yAxisConfig].
  ///
  /// Use case: Show a normalized series without displaying its Y-axis.
  ///
  /// Example:
  /// ```dart
  /// YAxisConfig(
  ///   id: 'cadence_axis',
  ///   position: YAxisPosition.leftOuter,
  ///   visible: false, // Hides entire axis but keeps series normalized
  /// )
  /// ```
  ///
  /// Defaults to true.
  final bool visible;

  /// Whether to show the axis line.
  final bool showAxisLine;

  /// Whether to show tick marks (small lines on axis).
  ///
  /// Defaults to true. Set to false to hide tick marks while
  /// potentially still showing tick labels (controlled by [labelDisplay]).
  final bool showTicks;

  /// Whether to show a crosshair Y-value label positioned over this axis.
  ///
  /// When enabled in multi-axis normalized mode, displays the actual
  /// (denormalized) Y-value at the crosshair's horizontal position,
  /// drawn with a semi-transparent background over this specific Y-axis.
  ///
  /// This is useful in multi-axis charts where the default crosshair Y-label
  /// shows normalized percentages which are not meaningful to users.
  ///
  /// Example:
  /// ```dart
  /// YAxisConfig(
  ///   id: 'power_axis',
  ///   position: YAxisPosition.left,
  ///   showCrosshairLabel: true, // Shows actual power value on crosshair
  /// )
  /// ```
  ///
  /// Defaults to false.
  final bool showCrosshairLabel;

  /// Controls display of axis label and tick unit suffixes.
  ///
  /// Defaults to [AxisLabelDisplay.labelWithUnit] for space efficiency.
  /// See [AxisLabelDisplay] for all available display modes.
  final AxisLabelDisplay labelDisplay;

  // ========== Sizing ==========

  /// Minimum width of the axis area in logical pixels.
  ///
  /// Must be non-negative. Defaults to 0.0 to allow the axis to
  /// shrink to fit its actual content. Set higher for fixed-width axes.
  final double minWidth;

  /// Maximum width of the axis area in logical pixels.
  ///
  /// Must be >= [minWidth].
  final double maxWidth;

  /// Padding between tick marks and tick labels in logical pixels.
  ///
  /// Controls the horizontal gap between where the tick mark ends
  /// and where the tick label text begins. Defaults to 4.0.
  final double tickLabelPadding;

  /// Padding between tick labels and the rotated axis title label.
  ///
  /// Controls the horizontal gap between the tick label text and the
  /// axis title (e.g., "Power (W)"). Defaults to 2.0 for compact layout.
  final double axisLabelPadding;

  /// Margin between this axis and adjacent axes or the plot area.
  ///
  /// Creates visual separation between stacked axes (e.g., left and leftOuter)
  /// and between the innermost axis and the chart plot area. Defaults to 8.0.
  ///
  /// Example:
  /// ```dart
  /// // More separation between axes
  /// YAxisConfig(
  ///   id: 'power',
  ///   position: YAxisPosition.left,
  ///   axisMargin: 16.0, // Double the default spacing
  /// )
  /// ```
  final double axisMargin;

  // ========== Formatting ==========

  /// Preferred number of tick marks.
  ///
  /// If null, tick count is computed automatically based on available space.
  /// If provided, must be >= 2.
  final int? tickCount;

  /// Custom formatter for tick labels.
  ///
  /// If null, uses default number formatting with [unit] suffix if provided.
  final YAxisLabelFormatter? labelFormatter;

  // ========== Methods ==========

  /// Creates a copy of this configuration with specified properties overridden.
  ///
  /// All parameters are optional. Properties not specified retain their
  /// current values.
  YAxisConfig copyWith({
    String? id,
    YAxisPosition? position,
    Color? color,
    String? label,
    String? unit,
    double? min,
    double? max,
    bool? visible,
    bool? showAxisLine,
    bool? showTicks,
    bool? showCrosshairLabel,
    AxisLabelDisplay? labelDisplay,
    double? minWidth,
    double? maxWidth,
    double? tickLabelPadding,
    double? axisLabelPadding,
    double? axisMargin,
    int? tickCount,
    YAxisLabelFormatter? labelFormatter,
  }) {
    return YAxisConfig._internal(
      id: id ?? this.id,
      position: position ?? this.position,
      color: color ?? this.color,
      label: label ?? this.label,
      unit: unit ?? this.unit,
      min: min ?? this.min,
      max: max ?? this.max,
      visible: visible ?? this.visible,
      showAxisLine: showAxisLine ?? this.showAxisLine,
      showTicks: showTicks ?? this.showTicks,
      showCrosshairLabel: showCrosshairLabel ?? this.showCrosshairLabel,
      labelDisplay: labelDisplay ?? this.labelDisplay,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      tickLabelPadding: tickLabelPadding ?? this.tickLabelPadding,
      axisLabelPadding: axisLabelPadding ?? this.axisLabelPadding,
      axisMargin: axisMargin ?? this.axisMargin,
      tickCount: tickCount ?? this.tickCount,
      labelFormatter: labelFormatter ?? this.labelFormatter,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is YAxisConfig &&
        other.id == id &&
        other.position == position &&
        other.color == color &&
        other.label == label &&
        other.unit == unit &&
        other.min == min &&
        other.max == max &&
        other.visible == visible &&
        other.showAxisLine == showAxisLine &&
        other.showTicks == showTicks &&
        other.showCrosshairLabel == showCrosshairLabel &&
        other.labelDisplay == labelDisplay &&
        other.minWidth == minWidth &&
        other.maxWidth == maxWidth &&
        other.tickLabelPadding == tickLabelPadding &&
        other.axisLabelPadding == axisLabelPadding &&
        other.axisMargin == axisMargin &&
        other.tickCount == tickCount &&
        other.labelFormatter == labelFormatter;
  }

  @override
  int get hashCode => Object.hash(
        id,
        position,
        color,
        label,
        unit,
        min,
        max,
        visible,
        showAxisLine,
        showTicks,
        showCrosshairLabel,
        labelDisplay,
        minWidth,
        maxWidth,
        tickLabelPadding,
        axisLabelPadding,
        axisMargin,
        tickCount,
        labelFormatter,
      );

  @override
  String toString() {
    return 'YAxisConfig('
        'id: $id, '
        'position: $position, '
        'color: $color, '
        'label: $label, '
        'unit: $unit, '
        'min: $min, '
        'max: $max, '
        'visible: $visible, '
        'showAxisLine: $showAxisLine, '
        'showTicks: $showTicks, '
        'showCrosshairLabel: $showCrosshairLabel, '
        'labelDisplay: $labelDisplay, '
        'minWidth: $minWidth, '
        'maxWidth: $maxWidth, '
        'tickLabelPadding: $tickLabelPadding, '
        'axisLabelPadding: $axisLabelPadding, '
        'axisMargin: $axisMargin, '
        'tickCount: $tickCount'
        ')';
  }

  // ========== Helper Methods ==========

  /// Returns true if the axis label should be displayed.
  ///
  /// Based on [labelDisplay] setting:
  /// - Shows label for: labelOnly, labelWithUnit, labelAndTickUnit, labelWithUnitAndTickUnit
  /// - Hides label for: tickUnitOnly, tickOnly, none
  bool get shouldShowAxisLabel {
    return labelDisplay != AxisLabelDisplay.tickUnitOnly && labelDisplay != AxisLabelDisplay.tickOnly && labelDisplay != AxisLabelDisplay.none;
  }

  /// Returns true if the unit should be appended to the axis label.
  ///
  /// Based on [labelDisplay] setting:
  /// - Appends unit for: labelWithUnit, labelWithUnitAndTickUnit
  /// - No unit for: labelOnly, labelAndTickUnit, tickUnitOnly, tickOnly, none
  bool get shouldAppendUnitToLabel {
    return labelDisplay == AxisLabelDisplay.labelWithUnit || labelDisplay == AxisLabelDisplay.labelWithUnitAndTickUnit;
  }

  /// Returns true if the unit should be shown on tick labels.
  ///
  /// Based on [labelDisplay] setting:
  /// - Shows unit for: labelAndTickUnit, labelWithUnitAndTickUnit, tickUnitOnly
  /// - No unit for: labelOnly, labelWithUnit, tickOnly, none
  bool get shouldShowTickUnit {
    return labelDisplay == AxisLabelDisplay.labelAndTickUnit ||
        labelDisplay == AxisLabelDisplay.labelWithUnitAndTickUnit ||
        labelDisplay == AxisLabelDisplay.tickUnitOnly;
  }

  /// Returns true if tick labels (values) should be displayed.
  ///
  /// Tick labels are shown for all modes except none.
  /// Note: This is independent of whether units are shown on ticks.
  bool get shouldShowTickLabels {
    return labelDisplay != AxisLabelDisplay.none;
  }
}
