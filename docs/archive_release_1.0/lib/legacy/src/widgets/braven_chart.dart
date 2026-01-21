// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';
import 'dart:math' show cos, sin, sqrt, log, pow, ln10;

// Multi-Axis Normalization (Layer 11)
import 'package:braven_charts/legacy/src/axis/data_normalizer.dart';
import 'package:braven_charts/legacy/src/axis/multi_axis_config.dart';
import 'package:braven_charts/legacy/src/axis/normalization_detector.dart';
import 'package:braven_charts/legacy/src/axis/normalization_mode.dart';
// Layer 5: Chart Configuration
import 'package:braven_charts/legacy/src/charts/line/line_chart_config.dart'
    show LineStyle;
import 'package:braven_charts/legacy/src/charts/line/line_interpolator.dart';
import 'package:braven_charts/legacy/src/foundation/data_models/chart_data_point.dart';
// Layer 0: Foundation
import 'package:braven_charts/legacy/src/foundation/data_models/chart_series.dart';
import 'package:braven_charts/legacy/src/foundation/foundation.dart'
    show DataRange;
// Layer 7: Interaction
import 'package:braven_charts/legacy/src/interaction/event_handler.dart'
    hide KeyEventResult;
import 'package:braven_charts/legacy/src/interaction/keyboard_handler.dart';
import 'package:braven_charts/legacy/src/interaction/models/crosshair_config.dart';
import 'package:braven_charts/legacy/src/interaction/models/interaction_config.dart';
import 'package:braven_charts/legacy/src/interaction/models/interaction_state.dart';
import 'package:braven_charts/legacy/src/interaction/models/tooltip_config.dart';
import 'package:braven_charts/legacy/src/interaction/models/zoom_pan_state.dart';
import 'package:braven_charts/legacy/src/interaction/zoom_pan_controller.dart';
import 'package:braven_charts/legacy/src/models/chart_mode.dart';
import 'package:braven_charts/legacy/src/models/streaming_config.dart';
import 'package:braven_charts/legacy/src/painters/multi_axis_painter.dart';
// Layer 3: Theming
import 'package:braven_charts/legacy/src/theming/chart_theme.dart';
import 'package:braven_charts/legacy/src/utils/buffer_manager.dart';
import 'package:braven_charts/legacy/src/utils/trend_calculator.dart';
import 'package:braven_charts/legacy/src/widgets/annotations/chart_annotation.dart';
import 'package:braven_charts/legacy/src/widgets/annotations/point_annotation.dart';
import 'package:braven_charts/legacy/src/widgets/annotations/range_annotation.dart';
import 'package:braven_charts/legacy/src/widgets/annotations/text_annotation.dart';
import 'package:braven_charts/legacy/src/widgets/annotations/threshold_annotation.dart';
import 'package:braven_charts/legacy/src/widgets/annotations/trend_annotation.dart';
import 'package:braven_charts/legacy/src/widgets/auto_scroll_config.dart';
import 'package:braven_charts/legacy/src/widgets/axis/axis_config.dart';
import 'package:braven_charts/legacy/src/widgets/chart_scrollbar.dart';
import 'package:braven_charts/legacy/src/widgets/controller/chart_controller.dart';
import 'package:braven_charts/legacy/src/widgets/controller/streaming_controller.dart';
import 'package:braven_charts/legacy/src/widgets/enums/annotation_anchor.dart';
import 'package:braven_charts/legacy/src/widgets/enums/annotation_axis.dart';
import 'package:braven_charts/legacy/src/widgets/enums/axis_position.dart';
// Layer 5: Widgets
import 'package:braven_charts/legacy/src/widgets/enums/chart_type.dart';
import 'package:braven_charts/legacy/src/widgets/enums/marker_shape.dart';
import 'package:braven_charts/legacy/src/widgets/enums/trend_type.dart';
import 'package:braven_charts/legacy/src/widgets/interactions/annotation_context_menu.dart';
import 'package:braven_charts/legacy/src/widgets/scrollbar/scrollbar_interaction.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart'
    show PointerScrollEvent, kMiddleMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart'
    show LogicalKeyboardKey, KeyDownEvent, KeyRepeatEvent, BrowserContextMenu;

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
///   xAxis: LegacyAxisConfig.defaults(),
///   yAxis: LegacyAxisConfig.defaults(),
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
    this.lineStyle = LineStyle.straight,
    required this.series,
    this.width,
    this.height,
    this.theme,
    this.xAxis,
    this.yAxis,
    this.annotations = const [],
    this.controller,
    this.streamingController,
    this.dataStream,
    this.autoScrollConfig,
    this.streamingConfig,
    this.title,
    this.subtitle,
    this.showLegend = true,
    this.showToolbar = false,
    this.interactiveAnnotations = true,
    this.loadingWidget,
    this.errorWidget,
    this.onPointTap,
    this.onPointHover,
    this.onBackgroundTap,
    this.onSeriesSelected,
    this.onAnnotationTap,
    this.onAnnotationDragged,
    this.interactionConfig,
    this.multiAxisConfig,
  })  : assert(series.isNotEmpty || dataStream != null,
            'At least one series or dataStream is required'),
        assert(width == null || width > 0, 'Width must be positive'),
        assert(height == null || height > 0, 'Height must be positive');

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
    LineStyle lineStyle = LineStyle.straight,
    required String seriesId,
    required List<double> yValues,
    List<double>? xValues,
    String? seriesName,
    Color? seriesColor,
    double? width,
    double? height,
    ChartTheme? theme,
    LegacyAxisConfig? xAxis,
    LegacyAxisConfig? yAxis,
    List<TextAnnotation> annotations = const [],
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
    void Function(ChartAnnotation annotation, Offset newPosition)?
        onAnnotationDragged,
    InteractionConfig? interactionConfig,
  }) {
    // Generate x-values if not provided
    final xVals = xValues ?? List.generate(yValues.length, (i) => i.toDouble());

    // Validate lengths match
    assert(xVals.length == yValues.length,
        'X and Y value lists must have the same length');

    // Create data points
    final points = List.generate(
        yValues.length, (i) => ChartDataPoint(x: xVals[i], y: yValues[i]));

    // Create series
    final series = ChartSeries(
        id: seriesId, name: seriesName, points: points, color: seriesColor);

    return BravenChart(
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
    LineStyle lineStyle = LineStyle.straight,
    required String seriesId,
    required Map<dynamic, double> data,
    String? seriesName,
    Color? seriesColor,
    double? width,
    double? height,
    ChartTheme? theme,
    LegacyAxisConfig? xAxis,
    LegacyAxisConfig? yAxis,
    List<TextAnnotation> annotations = const [],
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
    void Function(ChartAnnotation annotation, Offset newPosition)?
        onAnnotationDragged,
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
        id: seriesId, name: seriesName, points: points, color: seriesColor);

    return BravenChart(
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
    LineStyle lineStyle = LineStyle.straight,
    required String seriesId,
    required String json,
    String? seriesName,
    Color? seriesColor,
    double? width,
    double? height,
    ChartTheme? theme,
    LegacyAxisConfig? xAxis,
    LegacyAxisConfig? yAxis,
    List<TextAnnotation> annotations = const [],
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
    void Function(ChartAnnotation annotation, Offset newPosition)?
        onAnnotationDragged,
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
              label: item['label'] as String?);
        } else {
          throw ArgumentError(
              'JSON array must contain objects with x and y properties');
        }
      }).toList();
    } else {
      throw ArgumentError('JSON must be an array of data points');
    }

    // Create series
    final series = ChartSeries(
        id: seriesId, name: seriesName, points: points, color: seriesColor);

    return BravenChart(
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
  // ==================== CORE CONFIGURATION ====================

  /// Type of chart to render (line, area, bar, scatter).
  final ChartType chartType;

  /// Line interpolation style for line charts.
  ///
  /// Determines how points are connected:
  /// - [LineStyle.straight]: Direct linear segments (default)
  /// - [LineStyle.smooth]: Smooth bezier curves (Catmull-Rom spline)
  /// - [LineStyle.stepped]: Horizontal-then-vertical steps
  ///
  /// Only applies to line charts. Ignored for other chart types.
  final LineStyle lineStyle;

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
  /// Defaults to LegacyAxisConfig.defaults() if null.
  final LegacyAxisConfig? xAxis;

  /// Y-axis configuration.
  ///
  /// Controls visibility, labels, grid, range, and styling.
  /// Defaults to LegacyAxisConfig.defaults() if null.
  final LegacyAxisConfig? yAxis;

  // ==================== ANNOTATIONS ====================

  /// Static chart-level text annotations to render on the chart.
  ///
  /// Only TextAnnotation is supported at chart level since it's not tied to a specific series.
  /// For series-specific annotations (Point, Range, Threshold, Trend), add them to ChartSeries.annotations.
  /// For dynamic annotations, use [controller.addAnnotation()].
  final List<TextAnnotation> annotations;

  // ==================== REAL-TIME DATA ====================

  /// Controller for programmatic data and annotation updates.
  ///
  /// Provides methods to add/remove points and annotations dynamically.
  /// If null, widget creates an internal controller.
  final ChartController? controller;

  /// Controller for programmatic streaming mode control (T055: FR-010).
  ///
  /// Provides methods to manually pause and resume streaming, enabling
  /// custom UI controls for dual-mode streaming behavior.
  ///
  /// Example:
  /// ```dart
  /// final streamingController = StreamingController();
  ///
  /// ElevatedButton(
  ///   onPressed: () => streamingController.resumeStreaming(),
  ///   child: Text('Resume Live'),
  /// ),
  ///
  /// BravenChart(
  ///   streamingController: streamingController,
  ///   // ...
  /// )
  /// ```
  final StreamingController? streamingController;

  /// Stream for real-time data updates.
  ///
  /// When provided, the widget subscribes and adds incoming points
  /// to the chart with automatic throttling (16ms for 60 FPS).
  final Stream<ChartDataPoint>? dataStream;

  /// Configuration for automatic scrolling in streaming scenarios.
  ///
  /// When enabled, the chart automatically pans to keep the most recent
  /// [AutoScrollConfig.maxVisiblePoints] points visible as new data arrives.
  ///
  /// Useful for real-time monitoring where you want to see the latest data
  /// without manual panning.
  ///
  /// Example:
  /// ```dart
  /// BravenChart(
  ///   autoScrollConfig: AutoScrollConfig(
  ///     enabled: true,
  ///     maxVisiblePoints: 50,  // Show last 50 points
  ///     resumeOnNewData: true,
  ///   ),
  ///   // ... other parameters
  /// )
  /// ```
  final AutoScrollConfig? autoScrollConfig;

  /// Configuration for dual-mode streaming behavior (T010: FR-001 through FR-020).
  ///
  /// When provided, enables automatic mode switching between streaming and interactive:
  /// - **Streaming mode**: High-frequency updates (>10Hz), interactions disabled, auto-scroll
  /// - **Interactive mode**: Full interaction enabled, stream data buffered, auto-resume timer
  ///
  /// **Key Features:**
  /// - Auto-pause on interaction (hover, click, zoom, pan) → switches to interactive mode
  /// - Configurable auto-resume timeout (default 10s) → returns to streaming mode
  /// - FIFO buffer for incoming data during interactive mode (default 10K points)
  /// - Callbacks for mode changes, buffer updates, and return-to-live events
  ///
  /// **Example:**
  /// ```dart
  /// BravenChart(
  ///   dataStream: sensorDataStream,  // Stream of ChartDataPoint
  ///   streamingConfig: StreamingConfig(
  ///     autoResumeTimeout: Duration(seconds: 15),
  ///     maxBufferSize: 5000,
  ///     onModeChanged: (mode) => print('Mode: $mode'),
  ///     onBufferUpdated: (size, isFull) => print('Buffer: $size'),
  ///     onReturnToLive: () => print('Resumed streaming'),
  ///     onStreamError: (error) => print('Error: $error'),
  ///   ),
  ///   // ... other parameters
  /// )
  /// ```
  ///
  /// **Requirements:**
  /// - Must provide `dataStream` when using `streamingConfig`
  /// - Constitution II: Uses ValueNotifier pattern for >10Hz updates
  /// - Performance: 60fps streaming, <16ms interaction, <50ms mode transitions
  ///
  /// **Related:**
  /// - FR-001 to FR-020: All functional requirements
  /// - SC-001 to SC-010: All success criteria
  /// - Constitution II: No setState during high-frequency updates
  final StreamingConfig? streamingConfig;

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
  final void Function(ChartAnnotation annotation, Offset newPosition)?
      onAnnotationDragged;

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

  /// Configuration for multi-axis normalization (Layer 11).
  ///
  /// When provided, enables multiple Y-axes with different scales to be
  /// displayed on the same chart. The normalization system ensures all
  /// series are scaled appropriately based on their individual bounds.
  ///
  /// Example:
  /// ```dart
  /// BravenChart(
  ///   multiAxisConfig: MultiAxisConfig(
  ///     axes: [
  ///       YAxisConfig(id: 'power', label: 'Power (W)', min: 0, max: 300),
  ///       YAxisConfig(id: 'volume', label: 'Volume (L)', min: 0.5, max: 4.0),
  ///     ],
  ///     bindings: [
  ///       SeriesAxisBinding(seriesId: 'power-series', axisId: 'power'),
  ///       SeriesAxisBinding(seriesId: 'volume-series', axisId: 'volume'),
  ///     ],
  ///     normalizationMode: NormalizationMode.auto,
  ///   ),
  ///   // ... other parameters
  /// )
  /// ```
  final MultiAxisConfig? multiAxisConfig;

  // ==================== STATE ====================

  @override
  State<BravenChart> createState() => _BravenChartState();
}

// ==================== STATE CLASS ====================

