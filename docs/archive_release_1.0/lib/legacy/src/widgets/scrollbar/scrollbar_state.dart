import 'package:flutter/foundation.dart';

import 'hit_test_zone.dart';

/// Immutable state for scrollbar UI.
///
/// Managed via ValueNotifier to prevent setState crashes during pointer events
/// (Constitutional requirement: Performance First - ValueNotifier for >10Hz updates).
@immutable
class ScrollbarState {
  /// Create initial state (no interaction, default geometry).
  factory ScrollbarState.initial() => const ScrollbarState(
    handlePosition: 0.0,
    handleSize: 20.0, // Will be recalculated on first build
    isDragging: false,
    hoverZone: null,
    isFocused: false,
    isVisible: true,
  );
  const ScrollbarState({
    required this.handlePosition,
    required this.handleSize,
    required this.isDragging,
    required this.hoverZone,
    required this.isFocused,
    required this.isVisible,
  });

  /// Position of scrollbar handle's leading edge (pixels from track start).
  ///
  /// For horizontal scrollbar: distance from left edge.
  /// For vertical scrollbar: distance from top edge.
  ///
  /// Constrained to [0, trackSize - handleSize].
  final double handlePosition;

  /// Size of scrollbar handle (pixels along track axis).
  ///
  /// Calculated as: (viewportRange / dataRange) * trackSize.
  /// Clamped to minimum of ScrollbarConfig.minHandleSize (default 20px).
  final double handleSize;

  /// Whether user is currently dragging the handle.
  ///
  /// True during GestureDetector.onPanUpdate, false on onPanEnd.
  final bool isDragging;

  /// Which zone the mouse is currently hovering over (if any).
  ///
  /// Used to:
  /// - Show appropriate cursor (resize vs grab vs click)
  /// - Highlight hover state in theme colors
  ///
  /// null when mouse not over scrollbar.
  final HitTestZone? hoverZone;

  /// Whether scrollbar has keyboard focus.
  ///
  /// True when user tabs to scrollbar or clicks it.
  /// Enables keyboard navigation (arrow keys, etc.).
  final bool isFocused;

  /// Whether scrollbar is visible (for auto-hide feature).
  ///
  /// False after ScrollbarConfig.autoHideDelay expires with no interaction.
  final bool isVisible;

  /// Create copy with updated fields (for ValueNotifier updates).
  ScrollbarState copyWith({
    double? handlePosition,
    double? handleSize,
    bool? isDragging,
    HitTestZone? hoverZone,
    bool? isFocused,
    bool? isVisible,
  }) => ScrollbarState(
    handlePosition: handlePosition ?? this.handlePosition,
    handleSize: handleSize ?? this.handleSize,
    isDragging: isDragging ?? this.isDragging,
    hoverZone: hoverZone ?? this.hoverZone,
    isFocused: isFocused ?? this.isFocused,
    isVisible: isVisible ?? this.isVisible,
  );

  /// Create copy with hoverZone explicitly set to null (copyWith with null doesn't work for nullable fields).
  ScrollbarState clearHoverZone() => ScrollbarState(
    handlePosition: handlePosition,
    handleSize: handleSize,
    isDragging: isDragging,
    hoverZone: null,
    isFocused: isFocused,
    isVisible: isVisible,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScrollbarState &&
          handlePosition == other.handlePosition &&
          handleSize == other.handleSize &&
          isDragging == other.isDragging &&
          hoverZone == other.hoverZone &&
          isFocused == other.isFocused &&
          isVisible == other.isVisible;

  @override
  int get hashCode => Object.hash(
    handlePosition,
    handleSize,
    isDragging,
    hoverZone,
    isFocused,
    isVisible,
  );
}
