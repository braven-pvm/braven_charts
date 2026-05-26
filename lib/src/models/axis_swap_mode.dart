/// Controls swap persistence when a series is deselected.
///
/// Used with [BravenChartPlus.axisSwapMode] to configure whether a
/// swap triggered by series selection persists after deselection.
///
/// Example:
/// ```dart
/// BravenChartPlus(
///   axisSwapMode: AxisSwapMode.sticky, // default
///   ...
/// )
/// ```
enum AxisSwapMode {
  /// The swapped-in axis stays visible after deselection (default).
  ///
  /// Subsequent selections of other overflow series trigger additional
  /// swaps, each bumping the current last-declared visible axis on that side.
  sticky,

  /// The slot order reverts to original declaration order on deselection.
  ///
  /// Both [BravenChartPlus.onSeriesDeselected] and
  /// [BravenChartPlus.onAxisSwapped] fire with promoted/demoted reversed.
  revert,
}
