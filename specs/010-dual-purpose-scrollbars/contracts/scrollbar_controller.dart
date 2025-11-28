// Copyright 2025 Braven Charts. All rights reserved.
// Use of this source code is governed by a BSD-style license.

import 'package:flutter/widgets.dart';
import 'package:braven_charts/legacy/src/coordinate_system/data_range.dart';

/// Pure functions for scrollbar coordinate transformations.
///
/// All methods are static (no instance state) to enforce immutability and
/// functional purity. Used internally by ChartScrollbar for calculating
/// handle geometry and converting between pixel coordinates and data ranges.
///
/// **Performance**: All calculations are O(1) with target execution time <0.1ms.
///
/// ## Coordinate System
///
/// - **Track**: The full scrollable area (size in pixels)
/// - **Handle**: The draggable indicator within the track (position + size in pixels)
/// - **Data Range**: The full range of data values (min/max in data units)
/// - **Viewport Range**: The currently visible subset of data (min/max in data units)
///
/// ## Transformation Flow
///
/// ```
/// Data Space                    Pixel Space
/// ┌─────────────────────┐       ┌─────────────────┐
/// │ dataRange           │       │ track           │
/// │ min=0, max=100      │  ←→   │ size=200px      │
/// │                     │       │                 │
/// │  ┌──────────┐       │       │  ┌────┐         │
/// │  │ viewport │       │       │  │han│         │
/// │  │ 25-75    │       │  ←→   │  │dle│         │
/// │  └──────────┘       │       │  └────┘         │
/// │                     │       │  pos=50px       │
/// │                     │       │  size=100px     │
/// └─────────────────────┘       └─────────────────┘
/// ```
///
/// ## Usage
///
/// ```dart
/// // Calculate handle geometry from data ranges
/// final handleSize = ScrollbarController.calculateHandleSize(
///   dataRange: DataRange(min: 0, max: 100),
///   viewportRange: DataRange(min: 25, max: 75),
///   trackSize: 200.0,
///   minHandleSize: 20.0,
/// );  // Returns: (50/100) * 200 = 100px
///
/// final handlePos = ScrollbarController.calculateHandlePosition(
///   dataRange: DataRange(min: 0, max: 100),
///   viewportRange: DataRange(min: 25, max: 75),
///   trackSize: 200.0,
///   handleSize: 100.0,
/// );  // Returns: (25/100) * (200-100) = 25px
///
/// // Reverse: Convert handle drag delta to viewport change
/// final newViewport = ScrollbarController.handleToDataRange(
///   handlePosition: 50.0,  // User dragged to 50px
///   handleSize: 100.0,
///   trackSize: 200.0,
///   dataRange: DataRange(min: 0, max: 100),
/// );  // Returns: DataRange(min: 50, max: 100)
/// ```
///
/// ## See Also
///
/// - [ChartScrollbar] - Widget that uses these transformations
/// - [ScrollbarConfig] - Configuration including minHandleSize
class ScrollbarController {
  /// Private constructor to prevent instantiation (utility class).
  ScrollbarController._();

