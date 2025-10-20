// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';
import 'dart:math' show cos, sin, sqrt, log, pow, ln10;

import 'package:braven_charts/src/foundation/data_models/chart_data_point.dart';
// Layer 0: Foundation
import 'package:braven_charts/src/foundation/data_models/chart_series.dart';
// Layer 7: Interaction
import 'package:braven_charts/src/interaction/event_handler.dart' hide KeyEventResult;
import 'package:braven_charts/src/interaction/keyboard_handler.dart';
import 'package:braven_charts/src/interaction/models/crosshair_config.dart';
import 'package:braven_charts/src/interaction/models/interaction_config.dart';
import 'package:braven_charts/src/interaction/models/interaction_state.dart';
import 'package:braven_charts/src/interaction/models/tooltip_config.dart';
import 'package:braven_charts/src/interaction/models/zoom_pan_state.dart';
import 'package:braven_charts/src/interaction/zoom_pan_controller.dart';
// Layer 3: Theming
import 'package:braven_charts/src/theming/chart_theme.dart';
import 'package:braven_charts/src/widgets/annotations/chart_annotation.dart';
import 'package:braven_charts/src/widgets/annotations/point_annotation.dart';
import 'package:braven_charts/src/widgets/annotations/range_annotation.dart';
import 'package:braven_charts/src/widgets/annotations/text_annotation.dart';
import 'package:braven_charts/src/widgets/annotations/threshold_annotation.dart';
import 'package:braven_charts/src/widgets/annotations/trend_annotation.dart';
import 'package:braven_charts/src/widgets/axis/axis_config.dart';
import 'package:braven_charts/src/widgets/controller/chart_controller.dart';
import 'package:braven_charts/src/widgets/enums/annotation_axis.dart';
// Layer 5: Widgets
import 'package:braven_charts/src/widgets/enums/chart_type.dart';
import 'package:braven_charts/src/widgets/enums/marker_shape.dart';
import 'package:braven_charts/src/widgets/enums/trend_type.dart';
import 'package:flutter/gestures.dart' show PointerScrollEvent, kMiddleMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey, KeyDownEvent, KeyRepeatEvent;

/// Primary user-facing widget for rendering interactive charts.
///
/// BravenChart is the single entry point for all chart types in the
/// Braven Charts library. It supports:
/// - All chart types (line, area, bar, scatter)
/// - Real-time data streaming
/// - Interactive annotations
/// - Flexible axis configuration
/// - Programmatic control via ChartController
///
/// Example:
/// ```dart
/// BravenChart(
///   chartType: ChartType.line,
///   series: [
///     ChartSeries(
///       id: 'revenue',
///       points: [
///         ChartDataPoint(x: 0, y: 100),
///         ChartDataPoint(x: 1, y: 150),
///         ChartDataPoint(x: 2, y: 120),
///       ],
///     ),
///   ],
///   xAxis: AxisConfig.defaults(),
///   yAxis: AxisConfig.defaults(),
///   showLegend: true,
/// )
/// ```
class BravenChart extends StatefulWidget {
  // ==================== CONSTRUCTOR ====================

  /// Creates a BravenChart widget.
  ///
  /// Required parameters:
  /// - [chartType]: Type of chart to render
  /// - [series]: Data to display (or use [dataStream] for real-time)
  ///
  /// Validation:
  /// - At least one series OR [dataStream] required
  /// - [width] and [height] must be positive if specified
  BravenChart({
    super.key,
    required this.chartType,
    required this.series,
    this.width,
    this.height,
    this.theme,
    this.xAxis,
    this.yAxis,
    this.annotations = const [],
    this.controller,
    this.dataStream,
    this.title,
    this.subtitle,
    this.showLegend = true,
    this.showToolbar = false,
    this.interactiveAnnotations = false,
    this.loadingWidget,
    this.errorWidget,
    this.onPointTap,
    this.onPointHover,
    this.onBackgroundTap,
    this.onSeriesSelected,
    this.onAnnotationTap,
    this.onAnnotationDragged,
    this.interactionConfig,
  })  : assert(
          series.isNotEmpty || dataStream != null,
          'At least one series or dataStream is required',
        ),
        assert(
          width == null || width > 0,
          'Width must be positive',
        ),
        assert(
          height == null || height > 0,
          'Height must be positive',
        );

  // ==================== FACTORY CONSTRUCTORS ====================

