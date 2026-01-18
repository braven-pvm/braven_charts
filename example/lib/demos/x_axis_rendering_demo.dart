// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT
//
// X-Axis Rendering Demo
// Demonstrates the new XAxisConfig-based rendering pipeline with
// per-series axis configuration and crosshair labeling.

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

void main() => runApp(const XAxisRenderingDemo());

class XAxisRenderingDemo extends StatelessWidget {
  const XAxisRenderingDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final timeAxis = XAxisConfig(
      id: 'time-bottom',
      position: XAxisPosition.bottom,
      label: 'Time',
      unit: 's',
      showCrosshairLabel: true,
      labelDisplay: AxisLabelDisplay.labelWithUnit,
      color: Colors.red,
    );

    final phaseAxis = XAxisConfig(
      id: 'phase-top',
      position: XAxisPosition.top,
      label: 'Phase',
      unit: 'deg',
      showCrosshairLabel: true,
      labelDisplay: AxisLabelDisplay.labelWithUnit,
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
                'New XAxisConfig pipeline with per-series axis selection',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Blue series uses the bottom time axis. Green series binds to\n'
                'the top phase axis to demonstrate multi-axis X rendering.',
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
                      xAxisConfig: timeAxis,
                    ),
                    LineChartSeries(
                      id: 'phase',
                      name: 'Phase',
                      points: _phaseSeries(),
                      color: Colors.green,
                      unit: 'deg',
                      xAxisConfig: phaseAxis,
                    ),
                  ],
                  xAxisConfig: timeAxis,
                  yAxis: YAxisConfig(
                    position: YAxisPosition.left,
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

  List<ChartDataPoint> _velocitySeries() {
    return List.generate(
      60,
      (i) => ChartDataPoint(
        x: i.toDouble(),
        y: 20 + 8 * (i % 12) / 12,
      ),
    );
  }

  List<ChartDataPoint> _phaseSeries() {
    return List.generate(
      60,
      (i) => ChartDataPoint(
        x: i.toDouble(),
        y: (i * 6).toDouble(),
      ),
    );
  }
}
