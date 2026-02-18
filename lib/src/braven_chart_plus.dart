// Copyright (c) 2025 braven_charts. All rights reserved.
// BravenChartPlus - Integration of Prototype Interaction System
// NO REFERENCES TO lib/src - COMPLETELY ISOLATED

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// All dependencies are in src - the main source folder
import 'analysis/region_analyzer.dart';
import 'axis/axis.dart' as chart_axis;
import 'axis/normalization_detector.dart';
import 'controllers/annotation_controller.dart';
import 'controllers/chart_controller.dart';
import 'coordinates/chart_transform.dart';
import 'elements/annotation_elements.dart';
import 'elements/series_element.dart';
import 'interaction/core/chart_element.dart';
import 'interaction/core/coordinator.dart';
import 'interaction/core/interaction_mode.dart';
import 'interaction/recognizers/priority_pan_recognizer.dart';
import 'interaction/recognizers/priority_tap_recognizer.dart';
import 'models/auto_scroll_config.dart';
import 'models/chart_annotation.dart';
import 'models/chart_data_point.dart';
import 'models/chart_series.dart';
import 'models/chart_theme.dart';
import 'models/chart_type.dart';
import 'models/data_range.dart';
import 'models/data_region.dart';
import 'models/enums.dart';
import 'models/grid_config.dart';
import 'models/interaction_callbacks.dart';
import 'models/interaction_config.dart';
import 'models/legend_style.dart';
import 'models/region_summary.dart';
import 'models/region_summary_config.dart';
import 'models/streaming_config.dart';
import 'models/x_axis_config.dart';
import 'rendering/chart_render_box.dart';
import 'rendering/spatial_index.dart';
import 'streaming/buffer_manager.dart';
import 'streaming/live_stream_controller.dart';
import 'streaming/streaming_controller.dart';
import 'theming/components/scrollbar_config.dart';
import 'utils/data_converter.dart';
import 'widgets/dialogs/pin_annotation_dialog.dart';
import 'widgets/dialogs/point_annotation_dialog.dart';
import 'widgets/dialogs/range_annotation_dialog.dart';
import 'widgets/dialogs/text_annotation_dialog.dart';
import 'widgets/dialogs/threshold_annotation_dialog.dart';
import 'widgets/dialogs/trend_annotation_dialog.dart';
import 'widgets/web_context_menu.dart';

/// BravenChartPlus renders interactive, multi-series charts with annotations.
///
/// Key capabilities:
/// - Multi-axis support with independent Y-axis configuration
/// - Crosshair and tooltip interactions
/// - Annotations (point, range, text, threshold, trend)
/// - Streaming mode with buffering and auto-resume
///
/// Usage:
/// ```dart
/// BravenChartPlus(
///   series: [
///     ChartSeries(
///       id: 'revenue',
///       points: const [
///         ChartDataPoint(x: 1, y: 10),
///         ChartDataPoint(x: 2, y: 15),
///       ],
///       color: Colors.green,
///     ),
///   ],
///   xAxisConfig: const XAxisConfig(label: 'Month'),
///   yAxis: const YAxisConfig(label: 'USD'),
///   interactionConfig: const InteractionConfig(
///     crosshair: CrosshairConfig(enabled: true),
///   ),
/// )
/// ```
class BravenChartPlus extends StatefulWidget {
  const BravenChartPlus({
    super.key,
    required this.series,
    this.annotations = const [],
    this.annotationController,
    this.theme,
    this.xAxisConfig,
    this.yAxis,
    this.grid,
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
    this.liveStreamController,
    this.controller,
    this.interactionConfig,
    this.title,
    this.subtitle,
    this.showLegend = true,
    this.legendStyle,
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
    this.onRegionSelected,
    // ==================== MULTI-AXIS PARAMETERS ====================
    this.normalizationMode,
    // ==================== REGION SUMMARY OVERLAY ====================
    this.showRegionSummary = false,
    this.regionSummaryConfig,
    this.customRegionAnalysis,
  }); // ==================== FACTORY CONSTRUCTORS ====================
  /// Creates a chart from a simple list of y-values.
  factory BravenChartPlus.fromValues({
    Key? key,
    ChartType chartType = ChartType.line,
    LineInterpolation interpolation = LineInterpolation.linear,
    required String seriesId,
    required List<double> yValues,
    List<double>? xValues,
    String? seriesName,
    Color? seriesColor,
    double? width,
    double? height,
    ChartTheme? theme,
    XAxisConfig? xAxisConfig,
    YAxisConfig? yAxis,
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
      interpolation: interpolation,
    );

    return BravenChartPlus(
      key: key,
      series: [series],
      width: width,
      height: height,
      theme: theme,
      xAxisConfig: xAxisConfig,
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
    ChartType chartType = ChartType.line,
    LineInterpolation interpolation = LineInterpolation.linear,
    required String seriesId,
    required Map<dynamic, double> data,
    String? seriesName,
    Color? seriesColor,
    double? width,
    double? height,
    ChartTheme? theme,
    XAxisConfig? xAxisConfig,
    YAxisConfig? yAxis,
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
      interpolation: interpolation,
    );

    return BravenChartPlus(
      key: key,
      series: [series],
      width: width,
      height: height,
      theme: theme,
      xAxisConfig: xAxisConfig,
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
    ChartType chartType = ChartType.line,
    LineInterpolation interpolation = LineInterpolation.linear,
    required String seriesId,
    required String json,
    String? seriesName,
    Color? seriesColor,
    double? width,
    double? height,
    ChartTheme? theme,
    XAxisConfig? xAxisConfig,
    YAxisConfig? yAxis,
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
          return ChartDataPoint(x: (item['x'] as num).toDouble(), y: (item['y'] as num).toDouble(), label: item['label'] as String?);
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
          interpolation: interpolation,
        );
      case ChartType.area:
        series = AreaChartSeries(
          id: seriesId,
          name: seriesName ?? seriesId,
          points: points,
          color: seriesColor ?? Colors.blue,
          interpolation: interpolation,
        );
      case ChartType.bar:
        series = BarChartSeries(id: seriesId, name: seriesName ?? seriesId, points: points, color: seriesColor ?? Colors.blue, barWidthPercent: 0.8);
      case ChartType.scatter:
        series = ScatterChartSeries(id: seriesId, name: seriesName ?? seriesId, points: points, color: seriesColor ?? Colors.blue);
    }

