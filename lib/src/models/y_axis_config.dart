/// Configuration model for individual Y-axes in multi-axis charts.
///
/// This library provides the [YAxisConfig] class for configuring Y-axes
/// that can appear at different positions in a multi-axis chart layout.
library;

import 'dart:ui' show Color;

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
/// Each Y-axis needs configuration for identity, position, appearance,
/// bounds, and formatting. Multiple Y-axes can be displayed simultaneously
/// at different positions around the chart area.
///
/// Example:
/// ```dart
/// final powerAxis = YAxisConfig(
///   id: 'power',
///   position: YAxisPosition.left,
///   color: Colors.blue,
///   label: 'Power',
///   unit: 'W',
///   min: 0,
///   max: 400,
/// );
///
/// final hrAxis = YAxisConfig(
///   id: 'heartrate',
///   position: YAxisPosition.right,
///   color: Colors.red,
///   label: 'Heart Rate',
///   unit: 'bpm',
/// );
/// ```
class YAxisConfig {
  /// Creates a Y-axis configuration.
  ///
  /// [id] and [position] are required. All other parameters are optional
  /// with sensible defaults.
  ///
  /// Validation ensures:
  /// - [id] is non-empty
  /// - [minWidth] is positive
  /// - [maxWidth] >= [minWidth]
  /// - If both [min] and [max] are provided, [min] < [max]
  /// - If [tickCount] is provided, it must be >= 2
  YAxisConfig({
    required this.id,
    required this.position,
    this.color,
    this.label,
    this.unit,
    this.min,
    this.max,
    this.showTicks = true,
    this.showAxisLine = true,
    this.labelDisplay = AxisLabelDisplay.labelWithUnit,
    this.minWidth = 40.0,
    this.maxWidth = 80.0,
    this.tickLabelPadding = 4.0,
    this.axisLabelPadding = 5.0,
    this.axisMargin = 8.0,
    this.tickCount,
    this.labelFormatter,
  })  : assert(id.isNotEmpty, 'id must be non-empty'),
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

  // ========== Identity ==========

  /// Unique identifier for axis binding.
  ///
  /// Used to associate data series with this axis. Must be non-empty.
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

  /// Whether to show tick marks on the axis.
  final bool showTicks;

  /// Whether to show the axis line.
  final bool showAxisLine;

  /// Controls display of axis label and tick unit suffixes.
  ///
  /// Defaults to [AxisLabelDisplay.labelWithUnit] for space efficiency.
  /// See [AxisLabelDisplay] for all available display modes.
  final AxisLabelDisplay labelDisplay;

  // ========== Sizing ==========

  /// Minimum width of the axis area in logical pixels.
  ///
  /// Must be non-negative. Set to 0 to allow the axis to shrink
  /// to fit its actual content. Defaults to 40.0.
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
    bool? showTicks,
    bool? showAxisLine,
    AxisLabelDisplay? labelDisplay,
    double? minWidth,
    double? maxWidth,
    double? tickLabelPadding,
    double? axisLabelPadding,
    double? axisMargin,
    int? tickCount,
    YAxisLabelFormatter? labelFormatter,
  }) {
    return YAxisConfig(
      id: id ?? this.id,
      position: position ?? this.position,
      color: color ?? this.color,
      label: label ?? this.label,
      unit: unit ?? this.unit,
      min: min ?? this.min,
      max: max ?? this.max,
      showTicks: showTicks ?? this.showTicks,
      showAxisLine: showAxisLine ?? this.showAxisLine,
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
        other.showTicks == showTicks &&
        other.showAxisLine == showAxisLine &&
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
        showTicks,
        showAxisLine,
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
        'showTicks: $showTicks, '
        'showAxisLine: $showAxisLine, '
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
