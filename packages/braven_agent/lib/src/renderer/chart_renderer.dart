import 'package:braven_charts/braven_charts.dart' as charts;
import 'package:flutter/material.dart';

import '../models/models.dart' as models;

/// Renders chart configurations into Flutter widgets.
///
/// Converts [models.ChartConfiguration] objects from the braven_agent package
/// into [charts.BravenChartPlus] widgets provided by the braven_charts library.
/// This is the bridge between LLM-produced configuration models and on-screen
/// rendering.
///
/// The renderer accepts two input shapes:
/// - A strongly typed [models.ChartConfiguration]
/// - A JSON-style [Map<String, dynamic>] that can be parsed into a config
///
/// If parsing fails or the shape is unsupported, a friendly error widget is
/// returned instead of throwing.
///
/// Supported chart types: line, area, bar, scatter.
///
/// ## Example
///
/// ```dart
/// // Create a persistent controller for annotation state
/// final annotationController = AnnotationController();
///
/// // Render chart with the controller
/// final renderer = ChartRenderer(annotationController: annotationController);
/// final widget = renderer.render(chartConfiguration);
/// ```
class ChartRenderer {
  /// Creates a [ChartRenderer] with an optional persistent annotation controller.
  ///
  /// If [annotationController] is provided, it will be updated with annotations
  /// from the chart configuration and reused across renders. This preserves
  /// annotation state (e.g., drag positions) between parent widget rebuilds.
  ///
  /// If not provided, a new controller is created for each render (legacy behavior).
  const ChartRenderer({this.annotationController});

  /// Optional persistent annotation controller.
  ///
  /// When provided, the renderer updates this controller's annotations
  /// instead of creating a new controller each render. This is essential
  /// for preserving user interactions (e.g., drag-to-move annotations).
  final charts.AnnotationController? annotationController;

  /// Builds a widget for the provided chart configuration or raw chart data.
  ///
  /// Accepts either:
  /// - A [models.ChartConfiguration] instance
  /// - A [Map<String, dynamic>] that can be parsed as [models.ChartConfiguration]
  ///
  /// Returns an error widget if the format is unsupported or parsing fails.
  Widget render(dynamic chart) {
    if (chart is models.ChartConfiguration) {
      return _renderConfiguration(chart);
    }

    // Handle Map format (from CreateChartTool output)
    if (chart is Map<String, dynamic>) {
      try {
        final config = models.ChartConfiguration.fromJson(chart);
        return _renderConfiguration(config);
      } catch (e) {
        return _errorWidget('Invalid chart configuration: $e');
      }
    }

    return _errorWidget('Unsupported chart format');
  }