    return BravenChartPlus(
      key: key,
      series: [series],
      width: width,
      height: height,
      theme: theme,
      xAxisConfig: xAxisConfig,
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

  /// Modern X-axis configuration using XAxisConfig.
  ///
  /// Provides full access to X-axis features including crosshairLabelPosition.
  /// When provided, takes precedence over legacy [xAxis] parameter.
  ///
  /// Example:
  /// ```dart
  /// BravenChartPlus(
  ///   xAxisConfig: XAxisConfig(
  ///     label: 'Time',
  ///     unit: 's',
  ///     showCrosshairLabel: true,
  ///     crosshairLabelPosition: CrosshairLabelPosition.insidePlot,
  ///   ),
  /// )
  /// ```
  final XAxisConfig? xAxisConfig;

  final YAxisConfig? yAxis;
  final GridConfig? grid;
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
  ///
  /// **Deprecated**: Use [liveStreamController] for high-performance streaming.
  final StreamingController? streamingController;

  /// High-performance live streaming controller (recommended).
  ///
  /// The recommended way to stream high-frequency data (50Hz+) to charts.
  /// Provides frame-coalesced updates, direct RenderBox path (bypasses widget
  /// rebuild), built-in pause/resume with buffering, and auto-scroll.
  ///
  /// **Usage**:
  /// ```dart
  /// final controller = LiveStreamController(
  ///   seriesId: 'sensor',  // Must match series ID
  ///   maxPoints: 500,      // Sliding window size
  ///   autoScroll: true,    // Follow latest data
  /// );
  ///
  /// // Stream data
  /// sensorStream.listen((p) => controller.addPoint(p));
  ///
  /// // Use in widget
  /// BravenChartPlus(
  ///   liveStreamController: controller,
  ///   series: [LineChartSeries(id: 'sensor', points: [])],
  /// )
  /// ```
  ///
  /// For simple, low-frequency updates, use [controller] with `addPoint()`.
  /// For complex custom streaming, use [dataStream] with [streamingController].
  final LiveStreamController? liveStreamController;

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
  /// When [legendStyle] is provided, an overlay legend is rendered
  /// within the chart area (draggable, configurable styling).
  /// When [legendStyle] is null, a simple widget legend is shown
  /// below the chart.
  final bool showLegend;

  /// Style configuration for the overlay legend.
  ///
  /// When provided, the legend is rendered as a draggable overlay
  /// within the chart area, using the professional styling from
  /// [LegendStyle]. This is the recommended approach for production
  /// charts.
  ///
  /// When null, the legacy widget-based legend is shown below the chart.
  ///
  /// Example:
  /// ```dart
  /// BravenChartPlus(
  ///   series: [...],
  ///   showLegend: true,
  ///   legendStyle: LegendStyle(
  ///     position: LegendPosition.topRight,
  ///     backgroundColor: Colors.white.withOpacity(0.9),
  ///     markerShape: LegendMarkerShape.line,
  ///   ),
  /// )
  /// ```
  final LegendStyle? legendStyle;

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

  /// Fired when a data region is selected or deselected.
  ///
  /// Triggers on: range annotation tap (vertical only).
  /// Fires with null when the region is cleared.
  /// Existing [onAnnotationTap] continues to fire as before —
  /// [onRegionSelected] fires additionally for vertical RangeAnnotations.
  final RegionSelectedCallback? onRegionSelected;

  // ==================== MULTI-AXIS PARAMETERS ====================
  /// Y-axis configurations for multi-axis mode.
  ///
  /// When provided, enables multi-axis mode where each series can have
  /// its own Y-axis scale. Series are bound to axes in two ways:
  ///
  /// 1. **Inline config** (preferred): Set [ChartSeries.yAxisConfig] directly
  ///    on each series for dedicated axes.
  ///
  /// 2. **Shared reference**: Define axes here and reference them via
  ///    [ChartSeries.yAxisId] when multiple series share one axis.
  ///
  /// If null or empty, uses the default single Y-axis mode.
  ///
  /// Example with inline config (preferred):
  /// ```dart
  /// BravenChartPlus(
  ///   series: [
  ///     LineChartSeries(
  ///       id: 'power',
  ///       points: [...],
  ///       yAxisConfig: YAxisConfig(
  ///         position: YAxisPosition.left,
  ///         label: 'Power',
  ///         unit: 'W',
  ///       ),
  ///     ),
  ///   ],
  /// )
  /// ```

  /// Controls how normalization is applied to multi-axis data.
  ///
  /// - [NormalizationMode.auto]: Automatically detect when normalization is needed
  ///   based on Y-range ratios between series (>10x difference triggers normalization)
  /// - [NormalizationMode.perSeries]: Always normalize each axis independently,
  ///   useful when displaying conceptually different metrics
  /// - [NormalizationMode.none]: Never normalize, use global Y scale
  ///
  /// Defaults to [NormalizationMode.auto] when multiple axes are detected.
  final NormalizationMode? normalizationMode;

  // ==================== REGION SUMMARY OVERLAY ====================

  /// Whether to show the region summary overlay when a region is selected.
  ///
  /// When true, a card showing per-series statistical metrics is rendered
  /// above (or inside) the selected region. [RegionSummaryConfig] controls
  /// which metrics are shown, their formatting, and the card position.
  ///
  /// Defaults to false.
  final bool showRegionSummary;

  /// Configuration for the region summary overlay.
  ///
  /// Controls which [RegionMetric]s are displayed, how values are formatted,
  /// and where the card is positioned ([RegionSummaryPosition]).
  ///
  /// When null, a default [RegionSummaryConfig] is used
  /// (min, max, average — aboveRegion position).
  ///
  /// Only used when [showRegionSummary] is true.
  ///
  /// Example:
  /// ```dart
  /// BravenChartPlus(
  ///   showRegionSummary: true,
  ///   regionSummaryConfig: RegionSummaryConfig(
  ///     metrics: {RegionMetric.min, RegionMetric.max, RegionMetric.average},
  ///     position: RegionSummaryPosition.aboveRegion,
  ///   ),
  ///   series: [...],
  /// )
  /// ```
  final RegionSummaryConfig? regionSummaryConfig;

  /// Optional custom analysis callback for domain-specific metrics.
  ///
  /// When provided, this callback is invoked after the built-in
  /// [RegionSummary] is computed for the selected region. The returned
  /// [Map<String, String>] of label → formatted-value pairs is merged into
  /// the region summary overlay alongside the built-in metrics.
  ///
  /// This allows applications to display domain-specific computed metrics
  /// (e.g., Normalized Power for cycling, Sharpe Ratio for finance) in the
  /// same overlay card as the standard statistics.
  ///
  /// Parameters:
  /// - [DataRegion]: The selected region (startX, endX, seriesData).
  /// - [RegionSummary]: The computed per-series statistics.
  ///
  /// Returns a [Map<String, String>] of metric label → formatted value pairs
  /// to display in the overlay.
  ///
  /// Only used when [showRegionSummary] is true.
  ///
  /// Example:
  /// ```dart
  /// BravenChartPlus(
  ///   customRegionAnalysis: (region, summary) {
  ///     return {'NP': '${computeNormalizedPower(region)} W'};
  ///   },
  ///   showRegionSummary: true,
  ///   series: [...],
  /// )
  /// ```
  final CustomRegionAnalysisCallback? customRegionAnalysis;

  @override
  State<BravenChartPlus> createState() => BravenChartPlusState();
}

/// The [State] for a [BravenChartPlus] widget.
///
/// Exposes programmatic APIs such as [selectedDataRegions] and
/// [computeRegionSummaries] for consumers who access the state via
/// a [GlobalKey<BravenChartPlusState>].
///
/// Example:
/// ```dart
/// final chartKey = GlobalKey<BravenChartPlusState>();
///
/// BravenChartPlus(key: chartKey, series: [...]);
///
/// // Later, retrieve region summaries:
/// final summaries = chartKey.currentState!.computeRegionSummaries();
/// ```
class BravenChartPlusState extends State<BravenChartPlus> {
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

  /// Builds a map from series ID → display name for use in region summaries.
  Map<String, String> _buildSeriesNamesMap() {
    return {for (final s in widget.series) s.id: s.displayName};
  }

  // Track range creation mode to trigger UI updates
  bool _wasInRangeCreationMode = false;

  // Multi-axis normalization state (FR-008, US2)
  // Tracks whether auto-normalization is needed based on series Y-range ratios
  bool _normalizationNeeded = false;
  Map<String, DataRange> _seriesYRanges = {};

  // Internal annotation controller - created automatically when user doesn't provide one
  // This allows static annotations to be editable/draggable without explicit controller
  AnnotationController? _internalAnnotationController;

  // Legend custom position - stored internally since legend is auto-generated
  // and doesn't require user-provided annotationController
  Offset? _legendCustomPosition;

  // Region analysis state — currently selected data region (FR-005: single-region)
  DataRegion? _selectedDataRegion;

  // Cache for computed region summaries, keyed by region ID.
  // Invalidated when selected region changes (T027 spec requirement).
  final Map<String, RegionSummary> _regionSummaryCache = {};

  // Region summary overlay state — track active overlay data for ChartRenderBox.
  // _overlayRegion is the region currently shown in the overlay (may differ
  // from _selectedDataRegion when showRegionSummary transitions false→true).
  DataRegion? _overlayRegion;

  // Pre-computed summary for the active overlay region.
  RegionSummary? _overlayRegionSummary;

  // Custom metrics from the customRegionAnalysis callback — displayed alongside
  // built-in metrics in the widget-tree overlay.
  Map<String, String>? _overlayCustomMetrics;

  /// Shared [RegionAnalyzer] instance for stateless analysis operations.
  static const _regionAnalyzer = RegionAnalyzer();

  /// Returns the currently selected data regions.
  ///
  /// FR-005: Only one region can be active at a time.
  /// Returns a list containing the single active [DataRegion], or an
  /// empty list if no region is currently selected.
  List<DataRegion> get selectedDataRegions => _selectedDataRegion != null ? [_selectedDataRegion!] : [];

  // ---------------------------------------------------------------------------
  // Region selection helpers — centralise select/clear so the summary overlay
  // is always kept in sync.
  // ---------------------------------------------------------------------------

  /// Selects [region] as the active data region, fires [onRegionSelected],
  /// and auto-displays the summary overlay when [showRegionSummary] is true.
  void _selectRegion(DataRegion region) {
    _regionSummaryCache.clear();
    _selectedDataRegion = region;
    widget.onRegionSelected?.call(region);

    if (widget.showRegionSummary) {
      showRegionSummaryOverlay(region);
    }
  }

  /// Clears the active data region entirely (all sources), fires
  /// [onRegionSelected(null)], and hides the summary overlay.
  void _clearSelectedRegion() {
    if (_selectedDataRegion == null) return;
    _regionSummaryCache.clear();
    _selectedDataRegion = null;
    widget.onRegionSelected?.call(null);
    hideRegionSummaryOverlay();
  }

  /// Computes [RegionSummary] objects for the given [regions], or for
  /// [selectedDataRegions] if [regions] is null.
  ///
  /// Results are cached per region ID and returned from cache on repeat
  /// calls. The cache is invalidated automatically when the selected
  /// region changes (T027).
  ///
  /// Delegates to [RegionAnalyzer.computeRegionSummary] for each region.
  /// Returns an empty list when no regions are provided and no region is
  /// currently selected.
  ///
  /// Example:
  /// ```dart
  /// final chartKey = GlobalKey<BravenChartPlusState>();
  /// // ... build chart with key ...
  /// final summaries = chartKey.currentState!.computeRegionSummaries();
  /// for (final summary in summaries) {
  ///   for (final entry in summary.seriesSummaries.entries) {
  ///     print('${entry.key}: avg=${entry.value.average}');
  ///   }
  /// }
  /// ```
  List<RegionSummary> computeRegionSummaries([List<DataRegion>? regions]) {
    final effectiveRegions = regions ?? selectedDataRegions;
    final seriesNames = _buildSeriesNamesMap();
    return effectiveRegions.map((region) {
      final cached = _regionSummaryCache[region.id];
      if (cached != null) {
        return cached;
      }
      final summary = _regionAnalyzer.computeRegionSummary(region, seriesNames: seriesNames);
      _regionSummaryCache[region.id] = summary;
      return summary;
    }).toList();
  }

  /// Shows the region summary overlay for the given [region].
  ///
  /// Computes (or retrieves from cache) the [RegionSummary] for [region],
  /// stores it as the active overlay data, and triggers a repaint so the
  /// [ChartRenderBox] can paint the summary card on the next frame.
  ///
  /// Has no effect when [widget.showRegionSummary] is false.
  ///
  /// Example:
  /// ```dart
  /// final chartKey = GlobalKey<BravenChartPlusState>();
  ///
  /// // Show the overlay for a programmatically-created region:
  /// chartKey.currentState?.showRegionSummaryOverlay(myRegion);
  /// ```
  void showRegionSummaryOverlay(DataRegion region) {
    if (!mounted) return;

    // Compute or retrieve cached summary.
    final summary = _regionSummaryCache[region.id] ?? _regionAnalyzer.computeRegionSummary(region, seriesNames: _buildSeriesNamesMap());
    _regionSummaryCache[region.id] = summary;

    // Invoke custom analysis callback if provided.
    Map<String, String>? customMetrics;
    if (widget.customRegionAnalysis != null) {
      customMetrics = widget.customRegionAnalysis!(region, summary);
    }

    setState(() {
      _overlayRegion = region;
      _overlayRegionSummary = summary;
      _overlayCustomMetrics = customMetrics;
    });

    // Push the overlay data to the render box so it can paint without rebuild.
    _updateRenderBoxOverlay();
  }

  /// Hides the region summary overlay without clearing the selected region.
  ///
  /// After calling this method, no summary card is painted on the chart even
  /// if a region is still selected. The selected region data is preserved.
  ///
  /// Example:
  /// ```dart
  /// chartKey.currentState?.hideRegionSummaryOverlay();
  /// ```
  void hideRegionSummaryOverlay() {
    if (!mounted) return;
    setState(() {
      _overlayRegion = null;
      _overlayRegionSummary = null;
      _overlayCustomMetrics = null;
    });
    _updateRenderBoxOverlay();
  }