  /// Creates a chart from a simple list of y-values.
  ///
  /// X-values are auto-generated as 0, 1, 2, ... if not provided.
  ///
  /// Example:
  /// ```dart
  /// BravenChart.fromValues(
  ///   chartType: ChartType.line,
  ///   seriesId: 'sales',
  ///   yValues: [100, 150, 120, 180],
  /// )
  /// ```
  factory BravenChart.fromValues({
    Key? key,
    required ChartType chartType,
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
    String? title,
    String? subtitle,
    bool showLegend = true,
    bool showToolbar = false,
    bool interactiveAnnotations = false,
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
    final points = List.generate(
      yValues.length,
      (i) => ChartDataPoint(x: xVals[i], y: yValues[i]),
    );

    // Create series
    final series = ChartSeries(
      id: seriesId,
      name: seriesName,
      points: points,
      color: seriesColor,
    );

    return BravenChart(
      key: key,
      chartType: chartType,
      series: [series],
      width: width,
      height: height,
      theme: theme,
      xAxis: xAxis,
      yAxis: yAxis,
      annotations: annotations,
      controller: controller,
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
  ///
  /// Example:
  /// ```dart
  /// BravenChart.fromMap(
  ///   chartType: ChartType.bar,
  ///   seriesId: 'quarterly-sales',
  ///   data: {
  ///     'Q1': 100.0,
  ///     'Q2': 150.0,
  ///     'Q3': 120.0,
  ///     'Q4': 180.0,
  ///   },
  /// )
  /// ```
  factory BravenChart.fromMap({
    Key? key,
    required ChartType chartType,
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
    String? title,
    String? subtitle,
    bool showLegend = true,
    bool showToolbar = false,
    bool interactiveAnnotations = false,
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
    final series = ChartSeries(
      id: seriesId,
      name: seriesName,
      points: points,
      color: seriesColor,
    );

    return BravenChart(
      key: key,
      chartType: chartType,
      series: [series],
      width: width,
      height: height,
      theme: theme,
      xAxis: xAxis,
      yAxis: yAxis,
      annotations: annotations,
      controller: controller,
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
  ///
  /// JSON format: `[{"x": 0, "y": 1}, {"x": 1, "y": 2}]`
  ///
  /// Example:
  /// ```dart
  /// BravenChart.fromJson(
  ///   chartType: ChartType.scatter,
  ///   seriesId: 'measurements',
  ///   json: '[{"x":0,"y":10},{"x":1,"y":20},{"x":2,"y":15}]',
  /// )
  /// ```
  factory BravenChart.fromJson({
    Key? key,
    required ChartType chartType,
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
    String? title,
    String? subtitle,
    bool showLegend = true,
    bool showToolbar = false,
    bool interactiveAnnotations = false,
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
    final series = ChartSeries(
      id: seriesId,
      name: seriesName,
      points: points,
      color: seriesColor,
    );

    return BravenChart(
      key: key,
      chartType: chartType,
      series: [series],
      width: width,
      height: height,
      theme: theme,
      xAxis: xAxis,
      yAxis: yAxis,
      annotations: annotations,
      controller: controller,
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
  // ==================== CORE CONFIGURATION ====================

  /// Type of chart to render (line, area, bar, scatter).
  final ChartType chartType;

  /// Data series to display.
  ///
  /// At least one series OR [dataStream] is required.
  final List<ChartSeries> series;

  // ==================== DIMENSIONS ====================

  /// Chart width in logical pixels.
  ///
  /// If null, uses parent constraints.
  /// Must be positive if specified.
  final double? width;

  /// Chart height in logical pixels.
  ///
  /// If null, uses parent constraints.
  /// Must be positive if specified.
  final double? height;

  // ==================== THEMING ====================

  /// Visual theme for the chart.
  ///
  /// If null, uses ChartTheme.defaultLight or inherits from Theme.of(context).
  final ChartTheme? theme;

  // ==================== AXIS CONFIGURATION ====================

  /// X-axis configuration.
  ///
  /// Controls visibility, labels, grid, range, and styling.
  /// Defaults to AxisConfig.defaults() if null.
  final AxisConfig? xAxis;

  /// Y-axis configuration.
  ///
  /// Controls visibility, labels, grid, range, and styling.
  /// Defaults to AxisConfig.defaults() if null.
  final AxisConfig? yAxis;

  // ==================== ANNOTATIONS ====================

  /// Static annotations to render on the chart.
  ///
  /// For dynamic annotations, use [controller.addAnnotation()].
  final List<ChartAnnotation> annotations;

  // ==================== REAL-TIME DATA ====================

  /// Controller for programmatic data and annotation updates.
  ///
  /// Provides methods to add/remove points and annotations dynamically.
  /// If null, widget creates an internal controller.
  final ChartController? controller;

  /// Stream for real-time data updates.
  ///
  /// When provided, the widget subscribes and adds incoming points
  /// to the chart with automatic throttling (16ms for 60 FPS).
  final Stream<ChartDataPoint>? dataStream;

  // ==================== UI ELEMENTS ====================

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

  // ==================== INTERACTION ====================

  /// Whether annotations should be interactive (draggable, editable).
  ///
  /// Requires annotations to have `allowDragging = true`.
  final bool interactiveAnnotations;

  // ==================== LOADING & ERROR STATES ====================

  /// Widget to display while loading data.
  ///
  /// Defaults to CircularProgressIndicator.
  final Widget? loadingWidget;

  /// Widget to display when an error occurs.
  ///
  /// Receives the error object for custom error messages.
  /// Defaults to Text('Error: ...').
  final Widget Function(Object error)? errorWidget;

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

  // ==================== INTERACTION SYSTEM ====================

  /// Configuration for interactive features (crosshair, tooltip, gestures, keyboard navigation).
  ///
  /// If null, interaction features are disabled. Use [InteractionConfig.defaultConfig()]
  /// for standard interaction behavior, or customize specific features:
  ///
  /// ```dart
  /// BravenChart(
  ///   interactionConfig: InteractionConfig(
  ///     crosshair: CrosshairConfig(enabled: true, snapToDataPoint: true),
  ///     tooltip: TooltipConfig(enabled: true),
  ///     enableZoom: true,
  ///     enablePan: true,
  ///   ),
  ///   // ... other parameters
  /// )
  /// ```
  final InteractionConfig? interactionConfig;

  // ==================== STATE ====================

  @override
  State<BravenChart> createState() => _BravenChartState();
}

// ==================== STATE CLASS ====================

/// Private state class for BravenChart.
///
/// Manages lifecycle, controller subscriptions, stream subscriptions,
/// and rendering logic.
class _BravenChartState extends State<BravenChart> with TickerProviderStateMixin {
  // ==================== INTERNAL STATE ====================

  /// Subscription to the dataStream for real-time updates.
  StreamSubscription<ChartDataPoint>? _streamSubscription;

  /// Internal controller created if none provided.
  ChartController? _internalController;

  /// Timer for throttling stream updates to 60 FPS (16ms).
  Timer? _throttleTimer;

  /// Pending data point for throttled stream processing.
  ChartDataPoint? _pendingDataPoint;

  /// Flag to track if we're currently throttling.
  bool _isThrottling = false;

  /// Event handler for interaction system (Layer 7).
  EventHandler? _eventHandler;

  /// Keyboard handler for keyboard navigation.
  KeyboardHandler? _keyboardHandler;

  /// Zoom/pan controller for viewport transformation.
  ZoomPanController? _zoomPanController;

  /// Current interaction state.
  InteractionState _interactionState = InteractionState.initial();

  /// Tracks if currently panning with middle-mouse button.
  bool _isPanningWithMiddleMouse = false;

  /// Start position for middle-mouse pan drag.
  Offset? _panStartPosition;

  /// Manual SHIFT key state tracking for web compatibility.
  /// HardwareKeyboard.instance doesn't work reliably in Flutter Web.
  bool _isShiftPressed = false;

  /// Manual ALT key state tracking for web compatibility.
  bool _isAltPressed = false;

  /// Focus node for keyboard event handling.
  final FocusNode _focusNode = FocusNode();

  /// Animation controller for smooth zoom transitions.
  AnimationController? _zoomAnimationController;

  /// Animation for zoom level X.
  Animation<double>? _zoomAnimationX;

  /// Animation for zoom level Y.
  Animation<double>? _zoomAnimationY;

  /// Animation controller for smooth pan transitions.
  AnimationController? _panAnimationController;

  /// Animation for pan offset.
  Animation<Offset>? _panAnimation;

  /// Cached chart rectangle for use in interaction callbacks.
  ///
  /// Stores the calculated chart area (with padding) so that onHover,
  /// onTap, and other interaction callbacks can access it without
  /// needing to recalculate from render box (which may not be accurate).
  Rect? _cachedChartRect;

  /// Timer for hiding tooltip after a delay.
  ///
  /// The tooltip persists even after the mouse leaves the marker.
  /// It only hides after this timeout or when a new marker is hovered.
  Timer? _tooltipHideTimer;

  // ==================== LIFECYCLE METHODS ====================

  @override
  void initState() {
    super.initState();

    // Initialize zoom animation controller (250ms for smooth transitions)
    _zoomAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    )..addListener(() {
        // Update zoom state during animation
        if (_zoomAnimationX != null && _zoomAnimationY != null) {
          setState(() {
            final currentZoomState = _interactionState.zoomPanState;
            final newZoomState = currentZoomState.copyWith(
              zoomLevelX: _zoomAnimationX!.value,
              zoomLevelY: _zoomAnimationY!.value,
            );
            _interactionState = _interactionState.copyWith(zoomPanState: newZoomState);
          });
        }
      });

    // Initialize pan animation controller (250ms for smooth transitions)
    _panAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    )..addListener(() {
        // Update pan state during animation
        if (_panAnimation != null) {
          setState(() {
            final currentZoomState = _interactionState.zoomPanState;
            final newZoomState = currentZoomState.copyWith(
              panOffset: _panAnimation!.value,
            );
            _interactionState = _interactionState.copyWith(zoomPanState: newZoomState);
          });
        }
      });

    // Create internal controller if not provided
    if (widget.controller == null) {
      _internalController = ChartController();
    }

    // Subscribe to controller updates
    _getController()?.addListener(_onControllerUpdate);

    // Subscribe to dataStream if provided
    if (widget.dataStream != null) {
      _subscribeToStream(widget.dataStream!);
    }

    // Initialize interaction system if enabled
    if (widget.interactionConfig != null && widget.interactionConfig!.enabled) {
      _eventHandler = EventHandler();
      _registerInteractionCallbacks();

      // Initialize ZoomPanController if zoom or pan is enabled
      if (widget.interactionConfig!.enableZoom || widget.interactionConfig!.enablePan) {
        _zoomPanController = ZoomPanController();
      }

      // Initialize KeyboardHandler if keyboard navigation is enabled
      if (widget.interactionConfig!.keyboard.enabled) {
        _keyboardHandler = KeyboardHandler();
      }
    }
  }

  /// Registers all interaction callbacks with the event handler.
  void _registerInteractionCallbacks() {
    if (_eventHandler == null || widget.interactionConfig == null) return;

    final config = widget.interactionConfig!;

    // Register all 10 callback types if they exist
    // Note: Callbacks will be invoked from event handlers in _wrapWithInteractionSystem
    if (config.onDataPointTap != null) {
      // EventHandler will call this when tap is detected
    }
    if (config.onDataPointHover != null) {
      // EventHandler will call this when hover is detected
    }
    if (config.onDataPointLongPress != null) {
      // EventHandler will call this when long press is detected
    }
    if (config.onSelectionChanged != null) {
      // EventHandler will call this when selection changes
    }
    if (config.onZoomChanged != null) {
      // EventHandler will call this when zoom changes
    }
    if (config.onPanChanged != null) {
      // EventHandler will call this when pan changes
    }
    if (config.onViewportChanged != null) {
      // EventHandler will call this when viewport changes
    }
    if (config.onCrosshairChanged != null) {
      // EventHandler will call this when crosshair changes
    }
    if (config.onTooltipChanged != null) {
      // EventHandler will call this when tooltip changes
    }
    if (config.onKeyboardAction != null) {
      // EventHandler will call this when keyboard action occurs
    }
  }

  @override
  void didUpdateWidget(BravenChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle controller changes
    if (widget.controller != oldWidget.controller) {
      // Unsubscribe from old controller
      oldWidget.controller?.removeListener(_onControllerUpdate);

      // Dispose internal controller if we created it
      if (oldWidget.controller == null && _internalController != null) {
        _internalController!.dispose();
        _internalController = null;
      }

      // Create new internal controller if needed
      if (widget.controller == null) {
        _internalController = ChartController();
      }

      // Subscribe to new controller
      _getController()?.addListener(_onControllerUpdate);
    }

    // Handle dataStream changes
    if (widget.dataStream != oldWidget.dataStream) {
      // Cancel old subscription
      _streamSubscription?.cancel();
      _streamSubscription = null;

      // Cancel throttle timer
      _throttleTimer?.cancel();
      _throttleTimer = null;
      _pendingDataPoint = null;
      _isThrottling = false;

      // Subscribe to new stream
      if (widget.dataStream != null) {
        _subscribeToStream(widget.dataStream!);
      }
    }

    // Handle interaction config changes
    if (widget.interactionConfig != oldWidget.interactionConfig) {
      // Dispose old event handler
      if (_eventHandler != null) {
        _eventHandler!.dispose();
        _eventHandler = null;
      }

      // Create new event handler if enabled
      if (widget.interactionConfig != null && widget.interactionConfig!.enabled) {
        _eventHandler = EventHandler();
        _registerInteractionCallbacks();

        // Reset interaction state
        _interactionState = InteractionState.initial();
      }
    }
  }

  @override
  void dispose() {
    // Cancel stream subscription
    _streamSubscription?.cancel();
    _streamSubscription = null;

    // Cancel throttle timer
    _throttleTimer?.cancel();
    _throttleTimer = null;

    // Cancel tooltip hide timer
    _tooltipHideTimer?.cancel();
    _tooltipHideTimer = null;

    // Dispose zoom animation controller
    _zoomAnimationController?.dispose();
    _zoomAnimationController = null;

    // Dispose pan animation controller
    _panAnimationController?.dispose();
    _panAnimationController = null;

    // Unsubscribe from controller
    _getController()?.removeListener(_onControllerUpdate);

    // Dispose internal controller
    _internalController?.dispose();
    _internalController = null;

    // Dispose interaction system
    _eventHandler?.dispose();
    _eventHandler = null;

    // Dispose focus node
    _focusNode.dispose();

    super.dispose();
  }

  // ==================== HELPER METHODS ====================

  /// Gets the active controller (external or internal).
  ChartController? _getController() {
    return widget.controller ?? _internalController;
  }

  /// Subscribes to the data stream with throttling.
  void _subscribeToStream(Stream<ChartDataPoint> stream) {
    _streamSubscription = stream.listen(
      _onStreamData,
      onError: (error) {
        // Handle stream errors gracefully
        debugPrint('BravenChart: Stream error: $error');
      },
      onDone: () {
        // Stream completed
        debugPrint('BravenChart: Stream completed');
      },
    );
  }

  /// Handles incoming stream data with throttling (60 FPS = 16ms).
  void _onStreamData(ChartDataPoint point) {
    // Store the latest data point
    _pendingDataPoint = point;

    // If not currently throttling, process immediately
    if (!_isThrottling) {
      _processStreamData();
      _isThrottling = true;

      // Set up throttle timer (16ms for 60 FPS)
      _throttleTimer = Timer(const Duration(milliseconds: 16), () {
        _isThrottling = false;
        _throttleTimer = null;

        // Process any pending data point
        if (_pendingDataPoint != null) {
          _processStreamData();
          _isThrottling = true;

          // Recursively throttle if more data arrives
          _throttleTimer = Timer(const Duration(milliseconds: 16), () {
            _isThrottling = false;
            _throttleTimer = null;
          });
        }
      });
    }
  }

  /// Processes the pending stream data point.
  void _processStreamData() {
    if (_pendingDataPoint == null) return;

    // Clear the pending data point
    _pendingDataPoint = null;

    // Add point to the first series (or create a default series)
    // This is a simplified approach - real implementation would need
    // to determine which series to add the point to
    setState(() {
      // TODO: Determine target series from dataStream metadata
      // For now, this is a placeholder that will be enhanced in T023
    });
  }

  /// Called when the controller notifies of changes.
  void _onControllerUpdate() {
    // Rebuild widget when controller data changes
    setState(() {
      // Controller has updated its internal state
    });
  }

  /// Animates zoom level changes for smooth transitions.
  ///
  /// Parameters:
  /// - [newZoomX]: Target zoom level for X axis
  /// - [newZoomY]: Target zoom level for Y axis
  /// - [onComplete]: Optional callback when animation completes
  void _animateZoom({
    required double newZoomX,
    required double newZoomY,
    VoidCallback? onComplete,
  }) {
    if (_zoomAnimationController == null) {
      // Fallback: instant zoom if no animation controller
      setState(() {
        final currentZoomState = _interactionState.zoomPanState;
        final newZoomState = currentZoomState.copyWith(
          zoomLevelX: newZoomX,
          zoomLevelY: newZoomY,
        );
        _interactionState = _interactionState.copyWith(zoomPanState: newZoomState);
      });
      onComplete?.call();
      return;
    }

    // Get current zoom levels
    final currentZoomState = _interactionState.zoomPanState;
    final currentZoomX = currentZoomState.zoomLevelX;
    final currentZoomY = currentZoomState.zoomLevelY;

    // Create tween animations
    _zoomAnimationX = Tween<double>(
      begin: currentZoomX,
      end: newZoomX,
    ).animate(CurvedAnimation(
      parent: _zoomAnimationController!,
      curve: Curves.easeOut,
    ));

    _zoomAnimationY = Tween<double>(
      begin: currentZoomY,
      end: newZoomY,
    ).animate(CurvedAnimation(
      parent: _zoomAnimationController!,
      curve: Curves.easeOut,
    ));

    // Reset and start animation
    _zoomAnimationController!.reset();
    _zoomAnimationController!.forward().then((_) {
      onComplete?.call();
    });
  }

  /// Animates pan offset changes for smooth transitions.
  ///
  /// Parameters:
  /// - [newPanOffset]: Target pan offset
  /// - [onComplete]: Optional callback when animation completes
  void _animatePan({
    required Offset newPanOffset,
    VoidCallback? onComplete,
  }) {
    if (_panAnimationController == null) {
      // Fallback: instant pan if no animation controller
      setState(() {
        final currentZoomState = _interactionState.zoomPanState;
        final newZoomState = currentZoomState.copyWith(
          panOffset: newPanOffset,
        );
        _interactionState = _interactionState.copyWith(zoomPanState: newZoomState);
      });
      onComplete?.call();
      return;
    }

    // Get current pan offset
    final currentZoomState = _interactionState.zoomPanState;
    final currentPanOffset = currentZoomState.panOffset;

    // Create tween animation
    _panAnimation = Tween<Offset>(
      begin: currentPanOffset,
      end: newPanOffset,
    ).animate(CurvedAnimation(
      parent: _panAnimationController!,
      curve: Curves.easeOut,
    ));

    // Reset and start animation
    _panAnimationController!.reset();
    _panAnimationController!.forward().then((_) {
      onComplete?.call();
    });
  }

  /// Starts or restarts the tooltip hide timer.
  ///
  /// Cancels any existing timer and starts a new one with the configured timeout.
  /// When the timer fires, the tooltip is hidden.
  void _startTooltipHideTimer() {
    final config = widget.interactionConfig?.tooltip;
    if (config == null) return;

    // Cancel existing timer
    _tooltipHideTimer?.cancel();

    // Start new timer with the configured hide delay
    // hideDelay is shown duration, we want persistence after hover ends
    // Using a longer timeout for the tooltip to persist (5 seconds by default)
    const persistDelay = Duration(seconds: 5);
    _tooltipHideTimer = Timer(persistDelay, () {
      if (mounted) {
        setState(() {
          _interactionState = _interactionState.copyWith(
            isTooltipVisible: false,
            tooltipPosition: null,
            tooltipDataPoint: null,
          );
        });
      }
    });
  }

  // ==================== BUILD METHOD ====================

  @override
  Widget build(BuildContext context) {
    // Get effective theme
    final effectiveTheme = widget.theme ?? ChartTheme.defaultLight;

    // Get effective axis configurations
    final effectiveXAxis = widget.xAxis ?? AxisConfig.defaults();
    final effectiveYAxis = widget.yAxis ?? AxisConfig.defaults();

    // Get all series (widget series + controller series)
    final allSeries = _getAllSeries();

    // Get all annotations (widget annotations + controller annotations)
    final allAnnotations = _getAllAnnotations();

    // Build the chart widget
    // NOTE: RepaintBoundary removed - it was caching the painted content and preventing repaints
    Widget chartWidget = CustomPaint(
      painter: _BravenChartPainter(
        chartType: widget.chartType,
        series: allSeries,
        theme: effectiveTheme,
        xAxis: effectiveXAxis,
        yAxis: effectiveYAxis,
        annotations: [], // Chart painter doesn't render annotations
        zoomPanState: _interactionState.zoomPanState,
      ),
      child: Container(), // Force size from parent instead of using size parameter
    );

    // Add annotation overlay if annotations exist
    if (allAnnotations.isNotEmpty) {
      chartWidget = Stack(
        children: [
          chartWidget,
          // Annotation overlay
          _AnnotationOverlay(
            annotations: allAnnotations,
            interactiveAnnotations: widget.interactiveAnnotations,
            onAnnotationTap: widget.onAnnotationTap,
            onAnnotationDragged: widget.onAnnotationDragged,
          ),
        ],
      );
    }

    // Wrap with dimensions if specified
    if (widget.width != null || widget.height != null) {
      chartWidget = SizedBox(
        width: widget.width,
        height: widget.height,
        child: chartWidget,
      );
    }

    // Add title/subtitle if provided
    if (widget.title != null || widget.subtitle != null) {
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

      children.add(Flexible(child: chartWidget));

      chartWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    }

    // Wrap with interaction system if enabled
    if (widget.interactionConfig != null && widget.interactionConfig!.enabled) {
      chartWidget = _wrapWithInteractionSystem(chartWidget);
    }

    return chartWidget;
  }

  /// Wraps the chart widget with interaction system components.
  ///
  /// Integrates crosshair, tooltip, mouse/touch handling, keyboard navigation,
  /// and all interaction callbacks.
  Widget _wrapWithInteractionSystem(Widget child) {
    final config = widget.interactionConfig!;

    // Use LayoutBuilder to get size safely during build
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final chartRect = _calculateChartRect(size);

        // Cache the chartRect for use in interaction callbacks
        _cachedChartRect = chartRect;
        print('🗂️ CACHED chartRect: left=${chartRect.left}, top=${chartRect.top}, width=${chartRect.width}, height=${chartRect.height}');

        // Build the full interaction stack
        Widget interactiveWidget = Stack(
          children: [
            // Base chart
            child,

            // Crosshair overlay (if enabled and visible)
            if (config.crosshair.enabled &&
                _interactionState.isCrosshairVisible &&
                _interactionState.crosshairPosition != null &&
                _interactionState.crosshairPosition!.dx.isFinite &&
                _interactionState.crosshairPosition!.dy.isFinite)
              Positioned.fill(
                child: CustomPaint(
                  painter: _CrosshairPainter(
                    position: _interactionState.crosshairPosition!,
                    config: config.crosshair,
                    nearestPoint: _interactionState.hoveredPoint != null &&
                            _interactionState.hoveredPoint!.containsKey('x') &&
                            _interactionState.hoveredPoint!.containsKey('y')
                        ? () {
                            // Transform DATA coordinates to SCREEN coordinates with current zoom/pan
                            final dataX = (_interactionState.hoveredPoint!['x'] as num?)?.toDouble() ?? 0;
                            final dataY = (_interactionState.hoveredPoint!['y'] as num?)?.toDouble() ?? 0;

                            final allSeries = _getAllSeries();
                            if (allSeries.isEmpty) return null;

                            final bounds = _calculateDataBounds(allSeries, chartRect: chartRect);
                            final point = ChartDataPoint(x: dataX, y: dataY);
                            final screenPos = _dataToScreenPoint(point, chartRect, bounds);

                            // Validate coordinates are finite and within reasonable bounds
                            if (screenPos.dx.isFinite && screenPos.dy.isFinite) {
                              return screenPos;
                            }
                            return null;
                          }()
                        : null,
                    chartSize: Size.infinite,
                    dataBounds: () {
                      final allSeries = _getAllSeries();
                      if (allSeries.isEmpty) return null;
                      return _calculateDataBounds(allSeries, chartRect: chartRect);
                    }(),
                    chartRect: chartRect,
                  ),
                ),
              ),

            // Tooltip overlay (if enabled and visible)
            ..._buildTooltipOverlay() != null ? [_buildTooltipOverlay()!] : [],
          ],
        );

        // Wrap in MouseRegion for hover detection
        interactiveWidget = MouseRegion(
          onEnter: (_) {
            // Mouse entered chart area - request focus for keyboard interaction
            if (config.keyboard.enabled && !_focusNode.hasFocus) {
              _focusNode.requestFocus();
            }
          },
          onExit: (_) {
            setState(() {
              // Only hide crosshair, NOT tooltip
              // Tooltip persists after mouse exits and hides via timer
              _interactionState = _interactionState.copyWith(
                isCrosshairVisible: false,
                crosshairPosition: null,
              );
            });

            // Invoke hover callback with null (exited)
            const exitPosition = Offset.zero; // Position doesn't matter for exit
            config.onDataPointHover?.call(null, exitPosition);
          },
          onHover: (event) {
            List<Map<String, dynamic>> snapPointsData = const [];

            setState(() {
              // Update crosshair position
              _interactionState = _interactionState.copyWith(
                crosshairPosition: event.localPosition,
                isCrosshairVisible: config.crosshair.enabled,
              );

              // Find nearest data point for snap and tooltip
              final nearestPointData = _findNearestDataPoint(event.localPosition);
              if (nearestPointData != null) {
                snapPointsData = [nearestPointData]; // Capture for callback

                // Calculate the marker's screen position with current zoom/pan transforms
                final allSeries = _getAllSeries();

                // CRITICAL: The marker position MUST use the screenX/screenY already calculated in _findNearestDataPoint
                // This ensures the tooltip position exactly matches the marker on screen.
                // Using event.localPosition as fallback would tie tooltip to cursor!
                final markerScreenX = (nearestPointData['screenX'] as num?)?.toDouble();
                final markerScreenY = (nearestPointData['screenY'] as num?)?.toDouble();

                final Offset markerPosition;
                if (markerScreenX != null && markerScreenY != null && markerScreenX.isFinite && markerScreenY.isFinite && _cachedChartRect != null) {
                  // Use the cached screen coordinates from nearest point detection
                  // These are already in Stack-local coordinates (relative to chart area origin)
                  markerPosition = Offset(markerScreenX + _cachedChartRect!.left, markerScreenY + _cachedChartRect!.top);
                  print(
                      '📍 TOOLTIP MARKER: Using cached screenPos! markerX=$markerScreenX, markerY=$markerScreenY, final=(${markerPosition.dx}, ${markerPosition.dy})');
                } else {
                  // Fallback: Calculate from data point (should not happen if _findNearestDataPoint worked)
                  final dataX = (nearestPointData['x'] as num?)?.toDouble() ?? 0;
                  final dataY = (nearestPointData['y'] as num?)?.toDouble() ?? 0;

                  if (_cachedChartRect != null) {
                    final bounds = _calculateDataBounds(allSeries, chartRect: _cachedChartRect);
                    final point = ChartDataPoint(x: dataX, y: dataY);
                    final screenPos = _dataToScreenPoint(point, _cachedChartRect!, bounds);

                    if (screenPos.dx.isFinite && screenPos.dy.isFinite) {
                      markerPosition = Offset(screenPos.dx + _cachedChartRect!.left, screenPos.dy + _cachedChartRect!.top);
                      print(
                          '📍 TOOLTIP MARKER: Calculated from data! dataX=$dataX, dataY=$dataY, final=(${markerPosition.dx}, ${markerPosition.dy})');
                    } else {
                      // Last resort: Use cursor (should almost never happen)
                      markerPosition = event.localPosition;
                      print('❌ TOOLTIP MARKER: ERROR! Using cursor as fallback! event=${event.localPosition}');
                    }
                  } else {
                    // No chartRect available yet - use cursor
                    markerPosition = event.localPosition;
                    print('⚠️ TOOLTIP MARKER: chartRect not cached yet! Using cursor. This should only happen on first hover.');
                  }
                }

                _interactionState = _interactionState.copyWith(
                  hoveredPoint: nearestPointData,
                  hoveredSeriesId: nearestPointData['seriesId'] as String?,
                  tooltipPosition: markerPosition,
                  tooltipDataPoint: nearestPointData,
                  isTooltipVisible: config.tooltip.enabled,
                  snapPoints: snapPointsData, // Populate snapPoints with the nearest point
                );

                // Start tooltip hide timer - tooltip persists even after mouse exits
                if (config.tooltip.enabled) {
                  _startTooltipHideTimer();
                }

                // Convert Map to ChartDataPoint for callback
                final point = _mapToDataPoint(nearestPointData);
                config.onDataPointHover?.call(point, event.localPosition);
              } else {
                // No point nearby, don't clear tooltip immediately
                // Tooltip will hide via timer or when hovering a different marker
                snapPointsData = const [];
                // Don't update interaction state - let timer handle tooltip clearing
              }
            });

            // Invoke crosshair changed callback with the updated snap points
            final snapPointsList = snapPointsData.map((data) => _mapToDataPoint(data)).toList();
            config.onCrosshairChanged?.call(event.localPosition, snapPointsList);
          },
          child: interactiveWidget,
        );

        // Wrap with Listener for scroll/middle-mouse events
        interactiveWidget = Listener(
          // Handle scroll events with modifier keys
          onPointerSignal: (signal) {
            if (signal is PointerScrollEvent) {
              // Use manual state tracking for modifiers (web-compatible)
              // HardwareKeyboard.instance doesn't work reliably in Flutter Web
              final isShiftPressed = _isShiftPressed;

              if (config.enableZoom && _zoomPanController != null && isShiftPressed) {
                // SHIFT + Scroll → Zoom at cursor position
                final scrollDelta = signal.scrollDelta.dy;
                // Zoom in when scrolling up (negative delta), zoom out when scrolling down
                final zoomFactor = scrollDelta < 0 ? 1.1 : 0.9;

                setState(() {
                  final newZoomPanState = _zoomPanController!.zoom(
                    _interactionState.zoomPanState,
                    zoomFactor: zoomFactor,
                    focalPoint: signal.localPosition,
                  );

                  _interactionState = _interactionState.copyWith(
                    zoomPanState: newZoomPanState,
                  );
                });

                // Invoke zoom callback
                config.onZoomChanged?.call(
                  _interactionState.zoomPanState.zoomLevelX,
                  _interactionState.zoomPanState.zoomLevelY,
                );

                // Invoke viewport callback (visible bounds changed due to zoom)
                _invokeViewportCallback();
              }
              // If no SHIFT modifier, don't handle - allows default page scroll
              // This is CRITICAL for web UX - page must scroll normally without modifier
            }
          },

          // Handle middle-mouse button pan (PRIMARY pan method)
          onPointerDown: (event) {
            if (event.buttons == kMiddleMouseButton && config.enablePan) {
              setState(() {
                _isPanningWithMiddleMouse = true;
                _panStartPosition = event.localPosition;
              });
            }
          },

          onPointerMove: (event) {
            if (_isPanningWithMiddleMouse && _panStartPosition != null && _zoomPanController != null) {
              final delta = event.localPosition - _panStartPosition!;

              setState(() {
                final newZoomPanState = _zoomPanController!.pan(
                  _interactionState.zoomPanState,
                  delta,
                );

                _interactionState = _interactionState.copyWith(
                  zoomPanState: newZoomPanState,
                );

                _panStartPosition = event.localPosition;
              });

              // Invoke pan callback
              config.onPanChanged?.call(_interactionState.zoomPanState.panOffset);

              // Invoke viewport callback
              _invokeViewportCallback();
            }
          },

          onPointerUp: (event) {
            if (_isPanningWithMiddleMouse) {
              setState(() {
                _isPanningWithMiddleMouse = false;
                _panStartPosition = null;
              });
            }
          },

          child: interactiveWidget,
        );

        // Wrap with GestureDetector for tap/long-press/pan/pinch
        interactiveWidget = GestureDetector(
          // Handle tap for selection
          onTapDown: (details) {
            // Handle selection if enabled
            if (config.enableSelection) {
              final nearestPointData = _findNearestDataPoint(details.localPosition);
              if (nearestPointData != null) {
                final point = _mapToDataPoint(nearestPointData);

                setState(() {
                  // Add to selected points
                  final updatedSelection = List<Map<String, dynamic>>.from(
                    _interactionState.selectedPoints,
                  );
                  updatedSelection.add(nearestPointData);

                  _interactionState = _interactionState.copyWith(
                    selectedPoints: updatedSelection,
                    focusedPoint: nearestPointData,
                  );
                });

                // Invoke tap callback
                config.onDataPointTap?.call(point, details.localPosition);

                // Invoke selection callback
                final selectedPointsList = _interactionState.selectedPoints.map((data) => _mapToDataPoint(data)).toList();
                config.onSelectionChanged?.call(selectedPointsList);
              }
            }
          },

          // Long press handling
          onLongPressStart: (details) {
            final nearestPointData = _findNearestDataPoint(details.localPosition);
            if (nearestPointData != null) {
              final point = _mapToDataPoint(nearestPointData);
              config.onDataPointLongPress?.call(point, details.localPosition);
            }
          },

          // Use scale gestures if zoom is enabled (scale is superset of pan)
          // Otherwise use pan gestures if only pan is enabled
          onScaleStart: (config.enableZoom || config.enablePan) && _zoomPanController != null
              ? (details) {
                  // Track initial state for gestures
                }
              : null,

          onScaleUpdate: (config.enableZoom || config.enablePan) && _zoomPanController != null
              ? (details) {
                  setState(() {
                    ZoomPanState newZoomPanState = _interactionState.zoomPanState;

                    // Handle pinch-to-zoom (when scale changes)
                    if (config.enableZoom && details.scale != 1.0) {
                      newZoomPanState = _zoomPanController!.zoom(
                        newZoomPanState,
                        zoomFactor: details.scale,
                        focalPoint: details.focalPoint,
                      );

                      // Invoke zoom callback
                      config.onZoomChanged?.call(
                        newZoomPanState.zoomLevelX,
                        newZoomPanState.zoomLevelY,
                      );
                    }

                    // Handle pan (when delta changes but scale is 1.0)
                    if (config.enablePan && details.focalPointDelta != Offset.zero) {
                      newZoomPanState = _zoomPanController!.pan(
                        newZoomPanState,
                        details.focalPointDelta,
                      );

                      // Invoke pan callback
                      config.onPanChanged?.call(newZoomPanState.panOffset);
                    }

                    // Update state if anything changed
                    if (newZoomPanState != _interactionState.zoomPanState) {
                      _interactionState = _interactionState.copyWith(
                        zoomPanState: newZoomPanState,
                      );

                      // Invoke viewport callback
                      _invokeViewportCallback();
                    }
                  });
                }
              : null,

          onScaleEnd: (config.enableZoom || config.enablePan) && _zoomPanController != null
              ? (details) {
                  // Gesture ended - no cleanup needed
                }
              : null,

          // Double-tap to reset zoom
          onDoubleTap: config.enableZoom && _zoomPanController != null
              ? () {
                  setState(() {
                    final newZoomPanState = _zoomPanController!.resetZoom(
                      _interactionState.zoomPanState,
                    );

                    _interactionState = _interactionState.copyWith(
                      zoomPanState: newZoomPanState,
                    );
                  });

                  // Invoke zoom callback (reset to 1.0, 1.0)
                  config.onZoomChanged?.call(1.0, 1.0);

                  // Invoke viewport callback
                  _invokeViewportCallback();
                }
              : null,

          child: interactiveWidget,
        );

        // Wrap with Focus for keyboard navigation
        if (config.keyboard.enabled) {
          interactiveWidget = Focus(
            focusNode: _focusNode,
            autofocus: false,
            canRequestFocus: true,
            onKeyEvent: (node, event) {
              if (_keyboardHandler == null) return KeyEventResult.ignored;

              // Manual modifier key state tracking for web compatibility
              // HardwareKeyboard.instance doesn't work reliably in Flutter Web
              if (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight) {
                setState(() {
                  _isShiftPressed = event is KeyDownEvent || event is KeyRepeatEvent;
                });
                // Return ignored to allow scroll events to propagate
                return KeyEventResult.ignored;
              }
              if (event.logicalKey == LogicalKeyboardKey.altLeft || event.logicalKey == LogicalKeyboardKey.altRight) {
                setState(() {
                  _isAltPressed = event is KeyDownEvent || event is KeyRepeatEvent;
                });
                // Return ignored to allow events to propagate
                return KeyEventResult.ignored;
              }

              // Get all data points from series
              final allDataPoints = <Map<String, dynamic>>[];
              for (final series in widget.series) {
                for (final point in series.points) {
                  allDataPoints.add({
                    'x': point.x,
                    'y': point.y,
                    'label': point.label,
                    'metadata': point.metadata,
                    'seriesId': series.id,
                  });
                }
              }

              // CRITICAL FIX #5: INTERCEPT ZOOM KEYS - Zoom without pan offset (centered on data)
              // Keyboard zoom should zoom centered on the data center, NOT create pan offset like mouse zoom
              final key = event.logicalKey;
              if (widget.interactionConfig != null && widget.interactionConfig!.enableZoom) {
                if (key == LogicalKeyboardKey.numpadAdd || key == LogicalKeyboardKey.add || key == LogicalKeyboardKey.equal) {
                  // Zoom IN centered on data (no pan offset change) with SMOOTH ANIMATION
                  final currentZoomState = _interactionState.zoomPanState;
                  final newZoomX = (currentZoomState.zoomLevelX * 1.2).clamp(currentZoomState.minZoomLevel, currentZoomState.maxZoomLevel);
                  final newZoomY = (currentZoomState.zoomLevelY * 1.2).clamp(currentZoomState.minZoomLevel, currentZoomState.maxZoomLevel);

                  _animateZoom(
                    newZoomX: newZoomX,
                    newZoomY: newZoomY,
                    onComplete: () {
                      widget.interactionConfig!.onZoomChanged?.call(
                        _interactionState.zoomPanState.zoomLevelX,
                        _interactionState.zoomPanState.zoomLevelY,
                      );
                      _invokeViewportCallback();
                    },
                  );

                  return KeyEventResult.handled;
                } else if (key == LogicalKeyboardKey.minus || key == LogicalKeyboardKey.numpadSubtract) {
                  // Zoom OUT centered on data (no pan offset change) with SMOOTH ANIMATION
                  final currentZoomState = _interactionState.zoomPanState;
                  final newZoomX = (currentZoomState.zoomLevelX * 0.83333).clamp(currentZoomState.minZoomLevel, currentZoomState.maxZoomLevel);
                  final newZoomY = (currentZoomState.zoomLevelY * 0.83333).clamp(currentZoomState.minZoomLevel, currentZoomState.maxZoomLevel);

                  _animateZoom(
                    newZoomX: newZoomX,
                    newZoomY: newZoomY,
                    onComplete: () {
                      widget.interactionConfig!.onZoomChanged?.call(
                        _interactionState.zoomPanState.zoomLevelX,
                        _interactionState.zoomPanState.zoomLevelY,
                      );
                      _invokeViewportCallback();
                    },
                  );

                  return KeyEventResult.handled;
                }
              }

              // INTERCEPT ARROW KEYS for animated panning
              // CRITICAL: Distinguish KeyDownEvent (first press) from KeyRepeatEvent (held down)
              if (widget.interactionConfig != null && widget.interactionConfig!.enablePan) {
                if (key == LogicalKeyboardKey.arrowLeft ||
                    key == LogicalKeyboardKey.arrowRight ||
                    key == LogicalKeyboardKey.arrowUp ||
                    key == LogicalKeyboardKey.arrowDown) {
                  // Calculate new pan offset based on arrow direction
                  final currentPanOffset = _interactionState.zoomPanState.panOffset;
                  const panAmount = 50.0; // Same as KeyboardHandler default

                  Offset newPanOffset;
                  if (key == LogicalKeyboardKey.arrowLeft) {
                    newPanOffset = Offset(currentPanOffset.dx - panAmount, currentPanOffset.dy);
                  } else if (key == LogicalKeyboardKey.arrowRight) {
                    newPanOffset = Offset(currentPanOffset.dx + panAmount, currentPanOffset.dy);
                  } else if (key == LogicalKeyboardKey.arrowUp) {
                    newPanOffset = Offset(currentPanOffset.dx, currentPanOffset.dy - panAmount);
                  } else {
                    // arrowDown
                    newPanOffset = Offset(currentPanOffset.dx, currentPanOffset.dy + panAmount);
                  }

                  // DIFFERENTIATE: First press (smooth animation) vs held down (instant pan)
                  if (event is KeyDownEvent) {
                    // First press: Trigger smooth 250ms animation
                    _animatePan(
                      newPanOffset: newPanOffset,
                      onComplete: () {
                        widget.interactionConfig!.onPanChanged?.call(_interactionState.zoomPanState.panOffset);
                        _invokeViewportCallback();
                      },
                    );
                  } else if (event is KeyRepeatEvent) {
                    // Key held down: Apply pan offset directly for smooth continuous movement
                    // This prevents animation stuttering from rapid repeat events (~30ms intervals)
                    setState(() {
                      _interactionState = _interactionState.copyWith(
                        zoomPanState: _interactionState.zoomPanState.copyWith(
                          panOffset: newPanOffset,
                        ),
                      );
                    });

                    // Invoke callbacks immediately
                    widget.interactionConfig!.onPanChanged?.call(_interactionState.zoomPanState.panOffset);
                    _invokeViewportCallback();
                  }

                  return KeyEventResult.handled;
                }
              }

              // Process key event through keyboard handler
              final newState = _keyboardHandler!.handleKeyEvent(
                event,
                _interactionState,
                dataPoints: allDataPoints,
              );

              if (newState != null && newState != _interactionState) {
                print('🔄 STATE CHANGED! Updating InteractionState via setState...');
                print('   Old zoom: X=${_interactionState.zoomPanState.zoomLevelX}, Y=${_interactionState.zoomPanState.zoomLevelY}');
                print('   New zoom: X=${newState.zoomPanState.zoomLevelX}, Y=${newState.zoomPanState.zoomLevelY}');

                setState(() {
                  _interactionState = newState;

                  // If focused point changed, invoke callback
                  if (_interactionState.focusedPoint != null) {
                    final point = _mapToDataPoint(_interactionState.focusedPoint!);
                    config.onDataPointHover?.call(point, _interactionState.crosshairPosition ?? Offset.zero);
                  }

                  // If zoom/pan state changed, invoke callbacks
                  if (_interactionState.zoomPanState != newState.zoomPanState) {
                    print('✅ Zoom/Pan state changed! Calling callbacks...');
                    config.onZoomChanged?.call(
                      _interactionState.zoomPanState.zoomLevelX,
                      _interactionState.zoomPanState.zoomLevelY,
                    );
                    _invokeViewportCallback();
                  }

                  // If selection changed, invoke callback
                  if (_interactionState.selectedPoints != newState.selectedPoints) {
                    final selectedPointsList = _interactionState.selectedPoints.map((data) => _mapToDataPoint(data)).toList();
                    config.onSelectionChanged?.call(selectedPointsList);
                  }
                });

                print('✅ setState complete! Widget should rebuild now.');
                return KeyEventResult.handled;
              }

              return KeyEventResult.ignored;
            },
            child: interactiveWidget,
          );
        }

        // Wrap with Semantics for accessibility
        interactiveWidget = Semantics(
          label: 'Interactive chart',
          hint: 'Use arrow keys to navigate data points, +/- to zoom',
          enabled: true,
          child: interactiveWidget,
        );

        return interactiveWidget;
      },
    );
  }

  /// Converts a Map<String, dynamic> to a ChartDataPoint.
  ///
  /// Helper for callback invocations that require ChartDataPoint.
  ChartDataPoint _mapToDataPoint(Map<String, dynamic> data) {
    return ChartDataPoint(
      x: (data['x'] as num?)?.toDouble() ?? 0,
      y: (data['y'] as num?)?.toDouble() ?? 0,
      metadata: {
        ...data,
      },
    );
  }

  /// Finds the nearest data point to a screen position.
  ///
  /// Uses Euclidean distance with coordinate transformation.
  /// Returns null if no point is within the snap radius.
  ///
  /// Performance: O(n) where n = total points across all series.
  /// For large datasets (>10k points), consider spatial indexing (future optimization).
  Map<String, dynamic>? _findNearestDataPoint(Offset screenPosition) {
    if (!widget.interactionConfig!.crosshair.snapToDataPoint) {
      return null;
    }

    final snapRadius = widget.interactionConfig!.crosshair.snapRadius;

    // Calculate data bounds and chart rect for coordinate transformation
    final allSeries = _getAllSeries();
    if (allSeries.isEmpty) return null;

    final bounds = _calculateDataBounds(allSeries);
    final chartRect = _calculateChartRect(context.size!);

    Map<String, dynamic>? nearestPoint;
    double minDistance = snapRadius;

    // Iterate through all series to find nearest point
    for (final series in allSeries) {
      for (final point in series.points) {
        // Transform data coordinates to screen coordinates
        final screenPoint = _dataToScreenPoint(point, chartRect, bounds);

        // Skip points with invalid screen coordinates
        if (!screenPoint.dx.isFinite || !screenPoint.dy.isFinite) {
          continue;
        }

        // Calculate Euclidean distance
        final dx = screenPosition.dx - screenPoint.dx;
        final dy = screenPosition.dy - screenPoint.dy;
        final distance = sqrt(dx * dx + dy * dy);

        if (distance < minDistance) {
          minDistance = distance;
          nearestPoint = {
            'seriesId': series.id,
            'x': point.x,
            'y': point.y,
            'screenX': screenPoint.dx, // Store screen coordinates for crosshair rendering
            'screenY': screenPoint.dy,
            if (point.metadata != null) ...point.metadata!,
          };
        }
      }
    }

    return nearestPoint;
  }

  /// Transforms a data point to screen coordinates.
  ///
  /// Uses the same transformation logic as _BravenChartPainter._dataToPixel.
  Offset _dataToScreenPoint(ChartDataPoint point, Rect chartRect, _DataBounds bounds) {
    final xRange = bounds.maxX - bounds.minX;
    final yRange = bounds.maxY - bounds.minY;

    final xPercent = xRange == 0 ? 0.5 : (point.x - bounds.minX) / xRange;
    final yPercent = yRange == 0 ? 0.5 : (point.y - bounds.minY) / yRange;

    final pixelX = chartRect.left + (xPercent * chartRect.width);
    final pixelY = chartRect.bottom - (yPercent * chartRect.height);

    return Offset(pixelX, pixelY);
  }

  /// Calculates the chart rectangle within the widget.
  ///
  /// Same logic as _BravenChartPainter.paint, accounting for margins.
  Rect _calculateChartRect(Size size) {
    // Use same padding as painter (40.0 for axes)
    const padding = 40.0;
    return Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );
  }

  /// Calculates data bounds for all series.
  ///
  /// Same logic as _BravenChartPainter._calculateDataBounds - MUST include zoom/pan!
  _DataBounds _calculateDataBounds(List<ChartSeries> series, {Rect? chartRect}) {
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final s in series) {
      for (final point in s.points) {
        if (point.x < minX) minX = point.x;
        if (point.x > maxX) maxX = point.x;
        if (point.y < minY) minY = point.y;
        if (point.y > maxY) maxY = point.y;
      }
    }

    // Ensure valid bounds even for empty or single-point datasets
    if (minX == double.infinity) minX = 0;
    if (maxX == double.negativeInfinity) maxX = 1;
    if (minY == double.infinity) minY = 0;
    if (maxY == double.negativeInfinity) maxY = 1;

    // CRITICAL: Store data range BEFORE padding for zoom center calculation
    final dataMinX = minX;
    final dataMaxX = maxX;
    final dataMinY = minY;
    final dataMaxY = maxY;

    // Add padding to Y range (for visual spacing, but NOT for zoom center)
    final yRange = maxY - minY;
    minY -= yRange * 0.1;
    maxY += yRange * 0.1;

    // Apply zoom/pan transformation if enabled
    final zoomPanState = _interactionState.zoomPanState;
    final zoomX = zoomPanState.zoomLevelX;
    final zoomY = zoomPanState.zoomLevelY;
    final panX = zoomPanState.panOffset.dx;
    final panY = zoomPanState.panOffset.dy;

    // Only apply zoom/pan if not at default state (zoom != 1.0 or pan != 0)
    if (zoomX != 1.0 || zoomY != 1.0 || panX != 0.0 || panY != 0.0) {
      // CRITICAL FIX: Calculate center from ORIGINAL data range, NOT padded range
      final centerX = (dataMinX + dataMaxX) / 2;
      final centerY = (dataMinY + dataMaxY) / 2;

      // CRITICAL FIX: Calculate new range based on ORIGINAL data range (not padded)
      final dataRangeX = dataMaxX - dataMinX;
      final dataRangeY = dataMaxY - dataMinY;
      final rangeX = dataRangeX / zoomX;
      final rangeY = dataRangeY / zoomY;

      // CRITICAL FIX: Convert pan offset from pixel units to data units
      // Use provided chartRect if available, otherwise calculate it (fallback for compatibility)
      final rect = chartRect ?? _calculateChartRect(context.size!);
      final panDataX = -panX * (dataRangeX / rect.width);
      final panDataY = panY * (dataRangeY / rect.height); // Invert Y for screen coordinates

      // Calculate visible bounds (zoom is applied to data range, pan in data units)
      minX = centerX - rangeX / 2 + panDataX;
      maxX = centerX + rangeX / 2 + panDataX;
      minY = centerY - rangeY / 2 + panDataY;
      maxY = centerY + rangeY / 2 + panDataY;
    }

    return _DataBounds(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
    );
  }

  /// Builds the tooltip overlay widget with smart positioning.
  ///
  /// CRITICAL: Recalculates the tooltip position on EVERY BUILD to track marker through zoom/pan.
  /// Uses _cachedChartRect which is set in LayoutBuilder during render, so size is always available.
  /// The marker's screen position changes when zoom/pan state changes, so we must recalculate
  /// the tooltip position on every build using:
  /// 1. Marker's data coordinates (from tooltipDataPoint)
  /// 2. Current zoom/pan state (which affects coordinate transformation)
  /// 3. Transform to screen coordinates using _dataToScreenPoint()
  /// 4. Apply offset to keep tooltip visible near marker
  Widget? _buildTooltipOverlay() {
    final config = widget.interactionConfig?.tooltip;
    if (config == null || !config.enabled || !_interactionState.isTooltipVisible) {
      return null;
    }

    final dataPoint = _interactionState.tooltipDataPoint;
    if (dataPoint == null) {
      return null;
    }

    // Use the cached chart rect (set in LayoutBuilder during render)
    if (_cachedChartRect == null) {
      return null; // Chart rect not available yet
    }

    // CRITICAL: Recalculate marker screen position on every build to track zoom/pan
    // Get marker data coordinates
    final markerX = dataPoint['x'] as double?;
    final markerY = dataPoint['y'] as double?;

    if (markerX == null || markerY == null) {
      return null;
    }

    // Calculate current data bounds (includes zoom/pan transforms)
    final allSeries = _getAllSeries();
    if (allSeries.isEmpty) return null;

    final bounds = _calculateDataBounds(allSeries, chartRect: _cachedChartRect);

    // Transform marker from data coordinates to screen coordinates
    // _dataToScreenPoint already returns Stack-local coordinates (it adds chartRect.left/bottom internally)
    final markerDataPoint = ChartDataPoint(x: markerX, y: markerY);
    final markerScreenPos = _dataToScreenPoint(markerDataPoint, _cachedChartRect!, bounds);

    // Use custom builder if provided, otherwise default builder
    Widget tooltipContent;
    if (config.customBuilder != null) {
      tooltipContent = config.customBuilder!(context, dataPoint);
    } else {
      // Default tooltip builder
      tooltipContent = _buildDefaultTooltip(dataPoint, config);
    }

    // Store tooltip style info for use in arrow builder
    final tooltipStyle = (
      backgroundColor: config.style.backgroundColor,
      borderColor: config.style.borderColor,
      borderWidth: config.style.borderWidth,
      borderRadius: config.style.borderRadius,
      padding: config.style.padding,
      shadowColor: config.style.shadowColor,
      shadowBlurRadius: config.style.shadowBlurRadius,
    );

    // Calculate tooltip position based on preferredPosition
    // Estimate tooltip size for positioning (these are used for centering calculations)
    // The actual widget size may differ, but these estimates help with initial positioning
    const estimatedWidth = 220.0; // ~280px with content padding
    const estimatedHeight = 120.0;

    final tooltipPosition = _calculateTooltipPosition(
      markerScreenPos,
      config.preferredPosition,
      config.offsetFromPoint,
      estimatedWidth,
      estimatedHeight,
      _cachedChartRect!,
    );

    print(
        '🎯 TOOLTIP POSITIONED: position=${config.preferredPosition}, markerPos=$markerScreenPos, tooltipPos=$tooltipPosition, offset=${config.offsetFromPoint}');

    // Build tooltip with arrow pointer (integrated into border)
    final tooltipWithArrow = _buildTooltipWithArrow(
      tooltipContent,
      tooltipStyle,
      config.preferredPosition,
    );

    return Positioned(
      left: tooltipPosition.dx,
      top: tooltipPosition.dy,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _interactionState.isTooltipVisible ? 1.0 : 0.0,
          duration: config.showDelay,
          child: tooltipWithArrow,
        ),
      ),
    );
  }

  /// Calculates the optimal position for a tooltip based on preferredPosition.
  ///
  /// Uses arrow positioning with fixed offset from corner:
  /// - Arrow is positioned at a predictable offset from the Positioned corner
  /// - This offset is then aligned with the marker for perfect arrow-to-marker connection
  /// - TOP: arrow is at arrowOffsetX from left, positioned above marker
  /// - BOTTOM: arrow is at arrowOffsetX from left, positioned below marker
  /// - LEFT: arrow is at arrowOffsetY from top, positioned left of marker
  /// - RIGHT: arrow is at arrowOffsetY from top, positioned right of marker
  Offset _calculateTooltipPosition(
    Offset markerPos,
    TooltipPosition preferredPosition,
    double offset,
    double tooltipWidth,
    double tooltipHeight,
    Rect chartRect,
  ) {
    // Define minimum margin to chart edges
    const edgeMargin = 8.0;
    const arrowSize = 10.0;

    // Arrow offset from the Positioned corner (for good UX spacing)
    // This is where the arrow will appear relative to the top-left corner
    const arrowOffsetX = 6.0; // Horizontal offset from left edge
    const arrowOffsetY = 6.0; // Vertical offset from top edge

    // Available space calculations
    final totalHeight = tooltipHeight + arrowSize;
    final totalWidth = tooltipWidth + arrowSize;

    final spaceAbove = markerPos.dy - chartRect.top - edgeMargin;
    final spaceBelow = chartRect.bottom - markerPos.dy - edgeMargin;
    final spaceLeft = markerPos.dx - chartRect.left - edgeMargin;
    final spaceRight = chartRect.right - markerPos.dx - edgeMargin;

    print('📏 POSITIONING DEBUG: position=$preferredPosition, marker=$markerPos, offset=$offset');
    print('📏 SPACE: above=$spaceAbove, below=$spaceBelow, left=$spaceLeft, right=$spaceRight');

    switch (preferredPosition) {
      case TooltipPosition.auto:
        // Auto-position: try preferred order, fall back to best fit
        if (spaceAbove >= totalHeight) {
          // TOP: arrow offset X from left, positioned above marker
          final result = Offset(
            markerPos.dx - arrowOffsetX,
            markerPos.dy - totalHeight - offset,
          );
          print('✓ AUTO: chose TOP, result=$result, arrowAt=${markerPos.dx}');
          return result;
        } else if (spaceBelow >= totalHeight) {
          // BOTTOM: arrow offset X from left, positioned below marker
          final result = Offset(
            markerPos.dx - arrowOffsetX,
            markerPos.dy + offset,
          );
          print('✓ AUTO: chose BOTTOM, result=$result, arrowAt=${markerPos.dx}');
          return result;
        } else if (spaceRight >= totalWidth) {
          // RIGHT: arrow offset Y from top, positioned right of marker
          final result = Offset(
            markerPos.dx + offset,
            markerPos.dy - arrowOffsetY,
          );
          print('✓ AUTO: chose RIGHT, result=$result, arrowAt=${markerPos.dy}');
          return result;
        } else if (spaceLeft >= totalWidth) {
          // LEFT: arrow offset Y from top, positioned left of marker
          final result = Offset(
            markerPos.dx - totalWidth - offset,
            markerPos.dy - arrowOffsetY,
          );
          print('✓ AUTO: chose LEFT, result=$result, arrowAt=${markerPos.dy}');
          return result;
        } else {
          // Fallback: position to the bottom-right with arrow offset
          final result = Offset(
            markerPos.dx - arrowOffsetX,
            markerPos.dy + offset,
          );
          print('✓ AUTO: FALLBACK, result=$result');
          return result;
        }

      case TooltipPosition.top:
        // Arrow is at arrowOffsetX from left, tooltip positioned above marker
        // So: Positioned.left = markerPos.dx - arrowOffsetX
        // This makes arrow tip align with marker
        final result = Offset(
          markerPos.dx - arrowOffsetX,
          markerPos.dy - totalHeight - offset,
        );
        print('✓ TOP: result=$result, arrowAt=${markerPos.dx}');
        return result;

      case TooltipPosition.bottom:
        // Arrow is at arrowOffsetX from left, tooltip positioned below marker
        final result = Offset(
          markerPos.dx - arrowOffsetX,
          markerPos.dy + offset,
        );
        print('✓ BOTTOM: result=$result, arrowAt=${markerPos.dx}');
        return result;

      case TooltipPosition.left:
        // Arrow is at arrowOffsetY from top, tooltip positioned left of marker
        final result = Offset(
          markerPos.dx - totalWidth - offset,
          markerPos.dy - arrowOffsetY,
        );
        print('✓ LEFT: result=$result, arrowAt=${markerPos.dy}');
        return result;

      case TooltipPosition.right:
        // Arrow is at arrowOffsetY from top, tooltip positioned right of marker
        final result = Offset(
          markerPos.dx + offset,
          markerPos.dy - arrowOffsetY,
        );
        print('✓ RIGHT: result=$result, arrowAt=${markerPos.dy}');
        return result;
    }
  }

  /// Builds tooltip with integrated arrow as part of continuous border.
  ///
  /// The arrow is cut INTO the tooltip border, not added as a separate element.
  /// Arrow position based on preferredPosition:
  /// - TOP: arrow notch on top edge pointing down to marker
  /// - BOTTOM: arrow notch on bottom edge pointing up to marker
  /// - LEFT: arrow notch on left edge pointing right to marker
  /// - RIGHT: arrow notch on right edge pointing left to marker
  /// - AUTO: returns tooltip without arrow
  Widget _buildTooltipWithArrow(
    Widget tooltipContent,
    ({
      Color backgroundColor,
      Color borderColor,
      double borderWidth,
      double borderRadius,
      double padding,
      double shadowBlurRadius,
      Color shadowColor,
    }) tooltipStyle,
    TooltipPosition position,
  ) {
    // Build shadow if needed
    final boxShadow = tooltipStyle.shadowBlurRadius > 0
        ? [
            BoxShadow(
              color: tooltipStyle.shadowColor,
              blurRadius: tooltipStyle.shadowBlurRadius,
              offset: Offset(0, tooltipStyle.shadowBlurRadius / 2),
            ),
          ]
        : null;

    switch (position) {
      case TooltipPosition.top:
        // Tooltip is ABOVE marker, so arrow should be on BOTTOM pointing DOWN
        return Container(
          decoration: ShapeDecoration(
            color: Colors.transparent,
            shape: _TooltipShapeBorder(
              arrowPosition: _ArrowPosition.bottom,
              backgroundColor: tooltipStyle.backgroundColor,
              borderColor: tooltipStyle.borderColor,
              borderWidth: tooltipStyle.borderWidth,
              borderRadius: BorderRadius.circular(tooltipStyle.borderRadius),
              arrowSize: 10.0,
              boxShadow: boxShadow,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Padding(
              padding: EdgeInsets.all(tooltipStyle.padding),
              child: tooltipContent,
            ),
          ),
        );

      case TooltipPosition.bottom:
        // Tooltip is BELOW marker, so arrow should be on TOP pointing UP
        return Container(
          decoration: ShapeDecoration(
            color: Colors.transparent,
            shape: _TooltipShapeBorder(
              arrowPosition: _ArrowPosition.top,
              backgroundColor: tooltipStyle.backgroundColor,
              borderColor: tooltipStyle.borderColor,
              borderWidth: tooltipStyle.borderWidth,
              borderRadius: BorderRadius.circular(tooltipStyle.borderRadius),
              arrowSize: 10.0,
              boxShadow: boxShadow,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Padding(
              padding: EdgeInsets.all(tooltipStyle.padding),
              child: tooltipContent,
            ),
          ),
        );

      case TooltipPosition.left:
        // Tooltip is LEFT of marker, so arrow should be on RIGHT pointing RIGHT
        return Container(
          decoration: ShapeDecoration(
            color: Colors.transparent,
            shape: _TooltipShapeBorder(
              arrowPosition: _ArrowPosition.right,
              backgroundColor: tooltipStyle.backgroundColor,
              borderColor: tooltipStyle.borderColor,
              borderWidth: tooltipStyle.borderWidth,
              borderRadius: BorderRadius.circular(tooltipStyle.borderRadius),
              arrowSize: 10.0,
              boxShadow: boxShadow,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Padding(
              padding: EdgeInsets.all(tooltipStyle.padding),
              child: tooltipContent,
            ),
          ),
        );

      case TooltipPosition.right:
        // Tooltip is RIGHT of marker, so arrow should be on LEFT pointing LEFT
        return Container(
          decoration: ShapeDecoration(
            color: Colors.transparent,
            shape: _TooltipShapeBorder(
              arrowPosition: _ArrowPosition.left,
              backgroundColor: tooltipStyle.backgroundColor,
              borderColor: tooltipStyle.borderColor,
              borderWidth: tooltipStyle.borderWidth,
              borderRadius: BorderRadius.circular(tooltipStyle.borderRadius),
              arrowSize: 10.0,
              boxShadow: boxShadow,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Padding(
              padding: EdgeInsets.all(tooltipStyle.padding),
              child: tooltipContent,
            ),
          ),
        );

      case TooltipPosition.auto:
        // For auto, no arrow - just return content with default styling
        return Container(
          padding: EdgeInsets.all(tooltipStyle.padding),
          decoration: BoxDecoration(
            color: tooltipStyle.backgroundColor,
            border: Border.all(
              color: tooltipStyle.borderColor,
              width: tooltipStyle.borderWidth,
            ),
            borderRadius: BorderRadius.circular(tooltipStyle.borderRadius),
            boxShadow: boxShadow,
          ),
          child: tooltipContent,
        );
    }
  }

  /// Builds the default tooltip content.
  Widget _buildDefaultTooltip(Map<String, dynamic> dataPoint, TooltipConfig config) {
    final x = dataPoint['x'];
    final y = dataPoint['y'];

    final textStyle = TextStyle(
      color: config.style.textColor,
      fontSize: config.style.fontSize,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'X: ${x is num ? x.toStringAsFixed(2) : x.toString()}',
          style: textStyle,
        ),
        const SizedBox(height: 4),
        Text(
          'Y: ${y is num ? y.toStringAsFixed(2) : y.toString()}',
          style: textStyle,
        ),
        // Show additional properties if present
        ...dataPoint.entries.where((e) => e.key != 'x' && e.key != 'y').map((e) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${e.key}: ${e.value}',
                style: textStyle.copyWith(fontSize: config.style.fontSize * 0.83),
              ),
            )),
      ],
    );
  }

  // ==================== HELPER METHODS (continued) ====================

  /// Gets all series from widget and controller combined.
  List<ChartSeries> _getAllSeries() {
    final result = <ChartSeries>[...widget.series];

    // Add controller series if available
    final controller = _getController();
    if (controller != null) {
      final controllerSeries = controller.getAllSeries();
      for (final entry in controllerSeries.entries) {
        // Check if series already exists
        final existingIndex = result.indexWhere((s) => s.id == entry.key);
        if (existingIndex >= 0) {
          // Replace with controller version (controller has priority)
          result[existingIndex] = ChartSeries(
            id: entry.key,
            points: entry.value,
          );
        } else {
          // Add new series
          result.add(ChartSeries(
            id: entry.key,
            points: entry.value,
          ));
        }
      }
    }

    return result;
  }

  /// Gets all annotations from widget and controller combined.
  List<ChartAnnotation> _getAllAnnotations() {
    final result = <ChartAnnotation>[...widget.annotations];

    // Add controller annotations if available
    final controller = _getController();
    if (controller != null) {
      result.addAll(controller.getAllAnnotations());
    }

    // Sort by z-index (lower z-index renders first)
    result.sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return result;
  }

  /// Invokes the onViewportChanged callback with current visible bounds.
  ///
  /// Calculates the visible data range based on current zoom/pan state
  /// and invokes the callback if it exists.
  void _invokeViewportCallback() {
    if (widget.interactionConfig?.onViewportChanged == null) return;

    // Calculate visible data bounds from zoom/pan state
    final zoomPanState = _interactionState.zoomPanState;
    final allSeries = _getAllSeries();
    if (allSeries.isEmpty) return;

    // Get the original data bounds
    final dataBounds = _calculateDataBounds(allSeries);

    // Calculate visible range accounting for zoom and pan
    // Visible width = original width / zoom level
    final visibleWidth = (dataBounds.maxX - dataBounds.minX) / zoomPanState.zoomLevelX;
    final visibleHeight = (dataBounds.maxY - dataBounds.minY) / zoomPanState.zoomLevelY;

    // Pan offset shifts the visible region
    // Negative pan = showing right/bottom data (shifted left/up visually)
    final panOffsetX = -zoomPanState.panOffset.dx / zoomPanState.zoomLevelX;
    final panOffsetY = -zoomPanState.panOffset.dy / zoomPanState.zoomLevelY;

    final visibleBounds = {
      'minX': dataBounds.minX + panOffsetX,
      'maxX': dataBounds.minX + panOffsetX + visibleWidth,
      'minY': dataBounds.minY + panOffsetY,
      'maxY': dataBounds.minY + panOffsetY + visibleHeight,
    };

    widget.interactionConfig!.onViewportChanged!(visibleBounds);
  }
}

// ==================== CUSTOM PAINTER ====================

/// Custom painter for rendering BravenChart.
///
/// This painter integrates with Layer 4 (Chart Types) to render
/// the appropriate chart type with proper theming and axes.
class _BravenChartPainter extends CustomPainter {
  _BravenChartPainter({
    required this.chartType,
    required this.series,
    required this.theme,
    required this.xAxis,
    required this.yAxis,
    required this.annotations,
    this.zoomPanState,
  });

