/// Defines the positions where Y-axes can appear in a multi-axis chart.
///
/// Multi-axis charts support up to 4 Y-axes simultaneously, positioned
/// in a specific layout order from left to right:
///
/// ```
/// [outerLeft] [left] | Chart Area | [right] [outerRight]
/// ```
///
/// The [left] position is typically the primary/default position for
/// single-axis charts. When additional axes are needed, they can be
/// placed at [right], [outerLeft], or [outerRight] positions.
enum YAxisPosition {
  /// Leftmost position, outside of [left].
  ///
  /// Use for a secondary axis on the left side when [left] is already
  /// occupied by the primary axis.
  outerLeft,

  /// Inner left position (primary/default position).
  ///
  /// This is the standard position for the main Y-axis in most charts.
  /// Use this for the primary data series axis.
  left,

  /// Inner right position.
  ///
  /// Use for a secondary axis when displaying two data series with
  /// different scales or units.
  right,

  /// Rightmost position, outside of [right].
  ///
  /// Use for a tertiary or quaternary axis when both [left] and [right]
  /// positions are already occupied.
  outerRight,
}
