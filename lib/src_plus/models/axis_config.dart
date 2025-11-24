/// Axis configuration models.
///
/// This library provides configuration for chart axes, including range,
/// visibility, styling, and behavior.
library;

import 'dart:ui' show Color, Offset;

import 'package:flutter/widgets.dart' show TextStyle;

import 'enums.dart';

/// Typedef for custom axis label formatters.
typedef AxisLabelFormatter = String Function(double value);

/// Value object representing a fixed axis range.
class AxisRange {
  /// Creates a fixed range with explicit min and max values.
  factory AxisRange.fixed(double min, double max) {
    return AxisRange(min, max);
  }

  /// Creates a range centered on a specific value.
  ///
  /// For example, `AxisRange.centered(50, 20)` creates a range from 40 to 60.
  factory AxisRange.centered(double center, double range) {
    final halfRange = range / 2;
    return AxisRange(center - halfRange, center + halfRange);
  }

  /// Creates an axis range with the specified min and max values.
  ///
  /// Throws [AssertionError] if min >= max.
  const AxisRange(this.min, this.max) : assert(min < max, 'Axis range min must be less than max');

  /// The minimum value of the axis range.
  final double min;

  /// The maximum value of the axis range.
  final double max;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AxisRange && other.min == min && other.max == max;
  }

  @override
  int get hashCode => Object.hash(min, max);

  @override
  String toString() => 'AxisRange($min, $max)';
}

/// Comprehensive axis configuration with factory presets.
///
/// Provides 45+ properties organized into logical groups for complete
/// axis customization. Supports factory constructors for common patterns.
///
/// Example:
/// ```dart
/// // Standard axis with all components
/// AxisConfig.defaults()
///
/// // Hidden axis for sparklines
/// AxisConfig.hidden()
///
/// // Custom axis
/// AxisConfig(
///   label: 'Temperature (°C)',
///   range: AxisRange(-10, 50),
///   labelFormatter: (value) => '${value.toInt()}°C',
///   gridColor: Color(0xFFE0E0E0), // Colors.grey.shade300
/// )
/// ```
class AxisConfig {
  // ========== Factory Constructors ==========

  /// Creates a standard axis configuration with all components visible.
  factory AxisConfig.defaults() {
    return const AxisConfig();
  }

  /// Creates a hidden axis configuration (for sparklines, embedded charts).
  ///
  /// All axis components are hidden: axis line, grid, ticks, and labels.
  factory AxisConfig.hidden() {
    return const AxisConfig(
      showAxis: false,
      showGrid: false,
      showTicks: false,
      showLabels: false,
    );
  }

  /// Creates a minimal axis configuration with grid lines only.
  ///
  /// Hides axis line, ticks, and labels but shows grid for reference.
  factory AxisConfig.minimal() {
    return const AxisConfig(
      showAxis: false,
      showTicks: false,
      showLabels: false,
      showGrid: true,
    );
  }

  /// Creates a grid-only configuration.
  ///
  /// Shows only grid lines, hiding axis line, ticks, and labels.
  factory AxisConfig.gridOnly() {
    return const AxisConfig(
      showAxis: false,
      showGrid: true,
      showTicks: false,
      showLabels: false,
    );
  }

  /// Creates an axis configuration.
  ///
  /// All parameters are optional with sensible defaults.
  /// Validation ensures positive widths and valid rotation angles.
  const AxisConfig({
    // Visibility
    this.showAxis = true,
    this.showGrid = true,
    this.showTicks = true,
    this.showLabels = true,
    // Range
    this.range,
    this.allowZoom = false,
    this.allowPan = false,
    // Axis Line
    this.axisColor,
    this.axisWidth = 1.0,
    this.axisPosition = AxisPosition.bottom,
    // Grid Lines
    this.gridColor,
    this.gridWidth = 0.5,
    this.gridDashPattern,
    this.showMinorGrid = false,
    this.minorGridColor,
    // Ticks
    this.tickLength = 6.0,
    this.tickWidth = 1.0,
    this.tickColor,
    this.customTickPositions,
    // Labels
    this.label,
    this.labelFormatter,
    this.maxLabels,
    this.labelRotation = 0.0,
    this.labelOffset = Offset.zero,
    this.labelStyle,
    this.reservedSize,
    // Advanced
    this.highlightZeroLine = false,
    this.zeroLineColor,
    this.zeroLineWidth = 1.5,
    this.logarithmic = false,
    this.inverted = false,
  })  : assert(axisWidth >= 0.0, 'axisWidth must be non-negative'),
        assert(gridWidth >= 0.0, 'gridWidth must be non-negative'),
        assert(tickLength >= 0.0, 'tickLength must be non-negative'),
        assert(tickWidth >= 0.0, 'tickWidth must be non-negative'),
        assert(zeroLineWidth >= 0.0, 'zeroLineWidth must be non-negative'),
        assert(
          reservedSize == null || reservedSize >= 0.0,
          'reservedSize must be non-negative if specified',
        ),
        assert(
          labelRotation >= -180.0 && labelRotation <= 180.0,
          'labelRotation must be between -180° and 180°',
        ),
        assert(
          maxLabels == null || maxLabels > 0,
          'maxLabels must be positive if specified',
        );

