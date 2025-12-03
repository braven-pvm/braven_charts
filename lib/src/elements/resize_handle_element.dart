// Copyright (c) 2025 braven_charts. All rights reserved.
// Resize Handle Elements for Annotations

import 'dart:ui';

import '../interaction/core/chart_element.dart';
import '../interaction/core/element_types.dart';
import '../interaction/core/hit_test_strategy.dart';

/// Resize handle element for annotation edges.
///
/// **Purpose**: Make resize handles participate in the unified priority system.
/// Instead of checking resize handles separately, they are inserted into the
/// spatial index as real elements with high priority.
///
/// **Integration**: Created dynamically when annotations are added to the chart.
/// Each annotation generates 8 resize handle elements (4 corners + 4 edges).
///
/// **Priority**: 7 (HIGH) - participates in hit-testing but loses to datapoints if overlapping.
class ResizeHandleElement extends ChartElement {
  ResizeHandleElement({
    required this.parentAnnotation,
    required this.direction,
    required Rect bounds,
  }) : _bounds = bounds;

  /// The annotation this handle belongs to.
  final ChartElement parentAnnotation;

  /// The resize direction this handle controls.
  final ResizeDirection direction;

  /// The handle bounds (8px x 8px hit target at edge).
  Rect _bounds;

  @override
  String get id => '${parentAnnotation.id}_handle_${direction.name}';

  @override
  Rect get bounds => _bounds;

  @override
  ChartElementType get elementType => ChartElementType.resizeHandle;

  @override
  // Resize handles render on top (controls layer)
  int get renderOrder => RenderOrder.resizeHandle;

  @override
  bool get isSelected => parentAnnotation.isSelected;

  @override
  bool get isHovered => false; // Handles don't have separate hover state

  @override
  bool get isSelectable => false; // Handles trigger resize, not selection

  @override
  bool get isDraggable => true; // Handles are draggable (trigger resize)

  /// Updates the handle bounds (called when parent annotation moves/resizes).
  void updateBounds(Rect newBounds) {
    _bounds = newBounds;
  }

  @override
  bool hitTest(Offset position) {
    // Simple bounds check - the bounds are already sized correctly
    return _bounds.contains(position);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Resize handles are painted by the parent annotation
    // This element only exists for hit-testing and priority resolution
  }

  @override
  void onSelect() {
    // Handles don't get selected, they trigger resize mode
  }

  @override
  void onDeselect() {
    // No-op
  }

  @override
  void onHoverEnter() {
    // Cursor change is handled in ChartRenderBox
  }

  @override
  void onHoverExit() {
    // No-op
  }

  @override
  ChartElement copyWith({bool? isHovered, bool? isSelected}) {
    // Handles don't maintain their own state
    return this;
  }
}
