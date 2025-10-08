// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Example 8: Complete Interaction Configuration
///
/// This example demonstrates all interaction features working together:
/// - Crosshair with custom styling
/// - Tooltip with default content
/// - Zoom and pan enabled
/// - Keyboard navigation configured
/// - All callbacks hooked up
///
/// Reference: quickstart.md Example 8
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

class CompleteInteractionExample extends StatefulWidget {
  const CompleteInteractionExample({super.key});

  @override
  State<CompleteInteractionExample> createState() =>
      _CompleteInteractionExampleState();
}

class _CompleteInteractionExampleState
    extends State<CompleteInteractionExample> {
  String statusMessage = 'Hover, tap, zoom, or use keyboard to interact';
  double zoomLevelX = 1.0;
  double zoomLevelY = 1.0;
  Map<String, dynamic>? selectedPoint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example 8: Complete Interaction'),
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: $statusMessage'),
                Text('Zoom: X=${(zoomLevelX * 100).toInt()}%, Y=${(zoomLevelY * 100).toInt()}%'),
                if (selectedPoint != null)
                  Text('Selected: X=${selectedPoint!['x']}, Y=${selectedPoint!['y']}'),
              ],
            ),
          ),
          // Chart
          Expanded(
            child: BravenChart(
              chartType: ChartType.line,
              series: [
                ChartSeries(
                  id: 'revenue',
                  name: 'Revenue',
                  points: List.generate(
                    50,
                    (i) => ChartDataPoint(
                      x: i * 1.0,
                      y: 200 + (i * 5) + (i % 7) * 20,
                    ),
                  ),
                ),
                ChartSeries(
                  id: 'profit',
                  name: 'Profit',
                  points: List.generate(
                    50,
                    (i) => ChartDataPoint(
                      x: i * 1.0,
                      y: 150 + (i * 3) + (i % 5) * 15,
                    ),
                  ),
                ),
              ],
              interactionConfig: InteractionConfig(
                enabled: true,
                // Crosshair configuration
                crosshair: const CrosshairConfig(
                  enabled: true,
                  mode: CrosshairMode.both,
                  snapToDataPoint: true,
                  snapRadius: 25.0,
                  style: CrosshairStyle(
                    lineColor: Color(0xFF2196F3),
                    lineWidth: 1.5,
                    dashPattern: [8, 4],
                  ),
                  showCoordinateLabels: true,
                ),
                // Tooltip configuration
                tooltip: const TooltipConfig(
                  enabled: true,
                  triggerMode: TooltipTriggerMode.both,
                  showDelay: Duration(milliseconds: 200),
                  preferredPosition: TooltipPosition.auto,
                ),
                // Zoom/pan configuration
                enableZoom: true,
                enablePan: true,
                enableSelection: true,
                // Gesture configuration
                gesture: const GestureConfig(
                  tapTimeout: Duration(milliseconds: 200),
                  longPressTimeout: Duration(milliseconds: 500),
                  panThreshold: 10.0,
                ),
                // Keyboard configuration
                keyboard: const KeyboardConfig(
                  enabled: true,
                  panStep: 15.0,
                  zoomStep: 0.15,
                  enableArrowKeys: true,
                  enablePlusMinusKeys: true,
                  enableHomeEndKeys: true,
                ),
                // Callbacks
                onDataPointTap: (point, position) {
                  setState(() {
                    statusMessage = 'Tapped: X=${point.x}, Y=${point.y}';
                    selectedPoint = {'x': point.x, 'y': point.y};
                  });
                },
                onDataPointHover: (point, position) {
                  if (point != null) {
                    setState(() {
                      statusMessage = 'Hovering: X=${point.x}, Y=${point.y}';
                    });
                  }
                },
                onZoomChanged: (zoomX, zoomY) {
                  setState(() {
                    zoomLevelX = zoomX;
                    zoomLevelY = zoomY;
                    statusMessage = 'Zoomed to ${(zoomX * 100).toInt()}%';
                  });
                },
                onPanChanged: (offset) {
                  setState(() {
                    statusMessage = 'Panned: dx=${offset.dx.toStringAsFixed(0)}, dy=${offset.dy.toStringAsFixed(0)}';
                  });
                },
                onKeyboardAction: (action, targetPoint) {
                  setState(() {
                    statusMessage = 'Keyboard: $action';
                  });
                },
              ),
            ),
          ),
          // Instructions
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              'Try: Hover • Tap • Long-press • Zoom (wheel/pinch) • '
              'Pan (drag) • Keyboard (arrows, +/-, home/end)',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
