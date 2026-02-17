// Copyright (c) 2025 braven_charts. All rights reserved.
// Scrollbar Manager - Extracted from ChartRenderBox

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import '../../coordinates/chart_transform.dart';
import '../../theming/components/scrollbar_config.dart';
import '../../utils/data_converter.dart';
import '../../widgets/scrollbar/hit_test_zone.dart';
import '../../widgets/scrollbar/scrollbar_controller.dart';
import '../../widgets/scrollbar/scrollbar_interaction.dart';
import '../../widgets/scrollbar/scrollbar_painter.dart';
import '../../widgets/scrollbar/scrollbar_state.dart';

/// Re-export for convenience
export '../../utils/data_converter.dart' show DataBounds;
export '../../widgets/scrollbar/hit_test_zone.dart' show HitTestZone;
export '../../widgets/scrollbar/scrollbar_interaction.dart'
    show ScrollbarInteraction;

/// Delegate interface for ScrollbarManager to interact with ChartRenderBox.
///
/// This abstraction allows ScrollbarManager to:
/// - Read viewport state (transforms, bounds)
/// - Apply viewport changes (via callback)
/// - Trigger repaints
/// - Update cursor feedback
abstract interface class ScrollbarDelegate {
  /// Current viewport transform (may be null during initialization).
  ChartTransform? get transform;

  /// Original data bounds transform (for calculating scrollbar handle size).
  ChartTransform? get originalTransform;

  /// Streaming bounds (overrides originalTransform for streaming charts).
  DataBounds? get streamingBounds;

  /// Apply a new transform (triggers viewport update).
  void applyTransform(ChartTransform newTransform);

  /// Update axes from the current transform.
  void updateAxesFromTransform();

  /// Request a repaint.
  void markNeedsPaint();

  /// Update mouse cursor.
  void setCursor(MouseCursor cursor);
}

/// Manages all scrollbar-related state and interactions.
///
/// This module encapsulates:
/// - Scrollbar visibility and configuration
/// - Hit testing for scrollbar zones
/// - Drag interaction handling
/// - Auto-hide timer management
/// - Scrollbar rendering
///
/// The module uses a delegate pattern to interact with ChartRenderBox,
/// allowing clean separation of concerns while enabling transform updates.
class ScrollbarManager {
  ScrollbarManager({
    required ScrollbarDelegate delegate,
    bool showXScrollbar = false,
    bool showYScrollbar = false,
    ScrollbarConfig? scrollbarTheme,
  }) : _delegate = delegate,
       _showXScrollbar = showXScrollbar,
       _showYScrollbar = showYScrollbar,
       _scrollbarTheme = scrollbarTheme;

  // ==========================================================================
  // Dependencies
  // ==========================================================================

  final ScrollbarDelegate _delegate;

  // ==========================================================================
  // Scrollbar Configuration
  // ==========================================================================

  /// Whether to show horizontal scrollbar at bottom of chart.
  bool _showXScrollbar;

  /// Whether to show vertical scrollbar on right side of chart.
  bool _showYScrollbar;

  /// Theme configuration for scrollbars.
  /// If null, defaults to ScrollbarConfig.defaultLight.
  ScrollbarConfig? _scrollbarTheme;

  // ==========================================================================
  // Scrollbar Layout State
  // ==========================================================================

  /// Horizontal scrollbar rectangle (positioned below chart, if enabled).
  Rect? _xScrollbarRect;

  /// Vertical scrollbar rectangle (positioned to right of chart, if enabled).
  Rect? _yScrollbarRect;

  // ==========================================================================
  // Scrollbar Interaction State
  // ==========================================================================

  /// Active scrollbar being dragged (null if not dragging scrollbar).
  Axis? _activeScrollbarAxis;

  /// Initial pointer position when scrollbar drag started (in widget coordinates).
  Offset? _scrollbarDragStartPosition;

  /// Hit test zone where drag started (leftEdge, rightEdge, center, track, etc.).
  HitTestZone? _scrollbarDragStartZone;

  /// Last known drag position for incremental delta calculation.
  /// Using incremental deltas instead of accumulated deltas prevents oversensitivity.
  Offset? _scrollbarLastDragPosition;

  /// Current hover zone for X scrollbar (for visual feedback).
  HitTestZone? _xScrollbarHoverZone;

  /// Current hover zone for Y scrollbar (for visual feedback).
  HitTestZone? _yScrollbarHoverZone;

  // ==========================================================================
  // Scrollbar Auto-Hide State
  // ==========================================================================

  /// Timer for auto-hiding scrollbars after inactivity.
  Timer? _scrollbarAutoHideTimer;

  /// Whether scrollbar initialization logic has run.
  /// Used to ensure the postFrameCallback for auto-hide runs only once.
  bool _scrollbarInitialized = false;

  /// Whether scrollbars are currently visible.
  /// When false, scrollbars don't render and don't respond to interaction.
  /// Defaults to true - will be adjusted in performLayout based on autoHide config.
  bool _scrollbarsVisible = true;

  // ==========================================================================
  // Public Getters
  // ==========================================================================

  /// Whether X scrollbar is enabled.
  bool get showXScrollbar => _showXScrollbar;

  /// Whether Y scrollbar is enabled.
  bool get showYScrollbar => _showYScrollbar;

  /// Current scrollbar theme configuration.
  ScrollbarConfig? get scrollbarTheme => _scrollbarTheme;

  /// X scrollbar rectangle (may be null if not enabled or not laid out).
  Rect? get xScrollbarRect => _xScrollbarRect;

  /// Y scrollbar rectangle (may be null if not enabled or not laid out).
  Rect? get yScrollbarRect => _yScrollbarRect;

  /// Whether scrollbars are currently visible (for auto-hide).
  bool get scrollbarsVisible => _scrollbarsVisible;

