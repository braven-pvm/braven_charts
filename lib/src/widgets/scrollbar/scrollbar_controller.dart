// Copyright (c) 2025 Forcegage PVM. All rights reserved.
// Use of this source code is governed by a BSD-style license.

/// Pure functions for scrollbar handle geometry calculations.
///
/// This class provides static O(1) methods for:
/// - Calculating handle size based on viewport/data ratio
/// - Converting between scroll offsets and handle positions
/// - Hit testing for scrollbar zones (track/handle/edges)
/// - Determining appropriate cursors for interaction zones
///
/// All methods are stateless and side-effect free, enabling easy testing
/// and predictable behavior in high-frequency pointer event handlers.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'hit_test_zone.dart';

/// Pure functions for scrollbar coordinate transformations and hit testing.
///
/// Constitutional Requirements:
/// - All methods are static (pure functions)
/// - All calculations are O(1) complexity
/// - No side effects or mutable state
/// - Defensive validation for edge cases
class ScrollbarController {
  // Private constructor - this class should never be instantiated
  ScrollbarController._();

  /// Calculates the scrollbar handle size based on the viewport-to-data ratio.
  ///
  /// **Formula**:
  /// ```
  /// handleSize = max(minHandleSize, (viewportRange / totalRange) * trackLength)
  /// ```
  ///
  /// **Edge Cases**:
  /// - If viewportRange >= totalRange: Returns trackLength (100% handle)
  /// - If totalRange == 0: Returns minHandleSize (defensive fallback)
  /// - If viewportRange == 0: Returns minHandleSize (defensive fallback)
  /// - Negative inputs: Clamped to 0 before calculation
  ///
  /// **Performance**: O(1) - single multiplication and max() call
  ///
  /// Parameters:
  /// - [totalRange]: Total data range (e.g., 0-100 for 100 data points)
  /// - [viewportRange]: Visible data range (e.g., 0-10 when zoomed to 10%)
  /// - [trackLength]: Available pixel space for handle movement
  /// - [minHandleSize]: Minimum handle size in pixels (default 20.0 per FR-003)
  ///
  /// Returns: Handle size in pixels, clamped between minHandleSize and trackLength
  static double calculateHandleSize(
    double totalRange,
    double viewportRange,
    double trackLength,
    double minHandleSize,
  ) {
    // Defensive validation - clamp negative values to 0
    final safeTotal = math.max(0.0, totalRange);
    final safeViewport = math.max(0.0, viewportRange);
    final safeTrack = math.max(0.0, trackLength);
    final safeMin = math.max(0.0, minHandleSize);

    // Edge case: No data or invalid inputs
    if (safeTotal == 0.0 || safeViewport == 0.0 || safeTrack == 0.0) {
      return safeMin;
    }

    // Edge case: Viewport >= total (no zoom) - handle fills entire track
    if (safeViewport >= safeTotal) {
      return safeTrack;
    }

    // Standard case: Calculate handle size as ratio of viewport to total
    final ratio = safeViewport / safeTotal;
    final calculatedSize = ratio * safeTrack;

    // Enforce minimum handle size per FR-003 (usability requirement)
    return math.max(safeMin, calculatedSize);
  }

  /// Calculates the scrollbar handle position based on scroll offset.
  ///
  /// **Formula**:
  /// ```
  /// handlePosition = (scrollOffset / maxScrollOffset) * (trackLength - handleSize)
  /// ```
  ///
  /// Where:
  /// ```
  /// maxScrollOffset = totalRange - viewportRange
  /// ```
  ///
  /// **Edge Cases**:
  /// - If scrollOffset <= 0: Returns 0 (handle at start)
  /// - If scrollOffset >= maxScrollOffset: Returns (trackLength - handleSize) (handle at end)
  /// - If maxScrollOffset == 0 (no scrolling possible): Returns 0
  /// - Negative scrollOffset: Clamped to 0
  ///
  /// **Performance**: O(1) - single division and multiplication
  ///
  /// Parameters:
  /// - [scrollOffset]: Current scroll position in data units (0 = start of data)
  /// - [totalRange]: Total data range
  /// - [viewportRange]: Visible data range
  /// - [trackLength]: Available pixel space for handle movement
  /// - [handleSize]: Handle size in pixels (from calculateHandleSize)
  ///
  /// Returns: Handle position in pixels, clamped between 0 and (trackLength - handleSize)
  static double calculateHandlePosition(
    double scrollOffset,
    double totalRange,
    double viewportRange,
    double trackLength,
    double handleSize,
  ) {
    // Defensive validation
    final safeOffset = math.max(0.0, scrollOffset);
    final safeTotal = math.max(0.0, totalRange);
    final safeViewport = math.max(0.0, viewportRange);
    final safeTrack = math.max(0.0, trackLength);
    final safeHandle = math.max(0.0, handleSize);

    // Calculate maximum scrollable offset
    final maxScrollOffset = math.max(0.0, safeTotal - safeViewport);

    // Edge case: No scrolling possible (viewport >= total)
    if (maxScrollOffset == 0.0) {
      return 0.0;
    }

    // Calculate available track space for handle movement
    final availableTrack = math.max(0.0, safeTrack - safeHandle);

    // Edge case: No space for handle to move
    if (availableTrack == 0.0) {
      return 0.0;
    }

    // Standard case: Map scroll offset to handle position
    final ratio = safeOffset / maxScrollOffset;
    final calculatedPosition = ratio * availableTrack;

    // Clamp to valid range [0, availableTrack]
    return calculatedPosition.clamp(0.0, availableTrack);
  }

