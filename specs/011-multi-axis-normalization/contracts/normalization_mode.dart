/// Contract: NormalizationMode
///
/// Enum controlling when and how Y-axis normalization is applied.
library;

/// Controls multi-axis normalization behavior.
///
/// Example:
/// ```dart
/// BravenChartPlus(
///   normalizationMode: NormalizationMode.auto,
///   series: [powerSeries, heartRateSeries],
/// )
/// ```
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
  ///
  /// Example: Power (0-300W) and Tidal Volume (0.5-4L) differ by ~75x,
  /// so auto-detection would enable multi-axis mode.
  auto,

  /// Always normalize each series independently.
  ///
  /// Each series is normalized to use the full vertical plot height,
  /// regardless of how similar the ranges are. Use this when you want
  /// separate Y-axes for conceptually different metrics even if they
  /// happen to have similar numeric ranges.
  perSeries,
}