  /// Whether scrollbar initialization has been done.
  bool get scrollbarInitialized => _scrollbarInitialized;

  /// Whether a scrollbar drag is currently active.
  bool get isDragging => _activeScrollbarAxis != null;

  /// The active scrollbar axis being dragged (null if not dragging).
  Axis? get activeScrollbarAxis => _activeScrollbarAxis;

  // ==========================================================================
  // Public Setters / Configuration
  // ==========================================================================

  /// Updates X scrollbar visibility.
  /// Returns true if value changed (requiring layout).
  bool setShowXScrollbar(bool show) {
    if (_showXScrollbar == show) return false;
    _showXScrollbar = show;
    return true;
  }

  /// Updates Y scrollbar visibility.
  /// Returns true if value changed (requiring layout).
  bool setShowYScrollbar(bool show) {
    if (_showYScrollbar == show) return false;
    _showYScrollbar = show;
    return true;
  }

  /// Updates scrollbar theme configuration.
  /// Returns true if value changed (requiring repaint).
  bool setScrollbarTheme(ScrollbarConfig? theme) {
    if (_scrollbarTheme == theme) return false;
    _scrollbarTheme = theme;

    // Re-evaluate scrollbar visibility based on new theme's autoHide setting
    final autoHide = _scrollbarTheme?.autoHide ?? true;
    if (!autoHide) {
      // If autoHide is disabled, scrollbars should always be visible
      _scrollbarsVisible = true;
      _cancelScrollbarAutoHide();
    } else {
      _scrollbarsVisible = isViewportModified();
    }
    return true;
  }

  /// Sets scrollbar rects during layout.
  void setScrollbarRects({Rect? xRect, Rect? yRect}) {
    _xScrollbarRect = xRect;
    _yScrollbarRect = yRect;
  }

  /// Marks initialization as complete.
  void markInitialized() {
    _scrollbarInitialized = true;
  }

  /// Sets scrollbars visibility explicitly.
  void setScrollbarsVisible(bool visible) {
    _scrollbarsVisible = visible;
  }

  // ==========================================================================
  // Scrollbar Auto-Hide Logic
  // ==========================================================================

  /// Schedules scrollbar auto-hide after configured inactivity delay.
  ///
  /// "Inactivity" means no zoom/pan actions (mouse, keyboard, or scrollbar).
  /// Cancels any existing timer and starts fresh countdown.
  void scheduleScrollbarAutoHide() {
    final scrollbarConfig = _scrollbarTheme ?? ScrollbarConfig.defaultLight;
    if (!scrollbarConfig.autoHide) return;

    _cancelScrollbarAutoHide();

    _scrollbarAutoHideTimer = Timer(scrollbarConfig.autoHideDelay, () {
      _scrollbarsVisible = false;
      _delegate.markNeedsPaint();
    });
  }

  /// Cancels scheduled auto-hide timer without changing visibility.
  void _cancelScrollbarAutoHide() {
    _scrollbarAutoHideTimer?.cancel();
    _scrollbarAutoHideTimer = null;
  }

  /// Shows scrollbars and schedules auto-hide.
  ///
  /// Call on any zoom/pan action to show scrollbars and reset inactivity timer.
  void showScrollbarsAndScheduleHide() {
    _scrollbarsVisible = true;
    scheduleScrollbarAutoHide();
    _delegate.markNeedsPaint();
  }

  /// Checks if viewport is zoomed or panned from original state.
  ///
  /// Returns true if the current transform differs from the original transform,
  /// indicating the user has panned or zoomed the chart.
  bool isViewportModified() {
    final transform = _delegate.transform;
    final originalTransform = _delegate.originalTransform;
    if (transform == null || originalTransform == null) return false;

    return transform.dataXMin != originalTransform.dataXMin ||
        transform.dataXMax != originalTransform.dataXMax ||
        transform.dataYMin != originalTransform.dataYMin ||
        transform.dataYMax != originalTransform.dataYMax;
  }

  // ==========================================================================
  // Scrollbar Hover Handling
  // ==========================================================================

  /// Checks if pointer is hovering over a scrollbar and updates hover state.
  ///
  /// Returns true if pointer is over a scrollbar, false otherwise.
  bool checkScrollbarHover(Offset position) {
    final transform = _delegate.transform;
    final originalTransform = _delegate.originalTransform;
    if (transform == null || originalTransform == null) return false;

    // When scrollbars are hidden, they don't exist for interaction
    if (!_scrollbarsVisible) return false;

    // Check X scrollbar hover
    if (_showXScrollbar &&
        _xScrollbarRect != null &&
        _xScrollbarRect!.contains(position)) {
      final localX = position.dx - _xScrollbarRect!.left;
      final zone = _getScrollbarZoneAtPosition(Axis.horizontal, localX);
      final cursor = _getCursorForScrollbarZone(zone, Axis.horizontal);
      _delegate.setCursor(cursor);

      // Cancel auto-hide while hovering (user might be about to interact)
      _cancelScrollbarAutoHide();

      // Store hover zone and repaint to show visual feedback
      if (_xScrollbarHoverZone != zone) {
        _xScrollbarHoverZone = zone;
        _delegate.markNeedsPaint();
      }

      return true;
    }

    // Check Y scrollbar hover
    if (_showYScrollbar &&
        _yScrollbarRect != null &&
        _yScrollbarRect!.contains(position)) {
      final localY = position.dy - _yScrollbarRect!.top;
      final zone = _getScrollbarZoneAtPosition(Axis.vertical, localY);
      final cursor = _getCursorForScrollbarZone(zone, Axis.vertical);
      _delegate.setCursor(cursor);

      // Cancel auto-hide while hovering (user might be about to interact)
      _cancelScrollbarAutoHide();

      // Store hover zone and repaint to show visual feedback
      if (_yScrollbarHoverZone != zone) {
        _yScrollbarHoverZone = zone;
        _delegate.markNeedsPaint();
      }

      return true;
    }

    // Clear hover zones when not hovering over scrollbars
    if (_xScrollbarHoverZone != null || _yScrollbarHoverZone != null) {
      _xScrollbarHoverZone = null;
      _yScrollbarHoverZone = null;

      // Resume auto-hide timer when mouse leaves scrollbar
      scheduleScrollbarAutoHide();

      _delegate.markNeedsPaint();
    }

    return false; // Not hovering over scrollbar
  }

