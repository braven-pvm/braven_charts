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
  final _streamingDemo = ChartController();
  final _multiStreamDemo = ChartController();
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

  // Stream control state
  bool _isStreamingActive = false;
  bool _isStream1Active = false;
  bool _isStream2Active = false;
  int _streamSpeed = 200; // milliseconds
  final int _stream1Speed = 500; // milliseconds
  final int _stream2Speed = 300; // milliseconds

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Don't auto-start - let user control when to begin streaming
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
    _streamingDemo.dispose();
    _multiStreamDemo.dispose();
    super.dispose();
  }

  void _startSensorSimulation() {
    if (_isStreamingActive) return;

    setState(() {
      _isStreamingActive = true;
    });

    _sensorTimer = Timer.periodic(Duration(milliseconds: _streamSpeed), (timer) {
      if (mounted && _isStreamingActive) {
        final value = 50 + _random.nextDouble() * 50;
        // Add to controller instead of stream
        _streamingDemo.addPoint(
          'sensor',
          ChartDataPoint(x: _sensorDataCount.toDouble(), y: value),
        );
        setState(() {
          _sensorDataCount++;
        });
      }
    });
  }

  void _stopSensorSimulation() {
    setState(() {
      _isStreamingActive = false;
    });
    _sensorTimer?.cancel();
    _sensorTimer = null;
  }

  void _resetSensorData() {
    _stopSensorSimulation();
    _streamingDemo.clearSeries('sensor');
    setState(() {
      _sensorDataCount = 0;
    });
  }

  void _startMultiStreamSimulation() {
    _startStream1();
    _startStream2();
  }

  void _startStream1() {
    if (_isStream1Active) return;

    setState(() {
      _isStream1Active = true;
    });

    // Stream 1: Temperature
    _multiTimer1 = Timer.periodic(Duration(milliseconds: _stream1Speed), (timer) {
      if (mounted && _isStream1Active) {
        final temp = 20 + _random.nextDouble() * 10;
        _multiStreamDemo.addPoint(
          'temperature',
          ChartDataPoint(x: timer.tick.toDouble(), y: temp),
        );
      }
    });
  }

  void _stopStream1() {
    setState(() {
      _isStream1Active = false;
    });
    _multiTimer1?.cancel();
    _multiTimer1 = null;
  }

  void _startStream2() {
    if (_isStream2Active) return;

    setState(() {
      _isStream2Active = true;
    });

    // Stream 2: Humidity
    _multiTimer2 = Timer.periodic(Duration(milliseconds: _stream2Speed), (timer) {
      if (mounted && _isStream2Active) {
        final humidity = 40 + _random.nextDouble() * 40;
        _multiStreamDemo.addPoint(
          'humidity',
          ChartDataPoint(x: timer.tick.toDouble(), y: humidity),
        );
      }
    });
  }

  void _stopStream2() {
    setState(() {
      _isStream2Active = false;
    });
    _multiTimer2?.cancel();
    _multiTimer2 = null;
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

  void _addMultiplePoints({int count = 10}) {
    setState(() {
      for (int i = 0; i < count; i++) {
        _controllerDemo.addPoint(
          'controlled',
          ChartDataPoint(
            x: _controlledDataCount.toDouble(),
            y: _random.nextDouble() * 100,
          ),
        );
        _controlledDataCount++;
      }
    });
  }

  void _addSineWave({int points = 20}) {
    setState(() {
      for (int i = 0; i < points; i++) {
        final x = _controlledDataCount.toDouble();
        final y = 50 + 30 * sin(x * 0.3); // Sine wave centered at 50
        _controllerDemo.addPoint(
          'controlled',
          ChartDataPoint(x: x, y: y),
        );
        _controlledDataCount++;
      }
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
              textStyle: TextStyle(color: Colors.orange),
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
              interactionConfig: InteractionConfig.defaultConfig(),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _addRandomPoint,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add 1 Point'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _addMultiplePoints(count: 10),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Add 10 Points'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _addSineWave(points: 20),
                  icon: const Icon(Icons.waves, size: 18),
                  label: const Text('Add Sine Wave'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _removeOldestPoint,
                  icon: const Icon(Icons.remove, size: 18),
                  label: const Text('Remove Oldest'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addPeakAnnotation,
                  icon: const Icon(Icons.star, size: 18),
                  label: const Text('Mark Peak'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _clearAllData,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Total data points: $_controlledDataCount',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
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
              'Automatic 60 FPS throttling. ${_isStreamingActive ? "Streaming..." : "Paused"} ($_sensorDataCount points)',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            BravenChart(
              chartType: ChartType.area,
              series: [
                ChartSeries(
                  id: 'sensor',
                  points: const [],
                  color: Colors.green,
                  name: 'Sensor Value',
                ),
              ],
              controller: _streamingDemo,
              autoScrollConfig: const AutoScrollConfig(
                enabled: true,
                maxVisiblePoints: 50, // Show last 50 data points
                resumeOnNewData: true,
                animateScroll: true,
                scrollAnimationDuration: Duration(milliseconds: 200),
              ),
              title: 'Sensor Data Stream',
              subtitle: 'Updates every ${_streamSpeed}ms • Auto-scrolls after 50 points',
              width: 400,
              height: 300,
              theme: ChartTheme.defaultLight,
              yAxis: AxisConfig.defaults().copyWith(
                label: 'Value',
              ),
              interactionConfig: InteractionConfig.defaultConfig(),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isStreamingActive ? null : _startSensorSimulation,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isStreamingActive ? _stopSensorSimulation : null,
                  icon: const Icon(Icons.pause, size: 18),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _resetSensorData,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reset'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _streamSpeed,
                  items: const [
                    DropdownMenuItem(value: 50, child: Text('50ms (Fast)')),
                    DropdownMenuItem(value: 100, child: Text('100ms')),
                    DropdownMenuItem(value: 200, child: Text('200ms')),
                    DropdownMenuItem(value: 500, child: Text('500ms')),
                    DropdownMenuItem(value: 1000, child: Text('1s (Slow)')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      final wasActive = _isStreamingActive;
                      if (wasActive) _stopSensorSimulation();
                      setState(() {
                        _streamSpeed = value;
                      });
                      if (wasActive) _startSensorSimulation();
                    }
                  },
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
            Text(
              'Each series can have its own stream with different update rates. ${(_isStream1Active ? "Stream 1 active" : "")}${_isStream1Active && _isStream2Active ? ", " : ""}${(_isStream2Active ? "Stream 2 active" : "")}${!_isStream1Active && !_isStream2Active ? "Paused" : ""}',
              style: const TextStyle(color: Colors.grey),
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
              controller: _multiStreamDemo,
              autoScrollConfig: const AutoScrollConfig(
                enabled: true,
                maxVisiblePoints: 30, // Show last 30 data points for each series
                resumeOnNewData: true,
                animateScroll: true,
                scrollAnimationDuration: Duration(milliseconds: 300),
              ),
              title: 'Multi-Sensor Dashboard',
              subtitle: 'Independent stream controls • Auto-scrolls after 30 points',
              width: 400,
              height: 300,
              theme: ChartTheme.defaultLight,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
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
                          Text(
                            'Temperature (${_stream1Speed}ms)',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isStream1Active ? null : _startStream1,
                            icon: const Icon(Icons.play_arrow, size: 16),
                            label: const Text('Start'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: const Size(80, 32),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isStream1Active ? _stopStream1 : null,
                            icon: const Icon(Icons.pause, size: 16),
                            label: const Text('Stop'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: const Size(80, 32),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          Text(
                            'Humidity (${_stream2Speed}ms)',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isStream2Active ? null : _startStream2,
                            icon: const Icon(Icons.play_arrow, size: 16),
                            label: const Text('Start'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: const Size(80, 32),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isStream2Active ? _stopStream2 : null,
                            icon: const Icon(Icons.pause, size: 16),
                            label: const Text('Stop'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: const Size(80, 32),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _startMultiStreamSimulation,
              icon: const Icon(Icons.play_circle_filled, size: 18),
              label: const Text('Start Both Streams'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
