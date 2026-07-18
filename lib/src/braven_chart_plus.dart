// Copyright (c) 2025 braven_charts. All rights reserved.
// BravenChartPlus - Integration of Prototype Interaction System
// NO REFERENCES TO lib/src - COMPLETELY ISOLATED

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb, listEquals, setEquals;
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
import 'elements/pie_series_element.dart';
import 'elements/series_element.dart';
import 'interaction/core/chart_element.dart';
import 'interaction/core/coordinator.dart';
import 'interaction/core/data_hit.dart';
import 'interaction/core/interaction_mode.dart';
import 'interaction/recognizers/priority_pan_recognizer.dart';
import 'interaction/recognizers/priority_tap_recognizer.dart';
import 'layout/chart_layout_kind.dart';
import 'models/auto_scroll_config.dart';
import 'models/axis_swap_mode.dart';
import 'models/bar_chart_style.dart';
import 'models/braven_chart_controller.dart';
import 'models/chart_annotation.dart';
import 'models/chart_data_point.dart';
import 'models/chart_series.dart';
import 'models/chart_state_config.dart';
import 'models/chart_theme.dart';
import 'models/chart_type.dart';
import 'models/data_range.dart';
import 'models/donut_center_builder.dart';
import 'models/donut_chart_series.dart';
import 'models/enums.dart';
import 'models/grid_config.dart';
import 'models/interaction_config.dart';
import 'models/legend_style.dart';
import 'models/pie_chart_series.dart';
import 'models/pie_chart_config.dart';
import 'models/path_animation_style.dart';
import 'models/radial_category_series.dart';
import 'models/radial_legend_item.dart';
import 'models/streaming_config.dart';
import 'models/x_axis_config.dart';
import 'rendering/chart_render_box.dart';
import 'rendering/spatial_index.dart';
import 'streaming/buffer_manager.dart';
import 'streaming/live_stream_controller.dart';
import 'streaming/streaming_controller.dart';
import 'source/chart_source_capture_adapter.dart';
import 'theming/components/scrollbar_config.dart';
import 'utils/data_converter.dart';
import 'utils/bar_series_transition.dart';
import 'utils/radial_series_transition.dart';
import 'utils/path_animation_timeline.dart';
import 'utils/path_series_transition.dart';
import 'widgets/dialogs/pin_annotation_dialog.dart';
import 'widgets/dialogs/chord_annotation_dialog.dart';
import 'widgets/dialogs/point_annotation_dialog.dart';
import 'widgets/dialogs/range_annotation_dialog.dart';
import 'widgets/dialogs/text_annotation_dialog.dart';
import 'widgets/dialogs/threshold_annotation_dialog.dart';
import 'widgets/dialogs/trend_annotation_dialog.dart';
import 'widgets/chart_state_view.dart';
import 'widgets/pie_chart_legend.dart';
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
    this.radialLegendItemBuilder,
    this.donutCenterBuilder,
    this.onDonutCenterTap,
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

  /// Creates a Cartesian chart from a simple list of y-values.
  ///
  /// Supports line, area, bar, and scatter. Pie and Donut are rejected because
  /// numeric values alone cannot provide the required accessible category
  /// labels; use their `fromMap` series factories with the primary constructor.
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
    RadialLegendItemBuilder? radialLegendItemBuilder,
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
    if (chartType == ChartType.pie) {
      throw ArgumentError(
        'BravenChartPlus.fromValues cannot infer pie category labels. '
        'Use PieChartSeries.fromMap with BravenChartPlus instead.',
      );
    }
    if (chartType == ChartType.donut) {
      throw ArgumentError(
        'BravenChartPlus.fromValues cannot infer donut category labels. '
        'Use DonutChartSeries.fromMap with BravenChartPlus instead.',
      );
    }

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

    final series = _createSeriesForType(
      chartType: chartType,
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
      radialLegendItemBuilder: radialLegendItemBuilder,
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

  /// Creates a chart from a map.
  ///
  /// For Cartesian chart types, keys must be numbers or numeric strings and
  /// are interpreted as X values. For [ChartType.pie] and [ChartType.donut],
  /// keys become category labels and map insertion order becomes stable slice
  /// order.
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
    RadialLegendItemBuilder? radialLegendItemBuilder,
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
    final ChartSeries series;
    if (chartType == ChartType.pie || chartType == ChartType.donut) {
      final values = <String, num>{
        for (final entry in data.entries) entry.key.toString(): entry.value,
      };
      series = switch (chartType) {
        ChartType.pie => PieChartSeries.fromMap(
          id: seriesId,
          name: seriesName ?? seriesId,
          values: values,
          color: seriesColor,
        ),
        ChartType.donut => DonutChartSeries.fromMap(
          id: seriesId,
          name: seriesName ?? seriesId,
          values: values,
          color: seriesColor,
        ),
        _ => throw StateError('Unreachable radial chart type'),
      };
    } else {
      final points = data.entries.map((entry) {
        final x = switch (entry.key) {
          final int v => v.toDouble(),
          final double v => v,
          final String v => double.parse(v),
          _ => throw ArgumentError(
            'Map keys must be numeric or numeric strings',
          ),
        };
        return ChartDataPoint(x: x, y: entry.value);
      }).toList();
      series = _createSeriesForType(
        chartType: chartType,
        id: seriesId,
        name: seriesName ?? seriesId,
        points: points,
        color: seriesColor ?? Colors.blue,
        interpolation: interpolation,
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
      radialLegendItemBuilder: radialLegendItemBuilder,
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

  /// Creates a chart from a JSON array of point objects.
  ///
  /// Every object requires numeric `x` and `y` fields. Pie points also require
  /// a non-empty `label`; pie validation runs when the series is constructed.
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
    RadialLegendItemBuilder? radialLegendItemBuilder,
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

    final series = _createSeriesForType(
      chartType: chartType,
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
      radialLegendItemBuilder: radialLegendItemBuilder,
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

  static ChartSeries _createSeriesForType({
    required ChartType chartType,
    required String id,
    required String name,
    required List<ChartDataPoint> points,
    required Color color,
    required LineInterpolation interpolation,
  }) {
    return switch (chartType) {
      ChartType.line => LineChartSeries(
        id: id,
        name: name,
        points: points,
        color: color,
        interpolation: interpolation,
      ),
      ChartType.area => AreaChartSeries(
        id: id,
        name: name,
        points: points,
        color: color,
        interpolation: interpolation,
      ),
      ChartType.bar => BarChartSeries(
        id: id,
        name: name,
        points: points,
        color: color,
        barWidthPercent: 0.8,
      ),
      ChartType.scatter => ScatterChartSeries(
        id: id,
        name: name,
        points: points,
        color: color,
      ),
      ChartType.pie => PieChartSeries(
        id: id,
        name: name,
        points: points,
        color: color,
      ),
      ChartType.donut => DonutChartSeries(
        id: id,
        name: name,
        points: points,
        color: color,
      ),
    };
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
  /// Cartesian charts use their series legend. Pie and Donut charts use a
  /// native, slice-aware Flutter widget legend that selects slices without
  /// hiding data.
  final bool showLegend;

  /// Optional per-chart style for the Cartesian overlay legend.
  ///
  /// Radial widget legends resolve [LegendStyle] through
  /// [ChartTheme.legendStyle] so their position and appearance remain part of
  /// the portable chart theme. Use [radialLegendItemBuilder] only when the
  /// host needs custom runtime item widgets.
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

  /// Builds the visible contents of each Pie or Donut legend item.
  ///
  /// Braven Charts keeps the legend layout, tap target, selection action, and
  /// assistive semantics around the returned widget. The builder receives the
  /// resolved slice color, value, share, source points, and selection state.
  /// It is ignored for Cartesian series.
  ///
  /// This is a runtime-only binding. Widget builders are not serialized into
  /// chart artifacts; portable documents retain legend visibility, style, and
  /// data, and the hydrating host must bind the builder again.
  final RadialLegendItemBuilder? radialLegendItemBuilder;

  /// Builds runtime-only content inside a Donut chart's shared center opening.
  ///
  /// Braven Charts retains the circular clip, measured constraints, selection
  /// data, tap shell, and assistive semantics. The portable
  /// [DonutChartSeries.centerContent] remains the artifact and preview fallback
  /// and is restored when this builder is not rebound after hydration. The
  /// builder is active only while that portable center content is visible.
  final DonutCenterBuilder? donutCenterBuilder;

  /// Called when the package-owned Donut center shell is activated.
  ///
  /// The callback runs for pointer, keyboard, and assistive activation and
  /// receives the same immutable data supplied to [donutCenterBuilder]. It is
  /// runtime-only and must be rebound after artifact hydration.
  final DonutCenterTapCallback? onDonutCenterTap;

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
    with TickerProviderStateMixin {
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

  ChartLayoutKind _layoutKind = ChartLayoutKind.cartesian;
  double _textScaleFactor = 1;
  bool _disableAnimations = false;
  int? _radialKeyboardFocusIndex;
  bool _radialFocusIndicatorVisible = false;

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
  final Map<String, _ActiveBarSeriesTransition> _barSeriesTransitions =
      <String, _ActiveBarSeriesTransition>{};
  _ActiveRadialSeriesTransition? _radialSeriesTransition;
  final Map<String, _ActivePathSeriesTransition> _pathSeriesTransitions =
      <String, _ActivePathSeriesTransition>{};
  final Map<String, PathSeriesPointMap> _pathPointMapsBySeries =
      <String, PathSeriesPointMap>{};
  final Map<String, PathAnimationWindow> _pathRevealWindows =
      <String, PathAnimationWindow>{};
  Duration _pathDataTimelineDuration = Duration.zero;
  Duration _pathRevealTimelineDuration = Duration.zero;
  late final AnimationController _incomingDataAnimationController;
  late final AnimationController _barDataAnimationController;
  late final AnimationController _pathDataAnimationController;
  late final AnimationController _pathRevealAnimationController;
  late final AnimationController _radialRevealAnimationController;
  late final AnimationController _radialDataAnimationController;
  late final AnimationController _radialSelectionAnimationController;

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
    _barDataAnimationController = AnimationController(vsync: this, value: 1)
      ..addListener(_handleBarDataAnimationTick)
      ..addStatusListener(_handleBarDataAnimationStatus);
    _pathDataAnimationController = AnimationController(vsync: this, value: 1)
      ..addListener(_handlePathDataAnimationTick)
      ..addStatusListener(_handlePathDataAnimationStatus);
    _pathRevealAnimationController = AnimationController(vsync: this, value: 1)
      ..addListener(_handlePathRevealAnimationTick)
      ..addStatusListener(_handlePathRevealAnimationStatus);
    _radialRevealAnimationController = AnimationController(
      vsync: this,
      value: 1,
    )..addListener(_handleRadialAnimationTick);
    _radialDataAnimationController = AnimationController(vsync: this, value: 1)
      ..addListener(_handleRadialDataAnimationTick)
      ..addStatusListener(_handleRadialDataAnimationStatus);
    _radialSelectionAnimationController = AnimationController(
      vsync: this,
      value: 1,
    )..addListener(_handleRadialAnimationTick);

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
    _startBarEntranceAnimation();
    _startPathEntranceAnimation();
    _startRadialRevealAnimation();

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
      onExtractSourceDocument: _extractSourceDocument,
      onRestoreViewState: _restoreViewState,
      onCapturePreview: _capturePreview,
      onFocusPoints: _focusPoints,
      onSelectPoints: _selectPoints,
      onClearPointFocus: _clearPointFocus,
      onClearPointSelection: _clearPointSelection,
      onReplayRadialEntrance: _startRadialRevealAnimation,
      onReplaySeriesEntrance: _replaySeriesEntrance,
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextTextScale = MediaQuery.maybeOf(context)?.textScaler.scale(1) ?? 1;
    final nextDisableAnimations = MediaQuery.disableAnimationsOf(context);
    if (nextTextScale != _textScaleFactor ||
        nextDisableAnimations != _disableAnimations) {
      _textScaleFactor = nextTextScale;
      _disableAnimations = nextDisableAnimations;
      if (_disableAnimations) {
        _barDataAnimationController
          ..stop()
          ..value = 1;
        _barSeriesTransitions.clear();
        _finishPathAnimationsImmediately();
        _radialRevealAnimationController
          ..stop()
          ..value = 1;
        _radialDataAnimationController
          ..stop()
          ..value = 1;
        _radialSeriesTransition = null;
        _radialSelectionAnimationController
          ..stop()
          ..value = 1;
      }
      _refreshAnimatedRenderSeries();
      _rebuildElements();
    }
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
        onExtractSourceDocument: _extractSourceDocument,
        onRestoreViewState: _restoreViewState,
        onCapturePreview: _capturePreview,
        onFocusPoints: _focusPoints,
        onSelectPoints: _selectPoints,
        onClearPointFocus: _clearPointFocus,
        onClearPointSelection: _clearPointSelection,
        onReplayRadialEntrance: _startRadialRevealAnimation,
        onReplaySeriesEntrance: _replaySeriesEntrance,
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

    final seriesChanged = !listEquals(widget.series, oldWidget.series);
    if (_pathAnimationDuration == Duration.zero) {
      _finishPathAnimationsImmediately();
    }
    final radialDataChanged = _radialDataChanged(
      oldWidget.series,
      widget.series,
    );
    final radialAnimationModeChanged = _radialAnimationModeChanged(
      previous: oldWidget.series,
      next: widget.series,
      previousTheme: oldWidget.theme ?? ChartTheme.light,
      nextTheme: widget.theme ?? ChartTheme.light,
    );
    final radialCenterRuntimeChanged =
        widget.donutCenterBuilder != oldWidget.donutCenterBuilder ||
        widget.onDonutCenterTap != oldWidget.onDonutCenterTap;
    if (radialDataChanged) {
      _remapRadialPointState(oldWidget.series, widget.series);
    }
    if (seriesChanged ||
        widget.theme != oldWidget.theme ||
        widget.annotations != oldWidget.annotations ||
        radialCenterRuntimeChanged) {
      // Removed excessive debugPrint (theme/series/annotations changed)
      _rebuildElements(
        detectBarAnimations: seriesChanged,
        detectPathAnimations: seriesChanged,
        detectRadialAnimations:
            radialDataChanged && !radialAnimationModeChanged,
      );
      if (radialAnimationModeChanged) {
        _startRadialRevealAnimation();
      }
      // Focus will be acquired on next mouse enter — no need to grab it here.
      // Previously this called requestFocus() which caused 21 charts to fight
      // for focus on gallery page load, contributing to startup lag.
    }
  }

  /// Called when focus state changes.
  void _onFocusChanged() {
    final hideRadialFocus =
        !_focusNode.hasFocus && _radialFocusIndicatorVisible;
    // Only trigger rebuild when focus border is actually displayed.
    // Without this guard, every focus change triggers setState on ALL charts,
    // causing cascading rebuilds with 21+ charts on the gallery page.
    if ((widget.interactionConfig?.showFocusBorder ?? false) ||
        hideRadialFocus) {
      setState(() {
        if (hideRadialFocus) {
          _radialFocusIndicatorVisible = false;
          _elementGeneratorVersion++;
        }
      });
    }
  }

  @override
  void dispose() {
    _incomingDataAnimationController
      ..removeListener(_handleIncomingDataAnimationTick)
      ..removeStatusListener(_handleIncomingDataAnimationStatus)
      ..dispose();
    _barDataAnimationController
      ..removeListener(_handleBarDataAnimationTick)
      ..removeStatusListener(_handleBarDataAnimationStatus)
      ..dispose();
    _pathDataAnimationController
      ..removeListener(_handlePathDataAnimationTick)
      ..removeStatusListener(_handlePathDataAnimationStatus)
      ..dispose();
    _pathRevealAnimationController
      ..removeListener(_handlePathRevealAnimationTick)
      ..removeStatusListener(_handlePathRevealAnimationStatus)
      ..dispose();
    _radialRevealAnimationController
      ..removeListener(_handleRadialAnimationTick)
      ..dispose();
    _radialDataAnimationController
      ..removeListener(_handleRadialDataAnimationTick)
      ..removeStatusListener(_handleRadialDataAnimationStatus)
      ..dispose();
    _radialSelectionAnimationController
      ..removeListener(_handleRadialAnimationTick)
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
  ) => _extractDocumentInternal(options, forSource: false);

  ChartArtifactResult<ChartDocumentSnapshot> _extractSourceDocument(
    ChartDocumentExtractOptions options,
  ) => _extractDocumentInternal(options, forSource: true);

  ChartArtifactResult<ChartDocumentSnapshot> _extractDocumentInternal(
    ChartDocumentExtractOptions options, {
    required bool forSource,
  }) {
    for (var attempt = 0; attempt < options.maxSnapshotAttempts; attempt++) {
      final initialCapture = forSource
          ? ChartSourceCaptureAdapter.adapt(
              source: _buildDocumentExtractionSource(),
              options: options,
            )
          : ChartSourceCaptureRequest(
              source: _buildDocumentExtractionSource(),
              options: options,
            );
      final before = _captureRevisionToken(initialCapture.options);
      final nextRevision =
          _lastDocumentRevisionToken == null ||
              _lastDocumentRevisionToken == before
          ? _documentRevision
          : _documentRevision + 1;
      final effectiveRevision = _publishEffectiveDocumentRevision(
        before.effectiveRevision,
      );
      final capture = forSource
          ? ChartSourceCaptureAdapter.adapt(
              source: _buildDocumentExtractionSource(),
              options: options,
            )
          : ChartSourceCaptureRequest(
              source: _buildDocumentExtractionSource(),
              options: options,
            );
      final assembled = ChartDocumentExtractor.extract(
        source: capture.source,
        options: capture.options,
        revision: nextRevision,
        effectiveRevision: effectiveRevision,
      );
      if (assembled is ChartArtifactFailure<ChartDocumentSnapshot>) {
        return ChartArtifactFailure(
          error: assembled.error,
          warnings: [...capture.warnings, ...assembled.warnings],
        );
      }
      final after = _captureRevisionToken(capture.options);
      if (before != after) continue;

      _lastDocumentRevisionToken = after;
      _documentRevision = nextRevision;
      final success = assembled as ChartArtifactSuccess<ChartDocumentSnapshot>;
      return ChartArtifactSuccess(
        value: success.value,
        warnings: [...capture.warnings, ...success.warnings],
      );
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

  ChartDocumentExtractionSource _buildDocumentExtractionSource() {
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

    return ChartDocumentExtractionSource(
      allSeries: resolved.allSeries,
      visibleSeries: resolved.visibleSeries,
      declaredSeries: widget.series,
      annotations: _resolveEffectiveAnnotations(),
      xAxis: widget.xAxisConfig ?? const XAxisConfig(),
      axes: axisModels,
      theme: effectiveTheme,
      interaction: baseInteraction.copyWith(
        showXScrollbar: widget.showXScrollbar || baseInteraction.showXScrollbar,
        showYScrollbar: widget.showYScrollbar || baseInteraction.showYScrollbar,
      ),
      legendVisible: widget.showLegend,
      legendStyle: widget.legendStyle ?? effectiveTheme.legendStyle,
      grid: widget.grid ?? const GridConfig(),
      normalizationMode: _effectiveNormalizationMode ?? NormalizationMode.none,
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
    );
  }

  void _rebuildElements({
    bool detectIncomingAnimations = false,
    bool detectBarAnimations = false,
    bool detectRadialAnimations = false,
    bool detectPathAnimations = false,
  }) {
    _spatialIndex.clear();

    final previousSeriesById = <String, ChartSeries>{
      for (final series in _effectiveDataSeries) series.id: series,
    };
    final previousRenderSeriesById = <String, ChartSeries>{
      for (final series in _effectiveRenderSeries) series.id: series,
    };

    _resolvedChartData = _resolveChartData();
    _effectiveDataSeries = _resolvedChartData.renderSeries;
    final hoveredMarker = _coordinator.hoveredMarker;
    if (hoveredMarker != null) {
      ChartSeries? nextHoveredSeries;
      for (final series in _resolvedChartData.allSeries) {
        if (series.id == hoveredMarker.seriesId) {
          nextHoveredSeries = series;
          break;
        }
      }
      final sourceChanged =
          nextHoveredSeries == null ||
          hoveredMarker.markerIndex >= nextHoveredSeries.points.length ||
          previousSeriesById[hoveredMarker.seriesId] != nextHoveredSeries;
      if (sourceChanged) {
        _coordinator.setHoveredMarker(null);
        (_renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?)
            ?.clearTransientPreviewState();
      }
    }
    _layoutKind = ChartLayoutResolver.resolve(_resolvedChartData.allSeries);
    if (_layoutKind == ChartLayoutKind.partitionRadial &&
        _resolvedChartData.allSeries.single is RadialCategorySeries) {
      final visibleIndices =
          (_resolvedChartData.allSeries.single as RadialCategorySeries)
              .visiblePointIndices;
      if (_radialKeyboardFocusIndex != null &&
          !visibleIndices.contains(_radialKeyboardFocusIndex)) {
        _radialKeyboardFocusIndex = null;
        _radialFocusIndicatorVisible = false;
      }
    } else {
      _radialKeyboardFocusIndex = null;
      _radialFocusIndicatorVisible = false;
    }
    if (_layoutKind == ChartLayoutKind.partitionRadial &&
        _resolveEffectiveAnnotations().isNotEmpty) {
      throw ArgumentError('Radial charts do not support Cartesian annotations');
    }
    if (detectPathAnimations) {
      _remapPathPointState(previousSeriesById, _effectiveDataSeries);
    }
    _pruneInvalidPointRefs();
    if (detectIncomingAnimations) {
      _updateIncomingPointAnimations(
        previousSeriesById: previousSeriesById,
        nextSeries: _effectiveDataSeries,
      );
    }
    if (detectBarAnimations) {
      _updateBarSeriesTransitions(
        previousSeriesById: previousRenderSeriesById,
        nextSeries: _effectiveDataSeries,
      );
    }
    if (detectRadialAnimations) {
      _updateRadialSeriesTransition(
        previousSeriesById: previousRenderSeriesById,
        nextSeries: _effectiveDataSeries,
      );
    }
    if (detectPathAnimations) {
      _updatePathSeriesAnimations(
        previousSeriesById: previousRenderSeriesById,
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
      final List<ChartElement> elements;
      if (_layoutKind == ChartLayoutKind.partitionRadial) {
        if (_effectiveRenderSeries.isEmpty) {
          elements = <ChartElement>[];
        } else {
          final radialSeries =
              _effectiveRenderSeries.single as RadialCategorySeries;
          elements = <ChartElement>[
            PieSeriesElement(
              series: radialSeries,
              size: Size(transform.plotWidth, transform.plotHeight),
              theme: widget.theme ?? ChartTheme.light,
              textScaleFactor: _textScaleFactor,
              focusedPointIndices: {
                for (final ref in _focusedPointRefs)
                  if (ref.seriesId == radialSeries.id) ref.pointIndex,
                if (_radialFocusIndicatorVisible) ?_radialKeyboardFocusIndex,
              },
              selectedPointIndices: {
                for (final ref in _selectedPointRefs)
                  if (ref.seriesId == radialSeries.id) ref.pointIndex,
              },
              coordinator: _coordinator,
              animationProgress: _radialRevealProgress,
              isEntranceAnimationComplete:
                  _radialRevealAnimationController.value >= 1,
              selectionProgress: _radialSelectionProgress,
              paintCenterContent: widget.donutCenterBuilder == null,
              includeCenterSemantics:
                  widget.donutCenterBuilder == null &&
                  widget.onDonutCenterTap == null,
            ),
          ];
        }
      } else {
        elements = DataConverter.seriesToElements(
          series: _effectiveRenderSeries,
          transform: transform,
          theme: widget.theme,
          coordinator: _coordinator,
          focusedPointRefs: _focusedPointRefs,
          selectedPointRefs: _selectedPointRefs,
          pathRevealProgressBySeries: {
            for (final id in _pathRevealWindows.keys)
              id: _pathRevealProgressFor(id),
          },
          pathPointMapsBySeries: _pathPointMapsBySeries,
        ).cast<ChartElement>().toList();
      }

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
      if (widget.showLegend &&
          _layoutKind == ChartLayoutKind.cartesian &&
          _effectiveRenderSeries.isNotEmpty) {
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

  void _handleBarDataAnimationTick() {
    if (!mounted || _barSeriesTransitions.isEmpty) return;
    setState(() {
      _refreshAnimatedRenderSeries();
      _elementGeneratorVersion++;
    });
  }

  void _handleBarDataAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() {
      _barSeriesTransitions.clear();
      _refreshAnimatedRenderSeries();
      _elementGeneratorVersion++;
    });
  }

  void _handleRadialDataAnimationTick() {
    if (!mounted || _radialSeriesTransition == null) return;
    setState(() {
      _refreshAnimatedRenderSeries();
      _elementGeneratorVersion++;
    });
  }

  void _handlePathDataAnimationTick() {
    if (!mounted || _pathSeriesTransitions.isEmpty) return;
    setState(() {
      _refreshAnimatedRenderSeries();
      _elementGeneratorVersion++;
    });
  }

  void _handleRadialDataAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() {
      _radialSeriesTransition = null;
      _refreshAnimatedRenderSeries();
      _elementGeneratorVersion++;
    });
  }

  void _handlePathDataAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() {
      _pathSeriesTransitions.clear();
      _pathDataTimelineDuration = Duration.zero;
      _refreshAnimatedRenderSeries();
      _elementGeneratorVersion++;
    });
  }

  void _handlePathRevealAnimationTick() {
    if (!mounted || _pathRevealWindows.isEmpty) return;
    setState(() => _elementGeneratorVersion++);
  }

  void _handlePathRevealAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() {
      _pathRevealWindows.clear();
      _pathRevealTimelineDuration = Duration.zero;
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

  void _handleRadialAnimationTick() {
    if (!mounted || _layoutKind != ChartLayoutKind.partitionRadial) return;
    setState(() => _elementGeneratorVersion++);
  }

  Duration get _barDataAnimationDuration =>
      (widget.theme ?? ChartTheme.light).animationTheme.dataUpdateDuration;

  double get _barDataAnimationProgress {
    final curve =
        (widget.theme ?? ChartTheme.light).animationTheme.dataUpdateCurve;
    return curve.transform(_barDataAnimationController.value).clamp(0.0, 1.0);
  }

  double get _radialDataAnimationProgress {
    final curve =
        (widget.theme ?? ChartTheme.light).animationTheme.dataUpdateCurve;
    return curve
        .transform(_radialDataAnimationController.value)
        .clamp(0.0, 1.0);
  }

  bool get _canAnimateBars =>
      !_disableAnimations && _barDataAnimationDuration > Duration.zero;

  bool _canAnimateRadialData(RadialCategorySeries series) =>
      !_disableAnimations &&
      _barDataAnimationDuration > Duration.zero &&
      series.radialStyle.dataTransitionMode ==
          RadialDataTransitionMode.automatic;

  Duration get _pathAnimationDuration =>
      (widget.theme ?? ChartTheme.light).animationTheme.dataUpdateDuration;

  double _pathDataAnimationProgressFor(_ActivePathSeriesTransition transition) {
    final curve =
        (widget.theme ?? ChartTheme.light).animationTheme.dataUpdateCurve;
    return PathAnimationTimeline.progress(
      controllerValue: _pathDataAnimationController.value,
      timelineDuration: _pathDataTimelineDuration,
      window: transition.window,
      curve: curve,
    );
  }

  double _pathRevealProgressFor(String seriesId) {
    final window = _pathRevealWindows[seriesId];
    if (window == null) return 1;
    final curve =
        (widget.theme ?? ChartTheme.light).animationTheme.dataUpdateCurve;
    return PathAnimationTimeline.progress(
      controllerValue: _pathRevealAnimationController.value,
      timelineDuration: _pathRevealTimelineDuration,
      window: window,
      curve: curve,
    );
  }

  bool get _canAnimatePaths =>
      !_disableAnimations && _pathAnimationDuration > Duration.zero;

  void _finishPathAnimationsImmediately() {
    _pathDataAnimationController
      ..stop()
      ..value = 1;
    _pathSeriesTransitions.clear();
    _pathDataTimelineDuration = Duration.zero;
    _pathRevealAnimationController
      ..stop()
      ..value = 1;
    _pathRevealWindows.clear();
    _pathRevealTimelineDuration = Duration.zero;
  }

  PathAnimationStyle? _pathAnimationFor(ChartSeries series) => switch (series) {
    LineChartSeries() => series.pathAnimation,
    AreaChartSeries() => series.pathAnimation,
    _ => null,
  };

  void _replaySeriesEntrance() {
    if (_layoutKind == ChartLayoutKind.partitionRadial) {
      _startRadialRevealAnimation();
    } else {
      _startPathEntranceAnimation();
    }
  }

  void _startPathEntranceAnimation() {
    final ids = <String>{
      for (final series in _effectiveDataSeries)
        if (_pathAnimationFor(series)?.entranceMode ==
            PathEntranceAnimationMode.reveal)
          series.id,
    };
    _startPathReveal(ids);
  }

  void _startPathReveal(Set<String> seriesIds) {
    _pathRevealAnimationController.stop();
    _pathRevealWindows.clear();
    _pathRevealTimelineDuration = Duration.zero;
    if (!_canAnimatePaths || seriesIds.isEmpty) {
      _pathRevealAnimationController.value = 1;
      return;
    }
    final seriesById = <String, ChartSeries>{
      for (final series in _effectiveDataSeries) series.id: series,
    };
    final timings = <String, PathAnimationTiming>{
      for (final id in seriesIds)
        if (seriesById[id] case final series?)
          id: _pathAnimationFor(series)!.entranceTiming,
    };
    final windows = PathAnimationTimeline.resolve(
      timings: timings,
      themeDuration: _pathAnimationDuration,
    );
    _pathRevealWindows.addAll({
      for (final entry in windows.entries)
        if (!entry.value.isImmediate) entry.key: entry.value,
    });
    _pathRevealTimelineDuration = PathAnimationTimeline.totalDuration(
      _pathRevealWindows.values,
    );
    if (_pathRevealWindows.isEmpty ||
        _pathRevealTimelineDuration == Duration.zero) {
      _pathRevealAnimationController.value = 1;
      _pathRevealWindows.clear();
      return;
    }
    _pathRevealAnimationController
      ..duration = _pathRevealTimelineDuration
      ..value = 0;
    _elementGeneratorVersion++;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pathRevealWindows.isEmpty) return;
      _pathRevealAnimationController.forward();
    });
  }

  void _updatePathSeriesAnimations({
    required Map<String, ChartSeries> previousSeriesById,
    required List<ChartSeries> nextSeries,
  }) {
    _pathSeriesTransitions.clear();
    _pathDataTimelineDuration = Duration.zero;
    _pathDataAnimationController.stop();
    final revealIds = <String>{};
    if (!_canAnimatePaths || _layoutKind != ChartLayoutKind.cartesian) {
      _pathDataAnimationController.value = 1;
      _startPathReveal(const <String>{});
      return;
    }

    final pendingTransitions = <String, _PendingPathSeriesTransition>{};
    final transitionTimings = <String, PathAnimationTiming>{};
    for (final next in nextSeries) {
      final style = _pathAnimationFor(next);
      if (style == null) continue;
      final previous = previousSeriesById[next.id];
      if (previous == null) {
        if (style.entranceMode == PathEntranceAnimationMode.reveal) {
          revealIds.add(next.id);
        }
        continue;
      }
      final pointsChanged = !listEquals(previous.points, next.points);
      final previousStyle = _pathAnimationFor(previous);
      final entranceModeChanged =
          previousStyle?.entranceMode != style.entranceMode;
      if (!pointsChanged) {
        if (entranceModeChanged &&
            style.entranceMode == PathEntranceAnimationMode.reveal) {
          revealIds.add(next.id);
        }
        continue;
      }
      if (style.dataUpdateMode == PathDataUpdateAnimationMode.interpolate &&
          PathSeriesTransition.isCompatible(previous, next)) {
        pendingTransitions[next.id] = _PendingPathSeriesTransition(
          from: previous,
          to: next,
        );
        transitionTimings[next.id] = style.dataUpdateTiming;
      } else if (style.entranceMode == PathEntranceAnimationMode.reveal) {
        revealIds.add(next.id);
      }
    }

    final transitionWindows = PathAnimationTimeline.resolve(
      timings: transitionTimings,
      themeDuration: _pathAnimationDuration,
    );
    for (final entry in pendingTransitions.entries) {
      final window = transitionWindows[entry.key]!;
      if (window.isImmediate) continue;
      _pathSeriesTransitions[entry.key] = _ActivePathSeriesTransition(
        from: entry.value.from,
        to: entry.value.to,
        window: window,
      );
    }
    _pathDataTimelineDuration = PathAnimationTimeline.totalDuration(
      _pathSeriesTransitions.values.map((transition) => transition.window),
    );

    if (_pathSeriesTransitions.isEmpty) {
      _pathDataAnimationController.value = 1;
    } else {
      _pathDataAnimationController
        ..duration = _pathDataTimelineDuration
        ..value = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _pathSeriesTransitions.isEmpty) return;
        _pathDataAnimationController.forward();
      });
    }
    _startPathReveal(revealIds);
  }

  void _startBarEntranceAnimation() {
    _updateBarSeriesTransitions(
      previousSeriesById: const <String, ChartSeries>{},
      nextSeries: _effectiveDataSeries,
      entrance: true,
    );
    _refreshAnimatedRenderSeries();
    _elementGeneratorVersion++;
  }

  void _updateBarSeriesTransitions({
    required Map<String, ChartSeries> previousSeriesById,
    required List<ChartSeries> nextSeries,
    bool entrance = false,
  }) {
    _barSeriesTransitions.clear();
    _barDataAnimationController.stop();
    if (!_canAnimateBars || _layoutKind != ChartLayoutKind.cartesian) {
      _barDataAnimationController.value = 1;
      return;
    }
    _barDataAnimationController.value = 0;

    for (final next in nextSeries.whereType<BarChartSeries>()) {
      if (next.barStyle.animationMode == BarAnimationMode.none) continue;
      final previous = previousSeriesById[next.id];
      final from = entrance || previous is! BarChartSeries
          ? BarSeriesTransition.collapsed(next)
          : BarSeriesTransition.hasCompatibleLayout(previous, next)
          ? previous
          : BarSeriesTransition.collapsed(next);
      if (!entrance && from == next) continue;
      _barSeriesTransitions[next.id] = _ActiveBarSeriesTransition(
        from: from,
        to: next,
      );
    }

    if (_barSeriesTransitions.isEmpty) {
      _barDataAnimationController.value = 1;
      return;
    }

    _barDataAnimationController.duration = _barDataAnimationDuration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _barSeriesTransitions.isEmpty) return;
      _barDataAnimationController.forward();
    });
  }

  void _updateRadialSeriesTransition({
    required Map<String, ChartSeries> previousSeriesById,
    required List<ChartSeries> nextSeries,
  }) {
    _radialSeriesTransition = null;
    _radialDataAnimationController.stop();
    if (_layoutKind != ChartLayoutKind.partitionRadial ||
        nextSeries.length != 1) {
      _radialDataAnimationController.value = 1;
      return;
    }
    final next = nextSeries.single;
    if (next is! RadialCategorySeries || !_canAnimateRadialData(next)) {
      _radialDataAnimationController.value = 1;
      return;
    }
    final previous = previousSeriesById[next.id];
    if (previous is! RadialCategorySeries ||
        previous.runtimeType != next.runtimeType ||
        previous == next) {
      _radialDataAnimationController.value = 1;
      return;
    }
    _radialSeriesTransition = _ActiveRadialSeriesTransition(
      from: previous,
      to: next,
    );
    _radialDataAnimationController
      ..duration = _barDataAnimationDuration
      ..value = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _radialSeriesTransition == null) return;
      _radialDataAnimationController.forward();
    });
  }

  bool _radialDataChanged(List<ChartSeries> previous, List<ChartSeries> next) {
    if (previous.length != 1 || next.length != 1) return false;
    final previousRadial = previous.single;
    final nextRadial = next.single;
    if (previousRadial is! RadialCategorySeries ||
        nextRadial is! RadialCategorySeries) {
      return false;
    }
    return previousRadial.runtimeType != nextRadial.runtimeType ||
        previousRadial.id != nextRadial.id ||
        !listEquals(previousRadial.points, nextRadial.points) ||
        previousRadial.sliceGroupingConfig != nextRadial.sliceGroupingConfig;
  }

  void _remapPathPointState(
    Map<String, ChartSeries> previousSeriesById,
    List<ChartSeries> nextSeries,
  ) {
    if (_focusedPointRefs.isEmpty && _selectedPointRefs.isEmpty) return;
    final nextSeriesById = <String, ChartSeries>{
      for (final series in nextSeries) series.id: series,
    };

    Set<ChartPointRef> remap(Set<ChartPointRef> refs) {
      final result = <ChartPointRef>{};
      for (final ref in refs) {
        final previous = previousSeriesById[ref.seriesId];
        final next = nextSeriesById[ref.seriesId];
        final isPathPair =
            (previous is LineChartSeries || previous is AreaChartSeries) &&
            (next is LineChartSeries || next is AreaChartSeries);
        if (!isPathPair ||
            !PathSeriesTransition.isCompatible(previous!, next!)) {
          result.add(ref);
          continue;
        }
        final targetIndex = PathSeriesTransition.targetIndexForSource(
          previous,
          next,
          ref.pointIndex,
        );
        if (targetIndex != null) {
          result.add(ChartPointRef(seriesId: next.id, pointIndex: targetIndex));
        }
      }
      return result;
    }

    final focused = remap(_focusedPointRefs);
    final selected = remap(_selectedPointRefs);
    if (setEquals(focused, _focusedPointRefs) &&
        setEquals(selected, _selectedPointRefs)) {
      return;
    }
    _focusedPointRefs
      ..clear()
      ..addAll(focused);
    _selectedPointRefs
      ..clear()
      ..addAll(selected);
    _syncControllerPointState();
  }

  void _remapRadialPointState(
    List<ChartSeries> previous,
    List<ChartSeries> next,
  ) {
    if (previous.length != 1 || next.length != 1) return;
    final from = previous.single;
    final to = next.single;
    if (from is! RadialCategorySeries ||
        to is! RadialCategorySeries ||
        from.id != to.id) {
      return;
    }
    final fromKeys = RadialSeriesTransition.identityKeys(from.points);
    final toKeys = RadialSeriesTransition.identityKeys(to.points);
    final nextIndexByKey = <String, int>{
      for (final (index, key) in toKeys.indexed) key: index,
    };

    Set<ChartPointRef> remap(Set<ChartPointRef> refs) => <ChartPointRef>{
      for (final ref in refs)
        if (ref.seriesId != from.id)
          ref
        else if (ref.pointIndex >= 0 && ref.pointIndex < fromKeys.length)
          if (nextIndexByKey[fromKeys[ref.pointIndex]] case final nextIndex?)
            ChartPointRef(seriesId: to.id, pointIndex: nextIndex),
    };

    final focused = remap(_focusedPointRefs);
    final selected = remap(_selectedPointRefs);
    _focusedPointRefs
      ..clear()
      ..addAll(focused);
    _selectedPointRefs
      ..clear()
      ..addAll(selected);
    final keyboardIndex = _radialKeyboardFocusIndex;
    if (keyboardIndex != null &&
        keyboardIndex >= 0 &&
        keyboardIndex < fromKeys.length) {
      _radialKeyboardFocusIndex = nextIndexByKey[fromKeys[keyboardIndex]];
    }
    _syncControllerPointState();
  }

  bool _radialAnimationModeChanged({
    required List<ChartSeries> previous,
    required List<ChartSeries> next,
    required ChartTheme previousTheme,
    required ChartTheme nextTheme,
  }) {
    if (previous.length != 1 || next.length != 1) return false;
    final previousSeries = previous.single;
    final nextSeries = next.single;
    if (previousSeries is! RadialCategorySeries ||
        nextSeries is! RadialCategorySeries) {
      return false;
    }
    final previousMode =
        previousSeries.radialStyle.animationMode ??
        previousTheme.pieChartTheme.animationMode;
    final nextMode =
        nextSeries.radialStyle.animationMode ??
        nextTheme.pieChartTheme.animationMode;
    return previousMode != nextMode;
  }

  PieAnimationMode _effectiveRadialAnimationMode(RadialCategorySeries series) =>
      series.radialStyle.animationMode ??
      (widget.theme ?? ChartTheme.light).pieChartTheme.animationMode;

  bool _canAnimateRadial(RadialCategorySeries series, Duration duration) =>
      !_disableAnimations &&
      duration > Duration.zero &&
      _effectiveRadialAnimationMode(series) != PieAnimationMode.none;

  void _startRadialRevealAnimation() {
    final series = _effectiveRadialSeries;
    if (series == null) {
      _radialRevealAnimationController
        ..stop()
        ..value = 1;
      return;
    }
    final animationTheme = (widget.theme ?? ChartTheme.light).animationTheme;
    final duration = animationTheme.dataUpdateDuration;
    if (!_canAnimateRadial(series, duration)) {
      _radialRevealAnimationController
        ..stop()
        ..value = 1;
      return;
    }
    _radialRevealAnimationController
      ..duration = duration
      ..stop()
      ..value = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _effectiveRadialSeries == null) return;
      _radialRevealAnimationController.forward();
    });
  }

  void _startRadialSelectionAnimation() {
    final series = _effectiveRadialSeries;
    if (series == null) return;
    final animationTheme = (widget.theme ?? ChartTheme.light).animationTheme;
    final duration = animationTheme.interactionDuration;
    if (!_canAnimateRadial(series, duration)) {
      _radialSelectionAnimationController
        ..stop()
        ..value = 1;
      return;
    }
    _radialSelectionAnimationController
      ..duration = duration
      ..stop()
      ..value = 0
      ..forward();
  }

  double get _radialRevealProgress {
    final theme = (widget.theme ?? ChartTheme.light).animationTheme;
    return theme.dataUpdateCurve
        .transform(_radialRevealAnimationController.value)
        .clamp(0.0, 1.0);
  }

  double get _radialSelectionProgress {
    final theme = (widget.theme ?? ChartTheme.light).animationTheme;
    return theme.interactionCurve
        .transform(_radialSelectionAnimationController.value)
        .clamp(0.0, 1.0);
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
    _pathPointMapsBySeries.clear();
    if (_effectiveDataSeries.isEmpty) {
      _effectiveRenderSeries = _effectiveDataSeries;
      return;
    }

    var renderSeries = _effectiveDataSeries;
    if (_barSeriesTransitions.isNotEmpty) {
      final progress = _barDataAnimationProgress;
      renderSeries = _effectiveDataSeries
          .map((series) {
            final transition = _barSeriesTransitions[series.id];
            if (transition == null) return series;
            return BarSeriesTransition.interpolate(
              from: transition.from,
              to: transition.to,
              progress: progress,
            );
          })
          .toList(growable: false);
    }
    if (_pathSeriesTransitions.isNotEmpty) {
      renderSeries = renderSeries
          .map((series) {
            final transition = _pathSeriesTransitions[series.id];
            if (transition == null) return series;
            final frame = PathSeriesTransition.frame(
              from: transition.from,
              to: transition.to,
              progress: _pathDataAnimationProgressFor(transition),
            );
            _pathPointMapsBySeries[series.id] = frame.pointMap;
            return frame.series;
          })
          .toList(growable: false);
    }
    final radialTransition = _radialSeriesTransition;
    if (radialTransition != null) {
      final targetOpacity =
          radialTransition.to.radialStyle.opacity ??
          (widget.theme ?? ChartTheme.light).pieChartTheme.opacity;
      renderSeries = <ChartSeries>[
        RadialSeriesTransition.interpolate(
          from: radialTransition.from,
          to: radialTransition.to,
          progress: _radialDataAnimationProgress,
          effectiveOpacity: targetOpacity,
        ),
      ];
    }
    if (_incomingPointAnimations.isEmpty) {
      _effectiveRenderSeries = renderSeries;
      return;
    }

    final progress = _incomingDataAnimationController.value;
    _effectiveRenderSeries = renderSeries
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
    return to.copyWith(
      x: from.x + ((to.x - from.x) * clampedT),
      y: from.y + ((to.y - from.y) * clampedT),
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
    if (_layoutKind == ChartLayoutKind.partitionRadial) {
      final interaction = _effectiveRadialInteractionConfig();
      if (!interaction.enabled) return;
      final renderBox =
          _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
      final hit = renderBox?.dataHitAtWidgetPosition(details.localPosition);
      if (hit != null) {
        _activateRadialDataHit(hit, position: details.localPosition);
      } else {
        if (interaction.enableSelection) _clearRadialPointSelection();
        widget.onBackgroundTap?.call(details.localPosition);
      }
      if (!_focusNode.hasFocus) _focusNode.requestFocus();
      return;
    }

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
        final marker = _coordinator.pressedMarker ?? _coordinator.hoveredMarker;
        if (marker != null && marker.seriesId == tappedElement.series.id) {
          final point = tappedElement.series.points[marker.markerIndex];
          if (tappedElement.series is BarChartSeries) {
            _selectBarPointFromInteraction(marker);
          }
          widget.onPointTap?.call(point, tappedElement.series.id);
        } else {
          _handleSeriesSelected(tappedElement.series.id);
        }
      }
    } else {
      _clearPointSelection();
      widget.onBackgroundTap?.call(details.localPosition);
    }

    // Request focus on tap to enable keyboard controls
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  void _selectBarPointFromInteraction(HoveredMarkerInfo marker) {
    final ref = ChartPointRef(
      seriesId: marker.seriesId,
      pointIndex: marker.markerIndex,
    );
    _selectBarPointRef(ref, additive: _coordinator.isCtrlPressed);
  }

  void _selectBarPointRef(ChartPointRef ref, {required bool additive}) {
    final nextSelection = additive
        ? <ChartPointRef>{..._selectedPointRefs}
        : <ChartPointRef>{ref};
    if (additive && !nextSelection.add(ref)) {
      nextSelection.remove(ref);
    }
    if (setEquals(nextSelection, _selectedPointRefs)) return;
    _selectedPointRefs
      ..clear()
      ..addAll(nextSelection);
    _captureStateRevision++;
    _refreshLinkedPointRendering();
    _syncControllerPointState();
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
    if (element is DataHitElement) {
      final marker = _coordinator.hoveredMarker;
      final hit =
          marker?.dataHit ??
          (marker?.seriesId == element.series.id
              ? element.dataHitForPointIndex(marker!.markerIndex)
              : null);
      if (hit != null) {
        widget.onPointHover?.call(hit.point, element.series.id);
        widget.interactionConfig?.onDataPointHover?.call(
          hit.point,
          _widgetPositionForDataHit(hit),
        );
      } else {
        widget.onPointHover?.call(null, element.series.id);
        widget.interactionConfig?.onDataPointHover?.call(null, Offset.zero);
      }
    } else {
      widget.onPointHover?.call(null, null);
      widget.interactionConfig?.onDataPointHover?.call(null, Offset.zero);
    }
  }

  InteractionConfig _effectiveRadialInteractionConfig() {
    final source = widget.interactionConfig ?? const InteractionConfig();
    final tooltip = _disableAnimations
        ? source.tooltip.copyWith(
            showDelay: Duration.zero,
            hideDelay: Duration.zero,
          )
        : source.tooltip;
    return source.copyWith(
      crosshair: source.crosshair.copyWith(enabled: false),
      tooltip: tooltip,
      enableZoom: false,
      enablePan: false,
      showXScrollbar: false,
      showYScrollbar: false,
    );
  }

  void _activateRadialDataHit(
    ChartDataHit hit, {
    required Offset position,
    bool showFocusIndicator = false,
  }) {
    _focusRadialPoint(
      hit.pointIndex,
      announceHover: false,
      showFocusIndicator: showFocusIndicator,
    );
    _commitRadialPointActivation(
      point: hit.point,
      seriesId: hit.seriesId,
      sourcePointIndices: hit.effectiveSourcePointIndices,
      position: position,
    );
  }

  void _commitRadialPointActivation({
    required ChartDataPoint point,
    required String seriesId,
    required Iterable<int> sourcePointIndices,
    required Offset position,
  }) {
    final interaction = _effectiveRadialInteractionConfig();
    if (interaction.enableSelection) {
      final pointRefs = <ChartPointRef>{
        for (final sourcePointIndex in sourcePointIndices)
          ChartPointRef(seriesId: seriesId, pointIndex: sourcePointIndex),
      };
      final alreadySelected =
          _selectedPointRefs.length == pointRefs.length &&
          _selectedPointRefs.containsAll(pointRefs);
      _selectedPointRefs
        ..clear()
        ..addAll(alreadySelected ? const <ChartPointRef>{} : pointRefs);
      if (alreadySelected) {
        _coordinator.setHoveredMarker(null);
      }
      _captureStateRevision++;
      _startRadialSelectionAnimation();
      _refreshLinkedPointRendering();
      _syncControllerPointState();
      _notifyPointSelectionChanged();
    }
    widget.onPointTap?.call(point, seriesId);
    interaction.onDataPointTap?.call(point, position);
  }

  void _activateRadialPointIndex(
    int pointIndex, {
    bool showFocusIndicator = false,
  }) {
    final series = _effectiveRadialSeries;
    if (series == null) return;
    final renderBox =
        _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    final hit = renderBox?.dataHitForPointIndex(series.id, pointIndex);
    if (hit != null) {
      _activateRadialDataHit(
        hit,
        position: _widgetPositionForDataHit(hit),
        showFocusIndicator: showFocusIndicator,
      );
      return;
    }
    final visibleSlice = series.visibleSliceForSourcePointIndex(pointIndex);
    if (visibleSlice == null) return;
    _radialKeyboardFocusIndex = visibleSlice.pointIndex;
    _radialFocusIndicatorVisible = showFocusIndicator;
    _commitRadialPointActivation(
      point: visibleSlice.point,
      seriesId: series.id,
      sourcePointIndices: visibleSlice.sourcePointIndices,
      position: Offset.zero,
    );
  }

  void _clearRadialPointSelection() {
    if (_selectedPointRefs.isEmpty) return;
    _selectedPointRefs.clear();
    _coordinator.setHoveredMarker(null);
    _captureStateRevision++;
    _startRadialSelectionAnimation();
    _refreshLinkedPointRendering();
    _syncControllerPointState();
    _notifyPointSelectionChanged();
  }

  void _notifyPointSelectionChanged() {
    final selectedPoints = <ChartDataPoint>[];
    final seriesById = {
      for (final series in _resolvedChartData.allSeries) series.id: series,
    };
    for (final ref in _selectedPointRefs) {
      final series = seriesById[ref.seriesId];
      if (series != null && ref.pointIndex < series.points.length) {
        selectedPoints.add(series.points[ref.pointIndex]);
      }
    }
    widget.interactionConfig?.onSelectionChanged?.call(selectedPoints);
  }

  void _focusRadialPoint(
    int pointIndex, {
    bool announceHover = true,
    bool showFocusIndicator = true,
  }) {
    final series = _effectiveRadialSeries;
    final visibleSlice = series?.visibleSliceForSourcePointIndex(pointIndex);
    if (series == null || visibleSlice == null) {
      return;
    }
    _radialKeyboardFocusIndex = visibleSlice.pointIndex;
    _radialFocusIndicatorVisible = showFocusIndicator;
    final renderBox =
        _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    final hit = renderBox?.dataHitForPointIndex(series.id, pointIndex);
    if (hit != null) {
      _coordinator.setHoveredMarker(
        HoveredMarkerInfo(
          seriesId: hit.seriesId,
          markerIndex: hit.pointIndex,
          plotPosition: hit.plotPosition,
          dataHit: hit,
        ),
      );
      if (announceHover) {
        widget.onPointHover?.call(hit.point, hit.seriesId);
        widget.interactionConfig?.onDataPointHover?.call(
          hit.point,
          _widgetPositionForDataHit(hit),
        );
      }
    }
    _refreshLinkedPointRendering();
  }

  bool _handleRadialKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final interaction = _effectiveRadialInteractionConfig();
    if (!interaction.enabled || !interaction.keyboard.enabled) return false;
    final series = _effectiveRadialSeries;
    if (series == null || series.visiblePointIndices.isEmpty) return false;
    final visible = series.visiblePointIndices;

    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final forward =
          event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.arrowDown;
      final current = visible.indexOf(_radialKeyboardFocusIndex ?? -1);
      final next = current < 0
          ? (forward ? 0 : visible.length - 1)
          : (current + (forward ? 1 : -1)) % visible.length;
      _focusRadialPoint(visible[next]);
      final point = series.points[visible[next]];
      interaction.onKeyboardAction?.call(
        forward ? 'focus_next_slice' : 'focus_previous_slice',
        point,
      );
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      final pointIndex = _radialKeyboardFocusIndex ?? visible.first;
      _activateRadialPointIndex(pointIndex, showFocusIndicator: true);
      interaction.onKeyboardAction?.call(
        'select_slice',
        series.points[pointIndex],
      );
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _radialKeyboardFocusIndex = null;
      _radialFocusIndicatorVisible = false;
      _coordinator.setHoveredMarker(null);
      _clearRadialPointSelection();
      _refreshLinkedPointRendering();
      interaction.onKeyboardAction?.call('clear_slice_selection', null);
      return true;
    }
    return false;
  }

  RadialCategorySeries? get _effectiveRadialSeries {
    for (final series in _effectiveRenderSeries) {
      if (series is RadialCategorySeries) return series;
    }
    return null;
  }

  Offset _widgetPositionForDataHit(ChartDataHit hit) {
    final renderBox =
        _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    return renderBox?.plotToWidget(hit.plotPosition) ?? hit.plotPosition;
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
    // Publish hidden IDs immediately, then refresh axis-slot state after the
    // render object receives the filtered series during this frame.
    _syncControllerState(renderBox);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final updatedRenderBox =
          _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
      _syncControllerState(updatedRenderBox);
    });
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
    _startRadialSelectionAnimation();
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
    final expandedRefs = _expandRadialPointRefs(refs);
    final nextSelection = additive
        ? (<ChartPointRef>{..._selectedPointRefs, ...expandedRefs})
        : expandedRefs.toSet();
    if (setEquals(nextSelection, _selectedPointRefs)) {
      if (reveal) _revealPoints(expandedRefs);
      return ChartArtifactSuccess(value: null);
    }
    _selectedPointRefs
      ..clear()
      ..addAll(nextSelection);
    if (_layoutKind == ChartLayoutKind.partitionRadial &&
        nextSelection.isEmpty) {
      _coordinator.setHoveredMarker(null);
    }
    _captureStateRevision++;
    _startRadialSelectionAnimation();
    _refreshLinkedPointRendering();
    _syncControllerPointState();
    _notifyPointSelectionChanged();
    if (reveal) _revealPoints(expandedRefs);
    return ChartArtifactSuccess(value: null);
  }

  List<ChartPointRef> _expandRadialPointRefs(List<ChartPointRef> refs) {
    final series = _effectiveRadialSeries;
    if (series == null) return refs;
    final expanded = <ChartPointRef>{};
    for (final ref in refs) {
      if (ref.seriesId != series.id) {
        expanded.add(ref);
        continue;
      }
      final slice = series.visibleSliceForSourcePointIndex(ref.pointIndex);
      if (slice == null) {
        expanded.add(ref);
        continue;
      }
      expanded.addAll([
        for (final sourcePointIndex in slice.sourcePointIndices)
          ChartPointRef(seriesId: series.id, pointIndex: sourcePointIndex),
      ]);
    }
    return expanded.toList(growable: false);
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
    if (_layoutKind == ChartLayoutKind.partitionRadial) {
      _coordinator.setHoveredMarker(null);
    }
    _captureStateRevision++;
    _startRadialSelectionAnimation();
    _refreshLinkedPointRendering();
    _syncControllerPointState();
    _notifyPointSelectionChanged();
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

      if (_handleBarPointKey(event.logicalKey)) return;

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

  bool _handleBarPointKey(LogicalKeyboardKey key) {
    final keyboard =
        widget.interactionConfig?.keyboard ?? const KeyboardConfig();
    if (!keyboard.enabled) return false;
    final bars = _effectiveDataSeries
        .whereType<BarChartSeries>()
        .where((series) => series.points.isNotEmpty)
        .toList(growable: false);
    if (bars.isEmpty || bars.length != _effectiveDataSeries.length) {
      return false;
    }

    if (key == LogicalKeyboardKey.escape) {
      if (_focusedPointRefs.isEmpty && _selectedPointRefs.isEmpty) return false;
      _clearPointFocus();
      _clearPointSelection();
      return true;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      final current = _focusedPointRefs.firstOrNull;
      if (current == null) return false;
      _selectBarPointRef(
        current,
        additive:
            HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed,
      );
      return true;
    }

    final isArrow =
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown;
    if (!isArrow ||
        !keyboard.enableArrowKeys ||
        HardwareKeyboard.instance.isAltPressed) {
      return false;
    }

    var seriesIndex = 0;
    var pointIndex = 0;
    final current = _focusedPointRefs.firstOrNull;
    if (current != null) {
      final resolvedSeriesIndex = bars.indexWhere(
        (series) => series.id == current.seriesId,
      );
      if (resolvedSeriesIndex >= 0) {
        seriesIndex = resolvedSeriesIndex;
        pointIndex = current.pointIndex.clamp(
          0,
          bars[seriesIndex].points.length - 1,
        );
      }
    }

    final orientation = bars.first.orientation;
    final movesCategory = orientation == BarOrientation.vertical
        ? key == LogicalKeyboardKey.arrowLeft ||
              key == LogicalKeyboardKey.arrowRight
        : key == LogicalKeyboardKey.arrowUp ||
              key == LogicalKeyboardKey.arrowDown;
    final delta =
        key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowUp
        ? -1
        : 1;

    if (current == null) {
      // The first arrow press establishes a visible focus target without
      // skipping the first bar.
      _setKeyboardBarFocus(bars.first, 0);
      return true;
    }
    if (movesCategory) {
      pointIndex = (pointIndex + delta).clamp(
        0,
        bars[seriesIndex].points.length - 1,
      );
    } else {
      seriesIndex = (seriesIndex + delta).clamp(0, bars.length - 1);
      pointIndex = pointIndex.clamp(0, bars[seriesIndex].points.length - 1);
    }
    _setKeyboardBarFocus(bars[seriesIndex], pointIndex);
    return true;
  }

  void _setKeyboardBarFocus(BarChartSeries series, int pointIndex) {
    final ref = ChartPointRef(seriesId: series.id, pointIndex: pointIndex);
    if (_focusedPointRefs.length == 1 && _focusedPointRefs.contains(ref)) {
      return;
    }
    _focusedPointRefs
      ..clear()
      ..add(ref);
    _refreshLinkedPointRendering();
    _syncControllerPointState();
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
      if (series is BarChartSeries) {
        for (final target in series.targetValues.whereType<double>()) {
          if (!target.isFinite) continue;
          if (target < minY) minY = target;
          if (target > maxY) maxY = target;
        }
        for (final lower in series.errorLowerValues.whereType<double>()) {
          if (!lower.isFinite) continue;
          if (lower < minY) minY = lower;
          if (lower > maxY) maxY = lower;
        }
        for (final upper in series.errorUpperValues.whereType<double>()) {
          if (!upper.isFinite) continue;
          if (upper < minY) minY = upper;
          if (upper > maxY) maxY = upper;
        }
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
      final hasData = _layoutKind == ChartLayoutKind.partitionRadial
          ? _effectiveDataSeries.whereType<RadialCategorySeries>().any(
              (series) => series.total > 0,
            )
          : _effectiveDataSeries.any(
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

  ({String value, bool isSelected})? _focusedBarSemantics() {
    final ref = _focusedPointRefs.firstOrNull;
    if (ref == null) return null;
    return _barSemanticsForRef(ref);
  }

  ({String value, bool isSelected})? _barSemanticsForRef(ChartPointRef ref) {
    final series = _effectiveDataSeries
        .whereType<BarChartSeries>()
        .where((candidate) => candidate.id == ref.seriesId)
        .firstOrNull;
    if (series == null ||
        ref.pointIndex < 0 ||
        ref.pointIndex >= series.points.length) {
      return null;
    }
    final point = series.points[ref.pointIndex];
    final category = point.hasLabel
        ? point.label!
        : 'Category ${ref.pointIndex + 1}';
    final unit = series.unit == null || series.unit!.isEmpty
        ? ''
        : ' ${series.unit}';
    final value = switch (series.layoutMode) {
      BarLayoutMode.waterfall =>
        series.isWaterfallTotal(ref.pointIndex)
            ? 'total ${series.waterfallDisplayValueFor(ref.pointIndex)}$unit'
            : 'change ${point.y}$unit',
      _ when series.hasRangeValues =>
        '${series.rangeStartValueFor(ref.pointIndex)} to ${point.y}$unit',
      BarLayoutMode.normalizedStacked => '${point.y}$unit, normalized segment',
      _ => '${point.y}$unit',
    };
    final target = series.targetValueFor(ref.pointIndex);
    final targetDescription = target == null ? '' : ', target $target$unit';
    final errorLower = series.errorLowerValueFor(ref.pointIndex);
    final errorUpper = series.errorUpperValueFor(ref.pointIndex);
    final uncertaintyDescription = errorLower == null || errorUpper == null
        ? ''
        : ', uncertainty $errorLower to $errorUpper$unit';
    return (
      value:
          '${series.name}, $category, $value$targetDescription$uncertaintyDescription',
      isSelected: _selectedPointRefs.contains(ref),
    );
  }

  String? _adjacentBarSemanticsValue(int delta) {
    final current = _focusedPointRefs.firstOrNull;
    if (current == null) return null;
    final series = _effectiveDataSeries
        .whereType<BarChartSeries>()
        .where((candidate) => candidate.id == current.seriesId)
        .firstOrNull;
    if (series == null || series.points.isEmpty) return null;
    final nextIndex = (current.pointIndex + delta).clamp(
      0,
      series.points.length - 1,
    );
    return _barSemanticsForRef(
      ChartPointRef(seriesId: series.id, pointIndex: nextIndex),
    )?.value;
  }

  void _moveSemanticBarFocus(int delta) {
    final bars = _effectiveDataSeries.whereType<BarChartSeries>();
    if (bars.isEmpty) return;
    final orientation = bars.first.orientation;
    _handleBarPointKey(
      orientation == BarOrientation.vertical
          ? delta < 0
                ? LogicalKeyboardKey.arrowLeft
                : LogicalKeyboardKey.arrowRight
          : delta < 0
          ? LogicalKeyboardKey.arrowUp
          : LogicalKeyboardKey.arrowDown,
    );
    if (!_focusNode.hasFocus) _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    // Disable browser context menu on web platform
    if (kIsWeb) {
      BrowserContextMenu.disableContextMenu();
    }

    final isRadial = _layoutKind == ChartLayoutKind.partitionRadial;
    final effectiveInteractionConfig = isRadial
        ? _effectiveRadialInteractionConfig()
        : widget.interactionConfig;
    ChartPointRef? selectedTooltipPoint;
    final radialSeries = isRadial ? _effectiveRadialSeries : null;
    if (radialSeries != null) {
      for (final pointRef in _selectedPointRefs) {
        if (pointRef.seriesId == radialSeries.id &&
            radialSeries.visibleSliceForSourcePointIndex(pointRef.pointIndex) !=
                null) {
          selectedTooltipPoint = pointRef;
          break;
        }
      }
    }

    final focusChart = Focus(
      focusNode: _focusNode,
      autofocus: false,
      onKeyEvent: (node, event) {
        if (isRadial) {
          return _handleRadialKeyEvent(event)
              ? KeyEventResult.handled
              : KeyEventResult.ignored;
        }
        _handleKeyEvent(event);
        return KeyEventResult.handled;
      },
      child: Builder(
        builder: (context) {
          final hasFocus = _focusNode.hasFocus;
          final enableFocusOnHover =
              effectiveInteractionConfig?.enableFocusOnHover ?? true;
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
                    (effectiveInteractionConfig?.showFocusBorder ?? false) &&
                        hasFocus
                    ? Border.all(
                        color: widget.theme?.focusBorderColor ?? Colors.blue,
                        width: widget.theme?.focusBorderWidth ?? 2.0,
                      )
                    : null,
                borderRadius:
                    (effectiveInteractionConfig?.showFocusBorder ?? false) &&
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
                        xAxis: isRadial ? null : _xAxis,
                        xAxisConfig: isRadial ? null : widget.xAxisConfig,
                        yAxis: isRadial ? null : _yAxis,
                        primaryYAxisConfig: isRadial ? null : widget.yAxis,
                        theme: widget.theme,
                        tooltipsEnabled:
                            (effectiveInteractionConfig?.enabled ?? true) &&
                            (effectiveInteractionConfig?.tooltip.enabled ??
                                true),
                        selectedTooltipSeriesId: selectedTooltipPoint?.seriesId,
                        selectedTooltipPointIndex:
                            selectedTooltipPoint?.pointIndex,
                        // Prioritize widget's direct showXScrollbar/showYScrollbar properties
                        // InteractionConfig's defaults are false, so ?? doesn't work correctly
                        showXScrollbar: !isRadial && widget.showXScrollbar,
                        showYScrollbar: !isRadial && widget.showYScrollbar,
                        scrollbarTheme: widget.scrollbarTheme,
                        interactionConfig: effectiveInteractionConfig,
                        textScaleFactor: _textScaleFactor,
                        onCursorChange: _handleCursorChange,
                        onAnnotationChanged: _handleAnnotationChanged,
                        onElementHover: _handleElementHover,
                        onDataHitActivate: (hit) => _activateRadialDataHit(
                          hit,
                          position: _widgetPositionForDataHit(hit),
                          showFocusIndicator: true,
                        ),
                        onDataHitFocus: (hit) =>
                            _focusRadialPoint(hit.pointIndex),
                        onRangeCreationComplete: _onRangeCreationComplete,
                        onViewportInteracted: _handleViewportInteractionPulse,
                        gridConfig: isRadial ? null : widget.grid,
                        // Multi-axis parameters
                        normalizationMode: isRadial
                            ? NormalizationMode.none
                            : _effectiveNormalizationMode,
                        series: isRadial
                            ? const <ChartSeries>[]
                            : _effectiveRenderSeries,
                        maxAxesPerSide: widget.maxAxesPerSide,
                        axisSwapMode: widget.axisSwapMode,
                      ),
                    ),
                  ),
                  if (radialSeries is DonutChartSeries &&
                      radialSeries.centerContent.isVisible &&
                      (widget.donutCenterBuilder != null ||
                          widget.onDonutCenterTap != null))
                    Positioned.fill(
                      child: _DonutCenterOverlay(
                        series: radialSeries,
                        chartTheme: widget.theme ?? ChartTheme.light,
                        textScaleFactor: _textScaleFactor,
                        selectedPointIndices: {
                          for (final ref in _selectedPointRefs)
                            if (ref.seriesId == radialSeries.id) ref.pointIndex,
                        },
                        animationProgress: _radialRevealProgress,
                        isEntranceAnimationComplete:
                            _radialRevealAnimationController.value >= 1,
                        selectionProgress: _radialSelectionProgress,
                        builder: widget.donutCenterBuilder,
                        onTap: widget.onDonutCenterTap,
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

    final hasOnlyBars =
        !isRadial &&
        _effectiveDataSeries.isNotEmpty &&
        _effectiveDataSeries.every((series) => series is BarChartSeries);
    final focusedBar = hasOnlyBars ? _focusedBarSemantics() : null;
    final Widget renderedChart = hasOnlyBars
        ? Semantics(
            container: true,
            focusable: true,
            label: widget.title ?? 'Interactive bar chart',
            value: focusedBar?.value,
            increasedValue: focusedBar == null
                ? null
                : _adjacentBarSemanticsValue(1) ?? focusedBar.value,
            decreasedValue: focusedBar == null
                ? null
                : _adjacentBarSemanticsValue(-1) ?? focusedBar.value,
            hint: focusedBar == null
                ? 'Use arrow keys to move between bars. Press Enter to select.'
                : null,
            selected: focusedBar?.isSelected,
            onIncrease: () => _moveSemanticBarFocus(1),
            onDecrease: () => _moveSemanticBarFocus(-1),
            child: focusChart,
          )
        : focusChart;

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

      final radialSeries = isRadial ? _effectiveRadialSeries : null;
      if (widget.showLegend && radialSeries != null) {
        final theme = widget.theme ?? ChartTheme.light;
        final legend = PieChartLegend(
          series: radialSeries,
          chartTheme: theme,
          selectedPointIndices: {
            for (final ref in _selectedPointRefs)
              if (ref.seriesId == radialSeries.id) ref.pointIndex,
          },
          onSliceTap: _activateRadialPointIndex,
          itemBuilder: widget.radialLegendItemBuilder,
          disableAnimations: _disableAnimations,
        );
        children.add(
          Expanded(
            child: _buildPieLegendLayout(
              chartContent: chartContent,
              legend: legend,
              style: theme.legendStyle,
            ),
          ),
        );
      } else {
        // Chart content takes available space.
        children.add(Expanded(child: chartContent));
      }

      // Legacy ChartLegend widget removed - overlay legend (LegendAnnotation)
      // is now used exclusively for legend rendering within the chart area.

      return RepaintBoundary(
        key: _previewBoundaryKey,
        child: ColoredBox(
          color: (widget.theme ?? ChartTheme.light).backgroundColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }

    return RepaintBoundary(
      key: _previewBoundaryKey,
      child: ColoredBox(
        color: (widget.theme ?? ChartTheme.light).backgroundColor,
        child: chartContent,
      ),
    );
  }

  Widget _buildPieLegendLayout({
    required Widget chartContent,
    required Widget legend,
    required LegendStyle style,
  }) {
    const gap = 8.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final positionedLegend = Padding(
          padding: const EdgeInsets.all(gap),
          child: legend,
        );
        final maximumBandHeight = math.min(160.0, constraints.maxHeight * 0.36);
        final maximumRailWidth = math.min(
          constraints.maxWidth,
          math.min(200.0, math.max(120.0, constraints.maxWidth * 0.28)),
        );

        Widget horizontalBand(Alignment alignment) {
          return Align(
            alignment: alignment,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maximumBandHeight),
              child: SingleChildScrollView(child: positionedLegend),
            ),
          );
        }

        Widget verticalRail(Alignment alignment) {
          return Align(
            alignment: alignment,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maximumRailWidth,
                maxHeight: math.max(0, constraints.maxHeight - gap * 2),
              ),
              child: IntrinsicWidth(
                child: SingleChildScrollView(child: positionedLegend),
              ),
            ),
          );
        }

        return switch (style.position) {
          LegendPosition.topLeft ||
          LegendPosition.topCenter ||
          LegendPosition.topRight => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              horizontalBand(switch (style.position) {
                LegendPosition.topLeft => Alignment.topLeft,
                LegendPosition.topRight => Alignment.topRight,
                _ => Alignment.topCenter,
              }),
              Expanded(child: chartContent),
            ],
          ),
          LegendPosition.bottomLeft ||
          LegendPosition.bottomCenter ||
          LegendPosition.bottomRight => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: chartContent),
              horizontalBand(switch (style.position) {
                LegendPosition.bottomLeft => Alignment.bottomLeft,
                LegendPosition.bottomRight => Alignment.bottomRight,
                _ => Alignment.bottomCenter,
              }),
            ],
          ),
          LegendPosition.centerLeft => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              verticalRail(Alignment.centerLeft),
              const SizedBox(width: gap),
              Expanded(child: chartContent),
            ],
          ),
          LegendPosition.centerRight => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: chartContent),
              const SizedBox(width: gap),
              verticalRail(Alignment.centerRight),
            ],
          ),
          LegendPosition.center => Stack(
            fit: StackFit.expand,
            children: [
              chartContent,
              Align(child: positionedLegend),
            ],
          ),
        };
      },
    );
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
    this.selectedTooltipSeriesId,
    this.selectedTooltipPointIndex,
    required this.showXScrollbar,
    required this.showYScrollbar,
    this.scrollbarTheme,
    this.interactionConfig,
    this.textScaleFactor = 1,
    this.onCursorChange,
    this.onAnnotationChanged,
    this.onElementHover,
    this.onDataHitActivate,
    this.onDataHitFocus,
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
  final String? selectedTooltipSeriesId;
  final int? selectedTooltipPointIndex;
  final bool showXScrollbar;
  final bool showYScrollbar;
  final ScrollbarConfig? scrollbarTheme;
  final InteractionConfig? interactionConfig;
  final double textScaleFactor;
  final void Function(MouseCursor cursor)? onCursorChange;
  final void Function(String annotationId, ChartAnnotation updatedAnnotation)?
  onAnnotationChanged;
  final void Function(ChartElement? element)? onElementHover;
  final ValueChanged<ChartDataHit>? onDataHitActivate;
  final ValueChanged<ChartDataHit>? onDataHitFocus;
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
        selectedTooltipSeriesId: selectedTooltipSeriesId,
        selectedTooltipPointIndex: selectedTooltipPointIndex,
        showXScrollbar: showXScrollbar,
        showYScrollbar: showYScrollbar,
        scrollbarTheme: scrollbarTheme,
        interactionConfig: interactionConfig,
        textScaleFactor: textScaleFactor,
        normalizationMode: normalizationMode,
        series: series,
        onCursorChange: onCursorChange,
        onAnnotationChanged: onAnnotationChanged,
        onElementHover: onElementHover,
        onDataHitActivate: onDataHitActivate,
        onDataHitFocus: onDataHitFocus,
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
      // Multi-axis state must be current before elements are regenerated.
      // Visibility changes can alter the effective axes without changing the
      // chart's explicit per-series normalization contract.
      ..setNormalizationMode(normalizationMode)
      ..setSeries(series)
      ..setMaxAxesPerSide(maxAxesPerSide)
      ..setAxisSwapMode(axisSwapMode)
      ..setElementGenerator(elementGenerator, elementGeneratorVersion)
      ..setXAxis(xAxis)
      ..setXAxisConfig(xAxisConfig)
      ..setYAxis(yAxis)
      ..setPrimaryYAxisConfig(primaryYAxisConfig)
      ..setTheme(theme)
      ..setTooltipsEnabled(tooltipsEnabled)
      ..setSelectedTooltipPoint(
        seriesId: selectedTooltipSeriesId,
        pointIndex: selectedTooltipPointIndex,
      )
      ..setShowXScrollbar(showXScrollbar)
      ..setShowYScrollbar(showYScrollbar)
      ..setScrollbarTheme(scrollbarTheme)
      ..setInteractionConfig(interactionConfig)
      ..setTextScaleFactor(textScaleFactor)
      ..setGridConfig(gridConfig)
      ..onViewportInteracted = onViewportInteracted
      ..onElementHover = onElementHover;
    renderObject
      ..onDataHitActivate = onDataHitActivate
      ..onDataHitFocus = onDataHitFocus;
  }
}

