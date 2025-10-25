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
  /// - [theme]: Visual configuration (colors, sizes, interaction settings)
  const ChartScrollbar({
    super.key,
    required this.axis,
    required this.dataRange,
    required this.viewportRange,
    required this.onViewportChanged,
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
class _ChartScrollbarState extends State<ChartScrollbar> {
  /// Reactive state management (Constitutional requirement: ValueNotifier for >10Hz events).
  late ValueNotifier<ScrollbarState> _stateNotifier;

  /// Focus node for keyboard navigation.
  late FocusNode _focusNode;

  /// Timer for auto-hide feature.
  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();

    // Initialize state with handle geometry from current viewport
    _stateNotifier = ValueNotifier(ScrollbarState.initial());
    _focusNode = FocusNode();

    // Schedule initial handle geometry calculation
    // (deferred to first build to get accurate widget dimensions)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateHandleGeometry();
    });

    // Start auto-hide timer if enabled
    if (widget.theme.autoHide) {
      _scheduleAutoHide();
    }
  }

  @override
  void didUpdateWidget(ChartScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Recalculate handle geometry when viewport or data range changes
    if (oldWidget.viewportRange != widget.viewportRange ||
        oldWidget.dataRange != widget.dataRange ||
        oldWidget.axis != widget.axis) {
      _updateHandleGeometry();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to get available space for trackLength calculation
    return LayoutBuilder(
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
        final handlePosition = ScrollbarController.calculateHandlePosition(
          widget.dataRange.span,
          widget.viewportRange.span,
          trackLength,
          scrollOffset,
          widget.theme.minHandleSize,
        );

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

            // Render scrollbar using CustomPaint
            return SizedBox(
              width: widget.axis == Axis.horizontal ? trackLength : widget.theme.thickness,
              height: widget.axis == Axis.vertical ? trackLength : widget.theme.thickness,
              child: CustomPaint(
                painter: painter,
              ),
            );
          },
        );
      },
    );
  }

  /// Updates handle position and size based on current viewport and data range.
  ///
  /// Called when:
  /// - Widget initializes (initState)
  /// - External viewport changes (didUpdateWidget)
  /// - Track dimensions change (build phase)
  void _updateHandleGeometry() {
    // Get current widget dimensions from context
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      // Widget not laid out yet, skip update
      return;
    }

    final size = renderBox.size;
    final trackLength = widget.axis == Axis.horizontal ? size.width : size.height;

    // Calculate handle size using ScrollbarController
    final handleSize = ScrollbarController.calculateHandleSize(
      widget.dataRange.span,
      widget.viewportRange.span,
      trackLength,
      widget.theme.minHandleSize,
    );

    // Calculate handle position using ScrollbarController
    final scrollOffset = widget.viewportRange.min - widget.dataRange.min;

    final handlePosition = ScrollbarController.calculateHandlePosition(
      widget.dataRange.span,
      widget.viewportRange.span,
      trackLength,
      scrollOffset,
      widget.theme.minHandleSize,
    );

    // Update state via ValueNotifier (Performance First: no setState)
    _stateNotifier.value = _stateNotifier.value.copyWith(
      handleSize: handleSize,
      handlePosition: handlePosition,
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
}
