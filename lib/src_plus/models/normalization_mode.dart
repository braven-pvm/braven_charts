/// Normalization mode for multi-axis charts.
///
/// Controls when and how Y-axis normalization is applied to
/// enable displaying series with vastly different value ranges.
///
/// See also:
/// - [YAxisConfig] for per-axis configuration
/// - [MultiAxisState] for runtime normalization state
library;

/// Controls multi-axis normalization behavior.
///
/// Multi-axis normalization allows series with vastly different Y-ranges
/// (e.g., Power 0-300W vs Heart Rate 60-200bpm) to each use the full
/// vertical plot height while displaying their own properly-scaled Y-axis.
///
/// Example:
/// ```dart
/// // Auto-detect when normalization is needed
/// BravenChartPlus(
///   normalizationMode: NormalizationMode.auto,
///   series: [powerSeries, heartRateSeries],
/// )
///
/// // Always normalize each series independently
/// BravenChartPlus(
///   normalizationMode: NormalizationMode.perSeries,
///   yAxes: [powerAxis, heartRateAxis],
///   series: [powerSeries, heartRateSeries],
/// )
/// ```
enum NormalizationMode {
  /// No normalization - use global Y bounds.
  ///
  /// All series share a single Y-axis with min/max computed from
  /// all series combined. This is the default/legacy behavior.
  ///
  /// Use this when:
  /// - All series have similar Y-ranges
  /// - You want traditional single-axis chart behavior
  /// - Comparing absolute values across series is important
  none,

  /// Automatic detection based on range ratios.
  ///
  /// The system analyzes series Y-ranges and enables multi-axis normalization
  /// when ranges differ by more than the threshold (default: 10x).
  ///
  /// Examples that would trigger multi-axis mode:
  /// - Power (0-300W) vs Tidal Volume (0.5-4L) - ~75x difference
  /// - Temperature (36-40°C) vs Heart Rate (60-200) - ~35x difference
  ///
  /// Use this when:
  /// - You want the system to intelligently choose the best mode
  /// - Series may or may not have different ranges depending on data
  auto,

  /// Always normalize each series independently.
  ///
  /// Each series is normalized to use the full vertical plot height,
  /// regardless of how similar the ranges are. Each series requires
  /// its own Y-axis configuration.
  ///
  /// Use this when:
  /// - You always want separate Y-axes for different metrics
  /// - Conceptually different metrics should not share axes
  /// - You need explicit control over axis configuration
  perSeries,
}