  /// Gets the scrollbar zone at a local position within the scrollbar.
  HitTestZone? _getScrollbarZoneAtPosition(Axis axis, double localPos) {
    final transform = _delegate.transform;
    final originalTransform = _delegate.originalTransform;
    if (transform == null || originalTransform == null) return null;

    final scrollbarRect = axis == Axis.horizontal
        ? _xScrollbarRect
        : _yScrollbarRect;
    if (scrollbarRect == null) return null;

    final trackLength = axis == Axis.horizontal
        ? scrollbarRect.width
        : scrollbarRect.height;

    // CRITICAL: Use streaming bounds when available for correct handle positioning
    final double dataMin;
    final double dataMax;
    final streamingBounds = _delegate.streamingBounds;
    if (streamingBounds != null && axis == Axis.horizontal) {
      dataMin = streamingBounds.xMin;
      dataMax = streamingBounds.xMax;
    } else if (streamingBounds != null && axis == Axis.vertical) {
      dataMin = streamingBounds.yMin;
      dataMax = streamingBounds.yMax;
    } else {
      dataMin = axis == Axis.horizontal
          ? originalTransform.dataXMin
          : originalTransform.dataYMin;
      dataMax = axis == Axis.horizontal
          ? originalTransform.dataXMax
          : originalTransform.dataYMax;
    }
    final viewportMin = axis == Axis.horizontal
        ? transform.dataXMin
        : transform.dataYMin;
    final viewportMax = axis == Axis.horizontal
        ? transform.dataXMax
        : transform.dataYMax;

    final dataSpan = dataMax - dataMin;
    final viewportSpan = viewportMax - viewportMin;
    final scrollbarTheme = _scrollbarTheme ?? ScrollbarConfig.defaultLight;

    // Calculate handle geometry
    final handleSize = (viewportSpan / dataSpan * trackLength).clamp(
      scrollbarTheme.minHandleSize,
      trackLength,
    );

    // Calculate handle position (same logic for both axes - no inversion!)
    // For Y-axis: Chart Y increases upward, but screen Y increases downward
    // The natural mapping works: viewport at bottom (low Y) → handle at top (low screen Y)
    final handlePosition = ((viewportMin - dataMin) / dataSpan * trackLength)
        .clamp(0.0, trackLength - handleSize);

    // Calculate zoom-adjusted edge grip width (must match rendering logic)
    // Both X and Y axes now use LINEAR zoom scaling for consistency
    final zoomFactor = dataSpan / viewportSpan;
    final baseEdgeGripWidth = scrollbarTheme.edgeGripWidth;
    final maxEdgeGripWidth = handleSize * 0.4; // Max 40% of handle size
    final zoomAdjustedEdgeGripWidth = (baseEdgeGripWidth * zoomFactor)
        .clamp(
          math.min(baseEdgeGripWidth, maxEdgeGripWidth), // Ensure min <= max
          maxEdgeGripWidth,
        )
        .toDouble();

    // Use ScrollbarController to determine zone
    final zone = ScrollbarController.getHitTestZone(
      axis == Axis.horizontal ? Offset(localPos, 0) : Offset(0, localPos),
      axis,
      trackLength,
      handlePosition,
      handleSize,
      edgeDetectionThreshold: zoomAdjustedEdgeGripWidth,
    );

    return zone;
  }

  /// Gets the appropriate cursor for a scrollbar zone.
  MouseCursor _getCursorForScrollbarZone(HitTestZone? zone, Axis axis) {
    if (zone == null) return SystemMouseCursors.basic;

    switch (zone) {
      case HitTestZone.track:
        return SystemMouseCursors.click; // Click to jump
      case HitTestZone.center:
        return SystemMouseCursors.grab; // Drag to pan
      case HitTestZone.leftEdge:
      case HitTestZone.rightEdge:
        return SystemMouseCursors.resizeColumn; // Drag to zoom horizontally
      case HitTestZone.topEdge:
      case HitTestZone.bottomEdge:
        return SystemMouseCursors.resizeRow; // Drag to zoom vertically
    }
  }

  // ==========================================================================
  // Scrollbar Hit Testing & Interaction Start
  // ==========================================================================

  /// Hit tests scrollbar regions and handles initial scrollbar interaction.
  ///
  /// Returns true if pointer is on a scrollbar and starts interaction, false otherwise.
  /// When true is returned, the pointer event should not propagate to chart handlers.
  ///
  /// The [isModal] parameter indicates whether the coordinator is in modal mode.
  /// The [onClaimMode] callback is called to claim scrollbar dragging mode.
  /// The [cancelAutoScroll] callback is called to cancel any active auto-scroll.
  bool hitTestScrollbars(
    Offset position,
    int buttons, {
    required bool isModal,
    required VoidCallback onClaimMode,
    required VoidCallback cancelAutoScroll,
  }) {
    if (buttons != kPrimaryMouseButton) {
      return false; // Only left-click interacts with scrollbars
    }

    // Check X scrollbar (horizontal, bottom of chart)
    if (_showXScrollbar &&
        _xScrollbarRect != null &&
        _xScrollbarRect!.contains(position)) {
      return _startScrollbarInteraction(
        Axis.horizontal,
        position,
        isModal: isModal,
        onClaimMode: onClaimMode,
        cancelAutoScroll: cancelAutoScroll,
      );
    }

    // Check Y scrollbar (vertical, right of chart)
    if (_showYScrollbar &&
        _yScrollbarRect != null &&
        _yScrollbarRect!.contains(position)) {
      return _startScrollbarInteraction(
        Axis.vertical,
        position,
        isModal: isModal,
        onClaimMode: onClaimMode,
        cancelAutoScroll: cancelAutoScroll,
      );
    }

    return false; // Not on any scrollbar
  }

