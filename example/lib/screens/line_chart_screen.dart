import 'package:braven_charts/braven_charts.dart';
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
      height: 350,
      onRefresh: _refreshData,
      chart: LayoutBuilder(
        builder: (context, constraints) => BravenChart(
          chartType: ChartType.line,
          lineStyle: LineStyle.straight, // Explicit straight line style
          series: [
            ChartSeries(
              id: 'linear_data',
              name: 'Linear Growth',
              points: ChartDataGenerator.generateLinearData(pointCount: 8).map((dp) => ChartDataPoint(x: dp.x, y: dp.y)).toList(),
            ),
          ],
          width: constraints.maxWidth,
          height: 350,
        ),
      ),
    );
  }

  Widget _buildSmoothLineChart(BuildContext context) {
    return ChartContainer(
      title: 'Smooth Line Chart (Bezier Curves)',
      subtitle: 'Catmull-Rom spline → cubic bezier interpolation',
      height: 350,
      onRefresh: _refreshData,
      chart: LayoutBuilder(
        builder: (context, constraints) => BravenChart(
          chartType: ChartType.line,
          lineStyle: LineStyle.smooth, // Smooth bezier curves
          series: [
            ChartSeries(
              id: 'sine_wave',
              name: 'Sine Wave',
              points: ChartDataGenerator.generateSineWave().map((dp) => ChartDataPoint(x: dp.x, y: dp.y)).toList(),
            ),
          ],
          width: constraints.maxWidth,
          height: 350,
        ),
      ),
    );
  }

  Widget _buildSteppedLineChart(BuildContext context) {
    return ChartContainer(
      title: 'Stepped Line Chart',
      subtitle: 'Step interpolation (horizontal-then-vertical)',
      height: 350,
      onRefresh: _refreshData,
      chart: LayoutBuilder(
        builder: (context, constraints) => BravenChart(
          chartType: ChartType.line,
          lineStyle: LineStyle.stepped, // Stepped line style
          series: [
            ChartSeries(
              id: 'random_data',
              name: 'Random Data',
              points: ChartDataGenerator.generateRandomData(pointCount: 10).map((dp) => ChartDataPoint(x: dp.x, y: dp.y)).toList(),
            ),
          ],
          width: constraints.maxWidth,
          height: 350,
        ),
      ),
    );
  }

  Widget _buildMultiSeriesChart(BuildContext context) {
    return ChartContainer(
      title: 'Multi-Series Line Chart',
      subtitle: 'Multiple series with smooth bezier curves',
      height: 350,
      onRefresh: _refreshData,
      chart: LayoutBuilder(
        builder: (context, constraints) => BravenChart(
          chartType: ChartType.line,
          lineStyle: LineStyle.smooth, // Smooth curves for multi-series
          series: [
            ChartSeries(
              id: 'revenue',
              name: 'Revenue',
              points: ChartDataGenerator.generateLinearData(pointCount: 8, slope: 100).map((dp) => ChartDataPoint(x: dp.x, y: dp.y)).toList(),
            ),
            ChartSeries(
              id: 'expenses',
              name: 'Expenses',
              points:
                  ChartDataGenerator.generateRandomData(pointCount: 8, minY: 500, maxY: 800).map((dp) => ChartDataPoint(x: dp.x, y: dp.y)).toList(),
            ),
            ChartSeries(
              id: 'profit',
              name: 'Profit',
              points: ChartDataGenerator.generateLinearData(pointCount: 8, slope: 20).map((dp) => ChartDataPoint(x: dp.x, y: dp.y)).toList(),
            ),
          ],
          title: 'Financial Overview',
          width: constraints.maxWidth,
          height: 350,
        ),
      ),
    );
  }
}
