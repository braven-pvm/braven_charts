// Copyright 2025 Braven Charts - Multi-Axis Normalization Showcase
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/src_plus/axis/axis_config.dart';
import 'package:braven_charts/src_plus/axis/y_axis_config.dart';
import 'package:braven_charts/src_plus/models/chart_data_point.dart';
import 'package:braven_charts/src_plus/models/chart_series.dart';
import 'package:braven_charts/src_plus/models/chart_type.dart';
import 'package:braven_charts/src_plus/models/enums.dart';
import 'package:braven_charts/src_plus/models/interaction_config.dart';
import 'package:braven_charts/src_plus/models/normalization_mode.dart';
import 'package:braven_charts/src_plus/models/y_axis_position.dart';
import 'package:braven_charts/src_plus/widgets/braven_chart_plus.dart';
import 'package:flutter/material.dart';

/// Dedicated showcase page for Multi-Axis Normalization feature (011).
///
/// Demonstrates:
/// - 2-axis, 3-axis, and 4-axis configurations
/// - Auto-detection mode
/// - Color-coded axes matching series
/// - Original values in crosshair/tooltips
/// - Different axis positions (leftOuter, left, right, rightOuter)
class MultiAxisPage extends StatefulWidget {
  const MultiAxisPage({super.key});

  @override
  State<MultiAxisPage> createState() => _MultiAxisPageState();
}

class _MultiAxisPageState extends State<MultiAxisPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showComparison = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Axis Normalization'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.looks_two), text: '2 Axes'),
            Tab(icon: Icon(Icons.looks_3), text: '3 Axes'),
            Tab(icon: Icon(Icons.looks_4), text: '4 Axes'),
            Tab(icon: Icon(Icons.auto_fix_high), text: 'Auto-Detect'),
          ],
        ),
        actions: [
          // Toggle comparison view
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text(
                  'Show Before/After',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _showComparison,
                  onChanged: (v) => setState(() => _showComparison = v),
                ),
              ],
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TwoAxisDemo(showComparison: _showComparison),
          _ThreeAxisDemo(showComparison: _showComparison),
          _FourAxisDemo(showComparison: _showComparison),
          _AutoDetectDemo(showComparison: _showComparison),
        ],
      ),
    );
  }
}

/// Demonstrates 2-axis configuration: Power (W) vs Heart Rate (bpm)
class _TwoAxisDemo extends StatelessWidget {
  final bool showComparison;

  const _TwoAxisDemo({required this.showComparison});

  @override
  Widget build(BuildContext context) {
    final random = math.Random(42);

    // Power: 100-300W range
    final powerData = List.generate(
      200,
      (i) => ChartDataPoint(
        x: i.toDouble(),
        y: 150 + 80 * math.sin(i * 0.05) + random.nextDouble() * 30,
      ),
    );

    // Heart Rate: 60-180 bpm range
    final hrData = List.generate(
      200,
      (i) => ChartDataPoint(
        x: i.toDouble(),
        y: 120 + 40 * math.sin(i * 0.05 + 0.5) + random.nextDouble() * 15,
      ),
    );

    return _ComparisonLayout(
      showComparison: showComparison,
      title: '2-Axis: Power vs Heart Rate',
      description:
          'Power (100-300W) and Heart Rate (60-180 bpm) have different scales. '
          'Without normalization, one series dominates. With multi-axis, both use full height.',
      beforeChart: _buildWithoutMultiAxis(powerData, hrData),
      afterChart: _buildWithMultiAxis(powerData, hrData),
      legendItems: [
        _LegendItem('Power', Colors.blue[600]!, '100-300 W'),
        _LegendItem('Heart Rate', Colors.red[600]!, '60-180 bpm'),
      ],
    );
  }

  Widget _buildWithoutMultiAxis(
    List<ChartDataPoint> power,
    List<ChartDataPoint> hr,
  ) {
    return BravenChartPlus(
      chartType: ChartType.line,
      series: [
        LineChartSeries(
          id: 'power',
          name: 'Power',
          points: power,
          color: Colors.blue[600]!,
          strokeWidth: 2.0,
        ),
        LineChartSeries(
          id: 'hr',
          name: 'Heart Rate',
          points: hr,
          color: Colors.red[600]!,
          strokeWidth: 2.0,
        ),
      ],
      normalizationMode: NormalizationMode.none,
      xAxis: const AxisConfig(
        orientation: AxisOrientation.horizontal,
        position: AxisPosition.bottom,
        label: 'Time',
      ),
      yAxis: const AxisConfig(
        orientation: AxisOrientation.vertical,
        position: AxisPosition.left,
        label: 'Combined Scale',
      ),
    );
  }

