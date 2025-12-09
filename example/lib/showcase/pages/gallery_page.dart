// Copyright 2025 Braven Charts - Gallery Page
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Gallery page showcasing multiple charts with different themes and complexities.
class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('Chart Gallery'),
            floating: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 700, // Increased from 500 for bigger charts (3 per row on wide screens)
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildListDelegate([
                _buildMonthlyRevenueChart(isDark),
                _buildTemperatureTrendChart(isDark),
                _buildMixedSeriesTypeChart(isDark), // Line + Area on same chart
                _buildNormalizedCrosshairChart(isDark), // Multi-axis normalized with crosshair tracking
                _buildAnnotatedChart(isDark), // Chart with annotations
                _buildMixedInterpolationChart(isDark), // Multiple interpolation types on one chart
                _buildStockPriceChart(isDark),
                _buildSalesComparisonChart(isDark),
                _buildHeartRateChart(isDark),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyRevenueChart(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Revenue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: const [
                  LineChartSeries(
                    id: 'revenue',
                    name: 'Revenue',
                    points: [
                      ChartDataPoint(x: 1, y: 45000),
                      ChartDataPoint(x: 2, y: 52000),
                      ChartDataPoint(x: 3, y: 49000),
                      ChartDataPoint(x: 4, y: 63000),
                      ChartDataPoint(x: 5, y: 71000),
                      ChartDataPoint(x: 6, y: 68000),
                    ],
                    color: Colors.green,
                    interpolation: LineInterpolation.bezier,
                    strokeWidth: 3.0,
                  ),
                ],
                theme: ChartTheme.light.copyWith(
                  backgroundColor: const Color(0xFFE8F5E9),
                ),
                showLegend: false,
                xAxis: const AxisConfig(label: 'Month', showGrid: true),
                yAxis: const AxisConfig(label: 'USD', showGrid: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureTrendChart(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Temperature Trend',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0B2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('°C', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: const [
                  LineChartSeries(
                    id: 'high',
                    name: 'High',
                    points: [
                      ChartDataPoint(x: 0, y: 28),
                      ChartDataPoint(x: 1, y: 31),
                      ChartDataPoint(x: 2, y: 29),
                      ChartDataPoint(x: 3, y: 33),
                      ChartDataPoint(x: 4, y: 35),
                      ChartDataPoint(x: 5, y: 32),
                      ChartDataPoint(x: 6, y: 30),
                    ],
                    color: Colors.orange,
                    interpolation: LineInterpolation.bezier,
                    strokeWidth: 2.5,
                  ),
                  LineChartSeries(
                    id: 'low',
                    name: 'Low',
                    points: [
                      ChartDataPoint(x: 0, y: 18),
                      ChartDataPoint(x: 1, y: 20),
                      ChartDataPoint(x: 2, y: 19),
                      ChartDataPoint(x: 3, y: 22),
                      ChartDataPoint(x: 4, y: 24),
                      ChartDataPoint(x: 5, y: 21),
                      ChartDataPoint(x: 6, y: 19),
                    ],
                    color: Colors.blue,
                    interpolation: LineInterpolation.bezier,
                    strokeWidth: 2.5,
                  ),
                ],
                theme: isDark ? ChartTheme.dark : ChartTheme.light,
                showLegend: true,
                xAxis: const AxisConfig(showGrid: false),
                yAxis: const AxisConfig(showGrid: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockPriceChart(bool isDark) {
    return Card(
      color: const Color(0xFF1E1E2E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Stock Price',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '+12.5%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: const [
                  LineChartSeries(
                    id: 'stock',
                    name: 'AAPL',
                    points: [
                      ChartDataPoint(x: 0, y: 150),
                      ChartDataPoint(x: 1, y: 155),
                      ChartDataPoint(x: 2, y: 153),
                      ChartDataPoint(x: 3, y: 161),
                      ChartDataPoint(x: 4, y: 168),
                      ChartDataPoint(x: 5, y: 165),
                      ChartDataPoint(x: 6, y: 170),
                      ChartDataPoint(x: 7, y: 169),
                    ],
                    color: Color(0xFF00D9FF),
                    interpolation: LineInterpolation.bezier,
                    strokeWidth: 3.0,
                    showDataPointMarkers: true,
                    dataPointMarkerRadius: 4.0,
                  ),
                ],
                theme: ChartTheme.dark,
                showLegend: false,
                xAxis: const AxisConfig(showGrid: true),
                yAxis: const AxisConfig(showGrid: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesComparisonChart(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Q4 Sales Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: const [
                  LineChartSeries(
                    id: 'product-a',
                    name: 'Product A',
                    points: [
                      ChartDataPoint(x: 10, y: 85),
                      ChartDataPoint(x: 11, y: 92),
                      ChartDataPoint(x: 12, y: 98),
                    ],
                    color: Colors.purple,
                    interpolation: LineInterpolation.linear,
                    strokeWidth: 3.0,
                    showDataPointMarkers: true,
                  ),
                  LineChartSeries(
                    id: 'product-b',
                    name: 'Product B',
                    points: [
                      ChartDataPoint(x: 10, y: 70),
                      ChartDataPoint(x: 11, y: 75),
                      ChartDataPoint(x: 12, y: 82),
                    ],
                    color: Colors.teal,
                    interpolation: LineInterpolation.linear,
                    strokeWidth: 3.0,
                    showDataPointMarkers: true,
                  ),
                  LineChartSeries(
                    id: 'product-c',
                    name: 'Product C',
                    points: [
                      ChartDataPoint(x: 10, y: 60),
                      ChartDataPoint(x: 11, y: 68),
                      ChartDataPoint(x: 12, y: 71),
                    ],
                    color: Colors.amber,
                    interpolation: LineInterpolation.linear,
                    strokeWidth: 3.0,
                    showDataPointMarkers: true,
                  ),
                ],
                theme: ChartTheme.light,
                showLegend: true,
                xAxis: const AxisConfig(label: 'Month', showGrid: false),
                yAxis: const AxisConfig(label: 'Sales', showGrid: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartRateChart(bool isDark) {
    return Card(
      color: const Color(0xFFFCE4EC),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.favorite, color: Color(0xFFC2185B), size: 20),
                SizedBox(width: 8),
                Text(
                  'Heart Rate Monitor',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: [
                  LineChartSeries(
                    id: 'hr',
                    name: 'BPM',
                    points: List.generate(
                      30,
                      (i) => ChartDataPoint(
                        x: i.toDouble(),
                        y: 70 + (i % 3 == 0 ? 15 : (i % 2 == 0 ? -10 : 5)).toDouble(),
                      ),
                    ),
                    color: const Color(0xFFC2185B),
                    interpolation: LineInterpolation.bezier,
                    strokeWidth: 2.0,
                  ),
                ],
                theme: ChartTheme.light,
                showLegend: false,
                xAxis: const AxisConfig(showGrid: false, showAxis: false),
                yAxis: const AxisConfig(showGrid: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnergyConsumptionChart(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt, color: Color(0xFFF57C00), size: 20),
                SizedBox(width: 8),
                Text(
                  'Energy Usage',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: const [
                  LineChartSeries(
                    id: 'energy',
                    name: 'kWh',
                    points: [
                      ChartDataPoint(x: 0, y: 12),
                      ChartDataPoint(x: 4, y: 12),
                      ChartDataPoint(x: 4, y: 25),
                      ChartDataPoint(x: 8, y: 25),
                      ChartDataPoint(x: 8, y: 18),
                      ChartDataPoint(x: 12, y: 18),
                      ChartDataPoint(x: 12, y: 30),
                      ChartDataPoint(x: 16, y: 30),
                      ChartDataPoint(x: 16, y: 15),
                      ChartDataPoint(x: 20, y: 15),
                    ],
                    color: Color(0xFFF57C00),
                    interpolation: LineInterpolation.stepped,
                    strokeWidth: 2.5,
                  ),
                ],
                theme: isDark ? ChartTheme.dark : ChartTheme.light,
                showLegend: false,
                xAxis: const AxisConfig(label: 'Hour', showGrid: false),
                yAxis: const AxisConfig(label: 'kWh', showGrid: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebTrafficChart(bool isDark) {
    return Card(
      color: isDark ? const Color(0xFF212121) : const Color(0xFFE3F2FD),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Website Traffic',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: const [
                  LineChartSeries(
                    id: 'visitors',
                    name: 'Visitors',
                    points: [
                      ChartDataPoint(x: 1, y: 1200),
                      ChartDataPoint(x: 2, y: 1850),
                      ChartDataPoint(x: 3, y: 1600),
                      ChartDataPoint(x: 4, y: 2200),
                      ChartDataPoint(x: 5, y: 2800),
                      ChartDataPoint(x: 6, y: 2400),
                      ChartDataPoint(x: 7, y: 3100),
                    ],
                    color: Color(0xFF1976D2),
                    interpolation: LineInterpolation.bezier,
                    strokeWidth: 2.5,
                  ),
                  LineChartSeries(
                    id: 'pageviews',
                    name: 'Page Views',
                    points: [
                      ChartDataPoint(x: 1, y: 3200),
                      ChartDataPoint(x: 2, y: 4500),
                      ChartDataPoint(x: 3, y: 4100),
                      ChartDataPoint(x: 4, y: 5800),
                      ChartDataPoint(x: 5, y: 7200),
                      ChartDataPoint(x: 6, y: 6400),
                      ChartDataPoint(x: 7, y: 8500),
                    ],
                    color: Color(0xFF5E35B1),
                    interpolation: LineInterpolation.bezier,
                    strokeWidth: 2.0,
                  ),
                ],
                theme: ChartTheme.light.copyWith(
                  backgroundColor: const Color(0xFFE3F2FD),
                ),
                showLegend: true,
                xAxis: const AxisConfig(label: 'Day', showGrid: false),
                yAxis: const AxisConfig(showGrid: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectTimelineChart(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Project Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: const [
                  LineChartSeries(
                    id: 'planned',
                    name: 'Planned',
                    points: [
                      ChartDataPoint(x: 0, y: 0),
                      ChartDataPoint(x: 1, y: 20),
                      ChartDataPoint(x: 2, y: 40),
                      ChartDataPoint(x: 3, y: 60),
                      ChartDataPoint(x: 4, y: 80),
                      ChartDataPoint(x: 5, y: 100),
                    ],
                    color: Color(0xFFBDBDBD),
                    interpolation: LineInterpolation.linear,
                    strokeWidth: 2.0,
                  ),
                  LineChartSeries(
                    id: 'actual',
                    name: 'Actual',
                    points: [
                      ChartDataPoint(x: 0, y: 0),
                      ChartDataPoint(x: 1, y: 15),
                      ChartDataPoint(x: 2, y: 35),
                      ChartDataPoint(x: 3, y: 52),
                      ChartDataPoint(x: 4, y: 75),
                    ],
                    color: Colors.deepPurple,
                    interpolation: LineInterpolation.bezier,
                    strokeWidth: 3.0,
                    showDataPointMarkers: true,
                  ),
                ],
                theme: isDark ? ChartTheme.dark : ChartTheme.light,
                showLegend: true,
                xAxis: const AxisConfig(label: 'Week', showGrid: false),
                yAxis: const AxisConfig(label: '% Complete', showGrid: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCpuUsageChart(bool isDark) {
    return Card(
      color: const Color(0xFF0F172A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text(
                  'CPU Usage',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                Text(
                  '42%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF67E8F9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: [
                  LineChartSeries(
                    id: 'cpu',
                    name: 'CPU',
                    points: List.generate(
                      50,
                      (i) => ChartDataPoint(
                        x: i.toDouble(),
                        y: 30 + (i * 1.5) % 40 + (i % 5) * 3,
                      ),
                    ),
                    color: const Color(0xFF67E8F9),
                    interpolation: LineInterpolation.bezier,
                    strokeWidth: 2.0,
                  ),
                ],
                theme: ChartTheme.dark,
                showLegend: false,
                xAxis: const AxisConfig(showGrid: false, showAxis: false),
                yAxis: const AxisConfig(showGrid: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mixed series types: Line + Area on same chart
  Widget _buildMixedSeriesTypeChart(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue & Forecast',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text('Line + Area Chart', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: const [
                  LineChartSeries(
                    id: 'actual',
                    name: 'Actual Revenue',
                    points: [
                      ChartDataPoint(x: 1, y: 45000),
                      ChartDataPoint(x: 2, y: 52000),
                      ChartDataPoint(x: 3, y: 48000),
                      ChartDataPoint(x: 4, y: 61000),
                      ChartDataPoint(x: 5, y: 58000),
                      ChartDataPoint(x: 6, y: 67000),
                      ChartDataPoint(x: 7, y: 71000),
                    ],
                    color: Color(0xFF10B981),
                    interpolation: LineInterpolation.bezier,
                    strokeWidth: 3.0,
                    showDataPointMarkers: true,
                    dataPointMarkerRadius: 4.0,
                  ),
                  AreaChartSeries(
                    id: 'forecast',
                    name: 'Forecast Range',
                    points: [
                      ChartDataPoint(x: 1, y: 65000),
                      ChartDataPoint(x: 2, y: 48000),
                      ChartDataPoint(x: 3, y: 52000),
                      ChartDataPoint(x: 4, y: 59000),
                      ChartDataPoint(x: 5, y: 55000),
                      ChartDataPoint(x: 6, y: 64000),
                    ],
                    color: Color(0xFF3B82F6),
                    interpolation: LineInterpolation.linear,
                    strokeWidth: 2.0,
                    fillOpacity: 0.3,
                  ),
                ],
                theme: ChartTheme.light,
                showLegend: true,
                xAxis: const AxisConfig(label: 'Month'),
                yAxis: const AxisConfig(label: 'Revenue (\$)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Multi-axis normalized data with crosshair tracking mode
  Widget _buildNormalizedCrosshairChart(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Multi-Sensor Monitoring',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text('Normalized + Crosshair Tracking', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: [
                  LineChartSeries(
                    id: 'pressure',
                    name: 'Pressure',
                    points: List.generate(
                      300, // High data point count triggers tracking mode
                      (i) => ChartDataPoint(
                        x: i.toDouble(),
                        y: 1000 + (i * 2.5) % 100 + (i % 10) * 5,
                      ),
                    ),
                    color: const Color(0xFFEF4444),
                    interpolation: LineInterpolation.linear,
                    strokeWidth: 1.5,
                    yAxisConfig: YAxisConfig(
                      id: 'pressure-axis',
                      position: YAxisPosition.left,
                      label: 'Pressure',
                      unit: 'Pa',
                    ),
                    unit: 'Pa',
                  ),
                  LineChartSeries(
                    id: 'temperature',
                    name: 'Temperature',
                    points: List.generate(
                      300,
                      (i) => ChartDataPoint(
                        x: i.toDouble(),
                        y: 20 + (i * 0.05) % 15 + (i % 8) * 0.5,
                      ),
                    ),
                    color: const Color(0xFFF59E0B),
                    interpolation: LineInterpolation.linear,
                    strokeWidth: 1.5,
                    yAxisConfig: YAxisConfig(
                      id: 'temperature-axis',
                      position: YAxisPosition.right,
                      label: 'Temp',
                      unit: '°C',
                    ),
                    unit: '°C',
                  ),
                ],
                theme: ChartTheme.light,
                showLegend: true,
                normalizationMode: NormalizationMode.perSeries,
                xAxis: const AxisConfig(label: 'Sample'),
                interactionConfig: const InteractionConfig(
                  crosshair: CrosshairConfig(
                    enabled: true,
                    mode: CrosshairMode.vertical,
                    snapToDataPoint: true,
                    showCoordinateLabels: true,
                    displayMode: CrosshairDisplayMode.auto, // Will use tracking mode for 300 points
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Chart with annotations
  Widget _buildAnnotatedChart(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Annotated Analysis',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text('Point, Range & Threshold', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: const [
                  LineChartSeries(
                    id: 'metrics',
                    name: 'Performance',
                    points: [
                      ChartDataPoint(x: 1, y: 65),
                      ChartDataPoint(x: 2, y: 72),
                      ChartDataPoint(x: 3, y: 68),
                      ChartDataPoint(x: 4, y: 85), // Peak point
                      ChartDataPoint(x: 5, y: 78),
                      ChartDataPoint(x: 6, y: 82),
                      ChartDataPoint(x: 7, y: 75),
                      ChartDataPoint(x: 8, y: 88),
                    ],
                    color: Color(0xFF8B5CF6),
                    interpolation: LineInterpolation.bezier,
                    strokeWidth: 2.5,
                  ),
                ],
                annotations: [
                  PointAnnotation(
                    id: 'peak',
                    seriesId: 'metrics',
                    dataPointIndex: 3, // Point at x=4, y=85
                    markerShape: MarkerShape.star,
                    markerSize: 12.0,
                    markerColor: Colors.amber,
                    label: 'Peak',
                    labelMargin: 8.0,
                  ),
                  RangeAnnotation(
                    id: 'target_range',
                    startX: 1,
                    endX: 8,
                    startY: 70,
                    endY: 90,
                    label: 'Target Zone',
                    fillColor: const Color(0x1A10B981),
                    borderColor: const Color(0xFF10B981),
                  ),
                  ThresholdAnnotation(
                    id: 'critical',
                    axis: AnnotationAxis.y,
                    value: 80,
                    label: 'Critical Threshold',
                    lineColor: const Color(0xFFEF4444),
                    lineWidth: 2.0,
                    dashPattern: const [8, 4],
                  ),
                ],
                theme: ChartTheme.light,
                showLegend: false,
                xAxis: const AxisConfig(label: 'Week'),
                yAxis: const AxisConfig(label: 'Score'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Multiple interpolation types on one chart
  Widget _buildMixedInterpolationChart(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Interpolation Showcase',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text('Linear, Bezier, Stepped, Monotone', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: const [
                  LineChartSeries(
                    id: 'linear',
                    name: 'Linear',
                    points: [
                      ChartDataPoint(x: 1, y: 10),
                      ChartDataPoint(x: 2, y: 35),
                      ChartDataPoint(x: 3, y: 25),
                      ChartDataPoint(x: 4, y: 50),
                      ChartDataPoint(x: 5, y: 40),
                    ],
                    color: Color(0xFF3B82F6),
                    interpolation: LineInterpolation.linear,
                    strokeWidth: 2.0,
                  ),
                  LineChartSeries(
                    id: 'bezier',
                    name: 'Bezier',
                    points: [
                      ChartDataPoint(x: 1, y: 20),
                      ChartDataPoint(x: 2, y: 45),
                      ChartDataPoint(x: 3, y: 35),
                      ChartDataPoint(x: 4, y: 60),
                      ChartDataPoint(x: 5, y: 50),
                    ],
                    color: Color(0xFF10B981),
                    interpolation: LineInterpolation.bezier,
                    tension: 0.4,
                    strokeWidth: 2.0,
                  ),
                  LineChartSeries(
                    id: 'stepped',
                    name: 'Stepped',
                    points: [
                      ChartDataPoint(x: 1, y: 30),
                      ChartDataPoint(x: 2, y: 55),
                      ChartDataPoint(x: 3, y: 45),
                      ChartDataPoint(x: 4, y: 70),
                      ChartDataPoint(x: 5, y: 60),
                    ],
                    color: Color(0xFFF59E0B),
                    interpolation: LineInterpolation.stepped,
                    strokeWidth: 2.0,
                  ),
                  LineChartSeries(
                    id: 'monotone',
                    name: 'Monotone',
                    points: [
                      ChartDataPoint(x: 1, y: 15),
                      ChartDataPoint(x: 2, y: 40),
                      ChartDataPoint(x: 3, y: 30),
                      ChartDataPoint(x: 4, y: 55),
                      ChartDataPoint(x: 5, y: 45),
                    ],
                    color: Color(0xFFEF4444),
                    interpolation: LineInterpolation.monotone,
                    strokeWidth: 2.0,
                  ),
                ],
                theme: ChartTheme.light,
                showLegend: true,
                xAxis: const AxisConfig(label: 'X'),
                yAxis: const AxisConfig(label: 'Y'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