  /// Converts a handle position back to the corresponding scroll offset.
  ///
  /// **Inverse Transform** of calculateHandlePosition().
  ///
  /// **Formula**:
  /// ```
  /// scrollOffset = (handlePosition / (trackLength - handleSize)) * (totalRange - viewportRange)
  /// ```
  ///
  /// **Edge Cases**:
  /// - If handlePosition <= 0: Returns 0 (scroll to start)
  /// - If handlePosition >= (trackLength - handleSize): Returns maxScrollOffset (scroll to end)
  /// - If (trackLength - handleSize) == 0: Returns 0 (no scrolling possible)
  ///
  /// **Round-Trip Property**:
  /// ```dart
  /// final offset = 25.0;
  /// final handlePos = calculateHandlePosition(offset, ...);
  /// final recoveredOffset = handleToDataRange(handlePos, ...);
  /// assert(recoveredOffset == offset); // Should be true (within floating point precision)
  /// ```
  ///
  /// **Performance**: O(1) - single division and multiplication
  ///
  /// Parameters:
  /// - [handlePosition]: Handle position in pixels (from drag event)
  /// - [totalRange]: Total data range
  /// - [viewportRange]: Visible data range
  /// - [trackLength]: Available pixel space for handle movement
  /// - [handleSize]: Handle size in pixels
  ///
  /// Returns: Scroll offset in data units, clamped to valid range
  static double handleToDataRange(
    double handlePosition,
    double totalRange,
    double viewportRange,
    double trackLength,
    double handleSize,
  ) {
    // Defensive validation
    final safeHandlePos = math.max(0.0, handlePosition);
    final safeTotal = math.max(0.0, totalRange);
    final safeViewport = math.max(0.0, viewportRange);
    final safeTrack = math.max(0.0, trackLength);
    final safeHandle = math.max(0.0, handleSize);

    // Calculate maximum scrollable offset
    final maxScrollOffset = math.max(0.0, safeTotal - safeViewport);

    // Calculate available track space for handle movement
    final availableTrack = math.max(0.0, safeTrack - safeHandle);

    // Edge case: No scrolling possible
    if (maxScrollOffset == 0.0 || availableTrack == 0.0) {
      return 0.0;
    }

    // Standard case: Inverse transform from handle position to scroll offset
    final ratio = safeHandlePos / availableTrack;
    final calculatedOffset = ratio * maxScrollOffset;

    // Clamp to valid range [0, maxScrollOffset]
    return calculatedOffset.clamp(0.0, maxScrollOffset);
  }

  /// Alias for calculateHandlePosition() - forward transform.
  ///
  /// **Purpose**: Provides semantic clarity when explicitly converting
  /// from data range coordinates to handle pixel coordinates.
  ///
  /// This is the same as calculateHandlePosition() but with a name that
  /// makes the direction of transformation explicit:
  /// - dataRangeToHandle: scroll offset → handle position (this method)
  /// - handleToDataRange: handle position → scroll offset (inverse)
  ///
  /// **Performance**: O(1) - delegates to calculateHandlePosition()
  ///
  /// See [calculateHandlePosition] for detailed documentation.
  static double dataRangeToHandle(
    double scrollOffset,
    double totalRange,
    double viewportRange,
    double trackLength,
    double handleSize,
  ) {
    return calculateHandlePosition(
      scrollOffset,
      totalRange,
      viewportRange,
      trackLength,
      handleSize,
    );
  }

