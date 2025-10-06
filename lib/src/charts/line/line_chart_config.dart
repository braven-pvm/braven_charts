/// Line chart configuration and styling options
library;

/// Style of line rendering
///
/// Determines how the line connects data points:
/// - [straight]: Direct linear connection between points
/// - [smooth]: Smooth bezier curve through points
/// - [stepped]: Horizontal-then-vertical steps between points
enum LineStyle {
  /// Connect points with straight line segments
  straight,

  /// Connect points with smooth bezier curves
  smooth,

  /// Connect points with horizontal-then-vertical steps (step chart)
  stepped,
}
