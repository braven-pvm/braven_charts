import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

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
    try {
      // Convert SeriesConfig to ChartSeries
      if (config.series.isEmpty) {
        return _errorWidget('No series data provided');
      }

      final series = config.series.map((seriesConfig) {
        final dataPoints = seriesConfig.data ?? [];
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

      return SizedBox(
        height: 400,
        child: BravenChartPlus(
          series: series,
          xAxisConfig: xAxisConfig,
          yAxis: yAxisConfig,
        ),
      );
    } catch (e) {
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
        );
      case agentic.ChartType.area:
        return AreaChartSeries(
          id: id,
          name: name,
          points: points,
        );
      case agentic.ChartType.bar:
        return BarChartSeries(
          id: id,
          name: name,
          points: points,
        );
      case agentic.ChartType.scatter:
        return ScatterChartSeries(
          id: id,
          name: name,
          points: points,
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