  /// Pushes current overlay state to the [ChartRenderBox] and requests a
  /// repaint without invalidating the series cache (FR-013).
  void _updateRenderBoxOverlay() {
    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    if (renderBox == null) return;

    // Only show overlay when widget.showRegionSummary is enabled.
    final active = widget.showRegionSummary && _overlayRegionSummary != null && _overlayRegion != null;

    if (active) {
      renderBox.setRegionSummaryOverlay(
        summary: _overlayRegionSummary!,
        config: widget.regionSummaryConfig ?? RegionSummaryConfig(),
        regionBounds: _computeRegionBoundsForRenderBox(_overlayRegion!),
      );
    } else {
      renderBox.clearRegionSummaryOverlay();
    }
  }

  /// Computes a [Rect] for the active overlay region in widget (plot) space.
  ///
  /// The region bounds are expressed as a plot-aligned rectangle. The render
  /// box uses this to position the summary card horizontally and vertically.
  ///
  /// When the coordinate transform is unavailable (before first layout) a
  /// zero-sized rect is returned; the renderer handles this gracefully.
  Rect _computeRegionBoundsForRenderBox(DataRegion region) {
    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    if (renderBox == null) return Rect.zero;

    // Use render box size as fallback bounds spanning the full plot height.
    return Rect.fromLTRB(
      region.startX, // will be overridden by the RenderBox using transform
      0,
      region.endX,
      renderBox.size.height,
    );
  }

  /// Whether multi-axis normalization is currently needed.  ///  /// This is automatically determined by [NormalizationDetector] based on
  /// the Y-range ratios between series. When series have ranges that differ
  /// by 10x or more, normalization is recommended.
  ///
  /// See also:
  /// - [NormalizationDetector.shouldNormalize] for the detection logic
  /// - [seriesYRanges] for the individual series Y bounds
  bool get normalizationNeeded => _normalizationNeeded;

  /// The Y-range bounds for each series.
  ///
  /// This map contains [DataRange] objects keyed by series ID, representing
  /// the min/max Y values for each series. Used for multi-axis normalization
  /// and tooltip value display.
  Map<String, DataRange> get seriesYRanges => Map.unmodifiable(_seriesYRanges);

  /// Returns the effective annotation controller (user-provided or internal).
  AnnotationController? get _effectiveAnnotationController => widget.annotationController ?? _internalAnnotationController;

  /// Initializes the annotation controller.
  ///
  /// If user provided a controller, uses that. Otherwise creates an internal
  /// controller populated with static annotations from widget.annotations.
  /// This allows static annotations to be editable/draggable.
  void _initializeAnnotationController() {
    if (widget.annotationController != null) {
      // User provided controller - use it directly
      return;
    }

    // No user controller - create internal one and populate with static annotations
    if (widget.annotations.isNotEmpty) {
      _internalAnnotationController = AnnotationController(initialAnnotations: widget.annotations);
    }
  }

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

    // Initialize internal annotation controller if user didn't provide one
    // This allows static annotations to be editable/draggable
    _initializeAnnotationController();

    // Listen to annotation controller updates
    _effectiveAnnotationController?.addListener(_onAnnotationControllerUpdate);

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

    // Attach LiveStreamController after first build (needs RenderBox to exist)
    if (widget.liveStreamController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _attachLiveStreamController();
      });
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
      // Remove listener from old effective controller
      final oldEffectiveController = oldWidget.annotationController ?? _internalAnnotationController;
      oldEffectiveController?.removeListener(_onAnnotationControllerUpdate);

      // Dispose internal controller if we're switching to user-provided one
      if (widget.annotationController != null && _internalAnnotationController != null) {
        _internalAnnotationController?.dispose();
        _internalAnnotationController = null;
      }

      // Reinitialize controller for new widget
      _initializeAnnotationController();

      // Add listener to new effective controller
      _effectiveAnnotationController?.addListener(_onAnnotationControllerUpdate);

