/// Defines the positions where Y-axes can appear in a multi-axis chart.
///
/// Multi-axis charts support up to 4 Y-axes simultaneously, positioned
/// in a specific layout order from left to right:
///
/// ```
/// [leftOuter] [left] | Chart Area | [right] [rightOuter]
/// ```
///
/// The [left] position is typically the primary/default position for
/// single-axis charts. When additional axes are needed, they can be
/// placed at [right], [leftOuter], or [rightOuter] positions.
enum YAxisPosition {
  /// Leftmost axis (far left of plot area).
  ///
  /// Use for a secondary axis on the left side when [left] is already
  /// occupied by the primary axis.
  leftOuter,

  /// Primary left axis (adjacent to plot area left edge).
  ///
  /// This is the standard position for the main Y-axis in most charts.
  /// Use this for the primary data series axis.
  left,

  /// Primary right axis (adjacent to plot area right edge).
  ///
  /// Use for a secondary axis when displaying two data series with
  /// different scales or units.
  right,

  /// Rightmost axis (far right of plot area).
  ///
  /// Use for a tertiary or quaternary axis when both [left] and [right]
  /// positions are already occupied.
  rightOuter,
}
