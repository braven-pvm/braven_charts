// Implementation: ChartLayer Base Class
// Feature: 005-chart-types
// Purpose: Abstract base class for all chart type implementations
//
// Constitutional Compliance:
// - Extends RenderLayer from Core Rendering Engine (Architectural Integrity)
// - Must achieve <16ms frame time for specified data sizes (Performance First)
// - TDD: Contract tests written first (test/charts/contract/chart_layer_contract_test.dart)

import 'package:braven_charts/src/foundation/foundation.dart'
    show ChartSeries;
import 'package:braven_charts/src/rendering/render_context.dart';
import 'package:braven_charts/src/rendering/render_layer.dart';

// TODO: Import theming when Layer 3 (Theming) is implemented
// For now, use placeholders

/// Placeholder for ChartTheme until Layer 3 (Theming System) is implemented.
///
/// This allows ChartLayer to compile and be tested without the full
/// theming system. Will be replaced with actual ChartTheme import.
class ChartTheme {
  const ChartTheme();
}

/// Placeholder for ChartAnimationConfig until animation is implemented.
///
/// This allows ChartLayer to compile and be tested without the full
/// animation system. Will be replaced with actual AnimationConfig import.
class ChartAnimationConfig {
  const ChartAnimationConfig();
}

/// Abstract base class for all chart type implementations.
///
/// [ChartLayer] extends [RenderLayer] from the Core Rendering Engine
/// and provides chart-specific functionality such as:
/// - Data series management
/// - Theme application
/// - Animation support
/// - Data update handling
///
/// ## Contract Requirements
///
/// Implementations (LineChartLayer, AreaChartLayer, BarChartLayer,
/// ScatterChartLayer) MUST:
///
/// 1. **Rendering**: Override [render] to draw chart using data from [series],
///    styled according to [theme], and respecting viewport from [context].
///
/// 2. **Performance**: Complete rendering within frame budget:
///    - Line/Area charts: <16ms for 10,000 data points
///    - Bar charts: <16ms for 1,000 bars
///    - Scatter charts: <16ms for 10,000 points
///
/// 3. **Emptiness**: Override [isEmpty] to return true when no data to render
///    (enables pipeline optimization).
///
/// 4. **Resource Management**: Override [prepare] to acquire pooled objects
///    and [dispose] to release them. Use try-finally pattern.
///
/// 5. **Data Updates**: Override [updateData] to handle series changes with
///    optional animation based on [animationConfig].
///
/// ## Example Usage
///
/// ```dart
/// class LineChartLayer extends ChartLayer {
///   LineChartLayer({
///     required super.series,
///     required super.theme,
///     required super.animationConfig,
///     required super.zIndex,
///   });
///
///   @override
///   void render(RenderContext context) {
///     if (isEmpty) return;
///
///     final paint = context.paintPool.acquire();
///     try {
///       paint.color = theme.seriesTheme.colors.first;
///       paint.strokeWidth = 2.0;
///       paint.style = PaintingStyle.stroke;
///
///       for (final s in series) {
///         // Transform points and draw line
///         final path = _interpolator.interpolate(s.points);
///         context.canvas.drawPath(path, paint);
///       }
///     } finally {
///       context.paintPool.release(paint);
///     }
///   }
///
///   @override
///   bool get isEmpty => series.isEmpty || series.every((s) => s.isEmpty);
/// }
/// ```
///
/// ## Lifecycle
///
/// 1. **Construction**: Create with series, theme, animationConfig
/// 2. **Preparation**: Call [prepare] to acquire resources
/// 3. **Rendering**: Call [render] on each frame
/// 4. **Updates**: Call [updateData] when series changes
/// 5. **Cleanup**: Call [dispose] to release resources
abstract class ChartLayer extends RenderLayer {
  /// The data series to be rendered.
  ///
  /// Each series contains a list of data points with optional metadata.
  /// Empty list means no data to render ([isEmpty] should return true).
  final List<ChartSeries> series;