      // CRITICAL FIX: Rebuild elements when annotation controller changes.
      // Previously elements were NOT rebuilt, causing stale annotations to persist
      // even when a new controller with different annotations was provided.
      _rebuildElements();
    }

    // Handle static annotations changes when no user controller
    if (widget.annotationController == null && widget.annotations != oldWidget.annotations) {
      // Recreate internal controller with new annotations
      _internalAnnotationController?.dispose();
      _internalAnnotationController = null;
      _initializeAnnotationController();
      _effectiveAnnotationController?.addListener(_onAnnotationControllerUpdate);
      // Elements will be rebuilt by the condition below (annotations changed)
    }

    // Handle LiveStreamController changes
    if (widget.liveStreamController != oldWidget.liveStreamController) {
      oldWidget.liveStreamController?.detachRenderBox();
      if (widget.liveStreamController != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _attachLiveStreamController();
        });
      }
    }

    if (widget.series != oldWidget.series || widget.theme != oldWidget.theme || widget.annotations != oldWidget.annotations) {
      // Removed excessive debugPrint (theme/series/annotations changed)
      _rebuildElements();
      // Focus will be acquired on next mouse enter — no need to grab it here.
      // Previously this called requestFocus() which caused 21 charts to fight
      // for focus on gallery page load, contributing to startup lag.
    }
  }

  /// Called when focus state changes.
  void _onFocusChanged() {
    // Only trigger rebuild when focus border is actually displayed.
    // Without this guard, every focus change triggers setState on ALL charts,
    // causing cascading rebuilds with 21+ charts on the gallery page.
    if (widget.interactionConfig?.showFocusBorder ?? false) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _streamSubscription?.cancel();
    widget.controller?.removeListener(_onControllerUpdate);
    _effectiveAnnotationController?.removeListener(_onAnnotationControllerUpdate);
    _internalAnnotationController?.dispose();
    widget.liveStreamController?.detachRenderBox();
    _coordinator.removeListener(_onCoordinatorChanged);
    _coordinator.dispose();
    _panRecognizer.dispose();
    _tapRecognizer.dispose();
    super.dispose();
  }

  /// Called when controller notifies of changes (matches BravenChart pattern).
  void _onControllerUpdate() {
    if (!mounted) return;

    // Update cached bounds even when paused - needed for pan constraints
    if (widget.controller != null) {
      final controllerData = widget.controller!.getAllSeries();
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
          } else {
            _updateCachedDataBounds(point.x, point.y);
          }
        }
      }
      // Only log occasionally to avoid spam
      if (totalPoints % 50 == 0 || totalPoints < 10) {}
    }

    // When paused, don't rebuild - let data accumulate silently
    // This prevents visual jumps when exploring the viewport
    if (!_isStreaming) {
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
    // Special handling for internal legend - store position in state
    if (annotationId == '__internal_legend__' && updatedAnnotation is LegendAnnotation) {
      setState(() {
        _legendCustomPosition = updatedAnnotation.customPosition;
        _rebuildElements();
      });
      return;
    }

    // Update via effective controller (user-provided or internal)
    // Internal controller makes static annotations editable/draggable
    if (_effectiveAnnotationController != null) {
      _effectiveAnnotationController!.updateAnnotation(annotationId, updatedAnnotation);
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

    // Live-update the region summary overlay when a RangeAnnotation that is
    // currently selected is dragged/resized. Without this the overlay stays
    // stale until the user re-taps.
    if (updatedAnnotation is RangeAnnotation &&
        updatedAnnotation.startX != null &&
        updatedAnnotation.endX != null &&
        widget.showRegionSummary &&
        _overlayRegion != null &&
        _overlayRegion!.id == 'region-$annotationId') {
      final allSeriesData = <String, List<ChartDataPoint>>{for (final s in widget.series) s.id: s.points};
      final updatedRegion = _regionAnalyzer.regionFromAnnotation(updatedAnnotation, allSeriesData);
      // _selectRegion clears the cache and updates the overlay in one call.
      _selectRegion(updatedRegion);
    }
  }

  void _rebuildElements() {
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
              .map((p) => ChartDataPoint(x: p.x, y: p.y, timestamp: p.timestamp, label: p.label, metadata: p.metadata))
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
              .map((p) => ChartDataPoint(x: p.x, y: p.y, timestamp: p.timestamp, label: p.label, metadata: p.metadata))
              .toList();

          // Create new series from controller data
          mergedSeriesList.add(
            LineChartSeries(
              id: entry.key,
              name: entry.key,
              points: convertedPoints,
              color: widget.theme?.seriesTheme.colors.isNotEmpty == true
                  ? widget.theme!.seriesTheme.colors[mergedSeriesList.length % widget.theme!.seriesTheme.colors.length]
                  : Colors.blue,
            ),
          );
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

    // Series-level interpolation is now respected directly from ChartSeries.interpolation
    // The deprecated widget-level lineStyle override has been removed.

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

            // Add 5% padding to window bounds for visual breathing room
            // (same as computeDataBounds does for non-streaming data)
            final xRange = maxX - minX;
            final yRange = maxY - minY;
            final xPadding = xRange * 0.05;
            final yPadding = yRange * 0.05;

            // Removed excessive print (window bounds)

            dataBounds = DataBounds(xMin: minX - xPadding, xMax: maxX + xPadding, yMin: minY - yPadding, yMax: maxY + yPadding);
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
        dataBounds = DataConverter.computeDataBounds(effectiveSeries);
      }
    }

    // CRITICAL: Ensure valid bounds before creating axes (prevent dataMax <= dataMin assertion)
    if (dataBounds.xMax <= dataBounds.xMin) {
      dataBounds = DataBounds(xMin: 0, xMax: 1, yMin: dataBounds.yMin, yMax: dataBounds.yMax);
    }
    if (dataBounds.yMax <= dataBounds.yMin) {
      dataBounds = DataBounds(xMin: dataBounds.xMin, xMax: dataBounds.xMax, yMin: 0, yMax: 1);
    }

    // Multi-axis normalization detection (FR-008, US2)
    // Check if series have vastly different Y-ranges that would benefit from normalization
    final seriesRanges = _computeSeriesYRanges(effectiveSeries);
    final needsNormalization = NormalizationDetector.shouldNormalize(seriesRanges);
    // Store normalization state for potential future use
    // (Full rendering integration will use this in subsequent task phases)
    _normalizationNeeded = needsNormalization;
    _seriesYRanges = seriesRanges;

    // CRITICAL FIX: When using perSeries normalization with multi-axis,
    // the global Y bounds should use normalized range (0-1) so that
    // the scrollbar/transform calculations match the visual rendering.
    // Each series is rendered with its own Y-axis bounds, but the global
    // transform needs to use a consistent normalized space.
    // Add 5% padding buffer to prevent data points from being cut off at edges.
    //
    // Multi-axis is active when any series has inline yAxisConfig or yAxisId
    final hasMultiAxisConfig = widget.series.any((s) => s.yAxisConfig != null || (s.yAxisId != null && s.yAxisId!.isNotEmpty));
    if (widget.normalizationMode == NormalizationMode.perSeries && hasMultiAxisConfig) {
      dataBounds = DataBounds(
        xMin: dataBounds.xMin,
        xMax: dataBounds.xMax,
        yMin: -0.05, // 5% buffer below normalized range
        yMax: 1.05, // 5% buffer above normalized range
      );
    }

    // Create axes from data bounds using XAxisConfig/YAxisConfig
    final xAxisConfig = widget.xAxisConfig ?? const XAxisConfig();
    final yAxisConfigRaw = widget.yAxis ?? YAxisConfig(position: YAxisPosition.left, label: 'Y');

    _xAxis = chart_axis.Axis.fromXAxisConfig(
      config: xAxisConfig,
      dataMin: xAxisConfig.min ?? dataBounds.xMin,
      dataMax: xAxisConfig.max ?? dataBounds.xMax,
      labelFormatter: xAxisConfig.labelFormatter,
    );

    _yAxis = chart_axis.Axis.fromYAxisConfig(config: yAxisConfigRaw, dataMin: dataBounds.yMin, dataMax: dataBounds.yMax);

    // Create element generator that renders series
    // This will be called by ChartRenderBox during zoom/pan to regenerate elements
    _elementGenerator = (ChartTransform transform) {
      // Removed excessive debugPrint (element generator executing)

      // Generate series elements from effective series (with streaming data)
      final elements = DataConverter.seriesToElements(
        series: effectiveSeries,
        transform: transform,
        theme: widget.theme,
        coordinator: _coordinator,
      ).cast<ChartElement>().toList();

      // Convert annotations to elements
      // Removed excessive debugPrints (annotation conversion details)
      // Use effective controller (user-provided or internal with static annotations)
      final effectiveAnnotations = _effectiveAnnotationController?.annotations ?? [];
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
            PinAnnotation() => PinAnnotationElement(annotation: annotation, transform: transform),
            RangeAnnotation() => RangeAnnotationElement(
              annotation: annotation,
              transform: transform,
              chartSize: Size(transform.plotWidth, transform.plotHeight),
            ),
            TextAnnotation() => TextAnnotationElement(annotation: annotation),
            ThresholdAnnotation() => ThresholdAnnotationElement(annotation: annotation, transform: transform),
            TrendAnnotation() => TrendAnnotationElement(
              annotation: annotation,
              series: widget.series.firstWhere(
                (s) => s.id == annotation.seriesId,
                orElse: () => throw StateError('Series ${annotation.seriesId} not found'),
              ),
              transform: transform,
            ),
            LegendAnnotation() => LegendAnnotationElement(annotation: annotation, chartSize: Size(transform.plotWidth, transform.plotHeight)),
          };
          elements.add(element);

          // For resizable elements, also insert their resize handle elements
          if (element is ResizableElement && element.isResizable) {
            final handleElements = element.createResizeHandleElements().cast<ChartElement>();
            elements.addAll(handleElements);
            // Removed excessive debugPrint (resize handles added)
          }
        } catch (_) {
          // Silently ignore annotation conversion errors to prevent chart crashes
          // This can occur when annotation references an invalid series or has malformed data
        }
      }

      // Auto-generate legend overlay if showLegend is true
      if (widget.showLegend && effectiveSeries.isNotEmpty) {
        // Use widget legendStyle if provided, otherwise fall back to theme's legendStyle
        final effectiveLegendStyle = widget.legendStyle ?? widget.theme?.legendStyle ?? const LegendStyle();

        // Collect trend annotations that have labels for display in the legend
        final trendAnnotations = effectiveAnnotations.whereType<TrendAnnotation>().where((t) => t.label != null && t.label!.isNotEmpty).toList();

        final legendAnnotation = LegendAnnotation(
          id: '__internal_legend__', // Special ID for internal legend
          series: effectiveSeries,
          trendAnnotations: trendAnnotations,
          legendStyle: effectiveLegendStyle,
          customPosition: _legendCustomPosition,
        );
        elements.add(LegendAnnotationElement(annotation: legendAnnotation, chartSize: Size(transform.plotWidth, transform.plotHeight)));
      }

      return elements;
    };

    // Increment version to signal that regeneration is needed
    _elementGeneratorVersion++;
  }

  void _onCoordinatorChanged() {
    // CRITICAL: Detect mode transitions to handle context menu
    if (_coordinator.currentMode == InteractionMode.contextMenuOpen && mounted) {
      // Only show context menu if we have an effective annotation controller
      // (all current menu items are annotation-related)
      if (_effectiveAnnotationController != null) {
        if (_isShowingContextMenu) {
        } else {
          // PERFORMANCE FIX: Call immediately instead of post-frame callback
          // Post-frame callbacks were being delayed by 2-36 SECONDS when Flutter's
          // frame scheduler was busy or browser was throttling frames.
          // Context menus need immediate response for good UX.
          _showContextMenu();
        }
      } else {
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
    // Set guard flag to prevent duplicate menu opens
    _isShowingContextMenu = true;

    final localPosition = _coordinator.interactionStartPosition;
    final element = _coordinator.interactionStartElement;

    if (localPosition == null) {
      _coordinator.releaseMode(force: true);
      _isShowingContextMenu = false;
      return;
    }

    // Convert local position to global coordinates for menu positioning
    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      _coordinator.releaseMode(force: true);
      _isShowingContextMenu = false;
      return;
    }

    final globalPosition = renderBox.localToGlobal(localPosition);

    // Determine context for menu items
    // Show "Add Point Annotation" if hoveredMarker is set (within snap radius of a data point)
    // This matches the tooltip behavior - if you can see the tooltip, you can add a point annotation
    final bool isDataPointClick = _coordinator.hoveredMarker != null;
    final bool isSeriesLineClick = element is SeriesElement && _coordinator.hoveredMarker == null;
    final bool isExistingAnnotation = element != null && element is! SeriesElement;

    // Check if annotations are supported (effective controller exists)
    final bool hasAnnotationController = _effectiveAnnotationController != null;

    // Build context-aware web-native menu items
    final List<WebContextMenuItem> menuItems = [
      // Annotation creation items - ONLY show when annotationController is available
      if (hasAnnotationController) ...[
        // TextAnnotation - ALWAYS available
        const WebContextMenuAction(value: 'add_text', icon: Icons.text_fields, label: 'Add Text Annotation'),

        // PinAnnotation - ALWAYS available (arbitrary position marker)
        const WebContextMenuAction(value: 'add_pin', icon: Icons.push_pin, label: 'Add Pin Annotation'),

        // PointAnnotation - ONLY when clicking on data point marker
        if (isDataPointClick) const WebContextMenuAction(value: 'add_point', icon: Icons.place, label: 'Add Point Annotation'),

        // TrendAnnotation - ONLY when clicking on series line (not marker)
        if (isSeriesLineClick) const WebContextMenuAction(value: 'add_trend', icon: Icons.trending_up, label: 'Add Trend Annotation'),

        // RangeAnnotation - ALWAYS available (interactive drag mode)
        const WebContextMenuAction(value: 'add_range', icon: Icons.width_full, label: 'Add Range Annotation'),

        const WebContextMenuDivider(),

        // ThresholdAnnotation - ALWAYS available
        const WebContextMenuAction(value: 'add_threshold', icon: Icons.horizontal_rule, label: 'Add Threshold Line'),
      ],

      // Edit/Delete for existing annotations - ONLY show when annotationController is available
      if (hasAnnotationController && isExistingAnnotation) ...[
        const WebContextMenuDivider(),
        const WebContextMenuAction(value: 'edit', icon: Icons.edit, label: 'Edit'),
        const WebContextMenuAction(value: 'delete', icon: Icons.delete, label: 'Delete', iconColor: Colors.red, textColor: Colors.red),
      ],
    ];

    // Show the web-native context menu
    final result = await WebContextMenu.show(context: context, position: globalPosition, items: menuItems);

    // Clear guard flag now that menu is closed
    _isShowingContextMenu = false;

    // Release mode BEFORE handling action (so action handlers can claim new modes)
    // This is critical for modal-to-modal transitions (e.g., contextMenuOpen → rangeAnnotationCreation)
    _coordinator.releaseMode(force: true);

    // Handle menu selection
    if (result != null) {
      await _handleMenuAction(result, localPosition, element);
    }
  }

  /// Handles menu action selection from context menu.
  Future<void> _handleMenuAction(String action, Offset localPosition, ChartElement? element) async {
    switch (action) {
      case 'add_text':
        await _showAddTextAnnotationDialog(localPosition);
        break;
      case 'add_pin':
        await _showAddPinAnnotationDialog(localPosition);
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
    }
  }

  // ============================================================================
  // Annotation Dialogs
  // ============================================================================

  /// Shows the TextAnnotation creation dialog.
  Future<void> _showAddTextAnnotationDialog(Offset localPosition) async {
    if (!mounted) return;

    final result = await showDialog<TextAnnotation>(
      context: context,
      builder: (context) => TextAnnotationDialog(clickPosition: localPosition),
    );

    if (result != null && mounted) {
      _effectiveAnnotationController?.addAnnotation(result);
    } else {}
  }

  /// Shows the PinAnnotation creation dialog.
  Future<void> _showAddPinAnnotationDialog(Offset localPosition) async {
    if (!mounted) return;

    // Convert click position to data coordinates
    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    double? initialX;
    double? initialY;

    if (renderBox != null) {
      final transform = renderBox.transform;
      if (transform != null) {
        final dataPos = transform.plotToData(localPosition.dx, localPosition.dy);
        initialX = dataPos.dx;
        initialY = dataPos.dy;
      }
    }

    final result = await showDialog<PinAnnotation>(
      context: context,
      builder: (context) => PinAnnotationDialog(initialX: initialX, initialY: initialY, chartTheme: widget.theme),
    );

    if (result != null && mounted) {
      _effectiveAnnotationController?.addAnnotation(result);
    }
  }

  /// Shows the PointAnnotation creation dialog.
  Future<void> _showAddPointAnnotationDialog(ChartElement? element) async {
    if (!mounted) return;

    // PointAnnotation requires a data point - get info from coordinator's hoveredMarker
    final markerInfo = _coordinator.hoveredMarker;
    if (markerInfo == null) {
      return;
    }

    final result = await showDialog<PointAnnotation>(
      context: context,
      builder: (context) => PointAnnotationDialog(seriesId: markerInfo.seriesId, dataPointIndex: markerInfo.markerIndex, chartTheme: widget.theme),
    );

    if (result != null && mounted) {
      _effectiveAnnotationController?.addAnnotation(result);
    } else {}
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
        // In perSeries mode, this returns normalized Y (0-1)
        // The dialog will denormalize based on selected series
        final dataPos = transform.plotToData(localPosition.dx, localPosition.dy);
        initialXValue = dataPos.dx;
        initialYValue = dataPos.dy;
      }
    }

    final result = await showDialog<ThresholdAnnotation>(
      context: context,
      builder: (context) => ThresholdAnnotationDialog(
        initialXValue: initialXValue,
        initialYValue: initialYValue,
        availableSeries: widget.series,
        normalizationMode: widget.normalizationMode,
      ),
    );

    if (result != null && mounted) {
      _effectiveAnnotationController?.addAnnotation(result);
    } else {}
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

    // Enter rangeAnnotationCreation mode (priority 10, modal)
    if (!_coordinator.claimMode(InteractionMode.rangeAnnotationCreation)) {
      return;
    }

    // Completion is handled via _onRangeCreationComplete callback
    // (called from ChartRenderBox when drag finishes)
  }

  /// Called when user completes a box-select drag.
  ///
  /// Converts the data-coordinate X range to a [DataRegion] with
  /// [DataRegionSource.boxSelect] source, populates [seriesData],
  /// and fires [onRegionSelected] and [onSelectionChanged] callbacks.
  void _onBoxSelectComplete(double startX, double endX) {
    if (!mounted) return;

    // Build seriesData by filtering points within the X range for each series
    final seriesData = <String, List<ChartDataPoint>>{};
    final allPoints = <ChartDataPoint>[];

    for (final series in widget.series) {
      final filtered = _regionAnalyzer.filterPointsInRange(series.points, startX: startX, endX: endX);
      seriesData[series.id] = filtered;
      allPoints.addAll(filtered);
    }

    final region = DataRegion(
      id: 'box-select-${startX.toStringAsFixed(2)}-${endX.toStringAsFixed(2)}',
      startX: startX,
      endX: endX,
      source: DataRegionSource.boxSelect,
      seriesData: seriesData,
    );

    // FR-005: single-region selection — replace, not accumulate
    _selectRegion(region);

    // Co-fire onSelectionChanged with all selected points
    widget.interactionConfig?.onSelectionChanged?.call(allPoints);
  }

  /// Called when user taps to clear an active box selection.
  ///
  /// Clears the selected region and fires [onRegionSelected] with null.
  void _onBoxSelectCleared() {
    if (!mounted) return;

    // Only clear box-select regions. Segment and annotation regions are
    // independent of the box-select gesture and must not be cleared when
    // the user taps on an empty area that triggers the box-select cleared
    // event (e.g. tapping after a segment-styled series with no annotation).
    if (_selectedDataRegion != null && _selectedDataRegion!.source == DataRegionSource.boxSelect) {
      _clearSelectedRegion();
    }
  }

  /// Called when user completes drag in rangeAnnotationCreation mode.
  /// Opens dialog with pre-filled coordinates from drag bounds.
  Future<void> _onRangeCreationComplete(double startX, double endX, double startY, double endY) async {
    if (!mounted) return;

    // In perSeries mode, plotToData returns normalized Y values (0-1)
    // The dialog will denormalize based on the selected series

    // Open dialog with pre-filled values from drag
    final result = await showDialog<RangeAnnotation>(
      context: context,
      builder: (context) => RangeAnnotationDialog(
        initialStartX: startX,
        initialEndX: endX,
        initialStartY: startY,
        initialEndY: endY,
        availableSeries: widget.series,
        normalizationMode: widget.normalizationMode,
      ),
    );

    // Release rangeAnnotationCreation mode after dialog closes (regardless of result)
    // CRITICAL: Must use force=true because rangeAnnotationCreation is modal (priority 10)
    _coordinator.releaseMode(force: true);

    if (result != null && mounted) {
      _effectiveAnnotationController?.addAnnotation(result);
    }
  }

  /// Shows the TrendAnnotation creation dialog.
  Future<void> _showAddTrendAnnotationDialog(ChartElement? element) async {
    if (!mounted) return;

    // Get available series IDs
    final availableSeries = widget.series.map((s) => s.id).toList();
    if (availableSeries.isEmpty) {
      return;
    }

    // If clicked on series line, preselect that series
    String? preselectedSeriesId;
    if (element is SeriesElement) {
      preselectedSeriesId = element.series.id;
    }

    final result = await showDialog<TrendAnnotation>(
      context: context,
      builder: (context) => TrendAnnotationDialog(availableSeries: availableSeries, preselectedSeriesId: preselectedSeriesId),
    );

    if (result != null && mounted) {
      _effectiveAnnotationController?.addAnnotation(result);
    } else {}
  }

  /// Shows the appropriate edit dialog based on annotation type.
  Future<void> _showEditAnnotationDialog(ChartElement? element) async {
    if (!mounted) return;

    // Check for annotation element types directly (PointAnnotationElement uses datapoint type for priority)
    if (element == null ||
        (element is! TextAnnotationElement &&
            element is! PointAnnotationElement &&
            element is! PinAnnotationElement &&
            element is! ThresholdAnnotationElement &&
            element is! TrendAnnotationElement &&
            element is! RangeAnnotationElement)) {
      return;
    }

    // Cast to annotation element types to access annotation field and route to dialog
    if (element is TextAnnotationElement) {
      final annotation = element.annotation;
      final result = await showDialog<TextAnnotation>(
        context: context,
        builder: (context) => TextAnnotationDialog(annotation: annotation, clickPosition: annotation.position),
      );

      if (result != null && mounted) {
        _effectiveAnnotationController?.updateAnnotation(annotation.id, result);
      } else {}
    } else if (element is PointAnnotationElement) {
      final annotation = element.annotation;
      final result = await showDialog<PointAnnotation>(
        context: context,
        builder: (context) => PointAnnotationDialog(annotation: annotation, seriesId: annotation.seriesId, dataPointIndex: annotation.dataPointIndex),
      );

      if (result != null && mounted) {
        _effectiveAnnotationController?.updateAnnotation(annotation.id, result);
      } else {}
    } else if (element is PinAnnotationElement) {
      final annotation = element.annotation;
      final result = await showDialog<PinAnnotation>(
        context: context,
        builder: (context) => PinAnnotationDialog(annotation: annotation, initialX: annotation.x, initialY: annotation.y, chartTheme: widget.theme),
      );

      if (result != null && mounted) {
        _effectiveAnnotationController?.updateAnnotation(annotation.id, result);
      }
    } else if (element is ThresholdAnnotationElement) {
      final annotation = element.annotation;
      final result = await showDialog<ThresholdAnnotation>(
        context: context,
        builder: (context) =>
            ThresholdAnnotationDialog(annotation: annotation, availableSeries: widget.series, normalizationMode: widget.normalizationMode),
      );

      if (result != null && mounted) {
        _effectiveAnnotationController?.updateAnnotation(annotation.id, result);
      } else {}
    } else if (element is TrendAnnotationElement) {
      final annotation = element.annotation;
      final availableSeries = widget.series.map((s) => s.id).toList();
      final result = await showDialog<TrendAnnotation>(
        context: context,
        builder: (context) => TrendAnnotationDialog(annotation: annotation, availableSeries: availableSeries),
      );

      if (result != null && mounted) {
        _effectiveAnnotationController?.updateAnnotation(annotation.id, result);
      } else {}
    } else if (element is RangeAnnotationElement) {
      final annotation = element.annotation;
      final result = await showDialog<RangeAnnotation>(
        context: context,
        builder: (context) =>
            RangeAnnotationDialog(annotation: annotation, availableSeries: widget.series, normalizationMode: widget.normalizationMode),
      );

      if (result != null && mounted) {
        _effectiveAnnotationController?.updateAnnotation(annotation.id, result);
      } else {}
    } else {}
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
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Annotation'),
        content: Text('Are you sure you want to delete this $annotationType?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
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
      final wasRemoved = _effectiveAnnotationController?.removeAnnotation(annotationId) ?? false;
      if (wasRemoved) {
      } else {}
    } else {}
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
    // Also check interactionStartElement which is set during pointer down
    // hit testing and is available before activeElement gets set on pointer up.
    final tappedElement = _coordinator.activeElement ?? _coordinator.hoveredElement ?? _coordinator.interactionStartElement;

    // Check for double-click on annotation
    if (_lastTapTime != null && _lastTappedElement != null && tappedElement != null) {
      final now = DateTime.now();
      final timeDiff = now.difference(_lastTapTime!);

      if (tappedElement == _lastTappedElement && timeDiff <= _doubleTapTimeout) {
        // Double-click detected!
        if (tappedElement is TextAnnotationElement ||
            tappedElement is PointAnnotationElement ||
            tappedElement is PinAnnotationElement ||
            tappedElement is ThresholdAnnotationElement ||
            tappedElement is TrendAnnotationElement ||
            tappedElement is RangeAnnotationElement) {
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

    // Trigger element-specific callbacks (non-region)
    // segmentFiredInline tracks whether a segment region was selected inside
    // the SeriesElement branch so that _fireRegionSelectedForAnnotation is
    // skipped (preventing the annotation region from overwriting the more
    // specific segment selection).
    bool segmentFiredInline = false;
    if (tappedElement != null) {
      if (tappedElement is PointAnnotationElement) {
        widget.onAnnotationTap?.call(tappedElement.annotation);
      } else if (tappedElement is PinAnnotationElement) {
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
          // onPointTap always co-fires for any point tap (per api-contracts.md s4)
          widget.onPointTap?.call(point, tappedElement.series.id);

          // Segment-tap wiring: additionally fire onRegionSelected if the
          // tapped point has a non-null segmentStyle (US3).
          // Annotation wins over segment when the tap falls inside a range
          // annotation's x-range — let _fireRegionSelectedForAnnotation handle it.
          if (point.segmentStyle != null && widget.onRegionSelected != null && !_tapWithinRangeAnnotation(details.localPosition)) {
            final segmentRegion = _regionAnalyzer.segmentGroupForPoint(tappedElement.series.id, tappedElement.series.points, marker.markerIndex);
            if (segmentRegion != null) {
              _selectRegion(segmentRegion);
              segmentFiredInline = true;
            }
          }
        } else {
          // No specific marker hovered — find the nearest point to the tap
          // position and check for segment-tap wiring.
          final nearestIndex = _findNearestPointIndex(tappedElement.series, details.localPosition);
          if (nearestIndex != null) {
            final point = tappedElement.series.points[nearestIndex];
            widget.onPointTap?.call(point, tappedElement.series.id);

            // Segment-tap wiring for nearest point.
            // Annotation wins over segment when the tap falls inside a range
            // annotation's x-range — let _fireRegionSelectedForAnnotation handle it.
            if (point.segmentStyle != null && widget.onRegionSelected != null && !_tapWithinRangeAnnotation(details.localPosition)) {
              final segmentRegion = _regionAnalyzer.segmentGroupForPoint(tappedElement.series.id, tappedElement.series.points, nearestIndex);
              if (segmentRegion != null) {
                _selectRegion(segmentRegion);
                segmentFiredInline = true;
              }
            }
          } else {
            // Transform unavailable — fall through to the segment-tap
            // fallback below so styled-segment callbacks can still fire.
            widget.onSeriesSelected?.call(tappedElement.series.id);
            _trySegmentTapFallback(details.localPosition);
          }
        }
      }
    }

    // Segment-tap fallback: if no element was directly hit but the tap
    // is within the plot area, find the nearest styled point across all
    // series and fire onRegionSelected. This handles touch taps and
    // widget test scenarios where the tap doesn't precisely hit a line.
    // Skip the fallback when the tap is inside a range annotation's x-range —
    // annotation region selection takes priority over the nearest segment.
    bool segmentFired = segmentFiredInline;
    if (!segmentFiredInline && (tappedElement == null || tappedElement is! SeriesElement) && !_tapWithinRangeAnnotation(details.localPosition)) {
      segmentFired = _trySegmentTapFallback(details.localPosition);
    }

    // Region selection: fire onRegionSelected when the user taps a
    // RangeAnnotationElement directly, taps the background within an
    // annotation's X-range, or taps a series element within an annotation's
    // X-range (since series are drawn on top of annotations). Do NOT fire
    // when the user explicitly taps a different annotation type (threshold,
    // point, text, pin, trend) that happens to overlap an annotation's range.
    // ALSO skip when a segment was already fired — segment selection takes
    // priority over annotation region selection (more specific intent).
    final bool eligibleForRegion =
        !segmentFired && (tappedElement == null || tappedElement is RangeAnnotationElement || tappedElement is SeriesElement);
    final regionFired = eligibleForRegion
        ? _fireRegionSelectedForAnnotation(tapPosition: details.localPosition, tappedElement: tappedElement)
        : false;
    // Clear the active region when no region or segment was selected:
    //   • background tap (tappedElement == null, nothing fired) → clear + fire onBackgroundTap
    //   • series tap with no segment style and outside annotation → clear only
    // This ensures the summary overlay hides whenever the user clicks somewhere
    // that doesn't correspond to a selectable region.
    final bool nothingSelected = !regionFired && !segmentFired;
    if (nothingSelected) {
      _clearSelectedRegion();
      if (tappedElement == null) {
        widget.onBackgroundTap?.call(details.localPosition);
      }
    }

    // Request focus on tap to enable keyboard controls
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  /// Finds the appropriate range annotation for the given tap position
  /// and fires [onRegionSelected] and optionally [onAnnotationTap].
  ///
  /// When the [tappedElement] is a [RangeAnnotationElement], uses that
  /// annotation directly. Otherwise, converts the [tapPosition] to data
  /// coordinates and checks if the tap falls within any annotation's
  /// X-range. Returns false if no matching annotation is found.
  ///
  /// Returns true if a region was selected.
  bool _fireRegionSelectedForAnnotation({required Offset tapPosition, ChartElement? tappedElement}) {
    // If a RangeAnnotationElement was tapped directly, use it
    if (tappedElement is RangeAnnotationElement) {
      final annotation = tappedElement.annotation;
      if (annotation.startX != null && annotation.endX != null) {
        _computeAndFireRegion(annotation);
        return true;
      }
    }

    final annotations = _effectiveAnnotationController?.annotations ?? widget.annotations;

    // Collect all vertical range annotations
    final rangeAnnotations = annotations.whereType<RangeAnnotation>().where((a) => a.startX != null && a.endX != null).toList();

    if (rangeAnnotations.isEmpty) return false;

    // Try to find the annotation that contains the tap position
    RangeAnnotation? matched;
    bool positionResolved = false;
    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    if (renderBox != null) {
      final transform = renderBox.transform;
      if (transform != null) {
        positionResolved = true;
        final plotPos = renderBox.widgetToPlot(tapPosition);
        final dataPos = transform.plotToData(plotPos.dx, plotPos.dy);
        for (final annotation in rangeAnnotations) {
          if (dataPos.dx >= annotation.startX! && dataPos.dx <= annotation.endX!) {
            matched = annotation;
            break;
          }
        }
      }
    }

    if (positionResolved && matched == null) {
      // Tap position was resolved to data coordinates but falls outside
      // all annotation X-ranges — do not fire.
      return false;
    }

    // If position could not be resolved (no transform available yet),
    // fall back to the first vertical range annotation. This handles
    // the case where the chart layout hasn't fully initialized its
    // coordinate transform when the tap occurs.
    matched ??= rangeAnnotations.first; // Fire onAnnotationTap if the element branch didn't already fire it for
    // a RangeAnnotationElement
    if (tappedElement is! RangeAnnotationElement) {
      widget.onAnnotationTap?.call(matched);
    }
    _computeAndFireRegion(matched);
    return true;
  }

  /// Returns true when [tapPosition] (in widget-local coordinates) falls within
  /// the x-range of any vertical [RangeAnnotation] in the chart. Used to let
  /// annotation region selection take priority over segment region selection
  /// when they coincide spatially.
  bool _tapWithinRangeAnnotation(Offset tapPosition) {
    final annotations = _effectiveAnnotationController?.annotations ?? widget.annotations;
    final rangeAnnotations = annotations.whereType<RangeAnnotation>().where((a) => a.startX != null && a.endX != null).toList();
    if (rangeAnnotations.isEmpty) return false;

    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    if (renderBox == null) return false;
    final transform = renderBox.transform;
    if (transform == null) return false;

    final plotPos = renderBox.widgetToPlot(tapPosition);
    final dataPos = transform.plotToData(plotPos.dx, plotPos.dy);

    return rangeAnnotations.any((a) => dataPos.dx >= a.startX! && dataPos.dx <= a.endX!);
  }

  /// Computes a [DataRegion] from a [RangeAnnotation] and fires
  /// [onRegionSelected].
  void _computeAndFireRegion(RangeAnnotation annotation) {
    final allSeriesData = <String, List<ChartDataPoint>>{};
    for (final series in widget.series) {
      allSeriesData[series.id] = series.points;
    }

    final region = _regionAnalyzer.regionFromAnnotation(annotation, allSeriesData);

    // FR-005: single-region selection — replace, not accumulate
    _selectRegion(region);
  }

  /// Finds the index of the nearest data point to [widgetPosition] in
  /// [series], or `null` if the chart render box or transform is unavailable.
  ///
  /// Uses the chart's coordinate transform to convert [widgetPosition]
  /// (in widget-local coordinates) to data coordinates, then finds the
  /// nearest point by X-distance in data space.
  int? _findNearestPointIndex(ChartSeries series, Offset widgetPosition) {
    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    if (renderBox == null) return null;

    final transform = renderBox.transform;
    if (transform == null) return null;

    final points = series.points;
    if (points.isEmpty) return null;

    // Convert widget position to plot coordinates, then to data coordinates
    final plotPos = renderBox.widgetToPlot(widgetPosition);
    final dataPos = transform.plotToData(plotPos.dx, plotPos.dy);

    // Find the nearest point by X-distance in data space
    int nearestIndex = 0;
    double nearestDist = (points[0].x - dataPos.dx).abs();

    for (int i = 1; i < points.length; i++) {
      final dist = (points[i].x - dataPos.dx).abs();
      if (dist < nearestDist) {
        nearestDist = dist;
        nearestIndex = i;
      }
    }

    return nearestIndex;
  }

  /// Attempts segment-tap detection when no [SeriesElement] was directly hit.
  ///
  /// Converts [widgetPosition] to data coordinates, then scans all series
  /// to find the nearest styled data point. If found, fires [onPointTap]
  /// and [onRegionSelected] for the segment group.
  /// Attempts to select the nearest styled-segment point as a fallback.
  ///
  /// Returns `true` if a segment region was successfully selected.
  bool _trySegmentTapFallback(Offset widgetPosition) {
    if (widget.onRegionSelected == null && widget.onPointTap == null) return false;

    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    final transform = renderBox?.transform;

    // When coordinate transform is available, use it to find the nearest
    // styled point in data-space. Otherwise fall back to the first styled
    // point found (mirrors the annotation fallback in
    // _fireRegionSelectedForAnnotation).
    String? bestSeriesId;
    int? bestIndex;
    List<ChartDataPoint>? bestSeriesPoints;

    if (renderBox != null && transform != null) {
      // Hit-test for segment taps: two gates must both pass.
      //
      // Gate 1 (X-bracket): the tapped X must fall within a consecutive pair
      //   of styled data points. Rejects taps horizontally outside all segments.
      //
      // Gate 2 (Y-proximity): the tap must be within maxHitRadiusYPx vertical
      //   pixels of the interpolated line at that X. Prevents the full-height
      //   column selection effect — clicking far below an orange peak should not
      //   fire.
      const double maxHitRadiusYPx = 8.0;

      // Convert tap to data X.
      final plotPos = renderBox.widgetToPlot(widgetPosition);
      final dataPos = transform.plotToData(plotPos.dx, plotPos.dy);
      final tapDataX = dataPos.dx;

      double bestDistYPx = double.infinity;

      for (final series in widget.series) {
        final pts = series.points;
        if (pts.isEmpty) continue;

        // Gate 1: find bracket of consecutive points enclosing tapDataX.
        int? bracketIdx;
        for (int i = 0; i < pts.length - 1; i++) {
          if (tapDataX >= pts[i].x && tapDataX <= pts[i + 1].x) {
            bracketIdx = i;
            break;
          }
        }
        bracketIdx ??= tapDataX <= pts.first.x ? 0 : (tapDataX >= pts.last.x ? pts.length - 2 : null);
        if (bracketIdx == null) continue;

        final p0 = pts[bracketIdx];
        final p1 = pts[bracketIdx + 1];
        if (p0.segmentStyle == null && p1.segmentStyle == null) continue;

        // Gate 2: interpolate line Y at tapDataX and measure vertical distance.
        final t = (p1.x - p0.x) == 0 ? 0.0 : (tapDataX - p0.x) / (p1.x - p0.x);
        final interpY = p0.y + t * (p1.y - p0.y);
        final interpPlot = transform.dataToPlot(tapDataX, interpY);
        final interpWidget = renderBox.plotToWidget(Offset(interpPlot.dx, interpPlot.dy));
        final distYPx = (interpWidget.dy - widgetPosition.dy).abs();
        final effectiveDist = distYPx.isFinite ? distYPx : 0.0;

        if (effectiveDist < bestDistYPx) {
          bestDistYPx = effectiveDist;
          final repIdx = p0.segmentStyle != null ? bracketIdx : bracketIdx + 1;
          bestSeriesId = series.id;
          bestIndex = repIdx;
          bestSeriesPoints = pts;
        }
      }

      if (bestDistYPx > maxHitRadiusYPx) {
        bestSeriesId = null;
        bestIndex = null;
        bestSeriesPoints = null;
      }
    } else {
      // Fallback path: no transform available yet (e.g. early in layout cycle
      // or in widget-test environment). Pick the first series that has any
      // styled points and use the first styled point as the representative.
      outer:
      for (final series in widget.series) {
        for (int i = 0; i < series.points.length; i++) {
          if (series.points[i].segmentStyle != null) {
            bestSeriesId = series.id;
            bestIndex = i;
            bestSeriesPoints = series.points;
            break outer;
          }
        }
      }
    }

    if (bestSeriesId == null || bestIndex == null || bestSeriesPoints == null) {
      return false;
    }

    // Fire onPointTap for the nearest (or first) styled point
    final point = bestSeriesPoints[bestIndex];
    widget.onPointTap?.call(point, bestSeriesId);

    // Fire onRegionSelected with the segment group
    if (widget.onRegionSelected != null) {
      final segmentRegion = _regionAnalyzer.segmentGroupForPoint(bestSeriesId, bestSeriesPoints, bestIndex);
      if (segmentRegion != null) {
        _selectRegion(segmentRegion);
        return true;
      }
    }
    return false;
  }

  void _handleTapUp(TapUpDetails details) {
    // Double-click detection now handled in _handleTapDown    // (since activeElement is cleared by the time we get here)
    // CRITICAL: Cancel rangeAnnotationCreation mode on single click without drag
    // This provides an easy way to exit the mode if user changes their mind
    if (_coordinator.currentMode == InteractionMode.rangeAnnotationCreation) {
      // Check if this was a click without drag (no box selection drawn)
      // The RenderBox handles actual drag detection, so if we get here in creation mode,
      // it means the user just clicked without dragging
      _coordinator.releaseMode(force: true);
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
    if (_currentCursor != cursor) {
      setState(() => _currentCursor = cursor);
    }
  }

  /// Releases interaction mode after a short delay.
  ///
  /// Used for keyboard pan/zoom to ensure tooltip hide takes effect
  /// before returning to idle mode.
  void _releaseModeLater() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!_coordinator.isDisposed && !_coordinator.currentMode.isPassive) {
        _coordinator.releaseMode();
      }
    });
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
          _coordinator.claimMode(InteractionMode.panning);
          renderBox.panChart(-20.0, 0.0);
          _releaseModeLater();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        // Check if pan is enabled
        if (widget.interactionConfig?.enablePan ?? true) {
          _coordinator.claimMode(InteractionMode.panning);
          renderBox.panChart(20.0, 0.0);
          _releaseModeLater();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        // Check if pan is enabled
        if (widget.interactionConfig?.enablePan ?? true) {
          _coordinator.claimMode(InteractionMode.panning);
          renderBox.panChart(0.0, -20.0);
          _releaseModeLater();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        // Check if pan is enabled
        if (widget.interactionConfig?.enablePan ?? true) {
          _coordinator.claimMode(InteractionMode.panning);
          renderBox.panChart(0.0, 20.0);
          _releaseModeLater();
        }
      }
      // Zoom in with + or = or numpad +
      else if (event.logicalKey == LogicalKeyboardKey.equal ||
          event.logicalKey == LogicalKeyboardKey.add ||
          event.logicalKey == LogicalKeyboardKey.numpadAdd) {
        // Check if zoom is enabled
        final config = widget.interactionConfig ?? const InteractionConfig();
        if (config.enableZoom) {
          _coordinator.claimMode(InteractionMode.zooming);
          renderBox.zoomChart(1.0 + (config.keyboardZoomPercent / 100.0));
          _releaseModeLater();
        }
      }
      // Zoom out with - or numpad -
      else if (event.logicalKey == LogicalKeyboardKey.minus || event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
        // Check if zoom is enabled
        final config = widget.interactionConfig ?? const InteractionConfig();
        if (config.enableZoom) {
          _coordinator.claimMode(InteractionMode.zooming);
          renderBox.zoomChart(1.0 - (config.keyboardZoomPercent / 100.0));
          _releaseModeLater();
        }
      }
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight) {
        // Removed excessive debugPrint (removing shift modifier)
        _coordinator.removeModifierKey(LogicalKeyboardKey.shift);
      }
    }
  }

  // ============================================================================
  // LiveStreamController Integration
  // ============================================================================

  /// Attaches the LiveStreamController to the RenderBox.
  ///
  /// Called after build when the RenderBox exists. This enables the
  /// high-performance direct path for streaming data.
  void _attachLiveStreamController() {
    if (!mounted || widget.liveStreamController == null) return;

    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    if (renderBox != null) {
      widget.liveStreamController!.attachRenderBox(renderBox);
    }
  }

  // ============================================================================
  // Legacy Streaming Methods (deprecated - use LiveStreamController instead)
  // ============================================================================

  /// Sets up the stream subscription for real-time data ingestion.
  ///
  /// **Deprecated**: Use [LiveStreamController] for better performance.
  void _setupStreamSubscription() {
    final config = widget.streamingConfig ?? const StreamingConfig();

    // Initialize buffer if not already created
    _buffer ??= BufferManager<ChartDataPoint>(maxSize: config.maxBufferSize);

    // Subscribe to the data stream
    _streamSubscription = widget.dataStream?.listen(
      _onStreamData,
      onError: (error) {
        config.onStreamError?.call(error);
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

    // STEP 1: Capture current viewport bounds from axes
    // This is what the user sees RIGHT NOW - we must preserve it exactly
    if (_xAxis != null && _yAxis != null) {
      _lockedPausedBounds = DataBounds(xMin: _xAxis!.dataMin, xMax: _xAxis!.dataMax, yMin: _yAxis!.dataMin, yMax: _yAxis!.dataMax);
    }

    // STEP 2: Set pan constraints to full dataset bounds (Option 4)
    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    if (renderBox != null && _cachedDataXMin != null) {
      renderBox.setPanConstraintBounds(_cachedDataXMin!, _cachedDataXMax!, _cachedDataYMin!, _cachedDataYMax!);
    }

    // STEP 3: Update streaming state
    _isStreaming = false;

    // STEP 4: Force rebuild with locked bounds to prevent race condition
    // This ensures _lockedPausedBounds is used IMMEDIATELY, before any other rebuild
    setState(() {
      // Locked bounds are already set, this just triggers rebuild
    });
  }

  /// Resumes streaming and applies buffered data.
  /// FUNDAMENTAL FIX: Unlock the viewport bounds to resume dynamic calculation.
  void _resumeStreaming() {
    if (_isStreaming) return; // Already streaming

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
  }

  /// Computes the Y-range (min/max) for each series in the chart.
  ///
  /// This is used by [NormalizationDetector] to determine if multi-axis
  /// normalization should be applied automatically (FR-008, US2).
  ///
  /// Returns a map of series ID to [DataRange] containing that series' Y bounds.
  /// Series with no points are excluded from the result.
  Map<String, DataRange> _computeSeriesYRanges(List<ChartSeries> seriesList) {
    final result = <String, DataRange>{};

    for (final series in seriesList) {
      if (series.points.isEmpty) continue;

      double minY = double.infinity;
      double maxY = double.negativeInfinity;

      for (final point in series.points) {
        if (point.y < minY) minY = point.y;
        if (point.y > maxY) maxY = point.y;
      }

      // Handle edge case where all Y values are identical (zero span)
      if (minY == maxY) {
        // Create a small range around the value to avoid division by zero
        final value = minY;
        minY = value - 0.5;
        maxY = value + 0.5;
      }

      result[series.id] = DataRange(min: minY, max: maxY);
    }

    return result;
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
      autofocus: false,
      onKeyEvent: (node, event) {
        _handleKeyEvent(event);
        return KeyEventResult.handled;
      },
      child: Builder(
        builder: (context) {
          final hasFocus = _focusNode.hasFocus;
          final enableFocusOnHover = widget.interactionConfig?.enableFocusOnHover ?? true;
          return MouseRegion(
            onEnter: (_) {
              if (enableFocusOnHover && !_focusNode.hasFocus) {
                _focusNode.requestFocus();
              }
            },
            onExit: (_) {
              if (enableFocusOnHover && _focusNode.hasFocus) {
                _focusNode.unfocus();
              }
            },
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                border: (widget.interactionConfig?.showFocusBorder ?? false) && hasFocus
                    ? Border.all(color: widget.theme?.focusBorderColor ?? Colors.blue, width: widget.theme?.focusBorderWidth ?? 2.0)
                    : null,
                borderRadius: (widget.interactionConfig?.showFocusBorder ?? false) && hasFocus && (widget.theme?.focusBorderRadius ?? 0.0) > 0
                    ? BorderRadius.circular(widget.theme?.focusBorderRadius ?? 0.0)
                    : null,
              ),
              child: Stack(
                children: [
                  MouseRegion(
                    cursor: _coordinator.currentMode == InteractionMode.rangeAnnotationCreation
                        ? SystemMouseCursors
                              .precise // Precise crosshair cursor for range selection
                        : _currentCursor,
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
                        xAxisConfig: widget.xAxisConfig,
                        yAxis: _yAxis,
                        primaryYAxisConfig: widget.yAxis,
                        theme: widget.theme,
                        tooltipsEnabled: widget.interactionConfig?.tooltip.enabled ?? true,
                        // Prioritize widget's direct showXScrollbar/showYScrollbar properties
                        // InteractionConfig's defaults are false, so ?? doesn't work correctly
                        showXScrollbar: widget.showXScrollbar,
                        showYScrollbar: widget.showYScrollbar,
                        scrollbarTheme: widget.scrollbarTheme,
                        interactionConfig: widget.interactionConfig,
                        onCursorChange: _handleCursorChange,
                        onAnnotationChanged: _handleAnnotationChanged,
                        onElementHover: _handleElementHover,
                        onRangeCreationComplete: _onRangeCreationComplete,
                        onBoxSelectComplete: _onBoxSelectComplete,
                        onBoxSelectCleared: _onBoxSelectCleared, // Multi-axis parameters
                        normalizationMode: widget.normalizationMode,
                        series: widget.series,
                      ),
                    ),
                  ),
                  if (widget.showDebugInfo) Positioned(top: 8, left: 8, child: _DebugOverlay(coordinator: _coordinator)),
                  // Range creation mode instruction overlay
                  if (_coordinator.currentMode == InteractionMode.rangeAnnotationCreation)
                    Positioned(
                      top: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xE6448AFF), // Semi-opaque blue
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: const Text(
                            'Range Creation Mode: Drag to select region • ESC to cancel',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  // Widget-tree region summary overlay — uses real Text widgets
                  // so that find.text() works in tests (canvas paint is invisible
                  // to the Flutter widget finder).
                  // Rendered with opacity=0 so it is invisible to users while
                  // remaining discoverable by widget finders in tests.
                  // The canvas-painted version (via _regionSummaryRenderer) is
                  // the user-visible summary card.
                  // NOTE: Positioned must be a direct Stack child; Opacity wraps
                  // only the inner Container to avoid the ParentDataWidget error.
                  if (widget.showRegionSummary && _overlayRegionSummary != null && _overlayRegion != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Opacity(
                        opacity: 0.0,
                        child: _RegionSummaryOverlay(
                          summary: _overlayRegionSummary!,
                          config: widget.regionSummaryConfig ?? RegionSummaryConfig(),
                          customMetrics: _overlayCustomMetrics,
                        ),
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
            child: Text(widget.title!, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          ),
        );
      }

      if (widget.subtitle != null) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(widget.subtitle!, style: Theme.of(context).textTheme.titleSmall, textAlign: TextAlign.center),
          ),
        );
      }

      // Chart content takes available space
      children.add(Expanded(child: chartContent));

      // Legacy ChartLegend widget removed - overlay legend (LegendAnnotation)
      // is now used exclusively for legend rendering within the chart area.

      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
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
    this.xAxisConfig,
    this.yAxis,
    this.primaryYAxisConfig,
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
    this.onBoxSelectComplete,
    this.onBoxSelectCleared, // Multi-axis parameters
    this.normalizationMode,
    this.series,
  });

  final ChartInteractionCoordinator coordinator;
  final QuadTree spatialIndex;
  final List<ChartElement> Function(ChartTransform)? elementGenerator;
  final int elementGeneratorVersion;
  final chart_axis.Axis? xAxis;

  /// Modern X-axis configuration using [XAxisConfig].
  ///
  /// When provided, this is passed to ChartRenderBox for direct use in rendering,
  /// including crosshair label positioning.
  final XAxisConfig? xAxisConfig;

  final chart_axis.Axis? yAxis;

  /// The NEW [YAxisConfig] type from the widget for multi-axis system integration.
  final YAxisConfig? primaryYAxisConfig;
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
  final void Function(double startX, double endX)? onBoxSelectComplete;
  final VoidCallback? onBoxSelectCleared; // Multi-axis fields
  final NormalizationMode? normalizationMode;
  final List<ChartSeries>? series;

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
        normalizationMode: normalizationMode,
        series: series,
        onCursorChange: onCursorChange,
        onAnnotationChanged: onAnnotationChanged,
        onElementHover: onElementHover,
        onRangeCreationComplete: onRangeCreationComplete,
        onBoxSelectComplete: onBoxSelectComplete,
        onBoxSelectCleared: onBoxSelectCleared,
      )
      ..setXAxis(xAxis)
      ..setXAxisConfig(xAxisConfig)
      ..setYAxis(yAxis)
      ..setPrimaryYAxisConfig(primaryYAxisConfig);
  }

  @override
  void updateRenderObject(BuildContext context, ChartRenderBox renderObject) {
    renderObject
      ..setElementGenerator(elementGenerator, elementGeneratorVersion)
      ..setXAxis(xAxis)
      ..setXAxisConfig(xAxisConfig)
      ..setYAxis(yAxis)
      ..setPrimaryYAxisConfig(primaryYAxisConfig)
      ..setTheme(theme)
      ..setTooltipsEnabled(tooltipsEnabled)
      ..setShowXScrollbar(showXScrollbar)
      ..setShowYScrollbar(showYScrollbar)
      ..setScrollbarTheme(scrollbarTheme)
      ..setInteractionConfig(interactionConfig)
      ..setNormalizationMode(normalizationMode)
      ..setSeries(series)
      ..onElementHover = onElementHover
      ..onBoxSelectComplete = onBoxSelectComplete
      ..onBoxSelectCleared = onBoxSelectCleared;
  }
}

