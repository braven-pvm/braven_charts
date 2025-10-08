/// Interaction callback type definitions and safe invocation helpers.
///
/// Provides callback signatures for all interaction events and utilities
/// for safely invoking callbacks with error handling.
library;

import 'dart:ui' show Offset;

import '../foundation/data_models/chart_data_point.dart';

// ==============================================================================
// Callback Type Definitions (FR-007)
// ==============================================================================

/// Called when a user taps/clicks on a data point.
///
/// Parameters:
/// - [point]: The data point that was tapped
/// - [position]: Screen coordinates of the tap event
///
/// Example:
/// ```dart
/// InteractionConfig(
///   onDataPointTap: (point, position) {
///     print('Tapped point at ${point['x']}, ${point['y']}');
///   },
/// )
/// ```
typedef DataPointCallback = void Function(ChartDataPoint point, Offset position);

/// Called when the cursor hovers over a data point.
///
/// Parameters:
/// - [point]: The data point being hovered over (null when hover exits)
/// - [position]: Screen coordinates of the hover event
///
/// This callback may be invoked frequently during mouse movement.
/// Keep logic lightweight to avoid performance issues.
typedef DataPointHoverCallback = void Function(ChartDataPoint? point, Offset position);

/// Called when a user performs a long-press gesture on a data point.
///
/// Parameters:
/// - [point]: The data point that was long-pressed
/// - [position]: Screen coordinates of the long-press event
///
/// Typically used on mobile devices for context menus or additional actions.
typedef DataPointLongPressCallback = void Function(ChartDataPoint point, Offset position);

/// Called when the selected data points change.
///
/// Parameters:
/// - [selectedPoints]: List of currently selected data points (empty if none selected)
///
/// Selection can change through:
/// - User tapping/clicking points (with shift/ctrl modifiers)
/// - Keyboard navigation
/// - Programmatic selection changes
typedef SelectionCallback = void Function(List<ChartDataPoint> selectedPoints);

/// Called when the zoom level changes.
///
/// Parameters:
/// - [zoomLevelX]: Zoom factor for X-axis (1.0 = no zoom, >1.0 = zoomed in)
/// - [zoomLevelY]: Zoom factor for Y-axis (1.0 = no zoom, >1.0 = zoomed in)
///
/// Triggered by:
/// - Pinch-to-zoom gestures
/// - Mouse wheel zoom
/// - Keyboard zoom (+/- keys)
/// - Programmatic zoom changes
typedef ZoomCallback = void Function(double zoomLevelX, double zoomLevelY);

/// Called when the pan offset changes (viewport scrolling).
///
/// Parameters:
/// - [panOffset]: Current pan offset from original view (0,0 = no pan)
///
/// Triggered by:
/// - Drag gestures
/// - Arrow key navigation
/// - Programmatic pan changes
typedef PanCallback = void Function(Offset panOffset);

/// Called when the visible data range changes due to zoom or pan.
///
/// Parameters:
/// - [visibleBounds]: The current visible data range (minX, minY, maxX, maxY)
///
/// This is a higher-level callback that combines zoom and pan changes.
/// Useful for updating axis labels, loading data on-demand, etc.
typedef ViewportCallback = void Function(Map<String, double> visibleBounds);

/// Called when the crosshair position or snap points change.
///
/// Parameters:
/// - [position]: Current crosshair position in screen coordinates (null if hidden)
/// - [snapPoints]: List of data points near the crosshair (empty if no snapping)
///
/// Triggered when the cursor moves over the chart.
typedef CrosshairChangeCallback = void Function(
  Offset? position,
  List<ChartDataPoint> snapPoints,
);

/// Called when a tooltip is shown or hidden.
///
/// Parameters:
/// - [visible]: Whether the tooltip is currently visible
/// - [dataPoint]: The data point the tooltip is showing (null if hidden)
///
/// Useful for coordinating external UI with tooltip state.
typedef TooltipChangeCallback = void Function(bool visible, ChartDataPoint? dataPoint);

/// Called when a keyboard action is performed.
///
/// Parameters:
/// - [action]: The keyboard action (e.g., "zoom_in", "pan_left", "select_next")
/// - [targetPoint]: The data point targeted by the action (null for global actions)
///
/// Useful for logging keyboard interactions or custom keyboard handlers.
typedef KeyboardActionCallback = void Function(String action, ChartDataPoint? targetPoint);

// ==============================================================================
// Callback Invoker Helper Class
// ==============================================================================

