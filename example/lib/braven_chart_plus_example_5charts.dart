// Copyright (c) 2025 braven_charts. All rights reserved.
// 5-Chart Performance Test - Reproducing bad commit configuration

import 'package:braven_charts/src_plus/models/chart_data_point.dart';
import 'package:braven_charts/src_plus/models/chart_series.dart';
import 'package:braven_charts/src_plus/models/chart_theme.dart';
import 'package:braven_charts/src_plus/models/chart_type.dart';
import 'package:braven_charts/src_plus/widgets/braven_chart_plus.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BravenChart5ChartsApp());
}

class BravenChart5ChartsApp extends StatelessWidget {
  const BravenChart5ChartsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BravenChartPlus - 5 Charts Performance Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BravenChart5ChartsPage(),
    );
  }
}

class BravenChart5ChartsPage extends StatefulWidget {
  const BravenChart5ChartsPage({super.key});

  @override
  State<BravenChart5ChartsPage> createState() => _BravenChart5ChartsPageState();
}

class _BravenChart5ChartsPageState extends State<BravenChart5ChartsPage> {
  bool _showDebugInfo = false;
  ChartTheme _selectedTheme = ChartTheme.light;

  // Cache series lists to prevent unnecessary regeneration on rebuild
  late final List<ChartSeries> _lineInterpolationSeries;
  late final List<ChartSeries> _barWidthSeries;
  late final List<ChartSeries> _scatterSeries;
  late final List<ChartSeries> _areaSeries;
  late final List<ChartSeries> _mixedSeries;

  @override
  void initState() {
    super.initState();
    // Initialize cached series lists once
    _lineInterpolationSeries = _createLineInterpolationData();
    _barWidthSeries = _createBarWidthData();
    _scatterSeries = _createScatterData();
    _areaSeries = _createAreaData();
    _mixedSeries = _createMixedData();
  }

