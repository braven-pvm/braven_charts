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
    expect(
      chart.xAxisConfig!.effectiveTickLabelCollisionPolicy,
      XAxisTickLabelCollisionPolicy.auto,
    );
    expect(chart.xAxisConfig!.tickLabelCollisionPadding, 4);
    expect(chart.yAxis!.position, YAxisPosition.left);
    expect(chart.yAxis!.tickCount, 6);

    expect(find.text('Axis Pattern'), findsOneWidget);
    expect(find.text('X-axis ticks & labels'), findsOneWidget);
    expect(find.text('Labels & Bounds'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Chart Options'),
      240,
      scrollable: find.descendant(
        of: find.byType(OptionsPanel),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Chart Options'), findsOneWidget);
  });

  testWidgets('X-axis placement and label controls update the live chart', (
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
            widget is SliderOption && widget.label == 'Tick label angle',
      ),
    );
    angleOption.onChanged(-45);

    final tickCountOption = tester.widget<IntSliderOption>(
      find.byWidgetPredicate(
        (widget) =>
            widget is IntSliderOption &&
            widget.label == 'Requested X-axis ticks',
      ),
    );
    expect(tickCountOption.min, 2);
    expect(tickCountOption.max, 32);
    tickCountOption.onChanged(24);

    final showXTickMarks = tester.widget<BoolOption>(
      find.byWidgetPredicate(
        (widget) => widget is BoolOption && widget.label == 'Show tick marks',
      ),
    );
    showXTickMarks.onChanged(false);

    final showXTickLabels = tester.widget<BoolOption>(
      find.byWidgetPredicate(
        (widget) => widget is BoolOption && widget.label == 'Show tick labels',
      ),
    );
    showXTickLabels.onChanged(false);

    final collisionOption = tester
        .widget<EnumOption<XAxisTickLabelCollisionPolicy>>(
          find.byWidgetPredicate(
            (widget) =>
                widget is EnumOption<XAxisTickLabelCollisionPolicy> &&
                widget.label == 'Label density',
          ),
        );
    collisionOption.onChanged(XAxisTickLabelCollisionPolicy.showAll);

    final gapOption = tester.widget<SliderOption>(
      find.byWidgetPredicate(
        (widget) =>
            widget is SliderOption && widget.label == 'Minimum label spacing',
      ),
    );
    gapOption.onChanged(12);
    await tester.pump();

    final chart = _mainChart(tester);
    expect(chart.xAxisConfig?.position, XAxisPosition.both);
    expect(chart.xAxisConfig?.tickLabelRotationDegrees, -45);
    expect(chart.xAxisConfig?.tickCount, 24);
    expect(chart.xAxisConfig?.showTicks, isFalse);
    expect(chart.xAxisConfig?.showTickLabels, isFalse);
    expect(
      chart.xAxisConfig?.tickLabelCollisionPolicy,
      XAxisTickLabelCollisionPolicy.showAll,
    );
    expect(chart.xAxisConfig?.tickLabelCollisionPadding, 12);
    expect(chart.xAxisConfig?.labelFormatter?.call(42), '42:00');
    expect(chart.xAxisConfig?.labelFormatter?.call(42.75), '42:45');
    expect(chart.yAxis?.tickCount, 6);
    expect(chart.yAxis?.showTicks, isTrue);
    expect(chart.yAxis?.showTickLabels, isTrue);
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
    expect(find.text('Requested X-axis ticks'), findsOneWidget);
    expect(find.text('Label density'), findsOneWidget);
    expect(find.text('Minimum label spacing'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Labels & Bounds'),
      240,
      scrollable: find.descendant(
        of: find.byType(OptionsPanel),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Labels & Bounds'), findsOneWidget);
    Navigator.of(tester.element(find.byType(OptionsPanel))).pop();
    await tester.pumpAndSettle();
  });
}

BravenChartPlus _mainChart(WidgetTester tester) {
  return tester.widget<BravenChartPlus>(
    find.byKey(const ValueKey('axes-main-chart')),
  );
}