  /// Starts scrollbar interaction after hit test confirms pointer is on scrollbar.
  ///
  /// Returns true to indicate event was claimed by scrollbar.
  bool _startScrollbarInteraction(
    Axis axis,
    Offset position, {
    required bool isModal,
    required VoidCallback onClaimMode,
    required VoidCallback cancelAutoScroll,
  }) {
    final transform = _delegate.transform;
    final originalTransform = _delegate.originalTransform;
    if (transform == null || originalTransform == null) {
      return false; // Transform not ready
    }

    // Check if coordinator allows scrollbar interaction (not blocked by modal modes)
    if (isModal) {
      return false; // Modal state blocks scrollbar interaction
    }

    // Get scrollbar rect based on axis
    final scrollbarRect = axis == Axis.horizontal
        ? _xScrollbarRect
        : _yScrollbarRect;
    if (scrollbarRect == null) return false;

    // Calculate handle geometry
    final isHorizontal = axis == Axis.horizontal;
    final trackLength = isHorizontal
        ? scrollbarRect.width
        : scrollbarRect.height;

    // CRITICAL: Use streaming bounds when available for correct handle positioning
    final double dataMin;
    final double dataMax;
    final streamingBounds = _delegate.streamingBounds;
    if (streamingBounds != null && isHorizontal) {
      dataMin = streamingBounds.xMin;
      dataMax = streamingBounds.xMax;
    } else if (streamingBounds != null && !isHorizontal) {
      dataMin = streamingBounds.yMin;
      dataMax = streamingBounds.yMax;
    } else {
      dataMin = isHorizontal
          ? originalTransform.dataXMin
          : originalTransform.dataYMin;
      dataMax = isHorizontal
          ? originalTransform.dataXMax
          : originalTransform.dataYMax;
    }
    final viewportMin = isHorizontal ? transform.dataXMin : transform.dataYMin;
    final viewportMax = isHorizontal ? transform.dataXMax : transform.dataYMax;

    final dataSpan = dataMax - dataMin;
    final viewportSpan = viewportMax - viewportMin;
    final scrollbarTheme = _scrollbarTheme ?? ScrollbarConfig.defaultLight;

    // Calculate handle size and position using same formulas as paint
    final handleSize = (viewportSpan / dataSpan * trackLength).clamp(
      scrollbarTheme.minHandleSize,
      trackLength,
    );

    // Calculate handle position (same formula for both axes - natural mapping works!)
    final handlePosition = ((viewportMin - dataMin) / dataSpan * trackLength)
        .clamp(0.0, trackLength - handleSize);

    // Calculate zoom-adjusted edge grip width (must match rendering logic)
    // Both X and Y axes use LINEAR zoom scaling for consistency
    final zoomFactor = dataSpan / viewportSpan;
    final baseEdgeGripWidth = scrollbarTheme.edgeGripWidth;
    final maxEdgeGripWidth = handleSize * 0.4; // Max 40% of handle size
    final zoomAdjustedEdgeGripWidth = (baseEdgeGripWidth * zoomFactor)
        .clamp(
          math.min(baseEdgeGripWidth, maxEdgeGripWidth), // Ensure min <= max
          maxEdgeGripWidth,
        )
        .toDouble();

    // Convert pointer position to scrollbar-local coordinate
    final localPos = isHorizontal
        ? (position.dx - scrollbarRect.left)
        : (position.dy - scrollbarRect.top);

    // Use ScrollbarController to determine which zone was hit (with zoom-adjusted edges)
    final hitZone = ScrollbarController.getHitTestZone(
      isHorizontal
          ? Offset(localPos, 0)
          : Offset(0, localPos), // Correct offset based on axis
      axis,
      trackLength,
      handlePosition,
      handleSize,
      edgeDetectionThreshold: zoomAdjustedEdgeGripWidth,
    );

    if (hitZone == null) {
      return false; // Outside scrollbar bounds
    }

    // Store drag state
    _activeScrollbarAxis = axis;
    _scrollbarDragStartPosition = position;
    _scrollbarLastDragPosition =
        position; // Initialize for incremental delta tracking
    _scrollbarDragStartZone = hitZone;

    // CRITICAL: Cancel auto-scroll when user interacts with scrollbar
    // This prevents auto-scroll from overriding manual scrollbar zoom/pan
    cancelAutoScroll();

    // Show scrollbars and cancel auto-hide during drag (don't hide while dragging!)
    _scrollbarsVisible = true;
    _cancelScrollbarAutoHide();

    // Handle track click immediately (doesn't require drag)
    if (hitZone == HitTestZone.track) {
      _handleScrollbarTrackClick(axis, localPos, trackLength, handleSize);
    }

    // Claim scrollbar mode in coordinator
    onClaimMode();

    _delegate.markNeedsPaint(); // Redraw with active state
    return true; // Event claimed by scrollbar
  }

  // ==========================================================================
  // Scrollbar Drag Handling
  // ==========================================================================

