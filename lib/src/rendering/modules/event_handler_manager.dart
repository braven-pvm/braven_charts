// Copyright (c) 2025 braven_charts. All rights reserved.
// EventHandlerManager Module - Extracted from ChartRenderBox

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../../coordinates/chart_transform.dart';
import '../../elements/annotation_elements.dart';
import '../../elements/resize_handle_element.dart';
import '../../elements/series_element.dart';
import '../../interaction/core/chart_element.dart';
import '../../interaction/core/coordinator.dart';
import '../../interaction/core/element_types.dart';
import '../../interaction/core/hit_test_strategy.dart';
import '../../interaction/core/interaction_mode.dart';
import '../../models/chart_annotation.dart';
import '../../models/chart_series.dart';
import '../../models/interaction_config.dart';

/// Delegate interface for EventHandlerManager to interact with ChartRenderBox.
///
/// This abstraction allows the event handler to access and modify chart state
/// without directly coupling to ChartRenderBox, enabling better testing and
/// separation of concerns.
abstract class EventHandlerDelegate {
  /// The interaction coordinator for mode and selection management.
  ChartInteractionCoordinator get coordinator;

  /// Current coordinate transform.
  ChartTransform? get transform;

  /// Original transform for pan constraint calculations.
  ChartTransform? get originalTransform;

  /// All chart elements for hit testing and iteration.
  List<ChartElement> get elements;

  /// Current interaction configuration.
  InteractionConfig? get interactionConfig;

  /// The plot area rectangle.
  Rect get plotArea;

  // ==================== Callbacks ====================

  /// Callback for element click events.
  void Function(ChartElement element, PointerEvent event)? get onElementClick;

  /// Callback for element hover events.
  void Function(ChartElement? element)? get onElementHover;

  /// Callback for empty area click (for box select start).
  void Function(Offset position, PointerEvent event)? get onEmptyAreaClick;

  /// Callback for cursor changes.
  void Function(MouseCursor cursor)? get onCursorChange;

  /// Callback for annotation changes.
  void Function(String annotationId, ChartAnnotation updatedAnnotation)? get onAnnotationChanged;

  /// Callback for range annotation creation completion.
  void Function(double startX, double endX, double startY, double endY)? get onRangeCreationComplete;

  // ==================== Delegated Operations ====================

  /// Converts widget coordinates to plot coordinates.
  Offset widgetToPlot(Offset widgetPosition);

  /// Hit tests elements at the given position.
  ChartElement? hitTestElements(Offset widgetPosition);

  /// Hit tests elements within a rectangle.
  List<ChartElement> hitTestRect(Rect widgetRect);

  /// Rebuilds the spatial index after element changes.
  void rebuildSpatialIndex();

  /// Triggers a repaint.
  void markNeedsPaint();

  /// Invalidates the series cache.
  void invalidateSeriesCache();

  /// Updates axes from the current transform.
  void updateAxesFromTransform();

  /// Rebuilds elements with the current transform.
  void rebuildElementsWithTransform();

  /// Clamps pan delta to enforce viewport bounds.
  (double, double) clampPanDelta(double requestedPlotDx, double requestedPlotDy);

  /// Clamps zoom level to min/max constraints.
  ChartTransform clampZoomLevel(ChartTransform transform);

  /// Sets the current transform.
  set transform(ChartTransform? value);

  /// Zooms the chart with optional animation.
  ///
  /// [factor] is the zoom factor (> 1.0 = zoom in, < 1.0 = zoom out).
  /// [plotCenter] is the center point in plot space (if null, uses plot center).
  /// [animate] controls whether to animate the zoom transition.
  void zoomChart(double factor, {Offset? plotCenter, bool animate = true});

  // ==================== Scrollbar Module Delegation ====================

  /// Checks if pointer is on scrollbar and handles the event.
  bool hitTestScrollbars(
    Offset position,
    int buttons, {
    required bool isModal,
    required VoidCallback onClaimMode,
    required VoidCallback cancelAutoScroll,
  });

  /// Returns true if scrollbar is currently being dragged.
  bool get isScrollbarDragging;

  /// Handles scrollbar drag movement.
  void handleScrollbarDrag(Offset position);

  /// Clears scrollbar drag state.
  void clearScrollbarDragState();

  /// Checks scrollbar hover for cursor updates.
  bool checkScrollbarHover(Offset position);

  /// Shows scrollbars and schedules auto-hide.
  void showScrollbarsAndScheduleHide();

  // ==================== Streaming Module Delegation ====================

  /// Cancels auto-scroll for streaming mode.
  void cancelAutoScroll();

  // ==================== Coordinate Translation ====================

  /// Denormalizes Y values from normalized (0-1) space to actual data values.
  ///
  /// Used when converting screen coordinates back to data values in perSeries mode.
  /// Returns the input values unchanged if not in perSeries mode.
  ///
  /// [normalizedStartY] and [normalizedEndY] are in 0-1 normalized space.
  /// [seriesId] is optional - if null, uses first series for translation.
  (double startY, double endY) denormalizeYRange(
    double normalizedStartY,
    double normalizedEndY, {
    String? seriesId,
  });

  /// Gets the actual Y data range for snapping calculations.
  ///
  /// In perSeries mode, returns the axis bounds (actual data range).
  /// In other modes, returns the transform's Y range.
  (double min, double max) getActualYRange();

  /// Whether perSeries normalization mode is active.
  bool get isPerSeriesMode;
}

/// Manages all pointer event handling for the chart.
///
/// This module encapsulates:
/// - Pointer down/move/up/hover/scroll event handling
/// - Annotation drag state (resize, move for all annotation types)
/// - Hit test throttling for performance
/// - Coordinate conversion and transform application
///
/// **Design Pattern**: Delegate pattern with clear interface boundary.
/// ChartRenderBox owns the spatial index and transform state, while this
/// module handles all event dispatch and annotation drag logic.
class EventHandlerManager {
  EventHandlerManager({required EventHandlerDelegate delegate}) : _delegate = delegate;

  final EventHandlerDelegate _delegate;

  // ==========================================================================
  // Resize State
  // ==========================================================================

  /// Current resize direction (if resizing annotation).
  ResizeDirection? _activeResizeDirection;

  /// Annotation being resized.
  RangeAnnotationElement? _resizingAnnotation;

  /// Starting bounds for resize operation.
  Rect? _resizeStartBounds;

  // ==========================================================================
  // RangeAnnotation Move State
  // ==========================================================================

  /// Annotation being moved.
  RangeAnnotationElement? _movingAnnotation;

  /// Starting position for move operation.
  Offset? _moveStartPosition;

  /// Starting bounds for move operation.
  Rect? _moveStartBounds;

  // ==========================================================================
  // TextAnnotation Move State
  // ==========================================================================

  /// TextAnnotation being moved.
  TextAnnotationElement? _movingTextAnnotation;

  /// Starting position for TextAnnotation move.
  Offset? _moveTextStartPosition;

  // ==========================================================================
  // PointAnnotation Move State
  // ==========================================================================

  /// PointAnnotation being moved.
  PointAnnotationElement? _movingPointAnnotation;

  /// Original data point index before drag.
  int? _originalDataPointIndex;

  /// Candidate data point index during drag.
  int? _candidateDataPointIndex;

  // ==========================================================================
  // ThresholdAnnotation Move State
  // ==========================================================================

  /// ThresholdAnnotation being moved.
  ThresholdAnnotationElement? _movingThresholdAnnotation;

  /// Starting position for threshold move.
  Offset? _moveThresholdStartPosition;

  /// Original value in data coordinates.
  double? _moveThresholdStartValue;

  // ==========================================================================
  // PinAnnotation Move State
  // ==========================================================================