  /// The theme to apply for styling.
  ///
  /// Contains colors, line widths, fonts, and other visual properties.
  /// Implementations should use theme values instead of hardcoded styles.
  final ChartTheme theme;

  /// The animation configuration for data updates.
  ///
  /// Controls whether animations are enabled, their duration, and easing curves.
  /// When [updateData] is called, this config determines animation behavior.
  final ChartAnimationConfig animationConfig;

  /// Constructs a chart layer with required data and styling.
  ///
  /// [series] is the data to render (can be empty list).
  /// [theme] defines the visual styling.
  /// [animationConfig] controls data update animations.
  /// [zIndex] determines rendering order (inherited from RenderLayer).
  /// [isVisible] determines if layer renders (inherited from RenderLayer).
  ChartLayer({
    required this.series,
    required this.theme,
    required this.animationConfig,
    required super.zIndex,
    super.isVisible,
  });

  /// Renders the chart to the canvas.
  ///
  /// Implementations MUST:
  /// - Short-circuit if [isEmpty] is true
  /// - Acquire pooled objects from [context] (Paint, Path, TextPainter)
  /// - Release pooled objects in finally blocks
  /// - Use [context.culler] for viewport culling
  /// - Apply [theme] styling to all rendered elements
  ///
  /// Performance Requirements:
  /// - Line/Area: <16ms for 10,000 points
  /// - Bar: <16ms for 1,000 bars
  /// - Scatter: <16ms for 10,000 points
  ///
  /// [context] provides canvas, viewport, pools, and rendering resources.
  @override
  void render(RenderContext context);

  /// Update the data series with optional animation.
  ///
  /// If [animationConfig.enabled] is true (when animation system is implemented),
  /// the transition from old [series] to [newSeries] will be animated.
  /// Otherwise, [newSeries] is immediately assigned.
  ///
  /// Implementations should:
  /// 1. Calculate diff between old and new data
  /// 2. If animating: setup animation controller with interpolated values
  /// 3. If not animating: directly replace series
  ///
  /// This is a no-op in the base class. Subclasses MUST override if
  /// they support data updates.
  ///
  /// [newSeries] is the new data to display.
  void updateData(List<ChartSeries> newSeries) {
    // Default: no-op
    // Subclasses that support dynamic data updates must override
  }

  /// Prepare resources needed for rendering.
  ///
  /// Called once before rendering begins. Use this to:
  /// - Acquire objects from context pools (if needed for entire frame)
  /// - Cache transformed coordinates
  /// - Pre-compute bezier curves for smooth lines
  /// - Create gradient shaders for area fills
  ///
  /// Implementations that don't need preparation can leave this empty.
  ///
  /// [context] provides access to pools and rendering resources.
  void prepare(RenderContext context) {
    // Default: no-op
    // Subclasses can override to perform setup
  }

  /// Release resources after rendering.
  ///
  /// Called after rendering completes (or when layer is removed from pipeline).
  /// Use this to:
  /// - Return pooled objects acquired in [prepare]
  /// - Clear caches if needed
  /// - Stop animations
  ///
  /// Implementations that don't acquire resources can leave this empty.
  void dispose() {
    // Default: no-op
    // Subclasses can override to perform cleanup
  }

  /// Check if layer has no visible elements.
  ///
  /// Returns true when:
  /// - [series] is empty (no data)
  /// - All series in [series] are empty (no points)
  /// - All data points are outside viewport (after culling)
  ///
  /// Pipeline uses this to skip [render] call entirely, saving time.
  ///
  /// Default implementation checks if series list is empty.
  /// Subclasses SHOULD override for more accurate emptiness detection.
  @override
  bool get isEmpty => series.isEmpty;

  @override
  String toString() =>
      'ChartLayer(series: ${series.length}, zIndex: $zIndex, isVisible: $isVisible)';
}