  Widget _buildWithMultiAxis(
    List<ChartDataPoint> power,
    List<ChartDataPoint> hr,
  ) {
    return BravenChartPlus(
      chartType: ChartType.line,
      series: [
        LineChartSeries(
          id: 'power',
          name: 'Power',
          points: power,
          color: Colors.blue[600]!,
          strokeWidth: 2.0,
          yAxisId: 'power',
          unit: 'W',
        ),
        LineChartSeries(
          id: 'hr',
          name: 'Heart Rate',
          points: hr,
          color: Colors.red[600]!,
          strokeWidth: 2.0,
          yAxisId: 'hr',
          unit: 'bpm',
        ),
      ],
      yAxes: [
        YAxisConfig(
          id: 'power',
          position: YAxisPosition.left,
          label: 'Power (W)',
          color: Colors.blue[600]!,
        ),
        YAxisConfig(
          id: 'hr',
          position: YAxisPosition.right,
          label: 'Heart Rate (bpm)',
          color: Colors.red[600]!,
        ),
      ],
      normalizationMode: NormalizationMode.perSeries,
      xAxis: const AxisConfig(
        orientation: AxisOrientation.horizontal,
        position: AxisPosition.bottom,
        label: 'Time',
      ),
      yAxis: const AxisConfig(
        orientation: AxisOrientation.vertical,
        position: AxisPosition.left,
      ),
      interactionConfig: const InteractionConfig(
        crosshair: CrosshairConfig(
          showCoordinateLabels: true,
          mode: CrosshairMode.vertical,
          interpolateValues: true,
          showTrackingTooltip: true,
          showIntersectionMarkers: true,
        ),
      ),
    );
  }
}

/// Demonstrates 3-axis configuration: Power, HR, and Cadence
class _ThreeAxisDemo extends StatelessWidget {
  final bool showComparison;

  const _ThreeAxisDemo({required this.showComparison});

  @override
  Widget build(BuildContext context) {
    final random = math.Random(43);

    // Power: 100-350W
    final powerData = List.generate(
      200,
      (i) => ChartDataPoint(
        x: i.toDouble(),
        y: 200 + 100 * math.sin(i * 0.04) + random.nextDouble() * 40,
      ),
    );

    // Heart Rate: 60-185 bpm
    final hrData = List.generate(
      200,
      (i) => ChartDataPoint(
        x: i.toDouble(),
        y: 130 + 40 * math.sin(i * 0.04 + 0.3) + random.nextDouble() * 12,
      ),
    );

    // Cadence: 60-110 rpm
    final cadenceData = List.generate(
      200,
      (i) => ChartDataPoint(
        x: i.toDouble(),
        y: 85 + 20 * math.sin(i * 0.06) + random.nextDouble() * 8,
      ),
    );

    return _ComparisonLayout(
      showComparison: showComparison,
      title: '3-Axis: Power, Heart Rate & Cadence',
      description:
          'Three metrics from cycling: Power (W), Heart Rate (bpm), and Cadence (rpm). '
          'Each axis is color-coded to match its series for instant recognition.',
      beforeChart: _buildWithoutMultiAxis(powerData, hrData, cadenceData),
      afterChart: _buildWithMultiAxis(powerData, hrData, cadenceData),
      legendItems: [
        _LegendItem('Power', Colors.blue[600]!, '100-350 W'),
        _LegendItem('Heart Rate', Colors.red[600]!, '60-185 bpm'),
        _LegendItem('Cadence', Colors.green[600]!, '60-110 rpm'),
      ],
    );
  }

  Widget _buildWithoutMultiAxis(
    List<ChartDataPoint> power,
    List<ChartDataPoint> hr,
    List<ChartDataPoint> cadence,
  ) {
    return BravenChartPlus(
      chartType: ChartType.line,
      series: [
        LineChartSeries(
          id: 'power',
          name: 'Power',
          points: power,
          color: Colors.blue[600]!,
          strokeWidth: 2.0,
        ),
        LineChartSeries(
          id: 'hr',
          name: 'Heart Rate',
          points: hr,
          color: Colors.red[600]!,
          strokeWidth: 2.0,
        ),
        LineChartSeries(
          id: 'cadence',
          name: 'Cadence',
          points: cadence,
          color: Colors.green[600]!,
          strokeWidth: 2.0,
        ),
      ],
      normalizationMode: NormalizationMode.none,
      xAxis: const AxisConfig(
        orientation: AxisOrientation.horizontal,
        position: AxisPosition.bottom,
        label: 'Time',
      ),
      yAxis: const AxisConfig(
        orientation: AxisOrientation.vertical,
        position: AxisPosition.left,
        label: 'Combined Scale',
      ),
    );
  }

