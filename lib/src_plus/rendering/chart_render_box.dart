// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
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
import '../models/chart_theme.dart';
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
    this.onElementClick,
    this.onElementHover,
    this.onEmptyAreaClick,
    this.onCursorChange,
  })  : _elementGenerator = elementGenerator,
        _theme = theme,
        _tooltipsEnabled = tooltipsEnabled,
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
  final void Function(ChartElement? element)? onElementHover;

  /// Callback for empty area click (for box select start).
  final void Function(Offset position, PointerEvent event)? onEmptyAreaClick;

  /// Callback for cursor changes.
  final void Function(MouseCursor cursor)? onCursorChange;

  /// Current resize state (if resizing annotation).
  // Current resize state (if resizing annotation).
  ResizeDirection? _activeResizeDirection;
  RangeAnnotationElement? _resizingAnnotation;
  Rect? _resizeStartBounds;

  /// Current cursor position (for crosshair rendering).
  Offset? _cursorPosition;

  /// Whether tooltips are enabled.
  final bool _tooltipsEnabled;

  /// Last pan position (for calculating delta during middle-button drag).
  Offset? _lastPanPosition;

  // ==========================================================================
  // Hit Test Throttling (Performance Optimization)
  // ==========================================================================

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

      // Also update _originalTransform so pan constraints work correctly
      if (_originalTransform != null) {
        _originalTransform = _originalTransform!.copyWith(
          dataXMin: axis.dataMin,
          dataXMax: axis.dataMax,
        );
      }

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

      // Also update _originalTransform so pan constraints work correctly
      if (_originalTransform != null) {
        _originalTransform = _originalTransform!.copyWith(
          dataYMin: axis.dataMin,
          dataYMax: axis.dataMax,
        );
      }

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

    debugPrint('🔓 Pan constraints set to FULL DATASET: X=[$xMin, $xMax], Y=[$yMin, $yMax]');
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
    debugPrint('🔒 Pan constraints cleared - back to sliding window');
  }

  /// Updates the element generator function.
  ///
  /// Only regenerates elements if the version number has changed.
  /// This prevents unnecessary regeneration when parent widgets rebuild
  /// without actual data/theme changes.
  void setElementGenerator(ElementGenerator? generator, int version) {
    // [DEBUG OUTPUT REMOVED] Element generator updates - fire on data changes

    // Only update if version changed (indicates real data/theme change)
    if (_elementGeneratorVersion == version && _elementGenerator != null) {
      // [DEBUG OUTPUT REMOVED] Version unchanged - fires frequently
      return;
    }

    _elementGenerator = generator;
    _elementGeneratorVersion = version;

    // Regenerate elements with new generator if we have a transform
    if (_transform != null && _elementGenerator != null) {
      // [DEBUG OUTPUT REMOVED] Regenerating elements - fires on data updates
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

    // Update original transform to include expanded data range
    _originalTransform = ChartTransform(
      plotWidth: _plotArea.width,
      plotHeight: _plotArea.height,
      dataXMin: dataXMin,
      dataXMax: dataXMax,
      dataYMin: dataYMin,
      dataYMax: dataYMax,
      invertY: _originalTransform!.invertY,
    );

    // Also update current transform so viewport shows the new data
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

    final originalXRange = _originalTransform!.dataXMax - _originalTransform!.dataXMin;
    final originalYRange = _originalTransform!.dataYMax - _originalTransform!.dataYMin;

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

    // [DEBUG OUTPUT REMOVED] Zoom clamped - fires frequently during zoom operations

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
    final clampedDataXMin = tentativeDataXMin.clamp(minAllowedDataXMin, maxAllowedDataXMin);
    final clampedDataYMin = tentativeDataYMin.clamp(minAllowedDataYMin, maxAllowedDataYMin);

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
    if (!hasSize || _plotArea.isEmpty) return;

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

    // Calculate plot area (reserve space for axes)
    // Default margins if no axes
    double leftMargin = 10;
    const double rightMargin = 10;
    const double topMargin = 10;
    double bottomMargin = 10;

    // Reserve space for Y-axis (left side)
    if (_yAxis != null) {
      leftMargin = 60; // Space for Y-axis labels + axis label + padding
    }

    // Reserve space for X-axis (bottom)
    if (_xAxis != null) {
      bottomMargin = 50; // Space for X-axis labels + axis label + padding
    }

    // Calculate plot area
    _plotArea = Rect.fromLTRB(leftMargin, topMargin, size.width - rightMargin, size.height - bottomMargin);

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
        _originalTransform = _transform;
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

    // [DEBUG OUTPUT REMOVED] Pointer down - fires on every mouse click
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
      // Middle-click: EXCLUSIVELY pan (per scenario 6)
      // [DEBUG OUTPUT REMOVED] Middle button down - fires on user interaction
      coordinator.claimMode(InteractionMode.panning);
      // Store initial pan position in widget space
      _lastPanPosition = position;
      // [DEBUG OUTPUT REMOVED] Pan mode claimed - fires on user interaction
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

    // Clear resize state
    if (_resizingAnnotation != null) {
      _resizingAnnotation!.clearTempBounds(); // Clear temporary resize bounds
    }
    _activeResizeDirection = null;
    _resizingAnnotation = null;
    _resizeStartBounds = null;

    // Clear pan state and regenerate elements if we were panning
    // (Elements were not regenerated during drag for performance)
    final wasPanning = coordinator.currentMode == InteractionMode.panning;
    _lastPanPosition = null;
    if (wasPanning && _elementGenerator != null) {
      // Update axes after panning completes
      _updateAxesFromTransform();

      _rebuildElementsWithTransform();

      // Invalidate cache - transform changed from panning
      _seriesCacheDirty = true;

      // [DEBUG OUTPUT REMOVED] Pan ended - fires on user interaction
    }

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

    // Always update crosshair immediately for smooth 60fps tracking
    markNeedsPaint();

    // Per conflict resolution scenario 7: Hover is passive
    // Per scenario 12: Hover/tooltips suspended during panning
    if (coordinator.isPanning) {
      coordinator.setHoveredElement(null);
      onCursorChange?.call(SystemMouseCursors.basic);
      return;
    }

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

    // [DEBUG OUTPUT REMOVED] Hit test - fires frequently on mouse movement

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

    // Draw crosshair at cursor position (in widget space)
    final cursorPos = _cursorPosition;
    if (cursorPos != null) {
      // [DEBUG OUTPUT REMOVED] Crosshair drawing - was firing at 60fps on mouse move
      final crosshairPaint = Paint()
        ..color = const Color(0x80666666) // Semi-transparent gray
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      // Horizontal line across entire widget
      canvas.drawLine(Offset(0, cursorPos.dy), Offset(size.width, cursorPos.dy), crosshairPaint);

      // Vertical line across entire widget
      canvas.drawLine(Offset(cursorPos.dx, 0), Offset(cursorPos.dx, size.height), crosshairPaint);

      // Draw coordinate labels (showing both screen and data coordinates)
      _drawCrosshairLabels(canvas, size, cursorPos);
    }

    // Draw tooltip for hovered element (if any)
    // Show tooltips for datapoints or series (with nearest point lookup)
    final hoveredElement = coordinator.hoveredElement;
    if (_tooltipsEnabled &&
        hoveredElement != null &&
        !coordinator.isPanning &&
        (hoveredElement.elementType == ChartElementType.datapoint || hoveredElement.elementType == ChartElementType.series) &&
        _cursorPosition != null) {
      _drawTooltip(canvas, size, hoveredElement, _cursorPosition!);
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

    canvas.restore(); // Final restore (removes initial offset translation)
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
  void _drawTooltip(Canvas canvas, Size size, ChartElement element, Offset cursorPosition) {
    // For series elements, find nearest datapoint to cursor
    Offset tooltipAnchor = plotToWidget(element.bounds.center);
    String tooltipText;

    if (element.elementType == ChartElementType.series && element is SeriesElement) {
      // Convert cursor to plot space
      final plotCursor = widgetToPlot(cursorPosition);

      // Get series datapoints and transform them to plot space
      final dataPoints = element.series.points;
      if (dataPoints.isEmpty || _transform == null) {
        tooltipText = element.series.name ?? 'Series: ${element.id}';
      } else {
        // Find closest datapoint to cursor
        var minDist = double.infinity;
        var closestDataPoint = dataPoints.first;
        Offset closestPlotPoint = _transform!.dataToPlot(closestDataPoint.x, closestDataPoint.y);

        for (final dataPoint in dataPoints) {
          final plotPoint = _transform!.dataToPlot(dataPoint.x, dataPoint.y);
          final dist = (plotPoint.dx - plotCursor.dx).abs() + (plotPoint.dy - plotCursor.dy).abs();
          if (dist < minDist) {
            minDist = dist;
            closestDataPoint = dataPoint;
            closestPlotPoint = plotPoint;
          }
        }

        // Show tooltip with nearest datapoint's coordinates
        tooltipText = '${element.series.name ?? element.id}\nX: ${_formatDataValue(closestDataPoint.x)}\nY: ${_formatDataValue(closestDataPoint.y)}';
        tooltipAnchor = plotToWidget(closestPlotPoint); // Position tooltip at the datapoint
      }
    } else if (element.elementType == ChartElementType.datapoint) {
      // For actual datapoint elements (if they exist)
      final center = element.bounds.center;
      if (_transform != null) {
        final dataPos = _transform!.plotToData(center.dx, center.dy);
        tooltipText = '${element.id}\nX: ${_formatDataValue(dataPos.dx)}\nY: ${_formatDataValue(dataPos.dy)}';
      } else {
        tooltipText = element.id;
      }
      tooltipAnchor = plotToWidget(center);
    } else {
      // Fallback for other elements
      tooltipText = '${element.elementType.name}: ${element.id}';
      tooltipAnchor = plotToWidget(element.bounds.center);
    }

    // Create text painter
    const textStyle = TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: tooltipText, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    // Calculate tooltip size with padding
    const padding = 8.0;
    final tooltipWidth = textPainter.width + padding * 2;
    final tooltipHeight = textPainter.height + padding * 2;

    // Smart positioning: Position above datapoint anchor, but flip if it would clip top
    var tooltipX = tooltipAnchor.dx - tooltipWidth / 2;
    var tooltipY = tooltipAnchor.dy - tooltipHeight - 12;

    // Avoid clipping left/right edges
    if (tooltipX < 10) {
      tooltipX = 10;
    } else if (tooltipX + tooltipWidth > size.width - 10) {
      tooltipX = size.width - tooltipWidth - 10;
    }

    // Flip to below if it would clip top
    if (tooltipY < 10) {
      tooltipY = tooltipAnchor.dy + 12;
    }

    // Draw tooltip background (rounded rectangle with shadow)
    final tooltipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
      const Radius.circular(4),
    );

    // Draw shadow
    canvas.drawRRect(
      tooltipRect.shift(const Offset(0, 2)),
      Paint()
        ..color = const Color(0x40000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Draw background
    canvas.drawRRect(
      tooltipRect,
      Paint()..color = const Color(0xE0000000), // Semi-transparent black
    );

    // Draw text
    textPainter.paint(canvas, Offset(tooltipX + padding, tooltipY + padding));
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
