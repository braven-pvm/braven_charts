import 'dart:async';
import 'dart:math';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Quickstart Examples Screen
///
/// Demonstrates all 6 quickstart scenarios from quickstart.md:
/// 1. Basic Line Chart (2 minutes)
/// 2. Add Annotations (1 minute)
/// 3. Simplified Data Input (fromValues)
/// 4. Customize Axes (hidden, gridOnly)
/// 5. Real-Time Data (streaming)
/// 6. Programmatic Control (ChartController)
class QuickstartScreen extends StatefulWidget {
  const QuickstartScreen({super.key});

  @override
  State<QuickstartScreen> createState() => _QuickstartScreenState();
}

class _QuickstartScreenState extends State<QuickstartScreen> {
  // Step 5: Real-time streaming
  final _streamController = StreamController<ChartDataPoint>();
  Timer? _streamTimer;
  int _streamCounter = 0;

  // Step 6: Programmatic control
  final _controller = ChartController();

  @override
  void initState() {
    super.initState();
    _startStreaming();
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    _streamController.close();
    _controller.dispose();
    super.dispose();
  }

  void _startStreaming() {
    // Simulate sensor data every 500ms
    _streamTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        final value = 50 + Random().nextDouble() * 50; // 50-100 range
        _streamController.add(ChartDataPoint(x: _streamCounter.toDouble(), y: value));
        _streamCounter++;

        // Stop after 20 points
        if (_streamCounter >= 20) {
          timer.cancel();
        }
      }
    });
  }

  void _addDataPoint() {
    final nextX = _controller.getAllSeries()['dynamic_data']?.length ?? 0;
    _controller.addPoint('dynamic_data', ChartDataPoint(x: nextX.toDouble(), y: Random().nextDouble() * 30000));
  }

  void _addAnnotation() {
    final series = _controller.getAllSeries()['dynamic_data'];
    if (series != null && series.isNotEmpty) {
      final lastPoint = series.last;
      _controller.addAnnotation(
        TextAnnotation(
          id: 'event_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Event at ${lastPoint.x.toInt()}',
          position: const Offset(200, 100),
          style: const AnnotationStyle(
            textStyle: TextStyle(fontSize: 12, color: Colors.blue),
            backgroundColor: Colors.white,
          ),
        ),
      );
    }
  }

  void _clearData() {
    _controller.clearSeries('dynamic_data');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Quickstart Examples'), backgroundColor: theme.colorScheme.primaryContainer),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStep1(),
          const SizedBox(height: 24),
          _buildStep2(),
          const SizedBox(height: 24),
          _buildStep3(),
          const SizedBox(height: 24),
          _buildStep4Sparkline(),
          const SizedBox(height: 24),
          _buildStep4GridOnly(),
          const SizedBox(height: 24),
          _buildStep5(),
          const SizedBox(height: 24),
          _buildStep6(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Step 1: Basic Line Chart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Create a simple line chart with sales data', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            BravenChart(
              chartType: ChartType.line,
              series: [
                ChartSeries(
                  id: 'monthly_sales',
                  name: 'Monthly Sales',
                  points: const [
                    ChartDataPoint(x: 1, y: 10000), // Jan
                    ChartDataPoint(x: 2, y: 15000), // Feb
                    ChartDataPoint(x: 3, y: 12000), // Mar
                    ChartDataPoint(x: 4, y: 18000), // Apr
                    ChartDataPoint(x: 5, y: 22000), // May
                    ChartDataPoint(x: 6, y: 25000), // Jun
                  ],
                ),
              ],
              title: 'Monthly Sales 2025',
              width: 400,
              height: 300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Step 2: Add Annotations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Highlight important events on your chart', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            BravenChart(
              chartType: ChartType.line,
              series: [
                ChartSeries(
                  id: 'monthly_sales',
                  name: 'Monthly Sales',
                  points: const [
                    ChartDataPoint(x: 1, y: 10000),
                    ChartDataPoint(x: 2, y: 15000),
                    ChartDataPoint(x: 3, y: 12000),
                    ChartDataPoint(x: 4, y: 18000),
                    ChartDataPoint(x: 5, y: 22000),
                    ChartDataPoint(x: 6, y: 25000),
                  ],
                  annotations: [
                    PointAnnotation(
                      id: 'record_month',
                      seriesId: 'monthly_sales',
                      dataPointIndex: 5,
                      label: 'Record Month!',
                      markerShape: MarkerShape.star,
                      markerSize: 12,
                    ),
                    ThresholdAnnotation(
                      id: 'sales_target',
                      axis: AnnotationAxis.y,
                      value: 20000,
                      label: 'Sales Target',
                      style: const AnnotationStyle(borderColor: Colors.green, borderWidth: 2),
                    ),
                  ],
                ),
              ],
              title: 'Monthly Sales 2025',
              width: 400,
              height: 300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Step 3: Simplified Data Input', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Use fromValues factory for quick charts', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            BravenChart.fromValues(
              chartType: ChartType.line,
              seriesId: 'sales',
              seriesName: 'Sales',
              yValues: const [10000, 15000, 12000, 18000, 22000, 25000],
              title: 'Monthly Sales 2025',
              width: 400,
              height: 300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4Sparkline() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Step 4a: Sparkline (Hidden Axes)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Compact chart for dashboards', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            BravenChartPlus.fromValues(
              chartType: ChartType.line,
              seriesId: 'sales',
              yValues: const [10000, 15000, 12000, 18000, 22000, 25000],
              xAxisConfig: const XAxisConfig(
                visible: false,
                showAxisLine: false,
                showTicks: false,
                labelDisplay: AxisLabelDisplay.none,
              ),
              yAxis: const YAxisConfig(
                position: YAxisPosition.left,
                visible: false,
                showAxisLine: false,
                showTicks: false,
                labelDisplay: AxisLabelDisplay.none,
              ),
              width: 200,
              height: 60,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4GridOnly() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Step 4b: Grid Only Style', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Show grid without axis lines', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            BravenChartPlus.fromValues(
              chartType: ChartType.line,
              seriesId: 'sales',
              yValues: const [10000, 15000, 12000, 18000, 22000, 25000],
              xAxisConfig: const XAxisConfig(
                showAxisLine: false,
                showTicks: false,
                labelDisplay: AxisLabelDisplay.none,
              ),
              yAxis: const YAxisConfig(
                position: YAxisPosition.left,
                showAxisLine: false,
                showTicks: false,
                labelDisplay: AxisLabelDisplay.none,
              ),
              width: 400,
              height: 300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep5() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Step 5: Real-Time Data Streaming', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Auto-updating chart with 60 FPS throttling', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: _streamController.stream,
              title: 'Sensor Readings',
              width: 400,
              height: 300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep6() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Step 6: Programmatic Control', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Dynamic updates via ChartController', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            BravenChart(
              chartType: ChartType.line,
              series: [ChartSeries(id: 'dynamic_data', name: 'Dynamic Data', points: const [])],
              controller: _controller,
              title: 'Interactive Chart',
              width: 400,
              height: 300,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(onPressed: _addDataPoint, icon: const Icon(Icons.add), label: const Text('Add Point')),
                ElevatedButton.icon(onPressed: _addAnnotation, icon: const Icon(Icons.label), label: const Text('Add Annotation')),
                ElevatedButton.icon(
                  onPressed: _clearData,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Data'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