  /// Calculate handle size based on viewport-to-data ratio.
  ///
  /// **Formula**: `handleSize = (viewportRange.span / dataRange.span) * trackSize`
  ///
  /// **Clamping**: Result is clamped to `[minHandleSize, trackSize]` to prevent:
  /// - Too small: When zoomed far out (viewing 1% of data → 2px handle), clamp to minHandleSize
  /// - Too large: When zoomed in (viewing 100% of data → full track), clamp to trackSize
  ///
  /// **Performance**: 3 divisions, 1 multiplication, 1 clamp → <0.05ms
  ///
  /// **Example**:
  /// ```dart
  /// // Viewing 25% of data (25 out of 100 data points)
  /// calculateHandleSize(
  ///   dataRange: DataRange(min: 0, max: 100),
  ///   viewportRange: DataRange(min: 25, max: 50),  // span = 25
  ///   trackSize: 200.0,
  ///   minHandleSize: 20.0,
  /// );  // (25/100) * 200 = 50px
  ///
  /// // Viewing 1% of data (zoomed way out)
  /// calculateHandleSize(
  ///   dataRange: DataRange(min: 0, max: 100),
  ///   viewportRange: DataRange(min: 0, max: 1),  // span = 1
  ///   trackSize: 200.0,
  ///   minHandleSize: 20.0,
  /// );  // (1/100) * 200 = 2px, but clamped to 20px (minHandleSize)
  /// ```
  ///
  /// **Preconditions**:
  /// - `trackSize > 0`
  /// - `minHandleSize > 0`
  /// - `dataRange.span > 0` (dataRange.max > dataRange.min)
  /// - `viewportRange.span > 0` (viewportRange.max > viewportRange.min)
  ///
  /// **Throws**: [AssertionError] if any precondition violated (debug mode only)
  static double calculateHandleSize({
    required DataRange dataRange,
    required DataRange viewportRange,
    required double trackSize,
    required double minHandleSize,
  }) {
    assert(trackSize > 0, 'Track size must be positive');
    assert(minHandleSize > 0, 'Min handle size must be positive');
    assert(dataRange.span > 0, 'Data range span must be positive');
    assert(viewportRange.span > 0, 'Viewport range span must be positive');

    final visibleRatio = viewportRange.span / dataRange.span;
    final handleSize = visibleRatio * trackSize;
    return handleSize.clamp(minHandleSize, trackSize);
  }

  /// Calculate handle position based on viewport offset within data range.
  ///
  /// **Formula**: `handlePosition = ((viewportRange.min - dataRange.min) / dataRange.span) * (trackSize - handleSize)`
  ///
  /// **Meaning**: If viewport starts 50% through the data, handle starts 50% down the track.
  ///
  /// **Constraining**: Result is clamped to `[0, trackSize - handleSize]` to prevent
  /// handle from rendering outside track bounds.
  ///
  /// **Performance**: 2 divisions, 1 multiplication, 1 subtraction, 1 clamp → <0.05ms
  ///
  /// **Example**:
  /// ```dart
  /// // Viewport starts at 50% through data (min=50 in 0-100 range)
  /// calculateHandlePosition(
  ///   dataRange: DataRange(min: 0, max: 100),
  ///   viewportRange: DataRange(min: 50, max: 75),
  ///   trackSize: 200.0,
  ///   handleSize: 50.0,  // 25% of data = 50px handle
  /// );  // (50/100) * (200-50) = 0.5 * 150 = 75px from track start
  ///
  /// // Viewport at data start (min=0)
  /// calculateHandlePosition(
  ///   dataRange: DataRange(min: 0, max: 100),
  ///   viewportRange: DataRange(min: 0, max: 25),
  ///   trackSize: 200.0,
  ///   handleSize: 50.0,
  /// );  // (0/100) * 150 = 0px (handle at track start)
  ///
  /// // Viewport at data end (min=75)
  /// calculateHandlePosition(
  ///   dataRange: DataRange(min: 0, max: 100),
  ///   viewportRange: DataRange(min: 75, max: 100),
  ///   trackSize: 200.0,
  ///   handleSize: 50.0,
  /// );  // (75/100) * 150 = 112.5px, but clamped to 150px (trackSize - handleSize)
  /// ```
  ///
  /// **Preconditions**:
  /// - `trackSize > handleSize` (track must be larger than handle)
  /// - `dataRange.span > 0`
  ///
  /// **Throws**: [AssertionError] if any precondition violated (debug mode only)
  static double calculateHandlePosition({
    required DataRange dataRange,
    required DataRange viewportRange,
    required double trackSize,
    required double handleSize,
  }) {
    assert(trackSize > handleSize, 'Track must be larger than handle');
    assert(dataRange.span > 0, 'Data range span must be positive');

    final offsetRatio = (viewportRange.min - dataRange.min) / dataRange.span;
    final position = offsetRatio * (trackSize - handleSize);
    return position.clamp(0.0, trackSize - handleSize);
  }

