// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../core/chart_element.dart';
import '../core/coordinator.dart';
import '../core/element_types.dart';
import '../core/hit_test_strategy.dart';
import '../core/interaction_mode.dart';
import '../elements/resize_handle_element.dart';
import '../elements/simulated_annotation.dart';
import 'spatial_index.dart';

/// Custom RenderBox for high-performance chart rendering and interaction.
///
/// **Purpose** (per INTERACTION_ARCHITECTURE_DESIGN.md):
/// - High-performance rendering with GPU batching
/// - Viewport culling via QuadTree spatial index
/// - Background interactions (pan, zoom, wheel events)
/// - Pixel-perfect hit testing
/// - Handles 100+ elements at 60fps
///
/// **Integration**: Used by ChartPrototypeWidget as the RenderObject layer.
///
/// **Interaction Flow**:
/// 1. PointerEvent arrives at handleEvent()
/// 2. Use QuadTree to find candidate elements at pointer position
/// 3. Check coordinator state to determine if interaction is allowed
/// 4. Route event to appropriate handler based on button/modifiers
/// 5. Update coordinator state if interaction mode changes
class ChartRenderBox extends RenderBox {
  ChartRenderBox({
    required this.coordinator,
    List<ChartElement>? elements,
    this.onElementClick,
    this.onElementHover,
    this.onEmptyAreaClick,
    this.onCursorChange,
  }) {
    _elements = elements ?? [];
  }

  /// Spatial index for O(log n) hit testing.
  QuadTree? _spatialIndex;

  /// All chart elements to render and test.
  ///
  /// CRITICAL: This must be the same list reference that the coordinator
  /// mutates when calling element.onSelect()/onDeselect(), so that
  /// isSelected state changes are reflected during paint().
  List<ChartElement> _elements = [];

  /// Interaction coordinator for conflict resolution.
  final ChartInteractionCoordinator coordinator;

  /// Callback for element click events.
  final void Function(ChartElement element, PointerEvent event)? onElementClick;

  /// Callback for element hover events.
  final void Function(ChartElement? element)? onElementHover;

  /// Callback for empty area click (for box select start).
  final void Function(Offset position, PointerEvent event)? onEmptyAreaClick;

  /// Callback for cursor changes.
  final void Function(MouseCursor cursor)? onCursorChange;

  /// Current resize state (if resizing annotation).
  ResizeDirection? _activeResizeDirection;
  SimulatedAnnotation? _resizingAnnotation;
  Rect? _resizeStartBounds;

  /// Current cursor position (for crosshair rendering).
  Offset? _cursorPosition;

  /// Updates the list of chart elements.
  ///
  /// Rebuilds the spatial index with new elements.
  void updateElements(List<ChartElement> elements) {
    if (elements == _elements) return;

    _elements = elements;
    _rebuildSpatialIndex();
    markNeedsPaint();
  }

  /// Rebuilds the QuadTree spatial index from current elements.
  void _rebuildSpatialIndex() {
    if (!hasSize) return;

    _spatialIndex = QuadTree(
      bounds: Offset.zero & size,
      maxElementsPerNode: 4,
      maxDepth: 8,
    );

    // Insert all chart elements
    for (final element in _elements) {
      _spatialIndex!.insert(element);

      // For annotations, also insert their resize handle elements
      if (element is SimulatedAnnotation) {
        final handleElements = element.createResizeHandleElements();
        for (final handle in handleElements) {
          _spatialIndex!.insert(handle);
        }
      }
    }
  }

  // ============================================================================
  // Layout
  // ============================================================================

  @override
  void performLayout() {
    // Chart takes all available space
    size = constraints.biggest;

    // Rebuild spatial index when size changes
    _rebuildSpatialIndex();
  }

