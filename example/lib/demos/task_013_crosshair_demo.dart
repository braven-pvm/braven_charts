// Copyright 2025 Braven Charts
//
// Task 13 Visual Verification Demo: Crosshair Per-Axis Values
//
// This demo verifies that crosshair intersection markers and tracking tooltips
// display correct per-axis values when multi-axis normalization is active.
//
// Expected behavior:
// - Two Y-axes: Power (left, blue) and Heart Rate (right, red)
// - Crosshair markers on each line at the correct Y positions
// - Tooltip shows original values (e.g., "Power: 350 W", "Heart Rate: 150 bpm")
// - NOT normalized/scaled values

import 'package:flutter/material.dart';
import 'package:braven_charts/braven_charts.dart';

void main() => runApp(const Task013CrosshairDemo());

class Task013CrosshairDemo extends StatelessWidget {
  const Task013CrosshairDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // Power series (0-500W range)
    const powerSeries = LineChartSeries(
      id: 'power',
      name: 'Power',
      points: [
        ChartDataPoint(x: 0, y: 100),
        ChartDataPoint(x: 10, y: 180),
        ChartDataPoint(x: 20, y: 220),
        ChartDataPoint(x: 30, y: 300),
        ChartDataPoint(x: 40, y: 280),
        ChartDataPoint(x: 50, y: 350),
        ChartDataPoint(x: 60, y: 320),
        ChartDataPoint(x: 70, y: 380),
        ChartDataPoint(x: 80, y: 420),
        ChartDataPoint(x: 90, y: 400),
        ChartDataPoint(x: 100, y: 450),
      ],
      color: Color(0xFF2196F3), // Blue
      strokeWidth: 2.5,
    );

    // Heart rate series (60-180bpm range)
    const hrSeries = LineChartSeries(
      id: 'heartrate',
      name: 'Heart Rate',
      points: [
        ChartDataPoint(x: 0, y: 80),
        ChartDataPoint(x: 10, y: 95),
        ChartDataPoint(x: 20, y: 110),
        ChartDataPoint(x: 30, y: 125),
        ChartDataPoint(x: 40, y: 135),
        ChartDataPoint(x: 50, y: 150),
        ChartDataPoint(x: 60, y: 145),
        ChartDataPoint(x: 70, y: 160),
        ChartDataPoint(x: 80, y: 165),
        ChartDataPoint(x: 90, y: 170),
        ChartDataPoint(x: 100, y: 175),
      ],
      color: Color(0xFFF44336), // Red
      strokeWidth: 2.5,
    );

    // Y-axis configurations with units
    final yAxes = [
      YAxisConfig(
        id: 'power',
        position: YAxisPosition.left,
        unit: 'W',
        min: 0,
        max: 500,
      ),
      YAxisConfig(
        id: 'heartrate',
        position: YAxisPosition.right,
        unit: 'bpm',
        min: 60,
        max: 180,
      ),
    ];

    // Bind each series to its axis
    const axisBindings = [
      SeriesAxisBinding(seriesId: 'power', yAxisId: 'power'),
      SeriesAxisBinding(seriesId: 'heartrate', yAxisId: 'heartrate'),
    ];

    return MaterialApp(
      title: 'Task 13: Crosshair Per-Axis Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Task 13: Crosshair Per-Axis Values'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visual Verification Checklist:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('✓ Move mouse over chart to see crosshair'),
                      Text('✓ Intersection markers appear on BOTH lines'),
                      Text('✓ Markers are at correct Y positions (not overlapping)'),
                      Text(
                          '✓ Tooltip shows: "Power: [value] W" and "Heart Rate: [value] bpm"'),
                      Text('✓ Values are ORIGINAL (not normalized to 0-1)'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Chart
              Expanded(
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  series: const [powerSeries, hrSeries],
                  yAxes: yAxes,
                  axisBindings: axisBindings,
                  normalizationMode: NormalizationMode.perSeries,
                  interactionConfig: const InteractionConfig(
                    crosshair: CrosshairConfig(
                      enabled: true,
                      mode: CrosshairMode.both,
                      showTrackingTooltip: true,
                      showIntersectionMarkers: true,
                      intersectionMarkerRadius: 6.0,
                      displayMode: CrosshairDisplayMode.tracking,
                    ),
                  ),
                ),
              ),

              // Legend
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle, color: Color(0xFF2196F3), size: 12),
                  SizedBox(width: 4),
                  Text('Power (W) - Left Axis'),
                  SizedBox(width: 24),
                  Icon(Icons.circle, color: Color(0xFFF44336), size: 12),
                  SizedBox(width: 4),
                  Text('Heart Rate (bpm) - Right Axis'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
