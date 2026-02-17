/// Event handling system for chart interactions.
///
/// Unified event processing that translates platform-specific inputs
/// (mouse, touch, keyboard) into chart coordinate space and routes them
/// to registered interaction handlers by priority.
///
/// This module implements the IEventHandler contract with <5ms event
/// processing overhead and zero memory growth after 10,000 events.
library;

import 'dart:ui' show Offset;

import 'package:braven_charts/legacy/src/coordinates/coordinate_transformer.dart';
import 'package:braven_charts/legacy/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/legacy/src/interaction/models/gesture_details.dart';
import 'package:flutter/gestures.dart'
    show
        PointerEvent,
        PointerMoveEvent,
        PointerDownEvent,
        PointerUpEvent,
        PointerHoverEvent;
import 'package:flutter/services.dart' show KeyEvent;

/// Result of processing a keyboard event.
///
/// Indicates whether the event was handled or should be passed to other handlers.
enum KeyEventResult {
  /// The event was handled and should not be passed to other handlers.
  handled,

  /// The event was not handled and should be passed to other handlers.
  ignored,
}

/// Interface for unified event processing that translates platform-specific
/// inputs (mouse, touch, keyboard) into chart coordinate space.
///
/// Responsibilities:
/// - Capture PointerEvents (mouse/touch) from Flutter's event system
/// - Capture KeyEvents when chart has focus
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
  KeyEventResult processKeyEvent(KeyEvent event);

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
  void registerHandler(bool Function(ChartEvent) handler, int priority);

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
  /// Creates a chart event with the specified properties.
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

/// Types of chart events.
enum ChartEventType {
  // Mouse events
  /// Mouse enters the chart area
  mouseEnter,

  /// Mouse moves within the chart area
  mouseMove,

  /// Mouse exits the chart area
  mouseExit,

  /// Mouse button pressed
  mouseDown,

  /// Mouse button released
  mouseUp,

  /// Mouse wheel scrolled
  mouseWheel,

  // Touch events
  /// Touch down
  tapDown,

  /// Touch up
  tapUp,

  /// Long press
  longPress,

  /// Pan gesture started
  panStart,

  /// Pan gesture updated
  panUpdate,

  /// Pan gesture ended
  panEnd,

  /// Pinch gesture started
  pinchStart,

  /// Pinch gesture updated
  pinchUpdate,

  /// Pinch gesture ended
  pinchEnd,

  // Keyboard events
  /// Key down
  keyDown,

  /// Key up
  keyUp,
}

/// Handler entry with priority for event routing.
class _HandlerEntry {
  _HandlerEntry(this.handler, this.priority);

  final bool Function(ChartEvent) handler;
  final int priority;
}

/// Implementation of the event handling system.
///
/// Processes pointer and keyboard events, translates coordinates,
/// and routes events to registered handlers based on priority.
///
/// Example:
/// ```dart
/// final eventHandler = EventHandler();
///
/// // Register a handler
/// eventHandler.registerHandler(
///   (event) {
///     print('Event at: ${event.dataPosition}');
///     return true; // Event handled
///   },
///   priority: 10,
/// );
///
/// // Process an event
/// final chartEvent = eventHandler.processPointerEvent(
///   pointerEvent,
///   coordinateTransformer,
/// );
///
/// // Route the event
/// eventHandler.routeEvent(chartEvent);
///
/// // Clean up
/// eventHandler.dispose();
/// ```
class EventHandler implements IEventHandler {
  /// Creates an event handler instance.
  EventHandler() : _handlers = [];

  /// List of registered handlers sorted by priority (highest first).
  final List<_HandlerEntry> _handlers;

  /// Whether the handler has been disposed.
  bool _disposed = false;

  @override
  ChartEvent? processPointerEvent(
    PointerEvent event,
    CoordinateTransformer coordinateTransformer,
  ) {
    if (_disposed) {
      throw StateError('EventHandler has been disposed');
    }

    // Translate screen coordinates to data coordinates
    final screenPosition = event.position;
    final dataPosition = coordinateTransformer.screenToData(screenPosition);

    // Determine event type based on PointerEvent runtime type
    final eventType = _mapPointerEventType(event);

    // Create chart event
    return ChartEvent(
      type: eventType,
      screenPosition: screenPosition,
      dataPosition: dataPosition,
      timestamp: DateTime.now(),
    );
  }

  @override
  KeyEventResult processKeyEvent(KeyEvent event) {
    if (_disposed) {
      throw StateError('EventHandler has been disposed');
    }

    // For now, return ignored - keyboard handling will be implemented
    // when KeyboardHandler component is created
    return KeyEventResult.ignored;
  }

  @override
  bool routeEvent(ChartEvent event) {
    if (_disposed) {
      throw StateError('EventHandler has been disposed');
    }

    // Route event to handlers in priority order (highest to lowest)
    for (final entry in _handlers) {
      final handled = entry.handler(event);
      if (handled) {
        return true; // Stop propagation
      }
    }

    return false; // Event not handled
  }

  @override
  void registerHandler(bool Function(ChartEvent) handler, int priority) {
    if (_disposed) {
      throw StateError('EventHandler has been disposed');
    }

    // Add handler and maintain sorted order (highest priority first)
    _handlers.add(_HandlerEntry(handler, priority));
    _handlers.sort((a, b) => b.priority.compareTo(a.priority));
  }

  @override
  void unregisterHandler(bool Function(ChartEvent) handler) {
    if (_disposed) {
      throw StateError('EventHandler has been disposed');
    }

    // Remove handler by function reference
    _handlers.removeWhere((entry) => entry.handler == handler);
  }

  @override
  void dispose() {
    if (_disposed) return;

    // Clear all handlers
    _handlers.clear();
    _disposed = true;
  }

  /// Maps Flutter PointerEvent types to ChartEventType.
  ChartEventType _mapPointerEventType(PointerEvent event) {
    if (event is PointerMoveEvent) {
      return ChartEventType.mouseMove;
    } else if (event is PointerDownEvent) {
      return ChartEventType.mouseDown;
    } else if (event is PointerUpEvent) {
      return ChartEventType.mouseUp;
    } else if (event is PointerHoverEvent) {
      return ChartEventType.mouseMove;
    }

    // Default to mouseMove for unknown types
    return ChartEventType.mouseMove;
  }
}
