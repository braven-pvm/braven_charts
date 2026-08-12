// Copyright (c) 2025 braven_charts. All rights reserved.
// EventHandlerManager Module - Extracted from ChartRenderBox

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../coordinates/chart_transform.dart';
import '../../elements/annotation_elements.dart';
import '../../elements/resize_handle_element.dart';
import '../../elements/series_element.dart';
import '../../elements/value_summary_annotation_element.dart';
import '../../interaction/core/chart_element.dart';
import '../../interaction/core/coordinator.dart';
import '../../interaction/core/data_hit.dart';
import '../../interaction/core/element_types.dart';
import '../../interaction/core/hit_test_strategy.dart';
import '../../interaction/core/interaction_mode.dart';
import '../../models/chart_annotation.dart';
import '../../models/chart_series.dart';
import '../../models/braven_chart_controller.dart'
    show ChartSelectionBrushState;
import '../../models/heatmap_chart_series.dart';
import '../../models/interaction_config.dart';
import '../../models/radial_bar_chart_series.dart';
import '../../models/range_area_chart_series.dart';

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

  /// Current durable brush state supplied by the chart widget.
  ChartSelectionBrushState? get selectionBrushState;

  /// Current durable brush geometry in widget coordinates.
  Rect? get selectionBrushWidgetRect;

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
  void Function(String annotationId, ChartAnnotation updatedAnnotation)?
  get onAnnotationChanged;

  /// Callback for transient annotation geometry during an active drag.
  void Function(String annotationId, ChartAnnotation previewAnnotation)?
  get onAnnotationDragUpdate;

  /// Callback for range annotation creation completion.
  void Function(double startX, double endX, double startY, double endY)?
  get onRangeCreationComplete;

  /// Callback invoked when the user manually manipulates the viewport.
  VoidCallback? get onViewportInteracted;

  /// Callback invoked after visible viewport bounds change.
  VoidCallback? get onViewportChanged;

  /// Callback invoked when a drag acquisition resolves durable data hits.
  void Function(ChartSelectionGestureResult result)?
  get onSelectionGestureComplete;

  // ==================== Delegated Operations ====================

  /// Converts widget coordinates to plot coordinates.
  Offset widgetToPlot(Offset widgetPosition);

  /// Hit tests elements at the given position.
  ChartElement? hitTestElements(Offset widgetPosition);

  /// Resolves a primary-button annotation manipulation target.
  ///
  /// Resize handles and draggable annotation bodies own the press before data
  /// marks and active selection tools, even when their painted areas overlap.
  ChartElement? hitTestAnnotationInteractionTarget(Offset widgetPosition);

  /// Hit tests elements within a rectangle.
  List<ChartElement> hitTestRect(Rect widgetRect);

  /// Resolves Cartesian data hits enclosed by a widget-space rectangle.
  List<ChartDataHit> hitTestDataRect(Rect widgetRect);

  /// Resolves Cartesian data hits enclosed by a widget-space polygon.
  List<ChartDataHit> hitTestDataPolygon(List<Offset> widgetPolygon);

  /// Resolves one widget-space brush rectangle through normal selection.
  ChartSelectionGestureResult? selectionGestureForWidgetRect(
    Rect widgetRect, {
    bool isPersistentBrushUpdate,
    bool isFinal,
  });

  /// Rebuilds the spatial index after element changes.
  void rebuildSpatialIndex();

  /// Marks the spatial index as dirty for lazy rebuild.
  ///
  /// Instead of rebuilding the QuadTree synchronously (expensive with many
  /// elements), this defers the rebuild until the next hitTestElements() call.
  /// This eliminates the ~2s freeze when clicking on gallery pages with 21+ charts.
  void markSpatialIndexDirty();

  /// Triggers a repaint.
  void markNeedsPaint();

  /// Invalidates the series cache.
  void invalidateSeriesCache();

  /// Updates axes from the current transform.
  void updateAxesFromTransform();

  /// Rebuilds elements with the current transform.
  void rebuildElementsWithTransform();

  /// Clamps pan delta to enforce viewport bounds.
  (double, double) clampPanDelta(
    double requestedPlotDx,
    double requestedPlotDy,
  );

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

  // ==================== Value Summary Annotation Drag ====================

  /// The draggable annotation-style value summary panel, or null when the
  /// annotation presentation is inactive, non-draggable, or hidden.
  ValueSummaryAnnotationElement? get valueSummaryDragTarget;

  /// Captures pre-drag state when a summary panel drag engages.
  void beginValueSummaryDrag();

  /// Live drag preview for the summary panel top-left (plot-local).
  void updateValueSummaryDrag(Offset panelOriginPlot);

  /// Commits an engaged summary panel drag (clamp + exactly one
  /// `onPlacementChanged`).
  void commitValueSummaryDrag();

  /// Abandons an engaged summary panel drag without committing.
  void cancelValueSummaryDrag();

  /// Grants or clears the summary panel's keyboard focus.
  ///
  /// Returns whether the focus state actually changed.
  bool setValueSummaryFocus(bool focused);
}

/// Exact data-space intent and resolved hits produced by one drag acquisition.
///
/// Keeping the acquisition bounds alongside the resolved source identities lets
/// document extraction reproduce continuous interval boundaries instead of
/// guessing them from the first and last enclosed marker.
class ChartSelectionGestureResult {
  const ChartSelectionGestureResult({
    required this.acquisitionMode,
    required this.hits,
    this.minimumXInclusive,
    this.maximumXInclusive,
    this.minimumYInclusive,
    this.maximumYInclusive,
    this.plotBounds,
    this.isPersistentBrushUpdate = false,
    this.isFinal = true,
  });

  final ChartSelectionAcquisitionMode acquisitionMode;
  final List<ChartDataHit> hits;
  final double? minimumXInclusive;
  final double? maximumXInclusive;
  final double? minimumYInclusive;
  final double? maximumYInclusive;

  /// Exact plot-space drag bounds before any chart-wide data transform is
  /// applied.
  ///
  /// Y interval intent must be resolved through each participating series
  /// transform because independent axes map the same pixels to different data
  /// values.
  final Rect? plotBounds;

  /// Whether this gesture came from moving or resizing an existing brush.
  final bool isPersistentBrushUpdate;

  /// Whether this is the final pointer-up publication for the interaction.
  final bool isFinal;
}

enum _SelectionBrushDragKind {
  move,
  leadingHandle,
  trailingHandle,
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
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
  EventHandlerManager({required EventHandlerDelegate delegate})
    : _delegate = delegate;

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
  // Value Summary Annotation Move State
  // ==========================================================================

  /// Value summary panel being moved.
  ValueSummaryAnnotationElement? _movingValueSummary;

  /// Starting pointer position for the summary panel move.
  Offset? _moveValueSummaryStartPosition;

  /// Panel top-left (plot-local) at drag engagement.
  Offset? _moveValueSummaryStartOrigin;

  /// Potential value summary panel drag.
  ValueSummaryAnnotationElement? _potentialDragValueSummary;
  Offset? _potentialDragValueSummaryStart;

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
  // Deferred Selection State (Click-and-Hold Pattern)
  // ==========================================================================

  /// True when pointer-down was on empty area and selection should be cleared
  /// on pointer-up. Deferring this avoids synchronous notifyListeners() +
  /// rebuildSpatialIndex() during pointer-down, which caused ~2s freezes
  /// on gallery pages with 21+ charts.
  bool _pointerDownOnEmptyArea = false;

  /// Position where empty-area click occurred (for onEmptyAreaClick callback).
  Offset? _emptyAreaClickPosition;

  /// The PointerEvent from the empty-area click (for onEmptyAreaClick callback).
  PointerDownEvent? _emptyAreaClickEvent;

  /// Non-draggable element that was clicked during pointer-down.
  /// Selection is deferred to pointer-up to match draggable annotations' fast path.
  ChartElement? _potentialSelectElement;

  /// The PointerDownEvent associated with the deferred element selection.
  PointerDownEvent? _potentialSelectEvent;

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

  _SelectionBrushDragKind? _selectionBrushDragKind;
  Rect? _selectionBrushStartRect;
  Rect? _activeSelectionBrushRect;
  Offset? _selectionBrushStartPointer;
  bool _selectionBrushDidManipulate = false;
  bool _selectionBrushHovered = false;
  Rect? _pendingSelectionBrushRect;
  bool _selectionBrushFrameScheduled = false;

  /// Gets the current cursor position for crosshair rendering.
  Offset? get cursorPosition => _cursorPosition;

  /// Transient widget-space brush geometry during a move or resize.
  Rect? get activeSelectionBrushRect => _activeSelectionBrushRect;

  /// Whether the pointer is currently over the persistent brush.
  bool get selectionBrushHovered => _selectionBrushHovered;

  /// Clears the cursor position and repaints. Call when the pointer leaves the chart.
  void clearCursorPosition() {
    if (_cursorPosition == null &&
        _delegate.coordinator.hoveredMarker == null &&
        _delegate.coordinator.pressedMarker == null) {
      return;
    }
    _cursorPosition = null;
    _delegate.coordinator.setHoveredMarker(null);
    _delegate.coordinator.setPressedMarker(null);
    _selectionBrushHovered = false;
    _setHoveredElement(null);
    _delegate.markNeedsPaint();
  }

  /// Removes pointer-only overlay state before a durable preview capture.
  void clearTransientPreviewState() {
    _cursorPosition = null;
    _tappedMarker = null;
    _pendingHitTestPosition = null;
    _selectionBrushHovered = false;
    _delegate.coordinator.setHoveredMarker(null);
    _delegate.coordinator.setPressedMarker(null);
    _delegate.markNeedsPaint();
  }

  /// Tracks the tapped marker for tap-triggered tooltips.
  HoveredMarkerInfo? _tappedMarker;

  /// Gets the tapped marker for tooltip rendering.
  HoveredMarkerInfo? get tappedMarker => _tappedMarker;

  /// Clears a tap-pinned tooltip without disturbing cursor or hover state.
  ///
  /// Returns whether a pinned marker was dismissed.
  bool clearTappedMarker() {
    if (_tappedMarker == null) return false;
    _tappedMarker = null;
    _delegate.markNeedsPaint();
    return true;
  }

  // ==========================================================================
  // Hit Test Throttling
  // ==========================================================================

  /// Pending hover position for deferred hit testing.
  Offset? _pendingHitTestPosition;

  /// Timer for debouncing hit testing during rapid hover movements.
  Timer? _hitTestDebounceTimer;

  /// Throttle duration for hit testing (milliseconds).
  static const Duration _hitTestThrottleDuration = Duration(milliseconds: 50);

  /// Direct-touch pointers currently down on the rendering surface.
  final Set<int> _activeTouchPointers = <int>{};
  final Map<int, Offset> _touchDownPositions = <int, Offset>{};
  final Set<int> _browseScrollPointers = <int>{};

  /// Prevents the remainder of a claimed viewport transform from being
  /// interpreted as taps, selection, or annotation input.
  bool _suppressTouchSequence = false;

  /// Whether direct-touch raw events are currently owned by viewport input.
  bool get isSuppressingTouchSequence => _suppressTouchSequence;

