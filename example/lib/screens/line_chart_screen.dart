import 'package:flutter/material.dart';

import '../data/chart_data_generator.dart';
import '../widgets/chart_container.dart';

class LineChartScreen extends StatefulWidget {
  const LineChartScreen({super.key});

  @override
  State<LineChartScreen> createState() => _LineChartScreenState();
}

class _LineChartScreenState extends State<LineChartScreen> {
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
        title: const Text('Line Charts'),
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
          _buildStraightLineChart(context),
          _buildSmoothLineChart(context),
          _buildSteppedLineChart(context),
          _buildMultiSeriesChart(context),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Line charts support three interpolation modes: straight (linear), '
                'smooth (Bezier curves), and stepped. You can also customize marker shapes.',
                style: TextStyle(color: Colors.blue.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStraightLineChart(BuildContext context) {
    return ChartContainer(
      title: 'Straight Line Chart',
      subtitle: 'Linear interpolation between points',
      height: 250,
      onRefresh: _refreshData,
      chart: DemoChartWidget(
        chartType: 'STRAIGHT',
        color: Colors.blue,
        description: 'Using LineStyle.straight with circle markers.\n'
            'Data: ${ChartDataGenerator.generateLinearData(pointCount: 8).length} points',
      ),
    );
  }

  Widget _buildSmoothLineChart(BuildContext context) {
    return ChartContainer(
      title: 'Smooth Line Chart',
      subtitle: 'Bezier curve interpolation',
      height: 250,
      onRefresh: _refreshData,
      chart: DemoChartWidget(
        chartType: 'SMOOTH',
        color: Colors.green,
        description: 'Using LineStyle.smooth with cubic Bezier curves.\n'
            'Data: ${ChartDataGenerator.generateSineWave().length} sine wave points',
      ),
    );
  }

  Widget _buildSteppedLineChart(BuildContext context) {
    return ChartContainer(
      title: 'Stepped Line Chart',
      subtitle: 'Step interpolation (stair-step)',
      height: 250,
      onRefresh: _refreshData,
      chart: DemoChartWidget(
        chartType: 'STEPPED',
        color: Colors.orange,
        description: 'Using LineStyle.stepped with square markers.\n'
            'Data: ${ChartDataGenerator.generateRandomData(pointCount: 10).length} random points',
      ),
    );
  }

  Widget _buildMultiSeriesChart(BuildContext context) {
    return ChartContainer(
      title: 'Multi-Series Line Chart',
      subtitle: 'Multiple series with different markers',
      height: 300,
      onRefresh: _refreshData,
      chart: const DemoChartWidget(
        chartType: 'MULTI-SERIES',
        color: Colors.purple,
        description: '3 series with smooth interpolation.\n'
            'Markers: circle, square, triangle\n'
            'Demonstrates color cycling and marker variety',
      ),
    );
  }
}
