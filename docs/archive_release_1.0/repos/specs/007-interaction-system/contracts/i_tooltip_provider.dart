// Contract Interface: Tooltip Provider
// Feature: Layer 7 Interaction System
// Requirement: FR-003 (Tooltip System)

/// Interface for rendering context-aware tooltips that display data point
/// details on hover or tap.
///
/// Responsibilities:
/// - Display tooltip on hover (desktop) or tap (mobile)
/// - Show data point details (series name, X value, Y value)
/// - Position automatically to avoid clipping (smart positioning)
/// - Support custom content via developer-provided builder function
/// - Animate smoothly with configurable fade-in/fade-out
/// - Display data for multiple series when hovering at same X coordinate
///
/// Performance Requirements:
/// - Render time: <5ms including layout calculation
/// - Tooltip appears within configurable delay (default 300ms)
/// - Fade animations maintain 60 FPS
abstract class ITooltipProvider {
  /// Shows tooltip for a data point.
  ///
  /// Parameters:
  /// - [context]: BuildContext for widget tree
  /// - [point]: Data point to show tooltip for
  /// - [seriesId]: ID of the series containing the point
  /// - [screenPosition]: Position in screen coordinates
  /// - [config]: Tooltip configuration (style, builder, positioning)
  ///
  /// Returns: Tooltip widget to be rendered
  ///
  /// Performance: Must complete in <5ms
  Widget showTooltip(
    BuildContext context,
    ChartDataPoint point,
    String seriesId,
    Offset screenPosition,
    TooltipConfig config,
  );

  /// Hides the currently visible tooltip.
  ///
  /// Applies fade-out animation if configured.
  void hideTooltip();

  /// Calculates optimal tooltip position to avoid clipping.
  ///
  /// Smart positioning algorithm:
  /// 1. Try preferred position (top/bottom/left/right)
  /// 2. If clipped, try opposite side
  /// 3. If still clipped, try other two sides
  /// 4. If all clipped, position at edge with arrow pointing to point
  ///
  /// Parameters:
  /// - [tooltipSize]: Size of tooltip widget
  /// - [pointPosition]: Position of data point in screen coordinates
  /// - [chartBounds]: Visible bounds of chart area
  /// - [preferredPosition]: Developer's preferred position
  /// - [offset]: Distance from point in pixels
  ///
  /// Returns: Optimal position for tooltip
  Offset calculatePosition(
    Size tooltipSize,
    Offset pointPosition,
    Rect chartBounds,
    TooltipPosition preferredPosition,
    double offset,
  );

  /// Renders default tooltip content (series name, X/Y values).
  ///
  /// Used when no custom builder is provided.
  ///
  /// Parameters:
  /// - [context]: BuildContext
  /// - [point]: Data point
  /// - [seriesId]: Series ID
  /// - [style]: Tooltip style configuration
  ///
  /// Returns: Default tooltip widget
  Widget buildDefaultTooltip(
    BuildContext context,
    ChartDataPoint point,
    String seriesId,
    TooltipStyle style,
  );

  /// Renders tooltip for multiple series at same X coordinate.
  ///
  /// Shows all series values stacked vertically in tooltip.
  ///
  /// Parameters:
  /// - [context]: BuildContext
  /// - [points]: List of data points (one per series)
  /// - [seriesIds]: List of series IDs corresponding to points
  /// - [style]: Tooltip style configuration
  ///
  /// Returns: Multi-series tooltip widget
  Widget buildMultiSeriesTooltip(
    BuildContext context,
    List<ChartDataPoint> points,
    List<String> seriesIds,
    TooltipStyle style,
  );

  /// Determines if tooltip should update.
  ///
  /// Used to avoid unnecessary rebuilds.
  ///
  /// Parameters:
  /// - [oldPoint]: Previously displayed data point
  /// - [newPoint]: New data point to display
  ///
  /// Returns: true if tooltip content changed
  bool shouldUpdate(ChartDataPoint? oldPoint, ChartDataPoint? newPoint);
}

/// Configuration for tooltip behavior and appearance.
class TooltipConfig {
  TooltipConfig({
    required this.enabled,
    required this.triggerMode,
    required this.showDelay,
    required this.hideDelay,
    required this.preferredPosition,
    required this.offsetFromPoint,
    required this.style,
    this.customBuilder,
  });
  final bool enabled;
  final TooltipTriggerMode triggerMode;
  final Duration showDelay;
  final Duration hideDelay;
  final TooltipPosition preferredPosition;
  final double offsetFromPoint;
  final TooltipStyle style;
  final Widget Function(BuildContext, ChartDataPoint, String)? customBuilder;
}

/// Visual style for tooltip.
class TooltipStyle {
  TooltipStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.padding,
    required this.textStyle,
    this.shadow,
  });
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsets padding;
  final TextStyle textStyle;
  final BoxShadow? shadow;
}

/// Tooltip trigger mode.
enum TooltipTriggerMode {
  hover, // Desktop: mouse hover
  tap, // Mobile: tap to show
  both, // Both hover and tap
}

/// Tooltip position preference.
enum TooltipPosition {
  auto, // Smart positioning (avoid clipping)
  top,
  bottom,
  left,
  right,
}
