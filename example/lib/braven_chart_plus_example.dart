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
  bool _showDebugInfo = false;
  ChartTheme _selectedTheme = ChartTheme.light;

  // Line Interpolation Showcase - comparing all interpolation types
  List<ChartSeries> _createLineInterpolationData() {
    return [
      const LineChartSeries(
        id: 'line_linear',
        name: 'Linear',
        interpolation: LineInterpolation.linear,
        strokeWidth: 2.5,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 4.0,
        points: [
          ChartDataPoint(x: 0, y: 42.3),
          ChartDataPoint(x: 1.2, y: 68.7),
          ChartDataPoint(x: 2.8, y: 51.2),
          ChartDataPoint(x: 4.5, y: 89.4),
          ChartDataPoint(x: 6.1, y: 62.8),
          ChartDataPoint(x: 7.9, y: 95.6),
          ChartDataPoint(x: 9.3, y: 73.1),
          ChartDataPoint(x: 10, y: 81.9),
        ],
        isXOrdered: true,
      ),
      const LineChartSeries(
        id: 'line_bezier_low',
        name: 'Bezier (Tension 0.2)',
        interpolation: LineInterpolation.bezier,
        tension: 0.2,
        strokeWidth: 2.5,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 3.5,
        points: [
          ChartDataPoint(x: 0, y: 38.9),
          ChartDataPoint(x: 1.5, y: 72.4),
          ChartDataPoint(x: 3.2, y: 45.8),
          ChartDataPoint(x: 5.0, y: 91.2),
          ChartDataPoint(x: 6.7, y: 58.3),
          ChartDataPoint(x: 8.4, y: 87.6),
          ChartDataPoint(x: 9.8, y: 69.4),
          ChartDataPoint(x: 10, y: 76.8),
        ],
        isXOrdered: true,
      ),
      const LineChartSeries(
        id: 'line_bezier_high',
        name: 'Bezier (Tension 0.8)',
        interpolation: LineInterpolation.bezier,
        tension: 0.8,
        strokeWidth: 3.0,
        showDataPointMarkers: false,
        points: [
          ChartDataPoint(x: 0, y: 45.6),
          ChartDataPoint(x: 1.8, y: 65.3),
          ChartDataPoint(x: 3.5, y: 53.7),
          ChartDataPoint(x: 5.2, y: 88.9),
          ChartDataPoint(x: 6.9, y: 61.2),
          ChartDataPoint(x: 8.6, y: 93.4),
          ChartDataPoint(x: 9.5, y: 71.8),
          ChartDataPoint(x: 10, y: 79.5),
        ],
        isXOrdered: true,
      ),
      const LineChartSeries(
        id: 'line_stepped',
        name: 'Stepped',
        interpolation: LineInterpolation.stepped,
        strokeWidth: 2.0,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 3.0,
        points: [
          ChartDataPoint(x: 0, y: 41.7),
          ChartDataPoint(x: 1.6, y: 70.1),
          ChartDataPoint(x: 3.4, y: 48.9),
          ChartDataPoint(x: 5.5, y: 86.7),
          ChartDataPoint(x: 7.2, y: 64.5),
          ChartDataPoint(x: 8.8, y: 91.8),
          ChartDataPoint(x: 9.7, y: 75.3),
          ChartDataPoint(x: 10, y: 83.2),
        ],
        isXOrdered: true,
      ),
      const LineChartSeries(
        id: 'line_monotone',
        name: 'Monotone',
        interpolation: LineInterpolation.monotone,
        strokeWidth: 2.5,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 4.5,
        points: [
          ChartDataPoint(x: 0, y: 39.4),
          ChartDataPoint(x: 1.4, y: 67.8),
          ChartDataPoint(x: 3.1, y: 52.6),
          ChartDataPoint(x: 4.9, y: 90.3),
          ChartDataPoint(x: 6.5, y: 59.7),
          ChartDataPoint(x: 8.2, y: 94.1),
          ChartDataPoint(x: 9.6, y: 72.9),
          ChartDataPoint(x: 10, y: 80.6),
        ],
        isXOrdered: true,
      ),
    ];
  }

  // Bar Width Showcase - different bar width configurations
  List<ChartSeries> _createBarWidthData() {
    return [
      const BarChartSeries(
        id: 'bar_70_percent',
        name: '70% Width',
        barWidthPercent: 0.7,
        minWidth: 2.0,
        maxWidth: 100.0,
        points: [
          ChartDataPoint(x: 0.8, y: 56.2),
          ChartDataPoint(x: 2.3, y: 78.9),
          ChartDataPoint(x: 4.1, y: 63.4),
          ChartDataPoint(x: 5.9, y: 91.7),
          ChartDataPoint(x: 7.5, y: 69.8),
          ChartDataPoint(x: 9.2, y: 85.3),
        ],
        isXOrdered: true,
      ),
      const BarChartSeries(
        id: 'bar_40_percent',
        name: '40% Width',
        barWidthPercent: 0.4,
        minWidth: 2.0,
        maxWidth: 80.0,
        points: [
          ChartDataPoint(x: 1.2, y: 49.7),
          ChartDataPoint(x: 2.8, y: 73.2),
          ChartDataPoint(x: 4.6, y: 58.1),
          ChartDataPoint(x: 6.4, y: 87.4),
          ChartDataPoint(x: 8.1, y: 64.9),
          ChartDataPoint(x: 9.7, y: 81.6),
        ],
        isXOrdered: true,
      ),
      const BarChartSeries(
        id: 'bar_30px_fixed',
        name: '30px Fixed',
        barWidthPixels: 30.0,
        minWidth: 5.0,
        maxWidth: 150.0,
        points: [
          ChartDataPoint(x: 0.5, y: 52.8),
          ChartDataPoint(x: 2.1, y: 76.5),
          ChartDataPoint(x: 3.9, y: 61.3),
          ChartDataPoint(x: 5.7, y: 89.1),
          ChartDataPoint(x: 7.3, y: 67.4),
          ChartDataPoint(x: 8.9, y: 83.9),
        ],
        isXOrdered: true,
      ),
    ];
  }

  // Scatter Marker Showcase - different marker sizes
  List<ChartSeries> _createScatterData() {
    return [
      const ScatterChartSeries(
        id: 'scatter_small',
        name: 'Small Markers (4px)',
        markerRadius: 4.0,
        strokeWidth: 1.5,
        points: [
          ChartDataPoint(x: 0.3, y: 47.8),
          ChartDataPoint(x: 1.1, y: 62.3),
          ChartDataPoint(x: 2.4, y: 53.9),
          ChartDataPoint(x: 3.7, y: 78.4),
          ChartDataPoint(x: 4.9, y: 58.7),
          ChartDataPoint(x: 6.2, y: 85.1),
          ChartDataPoint(x: 7.5, y: 66.5),
          ChartDataPoint(x: 8.8, y: 92.3),
          ChartDataPoint(x: 9.6, y: 74.9),
        ],
        isXOrdered: true,
      ),
      const ScatterChartSeries(
        id: 'scatter_medium',
        name: 'Medium Markers (6px)',
        markerRadius: 6.0,
        strokeWidth: 2.0,
        points: [
          ChartDataPoint(x: 0.7, y: 51.2),
          ChartDataPoint(x: 1.9, y: 68.7),
          ChartDataPoint(x: 3.2, y: 56.4),
          ChartDataPoint(x: 4.5, y: 82.9),
          ChartDataPoint(x: 5.8, y: 63.1),
          ChartDataPoint(x: 7.1, y: 88.6),
          ChartDataPoint(x: 8.4, y: 70.8),
          ChartDataPoint(x: 9.7, y: 94.2),
        ],
        isXOrdered: true,
      ),
      const ScatterChartSeries(
        id: 'scatter_large',
        name: 'Large Markers (8px)',
        markerRadius: 8.0,
        strokeWidth: 2.5,
        points: [
          ChartDataPoint(x: 1.3, y: 45.6),
          ChartDataPoint(x: 2.6, y: 71.4),
          ChartDataPoint(x: 3.9, y: 59.8),
          ChartDataPoint(x: 5.2, y: 86.3),
          ChartDataPoint(x: 6.5, y: 65.9),
          ChartDataPoint(x: 7.8, y: 91.7),
          ChartDataPoint(x: 9.1, y: 73.5),
        ],
        isXOrdered: true,
      ),
    ];
  }

  // Area Chart Showcase - different opacities and interpolations
  List<ChartSeries> _createAreaData() {
    return [
      const AreaChartSeries(
        id: 'area_transparent',
        name: 'Low Opacity (15%)',
        interpolation: LineInterpolation.bezier,
        tension: 0.5,
        fillOpacity: 0.15,
        strokeWidth: 2.0,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 3.0,
        points: [
          ChartDataPoint(x: 0, y: 48.9),
          ChartDataPoint(x: 1.7, y: 67.2),
          ChartDataPoint(x: 3.4, y: 54.6),
          ChartDataPoint(x: 5.1, y: 83.8),
          ChartDataPoint(x: 6.8, y: 61.7),
          ChartDataPoint(x: 8.5, y: 90.4),
          ChartDataPoint(x: 10, y: 72.3),
        ],
        isXOrdered: true,
      ),
      const AreaChartSeries(
        id: 'area_medium',
        name: 'Medium Opacity (30%)',
        interpolation: LineInterpolation.monotone,
        fillOpacity: 0.3,
        strokeWidth: 2.0,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 3.5,
        points: [
          ChartDataPoint(x: 0, y: 43.7),
          ChartDataPoint(x: 1.8, y: 70.5),
          ChartDataPoint(x: 3.6, y: 52.1),
          ChartDataPoint(x: 5.4, y: 87.9),
          ChartDataPoint(x: 7.2, y: 64.3),
          ChartDataPoint(x: 9.0, y: 93.6),
          ChartDataPoint(x: 10, y: 75.8),
        ],
        isXOrdered: true,
      ),
      const AreaChartSeries(
        id: 'area_opaque',
        name: 'High Opacity (50%)',
        interpolation: LineInterpolation.bezier,
        tension: 0.6,
        fillOpacity: 0.5,
        strokeWidth: 2.5,
        showDataPointMarkers: false,
        points: [
          ChartDataPoint(x: 0, y: 46.4),
          ChartDataPoint(x: 1.9, y: 65.8),
          ChartDataPoint(x: 3.8, y: 57.9),
          ChartDataPoint(x: 5.7, y: 85.2),
          ChartDataPoint(x: 7.6, y: 68.6),
          ChartDataPoint(x: 9.5, y: 91.3),
          ChartDataPoint(x: 10, y: 77.4),
        ],
        isXOrdered: true,
      ),
    ];
  }

  // Mixed Chart - combining different chart types
  List<ChartSeries> _createMixedData() {
    return [
      const LineChartSeries(
        id: 'mixed_line',
        name: 'Temperature Trend',
        interpolation: LineInterpolation.bezier,
        tension: 0.5,
        strokeWidth: 2.5,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 4.0,
        points: [
          ChartDataPoint(x: 0, y: 44.8),
          ChartDataPoint(x: 2.5, y: 68.3),
          ChartDataPoint(x: 5.0, y: 55.7),
          ChartDataPoint(x: 7.5, y: 82.9),
          ChartDataPoint(x: 10, y: 71.5),
        ],
        isXOrdered: true,
      ),
      const BarChartSeries(
        id: 'mixed_bars',
        name: 'Daily Precipitation',
        barWidthPercent: 0.5,
        minWidth: 2.0,
        maxWidth: 80.0,
        points: [
          ChartDataPoint(x: 1.2, y: 38.4),
          ChartDataPoint(x: 3.7, y: 61.9),
          ChartDataPoint(x: 6.2, y: 49.2),
          ChartDataPoint(x: 8.7, y: 74.6),
        ],
        isXOrdered: true,
      ),
      const AreaChartSeries(
        id: 'mixed_area',
        name: 'Humidity Range',
        interpolation: LineInterpolation.bezier,
        tension: 0.4,
        fillOpacity: 0.2,
        strokeWidth: 1.5,
        showDataPointMarkers: false,
        color: Colors.teal,
        points: [
          ChartDataPoint(x: 0, y: 52.3),
          ChartDataPoint(x: 2.5, y: 73.8),
          ChartDataPoint(x: 5.0, y: 61.4),
          ChartDataPoint(x: 7.5, y: 87.2),
          ChartDataPoint(x: 10, y: 76.9),
        ],
        isXOrdered: true,
      ),
    ];
  }

  Widget _buildChartSection({
    required String title,
    required String description,
    required List<ChartSeries> series,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _selectedTheme == ChartTheme.dark ? Colors.grey.shade800 : Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 400,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BravenChartPlus(
                series: series,
                theme: _selectedTheme,
                backgroundColor: _selectedTheme == ChartTheme.dark ? Colors.grey.shade900 : Colors.white,
                showDebugInfo: _showDebugInfo,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('BravenChartPlus - Feature Showcase'),
        actions: [
          // Theme selector dropdown
          DropdownButton<ChartTheme>(
            value: _selectedTheme,
            items: const [
              DropdownMenuItem(
                value: ChartTheme.light,
                child: Text('Light'),
              ),
              DropdownMenuItem(
                value: ChartTheme.dark,
                child: Text('Dark'),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // Instructions banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade900),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pan: Arrow keys or middle mouse • Zoom: +/- keys or Shift+Wheel • Reset: R or Home',
                      style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),

            // Line Interpolation Chart
            _buildChartSection(
              title: '1. Line Interpolation Comparison',
              description: 'Comparing all line interpolation types: linear, bezier (low/high tension), stepped, and monotone',
              series: _createLineInterpolationData(),
            ),

            // Bar Width Chart
            _buildChartSection(
              title: '2. Bar Width Configurations',
              description: 'Demonstrating different bar width modes: percentage-based (70%, 40%) and pixel-based (30px fixed)',
              series: _createBarWidthData(),
            ),

            // Scatter Chart
            _buildChartSection(
              title: '3. Scatter Plot with Variable Marker Sizes',
              description: 'Showcasing different marker sizes (4px, 6px, 8px) for scatter plots',
              series: _createScatterData(),
            ),

            // Area Chart
            _buildChartSection(
              title: '4. Area Charts with Opacity Variations',
              description: 'Comparing area fill opacities (15%, 30%, 50%) with different interpolation methods',
              series: _createAreaData(),
            ),

            // Mixed Chart
            _buildChartSection(
              title: '5. Mixed Chart Types',
              description: 'Combining lines, bars, and areas in a single chart (e.g., weather data visualization)',
              series: _createMixedData(),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
