// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/widgets/pie_chart_legend.dart';
import 'package:braven_charts_example/showcase/pages/donut_charts_page.dart';
import 'package:braven_charts_example/showcase/widgets/radial_legend_value_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'generates current Donut configuration in the shared Source view',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DonutChartsPage())),
      );
      await tester.pumpAndSettle();

      final switcher = find.byKey(
        const ValueKey('chart-workbench-mode-switcher'),
      );
      final sourceMode = find.descendant(
        of: switcher,
        matching: find.text('Source'),
      );
      await tester.ensureVisible(sourceMode);
      await tester.pump();
      await tester.tap(sourceMode);
      await tester.pumpAndSettle();

      final workbench = tester.widget<BravenChartWorkbench>(
        find.byType(BravenChartWorkbench),
      );
      expect(
        workbench.workbenchController!.sourceState.phase,
        ChartWorkbenchSourcePhase.ready,
      );
      expect(
        workbench.workbenchController!.generatedSource!.source,
        allOf(
          contains('final donutChart = BravenChartPlus('),
          contains('DonutChartSeries('),
        ),
      );
      expect(find.byType(ChartSourceView), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows Donut stories and the chart, data, split workflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DonutChartsPage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Donut Charts'), findsOneWidget);
    expect(find.text('Contribution ring'), findsOneWidget);
    expect(find.text('Partial sweep'), findsOneWidget);
    expect(find.text('Variable radius'), findsOneWidget);
    expect(find.text('Grouped sources'), findsWidgets);
    expect(find.text('Center content'), findsOneWidget);
    expect(find.text('Motion'), findsOneWidget);
    expect(find.text('Grow in'), findsOneWidget);
    expect(find.text('Selected or total'), findsWidgets);
    expect(
      find.byKey(const ValueKey('chart-workbench-mode-switcher')),
      findsOneWidget,
    );
    expect(find.text('Source'), findsOneWidget);
    expect(find.byKey(const ValueKey('donut-showcase-chart')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chart-workbench-data-table')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('chart-workbench-split-handle')),
      findsOneWidget,
    );
    expect(find.byType(BravenChartPlus), findsOneWidget);
    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('donut-showcase-chart')),
    );
    final series = chart.series.single as DonutChartSeries;
    expect(
      series.donutStyle.dataTransitionMode,
      RadialDataTransitionMode.automatic,
    );
    expect(series.dataLabels.valueFormatter, isNotNull);
    expect(series.dataLabels.percentageFormatter, isNotNull);
    expect(series.centerContent.valueFormatter, isNotNull);
  });

  testWidgets('shows a host-built interactive Donut center', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DonutChartsPage())),
    );
    await tester.pumpAndSettle();

    final centerStyle = find.byKey(const ValueKey('donut-center-style'));
    await tester.ensureVisible(centerStyle);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: centerStyle, matching: find.text('Theme default')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom widget + action').last);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('donut-showcase-chart')),
    );
    expect(chart.donutCenterBuilder, isNotNull);
    expect(chart.onDonutCenterTap, isNotNull);
    expect(find.text('Center actions: 0'), findsOneWidget);

    await tester.tap(find.text('Center actions: 0'));
    await tester.pumpAndSettle();
    expect(find.text('Center actions: 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('auto-fits and resizes the native Donut Split surface', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DonutChartsPage())),
    );
    await tester.pumpAndSettle();

    final chartFinder = find.byKey(const ValueKey('donut-showcase-chart'));
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

  testWidgets('switching stories updates live Donut geometry', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DonutChartsPage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('360° sweep'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('donut-story-progress')));
    await tester.pumpAndSettle();

    expect(find.text('Delivery mix'), findsWidgets);
    expect(find.text('280° sweep'), findsOneWidget);
    expect(find.text('Sweep in'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('donut-story-reach')));
    await tester.pumpAndSettle();

    expect(find.text('Campaign contribution and reach'), findsWidgets);
    expect(find.text('30% center'), findsOneWidget);
    expect(find.text('Fade in'), findsOneWidget);
  });

  testWidgets('shows host-built Donut legend items with linked selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DonutChartsPage())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('donut-story-progress')));
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('donut-showcase-chart')),
    );
    expect(chart.radialLegendItemBuilder, isNotNull);
    final firstItemFinder = find.byKey(
      const ValueKey('donut-custom-legend-item-0'),
    );
    var firstItem = tester.widget<RadialLegendValueCard>(firstItemFinder);
    expect(firstItem.item.category, 'Build');
    expect(firstItem.item.valueLabel, '46.0 hours');
    expect(firstItem.item.shareLabel, '46%');
    expect(firstItem.item.selected, isFalse);
    final initialRect = tester.getRect(firstItemFinder);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('chart-workbench-data-table')),
        matching: find.text('Build'),
      ),
    );
    await tester.pumpAndSettle();

    firstItem = tester.widget<RadialLegendValueCard>(firstItemFinder);
    expect(firstItem.item.selected, isTrue);
    expect(tester.getRect(firstItemFinder), initialRect);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'grouping story keeps source rows and selects them as one visible slice',
    (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DonutChartsPage())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('donut-story-grouping')));
      await tester.pumpAndSettle();

      expect(find.text('Support requests by channel'), findsWidgets);
      expect(find.text('Grouped sources'), findsWidgets);
      var table = tester.widget<ChartDataTable>(
        find.byKey(const ValueKey('chart-workbench-data-table')),
      );
      expect(table.model?.pieRows, hasLength(7));
      expect(
        table.model?.pieRows.map((row) => row.category),
        containsAll(<String>['Email', 'Chat', 'Events', 'Other source']),
      );
      final chartSizeBeforeSelection = tester.getSize(
        find.byKey(const ValueKey('donut-showcase-chart')),
      );
      final legendRectBeforeSelection = tester.getRect(
        find.byType(PieChartLegend),
      );

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('chart-workbench-data-table')),
          matching: find.text('Email'),
        ),
      );
      await tester.pumpAndSettle();

      table = tester.widget<ChartDataTable>(
        find.byKey(const ValueKey('chart-workbench-data-table')),
      );
      expect(table.selectedPointRefs, hasLength(4));
      expect(
        tester.getSize(find.byKey(const ValueKey('donut-showcase-chart'))),
        chartSizeBeforeSelection,
      );
      expect(
        tester.getRect(find.byType(PieChartLegend)),
        legendRectBeforeSelection,
      );
      expect(find.textContaining('all 4 original source rows'), findsOneWidget);
      expect(
        find.semantics.byLabel(
          'Donut center, Other, 15 tickets, selected slice Other',
        ),
        findsOne,
      );
      semantics.dispose();
    },
  );

  testWidgets('replays the selected Donut entrance without remounting', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DonutChartsPage())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('replay-donut-entrance')));
    await tester.pump();

    expect(tester.hasRunningAnimations, isTrue);
    expect(find.byType(BravenChartPlus), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('selects native Donut data and restores a portable artifact', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DonutChartsPage())),
    );
    await _settleCapture(tester);
    await tester.pumpAndSettle();

    final table = tester.widget<ChartDataTable>(
      find.byKey(const ValueKey('chart-workbench-data-table')),
    );
    expect(table.model?.projectionKind, ChartTableProjectionKind.pie);
    expect(table.model?.pieRows.first.category, 'Subscriptions');
    expect(table.model?.pieRows.first.shareDisplay, '42.00%');

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('chart-workbench-data-table')),
        matching: find.text('Services'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Selected: Services'), findsOneWidget);
    expect(
      find.semantics.byLabel(
        'Donut center, Services, 28 USD, selected slice Services',
      ),
      findsOne,
    );
    semantics.dispose();

    final scrollable = find
        .descendant(
          of: find.byKey(const ValueKey('donut-showcase-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('capture-donut-artifact')),
      500,
      scrollable: scrollable,
    );
    await tester.tap(find.byKey(const ValueKey('capture-donut-artifact')));
    await _settleCapture(tester);

    expect(find.text('series.donut'), findsOneWidget);
    expect(find.text('series.donut.style.v1'), findsOneWidget);
    expect(find.text('series.donut.center-content.v1'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Captured donut chart preview'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('restore-donut-artifact')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('restored-donut-artifact')),
      findsOneWidget,
    );
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
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}
