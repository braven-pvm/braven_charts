// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

// Task 15 Demo: Multi-Axis API with yAxisId on Series
//
// This demo demonstrates the new `yAxisId` field on ChartSeries,
// which enables direct axis binding without needing axisBindings.
import 'package:flutter/material.dart';
import 'package:braven_charts/braven_charts.dart';

void main() => runApp(const Task015ApiDemo());

class Task015ApiDemo extends StatelessWidget {
  const Task015ApiDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // Series with direct yAxisId binding (new feature!)
    final powerSeries = LineChartSeries(
      id: 'power',
      name: 'Power Output',
      points: _generatePowerData(),
      color: Colors.blue,
      yAxisId: 'power-axis', // Direct binding via yAxisId
      unit: 'W',
    );

    final hrSeries = LineChartSeries(
      id: 'heartrate',
      name: 'Heart Rate',
      points: _generateHRData(),
      color: Colors.red,
      yAxisId: 'hr-axis', // Direct binding via yAxisId
      unit: 'bpm',
    );

    return MaterialApp(
      title: 'Task 15: API Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Task 15: yAxisId on Series'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Multi-Axis Chart with Direct Series Binding',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Power (W) on left axis • Heart Rate (bpm) on right axis',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  series: [powerSeries, hrSeries],
                  yAxes: [
                    YAxisConfig(
                      id: 'power-axis',
                      position: YAxisPosition.left,
                      label: 'Power',
                      unit: 'W',
                      color: Colors.blue,
                    ),
                    YAxisConfig(
                      id: 'hr-axis',
                      position: YAxisPosition.right,
                      label: 'Heart Rate',
                      unit: 'bpm',
                      color: Colors.red,
                    ),
                  ],
                  // Note: No axisBindings needed - yAxisId on series handles binding!
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withAlpha(77)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New API Feature:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'series.yAxisId = "power-axis" directly binds the series\n'
                      'to the axis with id="power-axis", no axisBindings needed!',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
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

  List<ChartDataPoint> _generatePowerData() {
    return List.generate(50, (i) {
      // Create a wave pattern for power (150-250W range)
      final wave = (i % 10 < 5) ? i % 10 / 5.0 : (10 - i % 10) / 5.0;
      return ChartDataPoint(
        x: i.toDouble(),
        y: 150 + 100 * wave,
      );
    });
  }

  List<ChartDataPoint> _generateHRData() {
    return List.generate(50, (i) {
      // Create a wave pattern for heart rate (80-120 bpm range)
      final wave = (i % 10 < 5) ? i % 10 / 5.0 : (10 - i % 10) / 5.0;
      return ChartDataPoint(
        x: i.toDouble(),
        y: 80 + 40 * wave,
      );
    });
  }
}