  Widget _renderConfiguration(models.ChartConfiguration config) {
    try {
      // Convert SeriesConfig to ChartSeries
      if (config.series.isEmpty) {
        return _errorWidget('No series data provided');
      }

      final series = config.series.map((seriesConfig) {
        final dataPoints = seriesConfig.data;
        final points = <charts.ChartDataPoint>[];
        for (var index = 0; index < dataPoints.length; index += 1) {
          final dataPoint = dataPoints[index];
          final xValue = dataPoint.x;
          final yValue = dataPoint.y;
          points.add(charts.ChartDataPoint(x: xValue, y: yValue));
        }

        // Parse color from SeriesConfig
        final seriesColor = _parseColor(seriesConfig.color);

        // Build YAxisConfig from per-series nested yAxis field (FR-001)
        final yAxisConfig = _buildYAxisConfigFromSeries(seriesConfig);

        // CRITICAL: showPoints is the ONLY control for markers.
        // Previous logic tried to implicitly enable markers when markerSize was non-default,
        // but this caused bugs: LLM setting showPoints: false was ignored if markerSize != 4.0.
        // Now: showPoints is authoritative. LLM must set showPoints: true to see markers.
        final effectiveShowPoints = seriesConfig.showPoints;

        // Always pass markerSize to dataPointMarkerRadius - this is the size IF markers are shown
        // The showDataPointMarkers flag controls visibility, not the radius value
        final effectiveMarkerRadius = seriesConfig.markerSize;

        return _createSeriesForType(
          seriesConfig.type,
          id: seriesConfig.id,
          name: seriesConfig.name,
          points: points,
          color: seriesColor,
          strokeWidth: seriesConfig.strokeWidth,
          yAxisConfig: yAxisConfig,
          // Per FR-003: yAxisId removed - yAxis is now inline on each series
          fillOpacity: seriesConfig.fillOpacity,
          tension: seriesConfig.tension,
          markerRadius: seriesConfig.markerSize,
          dataPointMarkerRadius: effectiveMarkerRadius,
          showDataPointMarkers: effectiveShowPoints,
          interpolation: seriesConfig.interpolation,
          unit: seriesConfig.unit,
          barWidthPercent: seriesConfig.barWidthPercent,
          barWidthPixels: seriesConfig.barWidthPixels,
          barMinWidth: seriesConfig.barMinWidth,
          barMaxWidth: seriesConfig.barMaxWidth,
        );
      }).toList();

      // Convert AnnotationConfig to ChartAnnotation
      final annotations = _convertAnnotations(config.annotations);

      // Build X-axis config - wire all properties from config
      // Explicit min/max values are passed through verbatim (no padding applied)
      // Padding is only for auto-calculated bounds (handled by the chart widget itself)
      final configXAxis = config.xAxis;
      final double? xMin = configXAxis?.min;
      final double? xMax = configXAxis?.max;

      final xAxisConfig = charts.XAxisConfig(
        label: configXAxis?.label ?? 'X',
        unit: configXAxis?.unit,
        min: xMin,
        max: xMax,
      );

      // Build Y-axis config from first yAxis
      final yAxisConfig = config.yAxes.isNotEmpty
          ? charts.YAxisConfig(
              label: config.yAxes.first.label ?? 'Y',
              position: charts.YAxisPosition.left,
            )
          : charts.YAxisConfig(
              label: 'Y',
              position: charts.YAxisPosition.left,
            );

      // Build theme from config
      final baseTheme = _buildChartTheme(config);

      // Get legend settings
      final showLegend = config.showLegend;
      final legendStyle = _buildLegendStyle(config);

      // Get scrollbar settings
      final showXScrollbar = config.showScrollbar;
      final showYScrollbar = config.showScrollbar;

      // Get grid settings - if grid is disabled, modify the theme's gridStyle
      // Use GridConfig if BravenChartPlus supports it, otherwise use theme.gridStyle
      final gridVisible = config.showGrid;
      final chartTheme = gridVisible
          ? baseTheme
          : baseTheme.copyWith(
              gridStyle: const charts.GridStyle(
                majorColor: Colors.transparent,
                majorWidth: 0.0,
                showMinor: false,
              ),
            );

      // Build GridConfig for explicit grid control
      final gridConfig = gridVisible
          ? null // Use default
          : const charts.GridConfig(horizontal: false, vertical: false);

      // Convert normalizationMode
      final normalizationMode = _getNormalizationMode(config);

      // Build InteractionConfig from configuration
      final interactionConfig = _buildInteractionConfig(config);

      // Determine chart dimensions
      final chartWidth = config.width;
      final chartHeight = config.height ?? 350.0;
      final backgroundColor = _parseColor(config.backgroundColor) ?? Colors.white;

      // Create annotation controller if we have annotations
      // Using annotationController (recommended) instead of deprecated annotations list
      final annotationController = annotations.isNotEmpty ? charts.AnnotationController(initialAnnotations: annotations) : null;

      return SizedBox(
        width: chartWidth,
        height: chartHeight,
        child: charts.BravenChartPlus(
            series: series,
            xAxisConfig: xAxisConfig,
            yAxis: yAxisConfig,
            annotationController: annotationController,
            theme: chartTheme,
            grid: gridConfig,
            showLegend: showLegend,
            legendStyle: legendStyle,
            showXScrollbar: showXScrollbar,
            showYScrollbar: showYScrollbar,
            normalizationMode: normalizationMode,
            interactionConfig: interactionConfig,
            // interactionConfig: rconst InteractionConfig(crosshair: CrosshairConfig(displayMode: CrosshairDisplayMode.standard)),
            title: config.title,
            subtitle: config.subtitle,
            backgroundColor: backgroundColor),
      );
    } catch (e) {
      return _errorWidget('Failed to render chart: $e');
    }
  }