  /// PinAnnotation being moved.
  PinAnnotationElement? _movingPinAnnotation;

  /// Starting position for pin move.
  Offset? _movePinStartPosition;

  /// Original X in data coordinates.
  double? _movePinStartX;

  /// Original Y in data coordinates.
  double? _movePinStartY;

  // ==========================================================================
  // Potential Drag State (Click-and-Hold Pattern)
  // ==========================================================================

  /// Minimum movement to trigger drag.
  static const double _dragThresholdPixels = 5.0;

  /// Potential PointAnnotation drag.
  PointAnnotationElement? _potentialDragPointAnnotation;
  Offset? _potentialDragStartPosition;

  /// Potential RangeAnnotation drag.
  RangeAnnotationElement? _potentialDragRangeAnnotation;
  Offset? _potentialDragRangeStartPosition;
  Rect? _potentialDragRangeStartBounds;

  /// Potential TextAnnotation drag.
  TextAnnotationElement? _potentialDragTextAnnotation;
  Offset? _potentialDragTextStartPosition;

  /// Potential ThresholdAnnotation drag.
  ThresholdAnnotationElement? _potentialDragThresholdAnnotation;
  Offset? _potentialDragThresholdStartPosition;

  /// Potential PinAnnotation drag.
  PinAnnotationElement? _potentialDragPinAnnotation;
  Offset? _potentialDragPinStartPosition;

  // ==========================================================================
  // LegendAnnotation Move State
  // ==========================================================================

  /// LegendAnnotation being moved.
  LegendAnnotationElement? _movingLegendAnnotation;

  /// Starting position for legend move.
  Offset? _moveLegendStartPosition;

  /// Potential LegendAnnotation drag.
  LegendAnnotationElement? _potentialDragLegendAnnotation;
  Offset? _potentialDragLegendStartPosition;

  // ==========================================================================
  // Pan State
  // ==========================================================================

  /// Last pan position (for calculating delta during middle-button drag).
  Offset? _lastPanPosition;

  // ==========================================================================
  // Cursor and Hover State
  // ==========================================================================

  /// Current cursor position (for crosshair rendering).
  Offset? _cursorPosition;

  /// Gets the current cursor position for crosshair rendering.
  Offset? get cursorPosition => _cursorPosition;

  /// Tracks the tapped marker for tap-triggered tooltips.
  HoveredMarkerInfo? _tappedMarker;

  /// Gets the tapped marker for tooltip rendering.
  HoveredMarkerInfo? get tappedMarker => _tappedMarker;

  // ==========================================================================
  // Hit Test Throttling
  // ==========================================================================

  /// Pending hover position for deferred hit testing.
  Offset? _pendingHitTestPosition;

  /// Timer for debouncing hit testing during rapid hover movements.
  Timer? _hitTestDebounceTimer;

  /// Throttle duration for hit testing (milliseconds).
  static const Duration _hitTestThrottleDuration = Duration(milliseconds: 50);

  // ==========================================================================
  // Lifecycle
  // ==========================================================================

  /// Disposes of resources.
  void dispose() {
    _hitTestDebounceTimer?.cancel();
    _hitTestDebounceTimer = null;
  }

  // ==========================================================================
  // Main Event Dispatcher
  // ==========================================================================