  final ChartType chartType;
  final List<ChartSeries> series;
  final ChartTheme theme;
  final AxisConfig xAxis;
  final AxisConfig yAxis;
  final List<ChartAnnotation> annotations;
  final ZoomPanState? zoomPanState;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;

    // Draw background
    final backgroundPaint = Paint()
      ..color = theme.backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Draw border if specified
    if (theme.borderWidth > 0) {
      final borderPaint = Paint()
        ..color = theme.borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = theme.borderWidth;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height).deflate(theme.borderWidth / 2),
        borderPaint,
      );
    }

    // Calculate chart area (leave room for axes)
    const padding = 40.0;
    final chartRect = Rect.fromLTWH(padding, padding, size.width - padding * 2, size.height - padding * 2);

    // Calculate data bounds
    final bounds = _calculateDataBounds(chartRect: chartRect);
    if (bounds == null) return;

    // Draw grid
    _drawGrid(canvas, chartRect, bounds);

    // Draw series based on chart type
    switch (chartType) {
      case ChartType.line:
        _drawLineSeries(canvas, chartRect, bounds);
        break;
      case ChartType.area:
        _drawAreaSeries(canvas, chartRect, bounds);
        break;
      case ChartType.bar:
        _drawBarSeries(canvas, chartRect, bounds);
        break;
      case ChartType.scatter:
        _drawScatterSeries(canvas, chartRect, bounds);
        break;
    }

    // Draw axes
    _drawAxes(canvas, size, chartRect, bounds);
  }

  _DataBounds? _calculateDataBounds({Rect? chartRect}) {
    if (series.isEmpty) return null;

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final s in series) {
      for (final point in s.points) {
        if (point.x < minX) minX = point.x;
        if (point.x > maxX) maxX = point.x;
        if (point.y < minY) minY = point.y;
        if (point.y > maxY) maxY = point.y;
      }
    }

    // CRITICAL: Store data range BEFORE padding for zoom center calculation
    final dataMinX = minX;
    final dataMaxX = maxX;
    final dataMinY = minY;
    final dataMaxY = maxY;

    // Add padding to Y range (for visual spacing, but NOT for zoom center)
    final yRange = maxY - minY;
    minY -= yRange * 0.1;
    maxY += yRange * 0.1;

    // Apply zoom/pan transformation if enabled
    if (zoomPanState != null) {
      final zoomX = zoomPanState!.zoomLevelX;
      final zoomY = zoomPanState!.zoomLevelY;
      final panX = zoomPanState!.panOffset.dx;
      final panY = zoomPanState!.panOffset.dy;

      // Only apply zoom/pan if not at default state (zoom != 1.0 or pan != 0)
      if (zoomX != 1.0 || zoomY != 1.0 || panX != 0.0 || panY != 0.0) {
        // CRITICAL FIX: Calculate center from ORIGINAL data range, NOT padded range
        // This ensures zoom centers on actual data, not the padded viewport
        final centerX = (dataMinX + dataMaxX) / 2;
        final centerY = (dataMinY + dataMaxY) / 2;

        // CRITICAL FIX: Calculate new range based on ORIGINAL data range (not padded)
        // This ensures zoom is relative to actual data, keeping it centered and visible
        final dataRangeX = dataMaxX - dataMinX;
        final dataRangeY = dataMaxY - dataMinY;
        final rangeX = dataRangeX / zoomX;
        final rangeY = dataRangeY / zoomY;

        // CRITICAL FIX #4: Convert pan offset from pixel units to data units
        // panOffset is in screen pixels, we need to convert to data coordinates
        // Conversion: panData = panPixels * (dataRange / screenSize)
        double panDataX = 0.0;
        double panDataY = 0.0;
        if (chartRect != null) {
          panDataX = -panX * (dataRangeX / chartRect.width);
          panDataY = panY * (dataRangeY / chartRect.height); // Invert Y for screen coordinates
        }

        // Calculate visible bounds (zoom is applied to data range, pan in data units)
        minX = centerX - rangeX / 2 + panDataX;
        maxX = centerX + rangeX / 2 + panDataX;
        minY = centerY - rangeY / 2 + panDataY;
        maxY = centerY + rangeY / 2 + panDataY;
      }
    }

    return _DataBounds(minX: minX, maxX: maxX, minY: minY, maxY: maxY);
  }

  void _drawGrid(Canvas canvas, Rect chartRect, _DataBounds bounds) {
    if (!xAxis.showGrid && !yAxis.showGrid) return;

    final gridPaint = Paint()
      ..color = theme.gridStyle.majorColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = theme.gridStyle.majorWidth;

    // Calculate nice round intervals for grid lines based on visible data range
    final xRange = bounds.maxX - bounds.minX;
    final yRange = bounds.maxY - bounds.minY;

    // Use a simple algorithm to get nice intervals (can be enhanced with smarter tick generation)
    final xInterval = _calculateNiceInterval(xRange);
    final yInterval = _calculateNiceInterval(yRange);

    if (yAxis.showGrid) {
      // Find the first grid line position (round down to nearest interval)
      final firstY = (bounds.minY / yInterval).floor() * yInterval;

      // Draw horizontal grid lines at data value intervals
      var currentY = firstY;
      while (currentY <= bounds.maxY) {
        // Convert data value to pixel position
        final yPercent = (currentY - bounds.minY) / yRange;
        final y = chartRect.bottom - (yPercent * chartRect.height);

        // Only draw if within chart bounds
        if (y >= chartRect.top && y <= chartRect.bottom) {
          canvas.drawLine(Offset(chartRect.left, y), Offset(chartRect.right, y), gridPaint);
        }

        currentY += yInterval;
      }
    }

    if (xAxis.showGrid) {
      // Find the first grid line position (round down to nearest interval)
      final firstX = (bounds.minX / xInterval).floor() * xInterval;

      // Draw vertical grid lines at data value intervals
      var currentX = firstX;
      while (currentX <= bounds.maxX) {
        // Convert data value to pixel position
        final xPercent = (currentX - bounds.minX) / xRange;
        final x = chartRect.left + (xPercent * chartRect.width);

        // Only draw if within chart bounds
        if (x >= chartRect.left && x <= chartRect.right) {
          canvas.drawLine(Offset(x, chartRect.top), Offset(x, chartRect.bottom), gridPaint);
        }

        currentX += xInterval;
      }
    }
  }

  /// Calculates a "nice" interval for grid lines based on the data range.
  ///
  /// This uses a simple algorithm to find intervals like 1, 2, 5, 10, 20, 50, 100, etc.
  /// that result in approximately 5-10 grid lines.
  double _calculateNiceInterval(double range) {
    if (range == 0) return 1.0;

    // Target approximately 5-10 grid lines
    final roughInterval = range / 7;

    // Find the magnitude (power of 10)
    final magnitude = pow(10, (log(roughInterval) / ln10).floor()).toDouble();

    // Normalize to range [1, 10)
    final normalized = roughInterval / magnitude;

    // Round to nice numbers: 1, 2, 5, or 10
    double niceNormalized;
    if (normalized < 1.5) {
      niceNormalized = 1.0;
    } else if (normalized < 3.5) {
      niceNormalized = 2.0;
    } else if (normalized < 7.5) {
      niceNormalized = 5.0;
    } else {
      niceNormalized = 10.0;
    }

    return niceNormalized * magnitude;
  }

  void _drawLineSeries(Canvas canvas, Rect chartRect, _DataBounds bounds) {
    final colors = theme.seriesTheme.colors;

    // CRITICAL FIX: Use Canvas clipping instead of point culling to maintain line continuity
    // Clipping preserves the line shape by rendering ALL segments, but only displaying
    // what's inside the viewport. Point culling would skip segments, distorting the curve.
    canvas.save();
    canvas.clipRect(chartRect);

    for (var i = 0; i < series.length; i++) {
      final s = series[i];
      if (s.points.isEmpty) continue;

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      bool first = true;

      // CRITICAL FIX: Render ALL points to maintain line continuity
      // Canvas clipping will automatically crop the visible region
      // This ensures line segments entering/exiting the viewport are drawn correctly
      for (final point in s.points) {
        final offset = _dataToPixel(point, chartRect, bounds);
        if (first) {
          path.moveTo(offset.dx, offset.dy);
          first = false;
        } else {
          path.lineTo(offset.dx, offset.dy);
        }
      }

      canvas.drawPath(path, paint);
    }

    canvas.restore(); // Remove clipping

    // Draw markers (using same clipping as lines for consistency with zoom/pan)
    // Canvas clipping handles viewport culling automatically
    canvas.save();
    canvas.clipRect(chartRect);

    for (var i = 0; i < series.length; i++) {
      final s = series[i];
      final markerPaint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      for (var j = 0; j < s.points.length; j++) {
        final point = s.points[j];
        final offset = _dataToPixel(point, chartRect, bounds);
        canvas.drawCircle(offset, 4, markerPaint);
      }
    }

    canvas.restore(); // Remove clipping
  }

  void _drawAreaSeries(Canvas canvas, Rect chartRect, _DataBounds bounds) {
    final colors = theme.seriesTheme.colors;

    // CRITICAL FIX: Use Canvas clipping instead of point filtering to maintain area continuity
    canvas.save();
    canvas.clipRect(chartRect);

    for (var i = 0; i < series.length; i++) {
      final s = series[i];
      if (s.points.isEmpty) continue;

      final color = colors[i % colors.length];
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      final path = Path();

      // CRITICAL FIX: Process ALL points to maintain area shape
      // Canvas clipping will automatically crop the visible region
      final firstPoint = _dataToPixel(s.points.first, chartRect, bounds);
      path.moveTo(firstPoint.dx, chartRect.bottom);
      path.lineTo(firstPoint.dx, firstPoint.dy);

      for (final point in s.points) {
        final offset = _dataToPixel(point, chartRect, bounds);
        path.lineTo(offset.dx, offset.dy);
      }

      final lastPoint = _dataToPixel(s.points.last, chartRect, bounds);
      path.lineTo(lastPoint.dx, chartRect.bottom);
      path.close();

      canvas.drawPath(path, fillPaint);

      // Draw line on top
      final linePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final linePath = Path();
      bool first = true;

      // CRITICAL FIX: Process ALL points for the outline too
      for (final point in s.points) {
        final offset = _dataToPixel(point, chartRect, bounds);
        if (first) {
          linePath.moveTo(offset.dx, offset.dy);
          first = false;
        } else {
          linePath.lineTo(offset.dx, offset.dy);
        }
      }

      canvas.drawPath(linePath, linePaint);
    }

    canvas.restore(); // Remove clipping
  }

  void _drawBarSeries(Canvas canvas, Rect chartRect, _DataBounds bounds) {
    final colors = theme.seriesTheme.colors;
    final barCount = series.isEmpty ? 0 : series.first.points.length;
    final seriesCount = series.length;

    if (barCount == 0) return;

    final barGroupWidth = chartRect.width / barCount;
    final barWidth = barGroupWidth / (seriesCount + 1);

    // Use canvas clipping to handle viewport bounds automatically with zoom/pan
    canvas.save();
    canvas.clipRect(chartRect);

    for (var seriesIndex = 0; seriesIndex < series.length; seriesIndex++) {
      final s = series[seriesIndex];
      final color = colors[seriesIndex % colors.length];
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      for (var pointIndex = 0; pointIndex < s.points.length; pointIndex++) {
        final point = s.points[pointIndex];

        final baseX = chartRect.left + (barGroupWidth * pointIndex);
        final barX = baseX + (barWidth * seriesIndex) + (barWidth / 2);

        final topY = _dataToPixel(point, chartRect, bounds).dy;
        final bottomY = chartRect.bottom;
        final barHeight = bottomY - topY;

        final rect = Rect.fromLTWH(barX, topY, barWidth * 0.8, barHeight);
        canvas.drawRect(rect, paint);
      }
    }

    canvas.restore(); // Remove clipping
  }

  void _drawScatterSeries(Canvas canvas, Rect chartRect, _DataBounds bounds) {
    final colors = theme.seriesTheme.colors;

    // Use canvas clipping to handle viewport bounds automatically with zoom/pan
    canvas.save();
    canvas.clipRect(chartRect);

    for (var i = 0; i < series.length; i++) {
      final s = series[i];
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      for (final point in s.points) {
        final offset = _dataToPixel(point, chartRect, bounds);
        canvas.drawCircle(offset, 5, paint);
      }
    }

    canvas.restore(); // Remove clipping
  }

  void _drawAxes(Canvas canvas, Size size, Rect chartRect, _DataBounds bounds) {
    final axisPaint = Paint()
      ..color = theme.axisStyle.lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = theme.axisStyle.lineWidth;

    // Calculate nice intervals for axis labels (same as grid)
    final xRange = bounds.maxX - bounds.minX;
    final yRange = bounds.maxY - bounds.minY;
    final xInterval = _calculateNiceInterval(xRange);
    final yInterval = _calculateNiceInterval(yRange);

    if (xAxis.showAxis) {
      // Draw X-axis line
      canvas.drawLine(Offset(chartRect.left, chartRect.bottom), Offset(chartRect.right, chartRect.bottom), axisPaint);

      // Draw X-axis labels at grid intervals
      if (xAxis.showLabels) {
        final firstX = (bounds.minX / xInterval).floor() * xInterval;
        var currentX = firstX;

        while (currentX <= bounds.maxX) {
          final xPercent = (currentX - bounds.minX) / xRange;
          final x = chartRect.left + (xPercent * chartRect.width);

          if (x >= chartRect.left && x <= chartRect.right) {
            // Format label (remove unnecessary decimals)
            final label = _formatAxisLabel(currentX);

            final textSpan = TextSpan(
              text: label,
              style: theme.axisStyle.labelStyle,
            );

            final textPainter = TextPainter(
              text: textSpan,
              textDirection: TextDirection.ltr,
            );

            textPainter.layout();
            textPainter.paint(
              canvas,
              Offset(x - textPainter.width / 2, chartRect.bottom + 5),
            );
          }

          currentX += xInterval;
        }
      }
    }

    if (yAxis.showAxis) {
      // Draw Y-axis line
      canvas.drawLine(Offset(chartRect.left, chartRect.top), Offset(chartRect.left, chartRect.bottom), axisPaint);

      // Draw Y-axis labels at grid intervals
      if (yAxis.showLabels) {
        final firstY = (bounds.minY / yInterval).floor() * yInterval;
        var currentY = firstY;

        while (currentY <= bounds.maxY) {
          final yPercent = (currentY - bounds.minY) / yRange;
          final y = chartRect.bottom - (yPercent * chartRect.height);

          if (y >= chartRect.top && y <= chartRect.bottom) {
            // Format label (remove unnecessary decimals)
            final label = _formatAxisLabel(currentY);

            final textSpan = TextSpan(
              text: label,
              style: theme.axisStyle.labelStyle,
            );

            final textPainter = TextPainter(
              text: textSpan,
              textDirection: TextDirection.ltr,
            );

            textPainter.layout();
            textPainter.paint(
              canvas,
              Offset(chartRect.left - textPainter.width - 5, y - textPainter.height / 2),
            );
          }

          currentY += yInterval;
        }
      }
    }
  }

  /// Formats axis labels to remove unnecessary decimal places.
  String _formatAxisLabel(double value) {
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

  Offset _dataToPixel(ChartDataPoint point, Rect chartRect, _DataBounds bounds) {
    final xRange = bounds.maxX - bounds.minX;
    final yRange = bounds.maxY - bounds.minY;

    final xPercent = xRange == 0 ? 0.5 : (point.x - bounds.minX) / xRange;
    final yPercent = yRange == 0 ? 0.5 : (point.y - bounds.minY) / yRange;

    final pixelX = chartRect.left + (xPercent * chartRect.width);
    final pixelY = chartRect.bottom - (yPercent * chartRect.height);

    return Offset(pixelX, pixelY);
  }

  @override
  bool shouldRepaint(_BravenChartPainter oldDelegate) {
    return chartType != oldDelegate.chartType ||
        series != oldDelegate.series ||
        theme != oldDelegate.theme ||
        xAxis != oldDelegate.xAxis ||
        yAxis != oldDelegate.yAxis ||
        annotations != oldDelegate.annotations ||
        zoomPanState != oldDelegate.zoomPanState; // CRITICAL: Repaint on zoom/pan changes
  }
}

