// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Example 6: Gesture Handling with Callbacks
///
/// This example demonstrates how to handle interaction events with
/// developer callbacks. Features:
/// - Track tap, hover, and long-press events on data points
/// - Monitor zoom and pan state changes
/// - Display event log showing all interactions
/// - Show selected point information
///
/// Reference: quickstart.md Example 6
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

class GestureCallbacksExample extends StatefulWidget {
  const GestureCallbacksExample({super.key});

  @override
  State<GestureCallbacksExample> createState() =>
      _GestureCallbacksExampleState();
}

class _GestureCallbacksExampleState extends State<GestureCallbacksExample> {
  String lastEvent = 'No events yet';
  Map<String, dynamic>? selectedPoint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example 6: Gesture Callbacks'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Event log
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade200,
                child: Text(
                  'Last Event: $lastEvent',
                  style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 8),
              // Selected point info
              if (selectedPoint != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.blue.shade50,
                  child: Text(
                    'Selected: X=${selectedPoint!['x']}, Y=${selectedPoint!['y']}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: BravenChart(
                  chartType: ChartType.line,
                  series: [_createSampleSeries()],
                  interactionConfig: InteractionConfig(
                    crosshair: CrosshairConfig.defaultConfig(),
                    tooltip: TooltipConfig.defaultConfig(),
                    enableZoom: true,
                    enablePan: true,
                    // Interaction callbacks
                    onDataPointTap: (point, position) {
                      setState(() {
                        lastEvent = 'Tap: X=${point.x}, Y=${point.y} at (${position.dx.toStringAsFixed(1)}, ${position.dy.toStringAsFixed(1)})';
                        selectedPoint = {'x': point.x, 'y': point.y};
                      });
                    },
                    onDataPointHover: (point, position) {
                      setState(() {
                        if (point != null) {
                          lastEvent = 'Hover: X=${point.x}, Y=${point.y}';
                        } else {
                          lastEvent = 'Hover exit';
                        }
                      });
                    },
                    onDataPointLongPress: (point, position) {
                      setState(() {
                        lastEvent = 'Long Press: X=${point.x}, Y=${point.y}';
                      });
                      // Show custom dialog on long press
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Data Point Details'),
                          content: Text('X: ${point.x}\nY: ${point.y}'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    onZoomChanged: (zoomLevelX, zoomLevelY) {
                      setState(() {
                        lastEvent =
                            'Zoom: X=${(zoomLevelX * 100).toInt()}%, Y=${(zoomLevelY * 100).toInt()}%';
                      });
                    },
                    onPanChanged: (panOffset) {
                      setState(() {
                        lastEvent =
                            'Pan: dx=${panOffset.dx.toStringAsFixed(1)}, dy=${panOffset.dy.toStringAsFixed(1)}';
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Expected Behavior:\n'
                '✅ All interaction events logged to UI\n'
                '✅ Tap selects data point and shows info\n'
                '✅ Long press shows dialog\n'
                '✅ Hover updates event log continuously\n'
                '✅ Zoom/pan events update viewport info',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ChartSeries _createSampleSeries() {
    return ChartSeries(
      id: 'data',
      name: 'Sample',
      points: List.generate(
        20,
        (i) => ChartDataPoint(
          x: i * 1.0,
          y: 50 + (i * 5) + (i % 4) * 10,
        ),
      ),
    );
  }
}
