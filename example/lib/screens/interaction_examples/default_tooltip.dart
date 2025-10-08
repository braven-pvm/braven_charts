// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Example 3: Tooltip with Default Content
///
/// This example demonstrates how to enable a tooltip with default formatting.
/// The tooltip will:
/// - Appear on hover or tap after a 300ms delay
/// - Show series name, X value, and Y value
/// - Position itself automatically to avoid clipping
/// - Display with white background and subtle shadow
///
/// Reference: quickstart.md Example 3
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

class DefaultTooltipExample extends StatelessWidget {
  const DefaultTooltipExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example 3: Tooltip with Default Content'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Hover or tap data points to see tooltip',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BravenChart(
                  chartType: ChartType.line,
                  series: [
                    ChartSeries(
                      id: 'temperature',
                      name: 'Temperature (°F)',
                      points: const [
                        ChartDataPoint(x: 1, y: 72),
                        ChartDataPoint(x: 2, y: 75),
                        ChartDataPoint(x: 3, y: 78),
                        ChartDataPoint(x: 4, y: 76),
                        ChartDataPoint(x: 5, y: 74),
                        ChartDataPoint(x: 6, y: 79),
                      ],
                    ),
                  ],
                  interactionConfig: InteractionConfig(
                    crosshair: CrosshairConfig.defaultConfig(),
                    tooltip: const TooltipConfig(
                      enabled: true,
                      triggerMode: TooltipTriggerMode.both, // Hover or tap
                      showDelay: Duration(milliseconds: 300),
                      hideDelay: Duration.zero,
                      preferredPosition: TooltipPosition.auto, // Smart positioning
                      offsetFromPoint: 10.0,
                      style: TooltipStyle(
                        backgroundColor: Color(0xFFFFFFFF),
                        borderColor: Color(0xFFE0E0E0),
                        borderWidth: 1.0,
                        borderRadius: 4.0,
                        padding: 8.0,
                        textColor: Color(0xFF333333),
                        fontSize: 14.0,
                        shadowColor: Color(0x1A000000),
                        shadowBlurRadius: 4.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Expected Behavior:\n'
                '✅ Tooltip appears 300ms after hover/tap\n'
                '✅ Shows series name, X value, Y value\n'
                '✅ Positioned automatically to avoid clipping\n'
                '✅ White background with subtle shadow',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
