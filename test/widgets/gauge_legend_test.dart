import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Gauge uses the native informational radial legend', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 640,
            height: 420,
            child: BravenChartPlus(
              showLegend: true,
              theme: ChartTheme.light.copyWith(
                legendStyle: ChartTheme.light.legendStyle.copyWith(
                  position: LegendPosition.centerRight,
                  orientation: LegendOrientation.vertical,
                  markerShape: LegendMarkerShape.diamond,
                ),
              ),
              series: [
                GaugeChartSeries.solid(
                  id: 'uptime',
                  metric: 'Service uptime',
                  value: 99.93,
                  minimum: 99,
                  maximum: 100,
                  unit: '%',
                  zones: const [
                    GaugeZone(from: 99, to: 99.9, status: 'At risk'),
                    GaugeZone(from: 99.9, to: 100, status: 'Healthy'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('gauge-legend')), findsOneWidget);
    expect(find.text('Service uptime'), findsOneWidget);
    expect(find.textContaining('Healthy'), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
