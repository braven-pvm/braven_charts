/// Simple zoom test screen to isolate and debug zoom functionality.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

class SimpleZoomTestScreen extends StatelessWidget {
  const SimpleZoomTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Zoom Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎯 Zoom Test Instructions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Text('1. Click on the chart to give it focus'),
                    Text('2. Press Numpad +/- to zoom'),
                    Text('3. Hold SHIFT and scroll mouse wheel to zoom'),
                    SizedBox(height: 8),
                    Text(
                      '📊 Watch the console for debug output',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BravenChart(
                    chartType: ChartType.line,
                    series: [
                      ChartSeries(
                        id: 'test-data',
                        name: 'Test Data',
                        points: _generateSimpleData(),
                      ),
                    ],
                    interactionConfig: InteractionConfig(
                      // Enable zoom
                      enableZoom: true,
                      // Enable keyboard
                      keyboard: const KeyboardConfig(enabled: true),
                      // Zoom callback to see changes
                      onZoomChanged: (zoomX, zoomY) {
                        print('📊 ZOOM CHANGED: X=${(zoomX * 100).toInt()}%, Y=${(zoomY * 100).toInt()}%');
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Generate simple test data.
  List<ChartDataPoint> _generateSimpleData() {
    final points = <ChartDataPoint>[];
    for (int i = 0; i < 20; i++) {
      points.add(
        ChartDataPoint(
          x: i.toDouble(),
          y: 50 + (i * 5) - (i * i * 0.2), // Simple parabola
        ),
      );
    }
    return points;
  }
}
