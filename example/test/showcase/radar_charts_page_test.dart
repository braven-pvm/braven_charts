import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/radar_series_element.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:braven_charts_example/showcase/pages/radar_charts_page.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;
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
    expect(find.text('Product comparison'), findsOneWidget);
    expect(find.text('Normalized scorecard'), findsOneWidget);
    expect(find.text('High contrast'), findsOneWidget);
    expect(find.text('Compact KPI'), findsOneWidget);
    expect(find.text('Risk exposure'), findsOneWidget);
    expect(find.text('Long labels'), findsOneWidget);
    expect(find.text('Dense stress'), findsOneWidget);
    expect(find.text('Playground'), findsOneWidget);

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('radar-chart-budget-polygon')),
    );
    expect(chart.series.whereType<RadarChartSeries>(), hasLength(2));
    expect(chart.radarChartConfig.radialAxis.maximum, 100);
    expect(chart.radarChartConfig.radialAxis.gridShape, RadarGridShape.polygon);
    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    final radarElement = renderBox.debugElements
        .whereType<RadarSeriesElement>()
        .first;
    expect(
      radarElement.pane.outerRadius,
      greaterThanOrEqualTo(100),
      reason:
          'The default desktop workbench must present Radar as a primary chart, '
          'not collapse it into a thumbnail after host and legend chrome.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Radar mobile review recipes reuse the single workbench chart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RadarChartsPage()));
    await tester.pumpAndSettle();

    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(find.byKey(const ValueKey('radar-mobile-examples')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('radar-mobile-example-snapshot')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('radar-mobile-example-touchComparison')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('radar-mobile-example-largeText')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    final openSnapshot = find.byKey(
      const ValueKey('radar-mobile-open-snapshot'),
    );
    await tester.ensureVisible(openSnapshot);
    await tester.pumpAndSettle();
    await tester.tap(openSnapshot);
    await tester.pump();

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('radar-chart-compact-circle')),
    );
    expect(chart.series.whereType<RadarChartSeries>(), hasLength(1));
    expect(chart.showLegend, isFalse);
    expect(
      chart.interactionConfig!.selection.dataPointHitRadius,
      greaterThanOrEqualTo(28),
    );
    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(tester.takeException(), isNull);

    final openTouch = find.byKey(
      const ValueKey('radar-mobile-open-touchComparison'),
    );
    await tester.ensureVisible(openTouch);
    await tester.pumpAndSettle();
    await tester.tap(openTouch);
    await tester.pump();

    final touchChart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('radar-chart-service-polygon')),
    );
    expect(
      touchChart.series.whereType<RadarChartSeries>().every(
        (series) => series.radarStyle.markerRadius >= 5,
      ),
      isTrue,
    );
    expect(
      touchChart.interactionConfig!.selection.dataPointHitRadius,
      greaterThanOrEqualTo(28),
    );
    expect(find.byType(BravenChartPlus), findsOneWidget);

    final openLargeText = find.byKey(
      const ValueKey('radar-mobile-open-largeText'),
    );
    await tester.ensureVisible(openLargeText);
    await tester.pumpAndSettle();
    await tester.tap(openLargeText);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('radar-chart-longLabels-polygon')),
      findsOneWidget,
    );
    expect(
      MediaQuery.textScalerOf(
        tester.element(
          find.byKey(const ValueKey('radar-chart-longLabels-polygon')),
        ),
      ).scale(1),
      1.6,
    );
    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Radar playground randomizes every portable presentation layer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RadarChartsPage()));
    await tester.pump();
    await tester.tap(find.text('Playground'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('radar-randomizer-editor')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('radar-randomizer-editor')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('radar-randomizer-status')),
      findsOneWidget,
    );
    expect(find.text('Inspecting seed 47'), findsOneWidget);

    BravenChartPlus chart() =>
        tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final initialChart = chart();
    final initialValues = initialChart.series
        .whereType<RadarChartSeries>()
        .expand((series) => series.points)
        .map((point) => point.y)
        .toList();
    final profiles = initialChart.series.whereType<RadarChartSeries>().toList();
    expect(profiles.length, inInclusiveRange(2, 6));
    expect(profiles.first.points.length, inInclusiveRange(5, 18));
    expect(initialChart.radarChartConfig.webStyle.ringWidth, isNotNull);
    expect(initialChart.radarChartConfig.webStyle.spokeWidth, isNotNull);
    expect(initialChart.radarChartConfig.webStyle.boundaryWidth, isNotNull);

    await tester.tap(find.byKey(const ValueKey('radar-randomizer-generate')));
    await tester.pump();
    final repeatedValues = chart().series
        .whereType<RadarChartSeries>()
        .expand((series) => series.points)
        .map((point) => point.y)
        .toList();
    expect(repeatedValues, initialValues);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('radar-randomizer-next')));
    await tester.pump();
    expect(find.textContaining('seed 48'), findsOneWidget);
    final nextValues = chart().series
        .whereType<RadarChartSeries>()
        .expand((series) => series.points)
        .map((point) => point.y)
        .toList();
    expect(nextValues, isNot(equals(initialValues)));
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
    expect(
      serviceSeries.every(
        (series) => series.radarStyle.maximumVisibleDataLabels == 12,
      ),
      isTrue,
    );
    expect(
      serviceSeries.every((series) => series.radarStyle.dataLabelOffset == 10),
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

    await tester.scrollUntilVisible(
      find.text('Preview reduced motion'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -160));
    await tester.pumpAndSettle();
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
