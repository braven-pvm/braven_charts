import 'dart:convert';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../models/annotation_config.dart';
import '../models/chart_configuration.dart' as agentic;

/// Renders chart configurations into Flutter widgets.
class ChartRenderer {
  const ChartRenderer();

  /// Builds a widget for the provided chart configuration or raw chart data.
  Widget render(dynamic chart) {
    if (chart is agentic.ChartConfiguration) {
      return _renderConfiguration(chart);
    }

    // Handle Map format (from CreateChartTool output)
    if (chart is Map<String, dynamic>) {
      try {
        final config = agentic.ChartConfiguration.fromJson(chart);
        return _renderConfiguration(config);
      } catch (e) {
        return _errorWidget('Invalid chart configuration: $e');
      }
    }

    return _errorWidget('Unsupported chart format');
  }

  Widget _renderConfiguration(agentic.ChartConfiguration config) {
    // DEBUG: Log chart configuration being rendered
    debugPrint('=== RENDERING CHART ===');
    _debugPrintChartJson(config);

    try {
      // Convert SeriesConfig to ChartSeries
      if (config.series.isEmpty) {
        return _errorWidget('No series data provided');
      }

      final series = config.series.map((seriesConfig) {
        final dataPoints = seriesConfig.data ?? [];
        final points = <ChartDataPoint>[];
        for (var index = 0; index < dataPoints.length; index += 1) {
          final dataPoint = dataPoints[index];
          double xValue;
          double yValue;

          if (dataPoint is Map<String, dynamic>) {
            final x = dataPoint['x'];
            final y = dataPoint['y'];
            xValue = (x is num) ? x.toDouble() : index.toDouble();
            yValue = (y is num) ? y.toDouble() : 0.0;
          } else if (dataPoint is List && dataPoint.length >= 2) {
            final x = dataPoint[0];
            final y = dataPoint[1];
            xValue = (x is num) ? x.toDouble() : index.toDouble();
            yValue = (y is num) ? y.toDouble() : 0.0;
          } else if (dataPoint is num) {
            xValue = index.toDouble();
            yValue = dataPoint.toDouble();
          } else {
            xValue = index.toDouble();
            yValue = 0.0;
          }

          points.add(ChartDataPoint(x: xValue, y: yValue));
        }

        // Parse color from SeriesConfig
        final seriesColor = _parseColor(seriesConfig.color);

        // Map to the appropriate concrete series type based on chart type
        return _createSeriesForType(
          config.type,
          id: seriesConfig.id,
          name: seriesConfig.name,
          points: points,
          color: seriesColor,
          strokeWidth: seriesConfig.strokeWidth,
        );
      }).toList();

      // Convert AnnotationConfig to ChartAnnotation
      final annotations = _convertAnnotations(config.annotations);

      // Build X-axis config
      final xAxisConfig = XAxisConfig(
        label: config.xAxis?.label ?? 'X',
      );

      // Build Y-axis config from first yAxis
      final yAxisConfig = config.yAxes.isNotEmpty
          ? YAxisConfig(
              label: config.yAxes.first.label ?? 'Y',
              position: YAxisPosition.left,
            )
          : YAxisConfig(
              label: 'Y',
              position: YAxisPosition.left,
            );

      // Build theme from config
      final baseTheme = _buildChartTheme(config);

      // Get legend settings
      final showLegend = _getLegendVisible(config);
      final legendStyle = _buildLegendStyle(config);

      // Get scrollbar settings
      final showXScrollbar = _getScrollbarEnabled(config);
      final showYScrollbar = _getScrollbarEnabled(config);

      // Get grid settings - if grid is disabled, modify the theme's gridStyle
      // Note: BravenChartPlus.grid (GridConfig) is not implemented yet, so we use theme.gridStyle
      final gridVisible = _getGridVisible(config);
      final chartTheme = gridVisible
          ? baseTheme
          : baseTheme.copyWith(
              gridStyle: const GridStyle(
                majorColor: Colors.transparent,
                majorWidth: 0.0,
                showMinor: false,
              ),
            );

      // Convert normalizationMode
      final normalizationMode = _getNormalizationMode(config);

      return SizedBox(
        height: 350,
        child: BravenChartPlus(
          series: series,
          xAxisConfig: xAxisConfig,
          yAxis: yAxisConfig,
          annotations: annotations,
          theme: chartTheme,
          showLegend: showLegend,
          legendStyle: legendStyle,
          showXScrollbar: showXScrollbar,
          showYScrollbar: showYScrollbar,
          normalizationMode: normalizationMode,
        ),
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
  ChartTheme _buildChartTheme(agentic.ChartConfiguration config) {
    // Check explicit useDarkTheme first, then fall back to theme string
    if (config.useDarkTheme == true) {
      return ChartTheme.dark;
    } else if (config.useDarkTheme == false) {
      return ChartTheme.light;
    }
    // Fall back to theme name string
    final themeName = config.theme?.toLowerCase() ?? 'light';
    return themeName == 'dark' ? ChartTheme.dark : ChartTheme.light;
  }

  /// Get grid visibility from configuration
  bool _getGridVisible(agentic.ChartConfiguration config) {
    // Check explicit showGrid first
    if (config.showGrid != null) {
      return config.showGrid!;
    }
    // Fall back to grid map
    if (config.grid == null) return true; // Default to visible
    if (config.grid is Map) {
      return (config.grid as Map)['visible'] == true;
    }
    return true;
  }

  /// Get legend visibility from configuration
  bool _getLegendVisible(agentic.ChartConfiguration config) {
    // Check explicit showLegend first
    if (config.showLegend != null) {
      return config.showLegend!;
    }
    // Fall back to legend map
    if (config.legend == null) return true; // Default to visible
    if (config.legend is Map) {
      return (config.legend as Map)['visible'] != false;
    }
    return true;
  }

  /// Build LegendStyle from configuration
  LegendStyle _buildLegendStyle(agentic.ChartConfiguration config) {
    // Theme for base style
    final useDark = config.useDarkTheme == true || (config.theme?.toLowerCase() ?? 'light') == 'dark';
    final baseStyle = useDark ? LegendStyle.dark : LegendStyle.light;

    // Check explicit legendPosition first
    String? positionStr = config.legendPosition;

    // Fall back to legend map position
    if (positionStr == null && config.legend is Map) {
      positionStr = (config.legend as Map)['position'] as String?;
    }

    if (positionStr == null) {
      return baseStyle;
    }

    LegendPosition position;
    switch (positionStr.toLowerCase()) {
      case 'top':
        position = LegendPosition.topCenter;
        break;
      case 'left':
        position = LegendPosition.centerLeft;
        break;
      case 'right':
        position = LegendPosition.centerRight;
        break;
      case 'bottom':
      default:
        position = LegendPosition.bottomCenter;
        break;
    }

    return baseStyle.copyWith(position: position);
  }

  /// Get scrollbar enabled from configuration
  bool _getScrollbarEnabled(agentic.ChartConfiguration config) {
    // Check explicit showScrollbar first
    if (config.showScrollbar != null) {
      return config.showScrollbar!;
    }
    // Fall back to interactions map
    if (config.interactions == null) return false; // Default to disabled
    if (config.interactions is Map) {
      final scrollbar = (config.interactions as Map)['scrollbar'];
      if (scrollbar is Map) {
        return scrollbar['enabled'] == true;
      }
    }
    return false;
  }

  /// Get normalization mode from configuration
  ///
  /// Converts agentic.NormalizationModeConfig to braven_charts.NormalizationMode
  NormalizationMode? _getNormalizationMode(agentic.ChartConfiguration config) {
    if (config.normalizationMode == null) {
      return null; // Let BravenChartPlus use its default
    }
    switch (config.normalizationMode!) {
      case agentic.NormalizationModeConfig.none:
        return NormalizationMode.none;
      case agentic.NormalizationModeConfig.auto:
        return NormalizationMode.auto;
      case agentic.NormalizationModeConfig.perSeries:
        return NormalizationMode.perSeries;
    }
  }

  /// Convert AnnotationConfig list to ChartAnnotation list
  List<ChartAnnotation> _convertAnnotations(List<dynamic>? annotations) {
    if (annotations == null || annotations.isEmpty) {
      return [];
    }

    final result = <ChartAnnotation>[];

    for (final annotationData in annotations) {
      try {
        final AnnotationConfig annotationConfig;
        if (annotationData is AnnotationConfig) {
          annotationConfig = annotationData;
        } else if (annotationData is Map<String, dynamic>) {
          annotationConfig = AnnotationConfig.fromJson(annotationData);
        } else {
          // Skip unknown annotation formats silently
          continue;
        }

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
  ChartAnnotation? _convertAnnotationConfig(AnnotationConfig config) {
    final color = _parseColor(config.color) ?? Colors.red;
    final lineWidth = config.lineWidth ?? 2.0;

    switch (config.type) {
      case 'referenceLine':
        // Convert to ThresholdAnnotation
        final isHorizontal = config.orientation != 'vertical';
        final value = config.value ?? 0.0;
        return ThresholdAnnotation(
          id: 'annotation_${DateTime.now().millisecondsSinceEpoch}',
          axis: isHorizontal ? AnnotationAxis.y : AnnotationAxis.x,
          value: value,
          label: config.label,
          lineColor: color,
          lineWidth: lineWidth,
          dashPattern: config.dashPattern,
        );

      case 'zone':
        // Convert to RangeAnnotation
        final isHorizontal = config.orientation != 'vertical';
        final minValue = config.minValue ?? 0.0;
        final maxValue = config.maxValue ?? 0.0;
        final opacity = config.opacity ?? 0.3;
        return RangeAnnotation(
          id: 'annotation_${DateTime.now().millisecondsSinceEpoch}',
          startY: isHorizontal ? minValue : null,
          endY: isHorizontal ? maxValue : null,
          startX: isHorizontal ? null : minValue,
          endX: isHorizontal ? null : maxValue,
          label: config.label,
          fillColor: color.withOpacity(opacity),
          borderColor: color,
        );

      case 'textLabel':
        // TextAnnotation uses screen coordinates (pixels), not data coordinates
        // Support semantic positions: topLeft, topCenter, topRight, centerLeft, center, centerRight, bottomLeft, bottomCenter, bottomRight
        final text = config.text ?? config.label ?? '';
        final position = _getTextAnnotationPosition(config.position);
        final anchor = _getTextAnnotationAnchor(config.position);
        return TextAnnotation(
          id: 'annotation_${DateTime.now().millisecondsSinceEpoch}',
          position: position,
          text: text,
          anchor: anchor,
          style: AnnotationStyle(
            textStyle: TextStyle(
              fontSize: config.fontSize ?? 12.0,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        );

      case 'marker':
        // Convert to PinAnnotation
        final x = config.x ?? 0.0;
        final y = config.y ?? 0.0;
        return PinAnnotation(
          id: 'annotation_${DateTime.now().millisecondsSinceEpoch}',
          x: x,
          y: y,
          label: config.label,
          markerColor: color,
        );

      default:
        return null;
    }
  }

  ChartSeries _createSeriesForType(
    agentic.ChartType type, {
    required String id,
    String? name,
    required List<ChartDataPoint> points,
    Color? color,
    double strokeWidth = 2.0,
  }) {
    switch (type) {
      case agentic.ChartType.line:
        return LineChartSeries(
          id: id,
          name: name,
          points: points,
          color: color,
          tension: 0.25,
          strokeWidth: strokeWidth,
        );
      case agentic.ChartType.area:
        return AreaChartSeries(
          id: id,
          name: name,
          points: points,
          color: color,
          tension: 0.25,
        );
      case agentic.ChartType.bar:
        return BarChartSeries(
          id: id,
          name: name,
          points: points,
          color: color,
          barWidthPercent: 0.7,
        );
      case agentic.ChartType.scatter:
        return ScatterChartSeries(
          id: id,
          name: name,
          points: points,
          color: color,
          markerRadius: 5.0,
        );
    }
  }

  /// Converts a semantic position string to screen coordinates.
  /// Positions are relative to chart area with sensible defaults.
  /// Supported: topLeft, topCenter, topRight, centerLeft, center, centerRight,
  /// bottomLeft, bottomCenter, bottomRight
  Offset _getTextAnnotationPosition(String? position) {
    // Default chart area dimensions for positioning
    // These are approximate - the annotation will be placed in the general area
    const double left = 60.0; // Account for Y-axis labels
    const double top = 30.0; // Account for title area
    const double centerX = 300.0; // Approximate center
    const double centerY = 150.0; // Approximate center
    const double right = 540.0; // Approximate right edge
    const double bottom = 280.0; // Approximate bottom

    switch (position?.toLowerCase()) {
      case 'topcenter':
      case 'top_center':
      case 'top-center':
        return const Offset(centerX, top);
      case 'topright':
      case 'top_right':
      case 'top-right':
        return const Offset(right, top);
      case 'centerleft':
      case 'center_left':
      case 'center-left':
        return const Offset(left, centerY);
      case 'center':
        return const Offset(centerX, centerY);
      case 'centerright':
      case 'center_right':
      case 'center-right':
        return const Offset(right, centerY);
      case 'bottomleft':
      case 'bottom_left':
      case 'bottom-left':
        return const Offset(left, bottom);
      case 'bottomcenter':
      case 'bottom_center':
      case 'bottom-center':
        return const Offset(centerX, bottom);
      case 'bottomright':
      case 'bottom_right':
      case 'bottom-right':
        return const Offset(right, bottom);
      case 'topleft':
      case 'top_left':
      case 'top-left':
      default:
        // Default to top-left with offset
        return const Offset(left, top);
    }
  }

  /// Gets the appropriate anchor for the semantic position.
  /// The anchor determines which corner of the text box is at the position.
  AnnotationAnchor _getTextAnnotationAnchor(String? position) {
    switch (position?.toLowerCase()) {
      case 'topcenter':
      case 'top_center':
      case 'top-center':
        return AnnotationAnchor.topCenter;
      case 'topright':
      case 'top_right':
      case 'top-right':
        return AnnotationAnchor.topRight;
      case 'centerleft':
      case 'center_left':
      case 'center-left':
        return AnnotationAnchor.centerLeft;
      case 'center':
        return AnnotationAnchor.center;
      case 'centerright':
      case 'center_right':
      case 'center-right':
        return AnnotationAnchor.centerRight;
      case 'bottomleft':
      case 'bottom_left':
      case 'bottom-left':
        return AnnotationAnchor.bottomLeft;
      case 'bottomcenter':
      case 'bottom_center':
      case 'bottom-center':
        return AnnotationAnchor.bottomCenter;
      case 'bottomright':
      case 'bottom_right':
      case 'bottom-right':
        return AnnotationAnchor.bottomRight;
      case 'topleft':
      case 'top_left':
      case 'top-left':
      default:
        return AnnotationAnchor.topLeft;
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

  /// Debug helper: print chart configuration as JSON
  void _debugPrintChartJson(agentic.ChartConfiguration config) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      final prettyJson = encoder.convert(config.toJson());
      debugPrint('Chart JSON:');
      for (final line in prettyJson.split('\n')) {
        debugPrint(line);
      }
    } catch (e) {
      debugPrint('Chart JSON: [Failed to serialize: $e]');
    }
  }
}