  // ========== Visibility ==========

  /// Whether to show the axis line.
  final bool showAxis;

  /// Whether to show grid lines.
  final bool showGrid;

  /// Whether to show tick marks.
  final bool showTicks;

  /// Whether to show labels.
  final bool showLabels;

  // ========== Range ==========

  /// Fixed axis range. If null, range is auto-calculated from data.
  final AxisRange? range;

  /// Whether to enable zoom interaction on this axis.
  final bool allowZoom;

  /// Whether to enable pan interaction on this axis.
  final bool allowPan;

  // ========== Axis Line ==========

  /// Color of the axis line. If null, uses theme default.
  final Color? axisColor;

  /// Width of the axis line in logical pixels.
  final double axisWidth;

  /// Position of the axis relative to the chart area.
  final AxisPosition axisPosition;

  // ========== Grid Lines ==========

  /// Color of major grid lines. If null, uses theme default.
  final Color? gridColor;

  /// Width of major grid lines in logical pixels.
  final double gridWidth;

  /// Dash pattern for grid lines. If null, grid lines are solid.
  ///
  /// Example: `[5, 3]` for 5px dash, 3px gap.
  final List<double>? gridDashPattern;

  /// Whether to show minor grid lines between major grid lines.
  final bool showMinorGrid;

  /// Color of minor grid lines. If null, uses theme default.
  final Color? minorGridColor;

  // ========== Ticks ==========

  /// Length of tick marks in logical pixels.
  final double tickLength;

  /// Width of tick marks in logical pixels.
  final double tickWidth;

  /// Color of tick marks. If null, uses theme default.
  final Color? tickColor;

  /// Custom tick positions. If null, positions are auto-calculated.
  final List<double>? customTickPositions;

  // ========== Labels ==========

  /// Axis label text (e.g., "Temperature (°C)").
  final String? label;

  /// Custom formatter for axis tick labels.
  ///
  /// If null, uses default number formatting.
  final AxisLabelFormatter? labelFormatter;

  /// Maximum number of labels to display. If null, calculated automatically.
  final int? maxLabels;

  /// Label rotation in degrees (-180° to 180°).
  ///
  /// Positive values rotate counter-clockwise.
  final double labelRotation;

  /// Offset to shift label positions.
  final Offset labelOffset;

  /// Text style for labels. If null, uses theme default.
  final TextStyle? labelStyle;

  /// Reserved space for axis labels and ticks in logical pixels.
  ///
  /// If null, space is calculated dynamically based on actual label sizes.
  /// If provided, this exact amount of space is reserved regardless of label content.
  ///
  /// For Y-axis: This is the width reserved on left or right.
  /// For X-axis: This is the height reserved on top or bottom.
  ///
  /// Example:
  /// ```dart
  /// AxisConfig(
  ///   reservedSize: 60.0,  // Reserve 60px for labels
  /// )
  /// ```
  final double? reservedSize;

  // ========== Advanced ==========

  /// Whether to highlight the zero line with special styling.
  final bool highlightZeroLine;

  /// Color of the zero line. Only used if [highlightZeroLine] is true.
  final Color? zeroLineColor;

  /// Width of the zero line. Only used if [highlightZeroLine] is true.
  final double zeroLineWidth;

  /// Whether to use logarithmic scale for this axis.
  final bool logarithmic;

  /// Whether to invert the axis direction (reverse min/max).
  final bool inverted;

  // ========== Methods ==========