  // ============================================================================
  // Hit Testing
  // ============================================================================

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Always claim hit test (chart consumes all pointer events in its bounds)
    if (!size.contains(position)) {
      return false;
    }

    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  /// Finds the top-priority element at the given position.
  ///
  /// Uses QuadTree for O(log n) spatial query, then performs precise hit
  /// testing and priority-based conflict resolution.
  ///
  /// Returns the element with highest priority that passes hitTest(), or null.
  ///
  /// **Conflict Resolution** (per CONFLICT_RESOLUTION_TABLE.md):
  /// - Query QuadTree for candidate elements at position
  /// - Filter to elements that pass precise hitTest()
  /// - Return highest priority element
  ChartElement? hitTestElements(Offset position) {
    if (_spatialIndex == null) return null;

    // Query spatial index for candidate elements
    // Use 18px radius to account for edge zones that extend 8px outside bounds
    // (10px base tolerance + 8px max edge width = 18px total)
    // NOTE: QuadTree now inserts elements into ALL overlapping quadrants,
    // so this smaller radius is sufficient (previously needed 50px due to center-only insertion bug)
    final candidates = _spatialIndex!.query(position, radius: 18);

    if (candidates.isEmpty) return null;

    // Filter to elements that pass precise hit test
    final hits = candidates.where((e) => e.hitTest(position)).toList();

    if (hits.isEmpty) return null;

    // Return highest priority element
    hits.sort((a, b) => b.priority.compareTo(a.priority));
    return hits.first;
  }

  /// Finds all elements within a rectangular region (for box select).
  ///
  /// Per conflict resolution scenario 14: Box select only captures datapoints.
  List<ChartElement> hitTestRect(Rect rect) {
    if (_spatialIndex == null) return [];

    final candidates = _spatialIndex!.queryRect(rect);

    // Filter to datapoints only (per conflict resolution)
    // and elements whose center is inside rect
    return candidates.where((e) => e.elementType == ChartElementType.datapoint && rect.contains(e.bounds.center)).toList();
  }