  // ==========================================================================
  // Lifecycle
  // ==========================================================================

  /// Disposes of resources.
  void dispose() {
    _hitTestDebounceTimer?.cancel();
    _hitTestDebounceTimer = null;
    _clearSelectionBrushInteractionState();
  }

  /// Cancels pointer-only candidate state after the gesture arena awards a
  /// direct-touch sequence to viewport navigation.
  ///
  /// The coordinator mode is deliberately left untouched: the touch
  /// recognizer has already claimed `transformingViewport`.
  void beginViewportTransform() {
    _beginClaimedTouchSequence(clearCursor: true);
  }

  /// Cancels pending raw-touch candidates after long-press tracking wins.
  void beginTouchTracking(Offset position) {
    _beginClaimedTouchSequence(clearCursor: false);
    updateTouchTrackingPosition(position);
  }

  void _beginClaimedTouchSequence({required bool clearCursor}) {
    _suppressTouchSequence = true;
    _hitTestDebounceTimer?.cancel();
    _hitTestDebounceTimer = null;
    _pendingHitTestPosition = null;
    _cancelDeferredEmptyAreaClick();
    _potentialDragPointAnnotation = null;
    _potentialDragStartPosition = null;
    _potentialDragRangeAnnotation = null;
    _potentialDragRangeStartPosition = null;
    _potentialDragRangeStartBounds = null;
    _potentialDragTextAnnotation = null;
    _potentialDragTextStartPosition = null;
    _potentialDragThresholdAnnotation = null;
    _potentialDragThresholdStartPosition = null;
    _potentialDragPinAnnotation = null;
    _potentialDragPinStartPosition = null;
    _potentialDragValueSummary = null;
    _potentialDragValueSummaryStart = null;
    _potentialDragLegendAnnotation = null;
    _potentialDragLegendStartPosition = null;
    _lastPanPosition = null;
    if (clearCursor) _cursorPosition = null;
    _tappedMarker = null;
    _delegate.coordinator.setHoveredMarker(null);
    _delegate.coordinator.setPressedMarker(null);
    _setHoveredElement(null);
    _delegate.markNeedsPaint();
  }

  /// Updates the renderer-owned cursor and marker feedback during touch scrub.
  void updateTouchTrackingPosition(Offset position) {
    _cursorPosition = position;
    _updateHoveredMarker(position);
    _delegate.markNeedsPaint();
  }

  // ==========================================================================
  // Main Event Dispatcher
  // ==========================================================================

  /// Main event handler - dispatches to specific handlers.
  void handleEvent(PointerEvent event) {
    final isDirectTouch = event.kind == PointerDeviceKind.touch;
    final interaction =
        _delegate.interactionConfig ?? const InteractionConfig();
    if (isDirectTouch && event is PointerDownEvent) {
      _activeTouchPointers.add(event.pointer);
      _touchDownPositions[event.pointer] = event.localPosition;
      final touchCanTransformViewport =
          interaction.enabled &&
          interaction.touch.enabled &&
          ((interaction.enableZoom && interaction.touch.enablePinchZoom) ||
              (interaction.enablePan && interaction.touch.enablePan));
      if (_activeTouchPointers.length >= 2 &&
          touchCanTransformViewport &&
          _delegate.coordinator.currentMode ==
              InteractionMode.selectionBrushManipulating) {
        // A visible brush owns one-finger manipulation, but an explicit second
        // touch is the mobile viewport-navigation chord. Release the brush
        // before the scale recognizer resolves so pinch/pan has no dead zone
        // when its first pointer happened to land inside the brush.
        _cancelSelectionBrushInteraction(restoreStartRect: true);
        _delegate.coordinator.setPressedMarker(null);
        _delegate.coordinator.endInteraction();
        _delegate.coordinator.releaseMode(force: true);
        _delegate.markNeedsPaint();
        return;
      }
    }
    if (isDirectTouch && _suppressTouchSequence) {
      if (event is PointerUpEvent || event is PointerCancelEvent) {
        _activeTouchPointers.remove(event.pointer);
        _touchDownPositions.remove(event.pointer);
        _browseScrollPointers.remove(event.pointer);
        if (_activeTouchPointers.isEmpty) {
          _suppressTouchSequence = false;
        }
      }
      return;
    }

    final visiblePersistentBrush =
        interaction.enableSelection &&
        interaction.selection.brush.enabled &&
        (_delegate.selectionBrushState?.visible ?? false);
    final persistentBrushManipulating =
        _delegate.coordinator.currentMode ==
        InteractionMode.selectionBrushManipulating;
    final selectionOwnsPrimaryTouchDrag =
        interaction.enableSelection &&
        interaction.selection.ownsPrimaryDrag() &&
        (!visiblePersistentBrush || persistentBrushManipulating);
    final isBrowseTouch =
        isDirectTouch &&
        interaction.touch.enabled &&
        interaction.touch.profile == TouchInteractionProfile.browse &&
        !selectionOwnsPrimaryTouchDrag;
    if (isBrowseTouch && event is PointerMoveEvent) {
      final downPosition = _touchDownPositions[event.pointer];
      if (downPosition != null &&
          (event.localPosition - downPosition).distance >=
              interaction.gesture.panThreshold) {
        _browseScrollPointers.add(event.pointer);
        _cancelDeferredEmptyAreaClick();
        _potentialDragPointAnnotation = null;
        _potentialDragRangeAnnotation = null;
        _potentialDragTextAnnotation = null;
        _potentialDragThresholdAnnotation = null;
        _potentialDragPinAnnotation = null;
        _potentialDragValueSummary = null;
        _potentialDragLegendAnnotation = null;
        _delegate.coordinator.setPressedMarker(null);
        _delegate.coordinator.endInteraction();
        _delegate.coordinator.releaseMode();
      }
      if (_browseScrollPointers.contains(event.pointer)) return;
    }
    if (isDirectTouch &&
        _browseScrollPointers.contains(event.pointer) &&
        (event is PointerUpEvent || event is PointerCancelEvent)) {
      _activeTouchPointers.remove(event.pointer);
      _touchDownPositions.remove(event.pointer);
      _browseScrollPointers.remove(event.pointer);
      return;
    }

    final coordinator = _delegate.coordinator;

    // The master switch is authoritative. Individual nested settings may
    // remain populated so a host can restore them later, but a disabled chart
    // must not hit-test, hover, focus, select, pan, zoom, or open tooltips.
    if (!interaction.enabled) {
      return;
    }

    // Modal states block all events except themselves
    // EXCEPTION: rangeAnnotationCreation mode needs pointer events to work
    if (coordinator.isModal &&
        coordinator.currentMode != InteractionMode.rangeAnnotationCreation) {
      return;
    }

    // CRITICAL: Use event.localPosition for current position
    final localPosition = event.localPosition;

    if (event is PointerDownEvent) {
      _handlePointerDown(event, localPosition);
    } else if (event is PointerMoveEvent) {
      _handlePointerMove(event, localPosition);
    } else if (event is PointerUpEvent) {
      final allowTapActivation =
          !isDirectTouch ||
          interaction.touch.tapBehavior != TouchTapBehavior.disabled;
      if (!allowTapActivation) {
        _clearDeferredTapActivation();
      }
      _handlePointerUp(
        event,
        localPosition,
        allowTapActivation: allowTapActivation,
      );
    } else if (event is PointerCancelEvent) {
      _handlePointerCancel();
    } else if (event is PointerHoverEvent) {
      _handlePointerHover(event, localPosition);
    } else if (event is PointerScrollEvent) {
      _handlePointerScroll(event, localPosition);
    }
    if (isDirectTouch &&
        (event is PointerUpEvent || event is PointerCancelEvent)) {
      _activeTouchPointers.remove(event.pointer);
      _touchDownPositions.remove(event.pointer);
      _browseScrollPointers.remove(event.pointer);
    }
  }

  // ==========================================================================
  // Pointer Down Handler
  // ==========================================================================

  void _handlePointerDown(PointerDownEvent event, Offset position) {
    final coordinator = _delegate.coordinator;
    coordinator.setPressedMarker(null);

    // Value summary annotation panel: within its painted bounds the
    // draggable panel wins the PRIMARY pointer (spec: drag begins only from
    // the summary bounds), and a primary press on it must never resolve,
    // hover, select, or tooltip the data beneath. Secondary (context menu)
    // and middle (pan) presses are not panel gestures — they fall through
    // to the exclusive per-button handlers below. Any press that is not a
    // primary press on the panel makes the panel give up keyboard focus.
    final summaryTarget = _delegate.valueSummaryDragTarget;
    final onSummaryPanel =
        summaryTarget != null &&
        summaryTarget.hitTest(_delegate.widgetToPlot(position));
    final primaryOnSummaryPanel =
        onSummaryPanel && event.buttons == kPrimaryMouseButton;
    if (summaryTarget != null) {
      _delegate.setValueSummaryFocus(primaryOnSummaryPanel);
    }
    if (primaryOnSummaryPanel) {
      coordinator.startInteraction(position, element: summaryTarget);
      _potentialDragValueSummary = summaryTarget;
      _potentialDragValueSummaryStart = position;
      return;
    }

    // Touch and stylus input do not produce a preceding hover event. Resolve
    // the datum on pointer-down only when the semantic scope includes marks;
    // complete-series-only selection must never flash marker feedback.
    final selection =
        _delegate.interactionConfig?.selection ?? const ChartSelectionConfig();
    if (selection.scope.includesMarks) {
      _updateHoveredMarker(position);
    } else {
      coordinator.setHoveredMarker(null);
    }

    // PRIORITY 1: Check if pointer is on scrollbar (highest priority)
    if (_delegate.hitTestScrollbars(
      position,
      event.buttons,
      isModal: coordinator.isModal,
      onClaimMode: () =>
          coordinator.claimMode(InteractionMode.scrollbarDragging),
      cancelAutoScroll: _delegate.cancelAutoScroll,
    )) {
      _delegate.onViewportInteracted?.call();
      return; // Scrollbar claimed the event
    }

    // Annotation manipulation has explicit ownership over data activation and
    // selection acquisition. Resolve that primary-button-only surface before
    // falling back to ordinary paint/hit priority.
    final annotationInteractionTarget = event.buttons == kPrimaryMouseButton
        ? _delegate.hitTestAnnotationInteractionTarget(position)
        : null;
    if (event.buttons == kPrimaryMouseButton &&
        annotationInteractionTarget == null &&
        _beginSelectionBrushInteraction(position)) {
      return;
    }
    final hitElement =
        annotationInteractionTarget ?? _delegate.hitTestElements(position);

    coordinator.startInteraction(position, element: hitElement);

    if (event.buttons == kPrimaryMouseButton &&
        hitElement is SeriesElement &&
        hitElement.series is BarChartSeries) {
      final geometry = hitElement.barGeometryAt(
        _delegate.widgetToPlot(position),
      );
      if (geometry != null) {
        final marker = HoveredMarkerInfo(
          seriesId: hitElement.id,
          markerIndex: geometry.pointIndex,
          plotPosition: geometry.valueEndPoint,
        );
        coordinator.setPressedMarker(marker);
        coordinator.setHoveredMarker(marker);
        _delegate.markNeedsPaint();
      }
    }

    // Check if we hit a resize handle (priority 7)
    if (event.buttons == kPrimaryMouseButton &&
        hitElement is ResizeHandleElement) {
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
      coordinator.claimMode(
        InteractionMode.resizingAnnotation,
        element: annotation,
      );
      _delegate.markNeedsPaint();
      return;
    }

    if (event.buttons == kPrimaryMouseButton &&
        hitElement is RangeAnnotationElement &&
        hitElement.isDraggable) {
      _delegate.onCursorChange?.call(SystemMouseCursors.grabbing);
    }

    // Per conflict resolution: Different buttons have different behaviors
    if (event.buttons == kMiddleMouseButton) {
      // Check if pan is enabled
      final enablePan = _delegate.interactionConfig?.enablePan ?? true;
      if (!enablePan) {
        return;
      }

      // Middle-click: EXCLUSIVELY pan (per scenario 6)
      _delegate.onViewportInteracted?.call();
      coordinator.claimMode(InteractionMode.panning);
      _lastPanPosition = position;
      _delegate.showScrollbarsAndScheduleHide();
    } else if (event.buttons == kSecondaryMouseButton) {
      // Right-click: EXCLUSIVELY context menu (per scenario 8)
      coordinator.claimMode(
        InteractionMode.contextMenuOpen,
        element: hitElement,
      );
    } else if (event.buttons == kPrimaryMouseButton) {
      // Left-click: Select, or start drag/box-select (determined on move)
      if (hitElement != null) {
        _handlePrimaryButtonDownOnElement(hitElement, event, position);
      } else {
        // Clicked on empty area — defer clearSelection to pointer-up
        // to avoid synchronous notifyListeners + rebuildSpatialIndex cascade
        // that caused ~2s freeze on gallery pages with 21+ charts.
        _pointerDownOnEmptyArea = true;
        _emptyAreaClickPosition = position;
        _emptyAreaClickEvent = event;
      }
    }
  }

