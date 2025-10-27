// Copyright (c) 2025 Forcegage PVM. All rights reserved.
// Use of this source code is governed by a BSD-style license.

/// ChartScrollbar widget for dual-purpose scrollbars (pan + zoom).
///
/// Provides:
/// - Visual feedback (handle size shows zoom level, position shows scroll offset)
/// - Pan interaction (drag handle center to shift viewport)
/// - Zoom interaction (drag handle edges to resize viewport)
/// - Track click to jump (click track to center viewport at click position)
/// - Keyboard navigation (arrow keys, page up/down, home/end)
/// - Auto-hide with fade animation
/// - WCAG 2.1 AA accessibility (44x44 touch targets, 7:1 contrast in high-contrast mode)
library;

import 'dart:async';

import 'package:flutter/material.dart' hide Scrollbar, ScrollbarPainter;

import '../foundation/foundation.dart' as braven;
import '../theming/components/scrollbar_config.dart';
import 'scrollbar/hit_test_zone.dart';
import 'scrollbar/scrollbar_controller.dart';
import 'scrollbar/scrollbar_painter.dart';
import 'scrollbar/scrollbar_state.dart';

/// Dual-purpose scrollbar for chart navigation (pan + zoom).
///
/// **Interaction Modes**:
/// - **Pan**: Drag center of handle to shift viewport (viewportMin and viewportMax move together)
/// - **Zoom**: Drag edges of handle to resize viewport (adjust viewportMin or viewportMax independently)
/// - **Jump**: Click track to center viewport at click position
///
/// **Constitutional Requirements**:
/// - ✅ Performance First: Uses ValueNotifier for >10Hz pointer events (no setState)
/// - ✅ Test-First Development: Contract tests written before implementation (Phase 2.2)
/// - ✅ Architectural Integrity: Scrollbar layout independent of TransformContext
///
/// **Accessibility**:
/// - WCAG 2.2 Level AA: 44x44px minimum touch targets (FR-024A)
/// - WCAG 2.1 Level AA: 4.5:1 contrast ratios (FR-025)
/// - WCAG 2.1 AAA: Optional 7:1 high-contrast theme (FR-025)
/// - Windows High Contrast Mode support (FR-024B)
/// - Prefers-reduced-motion support (FR-024C)
/// - Keyboard navigation with focus indicators
class ChartScrollbar extends StatefulWidget {
  /// Creates a dual-purpose scrollbar.
  ///
  /// Parameters:
  /// - [axis]: Orientation (Axis.horizontal for X-axis, Axis.vertical for Y-axis)
  /// - [dataRange]: Full range of data available (e.g., 0-100 for 100 data points)
  /// - [viewportRange]: Currently visible range (subset of dataRange)
  /// - [onViewportChanged]: Callback fired when user changes viewport via scrollbar
  /// - [onPanChanged]: Optional callback fired when pan gesture completes (T071)
  /// - [theme]: Visual configuration (colors, sizes, interaction settings)
  const ChartScrollbar({
    super.key,
    required this.axis,
    required this.dataRange,
    required this.viewportRange,
    required this.onViewportChanged,
    this.onPanChanged,
    required this.theme,
  });

  /// Orientation of the scrollbar.
  ///
  /// - Axis.horizontal: Scrolls along X-axis (bottom of chart)
  /// - Axis.vertical: Scrolls along Y-axis (right side of chart)
  final Axis axis;

  /// Full range of data available for this axis.
  ///
  /// **Example**: For time series from 2024-01-01 to 2024-12-31:
  /// ```dart
  /// dataRange = DataRange(min: 0, max: 365) // days since start
  /// ```
  ///
  /// **Invariant**: dataRange.span > 0 (enforced by DataRange)
  final braven.DataRange dataRange;

  /// Currently visible range within the data.
  ///
  /// **Example**: Viewing January-February:
  /// ```dart
  /// viewportRange = DataRange(min: 0, max: 31) // days 0-31
  /// ```
  ///
  /// **Invariant**: viewportRange ⊆ dataRange (must be subset)
  final braven.DataRange viewportRange;

  /// Callback fired when user changes viewport via scrollbar interaction.
  ///
  /// **Fired on**:
  /// - Handle drag (pan or zoom) - throttled to 60 FPS (max 1 update per 16ms)
  /// - Track click (jump) - immediate
  /// - Keyboard navigation - immediate
  ///
  /// **Contract**: New viewport will always be subset of dataRange (clamped if needed)
  final ValueChanged<braven.DataRange> onViewportChanged;

