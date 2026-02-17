// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT
//
// X-Axis Theming Demo
// Demonstrates that X-axis now supports color theming matching Y-axis styling.
// This visual verification shows the unified axis architecture is working correctly.

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

void main() => runApp(const XAxisThemingDemo());

class XAxisThemingDemo extends StatelessWidget {
  const XAxisThemingDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // Define themed X-axis configuration with explicit color
    // This demonstrates X-axis now supports the same theming as Y-axis
    const xAxisConfig = XAxisConfig(
      label: 'Time (s)',
      color: Colors.blue, // Themed color for X-axis
      showAxisLine: true,
      showTicks: true,
      labelDisplay: AxisLabelDisplay.labelWithUnitAndTickUnit,
    );

    return MaterialApp(
      title: 'X-Axis Theming Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('X-Axis Theming Demo'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Descriptive header explaining what this demo shows
              const Text(
                'Themed X-Axis matches Y-Axis styling',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'The X-axis (blue) and Y-axis (green) now both support '
                'explicit color theming through their config objects. '
                'This demonstrates the unified axis architecture.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Chart demonstrating themed axes
              Expanded(
                child: BravenChartPlus(
                  series: [
                    // Single series with sample data
                    LineChartSeries(
                      id: 'temperature',
                      name: 'Temperature',
                      points: _generateTemperatureData(),
                      color: Colors.orange,
                      unit: '°C',
                    ),
                  ],
                  xAxisConfig: xAxisConfig,
                  // Y-axis with contrasting themed color for visual comparison
                  yAxis: YAxisConfig(
                    position: YAxisPosition.left,
                    label: 'Value',
                    color: Colors.green, // Different color to show theming
                  ),
                  normalizationMode: NormalizationMode.none,
                  interactionConfig: const InteractionConfig(
                    crosshair: CrosshairConfig(
                      enabled: true,
                      mode: CrosshairMode.both,
                      showTrackingTooltip: true,
                      displayMode: CrosshairDisplayMode.tracking,
                    ),
                    tooltip: TooltipConfig(enabled: true),
                  ),
                ),
              ),

              // Footer explaining the color scheme
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Color Theming:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(width: 16, height: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text('X-Axis (Time) - Blue'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(width: 16, height: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text('Y-Axis (Value) - Green'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(width: 16, height: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text('Series (Temperature) - Orange'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Generates sample temperature data for demonstration.
  ///
  /// Creates a sinusoidal pattern showing temperature variation over time.
  List<ChartDataPoint> _generateTemperatureData() {
    return List.generate(
      50,
      (i) => ChartDataPoint(x: i.toDouble(), y: 20 + 10 * (i % 20) / 20),
    );
  }
}