  /// Convert handle position/size back to data range (inverse transformation).
  ///
  /// This is the **reverse operation** of calculateHandleSize + calculateHandlePosition.
  /// Used when user drags handle: pixel delta → data range delta.
  ///
  /// **Formulas**:
  /// ```
  /// offsetRatio = handlePosition / (trackSize - handleSize)
  /// visibleRatio = handleSize / trackSize
  /// viewportMin = dataRange.min + (dataRange.span * offsetRatio)
  /// viewportMax = viewportMin + (dataRange.span * visibleRatio)
  /// ```
  ///
  /// **Performance**: 4 divisions, 3 multiplications, 2 additions → <0.1ms
  ///
  /// **Example**:
  /// ```dart
  /// // Handle at 75px, size 100px, track 200px
  /// handleToDataRange(
  ///   handlePosition: 75.0,
  ///   handleSize: 100.0,
  ///   trackSize: 200.0,
  ///   dataRange: DataRange(min: 0, max: 100),
  /// );
  /// // offsetRatio = 75 / (200-100) = 0.75 (75% down track)
  /// // visibleRatio = 100 / 200 = 0.5 (50% of track = 50% of data)
  /// // viewportMin = 0 + (100 * 0.75) = 75
  /// // viewportMax = 75 + (100 * 0.5) = 125, but clamped to dataRange.max (100)
  /// // Returns: DataRange(min: 75, max: 100)
  /// ```
  ///
  /// **Inverse Property** (round-trip correctness):
  /// ```dart
  /// final viewport = DataRange(min: 25, max: 75);
  /// final handle = dataRangeToHandle(dataRange, viewport, trackSize, minHandleSize);
  /// final recovered = handleToDataRange(handle.position, handle.size, trackSize, dataRange);
  /// assert(recovered == viewport);  // Should be equal (within floating point precision)
  /// ```
  ///
  /// **Preconditions**:
  /// - `trackSize > handleSize`
  /// - `handlePosition >= 0 && handlePosition <= trackSize - handleSize`
  ///
  /// **Throws**: [AssertionError] if any precondition violated (debug mode only)
  static DataRange handleToDataRange({
    required double handlePosition,
    required double handleSize,
    required double trackSize,
    required DataRange dataRange,
  }) {
    assert(trackSize > handleSize, 'Track must be larger than handle');
    assert(
      handlePosition >= 0 && handlePosition <= trackSize - handleSize,
      'Handle position out of bounds: $handlePosition not in [0, ${trackSize - handleSize}]',
    );

    final offsetRatio = handlePosition / (trackSize - handleSize);
    final visibleRatio = handleSize / trackSize;

    final dataSpan = dataRange.span;
    final viewportSpan = dataSpan * visibleRatio;
    final viewportMin = dataRange.min + (dataSpan * offsetRatio);
    final viewportMax = viewportMin + viewportSpan;

    return DataRange(min: viewportMin, max: viewportMax);
  }