/// Utility class for safely invoking callbacks with error handling.
///
/// Prevents callback exceptions from crashing the interaction system.
/// All callback errors are caught and logged (in debug mode) or silently
/// ignored (in release mode) to ensure robust interaction handling.
///
/// Thread-safe: Can be used from any isolate/thread.
class CallbackInvoker {
  /// Invokes a nullable callback with error handling.
  ///
  /// If [callback] is null, does nothing.
  /// If [callback] throws an exception, catches it and logs in debug mode.
  ///
  /// Example:
  /// ```dart
  /// CallbackInvoker.invoke(
  ///   config.onDataPointTap,
  ///   () => [point, position],
  /// );
  /// ```
  static void invoke<T>(
    T? callback,
    List<dynamic> Function() getArgs,
  ) {
    if (callback == null) return;

    try {
      // Use Function.apply for dynamic argument passing
      Function.apply(callback as Function, getArgs());
    } catch (e, stackTrace) {
      // In debug mode, print error details
      assert(() {
        print('Callback invocation error: $e');
        print('Stack trace: $stackTrace');
        return true;
      }());
      // In release mode, silently ignore callback errors
      // This prevents user callback bugs from crashing the chart
    }
  }

  /// Invokes a data point callback (tap, hover, long-press).
  ///
  /// Convenience wrapper for [invoke] with type-safe parameters.
  static void invokeDataPoint(
    DataPointCallback? callback,
    ChartDataPoint point,
    Offset position,
  ) {
    invoke(callback, () => [point, position]);
  }

  /// Invokes a data point hover callback.
  ///
  /// Handles nullable point parameter for hover exit events.
  static void invokeDataPointHover(
    DataPointHoverCallback? callback,
    ChartDataPoint? point,
    Offset position,
  ) {
    invoke(callback, () => [point, position]);
  }

  /// Invokes a data point long-press callback.
  static void invokeDataPointLongPress(
    DataPointLongPressCallback? callback,
    ChartDataPoint point,
    Offset position,
  ) {
    invoke(callback, () => [point, position]);
  }

  /// Invokes a selection changed callback.
  static void invokeSelection(
    SelectionCallback? callback,
    List<ChartDataPoint> selectedPoints,
  ) {
    invoke(callback, () => [selectedPoints]);
  }

  /// Invokes a zoom changed callback.
  static void invokeZoom(
    ZoomCallback? callback,
    double zoomLevelX,
    double zoomLevelY,
  ) {
    invoke(callback, () => [zoomLevelX, zoomLevelY]);
  }

  /// Invokes a pan changed callback.
  static void invokePan(
    PanCallback? callback,
    Offset panOffset,
  ) {
    invoke(callback, () => [panOffset]);
  }

  /// Invokes a viewport changed callback.
  static void invokeViewport(
    ViewportCallback? callback,
    Map<String, double> visibleBounds,
  ) {
    invoke(callback, () => [visibleBounds]);
  }

  /// Invokes a crosshair changed callback.
  static void invokeCrosshair(
    CrosshairChangeCallback? callback,
    Offset? position,
    List<ChartDataPoint> snapPoints,
  ) {
    invoke(callback, () => [position, snapPoints]);
  }

  /// Invokes a tooltip changed callback.
  static void invokeTooltip(
    TooltipChangeCallback? callback,
    bool visible,
    ChartDataPoint? dataPoint,
  ) {
    invoke(callback, () => [visible, dataPoint]);
  }

  /// Invokes a keyboard action callback.
  static void invokeKeyboard(
    KeyboardActionCallback? callback,
    String action,
    ChartDataPoint? targetPoint,
  ) {
    invoke(callback, () => [action, targetPoint]);
  }

  /// Invokes an async callback safely.
  ///
  /// Unlike the synchronous [invoke], this method awaits the callback
  /// completion but still catches and logs any errors.
  ///
  /// Returns a Future that completes when the callback finishes or errors.
  static Future<void> invokeAsync<T>(
    T? callback,
    List<dynamic> Function() getArgs,
  ) async {
    if (callback == null) return;

    try {
      final result = Function.apply(callback as Function, getArgs());
      // If the callback returns a Future, await it
      if (result is Future) {
        await result;
      }
    } catch (e, stackTrace) {
      // In debug mode, print error details
      assert(() {
        print('Async callback invocation error: $e');
        print('Stack trace: $stackTrace');
        return true;
      }());
      // In release mode, silently ignore callback errors
    }
  }
}
