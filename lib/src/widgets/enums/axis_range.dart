/// Axis range calculation modes
/// 
/// Defines how axis ranges are determined.
enum AxisRange {
  /// Automatically calculate from data
  auto,

  /// Use user-specified min/max values
  fixed,

  /// Auto-calculate with padding
  padded,
}