class _DonutCenterOverlay extends StatelessWidget {
  const _DonutCenterOverlay({
    required this.series,
    required this.chartTheme,
    required this.textScaleFactor,
    required this.selectedPointIndices,
    required this.animationProgress,
    required this.isEntranceAnimationComplete,
    required this.selectionProgress,
    required this.builder,
    required this.onTap,
  });

  final DonutChartSeries series;
  final ChartTheme chartTheme;
  final double textScaleFactor;
  final Set<int> selectedPointIndices;
  final double animationProgress;
  final bool isEntranceAnimationComplete;
  final double selectionProgress;
  final DonutCenterBuilder? builder;
  final DonutCenterTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fullSize = constraints.biggest;
        if (!fullSize.width.isFinite ||
            !fullSize.height.isFinite ||
            fullSize.isEmpty) {
          return const SizedBox.shrink();
        }
        const insets = ChartRenderBox.axislessPlotInsets;
        final plotSize = Size(
          math.max(0, fullSize.width - insets.horizontal),
          math.max(0, fullSize.height - insets.vertical),
        );
        if (plotSize.isEmpty) return const SizedBox.shrink();

        final element = PieSeriesElement(
          series: series,
          size: plotSize,
          theme: chartTheme,
          textScaleFactor: textScaleFactor,
          selectedPointIndices: selectedPointIndices,
          animationProgress: animationProgress,
          isEntranceAnimationComplete: isEntranceAnimationComplete,
          selectionProgress: selectionProgress,
          paintCenterContent: false,
          includeCenterSemantics: false,
        );
        final presentation = element.centerPresentation;
        final diameter = element.geometry.innerRadius * 2;
        if (presentation == null || diameter < 16) {
          return const SizedBox.shrink();
        }