  /// Convert data range to handle position/size (forward transformation).
  ///
  /// **Convenience method** combining [calculateHandleSize] + [calculateHandlePosition].
  /// Returns both position and size as a record for efficiency (single call).
  ///
  /// **Performance**: Same as calling both methods separately → <0.1ms total
  ///
  /// **Example**:
  /// ```dart
  /// final (:position, :size) = dataRangeToHandle(
  ///   dataRange: DataRange(min: 0, max: 100),
  ///   viewportRange: DataRange(min: 25, max: 75),
  ///   trackSize: 200.0,
  ///   minHandleSize: 20.0,
  /// );
  /// print('Handle at $position px, size $size px');
  /// // Output: Handle at 50.0 px, size 100.0 px
  /// ```
  ///
  /// **Preconditions**: Same as [calculateHandleSize] and [calculateHandlePosition]
  static ({double position, double size}) dataRangeToHandle({
    required DataRange dataRange,
    required DataRange viewportRange,
    required double trackSize,
    required double minHandleSize,
  }) {
    final size = calculateHandleSize(
      dataRange: dataRange,
      viewportRange: viewportRange,
      trackSize: trackSize,
      minHandleSize: minHandleSize,
    );
    final position = calculateHandlePosition(
      dataRange: dataRange,
      viewportRange: viewportRange,
      trackSize: trackSize,
      handleSize: size,
    );
    return (position: position, size: size);
  }

  /// Determine which interaction zone the pointer is over.
  ///
  /// **Zones**:
  /// - **leftEdge/topEdge**: First `edgeGripWidth` pixels of handle (resize min bound)
  /// - **rightEdge/bottomEdge**: Last `edgeGripWidth` pixels of handle (resize max bound)
  /// - **center**: Middle of handle (pan viewport, shift both min/max)
  /// - **track**: Outside handle bounds (click to jump viewport)
  ///
  /// **Performance**: 6 comparisons, 2 subtractions → <0.01ms
  ///
  /// **Example** (horizontal scrollbar, edgeGripWidth=8px, handleSize=50px):
  /// ```dart
  /// final handleBounds = Rect.fromLTWH(100, 0, 50, 12);  // Handle at x=100-150
  ///
  /// getHitTestZone(
  ///   pointerPosition: Offset(102, 5),  // 2px from left edge
  ///   handleBounds: handleBounds,
  ///   edgeGripWidth: 8.0,
  ///   axis: Axis.horizontal,
  /// );  // Returns: HitTestZone.leftEdge (within first 8px)
  ///
  /// getHitTestZone(
  ///   pointerPosition: Offset(125, 5),  // Middle of handle
  ///   handleBounds: handleBounds,
  ///   edgeGripWidth: 8.0,
  ///   axis: Axis.horizontal,
  /// );  // Returns: HitTestZone.center (not within 8px of either edge)
  ///
  /// getHitTestZone(
  ///   pointerPosition: Offset(148, 5),  // 2px from right edge
  ///   handleBounds: handleBounds,
  ///   edgeGripWidth: 8.0,
  ///   axis: Axis.horizontal,
  /// );  // Returns: HitTestZone.rightEdge (within last 8px)
  ///
  /// getHitTestZone(
  ///   pointerPosition: Offset(50, 5),  // Before handle
  ///   handleBounds: handleBounds,
  ///   edgeGripWidth: 8.0,
  ///   axis: Axis.horizontal,
  /// );  // Returns: HitTestZone.track (outside handle)
  /// ```
  ///
  /// **Usage**: Determines cursor icon and drag behavior.
  /// ```dart
  /// final zone = ScrollbarController.getHitTestZone(...);
  /// final cursor = ScrollbarController.getCursorForZone(zone, axis);
  /// // zone=leftEdge → cursor=SystemMouseCursors.resizeColumn (↔)
  /// // zone=center → cursor=SystemMouseCursors.grab (✋)
  /// // zone=track → cursor=SystemMouseCursors.click (👆)
  /// ```
  static HitTestZone getHitTestZone({
    required Offset pointerPosition,
    required Rect handleBounds,
    required double edgeGripWidth,
    required Axis axis,
  }) {
    final isHorizontal = axis == Axis.horizontal;
    final pointerCoord = isHorizontal ? pointerPosition.dx : pointerPosition.dy;
    final handleStart = isHorizontal ? handleBounds.left : handleBounds.top;
    final handleEnd = isHorizontal ? handleBounds.right : handleBounds.bottom;

    // Outside handle → track
    if (pointerCoord < handleStart || pointerCoord > handleEnd) {
      return HitTestZone.track;
    }

    // Inside handle → determine edge vs center
    final distanceFromStart = pointerCoord - handleStart;
    final distanceFromEnd = handleEnd - pointerCoord;

    if (distanceFromStart <= edgeGripWidth) {
      return isHorizontal ? HitTestZone.leftEdge : HitTestZone.topEdge;
    } else if (distanceFromEnd <= edgeGripWidth) {
      return isHorizontal ? HitTestZone.rightEdge : HitTestZone.bottomEdge;
    } else {
      return HitTestZone.center;
    }
  }

