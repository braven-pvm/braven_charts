// Minimal test app for MultiAxisPainter integration
// Run with: flutter run -t lib/multi_axis_test_app.dart -d chrome

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MultiAxisTestApp());
}

class MultiAxisTestApp extends StatelessWidget {
  const MultiAxisTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi-Axis Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MultiAxisTestPage(),
    );
  }
}

class MultiAxisTestPage extends StatelessWidget {
  const MultiAxisTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Simple data series
    final powerSeries = ChartSeries(
      id: 'power',
      name: 'Power',
      points: _generateData(200, 100), // 100-300 range
      color: Colors.blue,
    );

    final hrSeries = ChartSeries(
      id: 'hr',
      name: 'Heart Rate',
      points: _generateData(150, 30), // 120-180 range
      color: Colors.red,
    );

    // Multi-axis config with 2 axes
    final multiAxisConfig = const MultiAxisConfig(
      axes: [
        YAxisConfig(
          id: 'powerAxis',
          position: YAxisPosition.left,
          color: Colors.blue,
          label: 'Power',
          unitSuffix: 'W',
          minValue: 0,
          maxValue: 400,
        ),
        YAxisConfig(
          id: 'hrAxis',
          position: YAxisPosition.right,
          color: Colors.red,
          label: 'HR',
          unitSuffix: 'bpm',
          minValue: 100,
          maxValue: 200,
        ),
      ],
      bindings: [
        SeriesAxisBinding(seriesId: 'power', axisId: 'powerAxis'),
        SeriesAxisBinding(seriesId: 'hr', axisId: 'hrAxis'),
      ],
      mode: NormalizationMode.always,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Axis Integration Test'),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: Container(
        color: const Color(0xFF1E1E1E),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text(
              'Task 10: MultiAxisPainter Integration',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Blue axis (left): Power | Red axis (right): Heart Rate',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                padding: const EdgeInsets.all(16),
                child: BravenChart(
                  series: [powerSeries, hrSeries],
                  multiAxisConfig: multiAxisConfig,
                  chartType: ChartType.line,
                  lineStyle: LineStyle.smooth,
                  theme: ChartTheme.defaultDark,
                  xAxis: const AxisConfig(
                    showAxis: true,
                    showLabels: true,
                    showGrid: true,
                  ),
                  yAxis: const AxisConfig(
                    showAxis: false, // Disable default Y-axis
                    showLabels: false,
                    showGrid: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legend(Colors.blue, 'Power (W)'),
                const SizedBox(width: 32),
                _legend(Colors.red, 'Heart Rate (bpm)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 20, height: 4, color: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  List<ChartDataPoint> _generateData(double base, double amplitude) {
    final points = <ChartDataPoint>[];
    for (var i = 0; i <= 50; i++) {
      final x = i.toDouble();
      // Simple sine-like pattern
      final y = base + amplitude * _wave(i);
      points.add(ChartDataPoint(x: x, y: y));
    }
    return points;
  }

  double _wave(int x) {
    // Simple triangular wave
    final period = 10;
    final pos = x % period;
    if (pos < period / 2) {
      return (pos / (period / 2)) * 2 - 1;
    } else {
      return 1 - ((pos - period / 2) / (period / 2)) * 2;
    }
  }
}

