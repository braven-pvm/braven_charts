import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:braven_charts_example/showcase/pages/technical_indicators_page.dart';
import 'package:flutter/gestures.dart';
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
    expect(price.theme?.interactionTheme.crosshairBandWidth, 28);
    expect(
      price.theme?.interactionTheme.crosshairBandColor.a,
      closeTo(.10, .01),
    );
    expect(price.theme?.interactionTheme.crosshairDashPattern, isEmpty);
    expect(price.interactionConfig?.crosshair.persistOnPointerExit, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pane handles resize adjacent studies without remounting charts',
    (tester) async {
      await pumpPage(tester);

      final macdFinder = find.byKey(const ValueKey('financial-macd-chart'));
      final momentumFinder = find.byKey(
        const ValueKey('financial-momentum-chart'),
      );
      final navigatorFinder = find.byKey(const ValueKey('financial-navigator'));
      final macdElement = macdFinder.evaluate().single;
      final priceWidget = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('financial-price-chart')),
      );
      final initialMacdHeight = tester.getSize(macdFinder).height;
      final initialMomentumHeight = tester.getSize(momentumFinder).height;
      final initialNavigatorHeight = tester.getSize(navigatorFinder).height;

      final macdMomentumHandle = find.byKey(
        const ValueKey('financial-resize-macd-momentum'),
      );
      final macdPane = find.byKey(const ValueKey('financial-pane-macd'));
      final momentumPane = find.byKey(
        const ValueKey('financial-pane-momentum'),
      );
      expect(
        tester.getBottomRight(macdPane).dy,
        closeTo(tester.getTopLeft(momentumPane).dy, .01),
        reason: 'the resize affordance must overlay, not split, the pane seam',
      );
      expect(
        tester.getCenter(macdMomentumHandle).dy,
        closeTo(tester.getBottomRight(macdPane).dy, .01),
      );
      await tester.ensureVisible(macdMomentumHandle);
      await tester.pump();
      await tester.drag(macdMomentumHandle, const Offset(0, 36));
      await tester.pump();

      final resizedMacdHeight = tester.getSize(macdFinder).height;
      final resizedMomentumHeight = tester.getSize(momentumFinder).height;
      expect(resizedMacdHeight, greaterThan(initialMacdHeight));
      expect(resizedMomentumHeight, lessThan(initialMomentumHeight));
      expect(
        resizedMacdHeight + resizedMomentumHeight,
        closeTo(initialMacdHeight + initialMomentumHeight, 1),
      );
      expect(macdFinder.evaluate().single, same(macdElement));
      expect(
        tester.widget<BravenChartPlus>(
          find.byKey(const ValueKey('financial-price-chart')),
        ),
        same(priceWidget),
        reason: 'dragging one seam must not rebuild unrelated chart widgets',
      );
      expect(
        tester.getBottomRight(macdPane).dy,
        closeTo(tester.getTopLeft(momentumPane).dy, .01),
      );

      final navigatorHandle = find.byKey(
        const ValueKey('financial-resize-momentum-navigator'),
      );
      await tester.ensureVisible(navigatorHandle);
      await tester.pump();
      await tester.drag(navigatorHandle, const Offset(0, -48));
      await tester.pump();

      expect(
        tester.getSize(navigatorFinder).height,
        greaterThan(initialNavigatorHeight),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    },
  );

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

    final source = renderBoxes.first;
    final viewport = source.transform!;
    final dataX = (viewport.dataXMin + viewport.dataXMax) / 2;
    final local = source.plotToWidget(
      source.transform!.dataToPlot(
        dataX,
        (viewport.dataYMin + viewport.dataYMax) / 2,
      ),
    );
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(location: Offset.zero);
    await pointer.moveTo(source.localToGlobal(local));
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

    final retainedDataX = source.debugSynchronizedCursorX;
    final sourceAxisPosition = Offset(
      source.debugPlotArea.center.dx,
      source.debugPlotArea.bottom + 4,
    );
    expect(sourceAxisPosition.dy, lessThan(source.size.height));
    await pointer.moveTo(source.localToGlobal(sourceAxisPosition));
    await tester.pump();

    for (final renderBox in renderBoxes) {
      expect(
        renderBox.debugSynchronizedCursorX,
        closeTo(retainedDataX!, .0001),
        reason:
            'crossing a pane axis or resize seam must retain the shared guide',
      );
    }

    final destinationIndex = 1;
    final destination = renderBoxes[destinationIndex];
    await tester.ensureVisible(
      find.byKey(const ValueKey('financial-volume-chart')),
    );
    await tester.pump();
    final nextDataX =
        viewport.dataXMin + ((viewport.dataXMax - viewport.dataXMin) * .72);
    final destinationLocal = destination.plotToWidget(
      destination.transform!.dataToPlot(
        nextDataX,
        (destination.transform!.dataYMin + destination.transform!.dataYMax) / 2,
      ),
    );
    await pointer.moveTo(destination.localToGlobal(destinationLocal));
    await tester.pump();

    final updatedGlobalCursorXs = <double>[
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
    for (var index = 0; index < renderBoxes.length; index++) {
      expect(
        renderBoxes[index].debugSynchronizedCursorX,
        closeTo(nextDataX, .0001),
      );
      expect(
        updatedGlobalCursorXs[index],
        closeTo(updatedGlobalCursorXs.first, .01),
        reason: 'entering another pane must move every retained guide together',
      );
    }

    await pointer.removePointer();
    final destinationGlobal = destination.localToGlobal(destinationLocal);
    final initialViewportMin = destination.transform!.dataXMin;
    final pan = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kMiddleMouseButton,
    );
    addTearDown(pan.removePointer);
    await pan.addPointer(location: Offset.zero);
    await pan.moveTo(destinationGlobal);
    await tester.pump();
    await pan.down(destinationGlobal);
    await tester.pump();

    for (final renderBox in renderBoxes) {
      expect(
        renderBox.debugSynchronizedCursorX,
        closeTo(nextDataX, .0001),
        reason:
            'middle-button down must retain the one shared financial cursor',
      );
    }

    await pan.moveBy(const Offset(36, 0));
    await tester.pump();

    expect(
      destination.transform!.dataXMin,
      isNot(closeTo(initialViewportMin, 1e-6)),
    );
    final pannedGlobalCursorXs = <double>[
      for (final renderBox in renderBoxes)
        renderBox.localToGlobal(renderBox.debugSynchronizedCursorPosition!).dx,
    ];
    for (var index = 0; index < renderBoxes.length; index++) {
      expect(
        renderBoxes[index].debugSynchronizedCursorX,
        closeTo(nextDataX, .0001),
        reason: 'middle-button pan must not expose pane-local stale cursors',
      );
      expect(
        pannedGlobalCursorXs[index],
        closeTo(pannedGlobalCursorXs.first, .01),
        reason: 'every guide must stay aligned throughout the pan gesture',
      );
      expect(
        renderBoxes[index].transform!.dataXMin,
        closeTo(destination.transform!.dataXMin, .0001),
      );
      expect(
        renderBoxes[index].transform!.dataXMax,
        closeTo(destination.transform!.dataXMax, .0001),
      );
    }

    await pan.up();
    await tester.pump();
    for (final renderBox in renderBoxes) {
      expect(renderBox.debugSynchronizedCursorX, closeTo(nextDataX, .0001));
    }

    final viewportBeforeWheel = (
      min: destination.transform!.dataXMin,
      max: destination.transform!.dataXMax,
    );
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: destinationGlobal,
        scrollDelta: const Offset(0, 60),
      ),
    );
    await tester.pump();

    expect(destination.coordinator.isPanningOrZooming, isFalse);
    expect(
      destination.transform!.dataXMin,
      closeTo(viewportBeforeWheel.min, .0001),
    );
    expect(
      destination.transform!.dataXMax,
      closeTo(viewportBeforeWheel.max, .0001),
    );
    final wheelGlobalCursorXs = <double>[
      for (final renderBox in renderBoxes)
        renderBox.localToGlobal(renderBox.debugSynchronizedCursorPosition!).dx,
    ];
    for (var index = 0; index < renderBoxes.length; index++) {
      expect(
        renderBoxes[index].debugSynchronizedCursorX,
        closeTo(nextDataX, .0001),
        reason: 'host wheel scroll must retain one shared data-X',
      );
      expect(
        wheelGlobalCursorXs[index],
        closeTo(wheelGlobalCursorXs.first, .01),
        reason: 'host wheel scroll must not expose pane-local stale cursors',
      );
    }

    await pan.moveTo(const Offset(1490, 990));
    await tester.pump();
    for (final renderBox in renderBoxes) {
      expect(
        renderBox.debugSynchronizedCursorX,
        closeTo(nextDataX, .0001),
        reason: 'leaving the stack must retain one shared data-X',
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
