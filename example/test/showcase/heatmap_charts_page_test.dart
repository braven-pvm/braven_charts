// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/heatmap_charts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HeatmapChartsPage())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Heatmap guide exposes chart, matrix data, split, and source', (
    tester,
  ) async {
    await pumpPage(tester);

    final workbenchFinder = find.byKey(const ValueKey('heatmap-workbench'));
    expect(workbenchFinder, findsOneWidget);
    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    expect(switcher, findsOneWidget);
    for (final mode in const ['Chart', 'Data', 'Split', 'Source']) {
      expect(
        find.descendant(of: switcher, matching: find.text(mode)),
        findsOneWidget,
      );
    }

    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Data')),
    );
    await tester.pumpAndSettle();

    var workbench = tester.widget<BravenChartWorkbench>(workbenchFinder);
    final table = workbench.workbenchController!.tableModel!;
    expect(table.series, hasLength(12));
    expect(table.wideRows, hasLength(7));
    expect(table.xColumnLabel, 'Y \\ X');
    expect(table.wideRows.first.xDisplay, 'Mon');

    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Source')),
    );
    await tester.pumpAndSettle();

    workbench = tester.widget<BravenChartWorkbench>(workbenchFinder);
    final generated = workbench.workbenchController!.generatedSource!;
    expect(generated.source, contains('final heatmapChart = BravenChartPlus('));
    expect(generated.source, contains('HeatmapChartSeries('));
    expect(
      generated.source,
      contains('colorScale: HeatmapColorScale.sequential('),
    );
    expect(find.byType(ChartSourceView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Heatmap preset changes refresh the mounted source', (
    tester,
  ) async {
    await pumpPage(tester);

    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Source')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Service health'));
    await tester.pumpAndSettle();

    final workbench = tester.widget<BravenChartWorkbench>(
      find.byKey(const ValueKey('heatmap-workbench')),
    );
    expect(workbench.workbenchController!.sourceIsStale, isFalse);
    expect(
      workbench.workbenchController!.generatedSource!.source,
      contains('colorScale: HeatmapColorScale.threshold('),
    );
    expect(
      workbench.workbenchController!.generatedSource!.source,
      contains("bandLabels: ['Degraded', 'Watch', 'Healthy'],"),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Heatmap guide covers calendar and correlation matrices', (
    tester,
  ) async {
    await pumpPage(tester);

    for (final label in const [
      'Activity matrix',
      'Temperature',
      'Service health',
      'Calendar month',
      'Correlation',
      'Dense viewport',
    ]) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('Calendar month'));
    await tester.pumpAndSettle();
    expect(find.text('Daily temperature in July'), findsOneWidget);

    final workbenchFinder = find.byKey(const ValueKey('heatmap-workbench'));
    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Source')),
    );
    await tester.pumpAndSettle();
    var workbench = tester.widget<BravenChartWorkbench>(workbenchFinder);
    expect(
      workbench.workbenchController!.generatedSource!.source,
      contains('HeatmapDataPoint.missing('),
    );

    await tester.tap(find.text('Correlation'));
    await tester.pumpAndSettle();
    expect(find.text('Product metric correlation'), findsOneWidget);

    workbench = tester.widget<BravenChartWorkbench>(workbenchFinder);
    expect(workbench.workbenchController!.sourceIsStale, isFalse);
    expect(
      workbench.workbenchController!.generatedSource!.source,
      contains("label: 'Correlation'"),
    );

    expect(find.text('Palette'), findsOneWidget);
    expect(find.text('Reverse palette'), findsOneWidget);
    expect(find.text('Clamp to domain'), findsOneWidget);
    expect(find.text('Domain padding'), findsOneWidget);
    expect(find.text('Midpoint offset'), findsOneWidget);
    expect(find.text('Missing cell'), findsOneWidget);
    expect(find.text('Show colour legend'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Heatmap inspector updates the mounted chart configuration', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.text('Calendar month'));
    await tester.pumpAndSettle();

    HeatmapChartSeries mountedSeries() {
      final chart = tester.widget<BravenChartPlus>(
        find.descendant(
          of: find.byKey(const ValueKey('heatmap-workbench')),
          matching: find.byType(BravenChartPlus),
        ),
      );
      return chart.series.single as HeatmapChartSeries;
    }

    expect(mountedSeries().colorScale.reverse, isFalse);
    final reverse = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Reverse palette'),
    );
    reverse.onChanged!(true);
    await tester.pumpAndSettle();
    expect(mountedSeries().colorScale.reverse, isTrue);

    final clamp = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Clamp to domain'),
    );
    clamp.onChanged!(false);
    await tester.pumpAndSettle();
    expect(mountedSeries().colorScale.clamp, isFalse);

    final domainSlider = tester
        .widgetList<Slider>(find.byType(Slider))
        .singleWhere((slider) => slider.value == 0 && slider.max == 10);
    domainSlider.onChanged!(4);
    await tester.pumpAndSettle();
    expect(mountedSeries().colorScale.minimumValue, 11);
    expect(mountedSeries().colorScale.maximumValue, 32);

    await tester.tap(find.text('Ocean'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sunset').last);
    await tester.pumpAndSettle();
    expect(mountedSeries().colorScale.colors, const [
      Color(0xFFFFF7ED),
      Color(0xFFFDBA74),
      Color(0xFFEA580C),
      Color(0xFF7C2D12),
    ]);

    final legend = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Show colour legend'),
    );
    legend.onChanged!(false);
    await tester.pumpAndSettle();
    expect(mountedSeries().colorScale.showLegend, isFalse);

    final labels = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Show cell values'),
    );
    labels.onChanged!(false);
    await tester.pumpAndSettle();
    expect(mountedSeries().showCellLabels, isFalse);

    final gapSlider = tester
        .widgetList<Slider>(find.byType(Slider))
        .singleWhere((slider) => slider.value == 0.06);
    gapSlider.onChanged!(0.2);
    await tester.pumpAndSettle();
    expect(mountedSeries().gapFraction, 0.2);

    final radiusSlider = tester
        .widgetList<Slider>(find.byType(Slider))
        .singleWhere((slider) => slider.value == 3);
    radiusSlider.onChanged!(8);
    await tester.pumpAndSettle();
    expect(mountedSeries().cornerRadius, 8);

    await tester.tap(
      find.byKey(ValueKey('heatmap-missing-color-${Colors.red.toARGB32()}')),
    );
    await tester.pumpAndSettle();
    expect(mountedSeries().colorScale.missingColor, Colors.red);
    expect(tester.takeException(), isNull);
  });
}