        final selectedSlice = element.selectedCenterSlice;
        final selectedIndices =
            selectedSlice?.sourcePointIndices ?? const <int>[];
        final selectedSources = <ChartDataPoint>[
          for (final index in selectedIndices) series.points[index],
        ];
        final data = DonutCenterData(
          seriesId: series.id,
          seriesName: series.name,
          unit: series.unit,
          total: series.total,
          label: presentation.label,
          valueLabel: presentation.value,
          semanticLabel: presentation.semanticLabel,
          availableDiameter: diameter,
          defaultLabelStyle: _centerTextStyle(
            source:
                series.centerContent.labelStyle?.textStyle ??
                chartTheme.pieChartTheme.centerLabelStyle?.textStyle,
            chartTheme: chartTheme,
            defaultFontSize: 12,
            defaultWeight: FontWeight.w500,
          ),
          defaultValueStyle: _centerTextStyle(
            source:
                series.centerContent.valueStyle?.textStyle ??
                chartTheme.pieChartTheme.centerValueStyle?.textStyle,
            chartTheme: chartTheme,
            defaultFontSize: 22,
            defaultWeight: FontWeight.w700,
          ),
          selectionColor: chartTheme.focusBorderColor,
          selectedPoint: selectedSlice?.point,
          selectedCategory: selectedSlice?.point.label?.trim(),
          selectedValue: selectedSlice?.point.y,
          selectedShare: selectedSlice == null || series.total <= 0
              ? null
              : selectedSlice.point.y / series.total,
          selectedSourcePointIndices: selectedIndices,
          selectedSourcePoints: selectedSources,
        );

