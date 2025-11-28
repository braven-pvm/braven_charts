/// Defines the positions for Y-axes in multi-axis charts.
///
/// Multi-axis charts can have up to 4 Y-axes positioned on the left and right
/// sides of the chart. This enum specifies where each axis should be rendered.
///
/// Axis ordering from left to right:
/// - [outerLeft] - Furthest left position (outside the left axis)
/// - [left] - Standard left position (primary left axis)
/// - [right] - Standard right position (primary right axis)
/// - [outerRight] - Furthest right position (outside the right axis)
///
/// Example:
/// ```dart
/// final position = YAxisPosition.left;
/// ```
enum YAxisPosition {
  /// Furthest left position, outside the standard left axis.
  ///
  /// Use this for secondary data that should be visually separated
  /// from the primary left axis.
  outerLeft,

  /// Standard left position for the primary left Y-axis.
  ///
  /// This is the default position for charts with a single left axis.
  left,

  /// Standard right position for the primary right Y-axis.
  ///
  /// This is the default position for charts with a single right axis.
  right,

  /// Furthest right position, outside the standard right axis.
  ///
  /// Use this for secondary data that should be visually separated
  /// from the primary right axis.
  outerRight,
}
