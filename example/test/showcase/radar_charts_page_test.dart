import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/radar_charts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Radar page opens with the authored budget comparison', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RadarChartsPage()));
    await tester.pump();

    expect(find.text('Radar and Spider Charts'), findsOneWidget);
    expect(find.text('Budget vs spending'), findsWidgets);
    expect(find.text('Capability profile'), findsOneWidget);
    expect(find.text('Service health'), findsOneWidget);

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('radar-chart-budget-polygon')),
    );
    expect(chart.series.whereType<RadarChartSeries>(), hasLength(2));
    expect(chart.radarChartConfig.radialAxis.maximum, 100);
    expect(chart.radarChartConfig.radialAxis.gridShape, RadarGridShape.polygon);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Radar authored examples change web and profile composition', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RadarChartsPage()));
    await tester.pump();
    await tester.tap(find.text('Capability profile').first);
    await tester.pump();

    final capability = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('radar-chart-capability-circle')),
    );
    expect(capability.series.whereType<RadarChartSeries>(), hasLength(3));
    expect(
      capability.radarChartConfig.radialAxis.gridShape,
      RadarGridShape.circle,
    );

    await tester.tap(find.text('Service health').first);
    await tester.pump();
    final service = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('radar-chart-service-polygon')),
    );
    final serviceSeries = service.series.whereType<RadarChartSeries>().toList();
    expect(serviceSeries, hasLength(2));
    expect(serviceSeries.first.points, hasLength(8));
    expect(
      serviceSeries.every((series) => series.radarStyle.showDataLabels),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Workbench links Radar rows and exposes Data, Split, and Source',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 950);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: RadarChartsPage()));
      await tester.pumpAndSettle();

      final chart = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('radar-chart-budget-polygon')),
      );
      final controller = chart.bravenChartController!;
      final workbench = tester.widget<BravenChartWorkbench>(
        find.byKey(const ValueKey('radar-workbench')),
      );
      final workbenchController = workbench.workbenchController!;
      final switcher = find.byKey(
        const ValueKey('chart-workbench-mode-switcher'),
      );

      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Data')),
      );
      await tester.pumpAndSettle();

      final model = workbenchController.tableModel!;
      expect(model.xColumnLabel, 'Category');
      expect(model.wideRows, hasLength(6));
      expect(model.wideRows[1].xDisplay, 'Marketing');
      expect(model.wideRows[1].cells, hasLength(2));

      await tester.tap(find.byKey(ValueKey(model.wideRows[1].rowId)));
      await tester.pump();

      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'budget-0', pointIndex: 1),
        const ChartPointRef(seriesId: 'budget-1', pointIndex: 1),
      });
      expect(
        find.text('Selected: Marketing · 2 linked profile values'),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Split')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('chart-workbench-split-handle')),
        findsOne,
      );
      expect(find.byType(BravenChartPlus), findsOne);
      expect(find.byType(ChartDataTable), findsOne);

      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Source')),
      );
      for (var frame = 0; frame < 20; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (workbenchController.generatedSource != null) break;
      }
      expect(
        workbenchController.generatedSource,
        isNotNull,
        reason:
            '${workbenchController.sourceState.phase}: '
            '${workbenchController.sourceState.error?.code} '
            '${workbenchController.sourceState.error?.message} '
            '${workbenchController.sourceState.error?.path}',
      );
      final code = tester.widget<ChartCodeBlock>(find.byType(ChartCodeBlock));
      expect(code.code, contains('.geomRadar('));
      expect(code.code, contains('.radarConfig('));
      expect(code.code, contains('RadarProfileRow'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Radar legend toggles the durable profile ID', (tester) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RadarChartsPage()));
    await tester.pump();

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('radar-chart-budget-polygon')),
    );
    final controller = chart.bravenChartController!;

    expect(find.byKey(const ValueKey('radar-legend')), findsOneWidget);
    await tester.tap(find.text('Allocated budget'));
    await tester.pump();

    expect(controller.hiddenSeriesIds, contains('budget-0'));
    expect(find.text('Allocated budget'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Radar motion controls update, replay, and reduce motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RadarChartsPage()));
    await tester.pump();

    BravenChartPlus chart() => tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('radar-chart-budget-polygon')),
    );

    final initial = chart().series.whereType<RadarChartSeries>().first;
    expect(initial.radarStyle.animationMode, RadarAnimationMode.radial);
    await tester.tap(find.byKey(const ValueKey('radar-update-values')));
    await tester.pump();
    final updated = chart().series.whereType<RadarChartSeries>().first;
    expect(updated.points, isNot(initial.points));
    expect(find.textContaining('update 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('radar-replay-entrance')));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Preview reduced motion'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('radar-reduced-motion-preview')),
      findsOneWidget,
    );
    expect(
      MediaQuery.disableAnimationsOf(
        tester.element(
          find.byKey(const ValueKey('radar-chart-budget-polygon')),
        ),
      ),
      isTrue,
    );
  });
}
