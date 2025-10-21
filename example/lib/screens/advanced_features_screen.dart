import 'dart:async';
import 'dart:math';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Advanced features showcase
///
/// Demonstrates:
/// - Real-time data streaming with throttling
/// - Programmatic control via ChartController
/// - Dynamic data updates
/// - Multiple controllers
/// - Stream lifecycle management
class AdvancedFeaturesScreen extends StatefulWidget {
  const AdvancedFeaturesScreen({super.key});

  @override
  State<AdvancedFeaturesScreen> createState() => _AdvancedFeaturesScreenState();
}

class _AdvancedFeaturesScreenState extends State<AdvancedFeaturesScreen> {
  // Controllers and streams
  final _controllerDemo = ChartController();
  final _streamController = StreamController<ChartDataPoint>();
  final _multiStreamController1 = StreamController<ChartDataPoint>();
  final _multiStreamController2 = StreamController<ChartDataPoint>();

  // Timers for simulated data
  Timer? _sensorTimer;
  Timer? _multiTimer1;
  Timer? _multiTimer2;

  // Counters
  int _sensorDataCount = 0;
  int _controlledDataCount = 0;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _startSensorSimulation();
    _startMultiStreamSimulation();
  }

  @override
  void dispose() {
    _sensorTimer?.cancel();
    _multiTimer1?.cancel();
    _multiTimer2?.cancel();
    _streamController.close();
    _multiStreamController1.close();
    _multiStreamController2.close();
    _controllerDemo.dispose();
    super.dispose();
  }

  void _startSensorSimulation() {
    _sensorTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (mounted && _sensorDataCount < 50) {
        final value = 50 + _random.nextDouble() * 50;
        _streamController.add(
          ChartDataPoint(x: _sensorDataCount.toDouble(), y: value),
        );
        _sensorDataCount++;
      } else {
        timer.cancel();
      }
    });
  }

  void _startMultiStreamSimulation() {
    // Stream 1: Temperature (slower, 500ms)
    _multiTimer1 = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        final temp = 20 + _random.nextDouble() * 10;
        _multiStreamController1.add(
          ChartDataPoint(x: timer.tick.toDouble(), y: temp),
        );
        if (timer.tick > 40) timer.cancel();
      }
    });

    // Stream 2: Humidity (faster, 300ms)
    _multiTimer2 = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (mounted) {
        final humidity = 40 + _random.nextDouble() * 40;
        _multiStreamController2.add(
          ChartDataPoint(x: timer.tick.toDouble(), y: humidity),
        );
        if (timer.tick > 60) timer.cancel();
      }
    });
  }

  void _addRandomPoint() {
    setState(() {
      _controllerDemo.addPoint(
        'controlled',
        ChartDataPoint(
          x: _controlledDataCount.toDouble(),
          y: _random.nextDouble() * 100,
        ),
      );
      _controlledDataCount++;
    });
  }

  void _removeOldestPoint() {
    setState(() {
      _controllerDemo.removeOldestPoint('controlled');
    });
  }

  void _clearAllData() {
    setState(() {
      _controllerDemo.clearSeries('controlled');
      _controlledDataCount = 0;
    });
  }

  void _addPeakAnnotation() {
    final series = _controllerDemo.getAllSeries()['controlled'];
    if (series != null && series.isNotEmpty) {
      // Find peak value
      double maxY = series[0].y;
      int maxIndex = 0;
      for (int i = 1; i < series.length; i++) {
        if (series[i].y > maxY) {
          maxY = series[i].y;
          maxIndex = i;
        }
      }

      setState(() {
        _controllerDemo.addAnnotation(
          PointAnnotation(
            id: 'peak_${DateTime.now().millisecondsSinceEpoch}',
            label: 'Peak: ${maxY.toStringAsFixed(1)}',
            seriesId: 'controlled',
            dataPointIndex: maxIndex,
            markerShape: MarkerShape.star,
            markerSize: 14,
            style: const AnnotationStyle(
              textColor: Colors.orange,
              borderColor: Colors.orange,
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Features'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          _buildControllerDemo(),
          const SizedBox(height: 24),
          _buildStreamingDemo(),
          const SizedBox(height: 24),
          _buildMultiStreamDemo(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.science, color: Colors.indigo.shade700, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Advanced Features',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time streaming, programmatic control, and dynamic data management.',
                    style: TextStyle(color: Colors.indigo.shade800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControllerDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.control_camera, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'ChartController',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Programmatically control chart data and annotations. '
              'Add, remove, or clear data points dynamically.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            BravenChart(
              chartType: ChartType.line,
              series: [
                ChartSeries(
                  id: 'controlled',
                  points: const [],
                  color: Colors.blue,
                ),
              ],
              controller: _controllerDemo,
              title: 'Controlled Chart',
              width: 400,
              height: 300,
              theme: ChartTheme.defaultLight,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _addRandomPoint,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Point'),
                ),
                ElevatedButton.icon(
                  onPressed: _removeOldestPoint,
                  icon: const Icon(Icons.remove),
                  label: const Text('Remove Oldest'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _clearAllData,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addPeakAnnotation,
                  icon: const Icon(Icons.star),
                  label: const Text('Mark Peak'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'final controller = ChartController();\n\n'
                '// Add data\n'
                'controller.addPoint(\n'
                '  \'series_id\',\n'
                '  ChartDataPoint(x: 1, y: 20),\n'
                ');\n\n'
                '// Remove oldest\n'
                'controller.removeOldestPoint(\'series_id\');\n\n'
                '// Clear all\n'
                'controller.clearSeries(\'series_id\');\n\n'
                '// Add annotation\n'
                'controller.addAnnotation(annotation);',
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

  Widget _buildStreamingDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.stream, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Real-Time Streaming',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Automatic 60 FPS throttling. Data points: $_sensorDataCount/50',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            BravenChart(
              chartType: ChartType.area,
              series: const [],
              dataStream: _streamController.stream,
              title: 'Sensor Data (200ms intervals)',
              subtitle: 'Auto-throttled to 60 FPS',
              width: 400,
              height: 300,
              theme: ChartTheme.defaultLight,
              yAxis: AxisConfig.defaults().copyWith(
                label: 'Value',
              ),
            ),
            const SizedBox(height: 12),
            if (_sensorDataCount >= 50)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Streaming complete! Chart automatically throttled '
                        '200ms updates to 60 FPS (16ms intervals).',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'final stream = StreamController<ChartDataPoint>();\n\n'
                'BravenChart(\n'
                '  chartType: ChartType.line,\n'
                '  series: [],\n'
                '  dataStream: stream.stream,\n'
                ');\n\n'
                '// Add data to stream\n'
                'stream.add(ChartDataPoint(x: 1, y: 20));\n\n'
                '// Automatically throttled to 60 FPS!',
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

  Widget _buildMultiStreamDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.device_hub, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Multiple Data Streams',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Each series can have its own stream with different update rates.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            BravenChart(
              chartType: ChartType.line,
              series: [
                ChartSeries(
                  id: 'temperature',
                  points: const [],
                  color: Colors.blue,
                  name: 'Temperature',
                ),
                ChartSeries(
                  id: 'humidity',
                  points: const [],
                  color: Colors.orange,
                  name: 'Humidity',
                ),
              ],
              title: 'Multi-Sensor Dashboard',
              subtitle: 'Temperature (500ms) & Humidity (300ms)',
              width: 400,
              height: 300,
              theme: ChartTheme.defaultLight,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Temperature: Updates every 500ms',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Humidity: Updates every 300ms',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '// Create separate streams\n'
                'final stream1 = StreamController<ChartDataPoint>();\n'
                'final stream2 = StreamController<ChartDataPoint>();\n\n'
                '// Different update rates\n'
                'Timer.periodic(Duration(milliseconds: 500), (timer) {\n'
                '  stream1.add(ChartDataPoint(...));\n'
                '});\n\n'
                'Timer.periodic(Duration(milliseconds: 300), (timer) {\n'
                '  stream2.add(ChartDataPoint(...));\n'
                '});\n\n'
                '// Each series updates independently!',
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
}
