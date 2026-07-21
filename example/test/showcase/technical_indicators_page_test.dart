import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:braven_charts_example/showcase/pages/technical_indicators_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, {double width = 1500}) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(width * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TechnicalIndicatorsPage())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders a native synchronized financial study stack', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Technical Indicators'), findsOneWidget);
    expect(find.text('Choose a financial study composition'), findsOneWidget);
    expect(find.byKey(const ValueKey('financial-price-chart')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('financial-volume-chart')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('financial-macd-chart')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('financial-momentum-chart')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('financial-navigator')), findsOneWidget);

    final price = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('financial-price-chart')),
    );
    final volume = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('financial-volume-chart')),
    );
    final macd = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('financial-macd-chart')),
    );
    final momentum = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('financial-momentum-chart')),
    );

    expect(price.series.whereType<CandlestickChartSeries>(), hasLength(1));
    expect(price.series.whereType<RangeAreaChartSeries>(), hasLength(1));
    expect(price.series.whereType<LineChartSeries>(), hasLength(2));
    final volatility = price.series.whereType<RangeAreaChartSeries>().single;
    expect(volatility.intervals, hasLength(180));
    expect(volatility.intervals.take(19).every((point) => point.isGap), isTrue);
    expect(volatility.intervals[19].isGap, isFalse);
    expect(
      volatility.intervals[19].low,
      lessThan(volatility.intervals[19].high!),
    );
    expect(volume.series.whereType<BarChartSeries>(), hasLength(1));
    expect(macd.series.whereType<BarChartSeries>(), hasLength(1));
    expect(macd.series.whereType<LineChartSeries>(), hasLength(2));
    expect(momentum.series.whereType<LineChartSeries>(), hasLength(2));
    expect(
      price.interactionGroupController,
      same(volume.interactionGroupController),
    );
    expect(
      price.interactionGroupController,
      same(macd.interactionGroupController),
    );
    expect(
      price.interactionGroupController,
      same(momentum.interactionGroupController),
    );
    expect(price.yAxis?.minWidth, 64);
    expect(volume.yAxis?.minWidth, 64);
    expect(macd.yAxis?.minWidth, 64);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared financial cursor aligns in global screen space', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('financial-range-all')));
    await tester.pumpAndSettle();

    final renderElements = find
        .descendant(
          of: find.byType(BravenChartPlus),
          matching: find.byWidgetPredicate(
            (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
          ),
        )
        .evaluate()
        .toList();
    final renderBoxes = renderElements
        .map((element) => element.renderObject! as ChartRenderBox)
        .toList();
    expect(renderBoxes, hasLength(4));

    final plotLefts = <double>[
      for (final renderBox in renderBoxes)
        renderBox.localToGlobal(renderBox.plotToWidget(Offset.zero)).dx,
    ];
    final plotRights = <double>[
      for (final renderBox in renderBoxes)
        renderBox
            .localToGlobal(
              renderBox.plotToWidget(Offset(renderBox.plotWidth, 0)),
            )
            .dx,
    ];
    for (var index = 1; index < renderBoxes.length; index++) {
      expect(
        plotLefts[index],
        closeTo(plotLefts.first, .01),
        reason: 'every financial pane must share one global plot left edge',
      );
      expect(
        plotRights[index],
        closeTo(plotRights.first, .01),
        reason: 'every financial pane must share one global plot right edge',
      );
      expect(
        renderBoxes[index].transform!.dataXMin,
        closeTo(renderBoxes.first.transform!.dataXMin, .0001),
      );
      expect(
        renderBoxes[index].transform!.dataXMax,
        closeTo(renderBoxes.first.transform!.dataXMax, .0001),
      );
    }

    final sourceFinder = find.byElementPredicate(
      (element) => element == renderElements.first,
    );
    final source = renderBoxes.first;
    final viewport = source.transform!;
    final dataX = (viewport.dataXMin + viewport.dataXMax) / 2;
    final local = source.plotToWidget(
      source.transform!.dataToPlot(
        dataX,
        (viewport.dataYMin + viewport.dataYMax) / 2,
      ),
    );
    final pointer = await tester.createGesture();
    addTearDown(pointer.removePointer);
    await pointer.addPointer(location: Offset.zero);
    await pointer.moveTo(tester.getTopLeft(sourceFinder) + local);
    await tester.pump();

    final globalCursorXs = <double>[
      for (var index = 0; index < renderBoxes.length; index++)
        tester
                .getTopLeft(
                  find.byElementPredicate(
                    (element) => element == renderElements[index],
                  ),
                )
                .dx +
            renderBoxes[index].debugSynchronizedCursorPosition!.dx,
    ];
    for (final cursorX in globalCursorXs.skip(1)) {
      expect(
        cursorX,
        closeTo(globalCursorXs.first, .01),
        reason: 'every pane must render one shared data X at the same screen X',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('preset and composition controls change visible studies', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(
      find.byKey(const ValueKey('financial-preset-trendAndVolume')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('financial-volume-chart')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('financial-macd-chart')), findsNothing);
    expect(
      find.byKey(const ValueKey('financial-momentum-chart')),
      findsNothing,
    );

    final volumeToggle = find.descendant(
      of: find.byKey(const ValueKey('financial-show-volume')),
      matching: find.byType(SwitchListTile),
    );
    await tester.tap(volumeToggle);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('financial-volume-chart')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('volatility preset and toggle use one native Range Area series', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const ValueKey('financial-preset-volatility')));
    await tester.pumpAndSettle();

    final price = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('financial-price-chart')),
    );
    expect(price.series.whereType<CandlestickChartSeries>(), hasLength(1));
    expect(price.series.whereType<RangeAreaChartSeries>(), hasLength(1));
    expect(price.series.whereType<LineChartSeries>(), hasLength(1));
    expect(
      find.byKey(const ValueKey('financial-volume-chart')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('financial-macd-chart')), findsNothing);
    expect(
      find.byKey(const ValueKey('financial-momentum-chart')),
      findsNothing,
    );

    final bandToggle = find.descendant(
      of: find.byKey(const ValueKey('financial-show-volatility-band')),
      matching: find.byType(SwitchListTile),
    );
    await tester.ensureVisible(bandToggle);
    await tester.tap(bandToggle);
    await tester.pumpAndSettle();

    final withoutBand = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('financial-price-chart')),
    );
    expect(withoutBand.series.whereType<RangeAreaChartSeries>(), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('terminal preset embeds identities and reclaims axis chrome', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const ValueKey('financial-preset-terminal')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('financial-volume-chart')), findsNothing);
    expect(find.text('Price and trend'), findsNothing);
    expect(find.text('MACD (12, 26, 9)'), findsNothing);

    final charts = tester
        .widgetList<BravenChartPlus>(find.byType(BravenChartPlus))
        .toList();
    expect(charts, hasLength(3));
    for (var index = 0; index < charts.length; index++) {
      final chart = charts[index];
      expect(chart.showLegend, isFalse);
      expect(
        chart.axislessPlotInsets,
        const EdgeInsets.symmetric(horizontal: 10),
      );
      expect(chart.xAxisConfig?.visible, index == charts.length - 1);
      expect(chart.xAxisConfig?.showTickLabels, index == charts.length - 1);
      expect(chart.yAxis?.position, YAxisPosition.hidden);
      expect(chart.yAxis?.visible, isFalse);
      expect(chart.annotations.whereType<TextAnnotation>(), hasLength(1));
    }
    expect(
      charts.last.xAxisConfig?.labelFormatter?.call(0),
      matches(RegExp(r'^[A-Z][a-z]{2} \d{1,2}$')),
    );

    final renderBoxes = find
        .descendant(
          of: find.byType(BravenChartPlus),
          matching: find.byWidgetPredicate(
            (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
          ),
        )
        .evaluate()
        .map((element) => element.renderObject! as ChartRenderBox)
        .toList();
    expect(renderBoxes, hasLength(3));
    for (final renderBox in renderBoxes) {
      expect(renderBox.plotToWidget(Offset.zero).dy, 0);
    }
    for (final renderBox in renderBoxes.take(2)) {
      expect(
        renderBox.plotToWidget(Offset(0, renderBox.plotHeight)).dy,
        renderBox.size.height,
      );
    }
    expect(
      renderBoxes.last.plotToWidget(Offset(0, renderBoxes.last.plotHeight)).dy,
      lessThan(renderBoxes.last.size.height),
    );
    final leftEdges = [
      for (final renderBox in renderBoxes)
        renderBox.localToGlobal(renderBox.plotToWidget(Offset.zero)).dx,
    ];
    final rightEdges = [
      for (final renderBox in renderBoxes)
        renderBox
            .localToGlobal(
              renderBox.plotToWidget(Offset(renderBox.plotWidth, 0)),
            )
            .dx,
    ];
    for (var index = 1; index < renderBoxes.length; index++) {
      expect(leftEdges[index], closeTo(leftEdges.first, .01));
      expect(rightEdges[index], closeTo(rightEdges.first, .01));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('terminal date axis follows the last visible study', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('financial-preset-terminal')));
    await tester.pumpAndSettle();

    var momentum = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('financial-momentum-chart')),
    );
    var macd = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('financial-macd-chart')),
    );
    expect(momentum.xAxisConfig?.visible, isTrue);
    expect(macd.xAxisConfig?.visible, isFalse);

    final momentumToggle = find.descendant(
      of: find.byKey(const ValueKey('financial-show-momentum')),
      matching: find.byType(SwitchListTile),
    );
    await tester.ensureVisible(momentumToggle);
    await tester.tap(momentumToggle);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('financial-momentum-chart')),
      findsNothing,
    );
    macd = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('financial-macd-chart')),
    );
    expect(macd.xAxisConfig?.visible, isTrue);
    expect(macd.xAxisConfig?.showTickLabels, isTrue);

    final dateAxisToggle = find.descendant(
      of: find.byKey(const ValueKey('financial-show-terminal-date-axis')),
      matching: find.byType(SwitchListTile),
    );
    await tester.ensureVisible(dateAxisToggle);
    await tester.tap(dateAxisToggle);
    await tester.pumpAndSettle();

    macd = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('financial-macd-chart')),
    );
    expect(macd.xAxisConfig?.visible, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact composition scrolls without overflow', (tester) async {
    await pumpPage(tester, width: 560);

    expect(find.text('Technical Indicators'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('financial-technical-stack')),
      findsOneWidget,
    );
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
