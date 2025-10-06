/// Scatter chart configuration and styling options
library;

/// Mode for determining marker sizes
///
/// - [fixed]: All markers have the same size
/// - [dataDriven]: Marker size varies based on a third data dimension
enum MarkerSizingMode {
  /// Fixed size for all markers
  fixed,

  /// Size determined by data (bubble chart)
  dataDriven,
}

/// Style of marker rendering
///
/// - [filled]: Solid filled markers
/// - [outlined]: Hollow markers with border only
/// - [both]: Filled markers with visible border
enum MarkerStyle {
  /// Solid filled markers
  filled,

  /// Hollow markers with border
  outlined,

  /// Filled with border
  both,
}
