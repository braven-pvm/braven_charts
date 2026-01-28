/// Enum types for the braven_agent package.
///
/// This file contains all enumeration types used across the model layer
/// for chart configuration, styling, and annotation options.
library;

/// The type of chart to render.
///
/// Determines the visual representation of data series.
enum ChartType {
  /// Line chart connecting data points with lines.
  line,

  /// Area chart with filled region below the line.
  area,

  /// Bar chart with vertical or horizontal bars.
  bar,

  /// Scatter chart showing individual data points.
  scatter,
}

/// Style of markers displayed at data points.
///
/// Used in [SeriesConfig] to customize how individual data points are rendered.
enum MarkerStyle {
  /// No marker displayed.
  none,

  /// Circular marker.
  circle,

  /// Square marker.
  square,

  /// Triangular marker.
  triangle,

  /// Diamond-shaped marker.
  diamond,
}

/// Interpolation mode for connecting data points in line/area charts.
///
/// Determines how lines are drawn between consecutive data points.
enum Interpolation {
  /// Straight lines between points.
  linear,

  /// Smooth bezier curves between points.
  bezier,

  /// Stepped/staircase pattern between points.
  stepped,

  /// Monotone cubic interpolation preserving monotonicity.
  monotone,
}

/// Type of axis data representation.
///
/// Used for X-axis configuration to specify how values are interpreted.
enum AxisType {
  /// Numeric continuous axis.
  numeric,

  /// Time-based axis for temporal data.
  time,

  /// Categorical axis for discrete categories.
  category,
}

/// Position of Y-axis on the chart.
///
/// Used for multi-axis charts to position Y-axes on left or right sides.
enum AxisPosition {
  /// Y-axis positioned on the left side.
  left,

  /// Y-axis positioned on the right side.
  right,
}

/// Normalization mode for multi-series charts.
///
/// Controls how data values are normalized for display.
enum NormalizationModeConfig {
  /// No normalization applied.
  none,

  /// Automatic normalization across all series.
  auto,

  /// Independent normalization per series.
  perSeries,
}

/// Position of the chart legend.
///
/// Determines where the legend is placed relative to the chart area.
enum LegendPosition {
  /// Legend at the top center.
  top,

  /// Legend at the bottom center.
  bottom,

  /// Legend on the left side.
  left,

  /// Legend on the right side.
  right,

  /// Legend at the top-left corner.
  topLeft,

  /// Legend at the top-right corner.
  topRight,

  /// Legend at the bottom-left corner.
  bottomLeft,

  /// Legend at the bottom-right corner.
  bottomRight,
}

/// Type of chart annotation.
///
/// Annotations provide additional context or highlights on charts.
enum AnnotationType {
  /// Reference line (horizontal or vertical) at a specific value.
  referenceLine,

  /// Shaded zone between two values.
  zone,

  /// Text label annotation.
  textLabel,

  /// Point marker annotation.
  marker,
}

/// Orientation for reference lines and other directional elements.
enum Orientation {
  /// Horizontal orientation (parallel to X-axis).
  horizontal,

  /// Vertical orientation (parallel to Y-axis).
  vertical,
}

/// Position for text labels and markers using a 9-position grid.
///
/// Provides fine-grained control over annotation placement.
enum AnnotationPosition {
  /// Top-left corner.
  topLeft,

  /// Top center.
  topCenter,

  /// Top-right corner.
  topRight,

  /// Center-left.
  centerLeft,

  /// Center.
  center,

  /// Center-right.
  centerRight,

  /// Bottom-left corner.
  bottomLeft,

  /// Bottom center.
  bottomCenter,

  /// Bottom-right corner.
  bottomRight,
}
