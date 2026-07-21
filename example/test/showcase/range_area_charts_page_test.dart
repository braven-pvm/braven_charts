import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/range_area_charts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the native Range Area review surface', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RangeAreaChartsPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Range Area Charts'), findsOneWidget);
    expect(find.text('Choose a range area example'), findsOneWidget);
    expect(find.byKey(const ValueKey('range-area-workbench')), findsOneWidget);
    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    expect(switcher, findsOneWidget);
    for (final label in ['Chart', 'Data', 'Split', 'Source']) {
      expect(
        find.descendant(of: switcher, matching: find.text(label)),
        findsOneWidget,
      );
    }
    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('range-area-chart-temperature')),
    );
    expect(chart.series, hasLength(2));
    expect(chart.series.first, isA<RangeAreaChartSeries>());
    final range = chart.series.first as RangeAreaChartSeries;
    expect(range.intervals, hasLength(24));
    expect(range.fillGradient, isNotNull);
    expect(range.borderMode, RangeAreaBorderMode.boundaries);
    expect(range.pathAnimation.entranceMode, PathEntranceAnimationMode.reveal);
    expect(
      range.pathAnimation.dataUpdateMode,
      PathDataUpdateAnimationMode.interpolate,
    );
    expect(range.labelConfig.value, RangeAreaLabelValue.none);
    expect(chart.series.last, isA<LineChartSeries>());
    expect(chart.interactionConfig!.valueSummary.enabled, isTrue);
    expect(chart.interactionConfig!.crosshair.showIntersectionMarkers, isTrue);
    expect(chart.interactionConfig!.keyboard.enabled, isTrue);
    expect(chart.interactionConfig!.showFocusBorder, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports Data, Split, and generated Source modes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RangeAreaChartsPage())),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('range-area-preset-volatility')),
    );
    await tester.pumpAndSettle();

    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Data')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(find.textContaining('Volatility range low'), findsWidgets);
    expect(find.textContaining('Volatility range high'), findsWidgets);
    expect(find.textContaining('Volatility range span'), findsWidgets);

    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Split')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chart-workbench-split-handle')),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Source')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChartSourceView), findsOneWidget);
    expect(find.textContaining('RangeAreaChartSeries('), findsWidgets);
    expect(find.textContaining('RangeAreaDataPoint('), findsWidgets);
    expect(find.textContaining('RangeAreaBoundaryStyle('), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switches presets and exposes live Range Area controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RangeAreaChartsPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const ValueKey('range-area-preset-confidence')),
    );
    await tester.pump();
    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('range-area-chart-confidence')),
    );
    final range = chart.series.first as RangeAreaChartSeries;
    expect(range.intervals, hasLength(20));
    expect(range.intervals.where((point) => point.isGap), hasLength(1));
    expect(find.text('Hit test mode'), findsOneWidget);
    expect(range.connectGaps, isFalse);
    expect(chart.interactionConfig!.crosshair.interpolateValues, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('showcases range-only, nested, and stepped-gap compositions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RangeAreaChartsPage())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('range-area-preset-seasonal')));
    await tester.pumpAndSettle();
    var chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('range-area-chart-seasonal')),
    );
    expect(chart.series, hasLength(1));
    expect(
      (chart.series.single as RangeAreaChartSeries).intervals,
      hasLength(52),
    );

    await tester.tap(
      find.byKey(const ValueKey('range-area-preset-forecastFan')),
    );
    await tester.pumpAndSettle();
    chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('range-area-chart-forecastFan')),
    );
    expect(chart.series, hasLength(3));
    expect(chart.series.take(2), everyElement(isA<RangeAreaChartSeries>()));
    expect(chart.series.last, isA<LineChartSeries>());
    final outer = chart.series.first as RangeAreaChartSeries;
    final inner = chart.series[1] as RangeAreaChartSeries;
    expect(outer.intervals.last.span!, greaterThan(inner.intervals.last.span!));

    await tester.tap(
      find.byKey(const ValueKey('range-area-preset-gapsAndSteps')),
    );
    await tester.pumpAndSettle();
    chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('range-area-chart-gapsAndSteps')),
    );
    expect(chart.series, hasLength(1));
    final stepped = chart.series.single as RangeAreaChartSeries;
    expect(stepped.interpolation, LineInterpolation.stepped);
    expect(stepped.intervals.where((point) => point.isGap), hasLength(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('animates an atomic low-high update without changing gaps', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RangeAreaChartsPage())),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(
      find.byKey(const ValueKey('range-area-preset-confidence')),
    );
    await tester.pumpAndSettle();

    RangeAreaChartSeries range() =>
        tester
                .widget<BravenChartPlus>(
                  find.byKey(const ValueKey('range-area-chart-confidence')),
                )
                .series
                .first
            as RangeAreaChartSeries;

    final before = range().intervals;
    await tester.tap(find.byKey(const ValueKey('range-area-animate-update')));
    await tester.pump(const Duration(milliseconds: 250));
    final during = range().intervals;

    expect(during, hasLength(before.length));
    expect(during.where((point) => point.isGap), hasLength(1));
    expect(
      during.where((point) => !point.isGap),
      everyElement(
        predicate<RangeAreaDataPoint>(
          (point) => point.low! <= point.high!,
          'low remains less than or equal to high',
        ),
      ),
    );
    expect(
      during.where((point) => !point.isGap).map((point) => point.low),
      isNot(
        equals(before.where((point) => !point.isGap).map((point) => point.low)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('stays usable at compact width', (tester) async {
    tester.view.physicalSize = const Size(720, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RangeAreaChartsPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Range Area Charts'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chart-page-options-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('range-area-coverage-strip')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
