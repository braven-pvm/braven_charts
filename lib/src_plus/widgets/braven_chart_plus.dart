// Copyright (c) 2025 braven_charts. All rights reserved.
// BravenChartPlus - Integration of Prototype Interaction System
// NO REFERENCES TO lib/src - COMPLETELY ISOLATED

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// All dependencies are now in src_plus - NO references to src!
import '../axis/axis.dart' as chart_axis;
import '../axis/axis_config.dart';
import '../controllers/annotation_controller.dart';
import '../controllers/chart_controller.dart';
import '../coordinates/chart_transform.dart';
import '../elements/annotation_elements.dart';
import '../elements/series_element.dart';
import '../interaction/core/chart_element.dart';
import '../interaction/core/coordinator.dart';
import '../interaction/core/interaction_mode.dart';
import '../interaction/recognizers/priority_pan_recognizer.dart';
import '../interaction/recognizers/priority_tap_recognizer.dart';
import '../models/auto_scroll_config.dart';
import '../models/chart_annotation.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';
import '../models/chart_theme.dart';
import '../models/chart_type.dart';
import '../models/enums.dart';
import '../models/interaction_config.dart';
import '../models/streaming_config.dart';
import '../rendering/chart_render_box.dart';
import '../rendering/spatial_index.dart';
import '../streaming/buffer_manager.dart';
import '../streaming/streaming_controller.dart';
import '../theming/components/scrollbar_config.dart';
import '../utils/data_converter.dart';
import 'chart_legend.dart';
import 'dialogs/point_annotation_dialog.dart';
import 'dialogs/range_annotation_dialog.dart';
import 'dialogs/text_annotation_dialog.dart';
import 'dialogs/threshold_annotation_dialog.dart';
import 'dialogs/trend_annotation_dialog.dart';
import 'web_context_menu.dart';

/// Next-generation BravenChart with prototype interaction system.
///
/// **⚠️ COMPLETELY ISOLATED** - No references to lib/src!
///
/// **Architecture** (from PrototypeChart):
/// - RenderBox with handleEvent() for direct pointer events
/// - ChartInteractionCoordinator for unified state management
/// - QuadTree spatial indexing for O(log n) hit testing
///
/// **Current Phase**: Foundation - Widget skeleton created
/// Next: Create example app to test empty widget
class BravenChartPlus extends StatefulWidget {
  const BravenChartPlus({
    super.key,
    required this.chartType,
    this.lineStyle = LineStyle.straight,
    required this.series,
    this.annotations = const [],
    this.annotationController,
    this.theme,
    this.xAxis,
    this.yAxis,
    this.width,
    this.height,
    this.backgroundColor = Colors.white,
    this.showDebugInfo = false,
    this.showXScrollbar = false,
    this.showYScrollbar = false,
    this.scrollbarTheme,
    this.dataStream,
    this.streamingConfig,
    this.streamingController,
    this.controller,
    this.interactionConfig,
    this.title,
    this.subtitle,
    this.showLegend = true,
    this.showToolbar = false,
    this.interactiveAnnotations = true,
    this.loadingWidget,
    this.errorWidget,
    this.autoScrollConfig,
    this.onPointTap,
    this.onPointHover,
    this.onBackgroundTap,
    this.onSeriesSelected,
    this.onAnnotationTap,
    this.onAnnotationDragged,
  });

  // ==================== FACTORY CONSTRUCTORS ====================

  /// Creates a chart from a simple list of y-values.
  factory BravenChartPlus.fromValues({
    Key? key,
    required ChartType chartType,
    LineStyle lineStyle = LineStyle.straight,
    required String seriesId,
    required List<double> yValues,
    List<double>? xValues,
    String? seriesName,
    Color? seriesColor,
    double? width,
    double? height,
    ChartTheme? theme,
    AxisConfig? xAxis,
    AxisConfig? yAxis,
    List<ChartAnnotation> annotations = const [],
    ChartController? controller,
    AutoScrollConfig? autoScrollConfig,
    String? title,
    String? subtitle,
    bool showLegend = true,
    bool showToolbar = false,
    bool interactiveAnnotations = true,
    Widget? loadingWidget,
    Widget Function(Object error)? errorWidget,
    void Function(ChartDataPoint point, String seriesId)? onPointTap,
    void Function(ChartDataPoint? point, String? seriesId)? onPointHover,
    void Function(Offset position)? onBackgroundTap,
    void Function(String seriesId)? onSeriesSelected,
    void Function(ChartAnnotation annotation)? onAnnotationTap,
    void Function(ChartAnnotation annotation, Offset newPosition)? onAnnotationDragged,
    InteractionConfig? interactionConfig,
  }) {
    // Generate x-values if not provided
    final xVals = xValues ?? List.generate(yValues.length, (i) => i.toDouble());

    // Validate lengths match
    assert(xVals.length == yValues.length, 'X and Y value lists must have the same length');

    // Create data points
    final points = List.generate(yValues.length, (i) => ChartDataPoint(x: xVals[i], y: yValues[i]));

    // Create series
    final series = LineChartSeries(
      id: seriesId,
      name: seriesName ?? seriesId,
      points: points,
      color: seriesColor ?? Colors.blue,
      interpolation: switch (lineStyle) {
        LineStyle.straight => LineInterpolation.linear,
        LineStyle.smooth => LineInterpolation.bezier,
        LineStyle.stepped => LineInterpolation.stepped,
      },
    );

    return BravenChartPlus(
      key: key,
      chartType: chartType,
      lineStyle: lineStyle,
      series: [series],
      width: width,
      height: height,
      theme: theme,
      xAxis: xAxis,
      yAxis: yAxis,
      annotations: annotations,
      controller: controller,
      autoScrollConfig: autoScrollConfig,
      title: title,
      subtitle: subtitle,
      showLegend: showLegend,
      showToolbar: showToolbar,
      interactiveAnnotations: interactiveAnnotations,
      loadingWidget: loadingWidget,
      errorWidget: errorWidget,
      onPointTap: onPointTap,
      onPointHover: onPointHover,
      onBackgroundTap: onBackgroundTap,
      onSeriesSelected: onSeriesSelected,
      onAnnotationTap: onAnnotationTap,
      onAnnotationDragged: onAnnotationDragged,
      interactionConfig: interactionConfig,
    );
  }

  /// Creates a chart from a Map of x->y values.
  factory BravenChartPlus.fromMap({
    Key? key,
    required ChartType chartType,
    LineStyle lineStyle = LineStyle.straight,
    required String seriesId,
    required Map<dynamic, double> data,
    String? seriesName,
    Color? seriesColor,
    double? width,
    double? height,
    ChartTheme? theme,
    AxisConfig? xAxis,
    AxisConfig? yAxis,
    List<ChartAnnotation> annotations = const [],
    ChartController? controller,
    AutoScrollConfig? autoScrollConfig,
    String? title,
    String? subtitle,
    bool showLegend = true,
    bool showToolbar = false,
    bool interactiveAnnotations = true,
    Widget? loadingWidget,
    Widget Function(Object error)? errorWidget,
    void Function(ChartDataPoint point, String seriesId)? onPointTap,
    void Function(ChartDataPoint? point, String? seriesId)? onPointHover,
    void Function(Offset position)? onBackgroundTap,
    void Function(String seriesId)? onSeriesSelected,
    void Function(ChartAnnotation annotation)? onAnnotationTap,
    void Function(ChartAnnotation annotation, Offset newPosition)? onAnnotationDragged,
    InteractionConfig? interactionConfig,
  }) {
    // Convert map to data points
    final points = data.entries.map((entry) {
      // Convert key to double (supports int, double, String numbers)
      final x = switch (entry.key) {
        final int v => v.toDouble(),
        final double v => v,
        final String v => double.parse(v),
        _ => throw ArgumentError('Map keys must be numeric or numeric strings'),
      };
      return ChartDataPoint(x: x, y: entry.value);
    }).toList();

    // Create series
    final series = LineChartSeries(
      id: seriesId,
      name: seriesName ?? seriesId,
      points: points,
      color: seriesColor ?? Colors.blue,
      interpolation: switch (lineStyle) {
        LineStyle.straight => LineInterpolation.linear,
        LineStyle.smooth => LineInterpolation.bezier,
        LineStyle.stepped => LineInterpolation.stepped,
      },
    );

    return BravenChartPlus(
      key: key,
      chartType: chartType,
      lineStyle: lineStyle,
      series: [series],
      width: width,
      height: height,
      theme: theme,
      xAxis: xAxis,
      yAxis: yAxis,
      annotations: annotations,
      controller: controller,
      autoScrollConfig: autoScrollConfig,
      title: title,
      subtitle: subtitle,
      showLegend: showLegend,
      showToolbar: showToolbar,
      interactiveAnnotations: interactiveAnnotations,
      loadingWidget: loadingWidget,
      errorWidget: errorWidget,
      onPointTap: onPointTap,
      onPointHover: onPointHover,
      onBackgroundTap: onBackgroundTap,
      onSeriesSelected: onSeriesSelected,
      onAnnotationTap: onAnnotationTap,
      onAnnotationDragged: onAnnotationDragged,
      interactionConfig: interactionConfig,
    );
  }

