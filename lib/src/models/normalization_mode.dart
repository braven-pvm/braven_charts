/// Controls when Y-axis normalization is applied in multi-axis charts.
///
/// Normalization allows displaying multiple data series with vastly different
/// value ranges on the same chart, with each series using the full vertical
/// space while showing original values on its associated Y-axis.
///
/// Example use case: Display Power (0-300W) and Heart Rate (60-180bpm) on
/// the same chart, each using the full height of the chart area.
enum NormalizationMode {
  /// Never normalize data.
  ///
  /// The chart behaves as a traditional single-axis chart. All series
  /// share the same Y-axis scale, which may cause series with smaller
  /// ranges to appear flat.
  disabled,

  /// Automatically detect when normalization is needed.
  ///
  /// Normalization is applied when data ranges differ significantly
  /// (e.g., when one series range is more than 10x larger than another).
  /// This is the recommended default for most use cases.
  auto,

  /// Always normalize, regardless of data ranges.
  ///
  /// Each series is independently normalized to use the full vertical
  /// space, even if the data ranges are similar. Use this when you
  /// always want consistent visual treatment across series.
  always,
}
