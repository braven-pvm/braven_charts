import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Axis configuration and theming showcase
///
/// Demonstrates:
/// - 4 axis presets: defaults(), hidden(), minimal(), gridOnly()
/// - Custom axis configurations
/// - copyWith() customization
/// - Light and dark themes
/// - Custom theme creation
class AxisAndThemingScreen extends StatefulWidget {
  const AxisAndThemingScreen({super.key});

  @override
  State<AxisAndThemingScreen> createState() => _AxisAndThemingScreenState();
}

class _AxisAndThemingScreenState extends State<AxisAndThemingScreen> {
  // Sample data
  final _series = [
    ChartSeries(
      id: 'data',
      name: 'Sample Data',
      points: const [
        ChartDataPoint(x: 0, y: 10),
        ChartDataPoint(x: 1, y: 25),
        ChartDataPoint(x: 2, y: 15),
        ChartDataPoint(x: 3, y: 30),
        ChartDataPoint(x: 4, y: 20),
        ChartDataPoint(x: 5, y: 35),
      ],
    ),
  ];

  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Axis & Theming'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
            tooltip: _isDarkMode ? 'Light Mode' : 'Dark Mode',
          ),
        ],
      ),
      backgroundColor: _isDarkMode ? Colors.grey.shade900 : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          _buildAxisPositionsSection(),
          const SizedBox(height: 24),
          _buildAxisPresetsSection(),
          const SizedBox(height: 24),
          _buildCustomAxisSection(),
          const SizedBox(height: 24),
          _buildThemingSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: _isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.tune,
              color: _isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Axis & Theme Configuration',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.blue.shade100 : Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Customize axes with 4 presets or create your own. '
                    'Apply light, dark, or custom themes.',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.blue.shade200 : Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAxisPositionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Axis Positioning',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        Card(
          color: _isDarkMode ? Colors.green.shade900 : Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: _isDarkMode ? Colors.green.shade200 : Colors.green.shade700,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Axis positions are now FULLY FUNCTIONAL! The axisPosition property '
                    'now controls where axes are actually rendered (top/bottom for X-axis, '
                    'left/right for Y-axis).',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.green.shade100 : Colors.green.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildAxisPositionCard(
          'Default (Bottom + Left)',
          'Standard positioning - X-axis bottom, Y-axis left',
          const XAxisConfig(),
          const YAxisConfig(position: YAxisPosition.left),
          Icons.south_west,
          Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildAxisPositionCard(
          'Alternate Left Axis',
          'Y-axis left with alternate styling',
          const XAxisConfig(),
          const YAxisConfig(position: YAxisPosition.left),
          Icons.north_west,
          Colors.purple,
        ),
        const SizedBox(height: 16),
        _buildAxisPositionCard(
          'Bottom + Right',
          'X-axis bottom, Y-axis right',
          const XAxisConfig(),
          const YAxisConfig(position: YAxisPosition.right),
          Icons.south_east,
          Colors.orange,
        ),
        const SizedBox(height: 16),
        _buildAxisPositionCard(
          'Bottom + Right (Alt)',
          'Alternate styling for right Y-axis',
          const XAxisConfig(),
          const YAxisConfig(position: YAxisPosition.right),
          Icons.north_east,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildAxisPositionCard(
    String title,
    String description,
    XAxisConfig xAxis,
    YAxisConfig yAxis,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: _isDarkMode ? Colors.grey.shade800 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            BravenChartPlus(
              chartType: ChartType.line,
              series: _series,
              xAxisConfig: xAxis,
              yAxis: yAxis,
              width: 400,
              height: 250,
              theme: _isDarkMode ? ChartTheme.defaultDark : ChartTheme.defaultLight,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'xAxisConfig: XAxisConfig(),\n'
                'yAxis: YAxisConfig(position: ${yAxis.position.name}),',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAxisPresetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Axis Presets',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        _buildAxisPresetCard(
          'Default',
          'Full axes with labels and grid',
          const XAxisConfig(
            showAxisLine: true,
            showTicks: true,
            labelDisplay: AxisLabelDisplay.labelWithUnit,
          ),
          const YAxisConfig(
            position: YAxisPosition.left,
            showAxisLine: true,
            showTicks: true,
            labelDisplay: AxisLabelDisplay.labelWithUnit,
          ),
          Icons.grid_on,
          Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildAxisPresetCard(
          'Hidden',
          'Perfect for sparklines - no axes shown',
          const XAxisConfig(
            visible: false,
            showAxisLine: false,
            showTicks: false,
            labelDisplay: AxisLabelDisplay.none,
          ),
          const YAxisConfig(
            position: YAxisPosition.left,
            visible: false,
            showAxisLine: false,
            showTicks: false,
            labelDisplay: AxisLabelDisplay.none,
          ),
          Icons.visibility_off,
          Colors.purple,
          height: 120,
        ),
        const SizedBox(height: 16),
        _buildAxisPresetCard(
          'Minimal',
          'Only axis lines, no labels or grid',
          const XAxisConfig(
            showAxisLine: true,
            showTicks: false,
            labelDisplay: AxisLabelDisplay.none,
          ),
          const YAxisConfig(
            position: YAxisPosition.left,
            showAxisLine: true,
            showTicks: false,
            labelDisplay: AxisLabelDisplay.none,
          ),
          Icons.remove,
          Colors.orange,
        ),
        const SizedBox(height: 16),
        _buildAxisPresetCard(
          'Grid only',
          'Grid without axis lines',
          const XAxisConfig(
            showAxisLine: false,
            showTicks: false,
            labelDisplay: AxisLabelDisplay.none,
          ),
          const YAxisConfig(
            position: YAxisPosition.left,
            showAxisLine: false,
            showTicks: false,
            labelDisplay: AxisLabelDisplay.none,
          ),
          Icons.grid_4x4,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildAxisPresetCard(
    String title,
    String description,
    XAxisConfig xAxis,
    YAxisConfig yAxis,
    IconData icon,
    Color color, {
    double height = 250,
  }) {
    return Card(
      color: _isDarkMode ? Colors.grey.shade800 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            BravenChartPlus(
              chartType: ChartType.line,
              series: _series,
              xAxisConfig: xAxis,
              yAxis: yAxis,
              width: 400,
              height: height,
              theme: _isDarkMode ? ChartTheme.defaultDark : ChartTheme.defaultLight,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'xAxisConfig: $title preset\nyAxis: $title preset',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAxisSection() {
    return Card(
      color: _isDarkMode ? Colors.grey.shade800 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.indigo.shade700),
                const SizedBox(width: 8),
                Text(
                  'Custom Axis Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Create custom axes or use copyWith() to modify presets',
              style: TextStyle(
                color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            BravenChartPlus(
              chartType: ChartType.area,
              series: _series,
              title: 'Custom Axes',
              xAxisConfig: const XAxisConfig(
                label: 'Time (seconds)',
                showAxisLine: true,
                showTicks: true,
                labelDisplay: AxisLabelDisplay.labelWithUnit,
              ),
              yAxis: YAxisConfig(
                position: YAxisPosition.left,
                label: 'Temperature (°C)',
                showAxisLine: false,
                showTicks: false,
                labelDisplay: AxisLabelDisplay.none,
              ),
              width: 400,
              height: 300,
              theme: _isDarkMode ? ChartTheme.defaultDark : ChartTheme.defaultLight,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '// Create from scratch\n'
                'xAxisConfig: XAxisConfig(\n'
                '  label: \'Time (seconds)\',\n'
                '  showAxisLine: true,\n'
                '  showTicks: true,\n'
                '  labelDisplay: AxisLabelDisplay.labelWithUnit,\n'
                '),\n\n'
                '// Configure a Y axis\n'
                'yAxis: YAxisConfig(\n'
                '  position: YAxisPosition.left,\n'
                '  label: \'Temperature (°C)\',\n'
                '  showAxisLine: false,\n'
                '  showTicks: false,\n'
                '  labelDisplay: AxisLabelDisplay.none,\n'
                '),',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Theming',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        _buildThemeCard(
          'Light Theme',
          'Optimized for light backgrounds',
          ChartTheme.defaultLight,
          Icons.light_mode,
          Colors.orange,
          backgroundColor: Colors.white,
        ),
        const SizedBox(height: 16),
        _buildThemeCard(
          'Dark Theme',
          'Optimized for dark backgrounds',
          ChartTheme.defaultDark,
          Icons.dark_mode,
          Colors.indigo,
          backgroundColor: Colors.grey.shade900,
        ),
        const SizedBox(height: 16),
        _buildComparisonCard(),
      ],
    );
  }

  Widget _buildThemeCard(
    String title,
    String description,
    ChartTheme theme,
    IconData icon,
    Color color, {
    Color? backgroundColor,
  }) {
    return Card(
      color: backgroundColor ?? (_isDarkMode ? Colors.grey.shade800 : null),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: backgroundColor != null
                        ? (backgroundColor == Colors.white ? Colors.black : Colors.white)
                        : (_isDarkMode ? Colors.white : Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: backgroundColor != null
                    ? (backgroundColor == Colors.white ? Colors.grey.shade700 : Colors.grey.shade400)
                    : (_isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
              ),
            ),
            const SizedBox(height: 16),
            BravenChart(
              chartType: ChartType.line,
              series: _series,
              title: 'Sales Report',
              subtitle: 'Q1 2025',
              width: 400,
              height: 300,
              theme: theme,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor != null
                    ? (backgroundColor == Colors.white ? Colors.grey.shade100 : Colors.black)
                    : (_isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'theme: ChartTheme.${title == 'Light Theme' ? 'defaultLight' : 'defaultDark'},',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard() {
    return Card(
      color: _isDarkMode ? Colors.grey.shade800 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare, color: Colors.teal.shade700),
                const SizedBox(width: 8),
                Text(
                  'Side-by-Side Comparison',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: BravenChart(
                          chartType: ChartType.bar,
                          series: _series,
                          title: 'Light',
                          width: 180,
                          height: 200,
                          theme: ChartTheme.defaultLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: BravenChart(
                          chartType: ChartType.bar,
                          series: _series,
                          title: 'Dark',
                          width: 180,
                          height: 200,
                          theme: ChartTheme.defaultDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.teal.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Themes automatically adapt text colors, '
                      'grid colors, and backgrounds for optimal readability.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
