// Copyright (c) 2025 braven_charts. All rights reserved.
// BravenChartPlus - Integration of Prototype Interaction System
// NO REFERENCES TO lib/src - COMPLETELY ISOLATED

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb, setEquals;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

// All dependencies are in src - the main source folder
import 'axis/axis.dart' as chart_axis;
import 'axis/normalization_detector.dart';
import 'artifacts/chart_artifact_diagnostics.dart';
import 'artifacts/chart_artifact_canonicalizer.dart';
import 'artifacts/chart_document_extractor.dart';
import 'artifacts/chart_preview.dart';
import 'artifacts/chart_preview_capture.dart';
import 'artifacts/chart_view_state.dart';
import 'artifacts/resolved_chart_data.dart';
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
import 'models/axis_swap_mode.dart';
import 'models/braven_chart_controller.dart';
import 'models/chart_annotation.dart';
import 'models/chart_data_point.dart';
import 'models/chart_series.dart';
import 'models/chart_state_config.dart';
import 'models/chart_theme.dart';
import 'models/chart_type.dart';
import 'models/data_range.dart';
import 'models/enums.dart';
import 'models/grid_config.dart';
import 'models/interaction_config.dart';
import 'models/legend_style.dart';
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
import 'widgets/dialogs/chord_annotation_dialog.dart';
import 'widgets/dialogs/point_annotation_dialog.dart';
import 'widgets/dialogs/range_annotation_dialog.dart';
import 'widgets/dialogs/text_annotation_dialog.dart';
import 'widgets/dialogs/threshold_annotation_dialog.dart';
import 'widgets/dialogs/trend_annotation_dialog.dart';
import 'widgets/chart_state_view.dart';
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
    this.isLoading = false,
    this.loadingConfig = const ChartLoadingConfig.skeleton(),
    this.emptyStateConfig = const ChartEmptyStateConfig(),
    this.loadingWidget,
    this.errorWidget,
    this.autoScrollConfig,
    this.onPointTap,
    this.onPointHover,
    this.onBackgroundTap,
    this.onSeriesSelected,
    this.onAnnotationTap,
    this.onAnnotationDragged,
    // ==================== Y-AXIS SLOT SYSTEM PARAMETERS ====================
    this.maxAxesPerSide = 3,
    this.axisSwapMode = AxisSwapMode.sticky,
    this.bravenChartController,
    this.onSeriesDeselected,
    this.onAxisSwapped,
    // ==================== MULTI-AXIS PARAMETERS ====================
    this.normalizationMode,
  });

  // ==================== FACTORY CONSTRUCTORS ====================

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
    bool isLoading = false,
    ChartLoadingConfig loadingConfig = const ChartLoadingConfig.skeleton(),
    ChartEmptyStateConfig emptyStateConfig = const ChartEmptyStateConfig(),
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
    int maxAxesPerSide = 3,
    AxisSwapMode axisSwapMode = AxisSwapMode.sticky,
    BravenChartController? bravenChartController,
    void Function(String seriesId)? onSeriesDeselected,
    void Function({
      required String promotedAxisId,
      required String demotedAxisId,
    })?
    onAxisSwapped,
  }) {
    // Generate x-values if not provided
    final xVals = xValues ?? List.generate(yValues.length, (i) => i.toDouble());

    // Validate lengths match
    assert(
      xVals.length == yValues.length,
      'X and Y value lists must have the same length',
    );

    // Create data points
    final points = List.generate(
      yValues.length,
      (i) => ChartDataPoint(x: xVals[i], y: yValues[i]),
    );

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
      isLoading: isLoading,
      loadingConfig: loadingConfig,
      emptyStateConfig: emptyStateConfig,
      loadingWidget: loadingWidget,
      errorWidget: errorWidget,
      onPointTap: onPointTap,
      onPointHover: onPointHover,
      onBackgroundTap: onBackgroundTap,
      onSeriesSelected: onSeriesSelected,
      onAnnotationTap: onAnnotationTap,
      onAnnotationDragged: onAnnotationDragged,
      interactionConfig: interactionConfig,
      maxAxesPerSide: maxAxesPerSide,
      axisSwapMode: axisSwapMode,
      bravenChartController: bravenChartController,
      onSeriesDeselected: onSeriesDeselected,
      onAxisSwapped: onAxisSwapped,
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
    bool isLoading = false,
    ChartLoadingConfig loadingConfig = const ChartLoadingConfig.skeleton(),
    ChartEmptyStateConfig emptyStateConfig = const ChartEmptyStateConfig(),
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
    int maxAxesPerSide = 3,
    AxisSwapMode axisSwapMode = AxisSwapMode.sticky,
    BravenChartController? bravenChartController,
    void Function(String seriesId)? onSeriesDeselected,
    void Function({
      required String promotedAxisId,
      required String demotedAxisId,
    })?
    onAxisSwapped,
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
      isLoading: isLoading,
      loadingConfig: loadingConfig,
      emptyStateConfig: emptyStateConfig,
      loadingWidget: loadingWidget,
      errorWidget: errorWidget,
      onPointTap: onPointTap,
      onPointHover: onPointHover,
      onBackgroundTap: onBackgroundTap,
      onSeriesSelected: onSeriesSelected,
      onAnnotationTap: onAnnotationTap,
      onAnnotationDragged: onAnnotationDragged,
      interactionConfig: interactionConfig,
      maxAxesPerSide: maxAxesPerSide,
      axisSwapMode: axisSwapMode,
      bravenChartController: bravenChartController,
      onSeriesDeselected: onSeriesDeselected,
      onAxisSwapped: onAxisSwapped,
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
    bool isLoading = false,
    ChartLoadingConfig loadingConfig = const ChartLoadingConfig.skeleton(),
    ChartEmptyStateConfig emptyStateConfig = const ChartEmptyStateConfig(),
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
    StreamingConfig? streamingConfig,
    Stream<ChartDataPoint>? dataStream,
    StreamingController? streamingController,
    bool showDebugInfo = false,
    bool showXScrollbar = false,
    bool showYScrollbar = false,
    ScrollbarConfig? scrollbarTheme,
    AnnotationController? annotationController,
    int maxAxesPerSide = 3,
    AxisSwapMode axisSwapMode = AxisSwapMode.sticky,
    BravenChartController? bravenChartController,
    void Function(String seriesId)? onSeriesDeselected,
    void Function({
      required String promotedAxisId,
      required String demotedAxisId,
    })?
    onAxisSwapped,
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
          throw ArgumentError(
            'JSON array must contain objects with x and y properties',
          );
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
      isLoading: isLoading,
      loadingConfig: loadingConfig,
      emptyStateConfig: emptyStateConfig,
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
      maxAxesPerSide: maxAxesPerSide,
      axisSwapMode: axisSwapMode,
      bravenChartController: bravenChartController,
      onSeriesDeselected: onSeriesDeselected,
      onAxisSwapped: onAxisSwapped,
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
  /// This is the supported X-axis configuration for the chart.
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
  /// If null, defaults to [ScrollbarConfig.defaultLight].
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
  /// Controls tooltip visibility via `InteractionConfig.tooltip.enabled`.
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

  /// Whether the chart data is currently loading.
  ///
  /// Loading takes precedence over both chart content and the empty state while
  /// preserving the chart's configured viewport size.
  final bool isLoading;

  /// Configures the built-in loading presentation.
  final ChartLoadingConfig loadingConfig;

  /// Configures the state shown when loading has finished without data.
  final ChartEmptyStateConfig emptyStateConfig;

  /// Widget to display while loading data.
  ///
  /// When provided, this replaces the indicator selected by [loadingConfig].
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
  final void Function(ChartAnnotation annotation, Offset newPosition)?
  onAnnotationDragged;

  // ==================== Y-AXIS SLOT SYSTEM PARAMETERS ====================

  /// Maximum number of Y-axes visible simultaneously on each side.
  ///
  /// When more series configure a Y-axis at the same position than this limit
  /// allows, the first [maxAxesPerSide] declared win visible slots. The rest
  /// are in overflow — not rendered but still used for normalization.
  /// Defaults to 3. Must be >= 1.
  ///
  /// Overflow axes can be swapped in by selecting their series (via legend tap,
  /// data-point tap, or [BravenChartController.selectSeries]).
  final int maxAxesPerSide;

  /// Controls whether a swap triggered by series selection persists after
  /// deselection. Defaults to [AxisSwapMode.sticky].
  ///
  /// - [AxisSwapMode.sticky]: The swapped-in axis stays visible.
  /// - [AxisSwapMode.revert]: Original declaration-order slot assignment
  ///   is restored when the selected series is deselected.
  final AxisSwapMode axisSwapMode;

  /// Optional controller for programmatic series selection and slot inspection.
  ///
  /// Attach to read [BravenChartController.visibleAxisIds] or call
  /// [BravenChartController.selectSeries] from outside the chart.
  /// The controller is optional — charts without one respond to taps internally.
  final BravenChartController? bravenChartController;

  /// Called when a series is deselected (tap again or tap empty space).
  final void Function(String seriesId)? onSeriesDeselected;

  /// Called immediately after an axis swap completes.
  ///
  /// `promotedAxisId` entered a visible slot; `demotedAxisId` moved to overflow.
  final void Function({
    required String promotedAxisId,
    required String demotedAxisId,
  })?
  onAxisSwapped;

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

  @override
  State<BravenChartPlus> createState() => _BravenChartPlusState();
}

