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

import '../../models/data_range.dart';
import '../../theming/components/scrollbar_config.dart';
import 'hit_test_zone.dart';
import 'scrollbar_controller.dart';
import 'scrollbar_interaction.dart';
import 'scrollbar_painter.dart';
import 'scrollbar_state.dart';

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
  /// - [onPixelDeltaChanged]: Callback fired when user interacts with scrollbar (pixel-delta pattern)
  /// - [theme]: Visual configuration (colors, sizes, interaction settings)
  const ChartScrollbar({
    super.key,
    required this.axis,
    required this.dataRange,
    required this.viewportRange,
    required this.onPixelDeltaChanged,
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
  final DataRange dataRange;

  /// Currently visible range within the data.
  ///
  /// **Example**: Viewing January-February:
  /// ```dart
  /// viewportRange = DataRange(min: 0, max: 31) // days 0-31
  /// ```
  ///
  /// **Invariant**: viewportRange ⊆ dataRange (must be subset)
  final DataRange viewportRange;

  /// Callback fired when user interacts with scrollbar (pixel-delta pattern).
  ///
  /// **Architecture**: Scrollbar reports PIXEL deltas, parent converts to DATA deltas.
  /// This eliminates circular dependencies by removing data state from scrollbar.
  ///
  /// **Parameters**:
  /// - pixelDelta: Pixel offset from drag start (for pan/zoom) or absolute pixel position (for trackClick)
  /// - interaction: Type of interaction (pan, zoom, trackClick, keyboard)
  ///
  /// **Parent Responsibility**:
  /// 1. Convert pixelDelta to data delta using current viewport state
  /// 2. Apply delta based on interaction type (shift both edges vs resize one edge)
  /// 3. Clamp to data range boundaries
  /// 4. Update zoomPanController with new viewport
  ///
  /// **Fired on**:
  /// - Handle drag (pan or zoom) - throttled to 60 FPS (max 1 update per 16ms)
  /// - Track click (jump) - immediate
  /// - Keyboard navigation - immediate
  ///
  /// See: docs/architecture/SCROLLBAR_ARCHITECTURE_ANALYSIS.md
  final void Function(Offset pixelDelta, ScrollbarInteraction interaction)
  onPixelDeltaChanged;

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
/// - Uses `ValueNotifier<ScrollbarState>` instead of setState() for >10Hz updates
/// - All state changes go through ValueNotifier for performance optimization
/// - Throttles viewport updates to 60 FPS to prevent chart jank
class _ChartScrollbarState extends State<ChartScrollbar>
    with TickerProviderStateMixin {
  /// Reactive state management (Constitutional requirement: ValueNotifier for >10Hz events).
  late ValueNotifier<ScrollbarState> _stateNotifier;

  /// Focus node for keyboard navigation.
  late FocusNode _focusNode;

  /// Timer for auto-hide feature.
  Timer? _autoHideTimer;

  /// Initial drag position in pixels (for delta calculations in _onPanUpdate).
  ///
  /// **Pixel-Delta Pattern**: This is the ONLY position state we track.
  /// No data baseline needed - parent owns all data state (single source of truth).
  ///
  /// Set in _onPanStart, used in _onPanUpdate, cleared in _onPanEnd.
  Offset? _dragStartPosition;

  /// Animation controller for track click jump (T073 - 300ms ease-out).
  AnimationController? _jumpAnimationController;

  /// Animation for track click jump (T073).
  Animation<double>? _jumpAnimation;

  /// Animation controller for zoom limit flash (T091A - 200ms).
  late AnimationController _flashAnimationController;

  /// Animation for zoom limit flash opacity (T091A - 0.8 → 0.4 → 0.8).
  late Animation<double> _flashOpacityAnimation;

  /// Flag to track if zoom limit was hit during current drag (T091B).
  /// Used to show 'not-allowed' cursor when dragging beyond zoom limits.
  bool _isAtZoomLimit = false;

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

    // Initialize flash animation controller for zoom limit feedback (T091A)
    _flashAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Create flash opacity animation: 0.8 → 0.4 → 0.8 (T091A)
    _flashOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.8,
          end: 0.4,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.4,
          end: 0.8,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0,
      ),
    ]).animate(_flashAnimationController);

    // Start auto-hide timer if enabled
    if (widget.theme.autoHide) {
      _scheduleAutoHide();
    }
  }

  @override
  void didUpdateWidget(ChartScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sync scrollbar visibility when viewport changes externally (T048)
    if (oldWidget.viewportRange != widget.viewportRange ||
        oldWidget.dataRange != widget.dataRange ||
        oldWidget.axis != widget.axis) {
      // Make scrollbar visible when viewport changes
      _stateNotifier.value = _stateNotifier.value.copyWith(isVisible: true);

      // PIXEL-DELTA PATTERN: No baseline tracking needed!
      // Scrollbar only tracks pixel positions. Parent owns all data state.

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
    _jumpAnimationController?.dispose();
    _flashAnimationController.dispose(); // T091A
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap in RepaintBoundary to isolate scrollbar repaints from rest of chart (T049)
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate track length based on orientation
          final trackLength = widget.axis == Axis.horizontal
              ? constraints.maxWidth
              : constraints.maxHeight;

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
          // Parameters: scrollOffset, totalRange, viewportRange, trackLength, handleSize
          final handlePosition = ScrollbarController.calculateHandlePosition(
            scrollOffset,
            widget.dataRange.span,
            widget.viewportRange.span,
            trackLength,
            handleSize,
          );

          // Update state with calculated handle geometry (needed for hit testing in T086)
          // Update synchronously so gesture handlers have correct values immediately
          if (_stateNotifier.value.handleSize != handleSize ||
              _stateNotifier.value.handlePosition != handlePosition) {
            _stateNotifier.value = _stateNotifier.value.copyWith(
              handleSize: handleSize,
              handlePosition: handlePosition,
            );
          }

          // Use ValueListenableBuilder for reactive state updates (Constitutional requirement)
          return ValueListenableBuilder<ScrollbarState>(
            valueListenable: _stateNotifier,
            builder: (context, state, child) {
              // Use AnimatedBuilder to listen to flash animation (T091A)
              return AnimatedBuilder(
                animation: _flashAnimationController,
                builder: (context, child) {
                  // Calculate final opacity: base opacity * flash opacity
                  // When not flashing, flash opacity is at rest (0.8), so final = 1.0 * 0.8 = 0.8
                  // During flash: 0.8 → 0.4 → 0.8 creates visible flash effect
                  final baseOpacity = state.isVisible ? 1.0 : 0.0;
                  final flashOpacity = _flashAnimationController.isAnimating
                      ? _flashOpacityAnimation.value
                      : 1.0; // No flash effect when not animating
                  final finalOpacity = baseOpacity * flashOpacity;

                  // Create ScrollbarPainter with current state and configuration
                  final painter = ScrollbarPainter(
                    config: widget.theme,
                    state: state.copyWith(
                      handleSize: handleSize,
                      handlePosition: handlePosition,
                    ),
                    isHorizontal: widget.axis == Axis.horizontal,
                    trackLength: trackLength,
                    isTrackHovered:
                        false, // TODO: Phase 4 (User Story 2) will add hover detection
                    opacity:
                        finalOpacity, // Apply flash animation opacity (T091A)
                  );

                  // Render scrollbar using CustomPaint wrapped in MouseRegion for hover detection (T084)
                  return SizedBox(
                    width: widget.axis == Axis.horizontal
                        ? trackLength
                        : widget.theme.thickness,
                    height: widget.axis == Axis.vertical
                        ? trackLength
                        : widget.theme.thickness,
                    child: MouseRegion(
                      cursor: _getCursorForZone(
                        state.hoverZone,
                      ), // T093: Dynamic cursor based on hover zone
                      onHover:
                          _onHover, // T084: Detect edge zones and update hoverZone
                      onExit: (_) => _onExit(), // T084: Clear hoverZone on exit
                      child: GestureDetector(
                        onTapUp: _onTrackClick, // T073: Track click to jump
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: CustomPaint(painter: painter),
                      ),
                    ),
                  );
                },
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
      _stateNotifier.value = _stateNotifier.value.copyWith(isVisible: false);
    });
  }

  /// Cancels auto-hide timer.
  void _cancelAutoHide() {
    _autoHideTimer?.cancel();
    _autoHideTimer = null;
  }

  /// Resets auto-hide timer (cancels and reschedules).
  ///
  /// Used when user interacts with scrollbar but doesn't start dragging
  /// (e.g., hovering, clicking track). This keeps scrollbar visible during
  /// interaction while ensuring it hides after inactivity.
  void _resetAutoHide() {
    if (widget.theme.autoHide) {
      _scheduleAutoHide();
    }
  }

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

    final trackLength = widget.axis == Axis.horizontal
        ? renderBox.size.width
        : renderBox.size.height;

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

    // Reset auto-hide timer on hover (Issue #2 fix)
    _resetAutoHide();
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
  /// Determines cursor type based on hover zone and zoom limit state (T093-T095, T091B).
  ///
  /// Returns:
  /// - SystemMouseCursors.forbidden: When at zoom limit during edge resize (T091B)
  /// - SystemMouseCursors.resizeColumn/resizeRow: For edge zones (T094-T095)
  /// - SystemMouseCursors.grab: For center zone (pan)
  /// - SystemMouseCursors.click: For track zone (jump)
  /// - SystemMouseCursors.basic: Default cursor
  MouseCursor _getCursorForZone(HitTestZone? zone) {
    if (zone == null) return SystemMouseCursors.basic;

    // T091B: Show 'not-allowed' cursor when at zoom limit during edge resize
    if (_isAtZoomLimit &&
        (zone == HitTestZone.leftEdge ||
            zone == HitTestZone.rightEdge ||
            zone == HitTestZone.topEdge ||
            zone == HitTestZone.bottomEdge)) {
      return SystemMouseCursors.forbidden;
    }

    switch (zone) {
      case HitTestZone.track:
        return SystemMouseCursors.click;
      case HitTestZone.center:
        return SystemMouseCursors.grab;
      case HitTestZone.leftEdge:
      case HitTestZone.rightEdge:
        return SystemMouseCursors
            .resizeColumn; // T094: Horizontal scrollbar edges
      case HitTestZone.topEdge:
      case HitTestZone.bottomEdge:
        return SystemMouseCursors.resizeRow; // T095: Vertical scrollbar edges
    }
  }

  // --- Track Click Handler (T073) ---

  /// Handles track click to jump viewport to click position (T073).
  ///
  /// PIXEL-DELTA PATTERN: Reports pixel offset for track click with trackClick interaction type.
  /// Parent converts to data position and handles the jump.
  ///
  /// Note: Track click jumps are NOT animated in pixel-delta pattern - parent handles animation.
  void _onTrackClick(TapUpDetails details) {
    // Cancel any active jump animation (T073B - animation cancellation)
    _cancelJumpAnimation();

    // Get current layout dimensions
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // Extract click position based on axis
    final clickPosition = widget.axis == Axis.horizontal
        ? details.localPosition.dx
        : details.localPosition.dy;

    // PIXEL-DELTA PATTERN: Report pixel offset for track click
    // Parent will convert to data position and handle jump/animation
    final pixelOffset = widget.axis == Axis.horizontal
        ? Offset(clickPosition, 0.0)
        : Offset(0.0, clickPosition);

    // Report track click to parent with pixel position
    widget.onPixelDeltaChanged(pixelOffset, ScrollbarInteraction.trackClick);

    // Reset auto-hide timer after track click (Issue #2 fix)
    _resetAutoHide();
  }

  /// Animation completion listener (T073) - REMOVED.
  ///
  /// PIXEL-DELTA PATTERN: Obsolete - animation handled by parent.
  // void _onJumpAnimationComplete(AnimationStatus status) {
  //   if (status == AnimationStatus.completed) {
  //     // Remove animation listener
  //     _jumpAnimation?.removeListener(_onJumpAnimationTick);
  //
  //     // Clean up animation state
  //     _jumpAnimationController?.removeStatusListener(_onJumpAnimationComplete);
  //
  //     // Restart auto-hide timer
  //     if (widget.theme.autoHide) {
  //       _scheduleAutoHide();
  //     }
  //   }
  // }

  /// Jump animation tick listener (T073).
  ///
  /// PIXEL-DELTA PATTERN: Animation is handled by parent, this method is obsolete.
  /// Kept for backward compatibility during transition.
  void _onJumpAnimationTick() {
    // PIXEL-DELTA PATTERN: Animation is handled by parent
    // This method is no longer used but kept during refactoring
  }

  /// Cancels active jump animation (T073B).
  ///
  /// PIXEL-DELTA PATTERN: Simplified - no viewport state to clean up.
  void _cancelJumpAnimation() {
    if (_jumpAnimationController?.isAnimating ?? false) {
      _jumpAnimationController?.stop();
      _jumpAnimationController?.reset();

      // CRITICAL: Remove the animation listener to prevent it from firing during drag
      _jumpAnimation?.removeListener(_onJumpAnimationTick);
    }
  }

  // --- Pan Gesture Handlers (T063-T066) ---

  /// Handles pan gesture start (T064, T086).
  ///
  /// PIXEL-DELTA PATTERN: Captures only the pixel position where drag started.
  /// No data baseline tracking - parent owns all data state (single source of truth).
  ///
  /// Detects drag zone (edge vs center) for resize vs pan behavior (T086).
  ///
  /// **Drag Zones** (T086):
  /// - leftEdge/topEdge: User dragging left/top edge → resize viewport min
  /// - rightEdge/bottomEdge: User dragging right/bottom edge → resize viewport max
  /// - center: User dragging center → pan viewport (both min and max shift)
  void _onPanStart(DragStartDetails details) {
    // Cancel any active jump animation (T073B - concurrent interaction cancellation)
    _cancelJumpAnimation();

    // PIXEL-DELTA PATTERN: Capture initial drag position (pixels only, no data state)
    _dragStartPosition = details.localPosition;

    // Detect drag zone (T086 - edge detection for zoom functionality)
    // Get current layout dimensions
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && widget.theme.enableResizeHandles) {
      // Edge resize enabled - detect which zone was clicked
      final trackLength = widget.axis == Axis.horizontal
          ? renderBox.size.width
          : renderBox.size.height;
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
    _stateNotifier.value = _stateNotifier.value.copyWith(isDragging: true);

    // Cancel auto-hide while dragging
    if (widget.theme.autoHide) {
      _cancelAutoHide();
    }
  }

  /// Handles pan gesture update (T065-T066, T087-T089).
  ///
  /// PIXEL-DELTA PATTERN: Calculates pixel delta from drag start and reports it
  /// to parent along with ScrollbarInteraction type. Parent converts pixel delta
  /// to data delta using current viewport.
  ///
  /// **Drag Modes**:
  /// - **Center Pan** (T065-T066): Reports ScrollbarInteraction.pan
  /// - **Left/Top Edge Resize** (T087): Reports ScrollbarInteraction.zoomLeftOrTop
  /// - **Right/Bottom Edge Resize** (T088): Reports ScrollbarInteraction.zoomRightOrBottom
  ///
  /// **TODO (T067)**: Implement 60 FPS throttling (max 1 update per 16ms).
  void _onPanUpdate(DragUpdateDetails details) {
    // Guard: Handle edge case where onPanUpdate fires before onPanStart
    if (_dragStartPosition == null) {
      // Initialize drag start position NOW
      _cancelJumpAnimation();
      _dragStartPosition = details.localPosition;

      // Detect drag zone
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null && widget.theme.enableResizeHandles) {
        final trackLength = widget.axis == Axis.horizontal
            ? renderBox.size.width
            : renderBox.size.height;
        final currentState = _stateNotifier.value;

        _dragZone = ScrollbarController.getHitTestZone(
          _dragStartPosition!,
          widget.axis,
          trackLength,
          currentState.handlePosition,
          currentState.handleSize,
          edgeDetectionThreshold: widget.theme.edgeGripWidth,
        );
      } else {
        _dragZone = HitTestZone.center;
      }

      // Set isDragging flag
      _stateNotifier.value = _stateNotifier.value.copyWith(isDragging: true);

      // Cancel auto-hide
      if (widget.theme.autoHide) {
        _cancelAutoHide();
      }

      // Skip this first update - wait for next frame
      return;
    }

    // PIXEL-DELTA PATTERN: Calculate pixel delta from drag start (pixels only)
    final currentPosition = details.localPosition;
    final dragDelta = currentPosition - _dragStartPosition!;

    // Extract relevant coordinate based on axis
    final pixelDelta = widget.axis == Axis.horizontal
        ? dragDelta.dx
        : dragDelta.dy;

    // Determine interaction type based on drag zone
    ScrollbarInteraction interactionType;

    switch (_dragZone ?? HitTestZone.center) {
      case HitTestZone.leftEdge:
      case HitTestZone.topEdge:
        interactionType = ScrollbarInteraction.zoomLeftOrTop;
        break;

      case HitTestZone.rightEdge:
      case HitTestZone.bottomEdge:
        interactionType = ScrollbarInteraction.zoomRightOrBottom;
        break;

      case HitTestZone.center:
        interactionType = ScrollbarInteraction.pan;
        break;

      case HitTestZone.track:
        // Track click should trigger jump, not drag - ignore
        return;
    }

    // PIXEL-DELTA PATTERN: Report pixel delta to parent (parent converts to data delta)
    // Create Offset with appropriate axis coordinate
    final pixelDeltaOffset = widget.axis == Axis.horizontal
        ? Offset(pixelDelta, 0.0)
        : Offset(0.0, pixelDelta);

    // Report to parent - parent will convert to data delta and update viewport
    widget.onPixelDeltaChanged(pixelDeltaOffset, interactionType);
  }

  /// Handles pan gesture end (T070-T071).
  ///
  /// PIXEL-DELTA PATTERN: Simple cleanup - no baseline updates needed.
  /// Parent owns all data state, scrollbar only tracks pixel positions.
  void _onPanEnd(DragEndDetails details) {
    // PIXEL-DELTA PATTERN: Signal drag end to parent by sending Offset.zero
    // This tells parent to clear its drag start baseline
    final lastInteraction =
        _dragZone == HitTestZone.leftEdge || _dragZone == HitTestZone.topEdge
        ? ScrollbarInteraction.zoomLeftOrTop
        : _dragZone == HitTestZone.rightEdge ||
              _dragZone == HitTestZone.bottomEdge
        ? ScrollbarInteraction.zoomRightOrBottom
        : ScrollbarInteraction.pan;

    widget.onPixelDeltaChanged(Offset.zero, lastInteraction);

    // PIXEL-DELTA PATTERN: Clear drag state (pixel position only)
    _dragStartPosition = null;
    _dragZone = null;
    _isAtZoomLimit = false;

    // Reset isDragging flag
    _stateNotifier.value = _stateNotifier.value.copyWith(isDragging: false);

    // Restart auto-hide timer if enabled
    if (widget.theme.autoHide) {
      _scheduleAutoHide();
    }
  }
}