class _DebugOverlay extends StatelessWidget {
  const _DebugOverlay({required this.coordinator});

  final ChartInteractionCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.black.withAlpha(179), borderRadius: BorderRadius.circular(4)),
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

/// Widget-tree region summary overlay card.
///
/// Renders computed region statistics as real Flutter [Text] widgets so that
/// `find.text()` can locate metric labels and values in widget tests.  This
/// supplements the canvas-based [RegionSummaryRenderer] which is invisible to
/// the Flutter widget finder.
///
/// Displayed as a [Positioned] overlay inside the chart [Stack] when
/// [BravenChartPlus.showRegionSummary] is true and a region is selected.
///
/// Example:
/// ```dart
/// _RegionSummaryOverlay(
///   summary: regionSummary,
///   config: RegionSummaryConfig(),
///   customMetrics: {'NP': '250 W'},
/// )
/// ```
class _RegionSummaryOverlay extends StatelessWidget {
  /// Creates a [_RegionSummaryOverlay].
  ///
  /// [summary] holds the per-series statistics to display.
  /// [config] controls which [RegionMetric]s are shown.
  /// [customMetrics] are optional domain-specific label→value pairs appended
  /// after the built-in metrics.
  const _RegionSummaryOverlay({required this.summary, required this.config, this.customMetrics});