class _BravenChartPlusState extends State<BravenChartPlus>
    with SingleTickerProviderStateMixin {
  late ChartInteractionCoordinator _coordinator;
  late QuadTree _spatialIndex;
  late PriorityPanGestureRecognizer _panRecognizer;
  late PriorityTapGestureRecognizer _tapRecognizer;
  late FocusNode _focusNode;

  MouseCursor _currentCursor = SystemMouseCursors.basic;
  final GlobalKey _renderBoxKey = GlobalKey();

  /// Currently selected series ID for Y-axis slot selection.
  String? _selectedSeriesId;

  final Set<ChartPointRef> _focusedPointRefs = <ChartPointRef>{};
  final Set<ChartPointRef> _selectedPointRefs = <ChartPointRef>{};

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
  Timer? _streamingResumeTimer;

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

  // Multi-axis normalization state (FR-008, US2)
  // Tracks whether auto-normalization is needed based on series Y-range ratios
  bool _normalizationNeeded = false;
  Map<String, DataRange> _seriesYRanges = {};
  ResolvedChartData _resolvedChartData = ResolvedChartData.empty;
  List<ChartSeries> _effectiveDataSeries = const <ChartSeries>[];
  List<ChartSeries> _effectiveRenderSeries = const <ChartSeries>[];
  int _captureStateRevisionValue = 0;
  int _documentRevision = 0;
  _ChartCaptureRevisionToken? _lastDocumentRevisionToken;
  _ChartEffectiveRevisionToken? _lastPublishedEffectiveRevisionToken;
  ChartDocumentRevision _effectiveDocumentRevision =
      ChartDocumentRevision.next();
  bool _documentRevisionFrameScheduled = false;
  Timer? _liveDocumentRevisionTimer;
  final GlobalKey _previewBoundaryKey = GlobalKey();
  bool _previewCaptureInProgress = false;
  final Map<String, _IncomingPointAnimation> _incomingPointAnimations =
      <String, _IncomingPointAnimation>{};
  late final AnimationController _incomingDataAnimationController;

  // Internal annotation controller - created automatically when user doesn't provide one
  // This allows static annotations to be editable/draggable without explicit controller
  AnnotationController? _internalAnnotationController;

  // Legend custom position - stored internally since legend is auto-generated
  // and doesn't require user-provided annotationController
  Offset? _legendCustomPosition;

  /// Whether multi-axis normalization is currently needed.
  ///
  /// This is automatically determined by [NormalizationDetector] based on
  /// the Y-range ratios between series. When series have ranges that differ
  /// by 10x or more, normalization is recommended.
  ///
  /// See also:
  /// - [NormalizationDetector.shouldNormalize] for the detection logic
  /// - [seriesYRanges] for the individual series Y bounds
  bool get normalizationNeeded => _normalizationNeeded;

  bool get _hasMultiAxisConfig => widget.series.any(
    (series) =>
        series.yAxisConfig != null ||
        (series.yAxisId != null && series.yAxisId!.isNotEmpty),
  );

  NormalizationMode? get _effectiveNormalizationMode {
    final mode = widget.normalizationMode;

    if (!_hasMultiAxisConfig) {
      return mode == NormalizationMode.perSeries
          ? NormalizationMode.none
          : mode;
    }

    return switch (mode) {
      NormalizationMode.auto =>
        _normalizationNeeded
            ? NormalizationMode.perSeries
            : NormalizationMode.none,
      _ => mode,
    };
  }

  /// The Y-range bounds for each series.
  ///
  /// This map contains [DataRange] objects keyed by series ID, representing
  /// the min/max Y values for each series. Used for multi-axis normalization
  /// and tooltip value display.
  Map<String, DataRange> get seriesYRanges => Map.unmodifiable(_seriesYRanges);

  /// Returns the effective annotation controller (user-provided or internal).
  AnnotationController? get _effectiveAnnotationController =>
      widget.annotationController ?? _internalAnnotationController;

  int get _captureStateRevision => _captureStateRevisionValue;

  set _captureStateRevision(int value) {
    if (_captureStateRevisionValue == value) return;
    _captureStateRevisionValue = value;
    _scheduleEffectiveDocumentRevisionPublish();
  }

  void _scheduleEffectiveDocumentRevisionPublish() {
    if (_documentRevisionFrameScheduled || !mounted) return;
    _documentRevisionFrameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _documentRevisionFrameScheduled = false;
      if (mounted) _publishEffectiveDocumentRevision();
    });
  }

  void _scheduleLiveDocumentRevisionPublish() {
    if (_liveDocumentRevisionTimer != null || !mounted) return;
    _liveDocumentRevisionTimer = Timer(const Duration(milliseconds: 250), () {
      _liveDocumentRevisionTimer = null;
      if (mounted) _publishEffectiveDocumentRevision();
    });
  }

  void _onLiveDocumentSourceChanged() {
    _scheduleLiveDocumentRevisionPublish();
  }

  ChartDocumentRevision _publishEffectiveDocumentRevision([
    _ChartEffectiveRevisionToken? sourceToken,
  ]) {
    final nextToken = sourceToken ?? _captureEffectiveRevisionToken();
    if (_lastPublishedEffectiveRevisionToken != nextToken) {
      _lastPublishedEffectiveRevisionToken = nextToken;
      _effectiveDocumentRevision = ChartDocumentRevision.next();
      widget.bravenChartController?.updateEffectiveDocumentRevision(
        _effectiveDocumentRevision,
      );
    }
    return _effectiveDocumentRevision;
  }

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
      _internalAnnotationController = AnnotationController(
        initialAnnotations: widget.annotations,
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
    _coordinator = ChartInteractionCoordinator();
    _coordinator.addListener(_onCoordinatorChanged);

    _spatialIndex = QuadTree(
      bounds: const Rect.fromLTWH(0, 0, 800, 600),
      maxElementsPerNode: 4,
    );

    _panRecognizer = PriorityPanGestureRecognizer(
      coordinator: _coordinator,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
    );

    _tapRecognizer = PriorityTapGestureRecognizer(
      coordinator: _coordinator,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
    );

    _incomingDataAnimationController =
        AnimationController(
            vsync: this,
            duration: _incomingDataAnimationDuration,
          )
          ..addListener(_handleIncomingDataAnimationTick)
          ..addStatusListener(_handleIncomingDataAnimationStatus);

    // Listen to controller updates (matches BravenChart pattern)
    widget.controller?.addListener(_onControllerUpdate);
    widget.liveStreamController?.addListener(_onLiveDocumentSourceChanged);
    widget.liveStreamController?.effectiveDataRevision.addListener(
      _onLiveDocumentSourceChanged,
    );

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

    widget.bravenChartController?.attach(
      onSelect: _handleSeriesSelected,
      onDeselect: _handleSeriesDeselected,
      onSetSeriesVisibility: _setSeriesVisibility,
      onExtractDocument: _extractDocument,
      onRestoreViewState: _restoreViewState,
      onCapturePreview: _capturePreview,
      onFocusPoints: _focusPoints,
      onSelectPoints: _selectPoints,
      onClearPointFocus: _clearPointFocus,
      onClearPointSelection: _clearPointSelection,
      effectiveDocumentRevision: _effectiveDocumentRevision,
      onClear: () {
        _captureStateRevision++;
        _selectedSeriesId = null;
        final renderBox =
            _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
        renderBox?.clearAllSeriesSelection();
        _syncControllerState(renderBox);
      },
    );
    _syncControllerPointState();
    _scheduleEffectiveDocumentRevisionPublish();
  }

  @override
  void didUpdateWidget(BravenChartPlus oldWidget) {
    super.didUpdateWidget(oldWidget);
    _captureStateRevision++;
    // Removed excessive debugPrints (didUpdateWidget details)

    // Handle controller changes (matches BravenChart pattern)
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onControllerUpdate);
      widget.controller?.addListener(_onControllerUpdate);
    }

    // Handle annotation controller changes
    if (widget.annotationController != oldWidget.annotationController) {
      // Remove listener from old effective controller
      final oldEffectiveController =
          oldWidget.annotationController ?? _internalAnnotationController;
      oldEffectiveController?.removeListener(_onAnnotationControllerUpdate);

      // Dispose internal controller if we're switching to user-provided one
      if (widget.annotationController != null &&
          _internalAnnotationController != null) {
        _internalAnnotationController?.dispose();
        _internalAnnotationController = null;
      }

      // Reinitialize controller for new widget
      _initializeAnnotationController();

      // Add listener to new effective controller
      _effectiveAnnotationController?.addListener(
        _onAnnotationControllerUpdate,
      );

      // CRITICAL FIX: Rebuild elements when annotation controller changes.
      // Previously elements were NOT rebuilt, causing stale annotations to persist
      // even when a new controller with different annotations was provided.
      _rebuildElements();
    }

    // Handle static annotations changes when no user controller
    if (widget.annotationController == null &&
        widget.annotations != oldWidget.annotations) {
      // Recreate internal controller with new annotations
      _internalAnnotationController?.dispose();
      _internalAnnotationController = null;
      _initializeAnnotationController();
      _effectiveAnnotationController?.addListener(
        _onAnnotationControllerUpdate,
      );
      // Elements will be rebuilt by the condition below (annotations changed)
    }

    // Handle LiveStreamController changes
    if (widget.liveStreamController != oldWidget.liveStreamController) {
      oldWidget.liveStreamController?.removeListener(
        _onLiveDocumentSourceChanged,
      );
      oldWidget.liveStreamController?.effectiveDataRevision.removeListener(
        _onLiveDocumentSourceChanged,
      );
      oldWidget.liveStreamController?.detachRenderBox();
      widget.liveStreamController?.addListener(_onLiveDocumentSourceChanged);
      widget.liveStreamController?.effectiveDataRevision.addListener(
        _onLiveDocumentSourceChanged,
      );
      if (widget.liveStreamController != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _attachLiveStreamController();
        });
      }
    }

    if (widget.bravenChartController != oldWidget.bravenChartController) {
      oldWidget.bravenChartController?.detach();
      widget.bravenChartController?.attach(
        onSelect: _handleSeriesSelected,
        onDeselect: _handleSeriesDeselected,
        onSetSeriesVisibility: _setSeriesVisibility,
        onExtractDocument: _extractDocument,
        onRestoreViewState: _restoreViewState,
        onCapturePreview: _capturePreview,
        onFocusPoints: _focusPoints,
        onSelectPoints: _selectPoints,
        onClearPointFocus: _clearPointFocus,
        onClearPointSelection: _clearPointSelection,
        effectiveDocumentRevision: _effectiveDocumentRevision,
        onClear: () {
          _captureStateRevision++;
          _selectedSeriesId = null;
          final renderBox =
              _renderBoxKey.currentContext?.findRenderObject()
                  as ChartRenderBox?;
          renderBox?.clearAllSeriesSelection();
          _syncControllerState(renderBox);
        },
      );
      _syncControllerPointState();
    }

    if (widget.series != oldWidget.series ||
        widget.theme != oldWidget.theme ||
        widget.annotations != oldWidget.annotations) {
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
    _incomingDataAnimationController
      ..removeListener(_handleIncomingDataAnimationTick)
      ..removeStatusListener(_handleIncomingDataAnimationStatus)
      ..dispose();
    _streamingResumeTimer?.cancel();
    _liveDocumentRevisionTimer?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _streamSubscription?.cancel();
    widget.controller?.removeListener(_onControllerUpdate);
    widget.liveStreamController?.removeListener(_onLiveDocumentSourceChanged);
    widget.liveStreamController?.effectiveDataRevision.removeListener(
      _onLiveDocumentSourceChanged,
    );
    _effectiveAnnotationController?.removeListener(
      _onAnnotationControllerUpdate,
    );
    _internalAnnotationController?.dispose();
    widget.liveStreamController?.detachRenderBox();
    widget.bravenChartController?.detach();
    _coordinator.removeListener(_onCoordinatorChanged);
    _coordinator.dispose();
    _panRecognizer.dispose();
    _tapRecognizer.dispose();
    super.dispose();
  }

  /// Called when controller notifies of changes (matches BravenChart pattern).
  void _onControllerUpdate() {
    if (!mounted) return;
    _captureStateRevision++;

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
      _rebuildElements(detectIncomingAnimations: true);
    });
  }

  bool get _autoScrollEnabled {
    final config = widget.streamingConfig ?? const StreamingConfig();
    return widget.autoScrollConfig?.enabled ?? config.autoScroll;
  }

  bool get _managesStreamingViewport {
    return widget.streamingController != null && _autoScrollEnabled;
  }

  bool get _pauseOnViewportInteraction {
    return _managesStreamingViewport &&
        (widget.autoScrollConfig?.pauseOnUserInteraction ?? false);
  }

  bool get _shouldAnimateIncomingData {
    if (!(widget.autoScrollConfig?.animateIncomingData ?? true)) {
      return false;
    }

    if (_incomingDataAnimationDuration <= Duration.zero) {
      return false;
    }

    if (!_autoScrollEnabled || !_isStreaming || widget.controller == null) {
      return false;
    }

    final controller = widget.streamingController;
    return controller == null ||
        controller.viewportMode == ViewportMode.followLatest;
  }

  Duration get _incomingDataAnimationDuration =>
      widget.autoScrollConfig?.incomingDataAnimationDuration ??
      const Duration(milliseconds: 180);

  bool get _usesPerSeriesNormalizedMultiAxis {
    if (_effectiveNormalizationMode != NormalizationMode.perSeries) {
      return false;
    }

    return _hasMultiAxisConfig;
  }

  void _cancelStreamingResumeTimer() {
    _streamingResumeTimer?.cancel();
    _streamingResumeTimer = null;
  }

  void _pauseStreamingForViewportInteraction() {
    if (!_pauseOnViewportInteraction) {
      return;
    }

    _cancelStreamingResumeTimer();
    widget.streamingController?.pauseStreaming();
  }

  void _scheduleStreamingResumeIfNeeded() {
    if (!_pauseOnViewportInteraction) {
      return;
    }

    final resumeDelay = widget.autoScrollConfig?.resumeAfterInteractionDelay;
    if (resumeDelay == null) {
      return;
    }

    _cancelStreamingResumeTimer();
    _streamingResumeTimer = Timer(resumeDelay, () {
      if (!mounted) {
        return;
      }

      if (widget.streamingController?.viewportMode == ViewportMode.explore) {
        widget.streamingController?.resumeStreaming();
      }
    });
  }

  void _handleViewportInteractionPulse() {
    _captureStateRevision++;
    _pauseStreamingForViewportInteraction();
    _scheduleStreamingResumeIfNeeded();
  }

  void _returnToLiveViewport(ChartRenderBox renderBox) {
    _cancelStreamingResumeTimer();

    if (_managesStreamingViewport) {
      if (widget.streamingController?.viewportMode == ViewportMode.explore ||
          !_isStreaming) {
        widget.streamingController?.resumeStreaming();
      } else {
        _jumpToLatestData();
      }
      return;
    }

    renderBox.resetView();
  }

  /// Called when annotation controller notifies of changes.
  void _onAnnotationControllerUpdate() {
    if (!mounted) {
      return;
    }
    _captureStateRevision++;

    // Annotations changed - rebuild elements
    // NOTE: setState() will trigger build() → updateRenderObject() → setElementGenerator()
    // automatically, so we don't need to call it manually here.
    setState(() {
      _rebuildElements();
    });
  }

  /// Called when an annotation is modified through user interaction (e.g., drag-to-resize).
  void _handleAnnotationChanged(
    String annotationId,
    ChartAnnotation updatedAnnotation,
  ) {
    // Special handling for internal legend - store position in state
    if (annotationId == '__internal_legend__' &&
        updatedAnnotation is LegendAnnotation) {
      setState(() {
        _captureStateRevision++;
        _legendCustomPosition = updatedAnnotation.customPosition;
        _rebuildElements();
      });
      return;
    }

    // Update via effective controller (user-provided or internal)
    // Internal controller makes static annotations editable/draggable
    if (_effectiveAnnotationController != null) {
      _effectiveAnnotationController!.updateAnnotation(
        annotationId,
        updatedAnnotation,
      );
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

  ResolvedChartData _resolveChartData({bool includeDirectStream = false}) {
    final liveController = includeDirectStream
        ? widget.liveStreamController
        : null;
    return ResolvedChartData.resolve(
      baseSeries: widget.series,
      hiddenSeriesIds: _hiddenSeriesIds,
      controllerSeries: widget.controller?.getAllSeries(),
      controllerRevision: widget.controller?.revision ?? 0,
      legacyStreamingPoints: _streamingDataPoints,
      liveSeries: liveController == null
          ? null
          : ResolvedLiveSeriesData(
              seriesId: liveController.seriesId,
              points: liveController.points,
              pendingPoints: liveController.pendingPoints,
              committedRevision: liveController.committedDataRevision,
              pendingRevision: liveController.pendingDataRevision,
              pendingPointCount: liveController.bufferedCount,
            ),
      seriesFactory: (seriesId, points, seriesIndex) => LineChartSeries(
        id: seriesId,
        name: seriesId,
        points: points,
        color: widget.theme?.seriesTheme.colors.isNotEmpty == true
            ? widget.theme!.seriesTheme.colors[seriesIndex %
                  widget.theme!.seriesTheme.colors.length]
            : Colors.blue,
      ),
    );
  }

  /// Returns the annotation projection shared by rendering and extraction.
  ///
  /// AnnotationController values take precedence when both controllers contain
  /// the same stable ID because they represent the chart's editable state.
  List<ChartAnnotation> _resolveEffectiveAnnotations() {
    final byId = <String, ChartAnnotation>{};
    for (final annotation
        in widget.controller?.getAllAnnotations() ?? const []) {
      byId[annotation.id] = annotation;
    }
    for (final annotation
        in _effectiveAnnotationController?.annotations ?? const []) {
      byId[annotation.id] = annotation;
    }
    return List.unmodifiable(byId.values);
  }

  _ChartEffectiveRevisionToken _captureEffectiveRevisionToken() {
    final live = widget.liveStreamController;
    final renderBox =
        _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    final transform = renderBox?.transform;
    final hiddenIds = _hiddenSeriesIds.toList()..sort();
    return _ChartEffectiveRevisionToken(
      stateRevision: _captureStateRevision,
      controllerRevision: widget.controller?.revision ?? 0,
      annotationRevision: _effectiveAnnotationController?.revision ?? 0,
      liveCommittedRevision: live?.committedDataRevision ?? 0,
      livePendingRevision: live?.pendingDataRevision ?? 0,
      livePendingPointCount: live?.bufferedCount ?? 0,
      viewStateHash: Object.hash(
        transform?.dataXMin,
        transform?.dataXMax,
        transform?.dataYMin,
        transform?.dataYMax,
        Object.hashAll(renderBox?.visibleAxisIds ?? const []),
        Object.hashAll(renderBox?.overflowAxisIds ?? const []),
        Object.hashAll(hiddenIds),
        _selectedSeriesId,
        Object.hashAll(
          _selectedPointRefs.toList()..sort((a, b) {
            final bySeries = a.seriesId.compareTo(b.seriesId);
            return bySeries != 0
                ? bySeries
                : a.pointIndex.compareTo(b.pointIndex);
          }),
        ),
        _effectiveAnnotationController?.selectedAnnotationId,
        _legendCustomPosition,
      ),
    );
  }

  _ChartCaptureRevisionToken _captureRevisionToken(
    ChartDocumentExtractOptions options,
  ) {
    return _ChartCaptureRevisionToken(
      effectiveRevision: _captureEffectiveRevisionToken(),
      optionsKey: jsonEncode({
        'dataScope': options.dataScope.name,
        'dataStorage': options.dataStorage.wireName,
        'includeViewState': options.includeViewState,
        'themeMode': options.themeMode.name,
        'themeReference': options.themeReference,
        'xAxisFormatter': options.xAxisFormatterDescriptor?.toJson(),
        'yAxisFormatters': {
          for (final key
              in options.yAxisFormatterDescriptors.keys.toList()..sort())
            key: options.yAxisFormatterDescriptors[key]!.toJson(),
        },
        'interactionBindings': {
          for (final key
              in options.interactionBindingDescriptors.keys.toList()..sort())
            key: options.interactionBindingDescriptors[key]!.toJson(),
        },
      }),
    );
  }

  ChartArtifactResult<ChartDocumentSnapshot> _extractDocument(
    ChartDocumentExtractOptions options,
  ) {
    for (var attempt = 0; attempt < options.maxSnapshotAttempts; attempt++) {
      final before = _captureRevisionToken(options);
      final nextRevision =
          _lastDocumentRevisionToken == null ||
              _lastDocumentRevisionToken == before
          ? _documentRevision
          : _documentRevision + 1;
      final effectiveRevision = _publishEffectiveDocumentRevision(
        before.effectiveRevision,
      );
      final assembled = _assembleDocumentSnapshot(
        options,
        nextRevision,
        effectiveRevision,
      );
      if (assembled is ChartArtifactFailure<ChartDocumentSnapshot>) {
        return assembled;
      }
      final after = _captureRevisionToken(options);
      if (before != after) continue;

      _lastDocumentRevisionToken = after;
      _documentRevision = nextRevision;
      return assembled;
    }

    return ChartArtifactFailure(
      error: ChartArtifactError(
        code: ChartArtifactDiagnosticCodes.unstableStreamRevision,
        message:
            'The chart changed during all ${options.maxSnapshotAttempts} snapshot attempts.',
      ),
    );
  }

  Future<ChartArtifactResult<ChartPreview>> _capturePreview(
    ChartPreviewOptions options,
  ) async {
    if (_previewCaptureInProgress) {
      return ChartArtifactFailure(
        error: const ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.captureInProgress,
          message: 'A chart preview capture is already in progress.',
        ),
      );
    }
    if (!options.pixelRatio.isFinite ||
        options.pixelRatio <= 0 ||
        options.maxPixelCount <= 0 ||
        options.maxCaptureAttempts <= 0) {
      return ChartArtifactFailure(
        error: const ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.previewCaptureFailed,
          message: 'Preview capture options are invalid.',
        ),
      );
    }

    _previewCaptureInProgress = true;
    try {
      if (!options.includeTransientInteractions) {
        _coordinator.setHoveredMarker(null);
        _coordinator.setHoveredElement(null);
        final renderBox =
            _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
        renderBox?.clearTransientPreviewState();
      }
      await WidgetsBinding.instance.endOfFrame;

      for (var attempt = 0; attempt < options.maxCaptureAttempts; attempt++) {
        final documentResult = _extractDocument(options.documentOptions);
        if (documentResult is ChartArtifactFailure<ChartDocumentSnapshot>) {
          return ChartArtifactFailure(
            error: documentResult.error,
            warnings: documentResult.warnings,
          );
        }
        final documentSuccess =
            documentResult as ChartArtifactSuccess<ChartDocumentSnapshot>;
        final revision = _captureRevisionToken(options.documentOptions);
        await WidgetsBinding.instance.endOfFrame;
        if (revision != _captureRevisionToken(options.documentOptions)) {
          continue;
        }

        final boundary = _previewBoundaryKey.currentContext?.findRenderObject();
        if (boundary is! RenderRepaintBoundary || !boundary.hasSize) {
          return ChartArtifactFailure(
            error: const ChartArtifactError(
              code: ChartArtifactDiagnosticCodes.previewCaptureFailed,
              message: 'The chart preview boundary is not ready for capture.',
            ),
            warnings: documentSuccess.warnings,
          );
        }
        final widthPixels = (boundary.size.width * options.pixelRatio).ceil();
        final heightPixels = (boundary.size.height * options.pixelRatio).ceil();
        if (widthPixels <= 0 ||
            heightPixels <= 0 ||
            widthPixels * heightPixels > options.maxPixelCount) {
          return ChartArtifactFailure(
            error: ChartArtifactError(
              code: ChartArtifactDiagnosticCodes.previewTooLarge,
              message:
                  'Preview dimensions ${widthPixels}x$heightPixels exceed the configured pixel limit.',
            ),
            warnings: documentSuccess.warnings,
          );
        }

        final image = await boundary.toImage(pixelRatio: options.pixelRatio);
        try {
          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (byteData == null) {
            throw StateError('The Flutter engine returned no PNG bytes.');
          }
          if (revision != _captureRevisionToken(options.documentOptions)) {
            continue;
          }
          final bytes = byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          );
          return ChartArtifactSuccess(
            value: ChartPreview(
              mimeType: 'image/png',
              widthPixels: image.width,
              heightPixels: image.height,
              pixelRatio: options.pixelRatio,
              documentHash: ChartArtifactCanonicalizer.documentHash(
                documentSuccess.value.document,
              ),
              bytes: bytes,
              byteLength: bytes.length,
            ),
            warnings: documentSuccess.warnings,
          );
        } finally {
          image.dispose();
        }
      }
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.unstableStreamRevision,
          message:
              'The chart changed during all ${options.maxCaptureAttempts} preview attempts.',
        ),
      );
    } on Object catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.previewCaptureFailed,
          message: 'Chart preview capture failed: $error',
        ),
      );
    } finally {
      _previewCaptureInProgress = false;
    }
  }

  ChartArtifactResult<ChartDocumentSnapshot> _assembleDocumentSnapshot(
    ChartDocumentExtractOptions options,
    int revision,
    ChartDocumentRevision effectiveRevision,
  ) {
    final resolved = _resolveChartData(includeDirectStream: true);
    final renderBox =
        _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    final transform = renderBox?.transform;
    final axisModels = <YAxisConfig>[];
    final axisIds = <String>{};
    void addAxis(YAxisConfig axis, String fallbackId) {
      final resolvedAxis = axis.id.isEmpty
          ? axis.copyWith(id: fallbackId)
          : axis;
      if (axisIds.add(resolvedAxis.id)) axisModels.add(resolvedAxis);
    }

    if (widget.yAxis != null) addAxis(widget.yAxis!, 'y');
    for (final series in resolved.allSeries) {
      final axis = series.yAxisConfig;
      if (axis != null) addAxis(axis, '${series.id}_axis');
    }
    if (axisModels.isEmpty) {
      addAxis(YAxisConfig(position: YAxisPosition.left), 'y');
    }
    final effectiveTheme = widget.theme ?? ChartTheme.light;
    final baseInteraction =
        widget.interactionConfig ?? const InteractionConfig();
    final legendPosition = _legendCustomPosition;
    final viewState = ChartViewState(
      visibleBounds: transform == null
          ? null
          : ChartBoundsDocument(
              xMin: transform.dataXMin,
              xMax: transform.dataXMax,
              yMin: transform.dataYMin,
              yMax: transform.dataYMax,
            ),
      hiddenSeriesIds: resolved.hiddenSeriesIds,
      selectedSeriesId: _selectedSeriesId,
      selectedPointRefs: _selectedPointRefs,
      visibleAxisIds: renderBox?.visibleAxisIds ?? const [],
      overflowAxisIds: renderBox?.overflowAxisIds ?? const [],
      selectedAnnotationId:
          _effectiveAnnotationController?.selectedAnnotationId,
      legendPosition: legendPosition == null
          ? null
          : ChartPositionDocument(x: legendPosition.dx, y: legendPosition.dy),
    );

    return ChartDocumentExtractor.extract(
      source: ChartDocumentExtractionSource(
        allSeries: resolved.allSeries,
        visibleSeries: resolved.visibleSeries,
        declaredSeries: widget.series,
        annotations: _resolveEffectiveAnnotations(),
        xAxis: widget.xAxisConfig ?? const XAxisConfig(),
        axes: axisModels,
        theme: effectiveTheme,
        interaction: baseInteraction.copyWith(
          showXScrollbar:
              widget.showXScrollbar || baseInteraction.showXScrollbar,
          showYScrollbar:
              widget.showYScrollbar || baseInteraction.showYScrollbar,
        ),
        legendVisible: widget.showLegend,
        legendStyle: widget.legendStyle ?? effectiveTheme.legendStyle,
        grid: widget.grid ?? const GridConfig(),
        normalizationMode:
            _effectiveNormalizationMode ?? NormalizationMode.none,
        title: widget.title,
        subtitle: widget.subtitle,
        width: widget.width,
        height: widget.height,
        backgroundColor: widget.backgroundColor,
        showToolbar: widget.showToolbar,
        interactiveAnnotations: widget.interactiveAnnotations,
        maxAxesPerSide: widget.maxAxesPerSide,
        axisSwapMode: widget.axisSwapMode,
        viewState: viewState,
      ),
      options: options,
      revision: revision,
      effectiveRevision: effectiveRevision,
    );
  }

  void _rebuildElements({bool detectIncomingAnimations = false}) {
    _spatialIndex.clear();

    final previousSeriesById = <String, ChartSeries>{
      for (final series in _effectiveDataSeries) series.id: series,
    };

    _resolvedChartData = _resolveChartData();
    _effectiveDataSeries = _resolvedChartData.renderSeries;
    _pruneInvalidPointRefs();
    if (detectIncomingAnimations) {
      _updateIncomingPointAnimations(
        previousSeriesById: previousSeriesById,
        nextSeries: _effectiveDataSeries,
      );
    }
    _refreshAnimatedRenderSeries();

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
      final autoScrollEnabled =
          widget.autoScrollConfig?.enabled ??
          widget.streamingConfig?.autoScroll ??
          false;
      // If streamingController is null, assume followLatest behavior when autoScroll is enabled
      final isFollowingLatest =
          widget.streamingController?.viewportMode ==
              ViewportMode.followLatest ||
          widget.streamingController == null;
      final shouldUseWindowBounds =
          autoScrollEnabled &&
          isFollowingLatest &&
          _effectiveDataSeries.isNotEmpty;

      if (shouldUseWindowBounds) {
        // Calculate sliding window bounds using CONFIGURABLE NUMBER of recent points
        final allPoints = _effectiveDataSeries.expand((s) => s.points).toList();
        final windowSize =
            widget.autoScrollConfig?.maxVisiblePoints ??
            widget.streamingConfig?.autoScrollWindowSize ??
            150;
        // Removed excessive debugPrint (sliding window calculation)

        if (allPoints.isNotEmpty) {
          // Use last N points only (or all if less than N)
          final windowPoints = allPoints.length <= windowSize
              ? allPoints
              : allPoints.sublist(allPoints.length - windowSize);

          // Removed excessive debugPrint (window points count)

          if (windowPoints.isNotEmpty) {
            final minX = windowPoints
                .map((p) => p.x)
                .reduce((a, b) => a < b ? a : b);
            final maxX = windowPoints
                .map((p) => p.x)
                .reduce((a, b) => a > b ? a : b);
            final minY = windowPoints
                .map((p) => p.y)
                .reduce((a, b) => a < b ? a : b);
            final maxY = windowPoints
                .map((p) => p.y)
                .reduce((a, b) => a > b ? a : b);

            // Add 5% padding to window bounds for visual breathing room
            // (same as computeDataBounds does for non-streaming data)
            final xRange = maxX - minX;
            final yRange = maxY - minY;
            final xPadding = xRange * 0.05;
            final yPadding = yRange * 0.05;

            // Removed excessive print (window bounds)

            dataBounds = DataBounds(
              xMin: minX - xPadding,
              xMax: maxX + xPadding,
              yMin: minY - yPadding,
              yMax: maxY + yPadding,
            );
          } else {
            // Removed excessive print (no points in window)
            dataBounds = DataConverter.computeDataBounds(_effectiveDataSeries);
          }
        } else {
          // Removed excessive print (no points at all)
          dataBounds = const DataBounds(xMin: 0, xMax: 1, yMin: 0, yMax: 1);
        }
      } else {
        // Non-streaming, no auto-scroll, or explore mode: use all data
        dataBounds = DataConverter.computeDataBounds(_effectiveDataSeries);
      }
    }

    // CRITICAL: Ensure valid bounds before creating axes (prevent dataMax <= dataMin assertion)
    if (dataBounds.xMax <= dataBounds.xMin) {
      dataBounds = DataBounds(
        xMin: 0,
        xMax: 1,
        yMin: dataBounds.yMin,
        yMax: dataBounds.yMax,
      );
    }
    if (dataBounds.yMax <= dataBounds.yMin) {
      dataBounds = DataBounds(
        xMin: dataBounds.xMin,
        xMax: dataBounds.xMax,
        yMin: 0,
        yMax: 1,
      );
    }

    // Multi-axis normalization detection (FR-008, US2)
    // Check if series have vastly different Y-ranges that would benefit from normalization
    final seriesRanges = _computeSeriesYRanges(_effectiveDataSeries);
    final needsNormalization = NormalizationDetector.shouldNormalize(
      seriesRanges,
    );
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
    if (_effectiveNormalizationMode == NormalizationMode.perSeries &&
        _hasMultiAxisConfig) {
      dataBounds = DataBounds(
        xMin: dataBounds.xMin,
        xMax: dataBounds.xMax,
        yMin: -0.05, // 5% buffer below normalized range
        yMax: 1.05, // 5% buffer above normalized range
      );
    }

    // Create axes from data bounds using XAxisConfig/YAxisConfig
    final xAxisConfig = widget.xAxisConfig ?? const XAxisConfig();
    final yAxisConfigRaw =
        widget.yAxis ?? YAxisConfig(position: YAxisPosition.left, label: 'Y');

    _xAxis = chart_axis.Axis.fromXAxisConfig(
      config: xAxisConfig,
      dataMin: xAxisConfig.min ?? dataBounds.xMin,
      dataMax: xAxisConfig.max ?? dataBounds.xMax,
      labelFormatter: xAxisConfig.labelFormatter,
    );

    _yAxis = chart_axis.Axis.fromYAxisConfig(
      config: yAxisConfigRaw,
      dataMin: yAxisConfigRaw.min ?? dataBounds.yMin,
      dataMax: yAxisConfigRaw.max ?? dataBounds.yMax,
    );

    // Create element generator that renders series
    // This will be called by ChartRenderBox during zoom/pan to regenerate elements
    _elementGenerator = (ChartTransform transform) {
      // Removed excessive debugPrint (element generator executing)

      // Generate series elements from effective series (with streaming data)
      final elements = DataConverter.seriesToElements(
        series: _effectiveRenderSeries,
        transform: transform,
        theme: widget.theme,
        coordinator: _coordinator,
        focusedPointRefs: _focusedPointRefs,
        selectedPointRefs: _selectedPointRefs,
      ).cast<ChartElement>().toList();

      // Convert annotations to elements
      // Removed excessive debugPrints (annotation conversion details)
      // Use effective controller (user-provided or internal with static annotations)
      final effectiveAnnotations = _resolveEffectiveAnnotations();
      for (final annotation in effectiveAnnotations) {
        try {
          final ChartElement element = switch (annotation) {
            PointAnnotation() => PointAnnotationElement(
              annotation: annotation,
              series: widget.series.firstWhere(
                (s) => s.id == annotation.seriesId,
                orElse: () =>
                    throw StateError('Series ${annotation.seriesId} not found'),
              ),
              transform: transform,
            ),
            PinAnnotation() => PinAnnotationElement(
              annotation: annotation,
              transform: transform,
            ),
            RangeAnnotation() => RangeAnnotationElement(
              annotation: annotation,
              transform: transform,
              chartSize: Size(transform.plotWidth, transform.plotHeight),
            ),
            TextAnnotation() => TextAnnotationElement(annotation: annotation),
            ThresholdAnnotation() => ThresholdAnnotationElement(
              annotation: annotation,
              transform: transform,
            ),
            TrendAnnotation() => TrendAnnotationElement(
              annotation: annotation,
              series: widget.series.firstWhere(
                (s) => s.id == annotation.seriesId,
                orElse: () =>
                    throw StateError('Series ${annotation.seriesId} not found'),
              ),
              transform: transform,
            ),
            ChordAnnotation() => ChordAnnotationElement(
              annotation: annotation,
              series: widget.series.firstWhere(
                (s) => s.id == annotation.seriesId,
                orElse: () =>
                    throw StateError('Series ${annotation.seriesId} not found'),
              ),
              transform: transform,
            ),
            LegendAnnotation() => LegendAnnotationElement(
              annotation: annotation,
              chartSize: Size(transform.plotWidth, transform.plotHeight),
            ),
          };
          elements.add(element);

          // For resizable elements, also insert their resize handle elements
          if (element is ResizableElement && element.isResizable) {
            final handleElements = element
                .createResizeHandleElements()
                .cast<ChartElement>();
            elements.addAll(handleElements);
            // Removed excessive debugPrint (resize handles added)
          }
        } catch (_) {
          // Silently ignore annotation conversion errors to prevent chart crashes
          // This can occur when annotation references an invalid series or has malformed data
        }
      }

      // Auto-generate legend overlay if showLegend is true
      if (widget.showLegend && _effectiveRenderSeries.isNotEmpty) {
        // Use widget legendStyle if provided, otherwise fall back to theme's legendStyle
        final effectiveLegendStyle =
            widget.legendStyle ??
            widget.theme?.legendStyle ??
            const LegendStyle();

        // Collect trend annotations that have labels for display in the legend
        final trendAnnotations = effectiveAnnotations
            .whereType<TrendAnnotation>()
            .where((t) => t.label != null && t.label!.isNotEmpty)
            .toList();

        final legendAnnotation = LegendAnnotation(
          id: '__internal_legend__', // Special ID for internal legend
          series: _effectiveRenderSeries,
          trendAnnotations: trendAnnotations,
          legendStyle: effectiveLegendStyle,
          customPosition: _legendCustomPosition,
        );
        elements.add(
          LegendAnnotationElement(
            annotation: legendAnnotation,
            chartSize: Size(transform.plotWidth, transform.plotHeight),
          ),
        );
      }

      return elements;
    };

    // Increment version to signal that regeneration is needed
    _elementGeneratorVersion++;
  }

  void _handleIncomingDataAnimationTick() {
    if (!mounted || _incomingPointAnimations.isEmpty) {
      return;
    }

    setState(() {
      _refreshAnimatedRenderSeries();
      _elementGeneratorVersion++;
    });
  }

  void _handleIncomingDataAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }

    setState(() {
      _incomingPointAnimations.clear();
      _refreshAnimatedRenderSeries();
      _elementGeneratorVersion++;
    });
  }

  void _updateIncomingPointAnimations({
    required Map<String, ChartSeries> previousSeriesById,
    required List<ChartSeries> nextSeries,
  }) {
    _incomingPointAnimations.clear();

    if (!_shouldAnimateIncomingData) {
      _incomingDataAnimationController.stop();
      return;
    }

    for (final nextSeriesEntry in nextSeries) {
      final previousSeries = previousSeriesById[nextSeriesEntry.id];
      if (previousSeries == null) {
        continue;
      }

      final previousPoints = previousSeries.points;
      final nextPoints = nextSeriesEntry.points;
      if (nextPoints.length != previousPoints.length + 1 ||
          nextPoints.length < 2) {
        continue;
      }

      final previousTailPoint = previousPoints.last;
      final anchorPoint = nextPoints[nextPoints.length - 2];
      final nextTailPoint = nextPoints.last;
      if (previousTailPoint != anchorPoint) {
        continue;
      }

      _incomingPointAnimations[nextSeriesEntry.id] = _IncomingPointAnimation(
        anchorPoint: anchorPoint,
        targetPoint: nextTailPoint,
      );
    }

    if (_incomingPointAnimations.isEmpty) {
      _incomingDataAnimationController.stop();
      return;
    }

    final duration = _incomingDataAnimationDuration;
    if (_incomingDataAnimationController.duration != duration) {
      _incomingDataAnimationController.duration = duration;
    }

    _incomingDataAnimationController
      ..stop()
      ..value = 0
      ..forward();
  }

  void _refreshAnimatedRenderSeries() {
    if (_effectiveDataSeries.isEmpty || _incomingPointAnimations.isEmpty) {
      _effectiveRenderSeries = _effectiveDataSeries;
      return;
    }

    final progress = _incomingDataAnimationController.value;
    _effectiveRenderSeries = _effectiveDataSeries
        .map((series) {
          final animation = _incomingPointAnimations[series.id];
          if (animation == null || series.points.length < 2) {
            return series;
          }

          final animatedPoints = List<ChartDataPoint>.from(series.points);
          animatedPoints[animatedPoints.length - 1] = _interpolatePoint(
            animation.anchorPoint,
            animation.targetPoint,
            progress,
          );

          return switch (series) {
            LineChartSeries() => series.copyWith(points: animatedPoints),
            AreaChartSeries() => series.copyWith(points: animatedPoints),
            _ => series.copyWith(points: animatedPoints),
          };
        })
        .toList(growable: false);
  }

  ChartDataPoint _interpolatePoint(
    ChartDataPoint from,
    ChartDataPoint to,
    double t,
  ) {
    final clampedT = t.clamp(0.0, 1.0);
    return ChartDataPoint(
      x: from.x + ((to.x - from.x) * clampedT),
      y: from.y + ((to.y - from.y) * clampedT),
      timestamp: to.timestamp,
      label: to.label,
      metadata: to.metadata,
    );
  }

  void _onCoordinatorChanged() {
    // CRITICAL: Detect mode transitions to handle context menu
    if (_coordinator.currentMode == InteractionMode.contextMenuOpen &&
        mounted) {
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
    final isInRangeCreation =
        _coordinator.currentMode == InteractionMode.rangeAnnotationCreation;
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
    final renderBox =
        _renderBoxKey.currentContext?.findRenderObject() as RenderBox?;
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
    final bool isSeriesLineClick =
        element is SeriesElement && _coordinator.hoveredMarker == null;
    final bool isExistingAnnotation =
        element != null && element is! SeriesElement;

    // Check if annotations are supported (effective controller exists)
    final bool hasAnnotationController = _effectiveAnnotationController != null;

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

        // PinAnnotation - ALWAYS available (arbitrary position marker)
        const WebContextMenuAction(
          value: 'add_pin',
          icon: Icons.push_pin,
          label: 'Add Pin Annotation',
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

        // ChordAnnotation - ONLY when clicking on series line (not marker)
        if (isSeriesLineClick)
          const WebContextMenuAction(
            value: 'add_chord',
            icon: Icons.commit,
            label: 'Add Chord Annotation',
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

    // Show the web-native context menu
    final result = await WebContextMenu.show(
      context: context,
      position: globalPosition,
      items: menuItems,
    );

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
  Future<void> _handleMenuAction(
    String action,
    Offset localPosition,
    ChartElement? element,
  ) async {
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
      case 'add_chord':
        await _showAddChordAnnotationDialog(element);
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
    final renderBox =
        _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    double? initialX;
    double? initialY;

    if (renderBox != null) {
      final transform = renderBox.transform;
      if (transform != null) {
        final dataPos = transform.plotToData(
          localPosition.dx,
          localPosition.dy,
        );
        initialX = dataPos.dx;
        initialY = dataPos.dy;
      }
    }

    final result = await showDialog<PinAnnotation>(
      context: context,
      builder: (context) => PinAnnotationDialog(
        initialX: initialX,
        initialY: initialY,
        chartTheme: widget.theme,
      ),
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
      builder: (context) => PointAnnotationDialog(
        seriesId: markerInfo.seriesId,
        dataPointIndex: markerInfo.markerIndex,
        chartTheme: widget.theme,
      ),
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
    final renderBox =
        _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;

    double? initialXValue;
    double? initialYValue;

    if (localPosition != null && renderBox != null) {
      final transform = renderBox.transform;
      if (transform != null) {
        // Convert local plot position to data coordinates
        // In perSeries mode, this returns normalized Y (0-1)
        // The dialog will denormalize based on selected series
        final dataPos = transform.plotToData(
          localPosition.dx,
          localPosition.dy,
        );
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
        normalizationMode: _effectiveNormalizationMode,
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

  /// Called when user completes drag in rangeAnnotationCreation mode.
  /// Opens dialog with pre-filled coordinates from drag bounds.
  Future<void> _onRangeCreationComplete(
    double startX,
    double endX,
    double startY,
    double endY,
  ) async {
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
        normalizationMode: _effectiveNormalizationMode,
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
      builder: (context) => TrendAnnotationDialog(
        availableSeries: availableSeries,
        preselectedSeriesId: preselectedSeriesId,
      ),
    );

    if (result != null && mounted) {
      _effectiveAnnotationController?.addAnnotation(result);
    } else {}
  }

  /// Shows the ChordAnnotation creation dialog.
  Future<void> _showAddChordAnnotationDialog(ChartElement? element) async {
    if (!mounted) return;

    if (widget.series.isEmpty) return;

    final result = await showDialog<ChordAnnotation>(
      context: context,
      builder: (context) =>
          ChordAnnotationDialog(availableSeries: widget.series),
    );

    if (result != null && mounted) {
      _effectiveAnnotationController?.addAnnotation(result);
    }
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
            element is! ChordAnnotationElement &&
            element is! RangeAnnotationElement)) {
      return;
    }

    // Cast to annotation element types to access annotation field and route to dialog
    if (element is TextAnnotationElement) {
      final annotation = element.annotation;
      final result = await showDialog<TextAnnotation>(
        context: context,
        builder: (context) => TextAnnotationDialog(
          annotation: annotation,
          clickPosition: annotation.position,
        ),
      );

      if (result != null && mounted) {
        _effectiveAnnotationController?.updateAnnotation(annotation.id, result);
      } else {}
    } else if (element is PointAnnotationElement) {
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
        _effectiveAnnotationController?.updateAnnotation(annotation.id, result);
      } else {}
    } else if (element is PinAnnotationElement) {
      final annotation = element.annotation;
      final result = await showDialog<PinAnnotation>(
        context: context,
        builder: (context) => PinAnnotationDialog(
          annotation: annotation,
          initialX: annotation.x,
          initialY: annotation.y,
          chartTheme: widget.theme,
        ),
      );

      if (result != null && mounted) {
        _effectiveAnnotationController?.updateAnnotation(annotation.id, result);
      }
    } else if (element is ThresholdAnnotationElement) {
      final annotation = element.annotation;
      final result = await showDialog<ThresholdAnnotation>(
        context: context,
        builder: (context) => ThresholdAnnotationDialog(
          annotation: annotation,
          availableSeries: widget.series,
          normalizationMode: _effectiveNormalizationMode,
        ),
      );

      if (result != null && mounted) {
        _effectiveAnnotationController?.updateAnnotation(annotation.id, result);
      } else {}
    } else if (element is TrendAnnotationElement) {
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
        _effectiveAnnotationController?.updateAnnotation(annotation.id, result);
      } else {}
    } else if (element is ChordAnnotationElement) {
      final annotation = element.annotation;
      final result = await showDialog<ChordAnnotation>(
        context: context,
        builder: (context) => ChordAnnotationDialog(
          annotation: annotation,
          availableSeries: widget.series,
        ),
      );

      if (result != null && mounted) {
        _effectiveAnnotationController?.updateAnnotation(annotation.id, result);
      }
    } else if (element is RangeAnnotationElement) {
      final annotation = element.annotation;
      final result = await showDialog<RangeAnnotation>(
        context: context,
        builder: (context) => RangeAnnotationDialog(
          annotation: annotation,
          availableSeries: widget.series,
          normalizationMode: _effectiveNormalizationMode,
        ),
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
            element is! TrendAnnotationElement &&
            element is! ChordAnnotationElement)) {
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
    } else if (element is ChordAnnotationElement) {
      annotationId = element.annotation.id;
      annotationType = 'Chord Annotation';
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
      final wasRemoved =
          _effectiveAnnotationController?.removeAnnotation(annotationId) ??
          false;
      if (wasRemoved) {
      } else {}
    } else {}
  }

  void _handlePanStart(DragStartDetails details) {
    _pauseStreamingForViewportInteraction();

    // Request focus on pan start to enable keyboard controls
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
      // Removed excessive debugPrint (focus requested via pan start)
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final renderBox =
        _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    renderBox?.panChart(details.delta.dx, details.delta.dy);
  }

  void _handlePanEnd(DragEndDetails details) {
    _scheduleStreamingResumeIfNeeded();
  }

  void _handleTapDown(TapDownDetails details) {
    // Capture element at tap down for double-click detection
    // (activeElement gets cleared by tap up, so we need to capture it now)
    final tappedElement =
        _coordinator.activeElement ?? _coordinator.hoveredElement;

    // Check for double-click on annotation
    if (_lastTapTime != null &&
        _lastTappedElement != null &&
        tappedElement != null) {
      final now = DateTime.now();
      final timeDiff = now.difference(_lastTapTime!);

      if (tappedElement == _lastTappedElement &&
          timeDiff <= _doubleTapTimeout) {
        // Double-click detected!
        if (tappedElement is TextAnnotationElement ||
            tappedElement is PointAnnotationElement ||
            tappedElement is PinAnnotationElement ||
            tappedElement is ThresholdAnnotationElement ||
            tappedElement is TrendAnnotationElement ||
            tappedElement is ChordAnnotationElement ||
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

    // Trigger callbacks
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
      } else if (tappedElement is ChordAnnotationElement) {
        widget.onAnnotationTap?.call(tappedElement.annotation);
      } else if (tappedElement is SeriesElement) {
        // Check if a specific marker was tapped
        final marker = _coordinator.hoveredMarker;
        if (marker != null && marker.seriesId == tappedElement.series.id) {
          final point = tappedElement.series.points[marker.markerIndex];
          widget.onPointTap?.call(point, tappedElement.series.id);
        } else {
          _handleSeriesSelected(tappedElement.series.id);
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

  void _handleSeriesSelected(String seriesId) {
    if (_selectedSeriesId == seriesId) {
      _handleSeriesDeselected(seriesId);
      return;
    }
    _captureStateRevision++;
    _selectedSeriesId = seriesId;

    final renderBox =
        _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    final swapResult = renderBox?.applySeriesSelection(seriesId);

    if (swapResult != null) {
      widget.onAxisSwapped?.call(
        promotedAxisId: swapResult.promotedAxisId,
        demotedAxisId: swapResult.demotedAxisId,
      );
    }

    _syncControllerState(renderBox);
    widget.onSeriesSelected?.call(seriesId);
  }

  void _handleSeriesDeselected(String seriesId) {
    _captureStateRevision++;
    _selectedSeriesId = null;
    final renderBox =
        _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    renderBox?.clearSeriesSelection(seriesId);
    _syncControllerState(renderBox);
    widget.onSeriesDeselected?.call(seriesId);
  }

  void _setSeriesVisibility(String seriesId, bool visible) {
    final changed = visible
        ? _hiddenSeriesIds.remove(seriesId)
        : _hiddenSeriesIds.add(seriesId);
    if (!changed) return;
    _captureStateRevision++;
    setState(() => _rebuildElements());
    final renderBox =
        _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    _syncControllerState(renderBox);
  }

  void _restoreViewState(ChartViewState viewState) {
    _captureStateRevision++;
    setState(() {
      _hiddenSeriesIds
        ..clear()
        ..addAll(viewState.hiddenSeriesIds);
      _selectedSeriesId = viewState.selectedSeriesId;
      _selectedPointRefs
        ..clear()
        ..addAll(_validPointRefs(viewState.selectedPointRefs));
      _focusedPointRefs.clear();
      if (viewState.selectedAnnotationId != null &&
          _effectiveAnnotationController?.containsId(
                viewState.selectedAnnotationId!,
              ) ==
              true) {
        _effectiveAnnotationController?.selectAnnotation(
          viewState.selectedAnnotationId,
        );
      }
      _legendCustomPosition = viewState.legendPosition == null
          ? null
          : Offset(viewState.legendPosition!.x, viewState.legendPosition!.y);
      _rebuildElements();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderBox =
          _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
      final bounds = viewState.visibleBounds;
      if (bounds != null) {
        renderBox?.restoreVisibleDataBounds(
          xMin: bounds.xMin,
          xMax: bounds.xMax,
          yMin: bounds.yMin,
          yMax: bounds.yMax,
        );
      }
      renderBox?.restoreVisibleAxisIds(viewState.visibleAxisIds);
      if (viewState.selectedSeriesId != null) {
        renderBox?.applySeriesSelection(viewState.selectedSeriesId!);
      }
      _syncControllerState(renderBox);
      _syncControllerPointState();
    });
  }

  void _syncControllerState(ChartRenderBox? renderBox) {
    widget.bravenChartController?.updateSlotState(
      selectedSeriesId: _selectedSeriesId,
      visibleAxisIds: renderBox?.visibleAxisIds ?? const [],
      overflowAxisIds: renderBox?.overflowAxisIds ?? const [],
      hiddenSeriesIds: _hiddenSeriesIds,
    );
  }

  ChartArtifactResult<void> _focusPoints(
    Iterable<ChartPointRef> points,
    ChartDocumentRevision revision, {
    required bool reveal,
    required bool additive,
  }) {
    final validation = _validatePointCommand(points, revision);
    if (validation case ChartArtifactFailure<List<ChartPointRef>>()) {
      return ChartArtifactFailure(
        error: validation.error,
        warnings: validation.warnings,
      );
    }
    final refs =
        (validation as ChartArtifactSuccess<List<ChartPointRef>>).value;
    _focusedPointRefs
      ..clear()
      ..addAll(refs);
    _refreshLinkedPointRendering();
    _syncControllerPointState();
    if (reveal) _revealPoints(refs);
    return ChartArtifactSuccess(value: null);
  }

  ChartArtifactResult<void> _selectPoints(
    Iterable<ChartPointRef> points,
    ChartDocumentRevision revision, {
    required bool reveal,
    required bool additive,
  }) {
    final validation = _validatePointCommand(points, revision);
    if (validation case ChartArtifactFailure<List<ChartPointRef>>()) {
      return ChartArtifactFailure(
        error: validation.error,
        warnings: validation.warnings,
      );
    }
    final refs =
        (validation as ChartArtifactSuccess<List<ChartPointRef>>).value;
    final nextSelection = additive
        ? (<ChartPointRef>{..._selectedPointRefs, ...refs})
        : refs.toSet();
    if (setEquals(nextSelection, _selectedPointRefs)) {
      if (reveal) _revealPoints(refs);
      return ChartArtifactSuccess(value: null);
    }
    _selectedPointRefs
      ..clear()
      ..addAll(nextSelection);
    _captureStateRevision++;
    _refreshLinkedPointRendering();
    _syncControllerPointState();
    if (reveal) _revealPoints(refs);
    return ChartArtifactSuccess(value: null);
  }

  ChartArtifactResult<List<ChartPointRef>> _validatePointCommand(
    Iterable<ChartPointRef> points,
    ChartDocumentRevision revision,
  ) {
    if (revision != _effectiveDocumentRevision) {
      return ChartArtifactFailure(
        error: const ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.stalePointReference,
          message:
              'The point reference belongs to an older chart document revision.',
        ),
      );
    }
    final refs = points.toSet().toList(growable: false);
    final seriesById = {
      for (final series in _resolvedChartData.allSeries) series.id: series,
    };
    for (final ref in refs) {
      final series = seriesById[ref.seriesId];
      if (series == null ||
          ref.pointIndex < 0 ||
          ref.pointIndex >= series.points.length) {
        return ChartArtifactFailure(
          error: ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.invalidPointReference,
            message:
                'Point ${ref.seriesId}[${ref.pointIndex}] is not present in the effective chart document.',
          ),
        );
      }
    }
    return ChartArtifactSuccess(value: refs);
  }

  Iterable<ChartPointRef> _validPointRefs(Iterable<ChartPointRef> refs) {
    final seriesById = {
      for (final series in _resolvedChartData.allSeries) series.id: series,
    };
    return refs.where((ref) {
      final series = seriesById[ref.seriesId];
      return series != null &&
          ref.pointIndex >= 0 &&
          ref.pointIndex < series.points.length;
    });
  }

  void _pruneInvalidPointRefs() {
    final validFocus = _validPointRefs(_focusedPointRefs).toSet();
    final validSelection = _validPointRefs(_selectedPointRefs).toSet();
    if (validFocus.length == _focusedPointRefs.length &&
        validSelection.length == _selectedPointRefs.length) {
      return;
    }
    _focusedPointRefs
      ..clear()
      ..addAll(validFocus);
    _selectedPointRefs
      ..clear()
      ..addAll(validSelection);
    _syncControllerPointState();
  }

  void _clearPointFocus() {
    if (_focusedPointRefs.isEmpty) return;
    _focusedPointRefs.clear();
    _refreshLinkedPointRendering();
    _syncControllerPointState();
  }

  void _clearPointSelection() {
    if (_selectedPointRefs.isEmpty) return;
    _selectedPointRefs.clear();
    _captureStateRevision++;
    _refreshLinkedPointRendering();
    _syncControllerPointState();
  }

  void _refreshLinkedPointRendering() {
    if (!mounted) return;
    setState(() => _elementGeneratorVersion++);
  }

  void _syncControllerPointState() {
    widget.bravenChartController?.updatePointState(
      focusedPointRefs: _focusedPointRefs,
      selectedPointRefs: _selectedPointRefs,
    );
  }

  void _revealPoints(List<ChartPointRef> refs) {
    if (refs.isEmpty) return;
    final renderBox =
        _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    final transform = renderBox?.transform;
    if (renderBox == null || transform == null) return;
    final seriesById = {
      for (final series in _resolvedChartData.allSeries) series.id: series,
    };
    final chartPoints = [
      for (final ref in refs) seriesById[ref.seriesId]!.points[ref.pointIndex],
    ];
    var xMin = chartPoints.first.x;
    var xMax = chartPoints.first.x;
    for (final point in chartPoints.skip(1)) {
      xMin = math.min(xMin, point.x);
      xMax = math.max(xMax, point.x);
    }
    if (xMin >= transform.dataXMin && xMax <= transform.dataXMax) return;
    final currentSpan = transform.dataXMax - transform.dataXMin;
    final desiredSpan = math.max(currentSpan, (xMax - xMin) * 1.2);
    final center = (xMin + xMax) / 2;
    final nextMin = center - desiredSpan / 2;
    final nextMax = center + desiredSpan / 2;
    if (renderBox.restoreVisibleDataBounds(
      xMin: nextMin,
      xMax: nextMax,
      yMin: transform.dataYMin,
      yMax: transform.dataYMax,
    )) {
      _captureStateRevision++;
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
      final renderBox =
          _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
      // Removed excessive debugPrint (renderbox found)

      if (renderBox == null) return;

      // Cancel range annotation creation mode
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (_coordinator.currentMode ==
            InteractionMode.rangeAnnotationCreation) {
          _coordinator.releaseMode(force: true);
          setState(() {
            _currentCursor = SystemMouseCursors.basic;
          });
          return;
        }
      }
      // Reset view
      else if (event.logicalKey == LogicalKeyboardKey.home ||
          event.logicalKey == LogicalKeyboardKey.keyR) {
        _returnToLiveViewport(renderBox);
      }
      // Shift modifier for zoom
      else if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
          event.logicalKey == LogicalKeyboardKey.shiftRight) {
        // Removed excessive debugPrint (adding shift modifier)
        _coordinator.addModifierKey(LogicalKeyboardKey.shift);
      }
      // Arrow keys for panning
      else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        // Check if pan is enabled
        if (widget.interactionConfig?.enablePan ?? true) {
          _pauseStreamingForViewportInteraction();
          _coordinator.claimMode(InteractionMode.panning);
          renderBox.panChart(-20.0, 0.0);
          _scheduleStreamingResumeIfNeeded();
          _releaseModeLater();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        // Check if pan is enabled
        if (widget.interactionConfig?.enablePan ?? true) {
          _pauseStreamingForViewportInteraction();
          _coordinator.claimMode(InteractionMode.panning);
          renderBox.panChart(20.0, 0.0);
          _scheduleStreamingResumeIfNeeded();
          _releaseModeLater();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        // Check if pan is enabled
        if (widget.interactionConfig?.enablePan ?? true) {
          _pauseStreamingForViewportInteraction();
          _coordinator.claimMode(InteractionMode.panning);
          renderBox.panChart(0.0, -20.0);
          _scheduleStreamingResumeIfNeeded();
          _releaseModeLater();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        // Check if pan is enabled
        if (widget.interactionConfig?.enablePan ?? true) {
          _pauseStreamingForViewportInteraction();
          _coordinator.claimMode(InteractionMode.panning);
          renderBox.panChart(0.0, 20.0);
          _scheduleStreamingResumeIfNeeded();
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
          _pauseStreamingForViewportInteraction();
          _coordinator.claimMode(InteractionMode.zooming);
          renderBox.zoomChart(1.0 + (config.keyboardZoomPercent / 100.0));
          _scheduleStreamingResumeIfNeeded();
          _releaseModeLater();
        }
      }
      // Zoom out with - or numpad -
      else if (event.logicalKey == LogicalKeyboardKey.minus ||
          event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
        // Check if zoom is enabled
        final config = widget.interactionConfig ?? const InteractionConfig();
        if (config.enableZoom) {
          _pauseStreamingForViewportInteraction();
          _coordinator.claimMode(InteractionMode.zooming);
          renderBox.zoomChart(1.0 - (config.keyboardZoomPercent / 100.0));
          _scheduleStreamingResumeIfNeeded();
          _releaseModeLater();
        }
      }
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
          event.logicalKey == LogicalKeyboardKey.shiftRight) {
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

    final renderBox =
        _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
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
        final seriesId = widget.series.isNotEmpty
            ? widget.series.first.id
            : 'stream';

        // Add to controller - this will trigger _onControllerUpdate -> setState -> rebuild
        // No conversion needed - both use src_plus ChartDataPoint now
        widget.controller!.addPoint(seriesId, point);

        // Auto-scroll if enabled
        final autoScrollEnabled =
            widget.autoScrollConfig?.enabled ?? config.autoScroll;
        if (autoScrollEnabled) {
          setState(() {
            _autoScrollToLatest();
          });
        }
      } else {
        // Legacy path: Add point to streaming data list
        setState(() {
          _captureStateRevision++;
          _streamingDataPoints.add(point);
          _rebuildElements();

          // Auto-scroll if enabled
          final autoScrollEnabled =
              widget.autoScrollConfig?.enabled ?? config.autoScroll;
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
      _lockedPausedBounds = DataBounds(
        xMin: _xAxis!.dataMin,
        xMax: _xAxis!.dataMax,
        yMin: _yAxis!.dataMin,
        yMax: _yAxis!.dataMax,
      );
    }

    // STEP 2: Set pan constraints to full dataset bounds (Option 4)
    final renderBox =
        _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    if (renderBox != null && _cachedDataXMin != null) {
      final constrainedYMin = _usesPerSeriesNormalizedMultiAxis
          ? (_yAxis?.dataMin ?? -0.05)
          : _cachedDataYMin!;
      final constrainedYMax = _usesPerSeriesNormalizedMultiAxis
          ? (_yAxis?.dataMax ?? 1.05)
          : _cachedDataYMax!;

      renderBox.setPanConstraintBounds(
        _cachedDataXMin!,
        _cachedDataXMax!,
        constrainedYMin,
        constrainedYMax,
      );
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
    final renderBox =
        _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
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
      final seriesId = widget.series.isNotEmpty
          ? widget.series.first.id
          : 'stream';

      for (final point in bufferedPoints) {
        // No conversion needed - both use src_plus ChartDataPoint now
        widget.controller!.addPoint(seriesId, point);
      }
      // Controller will trigger _onControllerUpdate -> setState -> rebuild
    } else {
      // Legacy path
      setState(() {
        _captureStateRevision++;
        _streamingDataPoints.addAll(bufferedPoints);
        _rebuildElements();
      });
    }

    // Auto-scroll and notify regardless of path
    final config = widget.streamingConfig ?? const StreamingConfig();
    final autoScrollEnabled =
        widget.autoScrollConfig?.enabled ?? config.autoScroll;
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
      final seriesId = widget.series.isNotEmpty
          ? widget.series.first.id
          : 'stream';
      widget.controller!.clearSeries(seriesId);
      // Controller will trigger _onControllerUpdate -> setState -> rebuild
    } else {
      // Legacy path
      setState(() {
        _captureStateRevision++;
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
    _cachedDataXMin = _cachedDataXMin == null
        ? x
        : (_cachedDataXMin! < x ? _cachedDataXMin! : x);
    _cachedDataXMax = _cachedDataXMax == null
        ? x
        : (_cachedDataXMax! > x ? _cachedDataXMax! : x);
    _cachedDataYMin = _cachedDataYMin == null
        ? y
        : (_cachedDataYMin! < y ? _cachedDataYMin! : y);
    _cachedDataYMax = _cachedDataYMax == null
        ? y
        : (_cachedDataYMax! > y ? _cachedDataYMax! : y);
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
    // Live follow mode is now driven by the rebuild-time sliding window bounds.
    // Applying an extra pixel pan here causes compounded drift after zoom/reset.
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

      final renderBox =
          _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
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

  Widget _buildViewportContent(Widget chartContent) {
    final Widget content;
    if (widget.isLoading) {
      content = ChartLoadingStateView(
        key: const ValueKey<String>('braven_chart_loading_state'),
        config: widget.loadingConfig,
        loadingWidget: widget.loadingWidget,
        chartTheme: widget.theme,
      );
    } else {
      final hasData = _effectiveDataSeries.any(
        (series) => series.points.any((point) => point.isValid),
      );
      final mustKeepRenderBoxMounted = widget.liveStreamController != null;
      if (!hasData && !mustKeepRenderBoxMounted) {
        content = ChartEmptyStateView(
          key: const ValueKey<String>('braven_chart_empty_state'),
          config: widget.emptyStateConfig,
        );
      } else {
        content = chartContent;
      }
    }

    if (identical(content, chartContent)) {
      return chartContent;
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ColoredBox(
        color: widget.theme?.backgroundColor ?? widget.backgroundColor,
        child: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Disable browser context menu on web platform
    if (kIsWeb) {
      BrowserContextMenu.disableContextMenu();
    }

    final Widget renderedChart = Focus(
      focusNode: _focusNode,
      autofocus: false,
      onKeyEvent: (node, event) {
        _handleKeyEvent(event);
        return KeyEventResult.handled;
      },
      child: Builder(
        builder: (context) {
          final hasFocus = _focusNode.hasFocus;
          final enableFocusOnHover =
              widget.interactionConfig?.enableFocusOnHover ?? true;
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
              (_renderBoxKey.currentContext?.findRenderObject()
                      as ChartRenderBox?)
                  ?.clearCursorPosition();
            },
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                border:
                    (widget.interactionConfig?.showFocusBorder ?? false) &&
                        hasFocus
                    ? Border.all(
                        color: widget.theme?.focusBorderColor ?? Colors.blue,
                        width: widget.theme?.focusBorderWidth ?? 2.0,
                      )
                    : null,
                borderRadius:
                    (widget.interactionConfig?.showFocusBorder ?? false) &&
                        hasFocus &&
                        (widget.theme?.focusBorderRadius ?? 0.0) > 0
                    ? BorderRadius.circular(
                        widget.theme?.focusBorderRadius ?? 0.0,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  MouseRegion(
                    cursor:
                        _coordinator.currentMode ==
                            InteractionMode.rangeAnnotationCreation
                        ? SystemMouseCursors
                              .precise // Precise crosshair cursor for range selection
                        : _currentCursor,
                    child: RawGestureDetector(
                      gestures: {
                        PriorityPanGestureRecognizer:
                            GestureRecognizerFactoryWithHandlers<
                              PriorityPanGestureRecognizer
                            >(() => _panRecognizer, (recognizer) {}),
                        PriorityTapGestureRecognizer:
                            GestureRecognizerFactoryWithHandlers<
                              PriorityTapGestureRecognizer
                            >(() => _tapRecognizer, (recognizer) {}),
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
                        tooltipsEnabled:
                            widget.interactionConfig?.tooltip.enabled ?? true,
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
                        onViewportInteracted: _handleViewportInteractionPulse,
                        gridConfig: widget.grid,
                        // Multi-axis parameters
                        normalizationMode: _effectiveNormalizationMode,
                        series: _effectiveRenderSeries,
                        maxAxesPerSide: widget.maxAxesPerSide,
                        axisSwapMode: widget.axisSwapMode,
                      ),
                    ),
                  ),
                  if (widget.showDebugInfo)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _DebugOverlay(coordinator: _coordinator),
                    ),
                  // Range creation mode instruction overlay
                  if (_coordinator.currentMode ==
                      InteractionMode.rangeAnnotationCreation)
                    Positioned(
                      top: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xE6448AFF), // Semi-opaque blue
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(51),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Range Creation Mode: Drag to select region • ESC to cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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

    final chartContent = _buildViewportContent(renderedChart);

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

      // Legacy ChartLegend widget removed - overlay legend (LegendAnnotation)
      // is now used exclusively for legend rendering within the chart area.

      return RepaintBoundary(
        key: _previewBoundaryKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );
    }

    return RepaintBoundary(key: _previewBoundaryKey, child: chartContent);
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
    this.onViewportInteracted,
    // Multi-axis parameters
    this.normalizationMode,
    this.series,
    this.gridConfig,
    required this.maxAxesPerSide,
    required this.axisSwapMode,
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

  /// Grid configuration for controlling grid line visibility and styling.
  final GridConfig? gridConfig;
  final bool tooltipsEnabled;
  final bool showXScrollbar;
  final bool showYScrollbar;
  final ScrollbarConfig? scrollbarTheme;
  final InteractionConfig? interactionConfig;
  final void Function(MouseCursor cursor)? onCursorChange;
  final void Function(String annotationId, ChartAnnotation updatedAnnotation)?
  onAnnotationChanged;
  final void Function(ChartElement? element)? onElementHover;
  final void Function(double startX, double endX, double startY, double endY)?
  onRangeCreationComplete;
  final VoidCallback? onViewportInteracted;
  // Multi-axis fields
  final NormalizationMode? normalizationMode;
  final List<ChartSeries>? series;
  final int maxAxesPerSide;
  final AxisSwapMode axisSwapMode;

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
        onViewportInteracted: onViewportInteracted,
      )
      ..setXAxis(xAxis)
      ..setXAxisConfig(xAxisConfig)
      ..setYAxis(yAxis)
      ..setPrimaryYAxisConfig(primaryYAxisConfig)
      ..setGridConfig(gridConfig)
      ..setMaxAxesPerSide(maxAxesPerSide)
      ..setAxisSwapMode(axisSwapMode);
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
      ..setMaxAxesPerSide(maxAxesPerSide)
      ..setAxisSwapMode(axisSwapMode)
      ..setGridConfig(gridConfig)
      ..onViewportInteracted = onViewportInteracted
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
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(179),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mode: ${coordinator.currentMode.name}'),
            Text('Selected: ${coordinator.selectedElements.length}'),
            if (coordinator.activeElement != null)
              Text('Active: ${coordinator.activeElement!.id}'),
          ],
        ),
      ),
    );
  }
}

class _IncomingPointAnimation {
  const _IncomingPointAnimation({
    required this.anchorPoint,
    required this.targetPoint,
  });

  final ChartDataPoint anchorPoint;
  final ChartDataPoint targetPoint;
}

class _ChartEffectiveRevisionToken {
  const _ChartEffectiveRevisionToken({
    required this.stateRevision,
    required this.controllerRevision,
    required this.annotationRevision,
    required this.liveCommittedRevision,
    required this.livePendingRevision,
    required this.livePendingPointCount,
    required this.viewStateHash,
  });

  final int stateRevision;
  final int controllerRevision;
  final int annotationRevision;
  final int liveCommittedRevision;
  final int livePendingRevision;
  final int livePendingPointCount;
  final int viewStateHash;

  @override
  bool operator ==(Object other) =>
      other is _ChartEffectiveRevisionToken &&
      stateRevision == other.stateRevision &&
      controllerRevision == other.controllerRevision &&
      annotationRevision == other.annotationRevision &&
      liveCommittedRevision == other.liveCommittedRevision &&
      livePendingRevision == other.livePendingRevision &&
      livePendingPointCount == other.livePendingPointCount &&
      viewStateHash == other.viewStateHash;

  @override
  int get hashCode => Object.hash(
    stateRevision,
    controllerRevision,
    annotationRevision,
    liveCommittedRevision,
    livePendingRevision,
    livePendingPointCount,
    viewStateHash,
  );
}

class _ChartCaptureRevisionToken {
  const _ChartCaptureRevisionToken({
    required this.effectiveRevision,
    required this.optionsKey,
  });

  final _ChartEffectiveRevisionToken effectiveRevision;
  final String optionsKey;

  @override
  bool operator ==(Object other) =>
      other is _ChartCaptureRevisionToken &&
      effectiveRevision == other.effectiveRevision &&
      optionsKey == other.optionsKey;

  @override
  int get hashCode => Object.hash(effectiveRevision, optionsKey);
}
