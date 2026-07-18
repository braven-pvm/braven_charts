import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/pie_charts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showcases live pie datasets and public usage guidance', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PieChartsPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Pie Charts'), findsOneWidget);
    expect(find.text('Choose a presentation'), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-preset-simple')), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-preset-editorial')), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-preset-compact')), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-preset-elevated')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pie-preset-highContrast')),
      findsOneWidget,
    );
    expect(find.text('Choose a category story'), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-showcase-chart')), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-dataset-revenue')), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-dataset-effort')), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-dataset-support')), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-dataset-countries')), findsOneWidget);
    expect(find.text('Try slice interaction'), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-legend-item-0')), findsOneWidget);
    final initialChart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('pie-showcase-chart')),
    );
    final initialSeries = initialChart.series.single as PieChartSeries;
    expect(
      initialSeries.pieStyle.dataTransitionMode,
      RadialDataTransitionMode.automatic,
    );
    expect(initialSeries.dataLabels.valueFormatter, isNotNull);
    expect(initialSeries.dataLabels.percentageFormatter, isNotNull);
    expect(initialSeries.pieStyle.gradient?.type, PieGradientType.radial);
    expect(initialSeries.pieStyle.cornerTreatment, PieCornerTreatment.roundAll);
    expect(initialChart.interactionConfig?.showFocusBorder, isFalse);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('pie-preset-compact')));
    await tester.pump(const Duration(milliseconds: 300));

    final compactChart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('pie-showcase-chart')),
    );
    expect(compactChart.radialLegendItemBuilder, isNotNull);
    expect(
      find.byKey(const ValueKey('pie-custom-legend-item-0')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('pie-preset-simple')));
    await tester.pump(const Duration(milliseconds: 300));

    final simpleChart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('pie-showcase-chart')),
    );
    final simpleSeries = simpleChart.series.single as PieChartSeries;
    expect(simpleChart.showLegend, isFalse);
    expect(simpleChart.theme?.backgroundColor, const Color(0xFF1F1F1F));
    expect(simpleSeries.dataLabels.position, PieDataLabelPosition.inside);
    expect(simpleSeries.dataLabels.content, PieDataLabelContent.value);
    expect(simpleSeries.dataLabels.minimumShare, 0.2);
    expect(simpleSeries.pieStyle.gradient?.type, PieGradientType.linear);
    expect(simpleSeries.pieStyle.cornerTreatment, PieCornerTreatment.outerOnly);
    expect(
      simpleChart.theme?.pieChartTheme.calloutStyle?.textStyle.color,
      const Color(0xFFFFFFFF),
    );
    expect(
      simpleChart.theme?.pieChartTheme.calloutStyle?.backgroundColor,
      const Color(0x00000000),
    );

    await tester.tap(find.byKey(const ValueKey('pie-preset-highContrast')));
    await tester.pump(const Duration(milliseconds: 300));

    final highContrastChart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('pie-showcase-chart')),
    );
    final highContrastSeries =
        highContrastChart.series.single as PieChartSeries;
    final highContrastCallout =
        highContrastChart.theme?.pieChartTheme.calloutStyle;
    expect(
      highContrastSeries.dataLabels.position,
      PieDataLabelPosition.outside,
    );
    expect(
      highContrastSeries.dataLabels.collisionStrategy,
      PieDataLabelCollisionStrategy.shiftAndHide,
    );
    expect(highContrastSeries.dataLabels.outsideOffset, 0);
    expect(highContrastSeries.pieStyle.gradient, isNull);
    expect(
      highContrastSeries.pieStyle.cornerTreatment,
      PieCornerTreatment.circularCenter,
    );
    expect(
      highContrastCallout?.backgroundColor.toARGB32(),
      const Color(0xFFFFFFFF).toARGB32(),
    );
    expect(
      highContrastCallout?.textStyle.color?.toARGB32(),
      const Color(0xFF1A1A1A).toARGB32(),
    );
    expect(highContrastCallout?.borderWidth, 2);

    await tester.tap(find.byKey(const ValueKey('pie-preset-elevated')));
    await tester.pump(const Duration(milliseconds: 300));

    final elevatedChart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('pie-showcase-chart')),
    );
    final elevatedSeries = elevatedChart.series.single as PieChartSeries;
    expect(elevatedSeries.pieStyle.sliceGap, 7);
    expect(elevatedSeries.pieStyle.cornerRadius, isNull);
    expect(elevatedSeries.dataLabels.position, PieDataLabelPosition.outside);
    expect(elevatedSeries.dataLabels.outsideOffset, 12);
    expect(elevatedSeries.pieStyle.gradient?.type, PieGradientType.radial);
    expect(elevatedChart.theme?.pieChartTheme.cornerRadius, 14);
    expect(
      elevatedChart.theme?.pieChartTheme.cornerTreatment,
      PieCornerTreatment.circularCenter,
    );
    expect(elevatedChart.theme?.pieChartTheme.shadow.isVisible, isTrue);
    expect(elevatedChart.theme?.pieChartTheme.opacity, 0.94);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('pie-legend-item-0')),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('pie-showcase-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const ValueKey('pie-legend-item-0')));
    await tester.pumpAndSettle();

    expect(find.text('Selected: Subscriptions'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('pie-dataset-support')),
      -500,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('pie-showcase-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const ValueKey('pie-dataset-support')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Requests by topic'), findsOneWidget);
    expect(find.textContaining('8 categories'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 2));
    tester
        .widget<ElevatedButton>(
          find.byKey(const ValueKey('regenerate-pie-values')),
        )
        .onPressed!();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('tickets total'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('pie-dataset-countries')));
    await _settleCapture(tester);

    final variableChart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('pie-showcase-chart')),
    );
    final variableSeries = variableChart.series.single as PieChartSeries;
    expect(variableSeries.hasVariableSliceRadius, isTrue);
    expect(variableSeries.sliceRadiusConfig?.label, 'Total area');
    expect(variableSeries.sliceRadiusConfig?.unit, 'km²');
    expect(variableSeries.points.first.pointStyle?.size, isNotNull);
    expect(find.text('Smallest slice radius'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('pie-display-mode')),
        matching: find.text('Split'),
      ),
    );
    await _settleCapture(tester);
    final variableTable = tester.widget<ChartDataTable>(
      find.byKey(const ValueKey('chart-workbench-data-table')),
    );
    expect(variableTable.model?.pieRadiusColumnLabel, 'Total area (km²)');
    expect(find.text('Total area (km²)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the pie showcase usable at a narrow viewport', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(390 * pixelRatio, 844 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PieChartsPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Options'), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-showcase-scroll')), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-showcase-chart')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pie-presentation-selector')),
      findsOneWidget,
    );
    expect(
      tester
          .getRect(find.byKey(const ValueKey('chart-page-options-button')))
          .right,
      lessThanOrEqualTo(390),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('pie-showcase-card'))).right,
      lessThanOrEqualTo(390),
    );

    await tester.tap(find.byKey(const ValueKey('chart-page-options-button')));
    await tester.pumpAndSettle();
    expect(find.text('Chart options'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('auto-fits and resizes the native Pie Split surface', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PieChartsPage())),
    );
    await _settleCapture(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('pie-display-mode')),
        matching: find.text('Split'),
      ),
    );
    await _settleCapture(tester);

    final chartFinder = find.byKey(const ValueKey('pie-showcase-chart'));
    final tableFinder = find.byKey(
      const ValueKey('chart-workbench-data-table'),
    );
    final handleFinder = find.byKey(
      const ValueKey('chart-workbench-split-handle'),
    );
    final initialChartWidth = tester.getSize(chartFinder).width;
    final initialTableWidth = tester.getSize(tableFinder).width;

    expect(initialChartWidth, greaterThan(initialTableWidth));
    await tester.drag(handleFinder, const Offset(120, 0));
    await tester.pumpAndSettle();
    expect(tester.getSize(chartFinder).width, greaterThan(initialChartWidth));
    expect(tester.getSize(tableFinder).width, lessThan(initialTableWidth));

    await tester.tap(handleFinder);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(tester.getSize(chartFinder).width, closeTo(initialChartWidth, 0.1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('replays each public Pie entrance mode without remounting', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PieChartsPage())),
    );
    await tester.pumpAndSettle();

    final animationOption = find.byKey(const ValueKey('pie-animation-mode'));
    await tester.scrollUntilVisible(
      animationOption,
      400,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final dropdown = find.descendant(
      of: animationOption,
      matching: find.byType(DropdownButtonFormField<PieAnimationMode>),
    );
    tester
        .widget<DropdownButtonFormField<PieAnimationMode>>(dropdown)
        .onChanged!(PieAnimationMode.sweep);
    await tester.pumpAndSettle();

    final chartBeforeReplay = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('pie-showcase-chart')),
    );
    expect(
      chartBeforeReplay.theme?.pieChartTheme.animationMode,
      PieAnimationMode.sweep,
    );

    await tester.tap(find.byKey(const ValueKey('replay-pie-entrance')));
    await tester.pump();

    expect(tester.hasRunningAnimations, isTrue);
    expect(
      tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('pie-showcase-chart')),
      ),
      same(chartBeforeReplay),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'groups small Pie slices while retaining and linking source table rows',
    (tester) async {
      tester.view.physicalSize = const Size(1800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PieChartsPage())),
      );
      await tester.pumpAndSettle();

      final groupingOption = find.byKey(
        const ValueKey('pie-group-small-slices'),
      );
      await tester.scrollUntilVisible(
        groupingOption,
        400,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      tester
          .widget<Switch>(
            find.descendant(of: groupingOption, matching: find.byType(Switch)),
          )
          .onChanged!(true);
      await tester.pumpAndSettle();

      final chart = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('pie-showcase-chart')),
      );
      final series = chart.series.single as PieChartSeries;
      expect(series.points, hasLength(5));
      expect(series.visibleSlices, hasLength(4));
      expect(series.visibleSlices.last.point.label, 'Other');
      expect(series.visibleSlices.last.sourcePointIndices, [3, 4]);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('pie-display-mode')),
          matching: find.text('Split'),
        ),
      );
      await _settleCapture(tester);

      var table = tester.widget<ChartDataTable>(
        find.byKey(const ValueKey('chart-workbench-data-table')),
      );
      expect(table.model?.pieRows, hasLength(5));
      expect(
        table.model?.pieRows.map((row) => row.category),
        containsAll(<String>['Training', 'Other']),
      );

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('chart-workbench-data-table')),
          matching: find.text('Training'),
        ),
      );
      await tester.pumpAndSettle();

      table = tester.widget<ChartDataTable>(
        find.byKey(const ValueKey('chart-workbench-data-table')),
      );
      expect(table.selectedPointRefs, {
        const ChartPointRef(seriesId: 'pie-showcase-revenue', pointIndex: 3),
        const ChartPointRef(seriesId: 'pie-showcase-revenue', pointIndex: 4),
      });
      expect(find.text('Selected: Other'), findsOneWidget);
      expect(find.textContaining('all 2 original source rows'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows native pie data and restores a captured artifact', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PieChartsPage())),
    );
    await _settleCapture(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('pie-display-mode')),
        matching: find.text('Split'),
      ),
    );
    await _settleCapture(tester);
    final initialTable = tester.widget<ChartDataTable>(
      find.byKey(const ValueKey('chart-workbench-data-table')),
    );
    expect(initialTable.model?.projectionKind, ChartTableProjectionKind.pie);
    expect(initialTable.model?.pieRows.first.category, 'Subscriptions');
    expect(initialTable.model?.pieRows.first.shareDisplay, '42.00%');
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Value (USD)'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);

    final hardwareCell = find.descendant(
      of: find.byKey(const ValueKey('chart-workbench-data-table')),
      matching: find.text('Hardware'),
    );
    await tester.tap(hardwareCell);
    await tester.pumpAndSettle();
    expect(find.text('Selected: Hardware'), findsOneWidget);
    final selectedTable = tester.widget<ChartDataTable>(
      find.byKey(const ValueKey('chart-workbench-data-table')),
    );
    expect(selectedTable.selectedPointRefs, {
      const ChartPointRef(seriesId: 'pie-showcase-revenue', pointIndex: 2),
    });
    expect(
      find.semantics.byLabel(
        'Hardware, 16.0 USD, 16 percent, slice 3 of 5, selected',
      ),
      findsOne,
    );

    await tester.tap(hardwareCell);
    await tester.pumpAndSettle();
    expect(find.text('Try slice interaction'), findsOneWidget);
    expect(
      tester
          .widget<ChartDataTable>(
            find.byKey(const ValueKey('chart-workbench-data-table')),
          )
          .selectedPointRefs,
      isEmpty,
    );
    semantics.dispose();

    final scrollable = find
        .descendant(
          of: find.byKey(const ValueKey('pie-showcase-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('capture-pie-artifact')),
      500,
      scrollable: scrollable,
    );
    await tester.tap(find.byKey(const ValueKey('capture-pie-artifact')));
    await _settleCapture(tester);

    expect(find.text('series.pie'), findsOneWidget);
    expect(find.text('series.pie.style.v2'), findsOneWidget);
    expect(find.text('series.pie.corner-treatment.v1'), findsOneWidget);
    expect(find.text('Schema 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Captured pie chart preview'), findsOneWidget);
    expect(find.text('Restore captured chart'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('restore-pie-artifact')));
    await tester.pump();
    expect(find.byKey(const ValueKey('restored-pie-artifact')), findsOneWidget);
    expect(
      find.text('Restored from canonical JSON into a fresh chart runtime'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _settleCapture(WidgetTester tester) async {
  for (var index = 0; index < 8; index++) {
    await tester.pump();
  }
  // Advance zero-delay extraction and the bounded revision refresh timer
  // without waiting for the showcase's intentionally replayable animation.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}
