import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  HeatmapChartSeries series(HeatmapColorScale scale) => HeatmapChartSeries(
    id: 'matrix',
    points: [
      HeatmapDataPoint(x: 0, y: 0, value: 10),
      HeatmapDataPoint(x: 1, y: 0, value: 30),
    ],
    colorScale: scale,
  );

  Future<void> pumpLegend(WidgetTester tester, HeatmapColorScale scale) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HeatmapColorLegend(series: series(scale))),
      ),
    );
  }

  testWidgets('continuous legend renders title, range, and midpoint', (
    tester,
  ) async {
    await pumpLegend(
      tester,
      HeatmapColorScale.diverging(
        lowColor: Colors.blue,
        midpointColor: Colors.white,
        highColor: Colors.red,
        midpoint: 20,
        minimumValue: 10,
        maximumValue: 30,
        label: 'Temperature',
        unit: '°C',
      ),
    );

    expect(find.text('Temperature (°C)'), findsOneWidget);
    expect(find.text('10 °C'), findsOneWidget);
    expect(find.text('20 °C'), findsOneWidget);
    expect(find.text('30 °C'), findsOneWidget);
  });

  testWidgets('threshold legend renders named bands', (tester) async {
    await pumpLegend(
      tester,
      HeatmapColorScale.threshold(
        thresholds: const [98, 99.5],
        colors: const [Colors.red, Colors.amber, Colors.green],
        bandLabels: const ['Degraded', 'Watch', 'Healthy'],
        label: 'Availability',
      ),
    );

    expect(find.text('Availability'), findsOneWidget);
    expect(find.text('Degraded'), findsOneWidget);
    expect(find.text('Watch'), findsOneWidget);
    expect(find.text('Healthy'), findsOneWidget);
  });

  testWidgets('legend visibility follows the scale contract', (tester) async {
    await pumpLegend(
      tester,
      HeatmapColorScale.sequential(
        colors: const [Colors.white, Colors.blue],
        label: 'Hidden scale',
        showLegend: false,
      ),
    );

    expect(find.text('Hidden scale'), findsNothing);
    expect(find.byType(SizedBox), findsWidgets);
  });
}
