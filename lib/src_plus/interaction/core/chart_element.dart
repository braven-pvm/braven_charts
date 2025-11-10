// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

import 'dart:ui';

import 'element_types.dart';

/// Base interface for all interactive chart elements.
///
/// This unified interface allows the rendering and interaction systems to handle
/// all chart elements (datapoints, annotations, series lines) uniformly.
///
/// Elements are tested for hit detection via [hitTest] and painted via [paint].
/// The [priority] property determines conflict resolution when elements overlap.
///
/// Design: Per INTERACTION_ARCHITECTURE_DESIGN.md, this enables O(log n) hit testing
/// via QuadTree spatial index and GPU batching via Canvas.drawRawAtlas.
abstract class ChartElement {
  /// Unique identifier for this element.
  String get id;

  /// Bounding rectangle for this element in chart coordinates.
  ///
  /// Used for:
  /// - QuadTree spatial indexing
  /// - Viewport culling (only paint/test visible elements)
  /// - Coarse hit testing before precise [hitTest]
  Rect get bounds;

  /// Element type identifier for type-safe behavior and conflict resolution.
  ///
  /// **Performance**: Enum comparison is faster than string comparison
  /// (integer comparison vs memcmp).
  ChartElementType get elementType;

  /// Priority level for conflict resolution.
  ///
  /// Default implementation derives priority from element type.
  /// Override if element needs dynamic priority based on state
  /// (e.g., annotation edges vs body).
  ///
  /// See [ElementPriority] for the complete hierarchy.
  ///
  /// Higher values win conflicts when elements overlap.
  int get priority => ElementPriority.forType(elementType);

  /// Whether this element is currently selected.
  bool get isSelected;

  /// Whether this element is currently hovered.
  bool get isHovered;

  /// Whether this element can be selected via click.
  ///
  /// Per conflict resolution rules:
  /// - Datapoints: always selectable
  /// - Annotations: only trend/selectable types
  /// - Series lines: selectable
  /// - Resize handles: not directly selectable (trigger resize mode)
  /// - Crosshair: not selectable (passive)
  bool get isSelectable;

  /// Whether this element can be dragged.
  ///
  /// Per conflict resolution rules:
  /// - Datapoints: draggable (left-click drag if started on point)
  /// - Annotations: draggable (left-click drag on body in edit mode)
  /// - Resize handles: draggable (triggers resize mode)
  /// - Series lines: not draggable (requires Alt modifier if supported)
  bool get isDraggable;

  /// Performs precise hit testing at the given point.
  ///
  /// Called after coarse bounds check. Should return true if the point
  /// is within the interactive region of this element.
  ///
  /// For datapoints: check distance to center <= radius
  /// For annotations: check if point is inside body or handle regions
  /// For series lines: check distance to path <= stroke width / 2
  ///
  /// [position] is in chart coordinates (same space as [bounds]).
  bool hitTest(Offset position);

  /// Paints this element on the canvas.
  ///
  /// [canvas] is the canvas to draw on.
  /// [size] is the size of the chart area.
  ///
  /// Implementation should respect [isSelected] and [isHovered] for visual feedback.
  ///
  /// Note: For performance, consider using Canvas.drawRawAtlas for batching
  /// multiple elements (per INTERACTION_ARCHITECTURE_DESIGN.md).
  void paint(Canvas canvas, Size size);

  /// Called when this element is selected.
  void onSelect();

  /// Called when this element is deselected.
  void onDeselect();

  /// Called when mouse enters this element's bounds.
  void onHoverEnter();

  /// Called when mouse exits this element's bounds.
  void onHoverExit();

  /// Returns a copy of this element with updated hover state.
  ///
  /// Immutable pattern for state updates without rebuilding entire tree.
  ChartElement copyWith({bool? isHovered, bool? isSelected});
}

/// Mixin for elements with resize handles.
///
/// Per conflict resolution scenario 1: Resize handles have priority 9
/// (highest interactive priority).
mixin ResizableElement on ChartElement {
  /// Returns the bounds of all resize handles for this element.
  ///
  /// Typically 8 handles (corners + midpoints) for rectangular elements.
  /// Each handle is typically 8px × 8px (per conflict resolution table).
  List<Rect> get resizeHandleBounds;

  /// Returns the index of the resize handle at the given position, or null if none.
  ///
  /// Handles are indexed:
  /// 0-3: corners (TL, TR, BR, BL)
  /// 4-7: midpoints (T, R, B, L)
  int? getResizeHandleAt(Offset position);

  /// Whether resize handles are currently visible.
  ///
  /// Typically true when element is selected, false otherwise.
  bool get showResizeHandles;
}

/// Mixin for elements that can show tooltips.
///
/// Per conflict resolution rules: Tooltips are passive and don't block clicks.
/// Per scenario 12: Tooltips are suspended during panning.
mixin TooltipElement on ChartElement {
  /// Returns the tooltip text/content for this element.
  String get tooltipText;

  /// Whether to show tooltip when hovering.
  ///
  /// Should check coordinator state: if panning, return false.
  bool get showTooltip;

  /// Returns the preferred position for the tooltip relative to the element.
  Offset get tooltipPosition;
}

/// Mixin for elements that support context menus.
///
/// Per conflict resolution scenario 8: Right-click opens context menu.
/// - Right-click on empty chart -> "Add Annotation / Chart Actions"
/// - Right-click on annotation -> "Edit / Delete / Properties"
mixin ContextMenuElement on ChartElement {
  /// Returns the context menu items for this element.
  List<ContextMenuItem> get contextMenuItems;
}

/// Represents a context menu item.
class ContextMenuItem {
  const ContextMenuItem({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });
  final String label;
  final VoidCallback onTap;
  final bool enabled;
}