// ==================== HELPER CLASSES ====================

/// Helper class to store data bounds for chart rendering
class _DataBounds {
  _DataBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _DataBounds && other.minX == minX && other.maxX == maxX && other.minY == minY && other.maxY == maxY;
  }

  @override
  int get hashCode => Object.hash(minX, maxX, minY, maxY);
}

// ==================== ANNOTATION OVERLAY ====================

/// Widget that renders annotations as an overlay on top of the chart.
///
/// This widget handles rendering all 5 annotation types with z-index ordering
/// and optional interaction support.
class _AnnotationOverlay extends StatelessWidget {
  const _AnnotationOverlay({
    required this.annotations,
    required this.interactiveAnnotations,
    this.onAnnotationTap,
    this.onAnnotationDragged,
  });

  final List<ChartAnnotation> annotations;
  final bool interactiveAnnotations;
  final void Function(ChartAnnotation annotation)? onAnnotationTap;
  final void Function(ChartAnnotation annotation, Offset newPosition)? onAnnotationDragged;

  @override
  Widget build(BuildContext context) {
    // Annotations are already sorted by z-index in _getAllAnnotations()
    return Stack(
      children: annotations.map((annotation) {
        return _buildAnnotationWidget(annotation);
      }).toList(),
    );
  }

  /// Builds the appropriate widget for each annotation type.
  Widget _buildAnnotationWidget(ChartAnnotation annotation) {
    // Import the annotation types
    if (annotation is TextAnnotation) {
      return _buildTextAnnotation(annotation);
    } else if (annotation is PointAnnotation) {
      return _buildPointAnnotation(annotation);
    } else if (annotation is RangeAnnotation) {
      return _buildRangeAnnotation(annotation);
    } else if (annotation is ThresholdAnnotation) {
      return _buildThresholdAnnotation(annotation);
    } else if (annotation is TrendAnnotation) {
      return _buildTrendAnnotation(annotation);
    }

    // Unknown annotation type - return empty widget
    return const SizedBox.shrink();
  }

