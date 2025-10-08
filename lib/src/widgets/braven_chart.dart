// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';
import 'dart:math' show cos, sin, sqrt;

import 'package:braven_charts/src/foundation/data_models/chart_data_point.dart';
// Layer 0: Foundation
import 'package:braven_charts/src/foundation/data_models/chart_series.dart';
// Layer 7: Interaction
import 'package:braven_charts/src/interaction/event_handler.dart' hide KeyEventResult;
import 'package:braven_charts/src/interaction/models/crosshair_config.dart';
import 'package:braven_charts/src/interaction/models/interaction_config.dart';
import 'package:braven_charts/src/interaction/models/interaction_state.dart';
import 'package:braven_charts/src/interaction/models/tooltip_config.dart';
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
import 'package:flutter/gestures.dart' show PointerScrollEvent;
import 'package:flutter/material.dart';

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
class _BravenChartState extends State<BravenChart> {
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

  /// Current interaction state.
  InteractionState _interactionState = InteractionState.initial();

  // ==================== LIFECYCLE METHODS ====================

  @override
  void initState() {
    super.initState();

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

    // Unsubscribe from controller
    _getController()?.removeListener(_onControllerUpdate);

    // Dispose internal controller
    _internalController?.dispose();
    _internalController = null;

    // Dispose interaction system
    _eventHandler?.dispose();
    _eventHandler = null;

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
    Widget chartWidget = RepaintBoundary(
      child: CustomPaint(
        painter: _BravenChartPainter(
          chartType: widget.chartType,
          series: allSeries,
          theme: effectiveTheme,
          xAxis: effectiveXAxis,
          yAxis: effectiveYAxis,
          annotations: [], // Chart painter doesn't render annotations
        ),
        size: Size(widget.width ?? double.infinity, widget.height ?? double.infinity),
      ),
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

    // Build the full interaction stack
    Widget interactiveWidget = Stack(
      children: [
        // Base chart
        child,
        
        // Crosshair overlay (if enabled and visible)
        if (config.crosshair.enabled && _interactionState.isCrosshairVisible)
          Positioned.fill(
            child: CustomPaint(
              painter: _CrosshairPainter(
                position: _interactionState.crosshairPosition!,
                config: config.crosshair,
                nearestPoint: _interactionState.hoveredPoint != null
                    ? Offset(
                        (_interactionState.hoveredPoint!['x'] as num?)?.toDouble() ?? 0,
                        (_interactionState.hoveredPoint!['y'] as num?)?.toDouble() ?? 0,
                      )
                    : null,
                chartSize: Size.infinite,
              ),
            ),
          ),

        // Tooltip overlay (if enabled and visible)
        if (_buildTooltipOverlay() != null) _buildTooltipOverlay()!,
      ],
    );

    // Wrap in MouseRegion for hover detection
    interactiveWidget = MouseRegion(
      onEnter: (_) {
        // Mouse entered chart area - don't change state yet, wait for actual hover
      },
      onExit: (_) {
        setState(() {
          _interactionState = _interactionState.copyWith(
            isCrosshairVisible: false,
            isTooltipVisible: false,
            crosshairPosition: null,
            tooltipPosition: null,
            hoveredPoint: null,
            hoveredSeriesId: null,
          );
        });

        // Invoke hover callback with null (exited)
        final exitPosition = Offset.zero; // Position doesn't matter for exit
        config.onDataPointHover?.call(null, exitPosition);
      },
      onHover: (event) {
        setState(() {
          // Update crosshair position
          _interactionState = _interactionState.copyWith(
            crosshairPosition: event.localPosition,
            isCrosshairVisible: config.crosshair.enabled,
          );

          // Find nearest data point for snap and tooltip
          final nearestPointData = _findNearestDataPoint(event.localPosition);
          if (nearestPointData != null) {
            _interactionState = _interactionState.copyWith(
              hoveredPoint: nearestPointData,
              hoveredSeriesId: nearestPointData['seriesId'] as String?,
              tooltipPosition: event.localPosition,
              tooltipDataPoint: nearestPointData,
              isTooltipVisible: config.tooltip.enabled,
            );

            // Convert Map to ChartDataPoint for callback
            final point = _mapToDataPoint(nearestPointData);
            config.onDataPointHover?.call(point, event.localPosition);
          } else {
            // No point nearby, clear tooltip
            _interactionState = _interactionState.copyWith(
              isTooltipVisible: false,
              hoveredPoint: null,
              hoveredSeriesId: null,
              tooltipDataPoint: null,
            );
          }
        });

        // Invoke crosshair changed callback
        final snapPointsList = _interactionState.snapPoints
            .map((data) => _mapToDataPoint(data))
            .toList();
        config.onCrosshairChanged?.call(event.localPosition, snapPointsList);
      },
      child: interactiveWidget,
    );

    // Wrap with Listener for scroll/middle-mouse events
    interactiveWidget = Listener(
      onPointerSignal: (signal) {
        if (signal is PointerScrollEvent && config.enableZoom) {
          // TODO R-T006: Will be implemented with modifier key detection
          // CTRL/CMD + Scroll -> Zoom
          // SHIFT + Scroll -> Pan horizontally
          // Plain scroll -> Allow page scroll (don't consume)
          // For now, just placeholder
        }
      },
      child: interactiveWidget,
    );

    // Wrap with GestureDetector for tap/long-press/pan/pinch
    interactiveWidget = GestureDetector(
      // Tap handling
      onTapDown: config.enableSelection ? (details) {
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
          final selectedPointsList = _interactionState.selectedPoints
              .map((data) => _mapToDataPoint(data))
              .toList();
          config.onSelectionChanged?.call(selectedPointsList);
        }
      } : null,

      // Long press handling
      onLongPressStart: (details) {
        final nearestPointData = _findNearestDataPoint(details.localPosition);
        if (nearestPointData != null) {
          final point = _mapToDataPoint(nearestPointData);
          config.onDataPointLongPress?.call(point, details.localPosition);
        }
      },

      // Pan handling (for drag interactions)
      onPanStart: config.enablePan ? (details) {
        // TODO R-T007: Actual pan logic will be added with ZoomPanController
        // For now just track that we're panning
      } : null,
      
      onPanUpdate: config.enablePan ? (details) {
        // TODO R-T007: Actual pan logic will be added with ZoomPanController
      } : null,

      onPanEnd: config.enablePan ? (details) {
        // TODO R-T007: Cleanup will be added with ZoomPanController
      } : null,

      // Pinch/scale handling (for zoom)
      onScaleStart: config.enableZoom ? (details) {
        // TODO R-T007: Zoom handling will be added with ZoomPanController
      } : null,

      onScaleUpdate: config.enableZoom ? (details) {
        // TODO R-T007: Zoom handling will be added with ZoomPanController
      } : null,

      onScaleEnd: config.enableZoom ? (details) {
        // TODO R-T007: Cleanup will be added with ZoomPanController
      } : null,

      child: interactiveWidget,
    );

    // Wrap with Focus for keyboard navigation
    if (config.keyboard.enabled) {
      interactiveWidget = Focus(
        autofocus: false,
        canRequestFocus: true,
        onKeyEvent: (node, event) {
          // TODO R-T010: KeyboardHandler integration will be added
          // For now just ignore
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
  /// Returns null if no point is within the snap radius.
  Map<String, dynamic>? _findNearestDataPoint(Offset screenPosition) {
    if (!widget.interactionConfig!.crosshair.snapToDataPoint) {
      return null;
    }

    final snapRadius = widget.interactionConfig!.crosshair.snapRadius;
    Map<String, dynamic>? nearestPoint;
    double minDistance = snapRadius;

    // Iterate through all series to find nearest point
    final allSeries = _getAllSeries();
    for (final series in allSeries) {
      for (final point in series.points) {
        // TODO R-T005: Convert data coordinates to screen coordinates
        // For now, using simplified distance calculation
        // This will be properly implemented when coordinate transformation is available
        final dx = screenPosition.dx - (point.x * 100); // Placeholder
        final dy = screenPosition.dy - (point.y * 100); // Placeholder
        final distance = sqrt(dx * dx + dy * dy);

        if (distance < minDistance) {
          minDistance = distance;
          nearestPoint = {
            'seriesId': series.id,
            'x': point.x,
            'y': point.y,
            if (point.metadata != null) ...point.metadata!,
          };
        }
      }
    }

    return nearestPoint;
  }

  /// Builds the tooltip overlay widget with smart positioning.
  Widget? _buildTooltipOverlay() {
    final config = widget.interactionConfig?.tooltip;
    if (config == null || !config.enabled || !_interactionState.isTooltipVisible) {
      return null;
    }

    final tooltipPosition = _interactionState.tooltipPosition;
    final dataPoint = _interactionState.tooltipDataPoint;
    
    if (tooltipPosition == null || dataPoint == null) {
      return null;
    }

    // Use custom builder if provided, otherwise default builder
    Widget tooltipContent;
    if (config.customBuilder != null) {
      tooltipContent = config.customBuilder!(context, dataPoint);
    } else {
      // Default tooltip builder
      tooltipContent = _buildDefaultTooltip(dataPoint, config);
    }

    // Wrap in container with style
    tooltipContent = Container(
      padding: EdgeInsets.all(config.style.padding),
      decoration: BoxDecoration(
        color: config.style.backgroundColor,
        border: Border.all(
          color: config.style.borderColor,
          width: config.style.borderWidth,
        ),
        borderRadius: BorderRadius.circular(config.style.borderRadius),
        boxShadow: config.style.shadowBlurRadius > 0
            ? [
                BoxShadow(
                  color: config.style.shadowColor,
                  blurRadius: config.style.shadowBlurRadius,
                  offset: Offset(0, config.style.shadowBlurRadius / 2),
                ),
              ]
            : null,
      ),
      child: tooltipContent,
    );

    // Calculate smart positioning
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final chartSize = renderBox.size;
    const tooltipSize = Size(200, 80); // Estimate, will be measured
    
    // Smart positioning: flip to opposite side if clipping
    double left = tooltipPosition.dx + config.offsetFromPoint;
    double top = tooltipPosition.dy + config.offsetFromPoint;

    // Check right boundary
    if (left + tooltipSize.width > chartSize.width) {
      left = tooltipPosition.dx - tooltipSize.width - config.offsetFromPoint;
    }

    // Check bottom boundary
    if (top + tooltipSize.height > chartSize.height) {
      top = tooltipPosition.dy - tooltipSize.height - config.offsetFromPoint;
    }

    // Ensure not off left edge
    if (left < 0) {
      left = 10;
    }

    // Ensure not off top edge
    if (top < 0) {
      top = 10;
    }

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _interactionState.isTooltipVisible ? 1.0 : 0.0,
          duration: config.showDelay,
          child: tooltipContent,
        ),
      ),
    );
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
        ...dataPoint.entries
            .where((e) => e.key != 'x' && e.key != 'y')
            .map((e) => Padding(
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
  });

  final ChartType chartType;
  final List<ChartSeries> series;
  final ChartTheme theme;
  final AxisConfig xAxis;
  final AxisConfig yAxis;
  final List<ChartAnnotation> annotations;

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

    // Calculate data bounds
    final bounds = _calculateDataBounds();
    if (bounds == null) return;

    // Calculate chart area (leave room for axes)
    const padding = 40.0;
    final chartRect = Rect.fromLTWH(padding, padding, size.width - padding * 2, size.height - padding * 2);

    // Draw grid
    _drawGrid(canvas, chartRect);

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

  _DataBounds? _calculateDataBounds() {
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

    // Add padding to Y range
    final yRange = maxY - minY;
    minY -= yRange * 0.1;
    maxY += yRange * 0.1;

    return _DataBounds(minX: minX, maxX: maxX, minY: minY, maxY: maxY);
  }

  void _drawGrid(Canvas canvas, Rect chartRect) {
    if (!xAxis.showGrid && !yAxis.showGrid) return;

    final gridPaint = Paint()
      ..color = theme.gridStyle.majorColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = theme.gridStyle.majorWidth;

    if (yAxis.showGrid) {
      for (var i = 0; i <= 5; i++) {
        final y = chartRect.top + (chartRect.height * i / 5);
        canvas.drawLine(Offset(chartRect.left, y), Offset(chartRect.right, y), gridPaint);
      }
    }

    if (xAxis.showGrid) {
      for (var i = 0; i <= 5; i++) {
        final x = chartRect.left + (chartRect.width * i / 5);
        canvas.drawLine(Offset(x, chartRect.top), Offset(x, chartRect.bottom), gridPaint);
      }
    }
  }

  void _drawLineSeries(Canvas canvas, Rect chartRect, _DataBounds bounds) {
    final colors = theme.seriesTheme.colors;

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

      // Draw markers
      final markerPaint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      for (final point in s.points) {
        final offset = _dataToPixel(point, chartRect, bounds);
        canvas.drawCircle(offset, 4, markerPaint);
      }
    }
  }

  void _drawAreaSeries(Canvas canvas, Rect chartRect, _DataBounds bounds) {
    final colors = theme.seriesTheme.colors;

    for (var i = 0; i < series.length; i++) {
      final s = series[i];
      if (s.points.isEmpty) continue;

      final color = colors[i % colors.length];
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      final path = Path();
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
  }

  void _drawBarSeries(Canvas canvas, Rect chartRect, _DataBounds bounds) {
    final colors = theme.seriesTheme.colors;
    final barCount = series.isEmpty ? 0 : series.first.points.length;
    final seriesCount = series.length;

    if (barCount == 0) return;

    final barGroupWidth = chartRect.width / barCount;
    final barWidth = barGroupWidth / (seriesCount + 1);

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
  }

  void _drawScatterSeries(Canvas canvas, Rect chartRect, _DataBounds bounds) {
    final colors = theme.seriesTheme.colors;

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
  }

  void _drawAxes(Canvas canvas, Size size, Rect chartRect, _DataBounds bounds) {
    final axisPaint = Paint()
      ..color = theme.axisStyle.lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = theme.axisStyle.lineWidth;

    if (xAxis.showAxis) {
      canvas.drawLine(Offset(chartRect.left, chartRect.bottom), Offset(chartRect.right, chartRect.bottom), axisPaint);
    }

    if (yAxis.showAxis) {
      canvas.drawLine(Offset(chartRect.left, chartRect.top), Offset(chartRect.left, chartRect.bottom), axisPaint);
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
        annotations != oldDelegate.annotations;
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
  });

  final Offset position;
  final CrosshairConfig config;
  final Offset? nearestPoint;
  final Size chartSize;

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
    final textStyle = config.coordinateLabelStyle ?? TextStyle(
      color: config.style.labelTextColor,
      fontSize: 10,
      backgroundColor: config.style.labelBackgroundColor.withOpacity(0.8),
    );

    // X coordinate label (bottom of vertical line)
    if (config.mode == CrosshairMode.vertical || config.mode == CrosshairMode.both) {
      final xTextPainter = TextPainter(
        text: TextSpan(
          text: 'X: ${position.dx.toStringAsFixed(0)}',
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final xLabelOffset = Offset(
        position.dx - xTextPainter.width / 2,
        size.height - xTextPainter.height - 4,
      );
      
      // Draw background
      final xBgRect = Rect.fromLTWH(
        xLabelOffset.dx - config.style.labelPadding,
        xLabelOffset.dy - config.style.labelPadding,
        xTextPainter.width + config.style.labelPadding * 2,
        xTextPainter.height + config.style.labelPadding * 2,
      );
      canvas.drawRect(xBgRect, Paint()..color = config.style.labelBackgroundColor);
      
      xTextPainter.paint(canvas, xLabelOffset);
    }

    // Y coordinate label (left of horizontal line)
    if (config.mode == CrosshairMode.horizontal || config.mode == CrosshairMode.both) {
      final yTextPainter = TextPainter(
        text: TextSpan(
          text: 'Y: ${position.dy.toStringAsFixed(0)}',
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final yLabelOffset = Offset(
        4,
        position.dy - yTextPainter.height / 2,
      );
      
      // Draw background
      final yBgRect = Rect.fromLTWH(
        yLabelOffset.dx - config.style.labelPadding,
        yLabelOffset.dy - config.style.labelPadding,
        yTextPainter.width + config.style.labelPadding * 2,
        yTextPainter.height + config.style.labelPadding * 2,
      );
      canvas.drawRect(yBgRect, Paint()..color = config.style.labelBackgroundColor);
      
      yTextPainter.paint(canvas, yLabelOffset);
    }
  }

  @override
  bool shouldRepaint(_CrosshairPainter oldDelegate) {
    return position != oldDelegate.position ||
        config != oldDelegate.config ||
        nearestPoint != oldDelegate.nearestPoint;
  }
}
