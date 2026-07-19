import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/candlestick_charts_page.dart';
import 'package:braven_charts_example/showcase/widgets/chart_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the native Candlestick workbench and overlay', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CandlestickChartsPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Candlestick Charts'), findsOneWidget);
    expect(find.text('Financial chart workbench'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('candlestick-reference-chart')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('candlestick-direction-legend')),
      findsOneWidget,
    );
    expect(find.text('Rising'), findsOneWidget);
    expect(find.text('Falling'), findsOneWidget);
    expect(find.text('Doji'), findsOneWidget);

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-reference-chart')),
    );
    expect(chart.series, hasLength(2));
    final candles = chart.series.first as CandlestickChartSeries;
    expect(candles.points, hasLength(32));
    expect(candles.candleAt(14).direction, CandlestickDirection.doji);
    expect(
      candles.candlestickStyle.bodyFillMode,
      CandlestickBodyFillMode.hollowRising,
    );
    expect(chart.series.last, isA<LineChartSeries>());
    expect(chart.interactionConfig?.crosshair.enabled, isTrue);
    expect(chart.interactionConfig?.crosshair.interpolateValues, isFalse);
    expect(
      chart.interactionConfig?.crosshair.displayMode,
      CrosshairDisplayMode.tracking,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes lossless Data, resizable Split, and generated Source', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CandlestickChartsPage())),
    );
    await tester.pumpAndSettle();

    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    expect(switcher, findsOneWidget);

    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Data')),
    );
    await tester.pumpAndSettle();
    var workbench = tester.widget<BravenChartWorkbench>(
      find.byKey(const ValueKey('candlestick-workbench')),
    );
    expect(
      workbench.workbenchController!.tableState.phase,
      ChartWorkbenchTablePhase.ready,
    );
    expect(
      workbench.workbenchController!.tableModel!.projectionKind,
      ChartTableProjectionKind.candlestick,
    );
    expect(
      workbench.workbenchController!.tableModel!.candlestickRows,
      hasLength(32),
    );
    expect(find.text('Open'), findsWidgets);
    expect(find.text('High'), findsWidgets);
    expect(find.text('Low'), findsWidgets);
    expect(find.text('Close'), findsWidgets);
    expect(find.text('Change %'), findsOneWidget);

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
    workbench = tester.widget<BravenChartWorkbench>(
      find.byKey(const ValueKey('candlestick-workbench')),
    );
    expect(
      workbench.workbenchController!.sourceState.phase,
      ChartWorkbenchSourcePhase.ready,
    );
    expect(
      workbench.workbenchController!.generatedSource!.source,
      contains('CandlestickChartSeries('),
    );
    expect(
      workbench.workbenchController!.generatedSource!.source,
      contains('CandlestickDataPoint('),
    );
    expect(find.byType(ChartSourceView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wires renderer geometry, stroke, overlay, and theme controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CandlestickChartsPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('candlestick-body-mode')),
      300,
      scrollable: find.byType(Scrollable).last,
    );

    final dynamic bodyMode = tester.widget(
      find.byKey(const ValueKey('candlestick-body-mode')),
    );
    bodyMode.onChanged(CandlestickBodyFillMode.filled);
    final dynamic widthFactor = tester.widget(
      find.byKey(const ValueKey('candlestick-width-factor')),
    );
    widthFactor.onChanged(0.9);
    final dynamic cornerRadius = tester.widget(
      find.byKey(const ValueKey('candlestick-corner-radius')),
    );
    cornerRadius.onChanged(4.0);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('candlestick-show-wicks')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    final dynamic showWicks = tester.widget(
      find.byKey(const ValueKey('candlestick-show-wicks')),
    );
    showWicks.onChanged(false);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('candlestick-show-average')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    final dynamic showAverage = tester.widget(
      find.byKey(const ValueKey('candlestick-show-average')),
    );
    showAverage.onChanged(false);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('candlestick-theme')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    final dynamic theme = tester.widget(
      find.byKey(const ValueKey('candlestick-theme')),
    );
    theme.onChanged(ThemePreset.dark);
    await tester.pump();

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-reference-chart')),
    );
    final series = chart.series.single as CandlestickChartSeries;
    expect(
      series.candlestickStyle.bodyFillMode,
      CandlestickBodyFillMode.filled,
    );
    expect(series.candlestickStyle.bodyWidthFactor, 0.9);
    expect(series.candlestickStyle.bodyCornerRadius, 4);
    expect(series.candlestickStyle.showWicks, isFalse);
    expect(chart.theme?.backgroundColor, ChartTheme.dark.backgroundColor);
    expect(chart.theme?.candlestickTheme, CandlestickTheme.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switches financial time spacing and revises the latest candle', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CandlestickChartsPage())),
    );
    await tester.pumpAndSettle();

    var chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-reference-chart')),
    );
    final original = chart.series.first as CandlestickChartSeries;
    final originalClose = original.candleAt(31).close;
    expect(original.candleAt(1).x - original.candleAt(0).x, 1);

    final dynamic spacing = tester.widget(
      find.byKey(const ValueKey('candlestick-time-spacing')),
    );
    spacing.onChanged(FinancialTimeSpacing.elapsed);
    await tester.pump();
    chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-reference-chart')),
    );
    final elapsed = chart.series.first as CandlestickChartSeries;
    expect(
      elapsed.candleAt(1).x - elapsed.candleAt(0).x,
      const Duration(days: 1).inMilliseconds,
    );

    await tester.tap(find.byKey(const ValueKey('candlestick-revise-latest')));
    await tester.pump();
    chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-reference-chart')),
    );
    final revised = chart.series.first as CandlestickChartSeries;
    expect(revised.candleAt(31).close, originalClose + 4.6);
    expect(revised.candleAt(31).x, elapsed.candleAt(31).x);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'stock composition synchronizes price and volume while navigator stays full-domain',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CandlestickChartsPage())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stock composition'));
      await tester.pumpAndSettle();

      final price = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('candlestick-stock-price-chart')),
      );
      final volume = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('candlestick-stock-volume-chart')),
      );
      final navigator = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('candlestick-stock-navigator')),
      );
      expect(price.series.first, isA<CandlestickChartSeries>());
      expect(price.series.last, isA<LineChartSeries>());
      expect(volume.series.single, isA<BarChartSeries>());
      expect(
        price.interactionGroupController,
        same(volume.interactionGroupController),
      );
      expect(
        navigator.interactionGroupController,
        same(price.interactionGroupController),
      );
      expect(navigator.interactionGroupOptions.synchronizeViewport, isFalse);
      expect(price.yAxis?.unit, 'USD');
      expect(volume.yAxis?.unit, 'M');
      expect(
        tester
            .getSize(
              find.byKey(const ValueKey('candlestick-stock-price-chart')),
            )
            .height,
        greaterThan(250),
      );
      expect(
        find.byKey(const ValueKey('candlestick-stock-performance')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('candlestick-stock-code-reference')),
        findsOneWidget,
      );

      final viewport = price.interactionGroupController!.viewport!;
      expect(viewport.max - viewport.min, 65);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('stock range, navigator, spacing, and volume controls are live', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CandlestickChartsPage())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stock composition'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('candlestick-range-oneMonth')));
    await tester.pump();
    var price = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-stock-price-chart')),
    );
    final group = price.interactionGroupController!;
    expect(group.viewport!.max - group.viewport!.min, 21);

    await tester.tap(find.byKey(const ValueKey('candlestick-range-all')));
    await tester.pump();
    expect(group.viewport, const ChartXViewport(min: 0, max: 419));

    await tester.tap(
      find.byKey(const ValueKey('candlestick-range-yearToDate')),
    );
    await tester.pump();
    price = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-stock-price-chart')),
    );
    final candles = (price.series.first as CandlestickChartSeries).candles;
    final firstCurrentYear = candles.indexWhere(
      (point) => point.timestamp!.year == candles.last.timestamp!.year,
    );
    expect(group.viewport!.min, firstCurrentYear.toDouble());
    expect(group.viewport!.max, 419);

    final dynamic navigatorRange = tester.widget(
      find.byKey(const ValueKey('candlestick-stock-navigator-range')),
    );
    navigatorRange.onChanged(const RangeValues(100, 160));
    await tester.pump();
    expect(group.viewport, const ChartXViewport(min: 100, max: 160));
    var navigator = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-stock-navigator')),
    );
    final ordinalWindow = navigator.annotations.single as RangeAnnotation;
    expect(ordinalWindow.startX, 100);
    expect(ordinalWindow.endX, 160);

    await tester.tap(
      find.byKey(const ValueKey('candlestick-stock-time-spacing')),
    );
    await tester.pump();
    price = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-stock-price-chart')),
    );
    final elapsed = price.series.first as CandlestickChartSeries;
    expect(
      elapsed.candleAt(1).x - elapsed.candleAt(0).x,
      const Duration(days: 1).inMilliseconds,
    );
    expect(group.viewport!.max - group.viewport!.min, greaterThan(60));
    navigator = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-stock-navigator')),
    );
    final elapsedWindow = navigator.annotations.single as RangeAnnotation;
    expect(elapsedWindow.startX, group.viewport!.min);
    expect(elapsedWindow.endX, group.viewport!.max);

    final viewportBeforeVolumeToggle = group.viewport;
    await tester.tap(find.byKey(const ValueKey('candlestick-volume-pane')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('candlestick-stock-volume-chart')),
      findsNothing,
    );
    expect(group.viewport, viewportBeforeVolumeToggle);
    expect(find.text('2  Active charts'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stock composition remains usable on a compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CandlestickChartsPage())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stock composition'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('candlestick-showcase-scroll')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('candlestick-stock-price-chart')),
      findsOneWidget,
    );
    expect(
      tester
          .getRect(find.byKey(const ValueKey('candlestick-review-header')))
          .right,
      lessThanOrEqualTo(390),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'compact workbench scrolls without overflow and exposes options',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CandlestickChartsPage())),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const ValueKey('candlestick-showcase-scroll')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('chart-page-options-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('candlestick-reference-chart')),
        findsOneWidget,
      );
      expect(
        tester
            .getRect(find.byKey(const ValueKey('candlestick-reset-example')))
            .right,
        lessThanOrEqualTo(390),
      );
      expect(
        tester
            .getRect(find.byKey(const ValueKey('chart-page-options-button')))
            .right,
        lessThanOrEqualTo(390),
      );
      expect(
        tester
            .getRect(find.byKey(const ValueKey('candlestick-review-header')))
            .right,
        lessThanOrEqualTo(390),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