  /// Hit tests for resize handles on annotations.
  ///
  /// Returns annotation and direction if a handle is hit, null otherwise.
  ///
  /// Performs resize operation during drag.
  void _performResize(Offset currentPosition, Offset startPosition) {
    if (_resizingAnnotation == null || _activeResizeDirection == null || _resizeStartBounds == null) {
      return;
    }

    final delta = currentPosition - startPosition;
    final oldBounds = _resizeStartBounds!;
    Rect newBounds;

    // Calculate new bounds based on resize direction
    switch (_activeResizeDirection!) {
      case ResizeDirection.topLeft:
        newBounds = Rect.fromLTRB(
          oldBounds.left + delta.dx,
          oldBounds.top + delta.dy,
          oldBounds.right,
          oldBounds.bottom,
        );
        break;
      case ResizeDirection.topRight:
        newBounds = Rect.fromLTRB(
          oldBounds.left,
          oldBounds.top + delta.dy,
          oldBounds.right + delta.dx,
          oldBounds.bottom,
        );
        break;
      case ResizeDirection.bottomLeft:
        newBounds = Rect.fromLTRB(
          oldBounds.left + delta.dx,
          oldBounds.top,
          oldBounds.right,
          oldBounds.bottom + delta.dy,
        );
        break;
      case ResizeDirection.bottomRight:
        newBounds = Rect.fromLTRB(
          oldBounds.left,
          oldBounds.top,
          oldBounds.right + delta.dx,
          oldBounds.bottom + delta.dy,
        );
        break;
      case ResizeDirection.top:
        newBounds = Rect.fromLTRB(
          oldBounds.left,
          oldBounds.top + delta.dy,
          oldBounds.right,
          oldBounds.bottom,
        );
        break;
      case ResizeDirection.right:
        newBounds = Rect.fromLTRB(
          oldBounds.left,
          oldBounds.top,
          oldBounds.right + delta.dx,
          oldBounds.bottom,
        );
        break;
      case ResizeDirection.bottom:
        newBounds = Rect.fromLTRB(
          oldBounds.left,
          oldBounds.top,
          oldBounds.right,
          oldBounds.bottom + delta.dy,
        );
        break;
      case ResizeDirection.left:
        newBounds = Rect.fromLTRB(
          oldBounds.left + delta.dx,
          oldBounds.top,
          oldBounds.right,
          oldBounds.bottom,
        );
        break;
    }

    // Apply minimum size constraints (40x40 minimum)
    const minSize = 40.0;
    if (newBounds.width < minSize || newBounds.height < minSize) {
      // Don't allow resize below minimum
      return;
    }

    // Update annotation bounds
    // Note: Spatial index will be rebuilt on pointer up for performance
    _resizingAnnotation!.updateBounds(newBounds);
  } // ============================================================================
  // Event Handling
  // ============================================================================

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));

    // Modal states block all events except themselves
    if (coordinator.isModal) {
      return;
    }

    // CRITICAL: Use event.localPosition, NOT entry.localPosition!
    // entry.localPosition is captured at hit test time (pointer down) and never updates.
    // event.localPosition gives us the current position for move events.
    final localPosition = event.localPosition;

    if (event is PointerDownEvent) {
      _handlePointerDown(event, localPosition);
    } else if (event is PointerMoveEvent) {
      _handlePointerMove(event, localPosition);
    } else if (event is PointerUpEvent) {
      _handlePointerUp(event, localPosition);
    } else if (event is PointerHoverEvent) {
      _handlePointerHover(event, localPosition);
    } else if (event is PointerScrollEvent) {
      _handlePointerScroll(event, localPosition);
    }
  }

  void _handlePointerDown(PointerDownEvent event, Offset position) {
    // Use unified hit testing with priority-based conflict resolution
    final hitElement = hitTestElements(position);

    coordinator.startInteraction(position, element: hitElement);

    // Check if we hit a resize handle (priority 7)
    if (event.buttons == kPrimaryMouseButton && hitElement is ResizeHandleElement) {
      // Clicked on resize handle - extract parent annotation and direction
      final annotation = hitElement.parentAnnotation;
      final direction = hitElement.direction;

      // Select the annotation first if not already selected
      if (!annotation.isSelected) {
        coordinator.selectElement(annotation);
      }

      _activeResizeDirection = direction;
      _resizingAnnotation = annotation;
      _resizeStartBounds = annotation.bounds;
      coordinator.claimMode(InteractionMode.resizingAnnotation, element: annotation);
      markNeedsPaint();
      return;
    }

    // Per conflict resolution: Different buttons have different behaviors
    if (event.buttons == kMiddleMouseButton) {
      // Middle-click: EXCLUSIVELY pan (per scenario 6)
      coordinator.claimMode(InteractionMode.panning);
    } else if (event.buttons == kSecondaryMouseButton) {
      // Right-click: EXCLUSIVELY context menu (per scenario 8)
      coordinator.claimMode(InteractionMode.contextMenuOpen, element: hitElement);
    } else if (event.buttons == kPrimaryMouseButton) {
      // Left-click: Select, or start drag/box-select (determined on move)
      if (hitElement != null) {
        // Clicked on element - select it (or toggle if Ctrl)
        if (coordinator.isCtrlPressed) {
          coordinator.toggleElementSelection(hitElement);
        } else {
          coordinator.selectElement(hitElement);
        }
        coordinator.claimMode(InteractionMode.selecting, element: hitElement);
        onElementClick?.call(hitElement, event);
      } else {
        // Clicked on empty area - clear selection and prepare for box select
        coordinator.clearSelection();
        onEmptyAreaClick?.call(position, event);
        markNeedsPaint();
      }
    }
  }

  void _handlePointerMove(PointerMoveEvent event, Offset position) {
    if (!coordinator.isInteracting) return;

    final startPos = coordinator.interactionStartPosition;
    if (startPos == null) return;

    // Handle resize dragging
    if (coordinator.currentMode == InteractionMode.resizingAnnotation &&
        _resizingAnnotation != null &&
        _activeResizeDirection != null &&
        _resizeStartBounds != null) {
      _performResize(position, startPos);
      markNeedsPaint();
      return;
    }

    // Middle-button drag = pan (per conflict resolution scenario 6)
    if (event.buttons == kMiddleMouseButton && coordinator.currentMode == InteractionMode.panning) {
      // Pan logic would go here in production
      // For prototype, just track the mode
      return;
    }

    // Left-button drag: datapoint drag, annotation drag, or box select
    if (event.buttons == kPrimaryMouseButton) {
      final startElement = coordinator.interactionStartElement;

      // Update box selection rectangle if already in box select mode
      if (coordinator.currentMode == InteractionMode.boxSelecting) {
        coordinator.updateBoxSelection(startPos, position);
        final newRect = coordinator.boxSelectionRect;

        // Track cursor position for crosshair rendering
        _cursorPosition = position;

        // Update preview selection with elements currently in box
        if (newRect != null) {
          final previewElements = hitTestRect(newRect);
          coordinator.updatePreviewSelection(previewElements.toSet());
        }

        markNeedsPaint();
        return;
      }

      if (startElement != null && startElement.isDraggable) {
        // Dragging an element (per scenarios 5, 10, 13)
        if (startElement.elementType == ChartElementType.datapoint) {
          coordinator.claimMode(InteractionMode.draggingDataPoint, element: startElement);
        } else if (startElement.elementType == ChartElementType.annotation) {
          coordinator.claimMode(InteractionMode.draggingAnnotation, element: startElement);
        }
      } else if (coordinator.shouldStartBoxSelect(position)) {
        // Box selection (per scenario 5: >5px drag on empty area)
        coordinator.claimMode(InteractionMode.boxSelecting);
        coordinator.updateBoxSelection(startPos, position);
        markNeedsPaint(); // Repaint to show box selection rectangle
      }
    }
  }

  void _handlePointerUp(PointerUpEvent event, Offset position) {
    // Complete box selection if active
    if (coordinator.currentMode == InteractionMode.boxSelecting) {
      final boxRect = coordinator.boxSelectionRect;
      if (boxRect != null) {
        final selectedElements = hitTestRect(boxRect);

        // Clear preview before committing actual selection
        coordinator.clearPreviewSelection();
        coordinator.addToSelection(selectedElements.toSet());
      }
    }

    // Rebuild spatial index if we just finished resizing
    // (Updates resize handle positions to match new annotation bounds)
    if (coordinator.currentMode == InteractionMode.resizingAnnotation) {
      _rebuildSpatialIndex();
    }

    // Clear resize state (annotation will revert to original size on next rebuild)
    _activeResizeDirection = null;
    _resizingAnnotation = null;
    _resizeStartBounds = null;

    // Clear cursor position
    _cursorPosition = null;

    // Release interaction
    coordinator.endInteraction();
    coordinator.releaseMode();
    markNeedsPaint();
  }

  void _handlePointerHover(PointerHoverEvent event, Offset position) {
    // Track cursor position for crosshair rendering
    _cursorPosition = position;

    // Per conflict resolution scenario 7: Hover is passive
    // Per scenario 12: Hover/tooltips suspended during panning
    if (coordinator.isPanning) {
      coordinator.setHoveredElement(null);
      onCursorChange?.call(SystemMouseCursors.basic);
      return;
    }

    // Use unified hit testing with priority-based conflict resolution
    final hitElement = hitTestElements(position);

    // Check if we hit a resize handle (priority 7)
    if (hitElement is ResizeHandleElement) {
      // Hovering over resize handle - show resize cursor
      final cursor = _getCursorForResizeDirection(hitElement.direction);
      onCursorChange?.call(cursor);
      coordinator.setHoveredElement(hitElement.parentAnnotation);
      onElementHover?.call(hitElement.parentAnnotation);
      markNeedsPaint();
      return;
    }

    // For any other element (datapoint=9, series=8, annotation=6, etc.)
    // Priority system ensures the highest-priority element wins
    onCursorChange?.call(SystemMouseCursors.basic);
    coordinator.setHoveredElement(hitElement);
    onElementHover?.call(hitElement);
    markNeedsPaint();
  }

  /// Gets the appropriate cursor for a resize direction.
  MouseCursor _getCursorForResizeDirection(ResizeDirection direction) {
    switch (direction) {
      case ResizeDirection.topLeft:
      case ResizeDirection.bottomRight:
        return SystemMouseCursors.resizeUpLeftDownRight;
      case ResizeDirection.topRight:
      case ResizeDirection.bottomLeft:
        return SystemMouseCursors.resizeUpRightDownLeft;
      case ResizeDirection.top:
      case ResizeDirection.bottom:
        return SystemMouseCursors.resizeUpDown;
      case ResizeDirection.left:
      case ResizeDirection.right:
        return SystemMouseCursors.resizeLeftRight;
    }
  }

  void _handlePointerScroll(PointerScrollEvent event, Offset position) {
    // Scroll events = zoom (per conflict resolution)
    // Modifiers affect zoom behavior (Ctrl = horizontal, Shift = vertical)
    // For prototype, just track the mode
    coordinator.claimMode(InteractionMode.zooming);

    // Release zoom mode after short delay (zoom is instant, not continuous)
    Future.delayed(const Duration(milliseconds: 100), () {
      if (coordinator.currentMode == InteractionMode.zooming) {
        coordinator.releaseMode();
      }
    });
  }

  // ============================================================================
  // Painting
  // ============================================================================

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    // Paint background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFFFFFF),
    );

    // Paint all elements (in order: lowest to highest priority)
    final sortedElements = _elements.toList()..sort((a, b) => a.priority.compareTo(b.priority));

    for (final element in sortedElements) {
      element.paint(canvas, size);
    }

    // Paint preview selection indicators (during box drag)
    // Draw with different visual style than actual selection (dashed outline)
    if (coordinator.currentMode == InteractionMode.boxSelecting) {
      final previewElements = coordinator.previewSelectedElements;
      for (final element in previewElements) {
        // Only draw preview for elements that aren't already selected
        if (!element.isSelected && element.elementType == ChartElementType.datapoint) {
          final bounds = element.bounds;
          final center = bounds.center;
          final radius = bounds.width / 2;

          // Draw dashed preview ring (different from solid selection ring)
          final previewPaint = Paint()
            ..color = const Color(0x8000AAFF) // Semi-transparent blue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
          canvas.drawCircle(center, radius + 3, previewPaint);
        }
      }
    }

    // Paint box selection rectangle if active
    if (coordinator.currentMode == InteractionMode.boxSelecting) {
      final boxRect = coordinator.boxSelectionRect;
      if (boxRect != null) {
        // Draw selection rectangle
        canvas.drawRect(
          boxRect,
          Paint()
            ..color = const Color(0x4000AAFF)
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          boxRect,
          Paint()
            ..color = const Color(0xFF0088FF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }

    // Draw crosshair at cursor position (always visible when cursor is over chart)
    final cursorPos = _cursorPosition;
    if (cursorPos != null) {
      final crosshairPaint = Paint()
        ..color = const Color(0x80666666) // Semi-transparent gray
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      // Horizontal line
      canvas.drawLine(
        Offset(0, cursorPos.dy),
        Offset(size.width, cursorPos.dy),
        crosshairPaint,
      );

      // Vertical line
      canvas.drawLine(
        Offset(cursorPos.dx, 0),
        Offset(cursorPos.dx, size.height),
        crosshairPaint,
      );
    }

    canvas.restore();
  }

  // ============================================================================
  // Debug
  // ============================================================================

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('elementCount', _elements.length));
    properties.add(DiagnosticsProperty<QuadTreeStats>('spatialIndexStats', _spatialIndex?.stats));
    properties.add(StringProperty('coordinatorState', coordinator.debugState()));
  }
}
