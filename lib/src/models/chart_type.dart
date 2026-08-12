/// Built-in series type rendered by `BravenChartPlus`.
///
/// Line, area, bar, scatter, and Candlestick are Cartesian. Pie and Donut are
/// partition-radial. Polar Column is axis-based polar. Radial and polar
/// families cannot mix with Cartesian series or each other.
enum ChartType {
  /// Line chart with connected points.
  line,

  /// Area chart with a filled region under its line.
  area,

  /// Bar chart with vertical bars.
  bar,

  /// Scatter chart with individual points.
  scatter,

  /// Open-high-low-close samples rendered as candle bodies and wicks.
  candlestick,

  /// Pie chart with category contributions rendered as radial slices.
  pie,

  /// Donut chart with category contributions rendered as annular slices.
  donut,

  /// Category columns rendered against angular and radial polar axes.
  polarColumn,

  /// Closed quantitative profiles rendered over shared radial category axes.
  radar,

  /// Independent category tracks whose absolute values map to angular sweep.
  radialBar,

  /// One operational measurement against an explicit domain and status zones.
  gauge,
}