  /// Handles ongoing scrollbar drag interaction.
  void handleScrollbarDrag(Offset currentPosition) {
    if (_activeScrollbarAxis == null ||
        _scrollbarDragStartPosition == null ||
        _scrollbarDragStartZone == null ||
        _scrollbarLastDragPosition == null) {
      return; // No active drag
    }

    // Track clicks don't drag - they jump immediately
    if (_scrollbarDragStartZone == HitTestZone.track) {
      return;
    }

    final axis = _activeScrollbarAxis!;
    final lastPos = _scrollbarLastDragPosition!;
    final zone = _scrollbarDragStartZone!;

    // Calculate INCREMENTAL pixel delta from last position (not from drag start)
    // This fixes issue #4: oversensitive pan due to accumulated delta
    final pixelDelta = axis == Axis.horizontal
        ? (currentPosition.dx - lastPos.dx)
        : (currentPosition.dy - lastPos.dy);

    // Update last position for next incremental delta
    _scrollbarLastDragPosition = currentPosition;

    // Convert zone to interaction type
    final interactionType = _scrollbarZoneToInteractionType(zone, axis);

    // Call appropriate pixel-delta handler
    if (axis == Axis.horizontal) {
      _handleXScrollbarDelta(pixelDelta, interactionType);
    } else {
      _handleYScrollbarDelta(pixelDelta, interactionType);
    }
  }

  /// Clears scrollbar drag state when drag ends.
  void clearScrollbarDragState() {
    _activeScrollbarAxis = null;
    _scrollbarDragStartPosition = null;
    _scrollbarDragStartZone = null;
    _scrollbarLastDragPosition = null;

    // Schedule auto-hide after drag ends (start inactivity timer)
    scheduleScrollbarAutoHide();

    _delegate.markNeedsPaint(); // Redraw with updated hover state
  }

  /// Handles track click (jump to clicked position).
  void _handleScrollbarTrackClick(
    Axis axis,
    double clickPosition,
    double trackLength,
    double handleSize,
  ) {
    // Calculate where the handle CENTER should be positioned (clicked position)
    final targetHandleCenter = clickPosition;

    // Calculate where handle CENTER currently is
    final currentHandlePosition = _calculateCurrentHandlePosition(axis);
    final currentHandleCenter = currentHandlePosition + (handleSize / 2.0);

    // Pixel delta = where we want to be - where we are
    final pixelDelta = targetHandleCenter - currentHandleCenter;

    // Call pixel-delta handler with trackClick interaction type
    if (axis == Axis.horizontal) {
      _handleXScrollbarDelta(pixelDelta, ScrollbarInteraction.trackClick);
    } else {
      _handleYScrollbarDelta(pixelDelta, ScrollbarInteraction.trackClick);
    }
  }

  /// Calculates current handle position for an axis (used for track click calculations).
  double _calculateCurrentHandlePosition(Axis axis) {
    final transform = _delegate.transform;
    final originalTransform = _delegate.originalTransform;
    if (transform == null || originalTransform == null) return 0.0;

    final isHorizontal = axis == Axis.horizontal;
    final scrollbarRect = isHorizontal ? _xScrollbarRect : _yScrollbarRect;
    if (scrollbarRect == null) return 0.0;

    final trackLength = isHorizontal
        ? scrollbarRect.width
        : scrollbarRect.height;

    // CRITICAL: Use streaming bounds when available for correct scrollbar behavior
    final double dataMin;
    final double dataMax;
    final streamingBounds = _delegate.streamingBounds;
    if (streamingBounds != null && isHorizontal) {
      dataMin = streamingBounds.xMin;
      dataMax = streamingBounds.xMax;
    } else if (streamingBounds != null && !isHorizontal) {
      dataMin = streamingBounds.yMin;
      dataMax = streamingBounds.yMax;
    } else {
      dataMin = isHorizontal
          ? originalTransform.dataXMin
          : originalTransform.dataYMin;
      dataMax = isHorizontal
          ? originalTransform.dataXMax
          : originalTransform.dataYMax;
    }
    final viewportMin = isHorizontal ? transform.dataXMin : transform.dataYMin;

    final dataSpan = dataMax - dataMin;
    if (dataSpan <= 0) return 0.0;

    // Calculate handle position (same formula for both axes - natural mapping!)
    final viewportOffset = viewportMin - dataMin;
    return (viewportOffset / dataSpan * trackLength).clamp(0.0, trackLength);
  }

  /// Converts HitTestZone to ScrollbarInteraction type.
  ScrollbarInteraction _scrollbarZoneToInteractionType(
    HitTestZone zone,
    Axis axis,
  ) {
    switch (zone) {
      case HitTestZone.leftEdge:
      case HitTestZone.topEdge:
        return ScrollbarInteraction.zoomLeftOrTop;
      case HitTestZone.rightEdge:
      case HitTestZone.bottomEdge:
        return ScrollbarInteraction.zoomRightOrBottom;
      case HitTestZone.center:
        return ScrollbarInteraction.pan;
      case HitTestZone.track:
        return ScrollbarInteraction.trackClick;
    }
  }

  // ==========================================================================
  // Scrollbar Delta Handlers
  // ==========================================================================

