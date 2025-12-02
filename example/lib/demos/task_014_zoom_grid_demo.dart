// Task 014 Demo: Y-Zoom & Grid Line Constraints in Multi-Axis Mode
//
// This demo demonstrates:
// 1. Multi-axis mode: No horizontal grid lines, Y-zoom disabled, X-zoom works
// 2. Single-axis mode: Grid lines visible, both X and Y zoom work
//
// Use the toggle switch in the app bar to switch between modes.

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

void main() => runApp(const Task014Demo());

class Task014Demo extends StatefulWidget {
  const Task014Demo({super.key});

  @override
  State<Task014Demo> createState() => _Task014DemoState();
}

class _Task014DemoState extends State<Task014Demo> {
  bool _multiAxisMode = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task 014: Y-Zoom & Grid Constraints',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Task 014: Y-Zoom & Grid Constraints'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Text(
                    _multiAxisMode ? 'Multi-Axis' : 'Single-Axis',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: _multiAxisMode,
                    onChanged: (v) => setState(() => _multiAxisMode = v),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  series: _multiAxisMode
                      // Multi-axis mode: series with inline yAxisConfig
                      ? [
                          LineChartSeries(
                            id: 'power',
                            points: List.generate(
                              50,
                              (i) => ChartDataPoint(
                                x: i.toDouble(),
                                y: 200 + 100 * (i % 10 / 10) + 50 * (i ~/ 10),
                              ),
                            ),
                            color: Colors.blue,
                            yAxisConfig: YAxisConfig(
                              id: 'power',
                              position: YAxisPosition.left,
                              label: 'Power',
                              unit: 'W',
                              color: Colors.blue,
                            ),
                          ),
                          LineChartSeries(
                            id: 'heart-rate',
                            points: List.generate(
                              50,
                              (i) => ChartDataPoint(
                                x: i.toDouble(),
                                y: 100 + 40 * ((i + 3) % 10 / 10) + 20 * (i ~/ 10),
                              ),
                            ),
                            color: Colors.red,
                            yAxisConfig: YAxisConfig(
                              id: 'heart-rate',
                              position: YAxisPosition.right,
                              label: 'Heart Rate',
                              unit: 'bpm',
                              color: Colors.red,
                            ),
                          ),
                        ]
                      // Single-axis mode: series without axis config (uses default)
                      : [
                          LineChartSeries(
                            id: 'power',
                            points: List.generate(
                              50,
                              (i) => ChartDataPoint(
                                x: i.toDouble(),
                                y: 200 + 100 * (i % 10 / 10) + 50 * (i ~/ 10),
                              ),
                            ),
                            color: Colors.blue,
                          ),
                          LineChartSeries(
                            id: 'heart-rate',
                            points: List.generate(
                              50,
                              (i) => ChartDataPoint(
                                x: i.toDouble(),
                                y: 100 + 40 * ((i + 3) % 10 / 10) + 20 * (i ~/ 10),
                              ),
                            ),
                            color: Colors.red,
                          ),
                        ],
                  yAxes: _multiAxisMode
                      ? null // Axes auto-detected from series.yAxisConfig
                      : [
                          YAxisConfig(
                            id: 'default',
                            position: YAxisPosition.left,
                          ),
                        ],
                ),
              ),
            ),
            Container(
              color: Colors.grey[200],
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _multiAxisMode ? '✓ Multi-axis mode active:' : '✓ Single-axis mode active:',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _multiAxisMode
                        ? '• No horizontal grid lines (each axis has different scale)\n'
                            '• Y-zoom disabled (would break per-axis normalization)\n'
                            '• Y-pan disabled (would break per-axis normalization)\n'
                            '• X-zoom still works (Shift + scroll wheel)'
                        : '• Horizontal grid lines visible\n'
                            '• Both X and Y zoom work (Shift + scroll wheel)\n'
                            '• Both X and Y pan work (middle mouse button drag)',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