  /// Creates a chart from a JSON string.
  factory BravenChartPlus.fromJson({
    Key? key,
    required ChartType chartType,
    LineStyle lineStyle = LineStyle.straight,
    required String seriesId,
    required String json,
    String? seriesName,
    Color? seriesColor,
    double? width,
    double? height,
    ChartTheme? theme,
    AxisConfig? xAxis,
    AxisConfig? yAxis,
    List<ChartAnnotation> annotations = const [],
    ChartController? controller,
    AutoScrollConfig? autoScrollConfig,
    String? title,
    String? subtitle,
    bool showLegend = true,
    bool showToolbar = false,
    bool interactiveAnnotations = true,
    Widget? loadingWidget,
    Widget Function(Object error)? errorWidget,
    void Function(ChartDataPoint point, String seriesId)? onPointTap,
    void Function(ChartDataPoint? point, String? seriesId)? onPointHover,
    void Function(Offset position)? onBackgroundTap,
    void Function(String seriesId)? onSeriesSelected,
    void Function(ChartAnnotation annotation)? onAnnotationTap,
    void Function(ChartAnnotation annotation, Offset newPosition)? onAnnotationDragged,
    InteractionConfig? interactionConfig,
    StreamingConfig? streamingConfig,
    Stream<ChartDataPoint>? dataStream,
    StreamingController? streamingController,
    bool showDebugInfo = false,
    bool showXScrollbar = false,
    bool showYScrollbar = false,
    ScrollbarConfig? scrollbarTheme,
    AnnotationController? annotationController,
  }) {
    // Parse JSON
    final dynamic decoded = jsonDecode(json);

    // Convert to list of points
    final List<ChartDataPoint> points;
    if (decoded is List) {
      points = decoded.map((item) {
        if (item is Map<String, dynamic>) {
          return ChartDataPoint(
            x: (item['x'] as num).toDouble(),
            y: (item['y'] as num).toDouble(),
            label: item['label'] as String?,
          );
        } else {
          throw ArgumentError('JSON array must contain objects with x and y properties');
        }
      }).toList();
    } else {
      throw ArgumentError('JSON must be an array of data points');
    }

    // Create series
    final ChartSeries series;
    switch (chartType) {
      case ChartType.line:
        series = LineChartSeries(
          id: seriesId,
          name: seriesName ?? seriesId,
          points: points,
          color: seriesColor ?? Colors.blue,
          interpolation: switch (lineStyle) {
            LineStyle.straight => LineInterpolation.linear,
            LineStyle.smooth => LineInterpolation.bezier,
            LineStyle.stepped => LineInterpolation.stepped,
          },
        );
      case ChartType.area:
        series = AreaChartSeries(
          id: seriesId,
          name: seriesName ?? seriesId,
          points: points,
          color: seriesColor ?? Colors.blue,
          interpolation: switch (lineStyle) {
            LineStyle.straight => LineInterpolation.linear,
            LineStyle.smooth => LineInterpolation.bezier,
            LineStyle.stepped => LineInterpolation.stepped,
          },
        );
      case ChartType.bar:
        series = BarChartSeries(
          id: seriesId,
          name: seriesName ?? seriesId,
          points: points,
          color: seriesColor ?? Colors.blue,
          barWidthPercent: 0.8,
        );
      case ChartType.scatter:
        series = ScatterChartSeries(
          id: seriesId,
          name: seriesName ?? seriesId,
          points: points,
          color: seriesColor ?? Colors.blue,
        );
    }

    return BravenChartPlus(
      key: key,
      chartType: chartType,
      lineStyle: lineStyle,
      series: [series],
      width: width,
      height: height,
      theme: theme,
      xAxis: xAxis,
      yAxis: yAxis,
      annotations: annotations,
      controller: controller,
      autoScrollConfig: autoScrollConfig,
      title: title,
      subtitle: subtitle,
      showLegend: showLegend,
      showToolbar: showToolbar,
      interactiveAnnotations: interactiveAnnotations,
      loadingWidget: loadingWidget,
      errorWidget: errorWidget,
      onPointTap: onPointTap,
      onPointHover: onPointHover,
      onBackgroundTap: onBackgroundTap,
      onSeriesSelected: onSeriesSelected,
      onAnnotationTap: onAnnotationTap,
      onAnnotationDragged: onAnnotationDragged,
      interactionConfig: interactionConfig,
      streamingConfig: streamingConfig,
      dataStream: dataStream,
      streamingController: streamingController,
      showDebugInfo: showDebugInfo,
      showXScrollbar: showXScrollbar,
      showYScrollbar: showYScrollbar,
      scrollbarTheme: scrollbarTheme,
      annotationController: annotationController,
    );
  }

  final ChartType chartType;
  final LineStyle lineStyle;
  final List<ChartSeries> series;

  /// **Deprecated**: Use [annotationController] for reactive annotation management.
  ///
  /// Static list of annotations. For editable annotations with reactive updates,
  /// use [annotationController] instead. If both are provided, [annotationController]
  /// takes precedence.
  final List<ChartAnnotation> annotations;

  /// Optional controller for managing annotations with CRUD operations.
  ///
  /// Provides reactive updates when annotations are added, modified, or removed.
  /// Recommended for editable annotations (e.g., drag-to-resize ranges).
  ///
  /// Example:
  /// ```dart
  /// final controller = AnnotationController();
  /// controller.addAnnotation(RangeAnnotation(...));
  ///
  /// BravenChartPlus(
  ///   annotationController: controller,
  ///   // annotations are managed via controller
  /// )
  /// ```
  ///
  /// If null, uses [annotations] list directly (backward compatible).
  final AnnotationController? annotationController;

  final ChartTheme? theme;
  final AxisConfig? xAxis;
  final AxisConfig? yAxis;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final bool showDebugInfo;

  /// Whether to show horizontal scrollbar at the bottom of the chart.
  ///
  /// When enabled, displays a dual-purpose scrollbar for panning (drag handle)
  /// and zooming (drag edges). Defaults to false.
  final bool showXScrollbar;

  /// Whether to show vertical scrollbar on the right side of the chart.
  ///
  /// When enabled, displays a dual-purpose scrollbar for panning (drag handle)
  /// and zooming (drag edges). Defaults to false.
  final bool showYScrollbar;

  /// Theme configuration for scrollbars.
  ///
  /// Controls visual appearance (colors, thickness, border radius) and
  /// interaction behavior (auto-hide, zoom limits, edge grip width).
  /// If null, defaults to [ScrollbarConfig.defaultLight()].
  ///
  /// **Property Implementation Status:**
  ///
  /// ✅ **Working:** All visual properties (thickness, colors, borderRadius,
  /// edgeGripWidth, showGripIndicator, padding, minHandleSize)
  ///
  /// ❌ **Not Yet Implemented:** Animation properties (autoHide, autoHideDelay,
  /// fadeDuration), behavior flags (enableResizeHandles), accessibility
  /// (forcedColorsMode, prefersReducedMotion), zoom limits (minZoomRatio,
  /// maxZoomRatio)
  ///
  /// See [ScrollbarConfig] documentation for full property list.
  final ScrollbarConfig? scrollbarTheme;

  /// Optional controller for programmatic data updates.
  ///
  /// Matches BravenChart API. When provided, the chart will listen to
  /// controller changes and merge controller data with [series] data.
  /// Use [ChartController.addPoint] for real-time data updates.
  final ChartController? controller;

  /// Optional stream of real-time data points.
  ///
  /// When provided, the chart will subscribe to this stream and add incoming
  /// data points to the first series. For multiple series streaming, use
  /// [StreamingController] to manage data programmatically.
  final Stream<ChartDataPoint>? dataStream;

  /// Configuration for streaming behavior.
  ///
  /// Controls buffer size, auto-scroll, and callbacks. Only used when
  /// [dataStream] is provided. Defaults to [StreamingConfig()] if null.
  final StreamingConfig? streamingConfig;

  /// Controller for programmatic streaming control.
  ///
  /// Allows pausing/resuming streaming and provides state notifications.
  /// Optional - streaming works without it, but useful for custom UI controls.
  final StreamingController? streamingController;

  /// Configuration for interactive features (crosshair, tooltip, gestures, keyboard navigation).
  ///
  /// Controls tooltip visibility via [InteractionConfig.tooltip.enabled].
  /// If null, defaults to enabled tooltips with standard behavior.
  final InteractionConfig? interactionConfig;

  // ==================== NEW PARAMETERS FOR COMPATIBILITY ====================

  /// Chart title displayed at the top.
  final String? title;

  /// Chart subtitle displayed below the title.
  final String? subtitle;

  /// Whether to show the legend.
  ///
  /// Legend displays all series with their colors and names.
  final bool showLegend;

  /// Whether to show the toolbar.
  ///
  /// Toolbar provides refresh, download, and settings controls.
  final bool showToolbar;

  /// Whether annotations should be interactive (draggable, editable).
  ///
  /// Requires annotations to have `allowDragging = true`.
  final bool interactiveAnnotations;

  /// Widget to display while loading data.
  ///
  /// Defaults to CircularProgressIndicator.
  final Widget? loadingWidget;

  /// Widget to display when an error occurs.
  ///
  /// Receives the error object for custom error messages.
  /// Defaults to Text('Error: ...').
  final Widget Function(Object error)? errorWidget;

  /// Configuration for automatic scrolling in streaming scenarios.
  final AutoScrollConfig? autoScrollConfig;

  // ==================== CALLBACKS ====================

  /// Called when a data point is tapped.
  final void Function(ChartDataPoint point, String seriesId)? onPointTap;

  /// Called when a data point is hovered (desktop/web).
  final void Function(ChartDataPoint? point, String? seriesId)? onPointHover;

  /// Called when the chart background is tapped.
  final void Function(Offset position)? onBackgroundTap;

  /// Called when a series is selected.
  final void Function(String seriesId)? onSeriesSelected;

  /// Called when an annotation is tapped.
  final void Function(ChartAnnotation annotation)? onAnnotationTap;

  /// Called when an annotation is dragged to a new position.
  final void Function(ChartAnnotation annotation, Offset newPosition)? onAnnotationDragged;

  @override
  State<BravenChartPlus> createState() => _BravenChartPlusState();
}

class _BravenChartPlusState extends State<BravenChartPlus> {
  late ChartInteractionCoordinator _coordinator;
  late QuadTree _spatialIndex;
  late PriorityPanGestureRecognizer _panRecognizer;
  late PriorityTapGestureRecognizer _tapRecognizer;
  late FocusNode _focusNode;

  MouseCursor _currentCursor = SystemMouseCursors.basic;
  final GlobalKey _renderBoxKey = GlobalKey();

  // Element generator function for pan/zoom regeneration
  List<ChartElement> Function(ChartTransform)? _elementGenerator;

  // Generation counter to track when elements actually need regeneration
  // Only incremented in _rebuildElements when series/theme change
  int _elementGeneratorVersion = 0;

  chart_axis.Axis? _xAxis;
  chart_axis.Axis? _yAxis;

  // Streaming state
  StreamSubscription<ChartDataPoint>? _streamSubscription;
  BufferManager<ChartDataPoint>? _buffer;
  bool _isStreaming = true;
  final List<ChartDataPoint> _streamingDataPoints = [];

  // Locked viewport bounds when paused - THE FUNDAMENTAL FIX
  DataBounds? _lockedPausedBounds;

  // Cached full dataset bounds for pan constraints when paused (Option 4)
  // Updated incrementally in O(1) time as new data arrives
  double? _cachedDataXMin;
  double? _cachedDataXMax;
  double? _cachedDataYMin;
  double? _cachedDataYMax;

  // Double-click detection for annotation editing
  ChartElement? _lastTappedElement;
  DateTime? _lastTapTime;
  static const Duration _doubleTapTimeout = Duration(milliseconds: 300);

  // Hidden series IDs for legend toggling
  final Set<String> _hiddenSeriesIds = {};

  // Guard flag to prevent duplicate context menu opens
  bool _isShowingContextMenu = false;

  // Track range creation mode to trigger UI updates
  bool _wasInRangeCreationMode = false;

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
    _coordinator = ChartInteractionCoordinator();
    _coordinator.addListener(_onCoordinatorChanged);

    _spatialIndex = QuadTree(bounds: const Rect.fromLTWH(0, 0, 800, 600), maxElementsPerNode: 4);

    _panRecognizer = PriorityPanGestureRecognizer(
      coordinator: _coordinator,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
    );

    _tapRecognizer = PriorityTapGestureRecognizer(coordinator: _coordinator, onTapDown: _handleTapDown, onTapUp: _handleTapUp);

    // Listen to controller updates (matches BravenChart pattern)
    widget.controller?.addListener(_onControllerUpdate);

    // Listen to annotation controller updates
    widget.annotationController?.addListener(_onAnnotationControllerUpdate);

    _rebuildElements();

    // Initialize cached bounds from existing series data for pan constraints
    _initializeCachedDataBounds();

