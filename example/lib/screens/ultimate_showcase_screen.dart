// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Ultimate comprehensive showcase demonstrating all core chart capabilities.
///
/// Features: Multiple series, static + streaming data, all line styles,
/// all chart types, full interaction, theme switching.
class UltimateShowcaseScreen extends StatefulWidget {
  const UltimateShowcaseScreen({super.key});

  @override
  State<UltimateShowcaseScreen> createState() => _UltimateShowcaseScreenState();
}

class _UltimateShowcaseScreenState extends State<UltimateShowcaseScreen> {
  // Data management
  final List<ChartDataPoint> _staticSeries1 = [];
  final List<ChartDataPoint> _staticSeries2 = [];
  StreamController<ChartDataPoint>? _liveStreamController;
  Timer? _dataTimer;
  double _currentX = 0;

  // UI state
  ChartType _chartType = ChartType.line;
  bool _isDarkTheme = false;
  bool _isStreaming = false;
  ChartMode _currentMode = ChartMode.streaming;
  int _bufferCount = 0;

  // Controllers
  final StreamingController _streamingController = StreamingController();

  @override
  void initState() {
    super.initState();
    _generateStaticData();
  }

  @override
  void dispose() {
    _stopStreaming();
    _streamingController.dispose();
    super.dispose();
  }

  void _generateStaticData() {
    _staticSeries1.clear();
    _staticSeries2.clear();

    // Series 1: Sine wave
    for (double x = 0; x < 100; x++) {
      final y = 50 + 30 * math.sin(x * 0.1);
      _staticSeries1.add(ChartDataPoint(x: x, y: y));
    }

    // Series 2: Cosine wave
    for (double x = 0; x < 100; x++) {
      final y = 50 + 20 * math.cos(x * 0.15);
      _staticSeries2.add(ChartDataPoint(x: x, y: y));
    }

    setState(() {});
  }

  void _startStreaming() {
    if (_isStreaming) return;

    _liveStreamController = StreamController<ChartDataPoint>.broadcast();
    _currentX = 100;

    _dataTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_liveStreamController != null && !_liveStreamController!.isClosed) {
        final sine = math.sin(_currentX * 0.05);
        final noise = (math.Random().nextDouble() - 0.5) * 0.3;
        final y = 50 + 25 * (sine + noise);

        _liveStreamController!.add(ChartDataPoint(x: _currentX, y: y));
        _currentX++;
      }
    });

    setState(() {
      _isStreaming = true;
    });
  }

  void _stopStreaming() {
    _dataTimer?.cancel();
    _dataTimer = null;
    _liveStreamController?.close();
    _liveStreamController = null;
    if (mounted) {
      setState(() {
        _isStreaming = false;
      });
    }
  }

  void _toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
  }

  void _cycleChartType() {
    setState(() {
      switch (_chartType) {
        case ChartType.line:
          _chartType = ChartType.area;
          break;
        case ChartType.area:
          _chartType = ChartType.bar;
          break;
        case ChartType.bar:
          _chartType = ChartType.scatter;
          break;
        case ChartType.scatter:
          _chartType = ChartType.line;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkTheme ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: const Text('🏆 Ultimate Showcase'),
        backgroundColor: _isDarkTheme ? Colors.grey[850] : null,
        foregroundColor: _isDarkTheme ? Colors.white : null,
        actions: [
          IconButton(
            icon: Icon(_isDarkTheme ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleTheme,
            tooltip: 'Toggle theme',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _cycleChartType,
            tooltip: 'Cycle chart type',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildControlPanel(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildChart(),
            ),
          ),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      color: _isDarkTheme ? Colors.grey[850] : Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _currentMode == ChartMode.streaming ? Icons.play_circle : Icons.pause_circle,
                  color: _currentMode == ChartMode.streaming ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mode: ${_currentMode == ChartMode.streaming ? "STREAMING" : "INTERACTIVE"}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isDarkTheme ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                Text(
                  'Type: ${_chartType.name.toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isDarkTheme ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isStreaming ? _stopStreaming : _startStreaming,
                  icon: Icon(_isStreaming ? Icons.stop : Icons.play_arrow),
                  label: Text(_isStreaming ? 'Stop' : 'Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isStreaming ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                if (_isStreaming) ...[
                  OutlinedButton.icon(
                    onPressed: () => _streamingController.pauseStreaming(),
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _streamingController.resumeStreaming(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                  ),
                ],
                const Spacer(),
                Text(
                  'Buffer: $_bufferCount',
                  style: TextStyle(color: _isDarkTheme ? Colors.white70 : Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    return BravenChart(
      chartType: _chartType,
      lineStyle: LineStyle.smooth,
      theme: _isDarkTheme ? ChartTheme.defaultDark : ChartTheme.defaultLight,
      series: [
        ChartSeries(
          id: 'sine',
          name: 'Sine Wave',
          points: _staticSeries1,
          color: Colors.blue,
        ),
        ChartSeries(
          id: 'cosine',
          name: 'Cosine Wave',
          points: _staticSeries2,
          color: Colors.purple,
        ),
      ],
      dataStream: _liveStreamController?.stream,
      streamingConfig: StreamingConfig(
        maxBufferSize: 200,
        autoResumeTimeout: const Duration(seconds: 3),
        onModeChanged: (mode) {
          setState(() {
            _currentMode = mode;
          });
        },
        onBufferUpdated: (count) {
          setState(() {
            _bufferCount = count;
          });
        },
      ),
      autoScrollConfig: const AutoScrollConfig(
        enabled: true,
        maxVisiblePoints: 50,
        resumeOnNewData: true,
        animateScroll: false, // Disable animation for smoother streaming
        scrollAnimationDuration: Duration(milliseconds: 100),
      ),
      streamingController: _streamingController,
      interactionConfig: const InteractionConfig(
        enabled: true,
        enableZoom: true,
        enablePan: true,
        crosshair: CrosshairConfig(enabled: true),
        tooltip: TooltipConfig(enabled: true),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: _isDarkTheme ? Colors.grey[850] : Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '📊 Features:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _isDarkTheme ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildChip('Static Data', Colors.blue),
              _buildChip('Smooth Lines', Colors.purple),
              _buildChip('Live Stream', Colors.red),
              _buildChip('Zoom/Pan', Colors.orange),
              _buildChip('Crosshair', Colors.green),
              _buildChip('Tooltips', Colors.teal),
              _buildChip('Themes', Colors.pink),
              _buildChip('Types', Colors.indigo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withOpacity(0.2),
      side: BorderSide(color: color),
    );
  }
}