  /// Parse hex color string to Color
  Color? _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return null;
    }

    // Handle hex color format (#RGB or #RRGGBB)
    if (colorString.startsWith('#')) {
      final hex = colorString.substring(1);
      if (hex.length == 3) {
        // #RGB -> #RRGGBB
        final r = hex[0] + hex[0];
        final g = hex[1] + hex[1];
        final b = hex[2] + hex[2];
        return Color(int.parse('FF$r$g$b', radix: 16));
      } else if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        // #AARRGGBB
        return Color(int.parse(hex, radix: 16));
      }
    }

    return null;
  }

  /// Build ChartTheme from configuration
  charts.ChartTheme _buildChartTheme(models.ChartConfiguration config) {
    // Use useDarkTheme boolean directly (it has a default value)
    if (config.useDarkTheme) {
      return charts.ChartTheme.dark;
    }
    return charts.ChartTheme.light;
  }

  /// Build LegendStyle from configuration
  charts.LegendStyle _buildLegendStyle(models.ChartConfiguration config) {
    // Theme for base style
    final baseStyle = config.useDarkTheme ? charts.LegendStyle.dark : charts.LegendStyle.light;

    // Map LegendPosition enum to braven_charts LegendPosition
    charts.LegendPosition position;
    switch (config.legendPosition) {
      case models.LegendPosition.top:
        position = charts.LegendPosition.topCenter;
      case models.LegendPosition.left:
        position = charts.LegendPosition.centerLeft;
      case models.LegendPosition.right:
        position = charts.LegendPosition.centerRight;
      case models.LegendPosition.topLeft:
        position = charts.LegendPosition.topLeft;
      case models.LegendPosition.topRight:
        position = charts.LegendPosition.topRight;
      case models.LegendPosition.bottomLeft:
        position = charts.LegendPosition.bottomLeft;
      case models.LegendPosition.bottomRight:
        position = charts.LegendPosition.bottomRight;
      case models.LegendPosition.bottom:
        position = charts.LegendPosition.bottomCenter;
    }

    return baseStyle.copyWith(position: position);
  }

  /// Get normalization mode from configuration
  ///
  /// Converts NormalizationModeConfig to braven_charts.NormalizationMode
  charts.NormalizationMode _getNormalizationMode(models.ChartConfiguration config) {
    switch (config.normalizationMode) {
      case models.NormalizationModeConfig.none:
        return charts.NormalizationMode.none;
      case models.NormalizationModeConfig.auto:
        return charts.NormalizationMode.auto;
      case models.NormalizationModeConfig.perSeries:
        return charts.NormalizationMode.perSeries;
    }
  }

  /// Build InteractionConfig from configuration
  ///
  /// Maps ChartConfiguration style to BravenChartPlus InteractionConfig.
  /// Uses default interactions (pan, zoom, crosshair, tooltip enabled).
  ///
  /// When tooltip or crosshair is enabled, uses CrosshairDisplayMode.tracking
  /// which is required for perSeries normalization mode to work correctly.
  charts.InteractionConfig _buildInteractionConfig(models.ChartConfiguration config) {
    if (config.interactions == null) {
      return const charts.InteractionConfig(
        enablePan: true,
        enableZoom: true,
        crosshair: charts.CrosshairConfig(
          enabled: true,
          displayMode: charts.CrosshairDisplayMode.tracking,
        ),
        tooltip: charts.TooltipConfig(enabled: true),
      );
    }

    final interactionsMap = config.interactions!;
    final enablePan = interactionsMap['pan'] as bool? ?? true;
    final enableZoom = interactionsMap['zoom'] as bool? ?? true;
    final crosshairEnabled = interactionsMap['crosshair'] as bool? ?? true;
    final tooltipEnabled = interactionsMap['tooltip'] as bool? ?? true;
    final useTrackingMode = tooltipEnabled || crosshairEnabled;

    return charts.InteractionConfig(
      enablePan: enablePan,
      enableZoom: enableZoom,
      crosshair: charts.CrosshairConfig(
        enabled: crosshairEnabled,
        displayMode: useTrackingMode ? charts.CrosshairDisplayMode.tracking : charts.CrosshairDisplayMode.standard,
      ),
      tooltip: charts.TooltipConfig(enabled: tooltipEnabled),
    );
  }

  /// Convert AnnotationConfig list to ChartAnnotation list
  List<charts.ChartAnnotation> _convertAnnotations(List<models.AnnotationConfig>? annotations) {
    if (annotations == null || annotations.isEmpty) {
      return [];
    }

    final result = <charts.ChartAnnotation>[];

    for (final annotationConfig in annotations) {
      try {
        final annotation = _convertAnnotationConfig(annotationConfig);
        if (annotation != null) {
          result.add(annotation);
        }
      } catch (_) {
        // Skip failed annotation conversions silently
      }
    }

    return result;
  }

  /// Convert a single AnnotationConfig to a ChartAnnotation
  charts.ChartAnnotation? _convertAnnotationConfig(models.AnnotationConfig config) {
    final color = _parseColor(config.color) ?? Colors.red;

    switch (config.type) {
      case models.AnnotationType.referenceLine:
        // Convert to ThresholdAnnotation
        final isHorizontal = config.orientation != models.Orientation.vertical;
        final value = config.value;
        final lineWidth = config.lineWidth ?? 2.0;

        return charts.ThresholdAnnotation(
          id: 'annotation_${DateTime.now().millisecondsSinceEpoch}',
          axis: isHorizontal ? charts.AnnotationAxis.y : charts.AnnotationAxis.x,
          value: value ?? 0.0,
          seriesId: config.seriesId, // Required for perSeries normalization mode
          label: config.label,
          lineColor: color,
          lineWidth: lineWidth,
          dashPattern: config.dashPattern,
        );

      case models.AnnotationType.zone:
        // Convert to RangeAnnotation
        final isHorizontal = config.orientation != models.Orientation.vertical;
        final minValue = config.minValue ?? 0.0;
        final maxValue = config.maxValue ?? 0.0;
        final opacity = config.opacity ?? 0.3;
        return charts.RangeAnnotation(
          id: 'annotation_${DateTime.now().millisecondsSinceEpoch}',
          startY: isHorizontal ? minValue : null,
          endY: isHorizontal ? maxValue : null,
          startX: isHorizontal ? null : minValue,
          endX: isHorizontal ? null : maxValue,
          seriesId: config.seriesId, // Required for perSeries normalization mode
          label: config.label,
          fillColor: color.withOpacity(opacity),
          borderColor: color,
        );

      case models.AnnotationType.textLabel:
        // TextAnnotation uses screen coordinates (pixels), not data coordinates
        // Support semantic positions: topLeft, topCenter, topRight, centerLeft, center, centerRight, bottomLeft, bottomCenter, bottomRight
        final text = config.text ?? config.label ?? '';
        final fontSize = config.fontSize ?? 12.0;
        final positionOffset = _getTextAnnotationPosition(config.position);
        final anchor = _getTextAnnotationAnchor(config.position);
        return charts.TextAnnotation(
          id: 'annotation_${DateTime.now().millisecondsSinceEpoch}',
          position: positionOffset,
          text: text,
          anchor: anchor,
          style: charts.AnnotationStyle(
            textStyle: TextStyle(
              fontSize: fontSize,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        );

      case models.AnnotationType.marker:
        // Convert to PinAnnotation
        final x = config.x ?? 0.0;
        final y = config.y ?? 0.0;
        return charts.PinAnnotation(
          id: 'annotation_${DateTime.now().millisecondsSinceEpoch}',
          x: x,
          y: y,
          label: config.label,
          markerColor: color,
        );

      case models.AnnotationType.trendLine:
        // Convert to TrendAnnotation
        final trendType = _mapTrendType(config.trendType);
        if (trendType == null) return null;

        // For moving average types, windowSize is required by BravenChartPlus.
        // Default to 5 if not specified by the agent.
        int? windowSize = config.windowSize;
        if ((trendType == charts.TrendType.movingAverage || trendType == charts.TrendType.exponentialMovingAverage) && windowSize == null) {
          windowSize = 5; // Sensible default for smoothing
        }

        return charts.TrendAnnotation(
          id: 'annotation_${DateTime.now().millisecondsSinceEpoch}',
          seriesId: config.seriesId ?? '', // Required for TrendAnnotation
          trendType: trendType,
          windowSize: windowSize,
          degree: config.degree ?? 2,
          label: config.label,
          lineColor: color,
          lineWidth: config.lineWidth ?? 2.0,
          dashPattern: config.dashPattern,
        );
    }
  }

  /// Maps agent TrendType enum to BravenChartPlus TrendType enum.
  charts.TrendType? _mapTrendType(models.TrendType? trendType) {
    if (trendType == null) return null;
    switch (trendType) {
      case models.TrendType.linear:
        return charts.TrendType.linear;
      case models.TrendType.polynomial:
        return charts.TrendType.polynomial;
      case models.TrendType.movingAverage:
        return charts.TrendType.movingAverage;
      case models.TrendType.exponentialMovingAverage:
        return charts.TrendType.exponentialMovingAverage;
    }
  }

  /// Builds a YAxisConfig from per-series Y-axis configuration.
  ///
  /// Returns null if no Y-axis configuration is specified on the series.
  charts.YAxisConfig? _buildYAxisConfigFromSeries(models.SeriesConfig seriesConfig) {
    // Per FR-001: Use nested yAxis field instead of flat fields
    final yAxis = seriesConfig.yAxis;
    if (yAxis == null) {
      return null;
    }

    // Map position enum to YAxisPosition enum
    charts.YAxisPosition position;
    switch (yAxis.position) {
      case models.AxisPosition.left:
        position = charts.YAxisPosition.left;
      case models.AxisPosition.right:
        position = charts.YAxisPosition.right;
      case models.AxisPosition.leftOuter:
        position = charts.YAxisPosition.leftOuter;
      case models.AxisPosition.rightOuter:
        position = charts.YAxisPosition.rightOuter;
    }

    // Parse axis color
    final axisColor = _parseColor(yAxis.color);

    return charts.YAxisConfig(
      position: position,
      label: yAxis.label,
      unit: yAxis.unit,
      color: axisColor,
      min: yAxis.min,
      max: yAxis.max,
    );
  }

  /// Maps Interpolation enum to BravenChartPlus LineInterpolation enum.
  charts.LineInterpolation _mapInterpolation(models.Interpolation interpolation) {
    switch (interpolation) {
      case models.Interpolation.linear:
        return charts.LineInterpolation.linear;
      case models.Interpolation.bezier:
        return charts.LineInterpolation.bezier;
      case models.Interpolation.stepped:
        return charts.LineInterpolation.stepped;
      case models.Interpolation.monotone:
        return charts.LineInterpolation.monotone;
    }
  }

  charts.ChartSeries _createSeriesForType(
    models.ChartType type, {
    required String id,
    String? name,
    required List<charts.ChartDataPoint> points,
    Color? color,
    double strokeWidth = 2.0,
    charts.YAxisConfig? yAxisConfig,
    String? yAxisId,
    double? fillOpacity,
    double? tension,
    double? markerRadius,
    double? dataPointMarkerRadius,
    bool showDataPointMarkers = false,
    models.Interpolation interpolation = models.Interpolation.linear,
    String? unit,
    double? barWidthPercent,
    double? barWidthPixels,
    double? barMinWidth,
    double? barMaxWidth,
  }) {
    switch (type) {
      case models.ChartType.line:
        return charts.LineChartSeries(
          id: id,
          name: name,
          points: points,
          color: color,
          interpolation: _mapInterpolation(interpolation),
          tension: tension ?? 0.25,
          strokeWidth: strokeWidth,
          yAxisConfig: yAxisConfig,
          yAxisId: yAxisId,
          showDataPointMarkers: showDataPointMarkers,
          dataPointMarkerRadius: dataPointMarkerRadius ?? 3.0,
          unit: unit,
        );
      case models.ChartType.area:
        return charts.AreaChartSeries(
          id: id,
          name: name,
          points: points,
          color: color,
          interpolation: _mapInterpolation(interpolation),
          tension: tension ?? 0.25,
          strokeWidth: strokeWidth,
          fillOpacity: fillOpacity ?? 0.3,
          yAxisConfig: yAxisConfig,
          yAxisId: yAxisId,
          showDataPointMarkers: showDataPointMarkers,
          dataPointMarkerRadius: dataPointMarkerRadius ?? 3.0,
          unit: unit,
        );
      case models.ChartType.bar:
        return charts.BarChartSeries(
          id: id,
          name: name,
          points: points,
          color: color,
          barWidthPercent: barWidthPercent ?? 0.7,
          barWidthPixels: barWidthPixels,
          minWidth: barMinWidth ?? 4.0,
          maxWidth: barMaxWidth ?? 100.0,
          yAxisConfig: yAxisConfig,
          yAxisId: yAxisId,
          unit: unit,
        );
      case models.ChartType.scatter:
        return charts.ScatterChartSeries(
          id: id,
          name: name,
          points: points,
          color: color,
          markerRadius: markerRadius ?? 5.0,
          yAxisConfig: yAxisConfig,
          yAxisId: yAxisId,
          unit: unit,
        );
    }
  }

  /// Converts a semantic position to screen coordinates.
  /// Positions are relative to chart area with sensible defaults.
  /// Supported: topLeft, topCenter, topRight, centerLeft, center, centerRight,
  /// bottomLeft, bottomCenter, bottomRight
  Offset _getTextAnnotationPosition(models.AnnotationPosition? position) {
    // Default chart area dimensions for positioning
    // These are approximate - the annotation will be placed in the general area
    const double left = 60.0; // Account for Y-axis labels
    const double top = 30.0; // Account for title area
    const double centerX = 300.0; // Approximate center
    const double centerY = 150.0; // Approximate center
    const double right = 540.0; // Approximate right edge
    const double bottom = 280.0; // Approximate bottom

    switch (position) {
      case models.AnnotationPosition.topCenter:
        return const Offset(centerX, top);
      case models.AnnotationPosition.topRight:
        return const Offset(right, top);
      case models.AnnotationPosition.centerLeft:
        return const Offset(left, centerY);
      case models.AnnotationPosition.center:
        return const Offset(centerX, centerY);
      case models.AnnotationPosition.centerRight:
        return const Offset(right, centerY);
      case models.AnnotationPosition.bottomLeft:
        return const Offset(left, bottom);
      case models.AnnotationPosition.bottomCenter:
        return const Offset(centerX, bottom);
      case models.AnnotationPosition.bottomRight:
        return const Offset(right, bottom);
      case models.AnnotationPosition.topLeft:
      case null:
        // Default to top-left with offset
        return const Offset(left, top);
    }
  }

  /// Gets the appropriate anchor for the semantic position.
  /// The anchor determines which corner of the text box is at the position.
  charts.AnnotationAnchor _getTextAnnotationAnchor(models.AnnotationPosition? position) {
    switch (position) {
      case models.AnnotationPosition.topCenter:
        return charts.AnnotationAnchor.topCenter;
      case models.AnnotationPosition.topRight:
        return charts.AnnotationAnchor.topRight;
      case models.AnnotationPosition.centerLeft:
        return charts.AnnotationAnchor.centerLeft;
      case models.AnnotationPosition.center:
        return charts.AnnotationAnchor.center;
      case models.AnnotationPosition.centerRight:
        return charts.AnnotationAnchor.centerRight;
      case models.AnnotationPosition.bottomLeft:
        return charts.AnnotationAnchor.bottomLeft;
      case models.AnnotationPosition.bottomCenter:
        return charts.AnnotationAnchor.bottomCenter;
      case models.AnnotationPosition.bottomRight:
        return charts.AnnotationAnchor.bottomRight;
      case models.AnnotationPosition.topLeft:
      case null:
        return charts.AnnotationAnchor.topLeft;
    }
  }

  Widget _errorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        message,
        style: TextStyle(fontSize: 14, color: Colors.red.shade900),
      ),
    );
  }
}
