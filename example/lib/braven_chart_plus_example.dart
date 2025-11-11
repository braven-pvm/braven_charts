// Copyright (c) 2025 braven_charts. All rights reserved.
// Example app for BravenChartPlus - Testing isolated implementation

// Import from src_plus (isolated workspace - NO lib/src references!)
import 'package:braven_charts/src_plus/models/chart_data_point.dart';
import 'package:braven_charts/src_plus/models/chart_series.dart';
import 'package:braven_charts/src_plus/models/chart_theme.dart';
import 'package:braven_charts/src_plus/widgets/braven_chart_plus.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BravenChartPlusExampleApp());
}

class BravenChartPlusExampleApp extends StatelessWidget {
  const BravenChartPlusExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BravenChartPlus Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BravenChartPlusExamplePage(),
    );
  }
}

class BravenChartPlusExamplePage extends StatefulWidget {
  const BravenChartPlusExamplePage({super.key});

  @override
  State<BravenChartPlusExamplePage> createState() => _BravenChartPlusExamplePageState();
}

class _BravenChartPlusExamplePageState extends State<BravenChartPlusExamplePage> {
  bool _showDebugInfo = true;
  ChartTheme _selectedTheme = ChartTheme.light;

  // Sample data - showcasing ALL chart types on one chart
  // Each type demonstrates its ideal use case with realistic patterns
  List<ChartSeries> _createSampleData() {
    return [
      // LINE CHART: Website Traffic Trend (smooth continuous data)
      // Perfect for: Time series, trends, continuous measurements
      const LineChartSeries(
        id: 'line_series',
        name: 'Daily Visitors (000s)',
        interpolation: LineInterpolation.bezier,
        tension: 0.4,
        strokeWidth: 2.0,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 3.0,
        points: [
          ChartDataPoint(x: 0, y: 12.5), // Monday
          ChartDataPoint(x: 1, y: 15.2), // Tuesday
          ChartDataPoint(x: 2, y: 18.7), // Wednesday
          ChartDataPoint(x: 3, y: 22.1), // Thursday
          ChartDataPoint(x: 4, y: 28.5), // Friday
          ChartDataPoint(x: 5, y: 25.3), // Saturday
          ChartDataPoint(x: 6, y: 19.8), // Sunday
          ChartDataPoint(x: 7, y: 14.2), // Monday
          ChartDataPoint(x: 8, y: 16.9), // Tuesday
          ChartDataPoint(x: 9, y: 20.4), // Wednesday
        ],
        isXOrdered: true,
      ),

      // SCATTER CHART: Individual Sales Events (discrete unconnected points)
      // Perfect for: Correlation, distribution, individual events
      const ScatterChartSeries(
        id: 'scatter_series',
        name: 'Individual Orders (\$)',
        markerRadius: 6.0,
        strokeWidth: 2.0,
        points: [
          ChartDataPoint(x: 0.3, y: 125),
          ChartDataPoint(x: 0.8, y: 145),
          ChartDataPoint(x: 1.2, y: 158),
          ChartDataPoint(x: 1.9, y: 132),
          ChartDataPoint(x: 2.4, y: 167),
          ChartDataPoint(x: 3.1, y: 142),
          ChartDataPoint(x: 3.7, y: 178),
          ChartDataPoint(x: 4.2, y: 155),
          ChartDataPoint(x: 4.9, y: 188),
          ChartDataPoint(x: 5.3, y: 162),
          ChartDataPoint(x: 6.1, y: 149),
          ChartDataPoint(x: 6.8, y: 171),
          ChartDataPoint(x: 7.5, y: 138),
          ChartDataPoint(x: 8.2, y: 165),
          ChartDataPoint(x: 8.9, y: 182),
        ],
        isXOrdered: true,
      ),

      // AREA CHART: Cumulative Revenue (shows magnitude and accumulation)
      // Perfect for: Cumulative data, showing "under the curve", volume
      const AreaChartSeries(
        id: 'area_series',
        name: 'Cumulative Revenue (\$K)',
        interpolation: LineInterpolation.linear,
        fillOpacity: 0.3,
        strokeWidth: 2.0,
        showDataPointMarkers: false,
        points: [
          ChartDataPoint(x: 0, y: 285),
          ChartDataPoint(x: 1, y: 310),
          ChartDataPoint(x: 2, y: 345),
          ChartDataPoint(x: 3, y: 398),
          ChartDataPoint(x: 4, y: 455),
          ChartDataPoint(x: 5, y: 490),
          ChartDataPoint(x: 6, y: 520),
          ChartDataPoint(x: 7, y: 545),
          ChartDataPoint(x: 8, y: 585),
          ChartDataPoint(x: 9, y: 635),
        ],
        isXOrdered: true,
      ),

      // BAR CHART: Quarterly Performance (categorical comparisons)
      // Perfect for: Comparisons, categorical data, discrete measurements
      const BarChartSeries(
        id: 'bar_series',
        name: 'Quarterly Sales (\$M)',
        barWidthPercent: 0.7, // 70% of X-axis spacing
        minWidth: 2.0,
        maxWidth: 100.0,
        points: [
          ChartDataPoint(x: 1, y: 42), // Q1: $42M
          ChartDataPoint(x: 3, y: 58), // Q2: $58M
          ChartDataPoint(x: 5, y: 75), // Q3: $75M
          ChartDataPoint(x: 7, y: 63), // Q4: $63M
        ],
        isXOrdered: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('BravenChartPlus - Phase 1 Test'),
        actions: [
          // Theme selector dropdown
          DropdownButton<ChartTheme>(
            value: _selectedTheme,
            items: const [
              DropdownMenuItem(
                value: ChartTheme.light,
                child: Text('Light Theme'),
              ),
              DropdownMenuItem(
                value: ChartTheme.dark,
                child: Text('Dark Theme'),
              ),
            ],
            onChanged: (theme) {
              if (theme != null) {
                setState(() {
                  _selectedTheme = theme;
                });
              }
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(_showDebugInfo ? Icons.bug_report : Icons.bug_report_outlined),
            onPressed: () {
              setState(() {
                _showDebugInfo = !_showDebugInfo;
              });
            },
            tooltip: 'Toggle Debug Overlay',
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.amber.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎨 ALL Chart Types Showcase',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text('📈 Line: Daily website visitors trend (continuous time series)'),
                const Text('🔵 Scatter: Individual order values (discrete events)'),
                const Text('📊 Area: Cumulative revenue growth (volume under curve)'),
                const Text('📊 Bar: Quarterly sales comparison (categorical data)'),
                const SizedBox(height: 8),
                Text(
                  'Debug Overlay: ${_showDebugInfo ? "ON" : "OFF"}',
                  style: TextStyle(
                    color: _showDebugInfo ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Chart area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: BravenChartPlus(
                    series: _createSampleData(),
                    theme: _selectedTheme,
                    backgroundColor: _selectedTheme == ChartTheme.dark ? Colors.grey.shade900 : Colors.white,
                    showDebugInfo: _showDebugInfo,
                  ),
                ),
              ),
            ),
          ),

          // Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎮 Interaction Test:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text('• Try clicking/dragging (coordinator should respond)'),
                Text('• Pan: Arrow keys or middle mouse drag'),
                Text('• Zoom: +/- keys or Shift+MouseWheel'),
                Text('• Reset: R or Home key'),
                Text('• Switch theme using dropdown above'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
