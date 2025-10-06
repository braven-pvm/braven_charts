/// Contract: ChartLayer Interface
///
/// Defines the interface that all chart type implementations must follow.
/// This contract extends the RenderLayer interface from the Core Rendering Engine.
///
/// Constitutional Requirements:
/// - Must integrate with RenderPipeline (Architectural Integrity)
/// - Must achieve <16ms frame time for specified data sizes (Performance First)
/// - Must be testable through contract tests (Testing Excellence)
library;

abstract class ChartLayer implements RenderLayer {
  /// The data series to be rendered
  List<ChartSeries> get series;

  /// The theme to apply for styling
  ChartTheme get theme;

  /// The animation configuration for data updates
  ChartAnimationConfig get animationConfig;

  /// Render the chart to the canvas
  ///
  /// PERFORMANCE REQUIREMENT:
  /// - Line/Area charts: Must complete in <16ms for 10,000 data points
  /// - Bar charts: Must complete in <16ms for 1,000 bars
  /// - Scatter charts: Must complete in <16ms for 10,000 points
  ///
  /// @param canvas The canvas to draw on
  /// @param size The available size for rendering
  /// @param context The rendering context with transformer, viewport, etc.
  @override
  void render(Canvas canvas, Size size, RenderContext context);

  /// Determine if the chart should render
  ///
  /// Returns false if there is no data or if the chart is not visible
  /// in the current viewport.
  @override
  bool shouldRender(RenderContext context);

  /// Update the data series with optional animation
  ///
  /// If animationConfig.enabled is true, the transition from old to new data
  /// will be animated. Otherwise, the new data is immediately displayed.
  ///
  /// @param newSeries The new data series to display
  void updateData(List<ChartSeries> newSeries);

  /// Prepare resources needed for rendering
  ///
  /// Called once before rendering begins. Use this to:
  /// - Acquire objects from pools
  /// - Cache transformed coordinates
  /// - Pre-compute bezier curves
  /// - Create gradient shaders
  @override
  void prepare(RenderContext context);

  /// Release resources after rendering
  ///
  /// Called after rendering completes. Use this to:
  /// - Return pooled objects
  /// - Clear caches if needed
  @override
  void dispose();
}
