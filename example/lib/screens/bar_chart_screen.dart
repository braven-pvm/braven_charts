import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_container.dart';

class BarChartScreen extends StatefulWidget {
  const BarChartScreen({super.key});

  @override
  State<BarChartScreen> createState() => _BarChartScreenState();
}

class _BarChartScreenState extends State<BarChartScreen> {
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
        title: const Text('Bar Charts'),
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
          _buildGroupedBarChart(context),
          _buildStackedBarChart(context),
          _buildHorizontalBarChart(context),
          _buildNegativeBarChart(context),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bar charts support vertical and horizontal orientations, grouped or stacked modes, '
                'rounded corners, borders, and gradient fills.',
                style: TextStyle(color: Colors.orange.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedBarChart(BuildContext context) {
    return ChartContainer(
      title: 'Grouped Bar Chart',
      subtitle: 'Multiple series side-by-side',
      height: 350,
      onRefresh: _refreshData,
      chart: LayoutBuilder(
        builder: (context, constraints) => BravenChart(
          chartType: ChartType.bar,
          series: [
            ChartSeries(
              id: 'q1',
              name: 'Q1',
              points: const [
                ChartDataPoint(x: 1, y: 45),
                ChartDataPoint(x: 2, y: 62),
                ChartDataPoint(x: 3, y: 38),
                ChartDataPoint(x: 4, y: 71),
              ],
            ),
            ChartSeries(
              id: 'q2',
              name: 'Q2',
              points: const [
                ChartDataPoint(x: 1, y: 52),
                ChartDataPoint(x: 2, y: 58),
                ChartDataPoint(x: 3, y: 44),
                ChartDataPoint(x: 4, y: 68),
              ],
            ),
            ChartSeries(
              id: 'q3',
              name: 'Q3',
              points: const [
                ChartDataPoint(x: 1, y: 48),
                ChartDataPoint(x: 2, y: 65),
                ChartDataPoint(x: 3, y: 41),
                ChartDataPoint(x: 4, y: 75),
              ],
            ),
          ],
          title: 'Quarterly Sales',
          width: constraints.maxWidth,
          height: 350,
        ),
      ),
    );
  }

  Widget _buildStackedBarChart(BuildContext context) {
    return ChartContainer(
      title: 'Stacked Bar Chart',
      subtitle: 'Series stacked on top of each other',
      height: 350,
      onRefresh: _refreshData,
      chart: LayoutBuilder(
        builder: (context, constraints) => BravenChart(
          chartType: ChartType.bar,
          series: [
            ChartSeries(
              id: 'desktop',
              name: 'Desktop',
              points: const [
                ChartDataPoint(x: 1, y: 30),
                ChartDataPoint(x: 2, y: 28),
                ChartDataPoint(x: 3, y: 25),
                ChartDataPoint(x: 4, y: 22),
                ChartDataPoint(x: 5, y: 20),
              ],
            ),
            ChartSeries(
              id: 'mobile',
              name: 'Mobile',
              points: const [
                ChartDataPoint(x: 1, y: 50),
                ChartDataPoint(x: 2, y: 55),
                ChartDataPoint(x: 3, y: 60),
                ChartDataPoint(x: 4, y: 65),
                ChartDataPoint(x: 5, y: 70),
              ],
            ),
            ChartSeries(
              id: 'tablet',
              name: 'Tablet',
              points: const [
                ChartDataPoint(x: 1, y: 20),
                ChartDataPoint(x: 2, y: 17),
                ChartDataPoint(x: 3, y: 15),
                ChartDataPoint(x: 4, y: 13),
                ChartDataPoint(x: 5, y: 10),
              ],
            ),
          ],
          title: 'Device Usage',
          width: constraints.maxWidth,
          height: 350,
        ),
      ),
    );
  }

  Widget _buildHorizontalBarChart(BuildContext context) {
    return ChartContainer(
      title: 'Horizontal Bar Chart',
      subtitle: 'Bars extending left-to-right',
      height: 350,
      onRefresh: _refreshData,
      chart: LayoutBuilder(
        builder: (context, constraints) => BravenChart(
          chartType: ChartType.bar,
          series: [
            ChartSeries(
              id: 'sales',
              name: 'Sales',
              points: const [
                ChartDataPoint(x: 1, y: 85),
                ChartDataPoint(x: 2, y: 72),
                ChartDataPoint(x: 3, y: 93),
                ChartDataPoint(x: 4, y: 68),
              ],
            ),
          ],
          width: constraints.maxWidth,
          height: 350,
        ),
      ),
    );
  }

  Widget _buildNegativeBarChart(BuildContext context) {
    return ChartContainer(
      title: 'Bar Chart with Negative Values',
      subtitle: 'Stacked bars with positive and negative values',
      height: 350,
      onRefresh: _refreshData,
      chart: LayoutBuilder(
        builder: (context, constraints) => BravenChart(
          chartType: ChartType.bar,
          series: [
            ChartSeries(
              id: 'profit',
              name: 'Profit',
              points: const [
                ChartDataPoint(x: 1, y: 45),
                ChartDataPoint(x: 2, y: -20),
                ChartDataPoint(x: 3, y: 60),
                ChartDataPoint(x: 4, y: -15),
                ChartDataPoint(x: 5, y: 80),
                ChartDataPoint(x: 6, y: 35),
              ],
            ),
          ],
          width: constraints.maxWidth,
          height: 350,
        ),
      ),
    );
  }
}