  /// Main event handler - dispatches to specific handlers.
  void handleEvent(PointerEvent event) {
    final coordinator = _delegate.coordinator;

    // Modal states block all events except themselves
    // EXCEPTION: rangeAnnotationCreation mode needs pointer events to work
    if (coordinator.isModal && coordinator.currentMode != InteractionMode.rangeAnnotationCreation) {
      return;
    }

    // CRITICAL: Use event.localPosition for current position
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

  // ==========================================================================
  // Pointer Down Handler
  // ==========================================================================

  void _handlePointerDown(PointerDownEvent event, Offset position) {
    final coordinator = _delegate.coordinator;

    // PRIORITY 1: Check if pointer is on scrollbar (highest priority)
    if (_delegate.hitTestScrollbars(
      position,
      event.buttons,
      isModal: coordinator.isModal,
      onClaimMode: () => coordinator.claimMode(InteractionMode.scrollbarDragging),
      cancelAutoScroll: _delegate.cancelAutoScroll,
    )) {
      return; // Scrollbar claimed the event
    }

    // Use unified hit testing with priority-based conflict resolution
    final hitElement = _delegate.hitTestElements(position);

    coordinator.startInteraction(position, element: hitElement);

    // Check if we hit a resize handle (priority 7)
    if (event.buttons == kPrimaryMouseButton && hitElement is ResizeHandleElement) {
      final annotation = hitElement.parentAnnotation;
      final direction = hitElement.direction;

      // Only RangeAnnotationElement supports resizing currently
      if (annotation is! RangeAnnotationElement) {
        return;
      }

      // Select the annotation first if not already selected
      if (!annotation.isSelected) {
        coordinator.selectElement(annotation);
      }

      _activeResizeDirection = direction;
      _resizingAnnotation = annotation;
      _resizeStartBounds = annotation.bounds;
      coordinator.claimMode(InteractionMode.resizingAnnotation, element: annotation);
      _delegate.markNeedsPaint();
      return;
    }

    // Per conflict resolution: Different buttons have different behaviors
    if (event.buttons == kMiddleMouseButton) {
      // Check if pan is enabled
      final enablePan = _delegate.interactionConfig?.enablePan ?? true;
      if (!enablePan) {
        return;
      }

      // Middle-click: EXCLUSIVELY pan (per scenario 6)
      coordinator.claimMode(InteractionMode.panning);
      _lastPanPosition = position;
      _delegate.showScrollbarsAndScheduleHide();
    } else if (event.buttons == kSecondaryMouseButton) {
      // Right-click: EXCLUSIVELY context menu (per scenario 8)
      coordinator.claimMode(InteractionMode.contextMenuOpen, element: hitElement);
    } else if (event.buttons == kPrimaryMouseButton) {
      // Left-click: Select, or start drag/box-select (determined on move)
      if (hitElement != null) {
        _handlePrimaryButtonDownOnElement(hitElement, event, position);
      } else {
        // Clicked on empty area - clear selection and prepare for box select
        coordinator.clearSelection();
        _delegate.rebuildSpatialIndex();
        _delegate.onEmptyAreaClick?.call(position, event);
        _delegate.markNeedsPaint();
      }
    }
  }

  /// Handles primary button down on a specific element.
  void _handlePrimaryButtonDownOnElement(ChartElement hitElement, PointerDownEvent event, Offset position) {
    final coordinator = _delegate.coordinator;

    // Check for various annotation types that support potential drag
    if (hitElement is RangeAnnotationElement) {
      _potentialDragRangeAnnotation = hitElement;
      _potentialDragRangeStartPosition = position;
      _potentialDragRangeStartBounds = hitElement.bounds;
    } else if (hitElement is TextAnnotationElement && hitElement.annotation.allowDragging) {
      _potentialDragTextAnnotation = hitElement;
      _potentialDragTextStartPosition = position;
    } else if (hitElement is ThresholdAnnotationElement && hitElement.annotation.allowDragging) {
      _potentialDragThresholdAnnotation = hitElement;
      _potentialDragThresholdStartPosition = position;
    } else if (hitElement is PinAnnotationElement && hitElement.annotation.allowDragging) {
      _potentialDragPinAnnotation = hitElement;
      _potentialDragPinStartPosition = position;
    } else if (hitElement is LegendAnnotationElement && hitElement.annotation.legendStyle.allowDragging) {
      _potentialDragLegendAnnotation = hitElement;
      _potentialDragLegendStartPosition = position;
    } else if (hitElement is PointAnnotationElement && hitElement.annotation.allowDragging) {
      _potentialDragPointAnnotation = hitElement;
      _potentialDragStartPosition = position;
    } else {
      // Check if selection is enabled
      final enableSelection = _delegate.interactionConfig?.enableSelection ?? true;
      if (!enableSelection) {
        return;
      }

      // Clicked on element - select it (or toggle if Ctrl)
      if (coordinator.isCtrlPressed) {
        coordinator.toggleElementSelection(hitElement);
      } else {
        coordinator.selectElement(hitElement);
      }
      _delegate.rebuildSpatialIndex();
      coordinator.claimMode(InteractionMode.selecting, element: hitElement);
      _delegate.onElementClick?.call(hitElement, event);
    }
  }

  // ==========================================================================
  // Pointer Move Handler
  // ==========================================================================

  void _handlePointerMove(PointerMoveEvent event, Offset position) {
    final coordinator = _delegate.coordinator;

    // Check potential drags first (before isInteracting check)
    if (_checkPotentialDrags(event, position)) {
      return;
    }

    // PRIORITY 1: Handle scrollbar drag if active
    if (_delegate.isScrollbarDragging) {
      _delegate.handleScrollbarDrag(position);
      return;
    }

    // PRIORITY 1.5: Handle range annotation creation mode
    if (coordinator.currentMode == InteractionMode.rangeAnnotationCreation && event.buttons == kPrimaryMouseButton) {
      if (!coordinator.isInteracting) {
        coordinator.startInteraction(position);
      }

      final startPos = coordinator.interactionStartPosition;
      if (startPos != null) {
        coordinator.updateBoxSelection(startPos, position);
        _delegate.markNeedsPaint();
      }
      return;
    }

    if (!coordinator.isInteracting) return;

    final startPos = coordinator.interactionStartPosition;
    if (startPos == null) return;

    // Handle active drags
    if (_handleActiveDrags(event, position, startPos)) {
      return;
    }

    // Handle pan and box selection
    _handlePanAndBoxSelection(event, position, startPos);
  }

  /// Checks and handles potential drag thresholds.
  /// Returns true if a potential drag was being checked (handled).
  bool _checkPotentialDrags(PointerMoveEvent event, Offset position) {
    // TextAnnotation potential drag
    if (_potentialDragTextAnnotation != null && _potentialDragTextStartPosition != null) {
      final dragDistance = (position - _potentialDragTextStartPosition!).distance;

      if (dragDistance >= _dragThresholdPixels) {
        final hitElement = _potentialDragTextAnnotation!;
        _movingTextAnnotation = hitElement;
        _moveTextStartPosition = _potentialDragTextStartPosition;

        _delegate.coordinator.startInteraction(_potentialDragTextStartPosition!, element: hitElement);
        _delegate.coordinator.claimMode(InteractionMode.draggingAnnotation, element: hitElement);

        _potentialDragTextAnnotation = null;
        _potentialDragTextStartPosition = null;

        _performTextAnnotationMove(position);
        _delegate.markNeedsPaint();
        return true;
      }
      return true; // Still within threshold
    }

    // ThresholdAnnotation potential drag
    if (_potentialDragThresholdAnnotation != null && _potentialDragThresholdStartPosition != null) {
      final dragDistance = (position - _potentialDragThresholdStartPosition!).distance;

      if (dragDistance >= _dragThresholdPixels) {
        final hitElement = _potentialDragThresholdAnnotation!;
        _movingThresholdAnnotation = hitElement;
        _moveThresholdStartPosition = _potentialDragThresholdStartPosition;
        _moveThresholdStartValue = hitElement.annotation.value;

        _delegate.coordinator.startInteraction(_potentialDragThresholdStartPosition!, element: hitElement);
        _delegate.coordinator.claimMode(InteractionMode.draggingAnnotation, element: hitElement);

        _potentialDragThresholdAnnotation = null;
        _potentialDragThresholdStartPosition = null;

        _performThresholdAnnotationMove(position);
        _delegate.markNeedsPaint();
        return true;
      }
      return true;
    }

    // PinAnnotation potential drag
    if (_potentialDragPinAnnotation != null && _potentialDragPinStartPosition != null) {
      final dragDistance = (position - _potentialDragPinStartPosition!).distance;

      if (dragDistance >= _dragThresholdPixels) {
        final hitElement = _potentialDragPinAnnotation!;
        _movingPinAnnotation = hitElement;
        _movePinStartPosition = _potentialDragPinStartPosition;
        _movePinStartX = hitElement.annotation.x;
        _movePinStartY = hitElement.annotation.y;

        _delegate.coordinator.startInteraction(_potentialDragPinStartPosition!, element: hitElement);
        _delegate.coordinator.claimMode(InteractionMode.draggingAnnotation, element: hitElement);
        _delegate.coordinator.selectElement(hitElement);

        _potentialDragPinAnnotation = null;
        _potentialDragPinStartPosition = null;

        _performPinAnnotationMove(position);
        _delegate.markNeedsPaint();
        return true;
      }
      return true;
    }

    // LegendAnnotation potential drag
    if (_potentialDragLegendAnnotation != null && _potentialDragLegendStartPosition != null) {
      final dragDistance = (position - _potentialDragLegendStartPosition!).distance;

      if (dragDistance >= _dragThresholdPixels) {
        final hitElement = _potentialDragLegendAnnotation!;
        _movingLegendAnnotation = hitElement;
        _moveLegendStartPosition = _potentialDragLegendStartPosition;

        _delegate.coordinator.startInteraction(_potentialDragLegendStartPosition!, element: hitElement);
        _delegate.coordinator.claimMode(InteractionMode.draggingAnnotation, element: hitElement);

        _potentialDragLegendAnnotation = null;
        _potentialDragLegendStartPosition = null;

        _performLegendAnnotationMove(position);
        _delegate.markNeedsPaint();
        return true;
      }
      return true;
    }

    // RangeAnnotation potential drag
    if (_potentialDragRangeAnnotation != null && _potentialDragRangeStartPosition != null && _potentialDragRangeStartBounds != null) {
      final dragDistance = (position - _potentialDragRangeStartPosition!).distance;

      if (dragDistance >= _dragThresholdPixels) {
        final hitElement = _potentialDragRangeAnnotation!;
        _movingAnnotation = hitElement;
        _moveStartPosition = _potentialDragRangeStartPosition;
        _moveStartBounds = _potentialDragRangeStartBounds;

        _delegate.coordinator.startInteraction(_potentialDragRangeStartPosition!, element: hitElement);
        _delegate.coordinator.claimMode(InteractionMode.draggingAnnotation, element: hitElement);

        _potentialDragRangeAnnotation = null;
        _potentialDragRangeStartPosition = null;
        _potentialDragRangeStartBounds = null;

        _performMove(position);
        _delegate.markNeedsPaint();
        return true;
      }
      return true;
    }

    // PointAnnotation potential drag
    if (_potentialDragPointAnnotation != null && _potentialDragStartPosition != null) {
      final dragDistance = (position - _potentialDragStartPosition!).distance;
      if (dragDistance >= _dragThresholdPixels) {
        final hitElement = _potentialDragPointAnnotation!;

        _movingPointAnnotation = hitElement;
        _originalDataPointIndex = hitElement.annotation.dataPointIndex;
        _candidateDataPointIndex = hitElement.annotation.dataPointIndex;

        _delegate.coordinator.startInteraction(_potentialDragStartPosition!, element: hitElement);
        _delegate.coordinator.claimMode(InteractionMode.draggingAnnotation, element: hitElement);

        _potentialDragPointAnnotation = null;
        _potentialDragStartPosition = null;

        _performPointAnnotationMove(position);
        _delegate.markNeedsPaint();
        return true;
      }
      return true;
    }

    return false;
  }

  /// Handles active annotation drags.
  /// Returns true if an active drag was handled.
  bool _handleActiveDrags(PointerMoveEvent event, Offset position, Offset startPos) {
    final coordinator = _delegate.coordinator;

    // Handle resize dragging
    if (coordinator.currentMode == InteractionMode.resizingAnnotation &&
        _resizingAnnotation != null &&
        _activeResizeDirection != null &&
        _resizeStartBounds != null) {
      _performResize(position, startPos);
      _delegate.markNeedsPaint();
      return true;
    }

    // Handle RangeAnnotation move dragging
    if (coordinator.currentMode == InteractionMode.draggingAnnotation &&
        _movingAnnotation != null &&
        _moveStartPosition != null &&
        _moveStartBounds != null) {
      _performMove(position);
      _delegate.markNeedsPaint();
      return true;
    }

    // Handle TextAnnotation move dragging
    if (coordinator.currentMode == InteractionMode.draggingAnnotation && _movingTextAnnotation != null && _moveTextStartPosition != null) {
      _performTextAnnotationMove(position);
      _delegate.markNeedsPaint();
      return true;
    }

    // Handle ThresholdAnnotation move dragging
    if (coordinator.currentMode == InteractionMode.draggingAnnotation && _movingThresholdAnnotation != null && _moveThresholdStartPosition != null) {
      _performThresholdAnnotationMove(position);
      _delegate.markNeedsPaint();
      return true;
    }

    // Handle PinAnnotation move dragging
    if (coordinator.currentMode == InteractionMode.draggingAnnotation && _movingPinAnnotation != null && _movePinStartPosition != null) {
      _performPinAnnotationMove(position);
      _delegate.markNeedsPaint();
      return true;
    }

    // Handle LegendAnnotation move dragging
    if (coordinator.currentMode == InteractionMode.draggingAnnotation && _movingLegendAnnotation != null && _moveLegendStartPosition != null) {
      _performLegendAnnotationMove(position);
      _delegate.markNeedsPaint();
      return true;
    }

    // Handle PointAnnotation move dragging
    if (coordinator.currentMode == InteractionMode.draggingAnnotation && _movingPointAnnotation != null) {
      _performPointAnnotationMove(position);
      _delegate.markNeedsPaint();
      return true;
    }

    return false;
  }

  /// Handles panning and box selection.
  void _handlePanAndBoxSelection(PointerMoveEvent event, Offset position, Offset startPos) {
    final coordinator = _delegate.coordinator;

    // Middle-button drag = pan
    if (event.buttons == kMiddleMouseButton && coordinator.currentMode == InteractionMode.panning) {
      if (_lastPanPosition != null && _delegate.transform != null && _delegate.originalTransform != null) {
        final plotDelta = _delegate.widgetToPlot(position) - _delegate.widgetToPlot(_lastPanPosition!);

        final (clampedDx, clampedDy) = _delegate.clampPanDelta(-plotDelta.dx, -plotDelta.dy);

        _delegate.transform = _delegate.transform!.pan(clampedDx, clampedDy);
        _delegate.updateAxesFromTransform();
        _lastPanPosition = position;
        _delegate.markNeedsPaint();
      }
      return;
    }

    // Left-button drag: datapoint drag, annotation drag, or box select
    if (event.buttons == kPrimaryMouseButton) {
      final startElement = coordinator.interactionStartElement;

      // Update box selection rectangle if already in box select mode
      if (coordinator.currentMode == InteractionMode.boxSelecting) {
        coordinator.updateBoxSelection(startPos, position);
        final newRect = coordinator.boxSelectionRect;

        _cursorPosition = position;

        if (newRect != null) {
          final previewElements = _delegate.hitTestRect(newRect);
          coordinator.updatePreviewSelection(previewElements.toSet());
        }

        _delegate.markNeedsPaint();
        return;
      }

      if (startElement != null && startElement.isDraggable) {
        if (startElement.elementType == ChartElementType.datapoint) {
          coordinator.claimMode(InteractionMode.draggingDataPoint, element: startElement);
        } else if (startElement.elementType == ChartElementType.annotation) {
          coordinator.claimMode(InteractionMode.draggingAnnotation, element: startElement);
        }
      } else if (coordinator.shouldStartBoxSelect(position)) {
        coordinator.claimMode(InteractionMode.boxSelecting);
        coordinator.updateBoxSelection(startPos, position);
        _delegate.markNeedsPaint();
      }
    }
  }

  // ==========================================================================
  // Pointer Up Handler
  // ==========================================================================

  void _handlePointerUp(PointerUpEvent event, Offset position) {
    final coordinator = _delegate.coordinator;

    // Clear scrollbar drag state if active
    if (_delegate.isScrollbarDragging) {
      _delegate.clearScrollbarDragState();
      coordinator.endInteraction();
      coordinator.releaseMode();
      return;
    }

    // Complete box selection if active
    if (coordinator.currentMode == InteractionMode.boxSelecting) {
      _completeBoxSelection();
    }

    // Complete range annotation creation if active
    if (coordinator.currentMode == InteractionMode.rangeAnnotationCreation) {
      _completeRangeAnnotationCreation();
      return;
    }

    bool completedResizeOrMove = false;

    // Clear resize state
    if (_resizingAnnotation != null) {
      completedResizeOrMove = true;
      _completeResize();
    }

    // Clear move state
    if (_movingAnnotation != null) {
      completedResizeOrMove = true;
      _completeRangeAnnotationMove();
    }

    // Handle potential drags that never exceeded threshold
    _handlePotentialDragReleases(event, completedResizeOrMove);

    // Clear annotation move states
    _clearAnnotationMoveStates(event);

    // Clear pan state
    _completePan();

    // Handle tap on marker for tap-triggered tooltips
    _handleTapForTooltip();

    // Clear cursor position
    _cursorPosition = null;

    // Release interaction
    coordinator.endInteraction();
    coordinator.releaseMode();
    _delegate.markNeedsPaint();
  }

  void _completeBoxSelection() {
    final coordinator = _delegate.coordinator;
    final boxRect = coordinator.boxSelectionRect;
    if (boxRect != null) {
      final selectedElements = _delegate.hitTestRect(boxRect);
      coordinator.clearPreviewSelection();
      coordinator.addToSelection(selectedElements.toSet());
    }
  }

  void _completeRangeAnnotationCreation() {
    final coordinator = _delegate.coordinator;
    final boxRect = coordinator.boxSelectionRect;
    if (boxRect != null && _delegate.onRangeCreationComplete != null) {
      final seriesElements = _delegate.elements.whereType<SeriesElement>();
      if (seriesElements.isNotEmpty) {
        final seriesElement = seriesElements.first;
        final transform = seriesElement.transform;
        final plotArea = _delegate.plotArea;

        // For X coordinates, use transform.plotToData as usual
        final topLeft = transform.plotToData(boxRect.left, boxRect.top);
        final bottomRight = transform.plotToData(boxRect.right, boxRect.bottom);

        final startX = topLeft.dx < bottomRight.dx ? topLeft.dx : bottomRight.dx;
        final endX = topLeft.dx > bottomRight.dx ? topLeft.dx : bottomRight.dx;

        double startY;
        double endY;

        if (_delegate.isPerSeriesMode) {
          // For perSeries mode, calculate normalized Y the SAME way crosshair does:
          // normalizedY = (plotArea.bottom - pixelY) / plotArea.height
          // This gives a true 0-1 value (0 at bottom, 1 at top)
          final normalizedTopY = (plotArea.bottom - boxRect.top) / plotArea.height;
          final normalizedBottomY = (plotArea.bottom - boxRect.bottom) / plotArea.height;

          // Denormalize using axisBounds (same as crosshair)
          final (denormStartY, denormEndY) = _delegate.denormalizeYRange(
            normalizedBottomY < normalizedTopY ? normalizedBottomY : normalizedTopY,
            normalizedBottomY > normalizedTopY ? normalizedBottomY : normalizedTopY,
          );
          startY = denormStartY;
          endY = denormEndY;
        } else {
          // Non-perSeries mode: use plotToData result directly
          startY = topLeft.dy < bottomRight.dy ? topLeft.dy : bottomRight.dy;
          endY = topLeft.dy > bottomRight.dy ? topLeft.dy : bottomRight.dy;
        }

        coordinator.endInteraction();
        _delegate.onRangeCreationComplete!(startX, endX, startY, endY);
        _delegate.markNeedsPaint();
        return;
      }
    }

    coordinator.endInteraction();
    coordinator.releaseMode();
    _delegate.markNeedsPaint();
  }

  void _completeResize() {
    final resizedBounds = _resizingAnnotation!.bounds;
    _resizingAnnotation!.clearTempBounds();

    final resizedAnnotation = _resizingAnnotation!.annotation;
    final resizeDirection = _activeResizeDirection;

    _resizingAnnotation = null;
    _activeResizeDirection = null;
    _resizeStartBounds = null;

    if (_delegate.onAnnotationChanged != null) {
      final seriesElements = _delegate.elements.whereType<SeriesElement>();
      if (seriesElements.isNotEmpty) {
        final seriesElement = seriesElements.first;
        final transform = seriesElement.transform;
        final plotArea = _delegate.plotArea;

        // For X coordinates, use transform.plotToData as usual
        final leftData = transform.plotToData(resizedBounds.left, resizedBounds.top);
        final rightData = transform.plotToData(resizedBounds.right, resizedBounds.bottom);

        var newStartX = leftData.dx;
        var newEndX = rightData.dx;
        double? newStartY;
        double? newEndY;

        if (resizedAnnotation.startY != null && resizedAnnotation.endY != null) {
          if (_delegate.isPerSeriesMode) {
            // For perSeries mode, calculate normalized Y the SAME way crosshair does:
            // normalizedY = (plotArea.bottom - pixelY) / plotArea.height
            final normalizedTopY = (plotArea.bottom - resizedBounds.top) / plotArea.height;
            final normalizedBottomY = (plotArea.bottom - resizedBounds.bottom) / plotArea.height;

            // Denormalize using axisBounds (same as crosshair)
            final (denormStartY, denormEndY) = _delegate.denormalizeYRange(
              normalizedBottomY < normalizedTopY ? normalizedBottomY : normalizedTopY,
              normalizedBottomY > normalizedTopY ? normalizedBottomY : normalizedTopY,
            );
            newStartY = denormStartY;
            newEndY = denormEndY;
          } else {
            // Non-perSeries mode: use plotToData result directly
            newStartY = rightData.dy;
            newEndY = leftData.dy;
          }
        }

        // Apply snapping if enabled
        if (resizedAnnotation.snapToValue) {
          (newStartX, newEndX, newStartY, newEndY) =
              _applyResizeSnapping(resizedAnnotation, transform, resizeDirection, newStartX, newEndX, newStartY, newEndY);
        }

        final updatedAnnotation = resizedAnnotation.copyWith(
          startX: resizedAnnotation.startX != null ? newStartX : null,
          endX: resizedAnnotation.endX != null ? newEndX : null,
          startY: resizedAnnotation.startY != null ? newStartY : null,
          endY: resizedAnnotation.endY != null ? newEndY : null,
        );

        _delegate.onAnnotationChanged!(resizedAnnotation.id, updatedAnnotation);
      }
    }
  }

  (double, double, double?, double?) _applyResizeSnapping(
    RangeAnnotation annotation,
    ChartTransform transform,
    ResizeDirection? direction,
    double startX,
    double endX,
    double? startY,
    double? endY,
  ) {
    final xTolerance = (transform.dataXMax - transform.dataXMin) * annotation.snapTolerance;
    // Use actual Y range for tolerance (not transform range which is 0-1 in perSeries mode)
    final (yMin, yMax) = _delegate.getActualYRange();
    final yTolerance = (yMax - yMin) * annotation.snapTolerance;

    final needsSnapStartX = direction == ResizeDirection.left || direction == ResizeDirection.topLeft || direction == ResizeDirection.bottomLeft;
    final needsSnapEndX = direction == ResizeDirection.right || direction == ResizeDirection.topRight || direction == ResizeDirection.bottomRight;
    final needsSnapStartY =
        direction == ResizeDirection.bottom || direction == ResizeDirection.bottomLeft || direction == ResizeDirection.bottomRight;
    final needsSnapEndY = direction == ResizeDirection.top || direction == ResizeDirection.topLeft || direction == ResizeDirection.topRight;

    var newStartX = startX;
    var newEndX = endX;
    var newStartY = startY;
    var newEndY = endY;

    if (needsSnapStartX) {
      final snapped = _findNearestDataValue(startX, axis: 'x', tolerance: xTolerance);
      if (snapped != null) newStartX = snapped;
    }
    if (needsSnapEndX) {
      final snapped = _findNearestDataValue(endX, axis: 'x', tolerance: xTolerance);
      if (snapped != null) newEndX = snapped;
    }
    if (needsSnapStartY && startY != null) {
      final snapped = _findNearestDataValue(startY, axis: 'y', tolerance: yTolerance);
      if (snapped != null) newStartY = snapped;
    }
    if (needsSnapEndY && endY != null) {
      final snapped = _findNearestDataValue(endY, axis: 'y', tolerance: yTolerance);
      if (snapped != null) newEndY = snapped;
    }

    return (newStartX, newEndX, newStartY, newEndY);
  }

  void _completeRangeAnnotationMove() {
    final movedBounds = _movingAnnotation!.bounds;
    _movingAnnotation!.clearTempBounds();

    final movedAnnotation = _movingAnnotation!.annotation;

    _movingAnnotation = null;
    _moveStartPosition = null;
    _moveStartBounds = null;

    if (_delegate.onAnnotationChanged != null) {
      final seriesElements = _delegate.elements.whereType<SeriesElement>();
      if (seriesElements.isNotEmpty) {
        final seriesElement = seriesElements.first;
        final transform = seriesElement.transform;
        final plotArea = _delegate.plotArea;

        // For X coordinates, use transform.plotToData as usual
        final leftData = transform.plotToData(movedBounds.left, movedBounds.top);
        final rightData = transform.plotToData(movedBounds.right, movedBounds.bottom);

        var newStartX = leftData.dx;
        var newEndX = rightData.dx;
        double? newStartY;
        double? newEndY;

        if (movedAnnotation.startY != null && movedAnnotation.endY != null) {
          if (_delegate.isPerSeriesMode) {
            // For perSeries mode, calculate normalized Y the SAME way crosshair does:
            // normalizedY = (plotArea.bottom - pixelY) / plotArea.height
            final normalizedTopY = (plotArea.bottom - movedBounds.top) / plotArea.height;
            final normalizedBottomY = (plotArea.bottom - movedBounds.bottom) / plotArea.height;

            // Denormalize using axisBounds (same as crosshair)
            final (denormStartY, denormEndY) = _delegate.denormalizeYRange(
              normalizedBottomY < normalizedTopY ? normalizedBottomY : normalizedTopY,
              normalizedBottomY > normalizedTopY ? normalizedBottomY : normalizedTopY,
            );
            newStartY = denormStartY;
            newEndY = denormEndY;
          } else {
            // Non-perSeries mode: use plotToData result directly
            newStartY = rightData.dy;
            newEndY = leftData.dy;
          }
        }

        // Apply snapping if enabled
        if (movedAnnotation.snapToValue) {
          final xTolerance = (transform.dataXMax - transform.dataXMin) * movedAnnotation.snapTolerance;
          // Use actual Y range for tolerance (not transform range which is 0-1 in perSeries mode)
          final (yMin, yMax) = _delegate.getActualYRange();
          final yTolerance = (yMax - yMin) * movedAnnotation.snapTolerance;

          if (movedAnnotation.startX != null && movedAnnotation.endX != null) {
            final snappedStartX = _findNearestDataValue(newStartX, axis: 'x', tolerance: xTolerance);
            if (snappedStartX != null) {
              final width = newEndX - newStartX;
              newStartX = snappedStartX;
              newEndX = newStartX + width;
            }
          }

          if (movedAnnotation.startY != null && movedAnnotation.endY != null && newStartY != null && newEndY != null) {
            final snappedStartY = _findNearestDataValue(newStartY, axis: 'y', tolerance: yTolerance);
            if (snappedStartY != null) {
              final height = newEndY - newStartY;
              newStartY = snappedStartY;
              newEndY = newStartY + height;
            }
          }
        }

        final updatedAnnotation = movedAnnotation.copyWith(
          startX: movedAnnotation.startX != null ? newStartX : null,
          endX: movedAnnotation.endX != null ? newEndX : null,
          startY: movedAnnotation.startY != null ? newStartY : null,
          endY: movedAnnotation.endY != null ? newEndY : null,
        );

        _delegate.onAnnotationChanged!(movedAnnotation.id, updatedAnnotation);
      }
    }
  }

  void _handlePotentialDragReleases(PointerUpEvent event, bool completedResizeOrMove) {
    // TextAnnotation
    if (_potentialDragTextAnnotation != null) {
      _handlePotentialDragClick(_potentialDragTextAnnotation!, event);
      _potentialDragTextAnnotation = null;
      _potentialDragTextStartPosition = null;
    }

    // ThresholdAnnotation
    if (_potentialDragThresholdAnnotation != null) {
      _handlePotentialDragClick(_potentialDragThresholdAnnotation!, event);
      _potentialDragThresholdAnnotation = null;
      _potentialDragThresholdStartPosition = null;
    }

    // PinAnnotation
    if (_potentialDragPinAnnotation != null) {
      _handlePotentialDragClick(_potentialDragPinAnnotation!, event);
      _potentialDragPinAnnotation = null;
      _potentialDragPinStartPosition = null;
    }

    // LegendAnnotation
    if (_potentialDragLegendAnnotation != null) {
      _handlePotentialDragClick(_potentialDragLegendAnnotation!, event);
      _potentialDragLegendAnnotation = null;
      _potentialDragLegendStartPosition = null;
    }

    // RangeAnnotation (skip if just completed resize/move)
    if (_potentialDragRangeAnnotation != null && !completedResizeOrMove) {
      _handlePotentialDragClick(_potentialDragRangeAnnotation!, event);
      _delegate.rebuildSpatialIndex();
    }
    if (_potentialDragRangeAnnotation != null) {
      _potentialDragRangeAnnotation = null;
      _potentialDragRangeStartPosition = null;
      _potentialDragRangeStartBounds = null;
    }

    // PointAnnotation
    if (_potentialDragPointAnnotation != null) {
      _handlePotentialDragClick(_potentialDragPointAnnotation!, event);
      _potentialDragPointAnnotation = null;
      _potentialDragStartPosition = null;
    }
  }

  void _handlePotentialDragClick(ChartElement element, PointerUpEvent event) {
    final coordinator = _delegate.coordinator;

    if (coordinator.isCtrlPressed) {
      coordinator.toggleElementSelection(element);
    } else {
      coordinator.selectElement(element);
    }

    _delegate.onElementClick?.call(element, event);
    _delegate.markNeedsPaint();
  }

  void _clearAnnotationMoveStates(PointerUpEvent event) {
    // PointAnnotation
    if (_movingPointAnnotation != null) {
      final movedAnnotation = _movingPointAnnotation!.annotation;
      final newIndex = _candidateDataPointIndex ?? _originalDataPointIndex ?? movedAnnotation.dataPointIndex;

      _movingPointAnnotation!.clearCandidateIndex();
      _movingPointAnnotation = null;
      _originalDataPointIndex = null;
      _candidateDataPointIndex = null;

      if (_delegate.onAnnotationChanged != null && newIndex != movedAnnotation.dataPointIndex) {
        final updatedAnnotation = movedAnnotation.copyWith(dataPointIndex: newIndex);
        _delegate.onAnnotationChanged!(movedAnnotation.id, updatedAnnotation);
      }
    }

    // TextAnnotation
    if (_movingTextAnnotation != null) {
      final originalPosition = _movingTextAnnotation!.annotation.position;
      final tempPosition = _movingTextAnnotation!.tempPosition;
      final newPosition = tempPosition ?? originalPosition;

      _movingTextAnnotation!.clearTempPosition();
      final movedAnnotation = _movingTextAnnotation!.annotation;

      _movingTextAnnotation = null;
      _moveTextStartPosition = null;

      if (_delegate.onAnnotationChanged != null && newPosition != originalPosition) {
        final updatedAnnotation = movedAnnotation.copyWith(position: newPosition);
        _delegate.onAnnotationChanged!(movedAnnotation.id, updatedAnnotation);
      }
    }

    // ThresholdAnnotation
    if (_movingThresholdAnnotation != null) {
      final originalValue = _movingThresholdAnnotation!.annotation.value;
      final tempValue = _movingThresholdAnnotation!.tempValue;
      final newValue = tempValue ?? originalValue;

      _movingThresholdAnnotation!.clearTempValue();
      final movedAnnotation = _movingThresholdAnnotation!.annotation;

      _movingThresholdAnnotation = null;
      _moveThresholdStartPosition = null;
      _moveThresholdStartValue = null;

      if (_delegate.onAnnotationChanged != null && newValue != originalValue) {
        final updatedAnnotation = movedAnnotation.copyWith(value: newValue);
        _delegate.onAnnotationChanged!(movedAnnotation.id, updatedAnnotation);
      }
    }

    // PinAnnotation
    if (_movingPinAnnotation != null) {
      final originalX = _movingPinAnnotation!.annotation.x;
      final originalY = _movingPinAnnotation!.annotation.y;
      final tempPos = _movingPinAnnotation!.tempPosition;
      final newX = tempPos?.$1 ?? originalX;
      final newY = tempPos?.$2 ?? originalY;

      _movingPinAnnotation!.clearTempPosition();
      final movedAnnotation = _movingPinAnnotation!.annotation;

      _movingPinAnnotation = null;
      _movePinStartPosition = null;
      _movePinStartX = null;
      _movePinStartY = null;

      if (_delegate.onAnnotationChanged != null && (newX != originalX || newY != originalY)) {
        final updatedAnnotation = movedAnnotation.copyWith(x: newX, y: newY);
        _delegate.onAnnotationChanged!(movedAnnotation.id, updatedAnnotation);
      }
    }

    // LegendAnnotation
    if (_movingLegendAnnotation != null) {
      final originalPosition = _movingLegendAnnotation!.annotation.customPosition;
      final tempPosition = _movingLegendAnnotation!.tempPosition;
      final newPosition = tempPosition ?? originalPosition;

      _movingLegendAnnotation!.clearTempPosition();
      final movedAnnotation = _movingLegendAnnotation!.annotation;

      _movingLegendAnnotation = null;
      _moveLegendStartPosition = null;

      if (_delegate.onAnnotationChanged != null && newPosition != originalPosition) {
        final updatedAnnotation = movedAnnotation.copyWith(customPosition: newPosition);
        _delegate.onAnnotationChanged!(movedAnnotation.id, updatedAnnotation);
      }
    }
  }

  void _completePan() {
    final wasPanning = _delegate.coordinator.currentMode == InteractionMode.panning;
    _lastPanPosition = null;

    if (wasPanning) {
      _delegate.updateAxesFromTransform();
      _delegate.rebuildElementsWithTransform();
      _delegate.invalidateSeriesCache();
    }
  }

  void _handleTapForTooltip() {
    final coordinator = _delegate.coordinator;
    final config = _delegate.interactionConfig?.tooltip ?? const TooltipConfig();

    if ((config.triggerMode == TooltipTriggerMode.tap || config.triggerMode == TooltipTriggerMode.both) &&
        coordinator.hoveredMarker != null &&
        !coordinator.isPanning &&
        coordinator.currentMode != InteractionMode.panning) {
      if (_tappedMarker == coordinator.hoveredMarker) {
        _tappedMarker = null;
      } else {
        _tappedMarker = coordinator.hoveredMarker;
      }
    }
  }

  // ==========================================================================
  // Pointer Hover Handler
  // ==========================================================================

  void _handlePointerHover(PointerHoverEvent event, Offset position) {
    final coordinator = _delegate.coordinator;

    _cursorPosition = position;
    _delegate.markNeedsPaint();

    // Check scrollbar hover first
    if (_delegate.checkScrollbarHover(position)) {
      return;
    }

    // Hover is passive during panning
    if (coordinator.isPanning) {
      coordinator.setHoveredElement(null);
      coordinator.setHoveredMarker(null);
      _delegate.onCursorChange?.call(SystemMouseCursors.basic);
      return;
    }

    // Immediate marker highlighting
    _updateHoveredMarker(position);

    // Throttle expensive hit testing
    _pendingHitTestPosition = position;
    _hitTestDebounceTimer?.cancel();
    _hitTestDebounceTimer = Timer(_hitTestThrottleDuration, () {
      _performDeferredHitTest();
    });
  }

  void _performDeferredHitTest() {
    final position = _pendingHitTestPosition;
    if (position == null) return;

    _pendingHitTestPosition = null;

    final hitElement = _delegate.hitTestElements(position);

    if (hitElement is ResizeHandleElement) {
      final cursor = _getCursorForResizeDirection(hitElement.direction);
      _delegate.onCursorChange?.call(cursor);
      _delegate.coordinator.setHoveredElement(hitElement.parentAnnotation);
      _delegate.onElementHover?.call(hitElement.parentAnnotation);
      _delegate.markNeedsPaint();
      return;
    }

    _delegate.onCursorChange?.call(SystemMouseCursors.basic);
    _delegate.coordinator.setHoveredElement(hitElement);
    _delegate.onElementHover?.call(hitElement);
    _delegate.markNeedsPaint();
  }

  void _updateHoveredMarker(Offset widgetPosition) {
    final transform = _delegate.transform;
    if (transform == null) {
      _delegate.coordinator.setHoveredMarker(null);
      return;
    }

    final plotPosition = _delegate.widgetToPlot(widgetPosition);
    const snapRadius = 20.0;

    HoveredMarkerInfo? nearestMarker;
    double minDistance = snapRadius;

    for (final element in _delegate.elements.whereType<SeriesElement>()) {
      final series = element.series;
      if (series is LineChartSeries && !series.showDataPointMarkers) continue;

      for (int i = 0; i < element.series.points.length; i++) {
        final point = element.series.points[i];
        final markerPlotPos = transform.dataToPlot(point.x, point.y);
        final distance = (plotPosition - markerPlotPos).distance;

        if (distance < minDistance) {
          minDistance = distance;
          nearestMarker = HoveredMarkerInfo(
            seriesId: element.id,
            markerIndex: i,
            plotPosition: markerPlotPos,
          );
        }
      }
    }

    final previousMarker = _delegate.coordinator.hoveredMarker;
    _delegate.coordinator.setHoveredMarker(nearestMarker);

    final markerChanged = (previousMarker == null) != (nearestMarker == null) ||
        (previousMarker != null &&
            nearestMarker != null &&
            (previousMarker.seriesId != nearestMarker.seriesId || previousMarker.markerIndex != nearestMarker.markerIndex));

    if (markerChanged) {
      _delegate.invalidateSeriesCache();
    }
  }

  // ==========================================================================
  // Pointer Scroll Handler
  // ==========================================================================

  void _handlePointerScroll(PointerScrollEvent event, Offset position) {
    final coordinator = _delegate.coordinator;

    final enableZoom = _delegate.interactionConfig?.enableZoom ?? true;
    if (!enableZoom) return;

    if (coordinator.currentMode == InteractionMode.scrollbarDragging) return;

    if (coordinator.isShiftPressed && _delegate.transform != null && _delegate.originalTransform != null) {
      coordinator.claimMode(InteractionMode.zooming);

      final double scrollAmount = event.scrollDelta.dy;
      const double zoomSensitivity = 0.0011;
      final double zoomFactor = 1.0 - (scrollAmount * zoomSensitivity);

      final Offset plotPosition = _delegate.widgetToPlot(position);

      // Mouse wheel zoom: no animation for responsive feel during rapid scrolling
      _delegate.zoomChart(zoomFactor, plotCenter: plotPosition, animate: false);

      Future.delayed(const Duration(milliseconds: 200), () {
        if (!coordinator.isDisposed && coordinator.currentMode == InteractionMode.zooming) {
          coordinator.releaseMode();
        }
      });
    } else {
      coordinator.claimMode(InteractionMode.zooming);

      Future.delayed(const Duration(milliseconds: 100), () {
        if (!coordinator.isDisposed && coordinator.currentMode == InteractionMode.zooming) {
          coordinator.releaseMode();
        }
      });
    }
  }

  // ==========================================================================
  // Perform Operations (Drag Logic)
  // ==========================================================================

  void _performResize(Offset currentPosition, Offset startPosition) {
    if (_resizingAnnotation == null || _activeResizeDirection == null || _resizeStartBounds == null) {
      return;
    }

    final delta = currentPosition - startPosition;
    final oldBounds = _resizeStartBounds!;
    Rect newBounds;

    switch (_activeResizeDirection!) {
      case ResizeDirection.topLeft:
        newBounds = Rect.fromLTRB(oldBounds.left + delta.dx, oldBounds.top + delta.dy, oldBounds.right, oldBounds.bottom);
      case ResizeDirection.topRight:
        newBounds = Rect.fromLTRB(oldBounds.left, oldBounds.top + delta.dy, oldBounds.right + delta.dx, oldBounds.bottom);
      case ResizeDirection.bottomLeft:
        newBounds = Rect.fromLTRB(oldBounds.left + delta.dx, oldBounds.top, oldBounds.right, oldBounds.bottom + delta.dy);
      case ResizeDirection.bottomRight:
        newBounds = Rect.fromLTRB(oldBounds.left, oldBounds.top, oldBounds.right + delta.dx, oldBounds.bottom + delta.dy);
      case ResizeDirection.top:
        newBounds = Rect.fromLTRB(oldBounds.left, oldBounds.top + delta.dy, oldBounds.right, oldBounds.bottom);
      case ResizeDirection.right:
        newBounds = Rect.fromLTRB(oldBounds.left, oldBounds.top, oldBounds.right + delta.dx, oldBounds.bottom);
      case ResizeDirection.bottom:
        newBounds = Rect.fromLTRB(oldBounds.left, oldBounds.top, oldBounds.right, oldBounds.bottom + delta.dy);
      case ResizeDirection.left:
        newBounds = Rect.fromLTRB(oldBounds.left + delta.dx, oldBounds.top, oldBounds.right, oldBounds.bottom);
    }

    const minSize = 40.0;
    if (newBounds.width < minSize || newBounds.height < minSize) {
      return;
    }

    _resizingAnnotation!.updateBounds(newBounds);

    // Update temporary edge values for value label display
    final seriesElements = _delegate.elements.whereType<SeriesElement>();
    if (seriesElements.isNotEmpty) {
      final seriesElement = seriesElements.first;
      final transform = seriesElement.transform;
      final annotation = _resizingAnnotation!.annotation;

      final leftData = transform.plotToData(newBounds.left, newBounds.top);
      final rightData = transform.plotToData(newBounds.right, newBounds.bottom);

      double? tempStartX;
      double? tempEndX;
      double? tempStartY;
      double? tempEndY;

      if ((_activeResizeDirection == ResizeDirection.left ||
              _activeResizeDirection == ResizeDirection.topLeft ||
              _activeResizeDirection == ResizeDirection.bottomLeft) &&
          annotation.startX != null) {
        tempStartX = leftData.dx;
      }

      if ((_activeResizeDirection == ResizeDirection.right ||
              _activeResizeDirection == ResizeDirection.topRight ||
              _activeResizeDirection == ResizeDirection.bottomRight) &&
          annotation.endX != null) {
        tempEndX = rightData.dx;
      }

      if ((_activeResizeDirection == ResizeDirection.bottom ||
              _activeResizeDirection == ResizeDirection.bottomLeft ||
              _activeResizeDirection == ResizeDirection.bottomRight) &&
          annotation.startY != null) {
        tempStartY = rightData.dy;
      }

      if ((_activeResizeDirection == ResizeDirection.top ||
              _activeResizeDirection == ResizeDirection.topLeft ||
              _activeResizeDirection == ResizeDirection.topRight) &&
          annotation.endY != null) {
        tempEndY = leftData.dy;
      }

      _resizingAnnotation!.updateTempValues(
        startX: tempStartX,
        endX: tempEndX,
        startY: tempStartY,
        endY: tempEndY,
      );
    }
  }

  void _performMove(Offset currentPosition) {
    if (_movingAnnotation == null || _moveStartPosition == null || _moveStartBounds == null) {
      return;
    }

    final delta = currentPosition - _moveStartPosition!;
    final oldBounds = _moveStartBounds!;

    final newBounds = Rect.fromLTRB(
      oldBounds.left + delta.dx,
      oldBounds.top + delta.dy,
      oldBounds.right + delta.dx,
      oldBounds.bottom + delta.dy,
    );

    _movingAnnotation!.updateBounds(newBounds);
  }

  void _performPointAnnotationMove(Offset currentPosition) {
    if (_movingPointAnnotation == null) return;

    final annotation = _movingPointAnnotation!.annotation;

    SeriesElement? targetSeries;
    for (final element in _delegate.elements.whereType<SeriesElement>()) {
      if (element.series.id == annotation.seriesId) {
        targetSeries = element;
        break;
      }
    }

    if (targetSeries == null || targetSeries.series.points.isEmpty) return;

    final transform = targetSeries.transform;
    final plotPos = _delegate.widgetToPlot(currentPosition);
    final dataPos = transform.plotToData(plotPos.dx, plotPos.dy);

    final points = targetSeries.series.points;
    double minDistance = double.infinity;
    int nearestIndex = _originalDataPointIndex ?? 0;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final dx = point.x - dataPos.dx;
      final dy = point.y - dataPos.dy;
      final distance = math.sqrt(dx * dx + dy * dy);

      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    final xRange = transform.dataXMax - transform.dataXMin;
    final yRange = transform.dataYMax - transform.dataYMin;
    final snapTolerance = 0.05 * math.sqrt(xRange * xRange + yRange * yRange);

    if (minDistance <= snapTolerance) {
      _candidateDataPointIndex = nearestIndex;
      _movingPointAnnotation!.updateCandidateIndex(nearestIndex);
    } else {
      _movingPointAnnotation!.updateCandidateIndex(_candidateDataPointIndex);
    }
  }

  void _performTextAnnotationMove(Offset currentPosition) {
    if (_movingTextAnnotation == null || _moveTextStartPosition == null) return;

    final delta = currentPosition - _moveTextStartPosition!;
    final originalPosition = _movingTextAnnotation!.annotation.position;
    final newPosition = originalPosition + delta;

    _movingTextAnnotation!.updateTempPosition(newPosition);
  }

  void _performThresholdAnnotationMove(Offset currentPosition) {
    if (_movingThresholdAnnotation == null || _moveThresholdStartPosition == null || _moveThresholdStartValue == null) {
      return;
    }

    final transform = _delegate.transform;
    if (transform == null) return;

    final element = _movingThresholdAnnotation!;
    final annotation = element.annotation;

    double newValue;
    if (annotation.axis == AnnotationAxis.x) {
      final screenX1 = _moveThresholdStartPosition!.dx;
      final screenX2 = currentPosition.dx;
      final dataX1 = transform.plotToData(screenX1, 0).dx;
      final dataX2 = transform.plotToData(screenX2, 0).dx;
      final dataDelta = dataX2 - dataX1;
      newValue = _moveThresholdStartValue! + dataDelta;
    } else {
      final screenY1 = _moveThresholdStartPosition!.dy;
      final screenY2 = currentPosition.dy;
      final dataY1 = transform.plotToData(0, screenY1).dy;
      final dataY2 = transform.plotToData(0, screenY2).dy;
      final dataDelta = dataY2 - dataY1;
      newValue = _moveThresholdStartValue! + dataDelta;
    }

    element.updateTempValue(newValue);
    _delegate.markNeedsPaint();
  }

  void _performPinAnnotationMove(Offset currentPosition) {
    if (_movingPinAnnotation == null || _movePinStartPosition == null || _movePinStartX == null || _movePinStartY == null) {
      return;
    }

    final transform = _delegate.transform;
    if (transform == null) return;

    final dataStart = transform.plotToData(_movePinStartPosition!.dx, _movePinStartPosition!.dy);
    final dataEnd = transform.plotToData(currentPosition.dx, currentPosition.dy);

    final dataDelta = dataEnd - dataStart;

    final newX = _movePinStartX! + dataDelta.dx;
    final newY = _movePinStartY! + dataDelta.dy;

    _movingPinAnnotation!.updateTempPosition(newX, newY);
    _delegate.markNeedsPaint();
  }

  void _performLegendAnnotationMove(Offset currentPosition) {
    if (_movingLegendAnnotation == null || _moveLegendStartPosition == null) {
      return;
    }

    final delta = currentPosition - _moveLegendStartPosition!;
    final currentBounds = _movingLegendAnnotation!.bounds;
    final newTopLeft = Offset(currentBounds.left + delta.dx, currentBounds.top + delta.dy);

    _movingLegendAnnotation!.updateTempPosition(newTopLeft);
    _moveLegendStartPosition = currentPosition; // Update for continuous delta
    _delegate.markNeedsPaint();
  }

  // ==========================================================================
  // Helper Methods
  // ==========================================================================

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

  double? _findNearestDataValue(double targetValue, {required String axis, required double tolerance}) {
    double? nearestValue;
    double minDistance = double.infinity;

    for (final element in _delegate.elements.whereType<SeriesElement>()) {
      for (final point in element.series.points) {
        final value = axis == 'x' ? point.x : point.y;
        final distance = (value - targetValue).abs();

        if (distance < minDistance && distance <= tolerance) {
          minDistance = distance;
          nearestValue = value;
        }
      }
    }

    return nearestValue;
  }
}
