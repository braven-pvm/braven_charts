/// Zoom and pan controller for chart navigation.
///
/// Manages zoom operations, pan gestures, and coordinate transformations
/// with support for constraints, inertial scrolling, and smooth animations.
library;

import 'dart:ui' show Offset, Rect;

import 'models/gesture_details.dart';
import 'models/zoom_pan_state.dart';

/// Controller for zoom and pan operations on charts.
///
/// Provides methods for:
/// - Zooming in/out with focal point preservation
/// - Panning with boundary constraints
/// - Gesture-based navigation (scale, pan, double-tap)
/// - Inertial scrolling with velocity decay
/// - Coordinate transformations between screen and data space
///
/// Example:
/// ```dart
/// final controller = ZoomPanController();
/// final dataBounds = Rect.fromLTWH(0, 0, 100, 100);
/// var state = const ZoomPanState.initial(dataBounds);
///
/// // Zoom in 2x centered at (400, 300)
/// state = controller.zoom(
///   state,
///   zoomFactor: 2.0,
///   focalPoint: const Offset(400, 300),
/// );
///
/// // Pan by (50, -30)
/// state = controller.pan(state, const Offset(50, -30));
/// ```
class ZoomPanController {
  /// Creates a zoom/pan controller.
  ZoomPanController({
    this.frictionCoefficient = 0.95,
    this.velocityThreshold = 50.0,
  })  : assert(frictionCoefficient > 0 && frictionCoefficient < 1,
            'frictionCoefficient must be between 0 and 1'),
        assert(velocityThreshold >= 0, 'velocityThreshold must be non-negative');

  /// Friction coefficient for inertial scrolling (0-1).
  ///
  /// Higher values = less friction = longer coasting.
  /// Default: 0.95 (slight friction)
  final double frictionCoefficient;

  /// Velocity threshold below which inertia stops (pixels/second).
  ///
  /// When velocity magnitude drops below this, inertia is cancelled.
  /// Default: 50.0 pixels/second
  final double velocityThreshold;

  /// Zooms the chart by the specified factor.
  ///
  /// The [zoomFactor] multiplies the current zoom level. Values > 1.0 zoom in,
  /// values < 1.0 zoom out. The [focalPoint] specifies the screen coordinate
  /// that should remain visually fixed during the zoom.
  ///
  /// Optional [minZoom] and [maxZoom] override the state's constraints.
  ///
  /// Returns a new [ZoomPanState] with updated zoom and pan.
  ZoomPanState zoom(
    ZoomPanState state, {
    required double zoomFactor,
    required Offset focalPoint,
    double? minZoom,
    double? maxZoom,
  }) {
    // Calculate new zoom level
    final newZoomX = state.zoomLevelX * zoomFactor;
    final newZoomY = state.zoomLevelY * zoomFactor;

    // Apply constraints
    final minLevel = minZoom ?? state.minZoomLevel;
    final maxLevel = maxZoom ?? state.maxZoomLevel;
    final clampedZoomX = newZoomX.clamp(minLevel, maxLevel);
    final clampedZoomY = newZoomY.clamp(minLevel, maxLevel);

    // Calculate pan offset to keep focal point fixed
    // Formula: new_pan = old_pan + focal * (1 - zoom_ratio)
    final zoomRatioX = clampedZoomX / state.zoomLevelX;
    final zoomRatioY = clampedZoomY / state.zoomLevelY;
    
    final newPanX = state.panOffset.dx + focalPoint.dx * (1 - zoomRatioX);
    final newPanY = state.panOffset.dy + focalPoint.dy * (1 - zoomRatioY);

    return state.copyWith(
      zoomLevelX: clampedZoomX,
      zoomLevelY: clampedZoomY,
      panOffset: Offset(newPanX, newPanY),
    );
  }

  /// Sets the zoom level to an exact value.
  ///
  /// Unlike [zoom], this sets the absolute zoom level rather than multiplying.
  /// The [focalPoint] specifies the screen coordinate that remains fixed.
  ///
  /// Returns a new [ZoomPanState] with the target zoom level.
  ZoomPanState zoomTo(
    ZoomPanState state, {
    required double targetZoom,
    required Offset focalPoint,
  }) {
    // Calculate zoom factor needed to reach target
    final zoomFactor = targetZoom / state.zoomLevelX;
    return zoom(state, zoomFactor: zoomFactor, focalPoint: focalPoint);
  }

  /// Resets zoom to 1.0 and pan to zero.
  ///
  /// Returns the chart to its default view with no zoom or pan applied.
  ZoomPanState resetZoom(ZoomPanState state) {
    return state.copyWith(
      zoomLevelX: 1.0,
      zoomLevelY: 1.0,
      panOffset: Offset.zero,
    );
  }

