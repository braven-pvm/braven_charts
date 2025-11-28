// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// T078: Advanced streaming example with custom configuration.
///
/// This example demonstrates advanced streaming features:
/// - Custom auto-resume timeout (3 seconds)
/// - Buffer update callbacks (onBufferUpdated)
/// - Mode change callbacks (onModeChanged)
/// - Manual resume control (StreamingController)
/// - Return-to-live notification (onReturnToLive)
/// - Stream error handling (onStreamError)
///
/// **Advanced Features:**
/// - Manual pause/resume buttons via StreamingController
/// - Real-time buffer count monitoring
/// - Mode change notifications
/// - Custom timeout configuration
/// - Error handling with callbacks
///
/// **Usage:**
/// ```dart
/// final controller = StreamingController();
///
/// BravenChart(
///   dataStream: myStream,
///   streamingConfig: StreamingConfig(
///     autoResumeTimeout: Duration(seconds: 3),
///     maxBufferSize: 500,
///     onModeChanged: (mode) => print('Mode: $mode'),
///     onBufferUpdated: (count) => print('Buffered: $count'),
///     onReturnToLive: () => print('Ready to resume'),
///     onStreamError: (error) => print('Error: $error'),
///   ),
///   streamingController: controller,
/// )
/// ```
class AdvancedStreamingExample extends StatefulWidget {
  const AdvancedStreamingExample({super.key});

  @override
  State<AdvancedStreamingExample> createState() => _AdvancedStreamingExampleState();
}

class _AdvancedStreamingExampleState extends State<AdvancedStreamingExample> {
  late StreamController<ChartDataPoint> _dataStream;
  final StreamingController _streamingController = StreamingController();
  Timer? _dataTimer;

  double _currentX = 0;
  int _bufferCount = 0;
  ChartMode _currentMode = ChartMode.streaming;
  String _statusMessage = 'Initializing...';
  final List<String> _eventLog = [];

  @override
  void initState() {
    super.initState();
    _dataStream = StreamController<ChartDataPoint>.broadcast();
    _startDataGeneration();
    _addToLog('Chart initialized in STREAMING mode');
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    _dataStream.close();
    _streamingController.dispose();
    super.dispose();
  }

  void _startDataGeneration() {
    _dataTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_dataStream.isClosed) {
        // Generate more complex waveform (sine + noise)
        final sine = math.sin(_currentX * 0.05);
        final noise = (math.Random().nextDouble() - 0.5) * 0.2;
        final y = 50 + 30 * (sine + noise);

        _dataStream.add(ChartDataPoint(x: _currentX, y: y));
        _currentX++;
      }
    });
  }

  void _addToLog(String message) {
    setState(() {
      _eventLog.insert(0, '${DateTime.now().toString().substring(11, 23)}: $message');
      if (_eventLog.length > 8) {
        _eventLog.removeLast();
      }
    });
  }

  void _manualPause() {
    _streamingController.pauseStreaming();
    _addToLog('Manual PAUSE triggered');
  }

  void _manualResume() {
    _streamingController.resumeStreaming();
    _addToLog('Manual RESUME triggered');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Streaming Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Panel
            Card(
              color: _currentMode == ChartMode.streaming ? Colors.green.shade50 : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Status: $_statusMessage'),
                    Text('Buffer Count: $_bufferCount points'),
                    Text('Data Generated: ${_currentX.toInt()} points'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Manual Control Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentMode == ChartMode.interactive ? null : _manualPause,
                    icon: const Icon(Icons.pause),
                    label: const Text('Manual Pause'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentMode == ChartMode.streaming ? null : _manualResume,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Manual Resume'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Chart with advanced configuration
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BravenChart(
                    chartType: ChartType.line,
                    series: const [],
                    dataStream: _dataStream.stream,

                    // ADVANCED STREAMING CONFIGURATION
                    streamingConfig: StreamingConfig(
                      // Custom timeout - shorter than default 10 seconds
                      autoResumeTimeout: const Duration(seconds: 3),

                      // Smaller buffer for demo purposes
                      maxBufferSize: 500,

                      // Mode change callback
                      onModeChanged: (ChartMode mode) {
                        setState(() {
                          _currentMode = mode;
                          _statusMessage = mode == ChartMode.streaming ? 'Streaming active' : 'Interactive mode - auto-resume in 3s';
                        });
                        _addToLog('Mode changed to: ${mode.name.toUpperCase()}');
                      },

                      // Buffer update callback
                      onBufferUpdated: (int count) {
                        setState(() {
                          _bufferCount = count;
                        });
                        if (count > 0 && count % 50 == 0) {
                          _addToLog('Buffer: $count points queued');
                        }
                      },

                      // Return-to-live callback
                      onReturnToLive: () {
                        _addToLog('Buffer applied - returned to live');
                        setState(() {
                          _statusMessage = 'Returned to live - buffer applied';
                        });
                      },

                      // Stream error callback
                      onStreamError: (Object error) {
                        _addToLog('ERROR: $error');
                        setState(() {
                          _statusMessage = 'Stream error occurred';
                        });
                      },
                    ),

                    // Manual control via StreamingController
                    streamingController: _streamingController,

                    title: 'Advanced Streaming with Callbacks',
                    interactionConfig: const InteractionConfig(
                      enabled: true,
                      enableZoom: true,
                      enablePan: true,
                      crosshair: CrosshairConfig(enabled: true),
                      tooltip: TooltipConfig(enabled: true),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Event Log
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event Log:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 120,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: _eventLog.length,
                        itemBuilder: (context, index) {
                          return Text(
                            _eventLog[index],
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