  /// The region summary produced by [RegionAnalyzer].
  final RegionSummary summary;

  /// Rendering configuration (which metrics to display, value formatter,
  /// position).
  final RegionSummaryConfig config;

  /// Optional custom metric key-value pairs returned by
  /// [BravenChartPlus.customRegionAnalysis].
  ///
  /// When non-null, these are appended after the built-in metric rows.
  final Map<String, String>? customMetrics;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    // Built-in per-series metrics
    final metricsList = config.metrics.toList();
    for (final entry in summary.seriesSummaries.entries) {
      final seriesSummary = entry.value;

      for (final metric in metricsList) {
        final rawValue = _metricValue(seriesSummary, metric);
        if (rawValue == null) continue;
        final formatted = _formatValue(rawValue, seriesSummary.unit, config);

        rows.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(metric.displayLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF555555))),
              const Text(': '),
              Text(
                formatted,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF111111)),
              ),
            ],
          ),
        );
      }
    }

    // Custom metrics appended after built-in rows
    if (customMetrics != null) {
      for (final entry in customMetrics!.entries) {
        rows.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(entry.key, style: const TextStyle(fontSize: 11, color: Color(0xFF555555))),
              const Text(': '),
              Text(
                entry.value,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF111111)),
              ),
            ],
          ),
        );
      }
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    // Returns only the Container — the Positioned wrapper is applied at the
    // call site so that Opacity can wrap this widget without violating the
    // StackParentData contract (Positioned must be a direct Stack child).
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFCCCCCC)),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }

  /// Returns the numeric value for [metric] from [s], or null when not
  /// available (e.g., stdDev with count < 2).
  double? _metricValue(SeriesRegionSummary s, RegionMetric metric) {
    return switch (metric) {
      RegionMetric.min => s.min,
      RegionMetric.max => s.max,
      RegionMetric.average => s.average,
      RegionMetric.sum => s.sum,
      RegionMetric.count => s.count.toDouble(),
      RegionMetric.range => s.range,
      RegionMetric.stdDev => s.stdDev,
      RegionMetric.delta => s.delta,
      RegionMetric.firstY => s.firstY,
      RegionMetric.lastY => s.lastY,
      RegionMetric.duration => s.duration,
    };
  }

  /// Formats [value] using the optional [config.valueFormatter] or falls back
  /// to 2 decimal places with an optional [unit] suffix.
  String _formatValue(double value, String? unit, RegionSummaryConfig config) {
    final formatter = config.valueFormatter;
    if (formatter != null) {
      return formatter(value, unit);
    }
    final formatted = value.toStringAsFixed(2);
    if (unit != null && unit.isNotEmpty) {
      return '$formatted $unit';
    }
    return formatted;
  }
}