  /// Builds a text annotation widget.
  Widget _buildTextAnnotation(TextAnnotation annotation) {
    final Widget textWidget = Positioned(
      left: annotation.position.dx,
      top: annotation.position.dy,
      child: GestureDetector(
        onTap: interactiveAnnotations && onAnnotationTap != null ? () => onAnnotationTap!(annotation) : null,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: annotation.backgroundColor,
            border: annotation.borderColor != null ? Border.all(color: annotation.borderColor!) : null,
          ),
          child: Text(
            annotation.text,
            style: TextStyle(
              fontSize: annotation.style.fontSize,
              fontWeight: annotation.style.fontWeight,
              color: annotation.style.textColor,
            ),
          ),
        ),
      ),
    );

    return textWidget;
  }

  /// Builds a point annotation widget (marker on specific data point).
  Widget _buildPointAnnotation(PointAnnotation annotation) {
    // Simplified: Just show a marker at the approximate position
    // Full implementation would transform data coordinates to screen coordinates
    return Positioned(
      left: 100, // Placeholder - would use coordinate transformation
      top: 100, // Placeholder - would use coordinate transformation
      child: GestureDetector(
        onTap: interactiveAnnotations && onAnnotationTap != null ? () => onAnnotationTap!(annotation) : null,
        child: CustomPaint(
          size: Size(annotation.markerSize * 2, annotation.markerSize * 2),
          painter: _MarkerPainter(
            shape: annotation.markerShape,
            size: annotation.markerSize,
            color: annotation.markerColor,
          ),
        ),
      ),
    );
  }

  /// Builds a range annotation widget (rectangular region).
  Widget _buildRangeAnnotation(RangeAnnotation annotation) {
    // Simplified: Show a semi-transparent rectangle
    // Full implementation would transform data coordinates to screen coordinates
    return Positioned(
      left: 50, // Placeholder
      top: 50, // Placeholder
      width: 200, // Placeholder
      height: 100, // Placeholder
      child: GestureDetector(
        onTap: interactiveAnnotations && onAnnotationTap != null ? () => onAnnotationTap!(annotation) : null,
        child: Container(
          decoration: BoxDecoration(
            color: annotation.style.backgroundColor ?? Colors.blue.withOpacity(0.2),
            border: Border.all(
              color: annotation.style.borderColor ?? Colors.blue,
              width: annotation.style.borderWidth,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a threshold annotation widget (horizontal or vertical line).
  Widget _buildThresholdAnnotation(ThresholdAnnotation annotation) {
    // Simplified: Show a line across the chart
    // Full implementation would use coordinate transformation
    return Positioned.fill(
      child: GestureDetector(
        onTap: interactiveAnnotations && onAnnotationTap != null ? () => onAnnotationTap!(annotation) : null,
        child: CustomPaint(
          painter: _ThresholdPainter(
            axis: annotation.axis,
            value: annotation.value,
            color: annotation.style.borderColor ?? Colors.red,
            width: annotation.style.borderWidth,
            dashPattern: annotation.dashPattern,
          ),
        ),
      ),
    );
  }

  /// Builds a trend annotation widget (trend line or regression).
  Widget _buildTrendAnnotation(TrendAnnotation annotation) {
    // Simplified: Placeholder for trend line
    // Full implementation would calculate and render the trend
    return Positioned.fill(
      child: GestureDetector(
        onTap: interactiveAnnotations && onAnnotationTap != null ? () => onAnnotationTap!(annotation) : null,
        child: CustomPaint(
          painter: _TrendPainter(
            trendType: annotation.trendType,
            color: annotation.style.borderColor ?? Colors.purple,
            width: annotation.style.borderWidth,
          ),
        ),
      ),
    );
  }
}

// ==================== ANNOTATION PAINTERS ====================

/// Custom painter for marker shapes.
class _MarkerPainter extends CustomPainter {
  _MarkerPainter({
    required this.shape,
    required this.size,
    required this.color,
  });

  final MarkerShape shape;
  final double size;
  final Color color;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);

    switch (shape) {
      case MarkerShape.circle:
        canvas.drawCircle(center, size, paint);
        break;
      case MarkerShape.square:
        canvas.drawRect(
          Rect.fromCenter(center: center, width: size * 2, height: size * 2),
          paint,
        );
        break;
      case MarkerShape.triangle:
        final path = Path()
          ..moveTo(center.dx, center.dy - size)
          ..lineTo(center.dx + size, center.dy + size)
          ..lineTo(center.dx - size, center.dy + size)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case MarkerShape.diamond:
        final path = Path()
          ..moveTo(center.dx, center.dy - size)
          ..lineTo(center.dx + size, center.dy)
          ..lineTo(center.dx, center.dy + size)
          ..lineTo(center.dx - size, center.dy)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case MarkerShape.cross:
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2;
        canvas.drawLine(
          Offset(center.dx - size, center.dy),
          Offset(center.dx + size, center.dy),
          paint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - size),
          Offset(center.dx, center.dy + size),
          paint,
        );
        break;
      case MarkerShape.plus:
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2;
        canvas.drawLine(
          Offset(center.dx - size, center.dy),
          Offset(center.dx + size, center.dy),
          paint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - size),
          Offset(center.dx, center.dy + size),
          paint,
        );
        break;
      case MarkerShape.star:
        // Draw a simple star shape
        final path = Path();
        for (var i = 0; i < 5; i++) {
          final angle = -90 + (i * 144) * 3.14159 / 180;
          final radius = i % 2 == 0 ? size : size / 2;
          final x = center.dx + radius * cos(angle);
          final y = center.dy + radius * sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(_MarkerPainter oldDelegate) {
    return shape != oldDelegate.shape || size != oldDelegate.size || color != oldDelegate.color;
  }
}

/// Custom painter for threshold lines.
class _ThresholdPainter extends CustomPainter {
  _ThresholdPainter({
    required this.axis,
    required this.value,
    required this.color,
    required this.width,
    this.dashPattern,
  });

  final AnnotationAxis axis;
  final double value;
  final Color color;
  final double width;
  final List<double>? dashPattern;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    // Simplified: Draw line at 50% of the canvas
    // Full implementation would use coordinate transformation
    if (axis == AnnotationAxis.y) {
      // Horizontal line
      final y = size.height / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    } else {
      // Vertical line
      final x = size.width / 2;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_ThresholdPainter oldDelegate) {
    return axis != oldDelegate.axis || value != oldDelegate.value || color != oldDelegate.color || width != oldDelegate.width;
  }
}

/// Custom painter for trend lines.
class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.trendType,
    required this.color,
    required this.width,
  });

  final TrendType trendType;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    // Simplified: Draw diagonal line as placeholder
    // Full implementation would calculate actual trend
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, 0),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) {
    return trendType != oldDelegate.trendType || color != oldDelegate.color || width != oldDelegate.width;
  }
}