  /// Creates a copy of this configuration with specified properties overridden.
  AxisConfig copyWith({
    // Visibility
    bool? showAxis,
    bool? showGrid,
    bool? showTicks,
    bool? showLabels,
    // Range
    AxisRange? range,
    bool? allowZoom,
    bool? allowPan,
    // Axis Line
    Color? axisColor,
    double? axisWidth,
    AxisPosition? axisPosition,
    // Grid Lines
    Color? gridColor,
    double? gridWidth,
    List<double>? gridDashPattern,
    bool? showMinorGrid,
    Color? minorGridColor,
    // Ticks
    double? tickLength,
    double? tickWidth,
    Color? tickColor,
    List<double>? customTickPositions,
    // Labels
    String? label,
    AxisLabelFormatter? labelFormatter,
    int? maxLabels,
    double? labelRotation,
    Offset? labelOffset,
    TextStyle? labelStyle,
    double? reservedSize,
    // Advanced
    bool? highlightZeroLine,
    Color? zeroLineColor,
    double? zeroLineWidth,
    bool? logarithmic,
    bool? inverted,
  }) {
    return AxisConfig(
      // Visibility
      showAxis: showAxis ?? this.showAxis,
      showGrid: showGrid ?? this.showGrid,
      showTicks: showTicks ?? this.showTicks,
      showLabels: showLabels ?? this.showLabels,
      // Range
      range: range ?? this.range,
      allowZoom: allowZoom ?? this.allowZoom,
      allowPan: allowPan ?? this.allowPan,
      // Axis Line
      axisColor: axisColor ?? this.axisColor,
      axisWidth: axisWidth ?? this.axisWidth,
      axisPosition: axisPosition ?? this.axisPosition,
      // Grid Lines
      gridColor: gridColor ?? this.gridColor,
      gridWidth: gridWidth ?? this.gridWidth,
      gridDashPattern: gridDashPattern ?? this.gridDashPattern,
      showMinorGrid: showMinorGrid ?? this.showMinorGrid,
      minorGridColor: minorGridColor ?? this.minorGridColor,
      // Ticks
      tickLength: tickLength ?? this.tickLength,
      tickWidth: tickWidth ?? this.tickWidth,
      tickColor: tickColor ?? this.tickColor,
      customTickPositions: customTickPositions ?? this.customTickPositions,
      // Labels
      label: label ?? this.label,
      labelFormatter: labelFormatter ?? this.labelFormatter,
      maxLabels: maxLabels ?? this.maxLabels,
      labelRotation: labelRotation ?? this.labelRotation,
      labelOffset: labelOffset ?? this.labelOffset,
      labelStyle: labelStyle ?? this.labelStyle,
      reservedSize: reservedSize ?? this.reservedSize,
      // Advanced
      highlightZeroLine: highlightZeroLine ?? this.highlightZeroLine,
      zeroLineColor: zeroLineColor ?? this.zeroLineColor,
      zeroLineWidth: zeroLineWidth ?? this.zeroLineWidth,
      logarithmic: logarithmic ?? this.logarithmic,
      inverted: inverted ?? this.inverted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AxisConfig &&
        other.showAxis == showAxis &&
        other.showGrid == showGrid &&
        other.showTicks == showTicks &&
        other.showLabels == showLabels &&
        other.range == range &&
        other.allowZoom == allowZoom &&
        other.allowPan == allowPan &&
        other.axisColor == axisColor &&
        other.axisWidth == axisWidth &&
        other.axisPosition == axisPosition &&
        other.gridColor == gridColor &&
        other.gridWidth == gridWidth &&
        _listEquals(other.gridDashPattern, gridDashPattern) &&
        other.showMinorGrid == showMinorGrid &&
        other.minorGridColor == minorGridColor &&
        other.tickLength == tickLength &&
        other.tickWidth == tickWidth &&
        other.tickColor == tickColor &&
        _listEquals(other.customTickPositions, customTickPositions) &&
        other.label == label &&
        other.labelFormatter == labelFormatter &&
        other.maxLabels == maxLabels &&
        other.labelRotation == labelRotation &&
        other.labelOffset == labelOffset &&
        other.labelStyle == labelStyle &&
        other.reservedSize == reservedSize &&
        other.highlightZeroLine == highlightZeroLine &&
        other.zeroLineColor == zeroLineColor &&
        other.zeroLineWidth == zeroLineWidth &&
        other.logarithmic == logarithmic &&
        other.inverted == inverted;
  }

  @override
  int get hashCode => Object.hashAll([
        showAxis,
        showGrid,
        showTicks,
        showLabels,
        range,
        allowZoom,
        allowPan,
        axisColor,
        axisWidth,
        axisPosition,
        gridColor,
        gridWidth,
        Object.hashAll(gridDashPattern ?? []),
        showMinorGrid,
        minorGridColor,
        tickLength,
        tickWidth,
        tickColor,
        Object.hashAll(customTickPositions ?? []),
        label,
        labelFormatter,
        maxLabels,
        labelRotation,
        labelOffset,
        labelStyle,
        reservedSize,
        highlightZeroLine,
        zeroLineColor,
        zeroLineWidth,
        logarithmic,
        inverted,
      ]);

  /// Helper to compare nullable lists.
  bool _listEquals(List<double>? a, List<double>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