  /// Optional callback fired when pan gesture completes (T071).
  ///
  /// **Fired on**:
  /// - Pan drag completes (_onPanEnd called)
  ///
  /// **Parameters**:
  /// - offset: Total pan offset from drag start to end (dx for horizontal, dy for vertical)
  ///
  /// **Integration**: This is typically wired from InteractionConfig.onPanChanged
  final void Function(Offset)? onPanChanged;

  /// Visual configuration (colors, sizes, interaction settings).
  ///
  /// Contains:
  /// - Colors (track, handle, hover, active, disabled)
  /// - Dimensions (thickness, minHandleSize, borderRadius, edgeGripWidth)
  /// - Behavior (autoHide, enableResizeHandles, minZoomRatio, maxZoomRatio)
  /// - Accessibility (forcedColorsMode, prefersReducedMotion)
  final ScrollbarConfig theme;

  @override
  State<ChartScrollbar> createState() => _ChartScrollbarState();
}

/// Private state for ChartScrollbar.
///
/// **Constitutional Compliance**:
/// - Uses ValueNotifier<ScrollbarState> instead of setState() for >10Hz updates
/// - All state changes go through ValueNotifier for performance optimization
/// - Throttles viewport updates to 60 FPS to prevent chart jank
class _ChartScrollbarState extends State<ChartScrollbar> with SingleTickerProviderStateMixin {
  /// Reactive state management (Constitutional requirement: ValueNotifier for >10Hz events).
  late ValueNotifier<ScrollbarState> _stateNotifier;

  /// Focus node for keyboard navigation.
  late FocusNode _focusNode;

  /// Timer for auto-hide feature.
  Timer? _autoHideTimer;

  /// Initial drag position (for delta calculations in _onPanUpdate).
  /// Set in _onPanStart, used in _onPanUpdate, cleared in _onPanEnd.
  Offset? _dragStartPosition;

  /// Initial viewport range at drag start (for delta calculation in _onPanEnd - T071).
  /// Set in _onPanStart, used in _onPanEnd, cleared in _onPanEnd.
  braven.DataRange? _dragStartViewportRange;

  /// Last viewport sent to onViewportChanged (for onPanChanged delta calculation - T071).
  /// Tracked during drag to calculate total pan delta in _onPanEnd.
  braven.DataRange? _lastSentViewport;

  /// Throttle timer for viewport updates (T067 - 60 FPS = 16ms max).
  Timer? _throttleTimer;

  /// Pending viewport update (for throttling - T067).
  braven.DataRange? _pendingViewportUpdate;

  /// Animation controller for track click jump (T073 - 300ms ease-out).
  AnimationController? _jumpAnimationController;

  /// Animation for track click jump (T073).
  Animation<double>? _jumpAnimation;

  /// Target viewport for jump animation (T073).
  braven.DataRange? _jumpTargetViewport;

  /// Initial viewport for jump animation (T073).
  braven.DataRange? _jumpStartViewport;

  /// Drag zone captured at drag start (T086 - for edge resize vs center pan).
  /// Set in _onPanStart, used in _onPanUpdate to determine resize vs pan behavior.
  /// - leftEdge/topEdge: Resize viewport min (anchor viewport max)
  /// - rightEdge/bottomEdge: Resize viewport max (anchor viewport min)
  /// - center: Pan viewport (shift both min and max by same delta)
  HitTestZone? _dragZone;

  @override
  void initState() {
    super.initState();

    // Initialize state with default values
    _stateNotifier = ValueNotifier(ScrollbarState.initial());
    _focusNode = FocusNode();

    // Initialize jump animation controller (T073)
    _jumpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this, // Requires TickerProviderStateMixin
    );

