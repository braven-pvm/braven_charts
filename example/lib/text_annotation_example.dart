import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Example demonstrating dual-mode TextAnnotation positioning.
///
/// Shows both:
/// 1. Screen-coordinate mode: Static text that stays in place regardless of zoom/pan
/// 2. Data-coordinate mode: Text anchored to data points that moves with zoom/pan
class TextAnnotationExample extends StatelessWidget {
  const TextAnnotationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TextAnnotation Dual-Mode Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dual-Mode TextAnnotation Demo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Blue text (top-left): Screen-coordinate mode - stays in place when zooming/panning\n'
              '• Red text ("Peak"): Data-coordinate mode - anchored to data point (x=5, y=8), moves with zoom/pan\n'
              '• Green text ("Valley"): Data-coordinate mode - anchored to data point (x=2, y=3)',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BravenChart(
                chartType: ChartType.line,
                series: [
                  ChartSeries(
                    id: 'example-series',
                    name: 'Sample Data',
                    points: [
                      const ChartDataPoint(x: 0, y: 5),
                      const ChartDataPoint(x: 1, y: 6),
                      const ChartDataPoint(x: 2, y: 3), // Valley point
                      const ChartDataPoint(x: 3, y: 7),
                      const ChartDataPoint(x: 4, y: 4),
                      const ChartDataPoint(x: 5, y: 8), // Peak point
                      const ChartDataPoint(x: 6, y: 6),
                      const ChartDataPoint(x: 7, y: 5),
                    ],
                  ),
                ],
                annotations: [
                  // SCREEN-COORDINATE MODE: Static text that stays in place
                  TextAnnotation(
                    id: 'static-label',
                    text: 'Static Text (Screen Coords)',
                    position: const Offset(100, 50), // Fixed screen position
                    backgroundColor: Colors.blue.withOpacity(0.8),
                    borderColor: Colors.blue,
                  ),

                  // DATA-COORDINATE MODE: Text anchored to peak data point
                  TextAnnotation(
                    id: 'peak-label',
                    text: 'Peak (5, 8)',
                    dataX: 5.0, // X data coordinate
                    dataY: 8.0, // Y data coordinate
                    seriesId: 'example-series', // Series containing the point
                    anchor: AnnotationAnchor.bottomCenter, // Position text below the point
                    backgroundColor: Colors.red.withOpacity(0.8),
                    borderColor: Colors.red,
                  ),

                  // DATA-COORDINATE MODE: Text anchored to valley data point
                  TextAnnotation(
                    id: 'valley-label',
                    text: 'Valley (2, 3)',
                    dataX: 2.0, // X data coordinate
                    dataY: 3.0, // Y data coordinate
                    seriesId: 'example-series', // Series containing the point
                    anchor: AnnotationAnchor.topCenter, // Position text above the point
                    backgroundColor: Colors.green.withOpacity(0.8),
                    borderColor: Colors.green,
                  ),
                ],
                xAxis: AxisConfig.defaults().copyWith(showGrid: true),
                yAxis: AxisConfig.defaults().copyWith(showGrid: true),
                interactionConfig: const InteractionConfig(
                  enableZoom: true,
                  enablePan: true,
                  crosshair: CrosshairConfig(enabled: true),
                ),
                showLegend: true,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Try zooming and panning:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text(
              '• Scroll to zoom\n'
              '• Drag to pan\n'
              '• Blue text stays fixed (screen-coordinate mode)\n'
              '• Red & green text move with data (data-coordinate mode)',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
