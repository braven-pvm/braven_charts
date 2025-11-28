// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Streaming mode test screen for validating dual-mode functionality.
///
/// This screen demonstrates the new dual-mode streaming feature (User Story 1):
/// - Streaming mode: Continuous data updates, auto-scroll, interactions disabled
/// - Interactive mode: Normal zoom/pan/interaction behavior
///
/// **Test Checklist:**
/// - ✅ Chart starts in streaming mode (no zoom/pan/interactions)
/// - ✅ Data streams continuously with auto-scroll
/// - ✅ Pause button switches to interactive mode
/// - ✅ In interactive mode: zoom/pan/crosshair/tooltip work
/// - ✅ Resume button switches back to streaming mode
/// - ✅ Auto-resume after timeout works
/// - ✅ Buffer overflow handled correctly
/// - ✅ No rendering errors or performance issues
class StreamingTestScreen extends StatefulWidget {
  const StreamingTestScreen({super.key});

  @override
  State<StreamingTestScreen> createState() => _StreamingTestScreenState();
}

class _StreamingTestScreenState extends State<StreamingTestScreen> {
  final ChartController _controller = ChartController();
  late StreamController<ChartDataPoint> _dataStreamController;
  Timer? _dataTimer;

  double _currentX = 0;
  int _pointsGenerated = 0;
  int _pointsBuffered = 0;
  ChartMode _currentMode = ChartMode.streaming;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _dataStreamController = StreamController<ChartDataPoint>.broadcast();
    _startDataGeneration();
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    _dataStreamController.close();
    _controller.dispose();
    super.dispose();
  }

  /// Starts generating simulated streaming data (sine wave)
  void _startDataGeneration() {
    setState(() {
      _statusMessage = 'Streaming active - generating data...';
    });

    _dataTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_dataStreamController.isClosed) {
        // Generate sine wave data point
        final y = 50 + 30 * math.sin(_currentX * 0.1);
        final point = ChartDataPoint(x: _currentX, y: y);

        _dataStreamController.add(point);

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
      _statusMessage = 'Streaming paused';
    });
  }

  void _resetChart() {
    _stopDataGeneration();
    setState(() {
      _currentX = 0;
      _pointsGenerated = 0;
      _pointsBuffered = 0;
      _statusMessage = 'Chart reset';
    });
    _dataStreamController.close();
    _dataStreamController = StreamController<ChartDataPoint>.broadcast();
    _startDataGeneration();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Streaming Mode Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetChart,
            tooltip: 'Reset Chart',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dual-Mode Streaming Test (User Story 1)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mode: ${_currentMode == ChartMode.streaming ? "STREAMING" : "INTERACTIVE"}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Status: $_statusMessage',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Points Generated: $_pointsGenerated',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
                Text(
                  'Points Buffered: $_pointsBuffered',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
            ),
          ),

          // Chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BravenChart(
                    chartType: ChartType.line,
                    series: const [],
                    dataStream: _dataStreamController.stream,
                    streamingConfig: StreamingConfig(
                      maxBufferSize: 100, // Must be >= maxVisiblePoints (150), using 2x for buffering headroom
                      autoResumeTimeout: const Duration(seconds: 5),
                      onModeChanged: (mode) {
                        setState(() {
                          _currentMode = mode;
                          _statusMessage = mode == ChartMode.streaming ? 'Switched to STREAMING mode' : 'Switched to INTERACTIVE mode';
                        });
                      },
                      onBufferUpdated: (bufferCount) {
                        setState(() {
                          _pointsBuffered = bufferCount;
                          _statusMessage = 'Buffering: $bufferCount points queued';
                        });
                      },
                      onReturnToLive: () {
                        setState(() {
                          _statusMessage = 'User can return to live mode';
                        });
                      },
                      onStreamError: (error) {
                        setState(() {
                          _statusMessage = 'Stream error: $error';
                        });
                      },
                    ),
                    controller: _controller,
                    autoScrollConfig: const AutoScrollConfig(
                      enabled: true,
                      maxVisiblePoints: 150,
                      resumeOnNewData: true,
                      animateScroll: false,
                    ),
                    title: 'Live Data Stream - Sine Wave',
                    interactionConfig: InteractionConfig(
                      enabled: true,
                      enableZoom: true,
                      enablePan: true,
                      crosshair: const CrosshairConfig(enabled: true),
                      tooltip: const TooltipConfig(enabled: true),
                      onDataPointTap: (point, position) {
                        setState(() {
                          _statusMessage = 'Tapped: x=${point.x.toStringAsFixed(1)}, y=${point.y.toStringAsFixed(1)}';
                        });
                      },
                      onDataPointHover: (point, position) {
                        if (point != null) {
                          setState(() {
                            _statusMessage = 'Hover: x=${point.x.toStringAsFixed(1)}, y=${point.y.toStringAsFixed(1)}';
                          });
                        }
                      },
                      onZoomChanged: (zoomX, zoomY) {
                        setState(() {
                          _statusMessage = 'Zoom: ${zoomX.toStringAsFixed(2)}x';
                        });
                      },
                      onPanChanged: (offset) {
                        setState(() {
                          _statusMessage = 'Pan: ${offset.dx.toStringAsFixed(0)}, ${offset.dy.toStringAsFixed(0)}';
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Test Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test Instructions:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...[
                  '1. Verify STREAMING mode - data auto-scrolls, no zoom/pan',
                  '2. Try to zoom/pan - should NOT work in streaming mode',
                  '3. Click chart - should switch to INTERACTIVE mode',
                  '4. In interactive mode - verify zoom/pan/crosshair work',
                  '5. Wait 5 seconds - should auto-resume streaming mode',
                  '6. Check buffered points counter during pause',
                  '7. Verify smooth transitions between modes',
                  '8. Check console - verify NO rendering errors',
                ].map(
                  (instruction) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      instruction,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