    // Register streaming controller callbacks (needed even without dataStream)
    widget.streamingController?.registerResumeCallback(_resumeStreaming);
    widget.streamingController?.registerPauseCallback(_pauseStreaming);
    widget.streamingController?.registerClearCallback(_clearStreamingData);

    // Set up streaming if dataStream is provided
    if (widget.dataStream != null) {
      _setupStreamSubscription();
    }
  }

  @override
  void didUpdateWidget(BravenChartPlus oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Removed excessive debugPrints (didUpdateWidget details)

    // Handle controller changes (matches BravenChart pattern)
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onControllerUpdate);
      widget.controller?.addListener(_onControllerUpdate);
    }

    // Handle annotation controller changes
    if (widget.annotationController != oldWidget.annotationController) {
      oldWidget.annotationController?.removeListener(_onAnnotationControllerUpdate);
      widget.annotationController?.addListener(_onAnnotationControllerUpdate);
    }

    if (widget.series != oldWidget.series || widget.theme != oldWidget.theme || widget.annotations != oldWidget.annotations) {
      // Removed excessive debugPrint (theme/series/annotations changed)
      _rebuildElements();
      // Request focus after rebuild to ensure keyboard events still work
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
          // Removed excessive debugPrint (focus requested)
        }
      });
    }
  }

  /// Called when focus state changes.
  void _onFocusChanged() {
    // Trigger rebuild to show/hide focus border
    setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _streamSubscription?.cancel();
    widget.controller?.removeListener(_onControllerUpdate);
    widget.annotationController?.removeListener(_onAnnotationControllerUpdate);
    _coordinator.removeListener(_onCoordinatorChanged);
    _coordinator.dispose();
    _panRecognizer.dispose();
    _tapRecognizer.dispose();
    super.dispose();
  }

  /// Called when controller notifies of changes (matches BravenChart pattern).
  void _onControllerUpdate() {
    debugPrint('🔔 _onControllerUpdate called, mounted=$mounted, controller=${widget.controller != null}');
    if (!mounted) return;

    // Update cached bounds even when paused - needed for pan constraints
    if (widget.controller != null) {
      final controllerData = widget.controller!.getAllSeries();
      debugPrint('🔔 Controller has ${controllerData.length} series');
      int totalPoints = 0;
      for (final points in controllerData.values) {
        totalPoints += points.length;
        for (final point in points) {
          // Initialize cached bounds if this is the first point
          if (_cachedDataXMin == null) {
            _cachedDataXMin = point.x;
            _cachedDataXMax = point.x;
            _cachedDataYMin = point.y;
            _cachedDataYMax = point.y;
            debugPrint('📊 Controller: Initialized cached bounds with first point: '
                'X=[$_cachedDataXMin, $_cachedDataXMax], Y=[$_cachedDataYMin, $_cachedDataYMax]');
          } else {
            _updateCachedDataBounds(point.x, point.y);
          }
        }
      }
      // Only log occasionally to avoid spam
      if (totalPoints % 50 == 0 || totalPoints < 10) {
        debugPrint('📊 Controller: Updated cached bounds from $totalPoints points: '
            'X=[$_cachedDataXMin, $_cachedDataXMax], Y=[$_cachedDataYMin, $_cachedDataYMax]');
      }
    }

    // When paused, don't rebuild - let data accumulate silently
    // This prevents visual jumps when exploring the viewport
    if (!_isStreaming) {
      debugPrint('⏸️  Controller updated while paused - data accumulating, no rebuild');
      return;
    }

    // Controller data changed - rebuild with merged data
    // This ensures controller.addPoint() updates appear immediately
    setState(() {
      _rebuildElements();
    });
  }

  /// Called when annotation controller notifies of changes.
  void _onAnnotationControllerUpdate() {
    if (!mounted) {
      return;
    }

    // Annotations changed - rebuild elements
    // NOTE: setState() will trigger build() → updateRenderObject() → setElementGenerator()
    // automatically, so we don't need to call it manually here.
    setState(() {
      _rebuildElements();
    });
  }

  /// Called when an annotation is modified through user interaction (e.g., drag-to-resize).
  void _handleAnnotationChanged(String annotationId, ChartAnnotation updatedAnnotation) {
    // Only update if we have a controller (otherwise annotations are read-only from widget.annotations)
    if (widget.annotationController != null) {
      widget.annotationController!.updateAnnotation(annotationId, updatedAnnotation);
    }

    // Call user callback
    if (widget.onAnnotationDragged != null) {
      Offset position = Offset.zero;
      if (updatedAnnotation is TextAnnotation) {
        position = updatedAnnotation.position;
      } else if (updatedAnnotation is PointAnnotation) {
        position = updatedAnnotation.offset;
      }
      widget.onAnnotationDragged!(updatedAnnotation, position);
    }
  }

  void _rebuildElements() {
    // Removed excessive debugPrints - was firing on every frame during streaming

    _spatialIndex.clear();

    // Start with widget.series as base
    List<ChartSeries> effectiveSeries = widget.series;

    // Filter out hidden series
    effectiveSeries = effectiveSeries.where((s) => !_hiddenSeriesIds.contains(s.id)).toList();

    // Merge controller data if controller is provided (matches BravenChart pattern)
    if (widget.controller != null) {
      final controllerData = widget.controller!.getAllSeries();

      // Create map of existing series for efficient lookup
      final seriesMap = <String, ChartSeries>{};
      for (final series in widget.series) {
        seriesMap[series.id] = series;
      }

      // Merge controller data into series
      final mergedSeriesList = <ChartSeries>[];
      final processedIds = <String>{};

      // Removed excessive debugPrint

      // First, update existing series with controller data
      for (final series in widget.series) {
        // Skip if hidden
        if (_hiddenSeriesIds.contains(series.id)) continue;

        final controllerPoints = controllerData[series.id];
        if (controllerPoints != null && controllerPoints.isNotEmpty) {
          // Removed excessive debugPrints - was firing on every frame

          // Convert src ChartDataPoint to src_plus ChartDataPoint
          final convertedPoints = controllerPoints
              .map((p) => ChartDataPoint(
                    x: p.x,
                    y: p.y,
                    timestamp: p.timestamp,
                    label: p.label,
                    metadata: p.metadata,
                  ))
              .toList();

          // Removed excessive debugPrint (last point details)

          // Merge series points with controller points
          final mergedPoints = [...series.points, ...convertedPoints];

          final updatedSeries = switch (series) {
            LineChartSeries() => LineChartSeries(
                id: series.id,
                name: series.name,
                points: mergedPoints,
                color: series.color,
                isXOrdered: series.isXOrdered,
                metadata: series.metadata,
                interpolation: series.interpolation,
                strokeWidth: series.strokeWidth,
                tension: series.tension,
                showDataPointMarkers: series.showDataPointMarkers,
                dataPointMarkerRadius: series.dataPointMarkerRadius,
              ),
            _ => series, // Keep original if not LineChartSeries
          };

          mergedSeriesList.add(updatedSeries);
        } else {
          mergedSeriesList.add(series);
        }
        processedIds.add(series.id);
      }

      // Then, add any controller series that don't exist in widget.series
      for (final entry in controllerData.entries) {
        if (!processedIds.contains(entry.key)) {
          // Convert src ChartDataPoint to src_plus ChartDataPoint
          final convertedPoints = entry.value
              .map((p) => ChartDataPoint(
                    x: p.x,
                    y: p.y,
                    timestamp: p.timestamp,
                    label: p.label,
                    metadata: p.metadata,
                  ))
              .toList();

          // Create new series from controller data
          mergedSeriesList.add(LineChartSeries(
            id: entry.key,
            name: entry.key,
            points: convertedPoints,
            color: widget.theme?.seriesColors.isNotEmpty == true
                ? widget.theme!.seriesColors[mergedSeriesList.length % widget.theme!.seriesColors.length]
                : Colors.blue,
          ));
        }
      }

      effectiveSeries = mergedSeriesList;
    }
    // Legacy: Also merge _streamingDataPoints if present (for backward compatibility)
    else if (_streamingDataPoints.isNotEmpty && widget.series.isNotEmpty) {
      final firstSeries = widget.series.first;
      final mergedPoints = [...firstSeries.points, ..._streamingDataPoints];

      // Create updated series with streaming data
      final updatedFirstSeries = switch (firstSeries) {
        LineChartSeries() => LineChartSeries(
            id: firstSeries.id,
            name: firstSeries.name,
            points: mergedPoints,
            color: firstSeries.color,
            isXOrdered: firstSeries.isXOrdered,
            metadata: firstSeries.metadata,
            interpolation: firstSeries.interpolation,
            strokeWidth: firstSeries.strokeWidth,
            tension: firstSeries.tension,
            showDataPointMarkers: firstSeries.showDataPointMarkers,
            dataPointMarkerRadius: firstSeries.dataPointMarkerRadius,
          ),
        _ => firstSeries, // Keep original if not LineChartSeries
      };

      effectiveSeries = [updatedFirstSeries, ...widget.series.skip(1)];
    }

    // Compute data bounds from effective series
    // FUNDAMENTAL FIX: Use locked bounds when paused to prevent visual jump
    // Otherwise calculate bounds based on viewport mode
    DataBounds dataBounds; // Made mutable for validation safety checks

    if (_lockedPausedBounds != null) {
      // PAUSED: Use locked bounds captured at pause time
      // Removed excessive debugPrint (locked bounds details)
      dataBounds = _lockedPausedBounds!;
    } else {
      // NOT PAUSED: Calculate bounds based on viewport mode
      final autoScrollEnabled = widget.autoScrollConfig?.enabled ?? widget.streamingConfig?.autoScroll ?? false;
      // If streamingController is null, assume followLatest behavior when autoScroll is enabled
      final isFollowingLatest = widget.streamingController?.viewportMode == ViewportMode.followLatest || widget.streamingController == null;
      final shouldUseWindowBounds = autoScrollEnabled && isFollowingLatest && effectiveSeries.isNotEmpty;

      if (shouldUseWindowBounds) {
        // Calculate sliding window bounds using CONFIGURABLE NUMBER of recent points
        final allPoints = effectiveSeries.expand((s) => s.points).toList();
        final windowSize = widget.autoScrollConfig?.maxVisiblePoints ?? widget.streamingConfig?.autoScrollWindowSize ?? 150;
        // Removed excessive debugPrint (sliding window calculation)

        if (allPoints.isNotEmpty) {
          // Use last N points only (or all if less than N)
          final windowPoints = allPoints.length <= windowSize ? allPoints : allPoints.sublist(allPoints.length - windowSize);

          // Removed excessive debugPrint (window points count)

          if (windowPoints.isNotEmpty) {
            final minX = windowPoints.map((p) => p.x).reduce((a, b) => a < b ? a : b);
            final maxX = windowPoints.map((p) => p.x).reduce((a, b) => a > b ? a : b);
            final minY = windowPoints.map((p) => p.y).reduce((a, b) => a < b ? a : b);
            final maxY = windowPoints.map((p) => p.y).reduce((a, b) => a > b ? a : b);

            // Removed excessive print (window bounds)

            dataBounds = DataBounds(xMin: minX, xMax: maxX, yMin: minY, yMax: maxY);
          } else {
            // Removed excessive print (no points in window)
            dataBounds = DataConverter.computeDataBounds(effectiveSeries);
          }
        } else {
          // Removed excessive print (no points at all)
          dataBounds = const DataBounds(xMin: 0, xMax: 1, yMin: 0, yMax: 1);
        }
      } else {
        // Non-streaming, no auto-scroll, or explore mode: use all data
        // Removed excessive print (full data bounds)
        dataBounds = DataConverter.computeDataBounds(effectiveSeries);
      }
    }

    // CRITICAL: Ensure valid bounds before creating axes (prevent dataMax <= dataMin assertion)
    if (dataBounds.xMax <= dataBounds.xMin) {
      print('⚠️ INVALID X BOUNDS: xMin=${dataBounds.xMin}, xMax=${dataBounds.xMax}, forcing default [0,1]');
      dataBounds = DataBounds(
        xMin: 0,
        xMax: 1,
        yMin: dataBounds.yMin,
        yMax: dataBounds.yMax,
      );
    }
    if (dataBounds.yMax <= dataBounds.yMin) {
      print('⚠️ INVALID Y BOUNDS: yMin=${dataBounds.yMin}, yMax=${dataBounds.yMax}, forcing default [0,1]');
      dataBounds = DataBounds(
        xMin: dataBounds.xMin,
        xMax: dataBounds.xMax,
        yMin: 0,
        yMax: 1,
      );
    }

    // Create axes from data bounds with theme colors
    // Use user's axis config if provided, otherwise create default
    final xAxisConfig = widget.xAxis ??
        const AxisConfig(
          label: 'X',
          orientation: AxisOrientation.horizontal,
          position: AxisPosition.bottom,
        );

    final yAxisConfig = widget.yAxis ??
        const AxisConfig(
          label: 'Y',
          orientation: AxisOrientation.vertical,
          position: AxisPosition.left,
        );

    _xAxis = chart_axis.Axis(
      config: AxisConfig(
        label: xAxisConfig.label,
        orientation: xAxisConfig.orientation,
        position: xAxisConfig.position,
        axisColor: widget.theme?.axisColor ?? xAxisConfig.axisColor,
        gridColor: widget.theme?.gridColor ?? xAxisConfig.gridColor,
        labelStyle: TextStyle(fontSize: 12, color: widget.theme?.textColor ?? Colors.black87),
        tickLabelStyle: TextStyle(fontSize: 10, color: widget.theme?.textColor ?? Colors.black54),
        showGrid: xAxisConfig.showGrid,
        showAxisLine: xAxisConfig.showAxisLine,
        showTickMarks: xAxisConfig.showTickMarks,
        tickLength: xAxisConfig.tickLength,
        labelPadding: xAxisConfig.labelPadding,
      ),
      dataMin: dataBounds.xMin,
      dataMax: dataBounds.xMax,
    );

    _yAxis = chart_axis.Axis(
      config: AxisConfig(
        label: yAxisConfig.label,
        orientation: yAxisConfig.orientation,
        position: yAxisConfig.position,
        axisColor: widget.theme?.axisColor ?? yAxisConfig.axisColor,
        gridColor: widget.theme?.gridColor ?? yAxisConfig.gridColor,
        labelStyle: TextStyle(fontSize: 12, color: widget.theme?.textColor ?? Colors.black87),
        tickLabelStyle: TextStyle(fontSize: 10, color: widget.theme?.textColor ?? Colors.black54),
        showGrid: yAxisConfig.showGrid,
        showAxisLine: yAxisConfig.showAxisLine,
        showTickMarks: yAxisConfig.showTickMarks,
        tickLength: yAxisConfig.tickLength,
        labelPadding: yAxisConfig.labelPadding,
      ),
      dataMin: dataBounds.yMin,
      dataMax: dataBounds.yMax,
    );

    // Create element generator that renders series
    // This will be called by ChartRenderBox during zoom/pan to regenerate elements
    _elementGenerator = (ChartTransform transform) {
      // Removed excessive debugPrint (element generator executing)

      // Generate series elements from effective series (with streaming data)
      final elements = DataConverter.seriesToElements(
        series: effectiveSeries,
        transform: transform,
        theme: widget.theme,
        strokeWidth: 2.0,
        coordinator: _coordinator,
      ).cast<ChartElement>().toList();

      // Convert annotations to elements
      // Removed excessive debugPrints (annotation conversion details)
      // Use annotation controller if provided, otherwise fall back to annotations list
      final effectiveAnnotations = widget.annotationController?.annotations ?? widget.annotations;
      print(
          '📊 _rebuildElements: Using ${widget.annotationController != null ? "CONTROLLER" : "WIDGET"} annotations (${effectiveAnnotations.length} total)');
      for (final annotation in effectiveAnnotations) {
        try {
          final ChartElement element = switch (annotation) {
            PointAnnotation() => PointAnnotationElement(
                annotation: annotation,
                series: widget.series.firstWhere(
                  (s) => s.id == annotation.seriesId,
                  orElse: () => throw StateError('Series ${annotation.seriesId} not found'),
                ),
                transform: transform,
              ),
            RangeAnnotation() => RangeAnnotationElement(
                annotation: annotation,
                transform: transform,
                chartSize: Size(transform.plotWidth, transform.plotHeight),
              ),
            TextAnnotation() => TextAnnotationElement(
                annotation: annotation,
              ),
            ThresholdAnnotation() => ThresholdAnnotationElement(
                annotation: annotation,
                transform: transform,
              ),
            TrendAnnotation() => TrendAnnotationElement(
                annotation: annotation,
                series: widget.series.firstWhere(
                  (s) => s.id == annotation.seriesId,
                  orElse: () => throw StateError('Series ${annotation.seriesId} not found'),
                ),
                transform: transform,
              ),
          };
          elements.add(element);
          debugPrint('  ✅ Created ${annotation.runtimeType} element: ${annotation.id}');

          // For resizable elements, also insert their resize handle elements
          if (element is ResizableElement && element.isResizable) {
            final handleElements = element.createResizeHandleElements().cast<ChartElement>();
            elements.addAll(handleElements);
            // Removed excessive debugPrint (resize handles added)
          }
        } catch (e) {
          debugPrint('⚠️ Warning: Failed to create annotation element for ${annotation.id}: $e');
        }
      }

      return elements;
    };

    // Increment version to signal that regeneration is needed
    _elementGeneratorVersion++;

    // Removed excessive debugPrint (_rebuildElements complete)
  }

  void _onCoordinatorChanged() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    debugPrint('⏱️ [$timestamp] _onCoordinatorChanged: mode=${_coordinator.currentMode.name}');

    // CRITICAL: Detect mode transitions to handle context menu
    if (_coordinator.currentMode == InteractionMode.contextMenuOpen && mounted) {
      // Only show context menu if annotationController is provided
      // (all current menu items are annotation-related)
      if (widget.annotationController != null) {
        if (_isShowingContextMenu) {
          debugPrint('⏱️ [$timestamp] Context menu already showing, ignoring duplicate request');
        } else {
          debugPrint('⏱️ [$timestamp] Detected contextMenuOpen mode, calling _showContextMenu immediately');
          // PERFORMANCE FIX: Call immediately instead of post-frame callback
          // Post-frame callbacks were being delayed by 2-36 SECONDS when Flutter's
          // frame scheduler was busy or browser was throttling frames.
          // Context menus need immediate response for good UX.
          _showContextMenu();
        }
      } else {
        debugPrint('⏱️ [$timestamp] Detected contextMenuOpen mode but no annotationController, releasing mode immediately');
        _coordinator.releaseMode(force: true);
      }
    }

    // CRITICAL: Call setState() when mode changes to update overlays (debug, crosshair)
    // Debug overlay and range creation crosshair both depend on coordinator mode
    final isInRangeCreation = _coordinator.currentMode == InteractionMode.rangeAnnotationCreation;
    final modeChanged = isInRangeCreation != _wasInRangeCreationMode;

    if (widget.showDebugInfo || modeChanged) {
      _wasInRangeCreationMode = isInRangeCreation;
      setState(() {});
    }
  }

  /// Shows context menu at the interaction start position.
  /// Called when coordinator enters contextMenuOpen mode.
  void _showContextMenu() async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    debugPrint('⏱️ [$startTime] 🎯 _showContextMenu START');

    // Set guard flag to prevent duplicate menu opens
    _isShowingContextMenu = true;

    final localPosition = _coordinator.interactionStartPosition;
    final element = _coordinator.interactionStartElement;

    if (localPosition == null) {
      final errorTime = DateTime.now().millisecondsSinceEpoch;
      debugPrint('⏱️ [$errorTime] ⚠️ No interaction position, releasing mode (${errorTime - startTime}ms)');
      _coordinator.releaseMode(force: true);
      debugPrint('⏱️ [${DateTime.now().millisecondsSinceEpoch}] Mode released (force=true)');
      _isShowingContextMenu = false;
      return;
    }

    // Convert local position to global coordinates for menu positioning
    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      final errorTime = DateTime.now().millisecondsSinceEpoch;
      debugPrint('⏱️ [$errorTime] ⚠️ No render box, releasing mode (${errorTime - startTime}ms)');
      _coordinator.releaseMode(force: true);
      debugPrint('⏱️ [${DateTime.now().millisecondsSinceEpoch}] Mode released (force=true)');
      _isShowingContextMenu = false;
      return;
    }

    final convertTime = DateTime.now().millisecondsSinceEpoch;
    final globalPosition = renderBox.localToGlobal(localPosition);
    debugPrint('⏱️ [$convertTime] Position converted (${convertTime - startTime}ms): local=$localPosition, global=$globalPosition');
    debugPrint('⏱️ [$convertTime] Element: ${element?.runtimeType ?? 'null (empty area)'}');

    final buildMenuTime = DateTime.now().millisecondsSinceEpoch;
    debugPrint('⏱️ [$buildMenuTime] Building menu items (${buildMenuTime - startTime}ms)...');

    // Determine context for menu items
    final bool isDataPointClick = element is SeriesElement && _coordinator.hoveredMarker != null;
    final bool isSeriesLineClick = element is SeriesElement && _coordinator.hoveredMarker == null;
    final bool isEmptyArea = element == null;
    final bool isExistingAnnotation = element != null && element is! SeriesElement;

    debugPrint(
        '⏱️ [$buildMenuTime] Context: isDataPointClick=$isDataPointClick, isSeriesLineClick=$isSeriesLineClick, isEmptyArea=$isEmptyArea, isExistingAnnotation=$isExistingAnnotation');

    // Check if annotations are supported (annotationController is provided)
    final bool hasAnnotationController = widget.annotationController != null;

    // Build context-aware web-native menu items
    final List<WebContextMenuItem> menuItems = [
      // Annotation creation items - ONLY show when annotationController is available
      if (hasAnnotationController) ...[
        // TextAnnotation - ALWAYS available
        const WebContextMenuAction(
          value: 'add_text',
          icon: Icons.text_fields,
          label: 'Add Text Annotation',
        ),

        // PointAnnotation - ONLY when clicking on data point marker
        if (isDataPointClick)
          const WebContextMenuAction(
            value: 'add_point',
            icon: Icons.place,
            label: 'Add Point Annotation',
          ),

        // TrendAnnotation - ONLY when clicking on series line (not marker)
        if (isSeriesLineClick)
          const WebContextMenuAction(
            value: 'add_trend',
            icon: Icons.trending_up,
            label: 'Add Trend Annotation',
          ),

        // RangeAnnotation - ALWAYS available (interactive drag mode)
        const WebContextMenuAction(
          value: 'add_range',
          icon: Icons.width_full,
          label: 'Add Range Annotation',
        ),

        const WebContextMenuDivider(),

        // ThresholdAnnotation - ALWAYS available
        const WebContextMenuAction(
          value: 'add_threshold',
          icon: Icons.horizontal_rule,
          label: 'Add Threshold Line',
        ),
      ],

      // Edit/Delete for existing annotations - ONLY show when annotationController is available
      if (hasAnnotationController && isExistingAnnotation) ...[
        const WebContextMenuDivider(),
        const WebContextMenuAction(
          value: 'edit',
          icon: Icons.edit,
          label: 'Edit',
        ),
        const WebContextMenuAction(
          value: 'delete',
          icon: Icons.delete,
          label: 'Delete',
          iconColor: Colors.red,
          textColor: Colors.red,
        ),
      ],
    ];

    final showMenuTime = DateTime.now().millisecondsSinceEpoch;
    debugPrint('⏱️ [$showMenuTime] Calling WebContextMenu.show (${showMenuTime - startTime}ms)...');

    // Show the web-native context menu
    final result = await WebContextMenu.show(
      context: context,
      position: globalPosition,
      items: menuItems,
    );

    final menuClosedTime = DateTime.now().millisecondsSinceEpoch;
    debugPrint('⏱️ [$menuClosedTime] showMenu returned (menu was open for ${menuClosedTime - showMenuTime}ms)');

    // Clear guard flag now that menu is closed
    _isShowingContextMenu = false;

    // Release mode BEFORE handling action (so action handlers can claim new modes)
    // This is critical for modal-to-modal transitions (e.g., contextMenuOpen → rangeAnnotationCreation)
    final releaseTime = DateTime.now().millisecondsSinceEpoch;
    debugPrint('⏱️ [$releaseTime] Releasing coordinator mode (force=true) BEFORE handling action...');
    _coordinator.releaseMode(force: true);

    // Handle menu selection
    if (result != null) {
      debugPrint('⏱️ [$menuClosedTime] 🎯 Menu action selected: $result');
      await _handleMenuAction(result, localPosition, element);
    } else {
      debugPrint('⏱️ [$menuClosedTime] Menu dismissed without selection');
    }

    final endTime = DateTime.now().millisecondsSinceEpoch;
    debugPrint('⏱️ [$endTime] 🎯 _showContextMenu END (total: ${endTime - startTime}ms, release: ${endTime - releaseTime}ms)');
  }

  /// Handles menu action selection from context menu.
  Future<void> _handleMenuAction(String action, Offset localPosition, ChartElement? element) async {
    debugPrint('🎯 Handling menu action: $action');

    switch (action) {
      case 'add_text':
        await _showAddTextAnnotationDialog(localPosition);
        break;
      case 'add_point':
        await _showAddPointAnnotationDialog(element);
        break;
      case 'add_trend':
        await _showAddTrendAnnotationDialog(element);
        break;
      case 'add_range':
        await _showAddRangeAnnotationDialog();
        break;
      case 'add_threshold':
        await _showAddThresholdAnnotationDialog();
        break;
      case 'edit':
        await _showEditAnnotationDialog(element);
        break;
      case 'delete':
        await _showDeleteAnnotationConfirmation(element);
        break;
      default:
        debugPrint('⚠️ Unknown menu action: $action');
    }
  }

  /// Shows the TextAnnotation creation dialog.
  Future<void> _showAddTextAnnotationDialog(Offset localPosition) async {
    if (!mounted) return;

    final result = await showDialog<TextAnnotation>(
      context: context,
      builder: (context) => TextAnnotationDialog(
        clickPosition: localPosition,
      ),
    );

    if (result != null && mounted) {
      debugPrint('✅ Created TextAnnotation: ${result.id} at ${result.position}');
      widget.annotationController?.addAnnotation(result);
    } else {
      debugPrint('❌ TextAnnotation creation cancelled');
    }
  }

  /// Shows the PointAnnotation creation dialog.
  Future<void> _showAddPointAnnotationDialog(ChartElement? element) async {
    if (!mounted) return;

    // PointAnnotation requires a data point - get info from coordinator's hoveredMarker
    final markerInfo = _coordinator.hoveredMarker;
    if (markerInfo == null) {
      debugPrint('⚠️ PointAnnotation requires clicking on a data point marker');
      return;
    }

    debugPrint('🎯 Creating PointAnnotation for marker: series=${markerInfo.seriesId}, index=${markerInfo.markerIndex}');

    final result = await showDialog<PointAnnotation>(
      context: context,
      builder: (context) => PointAnnotationDialog(
        seriesId: markerInfo.seriesId,
        dataPointIndex: markerInfo.markerIndex,
      ),
    );

    if (result != null && mounted) {
      debugPrint('✅ Created PointAnnotation: ${result.id} on ${result.seriesId}[${result.dataPointIndex}]');
      widget.annotationController?.addAnnotation(result);
    } else {
      debugPrint('❌ PointAnnotation creation cancelled');
    }
  }

  /// Shows the ThresholdAnnotation creation dialog.
  Future<void> _showAddThresholdAnnotationDialog() async {
    if (!mounted) return;

    // Get clicked position and convert to data coordinates
    final localPosition = _coordinator.interactionStartPosition;
    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;

    double? initialXValue;
    double? initialYValue;

    if (localPosition != null && renderBox != null) {
      final transform = renderBox.transform;
      if (transform != null) {
        // Convert local plot position to data coordinates
        final dataPos = transform.plotToData(localPosition.dx, localPosition.dy);
        initialXValue = dataPos.dx;
        initialYValue = dataPos.dy;
        debugPrint('🎯 Creating ThresholdAnnotation at position: X=${dataPos.dx.toStringAsFixed(2)}, Y=${dataPos.dy.toStringAsFixed(2)}');
      }
    }

    final result = await showDialog<ThresholdAnnotation>(
      context: context,
      builder: (context) => ThresholdAnnotationDialog(
        initialXValue: initialXValue,
        initialYValue: initialYValue,
      ),
    );

    if (result != null && mounted) {
      debugPrint('✅ Created ThresholdAnnotation: ${result.id} at ${result.axis} = ${result.value}');
      widget.annotationController?.addAnnotation(result);
    } else {
      debugPrint('❌ ThresholdAnnotation creation cancelled');
    }
  }

  /// Shows the RangeAnnotation creation dialog.
  ///
  /// **Option 4 Implementation**: Right-click → "Add Range" → Interactive drag → Dialog
  ///
  /// **Workflow**:
  /// 1. User selects "Add Range Annotation" from context menu
  /// 2. Enter `rangeAnnotationCreation` mode (cursor changes to crosshair)
  /// 3. User click-drags to define rectangular region (rubber-band preview shown)
  /// 4. On release (handled in RenderBox), callback opens dialog with pre-filled coords
  ///
  /// **Cancellation**: ESC key, right-click, or release without drag cancels mode
  Future<void> _showAddRangeAnnotationDialog() async {
    if (!mounted) return;

    debugPrint('🎯 Starting RangeAnnotation creation (Option 4: Interactive drag mode)');

    // Enter rangeAnnotationCreation mode (priority 10, modal)
    if (!_coordinator.claimMode(InteractionMode.rangeAnnotationCreation)) {
      debugPrint('❌ Failed to claim rangeAnnotationCreation mode');
      return;
    }

    debugPrint('✅ Entered rangeAnnotationCreation mode - cursor should change to red crosshair');
    debugPrint('   Now awaiting user drag... (drag to define rectangular region)');
    debugPrint('   Press ESC or click without dragging to cancel');

    // Hide system cursor completely - we'll show custom red crosshair via overlay
    // The _RangeCreationCrosshairOverlay widget will paint the red crosshair
    setState(() {
      _currentCursor = SystemMouseCursors.none;
    });

    // Completion is handled via _onRangeCreationComplete callback
    // (called from ChartRenderBox when drag finishes)
  }

  /// Called when user completes drag in rangeAnnotationCreation mode.
  /// Opens dialog with pre-filled coordinates from drag bounds.
  Future<void> _onRangeCreationComplete(double startX, double endX, double startY, double endY) async {
    if (!mounted) return;

    debugPrint('🎯 Range creation drag complete:');
    debugPrint('   X: [$startX, $endX]');
    debugPrint('   Y: [$startY, $endY]');

    // Reset cursor
    setState(() {
      _currentCursor = SystemMouseCursors.basic;
    });

    // Open dialog with pre-filled values from drag
    final result = await showDialog<RangeAnnotation>(
      context: context,
      builder: (context) => RangeAnnotationDialog(
        initialStartX: startX,
        initialEndX: endX,
        initialStartY: startY,
        initialEndY: endY,
      ),
    );

    // Release rangeAnnotationCreation mode after dialog closes (regardless of result)
    // CRITICAL: Must use force=true because rangeAnnotationCreation is modal (priority 10)
    _coordinator.releaseMode(force: true);
    debugPrint('🎯 Released rangeAnnotationCreation mode after dialog closed');

    if (result != null && mounted) {
      debugPrint('✅ Created RangeAnnotation: ${result.id}');
      debugPrint('   X: [${result.startX}, ${result.endX}], Y: [${result.startY}, ${result.endY}]');
      widget.annotationController?.addAnnotation(result);
    } else {
      debugPrint('❌ RangeAnnotation creation cancelled in dialog');
    }
  }

  /// Shows the TrendAnnotation creation dialog.
  Future<void> _showAddTrendAnnotationDialog(ChartElement? element) async {
    if (!mounted) return;

    // Get available series IDs
    final availableSeries = widget.series.map((s) => s.id).toList();
    if (availableSeries.isEmpty) {
      debugPrint('⚠️ No series available for trend annotation');
      return;
    }

    // If clicked on series line, preselect that series
    String? preselectedSeriesId;
    if (element is SeriesElement) {
      preselectedSeriesId = element.series.id;
      debugPrint('🎯 Creating TrendAnnotation for series: $preselectedSeriesId');
    }

    final result = await showDialog<TrendAnnotation>(
      context: context,
      builder: (context) => TrendAnnotationDialog(
        availableSeries: availableSeries,
        preselectedSeriesId: preselectedSeriesId,
      ),
    );

    if (result != null && mounted) {
      debugPrint('✅ Created TrendAnnotation: ${result.id} for series ${result.seriesId} (${result.trendType})');
      widget.annotationController?.addAnnotation(result);
    } else {
      debugPrint('❌ TrendAnnotation creation cancelled');
    }
  }

  /// Shows the appropriate edit dialog based on annotation type.
  Future<void> _showEditAnnotationDialog(ChartElement? element) async {
    if (!mounted) return;

    debugPrint('🔧 Edit dialog requested for element: ${element?.runtimeType}, elementType: ${element?.elementType}');

    // Check for annotation element types directly (PointAnnotationElement uses datapoint type for priority)
    if (element == null ||
        (element is! TextAnnotationElement &&
            element is! PointAnnotationElement &&
            element is! ThresholdAnnotationElement &&
            element is! TrendAnnotationElement &&
            element is! RangeAnnotationElement)) {
      debugPrint('⚠️ Edit action requires an annotation element (got ${element?.runtimeType})');
      return;
    }

    debugPrint('🔧 Annotation element confirmed, checking type...');

    // Cast to annotation element types to access annotation field and route to dialog
    if (element is TextAnnotationElement) {
      debugPrint('🔧 TextAnnotationElement detected');
      final annotation = element.annotation;
      final result = await showDialog<TextAnnotation>(
        context: context,
        builder: (context) => TextAnnotationDialog(
          annotation: annotation,
          clickPosition: annotation.position,
        ),
      );

      if (result != null && mounted) {
        debugPrint('✅ Updated TextAnnotation: ${result.id}');
        widget.annotationController?.updateAnnotation(annotation.id, result);
      } else {
        debugPrint('❌ TextAnnotation edit cancelled');
      }
    } else if (element is PointAnnotationElement) {
      debugPrint('🔧 PointAnnotationElement detected');
      final annotation = element.annotation;
      final result = await showDialog<PointAnnotation>(
        context: context,
        builder: (context) => PointAnnotationDialog(
          annotation: annotation,
          seriesId: annotation.seriesId,
          dataPointIndex: annotation.dataPointIndex,
        ),
      );

      if (result != null && mounted) {
        debugPrint('✅ Updated PointAnnotation: ${result.id}');
        widget.annotationController?.updateAnnotation(annotation.id, result);
      } else {
        debugPrint('❌ PointAnnotation edit cancelled');
      }
    } else if (element is ThresholdAnnotationElement) {
      debugPrint('🔧 ThresholdAnnotationElement detected');
      final annotation = element.annotation;
      final result = await showDialog<ThresholdAnnotation>(
        context: context,
        builder: (context) => ThresholdAnnotationDialog(annotation: annotation),
      );

      if (result != null && mounted) {
        debugPrint('✅ Updated ThresholdAnnotation: ${result.id}');
        widget.annotationController?.updateAnnotation(annotation.id, result);
      } else {
        debugPrint('❌ ThresholdAnnotation edit cancelled');
      }
    } else if (element is TrendAnnotationElement) {
      debugPrint('🔧 TrendAnnotationElement detected');
      final annotation = element.annotation;
      final availableSeries = widget.series.map((s) => s.id).toList();
      final result = await showDialog<TrendAnnotation>(
        context: context,
        builder: (context) => TrendAnnotationDialog(
          annotation: annotation,
          availableSeries: availableSeries,
        ),
      );

      if (result != null && mounted) {
        debugPrint('✅ Updated TrendAnnotation: ${result.id}');
        widget.annotationController?.updateAnnotation(annotation.id, result);
      } else {
        debugPrint('❌ TrendAnnotation edit cancelled');
      }
    } else if (element is RangeAnnotationElement) {
      debugPrint('🔧 RangeAnnotationElement detected');
      final annotation = element.annotation;
      final result = await showDialog<RangeAnnotation>(
        context: context,
        builder: (context) => RangeAnnotationDialog(annotation: annotation),
      );

      if (result != null && mounted) {
        debugPrint('✅ Updated RangeAnnotation: ${result.id}');
        widget.annotationController?.updateAnnotation(annotation.id, result);
      } else {
        debugPrint('❌ TrendAnnotation edit cancelled');
      }
    } else {
      debugPrint('⏳ TODO: Edit dialog for ${element.runtimeType} not implemented yet');
    }
  }

  /// Shows delete confirmation dialog and removes annotation if confirmed.
  Future<void> _showDeleteAnnotationConfirmation(ChartElement? element) async {
    if (!mounted) return;

    // Verify element is an annotation type
    if (element == null ||
        (element is! TextAnnotationElement &&
            element is! PointAnnotationElement &&
            element is! RangeAnnotationElement &&
            element is! ThresholdAnnotationElement &&
            element is! TrendAnnotationElement)) {
      debugPrint('⚠️ Delete action requires an annotation element (got ${element?.runtimeType})');
      return;
    }

    // Extract annotation ID and type name
    String annotationId;
    String annotationType;

    if (element is TextAnnotationElement) {
      annotationId = element.annotation.id;
      annotationType = 'Text Annotation';
    } else if (element is PointAnnotationElement) {
      annotationId = element.annotation.id;
      annotationType = 'Point Annotation';
    } else if (element is RangeAnnotationElement) {
      annotationId = element.annotation.id;
      annotationType = 'Range Annotation';
    } else if (element is ThresholdAnnotationElement) {
      annotationId = element.annotation.id;
      annotationType = 'Threshold Annotation';
    } else if (element is TrendAnnotationElement) {
      annotationId = element.annotation.id;
      annotationType = 'Trend Annotation';
    } else {
      debugPrint('⚠️ Unknown annotation element type: ${element.runtimeType}');
      return;
    }

    debugPrint('🗑️ Showing delete confirmation for $annotationType: $annotationId');

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Annotation'),
        content: Text('Are you sure you want to delete this $annotationType?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // Delete if confirmed
    if (confirmed == true && mounted) {
      final wasRemoved = widget.annotationController?.removeAnnotation(annotationId) ?? false;
      if (wasRemoved) {
        debugPrint('✅ Deleted $annotationType: $annotationId');
      } else {
        debugPrint('⚠️ Failed to delete $annotationType: $annotationId (not found)');
      }
    } else {
      debugPrint('❌ Delete cancelled for $annotationType: $annotationId');
    }
  }

  void _handlePanStart(DragStartDetails details) {
    // Request focus on pan start to enable keyboard controls
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
      // Removed excessive debugPrint (focus requested via pan start)
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    renderBox?.panChart(details.delta.dx, details.delta.dy);
  }

  void _handlePanEnd(DragEndDetails details) {}

  void _handleTapDown(TapDownDetails details) {
    // Capture element at tap down for double-click detection
    // (activeElement gets cleared by tap up, so we need to capture it now)
    final tappedElement = _coordinator.activeElement ?? _coordinator.hoveredElement;

    debugPrint('👇 TapDown: tappedElement=${tappedElement?.runtimeType}');

    // Check for double-click on annotation
    if (_lastTapTime != null && _lastTappedElement != null && tappedElement != null) {
      final now = DateTime.now();
      final timeDiff = now.difference(_lastTapTime!);
      debugPrint('   Time since last tap: ${timeDiff.inMilliseconds}ms, same element: ${tappedElement == _lastTappedElement}');

      if (tappedElement == _lastTappedElement && timeDiff <= _doubleTapTimeout) {
        // Double-click detected!
        if (tappedElement is TextAnnotationElement ||
            tappedElement is PointAnnotationElement ||
            tappedElement is ThresholdAnnotationElement ||
            tappedElement is TrendAnnotationElement ||
            tappedElement is RangeAnnotationElement) {
          debugPrint('🖱️ Double-click detected on ${tappedElement.runtimeType}, opening edit dialog');
          _showEditAnnotationDialog(tappedElement);
          // Reset to prevent triple-click
          _lastTapTime = null;
          _lastTappedElement = null;
          return;
        }
      }
    }

    // Update tracking for potential double-click
    _lastTapTime = DateTime.now();
    _lastTappedElement = tappedElement;

    // Trigger callbacks
    if (tappedElement != null) {
      if (tappedElement is PointAnnotationElement) {
        widget.onAnnotationTap?.call(tappedElement.annotation);
      } else if (tappedElement is TextAnnotationElement) {
        widget.onAnnotationTap?.call(tappedElement.annotation);
      } else if (tappedElement is RangeAnnotationElement) {
        widget.onAnnotationTap?.call(tappedElement.annotation);
      } else if (tappedElement is ThresholdAnnotationElement) {
        widget.onAnnotationTap?.call(tappedElement.annotation);
      } else if (tappedElement is TrendAnnotationElement) {
        widget.onAnnotationTap?.call(tappedElement.annotation);
      } else if (tappedElement is SeriesElement) {
        // Check if a specific marker was tapped
        final marker = _coordinator.hoveredMarker;
        if (marker != null && marker.seriesId == tappedElement.series.id) {
          final point = tappedElement.series.points[marker.markerIndex];
          widget.onPointTap?.call(point, tappedElement.series.id);
        } else {
          widget.onSeriesSelected?.call(tappedElement.series.id);
        }
      }
    } else {
      widget.onBackgroundTap?.call(details.localPosition);
    }

    // Request focus on tap to enable keyboard controls
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    // Double-click detection now handled in _handleTapDown
    // (since activeElement is cleared by the time we get here)

    // CRITICAL: Cancel rangeAnnotationCreation mode on single click without drag
    // This provides an easy way to exit the mode if user changes their mind
    if (_coordinator.currentMode == InteractionMode.rangeAnnotationCreation) {
      // Check if this was a click without drag (no box selection drawn)
      // The RenderBox handles actual drag detection, so if we get here in creation mode,
      // it means the user just clicked without dragging
      debugPrint('⏹️ Click detected in rangeAnnotationCreation mode - cancelling (no drag detected)');
      _coordinator.releaseMode(force: true);
      setState(() {
        _currentCursor = SystemMouseCursors.basic;
      });
    }
  }

  void _handleElementHover(ChartElement? element) {
    if (widget.onPointHover == null) return;

    if (element is SeriesElement) {
      final marker = _coordinator.hoveredMarker;
      if (marker != null && marker.seriesId == element.series.id) {
        final point = element.series.points[marker.markerIndex];
        widget.onPointHover!(point, element.series.id);
      } else {
        // Hovering series line but not a specific point
        widget.onPointHover!(null, element.series.id);
      }
    } else {
      // Not hovering a series (empty space or other element)
      widget.onPointHover!(null, null);
    }
  }

  void _handleCursorChange(MouseCursor cursor) {
    // CRITICAL: Don't change cursor during rangeAnnotationCreation mode
    // The crosshair cursor must remain visible regardless of what's being hovered
    if (_coordinator.currentMode == InteractionMode.rangeAnnotationCreation) {
      debugPrint('🚫 Cursor change blocked - rangeAnnotationCreation mode active (keeping crosshair)');
      return;
    }

    if (_currentCursor != cursor) {
      setState(() => _currentCursor = cursor);
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    // Removed excessive debugPrint (key event)

    if (event is KeyDownEvent) {
      final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
      // Removed excessive debugPrint (renderbox found)

      if (renderBox == null) return;

      // Cancel range annotation creation mode
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (_coordinator.currentMode == InteractionMode.rangeAnnotationCreation) {
          debugPrint('⏹️ ESC pressed - cancelling rangeAnnotationCreation mode');
          _coordinator.releaseMode(force: true);
          setState(() {
            _currentCursor = SystemMouseCursors.basic;
          });
          return;
        }
      }
      // Reset view
      else if (event.logicalKey == LogicalKeyboardKey.home || event.logicalKey == LogicalKeyboardKey.keyR) {
        // Removed excessive debugPrint (calling resetView)
        renderBox.resetView();
      }
      // Shift modifier for zoom
      else if (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight) {
        // Removed excessive debugPrint (adding shift modifier)
        _coordinator.addModifierKey(LogicalKeyboardKey.shift);
      }
      // Arrow keys for panning
      else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        // Check if pan is enabled
        if (widget.interactionConfig?.enablePan ?? true) {
          // Removed excessive debugPrint (arrow left)
          renderBox.panChart(-20.0, 0.0);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        // Check if pan is enabled
        if (widget.interactionConfig?.enablePan ?? true) {
          // Removed excessive debugPrint (arrow right)
          renderBox.panChart(20.0, 0.0);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        // Check if pan is enabled
        if (widget.interactionConfig?.enablePan ?? true) {
          // Removed excessive debugPrint (arrow up)
          renderBox.panChart(0.0, -20.0);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        // Check if pan is enabled
        if (widget.interactionConfig?.enablePan ?? true) {
          // Removed excessive debugPrint (arrow down)
          renderBox.panChart(0.0, 20.0);
        }
      }
      // Zoom in with + or = or numpad +
      else if (event.logicalKey == LogicalKeyboardKey.equal ||
          event.logicalKey == LogicalKeyboardKey.add ||
          event.logicalKey == LogicalKeyboardKey.numpadAdd) {
        // Check if zoom is enabled
        if (widget.interactionConfig?.enableZoom ?? true) {
          // Removed excessive debugPrint (zoom in)
          renderBox.zoomChart(1.1);
        }
      }
      // Zoom out with - or numpad -
      else if (event.logicalKey == LogicalKeyboardKey.minus || event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
        // Check if zoom is enabled
        if (widget.interactionConfig?.enableZoom ?? true) {
          // Removed excessive debugPrint (zoom out)
          renderBox.zoomChart(0.9);
        }
      }
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight) {
        // Removed excessive debugPrint (removing shift modifier)
        _coordinator.removeModifierKey(LogicalKeyboardKey.shift);
      }
    }
  }

  // Streaming methods

  /// Sets up the stream subscription for real-time data ingestion.
  void _setupStreamSubscription() {
    final config = widget.streamingConfig ?? const StreamingConfig();

    // Initialize buffer if not already created
    _buffer ??= BufferManager<ChartDataPoint>(maxSize: config.maxBufferSize);

    // Subscribe to the data stream
    _streamSubscription = widget.dataStream?.listen(
      _onStreamData,
      onError: (error) {
        config.onStreamError?.call(error);
        debugPrint('❌ Stream error: $error');
      },
    );
  }

  /// Handles incoming stream data points.
  void _onStreamData(ChartDataPoint point) {
    if (!mounted) return;

    final config = widget.streamingConfig ?? const StreamingConfig();

    // Removed excessive print - was flooding console 10-50 times per second

    // Update cached bounds for full dataset pan constraints (O(1) per point)
    _updateCachedDataBounds(point.x, point.y);

    if (_isStreaming) {
      // Use controller if available (matches BravenChart pattern)
      if (widget.controller != null) {
        // Determine series ID - use first series ID or default to 'stream'
        final seriesId = widget.series.isNotEmpty ? widget.series.first.id : 'stream';

        // Add to controller - this will trigger _onControllerUpdate -> setState -> rebuild
        // No conversion needed - both use src_plus ChartDataPoint now
        widget.controller!.addPoint(seriesId, point);

        // Auto-scroll if enabled
        final autoScrollEnabled = widget.autoScrollConfig?.enabled ?? config.autoScroll;
        if (autoScrollEnabled) {
          setState(() {
            _autoScrollToLatest();
          });
        }
      } else {
        // Legacy path: Add point to streaming data list
        setState(() {
          _streamingDataPoints.add(point);
          _rebuildElements();

          // Auto-scroll if enabled
          final autoScrollEnabled = widget.autoScrollConfig?.enabled ?? config.autoScroll;
          if (autoScrollEnabled) {
            _autoScrollToLatest();
          }
        });
      }
    } else {
      // Buffer the point for later
      _buffer?.add(point);
      config.onBufferUpdated?.call(_buffer?.length ?? 0);
    }
  }

  /// Pauses streaming and starts buffering incoming data.
  /// FUNDAMENTAL FIX: Lock the current viewport bounds to prevent visual jump.
  /// PERFORMANCE FIX: No expensive point iteration - instant pause response.
  void _pauseStreaming() {
    if (!_isStreaming) return; // Already paused

    print('⏸️  ===== PAUSE STREAMING STARTED =====');

    // STEP 1: Capture current viewport bounds from axes
    // This is what the user sees RIGHT NOW - we must preserve it exactly
    if (_xAxis != null && _yAxis != null) {
      _lockedPausedBounds = DataBounds(
        xMin: _xAxis!.dataMin,
        xMax: _xAxis!.dataMax,
        yMin: _yAxis!.dataMin,
        yMax: _yAxis!.dataMax,
      );
      print(
          '🔒 LOCKED viewport bounds: X=[${_lockedPausedBounds!.xMin}, ${_lockedPausedBounds!.xMax}], Y=[${_lockedPausedBounds!.yMin}, ${_lockedPausedBounds!.yMax}]');
    }

    // STEP 2: Set pan constraints to full dataset bounds (Option 4)
    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    if (renderBox != null && _cachedDataXMin != null) {
      renderBox.setPanConstraintBounds(
        _cachedDataXMin!,
        _cachedDataXMax!,
        _cachedDataYMin!,
        _cachedDataYMax!,
      );
    }

    // STEP 3: Update streaming state
    _isStreaming = false;

    print('⏸️  ===== PAUSE COMPLETE - Viewport LOCKED =====');

    // STEP 4: Force rebuild with locked bounds to prevent race condition
    // This ensures _lockedPausedBounds is used IMMEDIATELY, before any other rebuild
    setState(() {
      // Locked bounds are already set, this just triggers rebuild
      print('⏸️  Forcing rebuild with locked bounds to prevent race condition');
    });
  }

  /// Resumes streaming and applies buffered data.
  /// FUNDAMENTAL FIX: Unlock the viewport bounds to resume dynamic calculation.
  void _resumeStreaming() {
    if (_isStreaming) return; // Already streaming

    print('▶️  ===== RESUME STREAMING STARTED =====');

    // STEP 1: Clear pan constraint bounds to restore sliding window constraints (Option 4)
    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    renderBox?.clearPanConstraintBounds();

    // STEP 2: Unlock the viewport bounds AND update streaming state FIRST
    // CRITICAL: Must set _isStreaming = true BEFORE applying buffered data
    // to prevent "Controller updated while paused" spam when controller.addPoint() is called
    _lockedPausedBounds = null;
    _isStreaming = true;

    // STEP 3: Apply buffered data (controller.addPoint will now trigger rebuilds)
    _applyBufferedData();

    // DON'T call updateState() - the controller already updated its state
    // and called notifyListeners() before calling this callback
    // widget.streamingController?.updateState(true);  // REMOVED - redundant

    // STEP 3: Jump viewport to latest data after resume
    _jumpToLatestData();

    // Removed excessive debugPrint (streaming resumed)
  }

  /// Applies all buffered data points to the series.
  void _applyBufferedData() {
    final bufferedPoints = _buffer?.removeAll() ?? [];

    if (bufferedPoints.isEmpty) return;

    // Use controller if available
    if (widget.controller != null) {
      final seriesId = widget.series.isNotEmpty ? widget.series.first.id : 'stream';

      for (final point in bufferedPoints) {
        // No conversion needed - both use src_plus ChartDataPoint now
        widget.controller!.addPoint(seriesId, point);
      }
      // Controller will trigger _onControllerUpdate -> setState -> rebuild
    } else {
      // Legacy path
      setState(() {
        _streamingDataPoints.addAll(bufferedPoints);
        _rebuildElements();
      });
    }

    // Auto-scroll and notify regardless of path
    final config = widget.streamingConfig ?? const StreamingConfig();
    final autoScrollEnabled = widget.autoScrollConfig?.enabled ?? config.autoScroll;
    if (autoScrollEnabled) {
      setState(() {
        _autoScrollToLatest();
      });
    }

    // Notify about buffer clear
    config.onBufferUpdated?.call(0);

    // Removed excessive debugPrint (applied buffered points)
  }

  /// Clears all accumulated streaming data.
  void _clearStreamingData() {
    if (!mounted) return;

    // Clear controller data if available
    if (widget.controller != null) {
      final seriesId = widget.series.isNotEmpty ? widget.series.first.id : 'stream';
      widget.controller!.clearSeries(seriesId);
      // Controller will trigger _onControllerUpdate -> setState -> rebuild
    } else {
      // Legacy path
      setState(() {
        _streamingDataPoints.clear();
        _rebuildElements();
      });
      // Removed excessive debugPrint (cleared streaming points)
    }

    // Clear buffer regardless of path
    _buffer?.clear();
  }

  /// Updates the cached full dataset bounds incrementally (O(1) per point).
  ///
  /// This tracks the absolute min/max of all data that has ever been added,
  /// enabling pan constraints to cover the full dataset when paused.
  void _updateCachedDataBounds(double x, double y) {
    _cachedDataXMin = _cachedDataXMin == null ? x : (_cachedDataXMin! < x ? _cachedDataXMin! : x);
    _cachedDataXMax = _cachedDataXMax == null ? x : (_cachedDataXMax! > x ? _cachedDataXMax! : x);
    _cachedDataYMin = _cachedDataYMin == null ? y : (_cachedDataYMin! < y ? _cachedDataYMin! : y);
    _cachedDataYMax = _cachedDataYMax == null ? y : (_cachedDataYMax! > y ? _cachedDataYMax! : y);
  }

  /// Initializes cached bounds from existing series data.
  ///
  /// Called once during setup to establish baseline bounds before streaming starts.
  void _initializeCachedDataBounds() {
    if (_cachedDataXMin != null) return; // Already initialized

    // Get all points from widget.series OR widget.controller
    final List<dynamic> allPoints;
    if (widget.controller != null) {
      // ChartController Direct mode: get points from controller
      final controllerData = widget.controller!.getAllSeries();
      allPoints = controllerData.values.expand((points) => points).toList();
    } else {
      // Normal mode: get points from widget.series
      allPoints = widget.series.expand((s) => s.points).toList();
    }

    if (allPoints.isEmpty) {
      // No initial data - will be initialized when first point arrives
      return;
    }

    // Initialize with first point, then update with rest
    final firstPoint = allPoints.first;
    _cachedDataXMin = firstPoint.x;
    _cachedDataXMax = firstPoint.x;
    _cachedDataYMin = firstPoint.y;
    _cachedDataYMax = firstPoint.y;

    // Update with remaining points
    for (final point in allPoints.skip(1)) {
      _updateCachedDataBounds(point.x, point.y);
    }

    debugPrint('📊 Initialized cached bounds from ${allPoints.length} points: '
        'X=[$_cachedDataXMin, $_cachedDataXMax], Y=[$_cachedDataYMin, $_cachedDataYMax]');
  }

  /// Auto-scrolls the viewport to show the latest data.
  void _autoScrollToLatest() {
    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    if (renderBox == null) return;

    // NOTE: We don't call updateDataBounds() here anymore because:
    // 1. The sliding window in _rebuildElements() already calculated correct bounds
    // 2. Calling updateDataBounds() with all historical data causes bounds explosion
    // 3. The pan operation below is sufficient to follow latest data

    // Removed excessive debugPrint (auto-scrolling viewport)

    // Pan right every time to follow the data
    final panAmount = renderBox.size.width * 0.02; // 2% per update
    renderBox.panChart(panAmount, 0.0);
  }

  /// Jumps the viewport to show the latest data after resume.
  ///
  /// This is called when streaming resumes to ensure the user sees the
  /// most recent data immediately. The viewport smoothly animates back
  /// to the "tip" of the data stream.
  void _jumpToLatestData() {
    // Schedule for next frame to ensure data is applied
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
      if (renderBox == null) {
        // Keep this warning - it's important
        debugPrint('⚠️  Cannot jump to latest: renderBox not found');
        return;
      }

      // Reset the viewport transform to original (identity transform)
      // This effectively "jumps" back to showing the sliding window bounds
      // Removed excessive debugPrint (resetting viewport)

      // Reset view to show original bounds (which are now the sliding window)
      renderBox.resetView();

      // Trigger rebuild with sliding window bounds (viewportMode changed to followLatest)
      setState(() {
        _rebuildElements();
      });

      // Removed excessive debugPrint (viewport reset)
    });
  }

  @override
  Widget build(BuildContext context) {
    // Disable browser context menu on web platform
    if (kIsWeb) {
      BrowserContextMenu.disableContextMenu();
    }

    final Widget chartContent = Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        _handleKeyEvent(event);
        return KeyEventResult.handled;
      },
      child: Builder(
        builder: (context) {
          final hasFocus = _focusNode.hasFocus;
          return MouseRegion(
            onEnter: (_) {
              if (!_focusNode.hasFocus) {
                _focusNode.requestFocus();
              }
            },
            onExit: (_) {
              if (_focusNode.hasFocus) {
                _focusNode.unfocus();
              }
            },
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                border: (widget.interactionConfig?.showFocusBorder ?? false) && hasFocus
                    ? Border.all(
                        color: widget.theme?.focusBorderColor ?? Colors.blue,
                        width: widget.theme?.focusBorderWidth ?? 2.0,
                      )
                    : null,
                borderRadius: (widget.interactionConfig?.showFocusBorder ?? false) && hasFocus && (widget.theme?.focusBorderRadius ?? 0.0) > 0
                    ? BorderRadius.circular(widget.theme?.focusBorderRadius ?? 0.0)
                    : null,
              ),
              child: Stack(
                children: [
                  MouseRegion(
                    cursor: _currentCursor,
                    child: RawGestureDetector(
                      gestures: {
                        PriorityPanGestureRecognizer: GestureRecognizerFactoryWithHandlers<PriorityPanGestureRecognizer>(
                          () => _panRecognizer,
                          (recognizer) {},
                        ),
                        PriorityTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<PriorityTapGestureRecognizer>(
                          () => _tapRecognizer,
                          (recognizer) {},
                        ),
                      },
                      child: _ChartRenderWidget(
                        key: _renderBoxKey,
                        coordinator: _coordinator,
                        spatialIndex: _spatialIndex,
                        elementGenerator: _elementGenerator,
                        elementGeneratorVersion: _elementGeneratorVersion,
                        xAxis: _xAxis,
                        yAxis: _yAxis,
                        theme: widget.theme,
                        tooltipsEnabled: widget.interactionConfig?.tooltip.enabled ?? true,
                        showXScrollbar: widget.interactionConfig?.showXScrollbar ?? widget.showXScrollbar,
                        showYScrollbar: widget.interactionConfig?.showYScrollbar ?? widget.showYScrollbar,
                        scrollbarTheme: widget.scrollbarTheme,
                        interactionConfig: widget.interactionConfig,
                        onCursorChange: _handleCursorChange,
                        onAnnotationChanged: _handleAnnotationChanged,
                        onElementHover: _handleElementHover,
                        onRangeCreationComplete: _onRangeCreationComplete,
                      ),
                    ),
                  ),
                  if (widget.showDebugInfo) Positioned(top: 8, left: 8, child: _DebugOverlay(coordinator: _coordinator)),

                  // Red crosshair overlay for range annotation creation mode
                  if (_coordinator.currentMode == InteractionMode.rangeAnnotationCreation)
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: _RangeCreationCrosshairOverlay(),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );

    // Add title, subtitle, and legend
    if (widget.title != null || widget.subtitle != null || widget.showLegend) {
      final children = <Widget>[];

      if (widget.title != null) {
        children.add(
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              widget.title!,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      if (widget.subtitle != null) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.subtitle!,
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      // Chart content takes available space
      children.add(Expanded(child: chartContent));

      if (widget.showLegend) {
        children.add(
          ChartLegend(
            series: widget.series,
            hiddenSeriesIds: _hiddenSeriesIds,
            onSeriesToggle: (seriesId) {
              setState(() {
                if (_hiddenSeriesIds.contains(seriesId)) {
                  _hiddenSeriesIds.remove(seriesId);
                } else {
                  _hiddenSeriesIds.add(seriesId);
                }
                _rebuildElements();
              });
            },
          ),
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    return chartContent;
  }
}

class _ChartRenderWidget extends LeafRenderObjectWidget {
  const _ChartRenderWidget({
    super.key,
    required this.coordinator,
    required this.spatialIndex,
    this.elementGenerator,
    required this.elementGeneratorVersion,
    this.xAxis,
    this.yAxis,
    this.theme,
    required this.tooltipsEnabled,
    required this.showXScrollbar,
    required this.showYScrollbar,
    this.scrollbarTheme,
    this.interactionConfig,
    this.onCursorChange,
    this.onAnnotationChanged,
    this.onElementHover,
    this.onRangeCreationComplete,
  });

  final ChartInteractionCoordinator coordinator;
  final QuadTree spatialIndex;
  final List<ChartElement> Function(ChartTransform)? elementGenerator;
  final int elementGeneratorVersion;
  final chart_axis.Axis? xAxis;
  final chart_axis.Axis? yAxis;
  final ChartTheme? theme;
  final bool tooltipsEnabled;
  final bool showXScrollbar;
  final bool showYScrollbar;
  final ScrollbarConfig? scrollbarTheme;
  final InteractionConfig? interactionConfig;
  final void Function(MouseCursor cursor)? onCursorChange;
  final void Function(String annotationId, ChartAnnotation updatedAnnotation)? onAnnotationChanged;
  final void Function(ChartElement? element)? onElementHover;
  final void Function(double startX, double endX, double startY, double endY)? onRangeCreationComplete;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return ChartRenderBox(
      coordinator: coordinator,
      elementGenerator: elementGenerator,
      theme: theme,
      tooltipsEnabled: tooltipsEnabled,
      showXScrollbar: showXScrollbar,
      showYScrollbar: showYScrollbar,
      scrollbarTheme: scrollbarTheme,
      interactionConfig: interactionConfig,
      onCursorChange: onCursorChange,
      onAnnotationChanged: onAnnotationChanged,
      onElementHover: onElementHover,
      onRangeCreationComplete: onRangeCreationComplete,
    )
      ..setXAxis(xAxis)
      ..setYAxis(yAxis);
  }

  @override
  void updateRenderObject(BuildContext context, ChartRenderBox renderObject) {
    renderObject
      ..setElementGenerator(elementGenerator, elementGeneratorVersion)
      ..setXAxis(xAxis)
      ..setYAxis(yAxis)
      ..setTheme(theme)
      ..setTooltipsEnabled(tooltipsEnabled)
      ..setShowXScrollbar(showXScrollbar)
      ..setShowYScrollbar(showYScrollbar)
      ..setInteractionConfig(interactionConfig)
      ..onElementHover = onElementHover;
  }
}

class _DebugOverlay extends StatelessWidget {
  const _DebugOverlay({required this.coordinator});

  final ChartInteractionCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(4)),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mode: ${coordinator.currentMode.name}'),
            Text('Selected: ${coordinator.selectedElements.length}'),
            if (coordinator.activeElement != null) Text('Active: ${coordinator.activeElement!.id}'),
          ],
        ),
      ),
    );
  }
}

