import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/multi_axis_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('multi-axis introduces four scale patterns around one stage', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MultiAxisPage())),
    );
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Multi-Axis'), findsOneWidget);
    expect(find.text('Choose a multi-axis pattern'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('multi-axis-pattern-ribbon')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('multi-axis-pattern-guide')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('multi-axis-map')), findsOneWidget);

    for (final name in [
      'dualUnits',
      'normalized',
      'hiddenScale',
      'denseTelemetry',
    ]) {
      expect(find.byKey(ValueKey('multi-axis-pattern-$name')), findsOneWidget);
    }

    final chart = _mainChart(tester, 'dualUnits');
    expect(chart.series, hasLength(2));
    expect(chart.normalizationMode, NormalizationMode.perSeries);
    expect(chart.xAxisConfig!.label, 'Elapsed time');
    expect(chart.xAxisConfig!.unit, 'h');
    expect(chart.series.first.yAxisConfig!.position, YAxisPosition.left);
    expect(chart.series.last.yAxisConfig!.position, YAxisPosition.right);
    expect(chart.series.first.yAxisConfig!.unit, 'W');
    expect(chart.series.last.yAxisConfig!.unit, 'bpm');

    expect(find.text('Scale Model'), findsOneWidget);
    expect(find.text('Axis Placement'), findsOneWidget);
    expect(find.text('Chart Options'), findsOneWidget);
  });

  testWidgets('patterns cover normalization, hidden axes, and dense slots', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MultiAxisPage())),
    );
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(
      find.byKey(const ValueKey('multi-axis-pattern-normalized')),
    );
    await tester.pump(const Duration(milliseconds: 250));
    var chart = _mainChart(tester, 'normalized');
    expect(chart.series, hasLength(3));
    expect(chart.normalizationMode, NormalizationMode.perSeries);
    expect(
      chart.series.map((series) => series.yAxisConfig!.unit),
      containsAll(['W', 'bpm', 'mmol/L']),
    );
    expect(find.text('Independent physiological scales'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('multi-axis-pattern-hiddenScale')),
    );
    await tester.pump(const Duration(milliseconds: 250));
    chart = _mainChart(tester, 'hiddenScale');
    expect(chart.series, hasLength(3));
    expect(chart.series.last.yAxisConfig!.position, YAxisPosition.hidden);
    expect(find.text('Hidden Axis'), findsOneWidget);
    expect(find.text('Keep Efficiency Axis Hidden'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('multi-axis-pattern-denseTelemetry')),
    );
    await tester.pump(const Duration(milliseconds: 350));
    chart = _mainChart(tester, 'denseTelemetry');
    expect(chart.series, hasLength(6));
    expect(chart.maxAxesPerSide, 3);
    expect(chart.axisSwapMode, AxisSwapMode.sticky);
    expect(
      chart.series
          .where((series) => series.yAxisConfig!.position == YAxisPosition.left)
          .length,
      3,
    );
    expect(
      chart.series
          .where(
            (series) => series.yAxisConfig!.position == YAxisPosition.right,
          )
          .length,
      3,
    );
    expect(find.text('Visible Axis Slots'), findsOneWidget);
    expect(find.text('Max Axes Per Side'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('multi-axis-slot-status')),
      findsOneWidget,
    );
  });

  testWidgets('multi-axis selector remains usable on a narrow viewport', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(390 * pixelRatio, 844 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MultiAxisPage())),
    );
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.byKey(const ValueKey('multi-axis-pattern-ribbon')),
      findsOneWidget,
    );
    expect(find.text('Dual units'), findsWidgets);
    expect(find.text('Options'), findsOneWidget);

    await tester.tap(find.text('Options'));
    await tester.pumpAndSettle();
    expect(find.text('Multi-Axis Pattern'), findsOneWidget);
    expect(find.text('Scale Model'), findsOneWidget);
    expect(find.text('Normalization'), findsOneWidget);
    expect(find.text('Axis Placement'), findsOneWidget);
  });
}

BravenChartPlus _mainChart(WidgetTester tester, String pattern) {
  return tester.widget<BravenChartPlus>(
    find.byKey(ValueKey('multi-axis-main-chart-$pattern')),
  );
}
