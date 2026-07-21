import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

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

    final chartFinder = find.byKey(
      const ValueKey('candlestick-reference-chart'),
    );
    final chart = tester.widget<BravenChartPlus>(chartFinder);
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
    expect(chart.interactionConfig?.showFocusBorder, isFalse);
    expect(chart.interactionConfig?.enableFocusOnHover, isFalse);
    expect(chart.interactionConfig?.tooltip.enabled, isFalse);
    expect(chart.interactionConfig?.crosshair.showTrackingTooltip, isTrue);
    expect(chart.yAxis?.labelFormatter?.call(133.314099982216), '133.31');

    final chartFocus = tester
        .widgetList<Focus>(
          find.descendant(of: chartFinder, matching: find.byType(Focus)),
        )
        .firstWhere((focus) => focus.focusNode != null)
        .focusNode!;
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(chartFinder));
    await tester.pump();
    expect(chartFocus.hasFocus, isFalse);

    await mouse.down(tester.getCenter(chartFinder));
    await mouse.up();
    await tester.pump();
    expect(chartFocus.hasFocus, isTrue);
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

    await tester.tap(find.byKey(const ValueKey('candlestick-example-events')));
    await tester.pumpAndSettle();
    chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-reference-chart')),
    );
    candles = chart.series.first as CandlestickChartSeries;
    expect(candles.candles, hasLength(56));
    expect(find.text('Events and price levels'), findsOneWidget);
    expect(chart.annotations, hasLength(3));
    expect(
      chart.annotations.map((annotation) => annotation.id),
      containsAll(const [
        'candlestick-event-window',
        'candlestick-risk-level',
        'candlestick-market-event',
      ]),
    );
    final event = chart.annotations.whereType<PointAnnotation>().single;
    expect(event.seriesId, 'reference-ohlc');

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

  testWidgets('wires contextual annotation visibility and styling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CandlestickChartsPage())),
    );
    await tester.pumpAndSettle();

    final dynamic context = tester.widget(
      find.byKey(const ValueKey('candlestick-market-context')),
    );
    context.onChanged(true);
    await tester.pump();
    final dynamic thresholdColour = tester.widget(
      find.byKey(const ValueKey('candlestick-context-threshold-color')),
    );
    thresholdColour.onChanged(const Color(0xFFDC2626));
    final dynamic windowColour = tester.widget(
      find.byKey(const ValueKey('candlestick-context-window-color')),
    );
    windowColour.onChanged(const Color(0xFF059669));
    final dynamic eventColour = tester.widget(
      find.byKey(const ValueKey('candlestick-context-event-color')),
    );
    eventColour.onChanged(const Color(0xFF7C3AED));
    final dynamic strokeWidth = tester.widget(
      find.byKey(const ValueKey('candlestick-context-line-width')),
    );
    strokeWidth.onChanged(2.5);
    final dynamic dashed = tester.widget(
      find.byKey(const ValueKey('candlestick-context-dashed')),
    );
    dashed.onChanged(false);
    await tester.pump();

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-reference-chart')),
    );
    final threshold = chart.annotations.whereType<ThresholdAnnotation>().single;
    final range = chart.annotations.whereType<RangeAnnotation>().single;
    final event = chart.annotations.whereType<PointAnnotation>().single;
    expect(threshold.lineColor, const Color(0xFFDC2626));
    expect(threshold.lineWidth, 2.5);
    expect(threshold.dashPattern, isNull);
    expect(range.fillColor?.a, closeTo(.1, .001));
    expect(range.fillColor?.r, closeTo(const Color(0xFF059669).r, .001));
    expect(range.fillColor?.g, closeTo(const Color(0xFF059669).g, .001));
    expect(range.fillColor?.b, closeTo(const Color(0xFF059669).b, .001));
    expect(range.style.borderWidth, 2.5);
    expect(event.markerColor, const Color(0xFF7C3AED));
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
    final priceFormatter = ChartFormatterDescriptor.fromDocument(
      workbench.documentOptions.yAxisFormatterDescriptors['y']!,
    );
    expect(
      const ChartFormatterRegistry()
          .resolve(priceFormatter)
          .formatter(133.314099982216),
      '133.31',
    );
    expect(find.text('Open'), findsWidgets);
    expect(find.text('High'), findsWidgets);
    expect(find.text('Low'), findsWidgets);
    expect(find.text('Close'), findsWidgets);
    expect(find.text('Change %'), findsOneWidget);
    expect(find.text('228.00'), findsWidgets);

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
    expect(
      find.textContaining(
        'Formatter "showcase.candlestick.session" is not registered',
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps crosshair, hover, and pinned OHLC details independent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CandlestickChartsPage())),
    );
    await tester.pumpAndSettle();

    var chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-reference-chart')),
    );
    expect(chart.interactionConfig?.crosshair.showTrackingTooltip, isTrue);
    expect(chart.interactionConfig?.tooltip.enabled, isFalse);
    expect(
      find.byKey(const ValueKey('candlestick-pinned-summary-card')),
      findsNothing,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('candlestick-point-tooltip')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    final dynamic pointTooltip = tester.widget(
      find.byKey(const ValueKey('candlestick-point-tooltip')),
    );
    pointTooltip.onChanged(true);
    final dynamic pinnedSummary = tester.widget(
      find.byKey(const ValueKey('candlestick-pinned-summary')),
    );
    pinnedSummary.onChanged(true);
    final dynamic trackingTooltip = tester.widget(
      find.byKey(const ValueKey('candlestick-tracking-tooltip')),
    );
    trackingTooltip.onChanged(false);
    await tester.pump();

    chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-reference-chart')),
    );
    expect(chart.interactionConfig?.crosshair.showTrackingTooltip, isFalse);
    expect(chart.interactionConfig?.tooltip.enabled, isTrue);
    expect(
      find.byKey(const ValueKey('candlestick-pinned-summary-card')),
      findsOneWidget,
    );

    final candles = (chart.series.first as CandlestickChartSeries).candles;
    final candle = candles[1];
    final inBetweenX = candles.first.x + (candle.x - candles.first.x) * .6;
    chart.onDataXCursorChanged?.call(inBetweenX);
    await tester.pump();
    final summary = find.byKey(
      const ValueKey('candlestick-pinned-summary-card'),
    );
    expect(
      find.descendant(
        of: summary,
        matching: find.text('\$${candle.open.toStringAsFixed(2)}'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: summary,
        matching: find.text('\$${candle.high.toStringAsFixed(2)}'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('moves and styles the pinned summary as a chart annotation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CandlestickChartsPage())),
    );
    await tester.pumpAndSettle();

    final optionsScroll = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('candlestick-pinned-summary')),
      300,
      scrollable: optionsScroll,
    );
    final dynamic pinnedSummary = tester.widget(
      find.byKey(const ValueKey('candlestick-pinned-summary')),
    );
    pinnedSummary.onChanged(true);
    await tester.pump();

    final dynamic presentation = tester.widget(
      find.byKey(const ValueKey('candlestick-pinned-summary-presentation')),
    );
    presentation.onChanged(_testEnumValue('annotation', presentation.values));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('candlestick-pinned-summary-card')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('candlestick-pinned-summary-draggable')),
      findsOneWidget,
    );

    for (final entry in <(String, Color)>[
      ('candlestick-summary-background', const Color(0xFF111827)),
      ('candlestick-summary-border', const Color(0xFF7C3AED)),
      ('candlestick-summary-text', const Color(0xFFFFFFFF)),
      ('candlestick-summary-accent', const Color(0xFFEC4899)),
    ]) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey(entry.$1)),
        300,
        scrollable: optionsScroll,
      );
      final dynamic palette = tester.widget(find.byKey(ValueKey(entry.$1)));
      palette.onChanged(entry.$2);
      await tester.pump();
    }

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('candlestick-summary-opacity')),
      300,
      scrollable: optionsScroll,
    );
    final dynamic opacity = tester.widget(
      find.byKey(const ValueKey('candlestick-summary-opacity')),
    );
    opacity.onChanged(1.0);
    final dynamic borderWidth = tester.widget(
      find.byKey(const ValueKey('candlestick-summary-border-width')),
    );
    borderWidth.onChanged(2.0);
    final dynamic cornerRadius = tester.widget(
      find.byKey(const ValueKey('candlestick-summary-corner-radius')),
    );
    cornerRadius.onChanged(12.0);
    final dynamic padding = tester.widget(
      find.byKey(const ValueKey('candlestick-summary-padding')),
    );
    padding.onChanged(16.0);
    final dynamic fontSize = tester.widget(
      find.byKey(const ValueKey('candlestick-summary-font-size')),
    );
    fontSize.onChanged(14.0);
    await tester.pump();

    var chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-reference-chart')),
    );
    var annotation = chart.annotations.whereType<TextAnnotation>().singleWhere(
      (value) => value.label == 'Pinned OHLC summary',
    );
    expect(annotation.allowDragging, isTrue);
    expect(annotation.position, const Offset(96, 48));
    expect(annotation.style.backgroundColor, const Color(0xFF111827));
    expect(annotation.style.borderColor, const Color(0xFF7C3AED));
    expect(annotation.style.borderWidth, 2);
    expect(annotation.style.borderRadius, BorderRadius.circular(12));
    expect(annotation.style.padding, const EdgeInsets.all(16));
    expect(annotation.style.textStyle.fontSize, 14);
    expect(annotation.plainText, contains('Open'));
    expect(annotation.plainText, contains(RegExp(r'\$\d+\.\d{2}')));

    final firstCandle =
        (chart.series.first as CandlestickChartSeries).candles.first;
    chart.onPointHover?.call(firstCandle, 'candles');
    await tester.pump();
    chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-reference-chart')),
    );
    annotation = chart.annotations.whereType<TextAnnotation>().singleWhere(
      (value) => value.label == 'Pinned OHLC summary',
    );
    expect(
      annotation.plainText,
      contains('\$${firstCandle.open.toStringAsFixed(2)}'),
    );

    chart.onAnnotationDragged?.call(annotation, const Offset(180, 96));
    await tester.pump();
    chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-reference-chart')),
    );
    annotation = chart.annotations.whereType<TextAnnotation>().singleWhere(
      (value) => value.label == 'Pinned OHLC summary',
    );
    expect(annotation.position, const Offset(180, 96));

    final dynamic backgroundPalette = tester.widget(
      find.byKey(const ValueKey('candlestick-summary-background')),
    );
    final dynamic borderPalette = tester.widget(
      find.byKey(const ValueKey('candlestick-summary-border')),
    );
    backgroundPalette.onChanged(null);
    borderPalette.onChanged(null);
    await tester.pump();
    chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('candlestick-reference-chart')),
    );
    annotation = chart.annotations.whereType<TextAnnotation>().singleWhere(
      (value) => value.label == 'Pinned OHLC summary',
    );
    expect(annotation.style.backgroundColor, Colors.transparent);
    expect(annotation.style.borderColor, Colors.transparent);
    expect(tester.takeException(), isNull);
  });

  testWidgets('moves the pinned overlay between chart corners', (tester) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CandlestickChartsPage())),
    );
    await tester.pumpAndSettle();

    final optionsScroll = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('candlestick-pinned-summary')),
      300,
      scrollable: optionsScroll,
    );
    final dynamic pinnedSummary = tester.widget(
      find.byKey(const ValueKey('candlestick-pinned-summary')),
    );
    pinnedSummary.onChanged(true);
    await tester.pump();
    final dynamic corner = tester.widget(
      find.byKey(const ValueKey('candlestick-pinned-summary-corner')),
    );
    corner.onChanged(_testEnumValue('bottomRight', corner.values));
    await tester.pump();

    final positioned = tester.widget<Positioned>(
      find.byKey(const ValueKey('candlestick-pinned-summary-position')),
    );
    expect(positioned.top, isNull);
    expect(positioned.left, isNull);
    expect(positioned.bottom, 12);
    expect(positioned.right, 12);

    final summary = find.byKey(
      const ValueKey('candlestick-pinned-summary-card'),
    );
    expect(tester.getSize(summary).width, 168);

    final dynamic backgroundPalette = tester.widget(
      find.byKey(const ValueKey('candlestick-summary-background')),
    );
    final dynamic borderPalette = tester.widget(
      find.byKey(const ValueKey('candlestick-summary-border')),
    );
    backgroundPalette.onChanged(null);
    borderPalette.onChanged(null);
    await tester.pump();

    final card = tester.widget<Container>(summary);
    final decoration = card.decoration! as BoxDecoration;
    expect(decoration.color, Colors.transparent);
    expect((decoration.border! as Border).top.color, Colors.transparent);
    expect(decoration.boxShadow, isEmpty);
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
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('candlestick-selection-enabled')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
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
    final dynamic selectionColour = tester.widget(
      find.byKey(const ValueKey('candlestick-selection-color')),
    );
    selectionColour.onChanged(const Color(0xFFDB2777));
    final dynamic focusColour = tester.widget(
      find.byKey(const ValueKey('candlestick-focus-color')),
    );
    focusColour.onChanged(const Color(0xFF0891B2));
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
      find.byKey(const ValueKey('candlestick-point-tooltip')),
      -300,
      scrollable: find.byType(Scrollable).last,
    );
    final dynamic pointTooltip = tester.widget(
      find.byKey(const ValueKey('candlestick-point-tooltip')),
    );
    pointTooltip.onChanged(true);
    await tester.pump();
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
      chart.theme?.interactionTheme.selectionColor,
      const Color(0xFFDB2777),
    );
    expect(
      chart.theme?.interactionTheme.crosshairColor,
      const Color(0xFF0891B2),
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

  testWidgets(
    'uses annotation palettes with clear and selected-colour toggle semantics',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CandlestickChartsPage())),
      );
      await tester.pumpAndSettle();

      final optionsScroll = find.byType(Scrollable).last;
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('candlestick-custom-direction-colors')),
        300,
        scrollable: optionsScroll,
      );
      final dynamic customColours = tester.widget(
        find.byKey(const ValueKey('candlestick-custom-direction-colors')),
      );
      customColours.onChanged(true);
      await tester.pump();

      final risingPalette = find.byKey(
        const ValueKey('candlestick-rising-body-color'),
      );
      expect(
        find.descendant(
          of: risingPalette,
          matching: find.byType(ChartColorPalette),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('candlestick-rising-body-color-custom')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('candlestick-rising-body-color-clear')),
      );
      await tester.pump();
      var chart = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('candlestick-reference-chart')),
      );
      var series = chart.series.first as CandlestickChartSeries;
      expect(series.candlestickStyle.risingBodyFillColor, isNull);

      final blueSwatch = find.byKey(
        ValueKey('candlestick-rising-body-color-${Colors.blue.toARGB32()}'),
      );
      await tester.tap(blueSwatch);
      await tester.pump();
      chart = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('candlestick-reference-chart')),
      );
      series = chart.series.first as CandlestickChartSeries;
      expect(series.candlestickStyle.risingBodyFillColor, Colors.blue);

      await tester.tap(blueSwatch);
      await tester.pump();
      chart = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('candlestick-reference-chart')),
      );
      series = chart.series.first as CandlestickChartSeries;
      expect(series.candlestickStyle.risingBodyFillColor, isNull);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('candlestick-average-color')),
        300,
        scrollable: optionsScroll,
      );
      final averageClear = find.byKey(
        const ValueKey('candlestick-average-color-clear'),
      );
      await tester.ensureVisible(averageClear);
      await tester.pumpAndSettle();
      await tester.tap(averageClear);
      await tester.pump();
      chart = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('candlestick-reference-chart')),
      );
      expect((chart.series.last as LineChartSeries).color, isNull);
      expect(tester.takeException(), isNull);
    },
  );

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
      final navigator = tester.widget<CartesianNavigator>(
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
      expect(navigator.overviewSeries, isA<AreaChartSeries>());
      expect(navigator.fullDomain, const ChartXViewport(min: 0, max: 419));
      expect(
        navigator.snapPolicy.mode,
        CartesianNavigatorSnapMode.orderedValues,
      );
      expect(
        find.text('Drag window to pan · drag either edge to zoom'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cartesian-navigator-start-handle')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cartesian-navigator-end-handle')),
        findsOneWidget,
      );
      expect(price.yAxis?.unit, 'USD');
      expect(volume.yAxis?.unit, 'M');
      expect(price.yAxis?.minWidth, 64);
      expect(price.yAxis?.maxWidth, 64);
      expect(volume.yAxis?.minWidth, 64);
      expect(volume.yAxis?.maxWidth, 64);

      final priceRect = tester.getRect(
        find.byKey(const ValueKey('candlestick-stock-price-chart')),
      );
      final volumeRect = tester.getRect(
        find.byKey(const ValueKey('candlestick-stock-volume-chart')),
      );
      final navigatorChartRect = tester.getRect(
        find.byKey(const ValueKey('cartesian-navigator-overview')),
      );
      final plotLefts = [
        priceRect.left + 64,
        volumeRect.left + 10,
        navigatorChartRect.left + 10,
      ];
      final plotRights = [
        priceRect.right - 10,
        volumeRect.right - 64,
        navigatorChartRect.right - 10,
      ];
      for (final plotLeft in plotLefts.skip(1)) {
        expect(plotLeft, closeTo(plotLefts.first, .01));
      }
      for (final plotRight in plotRights.skip(1)) {
        expect(plotRight, closeTo(plotRights.first, .01));
      }
      expect(
        tester
            .getSize(find.byKey(const ValueKey('candlestick-stock-navigator')))
            .height,
        lessThan(110),
      );
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
    var navigator = tester.widget<CartesianNavigator>(
      find.byKey(const ValueKey('candlestick-stock-navigator')),
    );
    expect(navigator.fullDomain, const ChartXViewport(min: 0, max: 419));
    expect(navigator.snapPolicy.values.first, 0);
    expect(navigator.snapPolicy.values.last, 419);

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

    navigator = tester.widget<CartesianNavigator>(
      find.byKey(const ValueKey('candlestick-stock-navigator')),
    );
    expect(navigator.behavior.allowPan, isTrue);
    expect(navigator.behavior.allowResize, isTrue);
    group.setViewport(const ChartXViewport(min: 100, max: 160));
    await tester.pump();
    expect(group.viewport, const ChartXViewport(min: 100, max: 160));

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
    navigator = tester.widget<CartesianNavigator>(
      find.byKey(const ValueKey('candlestick-stock-navigator')),
    );
    expect(navigator.fullDomain.min, elapsed.candleAt(0).x);
    expect(navigator.fullDomain.max, elapsed.candleAt(419).x);
    expect(navigator.snapPolicy.values.first, elapsed.candleAt(0).x);
    expect(navigator.snapPolicy.values.last, elapsed.candleAt(419).x);

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
      final windowFinder = find.byKey(
        const ValueKey('cartesian-navigator-window'),
      );
      final startHandleFinder = find.byKey(
        const ValueKey('cartesian-navigator-start-handle'),
      );

      final price = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('candlestick-stock-price-chart')),
      );
      final group = price.interactionGroupController!;
      final original = group.viewport!;
      final windowCenter = tester.getCenter(windowFinder);

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
      await mouse.moveBy(const Offset(-20, 0));
      await mouse.moveBy(const Offset(-100, 0));
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

      await mouse.moveTo(tester.getCenter(startHandleFinder));
      await mouse.down(tester.getCenter(startHandleFinder));
      await mouse.moveBy(const Offset(-20, 0));
      await mouse.moveBy(const Offset(-50, 0));
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
    final dynamic selection = tester.widget(
      find.byKey(const ValueKey('candlestick-selection-enabled')),
    );
    selection.onChanged(false);
    final dynamic keyboard = tester.widget(
      find.byKey(const ValueKey('candlestick-keyboard-enabled')),
    );
    keyboard.onChanged(false);
    final dynamic focusBorder = tester.widget(
      find.byKey(const ValueKey('candlestick-focus-border')),
    );
    focusBorder.onChanged(false);

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
      find.byKey(const ValueKey('candlestick-y-axis-position')),
      -300,
      scrollable: find.byType(Scrollable).last,
    );
    final dynamic yAxisPosition = tester.widget(
      find.byKey(const ValueKey('candlestick-y-axis-position')),
    );
    yAxisPosition.onChanged(YAxisPosition.hidden);
    final dynamic xTickCount = tester.widget(
      find.byKey(const ValueKey('candlestick-x-tick-count')),
    );
    xTickCount.onChanged(5);
    final dynamic xLabels = tester.widget(
      find.byKey(const ValueKey('candlestick-x-labels')),
    );
    xLabels.onChanged(false);
    final dynamic yLabels = tester.widget(
      find.byKey(const ValueKey('candlestick-y-labels')),
    );
    yLabels.onChanged(false);

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
    final navigator = tester.widget<CartesianNavigator>(
      find.byKey(const ValueKey('candlestick-stock-navigator')),
    );
    expect(price.series, hasLength(1));
    expect(price.showLegend, isFalse);
    expect(price.theme?.backgroundColor, ChartTheme.dark.backgroundColor);
    expect(price.interactionConfig?.crosshair.enabled, isFalse);
    expect(price.interactionConfig?.enableSelection, isFalse);
    expect(price.interactionConfig?.showFocusBorder, isFalse);
    expect(price.interactionConfig?.keyboard.enabled, isFalse);
    expect(price.xAxisConfig?.tickCount, 5);
    expect(price.xAxisConfig?.showTickLabels, isFalse);
    expect(price.yAxis?.position, YAxisPosition.hidden);
    expect(price.yAxis?.showTickLabels, isFalse);
    expect(volume.theme?.backgroundColor, ChartTheme.dark.backgroundColor);
    expect(volume.interactionConfig?.crosshair.enabled, isFalse);
    expect(volume.interactionConfig?.enableSelection, isFalse);
    expect(volume.interactionConfig?.showFocusBorder, isFalse);
    expect(volume.interactionConfig?.keyboard.enabled, isFalse);
    expect(volume.yAxis?.showTickLabels, isFalse);
    expect(navigator.theme?.backgroundColor, ChartTheme.dark.backgroundColor);
    final navigatorChart = tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('candlestick-stock-navigator')),
        matching: find.byKey(const ValueKey('cartesian-navigator-overview')),
      ),
    );
    expect(navigatorChart.interactionConfig?.crosshair.enabled, isFalse);
    expect(navigatorChart.xAxisConfig?.visible, isFalse);
    expect(navigatorChart.xAxisConfig?.showTickLabels, isFalse);
    expect(
      find.byKey(const ValueKey('candlestick-direction-key')),
      findsNothing,
    );
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
    await tester.ensureVisible(
      find.byKey(const ValueKey('candlestick-example-stockComposition')),
    );
    await tester.tap(
      find.byKey(const ValueKey('candlestick-example-stockComposition')),
    );
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