/// Red crosshair overlay for range annotation creation mode.
/// Provides visual feedback that the chart is in range selection mode.
class _RangeCreationCrosshairOverlay extends StatefulWidget {
  const _RangeCreationCrosshairOverlay();

  @override
  State<_RangeCreationCrosshairOverlay> createState() => _RangeCreationCrosshairOverlayState();
}

class _RangeCreationCrosshairOverlayState extends State<_RangeCreationCrosshairOverlay> {
  Offset? _mousePosition;

  @override
  void initState() {
    super.initState();
    debugPrint('🎨 _RangeCreationCrosshairOverlay initState - overlay widget created');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 _RangeCreationCrosshairOverlay build - position: $_mousePosition');
    return MouseRegion(
      onHover: (event) {
        debugPrint('🎨 Crosshair overlay onHover: ${event.localPosition}');
        setState(() {
          _mousePosition = event.localPosition;
        });
      },
      onExit: (_) {
        debugPrint('🎨 Crosshair overlay onExit');
        setState(() {
          _mousePosition = null;
        });
      },
      child: CustomPaint(
        painter: _CrosshairPainter(
          position: _mousePosition,
          color: Colors.red.withOpacity(0.8),
        ),
        size: Size.infinite, // CRITICAL: Ensure CustomPaint fills available space
      ),
    );
  }
}

