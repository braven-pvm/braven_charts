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
                'and custom baselines (zero, fixed value, or another series).',
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
      title: 'Solid Fill Area Chart',
      subtitle: 'Single color fill with optional line overlay',
      height: 250,
      onRefresh: _refreshData,
      chart: DemoChartWidget(
        chartType: 'SOLID FILL',
        color: Colors.blue,
        description: 'Using AreaFillStyle.solid with smooth interpolation.\n'
            'Data: ${ChartDataGenerator.generateSineWave().length} sine wave points',
      ),
    );
  }

  Widget _buildGradientAreaChart(BuildContext context) {
    return ChartContainer(
      title: 'Gradient Area Chart',
      subtitle: 'Vertical gradient fill from top to bottom',
      height: 250,
      onRefresh: _refreshData,
      chart: DemoChartWidget(
        chartType: 'GRADIENT',
        color: Colors.purple,
        description: 'Using AreaFillStyle.gradient with custom colors.\n'
            'Gradient shader cached for performance',
      ),
    );
  }

  Widget _buildStackedAreaChart(BuildContext context) {
    return ChartContainer(
      title: 'Stacked Area Chart',
      subtitle: 'Multiple series stacked on top of each other',
      height: 300,
      onRefresh: _refreshData,
      chart: DemoChartWidget(
        chartType: 'STACKED',
        color: Colors.green,
        description: '3 series with AreaStacking algorithm.\n'
            'Handles positive values and automatic baseline calculation',
      ),
    );
  }

  Widget _buildBaselineAreaChart(BuildContext context) {
    return ChartContainer(
      title: 'Custom Baseline Area Chart',
      subtitle: 'Area chart with fixed baseline value',
      height: 250,
      onRefresh: _refreshData,
      chart: DemoChartWidget(
        chartType: 'CUSTOM BASELINE',
        color: Colors.orange,
        description: 'Using AreaBaselineType.fixed at y=50.\n'
            'Shows area above and below baseline',
      ),
    );
  }
}