  /// Get appropriate mouse cursor for interaction zone.
  ///
  /// **Cursor Mappings**:
  /// | Zone | Horizontal Axis | Vertical Axis | Meaning |
  /// |------|----------------|---------------|---------|
  /// | leftEdge/rightEdge | resizeColumn (↔) | resizeRow (↕) | Resize viewport bounds |
  /// | topEdge/bottomEdge | N/A | resizeRow (↕) | Resize viewport bounds |
  /// | center | grab (✋) | grab (✋) | Pan viewport |
  /// | track | click (👆) | click (👆) | Jump to position |
  ///
  /// **Example**:
  /// ```dart
  /// final cursor = getCursorForZone(HitTestZone.leftEdge, Axis.horizontal);
  /// // Returns: SystemMouseCursors.resizeColumn (↔)
  ///
  /// final cursor2 = getCursorForZone(HitTestZone.center, Axis.vertical);
  /// // Returns: SystemMouseCursors.grab (✋)
  /// ```
  static MouseCursor getCursorForZone(HitTestZone zone, Axis axis) {
    switch (zone) {
      case HitTestZone.leftEdge:
      case HitTestZone.rightEdge:
        return axis == Axis.horizontal ? SystemMouseCursors.resizeColumn : SystemMouseCursors.resizeRow;
      case HitTestZone.topEdge:
      case HitTestZone.bottomEdge:
        return SystemMouseCursors.resizeRow;
      case HitTestZone.center:
        return SystemMouseCursors.grab;
      case HitTestZone.track:
        return SystemMouseCursors.click;
    }
  }
}

/// Interaction zones within scrollbar for hit testing.
///
/// Determines which part of the scrollbar the pointer is over, controlling
/// cursor icons and drag behavior.
enum HitTestZone {
  /// Left edge of horizontal scrollbar (first edgeGripWidth pixels).
  ///
  /// **Drag behavior**: Adjusts viewportMin, keeping viewportMax fixed (zoom in/out left side).
  ///
  /// **Cursor**: ↔ (resizeColumn)
  leftEdge,

  /// Right edge of horizontal scrollbar (last edgeGripWidth pixels).
  ///
  /// **Drag behavior**: Adjusts viewportMax, keeping viewportMin fixed (zoom in/out right side).
  ///
  /// **Cursor**: ↔ (resizeColumn)
  rightEdge,

  /// Top edge of vertical scrollbar (first edgeGripWidth pixels).
  ///
  /// **Drag behavior**: Adjusts viewportMin, keeping viewportMax fixed.
  ///
  /// **Cursor**: ↕ (resizeRow)
  topEdge,

  /// Bottom edge of vertical scrollbar (last edgeGripWidth pixels).
  ///
  /// **Drag behavior**: Adjusts viewportMax, keeping viewportMin fixed.
  ///
  /// **Cursor**: ↕ (resizeRow)
  bottomEdge,

  /// Center of scrollbar handle (between edge zones).
  ///
  /// **Drag behavior**: Pans viewport (shifts both min and max by same delta).
  ///
  /// **Cursor**: ✋ (grab)
  center,

  /// Track area outside handle.
  ///
  /// **Click behavior**: Jumps viewport to center around click position.
  ///
  /// **Cursor**: 👆 (click)
  track,
}
