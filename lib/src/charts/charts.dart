/// Chart Types Library
///
/// Provides four core chart implementations (Line, Area, Bar, Scatter) as
/// RenderLayer implementations for the Braven Charts library.
///
/// This library exports all public APIs for chart type implementations,
/// configuration classes, and enumerations.
///
/// ## Chart Layer Implementations
/// - [LineChartLayer]: Renders line charts with straight/smooth/stepped interpolation
/// - [AreaChartLayer]: Renders area charts with solid/gradient fills and stacking
/// - [BarChartLayer]: Renders bar charts with grouped/stacked modes and orientations
/// - [ScatterChartLayer]: Renders scatter plots with fixed/data-driven sizing
///
/// ## Configuration Classes
/// - [LineChartConfig]: Configuration for line chart rendering
/// - [AreaChartConfig]: Configuration for area chart rendering
/// - [BarChartConfig]: Configuration for bar chart rendering
/// - [ScatterChartConfig]: Configuration for scatter chart rendering
///
/// ## Enumerations
/// - [LineStyle]: Line interpolation styles (straight, smooth, stepped)
/// - [MarkerShape]: Marker shapes (circle, square, triangle, diamond, cross, plus, none)
/// - [AreaFillStyle]: Area fill styles (solid, gradient, pattern)
/// - [AreaBaselineType]: Baseline types for areas (zero, fixed, series)
/// - [BarOrientation]: Bar orientations (vertical, horizontal)
/// - [BarGroupingMode]: Bar grouping modes (grouped, stacked)
/// - [MarkerSizingMode]: Marker sizing modes (fixed, dataDriven)
/// - [MarkerStyle]: Marker rendering styles (filled, outlined, both)
library;

// Area charts
export 'area/area_chart_config.dart' show AreaChartConfig, AreaFillStyle, AreaBaselineType;
export 'area/area_chart_layer.dart' show AreaChartLayer;
export 'area/area_stacking.dart' show AreaStacking;
// Bar charts
export 'bar/bar_chart_config.dart' show BarChartConfig, BarOrientation, BarGroupingMode;
export 'bar/bar_chart_layer.dart' show BarChartLayer;
export 'bar/bar_positioner.dart' show BarPositioner, BarLayoutInfo;
// Base classes and utilities
export 'base/chart_config.dart' show MarkerShape;
export 'base/chart_layer.dart' show ChartLayer, ChartTheme, ChartAnimationConfig;
export 'base/chart_renderer.dart' show ChartRenderer;
// Line charts
export 'line/line_chart_config.dart' show LineChartConfig, LineStyle;
export 'line/line_chart_layer.dart' show LineChartLayer;
export 'line/line_interpolator.dart' show LineInterpolator;
// Scatter charts
export 'scatter/scatter_chart_config.dart' show ScatterChartConfig, MarkerSizingMode, MarkerStyle;
export 'scatter/scatter_chart_layer.dart' show ScatterChartLayer;
export 'scatter/scatter_clusterer.dart' show ScatterClusterer, ClusterInfo, ClusterResult;
