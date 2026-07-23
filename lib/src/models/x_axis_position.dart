/// Visual edge used by a Cartesian X-axis.
enum XAxisPosition {
  /// Paint the axis below the plot area.
  bottom,

  /// Paint the axis above the plot area.
  top,

  /// Paint mirrored axes above and below the plot area.
  ///
  /// Tick marks, tick labels, and crosshair values appear on both edges. The
  /// axis title is painted once on the conventional bottom edge.
  both,
}