  /// Handles horizontal scrollbar pixel delta and converts to viewport change.
  ///
  /// Converts pixel delta from scrollbar to data delta using current viewport,
  /// then updates the X viewport range accordingly.
  ///
  /// **Parameters**:
  /// - `pixelDelta`: Horizontal pixel offset from scrollbar drag
  /// - `interactionType`: Type of scrollbar interaction (pan, zoom, track click)
  void _handleXScrollbarDelta(
    double pixelDelta,
    ScrollbarInteraction interactionType,
  ) {
    final transform = _delegate.transform;
    final originalTransform = _delegate.originalTransform;
    if (transform == null ||
        originalTransform == null ||
        _xScrollbarRect == null) {
      return;
    }

    final trackLength = _xScrollbarRect!.width;
    if (trackLength == 0) return;

    // CRITICAL: Use streaming bounds when available for correct scrollbar interaction
    final double dataMin;
    final double dataMax;
    final streamingBounds = _delegate.streamingBounds;
    if (streamingBounds != null) {
      dataMin = streamingBounds.xMin;
      dataMax = streamingBounds.xMax;
    } else {
      dataMin = originalTransform.dataXMin;
      dataMax = originalTransform.dataXMax;
    }
    final dataSpan = dataMax - dataMin;
    if (dataSpan <= 0) return;

    // Get current viewport range
    final viewportMin = transform.dataXMin;
    final viewportMax = transform.dataXMax;
    final viewportSpan = viewportMax - viewportMin;

    // Convert pixel delta to data delta
    final dataPerPixel = dataSpan / trackLength;
    final dataDelta = pixelDelta * dataPerPixel;

    ChartTransform? newTransform;

    // Apply based on interaction type
    switch (interactionType) {
      case ScrollbarInteraction.pan:
        // Pan: shift entire viewport by delta
        var newMin = viewportMin + dataDelta;
        var newMax = viewportMax + dataDelta;

        // Clamp to data bounds
        if (newMin < dataMin) {
          newMin = dataMin;
          newMax = dataMin + viewportSpan;
        }
        if (newMax > dataMax) {
          newMax = dataMax;
          newMin = dataMax - viewportSpan;
        }

        newTransform = transform.copyWith(dataXMin: newMin, dataXMax: newMax);
        break;

      case ScrollbarInteraction.zoomLeftOrTop:
        // Zoom left: adjust minimum boundary only
        var newMin = viewportMin + dataDelta;

        // Clamp to prevent inversion and respect data bounds
        newMin = newMin.clamp(
          dataMin,
          viewportMax - (dataSpan * 0.01),
        ); // Min 1% of data range

        newTransform = transform.copyWith(dataXMin: newMin);
        break;

      case ScrollbarInteraction.zoomRightOrBottom:
        // Zoom right: adjust maximum boundary only
        var newMax = viewportMax + dataDelta;

        // Clamp to prevent inversion and respect data bounds
        newMax = newMax.clamp(
          viewportMin + (dataSpan * 0.01),
          dataMax,
        ); // Min 1% of data range

        newTransform = transform.copyWith(dataXMax: newMax);
        break;

      case ScrollbarInteraction.trackClick:
        // Track click: center viewport at clicked position
        final targetDataPosition = dataMin + (pixelDelta * dataPerPixel);
        final halfSpan = viewportSpan / 2;

        var newMin = targetDataPosition - halfSpan;
        var newMax = targetDataPosition + halfSpan;

        // Clamp to data bounds
        if (newMin < dataMin) {
          newMin = dataMin;
          newMax = dataMin + viewportSpan;
        }
        if (newMax > dataMax) {
          newMax = dataMax;
          newMin = dataMax - viewportSpan;
        }

        newTransform = transform.copyWith(dataXMin: newMin, dataXMax: newMax);
        break;

      case ScrollbarInteraction.keyboard:
        // Keyboard: apply delta directly (already calculated by controller)
        var newMin = viewportMin + dataDelta;
        var newMax = viewportMax + dataDelta;

        // Clamp to data bounds
        if (newMin < dataMin) {
          newMin = dataMin;
          newMax = dataMin + viewportSpan;
        }
        if (newMax > dataMax) {
          newMax = dataMax;
          newMin = dataMax - viewportSpan;
        }

        newTransform = transform.copyWith(dataXMin: newMin, dataXMax: newMax);
        break;
    }

    _delegate.applyTransform(newTransform);
    _delegate.updateAxesFromTransform();
    showScrollbarsAndScheduleHide();
  }

