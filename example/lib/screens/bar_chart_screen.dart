import 'package:flutter/material.dart';
import '../data/chart_data_generator.dart';
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
    final data = ChartDataGenerator.generateCategoricalData(
      categoryCount: 6,
      seriesCount: 3,
    );
    return ChartContainer(
      title: 'Grouped Bar Chart',
      subtitle: 'Multiple series side-by-side',
      height: 300,
      onRefresh: _refreshData,
      chart: DemoChartWidget(
        chartType: 'GROUPED',
        color: Colors.blue,
        description: 'Using BarGroupingMode.grouped with vertical orientation.\n'
            '${data.length} categories × ${data.first.values.length} series\n'
            'BarPositioner calculates layout automatically',
      ),
    );
  }

  Widget _buildStackedBarChart(BuildContext context) {
    final data = ChartDataGenerator.generateCategoricalData(
      categoryCount: 6,
      seriesCount: 4,
    );
    return ChartContainer(
      title: 'Stacked Bar Chart',
      subtitle: 'Series stacked on top of each other',
      height: 300,
      onRefresh: _refreshData,
      chart: DemoChartWidget(
        chartType: 'STACKED',
        color: Colors.green,
        description: 'Using BarGroupingMode.stacked with vertical orientation.\n'
            '${data.length} categories × ${data.first.values.length} series stacked',
      ),
    );
  }

  Widget _buildHorizontalBarChart(BuildContext context) {
    final data = ChartDataGenerator.generateCategoricalData(
      categoryCount: 5,
      seriesCount: 2,
    );
    return ChartContainer(
      title: 'Horizontal Bar Chart',
      subtitle: 'Bars extending left-to-right',
      height: 250,
      onRefresh: _refreshData,
      chart: DemoChartWidget(
        chartType: 'HORIZONTAL',
        color: Colors.purple,
        description: 'Using BarOrientation.horizontal with grouped mode.\n'
            'Perfect for category name labels',
      ),
    );
  }

  Widget _buildNegativeBarChart(BuildContext context) {
    final data = ChartDataGenerator.generateCategoricalData(
      categoryCount: 6,
      seriesCount: 2,
      allowNegative: true,
    );
    return ChartContainer(
      title: 'Bar Chart with Negative Values',
      subtitle: 'Stacked bars with positive and negative values',
      height: 300,
      onRefresh: _refreshData,
      chart: DemoChartWidget(
        chartType: 'NEGATIVE VALUES',
        color: Colors.red,
        description: 'Stacked mode handles negatives correctly.\n'
            '${data.length} categories with mixed +/- values',
      ),
    );
  }
}
