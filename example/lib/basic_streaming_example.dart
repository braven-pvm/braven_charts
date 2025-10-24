// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// T077: Basic streaming chart example with minimal configuration.
///
/// This example demonstrates the simplest possible dual-mode streaming setup:
/// - Starts in streaming mode automatically
/// - Pauses on user interaction
/// - Auto-resumes after 10 seconds (default timeout)
/// - Clean and minimal code
///
/// **Key Features:**
/// - Automatic streaming mode on chart load
/// - Simple Stream<ChartDataPoint> configuration
/// - Default StreamingConfig with 10-second timeout
/// - No manual mode control needed
///
/// **Usage:**
/// ```dart
/// BravenChart(
///   chartType: ChartType.line,
///   dataStream: myDataStream,
///   streamingConfig: StreamingConfig(),  // Defaults to 10s timeout
/// )
/// ```
class BasicStreamingExample extends StatefulWidget {
  const BasicStreamingExample({super.key});

  @override
  State<BasicStreamingExample> createState() => _BasicStreamingExampleState();
}

class _BasicStreamingExampleState extends State<BasicStreamingExample> {
  late StreamController<ChartDataPoint> _dataStream;
  Timer? _dataTimer;
  double _currentX = 0;

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
    super.dispose();
  }

  /// Generates simulated sensor data (sine wave)
  void _startDataGeneration() {
    _dataTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_dataStream.isClosed) {
        // Simulated sensor reading
        final y = 50 + 30 * math.sin(_currentX * 0.1);
        _dataStream.add(ChartDataPoint(x: _currentX, y: y));
        _currentX++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Streaming Example'),
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
                      'Minimal Streaming Setup',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Chart starts in streaming mode (auto-scrolls)\n'
                      '• Click/zoom/pan to pause (enters interactive mode)\n'
                      '• Auto-resumes streaming after 10 seconds of inactivity\n'
                      '• Try interacting with the chart below!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Chart with minimal streaming configuration
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BravenChart(
                    chartType: ChartType.line,
                    series: const [], // Data comes from stream
                    dataStream: _dataStream.stream,
                    
                    // MINIMAL STREAMING CONFIGURATION
                    // Just pass StreamingConfig() with defaults:
                    // - 10-second auto-resume timeout
                    // - 10,000 point buffer
                    // - No callbacks needed for basic usage
                    streamingConfig: StreamingConfig(),
                    
                    title: 'Live Sensor Data',
                    interactionConfig: InteractionConfig(
                      enabled: true,
                      enableZoom: true,
                      enablePan: true,
                      crosshair: const CrosshairConfig(enabled: true),
                      tooltip: const TooltipConfig(enabled: true),
                    ),
                  ),
                ),
              ),
            ),

            // Code snippet
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Code:',
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
                        'BravenChart(\n'
                        '  chartType: ChartType.line,\n'
                        '  dataStream: myDataStream,\n'
                        '  streamingConfig: StreamingConfig(),\n'
                        ')',
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