  /// Handles vertical scrollbar pixel delta and converts to viewport change.
  ///
  /// Converts pixel delta from scrollbar to data delta using current viewport,
  /// then updates the Y viewport range accordingly.
  ///
  /// **Y-AXIS COORDINATE MAPPING**: Drag direction matches viewport movement.
  /// Positive pixelDelta (drag down) moves viewport DOWN (to lower Y values).
  /// Negative pixelDelta (drag up) moves viewport UP (to higher Y values).
  ///
  /// **Parameters**:
  /// - `pixelDelta`: Vertical pixel offset from scrollbar drag
  /// - `interactionType`: Type of scrollbar interaction (pan, zoom, track click)
  void _handleYScrollbarDelta(
    double pixelDelta,
    ScrollbarInteraction interactionType,
  ) {
    final transform = _delegate.transform;
    final originalTransform = _delegate.originalTransform;
    if (transform == null ||
        originalTransform == null ||
        _yScrollbarRect == null) {
      return;
    }

    final trackLength = _yScrollbarRect!.height;
    if (trackLength == 0) return;

    // CRITICAL: Use streaming bounds when available for correct scrollbar interaction
    final double dataMin;
    final double dataMax;
    final streamingBounds = _delegate.streamingBounds;
    if (streamingBounds != null) {
      dataMin = streamingBounds.yMin;
      dataMax = streamingBounds.yMax;
    } else {
      dataMin = originalTransform.dataYMin;
      dataMax = originalTransform.dataYMax;
    }
    final dataSpan = dataMax - dataMin;
    if (dataSpan <= 0) return;

    // Get current viewport range
    final viewportMin = transform.dataYMin;
    final viewportMax = transform.dataYMax;
    final viewportSpan = viewportMax - viewportMin;

    // Convert pixel delta to data delta (natural mapping for Y-axis)
    final dataPerPixel = dataSpan / trackLength;
    final dataDelta =
        pixelDelta * dataPerPixel; // Drag down = move viewport down

    ChartTransform? newTransform;

    // Apply based on interaction type
    switch (interactionType) {
      case ScrollbarInteraction.pan:
        // Pan: shift entire viewport by delta
        var newMin = viewportMin + dataDelta;
        var newMax = viewportMax + dataDelta;

        // Clamp to data bounds
        if (newMin < dataMin) {
          newMin = dataMin;
          newMax = dataMin + viewportSpan;
        }
        if (newMax > dataMax) {
          newMax = dataMax;
          newMin = dataMax - viewportSpan;
        }

        newTransform = transform.copyWith(dataYMin: newMin, dataYMax: newMax);
        break;

      case ScrollbarInteraction.zoomLeftOrTop:
        // Zoom top: adjust minimum boundary only
        var newMin = viewportMin + dataDelta;

        // Clamp to prevent inversion and respect data bounds
        newMin = newMin.clamp(
          dataMin,
          viewportMax - (dataSpan * 0.01),
        ); // Min 1% of data range

        newTransform = transform.copyWith(dataYMin: newMin);
        break;

      case ScrollbarInteraction.zoomRightOrBottom:
        // Zoom bottom: adjust maximum boundary only
        var newMax = viewportMax + dataDelta;

        // Clamp to prevent inversion and respect data bounds
        newMax = newMax.clamp(
          viewportMin + (dataSpan * 0.01),
          dataMax,
        ); // Min 1% of data range

        newTransform = transform.copyWith(dataYMax: newMax);
        break;

      case ScrollbarInteraction.trackClick:
        // Track click: center viewport at clicked position
        final targetDataPosition = dataMin + (pixelDelta * dataPerPixel);
        final halfSpan = viewportSpan / 2;

        var newMin = targetDataPosition - halfSpan;
        var newMax = targetDataPosition + halfSpan;

        // Clamp to data bounds
        if (newMin < dataMin) {
          newMin = dataMin;
          newMax = dataMin + viewportSpan;
        }
        if (newMax > dataMax) {
          newMax = dataMax;
          newMin = dataMax - viewportSpan;
        }

        newTransform = transform.copyWith(dataYMin: newMin, dataYMax: newMax);
        break;

      case ScrollbarInteraction.keyboard:
        // Keyboard: apply delta directly (already calculated by controller)
        var newMin = viewportMin + dataDelta;
        var newMax = viewportMax + dataDelta;

        // Clamp to data bounds
        if (newMin < dataMin) {
          newMin = dataMin;
          newMax = dataMin + viewportSpan;
        }
        if (newMax > dataMax) {
          newMax = dataMax;
          newMin = dataMax - viewportSpan;
        }

        newTransform = transform.copyWith(dataYMin: newMin, dataYMax: newMax);
        break;
    }

    _delegate.applyTransform(newTransform);
    _delegate.updateAxesFromTransform();
    showScrollbarsAndScheduleHide();
  }

  // ==========================================================================
  // Scrollbar Rendering
  // ==========================================================================

  /// Paints scrollbars if enabled.
  ///
  /// Renders horizontal and/or vertical scrollbars using ScrollbarPainter.
  /// Scrollbars show the current viewport range relative to the full data range.
  void paint(Canvas canvas, Size size) {
    final transform = _delegate.transform;
    final originalTransform = _delegate.originalTransform;
    if (transform == null || originalTransform == null) return;

    // Don't render scrollbars when hidden (they shouldn't exist)
    if (!_scrollbarsVisible) return;

    final scrollbarTheme = _scrollbarTheme ?? ScrollbarConfig.defaultLight;

    // Paint horizontal scrollbar (X-axis)
    if (_showXScrollbar && _xScrollbarRect != null) {
      _paintXScrollbar(canvas, transform, originalTransform, scrollbarTheme);
    }

    // Paint vertical scrollbar (Y-axis)
    if (_showYScrollbar && _yScrollbarRect != null) {
      _paintYScrollbar(canvas, transform, originalTransform, scrollbarTheme);
    }
  }

  /// Paints the horizontal (X-axis) scrollbar.
  void _paintXScrollbar(
    Canvas canvas,
    ChartTransform transform,
    ChartTransform originalTransform,
    ScrollbarConfig scrollbarTheme,
  ) {
    // CRITICAL FIX: Use streaming bounds for full data range when available
    // During streaming, _originalTransform may be overwritten by performLayout
    // to match the sliding viewport, but _streamingBounds always has the TRUE
    // full data range (0 to latest point).
    final double dataMin;
    final double dataMax;
    final streamingBounds = _delegate.streamingBounds;
    if (streamingBounds != null) {
      dataMin = streamingBounds.xMin;
      dataMax = streamingBounds.xMax;
    } else {
      dataMin = originalTransform.dataXMin;
      dataMax = originalTransform.dataXMax;
    }

    // Use current transform for viewport range
    final viewportMin = transform.dataXMin;
    final viewportMax = transform.dataXMax;

    final trackLength = _xScrollbarRect!.width;
    final dataSpan = dataMax - dataMin;

    // Guard against zero/negative data span
    if (dataSpan <= 0) return;

    // Calculate handle size as ZOOM LEVEL representation
    // At 100% zoom (all data visible): handle = ~80% of track (no zoom applied)
    // As zoom increases: handle shrinks to show zoomed-in state
    // Example: 200% zoom → handle = 40% of track (showing you're viewing half the data)
    final viewportSpan = viewportMax - viewportMin;
    final visibleRatio = viewportSpan / dataSpan; // Gets smaller as you zoom in
    final handleSize = (visibleRatio * trackLength).clamp(
      scrollbarTheme.minHandleSize,
      trackLength,
    );

    // Calculate handle position (where viewport starts relative to data)
    final viewportOffset = viewportMin - dataMin;
    final handlePosition = (viewportOffset / dataSpan * trackLength).clamp(
      0.0,
      trackLength - handleSize,
    );

    // Calculate zoom-adjusted edge grip width (blue zones grow with zoom level)
    // At 100% zoom (visibleRatio=1.0): edgeGripWidth = base size (e.g., 8px)
    // At 200% zoom (visibleRatio=0.5): edgeGripWidth = 2x base size (e.g., 16px)
    // Formula: zoomFactor = 1 / visibleRatio = dataSpan / viewportSpan
    final zoomFactor = dataSpan / viewportSpan;
    final baseEdgeGripWidth = scrollbarTheme.edgeGripWidth;
    final maxEdgeGripWidth =
        handleSize * 0.4; // Max 40% of handle size to leave center draggable
    final zoomAdjustedEdgeGripWidth = (baseEdgeGripWidth * zoomFactor)
        .clamp(
          math.min(baseEdgeGripWidth, maxEdgeGripWidth), // Ensure min <= max
          maxEdgeGripWidth,
        )
        .toDouble();

    // Create modified scrollbar config with zoom-adjusted edge zones
    final zoomAdjustedConfig = scrollbarTheme.copyWith(
      edgeGripWidth: zoomAdjustedEdgeGripWidth,
    );

    // Create scrollbar state with hover zone for visual feedback
    final state = ScrollbarState(
      handlePosition: handlePosition,
      handleSize: handleSize,
      isDragging: _activeScrollbarAxis == Axis.horizontal,
      hoverZone: _xScrollbarHoverZone,
      isFocused: false,
      isVisible: true,
    );

    // Create painter and render with zoom-adjusted config
    final painter = ScrollbarPainter(
      config: zoomAdjustedConfig,
      state: state,
      isHorizontal: true,
      trackLength: trackLength,
      isTrackHovered: _xScrollbarHoverZone == HitTestZone.track,
      opacity: 1.0,
    );

    canvas.save();
    canvas.translate(_xScrollbarRect!.left, _xScrollbarRect!.top);
    painter.paint(
      canvas,
      Size(_xScrollbarRect!.width, _xScrollbarRect!.height),
    );
    canvas.restore();
  }

