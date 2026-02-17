// Contract Interface: Crosshair Renderer
// Feature: Layer 7 Interaction System
// Requirement: FR-002 (Crosshair System)

/// Interface for rendering precision targeting crosshair that follows
/// cursor/tap position and snaps to nearest data points.
///
/// Responsibilities:
/// - Render vertical/horizontal guide lines at cursor position
/// - Snap crosshair to nearest data point within configurable radius
/// - Display coordinate labels at crosshair intersection
/// - Highlight nearest point on all series (multi-series support)
/// - Update at 60 FPS during cursor movement (<16ms per frame)
///
/// Performance Requirements:
/// - Render time: <2ms per frame (measured across 1000 frames)
/// - Snap-to-point calculation: <1ms for 10,000 visible points
abstract class ICrosshairRenderer {
  /// Renders crosshair on the provided canvas.
  ///
  /// Parameters:
  /// - [canvas]: Flutter canvas for drawing
  /// - [size]: Size of the chart area
  /// - [state]: Current interaction state (crosshair position, snap points)
  /// - [config]: Crosshair configuration (style, mode, snap settings)
  ///
  /// Performance: Must complete in <2ms
  void render(
    Canvas canvas,
    Size size,
    InteractionState state,
    CrosshairConfig config,
  );

  /// Calculates snap points (nearest data points) for crosshair position.
  ///
  /// Uses spatial indexing (quadtree) for O(log n) performance.
  ///
  /// Parameters:
  /// - [position]: Crosshair position in data coordinates
  /// - [visiblePoints]: List of visible data points (after viewport culling)
  /// - [snapRadius]: Maximum distance in pixels to snap
  ///
  /// Returns: List of snap points (one per series at nearest X coordinate)
  ///
  /// Performance: Must complete in <1ms for 10,000 points
  List<ChartDataPoint> calculateSnapPoints(
    Offset position,
    List<ChartDataPoint> visiblePoints,
    double snapRadius,
  );

  /// Renders crosshair lines (vertical and/or horizontal).
  ///
  /// Parameters:
  /// - [canvas]: Flutter canvas
  /// - [size]: Chart area size
  /// - [position]: Crosshair position in screen coordinates
  /// - [style]: Crosshair visual style
  /// - [mode]: Which lines to render (vertical/horizontal/both)
  void renderCrosshairLines(
    Canvas canvas,
    Size size,
    Offset position,
    CrosshairStyle style,
    CrosshairMode mode,
  );

  /// Renders coordinate labels at crosshair intersection.
  ///
  /// Parameters:
  /// - [canvas]: Flutter canvas
  /// - [position]: Crosshair position in screen coordinates
  /// - [dataPosition]: Crosshair position in data coordinates
  /// - [textStyle]: Text style for labels
  void renderCoordinateLabels(
    Canvas canvas,
    Offset position,
    Offset dataPosition,
    TextStyle textStyle,
  );

  /// Highlights snap points (nearest data points) on all series.
  ///
  /// Typically renders a circle or highlight around the snapped point.
  ///
  /// Parameters:
  /// - [canvas]: Flutter canvas
  /// - [snapPoints]: List of points to highlight
  /// - [coordinateTransformer]: For converting data → screen coordinates
  /// - [highlightStyle]: Style for highlight indicator
  void renderSnapPointHighlights(
    Canvas canvas,
    List<ChartDataPoint> snapPoints,
    CoordinateTransformer coordinateTransformer,
    HighlightStyle highlightStyle,
  );

  /// Determines if crosshair should repaint.
  ///
  /// Used by CustomPainter.shouldRepaint() for optimization.
  ///
  /// Parameters:
  /// - [oldState]: Previous interaction state
  /// - [newState]: New interaction state
  ///
  /// Returns: true if crosshair position or visibility changed
  bool shouldRepaint(InteractionState oldState, InteractionState newState);
}

/// Visual style for crosshair lines.
class CrosshairStyle {
  CrosshairStyle({
    required this.lineColor,
    required this.lineWidth,
    this.dashPattern,
    this.strokeCap = StrokeCap.round,
  });
  final Color lineColor;
  final double lineWidth;
  final List<double>? dashPattern;
  final StrokeCap strokeCap;
}

/// Crosshair rendering mode.
enum CrosshairMode {
  none, // No crosshair
  vertical, // Vertical line only
  horizontal, // Horizontal line only
  both, // Both lines
}

/// Visual style for snap point highlights.
class HighlightStyle {
  HighlightStyle({
    required this.color,
    this.radius = 5.0,
    this.strokeWidth = 2.0,
    this.filled = false,
  });
  final Color color;
  final double radius;
  final double strokeWidth;
  final bool filled;
}
