// Copyright (c) 2025 braven_charts. All rights reserved.
// Multi-Axis Zoom Controller with Y-axis constraint for multi-axis mode (FR-013)

import 'dart:ui' show Offset, Rect;

import 'package:braven_charts/src/interaction/models/gesture_details.dart';
import 'package:braven_charts/src/interaction/models/zoom_pan_state.dart';

/// Controller for zoom and pan operations that supports multi-axis mode constraints.
///
/// Extends the functionality of the base ZoomPanController to implement FR-013:
/// **Y-axis zoom/pan must be disabled when multi-axis mode is active.**
///
/// In multi-axis mode:
/// - Each series is normalized to its own Y-axis scale (0-1 normalized space)
/// - Zooming on Y would change which part of normalized space is visible
/// - This would break the visual mapping where each series spans full height
/// - Therefore, Y-axis zoom and pan are constrained to identity (no change)
/// - X-axis zoom and pan remain fully functional for time-based navigation
///
/// ## Usage
///
/// ```dart
/// final controller = MultiAxisZoomController();
/// var state = const ZoomPanState.initial(dataBounds);
///
/// // In multi-axis mode: only X zoom applies
/// state = controller.zoom(
///   state,
///   zoomFactor: 2.0,
///   focalPoint: const Offset(400, 200),
///   isMultiAxisMode: true,
/// );
/// // Result: zoomLevelX = 2.0, zoomLevelY = 1.0 (unchanged)
///
/// // In normal mode: both X and Y zoom apply
/// state = controller.zoom(
///   state,
///   zoomFactor: 2.0,
///   focalPoint: const Offset(400, 200),
///   isMultiAxisMode: false,
/// );
/// // Result: zoomLevelX = 2.0, zoomLevelY = 2.0
/// ```
class MultiAxisZoomController {
  /// Creates a multi-axis zoom controller.
  ///
  /// [frictionCoefficient] controls inertial scrolling decay (0-1).
  /// Higher values = longer coasting. Default: 0.95
  ///
  /// [velocityThreshold] is the minimum velocity to continue inertia.
  /// Default: 50.0 pixels/second
  MultiAxisZoomController({
    this.frictionCoefficient = 0.95,
    this.velocityThreshold = 50.0,
  })  : assert(frictionCoefficient > 0 && frictionCoefficient < 1,
            'frictionCoefficient must be between 0 and 1'),
        assert(
            velocityThreshold >= 0, 'velocityThreshold must be non-negative');

  /// Friction coefficient for inertial scrolling (0-1).
  final double frictionCoefficient;

  /// Velocity threshold below which inertia stops (pixels/second).
  final double velocityThreshold;

  /// Zooms the chart by the specified factor with multi-axis awareness.
  ///
  /// **FR-013 Implementation**: When [isMultiAxisMode] is true, only X-axis
  /// zoom is applied. The Y-axis zoom level remains unchanged.
  ///
  /// Parameters:
  /// - [state]: The current zoom/pan state
  /// - [zoomFactor]: Multiplier for zoom level (>1 = zoom in, <1 = zoom out)
  /// - [focalPoint]: Screen coordinate that remains fixed during zoom
  /// - [isMultiAxisMode]: When true, Y-axis zoom is constrained to current value
  /// - [minZoom], [maxZoom]: Optional overrides for zoom limits
  ///
  /// Returns a new [ZoomPanState] with updated zoom levels and pan offset.
  ZoomPanState zoom(
    ZoomPanState state, {
    required double zoomFactor,
    required Offset focalPoint,
    required bool isMultiAxisMode,
    double? minZoom,
    double? maxZoom,
  }) {
    // Calculate new zoom levels
    final newZoomX = state.zoomLevelX * zoomFactor;

    // FR-013: In multi-axis mode, Y zoom is constrained to 1.0
    // This ensures each series uses full vertical space with its own scale
    final double newZoomY;
    if (isMultiAxisMode) {
      // Force Y zoom to 1.0 (identity) in multi-axis mode
      newZoomY = 1.0;
    } else {
      // Normal mode: apply zoom factor to Y as well
      newZoomY = state.zoomLevelY * zoomFactor;
    }

    // Apply zoom limits
    final minLevel = minZoom ?? state.minZoomLevel;
    final maxLevel = maxZoom ?? state.maxZoomLevel;
    final clampedZoomX = newZoomX.clamp(minLevel, maxLevel);
    final clampedZoomY = isMultiAxisMode ? 1.0 : newZoomY.clamp(minLevel, maxLevel);

    // Calculate pan offset to keep focal point fixed
    // Formula: new_pan = old_pan + focal * (1 - zoom_ratio)
    final zoomRatioX = clampedZoomX / state.zoomLevelX;
    final zoomRatioY = clampedZoomY / state.zoomLevelY;

    final newPanX = state.panOffset.dx + focalPoint.dx * (1 - zoomRatioX);

    // FR-013: In multi-axis mode, Y pan offset should not change from zoom
    final double newPanY;
    if (isMultiAxisMode) {
      // Keep Y pan at zero in multi-axis mode (or preserve but don't modify)
      newPanY = 0.0;
    } else {
      newPanY = state.panOffset.dy + focalPoint.dy * (1 - zoomRatioY);
    }

    return state.copyWith(
      zoomLevelX: clampedZoomX,
      zoomLevelY: clampedZoomY,
      panOffset: Offset(newPanX, newPanY),
    );
  }