/// Private state class for BravenChart.
///
/// Manages lifecycle, controller subscriptions, stream subscriptions,
/// and rendering logic.
class _BravenChartState extends State<BravenChart>
    with TickerProviderStateMixin {
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

  /// Pending interaction state for throttled update.
  InteractionState? _pendingInteractionState;

  /// Flag to track if we have a pending frame callback scheduled.
  bool _hasPendingFrameCallback = false;

  /// Last time hover was processed (for simple timestamp throttling).
  int _lastHoverProcessTime = 0;

  /// Event handler for interaction system (Layer 7).
  EventHandler? _eventHandler;

  /// Keyboard handler for keyboard navigation.
  KeyboardHandler? _keyboardHandler;

  /// Zoom/pan controller for viewport transformation.
  ZoomPanController? _zoomPanController;

  /// ValueNotifier for interaction state (replaces setState pattern).
  ///
  /// This notifier allows interactive overlays (crosshair, tooltip) to rebuild
  /// independently without triggering full widget rebuilds. Updates are made
  /// directly via `_interactionStateNotifier.value = ...` instead of setState().
  ///
  /// CRITICAL: Must be disposed in dispose() to prevent memory leaks.
  late final ValueNotifier<InteractionState> _interactionStateNotifier;

  /// ValueNotifier for tracking current chart operating mode (FR-001, FR-002 - T007).
  ///
  /// This notifier manages the mutually exclusive streaming vs. interactive modes:
  /// - ChartMode.streaming: High-frequency updates (>10Hz), interactions disabled
  /// - ChartMode.interactive: Full interaction enabled, streaming paused
  ///
  /// Mode changes trigger:
  /// - Auto-resume timer reset (FR-003)
  /// - StreamingConfig.onModeChanged callback (FR-004)
  /// - Conditional rendering of interaction overlays
  ///
  /// CRITICAL: Must be disposed in dispose() to prevent memory leaks.
  ///
  /// Related: Constitution II (no setState for >10Hz updates), FR-001 performance targets.
  late final ValueNotifier<ChartMode> _chartMode;

  /// Buffer manager for incoming data points during interactive mode (FR-006, FR-013, FR-014 - T008).
  ///
  /// When chart transitions to interactive mode (user hovers, clicks, zooms), incoming
  /// stream data is buffered instead of being rendered immediately. This enables:
  /// - Pause for historical analysis without data loss
  /// - FIFO buffering with configurable max size (default 10,000 points)
  /// - Automatic oldest-data discard when buffer is full
  /// - Bulk application of buffered data on auto-resume or manual resume
  ///
  /// Buffer operations:
  /// - add(): Append new point (discards oldest if full)
  /// - removeAll(): Get all buffered points for bulk application
  /// - clear(): Discard all buffered data
  /// - isFull: Check if buffer reached capacity
  ///
  /// Lifecycle:
  /// - Created in initState() with StreamingConfig.maxBufferSize
  /// - Active only in interactive mode (ChartMode.interactive)
  /// - Cleared on resume to streaming mode
  /// - No disposal needed (Queue auto-managed by Dart GC)
  ///
  /// Related: FR-006 (buffer in interactive), FR-013 (size limit), FR-014 (FIFO),
  ///          FR-011 (apply on resume), SC-005 (10K points performance)
  late final BufferManager<ChartDataPoint> _bufferedPoints;

  /// Auto-resume timer for returning to streaming mode after inactivity (FR-007, FR-009 - T009).
  ///
  /// When chart transitions to interactive mode (user hovers, zooms, pans), this timer
  /// starts counting down. If no user interactions occur before timeout, the chart
  /// automatically resumes streaming mode:
  /// - Timer duration: StreamingConfig.autoResumeTimeout (default 10 seconds)
  /// - Timer reset: On ANY user interaction (hover, click, zoom, pan) per FR-008
  /// - On timeout: Apply buffered data + switch to streaming mode + invoke callbacks
  ///
  /// Timer lifecycle:
  /// - Created when transitioning FROM streaming TO interactive mode
  /// - Canceled and restarted on each user interaction while in interactive mode
  /// - Canceled when manually resuming or disposing widget
  /// - Canceled in dispose() to prevent memory leaks
  ///
  /// Related callbacks invoked on timeout:
  /// - StreamingConfig.onModeChanged(ChartMode.streaming)
  /// - StreamingConfig.onReturnToLive()
  ///
  /// Related: FR-007 (configurable timeout), FR-008 (reset on interaction),
  ///          FR-009 (auto-resume), FR-011 (apply buffered data), SC-006 (100ms resume)
  Timer? _autoResumeTimer;

  /// Tracks if currently panning with middle-mouse button.
  bool _isPanningWithMiddleMouse = false;

  /// Start position for middle-mouse pan drag.
  Offset? _panStartPosition;

  /// Manual SHIFT key state tracking for web compatibility.
  /// HardwareKeyboard.instance doesn't work reliably in Flutter Web.
  bool _isShiftPressed = false;

  /// Focus node for keyboard event handling.
  final FocusNode _focusNode = FocusNode();

  /// Tracks if any annotation is currently being dragged (for cursor management).
  /// Tracks if any annotation is currently being dragged (for cursor management).
  String? _annotationDraggingEdge; // 'left', 'right', 'top', 'bottom', or null

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
  ///
  /// CRITICAL: This chartRect is in CustomPaint coordinate space (0,0 = top-left of CustomPaint).
  /// When using in Stack coordinate space (which includes title), add _titleOffset.dy to Y coordinates.
  Rect? _cachedChartRect;

  /// Offset of the chart canvas relative to the Stack (includes title height).
  ///
  /// When a title/subtitle is present, the CustomPaint canvas is positioned BELOW the title.
  /// This offset tracks the Y distance from Stack's top (0,0) to CustomPaint's top.
  /// Must be added to chartRect Y coordinates when positioning overlays in Stack space.
  Offset _titleOffset = Offset.zero;

  /// Cached Stack size for tooltip positioning.
  ///
  /// Stores the full widget size from LayoutBuilder constraints.
  /// This is the RED area (entire widget) and is used for Positioned widget coordinates.
  Size? _cachedStackSize;

  /// X-scrollbar height when visible (positioned OUTSIDE the Stack where overlays are).
  /// Used to correct Y-coordinate transformations by subtracting from _cachedStackSize.
  double _scrollbarHeightOffset = 0.0;

  /// Timer for hiding tooltip after a delay.
  ///
  /// The tooltip persists even after the mouse leaves the marker.
  /// It only hides after this timeout or when a new marker is hovered.
  Timer? _tooltipHideTimer;

  /// Tracks pan offset at the start of a scrollbar drag operation.
  ///
  /// Scrollbar reports cumulative pixel delta from drag start (e.g., -1, -2, -3...).
  /// To convert this to absolute pan offset, we need to know the starting point.
  /// This field stores panOffset when the drag begins, allowing us to calculate:
  ///   targetPan = dragStartPan + (cumulative delta * scaleFactor)
  ///
  /// Without this, adding cumulative delta to current pan on each frame causes
  /// exponential acceleration (frame N adds sum of all previous deltas).
  ///
  /// Set on first pan interaction, cleared when drag ends or interaction changes.
  Offset? _scrollbarDragStartPan;

  /// Tracks the last scrollbar interaction type to detect interaction changes.
  ///
  /// Used to reset _scrollbarDragStartPan when switching between pan/zoom operations.
  /// Example: User pans, then starts zooming → need to reset drag start tracking.
  ScrollbarInteraction? _lastScrollbarInteraction;

  // ==================== LIFECYCLE METHODS ====================

  @override
  void initState() {
    super.initState();

    // Validation: If dataStream provided, streamingConfig must also be provided (T022: FR-002)
    if (widget.dataStream != null && widget.streamingConfig == null) {
      throw ArgumentError(
        'streamingConfig is required when dataStream is provided. '
        'Provide StreamingConfig to enable dual-mode streaming behavior.',
      );
    }

    // Initialize ValueNotifier for interaction state
    _interactionStateNotifier =
        ValueNotifier<InteractionState>(InteractionState.initial());

    // Initialize dual-mode streaming state (T011: FR-002, FR-003)
    // Determine initial mode: streaming if streamingConfig provided, interactive otherwise
    final initialMode = (widget.streamingConfig != null)
        ? ChartMode.streaming
        : ChartMode.interactive;
    _chartMode = ValueNotifier<ChartMode>(initialMode);

    // Initialize buffer manager with configured max size (default 10K points)
    final bufferSize = widget.streamingConfig?.maxBufferSize ?? 10000;
    _bufferedPoints = BufferManager<ChartDataPoint>(maxSize: bufferSize);

    // Auto-resume timer initialized as null - created when transitioning to interactive mode
    _autoResumeTimer = null;

    // Initialize zoom animation controller (250ms for smooth transitions)
    _zoomAnimationController = AnimationController(
        duration: const Duration(milliseconds: 250), vsync: this)
      ..addListener(() {
        // Update zoom state during animation via notifier (NOT setState)
        if (_zoomAnimationX != null && _zoomAnimationY != null) {
          final currentZoomState = _interactionStateNotifier.value.zoomPanState;
          final newZoomState = currentZoomState.copyWith(
              zoomLevelX: _zoomAnimationX!.value,
              zoomLevelY: _zoomAnimationY!.value);
          _interactionStateNotifier.value = _interactionStateNotifier.value
              .copyWith(zoomPanState: newZoomState);
        }
      });

    // Initialize pan animation controller (250ms for smooth transitions)
    _panAnimationController = AnimationController(
        duration: const Duration(milliseconds: 250), vsync: this)
      ..addListener(() {
        // Update pan state during animation via notifier (NOT setState)
        if (_panAnimation != null) {
          final currentZoomState = _interactionStateNotifier.value.zoomPanState;
          final newZoomState =
              currentZoomState.copyWith(panOffset: _panAnimation!.value);
          _interactionStateNotifier.value = _interactionStateNotifier.value
              .copyWith(zoomPanState: newZoomState);
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

    // Register StreamingController callbacks if provided (T055: FR-010)
    if (widget.streamingController != null) {
      widget.streamingController!.registerResumeCallback(_resumeStreaming);
      widget.streamingController!.registerPauseCallback(_pauseStreaming);
    }

    // Initialize interaction system if enabled
    if (widget.interactionConfig != null && widget.interactionConfig!.enabled) {
      _eventHandler = EventHandler();
      _registerInteractionCallbacks();

      // Initialize ZoomPanController if zoom or pan is enabled
      if (widget.interactionConfig!.enableZoom ||
          widget.interactionConfig!.enablePan) {
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
      if (widget.interactionConfig != null &&
          widget.interactionConfig!.enabled) {
        _eventHandler = EventHandler();
        _registerInteractionCallbacks();

        // Reset interaction state
        _interactionStateNotifier.value = InteractionState.initial();
      }
    }
  }

  /// T074: Handle hot reload - reset to streaming mode (no mode persistence).
  ///
  /// Called during hot reload in development mode. Per spec edge case,
  /// chart should reset to streaming mode regardless of current mode.
  @override
  void reassemble() {
    super.reassemble();

    // Reset to streaming mode if streamingConfig is provided
    if (widget.streamingConfig != null &&
        _chartMode.value != ChartMode.streaming) {
      // Cancel auto-resume timer if active
      _autoResumeTimer?.cancel();
      _autoResumeTimer = null;

      // Clear buffered data on hot reload
      _bufferedPoints.removeAll();

      // Reset to streaming mode
      _chartMode.value = ChartMode.streaming;

      // Notify mode changed
      widget.streamingConfig?.onModeChanged?.call(ChartMode.streaming);
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

    // Dispose ValueNotifier (after all timers and controllers)
    _interactionStateNotifier.dispose();

    // Dispose dual-mode streaming resources
    _autoResumeTimer?.cancel();
    _autoResumeTimer = null;
    _chartMode.dispose();
    // Note: _bufferedPoints has no dispose method (Queue is GC-managed)

    super.dispose();
  }

  // ==================== HELPER METHODS ====================

  /// Gets the active controller (external or internal).
  ChartController? _getController() {
    return widget.controller ?? _internalController;
  }

  /// Updates interaction state with 60Hz throttling (T049).
  ///
  /// Coalesces multiple updates within the same frame. Only applies the LAST
  /// state update after the current frame completes. This prevents multiple
  /// notifier updates during high-frequency events (onHover, onPointerMove, onPointerSignal).
  ///
  /// CRITICAL: Does NOT delay updates - applies immediately if no pending callback.
  /// Only coalesces when multiple updates arrive in the same frame.
  void _updateInteractionStateThrottled(InteractionState newState) {
    // Store the latest state
    _pendingInteractionState = newState;

    // If we don't have a pending callback, schedule one
    if (!_hasPendingFrameCallback) {
      _hasPendingFrameCallback = true;

      SchedulerBinding.instance.addPostFrameCallback((_) {
        _hasPendingFrameCallback = false;

        // Apply the latest pending state (coalesced)
        if (mounted && _pendingInteractionState != null) {
          _interactionStateNotifier.value = _pendingInteractionState!;
          _pendingInteractionState = null;
        }
      });
    }
    // If callback already scheduled, the new state just replaces the pending one (coalescing)
  }

  /// Processes hover events with 60Hz throttling.
  ///
  /// Uses simple timestamp-based throttling (16ms = 60Hz).
  /// This avoids the post-frame callback deadlock where ValueListenableBuilder
  /// triggers a new frame before the callback fires.
  void _processHoverThrottled(Offset position, InteractionConfig config) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeSinceLastProcess = now - _lastHoverProcessTime;

    // Throttle: only process if 16ms have passed (60Hz)
    if (timeSinceLastProcess >= 16) {
      _lastHoverProcessTime = now;
      _processHoverImmediate(position, config);
    }
    // else: Event is too soon - ignore it (last-wins strategy)
    // The next event that comes after 16ms will be processed
  }

  /// Processes a hover event immediately (called by throttled handler).
  void _processHoverImmediate(Offset position, InteractionConfig config) {
    List<Map<String, dynamic>> snapPointsData = const [];

    // Update crosshair position
    final newState = _interactionStateNotifier.value.copyWith(
        crosshairPosition: position,
        isCrosshairVisible: config.crosshair.enabled);

    // Find nearest data point for snap and tooltip
    final nearestPointData = _findNearestDataPoint(position);

    if (nearestPointData != null) {
      snapPointsData = [nearestPointData];

      // Calculate the marker's screen position
      // CRITICAL FIX: _dataToScreenPoint already returns absolute screen coordinates
      // (includes chartRect.left/top offset). DO NOT add the offset again!
      final allSeries = _getAllSeries();

      final markerScreenX = (nearestPointData['screenX'] as num?)?.toDouble();
      final markerScreenY = (nearestPointData['screenY'] as num?)?.toDouble();

      final Offset markerPosition;
      if (markerScreenX != null &&
          markerScreenY != null &&
          markerScreenX.isFinite &&
          markerScreenY.isFinite) {
        // screenX/screenY from _findNearestDataPoint already include chartRect offset
        markerPosition = Offset(markerScreenX, markerScreenY);
      } else {
        final dataX = (nearestPointData['x'] as num?)?.toDouble() ?? 0;
        final dataY = (nearestPointData['y'] as num?)?.toDouble() ?? 0;

        if (_cachedChartRect != null) {
          final bounds =
              _calculateDataBounds(allSeries, chartRect: _cachedChartRect);

          final point = ChartDataPoint(x: dataX, y: dataY);
          final screenPos =
              _dataToScreenPoint(point, _cachedChartRect!, bounds);

          if (screenPos.dx.isFinite && screenPos.dy.isFinite) {
            // _dataToScreenPoint already returns absolute screen coordinates
            markerPosition = screenPos;
          } else {
            markerPosition = position;
          }
        } else {
          markerPosition = position;
        }
      }

      // Update with hoverepoint and tooltip
      _interactionStateNotifier.value = newState.copyWith(
        hoveredPoint: nearestPointData,
        hoveredSeriesId: nearestPointData['seriesId'] as String?,
        tooltipPosition: markerPosition,
        tooltipDataPoint: nearestPointData,
        isTooltipVisible: config.tooltip.enabled,
        snapPoints: snapPointsData,
      );

      // Start tooltip hide timer
      if (config.tooltip.enabled) {
        _startTooltipHideTimer();
      }

      // Invoke hover callback
      final point = _mapToDataPoint(nearestPointData);
      config.onDataPointHover?.call(point, position);

      // Invoke crosshair changed callback
      config.onCrosshairChanged?.call(position, [point]);
    } else {
      // No point nearby - just update crosshair
      _interactionStateNotifier.value = newState;

      // Invoke crosshair changed callback with empty list
      config.onCrosshairChanged?.call(position, []);
    }
  }

  /// Subscribes to the data stream with throttling.
  void _subscribeToStream(Stream<ChartDataPoint> stream) {
    _streamSubscription = stream.listen(
      _onStreamData,
      onError: (error) {
        // T071: Handle stream errors gracefully (FR-017a)
        // Invoke callback immediately (no retry per clarification Q2)
        widget.streamingConfig?.onStreamError?.call(error);
      },
      onDone: () {
        // Stream completed
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

    // Clear the pending data point
    _pendingDataPoint = null;

    // Handle data based on current mode (T017: FR-006)
    _updateData(point);
  }

  /// Updates chart data based on current mode (T017: FR-006).
  ///
  /// Behavior:
  /// - **Streaming mode**: Applies data immediately to chart (triggers rebuild)
  /// - **Interactive mode**: Buffers data silently (no visual update)
  ///
  /// This is the core of dual-mode streaming:
  /// - In streaming mode, users see real-time updates with auto-scroll
  /// - In interactive mode, users can explore historical data without distraction
  /// - Buffered data is applied when returning to streaming mode
  ///
  /// Related: FR-006 (mode-dependent behavior), T029 (_bufferDataPoint)
  void _updateData(ChartDataPoint point) {
    final controller = _getController();
    if (controller == null) return;

    // Check current mode
    if (_chartMode.value == ChartMode.streaming) {
      // Streaming mode: Apply data immediately to the chart
      // Use 'stream' as the default series ID for streamed data
      controller.addPoint('stream', point);

      // DO NOT delete historic data - user should be able to pan through all data
      // The auto-scroll calculation will handle showing only the most recent points
      // in the viewport, but all data remains available for manual exploration

      // Update auto-scroll viewport if enabled (T018: FR-002)
      _updateAutoScrollViewport();
    } else {
      // Interactive mode: Buffer data silently (T029: FR-006)
      _bufferDataPoint(point);
    }
  }

  /// Buffers a data point during interactive mode (T029: FR-006, FR-013, FR-014).
  ///
  /// When in interactive mode, incoming stream data is buffered instead of rendered.
  /// This enables users to explore historical data without distraction from new updates.
  ///
  /// **Behavior**:
  /// - Adds point to FIFO buffer (_bufferedPoints)
  /// - Automatically discards oldest when buffer is full (FR-014)
  /// - Invokes StreamingConfig.onBufferUpdated callback (FR-015)
  ///
  /// **Related**: FR-006 (buffer in interactive), FR-013 (size limit), FR-014 (FIFO)
  void _bufferDataPoint(ChartDataPoint point) {
    // Add to buffer (automatically handles overflow via FIFO)
    _bufferedPoints.add(point);

    // Invoke buffer update callback if provided (FR-015)
    widget.streamingConfig?.onBufferUpdated?.call(_bufferedPoints.length);

    // T062: Enforce maxBufferSize - force auto-resume if buffer full (FR-014, SC-005)
    final maxSize = widget.streamingConfig?.maxBufferSize ?? 10000;
    if (_bufferedPoints.length >= maxSize) {
      // Buffer full - immediately resume to prevent unbounded growth
      _resumeStreaming();
    }
  }

  /// Transitions from streaming mode to interactive mode (T030: FR-004, FR-005).
  ///
  /// Called when user initiates ANY intentional interaction (click, zoom, pan).
  /// This method atomically switches modes and starts the auto-resume timer.
  ///
  /// **Behavior**:
  /// - Guards against redundant transitions (already in interactive mode)
  /// - Sets _chartMode to ChartMode.interactive (triggers rebuild via ValueNotifier)
  /// - Invokes StreamingConfig.onModeChanged callback (FR-004)
  /// - Starts auto-resume timer with configured timeout (FR-007)
  ///
  /// **Related**: FR-004 (pause on interaction), FR-005 (disable interactions in streaming),
  ///              FR-007 (configurable timeout), FR-008 (reset timer on interaction)
  void _pauseStreaming() {
    // Guard: Only transition if streamingConfig is provided
    if (widget.streamingConfig == null) return;

    final wasInStreamingMode = _chartMode.value == ChartMode.streaming;

    // If already in interactive mode, just reset the timer (FR-008)
    if (!wasInStreamingMode) {
      _resetAutoResumeTimer();
      return;
    }

    // Transition to interactive mode (atomic operation)
    _chartMode.value = ChartMode.interactive;

    // Invoke mode changed callback (FR-004)
    widget.streamingConfig?.onModeChanged?.call(ChartMode.interactive);

    // Start auto-resume timer (FR-007, FR-009)
    _startAutoResumeTimer();
  }

  /// Resets the auto-resume timer on continued interactions (FR-008).
  ///
  /// Called when user continues interacting while already in interactive mode.
  /// This ensures the timer only starts counting AFTER the last interaction.
  void _resetAutoResumeTimer() {
    // Only reset if already in interactive mode with an active timer
    if (_chartMode.value != ChartMode.interactive) return;
    if (widget.streamingConfig == null) return;

    // Cancel existing timer and start fresh
    _autoResumeTimer?.cancel();

    // Get timeout duration from config
    final timeout = widget.streamingConfig?.autoResumeTimeout ??
        const Duration(seconds: 10);

    // Start new timer from current moment
    _autoResumeTimer = Timer(timeout, () {
      _resumeStreaming();
    });
  }

  /// Starts the auto-resume timer for returning to streaming mode after inactivity (FR-007, FR-009).
  ///
  /// Timer is reset on ANY user interaction while in interactive mode (FR-008).
  /// When timer expires, chart automatically resumes streaming mode (FR-009).
  void _startAutoResumeTimer() {
    // Cancel any existing timer
    _autoResumeTimer?.cancel();

    // Get timeout duration from config (default 10 seconds per FR-007)
    final timeout = widget.streamingConfig?.autoResumeTimeout ??
        const Duration(seconds: 10);

    // Start new timer
    _autoResumeTimer = Timer(timeout, () {
      // Timer expired - resume streaming mode (FR-009)
      _resumeStreaming();
    });
  }

  /// Resumes streaming mode from interactive mode (FR-009, FR-011).
  ///
  /// Called automatically after auto-resume timeout, or manually via API.
  ///
  /// **Behavior**:
  /// - Applies all buffered data to chart (FR-011)
  /// - Clears buffer
  /// - Transitions to streaming mode
  /// - Invokes callbacks
  void _resumeStreaming() {
    // Guard: Only transition if currently in interactive mode
    if (_chartMode.value != ChartMode.interactive) return;

    final controller = _getController();
    if (controller == null) return;

    // Apply all buffered data (FR-011)
    final bufferedData = _bufferedPoints.removeAll();
    for (final point in bufferedData) {
      controller.addPoint('stream', point);
    }

    // Transition to streaming mode
    _chartMode.value = ChartMode.streaming;

    // Cancel auto-resume timer
    _autoResumeTimer?.cancel();
    _autoResumeTimer = null;

    // Invoke callbacks
    widget.streamingConfig?.onModeChanged?.call(ChartMode.streaming);
    widget.streamingConfig?.onReturnToLive?.call();
  }

  /// Updates viewport for auto-scroll in streaming mode (T018: FR-002).
  ///
  /// Behavior:
  /// - Only applies when mode == ChartMode.streaming
  /// - Only applies when autoScrollConfig.enabled == true
  /// - Scrolls viewport to show latest data (rightmost points)
  /// - Uses ValueNotifier to avoid setState-during-rendering crashes
  ///
  /// This method is safe to call during data streaming because:
  /// 1. Only updates when in streaming mode (no interaction conflicts)
  /// 2. Uses ValueNotifier pattern (Constitution II compliance)
  /// 3. Doesn't trigger setState during rendering pipeline
  ///
  /// Related: FR-002 (auto-scroll in streaming mode only), T019 (no interactions in streaming)
  void _updateAutoScrollViewport() {
    // Guard: Only auto-scroll in streaming mode
    if (_chartMode.value != ChartMode.streaming) {
      return;
    }

    // Guard: Only auto-scroll if config enabled
    if (widget.autoScrollConfig == null || !widget.autoScrollConfig!.enabled) {
      return;
    }

    // Schedule auto-scroll update for after the current frame completes
    // This avoids Flutter rendering pipeline corruption by NOT using setState during frame rendering
    // Instead, we modify ValueNotifier directly in post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final newZoomPanState = _calculateAutoScrollUpdate();
      if (newZoomPanState != null) {
        // Update ValueNotifier directly (NOT setState) to avoid rendering corruption
        // The ValueNotifier will trigger listeners to rebuild automatically
        _interactionStateNotifier.value = _interactionStateNotifier.value
            .copyWith(zoomPanState: newZoomPanState);
      }
    });
  }

  /// Called when the controller notifies of changes.
  void _onControllerUpdate() {
    if (!mounted) return;

    // Rebuild with new data from controller
    // Controller.addPoint() -> notifyListeners() -> this callback -> setState() -> rebuild
    // This ensures buffered points appear immediately when _resumeStreaming() adds them
    setState(() {
      // Data is fetched from controller in build() via _getAllSeries()
      // No state changes needed here - just trigger rebuild
    });
  }

  /// Calculates the pan offset needed to create a sliding window showing the latest data.
  ///
  /// This implements auto-scroll as a **sliding window** that shows only the last N points
  /// (configured via AutoScrollConfig.maxVisiblePoints). As new data arrives, older data
  /// scrolls out of view on the left edge, creating a smooth real-time monitoring experience.
  ///
  /// **Behavior:**
  /// - Adjusts BOTH zoom and pan to create sliding window effect
  /// - Zoom level calculated to make maxVisiblePoints fill the viewport
  /// - Pan offset calculated to show the most recent maxVisiblePoints at right edge
  /// - Older data scrolls off the left edge of viewport
  /// - Creates a moving window where new data always fills the viewport
  ///
  /// Returns null if auto-scroll is not needed or calculations fail validation.
  /// This method performs extensive safety checks to prevent rendering issues.
  ZoomPanState? _calculateAutoScrollUpdate() {
    final config = widget.autoScrollConfig;
    if (config == null || !config.enabled) {
      return null;
    }

    // Get all series to count total points
    final allSeries = _getAllSeries();
    if (allSeries.isEmpty) return null;

    // Find the series with the most points (typically the streaming series)
    int maxPointCount = 0;
    for (final series in allSeries) {
      if (series.points.length > maxPointCount) {
        maxPointCount = series.points.length;
      }
    }

    // SAFETY: Validate point count
    if (maxPointCount <= 0 || maxPointCount <= config.maxVisiblePoints) {
      return null;
    }

    // Get current zoom/pan state for Y-axis only (X will be recalculated)
    final currentZoomState = _interactionStateNotifier.value.zoomPanState;

    // SAFETY: Validate current zoom state
    if (!currentZoomState.zoomLevelY.isFinite) {
      return null;
    }

    // Calculate chart rect for coordinate transformations
    final chartRect =
        _cachedChartRect ?? _calculateChartRect(context.size ?? Size.zero);

    // SAFETY: Validate chart dimensions
    if (chartRect.width <= 0 || !chartRect.width.isFinite) return null;
    if (chartRect.height <= 0 || !chartRect.height.isFinite) return null;

    // Calculate RAW data bounds (WITHOUT zoom/pan transformations)
    // CRITICAL: We need the ACTUAL full data range to calculate zoom properly
    // _calculateDataBounds() applies current zoom/pan state which gives wrong results
    final bounds = _calculateRawDataBounds(allSeries);
    final dataRangeX = bounds.maxX - bounds.minX;

    // SAFETY: Validate data range (prevent division by zero and NaN)
    if (dataRangeX <= 0 || !dataRangeX.isFinite) {
      return null;
    }

    // SAFETY: Validate bounds are reasonable
    if (!bounds.minX.isFinite || !bounds.maxX.isFinite) return null;

    // === SLIDING WINDOW - RIGHTMOST N POINTS ===
    // Goal: Show exactly the rightmost maxVisiblePoints (e.g., 150 points) filling the viewport
    // All historic data is preserved - user can pan back through entire dataset
    //
    // Approach:
    // - Calculate zoom so that targetVisibleRangeX (150 X-units) fills the viewport
    // - Pan to show the rightmost portion of the data
    // - During initial fill (< 150 points), show entire buffer
    // - Once buffer has >= 150 points, show rightmost 150
    //
    // Result:
    // - Zoom is CONSTANT (based on targetVisibleRangeX, not buffer size)
    // - Historic data is preserved for manual panning
    // - Auto-scroll smoothly tracks newest data

    final dataPointsToShow = config.maxVisiblePoints.toDouble();

    // Calculate X-spacing from actual data
    double xRangePerPoint = 1.0;
    if (allSeries.isNotEmpty && allSeries.first.points.length >= 2) {
      final firstSeries = allSeries.first;
      final sortedData = List<ChartDataPoint>.from(firstSeries.points)
        ..sort((a, b) => a.x.compareTo(b.x));

      double totalSpacing = 0;
      int spacingCount = 0;
      for (int i = 1; i < sortedData.length && i < 10; i++) {
        final spacing = (sortedData[i].x - sortedData[i - 1].x).abs();
        if (spacing > 0 && spacing.isFinite) {
          totalSpacing += spacing;
          spacingCount++;
        }
      }
      if (spacingCount > 0) {
        xRangePerPoint = totalSpacing / spacingCount;
      }
    }

    // The DESIRED visible X-range (constant: 150 X-units)
    final targetVisibleRangeX =
        xRangePerPoint * dataPointsToShow; // e.g., 150.0
    if (!targetVisibleRangeX.isFinite || targetVisibleRangeX <= 0) return null;

    // Calculate zoom: how much to zoom so targetVisibleRangeX fills the viewport
    // At zoom=1.0, the entire dataRangeX would fill viewport
    // We want targetVisibleRangeX (150 units) to fill viewport instead
    //
    // Formula: zoom = dataRangeX / targetVisibleRangeX
    //
    // Examples:
    // - dataRangeX = 50 units, targetVisibleRangeX = 150 → zoom = 0.33x (show all data during initial fill)
    // - dataRangeX = 150 units, targetVisibleRangeX = 150 → zoom = 1.0x (perfect fit)
    // - dataRangeX = 450 units, targetVisibleRangeX = 150 → zoom = 3.0x (zoomed in, show rightmost 150 units)
    //
    // This zoom value, combined with pan, ensures exactly 150 units are visible
    final calculatedZoom = dataRangeX / targetVisibleRangeX;

    if (!calculatedZoom.isFinite || calculatedZoom <= 0) return null;
    final clampedZoomX = calculatedZoom.clamp(0.1, 100.0);

    // Show the NEWEST targetVisibleRangeX (150 units) from the buffer
    // Window end = rightmost point in buffer
    // Window start = end - 150 units
    final windowEnd = bounds.maxX;
    final windowStart = windowEnd - targetVisibleRangeX;

    // CRITICAL: Clamp window start to buffer bounds to prevent showing empty space
    // If buffer is smaller than targetVisibleRangeX, show entire buffer
    final clampedWindowStart =
        windowStart < bounds.minX ? bounds.minX : windowStart;

    // === CRITICAL FIX: Pan offset calculation ===
    // Pan offset is stored in PIXEL units and gets divided by zoom when applied (line 2832)
    //
    // The zoom/pan system (line 2822-2837):
    // 1. centerX = (dataMinX + dataMaxX) / 2  -- center of FULL data range
    // 2. rangeX = dataRangeX / zoom  -- visible range after zoom
    // 3. panDataX = -panX * (dataRangeX / width)  -- pan in data units (NEGATED!)
    // 4. minX = centerX - rangeX/2 + panDataX  -- visible window
    //
    // Natural center (pan=0): centerX = (0 + 291) / 2 = 145.5
    // Desired center (rightmost): bounds.maxX - targetVisibleRangeX/2 = 291 - 75 = 216
    // Shift needed: 216 - 145.5 = 70.5 = (dataRangeX - targetVisibleRangeX) / 2
    //
    // This shift should be CONSTANT once we have >150 points!
    // Convert to pixels and negate (because panDataX = -panX):
    final shiftInDataUnits = (dataRangeX - targetVisibleRangeX) / 2;
    final panOffsetX = -(shiftInDataUnits / dataRangeX) * chartRect.width;

    // DEBUG
    debugPrint('\n🎯 [AutoScroll - Rightmost Window (No Data Deletion)]');
    debugPrint('  Buffer: $maxPointCount points (all historic data preserved)');
    debugPrint(
        '  Buffer X-range: ${dataRangeX.toStringAsFixed(1)} units (${bounds.minX.toStringAsFixed(1)} to ${bounds.maxX.toStringAsFixed(1)})');
    debugPrint(
        '  Target visible: ${targetVisibleRangeX.toStringAsFixed(1)} X-units (${dataPointsToShow.toInt()} points)');
    debugPrint(
      '  Calculated zoom: ${calculatedZoom.toStringAsFixed(3)} (${dataRangeX.toStringAsFixed(1)} / ${targetVisibleRangeX.toStringAsFixed(1)})',
    );
    debugPrint(
        '  Desired window: ${windowStart.toStringAsFixed(1)} to ${windowEnd.toStringAsFixed(1)}');
    debugPrint(
        '  Clamped window: ${clampedWindowStart.toStringAsFixed(1)} to ${windowEnd.toStringAsFixed(1)}');
    debugPrint('  Pan offset: ${panOffsetX.toStringAsFixed(1)} px');

    // SAFETY: Validate final pan offset (must be finite and reasonable)
    if (!panOffsetX.isFinite) {
      return null;
    }

    // SAFETY: Prevent extreme pan values that could cause rendering issues
    final maxReasonablePan =
        chartRect.width * 100.0; // Allow larger pans for streaming
    if (panOffsetX.abs() > maxReasonablePan) return null;

    // Return the new zoom/pan state with BOTH zoom and pan updated
    return currentZoomState.copyWith(
        zoomLevelX: clampedZoomX,
        panOffset: Offset(panOffsetX, currentZoomState.panOffset.dy));
  }

  /// Animates zoom level changes for smooth transitions.
  ///
  /// Parameters:
  /// - [newZoomX]: Target zoom level for X axis
  /// - [newZoomY]: Target zoom level for Y axis
  /// - [onComplete]: Optional callback when animation completes
  void _animateZoom(
      {required double newZoomX,
      required double newZoomY,
      VoidCallback? onComplete}) {
    if (_zoomAnimationController == null) {
      // Fallback: instant zoom if no animation controller
      final currentZoomState = _interactionStateNotifier.value.zoomPanState;
      final newZoomState =
          currentZoomState.copyWith(zoomLevelX: newZoomX, zoomLevelY: newZoomY);
      _interactionStateNotifier.value =
          _interactionStateNotifier.value.copyWith(zoomPanState: newZoomState);
      onComplete?.call();
      return;
    }

    // Get current zoom levels
    final currentZoomState = _interactionStateNotifier.value.zoomPanState;
    final currentZoomX = currentZoomState.zoomLevelX;
    final currentZoomY = currentZoomState.zoomLevelY;

    // Create tween animations
    _zoomAnimationX = Tween<double>(
      begin: currentZoomX,
      end: newZoomX,
    ).animate(CurvedAnimation(
        parent: _zoomAnimationController!, curve: Curves.easeOut));

    _zoomAnimationY = Tween<double>(
      begin: currentZoomY,
      end: newZoomY,
    ).animate(CurvedAnimation(
        parent: _zoomAnimationController!, curve: Curves.easeOut));

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
  void _animatePan({required Offset newPanOffset, VoidCallback? onComplete}) {
    if (_panAnimationController == null) {
      // Fallback: instant pan if no animation controller
      final currentZoomState = _interactionStateNotifier.value.zoomPanState;
      final newZoomState = currentZoomState.copyWith(panOffset: newPanOffset);
      _interactionStateNotifier.value =
          _interactionStateNotifier.value.copyWith(zoomPanState: newZoomState);
      onComplete?.call();
      return;
    }

    // Get current pan offset
    final currentZoomState = _interactionStateNotifier.value.zoomPanState;
    final currentPanOffset = currentZoomState.panOffset;

    // Create tween animation
    _panAnimation = Tween<Offset>(
      begin: currentPanOffset,
      end: newPanOffset,
    ).animate(CurvedAnimation(
        parent: _panAnimationController!, curve: Curves.easeOut));

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
        _interactionStateNotifier.value =
            _interactionStateNotifier.value.copyWith(
          isTooltipVisible: false,
          tooltipPosition: null,
          tooltipDataPoint: null,
        );
      }
    });
  }

  /// Safely schedules a setState call after the current AND next frame complete.
  ///
  /// This is CRITICAL for interaction handlers (onHover, onPointerMove, etc.)
  /// because they are called during Flutter's hit testing phase. Calling setState
  /// during hit testing causes rendering pipeline corruption.
  ///
  /// CRITICAL INSIGHT: We need to wait for TWO frames:
  /// 1. Current frame's post-frame callback - exits the current frame
  /// 2. Next frame's post-frame callback - ensures we're truly past all hit testing
  ///
  /// Why single post-frame or microtask doesn't work:
  /// - Single post-frame: Still in same frame when MouseTracker is updating
  /// - Microtask: Executes before next frame, can still hit MouseTracker updates
  /// - Double post-frame: Guarantees we're in a completely new frame context
  ///
  /// By using two post-frame callbacks, we ensure:
  /// 1. Current frame completes entirely (build → layout → paint → post-frame)
  /// 2. Mouse tracking updates finish cleanly
  /// 3. Next frame begins and completes
  // ==================== BUILD METHOD ====================

  @override
  Widget build(BuildContext context) {
    // Get effective theme
    final effectiveTheme = widget.theme ?? ChartTheme.defaultLight;

    // Get effective axis configurations
    // NOTE: Y-axis should default to left position for standard charts
    final effectiveXAxis = widget.xAxis ?? LegacyAxisConfig.defaults();
    final effectiveYAxis = widget.yAxis ??
        LegacyAxisConfig.defaults().copyWith(axisPosition: AxisPosition.left);

    // Get all series (widget series + controller series)
    final allSeries = _getAllSeries();

    // Get all annotations (widget annotations + controller annotations)
    final allAnnotations = _getAllAnnotations();

    // Build the chart widget
    // CRITICAL: Wrap CustomPaint with ValueListenableBuilder so it rebuilds when zoom/pan changes
    // Compute original data bounds once (preliminary) to avoid scanning series
    final preliminaryBounds = _calculatePreliminaryBounds(allSeries);

    Widget chartWidget = ValueListenableBuilder<InteractionState>(
      valueListenable: _interactionStateNotifier,
      builder: (context, interactionState, child) {
        // RepaintBoundary reduces the area that needs to be composited
        // when the chart repaints (helpful during zoom/pan animations).
        return RepaintBoundary(
          child: CustomPaint(
            painter: _BravenChartPainter(
              chartType: widget.chartType,
              lineStyle: widget.lineStyle,
              series: allSeries,
              theme: effectiveTheme,
              xAxis: effectiveXAxis,
              yAxis: effectiveYAxis,
              annotations: [], // Chart painter doesn't render annotations
              zoomPanState: interactionState.zoomPanState,
              multiAxisConfig: widget.multiAxisConfig,
              // CRITICAL FIX: Don't use cached originalDataBounds when controller series exist
              // because new points added via controller.addPoint() won't be in the cached bounds.
              // This causes buffered streaming points to fall outside viewport after zoom/pan.
              // For streaming scenarios, we must recalculate bounds on every paint.
              // TODO: Optimize by tracking controller series changes and only invalidating when needed.
              originalDataBounds:
                  _getController() == null ? preliminaryBounds : null,
              // CRITICAL FIX: Pass callback to receive chartRect calculated with ACTUAL render size
              onChartRectCalculated: (Rect chartRect, Size size) {
                // Calculate title offset: difference between Stack size and CustomPaint size
                // CustomPaint is positioned BELOW the title in Stack coordinate space
                // CRITICAL: When scrollbars are present, LayoutBuilder measures FULL size including scrollbars,
                // but scrollbars are OUTSIDE the Stack where overlays are positioned.
                // We must subtract scrollbar dimensions from _cachedStackSize before calculating offset.
                final effectiveStackHeight = _cachedStackSize != null
                    ? (_cachedStackSize!.height - _scrollbarHeightOffset)
                    : 0.0;

                final titleHeight = effectiveStackHeight > 0
                    ? (effectiveStackHeight - size.height)
                    : 0.0;
                final newTitleOffset = Offset(0, titleHeight);

                // Update cached values if changed
                if (_cachedChartRect != chartRect ||
                    _titleOffset != newTitleOffset) {
                  // Use post-frame callback to avoid setState during build
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _cachedChartRect = chartRect;
                        _titleOffset = newTitleOffset;
                      });
                    }
                  });
                }
              },
            ),
            child:
                Container(), // Force size from parent instead of using size parameter
          ),
        );
      },
    );

    // Add annotation overlay if annotations exist
    // CRITICAL: Wrap in ValueListenableBuilder so annotations rebuild when zoom/pan changes
    if (allAnnotations.isNotEmpty) {
      chartWidget = Stack(
        children: [
          chartWidget,
          // Annotation overlay (ValueListenableBuilder for independent rebuilds)
          ValueListenableBuilder<InteractionState>(
            valueListenable: _interactionStateNotifier,
            builder: (context, interactionState, child) {
              return _AnnotationOverlay(
                annotations: allAnnotations,
                interactiveAnnotations: widget.interactiveAnnotations,
                onAnnotationTap: widget.onAnnotationTap,
                onAnnotationDragged: widget.onAnnotationDragged,
                onAnnotationUpdate: (updatedAnnotation) {
                  // Update the annotation in the controller (if it exists there)
                  final controller = _getController();
                  if (controller != null &&
                      controller.getAnnotation(updatedAnnotation.id) != null) {
                    controller.updateAnnotation(
                        updatedAnnotation.id, updatedAnnotation);
                  }

                  // ALSO update series-level annotations (FIX: handle both locations)
                  setState(() {
                    for (final series in widget.series) {
                      final index = series.annotations
                          .indexWhere((a) => a.id == updatedAnnotation.id);
                      if (index != -1) {
                        series.annotations[index] = updatedAnnotation;
                        break; // Found and updated, no need to check other series
                      }
                    }
                  });
                },
                onDragStateChanged: (edge) {
                  setState(() {
                    _annotationDraggingEdge = edge;
                  });
                },
                series: _getAllSeries(),
                chartRect: _cachedChartRect,
                titleOffset: _titleOffset,
                zoomPanState: interactionState.zoomPanState,
                dataToScreenPoint: _dataToScreenPoint,
              );
            },
          ),
        ],
      );
    }

    // Wrap with dimensions if specified
    if (widget.width != null || widget.height != null) {
      chartWidget = SizedBox(
          width: widget.width, height: widget.height, child: chartWidget);
    }

    // Add title/subtitle if provided
    if (widget.title != null || widget.subtitle != null) {
      final children = <Widget>[];

      if (widget.title != null) {
        children.add(
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(widget.title!,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
          ),
        );
      }

      if (widget.subtitle != null) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(widget.subtitle!,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center),
          ),
        );
      }

      children.add(Flexible(child: chartWidget));

      chartWidget = Column(mainAxisSize: MainAxisSize.min, children: children);
    }

    // Add scrollbars if enabled (T050-T055: User Story 1 - Dual-purpose scrollbars)
    // Scrollbars positioned OUTSIDE chart canvas for clear separation of concerns
    // CRITICAL: Track scrollbar dimensions for coordinate transformation offset correction
    // CRITICAL FIX: Wrap scrollbar creation in ValueListenableBuilder so handle resizes when zoom/pan changes
    if (widget.interactionConfig != null) {
      final showX = widget.interactionConfig!.showXScrollbar;
      final showY = widget.interactionConfig!.showYScrollbar;

      if (showX || showY) {
        chartWidget = ValueListenableBuilder<InteractionState>(
          valueListenable: _interactionStateNotifier,
          builder: (context, interactionState, child) {
            // CRITICAL FIX: Calculate TWO separate bounds for scrollbar
            // 1. ORIGINAL data bounds (no zoom/pan) - for dataRange (full range)
            // 2. CURRENT visible bounds (with zoom/pan) - for viewportRange (what's visible)
            final originalDataBounds = _calculatePreliminaryBounds(allSeries);
            final visibleDataBounds = _calculateDataBounds(allSeries,
                chartRect: _cachedChartRect, includePadding: false);

            // dataRange = FULL original data range (constant regardless of zoom/pan)
            final xDataRange = DataRange(
                min: originalDataBounds.minX, max: originalDataBounds.maxX);
            final yDataRange = DataRange(
                min: originalDataBounds.minY, max: originalDataBounds.maxY);

            // viewportRange = CURRENT visible range (changes with zoom/pan)
            final xViewportRange = DataRange(
                min: visibleDataBounds.minX, max: visibleDataBounds.maxX);
            final yViewportRange = DataRange(
                min: visibleDataBounds.minY, max: visibleDataBounds.maxY);

            // Get scrollbar theme
            final scrollbarTheme = effectiveTheme.scrollbarTheme;

            // Track X-scrollbar height for coordinate offset correction
            _scrollbarHeightOffset =
                showX ? scrollbarTheme.xAxisScrollbar.thickness : 0.0;

            // Build scrollbar layout aligned with chart viewport (Issue #1 fix)
            // Strategy: Add padding to chart for scrollbar space, then overlay scrollbars using Stack
            Widget chartWithScrollbars = child!;

            // Get chart rect for positioning calculations
            final chartRect = _cachedChartRect;

            // Only apply alignment if we have a valid chart rect
            if (chartRect != null && (showX || showY)) {
              // Calculate padding values from chart rect
              // chartRect is Rect.fromLTWH(left, top, width, height)
              final leftPad = chartRect.left;
              final topPad = chartRect.top;

              // Add padding to chart to make room for scrollbars (so they don't overlap axes)
              final paddedChart = Padding(
                padding: EdgeInsets.only(
                  right: showY ? scrollbarTheme.yAxisScrollbar.thickness : 0.0,
                  bottom: showX ? scrollbarTheme.xAxisScrollbar.thickness : 0.0,
                ),
                child: child,
              );

              // Build list of scrollbar overlays
              final List<Widget> scrollbarOverlays = [];

              // Add X scrollbar (horizontal, bottom, aligned with chart rect)
              if (showX) {
                scrollbarOverlays.add(
                  Positioned(
                    left: leftPad,
                    right: 0,
                    bottom: 0,
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: showY
                              ? scrollbarTheme.yAxisScrollbar.thickness
                              : 0.0),
                      child: SizedBox(
                        height: scrollbarTheme.xAxisScrollbar.thickness,
                        child: ChartScrollbar(
                          axis: Axis.horizontal,
                          dataRange: xDataRange,
                          viewportRange: xViewportRange,
                          onPixelDeltaChanged: (pixelDelta, interaction) {
                            _onScrollbarPixelDelta(pixelDelta, interaction,
                                isXAxis: true);
                          },
                          theme: scrollbarTheme.xAxisScrollbar,
                        ),
                      ),
                    ),
                  ),
                );
              }

              // Add Y scrollbar (vertical, right, aligned with chart rect)
              if (showY) {
                scrollbarOverlays.add(
                  Positioned(
                    top: topPad,
                    right: 0,
                    bottom: 0,
                    child: Padding(
                      padding: EdgeInsets.only(
                          bottom: showX
                              ? scrollbarTheme.xAxisScrollbar.thickness
                              : 0.0),
                      child: SizedBox(
                        width: scrollbarTheme.yAxisScrollbar.thickness,
                        child: ChartScrollbar(
                          axis: Axis.vertical,
                          dataRange: yDataRange,
                          viewportRange: yViewportRange,
                          onPixelDeltaChanged: (pixelDelta, interaction) {
                            _onScrollbarPixelDelta(pixelDelta, interaction,
                                isXAxis: false);
                          },
                          theme: scrollbarTheme.yAxisScrollbar,
                        ),
                      ),
                    ),
                  ),
                );
              }

              // Overlay scrollbars on top of padded chart using Stack
              chartWithScrollbars =
                  Stack(children: [paddedChart, ...scrollbarOverlays]);
            } else {
              // Fallback: No chart rect available, use original full-width layout
              // Add Y scrollbar (vertical, on right side)
              if (showY) {
                chartWithScrollbars = Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: chartWithScrollbars),
                    SizedBox(
                      width: scrollbarTheme.yAxisScrollbar.thickness,
                      child: ChartScrollbar(
                        axis: Axis.vertical,
                        dataRange: yDataRange,
                        viewportRange: yViewportRange,
                        onPixelDeltaChanged: (pixelDelta, interaction) {
                          _onScrollbarPixelDelta(pixelDelta, interaction,
                              isXAxis: false);
                        },
                        theme: scrollbarTheme.yAxisScrollbar,
                      ),
                    ),
                  ],
                );
              }

              // Add X scrollbar (horizontal, on bottom)
              if (showX) {
                chartWithScrollbars = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: chartWithScrollbars),
                    SizedBox(
                      height: scrollbarTheme.xAxisScrollbar.thickness,
                      child: ChartScrollbar(
                        axis: Axis.horizontal,
                        dataRange: xDataRange,
                        viewportRange: xViewportRange,
                        onPixelDeltaChanged: (pixelDelta, interaction) {
                          _onScrollbarPixelDelta(pixelDelta, interaction,
                              isXAxis: true);
                        },
                        theme: scrollbarTheme.xAxisScrollbar,
                      ),
                    ),
                  ],
                );
              }
            }

            return chartWithScrollbars;
          },
          child: chartWidget,
        );
      } else {
        // No scrollbars: reset offset to zero
        _scrollbarHeightOffset = 0.0;
      }
    } else {
      // Interaction disabled: reset offset to zero
      _scrollbarHeightOffset = 0.0;
    }

    // Wrap with mode-dependent interaction system (T019, T021: FR-005, Constitution II)
    // Uses ValueListenableBuilder to rebuild only when mode changes (no setState needed)
    // CRITICAL: Dual-mode interaction handling (T030: FR-004 + FR-005)
    // FR-004: Detect first interaction to trigger pause
    // FR-005: Disable full interaction system in streaming mode
    if (widget.interactionConfig != null && widget.interactionConfig!.enabled) {
      chartWidget = ValueListenableBuilder<ChartMode>(
        valueListenable: _chartMode,
        builder: (context, currentMode, child) {
          debugPrint('🔵 ValueListenableBuilder build - mode=$currentMode');

          // FIX: When streamingConfig is null, chart is ALWAYS in interactive mode (line 863)
          // So we should never hit the fallback - if we do, it's a bug.
          // The correct logic: wrap with full interaction system when in interactive mode.
          if (currentMode == ChartMode.interactive) {
            debugPrint('🔵 Returning _wrapWithInteractionSystem');
            return _wrapWithInteractionSystem(child!);
          }

          // Streaming mode: Minimal interaction detector for FR-004 (pause on first interaction)
          // Wraps chart with lightweight listeners that ONLY trigger mode switch
          // Full interaction system disabled per FR-005
          // CRITICAL: This branch only executes when streamingConfig exists
          if (widget.streamingConfig != null &&
              currentMode == ChartMode.streaming) {
            return _wrapWithStreamingModeInteractionDetector(child!);
          }

          // Fallback: Should never reach here unless mode/config mismatch
          // If no streamingConfig, mode should always be interactive (see line 863)
          // Log error and wrap with interaction system as safeguard
          debugPrint(
              '🔴 WARNING: Unexpected chart mode state: $currentMode with streamingConfig=${widget.streamingConfig != null}');
          debugPrint(
              '🟢 Applying fallback: wrapping with FULL interaction system');
          return _wrapWithInteractionSystem(child!);
        },
        child: chartWidget,
      );
    }

    // Disable browser context menu on web by wrapping entire chart
    // This ensures our custom annotation menu shows instead of browser menu
    if (kIsWeb) {
      BrowserContextMenu.disableContextMenu();
    }

    // Wrap entire chart in MouseRegion to maintain resize cursor during annotation drag
    // Choose cursor based on which edge is being dragged
    MouseCursor cursor = MouseCursor.defer;
    if (_annotationDraggingEdge == 'left' ||
        _annotationDraggingEdge == 'right') {
      cursor = SystemMouseCursors.resizeLeftRight;
    } else if (_annotationDraggingEdge == 'top' ||
        _annotationDraggingEdge == 'bottom') {
      cursor = SystemMouseCursors.resizeUpDown;
    }

    return MouseRegion(
      cursor: cursor,
      child: chartWidget,
    );
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

        // CRITICAL FIX: Do NOT calculate chartRect here with LayoutBuilder size.
        // LayoutBuilder sees the full widget size including title/subtitle (537px height),
        // but CustomPaint renders with a smaller size (493px, excluding title).
        // This size mismatch causes proportional coordinate transformation errors.
        // Cache only the Stack size - chartRect will be calculated with actual render size.
        _cachedStackSize = size;
        // chartRect will be set by painter callback with the CORRECT size

        // Use cached chartRect if available (set by previous paint), otherwise return child without interaction
        final chartRect = _cachedChartRect;
        if (chartRect == null) {
          // First build before painter has run - return child without interaction overlays
          // Painter will set _cachedChartRect and trigger rebuild
          return child;
        }

        // Build the full interaction stack
        Widget interactiveWidget = Stack(
          children: [
            // Base chart
            child,

            // Crosshair overlay (ValueListenableBuilder for independent rebuilds)
            // Split into TWO layers: lines (clipped) + labels (unclipped)
            if (config.crosshair.enabled)
              ValueListenableBuilder<InteractionState>(
                valueListenable: _interactionStateNotifier,
                builder: (context, interactionState, child) {
                  if (!interactionState.isCrosshairVisible ||
                      interactionState.crosshairPosition == null ||
                      !interactionState.crosshairPosition!.dx.isFinite ||
                      !interactionState.crosshairPosition!.dy.isFinite) {
                    return const SizedBox.shrink();
                  }

                  // Translate chartRect from CustomPaint space to Stack space
                  final stackChartRect =
                      chartRect.translate(_titleOffset.dx, _titleOffset.dy);

                  // Calculate shared painter data
                  final nearestPoint = interactionState.hoveredPoint != null &&
                          interactionState.hoveredPoint!.containsKey('x') &&
                          interactionState.hoveredPoint!.containsKey('y')
                      ? () {
                          // Transform DATA coordinates to SCREEN coordinates with current zoom/pan
                          final dataX =
                              (interactionState.hoveredPoint!['x'] as num?)
                                      ?.toDouble() ??
                                  0;
                          final dataY =
                              (interactionState.hoveredPoint!['y'] as num?)
                                      ?.toDouble() ??
                                  0;

                          final allSeries = _getAllSeries();
                          if (allSeries.isEmpty) return null;

                          final bounds = _calculateDataBounds(allSeries,
                              chartRect: chartRect);
                          final point = ChartDataPoint(x: dataX, y: dataY);
                          final screenPosBase =
                              _dataToScreenPoint(point, chartRect, bounds);

                          // CRITICAL: Add titleOffset for crosshair snap point (same as tooltip)
                          final screenPos = screenPosBase + _titleOffset;

                          // Validate coordinates are finite and within reasonable bounds
                          if (screenPos.dx.isFinite && screenPos.dy.isFinite) {
                            return screenPos;
                          }
                          return null;
                        }()
                      : null;

                  final dataBounds = () {
                    final allSeries = _getAllSeries();
                    if (allSeries.isEmpty) return null;
                    return _calculateDataBounds(allSeries,
                        chartRect: chartRect);
                  }();

                  // LAYER 1: Crosshair LINES (clipped to chart area to prevent drawing over scrollbars)
                  // LAYER 2: Coordinate LABELS (unclipped so they remain visible at edges)
                  // CRITICAL: Labels layer wrapped in IgnorePointer to allow scrollbar interaction
                  return Stack(
                    children: [
                      // Layer 1: Clipped crosshair lines
                      Positioned.fill(
                        child: ClipRect(
                          clipper: ChartAreaClipper(stackChartRect),
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: _CrosshairLinesPainter(
                                position: interactionState.crosshairPosition!,
                                config: config.crosshair,
                                nearestPoint: nearestPoint,
                                chartSize: Size.infinite,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Layer 2: Unclipped coordinate labels (pointer-transparent)
                      // CRITICAL: Positioned must be direct child of Stack, IgnorePointer goes inside
                      Positioned.fill(
                        child: IgnorePointer(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: _CrosshairLabelsPainter(
                                position: interactionState.crosshairPosition!,
                                config: config.crosshair,
                                dataBounds: dataBounds,
                                chartRect: stackChartRect,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

            // Tooltip overlay (ValueListenableBuilder for independent rebuilds)
            ValueListenableBuilder<InteractionState>(
              valueListenable: _interactionStateNotifier,
              builder: (context, interactionState, child) {
                final tooltip = _buildTooltipOverlay();
                return tooltip ?? const SizedBox.shrink();
              },
            ),
          ],
        );

        // Wrap in MouseRegion for hover detection
        interactiveWidget = MouseRegion(
          opaque:
              false, // Allow child MouseRegions (annotation handles) to receive events
          onEnter: (_) {
            // Mouse entered chart area - request focus for keyboard interaction
            if (config.keyboard.enabled && !_focusNode.hasFocus) {
              _focusNode.requestFocus();
            }
          },
          onExit: (_) {
            // Only hide crosshair, NOT tooltip
            // Tooltip persists after mouse exits and hides via timer
            _interactionStateNotifier.value = _interactionStateNotifier.value
                .copyWith(isCrosshairVisible: false, crosshairPosition: null);

            // Invoke hover callback with null (exited)
            const exitPosition =
                Offset.zero; // Position doesn't matter for exit
            config.onDataPointHover?.call(null, exitPosition);
          },
          onHover: (event) {
            // NOTE: Hover does NOT pause streaming - only intentional interactions do
            // (click, zoom, pan, scroll). This prevents accidental stream pausing from
            // casual mouse movement over the chart.
            //
            // However, if already in interactive mode, hover DOES reset the timer (T043: FR-008)
            // This keeps the chart paused while user is actively hovering/exploring
            if (_chartMode.value == ChartMode.interactive) {
              _resetAutoResumeTimer();
            }

            // Throttle the ENTIRE hover processing (calculations + state update)
            _processHoverThrottled(event.localPosition, config);
          },
          child: interactiveWidget,
        );

        // CRITICAL FIX: Wrap with GestureDetector BEFORE Listener
        // GestureDetector must be OUTER layer to receive events first for right-click handling
        // Widget tree order: GestureDetector → Listener → MouseRegion → chart
        // This ensures right-clicks reach GestureDetector before Listener can interfere
        interactiveWidget = GestureDetector(
          // CRITICAL: Use opaque behavior so GestureDetector claims ALL events
          // This prevents Listener below from participating in hit testing for right-clicks
          behavior: HitTestBehavior.opaque,

          // Handle right-click for annotation context menu
          onSecondaryTapDown: (details) {
            debugPrint(
                '🔴 GestureDetector.onSecondaryTapDown FIRED at ${details.localPosition}');
            debugPrint(
                '🔴 widget.interactiveAnnotations = ${widget.interactiveAnnotations}');
            debugPrint('🔴 mounted = $mounted');
            _handleRightClick(details);
          },
          // Consume the secondary tap to prevent browser context menu
          onSecondaryTap: () {
            debugPrint('🔴 GestureDetector.onSecondaryTap FIRED');
            // Event consumed - prevents default browser context menu
          },

          // Handle tap for selection
          onTapDown: (details) {
            // T030: Pause streaming on tap (FR-004) or reset timer if already paused (FR-008)
            _pauseStreaming();

            // Handle selection if enabled
            if (config.enableSelection) {
              final nearestPointData =
                  _findNearestDataPoint(details.localPosition);
              if (nearestPointData != null) {
                final point = _mapToDataPoint(nearestPointData);

                // Add to selected points
                final updatedSelection = List<Map<String, dynamic>>.from(
                    _interactionStateNotifier.value.selectedPoints);
                updatedSelection.add(nearestPointData);

                _interactionStateNotifier.value =
                    _interactionStateNotifier.value.copyWith(
                  selectedPoints: updatedSelection,
                  focusedPoint: nearestPointData,
                );

                // Invoke tap callback
                config.onDataPointTap?.call(point, details.localPosition);

                // Invoke selection callback
                final selectedPointsList = _interactionStateNotifier
                    .value.selectedPoints
                    .map((data) => _mapToDataPoint(data))
                    .toList();
                config.onSelectionChanged?.call(selectedPointsList);
              }
            }
          },

          // Long press handling
          onLongPressStart: (details) {
            final nearestPointData =
                _findNearestDataPoint(details.localPosition);
            if (nearestPointData != null) {
              final point = _mapToDataPoint(nearestPointData);
              config.onDataPointLongPress?.call(point, details.localPosition);
            }
          },

          // Use scale gestures ONLY for pinch-to-zoom (multi-touch)
          // Pan is handled separately via middle-mouse button in Listener widget below
          onScaleStart: config.enableZoom && _zoomPanController != null
              ? (details) {
                  // T030: Pause streaming on zoom gesture (FR-004)
                  _pauseStreaming();

                  // Track initial state for zoom gestures
                }
              : null,

          onScaleUpdate: config.enableZoom && _zoomPanController != null
              ? (details) {
                  // ONLY handle pinch-to-zoom here (multi-touch zoom)
                  // Pan is handled separately via middle-mouse in Listener widget below

                  // Handle pinch-to-zoom (when scale changes with multi-touch)
                  if (details.scale != 1.0 && details.pointerCount >= 2) {
                    // T043: Reset timer on continued zoom gestures (FR-008)
                    _resetAutoResumeTimer();

                    final ZoomPanState newZoomPanState = _zoomPanController!
                        .zoom(_interactionStateNotifier.value.zoomPanState,
                            zoomFactor: details.scale,
                            focalPoint: details.focalPoint);

                    // Update state
                    _interactionStateNotifier.value = _interactionStateNotifier
                        .value
                        .copyWith(zoomPanState: newZoomPanState);

                    // Invoke zoom callback
                    config.onZoomChanged?.call(
                        newZoomPanState.zoomLevelX, newZoomPanState.zoomLevelY);

                    // Invoke viewport callback
                    _invokeViewportCallback();
                  }
                }
              : null,

          onScaleEnd: config.enableZoom && _zoomPanController != null
              ? (details) {
                  // Zoom gesture ended - no cleanup needed
                }
              : null,

          // Double-tap to reset zoom
          onDoubleTap: config.enableZoom && _zoomPanController != null
              ? () {
                  final newZoomPanState = _zoomPanController!
                      .resetZoom(_interactionStateNotifier.value.zoomPanState);

                  _interactionStateNotifier.value = _interactionStateNotifier
                      .value
                      .copyWith(zoomPanState: newZoomPanState);

                  // Invoke zoom callback (reset to 1.0, 1.0)
                  config.onZoomChanged?.call(1.0, 1.0);

                  // Invoke viewport callback
                  _invokeViewportCallback();
                }
              : null,

          // CRITICAL: Listener is now CHILD of GestureDetector (inner layer)
          // This allows GestureDetector to handle right-clicks BEFORE Listener sees the event
          child: Listener(
            // CRITICAL: Use opaque + early return instead of translucent
            // opaque means: Listener handles events it responds to (middle-mouse), blocks others from below
            // BUT with early return for non-middle-mouse, those events don't actually get handled
            // This allows GestureDetector above to handle them instead
            behavior: HitTestBehavior.opaque,

            // Handle scroll events with modifier keys
            onPointerSignal: (signal) {
              if (signal is PointerScrollEvent) {
                // Use manual state tracking for modifiers (web-compatible)
                // HardwareKeyboard.instance doesn't work reliably in Flutter Web
                final isShiftPressed = _isShiftPressed;

                if (config.enableZoom &&
                    _zoomPanController != null &&
                    isShiftPressed) {
                  // T030: Pause streaming on zoom (FR-004) or reset timer if already paused (FR-008)
                  _pauseStreaming();

                  // SHIFT + Scroll → Zoom at cursor position
                  final scrollDelta = signal.scrollDelta.dy;
                  // Zoom in when scrolling up (negative delta), zoom out when scrolling down
                  final zoomFactor = scrollDelta < 0 ? 1.1 : 0.9;

                  final oldState = _interactionStateNotifier.value.zoomPanState;
                  final newZoomPanState = _zoomPanController!.zoom(oldState,
                      zoomFactor: zoomFactor, focalPoint: signal.localPosition);

                  // CRITICAL FIX: Apply state immediately, don't throttle zoom/pan!
                  // Throttling these makes interactions feel broken
                  _interactionStateNotifier.value = _interactionStateNotifier
                      .value
                      .copyWith(zoomPanState: newZoomPanState);

                  // Invoke zoom callback with NEW state
                  config.onZoomChanged?.call(
                      newZoomPanState.zoomLevelX, newZoomPanState.zoomLevelY);

                  // Invoke viewport callback (visible bounds changed due to zoom)
                  _invokeViewportCallback();
                }
                // If no SHIFT modifier, don't handle - allows default page scroll
                // This is CRITICAL for web UX - page must scroll normally without modifier
              }
            },

            // Handle middle-mouse button pan (PRIMARY pan method)
            onPointerDown: (event) {
              debugPrint(
                  '🟣 MAIN CHART Listener.onPointerDown - button=${event.buttons}');
              // CRITICAL: Only handle middle mouse button
              // Let other buttons (left=1, right=2) pass through to GestureDetector below
              if (event.buttons != kMiddleMouseButton) {
                debugPrint(
                    '   ➡️ NOT middle button - returning early to pass through');
                return;
              }

              debugPrint('   ✅ Middle button - HANDLING pan');
              if (config.enablePan) {
                // T030: Pause streaming on pan start (FR-004) or reset timer if already paused (FR-008)
                _pauseStreaming();

                _isPanningWithMiddleMouse = true;
                _panStartPosition = event.localPosition;
              }
            },

            onPointerMove: (event) {
              if (_isPanningWithMiddleMouse &&
                  _panStartPosition != null &&
                  _zoomPanController != null) {
                // Reset timer on continued panning (FR-008)
                _resetAutoResumeTimer();

                final delta = event.localPosition - _panStartPosition!;

                final newZoomPanState = _zoomPanController!
                    .pan(_interactionStateNotifier.value.zoomPanState, delta);

                // CRITICAL: Clamp pan offset to prevent panning beyond data boundaries
                final clampedState = _clampPanOffset(newZoomPanState);

                // CRITICAL FIX: Apply state immediately, don't throttle zoom/pan!
                _interactionStateNotifier.value = _interactionStateNotifier
                    .value
                    .copyWith(zoomPanState: clampedState);

                _panStartPosition = event.localPosition;

                // Invoke pan callback with NEW state
                config.onPanChanged?.call(clampedState.panOffset);

                // Invoke viewport callback
                _invokeViewportCallback();
              }
            },

            onPointerUp: (event) {
              if (_isPanningWithMiddleMouse) {
                _isPanningWithMiddleMouse = false;
                _panStartPosition = null;
              }
            },

            child: interactiveWidget,
          ),
        ); // End of GestureDetector (wraps Listener)

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
              if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
                  event.logicalKey == LogicalKeyboardKey.shiftRight) {
                _isShiftPressed =
                    event is KeyDownEvent || event is KeyRepeatEvent;
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
                    'seriesId': series.id
                  });
                }
              }

              // CRITICAL FIX #5: INTERCEPT ZOOM KEYS - Zoom without pan offset (centered on data)
              // Keyboard zoom should zoom centered on the data center, NOT create pan offset like mouse zoom
              final key = event.logicalKey;
              if (widget.interactionConfig != null &&
                  widget.interactionConfig!.enableZoom) {
                if (key == LogicalKeyboardKey.numpadAdd ||
                    key == LogicalKeyboardKey.add ||
                    key == LogicalKeyboardKey.equal) {
                  // T030: Pause streaming on keyboard zoom (FR-004) or reset timer if already paused (FR-008)
                  _pauseStreaming();

                  // Zoom IN centered on data (no pan offset change) with SMOOTH ANIMATION
                  final currentZoomState =
                      _interactionStateNotifier.value.zoomPanState;
                  final newZoomX = (currentZoomState.zoomLevelX * 1.2).clamp(
                      currentZoomState.minZoomLevel,
                      currentZoomState.maxZoomLevel);
                  final newZoomY = (currentZoomState.zoomLevelY * 1.2).clamp(
                      currentZoomState.minZoomLevel,
                      currentZoomState.maxZoomLevel);

                  _animateZoom(
                    newZoomX: newZoomX,
                    newZoomY: newZoomY,
                    onComplete: () {
                      widget.interactionConfig!.onZoomChanged?.call(
                        _interactionStateNotifier.value.zoomPanState.zoomLevelX,
                        _interactionStateNotifier.value.zoomPanState.zoomLevelY,
                      );
                      _invokeViewportCallback();
                    },
                  );

                  return KeyEventResult.handled;
                } else if (key == LogicalKeyboardKey.minus ||
                    key == LogicalKeyboardKey.numpadSubtract) {
                  // T030: Pause streaming on keyboard zoom (FR-004) or reset timer if already paused (FR-008)
                  _pauseStreaming();

                  // Zoom OUT centered on data (no pan offset change) with SMOOTH ANIMATION
                  final currentZoomState =
                      _interactionStateNotifier.value.zoomPanState;
                  final newZoomX = (currentZoomState.zoomLevelX * 0.83333)
                      .clamp(currentZoomState.minZoomLevel,
                          currentZoomState.maxZoomLevel);
                  final newZoomY = (currentZoomState.zoomLevelY * 0.83333)
                      .clamp(currentZoomState.minZoomLevel,
                          currentZoomState.maxZoomLevel);

                  _animateZoom(
                    newZoomX: newZoomX,
                    newZoomY: newZoomY,
                    onComplete: () {
                      widget.interactionConfig!.onZoomChanged?.call(
                        _interactionStateNotifier.value.zoomPanState.zoomLevelX,
                        _interactionStateNotifier.value.zoomPanState.zoomLevelY,
                      );
                      _invokeViewportCallback();
                    },
                  );

                  return KeyEventResult.handled;
                }
              }

              // INTERCEPT ARROW KEYS for animated panning
              // CRITICAL: Distinguish KeyDownEvent (first press) from KeyRepeatEvent (held down)
              if (widget.interactionConfig != null &&
                  widget.interactionConfig!.enablePan) {
                if (key == LogicalKeyboardKey.arrowLeft ||
                    key == LogicalKeyboardKey.arrowRight ||
                    key == LogicalKeyboardKey.arrowUp ||
                    key == LogicalKeyboardKey.arrowDown) {
                  // T030: Pause streaming on keyboard pan (FR-004) or reset timer if already paused (FR-008)
                  _pauseStreaming();

                  // Calculate new pan offset based on arrow direction
                  final currentPanOffset =
                      _interactionStateNotifier.value.zoomPanState.panOffset;
                  const panAmount = 50.0; // Same as KeyboardHandler default

                  Offset newPanOffset;
                  if (key == LogicalKeyboardKey.arrowLeft) {
                    newPanOffset = Offset(
                        currentPanOffset.dx - panAmount, currentPanOffset.dy);
                  } else if (key == LogicalKeyboardKey.arrowRight) {
                    newPanOffset = Offset(
                        currentPanOffset.dx + panAmount, currentPanOffset.dy);
                  } else if (key == LogicalKeyboardKey.arrowUp) {
                    newPanOffset = Offset(
                        currentPanOffset.dx, currentPanOffset.dy - panAmount);
                  } else {
                    // arrowDown
                    newPanOffset = Offset(
                        currentPanOffset.dx, currentPanOffset.dy + panAmount);
                  }

                  // DIFFERENTIATE: First press (smooth animation) vs held down (instant pan)
                  if (event is KeyDownEvent) {
                    // First press: Trigger smooth 250ms animation
                    _animatePan(
                      newPanOffset: newPanOffset,
                      onComplete: () {
                        widget.interactionConfig!.onPanChanged?.call(
                            _interactionStateNotifier
                                .value.zoomPanState.panOffset);
                        _invokeViewportCallback();
                      },
                    );
                  } else if (event is KeyRepeatEvent) {
                    // Key held down: Apply pan offset directly for smooth continuous movement
                    // This prevents animation stuttering from rapid repeat events (~30ms intervals)
                    final currentZoomState =
                        _interactionStateNotifier.value.zoomPanState;
                    final newZoomState =
                        currentZoomState.copyWith(panOffset: newPanOffset);
                    _interactionStateNotifier.value = _interactionStateNotifier
                        .value
                        .copyWith(zoomPanState: newZoomState);

                    // Invoke callbacks immediately
                    widget.interactionConfig!.onPanChanged?.call(
                        _interactionStateNotifier.value.zoomPanState.panOffset);
                    _invokeViewportCallback();
                  }

                  return KeyEventResult.handled;
                }
              }

              // Process key event through keyboard handler
              final newState = _keyboardHandler!.handleKeyEvent(
                  event, _interactionStateNotifier.value,
                  dataPoints: allDataPoints);

              if (newState != null &&
                  newState != _interactionStateNotifier.value) {
                _interactionStateNotifier.value = newState;

                // If focused point changed, invoke callback
                if (_interactionStateNotifier.value.focusedPoint != null) {
                  final point = _mapToDataPoint(
                      _interactionStateNotifier.value.focusedPoint!);
                  config.onDataPointHover?.call(
                      point,
                      _interactionStateNotifier.value.crosshairPosition ??
                          Offset.zero);
                }

                // If zoom/pan state changed, invoke callbacks
                if (_interactionStateNotifier.value.zoomPanState !=
                    newState.zoomPanState) {
                  config.onZoomChanged?.call(
                    _interactionStateNotifier.value.zoomPanState.zoomLevelX,
                    _interactionStateNotifier.value.zoomPanState.zoomLevelY,
                  );
                  _invokeViewportCallback();
                }

                // If selection changed, invoke callback
                if (_interactionStateNotifier.value.selectedPoints !=
                    newState.selectedPoints) {
                  final selectedPointsList = _interactionStateNotifier
                      .value.selectedPoints
                      .map((data) => _mapToDataPoint(data))
                      .toList();
                  config.onSelectionChanged?.call(selectedPointsList);
                }

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

  /// Wraps the chart with minimal interaction detection in streaming mode (T030: FR-004).
  ///
  /// This is a lightweight detector that exists ONLY to catch the first user interaction
  /// and trigger the streaming → interactive mode transition. Unlike the full interaction
  /// system, this ONLY listens for INTENTIONAL events (clicks, scrolls, gestures) and calls
  /// _pauseStreaming() - no crosshair, no tooltip, no zoom/pan processing.
  ///
  /// **CRITICAL**: Does NOT trigger on hover/mouse movement - only on deliberate user actions:
  /// - Mouse clicks (any button)
  /// - Touch gestures (tap, pan, zoom)
  /// - Scroll wheel events
  /// - Keyboard interactions
  ///
  /// **Purpose**: Resolves FR-004 vs FR-005 conflict:
  /// - FR-004: Must detect first INTENTIONAL interaction to pause streaming
  /// - FR-005: Must disable all interaction handlers in streaming mode
  ///
  /// **Design**: Minimal event detection without full interaction processing.
  Widget _wrapWithStreamingModeInteractionDetector(Widget child) {
    return GestureDetector(
      onTapDown: (_) => _pauseStreaming(), // Click triggers pause (FR-004)
      onScaleStart: (_) =>
          _pauseStreaming(), // Touch pan/zoom triggers pause (FR-004)
      child: Listener(
        onPointerSignal: (_) =>
            _pauseStreaming(), // Scroll triggers pause (FR-004)
        onPointerDown: (_) =>
            _pauseStreaming(), // Any pointer down triggers pause (FR-004)
        child: child,
      ),
    );
  }

  /// Converts a Map<String, dynamic> to a ChartDataPoint.
  ///
  /// Helper for callback invocations that require ChartDataPoint.
  ChartDataPoint _mapToDataPoint(Map<String, dynamic> data) {
    return ChartDataPoint(
        x: (data['x'] as num?)?.toDouble() ?? 0,
        y: (data['y'] as num?)?.toDouble() ?? 0,
        metadata: {...data});
  }

  /// Handles right-click events to show annotation context menu
  void _handleRightClick(TapDownDetails details) {
    debugPrint(
        '🟡 _handleRightClick CALLED - mounted=$mounted, interactiveAnnotations=${widget.interactiveAnnotations}');

    if (!mounted || !widget.interactiveAnnotations) {
      debugPrint(
          '🔴 EARLY RETURN: mounted=$mounted, interactiveAnnotations=${widget.interactiveAnnotations}');
      return;
    }

    debugPrint('🟢 Proceeding to show context menu...');

    // CRITICAL: Subtract title offset because:
    // - GestureDetector is at widget top (includes title)
    // - Annotation Stack is positioned BELOW title in Column
    // - So click Y includes title height, but Stack Y starts after title
    final adjustedLocalPosition = details.localPosition - _titleOffset;

    // Get available series IDs for data-position mode
    final availableSeriesIds = _getAllSeries().map((s) => s.id).toList();
    if (availableSeriesIds.isEmpty) return;

    // Check if right-click hit an existing text annotation (use adjusted position!)
    final clickedTextAnnotation =
        _findAnnotationAtPosition(adjustedLocalPosition);

    // Check if right-click hit an existing point annotation
    final clickedPointAnnotationData =
        _findPointAnnotationAtPosition(adjustedLocalPosition);

    // Detect nearest data point for context determination
    final nearestPoint = _findNearestDataPoint(details.localPosition);

    // Determine context type and data point info
    AnnotationContextType contextType;
    String? targetSeriesId;
    int? targetDataPointIndex;

    // If click is near a data point (within 10px), use point annotation context
    if (nearestPoint != null) {
      final dx = details.localPosition.dx - nearestPoint['screenX'];
      final dy = details.localPosition.dy - nearestPoint['screenY'];
      final distance = sqrt(dx * dx + dy * dy);

      if (distance < 10.0) {
        contextType = AnnotationContextType.pointAnnotation;
        targetSeriesId = nearestPoint['seriesId'] as String;

        // Find the data point index in the series
        final series =
            _getAllSeries().firstWhere((s) => s.id == targetSeriesId);
        final pointX = nearestPoint['x'] as double;
        final pointY = nearestPoint['y'] as double;

        targetDataPointIndex = series.points.indexWhere(
          (p) => p.x == pointX && p.y == pointY,
        );
      } else {
        contextType = AnnotationContextType.textAnnotation;
      }
    } else {
      contextType = AnnotationContextType.textAnnotation;
    }

    // Show context-sensitive menu
    AnnotationContextMenu.show(
      context: context,
      position: details.globalPosition,
      localPosition: adjustedLocalPosition,
      contextType: contextType,
      existingTextAnnotation: clickedTextAnnotation,
      existingPointAnnotation:
          clickedPointAnnotationData?['annotation'] as PointAnnotation?,
      seriesId: targetSeriesId,
      dataPointIndex: targetDataPointIndex,
      availableSeriesIds: availableSeriesIds,
      onSaveTextAnnotation: (annotation) {
        final controller = _getController();
        if (controller != null) {
          if (clickedTextAnnotation != null) {
            // Update existing
            controller.updateAnnotation(annotation.id, annotation);
          } else {
            // Add new
            controller.addAnnotation(annotation);
          }
        }
      },
      onSavePointAnnotation: (annotation) {
        _addPointAnnotationToSeries(annotation);
      },
      onSaveRangeAnnotation: (annotation) {
        final controller = _getController();
        if (controller != null) {
          controller.addAnnotation(annotation);
        }
      },
      onDeleteTextAnnotation: (annotationId) {
        final controller = _getController();
        if (controller != null) {
          controller.removeAnnotation(annotationId);
        }
      },
      onDeletePointAnnotation: (seriesId, annotationId) {
        _removePointAnnotationFromSeries(seriesId, annotationId);
      },
      onDeleteRangeAnnotation: (annotationId) {
        final controller = _getController();
        if (controller != null) {
          controller.removeAnnotation(annotationId);
        }
      },
    );
  }

  /// Finds a TextAnnotation at the given screen position
  TextAnnotation? _findAnnotationAtPosition(Offset position) {
    // Check if click hit any existing text annotation
    final annotations = _getController()?.getAllAnnotations() ?? [];

    for (final annotation in annotations.reversed) {
      // Only check TextAnnotations for hit testing
      if (annotation is! TextAnnotation) continue;

      // Get the annotation bounds (approximate based on text and anchor)
      final annotationPos = annotation.position;

      // Create a hit-test rectangle around the annotation
      // Approximate size - actual size depends on text content and styling
      const approximateWidth = 100.0;
      const approximateHeight = 30.0;

      // Adjust hit rectangle based on anchor point
      final anchorOffset = _getAnchorOffsetForHitTest(annotation.anchor);
      final hitRect = Rect.fromLTWH(
        annotationPos.dx + (anchorOffset.dx * approximateWidth),
        annotationPos.dy + (anchorOffset.dy * approximateHeight),
        approximateWidth,
        approximateHeight,
      );

      if (hitRect.contains(position)) {
        return annotation;
      }
    }

    return null;
  }

  /// Get anchor offset for hit testing (similar to rendering but for Rect creation)
  Offset _getAnchorOffsetForHitTest(AnnotationAnchor anchor) {
    switch (anchor) {
      case AnnotationAnchor.topLeft:
        return const Offset(0, 0);
      case AnnotationAnchor.topCenter:
        return const Offset(-0.5, 0);
      case AnnotationAnchor.topRight:
        return const Offset(-1, 0);
      case AnnotationAnchor.centerLeft:
        return const Offset(0, -0.5);
      case AnnotationAnchor.center:
        return const Offset(-0.5, -0.5);
      case AnnotationAnchor.centerRight:
        return const Offset(-1, -0.5);
      case AnnotationAnchor.bottomLeft:
        return const Offset(0, -1);
      case AnnotationAnchor.bottomCenter:
        return const Offset(-0.5, -1);
      case AnnotationAnchor.bottomRight:
        return const Offset(-1, -1);
    }
  }

  /// Finds a PointAnnotation at the given screen position
  Map<String, dynamic>? _findPointAnnotationAtPosition(Offset position) {
    if (_cachedChartRect == null) return null;

    final chartRect = _cachedChartRect!;
    final bounds = _calculateDataBounds(_getAllSeries(), chartRect: chartRect);

    for (final series in _getAllSeries()) {
      for (final annotation
          in series.annotations.whereType<PointAnnotation>()) {
        // Get the data point this annotation is attached to
        if (annotation.dataPointIndex >= 0 &&
            annotation.dataPointIndex < series.points.length) {
          final point = series.points[annotation.dataPointIndex];

          // Transform to screen coordinates
          final screenPoint = _dataToScreenPoint(point, chartRect, bounds);

          // Apply annotation offset
          final annotationScreenPos = screenPoint + annotation.offset;

          // Hit test with marker size as radius
          final hitRadius = annotation.markerSize +
              4.0; // Add 4px padding for easier clicking
          final dx = position.dx - annotationScreenPos.dx;
          final dy = position.dy - annotationScreenPos.dy;
          final distance = sqrt(dx * dx + dy * dy);

          if (distance <= hitRadius) {
            return {
              'annotation': annotation,
              'seriesId': series.id,
            };
          }
        }
      }
    }

    return null;
  }

  /// Adds a PointAnnotation to the specified series
  void _addPointAnnotationToSeries(PointAnnotation annotation) {
    setState(() {
      final series = _getAllSeries().firstWhere(
        (s) => s.id == annotation.seriesId,
        orElse: () =>
            throw StateError('Series ${annotation.seriesId} not found'),
      );

      // Add or update annotation
      final existingIndex =
          series.annotations.indexWhere((a) => a.id == annotation.id);
      if (existingIndex >= 0) {
        series.annotations[existingIndex] = annotation;
      } else {
        series.annotations.add(annotation);
      }
    });
  }

  /// Removes a PointAnnotation from the specified series
  void _removePointAnnotationFromSeries(String seriesId, String annotationId) {
    setState(() {
      final series = _getAllSeries().firstWhere(
        (s) => s.id == seriesId,
        orElse: () => throw StateError('Series $seriesId not found'),
      );

      series.annotations.removeWhere((a) => a.id == annotationId);
    });
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

    // CRITICAL FIX: Use cached size from LayoutBuilder, not context.size
    // context.size can be incorrect during interaction system initialization
    if (_cachedStackSize == null || _cachedChartRect == null) {
      return null; // Not yet initialized
    }

    final chartRect = _cachedChartRect!;
    final bounds = _calculateDataBounds(allSeries, chartRect: chartRect);

    Map<String, dynamic>? nearestPoint;
    double minDistance = snapRadius;

    // Iterate through all series to find nearest point
    for (final series in allSeries) {
      for (final point in series.points) {
        // Transform data coordinates to screen coordinates (chartRect space)
        final screenPointBase = _dataToScreenPoint(point, chartRect, bounds);

        // CRITICAL: Add titleOffset for hit-test comparison
        // Mouse position is in Stack space, screenPoint needs same adjustment as tooltip/crosshair
        final screenPoint = screenPointBase + _titleOffset;

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
            'screenX': screenPoint
                .dx, // Store screen coordinates for crosshair rendering
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
  /// Returns coordinates in STACK space (includes title offset if present).
  Offset _dataToScreenPoint(
      ChartDataPoint point, Rect chartRect, _DataBounds bounds) {
    final xRange = bounds.maxX - bounds.minX;
    final yRange = bounds.maxY - bounds.minY;

    final xPercent = xRange == 0 ? 0.5 : (point.x - bounds.minX) / xRange;
    final yPercent = yRange == 0 ? 0.5 : (point.y - bounds.minY) / yRange;

    // Calculate position in chart coordinate space
    // CRITICAL: chartRect already contains the axis padding offsets (left, top)
    // These are the same coordinates used by the painter's canvas
    final pixelX = chartRect.left + (xPercent * chartRect.width);
    final pixelY = chartRect.bottom - (yPercent * chartRect.height);

    // CRITICAL COORDINATE SPACE USAGE:
    // - Annotations (Point, Text, Range, etc.): Use this directly (render in same Stack as CustomPaint)
    // - Tooltip/Crosshair: Must ADD _titleOffset after calling this function
    //   (tooltips render differently and need title height adjustment)
    return Offset(pixelX, pixelY);
  }

  /// Calculates the chart rectangle within the widget.
  ///
  /// Same logic as _BravenChartPainter.paint, accounting for margins.
  Rect _calculateChartRect(Size size) {
    // Get effective axis configurations
    // NOTE: Y-axis should default to left position for standard charts
    final effectiveXAxis = widget.xAxis ?? LegacyAxisConfig.defaults();
    final effectiveYAxis = widget.yAxis ??
        LegacyAxisConfig.defaults().copyWith(axisPosition: AxisPosition.left);

    // Get all series for bounds calculation
    final allSeries = _getAllSeries();
    if (allSeries.isEmpty) {
      return Rect.fromLTWH(0, 0, size.width, size.height);
    }

    // Calculate preliminary bounds for axis sizing
    final preliminaryBounds = _calculatePreliminaryBounds(allSeries);

    // Calculate padding based on dynamic axis sizing or user-provided reservedSize
    final leftPadding = (effectiveYAxis.showAxis &&
            effectiveYAxis.axisPosition == AxisPosition.left)
        ? _calculateAxisPadding(effectiveYAxis, preliminaryBounds, false)
        : 0.0;
    final rightPadding = (effectiveYAxis.showAxis &&
            effectiveYAxis.axisPosition == AxisPosition.right)
        ? _calculateAxisPadding(effectiveYAxis, preliminaryBounds, false)
        : 0.0;
    final topPadding = (effectiveXAxis.showAxis &&
            effectiveXAxis.axisPosition == AxisPosition.top)
        ? _calculateAxisPadding(effectiveXAxis, preliminaryBounds, true)
        : 0.0;
    final bottomPadding = (effectiveXAxis.showAxis &&
            effectiveXAxis.axisPosition == AxisPosition.bottom)
        ? _calculateAxisPadding(effectiveXAxis, preliminaryBounds, true)
        : 0.0;

    return Rect.fromLTWH(
        leftPadding,
        topPadding,
        size.width - leftPadding - rightPadding,
        size.height - topPadding - bottomPadding);
  }

  /// Calculates preliminary data bounds from series (for axis sizing).
  ///
  /// CRITICAL: Returns UNPADDED original data bounds.
  /// Padding should be applied AFTER zoom/pan transformation to avoid coordinate misalignment.
  _DataBounds _calculatePreliminaryBounds(List<ChartSeries> series) {
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

    // CRITICAL FIX: DO NOT add padding here!
    // This method returns ORIGINAL data bounds for zoom/pan calculations.
    // Padding is applied in _calculateDataBounds and painter AFTER zoom/pan transformation.

    return _DataBounds(minX: minX, maxX: maxX, minY: minY, maxY: maxY);
  }

  /// Calculates axis padding (same logic as _BravenChartPainter._calculateAxisReservedSize).
  double _calculateAxisPadding(
      LegacyAxisConfig axis, _DataBounds bounds, bool isXAxis) {
    // If user provided explicit size, use it
    if (axis.reservedSize != null) {
      return axis.reservedSize!;
    }

    // If axis and labels are hidden, no space needed
    if (!axis.showAxis || !axis.showLabels) {
      return 0.0;
    }

    // Get effective theme
    final effectiveTheme = widget.theme ?? ChartTheme.defaultLight;

    // Calculate the data range
    final range =
        isXAxis ? (bounds.maxX - bounds.minX) : (bounds.maxY - bounds.minY);

    // If range is invalid (NaN, infinite, or zero), return default padding
    if (range.isNaN || range.isInfinite || range <= 0) {
      // Return a reasonable default: typical label height/width + gap + tick
      const labelGap = 5.0;
      final tickSpace = axis.showTicks ? axis.tickLength : 0.0;
      return (isXAxis ? 20.0 : 40.0) + labelGap + tickSpace;
    }

    // Calculate based on actual label sizes
    final interval = _calculateNiceInterval(range);
    final first = isXAxis
        ? (bounds.minX / interval).floor() * interval
        : (bounds.minY / interval).floor() * interval;
    final last = isXAxis ? bounds.maxX : bounds.maxY;

    double maxSize = 0.0;
    var current = first;

    // Measure all labels to find the maximum size
    while (current <= last) {
      final label = _formatAxisLabel(current);
      final textSpan =
          TextSpan(text: label, style: effectiveTheme.axisStyle.labelStyle);
      final textPainter =
          TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();

      if (isXAxis) {
        // For X-axis, we need height + buffer for spacing
        if (textPainter.height > maxSize) {
          maxSize = textPainter.height;
        }
      } else {
        // For Y-axis, we need width + buffer for spacing
        if (textPainter.width > maxSize) {
          maxSize = textPainter.width;
        }
      }

      current += interval;
    }

    // Add buffer: 5px for gap between label and axis + tick length if needed
    const labelGap = 5.0;
    final tickSpace = axis.showTicks ? axis.tickLength : 0.0;

    return maxSize + labelGap + tickSpace;
  }

  /// Calculates a "nice" interval (shared with painter).
  double _calculateNiceInterval(double range) {
    if (range == 0) return 1.0;
    final roughInterval = range / 7;
    final magnitude = (log(roughInterval) / ln10).floor();
    final pow10 = pow(10.0, magnitude).toDouble();
    final normalized = roughInterval / pow10;
    double niceNormalized;
    if (normalized < 1.5) {
      niceNormalized = 1.0;
    } else if (normalized < 3) {
      niceNormalized = 2.0;
    } else if (normalized < 7) {
      niceNormalized = 5.0;
    } else {
      niceNormalized = 10.0;
    }
    return niceNormalized * pow10;
  }

  /// Formats axis labels (shared with painter).
  String _formatAxisLabel(double value) {
    if ((value - value.round()).abs() < 0.0001) {
      return value.round().toString();
    }
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

  /// Calculates data bounds for all series.
  ///
  /// Same logic as _BravenChartPainter._calculateDataBounds - MUST include zoom/pan!
  /// Calculates RAW data bounds without any zoom/pan transformations.
  ///
  /// This method returns the actual min/max values from the dataset,
  /// which is essential for auto-scroll to determine the full data range.
  /// Use this instead of _calculateDataBounds() when you need the complete
  /// data range regardless of current zoom/pan state.
  _DataBounds _calculateRawDataBounds(List<ChartSeries> series) {
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

    // Add padding for Y-axis
    final yRange = maxY - minY;
    minY -= yRange * 0.1;
    maxY += yRange * 0.1;

    return _DataBounds(minX: minX, maxX: maxX, minY: minY, maxY: maxY);
  }

  /// Clamps pan offset to prevent panning beyond data boundaries.
  ///
  /// **Coordinate System**:
  /// - Pan offset (pixels): `panX`, `panY` in screen coordinates
  /// - Pan data (data units): `panDataX = -panX * (dataRangeX / rect.width)`
  /// - Viewport: `minX = centerX - rangeX/2 + panDataX`, `maxX = centerX + rangeX/2 + panDataX`
  ///
  /// **Boundary Conditions with Padding**:
  /// - Adds visual breathing room (default 5% of visible range on each side)
  /// - LEFT edge: `minX = dataMinX - padding` → allows panning slightly beyond left boundary
  /// - RIGHT edge: `maxX = dataMaxX + padding` → allows panning slightly beyond right boundary
  ///
  /// **Padding Calculation**:
  /// - `padding = visibleRange * edgePaddingPercent`
  /// - At zoom 1x (100 points visible, 5% padding): 5 points of padding
  /// - At zoom 4x (25 points visible, 5% padding): 1.25 points of padding
  ///
  /// **Returns**: New ZoomPanState with clamped pan offset
  ZoomPanState _clampPanOffset(ZoomPanState state) {
    if (_cachedChartRect == null) {
      return state; // Can't clamp without chart rect
    }

    final allSeries = _getAllSeries();
    if (allSeries.isEmpty) {
      return state; // No data to clamp against
    }

    // Get ORIGINAL data bounds (without zoom/pan transformation)
    final dataBounds = _calculateRawDataBounds(allSeries);
    final dataMinX = dataBounds.minX;
    final dataMaxX = dataBounds.maxX;
    final dataMinY = dataBounds.minY;
    final dataMaxY = dataBounds.maxY;

    final dataRangeX = dataMaxX - dataMinX;
    final dataRangeY = dataMaxY - dataMinY;

    final rect = _cachedChartRect!;

    // Calculate visible range based on zoom level
    final rangeX = dataRangeX / state.zoomLevelX;
    final rangeY = dataRangeY / state.zoomLevelY;

    // Add edge padding (5% of visible range on each side)
    // This allows panning slightly beyond data boundaries for better visibility
    const edgePaddingPercent = 0.05;
    final paddingX = rangeX * edgePaddingPercent;
    final paddingY = rangeY * edgePaddingPercent;

    // Adjust effective data range to include padding
    final effectiveMinX = dataMinX - paddingX;
    final effectiveMaxX = dataMaxX + paddingX;
    final effectiveMinY = dataMinY - paddingY;
    final effectiveMaxY = dataMaxY + paddingY;

    // Calculate center of ORIGINAL data range (not effective range)
    // This is critical - viewport transformation uses original center
    final originalCenterX = (dataMinX + dataMaxX) / 2;
    final originalCenterY = (dataMinY + dataMaxY) / 2;

    final maxPanDataX = effectiveMinX - originalCenterX + rangeX / 2;
    final maxPanX = -maxPanDataX * (rect.width / dataRangeX);

    final maxPanDataY = effectiveMinY - originalCenterY + rangeY / 2;
    final maxPanY = -maxPanDataY * (rect.height / dataRangeY);

    // Calculate min allowed pan offset (at RIGHT/BOTTOM edge with padding)
    final minPanDataX = effectiveMaxX - originalCenterX - rangeX / 2;
    final minPanX = -minPanDataX * (rect.width / dataRangeX);

    final minPanDataY = effectiveMaxY - originalCenterY - rangeY / 2;
    final minPanY = -minPanDataY * (rect.height / dataRangeY);

    // Clamp pan offset
    final clampedPanX = state.panOffset.dx.clamp(minPanX, maxPanX);
    final clampedPanY = state.panOffset.dy.clamp(minPanY, maxPanY);

    return state.copyWith(panOffset: Offset(clampedPanX, clampedPanY));
  }

  _DataBounds _calculateDataBounds(List<ChartSeries> series,
      {Rect? chartRect, bool includePadding = true}) {
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

    // CRITICAL: Store ORIGINAL data range for zoom center calculation
    final dataMinX = minX;
    final dataMaxX = maxX;
    final dataMinY = minY;
    final dataMaxY = maxY;

    // Apply zoom/pan transformation FIRST (before padding)
    final zoomPanState = _interactionStateNotifier.value.zoomPanState;
    final zoomX = zoomPanState.zoomLevelX;
    final zoomY = zoomPanState.zoomLevelY;
    final panX = zoomPanState.panOffset.dx;
    final panY = zoomPanState.panOffset.dy;

    // Only apply zoom/pan if not at default state (zoom != 1.0 or pan != 0)
    if (zoomX != 1.0 || zoomY != 1.0 || panX != 0.0 || panY != 0.0) {
      // Calculate center from ORIGINAL data range
      final centerX = (dataMinX + dataMaxX) / 2;
      final centerY = (dataMinY + dataMaxY) / 2;

      // Calculate new range based on ORIGINAL data range
      final dataRangeX = dataMaxX - dataMinX;
      final dataRangeY = dataMaxY - dataMinY;
      final rangeX = dataRangeX / zoomX;
      final rangeY = dataRangeY / zoomY;

      // Convert pan offset from pixel units to data units
      // CRITICAL FIX: Use _cachedChartRect instead of accessing context.size during callbacks
      // context.size throws "Cannot get size from a render object that has been marked dirty"
      // when called during scrollbar animation callbacks (layout phase)
      final rect = chartRect ?? _cachedChartRect;
      if (rect == null) {
        // No chart rect available yet - skip zoom/pan transformation
        // This can happen on first build before layout completes
        minX = dataMinX;
        maxX = dataMaxX;
        minY = dataMinY;
        maxY = dataMaxY;
      } else {
        final panDataX = -panX * (dataRangeX / rect.width);
        final panDataY = panY *
            (dataRangeY / rect.height); // Invert Y for screen coordinates

        // Calculate visible bounds after zoom/pan (BEFORE padding)
        minX = centerX - rangeX / 2 + panDataX;
        maxX = centerX + rangeX / 2 + panDataX;
        minY = centerY - rangeY / 2 + panDataY;
        maxY = centerY + rangeY / 2 + panDataY;
      }
    } // CRITICAL: Add padding AFTER zoom/pan transformation (optional for scrollbar calculations)
    // This ensures padding is applied to the visible viewport, not the original data
    if (includePadding) {
      final yRange = maxY - minY;
      minY -= yRange * 0.1;
      maxY += yRange * 0.1;
    }

    return _DataBounds(minX: minX, maxX: maxX, minY: minY, maxY: maxY);
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
    if (config == null ||
        !config.enabled ||
        !_interactionStateNotifier.value.isTooltipVisible) {
      return null;
    }

    final dataPoint = _interactionStateNotifier.value.tooltipDataPoint;
    if (dataPoint == null) {
      return null;
    }

    // Use the cached chart rect and stack size (set in LayoutBuilder during render)
    if (_cachedChartRect == null || _cachedStackSize == null) {
      return null; // Chart dimensions not available yet
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
    // _dataToScreenPoint returns chartRect-local coordinates (for annotations)
    final markerDataPoint = ChartDataPoint(x: markerX, y: markerY);
    final markerScreenPosBase =
        _dataToScreenPoint(markerDataPoint, _cachedChartRect!, bounds);

    // CRITICAL: Add titleOffset for tooltip positioning (tooltips render differently than annotations)
    // Annotations use chartRect coords directly; tooltips need titleOffset adjustment
    final markerScreenPos = markerScreenPosBase + _titleOffset;

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

    // Calculate tooltip position using directional Positioned properties
    // No need for size estimates - Flutter handles sizing automatically
    // Pass both Stack size (for positioning) and chartRect (for clipping bounds)
    final tooltipPosition = _calculateTooltipPosition(markerScreenPos,
        config.preferredPosition, _cachedStackSize!, _cachedChartRect!);

    // Build tooltip with arrow pointer (integrated into border)
    final tooltipWithArrow = _buildTooltipWithArrow(
        tooltipContent, tooltipStyle, config.preferredPosition);

    // Return positioned tooltip without clipping
    return Positioned(
      left: tooltipPosition.left,
      right: tooltipPosition.right,
      top: tooltipPosition.top,
      bottom: tooltipPosition.bottom,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _interactionStateNotifier.value.isTooltipVisible ? 1.0 : 0.0,
          duration: config.showDelay,
          child: tooltipWithArrow,
        ),
      ),
    );
  }

  /// Calculates the optimal position for a tooltip based on preferredPosition.
  ///
  /// Returns directional positioning properties for the Positioned widget.
  /// Uses the appropriate edge (left/right/top/bottom) to avoid needing tooltip dimensions.
  ///
  /// - TOP: Uses `bottom` property (distance from screen bottom)
  /// - BOTTOM: Uses `top` property (distance from screen top)
  /// - LEFT: Uses `right` property (distance from screen right)
  /// - RIGHT: Uses `left` property (distance from screen left)
  ///
  /// Arrow is positioned at fixed offset from corner (arrowOffsetX/Y) and
  /// aligned with marker edge by adding marker radius to marker center position.
  ///
  /// Parameters:
  /// - [markerPos]: Marker position in Stack coordinates (includes axis padding)
  /// - [preferredPosition]: Tooltip position mode (top/bottom/left/right/auto)
  /// - [stackSize]: Full widget size (RED area) - used for Positioned coordinates
  /// - [chartRect]: Chart plotting area (BLUE area) - used for clipping reference
  ({double? left, double? right, double? top, double? bottom})
      _calculateTooltipPosition(
    Offset markerPos,
    TooltipPosition preferredPosition,
    Size stackSize,
    Rect chartRect,
  ) {
    // Constants for positioning
    const arrowSize = 10.0;
    const markerRadius = 6.0; // Marker is drawn with 6.0 radius
    const arrowOffsetX =
        20.0; // Horizontal offset from left/right edge for arrow
    const arrowOffsetY = 20.0; // Vertical offset from top/bottom edge for arrow

    // Screen dimensions from STACK size (full widget)
    final screenWidth = stackSize.width;
    final screenHeight = stackSize.height;

    // Calculate marker edge positions (marker center + radius)
    final markerEdgeTop = markerPos.dy - markerRadius;
    final markerEdgeBottom = markerPos.dy + markerRadius;
    final markerEdgeLeft = markerPos.dx - markerRadius;
    final markerEdgeRight = markerPos.dx + markerRadius;

    switch (preferredPosition) {
      case TooltipPosition.auto:
        // Auto-position defaults to TOP (requires tooltip size measurement for smart positioning)
        return (
          left: markerPos.dx - arrowOffsetX,
          bottom: screenHeight - markerEdgeTop + arrowSize,
          top: null,
          right: null
        );

      case TooltipPosition.top:
        // Tooltip ABOVE marker
        // Use `bottom` property: distance from screen bottom to marker's top edge
        // Arrow is arrowOffsetX from left edge, points down to marker
        return (
          left: markerPos.dx - arrowOffsetX,
          bottom: screenHeight - markerEdgeTop + arrowSize,
          top: null,
          right: null
        );

      case TooltipPosition.bottom:
        // Tooltip BELOW marker
        // Use `top` property: distance from screen top to marker's bottom edge
        // Arrow is arrowOffsetX from left edge, points up to marker
        return (
          left: markerPos.dx - arrowOffsetX,
          top: markerEdgeBottom + arrowSize,
          bottom: null,
          right: null
        );

      case TooltipPosition.left:
        // Tooltip LEFT of marker
        // Use `right` property: distance from screen right to marker's left edge
        // Arrow is arrowOffsetY from top edge, points right to marker
        return (
          right: screenWidth - markerEdgeLeft + arrowSize,
          top: markerPos.dy - arrowOffsetY,
          left: null,
          bottom: null
        );

      case TooltipPosition.right:
        // Tooltip RIGHT of marker
        // Use `left` property: distance from screen left to marker's right edge
        // Arrow is arrowOffsetY from top edge, points left to marker
        return (
          left: markerEdgeRight + arrowSize,
          top: markerPos.dy - arrowOffsetY,
          right: null,
          bottom: null
        );
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
      Color shadowColor
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
                child: tooltipContent),
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
                child: tooltipContent),
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
                child: tooltipContent),
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
                child: tooltipContent),
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
                width: tooltipStyle.borderWidth),
            borderRadius: BorderRadius.circular(tooltipStyle.borderRadius),
            boxShadow: boxShadow,
          ),
          child: tooltipContent,
        );
    }
  }

  /// Builds the default tooltip content.
  Widget _buildDefaultTooltip(
      Map<String, dynamic> dataPoint, TooltipConfig config) {
    final x = dataPoint['x'];
    final y = dataPoint['y'];

    final textStyle = TextStyle(
        color: config.style.textColor, fontSize: config.style.fontSize);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('X: ${x is num ? x.toStringAsFixed(2) : x.toString()}',
            style: textStyle),
        const SizedBox(height: 4),
        Text('Y: ${y is num ? y.toStringAsFixed(2) : y.toString()}',
            style: textStyle),
        // Show additional properties if present
        ...dataPoint.entries.where((e) => e.key != 'x' && e.key != 'y').map(
              (e) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${e.key}: ${e.value}',
                    style: textStyle.copyWith(
                        fontSize: config.style.fontSize * 0.83)),
              ),
            ),
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
          result[existingIndex] =
              ChartSeries(id: entry.key, points: entry.value);
        } else {
          // Add new series
          result.add(ChartSeries(id: entry.key, points: entry.value));
        }
      }
    }

    return result;
  }

  /// Gets all annotations from widget and controller combined.
  ///
  /// **Architecture**: Merges annotations from three sources in this priority:
  /// 1. Chart-level annotations (widget.annotations) - global annotations
  /// 2. Series-level annotations (series.annotations) - series-specific annotations
  /// 3. Controller annotations - programmatic annotations
  ///
  /// This enables both patterns:
  /// - **Preferred**: Attach annotations to ChartSeries for encapsulation
  /// - **Legacy**: Use chart-level annotations for backwards compatibility
  List<ChartAnnotation> _getAllAnnotations() {
    final result = <ChartAnnotation>[...widget.annotations];

    // Add series-level annotations (NEW: preferred pattern)
    for (final series in _getAllSeries()) {
      result.addAll(series.annotations);
    }

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
  /// Handles scrollbar pixel delta changes (T050-T055: User Story 1 - PIXEL-DELTA PATTERN).
  ///
  /// Converts scrollbar pixel delta to data delta using current viewport and updates zoom/pan state.
  /// This method is called when user interacts with scrollbars.
  ///
  /// **PIXEL-DELTA PATTERN**: Scrollbar reports pixel deltas + interaction type.
  /// Parent (this method) converts pixel deltas to zoom/pan state adjustments.
  ///
  /// CRITICAL FIX: Directly manipulate zoom/pan state instead of going through viewport calculations.
  /// Previous bug: Used _calculateDataBounds which ALREADY applies zoom/pan, then applied MORE transformations,
  /// creating a feedback loop causing jumps.
  ///
  /// New approach: Convert pixel delta directly to pan offset delta (for pan) or zoom level delta (for zoom edges).
  void _onScrollbarPixelDelta(
      Offset pixelDelta, ScrollbarInteraction interaction,
      {required bool isXAxis}) {
    // DRAG END SIGNAL: Scrollbar sends Offset.zero when drag ends
    // Clear drag start baseline so next drag starts fresh
    if (pixelDelta == Offset.zero) {
      _scrollbarDragStartPan = null;
      _lastScrollbarInteraction = null;
      return;
    }

    // Get current zoom/pan state
    final currentState = _interactionStateNotifier.value.zoomPanState;

    final allSeries = _getAllSeries();
    if (allSeries.isEmpty) {
      return;
    }
    if (_cachedChartRect == null) {
      return;
    }

    // Calculate ORIGINAL data bounds (full data range, no zoom/pan)
    final dataBounds = _calculateRawDataBounds(allSeries);
    final dataMinX = dataBounds.minX;
    final dataMaxX = dataBounds.maxX;
    final dataMinY = dataBounds.minY;
    final dataMaxY = dataBounds.maxY;

    final dataRangeX = dataMaxX - dataMinX;
    final dataRangeY = dataMaxY - dataMinY;

    // Convert pixel delta to data delta and apply based on interaction type
    if (isXAxis) {
      // Extract X pixel delta
      final pixelDeltaX = pixelDelta.dx;
      final trackLength = _cachedChartRect!.width;

      // Handle track click special case (absolute position, not delta)
      if (interaction == ScrollbarInteraction.trackClick) {
        // pixelDelta is absolute position in track coordinates (0 to trackLength)
        // Convert to data position and center viewport there
        final clickRatio = pixelDeltaX / trackLength;
        final targetDataPosition = dataMinX + (clickRatio * dataRangeX);

        // Calculate viewport size from current zoom level
        final viewportSize = dataRangeX / currentState.zoomLevelX;

        // Calculate new viewport centered at target position
        final newViewportMin = (targetDataPosition - viewportSize / 2)
            .clamp(dataMinX, dataMaxX - viewportSize);
        final newViewportMax = newViewportMin + viewportSize;

        // Convert viewport to zoom/pan (zoom stays same, only pan changes)
        final visibleCenterX = (newViewportMin + newViewportMax) / 2;
        final dataCenterX = (dataMinX + dataMaxX) / 2;
        final panDataX = visibleCenterX - dataCenterX;
        // CRITICAL FIX: X-axis uses negation: panDataX = -panX * (dataRangeX / trackLength)
        // Therefore reverse is: panX = -panDataX * (trackLength / dataRangeX)
        final newPanX = -panDataX * (trackLength / dataRangeX);

        final newZoomPanState = currentState.copyWith(
            panOffset: Offset(newPanX, currentState.panOffset.dy));

        _interactionStateNotifier.value = _interactionStateNotifier.value
            .copyWith(zoomPanState: newZoomPanState);
      } else {
        // Regular drag: Convert pixel delta to pan offset delta
        // CRITICAL FIX FOR SENSITIVITY: Scale by the ratio of data range to track length
        // This makes scrollbar movement proportional to data movement
        // Formula: panOffsetDelta = -(pixelDelta / trackLength) * trackLength = -pixelDelta
        // BUT we need to account for zoom level! At zoom 2x, scrollbar should move half as much data
        // So we scale by (dataRange / visibleRange) to maintain proper sensitivity

        // Get current viewport size from zoom level
        final viewportSize = dataRangeX / currentState.zoomLevelX;

        // CRITICAL FIX: Use reduced sensitivity multiplier for comfortable panning
        // Testing showed 1.0x was too sensitive, reducing to 0.5x for better control
        // SENSITIVITY MULTIPLIER: 0.5x (drag scrollbar 10px = pan viewport 5px)
        const scaleFactor = 0.5;

        // CRITICAL: Negate for correct directionality (drag scrollbar right = pan viewport right = negative pan offset)
        final panOffsetDeltaX = -(pixelDeltaX * scaleFactor);

        switch (interaction) {
          case ScrollbarInteraction.pan:
            // CRITICAL FIX: Scrollbar sends CUMULATIVE deltas, not incremental!
            // Initialize drag start pan on first frame or interaction change
            if (_scrollbarDragStartPan == null ||
                _lastScrollbarInteraction != interaction) {
              _scrollbarDragStartPan = currentState.panOffset;
              _lastScrollbarInteraction = interaction;
              return; // CRITICAL: Return immediately on first frame to skip processing
            }

            // Calculate absolute target pan from drag start + cumulative delta
            // This prevents acceleration: newPan = dragStartPan + cumulativeDelta
            final newPanX = _scrollbarDragStartPan!.dx + panOffsetDeltaX;

            // Clamp pan to valid range to prevent panning beyond data boundaries
            // CORRECTED FORMULA: Account for negation in panDataX = -panX * (dataRangeX / trackLength)
            // When viewport is at LEFT edge: minX = dataMinX → panDataX = -(dataRangeX - rangeX)/2
            // When viewport is at RIGHT edge: maxX = dataMaxX → panDataX = (dataRangeX - rangeX)/2
            // Converting to panX: panX = -panDataX * (trackLength / dataRangeX)
            final viewportSize = dataRangeX / currentState.zoomLevelX;
            final minPanX = -(dataRangeX - viewportSize) /
                2 *
                (trackLength / dataRangeX); // Viewport at left edge
            final maxPanX = (dataRangeX - viewportSize) /
                2 *
                (trackLength / dataRangeX); // Viewport at right edge

            final clampedPanX = newPanX.clamp(minPanX, maxPanX);

            final newZoomPanState = currentState.copyWith(
                panOffset: Offset(clampedPanX, currentState.panOffset.dy));

            _interactionStateNotifier.value = _interactionStateNotifier.value
                .copyWith(zoomPanState: newZoomPanState);
            break;

          case ScrollbarInteraction.zoomLeftOrTop:
          case ScrollbarInteraction.zoomRightOrBottom:
            // Zoom edges: Adjust zoom level while keeping anchor point fixed
            // This is more complex - need to calculate new zoom and pan to keep anchor point stationary

            // Get current viewport from zoom/pan state
            final dataCenterX = (dataMinX + dataMaxX) / 2;
            final currentPanDataX =
                -currentState.panOffset.dx * (dataRangeX / trackLength);
            final currentViewportSize = dataRangeX / currentState.zoomLevelX;
            final currentVisibleCenterX = dataCenterX + currentPanDataX;
            final currentViewportMinX =
                currentVisibleCenterX - currentViewportSize / 2;
            final currentViewportMaxX =
                currentVisibleCenterX + currentViewportSize / 2;

            // CRITICAL: Scrollbar sends CUMULATIVE delta from drag start, not incremental!
            // We need to track the starting viewport and calculate absolute positions.

            // Initialize drag start viewport on first frame or interaction change
            if (_scrollbarDragStartPan == null ||
                _lastScrollbarInteraction != interaction) {
              _scrollbarDragStartPan =
                  Offset(currentViewportMinX, currentViewportMaxX);
              _lastScrollbarInteraction = interaction;
              return; // CRITICAL: Return immediately on first frame to skip processing
            }

            // Convert CUMULATIVE pixel delta to data delta
            // SENSITIVITY: 35% (0.35x multiplier) for balanced zoom control
            final dataDeltaX = (pixelDeltaX / trackLength) * dataRangeX * 0.35;

            // Calculate new viewport bounds from ORIGINAL viewport + cumulative delta
            final startViewportMinX = _scrollbarDragStartPan!.dx;
            final startViewportMaxX = _scrollbarDragStartPan!
                .dy; // Calculate new viewport with anchor point
            late final double newViewportMinX;
            late final double newViewportMaxX;

            if (interaction == ScrollbarInteraction.zoomLeftOrTop) {
              // Anchor right edge, adjust left edge from STARTING position
              newViewportMinX = (startViewportMinX + dataDeltaX).clamp(dataMinX,
                  startViewportMaxX - (dataRangeX * 0.01)); // Min 1% viewport
              newViewportMaxX = startViewportMaxX;
            } else {
              // Anchor left edge, adjust right edge from STARTING position
              newViewportMinX = startViewportMinX;
              newViewportMaxX = (startViewportMaxX + dataDeltaX).clamp(
                  startViewportMinX + (dataRangeX * 0.01),
                  dataMaxX); // Min 1% viewport
            }

            // Convert new viewport to zoom/pan state
            final newViewportSize = newViewportMaxX - newViewportMinX;
            final newZoomX = dataRangeX / newViewportSize;
            final newVisibleCenterX = (newViewportMinX + newViewportMaxX) / 2;
            final newPanDataX = newVisibleCenterX - dataCenterX;
            // CRITICAL FIX: X-axis uses negation: panDataX = -panX * (dataRangeX / trackLength)
            // Therefore reverse is: panX = -panDataX * (trackLength / dataRangeX)
            final newPanX = -newPanDataX * (trackLength / dataRangeX);

            final newZoomPanState = currentState.copyWith(
                zoomLevelX: newZoomX,
                panOffset: Offset(newPanX, currentState.panOffset.dy));

            _interactionStateNotifier.value = _interactionStateNotifier.value
                .copyWith(zoomPanState: newZoomPanState);
            break;

          case ScrollbarInteraction.keyboard:
            // Keyboard: Treated as pan
            final newPanX = currentState.panOffset.dx + panOffsetDeltaX;

            // Clamp to prevent panning beyond data boundaries (same formula as scrollbar pan)
            final viewportSize = dataRangeX / currentState.zoomLevelX;
            final minPanX =
                -(dataRangeX - viewportSize) / 2 * (trackLength / dataRangeX);
            final maxPanX =
                (dataRangeX - viewportSize) / 2 * (trackLength / dataRangeX);
            final clampedPanX = newPanX.clamp(minPanX, maxPanX);

            final newZoomPanState = currentState.copyWith(
                panOffset: Offset(clampedPanX, currentState.panOffset.dy));

            _interactionStateNotifier.value = _interactionStateNotifier.value
                .copyWith(zoomPanState: newZoomPanState);
            break;

          case ScrollbarInteraction.trackClick:
            // Already handled above
            return;
        }
      }
    } else {
      // Y-axis: Similar logic for vertical scrollbar
      final pixelDeltaY = pixelDelta.dy;
      final trackLength = _cachedChartRect!.height;

      // Handle track click special case (absolute position, not delta)
      if (interaction == ScrollbarInteraction.trackClick) {
        // pixelDelta is absolute position in track coordinates (0 to trackLength)
        final clickRatio = pixelDeltaY / trackLength;
        final targetDataPosition = dataMinY + (clickRatio * dataRangeY);

        // Calculate viewport size from current zoom level
        final viewportSize = dataRangeY / currentState.zoomLevelY;

        // Calculate new viewport centered at target position
        final newViewportMin = (targetDataPosition - viewportSize / 2)
            .clamp(dataMinY, dataMaxY - viewportSize);
        final newViewportMax = newViewportMin + viewportSize;

        // Convert viewport to zoom/pan (zoom stays same, only pan changes)
        final visibleCenterY = (newViewportMin + newViewportMax) / 2;
        final dataCenterY = (dataMinY + dataMaxY) / 2;
        final panDataY = visibleCenterY - dataCenterY;
        final newPanY = panDataY * (trackLength / dataRangeY);

        final newZoomPanState = currentState.copyWith(
            panOffset: Offset(currentState.panOffset.dx, newPanY));

        _interactionStateNotifier.value = _interactionStateNotifier.value
            .copyWith(zoomPanState: newZoomPanState);
      } else {
        // Regular drag: Convert pixel delta to pan offset delta
        // CRITICAL FIX FOR SENSITIVITY: Use constant sensitivity multiplier

        // CRITICAL FIX: Use reduced sensitivity multiplier for comfortable panning
        // Testing showed 1.0x was too sensitive, reducing to 0.5x for better control
        // SENSITIVITY MULTIPLIER: 0.5x (drag scrollbar 10px = pan viewport 5px)
        const scaleFactor = 0.5;

        // CRITICAL: NO negation for Y-axis (screen Y increases downward, data Y increases downward)
        // Drag scrollbar down (positive pixel delta) = pan viewport down (positive pan offset)
        final panOffsetDeltaY = pixelDeltaY * scaleFactor;

        switch (interaction) {
          case ScrollbarInteraction.pan:
            // CRITICAL FIX: Scrollbar sends CUMULATIVE deltas, not incremental!
            // Initialize drag start pan on first frame or interaction change
            if (_scrollbarDragStartPan == null ||
                _lastScrollbarInteraction != interaction) {
              _scrollbarDragStartPan = currentState.panOffset;
              _lastScrollbarInteraction = interaction;
              return; // CRITICAL: Return immediately on first frame to skip processing
            }

            // Calculate absolute target pan from drag start + cumulative delta
            // This prevents acceleration: newPan = dragStartPan + cumulativeDelta
            final newPanY = _scrollbarDragStartPan!.dy + panOffsetDeltaY;

            // Clamp pan to valid range to prevent panning beyond data boundaries
            // Y-axis formula: panDataY = panY * (dataRangeY / trackLength) [NO negation unlike X]
            // When viewport is at BOTTOM edge: minY = dataMinY → panDataY = -(dataRangeY - rangeY)/2
            // When viewport is at TOP edge: maxY = dataMaxY → panDataY = (dataRangeY - rangeY)/2
            // Converting to panY: panY = panDataY * (trackLength / dataRangeY)
            final viewportSize = dataRangeY / currentState.zoomLevelY;
            final minPanY = -(dataRangeY - viewportSize) /
                2 *
                (trackLength / dataRangeY); // Viewport at bottom edge
            final maxPanY = (dataRangeY - viewportSize) /
                2 *
                (trackLength / dataRangeY); // Viewport at top edge

            final clampedPanY = newPanY.clamp(minPanY, maxPanY);

            final newZoomPanState = currentState.copyWith(
                panOffset: Offset(currentState.panOffset.dx, clampedPanY));

            _interactionStateNotifier.value = _interactionStateNotifier.value
                .copyWith(zoomPanState: newZoomPanState);
            break;

          case ScrollbarInteraction.zoomLeftOrTop:
          case ScrollbarInteraction.zoomRightOrBottom:
            // Zoom edges: Adjust zoom level while keeping anchor point fixed

            // Get current viewport from zoom/pan state
            final dataCenterY = (dataMinY + dataMaxY) / 2;
            final currentPanDataY =
                currentState.panOffset.dy * (dataRangeY / trackLength);
            final currentViewportSize = dataRangeY / currentState.zoomLevelY;
            final currentVisibleCenterY = dataCenterY + currentPanDataY;
            final currentViewportMinY =
                currentVisibleCenterY - currentViewportSize / 2;
            final currentViewportMaxY =
                currentVisibleCenterY + currentViewportSize / 2;

            // CRITICAL: Scrollbar sends CUMULATIVE delta from drag start, not incremental!
            // We need to track the starting viewport and calculate absolute positions.

            // Initialize drag start viewport on first frame or interaction change
            // For Y-axis, store in separate variable to avoid conflict with X-axis
            if (_scrollbarDragStartPan == null ||
                _lastScrollbarInteraction != interaction) {
              _scrollbarDragStartPan =
                  Offset(currentViewportMinY, currentViewportMaxY);
              _lastScrollbarInteraction = interaction;
              return; // CRITICAL: Return immediately on first frame to skip processing
            }

            // Convert CUMULATIVE pixel delta to data delta
            // SENSITIVITY: 35% (0.35x multiplier) for balanced zoom control
            final dataDeltaY = (pixelDeltaY / trackLength) * dataRangeY * 0.35;

            // Calculate new viewport bounds from ORIGINAL viewport + cumulative delta
            final startViewportMinY = _scrollbarDragStartPan!.dx;
            final startViewportMaxY = _scrollbarDragStartPan!
                .dy; // Calculate new viewport with anchor point
            late final double newViewportMinY;
            late final double newViewportMaxY;

            if (interaction == ScrollbarInteraction.zoomLeftOrTop) {
              // Anchor bottom edge, adjust top edge from STARTING position
              newViewportMinY = (startViewportMinY + dataDeltaY)
                  .clamp(dataMinY, startViewportMaxY - (dataRangeY * 0.01));
              newViewportMaxY = startViewportMaxY;
            } else {
              // Anchor top edge, adjust bottom edge from STARTING position
              newViewportMinY = startViewportMinY;
              newViewportMaxY = (startViewportMaxY + dataDeltaY)
                  .clamp(startViewportMinY + (dataRangeY * 0.01), dataMaxY);
            }

            // Convert new viewport to zoom/pan state
            final newViewportSize = newViewportMaxY - newViewportMinY;
            final newZoomY = dataRangeY / newViewportSize;
            final newVisibleCenterY = (newViewportMinY + newViewportMaxY) / 2;
            final newPanDataY = newVisibleCenterY - dataCenterY;
            final newPanY = newPanDataY * (trackLength / dataRangeY);

            final newZoomPanState = currentState.copyWith(
                zoomLevelY: newZoomY,
                panOffset: Offset(currentState.panOffset.dx, newPanY));

            _interactionStateNotifier.value = _interactionStateNotifier.value
                .copyWith(zoomPanState: newZoomPanState);
            break;

          case ScrollbarInteraction.keyboard:
            // Keyboard: Treated as pan
            final newPanY = currentState.panOffset.dy + panOffsetDeltaY;

            // Clamp to prevent panning beyond data boundaries (same formula as scrollbar pan)
            final viewportSize = dataRangeY / currentState.zoomLevelY;
            final minPanY =
                -(dataRangeY - viewportSize) / 2 * (trackLength / dataRangeY);
            final maxPanY =
                (dataRangeY - viewportSize) / 2 * (trackLength / dataRangeY);
            final clampedPanY = newPanY.clamp(minPanY, maxPanY);

            final newZoomPanState = currentState.copyWith(
                panOffset: Offset(currentState.panOffset.dx, clampedPanY));

            _interactionStateNotifier.value = _interactionStateNotifier.value
                .copyWith(zoomPanState: newZoomPanState);
            break;

          case ScrollbarInteraction.trackClick:
            // Already handled above
            return;
        }
      }
    }

    // Invoke viewport callback
    _invokeViewportCallback();
  }

  void _invokeViewportCallback() {
    if (widget.interactionConfig?.onViewportChanged == null) return;

    // Calculate visible data bounds from zoom/pan state
    final zoomPanState = _interactionStateNotifier.value.zoomPanState;
    final allSeries = _getAllSeries();
    if (allSeries.isEmpty) return;

    // Get the original data bounds
    final dataBounds = _calculateDataBounds(allSeries);

    // Calculate visible range accounting for zoom and pan
    // Visible width = original width / zoom level
    final visibleWidth =
        (dataBounds.maxX - dataBounds.minX) / zoomPanState.zoomLevelX;
    final visibleHeight =
        (dataBounds.maxY - dataBounds.minY) / zoomPanState.zoomLevelY;

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
    required this.lineStyle,
    required this.series,
    required this.theme,
    required this.xAxis,
    required this.yAxis,
    required this.annotations,
    this.zoomPanState,
    this.originalDataBounds,
    this.onChartRectCalculated,
    this.multiAxisConfig,
  });
  // Toggle this at runtime to enable simple paint-stage profiling logs.
  // Keep false by default; set to true in a debug session to get timing output.
  static bool enablePaintProfiling = false;

  final ChartType chartType;
  final LineStyle lineStyle;
  final List<ChartSeries> series;
  final ChartTheme theme;
  final LegacyAxisConfig xAxis;
  final LegacyAxisConfig yAxis;
  final List<ChartAnnotation> annotations;
  final ZoomPanState? zoomPanState;
  // Optional precomputed bounds to avoid scanning series on every paint
  final _DataBounds? originalDataBounds;
  // Callback to notify State of the calculated chartRect with actual render size
  final void Function(Rect chartRect, Size size)? onChartRectCalculated;
  // Multi-axis configuration for normalization (Layer 11)
  final MultiAxisConfig? multiAxisConfig;

  @override
  void paint(Canvas canvas, Size size) {
    // Toggle profiling here for quick debugging. Flip the static flag
    // `_BravenChartPainter.enablePaintProfiling` to true during a debug run
    // to emit timing logs. It's non-const to avoid dead-code elimination.
    final bool enablePaintProfiling = _BravenChartPainter.enablePaintProfiling;
    Stopwatch? totalStopwatch;
    Stopwatch? stageStopwatch;
    if (enablePaintProfiling) {
      totalStopwatch = Stopwatch()..start();
      // Measure background + border stage
      stageStopwatch = Stopwatch()..start();
    }
    if (series.isEmpty) return;

    // Draw background
    final backgroundPaint = Paint()
      ..color = theme.backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Draw border if specified
    if (theme.borderWidth > 0) {
      final borderPaint = Paint()
        ..color = theme.borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = theme.borderWidth;
      canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height)
              .deflate(theme.borderWidth / 2),
          borderPaint);
    }

    // Calculate data bounds first (needed for dynamic axis sizing)
    final preliminaryBounds = _calculateDataBounds(chartRect: null);
    if (enablePaintProfiling) {
      stageStopwatch!.stop();

      stageStopwatch
        ..reset()
        ..start();
    }
    if (preliminaryBounds == null) return;

    // Calculate chart area (leave room for axes based on their positions)
    // Use dynamic calculation or user-provided reservedSize
    final leftPadding =
        (yAxis.showAxis && yAxis.axisPosition == AxisPosition.left)
            ? _calculateAxisReservedSize(yAxis, preliminaryBounds, false)
            : 0.0;
    final rightPadding =
        (yAxis.showAxis && yAxis.axisPosition == AxisPosition.right)
            ? _calculateAxisReservedSize(yAxis, preliminaryBounds, false)
            : 0.0;
    final topPadding =
        (xAxis.showAxis && xAxis.axisPosition == AxisPosition.top)
            ? _calculateAxisReservedSize(xAxis, preliminaryBounds, true)
            : 0.0;
    final bottomPadding =
        (xAxis.showAxis && xAxis.axisPosition == AxisPosition.bottom)
            ? _calculateAxisReservedSize(xAxis, preliminaryBounds, true)
            : 0.0;

    final chartRect = Rect.fromLTWH(
        leftPadding,
        topPadding,
        size.width - leftPadding - rightPadding,
        size.height - topPadding - bottomPadding);

    // CRITICAL FIX: Notify State of the chartRect calculated with ACTUAL render size.
    // This ensures cached chartRect matches the size CustomPaint uses for rendering.
    onChartRectCalculated?.call(chartRect, size);

    // Recalculate bounds with correct chart rect for zoom/pan
    final bounds = _calculateDataBounds(chartRect: chartRect);
    if (bounds == null) return;

    // Draw grid
    _drawGrid(canvas, chartRect, bounds);
    if (enablePaintProfiling) {
      stageStopwatch!.stop();

      stageStopwatch
        ..reset()
        ..start();
    }

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
    if (enablePaintProfiling) {
      stageStopwatch!.stop();

      stageStopwatch
        ..reset()
        ..start();
    }

    // Draw axes
    _drawAxes(canvas, size, chartRect, bounds);

    // Draw additional Y-axes from multiAxisConfig (Layer 11)
    _drawMultiAxes(canvas, size, chartRect);

    if (enablePaintProfiling) {
      stageStopwatch!.stop();

      totalStopwatch!.stop();
    }
  }

  _DataBounds? _calculateDataBounds({Rect? chartRect}) {
    if (series.isEmpty) return null;

    // Use precomputed original bounds if available to avoid O(n) scans each frame
    double minX;
    double maxX;
    double minY;
    double maxY;

    if (originalDataBounds != null) {
      minX = originalDataBounds!.minX;
      maxX = originalDataBounds!.maxX;
      minY = originalDataBounds!.minY;
      maxY = originalDataBounds!.maxY;
    } else {
      minX = double.infinity;
      maxX = double.negativeInfinity;
      minY = double.infinity;
      maxY = double.negativeInfinity;

      for (final s in series) {
        for (final point in s.points) {
          if (point.x < minX) minX = point.x;
          if (point.x > maxX) maxX = point.x;
          if (point.y < minY) minY = point.y;
          if (point.y > maxY) maxY = point.y;
        }
      }
    }

    // CRITICAL: Store data range BEFORE padding for zoom center calculation
    final dataMinX = minX;
    final dataMaxX = maxX;
    final dataMinY = minY;
    final dataMaxY = maxY;

    // Apply zoom/pan transformation FIRST (before padding)
    if (zoomPanState != null) {
      final zoomX = zoomPanState!.zoomLevelX;
      final zoomY = zoomPanState!.zoomLevelY;
      final panX = zoomPanState!.panOffset.dx;
      final panY = zoomPanState!.panOffset.dy;

      // Only apply zoom/pan if not at default state (zoom != 1.0 or pan != 0)
      if (zoomX != 1.0 || zoomY != 1.0 || panX != 0.0 || panY != 0.0) {
        // Calculate center from ORIGINAL data range
        final centerX = (dataMinX + dataMaxX) / 2;
        final centerY = (dataMinY + dataMaxY) / 2;

        // Calculate new range based on ORIGINAL data range
        final dataRangeX = dataMaxX - dataMinX;
        final dataRangeY = dataMaxY - dataMinY;
        final rangeX = dataRangeX / zoomX;
        final rangeY = dataRangeY / zoomY;

        // Convert pan offset from pixel units to data units
        double panDataX = 0.0;
        double panDataY = 0.0;
        if (chartRect != null) {
          panDataX = -panX * (dataRangeX / chartRect.width);
          panDataY = panY *
              (dataRangeY /
                  chartRect.height); // Invert Y for screen coordinates
        }

        // Calculate visible bounds after zoom/pan (BEFORE padding)
        minX = centerX - rangeX / 2 + panDataX;
        maxX = centerX + rangeX / 2 + panDataX;
        minY = centerY - rangeY / 2 + panDataY;
        maxY = centerY + rangeY / 2 + panDataY;
      }
    }

    // CRITICAL: Add padding AFTER zoom/pan transformation
    // This ensures padding is applied to the visible viewport, not the original data
    final yRange = maxY - minY;
    minY -= yRange * 0.1;
    maxY += yRange * 0.1;

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

    // If ranges are invalid (NaN, infinite, or zero), skip grid drawing
    // This happens when there's no data or invalid bounds
    if (xRange.isNaN ||
        xRange.isInfinite ||
        xRange <= 0 ||
        yRange.isNaN ||
        yRange.isInfinite ||
        yRange <= 0) {
      return;
    }

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
          canvas.drawLine(
              Offset(chartRect.left, y), Offset(chartRect.right, y), gridPaint);
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
          canvas.drawLine(
              Offset(x, chartRect.top), Offset(x, chartRect.bottom), gridPaint);
        }

        currentX += xInterval;
      }
    }
  }

  /// Calculates the required space for axis labels dynamically.
  ///
  /// Returns the width (for Y-axis) or height (for X-axis) needed to display labels.
  /// If [axis.reservedSize] is provided, returns that value.
  /// Otherwise, calculates based on actual label sizes with a buffer.
  double _calculateAxisReservedSize(
      LegacyAxisConfig axis, _DataBounds bounds, bool isXAxis) {
    // If user provided explicit size, use it
    if (axis.reservedSize != null) {
      return axis.reservedSize!;
    }

    // If axis and labels are hidden, no space needed
    if (!axis.showAxis || !axis.showLabels) {
      return 0.0;
    }

    // Calculate the data range
    final range =
        isXAxis ? (bounds.maxX - bounds.minX) : (bounds.maxY - bounds.minY);

    // If range is invalid (NaN, infinite, or zero), return default padding
    if (range.isNaN || range.isInfinite || range <= 0) {
      // Return a reasonable default: typical label height/width + gap + tick
      const labelGap = 5.0;
      final tickSpace = axis.showTicks ? axis.tickLength : 0.0;
      return (isXAxis ? 20.0 : 40.0) + labelGap + tickSpace;
    }

    // Calculate based on actual label sizes
    final interval = _calculateNiceInterval(range);
    final first = isXAxis
        ? (bounds.minX / interval).floor() * interval
        : (bounds.minY / interval).floor() * interval;
    final last = isXAxis ? bounds.maxX : bounds.maxY;

    double maxSize = 0.0;
    var current = first;

    // Measure all labels to find the maximum size
    while (current <= last) {
      final label = _formatAxisLabel(current);
      final textSpan = TextSpan(text: label, style: theme.axisStyle.labelStyle);
      final textPainter =
          TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();

      if (isXAxis) {
        // For X-axis, we need height + buffer for spacing
        if (textPainter.height > maxSize) {
          maxSize = textPainter.height;
        }
      } else {
        // For Y-axis, we need width + buffer for spacing
        if (textPainter.width > maxSize) {
          maxSize = textPainter.width;
        }
      }

      current += interval;
    }

    // Add buffer: 5px for gap between label and axis + tick length if needed
    const labelGap = 5.0;
    final tickSpace = axis.showTicks ? axis.tickLength : 0.0;

    return maxSize + labelGap + tickSpace;
  }

  /// Calculates a "nice" interval for grid lines based on the data range.
  ///
  /// This uses a simple algorithm to find intervals like 1, 2, 5, 10, 20, 50, 100, etc.
  /// that result in approximately 5-10 grid lines.
  double _calculateNiceInterval(double range) {
    // Guard against invalid ranges
    if (range.isNaN || range.isInfinite || range <= 0) return 1.0;

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

    // Create LineInterpolator with the configured line style
    final interpolator = LineInterpolator(lineStyle);

    for (var i = 0; i < series.length; i++) {
      final s = series[i];
      if (s.points.isEmpty) continue;

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Convert ChartDataPoints to screen coordinates (Offsets)
      // CRITICAL FIX: Render ALL points to maintain line continuity
      // Canvas clipping will automatically crop the visible region
      // This ensures line segments entering/exiting the viewport are drawn correctly
      final points = s.points
          .map(
              (point) => _dataToPixel(point, chartRect, bounds, seriesId: s.id))
          .toList();

      // Use LineInterpolator to generate path with the specified line style
      // (straight, smooth bezier, or stepped)
      final path = interpolator.interpolate(points);

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
        final offset = _dataToPixel(point, chartRect, bounds, seriesId: s.id);
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

      // Convert data points to screen coordinates
      final screenPoints = s.points
          .map(
              (point) => _dataToPixel(point, chartRect, bounds, seriesId: s.id))
          .toList();

      // Create the area fill path
      final path = Path();
      final firstPoint = screenPoints.first;
      final lastPoint = screenPoints.last;

      // Start at bottom-left baseline
      path.moveTo(firstPoint.dx, chartRect.bottom);

      // Build the top edge with interpolation based on lineStyle
      if (lineStyle == LineStyle.straight) {
        // Straight lines: Go to each point directly
        for (final point in screenPoints) {
          path.lineTo(point.dx, point.dy);
        }
      } else if (lineStyle == LineStyle.smooth) {
        // Smooth curves: Use Catmull-Rom to cubic bezier
        if (screenPoints.length >= 2) {
          // Go to first point
          path.lineTo(firstPoint.dx, firstPoint.dy);

          if (screenPoints.length == 2) {
            // Only 2 points: straight line
            path.lineTo(screenPoints[1].dx, screenPoints[1].dy);
          } else {
            // 3+ points: Use bezier curves
            for (int j = 0; j < screenPoints.length - 1; j++) {
              final p0 = j > 0 ? screenPoints[j - 1] : screenPoints[j];
              final p1 = screenPoints[j];
              final p2 = screenPoints[j + 1];
              final p3 = j < screenPoints.length - 2
                  ? screenPoints[j + 2]
                  : screenPoints[j + 1];

              // Catmull-Rom to Bezier control points
              final cp1 = Offset(
                  p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
              final cp2 = Offset(
                  p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);

              path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
            }
          }
        }
      } else if (lineStyle == LineStyle.stepped) {
        // Stepped: horizontal then vertical segments
        path.lineTo(firstPoint.dx, firstPoint.dy);
        for (int j = 1; j < screenPoints.length; j++) {
          path.lineTo(screenPoints[j].dx, screenPoints[j - 1].dy); // Horizontal
          path.lineTo(screenPoints[j].dx, screenPoints[j].dy); // Vertical
        }
      }

      // Complete the area by going back to baseline
      path.lineTo(lastPoint.dx, chartRect.bottom);
      path.close();

      canvas.drawPath(path, fillPaint);

      // Draw the top edge line using LineInterpolator
      final linePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final interpolator = LineInterpolator(lineStyle);
      final topEdgePath = interpolator.interpolate(screenPoints);
      canvas.drawPath(topEdgePath, linePaint);
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

        final topY = _dataToPixel(point, chartRect, bounds, seriesId: s.id).dy;
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
        final offset = _dataToPixel(point, chartRect, bounds, seriesId: s.id);
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

    // If ranges are invalid, we can still draw axis lines, but not labels
    final bool validRanges = !xRange.isNaN &&
        !xRange.isInfinite &&
        xRange > 0 &&
        !yRange.isNaN &&
        !yRange.isInfinite &&
        yRange > 0;

    final xInterval = validRanges ? _calculateNiceInterval(xRange) : 1.0;
    final yInterval = validRanges ? _calculateNiceInterval(yRange) : 1.0;

    if (xAxis.showAxis) {
      // Draw X-axis line at the position specified by axisPosition
      final double axisY = xAxis.axisPosition == AxisPosition.top
          ? chartRect.top
          : chartRect.bottom;
      canvas.drawLine(Offset(chartRect.left, axisY),
          Offset(chartRect.right, axisY), axisPaint);

      // Draw X-axis labels at grid intervals
      if (xAxis.showLabels && validRanges) {
        final firstX = (bounds.minX / xInterval).floor() * xInterval;
        var currentX = firstX;

        while (currentX <= bounds.maxX) {
          final xPercent = (currentX - bounds.minX) / xRange;
          final x = chartRect.left + (xPercent * chartRect.width);

          if (x >= chartRect.left && x <= chartRect.right) {
            // Format label (remove unnecessary decimals)
            final label = _formatAxisLabel(currentX);

            final textSpan =
                TextSpan(text: label, style: theme.axisStyle.labelStyle);

            final textPainter =
                TextPainter(text: textSpan, textDirection: TextDirection.ltr);

            textPainter.layout();

            // Position labels based on axis position
            final double labelY = xAxis.axisPosition == AxisPosition.top
                ? chartRect.top - textPainter.height - 5
                : chartRect.bottom + 5;

            textPainter.paint(
                canvas, Offset(x - textPainter.width / 2, labelY));
          }

          currentX += xInterval;
        }
      }
    }

    if (yAxis.showAxis) {
      // Draw Y-axis line at the position specified by axisPosition
      final double axisX = yAxis.axisPosition == AxisPosition.right
          ? chartRect.right
          : chartRect.left;
      canvas.drawLine(Offset(axisX, chartRect.top),
          Offset(axisX, chartRect.bottom), axisPaint);

      // Draw Y-axis labels at grid intervals
      if (yAxis.showLabels && validRanges) {
        final firstY = (bounds.minY / yInterval).floor() * yInterval;
        var currentY = firstY;

        while (currentY <= bounds.maxY) {
          final yPercent = (currentY - bounds.minY) / yRange;
          final y = chartRect.bottom - (yPercent * chartRect.height);

          if (y >= chartRect.top && y <= chartRect.bottom) {
            // Format label (remove unnecessary decimals)
            final label = _formatAxisLabel(currentY);

            final textSpan =
                TextSpan(text: label, style: theme.axisStyle.labelStyle);

            final textPainter =
                TextPainter(text: textSpan, textDirection: TextDirection.ltr);

            textPainter.layout();

            // Position labels based on axis position
            final double labelX = yAxis.axisPosition == AxisPosition.right
                ? chartRect.right + 5
                : chartRect.left - textPainter.width - 5;

            textPainter.paint(
                canvas, Offset(labelX, y - textPainter.height / 2));
          }

          currentY += yInterval;
        }
      }
    }
  }

  /// Renders additional Y-axes from multiAxisConfig using MultiAxisPainter.
  ///
  /// This method instantiates [MultiAxisPainter] with the axes defined in
  /// [multiAxisConfig] and renders them at their configured positions.
  void _drawMultiAxes(Canvas canvas, Size size, Rect chartRect) {
    // Only render if multiAxisConfig is provided with axes
    if (multiAxisConfig == null || multiAxisConfig!.axes.isEmpty) {
      return;
    }

    // Create and invoke MultiAxisPainter
    final axisPainter = MultiAxisPainter(
      axes: multiAxisConfig!.axes,
      chartRect: chartRect,
    );

    axisPainter.paint(canvas, size);
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

  /// Gets the Y bounds for a specific series based on multiAxisConfig.
  ///
  /// If multiAxisConfig is provided and the series is bound to an axis,
  /// returns the axis-specific bounds. Otherwise, returns the global bounds.
  ({double minY, double maxY}) _getSeriesYBounds(
      String seriesId, _DataBounds globalBounds) {
    if (multiAxisConfig == null) {
      return (minY: globalBounds.minY, maxY: globalBounds.maxY);
    }

    // Find the binding for this series
    final binding = multiAxisConfig!.bindings
        .where((b) => b.seriesId == seriesId)
        .firstOrNull;
    if (binding == null) {
      return (minY: globalBounds.minY, maxY: globalBounds.maxY);
    }

    // Find the axis for this binding
    final axis =
        multiAxisConfig!.axes.where((a) => a.id == binding.axisId).firstOrNull;
    if (axis == null) {
      return (minY: globalBounds.minY, maxY: globalBounds.maxY);
    }

    // Use axis minValue/maxValue if specified, otherwise compute from series data
    final targetSeries = series.where((s) => s.id == seriesId).firstOrNull;
    if (targetSeries == null || targetSeries.points.isEmpty) {
      return (minY: globalBounds.minY, maxY: globalBounds.maxY);
    }

    // Compute series range if axis doesn't specify explicit bounds
    final minY = axis.minValue ??
        targetSeries.points.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    final maxY = axis.maxValue ??
        targetSeries.points.map((p) => p.y).reduce((a, b) => a > b ? a : b);

    return (minY: minY, maxY: maxY);
  }

  /// Checks if normalization should be applied based on multiAxisConfig mode.
  bool _shouldNormalize() {
    if (multiAxisConfig == null) return false;

    switch (multiAxisConfig!.mode) {
      case NormalizationMode.none:
        return false;
      case NormalizationMode.perSeries:
        return true;
      case NormalizationMode.auto:
        // Use NormalizationDetector to determine if normalization is needed
        final ranges = <SeriesRange>[];
        for (final s in series) {
          if (s.points.isEmpty) continue;
          final seriesYBounds = _getSeriesYBounds(
              s.id, _DataBounds(minX: 0, maxX: 1, minY: 0, maxY: 1));
          ranges.add(SeriesRange(
              seriesId: s.id,
              min: seriesYBounds.minY,
              max: seriesYBounds.maxY));
        }
        return NormalizationDetector.shouldNormalize(ranges);
    }
  }

  /// Converts a data point to pixel coordinates.
  ///
  /// When multiAxisConfig is provided with normalization enabled, uses
  /// series-specific Y bounds for the conversion. Otherwise uses global bounds.
  Offset _dataToPixel(ChartDataPoint point, Rect chartRect, _DataBounds bounds,
      {String? seriesId}) {
    final xRange = bounds.maxX - bounds.minX;

    final xPercent = xRange == 0 ? 0.5 : (point.x - bounds.minX) / xRange;
    final pixelX = chartRect.left + (xPercent * chartRect.width);

    // Determine Y bounds based on normalization config
    double yPercent;
    if (seriesId != null && _shouldNormalize()) {
      final seriesYBounds = _getSeriesYBounds(seriesId, bounds);
      // Use DataNormalizer for consistent normalization
      yPercent = DataNormalizer.normalize(
          point.y, seriesYBounds.minY, seriesYBounds.maxY);
    } else {
      final yRange = bounds.maxY - bounds.minY;
      yPercent = yRange == 0 ? 0.5 : (point.y - bounds.minY) / yRange;
    }

    final pixelY = chartRect.bottom - (yPercent * chartRect.height);

    return Offset(pixelX, pixelY);
  }

  @override
  bool shouldRepaint(_BravenChartPainter oldDelegate) {
    // Cheap checks first
    if (chartType != oldDelegate.chartType) return true;
    if (theme != oldDelegate.theme) return true;
    if (xAxis != oldDelegate.xAxis || yAxis != oldDelegate.yAxis) return true;
    if (multiAxisConfig != oldDelegate.multiAxisConfig) return true;

    // Series: if list length differs or any series object identity changed, repaint
    if (series.length != oldDelegate.series.length) return true;
    for (var i = 0; i < series.length; i++) {
      if (!identical(series[i], oldDelegate.series[i])) return true;
    }

    // Annotations: compare lengths and identities
    if (annotations.length != oldDelegate.annotations.length) return true;
    for (var i = 0; i < annotations.length; i++) {
      if (!identical(annotations[i], oldDelegate.annotations[i])) return true;
    }

    // Zoom/pan: compare primitive fields for quick decision
    final a = zoomPanState;
    final b = oldDelegate.zoomPanState;
    if (a == null && b == null) return false;
    if (a == null || b == null) return true;
    if (a.zoomLevelX != b.zoomLevelX || a.zoomLevelY != b.zoomLevelY)
      return true;
    if (a.panOffset != b.panOffset) return true;

    return false;
  }
}

// ==================== HELPER CLASSES ====================

/// Custom clipper that clips tooltip to chart plotting area (BLUE area).
///
/// Ensures tooltips are clipped to the visible chart viewport, not the full widget.
/// The chart rect excludes the 40px axis padding on all four sides.
class ChartAreaClipper extends CustomClipper<Rect> {
  ChartAreaClipper(this.chartRect);

  final Rect chartRect;

  @override
  Rect getClip(Size size) => chartRect;

  @override
  bool shouldReclip(ChartAreaClipper oldClipper) =>
      chartRect != oldClipper.chartRect;
}

/// Helper class to store data bounds for chart rendering
class _DataBounds {
  _DataBounds(
      {required this.minX,
      required this.maxX,
      required this.minY,
      required this.maxY});
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _DataBounds &&
        other.minX == minX &&
        other.maxX == maxX &&
        other.minY == minY &&
        other.maxY == maxY;
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
    this.onAnnotationUpdate,
    required this.series,
    this.chartRect,
    required this.titleOffset,
    required this.zoomPanState,
    required this.dataToScreenPoint,
    this.onDragStateChanged,
  });

  final List<ChartAnnotation> annotations;
  final bool interactiveAnnotations;
  final void Function(ChartAnnotation annotation)? onAnnotationTap;
  final void Function(ChartAnnotation annotation, Offset newPosition)?
      onAnnotationDragged;
  final void Function(ChartAnnotation annotation)? onAnnotationUpdate;
  final List<ChartSeries> series;
  final Rect? chartRect;
  final Offset titleOffset;
  final ZoomPanState zoomPanState;
  final Offset Function(
          ChartDataPoint point, Rect chartRect, _DataBounds bounds)
      dataToScreenPoint;
  final void Function(String? edge)?
      onDragStateChanged; // edge is 'left', 'right', 'top', 'bottom', or null

  @override
  Widget build(BuildContext context) {
    // Annotations are already sorted by z-index in _getAllAnnotations()
    return Stack(
      clipBehavior: Clip
          .none, // CRITICAL: Don't clip annotations that extend beyond Stack bounds
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
    // TextAnnotation now uses screen coordinates only
    final screenPosition = annotation.position;

    // Build the annotation content
    final annotationContent = GestureDetector(
      onTap: interactiveAnnotations && onAnnotationTap != null
          ? () => onAnnotationTap!(annotation)
          : null,
      child: Container(
        padding: annotation.style.padding ??
            const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: annotation.backgroundColor,
          border: annotation.borderColor != null
              ? Border.all(color: annotation.borderColor!)
              : null,
          borderRadius:
              annotation.style.borderRadius ?? BorderRadius.circular(4),
        ),
        child: Text(annotation.text, style: annotation.style.textStyle),
      ),
    );

    // Use Align to apply anchor positioning
    // The anchor determines which point of the widget should be at the screenPosition
    return Positioned(
      left: screenPosition.dx,
      top: screenPosition.dy,
      child: FractionalTranslation(
        translation: _getAnchorOffset(annotation.anchor),
        child: annotationContent,
      ),
    );
  }

  /// Converts AnnotationAnchor to a fractional offset for FractionalTranslation.
  /// Returns negative values because FractionalTranslation shifts the widget.
  Offset _getAnchorOffset(AnnotationAnchor anchor) {
    switch (anchor) {
      case AnnotationAnchor.topLeft:
        return const Offset(0, 0);
      case AnnotationAnchor.topCenter:
        return const Offset(-0.5, 0);
      case AnnotationAnchor.topRight:
        return const Offset(-1, 0);
      case AnnotationAnchor.centerLeft:
        return const Offset(0, -0.5);
      case AnnotationAnchor.center:
        return const Offset(-0.5, -0.5);
      case AnnotationAnchor.centerRight:
        return const Offset(-1, -0.5);
      case AnnotationAnchor.bottomLeft:
        return const Offset(0, -1);
      case AnnotationAnchor.bottomCenter:
        return const Offset(-0.5, -1);
      case AnnotationAnchor.bottomRight:
        return const Offset(-1, -1);
    }
  }

  /// Builds a point annotation widget (marker on specific data point).
  Widget _buildPointAnnotation(PointAnnotation annotation) {
    // Get the series containing the data point
    final targetSeries =
        series.where((s) => s.id == annotation.seriesId).firstOrNull;

    if (targetSeries == null ||
        annotation.dataPointIndex >= targetSeries.points.length) {
      // Series not found or invalid index - don't render
      return const SizedBox.shrink();
    }

    // Get the specific data point
    final dataPoint = targetSeries.points[annotation.dataPointIndex];

    // Calculate bounds for coordinate transformation
    if (chartRect == null) {
      // Chart not yet rendered - don't show annotation
      return const SizedBox.shrink();
    }

    final bounds = _calculateDataBounds(series);

    // Transform data coordinates to screen coordinates
    final screenPos = dataToScreenPoint(dataPoint, chartRect!, bounds);

    // Check if point is within visible bounds (optimization)
    if (!chartRect!.contains(screenPos)) {
      // Point is outside visible area
      return const SizedBox.shrink();
    }

    // Apply offset for marker centering
    final markerLeft = screenPos.dx - annotation.markerSize;
    final markerTop = screenPos.dy - annotation.markerSize;

    return Positioned(
      left: markerLeft,
      top: markerTop,
      child: GestureDetector(
        onTap: interactiveAnnotations && onAnnotationTap != null
            ? () => onAnnotationTap!(annotation)
            : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Marker
            CustomPaint(
              size: Size(annotation.markerSize * 2, annotation.markerSize * 2),
              painter: _MarkerPainter(
                  shape: annotation.markerShape,
                  size: annotation.markerSize,
                  color: annotation.markerColor),
            ),
            // Label (if present)
            if (annotation.label != null && annotation.label!.isNotEmpty)
              Positioned(
                left: annotation.markerSize * 2 + 4, // 4px offset from marker
                top: annotation
                    .markerSize, // Position at marker's vertical center
                child: Transform.translate(
                  offset: const Offset(0,
                      -0.5), // Shift up by half its own height (using fractional offset)
                  child: FractionalTranslation(
                    translation: const Offset(
                        0, -0.5), // Center vertically relative to marker center
                    child: Container(
                      padding: annotation.style.padding ??
                          const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: annotation.style.backgroundColor ??
                            Colors.white.withOpacity(0.9),
                        borderRadius: annotation.style.borderRadius ??
                            BorderRadius.circular(4),
                        border: annotation.style.borderColor != null
                            ? Border.all(
                                color: annotation.style.borderColor!,
                                width: annotation.style.borderWidth)
                            : null,
                      ),
                      child: Text(annotation.label!,
                          style: annotation.style.textStyle),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a range annotation widget (rectangular region).
  ///
  /// Handles both explicit and infinite ranges for X and Y axes:
  /// - Explicit ranges (non-null startX/endX, startY/endY): Transform data coordinates to screen coordinates
  /// - Infinite X ranges (null startX/endX): Span the full visible viewport width (changes with zoom/pan)
  /// - Infinite Y ranges (null startY/endY): Span the full chart canvas height (always top-to-bottom)
  ///
  /// The asymmetric handling of infinite ranges ensures proper behavior:
  /// - X-axis: Infinite ranges track the viewport (useful for vertical bands across visible data)
  /// - Y-axis: Infinite ranges always span chart height (prevents thin horizontal slices when zoomed)
  Widget _buildRangeAnnotation(RangeAnnotation annotation) {
    if (chartRect == null) {
      return const SizedBox.shrink();
    }

    final bounds = _calculateDataBounds(series);

    double left, top, width, height;
    if (annotation.startX != null && annotation.endX != null) {
      // Explicit X range - transform data coordinates to screen coordinates
      final startPoint = dataToScreenPoint(
          ChartDataPoint(x: annotation.startX!, y: bounds.minY),
          chartRect!,
          bounds);
      final endPoint = dataToScreenPoint(
          ChartDataPoint(x: annotation.endX!, y: bounds.maxY),
          chartRect!,
          bounds);
      left = startPoint.dx;
      width = (endPoint.dx - startPoint.dx).abs();
    } else {
      // Infinite X range - use full chartRect width
      left = chartRect!.left;
      width = chartRect!.width;
    }

    if (annotation.startY != null && annotation.endY != null) {
      // Explicit Y range - transform data coordinates to screen coordinates
      final startPoint = dataToScreenPoint(
          ChartDataPoint(x: bounds.minX, y: annotation.startY!),
          chartRect!,
          bounds);
      final endPoint = dataToScreenPoint(
          ChartDataPoint(x: bounds.maxX, y: annotation.endY!),
          chartRect!,
          bounds);
      top = endPoint.dy; // endY has smaller screen coordinate (Y is inverted)
      height = (startPoint.dy - endPoint.dy).abs();
    } else {
      // Infinite Y range - use full chartRect height (always spans top-to-bottom of canvas)
      top = chartRect!.top;
      height = chartRect!.height;
    }

    // Calculate rectangle edges for visibility check and clipping
    final right = left + width;
    final bottom = top + height;

    // Visibility check: Hide only if the annotation is completely outside the chart area.
    // An annotation is completely outside if both corners are on the same side of the boundary.
    final bothLeft = right < chartRect!.left;
    final bothRight = left > chartRect!.right;
    final bothAbove = bottom < chartRect!.top;
    final bothBelow = top > chartRect!.bottom;

    if (bothLeft || bothRight || bothAbove || bothBelow) {
      // Range is completely outside visible area on one side
      return const SizedBox.shrink();
    }

    // Clamp all four edges independently to chartRect boundaries.
    // This prevents Flutter from clipping the entire widget when coordinates extend outside bounds.
    final clampedLeft = left.clamp(chartRect!.left, chartRect!.right);
    final clampedTop = top.clamp(chartRect!.top, chartRect!.bottom);
    final clampedRight = right.clamp(chartRect!.left, chartRect!.right);
    final clampedBottom = bottom.clamp(chartRect!.top, chartRect!.bottom);

    // Recalculate dimensions from clamped edges
    final clampedWidth = clampedRight - clampedLeft;
    final clampedHeight = clampedBottom - clampedTop;

    // Validate dimensions - if width or height is <= 0 after clipping, annotation has no visible area
    if (clampedWidth <= 0 || clampedHeight <= 0) {
      return const SizedBox.shrink();
    }

    // CRITICAL: Add padding to allow handle hit zones to extend outside annotation bounds
    // Handles extend 10px beyond edges, so we need at least 10px padding on all sides
    const handlePadding = 10.0;

    return Positioned(
      left: clampedLeft - handlePadding,
      top: clampedTop - handlePadding,
      width: clampedWidth + (handlePadding * 2),
      height: clampedHeight + (handlePadding * 2),
      child: Padding(
        padding: const EdgeInsets.all(handlePadding),
        child: _RangeAnnotationWidget(
          annotation: annotation,
          chartRect: chartRect!,
          bounds: bounds,
          clampedWidth: clampedWidth,
          clampedHeight: clampedHeight,
          interactiveAnnotations: interactiveAnnotations,
          onAnnotationTap: onAnnotationTap,
          onAnnotationUpdate: onAnnotationUpdate != null
              ? (updated) => onAnnotationUpdate!(updated)
              : null,
          dataToScreenPoint: dataToScreenPoint,
          onDragStateChanged: onDragStateChanged,
        ),
      ),
    );
  }

  /// Builds a threshold annotation widget (horizontal or vertical line).
  Widget _buildThresholdAnnotation(ThresholdAnnotation annotation) {
    // PHASE 1, TASK 1.3: Coordinate transformation integration
    if (chartRect == null) {
      // Chart not yet rendered - don't show annotation
      return const SizedBox.shrink();
    }

    final bounds = _calculateDataBounds(series);

    // Check if the threshold value is within visible data bounds
    if (annotation.axis == AnnotationAxis.y) {
      if (annotation.value < bounds.minY || annotation.value > bounds.maxY) {
        // Y threshold is outside visible range
        return const SizedBox.shrink();
      }
    } else {
      if (annotation.value < bounds.minX || annotation.value > bounds.maxX) {
        // X threshold is outside visible range
        return const SizedBox.shrink();
      }
    }

    // Calculate label position based on labelPosition
    double? labelLeft;
    double? labelTop;
    double? labelRight;
    double? labelBottom;

    // Determine vertical translation based on position (for horizontal lines)
    // or horizontal translation based on position (for vertical lines)
    Offset translation;

    if (annotation.axis == AnnotationAxis.y) {
      // Horizontal line - calculate Y position
      final yRange = bounds.maxY - bounds.minY;
      final yPercent =
          yRange == 0 ? 0.5 : (annotation.value - bounds.minY) / yRange;
      final pixelY = chartRect!.bottom - (yPercent * chartRect!.height);
      final y = pixelY + titleOffset.dy;

      // Position label along the horizontal line based on labelPosition
      switch (annotation.labelPosition) {
        case AnnotationLabelPosition.topLeft:
          labelLeft = chartRect!.left + titleOffset.dx + 8;
          labelTop = y;
          translation =
              const Offset(0, -1.0); // Above line (shift up by full height)
          break;
        case AnnotationLabelPosition.topRight:
          labelRight = 8; // 8px from right edge
          labelTop = y;
          translation =
              const Offset(0, -1.0); // Above line (shift up by full height)
          break;
        case AnnotationLabelPosition.bottomLeft:
          labelLeft = chartRect!.left + titleOffset.dx + 8;
          labelTop = y;
          translation = const Offset(0, 0); // Below line (no shift)
          break;
        case AnnotationLabelPosition.bottomRight:
          labelRight = 8; // 8px from right edge
          labelTop = y;
          translation = const Offset(0, 0); // Below line (no shift)
          break;
        case AnnotationLabelPosition.center:
          labelLeft = chartRect!.left + (chartRect!.width / 2) + titleOffset.dx;
          labelTop = y;
          translation = const Offset(0, -0.5); // Centered on line
          break;
      }
    } else {
      // Vertical line - calculate X position
      final xRange = bounds.maxX - bounds.minX;
      final xPercent =
          xRange == 0 ? 0.5 : (annotation.value - bounds.minX) / xRange;
      final pixelX = chartRect!.left + (xPercent * chartRect!.width);
      final x = pixelX + titleOffset.dx;

      // Position label along the vertical line based on labelPosition
      switch (annotation.labelPosition) {
        case AnnotationLabelPosition.topLeft:
          labelLeft = x;
          labelTop = chartRect!.top + titleOffset.dy + 8;
          translation =
              const Offset(-1.0, 0); // Left of line (shift left by full width)
          break;
        case AnnotationLabelPosition.topRight:
          labelLeft = x;
          labelTop = chartRect!.top + titleOffset.dy + 8;
          translation = const Offset(0, 0); // Right of line (no shift)
          break;
        case AnnotationLabelPosition.bottomLeft:
          labelLeft = x;
          labelBottom = 8; // 8px from bottom edge
          translation =
              const Offset(-1.0, 0); // Left of line (shift left by full width)
          break;
        case AnnotationLabelPosition.bottomRight:
          labelLeft = x;
          labelBottom = 8; // 8px from bottom edge
          translation = const Offset(0, 0); // Right of line (no shift)
          break;
        case AnnotationLabelPosition.center:
          labelLeft = x;
          labelTop = chartRect!.top + (chartRect!.height / 2) + titleOffset.dy;
          translation =
              const Offset(-0.5, 0); // Centered on line (horizontal centering)
          break;
      }
    }

    return Positioned.fill(
      child: GestureDetector(
        onTap: interactiveAnnotations && onAnnotationTap != null
            ? () => onAnnotationTap!(annotation)
            : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Threshold line
            CustomPaint(
              painter: _ThresholdPainter(
                axis: annotation.axis,
                value: annotation.value,
                color: annotation.lineColor,
                width: annotation.lineWidth,
                dashPattern: annotation.dashPattern,
                chartRect: chartRect!,
                bounds: bounds,
                titleOffset: titleOffset,
              ),
            ),
            // Label (if present)
            if (annotation.label != null && annotation.label!.isNotEmpty)
              Positioned(
                left: labelLeft,
                top: labelTop,
                right: labelRight,
                bottom: labelBottom,
                child: FractionalTranslation(
                  translation: translation, // Position-aware translation
                  child: Container(
                    padding: annotation.style.padding ??
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: annotation.style.backgroundColor ??
                          Colors.white.withOpacity(0.9),
                      borderRadius: annotation.style.borderRadius ??
                          BorderRadius.circular(4),
                      border: annotation.style.borderColor != null
                          ? Border.all(
                              color: annotation.style.borderColor!,
                              width: annotation.style.borderWidth)
                          : null,
                    ),
                    child: Text(annotation.label!,
                        style: annotation.style.textStyle),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a trend annotation widget (trend line or regression).
  Widget _buildTrendAnnotation(TrendAnnotation annotation) {
    if (chartRect == null) return const SizedBox.shrink();

    // Find the series that owns this trend annotation
    // **NEW ARCHITECTURE**: First check if annotation is attached to a series
    // (series.annotations), then fall back to seriesId lookup for chart-level annotations
    ChartSeries? targetSeries;

    // Search series-level annotations first (preferred pattern)
    for (final s in series) {
      if (s.annotations.contains(annotation)) {
        targetSeries = s;
        break;
      }
    }

    // Fall back to seriesId lookup for chart-level/controller annotations
    if (targetSeries == null && annotation.seriesId.isNotEmpty) {
      try {
        targetSeries = series.firstWhere((s) => s.id == annotation.seriesId);
      } catch (e) {
        debugPrint(
            'TrendAnnotation: Series "${annotation.seriesId}" not found');
        return const SizedBox.shrink();
      }
    }

    // If still no series found, annotation is invalid
    if (targetSeries == null) {
      debugPrint(
          'TrendAnnotation: No parent series found for annotation "${annotation.id}"');
      return const SizedBox.shrink();
    }

    // Calculate trend based on type using the PARENT SERIES DATA
    // This eliminates the dataset scope issue - trends always use their series' data
    List<ChartDataPoint>? trendPoints;
    TrendResult? trendResult;

    switch (annotation.trendType) {
      case TrendType.linear:
        trendResult = TrendCalculator.linearRegression(targetSeries.points);
        trendPoints = trendResult?.trendPoints;
        break;

      case TrendType.polynomial:
        final degree = annotation.degree; // Default is 2 in data model
        trendResult =
            TrendCalculator.polynomialRegression(targetSeries.points, degree);
        trendPoints = trendResult?.trendPoints;
        break;

      case TrendType.movingAverage:
        final windowSize = annotation.windowSize ?? 5; // Default window
        trendPoints =
            TrendCalculator.movingAverage(targetSeries.points, windowSize);
        break;

      case TrendType.exponential:
        const alpha = 0.3; // Standard smoothing factor
        trendPoints =
            TrendCalculator.exponentialSmoothing(targetSeries.points, alpha);
        break;
    }

    // If calculation failed or no data, don't render
    if (trendPoints == null || trendPoints.isEmpty) {
      debugPrint(
          'TrendAnnotation: Failed to calculate trend for series "${targetSeries.id}"');
      return const SizedBox.shrink();
    }

    // Calculate bounds for coordinate transformation
    final bounds = _calculateDataBounds(series);

    return Positioned.fill(
      child: GestureDetector(
        onTap: interactiveAnnotations && onAnnotationTap != null
            ? () => onAnnotationTap!(annotation)
            : null,
        child: CustomPaint(
          painter: _TrendPainter(
            trendPoints: trendPoints,
            bounds: bounds,
            chartRect: chartRect!,
            titleOffset: titleOffset,
            lineColor: annotation.lineColor,
            lineWidth: annotation.lineWidth,
            dashPattern: annotation.dashPattern,
          ),
        ),
      ),
    );
  }

  // ==================== COORDINATE TRANSFORMATION HELPERS ====================

  /// Calculate data bounds from the provided series.
  /// Applies zoom/pan transformation to calculate visible viewport bounds.
  _DataBounds _calculateDataBounds(List<ChartSeries> seriesList) {
    if (seriesList.isEmpty) {
      return _DataBounds(minX: 0, maxX: 1, minY: 0, maxY: 1);
    }

    // Find raw data bounds
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final series in seriesList) {
      for (final point in series.points) {
        if (point.x < minX) minX = point.x;
        if (point.x > maxX) maxX = point.x;
        if (point.y < minY) minY = point.y;
        if (point.y > maxY) maxY = point.y;
      }
    }

    // Store original data range
    final dataMinX = minX;
    final dataMaxX = maxX;
    final dataMinY = minY;
    final dataMaxY = maxY;

    // Apply zoom/pan transformation
    final zoomX = zoomPanState.zoomLevelX;
    final zoomY = zoomPanState.zoomLevelY;
    final panX = zoomPanState.panOffset.dx;
    final panY = zoomPanState.panOffset.dy;

    if (zoomX != 1.0 || zoomY != 1.0 || panX != 0.0 || panY != 0.0) {
      // Calculate center from original data range
      final centerX = (dataMinX + dataMaxX) / 2;
      final centerY = (dataMinY + dataMaxY) / 2;

      // Calculate original data range
      final dataRangeX = dataMaxX - dataMinX;
      final dataRangeY = dataMaxY - dataMinY;

      // Calculate new range based on zoom
      final rangeX = dataRangeX / zoomX;
      final rangeY = dataRangeY / zoomY;

      // Convert pan offset from pixels to data units
      if (chartRect != null) {
        final panDataX = -panX * (dataRangeX / chartRect!.width);
        final panDataY = panY * (dataRangeY / chartRect!.height);

        // Calculate visible viewport bounds
        minX = centerX - rangeX / 2 + panDataX;
        maxX = centerX + rangeX / 2 + panDataX;
        minY = centerY - rangeY / 2 + panDataY;
        maxY = centerY + rangeY / 2 + panDataY;
      }
    }

    // Handle edge case where all values are the same
    if (minX == maxX) {
      minX -= 0.5;
      maxX += 0.5;
    }
    if (minY == maxY) {
      minY -= 0.5;
      maxY += 0.5;
    }

    // CRITICAL FIX: Add Y-axis padding to match _BravenChartPainter's bounds calculation
    // The main painter adds 10% padding AFTER zoom/pan, so we must do the same
    // to ensure annotations use the same coordinate space as rendered data points
    final yRange = maxY - minY;
    minY -= yRange * 0.1;
    maxY += yRange * 0.1;

    return _DataBounds(minX: minX, maxX: maxX, minY: minY, maxY: maxY);
  }
}

// ==================== RANGE ANNOTATION RESIZE WIDGET ====================

/// Interactive range annotation widget with resize handles.
///
/// Displays a range annotation with draggable handles on the left and right edges
/// for resizing the range along the x-axis.
class _RangeAnnotationWidget extends StatefulWidget {
  const _RangeAnnotationWidget({
    required this.annotation,
    required this.chartRect,
    required this.bounds,
    required this.clampedWidth,
    required this.clampedHeight,
    required this.interactiveAnnotations,
    required this.onAnnotationTap,
    this.onAnnotationUpdate,
    required this.dataToScreenPoint,
    this.onDragStateChanged,
  });

  final RangeAnnotation annotation;
  final Rect chartRect;
  final _DataBounds bounds;
  final double clampedWidth;
  final double clampedHeight;
  final bool interactiveAnnotations;
  final void Function(ChartAnnotation)? onAnnotationTap;
  final void Function(RangeAnnotation)? onAnnotationUpdate;
  final Offset Function(ChartDataPoint, Rect, _DataBounds) dataToScreenPoint;
  final void Function(String? edge)?
      onDragStateChanged; // edge is 'left', 'right', 'top', 'bottom', or null

  @override
  State<_RangeAnnotationWidget> createState() => _RangeAnnotationWidgetState();
}

class _RangeAnnotationWidgetState extends State<_RangeAnnotationWidget> {
  /// Which edge is being dragged (null = none, 'left'/'right' for X-axis, 'top'/'bottom' for Y-axis)
  String? _draggingEdge;

  /// Whether mouse is hovering over left handle (X-axis)
  bool _hoveringLeftHandle = false;

  /// Whether mouse is hovering over right handle (X-axis)
  bool _hoveringRightHandle = false;

  /// Whether mouse is hovering over top handle (Y-axis)
  bool _hoveringTopHandle = false;

  /// Whether mouse is hovering over bottom handle (Y-axis)
  bool _hoveringBottomHandle = false;

  /// Position where drag started (in local coordinates)
  double? _dragStartX;
  double? _dragStartY;

  /// Original values when drag began
  double? _originalStartX;
  double? _originalEndX;
  double? _originalStartY;
  double? _originalEndY;

  /// Size of the resize handles (width of the draggable hit area)
  static const double _handleHitWidth = 20.0;

  @override
  Widget build(BuildContext context) {
    // Check which type of range this is
    final hasExplicitXRange =
        widget.annotation.startX != null && widget.annotation.endX != null;
    final hasExplicitYRange =
        widget.annotation.startY != null && widget.annotation.endY != null;

    // DEBUG: Print annotation properties to verify
    print('🔍 RangeAnnotationWidget.build - id=${widget.annotation.id}');
    print('   allowEditing=${widget.annotation.allowEditing}');
    print('   allowDragging=${widget.annotation.allowDragging}');
    print('   interactiveAnnotations=${widget.interactiveAnnotations}');
    print('   hasExplicitXRange=$hasExplicitXRange');
    print('   hasExplicitYRange=$hasExplicitYRange');
    print(
        '   Handles will show: ${(hasExplicitXRange || hasExplicitYRange) && widget.interactiveAnnotations && widget.annotation.allowEditing}');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main range container with custom border drawing
        // CRITICAL: Wrap GestureDetector/CustomPaint in IgnorePointer so visual elements don't block hit zones from other annotations
        Positioned.fill(
          child: IgnorePointer(
            child: GestureDetector(
              onTap: widget.interactiveAnnotations &&
                      widget.onAnnotationTap != null
                  ? () => widget.onAnnotationTap!(widget.annotation)
                  : null,
              child: CustomPaint(
                painter: _RangeAnnotationPainter(
                  fillColor: widget.annotation.fillColor,
                  borderColor: widget.annotation.borderColor,
                  borderWidth: widget.annotation.style.borderWidth,
                  leftBorderHover:
                      _hoveringLeftHandle || _draggingEdge == 'left',
                  rightBorderHover:
                      _hoveringRightHandle || _draggingEdge == 'right',
                  topBorderHover: _hoveringTopHandle || _draggingEdge == 'top',
                  bottomBorderHover:
                      _hoveringBottomHandle || _draggingEdge == 'bottom',
                  hasExplicitXRange: hasExplicitXRange,
                  hasExplicitYRange: hasExplicitYRange,
                  isInteractive: widget.interactiveAnnotations,
                ),
                child: widget.annotation.label != null
                    ? _buildRangeLabel(widget.annotation, widget.clampedWidth,
                        widget.clampedHeight)
                    : null,
              ),
            ),
          ),
        ),

        // Left boundary hit zone (invisible, wide area for easy dragging)
        if (hasExplicitXRange &&
            widget.interactiveAnnotations &&
            widget.annotation.allowEditing)
          Positioned(
            left: -_handleHitWidth / 2,
            top: 0,
            bottom: 0,
            width: _handleHitWidth,
            child: MouseRegion(
              // CRITICAL: Must use translucent to allow unhandled events to pass through
              // Without this, MouseRegion blocks ALL pointer events including right-click/middle-click
              hitTestBehavior: HitTestBehavior.translucent,
              cursor: SystemMouseCursors.resizeLeftRight,
              onEnter: (_) {
                print('🟣 LEFT HANDLE MouseRegion ENTER');
                if (_draggingEdge == null) {
                  setState(() => _hoveringLeftHandle = true);
                }
              },
              onExit: (_) {
                print('🟣 LEFT HANDLE MouseRegion EXIT');
                if (_draggingEdge == null) {
                  setState(() => _hoveringLeftHandle = false);
                }
              },
              child: Listener(
                // CRITICAL: Use opaque so we ONLY handle left-click drag, everything else passes through
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) {
                  print(
                      '🟠 LEFT HANDLE Listener.onPointerDown - button=${event.buttons}');
                  // CRITICAL: Only handle left mouse button (primary button)
                  // Let right-clicks, middle-clicks pass through to GestureDetector for context menu and panning
                  if (event.buttons != 1) {
                    print(
                        '   ➡️ NOT button 1 - returning early to pass through');
                    return;
                  }

                  print('🎯 Left handle pointer down - HANDLING');
                  _startDrag('left', event.localPosition.dx, null);
                },
                onPointerMove: (event) {
                  if (_draggingEdge == 'left') {
                    _updateDrag(event.localPosition.dx, null, 'left');
                  }
                },
                onPointerUp: (event) {
                  print('🎯 Left handle pointer up');
                  if (_draggingEdge == 'left') {
                    _endDrag();
                  }
                },
              ),
            ),
          ),

        // Right boundary hit zone (invisible, wide area for easy dragging)
        if (hasExplicitXRange &&
            widget.interactiveAnnotations &&
            widget.annotation.allowEditing)
          Positioned(
            right: -_handleHitWidth / 2,
            top: 0,
            bottom: 0,
            width: _handleHitWidth,
            child: MouseRegion(
              // CRITICAL: Must use translucent to allow unhandled events to pass through
              // Without this, MouseRegion blocks ALL pointer events including right-click/middle-click
              hitTestBehavior: HitTestBehavior.translucent,
              cursor: SystemMouseCursors.resizeLeftRight,
              onEnter: (_) {
                if (_draggingEdge == null) {
                  setState(() => _hoveringRightHandle = true);
                }
              },
              onExit: (_) {
                if (_draggingEdge == null) {
                  setState(() => _hoveringRightHandle = false);
                }
              },
              child: Listener(
                // CRITICAL: Use opaque so we ONLY handle left-click drag, everything else passes through
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) {
                  // CRITICAL: Only handle left mouse button (primary button)
                  // Let right-clicks, middle-clicks pass through to GestureDetector for context menu and panning
                  if (event.buttons != 1) return;

                  print('🎯 Right handle pointer down');
                  _startDrag('right', event.localPosition.dx, null);
                },
                onPointerMove: (event) {
                  if (_draggingEdge == 'right') {
                    _updateDrag(event.localPosition.dx, null, 'right');
                  }
                },
                onPointerUp: (event) {
                  print('🎯 Right handle pointer up');
                  if (_draggingEdge == 'right') {
                    _endDrag();
                  }
                },
              ),
            ),
          ),

        // Top boundary hit zone (invisible, wide area for easy dragging)
        if (hasExplicitYRange &&
            widget.interactiveAnnotations &&
            widget.annotation.allowEditing)
          Positioned(
            top: -_handleHitWidth / 2,
            left: 0,
            right: 0,
            height: _handleHitWidth,
            child: MouseRegion(
              // CRITICAL: Must use translucent to allow unhandled events to pass through
              // Without this, MouseRegion blocks ALL pointer events including right-click/middle-click
              hitTestBehavior: HitTestBehavior.translucent,
              cursor: SystemMouseCursors.resizeUpDown,
              onEnter: (_) {
                print(
                    '🔵 Top handle ENTER event - _draggingEdge=$_draggingEdge');
                if (_draggingEdge == null) {
                  setState(() => _hoveringTopHandle = true);
                  print('   ✅ Set _hoveringTopHandle = true');
                }
              },
              onExit: (_) {
                print(
                    '🔴 Top handle EXIT event - _draggingEdge=$_draggingEdge');
                if (_draggingEdge == null) {
                  setState(() => _hoveringTopHandle = false);
                  print('   ✅ Set _hoveringTopHandle = false');
                }
              },
              child: Listener(
                // CRITICAL: Use opaque so we ONLY handle left-click drag, everything else passes through
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) {
                  // CRITICAL: Only handle left mouse button (primary button)
                  // Let right-clicks, middle-clicks pass through to GestureDetector for context menu and panning
                  if (event.buttons != 1) return;

                  print('🎯 Top handle pointer down');
                  _startDrag('top', null, event.localPosition.dy);
                },
                onPointerMove: (event) {
                  if (_draggingEdge == 'top') {
                    _updateDrag(null, event.localPosition.dy, 'top');
                  }
                },
                onPointerUp: (event) {
                  print('🎯 Top handle pointer up');
                  if (_draggingEdge == 'top') {
                    _endDrag();
                  }
                },
              ),
            ),
          ),

        // Bottom boundary hit zone (invisible, wide area for easy dragging)
        if (hasExplicitYRange &&
            widget.interactiveAnnotations &&
            widget.annotation.allowEditing)
          Positioned(
            bottom: -_handleHitWidth / 2,
            left: 0,
            right: 0,
            height: _handleHitWidth,
            child: MouseRegion(
              // CRITICAL: Must use translucent to allow unhandled events to pass through
              // Without this, MouseRegion blocks ALL pointer events including right-click/middle-click
              hitTestBehavior: HitTestBehavior.translucent,
              cursor: SystemMouseCursors.resizeUpDown,
              onEnter: (_) {
                print(
                    '🔵 Bottom handle ENTER event - _draggingEdge=$_draggingEdge');
                if (_draggingEdge == null) {
                  setState(() => _hoveringBottomHandle = true);
                  print('   ✅ Set _hoveringBottomHandle = true');
                }
              },
              onExit: (_) {
                print(
                    '🔴 Bottom handle EXIT event - _draggingEdge=$_draggingEdge');
                if (_draggingEdge == null) {
                  setState(() => _hoveringBottomHandle = false);
                  print('   ✅ Set _hoveringBottomHandle = false');
                }
              },
              child: Listener(
                // CRITICAL: Use opaque so we ONLY handle left-click drag, everything else passes through
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) {
                  // CRITICAL: Only handle left mouse button (primary button)
                  // Let right-clicks, middle-clicks pass through to GestureDetector for context menu and panning
                  if (event.buttons != 1) return;

                  print('🎯 Bottom handle pointer down');
                  _startDrag('bottom', null, event.localPosition.dy);
                },
                onPointerMove: (event) {
                  if (_draggingEdge == 'bottom') {
                    _updateDrag(null, event.localPosition.dy, 'bottom');
                  }
                },
                onPointerUp: (event) {
                  print('🎯 Bottom handle pointer up');
                  if (_draggingEdge == 'bottom') {
                    _endDrag();
                  }
                },
              ),
            ),
          ),
      ],
    );
  }

  /// Starts dragging an edge
  void _startDrag(String edge, double? localX, double? localY) {
    print('🎯 _startDrag called: edge=$edge, localX=$localX, localY=$localY');
    setState(() {
      _draggingEdge = edge;
      if (edge == 'left' || edge == 'right') {
        _dragStartX = localX;
        _originalStartX = widget.annotation.startX;
        _originalEndX = widget.annotation.endX;
      } else if (edge == 'top' || edge == 'bottom') {
        _dragStartY = localY;
        _originalStartY = widget.annotation.startY;
        _originalEndY = widget.annotation.endY;
      }
    });
    // Notify parent chart that dragging started
    widget.onDragStateChanged?.call(edge);
    print('   State updated: _draggingEdge=$_draggingEdge');
  }

  /// Updates the range based on current drag position
  void _updateDrag(double? currentX, double? currentY, String edge) {
    print(
        '📍 _updateDrag called: currentX=$currentX, currentY=$currentY, edge=$edge');

    if (edge == 'left' || edge == 'right') {
      // Handle X-axis dragging
      if (widget.annotation.startX == null || widget.annotation.endX == null) {
        print('   ❌ Skipped: infinite X range');
        return;
      }

      if (_dragStartX == null ||
          _originalStartX == null ||
          _originalEndX == null ||
          currentX == null) {
        print('   ❌ Skipped: X drag not initialized');
        return;
      }

      final deltaX = currentX - _dragStartX!;
      final xRange = widget.bounds.maxX - widget.bounds.minX;
      final screenWidth = widget.chartRect.width;
      final dataPerPixel = xRange / screenWidth;
      final dataDelta = deltaX * dataPerPixel;

      double newStartX = _originalStartX!;
      double newEndX = _originalEndX!;

      if (edge == 'left') {
        newStartX += dataDelta;
        if (newStartX >= newEndX) {
          newStartX = newEndX - (xRange * 0.01);
        }
      } else if (edge == 'right') {
        newEndX += dataDelta;
        if (newEndX <= newStartX) {
          newEndX = newStartX + (xRange * 0.01);
        }
      }

      if (widget.annotation.snapToValue) {
        newStartX = _snapToNearestValue(newStartX);
        newEndX = _snapToNearestValue(newEndX);
      }

      final updatedAnnotation = widget.annotation.copyWith(
        startX: newStartX,
        endX: newEndX,
      );

      print(
          '   ✅ Calling onAnnotationUpdate: newStartX=$newStartX, newEndX=$newEndX');
      widget.onAnnotationUpdate?.call(updatedAnnotation);
    } else if (edge == 'top' || edge == 'bottom') {
      // Handle Y-axis dragging
      if (widget.annotation.startY == null || widget.annotation.endY == null) {
        print('   ❌ Skipped: infinite Y range');
        return;
      }

      if (_dragStartY == null ||
          _originalStartY == null ||
          _originalEndY == null ||
          currentY == null) {
        print('   ❌ Skipped: Y drag not initialized');
        return;
      }

      final deltaY = currentY - _dragStartY!;
      final yRange = widget.bounds.maxY - widget.bounds.minY;
      final screenHeight = widget.chartRect.height;
      final dataPerPixel = yRange / screenHeight;
      // Y-axis is inverted: screen Y increases downward, data Y increases upward
      final dataDelta = -deltaY * dataPerPixel;

      double newStartY = _originalStartY!;
      double newEndY = _originalEndY!;

      if (edge == 'top') {
        // Top edge controls the higher Y value (endY)
        newEndY += dataDelta;
        if (newEndY <= newStartY) {
          newEndY = newStartY + (yRange * 0.01);
        }
      } else if (edge == 'bottom') {
        // Bottom edge controls the lower Y value (startY)
        newStartY += dataDelta;
        if (newStartY >= newEndY) {
          newStartY = newEndY - (yRange * 0.01);
        }
      }

      if (widget.annotation.snapToValue) {
        newStartY = _snapToNearestValue(newStartY);
        newEndY = _snapToNearestValue(newEndY);
      }

      final updatedAnnotation = widget.annotation.copyWith(
        startY: newStartY,
        endY: newEndY,
      );

      print(
          '   ✅ Calling onAnnotationUpdate: newStartY=$newStartY, newEndY=$newEndY');
      widget.onAnnotationUpdate?.call(updatedAnnotation);
    }
  }

  /// Ends dragging
  void _endDrag() {
    print('🏁 _endDrag called');
    setState(() {
      _draggingEdge = null;
      _dragStartX = null;
      _dragStartY = null;
      _originalStartX = null;
      _originalEndX = null;
      _originalStartY = null;
      _originalEndY = null;
      // Reset all hover states so borders return to normal
      _hoveringLeftHandle = false;
      _hoveringRightHandle = false;
      _hoveringTopHandle = false;
      _hoveringBottomHandle = false;
    });
    // Notify parent chart that dragging ended
    widget.onDragStateChanged?.call(null);
  }

  /// Snaps a value to the nearest increment based on the annotation's snapIncrement.
  ///
  /// This provides a smoother user experience by aligning annotations
  /// with specific value increments (e.g., 0.5, 1.0, 10.0) rather than
  /// arbitrary positions.
  double _snapToNearestValue(double value) {
    final increment = widget.annotation.snapIncrement;
    // TODO: In the future, could also snap to actual data point X values from the series
    return (value / increment).roundToDouble() * increment;
  }

  /// Builds a positioned label widget for range annotations.
  Widget _buildRangeLabel(
      RangeAnnotation annotation, double width, double height) {
    Alignment alignment;
    EdgeInsets padding;

    // Position label according to labelPosition setting
    switch (annotation.labelPosition) {
      case AnnotationLabelPosition.topLeft:
        alignment = Alignment.topLeft;
        padding = const EdgeInsets.all(4);
        break;
      case AnnotationLabelPosition.topRight:
        alignment = Alignment.topRight;
        padding = const EdgeInsets.all(4);
        break;
      case AnnotationLabelPosition.bottomLeft:
        alignment = Alignment.bottomLeft;
        padding = const EdgeInsets.all(4);
        break;
      case AnnotationLabelPosition.bottomRight:
        alignment = Alignment.bottomRight;
        padding = const EdgeInsets.all(4);
        break;
      case AnnotationLabelPosition.center:
        alignment = Alignment.center;
        padding = EdgeInsets.zero;
        break;
    }

    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: Container(
          padding: annotation.style.padding ??
              const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: annotation.style.backgroundColor ??
                Colors.white.withOpacity(0.9),
            borderRadius:
                annotation.style.borderRadius ?? BorderRadius.circular(4),
            border: annotation.style.borderColor != null
                ? Border.all(color: annotation.style.borderColor!, width: 1)
                : null,
          ),
          child: Text(annotation.label!, style: annotation.style.textStyle),
        ),
      ),
    );
  }
}

// ==================== ANNOTATION PAINTERS ====================

/// Custom painter for range annotation borders with interactive styling.
class _RangeAnnotationPainter extends CustomPainter {
  _RangeAnnotationPainter({
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
    required this.leftBorderHover,
    required this.rightBorderHover,
    required this.topBorderHover,
    required this.bottomBorderHover,
    required this.hasExplicitXRange,
    required this.hasExplicitYRange,
    required this.isInteractive,
  });

  final Color? fillColor;
  final Color? borderColor;
  final double borderWidth;
  final bool leftBorderHover;
  final bool rightBorderHover;
  final bool topBorderHover;
  final bool bottomBorderHover;
  final bool hasExplicitXRange;
  final bool hasExplicitYRange;
  final bool isInteractive;

  @override
  void paint(Canvas canvas, Size size) {
    // Debug print to see if painter is receiving hover states
    if (topBorderHover ||
        bottomBorderHover ||
        leftBorderHover ||
        rightBorderHover) {
      print(
          '🎨 PAINTER: topHover=$topBorderHover, bottomHover=$bottomBorderHover, leftHover=$leftBorderHover, rightHover=$rightBorderHover');
      print(
          '   hasExplicitYRange=$hasExplicitYRange, isInteractive=$isInteractive');
    }

    // Draw fill
    if (fillColor != null) {
      final fillPaint = Paint()
        ..color = fillColor!
        ..style = PaintingStyle.fill;
      canvas.drawRect(Offset.zero & size, fillPaint);
    }

    // Draw borders
    if (borderColor != null) {
      // Top border (special styling if interactive Y-range and hovering)
      if (hasExplicitYRange && isInteractive && topBorderHover) {
        final topPaint = Paint()
          ..color = borderColor!
          ..strokeWidth = 3.0 // Thicker when hovering
          ..style = PaintingStyle.stroke;

        // Draw dashed line
        _drawDashedLine(
            canvas, const Offset(0, 0), Offset(size.width, 0), topPaint,
            dashLength: 8, gapLength: 4);
      } else {
        final topPaint = Paint()
          ..color = borderColor!
          ..strokeWidth = borderWidth
          ..style = PaintingStyle.stroke;
        canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), topPaint);
      }

      // Bottom border (special styling if interactive Y-range and hovering)
      if (hasExplicitYRange && isInteractive && bottomBorderHover) {
        final bottomPaint = Paint()
          ..color = borderColor!
          ..strokeWidth = 3.0 // Thicker when hovering
          ..style = PaintingStyle.stroke;

        // Draw dashed line
        _drawDashedLine(canvas, Offset(0, size.height),
            Offset(size.width, size.height), bottomPaint,
            dashLength: 8, gapLength: 4);
      } else {
        final bottomPaint = Paint()
          ..color = borderColor!
          ..strokeWidth = borderWidth
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height),
            bottomPaint);
      }

      // Left border (special styling if interactive X-range and hovering)
      if (hasExplicitXRange && isInteractive && leftBorderHover) {
        final leftPaint = Paint()
          ..color = borderColor!
          ..strokeWidth = 3.0 // Thicker when hovering
          ..style = PaintingStyle.stroke;

        // Draw dashed line
        _drawDashedLine(
            canvas, const Offset(0, 0), Offset(0, size.height), leftPaint,
            dashLength: 8, gapLength: 4);
      } else {
        final leftPaint = Paint()
          ..color = borderColor!
          ..strokeWidth = borderWidth
          ..style = PaintingStyle.stroke;
        canvas.drawLine(const Offset(0, 0), Offset(0, size.height), leftPaint);
      }

      // Right border (special styling if interactive X-range and hovering)
      if (hasExplicitXRange && isInteractive && rightBorderHover) {
        final rightPaint = Paint()
          ..color = borderColor!
          ..strokeWidth = 3.0 // Thicker when hovering
          ..style = PaintingStyle.stroke;

        // Draw dashed line
        _drawDashedLine(canvas, Offset(size.width, 0),
            Offset(size.width, size.height), rightPaint,
            dashLength: 8, gapLength: 4);
      } else {
        final rightPaint = Paint()
          ..color = borderColor!
          ..strokeWidth = borderWidth
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
            Offset(size.width, 0), Offset(size.width, size.height), rightPaint);
      }
    }
  }

  /// Helper to draw dashed lines
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint,
      {required double dashLength, required double gapLength}) {
    final totalDistance = (end - start).distance;
    final dashCount = (totalDistance / (dashLength + gapLength)).floor();

    final direction = (end - start) / totalDistance;

    for (int i = 0; i < dashCount; i++) {
      final dashStart = start + direction * (i * (dashLength + gapLength));
      final dashEnd =
          start + direction * (i * (dashLength + gapLength) + dashLength);
      canvas.drawLine(dashStart, dashEnd, paint);
    }
  }

  @override
  bool shouldRepaint(_RangeAnnotationPainter oldDelegate) {
    return leftBorderHover != oldDelegate.leftBorderHover ||
        rightBorderHover != oldDelegate.rightBorderHover ||
        topBorderHover != oldDelegate.topBorderHover ||
        bottomBorderHover != oldDelegate.bottomBorderHover ||
        fillColor != oldDelegate.fillColor ||
        borderColor != oldDelegate.borderColor ||
        borderWidth != oldDelegate.borderWidth;
  }
}

