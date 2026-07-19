import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/polar_column_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Polar Column guide renders the real public chart model', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PolarColumnPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Polar Column'), findsOneWidget);
    expect(find.text('Standard columns'), findsOneWidget);
    expect(find.text('Nightingale rose'), findsOneWidget);
    expect(find.text('Partial sweep'), findsOneWidget);
    final chart = tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('polar-column-live-chart')),
        matching: find.byType(BravenChartPlus),
      ),
    );
    expect(chart.series.single, isA<PolarColumnChartSeries>());
    expect(chart.polarChartConfig.pane.sweepAngleDegrees, 360);
    expect(tester.takeException(), isNull);
  });

  testWidgets('presentation cards change the real series and pane contract', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PolarColumnPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const ValueKey('polar-presentation-rose')));
    await tester.pump();
    var chart = tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('polar-column-live-chart')),
        matching: find.byType(BravenChartPlus),
      ),
    );
    expect(
      (chart.series.single as PolarColumnChartSeries).preset,
      PolarColumnPreset.rose,
    );
    expect(
      chart.polarChartConfig.radialAxis.scaleMode,
      PolarRadialScaleMode.areaCorrect,
    );

    await tester.tap(find.byKey(const ValueKey('polar-presentation-partial')));
    await tester.pump();
    chart = tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('polar-column-live-chart')),
        matching: find.byType(BravenChartPlus),
      ),
    );
    expect(chart.polarChartConfig.pane.sweepAngleDegrees, 240);
    expect(chart.polarChartConfig.pane.innerRadiusFactor, 0.28);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Workbench exposes Polar chart, value table, split, and source', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PolarColumnPage())),
    );
    await tester.pumpAndSettle();

    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    expect(switcher, findsOneWidget);

    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Data')),
    );
    await _pumpUntil(
      tester,
      () =>
          tester
              .widget<BravenChartWorkbench>(find.byType(BravenChartWorkbench))
              .workbenchController
              ?.tableModel !=
          null,
    );
    final dataWorkbench = tester.widget<BravenChartWorkbench>(
      find.byType(BravenChartWorkbench),
    );
    expect(
      dataWorkbench.workbenchController?.tableModel,
      isNotNull,
      reason:
          '${dataWorkbench.workbenchController?.tableState.phase}: ${dataWorkbench.workbenchController?.tableState.error?.message}',
    );
    final table = tester.widget<ChartDataTable>(find.byType(ChartDataTable));
    expect(table.model?.projectionKind, ChartTableProjectionKind.polar);
    expect(table.model?.polarRows, hasLength(8));
    expect(table.model?.pieRows, isEmpty);

    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Split')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chart-workbench-split-handle')),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Source')),
    );
    await _pumpUntil(
      tester,
      () =>
          tester
              .widget<BravenChartWorkbench>(find.byType(BravenChartWorkbench))
              .workbenchController
              ?.generatedSource !=
          null,
    );
    final workbench = tester.widget<BravenChartWorkbench>(
      find.byType(BravenChartWorkbench),
    );
    expect(
      workbench.workbenchController?.sourceState.phase,
      ChartWorkbenchSourcePhase.ready,
    );
    final source = workbench.workbenchController?.generatedSource?.source;
    expect(source, contains('PolarColumnChartSeries('));
    expect(source, contains('polarChartConfig: PolarChartConfig('));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 20 && !condition(); attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
