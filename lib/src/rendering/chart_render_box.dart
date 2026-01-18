// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../axis/axis.dart' as chart_axis;
import '../coordinates/chart_transform.dart';
import '../elements/annotation_elements.dart';
import '../elements/resize_handle_element.dart';
import '../elements/series_element.dart';
import '../elements/simulated_annotation.dart';
import '../interaction/core/chart_element.dart';
import '../interaction/core/coordinator.dart';
import '../interaction/core/element_types.dart';
import '../interaction/core/interaction_mode.dart';
import '../models/chart_annotation.dart';
import '../models/chart_series.dart';
import '../models/chart_theme.dart';
import '../models/interaction_config.dart';
import '../models/normalization_mode.dart';
import '../models/series_axis_binding.dart';
import '../models/x_axis_config.dart';
import '../models/y_axis_config.dart';
import '../streaming/streaming_buffer.dart';
import '../theming/components/scrollbar_config.dart';
import 'grid_renderer.dart';
import 'modules/annotation_drag_handler.dart';
import 'modules/crosshair_renderer.dart';
import 'modules/event_handler_manager.dart';
import 'modules/multi_axis_manager.dart';
import 'modules/scrollbar_manager.dart';
import 'modules/series_cache_manager.dart';
import 'modules/streaming_manager.dart';
import 'modules/tooltip_animator.dart';
import 'modules/tooltip_renderer.dart';
import 'modules/viewport_constraints.dart';
import 'modules/zoom_animator.dart';
import 'multi_axis_painter.dart';
import 'spatial_index.dart';
import 'x_axis_painter.dart';