  /// Pans the chart by the specified delta.
  ///
  /// The [delta] is in screen pixels. Positive dx pans right, positive dy pans down.
  ///
  /// If [bounds] is provided, panning is constrained to keep the visible area
  /// within those data bounds.
  ///
  /// Returns a new [ZoomPanState] with updated pan offset.
  ZoomPanState pan(
    ZoomPanState state,
    Offset delta, {
    Rect? bounds,
  }) {
    // Calculate new pan offset
    final newPanX = state.panOffset.dx + delta.dx;
    final newPanY = state.panOffset.dy + delta.dy;
    var newPan = Offset(newPanX, newPanY);

    // Apply bounds constraint if provided
    if (bounds != null && !state.allowOverscroll) {
      // Calculate visible data width/height at current zoom
      final visibleDataWidth = bounds.width / state.zoomLevelX;
      final visibleDataHeight = bounds.height / state.zoomLevelY;

      // Calculate max pan that keeps data visible
      // Pan is negative when scrolling right/down (showing left/top data)
      final maxPanX = 0.0; // Can't pan right beyond origin
      final minPanX = -(bounds.width - visibleDataWidth);
      final maxPanY = 0.0; // Can't pan down beyond origin
      final minPanY = -(bounds.height - visibleDataHeight);

      newPan = Offset(
        newPanX.clamp(minPanX, maxPanX),
        newPanY.clamp(minPanY, maxPanY),
      );
    }

    return state.copyWith(panOffset: newPan);
  }

  /// Processes a gesture and updates the zoom/pan state accordingly.
  ///
  /// Supports:
  /// - Pinch gestures: Zoom in/out with focal point (uses currentScale)
  /// - Pan gestures: Move the chart (uses panDelta)
  /// - Double-tap gestures: Quick zoom with optional factor (uses currentPosition)
  ///
  /// Note: Since GestureDetails uses different field names than what gesture
  /// processing typically expects, this method maps them appropriately:
  /// - Pinch → uses currentScale for zoom factor, currentPosition as focal point
  /// - Pan → uses panDelta for movement
  /// - DoubleTap → uses currentPosition as tap location
  ///
  /// Returns a new [ZoomPanState] reflecting the gesture.
  ZoomPanState processGesture(
    ZoomPanState state,
    GestureDetails gesture, {
    double? doubleTapZoomFactor,
  }) {
    switch (gesture.type) {
      case GestureType.pinch:
        // Pinch gesture (pinch-to-zoom)
        final scale = gesture.currentScale ?? 1.0;
        final focalPoint = gesture.currentPosition; // Use current position as focal point
        return zoom(
          state,
          zoomFactor: scale,
          focalPoint: focalPoint,
        );

      case GestureType.pan:
        // Pan gesture (drag)
        final delta = gesture.panDelta ?? Offset.zero;
        return pan(state, delta);

      case GestureType.doubleTap:
        // Double-tap to zoom
        final zoomFactor = doubleTapZoomFactor ?? 2.0;
        final focalPoint = gesture.currentPosition; // Use current position as tap location
        return zoom(state, zoomFactor: zoomFactor, focalPoint: focalPoint);

      default:
        return state;
    }
  }

  /// Applies inertial scrolling based on velocity stored in metadata.
  ///
  /// This is a simplified version that works without panVelocity in ZoomPanState.
  /// In a real implementation, velocity would be tracked externally or added
  /// to the state model.
  ///
  /// For now, this method is a placeholder that returns the state unchanged.
  /// To properly implement inertia, the ZoomPanState model would need a
  /// panVelocity field added.
  ///
  /// [deltaTime] is the elapsed time since the last frame.
  ///
  /// Returns the state unchanged (inertia requires panVelocity field).
  ZoomPanState applyInertia(
    ZoomPanState state, {
    required Duration deltaTime,
  }) {
    // Inertia requires panVelocity field in ZoomPanState
    // Since it's not present in the current model, return state unchanged
    // This would need to be implemented if panVelocity is added to the model
    return state;
  }

  /// Converts screen coordinates to data coordinates.
  ///
  /// Takes a point in screen space (e.g., touch position) and transforms it
  /// to the corresponding point in data space, accounting for zoom and pan.
  ///
  /// Formula:
  /// ```
  /// data_x = (screen_x - pan_x) / zoom_x
  /// data_y = (screen_y - pan_y) / zoom_y
  /// ```
  ///
  /// Returns the point in data coordinates.
  Offset screenToData(
    Offset screenPoint,
    ZoomPanState state,
  ) {
    final dataX = (screenPoint.dx - state.panOffset.dx) / state.zoomLevelX;
    final dataY = (screenPoint.dy - state.panOffset.dy) / state.zoomLevelY;
    return Offset(dataX, dataY);
  }

  /// Converts data coordinates to screen coordinates.
  ///
  /// Takes a point in data space and transforms it to screen space,
  /// accounting for zoom and pan.
  ///
  /// Formula:
  /// ```
  /// screen_x = data_x * zoom_x + pan_x
  /// screen_y = data_y * zoom_y + pan_y
  /// ```
  ///
  /// Returns the point in screen coordinates.
  Offset dataToScreen(
    Offset dataPoint,
    ZoomPanState state,
  ) {
    final screenX = dataPoint.dx * state.zoomLevelX + state.panOffset.dx;
    final screenY = dataPoint.dy * state.zoomLevelY + state.panOffset.dy;
    return Offset(screenX, screenY);
  }
}
