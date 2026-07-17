import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/cartesian_chart_type_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: page)));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('line guide covers workhorse, interpolation, and multi-axis', (
    tester,
  ) async {
    await pumpPage(tester, const LineChartsPage());

    expect(find.text('Line Charts'), findsOneWidget);
    expect(find.text('Workhorse'), findsWidgets);
    expect(find.text('Interpolation'), findsWidgets);
    expect(find.text('Multi-axis'), findsWidgets);
    expect(find.byType(BravenChartPlus), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('line-preset-picker')),
        matching: find.text('Multi-axis'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(chart.series, hasLength(3));
    expect(chart.normalizationMode, NormalizationMode.perSeries);
  });

  testWidgets('area guide exposes baseline and forecast compositions', (
    tester,
  ) async {
    await pumpPage(tester, const AreaChartsPage());

    expect(find.text('Area Charts'), findsOneWidget);
    expect(find.text('Layered'), findsWidgets);
    expect(find.text('Baseline'), findsWidgets);
    expect(find.text('Forecast'), findsWidgets);

    await tester.tap(find.text('Baseline'));
    await tester.pump(const Duration(milliseconds: 200));

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final series = chart.series.first as AreaChartSeries;
    expect(series.aboveBaselineFillColor, isNotNull);
    expect(series.belowBaselineFillColor, isNotNull);
  });

  testWidgets('scatter guide demonstrates a trend annotation', (tester) async {
    await pumpPage(tester, const ScatterChartsPage());

    expect(find.text('Scatter Charts'), findsOneWidget);
    expect(find.text('Cohorts'), findsWidgets);

    await tester.tap(find.text('Correlation'));
    await tester.pump(const Duration(milliseconds: 200));

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(chart.annotations.whereType<TrendAnnotation>(), hasLength(1));
  });
}