/// Custom painter for red crosshair lines.
class _CrosshairPainter extends CustomPainter {
  _CrosshairPainter({
    required this.position,
    required this.color,
  });

  final Offset? position;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    debugPrint('🎨 _CrosshairPainter.paint called - position: $position, size: $size');
    
    // Don't paint if no mouse position yet
    if (position == null) {
      debugPrint('🎨 _CrosshairPainter.paint - position is null, skipping paint');
      return;
    }

    debugPrint('🎨 _CrosshairPainter.paint - painting red crosshair at $position');

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5 // Thicker for better visibility
      ..style = PaintingStyle.stroke;

    // Vertical line
    canvas.drawLine(
      Offset(position!.dx, 0),
      Offset(position!.dx, size.height),
      paint,
    );

    // Horizontal line
    canvas.drawLine(
      Offset(0, position!.dy),
      Offset(size.width, position!.dy),
      paint,
    );

    // Draw small circle at intersection for emphasis
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill; // Fill the circle for better visibility

    canvas.drawCircle(position!, 6.0, circlePaint); // Larger circle
    
    debugPrint('🎨 _CrosshairPainter.paint - completed drawing crosshair');
  }

  @override
  bool shouldRepaint(_CrosshairPainter oldDelegate) {
    return oldDelegate.position != position || oldDelegate.color != color;
  }
}
