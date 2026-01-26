import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../models/chart_configuration.dart' as agentic;

/// Renders chart configurations into Flutter widgets.
class ChartRenderer {
  const ChartRenderer();

  /// Builds a widget for the provided chart configuration or raw chart data.
  Widget render(dynamic chart) {
    debugPrint('ChartRenderer.render() called with: ${chart.runtimeType}');

    if (chart is agentic.ChartConfiguration) {
      debugPrint('Rendering ChartConfiguration directly');
      return _renderConfiguration(chart);
    }

    // Handle Map format (from CreateChartTool output)
    if (chart is Map<String, dynamic>) {
      debugPrint('Rendering from Map: ${chart.keys.toList()}');
      try {
        final config = agentic.ChartConfiguration.fromJson(chart);
        debugPrint(
            'Parsed config: type=${config.type}, series=${config.series.length}');
        return _renderConfiguration(config);
      } catch (e) {
        debugPrint('Error parsing chart config: $e');
        return _errorWidget('Invalid chart configuration: $e');
      }
    }

    debugPrint('Unsupported chart format: ${chart.runtimeType}');
    return _errorWidget('Unsupported chart format');
  }

  Widget _renderConfiguration(agentic.ChartConfiguration config) {
    try {
      // Convert SeriesConfig to ChartSeries
      if (config.series.isEmpty) {
        debugPrint('No series data in config');
        return _errorWidget('No series data provided');
      }

      debugPrint('Building ${config.series.length} series');
      final series = config.series.map((seriesConfig) {
        final dataPoints = seriesConfig.data ?? [];
        debugPrint(
            'Series ${seriesConfig.id}: ${dataPoints.length} data points');
        final points = dataPoints.map((dataPoint) {
          final x = dataPoint['x'];
          final y = dataPoint['y'];
          return ChartDataPoint(
            x: (x is num) ? x.toDouble() : 0.0,
            y: (y is num) ? y.toDouble() : 0.0,
          );
        }).toList();

        // Map to the appropriate concrete series type based on chart type
        return _createSeriesForType(
          config.type,
          id: seriesConfig.id,
          name: seriesConfig.name,
          points: points,
        );
      }).toList();

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

      debugPrint('Creating BravenChartPlus widget');
      return SizedBox(
        height: 300,
        child: BravenChartPlus(
          series: series,
          xAxisConfig: xAxisConfig,
          yAxis: yAxisConfig,
        ),
      );
    } catch (e, stack) {
      debugPrint('Error rendering chart: $e');
      debugPrint('Stack: $stack');
      return _errorWidget('Failed to render chart: $e');
    }
  }

  ChartSeries _createSeriesForType(
    agentic.ChartType type, {
    required String id,
    String? name,
    required List<ChartDataPoint> points,
  }) {
    switch (type) {
      case agentic.ChartType.line:
        return LineChartSeries(
          id: id,
          name: name,
          points: points,
          tension: 0.25,
        );
      case agentic.ChartType.area:
        return AreaChartSeries(
          id: id,
          name: name,
          points: points,
          tension: 0.25,
        );
      case agentic.ChartType.bar:
        return BarChartSeries(
          id: id,
          name: name,
          points: points,
          barWidthPercent: 0.7,
        );
      case agentic.ChartType.scatter:
        return ScatterChartSeries(
          id: id,
          name: name,
          points: points,
          markerRadius: 5.0,
        );
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
