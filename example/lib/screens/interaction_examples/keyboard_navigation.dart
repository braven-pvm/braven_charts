// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Example 7: Keyboard Navigation Setup
///
/// This example demonstrates how to enable keyboard navigation with
/// the current API. Features:
/// - Enable keyboard interaction via KeyboardConfig
/// - Configure pan and zoom steps
/// - Enable/disable specific key groups
/// - Simplified version matching current InteractionConfig API
///
/// Reference: quickstart.md Example 7 (simplified for current API)
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

class KeyboardNavigationExample extends StatefulWidget {
  const KeyboardNavigationExample({super.key});

  @override
  State<KeyboardNavigationExample> createState() => _KeyboardNavigationExampleState();
}

class _KeyboardNavigationExampleState extends State<KeyboardNavigationExample> {
  String lastKeyAction = 'No keyboard actions yet';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example 7: Keyboard Navigation'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Instructions
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.blue.shade50,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keyboard Controls:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Arrow keys: Pan chart (10px steps)'),
                    Text('+/- keys: Zoom in/out (0.1 steps)'),
                    Text('Home/End keys: Jump to start/end'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Last action
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade200,
                child: Text(
                  'Last Action: $lastKeyAction',
                  style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
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
                    keyboard: const KeyboardConfig(
                      enabled: true,
                      panStep: 10.0, // 10 pixels per arrow key press
                      zoomStep: 0.1, // 10% zoom per +/- key press
                      enableArrowKeys: true,
                      enablePlusMinusKeys: true,
                      enableHomeEndKeys: true,
                    ),
                    onKeyboardAction: (action, targetPoint) {
                      setState(() {
                        if (targetPoint != null) {
                          lastKeyAction = '$action -> X=${targetPoint.x}, Y=${targetPoint.y}';
                        } else {
                          lastKeyAction = action;
                        }
                      });
                    },
                    onPanChanged: (offset) {
                      setState(() {
                        lastKeyAction = 'Pan: dx=${offset.dx.toStringAsFixed(1)}, dy=${offset.dy.toStringAsFixed(1)}';
                      });
                    },
                    onZoomChanged: (zoomX, zoomY) {
                      setState(() {
                        lastKeyAction = 'Zoom: ${(zoomX * 100).toInt()}%';
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Expected Behavior:\n'
                '✅ Arrow keys pan the chart\n'
                '✅ +/- keys zoom in/out\n'
                '✅ Home/End jump to boundaries\n'
                '✅ Actions logged to UI',
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
      name: 'Sample Data',
      points: List.generate(
        50,
        (i) => ChartDataPoint(
          x: i * 1.0,
          y: 100 + (i * 2) + (i % 5) * 10,
        ),
      ),
    );
  }
}
