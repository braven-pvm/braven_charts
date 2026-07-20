import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
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
    expect(find.text('Choose a candlestick example'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('candlestick-surface-selector')),
      findsOneWidget,
    );
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

  testWidgets('switches among meaningful Candlestick example presets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CandlestickChartsPage())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('candlestick-example-trend')));
    await tester.pumpAndSettle();
    var chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-reference-chart')),
    );
    var candles = chart.series.first as CandlestickChartSeries;
    expect(candles.candles, hasLength(64));
    expect(find.text('Advancing market trend'), findsOneWidget);
    expect(candles.candles.last.close, greaterThan(candles.candles.first.open));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('candlestick-gap-frequency')),
        matching: find.text('None'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('candlestick-example-volatility')),
    );
    await tester.pumpAndSettle();
    chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-reference-chart')),
    );
    candles = chart.series.first as CandlestickChartSeries;
    expect(candles.candles, hasLength(72));
    expect(find.text('High-volatility sessions'), findsOneWidget);
    expect(
      candles.candles.map((point) => point.high - point.low).reduce(math.max),
      greaterThan(20),
    );

    await tester.tap(
      find.byKey(const ValueKey('candlestick-example-gapsAndDoji')),
    );
    await tester.pumpAndSettle();
    chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-reference-chart')),
    );
    candles = chart.series.first as CandlestickChartSeries;
    expect(candles.candles, hasLength(48));
    expect(
      candles.candles.where(
        (point) => point.direction == CandlestickDirection.doji,
      ),
      hasLength(6),
    );
    expect(chart.series, hasLength(1));

    await tester.tap(find.byKey(const ValueKey('candlestick-example-density')));
    await tester.pumpAndSettle();
    chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-reference-chart')),
    );
    candles = chart.series.first as CandlestickChartSeries;
    expect(candles.candles, hasLength(2000));
    expect(candles.densityGrouping.enabled, isTrue);

    await tester.tap(
      find.byKey(const ValueKey('candlestick-example-stockComposition')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('candlestick-stock-price-chart')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('wires data, palette, overlay, and legend test controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CandlestickChartsPage())),
    );
    await tester.pumpAndSettle();

    final dynamic count = tester.widget(
      find.byKey(const ValueKey('candlestick-session-count')),
    );
    count.onChanged(24);
    final dynamic range = tester.widget(
      find.byKey(const ValueKey('candlestick-range-scale')),
    );
    range.onChanged(2.5);
    final dynamic trend = tester.widget(
      find.byKey(const ValueKey('candlestick-trend-bias')),
    );
    trend.onChanged(-0.6);
    final dynamic gaps = tester.widget(
      find.byKey(const ValueKey('candlestick-gap-frequency')),
    );
    gaps.onChanged(_testEnumValue('frequent', gaps.values));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('candlestick-palette')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    final dynamic palette = tester.widget(
      find.byKey(const ValueKey('candlestick-palette')),
    );
    palette.onChanged(_testEnumValue('blueOrange', palette.values));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('candlestick-average-window')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    final dynamic averageWindow = tester.widget(
      find.byKey(const ValueKey('candlestick-average-window')),
    );
    averageWindow.onChanged(12.0);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('candlestick-series-legend')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    final dynamic legendPosition = tester.widget(
      find.byKey(const ValueKey('candlestick-legend-position')),
    );
    legendPosition.onChanged(LegendPosition.bottomLeft);
    final dynamic seriesLegend = tester.widget(
      find.byKey(const ValueKey('candlestick-series-legend')),
    );
    seriesLegend.onChanged(false);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-reference-chart')),
    );
    final candles = chart.series.first as CandlestickChartSeries;
    expect(candles.candles, hasLength(24));
    expect(chart.theme?.candlestickTheme, CandlestickTheme.colorblindFriendly);
    expect(chart.showLegend, isFalse);
    expect(chart.legendStyle?.position, LegendPosition.bottomLeft);
    expect(chart.series.last.name, '12-session close average');
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
    expect(workbench.workbenchController, isNull);
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
    expect(workbench.workbenchController, isNull);
    expect(find.byType(ChartSourceView), findsOneWidget);
    expect(find.textContaining('CandlestickChartSeries('), findsWidgets);
    expect(find.textContaining('CandlestickDataPoint('), findsWidgets);
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
      find.byKey(const ValueKey('candlestick-coordinate-labels')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    final dynamic coordinateLabels = tester.widget(
      find.byKey(const ValueKey('candlestick-coordinate-labels')),
    );
    coordinateLabels.onChanged(false);
    final dynamic dashedCrosshair = tester.widget(
      find.byKey(const ValueKey('candlestick-crosshair-dashed')),
    );
    dashedCrosshair.onChanged(true);
    final dynamic selection = tester.widget(
      find.byKey(const ValueKey('candlestick-selection-enabled')),
    );
    selection.onChanged(false);

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
    final dynamic minWidth = tester.widget(
      find.byKey(const ValueKey('candlestick-min-width')),
    );
    minWidth.onChanged(3.0);
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
    expect(series.candlestickStyle.minBodyWidth, 3);
    expect(series.candlestickStyle.bodyCornerRadius, 4);
    expect(series.candlestickStyle.showWicks, isFalse);
    expect(chart.theme?.backgroundColor, ChartTheme.dark.backgroundColor);
    expect(chart.theme?.candlestickTheme, CandlestickTheme.dark);
    expect(chart.interactionConfig?.enableSelection, isFalse);
    expect(chart.interactionConfig?.crosshair.showCoordinateLabels, isFalse);
    expect(chart.interactionConfig?.crosshair.style.dashPattern, const [
      6.0,
      4.0,
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wires element colours, motion, replay, and tracking theme', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CandlestickChartsPage())),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('candlestick-style-recipe')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    final dynamic recipe = tester.widget(
      find.byKey(const ValueKey('candlestick-style-recipe')),
    );
    recipe.onChanged(_testEnumValue('event', recipe.values));
    await tester.pump();

    final dynamic customColours = tester.widget(
      find.byKey(const ValueKey('candlestick-custom-direction-colors')),
    );
    customColours.onChanged(true);
    await tester.pump();
    final dynamic risingBody = tester.widget(
      find.byKey(const ValueKey('candlestick-rising-body-color')),
    );
    risingBody.onChanged(const Color(0xFF2563EB));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('candlestick-custom-tracking-theme')),
      -300,
      scrollable: find.byType(Scrollable).last,
    );
    final dynamic customTracking = tester.widget(
      find.byKey(const ValueKey('candlestick-custom-tracking-theme')),
    );
    customTracking.onChanged(true);
    await tester.pump();
    final dynamic crosshairColour = tester.widget(
      find.byKey(const ValueKey('candlestick-crosshair-color')),
    );
    crosshairColour.onChanged(const Color(0xFF7C3AED));
    final dynamic tooltipBackground = tester.widget(
      find.byKey(const ValueKey('candlestick-tooltip-background')),
    );
    tooltipBackground.onChanged(const Color(0xFF111827));
    final dynamic tooltipBorderWidth = tester.widget(
      find.byKey(const ValueKey('candlestick-tooltip-border-width')),
    );
    tooltipBorderWidth.onChanged(2.0);
    final dynamic tooltipFontSize = tester.widget(
      find.byKey(const ValueKey('candlestick-tooltip-font-size')),
    );
    tooltipFontSize.onChanged(14.0);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('candlestick-tooltip-position')),
      -300,
      scrollable: find.byType(Scrollable).last,
    );
    final dynamic tooltipPosition = tester.widget(
      find.byKey(const ValueKey('candlestick-tooltip-position')),
    );
    tooltipPosition.onChanged(TooltipPosition.right);
    final dynamic followCursor = tester.widget(
      find.byKey(const ValueKey('candlestick-tooltip-follow-cursor')),
    );
    followCursor.onChanged(true);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('candlestick-update-animation')),
      -300,
      scrollable: find.byType(Scrollable).last,
    );
    final dynamic updateAnimation = tester.widget(
      find.byKey(const ValueKey('candlestick-update-animation')),
    );
    updateAnimation.onChanged(CandlestickDataUpdateAnimationMode.none);
    final dynamic duration = tester.widget(
      find.byKey(const ValueKey('candlestick-animation-duration')),
    );
    duration.onChanged(700);
    final dynamic curve = tester.widget(
      find.byKey(const ValueKey('candlestick-motion-curve')),
    );
    curve.onChanged(_testEnumValue('linear', curve.values));
    await tester.pump();

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-reference-chart')),
    );
    final series = chart.series.first as CandlestickChartSeries;
    expect(
      series.candlestickStyle.risingBodyFillColor,
      const Color(0xFF2563EB),
    );
    expect(series.candles.last.candlestickStyle?.bodyFillColor, isNotNull);
    expect(
      series.animation.dataUpdateMode,
      CandlestickDataUpdateAnimationMode.none,
    );
    expect(
      chart.theme?.animationTheme.dataUpdateDuration,
      const Duration(milliseconds: 700),
    );
    expect(chart.theme?.animationTheme.dataUpdateCurve, Curves.linear);
    expect(
      chart.interactionConfig?.crosshair.style.lineColor,
      const Color(0xFF7C3AED),
    );
    expect(
      chart.interactionConfig?.tooltip.style.backgroundColor,
      const Color(0xFF111827),
    );
    expect(chart.interactionConfig?.tooltip.style.borderWidth, 2);
    expect(chart.interactionConfig?.tooltip.style.fontSize, 14);
    expect(
      chart.interactionConfig?.tooltip.preferredPosition,
      TooltipPosition.right,
    );
    expect(chart.interactionConfig?.tooltip.followCursor, isTrue);

    await tester.ensureVisible(
      find.byKey(const ValueKey('candlestick-options-replay')),
    );
    await tester.tap(find.byKey(const ValueKey('candlestick-options-replay')));
    await tester.pump(const Duration(milliseconds: 32));
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

  testWidgets('groups dense rendering while Workbench keeps raw OHLC rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CandlestickChartsPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final dynamic stressData = tester.widget(
      find.byKey(const ValueKey('candlestick-density-stress-data')),
    );
    stressData.onChanged(true);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('candlestick-target-group-width')),
      300,
      scrollable: find.byType(Scrollable).last,
    );

    final dynamic targetWidth = tester.widget(
      find.byKey(const ValueKey('candlestick-target-group-width')),
    );
    targetWidth.onChanged(8.0);
    final dynamic minimumSize = tester.widget(
      find.byKey(const ValueKey('candlestick-minimum-group-size')),
    );
    minimumSize.onChanged(4.0);
    await tester.pump(const Duration(milliseconds: 300));

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-reference-chart')),
    );
    final candles = chart.series.first as CandlestickChartSeries;
    expect(candles.points, hasLength(2000));
    expect(candles.densityGrouping.enabled, isTrue);
    expect(candles.densityGrouping.targetGroupWidth, 8);
    expect(candles.densityGrouping.minimumPointsPerGroup, 4);
    expect(find.text('2,000-session density stress'), findsOneWidget);

    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Data')),
    );
    await tester.pumpAndSettle();
    final table = tester.widget<ChartDataTable>(find.byType(ChartDataTable));
    expect(table.model!.candlestickRows, hasLength(2000));
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
      expect(navigator.interactionGroupOptions.synchronizeCursor, isFalse);
      expect(navigator.interactionGroupOptions.synchronizeViewport, isFalse);
      expect(navigator.persistentRangeAnnotationHandles, isTrue);
      expect(navigator.annotationController, isNotNull);
      expect(navigator.onAnnotationDragUpdate, isNotNull);
      expect(navigator.onAnnotationDragged, isNotNull);
      expect(
        navigator.annotationController!.selectedAnnotationId,
        'navigator-window',
      );
      expect(
        find.byKey(const ValueKey('candlestick-stock-navigator-range')),
        findsNothing,
      );
      expect(
        find.text('Drag window to pan · drag either edge to zoom'),
        findsOneWidget,
      );
      navigator.annotationController!.clearSelection();
      await tester.pump();
      final navigatorRender = tester.renderObject<ChartRenderBox>(
        find.descendant(
          of: find.byKey(const ValueKey('candlestick-stock-navigator')),
          matching: find.byWidgetPredicate(
            (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
          ),
        ),
      );
      expect(
        navigatorRender.debugElements.map((element) => element.id),
        containsAll(const [
          'navigator-window_handle_left',
          'navigator-window_handle_right',
        ]),
      );
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
    var navigator = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-stock-navigator')),
    );
    var ordinalWindow =
        navigator.annotationController!.getAnnotation('navigator-window')
            as RangeAnnotation;
    expect(ordinalWindow.startX, group.viewport!.min);
    expect(ordinalWindow.endX, group.viewport!.max);

    await tester.tap(find.byKey(const ValueKey('candlestick-range-all')));
    await tester.pump();
    expect(group.viewport, const ChartXViewport(min: 0, max: 419));
    ordinalWindow =
        navigator.annotationController!.getAnnotation('navigator-window')
            as RangeAnnotation;
    expect(ordinalWindow.startX, 0);
    expect(ordinalWindow.endX, 419);

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

    navigator = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-stock-navigator')),
    );
    final interactiveWindow =
        navigator.annotationController!.getAnnotation('navigator-window')
            as RangeAnnotation;
    expect(interactiveWindow.allowDragging, isTrue);
    expect(interactiveWindow.allowEditing, isFalse);
    expect(interactiveWindow.snapToValue, isTrue);
    navigator.onAnnotationDragged!(
      interactiveWindow.copyWith(startX: 100, endX: 160),
      Offset.zero,
    );
    await tester.pump();
    expect(group.viewport, const ChartXViewport(min: 100, max: 160));
    navigator = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-stock-navigator')),
    );
    ordinalWindow =
        navigator.annotationController!.getAnnotation('navigator-window')
            as RangeAnnotation;
    expect(ordinalWindow.startX, 100);
    expect(ordinalWindow.endX, 160);

    navigator.onAnnotationDragged!(
      ordinalWindow.copyWith(startX: 120, endX: 180),
      Offset.zero,
    );
    await tester.pump();
    expect(group.viewport, const ChartXViewport(min: 120, max: 180));

    navigator.onAnnotationDragged!(
      ordinalWindow.copyWith(startX: 120, endX: 210),
      Offset.zero,
    );
    await tester.pump();
    expect(group.viewport, const ChartXViewport(min: 120, max: 210));

    navigator.onAnnotationDragged!(
      ordinalWindow.copyWith(startX: -20, endX: 70),
      Offset.zero,
    );
    await tester.pump();
    expect(group.viewport, const ChartXViewport(min: 0, max: 90));

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
    final elapsedWindow =
        navigator.annotationController!.getAnnotation('navigator-window')
            as RangeAnnotation;
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

  testWidgets(
    'stock navigator body pans and its edge zooms the shared viewport',
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

      final navigatorFinder = find.byKey(
        const ValueKey('candlestick-stock-navigator'),
      );
      final renderFinder = find.descendant(
        of: navigatorFinder,
        matching: find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
        ),
      );
      ChartRenderBox renderBox() =>
          tester.renderObject<ChartRenderBox>(renderFinder);
      Offset globalElementPoint(
        String elementId,
        Offset Function(Rect bounds) pointForBounds,
      ) {
        final box = renderBox();
        final element = box.debugElements.firstWhere(
          (candidate) => candidate.id == elementId,
        );
        return tester.getTopLeft(renderFinder) +
            box.plotToWidget(pointForBounds(element.bounds));
      }

      final price = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('candlestick-stock-price-chart')),
      );
      final group = price.interactionGroupController!;
      final original = group.viewport!;
      final windowCenter = globalElementPoint(
        'navigator-window',
        (bounds) => bounds.center,
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(windowCenter);
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        tester
            .widgetList<MouseRegion>(
              find.descendant(
                of: navigatorFinder,
                matching: find.byType(MouseRegion),
              ),
            )
            .map((region) => region.cursor),
        contains(SystemMouseCursors.grab),
      );
      await mouse.down(windowCenter);
      await tester.pump();
      expect(
        tester
            .widgetList<MouseRegion>(
              find.descendant(
                of: navigatorFinder,
                matching: find.byType(MouseRegion),
              ),
            )
            .map((region) => region.cursor),
        contains(SystemMouseCursors.grabbing),
      );
      await mouse.moveBy(const Offset(-120, 0));
      await tester.pump();

      final pannedDuringDrag = group.viewport!;
      expect(pannedDuringDrag.min, lessThan(original.min));
      expect(
        pannedDuringDrag.max - pannedDuringDrag.min,
        original.max - original.min,
      );
      expect(group.cursorX, isNull);

      await mouse.up();
      await tester.pumpAndSettle();

      final panned = group.viewport!;
      expect(panned.min, lessThan(original.min));
      expect(panned.max - panned.min, original.max - original.min);

      await mouse.moveTo(
        globalElementPoint(
          'navigator-window_handle_left',
          (bounds) => bounds.center,
        ),
      );
      await mouse.down(
        globalElementPoint(
          'navigator-window_handle_left',
          (bounds) => bounds.center,
        ),
      );
      await mouse.moveBy(const Offset(-70, 0));
      await tester.pump();

      final resizedDuringDrag = group.viewport!;
      expect(resizedDuringDrag.min, lessThan(panned.min));
      expect(resizedDuringDrag.max, panned.max);
      expect(
        resizedDuringDrag.max - resizedDuringDrag.min,
        greaterThan(panned.max - panned.min),
      );
      expect(group.cursorX, isNull);

      await mouse.up();
      await tester.pumpAndSettle();

      final resized = group.viewport!;
      expect(resized.min, lessThan(panned.min));
      expect(resized.max, panned.max);
      expect(resized.max - resized.min, greaterThan(panned.max - panned.min));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('stock panes honour shared visual and interaction controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CandlestickChartsPage())),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('candlestick-example-stockComposition')),
    );
    await tester.pumpAndSettle();

    final dynamic tracking = tester.widget(
      find.byKey(const ValueKey('candlestick-tracking-enabled')),
    );
    tracking.onChanged(false);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('candlestick-show-average')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    final dynamic average = tester.widget(
      find.byKey(const ValueKey('candlestick-show-average')),
    );
    average.onChanged(false);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('candlestick-series-legend')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    final dynamic legend = tester.widget(
      find.byKey(const ValueKey('candlestick-series-legend')),
    );
    legend.onChanged(false);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('candlestick-theme')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    final dynamic theme = tester.widget(
      find.byKey(const ValueKey('candlestick-theme')),
    );
    theme.onChanged(ThemePreset.dark);
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
    expect(price.series, hasLength(1));
    expect(price.showLegend, isFalse);
    expect(price.theme?.backgroundColor, ChartTheme.dark.backgroundColor);
    expect(price.interactionConfig?.crosshair.enabled, isFalse);
    expect(volume.theme?.backgroundColor, ChartTheme.dark.backgroundColor);
    expect(volume.interactionConfig?.crosshair.enabled, isFalse);
    expect(navigator.theme?.backgroundColor, ChartTheme.dark.backgroundColor);
    expect(navigator.interactionConfig?.crosshair.enabled, isFalse);
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

T _testEnumValue<T>(String name, List<T> values) =>
    values.singleWhere((value) => value.toString().split('.').last == name);