  /// Handles primary button down on a specific element.
  void _handlePrimaryButtonDownOnElement(
    ChartElement hitElement,
    PointerDownEvent event,
    Offset position,
  ) {
    // Check for various annotation types that support potential drag
    if (hitElement is RangeAnnotationElement) {
      _potentialDragRangeAnnotation = hitElement;
      _potentialDragRangeStartPosition = position;
      _potentialDragRangeStartBounds = hitElement.bounds;
    } else if (hitElement is TextAnnotationElement &&
        hitElement.annotation.allowDragging) {
      _potentialDragTextAnnotation = hitElement;
      _potentialDragTextStartPosition = position;
    } else if (hitElement is ThresholdAnnotationElement &&
        hitElement.annotation.allowDragging) {
      _potentialDragThresholdAnnotation = hitElement;
      _potentialDragThresholdStartPosition = position;
    } else if (hitElement is PinAnnotationElement &&
        hitElement.annotation.allowDragging) {
      _potentialDragPinAnnotation = hitElement;
      _potentialDragPinStartPosition = position;
    } else if (hitElement is LegendAnnotationElement &&
        hitElement.annotation.legendStyle.allowDragging) {
      _potentialDragLegendAnnotation = hitElement;
      _potentialDragLegendStartPosition = position;
    } else if (hitElement is PointAnnotationElement &&
        hitElement.annotation.allowDragging) {
      _potentialDragPointAnnotation = hitElement;
      _potentialDragStartPosition = position;
    } else {
      // Non-draggable element — defer selection to pointer-up
      // to match draggable annotations' fast path and avoid synchronous
      // notifyListeners + rebuildSpatialIndex during pointer-down.
      _potentialSelectElement = hitElement;
      _potentialSelectEvent = event;
    }
  }

  bool _beginSelectionBrushInteraction(Offset position) {
    if (!hitTestSelectionBrushInteraction(position)) return false;

    final selection =
        _delegate.interactionConfig?.selection ?? const ChartSelectionConfig();
    final state = _delegate.selectionBrushState!;
    final rect = _delegate.selectionBrushWidgetRect!;
    final kind = _selectionBrushHitKind(position, rect, selection)!;

    _cancelDeferredEmptyAreaClick();
    _selectionBrushDragKind = kind;
    _selectionBrushStartRect = rect;
    _activeSelectionBrushRect = rect;
    _selectionBrushStartPointer = position;
    _selectionBrushDidManipulate = false;
    _delegate.coordinator.startInteraction(position);
    _delegate.coordinator.claimMode(InteractionMode.selectionBrushManipulating);
    _delegate.onCursorChange?.call(
      kind == _SelectionBrushDragKind.move
          ? SystemMouseCursors.grabbing
          : _selectionBrushResizeCursor(state.acquisitionMode, kind),
    );
    _delegate.markNeedsPaint();
    return true;
  }

  /// Whether [position] starts a move or resize on the persistent brush.
  ///
  /// The widget-level touch recognizer uses this before the pointer moves so a
  /// brush manipulation can defeat an ancestor [Scrollable] in the gesture
  /// arena. Ordinary touches outside the brush remain available to page
  /// scrolling.
  bool hitTestSelectionBrushInteraction(Offset position) {
    final selection =
        _delegate.interactionConfig?.selection ?? const ChartSelectionConfig();
    final state = _delegate.selectionBrushState;
    final rect = _delegate.selectionBrushWidgetRect;
    if (!selection.brush.enabled ||
        state == null ||
        !state.visible ||
        rect == null) {
      return false;
    }
    return _selectionBrushHitKind(position, rect, selection) != null;
  }

  _SelectionBrushDragKind? _selectionBrushHitKind(
    Offset position,
    Rect rect,
    ChartSelectionConfig selection,
  ) {
    final state = _delegate.selectionBrushState;
    if (state == null) return null;
    final extent = selection.brush.style.handleHitSize;
    if (state.acquisitionMode == ChartSelectionAcquisitionMode.rectangle) {
      final handles = <(_SelectionBrushDragKind, Offset)>[
        (_SelectionBrushDragKind.topLeft, rect.topLeft),
        (_SelectionBrushDragKind.topRight, rect.topRight),
        (_SelectionBrushDragKind.bottomRight, rect.bottomRight),
        (_SelectionBrushDragKind.bottomLeft, rect.bottomLeft),
        (_SelectionBrushDragKind.top, rect.topCenter),
        (_SelectionBrushDragKind.right, rect.centerRight),
        (_SelectionBrushDragKind.bottom, rect.bottomCenter),
        (_SelectionBrushDragKind.left, rect.centerLeft),
      ];
      for (final (kind, center) in handles) {
        if ((position - center).distance <= extent / 2) return kind;
      }
      return rect.contains(position) ? _SelectionBrushDragKind.move : null;
    }
    final transposed = _delegate.transform?.transposed ?? false;
    final usesScreenX =
        state.acquisitionMode == ChartSelectionAcquisitionMode.xInterval
        ? !transposed
        : transposed;
    final leadingCenter = usesScreenX ? rect.centerLeft : rect.topCenter;
    final trailingCenter = usesScreenX ? rect.centerRight : rect.bottomCenter;
    if ((position - leadingCenter).distance <= extent / 2) {
      return _SelectionBrushDragKind.leadingHandle;
    }
    if ((position - trailingCenter).distance <= extent / 2) {
      return _SelectionBrushDragKind.trailingHandle;
    }
    return rect.contains(position) ? _SelectionBrushDragKind.move : null;
  }

  MouseCursor _selectionBrushResizeCursor(
    ChartSelectionAcquisitionMode mode,
    _SelectionBrushDragKind kind,
  ) {
    if (mode == ChartSelectionAcquisitionMode.rectangle) {
      return switch (kind) {
        _SelectionBrushDragKind.topLeft ||
        _SelectionBrushDragKind.bottomRight =>
          SystemMouseCursors.resizeUpLeftDownRight,
        _SelectionBrushDragKind.topRight ||
        _SelectionBrushDragKind.bottomLeft =>
          SystemMouseCursors.resizeUpRightDownLeft,
        _SelectionBrushDragKind.top ||
        _SelectionBrushDragKind.bottom => SystemMouseCursors.resizeUpDown,
        _SelectionBrushDragKind.left ||
        _SelectionBrushDragKind.right => SystemMouseCursors.resizeLeftRight,
        _ => SystemMouseCursors.move,
      };
    }
    final transposed = _delegate.transform?.transposed ?? false;
    final usesScreenX = mode == ChartSelectionAcquisitionMode.xInterval
        ? !transposed
        : transposed;
    return usesScreenX
        ? SystemMouseCursors.resizeLeftRight
        : SystemMouseCursors.resizeUpDown;
  }

  // ==========================================================================
  // Pointer Move Handler
  // ==========================================================================