  /// Determines which zone of the scrollbar was hit by a pointer event.
  ///
  /// **Zones** (FR-008/009 enhanced with 8.0px edge detection):
  /// - [HitTestZone.track]: On track but not on handle
  /// - [HitTestZone.center]: On handle body (not near edges)
  /// - [HitTestZone.leftEdge]/[HitTestZone.topEdge]: Within 8.0px of handle start (for resize)
  /// - [HitTestZone.rightEdge]/[HitTestZone.bottomEdge]: Within 8.0px of handle end (for resize)
  ///
  /// **Edge Detection Algorithm**:
  /// 1. Check if pointer is within scrollbar bounds (0 to trackLength)
  /// 2. Check if pointer is within handle bounds (handlePosition to handlePosition + handleSize)
  /// 3. If in handle, check distance from start/end edges (8.0px threshold)
  /// 4. Return axis-specific edge zone (left/right for horizontal, top/bottom for vertical)
  ///
  /// **Performance**: O(1) - simple bounds checking with early returns
  ///
  /// Parameters:
  /// - [localPosition]: Pointer position in scrollbar local coordinates
  /// - [axis]: Scrollbar axis (Axis.horizontal or Axis.vertical)
  /// - [trackLength]: Total track length in pixels
  /// - [handlePosition]: Current handle position in pixels
  /// - [handleSize]: Handle size in pixels
  /// - [edgeDetectionThreshold]: Distance from edge to trigger edge zone (default 8.0px)
  ///
  /// Returns: The zone that was hit (null if outside scrollbar bounds)
  static HitTestZone? getHitTestZone(
    Offset localPosition,
    Axis axis,
    double trackLength,
    double handlePosition,
    double handleSize, {
    double edgeDetectionThreshold = 8.0,
  }) {
    // Extract relevant coordinate based on axis
    final coord = axis == Axis.horizontal ? localPosition.dx : localPosition.dy;

    // Defensive validation
    final safeTrack = math.max(0.0, trackLength);
    final safeHandlePos = math.max(0.0, handlePosition);
    final safeHandleSize = math.max(0.0, handleSize);
    final safeThreshold = math.max(0.0, edgeDetectionThreshold);

    // Check if outside scrollbar bounds
    if (coord < 0.0 || coord > safeTrack) {
      return null; // Outside scrollbar - no zone
    }

    // Calculate handle bounds
    final handleStart = safeHandlePos;
    final handleEnd = safeHandlePos + safeHandleSize;

    // Check if outside handle bounds (on track)
    if (coord < handleStart || coord > handleEnd) {
      return HitTestZone.track;
    }

    // Inside handle - check for edge zones
    final distanceFromStart = coord - handleStart;
    final distanceFromEnd = handleEnd - coord;

    // Start edge has priority if both edges are within threshold
    // (e.g., when handle size < 2 * threshold)
    if (distanceFromStart <= safeThreshold) {
      // Return axis-specific start edge
      return axis == Axis.horizontal
          ? HitTestZone.leftEdge
          : HitTestZone.topEdge;
    }

    if (distanceFromEnd <= safeThreshold) {
      // Return axis-specific end edge
      return axis == Axis.horizontal
          ? HitTestZone.rightEdge
          : HitTestZone.bottomEdge;
    }

    // Default: On handle body (not near edges)
    return HitTestZone.center;
  }

  /// Returns the appropriate cursor for a given scrollbar zone.
  ///
  /// **Cursor Mapping** (FR-009 enhanced):
  /// - [HitTestZone.track] → SystemMouseCursors.click (track clicks jump viewport)
  /// - [HitTestZone.center] → SystemMouseCursors.grab (hovering) / SystemMouseCursors.grabbing (dragging)
  /// - [HitTestZone.leftEdge]/[HitTestZone.rightEdge] → SystemMouseCursors.resizeColumn (horizontal)
  /// - [HitTestZone.topEdge]/[HitTestZone.bottomEdge] → SystemMouseCursors.resizeRow (vertical)
  ///
  /// **Performance**: O(1) - simple switch statement
  ///
  /// Parameters:
  /// - [zone]: The hit test zone (from getHitTestZone)
  /// - [isDragging]: Whether handle is currently being dragged (affects grab cursor)
  ///
  /// Returns: Appropriate MouseCursor for the zone
  static MouseCursor getCursorForZone(
    HitTestZone zone, {
    bool isDragging = false,
  }) {
    switch (zone) {
      case HitTestZone.track:
        // Track clicks jump viewport to click position
        return SystemMouseCursors.click;

      case HitTestZone.center:
        // Show grabbing cursor when actively dragging, grab when hovering
        return isDragging
            ? SystemMouseCursors.grabbing
            : SystemMouseCursors.grab;

      case HitTestZone.leftEdge:
      case HitTestZone.rightEdge:
        // Horizontal scrollbar edge resize
        return SystemMouseCursors.resizeColumn;

      case HitTestZone.topEdge:
      case HitTestZone.bottomEdge:
        // Vertical scrollbar edge resize
        return SystemMouseCursors.resizeRow;
    }
  }