  Widget _buildWithMultiAxis(
    List<ChartDataPoint> power,
    List<ChartDataPoint> hr,
    List<ChartDataPoint> cadence,
  ) {
    return BravenChartPlus(
      chartType: ChartType.line,
      series: [
        LineChartSeries(
          id: 'power',
          name: 'Power',
          points: power,
          color: Colors.blue[600]!,
          strokeWidth: 2.0,
          yAxisId: 'power',
          unit: 'W',
        ),
        LineChartSeries(
          id: 'hr',
          name: 'Heart Rate',
          points: hr,
          color: Colors.red[600]!,
          strokeWidth: 2.0,
          yAxisId: 'hr',
          unit: 'bpm',
        ),
        LineChartSeries(
          id: 'cadence',
          name: 'Cadence',
          points: cadence,
          color: Colors.green[600]!,
          strokeWidth: 2.0,
          yAxisId: 'cadence',
          unit: 'rpm',
        ),
      ],
      yAxes: [
        YAxisConfig(
          id: 'power',
          position: YAxisPosition.left,
          label: 'Power (W)',
          color: Colors.blue[600]!,
        ),
        YAxisConfig(
          id: 'hr',
          position: YAxisPosition.right,
          label: 'Heart Rate (bpm)',
          color: Colors.red[600]!,
        ),
        YAxisConfig(
          id: 'cadence',
          position: YAxisPosition.leftOuter,
          label: 'Cadence (rpm)',
          color: Colors.green[600]!,
        ),
      ],
      normalizationMode: NormalizationMode.perSeries,
      xAxis: const AxisConfig(
        orientation: AxisOrientation.horizontal,
        position: AxisPosition.bottom,
        label: 'Time',
      ),
      yAxis: const AxisConfig(
        orientation: AxisOrientation.vertical,
        position: AxisPosition.left,
      ),
      interactionConfig: const InteractionConfig(
        crosshair: CrosshairConfig(
          showCoordinateLabels: true,
          mode: CrosshairMode.vertical,
          interpolateValues: true,
          showTrackingTooltip: true,
          showIntersectionMarkers: true,
        ),
      ),
    );
  }
}

/// Demonstrates 4-axis configuration: All positions used
class _FourAxisDemo extends StatelessWidget {
  final bool showComparison;

  const _FourAxisDemo({required this.showComparison});

  @override
  Widget build(BuildContext context) {
    final random = math.Random(44);

    // Ventilation: 20-150 L/min
    final veData = List.generate(
      200,
      (i) => ChartDataPoint(
        x: i.toDouble(),
        y: 60 + 50 * math.sin(i * 0.03) + random.nextDouble() * 20,
      ),
    );

    // Tidal Volume: 0.5-3.5 L
    final tvData = List.generate(
      200,
      (i) => ChartDataPoint(
        x: i.toDouble(),
        y: 1.5 + 1.0 * math.sin(i * 0.04 + 0.2) + random.nextDouble() * 0.4,
      ),
    );

    // Power: 50-400 W
    final powerData = List.generate(
      200,
      (i) => ChartDataPoint(
        x: i.toDouble(),
        y: 180 + 120 * math.sin(i * 0.035) + random.nextDouble() * 40,
      ),
    );

    // Respiratory Rate: 10-50 breaths/min
    final rrData = List.generate(
      200,
      (i) => ChartDataPoint(
        x: i.toDouble(),
        y: 25 + 15 * math.sin(i * 0.025 + 0.5) + random.nextDouble() * 6,
      ),
    );

    return _ComparisonLayout(
      showComparison: showComparison,
      title: '4-Axis: Full Cardiopulmonary Exercise Test',
      description:
          'Maximum configuration with all 4 axis positions: leftOuter (VE), left (TV), '
          'right (Power), rightOuter (RR). Scientific/medical data visualization.',
      beforeChart: _buildWithoutMultiAxis(veData, tvData, powerData, rrData),
      afterChart: _buildWithMultiAxis(veData, tvData, powerData, rrData),
      legendItems: [
        _LegendItem('Ventilation', Colors.purple[600]!, '20-150 L/min'),
        _LegendItem('Tidal Volume', Colors.teal[600]!, '0.5-3.5 L'),
        _LegendItem('Power', Colors.blue[600]!, '50-400 W'),
        _LegendItem('Resp Rate', Colors.orange[600]!, '10-50 bpm'),
      ],
    );
  }

