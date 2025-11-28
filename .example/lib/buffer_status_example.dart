// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// T079: Buffer status example with "Return to Live" button.
///
/// This example demonstrates buffer count tracking and manual resume:
/// - Real-time buffer count display using onBufferUpdated
/// - Visual indicator when data is buffering
/// - "Return to Live" button using StreamingController
/// - Buffer overflow handling (forced auto-resume)
///
/// **Key Features:**
/// - onBufferUpdated callback tracks queued data points
/// - StreamingController enables manual resume button
/// - Visual feedback for buffer state
/// - Demonstrates buffer overflow behavior (maxBufferSize)
///
/// **Usage:**
/// ```dart
/// final controller = StreamingController();
/// int bufferCount = 0;
///
/// BravenChart(
///   dataStream: myStream,
///   streamingConfig: StreamingConfig(
///     maxBufferSize: 100,  // Force resume when buffer full
///     onBufferUpdated: (count) => setState(() => bufferCount = count),
///   ),
///   streamingController: controller,
/// )
///
/// // "Return to Live" button:
/// ElevatedButton(
///   onPressed: () => controller.resumeStreaming(),
///   child: Text('Return to Live ($bufferCount buffered)'),
/// )
/// ```
class BufferStatusExample extends StatefulWidget {
  const BufferStatusExample({super.key});

  @override
  State<BufferStatusExample> createState() => _BufferStatusExampleState();
}

class _BufferStatusExampleState extends State<BufferStatusExample> {
  late StreamController<ChartDataPoint> _dataStream;
  final StreamingController _streamingController = StreamingController();
  Timer? _dataTimer;

  double _currentX = 0;
  int _bufferCount = 0;
  ChartMode _currentMode = ChartMode.streaming;
  bool _showReturnToLiveButton = false;

  @override
  void initState() {
    super.initState();
    _dataStream = StreamController<ChartDataPoint>.broadcast();
    _startDataGeneration();
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    _dataStream.close();
    _streamingController.dispose();
    super.dispose();
  }

  void _startDataGeneration() {
    // Generate data at 20 points/second for demonstration
    _dataTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_dataStream.isClosed) {
        final y = 50 + 30 * math.sin(_currentX * 0.05);
        _dataStream.add(ChartDataPoint(x: _currentX, y: y));
        _currentX++;
      }
    });
  }

  void _returnToLive() {
    _streamingController.resumeStreaming();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buffer Status Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buffer Count Tracking',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Click chart to pause streaming (enter interactive mode)\n'
                      '• Watch buffer count increase while paused\n'
                      '• Click "Return to Live" button to apply buffered data\n'
                      '• Buffer overflow (>200 points) triggers automatic resume',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Buffer Status Display
            Card(
              color: _currentMode == ChartMode.interactive && _bufferCount > 0 ? Colors.orange.shade50 : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _currentMode == ChartMode.streaming ? Icons.rss_feed : Icons.pause_circle_filled,
                      color: _currentMode == ChartMode.streaming ? Colors.green : Colors.orange,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentMode == ChartMode.streaming ? 'Streaming LIVE' : 'PAUSED - Buffering Data',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Buffer: $_bufferCount points queued',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (_bufferCount > 150)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '⚠️ Buffer filling fast - auto-resume at 200 points',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Return to Live Button
            if (_showReturnToLiveButton && _currentMode == ChartMode.interactive)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _returnToLive,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  icon: const Icon(Icons.play_arrow, size: 32),
                  label: Text(
                    _bufferCount > 0 ? 'Return to Live ($_bufferCount buffered)' : 'Return to Live',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            if (_showReturnToLiveButton && _currentMode == ChartMode.interactive) const SizedBox(height: 16),

            // Chart with buffer tracking
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BravenChart(
                    chartType: ChartType.line,
                    series: const [],
                    dataStream: _dataStream.stream,

                    // BUFFER TRACKING CONFIGURATION
                    streamingConfig: StreamingConfig(
                      // Smaller buffer for demo - forces auto-resume sooner
                      maxBufferSize: 200,

                      // Shorter auto-resume timeout
                      autoResumeTimeout: const Duration(seconds: 5),

                      // Track mode changes to show/hide button
                      onModeChanged: (ChartMode mode) {
                        setState(() {
                          _currentMode = mode;
                          // Show button immediately when entering interactive mode
                          _showReturnToLiveButton = (mode == ChartMode.interactive);
                        });
                      },

                      // CRITICAL: Track buffer count in real-time
                      onBufferUpdated: (int count) {
                        setState(() {
                          _bufferCount = count;
                        });
                      },

                      // Hide button when returning to live
                      onReturnToLive: () {
                        setState(() {
                          _showReturnToLiveButton = false;
                        });
                      },
                    ),

                    // Enable manual control
                    streamingController: _streamingController,

                    title: 'Live Data with Buffer Tracking',
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

            // Code snippet
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Key Code:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        r'''// Track buffer count
StreamingConfig(
  onBufferUpdated: (count) {
    setState(() => bufferCount = count);
  },
)

// "Return to Live" button
ElevatedButton(
  onPressed: () => controller.resumeStreaming(),
  child: Text("Return to Live ($bufferCount)"),
)''',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
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