/// Custom painter for marker shapes.
class _MarkerPainter extends CustomPainter {
  _MarkerPainter(
      {required this.shape, required this.size, required this.color});

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
            paint);
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
        canvas.drawLine(Offset(center.dx - size, center.dy),
            Offset(center.dx + size, center.dy), paint);
        canvas.drawLine(Offset(center.dx, center.dy - size),
            Offset(center.dx, center.dy + size), paint);
        break;
      case MarkerShape.plus:
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2;
        canvas.drawLine(Offset(center.dx - size, center.dy),
            Offset(center.dx + size, center.dy), paint);
        canvas.drawLine(Offset(center.dx, center.dy - size),
            Offset(center.dx, center.dy + size), paint);
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
    return shape != oldDelegate.shape ||
        size != oldDelegate.size ||
        color != oldDelegate.color;
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
    required this.chartRect,
    required this.bounds,
    required this.titleOffset,
  });

  final AnnotationAxis axis;
  final double value;
  final Color color;
  final double width;
  final List<double>? dashPattern;
  final Rect chartRect;
  final _DataBounds bounds;
  final Offset titleOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    // PHASE 1, TASK 1.3: Use coordinate transformation
    if (axis == AnnotationAxis.y) {
      // Horizontal line at Y value
      // Transform the Y data value to screen coordinate
      final yRange = bounds.maxY - bounds.minY;
      final yPercent = yRange == 0 ? 0.5 : (value - bounds.minY) / yRange;
      final pixelY = chartRect.bottom - (yPercent * chartRect.height);
      final y = pixelY + titleOffset.dy;

      // Draw line across the full width of the chart
      final startX = chartRect.left + titleOffset.dx;
      final endX = chartRect.right + titleOffset.dx;

      if (dashPattern != null && dashPattern!.isNotEmpty) {
        _drawDashedLine(
            canvas, Offset(startX, y), Offset(endX, y), paint, dashPattern!);
      } else {
        canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
      }
    } else {
      // Vertical line at X value
      // Transform the X data value to screen coordinate
      final xRange = bounds.maxX - bounds.minX;
      final xPercent = xRange == 0 ? 0.5 : (value - bounds.minX) / xRange;
      final pixelX = chartRect.left + (xPercent * chartRect.width);
      final x = pixelX + titleOffset.dx;

      // Draw line across the full height of the chart
      final startY = chartRect.top + titleOffset.dy;
      final endY = chartRect.bottom + titleOffset.dy;

      if (dashPattern != null && dashPattern!.isNotEmpty) {
        _drawDashedLine(
            canvas, Offset(x, startY), Offset(x, endY), paint, dashPattern!);
      } else {
        canvas.drawLine(Offset(x, startY), Offset(x, endY), paint);
      }
    }
  }

  /// Draws a dashed line between two points.
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint,
      List<double> dashPattern) {
    final path = Path();
    final totalDistance = (end - start).distance;
    var currentDistance = 0.0;
    var patternIndex = 0;
    var isDash = true;

    while (currentDistance < totalDistance) {
      final dashLength = dashPattern[patternIndex % dashPattern.length];
      final nextDistance =
          (currentDistance + dashLength).clamp(0.0, totalDistance);

      if (isDash) {
        final t1 = currentDistance / totalDistance;
        final t2 = nextDistance / totalDistance;
        final p1 = Offset.lerp(start, end, t1)!;
        final p2 = Offset.lerp(start, end, t2)!;
        path.moveTo(p1.dx, p1.dy);
        path.lineTo(p2.dx, p2.dy);
      }

      currentDistance = nextDistance;
      patternIndex++;
      isDash = !isDash;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ThresholdPainter oldDelegate) {
    return axis != oldDelegate.axis ||
        value != oldDelegate.value ||
        color != oldDelegate.color ||
        width != oldDelegate.width ||
        chartRect != oldDelegate.chartRect ||
        bounds != oldDelegate.bounds ||
        titleOffset != oldDelegate.titleOffset;
  }
}