  // Chart 1: Line Interpolation Comparison - ALL interpolation types (5 series)
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
      // const LineChartSeries(
      //   id: 'line_monotone',
      //   name: 'Monotone',
      //   interpolation: LineInterpolation.monotone,
      //   strokeWidth: 2.5,
      //   showDataPointMarkers: true,
      //   dataPointMarkerRadius: 4.5,
      //   points: [
      //     ChartDataPoint(x: 0, y: 39.4),
      //     ChartDataPoint(x: 1.4, y: 67.8),
      //     ChartDataPoint(x: 3.1, y: 52.6),
      //     ChartDataPoint(x: 4.9, y: 90.3),
      //     ChartDataPoint(x: 6.5, y: 59.7),
      //     ChartDataPoint(x: 8.2, y: 94.1),
      //     ChartDataPoint(x: 9.6, y: 72.9),
      //     ChartDataPoint(x: 10, y: 80.6),
      //   ],
      //   isXOrdered: true,
      // ),
      const LineChartSeries(
        id: 'line_linear2',
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
    ];
  }

  // Chart 2: Bar Width Configurations (3 series)
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

  // Chart 3: Scatter Plots with Variable Marker Sizes (3 series)
  List<ChartSeries> _createScatterData() {
    return [
      const ScatterChartSeries(
        id: 'scatter_4px',
        name: '4px Markers',
        markerRadius: 4.0,
        points: [
          ChartDataPoint(x: 1.3, y: 62.7),
          ChartDataPoint(x: 2.9, y: 78.4),
          ChartDataPoint(x: 4.7, y: 55.1),
          ChartDataPoint(x: 6.2, y: 89.3),
          ChartDataPoint(x: 7.8, y: 71.6),
          ChartDataPoint(x: 9.4, y: 83.8),
        ],
        isXOrdered: true,
      ),
      const ScatterChartSeries(
        id: 'scatter_6px',
        name: '6px Markers',
        markerRadius: 6.0,
        points: [
          ChartDataPoint(x: 0.9, y: 58.2),
          ChartDataPoint(x: 2.5, y: 74.9),
          ChartDataPoint(x: 4.3, y: 51.7),
          ChartDataPoint(x: 5.8, y: 85.4),
          ChartDataPoint(x: 7.4, y: 68.1),
          ChartDataPoint(x: 9.0, y: 79.5),
        ],
        isXOrdered: true,
      ),
      const ScatterChartSeries(
        id: 'scatter_8px',
        name: '8px Markers',
        markerRadius: 8.0,
        points: [
          ChartDataPoint(x: 1.7, y: 54.6),
          ChartDataPoint(x: 3.3, y: 70.2),
          ChartDataPoint(x: 5.1, y: 47.8),
          ChartDataPoint(x: 6.6, y: 81.9),
          ChartDataPoint(x: 8.2, y: 64.3),
          ChartDataPoint(x: 9.8, y: 75.7),
        ],
        isXOrdered: true,
      ),
    ];
  }

  // Chart 4: Area Charts with Opacity Variations (3 series)
  List<ChartSeries> _createAreaData() {
    return [
      const AreaChartSeries(
        id: 'area_15_opacity',
        name: '15% Opacity',
        interpolation: LineInterpolation.bezier,
        tension: 0.4,
        fillOpacity: 0.15,
        strokeWidth: 2.0,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 3.0,
        points: [
          ChartDataPoint(x: 0, y: 45.8),
          ChartDataPoint(x: 1.5, y: 69.3),
          ChartDataPoint(x: 3.2, y: 52.7),
          ChartDataPoint(x: 4.8, y: 88.1),
          ChartDataPoint(x: 6.4, y: 61.4),
          ChartDataPoint(x: 8.0, y: 92.6),
          ChartDataPoint(x: 9.5, y: 74.9),
          ChartDataPoint(x: 10, y: 82.3),
        ],
        isXOrdered: true,
      ),
      const AreaChartSeries(
        id: 'area_30_opacity',
        name: '30% Opacity',
        interpolation: LineInterpolation.bezier,
        tension: 0.5,
        fillOpacity: 0.30,
        strokeWidth: 2.5,
        showDataPointMarkers: false,
        points: [
          ChartDataPoint(x: 0, y: 41.2),
          ChartDataPoint(x: 1.8, y: 65.7),
          ChartDataPoint(x: 3.5, y: 48.9),
          ChartDataPoint(x: 5.1, y: 84.3),
          ChartDataPoint(x: 6.7, y: 57.6),
          ChartDataPoint(x: 8.3, y: 88.9),
          ChartDataPoint(x: 9.8, y: 71.2),
          ChartDataPoint(x: 10, y: 78.5),
        ],
        isXOrdered: true,
      ),
      const AreaChartSeries(
        id: 'area_50_opacity',
        name: '50% Opacity',
        interpolation: LineInterpolation.bezier,
        tension: 0.6,
        fillOpacity: 0.50,
        strokeWidth: 2.0,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 2.5,
        points: [
          ChartDataPoint(x: 0, y: 37.9),
          ChartDataPoint(x: 2.1, y: 62.4),
          ChartDataPoint(x: 3.8, y: 45.3),
          ChartDataPoint(x: 5.4, y: 80.7),
          ChartDataPoint(x: 7.0, y: 54.1),
          ChartDataPoint(x: 8.6, y: 85.2),
          ChartDataPoint(x: 9.6, y: 67.8),
          ChartDataPoint(x: 10, y: 74.9),
        ],
        isXOrdered: true,
      ),
    ];
  }

  // Chart 5: Mixed Chart Types (3 series)
  List<ChartSeries> _createMixedData() {
    return [
      const LineChartSeries(
        id: 'mixed_temp',
        name: 'Temperature',
        interpolation: LineInterpolation.bezier,
        tension: 0.5,
        strokeWidth: 2.5,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 4.0,
        points: [
          ChartDataPoint(x: 0, y: 18.3),
          ChartDataPoint(x: 2, y: 22.7),
          ChartDataPoint(x: 4, y: 25.1),
          ChartDataPoint(x: 6, y: 28.9),
          ChartDataPoint(x: 8, y: 24.6),
          ChartDataPoint(x: 10, y: 20.2),
        ],
        isXOrdered: true,
      ),
      const BarChartSeries(
        id: 'mixed_precipitation',
        name: 'Precipitation',
        barWidthPercent: 0.5,
        minWidth: 4.0,
        maxWidth: 60.0,
        points: [
          ChartDataPoint(x: 1, y: 12.4),
          ChartDataPoint(x: 3, y: 8.7),
          ChartDataPoint(x: 5, y: 15.2),
          ChartDataPoint(x: 7, y: 6.8),
          ChartDataPoint(x: 9, y: 10.5),
        ],
        isXOrdered: true,
      ),
      const AreaChartSeries(
        id: 'mixed_humidity',
        name: 'Humidity',
        interpolation: LineInterpolation.linear,
        fillOpacity: 0.2,
        strokeWidth: 2.0,
        showDataPointMarkers: false,
        points: [
          ChartDataPoint(x: 0, y: 65.3),
          ChartDataPoint(x: 2, y: 72.8),
          ChartDataPoint(x: 4, y: 68.4),
          ChartDataPoint(x: 6, y: 75.9),
          ChartDataPoint(x: 8, y: 70.2),
          ChartDataPoint(x: 10, y: 67.6),
        ],
        isXOrdered: true,
      ),
    ];
  }

  Widget _buildChartSection({
    required String title,
    required String description,
    required List<ChartSeries> series,
    required String chartKey, // Add key parameter
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
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
              height: 350,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: BravenChartPlus(
                  key: ValueKey(chartKey), // Add key to preserve widget identity
                  chartType: ChartType.line,
                  series: series,
                  theme: _selectedTheme,
                  backgroundColor: _selectedTheme == ChartTheme.dark ? Colors.grey.shade900 : Colors.white,
                  showDebugInfo: _showDebugInfo,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total series count
    int totalSeries = 5 + 3 + 3 + 3 + 3; // 17 series total
    int totalPoints = (5 * 8) + (3 * 6) + (3 * 6) + (3 * 8) + (1 * 6) + (1 * 5) + (1 * 6); // ~100 points

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('BravenChartPlus - 5 Charts Performance Test'),
        actions: [
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

            // Warning banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red.shade900),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ PERFORMANCE TEST - Reproducing Bad Commit Configuration',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '5 charts × $totalSeries series × ~$totalPoints total points\n'
                          'Features: Monotone interpolation, Multiple bezier tensions, Variable opacities, Mixed types\n'
                          'Watch for lag during pan/zoom operations!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

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

            // Chart 1: Line Interpolation (5 series)
            _buildChartSection(
              title: '1. Line Interpolation Comparison',
              description: 'ALL interpolation types: linear, bezier (low/high tension), stepped, and MONOTONE',
              series: _lineInterpolationSeries,
              chartKey: 'chart_line_interpolation',
            ),

            // // Chart 2: Bar Width (3 series)
            // _buildChartSection(
            //   title: '2. Bar Width Configurations',
            //   description: 'Different bar width modes: percentage-based (70%, 40%) and pixel-based (30px fixed)',
            //   series: _barWidthSeries,
            //   chartKey: 'chart_bar_width',
            // ),

            // // Chart 3: Scatter (3 series)
            // _buildChartSection(
            //   title: '3. Scatter Plot with Variable Marker Sizes',
            //   description: 'Different marker sizes (4px, 6px, 8px) for scatter plots',
            //   series: _scatterSeries,
            //   chartKey: 'chart_scatter',
            // ),

            // // Chart 4: Area (3 series)
            // _buildChartSection(
            //   title: '4. Area Charts with Opacity Variations',
            //   description: 'Multiple fill opacities (15%, 30%, 50%) with different interpolation methods',
            //   series: _areaSeries,
            //   chartKey: 'chart_area',
            // ),

            // // Chart 5: Mixed (3 series)
            // _buildChartSection(
            //   title: '5. Mixed Chart Types',
            //   description: 'Combining lines, bars, and areas in a single chart (weather data visualization)',
            //   series: _mixedSeries,
            //   chartKey: 'chart_mixed',
            // ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