  Widget _buildWithoutMultiAxis(
    List<ChartDataPoint> ve,
    List<ChartDataPoint> tv,
    List<ChartDataPoint> power,
    List<ChartDataPoint> rr,
  ) {
    return BravenChartPlus(
      chartType: ChartType.line,
      series: [
        LineChartSeries(
            id: 've', name: 'VE', points: ve, color: Colors.purple[600]!),
        LineChartSeries(
            id: 'tv', name: 'TV', points: tv, color: Colors.teal[600]!),
        LineChartSeries(
            id: 'power', name: 'Power', points: power, color: Colors.blue[600]!),
        LineChartSeries(
            id: 'rr', name: 'RR', points: rr, color: Colors.orange[600]!),
      ],
      normalizationMode: NormalizationMode.none,
      xAxis: const AxisConfig(
        orientation: AxisOrientation.horizontal,
        position: AxisPosition.bottom,
        label: 'Time',
      ),
      yAxis: const AxisConfig(
        orientation: AxisOrientation.vertical,
        position: AxisPosition.left,
        label: 'Combined (unusable)',
      ),
    );
  }

  Widget _buildWithMultiAxis(
    List<ChartDataPoint> ve,
    List<ChartDataPoint> tv,
    List<ChartDataPoint> power,
    List<ChartDataPoint> rr,
  ) {
    return BravenChartPlus(
      chartType: ChartType.line,
      series: [
        LineChartSeries(
          id: 've',
          name: 'VE',
          points: ve,
          color: Colors.purple[600]!,
          strokeWidth: 2.0,
          yAxisId: 've',
          unit: 'L/min',
        ),
        LineChartSeries(
          id: 'tv',
          name: 'TV',
          points: tv,
          color: Colors.teal[600]!,
          strokeWidth: 2.0,
          yAxisId: 'tv',
          unit: 'L',
        ),
        LineChartSeries(
          id: 'power',
          name: 'Power',
          points: power,
          color: Colors.blue[600]!,
          strokeWidth: 2.0,
          yAxisId: 'power',
          unit: 'W',
        ),
        LineChartSeries(
          id: 'rr',
          name: 'RR',
          points: rr,
          color: Colors.orange[600]!,
          strokeWidth: 2.0,
          yAxisId: 'rr',
          unit: 'bpm',
        ),
      ],
      yAxes: [
        YAxisConfig(
          id: 've',
          position: YAxisPosition.leftOuter,
          label: 'VE (L/min)',
          color: Colors.purple[600]!,
        ),
        YAxisConfig(
          id: 'tv',
          position: YAxisPosition.left,
          label: 'TV (L)',
          color: Colors.teal[600]!,
        ),
        YAxisConfig(
          id: 'power',
          position: YAxisPosition.right,
          label: 'Power (W)',
          color: Colors.blue[600]!,
        ),
        YAxisConfig(
          id: 'rr',
          position: YAxisPosition.rightOuter,
          label: 'RR (bpm)',
          color: Colors.orange[600]!,
        ),
      ],
      normalizationMode: NormalizationMode.perSeries,
      xAxis: const AxisConfig(
        orientation: AxisOrientation.horizontal,
        position: AxisPosition.bottom,
        label: 'Time (seconds)',
      ),
      yAxis: const AxisConfig(
        orientation: AxisOrientation.vertical,
        position: AxisPosition.left,
      ),
      interactionConfig: const InteractionConfig(
        crosshair: CrosshairConfig(
          showCoordinateLabels: true,
          mode: CrosshairMode.vertical,
          interpolateValues: true,
          showTrackingTooltip: true,
          showIntersectionMarkers: true,
        ),
      ),
    );
  }
}

/// Demonstrates Auto-Detection mode
class _AutoDetectDemo extends StatelessWidget {
  final bool showComparison;

  const _AutoDetectDemo({required this.showComparison});

