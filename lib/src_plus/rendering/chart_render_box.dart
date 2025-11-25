// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../axis/axis.dart' as chart_axis;
import '../axis/axis_renderer.dart';
import '../coordinates/chart_transform.dart';
import '../elements/annotation_elements.dart';
import '../elements/resize_handle_element.dart';
import '../elements/series_element.dart';
import '../elements/simulated_annotation.dart';
import '../interaction/core/chart_element.dart';
import '../interaction/core/coordinator.dart';
import '../interaction/core/element_types.dart';
import '../interaction/core/hit_test_strategy.dart';
import '../interaction/core/interaction_mode.dart';
import '../models/chart_annotation.dart';
import '../models/chart_series.dart';
import '../models/chart_theme.dart';
import '../models/interaction_config.dart';
import '../theming/components/scrollbar_config.dart';
import '../widgets/scrollbar/hit_test_zone.dart';
import '../widgets/scrollbar/scrollbar_controller.dart';
import '../widgets/scrollbar/scrollbar_interaction.dart';
import '../widgets/scrollbar/scrollbar_painter.dart';
import '../widgets/scrollbar/scrollbar_state.dart';
import 'spatial_index.dart';

/// Callback for generating chart elements based on current transform.
/// Used for zoom/pan to regenerate elements from original data coordinates.
typedef ElementGenerator = List<ChartElement> Function(ChartTransform transform);

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
    ElementGenerator? elementGenerator,
    ChartTheme? theme,
    bool tooltipsEnabled = true,
    bool showXScrollbar = false,
    bool showYScrollbar = false,
    ScrollbarConfig? scrollbarTheme,
    InteractionConfig? interactionConfig,
    this.onElementClick,
    this.onElementHover,
    this.onEmptyAreaClick,
    this.onCursorChange,
    this.onAnnotationChanged,
    this.onRangeCreationComplete,
  })  : _elementGenerator = elementGenerator,
        _theme = theme,
        _tooltipsEnabled = tooltipsEnabled,
        _showXScrollbar = showXScrollbar,
        _showYScrollbar = showYScrollbar,
        _scrollbarTheme = scrollbarTheme,
        _interactionConfig = interactionConfig,
        assert((elements != null) != (elementGenerator != null), 'Must provide either elements or elementGenerator, but not both') {
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

  /// Optional callback for generating elements from current transform.
  /// If provided, elements will be regenerated on zoom/pan operations.
  ElementGenerator? _elementGenerator;

  /// Version number to track when element generator actually changed.
  /// Only regenerate elements when this version increments.
  int _elementGeneratorVersion = 0;

  /// Current theme for the chart (colors, styles, etc.)
  ChartTheme? _theme;

  /// Interaction coordinator for conflict resolution.
  final ChartInteractionCoordinator coordinator;

  /// Callback for element click events.
  final void Function(ChartElement element, PointerEvent event)? onElementClick;

  /// Callback for element hover events.
  void Function(ChartElement? element)? onElementHover;

  /// Callback for empty area click (for box select start).
  final void Function(Offset position, PointerEvent event)? onEmptyAreaClick;

  /// Callback for cursor changes.
  final void Function(MouseCursor cursor)? onCursorChange;

  /// Callback for annotation changes (e.g., after drag-to-resize).
  ///
  /// Called when an annotation is modified through user interaction.
  /// The [annotationId] is the ID of the modified annotation, and
  /// [updatedAnnotation] is the new annotation object with updated values.
  final void Function(String annotationId, ChartAnnotation updatedAnnotation)? onAnnotationChanged;

  /// Callback for range annotation creation completion.
  ///
  /// Called when user completes drag in rangeAnnotationCreation mode.
  /// Provides data coordinates of dragged rectangle (startX, endX, startY, endY).
  final void Function(double startX, double endX, double startY, double endY)? onRangeCreationComplete;

  /// Current resize state (if resizing annotation).
  // Current resize state (if resizing annotation).
  ResizeDirection? _activeResizeDirection;
  RangeAnnotationElement? _resizingAnnotation;
  Rect? _resizeStartBounds;

  /// Current move state (if moving RangeAnnotation).
  RangeAnnotationElement? _movingAnnotation;
  Offset? _moveStartPosition;
  Rect? _moveStartBounds;

  /// Current move state (if moving TextAnnotation).
  TextAnnotationElement? _movingTextAnnotation;
  Offset? _moveTextStartPosition;

  /// Current move state (if moving PointAnnotation).
  PointAnnotationElement? _movingPointAnnotation;
  int? _originalDataPointIndex;
  int? _candidateDataPointIndex;

  /// Potential drag state for click-and-hold pattern on PointAnnotation.
  /// When user clicks on PointAnnotation, we don't immediately start dragging.
  /// Instead, we wait to see if they move the pointer (drag) or release quickly (click to select).
  PointAnnotationElement? _potentialDragPointAnnotation;
  Offset? _potentialDragStartPosition;
  static const double _dragThresholdPixels = 5.0; // Minimum movement to trigger drag

  /// Potential drag state for click-and-hold pattern on RangeAnnotation.
  /// Same pattern as PointAnnotation - wait for movement to distinguish click from drag.
  RangeAnnotationElement? _potentialDragRangeAnnotation;
  Offset? _potentialDragRangeStartPosition;
  Rect? _potentialDragRangeStartBounds;

  /// Potential drag state for click-and-hold pattern on TextAnnotation.
  /// Wait for movement to decide: click (select) or drag (reposition).
  TextAnnotationElement? _potentialDragTextAnnotation;
  Offset? _potentialDragTextStartPosition;

  /// Potential drag state for click-and-hold pattern on ThresholdAnnotation.
  /// Wait for movement to decide: click (select) or drag (move along axis).
  ThresholdAnnotationElement? _potentialDragThresholdAnnotation;
  Offset? _potentialDragThresholdStartPosition;

  /// Current move state (if moving ThresholdAnnotation).
  ThresholdAnnotationElement? _movingThresholdAnnotation;
  Offset? _moveThresholdStartPosition;
  double? _moveThresholdStartValue; // Original value in data coordinates

  /// Current cursor position (for crosshair rendering).
  Offset? _cursorPosition;

  /// Whether tooltips are enabled.
  bool _tooltipsEnabled;

  /// Tracks the tapped marker for tap-triggered tooltips.
  /// Used when triggerMode is tap or both.
  HoveredMarkerInfo? _tappedMarker;

  /// Current tooltip opacity for fade animation (0.0 = hidden, 1.0 = visible)
  double _tooltipOpacity = 0.0;

  /// Timer for delaying tooltip show
  Timer? _tooltipShowTimer;

  /// Timer for delaying tooltip hide
  Timer? _tooltipHideTimer;

  /// Timer for fade animation steps (incremental opacity changes)
  Timer? _tooltipFadeTimer;

  /// Target marker for tooltip display (cached to detect marker changes)
  HoveredMarkerInfo? _tooltipTargetMarker;

  /// Whether to show horizontal scrollbar at bottom of chart.
  bool _showXScrollbar;

  /// Whether to show vertical scrollbar on right side of chart.
  bool _showYScrollbar;

  /// Theme configuration for scrollbars.
  /// If null, defaults to ScrollbarConfig.defaultLight().
  final ScrollbarConfig? _scrollbarTheme;

  /// Interaction configuration for controlling enabled interactions.
  InteractionConfig? _interactionConfig;

  /// Last pan position (for calculating delta during middle-button drag).
  Offset? _lastPanPosition;

  // ==========================================================================
  // Scrollbar Interaction State
  // ==========================================================================

  /// Active scrollbar being dragged (null if not dragging scrollbar).
  Axis? _activeScrollbarAxis;

  /// Initial pointer position when scrollbar drag started (in widget coordinates).
  Offset? _scrollbarDragStartPosition;

  /// Hit test zone where drag started (leftEdge, rightEdge, center, track, etc.).
  HitTestZone? _scrollbarDragStartZone;

  /// Last known drag position for incremental delta calculation.
  /// Using incremental deltas instead of accumulated deltas prevents oversensitivity.
  Offset? _scrollbarLastDragPosition;

  /// Current hover zone for X scrollbar (for visual feedback).
  HitTestZone? _xScrollbarHoverZone;

  /// Current hover zone for Y scrollbar (for visual feedback).
  HitTestZone? _yScrollbarHoverZone;

  // ==========================================================================
  // Scrollbar Auto-Hide State
  // ==========================================================================

  /// Timer for auto-hiding scrollbars after inactivity.
  Timer? _scrollbarAutoHideTimer;

  /// Whether scrollbars are currently visible.
  /// When false, scrollbars don't render and don't respond to interaction.
  /// Defaults to true - will be adjusted in performLayout based on autoHide config.
  bool _scrollbarsVisible = true;

  // ==========================================================================
  // Hit Test Throttling (Performance Optimization)
  // ===========================================================================

  /// Pending hover position for deferred hit testing.
  ///
  /// When mouse moves rapidly, we update crosshair immediately but defer
  /// expensive hit testing until movement slows or stops.
  Offset? _pendingHitTestPosition;

  /// Timer for debouncing hit testing during rapid hover movements.
  ///
  /// Scheduled when mouse moves, cancelled if mouse moves again before firing.
  /// This ensures hit testing only runs when mouse is relatively still.
  Timer? _hitTestDebounceTimer;

  /// Throttle duration for hit testing (milliseconds).
  ///
  /// Hit testing will be deferred until mouse movement pauses for this duration.
  /// Tuned to balance responsiveness with performance (16ms = ~60fps frame budget).
  static const Duration _hitTestThrottleDuration = Duration(milliseconds: 50);

  /// X-axis for the chart (optional).
  chart_axis.Axis? _xAxis;

  /// Y-axis for the chart (optional).
  chart_axis.Axis? _yAxis;

  /// Last axes range values for change detection.
  /// Only update axes when these values actually change to avoid unnecessary tick regeneration.
  double? _lastXMin;
  double? _lastXMax;
  double? _lastYMin;
  double? _lastYMax;

  /// Plot area where chart elements are rendered (excluding axis space).
  Rect _plotArea = Rect.zero;

  /// Horizontal scrollbar rectangle (positioned below chart, if enabled).
  Rect? _xScrollbarRect;

  /// Vertical scrollbar rectangle (positioned to right of chart, if enabled).
  Rect? _yScrollbarRect;

  /// Coordinate transform for Data ↔ Plot conversion.
  ///
  /// Created during layout based on data ranges and plot area dimensions.
  /// Elements are stored in PLOT space, transform is used for viewport changes.
  ChartTransform? _transform;

  /// Original transform state (for reset functionality and constraint calculations).
  ///
  /// Captured during first performLayout() and preserved throughout chart lifetime.
  /// Used to:
  /// - Calculate current zoom level relative to original
  /// - Enforce pan bounds (keep data visible)
  /// - Reset view to original state
  ChartTransform? _originalTransform;

  /// Optional pan constraint bounds (for paused streaming mode).
  ///
  /// When set (non-null), this overrides _originalTransform for pan constraint
  /// calculations in _clampPanDelta(). This allows paused streaming mode to
  /// provide pan constraints based on the FULL accumulated dataset, while
  /// _originalTransform continues to track the sliding window bounds.
  ///
  /// Usage flow:
  /// - Streaming: _panConstraintTransform = null, constraints use _originalTransform (sliding window)
  /// - Pause: Widget calls setPanConstraintBounds(fullDataBounds), user can pan through entire dataset
  /// - Resume: Widget calls clearPanConstraintBounds(), constraints back to sliding window
  ///
  /// This separation is critical because during streaming, setXAxis()/setYAxis()
  /// continuously update _originalTransform to match the sliding window. If we used
  /// _originalTransform for full dataset constraints, they would be overwritten.
  ChartTransform? _panConstraintTransform;

  // ==========================================================================
  // Layer Separation & Picture Caching (Sprint 1)
  // ==========================================================================

  /// Cached rendering of series layer as a Picture.
  ///
  /// This cache stores the rendered output of all series elements as a
  /// GPU-accelerated Picture. The cache is invalidated when:
  /// - Data changes (series added/removed/updated)
  /// - Transform changes (pan/zoom operations complete)
  /// - Theme changes (visual appearance updated)
  ///
  /// The cache is NOT invalidated for:
  /// - Crosshair hover events
  /// - Box selection drag
  /// - Annotation drag
  ///
  /// Memory footprint: ~170KB for typical chart (5 series, 1000 points each)
  ui.Picture? _cachedSeriesPicture;

  /// Flag indicating if the series cache needs regeneration.
  ///
  /// Set to true when cache-invalidating events occur:
  /// - setElements() called with new data
  /// - setTransform() called with different transform
  /// - setTheme() called with new theme
  ///
  /// Set to false after cache successfully regenerated in _getSeriesPicture()
  bool _seriesCacheDirty = true;

  /// Transform state when cache was last generated.
  ///
  /// Used to detect if transform has changed since cache generation,
  /// which would require cache invalidation and regeneration.
  ChartTransform? _cachedTransform;

  /// Hash of series data when cache was last generated.
  ///
  /// Used to detect if series data has changed since cache generation.
  /// Computed from series count, element count, and data ranges.
  /// If hash changes, cache must be regenerated.
  int _cachedSeriesHash = 0;

  // ==========================================================================
  // Crosshair Label Caching (Sprint 3 Optimization)
  // ==========================================================================

  /// Cached TextPainter for X coordinate label.
  ///
  /// Reused across frames to avoid expensive TextPainter.layout() calls.
  /// Only re-layout when label text actually changes.
  // TODO: Implement crosshair label caching
  // TextPainter? _cachedXLabelPainter;

  /// Cached TextPainter for Y coordinate label.
  ///
  /// Reused across frames to avoid expensive TextPainter.layout() calls.
  /// Only re-layout when label text actually changes.
  // TODO: Implement crosshair label caching
  // TextPainter? _cachedYLabelPainter;

  /// Last X label text rendered (for change detection).
  // TODO: Implement crosshair label caching
  // final String _lastXLabelText = '';

  /// Last Y label text rendered (for change detection).
  // TODO: Implement crosshair label caching
  // final String _lastYLabelText = '';

  // ==========================================================================
  // Zoom/Pan Constraints
  // ==========================================================================

  /// Minimum zoom level (relative to original data range).
  /// 1.0 = cannot zoom out beyond original view (no zoom out allowed).
  static const double minZoomLevel = 1.0;

  /// Maximum zoom level (relative to original data range).
  /// 10.0 = can zoom in to show 1/10th of original data range.
  static const double maxZoomLevel = 10.0;

  /// Maximum whitespace allowed beyond data boundaries when panning.
  /// 0.1 = can pan until original data edge is 10% into viewport
  /// (leaving maximum 90% of data visible, minimum 10% whitespace).
  /// This is viewport-based, so it's independent of zoom level.
  static const double maxWhitespaceFraction = 0.1;

  /// Public getter for plot width.
  double get plotWidth => _plotArea.width;

  /// Public getter for plot height.
  double get plotHeight => _plotArea.height;

  /// Public getter for current coordinate transform.
  /// Returns null if chart hasn't been laid out yet.
  ChartTransform? get transform => _transform;

  // ==========================================================================
  // Lifecycle
  // ==========================================================================

  /// Dispose of resources when render object is removed from tree.
  ///
  /// Properly disposes the cached Picture to free GPU memory.
  /// Critical to prevent memory leaks in long-running applications.
  @override
  void dispose() {
    _cachedSeriesPicture?.dispose();
    _cachedSeriesPicture = null;
    _hitTestDebounceTimer?.cancel();
    _hitTestDebounceTimer = null;
    _scrollbarAutoHideTimer?.cancel();
    // Cancel tooltip animation timers to prevent memory leaks
    _cancelTooltipTimers();
    super.dispose();
  }

  /// Updates the list of chart elements.
  ///
  /// Rebuilds the spatial index with new elements.
  /// Invalidates series cache since data has changed.
  void updateElements(List<ChartElement> elements) {
    if (elements == _elements) return;

    _elements = elements;
    _seriesCacheDirty = true; // Invalidate cache - data changed
    _rebuildSpatialIndex();
    markNeedsPaint();
  }

  /// Sets the X-axis for the chart.
  ///
  /// Triggers layout and paint when axis is changed.
  /// If transform exists (zoomed/panned state), syncs new axis with current viewport.
  void setXAxis(chart_axis.Axis? axis) {
    if (_xAxis == axis) {
      // [DEBUG OUTPUT REMOVED] Same axis reference - fires frequently during streaming
      return;
    }

    // [DEBUG OUTPUT REMOVED] X-axis updates - fire frequently during streaming
    _xAxis = axis;

    // Update both transforms to show the new data range (for streaming/dynamic data)
    // CRITICAL: Update _originalTransform too, so pan constraints are calculated from correct bounds
    if (_transform != null && axis != null) {
      _transform = _transform!.copyWith(
        dataXMin: axis.dataMin,
        dataXMax: axis.dataMax,
      );

      // DO NOT update _originalTransform here - it must stay frozen at initial data range
      // for scrollbar handle sizing to work correctly. Updating it causes the handle
      // to always show full size because dataSpan == viewportSpan after update.

      // Invalidate series cache - viewport changed, need to regenerate Picture
      _seriesCacheDirty = true;

      // [DEBUG OUTPUT REMOVED] X-axis viewport update - fires frequently during streaming
    }

    markNeedsLayout();
  }

  /// Sets the Y-axis for the chart.
  ///
  /// Triggers layout and paint when axis is changed.
  /// If transform exists (zoomed/panned state), syncs new axis with current viewport.
  void setYAxis(chart_axis.Axis? axis) {
    if (_yAxis == axis) {
      // [DEBUG OUTPUT REMOVED] Same axis reference - fires frequently during streaming
      return;
    }

    // [DEBUG OUTPUT REMOVED] Y-axis updates - fire frequently during streaming
    _yAxis = axis;

    // Update both transforms to show the new data range (for streaming/dynamic data)
    // CRITICAL: Update _originalTransform too, so pan constraints are calculated from correct bounds
    if (_transform != null && axis != null) {
      _transform = _transform!.copyWith(
        dataYMin: axis.dataMin,
        dataYMax: axis.dataMax,
      );

      // DO NOT update _originalTransform here - it must stay frozen at initial data range
      // for scrollbar handle sizing to work correctly. Updating it causes the handle
      // to always show full size because dataSpan == viewportSpan after update.

      // Invalidate series cache - viewport changed, need to regenerate Picture
      _seriesCacheDirty = true;

      // [DEBUG OUTPUT REMOVED] Y-axis viewport update - fires frequently during streaming
    }

    markNeedsLayout();
  }

  /// Sets the theme for the chart.
  ///
  /// Updates colors for background, grid, axes, etc.
  /// Invalidates series cache since visual appearance changed.
  void setTheme(ChartTheme? theme) {
    if (_theme == theme) return;
    _theme = theme;
    _seriesCacheDirty = true; // Invalidate cache - theme changed
    markNeedsPaint();
  }

  /// Updates tooltip visibility.
  void setTooltipsEnabled(bool enabled) {
    if (_tooltipsEnabled == enabled) return;
    _tooltipsEnabled = enabled;
    markNeedsPaint();
  }

  /// Updates X scrollbar visibility.
  void setShowXScrollbar(bool show) {
    if (_showXScrollbar == show) return;
    _showXScrollbar = show;
    markNeedsPaint();
  }

  /// Updates Y scrollbar visibility.
  void setShowYScrollbar(bool show) {
    if (_showYScrollbar == show) return;
    _showYScrollbar = show;
    markNeedsPaint();
  }

  /// Updates interaction configuration.
  void setInteractionConfig(InteractionConfig? config) {
    if (_interactionConfig == config) return;
    _interactionConfig = config;
    markNeedsPaint();
  }

  /// Sets pan constraint bounds for paused streaming mode.
  ///
  /// When called, creates a separate transform from the provided data bounds
  /// that will be used by _clampPanDelta() for pan constraint calculations.
  /// This allows the widget to provide full dataset bounds while paused,
  /// enabling exploration of all accumulated data, while _originalTransform
  /// continues to track the sliding window bounds.
  ///
  /// Typical usage:
  /// ```dart
  /// // In widget's _pauseStreaming():
  /// renderBox.setPanConstraintBounds(
  ///   _cachedDataXMin, _cachedDataXMax,
  ///   _cachedDataYMin, _cachedDataYMax,
  /// );
  /// ```
  ///
  /// See also: [clearPanConstraintBounds] to restore normal pan constraints.
  void setPanConstraintBounds(double xMin, double xMax, double yMin, double yMax) {
    if (_transform == null) {
      debugPrint('⚠️ Cannot set pan constraints: transform not initialized');
      return;
    }

    // Create a transform with full dataset bounds for pan constraints
    _panConstraintTransform = _transform!.copyWith(
      dataXMin: xMin,
      dataXMax: xMax,
      dataYMin: yMin,
      dataYMax: yMax,
    );
  }

  /// Clears pan constraint bounds, restoring normal sliding window constraints.
  ///
  /// After calling this, _clampPanDelta() will use _originalTransform again
  /// for pan constraint calculations, which tracks the sliding window bounds
  /// during streaming.
  ///
  /// Typical usage:
  /// ```dart
  /// // In widget's _resumeStreaming():
  /// renderBox.clearPanConstraintBounds();
  /// ```
  ///
  /// See also: [setPanConstraintBounds] to set full dataset constraints.
  void clearPanConstraintBounds() {
    _panConstraintTransform = null;
  }

  /// Updates the element generator function.
  ///
  /// Only regenerates elements if the version number has changed.
  /// This prevents unnecessary regeneration when parent widgets rebuild
  /// without actual data/theme changes.
  void setElementGenerator(ElementGenerator? generator, int version) {
    // Only update if version changed (indicates real data/theme change)
    if (_elementGeneratorVersion == version && _elementGenerator != null) {
      return;
    }

    _elementGenerator = generator;
    _elementGeneratorVersion = version;

    // Regenerate elements with new generator if we have a transform
    if (_transform != null && _elementGenerator != null) {
      _rebuildElementsWithTransform();

      // Invalidate cache - element generator changed (new data/theme)
      _seriesCacheDirty = true;
    }
  }

  /// Programmatically zoom the chart.
  ///
  /// **Parameters**:
  /// - `factor`: Zoom factor (> 1.0 = zoom in, < 1.0 = zoom out)
  /// - `plotCenter`: Center point in plot space (if null, uses plot center)
  ///
  /// Only works when using elementGenerator (for element regeneration).
  void zoomChart(double factor, {Offset? plotCenter}) {
    // [DEBUG OUTPUT REMOVED] Zoom chart calls - fire on user interaction

    if (_transform == null || _elementGenerator == null || _originalTransform == null) {
      // [DEBUG OUTPUT REMOVED] Cannot zoom warning - rare error case
      return;
    }

    // Use plot center if not specified
    final center = plotCenter ?? Offset(_plotArea.width / 2, _plotArea.height / 2);

    // Apply zoom tentatively
    final tentativeTransform = _transform!.zoom(factor, center);

    // Clamp zoom to min/max levels
    final clampedTransform = _clampZoomLevel(tentativeTransform);

    // Apply clamped zoom
    _transform = clampedTransform;

    // Update axes to reflect new viewport
    _updateAxesFromTransform();

    // Regenerate elements
    _rebuildElementsWithTransform();

    // Show scrollbars on viewport change from programmatic zoom
    _showScrollbarsAndScheduleHide();

    // Invalidate cache - transform changed
    _seriesCacheDirty = true;

    // [DEBUG OUTPUT REMOVED] Keyboard zoom - fires on user interaction
  }

  /// Programmatically pan the chart.
  ///
  /// **Parameters**:
  /// - `plotDx`, `plotDy`: Pan delta in plot pixels
  ///
  /// Only works when using elementGenerator (for element regeneration).
  void panChart(double plotDx, double plotDy) {
    // [DEBUG OUTPUT REMOVED] Pan chart calls - fire frequently during dragging

    if (_transform == null || _elementGenerator == null || _originalTransform == null) {
      // [DEBUG OUTPUT REMOVED] Cannot pan warning - rare error case
      return;
    }

    // Clamp pan delta BEFORE applying (prevents overshoot/snap-back)
    final (clampedDx, clampedDy) = _clampPanDelta(plotDx, plotDy);

    // Apply constrained pan (won't violate boundaries)
    _transform = _transform!.pan(clampedDx, clampedDy);

    // Update axes to reflect new viewport
    _updateAxesFromTransform();

    // NOTE: Element regeneration is deferred until pan ends for performance
    // See _handlePointerUp for the final regeneration
    // _rebuildElementsWithTransform();  // REMOVED - was causing massive slowdown during pan

    // Show scrollbars on viewport change from programmatic pan
    _showScrollbarsAndScheduleHide();

    // Mark for repaint (will paint existing elements with new transform)
    markNeedsPaint();

    // [DEBUG OUTPUT REMOVED] Pan constrained/applied - fires frequently during dragging
  }

  /// Reset view to original zoom/pan state.
  void resetView() {
    if (_originalTransform == null || _elementGenerator == null) {
      debugPrint('⚠️ Cannot reset: originalTransform or elementGenerator not available');
      return;
    }

    // Restore original data ranges, preserve current plot dimensions
    _transform = _originalTransform!.copyWith(plotWidth: _plotArea.width, plotHeight: _plotArea.height);

    // Update axes to reflect reset viewport
    _updateAxesFromTransform();

    // Regenerate elements
    _rebuildElementsWithTransform();

    // Invalidate cache - transform reset to original
    _seriesCacheDirty = true;

    // [DEBUG OUTPUT REMOVED] View reset - fires on user action
  }

  /// Updates the data bounds for streaming data that extends beyond original range.
  ///
  /// Called when streaming data expands the data range, allowing pan constraints
  /// to permit panning to the new data regions.
  void updateDataBounds(double dataXMin, double dataXMax, double dataYMin, double dataYMax) {
    if (_originalTransform == null) return;

    // DO NOT update _originalTransform here - it must stay frozen at initial data range
    // for scrollbar handle sizing to work correctly. Updating it causes the scrollbar
    // handle to always show full size because dataSpan == viewportSpan after update.
    //
    // TODO: Create separate _fullDataTransform field for pan constraints that can be
    // updated with expanded data range, while keeping _originalTransform frozen.

    // Update current transform so viewport shows the new data
    _transform = ChartTransform(
      plotWidth: _plotArea.width,
      plotHeight: _plotArea.height,
      dataXMin: dataXMin,
      dataXMax: dataXMax,
      dataYMin: dataYMin,
      dataYMax: dataYMax,
      invertY: _transform?.invertY ?? false,
    );

    _updateAxesFromTransform();
    _rebuildElementsWithTransform();
    _seriesCacheDirty = true;
    markNeedsPaint();

    // [DEBUG OUTPUT REMOVED] Data bounds updated - fires during streaming
  }

  /// Updates axes to reflect the current transform's data ranges.
  ///
  /// Called after zoom/pan operations to keep axis labels synchronized
  /// with the visible viewport. The reference implementation does this
  /// dynamically during paint, but our prototype uses a separate Axis
  /// class that needs explicit updates.
  void _updateAxesFromTransform() {
    if (_transform == null) return;

    // Get current transform range values
    final currentXMin = _transform!.dataXMin;
    final currentXMax = _transform!.dataXMax;
    final currentYMin = _transform!.dataYMin;
    final currentYMax = _transform!.dataYMax;

    // Check if X-axis range changed
    final xChanged = _lastXMin != currentXMin || _lastXMax != currentXMax;

    // Check if Y-axis range changed
    final yChanged = _lastYMin != currentYMin || _lastYMax != currentYMax;

    // Only update X-axis if its range actually changed
    if (xChanged && _xAxis != null) {
      _xAxis!.updateDataRange(currentXMin, currentXMax);
      _lastXMin = currentXMin;
      _lastXMax = currentXMax;
      // debugPrint('🔄 X-axis updated: [$currentXMin, $currentXMax]');
    }

    // Only update Y-axis if its range actually changed
    if (yChanged && _yAxis != null) {
      _yAxis!.updateDataRange(currentYMin, currentYMax);
      _lastYMin = currentYMin;
      _lastYMax = currentYMax;
      // debugPrint('🔄 Y-axis updated: [$currentYMin, $currentYMax]');
    }

    // debugPrint if either changed: ' Axes updated: X=[$currentXMin, $currentXMax], Y=[$currentYMin, $currentYMax]'
  }

  // ============================================================================
  // Zoom/Pan Constraint Helpers
  // ============================================================================

  /// Clamps a transform to enforce min/max zoom levels.
  ///
  /// **Constraints**:
  /// - Min zoom: 0.1x (can zoom out to show 10x original data)
  /// - Max zoom: 10.0x (can zoom in to show 1/10th original data)
  ///
  /// **Algorithm**:
  /// 1. Calculate current zoom level: original_range / current_range
  /// 2. If zoom exceeds limits, scale ranges back to limit
  /// 3. Preserve center point of current viewport
  ChartTransform _clampZoomLevel(ChartTransform transform) {
    if (_originalTransform == null) return transform;

    // Use pan constraint transform if set (paused streaming with full dataset),
    // otherwise use original transform (normal mode or active streaming with sliding window)
    // This ensures zoom is calculated relative to the actual data range, not stale initial bounds
    final zoomBaseTransform = _panConstraintTransform ?? _originalTransform!;

    final originalXRange = zoomBaseTransform.dataXMax - zoomBaseTransform.dataXMin;
    final originalYRange = zoomBaseTransform.dataYMax - zoomBaseTransform.dataYMin;

    final currentXRange = transform.dataXMax - transform.dataXMin;
    final currentYRange = transform.dataYMax - transform.dataYMin;

    // Calculate current zoom levels
    final currentZoomX = originalXRange / currentXRange;
    final currentZoomY = originalYRange / currentYRange;

    // Check if clamping needed
    final bool needsClampX = currentZoomX < minZoomLevel || currentZoomX > maxZoomLevel;
    final bool needsClampY = currentZoomY < minZoomLevel || currentZoomY > maxZoomLevel;

    if (!needsClampX && !needsClampY) {
      return transform; // No clamping needed
    }

    // Clamp zoom levels
    final clampedZoomX = currentZoomX.clamp(minZoomLevel, maxZoomLevel);
    final clampedZoomY = currentZoomY.clamp(minZoomLevel, maxZoomLevel);

    // Calculate new ranges from clamped zoom
    final newXRange = originalXRange / clampedZoomX;
    final newYRange = originalYRange / clampedZoomY;

    // Preserve center of current viewport
    final centerX = (transform.dataXMin + transform.dataXMax) / 2;
    final centerY = (transform.dataYMin + transform.dataYMax) / 2;

    // Calculate new bounds centered on viewport center
    final newDataXMin = centerX - newXRange / 2;
    final newDataXMax = centerX + newXRange / 2;
    final newDataYMin = centerY - newYRange / 2;
    final newDataYMax = centerY + newYRange / 2;

    return ChartTransform(
      dataXMin: newDataXMin,
      dataXMax: newDataXMax,
      dataYMin: newDataYMin,
      dataYMax: newDataYMax,
      plotWidth: transform.plotWidth,
      plotHeight: transform.plotHeight,
      invertY: transform.invertY,
    );
  }

  /// Clamps pan delta to enforce viewport bounds (limit whitespace).
  ///
  /// **Correct Viewport Position Constraint Algorithm**:
  ///
  /// **Core Concept**: Track WHERE THE VIEWPORT IS in data space, not where
  /// original boundaries appear in viewport. This makes constraints zoom-independent.
  ///
  /// **Algorithm**:
  /// 1. Convert requested plot delta to data delta
  /// 2. Calculate tentative new viewport position (dataXMin, dataYMin)
  /// 3. Calculate max allowed whitespace in data space (zoom-aware)
  /// 4. Calculate allowed bounds for viewport position
  /// 5. Clamp tentative position to allowed bounds
  /// 6. Calculate actual movement and convert back to plot delta
  ///
  /// **Constraint**: Viewport can show up to 10% whitespace beyond original data.
  /// - Example at 1x zoom (800px plot, 1000 data range):
  ///   maxWhitespace = 800 * 0.1 * (1000/800) = 100 data units
  /// - Example at 2x zoom (800px plot, 500 data range):
  ///   maxWhitespace = 800 * 0.1 * (500/800) = 50 data units
  ///
  /// **Result**: Consistent 10% whitespace at ALL zoom levels. Zoom-independent!
  (double, double) _clampPanDelta(double requestedPlotDx, double requestedPlotDy) {
    if (_originalTransform == null || _transform == null) {
      return (requestedPlotDx, requestedPlotDy);
    }

    // Use pan constraint transform if set (paused streaming mode with full dataset bounds),
    // otherwise use original transform (normal streaming mode with sliding window bounds)
    final constraintTransform = _panConstraintTransform ?? _originalTransform!;

    // 1. Convert requested plot delta to data space
    // CRITICAL: Match the inversion logic in ChartTransform.pan()!
    final dataPerPixelX = _transform!.dataPerPixelX;
    final dataPerPixelY = _transform!.dataPerPixelY;
    final requestedDataDx = requestedPlotDx * dataPerPixelX;
    final requestedDataDy = _transform!.invertY
        ? -requestedPlotDy * dataPerPixelY // Invert Y movement (match pan() logic)
        : requestedPlotDy * dataPerPixelY;

    // 2. Calculate tentative new viewport position in data space
    final tentativeDataXMin = _transform!.dataXMin + requestedDataDx;
    final tentativeDataYMin = _transform!.dataYMin + requestedDataDy;

    // 3. Calculate maximum allowed whitespace in data space (zoom-aware!)
    // At 1x zoom: maxWhitespace = plotWidth * 0.1 * (originalRange / plotWidth) = originalRange * 0.1
    // At 2x zoom: maxWhitespace = plotWidth * 0.1 * (originalRange/2 / plotWidth) = originalRange * 0.05
    // This ensures 10% whitespace in VIEWPORT, which scales correctly with zoom
    final maxWhitespaceDataX = _transform!.plotWidth * maxWhitespaceFraction * dataPerPixelX;
    final maxWhitespaceDataY = _transform!.plotHeight * maxWhitespaceFraction * dataPerPixelY;

    // 4. Calculate allowed bounds for viewport position using constraint transform
    // Viewport left edge (dataXMin) can range from:
    //   - Minimum: constraintDataXMin - maxWhitespace (show whitespace on left)
    //   - Maximum: constraintDataXMax - currentViewportWidth + maxWhitespace (show whitespace on right)
    final minAllowedDataXMin = constraintTransform.dataXMin - maxWhitespaceDataX;
    final maxAllowedDataXMin = constraintTransform.dataXMax - _transform!.dataXRange + maxWhitespaceDataX;

    final minAllowedDataYMin = constraintTransform.dataYMin - maxWhitespaceDataY;
    final maxAllowedDataYMin = constraintTransform.dataYMax - _transform!.dataYRange + maxWhitespaceDataY;

    // 5. Clamp tentative viewport position to allowed bounds
    // Defensive: If min > max (viewport larger than constraint range), allow full movement
    final clampedDataXMin =
        minAllowedDataXMin <= maxAllowedDataXMin ? tentativeDataXMin.clamp(minAllowedDataXMin, maxAllowedDataXMin) : tentativeDataXMin;
    final clampedDataYMin =
        minAllowedDataYMin <= maxAllowedDataYMin ? tentativeDataYMin.clamp(minAllowedDataYMin, maxAllowedDataYMin) : tentativeDataYMin;

    // 6. Calculate actual movement allowed and convert back to plot space
    // CRITICAL: Reverse the inversion applied in step 1!
    final actualDataDx = clampedDataXMin - _transform!.dataXMin;
    final actualDataDy = clampedDataYMin - _transform!.dataYMin;

    final actualPlotDx = actualDataDx / dataPerPixelX;
    final actualPlotDy = _transform!.invertY
        ? -actualDataDy / dataPerPixelY // Reverse Y inversion
        : actualDataDy / dataPerPixelY;

    // [DEBUG OUTPUT REMOVED] Pan constrained - fires frequently during dragging

    return (actualPlotDx, actualPlotDy);
  }

  // ============================================================================
  // Coordinate Space Conversion (Widget ↔ Plot)
  // ============================================================================

  /// Converts widget coordinates to plot coordinates.
  ///
  /// Widget coordinates include axis areas, plot coordinates are relative
  /// to the plot area (0,0 at top-left of plot area).
  Offset widgetToPlot(Offset widgetPosition) {
    return Offset(widgetPosition.dx - _plotArea.left, widgetPosition.dy - _plotArea.top);
  }

  /// Converts plot coordinates to widget coordinates.
  ///
  /// Inverse of widgetToPlot().
  Offset plotToWidget(Offset plotPosition) {
    return Offset(plotPosition.dx + _plotArea.left, plotPosition.dy + _plotArea.top);
  }

  /// Rebuilds the QuadTree spatial index from current elements.
  ///
  /// QuadTree operates in PLOT space (0,0 → plotWidth,plotHeight).
  void _rebuildSpatialIndex() {
    if (!hasSize || _plotArea.isEmpty) {
      return;
    }

    // QuadTree bounds = plot area (in plot space, not widget space)
    _spatialIndex = QuadTree(bounds: Offset.zero & _plotArea.size, maxElementsPerNode: 4, maxDepth: 8);

    // Collect all elements to insert, including generated sub-elements
    final allElements = <ChartElement>[];

    // Insert all chart elements
    for (final element in _elements) {
      allElements.add(element);

      // For annotations, also insert their resize handle elements
      if (element is SimulatedAnnotation) {
        final handleElements = element.createResizeHandleElements();
        allElements.addAll(handleElements);
      }
    }

    // Insert all collected elements into spatial index
    for (final element in allElements) {
      _spatialIndex!.insert(element);
    }

    // Update _elements to include handle elements for painting
    // Keep original order, then add handles at the end
    final handleElements = allElements.skip(_elements.length).toList();
    _elements = [..._elements, ...handleElements];
  }

  /// Rebuilds elements using the element generator with current transform.
  ///
  /// Called after zoom/pan operations to regenerate elements from original
  /// data coordinates using the updated transform.
  void _rebuildElementsWithTransform() {
    final generator = _elementGenerator;
    final transform = _transform;
    if (generator == null || transform == null) {
      // [DEBUG OUTPUT REMOVED] Rebuild elements skipped - fires frequently
      return;
    }

    // Generate new elements using current transform
    _elements = generator(transform);
    // [DEBUG OUTPUT REMOVED] Elements regenerated - fires on data updates

    // Rebuild spatial index with new elements
    _rebuildSpatialIndex();

    // Mark for repaint to show updated elements
    markNeedsPaint();
  }

  // ============================================================================
  // Layout
  // ============================================================================

  @override
  void performLayout() {
    // Chart respects parent constraints
    // Use constrain() to handle both bounded and unbounded constraints
    size = constraints.constrain(
      constraints.isTight
          ? constraints.smallest
          : Size(constraints.hasBoundedWidth ? constraints.maxWidth : 800, constraints.hasBoundedHeight ? constraints.maxHeight : 600),
    );

    // Get scrollbar theme (use default if not provided)
    final scrollbarTheme = _scrollbarTheme ?? ScrollbarConfig.defaultLight;
    final scrollbarPadding = scrollbarTheme.padding;

    // Calculate space needed for scrollbars
    double rightReserved = 0;
    double bottomReserved = 0;

    if (_showYScrollbar) {
      rightReserved = scrollbarTheme.thickness + scrollbarPadding;
    }

    if (_showXScrollbar) {
      bottomReserved = scrollbarTheme.thickness + (scrollbarPadding * 2); // Padding above and below scrollbar
    }

    // Calculate plot area (reserve space for axes AND scrollbars)
    // Default margins if no axes
    double leftMargin = 10;
    final double rightMargin = 10 + rightReserved; // Add scrollbar space
    const double topMargin = 10;
    double bottomMargin = 10 + bottomReserved; // Add scrollbar space

    // Reserve space for Y-axis (left side) - only if axis is visible
    if (_yAxis != null && _yAxis!.config.showAxisLine) {
      leftMargin = 60; // Space for Y-axis labels + axis label + padding
    }

    // Reserve space for X-axis (bottom) - only if axis is visible
    if (_xAxis != null && _xAxis!.config.showAxisLine) {
      bottomMargin = 50 + bottomReserved; // Space for X-axis labels + axis label + padding + scrollbar
    }

    // Calculate plot area (chart canvas excluding axes and scrollbars)
    _plotArea = Rect.fromLTRB(leftMargin, topMargin, size.width - rightMargin, size.height - bottomMargin);

    // Calculate scrollbar rectangles if enabled
    if (_showXScrollbar) {
      // Position horizontal scrollbar BELOW the X-axis label
      // Layout order: plot area → tick labels (~30px) → axis label (~20px) → scrollbar
      // So scrollbar should start after ~50px total
      const xAxisAndLabelHeight = 50.0; // Space for tick labels + axis label
      final scrollbarTop = _plotArea.bottom + xAxisAndLabelHeight + scrollbarPadding;
      _xScrollbarRect = Rect.fromLTWH(
        _plotArea.left,
        scrollbarTop,
        _plotArea.width, // Match plot area width
        scrollbarTheme.thickness,
      );
    } else {
      _xScrollbarRect = null;
    }

    if (_showYScrollbar) {
      // Position vertical scrollbar to the right of the plot area
      final scrollbarLeft = _plotArea.right + scrollbarPadding;
      _yScrollbarRect = Rect.fromLTWH(
        scrollbarLeft,
        _plotArea.top,
        scrollbarTheme.thickness,
        _plotArea.height, // Match plot area height
      );
    } else {
      _yScrollbarRect = null;
    }

    // Update axis pixel ranges to match plot area
    _xAxis?.updatePixelRange(_plotArea.left, _plotArea.right);
    _yAxis?.updatePixelRange(_plotArea.top, _plotArea.bottom);

    // Create/update coordinate transform
    // Transform handles Data ↔ Plot conversion based on axis data ranges
    if (_xAxis != null && _yAxis != null) {
      // Only create initial transform if none exists, otherwise preserve zoom/pan state
      if (_transform == null) {
        // First time: create transform from axis data ranges
        _transform = ChartTransform(
          dataXMin: _xAxis!.dataMin,
          dataXMax: _xAxis!.dataMax,
          dataYMin: _yAxis!.dataMin,
          dataYMax: _yAxis!.dataMax,
          plotWidth: _plotArea.width,
          plotHeight: _plotArea.height,
          invertY: true, // Standard chart convention (Y=0 at bottom)
        );

        // Capture original transform for reset and constraint calculations
        // CRITICAL: Use copyWith() to create a deep copy, not a reference
        // Otherwise both variables point to same object and zoom breaks scrollbar handle sizing
        _originalTransform = _transform!.copyWith();
        // [DEBUG OUTPUT REMOVED] Original transform captured - fires once at init

        // Generate initial elements now that we have a transform
        if (_elementGenerator != null) {
          // [DEBUG OUTPUT REMOVED] Generating initial elements - fires once at init
          _rebuildElementsWithTransform();

          // Invalidate cache - initial element generation
          _seriesCacheDirty = true;
        }
      } else {
        // Subsequent layouts: preserve current data ranges (zoom/pan state),
        // only update plot dimensions if they changed
        if (_transform!.plotWidth != _plotArea.width || _transform!.plotHeight != _plotArea.height) {
          _transform = _transform!.copyWith(plotWidth: _plotArea.width, plotHeight: _plotArea.height);
        }
      }
    }

    // Rebuild spatial index when size changes (for static elements or after transform updates)
    _rebuildSpatialIndex();

    // First render: handle scrollbar visibility based on autoHide config
    final scrollbarConfig = _scrollbarTheme ?? ScrollbarConfig.defaultLight;
    if (_scrollbarAutoHideTimer == null) {
      // Only run once on first layout
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (scrollbarConfig.autoHide) {
          // Auto-hide enabled: show only if viewport is modified, then schedule hide
          _scrollbarsVisible = _isViewportModified();
          if (_scrollbarsVisible) {
            _scheduleScrollbarAutoHide();
          }
        } else {
          // Auto-hide disabled: always show scrollbars
          _scrollbarsVisible = true;
        }
        markNeedsPaint();
      });
    }
  } // ============================================================================
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
  /// **Coordinate Conversion**: Position is in widget space, converted to
  /// plot space before querying QuadTree (which operates in plot space).
  ///
  /// Returns the element with highest priority that passes hitTest(), or null.
  ///
  /// **Conflict Resolution** (per CONFLICT_RESOLUTION_TABLE.md):
  /// - Query QuadTree for candidate elements at position
  /// - Filter to elements that pass precise hitTest()
  /// - Return highest priority element
  ChartElement? hitTestElements(Offset widgetPosition) {
    if (_spatialIndex == null) return null;

    // Convert widget coordinates to plot coordinates
    final plotPosition = widgetToPlot(widgetPosition);

    // Query spatial index for candidate elements (in plot space)
    // Use 18px radius to account for edge zones that extend 8px outside bounds
    // (10px base tolerance + 8px max edge width = 18px total)
    // NOTE: QuadTree now inserts elements into ALL overlapping quadrants,
    // so this smaller radius is sufficient (previously needed 50px due to center-only insertion bug)
    final candidates = _spatialIndex!.query(plotPosition, radius: 18);

    if (candidates.isEmpty) return null;

    // Filter to elements that pass precise hit test
    // Elements use plot coordinates, so pass plot position
    final hits = candidates.where((e) => e.hitTest(plotPosition)).toList();

    if (hits.isEmpty) return null;

    // Return highest priority element
    hits.sort((a, b) => b.priority.compareTo(a.priority));
    return hits.first;
  }

  /// Finds all elements within a rectangular region (for box select).
  ///
  /// **Coordinate Conversion**: Rect is in widget space, converted to plot
  /// space before querying QuadTree.
  ///
  /// Per conflict resolution scenario 14: Box select only captures datapoints.
  List<ChartElement> hitTestRect(Rect widgetRect) {
    if (_spatialIndex == null) return [];

    // Convert widget rect to plot rect
    final plotTopLeft = widgetToPlot(widgetRect.topLeft);
    final plotBottomRight = widgetToPlot(widgetRect.bottomRight);
    final plotRect = Rect.fromPoints(plotTopLeft, plotBottomRight);

    final candidates = _spatialIndex!.queryRect(plotRect);

    // Filter to datapoints only (per conflict resolution)
    // and elements whose center is inside rect (in plot space)
    return candidates.where((e) => e.elementType == ChartElementType.datapoint && plotRect.contains(e.bounds.center)).toList();
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
        newBounds = Rect.fromLTRB(oldBounds.left + delta.dx, oldBounds.top + delta.dy, oldBounds.right, oldBounds.bottom);
        break;
      case ResizeDirection.topRight:
        newBounds = Rect.fromLTRB(oldBounds.left, oldBounds.top + delta.dy, oldBounds.right + delta.dx, oldBounds.bottom);
        break;
      case ResizeDirection.bottomLeft:
        newBounds = Rect.fromLTRB(oldBounds.left + delta.dx, oldBounds.top, oldBounds.right, oldBounds.bottom + delta.dy);
        break;
      case ResizeDirection.bottomRight:
        newBounds = Rect.fromLTRB(oldBounds.left, oldBounds.top, oldBounds.right + delta.dx, oldBounds.bottom + delta.dy);
        break;
      case ResizeDirection.top:
        newBounds = Rect.fromLTRB(oldBounds.left, oldBounds.top + delta.dy, oldBounds.right, oldBounds.bottom);
        break;
      case ResizeDirection.right:
        newBounds = Rect.fromLTRB(oldBounds.left, oldBounds.top, oldBounds.right + delta.dx, oldBounds.bottom);
        break;
      case ResizeDirection.bottom:
        newBounds = Rect.fromLTRB(oldBounds.left, oldBounds.top, oldBounds.right, oldBounds.bottom + delta.dy);
        break;
      case ResizeDirection.left:
        newBounds = Rect.fromLTRB(oldBounds.left + delta.dx, oldBounds.top, oldBounds.right, oldBounds.bottom);
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
  }

  /// Performs move operation for RangeAnnotation during drag.
  ///
  /// Moves the entire annotation region by updating both start and end coordinates
  /// while maintaining the original width/height of the region.
  void _performMove(Offset currentPosition) {
    if (_movingAnnotation == null || _moveStartPosition == null || _moveStartBounds == null) {
      return;
    }

    final delta = currentPosition - _moveStartPosition!;
    final oldBounds = _moveStartBounds!;

    // Calculate new bounds by shifting entire region
    final newBounds = Rect.fromLTRB(
      oldBounds.left + delta.dx,
      oldBounds.top + delta.dy,
      oldBounds.right + delta.dx,
      oldBounds.bottom + delta.dy,
    );

    // Update annotation bounds
    // Note: Spatial index will be rebuilt on pointer up for performance
    _movingAnnotation!.updateBounds(newBounds);
  }

  /// Performs move operation for PointAnnotation during drag.
  ///
  /// Finds the nearest data point in the same series and updates the candidate index
  /// for visual preview. The annotation will snap to this point on pointer up.
  void _performPointAnnotationMove(Offset currentPosition) {
    if (_movingPointAnnotation == null) {
      return;
    }

    final annotation = _movingPointAnnotation!.annotation;

    // Find the series element for this annotation
    final seriesElements = _elements.whereType<SeriesElement>();
    SeriesElement? targetSeries;
    for (final seriesElement in seriesElements) {
      if (seriesElement.series.id == annotation.seriesId) {
        targetSeries = seriesElement;
        break;
      }
    }

    if (targetSeries == null || targetSeries.series.points.isEmpty) {
      return;
    }

    // Convert cursor position to data coordinates
    final transform = targetSeries.transform;
    final plotPos = widgetToPlot(currentPosition);
    final dataPos = transform.plotToData(plotPos.dx, plotPos.dy);

    // Find nearest data point in the series
    final points = targetSeries.series.points;
    double minDistance = double.infinity;
    int nearestIndex = _originalDataPointIndex ?? 0;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      // Calculate Euclidean distance in data space
      final dx = point.x - dataPos.dx;
      final dy = point.y - dataPos.dy;
      final distance = math.sqrt(dx * dx + dy * dy);

      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    // Calculate snap tolerance (5% of viewport range, similar to RangeAnnotation)
    final xRange = transform.dataXMax - transform.dataXMin;
    final yRange = transform.dataYMax - transform.dataYMin;
    final snapTolerance = 0.05 * math.sqrt(xRange * xRange + yRange * yRange);

    // Update candidate index if within snap tolerance
    if (minDistance <= snapTolerance) {
      _candidateDataPointIndex = nearestIndex;
      // Update element's candidate index for visual preview
      _movingPointAnnotation!.updateCandidateIndex(nearestIndex);
    } else {
      // Out of snap tolerance - keep the CURRENT candidate (last valid snap), not the original
      // This allows smooth progression: point A -> point B -> point C (not A -> B -> A)
      // The candidate stays at the last snapped position until we snap to a new one
      _movingPointAnnotation!.updateCandidateIndex(_candidateDataPointIndex);
    }
  }

  /// Performs move operation for TextAnnotation during drag.
  ///
  /// Updates the annotation's position by the drag delta. The position is stored
  /// as screen coordinates, so we just offset by the pointer movement.
  void _performTextAnnotationMove(Offset currentPosition) {
    if (_movingTextAnnotation == null || _moveTextStartPosition == null) {
      return;
    }

    final delta = currentPosition - _moveTextStartPosition!;
    final originalPosition = _movingTextAnnotation!.annotation.position;
    final newPosition = originalPosition + delta;

    // Update element's temporary position for visual preview
    _movingTextAnnotation!.updateTempPosition(newPosition);
  }

  /// Perform ThresholdAnnotation move with axis-constrained drag.
  /// Converts screen delta to data delta and updates temp value for preview.
  void _performThresholdAnnotationMove(Offset currentPosition) {
    if (_movingThresholdAnnotation == null || _moveThresholdStartPosition == null || _moveThresholdStartValue == null) {
      return;
    }

    final element = _movingThresholdAnnotation!;
    final annotation = element.annotation;

    // Convert screen coordinates to data coordinates (axis-constrained)
    double newValue;
    if (annotation.axis == AnnotationAxis.x) {
      // Vertical line - only X movement matters
      // Convert screen X to data X
      final screenX1 = _moveThresholdStartPosition!.dx;
      final screenX2 = currentPosition.dx;
      final dataX1 = _transform!.plotToData(screenX1, 0).dx;
      final dataX2 = _transform!.plotToData(screenX2, 0).dx;
      final dataDelta = dataX2 - dataX1;
      newValue = _moveThresholdStartValue! + dataDelta;
    } else {
      // Horizontal line (y-axis) - only Y movement matters
      // Convert screen Y to data Y
      final screenY1 = _moveThresholdStartPosition!.dy;
      final screenY2 = currentPosition.dy;
      final dataY1 = _transform!.plotToData(0, screenY1).dy;
      final dataY2 = _transform!.plotToData(0, screenY2).dy;
      final dataDelta = dataY2 - dataY1;
      newValue = _moveThresholdStartValue! + dataDelta;
    }

    element.updateTempValue(newValue);
    markNeedsPaint();
  }

  // ============================================================================
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
    // PRIORITY 1: Check if pointer is on scrollbar (highest priority)
    if (_hitTestScrollbars(position, event)) {
      return; // Scrollbar claimed the event
    }

    // Use unified hit testing with priority-based conflict resolution
    final hitElement = hitTestElements(position);

    coordinator.startInteraction(position, element: hitElement);

    // Check if we hit a resize handle (priority 7)
    if (event.buttons == kPrimaryMouseButton && hitElement is ResizeHandleElement) {
      // Clicked on resize handle - extract parent annotation and direction
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
      markNeedsPaint();
      return;
    }

    // Per conflict resolution: Different buttons have different behaviors
    if (event.buttons == kMiddleMouseButton) {
      // Check if pan is enabled
      final enablePan = _interactionConfig?.enablePan ?? true;
      if (!enablePan) {
        return;
      }

      // Middle-click: EXCLUSIVELY pan (per scenario 6)
      // [DEBUG OUTPUT REMOVED] Middle button down - fires on user interaction
      coordinator.claimMode(InteractionMode.panning);
      // Store initial pan position in widget space
      _lastPanPosition = position;
      // Show scrollbars when pan starts (once, not on every move)
      _showScrollbarsAndScheduleHide();
      // [DEBUG OUTPUT REMOVED] Pan mode claimed - fires on user interaction
    } else if (event.buttons == kSecondaryMouseButton) {
      // Right-click: EXCLUSIVELY context menu (per scenario 8)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      debugPrint('⏱️ [$timestamp] 🖱️ RIGHT-CLICK detected in RenderBox at position: $position, element: ${hitElement?.runtimeType}');
      coordinator.claimMode(InteractionMode.contextMenuOpen, element: hitElement);
      debugPrint(
          '⏱️ [${DateTime.now().millisecondsSinceEpoch}] contextMenuOpen mode claimed (${DateTime.now().millisecondsSinceEpoch - timestamp}ms)');
    } else if (event.buttons == kPrimaryMouseButton) {
      // Left-click: Select, or start drag/box-select (determined on move)
      if (hitElement != null) {
        print('🔍 Left-click on element: type=${hitElement.runtimeType}, isSelected=${hitElement.isSelected}');
        if (hitElement is PointAnnotationElement) {
          print('🔍   PointAnnotation: id=${hitElement.annotation.id}, allowDragging=${hitElement.annotation.allowDragging}');
        }

        // Check if we clicked on a RangeAnnotationElement body (not a resize handle)
        // This allows moving the entire annotation region
        if (hitElement is RangeAnnotationElement) {
          // Clicked on RangeAnnotation body - store as potential drag
          // Wait for movement to decide: click (to select) or drag (to move)
          _potentialDragRangeAnnotation = hitElement;
          _potentialDragRangeStartPosition = position;
          _potentialDragRangeStartBounds = hitElement.bounds;
          // Don't claim mode or call callbacks yet - wait for movement or release
        } else if (hitElement is TextAnnotationElement && hitElement.annotation.allowDragging) {
          // Clicked on TextAnnotation - store as potential drag
          // Wait for movement to decide: click (to select) or drag (to reposition)
          _potentialDragTextAnnotation = hitElement;
          _potentialDragTextStartPosition = position;
          // Don't claim mode or call callbacks yet - wait for movement or release
        } else if (hitElement is ThresholdAnnotationElement && hitElement.annotation.allowDragging) {
          // Clicked on ThresholdAnnotation - store as potential drag
          // Wait for movement to decide: click (to select) or drag (to move along axis)
          _potentialDragThresholdAnnotation = hitElement;
          _potentialDragThresholdStartPosition = position;
          // Don't claim mode or call callbacks yet - wait for movement or release
        } else if (hitElement is PointAnnotationElement && hitElement.annotation.allowDragging) {
          // Clicked on PointAnnotation with dragging enabled - store as potential drag
          // We don't know yet if this is a click (to select) or click-and-hold (to drag)
          // Wait for pointer movement to decide
          print('🎯 PointAnnotation POTENTIAL DRAG: id=${hitElement.annotation.id}, allowDragging=${hitElement.annotation.allowDragging}');
          _potentialDragPointAnnotation = hitElement;
          _potentialDragStartPosition = position;
          // Don't claim mode or call callbacks yet - wait for movement or release
        } else {
          // Check if selection is enabled
          final enableSelection = _interactionConfig?.enableSelection ?? true;
          if (!enableSelection) {
            return;
          }

          // Clicked on element - select it (or toggle if Ctrl)
          if (coordinator.isCtrlPressed) {
            coordinator.toggleElementSelection(hitElement);
          } else {
            coordinator.selectElement(hitElement);
          }
          coordinator.claimMode(InteractionMode.selecting, element: hitElement);
          onElementClick?.call(hitElement, event);
        }
      } else {
        // Clicked on empty area - clear selection and prepare for box select
        coordinator.clearSelection();
        onEmptyAreaClick?.call(position, event);
        markNeedsPaint();
      }
    }
  }

  void _handlePointerMove(PointerMoveEvent event, Offset position) {
    // PRIORITY 0: Check for drag threshold on potential TextAnnotation drag
    // This must happen BEFORE checking coordinator.isInteracting because we haven't claimed mode yet
    if (_potentialDragTextAnnotation != null && _potentialDragTextStartPosition != null) {
      final dragDistance = (position - _potentialDragTextStartPosition!).distance;

      if (dragDistance >= _dragThresholdPixels) {
        // Threshold exceeded - convert potential drag to actual drag
        final hitElement = _potentialDragTextAnnotation!;
        _movingTextAnnotation = hitElement;
        _moveTextStartPosition = _potentialDragTextStartPosition;

        coordinator.startInteraction(_potentialDragTextStartPosition!, element: hitElement);
        coordinator.claimMode(InteractionMode.draggingAnnotation, element: hitElement);

        // Clear potential drag state
        _potentialDragTextAnnotation = null;
        _potentialDragTextStartPosition = null;

        // Perform initial move to current position
        _performTextAnnotationMove(position);
        markNeedsPaint();
        return;
      }
      // Still within threshold - keep waiting
      return;
    }

    // PRIORITY 0B: Check for drag threshold on potential ThresholdAnnotation drag
    // This must happen BEFORE checking coordinator.isInteracting because we haven't claimed mode yet
    if (_potentialDragThresholdAnnotation != null && _potentialDragThresholdStartPosition != null) {
      final dragDistance = (position - _potentialDragThresholdStartPosition!).distance;

      if (dragDistance >= _dragThresholdPixels) {
        // Threshold exceeded - convert potential drag to actual drag
        final hitElement = _potentialDragThresholdAnnotation!;
        _movingThresholdAnnotation = hitElement;
        _moveThresholdStartPosition = _potentialDragThresholdStartPosition;
        _moveThresholdStartValue = hitElement.annotation.value; // Store original value

        coordinator.startInteraction(_potentialDragThresholdStartPosition!, element: hitElement);
        coordinator.claimMode(InteractionMode.draggingAnnotation, element: hitElement);

        // Clear potential drag state
        _potentialDragThresholdAnnotation = null;
        _potentialDragThresholdStartPosition = null;

        // Perform initial move to current position
        _performThresholdAnnotationMove(position);
        markNeedsPaint();
        return;
      }
      // Still within threshold - keep waiting
      return;
    }

    // PRIORITY 0A: Check for drag threshold on potential RangeAnnotation drag
    // This must happen BEFORE checking coordinator.isInteracting because we haven't claimed mode yet
    if (_potentialDragRangeAnnotation != null && _potentialDragRangeStartPosition != null && _potentialDragRangeStartBounds != null) {
      final dragDistance = (position - _potentialDragRangeStartPosition!).distance;

      if (dragDistance >= _dragThresholdPixels) {
        // Threshold exceeded - convert potential drag to actual drag
        final hitElement = _potentialDragRangeAnnotation!;
        _movingAnnotation = hitElement;
        _moveStartPosition = _potentialDragRangeStartPosition;
        _moveStartBounds = _potentialDragRangeStartBounds;

        coordinator.startInteraction(_potentialDragRangeStartPosition!, element: hitElement);
        coordinator.claimMode(InteractionMode.draggingAnnotation, element: hitElement);

        // Clear potential drag state
        _potentialDragRangeAnnotation = null;
        _potentialDragRangeStartPosition = null;
        _potentialDragRangeStartBounds = null;

        // Perform initial move to current position
        _performMove(position);
        markNeedsPaint();
        return;
      }
      // Still within threshold - keep waiting
      return;
    }

    // PRIORITY 0B: Check for drag threshold on potential PointAnnotation drag
    // This must happen BEFORE checking coordinator.isInteracting because we haven't claimed mode yet
    if (_potentialDragPointAnnotation != null && _potentialDragStartPosition != null) {
      final dragDistance = (position - _potentialDragStartPosition!).distance;
      if (dragDistance >= _dragThresholdPixels) {
        // Pointer moved beyond threshold - convert to actual drag
        print('🎯 PointAnnotation DRAG START (threshold met): distance=${dragDistance.toStringAsFixed(1)}px');
        final hitElement = _potentialDragPointAnnotation!;

        // Initialize drag state
        _movingPointAnnotation = hitElement;
        _originalDataPointIndex = hitElement.annotation.dataPointIndex;
        _candidateDataPointIndex = hitElement.annotation.dataPointIndex;

        // Check coordinator state BEFORE claiming
        print(
            '🎯 BEFORE claim: currentMode=${coordinator.currentMode}, priority=${coordinator.currentMode.priority}, isModal=${coordinator.currentMode.isModal}');

        // Start interaction and claim drag mode
        coordinator.startInteraction(_potentialDragStartPosition!, element: hitElement);
        final claimSuccess = coordinator.claimMode(InteractionMode.draggingAnnotation, element: hitElement);

        print('🎯 Drag mode claim attempt: success=$claimSuccess, isInteracting=${coordinator.isInteracting}, mode=${coordinator.currentMode}');

        // Clear potential drag state
        _potentialDragPointAnnotation = null;
        _potentialDragStartPosition = null;

        // Now perform the first move to current position
        _performPointAnnotationMove(position);
        markNeedsPaint();
        return;
      }
      // Still within threshold - don't start drag yet, just return
      return;
    }

    // PRIORITY 1: Handle scrollbar drag if active
    if (_activeScrollbarAxis != null && _scrollbarDragStartPosition != null) {
      _handleScrollbarDrag(position);
      return; // Scrollbar is handling the event
    }

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

    // Handle RangeAnnotation move dragging
    if (coordinator.currentMode == InteractionMode.draggingAnnotation &&
        _movingAnnotation != null &&
        _moveStartPosition != null &&
        _moveStartBounds != null) {
      _performMove(position);
      markNeedsPaint();
      return;
    }

    // Handle TextAnnotation move dragging
    if (coordinator.currentMode == InteractionMode.draggingAnnotation && _movingTextAnnotation != null && _moveTextStartPosition != null) {
      _performTextAnnotationMove(position);
      markNeedsPaint();
      return;
    }

    // Handle ThresholdAnnotation move dragging (axis-constrained)
    if (coordinator.currentMode == InteractionMode.draggingAnnotation && _movingThresholdAnnotation != null && _moveThresholdStartPosition != null) {
      _performThresholdAnnotationMove(position);
      markNeedsPaint();
      return;
    }

    // Handle PointAnnotation move dragging
    if (coordinator.currentMode == InteractionMode.draggingAnnotation && _movingPointAnnotation != null) {
      _performPointAnnotationMove(position);
      markNeedsPaint();
      return;
    }

    // Middle-button drag = pan (per conflict resolution scenario 6)
    if (event.buttons == kMiddleMouseButton && coordinator.currentMode == InteractionMode.panning) {
      // debugPrint(
      //   ' Middle button MOVE: buttons=${event.buttons}, mode=${coordinator.currentMode}, lastPos=$_lastPanPosition, transform=${_transform != null}',
      // );
      if (_lastPanPosition != null && _transform != null && _originalTransform != null) {
        // Calculate delta in widget space (for debugging if needed)
        // final widgetDelta = position - _lastPanPosition!;

        // Convert widget delta to plot space (widget space -> plot space is just offset removal)
        final plotDelta = widgetToPlot(position) - widgetToPlot(_lastPanPosition!);

        // debugPrint(' BEFORE CLAMP: position=$position, lastPos=$_lastPanPosition, plotDelta=$plotDelta');

        // Clamp pan delta BEFORE applying (prevents overshoot/snap-back)
        final (clampedDx, clampedDy) = _clampPanDelta(-plotDelta.dx, -plotDelta.dy);

        // Apply constrained pan (won't violate boundaries)
        _transform = _transform!.pan(clampedDx, clampedDy);

        // Update axes to match new transform
        _updateAxesFromTransform();

        // DO NOT regenerate elements during pan - just update transform
        // Elements will use the updated _transform during paint() for coordinate conversion
        // Regeneration happens in _handlePointerUp when pan ends

        // Update last position for next move event
        _lastPanPosition = position;

        // Repaint with updated transform (elements use _transform during paint)
        // Note: Scrollbars already shown in _handlePointerDown, no need to reset timer on every move
        markNeedsPaint();

        // if (clampedDx != -plotDelta.dx || clampedDy != -plotDelta.dy) {
        //   debugPrint(' Pan constrained: requested=${Offset(-plotDelta.dx, -plotDelta.dy)} to allowed=${Offset(clampedDx, clampedDy)}');
        // } else {
        //   debugPrint(' Middle-button pan: widgetDelta=$widgetDelta, plotDelta=$plotDelta');
        // }
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

      // Update range annotation creation rectangle if in rangeAnnotationCreation mode (Option 4)
      if (coordinator.currentMode == InteractionMode.rangeAnnotationCreation) {
        debugPrint('🎯 Range creation drag: updating box selection rectangle');
        coordinator.updateBoxSelection(startPos, position);
        markNeedsPaint(); // Trigger rubber-band rendering
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
    // Clear scrollbar drag state if active
    if (_activeScrollbarAxis != null) {
      _activeScrollbarAxis = null;
      _scrollbarDragStartPosition = null;
      _scrollbarDragStartZone = null;

      // Schedule auto-hide after drag ends (start inactivity timer)
      _scheduleScrollbarAutoHide();

      // Release scrollbar mode and end interaction
      coordinator.endInteraction();
      coordinator.releaseMode();
      markNeedsPaint(); // Redraw with updated hover state
      return;
    }

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

    // Complete range annotation creation if active (Option 4 workflow)
    if (coordinator.currentMode == InteractionMode.rangeAnnotationCreation) {
      final boxRect = coordinator.boxSelectionRect;
      if (boxRect != null && onRangeCreationComplete != null) {
        debugPrint('🎯 Range creation drag complete, converting to data coords...');

        // Get transform from first series to convert plot coords to data coords
        if (_elements.whereType<SeriesElement>().isNotEmpty) {
          final seriesElement = _elements.whereType<SeriesElement>().first;
          final transform = seriesElement.transform;

          // Convert plot coordinates to data coordinates
          final topLeft = transform.plotToData(boxRect.left, boxRect.top);
          final bottomRight = transform.plotToData(boxRect.right, boxRect.bottom);

          // Calculate data bounds (note: Y axis is inverted in plot space)
          final startX = topLeft.dx < bottomRight.dx ? topLeft.dx : bottomRight.dx;
          final endX = topLeft.dx > bottomRight.dx ? topLeft.dx : bottomRight.dx;
          final startY = topLeft.dy < bottomRight.dy ? topLeft.dy : bottomRight.dy;
          final endY = topLeft.dy > bottomRight.dy ? topLeft.dy : bottomRight.dy;

          debugPrint('   Plot rect: $boxRect');
          debugPrint('   Data bounds: X[$startX, $endX], Y[$startY, $endY]');

          // Release mode BEFORE calling callback (callback may show dialog)
          coordinator.endInteraction();
          coordinator.releaseMode();

          // Notify widget to open dialog with pre-filled coordinates
          onRangeCreationComplete!(startX, endX, startY, endY);
          markNeedsPaint();
          return;
        } else {
          debugPrint('❌ No series elements found, cannot convert to data coords');
        }
      } else if (boxRect == null) {
        debugPrint('❌ Range creation cancelled (no drag or too small)');
      }

      // Release mode even if cancelled
      coordinator.endInteraction();
      coordinator.releaseMode();
      markNeedsPaint();
      return;
    }

    // Clear resize state
    if (_resizingAnnotation != null) {
      // CRITICAL: Read temp bounds BEFORE clearing them!
      // clearTempBounds() will null out _tempResizeBounds, causing bounds getter
      // to fall back to original annotation data instead of the resized values.
      final resizedBounds = _resizingAnnotation!.bounds; // Get resized bounds while temp bounds still exist

      _resizingAnnotation!.clearTempBounds(); // Now safe to clear temporary resize bounds

      // CRITICAL: Store references BEFORE clearing state
      // We need to clear _resizingAnnotation BEFORE the callback to prevent old
      // element references from being accessed during the rebuild cycle triggered
      // by notifyListeners() in the callback.
      // BUT we need to capture the values we need FIRST!
      final resizedAnnotation = _resizingAnnotation!.annotation;
      final resizeDirection = _activeResizeDirection; // Capture before clearing

      // Clear the resizing state NOW, before emitting callback
      // This ensures that when notifyListeners() triggers rebuilds, the old
      // element reference is no longer accessible
      _resizingAnnotation = null;
      _activeResizeDirection = null;
      _resizeStartBounds = null;

      // Emit annotation changed callback with updated bounds
      // Convert pixel bounds back to data coordinates for the annotation
      if (onAnnotationChanged != null) {
        // Get transform from first series (all series share same transform)
        if (_elements.whereType<SeriesElement>().isNotEmpty) {
          final seriesElement = _elements.whereType<SeriesElement>().first;
          final transform = seriesElement.transform;

          // Convert pixel bounds back to data coordinates
          // plotToData returns Offset(dataX, dataY)
          final leftData = transform.plotToData(resizedBounds.left, resizedBounds.top);
          final rightData = transform.plotToData(resizedBounds.right, resizedBounds.bottom);

          var newStartX = leftData.dx;
          var newEndX = rightData.dx;
          // Y axis: Only set Y coordinates if they were originally defined
          // If original annotation had null Y values (full height), keep them null
          double? newStartY;
          double? newEndY;

          if (resizedAnnotation.startY != null && resizedAnnotation.endY != null) {
            // Y axis is inverted: top pixel (smaller value) = higher Y data
            // bottom pixel (larger value) = lower Y data
            // So we need to swap them to maintain startY < endY
            newStartY = rightData.dy; // bottom pixel → lower Y data (startY)
            newEndY = leftData.dy; // top pixel → higher Y data (endY)
          }

          // Apply snapping if enabled
          if (resizedAnnotation.snapToValue) {
            // Calculate tolerance distances in data units (percentage of visible range)
            final xTolerance = (transform.dataXMax - transform.dataXMin) * resizedAnnotation.snapTolerance;
            final yTolerance = (transform.dataYMax - transform.dataYMin) * resizedAnnotation.snapTolerance;

            // Determine which edge was resized based on resize direction
            final needsSnapStartX = resizeDirection == ResizeDirection.left ||
                resizeDirection == ResizeDirection.topLeft ||
                resizeDirection == ResizeDirection.bottomLeft;
            final needsSnapEndX = resizeDirection == ResizeDirection.right ||
                resizeDirection == ResizeDirection.topRight ||
                resizeDirection == ResizeDirection.bottomRight;
            final needsSnapStartY =
                resizeDirection == ResizeDirection.top || resizeDirection == ResizeDirection.topLeft || resizeDirection == ResizeDirection.topRight;
            final needsSnapEndY = resizeDirection == ResizeDirection.bottom ||
                resizeDirection == ResizeDirection.bottomLeft ||
                resizeDirection == ResizeDirection.bottomRight;

            // Snap X coordinates if needed
            if (needsSnapStartX) {
              final snapped = _findNearestDataValue(newStartX, axis: 'x', tolerance: xTolerance);
              if (snapped != null) {
                newStartX = snapped;
              }
            }
            if (needsSnapEndX) {
              final snapped = _findNearestDataValue(newEndX, axis: 'x', tolerance: xTolerance);
              if (snapped != null) {
                newEndX = snapped;
              }
            }

            // Snap Y coordinates if needed (only if they're defined)
            if (needsSnapStartY && newStartY != null) {
              final snapped = _findNearestDataValue(newStartY, axis: 'y', tolerance: yTolerance);
              if (snapped != null) {
                newStartY = snapped;
              }
            }
            if (needsSnapEndY && newEndY != null) {
              final snapped = _findNearestDataValue(newEndY, axis: 'y', tolerance: yTolerance);
              if (snapped != null) {
                newEndY = snapped;
              }
            }
          }

          // Create updated annotation with new bounds
          final updatedAnnotation = resizedAnnotation.copyWith(
            startX: newStartX,
            endX: newEndX,
            startY: newStartY,
            endY: newEndY,
          );

          // Emit callback
          onAnnotationChanged!(resizedAnnotation.id, updatedAnnotation);
        }
      }
      // Note: _resizingAnnotation, _activeResizeDirection, and _resizeStartBounds
      // were already cleared above before the callback was emitted
    }

    // Clear move state
    if (_movingAnnotation != null) {
      // CRITICAL: Read temp bounds BEFORE clearing them!
      final movedBounds = _movingAnnotation!.bounds; // Get moved bounds while temp bounds still exist

      _movingAnnotation!.clearTempBounds(); // Now safe to clear temporary bounds

      // CRITICAL: Store references BEFORE clearing state
      final movedAnnotation = _movingAnnotation!.annotation;

      // Clear the moving state NOW, before emitting callback
      _movingAnnotation = null;
      _moveStartPosition = null;
      _moveStartBounds = null;

      // Emit annotation changed callback with updated bounds
      // Convert pixel bounds back to data coordinates for the annotation
      if (onAnnotationChanged != null) {
        // Get transform from first series (all series share same transform)
        if (_elements.whereType<SeriesElement>().isNotEmpty) {
          final seriesElement = _elements.whereType<SeriesElement>().first;
          final transform = seriesElement.transform;

          // Convert pixel bounds back to data coordinates
          // plotToData returns Offset(dataX, dataY)
          final leftData = transform.plotToData(movedBounds.left, movedBounds.top);
          final rightData = transform.plotToData(movedBounds.right, movedBounds.bottom);

          var newStartX = leftData.dx;
          var newEndX = rightData.dx;
          // Y axis: Only set Y coordinates if they were originally defined
          // If original annotation had null Y values (full height), keep them null
          double? newStartY;
          double? newEndY;

          if (movedAnnotation.startY != null && movedAnnotation.endY != null) {
            // Y axis is inverted: top pixel (smaller value) = higher Y data
            // bottom pixel (larger value) = lower Y data
            // So we need to swap them to maintain startY < endY
            newStartY = rightData.dy; // bottom pixel → lower Y data (startY)
            newEndY = leftData.dy; // top pixel → higher Y data (endY)
          }

          // Apply snapping if enabled
          if (movedAnnotation.snapToValue) {
            // Calculate tolerance distances in data units (percentage of visible range)
            final xTolerance = (transform.dataXMax - transform.dataXMin) * movedAnnotation.snapTolerance;
            final yTolerance = (transform.dataYMax - transform.dataYMin) * movedAnnotation.snapTolerance;

            // For move operations, snap both edges
            final snappedStartX = _findNearestDataValue(newStartX, axis: 'x', tolerance: xTolerance);
            if (snappedStartX != null) {
              // Maintain width by shifting both edges
              final width = newEndX - newStartX;
              newStartX = snappedStartX;
              newEndX = newStartX + width;
            }

            // Snap Y coordinates if needed (only if they're defined)
            if (newStartY != null && newEndY != null) {
              final snappedStartY = _findNearestDataValue(newStartY, axis: 'y', tolerance: yTolerance);
              if (snappedStartY != null) {
                // Maintain height by shifting both edges
                final height = newEndY - newStartY;
                newStartY = snappedStartY;
                newEndY = newStartY + height;
              }
            }
          }

          // Create updated annotation with new bounds
          final updatedAnnotation = movedAnnotation.copyWith(
            startX: newStartX,
            endX: newEndX,
            startY: newStartY,
            endY: newEndY,
          );

          // Emit callback
          onAnnotationChanged!(movedAnnotation.id, updatedAnnotation);
        }
      }
      // Note: _movingAnnotation, _moveStartPosition, and _moveStartBounds
      // were already cleared above before the callback was emitted
    }

    // Handle potential TextAnnotation drag that never exceeded threshold (treat as selection click)
    if (_potentialDragTextAnnotation != null) {
      final hitElement = _potentialDragTextAnnotation!;

      // This was a quick click without dragging - toggle selection
      if (coordinator.isCtrlPressed) {
        coordinator.toggleElementSelection(hitElement);
      } else {
        coordinator.selectElement(hitElement);
      }

      // Emit click callback
      onElementClick?.call(hitElement, event);

      // Clear potential drag state
      _potentialDragTextAnnotation = null;
      _potentialDragTextStartPosition = null;

      markNeedsPaint();
    }

    // Handle potential ThresholdAnnotation drag that never exceeded threshold (treat as selection click)
    if (_potentialDragThresholdAnnotation != null) {
      final hitElement = _potentialDragThresholdAnnotation!;

      // This was a quick click without dragging - toggle selection
      if (coordinator.isCtrlPressed) {
        coordinator.toggleElementSelection(hitElement);
      } else {
        coordinator.selectElement(hitElement);
      }

      // Emit click callback
      onElementClick?.call(hitElement, event);

      // Clear potential drag state
      _potentialDragThresholdAnnotation = null;
      _potentialDragThresholdStartPosition = null;

      markNeedsPaint();
    }

    // Handle potential RangeAnnotation drag that never exceeded threshold (treat as selection click)
    if (_potentialDragRangeAnnotation != null) {
      final hitElement = _potentialDragRangeAnnotation!;

      // This was a quick click without dragging - toggle selection
      if (coordinator.isCtrlPressed) {
        coordinator.toggleElementSelection(hitElement);
      } else {
        coordinator.selectElement(hitElement);
      }

      // Emit click callback
      onElementClick?.call(hitElement, event);

      // Clear potential drag state
      _potentialDragRangeAnnotation = null;
      _potentialDragRangeStartPosition = null;
      _potentialDragRangeStartBounds = null;

      markNeedsPaint();
    }

    // Handle potential PointAnnotation drag that never exceeded threshold (treat as selection click)
    if (_potentialDragPointAnnotation != null) {
      print('🎯 PointAnnotation CLICK (no drag): id=${_potentialDragPointAnnotation!.annotation.id}');
      final hitElement = _potentialDragPointAnnotation!;

      // This was a quick click without dragging - toggle selection
      if (coordinator.isCtrlPressed) {
        coordinator.toggleElementSelection(hitElement);
      } else {
        coordinator.selectElement(hitElement);
      }

      // Emit click callback
      onElementClick?.call(hitElement, event);

      // Clear potential drag state
      _potentialDragPointAnnotation = null;
      _potentialDragStartPosition = null;

      markNeedsPaint();
    }

    // Clear PointAnnotation move state
    if (_movingPointAnnotation != null) {
      // CRITICAL: Store references BEFORE clearing state
      final movedAnnotation = _movingPointAnnotation!.annotation;
      final newIndex = _candidateDataPointIndex ?? _originalDataPointIndex ?? movedAnnotation.dataPointIndex;

      // Clear candidate preview
      _movingPointAnnotation!.clearCandidateIndex();

      // Clear the moving state NOW, before emitting callback
      _movingPointAnnotation = null;
      _originalDataPointIndex = null;
      _candidateDataPointIndex = null;

      // Emit annotation changed callback with updated dataPointIndex (only if changed)
      if (onAnnotationChanged != null && newIndex != movedAnnotation.dataPointIndex) {
        // Create updated annotation with new dataPointIndex
        final updatedAnnotation = movedAnnotation.copyWith(
          dataPointIndex: newIndex,
        );

        // Emit callback
        onAnnotationChanged!(movedAnnotation.id, updatedAnnotation);
      }
    }

    // Clear TextAnnotation move state
    if (_movingTextAnnotation != null) {
      // Get the final moved position from the element's temp position
      final originalPosition = _movingTextAnnotation!.annotation.position;
      final tempPosition = _movingTextAnnotation!.tempPosition;
      final newPosition = tempPosition ?? originalPosition; // Use temp if available, else original

      // Clear temp position
      _movingTextAnnotation!.clearTempPosition();

      // CRITICAL: Store references BEFORE clearing state
      final movedAnnotation = _movingTextAnnotation!.annotation;

      // Clear the moving state NOW, before emitting callback
      _movingTextAnnotation = null;
      _moveTextStartPosition = null;

      // Emit annotation changed callback with updated position (only if changed)
      if (onAnnotationChanged != null && newPosition != originalPosition) {
        // Create updated annotation with new position
        final updatedAnnotation = movedAnnotation.copyWith(
          position: newPosition,
        );

        // Emit callback
        onAnnotationChanged!(movedAnnotation.id, updatedAnnotation);
      }
    }

    // Clear ThresholdAnnotation move state
    if (_movingThresholdAnnotation != null) {
      // Get the final moved value from the element's temp value
      final originalValue = _movingThresholdAnnotation!.annotation.value;
      final tempValue = _movingThresholdAnnotation!.tempValue;
      final newValue = tempValue ?? originalValue; // Use temp if available, else original

      // Clear temp value
      _movingThresholdAnnotation!.clearTempValue();

      // CRITICAL: Store references BEFORE clearing state
      final movedAnnotation = _movingThresholdAnnotation!.annotation;

      // Clear the moving state NOW, before emitting callback
      _movingThresholdAnnotation = null;
      _moveThresholdStartPosition = null;
      _moveThresholdStartValue = null;

      // Emit annotation changed callback with updated value (only if changed)
      if (onAnnotationChanged != null && newValue != originalValue) {
        // Create updated annotation with new value
        final updatedAnnotation = movedAnnotation.copyWith(
          value: newValue,
        );

        // Emit callback
        onAnnotationChanged!(movedAnnotation.id, updatedAnnotation);
      }
    }

    // Clear pan state and regenerate elements if we were panning
    // (Elements were not regenerated during drag for performance)
    final wasPanning = coordinator.currentMode == InteractionMode.panning;
    _lastPanPosition = null;
    if (wasPanning && _elementGenerator != null) {
      // Update axes after panning completes
      _updateAxesFromTransform();

      // Regenerate elements with new transform
      // Note: Scrollbars already visible from pointer down, auto-hide timer will handle hiding
      _rebuildElementsWithTransform();

      // Invalidate cache - transform changed from panning
      _seriesCacheDirty = true;

      // [DEBUG OUTPUT REMOVED] Pan ended - fires on user interaction
    }

    // Handle tap on marker for tap-triggered tooltips
    // Check if we're still hovering the same marker we started with (indicates a tap, not a drag)
    final config = _interactionConfig?.tooltip ?? const TooltipConfig();
    if ((config.triggerMode == TooltipTriggerMode.tap || config.triggerMode == TooltipTriggerMode.both) &&
        coordinator.hoveredMarker != null &&
        !coordinator.isPanning &&
        !wasPanning) {
      // Toggle tapped marker: if same marker, clear it (hide tooltip), else set it (show tooltip)
      if (_tappedMarker == coordinator.hoveredMarker) {
        _tappedMarker = null; // Tap same marker again = hide tooltip
      } else {
        _tappedMarker = coordinator.hoveredMarker; // Tap new marker = show tooltip
      }
    }

    // Clear cursor position
    _cursorPosition = null;

    // Release interaction
    coordinator.endInteraction();
    coordinator.releaseMode();
    markNeedsPaint();
  }

  /// Find the nearest data point value on the specified axis within tolerance.
  ///
  /// Searches all series data points and returns the nearest X or Y value
  /// that is within the specified tolerance distance from [targetValue].
  ///
  /// Returns null if no data point is within tolerance.
  double? _findNearestDataValue(double targetValue, {required String axis, required double tolerance}) {
    double? nearestValue;
    double minDistance = double.infinity;

    // Collect all data points from all series
    for (final element in _elements.whereType<SeriesElement>()) {
      for (final point in element.series.points) {
        // Get the value for the specified axis
        final value = axis == 'x' ? point.x : point.y;
        final distance = (value - targetValue).abs();

        // Check if this is the nearest point within tolerance
        if (distance < minDistance && distance <= tolerance) {
          minDistance = distance;
          nearestValue = value;
        }
      }
    }

    return nearestValue;
  }

  void _handlePointerHover(PointerHoverEvent event, Offset position) {
    // Track cursor position for crosshair rendering
    _cursorPosition = position;

    // Always update crosshair immediately for smooth 60fps tracking
    markNeedsPaint();

    // PRIORITY 1: Check scrollbar hover first (before element hit testing)
    // Fixes issue #5: Show appropriate cursors for pan (center) and zoom (edges)
    if (_checkScrollbarHover(position)) {
      return; // Scrollbar handled hover, don't check elements
    }

    // Per conflict resolution scenario 7: Hover is passive
    // Per scenario 12: Hover/tooltips suspended during panning
    if (coordinator.isPanning) {
      coordinator.setHoveredElement(null);
      coordinator.setHoveredMarker(null);
      onCursorChange?.call(SystemMouseCursors.basic);
      return;
    }

    // IMMEDIATE marker highlighting for snappy response (not deferred!)
    // This must be instant - moving from one marker to another should immediately
    // unhighlight the old and highlight the new without any delay
    _updateHoveredMarker(position);

    // Throttle expensive hit testing during rapid mouse movement
    // Strategy: Update crosshair immediately, defer hit testing until movement slows
    _pendingHitTestPosition = position;

    // Cancel previous hit test if still pending (mouse moved again before timer fired)
    _hitTestDebounceTimer?.cancel();

    // Schedule deferred hit testing
    _hitTestDebounceTimer = Timer(_hitTestThrottleDuration, () {
      _performDeferredHitTest();
    });
  }

  /// Performs deferred hit testing after mouse movement slows/stops.
  ///
  /// This method is called by the debounce timer when mouse movement pauses.
  /// It performs the expensive hit testing operations (QuadTree query, precise
  /// hit test, priority sorting) that would cause lag if done on every hover event.
  void _performDeferredHitTest() {
    final position = _pendingHitTestPosition;
    if (position == null) return;

    // Clear pending state
    _pendingHitTestPosition = null;

    // Use unified hit testing with priority-based conflict resolution
    final hitElement = hitTestElements(position);

    // Check if we hit a resize handle (priority 7)
    if (hitElement is ResizeHandleElement) {
      // Hovering over resize handle - show resize cursor
      final cursor = _getCursorForResizeDirection(hitElement.direction);
      onCursorChange?.call(cursor);
      coordinator.setHoveredElement(hitElement.parentAnnotation);
      onElementHover?.call(hitElement.parentAnnotation);
      markNeedsPaint(); // Repaint for hover highlight
      return;
    }

    // For any other element (datapoint=9, series=8, annotation=6, etc.)
    // Priority system ensures the highest-priority element wins
    onCursorChange?.call(SystemMouseCursors.basic);
    coordinator.setHoveredElement(hitElement);
    onElementHover?.call(hitElement);

    markNeedsPaint(); // Repaint for hover highlight
  }

  /// Updates the hovered marker state immediately (no debounce).
  ///
  /// Called on every hover event for instant snappy marker highlighting.
  /// When moving from one marker to another, this immediately clears the old
  /// and highlights the new without any delay.
  void _updateHoveredMarker(Offset widgetPosition) {
    if (_transform == null) {
      coordinator.setHoveredMarker(null);
      return;
    }

    final plotPosition = widgetToPlot(widgetPosition);
    const snapRadius = 20.0; // Match BravenChart's precise snap radius

    HoveredMarkerInfo? nearestMarker;
    double minDistance = snapRadius;

    // Search all series elements for nearest marker
    for (final element in _elements.whereType<SeriesElement>()) {
      for (int i = 0; i < element.series.points.length; i++) {
        final point = element.series.points[i];
        final markerPlotPos = _transform!.dataToPlot(point.x, point.y);
        final distance = (plotPosition - markerPlotPos).distance;

        // Only consider markers WITHIN snap radius
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

    // Update coordinator state immediately
    coordinator.setHoveredMarker(nearestMarker);

    // Invalidate series cache if marker state changed
    _seriesCacheDirty = true;
  }

  /// Finds the nearest marker within a series element.
  ///
  /// Returns marker information if a marker is within the snap radius,
  /// null otherwise.
  ///
  /// **Performance**: Only called after debounced hit testing (50ms throttle),
  /// and only on the series that was hit by priority-based resolution.
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
    // Check if zoom is enabled
    final enableZoom = _interactionConfig?.enableZoom ?? true;
    if (!enableZoom) {
      return;
    }

    // Prevent scroll wheel zoom during scrollbar drag
    if (coordinator.currentMode == InteractionMode.scrollbarDragging) {
      return;
    }

    // Check for Shift modifier to trigger zoom
    if (coordinator.isShiftPressed && _transform != null && _elementGenerator != null && _originalTransform != null) {
      // Claim zooming mode
      coordinator.claimMode(InteractionMode.zooming);

      // Calculate zoom factor from scroll delta
      // Positive scrollDelta.dy = scroll down = zoom out
      // Negative scrollDelta.dy = scroll up = zoom in
      final double scrollAmount = event.scrollDelta.dy;
      const double zoomSensitivity = 0.001; // Adjust for comfortable zoom speed
      final double zoomFactor = 1.0 - (scrollAmount * zoomSensitivity);

      // [DEBUG OUTPUT REMOVED] Zoom factor - fires on scroll events

      // Convert cursor position (widget space) to plot space
      final Offset plotPosition = widgetToPlot(position);

      // Apply zoom centered on cursor position with constraints
      final tentativeTransform = _transform!.zoom(zoomFactor, plotPosition);
      _transform = _clampZoomLevel(tentativeTransform);

      // Update axes to reflect new viewport
      _updateAxesFromTransform();

      // Regenerate elements with new transform
      _rebuildElementsWithTransform();

      // Show scrollbars on viewport change from mouse wheel zoom
      _showScrollbarsAndScheduleHide();

      // Invalidate cache - transform changed from scroll zoom
      _seriesCacheDirty = true;

      // [DEBUG OUTPUT REMOVED] Transform updated - fires on scroll zoom

      // Release zoom mode after short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (coordinator.currentMode == InteractionMode.zooming) {
          coordinator.releaseMode();
        }
      });
    } else {
      // [DEBUG OUTPUT REMOVED] Scroll without zoom - fires on regular scroll

      // Without Shift, just claim mode for compatibility
      coordinator.claimMode(InteractionMode.zooming);

      // Release zoom mode after short delay (zoom is instant, not continuous)
      Future.delayed(const Duration(milliseconds: 100), () {
        if (coordinator.currentMode == InteractionMode.zooming) {
          coordinator.releaseMode();
        }
      });
    }
  }

  // ============================================================================
  // Cache Management (Sprint 1)
  // ============================================================================

  /// Calculate hash of series data for cache validation.
  ///
  /// Computes a hash based on:
  /// - Number of series elements
  /// - Number of points per series
  /// - Data ranges (min/max X and Y values)
  ///
  /// This hash is used to detect if series data has changed since the cache
  /// was generated. If the hash changes, the cache must be regenerated.
  ///
  /// Returns: Hash value as int, 0 if no series elements present
  int _calculateSeriesHash() {
    final seriesElements = _elements.whereType<SeriesElement>().toList();
    if (seriesElements.isEmpty) return 0;

    int hash = seriesElements.length;

    for (final seriesElement in seriesElements) {
      final points = seriesElement.series.points;

      // Hash number of points
      hash = hash ^ points.length;

      // Hash data ranges (first and last points as proxy for data range)
      if (points.isNotEmpty) {
        final first = points.first;
        final last = points.last;
        hash = hash ^ first.x.hashCode;
        hash = hash ^ first.y.hashCode;
        hash = hash ^ last.x.hashCode;
        hash = hash ^ last.y.hashCode;
      }
    }

    return hash;
  }

  /// Check if transform has changed since cache was generated.
  ///
  /// Compares current transform with cached transform to detect changes
  /// that would require cache regeneration (pan/zoom operations).
  ///
  /// Returns: true if transform has changed, false otherwise
  bool _transformChanged() {
    if (_transform == null || _cachedTransform == null) {
      return true; // Consider changed if either is null
    }

    // Compare data ranges (this is what affects rendering)
    return _transform!.dataXMin != _cachedTransform!.dataXMin ||
        _transform!.dataXMax != _cachedTransform!.dataXMax ||
        _transform!.dataYMin != _cachedTransform!.dataYMin ||
        _transform!.dataYMax != _cachedTransform!.dataYMax;
  }

  /// Check if series cache is valid and can be reused.
  ///
  /// Cache is valid if:
  /// 1. Cache exists (_cachedSeriesPicture != null)
  /// 2. Cache is not marked dirty (_seriesCacheDirty == false)
  /// 3. Series data hash hasn't changed
  /// 4. Transform hasn't changed
  ///
  /// Returns: true if cache is valid and can be reused
  bool _isCacheValid() {
    if (_cachedSeriesPicture == null || _seriesCacheDirty) {
      return false;
    }

    // Check if series data changed
    final currentHash = _calculateSeriesHash();
    if (currentHash != _cachedSeriesHash) {
      return false;
    }

    // Check if transform changed
    if (_transformChanged()) {
      return false;
    }

    return true;
  }

  // ============================================================================
  // Painting
  // ============================================================================

  /// Paints all series elements into a PictureRecorder for caching.
  ///
  /// This method isolates series rendering for GPU-accelerated Picture caching.
  /// It paints series elements in priority order within the plot area bounds.
  ///
  /// **Coordinate Space**: Operates in plot space (0,0 → plotWidth, plotHeight).
  /// Elements are already positioned in plot space, so no conversion needed.
  ///
  /// **Purpose**: This is Layer 1 in the two-layer rendering architecture.
  /// Series elements are static (only change on data/transform updates),
  /// so they can be cached and reused across frames. This eliminates
  /// expensive series rendering during hover events.
  ///
  /// **Performance**: At 5 series × 1000 points, this saves ~17ms per frame
  /// during hover, enabling 60fps interaction with large datasets.
  ///
  /// Parameters:
  /// - recorder: PictureRecorder to capture rendering commands
  /// - size: Size of the plot area (for element paint calls)
  void _paintSeriesLayer(ui.PictureRecorder recorder, Size size) {
    final canvas = Canvas(recorder);

    // Clip to plot area bounds to prevent rendering outside cache region
    canvas.clipRect(Offset.zero & size);

    // Paint series elements only (filter out overlays, handles, etc.)
    // Series elements have priority 8, so we filter by type instead
    final seriesElements = _elements.whereType<SeriesElement>().toList()..sort((a, b) => a.priority.compareTo(b.priority));

    // Paint each series with current transform
    for (final series in seriesElements) {
      if (_transform != null) {
        // CRITICAL: Update transform before painting (enables path caching!)
        // This allows SeriesElement to cache paths and only regenerate when transform changes.
        series.updateTransform(_transform!);
      }
      series.paint(canvas, size);
    }
  }

  /// Generates a cached Picture of the series layer.
  ///
  /// This method creates a GPU-accelerated Picture by recording all series
  /// rendering commands into a PictureRecorder, then ending the recording
  /// to produce a reusable Picture.
  ///
  /// **Cache Management**:
  /// - Updates _cachedSeriesHash with current data state
  /// - Updates _cachedTransform with current transform state
  /// - Clears _seriesCacheDirty flag
  /// - Returns new Picture ready for drawing
  ///
  /// **Performance**: Picture recording adds ~1-2ms overhead on first paint,
  /// but saves ~17ms on every subsequent hover frame (17x ROI!).
  ///
  /// **Memory**: Picture consumes ~170KB for typical chart (5 series, 1000 points).
  ///
  /// Returns: Cached Picture of series layer, ready to draw with Canvas.drawPicture()
  ui.Picture _generateSeriesPicture() {
    // Create recorder with plot area bounds
    final recorder = ui.PictureRecorder();

    // Paint series into recorder
    _paintSeriesLayer(recorder, _plotArea.size);

    // End recording to produce Picture
    final picture = recorder.endRecording();

    // Update cache metadata
    _cachedSeriesHash = _calculateSeriesHash();
    _cachedTransform = _transform?.copyWith(); // Deep copy to detect future changes
    _seriesCacheDirty = false;

    return picture;
  }

  /// Paints the overlay layer (crosshair, selection box, preview indicators).
  ///
  /// This is Layer 2 in the two-layer rendering architecture. Overlays are
  /// dynamic (change every frame during hover/drag), so they cannot be cached.
  ///
  /// **Coordinate Space**: Operates in widget space (includes axis areas).
  /// Uses plotToWidget() to convert plot-space element bounds to widget space.
  ///
  /// **Performance**: This layer renders fresh every frame (~1-2ms overhead).
  /// By separating from series layer, we avoid re-rendering series during hover,
  /// achieving 60fps with large datasets.
  ///
  /// Parameters:
  /// - canvas: Canvas to paint overlays (in widget space)
  /// - size: Total widget size (including axis areas)
  void _paintOverlayLayer(Canvas canvas, Size size) {
    // [DEBUG OUTPUT REMOVED] Overlay paint start - was firing at 60fps
    // Paint preview selection indicators (during box drag)
    // Draw with different visual style than actual selection (dashed outline)
    if (coordinator.currentMode == InteractionMode.boxSelecting) {
      final previewElements = coordinator.previewSelectedElements;
      for (final element in previewElements) {
        // Only draw preview for elements that aren't already selected
        if (!element.isSelected && element.elementType == ChartElementType.datapoint) {
          // Convert plot bounds to widget bounds for preview rendering
          final plotBounds = element.bounds;
          final widgetCenter = plotToWidget(plotBounds.center);
          final radius = plotBounds.width / 2;

          // Draw dashed preview ring (different from solid selection ring)
          final previewPaint = Paint()
            ..color = const Color(0x8000AAFF) // Semi-transparent blue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
          canvas.drawCircle(widgetCenter, radius + 3, previewPaint);
        }
      }
    }

    // Paint box selection rectangle if active (in widget space)
    if (coordinator.currentMode == InteractionMode.boxSelecting) {
      final boxRect = coordinator.boxSelectionRect;
      if (boxRect != null) {
        // boxRect is already in widget space, draw it directly
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

    // Paint range annotation creation rectangle if active (Option 4 rubber-band)
    if (coordinator.currentMode == InteractionMode.rangeAnnotationCreation) {
      final boxRect = coordinator.boxSelectionRect;
      if (boxRect != null) {
        // Draw semi-transparent filled rectangle (lighter blue than box select)
        canvas.drawRect(
          boxRect,
          Paint()
            ..color = const ui.Color(0x26448AFF) // Blue with 15% opacity
            ..style = PaintingStyle.fill,
        );

        // Draw solid border (dashed would require path, keeping simple for now)
        final borderPaint = Paint()
          ..color = const ui.Color(0xFF448AFF) // Blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawRect(boxRect, borderPaint);

        // Draw coordinate labels showing data bounds
        if (_transform != null) {
          final topLeft = _transform!.plotToData(boxRect.left, boxRect.top);
          final bottomRight = _transform!.plotToData(boxRect.right, boxRect.bottom);

          // Calculate min/max coordinates
          final xMin = topLeft.dx < bottomRight.dx ? topLeft.dx : bottomRight.dx;
          final xMax = topLeft.dx > bottomRight.dx ? topLeft.dx : bottomRight.dx;
          final yMin = topLeft.dy < bottomRight.dy ? topLeft.dy : bottomRight.dy;
          final yMax = topLeft.dy > bottomRight.dy ? topLeft.dy : bottomRight.dy;

          // Format coordinate text
          final coordText = 'X: [${xMin.toStringAsFixed(2)}, ${xMax.toStringAsFixed(2)}]  '
              'Y: [${yMin.toStringAsFixed(2)}, ${yMax.toStringAsFixed(2)}]';

          // Draw text near bottom-right corner of rectangle
          final textPainter = TextPainter(
            text: TextSpan(
              text: coordText,
              style: const TextStyle(
                color: ui.Color(0xFF000000),
                fontSize: 11,
                backgroundColor: ui.Color(0xE6FFFFFF), // White with 90% opacity
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();

          // Position tooltip below and to the left of bottom-right corner
          var tooltipOffset = boxRect.bottomRight + const Offset(5, 5);

          // Keep tooltip inside widget bounds
          if (tooltipOffset.dx + textPainter.width > size.width) {
            tooltipOffset = Offset(size.width - textPainter.width - 5, tooltipOffset.dy);
          }
          if (tooltipOffset.dy + textPainter.height > size.height) {
            tooltipOffset = Offset(tooltipOffset.dx, boxRect.top - textPainter.height - 5);
          }

          textPainter.paint(canvas, tooltipOffset);
        }
      }
    }

    // Draw crosshair at cursor position (in widget space)
    final cursorPos = _cursorPosition;
    final crosshairEnabled = _interactionConfig?.crosshair.enabled ?? true;
    if (crosshairEnabled && cursorPos != null && _plotArea.contains(cursorPos) && !coordinator.currentMode.isDragging) {
      // Only draw crosshair if cursor is inside plot area AND not dragging
      // Hide crosshair during all drag operations (datapoint, annotation, resize)
      // [DEBUG OUTPUT REMOVED] Crosshair drawing - was firing at 60fps on mouse move
      final crosshairPaint = Paint()
        ..color = const Color(0x80666666) // Semi-transparent gray
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      // Horizontal line across plot area
      canvas.drawLine(Offset(_plotArea.left, cursorPos.dy), Offset(_plotArea.right, cursorPos.dy), crosshairPaint);

      // Vertical line across plot area
      canvas.drawLine(Offset(cursorPos.dx, _plotArea.top), Offset(cursorPos.dx, _plotArea.bottom), crosshairPaint);

      // Draw coordinate labels (showing both screen and data coordinates)
      _drawCrosshairLabels(canvas, size, cursorPos);
    }

    // Draw tooltip for hovered/tapped marker (if any)
    // Show based on tooltip trigger mode configuration with animations
    if (_tooltipsEnabled && !coordinator.isPanning) {
      final config = _interactionConfig?.tooltip ?? const TooltipConfig();
      HoveredMarkerInfo? markerToShow;

      switch (config.triggerMode) {
        case TooltipTriggerMode.hover:
          // Show tooltip only when hovering
          markerToShow = coordinator.hoveredMarker;
          break;
        case TooltipTriggerMode.tap:
          // Show tooltip only for tapped marker
          markerToShow = _tappedMarker;
          break;
        case TooltipTriggerMode.both:
          // Show tooltip for either hover or tap (prefer tapped if both exist)
          markerToShow = _tappedMarker ?? coordinator.hoveredMarker;
          break;
      }

      // Handle show/hide animations based on marker presence
      if (markerToShow != null) {
        // Start show animation if marker changed or newly appeared
        if (_tooltipTargetMarker != markerToShow) {
          _showTooltipWithDelay(markerToShow);
        }

        // Only draw tooltip if it has some opacity (visible or fading)
        if (_tooltipOpacity > 0.001) {
          _drawMarkerTooltip(canvas, size, markerToShow);
        }
      } else {
        // Start hide animation if marker disappeared
        if (_tooltipTargetMarker != null) {
          _hideTooltipWithDelay();
        }

        // Still draw tooltip during fade-out
        if (_tooltipOpacity > 0.001 && _tooltipTargetMarker != null) {
          _drawMarkerTooltip(canvas, size, _tooltipTargetMarker!);
        }
      }
    } else {
      // Tooltips disabled or panning - cancel animations and hide
      if (_tooltipOpacity > 0) {
        _cancelTooltipTimers();
        _tooltipOpacity = 0.0;
      }
    }

    // [DEBUG OUTPUT REMOVED] Overlay paint complete - was firing at 60fps
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    // Paint background using theme color
    final backgroundColor = _theme?.backgroundColor ?? const Color(0xFFFFFFFF);
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);

    // Axes are updated via _updateAxesFromTransform() when transform ACTUALLY changes
    // (during pan, zoom, performLayout, etc.) - NOT on every paint!
    // This avoids unnecessary tick regeneration during crosshair hover.

    // Paint axes (behind all chart elements)
    if (_xAxis != null) {
      AxisRenderer(_xAxis!).paint(canvas, size, _plotArea);
    }
    if (_yAxis != null) {
      AxisRenderer(_yAxis!).paint(canvas, size, _plotArea);
    }

    // ==========================================================================
    // Two-Layer Rendering Architecture (Sprint 2)
    // ==========================================================================
    // Layer 1: Series (cached) - only regenerate on data/transform changes
    // Layer 2: Overlays (dynamic) - render fresh every frame
    //
    // This separation eliminates expensive series rendering during hover events,
    // enabling 60fps interaction with large datasets (5+ series).
    //
    // Performance: 17ms → <5ms hover latency (17x speedup!)
    // ==========================================================================

    // Clip canvas to plot area to prevent elements from rendering over axes
    canvas.save();
    canvas.translate(_plotArea.left, _plotArea.top);
    canvas.clipRect(Offset.zero & _plotArea.size);

    // LAYER 1: Series (cached)
    // Check if we can reuse cached Picture, or need to regenerate
    final cacheValid = _isCacheValid();
    // [DEBUG OUTPUT REMOVED] Cache hit/miss - was firing at 60fps

    if (cacheValid) {
      // Cache hit! Draw cached Picture (fast path ~0.1ms)
      canvas.drawPicture(_cachedSeriesPicture!);
    } else {
      // Cache miss - regenerate Picture from current data/transform
      // [DEBUG OUTPUT REMOVED] Picture regeneration - fires on data updates

      // Dispose old Picture to free GPU memory
      _cachedSeriesPicture?.dispose();

      // Generate new Picture (slow path ~17ms for 5 series)
      _cachedSeriesPicture = _generateSeriesPicture();

      // Draw freshly generated Picture
      canvas.drawPicture(_cachedSeriesPicture!);

      // [DEBUG OUTPUT REMOVED] Picture regenerated - fires on data updates
    }

    // Paint non-series elements (annotations, handles, etc.)
    // These are not cached because they're less expensive and change frequently
    final nonSeriesElements = _elements.where((e) => e is! SeriesElement).toList()..sort((a, b) => a.priority.compareTo(b.priority));

    // [DEBUG OUTPUT REMOVED] Non-series element painting - was firing at 60fps
    for (final element in nonSeriesElements) {
      // [DEBUG OUTPUT REMOVED] Per-element painting - was firing at 60fps

      // Update transform for annotation elements before painting (enables dynamic positioning)
      // CRITICAL FIX: Update transform for ALL annotation types, not just Point and Range
      // This ensures Threshold and Trend annotations update during pan/zoom gestures
      if (_transform != null) {
        if (element is PointAnnotationElement) {
          element.updateTransform(_transform!);
        } else if (element is RangeAnnotationElement) {
          element.updateTransform(_transform!);
        } else if (element is ThresholdAnnotationElement) {
          element.updateTransform(_transform!);
        } else if (element is TrendAnnotationElement) {
          element.updateTransform(_transform!);
        }
      }

      element.paint(canvas, _plotArea.size);
    }

    canvas.restore(); // Restore canvas state (removes clipping and translation from plot area)

    // LAYER 2: Overlays (dynamic, always rendered fresh)
    // Crosshair, selection box, preview indicators - change every frame during hover/drag
    // Use saveLayer to create independent compositing layer for crosshair
    // This allows Flutter to repaint ONLY the crosshair without touching series layer
    final overlayBounds = Offset.zero & size;
    canvas.saveLayer(overlayBounds, Paint());
    _paintOverlayLayer(canvas, size);
    canvas.restore(); // Restore from saveLayer

    // Paint scrollbars if enabled (outside plot area clipping)
    _paintScrollbars(canvas, size);

    canvas.restore(); // Final restore (removes initial offset translation)
  }

  // ==========================================================================
  // Scrollbar Interaction Handlers
  // ==========================================================================

  /// Checks if pointer is hovering over a scrollbar and updates cursor.
  ///
  /// Returns true if hovering over scrollbar (prevents element hit testing).
  /// Fixes issue #5: Show appropriate cursors for pan (center) vs zoom (edges).
  bool _checkScrollbarHover(Offset position) {
    if (_transform == null || _originalTransform == null) return false;

    // When scrollbars are hidden, they don't exist for interaction
    if (!_scrollbarsVisible) return false;

    // Check X scrollbar hover
    if (_showXScrollbar && _xScrollbarRect != null && _xScrollbarRect!.contains(position)) {
      final localX = position.dx - _xScrollbarRect!.left;
      final zone = _getScrollbarZoneAtPosition(Axis.horizontal, localX);
      final cursor = _getCursorForScrollbarZone(zone, Axis.horizontal);
      onCursorChange?.call(cursor);

      // Cancel auto-hide while hovering (user might be about to interact)
      _cancelScrollbarAutoHide();

      // Store hover zone and repaint to show visual feedback
      if (_xScrollbarHoverZone != zone) {
        _xScrollbarHoverZone = zone;
        markNeedsPaint();
      }

      return true;
    }

    // Check Y scrollbar hover
    if (_showYScrollbar && _yScrollbarRect != null && _yScrollbarRect!.contains(position)) {
      final localY = position.dy - _yScrollbarRect!.top;
      final zone = _getScrollbarZoneAtPosition(Axis.vertical, localY);
      final cursor = _getCursorForScrollbarZone(zone, Axis.vertical);
      onCursorChange?.call(cursor);

      // Cancel auto-hide while hovering (user might be about to interact)
      _cancelScrollbarAutoHide();

      // Store hover zone and repaint to show visual feedback
      if (_yScrollbarHoverZone != zone) {
        _yScrollbarHoverZone = zone;
        markNeedsPaint();
      }

      return true;
    }

    // Clear hover zones when not hovering over scrollbars
    if (_xScrollbarHoverZone != null || _yScrollbarHoverZone != null) {
      _xScrollbarHoverZone = null;
      _yScrollbarHoverZone = null;

      // Resume auto-hide timer when mouse leaves scrollbar
      _scheduleScrollbarAutoHide();

      markNeedsPaint();
    }

    return false; // Not hovering over scrollbar
  }

  /// Gets the scrollbar zone at a local position within the scrollbar.
  HitTestZone? _getScrollbarZoneAtPosition(Axis axis, double localPos) {
    if (_transform == null || _originalTransform == null) return null;

    final scrollbarRect = axis == Axis.horizontal ? _xScrollbarRect : _yScrollbarRect;
    if (scrollbarRect == null) return null;

    final trackLength = axis == Axis.horizontal ? scrollbarRect.width : scrollbarRect.height;
    final dataMin = axis == Axis.horizontal ? _originalTransform!.dataXMin : _originalTransform!.dataYMin;
    final dataMax = axis == Axis.horizontal ? _originalTransform!.dataXMax : _originalTransform!.dataYMax;
    final viewportMin = axis == Axis.horizontal ? _transform!.dataXMin : _transform!.dataYMin;
    final viewportMax = axis == Axis.horizontal ? _transform!.dataXMax : _transform!.dataYMax;

    final dataSpan = dataMax - dataMin;
    final viewportSpan = viewportMax - viewportMin;
    final scrollbarTheme = _scrollbarTheme ?? ScrollbarConfig.defaultLight;

    // Calculate handle geometry
    final handleSize = (viewportSpan / dataSpan * trackLength).clamp(scrollbarTheme.minHandleSize, trackLength);

    // Calculate handle position (same logic for both axes - no inversion!)
    // For Y-axis: Chart Y increases upward, but screen Y increases downward
    // The natural mapping works: viewport at bottom (low Y) → handle at top (low screen Y)
    final handlePosition = ((viewportMin - dataMin) / dataSpan * trackLength).clamp(0.0, trackLength - handleSize);

    // Calculate zoom-adjusted edge grip width (must match rendering logic)
    // Both X and Y axes now use LINEAR zoom scaling for consistency
    final zoomFactor = dataSpan / viewportSpan;
    final baseEdgeGripWidth = scrollbarTheme.edgeGripWidth;
    final maxEdgeGripWidth = handleSize * 0.4; // Max 40% of handle size
    final zoomAdjustedEdgeGripWidth = (baseEdgeGripWidth * zoomFactor)
        .clamp(
          math.min(baseEdgeGripWidth, maxEdgeGripWidth), // Ensure min <= max
          maxEdgeGripWidth,
        )
        .toDouble();

    // Use ScrollbarController to determine zone
    final zone = ScrollbarController.getHitTestZone(
      axis == Axis.horizontal ? Offset(localPos, 0) : Offset(0, localPos),
      axis,
      trackLength,
      handlePosition,
      handleSize,
      edgeDetectionThreshold: zoomAdjustedEdgeGripWidth,
    );

    return zone;
  }

  /// Gets the appropriate cursor for a scrollbar zone.
  MouseCursor _getCursorForScrollbarZone(HitTestZone? zone, Axis axis) {
    if (zone == null) return SystemMouseCursors.basic;

    switch (zone) {
      case HitTestZone.track:
        return SystemMouseCursors.click; // Click to jump
      case HitTestZone.center:
        return SystemMouseCursors.grab; // Drag to pan
      case HitTestZone.leftEdge:
      case HitTestZone.rightEdge:
        return SystemMouseCursors.resizeColumn; // Drag to zoom horizontally
      case HitTestZone.topEdge:
      case HitTestZone.bottomEdge:
        return SystemMouseCursors.resizeRow; // Drag to zoom vertically
    }
  }

  /// Hit tests scrollbar regions and handles initial scrollbar interaction.
  ///
  /// Returns true if pointer is on a scrollbar and starts interaction, false otherwise.
  /// When true is returned, the pointer event should not propagate to chart handlers.
  bool _hitTestScrollbars(Offset position, PointerDownEvent event) {
    if (event.buttons != kPrimaryMouseButton) {
      return false; // Only left-click interacts with scrollbars
    }

    // Check X scrollbar (horizontal, bottom of chart)
    if (_showXScrollbar && _xScrollbarRect != null && _xScrollbarRect!.contains(position)) {
      return _startScrollbarInteraction(Axis.horizontal, position);
    }

    // Check Y scrollbar (vertical, right of chart)
    if (_showYScrollbar && _yScrollbarRect != null && _yScrollbarRect!.contains(position)) {
      return _startScrollbarInteraction(Axis.vertical, position);
    }

    return false; // Not on any scrollbar
  }

  /// Starts scrollbar interaction after hit test confirms pointer is on scrollbar.
  ///
  /// Returns true to indicate event was claimed by scrollbar.
  bool _startScrollbarInteraction(Axis axis, Offset position) {
    if (_transform == null || _originalTransform == null) {
      return false; // Transform not ready
    }

    // Check if coordinator allows scrollbar interaction (not blocked by modal modes)
    if (coordinator.isModal) {
      return false; // Modal state blocks scrollbar interaction
    }

    // Get scrollbar rect based on axis
    final scrollbarRect = axis == Axis.horizontal ? _xScrollbarRect : _yScrollbarRect;
    if (scrollbarRect == null) return false;

    // Calculate handle geometry
    final isHorizontal = axis == Axis.horizontal;
    final trackLength = isHorizontal ? scrollbarRect.width : scrollbarRect.height;

    final dataMin = isHorizontal ? _originalTransform!.dataXMin : _originalTransform!.dataYMin;
    final dataMax = isHorizontal ? _originalTransform!.dataXMax : _originalTransform!.dataYMax;
    final viewportMin = isHorizontal ? _transform!.dataXMin : _transform!.dataYMin;
    final viewportMax = isHorizontal ? _transform!.dataXMax : _transform!.dataYMax;

    final dataSpan = dataMax - dataMin;
    final viewportSpan = viewportMax - viewportMin;
    final scrollbarTheme = _scrollbarTheme ?? ScrollbarConfig.defaultLight;

    // Calculate handle size and position using same formulas as _paintScrollbars
    final handleSize = (viewportSpan / dataSpan * trackLength).clamp(scrollbarTheme.minHandleSize, trackLength);

    // Calculate handle position (same formula for both axes - natural mapping works!)
    final handlePosition = ((viewportMin - dataMin) / dataSpan * trackLength).clamp(0.0, trackLength - handleSize);

    // Calculate zoom-adjusted edge grip width (must match rendering logic)
    // Both X and Y axes use LINEAR zoom scaling for consistency
    final zoomFactor = dataSpan / viewportSpan;
    final baseEdgeGripWidth = scrollbarTheme.edgeGripWidth;
    final maxEdgeGripWidth = handleSize * 0.4; // Max 40% of handle size
    final zoomAdjustedEdgeGripWidth = (baseEdgeGripWidth * zoomFactor)
        .clamp(
          math.min(baseEdgeGripWidth, maxEdgeGripWidth), // Ensure min <= max
          maxEdgeGripWidth,
        )
        .toDouble();

    // Convert pointer position to scrollbar-local coordinate
    final localPos = isHorizontal ? (position.dx - scrollbarRect.left) : (position.dy - scrollbarRect.top);

    // Use ScrollbarController to determine which zone was hit (with zoom-adjusted edges)
    final hitZone = ScrollbarController.getHitTestZone(
      isHorizontal ? Offset(localPos, 0) : Offset(0, localPos), // Correct offset based on axis
      axis,
      trackLength,
      handlePosition,
      handleSize,
      edgeDetectionThreshold: zoomAdjustedEdgeGripWidth,
    );

    if (hitZone == null) {
      return false; // Outside scrollbar bounds
    }

    // Store drag state
    _activeScrollbarAxis = axis;
    _scrollbarDragStartPosition = position;
    _scrollbarLastDragPosition = position; // Initialize for incremental delta tracking
    _scrollbarDragStartZone = hitZone;

    // Show scrollbars and cancel auto-hide during drag (don't hide while dragging!)
    _scrollbarsVisible = true;
    _cancelScrollbarAutoHide();

    // Handle track click immediately (doesn't require drag)
    if (hitZone == HitTestZone.track) {
      _handleScrollbarTrackClick(axis, localPos, trackLength, handleSize);
    }

    // Claim scrollbar mode in coordinator
    coordinator.claimMode(InteractionMode.scrollbarDragging);

    markNeedsPaint(); // Redraw with active state
    return true; // Event claimed by scrollbar
  }

  /// Handles ongoing scrollbar drag interaction.
  void _handleScrollbarDrag(Offset currentPosition) {
    if (_activeScrollbarAxis == null ||
        _scrollbarDragStartPosition == null ||
        _scrollbarDragStartZone == null ||
        _scrollbarLastDragPosition == null) {
      return; // No active drag
    }

    // Track clicks don't drag - they jump immediately
    if (_scrollbarDragStartZone == HitTestZone.track) {
      return;
    }

    final axis = _activeScrollbarAxis!;
    final lastPos = _scrollbarLastDragPosition!;
    final zone = _scrollbarDragStartZone!;

    // Calculate INCREMENTAL pixel delta from last position (not from drag start)
    // This fixes issue #4: oversensitive pan due to accumulated delta
    final pixelDelta = axis == Axis.horizontal ? (currentPosition.dx - lastPos.dx) : (currentPosition.dy - lastPos.dy);

    // Update last position for next incremental delta
    _scrollbarLastDragPosition = currentPosition;

    // Convert zone to interaction type
    final interactionType = _scrollbarZoneToInteractionType(zone, axis);

    // Call appropriate pixel-delta handler
    if (axis == Axis.horizontal) {
      _handleXScrollbarDelta(pixelDelta, interactionType);
    } else {
      _handleYScrollbarDelta(pixelDelta, interactionType);
    }
  }

  /// Handles track click (jump to clicked position).
  void _handleScrollbarTrackClick(Axis axis, double clickPosition, double trackLength, double handleSize) {
    // Calculate where the handle CENTER should be positioned (clicked position)
    final targetHandleCenter = clickPosition;

    // Calculate where handle CENTER currently is
    final currentHandlePosition =
        axis == Axis.horizontal ? _calculateCurrentHandlePosition(Axis.horizontal) : _calculateCurrentHandlePosition(Axis.vertical);
    final currentHandleCenter = currentHandlePosition + (handleSize / 2.0);

    // Pixel delta = where we want to be - where we are
    final pixelDelta = targetHandleCenter - currentHandleCenter;

    // Call pixel-delta handler with trackClick interaction type
    if (axis == Axis.horizontal) {
      _handleXScrollbarDelta(pixelDelta, ScrollbarInteraction.trackClick);
    } else {
      _handleYScrollbarDelta(pixelDelta, ScrollbarInteraction.trackClick);
    }
  }

  /// Calculates current handle position for an axis (used for track click calculations).
  double _calculateCurrentHandlePosition(Axis axis) {
    if (_transform == null || _originalTransform == null) return 0.0;

    final isHorizontal = axis == Axis.horizontal;
    final scrollbarRect = isHorizontal ? _xScrollbarRect : _yScrollbarRect;
    if (scrollbarRect == null) return 0.0;

    final trackLength = isHorizontal ? scrollbarRect.width : scrollbarRect.height;
    final dataMin = isHorizontal ? _originalTransform!.dataXMin : _originalTransform!.dataYMin;
    final dataMax = isHorizontal ? _originalTransform!.dataXMax : _originalTransform!.dataYMax;
    final viewportMin = isHorizontal ? _transform!.dataXMin : _transform!.dataYMin;

    final dataSpan = dataMax - dataMin;

    // Calculate handle position (same formula for both axes - natural mapping!)
    final viewportOffset = viewportMin - dataMin;
    return (viewportOffset / dataSpan * trackLength).clamp(0.0, trackLength);
  }

  /// Converts HitTestZone to ScrollbarInteraction type.
  ScrollbarInteraction _scrollbarZoneToInteractionType(HitTestZone zone, Axis axis) {
    switch (zone) {
      case HitTestZone.leftEdge:
      case HitTestZone.topEdge:
        return ScrollbarInteraction.zoomLeftOrTop;
      case HitTestZone.rightEdge:
      case HitTestZone.bottomEdge:
        return ScrollbarInteraction.zoomRightOrBottom;
      case HitTestZone.center:
        return ScrollbarInteraction.pan;
      case HitTestZone.track:
        return ScrollbarInteraction.trackClick;
    }
  }

  // ==========================================================================
  // Scrollbar Auto-Hide Logic
  // ==========================================================================

  /// Schedules scrollbar auto-hide after configured inactivity delay.
  ///
  /// "Inactivity" means no zoom/pan actions (mouse, keyboard, or scrollbar).
  /// Cancels any existing timer and starts fresh countdown.
  void _scheduleScrollbarAutoHide() {
    final scrollbarConfig = _scrollbarTheme ?? ScrollbarConfig.defaultLight;
    if (!scrollbarConfig.autoHide) return;

    _cancelScrollbarAutoHide();

    _scrollbarAutoHideTimer = Timer(scrollbarConfig.autoHideDelay, () {
      _scrollbarsVisible = false;
      markNeedsPaint();
    });
  }

  /// Cancels scheduled auto-hide timer without changing visibility.
  void _cancelScrollbarAutoHide() {
    _scrollbarAutoHideTimer?.cancel();
    _scrollbarAutoHideTimer = null;
  }

  /// Shows scrollbars and schedules auto-hide.
  ///
  /// Call on any zoom/pan action to show scrollbars and reset inactivity timer.
  void _showScrollbarsAndScheduleHide() {
    _scrollbarsVisible = true;
    _scheduleScrollbarAutoHide();
    markNeedsPaint();
  }

  /// Checks if viewport is zoomed or panned from original state.
  bool _isViewportModified() {
    if (_transform == null || _originalTransform == null) return false;

    return _transform!.dataXMin != _originalTransform!.dataXMin ||
        _transform!.dataXMax != _originalTransform!.dataXMax ||
        _transform!.dataYMin != _originalTransform!.dataYMin ||
        _transform!.dataYMax != _originalTransform!.dataYMax;
  }

  // ==========================================================================
  // Scrollbar Rendering
  // ==========================================================================

  /// Paints scrollbars if enabled.
  ///
  /// Renders horizontal and/or vertical scrollbars using ScrollbarPainter.
  /// Scrollbars show the current viewport range relative to the full data range.
  ///
  /// **ScrollbarConfig Properties - Implementation Status:**
  ///
  /// ✅ **FULLY IMPLEMENTED (Visual):**
  /// - `thickness` - Width/height of scrollbar track
  /// - `minHandleSize` - Minimum LENGTH of draggable handle (prevents tiny handle when zoomed out)
  /// - `padding` - Space between scrollbar and chart edge
  /// - `borderRadius` - Corner radius for rounded edges
  /// - `edgeGripWidth` - WIDTH of zoom edge zones at each end (relationship: minHandleSize >= edgeGripWidth * 2)
  ///
  /// ✅ **FULLY IMPLEMENTED (Colors):**
  /// - `trackColor` - Background color of scrollbar track
  /// - `trackHoverColor` - Track color when hovering over track (not on handle)
  /// - `handleColor` - Default handle color
  /// - `handleHoverColor` - Handle color when hovering
  /// - `handleActiveColor` - Handle color when dragging
  /// - `handleDisabledColor` - Handle color when disabled (TODO: wire to InteractionConfig)
  /// - `edgeZoneColor` - Default color of edge zones (always visible)
  /// - `edgeHoverColor` - Edge zone color when hovering (zoom affordance)
  /// - `gripIndicatorColor` - Color of grip indicator lines
  ///
  /// ✅ **FULLY IMPLEMENTED (Grip Indicators):**
  /// - `showGripIndicator` - Toggle center grip indicator on/off
  ///
  /// ❌ **NOT IMPLEMENTED (Animations - Architectural):**
  /// - `autoHide` - Auto-hide after inactivity (requires animation system)
  /// - `autoHideDelay` - Delay before hiding (requires timer management)
  /// - `fadeDuration` - Fade animation duration (requires animation controller)
  ///
  /// ❌ **NOT IMPLEMENTED (Behavior - Architectural):**
  /// - `enableResizeHandles` - Edge zones always enabled (no conditional logic)
  /// - `minZoomRatio` - Zoom limits not enforced in scrollbar (handled elsewhere)
  /// - `maxZoomRatio` - Zoom limits not enforced in scrollbar (handled elsewhere)
  ///
  /// ❌ **NOT IMPLEMENTED (Accessibility - Platform-Specific):**
  /// - `forcedColorsMode` - High contrast mode (requires MediaQuery integration)
  /// - `prefersReducedMotion` - Motion preferences (requires MediaQuery integration)
  ///
  /// **Note:** The ChartScrollbar widget (separate component) implements some of these
  /// missing features, but chart_render_box does direct rendering for performance.
  void _paintScrollbars(Canvas canvas, Size size) {
    if (_transform == null || _originalTransform == null) return;

    // Don't render scrollbars when hidden (they shouldn't exist)
    if (!_scrollbarsVisible) return;

    final scrollbarTheme = _scrollbarTheme ?? ScrollbarConfig.defaultLight;

    // Paint horizontal scrollbar (X-axis)
    if (_showXScrollbar && _xScrollbarRect != null) {
      // Use original transform for full data range
      final dataMin = _originalTransform!.dataXMin;
      final dataMax = _originalTransform!.dataXMax;

      // Use current transform for viewport range
      final viewportMin = _transform!.dataXMin;
      final viewportMax = _transform!.dataXMax;

      final trackLength = _xScrollbarRect!.width;
      final dataSpan = dataMax - dataMin;

      // Calculate handle size as ZOOM LEVEL representation
      // At 100% zoom (all data visible): handle = ~80% of track (no zoom applied)
      // As zoom increases: handle shrinks to show zoomed-in state
      // Example: 200% zoom → handle = 40% of track (showing you're viewing half the data)
      final viewportSpan = viewportMax - viewportMin;
      final visibleRatio = viewportSpan / dataSpan; // Gets smaller as you zoom in
      final handleSize = (visibleRatio * trackLength).clamp(scrollbarTheme.minHandleSize, trackLength);

      // Calculate handle position (where viewport starts relative to data)
      final viewportOffset = viewportMin - dataMin;
      final handlePosition = (viewportOffset / dataSpan * trackLength).clamp(0.0, trackLength - handleSize);

      // Calculate zoom-adjusted edge grip width (blue zones grow with zoom level)
      // At 100% zoom (visibleRatio=1.0): edgeGripWidth = base size (e.g., 8px)
      // At 200% zoom (visibleRatio=0.5): edgeGripWidth = 2x base size (e.g., 16px)
      // Formula: zoomFactor = 1 / visibleRatio = dataSpan / viewportSpan
      final zoomFactor = dataSpan / viewportSpan;
      final baseEdgeGripWidth = scrollbarTheme.edgeGripWidth;
      final maxEdgeGripWidth = handleSize * 0.4; // Max 40% of handle size to leave center draggable
      final zoomAdjustedEdgeGripWidth = (baseEdgeGripWidth * zoomFactor)
          .clamp(
            math.min(baseEdgeGripWidth, maxEdgeGripWidth), // Ensure min <= max
            maxEdgeGripWidth,
          )
          .toDouble();

      // Create modified scrollbar config with zoom-adjusted edge zones
      final zoomAdjustedConfig = scrollbarTheme.copyWith(
        edgeGripWidth: zoomAdjustedEdgeGripWidth,
      );

      // Create scrollbar state with hover zone for visual feedback
      final state = ScrollbarState(
        handlePosition: handlePosition,
        handleSize: handleSize,
        isDragging: _activeScrollbarAxis == Axis.horizontal,
        hoverZone: _xScrollbarHoverZone,
        isFocused: false,
        isVisible: true,
      );

      // Create painter and render with zoom-adjusted config
      final painter = ScrollbarPainter(
        config: zoomAdjustedConfig,
        state: state,
        isHorizontal: true,
        trackLength: trackLength,
        isTrackHovered: _xScrollbarHoverZone == HitTestZone.track,
        opacity: 1.0,
      );

      canvas.save();
      canvas.translate(_xScrollbarRect!.left, _xScrollbarRect!.top);
      painter.paint(canvas, Size(_xScrollbarRect!.width, _xScrollbarRect!.height));
      canvas.restore();
    }

    // Paint vertical scrollbar (Y-axis)
    if (_showYScrollbar && _yScrollbarRect != null) {
      // Use original transform for full data range
      final dataMin = _originalTransform!.dataYMin;
      final dataMax = _originalTransform!.dataYMax;

      // Use current transform for viewport range
      final viewportMin = _transform!.dataYMin;
      final viewportMax = _transform!.dataYMax;

      final trackLength = _yScrollbarRect!.height;
      final dataSpan = dataMax - dataMin;

      // Calculate handle size as ZOOM LEVEL representation
      // At 100% zoom (all data visible): handle = ~80% of track (no zoom applied)
      // As zoom increases: handle shrinks to show zoomed-in state
      // Example: 200% zoom → handle = 40% of track (showing you're viewing half the data)
      final viewportSpan = viewportMax - viewportMin;
      final visibleRatio = viewportSpan / dataSpan; // Gets smaller as you zoom in
      final handleSize = (visibleRatio * trackLength).clamp(scrollbarTheme.minHandleSize, trackLength);

      // Calculate handle position (where viewport starts relative to data)
      // Y-AXIS INVERTED: In chart space, Y increases upward, but in screen space Y increases downward
      // When viewport shows LOWER Y values (bottom of chart), handle should be at TOP of scrollbar
      // When viewport shows HIGHER Y values (top of chart), handle should be at BOTTOM of scrollbar
      // Therefore: use viewportMin (not viewportMax) and NO inversion needed!
      final viewportOffset = viewportMin - dataMin;
      final handlePosition = (viewportOffset / dataSpan * trackLength).clamp(0.0, trackLength - handleSize);

      // Calculate zoom-adjusted edge grip width (blue zones grow with zoom level)
      // At 100% zoom (visibleRatio=1.0): edgeGripWidth = base size (e.g., 40px)
      // At 200% zoom (visibleRatio=0.5): edgeGripWidth = 2x base size (e.g., 80px)
      // Formula: zoomFactor = 1 / visibleRatio = dataSpan / viewportSpan
      final zoomFactor = dataSpan / viewportSpan;
      final baseEdgeGripWidth = scrollbarTheme.edgeGripWidth;
      final maxEdgeGripWidth = handleSize * 0.4; // Max 40% of handle size to leave center draggable
      final zoomAdjustedEdgeGripWidth = (baseEdgeGripWidth * zoomFactor)
          .clamp(
            math.min(baseEdgeGripWidth, maxEdgeGripWidth), // Ensure min <= max
            maxEdgeGripWidth,
          )
          .toDouble();

      // Create modified scrollbar config with zoom-adjusted edge zones
      final zoomAdjustedConfig = scrollbarTheme.copyWith(
        edgeGripWidth: zoomAdjustedEdgeGripWidth,
      );

      // Create scrollbar state with hover zone for visual feedback
      final state = ScrollbarState(
        handlePosition: handlePosition,
        handleSize: handleSize,
        isDragging: _activeScrollbarAxis == Axis.vertical,
        hoverZone: _yScrollbarHoverZone,
        isFocused: false,
        isVisible: true,
      );

      // Create painter and render with zoom-adjusted config
      final painter = ScrollbarPainter(
        config: zoomAdjustedConfig,
        state: state,
        isHorizontal: false,
        trackLength: trackLength,
        isTrackHovered: _yScrollbarHoverZone == HitTestZone.track,
        opacity: 1.0,
      );

      canvas.save();
      canvas.translate(_yScrollbarRect!.left, _yScrollbarRect!.top);
      painter.paint(canvas, Size(_yScrollbarRect!.width, _yScrollbarRect!.height));
      canvas.restore();
    }
  }

  // ============================================================================
  // Scrollbar Interaction Handlers
  // ============================================================================

  /// Handles horizontal scrollbar pixel delta and converts to viewport change.
  ///
  /// Converts pixel delta from scrollbar to data delta using current viewport,
  /// then updates the X viewport range accordingly.
  ///
  /// **Parameters**:
  /// - `pixelDelta`: Horizontal pixel offset from scrollbar drag
  /// - `interactionType`: Type of scrollbar interaction (pan, zoom, track click)
  void _handleXScrollbarDelta(double pixelDelta, ScrollbarInteraction interactionType) {
    if (_transform == null || _originalTransform == null || _xScrollbarRect == null) return;

    final trackLength = _xScrollbarRect!.width;
    if (trackLength == 0) return;

    // Get full data range (original transform = full dataset)
    final dataMin = _originalTransform!.dataXMin;
    final dataMax = _originalTransform!.dataXMax;
    final dataSpan = dataMax - dataMin;

    // Get current viewport range
    final viewportMin = _transform!.dataXMin;
    final viewportMax = _transform!.dataXMax;
    final viewportSpan = viewportMax - viewportMin;

    // Convert pixel delta to data delta
    final dataPerPixel = dataSpan / trackLength;
    final dataDelta = pixelDelta * dataPerPixel;

    // Apply based on interaction type
    switch (interactionType) {
      case ScrollbarInteraction.pan:
        // Pan: shift entire viewport by delta
        var newMin = viewportMin + dataDelta;
        var newMax = viewportMax + dataDelta;

        // Clamp to data bounds
        if (newMin < dataMin) {
          newMin = dataMin;
          newMax = dataMin + viewportSpan;
        }
        if (newMax > dataMax) {
          newMax = dataMax;
          newMin = dataMax - viewportSpan;
        }

        _transform = _transform!.copyWith(dataXMin: newMin, dataXMax: newMax);
        break;

      case ScrollbarInteraction.zoomLeftOrTop:
        // Zoom left: adjust minimum boundary only
        var newMin = viewportMin + dataDelta;

        // Clamp to prevent inversion and respect data bounds
        newMin = newMin.clamp(dataMin, viewportMax - (dataSpan * 0.01)); // Min 1% of data range

        _transform = _transform!.copyWith(dataXMin: newMin);
        break;

      case ScrollbarInteraction.zoomRightOrBottom:
        // Zoom right: adjust maximum boundary only
        var newMax = viewportMax + dataDelta;

        // Clamp to prevent inversion and respect data bounds
        newMax = newMax.clamp(viewportMin + (dataSpan * 0.01), dataMax); // Min 1% of data range

        _transform = _transform!.copyWith(dataXMax: newMax);
        break;

      case ScrollbarInteraction.trackClick:
        // Track click: center viewport at clicked position
        final targetDataPosition = dataMin + (pixelDelta * dataPerPixel);
        final halfSpan = viewportSpan / 2;

        var newMin = targetDataPosition - halfSpan;
        var newMax = targetDataPosition + halfSpan;

        // Clamp to data bounds
        if (newMin < dataMin) {
          newMin = dataMin;
          newMax = dataMin + viewportSpan;
        }
        if (newMax > dataMax) {
          newMax = dataMax;
          newMin = dataMax - viewportSpan;
        }

        _transform = _transform!.copyWith(dataXMin: newMin, dataXMax: newMax);
        break;

      case ScrollbarInteraction.keyboard:
        // Keyboard: apply delta directly (already calculated by controller)
        var newMin = viewportMin + dataDelta;
        var newMax = viewportMax + dataDelta;

        // Clamp to data bounds
        if (newMin < dataMin) {
          newMin = dataMin;
          newMax = dataMin + viewportSpan;
        }
        if (newMax > dataMax) {
          newMax = dataMax;
          newMin = dataMax - viewportSpan;
        }

        _transform = _transform!.copyWith(dataXMin: newMin, dataXMax: newMax);
        break;
    }

    // Update axes and trigger repaint
    _updateAxesFromTransform();

    // Show scrollbars and schedule auto-hide after viewport change
    _showScrollbarsAndScheduleHide();
  }

  /// Handles vertical scrollbar pixel delta and converts to viewport change.
  ///
  /// Converts pixel delta from scrollbar to data delta using current viewport,
  /// then updates the Y viewport range accordingly.
  ///
  /// **Y-AXIS COORDINATE MAPPING**: Drag direction matches viewport movement.
  /// Positive pixelDelta (drag down) moves viewport DOWN (to lower Y values).
  /// Negative pixelDelta (drag up) moves viewport UP (to higher Y values).
  ///
  /// **Parameters**:
  /// - `pixelDelta`: Vertical pixel offset from scrollbar drag
  /// - `interactionType`: Type of scrollbar interaction (pan, zoom, track click)
  void _handleYScrollbarDelta(double pixelDelta, ScrollbarInteraction interactionType) {
    if (_transform == null || _originalTransform == null || _yScrollbarRect == null) return;

    final trackLength = _yScrollbarRect!.height;
    if (trackLength == 0) return;

    // Get full data range (original transform = full dataset)
    final dataMin = _originalTransform!.dataYMin;
    final dataMax = _originalTransform!.dataYMax;
    final dataSpan = dataMax - dataMin;

    // Get current viewport range
    final viewportMin = _transform!.dataYMin;
    final viewportMax = _transform!.dataYMax;
    final viewportSpan = viewportMax - viewportMin;

    // Convert pixel delta to data delta (natural mapping for Y-axis)
    final dataPerPixel = dataSpan / trackLength;
    final dataDelta = pixelDelta * dataPerPixel; // Drag down = move viewport down

    // Apply based on interaction type
    switch (interactionType) {
      case ScrollbarInteraction.pan:
        // Pan: shift entire viewport by delta
        var newMin = viewportMin + dataDelta;
        var newMax = viewportMax + dataDelta;

        // Clamp to data bounds
        if (newMin < dataMin) {
          newMin = dataMin;
          newMax = dataMin + viewportSpan;
        }
        if (newMax > dataMax) {
          newMax = dataMax;
          newMin = dataMax - viewportSpan;
        }

        _transform = _transform!.copyWith(dataYMin: newMin, dataYMax: newMax);
        break;

      case ScrollbarInteraction.zoomLeftOrTop:
        // Zoom top: adjust minimum boundary only
        var newMin = viewportMin + dataDelta;

        // Clamp to prevent inversion and respect data bounds
        newMin = newMin.clamp(dataMin, viewportMax - (dataSpan * 0.01)); // Min 1% of data range

        _transform = _transform!.copyWith(dataYMin: newMin);
        break;

      case ScrollbarInteraction.zoomRightOrBottom:
        // Zoom bottom: adjust maximum boundary only
        var newMax = viewportMax + dataDelta;

        // Clamp to prevent inversion and respect data bounds
        newMax = newMax.clamp(viewportMin + (dataSpan * 0.01), dataMax); // Min 1% of data range

        _transform = _transform!.copyWith(dataYMax: newMax);
        break;

      case ScrollbarInteraction.trackClick:
        // Track click: center viewport at clicked position
        final targetDataPosition = dataMin + (pixelDelta * dataPerPixel);
        final halfSpan = viewportSpan / 2;

        var newMin = targetDataPosition - halfSpan;
        var newMax = targetDataPosition + halfSpan;

        // Clamp to data bounds
        if (newMin < dataMin) {
          newMin = dataMin;
          newMax = dataMin + viewportSpan;
        }
        if (newMax > dataMax) {
          newMax = dataMax;
          newMin = dataMax - viewportSpan;
        }

        _transform = _transform!.copyWith(dataYMin: newMin, dataYMax: newMax);
        break;

      case ScrollbarInteraction.keyboard:
        // Keyboard: apply delta directly (already calculated by controller)
        var newMin = viewportMin + dataDelta;
        var newMax = viewportMax + dataDelta;

        // Clamp to data bounds
        if (newMin < dataMin) {
          newMin = dataMin;
          newMax = dataMin + viewportSpan;
        }
        if (newMax > dataMax) {
          newMax = dataMax;
          newMin = dataMax - viewportSpan;
        }

        _transform = _transform!.copyWith(dataYMin: newMin, dataYMax: newMax);
        break;
    }

    // Update axes and trigger repaint
    _updateAxesFromTransform();

    // Show scrollbars and schedule auto-hide after viewport change
    _showScrollbarsAndScheduleHide();
  }

  /// Draws coordinate labels for the crosshair showing screen and data coordinates.
  ///
  /// Displays:
  /// - X label at bottom of plot area showing data coordinate
  /// - Y label at left of plot area showing data coordinate
  void _drawCrosshairLabels(Canvas canvas, Size size, Offset cursorPos) {
    if (_transform == null) return;

    // Convert cursor position (widget space) to plot space for data coordinate calculation
    final plotPos = widgetToPlot(cursorPos);

    // Convert plot coordinates to data coordinates
    final dataPos = _transform!.plotToData(plotPos.dx, plotPos.dy);
    final dataX = dataPos.dx;
    final dataY = dataPos.dy;

    const textStyle = TextStyle(
      color: Color(0xFF000000),
      fontSize: 10,
      backgroundColor: Color(0xF0FFFFFF), // Almost opaque white
    );

    const labelPadding = 4.0;
    final labelBackgroundPaint = Paint()..color = const Color(0xF0FFFFFF);

    // X coordinate label (positioned at bottom of chart area)
    final xDisplayValue = _formatDataValue(dataX);
    final xTextPainter = TextPainter(
      text: TextSpan(text: 'X: $xDisplayValue', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    // Position label inside chart area (just above bottom edge)
    var xLabelX = cursorPos.dx - xTextPainter.width / 2;
    final xLabelY = _plotArea.bottom - xTextPainter.height - 8;

    // Clamp X position to keep label within plot bounds
    xLabelX = xLabelX.clamp(_plotArea.left + labelPadding, _plotArea.right - xTextPainter.width - labelPadding);

    // Draw background
    final xBgRect = Rect.fromLTWH(
      xLabelX - labelPadding,
      xLabelY - labelPadding,
      xTextPainter.width + labelPadding * 2,
      xTextPainter.height + labelPadding * 2,
    );
    canvas.drawRect(xBgRect, labelBackgroundPaint);

    // Draw text
    xTextPainter.paint(canvas, Offset(xLabelX, xLabelY));

    // Y coordinate label (positioned at left of chart area)
    final yDisplayValue = _formatDataValue(dataY);
    final yTextPainter = TextPainter(
      text: TextSpan(text: 'Y: $yDisplayValue', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    // Position label inside chart area (just right of left edge)
    final yLabelX = _plotArea.left + 8;
    var yLabelY = cursorPos.dy - yTextPainter.height / 2;

    // Clamp Y position to keep label within plot bounds
    yLabelY = yLabelY.clamp(_plotArea.top + labelPadding, _plotArea.bottom - yTextPainter.height - labelPadding);

    // Draw background
    final yBgRect = Rect.fromLTWH(
      yLabelX - labelPadding,
      yLabelY - labelPadding,
      yTextPainter.width + labelPadding * 2,
      yTextPainter.height + labelPadding * 2,
    );
    canvas.drawRect(yBgRect, labelBackgroundPaint);

    // Draw text
    yTextPainter.paint(canvas, Offset(yLabelX, yLabelY));
  }

  /// Formats data values for display (same logic as axis labels).
  String _formatDataValue(double value) {
    // If the value is very close to an integer, show it as an integer
    if ((value - value.round()).abs() < 0.0001) {
      return value.round().toString();
    }

    // Otherwise, show with appropriate decimal places
    if (value.abs() < 0.01) {
      return value.toStringAsExponential(1);
    } else if (value.abs() < 1) {
      return value.toStringAsFixed(2);
    } else if (value.abs() < 100) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(0);
    }
  }

  /// Draws a tooltip for the hovered element.
  ///
  /// Implements FR-003: Tooltip System from spec 007-interaction-system
  /// - Shows data point details (series name, X value, Y value)
  /// - Positions automatically to avoid clipping
  /// - Renders with semi-transparent background
  ///
  /// For series elements, finds the nearest datapoint to cursor position.
  /// Draws tooltip at the exact position of a hovered data point marker.

  /// Creates a tooltip path with an arrow pointer pointing to the data point.
  ///
  /// [tooltipRect] The rectangle bounds of the tooltip
  /// [arrowAnchor] The exact point the arrow should point to (data point position)
  /// [arrowSize] The height/width of the arrow pointer
  /// [borderRadius] The corner radius of the tooltip
  ///
  /// Returns a Path that includes rounded corners and an arrow pointer
  /// positioned on the side closest to the anchor point.
  Path _createTooltipPath({
    required Rect tooltipRect,
    required Offset arrowAnchor,
    required double arrowSize,
    required double borderRadius,
  }) {
    final path = Path();

    // Determine which side should have the arrow based on anchor position
    // Arrow points TO the anchor from the tooltip

    // Calculate which edge is closest to anchor
    final leftDist = (arrowAnchor.dx - tooltipRect.left).abs();
    final rightDist = (arrowAnchor.dx - tooltipRect.right).abs();
    final topDist = (arrowAnchor.dy - tooltipRect.top).abs();
    final bottomDist = (arrowAnchor.dy - tooltipRect.bottom).abs();

    final minHorizDist = leftDist < rightDist ? leftDist : rightDist;
    final minVertDist = topDist < bottomDist ? topDist : bottomDist;

    // Determine arrow position (prefer vertical positioning for typical top/bottom tooltips)
    final bool arrowOnTop = topDist < bottomDist && minVertDist < minHorizDist;
    final bool arrowOnBottom = bottomDist <= topDist && minVertDist < minHorizDist;
    final bool arrowOnLeft = !arrowOnTop && !arrowOnBottom && leftDist < rightDist;
    // arrowOnRight is the else case    // Calculate arrow offset along the edge (clamped to stay within rect with margin)
    const edgeMargin = 10.0; // Keep arrow away from corners

    if (arrowOnTop) {
      // Arrow on top edge pointing up to anchor
      final arrowX = (arrowAnchor.dx - tooltipRect.left).clamp(
        edgeMargin + arrowSize / 2,
        tooltipRect.width - edgeMargin - arrowSize / 2,
      );
      final arrowLeft = arrowX - arrowSize / 2;
      final arrowRight = arrowX + arrowSize / 2;
      final arrowTop = tooltipRect.top - arrowSize;

      path.moveTo(tooltipRect.left + borderRadius, tooltipRect.top);
      path.lineTo(tooltipRect.left + arrowLeft, tooltipRect.top);
      path.lineTo(tooltipRect.left + arrowX, arrowTop); // Arrow point
      path.lineTo(tooltipRect.left + arrowRight, tooltipRect.top);
      path.lineTo(tooltipRect.right - borderRadius, tooltipRect.top);
      path.quadraticBezierTo(tooltipRect.right, tooltipRect.top, tooltipRect.right, tooltipRect.top + borderRadius);
      path.lineTo(tooltipRect.right, tooltipRect.bottom - borderRadius);
      path.quadraticBezierTo(tooltipRect.right, tooltipRect.bottom, tooltipRect.right - borderRadius, tooltipRect.bottom);
      path.lineTo(tooltipRect.left + borderRadius, tooltipRect.bottom);
      path.quadraticBezierTo(tooltipRect.left, tooltipRect.bottom, tooltipRect.left, tooltipRect.bottom - borderRadius);
      path.lineTo(tooltipRect.left, tooltipRect.top + borderRadius);
      path.quadraticBezierTo(tooltipRect.left, tooltipRect.top, tooltipRect.left + borderRadius, tooltipRect.top);
    } else if (arrowOnBottom) {
      // Arrow on bottom edge pointing down to anchor
      final arrowX = (arrowAnchor.dx - tooltipRect.left).clamp(
        edgeMargin + arrowSize / 2,
        tooltipRect.width - edgeMargin - arrowSize / 2,
      );
      final arrowLeft = arrowX - arrowSize / 2;
      final arrowRight = arrowX + arrowSize / 2;
      final arrowBottom = tooltipRect.bottom + arrowSize;

      path.moveTo(tooltipRect.left + borderRadius, tooltipRect.top);
      path.lineTo(tooltipRect.right - borderRadius, tooltipRect.top);
      path.quadraticBezierTo(tooltipRect.right, tooltipRect.top, tooltipRect.right, tooltipRect.top + borderRadius);
      path.lineTo(tooltipRect.right, tooltipRect.bottom - borderRadius);
      path.quadraticBezierTo(tooltipRect.right, tooltipRect.bottom, tooltipRect.right - borderRadius, tooltipRect.bottom);
      path.lineTo(tooltipRect.left + arrowRight, tooltipRect.bottom);
      path.lineTo(tooltipRect.left + arrowX, arrowBottom); // Arrow point
      path.lineTo(tooltipRect.left + arrowLeft, tooltipRect.bottom);
      path.lineTo(tooltipRect.left + borderRadius, tooltipRect.bottom);
      path.quadraticBezierTo(tooltipRect.left, tooltipRect.bottom, tooltipRect.left, tooltipRect.bottom - borderRadius);
      path.lineTo(tooltipRect.left, tooltipRect.top + borderRadius);
      path.quadraticBezierTo(tooltipRect.left, tooltipRect.top, tooltipRect.left + borderRadius, tooltipRect.top);
    } else if (arrowOnLeft) {
      // Arrow on left edge pointing left to anchor
      final arrowY = (arrowAnchor.dy - tooltipRect.top).clamp(
        edgeMargin + arrowSize / 2,
        tooltipRect.height - edgeMargin - arrowSize / 2,
      );
      final arrowTop = arrowY - arrowSize / 2;
      final arrowBottom = arrowY + arrowSize / 2;
      final arrowLeft = tooltipRect.left - arrowSize;

      path.moveTo(tooltipRect.left, tooltipRect.top + borderRadius);
      path.lineTo(tooltipRect.left, tooltipRect.top + arrowTop);
      path.lineTo(arrowLeft, tooltipRect.top + arrowY); // Arrow point
      path.lineTo(tooltipRect.left, tooltipRect.top + arrowBottom);
      path.lineTo(tooltipRect.left, tooltipRect.bottom - borderRadius);
      path.quadraticBezierTo(tooltipRect.left, tooltipRect.bottom, tooltipRect.left + borderRadius, tooltipRect.bottom);
      path.lineTo(tooltipRect.right - borderRadius, tooltipRect.bottom);
      path.quadraticBezierTo(tooltipRect.right, tooltipRect.bottom, tooltipRect.right, tooltipRect.bottom - borderRadius);
      path.lineTo(tooltipRect.right, tooltipRect.top + borderRadius);
      path.quadraticBezierTo(tooltipRect.right, tooltipRect.top, tooltipRect.right - borderRadius, tooltipRect.top);
      path.lineTo(tooltipRect.left + borderRadius, tooltipRect.top);
      path.quadraticBezierTo(tooltipRect.left, tooltipRect.top, tooltipRect.left, tooltipRect.top + borderRadius);
    } else {
      // arrowOnRight
      // Arrow on right edge pointing right to anchor
      final arrowY = (arrowAnchor.dy - tooltipRect.top).clamp(
        edgeMargin + arrowSize / 2,
        tooltipRect.height - edgeMargin - arrowSize / 2,
      );
      final arrowTop = arrowY - arrowSize / 2;
      final arrowBottom = arrowY + arrowSize / 2;
      final arrowRight = tooltipRect.right + arrowSize;

      path.moveTo(tooltipRect.left + borderRadius, tooltipRect.top);
      path.lineTo(tooltipRect.right - borderRadius, tooltipRect.top);
      path.quadraticBezierTo(tooltipRect.right, tooltipRect.top, tooltipRect.right, tooltipRect.top + borderRadius);
      path.lineTo(tooltipRect.right, tooltipRect.top + arrowTop);
      path.lineTo(arrowRight, tooltipRect.top + arrowY); // Arrow point
      path.lineTo(tooltipRect.right, tooltipRect.top + arrowBottom);
      path.lineTo(tooltipRect.right, tooltipRect.bottom - borderRadius);
      path.quadraticBezierTo(tooltipRect.right, tooltipRect.bottom, tooltipRect.right - borderRadius, tooltipRect.bottom);
      path.lineTo(tooltipRect.left + borderRadius, tooltipRect.bottom);
      path.quadraticBezierTo(tooltipRect.left, tooltipRect.bottom, tooltipRect.left, tooltipRect.bottom - borderRadius);
      path.lineTo(tooltipRect.left, tooltipRect.top + borderRadius);
      path.quadraticBezierTo(tooltipRect.left, tooltipRect.top, tooltipRect.left + borderRadius, tooltipRect.top);
    }

    path.close();
    return path;
  }

  void _drawMarkerTooltip(Canvas canvas, Size size, HoveredMarkerInfo markerInfo) {
    // Get tooltip configuration (use default if not provided)
    final config = _interactionConfig?.tooltip ?? const TooltipConfig();

    // Find the series element containing this marker
    final seriesElement = _elements.whereType<SeriesElement>().firstWhere(
          (e) => e.id == markerInfo.seriesId,
          orElse: () => throw StateError('Series ${markerInfo.seriesId} not found'),
        );

    // Get the exact data point
    final dataPoint = seriesElement.series.points[markerInfo.markerIndex];

    // Convert data point to screen coordinates for tooltip anchor
    // If followCursor is enabled, use current cursor position instead of marker position
    final tooltipAnchor = config.followCursor && _cursorPosition != null ? _cursorPosition! : plotToWidget(markerInfo.plotPosition);

    // Build tooltip text
    final seriesName = seriesElement.series.name ?? seriesElement.id;
    final tooltipText = '$seriesName\nX: ${_formatDataValue(dataPoint.x)}\nY: ${_formatDataValue(dataPoint.y)}';

    // Create text painter with configured style
    final textStyle = TextStyle(
      color: config.style.textColor,
      fontSize: config.style.fontSize,
      fontWeight: FontWeight.w500,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: tooltipText, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    // Calculate tooltip size with configured padding
    final padding = config.style.padding;
    final tooltipWidth = textPainter.width + padding * 2;
    final tooltipHeight = textPainter.height + padding * 2;

    // Get marker radius to offset tooltip position
    double markerRadius = 0.0;
    if (seriesElement.series is LineChartSeries) {
      markerRadius = (seriesElement.series as LineChartSeries).dataPointMarkerRadius;
    } else if (seriesElement.series is ScatterChartSeries) {
      markerRadius = (seriesElement.series as ScatterChartSeries).markerRadius;
    } else if (seriesElement.series is AreaChartSeries) {
      markerRadius = (seriesElement.series as AreaChartSeries).dataPointMarkerRadius;
    }

    // Smart positioning: Respect preferredPosition, but auto-adjust to avoid clipping
    // Add marker radius to offset so arrow starts at marker edge, not center
    final offset = config.offsetFromPoint + markerRadius;
    const edgeMargin = 10.0; // Margin from canvas edges

    double tooltipX;
    double tooltipY;

    // Determine initial position based on preferredPosition
    switch (config.preferredPosition) {
      case TooltipPosition.top:
        tooltipX = tooltipAnchor.dx - tooltipWidth / 2;
        tooltipY = tooltipAnchor.dy - tooltipHeight - offset;
        break;
      case TooltipPosition.bottom:
        tooltipX = tooltipAnchor.dx - tooltipWidth / 2;
        tooltipY = tooltipAnchor.dy + offset;
        break;
      case TooltipPosition.left:
        tooltipX = tooltipAnchor.dx - tooltipWidth - offset;
        tooltipY = tooltipAnchor.dy - tooltipHeight / 2;
        break;
      case TooltipPosition.right:
        tooltipX = tooltipAnchor.dx + offset;
        tooltipY = tooltipAnchor.dy - tooltipHeight / 2;
        break;
      case TooltipPosition.auto:
        // Auto mode: default to top, but will flip if needed
        tooltipX = tooltipAnchor.dx - tooltipWidth / 2;
        tooltipY = tooltipAnchor.dy - tooltipHeight - offset;
        break;
    }

    // Adjust X position to avoid clipping left/right edges
    if (tooltipX < edgeMargin) {
      tooltipX = edgeMargin;
    } else if (tooltipX + tooltipWidth > size.width - edgeMargin) {
      tooltipX = size.width - tooltipWidth - edgeMargin;
    }

    // Adjust Y position to avoid clipping top/bottom edges
    if (tooltipY < edgeMargin) {
      // Would clip top - flip to bottom if in top/auto mode
      if (config.preferredPosition == TooltipPosition.top || config.preferredPosition == TooltipPosition.auto) {
        tooltipY = tooltipAnchor.dy + offset;
      } else {
        // Otherwise just push down
        tooltipY = edgeMargin;
      }
    } else if (tooltipY + tooltipHeight > size.height - edgeMargin) {
      // Would clip bottom - flip to top if in bottom mode
      if (config.preferredPosition == TooltipPosition.bottom) {
        tooltipY = tooltipAnchor.dy - tooltipHeight - offset;
      } else {
        // Otherwise just push up
        tooltipY = size.height - tooltipHeight - edgeMargin;
      }
    }

    // Create tooltip path with arrow pointer
    const arrowSize = 8.0; // Height/width of arrow

    final tooltipRect = Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight);

    final tooltipPath = _createTooltipPath(
      tooltipRect: tooltipRect,
      arrowAnchor: tooltipAnchor,
      arrowSize: arrowSize,
      borderRadius: config.style.borderRadius,
    );

    // Draw shadow if configured (with opacity)
    if (config.style.shadowBlurRadius > 0) {
      final shadowPath = tooltipPath.shift(const Offset(0, 2));
      canvas.drawPath(
        shadowPath,
        Paint()
          ..color = config.style.shadowColor.withOpacity(config.style.shadowColor.opacity * _tooltipOpacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.style.shadowBlurRadius),
      );
    }

    // Draw background with configured color (with opacity)
    canvas.drawPath(
      tooltipPath,
      Paint()
        ..color = config.style.backgroundColor.withOpacity(config.style.backgroundColor.opacity * _tooltipOpacity)
        ..style = PaintingStyle.fill,
    );

    // Draw border if configured (with opacity)
    if (config.style.borderWidth > 0) {
      canvas.drawPath(
        tooltipPath,
        Paint()
          ..color = config.style.borderColor.withOpacity(config.style.borderColor.opacity * _tooltipOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = config.style.borderWidth,
      );
    }

    // Draw text (with opacity)
    final textPaintWithOpacity = TextPainter(
      text: TextSpan(
        text: tooltipText,
        style: textStyle.copyWith(color: config.style.textColor.withOpacity(_tooltipOpacity)),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    textPaintWithOpacity.paint(canvas, Offset(tooltipX + padding, tooltipY + padding));
  }

  /// Shows tooltip with configured delay and fade-in animation.
  void _showTooltipWithDelay(HoveredMarkerInfo markerInfo) {
    final config = _interactionConfig?.tooltip ?? const TooltipConfig();

    // Cancel existing timers
    _tooltipShowTimer?.cancel();
    _tooltipHideTimer?.cancel();

    // Cache target marker to detect changes
    _tooltipTargetMarker = markerInfo;

    // If showDelay is zero, show immediately
    if (config.showDelay == Duration.zero) {
      _animateTooltipOpacity(1.0, const Duration(milliseconds: 150));
      return;
    }

    // Start show delay timer
    _tooltipShowTimer = Timer(config.showDelay, () {
      // Only show if still targeting same marker
      if (_tooltipTargetMarker == markerInfo) {
        _animateTooltipOpacity(1.0, const Duration(milliseconds: 150));
      }
    });
  }

  /// Hides tooltip with configured delay and fade-out animation.
  void _hideTooltipWithDelay() {
    final config = _interactionConfig?.tooltip ?? const TooltipConfig();

    // Cancel show timer (user moved away before delay finished)
    _tooltipShowTimer?.cancel();
    _tooltipTargetMarker = null;

    // If hideDelay is zero, hide immediately
    if (config.hideDelay == Duration.zero) {
      _animateTooltipOpacity(0.0, const Duration(milliseconds: 100));
      return;
    }

    // Start hide delay timer
    _tooltipHideTimer = Timer(config.hideDelay, () {
      _animateTooltipOpacity(0.0, const Duration(milliseconds: 100));
    });
  }

  /// Animates tooltip opacity to target value over specified duration.
  void _animateTooltipOpacity(double target, Duration duration) {
    _tooltipFadeTimer?.cancel();

    final startOpacity = _tooltipOpacity;
    final delta = target - startOpacity;

    // If already at target, nothing to do
    if (delta.abs() < 0.001) {
      _tooltipOpacity = target;
      markNeedsPaint();
      return;
    }

    // Animate in small steps for smooth fade
    const fps = 60;
    const stepDuration = Duration(milliseconds: 1000 ~/ fps);
    final totalSteps = (duration.inMilliseconds * fps / 1000).round();
    var currentStep = 0;

    _tooltipFadeTimer = Timer.periodic(stepDuration, (timer) {
      currentStep++;

      if (currentStep >= totalSteps) {
        _tooltipOpacity = target;
        timer.cancel();
        markNeedsPaint();
      } else {
        final progress = currentStep / totalSteps;
        _tooltipOpacity = startOpacity + delta * progress;
        markNeedsPaint();
      }
    });
  }

  /// Cancels all tooltip timers and resets animation state.
  void _cancelTooltipTimers() {
    _tooltipShowTimer?.cancel();
    _tooltipShowTimer = null;
    _tooltipHideTimer?.cancel();
    _tooltipHideTimer = null;
    _tooltipFadeTimer?.cancel();
    _tooltipFadeTimer = null;
    _tooltipTargetMarker = null;
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
