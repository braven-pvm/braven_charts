// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Screen demonstrating ALL line styles with live streaming data.
///
/// Shows that cubic bezier curves work perfectly with real-time streaming.
class LineStylesStreamingScreen extends StatefulWidget {
  const LineStylesStreamingScreen({super.key});

  @override
  State<LineStylesStreamingScreen> createState() => _LineStylesStreamingScreenState();
}

class _LineStylesStreamingScreenState extends State<LineStylesStreamingScreen> {
  // Controllers for each chart
  final ChartController _straightController = ChartController();
  final ChartController _smoothController = ChartController();
  final ChartController _steppedController = ChartController();

  // Data stream controllers
  late StreamController<ChartDataPoint> _straightStreamController;
  late StreamController<ChartDataPoint> _smoothStreamController;
  late StreamController<ChartDataPoint> _steppedStreamController;

  Timer? _dataTimer;
  double _currentX = 0;
  int _pointsGenerated = 0;
  bool _isStreaming = true;

  @override
  void initState() {
    super.initState();
    _straightStreamController = StreamController<ChartDataPoint>.broadcast();
    _smoothStreamController = StreamController<ChartDataPoint>.broadcast();
    _steppedStreamController = StreamController<ChartDataPoint>.broadcast();
    _startDataGeneration();
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    _straightStreamController.close();
    _smoothStreamController.close();
    _steppedStreamController.close();
    _straightController.dispose();
    _smoothController.dispose();
    _steppedController.dispose();
    super.dispose();
  }

  void _startDataGeneration() {
    setState(() {
      _isStreaming = true;
    });

    _dataTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_straightStreamController.isClosed) {
        // Sine wave for smooth curves (shows bezier beautifully)
        final smoothY = 50 + 30 * math.sin(_currentX * 0.1);
        _smoothStreamController.add(ChartDataPoint(x: _currentX, y: smoothY));

        // Linear with noise for straight lines
        final straightY = 30 + (_currentX * 0.5) + (math.Random().nextDouble() * 10);
        _straightStreamController.add(ChartDataPoint(x: _currentX, y: straightY));

        // Random walk for stepped
        final steppedY = 50 + (math.Random().nextDouble() * 40 - 20);
        _steppedStreamController.add(ChartDataPoint(x: _currentX, y: steppedY));

        setState(() {
          _currentX++;
          _pointsGenerated++;
        });
      }
    });
  }

  void _stopDataGeneration() {
    _dataTimer?.cancel();
    setState(() {
      _isStreaming = false;
    });
  }

  void _toggleStreaming() {
    if (_isStreaming) {
      _stopDataGeneration();
    } else {
      _startDataGeneration();
    }
  }

  void _resetCharts() {
    _stopDataGeneration();
    setState(() {
      _currentX = 0;
      _pointsGenerated = 0;
    });

    _straightStreamController.close();
    _smoothStreamController.close();
    _steppedStreamController.close();

    _straightStreamController = StreamController<ChartDataPoint>.broadcast();
    _smoothStreamController = StreamController<ChartDataPoint>.broadcast();
    _steppedStreamController = StreamController<ChartDataPoint>.broadcast();

    _startDataGeneration();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Line Styles - Live Streaming'),
        actions: [
          IconButton(
            icon: Icon(_isStreaming ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleStreaming,
            tooltip: _isStreaming ? 'Pause' : 'Resume',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCharts,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildChartCard(
            '🟦 Straight Lines (Live)',
            'Linear interpolation',
            LineStyle.straight,
            _straightStreamController,
            _straightController,
          ),
          const SizedBox(height: 16),
          _buildChartCard(
            '🟩 Smooth Bezier Curves (Live)',
            'Cubic bezier - Catmull-Rom spline',
            LineStyle.smooth,
            _smoothStreamController,
            _smoothController,
          ),
          const SizedBox(height: 16),
          _buildChartCard(
            '🟧 Stepped Lines (Live)',
            'Horizontal-then-vertical steps',
            LineStyle.stepped,
            _steppedStreamController,
            _steppedController,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All Three Line Styles - Real-Time Streaming',
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Status: ${_isStreaming ? "🟢 STREAMING" : "🔴 PAUSED"} • Points: $_pointsGenerated',
              style: TextStyle(
                color: Colors.green.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This demonstrates that cubic bezier curves (smooth lines) work '
              'perfectly with real-time streaming data. All three interpolation '
              'modes are streaming simultaneously at 10Hz (100ms intervals).',
              style: TextStyle(color: Colors.green.shade800, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(
    String title,
    String subtitle,
    LineStyle lineStyle,
    StreamController<ChartDataPoint> streamController,
    ChartController chartController,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: BravenChart(
                chartType: ChartType.line,
                lineStyle: lineStyle,
                series: const [],
                dataStream: streamController.stream,
                streamingConfig: StreamingConfig(
                  maxBufferSize: 100,
                  autoResumeTimeout: const Duration(seconds: 5),
                ),
                controller: chartController,
                autoScrollConfig: const AutoScrollConfig(
                  enabled: true,
                  maxVisiblePoints: 50,
                  resumeOnNewData: true,
                  animateScroll: false,
                ),
                interactionConfig: const InteractionConfig(
                  enabled: true,
                  enableZoom: true,
                  enablePan: true,
                  crosshair: CrosshairConfig(enabled: true),
                  tooltip: TooltipConfig(enabled: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