  @override
  Widget build(BuildContext context) {
    final random = math.Random(45);

    // Stock Price: $50-$200 range
    final stockData = List.generate(
      200,
      (i) => ChartDataPoint(
        x: i.toDouble(),
        y: 120 + 50 * math.sin(i * 0.02) + random.nextDouble() * 20,
      ),
    );

    // Trading Volume: 100,000 - 10,000,000 (vastly different scale!)
    final volumeData = List.generate(
      200,
      (i) => ChartDataPoint(
        x: i.toDouble(),
        y: 2000000 +
            3000000 * math.sin(i * 0.04).abs() +
            random.nextDouble() * 500000,
      ),
    );

    return _ComparisonLayout(
      showComparison: showComparison,
      title: 'Auto-Detection: Stock Price vs Volume',
      description:
          'When ranges differ by >10x, auto-detection kicks in. '
          'Stock price (~\$50-200) vs Volume (~1M-5M) = ~25,000x ratio. '
          'No explicit yAxes needed - the system detects and normalizes automatically!',
      beforeChart: _buildWithoutMultiAxis(stockData, volumeData),
      afterChart: _buildWithAutoDetect(stockData, volumeData),
      legendItems: [
        _LegendItem('Stock Price', Colors.green[600]!, '\$50-200'),
        _LegendItem('Volume', Colors.blue[600]!, '1M-5M'),
      ],
      afterLabel: 'Auto-Detected',
    );
  }

  Widget _buildWithoutMultiAxis(
    List<ChartDataPoint> stock,
    List<ChartDataPoint> volume,
  ) {
    return BravenChartPlus(
      chartType: ChartType.line,
      series: [
        LineChartSeries(
          id: 'stock',
          name: 'Stock',
          points: stock,
          color: Colors.green[600]!,
          strokeWidth: 2.0,
        ),
        LineChartSeries(
          id: 'volume',
          name: 'Volume',
          points: volume,
          color: Colors.blue[600]!,
          strokeWidth: 2.0,
        ),
      ],
      normalizationMode: NormalizationMode.none,
      xAxis: const AxisConfig(
        orientation: AxisOrientation.horizontal,
        position: AxisPosition.bottom,
        label: 'Time',
      ),
      yAxis: const AxisConfig(
        orientation: AxisOrientation.vertical,
        position: AxisPosition.left,
        label: 'Combined (stock invisible!)',
      ),
    );
  }

  Widget _buildWithAutoDetect(
    List<ChartDataPoint> stock,
    List<ChartDataPoint> volume,
  ) {
    return BravenChartPlus(
      chartType: ChartType.line,
      series: [
        LineChartSeries(
          id: 'stock',
          name: 'Stock',
          points: stock,
          color: Colors.green[600]!,
          strokeWidth: 2.0,
          unit: '\$',
        ),
        LineChartSeries(
          id: 'volume',
          name: 'Volume',
          points: volume,
          color: Colors.blue[600]!,
          strokeWidth: 2.0,
          unit: 'shares',
        ),
      ],
      // KEY: NormalizationMode.auto - no yAxes needed!
      normalizationMode: NormalizationMode.auto,
      xAxis: const AxisConfig(
        orientation: AxisOrientation.horizontal,
        position: AxisPosition.bottom,
        label: 'Time',
      ),
      yAxis: const AxisConfig(
        orientation: AxisOrientation.vertical,
        position: AxisPosition.left,
        label: 'Auto',
      ),
      interactionConfig: const InteractionConfig(
        crosshair: CrosshairConfig(
          showCoordinateLabels: true,
          mode: CrosshairMode.vertical,
          interpolateValues: true,
          showTrackingTooltip: true,
          showIntersectionMarkers: true,
        ),
      ),
    );
  }
}

/// Comparison layout showing before/after side by side
class _ComparisonLayout extends StatelessWidget {
  final bool showComparison;
  final String title;
  final String description;
  final Widget beforeChart;
  final Widget afterChart;
  final List<_LegendItem> legendItems;
  final String afterLabel;

  const _ComparisonLayout({
    required this.showComparison,
    required this.title,
    required this.description,
    required this.beforeChart,
    required this.afterChart,
    required this.legendItems,
    this.afterLabel = 'Multi-Axis',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and description
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                ),
          ),
          const SizedBox(height: 16),

          // Legend
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: legendItems.map((item) => _buildLegendChip(item)).toList(),
          ),
          const SizedBox(height: 16),

          // Charts
          Expanded(
            child: showComparison
                ? Row(
                    children: [
                      // Before
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.close, size: 16, color: Colors.red[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Without Multi-Axis',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.red[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: beforeChart,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // After
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, size: 16, color: Colors.green[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'With $afterLabel',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.green[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: afterChart,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : afterChart,
          ),

          // Hover hint
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.touch_app,
                  size: 16,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Hover over the chart to see values with units in the tooltip',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendChip(_LegendItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: item.color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.range,
            style: TextStyle(
              fontSize: 12,
              color: item.color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem {
  final String label;
  final Color color;
  final String range;

  _LegendItem(this.label, this.color, this.range);
}
