/// Configuration model for individual Y-axes in multi-axis charts.
///
/// This library provides the [YAxisConfig] class for configuring Y-axes
/// that can appear at different positions in a multi-axis chart layout.
library;

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../meta/chart_surface.dart';
import 'axis_scale_type.dart';
import 'y_axis_position.dart';

/// Controls where crosshair Y-value labels appear when hovering over the chart.
///
/// This enum determines the positioning of the label that displays the Y-axis
/// value when the crosshair is active (user hovers over the chart).
///
/// Example:
/// ```dart
/// // Label appears in the axis strip area outside the plot (default)
/// YAxisConfig(
///   crosshairLabelPosition: CrosshairLabelPosition.overAxis,
/// )
///
/// // Label appears inside the plot area near the axis edge
/// YAxisConfig(
///   crosshairLabelPosition: CrosshairLabelPosition.insidePlot,
/// )
/// ```
enum CrosshairLabelPosition {
  /// Label appears in the axis strip area outside the plot area.
  ///
  /// This is the default and traditional behavior where the crosshair
  /// Y-value label is rendered in the Y-axis strip (the area containing
  /// tick labels), positioned outside the main plot area.
  ///
  /// Use when: Standard layout with clear separation between axis and plot.
  overAxis,

  /// Label appears inside the plot area near the axis edge.
  ///
  /// The crosshair Y-value label is rendered inside the plot area,
  /// positioned near the corresponding Y-axis edge. This can be useful
  /// for space-constrained layouts or when the axis strip is narrow.
  ///
  /// Use when: Axis strip is too narrow or space-efficient layout needed.
  insidePlot,
}

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
// The reader selects the const `_internal` constructor (the public one is not
// const), so `id` — an internal, pipeline-assigned identity — would otherwise
// surface as a public `withId` that hijacks multi-axis binding.
@ChartSurface(
  excluded: ['id'],
  combinedSetters: [
    // The public constructor asserts `min < max` and `maxWidth >= minWidth`.
    // `copyWith` rebuilds through `_internal`, which carries no asserts, so
    // these pairs are coupled by contract rather than by a runtime throw —
    // an individual setter would silently produce an inverted axis.
    CombinedSetter('withRange', ['min', 'max']),
    CombinedSetter('withWidthBounds', ['minWidth', 'maxWidth']),
  ],
)
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
    required YAxisPosition position,
    this.color,
    this.label,
    this.unit,
    this.min,
    this.max,
    this.renderMin,
    this.renderMax,
    bool visible = true,
    this.showAxisLine = true,
    this.showTicks = true,
    this.showTickLabels = true,
    this.showCrosshairLabel = true,
    this.crosshairLabelPosition = CrosshairLabelPosition.overAxis,
    this.labelDisplay = AxisLabelDisplay.labelWithUnit,
    this.minWidth = 0.0,
    this.maxWidth = 80.0,
    this.tickLabelPadding = 4.0,
    this.axisLabelPadding = 5.0,
    this.axisMargin = 8.0,
    this.tickCount,
    this.scaleType = AxisScaleType.linear,
    this.logBase = 10,
    this.labelFormatter,
    this.showMinorTicks = false,
    this.minorTickCount = 4,
    this.minorTickLength = 3.0,
  })  : id = '',
        // ignore: deprecated_member_use_from_same_package
        position = (position == YAxisPosition.leftOuter)
            ? YAxisPosition.left
            // ignore: deprecated_member_use_from_same_package
            : (position == YAxisPosition.rightOuter)
                ? YAxisPosition.right
                : position,
        // Raw `position` parameter intentionally used: leftOuter/rightOuter never equal hidden,
        // so the result is identical to checking the normalised this.position.
        visible = position == YAxisPosition.hidden ? false : visible,
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
  /// Used by the multi-axis render pipeline to create auto-generated IDs.
  /// Not part of the public API.
  const YAxisConfig._internal({
    required this.id,
    required this.position,
    this.color,
    this.label,
    this.unit,
    this.min,
    this.max,
    this.renderMin,
    this.renderMax,
    bool visible = true,
    this.showAxisLine = true,
    this.showTicks = true,
    this.showTickLabels = true,
    this.showCrosshairLabel = true,
    this.crosshairLabelPosition = CrosshairLabelPosition.overAxis,
    this.labelDisplay = AxisLabelDisplay.labelWithUnit,
    this.minWidth = 0.0,
    this.maxWidth = 80.0,
    this.tickLabelPadding = 4.0,
    this.axisLabelPadding = 5.0,
    this.axisMargin = 8.0,
    this.tickCount,
    this.scaleType = AxisScaleType.linear,
    this.logBase = 10,
    this.labelFormatter,
    this.showMinorTicks = false,
    this.minorTickCount = 4,
    this.minorTickLength = 3.0,
  }) : visible = position == YAxisPosition.hidden ? false : visible;

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
    double? renderMin,
    double? renderMax,
    bool visible = true,
    bool showAxisLine = true,
    bool showTicks = true,
    bool showTickLabels = true,
    bool showCrosshairLabel = true,
    CrosshairLabelPosition crosshairLabelPosition =
        CrosshairLabelPosition.overAxis,
    AxisLabelDisplay labelDisplay = AxisLabelDisplay.labelWithUnit,
    double minWidth = 0.0,
    double maxWidth = 80.0,
    double tickLabelPadding = 4.0,
    double axisLabelPadding = 5.0,
    double axisMargin = 8.0,
    int? tickCount,
    AxisScaleType scaleType = AxisScaleType.linear,
    double logBase = 10,
    YAxisLabelFormatter? labelFormatter,
    bool showMinorTicks = false,
    int minorTickCount = 4,
    double minorTickLength = 3.0,
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
      renderMin: renderMin,
      renderMax: renderMax,
      visible: visible,
      showAxisLine: showAxisLine,
      showTicks: showTicks,
      showTickLabels: showTickLabels,
      showCrosshairLabel: showCrosshairLabel,
      crosshairLabelPosition: crosshairLabelPosition,
      labelDisplay: labelDisplay,
      minWidth: minWidth,
      maxWidth: maxWidth,
      tickLabelPadding: tickLabelPadding,
      axisLabelPadding: axisLabelPadding,
      axisMargin: axisMargin,
      tickCount: tickCount,
      scaleType: scaleType,
      logBase: logBase,
      labelFormatter: labelFormatter,
      showMinorTicks: showMinorTicks,
      minorTickCount: minorTickCount,
      minorTickLength: minorTickLength,
    );
  }

  // ========== Identity ==========

  /// Internal identifier for axis binding and map keys.
  ///
  /// Auto-generated from series ID when using inline yAxisConfig.
  /// Empty string until resolved by the multi-axis render pipeline.
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
  /// hidden from display. However, the axis is still used for normalization
  /// calculations if a series references it via `ChartSeries.yAxisConfig`.
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
  /// potentially still showing tick labels (controlled by [showTickLabels]).
  final bool showTicks;

  /// Whether to show numeric tick labels (e.g., 0, 2, 4, 6) on the axis.
  ///
  /// Defaults to true. Set to false to hide tick value labels while
  /// keeping the axis label and tick marks visible.
  final bool showTickLabels;

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

  /// Controls where the crosshair Y-value label appears.
  ///
  /// Only applicable when [showCrosshairLabel] is true.
  /// Defaults to [CrosshairLabelPosition.overAxis].
  ///
  /// See [CrosshairLabelPosition] for available positions.
  final CrosshairLabelPosition crosshairLabelPosition;

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

  /// How this axis maps values to positions and generates ticks.
  final AxisScaleType scaleType;

  /// Base for [AxisScaleType.log]; ignored otherwise.
  final double logBase;

  /// Custom formatter for tick labels.
  ///
  /// If null, uses default number formatting with [unit] suffix if provided.
  final YAxisLabelFormatter? labelFormatter;

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

  // ========== Methods ==========

  /// Creates a copy of this configuration with specified properties overridden.
  ///
  /// All parameters are optional. Properties not specified retain their
  /// current values.
  YAxisConfig copyWith({
    String? id,
    YAxisPosition? position,
    Color? color,
    bool clearColor = false,
    String? label,
    bool clearLabel = false,
    String? unit,
    bool clearUnit = false,
    double? min,
    bool clearMin = false,
    double? max,
    bool clearMax = false,
    double? renderMin,
    bool clearRenderMin = false,
    double? renderMax,
    bool clearRenderMax = false,
    bool? visible,
    bool? showAxisLine,
    bool? showTicks,
    bool? showTickLabels,
    bool? showCrosshairLabel,
    CrosshairLabelPosition? crosshairLabelPosition,
    AxisLabelDisplay? labelDisplay,
    double? minWidth,
    double? maxWidth,
    double? tickLabelPadding,
    double? axisLabelPadding,
    double? axisMargin,
    int? tickCount,
    bool clearTickCount = false,
    AxisScaleType? scaleType,
    double? logBase,
    YAxisLabelFormatter? labelFormatter,
    bool? showMinorTicks,
    int? minorTickCount,
    double? minorTickLength,
  }) {
    return YAxisConfig._internal(
      id: id ?? this.id,
      position: position ?? this.position,
      color: clearColor ? null : (color ?? this.color),
      label: clearLabel ? null : (label ?? this.label),
      unit: clearUnit ? null : (unit ?? this.unit),
      min: clearMin ? null : (min ?? this.min),
      max: clearMax ? null : (max ?? this.max),
      renderMin: clearRenderMin ? null : (renderMin ?? this.renderMin),
      renderMax: clearRenderMax ? null : (renderMax ?? this.renderMax),
      visible: visible ?? this.visible,
      showAxisLine: showAxisLine ?? this.showAxisLine,
      showTicks: showTicks ?? this.showTicks,
      showTickLabels: showTickLabels ?? this.showTickLabels,
      showCrosshairLabel: showCrosshairLabel ?? this.showCrosshairLabel,
      crosshairLabelPosition:
          crosshairLabelPosition ?? this.crosshairLabelPosition,
      labelDisplay: labelDisplay ?? this.labelDisplay,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      tickLabelPadding: tickLabelPadding ?? this.tickLabelPadding,
      axisLabelPadding: axisLabelPadding ?? this.axisLabelPadding,
      axisMargin: axisMargin ?? this.axisMargin,
      tickCount: clearTickCount ? null : (tickCount ?? this.tickCount),
      scaleType: scaleType ?? this.scaleType,
      logBase: logBase ?? this.logBase,
      labelFormatter: labelFormatter ?? this.labelFormatter,
      showMinorTicks: showMinorTicks ?? this.showMinorTicks,
      minorTickCount: minorTickCount ?? this.minorTickCount,
      minorTickLength: minorTickLength ?? this.minorTickLength,
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
        other.renderMin == renderMin &&
        other.renderMax == renderMax &&
        other.visible == visible &&
        other.showAxisLine == showAxisLine &&
        other.showTicks == showTicks &&
        other.showTickLabels == showTickLabels &&
        other.showCrosshairLabel == showCrosshairLabel &&
        other.crosshairLabelPosition == crosshairLabelPosition &&
        other.labelDisplay == labelDisplay &&
        other.minWidth == minWidth &&
        other.maxWidth == maxWidth &&
        other.tickLabelPadding == tickLabelPadding &&
        other.axisLabelPadding == axisLabelPadding &&
        other.axisMargin == axisMargin &&
        other.tickCount == tickCount &&
        other.scaleType == scaleType &&
        other.logBase == logBase &&
        other.labelFormatter == labelFormatter &&
        other.showMinorTicks == showMinorTicks &&
        other.minorTickCount == minorTickCount &&
        other.minorTickLength == minorTickLength;
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        position,
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
        minWidth,
        maxWidth,
        tickLabelPadding,
        axisLabelPadding,
        axisMargin,
        tickCount,
        scaleType,
        logBase,
        labelFormatter,
        showMinorTicks,
        minorTickCount,
        minorTickLength,
      ]);

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
        'renderMin: $renderMin, '
        'renderMax: $renderMax, '
        'visible: $visible, '
        'showAxisLine: $showAxisLine, '
        'showTicks: $showTicks, '
        'showCrosshairLabel: $showCrosshairLabel, '
        'crosshairLabelPosition: $crosshairLabelPosition, '
        'labelDisplay: $labelDisplay, '
        'minWidth: $minWidth, '
        'maxWidth: $maxWidth, '
        'tickLabelPadding: $tickLabelPadding, '
        'axisLabelPadding: $axisLabelPadding, '
        'axisMargin: $axisMargin, '
        'tickCount: $tickCount, '
        'scaleType: $scaleType, '
        'logBase: $logBase, '
        'showMinorTicks: $showMinorTicks, '
        'minorTickCount: $minorTickCount, '
        'minorTickLength: $minorTickLength'
        ')';
  }

  // ========== Helper Methods ==========

  /// Returns true if the axis label should be displayed.
  ///
  /// Based on [labelDisplay] setting:
  /// - Shows label for: labelOnly, labelWithUnit, labelAndTickUnit, labelWithUnitAndTickUnit
  /// - Hides label for: tickUnitOnly, tickOnly, none
  bool get shouldShowAxisLabel {
    return labelDisplay != AxisLabelDisplay.tickUnitOnly &&
        labelDisplay != AxisLabelDisplay.tickOnly &&
        labelDisplay != AxisLabelDisplay.none;
  }

  /// Returns true if the unit should be appended to the axis label.
  ///
  /// Based on [labelDisplay] setting:
  /// - Appends unit for: labelWithUnit, labelWithUnitAndTickUnit
  /// - No unit for: labelOnly, labelAndTickUnit, tickUnitOnly, tickOnly, none
  bool get shouldAppendUnitToLabel {
    return labelDisplay == AxisLabelDisplay.labelWithUnit ||
        labelDisplay == AxisLabelDisplay.labelWithUnitAndTickUnit;
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
    return showTickLabels && labelDisplay != AxisLabelDisplay.none;
  }
}
