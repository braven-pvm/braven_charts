import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../data/chart_data_generator.dart';
import '../widgets/chart_container.dart';

class AreaChartScreen extends StatefulWidget {
  const AreaChartScreen({super.key});

  @override
  State<AreaChartScreen> createState() => _AreaChartScreenState();
}

class _AreaChartScreenState extends State<AreaChartScreen> {
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
        title: const Text('Area Charts'),
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
          _buildSolidAreaChart(context),
          _buildGradientAreaChart(context),
          _buildStackedAreaChart(context),
          _buildBaselineAreaChart(context),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.green.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Area charts support solid and gradient fills, stacking multiple series, '
                'custom baselines, AND line styles (straight, smooth bezier, stepped) '
                'for the top edge interpolation.',
                style: TextStyle(color: Colors.green.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolidAreaChart(BuildContext context) {
    return ChartContainer(
      title: 'Solid Fill Area Chart (Straight Lines)',
      subtitle: 'Linear interpolation - sharp angular edges',
      height: 350,
      onRefresh: _refreshData,
      chart: LayoutBuilder(
        builder: (context, constraints) => BravenChart(
          chartType: ChartType.area,
          lineStyle: LineStyle.straight, // Explicit straight line edges
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

  Widget _buildGradientAreaChart(BuildContext context) {
    return ChartContainer(
      title: 'Smooth Bezier Area Chart',
      subtitle: 'Cubic bezier curves - flowing smooth edges (Catmull-Rom spline)',
      height: 350,
      onRefresh: _refreshData,
      chart: LayoutBuilder(
        builder: (context, constraints) => BravenChart(
          chartType: ChartType.area,
          lineStyle: LineStyle.smooth, // Smooth bezier curves for area edge
          series: [
            ChartSeries(
              id: 'gradient_data',
              name: 'Smooth Area',
              points: ChartDataGenerator.generateRandomData(pointCount: 15).map((dp) => ChartDataPoint(x: dp.x, y: dp.y)).toList(),
            ),
          ],
          width: constraints.maxWidth,
          height: 350,
        ),
      ),
    );
  }

  Widget _buildStackedAreaChart(BuildContext context) {
    return ChartContainer(
      title: 'Stacked Area Chart (Stepped)',
      subtitle: 'Multiple series stacked with stepped interpolation',
      height: 350,
      onRefresh: _refreshData,
      chart: LayoutBuilder(
        builder: (context, constraints) => BravenChart(
          chartType: ChartType.area,
          lineStyle: LineStyle.stepped, // Stepped edges for discrete data
          series: [
            ChartSeries(
              id: 'series1',
              name: 'Series 1',
              points:
                  ChartDataGenerator.generateRandomData(pointCount: 10, minY: 20, maxY: 50).map((dp) => ChartDataPoint(x: dp.x, y: dp.y)).toList(),
            ),
            ChartSeries(
              id: 'series2',
              name: 'Series 2',
              points:
                  ChartDataGenerator.generateRandomData(pointCount: 10, minY: 15, maxY: 40).map((dp) => ChartDataPoint(x: dp.x, y: dp.y)).toList(),
            ),
            ChartSeries(
              id: 'series3',
              name: 'Series 3',
              points:
                  ChartDataGenerator.generateRandomData(pointCount: 10, minY: 10, maxY: 30).map((dp) => ChartDataPoint(x: dp.x, y: dp.y)).toList(),
            ),
          ],
          title: 'Stacked Areas',
          width: constraints.maxWidth,
          height: 350,
          interactionConfig: InteractionConfig.defaultConfig()
              .copyWith(enableZoom: true, enablePan: true, enableSelection: true, crosshair: CrosshairConfig.defaultConfig()),
        ),
      ),
    );
  }

  Widget _buildBaselineAreaChart(BuildContext context) {
    return ChartContainer(
      title: 'Custom Baseline Area Chart (Smooth Bezier)',
      subtitle: 'Area with fixed baseline and smooth cubic curves',
      height: 350,
      onRefresh: _refreshData,
      chart: LayoutBuilder(
        builder: (context, constraints) => BravenChart(
          chartType: ChartType.area,
          lineStyle: LineStyle.smooth, // Smooth bezier for elegant baseline area
          series: [
            ChartSeries(
              id: 'baseline_data',
              name: 'Data',
              points: ChartDataGenerator.generateLinearData(pointCount: 10, startY: 40, slope: 0.8)
                  .map((dp) => ChartDataPoint(x: dp.x, y: dp.y))
                  .toList(),
            ),
          ],
          width: constraints.maxWidth,
          height: 350,
        ),
      ),
    );
  }
}

