import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../data/chart_data_generator.dart';
import '../widgets/chart_container.dart';

class ScatterChartScreen extends StatefulWidget {
  const ScatterChartScreen({super.key});

  @override
  State<ScatterChartScreen> createState() => _ScatterChartScreenState();
}

class _ScatterChartScreenState extends State<ScatterChartScreen> {
  int _refreshKey = 0;

  void _refreshData() {
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scatter Plots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh all charts',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(context),
          const SizedBox(height: 16),
          _buildFixedSizeScatter(context),
          _buildBubbleChart(context),
          _buildClusteredScatter(context),
          _buildMarkerVarietyScatter(context),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      color: Colors.purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.purple.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Scatter plots support fixed-size and data-driven sizing (bubble charts), '
                'automatic clustering for dense data, and various marker shapes and styles.',
                style: TextStyle(color: Colors.purple.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedSizeScatter(BuildContext context) {
    return ChartContainer(
      title: 'Fixed-Size Scatter Plot',
      subtitle: 'All markers same size',
      height: 300,
      onRefresh: _refreshData,
      chart: BravenChart(
        chartType: ChartType.scatter,
        series: [
          ChartSeries(
            id: 'scatter_data',
            name: 'Random Points',
            points: ChartDataGenerator.generateRandomData(pointCount: 40)
                .map((dp) => ChartDataPoint(x: dp.x, y: dp.y))
                .toList(),
          ),
        ],
        width: 400,
        height: 300,
      ),
    );
  }

  Widget _buildBubbleChart(BuildContext context) {
    return ChartContainer(
      title: 'Bubble Chart',
      subtitle: 'Data-driven marker sizing',
      height: 300,
      onRefresh: _refreshData,
      chart: BravenChart(
        chartType: ChartType.scatter,
        series: [
          ChartSeries(
            id: 'bubbles',
            name: 'Bubbles',
            points: ChartDataGenerator.generateRandomData(pointCount: 30)
                .map((dp) => ChartDataPoint(x: dp.x, y: dp.y))
                .toList(),
          ),
        ],
        width: 400,
        height: 300,
      ),
    );
  }

  Widget _buildClusteredScatter(BuildContext context) {
    return ChartContainer(
      title: 'Clustered Scatter Plot',
      subtitle: 'Automatic clustering for dense data',
      height: 300,
      onRefresh: _refreshData,
      chart: BravenChart(
        chartType: ChartType.scatter,
        series: [
          ChartSeries(
            id: 'cluster_data',
            name: 'Dense Points',
            points: ChartDataGenerator.generateRandomData(pointCount: 100)
                .map((dp) => ChartDataPoint(x: dp.x, y: dp.y))
                .toList(),
          ),
        ],
        width: 400,
        height: 300,
      ),
    );
  }

  Widget _buildMarkerVarietyScatter(BuildContext context) {
    return ChartContainer(
      title: 'Multi-Series with Different Markers',
      subtitle: 'Demonstrating marker shape variety',
      height: 300,
      onRefresh: _refreshData,
      chart: BravenChart(
        chartType: ChartType.scatter,
        series: [
          ChartSeries(
            id: 'series_a',
            name: 'Series A',
            points: ChartDataGenerator.generateRandomData(pointCount: 20, minY: 20, maxY: 50)
                .map((dp) => ChartDataPoint(x: dp.x, y: dp.y))
                .toList(),
          ),
          ChartSeries(
            id: 'series_b',
            name: 'Series B',
            points: ChartDataGenerator.generateRandomData(pointCount: 20, minY: 40, maxY: 70)
                .map((dp) => ChartDataPoint(x: dp.x, y: dp.y))
                .toList(),
          ),
          ChartSeries(
            id: 'series_c',
            name: 'Series C',
            points: ChartDataGenerator.generateRandomData(pointCount: 20, minY: 60, maxY: 90)
                .map((dp) => ChartDataPoint(x: dp.x, y: dp.y))
                .toList(),
          ),
        ],
        title: 'Multi-Series Scatter',
        width: 400,
        height: 300,
      ),
    );
  }
}