/// Custom painter for crosshair rendering.
class _CrosshairPainter extends CustomPainter {
  _CrosshairPainter({
    required this.position,
    required this.config,
    this.nearestPoint,
    required this.chartSize,
    this.dataBounds,
    this.chartRect,
  });

  final Offset position;
  final CrosshairConfig config;
  final Offset? nearestPoint;
  final Size chartSize;
  final _DataBounds? dataBounds;
  final Rect? chartRect;

  @override
  void paint(Canvas canvas, Size size) {
    if (!config.enabled) return;

    final paint = Paint()
      ..color = config.style.lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.style.lineWidth
      ..strokeCap = config.style.strokeCap;

    // Draw vertical line for vertical and both modes
    if (config.mode == CrosshairMode.vertical || config.mode == CrosshairMode.both) {
      if (config.style.dashPattern != null && config.style.dashPattern!.isNotEmpty) {
        _drawDashedLine(canvas, Offset(position.dx, 0), Offset(position.dx, size.height), paint, config.style.dashPattern!);
      } else {
        canvas.drawLine(
          Offset(position.dx, 0),
          Offset(position.dx, size.height),
          paint,
        );
      }
    }

    // Draw horizontal line for horizontal and both modes
    if (config.mode == CrosshairMode.horizontal || config.mode == CrosshairMode.both) {
      if (config.style.dashPattern != null && config.style.dashPattern!.isNotEmpty) {
        _drawDashedLine(canvas, Offset(0, position.dy), Offset(size.width, position.dy), paint, config.style.dashPattern!);
      } else {
        canvas.drawLine(
          Offset(0, position.dy),
          Offset(size.width, position.dy),
          paint,
        );
      }
    }

    // Draw snap point highlight if snap is enabled and near a point
    if (config.snapToDataPoint && nearestPoint != null) {
      // Validate nearestPoint coordinates are finite (not NaN or infinity)
      if (nearestPoint!.dx.isFinite && nearestPoint!.dy.isFinite) {
        final highlightPaint = Paint()
          ..color = config.style.lineColor.withOpacity(0.3)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(nearestPoint!, 6.0, highlightPaint);

        final borderPaint = Paint()
          ..color = config.style.lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawCircle(nearestPoint!, 6.0, borderPaint);
      }
    }

    // Draw coordinate labels if enabled
    if (config.showCoordinateLabels) {
      _drawCoordinateLabels(canvas, size);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, List<double> dashPattern) {
    final path = Path();
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);

    var currentDistance = 0.0;
    var patternIndex = 0;
    var isDash = true;

    while (currentDistance < distance) {
      final dashLength = dashPattern[patternIndex % dashPattern.length];
      final nextDistance = (currentDistance + dashLength).clamp(0.0, distance);

      if (isDash) {
        final startRatio = currentDistance / distance;
        final endRatio = nextDistance / distance;
        path.moveTo(
          start.dx + dx * startRatio,
          start.dy + dy * startRatio,
        );
        path.lineTo(
          start.dx + dx * endRatio,
          start.dy + dy * endRatio,
        );
      }

      currentDistance = nextDistance;
      patternIndex++;
      isDash = !isDash;
    }

    canvas.drawPath(path, paint);
  }

