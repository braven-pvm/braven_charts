// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Example 5: Zoom/Pan Configuration
///
/// This example demonstrates how to enable zoom and pan interactions
/// with the current API. Features:
/// - Enable zoom and pan with simple boolean flags
/// - Monitor zoom level changes via onZoomChanged callback
/// - Display current zoom level to user
/// - Simplified version matching current InteractionConfig API
///
/// Reference: quickstart.md Example 5 (simplified for current API)
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

class ZoomPanConfigExample extends StatefulWidget {
  const ZoomPanConfigExample({super.key});

  @override
  State<ZoomPanConfigExample> createState() => _ZoomPanConfigExampleState();
}

class _ZoomPanConfigExampleState extends State<ZoomPanConfigExample> {
  double currentZoomLevelX = 1.0;
  double currentZoomLevelY = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example 5: Zoom/Pan Configuration'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Zoom X: ${(currentZoomLevelX * 100).toInt()}% | '
                'Zoom Y: ${(currentZoomLevelY * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use mouse wheel to zoom, drag to pan',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BravenChart(
                  chartType: ChartType.line,
                  series: [_createLargeDataset()],
                  interactionConfig: InteractionConfig(
                    crosshair: CrosshairConfig.defaultConfig(),
                    tooltip: TooltipConfig.defaultConfig(),
                    enableZoom: true,
                    enablePan: true,
                    onZoomChanged: (zoomLevelX, zoomLevelY) {
                      setState(() {
                        currentZoomLevelX = zoomLevelX;
                        currentZoomLevelY = zoomLevelY;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Expected Behavior:\n'
                '✅ Mouse wheel zooms in/out\n'
                '✅ Drag to pan across data\n'
                '✅ Zoom level updates in real-time\n'
                '✅ Crosshair and tooltip work while zoomed',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ChartSeries _createLargeDataset() {
    return ChartSeries(
      id: 'data',
      name: 'Large Dataset',
      points: List.generate(
        100,
        (i) => ChartDataPoint(
          x: i * 1.0,
          y: 100 + (i * 2) + ((i % 10) * 15) - ((i % 5) * 8),
        ),
      ),
    );
  }
}

