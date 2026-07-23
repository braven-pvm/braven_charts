import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/axes_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('axes introduces four patterns around one focused stage', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AxesPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Axes'), findsOneWidget);
    expect(find.text('Choose an axis pattern'), findsOneWidget);
    expect(find.byKey(const ValueKey('axis-pattern-ribbon')), findsOneWidget);
    expect(find.byKey(const ValueKey('axis-pattern-guide')), findsOneWidget);
    expect(find.byKey(const ValueKey('axes-main-chart')), findsOneWidget);

    for (final name in [
      'labelsBounds',
      'minorTicks',
      'renderWindows',
      'axisSlots',
    ]) {
      expect(find.byKey(ValueKey('axis-pattern-$name')), findsOneWidget);
    }

    final chart = _mainChart(tester);
    expect(chart.series, hasLength(3));
    expect(chart.xAxisConfig!.label, 'Time');
    expect(chart.xAxisConfig!.unit, 'h');
    expect(chart.xAxisConfig!.min, -10);
    expect(chart.xAxisConfig!.max, 110);
    expect(chart.xAxisConfig!.renderMin, 0);
    expect(chart.xAxisConfig!.renderMax, 100);
    expect(chart.xAxisConfig!.tickCount, 6);
    expect(chart.xAxisConfig!.labelFormatter, isNotNull);
    expect(chart.xAxisConfig!.position, XAxisPosition.bottom);
    expect(chart.xAxisConfig!.effectiveTickLabelRotationDegrees, 0);
    expect(chart.yAxis!.position, YAxisPosition.left);

    expect(find.text('Axis Pattern'), findsOneWidget);
    expect(find.text('X-Axis Placement & Labels'), findsOneWidget);
    expect(find.text('Labels & Bounds'), findsOneWidget);
    expect(find.text('Chart Options'), findsOneWidget);
  });

  testWidgets('X-axis placement and angle controls update the live chart', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AxesPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final positionOption = tester.widget<EnumOption<XAxisPosition>>(
      find.byWidgetPredicate(
        (widget) =>
            widget is EnumOption<XAxisPosition> && widget.label == 'Position',
      ),
    );
    expect(positionOption.values, contains(XAxisPosition.both));
    positionOption.onChanged(XAxisPosition.both);

    final angleOption = tester.widget<SliderOption>(
      find.byWidgetPredicate(
        (widget) =>
            widget is SliderOption && widget.label == 'Tick Label Angle',
      ),
    );
    angleOption.onChanged(-45);
    await tester.pump();

    final chart = _mainChart(tester);
    expect(chart.xAxisConfig?.position, XAxisPosition.both);
    expect(chart.xAxisConfig?.tickLabelRotationDegrees, -45);
  });

  testWidgets('axis patterns configure ticks, render windows, and slots', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AxesPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const ValueKey('axis-pattern-minorTicks')));
    await tester.pump(const Duration(milliseconds: 200));
    var chart = _mainChart(tester);
    expect(chart.xAxisConfig!.showMinorTicks, isTrue);
    expect(chart.xAxisConfig!.minorTickCount, 4);
    expect(chart.yAxis!.showMinorTicks, isTrue);
    expect(chart.grid!.horizontal, isTrue);
    expect(chart.grid!.vertical, isTrue);
    expect(find.text('Ticks & Grid'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('axis-pattern-renderWindows')));
    await tester.pump(const Duration(milliseconds: 200));
    chart = _mainChart(tester);
    expect(chart.xAxisConfig!.renderMin, 10);
    expect(chart.xAxisConfig!.renderMax, 90);
    expect(chart.yAxis!.renderMin, 45);
    expect(chart.yAxis!.renderMax, 90);
    expect(chart.annotations, hasLength(1));
    expect(find.text('Render Windows'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('axis-pattern-axisSlots')));
    await tester.pump(const Duration(milliseconds: 300));
    chart = _mainChart(tester);
    expect(chart.series, hasLength(5));
    expect(chart.maxAxesPerSide, 3);
    expect(chart.axisSwapMode, AxisSwapMode.sticky);
    expect(chart.normalizationMode, NormalizationMode.perSeries);
    expect(find.byType(ChartLegend), findsOneWidget);
    expect(find.byKey(const ValueKey('axis-slot-status')), findsOneWidget);
    expect(find.text('Axis Slot Allocation'), findsOneWidget);
    expect(find.text('Max Axes Per Side'), findsOneWidget);
  });

  testWidgets('axes selector and options remain usable on narrow layouts', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(390 * pixelRatio, 844 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AxesPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('axis-pattern-ribbon')), findsOneWidget);
    expect(find.text('Labels & bounds'), findsWidgets);
    expect(find.text('Options'), findsOneWidget);

    await tester.tap(find.text('Options'));
    await tester.pumpAndSettle();
    expect(find.text('Axis Pattern'), findsOneWidget);
    expect(find.text('Labels & Bounds'), findsOneWidget);
    expect(find.text('Major Tick Count'), findsOneWidget);
    Navigator.of(tester.element(find.text('Axis Pattern'))).pop();
    await tester.pumpAndSettle();
  });
}

BravenChartPlus _mainChart(WidgetTester tester) {
  return tester.widget<BravenChartPlus>(
    find.byKey(const ValueKey('axes-main-chart')),
  );
}