  void _handlePointerMove(PointerMoveEvent event, Offset position) {
    final coordinator = _delegate.coordinator;

    if (coordinator.currentMode == InteractionMode.selectionBrushManipulating &&
        event.buttons == kPrimaryMouseButton) {
      // Crosshair painting is suppressed while the brush owns the drag, but
      // its retained pointer must continue following the gesture. Otherwise
      // releasing the brush briefly reveals the pointer-down crosshair before
      // the next hover event supplies the release position.
      _cursorPosition = position;
      _updateSelectionBrushInteraction(position);
      return;
    }

    // Check potential drags first (before isInteracting check)
    if (_checkPotentialDrags(event, position)) {
      return;
    }

    // PRIORITY 1: Handle scrollbar drag if active
    if (_delegate.isScrollbarDragging) {
      _delegate.handleScrollbarDrag(position);
      _delegate.onViewportChanged?.call();
      return;
    }

    if (coordinator.currentMode == InteractionMode.selectionBrushManipulating) {
      _cursorPosition = position;
      _completeSelectionBrushInteraction();
      coordinator.setPressedMarker(null);
      coordinator.endInteraction();
      coordinator.releaseMode();
      _delegate.markNeedsPaint();
      return;
    }

    // PRIORITY 1.5: Handle range annotation creation mode
    if (coordinator.currentMode == InteractionMode.rangeAnnotationCreation &&
        event.buttons == kPrimaryMouseButton) {
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

    final startPos = coordinator.interactionStartPosition;
    if (startPos == null) return;

    // Handle active drags
    if (_handleActiveDrags(event, position, startPos)) {
      return;
    }

    // Handle pan and box selection
    _handlePanAndBoxSelection(event, position, startPos);
  }

  void _updateSelectionBrushInteraction(Offset position) {
    final state = _delegate.selectionBrushState;
    final kind = _selectionBrushDragKind;
    final startRect = _selectionBrushStartRect;
    final startPointer = _selectionBrushStartPointer;
    if (state == null ||
        kind == null ||
        startRect == null ||
        startPointer == null) {
      return;
    }
    final transposed = _delegate.transform?.transposed ?? false;
    final usesScreenX =
        state.acquisitionMode == ChartSelectionAcquisitionMode.xInterval
        ? !transposed
        : transposed;
    final plot = _delegate.plotArea;
    final style =
        (_delegate.interactionConfig?.selection ?? const ChartSelectionConfig())
            .brush
            .style;
    final minimumSpan = math.max(style.handleSize, 2);
    final pointerDelta = position - startPointer;
    if (state.acquisitionMode == ChartSelectionAcquisitionMode.rectangle) {
      Rect next;
      if (kind == _SelectionBrushDragKind.move) {
        final dx = pointerDelta.dx.clamp(
          plot.left - startRect.left,
          plot.right - startRect.right,
        );
        final dy = pointerDelta.dy.clamp(
          plot.top - startRect.top,
          plot.bottom - startRect.bottom,
        );
        next = startRect.shift(Offset(dx, dy));
      } else {
        var left = startRect.left;
        var top = startRect.top;
        var right = startRect.right;
        var bottom = startRect.bottom;
        final changesLeft =
            kind == _SelectionBrushDragKind.topLeft ||
            kind == _SelectionBrushDragKind.bottomLeft ||
            kind == _SelectionBrushDragKind.left;
        final changesRight =
            kind == _SelectionBrushDragKind.topRight ||
            kind == _SelectionBrushDragKind.bottomRight ||
            kind == _SelectionBrushDragKind.right;
        final changesTop =
            kind == _SelectionBrushDragKind.topLeft ||
            kind == _SelectionBrushDragKind.top ||
            kind == _SelectionBrushDragKind.topRight;
        final changesBottom =
            kind == _SelectionBrushDragKind.bottomLeft ||
            kind == _SelectionBrushDragKind.bottom ||
            kind == _SelectionBrushDragKind.bottomRight;
        if (changesLeft) {
          left = (startRect.left + pointerDelta.dx).clamp(
            plot.left,
            startRect.right - minimumSpan,
          );
        }
        if (changesRight) {
          right = (startRect.right + pointerDelta.dx).clamp(
            startRect.left + minimumSpan,
            plot.right,
          );
        }
        if (changesTop) {
          top = (startRect.top + pointerDelta.dy).clamp(
            plot.top,
            startRect.bottom - minimumSpan,
          );
        }
        if (changesBottom) {
          bottom = (startRect.bottom + pointerDelta.dy).clamp(
            startRect.top + minimumSpan,
            plot.bottom,
          );
        }
        next = Rect.fromLTRB(left, top, right, bottom);
      }
      _beginSelectionBrushMutation(next, startRect);
      _activeSelectionBrushRect = next;
      _pendingSelectionBrushRect = next;
      _scheduleSelectionBrushUpdate();
      _delegate.markNeedsPaint();
      return;
    }
    final delta = usesScreenX
        ? position.dx - startPointer.dx
        : position.dy - startPointer.dy;
    Rect next;
    if (kind == _SelectionBrushDragKind.move) {
      if (usesScreenX) {
        final clampedDelta = delta.clamp(
          plot.left - startRect.left,
          plot.right - startRect.right,
        );
        next = startRect.shift(Offset(clampedDelta, 0));
      } else {
        final clampedDelta = delta.clamp(
          plot.top - startRect.top,
          plot.bottom - startRect.bottom,
        );
        next = startRect.shift(Offset(0, clampedDelta));
      }
    } else if (usesScreenX) {
      final edge = kind == _SelectionBrushDragKind.leadingHandle
          ? (startRect.left + delta).clamp(
              plot.left,
              startRect.right - minimumSpan,
            )
          : (startRect.right + delta).clamp(
              startRect.left + minimumSpan,
              plot.right,
            );
      next = kind == _SelectionBrushDragKind.leadingHandle
          ? Rect.fromLTRB(
              edge,
              startRect.top,
              startRect.right,
              startRect.bottom,
            )
          : Rect.fromLTRB(
              startRect.left,
              startRect.top,
              edge,
              startRect.bottom,
            );
    } else {
      final edge = kind == _SelectionBrushDragKind.leadingHandle
          ? (startRect.top + delta).clamp(
              plot.top,
              startRect.bottom - minimumSpan,
            )
          : (startRect.bottom + delta).clamp(
              startRect.top + minimumSpan,
              plot.bottom,
            );
      next = kind == _SelectionBrushDragKind.leadingHandle
          ? Rect.fromLTRB(
              startRect.left,
              edge,
              startRect.right,
              startRect.bottom,
            )
          : Rect.fromLTRB(startRect.left, startRect.top, startRect.right, edge);
    }
    _beginSelectionBrushMutation(next, startRect);
    _activeSelectionBrushRect = next;
    _pendingSelectionBrushRect = next;
    _scheduleSelectionBrushUpdate();
    _delegate.markNeedsPaint();
  }

  void _beginSelectionBrushMutation(Rect next, Rect startRect) {
    if (_selectionBrushDidManipulate || next == startRect) return;
    _selectionBrushDidManipulate = true;
    // A durable tap target must never outlive a brush move or resize that can
    // change whether that datum belongs to the active selection.
    clearTappedMarker();
    _delegate.coordinator.setHoveredMarker(null);
  }

  void _scheduleSelectionBrushUpdate() {
    if (_selectionBrushFrameScheduled) return;
    _selectionBrushFrameScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _selectionBrushFrameScheduled = false;
      final rect = _pendingSelectionBrushRect;
      _pendingSelectionBrushRect = null;
      if (rect == null) return;
      final result = _delegate.selectionGestureForWidgetRect(
        rect,
        isPersistentBrushUpdate: true,
        isFinal: false,
      );
      if (result != null) {
        _delegate.onSelectionGestureComplete?.call(result);
      }
    });
  }

  /// Checks and handles potential drag thresholds.
  /// Returns true if a potential drag was being checked (handled).
  bool _checkPotentialDrags(PointerMoveEvent event, Offset position) {
    // Value summary panel potential drag. Engaging claims the shared
    // annotation-drag mode (coordinator.isDragging suspends tracking), shows
    // the platform move cursor, and — deliberately — never selects the
    // element: the drag must not disturb selection state.
    if (_potentialDragValueSummary != null &&
        _potentialDragValueSummaryStart != null) {
      final dragDistance =
          (position - _potentialDragValueSummaryStart!).distance;

      if (dragDistance >= _dragThresholdPixels) {
        final hitElement = _potentialDragValueSummary!;
        _movingValueSummary = hitElement;
        _moveValueSummaryStartPosition = _potentialDragValueSummaryStart;
        _moveValueSummaryStartOrigin = hitElement.bounds.topLeft;

        _delegate.coordinator.startInteraction(
          _potentialDragValueSummaryStart!,
          element: hitElement,
        );
        _delegate.coordinator.claimMode(
          InteractionMode.draggingAnnotation,
          element: hitElement,
        );
        _delegate.beginValueSummaryDrag();
        _delegate.onCursorChange?.call(SystemMouseCursors.move);

        _potentialDragValueSummary = null;
        _potentialDragValueSummaryStart = null;

        _performValueSummaryMove(position);
        _delegate.markNeedsPaint();
        return true;
      }
      return true; // Still within threshold
    }

    // TextAnnotation potential drag
    if (_potentialDragTextAnnotation != null &&
        _potentialDragTextStartPosition != null) {
      final dragDistance =
          (position - _potentialDragTextStartPosition!).distance;

      if (dragDistance >= _dragThresholdPixels) {
        final hitElement = _potentialDragTextAnnotation!;
        _movingTextAnnotation = hitElement;
        _moveTextStartPosition = _potentialDragTextStartPosition;

        _delegate.coordinator.startInteraction(
          _potentialDragTextStartPosition!,
          element: hitElement,
        );
        _delegate.coordinator.claimMode(
          InteractionMode.draggingAnnotation,
          element: hitElement,
        );

        _potentialDragTextAnnotation = null;
        _potentialDragTextStartPosition = null;

        _performTextAnnotationMove(position);
        _delegate.markNeedsPaint();
        return true;
      }
      return true; // Still within threshold
    }

    // ThresholdAnnotation potential drag
    if (_potentialDragThresholdAnnotation != null &&
        _potentialDragThresholdStartPosition != null) {
      final dragDistance =
          (position - _potentialDragThresholdStartPosition!).distance;

      if (dragDistance >= _dragThresholdPixels) {
        final hitElement = _potentialDragThresholdAnnotation!;
        _movingThresholdAnnotation = hitElement;
        _moveThresholdStartPosition = _potentialDragThresholdStartPosition;
        _moveThresholdStartValue = hitElement.annotation.value;

        _delegate.coordinator.startInteraction(
          _potentialDragThresholdStartPosition!,
          element: hitElement,
        );
        _delegate.coordinator.claimMode(
          InteractionMode.draggingAnnotation,
          element: hitElement,
        );

        _potentialDragThresholdAnnotation = null;
        _potentialDragThresholdStartPosition = null;

        _performThresholdAnnotationMove(position);
        _delegate.markNeedsPaint();
        return true;
      }
      return true;
    }

    // PinAnnotation potential drag
    if (_potentialDragPinAnnotation != null &&
        _potentialDragPinStartPosition != null) {
      final dragDistance =
          (position - _potentialDragPinStartPosition!).distance;

      if (dragDistance >= _dragThresholdPixels) {
        final hitElement = _potentialDragPinAnnotation!;
        _movingPinAnnotation = hitElement;
        _movePinStartPosition = _potentialDragPinStartPosition;
        _movePinStartX = hitElement.annotation.x;
        _movePinStartY = hitElement.annotation.y;

        _delegate.coordinator.startInteraction(
          _potentialDragPinStartPosition!,
          element: hitElement,
        );
        _delegate.coordinator.claimMode(
          InteractionMode.draggingAnnotation,
          element: hitElement,
        );
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
    if (_potentialDragLegendAnnotation != null &&
        _potentialDragLegendStartPosition != null) {
      final dragDistance =
          (position - _potentialDragLegendStartPosition!).distance;

      if (dragDistance >= _dragThresholdPixels) {
        final hitElement = _potentialDragLegendAnnotation!;
        _movingLegendAnnotation = hitElement;
        _moveLegendStartPosition = _potentialDragLegendStartPosition;

        _delegate.coordinator.startInteraction(
          _potentialDragLegendStartPosition!,
          element: hitElement,
        );
        _delegate.coordinator.claimMode(
          InteractionMode.draggingAnnotation,
          element: hitElement,
        );

        _potentialDragLegendAnnotation = null;
        _potentialDragLegendStartPosition = null;

        _performLegendAnnotationMove(position);
        _delegate.markNeedsPaint();
        return true;
      }
      return true;
    }

    // RangeAnnotation potential drag
    if (_potentialDragRangeAnnotation != null &&
        _potentialDragRangeStartPosition != null &&
        _potentialDragRangeStartBounds != null) {
      final dragDistance =
          (position - _potentialDragRangeStartPosition!).distance;

      if (dragDistance >= _dragThresholdPixels) {
        final hitElement = _potentialDragRangeAnnotation!;
        _movingAnnotation = hitElement;
        _moveStartPosition = _potentialDragRangeStartPosition;
        _moveStartBounds = _potentialDragRangeStartBounds;

        _delegate.coordinator.startInteraction(
          _potentialDragRangeStartPosition!,
          element: hitElement,
        );
        _delegate.coordinator.claimMode(
          InteractionMode.draggingAnnotation,
          element: hitElement,
        );

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
    if (_potentialDragPointAnnotation != null &&
        _potentialDragStartPosition != null) {
      final dragDistance = (position - _potentialDragStartPosition!).distance;
      if (dragDistance >= _dragThresholdPixels) {
        final hitElement = _potentialDragPointAnnotation!;

        _movingPointAnnotation = hitElement;
        _originalDataPointIndex = hitElement.annotation.dataPointIndex;
        _candidateDataPointIndex = hitElement.annotation.dataPointIndex;

        _delegate.coordinator.startInteraction(
          _potentialDragStartPosition!,
          element: hitElement,
        );
        _delegate.coordinator.claimMode(
          InteractionMode.draggingAnnotation,
          element: hitElement,
        );

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
  bool _handleActiveDrags(
    PointerMoveEvent event,
    Offset position,
    Offset startPos,
  ) {
    final coordinator = _delegate.coordinator;

    // Handle value summary panel move dragging
    if (coordinator.currentMode == InteractionMode.draggingAnnotation &&
        _movingValueSummary != null &&
        _moveValueSummaryStartPosition != null) {
      _performValueSummaryMove(position);
      _delegate.markNeedsPaint();
      return true;
    }

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
    if (coordinator.currentMode == InteractionMode.draggingAnnotation &&
        _movingTextAnnotation != null &&
        _moveTextStartPosition != null) {
      _performTextAnnotationMove(position);
      _delegate.markNeedsPaint();
      return true;
    }

    // Handle ThresholdAnnotation move dragging
    if (coordinator.currentMode == InteractionMode.draggingAnnotation &&
        _movingThresholdAnnotation != null &&
        _moveThresholdStartPosition != null) {
      _performThresholdAnnotationMove(position);
      _delegate.markNeedsPaint();
      return true;
    }

    // Handle PinAnnotation move dragging
    if (coordinator.currentMode == InteractionMode.draggingAnnotation &&
        _movingPinAnnotation != null &&
        _movePinStartPosition != null) {
      _performPinAnnotationMove(position);
      _delegate.markNeedsPaint();
      return true;
    }

    // Handle LegendAnnotation move dragging
    if (coordinator.currentMode == InteractionMode.draggingAnnotation &&
        _movingLegendAnnotation != null &&
        _moveLegendStartPosition != null) {
      _performLegendAnnotationMove(position);
      _delegate.markNeedsPaint();
      return true;
    }

    // Handle PointAnnotation move dragging
    if (coordinator.currentMode == InteractionMode.draggingAnnotation &&
        _movingPointAnnotation != null) {
      _performPointAnnotationMove(position);
      _delegate.markNeedsPaint();
      return true;
    }

    return false;
  }

  /// Handles panning and box selection.
  void _handlePanAndBoxSelection(
    PointerMoveEvent event,
    Offset position,
    Offset startPos,
  ) {
    final coordinator = _delegate.coordinator;

    // Middle-button drag = pan
    if (event.buttons == kMiddleMouseButton &&
        coordinator.currentMode == InteractionMode.panning) {
      if (_lastPanPosition != null &&
          _delegate.transform != null &&
          _delegate.originalTransform != null) {
        final plotDelta =
            _delegate.widgetToPlot(position) -
            _delegate.widgetToPlot(_lastPanPosition!);

        final (clampedDx, clampedDy) = _delegate.clampPanDelta(
          -plotDelta.dx,
          -plotDelta.dy,
        );

        _delegate.transform = _delegate.transform!.pan(clampedDx, clampedDy);
        _delegate.updateAxesFromTransform();
        _lastPanPosition = position;
        _delegate.markNeedsPaint();
        _delegate.onViewportChanged?.call();
      }
      return;
    }

    // Left-button drag: datapoint drag, annotation drag, or box select
    if (event.buttons == kPrimaryMouseButton) {
      final startElement = coordinator.interactionStartElement;

      // Update box selection rectangle if already in box select mode
      if (coordinator.currentMode == InteractionMode.boxSelecting) {
        _cursorPosition = position;
        _updateDragSelectionPreview(startPos, position);
        _delegate.markNeedsPaint();
        return;
      }

      if (startElement != null && startElement.isDraggable) {
        if (startElement.elementType == ChartElementType.datapoint) {
          coordinator.claimMode(
            InteractionMode.draggingDataPoint,
            element: startElement,
          );
        } else if (startElement.elementType == ChartElementType.annotation) {
          coordinator.claimMode(
            InteractionMode.draggingAnnotation,
            element: startElement,
          );
        }
      } else if (coordinator.shouldStartBoxSelect(position)) {
        // Crossing drag slop means this is no longer an empty-area click,
        // even when the active selection policy does not own the gesture.
        _cancelDeferredEmptyAreaClick();

        final interaction =
            _delegate.interactionConfig ?? const InteractionConfig();
        final selection = interaction.selection;
        final ownsSelectionDrag =
            interaction.enabled &&
            interaction.enableSelection &&
            selection.acquisitionMode != ChartSelectionAcquisitionMode.point &&
            selection.ownsPrimaryDrag(shift: coordinator.isShiftPressed);
        if (ownsSelectionDrag) {
          coordinator.claimMode(InteractionMode.boxSelecting);
          _updateDragSelectionPreview(startPos, position);
          _delegate.markNeedsPaint();
        }
      }
    }
  }

  void _updateDragSelectionPreview(Offset start, Offset current) {
    final coordinator = _delegate.coordinator;
    final acquisitionMode =
        (_delegate.interactionConfig ?? const InteractionConfig())
            .selection
            .acquisitionMode;
    final hits = switch (acquisitionMode) {
      ChartSelectionAcquisitionMode.xInterval => () {
        final rect = _intervalSelectionRect(start, current, selectsDataX: true);
        coordinator.updateSelectionRect(rect);
        return _delegate.hitTestDataRect(rect);
      }(),
      ChartSelectionAcquisitionMode.yInterval => () {
        final rect = _intervalSelectionRect(
          start,
          current,
          selectsDataX: false,
        );
        coordinator.updateSelectionRect(rect);
        return _delegate.hitTestDataRect(rect);
      }(),
      ChartSelectionAcquisitionMode.rectangle => () {
        coordinator.updateBoxSelection(start, current);
        final rect = coordinator.boxSelectionRect;
        return rect == null
            ? const <ChartDataHit>[]
            : _delegate.hitTestDataRect(rect);
      }(),
      ChartSelectionAcquisitionMode.lasso => () {
        coordinator.updateLassoSelection(start, current);
        return _delegate.hitTestDataPolygon(coordinator.lassoSelectionPath);
      }(),
      ChartSelectionAcquisitionMode.point => const <ChartDataHit>[],
    };
    coordinator.updatePreviewDataHits(hits);
  }

  Rect _intervalSelectionRect(
    Offset start,
    Offset current, {
    required bool selectsDataX,
  }) {
    final plotArea = _delegate.plotArea;
    final transposed = _delegate.transform?.transposed ?? false;
    final usesScreenX = selectsDataX ? !transposed : transposed;
    if (usesScreenX) {
      return Rect.fromLTRB(
        math.min(start.dx, current.dx).clamp(plotArea.left, plotArea.right),
        plotArea.top,
        math.max(start.dx, current.dx).clamp(plotArea.left, plotArea.right),
        plotArea.bottom,
      );
    }
    return Rect.fromLTRB(
      plotArea.left,
      math.min(start.dy, current.dy).clamp(plotArea.top, plotArea.bottom),
      plotArea.right,
      math.max(start.dy, current.dy).clamp(plotArea.top, plotArea.bottom),
    );
  }

  void _cancelDeferredEmptyAreaClick() {
    _pointerDownOnEmptyArea = false;
    _emptyAreaClickPosition = null;
    _emptyAreaClickEvent = null;
    _potentialSelectElement = null;
    _potentialSelectEvent = null;
  }

  void _clearDeferredTapActivation() {
    _cancelDeferredEmptyAreaClick();
    _potentialDragPointAnnotation = null;
    _potentialDragStartPosition = null;
    _potentialDragRangeAnnotation = null;
    _potentialDragRangeStartPosition = null;
    _potentialDragRangeStartBounds = null;
    _potentialDragTextAnnotation = null;
    _potentialDragTextStartPosition = null;
    _potentialDragThresholdAnnotation = null;
    _potentialDragThresholdStartPosition = null;
    _potentialDragPinAnnotation = null;
    _potentialDragPinStartPosition = null;
    _potentialDragValueSummary = null;
    _potentialDragValueSummaryStart = null;
    _potentialDragLegendAnnotation = null;
    _potentialDragLegendStartPosition = null;
  }

  // ==========================================================================
  // Pointer Up Handler
  // ==========================================================================

  void _handlePointerUp(
    PointerUpEvent event,
    Offset position, {
    bool allowTapActivation = true,
  }) {
    final coordinator = _delegate.coordinator;
    coordinator.setPressedMarker(null);

    // Clear scrollbar drag state if active
    if (_delegate.isScrollbarDragging) {
      _delegate.clearScrollbarDragState();
      coordinator.endInteraction();
      coordinator.releaseMode();
      return;
    }

    if (coordinator.currentMode == InteractionMode.selectionBrushManipulating) {
      _cursorPosition = position;
      final brushKind = _selectionBrushDragKind;
      final didManipulate = _selectionBrushDidManipulate;
      if (didManipulate) {
        _completeSelectionBrushInteraction();
      } else {
        _cancelSelectionBrushInteraction();
        if (brushKind == _SelectionBrushDragKind.move) {
          _handleTapForTooltip();
        }
      }
      coordinator.endInteraction();
      coordinator.releaseMode();
      _delegate.markNeedsPaint();
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

    // Complete or release the value summary panel interaction. A press on
    // the panel must never tap-tooltip or select the data beneath it.
    bool valueSummaryHandled = false;
    if (_movingValueSummary != null) {
      final target = _movingValueSummary!;
      _delegate.commitValueSummaryDrag();
      _movingValueSummary = null;
      _moveValueSummaryStartPosition = null;
      _moveValueSummaryStartOrigin = null;
      valueSummaryHandled = true;
      // Keep the move cursor while the pointer is still over the (possibly
      // clamped) panel; the next hover hit test takes over from here.
      _delegate.onCursorChange?.call(
        target.hitTest(_delegate.widgetToPlot(position))
            ? SystemMouseCursors.move
            : SystemMouseCursors.basic,
      );
    }
    if (_potentialDragValueSummary != null) {
      // Click without a drag: keyboard focus was granted on pointer-down.
      _potentialDragValueSummary = null;
      _potentialDragValueSummaryStart = null;
      valueSummaryHandled = true;
    }

    // Handle potential drags that never exceeded threshold
    _handlePotentialDragReleases(event, completedResizeOrMove);

    // Clear annotation move states
    _clearAnnotationMoveStates(event);

    // Clear pan state
    _completePan();

    // Handle tap on marker for tap-triggered tooltips
    if (!valueSummaryHandled && allowTapActivation) {
      _handleTapForTooltip();
    }

    // Clear cursor position
    _cursorPosition = null;

    // Release interaction
    coordinator.endInteraction();
    coordinator.releaseMode();
    _delegate.markNeedsPaint();
  }

  void _handlePointerCancel() {
    if (_movingValueSummary != null) {
      _delegate.cancelValueSummaryDrag();
      _movingValueSummary = null;
      _moveValueSummaryStartPosition = null;
      _moveValueSummaryStartOrigin = null;
    }
    _potentialDragValueSummary = null;
    _potentialDragValueSummaryStart = null;
    _cancelSelectionBrushInteraction();
    _delegate.coordinator.setPressedMarker(null);
    _delegate.coordinator.endInteraction();
    _delegate.coordinator.releaseMode(force: true);
    _delegate.markNeedsPaint();
  }

  void _completeSelectionBrushInteraction() {
    final rect = _activeSelectionBrushRect ?? _selectionBrushStartRect;
    _pendingSelectionBrushRect = null;
    if (rect != null) {
      final result = _delegate.selectionGestureForWidgetRect(
        rect,
        isPersistentBrushUpdate: true,
        isFinal: true,
      );
      if (result != null) {
        _delegate.onSelectionGestureComplete?.call(result);
      }
    }
    _clearSelectionBrushInteractionState(preserveActiveRect: rect != null);
    if (rect != null) {
      // Keep the live rectangle through the frame that transfers the final
      // data-domain range back into the RenderBox. Clearing it synchronously
      // would paint the previously committed range for one frame.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (_selectionBrushDragKind == null &&
            identical(_activeSelectionBrushRect, rect)) {
          _activeSelectionBrushRect = null;
          _delegate.markNeedsPaint();
        }
      });
    }
  }

  void _cancelSelectionBrushInteraction({bool restoreStartRect = false}) {
    final startRect = _selectionBrushStartRect;
    _pendingSelectionBrushRect = null;
    if (restoreStartRect && startRect != null) {
      final result = _delegate.selectionGestureForWidgetRect(
        startRect,
        isPersistentBrushUpdate: true,
        isFinal: true,
      );
      if (result != null) {
        _delegate.onSelectionGestureComplete?.call(result);
      }
    }
    _clearSelectionBrushInteractionState();
  }

  void _clearSelectionBrushInteractionState({bool preserveActiveRect = false}) {
    _selectionBrushDragKind = null;
    _selectionBrushStartRect = null;
    if (!preserveActiveRect) _activeSelectionBrushRect = null;
    _selectionBrushStartPointer = null;
    _selectionBrushDidManipulate = false;
  }

  void _completeBoxSelection() {
    final coordinator = _delegate.coordinator;
    final hits = List<ChartDataHit>.unmodifiable(coordinator.previewDataHits);
    final selection =
        (_delegate.interactionConfig ?? const InteractionConfig()).selection;
    final boxRect = coordinator.boxSelectionRect;
    final transform = _delegate.transform;
    double? minimumX;
    double? maximumX;
    double? minimumY;
    double? maximumY;
    Rect? plotBounds;
    if (boxRect != null && transform != null) {
      final firstPlot = _delegate.widgetToPlot(boxRect.topLeft);
      final secondPlot = _delegate.widgetToPlot(boxRect.bottomRight);
      plotBounds = Rect.fromPoints(firstPlot, secondPlot);
      final first = transform.plotToData(firstPlot.dx, firstPlot.dy);
      final second = transform.plotToData(secondPlot.dx, secondPlot.dy);
      minimumX = math.min(first.dx, second.dx);
      maximumX = math.max(first.dx, second.dx);
      minimumY = math.min(first.dy, second.dy);
      maximumY = math.max(first.dy, second.dy);
    }
    coordinator.clearPreviewSelection();
    _delegate.onSelectionGestureComplete?.call(
      ChartSelectionGestureResult(
        acquisitionMode: selection.acquisitionMode,
        hits: hits,
        minimumXInclusive: minimumX,
        maximumXInclusive: maximumX,
        minimumYInclusive: minimumY,
        maximumYInclusive: maximumY,
        plotBounds: plotBounds,
      ),
    );
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

        final startX = topLeft.dx < bottomRight.dx
            ? topLeft.dx
            : bottomRight.dx;
        final endX = topLeft.dx > bottomRight.dx ? topLeft.dx : bottomRight.dx;

        double startY;
        double endY;

        if (_delegate.isPerSeriesMode) {
          // For perSeries mode, calculate normalized Y the SAME way crosshair does:
          // normalizedY = (plotArea.bottom - pixelY) / plotArea.height
          // This gives a true 0-1 value (0 at bottom, 1 at top)
          final normalizedTopY =
              (plotArea.bottom - boxRect.top) / plotArea.height;
          final normalizedBottomY =
              (plotArea.bottom - boxRect.bottom) / plotArea.height;

          // Denormalize using axisBounds (same as crosshair)
          final (denormStartY, denormEndY) = _delegate.denormalizeYRange(
            normalizedBottomY < normalizedTopY
                ? normalizedBottomY
                : normalizedTopY,
            normalizedBottomY > normalizedTopY
                ? normalizedBottomY
                : normalizedTopY,
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
        final leftData = transform.plotToData(
          resizedBounds.left,
          resizedBounds.top,
        );
        final rightData = transform.plotToData(
          resizedBounds.right,
          resizedBounds.bottom,
        );

        var newStartX = leftData.dx;
        var newEndX = rightData.dx;
        double? newStartY;
        double? newEndY;

        if (resizedAnnotation.startY != null &&
            resizedAnnotation.endY != null) {
          if (_delegate.isPerSeriesMode) {
            // For perSeries mode, calculate normalized Y the SAME way crosshair does:
            // normalizedY = (plotArea.bottom - pixelY) / plotArea.height
            final normalizedTopY =
                (plotArea.bottom - resizedBounds.top) / plotArea.height;
            final normalizedBottomY =
                (plotArea.bottom - resizedBounds.bottom) / plotArea.height;

            // Denormalize using axisBounds (same as crosshair)
            final (denormStartY, denormEndY) = _delegate.denormalizeYRange(
              normalizedBottomY < normalizedTopY
                  ? normalizedBottomY
                  : normalizedTopY,
              normalizedBottomY > normalizedTopY
                  ? normalizedBottomY
                  : normalizedTopY,
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
          (newStartX, newEndX, newStartY, newEndY) = _applyResizeSnapping(
            resizedAnnotation,
            transform,
            resizeDirection,
            newStartX,
            newEndX,
            newStartY,
            newEndY,
          );
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
    final xTolerance =
        (transform.dataXMax - transform.dataXMin) * annotation.snapTolerance;
    // Use actual Y range for tolerance (not transform range which is 0-1 in perSeries mode)
    final (yMin, yMax) = _delegate.getActualYRange();
    final yTolerance = (yMax - yMin) * annotation.snapTolerance;

    final needsSnapStartX =
        direction == ResizeDirection.left ||
        direction == ResizeDirection.topLeft ||
        direction == ResizeDirection.bottomLeft;
    final needsSnapEndX =
        direction == ResizeDirection.right ||
        direction == ResizeDirection.topRight ||
        direction == ResizeDirection.bottomRight;
    final needsSnapStartY =
        direction == ResizeDirection.bottom ||
        direction == ResizeDirection.bottomLeft ||
        direction == ResizeDirection.bottomRight;
    final needsSnapEndY =
        direction == ResizeDirection.top ||
        direction == ResizeDirection.topLeft ||
        direction == ResizeDirection.topRight;

    var newStartX = startX;
    var newEndX = endX;
    var newStartY = startY;
    var newEndY = endY;

    if (needsSnapStartX) {
      final snapped = _findNearestDataValue(
        startX,
        axis: 'x',
        tolerance: xTolerance,
      );
      if (snapped != null) newStartX = snapped;
    }
    if (needsSnapEndX) {
      final snapped = _findNearestDataValue(
        endX,
        axis: 'x',
        tolerance: xTolerance,
      );
      if (snapped != null) newEndX = snapped;
    }
    if (needsSnapStartY && startY != null) {
      final snapped = _findNearestDataValue(
        startY,
        axis: 'y',
        tolerance: yTolerance,
      );
      if (snapped != null) newStartY = snapped;
    }
    if (needsSnapEndY && endY != null) {
      final snapped = _findNearestDataValue(
        endY,
        axis: 'y',
        tolerance: yTolerance,
      );
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
        final leftData = transform.plotToData(
          movedBounds.left,
          movedBounds.top,
        );
        final rightData = transform.plotToData(
          movedBounds.right,
          movedBounds.bottom,
        );

        var newStartX = leftData.dx;
        var newEndX = rightData.dx;
        double? newStartY;
        double? newEndY;

        if (movedAnnotation.startY != null && movedAnnotation.endY != null) {
          if (_delegate.isPerSeriesMode) {
            // For perSeries mode, calculate normalized Y the SAME way crosshair does:
            // normalizedY = (plotArea.bottom - pixelY) / plotArea.height
            final normalizedTopY =
                (plotArea.bottom - movedBounds.top) / plotArea.height;
            final normalizedBottomY =
                (plotArea.bottom - movedBounds.bottom) / plotArea.height;

            // Denormalize using axisBounds (same as crosshair)
            final (denormStartY, denormEndY) = _delegate.denormalizeYRange(
              normalizedBottomY < normalizedTopY
                  ? normalizedBottomY
                  : normalizedTopY,
              normalizedBottomY > normalizedTopY
                  ? normalizedBottomY
                  : normalizedTopY,
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
          final xTolerance =
              (transform.dataXMax - transform.dataXMin) *
              movedAnnotation.snapTolerance;
          // Use actual Y range for tolerance (not transform range which is 0-1 in perSeries mode)
          final (yMin, yMax) = _delegate.getActualYRange();
          final yTolerance = (yMax - yMin) * movedAnnotation.snapTolerance;

          if (movedAnnotation.startX != null && movedAnnotation.endX != null) {
            final snappedStartX = _findNearestDataValue(
              newStartX,
              axis: 'x',
              tolerance: xTolerance,
            );
            if (snappedStartX != null) {
              final width = newEndX - newStartX;
              newStartX = snappedStartX;
              newEndX = newStartX + width;
            }
          }

          if (movedAnnotation.startY != null &&
              movedAnnotation.endY != null &&
              newStartY != null &&
              newEndY != null) {
            final snappedStartY = _findNearestDataValue(
              newStartY,
              axis: 'y',
              tolerance: yTolerance,
            );
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

  void _handlePotentialDragReleases(
    PointerUpEvent event,
    bool completedResizeOrMove,
  ) {
    // Handle deferred empty-area click (was deferred from pointer-down)
    if (_pointerDownOnEmptyArea) {
      final coordinator = _delegate.coordinator;
      // Empty chart space dismisses only the tap-pinned popup. A persistent
      // brush remains authoritative and is reconciled by the host callback.
      clearTappedMarker();
      coordinator.setHoveredMarker(null);
      coordinator.clearSelection();
      _delegate.markSpatialIndexDirty();
      if (_emptyAreaClickPosition != null && _emptyAreaClickEvent != null) {
        _delegate.onEmptyAreaClick?.call(
          _emptyAreaClickPosition!,
          _emptyAreaClickEvent!,
        );
      }
      _delegate.markNeedsPaint();
      _pointerDownOnEmptyArea = false;
      _emptyAreaClickPosition = null;
      _emptyAreaClickEvent = null;
    }

    // Handle deferred non-draggable element selection (was deferred from pointer-down)
    if (_potentialSelectElement != null) {
      final coordinator = _delegate.coordinator;
      final enableSelection =
          _delegate.interactionConfig?.enableSelection ?? true;
      if (enableSelection) {
        if (coordinator.isCtrlPressed) {
          coordinator.toggleElementSelection(_potentialSelectElement!);
        } else {
          coordinator.selectElement(_potentialSelectElement!);
        }
        _delegate.markSpatialIndexDirty();
        coordinator.claimMode(
          InteractionMode.selecting,
          element: _potentialSelectElement,
        );
        _delegate.onElementClick?.call(
          _potentialSelectElement!,
          _potentialSelectEvent ?? event,
        );
      }
      _potentialSelectElement = null;
      _potentialSelectEvent = null;
    }

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
      _delegate.markSpatialIndexDirty();
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
      final newIndex =
          _candidateDataPointIndex ??
          _originalDataPointIndex ??
          movedAnnotation.dataPointIndex;

      _movingPointAnnotation!.clearCandidateIndex();
      _movingPointAnnotation = null;
      _originalDataPointIndex = null;
      _candidateDataPointIndex = null;

      if (_delegate.onAnnotationChanged != null &&
          newIndex != movedAnnotation.dataPointIndex) {
        final updatedAnnotation = movedAnnotation.copyWith(
          dataPointIndex: newIndex,
        );
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

      if (_delegate.onAnnotationChanged != null &&
          newPosition != originalPosition) {
        final updatedAnnotation = movedAnnotation.copyWith(
          position: newPosition,
        );
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

      if (_delegate.onAnnotationChanged != null &&
          (newX != originalX || newY != originalY)) {
        final updatedAnnotation = movedAnnotation.copyWith(x: newX, y: newY);
        _delegate.onAnnotationChanged!(movedAnnotation.id, updatedAnnotation);
      }
    }

    // LegendAnnotation
    if (_movingLegendAnnotation != null) {
      final originalPosition =
          _movingLegendAnnotation!.annotation.customPosition;
      final tempPosition = _movingLegendAnnotation!.tempPosition;
      final newPosition = tempPosition ?? originalPosition;

      _movingLegendAnnotation!.clearTempPosition();
      final movedAnnotation = _movingLegendAnnotation!.annotation;

      _movingLegendAnnotation = null;
      _moveLegendStartPosition = null;

      if (_delegate.onAnnotationChanged != null &&
          newPosition != originalPosition) {
        final updatedAnnotation = movedAnnotation.copyWith(
          customPosition: newPosition,
        );
        _delegate.onAnnotationChanged!(movedAnnotation.id, updatedAnnotation);
      }
    }
  }

  void _completePan() {
    final wasPanning =
        _delegate.coordinator.currentMode == InteractionMode.panning;
    _lastPanPosition = null;

    if (wasPanning) {
      _delegate.updateAxesFromTransform();
      _delegate.rebuildElementsWithTransform();
      _delegate.invalidateSeriesCache();
    }
  }

  void _handleTapForTooltip() {
    final coordinator = _delegate.coordinator;
    final config =
        _delegate.interactionConfig?.tooltip ?? const TooltipConfig();

    final supportsTap =
        config.triggerMode == TooltipTriggerMode.tap ||
        config.triggerMode == TooltipTriggerMode.both;
    if (!supportsTap ||
        coordinator.isPanning ||
        coordinator.currentMode == InteractionMode.panning) {
      return;
    }

    final hoveredMarker = coordinator.hoveredMarker;
    if (hoveredMarker == null) {
      // A click on empty plot or empty persistent-brush body is an explicit
      // dismissal surface. It must not require hiding the brush itself.
      clearTappedMarker();
      return;
    }

    if (_tappedMarker == hoveredMarker) {
      _tappedMarker = null;
    } else {
      _tappedMarker = hoveredMarker;
    }
  }

  // ==========================================================================
  // Pointer Hover Handler
  // ==========================================================================

  void _handlePointerHover(PointerHoverEvent event, Offset position) {
    final coordinator = _delegate.coordinator;

    final retainTrackingCursor =
        !_delegate.plotArea.contains(position) &&
        (_delegate.interactionConfig?.crosshair.persistOnPointerExit ?? false);
    if (!retainTrackingCursor) {
      _cursorPosition = position;
    }
    _delegate.markNeedsPaint();

    // Check scrollbar hover first
    if (_delegate.checkScrollbarHover(position)) {
      _setSelectionBrushHovered(false);
      return;
    }

    // Hover is passive during panning
    if (coordinator.isPanning) {
      _setHoveredElement(null);
      coordinator.setHoveredMarker(null);
      _delegate.onCursorChange?.call(SystemMouseCursors.basic);
      return;
    }

    final selection =
        _delegate.interactionConfig?.selection ?? const ChartSelectionConfig();
    final brushRect = _delegate.selectionBrushWidgetRect;
    final brushKind = selection.brush.enabled && brushRect != null
        ? _selectionBrushHitKind(position, brushRect, selection)
        : null;
    if (brushKind != null) {
      _setSelectionBrushHovered(true);
      _setHoveredElement(null);
      if (brushKind == _SelectionBrushDragKind.move &&
          selection.scope.includesMarks) {
        // The brush body is a movable visual surface, but its interior remains
        // data-active until a drag actually begins. Resize handles retain
        // exclusive ownership so their larger hit targets cannot activate a
        // nearby datum accidentally.
        _updateHoveredMarker(position);
      } else {
        coordinator.setHoveredMarker(null);
      }
      final mode = _delegate.selectionBrushState?.acquisitionMode;
      _delegate.onCursorChange?.call(
        brushKind == _SelectionBrushDragKind.move || mode == null
            ? SystemMouseCursors.move
            : _selectionBrushResizeCursor(mode, brushKind),
      );
      return;
    }
    _setSelectionBrushHovered(false);

    // Resolve marker feedback first. In the dual-target scope a marker inside
    // its configured radius wins exclusively; only the remaining path corridor
    // may expose complete-series feedback.
    if (selection.scope.includesMarks) {
      _updateHoveredMarker(position);
    } else {
      coordinator.setHoveredMarker(null);
    }

    if (selection.scope == ChartSelectionScope.markOrWholeSeries &&
        coordinator.hoveredMarker != null) {
      _hitTestDebounceTimer?.cancel();
      _pendingHitTestPosition = null;
      _setHoveredElement(null);
      _delegate.markNeedsPaint();
      return;
    }

    if (selection.scope.includesWholeSeries &&
        selection.acquisitionMode == ChartSelectionAcquisitionMode.point) {
      // Series selection needs immediate enter/exit feedback. A debounce waits
      // until pointer movement stops and leaves the old path highlighted.
      _hitTestDebounceTimer?.cancel();
      _pendingHitTestPosition = position;
      _performDeferredHitTest();
      return;
    }

    // Throttle expensive hit testing
    _pendingHitTestPosition = position;
    _hitTestDebounceTimer?.cancel();
    _hitTestDebounceTimer = Timer(_hitTestThrottleDuration, () {
      _performDeferredHitTest();
    });
  }

  void _setSelectionBrushHovered(bool value) {
    if (_selectionBrushHovered == value) return;
    _selectionBrushHovered = value;
    _delegate.markNeedsPaint();
  }

  void _performDeferredHitTest() {
    final position = _pendingHitTestPosition;
    if (position == null) return;

    _pendingHitTestPosition = null;

    final hitElement = _delegate.hitTestElements(position);

    if (hitElement is ResizeHandleElement) {
      final cursor = _getCursorForResizeDirection(hitElement.direction);
      _delegate.onCursorChange?.call(cursor);
      _setHoveredElement(hitElement.parentAnnotation);
      _delegate.onElementHover?.call(hitElement.parentAnnotation);
      _delegate.markNeedsPaint();
      return;
    }

    _delegate.onCursorChange?.call(_cursorForHoveredElement(hitElement));
    _setHoveredElement(hitElement);
    _delegate.onElementHover?.call(hitElement);
    _delegate.markNeedsPaint();
  }

  void _setHoveredElement(ChartElement? element) {
    final previous = _delegate.coordinator.hoveredElement;
    final previousHadPathFeedback = _usesPathHoverFeedback(previous);
    _delegate.coordinator.setHoveredElement(element);
    final current = _delegate.coordinator.hoveredElement;
    if (current is SeriesElement &&
        !(_delegate.interactionConfig?.selection.scope.includesWholeSeries ??
            false)) {
      current.onHoverExit();
    }
    final currentHasPathFeedback = _usesPathHoverFeedback(current);
    if (identical(previous, current) &&
        previousHadPathFeedback == currentHasPathFeedback) {
      return;
    }
    if (previousHadPathFeedback || currentHasPathFeedback) {
      // Line and Area paths live in the cached series picture. Invalidate only
      // when the hovered path identity changes, never for pointer movement
      // within the same 44 logical-pixel acquisition corridor.
      _delegate.invalidateSeriesCache();
    }
  }

  bool _usesPathHoverFeedback(ChartElement? element) =>
      element is SeriesElement &&
      element.isHovered &&
      (element.series is LineChartSeries ||
          element.series is AreaChartSeries ||
          element.series is RangeAreaChartSeries);

  void _updateHoveredMarker(Offset widgetPosition) {
    if (!(_delegate.interactionConfig?.enabled ?? true)) {
      _delegate.coordinator.setHoveredMarker(null);
      return;
    }
    if (_delegate.transform == null) {
      _delegate.coordinator.setHoveredMarker(null);
      return;
    }

    final plotPosition = _delegate.widgetToPlot(widgetPosition);
    final snapRadius =
        _delegate.interactionConfig?.selection.dataPointHitRadius ?? 20;

    HoveredMarkerInfo? nearestMarker;
    double minDistance = snapRadius;

    // The draggable summary panel owns the pointer within its painted
    // bounds: data beneath it must not marker-highlight or tooltip under
    // the panel's move cursor, matching the press path's suppression. The
    // fixed overlay and a non-draggable panel never hit-test, so hover
    // keeps resolving through them (spec).
    final summaryTarget = _delegate.valueSummaryDragTarget;
    final overSummaryPanel =
        summaryTarget != null && summaryTarget.hitTest(plotPosition);

    if (!overSummaryPanel) {
      final seriesElements = _delegate.elements
          .whereType<SeriesElement>()
          .toList();

      // Bars own their complete rectangle, not only the value-end marker.
      // Prefer later-painted series so overlaid front layers receive
      // interaction first.
      for (final element in seriesElements.reversed) {
        if (element.series is! BarChartSeries) continue;
        final geometry = element.barGeometryAt(plotPosition);
        if (geometry == null) continue;
        nearestMarker = HoveredMarkerInfo(
          seriesId: element.id,
          markerIndex: geometry.pointIndex,
          plotPosition: geometry.valueEndPoint,
          dataHit: element.dataHitForPointIndex(geometry.pointIndex),
        );
        minDistance = 0;
        break;
      }

      final dataHitElements =
          _delegate.elements.whereType<DataHitElement>().toList()
            ..sort((a, b) => b.priority.compareTo(a.priority));
      for (final element in dataHitElements) {
        if (minDistance == 0) break;
        final hit = element.dataHitAt(plotPosition, maxDistance: snapRadius);
        if (hit == null) continue;
        // Pie-style shares and Radial Bar tracks own their complete painted
        // area. Their tooltip anchor is a presentation position, not a
        // proximity target; remeasuring against it would reject hover across
        // most of a long arc even though the renderer already confirmed an
        // exact path hit.
        final ownsCompletePaintedArea =
            hit.share != null || element.series is RadialBarChartSeries;
        final distance = ownsCompletePaintedArea
            ? 0.0
            : (plotPosition - hit.plotPosition).distance;
        if (distance < minDistance) {
          minDistance = distance;
          nearestMarker = HoveredMarkerInfo(
            seriesId: hit.seriesId,
            markerIndex: hit.pointIndex,
            plotPosition: hit.plotPosition,
            dataHit: hit,
          );
        }
      }
    }

    final previousMarker = _delegate.coordinator.hoveredMarker;
    _delegate.coordinator.setHoveredMarker(nearestMarker);
    if (nearestMarker?.dataHit?.activationHint != null) {
      _delegate.onCursorChange?.call(SystemMouseCursors.click);
    }

    final markerChanged =
        (previousMarker == null) != (nearestMarker == null) ||
        (previousMarker != null &&
            nearestMarker != null &&
            (previousMarker.seriesId != nearestMarker.seriesId ||
                previousMarker.markerIndex != nearestMarker.markerIndex));

    final cachedMarkerFeedbackChanged =
        _usesCachedMarkerFeedback(previousMarker) ||
        _usesCachedMarkerFeedback(nearestMarker);
    if (markerChanged && cachedMarkerFeedbackChanged) {
      _delegate.invalidateSeriesCache();
      final element = nearestMarker == null
          ? null
          : _delegate.elements
                .whereType<DataHitElement>()
                .cast<ChartElement?>()
                .firstWhere(
                  (candidate) => candidate?.id == nearestMarker!.seriesId,
                  orElse: () => null,
                );
      _delegate.onElementHover?.call(element);
    }
  }

  bool _usesCachedMarkerFeedback(HoveredMarkerInfo? marker) {
    if (marker == null) return false;
    for (final element in _delegate.elements.whereType<DataHitElement>()) {
      if (element.id == marker.seriesId) {
        return element.series is! BarChartSeries &&
            element.series is! RangeAreaChartSeries &&
            element.series is! HeatmapChartSeries;
      }
    }
    return false;
  }

  // ==========================================================================
  // Pointer Scroll Handler
  // ==========================================================================

  void _handlePointerScroll(PointerScrollEvent event, Offset position) {
    final coordinator = _delegate.coordinator;

    final enableZoom = _delegate.interactionConfig?.enableZoom ?? true;
    if (!enableZoom) return;

    if (coordinator.currentMode == InteractionMode.scrollbarDragging) return;

    // An unmodified wheel belongs to the host scroll view. Claiming the chart's
    // zoom mode here, despite applying no transform, temporarily suspended and
    // cleared synchronized tracking while the page moved beneath the pointer.
    if (!coordinator.isShiftPressed ||
        _delegate.transform == null ||
        _delegate.originalTransform == null) {
      return;
    }

    _delegate.onViewportInteracted?.call();
    coordinator.claimMode(InteractionMode.zooming);

    final double scrollAmount = event.scrollDelta.dy;
    const double zoomSensitivity = 0.0011;
    final double zoomFactor = 1.0 - (scrollAmount * zoomSensitivity);

    final Offset plotPosition = _delegate.widgetToPlot(position);

    // Mouse wheel zoom: no animation for responsive feel during rapid scrolling
    _delegate.zoomChart(zoomFactor, plotCenter: plotPosition, animate: false);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!coordinator.isDisposed &&
          coordinator.currentMode == InteractionMode.zooming) {
        coordinator.releaseMode();
      }
    });
  }

  // ==========================================================================
  // Perform Operations (Drag Logic)
  // ==========================================================================

  void _performResize(Offset currentPosition, Offset startPosition) {
    if (_resizingAnnotation == null ||
        _activeResizeDirection == null ||
        _resizeStartBounds == null) {
      return;
    }

    final delta = currentPosition - startPosition;
    final oldBounds = _resizeStartBounds!;
    Rect newBounds;

    switch (_activeResizeDirection!) {
      case ResizeDirection.topLeft:
        newBounds = Rect.fromLTRB(
          oldBounds.left + delta.dx,
          oldBounds.top + delta.dy,
          oldBounds.right,
          oldBounds.bottom,
        );
      case ResizeDirection.topRight:
        newBounds = Rect.fromLTRB(
          oldBounds.left,
          oldBounds.top + delta.dy,
          oldBounds.right + delta.dx,
          oldBounds.bottom,
        );
      case ResizeDirection.bottomLeft:
        newBounds = Rect.fromLTRB(
          oldBounds.left + delta.dx,
          oldBounds.top,
          oldBounds.right,
          oldBounds.bottom + delta.dy,
        );
      case ResizeDirection.bottomRight:
        newBounds = Rect.fromLTRB(
          oldBounds.left,
          oldBounds.top,
          oldBounds.right + delta.dx,
          oldBounds.bottom + delta.dy,
        );
      case ResizeDirection.top:
        newBounds = Rect.fromLTRB(
          oldBounds.left,
          oldBounds.top + delta.dy,
          oldBounds.right,
          oldBounds.bottom,
        );
      case ResizeDirection.right:
        newBounds = Rect.fromLTRB(
          oldBounds.left,
          oldBounds.top,
          oldBounds.right + delta.dx,
          oldBounds.bottom,
        );
      case ResizeDirection.bottom:
        newBounds = Rect.fromLTRB(
          oldBounds.left,
          oldBounds.top,
          oldBounds.right,
          oldBounds.bottom + delta.dy,
        );
      case ResizeDirection.left:
        newBounds = Rect.fromLTRB(
          oldBounds.left + delta.dx,
          oldBounds.top,
          oldBounds.right,
          oldBounds.bottom,
        );
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

    _publishRangeAnnotationDragUpdate(_resizingAnnotation!, newBounds);
  }

  void _performMove(Offset currentPosition) {
    if (_movingAnnotation == null ||
        _moveStartPosition == null ||
        _moveStartBounds == null) {
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
    _publishRangeAnnotationDragUpdate(_movingAnnotation!, newBounds);
  }

  void _publishRangeAnnotationDragUpdate(
    RangeAnnotationElement element,
    Rect bounds,
  ) {
    final callback = _delegate.onAnnotationDragUpdate;
    if (callback == null) return;
    final seriesElements = _delegate.elements.whereType<SeriesElement>();
    if (seriesElements.isEmpty) return;

    final annotation = element.annotation;
    final transform = seriesElements.first.transform;
    final leftData = transform.plotToData(bounds.left, bounds.top);
    final rightData = transform.plotToData(bounds.right, bounds.bottom);
    double? startY;
    double? endY;

    if (annotation.startY != null || annotation.endY != null) {
      if (_delegate.isPerSeriesMode) {
        final plotArea = _delegate.plotArea;
        final normalizedTopY = (plotArea.bottom - bounds.top) / plotArea.height;
        final normalizedBottomY =
            (plotArea.bottom - bounds.bottom) / plotArea.height;
        final (denormalizedStartY, denormalizedEndY) = _delegate
            .denormalizeYRange(
              math.min(normalizedBottomY, normalizedTopY),
              math.max(normalizedBottomY, normalizedTopY),
            );
        if (annotation.startY != null) startY = denormalizedStartY;
        if (annotation.endY != null) endY = denormalizedEndY;
      } else {
        if (annotation.startY != null) startY = rightData.dy;
        if (annotation.endY != null) endY = leftData.dy;
      }
    }

    callback(
      annotation.id,
      annotation.copyWith(
        startX: annotation.startX != null ? leftData.dx : null,
        endX: annotation.endX != null ? rightData.dx : null,
        startY: startY,
        endY: endY,
      ),
    );
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

  void _performValueSummaryMove(Offset currentPosition) {
    final startPosition = _moveValueSummaryStartPosition;
    final startOrigin = _moveValueSummaryStartOrigin;
    if (_movingValueSummary == null ||
        startPosition == null ||
        startOrigin == null) {
      return;
    }

    final delta =
        _delegate.widgetToPlot(currentPosition) -
        _delegate.widgetToPlot(startPosition);
    _delegate.updateValueSummaryDrag(startOrigin + delta);
  }

  void _performTextAnnotationMove(Offset currentPosition) {
    if (_movingTextAnnotation == null || _moveTextStartPosition == null) return;

    final delta = currentPosition - _moveTextStartPosition!;
    final originalPosition = _movingTextAnnotation!.annotation.position;
    final newPosition = originalPosition + delta;

    _movingTextAnnotation!.updateTempPosition(newPosition);
  }

  void _performThresholdAnnotationMove(Offset currentPosition) {
    if (_movingThresholdAnnotation == null ||
        _moveThresholdStartPosition == null ||
        _moveThresholdStartValue == null) {
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
    if (_movingPinAnnotation == null ||
        _movePinStartPosition == null ||
        _movePinStartX == null ||
        _movePinStartY == null) {
      return;
    }

    final transform = _delegate.transform;
    if (transform == null) return;

    final dataStart = transform.plotToData(
      _movePinStartPosition!.dx,
      _movePinStartPosition!.dy,
    );
    final dataEnd = transform.plotToData(
      currentPosition.dx,
      currentPosition.dy,
    );

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
    final newTopLeft = Offset(
      currentBounds.left + delta.dx,
      currentBounds.top + delta.dy,
    );

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

  double? _findNearestDataValue(
    double targetValue, {
    required String axis,
    required double tolerance,
  }) {
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

  MouseCursor _cursorForHoveredElement(ChartElement? element) {
    if (element is ValueSummaryAnnotationElement && element.isDraggable) {
      // The spec asks for the platform move cursor over the draggable
      // summary panel (unlike the grab/grabbing pair used by annotations).
      return SystemMouseCursors.move;
    }
    if (element is RangeAnnotationElement && element.isDraggable) {
      return SystemMouseCursors.grab;
    }
    if (element is SeriesElement) return SystemMouseCursors.click;
    return SystemMouseCursors.basic;
  }
}
