import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/chart_types_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('chart type ribbon selects the configurable main chart', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ChartTypesPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Choose a chart type'), findsOneWidget);
    expect(find.byKey(const ValueKey('chart-type-ribbon')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chart-type-preview-line')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('chart-type-preview-area')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('chart-type-preview-bar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('chart-type-preview-scatter')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('chart-type-preview-pie')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('chart-type-preview-donut')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('selected-chart-type-line')),
      findsOneWidget,
    );
    expect(find.text('Line chart playground'), findsOneWidget);
    expect(find.textContaining('2 series · 16 points each'), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('chart-type-preview-bar')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey('selected-chart-type-bar')),
      findsOneWidget,
    );
    expect(find.text('Bar chart playground'), findsOneWidget);
    expect(find.text('Bar Appearance'), findsOneWidget);
    expect(find.textContaining('64% bar width'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('chart-type-preview-scatter')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey('selected-chart-type-scatter')),
      findsOneWidget,
    );
    expect(find.text('Scatter chart playground'), findsOneWidget);
    expect(find.text('Marker Appearance'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('chart-type-preview-pie')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey('selected-chart-type-pie')),
      findsOneWidget,
    );
    expect(find.text('Pie chart playground'), findsOneWidget);
    expect(find.textContaining('5 categories'), findsOneWidget);
    expect(find.text('Pie Appearance'), findsOneWidget);
    expect(find.text('Show Data Labels'), findsOneWidget);
    expect(find.text('Label Position'), findsOneWidget);
    expect(find.text('Label Offset'), findsOneWidget);
    expect(find.text('Slice Gap'), findsOneWidget);
    expect(find.text('Start Angle'), findsOneWidget);
    expect(find.text('Slice Fill'), findsOneWidget);
    expect(find.text('Show Second Series'), findsNothing);
    expect(find.text('Show Grid Lines'), findsNothing);
    expect(find.text('Show Axis Lines'), findsNothing);
    expect(find.text('Show X Scrollbar'), findsNothing);
    expect(find.text('Enable Zoom'), findsNothing);
    expect(find.text('Show Legend'), findsOneWidget);

    final pieChart = tester
        .widgetList<BravenChartPlus>(find.byType(BravenChartPlus))
        .singleWhere(
          (chart) =>
              chart.series.any((series) => series.id == 'pie-contributions'),
        );
    final pieSeries = pieChart.series.single as PieChartSeries;
    expect(pieSeries.pieStyle.sliceGap, 3);
    expect(pieSeries.pieStyle.gradient?.type, PieGradientType.radial);
    expect(pieSeries.dataLabels.isVisible, isTrue);
    expect(pieSeries.dataLabels.position, PieDataLabelPosition.outside);
    expect(pieSeries.dataLabels.outsideOffset, 0);

    await tester.tap(find.byKey(const ValueKey('chart-type-preview-donut')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey('selected-chart-type-donut')),
      findsOneWidget,
    );
    expect(find.text('Donut chart playground'), findsOneWidget);
    expect(find.text('Donut Appearance'), findsOneWidget);
    expect(find.text('Inner Radius'), findsOneWidget);
    expect(find.text('Sweep Angle'), findsOneWidget);
    expect(find.text('Show Center Content'), findsOneWidget);
    expect(find.text('Center Value'), findsOneWidget);
    final donutChart = tester
        .widgetList<BravenChartPlus>(find.byType(BravenChartPlus))
        .singleWhere(
          (chart) =>
              chart.series.any((series) => series.id == 'donut-contributions'),
        );
    final donutSeries = donutChart.series.single as DonutChartSeries;
    expect(donutSeries.donutStyle.innerRadiusFactor, 0.58);
    expect(donutSeries.centerContent.isVisible, isTrue);
    expect(
      donutSeries.centerContent.valueMode,
      DonutCenterValueMode.selectedOrTotal,
    );
  });

  testWidgets('chart-defining controls precede generic display controls', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ChartTypesPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final chartTypeTop = tester.getTopLeft(find.text('Chart Type')).dy;
    final genericOptionsTop = tester.getTopLeft(find.text('Chart Options')).dy;

    expect(chartTypeTop, lessThan(genericOptionsTop));
    expect(find.text('Show Second Series'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Regenerate Dataset'),
      300,
      scrollable: find.descendant(
        of: find.byType(OptionsPanel),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Regenerate Dataset'), findsOneWidget);
  });
}
