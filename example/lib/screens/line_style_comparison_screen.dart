// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Comprehensive line style comparison screen.
///
/// Allows dynamic switching between LineStyle.straight, LineStyle.smooth (bezier),
/// and LineStyle.stepped for the SAME dataset to clearly see the interpolation differences.
///
/// Features:
/// - Toggle between static and streaming modes
/// - Generate random data or predefined patterns
/// - Switch line styles in real-time
/// - Side-by-side comparison view
class LineStyleComparisonScreen extends StatefulWidget {
  const LineStyleComparisonScreen({super.key});

  @override
  State<LineStyleComparisonScreen> createState() => _LineStyleComparisonScreenState();
}

class _LineStyleComparisonScreenState extends State<LineStyleComparisonScreen> {
  // Current line style selection
  LineStyle _selectedLineStyle = LineStyle.smooth;

  // Chart type selection
  ChartType _selectedChartType = ChartType.line;

  // Data generation mode
  DataGenerationMode _dataMode = DataGenerationMode.sineWave; // Streaming state
  bool _isStreaming = false;
  StreamController<ChartDataPoint>? _streamController;
  Timer? _streamTimer;
  double _currentX = 0;

  // Static data for comparison
  List<ChartDataPoint> _staticData = [];

  @override
  void initState() {
    super.initState();
    _generateStaticData();
  }

  @override
  void dispose() {
    _stopStreaming();
    super.dispose();
  }

  void _generateStaticData() {
    setState(() {
      _staticData = _generateDataPoints(_dataMode, 0, 50);
    });
  }

  List<ChartDataPoint> _generateDataPoints(DataGenerationMode mode, double startX, int count) {
    final points = <ChartDataPoint>[];

    switch (mode) {
      case DataGenerationMode.sineWave:
        // Sine wave - best for showing bezier curves
        for (int i = 0; i < count; i++) {
          final x = startX + i;
          final y = 50 + 30 * math.sin(x * 0.2);
          points.add(ChartDataPoint(x: x, y: y));
        }
        break;

      case DataGenerationMode.random:
        // Random walk
        double currentY = 50;
        for (int i = 0; i < count; i++) {
          final x = startX + i;
          currentY += (math.Random().nextDouble() - 0.5) * 20;
          currentY = currentY.clamp(10, 90);
          points.add(ChartDataPoint(x: x, y: currentY));
        }
        break;

      case DataGenerationMode.zigzag:
        // Zigzag pattern
        for (int i = 0; i < count; i++) {
          final x = startX + i;
          final y = i % 2 == 0 ? 30.0 : 70.0;
          points.add(ChartDataPoint(x: x, y: y));
        }
        break;

      case DataGenerationMode.peaks:
        // Mountain peaks
        for (int i = 0; i < count; i++) {
          final x = startX + i;
          final y = 50 + 40 * math.sin(x * 0.3) * math.cos(x * 0.1);
          points.add(ChartDataPoint(x: x, y: y));
        }
        break;

      case DataGenerationMode.steps:
        // Step function - shows difference best with stepped style
        for (int i = 0; i < count; i++) {
          final x = startX + i;
          final y = 20 + (i ~/ 5) * 15.0;
          points.add(ChartDataPoint(x: x, y: y.clamp(10, 90)));
        }
        break;
    }

    return points;
  }

