import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/baseline_area_demo_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('baseline workbench presents four real fill patterns', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BaselineAreaDemoPage())),
    );
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Choose a baseline pattern'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('baseline-pattern-ribbon')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('baseline-guide')), findsOneWidget);
    expect(find.byKey(const ValueKey('baseline-main-stage')), findsOneWidget);

    for (final name in ['target', 'zeroCentered', 'deviation', 'stepped']) {
      expect(find.byKey(ValueKey('baseline-pattern-$name')), findsOneWidget);
      expect(find.byKey(ValueKey('baseline-preview-$name')), findsOneWidget);
    }

    final chart = _mainChart(tester, 'target');
    final series = chart.series.single as AreaChartSeries;
    expect(series.baselineValue, 120);
    expect(series.aboveBaselineFillColor, isNot(series.belowBaselineFillColor));
    expect(series.interpolation, LineInterpolation.monotone);
    expect(chart.annotations.whereType<ThresholdAnnotation>(), hasLength(1));

    expect(find.text('Baseline'), findsWidgets);
    expect(find.text('Baseline Value'), findsOneWidget);
    expect(find.text('Region Styling'), findsOneWidget);
    expect(find.text('Chart Options'), findsOneWidget);
  });

  testWidgets('zero-centred and deviation patterns carry distinct semantics', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BaselineAreaDemoPage())),
    );
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(
      find.byKey(const ValueKey('baseline-pattern-zeroCentered')),
    );
    await tester.pump(const Duration(milliseconds: 250));
    var chart = _mainChart(tester, 'zeroCentered');
    var series = chart.series.single as AreaChartSeries;
    expect(series.baselineValue, 0);
    expect(series.points.any((point) => point.y < 0), isTrue);
    expect(series.points.any((point) => point.y > 0), isTrue);
    expect(chart.yAxis!.unit, '%');
    expect(find.text('Positive / negative'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('baseline-pattern-deviation')));
    await tester.pump(const Duration(milliseconds: 250));
    chart = _mainChart(tester, 'deviation');
    series = chart.series.single as AreaChartSeries;
    expect(series.baselineValue, 120);
    expect(series.aboveBaselineFillColor, series.belowBaselineFillColor);
    expect(series.interpolation, LineInterpolation.linear);
    expect(find.text('Magnitude of deviation'), findsWidgets);
  });

  testWidgets('stepped pattern exposes interpolation-aligned fill controls', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BaselineAreaDemoPage())),
    );
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.byKey(const ValueKey('baseline-pattern-stepped')));
    await tester.pump(const Duration(milliseconds: 250));

    final chart = _mainChart(tester, 'stepped');
    final series = chart.series.single as AreaChartSeries;
    expect(series.interpolation, LineInterpolation.stepped);
    expect(series.baselineValue, 120);
    expect(series.points, hasLength(9));
    expect(find.text('Stepped regimes'), findsWidgets);
    expect(find.text('Interpolation'), findsWidgets);
    expect(find.text('Above Baseline'), findsOneWidget);
    expect(find.text('Below Baseline'), findsOneWidget);
  });
}

BravenChartPlus _mainChart(WidgetTester tester, String pattern) {
  return tester.widget<BravenChartPlus>(
    find.byKey(ValueKey('baseline-main-chart-$pattern')),
  );
}