  void _drawCoordinateLabels(Canvas canvas, Size size) {
    // Wrap in try-catch to prevent ANY label rendering issues from breaking the entire crosshair
    try {
      // Validate that position coordinates are finite
      if (!position.dx.isFinite || !position.dy.isFinite) {
        return; // Skip label rendering if position is invalid
      }

      // Convert screen coordinates to data coordinates
      double? dataX;
      double? dataY;

      if (dataBounds != null && chartRect != null) {
        // Screen to data transformation (inverse of _dataToPixel)
        final xRange = dataBounds!.maxX - dataBounds!.minX;
        final yRange = dataBounds!.maxY - dataBounds!.minY;

        // Calculate percentage from screen position
        final xPercent = (position.dx - chartRect!.left) / chartRect!.width;
        final yPercent = 1.0 - ((position.dy - chartRect!.top) / chartRect!.height);

        // Convert to data coordinates
        dataX = dataBounds!.minX + (xPercent * xRange);
        dataY = dataBounds!.minY + (yPercent * yRange);
      }

      final textStyle = config.coordinateLabelStyle ??
          TextStyle(
            color: config.style.labelTextColor,
            fontSize: 10,
            backgroundColor: config.style.labelBackgroundColor.withOpacity(0.8),
          );

      // X coordinate label (bottom of vertical line)
      if (config.mode == CrosshairMode.vertical || config.mode == CrosshairMode.both) {
        // Use data X value if available, otherwise fall back to screen position
        final displayValue = dataX != null ? _formatDataValue(dataX) : position.dx.toStringAsFixed(0);

        final xTextPainter = TextPainter(
          text: TextSpan(
            text: 'X: $displayValue',
            style: textStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        // Calculate label position with bounds checking
        var xLabelX = position.dx - xTextPainter.width / 2;
        final xLabelY = size.height - xTextPainter.height - 4;

        // Clamp X position to keep label within canvas bounds
        xLabelX = xLabelX.clamp(config.style.labelPadding, size.width - xTextPainter.width - config.style.labelPadding);

        // Only draw if Y position is valid and all values are finite
        if (xLabelY >= 0 && xLabelY + xTextPainter.height <= size.height && xLabelX.isFinite && xLabelY.isFinite) {
          final xLabelOffset = Offset(xLabelX, xLabelY);

          // Draw background with validated dimensions
          final bgLeft = xLabelOffset.dx - config.style.labelPadding;
          final bgTop = xLabelOffset.dy - config.style.labelPadding;
          final bgWidth = xTextPainter.width + config.style.labelPadding * 2;
          final bgHeight = xTextPainter.height + config.style.labelPadding * 2;

          // Additional validation for rect dimensions
          if (bgLeft.isFinite && bgTop.isFinite && bgWidth.isFinite && bgHeight.isFinite && bgWidth > 0 && bgHeight > 0) {
            final xBgRect = Rect.fromLTWH(bgLeft, bgTop, bgWidth, bgHeight);
            canvas.drawRect(xBgRect, Paint()..color = config.style.labelBackgroundColor);
            xTextPainter.paint(canvas, xLabelOffset);
          }
        }
      }

      // Y coordinate label (left of horizontal line)
      if (config.mode == CrosshairMode.horizontal || config.mode == CrosshairMode.both) {
        // Use data Y value if available, otherwise fall back to screen position
        final displayValue = dataY != null ? _formatDataValue(dataY) : position.dy.toStringAsFixed(0);

        final yTextPainter = TextPainter(
          text: TextSpan(
            text: 'Y: $displayValue',
            style: textStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        // Calculate label position with bounds checking
        const yLabelX = 4.0;
        var yLabelY = position.dy - yTextPainter.height / 2;

        // Clamp Y position to keep label within canvas bounds
        yLabelY = yLabelY.clamp(config.style.labelPadding, size.height - yTextPainter.height - config.style.labelPadding);

        // Only draw if X position is valid and all values are finite
        if (yLabelX >= 0 && yLabelX + yTextPainter.width <= size.width && yLabelX.isFinite && yLabelY.isFinite) {
          final yLabelOffset = Offset(yLabelX, yLabelY);

          // Draw background with validated dimensions
          final bgLeft = yLabelOffset.dx - config.style.labelPadding;
          final bgTop = yLabelOffset.dy - config.style.labelPadding;
          final bgWidth = yTextPainter.width + config.style.labelPadding * 2;
          final bgHeight = yTextPainter.height + config.style.labelPadding * 2;

          // Additional validation for rect dimensions
          if (bgLeft.isFinite && bgTop.isFinite && bgWidth.isFinite && bgHeight.isFinite && bgWidth > 0 && bgHeight > 0) {
            final yBgRect = Rect.fromLTWH(bgLeft, bgTop, bgWidth, bgHeight);
            canvas.drawRect(yBgRect, Paint()..color = config.style.labelBackgroundColor);
            yTextPainter.paint(canvas, yLabelOffset);
          }
        }
      }
    } catch (e) {
      // Silently fail label rendering - don't break the entire crosshair
      // The crosshair lines will still render even if labels fail
      return;
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

  @override
  bool shouldRepaint(_CrosshairPainter oldDelegate) {
    return position != oldDelegate.position ||
        config != oldDelegate.config ||
        nearestPoint != oldDelegate.nearestPoint ||
        dataBounds != oldDelegate.dataBounds ||
        chartRect != oldDelegate.chartRect;
  }
}

// ============================================================================
// TOOLTIP ARROW SUPPORT
// ============================================================================

/// Direction that the tooltip arrow should point.
/// Arrow position for integrated tooltip border
enum _ArrowPosition {
  top,
  bottom,
  left,
  right,
}

/// Custom shape border that integrates arrow notch into tooltip border.
///
/// Creates a continuous path with an arrow notch that is part of the border,
/// not a separate element. This produces the visual effect of the arrow being
/// cut into the tooltip edge.
class _TooltipShapeBorder extends ShapeBorder {
  const _TooltipShapeBorder({
    required this.arrowPosition,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.arrowSize,
    this.boxShadow,
  });

  final _ArrowPosition arrowPosition;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final double arrowSize;
  final List<BoxShadow>? boxShadow;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _createTooltipPath(rect);
  }

  Path _createTooltipPath(Rect rect) {
    final path = Path();
    final radius = borderRadius.topLeft.x;

    switch (arrowPosition) {
      case _ArrowPosition.top:
        // Arrow notch on top edge at FIXED offset from left (not centered)
        const arrowOffsetX = 6.0;
        final arrowLeft = arrowOffsetX - arrowSize / 2;
        final arrowRight = arrowOffsetX + arrowSize / 2;
        final arrowTop = rect.top - arrowSize;

        path.moveTo(rect.left + radius, rect.top);
        // Top-left to arrow start
        path.lineTo(rect.left + arrowLeft, rect.top);
        // Arrow notch down
        path.lineTo(rect.left + arrowOffsetX, arrowTop);
        // Arrow notch back to right
        path.lineTo(rect.left + arrowRight, rect.top);
        // Top-right corner
        path.lineTo(rect.right - radius, rect.top);
        path.quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + radius);
        // Right side
        path.lineTo(rect.right, rect.bottom - radius);
        path.quadraticBezierTo(rect.right, rect.bottom, rect.right - radius, rect.bottom);
        // Bottom-right to bottom-left
        path.lineTo(rect.left + radius, rect.bottom);
        path.quadraticBezierTo(rect.left, rect.bottom, rect.left, rect.bottom - radius);
        // Left side back to start
        path.lineTo(rect.left, rect.top + radius);
        path.quadraticBezierTo(rect.left, rect.top, rect.left + radius, rect.top);
        break;

      case _ArrowPosition.bottom:
        // Arrow notch on bottom edge at FIXED offset from left (not centered)
        const arrowOffsetX = 6.0;
        final arrowLeft = arrowOffsetX - arrowSize / 2;
        final arrowRight = arrowOffsetX + arrowSize / 2;
        final arrowBottom = rect.bottom + arrowSize;

        path.moveTo(rect.left + radius, rect.top);
        // Top side
        path.lineTo(rect.right - radius, rect.top);
        path.quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + radius);
        // Right side
        path.lineTo(rect.right, rect.bottom - radius);
        path.quadraticBezierTo(rect.right, rect.bottom, rect.right - radius, rect.bottom);
        // Bottom-right to arrow start
        path.lineTo(rect.left + arrowRight, rect.bottom);
        // Arrow notch down
        path.lineTo(rect.left + arrowOffsetX, arrowBottom);
        // Arrow notch back to left
        path.lineTo(rect.left + arrowLeft, rect.bottom);
        // Bottom-left corner
        path.lineTo(rect.left + radius, rect.bottom);
        path.quadraticBezierTo(rect.left, rect.bottom, rect.left, rect.bottom - radius);
        // Left side
        path.lineTo(rect.left, rect.top + radius);
        path.quadraticBezierTo(rect.left, rect.top, rect.left + radius, rect.top);
        break;

      case _ArrowPosition.left:
        // Arrow notch on left edge at FIXED offset from top (not centered)
        const arrowOffsetY = 6.0;
        final arrowTop = arrowOffsetY - arrowSize / 2;
        final arrowBottom = arrowOffsetY + arrowSize / 2;
        final arrowLeft = rect.left - arrowSize;

        path.moveTo(rect.left, rect.top + radius);
        // Top-left to arrow start
        path.lineTo(rect.left, rect.top + arrowTop);
        // Arrow notch left
        path.lineTo(arrowLeft, rect.top + arrowOffsetY);
        // Arrow notch back to bottom
        path.lineTo(rect.left, rect.top + arrowBottom);
        // Left side continues down
        path.lineTo(rect.left, rect.bottom - radius);
        path.quadraticBezierTo(rect.left, rect.bottom, rect.left + radius, rect.bottom);
        // Bottom side
        path.lineTo(rect.right - radius, rect.bottom);
        path.quadraticBezierTo(rect.right, rect.bottom, rect.right, rect.bottom - radius);
        // Right side
        path.lineTo(rect.right, rect.top + radius);
        path.quadraticBezierTo(rect.right, rect.top, rect.right - radius, rect.top);
        // Top side back to start
        path.lineTo(rect.left + radius, rect.top);
        path.quadraticBezierTo(rect.left, rect.top, rect.left, rect.top + radius);
        break;

      case _ArrowPosition.right:
        // Arrow notch on right edge at FIXED offset from top (not centered)
        const arrowOffsetY = 6.0;
        final arrowTop = arrowOffsetY - arrowSize / 2;
        final arrowBottom = arrowOffsetY + arrowSize / 2;
        final arrowRight = rect.right + arrowSize;

        path.moveTo(rect.left + radius, rect.top);
        // Top side
        path.lineTo(rect.right - radius, rect.top);
        path.quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + radius);
        // Right side to arrow start
        path.lineTo(rect.right, rect.top + arrowTop);
        // Arrow notch right
        path.lineTo(arrowRight, rect.top + arrowOffsetY);
        // Arrow notch back to bottom
        path.lineTo(rect.right, rect.top + arrowBottom);
        // Right side continues down
        path.lineTo(rect.right, rect.bottom - radius);
        path.quadraticBezierTo(rect.right, rect.bottom, rect.right - radius, rect.bottom);
        // Bottom side
        path.lineTo(rect.left + radius, rect.bottom);
        path.quadraticBezierTo(rect.left, rect.bottom, rect.left, rect.bottom - radius);
        // Left side back to start
        path.lineTo(rect.left, rect.top + radius);
        path.quadraticBezierTo(rect.left, rect.top, rect.left + radius, rect.top);
        break;
    }

    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final path = _createTooltipPath(rect);

    // Draw shadows if provided
    if (boxShadow != null && boxShadow!.isNotEmpty) {
      for (final shadow in boxShadow!) {
        final shadowPath = path.shift(shadow.offset);
        canvas.drawPath(
          shadowPath,
          Paint()
            ..color = shadow.color.withOpacity(shadow.color.opacity)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius),
        );
      }
    }

    // Fill background
    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Draw border
    if (borderWidth > 0) {
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  ShapeBorder scale(double t) {
    return _TooltipShapeBorder(
      arrowPosition: arrowPosition,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      borderRadius: borderRadius * t,
      arrowSize: arrowSize * t,
      boxShadow: boxShadow?.map((s) => s.scale(t)).toList(),
    );
  }
}