  void _startStreaming() {
    _stopStreaming();

    setState(() {
      _isStreaming = true;
      _currentX = 0;
      _streamController = StreamController<ChartDataPoint>.broadcast();
    });

    _streamTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_streamController != null && !_streamController!.isClosed) {
        final points = _generateDataPoints(_dataMode, _currentX, 1);
        if (points.isNotEmpty) {
          _streamController!.add(points.first);
          _currentX++;
        }
      }
    });
  }

  void _stopStreaming() {
    _streamTimer?.cancel();
    _streamTimer = null;
    _streamController?.close();
    _streamController = null;

    setState(() {
      _isStreaming = false;
    });
  }

  void _toggleStreaming() {
    if (_isStreaming) {
      _stopStreaming();
    } else {
      _startStreaming();
    }
  }

  void _changeDataMode(DataGenerationMode mode) {
    setState(() {
      _dataMode = mode;
    });

    if (_isStreaming) {
      // Restart streaming with new data mode
      _startStreaming();
    } else {
      // Regenerate static data
      _generateStaticData();
    }
  }

  void _changeLineStyle(LineStyle style) {
    setState(() {
      _selectedLineStyle = style;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Line Style Comparison'),
        actions: [
          IconButton(
            icon: Icon(_isStreaming ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleStreaming,
            tooltip: _isStreaming ? 'Stop Streaming' : 'Start Streaming',
          ),
        ],
      ),
      body: Column(
        children: [
          // Controls Panel
          _buildControlsPanel(),

          const Divider(height: 1),

          // Chart Display
          Expanded(
            child: _isStreaming ? _buildStreamingChart() : _buildStaticChart(),
          ),

          const Divider(height: 1),

          // Info Panel
          _buildInfoPanel(),
        ],
      ),
    );
  }

  Widget _buildControlsPanel() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line Style Selector
            const Text(
              'Line Style (Same Data, Different Interpolation)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildLineStyleChip(
                  'Straight',
                  LineStyle.straight,
                  Icons.show_chart,
                  Colors.blue,
                  'Linear interpolation - straight lines between points',
                ),
                _buildLineStyleChip(
                  'Smooth (Bezier)',
                  LineStyle.smooth,
                  Icons.auto_graph,
                  Colors.green,
                  'Cubic bezier curves - Catmull-Rom spline interpolation',
                ),
                _buildLineStyleChip(
                  'Stepped',
                  LineStyle.stepped,
                  Icons.stairs,
                  Colors.orange,
                  'Step function - horizontal then vertical',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Chart Type Selector
            const Text(
              'Chart Type',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Line Chart'),
                  selected: _selectedChartType == ChartType.line,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedChartType = ChartType.line);
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Area Chart'),
                  selected: _selectedChartType == ChartType.area,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedChartType = ChartType.area);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Data Generation Mode
            const Text(
              'Data Pattern',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DataGenerationMode.values.map((mode) {
                return ChoiceChip(
                  label: Text(mode.label),
                  selected: _dataMode == mode,
                  onSelected: (selected) {
                    if (selected) _changeDataMode(mode);
                  },
                  avatar: Icon(mode.icon, size: 18),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineStyleChip(
    String label,
    LineStyle style,
    IconData icon,
    Color color,
    String tooltip,
  ) {
    final isSelected = _selectedLineStyle == style;

    return Tooltip(
      message: tooltip,
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) _changeLineStyle(style);
        },
        backgroundColor: color.withOpacity(0.1),
        selectedColor: color.withOpacity(0.3),
        checkmarkColor: color,
        labelStyle: TextStyle(
          color: isSelected ? color : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildStaticChart() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Static Mode - ${_dataMode.label}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BravenChart(
              chartType: _selectedChartType,
              lineStyle: _selectedLineStyle,
              series: [
                ChartSeries(
                  id: 'data',
                  name: _selectedLineStyle.name.toUpperCase(),
                  points: _staticData,
                  color: _getColorForLineStyle(_selectedLineStyle),
                ),
              ],
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
    );
  }

  Widget _buildStreamingChart() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Streaming Mode - ${_dataMode.label} (10Hz)',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BravenChart(
              chartType: _selectedChartType,
              lineStyle: _selectedLineStyle,
              series: const [],
              dataStream: _streamController?.stream,
              streamingConfig: StreamingConfig(
                maxBufferSize: 100,
                autoResumeTimeout: const Duration(seconds: 5),
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
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Understanding Line Styles',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.show_chart,
            'STRAIGHT',
            'Connects data points with straight line segments (linear interpolation)',
            Colors.blue,
          ),
          const SizedBox(height: 6),
          _buildInfoRow(
            Icons.auto_graph,
            'SMOOTH (BEZIER)',
            'Creates smooth curves using cubic bezier with Catmull-Rom spline algorithm',
            Colors.green,
          ),
          const SizedBox(height: 6),
          _buildInfoRow(
            Icons.stairs,
            'STEPPED',
            'Creates horizontal-then-vertical steps (good for discrete changes)',
            Colors.orange,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.timeline, color: Colors.blue[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Toggle between Line and Area charts to see how interpolation affects both chart types',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isStreaming
                ? '🟢 LIVE STREAMING - Change line style to see real-time interpolation differences'
                : '⚫ STATIC MODE - Click Play to start streaming, or change data pattern',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorForLineStyle(LineStyle style) {
    switch (style) {
      case LineStyle.straight:
        return Colors.blue;
      case LineStyle.smooth:
        return Colors.green;
      case LineStyle.stepped:
        return Colors.orange;
    }
  }
}

enum DataGenerationMode {
  sineWave('Sine Wave', Icons.waves),
  random('Random Walk', Icons.shuffle),
  zigzag('Zigzag', Icons.trending_up),
  peaks('Peaks', Icons.landscape),
  steps('Steps', Icons.stairs);

  const DataGenerationMode(this.label, this.icon);

  final String label;
  final IconData icon;
}