        final plotOffset = Offset(insets.left, insets.top);
        final center = element.geometry.center + plotOffset;
        final centerRect = Rect.fromCircle(
          center: center,
          radius: element.geometry.innerRadius,
        );
        final customContent = builder?.call(context, data);
        final centerContent = Padding(
          padding: EdgeInsets.all(math.max(4, diameter * 0.06)),
          child: customContent ?? const SizedBox.expand(),
        );
        final Widget interactive = onTap == null
            ? centerContent
            : Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: isEntranceAnimationComplete
                      ? () => onTap!(data)
                      : null,
                  customBorder: const CircleBorder(),
                  excludeFromSemantics: true,
                  child: centerContent,
                ),
              );
        final animationMode =
            series.radialStyle.animationMode ??
            chartTheme.pieChartTheme.animationMode;
        final opacity = animationMode == PieAnimationMode.fade
            ? animationProgress.clamp(0.0, 1.0)
            : 1.0;

        return Stack(
          children: [
            Positioned.fromRect(
              rect: centerRect,
              child: Opacity(
                opacity: opacity,
                child: Semantics(
                  container: true,
                  button: onTap != null,
                  excludeSemantics: true,
                  label: data.semanticLabel,
                  onTap: onTap == null || !isEntranceAnimationComplete
                      ? null
                      : () => onTap!(data),
                  child: ClipOval(child: interactive),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  TextStyle _centerTextStyle({
    required TextStyle? source,
    required ChartTheme chartTheme,
    required double defaultFontSize,
    required FontWeight defaultWeight,
  }) {
    final color =
        source?.color ??
        chartTheme.axisStyle.labelStyle.color ??
        const Color(0xFF1F2937);
    final fontSize = (source?.fontSize ?? defaultFontSize) * textScaleFactor;
    return TextStyle(
      color: color,
      fontFamily: chartTheme.typographyTheme.fontFamily,
      fontSize: fontSize,
      fontWeight: defaultWeight,
      height: 1.1,
    ).merge(source).copyWith(fontSize: fontSize);
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

class _ActiveBarSeriesTransition {
  const _ActiveBarSeriesTransition({required this.from, required this.to});

  final BarChartSeries from;
  final BarChartSeries to;
}

class _ActiveRadialSeriesTransition {
  const _ActiveRadialSeriesTransition({required this.from, required this.to});

  final RadialCategorySeries from;
  final RadialCategorySeries to;
}

class _ActivePathSeriesTransition {
  const _ActivePathSeriesTransition({
    required this.from,
    required this.to,
    required this.window,
  });

  final ChartSeries from;
  final ChartSeries to;
  final PathAnimationWindow window;
}

class _PendingPathSeriesTransition {
  const _PendingPathSeriesTransition({required this.from, required this.to});

  final ChartSeries from;
  final ChartSeries to;
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