/// Custom painter for trend lines.
class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.trendPoints,
    required this.bounds,
    required this.chartRect,
    required this.titleOffset,
    required this.lineColor,
    required this.lineWidth,
    this.dashPattern,
  });

  final List<ChartDataPoint> trendPoints;
  final _DataBounds bounds;
  final Rect chartRect;
  final Offset titleOffset;
  final Color lineColor;
  final double lineWidth;
  final List<double>? dashPattern;

  @override
  void paint(Canvas canvas, Size size) {
    if (trendPoints.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth;

    // Transform trend points from data coordinates to screen coordinates
    final screenPoints = <Offset>[];
    for (final point in trendPoints) {
      // Calculate percentage within data bounds
      final xRange = bounds.maxX - bounds.minX;
      final yRange = bounds.maxY - bounds.minY;

      final xPercent = xRange == 0 ? 0.5 : (point.x - bounds.minX) / xRange;
      final yPercent = yRange == 0 ? 0.5 : (point.y - bounds.minY) / yRange;

      // Convert to screen pixels
      final screenX =
          chartRect.left + titleOffset.dx + (xPercent * chartRect.width);
      final screenY =
          chartRect.bottom + titleOffset.dy - (yPercent * chartRect.height);

      screenPoints.add(Offset(screenX, screenY));
    }

    // Draw trend line
    if (screenPoints.length >= 2) {
      if (dashPattern != null && dashPattern!.isNotEmpty) {
        // Draw dashed line
        _drawDashedPath(canvas, screenPoints, paint, dashPattern!);
      } else {
        // Draw solid line
        final path = Path()
          ..moveTo(screenPoints.first.dx, screenPoints.first.dy);
        for (int i = 1; i < screenPoints.length; i++) {
          path.lineTo(screenPoints[i].dx, screenPoints[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  /// Helper method to draw a dashed path through multiple points
  void _drawDashedPath(
      Canvas canvas, List<Offset> points, Paint paint, List<double> pattern) {
    if (points.length < 2) return;

    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];

      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final segmentLength = sqrt(dx * dx + dy * dy);

      double distance = 0;
      int patternIndex = 0;
      bool draw = true;

      while (distance < segmentLength) {
        final patternLength = pattern[patternIndex % pattern.length];
        final nextDistance =
            (distance + patternLength).clamp(0.0, segmentLength);

        if (draw) {
          final t1 = distance / segmentLength;
          final t2 = nextDistance / segmentLength;

          final x1 = start.dx + dx * t1;
          final y1 = start.dy + dy * t1;
          final x2 = start.dx + dx * t2;
          final y2 = start.dy + dy * t2;

          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
        }

        distance = nextDistance;
        patternIndex++;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) {
    return trendPoints != oldDelegate.trendPoints ||
        bounds != oldDelegate.bounds ||
        chartRect != oldDelegate.chartRect ||
        titleOffset != oldDelegate.titleOffset ||
        lineColor != oldDelegate.lineColor ||
        lineWidth != oldDelegate.lineWidth ||
        dashPattern != oldDelegate.dashPattern;
  }
}

/// Custom painter for crosshair LINES only (clipped to chart area).
///
/// Renders crosshair lines and snap point circle, but NOT coordinate labels.
/// Designed to be clipped to chart bounds to prevent drawing over scrollbars.
class _CrosshairLinesPainter extends CustomPainter {
  _CrosshairLinesPainter(
      {required this.position,
      required this.config,
      this.nearestPoint,
      required this.chartSize});

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
    if (config.mode == CrosshairMode.vertical ||
        config.mode == CrosshairMode.both) {
      if (config.style.dashPattern != null &&
          config.style.dashPattern!.isNotEmpty) {
        _drawDashedLine(canvas, Offset(position.dx, 0),
            Offset(position.dx, size.height), paint, config.style.dashPattern!);
      } else {
        canvas.drawLine(
            Offset(position.dx, 0), Offset(position.dx, size.height), paint);
      }
    }

    // Draw horizontal line for horizontal and both modes
    if (config.mode == CrosshairMode.horizontal ||
        config.mode == CrosshairMode.both) {
      if (config.style.dashPattern != null &&
          config.style.dashPattern!.isNotEmpty) {
        _drawDashedLine(canvas, Offset(0, position.dy),
            Offset(size.width, position.dy), paint, config.style.dashPattern!);
      } else {
        canvas.drawLine(
            Offset(0, position.dy), Offset(size.width, position.dy), paint);
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
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint,
      List<double> dashPattern) {
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
        path.moveTo(start.dx + dx * startRatio, start.dy + dy * startRatio);
        path.lineTo(start.dx + dx * endRatio, start.dy + dy * endRatio);
      }

      currentDistance = nextDistance;
      patternIndex++;
      isDash = !isDash;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CrosshairLinesPainter oldDelegate) {
    return position != oldDelegate.position ||
        config != oldDelegate.config ||
        nearestPoint != oldDelegate.nearestPoint;
  }
}

/// Custom painter for crosshair COORDINATE LABELS only (unclipped).
///
/// Renders X and Y coordinate labels at chart edges.
/// NOT clipped so labels remain visible even when crosshair is near chart bounds.
class _CrosshairLabelsPainter extends CustomPainter {
  _CrosshairLabelsPainter(
      {required this.position,
      required this.config,
      this.dataBounds,
      this.chartRect});

  final Offset position;
  final CrosshairConfig config;
  final _DataBounds? dataBounds;
  final Rect? chartRect;

  @override
  void paint(Canvas canvas, Size size) {
    if (!config.enabled || !config.showCoordinateLabels) return;

    _drawCoordinateLabels(canvas, size);
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
        final yPercent =
            1.0 - ((position.dy - chartRect!.top) / chartRect!.height);

        // Convert to data coordinates
        dataX = dataBounds!.minX + (xPercent * xRange);
        dataY = dataBounds!.minY + (yPercent * yRange);
      }

      final textStyle = config.coordinateLabelStyle ??
          TextStyle(
              color: config.style.labelTextColor,
              fontSize: 10,
              backgroundColor:
                  config.style.labelBackgroundColor.withOpacity(0.8));

      // X coordinate label (positioned at bottom edge of chart area, INSIDE chartRect)
      if (config.mode == CrosshairMode.vertical ||
          config.mode == CrosshairMode.both) {
        // Use data X value if available, otherwise fall back to screen position
        final displayValue = dataX != null
            ? _formatDataValue(dataX)
            : position.dx.toStringAsFixed(0);

        final xTextPainter = TextPainter(
          text: TextSpan(text: 'X: $displayValue', style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();

        // Position label INSIDE chart area (just above bottom edge of chartRect)
        // Use chartRect bounds if available, otherwise fall back to canvas size
        final chartBottom = chartRect?.bottom ?? size.height;

        // Calculate label position with bounds checking
        var xLabelX = position.dx - xTextPainter.width / 2;
        final xLabelY = chartBottom -
            xTextPainter.height -
            8; // 8px padding from chart bottom

        // Clamp X position to keep label within chart bounds (if chartRect available)
        if (chartRect != null) {
          xLabelX = xLabelX.clamp(
              chartRect!.left + config.style.labelPadding,
              chartRect!.right -
                  xTextPainter.width -
                  config.style.labelPadding);
        } else {
          xLabelX = xLabelX.clamp(config.style.labelPadding,
              size.width - xTextPainter.width - config.style.labelPadding);
        }

        // Only draw if Y position is valid and all values are finite
        if (xLabelY >= 0 &&
            xLabelY + xTextPainter.height <= size.height &&
            xLabelX.isFinite &&
            xLabelY.isFinite) {
          final xLabelOffset = Offset(xLabelX, xLabelY);

          // Draw background with validated dimensions
          final bgLeft = xLabelOffset.dx - config.style.labelPadding;
          final bgTop = xLabelOffset.dy - config.style.labelPadding;
          final bgWidth = xTextPainter.width + config.style.labelPadding * 2;
          final bgHeight = xTextPainter.height + config.style.labelPadding * 2;

          // Additional validation for rect dimensions
          if (bgLeft.isFinite &&
              bgTop.isFinite &&
              bgWidth.isFinite &&
              bgHeight.isFinite &&
              bgWidth > 0 &&
              bgHeight > 0) {
            final xBgRect = Rect.fromLTWH(bgLeft, bgTop, bgWidth, bgHeight);
            canvas.drawRect(
                xBgRect, Paint()..color = config.style.labelBackgroundColor);
            xTextPainter.paint(canvas, xLabelOffset);
          }
        }
      }

      // Y coordinate label (positioned at left edge of chart area, INSIDE chartRect)
      if (config.mode == CrosshairMode.horizontal ||
          config.mode == CrosshairMode.both) {
        // Use data Y value if available, otherwise fall back to screen position
        final displayValue = dataY != null
            ? _formatDataValue(dataY)
            : position.dy.toStringAsFixed(0);

        final yTextPainter = TextPainter(
          text: TextSpan(text: 'Y: $displayValue', style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();

        // Position label INSIDE chart area (just right of left edge of chartRect)
        // Use chartRect bounds if available, otherwise fall back to canvas edge
        final chartLeft = chartRect?.left ?? 0.0;

        // Calculate label position with bounds checking
        final yLabelX = chartLeft + 8.0; // 8px padding from chart left edge
        var yLabelY = position.dy - yTextPainter.height / 2;

        // Clamp Y position to keep label within chart bounds (if chartRect available)
        if (chartRect != null) {
          yLabelY = yLabelY.clamp(
              chartRect!.top + config.style.labelPadding,
              chartRect!.bottom -
                  yTextPainter.height -
                  config.style.labelPadding);
        } else {
          yLabelY = yLabelY.clamp(config.style.labelPadding,
              size.height - yTextPainter.height - config.style.labelPadding);
        }

        // Only draw if X position is valid and all values are finite
        if (yLabelX >= 0 &&
            yLabelX + yTextPainter.width <= size.width &&
            yLabelX.isFinite &&
            yLabelY.isFinite) {
          final yLabelOffset = Offset(yLabelX, yLabelY);

          // Draw background with validated dimensions
          final bgLeft = yLabelOffset.dx - config.style.labelPadding;
          final bgTop = yLabelOffset.dy - config.style.labelPadding;
          final bgWidth = yTextPainter.width + config.style.labelPadding * 2;
          final bgHeight = yTextPainter.height + config.style.labelPadding * 2;

          // Additional validation for rect dimensions
          if (bgLeft.isFinite &&
              bgTop.isFinite &&
              bgWidth.isFinite &&
              bgHeight.isFinite &&
              bgWidth > 0 &&
              bgHeight > 0) {
            final yBgRect = Rect.fromLTWH(bgLeft, bgTop, bgWidth, bgHeight);
            canvas.drawRect(
                yBgRect, Paint()..color = config.style.labelBackgroundColor);
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
  bool shouldRepaint(_CrosshairLabelsPainter oldDelegate) {
    return position != oldDelegate.position ||
        config != oldDelegate.config ||
        dataBounds != oldDelegate.dataBounds ||
        chartRect != oldDelegate.chartRect;
  }
}

/// Custom painter for crosshair rendering (DEPRECATED - split into Lines + Labels).
///
/// This painter is no longer used but kept for reference during migration.
/// Use _CrosshairLinesPainter + _CrosshairLabelsPainter instead.
class _CrosshairPainter extends CustomPainter {
  _CrosshairPainter(
      {required this.position,
      required this.config,
      this.nearestPoint,
      required this.chartSize,
      this.dataBounds,
      this.chartRect});

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
    if (config.mode == CrosshairMode.vertical ||
        config.mode == CrosshairMode.both) {
      if (config.style.dashPattern != null &&
          config.style.dashPattern!.isNotEmpty) {
        _drawDashedLine(canvas, Offset(position.dx, 0),
            Offset(position.dx, size.height), paint, config.style.dashPattern!);
      } else {
        canvas.drawLine(
            Offset(position.dx, 0), Offset(position.dx, size.height), paint);
      }
    }

    // Draw horizontal line for horizontal and both modes
    if (config.mode == CrosshairMode.horizontal ||
        config.mode == CrosshairMode.both) {
      if (config.style.dashPattern != null &&
          config.style.dashPattern!.isNotEmpty) {
        _drawDashedLine(canvas, Offset(0, position.dy),
            Offset(size.width, position.dy), paint, config.style.dashPattern!);
      } else {
        canvas.drawLine(
            Offset(0, position.dy), Offset(size.width, position.dy), paint);
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

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint,
      List<double> dashPattern) {
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
        path.moveTo(start.dx + dx * startRatio, start.dy + dy * startRatio);
        path.lineTo(start.dx + dx * endRatio, start.dy + dy * endRatio);
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
        final yPercent =
            1.0 - ((position.dy - chartRect!.top) / chartRect!.height);

        // Convert to data coordinates
        dataX = dataBounds!.minX + (xPercent * xRange);
        dataY = dataBounds!.minY + (yPercent * yRange);
      }

      final textStyle = config.coordinateLabelStyle ??
          TextStyle(
              color: config.style.labelTextColor,
              fontSize: 10,
              backgroundColor:
                  config.style.labelBackgroundColor.withOpacity(0.8));

      // X coordinate label (bottom of vertical line)
      if (config.mode == CrosshairMode.vertical ||
          config.mode == CrosshairMode.both) {
        // Use data X value if available, otherwise fall back to screen position
        final displayValue = dataX != null
            ? _formatDataValue(dataX)
            : position.dx.toStringAsFixed(0);

        final xTextPainter = TextPainter(
          text: TextSpan(text: 'X: $displayValue', style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();

        // Calculate label position with bounds checking
        var xLabelX = position.dx - xTextPainter.width / 2;
        final xLabelY = size.height - xTextPainter.height - 4;

        // Clamp X position to keep label within canvas bounds
        xLabelX = xLabelX.clamp(config.style.labelPadding,
            size.width - xTextPainter.width - config.style.labelPadding);

        // Only draw if Y position is valid and all values are finite
        if (xLabelY >= 0 &&
            xLabelY + xTextPainter.height <= size.height &&
            xLabelX.isFinite &&
            xLabelY.isFinite) {
          final xLabelOffset = Offset(xLabelX, xLabelY);

          // Draw background with validated dimensions
          final bgLeft = xLabelOffset.dx - config.style.labelPadding;
          final bgTop = xLabelOffset.dy - config.style.labelPadding;
          final bgWidth = xTextPainter.width + config.style.labelPadding * 2;
          final bgHeight = xTextPainter.height + config.style.labelPadding * 2;

          // Additional validation for rect dimensions
          if (bgLeft.isFinite &&
              bgTop.isFinite &&
              bgWidth.isFinite &&
              bgHeight.isFinite &&
              bgWidth > 0 &&
              bgHeight > 0) {
            final xBgRect = Rect.fromLTWH(bgLeft, bgTop, bgWidth, bgHeight);
            canvas.drawRect(
                xBgRect, Paint()..color = config.style.labelBackgroundColor);
            xTextPainter.paint(canvas, xLabelOffset);
          }
        }
      }

      // Y coordinate label (left of horizontal line)
      if (config.mode == CrosshairMode.horizontal ||
          config.mode == CrosshairMode.both) {
        // Use data Y value if available, otherwise fall back to screen position
        final displayValue = dataY != null
            ? _formatDataValue(dataY)
            : position.dy.toStringAsFixed(0);

        final yTextPainter = TextPainter(
          text: TextSpan(text: 'Y: $displayValue', style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();

        // Calculate label position with bounds checking
        const yLabelX = 4.0;
        var yLabelY = position.dy - yTextPainter.height / 2;

        // Clamp Y position to keep label within canvas bounds
        yLabelY = yLabelY.clamp(config.style.labelPadding,
            size.height - yTextPainter.height - config.style.labelPadding);

        // Only draw if X position is valid and all values are finite
        if (yLabelX >= 0 &&
            yLabelX + yTextPainter.width <= size.width &&
            yLabelX.isFinite &&
            yLabelY.isFinite) {
          final yLabelOffset = Offset(yLabelX, yLabelY);

          // Draw background with validated dimensions
          final bgLeft = yLabelOffset.dx - config.style.labelPadding;
          final bgTop = yLabelOffset.dy - config.style.labelPadding;
          final bgWidth = yTextPainter.width + config.style.labelPadding * 2;
          final bgHeight = yTextPainter.height + config.style.labelPadding * 2;

          // Additional validation for rect dimensions
          if (bgLeft.isFinite &&
              bgTop.isFinite &&
              bgWidth.isFinite &&
              bgHeight.isFinite &&
              bgWidth > 0 &&
              bgHeight > 0) {
            final yBgRect = Rect.fromLTWH(bgLeft, bgTop, bgWidth, bgHeight);
            canvas.drawRect(
                yBgRect, Paint()..color = config.style.labelBackgroundColor);
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
enum _ArrowPosition { top, bottom, left, right }

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
        const arrowOffsetX = 20.0;
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
        path.quadraticBezierTo(
            rect.right, rect.top, rect.right, rect.top + radius);
        // Right side
        path.lineTo(rect.right, rect.bottom - radius);
        path.quadraticBezierTo(
            rect.right, rect.bottom, rect.right - radius, rect.bottom);
        // Bottom-right to bottom-left
        path.lineTo(rect.left + radius, rect.bottom);
        path.quadraticBezierTo(
            rect.left, rect.bottom, rect.left, rect.bottom - radius);
        // Left side back to start
        path.lineTo(rect.left, rect.top + radius);
        path.quadraticBezierTo(
            rect.left, rect.top, rect.left + radius, rect.top);
        break;

      case _ArrowPosition.bottom:
        // Arrow notch on bottom edge at FIXED offset from left (not centered)
        const arrowOffsetX = 20.0;
        final arrowLeft = arrowOffsetX - arrowSize / 2;
        final arrowRight = arrowOffsetX + arrowSize / 2;
        final arrowBottom = rect.bottom + arrowSize;

        path.moveTo(rect.left + radius, rect.top);
        // Top side
        path.lineTo(rect.right - radius, rect.top);
        path.quadraticBezierTo(
            rect.right, rect.top, rect.right, rect.top + radius);
        // Right side
        path.lineTo(rect.right, rect.bottom - radius);
        path.quadraticBezierTo(
            rect.right, rect.bottom, rect.right - radius, rect.bottom);
        // Bottom-right to arrow start
        path.lineTo(rect.left + arrowRight, rect.bottom);
        // Arrow notch down
        path.lineTo(rect.left + arrowOffsetX, arrowBottom);
        // Arrow notch back to left
        path.lineTo(rect.left + arrowLeft, rect.bottom);
        // Bottom-left corner
        path.lineTo(rect.left + radius, rect.bottom);
        path.quadraticBezierTo(
            rect.left, rect.bottom, rect.left, rect.bottom - radius);
        // Left side
        path.lineTo(rect.left, rect.top + radius);
        path.quadraticBezierTo(
            rect.left, rect.top, rect.left + radius, rect.top);
        break;

      case _ArrowPosition.left:
        // Arrow notch on left edge at FIXED offset from top (not centered)
        const arrowOffsetY = 20.0;
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
        path.quadraticBezierTo(
            rect.left, rect.bottom, rect.left + radius, rect.bottom);
        // Bottom side
        path.lineTo(rect.right - radius, rect.bottom);
        path.quadraticBezierTo(
            rect.right, rect.bottom, rect.right, rect.bottom - radius);
        // Right side
        path.lineTo(rect.right, rect.top + radius);
        path.quadraticBezierTo(
            rect.right, rect.top, rect.right - radius, rect.top);
        // Top side back to start
        path.lineTo(rect.left + radius, rect.top);
        path.quadraticBezierTo(
            rect.left, rect.top, rect.left, rect.top + radius);
        break;

      case _ArrowPosition.right:
        // Arrow notch on right edge at FIXED offset from top (not centered)
        const arrowOffsetY = 20.0;
        final arrowTop = arrowOffsetY - arrowSize / 2;
        final arrowBottom = arrowOffsetY + arrowSize / 2;
        final arrowRight = rect.right + arrowSize;

        path.moveTo(rect.left + radius, rect.top);
        // Top side
        path.lineTo(rect.right - radius, rect.top);
        path.quadraticBezierTo(
            rect.right, rect.top, rect.right, rect.top + radius);
        // Right side to arrow start
        path.lineTo(rect.right, rect.top + arrowTop);
        // Arrow notch right
        path.lineTo(arrowRight, rect.top + arrowOffsetY);
        // Arrow notch back to bottom
        path.lineTo(rect.right, rect.top + arrowBottom);
        // Right side continues down
        path.lineTo(rect.right, rect.bottom - radius);
        path.quadraticBezierTo(
            rect.right, rect.bottom, rect.right - radius, rect.bottom);
        // Bottom side
        path.lineTo(rect.left + radius, rect.bottom);
        path.quadraticBezierTo(
            rect.left, rect.bottom, rect.left, rect.bottom - radius);
        // Left side back to start
        path.lineTo(rect.left, rect.top + radius);
        path.quadraticBezierTo(
            rect.left, rect.top, rect.left + radius, rect.top);
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
