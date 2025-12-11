// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

/// Defines all possible interaction modes the chart can be in.
///
/// These modes are mutually exclusive and managed by [ChartInteractionCoordinator].
/// The coordinator ensures only one mode is active at a time to prevent gesture conflicts.
///
/// Modes are ordered by typical priority (highest to lowest):
/// - Modal states (contextMenuOpen, editingAnnotation) block other interactions
/// - Active operations (dragging, resizing, boxSelecting) claim interaction rights
/// - Selection states (selecting) are transient
/// - Passive states (hovering, idle) don't claim interactions
enum InteractionMode {
  /// No active interaction. Default state.
  idle,

  /// Mouse is hovering over an interactive element.
  /// This is a passive state - doesn't claim interactions.
  hovering,

  /// Scrollbar is being dragged (left-click drag on scrollbar handle/edges).
  /// Priority: 4 (above pan/zoom, below element interactions)
  /// Provides explicit viewport control via scrollbar UI.
  scrollbarDragging,

  /// Chart is being panned (middle-click drag per conflict resolution rules).
  /// EXCLUSIVE: Middle-button events route here only.
  panning,

  /// Chart is being zoomed (mouse wheel).
  zooming,

  /// Single element selection in progress (left-click).
  selecting,

  /// Box selection drag in progress (left-click drag on empty space).
  /// Box selects ONLY datapoints, not annotations (per conflict resolution table).
  boxSelecting,

  /// Datapoint is being dragged (left-click drag started on datapoint).
  /// Priority: 7 (per conflict resolution scenario 13)
  draggingDataPoint,

  /// Annotation body is being dragged/moved (left-click drag on annotation body).
  /// Priority: 8 (per conflict resolution scenario 10)
  draggingAnnotation,

  /// Annotation resize handle is being dragged.
  /// Priority: 9 (highest interactive priority - per conflict resolution scenario 1)
  resizingAnnotation,

  /// Annotation is in edit mode (double-click to edit).
  /// Priority: 9 (blocks most interactions - per conflict resolution scenario 11)
  editingAnnotation,

  /// Context menu is open (right-click).
  /// Priority: 10 (MODAL - blocks ALL chart interactions - per conflict resolution scenario 8)
  contextMenuOpen,

  /// Range annotation creation mode is active (right-click → "Add Range Annotation").
  /// Priority: 10 (MODAL - blocks ALL chart interactions, awaits drag to create range)
  /// User drags to define rectangular region, then dialog opens with pre-filled coordinates.
  rangeAnnotationCreation,
}

/// Extension methods for InteractionMode
extension InteractionModeExtensions on InteractionMode {
  /// Returns true if this mode blocks other interactions (modal states).
  bool get isModal {
    return this == InteractionMode.contextMenuOpen ||
        this == InteractionMode.editingAnnotation ||
        this == InteractionMode.rangeAnnotationCreation;
  }

  /// Returns true if this mode represents an active drag operation.
  bool get isDragging {
    return this == InteractionMode.draggingDataPoint ||
        this == InteractionMode.draggingAnnotation ||
        this == InteractionMode.resizingAnnotation;
  }

  /// Returns true if this mode represents a selection operation.
  bool get isSelecting {
    return this == InteractionMode.selecting ||
        this == InteractionMode.boxSelecting;
  }

  /// Returns true if this mode is passive (doesn't claim interactions).
  bool get isPassive {
    return this == InteractionMode.idle || this == InteractionMode.hovering;
  }

  /// Returns the priority level for this interaction mode.
  /// Higher values = higher priority in conflict resolution.
  ///
  /// Priority mapping from CONFLICT_RESOLUTION_TABLE.md:
  /// - 10: Modal (contextMenuOpen)
  /// - 9: Resize handles, edit mode (resizingAnnotation, editingAnnotation)
  /// - 8: Annotation drag (draggingAnnotation)
  /// - 7: Datapoint drag (draggingDataPoint)
  /// - 6: Selection (selecting, boxSelecting)
  /// - 3: Pan (panning)
  /// - 1: Zoom (zooming)
  /// - 0: Passive (idle, hovering)
  int get priority {
    switch (this) {
      case InteractionMode.contextMenuOpen:
      case InteractionMode.rangeAnnotationCreation:
        return 10;
      case InteractionMode.resizingAnnotation:
      case InteractionMode.editingAnnotation:
        return 9;
      case InteractionMode.draggingAnnotation:
        return 8;
      case InteractionMode.draggingDataPoint:
        return 7;
      case InteractionMode.selecting:
      case InteractionMode.boxSelecting:
        return 6;
      case InteractionMode.scrollbarDragging:
        return 4;
      case InteractionMode.panning:
        return 3;
      case InteractionMode.zooming:
        return 1;
      case InteractionMode.idle:
      case InteractionMode.hovering:
        return 0;
    }
  }

  /// Returns a human-readable description of this mode.
  String get description {
    switch (this) {
      case InteractionMode.idle:
        return 'Idle';
      case InteractionMode.hovering:
        return 'Hovering';
      case InteractionMode.scrollbarDragging:
        return 'Dragging scrollbar';
      case InteractionMode.panning:
        return 'Panning (middle-click drag)';
      case InteractionMode.zooming:
        return 'Zooming (mouse wheel)';
      case InteractionMode.selecting:
        return 'Selecting element';
      case InteractionMode.boxSelecting:
        return 'Box selecting datapoints';
      case InteractionMode.draggingDataPoint:
        return 'Dragging datapoint';
      case InteractionMode.draggingAnnotation:
        return 'Dragging annotation';
      case InteractionMode.resizingAnnotation:
        return 'Resizing annotation';
      case InteractionMode.editingAnnotation:
        return 'Editing annotation';
      case InteractionMode.contextMenuOpen:
        return 'Context menu open';
      case InteractionMode.rangeAnnotationCreation:
        return 'Creating range annotation (drag to define region)';
    }
  }
}
