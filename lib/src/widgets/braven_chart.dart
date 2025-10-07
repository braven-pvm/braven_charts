// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import 'package:braven_charts/src/foundation/data_models/chart_data_point.dart';
// Layer 0: Foundation
import 'package:braven_charts/src/foundation/data_models/chart_series.dart';
// Layer 3: Theming
import 'package:braven_charts/src/theming/chart_theme.dart';
import 'package:braven_charts/src/widgets/annotations/chart_annotation.dart';
import 'package:braven_charts/src/widgets/axis/axis_config.dart';
import 'package:braven_charts/src/widgets/controller/chart_controller.dart';
// Layer 5: Widgets
import 'package:braven_charts/src/widgets/enums/chart_type.dart';
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

    final point = _pendingDataPoint!;
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

    // Build widget tree
    Widget chartWidget = RepaintBoundary(
      child: CustomPaint(
        painter: _BravenChartPainter(
          chartType: widget.chartType,
          series: allSeries,
          theme: effectiveTheme,
          xAxis: effectiveXAxis,
          yAxis: effectiveYAxis,
          annotations: _getAllAnnotations(),
        ),
        size: Size(widget.width ?? double.infinity, widget.height ?? double.infinity),
      ),
    );

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

      children.add(Expanded(child: chartWidget));

      chartWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    }

    return chartWidget;
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
    // TODO: Full integration with Layer 4 chart implementations
    // For now, draw a placeholder with basic information

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

    // Draw placeholder grid (if grid is visible)
    if (xAxis.showGrid || yAxis.showGrid) {
      final gridPaint = Paint()
        ..color = theme.gridStyle.majorColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = theme.gridStyle.majorWidth;

      // Vertical grid lines (x-axis)
      if (xAxis.showGrid) {
        const gridCount = 5;
        for (var i = 1; i < gridCount; i++) {
          final x = size.width * i / gridCount;
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
        }
      }

      // Horizontal grid lines (y-axis)
      if (yAxis.showGrid) {
        const gridCount = 5;
        for (var i = 1; i < gridCount; i++) {
          final y = size.height * i / gridCount;
          canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
        }
      }
    }

    // Draw placeholder chart type indicator
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Chart Type: ${chartType.name}\n'
            'Series: ${series.length}\n'
            'Annotations: ${annotations.length}\n'
            'Full rendering in T024',
        style: TextStyle(
          color: theme.gridStyle.majorColor,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height / 2 - textPainter.height / 2));
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
