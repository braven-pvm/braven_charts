/// Shared enums for BravenChartPlus
library;

export 'multi_axis_config.dart';
export 'normalization_mode.dart';
export 'series_axis_binding.dart';
export 'y_axis_config.dart';
export 'y_axis_position.dart';

/// Style of line rendering
///
/// **DEPRECATED**: Use [LineInterpolation] on individual [ChartSeries] instead.
/// This enum was used by the widget-level lineStyle parameter which has been removed.
/// Interpolation should now be set directly on each series for fine-grained control.
///
/// Kept for legacy compatibility with lib/legacy code.
///
/// Determines how the line connects data points:
/// - [straight]: Direct linear connection between points (use [LineInterpolation.linear])
/// - [smooth]: Smooth bezier curve through points (use [LineInterpolation.bezier])
/// - [stepped]: Horizontal-then-vertical steps between points (use [LineInterpolation.stepped])
@Deprecated('Use LineInterpolation on ChartSeries instead')
enum LineStyle {
  /// Connect points with straight line segments
  straight,

  /// Connect points with smooth bezier curves
  smooth,

  /// Connect points with horizontal-then-vertical steps (step chart)
  stepped,
}

/// Shape of chart markers (data points)
///
/// Defines the visual representation of individual data points:
/// - [circle]: Circular marker
/// - [square]: Square marker
/// - [triangle]: Triangular marker pointing up
/// - [diamond]: Diamond/rhombus marker
/// - [cross]: Cross (+) marker
/// - [plus]: Plus (x) marker rotated 45°
/// - [none]: No marker (useful for line charts without points)
enum MarkerShape {
  /// Circular marker (●)
  circle,

  /// Square marker (■)
  square,

  /// Triangular marker (▲)
  triangle,

  /// Diamond marker (◆)
  diamond,

  /// Star marker (★)
  star,

  /// Cross marker (+)
  cross,

  /// Plus marker (x) - cross rotated 45°
  plus,

  /// No marker - just the line
  none,
}

/// Position of the axis relative to the chart area.
enum AxisPosition {
  /// Axis at the bottom of the chart (default for X-axis).
  bottom,

  /// Axis at the top of the chart.
  top,

  /// Axis at the left of the chart (default for Y-axis).
  left,

  /// Axis at the right of the chart.
  right,
}
