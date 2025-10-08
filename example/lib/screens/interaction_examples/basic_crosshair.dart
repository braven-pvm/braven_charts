// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Example 1: Basic Crosshair Enablement
///
/// This example demonstrates how to enable a crosshair with default settings
/// using just 5 lines of code. The crosshair will:
/// - Follow the mouse cursor on hover
/// - Snap to the nearest data point within 20px
/// - Display both vertical and horizontal lines
/// - Show coordinate labels at the intersection
///
/// Reference: quickstart.md Example 1
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

class BasicCrosshairExample extends StatelessWidget {
  const BasicCrosshairExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example 1: Basic Crosshair'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Hover over the chart to see the crosshair',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BravenChart(
                  chartType: ChartType.line,
                  series: [
                    ChartSeries(
                      id: 'sales',
                      points: const [
                        ChartDataPoint(x: 1, y: 100),
                        ChartDataPoint(x: 2, y: 150),
                        ChartDataPoint(x: 3, y: 120),
                        ChartDataPoint(x: 4, y: 180),
                        ChartDataPoint(x: 5, y: 140),
                      ],
                    ),
                  ],
                  // Enable crosshair with one line
                  interactionConfig: InteractionConfig(
                    crosshair: CrosshairConfig.defaultConfig(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Expected Behavior:\n'
                '✅ Mouse hover shows crosshair following cursor\n'
                '✅ Crosshair snaps to nearest data point within 20px\n'
                '✅ Vertical + horizontal lines displayed\n'
                '✅ Coordinate labels shown at intersection',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
