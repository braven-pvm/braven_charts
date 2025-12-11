// Standalone debug app for bezier + normalization testing
// Run with: flutter run -t lib/demos/bezier_normalization_debug.dart

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BezierNormalizationDebugApp());
}

class BezierNormalizationDebugApp extends StatelessWidget {
  const BezierNormalizationDebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bezier + Normalization Debug',
      theme: ThemeData.light(),
      home: const DebugPage(),
    );
  }
}

class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bezier + Normalization Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Chart 1: Bezier WITHOUT normalization (should work)
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chart 1: Bezier WITHOUT normalization',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const Text('Expected: Smooth curves',
                          style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: BravenChartPlus(
                          series: const [
                            LineChartSeries(
                              id: 'no-norm-1',
                              name: 'Series A',
                              points: [
                                ChartDataPoint(x: 0, y: 10),
                                ChartDataPoint(x: 1, y: 50),
                                ChartDataPoint(x: 2, y: 30),
                                ChartDataPoint(x: 3, y: 70),
                                ChartDataPoint(x: 4, y: 40),
                                ChartDataPoint(x: 5, y: 60),
                              ],
                              color: Colors.blue,
                              interpolation: LineInterpolation.bezier,
                              strokeWidth: 3.0,
                            ),
                          ],
                          theme: ChartTheme.light,
                          showLegend: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Chart 2: Bezier WITH normalization (potentially broken)
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                          'Chart 2: Bezier WITH NormalizationMode.perSeries',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const Text('Expected: Smooth curves (if working)',
                          style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: BravenChartPlus(
                          series: [
                            LineChartSeries(
                              id: 'with-norm-1',
                              name: 'Pressure (1000-1100)',
                              points: const [
                                ChartDataPoint(x: 0, y: 1000),
                                ChartDataPoint(x: 1, y: 1050),
                                ChartDataPoint(x: 2, y: 1020),
                                ChartDataPoint(x: 3, y: 1080),
                                ChartDataPoint(x: 4, y: 1040),
                                ChartDataPoint(x: 5, y: 1100),
                              ],
                              color: Colors.red,
                              interpolation: LineInterpolation.bezier,
                              strokeWidth: 3.0,
                              yAxisConfig: YAxisConfig(
                                position: YAxisPosition.left,
                              ),
                            ),
                            LineChartSeries(
                              id: 'with-norm-2',
                              name: 'Temp (20-35)',
                              points: const [
                                ChartDataPoint(x: 0, y: 20),
                                ChartDataPoint(x: 1, y: 28),
                                ChartDataPoint(x: 2, y: 24),
                                ChartDataPoint(x: 3, y: 32),
                                ChartDataPoint(x: 4, y: 26),
                                ChartDataPoint(x: 5, y: 35),
                              ],
                              color: Colors.orange,
                              interpolation: LineInterpolation.bezier,
                              strokeWidth: 3.0,
                              yAxisConfig: YAxisConfig(
                                position: YAxisPosition.right,
                              ),
                            ),
                          ],
                          normalizationMode: NormalizationMode.perSeries,
                          theme: ChartTheme.light,
                          showLegend: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