  /// Sets the zoom level to an exact value with multi-axis awareness.
  ///
  /// Unlike [zoom], this sets the absolute zoom level rather than multiplying.
  /// In multi-axis mode, only X zoom is applied; Y remains at 1.0.
  ZoomPanState zoomTo(
    ZoomPanState state, {
    required double targetZoom,
    required Offset focalPoint,
    required bool isMultiAxisMode,
  }) {
    final zoomFactor = targetZoom / state.zoomLevelX;
    return zoom(
      state,
      zoomFactor: zoomFactor,
      focalPoint: focalPoint,
      isMultiAxisMode: isMultiAxisMode,
    );
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

  /// Pans the chart by the specified delta with multi-axis awareness.
  ///
  /// **FR-013 Implementation**: When [isMultiAxisMode] is true, only X-axis
  /// pan is applied. The Y-axis pan remains unchanged (constrained to 0).
  ///
  /// Parameters:
  /// - [state]: The current zoom/pan state
  /// - [delta]: Pan movement in screen pixels (positive dx = pan right)
  /// - [isMultiAxisMode]: When true, Y-axis pan is constrained
  /// - [bounds]: Optional data bounds for constraining pan
  ///
  /// Returns a new [ZoomPanState] with updated pan offset.
  ZoomPanState pan(
    ZoomPanState state,
    Offset delta, {
    required bool isMultiAxisMode,
    Rect? bounds,
  }) {
    // Calculate new pan offset
    final newPanX = state.panOffset.dx + delta.dx;

    // FR-013: In multi-axis mode, Y pan is constrained to 0
    final double newPanY;
    if (isMultiAxisMode) {
      newPanY = 0.0; // Force Y pan to zero
    } else {
      newPanY = state.panOffset.dy + delta.dy;
    }

    var newPan = Offset(newPanX, newPanY);

    // Apply bounds constraint if provided
    if (bounds != null && !state.allowOverscroll) {
      final visibleDataWidth = bounds.width / state.zoomLevelX;
      final visibleDataHeight = bounds.height / state.zoomLevelY;

      const maxPanX = 0.0;
      final minPanX = -(bounds.width - visibleDataWidth);
      const maxPanY = 0.0;
      final minPanY = -(bounds.height - visibleDataHeight);

      if (isMultiAxisMode) {
        // Only constrain X pan in multi-axis mode
        newPan = Offset(newPanX.clamp(minPanX, maxPanX), 0.0);
      } else {
        newPan = Offset(
          newPanX.clamp(minPanX, maxPanX),
          newPanY.clamp(minPanY, maxPanY),
        );
      }
    }

    return state.copyWith(panOffset: newPan);
  }

  /// Processes a gesture with multi-axis awareness.
  ///
  /// Handles pinch (zoom), pan, and double-tap gestures with FR-013 constraints
  /// applied when [isMultiAxisMode] is true.
  ZoomPanState processGesture(
    ZoomPanState state,
    GestureDetails gesture, {
    required bool isMultiAxisMode,
    double? doubleTapZoomFactor,
  }) {
    switch (gesture.type) {
      case GestureType.pinch:
        final scale = gesture.currentScale ?? 1.0;
        final focalPoint = gesture.currentPosition;
        return zoom(
          state,
          zoomFactor: scale,
          focalPoint: focalPoint,
          isMultiAxisMode: isMultiAxisMode,
        );

      case GestureType.pan:
        final delta = gesture.panDelta ?? Offset.zero;
        return pan(state, delta, isMultiAxisMode: isMultiAxisMode);

      case GestureType.doubleTap:
        final zoomFactor = doubleTapZoomFactor ?? 2.0;
        final focalPoint = gesture.currentPosition;
        return zoom(
          state,
          zoomFactor: zoomFactor,
          focalPoint: focalPoint,
          isMultiAxisMode: isMultiAxisMode,
        );

      default:
        return state;
    }
  }

  /// Converts screen coordinates to data coordinates.
  ///
  /// Takes a point in screen space and transforms it to data space,
  /// accounting for current zoom and pan.
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
  /// accounting for current zoom and pan.
  Offset dataToScreen(
    Offset dataPoint,
    ZoomPanState state,
  ) {
    final screenX = dataPoint.dx * state.zoomLevelX + state.panOffset.dx;
    final screenY = dataPoint.dy * state.zoomLevelY + state.panOffset.dy;
    return Offset(screenX, screenY);
  }

  /// Checks if Y-axis operations are constrained.
  ///
  /// Returns true when in multi-axis mode, indicating Y zoom/pan is disabled.
  /// Useful for UI feedback (e.g., disabling Y-axis zoom gestures visually).
  bool isYAxisConstrained(bool isMultiAxisMode) => isMultiAxisMode;

  /// Gets the effective zoom factor for Y-axis.
  ///
  /// In multi-axis mode, always returns 1.0 (identity).
  /// In normal mode, returns the provided zoom factor unchanged.
  double getEffectiveYZoomFactor(double zoomFactor, bool isMultiAxisMode) {
    return isMultiAxisMode ? 1.0 : zoomFactor;
  }

  /// Gets the effective pan delta for Y-axis.
  ///
  /// In multi-axis mode, always returns 0.0 (no Y pan).
  /// In normal mode, returns the provided delta unchanged.
  double getEffectiveYPanDelta(double deltaY, bool isMultiAxisMode) {
    return isMultiAxisMode ? 0.0 : deltaY;
  }
}
