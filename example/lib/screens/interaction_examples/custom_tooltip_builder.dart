// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Example 4: Tooltip with Custom Builder
///
/// This example demonstrates how to provide custom tooltip content with
/// rich formatting. Features:
/// - Custom widget builder with title, icons, and conditional styling
/// - Shows "Above Target" or "Below Target" badge based on value
/// - Blue-themed styling with custom border radius
/// - Positioned at top of data point
///
/// Reference: quickstart.md Example 4
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

class CustomTooltipBuilderExample extends StatelessWidget {
  const CustomTooltipBuilderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example 4: Custom Tooltip Builder'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Hover or tap to see custom tooltip with rich formatting',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BravenChart(
                  chartType: ChartType.line,
                  series: [_createSalesSeries()],
                  interactionConfig: InteractionConfig(
                    crosshair: CrosshairConfig.defaultConfig(),
                    tooltip: TooltipConfig(
                      enabled: true,
                      triggerMode: TooltipTriggerMode.both,
                      showDelay: const Duration(milliseconds: 200),
                      hideDelay: Duration.zero,
                      preferredPosition: TooltipPosition.top,
                      offsetFromPoint: 15.0,
                      style: const TooltipStyle(
                        backgroundColor: Color(0xFFE3F2FD), // blue.shade50
                        borderColor: Color(0xFF2196F3), // blue
                        borderWidth: 2.0,
                        borderRadius: 8.0,
                        padding: 12.0,
                        textColor: Color(0xFF000000),
                        fontSize: 14.0,
                      ),
                      // Custom builder for rich content
                      customBuilder: (context, dataPoint) {
                        final x = dataPoint['x'] as num;
                        final y = dataPoint['y'] as num;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sales Report',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF0D47A1), // blue.shade900
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Color(0xFF757575), // grey
                                ),
                                const SizedBox(width: 4),
                                Text('Day ${x.toInt()}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.attach_money,
                                  size: 16,
                                  color: Color(0xFF4CAF50), // green
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '\$${y.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF388E3C), // green.shade700
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: y > 150
                                    ? const Color(0xFF4CAF50) // green
                                    : const Color(0xFFFF9800), // orange
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                y > 150 ? 'Above Target' : 'Below Target',
                                style: const TextStyle(
                                  color: Color(0xFFFFFFFF), // white
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Expected Behavior:\n'
                '✅ Rich tooltip with title, icons, and conditional styling\n'
                '✅ Shows "Above Target" badge if sales > 150\n'
                '✅ Blue-themed styling with custom border radius\n'
                '✅ Positioned at top of data point',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ChartSeries _createSalesSeries() {
    return ChartSeries(
      id: 'sales',
      name: 'Daily Sales',
      points: const [
        ChartDataPoint(x: 1, y: 120),
        ChartDataPoint(x: 2, y: 165),
        ChartDataPoint(x: 3, y: 145),
        ChartDataPoint(x: 4, y: 180),
        ChartDataPoint(x: 5, y: 130),
        ChartDataPoint(x: 6, y: 155),
      ],
    );
  }
}
