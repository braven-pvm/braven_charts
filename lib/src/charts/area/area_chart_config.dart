/// Area chart configuration and styling options
library;

/// Style of area fill rendering
///
/// Determines how the area under the line is filled:
/// - [solid]: Solid color fill with optional opacity
/// - [gradient]: Vertical gradient from line to baseline
/// - [pattern]: Pattern fill (e.g., diagonal lines, dots)
enum AreaFillStyle {
  /// Solid color fill with opacity control
  solid,

  /// Vertical gradient from top (line) to bottom (baseline)
  gradient,

  /// Pattern fill (diagonal lines, dots, etc.)
  pattern,
}

/// Type of baseline for area chart
///
/// Determines what the area is filled relative to:
/// - [zero]: Fill from zero line (y=0)
/// - [fixed]: Fill from a fixed y-value
/// - [series]: Fill from another data series
enum AreaBaselineType {
  /// Fill from y=0 (zero line)
  zero,

  /// Fill from a fixed y-value
  fixed,

  /// Fill from another data series
  series,
}
