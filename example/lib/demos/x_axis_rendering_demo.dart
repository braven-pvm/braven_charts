// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT
//
// X-Axis Rendering Demo
// Demonstrates XAxisConfig features including label/unit display,
// color customization, and crosshair integration.

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

void main() => runApp(const XAxisRenderingDemo());

class XAxisRenderingDemo extends StatelessWidget {
  const XAxisRenderingDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: XAxisConfig is used by XAxisPainter internally.
    // The BravenChartPlus widget currently uses AxisConfig for xAxis parameter.
    final xAxisConfig = const AxisConfig(
      label: 'Time (s)',
      showAxis: true,
      showTicks: true,
      showLabels: true,
      axisColor: Colors.blue,
      
    );

    return MaterialApp(
      title: 'X-Axis Rendering Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('X-Axis Rendering Demo'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'X-Axis Configuration Demo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Demonstrates X-axis with custom label, color, and styling.\n'
                'Blue axis line matches the velocity series color.',
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'velocity',
                      name: 'Velocity',
                      points: _velocitySeries(),
                      color: Colors.blue,
                      unit: 'm/s',
                    ),
                    LineChartSeries(
                      id: 'acceleration',
                      name: 'Acceleration',
                      points: _accelerationSeries(),
                      color: Colors.green,
                      unit: 'm/s²',
                    ),
                  ],
                  xAxis: xAxisConfig,
                  yAxis: YAxisConfig(
                    position: YAxisPosition.left,
                    crosshairLabelPosition: CrosshairLabelPosition.insidePlot,
                    color: Colors.orange,
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
            ],
          ),
        ),
      ),
    );
  }

  static List<ChartDataPoint> _velocitySeries() {
    return List.generate(
      60,
      (i) => ChartDataPoint(
        x: i.toDouble(),
        y: 10 + 5 * (i % 10) / 10,
      ),
    );
  }

  static List<ChartDataPoint> _accelerationSeries() {
    return List.generate(
      60,
      (i) => ChartDataPoint(
        x: i.toDouble(),
        y: 2 + 1.5 * (i % 8) / 8,
      ),
    );
  }
}
