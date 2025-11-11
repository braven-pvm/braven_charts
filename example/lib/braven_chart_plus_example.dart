// Copyright (c) 2025 braven_charts. All rights reserved.
// Example app for BravenChartPlus - Testing isolated implementation

// Import from src_plus (isolated workspace - NO lib/src references!)
import 'package:braven_charts/src_plus/models/chart_data_point.dart';
import 'package:braven_charts/src_plus/models/chart_series.dart';
import 'package:braven_charts/src_plus/models/chart_theme.dart';
import 'package:braven_charts/src_plus/models/chart_type.dart';
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

  // Sample data
  List<ChartSeries> _createSampleData() {
    return [
      const ChartSeries(
        id: 'series1',
        name: 'Revenue',
        points: [
          ChartDataPoint(x: 0, y: 100),
          ChartDataPoint(x: 1, y: 150),
          ChartDataPoint(x: 2, y: 120),
          ChartDataPoint(x: 3, y: 180),
          ChartDataPoint(x: 4, y: 160),
          ChartDataPoint(x: 5, y: 200),
        ],
        // color: Colors.blue,  // REMOVED: Let theme provide colors
        isXOrdered: true,
      ),
      const ChartSeries(
        id: 'series2',
        name: 'Expenses',
        points: [
          ChartDataPoint(x: 0, y: 80),
          ChartDataPoint(x: 1, y: 90),
          ChartDataPoint(x: 2, y: 85),
          ChartDataPoint(x: 3, y: 110),
          ChartDataPoint(x: 4, y: 95),
          ChartDataPoint(x: 5, y: 120),
        ],
        // color: Colors.red,  // REMOVED: Let theme provide colors
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
                  '🎨 Phase 1: Real Data + Theming',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text('✅ SeriesElement wrapper created'),
                const Text('✅ Real ChartSeries data rendering'),
                const Text('✅ ChartTheme system wired through widget chain'),
                const Text('✅ Theme colors applied (change theme above!)'),
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
                    chartType: ChartType.line,
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
