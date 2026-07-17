/// Defines the positions where Y-axes can appear in a multi-axis chart.
///
/// Multi-axis charts support up to [BravenChartPlus.maxAxesPerSide] Y-axes
/// visible per side simultaneously. Axes on each side are stacked from the
/// plot area outward in declaration order.
///
/// ```
/// [left...] | Chart Area | [...right]
/// ```
///
/// Horizontal bar charts transpose these semantic value-axis positions:
/// [left] axes render below the plot and [right] axes render above it.
///
/// The [left] position is the standard position for the primary Y-axis.
/// Add more axes with [right] (or additional [left] configs on separate series).
enum YAxisPosition {
  /// Left side — adjacent to plot area, stacked outward in declaration order.
  ///
  /// This is the standard position for the main Y-axis in most charts.
  left,

  /// Right side — adjacent to plot area, stacked outward in declaration order.
  ///
  /// Use for secondary or tertiary axes with different scales or units.
  right,

  /// Hidden axis — participates in data normalization but takes no visual space.
  ///
  /// Equivalent to setting [YAxisConfig.visible] to `false`. Use when a series
  /// needs its own Y-axis for normalization purposes but the axis itself
  /// should not be rendered (no ticks, labels, or line).
  ///
  /// Example:
  /// ```dart
  /// LineChartSeries(
  ///   id: 'reference',
  ///   yAxisConfig: YAxisConfig(position: YAxisPosition.hidden, min: 0, max: 100),
  /// )
  /// ```
  hidden,

  /// Deprecated. Use [left] instead.
  ///
  /// Previously: leftmost axis (far left of plot area).
  /// Now: treated identically to [left] at runtime.
  @Deprecated('Use YAxisPosition.left instead. leftOuter is treated as left.')
  leftOuter,

  /// Deprecated. Use [right] instead.
  ///
  /// Previously: rightmost axis (far right of plot area).
  /// Now: treated identically to [right] at runtime.
  @Deprecated(
    'Use YAxisPosition.right instead. rightOuter is treated as right.',
  )
  rightOuter,
}
