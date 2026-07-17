/// Built-in series type rendered by `BravenChartPlus`.
///
/// Line, area, bar, and scatter are Cartesian and may share one chart. Pie and
/// Donut are radial, accept exactly one radial category series, and cannot mix
/// with the Cartesian types or each other.
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

  /// Donut chart with category contributions rendered as annular slices.
  donut,
}
