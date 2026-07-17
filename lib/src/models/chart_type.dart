/// Built-in series type rendered by `BravenChartPlus`.
///
/// Line, area, bar, and scatter are Cartesian and may share one chart. Pie is
/// radial, accepts exactly one `PieChartSeries`, and cannot mix with the
/// Cartesian types.
enum ChartType {
  /// Line chart with connected points.
  line,

  /// Area chart with a filled region under its line.
  area,

  /// Bar chart with vertical bars.
  bar,

  /// Scatter chart with individual points.
  scatter,

  /// Pie chart with category contributions rendered as radial slices.
  pie,
}
