// Contract Interface: Keyboard Handler
// Feature: Layer 7 Interaction System
// Requirement: FR-006 (Keyboard Navigation)

/// Interface for keyboard-only interaction with charts.
///
/// Responsibilities:
/// - Navigate between data points using arrow keys
/// - Pan viewport using arrow keys
/// - Zoom in/out using plus/minus keys
/// - Jump to first/last data point using Home/End
/// - Activate focused element using Enter/Space
/// - Close tooltip/clear selection using Escape
/// - Support custom key bindings
///
/// Accessibility Requirements:
/// - All chart features accessible without mouse/touch
/// - Focus indicator visible with 3:1 contrast ratio (WCAG 2.1 AA)
/// - Screen reader announces focused data point details
/// - Keyboard actions respond within <50ms
abstract class IKeyboardHandler {
  /// Processes a keyboard event when chart has focus.
  ///
  /// Parameters:
  /// - [event]: Raw keyboard event from Flutter
  /// - [state]: Current interaction state (focused point, zoom/pan)
  /// - [points]: List of data points for navigation
  ///
  /// Returns: Updated interaction state, or null if event not handled
  ///
  /// Performance: Must complete in <50ms
  InteractionState? handleKeyEvent(
    RawKeyEvent event,
    InteractionState state,
    List<ChartDataPoint> points,
  );

  /// Navigates to next data point.
  ///
  /// Called when Right Arrow key pressed.
  ///
  /// Parameters:
  /// - [currentPoint]: Currently focused data point
  /// - [points]: List of all data points in series
  ///
  /// Returns: Next data point (wraps to first if at end)
  ChartDataPoint navigateToNext(
    ChartDataPoint? currentPoint,
    List<ChartDataPoint> points,
  );

  /// Navigates to previous data point.
  ///
  /// Called when Left Arrow key pressed.
  ///
  /// Parameters:
  /// - [currentPoint]: Currently focused data point
  /// - [points]: List of all data points in series
  ///
  /// Returns: Previous data point (wraps to last if at start)
  ChartDataPoint navigateToPrevious(
    ChartDataPoint? currentPoint,
    List<ChartDataPoint> points,
  );

  /// Navigates to first data point.
  ///
  /// Called when Home key pressed.
  ///
  /// Parameters:
  /// - [points]: List of all data points in series
  ///
  /// Returns: First data point
  ChartDataPoint navigateToFirst(List<ChartDataPoint> points);

  /// Navigates to last data point.
  ///
  /// Called when End key pressed.
  ///
  /// Parameters:
  /// - [points]: List of all data points in series
  ///
  /// Returns: Last data point
  ChartDataPoint navigateToLast(List<ChartDataPoint> points);

  /// Pans chart viewport using arrow keys.
  ///
  /// Called when arrow keys pressed while chart focused but no point focused.
  ///
  /// Parameters:
  /// - [direction]: Pan direction (up/down/left/right)
  /// - [currentState]: Current zoom/pan state
  /// - [panAmount]: Distance to pan in data space
  ///
  /// Returns: Updated zoom/pan state
  ZoomPanState panViewport(
    PanDirection direction,
    ZoomPanState currentState,
    double panAmount,
  );

  /// Zooms chart using keyboard.
  ///
  /// Called when Plus/Minus keys pressed.
  ///
  /// Parameters:
  /// - [zoomIn]: true for zoom in (+), false for zoom out (-)
  /// - [currentState]: Current zoom/pan state
  /// - [zoomFactor]: Zoom multiplier (default 1.1 for in, 0.9 for out)
  ///
  /// Returns: Updated zoom/pan state
  ZoomPanState zoomViewport(
    bool zoomIn,
    ZoomPanState currentState,
    double zoomFactor,
  );

  /// Activates focused element (shows tooltip).
  ///
  /// Called when Enter or Space pressed.
  ///
  /// Parameters:
  /// - [focusedPoint]: Currently focused data point
  /// - [state]: Current interaction state
  ///
  /// Returns: Updated state with tooltip visible
  InteractionState activateFocusedElement(
    ChartDataPoint focusedPoint,
    InteractionState state,
  );

  /// Closes tooltip or clears selection.
  ///
  /// Called when Escape pressed.
  ///
  /// Parameters:
  /// - [state]: Current interaction state
  ///
  /// Returns: Updated state with tooltip hidden and selection cleared
  InteractionState closeTooltipOrClearSelection(InteractionState state);

  /// Announces focused element to screen reader.
  ///
  /// Uses Flutter's SemanticsService to announce:
  /// "Data point: [Series Name], [X Value], [Y Value]"
  ///
  /// Parameters:
  /// - [point]: Data point to announce
  /// - [seriesName]: Name of the series
  void announceToScreenReader(ChartDataPoint point, String seriesName);

  /// Registers custom key binding.
  ///
  /// Allows developers to add custom keyboard shortcuts.
  ///
  /// Parameters:
  /// - [key]: Logical keyboard key
  /// - [handler]: Callback function when key pressed
  void registerKeyBinding(
    LogicalKeyboardKey key,
    void Function(InteractionState state) handler,
  );

  /// Unregisters custom key binding.
  void unregisterKeyBinding(LogicalKeyboardKey key);
}

/// Pan direction for keyboard navigation.
enum PanDirection { up, down, left, right }

/// Logical keyboard key (from Flutter).
///
/// Examples:
/// - LogicalKeyboardKey.arrowRight
/// - LogicalKeyboardKey.arrowLeft
/// - LogicalKeyboardKey.home
/// - LogicalKeyboardKey.end
/// - LogicalKeyboardKey.enter
/// - LogicalKeyboardKey.space
/// - LogicalKeyboardKey.escape
/// - LogicalKeyboardKey.equal (Plus key)
/// - LogicalKeyboardKey.minus
class LogicalKeyboardKey {
  const LogicalKeyboardKey(this.keyLabel);
  // This is a placeholder - actual implementation from Flutter
  final String keyLabel;
}