/// Callback for generating chart elements based on current transform.
/// Used for zoom/pan to regenerate elements from original data coordinates.
typedef ElementGenerator = List<ChartElement> Function(
    ChartTransform transform);

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
    NormalizationMode? normalizationMode,
    List<ChartSeries>? series,
    this.onElementClick,
    this.onElementHover,
    this.onEmptyAreaClick,
    this.onCursorChange,
    this.onAnnotationChanged,
    this.onRangeCreationComplete,
  })  : _elementGenerator = elementGenerator,
        _theme = theme,
        _tooltipsEnabled = tooltipsEnabled,
        _interactionConfig = interactionConfig,
        assert((elements != null) != (elementGenerator != null),
            'Must provide either elements or elementGenerator, but not both') {
    _elements = elements ?? [];
    _tooltipAnimator = TooltipAnimator(onRepaint: markNeedsPaint);
    _zoomAnimator = ZoomAnimator(
      onUpdate: _onZoomAnimationUpdate,
      onComplete: _onZoomAnimationComplete,
    );
    _initScrollbarManager(showXScrollbar, showYScrollbar, scrollbarTheme);
    _initStreamingManager();
    _initAnnotationDragHandler();
    _initEventHandlerManager();
    _initMultiAxisManager(normalizationMode, series);
  }

  /// Initializes the MultiAxisManager with normalization mode and series.
  void _initMultiAxisManager(
      NormalizationMode? normalizationMode, List<ChartSeries>? series) {
    _multiAxisManager.setNormalizationMode(normalizationMode);
    _multiAxisManager.setSeries(series);
  }

  /// Initializes the ScrollbarManager with a delegate that references this RenderBox.
  void _initScrollbarManager(bool showXScrollbar, bool showYScrollbar,
      ScrollbarConfig? scrollbarTheme) {
    _scrollbarManager = ScrollbarManager(
      delegate: _ScrollbarDelegateImpl(this),
      showXScrollbar: showXScrollbar,
      showYScrollbar: showYScrollbar,
      scrollbarTheme: scrollbarTheme,
    );
  }

  /// Initializes the StreamingManager with a delegate that references this RenderBox.
  void _initStreamingManager() {
    _streamingManager = StreamingManager(
      delegate: _StreamingDelegateImpl(this),
    );
  }

  /// Initializes the AnnotationDragHandler with a delegate that references this RenderBox.
  void _initAnnotationDragHandler() {
    _annotationDragHandler = AnnotationDragHandler(
      delegate: _AnnotationDragDelegateImpl(this),
    );
  }

  /// Initializes the EventHandlerManager with a delegate that references this RenderBox.
  void _initEventHandlerManager() {
    _eventHandlerManager = EventHandlerManager(
      delegate: _EventHandlerDelegateImpl(this),
    );
  }

  /// Scrollbar manager handling all scrollbar state and interactions.
  late final ScrollbarManager _scrollbarManager;

  /// Streaming manager handling real-time data buffering and viewport auto-scroll.
  late final StreamingManager _streamingManager;

  /// Annotation drag handler managing resize/move operations for all annotation types.
  late final AnnotationDragHandler _annotationDragHandler;

  /// Event handler manager handling all pointer events and annotation drags.
  late final EventHandlerManager _eventHandlerManager;

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

  // ==================== MULTI-AXIS MODULE ====================

  /// Multi-axis manager module.
  ///
  /// Manages all multi-axis configuration and rendering:
  /// - Effective Y-axis configuration resolution (with caching)
  /// - Series-to-axis binding resolution (with caching)
  /// - Viewport-aware bounds computation
  /// - Axis width calculation
  /// - Multi-axis painting coordination
  final MultiAxisManager _multiAxisManager = MultiAxisManager();

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
  final void Function(String annotationId, ChartAnnotation updatedAnnotation)?
      onAnnotationChanged;

  /// Callback for range annotation creation completion.
  ///
  /// Called when user completes drag in rangeAnnotationCreation mode.
  /// Provides data coordinates of dragged rectangle (startX, endX, startY, endY).
  final void Function(double startX, double endX, double startY, double endY)?
      onRangeCreationComplete;

  // ==================== EVENT STATE (delegated to EventHandlerManager) ====================
  // Resize, move, potential drag state, cursor position, pan position, hit test throttling
  // are now managed by EventHandlerManager module.

  /// Whether tooltips are enabled.
  bool _tooltipsEnabled;

  /// Manages tooltip show/hide animations with configurable delays.
  ///
  /// Handles timing and opacity animation for tooltips:
  /// - Show delay: Wait before displaying tooltip on hover
  /// - Hide delay: Wait before hiding tooltip when moving away
  /// - Fade animation: Smooth opacity transitions
  late final TooltipAnimator _tooltipAnimator;

  /// Whether tooltip rendering has been pre-warmed.
  ///
  /// Pre-warming eliminates the first-render latency by forcing font loading
  /// and shader compilation during chart initialization rather than on first hover.
  bool _tooltipPrewarmed = false;

  /// Manages smooth zoom animations with easing.
  ///
  /// Provides natural transitions when zooming via:
  /// - Keyboard shortcuts (+/-/numpad)
  /// - Mouse wheel + Shift modifier
  late final ZoomAnimator _zoomAnimator;

  /// Interaction configuration for controlling enabled interactions.
  InteractionConfig? _interactionConfig;

  /// X-axis for the chart (optional).
  chart_axis.Axis? _xAxis;

  /// Y-axis for the chart (optional).
  chart_axis.Axis? _yAxis;

  /// Primary Y-axis configuration from the widget (NEW multi-axis YAxisConfig type).
  ///
  /// This is passed to [MultiAxisManager.getEffectiveYAxes] as the `primaryYAxis`
  /// parameter so the multi-axis system knows about widget-level axis configuration.
  /// This ensures:
  /// - Widget-level `showCrosshairLabel` setting is respected
  /// - No duplicate axes are created (widget-level + auto-generated)
  /// - Proper axis positioning without gaps
  YAxisConfig? _primaryYAxisConfig;

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
  // Widget-Provided Axis Bounds Tracking
  // ==========================================================================

  /// Tracks the ORIGINAL full data bounds as provided by the widget.
  ///
  /// These values are captured when a new axis is first set and represent
  /// the FULL data range from the widget (before any zoom/pan adjustments).
  /// They are used to detect whether widget-level data has actually changed
  /// vs. just an axis object recreation during annotation updates.
  ///
  /// CRITICAL: These are NOT the same as _originalTransform bounds!
  /// - _widgetProvidedX/YBounds: Always the FULL range from widget (never zoomed)
  /// - _originalTransform: Can be the zoomed range in some scenarios
  double? _widgetProvidedXMin;
  double? _widgetProvidedXMax;
  double? _widgetProvidedYMin;
  double? _widgetProvidedYMax;

  // ==========================================================================
  // Layer Separation & Picture Caching (Sprint 1)
  // ==========================================================================

  /// Manages GPU-accelerated Picture caching for series layer rendering.
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
  final SeriesCacheManager _seriesCacheManager = SeriesCacheManager();

  /// Crosshair renderer module.
  ///
  /// Handles all crosshair-related rendering:
  /// - Standard crosshair lines and coordinate labels
  /// - Per-axis crosshair labels for multi-axis mode
  /// - Tracking mode with intersection markers and tooltip
  static const CrosshairRenderer _crosshairRenderer = CrosshairRenderer();

  /// Tooltip renderer module.
  ///
  /// Handles all tooltip-related rendering:
  /// - Smart positioning to avoid clipping at canvas edges
  /// - Arrow pointer pointing to data marker
  /// - Styling with background, border, shadow, and opacity animation
  static const TooltipRenderer _tooltipRenderer = TooltipRenderer();

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

  /// Viewport constraint calculator for zoom/pan limits.
  /// Enforces min/max zoom levels and pan whitespace limits.
  static const ViewportConstraints _viewportConstraints = ViewportConstraints();

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
    _seriesCacheManager.dispose();
    _tooltipAnimator.dispose();
    _zoomAnimator.dispose();
    _scrollbarManager.dispose();
    _streamingManager.dispose();
    _annotationDragHandler.dispose();
    _eventHandlerManager.dispose();
    super.dispose();
  }

  /// Updates the list of chart elements.
  ///
  /// Rebuilds the spatial index with new elements.
  /// Invalidates series cache since data has changed.
  /// Preserves selection state by matching elements by ID.
  void updateElements(List<ChartElement> elements) {
    if (elements == _elements) return;

    // Preserve selection state: get IDs of currently selected elements
    final selectedIds = coordinator.selectedElements.map((e) => e.id).toSet();

    // Replace elements
    _elements = elements;
    _seriesCacheManager.invalidate(); // Invalidate cache - data changed

    // Restore selection state on new elements that match by ID
    if (selectedIds.isNotEmpty) {
      // Clear old selection (references to old elements)
      coordinator.clearSelection();

      // Re-select new elements that match the old selection by ID
      for (final element in _elements) {
        if (selectedIds.contains(element.id)) {
          coordinator.addToSelection({element});
        }
      }
    }

    _rebuildSpatialIndex();
    markNeedsPaint();
  }

  /// Sets the X-axis for the chart.
  ///
  /// Triggers layout and paint when axis is changed.
  /// If transform exists (zoomed/panned state), syncs new axis with current viewport.
  void setXAxis(chart_axis.Axis? axis) {
    // Compare by data bounds, not reference - axis objects are recreated on each rebuild
    // but we only need to update if the actual data range changed
    if (_xAxis == axis) {
      return;
    }

    // Check if the NEW axis bounds match the WIDGET-PROVIDED full data range.
    // This is crucial for preserving zoom/pan during annotation updates:
    // - When zoomed, _xAxis.dataMin/Max reflect the zoomed viewport (e.g., 5-15)
    // - When widget rebuilds, new axis has FULL data range (e.g., 0-100)
    // - We track the ORIGINAL widget-provided bounds separately from _originalTransform
    //   because _originalTransform can get updated during zoom/pan operations
    final boundsMatchWidgetProvided = _widgetProvidedXMin != null &&
        _widgetProvidedXMax != null &&
        axis != null &&
        _widgetProvidedXMin == axis.dataMin &&
        _widgetProvidedXMax == axis.dataMax;

    _xAxis = axis;

    // Skip transform updates if new bounds match widget-provided - preserves zoom/pan state
    // during annotation-only updates (where data bounds don't actually change)
    if (boundsMatchWidgetProvided && _transform != null) {
      // CRITICAL: The new axis has FULL data range ticks, but we're zoomed.
      // We must sync the new axis to the current zoomed viewport so tick labels
      // reflect the zoomed range, not the full range.
      _xAxis!.updateDataRange(_transform!.dataXMin, _transform!.dataXMax);
      _seriesCacheManager.invalidate();
      markNeedsLayout();
      return;
    }

    // Track the widget-provided bounds for future comparisons
    if (axis != null) {
      _widgetProvidedXMin = axis.dataMin;
      _widgetProvidedXMax = axis.dataMax;
    }

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
      _seriesCacheManager.invalidate();
    }

    markNeedsLayout();
  }

  /// Sets the Y-axis for the chart.
  ///
  /// Triggers layout and paint when axis is changed.
  /// If transform exists (zoomed/panned state), syncs new axis with current viewport.
  void setYAxis(chart_axis.Axis? axis) {
    // Compare by data bounds, not reference - axis objects are recreated on each rebuild
    // but we only need to update if the actual data range changed
    if (_yAxis == axis) {
      return;
    }

    // Check if widget-provided bounds have actually changed
    // This compares the NEW axis bounds against the LAST widget-provided bounds
    // (not the zoomed axis bounds, not _originalTransform which has complex lifecycle)
    //
    // Why this approach works:
    // - _originalTransform gets updated during pan constraint calculations, chart switches, etc.
    // - After first annotation drag, _originalTransform may contain ZOOMED range, not original
    // - Widget-provided bounds are stable: always the FULL data range from the widget
    // - This correctly detects "same data, just annotation change" vs "actual data range change"
    final boundsMatchWidgetProvided = _widgetProvidedYMin != null &&
        _widgetProvidedYMax != null &&
        axis != null &&
        _widgetProvidedYMin == axis.dataMin &&
        _widgetProvidedYMax == axis.dataMax;

    _yAxis = axis;

    // Skip transform updates if widget-provided bounds haven't changed
    // This preserves zoom/pan state during annotation-only updates
    if (boundsMatchWidgetProvided && _transform != null) {
      // CRITICAL: The new axis has FULL data range ticks, but we're zoomed.
      // We must sync the new axis to the current zoomed viewport so tick labels
      // reflect the zoomed range, not the full range.
      // Note: We call updateDataRange directly on the new axis object, not via
      // _updateAxesFromTransform(), because that method uses _lastXMin/_lastYMin
      // tracking which may skip the update if values haven't changed (but we have
      // a NEW axis object that needs its ticks regenerated for the zoomed range).
      _yAxis!.updateDataRange(_transform!.dataYMin, _transform!.dataYMax);
      _seriesCacheManager.invalidate();
      markNeedsLayout();
      return;
    }

    // Track the widget-provided bounds for future comparisons
    if (axis != null) {
      _widgetProvidedYMin = axis.dataMin;
      _widgetProvidedYMax = axis.dataMax;
    }

    // Update both transforms to show the new data range (for streaming/dynamic data)
    // CRITICAL: Update _originalTransform too, so pan constraints are calculated from correct bounds
    if (_transform != null && axis != null) {
      // CRITICAL FIX: Detect if this is a chart type switch (complete data range change)
      // vs a streaming update (incremental data range change).
      // If the new axis bounds don't overlap with the original transform bounds,
      // this indicates switching to a different chart/dataset - reset transforms completely.
      final originalYMin = _originalTransform?.dataYMin ?? _transform!.dataYMin;
      final originalYMax = _originalTransform?.dataYMax ?? _transform!.dataYMax;
      final newYMin = axis.dataMin;
      final newYMax = axis.dataMax;

      // Check for range overlap: if ranges don't overlap at all, it's a chart switch
      final rangesOverlap = newYMin <= originalYMax && newYMax >= originalYMin;

      // Also detect normalized range switch (0-1 bounds indicate multi-axis normalization)
      final isNormalizedRange = (newYMin == 0.0 && newYMax == 1.0);
      final wasNormalizedRange = (originalYMin == 0.0 && originalYMax == 1.0);
      final normalizationChanged = isNormalizedRange != wasNormalizedRange;

      if (!rangesOverlap || normalizationChanged) {
        // Chart type switch detected - reset transforms to use new bounds
        _transform = null;
        _originalTransform = null;
        // Let performLayout() recreate transforms with new bounds
      } else {
        _transform = _transform!.copyWith(
          dataYMin: axis.dataMin,
          dataYMax: axis.dataMax,
        );

        // DO NOT update _originalTransform here - it must stay frozen at initial data range
        // for scrollbar handle sizing to work correctly. Updating it causes the handle
        // to always show full size because dataSpan == viewportSpan after update.

        // Invalidate series cache - viewport changed, need to regenerate Picture
        _seriesCacheManager.invalidate();
      }
    }

    markNeedsLayout();
  }

  /// Sets the primary Y-axis configuration from the widget.
  ///
  /// This is the NEW [YAxisConfig] type from the multi-axis system, NOT the legacy
  /// [chart_axis.Axis] type. It's passed to [MultiAxisManager] so the multi-axis
  /// system respects widget-level axis configuration (e.g., color, showCrosshairLabel,
  /// padding, position).
  void setPrimaryYAxisConfig(YAxisConfig? config) {
    if (_primaryYAxisConfig == config) return;
    _primaryYAxisConfig = config;
    _multiAxisManager.setPrimaryYAxisConfig(config);
    markNeedsLayout();
  }

  /// Sets the theme for the chart.
  ///
  /// Updates colors for background, grid, axes, etc.
  /// Invalidates series cache since visual appearance changed.
  void setTheme(ChartTheme? theme) {
    if (_theme == theme) return;
    _theme = theme;
    _seriesCacheManager.invalidate(); // Invalidate cache - theme changed
    markNeedsPaint();
  }

  /// Updates tooltip visibility.
  void setTooltipsEnabled(bool enabled) {
    if (_tooltipsEnabled == enabled) return;
    _tooltipsEnabled = enabled;
    markNeedsPaint();
  }

  /// Updates interaction configuration.
  void setInteractionConfig(InteractionConfig? config) {
    if (_interactionConfig == config) return;
    _interactionConfig = config;
    markNeedsPaint();
  }

  // ==================== MULTI-AXIS SETTERS ====================

  /// Sets the normalization mode for multi-axis charts.
  ///
  /// Delegates to [MultiAxisManager.setNormalizationMode].
  void setNormalizationMode(NormalizationMode? mode) {
    if (_multiAxisManager.setNormalizationMode(mode)) {
      markNeedsPaint();
    }
  }

  /// Sets the data series for multi-axis color resolution.
  ///
  /// Delegates to [MultiAxisManager.setSeries].
  void setSeries(List<ChartSeries>? series) {
    if (_multiAxisManager.setSeries(series)) {
      markNeedsPaint();
    }
  }

  // ==================== MULTI-AXIS HELPERS (DELEGATING) ====================

  /// Gets effective Y-axes from inline yAxisConfig on series.
  ///
  /// Delegates to [MultiAxisManager.getEffectiveYAxes].
  /// Passes [_primaryYAxisConfig] so widget-level axis config is respected.
  List<YAxisConfig> _getEffectiveYAxes() {
    return _multiAxisManager.getEffectiveYAxes(
        primaryYAxis: _primaryYAxisConfig);
  }

  /// Paints multiple Y-axes using [MultiAxisPainter].
  ///
  /// Delegates to [MultiAxisManager.paintMultipleYAxes].
  void _paintMultipleYAxes(Canvas canvas) {
    _multiAxisManager.paintMultipleYAxes(
      canvas: canvas,
      size: size,
      plotArea: _plotArea,
      transform: _transform,
      originalTransform: _originalTransform,
    );
  }

  /// Computes axis bounds from series data for multi-axis rendering.
  ///
  /// Delegates to [MultiAxisManager.computeAxisBounds].
  ///
  /// [forceFullBounds]: If true, returns full data bounds without viewport
  /// transformation. Use this for series painting transforms.
  Map<String, DataRange> _computeAxisBounds({bool forceFullBounds = false}) {
    return _multiAxisManager.computeAxisBounds(
      transform: _transform,
      originalTransform: _originalTransform,
      forceFullBounds: forceFullBounds,
    );
  }

  /// Gets effective axis bindings by deriving bindings from series properties.
  ///
  /// Delegates to [MultiAxisManager.getEffectiveBindings].
  List<SeriesAxisBinding> _getEffectiveBindings() {
    return _multiAxisManager.getEffectiveBindings();
  }

  /// Builds MultiAxisInfo for the CrosshairRenderer module.
  ///
  /// Delegates to [MultiAxisManager.buildMultiAxisInfo].
  MultiAxisInfo _buildMultiAxisInfo() {
    return _multiAxisManager.buildMultiAxisInfo(
      transform: _transform,
      originalTransform: _originalTransform,
    );
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
  void setPanConstraintBounds(
      double xMin, double xMax, double yMin, double yMax) {
    if (_transform == null) {
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
      _seriesCacheManager.invalidate();
    }
  }

  /// Programmatically zoom the chart with smooth animation.
  ///
  /// **Parameters**:
  /// - `factor`: Zoom factor (> 1.0 = zoom in, < 1.0 = zoom out)
  /// - `plotCenter`: Center point in plot space (if null, uses plot center)
  /// - `animate`: Whether to animate the zoom (default: true)
  ///
  /// Only works when using elementGenerator (for element regeneration).
  void zoomChart(double factor, {Offset? plotCenter, bool animate = true}) {
    // [DEBUG OUTPUT REMOVED] Zoom chart calls - fire on user interaction

    if (_transform == null ||
        _elementGenerator == null ||
        _originalTransform == null) {
      // [DEBUG OUTPUT REMOVED] Cannot zoom warning - rare error case
      return;
    }

    // Use plot center if not specified
    final center =
        plotCenter ?? Offset(_plotArea.width / 2, _plotArea.height / 2);

    // Apply zoom tentatively
    final tentativeTransform = _transform!.zoom(factor, center);

    // Clamp zoom to min/max levels
    final targetTransform = _clampZoomLevel(tentativeTransform);

    if (animate) {
      // Animate to target transform
      _zoomAnimator.animateTo(_transform!, targetTransform);
    } else {
      // Apply immediately without animation
      _applyZoomTransform(targetTransform);
      _onZoomAnimationComplete();
    }
  }

  /// Callback invoked on each frame of zoom animation.
  void _onZoomAnimationUpdate(ChartTransform transform) {
    _transform = transform;
    _updateAxesFromTransform();
    _scrollbarManager.showScrollbarsAndScheduleHide();
    markNeedsPaint();
  }

  /// Callback invoked when zoom animation completes.
  void _onZoomAnimationComplete() {
    // Regenerate elements at final transform
    _rebuildElementsWithTransform();

    // Invalidate cache - transform changed
    _seriesCacheManager.invalidate();
  }

  /// Applies a zoom transform directly (used during animation and immediate mode).
  void _applyZoomTransform(ChartTransform transform) {
    _transform = transform;
    _updateAxesFromTransform();
    _scrollbarManager.showScrollbarsAndScheduleHide();
    markNeedsPaint();
  }

  /// Programmatically pan the chart.
  ///
  /// **Parameters**:
  /// - `plotDx`, `plotDy`: Pan delta in plot pixels
  ///
  /// Only works when using elementGenerator (for element regeneration).
  void panChart(double plotDx, double plotDy) {
    // [DEBUG OUTPUT REMOVED] Pan chart calls - fire frequently during dragging

    if (_transform == null ||
        _elementGenerator == null ||
        _originalTransform == null) {
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
    _scrollbarManager.showScrollbarsAndScheduleHide();

    // Mark for repaint (will paint existing elements with new transform)
    markNeedsPaint();

    // [DEBUG OUTPUT REMOVED] Pan constrained/applied - fires frequently during dragging
  }

  /// Reset view to original zoom/pan state.
  void resetView() {
    if (_originalTransform == null || _elementGenerator == null) {
      return;
    }

    // Restore original data ranges, preserve current plot dimensions
    _transform = _originalTransform!
        .copyWith(plotWidth: _plotArea.width, plotHeight: _plotArea.height);

    // Update axes to reflect reset viewport
    _updateAxesFromTransform();

    // Regenerate elements
    _rebuildElementsWithTransform();

    // Invalidate cache - transform reset to original
    _seriesCacheManager.invalidate();
  }

  /// Updates the data bounds for streaming data that extends beyond original range.
  ///
  /// Called when streaming data expands the data range, allowing pan constraints
  /// to permit panning to the new data regions.
  void updateDataBounds(
      double dataXMin, double dataXMax, double dataYMin, double dataYMax) {
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
    _seriesCacheManager.invalidate();
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
  /// Delegates to ViewportConstraints module for the actual calculation.
  /// Handles null checks and pan constraint transform selection.
  ChartTransform _clampZoomLevel(ChartTransform transform) {
    if (_originalTransform == null) return transform;

    // Use pan constraint transform if set (paused streaming with full dataset),
    // otherwise use original transform (normal mode or active streaming with sliding window)
    final zoomBaseTransform = _panConstraintTransform ?? _originalTransform!;

    return _viewportConstraints.clampZoomLevel(
      transform: transform,
      baseTransform: zoomBaseTransform,
    );
  }

  /// Clamps pan delta to enforce viewport bounds (limit whitespace).
  ///
  /// Delegates to ViewportConstraints module for the actual calculation.
  /// Handles null checks and pan constraint transform selection.
  (double, double) _clampPanDelta(
      double requestedPlotDx, double requestedPlotDy) {
    if (_originalTransform == null || _transform == null) {
      return (requestedPlotDx, requestedPlotDy);
    }

    // Use pan constraint transform if set (paused streaming mode with full dataset bounds),
    // otherwise use original transform (normal streaming mode with sliding window bounds)
    final constraintTransform = _panConstraintTransform ?? _originalTransform!;

    final result = _viewportConstraints.clampPanDelta(
      requestedPlotDx: requestedPlotDx,
      requestedPlotDy: requestedPlotDy,
      currentTransform: _transform!,
      constraintTransform: constraintTransform,
    );

    return (result.dx, result.dy);
  }

  // ============================================================================
  // Live Streaming Support (delegated to StreamingManager)
  // ============================================================================

  /// Sets streaming data for a specific series.
  ///
  /// Called by LiveStreamController on each frame to update the chart
  /// with new streaming data. This bypasses widget rebuild entirely.
  ///
  /// **Parameters**:
  /// - [seriesId]: ID of the series to update
  /// - [buffer]: Reference to the StreamingBuffer (zero-copy!)
  ///
  /// **Performance**: O(1) for data storage, O(visible points) for rendering.
  void setStreamingData({
    required String seriesId,
    required StreamingBuffer buffer,
    bool expandViewportWhenNotAutoScrolling = false,
    int maxVisiblePoints = 10000,
  }) {
    _streamingManager.setStreamingData(
      seriesId: seriesId,
      buffer: buffer,
      expandViewportWhenNotAutoScrolling: expandViewportWhenNotAutoScrolling,
      maxVisiblePoints: maxVisiblePoints,
    );
  }

  /// Clears streaming data for a specific series.
  ///
  /// Called by LiveStreamController when clear() is invoked.
  void clearStreamingData(String seriesId) {
    _streamingManager.clearStreamingData(seriesId);
  }

  /// Locks the viewport for pause mode.
  ///
  /// When locked:
  /// - Auto-scroll is disabled
  /// - Pan constraints use full data bounds
  /// - User can explore historical data
  void lockViewportForPause() {
    _streamingManager.lockViewportForPause();
  }

  /// Unlocks the viewport after pause mode.
  ///
  /// Clears pan constraints and allows auto-scroll to resume.
  void unlockViewportForResume() {
    _streamingManager.unlockViewportForResume();
  }

  /// Snaps the viewport to show the latest streaming data.
  ///
  /// Called by LiveStreamController when autoScroll is enabled.
  /// Calculates the viewport position to show the latest data with margin.
  /// Uses smooth interpolation to avoid visual stuttering.
  ///
  /// **Parameters**:
  /// - [marginPercent]: Percentage of visible width to keep as margin on right
  /// - [viewportDataPoints]: Number of data points to show in viewport. If null,
  ///   shows all accumulated data (viewport expands as buffer fills).
  void snapViewportToStreamingData({
    double marginPercent = 5.0,
    int? viewportDataPoints,
  }) {
    _streamingManager.snapViewportToStreamingData(
      marginPercent: marginPercent,
      viewportDataPoints: viewportDataPoints,
    );
  }

  // ============================================================================
  // Coordinate Space Conversion (Widget ↔ Plot)
  // ============================================================================

  /// Converts widget coordinates to plot coordinates.
  ///
  /// Widget coordinates include axis areas, plot coordinates are relative
  /// to the plot area (0,0 at top-left of plot area).
  Offset widgetToPlot(Offset widgetPosition) {
    return Offset(
        widgetPosition.dx - _plotArea.left, widgetPosition.dy - _plotArea.top);
  }

  /// Converts plot coordinates to widget coordinates.
  ///
  /// Inverse of widgetToPlot().
  Offset plotToWidget(Offset plotPosition) {
    return Offset(
        plotPosition.dx + _plotArea.left, plotPosition.dy + _plotArea.top);
  }

  /// Rebuilds the QuadTree spatial index from current elements.
  ///
  /// QuadTree operates in PLOT space (0,0 → plotWidth,plotHeight).
  void _rebuildSpatialIndex() {
    if (!hasSize || _plotArea.isEmpty) {
      return;
    }

    // QuadTree bounds = plot area (in plot space, not widget space)
    _spatialIndex = QuadTree(
        bounds: Offset.zero & _plotArea.size,
        maxElementsPerNode: 4,
        maxDepth: 8);

    // First, filter out any existing resize handles from _elements
    // (handles are generated dynamically, not persisted)
    _elements = _elements.where((e) => e is! ResizeHandleElement).toList();

    // Collect all elements to insert, including generated sub-elements
    final allElements = <ChartElement>[];
    final generatedHandles = <ResizeHandleElement>[];

    // Insert all chart elements
    for (final element in _elements) {
      allElements.add(element);

      // For resizable annotations, also insert their resize handle elements
      // ONLY if the annotation is currently resizable (typically when selected)
      if (element is ResizableElement && element.isResizable) {
        final handleElements =
            element.createResizeHandleElements().cast<ResizeHandleElement>();
        allElements.addAll(handleElements);
        generatedHandles.addAll(handleElements);
      }
      // Legacy support for SimulatedAnnotation (test class)
      else if (element is SimulatedAnnotation && element.isResizable) {
        final handleElements =
            element.createResizeHandleElements().cast<ResizeHandleElement>();
        allElements.addAll(handleElements);
        generatedHandles.addAll(handleElements);
      }
    }

    // Insert all collected elements into spatial index
    for (final element in allElements) {
      _spatialIndex!.insert(element);
    }

    // Update _elements to include handle elements for painting
    // CRITICAL: Only add the ResizeHandleElements we generated, not arbitrary elements.
    // Previous bug used allElements.skip(_elements.length) which incorrectly included
    // annotation elements when handles were interleaved in allElements.
    _elements = [..._elements, ...generatedHandles];
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

    // Preserve selection state: get IDs of currently selected elements
    final selectedIds = coordinator.selectedElements.map((e) => e.id).toSet();

    // Generate new elements using current transform
    _elements = generator(transform);

    // Restore selection state on new elements that match by ID
    if (selectedIds.isNotEmpty) {
      // Clear old selection (references to old elements)
      coordinator.clearSelection();

      // Re-select new elements that match the old selection by ID
      for (final element in _elements) {
        if (selectedIds.contains(element.id)) {
          coordinator.addToSelection({element});
        }
      }
    }

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
          : Size(constraints.hasBoundedWidth ? constraints.maxWidth : 800,
              constraints.hasBoundedHeight ? constraints.maxHeight : 600),
    );

    // Get scrollbar theme (use default if not provided)
    final scrollbarTheme =
        _scrollbarManager.scrollbarTheme ?? ScrollbarConfig.defaultLight;
    final scrollbarPadding = scrollbarTheme.padding;

    // Calculate space needed for scrollbars
    double rightReserved = 0;
    double bottomReserved = 0;

    if (_scrollbarManager.showYScrollbar) {
      rightReserved = scrollbarTheme.thickness + scrollbarPadding;
    }

    if (_scrollbarManager.showXScrollbar) {
      bottomReserved = scrollbarTheme.thickness +
          (scrollbarPadding * 2); // Padding above and below scrollbar
    }

    // Calculate plot area (reserve space for axes AND scrollbars)
    // Default margins if no axes
    double leftMargin = 10;
    double rightMargin = 10 + rightReserved; // Add scrollbar space
    const double topMargin = 10;
    double bottomMargin = 10 + bottomReserved; // Add scrollbar space

    // Track right axis width separately for scrollbar positioning
    double rightAxisWidth = 0;

    // Reserve space for X-axis (bottom) - only if axis is visible
    if (_xAxis != null && _xAxis!.config.showAxisLine) {
      bottomMargin = 50 +
          bottomReserved; // Space for X-axis labels + axis label + padding + scrollbar
    }

    // MULTI-AXIS: Compute axis widths using the multi-axis system for ALL Y-axes
    // This ensures consistent layout whether using single or multiple axes.
    // Previously, single-axis mode used hardcoded 60px margin which caused gaps.
    final effectiveAxes = _getEffectiveYAxes();
    if (effectiveAxes.isNotEmpty) {
      final axisBounds = _computeAxisBounds();
      final axisWidths =
          _multiAxisManager.computeAxisWidths(axisBounds: axisBounds);

      // Get total width needed for left and right axes
      final totalLeftWidth =
          _multiAxisManager.getTotalLeftAxisWidth(axisWidths);
      rightAxisWidth = _multiAxisManager.getTotalRightAxisWidth(axisWidths);

      // Use the computed axis widths directly so that the plot area aligns
      // exactly with where MultiAxisPainter draws the axis lines.
      // This prevents gaps between Y-axis lines and X-axis lines.
      leftMargin = totalLeftWidth > 0 ? totalLeftWidth : leftMargin;

      // Add right axis width to right margin (in addition to scrollbar space)
      if (rightAxisWidth > 0) {
        rightMargin = rightAxisWidth + rightReserved;
      }
    } else if (_yAxis != null && _yAxis!.config.showAxisLine) {
      // Fallback for legacy mode (no multi-axis config at all)
      leftMargin = 60; // Space for Y-axis labels + axis label + padding
    }

    // Calculate plot area (chart canvas excluding axes and scrollbars)
    _plotArea = Rect.fromLTRB(leftMargin, topMargin, size.width - rightMargin,
        size.height - bottomMargin);

    // Calculate scrollbar rectangles if enabled
    Rect? xScrollbarRect;
    Rect? yScrollbarRect;

    if (_scrollbarManager.showXScrollbar) {
      // Position horizontal scrollbar BELOW the X-axis label
      // Layout order: plot area → tick labels (~30px) → axis label (~20px) → scrollbar
      // So scrollbar should start after ~50px total
      const xAxisAndLabelHeight = 50.0; // Space for tick labels + axis label
      final scrollbarTop =
          _plotArea.bottom + xAxisAndLabelHeight + scrollbarPadding;
      xScrollbarRect = Rect.fromLTWH(
        _plotArea.left,
        scrollbarTop,
        _plotArea.width, // Match plot area width
        scrollbarTheme.thickness,
      );
    }

    if (_scrollbarManager.showYScrollbar) {
      // Position vertical scrollbar to the right of:
      // - Just the plot area (single axis mode)
      // - Plot area + right axis (multi-axis mode)
      final scrollbarLeft = _plotArea.right + rightAxisWidth + scrollbarPadding;
      yScrollbarRect = Rect.fromLTWH(
        scrollbarLeft,
        _plotArea.top,
        scrollbarTheme.thickness,
        _plotArea.height, // Match plot area height
      );
    }

    // Update scrollbar manager with calculated rects
    _scrollbarManager.setScrollbarRects(
        xRect: xScrollbarRect, yRect: yScrollbarRect);

    // Update axis pixel ranges to match plot area
    _xAxis?.updatePixelRange(_plotArea.left, _plotArea.right);
    _yAxis?.updatePixelRange(_plotArea.top, _plotArea.bottom);

    // Create/update coordinate transform
    // Transform handles Data ↔ Plot conversion based on axis data ranges
    if (_xAxis != null && _yAxis != null) {
      // Detect if data range has fundamentally changed (different chart/dataset)
      // This handles the case where Flutter reuses the same RenderBox instance
      // when switching between charts (e.g., Athletic → Test → Scientific)
      final bool rangeChanged = _originalTransform != null &&
          ((_xAxis!.dataMin - _originalTransform!.dataXMin).abs() > 10 ||
              (_xAxis!.dataMax - _originalTransform!.dataXMax).abs() > 10);

      // Create initial transform if none exists OR if data range has significantly changed
      if (_transform == null || rangeChanged) {
        // First time OR range changed: create transform from axis data ranges
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

        // Pre-warm tooltip rendering to eliminate first-hover latency
        if (!_tooltipPrewarmed) {
          prewarmTooltipRendering();
          _tooltipPrewarmed = true;
        }

        // Generate initial elements now that we have a transform
        if (_elementGenerator != null) {
          _rebuildElementsWithTransform();

          // Invalidate cache - initial element generation
          _seriesCacheManager.invalidate();
        }
      } else {
        // Subsequent layouts: preserve current data ranges (zoom/pan state),
        // only update plot dimensions if they changed
        if (_transform!.plotWidth != _plotArea.width ||
            _transform!.plotHeight != _plotArea.height) {
          _transform = _transform!.copyWith(
              plotWidth: _plotArea.width, plotHeight: _plotArea.height);
        }
      }
    }

    // Rebuild spatial index when size changes (for static elements or after transform updates)
    _rebuildSpatialIndex();

    // First render: handle scrollbar visibility based on autoHide config
    // Note: We use _scrollbarManager directly in the callback (not a captured local)
    // because the theme may be updated via setScrollbarTheme before the callback runs.
    if (!_scrollbarManager.scrollbarInitialized) {
      _scrollbarManager.markInitialized();
      // Only run once on first layout
      SchedulerBinding.instance.addPostFrameCallback((_) {
        final scrollbarConfig =
            _scrollbarManager.scrollbarTheme ?? ScrollbarConfig.defaultLight;
        if (scrollbarConfig.autoHide) {
          // Auto-hide enabled: show only if viewport is modified, then schedule hide
          final isModified = _scrollbarManager.isViewportModified();
          _scrollbarManager.setScrollbarsVisible(isModified);
          if (isModified) {
            _scrollbarManager.scheduleScrollbarAutoHide();
          }
        } else {
          // Auto-hide disabled: always show scrollbars
          _scrollbarManager.setScrollbarsVisible(true);
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

    // Return highest priority element (highest priority = painted last = on top = should receive hits)
    // Within same priority, NON-Range annotations should be hit-tested first (they're on top)
    hits.sort((a, b) {
      // First, sort by priority (higher priority = painted last = on top = should be hit first)
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;

      // Within same priority, RangeAnnotations should be hit-tested LAST (they're in back)
      final aIsRange = a is RangeAnnotationElement;
      final bIsRange = b is RangeAnnotationElement;

      if (aIsRange && !bIsRange) return 1; // b (non-Range) hit-tested first
      if (!aIsRange && bIsRange) return -1; // a (non-Range) hit-tested first

      return 0; // Equal priority and type
    });
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
    return candidates
        .where((e) =>
            e.elementType == ChartElementType.datapoint &&
            plotRect.contains(e.bounds.center))
        .toList();
  }

  // ============================================================================
  // Event Handling (delegated to EventHandlerManager)
  // ============================================================================

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    _eventHandlerManager.handleEvent(event);
  }

  // ============================================================================
  // Cache Management (Sprint 1)
  // ============================================================================

  /// Calculate hash of series data for cache validation.
  ///
  /// Computes a hash based on:
  /// - Number of series elements
  // NOTE: Series cache hash calculation, transform change detection, and cache
  // validity checking are now handled by SeriesCacheManager module.

  // ============================================================================
  // Painting
  // ============================================================================

  /// Paints all series elements onto the provided canvas.
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
  /// - canvas: Canvas to paint series elements (already clipped to plot area)
  /// - size: Size of the plot area (for element paint calls)
  void _paintSeriesLayerContent(ui.Canvas canvas, Size size) {
    // Note: Canvas is already clipped to plot area by SeriesCacheManager

    // Paint series elements only (filter out overlays, handles, etc.)
    // Series elements have priority 8, so we filter by type instead
    final seriesElements = _elements.whereType<SeriesElement>().toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    // Compute per-axis bounds for multi-axis normalization (if multi-axis mode is active)
    // Checks effective axes (including inline yAxisConfig) via MultiAxisManager
    // Use forceFullBounds=true to get the FULL data range for series painting transforms
    // (viewport transformation is only for axis labels/crosshair, not series rendering)
    final Map<String, DataRange>? axisBounds =
        (_multiAxisManager.isMultiAxisNormalizationActive())
            ? _computeAxisBounds(forceFullBounds: true)
            : null;

    // Build series-to-axis lookup for efficient transform creation (use effective bindings)
    final effectiveBindings = _getEffectiveBindings();
    final Map<String, String>? seriesToAxisMap = axisBounds != null
        ? {
            for (final binding in effectiveBindings)
              binding.seriesId: binding.yAxisId
          }
        : null;

    // Paint each series with current transform
    for (final series in seriesElements) {
      if (_transform != null) {
        // CRITICAL: Update transform before painting (enables path caching!)
        // This allows SeriesElement to cache paths and only regenerate when transform changes.

        // Multi-axis mode: Create per-series transform with axis-specific Y bounds
        if (axisBounds != null && seriesToAxisMap != null) {
          final axisId = seriesToAxisMap[series.id];
          if (axisId != null && axisBounds.containsKey(axisId)) {
            final axisRange = axisBounds[axisId]!;
            // Create transform with per-axis Y bounds for proper normalization
            final perSeriesTransform = _transform!.copyWith(
              dataYMin: axisRange.min,
              dataYMax: axisRange.max,
            );
            series.updateTransform(perSeriesTransform);
          } else {
            // Fallback: No axis binding found, use global transform
            series.updateTransform(_transform!);
          }
        } else {
          // Single-axis mode: Use global transform
          series.updateTransform(_transform!);
        }
      }
      series.paint(canvas, size);
    }

    // NOTE: Streaming elements are NOT painted here - they're painted
    // separately in _paintStreamingElements() to avoid cache thrashing.
    // Static series are cached in Picture, streaming data is painted fresh.
  }

  /// Paints streaming elements directly without caching.
  ///
  /// Streaming elements (from LiveStreamController) are painted fresh every
  /// frame to avoid cache thrashing at 60fps. This allows static series to
  /// remain in GPU-cached Picture while streaming data updates smoothly.
  ///
  /// **Performance**: Direct painting at 60fps with multi-axis transforms.
  ///
  /// **Coordinate Space**: Operates in plot space (0,0 → plotWidth, plotHeight).
  ///
  /// Parameters:
  /// - canvas: Canvas to paint streaming elements (already translated to plot space)
  /// - size: Size of the plot area
  void _paintStreamingElements(Canvas canvas, Size size) {
    if (_transform == null) return;
    _streamingManager.paint(canvas, size, _transform!);
  }

  // NOTE: Picture generation is now handled by SeriesCacheManager.generatePicture()

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
        if (!element.isSelected &&
            element.elementType == ChartElementType.datapoint) {
          // Convert plot bounds to widget bounds for preview rendering
          final plotBounds = element.bounds;
          final widgetCenter = plotToWidget(plotBounds.center);
          final radius = plotBounds.width / 2;

          // Draw dashed preview ring (different from solid selection ring)
          final interactionTheme = _theme?.interactionTheme;
          final previewPaint = Paint()
            ..color =
                (interactionTheme?.selectionColor ?? const Color(0xFF00AAFF))
                    .withValues(alpha: 0.5)
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
        final interactionTheme = _theme?.interactionTheme;
        canvas.drawRect(
          boxRect,
          Paint()
            ..color =
                interactionTheme?.selectionColor.withValues(alpha: 0.25) ??
                    const Color(0x4000AAFF)
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          boxRect,
          Paint()
            ..color =
                interactionTheme?.selectionColor ?? const Color(0xFF0088FF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }

    // Paint range annotation creation rectangle if active (Option 4 rubber-band)
    if (coordinator.currentMode == InteractionMode.rangeAnnotationCreation) {
      final boxRect = coordinator.boxSelectionRect;
      if (boxRect != null) {
        // Draw semi-transparent filled rectangle (use theme color or default blue)
        final interactionTheme = _theme?.interactionTheme;
        final rangeColor =
            interactionTheme?.crosshairColor ?? const ui.Color(0xFF448AFF);
        canvas.drawRect(
          boxRect,
          Paint()
            ..color = rangeColor.withValues(alpha: 0.15) // 15% opacity for fill
            ..style = PaintingStyle.fill,
        );

        // Draw solid border (use same theme color)
        final borderPaint = Paint()
          ..color = rangeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawRect(boxRect, borderPaint);

        // Draw coordinate labels showing data bounds
        if (_transform != null) {
          final topLeft = _transform!.plotToData(boxRect.left, boxRect.top);
          final bottomRight =
              _transform!.plotToData(boxRect.right, boxRect.bottom);

          // Calculate min/max coordinates
          final xMin =
              topLeft.dx < bottomRight.dx ? topLeft.dx : bottomRight.dx;
          final xMax =
              topLeft.dx > bottomRight.dx ? topLeft.dx : bottomRight.dx;
          final yMin =
              topLeft.dy < bottomRight.dy ? topLeft.dy : bottomRight.dy;
          final yMax =
              topLeft.dy > bottomRight.dy ? topLeft.dy : bottomRight.dy;

          // Format coordinate text
          final coordText =
              'X: [${xMin.toStringAsFixed(2)}, ${xMax.toStringAsFixed(2)}]  '
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
            tooltipOffset =
                Offset(size.width - textPainter.width - 5, tooltipOffset.dy);
          }
          if (tooltipOffset.dy + textPainter.height > size.height) {
            tooltipOffset =
                Offset(tooltipOffset.dx, boxRect.top - textPainter.height - 5);
          }

          textPainter.paint(canvas, tooltipOffset);
        }
      }
    }

    // Draw crosshair at cursor position (in widget space)
    final cursorPos = _eventHandlerManager.cursorPosition;
    final crosshairConfig =
        _interactionConfig?.crosshair ?? const CrosshairConfig();
    final crosshairEnabled = crosshairConfig.enabled;
    if (crosshairEnabled &&
        cursorPos != null &&
        _plotArea.contains(cursorPos) &&
        !coordinator.currentMode.isDragging) {
      // Only draw crosshair if cursor is inside plot area AND not dragging
      // Hide crosshair during all drag operations (datapoint, annotation, resize)

      // Build multi-axis info for crosshair rendering
      final multiAxisInfo = _buildMultiAxisInfo();

      // Create X-axis config for crosshair label styling
      final xAxisConfig = _xAxis != null
          ? XAxisConfig(
              visible: _xAxis!.config.showAxisLine,
              showAxisLine: _xAxis!.config.showAxisLine,
              showTicks: _xAxis!.config.showTickMarks,
              showCrosshairLabel: true, // Enable crosshair label by default
              color: _xAxis!.config.axisColor,
              label: _xAxis!.config.label,
            )
          : null;

      // Delegate to CrosshairRenderer module
      _crosshairRenderer.paint(
        canvas: canvas,
        size: size,
        cursorPosition: cursorPos,
        plotArea: _plotArea,
        transform: _transform!,
        theme: _theme,
        crosshairConfig: crosshairConfig,
        multiAxisInfo: multiAxisInfo,
        seriesElements: _elements.whereType<SeriesElement>().toList(),
        isRangeCreationMode:
            coordinator.currentMode == InteractionMode.rangeAnnotationCreation,
        xAxisConfig: xAxisConfig,
      );
    }

    // Draw tooltip for hovered/tapped marker (if any)
    // Show based on tooltip trigger mode configuration with animations
    if (_tooltipsEnabled && !coordinator.isPanningOrZooming) {
      final config = _interactionConfig?.tooltip ?? const TooltipConfig();
      HoveredMarkerInfo? markerToShow;

      switch (config.triggerMode) {
        case TooltipTriggerMode.hover:
          // Show tooltip only when hovering
          markerToShow = coordinator.hoveredMarker;
          break;
        case TooltipTriggerMode.tap:
          // Show tooltip only for tapped marker
          markerToShow = _eventHandlerManager.tappedMarker;
          break;
        case TooltipTriggerMode.both:
          // Show tooltip for either hover or tap (prefer tapped if both exist)
          markerToShow =
              _eventHandlerManager.tappedMarker ?? coordinator.hoveredMarker;
          break;
      }

      // Handle show/hide animations based on marker presence
      if (markerToShow != null) {
        // Start show animation if marker changed or newly appeared
        // Use sameMarkerAs to compare by identity (seriesId + markerIndex) only,
        // ignoring plotPosition to prevent flickering from floating-point differences
        final currentTarget =
            _tooltipAnimator.getTargetMarker<HoveredMarkerInfo>();
        if (!markerToShow.sameMarkerAs(currentTarget)) {
          _tooltipAnimator.show(markerToShow, config);
        }

        // Only draw tooltip if it has some opacity (visible or fading)
        if (_tooltipAnimator.isVisible) {
          _drawMarkerTooltip(canvas, size, markerToShow);
        }
      } else {
        // Start hide animation if marker disappeared
        final currentTarget =
            _tooltipAnimator.getTargetMarker<HoveredMarkerInfo>();
        if (currentTarget != null) {
          _tooltipAnimator.hide(config);
        }

        // Still draw tooltip during fade-out
        final targetMarker =
            _tooltipAnimator.getTargetMarker<HoveredMarkerInfo>();
        if (_tooltipAnimator.isVisible && targetMarker != null) {
          _drawMarkerTooltip(canvas, size, targetMarker);
        }
      }
    } else {
      // Tooltips disabled or panning - cancel animations and hide
      if (_tooltipAnimator.opacity > 0) {
        _tooltipAnimator.hideImmediately();
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

    // Paint grid lines (behind everything)
    if (_xAxis != null && _yAxis != null) {
      final gridRenderer = GridRenderer(
        theme: _theme,
        config:
            null, // TODO: Get from widget.grid once chart_render_box receives it
      );

      // Get tick positions for grid lines
      final xTicks =
          _xAxis!.ticks.map((t) => _xAxis!.scale.dataToPixel(t.value)).toList();
      final yTicks =
          _yAxis!.ticks.map((t) => _yAxis!.scale.dataToPixel(t.value)).toList();

      gridRenderer.paintVerticalGrid(canvas, _plotArea, xTicks);
      gridRenderer.paintHorizontalGrid(canvas, _plotArea, yTicks);
    }

    // Paint axes (behind all chart elements)
    // Paint Y-axes using MultiAxisPainter (handles single or multiple axes)
    _paintMultipleYAxes(canvas);

    // Paint X-axis using XAxisPainter (unified approach)
    if (_xAxis != null) {
      final xAxisPainter = XAxisPainter(
        config: XAxisConfig(
          visible: _xAxis!.config.showAxisLine,
          showAxisLine: _xAxis!.config.showAxisLine,
          showTicks: _xAxis!.config.showTickMarks,
          color: _xAxis!.config.axisColor,
          label: _xAxis!.config.label,
        ),
        axisBounds: DataRange(min: _xAxis!.dataMin, max: _xAxis!.dataMax),
        labelStyle: _xAxis!.config.tickLabelStyle,
        series: _multiAxisManager.series,
      );
      xAxisPainter.paint(
          canvas, Rect.fromLTWH(0, 0, size.width, size.height), _plotArea);
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

    // ==========================================================================
    // LAYER 0: Background annotations (Range annotations with renderOrder < 2)
    // These must paint BEFORE series so they appear behind the data lines
    // ==========================================================================
    final backgroundElements = _elements
        .where((e) => e is! SeriesElement && e.renderOrder < RenderOrder.series)
        .toList()
      ..sort((a, b) => a.renderOrder.compareTo(b.renderOrder));

    for (final element in backgroundElements) {
      if (_transform != null && element is RangeAnnotationElement) {
        element.updateTransform(_transform!);
      }
      element.paint(canvas, _plotArea.size);
    }

    // LAYER 1: Series (cached)
    // Check if we can reuse cached Picture, or need to regenerate
    final cacheValid = _seriesCacheManager.isValid(
      elements: _elements,
      currentTransform: _transform,
    );
    // [DEBUG OUTPUT REMOVED] Cache hit/miss - was firing at 60fps

    if (cacheValid) {
      // Cache hit! Draw cached Picture (fast path ~0.1ms)
      canvas.drawPicture(_seriesCacheManager.cachedPicture!);
    } else {
      // Cache miss - regenerate Picture from current data/transform
      // [DEBUG OUTPUT REMOVED] Picture regeneration - fires on data updates

      // Generate new Picture (slow path ~17ms for 5 series)
      final picture = _seriesCacheManager.generatePicture(
        elements: _elements,
        plotAreaSize: _plotArea.size,
        currentTransform: _transform,
        painter: _paintSeriesLayerContent,
      );

      // Draw freshly generated Picture
      canvas.drawPicture(picture);

      // [DEBUG OUTPUT REMOVED] Picture regenerated - fires on data updates
    }

    // LAYER 1.5: Streaming elements (uncached, painted fresh every frame)
    // Paint streaming data on top of cached static series. This avoids cache
    // thrashing at 60fps while maintaining high performance.
    _paintStreamingElements(canvas, _plotArea.size);

    // LAYER 2: Foreground annotations (handles, points, text, thresholds, etc.)
    // These paint AFTER series so they appear on top of data lines
    // Only paint elements with renderOrder >= series (already painted background in Layer 0)
    // Sort by renderOrder (lower = paint first/back, higher = paint last/front)
    // NOTE: renderOrder is SEPARATE from hit test priority!
    final foregroundElements = _elements
        .where(
            (e) => e is! SeriesElement && e.renderOrder >= RenderOrder.series)
        .toList()
      ..sort((a, b) => a.renderOrder.compareTo(b.renderOrder));

    // [DEBUG OUTPUT REMOVED] Non-series element painting - was firing at 60fps
    for (final element in foregroundElements) {
      // [DEBUG OUTPUT REMOVED] Per-element painting - was firing at 60fps

      // Update transform for annotation elements before painting (enables dynamic positioning)
      // CRITICAL FIX: Update transform for ALL annotation types, not just Point and Range
      // This ensures Threshold, Trend, and Pin annotations update during pan/zoom gestures
      if (_transform != null) {
        if (element is PointAnnotationElement) {
          element.updateTransform(_transform!);
        } else if (element is RangeAnnotationElement) {
          element.updateTransform(_transform!);
        } else if (element is ThresholdAnnotationElement) {
          element.updateTransform(_transform!);
        } else if (element is TrendAnnotationElement) {
          element.updateTransform(_transform!);
        } else if (element is PinAnnotationElement) {
          element.updateTransform(_transform!);
        }
      }

      element.paint(canvas, _plotArea.size);
    }

    canvas
        .restore(); // Restore canvas state (removes clipping and translation from plot area)

    // LAYER 3: Overlays (dynamic, always rendered fresh)
    // Crosshair, selection box, preview indicators - change every frame during hover/drag
    // Use saveLayer to create independent compositing layer for crosshair
    // This allows Flutter to repaint ONLY the crosshair without touching series layer
    final overlayBounds = Offset.zero & size;
    canvas.saveLayer(overlayBounds, Paint());
    _paintOverlayLayer(canvas, size);
    canvas.restore(); // Restore from saveLayer

    // Paint scrollbars if enabled (outside plot area clipping)
    _scrollbarManager.paint(canvas, size);

    canvas.restore(); // Final restore (removes initial offset translation)
  }

  // ==========================================================================
  // Scrollbar Setters (delegate to ScrollbarManager)
  // ==========================================================================

  /// Updates X scrollbar visibility.
  void setShowXScrollbar(bool show) {
    if (_scrollbarManager.setShowXScrollbar(show)) {
      // Need layout to recalculate scrollbar rects
      markNeedsLayout();
    }
  }

  /// Updates Y scrollbar visibility.
  void setShowYScrollbar(bool show) {
    if (_scrollbarManager.setShowYScrollbar(show)) {
      // Need layout to recalculate scrollbar rects
      markNeedsLayout();
    }
  }

  /// Updates scrollbar theme configuration.
  void setScrollbarTheme(ScrollbarConfig? theme) {
    if (_scrollbarManager.setScrollbarTheme(theme)) {
      markNeedsPaint();
    }
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

  /// Normalizes a Y value for multi-axis rendering (FR-008).
  ///
  /// When charts have series with vastly different Y-ranges (e.g., 0-10 vs 0-1000),
  /// normalization maps all values to 0.0-1.0 range for consistent visual display.
  ///
  /// This method is used by the rendering pipeline when multi-axis normalization
  /// is active. Each series gets its own normalized space while sharing the X-axis.
  ///
  /// Parameters:
  /// - [value]: The original Y data value to normalize
  /// - [seriesMin]: The minimum Y value in this series
  /// - [seriesMax]: The maximum Y value in this series
  ///
  /// Returns: Normalized value in 0.0-1.0 range
  double normalizeYValue(double value, double seriesMin, double seriesMax) {
    return _multiAxisManager.normalizeYValue(value, seriesMin, seriesMax);
  }

  /// Denormalizes a Y value back to original data coordinates (FR-008).
  ///
  /// Delegates to [MultiAxisManager.denormalizeYValue].
  double denormalizeYValue(
      double normalizedValue, double seriesMin, double seriesMax) {
    return _multiAxisManager.denormalizeYValue(
        normalizedValue, seriesMin, seriesMax);
  }

  /// Draws a tooltip for the hovered marker.
  ///
  /// Delegates to [TooltipRenderer] module for the actual rendering.
  void _drawMarkerTooltip(
      Canvas canvas, Size size, HoveredMarkerInfo markerInfo) {
    _tooltipRenderer.drawMarkerTooltip(
      canvas: canvas,
      size: size,
      markerInfo: markerInfo,
      elements: _elements,
      animator: _tooltipAnimator,
      cursorPosition: _eventHandlerManager.cursorPosition,
      interactionConfig: _interactionConfig,
      theme: _theme,
      effectiveAxes: _getEffectiveYAxes(),
      effectiveBindings: _getEffectiveBindings(),
      formatDataValue: _formatDataValue,
      plotToWidget: plotToWidget,
    );
  }

  // ============================================================================
  // Debug
  // ============================================================================

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('elementCount', _elements.length));
    properties.add(DiagnosticsProperty<QuadTreeStats>(
        'spatialIndexStats', _spatialIndex?.stats));
    properties
        .add(StringProperty('coordinatorState', coordinator.debugState()));
  }

  // ============================================================================
  // Multi-Axis Normalization Helpers (FR-008)
  // ============================================================================

  /// Normalizes a Y-axis value from data space to normalized [0, 1] space.
  ///
  /// Delegates to [MultiAxisManager.normalizeValue].
  double normalizeValue(double value, double min, double max) {
    return _multiAxisManager.normalizeValue(value, min, max);
  }

  /// Denormalizes a value from normalized [0, 1] space back to data space.
  ///
  /// Delegates to [MultiAxisManager.denormalizeValue].
  double denormalizeValue(double normalizedValue, double min, double max) {
    return _multiAxisManager.denormalizeValue(normalizedValue, min, max);
  }
}

// =============================================================================
// Scrollbar Delegate Implementation
// =============================================================================

/// Internal delegate implementation for ScrollbarManager.
///
/// This class adapts ChartRenderBox to the ScrollbarDelegate interface,
/// providing the scrollbar manager with access to transforms and the ability
/// to apply viewport changes.
class _ScrollbarDelegateImpl implements ScrollbarDelegate {
  _ScrollbarDelegateImpl(this._renderBox);

  final ChartRenderBox _renderBox;

  @override
  ChartTransform? get transform => _renderBox._transform;

  @override
  ChartTransform? get originalTransform => _renderBox._originalTransform;

  @override
  DataBounds? get streamingBounds =>
      _renderBox._streamingManager.streamingBounds;

  @override
  void applyTransform(ChartTransform newTransform) {
    _renderBox._transform = newTransform;
  }

  @override
  void updateAxesFromTransform() {
    _renderBox._updateAxesFromTransform();
  }

  @override
  void markNeedsPaint() {
    _renderBox.markNeedsPaint();
  }

  @override
  void setCursor(MouseCursor cursor) {
    _renderBox.onCursorChange?.call(cursor);
  }
}

// =============================================================================
// Streaming Delegate Implementation
// =============================================================================

/// Internal delegate implementation for StreamingManager.
///
/// This class adapts ChartRenderBox to the StreamingDelegate interface,
/// providing the streaming manager with access to transforms and the ability
/// to apply viewport changes for auto-scroll and viewport expansion.
class _StreamingDelegateImpl implements StreamingDelegate {
  _StreamingDelegateImpl(this._renderBox);

  final ChartRenderBox _renderBox;

  @override
  ChartTransform? get transform => _renderBox._transform;

  @override
  set transform(ChartTransform? value) {
    _renderBox._transform = value;
  }

  @override
  ChartTransform? get originalTransform => _renderBox._originalTransform;

  @override
  set originalTransform(ChartTransform? value) {
    _renderBox._originalTransform = value;
  }

  @override
  List<ChartSeries> get series => _renderBox._multiAxisManager.series;

  @override
  void updateAxesFromTransform() {
    _renderBox._updateAxesFromTransform();
  }

  @override
  void markNeedsPaint() {
    _renderBox.markNeedsPaint();
  }

  @override
  void invalidateSeriesCache() {
    _renderBox._seriesCacheManager.invalidate();
  }

  @override
  void setPanConstraintBounds(
      double minX, double maxX, double minY, double maxY) {
    _renderBox.setPanConstraintBounds(minX, maxX, minY, maxY);
  }

  @override
  void clearPanConstraintBounds() {
    _renderBox.clearPanConstraintBounds();
  }
}

// =============================================================================
// Annotation Drag Delegate Implementation
// =============================================================================

/// Internal delegate implementation for AnnotationDragHandler.
///
/// This class adapts ChartRenderBox to the AnnotationDragDelegate interface,
/// providing the annotation drag handler with access to elements, transforms,
/// and the ability to trigger repaints and notify about annotation changes.
class _AnnotationDragDelegateImpl implements AnnotationDragDelegate {
  _AnnotationDragDelegateImpl(this._renderBox);

  final ChartRenderBox _renderBox;

  @override
  ChartTransform? get transform => _renderBox._transform;

  @override
  List<ChartElement> get elements => _renderBox._elements;

  @override
  List<ChartSeries> get series => _renderBox._multiAxisManager.series;

  @override
  void rebuildSpatialIndex() {
    _renderBox._rebuildSpatialIndex();
  }

  @override
  void markNeedsPaint() {
    _renderBox.markNeedsPaint();
  }

  @override
  void notifyAnnotationChanged(
      String annotationId, ChartAnnotation updatedAnnotation) {
    _renderBox.onAnnotationChanged?.call(annotationId, updatedAnnotation);
  }
}

/// Internal delegate implementation for EventHandlerManager.
///
/// This class adapts ChartRenderBox to the EventHandlerDelegate interface,
/// providing the event handler manager with access to all required dependencies
/// for handling pointer events, hit testing, and interaction state management.
class _EventHandlerDelegateImpl implements EventHandlerDelegate {
  _EventHandlerDelegateImpl(this._renderBox);

  final ChartRenderBox _renderBox;

  // ============================================================================
  // Core dependencies
  // ============================================================================

  @override
  ChartInteractionCoordinator get coordinator => _renderBox.coordinator;

  @override
  ChartTransform? get transform => _renderBox._transform;

  @override
  set transform(ChartTransform? value) {
    _renderBox._transform = value;
  }

  @override
  ChartTransform? get originalTransform => _renderBox._originalTransform;

  @override
  InteractionConfig? get interactionConfig => _renderBox._interactionConfig;

  @override
  List<ChartElement> get elements => _renderBox._elements;

  @override
  Rect get plotArea => _renderBox._plotArea;

  // ============================================================================
  // Callbacks
  // ============================================================================

  @override
  void Function(ChartElement, PointerEvent)? get onElementClick =>
      _renderBox.onElementClick;

  @override
  void Function(Offset, PointerEvent)? get onEmptyAreaClick =>
      _renderBox.onEmptyAreaClick;

  @override
  void Function(ChartElement?)? get onElementHover => _renderBox.onElementHover;

  @override
  void Function(MouseCursor)? get onCursorChange => _renderBox.onCursorChange;

  @override
  void Function(String, ChartAnnotation)? get onAnnotationChanged =>
      _renderBox.onAnnotationChanged;

  @override
  void Function(double, double, double, double)? get onRangeCreationComplete =>
      _renderBox.onRangeCreationComplete;

  // ============================================================================
  // Hit testing
  // ============================================================================

  @override
  ChartElement? hitTestElements(Offset position) {
    return _renderBox.hitTestElements(position);
  }

  @override
  List<ChartElement> hitTestRect(Rect rect) {
    return _renderBox.hitTestRect(rect).toList();
  }

  @override
  void rebuildSpatialIndex() {
    _renderBox._rebuildSpatialIndex();
  }

  // ============================================================================
  // Module delegations
  // ============================================================================

  @override
  bool hitTestScrollbars(
    Offset position,
    int buttons, {
    required bool isModal,
    required VoidCallback onClaimMode,
    required VoidCallback cancelAutoScroll,
  }) {
    return _renderBox._scrollbarManager.hitTestScrollbars(
      position,
      buttons,
      isModal: isModal,
      onClaimMode: onClaimMode,
      cancelAutoScroll: cancelAutoScroll,
    );
  }

  @override
  bool get isScrollbarDragging => _renderBox._scrollbarManager.isDragging;

  @override
  void handleScrollbarDrag(Offset position) {
    _renderBox._scrollbarManager.handleScrollbarDrag(position);
  }

  @override
  void clearScrollbarDragState() {
    _renderBox._scrollbarManager.clearScrollbarDragState();
  }

  @override
  bool checkScrollbarHover(Offset position) {
    return _renderBox._scrollbarManager.checkScrollbarHover(position);
  }

  @override
  void showScrollbarsAndScheduleHide() {
    _renderBox._scrollbarManager.showScrollbarsAndScheduleHide();
  }

  @override
  void cancelAutoScroll() {
    _renderBox._streamingManager.cancelAutoScroll();
  }

  @override
  void invalidateSeriesCache() {
    _renderBox._seriesCacheManager.invalidate();
  }

  // ============================================================================
  // Transform operations
  // ============================================================================

  @override
  Offset widgetToPlot(Offset widgetPosition) {
    return _renderBox.widgetToPlot(widgetPosition);
  }

  @override
  (double, double) clampPanDelta(double dx, double dy) {
    return _renderBox._clampPanDelta(dx, dy);
  }

  @override
  void updateAxesFromTransform() {
    _renderBox._updateAxesFromTransform();
  }

  @override
  void rebuildElementsWithTransform() {
    _renderBox._rebuildElementsWithTransform();
  }

  @override
  ChartTransform clampZoomLevel(ChartTransform tentativeTransform) {
    return _renderBox._clampZoomLevel(tentativeTransform);
  }

  @override
  void zoomChart(double factor, {Offset? plotCenter, bool animate = true}) {
    _renderBox.zoomChart(factor, plotCenter: plotCenter, animate: animate);
  }

  // ============================================================================
  // Render operations
  // ============================================================================

  @override
  void markNeedsPaint() {
    _renderBox.markNeedsPaint();
  }
}
