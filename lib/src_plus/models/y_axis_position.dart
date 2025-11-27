/// Y-axis position relative to the plot area.
///
/// Multi-axis charts support up to 4 Y-axes positioned around the plot area.
/// Layout order (left to right):
/// ```
/// [leftOuter] [left] [PLOT AREA] [right] [rightOuter]
/// ```
///
/// See also:
/// - [YAxisConfig] for complete axis configuration
/// - [MultiAxisState] for runtime axis state
library;

/// Position of Y-axis relative to the plot area.
///
/// Example:
/// ```dart
/// final powerAxis = YAxisConfig(
///   id: 'power',
///   position: YAxisPosition.left,
///   unit: 'W',
/// );
///
/// final heartRateAxis = YAxisConfig(
///   id: 'heartRate',
///   position: YAxisPosition.right,
///   unit: 'bpm',
/// );
/// ```
enum YAxisPosition {
  /// Leftmost axis position (far left of plot area).
  ///
  /// Use for a secondary left-side metric when [left] is already occupied.
  leftOuter,

  /// Primary left axis position (adjacent to plot area left edge).
  ///
  /// This is the default position and should be used for the primary metric.
  left,

  /// Primary right axis position (adjacent to plot area right edge).
  ///
  /// Use for secondary metrics that should appear on the right side.
  right,

  /// Rightmost axis position (far right of plot area).
  ///
  /// Use for a tertiary right-side metric when [right] is already occupied.
  rightOuter;

  /// Whether this position is on the left side of the plot area.
  bool get isLeft => this == leftOuter || this == left;

  /// Whether this position is on the right side of the plot area.
  bool get isRight => this == right || this == rightOuter;

  /// Whether this is an outer (non-adjacent) position.
  bool get isOuter => this == leftOuter || this == rightOuter;

  /// Whether this is an inner (adjacent to plot area) position.
  bool get isInner => this == left || this == right;
}