  /// Determines the current interaction state of the scrollbar.
  ///
  /// **States** (FR-021A):
  /// - [ScrollbarInteractionState.default_]: Normal state (no interaction)
  /// - [ScrollbarInteractionState.hover]: Pointer hovering over scrollbar
  /// - [ScrollbarInteractionState.active]: Scrollbar is being dragged or resized
  /// - [ScrollbarInteractionState.disabled]: Scrollbar is disabled (not scrollable)
  ///
  /// **State Priority** (highest to lowest):
  /// 1. disabled: Always wins if isEnabled is false
  /// 2. active: Pointer is down on handle/edges
  /// 3. hover: Pointer is over scrollbar but not pressed
  /// 4. default: No interaction
  ///
  /// **Performance**: O(1) - simple conditional checks
  ///
  /// Parameters:
  /// - [isHovering]: Whether pointer is currently over scrollbar
  /// - [isActive]: Whether scrollbar is being actively dragged/resized
  /// - [isEnabled]: Whether scrollbar is enabled (false when no scrolling possible)
  ///
  /// Returns: Current interaction state
  static ScrollbarInteractionState getInteractionState({
    required bool isHovering,
    required bool isActive,
    required bool isEnabled,
  }) {
    // Disabled state has highest priority
    if (!isEnabled) {
      return ScrollbarInteractionState.disabled;
    }

    // Active state (dragging/resizing) has second priority
    if (isActive) {
      return ScrollbarInteractionState.active;
    }

    // Hover state when pointer is over scrollbar
    if (isHovering) {
      return ScrollbarInteractionState.hover;
    }

    // Default state (no interaction)
    return ScrollbarInteractionState.default_;
  }

  /// Calculates the touch hit test padding for minimum 44x44 touch targets.
  ///
  /// **Purpose**: Ensures scrollbar handles meet WCAG 2.2 minimum touch target
  /// size (44x44 CSS pixels per FR-024A) by calculating required padding.
  ///
  /// **Algorithm**:
  /// 1. Calculate shortfall on each axis: `max(0, 44.0 - actualSize)`
  /// 2. Distribute shortfall evenly: `padding = shortfall / 2.0`
  /// 3. Return EdgeInsets with calculated padding
  ///
  /// **Example**:
  /// ```dart
  /// // 8px wide scrollbar handle needs (44 - 8) / 2 = 18px padding on each side
  /// final padding = calculateTouchHitTestPadding(
  ///   handleWidth: 8.0,
  ///   handleHeight: 100.0,
  ///   axis: Axis.vertical,
  /// );
  /// // Returns: EdgeInsets.symmetric(horizontal: 18.0, vertical: 0.0)
  /// ```
  ///
  /// **Performance**: O(1) - simple arithmetic
  ///
  /// Parameters:
  /// - [handleWidth]: Handle width in pixels (for horizontal scrollbars)
  /// - [handleHeight]: Handle height in pixels (for vertical scrollbars)
  /// - [axis]: Scrollbar axis (determines which dimension needs padding)
  /// - [minTouchTarget]: Minimum touch target size (default 44.0 per WCAG 2.2)
  ///
  /// Returns: EdgeInsets with padding needed to reach minimum touch target
  static EdgeInsets calculateTouchHitTestPadding({
    required double handleWidth,
    required double handleHeight,
    required Axis axis,
    double minTouchTarget = 44.0,
  }) {
    // Defensive validation
    final safeWidth = math.max(0.0, handleWidth);
    final safeHeight = math.max(0.0, handleHeight);
    final safeMin = math.max(0.0, minTouchTarget);

    if (axis == Axis.horizontal) {
      // Horizontal scrollbar: ensure height meets minimum
      final heightShortfall = math.max(0.0, safeMin - safeHeight);
      final verticalPadding = heightShortfall / 2.0;

      return EdgeInsets.symmetric(horizontal: 0.0, vertical: verticalPadding);
    } else {
      // Vertical scrollbar: ensure width meets minimum
      final widthShortfall = math.max(0.0, safeMin - safeWidth);
      final horizontalPadding = widthShortfall / 2.0;

      return EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 0.0);
    }
  }
}

/// Interaction states for scrollbar rendering (FR-021A).
enum ScrollbarInteractionState {
  /// Default state - no interaction
  default_,

  /// Pointer hovering over scrollbar
  hover,

  /// Scrollbar is being actively dragged or resized
  active,

  /// Scrollbar is disabled (no scrolling possible)
  disabled,
}