  /// Paints the vertical (Y-axis) scrollbar.
  void _paintYScrollbar(
    Canvas canvas,
    ChartTransform transform,
    ChartTransform originalTransform,
    ScrollbarConfig scrollbarTheme,
  ) {
    // Use original transform for full data range
    final dataMin = originalTransform.dataYMin;
    final dataMax = originalTransform.dataYMax;

    // Use current transform for viewport range
    final viewportMin = transform.dataYMin;
    final viewportMax = transform.dataYMax;

    final trackLength = _yScrollbarRect!.height;
    final dataSpan = dataMax - dataMin;

    // Calculate handle size as ZOOM LEVEL representation
    // At 100% zoom (all data visible): handle = ~80% of track (no zoom applied)
    // As zoom increases: handle shrinks to show zoomed-in state
    // Example: 200% zoom → handle = 40% of track (showing you're viewing half the data)
    final viewportSpan = viewportMax - viewportMin;
    final visibleRatio = viewportSpan / dataSpan; // Gets smaller as you zoom in
    final handleSize = (visibleRatio * trackLength).clamp(
      scrollbarTheme.minHandleSize,
      trackLength,
    );

    // Calculate handle position (where viewport starts relative to data)
    // Y-AXIS INVERTED: In chart space, Y increases upward, but in screen space Y increases downward
    // When viewport shows LOWER Y values (bottom of chart), handle should be at TOP of scrollbar
    // When viewport shows HIGHER Y values (top of chart), handle should be at BOTTOM of scrollbar
    // Therefore: use viewportMin (not viewportMax) and NO inversion needed!
    final viewportOffset = viewportMin - dataMin;
    final handlePosition = (viewportOffset / dataSpan * trackLength).clamp(
      0.0,
      trackLength - handleSize,
    );

    // Calculate zoom-adjusted edge grip width (blue zones grow with zoom level)
    // At 100% zoom (visibleRatio=1.0): edgeGripWidth = base size (e.g., 40px)
    // At 200% zoom (visibleRatio=0.5): edgeGripWidth = 2x base size (e.g., 80px)
    // Formula: zoomFactor = 1 / visibleRatio = dataSpan / viewportSpan
    final zoomFactor = dataSpan / viewportSpan;
    final baseEdgeGripWidth = scrollbarTheme.edgeGripWidth;
    final maxEdgeGripWidth =
        handleSize * 0.4; // Max 40% of handle size to leave center draggable
    final zoomAdjustedEdgeGripWidth = (baseEdgeGripWidth * zoomFactor)
        .clamp(
          math.min(baseEdgeGripWidth, maxEdgeGripWidth), // Ensure min <= max
          maxEdgeGripWidth,
        )
        .toDouble();

    // Create modified scrollbar config with zoom-adjusted edge zones
    final zoomAdjustedConfig = scrollbarTheme.copyWith(
      edgeGripWidth: zoomAdjustedEdgeGripWidth,
    );

    // Create scrollbar state with hover zone for visual feedback
    final state = ScrollbarState(
      handlePosition: handlePosition,
      handleSize: handleSize,
      isDragging: _activeScrollbarAxis == Axis.vertical,
      hoverZone: _yScrollbarHoverZone,
      isFocused: false,
      isVisible: true,
    );

    // Create painter and render with zoom-adjusted config
    final painter = ScrollbarPainter(
      config: zoomAdjustedConfig,
      state: state,
      isHorizontal: false,
      trackLength: trackLength,
      isTrackHovered: _yScrollbarHoverZone == HitTestZone.track,
      opacity: 1.0,
    );

    canvas.save();
    canvas.translate(_yScrollbarRect!.left, _yScrollbarRect!.top);
    painter.paint(
      canvas,
      Size(_yScrollbarRect!.width, _yScrollbarRect!.height),
    );
    canvas.restore();
  }

  // ==========================================================================
  // Disposal
  // ==========================================================================

  /// Disposes of timer resources.
  void dispose() {
    _scrollbarAutoHideTimer?.cancel();
    _scrollbarAutoHideTimer = null;
  }
}
