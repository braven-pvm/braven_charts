// Contract Interface: Event Handler
// Feature: Layer 7 Interaction System
// Requirement: FR-001 (Event Handling System)

/// Interface for unified event processing that translates platform-specific
/// inputs (mouse, touch, keyboard) into chart coordinate space.
///
/// Responsibilities:
/// - Capture PointerEvents (mouse/touch) from Flutter's event system
/// - Capture RawKeyEvents when chart has focus
/// - Translate screen coordinates to chart data coordinates
/// - Route events to appropriate interaction handlers by priority
/// - Process all events within <5ms overhead
///
/// Performance Requirements:
/// - Event processing: <5ms per event (99th percentile)
/// - Zero memory growth after 10,000 event cycles
abstract class IEventHandler {
  /// Processes a pointer event (mouse move, mouse down, touch, etc.)
  /// and returns a normalized chart event with data coordinates.
  ///
  /// Parameters:
  /// - [event]: Raw pointer event from Flutter
  /// - [coordinateTransformer]: Converts screen ↔ data coordinates
  ///
  /// Returns: ChartEvent with data coordinates, or null if event ignored
  ///
  /// Performance: Must complete in <5ms
  ChartEvent? processPointerEvent(
    PointerEvent event,
    CoordinateTransformer coordinateTransformer,
  );

  /// Processes a keyboard event when chart has focus.
  ///
  /// Parameters:
  /// - [event]: Raw keyboard event from Flutter
  ///
  /// Returns: KeyEventResult.handled if processed, .ignored otherwise
  ///
  /// Performance: Must complete in <50ms (keyboard response time)
  KeyEventResult processKeyEvent(RawKeyEvent event);

  /// Routes a chart event to registered handlers based on priority.
  ///
  /// Priority order:
  /// 1. Gesture recognizers (pan/pinch/zoom)
  /// 2. Crosshair renderer
  /// 3. Tooltip provider
  /// 4. Callback delegates
  ///
  /// Parameters:
  /// - [event]: Chart event with data coordinates
  ///
  /// Returns: true if event was handled, false if propagated
  bool routeEvent(ChartEvent event);

  /// Registers an interaction handler with specified priority.
  ///
  /// Higher priority handlers receive events first.
  ///
  /// Parameters:
  /// - [handler]: Handler function
  /// - [priority]: Priority level (higher = earlier processing)
  void registerHandler(
    bool Function(ChartEvent) handler,
    int priority,
  );

  /// Unregisters a previously registered handler.
  void unregisterHandler(bool Function(ChartEvent) handler);

  /// Disposes resources (event listeners, pools).
  ///
  /// Must be called when chart widget is disposed to prevent memory leaks.
  void dispose();
}

/// Normalized chart event with data coordinates.
///
/// All screen coordinates are translated to chart data space.
class ChartEvent {
  ChartEvent({
    required this.type,
    required this.screenPosition,
    required this.dataPosition,
    this.nearestPoint,
    this.gesture,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Type of event (hover, tap, pan, zoom, key, etc.)
  final ChartEventType type;

  /// Position in screen coordinates
  final Offset screenPosition;

  /// Position in data coordinates (after transformation)
  final Offset dataPosition;

  /// Data point nearest to event position (if within snap radius)
  final ChartDataPoint? nearestPoint;

  /// Gesture details (for pan/pinch/zoom events)
  final GestureDetails? gesture;

  /// Timestamp
  final DateTime timestamp;
}

enum ChartEventType {
  // Mouse events
  mouseEnter,
  mouseMove,
  mouseExit,
  mouseDown,
  mouseUp,
  mouseWheel,

  // Touch events
  tapDown,
  tapUp,
  longPress,
  panStart,
  panUpdate,
  panEnd,
  pinchStart,
  pinchUpdate,
  pinchEnd,

  // Keyboard events
  keyDown,
  keyUp,
}
