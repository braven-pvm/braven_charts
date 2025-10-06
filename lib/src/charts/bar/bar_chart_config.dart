/// Bar chart configuration and styling options
library;

/// Orientation of bars
///
/// - [vertical]: Bars extend vertically from baseline (standard column chart)
/// - [horizontal]: Bars extend horizontally from baseline
enum BarOrientation {
  /// Vertical bars (column chart)
  vertical,

  /// Horizontal bars
  horizontal,
}

/// Grouping mode for multiple series
///
/// - [grouped]: Bars are placed side-by-side within each category
/// - [stacked]: Bars are stacked on top of each other
enum BarGroupingMode {
  /// Side-by-side bars for each series
  grouped,

  /// Stacked bars (one on top of another)
  stacked,
}
