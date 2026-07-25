import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/radial_bar_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Radial Bar page exposes authored, Workbench, and inspector UI', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RadialBarPage()));
    await tester.pump();

    expect(find.text('Radial Bar Charts'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Signed baseline'), findsOneWidget);
    expect(find.text('Partial target'), findsOneWidget);
    expect(find.text('Dense tracks'), findsOneWidget);
    expect(find.text('Playground'), findsOneWidget);
    expect(find.text('Chart'), findsOneWidget);
    expect(find.text('Data'), findsOneWidget);
    expect(find.text('Split'), findsOneWidget);
    expect(find.text('Source'), findsOneWidget);
    expect(find.byType(PaletteColorOption), findsAtLeastNWidgets(3));

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('radial-bar-chart-0')),
    );
    expect(chart.series.single, isA<RadialBarChartSeries>());
    expect(chart.radialBarChartConfig.thresholds.single.value, 75);
    expect(chart.radialBarChartConfig.pane.sweepAngleDegrees, 360);
    expect(tester.takeException(), isNull);
  });

  testWidgets('authored examples start fresh and Playground randomizes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RadialBarPage()));
    await tester.pump();

    await tester.tap(find.text('Partial target'));
    await tester.pump();
    final partial = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('radial-bar-chart-1')),
    );
    expect(partial.radialBarChartConfig.pane.sweepAngleDegrees, 270);
    expect(partial.radialBarChartConfig.thresholds.single.value, 80);

    await tester.tap(find.text('Playground'));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('radial-bar-randomizer-editor')),
    );
    await tester.pump();
    expect(find.text('Property randomizer'), findsNWidgets(2));
    await tester.tap(find.text('Close'));
    await tester.pump();
    final generated = tester.widget<BravenChartPlus>(
      find.byWidgetPredicate(
        (widget) =>
            widget is BravenChartPlus &&
            widget.key != null &&
            widget.key.toString().contains('radial-bar-chart-'),
      ),
    );
    final generatedSeries = generated.series.single as RadialBarChartSeries;
    expect(generatedSeries.points.length, inInclusiveRange(4, 12));
    expect(tester.takeException(), isNull);
  });
}
