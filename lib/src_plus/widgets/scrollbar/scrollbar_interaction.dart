// Copyright (c) 2025 Forcegage PVM. All rights reserved.
// Use of this source code is governed by a BSD-style license.

/// Type of scrollbar interaction for pixel-delta reporting.
///
/// This enum enables the parent widget to distinguish between different
/// types of scrollbar gestures when receiving pixel delta updates, allowing
/// it to apply the appropriate viewport transformation (pan vs zoom).
///
/// **Purpose**: Support dual-purpose scrollbar (pan + zoom) with pixel-delta pattern
/// **Architecture**: Part of the simplified scrollbar redesign (2025-10-28)
/// See: docs/architecture/SCROLLBAR_ARCHITECTURE_ANALYSIS.md
enum ScrollbarInteraction {
  /// User dragging center of handle → shift entire viewport (both min and max).
  ///
  /// **Parent behavior**: Apply pixel delta to BOTH viewport min and max equally.
  /// This maintains viewport size while shifting the visible window.
  ///
  /// **Example**:
  /// ```dart
  /// // Center pan - shift both boundaries
  /// final dataDelta = convertPixelDeltaToDataDelta(pixelDelta);
  /// newViewport = DataRange(
  ///   min: currentViewport.min + dataDelta,
  ///   max: currentViewport.max + dataDelta,
  /// );
  /// ```
  pan,

  /// User dragging left edge (horizontal) or top edge (vertical) → resize viewport min.
  ///
  /// **Parent behavior**: Apply pixel delta to viewport min only, keep max anchored.
  /// This changes viewport size (zoom) while keeping right/bottom edge fixed.
  ///
  /// **Example**:
  /// ```dart
  /// // Zoom via left edge - adjust min only
  /// final dataDelta = convertPixelDeltaToDataDelta(pixelDelta);
  /// newViewport = DataRange(
  ///   min: currentViewport.min + dataDelta,
  ///   max: currentViewport.max, // Anchored
  /// );
  /// ```
  zoomLeftOrTop,

  /// User dragging right edge (horizontal) or bottom edge (vertical) → resize viewport max.
  ///
  /// **Parent behavior**: Apply pixel delta to viewport max only, keep min anchored.
  /// This changes viewport size (zoom) while keeping left/top edge fixed.
  ///
  /// **Example**:
  /// ```dart
  /// // Zoom via right edge - adjust max only
  /// final dataDelta = convertPixelDeltaToDataDelta(pixelDelta);
  /// newViewport = DataRange(
  ///   min: currentViewport.min, // Anchored
  ///   max: currentViewport.max + dataDelta,
  /// );
  /// ```
  zoomRightOrBottom,

  /// User clicked track to jump viewport to click position.
  ///
  /// **Parent behavior**: Pixel delta represents absolute target position, not relative delta.
  /// Center viewport at the clicked data coordinate.
  ///
  /// **Example**:
  /// ```dart
  /// // Track click - center viewport at target
  /// final targetPosition = convertPixelToDataPosition(pixelOffset);
  /// final halfSpan = currentViewport.span / 2;
  /// newViewport = DataRange(
  ///   min: targetPosition - halfSpan,
  ///   max: targetPosition + halfSpan,
  /// );
  /// ```
  trackClick,

  /// User pressed keyboard navigation key (arrows, page up/down, home/end).
  ///
  /// **Parent behavior**: Pixel delta represents discrete step amount.
  /// Apply delta as pan operation (shift both boundaries).
  ///
  /// **Example**:
  /// ```dart
  /// // Keyboard nav - discrete pan steps
  /// final dataDelta = convertPixelDeltaToDataDelta(pixelDelta);
  /// newViewport = DataRange(
  ///   min: currentViewport.min + dataDelta,
  ///   max: currentViewport.max + dataDelta,
  /// );
  /// ```
  keyboard,
}
