// Copyright 2025 Braven Charts - Gallery Page
// SPDX-License-Identifier: MIT

import 'dart:math';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

import '../data/ecg_generator.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: CustomScrollView(
          shrinkWrap: true,
          slivers: [
            SliverAppBar(
              title: Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chart Gallery',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Multitude of chart configurations",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              floating: true,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 750, // Increased from 500 for bigger charts (3 per row on wide screens)
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
                  _buildEnergyConsumptionChart(isDark), // Energy usage pattern
                  _buildWebTrafficChart(isDark), // Website traffic
                  _buildProjectTimelineChart(isDark), // Project progress
                  _buildCpuUsageChart(isDark), // Real-time CPU monitoring
                  // Segment Colors Showcases - Lines
                  _buildThresholdColoringChart(isDark), // Color by Y threshold
                  _buildGradientSegmentsChart(isDark), // Rainbow gradient segments
                  _buildStockGainLossChart(isDark), // Green/red for gain/loss
                  // Segment Colors Showcases - Areas
                  _buildTemperatureZonesAreaChart(isDark), // Area with hot/cold zones
                  _buildProfitLossAreaChart(isDark), // Area with profit/loss coloring
                  // Multi-Series Mixed Charts
                  _buildMultiLayerAnalyticsChart(isDark), // 3 areas + 2 lines
                  _buildNetworkTrafficChart(isDark), // Upload/download areas + latency line
                  _buildFinancialDashboardChart(isDark), // Multiple indicators
                ]),
              ),
            ),
          ],
        ),
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
                    strokeWidth: 4.0,
                    showDataPointMarkers: true,
                    dataPointMarkerRadius: 5.0,
                  ),
                ],
                annotations: [
                  ThresholdAnnotation(
                    id: 'target',
                    axis: AnnotationAxis.y,
                    value: 60000,
                    label: 'Target',
                    lineColor: const Color(0xFF2E7D32),
                    lineWidth: 2.0,
                    dashPattern: const [6, 3],
                  ),
                ],
                theme: ChartTheme.light.copyWith(
                  backgroundColor: const Color(0xFFE8F5E9),
                ),
                showLegend: true,
                interactionConfig: const InteractionConfig(
                    crosshair: CrosshairConfig(
                      enabled: true,
                    ),
                    tooltip: TooltipConfig(
                        enabled: true,
                        hideDelay: Duration(milliseconds: 500),
                        showDelay: Duration(milliseconds: 50),
                        triggerMode: TooltipTriggerMode.hover)),
                xAxis: const AxisConfig(label: 'Month', showGrid: true),
                yAxis: const AxisConfig(label: 'USD', showGrid: false),
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
                    strokeWidth: 3.5,
                    showDataPointMarkers: true,
                    dataPointMarkerRadius: 4.0,
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
                    strokeWidth: 3.5,
                    showDataPointMarkers: true,
                    dataPointMarkerRadius: 4.0,
                  ),
                ],
                theme: isDark ? ChartTheme.dark : ChartTheme.light,
                showLegend: true,
                legendStyle: const LegendStyle(orientation: LegendOrientation.vertical),
                xAxis: const AxisConfig(showGrid: false, showAxis: false),
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
                    strokeWidth: 2.5,
                    showDataPointMarkers: true,
                    dataPointMarkerRadius: 6.0,
                  ),
                ],
                theme: ChartTheme.dark,
                showLegend: false,
                xAxis: const AxisConfig(showGrid: false, showAxis: false),
                yAxis: const AxisConfig(showGrid: false),
                interactionConfig: const InteractionConfig(
                  crosshair: CrosshairConfig(
                    enabled: true,
                    mode: CrosshairMode.both,
                    snapToDataPoint: true,
                    showCoordinateLabels: true,
                  ),
                ),
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
                    strokeWidth: 4.0,
                    showDataPointMarkers: true,
                    dataPointMarkerRadius: 7.0,
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
                    dataPointMarkerRadius: 5.0,
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
                    strokeWidth: 2.0,
                    showDataPointMarkers: true,
                    dataPointMarkerRadius: 4.0,
                  ),
                ],
                theme: ChartTheme.light,
                showLegend: true,
                xAxis: const AxisConfig(label: 'Month', showGrid: true),
                yAxis: const AxisConfig(label: 'Sales', showGrid: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartRateChart(bool isDark) {
    // Generate realistic ECG data
    final generator = EcgDataGenerator(heartRateBpm: 70, samplesPerSecond: 250);
    final ecgData = generator.generateEcgData(5.0); // 10 seconds of data

    // Convert Point<double> to ChartDataPoint
    final points = ecgData.map((p) => ChartDataPoint(x: p.x, y: p.y)).toList();

    return Card(
      color: const Color(0xFF0D1117), // Dark medical monitor look
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monitor_heart, color: Color(0xFF00FF00), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'ECG Monitor',
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
                    color: const Color(0xFF00FF00).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '70 BPM',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
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
                series: [
                  LineChartSeries(
                    id: 'ecg',
                    name: 'ECG',
                    points: points,
                    color: const Color(0xFF00FF00), // Classic ECG green
                    interpolation: LineInterpolation.linear,
                    strokeWidth: 1.5,
                  ),
                ],
                theme: ChartTheme.dark.copyWith(
                  backgroundColor: const Color(0xFF0D1117),
                ),
                showLegend: false,
                xAxis: const AxisConfig(label: 'Time (s)', showGrid: true, showAxis: false),
                yAxis: const AxisConfig(label: 'mV', showGrid: true, showAxis: false),
                interactionConfig: const InteractionConfig(
                  crosshair: CrosshairConfig(
                    enabled: true,
                    mode: CrosshairMode.vertical,
                    snapToDataPoint: true,
                    displayMode: CrosshairDisplayMode.tracking,
                  ),
                ),
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
                    strokeWidth: 3.5,
                  ),
                ],
                annotations: [
                  RangeAnnotation(
                    id: 'peak_hours',
                    startX: 12,
                    endX: 16,
                    label: 'Peak Hours',
                    fillColor: const Color(0x20FF5722),
                    borderColor: const Color(0xFFFF5722),
                  ),
                ],
                theme: isDark ? ChartTheme.dark : ChartTheme.light,
                showLegend: false,
                xAxis: const AxisConfig(label: 'Hour', showGrid: true),
                yAxis: const AxisConfig(label: 'kWh', showGrid: false),
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
                    strokeWidth: 3.0,
                    showDataPointMarkers: true,
                    dataPointMarkerRadius: 3.5,
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
                    strokeWidth: 2.5,
                    showDataPointMarkers: true,
                    dataPointMarkerRadius: 3.5,
                  ),
                ],
                theme: ChartTheme.light.copyWith(
                  backgroundColor: const Color(0xFFE3F2FD),
                ),
                showLegend: true,
                legendStyle: const LegendStyle(orientation: LegendOrientation.vertical),
                normalizationMode: NormalizationMode.perSeries,
                xAxis: const AxisConfig(label: 'Day', showGrid: true),
                yAxis: const AxisConfig(showGrid: false, showAxis: false),
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
                    strokeWidth: 1.5,
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
                    strokeWidth: 3.5,
                    showDataPointMarkers: true,
                    dataPointMarkerRadius: 5.0,
                  ),
                ],
                annotations: [
                  ThresholdAnnotation(
                    id: 'milestone',
                    axis: AnnotationAxis.x,
                    value: 3,
                    label: 'Milestone',
                    lineColor: const Color(0xFF9C27B0),
                    lineWidth: 2.0,
                    dashPattern: const [5, 3],
                  ),
                ],
                theme: isDark ? ChartTheme.dark : ChartTheme.light,
                showLegend: true,
                xAxis: const AxisConfig(label: 'Week', showGrid: false, showAxis: false),
                yAxis: const AxisConfig(label: '% Complete', showGrid: false),
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
                      strokeWidth: 1.5,
                      yAxisConfig: YAxisConfig(
                        id: 'cpu',
                        position: YAxisPosition.left,
                        visible: true,
                        labelDisplay: AxisLabelDisplay.labelWithUnitAndTickUnit,
                        showAxisLine: true,
                        showCrosshairLabel: true,
                      )),
                ],
                annotations: [
                  ThresholdAnnotation(
                    id: 'warning',
                    axis: AnnotationAxis.y,
                    value: 70,
                    label: 'Warning',
                    lineColor: const Color(0xFFFBBF24),
                    lineWidth: 1.5,
                    dashPattern: const [3, 2],
                  ),
                  ThresholdAnnotation(
                    id: 'critical',
                    axis: AnnotationAxis.y,
                    value: 90,
                    label: 'Critical',
                    lineColor: const Color(0xFFEF4444),
                    lineWidth: 1.5,
                    dashPattern: const [3, 2],
                  ),
                ],
                normalizationMode: NormalizationMode.auto,
                theme: ChartTheme.dark,
                showLegend: false,
                xAxis: const AxisConfig(showGrid: false, showAxis: false),
                yAxis: const AxisConfig(showGrid: false, showAxis: true),
                interactionConfig: const InteractionConfig(
                  crosshair: CrosshairConfig(
                      enabled: true,
                      mode: CrosshairMode.vertical,
                      snapToDataPoint: true,
                      displayMode: CrosshairDisplayMode.tracking,
                      showTrackingTooltip: true),
                ),
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
                    tension: 0.25,
                    strokeWidth: 4.0,
                    showDataPointMarkers: true,
                    dataPointMarkerRadius: 4.5,
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
                      ChartDataPoint(x: 7, y: 48000),
                    ],
                    color: Color(0xFF3B82F6),
                    interpolation: LineInterpolation.bezier,
                    showDataPointMarkers: false,
                    tension: 0.2,
                    strokeWidth: 1.5,
                    fillOpacity: 0.25,
                  ),
                ],
                theme: ChartTheme.light,
                showLegend: true,
                legendStyle: const LegendStyle(orientation: LegendOrientation.vertical),
                xAxis: const AxisConfig(label: 'Month', showGrid: false, showAxis: false),
                yAxis: const AxisConfig(label: 'Revenue (\$)', showGrid: true),
                interactionConfig: const InteractionConfig(
                  crosshair: CrosshairConfig(
                    enabled: true,
                    mode: CrosshairMode.vertical,
                    snapToDataPoint: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Multi-axis normalized data with crosshair tracking mode
  Widget _buildNormalizedCrosshairChart(bool isDark) {
    var random = Random();
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
                      50, // High data point count triggers tracking mode
                      (i) => ChartDataPoint(
                        x: i.toDouble(),
                        y: random.nextInt(1000) + (i * 2.5) % 100 + (i % 10) * 5,
                        // 1000 + (i * 2.5) % 100 + (i % 10) * 5,
                      ),
                    ),
                    color: Colors.red,
                    interpolation: LineInterpolation.bezier,
                    tension: 0.2,
                    strokeWidth: 4.0,
                    yAxisConfig: YAxisConfig(
                      id: 'pressure-axis',
                      position: YAxisPosition.left,
                      labelDisplay: AxisLabelDisplay.labelWithUnitAndTickUnit,
                      label: 'Pressure',
                      unit: 'Pa',
                    ),
                    unit: 'Pa',
                  ),
                  LineChartSeries(
                    id: 'temperature',
                    name: 'Temperature',
                    points: List.generate(
                      50,
                      (i) => ChartDataPoint(
                        x: i.toDouble(),
                        y: random.nextInt(20) + (i * 0.05) % 15 + (i % 8) * 0.5,
                      ),
                    ),
                    color: const Color(0xFFF59E0B),
                    interpolation: LineInterpolation.bezier,
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
                theme: ChartTheme.dark,
                showLegend: false,
                normalizationMode: NormalizationMode.perSeries,
                xAxis: const AxisConfig(label: 'Sample'),
                interactionConfig: const InteractionConfig(
                  crosshair: CrosshairConfig(
                    enabled: true,
                    mode: CrosshairMode.vertical,
                    snapToDataPoint: true,
                    showCoordinateLabels: true,
                    displayMode: CrosshairDisplayMode.tracking, // Will use tracking mode for 300 points
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
                    strokeWidth: 3.0,
                    showDataPointMarkers: true,
                    dataPointMarkerRadius: 4.0,
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
                    strokeWidth: 2.5,
                    showDataPointMarkers: true,
                    dataPointMarkerRadius: 3.5,
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
                    showDataPointMarkers: true,
                    dataPointMarkerRadius: 3.0,
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
                    strokeWidth: 1.5,
                    showDataPointMarkers: true,
                    dataPointMarkerRadius: 2.5,
                  ),
                ],
                theme: ChartTheme.light,
                showLegend: true,
                xAxis: const AxisConfig(label: 'X', showGrid: true, showAxis: false),
                yAxis: const AxisConfig(label: 'Y', showGrid: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // Segment Colors Showcases
  // ==========================================================================

  /// Threshold-based coloring: segments colored by Y value
  Widget _buildThresholdColoringChart(bool isDark) {
    // Generate data with varying Y values
    final points = <ChartDataPoint>[
      const ChartDataPoint(x: 0, y: 45),
      const ChartDataPoint(x: 1, y: 52),
      const ChartDataPoint(x: 2, y: 78),
      const ChartDataPoint(x: 3, y: 85),
      const ChartDataPoint(x: 4, y: 92),
      const ChartDataPoint(x: 5, y: 88),
      const ChartDataPoint(x: 6, y: 65),
      const ChartDataPoint(x: 7, y: 55),
      const ChartDataPoint(x: 8, y: 48),
      const ChartDataPoint(x: 9, y: 72),
      const ChartDataPoint(x: 10, y: 95),
    ];

    // Create series and apply threshold coloring
    var series = LineChartSeries(
      id: 'threshold',
      name: 'System Load',
      points: points,
      color: const Color(0xFF10B981), // Green = normal
      interpolation: LineInterpolation.bezier,
      strokeWidth: 3.0,
    );

    // Color segments based on next point's Y value (threshold at 80)
    series = series.withColorWhere(
      (point) => point.y >= 80,
      const Color(0xFFEF4444), // Red = high load
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.speed, color: Color(0xFF10B981), size: 20),
                SizedBox(width: 8),
                Text(
                  'System Load Monitor',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Threshold Coloring', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('< 80%', style: TextStyle(fontSize: 10, color: Color(0xFF10B981))),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('≥ 80%', style: TextStyle(fontSize: 10, color: Color(0xFFEF4444))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: [series],
                annotations: [
                  ThresholdAnnotation(
                    id: 'threshold-line',
                    axis: AnnotationAxis.y,
                    value: 80,
                    label: '80% Threshold',
                    lineColor: const Color(0xFFEF4444),
                    lineWidth: 1.5,
                    dashPattern: const [6, 3],
                  ),
                ],
                theme: isDark ? ChartTheme.dark : ChartTheme.light,
                showLegend: false,
                xAxis: const AxisConfig(label: 'Time (s)', showGrid: true),
                yAxis: const AxisConfig(label: 'Load %', showGrid: false),
                interactionConfig: const InteractionConfig(
                  crosshair: CrosshairConfig(
                    enabled: true,
                    mode: CrosshairMode.vertical,
                    snapToDataPoint: true,
                    displayMode: CrosshairDisplayMode.tracking,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Rainbow gradient segments across the line
  Widget _buildGradientSegmentsChart(bool isDark) {
    // Generate smooth wave data
    final points = List.generate(
      20,
      (i) => ChartDataPoint(
        x: i.toDouble(),
        y: 50 + 30 * sin(i * 0.5),
      ),
    );

    // Rainbow colors for each segment
    final rainbowColors = [
      const Color(0xFFFF0000), // Red
      const Color(0xFFFF7F00), // Orange
      const Color(0xFFFFFF00), // Yellow
      const Color(0xFF00FF00), // Green
      const Color(0xFF0000FF), // Blue
      const Color(0xFF4B0082), // Indigo
      const Color(0xFF9400D3), // Violet
    ];

    // Create color map for segments
    final colorMap = <int, Color>{};
    for (int i = 0; i < points.length - 1; i++) {
      colorMap[i] = rainbowColors[i % rainbowColors.length];
    }

    var series = LineChartSeries(
      id: 'rainbow',
      name: 'Rainbow Wave',
      points: points,
      color: Colors.grey, // Base color (overridden)
      interpolation: LineInterpolation.bezier,
      tension: 0.3,
      strokeWidth: 5.0,
    );

    series = series.withSegmentColors(colorMap);

    return Card(
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.gradient, color: Color(0xFF9400D3), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Rainbow Segments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            Text(
              'Per-segment color override',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: [series],
                theme: isDark ? ChartTheme.dark : ChartTheme.light,
                showLegend: false,
                xAxis: const AxisConfig(showGrid: true, showAxis: false),
                yAxis: const AxisConfig(showGrid: false, showAxis: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Stock chart with green/red for gain/loss segments
  Widget _buildStockGainLossChart(bool isDark) {
    // Stock price data with ups and downs
    final points = <ChartDataPoint>[
      const ChartDataPoint(x: 0, y: 150.0),
      const ChartDataPoint(x: 1, y: 155.5),
      const ChartDataPoint(x: 2, y: 152.3),
      const ChartDataPoint(x: 3, y: 158.7),
      const ChartDataPoint(x: 4, y: 161.2),
      const ChartDataPoint(x: 5, y: 157.8),
      const ChartDataPoint(x: 6, y: 163.4),
      const ChartDataPoint(x: 7, y: 168.9),
      const ChartDataPoint(x: 8, y: 165.2),
      const ChartDataPoint(x: 9, y: 171.5),
      const ChartDataPoint(x: 10, y: 169.8),
      const ChartDataPoint(x: 11, y: 175.3),
    ];

    // Determine gain/loss color for each segment
    final colorMap = <int, Color>{};
    for (int i = 0; i < points.length - 1; i++) {
      final isGain = points[i + 1].y > points[i].y;
      colorMap[i] = isGain ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    }

    var series = LineChartSeries(
      id: 'stock',
      name: 'TECH',
      points: points,
      color: Colors.grey,
      interpolation: LineInterpolation.linear,
      strokeWidth: 3.0,
      showDataPointMarkers: true,
      dataPointMarkerRadius: 4.5,
    );

    series = series.withSegmentColors(colorMap);

    // Calculate overall change
    final startPrice = points.first.y;
    final endPrice = points.last.y;
    final change = endPrice - startPrice;
    final changePercent = (change / startPrice * 100);
    final isPositive = change >= 0;

    return Card(
      color: const Color(0xFF0F172A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'TECH Stock',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Text(
              'Gain/Loss segment coloring',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: [series],
                theme: ChartTheme.dark,
                showLegend: false,
                xAxis: const AxisConfig(label: 'Day', showGrid: false, showAxis: false),
                yAxis: const AxisConfig(label: 'Price (\$)', showGrid: true),
                interactionConfig: const InteractionConfig(
                  crosshair: CrosshairConfig(
                    enabled: true,
                    mode: CrosshairMode.both,
                    snapToDataPoint: true,
                    showCoordinateLabels: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // Area Segment Colors Showcases
  // ==========================================================================

  /// Temperature zones with hot/cold colored segments
  Widget _buildTemperatureZonesAreaChart(bool isDark) {
    // Temperature data over 24 hours
    final points = <ChartDataPoint>[
      const ChartDataPoint(x: 0, y: 12),
      const ChartDataPoint(x: 2, y: 10),
      const ChartDataPoint(x: 4, y: 8),
      const ChartDataPoint(x: 6, y: 11),
      const ChartDataPoint(x: 8, y: 18),
      const ChartDataPoint(x: 10, y: 24),
      const ChartDataPoint(x: 12, y: 28),
      const ChartDataPoint(x: 14, y: 31),
      const ChartDataPoint(x: 16, y: 29),
      const ChartDataPoint(x: 18, y: 25),
      const ChartDataPoint(x: 20, y: 20),
      const ChartDataPoint(x: 22, y: 15),
      const ChartDataPoint(x: 24, y: 13),
    ];

    // Color based on temperature: cold (<15), mild (15-25), hot (>25)
    var series = AreaChartSeries(
      id: 'temp-zones',
      name: 'Temperature',
      points: points,
      color: const Color(0xFF3B82F6), // Base blue
      interpolation: LineInterpolation.bezier,
      tension: 0.3,
      strokeWidth: 2.5,
      fillOpacity: 0.6,
    );

    // Apply zone coloring
    series = series
        .withColorWhere(
          (point) => point.y >= 25,
          const Color(0xFFEF4444), // Hot = red
        )
        .withColorWhere(
          (point) => point.y >= 15 && point.y < 25,
          const Color(0xFFF59E0B), // Mild = amber
        );

    return Card(
      color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F9FF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.thermostat,
                  color: isDark ? Colors.white70 : Colors.black87,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '24-Hour Temperature',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Area with zone coloring',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey),
                ),
                const Spacer(),
                _buildLegendChip('Cold', const Color(0xFF3B82F6)),
                _buildLegendChip('Mild', const Color(0xFFF59E0B)),
                _buildLegendChip('Hot', const Color(0xFFEF4444)),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: [series],
                annotations: [
                  ThresholdAnnotation(
                    id: 'cold-mild',
                    axis: AnnotationAxis.y,
                    value: 15,
                    lineColor: const Color(0xFF3B82F6),
                    lineWidth: 1.0,
                    dashPattern: const [4, 2],
                  ),
                  ThresholdAnnotation(
                    id: 'mild-hot',
                    axis: AnnotationAxis.y,
                    value: 25,
                    lineColor: const Color(0xFFEF4444),
                    lineWidth: 1.0,
                    dashPattern: const [4, 2],
                  ),
                ],
                theme: isDark ? ChartTheme.dark : ChartTheme.light,
                showLegend: false,
                xAxis: const AxisConfig(label: 'Hour', showGrid: true),
                yAxis: const AxisConfig(label: '°C', showGrid: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// Profit/Loss area chart with green/red segments
  Widget _buildProfitLossAreaChart(bool isDark) {
    // Monthly profit/loss data
    final points = <ChartDataPoint>[
      const ChartDataPoint(x: 1, y: 5200),
      const ChartDataPoint(x: 2, y: 8100),
      const ChartDataPoint(x: 3, y: -2300),
      const ChartDataPoint(x: 4, y: -4500),
      const ChartDataPoint(x: 5, y: 1200),
      const ChartDataPoint(x: 6, y: 6800),
      const ChartDataPoint(x: 7, y: 9500),
      const ChartDataPoint(x: 8, y: 7200),
      const ChartDataPoint(x: 9, y: -1800),
      const ChartDataPoint(x: 10, y: 4300),
      const ChartDataPoint(x: 11, y: 11200),
      const ChartDataPoint(x: 12, y: 8900),
    ];

    var series = AreaChartSeries(
      id: 'profit-loss',
      name: 'P&L',
      points: points,
      color: const Color(0xFF10B981), // Default green
      interpolation: LineInterpolation.monotone,
      strokeWidth: 2.0,
      fillOpacity: 0.5,
    );

    // Red for loss periods
    series = series.withColorWhere(
      (point) => point.y < 0,
      const Color(0xFFEF4444),
    );

    return Card(
      color: const Color(0xFF0C1222),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, color: Color(0xFF10B981), size: 20),
                SizedBox(width: 8),
                Text(
                  'Monthly P&L',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                Text(
                  'YTD: +\$54,800',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const Text(
              'Profit (green) / Loss (red) area segments',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: [series],
                annotations: [
                  ThresholdAnnotation(
                    id: 'zero-line',
                    axis: AnnotationAxis.y,
                    value: 0,
                    label: 'Break-even',
                    lineColor: const Color(0xFF64748B),
                    lineWidth: 1.5,
                    dashPattern: const [5, 3],
                  ),
                ],
                theme: ChartTheme.dark,
                showLegend: false,
                xAxis: const AxisConfig(label: 'Month', showGrid: false, showAxis: false),
                yAxis: const AxisConfig(label: 'USD', showGrid: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // Multi-Series Mixed Charts
  // ==========================================================================

  /// Multi-layer analytics: 3 stacked areas + 2 trend lines
  Widget _buildMultiLayerAnalyticsChart(bool isDark) {
    // Generate data for multiple series
    final baseData = List.generate(
      12,
      (i) => 50.0 + 20 * sin(i * 0.5) + i * 2,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Analytics Dashboard',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text(
              '3 Areas + 2 Lines',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: [
                  // Background areas (stacked effect via different base values)
                  AreaChartSeries(
                    id: 'sessions',
                    name: 'Sessions',
                    points: List.generate(
                      12,
                      (i) => ChartDataPoint(
                        x: i.toDouble(),
                        y: baseData[i] * 1.5 + 30,
                      ),
                    ),
                    color: const Color(0xFF6366F1),
                    interpolation: LineInterpolation.bezier,
                    tension: 0.3,
                    strokeWidth: 0,
                    fillOpacity: 0.3,
                  ),
                  AreaChartSeries(
                    id: 'pageviews',
                    name: 'Page Views',
                    points: List.generate(
                      12,
                      (i) => ChartDataPoint(
                        x: i.toDouble(),
                        y: baseData[i] * 1.2,
                      ),
                    ),
                    color: const Color(0xFF8B5CF6),
                    interpolation: LineInterpolation.bezier,
                    tension: 0.3,
                    strokeWidth: 0,
                    fillOpacity: 0.4,
                  ),
                  AreaChartSeries(
                    id: 'users',
                    name: 'Active Users',
                    points: List.generate(
                      12,
                      (i) => ChartDataPoint(
                        x: i.toDouble(),
                        y: baseData[i] * 0.8,
                      ),
                    ),
                    color: const Color(0xFFA855F7),
                    interpolation: LineInterpolation.bezier,
                    tension: 0.3,
                    strokeWidth: 0,
                    fillOpacity: 0.5,
                  ),
                  // Trend lines on top
                  LineChartSeries(
                    id: 'bounce-rate',
                    name: 'Bounce Rate',
                    points: List.generate(
                      12,
                      (i) => ChartDataPoint(
                        x: i.toDouble(),
                        y: 45 - i * 1.5 + 10 * sin(i * 0.8),
                      ),
                    ),
                    color: const Color(0xFFF97316),
                    interpolation: LineInterpolation.bezier,
                    strokeWidth: 2.5,
                    showDataPointMarkers: true,
                    dataPointMarkerRadius: 3.0,
                  ),
                  LineChartSeries(
                    id: 'conversion',
                    name: 'Conversion %',
                    points: List.generate(
                      12,
                      (i) => ChartDataPoint(
                        x: i.toDouble(),
                        y: 15 + i * 2 + 5 * cos(i * 0.6),
                      ),
                    ),
                    color: const Color(0xFF10B981),
                    interpolation: LineInterpolation.bezier,
                    strokeWidth: 2.5,
                    showDataPointMarkers: true,
                    dataPointMarkerRadius: 3.0,
                  ),
                ],
                theme: isDark ? ChartTheme.dark : ChartTheme.light,
                showLegend: true,
                legendStyle: const LegendStyle(orientation: LegendOrientation.vertical),
                normalizationMode: NormalizationMode.perSeries,
                xAxis: const AxisConfig(label: 'Month', showGrid: false, showAxis: false),
                yAxis: const AxisConfig(label: 'Value', showGrid: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Network traffic: Upload/Download areas + Latency line with segment colors
  Widget _buildNetworkTrafficChart(bool isDark) {
    final hours = 24;
    final downloadData = List.generate(
      hours,
      (i) => ChartDataPoint(
        x: i.toDouble(),
        y: 50 + 40 * sin(i * 0.3) + (i > 8 && i < 20 ? 30 : 0),
      ),
    );
    final uploadData = List.generate(
      hours,
      (i) => ChartDataPoint(
        x: i.toDouble(),
        y: 20 + 15 * cos(i * 0.4) + (i > 10 && i < 18 ? 20 : 0),
      ),
    );

    // Latency line with segment coloring (red when high)
    var latencySeries = LineChartSeries(
      id: 'latency',
      name: 'Latency (ms)',
      points: List.generate(
        hours,
        (i) => ChartDataPoint(
          x: i.toDouble(),
          y: 20 + 15 * sin(i * 0.5) + (i > 12 && i < 16 ? 40 : 0),
        ),
      ),
      color: const Color(0xFF10B981), // Green = good
      interpolation: LineInterpolation.monotone,
      strokeWidth: 2.5,
      showDataPointMarkers: false,
    );

    // High latency segments in red
    latencySeries = latencySeries.withColorWhere(
      (point) => point.y > 50,
      const Color(0xFFEF4444), // Red = high latency
    );

    return Card(
      color: const Color(0xFF0F172A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.router, color: Color(0xFF3B82F6), size: 20),
                SizedBox(width: 8),
                Text(
                  'Network Monitor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Text(
              'Download/Upload areas + Latency line (red when >50ms)',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: [
                  AreaChartSeries(
                    id: 'download',
                    name: 'Download',
                    points: downloadData,
                    color: const Color(0xFF3B82F6),
                    interpolation: LineInterpolation.bezier,
                    tension: 0.2,
                    strokeWidth: 1.5,
                    fillOpacity: 0.4,
                  ),
                  AreaChartSeries(
                    id: 'upload',
                    name: 'Upload',
                    points: uploadData,
                    color: const Color(0xFF22D3EE),
                    interpolation: LineInterpolation.bezier,
                    tension: 0.2,
                    strokeWidth: 1.5,
                    fillOpacity: 0.4,
                  ),
                  latencySeries,
                ],
                annotations: [
                  ThresholdAnnotation(
                    id: 'latency-warn',
                    axis: AnnotationAxis.y,
                    value: 50,
                    label: '50ms',
                    lineColor: const Color(0xFFFBBF24),
                    lineWidth: 1.5,
                    dashPattern: const [4, 2],
                  ),
                ],
                theme: ChartTheme.dark,
                showLegend: true,
                legendStyle: const LegendStyle(
                  orientation: LegendOrientation.vertical,
                  backgroundColor: Colors.black12,
                  textStyle: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
                xAxis: const AxisConfig(label: 'Hour', showGrid: true),
                yAxis: const AxisConfig(label: 'Mbps / ms', showGrid: false),
                interactionConfig: const InteractionConfig(
                  crosshair: CrosshairConfig(
                    enabled: true,
                    mode: CrosshairMode.vertical,
                    snapToDataPoint: true,
                    displayMode: CrosshairDisplayMode.tracking,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Financial dashboard: Multiple indicators with segment colors
  Widget _buildFinancialDashboardChart(bool isDark) {
    // Generate financial data
    final months = 12;
    final revenueData = <ChartDataPoint>[
      const ChartDataPoint(x: 1, y: 85),
      const ChartDataPoint(x: 2, y: 92),
      const ChartDataPoint(x: 3, y: 78),
      const ChartDataPoint(x: 4, y: 105),
      const ChartDataPoint(x: 5, y: 115),
      const ChartDataPoint(x: 6, y: 98),
      const ChartDataPoint(x: 7, y: 125),
      const ChartDataPoint(x: 8, y: 132),
      const ChartDataPoint(x: 9, y: 118),
      const ChartDataPoint(x: 10, y: 145),
      const ChartDataPoint(x: 11, y: 158),
      const ChartDataPoint(x: 12, y: 172),
    ];

    // Revenue line with growth/decline coloring
    var revenueSeries = LineChartSeries(
      id: 'revenue',
      name: 'Revenue',
      points: revenueData,
      color: const Color(0xFF10B981),
      interpolation: LineInterpolation.bezier,
      tension: 0.2,
      strokeWidth: 2.0,
      showDataPointMarkers: true,
      dataPointMarkerRadius: 3.0,
    );

    // Segment coloring for growth vs decline
    final colorMap = <int, Color>{};
    for (int i = 0; i < revenueData.length - 1; i++) {
      colorMap[i] = revenueData[i + 1].y > revenueData[i].y
          ? const Color(0xFF10B981) // Growth
          : const Color(0xFFEF4444); // Decline
    }
    revenueSeries = revenueSeries.withSegmentColors(colorMap);

    // Expense area with gradient segments
    var expenseSeries = AreaChartSeries(
      id: 'expenses',
      name: 'Expenses',
      points: List.generate(
        months,
        (i) => ChartDataPoint(
          x: (i + 1).toDouble(),
          y: 40 + 15 * sin(i * 0.5) + i * 3,
        ),
      ),
      color: const Color(0xFFF59E0B),
      interpolation: LineInterpolation.bezier,
      tension: 0.3,
      strokeWidth: 2.0,
      fillOpacity: 0.3,
    );

    // Color high expense periods
    expenseSeries = expenseSeries.withColorWhere(
      (point) => point.y > 70,
      const Color(0xFFEF4444),
    );

    return Card(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: isDark ? Colors.white70 : Colors.black87,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Financial Overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            Text(
              'Revenue line (growth/decline) + Expense area (alert when high)',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: [
                  expenseSeries,
                  revenueSeries,
                  // Add a target line
                  const LineChartSeries(
                    id: 'target',
                    name: 'Target',
                    points: [
                      ChartDataPoint(x: 1, y: 100),
                      ChartDataPoint(x: 12, y: 150),
                    ],
                    color: Color(0xFF6366F1),
                    interpolation: LineInterpolation.linear,
                    strokeWidth: 1.5,
                  ),
                ],
                annotations: [
                  RangeAnnotation(
                    id: 'target_zone',
                    startX: 1,
                    endX: 12,
                    startY: 100,
                    endY: 160,
                    label: 'Target Zone',
                    fillColor: const Color(0x156366F1),
                    borderColor: const Color(0xFF6366F1),
                  ),
                ],
                theme: isDark ? ChartTheme.dark : ChartTheme.light,
                showLegend: true,
                xAxis: const AxisConfig(label: 'Month', showGrid: true, showAxis: false),
                yAxis: const AxisConfig(label: 'K USD', showGrid: false),
                interactionConfig: const InteractionConfig(
                  crosshair: CrosshairConfig(
                    enabled: true,
                    mode: CrosshairMode.both,
                    snapToDataPoint: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
