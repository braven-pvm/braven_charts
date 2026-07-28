// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart'
    show ValueChanged, ValueKey, visibleForTesting;
import 'package:flutter/gestures.dart'
    show PointerDeviceKind, PointerHoverEvent;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart'
    show
        HardwareKeyboard,
        KeyDownEvent,
        KeyEvent,
        KeyRepeatEvent,
        KeyUpEvent,
        LogicalKeyboardKey;

import '../artifacts/chart_view_state.dart' show ChartPointRef;
import '../axis/axis.dart' as chart_axis;
import '../axis/log_ticks.dart';
import '../coordinates/chart_transform.dart';
import '../elements/annotation_elements.dart';
import '../elements/pie_series_element.dart';
import '../elements/radial_bar_series_element.dart';
import '../elements/resize_handle_element.dart';
import '../elements/series_element.dart';
import '../elements/simulated_annotation.dart';
import '../elements/value_summary_annotation_element.dart';
import '../interaction/core/cartesian_tracking_snapshot.dart';
import '../interaction/core/chart_element.dart';
import '../interaction/core/coordinator.dart';
import '../interaction/core/crosshair_tracker.dart';
import '../interaction/core/tracking_snapshot_resolver.dart';
import '../interaction/core/data_hit.dart';
import '../interaction/core/element_types.dart';
import '../interaction/core/interaction_mode.dart';
import '../interaction/summary/value_summary_coordinator.dart';
import '../models/axis_scale_type.dart';
import '../models/axis_swap_mode.dart';
import '../models/bar_chart_style.dart';
import '../models/braven_chart_controller.dart' show ChartSelectionBrushState;
import '../models/cartesian_value_summary_config.dart';
import '../models/chart_annotation.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';
import '../models/chart_theme.dart';
import '../models/grid_config.dart';
import '../models/interaction_config.dart';
import '../models/normalization_mode.dart';
import '../models/range_area_chart_series.dart';
import '../models/series_axis_binding.dart';
import '../models/x_axis_config.dart';
import '../models/x_axis_position.dart';
import '../models/y_axis_config.dart';
import '../streaming/streaming_buffer.dart';
import '../theming/components/cartesian_value_summary_theme.dart';
import '../theming/components/scrollbar_config.dart';
import '../utils/dashed_path.dart';
import 'grid_renderer.dart';
import 'bar_label_layout.dart';
import 'data_point_label_layout.dart';
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
import 'multi_axis_normalizer.dart';
import 'multi_axis_painter.dart';
import 'spatial_index.dart';
import 'transposed_bar_axes_painter.dart';
import 'x_axis_painter.dart';

/// Callback for generating chart elements based on current transform.
/// Used for zoom/pan to regenerate elements from original data coordinates.
typedef ElementGenerator =
    List<ChartElement> Function(ChartTransform transform);

