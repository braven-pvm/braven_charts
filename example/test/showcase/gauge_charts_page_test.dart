import 'dart:ui' show PointerDeviceKind;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/gauge_charts_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Gauge page exposes authored, Workbench, and inspector UI', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: GaugeChartsPage()));
    await tester.pump();

    expect(find.text('Gauge Charts'), findsOneWidget);
    for (final label in [
      'Needle',
      'Solid',
      'Zones',
      'Target',
      'Partial sweep',
      'Accessible',
      'Density',
      'Playground',
    ]) {
      expect(find.text(label), findsWidgets);
    }
    for (final mode in ['Chart', 'Data', 'Split', 'Source']) {
      expect(find.text(mode), findsOneWidget);
    }
    expect(find.byType(PaletteColorOption), findsWidgets);

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('gauge-chart-0')),
    );
    final series = chart.series.single as GaugeChartSeries;
    expect(series.indicatorStyle, isA<NeedleGaugeStyle>());
    expect(series.status, 'Elevated');
    expect(chart.gaugeChartConfig.pane.sweepAngleDegrees, 270);
    expect(tester.takeException(), isNull);
  });

  testWidgets('authored examples start fresh and Playground randomizes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: GaugeChartsPage()));
    await tester.pump();

    await tester.tap(find.text('Solid').first);
    await tester.pump();
    final solid = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('gauge-chart-1')),
    );
    expect(
      (solid.series.single as GaugeChartSeries).indicatorStyle,
      isA<SolidGaugeStyle>(),
    );
    expect((solid.series.single as GaugeChartSeries).minimum, 99);

    await tester.tap(find.text('Playground').first);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('gauge-randomizer-editor')));
    await tester.pump();
    expect(find.text('Property randomizer'), findsNWidgets(2));
    await tester.tap(find.text('Close'));
    await tester.pump();
    final generated = tester.widget<BravenChartPlus>(
      find.byWidgetPredicate(
        (widget) =>
            widget is BravenChartPlus &&
            widget.key != null &&
            widget.key.toString().contains('gauge-chart-'),
      ),
    );
    final generatedSeries = generated.series.single as GaugeChartSeries;
    expect(generatedSeries.value, inInclusiveRange(0, generatedSeries.maximum));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Gauge page remains usable at tablet width with touch input', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: GaugeChartsPage()));
    await tester.pump();

    final solidChoice = find.text('Solid').first;
    await tester.ensureVisible(solidChoice);
    final touch = await tester.startGesture(
      tester.getCenter(solidChoice),
      kind: PointerDeviceKind.touch,
    );
    await touch.up();
    await tester.pump();

    final solid = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('gauge-chart-1')),
    );
    expect(
      (solid.series.single as GaugeChartSeries).indicatorStyle,
      isA<SolidGaugeStyle>(),
    );
    expect(find.byKey(const ValueKey('gauge-showcase-scroll')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
