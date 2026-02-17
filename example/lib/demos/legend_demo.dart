// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Legend Demo: Overlay Legend with LegendStyle
///
/// Demonstrates:
/// - Overlay legend inside chart area
/// - Configurable position via LegendStyle.position
/// - Custom styling (background, border, opacity)
/// - Draggable legend (when allowDragging is true)
void main() => runApp(const LegendDemo());

/// Main demo widget for Legend feature.
class LegendDemo extends StatelessWidget {
  const LegendDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Legend Demo',
      theme: ThemeData.dark(),
      home: const LegendDemoPage(),
    );
  }
}

/// Demo page with legend configuration options.
class LegendDemoPage extends StatefulWidget {
  const LegendDemoPage({super.key});

  @override
  State<LegendDemoPage> createState() => _LegendDemoPageState();
}

class _LegendDemoPageState extends State<LegendDemoPage> {
  LegendPosition _position = LegendPosition.topRight;
  bool _allowDragging = true;
  double _opacity = 0.95;

  @override
  Widget build(BuildContext context) {
    // Sample data for multiple series
    final series1Data = List.generate(
      20,
      (i) => ChartDataPoint(x: i.toDouble(), y: 50 + (i * 3) % 100),
    );
    final series2Data = List.generate(
      20,
      (i) => ChartDataPoint(x: i.toDouble(), y: 30 + (i * 5) % 80),
    );
    final series3Data = List.generate(
      20,
      (i) => ChartDataPoint(x: i.toDouble(), y: 70 + (i * 2) % 60),
    );

    final series = [
      LineChartSeries(
        id: 'power',
        name: 'Power (W)',
        points: series1Data,
        color: Colors.blue,
      ),
      LineChartSeries(
        id: 'heartrate',
        name: 'Heart Rate (bpm)',
        points: series2Data,
        color: Colors.red,
      ),
      LineChartSeries(
        id: 'cadence',
        name: 'Cadence (rpm)',
        points: series3Data,
        color: Colors.green,
      ),
    ];

    // Use mostly defaults to demonstrate no-border, semi-transparent background
    final legendStyle = LegendStyle(
      position: _position,
      allowDragging: _allowDragging,
      opacity: _opacity,
      // No backgroundColor specified - uses default semi-transparent white
      // No borderColor specified - defaults apply
      // borderWidth defaults to 0.0 (no border)
      borderRadius: BorderRadius.circular(6),
      padding: const EdgeInsets.all(10),
      markerShape: LegendMarkerShape.line,
      markerSize: 14,
      // textStyle defaults to black87 for light background
      itemSpacing: 6,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Legend Demo'),
        backgroundColor: Colors.grey[900],
      ),
      body: Column(
        children: [
          // Control panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[850],
            child: Row(
              children: [
                // Position dropdown
                const Text('Position: '),
                DropdownButton<LegendPosition>(
                  value: _position,
                  dropdownColor: Colors.grey[800],
                  items: LegendPosition.values.map((pos) {
                    return DropdownMenuItem(value: pos, child: Text(pos.name));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _position = value);
                  },
                ),
                const SizedBox(width: 24),
                // Dragging toggle
                const Text('Draggable: '),
                Switch(
                  value: _allowDragging,
                  onChanged: (value) => setState(() => _allowDragging = value),
                ),
                const SizedBox(width: 24),
                // Opacity slider
                const Text('Opacity: '),
                SizedBox(
                  width: 150,
                  child: Slider(
                    value: _opacity,
                    min: 0.3,
                    max: 1.0,
                    onChanged: (value) => setState(() => _opacity = value),
                  ),
                ),
                Text(_opacity.toStringAsFixed(2)),
              ],
            ),
          ),
          // Chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: BravenChartPlus(
                series: series,
                showLegend: true,
                legendStyle: legendStyle,
                theme: ChartTheme.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
