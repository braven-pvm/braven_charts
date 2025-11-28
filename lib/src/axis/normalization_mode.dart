/// Defines how normalization is applied in multi-axis charts.
///
/// When multiple data series with vastly different Y-ranges are displayed
/// together, normalization ensures each series uses the full vertical
/// height of the chart while maintaining its own properly-scaled Y-axis.
///
/// Example:
/// ```dart
/// final mode = NormalizationMode.auto;
/// ```
enum NormalizationMode {
  /// No normalization - traditional single-axis behavior.
  ///
  /// All series share the same Y-axis scale. Series with smaller ranges
  /// may appear as flat lines when displayed alongside series with larger
  /// ranges. Use this when all series have compatible value ranges.
  none,

  /// Automatically enable normalization when series ranges differ significantly.
  ///
  /// The chart analyzes the data ranges of all series and enables multi-axis
  /// normalization when the ratio between the largest and smallest range
  /// exceeds a threshold (typically 10x). This is the recommended default
  /// for most use cases as it provides intelligent behavior without
  /// manual configuration.
  auto,

  /// Always normalize all series to use the full chart height.
  ///
  /// Each series is scaled independently to span the full vertical space,
  /// regardless of whether their ranges are similar. Use this when you
  /// always want separate Y-axes for visual comparison of trends rather
  /// than absolute values.
  always,
}