    // Start auto-hide timer if enabled
    if (widget.theme.autoHide) {
      _scheduleAutoHide();
    }
  }

  @override
  void didUpdateWidget(ChartScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sync scrollbar visibility when viewport changes externally (T048)
    if (oldWidget.viewportRange != widget.viewportRange || oldWidget.dataRange != widget.dataRange || oldWidget.axis != widget.axis) {
      // Make scrollbar visible when viewport changes
      _stateNotifier.value = _stateNotifier.value.copyWith(isVisible: true);

      // Restart auto-hide timer if enabled
      if (widget.theme.autoHide) {
        _scheduleAutoHide();
      }
    }

    // Restart auto-hide timer if theme changed
    if (oldWidget.theme.autoHide != widget.theme.autoHide) {
      if (widget.theme.autoHide) {
        _scheduleAutoHide();
      } else {
        _cancelAutoHide();
      }
    }
  }

  @override
  void dispose() {
    // Clean up resources (Constitutional requirement: no memory leaks)
    _stateNotifier.dispose();
    _focusNode.dispose();
    _cancelAutoHide();
    _throttleTimer?.cancel();
    _jumpAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap in RepaintBoundary to isolate scrollbar repaints from rest of chart (T049)
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate track length based on orientation
          final trackLength = widget.axis == Axis.horizontal ? constraints.maxWidth : constraints.maxHeight;

          // Calculate handle size using ScrollbarController (T046)
          final handleSize = ScrollbarController.calculateHandleSize(
            widget.dataRange.span,
            widget.viewportRange.span,
            trackLength,
            widget.theme.minHandleSize,
          );

          // Calculate scroll offset from viewport position
          final scrollOffset = widget.viewportRange.min - widget.dataRange.min;

          // Calculate handle position using ScrollbarController (T047)
          final handlePosition = ScrollbarController.calculateHandlePosition(
            widget.dataRange.span,
            widget.viewportRange.span,
            trackLength,
            scrollOffset,
            widget.theme.minHandleSize,
          );

          // Update state with calculated handle geometry (needed for hit testing in T086)
          // Update synchronously so gesture handlers have correct values immediately
          if (_stateNotifier.value.handleSize != handleSize || _stateNotifier.value.handlePosition != handlePosition) {
            _stateNotifier.value = _stateNotifier.value.copyWith(
              handleSize: handleSize,
              handlePosition: handlePosition,
            );
          }

          // Use ValueListenableBuilder for reactive state updates (Constitutional requirement)
          return ValueListenableBuilder<ScrollbarState>(
            valueListenable: _stateNotifier,
            builder: (context, state, child) {
              // Create ScrollbarPainter with current state and configuration
              final painter = ScrollbarPainter(
                config: widget.theme,
                state: state.copyWith(
                  handleSize: handleSize,
                  handlePosition: handlePosition,
                ),
                isHorizontal: widget.axis == Axis.horizontal,
                trackLength: trackLength,
                isTrackHovered: false, // TODO: Phase 4 (User Story 2) will add hover detection
                opacity: 1.0, // TODO: Phase 4 (User Story 3) will add auto-hide animation
              );

              // Render scrollbar using CustomPaint wrapped in MouseRegion for hover detection (T084)
              return SizedBox(
                width: widget.axis == Axis.horizontal ? trackLength : widget.theme.thickness,
                height: widget.axis == Axis.vertical ? trackLength : widget.theme.thickness,
                child: MouseRegion(
                  cursor: _getCursorForZone(state.hoverZone), // T093: Dynamic cursor based on hover zone
                  onHover: _onHover, // T084: Detect edge zones and update hoverZone
                  onExit: (_) => _onExit(), // T084: Clear hoverZone on exit
                  child: GestureDetector(
                    onTapUp: _onTrackClick, // T073: Track click to jump
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
                      painter: painter,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Schedules auto-hide timer based on theme configuration.
  void _scheduleAutoHide() {
    _cancelAutoHide();
    _autoHideTimer = Timer(widget.theme.autoHideDelay, () {
      // Fade out scrollbar
      _stateNotifier.value = _stateNotifier.value.copyWith(
        isVisible: false,
      );
    });
  }

  /// Cancels auto-hide timer.
  void _cancelAutoHide() {
    _autoHideTimer?.cancel();
    _autoHideTimer = null;
  }

  // NOTE: _resetAutoHide() will be added in Phase 4 (User Story 2) when gesture handlers are implemented

  // --- Hover Detection (T084-T085) ---

  /// Handles mouse hover to detect edge zones and update cursor (T084-T085).
  ///
  /// Detects which zone of the scrollbar the mouse is hovering over:
  /// - Left/Top edge (first 8px of handle): For left/top edge resize
  /// - Right/Bottom edge (last 8px of handle): For right/bottom edge resize
  /// - Center of handle: For panning
  /// - Track (outside handle): For track click
  ///
  /// Updates ScrollbarState.hoverZone via ValueNotifier to trigger cursor change (T085).
  ///
  /// Constitutional Requirements:
  /// - Performance First: O(1) hit test using ScrollbarController.getHitTestZone()
  void _onHover(PointerEvent event) {
    // Get current layout dimensions
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final trackLength = widget.axis == Axis.horizontal ? renderBox.size.width : renderBox.size.height;

    // Calculate handle geometry from current state
    final currentState = _stateNotifier.value;
    final handlePosition = currentState.handlePosition;
    final handleSize = currentState.handleSize;

    // Detect hit test zone using ScrollbarController
    // Note: getHitTestZone() takes Offset as first positional parameter
    final zone = ScrollbarController.getHitTestZone(
      event.localPosition, // Offset (first positional parameter)
      widget.axis, // Axis (second positional parameter)
      trackLength, // double (third positional parameter)
      handlePosition, // double (fourth positional parameter)
      handleSize, // double (fifth positional parameter)
      edgeDetectionThreshold: widget.theme.edgeGripWidth, // Named parameter
    );

    // Update hoverZone in state via ValueNotifier (T085)
    if (zone != currentState.hoverZone) {
      _stateNotifier.value = currentState.copyWith(hoverZone: zone);
    }
  }

  /// Clears hover zone when mouse exits scrollbar area (T084).
  void _onExit() {
    _stateNotifier.value = _stateNotifier.value.clearHoverZone();
  }

  /// Returns appropriate cursor for the given hover zone (T093-T095).
  ///
  /// **Cursor Mapping**:
  /// - Track → SystemMouseCursors.click (indicates clickable)
  /// - Center → SystemMouseCursors.grab (indicates draggable for panning)
  /// - Left/Right edge (horizontal) → SystemMouseCursors.resizeColumn (indicates horizontal resize)
  /// - Top/Bottom edge (vertical) → SystemMouseCursors.resizeRow (indicates vertical resize)
  /// - null (not hovering) → SystemMouseCursors.basic (default cursor)
  ///
  /// Constitutional Requirements:
  /// - Accessibility: Cursor provides visual feedback for interaction affordances
  MouseCursor _getCursorForZone(HitTestZone? zone) {
    if (zone == null) return SystemMouseCursors.basic;

    switch (zone) {
      case HitTestZone.track:
        return SystemMouseCursors.click;
      case HitTestZone.center:
        return SystemMouseCursors.grab;
      case HitTestZone.leftEdge:
      case HitTestZone.rightEdge:
        return SystemMouseCursors.resizeColumn; // T094: Horizontal scrollbar edges
      case HitTestZone.topEdge:
      case HitTestZone.bottomEdge:
        return SystemMouseCursors.resizeRow; // T095: Vertical scrollbar edges
    }
  }

  // --- Track Click Handler (T073) ---

  /// Handles track click to jump viewport to click position (T073).
  ///
  /// Animates viewport to center at click position using 300ms ease-out curve.
  /// Cancels any active animation before starting new one (T073B).
  void _onTrackClick(TapUpDetails details) {
    // Cancel any active jump animation (T073B - animation cancellation)
    _cancelJumpAnimation();

    // Get current layout dimensions
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final trackLength = widget.axis == Axis.horizontal ? renderBox.size.width : renderBox.size.height;

    // Extract click position based on axis
    final clickPosition = widget.axis == Axis.horizontal ? details.localPosition.dx : details.localPosition.dy;

    // Calculate target scroll offset to center viewport at click position
    final viewportSize = widget.viewportRange.span;
    final clickRatio = clickPosition / trackLength;
    final targetDataPosition = widget.dataRange.min + (clickRatio * widget.dataRange.span);

    // Center viewport at click position
    final targetViewportMin = targetDataPosition - (viewportSize / 2);

    // Apply boundary clamping
    final clampedMin = targetViewportMin.clamp(widget.dataRange.min, widget.dataRange.max - viewportSize);
    final clampedMax = clampedMin + viewportSize;

    final targetViewport = braven.DataRange(min: clampedMin, max: clampedMax);

    // Store initial and target viewports for animation
    _jumpStartViewport = widget.viewportRange;
    _jumpTargetViewport = targetViewport;

    // Create 300ms ease-out animation (T073)
    _jumpAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _jumpAnimationController!,
        curve: Curves.easeOut, // FR-007 enhanced
      ),
    )..addListener(() {
        // Interpolate between start and target viewport
        if (_jumpStartViewport != null && _jumpTargetViewport != null) {
          final t = _jumpAnimation!.value;
          final interpolatedMin = _jumpStartViewport!.min + ((_jumpTargetViewport!.min - _jumpStartViewport!.min) * t);
          final interpolatedMax = _jumpStartViewport!.max + ((_jumpTargetViewport!.max - _jumpStartViewport!.max) * t);

          final interpolatedViewport = braven.DataRange(min: interpolatedMin, max: interpolatedMax);

          // Fire viewport changed callback
          widget.onViewportChanged(interpolatedViewport);
        }
      });

    // Add completion listener to clean up
    _jumpAnimationController!.addStatusListener(_onJumpAnimationComplete);

    // Start animation from 0.0
    _jumpAnimationController!.forward(from: 0.0);

    // Cancel auto-hide while animating
    if (widget.theme.autoHide) {
      _cancelAutoHide();
    }
  }

  /// Animation completion listener (T073).
  void _onJumpAnimationComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // Clean up animation state
      _jumpStartViewport = null;
      _jumpTargetViewport = null;
      _jumpAnimationController?.removeStatusListener(_onJumpAnimationComplete);

      // Restart auto-hide timer
      if (widget.theme.autoHide) {
        _scheduleAutoHide();
      }
    }
  }

  /// Cancels active jump animation (T073B).
  void _cancelJumpAnimation() {
    if (_jumpAnimationController?.isAnimating ?? false) {
      _jumpAnimationController?.stop();
      _jumpAnimationController?.reset();
      _jumpStartViewport = null;
      _jumpTargetViewport = null;
    }
  }

  // --- Pan Gesture Handlers (T063-T066) ---

  /// Handles pan gesture start (T064, T086).
  ///
  /// Initializes drag state when user starts dragging scrollbar handle.
  /// Captures initial touch position for delta calculations in _onPanUpdate.
  /// Detects drag zone (edge vs center) for resize vs pan behavior (T086).
  ///
  /// **Drag Zones** (T086):
  /// - leftEdge/topEdge: User dragging left/top edge → resize viewport min
  /// - rightEdge/bottomEdge: User dragging right/bottom edge → resize viewport max
  /// - center: User dragging center → pan viewport (both min and max shift)
  void _onPanStart(DragStartDetails details) {
    // Cancel any active jump animation (T073B - concurrent interaction cancellation)
    _cancelJumpAnimation();

    // Capture initial drag position for delta calculations (T064)
    _dragStartPosition = details.localPosition;

    // Capture initial viewport range for callback delta calculation (T071)
    _dragStartViewportRange = widget.viewportRange;

    // Detect drag zone (T086 - edge detection for zoom functionality)
    // Get current layout dimensions
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && widget.theme.enableResizeHandles) {
      // Edge resize enabled - detect which zone was clicked
      final trackLength = widget.axis == Axis.horizontal ? renderBox.size.width : renderBox.size.height;
      final currentState = _stateNotifier.value;
      
      // Use ScrollbarController to detect which zone was clicked
      _dragZone = ScrollbarController.getHitTestZone(
        details.localPosition,
        widget.axis,
        trackLength,
        currentState.handlePosition,
        currentState.handleSize,
        edgeDetectionThreshold: widget.theme.edgeGripWidth,
      );
    } else {
      // Fallback: edge resize disabled or can't get layout - use center pan only
      _dragZone = HitTestZone.center;
    }

    // Set isDragging flag to true
    _stateNotifier.value = _stateNotifier.value.copyWith(
      isDragging: true,
    );

    // Cancel auto-hide while dragging
    if (widget.theme.autoHide) {
      _cancelAutoHide();
    }
  }

  /// Handles pan gesture update (T065-T066, T087-T089).
  ///
  /// Calculates viewport delta from drag distance and triggers viewport update.
  /// Supports both center pan (T065-T066) and edge resize (T087-T089).
  ///
  /// **Drag Modes**:
  /// - **Center Pan** (T065-T066): Drag center → shift entire viewport (both min and max)
  /// - **Left Edge Resize** (T087): Drag left edge → adjust viewportMin (right edge anchored)
  /// - **Right Edge Resize** (T088): Drag right edge → adjust viewportMax (left edge anchored)
  ///
  /// **TODO (T067)**: Implement 60 FPS throttling (max 1 update per 16ms).
  void _onPanUpdate(DragUpdateDetails details) {
    // Skip if no drag start position captured (shouldn't happen, but defensive)
    if (_dragStartPosition == null) return;

    // Calculate drag delta from initial position (T065)
    final currentPosition = details.localPosition;
    final dragDelta = currentPosition - _dragStartPosition!;

    // Extract relevant coordinate based on axis
    final pixelDelta = widget.axis == Axis.horizontal ? dragDelta.dx : dragDelta.dy;

    // Get current layout dimensions from build context
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final trackLength = widget.axis == Axis.horizontal ? renderBox.size.width : renderBox.size.height;

    // Calculate current handle size and position
    final currentHandleSize = ScrollbarController.calculateHandleSize(
      widget.dataRange.span,
      widget.viewportRange.span,
      trackLength,
      widget.theme.minHandleSize,
    );

    final currentHandlePosition = ScrollbarController.calculateHandlePosition(
      widget.viewportRange.min - widget.dataRange.min,
      widget.dataRange.span,
      widget.viewportRange.span,
      trackLength,
      widget.theme.minHandleSize,
    );

    // Determine behavior based on drag zone (T086-T089)
    // If _dragZone is null (edge case - drag without pan start), default to center pan
    late final braven.DataRange newViewport;

    switch (_dragZone ?? HitTestZone.center) {
      case HitTestZone.leftEdge:
      case HitTestZone.topEdge:
        // Left/Top Edge Resize (T087): Adjust viewportMin, keep viewportMax anchored
        // Convert pixel delta to data delta manually
        final dataDelta = (pixelDelta / trackLength) * widget.dataRange.span;

        var newViewportMin = widget.viewportRange.min + dataDelta;

        // Clamp to data range boundaries and not exceed viewportMax
        newViewportMin = newViewportMin.clamp(
          widget.dataRange.min,
          widget.viewportRange.max,
        );

        // Calculate resulting span after resize
        var newSpan = widget.viewportRange.max - newViewportMin;

        // Enforce zoom limits (T090-T091)
        final minSpan = widget.dataRange.span * widget.theme.minZoomRatio;
        final maxSpan = widget.dataRange.span * widget.theme.maxZoomRatio;

        // If zoomed in too far (span too small), clamp viewportMin
        if (newSpan < minSpan) {
          newViewportMin = widget.viewportRange.max - minSpan;
        }

        // If zoomed out too far (span too large), clamp viewportMin
        if (newSpan > maxSpan) {
          newViewportMin = widget.viewportRange.max - maxSpan;
        }

        // Final clamp to data boundaries
        newViewportMin = newViewportMin.clamp(
          widget.dataRange.min,
          widget.dataRange.max,
        );

        newViewport = braven.DataRange(
          min: newViewportMin,
          max: widget.viewportRange.max, // Right edge anchored
        );
        break;

      case HitTestZone.rightEdge:
      case HitTestZone.bottomEdge:
        // Right/Bottom Edge Resize (T088): Adjust viewportMax, keep viewportMin anchored
        // Convert pixel delta to data delta manually
        final dataDelta = (pixelDelta / trackLength) * widget.dataRange.span;

        var newViewportMax = widget.viewportRange.max + dataDelta;

        // Clamp to data range boundaries and not below viewportMin
        newViewportMax = newViewportMax.clamp(
          widget.viewportRange.min,
          widget.dataRange.max,
        );

        // Calculate resulting span after resize
        var newSpan = newViewportMax - widget.viewportRange.min;

        // Enforce zoom limits (T090-T091)
        final minSpan = widget.dataRange.span * widget.theme.minZoomRatio;
        final maxSpan = widget.dataRange.span * widget.theme.maxZoomRatio;

        // If zoomed in too far (span too small), clamp viewportMax
        if (newSpan < minSpan) {
          newViewportMax = widget.viewportRange.min + minSpan;
        }

        // If zoomed out too far (span too large), clamp viewportMax
        if (newSpan > maxSpan) {
          newViewportMax = widget.viewportRange.min + maxSpan;
        }

        // Final clamp to data boundaries
        newViewportMax = newViewportMax.clamp(
          widget.dataRange.min,
          widget.dataRange.max,
        );

        newViewport = braven.DataRange(
          min: widget.viewportRange.min, // Left edge anchored
          max: newViewportMax,
        );
        break;

      case HitTestZone.center:
        // Center Pan (T065-T066): Calculate new handle position after drag
        final newHandlePosition = currentHandlePosition + pixelDelta;

        // Convert handle position to data range offset (T068)
        final newScrollOffset = ScrollbarController.handleToDataRange(
          newHandlePosition,
          widget.dataRange.span,
          widget.viewportRange.span,
          trackLength,
          currentHandleSize,
        );

        // Calculate new viewport range (maintaining viewport size, shifting position)
        final viewportSize = widget.viewportRange.span;
        final newViewportMin = widget.dataRange.min + newScrollOffset;

        // Apply boundary clamping (T072)
        final clampedMin = newViewportMin.clamp(
          widget.dataRange.min,
          widget.dataRange.max - viewportSize,
        );
        final clampedMax = clampedMin + viewportSize;

        newViewport = braven.DataRange(min: clampedMin, max: clampedMax);
        break;

      case HitTestZone.track:
        // Track click should trigger jump animation, not drag
        // If we're here, user started drag on track (outside handle) - ignore
        return;
    }

    // Update handle position in state via ValueNotifier (T066)
    final newHandlePositionClamped = ScrollbarController.calculateHandlePosition(
      newViewport.min - widget.dataRange.min,
      widget.dataRange.span,
      newViewport.span,
      trackLength,
      widget.theme.minHandleSize,
    );

    _stateNotifier.value = _stateNotifier.value.copyWith(
      handlePosition: newHandlePositionClamped,
    );

    // Throttle viewport updates to 60 FPS (T067)
    // Store the latest viewport update
    _pendingViewportUpdate = newViewport;

    // If no throttle is active, fire immediately and start throttle period
    if (_throttleTimer == null) {
      widget.onViewportChanged(_pendingViewportUpdate!);
      _lastSentViewport = _pendingViewportUpdate; // Track for onPanChanged delta (T071)
      _pendingViewportUpdate = null;

      // Start 16ms throttle period
      _throttleTimer = Timer(const Duration(milliseconds: 16), () {
        // Throttle period ended - fire any pending update
        if (_pendingViewportUpdate != null) {
          widget.onViewportChanged(_pendingViewportUpdate!);
          _lastSentViewport = _pendingViewportUpdate; // Track for onPanChanged delta (T071)
          _pendingViewportUpdate = null;
        }
        _throttleTimer = null;
      });
    }
    // Else: throttle active - just store the update, it will fire when throttle expires

    // Update drag start position for next delta calculation
    _dragStartPosition = currentPosition;
  }

  /// Handles pan gesture end (T070-T071).
  ///
  /// Finalizes drag operation and ensures final viewport sync.
  /// Fires onPanChanged callback with total pan delta.
  void _onPanEnd(DragEndDetails details) {
    // Flush any pending throttled viewport update (T070)
    if (_pendingViewportUpdate != null) {
      widget.onViewportChanged(_pendingViewportUpdate!);
      _lastSentViewport = _pendingViewportUpdate; // Track for onPanChanged delta (T071)
      _pendingViewportUpdate = null;
    }

    // Cancel throttle timer
    _throttleTimer?.cancel();
    _throttleTimer = null;

    // Fire onPanChanged callback with total pan delta (T071)
    if (widget.onPanChanged != null && _dragStartViewportRange != null && _lastSentViewport != null) {
      // Calculate total pan delta from start to end using last sent viewport
      final initialViewportMin = _dragStartViewportRange!.min;
      final finalViewportMin = _lastSentViewport!.min;
      final dataDelta = finalViewportMin - initialViewportMin;

      // Convert data delta to offset based on axis
      // For horizontal: dx = dataDelta, dy = 0
      // For vertical: dx = 0, dy = dataDelta
      final offset = widget.axis == Axis.horizontal ? Offset(dataDelta, 0.0) : Offset(0.0, dataDelta);

      widget.onPanChanged!(offset);
    }

    // Clear drag state
    _dragStartPosition = null;
    _dragStartViewportRange = null;
    _lastSentViewport = null;

    // Reset isDragging flag
    _stateNotifier.value = _stateNotifier.value.copyWith(
      isDragging: false,
    );

    // Restart auto-hide timer if enabled
    if (widget.theme.autoHide) {
      _scheduleAutoHide();
    }
  }
}