enum _SelectionBrushKeyboardTarget { body, lowerBound, upperBound }

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
  /// Insets around an axisless radial plot inside this render box.
  ///
  /// Widget overlays use the same contract so Donut center content remains
  /// aligned with Canvas geometry during resize.
  static const EdgeInsets axislessPlotInsets = EdgeInsets.all(10);

  ChartRenderBox({
    required this.coordinator,
    List<ChartElement>? elements,
    ElementGenerator? elementGenerator,
    ChartTheme? theme,
    bool tooltipsEnabled = true,
    String? selectedTooltipSeriesId,
    int? selectedTooltipPointIndex,
    bool showXScrollbar = false,
    bool showYScrollbar = false,
    ScrollbarConfig? scrollbarTheme,
    InteractionConfig? interactionConfig,
    ChartSelectionBrushState? selectionBrushState,
    bool selectionBrushKeyboardFocused = false,
    bool disableAnimations = false,
    NormalizationMode? normalizationMode,
    List<ChartSeries>? series,
    this.onElementClick,
    this.onElementHover,
    this.onDataHitActivate,
    this.onDataHitFocus,
    this.onEmptyAreaClick,
    this.onCursorChange,
    this.onAnnotationDragUpdate,
    this.onAnnotationChanged,
    this.onRangeCreationComplete,
    this.onSelectionGestureComplete,
    this.onViewportInteracted,
    this.onViewportChanged,
    this.onDataXCursorChanged,
    double textScaleFactor = 1,
    TextDirection textDirection = TextDirection.ltr,
    EdgeInsets axislessInsets = axislessPlotInsets,
  }) : _elementGenerator = elementGenerator,
       _theme = theme,
       _tooltipsEnabled = tooltipsEnabled,
       _selectedTooltipSeriesId = selectedTooltipSeriesId,
       _selectedTooltipPointIndex = selectedTooltipPointIndex,
       _interactionConfig = interactionConfig,
       _selectionBrushState = selectionBrushState,
       _selectionBrushKeyboardFocused = selectionBrushKeyboardFocused,
       _disableAnimations = disableAnimations,
       _textScaleFactor = textScaleFactor,
       _textDirection = textDirection,
       _axislessInsets = axislessInsets,
       assert(
         (elements != null) != (elementGenerator != null),
         'Must provide either elements or elementGenerator, but not both',
       ) {
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
    _valueSummaryCoordinator = ValueSummaryCoordinator(
      onNeedsRepaint: markNeedsPaint,
    );
    _valueSummaryCoordinator.onAnnounce = _announceValueSummary;
    // Controllers are excluded from config equality; attach by reference.
    _valueSummaryCoordinator.attachController(
      interactionConfig?.valueSummary.controller,
    );
    _valueSummaryCoordinator.onPlacementChanged =
        interactionConfig?.valueSummary.onPlacementChanged;
  }

  /// Initializes the MultiAxisManager with normalization mode and series.
  void _initMultiAxisManager(
    NormalizationMode? normalizationMode,
    List<ChartSeries>? series,
  ) {
    _multiAxisManager.setNormalizationMode(normalizationMode);
    _multiAxisManager.setSeries(series);
  }

  /// Initializes the ScrollbarManager with a delegate that references this RenderBox.
  void _initScrollbarManager(
    bool showXScrollbar,
    bool showYScrollbar,
    ScrollbarConfig? scrollbarTheme,
  ) {
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

  /// Whether the spatial index needs rebuilding before the next query.
  ///
  /// Set to true when selection changes or elements are modified, instead of
  /// rebuilding synchronously. This defers the expensive QuadTree rebuild
  /// until the next hitTestElements() call or paint(), avoiding 2s freezes
  /// when multiple charts are on screen (e.g., gallery with 21 charts).
  bool _spatialIndexDirty = false;

  /// Diagnostic count of completed element regenerations.
  ///
  /// This lets interaction regression tests prove that continuous viewport
  /// gestures remain paint-only and pay the geometry/index rebuild cost once
  /// when the gesture settles.
  int get debugElementRebuildCount => _debugElementRebuildCount;
  int _debugElementRebuildCount = 0;

  /// Whether raw touch input is still suppressed by an owned viewport gesture.
  bool get debugIsSuppressingTouchSequence =>
      _eventHandlerManager.isSuppressingTouchSequence;

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

  /// Grid configuration for controlling grid line visibility.
  GridConfig? _gridConfig;

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

  /// Activates a resolved datum through assistive semantics.
  void Function(ChartDataHit hit)? onDataHitActivate;

  /// Focuses a resolved datum through assistive semantics.
  void Function(ChartDataHit hit)? onDataHitFocus;

  /// Callback for empty area click (for box select start).
  final void Function(Offset position, PointerEvent event)? onEmptyAreaClick;

  /// Callback for cursor changes.
  final void Function(MouseCursor cursor)? onCursorChange;

  /// Callback for transient annotation geometry during move or resize.
  ///
  /// Unlike [onAnnotationChanged], this does not commit controller state.
  void Function(String annotationId, ChartAnnotation previewAnnotation)?
  onAnnotationDragUpdate;

  /// Callback for annotation changes (e.g., after drag-to-resize).
  ///
  /// Called when an annotation is modified through user interaction.
  /// The `annotationId` is the ID of the modified annotation, and
  /// `updatedAnnotation` is the new annotation object with updated values.
  final void Function(String annotationId, ChartAnnotation updatedAnnotation)?
  onAnnotationChanged;

  /// Callback for range annotation creation completion.
  ///
  /// Called when user completes drag in rangeAnnotationCreation mode.
  /// Provides data coordinates of dragged rectangle (startX, endX, startY, endY).
  final void Function(double startX, double endX, double startY, double endY)?
  onRangeCreationComplete;

  /// Callback for completed rectangle or lasso data acquisition.
  void Function(ChartSelectionGestureResult result)? onSelectionGestureComplete;

  /// Callback for manual viewport interactions such as wheel zoom or scrollbar drag.
  void Function()? onViewportInteracted;

  /// Callback emitted after local viewport bounds actually change.
  VoidCallback? onViewportChanged;

  /// Callback emitted when local pointer interaction resolves a data-space X.
  ValueChanged<double?>? onDataXCursorChanged;

  // ==================== EVENT STATE (delegated to EventHandlerManager) ====================
  // Resize, move, potential drag state, cursor position, pan position, hit test throttling
  // are now managed by EventHandlerManager module.

  /// Whether tooltips are enabled.
  bool _tooltipsEnabled;

  /// Durable selected datum whose tooltip is independent of pointer hover.
  String? _selectedTooltipSeriesId;
  int? _selectedTooltipPointIndex;
  double? _synchronizedCursorX;

  /// Manages tooltip show/hide animations with configurable delays.
  ///
  /// Handles timing and opacity animation for tooltips:
  /// - Show delay: Wait before displaying tooltip on hover
  /// - Hide delay: Wait before hiding tooltip when moving away
  /// - Fade animation: Smooth opacity transitions
  late final TooltipAnimator _tooltipAnimator;
  Rect? _debugTooltipRect;

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
  ChartSelectionBrushState? _selectionBrushState;
  bool _selectionBrushKeyboardFocused;
  bool _disableAnimations;
  _SelectionBrushKeyboardTarget _selectionBrushKeyboardTarget =
      _SelectionBrushKeyboardTarget.body;

  /// Effective MediaQuery text scale used by canvas tooltips.
  double _textScaleFactor;

  /// Ambient reading direction for canvas text and semantics.
  TextDirection _textDirection;

  final Map<String, SemanticsNode> _dataSemanticsNodes =
      <String, SemanticsNode>{};

  /// X-axis for the chart (optional).
  chart_axis.Axis? _xAxis;

  /// Modern X-axis configuration using [XAxisConfig] type.
  ///
  /// When provided, this is used directly by CrosshairRenderer and other
  /// components that need access to X-axis configuration like crosshairLabelPosition.
  /// This is the NEW [XAxisConfig] type, NOT the legacy [chart_axis.Axis].
  XAxisConfig? _xAxisConfig;

  /// Category configuration for which the automatic initial viewport was
  /// resolved. This prevents relayouts from snapping a user-panned chart back
  /// to its first categories.
  XAxisConfig? _categoricalViewportAppliedFor;

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

  /// Base X bounds last used to initialize the transform lifecycle.
  ///
  /// This must track widget-provided chart bounds, not the current zoomed axis
  /// range. Otherwise a zoomed rebuild can be misclassified as a chart switch.
  double? _layoutBaseXMin;
  double? _layoutBaseXMax;

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

  /// Single per-chart tracking resolution point.
  ///
  /// Resolves the crosshair tracking snapshot once per interaction frame with
  /// input memoization and identity-based publish suppression. The paint
  /// path, the synchronized-cursor path, and the debug hooks all consume its
  /// published [CartesianTrackingSnapshot] instead of re-running
  /// [CrosshairTracker.calculateTrackingState].
  final CartesianTrackingSnapshotResolver _trackingSnapshotResolver =
      CartesianTrackingSnapshotResolver();

  /// Monotonic revision of tracked series data and axis bindings.
  ///
  /// Element instances and axis info are deliberately not part of the
  /// resolver's cache key, so every path that rebuilds elements or changes
  /// series/axis configuration bumps this revision to force re-resolution.
  int _trackingDataRevision = 0;

  /// Value summary pipeline state (policy reduction, adaptation, overlay
  /// element feeding). Owned per chart; near-free while the summary is
  /// disabled.
  late final ValueSummaryCoordinator _valueSummaryCoordinator;

  /// Dedicated resolver for the value summary's divergent live-tracking
  /// resolution: used only while the crosshair actively resolves the shared
  /// pointer-path snapshot WITH interpolation and the summary's `valueMode`
  /// wants snapped data points. Keeping the divergent preference on its own
  /// instance preserves the shared resolver's input memo — one computation
  /// per consumer per cursor change, no memo thrash, no publish ping-pong.
  /// In every compatible combination this resolver is never touched.
  final CartesianTrackingSnapshotResolver _summaryTrackingResolver =
      CartesianTrackingSnapshotResolver();

  /// Whether the current frame's summary tracking resolution went through
  /// the shared pointer-path resolver (compatible path) rather than the
  /// dedicated [_summaryTrackingResolver] (divergent path). Written by
  /// [_resolveSummaryTracking] each frame.
  bool _valueSummaryUsedSharedResolver = false;

  /// Whether the value summary consumed a live pointer/synchronized tracking
  /// resolution from the SHARED resolver during the current paint frame.
  ///
  /// While true, the crosshair path's gate-off `clear()` calls are skipped so
  /// they cannot wipe the resolver state (and its input memo) the summary
  /// resolved this frame — the summary is a legitimate consumer of tracking
  /// even when the crosshair itself is disabled. A divergent-mode summary
  /// resolution (dedicated resolver) leaves this false: the shared state
  /// belongs to the crosshair that frame. With the summary disabled this
  /// flag is always false and every clear behaves exactly as before.
  bool _valueSummaryTrackingActive = false;

  /// Tooltip renderer module.
  ///
  /// Handles all tooltip-related rendering:
  /// - Smart positioning to avoid clipping at canvas edges
  /// - Arrow pointer pointing to data marker
  /// - Styling with background, border, shadow, and opacity animation
  static const TooltipRenderer _tooltipRenderer = TooltipRenderer();

  // Crosshair axis-label layout remains intentionally uncached. BC-0019's
  // focused benchmark did not meet the approved absolute p95 benefit floor;
  // see the committed design evidence.

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

  EdgeInsets _axislessInsets;

  /// Updates the plot insets used when no visible axes reserve geometry.
  void setAxislessPlotInsets(EdgeInsets value) {
    if (_axislessInsets == value) return;
    _axislessInsets = value;
    markNeedsLayout();
  }

  /// Restores durable data-space viewport bounds after hydration.
  bool restoreVisibleDataBounds({
    required double xMin,
    required double xMax,
    required double yMin,
    required double yMax,
    bool notifyViewportChanged = false,
  }) {
    if (_transform == null ||
        !xMin.isFinite ||
        !xMax.isFinite ||
        !yMin.isFinite ||
        !yMax.isFinite ||
        xMin >= xMax ||
        yMin >= yMax) {
      return false;
    }
    _transform = _transform!.copyWith(
      dataXMin: xMin,
      dataXMax: xMax,
      dataYMin: yMin,
      dataYMax: yMax,
    );
    _updateAxesFromTransform();
    _rebuildElementsWithTransform();
    markNeedsPaint();
    if (notifyViewportChanged) onViewportChanged?.call();
    return true;
  }

  /// Restores only visible data-X bounds while preserving the local Y domain.
  ///
  /// This non-broadcasting path is used by synchronized-chart participants and
  /// therefore deliberately does not invoke [onViewportChanged].
  bool restoreVisibleXBounds({required double xMin, required double xMax}) {
    final transform = _transform;
    if (transform == null || !xMin.isFinite || !xMax.isFinite || xMin >= xMax) {
      return false;
    }
    if (transform.dataXMin == xMin && transform.dataXMax == xMax) return false;
    _transform = transform.copyWith(dataXMin: xMin, dataXMax: xMax);
    _updateAxesFromTransform();
    markNeedsPaint();
    return true;
  }

  /// Finalizes geometry and hit-test state after synchronized viewport input
  /// settles. Continuous updates use [restoreVisibleXBounds]'s paint-only path.
  void finalizeSynchronizedViewport() => finalizeViewportInteraction();

  /// Finalizes geometry and hit-test state after continuous viewport input.
  ///
  /// Touch transforms and synchronized charts use paint-only updates while an
  /// interaction is active, then pay this rebuild cost once when it settles.
  void finalizeViewportInteraction() {
    if (_transform == null) return;
    _rebuildElementsWithTransform();
    _seriesCacheManager.invalidate();
    markNeedsPaint();
  }

  /// Applies a transient synchronized data-X cursor without rebuilding data.
  void setSynchronizedCursorDataX(double? dataX) {
    if (dataX != null && !dataX.isFinite) {
      throw ArgumentError.value(dataX, 'dataX', 'must be finite or null');
    }
    if (_synchronizedCursorX == dataX) return;
    _synchronizedCursorX = dataX;
    markNeedsPaint();
  }

  // Memoized synchronized cursor position. The getter is consulted several
  // times per paint frame (overlay activity check, effective config, paint
  // guard, debug hooks); memoizing on its inputs collapses those repeated
  // evaluations into a single computation per cursor/viewport/data change.
  bool _syncPositionCacheValid = false;
  double? _syncPositionCacheDataX;
  ChartTransform? _syncPositionCacheTransform;
  Rect? _syncPositionCachePlotArea;
  List<ChartElement>? _syncPositionCacheElements;
  CrosshairConfig? _syncPositionCacheCrosshair;
  Offset? _syncPositionCacheValue;

  // The tracking snapshot resolved while computing the synchronized cursor
  // position (Y adjustment), retained so the same frame's paint and debug
  // reads share one resolution instead of resolving again at the adjusted
  // cursor. Valid only while it is identical to the resolver's current
  // snapshot; cleared with the position cache.
  CartesianTrackingSnapshot? _syncPositionSnapshot;

  Offset? get _synchronizedCursorPosition {
    final transform = _transform;
    final dataX = _synchronizedCursorX;
    if (transform == null || dataX == null || _plotArea.isEmpty) return null;
    final crosshair = _interactionConfig?.crosshair ?? const CrosshairConfig();
    if (_syncPositionCacheValid &&
        _syncPositionCacheDataX == dataX &&
        _syncPositionCacheTransform == transform &&
        _syncPositionCachePlotArea == _plotArea &&
        identical(_syncPositionCacheElements, _elements) &&
        _syncPositionCacheCrosshair == crosshair) {
      return _syncPositionCacheValue;
    }
    final position = _computeSynchronizedCursorPosition(
      transform: transform,
      dataX: dataX,
      crosshair: crosshair,
    );
    _syncPositionCacheValid = true;
    _syncPositionCacheDataX = dataX;
    _syncPositionCacheTransform = transform;
    _syncPositionCachePlotArea = _plotArea;
    _syncPositionCacheElements = _elements;
    _syncPositionCacheCrosshair = crosshair;
    _syncPositionCacheValue = position;
    return position;
  }

  Offset? _computeSynchronizedCursorPosition({
    required ChartTransform transform,
    required double dataX,
    required CrosshairConfig crosshair,
  }) {
    final plotPosition = transform.dataToPlot(dataX, transform.dataYMin);
    var widgetPosition = plotToWidget(
      transform.transposed
          ? Offset(_plotArea.width / 2, plotPosition.dy)
          : Offset(plotPosition.dx, _plotArea.height / 2),
    );
    final needsLocalY =
        crosshair.enabled &&
        (crosshair.mode == CrosshairMode.horizontal ||
            crosshair.mode == CrosshairMode.both) &&
        !transform.transposed;
    _syncPositionSnapshot = null;
    if (needsLocalY) {
      final snapshot = _resolveTrackingSnapshot(
        cursorPosition: widgetPosition,
        origin: CartesianTrackingOrigin.synchronized,
        interpolateValues: crosshair.interpolateValues,
      );
      _syncPositionSnapshot = snapshot;
      if (snapshot != null && snapshot.values.isNotEmpty) {
        final value = snapshot.values.first;
        SeriesElement? seriesElement;
        for (final candidate in _elements.whereType<SeriesElement>()) {
          if (candidate.id == value.axisSeriesId) {
            seriesElement = candidate;
            break;
          }
        }
        final screenY = seriesElement == null
            ? CrosshairTracker.dataToScreenY(
                dataY: value.y,
                chartBounds: _plotArea,
                yMin: transform.dataYMin,
                yMax: transform.dataYMax,
              )
            : plotToWidget(
                seriesElement.dataToCurrentPlot(value.x, value.y),
              ).dy;
        widgetPosition = Offset(widgetPosition.dx, screenY);
      }
    }
    return _plotArea.contains(widgetPosition) ? widgetPosition : null;
  }

  Offset? get _effectiveCrosshairCursorPosition =>
      _synchronizedCursorPosition ?? _eventHandlerManager.cursorPosition;

  CrosshairConfig _effectiveCrosshairConfig(CrosshairConfig base) {
    if (_synchronizedCursorPosition == null) return base;
    return base.copyWith(
      snapToDataPoint: false,
      displayMode: CrosshairDisplayMode.tracking,
      // A shared cursor remains a continuous data-X coordinate. Local value
      // resolution still honors the participant's interpolation preference.
    );
  }

  /// Resolves the tracking snapshot for a widget-space cursor position
  /// through the chart's single [CartesianTrackingSnapshotResolver].
  ///
  /// [axisInfo] lets the paint path reuse its already-built [MultiAxisInfo];
  /// other callers build one on demand.
  CartesianTrackingSnapshot? _resolveTrackingSnapshot({
    required Offset cursorPosition,
    required CartesianTrackingOrigin origin,
    required bool interpolateValues,
    MultiAxisInfo? axisInfo,
  }) {
    final transform = _transform;
    if (transform == null || _plotArea.isEmpty) {
      // Resolution prerequisites are gone; publish the null snapshot so
      // consumers of the resolver never observe stale tracking state.
      _trackingSnapshotResolver.clear();
      return null;
    }
    return _trackingSnapshotResolver.resolve(
      cursorPlotPosition: cursorPosition - _plotArea.topLeft,
      plotArea: _plotArea,
      transform: transform,
      elements: _elements,
      axisInfo: axisInfo ?? _buildMultiAxisInfo(),
      origin: origin,
      includeTrends: true,
      interpolateValues: interpolateValues,
      dataRevision: _trackingDataRevision,
    );
  }

  /// Signals that tracked series data or axis bindings changed, forcing the
  /// next tracking resolution to recompute.
  void _invalidateTrackingResolution() {
    _trackingDataRevision++;
    _syncPositionCacheValid = false;
    _syncPositionSnapshot = null;
  }

  /// Current synchronized data X for render-path verification.
  @visibleForTesting
  double? get debugSynchronizedCursorX => _synchronizedCursorX;

  /// Locally mapped synchronized cursor position for render-path verification.
  @visibleForTesting
  Offset? get debugSynchronizedCursorPosition => _synchronizedCursorPosition;

  /// Last local pointer position retained for crosshair rendering.
  @visibleForTesting
  Offset? get debugPointerCursorPosition => _eventHandlerManager.cursorPosition;

  /// Local rendered-path intersections used by synchronized tracking.
  ///
  /// Reads the shared tracking resolver (a cache hit when paint already
  /// resolved this frame) and adapts the snapshot to the legacy
  /// [CrosshairTrackingState] contract expected by existing tests.
  @visibleForTesting
  CrosshairTrackingState? get debugSynchronizedTrackingState {
    final cursor = _synchronizedCursorPosition;
    if (cursor == null) return null;
    final crosshair = _interactionConfig?.crosshair ?? const CrosshairConfig();
    // Share the resolution retained by the synchronized-position computation
    // (the same one paint reuses) instead of resolving again at the
    // Y-adjusted cursor.
    final retained = _syncPositionSnapshot;
    final snapshot =
        (retained != null &&
            identical(retained, _trackingSnapshotResolver.current))
        ? retained
        : _resolveTrackingSnapshot(
            cursorPosition: cursor,
            origin: CartesianTrackingOrigin.synchronized,
            interpolateValues: crosshair.interpolateValues,
          );
    if (snapshot == null) return null;
    final transposed = _transform?.transposed ?? false;
    return CrosshairTrackingState(
      dataX: snapshot.dataX,
      screenX: transposed ? cursor.dy : cursor.dx,
      seriesValues: [
        for (final value in snapshot.values) _toCrosshairSeriesValue(value),
      ],
    );
  }

  static CrosshairSeriesValue _toCrosshairSeriesValue(
    CartesianTrackedSeriesValue value,
  ) {
    return CrosshairSeriesValue(
      seriesId: value.seriesId,
      seriesName: value.seriesName,
      seriesColor: value.seriesColor,
      x: value.x,
      y: value.y,
      dataPointIndex: value.dataPointIndex,
      sourcePointIndices: value.sourcePointIndices,
      isInterpolated: value.isInterpolated,
      linkedSeriesId: value.linkedSeriesId,
      isTrend: value.isTrend,
      pointLabel: value.pointLabel,
      magnitudeValue: value.magnitudeValue,
      formattedMagnitudeValue: value.formattedMagnitudeValue,
      magnitudeLabel: value.magnitudeLabel,
      colorValue: value.colorValue,
      formattedColorValue: value.formattedColorValue,
      colorLabel: value.colorLabel,
      opacityValue: value.opacityValue,
      formattedOpacityValue: value.formattedOpacityValue,
      opacityLabel: value.opacityLabel,
      candlestick: value.candlestick,
      categoryValue: value.categoryValue,
      categoryLabel: value.categoryLabel,
    );
  }

  /// Latest published tracking snapshot, without triggering a resolution.
  @visibleForTesting
  CartesianTrackingSnapshot? get debugTrackingSnapshot =>
      _trackingSnapshotResolver.current;

  /// Total [CartesianTrackingSnapshotResolver.resolve] calls on this chart.
  @visibleForTesting
  int get debugTrackingResolveCount =>
      _trackingSnapshotResolver.debugResolveCount;

  /// Total published tracking snapshot changes on this chart.
  @visibleForTesting
  int get debugTrackingPublishCount =>
      _trackingSnapshotResolver.debugPublishCount;

  /// Total actual tracking snapshot computations (input-cache misses) on
  /// this chart. Stationary repaints must not increment this.
  @visibleForTesting
  int get debugTrackingComputeCount =>
      _trackingSnapshotResolver.debugComputeCount;

  /// Intersection markers painted by the most recent crosshair paint, in
  /// chart-local screen coordinates.
  ///
  /// Empty when the last paint drew no tracking-mode intersection markers.
  /// Widget tests use this probe to assert exact marker placement — in
  /// particular that interpolated markers follow the live cursor X even
  /// while snapshot identity suppression retains the published snapshot.
  @visibleForTesting
  List<PaintedIntersectionMarker> get debugPaintedIntersectionMarkers =>
      List.unmodifiable(_paintedIntersectionMarkers);

  final List<PaintedIntersectionMarker> _paintedIntersectionMarkers =
      <PaintedIntersectionMarker>[];

  // ==========================================================================
  // Cartesian value summary pipeline
  // ==========================================================================

  /// Runs the value summary pipeline for the current paint frame.
  ///
  /// Called once per paint before the foreground element pass so the overlay
  /// element paints this frame's policy-resolved content. Honors both the
  /// outer [InteractionConfig.enabled] gate and the nested
  /// `valueSummary.enabled` flag (`InteractionConfig.none()` therefore
  /// disables the summary even when the nested config is enabled), and
  /// suspends transient tracking during drags and pan/zoom.
  void _updateValueSummary() {
    final interaction = _interactionConfig;
    final summaryConfig =
        interaction != null &&
            interaction.enabled &&
            interaction.valueSummary.enabled
        ? interaction.valueSummary
        : null;
    final suspended = coordinator.isDragging || coordinator.isPanningOrZooming;

    // Live tracking feeds every policy chain except explicitOnly. The
    // resolution goes through the chart's shared pointer-path resolver
    // whenever the summary's value mode is compatible with it, so when the
    // crosshair also tracks this frame its own resolve call is an input-memo
    // hit — one computation per frame either way. Only the genuinely
    // divergent combination (crosshair interpolating while the summary wants
    // data points) resolves through the dedicated summary resolver.
    CartesianTrackingSnapshot? tracking;
    _valueSummaryUsedSharedResolver = false;
    if (summaryConfig != null &&
        summaryConfig.valuePolicy !=
            CartesianValueSummaryValuePolicy.explicitOnly &&
        !suspended) {
      tracking = _resolveSummaryTracking(summaryConfig);
    }
    _valueSummaryTrackingActive =
        tracking != null && _valueSummaryUsedSharedResolver;

    ChartPointRef? selection;
    if (summaryConfig?.valuePolicy ==
            CartesianValueSummaryValuePolicy.selectionThenTrackingThenLatest &&
        _selectedTooltipSeriesId != null &&
        _selectedTooltipPointIndex != null) {
      selection = ChartPointRef(
        seriesId: _selectedTooltipSeriesId!,
        pointIndex: _selectedTooltipPointIndex!,
      );
    }

    _valueSummaryCoordinator.update(
      config: summaryConfig,
      theme:
          _theme?.cartesianValueSummaryTheme ??
          CartesianValueSummaryTheme.light,
      tracking: tracking,
      suspended: suspended,
      plotArea: _plotArea,
      transform: _transform,
      elements: _elements,
      axisInfoBuilder: _buildMultiAxisInfo,
      dataRevision: _trackingDataRevision,
      textDirection: _textDirection,
      textScale: _textScaleFactor,
      selection: selection,
    );
  }

  /// Resolves the summary's live tracking snapshot for this frame, or null
  /// when no live tracking source exists (no cursor, cursor outside the
  /// plot).
  ///
  /// Mirrors the crosshair paint path's source selection — the synchronized
  /// cursor takes precedence over the local pointer, and a snapshot already
  /// retained by the synchronized-position computation is reused instead of
  /// re-resolving at the Y-adjusted cursor.
  ///
  /// The summary's `valueMode` decides how the resolution is sourced:
  ///
  /// - **Compatible with the shared resolution** (interpolated mode; or
  ///   dataPoints mode while the crosshair's interpolation is off; or the
  ///   crosshair not consuming the shared tracking resolution at all, in
  ///   which case the summary owns the resolve and passes the interpolation
  ///   flag its mode implies): reuse the shared pointer-path resolver —
  ///   zero extra resolutions per frame.
  /// - **Divergent** (crosshair actively tracking WITH interpolation while
  ///   the summary wants data points): resolve once through the dedicated
  ///   [_summaryTrackingResolver] with the same memo discipline, leaving the
  ///   shared resolver's input memo to the crosshair.
  CartesianTrackingSnapshot? _resolveSummaryTracking(
    CartesianValueSummaryConfig summaryConfig,
  ) {
    final cursorPos = _effectiveCrosshairCursorPosition;
    if (cursorPos == null || !_plotArea.contains(cursorPos)) return null;
    final crosshair = _interactionConfig?.crosshair ?? const CrosshairConfig();
    final origin = _synchronizedCursorPosition != null
        ? CartesianTrackingOrigin.synchronized
        : CartesianTrackingOrigin.pointer;
    final wantsDataPoints =
        summaryConfig.valueMode == CartesianValueSummaryValueMode.dataPoints;

    if (wantsDataPoints &&
        crosshair.interpolateValues &&
        _crosshairConsumesSharedTracking(crosshair)) {
      // Divergent path. Sharing the pointer-path resolver here would flip
      // its interpolateValues memo key every frame (two computations plus
      // publish ping-pong), so the summary resolves on its own instance:
      // one extra memoized computation per cursor change, none per repaint.
      final transform = _transform;
      if (transform == null || _plotArea.isEmpty) {
        _summaryTrackingResolver.clear();
        return null;
      }
      return _summaryTrackingResolver.resolve(
        cursorPlotPosition: cursorPos - _plotArea.topLeft,
        plotArea: _plotArea,
        transform: transform,
        elements: _elements,
        axisInfo: _buildMultiAxisInfo(),
        origin: origin,
        includeTrends: true,
        interpolateValues: false,
        dataRevision: _trackingDataRevision,
      );
    }

    _valueSummaryUsedSharedResolver = true;
    // The synchronized-position snapshot was resolved with the crosshair's
    // interpolation preference; reuse it unless the summary wants data
    // points while that preference interpolates (in which case the divergent
    // branch above already ran — a retained sync snapshot here is always
    // compatible, but keep the guard explicit).
    final syncSnapshot = _syncPositionSnapshot;
    if ((!wantsDataPoints || !crosshair.interpolateValues) &&
        _synchronizedCursorPosition != null &&
        syncSnapshot != null &&
        identical(syncSnapshot, _trackingSnapshotResolver.current)) {
      return syncSnapshot;
    }
    return _resolveTrackingSnapshot(
      cursorPosition: cursorPos,
      origin: origin,
      interpolateValues: wantsDataPoints ? false : crosshair.interpolateValues,
    );
  }

  /// Whether the crosshair itself resolves the shared pointer-path tracking
  /// snapshot this frame: enabled and in tracking mode for the current data
  /// density, including the synchronized-cursor override that forces
  /// tracking mode.
  bool _crosshairConsumesSharedTracking(CrosshairConfig crosshair) {
    final effective = _effectiveCrosshairConfig(crosshair);
    if (!effective.enabled) return false;
    return effective.shouldUseTrackingMode(
      CrosshairTracker.getTotalPointCount([
        for (final element in _elements)
          if (element is SeriesElement) element.series,
      ]),
    );
  }

  /// The value summary's policy-resolved snapshot behind the displayed
  /// content (its origin distinguishes tracking, pinned, and fallback).
  @visibleForTesting
  CartesianTrackingSnapshot? get debugValueSummarySnapshot =>
      _valueSummaryCoordinator.debugReducedSnapshot;

  /// The value summary's displayed content model, or null while hidden.
  @visibleForTesting
  CartesianValueSummaryContentModel? get debugValueSummaryModel =>
      _valueSummaryCoordinator.debugModel;

  /// Number of value summary reduce+adapt executions. Repaints with
  /// unchanged inputs must not increment this.
  @visibleForTesting
  int get debugValueSummaryReduceCount =>
      _valueSummaryCoordinator.debugReduceCount;

  /// The summary panel's last painted bounds ([Rect.zero] while hidden).
  @visibleForTesting
  Rect get debugValueSummaryBounds =>
      _valueSummaryCoordinator.debugOverlayBounds;

  /// Total resolve calls on the summary's dedicated divergent-mode tracking
  /// resolver. Stays zero while every configuration is compatible with the
  /// shared pointer-path resolution.
  @visibleForTesting
  int get debugSummaryTrackingResolveCount =>
      _summaryTrackingResolver.debugResolveCount;

  /// Actual computations on the dedicated divergent-mode resolver
  /// (input-cache misses). Stationary repaints must not increment this.
  @visibleForTesting
  int get debugSummaryTrackingComputeCount =>
      _summaryTrackingResolver.debugComputeCount;

  /// Published snapshot changes on the dedicated divergent-mode resolver —
  /// one per snapped-datum change, never per cursor pixel or repaint.
  @visibleForTesting
  int get debugSummaryTrackingPublishCount =>
      _summaryTrackingResolver.debugPublishCount;

  /// The current plot area rectangle, for widget tests.
  @visibleForTesting
  Rect get debugPlotArea => _plotArea;

  /// The laid-out horizontal scrollbar bounds, for interaction ownership
  /// tests. The bounds are chart-local and null while the scrollbar is hidden.
  @visibleForTesting
  Rect? get debugXScrollbarRect => _scrollbarManager.xScrollbarRect;

  /// The laid-out vertical scrollbar bounds, for interaction ownership tests.
  /// The bounds are chart-local and null while the scrollbar is hidden.
  @visibleForTesting
  Rect? get debugYScrollbarRect => _scrollbarManager.yScrollbarRect;

  // ==========================================================================
  // Value summary annotation drag + keyboard surface
  // ==========================================================================

  /// The draggable annotation-style summary panel, or null when inactive.
  ValueSummaryAnnotationElement? get valueSummaryDragTarget =>
      _valueSummaryCoordinator.annotationDragTarget;

  /// Captures pre-drag state when `EventHandlerManager` engages a drag.
  void beginValueSummaryDrag() =>
      _valueSummaryCoordinator.beginAnnotationDrag();

  /// Live drag preview for the panel top-left (plot-local); repaints the
  /// feedback layer only.
  void updateValueSummaryDrag(Offset panelOriginPlot) =>
      _valueSummaryCoordinator.updateAnnotationDragOrigin(panelOriginPlot);

  /// Commits an engaged drag: clamp (when configured) and exactly one
  /// `onPlacementChanged`.
  void commitValueSummaryDrag() =>
      _valueSummaryCoordinator.commitAnnotationDrag();

  /// Abandons an engaged drag without committing.
  void cancelValueSummaryDrag() =>
      _valueSummaryCoordinator.cancelAnnotationDrag();

  /// Grants or clears the summary panel's keyboard focus.
  ///
  /// Returns whether the focus state actually changed. The semantics tree
  /// is only re-flushed on real transitions, so the per-pointer-down calls
  /// from `EventHandlerManager` stay free while focus is steady.
  bool setValueSummaryFocus(bool focused) {
    final changed = _valueSummaryCoordinator.setAnnotationFocus(focused);
    if (changed) markNeedsSemanticsUpdate();
    return changed;
  }

  /// Handles a key event for the focused, draggable summary panel.
  ///
  /// Called by the chart widget's `Focus.onKeyEvent` chain before any other
  /// keyboard handling. Arrow keys move the panel by 1 logical pixel (10
  /// with Shift) on key-down/repeat; the accumulated movement is committed
  /// through `onPlacementChanged` exactly once on the arrow's key-up. Escape
  /// restores the configured placement (emitting it) and releases focus.
  ///
  /// Returns true when the event was consumed.
  bool handleValueSummaryKeyEvent(KeyEvent event) {
    final coordinator = _valueSummaryCoordinator;
    if (!coordinator.annotationFocused ||
        coordinator.annotationDragTarget == null) {
      return false;
    }

    final key = event.logicalKey;
    final isArrow =
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown;

    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (key == LogicalKeyboardKey.escape) {
        coordinator.resetAnnotationPlacement(emit: true);
        setValueSummaryFocus(false);
        return true;
      }
      if (!isArrow) return false;
      final step = HardwareKeyboard.instance.isShiftPressed ? 10.0 : 1.0;
      final delta = switch (key) {
        LogicalKeyboardKey.arrowLeft => Offset(-step, 0),
        LogicalKeyboardKey.arrowRight => Offset(step, 0),
        LogicalKeyboardKey.arrowUp => Offset(0, -step),
        _ => Offset(0, step),
      };
      coordinator.nudgeAnnotation(delta);
      return true;
    }

    if (event is KeyUpEvent && isArrow) {
      coordinator.commitKeyboardNudge();
      return true;
    }

    return false;
  }

  /// The cached series-layer picture, for zero-invalidation proofs: the
  /// instance must stay identical across hover/tracking frames.
  @visibleForTesting
  ui.Picture? get debugSeriesCachePicture => _seriesCacheManager.cachedPicture;

  @visibleForTesting
  bool get debugSelectionBrushKeyboardFocused => _selectionBrushKeyboardFocused;

  /// Records only the persistent-brush overlay for focused performance tests.
  @visibleForTesting
  void debugPaintPersistentSelectionBrush(Canvas canvas) =>
      _paintPersistentSelectionBrush(canvas);

  // ==========================================================================
  // Value summary semantics
  // ==========================================================================

  /// Semantic move step for one custom move action, matching the
  /// Shift+arrow keyboard step.
  static const double _valueSummarySemanticMoveStep = 10;

  static const CustomSemanticsAction _valueSummaryMoveLeftAction =
      CustomSemanticsAction(label: 'Move left');
  static const CustomSemanticsAction _valueSummaryMoveRightAction =
      CustomSemanticsAction(label: 'Move right');
  static const CustomSemanticsAction _valueSummaryMoveUpAction =
      CustomSemanticsAction(label: 'Move up');
  static const CustomSemanticsAction _valueSummaryMoveDownAction =
      CustomSemanticsAction(label: 'Move down');
  static const CustomSemanticsAction _valueSummaryResetPositionAction =
      CustomSemanticsAction(label: 'Reset position');
  static const CustomSemanticsAction _valueSummaryPinAction =
      CustomSemanticsAction(label: 'Pin value');
  static const CustomSemanticsAction _valueSummaryClearPinAction =
      CustomSemanticsAction(label: 'Clear pin');

  static const double _selectionBrushKeyboardStep = 10;
  static const CustomSemanticsAction _selectionBrushMoveLowerAction =
      CustomSemanticsAction(label: 'Move interval lower');
  static const CustomSemanticsAction _selectionBrushMoveHigherAction =
      CustomSemanticsAction(label: 'Move interval higher');
  static const CustomSemanticsAction _selectionBrushLowerBoundLowerAction =
      CustomSemanticsAction(label: 'Decrease lower bound');
  static const CustomSemanticsAction _selectionBrushLowerBoundHigherAction =
      CustomSemanticsAction(label: 'Increase lower bound');
  static const CustomSemanticsAction _selectionBrushUpperBoundLowerAction =
      CustomSemanticsAction(label: 'Decrease upper bound');
  static const CustomSemanticsAction _selectionBrushUpperBoundHigherAction =
      CustomSemanticsAction(label: 'Increase upper bound');

  /// The semantics surface last observed at the end of a paint frame.
  ///
  /// Compared per paint (record value equality over cached references) so
  /// content, bounds, focus, or capability changes re-flush semantics at
  /// paint cadence without any per-frame string building.
  ValueSummarySemanticsInfo? _lastValueSummarySemantics;

  /// Re-flushes semantics when the summary's assistive surface changed.
  ///
  /// Called at the end of [paint], after the foreground element pass has
  /// finalized the panel bounds for this frame. Marking during paint is
  /// safe: the semantics flush runs after the paint flush in the same
  /// frame.
  void _updateValueSummarySemanticsDirty() {
    final info = _valueSummaryCoordinator.summarySemanticsInfo;
    if (info == _lastValueSummarySemantics) return;
    _lastValueSummarySemantics = info;
    markNeedsSemanticsUpdate();
  }

  /// Sends one debounced summary announcement (config `announceChanges`).
  ///
  /// Skipped entirely while no assistive technology has enabled semantics.
  void _announceValueSummary(String message) {
    if (owner?.semanticsOwner == null) return;
    RenderObject node = this;
    while (node.parent != null) {
      node = node.parent!;
    }
    if (node is! RenderView) return;
    SemanticsService.sendAnnouncement(
      node.flutterView,
      message,
      _textDirection,
    );
  }

  // ==========================================================================
  // Lifecycle
  // ==========================================================================

  /// Dispose of resources when render object is removed from tree.
  ///
  /// Properly disposes the cached Picture to free GPU memory.
  /// Critical to prevent memory leaks in long-running applications.
  @override
  void dispose() {
    for (final element in _elements.whereType<SeriesElement>()) {
      element.dispose();
    }
    _seriesCacheManager.dispose();
    _tooltipAnimator.dispose();
    _zoomAnimator.dispose();
    _scrollbarManager.dispose();
    _streamingManager.dispose();
    _annotationDragHandler.dispose();
    _eventHandlerManager.dispose();
    _valueSummaryCoordinator.dispose();
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
    final hoveredSeriesId = coordinator.hoveredElement is SeriesElement
        ? coordinator.hoveredElement!.id
        : null;

    // Replace elements
    _elements = elements;
    _seriesCacheManager.invalidate(); // Invalidate cache - data changed
    _restoreHoveredSeriesElement(hoveredSeriesId);

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
    markNeedsSemanticsUpdate();
  }

  /// Read-only element snapshot for diagnostics and interaction tests.
  @visibleForTesting
  List<ChartElement> get debugElements => List.unmodifiable(_elements);

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
    final boundsMatchWidgetProvided =
        _widgetProvidedXMin != null &&
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
    final boundsMatchWidgetProvided =
        _widgetProvidedYMin != null &&
        _widgetProvidedYMax != null &&
        axis != null &&
        _widgetProvidedYMin == axis.dataMin &&
        _widgetProvidedYMax == axis.dataMax;

    _yAxis = axis;

    // In per-series multi-axis mode, the widget-level Y axis is only the global
    // normalized transform carrier. Rebuilds must not rewrite the viewport Y range
    // from that axis, or Y zoom will snap back while X zoom stays intact.
    if (_multiAxisManager.isMultiAxisNormalizationActive()) {
      if (axis != null) {
        _widgetProvidedYMin = axis.dataMin;
        _widgetProvidedYMax = axis.dataMax;
      }

      if (_transform != null && _yAxis != null) {
        _yAxis!.updateDataRange(_transform!.dataYMin, _transform!.dataYMax);
        _seriesCacheManager.invalidate();
      }

      markNeedsLayout();
      return;
    }

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
    _invalidateTrackingResolution(); // Axis units feed snapshot formatting
    markNeedsLayout();
  }

  /// Sets the X-axis configuration (NEW XAxisConfig type).
  ///
  /// This is the modern [XAxisConfig] type with full feature support including
  /// crosshairLabelPosition. It's used directly by rendering components like
  /// CrosshairRenderer, bypassing legacy conversion.
  ///
  /// When both legacy xAxis (chart_axis.Axis) and xAxisConfig are provided,
  /// xAxisConfig takes precedence for configuration properties.
  void setXAxisConfig(XAxisConfig? config) {
    if (_xAxisConfig == config) return;
    _xAxisConfig = config;
    _categoricalViewportAppliedFor = null;
    // Category labels affect both axis reservation and the initial viewport.
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
    _invalidateTrackingResolution(); // Tracked colors may resolve differently
    markNeedsPaint();
  }

  /// Updates grid configuration.
  void setGridConfig(GridConfig? config) {
    if (_gridConfig == config) return;
    _gridConfig = config;
    markNeedsPaint();
  }

  /// Updates tooltip visibility.
  void setTooltipsEnabled(bool enabled) {
    if (_tooltipsEnabled == enabled) return;
    _tooltipsEnabled = enabled;
    markNeedsPaint();
  }

  /// Updates the datum whose tooltip follows durable chart selection.
  void setSelectedTooltipPoint({String? seriesId, int? pointIndex}) {
    if (_selectedTooltipSeriesId == seriesId &&
        _selectedTooltipPointIndex == pointIndex) {
      return;
    }
    final removedSelection =
        _selectedTooltipSeriesId != null && seriesId == null;
    _selectedTooltipSeriesId = seriesId;
    _selectedTooltipPointIndex = pointIndex;
    if (removedSelection) {
      _eventHandlerManager.clearTappedMarker();
      _tooltipAnimator.hideImmediately();
    }
    markNeedsPaint();
  }

  HoveredMarkerInfo? _resolveSelectedTooltipMarker() {
    final seriesId = _selectedTooltipSeriesId;
    final pointIndex = _selectedTooltipPointIndex;
    if (seriesId == null || pointIndex == null) return null;
    for (final element in _elements.whereType<DataHitElement>()) {
      if (element.id != seriesId) continue;
      final hit = element.dataHitForPointIndex(pointIndex);
      if (hit == null) return null;
      return HoveredMarkerInfo(
        seriesId: hit.seriesId,
        markerIndex: hit.pointIndex,
        plotPosition: hit.plotPosition,
        dataHit: hit,
      );
    }
    return null;
  }

  /// Current geometry-resolved selected tooltip marker for widget tests.
  @visibleForTesting
  HoveredMarkerInfo? get debugSelectedTooltipMarker =>
      _resolveSelectedTooltipMarker();

  /// Bounds of the most recently painted tooltip surface.
  @visibleForTesting
  Rect? get debugTooltipRect => _debugTooltipRect;

  /// Current tap-pinned tooltip marker for widget tests.
  @visibleForTesting
  HoveredMarkerInfo? get debugTappedTooltipMarker =>
      _eventHandlerManager.tappedMarker;

  /// Dismisses a tap-pinned data-point tooltip independently of selection.
  ///
  /// Persistent selection brushes and durable selected data are intentionally
  /// left untouched.
  bool dismissTapPinnedTooltip() => _eventHandlerManager.clearTappedMarker();

  /// Current tooltip opacity for animation lifecycle tests.
  @visibleForTesting
  double get debugTooltipOpacity => _tooltipAnimator.opacity;

  /// Marker currently owned by the tooltip animator for widget tests.
  @visibleForTesting
  HoveredMarkerInfo? get debugTooltipTargetMarker =>
      _tooltipAnimator.getTargetMarker<HoveredMarkerInfo>();

  /// Updates interaction configuration.
  void setInteractionConfig(InteractionConfig? config) {
    // The value summary controller and placement callback are excluded from
    // config equality, so they must be (re)attached by reference before the
    // equality early-return below.
    _valueSummaryCoordinator.attachController(config?.valueSummary.controller);
    _valueSummaryCoordinator.onPlacementChanged =
        config?.valueSummary.onPlacementChanged;
    if (_interactionConfig == config) return;
    _interactionConfig = config;
    markNeedsPaint();
    // The value summary annotation panel contributes a semantics node whose
    // presence depends on this config.
    markNeedsSemanticsUpdate();
  }

  /// Updates whether ambient reduced-motion preferences disable transitions.
  void setDisableAnimations(bool disableAnimations) {
    if (_disableAnimations == disableAnimations) return;
    _disableAnimations = disableAnimations;
    if (_disableAnimations) {
      final targetMarker = _tooltipAnimator
          .getTargetMarker<HoveredMarkerInfo>();
      if (targetMarker == null) {
        _tooltipAnimator.hideImmediately();
      } else {
        _tooltipAnimator.show(
          targetMarker,
          const TooltipConfig(showDelay: Duration.zero),
          animate: false,
        );
      }
    }
    markNeedsPaint();
  }

  /// Updates the durable data-domain state used to paint the interval brush.
  void setSelectionBrushState(ChartSelectionBrushState? state) {
    if (_selectionBrushState == state) return;
    _selectionBrushState = state;
    // A controller/keyboard brush mutation can move the durable range without
    // producing a pointer gesture in EventHandlerManager. Do not retain a
    // tap-pinned datum whose membership may have changed underneath it.
    _eventHandlerManager.clearTappedMarker();
    coordinator.setHoveredMarker(null);
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// Updates whether the chart's keyboard focus currently belongs to its
  /// persistent interval brush.
  void setSelectionBrushKeyboardFocused(bool focused) {
    if (_selectionBrushKeyboardFocused == focused) return;
    _selectionBrushKeyboardFocused = focused;
    if (!focused) {
      _selectionBrushKeyboardTarget = _SelectionBrushKeyboardTarget.body;
    }
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// Updates canvas text scaling for tooltip content.
  void setTextScaleFactor(double value) {
    if (_textScaleFactor == value) return;
    _textScaleFactor = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// Updates the ambient reading direction used by chart-owned text.
  void setTextDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  // ==================== MULTI-AXIS SETTERS ====================

  /// Sets the normalization mode for multi-axis charts.
  ///
  /// Delegates to [MultiAxisManager.setNormalizationMode].
  void setNormalizationMode(NormalizationMode? mode) {
    if (_multiAxisManager.setNormalizationMode(mode)) {
      _seriesCacheManager.invalidate();
      _invalidateTrackingResolution();
      markNeedsLayout();
      markNeedsPaint();
    }
  }

  /// Sets the data series for multi-axis color resolution.
  ///
  /// Delegates to [MultiAxisManager.setSeries].
  void setSeries(List<ChartSeries>? series) {
    if (_multiAxisManager.setSeries(series)) {
      _seriesCacheManager.invalidate();
      _invalidateTrackingResolution();
      markNeedsLayout();
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
      primaryYAxis: _primaryYAxisConfig,
    );
  }

  bool get _isHorizontalBarChart {
    final series = _multiAxisManager.series;
    return series.isNotEmpty &&
        series.every(
          (current) =>
              current is BarChartSeries &&
              current.orientation == BarOrientation.horizontal,
        );
  }

  TransposedBarAxesPainter _buildTransposedAxesPainter() {
    final categoryConfig = _xAxisConfig ?? const XAxisConfig();
    final valueAxes = _multiAxisManager.getVisibleAxes();
    final axisBounds = _computeAxisBounds(forPainting: true);
    final labelStyle =
        _theme?.axisStyle.labelStyle ??
        const TextStyle(fontSize: 12.0, color: ui.Color(0xFF000000));
    return TransposedBarAxesPainter(
      categoryConfig: categoryConfig,
      categoryBounds: DataRange(
        min: _transform?.dataXMin ?? _xAxis?.dataMin ?? 0,
        max: _transform?.dataXMax ?? _xAxis?.dataMax ?? 1,
      ),
      valueAxes: valueAxes,
      valueBounds: axisBounds,
      labelStyle: labelStyle,
      bindings: _getEffectiveBindings(),
      series: _multiAxisManager.series,
      categoryTickValues: _xAxis?.ticks.map((tick) => tick.value).toList(),
      textDirection: _textDirection,
    );
  }

  XAxisPainter _buildXAxisPainter({DataRange? bounds}) {
    final labelStyle =
        _theme?.axisStyle.labelStyle ??
        const TextStyle(fontSize: 12.0, color: ui.Color(0xFF000000));
    return XAxisPainter(
      config: _xAxisConfig ?? const XAxisConfig(),
      axisBounds:
          bounds ??
          DataRange(
            min: _transform?.dataXMin ?? _xAxis?.dataMin ?? 0,
            max: _transform?.dataXMax ?? _xAxis?.dataMax ?? 1,
          ),
      labelStyle: labelStyle,
      series: _multiAxisManager.series,
      tickValues: _xAxis?.ticks.map((tick) => tick.value).toList(),
      textDirection: _textDirection,
    );
  }

  void _applyInitialCategoricalViewport() {
    final config = _xAxisConfig;
    final categoryAxis = config?.categoryAxis;
    if (config == null ||
        categoryAxis == null ||
        categoryAxis.categories.isEmpty ||
        !categoryAxis.autoViewport ||
        _categoricalViewportAppliedFor == config ||
        _transform == null) {
      return;
    }

    _categoricalViewportAppliedFor = config;
    final screenExtent = _isHorizontalBarChart
        ? _plotArea.height
        : _plotArea.width;
    final visibleCategoryCount = math.max(
      1,
      (screenExtent / categoryAxis.minimumCategoryExtent).floor(),
    );
    if (visibleCategoryCount >= categoryAxis.categories.length) return;

    _transform = _transform!.copyWith(
      dataXMin: categoryAxis.domainMin,
      dataXMax: categoryAxis.domainMin + visibleCategoryCount,
    );
    _updateAxesFromTransform();
  }

  /// Paints multiple Y-axes using [MultiAxisPainter].
  ///
  /// Delegates to [MultiAxisManager.paintMultipleYAxes].
  void _paintMultipleYAxes(Canvas canvas) {
    _multiAxisManager.paintMultipleYAxes(
      canvas: canvas,
      size: size,
      plotArea: _plotArea,
      labelStyle: _theme?.axisStyle.labelStyle,
      transform: _transform,
      originalTransform: _originalTransform,
    );
  }

  /// Computes axis bounds from series data for multi-axis rendering.
  ///
  /// Delegates to [MultiAxisManager.computeAxisBounds].
  ///
  /// [forceFullBounds]: If true, returns full data bounds without viewport
  /// transformation.
  /// [forPainting]: When true AND viewport is zoomed, returns bounds that match
  /// the visible portion of data. Used for series rendering transforms.
  Map<String, DataRange> _computeAxisBounds({
    bool forceFullBounds = false,
    bool forPainting = false,
  }) {
    return _multiAxisManager.computeAxisBounds(
      transform: _transform,
      originalTransform: _originalTransform,
      forceFullBounds: forceFullBounds,
      forPainting: forPainting,
    );
  }

  /// Computes Y-bounds for each series by series ID.
  ///
  /// Used for threshold annotations with perSeries normalization mode.
  /// Delegates to [MultiAxisManager.computeSeriesBounds].
  Map<String, DataRange> _computeSeriesBounds({bool forPainting = false}) {
    return _multiAxisManager.computeSeriesBounds(
      transform: _transform,
      originalTransform: _originalTransform,
      forPainting: forPainting,
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
    double xMin,
    double xMax,
    double yMin,
    double yMax,
  ) {
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
  void zoomChart(
    double factor, {
    Offset? plotCenter,
    bool animate = true,
    bool finalize = true,
  }) {
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
      if (finalize) _onZoomAnimationComplete();
    }
  }

  /// Callback invoked on each frame of zoom animation.
  void _onZoomAnimationUpdate(ChartTransform transform) {
    _transform = transform;
    _updateAxesFromTransform();
    _scrollbarManager.showScrollbarsAndScheduleHide();
    markNeedsPaint();
    onViewportChanged?.call();
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
    onViewportChanged?.call();
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
    onViewportChanged?.call();

    // [DEBUG OUTPUT REMOVED] Pan constrained/applied - fires frequently during dragging
  }

  /// Reset view to original zoom/pan state.
  void resetView() {
    if (_originalTransform == null || _elementGenerator == null) {
      return;
    }

    // Restore original data ranges, preserve current plot dimensions
    _transform = _originalTransform!.copyWith(
      plotWidth: _plotArea.width,
      plotHeight: _plotArea.height,
    );

    // Update axes to reflect reset viewport
    _updateAxesFromTransform();

    // Regenerate elements
    _rebuildElementsWithTransform();

    // Invalidate cache - transform reset to original
    _seriesCacheManager.invalidate();
    markNeedsPaint();
    onViewportChanged?.call();
  }

  /// Updates the data bounds for streaming data that extends beyond original range.
  ///
  /// Called when streaming data expands the data range, allowing pan constraints
  /// to permit panning to the new data regions.
  void updateDataBounds(
    double dataXMin,
    double dataXMax,
    double dataYMin,
    double dataYMax,
  ) {
    if (_originalTransform == null) return;

    // DO NOT update _originalTransform here - it must stay frozen at initial data range
    // for scrollbar handle sizing to work correctly. Updating it causes the scrollbar
    // handle to always show full size because dataSpan == viewportSpan after update.
    //
    // TODO: Create separate _fullDataTransform field for pan constraints that can be
    // updated with expanded data range, while keeping _originalTransform frozen.

    // Update current transform so viewport shows the new data. copyWith on the
    // existing transform preserves invertY, transposed AND the per-axis scale
    // fields (scaleType/logBase); without it a streaming range expansion would
    // revert a log/time chart to linear positioning.
    final source = _transform;
    _transform = source != null
        ? source.copyWith(
            plotWidth: _plotArea.width,
            plotHeight: _plotArea.height,
            dataXMin: dataXMin,
            dataXMax: dataXMax,
            dataYMin: dataYMin,
            dataYMax: dataYMax,
          )
        : ChartTransform(
            plotWidth: _plotArea.width,
            plotHeight: _plotArea.height,
            dataXMin: dataXMin,
            dataXMax: dataXMax,
            dataYMin: dataYMin,
            dataYMax: dataYMax,
            invertY: false,
            transposed: _isHorizontalBarChart,
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
    double requestedPlotDx,
    double requestedPlotDy,
  ) {
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
      widgetPosition.dx - _plotArea.left,
      widgetPosition.dy - _plotArea.top,
    );
  }

  /// Converts plot coordinates to widget coordinates.
  ///
  /// Inverse of widgetToPlot().
  Offset plotToWidget(Offset plotPosition) {
    return Offset(
      plotPosition.dx + _plotArea.left,
      plotPosition.dy + _plotArea.top,
    );
  }

  /// Transfers the active direct-touch sequence from raw chart interaction to
  /// viewport navigation.
  void beginViewportTransform() {
    _eventHandlerManager.beginViewportTransform();
    _publishCrosshairChange(null);
    onDataXCursorChanged?.call(null);
  }

  /// Claims the active touch sequence for transient tracking inspection.
  double? beginTouchTracking(Offset widgetPosition) {
    if (!_plotArea.contains(widgetPosition)) return null;
    _eventHandlerManager.beginTouchTracking(widgetPosition);
    return _publishTouchTrackingPosition(widgetPosition);
  }

  /// Moves transient touch tracking and returns the snapped X observation.
  double? updateTouchTrackingPosition(Offset widgetPosition) {
    _eventHandlerManager.updateTouchTrackingPosition(widgetPosition);
    return _publishTouchTrackingPosition(widgetPosition);
  }

  double? _publishTouchTrackingPosition(Offset widgetPosition) {
    final snapPoints = _publishCrosshairChange(widgetPosition);
    final transform = _transform;
    if (transform != null && _plotArea.contains(widgetPosition)) {
      final plotPosition = widgetToPlot(widgetPosition);
      onDataXCursorChanged?.call(
        transform.plotToData(plotPosition.dx, plotPosition.dy).dx,
      );
    }
    return snapPoints.isEmpty ? null : snapPoints.first.x;
  }

  /// Ends transient touch tracking without committing selection.
  void endTouchTracking() {
    clearCursorPosition();
  }

  /// Rebuilds the QuadTree spatial index from current elements.
  ///
  /// QuadTree operates in PLOT space (0,0 → plotWidth,plotHeight).
  void _rebuildSpatialIndex() {
    // Elements are being replaced; tracked series data may have changed.
    _invalidateTrackingResolution();

    if (!hasSize || _plotArea.isEmpty) {
      return;
    }

    // QuadTree bounds = plot area (in plot space, not widget space)
    _spatialIndex = QuadTree(
      bounds: Offset.zero & _plotArea.size,
      maxElementsPerNode: 4,
      maxDepth: 8,
    );

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
        final handleElements = element
            .createResizeHandleElements()
            .cast<ResizeHandleElement>();
        allElements.addAll(handleElements);
        generatedHandles.addAll(handleElements);
      }
      // Legacy support for SimulatedAnnotation (test class)
      else if (element is SimulatedAnnotation && element.isResizable) {
        final handleElements = element
            .createResizeHandleElements()
            .cast<ResizeHandleElement>();
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
      return;
    }
    _debugElementRebuildCount++;

    // Preserve selection state: get IDs of currently selected elements
    final selectedIds = coordinator.selectedElements.map((e) => e.id).toSet();
    final hoveredSeriesId = coordinator.hoveredElement is SeriesElement
        ? coordinator.hoveredElement!.id
        : null;

    // Generate new elements using current transform
    _elements = generator(transform);
    _restoreHoveredSeriesElement(hoveredSeriesId);

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
    markNeedsSemanticsUpdate();
  }

  void _restoreHoveredSeriesElement(String? seriesId) {
    if (seriesId == null) return;
    SeriesElement? replacement;
    for (final element in _elements.whereType<SeriesElement>()) {
      if (element.id == seriesId) {
        replacement = element;
        break;
      }
    }
    coordinator.setHoveredElement(replacement);
    if (!(_interactionConfig?.selection.scope.includesWholeSeries ?? false)) {
      replacement?.onHoverExit();
    }
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
          : Size(
              constraints.hasBoundedWidth ? constraints.maxWidth : 800,
              constraints.hasBoundedHeight ? constraints.maxHeight : 600,
            ),
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
      bottomReserved =
          scrollbarTheme.thickness +
          (scrollbarPadding * 2); // Padding above and below scrollbar
    }

    // Calculate plot area (reserve space for axes AND scrollbars)
    // Default margins if no axes
    double leftMargin = _axislessInsets.left;
    double rightMargin =
        _axislessInsets.right + rightReserved; // Add scrollbar space
    double topMargin = _axislessInsets.top;
    double bottomMargin =
        _axislessInsets.bottom + bottomReserved; // Add scrollbar space
    double xAxisReservedHeight = 50;

    // Track right axis width separately for scrollbar positioning
    double rightAxisWidth = 0;

    if (_isHorizontalBarChart) {
      final axesPainter = _buildTransposedAxesPainter();
      leftMargin = axesPainter.measureCategoryAxisWidth();
      topMargin = math.max(10, axesPainter.measureTopAxesHeight());
      bottomMargin =
          math.max(10, axesPainter.measureBottomAxesHeight()) + bottomReserved;
    } else {
      // MULTI-AXIS: Compute axis widths using the multi-axis system for ALL Y-axes
      // This ensures consistent layout whether using single or multiple axes.
      // Previously, single-axis mode used a hardcoded 60px margin which caused
      // gaps between the Y-axis and the plot area.
      final effectiveAxes = _yAxis == null
          ? const <YAxisConfig>[]
          : _getEffectiveYAxes();
      if (effectiveAxes.isNotEmpty) {
        final axisBounds = _computeAxisBounds();
        final axisWidths = _multiAxisManager.computeAxisWidths(
          axisBounds: axisBounds,
        );
        final totalLeftWidth = _multiAxisManager.getTotalLeftAxisWidth(
          axisWidths,
        );
        rightAxisWidth = _multiAxisManager.getTotalRightAxisWidth(axisWidths);
        leftMargin = totalLeftWidth > 0 ? totalLeftWidth : leftMargin;
        if (rightAxisWidth > 0) {
          rightMargin = rightAxisWidth + rightReserved;
        }
      }

      // Category labels may wrap or rotate, so reserve their measured height
      // instead of relying on the legacy fixed 50px axis gutter.
      if (_xAxis != null && (_xAxisConfig?.visible ?? true)) {
        final estimatedPlotWidth = math.max(
          1.0,
          size.width - leftMargin - rightMargin,
        );
        final xAxisPainter = _buildXAxisPainter(
          bounds: DataRange(min: _xAxis!.dataMin, max: _xAxis!.dataMax),
        );
        xAxisReservedHeight = math.max(
          50.0,
          xAxisPainter.measureRequiredHeight(estimatedPlotWidth),
        );
        final xAxisPosition = _xAxisConfig?.position ?? XAxisPosition.bottom;
        if (xAxisPosition == XAxisPosition.top ||
            xAxisPosition == XAxisPosition.both) {
          final topAxisReservedHeight = xAxisPosition == XAxisPosition.both
              ? math.max(
                  50.0,
                  xAxisPainter.measureRequiredHeight(
                    estimatedPlotWidth,
                    includeAxisTitle: false,
                  ),
                )
              : xAxisReservedHeight;
          topMargin = math.max(topMargin, topAxisReservedHeight);
        }
        if (xAxisPosition == XAxisPosition.bottom ||
            xAxisPosition == XAxisPosition.both) {
          bottomMargin = xAxisReservedHeight + bottomReserved;
        }
      }
    }

    // Calculate plot area (chart canvas excluding axes and scrollbars)
    _plotArea = Rect.fromLTRB(
      leftMargin,
      topMargin,
      size.width - rightMargin,
      size.height - bottomMargin,
    );

    // Calculate scrollbar rectangles if enabled
    Rect? xScrollbarRect;
    Rect? yScrollbarRect;

    if (_scrollbarManager.showXScrollbar) {
      // A top X-axis leaves the lower gutter entirely to the scrollbar.
      // Transposed charts retain their existing bottom value-axis extent.
      final xAxisExtentBelowPlot =
          _isHorizontalBarChart ||
              (_xAxis != null &&
                  (_xAxisConfig?.visible ?? true) &&
                  {
                    XAxisPosition.bottom,
                    XAxisPosition.both,
                  }.contains(_xAxisConfig?.position ?? XAxisPosition.bottom))
          ? xAxisReservedHeight
          : 0.0;
      final scrollbarTop =
          _plotArea.bottom + xAxisExtentBelowPlot + scrollbarPadding;
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
      xRect: xScrollbarRect,
      yRect: yScrollbarRect,
    );

    // Update axis pixel ranges to match plot area
    _xAxis?.updatePixelRange(_plotArea.left, _plotArea.right);
    _yAxis?.updatePixelRange(_plotArea.top, _plotArea.bottom);

    // Create/update coordinate transform
    // Transform handles Data ↔ Plot conversion based on axis data ranges
    if (_xAxis != null && _yAxis != null) {
      final currentBaseXMin = _widgetProvidedXMin ?? _xAxis!.dataMin;
      final currentBaseXMax = _widgetProvidedXMax ?? _xAxis!.dataMax;
      final currentBaseYMin = _widgetProvidedYMin ?? _yAxis!.dataMin;
      final currentBaseYMax = _widgetProvidedYMax ?? _yAxis!.dataMax;

      // Detect if data range has fundamentally changed (different chart/dataset)
      // This handles the case where Flutter reuses the same RenderBox instance
      // when switching between charts (e.g., Athletic → Test → Scientific)
      final bool rangeChanged =
          _layoutBaseXMin != null &&
          _layoutBaseXMax != null &&
          ((currentBaseXMin - _layoutBaseXMin!).abs() > 10 ||
              (currentBaseXMax - _layoutBaseXMax!).abs() > 10);

      // Create initial transform if none exists OR if data range has significantly changed
      if (_transform == null ||
          rangeChanged ||
          _transform!.transposed != _isHorizontalBarChart) {
        // First time OR range changed: create transform from the widget-provided
        // baseline viewport when available. Axis instances may already have been
        // synchronized to a transient viewport, but reset/original state must stay
        // anchored to the resolved chart bounds from the widget layer.
        _transform = ChartTransform(
          dataXMin: currentBaseXMin,
          dataXMax: currentBaseXMax,
          dataYMin: currentBaseYMin,
          dataYMax: currentBaseYMax,
          plotWidth: _plotArea.width,
          plotHeight: _plotArea.height,
          invertY: true, // Standard chart convention (Y=0 at bottom)
          transposed: _isHorizontalBarChart,
          xScaleType: _xAxis!.scaleType,
          xLogBase: _xAxis!.logBase,
          yScaleType: _yAxis!.scaleType,
          yLogBase: _yAxis!.logBase,
        );

        // Capture original transform for reset and constraint calculations
        // CRITICAL: Use copyWith() to create a deep copy, not a reference
        // Otherwise both variables point to same object and zoom breaks scrollbar handle sizing
        _originalTransform = _transform!.copyWith();
        _layoutBaseXMin = currentBaseXMin;
        _layoutBaseXMax = currentBaseXMax;

        _applyInitialCategoricalViewport();

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
            plotWidth: _plotArea.width,
            plotHeight: _plotArea.height,
          );
          // Rebuild series paths and spatial index when the canvas resizes
          if (_elementGenerator != null) {
            _rebuildElementsWithTransform();
            _seriesCacheManager.invalidate();
          }
        }
      }
    } else if (_elementGenerator != null) {
      // Radial layouts do not have Cartesian axes, but their element generator
      // still needs the resolved plot dimensions. Keep a neutral transform as
      // the render-box sizing contract without exposing axes or data scaling.
      final needsAxislessTransform =
          _transform == null ||
          _transform!.dataXMin != 0 ||
          _transform!.dataXMax != 1 ||
          _transform!.dataYMin != 0 ||
          _transform!.dataYMax != 1 ||
          _transform!.plotWidth != _plotArea.width ||
          _transform!.plotHeight != _plotArea.height;
      if (needsAxislessTransform) {
        _transform = ChartTransform(
          dataXMin: 0,
          dataXMax: 1,
          dataYMin: 0,
          dataYMax: 1,
          plotWidth: _plotArea.width,
          plotHeight: _plotArea.height,
          invertY: true,
        );
        _originalTransform = _transform!.copyWith();
        _rebuildElementsWithTransform();
        _seriesCacheManager.invalidate();
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
    // The draggable value summary annotation panel never enters _elements or
    // the spatial index; consult it explicitly first so it wins the hit
    // within its painted bounds (bounds-only hitTest) and can never steal a
    // hit anywhere else.
    final summaryPanel = _valueSummaryCoordinator.annotationDragTarget;
    if (summaryPanel != null &&
        summaryPanel.hitTest(widgetToPlot(widgetPosition))) {
      return summaryPanel;
    }

    // Lazily rebuild spatial index if marked dirty (deferred from click handlers)
    if (_spatialIndexDirty) {
      _rebuildSpatialIndex();
      _spatialIndexDirty = false;
    }
    if (_spatialIndex == null) return null;

    // Convert widget coordinates to plot coordinates
    final plotPosition = widgetToPlot(widgetPosition);
    final selection = _interactionConfig?.selection;
    final usesWholePathCorridor =
        (selection?.scope.includesWholeSeries ?? false) &&
        selection?.acquisitionMode == ChartSelectionAcquisitionMode.point;

    // In perSeries normalization mode, QuadTree bounds for SeriesElements are
    // incorrect because they were computed with the initial global transform.
    // We need to ensure transforms are updated and check ALL series elements
    // directly, bypassing the spatial index for series.
    final isPerSeriesMode = _multiAxisManager.isMultiAxisNormalizationActive();

    List<ChartElement> candidates;

    if (isPerSeriesMode) {
      // Get series elements directly and update their transforms
      final seriesElements = _elements.whereType<SeriesElement>().toList();
      _ensureSeriesTransformsUpdated(seriesElements.cast<ChartElement>());

      // Query spatial index for non-series elements (annotations, etc.)
      final nonSeriesCandidates = _spatialIndex!
          .query(plotPosition, radius: 18)
          .where((e) => e is! SeriesElement)
          .toList();

      // Combine: all series elements + spatially-nearby non-series elements
      candidates = [...seriesElements, ...nonSeriesCandidates];
    } else {
      // Standard mode: use spatial index normally
      candidates = _spatialIndex!.query(plotPosition, radius: 18);
      if (usesWholePathCorridor) {
        final pathSeries = _elements
            .whereType<SeriesElement>()
            .where(
              (element) =>
                  element.series is LineChartSeries ||
                  element.series is AreaChartSeries,
            )
            .toList();
        _ensureSeriesTransformsUpdated(pathSeries.cast<ChartElement>());
        candidates = <ChartElement>{...candidates, ...pathSeries}.toList();
      }
    }

    if (candidates.isEmpty) return null;

    // Filter to elements that pass precise hit test
    // Elements use plot coordinates, so pass plot position
    final hits = candidates.where((e) => e.hitTest(plotPosition)).toList();

    // Whole-series point selection deliberately exposes a wider invisible
    // corridor around Line and Area paths. Other acquisition modes retain
    // their precise hit geometry so a nearby path cannot steal an interval,
    // rectangle, or lasso drag.
    if (usesWholePathCorridor) {
      for (final candidate in candidates.whereType<SeriesElement>()) {
        if (hits.contains(candidate)) continue;
        final distance = candidate.pathHitDistance(plotPosition);
        if (distance != null &&
            distance <= selection!.completeSeriesHitRadius) {
          hits.add(candidate);
        }
      }
    }

    if (hits.isEmpty) return null;

    // Return highest priority element (highest priority = painted last = on top = should receive hits)
    // Within same priority, NON-Range annotations should be hit-tested first (they're on top)
    hits.sort((a, b) {
      // First, sort by priority (higher priority = painted last = on top = should be hit first)
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;

      if (a is DataSeriesElement && b is DataSeriesElement) {
        if (a is SeriesElement && b is SeriesElement) {
          final aDistance = a.pathHitDistance(plotPosition);
          final bDistance = b.pathHitDistance(plotPosition);
          if (aDistance != null && bDistance != null) {
            final distanceCompare = aDistance.compareTo(bDistance);
            if (distanceCompare != 0) return distanceCompare;
          }
        }
        return b.seriesIndex.compareTo(a.seriesIndex);
      }

      // Within same priority, RangeAnnotations should be hit-tested LAST (they're in back)
      final aIsRange = a is RangeAnnotationElement;
      final bIsRange = b is RangeAnnotationElement;

      if (aIsRange && !bIsRange) return 1; // b (non-Range) hit-tested first
      if (!aIsRange && bIsRange) return -1; // a (non-Range) hit-tested first

      return 0; // Equal priority and type
    });
    return hits.first;
  }

  /// Resolves primary-button annotation manipulation independently of the
  /// ordinary paint-order hit priority used for passive hover.
  ChartElement? hitTestAnnotationInteractionTarget(Offset widgetPosition) {
    if (_spatialIndexDirty) {
      _rebuildSpatialIndex();
      _spatialIndexDirty = false;
    }
    final plotPosition = widgetToPlot(widgetPosition);
    final hits = _elements.where((element) {
      final ownsAnnotationGesture =
          element is ResizeHandleElement ||
          (element.elementType == ChartElementType.annotation &&
              element.isDraggable);
      return ownsAnnotationGesture && element.hitTest(plotPosition);
    }).toList();
    if (hits.isEmpty) return null;
    hits.sort((a, b) {
      final aIsHandle = a is ResizeHandleElement;
      final bIsHandle = b is ResizeHandleElement;
      if (aIsHandle != bIsHandle) return aIsHandle ? -1 : 1;
      final renderOrder = b.renderOrder.compareTo(a.renderOrder);
      return renderOrder != 0 ? renderOrder : b.priority.compareTo(a.priority);
    });
    return hits.first;
  }

  /// Resolves one renderer-neutral datum from widget-local coordinates.
  ChartDataHit? dataHitAtWidgetPosition(
    Offset widgetPosition, {
    double maxDistance = 20,
  }) {
    final plotPosition = widgetToPlot(widgetPosition);
    final elements = _elements.whereType<DataHitElement>().toList()
      ..sort((a, b) {
        final priority = b.priority.compareTo(a.priority);
        return priority != 0
            ? priority
            : b.seriesIndex.compareTo(a.seriesIndex);
      });
    for (final element in elements) {
      final hit = element.dataHitAt(plotPosition, maxDistance: maxDistance);
      if (hit != null) return hit;
    }
    return null;
  }

  /// Resolves the nearest visible Line/Area datum owned by [seriesId].
  ///
  /// Normal hover hit testing still respects hidden marker configuration. This
  /// opt-in path is used only after the owning path itself won tap hit testing
  /// under mark-selection policy.
  ChartDataHit? nearestPathDataHitAtWidgetPosition(
    String seriesId,
    Offset widgetPosition,
  ) {
    final element = _elements
        .whereType<SeriesElement>()
        .where((candidate) => candidate.series.id == seriesId)
        .firstOrNull;
    if (element == null) return null;
    _ensureSeriesTransformsUpdated(<ChartElement>[element]);
    return element.nearestPathDataHitAt(widgetToPlot(widgetPosition));
  }

  /// Resolves the nearest Line or Area path inside [maxDistance].
  ///
  /// This is the direct-activation counterpart to the passive path hover
  /// corridor. It deliberately ignores point markers so a dual-target scope
  /// can try mark acquisition first, then fall back to exactly one series.
  String? nearestPathSeriesIdAtWidgetPosition(
    Offset widgetPosition, {
    required double maxDistance,
  }) {
    final plotPosition = widgetToPlot(widgetPosition);
    final candidates = _elements
        .whereType<SeriesElement>()
        .where(
          (element) =>
              element.series is LineChartSeries ||
              element.series is AreaChartSeries,
        )
        .toList();
    _ensureSeriesTransformsUpdated(candidates.cast<ChartElement>());

    SeriesElement? nearest;
    var nearestDistance = maxDistance;
    for (final candidate in candidates) {
      final distance = candidate.pathHitDistance(plotPosition);
      if (distance == null || distance > nearestDistance) continue;
      if (distance < nearestDistance ||
          nearest == null ||
          candidate.seriesIndex > nearest.seriesIndex) {
        nearest = candidate;
        nearestDistance = distance;
      }
    }
    return nearest?.series.id;
  }

  /// Resolves one visible datum by stable series ID and source point index.
  ChartDataHit? dataHitForPointIndex(String seriesId, int pointIndex) {
    for (final element in _elements.whereType<DataHitElement>()) {
      if (element.id != seriesId) continue;
      return element.dataHitForPointIndex(pointIndex);
    }
    return null;
  }

  /// Ensures SeriesElement transforms are updated before hit testing.
  ///
  /// In perSeries normalization mode, each series needs its own Y bounds
  /// in the transform. This is normally done during painting, but hit testing
  /// may occur before the current frame's paint (e.g., on pointer events).
  ///
  /// This method applies the same per-series transform logic used during
  /// painting, ensuring hit detection works correctly in normalized mode.
  void _ensureSeriesTransformsUpdated(List<ChartElement> candidates) {
    if (_transform == null) return;

    // Only need to update transforms in multi-axis normalization mode
    if (!_multiAxisManager.isMultiAxisNormalizationActive()) return;

    // Get axis bounds and series-to-axis mapping
    final axisBounds = _computeAxisBounds(forPainting: true);
    final effectiveBindings = _getEffectiveBindings();
    final seriesToAxisMap = {
      for (final binding in effectiveBindings)
        binding.seriesId: binding.yAxisId,
    };
    // Per-axis Y scale (log/linear), keyed by the same axis IDs as axisBounds.
    final axisConfigsById = {
      for (final axis in _getEffectiveYAxes()) axis.id: axis,
    };

    // Update transform for each SeriesElement candidate
    for (final element in candidates) {
      if (element is SeriesElement) {
        final axisId = seriesToAxisMap[element.id];
        if (axisId != null && axisBounds.containsKey(axisId)) {
          final axisRange = axisBounds[axisId]!;
          final axisConfig = axisConfigsById[axisId];
          final perSeriesTransform = _transform!.copyWith(
            dataYMin: axisRange.min,
            dataYMax: axisRange.max,
            yScaleType: axisConfig?.scaleType,
            yLogBase: axisConfig?.logBase,
          );
          element.updateTransform(perSeriesTransform);
        } else {
          element.updateTransform(_transform!);
        }
      }
    }
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
        .where(
          (e) =>
              e.elementType == ChartElementType.datapoint &&
              plotRect.contains(e.bounds.center),
        )
        .toList();
  }

  /// Resolves visible Cartesian data enclosed by a widget-space rectangle.
  List<ChartDataHit> dataHitsInWidgetRect(Rect widgetRect) {
    final plotRect = Rect.fromPoints(
      widgetToPlot(widgetRect.topLeft),
      widgetToPlot(widgetRect.bottomRight),
    );
    final seriesElements = _elements.whereType<SeriesElement>().toList(
      growable: false,
    );
    _ensureSeriesTransformsUpdated(seriesElements);
    return [
      for (final element in seriesElements)
        ...element.dataHitsInPlotRect(plotRect),
    ];
  }

  /// Resolves visible Cartesian data enclosed by a widget-space polygon.
  List<ChartDataHit> dataHitsInWidgetPolygon(List<Offset> widgetPolygon) {
    if (widgetPolygon.length < 3) return const [];
    final plotPolygon = [
      for (final point in widgetPolygon) widgetToPlot(point),
    ];
    final seriesElements = _elements.whereType<SeriesElement>().toList(
      growable: false,
    );
    _ensureSeriesTransformsUpdated(seriesElements);
    return [
      for (final element in seriesElements)
        ...element.dataHitsInPlotPolygon(plotPolygon),
    ];
  }

  /// Resolves one plot-space Y interval through every Cartesian series
  /// transform.
  ///
  /// Independent Y axes assign different data values to the same pixels.
  /// Durable Y-selection intent therefore records one targeted clause per
  /// series instead of applying the primary-axis values to every series.
  Map<String, ({double minimum, double maximum})> seriesYIntervalsForPlotRect(
    Rect plotRect,
  ) {
    if (plotRect.isEmpty) return const {};
    final elements = _elements.whereType<SeriesElement>().toList(
      growable: false,
    );
    _ensureSeriesTransformsUpdated(elements);
    return {
      for (final element in elements)
        element.series.id: (
          minimum: math.min(
            element.currentTransform.plotToData(plotRect.left, plotRect.top).dy,
            element.currentTransform
                .plotToData(plotRect.right, plotRect.bottom)
                .dy,
          ),
          maximum: math.max(
            element.currentTransform.plotToData(plotRect.left, plotRect.top).dy,
            element.currentTransform
                .plotToData(plotRect.right, plotRect.bottom)
                .dy,
          ),
        ),
    };
  }

  /// Resolves the current persistent brush into widget-space geometry.
  Rect? get selectionBrushWidgetRect {
    final state = _selectionBrushState;
    if (state == null || !state.visible) return null;
    return _selectionBrushWidgetRectForState(state);
  }

  /// Whether a widget-local pointer can manipulate the persistent brush.
  ///
  /// This is consumed by the widget-level touch recognizer so a brush body or
  /// handle owns its one-finger gesture before an ancestor scrollable can
  /// claim it.
  bool hitTestSelectionBrushInteraction(Offset position) =>
      _eventHandlerManager.hitTestSelectionBrushInteraction(position);

  Rect? _selectionBrushWidgetRectForState(
    ChartSelectionBrushState state, {
    bool clipToPlot = true,
  }) {
    if (_transform == null) return null;
    final plotRect = _selectionBrushPlotRect(state);
    if (plotRect == null) return null;
    final widgetRect = Rect.fromPoints(
      plotToWidget(plotRect.topLeft),
      plotToWidget(plotRect.bottomRight),
    );
    if (!clipToPlot) return widgetRect;
    final clipped = widgetRect.intersect(_plotArea);
    return clipped.isEmpty ? null : clipped;
  }

  Rect? _selectionBrushPlotRect(ChartSelectionBrushState state) {
    if (state.acquisitionMode == ChartSelectionAcquisitionMode.rectangle) {
      final box = state.box;
      if (box == null) return null;
      final transform = _selectionBrushReferenceTransform(
        box.referenceSeriesId,
      );
      if (transform == null) return null;
      final first = transform.dataToPlot(box.minimumX, box.minimumY);
      final second = transform.dataToPlot(box.maximumX, box.maximumY);
      return Rect.fromLTRB(
        math.min(first.dx, second.dx),
        math.min(first.dy, second.dy),
        math.max(first.dx, second.dx),
        math.max(first.dy, second.dy),
      );
    }
    final range = state.range;
    final transform =
        state.acquisitionMode == ChartSelectionAcquisitionMode.yInterval
        ? _selectionBrushReferenceTransform(range.referenceSeriesId)
        : _transform;
    if (transform == null) return null;
    final transposed = transform.transposed;
    if (state.acquisitionMode == ChartSelectionAcquisitionMode.xInterval) {
      final first = transform.dataToPlot(range.minimum, transform.dataYMin);
      final second = transform.dataToPlot(range.maximum, transform.dataYMin);
      return transposed
          ? Rect.fromLTRB(
              0,
              math.min(first.dy, second.dy),
              transform.plotWidth,
              math.max(first.dy, second.dy),
            )
          : Rect.fromLTRB(
              math.min(first.dx, second.dx),
              0,
              math.max(first.dx, second.dx),
              transform.plotHeight,
            );
    }
    final first = transform.dataToPlot(transform.dataXMin, range.minimum);
    final second = transform.dataToPlot(transform.dataXMin, range.maximum);
    return transposed
        ? Rect.fromLTRB(
            math.min(first.dx, second.dx),
            0,
            math.max(first.dx, second.dx),
            transform.plotHeight,
          )
        : Rect.fromLTRB(
            0,
            math.min(first.dy, second.dy),
            transform.plotWidth,
            math.max(first.dy, second.dy),
          );
  }

  ChartTransform? _selectionBrushReferenceTransform(String? seriesId) {
    final elements = _elements.whereType<SeriesElement>().toList(
      growable: false,
    );
    if (elements.isEmpty) return _transform;
    _ensureSeriesTransformsUpdated(elements);
    if (seriesId != null) {
      for (final element in elements) {
        if (element.series.id == seriesId) return element.currentTransform;
      }
      return null;
    }
    return elements.first.currentTransform;
  }

  /// Converts widget-space brush geometry back into its reference data range.
  ChartSelectionBrushRange? selectionBrushRangeForWidgetRect(
    Rect widgetRect, {
    required ChartSelectionAcquisitionMode acquisitionMode,
    String? referenceSeriesId,
  }) {
    final transform = acquisitionMode == ChartSelectionAcquisitionMode.yInterval
        ? _selectionBrushReferenceTransform(referenceSeriesId)
        : _transform;
    if (transform == null || widgetRect.isEmpty) return null;
    final plotRect = Rect.fromPoints(
      widgetToPlot(widgetRect.topLeft),
      widgetToPlot(widgetRect.bottomRight),
    );
    final first = transform.plotToData(plotRect.left, plotRect.top);
    final second = transform.plotToData(plotRect.right, plotRect.bottom);
    final minimum = acquisitionMode == ChartSelectionAcquisitionMode.xInterval
        ? math.min(first.dx, second.dx)
        : math.min(first.dy, second.dy);
    final maximum = acquisitionMode == ChartSelectionAcquisitionMode.xInterval
        ? math.max(first.dx, second.dx)
        : math.max(first.dy, second.dy);
    return ChartSelectionBrushRange(
      minimum: minimum,
      maximum: maximum,
      referenceSeriesId: referenceSeriesId,
    );
  }

  /// Converts widget-space brush geometry into two-axis data-domain bounds.
  ChartSelectionBrushBox? selectionBrushBoxForWidgetRect(
    Rect widgetRect, {
    String? referenceSeriesId,
  }) {
    final transform = _selectionBrushReferenceTransform(referenceSeriesId);
    if (transform == null || widgetRect.isEmpty) return null;
    final firstPlot = widgetToPlot(widgetRect.topLeft);
    final secondPlot = widgetToPlot(widgetRect.bottomRight);
    final first = transform.plotToData(firstPlot.dx, firstPlot.dy);
    final second = transform.plotToData(secondPlot.dx, secondPlot.dy);
    return ChartSelectionBrushBox(
      minimumX: math.min(first.dx, second.dx),
      maximumX: math.max(first.dx, second.dx),
      minimumY: math.min(first.dy, second.dy),
      maximumY: math.max(first.dy, second.dy),
      referenceSeriesId: referenceSeriesId,
    );
  }

  /// Resolves one brush rectangle through the ordinary selection gesture seam.
  ChartSelectionGestureResult? selectionGestureForWidgetRect(
    Rect widgetRect, {
    bool isPersistentBrushUpdate = false,
    bool isFinal = true,
  }) {
    final transform = _transform;
    final selection = _interactionConfig?.selection;
    if (transform == null || selection == null || widgetRect.isEmpty) {
      return null;
    }
    final firstPlot = widgetToPlot(widgetRect.topLeft);
    final secondPlot = widgetToPlot(widgetRect.bottomRight);
    final plotBounds = Rect.fromPoints(firstPlot, secondPlot);
    final first = transform.plotToData(firstPlot.dx, firstPlot.dy);
    final second = transform.plotToData(secondPlot.dx, secondPlot.dy);
    return ChartSelectionGestureResult(
      acquisitionMode: selection.acquisitionMode,
      hits: List<ChartDataHit>.unmodifiable(dataHitsInWidgetRect(widgetRect)),
      minimumXInclusive: math.min(first.dx, second.dx),
      maximumXInclusive: math.max(first.dx, second.dx),
      minimumYInclusive: math.min(first.dy, second.dy),
      maximumYInclusive: math.max(first.dy, second.dy),
      plotBounds: plotBounds,
      isPersistentBrushUpdate: isPersistentBrushUpdate,
      isFinal: isFinal,
    );
  }

  /// Handles keyboard movement and resizing for a visible persistent brush.
  ///
  /// Arrow keys move the interval along its visual axis. Shift+arrow adjusts
  /// the upper bound in that visual direction. Both operations use a stable
  /// ten-logical-pixel step resolved through the current chart transform, so
  /// transpose, RTL, zoom, and pan retain their native geometry.
  bool handleSelectionBrushKeyEvent(KeyEvent event) {
    final state = _selectionBrushState;
    final selection = _interactionConfig?.selection;
    final transform = _transform;
    if (!_selectionBrushKeyboardFocused ||
        state == null ||
        !state.visible ||
        selection == null ||
        !selection.brush.enabled ||
        !selection.brush.keyboardEnabled ||
        transform == null) {
      return false;
    }
    if (state.acquisitionMode == ChartSelectionAcquisitionMode.rectangle) {
      return _handleSelectionBrushBoxKeyEvent(event, state);
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.tab) {
      if (event is KeyUpEvent) return true;
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
      final reverse = HardwareKeyboard.instance.isShiftPressed;
      _selectionBrushKeyboardTarget = switch ((
        _selectionBrushKeyboardTarget,
        reverse,
      )) {
        (_SelectionBrushKeyboardTarget.body, false) =>
          _SelectionBrushKeyboardTarget.lowerBound,
        (_SelectionBrushKeyboardTarget.lowerBound, false) =>
          _SelectionBrushKeyboardTarget.upperBound,
        (_SelectionBrushKeyboardTarget.upperBound, false) =>
          _SelectionBrushKeyboardTarget.body,
        (_SelectionBrushKeyboardTarget.body, true) =>
          _SelectionBrushKeyboardTarget.upperBound,
        (_SelectionBrushKeyboardTarget.upperBound, true) =>
          _SelectionBrushKeyboardTarget.lowerBound,
        (_SelectionBrushKeyboardTarget.lowerBound, true) =>
          _SelectionBrushKeyboardTarget.body,
      };
      markNeedsPaint();
      markNeedsSemanticsUpdate();
      return true;
    }
    final usesScreenX =
        state.acquisitionMode == ChartSelectionAcquisitionMode.xInterval
        ? !transform.transposed
        : transform.transposed;
    final isNegativeKey = usesScreenX
        ? key == LogicalKeyboardKey.arrowLeft
        : key == LogicalKeyboardKey.arrowUp;
    final isPositiveKey = usesScreenX
        ? key == LogicalKeyboardKey.arrowRight
        : key == LogicalKeyboardKey.arrowDown;
    if (!isNegativeKey && !isPositiveKey) return false;
    if (event is KeyUpEvent) return true;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;

    final rect = _selectionBrushWidgetRectForState(state, clipToPlot: false);
    if (rect == null) return false;
    final screenDelta = usesScreenX
        ? Offset(
            isNegativeKey
                ? -_selectionBrushKeyboardStep
                : _selectionBrushKeyboardStep,
            0,
          )
        : Offset(
            0,
            isNegativeKey
                ? -_selectionBrushKeyboardStep
                : _selectionBrushKeyboardStep,
          );
    final shiftedRange = selectionBrushRangeForWidgetRect(
      rect.shift(screenDelta),
      acquisitionMode: state.acquisitionMode,
      referenceSeriesId: state.range.referenceSeriesId,
    );
    if (shiftedRange == null) return false;
    final domainDelta = shiftedRange.minimum - state.range.minimum;
    if (domainDelta == 0) return true;

    final resizeTarget =
        _selectionBrushKeyboardTarget == _SelectionBrushKeyboardTarget.body
        ? HardwareKeyboard.instance.isShiftPressed
              ? _SelectionBrushKeyboardTarget.upperBound
              : null
        : _selectionBrushKeyboardTarget;
    final nextRange = switch (resizeTarget) {
      _SelectionBrushKeyboardTarget.lowerBound => _resizeSelectionBrushBound(
        state,
        domainDelta,
        upperBound: false,
      ),
      _SelectionBrushKeyboardTarget.upperBound => _resizeSelectionBrushBound(
        state,
        domainDelta,
        upperBound: true,
      ),
      _ => _moveSelectionBrushRange(state, domainDelta),
    };
    if (nextRange == null || nextRange == state.range) return true;
    _commitSelectionBrushRange(state, nextRange);
    return true;
  }

  ChartSelectionBrushRange? _moveSelectionBrushRange(
    ChartSelectionBrushState state,
    double delta,
  ) {
    final limits = _selectionBrushDomainLimits(state);
    if (limits == null) return null;
    final range = state.range;
    final width = range.maximum - range.minimum;
    var minimum = range.minimum + delta;
    var maximum = range.maximum + delta;
    if (minimum < limits.minimum) {
      minimum = limits.minimum;
      maximum = minimum + width;
    }
    if (maximum > limits.maximum) {
      maximum = limits.maximum;
      minimum = maximum - width;
    }
    return ChartSelectionBrushRange(
      minimum: minimum,
      maximum: maximum,
      referenceSeriesId: range.referenceSeriesId,
    );
  }

  ChartSelectionBrushRange? _resizeSelectionBrushBound(
    ChartSelectionBrushState state,
    double delta, {
    required bool upperBound,
  }) {
    final range = state.range;
    final limits = _selectionBrushDomainLimits(state);
    if (limits == null) return null;
    final domainSpan = limits.maximum - limits.minimum;
    final minimumSpan = math.max(domainSpan / 1000, 1e-9);
    if (!upperBound) {
      final minimum = (range.minimum + delta).clamp(
        limits.minimum,
        range.maximum - minimumSpan,
      );
      return ChartSelectionBrushRange(
        minimum: minimum,
        maximum: range.maximum,
        referenceSeriesId: range.referenceSeriesId,
      );
    }
    final maximum = (range.maximum + delta).clamp(
      range.minimum + minimumSpan,
      limits.maximum,
    );
    return ChartSelectionBrushRange(
      minimum: range.minimum,
      maximum: maximum,
      referenceSeriesId: range.referenceSeriesId,
    );
  }

  ({double minimum, double maximum})? _selectionBrushDomainLimits(
    ChartSelectionBrushState state,
  ) {
    final range = state.range;
    final transform =
        state.acquisitionMode == ChartSelectionAcquisitionMode.yInterval
        ? _selectionBrushReferenceTransform(range.referenceSeriesId)
        : _transform;
    if (transform == null) return null;
    return state.acquisitionMode == ChartSelectionAcquisitionMode.xInterval
        ? (
            minimum: math.min(transform.dataXMin, transform.dataXMax),
            maximum: math.max(transform.dataXMin, transform.dataXMax),
          )
        : (
            minimum: math.min(transform.dataYMin, transform.dataYMax),
            maximum: math.max(transform.dataYMin, transform.dataYMax),
          );
  }

  bool _handleSelectionBrushBoxKeyEvent(
    KeyEvent event,
    ChartSelectionBrushState state,
  ) {
    final key = event.logicalKey;
    final isArrow =
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown;
    if (!isArrow) return false;
    if (event is KeyUpEvent) return true;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    final rect = _selectionBrushWidgetRectForState(state, clipToPlot: false);
    if (rect == null) return false;
    final dx = key == LogicalKeyboardKey.arrowLeft
        ? -_selectionBrushKeyboardStep
        : key == LogicalKeyboardKey.arrowRight
        ? _selectionBrushKeyboardStep
        : 0.0;
    final dy = key == LogicalKeyboardKey.arrowUp
        ? -_selectionBrushKeyboardStep
        : key == LogicalKeyboardKey.arrowDown
        ? _selectionBrushKeyboardStep
        : 0.0;
    final plot = _plotArea;
    final shifted = rect.shift(Offset(dx, dy));
    final clamped = shifted.shift(
      Offset(
        shifted.left < plot.left
            ? plot.left - shifted.left
            : shifted.right > plot.right
            ? plot.right - shifted.right
            : 0,
        shifted.top < plot.top
            ? plot.top - shifted.top
            : shifted.bottom > plot.bottom
            ? plot.bottom - shifted.bottom
            : 0,
      ),
    );
    final box = selectionBrushBoxForWidgetRect(
      clamped,
      referenceSeriesId: state.box?.referenceSeriesId,
    );
    if (box == null || box == state.box) return true;
    _commitSelectionBrushBox(state, box);
    return true;
  }

  void _commitSelectionBrushRange(
    ChartSelectionBrushState state,
    ChartSelectionBrushRange range,
  ) {
    final next = state.copyWith(range: range, visible: true);
    final rect = _selectionBrushWidgetRectForState(next);
    if (rect == null) return;
    final gesture = selectionGestureForWidgetRect(
      rect,
      isPersistentBrushUpdate: true,
      isFinal: true,
    );
    if (gesture != null) onSelectionGestureComplete?.call(gesture);
  }

  void _commitSelectionBrushBox(
    ChartSelectionBrushState state,
    ChartSelectionBrushBox box,
  ) {
    final next = ChartSelectionBrushState(
      acquisitionMode: ChartSelectionAcquisitionMode.rectangle,
      range: ChartSelectionBrushRange(
        minimum: box.minimumX,
        maximum: box.maximumX,
        referenceSeriesId: box.referenceSeriesId,
      ),
      box: box,
      visible: true,
    );
    final rect = _selectionBrushWidgetRectForState(next);
    if (rect == null) return;
    final gesture = selectionGestureForWidgetRect(
      rect,
      isPersistentBrushUpdate: true,
      isFinal: true,
    );
    if (gesture != null) onSelectionGestureComplete?.call(gesture);
  }

  void _performSelectionBrushSemanticAdjustment({
    double moveSteps = 0,
    double lowerSteps = 0,
    double upperSteps = 0,
  }) {
    final state = _selectionBrushState;
    if (state == null) return;
    if (state.acquisitionMode == ChartSelectionAcquisitionMode.rectangle) {
      return;
    }
    final limits = _selectionBrushDomainLimits(state);
    if (limits == null) return;
    final step = (limits.maximum - limits.minimum) / 100;
    ChartSelectionBrushRange? next;
    if (moveSteps != 0) {
      next = _moveSelectionBrushRange(state, step * moveSteps);
    } else {
      final range = state.range;
      final minimum = (range.minimum + step * lowerSteps).clamp(
        limits.minimum,
        range.maximum,
      );
      final maximum = (range.maximum + step * upperSteps).clamp(
        minimum,
        limits.maximum,
      );
      next = ChartSelectionBrushRange(
        minimum: minimum,
        maximum: maximum,
        referenceSeriesId: range.referenceSeriesId,
      );
    }
    if (next != null && next != state.range) {
      _commitSelectionBrushRange(state, next);
    }
  }

  // ============================================================================
  // Event Handling (delegated to EventHandlerManager)
  // ============================================================================

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    _eventHandlerManager.handleEvent(event);
    final retainsPersistentGuideDuringMousePan =
        coordinator.currentMode == InteractionMode.panning &&
        (_interactionConfig?.crosshair.persistOnPointerExit ?? false);
    if (coordinator.isPanningOrZooming ||
        _eventHandlerManager.isSuppressingTouchSequence) {
      // A persistent synchronized guide represents a durable data-X, not the
      // current pointer pixel. Middle-button panning must therefore retain the
      // group's shared value while each participant remaps it through the
      // moving viewport. Clearing here exposes every pane's stale local hover
      // position and makes an otherwise synchronized stack visibly diverge.
      if (!retainsPersistentGuideDuringMousePan) {
        _publishCrosshairChange(null);
        onDataXCursorChanged?.call(null);
      }
      return;
    }
    final publishesPosition =
        event is PointerHoverEvent ||
        event is PointerDownEvent ||
        event is PointerMoveEvent;
    if (publishesPosition) {
      final position = event.localPosition;
      final transform = _transform;
      if (transform != null && _plotArea.contains(position)) {
        _publishCrosshairChange(position);
        final plotPosition = widgetToPlot(position);
        onDataXCursorChanged?.call(
          transform.plotToData(plotPosition.dx, plotPosition.dy).dx,
        );
      } else {
        // A hover can remain inside the chart widget while leaving its plot
        // (for example over an axis, pane seam, or overlay control). When the
        // last guide is configured to persist, that transition must not clear
        // the interaction group's shared data-X. Otherwise every participant
        // falls back to its own stale local pointer and synchronized panes
        // visibly diverge until the pointer re-enters a plot.
        final persistsAfterPointerDeparture =
            event is PointerHoverEvent &&
            (_interactionConfig?.crosshair.persistOnPointerExit ?? false);
        if (!persistsAfterPointerDeparture) {
          _publishCrosshairChange(null);
          onDataXCursorChanged?.call(null);
        }
      }
    } else if ((event is PointerUpEvent || event is PointerCancelEvent) &&
        event.kind != PointerDeviceKind.mouse) {
      _publishCrosshairChange(null);
      onDataXCursorChanged?.call(null);
    }
  }

  List<ChartDataPoint> _publishCrosshairChange(Offset? position) {
    final callback = _interactionConfig?.onCrosshairChanged;
    final transform = _transform;
    if (position == null ||
        transform == null ||
        !_plotArea.contains(position) ||
        !(_interactionConfig?.enabled ?? true) ||
        coordinator.isPanningOrZooming ||
        coordinator.isDragging) {
      callback?.call(null, const []);
      return const [];
    }

    final categoryScreenPosition = transform.transposed
        ? position.dy
        : position.dx;
    final trackingBounds = transform.transposed
        ? Rect.fromLTWH(_plotArea.top, 0, _plotArea.height, 1)
        : _plotArea;
    final seriesElements = _elements.whereType<SeriesElement>().toList(
      growable: false,
    );
    final trackingState = CrosshairTracker.calculateTrackingState(
      screenX: categoryScreenPosition,
      chartBounds: trackingBounds,
      xMin: transform.dataXMin,
      xMax: transform.dataXMax,
      seriesList: seriesElements
          .map((element) => element.series)
          .toList(growable: false),
      interpolate: false,
      useCandlestickDensityGrouping: false,
    );
    if (trackingState == null) {
      callback?.call(position, const []);
      return const [];
    }

    final elementsById = {
      for (final element in seriesElements) element.series.id: element,
    };
    final snapPoints = [
      for (final value in trackingState.seriesValues)
        if (elementsById[value.seriesId] case final element?
            when value.dataPointIndex >= 0 &&
                value.dataPointIndex < element.series.points.length)
          element.series.points[value.dataPointIndex],
    ];
    final immutablePoints = List<ChartDataPoint>.unmodifiable(snapPoints);
    callback?.call(position, immutablePoints);
    return immutablePoints;
  }

  /// Clears crosshair state when the pointer leaves the chart widget.
  void clearCursorPosition() {
    _eventHandlerManager.clearCursorPosition();
    _publishCrosshairChange(null);
    onDataXCursorChanged?.call(null);
  }

  /// Removes crosshair and tooltip state that is not part of the artifact.
  void clearTransientPreviewState() {
    _eventHandlerManager.clearTransientPreviewState();
    _tooltipAnimator.hideImmediately();
  }

  // ============================================================================
  // Y-Axis Slot Selection Delegation
  // ============================================================================

  /// Applies series selection to the slot system.
  ///
  /// Returns a swap record if an axis was promoted/demoted, or null.
  ({String promotedAxisId, String demotedAxisId})? applySeriesSelection(
    String seriesId,
  ) {
    final result = _multiAxisManager.applySeriesSelection(seriesId);
    if (result != null) markNeedsLayout();
    return result;
  }

  /// Deselects a series, reverting slot if mode is revert.
  void clearSeriesSelection(String seriesId) {
    final reverted = _multiAxisManager.clearSelectionFor(seriesId);
    if (reverted) markNeedsLayout();
  }

  /// Clears all selection state.
  void clearAllSeriesSelection() {
    _multiAxisManager.clearAllSelection();
    markNeedsLayout();
  }

  /// Currently visible axis IDs.
  List<String> get visibleAxisIds =>
      _multiAxisManager.getVisibleAxes().map((a) => a.id).toList();

  /// Currently overflow axis IDs.
  List<String> get overflowAxisIds => _multiAxisManager.overflowAxisIds;

  /// Restores captured visible-axis slot order and schedules layout.
  void restoreVisibleAxisIds(Iterable<String> axisIds) {
    _multiAxisManager.restoreVisibleAxisIds(axisIds);
    markNeedsLayout();
  }

  /// Sets the maximum number of visible Y-axes per side.
  void setMaxAxesPerSide(int max) {
    if (_multiAxisManager.setMaxAxesPerSide(max)) markNeedsLayout();
  }

  /// Sets the swap mode for deselection behaviour.
  void setAxisSwapMode(AxisSwapMode mode) {
    if (_multiAxisManager.setAxisSwapMode(mode)) markNeedsLayout();
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
    final seriesElements = _elements.whereType<DataSeriesElement>().toList()
      ..sort((a, b) {
        final priority = a.priority.compareTo(b.priority);
        return priority != 0
            ? priority
            : a.seriesIndex.compareTo(b.seriesIndex);
      });

    // Compute per-axis bounds for multi-axis normalization (if multi-axis mode is active)
    // Checks effective axes (including inline yAxisConfig) via MultiAxisManager
    // Use forceFullBounds=true to get the FULL data range for series painting transforms
    // (viewport transformation is only for axis labels/crosshair, not series rendering)
    final Map<String, DataRange>? axisBounds =
        (_multiAxisManager.isMultiAxisNormalizationActive())
        ? _computeAxisBounds(forPainting: true)
        : null;

    // Build series-to-axis lookup for efficient transform creation (use effective bindings)
    final effectiveBindings = _getEffectiveBindings();
    final Map<String, String>? seriesToAxisMap = axisBounds != null
        ? {
            for (final binding in effectiveBindings)
              binding.seriesId: binding.yAxisId,
          }
        : null;
    // Per-axis Y scale (log/linear), keyed by the same axis IDs as axisBounds.
    final Map<String, YAxisConfig>? axisConfigsById = axisBounds != null
        ? {for (final axis in _getEffectiveYAxes()) axis.id: axis}
        : null;

    final barLabelLayout = BarLabelLayoutCoordinator(
      plotBounds: Offset.zero & size,
    );
    final dataPointLabelLayout = DataPointLabelLayoutCoordinator(
      plotBounds: Offset.zero & size,
    );

    // Paint each series with current transform
    for (final series in seriesElements) {
      if (_transform != null && series is SeriesElement) {
        series.setBarLabelLayoutCoordinator(barLabelLayout);
        series.setDataPointLabelLayoutCoordinator(dataPointLabelLayout);
        // CRITICAL: Update transform before painting (enables path caching!)
        // This allows SeriesElement to cache paths and only regenerate when transform changes.

        // Multi-axis mode: Create per-series transform with axis-specific Y bounds
        if (axisBounds != null && seriesToAxisMap != null) {
          final axisId = seriesToAxisMap[series.id];
          if (axisId != null && axisBounds.containsKey(axisId)) {
            final axisRange = axisBounds[axisId]!;
            final axisConfig = axisConfigsById?[axisId];
            // Create transform with per-axis Y bounds for proper normalization
            final perSeriesTransform = _transform!.copyWith(
              dataYMin: axisRange.min,
              dataYMax: axisRange.max,
              yScaleType: axisConfig?.scaleType,
              yLogBase: axisConfig?.logBase,
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

    final coordinatedRadialLabels = seriesElements
        .whereType<PieSeriesElement>()
        .where((element) => element.coordinateOutsideLabels)
        .toList(growable: false);
    if (coordinatedRadialLabels.length > 1) {
      PieSeriesElement.paintCoordinatedOutsideLabels(
        canvas,
        coordinatedRadialLabels,
      );
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

  /// Returns true if there is active overlay content to paint.
  ///
  /// Overlays paint directly into the render object's canvas. None of the
  /// overlay primitives require offscreen compositing, so a full-widget
  /// `saveLayer` would only allocate an avoidable CanvasKit texture.
  bool _hasActiveOverlayContent() {
    final hoveredMarker = coordinator.hoveredMarker;
    final pressedMarker = coordinator.pressedMarker;
    if (_isBarMarker(hoveredMarker) ||
        _isBarMarker(pressedMarker) ||
        _isScatterMarker(hoveredMarker) ||
        _isScatterMarker(pressedMarker) ||
        _isRangeAreaMarker(hoveredMarker) ||
        _isRangeAreaMarker(pressedMarker)) {
      return true;
    }

    // Box selection or range creation has visible rectangle
    if (coordinator.currentMode == InteractionMode.boxSelecting ||
        coordinator.currentMode == InteractionMode.rangeAnnotationCreation) {
      return true;
    }
    if (_selectionBrushState?.visible ?? false) return true;

    // Crosshair is visible
    final crosshairConfig = _effectiveCrosshairConfig(
      _interactionConfig?.crosshair ?? const CrosshairConfig(),
    );
    final cursorPos = _effectiveCrosshairCursorPosition;
    if (crosshairConfig.enabled &&
        cursorPos != null &&
        _plotArea.contains(cursorPos) &&
        !coordinator.currentMode.isDragging) {
      return true;
    }

    if (_hasActiveTooltipOverlay()) return true;

    return false;
  }

  /// Whether the overlay pass contains tooltip primitives.
  ///
  /// Tooltip shadows and translucent surfaces retain an isolated compositing
  /// layer so their blending stays stable across renderers. Lightweight
  /// crosshair, selection, and mark-feedback overlays paint directly and avoid
  /// allocating a full-widget offscreen texture.
  bool _hasActiveTooltipOverlay() {
    if (!_tooltipsEnabled || coordinator.isPanningOrZooming) return false;
    if (_tooltipAnimator.isVisible || _tooltipAnimator.opacity > 0) return true;
    if (_resolveSelectedTooltipMarker() != null) return true;

    final config = _interactionConfig?.tooltip ?? const TooltipConfig();
    final hasHoveredMarker = coordinator.hoveredMarker != null;
    final hasTappedMarker = _eventHandlerManager.tappedMarker != null;
    if (hasHoveredMarker &&
        (config.triggerMode == TooltipTriggerMode.hover ||
            config.triggerMode == TooltipTriggerMode.both)) {
      return true;
    }
    if (hasTappedMarker &&
        (config.triggerMode == TooltipTriggerMode.tap ||
            config.triggerMode == TooltipTriggerMode.both)) {
      return true;
    }
    return false;
  }

  void _paintOverlayLayer(Canvas canvas, Size size) {
    // [DEBUG OUTPUT REMOVED] Overlay paint start - was firing at 60fps
    _paintPersistentSelectionBrush(canvas);
    _paintBarInteractionOverlays(canvas);
    _paintScatterInteractionOverlays(canvas);
    _paintRangeAreaInteractionOverlays(canvas);

    // Paint preview selection indicators (during box drag)
    // Draw with different visual style than actual selection (dashed outline)
    if (coordinator.currentMode == InteractionMode.boxSelecting) {
      for (final hit in coordinator.previewDataHits) {
        final interactionTheme = _theme?.interactionTheme;
        final selectionColor =
            interactionTheme?.selectionColor ?? const Color(0xFF00AAFF);
        final previewPaint = Paint()
          ..color = selectionColor.withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        final selectionBounds = hit.selectionBounds;
        if (hit.rangeArea != null && selectionBounds != null) {
          final bounds = selectionBounds;
          final upper = plotToWidget(
            Offset(bounds.center.dx, math.min(bounds.top, bounds.bottom)),
          );
          final lower = plotToWidget(
            Offset(bounds.center.dx, math.max(bounds.top, bounds.bottom)),
          );
          canvas
            ..drawLine(
              upper,
              lower,
              Paint()
                ..color = selectionColor.withValues(alpha: 0.42)
                ..strokeWidth = 3
                ..strokeCap = StrokeCap.round,
            )
            ..drawCircle(upper, 7, previewPaint)
            ..drawCircle(lower, 7, previewPaint);
        } else {
          final widgetCenter = plotToWidget(hit.plotPosition);
          final radius =
              (math.max(hit.semanticBounds.width, hit.semanticBounds.height) /
                      2)
                  .clamp(4.0, 10.0);
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
        final selectionColor =
            interactionTheme?.selectionColor ?? const Color(0xFF0088FF);
        canvas.drawRect(
          boxRect,
          Paint()
            ..color = selectionColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        _paintIntervalSelectionHandles(canvas, boxRect, selectionColor);
      }
    }

    // Paint free-form lasso geometry when lasso owns the active drag.
    if (coordinator.currentMode == InteractionMode.boxSelecting &&
        _interactionConfig?.selection.acquisitionMode ==
            ChartSelectionAcquisitionMode.lasso) {
      final points = coordinator.lassoSelectionPath;
      if (points.length >= 2) {
        final interactionTheme = _theme?.interactionTheme;
        final color =
            interactionTheme?.selectionColor ?? const Color(0xFF0088FF);
        final path = Path()..addPolygon(points, points.length >= 3);
        if (points.length >= 3) {
          canvas.drawPath(
            path,
            Paint()
              ..color = color.withValues(alpha: 0.18)
              ..style = PaintingStyle.fill,
          );
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
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
            ..color = rangeColor
                .withValues(alpha: 0.15) // 15% opacity for fill
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
          final bottomRight = _transform!.plotToData(
            boxRect.right,
            boxRect.bottom,
          );

          // Calculate min/max coordinates
          final xMin = topLeft.dx < bottomRight.dx
              ? topLeft.dx
              : bottomRight.dx;
          final xMax = topLeft.dx > bottomRight.dx
              ? topLeft.dx
              : bottomRight.dx;
          final yMin = topLeft.dy < bottomRight.dy
              ? topLeft.dy
              : bottomRight.dy;
          final yMax = topLeft.dy > bottomRight.dy
              ? topLeft.dy
              : bottomRight.dy;

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
            tooltipOffset = Offset(
              size.width - textPainter.width - 5,
              tooltipOffset.dy,
            );
          }
          if (tooltipOffset.dy + textPainter.height > size.height) {
            tooltipOffset = Offset(
              tooltipOffset.dx,
              boxRect.top - textPainter.height - 5,
            );
          }

          textPainter.paint(canvas, tooltipOffset);
        }
      }
    }

    // Draw crosshair at cursor position (in widget space)
    final cursorPos = _effectiveCrosshairCursorPosition;
    var crosshairConfig = _effectiveCrosshairConfig(
      _interactionConfig?.crosshair ?? const CrosshairConfig(),
    );
    final hoveredDataHit = coordinator.hoveredMarker?.dataHit;
    final hoveringAggregate =
        hoveredDataHit != null &&
        (hoveredDataHit.sourcePointIndices.length > 1 ||
            hoveredDataHit.formattedAggregateValue != null);
    if (hoveringAggregate) {
      // The marker tooltip already describes the aggregate. Retain the
      // crosshair and coordinate labels, but remove the competing tracking
      // tooltip and intersection marker that imply a second raw datum.
      crosshairConfig = crosshairConfig.copyWith(
        showTrackingTooltip: false,
        showIntersectionMarkers: false,
      );
    }
    final crosshairEnabled = crosshairConfig.enabled;
    // The painted-marker probe reflects only the current frame: cleared here
    // so a frame that paints no tracking markers leaves it empty.
    _paintedIntersectionMarkers.clear();
    if (crosshairEnabled &&
        cursorPos != null &&
        _plotArea.contains(cursorPos) &&
        !coordinator.currentMode.isDragging) {
      // Only draw crosshair if cursor is inside plot area AND not dragging
      // Hide crosshair during all drag operations (datapoint, annotation, resize)

      // Build multi-axis info for crosshair rendering
      final multiAxisInfo = _buildMultiAxisInfo();

      // Use widget-provided XAxisConfig directly
      final xAxisConfig = _xAxisConfig ?? const XAxisConfig();

      final seriesElements = _elements.whereType<SeriesElement>().toList();

      // Resolve the frame's tracking snapshot once before painting, honoring
      // the same tracking-mode gate the renderer applies. The resolver
      // memoizes unchanged inputs and suppresses identity-equal publication,
      // so stationary repaints reuse the cached snapshot.
      CartesianTrackingSnapshot? trackingSnapshot;
      final totalDataPoints = CrosshairTracker.getTotalPointCount([
        for (final element in seriesElements) element.series,
      ]);
      if (crosshairConfig.shouldUseTrackingMode(totalDataPoints)) {
        final syncSnapshot = _syncPositionSnapshot;
        if (_synchronizedCursorPosition != null &&
            syncSnapshot != null &&
            identical(syncSnapshot, _trackingSnapshotResolver.current)) {
          // The synchronized-position computation already resolved this
          // frame's snapshot: the effective cursor derives from the same
          // sync data-X and transform, only its Y was adjusted afterwards.
          // Reuse that resolution instead of resolving again at the
          // Y-adjusted cursor, which would double-compute every sync frame
          // and could ping-pong publication with Y-sensitive scatter hits.
          trackingSnapshot = syncSnapshot;
        } else {
          trackingSnapshot = _resolveTrackingSnapshot(
            cursorPosition: cursorPos,
            origin: _synchronizedCursorPosition != null
                ? CartesianTrackingOrigin.synchronized
                : CartesianTrackingOrigin.pointer,
            interpolateValues: crosshairConfig.interpolateValues,
            axisInfo: multiAxisInfo,
          );
        }
      } else if (!_valueSummaryTrackingActive) {
        // Tracking-mode gate is off: publish the null snapshot so consumers
        // of the resolver never observe stale tracking state. Skipped while
        // the value summary consumed this frame's tracking resolution — the
        // summary is a live consumer of the resolver state.
        _trackingSnapshotResolver.clear();
      }

      // Delegate to CrosshairRenderer module
      _crosshairRenderer.paint(
        canvas: canvas,
        size: size,
        cursorPosition: cursorPos,
        plotArea: _plotArea,
        transform: _transform!,
        theme: _theme,
        interactionConfig: _interactionConfig,
        crosshairConfig: crosshairConfig,
        multiAxisInfo: multiAxisInfo,
        seriesElements: seriesElements,
        isRangeCreationMode:
            coordinator.currentMode == InteractionMode.rangeAnnotationCreation,
        trackingSnapshot: trackingSnapshot,
        xAxisConfig: xAxisConfig,
        trendElements: _elements.whereType<TrendAnnotationElement>().toList(),
        paintedMarkerSink: _paintedIntersectionMarkers,
      );
    } else if (!_valueSummaryTrackingActive) {
      // The crosshair gate is off (disabled, cursor gone or outside the
      // plot, or a drag in progress): publish the null snapshot so future
      // consumers of the resolver never observe the stale hover state.
      // Skipped while the value summary consumed this frame's tracking
      // resolution — the summary is a live consumer of the resolver state.
      _trackingSnapshotResolver.clear();
    }

    // Draw tooltip for hovered/tapped marker (if any)
    // Show based on tooltip trigger mode configuration with animations
    if (_tooltipsEnabled && !coordinator.isPanningOrZooming) {
      final config = _interactionConfig?.tooltip ?? const TooltipConfig();
      HoveredMarkerInfo? markerToShow = _resolveSelectedTooltipMarker();

      if (markerToShow == null) {
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
      }

      // Handle show/hide animations based on marker presence
      if (markerToShow != null) {
        // Start show animation if marker changed or newly appeared
        // Use sameMarkerAs to compare by identity (seriesId + markerIndex) only,
        // ignoring plotPosition to prevent flickering from floating-point differences
        final currentTarget = _tooltipAnimator
            .getTargetMarker<HoveredMarkerInfo>();
        if (!markerToShow.sameMarkerAs(currentTarget)) {
          _tooltipAnimator.show(
            markerToShow,
            config,
            animate: !_disableAnimations,
          );
        }

        // Only draw tooltip if it has some opacity (visible or fading)
        if (_tooltipAnimator.isVisible) {
          _drawMarkerTooltip(canvas, size, markerToShow);
        }
      } else {
        // Start hide animation if marker disappeared
        final currentTarget = _tooltipAnimator
            .getTargetMarker<HoveredMarkerInfo>();
        if (currentTarget != null) {
          _tooltipAnimator.hide(config, animate: !_disableAnimations);
        }

        // Still draw tooltip during fade-out
        final targetMarker = _tooltipAnimator
            .getTargetMarker<HoveredMarkerInfo>();
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

  bool _isBarMarker(HoveredMarkerInfo? marker) {
    if (marker == null) return false;
    for (final element in _elements.whereType<SeriesElement>()) {
      if (element.id == marker.seriesId) {
        return element.series is BarChartSeries;
      }
    }
    return false;
  }

  bool _isScatterMarker(HoveredMarkerInfo? marker) {
    if (marker == null) return false;
    for (final element in _elements.whereType<SeriesElement>()) {
      if (element.id == marker.seriesId) {
        return element.series is ScatterChartSeries;
      }
    }
    return false;
  }

  bool _isRangeAreaMarker(HoveredMarkerInfo? marker) {
    if (marker == null) return false;
    for (final element in _elements.whereType<SeriesElement>()) {
      if (element.id == marker.seriesId) {
        return element.series is RangeAreaChartSeries;
      }
    }
    return false;
  }

  void _paintBarInteractionOverlays(Canvas canvas) {
    final hoveredMarker = coordinator.hoveredMarker;
    final pressedMarker = coordinator.pressedMarker;
    if (!_isBarMarker(hoveredMarker) && !_isBarMarker(pressedMarker)) return;

    canvas.save();
    canvas.translate(_plotArea.left, _plotArea.top);
    canvas.clipRect(Offset.zero & _plotArea.size);
    for (final element in _elements.whereType<SeriesElement>()) {
      final hoveredPointIndex = hoveredMarker?.seriesId == element.id
          ? hoveredMarker!.markerIndex
          : null;
      final pressedPointIndex = pressedMarker?.seriesId == element.id
          ? pressedMarker!.markerIndex
          : null;
      if (hoveredPointIndex == null && pressedPointIndex == null) continue;
      element.paintBarInteractionOverlay(
        canvas,
        hoveredPointIndex: hoveredPointIndex,
        pressedPointIndex: pressedPointIndex,
      );
    }
    canvas.restore();
  }

  void _paintScatterInteractionOverlays(Canvas canvas) {
    final hoveredMarker = coordinator.hoveredMarker;
    final pressedMarker = coordinator.pressedMarker;
    if (!_isScatterMarker(hoveredMarker) && !_isScatterMarker(pressedMarker)) {
      return;
    }

    canvas.save();
    canvas.translate(_plotArea.left, _plotArea.top);
    canvas.clipRect(Offset.zero & _plotArea.size);
    for (final element in _elements.whereType<SeriesElement>()) {
      if (element.series is! ScatterChartSeries) continue;
      final hoveredPointIndex = hoveredMarker?.seriesId == element.id
          ? hoveredMarker!.markerIndex
          : null;
      final pressedPointIndex = pressedMarker?.seriesId == element.id
          ? pressedMarker!.markerIndex
          : null;
      if (hoveredPointIndex == null && pressedPointIndex == null) continue;
      element.paintScatterInteractionOverlay(
        canvas,
        hoveredPointIndex: hoveredPointIndex,
        pressedPointIndex: pressedPointIndex,
      );
    }
    canvas.restore();
  }

  void _paintRangeAreaInteractionOverlays(Canvas canvas) {
    final hoveredMarker = coordinator.hoveredMarker;
    final pressedMarker = coordinator.pressedMarker;
    if (!_isRangeAreaMarker(hoveredMarker) &&
        !_isRangeAreaMarker(pressedMarker)) {
      return;
    }

    canvas.save();
    canvas.translate(_plotArea.left, _plotArea.top);
    canvas.clipRect(Offset.zero & _plotArea.size);
    for (final element in _elements.whereType<SeriesElement>()) {
      if (element.series is! RangeAreaChartSeries) continue;
      final hoveredPointIndex = hoveredMarker?.seriesId == element.id
          ? hoveredMarker!.markerIndex
          : null;
      final pressedPointIndex = pressedMarker?.seriesId == element.id
          ? pressedMarker!.markerIndex
          : null;
      if (hoveredPointIndex == null && pressedPointIndex == null) continue;
      element.paintRangeAreaInteractionOverlay(
        canvas,
        hoveredPointIndex: hoveredPointIndex,
        pressedPointIndex: pressedPointIndex,
      );
    }
    canvas.restore();
  }

  /// Computes the canvas-space grid-line positions for the current axes,
  /// transform, and plot area.
  ///
  /// Returns the vertical grid X pixels ([xTicks]) and horizontal grid Y pixels
  /// ([yTicks]). Only valid when both [_xAxis] and [_yAxis] are non-null (the
  /// paint-time guard); the debug accessor mirrors that precondition.
  ({List<double> xTicks, List<double> yTicks}) _computeGridLinePositions() {
    final List<double> xTicks;
    final List<double> yTicks;
    if (_isHorizontalBarChart && _transform != null) {
      xTicks = _buildTransposedAxesPainter().valueGridPositions(_plotArea);
      final categoryTicks = _buildXAxisPainter(
        bounds: DataRange(min: _transform!.dataXMin, max: _transform!.dataXMax),
      ).resolveTickValues(_plotArea.height);
      yTicks = categoryTicks
          .map(
            (tick) =>
                _plotArea.top +
                (tick - _transform!.dataXMin) /
                    _transform!.dataXRange *
                    _plotArea.height,
          )
          .toList();
    } else {
      final categoryTicks = _buildXAxisPainter(
        bounds: DataRange(min: _xAxis!.dataMin, max: _xAxis!.dataMax),
      ).resolveTickValues(_plotArea.width);
      // Grid pixels must register with the axis painters and the data marks.
      // The linear arm is the original expression verbatim; the log arm routes
      // through the same [logFraction] mapping the X painter (`tickRatio`) and
      // [ChartTransform] apply to the ticks/marks, so decade grid lines land on
      // their own tick marks and on the data instead of the linear positions.
      xTicks = categoryTicks
          .map(
            (tick) => _xAxis!.scaleType == AxisScaleType.linear
                ? _xAxis!.scale.dataToPixel(tick)
                : _plotArea.left +
                      logFraction(
                            tick,
                            _xAxis!.dataMin,
                            _xAxis!.dataMax,
                            _xAxis!.logBase,
                          ) *
                          _plotArea.width,
          )
          .toList();
      // The linear arm keeps the legacy nice-number tick values at their linear
      // pixels verbatim; the log arm uses decade tick values placed by
      // [logFraction] so grid lines register with the Y multi-axis painter
      // (`normalizeScaled`) and the data marks.
      yTicks = _yAxis!.scaleType == AxisScaleType.linear
          ? _yAxis!.ticks
                .map((t) => _yAxis!.scale.dataToPixel(t.value))
                .toList()
          : decadeTicks(_yAxis!.dataMin, _yAxis!.dataMax, base: _yAxis!.logBase)
                .map(
                  (v) =>
                      _plotArea.bottom -
                      logFraction(
                            v,
                            _yAxis!.dataMin,
                            _yAxis!.dataMax,
                            _yAxis!.logBase,
                          ) *
                          _plotArea.height,
                )
                .toList();
    }
    return (xTicks: xTicks, yTicks: yTicks);
  }

  /// The canvas-space grid-line positions for the current frame, for
  /// render-path verification. Only call when both axes are present.
  @visibleForTesting
  ({List<double> xTicks, List<double> yTicks}) debugGridLinePositions() =>
      _computeGridLinePositions();

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
      final gridRenderer = GridRenderer(theme: _theme, config: _gridConfig);
      final gridPositions = _computeGridLinePositions();
      gridRenderer.paintVerticalGrid(canvas, _plotArea, gridPositions.xTicks);
      gridRenderer.paintHorizontalGrid(canvas, _plotArea, gridPositions.yTicks);
    }

    // Paint axes (behind all chart elements).
    if (_isHorizontalBarChart && _xAxis != null && _yAxis != null) {
      _buildTransposedAxesPainter().paint(
        canvas,
        Rect.fromLTWH(0, 0, size.width, size.height),
        _plotArea,
      );
    } else {
      // Paint Y-axes using MultiAxisPainter (handles single or multiple axes)
      // Radial layouts deliberately provide no Cartesian Y-axis. Preserve that
      // boundary so pie charts do not paint the manager's synthetic fallback
      // axis behind their slices.
      if (_yAxis != null) {
        _paintMultipleYAxes(canvas);
      }

      // Paint X-axis using XAxisPainter (unified approach)
      if (_xAxis != null) {
        _buildXAxisPainter(
          bounds: DataRange(min: _xAxis!.dataMin, max: _xAxis!.dataMax),
        ).paint(
          canvas,
          Rect.fromLTWH(0, 0, size.width, size.height),
          _plotArea,
        );
      }
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

    // Run the value summary pipeline before the element passes so the
    // overlay panel paints this frame's policy-resolved content. This also
    // performs the frame's tracking resolution when the summary consumes it,
    // which the crosshair path below then reuses through the resolver's
    // input memo.
    _updateValueSummary();

    // Clip canvas to plot area to prevent elements from rendering over axes
    canvas.save();
    canvas.translate(_plotArea.left, _plotArea.top);
    canvas.clipRect(Offset.zero & _plotArea.size);

    // ==========================================================================
    // LAYER 0: Background annotations (Range annotations with renderOrder < 2)
    // These must paint BEFORE series so they appear behind the data lines
    // ==========================================================================
    final backgroundElements =
        _elements
            .where(
              (e) =>
                  e is! DataSeriesElement && e.renderOrder < RenderOrder.series,
            )
            .toList()
          ..sort((a, b) => a.renderOrder.compareTo(b.renderOrder));

    // Compute series bounds for range annotations in perSeries mode
    // This ensures range annotations are positioned correctly when each series
    // has its own Y-axis range. Must be computed BEFORE painting background elements.
    Map<String, DataRange>? backgroundSeriesBounds;
    if (_multiAxisManager.effectiveNormalizationMode ==
            NormalizationMode.perSeries &&
        _multiAxisManager.series.isNotEmpty) {
      backgroundSeriesBounds = _computeSeriesBounds(forPainting: true);
    }

    for (final element in backgroundElements) {
      if (_transform != null && element is RangeAnnotationElement) {
        element.updateTransform(_transform!);
        // For perSeries mode: update axis bounds for correct Y-value normalization
        if (backgroundSeriesBounds != null &&
            backgroundSeriesBounds.isNotEmpty &&
            (element.annotation.startY != null ||
                element.annotation.endY != null)) {
          final seriesId = element.annotation.seriesId;
          final axisBoundsToUse = seriesId != null
              ? backgroundSeriesBounds[seriesId]
              : backgroundSeriesBounds.values.first;
          element.updateAxisBounds(axisBoundsToUse);
        } else {
          element.updateAxisBounds(null);
        }
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
          (e) => e is! DataSeriesElement && e.renderOrder >= RenderOrder.series,
        )
        .toList();
    // The value summary overlay joins the foreground pass for paint ordering
    // only (RenderOrder.valueSummary); it never enters _elements, the
    // spatial index, or any hit-testing/selection flow.
    final valueSummaryElement = _valueSummaryCoordinator.overlayElementForPaint;
    if (valueSummaryElement != null) {
      foregroundElements.add(valueSummaryElement);
    }
    foregroundElements.sort((a, b) => a.renderOrder.compareTo(b.renderOrder));

    // Compute series bounds for annotations in perSeries mode
    // This ensures threshold lines and range annotations are positioned correctly
    // when each series has its own Y-axis range (FR-008)
    // NOTE: Bounds are keyed by SERIES ID (not axis ID) for user-friendly API
    // CRITICAL: Compute bounds whenever perSeries mode is active, not just when
    // multiple Y-axes exist. Otherwise range annotations with Y values will render
    // off-screen because the transform uses normalized Y range (-0.05 to 1.05).
    Map<String, DataRange>? thresholdSeriesBounds;
    if (_multiAxisManager.effectiveNormalizationMode ==
            NormalizationMode.perSeries &&
        _multiAxisManager.series.isNotEmpty) {
      thresholdSeriesBounds = _computeSeriesBounds(forPainting: true);
    }

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
          // For perSeries mode: update axis bounds for correct Y-value normalization
          // Use seriesId from annotation if specified, otherwise use first available series
          if (thresholdSeriesBounds != null &&
              thresholdSeriesBounds.isNotEmpty &&
              (element.annotation.startY != null ||
                  element.annotation.endY != null)) {
            final seriesId = element.annotation.seriesId;
            final axisBoundsToUse = seriesId != null
                ? thresholdSeriesBounds[seriesId]
                : thresholdSeriesBounds.values.first;
            element.updateAxisBounds(axisBoundsToUse);
          } else {
            element.updateAxisBounds(null);
          }
        } else if (element is ThresholdAnnotationElement) {
          element.updateTransform(_transform!);
          // For perSeries mode: update axis bounds for correct Y-value normalization
          // Use seriesId from annotation if specified, otherwise use first available series
          if (thresholdSeriesBounds != null &&
              thresholdSeriesBounds.isNotEmpty &&
              element.annotation.axis == AnnotationAxis.y) {
            final seriesId = element.annotation.seriesId;
            final axisBoundsToUse = seriesId != null
                ? thresholdSeriesBounds[seriesId]
                : thresholdSeriesBounds.values.first;
            element.updateAxisBounds(axisBoundsToUse);
          } else {
            element.updateAxisBounds(null);
          }
        } else if (element is TrendAnnotationElement) {
          element.updateTransform(_transform!);
          // For perSeries mode: update axis bounds for correct Y-value normalization
          // Use seriesId from the annotation's linked series
          if (thresholdSeriesBounds != null &&
              thresholdSeriesBounds.isNotEmpty) {
            final seriesId = element.annotation.seriesId;
            final axisBoundsToUse = thresholdSeriesBounds[seriesId];
            element.updateAxisBounds(axisBoundsToUse);
          } else {
            element.updateAxisBounds(null);
          }
        } else if (element is ChordAnnotationElement) {
          element.updateTransform(_transform!);
          if (thresholdSeriesBounds != null &&
              thresholdSeriesBounds.isNotEmpty) {
            final seriesId = element.annotation.seriesId;
            final axisBoundsToUse = thresholdSeriesBounds[seriesId];
            element.updateAxisBounds(axisBoundsToUse);
          } else {
            element.updateAxisBounds(null);
          }
        } else if (element is PinAnnotationElement) {
          element.updateTransform(_transform!);
        }
      }

      element.paint(canvas, _plotArea.size);
    }

    canvas
        .restore(); // Restore canvas state (removes clipping and translation from plot area)

    // LAYER 3: Overlays (dynamic, always rendered fresh).
    // Crosshair, selection box, and interaction feedback paint directly.
    // Tooltip surfaces retain an isolated layer for stable shadow/translucency
    // blending, while lightweight overlays avoid the full-widget allocation.
    if (_hasActiveOverlayContent()) {
      if (_hasActiveTooltipOverlay()) {
        canvas.saveLayer(Offset.zero & size, Paint());
        _paintOverlayLayer(canvas, size);
        canvas.restore();
      } else {
        _paintOverlayLayer(canvas, size);
      }
    } else if (!_valueSummaryTrackingActive) {
      // No overlay content means no tracking source either (cursor gone or
      // crosshair gated off): publish the null snapshot so future consumers
      // of the resolver never observe the stale hover state. Skipped while
      // the value summary consumed this frame's tracking resolution — the
      // summary is a live consumer of the resolver state.
      _trackingSnapshotResolver.clear();
    }

    // Paint scrollbars if enabled (outside plot area clipping)
    _scrollbarManager.paint(canvas, size);

    canvas.restore(); // Final restore (removes initial offset translation)

    // The value summary's assistive surface (content, bounds, focus,
    // capabilities) is final for this frame now that the foreground element
    // pass has painted the panel; re-flush semantics only when it changed.
    _updateValueSummarySemanticsDirty();
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

  void _paintIntervalSelectionHandles(
    Canvas canvas,
    Rect selectionRect,
    Color color,
  ) {
    final acquisitionMode = _interactionConfig?.selection.acquisitionMode;
    if (acquisitionMode != ChartSelectionAcquisitionMode.xInterval &&
        acquisitionMode != ChartSelectionAcquisitionMode.yInterval) {
      return;
    }
    final handlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = _theme?.backgroundColor ?? const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final transposed = _transform?.transposed ?? false;
    final usesScreenX =
        acquisitionMode == ChartSelectionAcquisitionMode.xInterval
        ? !transposed
        : transposed;
    final centers = usesScreenX
        ? <Offset>[selectionRect.centerLeft, selectionRect.centerRight]
        : <Offset>[selectionRect.topCenter, selectionRect.bottomCenter];
    for (final center in centers) {
      canvas.drawCircle(center, 5, handlePaint);
      canvas.drawCircle(center, 5, outlinePaint);
    }
  }

  void _paintPersistentSelectionBrush(Canvas canvas) {
    final state = _selectionBrushState;
    final selection = _interactionConfig?.selection;
    if (state == null ||
        !state.visible ||
        selection == null ||
        !selection.brush.enabled) {
      return;
    }
    final rect =
        _eventHandlerManager.activeSelectionBrushRect ??
        selectionBrushWidgetRect;
    if (rect == null || rect.isEmpty) return;
    final style = selection.brush.style;
    final selectionColor =
        _theme?.interactionTheme.selectionColor ?? const Color(0xFF0088FF);
    final active =
        coordinator.currentMode == InteractionMode.selectionBrushManipulating;
    final opacity = active
        ? style.activeOpacity
        : _eventHandlerManager.selectionBrushHovered
        ? style.hoverOpacity
        : style.fillOpacity;
    final fillColor = style.fillColor ?? selectionColor;
    final borderColor = style.borderColor ?? selectionColor;
    final keyboardFocusBorderColor =
        style.keyboardFocusBorderColor ?? borderColor;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(style.borderRadius),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = fillColor.withValues(alpha: opacity)
        ..style = PaintingStyle.fill,
    );
    _paintPersistentSelectionBrushGrid(canvas, rrect, style.grid, borderColor);
    if (style.borderWidth > 0) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.borderWidth,
      );
    }
    if (_selectionBrushKeyboardFocused &&
        _selectionBrushKeyboardTarget == _SelectionBrushKeyboardTarget.body) {
      canvas.drawRRect(
        rrect.inflate(3),
        Paint()
          ..color = keyboardFocusBorderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    _paintPersistentSelectionBrushHandles(canvas, rect, state, selectionColor);
  }

  void _paintPersistentSelectionBrushGrid(
    Canvas canvas,
    RRect bounds,
    ChartSelectionBrushGridStyle grid,
    Color fallbackColor,
  ) {
    if (grid.direction == ChartSelectionBrushGridDirection.none ||
        grid.lineWidth <= 0) {
      return;
    }
    final rect = bounds.outerRect;
    final path = Path();
    if (grid.showsHorizontal && grid.rows > 1) {
      for (var row = 1; row < grid.rows; row++) {
        final y = rect.top + rect.height * row / grid.rows;
        path.moveTo(rect.left, y);
        path.lineTo(rect.right, y);
      }
    }
    if (grid.showsVertical && grid.columns > 1) {
      for (var column = 1; column < grid.columns; column++) {
        final x = rect.left + rect.width * column / grid.columns;
        path.moveTo(x, rect.top);
        path.lineTo(x, rect.bottom);
      }
    }
    if (path.computeMetrics().isEmpty) return;
    final pattern = switch (grid.pattern) {
      ChartSelectionBrushGridPattern.solid => const <double>[],
      ChartSelectionBrushGridPattern.dashed => const <double>[6, 4],
      ChartSelectionBrushGridPattern.dotted => const <double>[1, 4],
    };
    final paint = Paint()
      ..color = grid.color ?? fallbackColor.withValues(alpha: 0.62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = grid.lineWidth
      ..strokeCap = grid.pattern == ChartSelectionBrushGridPattern.dotted
          ? StrokeCap.round
          : StrokeCap.butt;
    canvas.save();
    canvas.clipRRect(bounds);
    canvas.drawPath(
      pattern.isEmpty ? path : createDashedPath(path, pattern),
      paint,
    );
    canvas.restore();
  }

  void _paintPersistentSelectionBrushHandles(
    Canvas canvas,
    Rect rect,
    ChartSelectionBrushState state,
    Color selectionColor,
  ) {
    final style = _interactionConfig!.selection.brush.style;
    final isBox =
        state.acquisitionMode == ChartSelectionAcquisitionMode.rectangle;
    final transposed = _transform?.transposed ?? false;
    final usesScreenX =
        state.acquisitionMode == ChartSelectionAcquisitionMode.xInterval
        ? !transposed
        : transposed;
    final centers = isBox
        ? <Offset>[
            rect.topLeft,
            rect.topCenter,
            rect.topRight,
            rect.centerRight,
            rect.bottomRight,
            rect.bottomCenter,
            rect.bottomLeft,
            rect.centerLeft,
          ]
        : usesScreenX
        ? <Offset>[rect.centerLeft, rect.centerRight]
        : <Offset>[rect.topCenter, rect.bottomCenter];
    final shortSide = style.handleSize;
    final longSide = math.max(style.handleSize, style.handleSize * 1.8);
    final fill = style.handleFillColor ?? selectionColor;
    final keyboardFocusBorderColor =
        style.keyboardFocusBorderColor ?? style.borderColor ?? selectionColor;
    final outline =
        style.handleBorderColor ??
        _theme?.backgroundColor ??
        const Color(0xFFFFFFFF);
    for (final (index, center) in centers.indexed) {
      final handleRect = Rect.fromCenter(
        center: center,
        width: isBox ? shortSide : (usesScreenX ? shortSide : longSide),
        height: isBox ? shortSide : (usesScreenX ? longSide : shortSide),
      );
      final handle = RRect.fromRectAndRadius(
        handleRect,
        Radius.circular(math.min(4, shortSide / 2)),
      );
      final focusedHandleIndex = _selectionBrushFocusedHandleIndex(
        state,
        centers,
      );
      if (_selectionBrushKeyboardFocused && index == focusedHandleIndex) {
        canvas.drawRRect(
          handle.inflate(4),
          Paint()
            ..color = keyboardFocusBorderColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      canvas.drawRRect(
        handle,
        Paint()
          ..color = fill
          ..style = PaintingStyle.fill,
      );
      if (style.handleBorderWidth > 0) {
        canvas.drawRRect(
          handle,
          Paint()
            ..color = outline
            ..style = PaintingStyle.stroke
            ..strokeWidth = style.handleBorderWidth,
        );
      }
    }
  }

  int? _selectionBrushFocusedHandleIndex(
    ChartSelectionBrushState state,
    List<Offset> centers,
  ) {
    final target = _selectionBrushKeyboardTarget;
    if (state.acquisitionMode == ChartSelectionAcquisitionMode.rectangle ||
        target == _SelectionBrushKeyboardTarget.body ||
        centers.length != 2) {
      return null;
    }
    final range = state.range;
    final transform =
        state.acquisitionMode == ChartSelectionAcquisitionMode.yInterval
        ? _selectionBrushReferenceTransform(range.referenceSeriesId)
        : _transform;
    if (transform == null) return null;
    final minimumPlot =
        state.acquisitionMode == ChartSelectionAcquisitionMode.xInterval
        ? transform.dataToPlot(range.minimum, transform.dataYMin)
        : transform.dataToPlot(transform.dataXMin, range.minimum);
    final minimumWidget = plotToWidget(minimumPlot);
    final minimumIndex =
        (minimumWidget - centers.first).distanceSquared <=
            (minimumWidget - centers.last).distanceSquared
        ? 0
        : 1;
    return target == _SelectionBrushKeyboardTarget.lowerBound
        ? minimumIndex
        : 1 - minimumIndex;
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
    double normalizedValue,
    double seriesMin,
    double seriesMax,
  ) {
    return _multiAxisManager.denormalizeYValue(
      normalizedValue,
      seriesMin,
      seriesMax,
    );
  }

  /// Draws a tooltip for the hovered marker.
  ///
  /// Delegates to [TooltipRenderer] module for the actual rendering.
  void _drawMarkerTooltip(
    Canvas canvas,
    Size size,
    HoveredMarkerInfo markerInfo,
  ) {
    if (!_elements.whereType<DataHitElement>().any(
      (element) => element.id == markerInfo.seriesId,
    )) {
      _tooltipAnimator.hideImmediately();
      _debugTooltipRect = null;
      return;
    }
    _debugTooltipRect = _tooltipRenderer.drawMarkerTooltip(
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
      textScaleFactor: _textScaleFactor,
    );
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    final hits = _elements
        .whereType<DataHitElement>()
        .expand((element) => element.semanticDataHits)
        .toList();
    final hitCount = hits.length;
    final summaryCount = _elements
        .whereType<ChartSemanticSummaryProvider>()
        .expand((element) => element.semanticSummaries)
        .length;
    final valueSummaryPanel = _valueSummaryCoordinator.summarySemanticsInfo;
    final selectionBrush = selectionBrushWidgetRect;
    if (hitCount == 0 &&
        summaryCount == 0 &&
        valueSummaryPanel == null &&
        selectionBrush == null) {
      return;
    }
    config
      ..isSemanticBoundary = true
      ..explicitChildNodes = true
      ..textDirection = _textDirection;
    if (hitCount == 0 && summaryCount == 0) return;
    int? groupCount;
    for (final hit in hits) {
      groupCount ??= hit.groupCount;
    }
    final isRadial = hits.any(
      (hit) => hit.share != null || hit.groupCount != null,
    );
    final isRadialBar = _elements.any(
      (element) => element is RadialBarSeriesElement,
    );
    config.label = isRadialBar
        ? 'Radial Bar chart with $hitCount categories'
        : groupCount != null
        ? 'Concentric Donut chart with $groupCount rings and $hitCount slices'
        : isRadial
        ? 'Radial chart with $hitCount slices'
        : 'Cartesian chart with $hitCount data points';
  }

  @override
  void assembleSemanticsNode(
    SemanticsNode node,
    SemanticsConfiguration config,
    Iterable<SemanticsNode> children,
  ) {
    final hits = _elements
        .whereType<DataHitElement>()
        .expand((element) => element.semanticDataHits)
        .toList();
    final summaries = _elements
        .whereType<ChartSemanticSummaryProvider>()
        .expand((element) => element.semanticSummaries)
        .toList();
    final valueSummaryPanel = _valueSummaryCoordinator.summarySemanticsInfo;
    final selectionBrush = selectionBrushWidgetRect;
    if (hits.isEmpty &&
        summaries.isEmpty &&
        valueSummaryPanel == null &&
        selectionBrush == null) {
      _dataSemanticsNodes.clear();
      super.assembleSemanticsNode(node, config, children);
      return;
    }

    final nextNodes = <String, SemanticsNode>{};
    final orderedNodes = <SemanticsNode>[];
    final brushState = _selectionBrushState;
    if (selectionBrush != null && brushState != null) {
      const identity = 'selection-brush';
      final isBox =
          brushState.acquisitionMode == ChartSelectionAcquisitionMode.rectangle;
      final dimension = isBox
          ? 'Box'
          : brushState.acquisitionMode ==
                ChartSelectionAcquisitionMode.xInterval
          ? 'X'
          : 'Y';
      final semanticValue = isBox
          ? 'X ${brushState.box!.minimumX.toStringAsFixed(2)} to '
                '${brushState.box!.maximumX.toStringAsFixed(2)}, '
                'Y ${brushState.box!.minimumY.toStringAsFixed(2)} to '
                '${brushState.box!.maximumY.toStringAsFixed(2)}'
          : '${brushState.range.minimum.toStringAsFixed(2)} to '
                '${brushState.range.maximum.toStringAsFixed(2)}';
      final semanticConfig = SemanticsConfiguration()
        ..sortKey = const OrdinalSortKey(0)
        ..textDirection = _textDirection
        ..identifier = identity
        ..label = '$dimension range selection'
        ..value = semanticValue
        ..isFocusable = true
        ..isFocused = _selectionBrushKeyboardFocused
        ..customSemanticsActions = isBox
            ? const {}
            : {
                _selectionBrushMoveLowerAction: () =>
                    _performSelectionBrushSemanticAdjustment(moveSteps: -1),
                _selectionBrushMoveHigherAction: () =>
                    _performSelectionBrushSemanticAdjustment(moveSteps: 1),
                _selectionBrushLowerBoundLowerAction: () =>
                    _performSelectionBrushSemanticAdjustment(lowerSteps: -1),
                _selectionBrushLowerBoundHigherAction: () =>
                    _performSelectionBrushSemanticAdjustment(lowerSteps: 1),
                _selectionBrushUpperBoundLowerAction: () =>
                    _performSelectionBrushSemanticAdjustment(upperSteps: -1),
                _selectionBrushUpperBoundHigherAction: () =>
                    _performSelectionBrushSemanticAdjustment(upperSteps: 1),
              };
      final semanticNode =
          _dataSemanticsNodes[identity] ??
          SemanticsNode(key: const ValueKey(identity));
      semanticNode
        ..rect = selectionBrush
        ..updateWith(config: semanticConfig);
      nextNodes[identity] = semanticNode;
      orderedNodes.add(semanticNode);
    }
    if (valueSummaryPanel != null) {
      // One grouped region per visible summary, shared by both
      // presentations: the label carries the `Value summary` prefix plus
      // title/context, the value the unit-carrying rows in source order. A
      // panel dragged fully outside the chart (clampToPlot false)
      // contributes no node: invisible semantics nodes are forbidden.
      final panelRect = valueSummaryPanel.bounds
          .shift(_plotArea.topLeft)
          .intersect(Offset.zero & size);
      if (!panelRect.isEmpty) {
        const identity = 'value-summary';
        final semanticConfig = SemanticsConfiguration()
          ..sortKey = const OrdinalSortKey(0)
          ..textDirection = _textDirection
          ..identifier = identity
          ..label = valueSummaryPanel.label
          ..value = valueSummaryPanel.value;
        if (valueSummaryPanel.focusable) {
          semanticConfig
            ..isFocusable = true
            ..isFocused = valueSummaryPanel.focused;
        }
        final coordinator = _valueSummaryCoordinator;
        final actions = <CustomSemanticsAction, VoidCallback>{
          // Movable (draggable annotation) panels get explicit move actions
          // regardless of the internal pointer-focus flag, so assistive
          // users who never click can still reposition the panel; each
          // action moves by one Shift+arrow step and commits once.
          if (valueSummaryPanel.movable) ...{
            _valueSummaryMoveLeftAction: () => coordinator.performSemanticMove(
              const Offset(-_valueSummarySemanticMoveStep, 0),
            ),
            _valueSummaryMoveRightAction: () => coordinator.performSemanticMove(
              const Offset(_valueSummarySemanticMoveStep, 0),
            ),
            _valueSummaryMoveUpAction: () => coordinator.performSemanticMove(
              const Offset(0, -_valueSummarySemanticMoveStep),
            ),
            _valueSummaryMoveDownAction: () => coordinator.performSemanticMove(
              const Offset(0, _valueSummarySemanticMoveStep),
            ),
            _valueSummaryResetPositionAction: () =>
                coordinator.resetAnnotationPlacement(emit: true),
          },
          if (valueSummaryPanel.canPin)
            _valueSummaryPinAction: coordinator.performSemanticPin,
          if (valueSummaryPanel.canClearPin)
            _valueSummaryClearPinAction: coordinator.performSemanticClearPin,
        };
        if (actions.isNotEmpty) {
          semanticConfig.customSemanticsActions = actions;
        }
        final semanticNode =
            _dataSemanticsNodes[identity] ??
            SemanticsNode(key: const ValueKey(identity));
        semanticNode
          ..rect = panelRect
          ..updateWith(config: semanticConfig);
        nextNodes[identity] = semanticNode;
        orderedNodes.add(semanticNode);
      }
    }
    for (final summary in summaries) {
      final summaryRect = summary.bounds
          .shift(_plotArea.topLeft)
          .intersect(Offset.zero & size);
      if (summaryRect.isEmpty) continue;
      final identity = 'summary:${summary.id}';
      final semanticConfig = SemanticsConfiguration()
        ..sortKey = const OrdinalSortKey(0)
        ..textDirection = _textDirection
        ..identifier = identity
        ..label = summary.label;
      final semanticNode =
          _dataSemanticsNodes[identity] ??
          SemanticsNode(key: ValueKey(identity));
      semanticNode
        ..rect = summaryRect
        ..updateWith(config: semanticConfig);
      nextNodes[identity] = semanticNode;
      orderedNodes.add(semanticNode);
    }
    for (final hit in hits) {
      final hitRect = hit.semanticBounds
          .shift(_plotArea.topLeft)
          .intersect(Offset.zero & size);
      if (hitRect.isEmpty) continue;
      final identity = '${hit.seriesId}:${hit.pointIndex}';
      final semanticConfig = SemanticsConfiguration()
        ..sortKey = OrdinalSortKey(hit.semanticSortOrdinal + 1)
        ..textDirection = _textDirection
        ..identifier = identity
        ..label = hit.semanticLabel
        ..isSelected = hit.isSelected
        ..isFocusable = true
        ..isFocused = hit.isFocused;
      if (hit.isActivatable) {
        semanticConfig
          ..isButton = true
          ..onTap = () => onDataHitActivate?.call(hit);
      }
      semanticConfig.onDidGainAccessibilityFocus = () {
        onDataHitFocus?.call(hit);
      };
      final semanticNode =
          _dataSemanticsNodes[identity] ??
          SemanticsNode(key: ValueKey(identity));
      semanticNode
        ..rect = hitRect
        ..updateWith(config: semanticConfig);
      nextNodes[identity] = semanticNode;
      orderedNodes.add(semanticNode);
    }
    _dataSemanticsNodes
      ..clear()
      ..addAll(nextNodes);
    node.updateWith(config: config, childrenInInversePaintOrder: orderedNodes);
  }

  @override
  void clearSemantics() {
    super.clearSemantics();
    _dataSemanticsNodes.clear();
  }

  // ============================================================================
  // Debug
  // ============================================================================

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('elementCount', _elements.length));
    properties.add(
      DiagnosticsProperty<QuadTreeStats>(
        'spatialIndexStats',
        _spatialIndex?.stats,
      ),
    );
    properties.add(
      StringProperty('coordinatorState', coordinator.debugState()),
    );
  }

  // ============================================================================
  // Multi-Axis Normalization Helpers (FR-008)
  // ============================================================================

  /// Normalizes a Y-axis value from data space to normalized `0..1` space.
  ///
  /// Delegates to [MultiAxisManager.normalizeValue].
  double normalizeValue(double value, double min, double max) {
    return _multiAxisManager.normalizeValue(value, min, max);
  }

  /// Denormalizes a value from normalized `0..1` space back to data space.
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
    _renderBox._invalidateTrackingResolution();
  }

  @override
  void setPanConstraintBounds(
    double minX,
    double maxX,
    double minY,
    double maxY,
  ) {
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
    String annotationId,
    ChartAnnotation updatedAnnotation,
  ) {
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

  @override
  ChartSelectionBrushState? get selectionBrushState =>
      _renderBox._selectionBrushState;

  @override
  Rect? get selectionBrushWidgetRect => _renderBox.selectionBrushWidgetRect;

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
  void Function(String, ChartAnnotation)? get onAnnotationDragUpdate =>
      _renderBox.onAnnotationDragUpdate;

  @override
  void Function(double, double, double, double)? get onRangeCreationComplete =>
      _renderBox.onRangeCreationComplete;

  @override
  VoidCallback? get onViewportInteracted => _renderBox.onViewportInteracted;

  @override
  VoidCallback? get onViewportChanged => _renderBox.onViewportChanged;

  @override
  void Function(ChartSelectionGestureResult)? get onSelectionGestureComplete =>
      _renderBox.onSelectionGestureComplete;

  // ============================================================================
  // Hit testing
  // ============================================================================

  @override
  ChartElement? hitTestElements(Offset position) {
    return _renderBox.hitTestElements(position);
  }

  @override
  ChartElement? hitTestAnnotationInteractionTarget(Offset position) {
    return _renderBox.hitTestAnnotationInteractionTarget(position);
  }

  @override
  List<ChartElement> hitTestRect(Rect rect) {
    return _renderBox.hitTestRect(rect).toList();
  }

  @override
  List<ChartDataHit> hitTestDataRect(Rect rect) {
    return _renderBox.dataHitsInWidgetRect(rect);
  }

  @override
  List<ChartDataHit> hitTestDataPolygon(List<Offset> polygon) {
    return _renderBox.dataHitsInWidgetPolygon(polygon);
  }

  @override
  ChartSelectionGestureResult? selectionGestureForWidgetRect(
    Rect widgetRect, {
    bool isPersistentBrushUpdate = false,
    bool isFinal = true,
  }) => _renderBox.selectionGestureForWidgetRect(
    widgetRect,
    isPersistentBrushUpdate: isPersistentBrushUpdate,
    isFinal: isFinal,
  );

  @override
  void rebuildSpatialIndex() {
    _renderBox._rebuildSpatialIndex();
  }

  @override
  void markSpatialIndexDirty() {
    _renderBox._spatialIndexDirty = true;
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
    _renderBox._invalidateTrackingResolution();
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

  // ============================================================================
  // Value summary annotation drag
  // ============================================================================

  @override
  ValueSummaryAnnotationElement? get valueSummaryDragTarget =>
      _renderBox.valueSummaryDragTarget;

  @override
  void beginValueSummaryDrag() => _renderBox.beginValueSummaryDrag();

  @override
  void updateValueSummaryDrag(Offset panelOriginPlot) =>
      _renderBox.updateValueSummaryDrag(panelOriginPlot);

  @override
  void commitValueSummaryDrag() => _renderBox.commitValueSummaryDrag();

  @override
  void cancelValueSummaryDrag() => _renderBox.cancelValueSummaryDrag();

  @override
  bool setValueSummaryFocus(bool focused) =>
      _renderBox.setValueSummaryFocus(focused);

  // ============================================================================
  // Per-series normalization support
  // ============================================================================

  @override
  bool get isPerSeriesMode =>
      _renderBox._multiAxisManager.effectiveNormalizationMode ==
      NormalizationMode.perSeries;

  @override
  (double startY, double endY) denormalizeYRange(
    double normalizedStartY,
    double normalizedEndY, {
    String? seriesId,
  }) {
    // Use axisBounds - this is what the Y-axis labels show and what crosshair uses.
    // The input values are already true 0-1 normalized (calculated like crosshair does).
    final axisBounds = _renderBox._computeAxisBounds();

    // Use first available axis bounds (same approach as crosshair for single axis)
    if (axisBounds.isNotEmpty) {
      final bounds = axisBounds.values.first;

      // Denormalize exactly like crosshair: MultiAxisNormalizer.denormalize(yValue, bounds.min, bounds.max)
      final startY = MultiAxisNormalizer.denormalize(
        normalizedStartY,
        bounds.min,
        bounds.max,
      );
      final endY = MultiAxisNormalizer.denormalize(
        normalizedEndY,
        bounds.min,
        bounds.max,
      );

      return (startY, endY);
    }

    // If no bounds available, return unchanged
    return (normalizedStartY, normalizedEndY);
  }

  @override
  (double min, double max) getActualYRange() {
    // In perSeries mode, use axisBounds (actual data range)
    // In other modes, use transform's Y range
    if (isPerSeriesMode) {
      final axisBounds = _renderBox._computeAxisBounds();
      if (axisBounds.isNotEmpty) {
        final bounds = axisBounds.values.first;
        return (bounds.min, bounds.max);
      }
    }

    // Fallback to transform range
    final transform = _renderBox._transform;
    if (transform != null) {
      return (transform.dataYMin, transform.dataYMax);
    }

    return (0.0, 1.0);
  }
}
