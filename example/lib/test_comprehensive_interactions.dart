import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/interaction/models/tooltip_config.dart' as bc;
import 'package:flutter/material.dart' hide TooltipTriggerMode;

/// Comprehensive Interactive Features Test
///
/// Demonstrates:
/// 1. Zoom/Pan - shift+scroll to zoom, middle-mouse to pan, double-tap to reset
/// 2. Crosshair - hover to see crosshair with coordinate labels
/// 3. Tooltips - custom tooltips on data points
/// 4. Multiple Series - Sine and Cosine waves with visual markers
void main() {
  runApp(const ComprehensiveInteractionsTestApp());
}

class ComprehensiveInteractionsTestApp extends StatelessWidget {
  const ComprehensiveInteractionsTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comprehensive Interactive Features Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ComprehensiveInteractionsTestPage(),
    );
  }
}

class ComprehensiveInteractionsTestPage extends StatefulWidget {
  const ComprehensiveInteractionsTestPage({super.key});

  @override
  State<ComprehensiveInteractionsTestPage> createState() => _ComprehensiveInteractionsTestPageState();
}

class _ComprehensiveInteractionsTestPageState extends State<ComprehensiveInteractionsTestPage> {
  final String _lastEvent = 'No events yet';

  // Generate sine wave data
  List<ChartDataPoint> _generateSineData() {
    return List.generate(50, (index) {
      final x = index * 0.2;
      final y = 30 + 20 * Math.sin(x);
      return ChartDataPoint(x: x, y: y);
    });
  }

  // Generate cosine wave data
  List<ChartDataPoint> _generateCosineData() {
    return List.generate(50, (index) {
      final x = index * 0.2;
      final y = 40 + 15 * Math.cos(x);
      return ChartDataPoint(x: x, y: y);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprehensive Interactions Test'),
      ),
      body: Column(
        children: [
          // Info Panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('• Shift + Scroll: Zoom'),
                const Text('• Middle Mouse: Pan'),
                const Text('• Double Tap: Reset'),
                const Text('• Hover: Crosshair & Tooltip'),
                const Divider(),
                Text('Last Event: $_lastEvent'),
              ],
            ),
          ),

          // Chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BravenChart(
                chartType: ChartType.line,
                lineStyle: LineStyle.straight,
                series: [
                  ChartSeries(
                    id: 'sine',
                    name: 'Sine Wave',
                    points: _generateSineData(),
                    color: Colors.blue,
                    style: SeriesStyle.line,
                  ),
                  ChartSeries(
                    id: 'cosine',
                    name: 'Cosine Wave',
                    points: _generateCosineData(),
                    color: Colors.orange,
                    style: SeriesStyle.line,
                  ),
                ],
                xAxis: const AxisConfig(
                  label: 'X Axis',
                  showGrid: true,
                  showAxis: true,
                ),
                yAxis: const AxisConfig(
                  label: 'Y Axis',
                  showGrid: true,
                  showAxis: true,
                  axisPosition: AxisPosition.left,
                ),
                interactionConfig: InteractionConfig(
                  enableZoom: true,
                  enablePan: true,
                  crosshair: const CrosshairConfig(
                    enabled: true,
                    mode: CrosshairMode.both,
                    snapToDataPoint: true,
                    showCoordinateLabels: true,
                  ),
                  tooltip: bc.TooltipConfig(
                    enabled: true,
                    triggerMode: bc.TooltipTriggerMode.hover,
                    preferredPosition: bc.TooltipPosition.auto,
                    customBuilder: (context, dataPoint) {
                      final x = dataPoint['x'] as double?;
                      final y = dataPoint['y'] as double?;
                      final seriesId = dataPoint['seriesId'] as String?;

                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              seriesId ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('X: ${x?.toStringAsFixed(2) ?? "N/A"}'),
                            Text('Y: ${y?.toStringAsFixed(2) ?? "N/A"}'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pure Dart Math implementation
class Math {
  static double sin(double radians) {
    const pi = 3.14159265359;
    double normalized = radians;
    while (normalized > pi) normalized -= 2 * pi;
    while (normalized < -pi) normalized += 2 * pi;

    double result = 0;
    double term = normalized;
    for (int n = 1; n <= 10; n++) {
      result += term;
      term *= -normalized * normalized / ((2 * n) * (2 * n + 1));
    }
    return result;
  }

  static double cos(double radians) {
    const piOver2 = 3.14159265359 / 2;
    return sin(radians + piOver2);
  }
}
