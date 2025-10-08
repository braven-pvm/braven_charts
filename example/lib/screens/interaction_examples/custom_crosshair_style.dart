// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Example 2: Custom Crosshair Styling
///
/// This example demonstrates how to customize the crosshair appearance with:
/// - Custom color (blue with opacity)
/// - Increased line width (2px instead of default 1px)
/// - Custom dash pattern (10px dash, 5px gap)
/// - Larger snap radius (30px instead of default 20px)
/// - Styled coordinate labels (bold blue text)
///
/// Reference: quickstart.md Example 2
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

class CustomCrosshairStyleExample extends StatelessWidget {
  const CustomCrosshairStyleExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example 2: Custom Crosshair Styling'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Hover to see custom styled crosshair (blue, dashed, thicker)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BravenChart(
                  chartType: ChartType.line,
                  series: [_createSampleSeries()],
                  interactionConfig: InteractionConfig(
                    crosshair: CrosshairConfig(
                      enabled: true,
                      mode: CrosshairMode.both, // Both vertical and horizontal
                      snapToDataPoint: true,
                      snapRadius: 30.0, // Increased snap radius
                      style: CrosshairStyle(
                        lineColor: Colors.blue.withValues(alpha: 0.8),
                        lineWidth: 2.0, // Thicker line
                        dashPattern: const [10, 5], // Custom dash pattern
                        strokeCap: StrokeCap.round,
                      ),
                      showCoordinateLabels: true,
                      coordinateLabelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Expected Behavior:\n'
                '✅ Blue crosshair with 2px width\n'
                '✅ Custom dash pattern (10px dash, 5px gap)\n'
                '✅ Larger snap radius (30px instead of default 20px)\n'
                '✅ Bold blue coordinate labels',
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
      id: 'revenue',
      points: List.generate(
        20,
        (i) => ChartDataPoint(
          x: i * 1.0,
          y: 100 + (i * 10) + (i % 3) * 20,
        ),
      ),
    );
  }
}
