import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  HeatmapChartSeries series(
    HeatmapColorScale scale, {
    HeatmapEmptyValueStyle? emptyValueStyle,
    HeatmapValueFilter? valueFilter,
  }) => HeatmapChartSeries(
    id: 'matrix',
    points: [
      HeatmapDataPoint(x: 0, y: 0, value: 10),
      HeatmapDataPoint(x: 1, y: 0, value: 30),
    ],
    colorScale: scale,
    emptyValueStyle: emptyValueStyle,
    valueFilter: valueFilter,
  );

  Future<void> pumpLegend(
    WidgetTester tester,
    HeatmapColorScale scale, {
    HeatmapEmptyValueStyle? emptyValueStyle,
    HeatmapValueFilter? valueFilter,
    ValueChanged<HeatmapValueFilter?>? onValueFilterChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HeatmapColorLegend(
            series: series(
              scale,
              emptyValueStyle: emptyValueStyle,
              valueFilter: valueFilter,
            ),
            onValueFilterChanged: onValueFilterChanged,
          ),
        ),
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

  testWidgets('legend can identify a styled real empty value', (tester) async {
    await pumpLegend(
      tester,
      HeatmapColorScale.sequential(
        colors: const [Colors.white, Colors.green],
        label: 'Contributions',
      ),
      emptyValueStyle: const HeatmapEmptyValueStyle(
        fillColor: Color(0xFFE5E7EB),
        legendLabel: 'No contributions',
      ),
    );

    expect(find.text('Contributions'), findsOneWidget);
    expect(find.text('No contributions'), findsOneWidget);
  });

  testWidgets('continuous legend publishes and clears a durable value window', (
    tester,
  ) async {
    HeatmapValueFilter? published;
    final scale = HeatmapColorScale.sequential(
      colors: const [Colors.white, Colors.blue],
      minimumValue: 0,
      maximumValue: 40,
      label: 'Latency',
    );
    await pumpLegend(
      tester,
      scale,
      valueFilter: const HeatmapValueFilter(
        minimumValue: 10,
        maximumValue: 30,
        mode: HeatmapValueFilterMode.hide,
        excludedOpacity: 0.2,
      ),
      onValueFilterChanged: (value) => published = value,
    );

    final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
    slider.onChanged!(const RangeValues(12, 28));
    expect(
      published,
      const HeatmapValueFilter(
        minimumValue: 12,
        maximumValue: 28,
        mode: HeatmapValueFilterMode.hide,
        excludedOpacity: 0.2,
      ),
    );

    await tester.tap(find.byTooltip('Clear value filter'));
    expect(published, isNull);
  });

  testWidgets(
    'legend group retains series order, visibility, and filter identity',
    (tester) async {
      final changes = <(String, HeatmapValueFilter?)>[];
      final latency = HeatmapChartSeries(
        id: 'latency',
        name: 'Latency lane',
        points: [HeatmapDataPoint(x: 0, y: 1, value: 42)],
        colorScale: HeatmapColorScale.sequential(
          colors: const [Colors.white, Colors.blue],
          minimumValue: 0,
          maximumValue: 100,
          label: 'Latency',
          unit: 'ms',
        ),
      );
      final errors = HeatmapChartSeries(
        id: 'errors',
        name: 'Error lane',
        points: [HeatmapDataPoint(x: 0, y: 0, value: 2)],
        colorScale: HeatmapColorScale.sequential(
          colors: const [Colors.white, Colors.red],
          minimumValue: 0,
          maximumValue: 5,
          label: 'Errors',
          unit: '%',
        ),
      );
      final hidden = HeatmapChartSeries(
        id: 'hidden',
        name: 'Hidden lane',
        points: [HeatmapDataPoint(x: 0, y: 2, value: 1)],
        colorScale: HeatmapColorScale.sequential(
          colors: const [Colors.white, Colors.green],
          label: 'Hidden',
          showLegend: false,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeatmapColorLegendGroup(
              series: [latency, errors, hidden],
              onValueFilterChanged: (seriesId, filter) {
                changes.add((seriesId, filter));
              },
            ),
          ),
        ),
      );

      expect(find.text('Latency lane'), findsOneWidget);
      expect(find.text('Error lane'), findsOneWidget);
      expect(find.text('Hidden lane'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Latency lane')).dx,
        lessThan(tester.getTopLeft(find.text('Error lane')).dx),
      );

      final sliders = tester.widgetList<RangeSlider>(find.byType(RangeSlider));
      sliders.first.onChanged!(const RangeValues(20, 80));
      sliders.last.onChanged!(const RangeValues(1, 4));

      expect(changes[0].$1, 'latency');
      expect(changes[0].$2?.minimumValue, 20);
      expect(changes[0].$2?.maximumValue, 80);
      expect(changes[1].$1, 'errors');
      expect(changes[1].$2?.minimumValue, 1);
      expect(changes[1].$2?.maximumValue, 4);
      expect(find.bySemanticsLabel('2 Heatmap colour axes'), findsOneWidget);
    },
  );
}
