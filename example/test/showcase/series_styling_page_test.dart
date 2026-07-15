import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/series_styling_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('series styling introduces four layers around one stage', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SeriesStylingPage())),
    );
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Choose a styling layer'), findsOneWidget);
    expect(find.byKey(const ValueKey('series-styling-ribbon')), findsOneWidget);
    expect(find.byKey(const ValueKey('series-styling-guide')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('series-styling-main-stage')),
      findsOneWidget,
    );

    for (final name in [
      'appearance',
      'inlineLabels',
      'pointLabels',
      'conditional',
    ]) {
      expect(
        find.byKey(ValueKey('series-styling-pattern-$name')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('series-styling-preview-$name')),
        findsOneWidget,
      );
    }

    final chart = _mainChart(tester, 'appearance');
    expect(chart.series, hasLength(2));
    expect(chart.series.whereType<LineChartSeries>(), hasLength(2));
    expect(
      chart.series.whereType<LineChartSeries>().every(
        (series) => series.lineGlow == 4,
      ),
      isTrue,
    );

    expect(find.text('Styling Layer'), findsOneWidget);
    expect(find.text('Series Appearance'), findsWidgets);
    expect(find.text('Glow Radius'), findsOneWidget);
    expect(find.text('Chart Options'), findsOneWidget);
  });

  testWidgets('label layers expose inline and data-point configuration', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SeriesStylingPage())),
    );
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(
      find.byKey(const ValueKey('series-styling-pattern-inlineLabels')),
    );
    await tester.pump(const Duration(milliseconds: 250));
    var chart = _mainChart(tester, 'inlineLabels');
    final inlineSeries = chart.series.whereType<LineChartSeries>().toList();
    expect(inlineSeries, hasLength(2));
    expect(inlineSeries.every((series) => series.inlineLabel != null), isTrue);
    expect(
      inlineSeries.every((series) => series.inlineLabel!.background != null),
      isTrue,
    );
    expect(find.text('Inline Labels'), findsWidgets);
    expect(find.text('Anchor Position'), findsOneWidget);
    expect(find.text('Background Pill'), findsOneWidget);
    expect(find.text('Series-Color Border'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('series-styling-pattern-pointLabels')),
    );
    await tester.pump(const Duration(milliseconds: 250));
    chart = _mainChart(tester, 'pointLabels');
    final pointSeries = chart.series.single as LineChartSeries;
    expect(pointSeries.showDataPointMarkers, isTrue);
    expect(pointSeries.dataPointMarkerStyle, DataPointMarkerStyle.hollow);
    expect(pointSeries.dataPointLabels!.show, isTrue);
    expect(pointSeries.dataPointLabels!.showUnit, isTrue);
    expect(find.text('Data Point Labels'), findsOneWidget);
    expect(find.text('Custom Formatter'), findsOneWidget);
    expect(find.text('Marker Radius'), findsOneWidget);
  });

  testWidgets('conditional styling applies segment overrides and options', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SeriesStylingPage())),
    );
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(
      find.byKey(const ValueKey('series-styling-pattern-conditional')),
    );
    await tester.pump(const Duration(milliseconds: 250));

    final chart = _mainChart(tester, 'conditional');
    expect(chart.series, hasLength(1));
    expect(chart.series.single, isA<LineChartSeries>());
    expect(
      chart.series.single.points.where((point) => point.segmentStyle != null),
      isNotEmpty,
    );
    expect(find.text('Conditional Styling'), findsWidgets);
    expect(find.text('Chart Type'), findsOneWidget);
    expect(find.text('Rule'), findsOneWidget);
    expect(find.text('Highlight Color'), findsOneWidget);
    expect(find.text('Y Threshold'), findsOneWidget);
  });
}

BravenChartPlus _mainChart(WidgetTester tester, String pattern) {
  return tester.widget<BravenChartPlus>(
    find.byKey(ValueKey('series-styling-main-chart-$pattern')),
  );
}
