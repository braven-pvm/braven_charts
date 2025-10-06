/// Base chart configuration and styling options
library;

/// Shape of chart markers (data points)
///
/// Defines the visual representation of individual data points:
/// - [circle]: Circular marker
/// - [square]: Square marker
/// - [triangle]: Triangular marker pointing up
/// - [diamond]: Diamond/rhombus marker
/// - [cross]: Cross (+) marker
/// - [plus]: Plus (x) marker rotated 45°
/// - [none]: No marker (useful for line charts without points)
enum MarkerShape {
  /// Circular marker (●)
  circle,

  /// Square marker (■)
  square,

  /// Triangular marker (▲)
  triangle,

  /// Diamond marker (◆)
  diamond,

  /// Cross marker (+)
  cross,

  /// Plus marker (x) - cross rotated 45°
  plus,

  /// No marker - just the line
  none,
}
