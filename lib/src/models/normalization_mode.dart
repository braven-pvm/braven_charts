/// Controls when Y-axis normalization is applied in multi-axis charts.
///
/// Normalization allows displaying multiple data series with vastly different
/// value ranges on the same chart, with each series using the full vertical
/// space while showing original values on its associated Y-axis.
///
/// Example use case: Display Power (0-300W) and Heart Rate (60-180bpm) on
/// the same chart, each using the full height of the chart area.
enum NormalizationMode {
  /// No normalization - use global Y bounds.
  ///
  /// All series share a single Y-axis with min/max computed from
  /// all series combined. This is the current/legacy behavior.
  none,

  /// Automatic detection based on range ratios.
  ///
  /// System analyzes series Y-ranges and enables multi-axis normalization
  /// when ranges differ by more than the threshold (default: 10x).
  /// This is the recommended default for most use cases.
  auto,

  /// Always normalize each series independently.
  ///
  /// Each series is normalized to use the full vertical plot height,
  /// regardless of how similar the ranges are. Use this when you want
  /// separate Y-axes for conceptually different metrics even if they
  /// happen to have similar numeric ranges.
  perSeries,
}
