import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'maps one data-X cursor through different plots and rendered paths',
    (tester) async {
      final group = ChartInteractionGroupController();
      addTearDown(group.dispose);

      await tester.pumpWidget(_host(group));
      await tester.pumpAndSettle();

      final renderFinders = _chartRenderFinder().evaluate().toList();
      final firstFinder = find.byElementPredicate(
        (element) => element == renderFinders[0],
      );
      final secondFinder = find.byElementPredicate(
        (element) => element == renderFinders[1],
      );
      final first = renderFinders[0].renderObject! as ChartRenderBox;
      final second = renderFinders[1].renderObject! as ChartRenderBox;
      const dataX = 4.4;
      final firstLocal = first.plotToWidget(
        first.transform!.dataToPlot(
          dataX,
          (first.transform!.dataYMin + first.transform!.dataYMax) / 2,
        ),
      );
      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(tester.getTopLeft(firstFinder) + firstLocal);
      await tester.pump();

      expect(group.cursorX, closeTo(dataX, 0.0001));
      expect(first.debugSynchronizedCursorX, closeTo(dataX, 0.0001));
      expect(second.debugSynchronizedCursorX, closeTo(dataX, 0.0001));
      final expectedSecondX = second
          .plotToWidget(
            second.transform!.dataToPlot(dataX, second.transform!.dataYMin),
          )
          .dx;
      expect(
        second.debugSynchronizedCursorPosition!.dx,
        closeTo(expectedSecondX, 0.0001),
      );
      expect(
        first.debugSynchronizedTrackingState!.seriesValues.single,
        isA<CrosshairSeriesValue>()
            .having((value) => value.dataPointIndex, 'point index', 2)
            .having((value) => value.x, 'intersection X', closeTo(dataX, 1e-9))
            .having((value) => value.isInterpolated, 'interpolated', isTrue),
      );
      expect(
        second.debugSynchronizedTrackingState!.seriesValues.single,
        isA<CrosshairSeriesValue>()
            .having((value) => value.dataPointIndex, 'point index', 1)
            .having((value) => value.x, 'intersection X', closeTo(dataX, 1e-9))
            .having(
              (value) => value.y,
              'stepped intersection Y',
              closeTo(420, 1e-9),
            ),
      );

      await pointer.moveTo(const Offset(1100, 700));
      await tester.pump();
      expect(group.cursorX, isNull);
      expect(first.debugSynchronizedCursorPosition, isNull);
      expect(second.debugSynchronizedCursorPosition, isNull);
      expect(secondFinder, findsOneWidget);
    },
  );

  testWidgets(
    'persistent guide stays synchronized across plots, axes, and exit',
    (tester) async {
      final group = ChartInteractionGroupController();
      addTearDown(group.dispose);
      await tester.pumpWidget(_host(group, persistOnPointerExit: true));
      await tester.pumpAndSettle();

      final renderElements = _chartRenderFinder().evaluate().toList();
      final sourceFinder = find.byElementPredicate(
        (element) => element == renderElements.first,
      );
      final targetFinder = find.byElementPredicate(
        (element) => element == renderElements.last,
      );
      final source = renderElements.first.renderObject! as ChartRenderBox;
      final target = renderElements.last.renderObject! as ChartRenderBox;
      final sourcePosition = source.plotToWidget(
        source.transform!.dataToPlot(
          4.4,
          (source.transform!.dataYMin + source.transform!.dataYMax) / 2,
        ),
      );
      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(tester.getTopLeft(sourceFinder) + sourcePosition);
      await tester.pump();

      final cursorX = group.cursorX;
      expect(cursorX, closeTo(4.4, .0001));
      expect(
        target,
        isA<ChartRenderBox>().having(
          (renderBox) => renderBox.debugSynchronizedCursorX,
          'synchronized X',
          closeTo(cursorX!, .0001),
        ),
      );

      // Moving over an axis remains inside the chart render box. This used to
      // clear the group while leaving each pane's local pointer behind.
      final sourceAxisPosition = Offset(
        source.debugPlotArea.center.dx,
        source.debugPlotArea.bottom + 4,
      );
      expect(sourceAxisPosition.dy, lessThan(source.size.height));
      await pointer.moveTo(
        tester.getTopLeft(sourceFinder) + sourceAxisPosition,
      );
      await tester.pump();

      expect(group.cursorX, cursorX);
      for (final element in renderElements) {
        final renderBox = element.renderObject! as ChartRenderBox;
        expect(renderBox.debugSynchronizedCursorX, closeTo(cursorX!, .0001));
      }

      const nextDataX = 7.2;
      final targetPosition = target.plotToWidget(
        target.transform!.dataToPlot(
          nextDataX,
          (target.transform!.dataYMin + target.transform!.dataYMax) / 2,
        ),
      );
      await pointer.moveTo(tester.getTopLeft(targetFinder) + targetPosition);
      await tester.pump();

      expect(group.cursorX, closeTo(nextDataX, .0001));
      for (final element in renderElements) {
        final renderBox = element.renderObject! as ChartRenderBox;
        expect(renderBox.debugSynchronizedCursorX, closeTo(nextDataX, .0001));
        final expectedX = renderBox
            .plotToWidget(
              renderBox.transform!.dataToPlot(
                nextDataX,
                renderBox.transform!.dataYMin,
              ),
            )
            .dx;
        expect(
          renderBox.debugSynchronizedCursorPosition!.dx,
          closeTo(expectedX, .0001),
        );
      }

      await pointer.moveTo(const Offset(1100, 700));
      await tester.pump();

      expect(group.cursorX, closeTo(nextDataX, .0001));
      for (final element in renderElements) {
        final renderBox = element.renderObject! as ChartRenderBox;
        expect(renderBox.debugSynchronizedCursorX, closeTo(nextDataX, .0001));
      }
    },
  );

  testWidgets(
    'persistent guide stays synchronized throughout middle-button panning',
    (tester) async {
      final group = ChartInteractionGroupController();
      addTearDown(group.dispose);
      await tester.pumpWidget(_host(group, persistOnPointerExit: true));
      await tester.pumpAndSettle();

      final renderElements = _chartRenderFinder().evaluate().toList();
      final sourceElement = renderElements.first;
      final source = sourceElement.renderObject! as ChartRenderBox;
      final sourceFinder = find.byElementPredicate(
        (element) => element == sourceElement,
      );
      const dataX = 4.4;
      final sourcePosition = source.plotToWidget(
        source.transform!.dataToPlot(
          dataX,
          (source.transform!.dataYMin + source.transform!.dataYMax) / 2,
        ),
      );
      final globalSourcePosition =
          tester.getTopLeft(sourceFinder) + sourcePosition;
      final pan = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kMiddleMouseButton,
      );
      addTearDown(pan.removePointer);
      await pan.addPointer(location: Offset.zero);
      await pan.moveTo(globalSourcePosition);
      await tester.pump();

      expect(group.cursorX, closeTo(dataX, .0001));
      final initialViewportMin = source.transform!.dataXMin;

      await pan.down(globalSourcePosition);
      await tester.pump();

      expect(
        group.cursorX,
        closeTo(dataX, .0001),
        reason: 'middle-button down must not clear a persistent shared guide',
      );
      for (final element in renderElements) {
        final renderBox = element.renderObject! as ChartRenderBox;
        expect(renderBox.debugSynchronizedCursorX, closeTo(dataX, .0001));
      }

      await pan.moveBy(const Offset(48, 0));
      await tester.pump();

      expect(
        source.transform!.dataXMin,
        isNot(closeTo(initialViewportMin, 1e-6)),
      );
      expect(
        group.cursorX,
        closeTo(dataX, .0001),
        reason: 'the retained data-X remains authoritative while panning',
      );
      for (final element in renderElements) {
        final renderBox = element.renderObject! as ChartRenderBox;
        expect(renderBox.debugSynchronizedCursorX, closeTo(dataX, .0001));
        final expectedX = renderBox
            .plotToWidget(
              renderBox.transform!.dataToPlot(
                dataX,
                renderBox.transform!.dataYMin,
              ),
            )
            .dx;
        expect(
          renderBox.debugSynchronizedCursorPosition!.dx,
          closeTo(expectedX, .0001),
        );
      }

      await pan.up();
      await tester.pump();
      expect(group.cursorX, closeTo(dataX, .0001));
      for (final element in renderElements) {
        final renderBox = element.renderObject! as ChartRenderBox;
        expect(renderBox.debugSynchronizedCursorX, closeTo(dataX, .0001));
      }
    },
  );

  testWidgets(
    'plain wheel scrolling leaves the persistent guide and viewport untouched',
    (tester) async {
      final group = ChartInteractionGroupController();
      addTearDown(group.dispose);
      await tester.pumpWidget(_host(group, persistOnPointerExit: true));
      await tester.pumpAndSettle();

      final renderElements = _chartRenderFinder().evaluate().toList();
      final sourceElement = renderElements.first;
      final source = sourceElement.renderObject! as ChartRenderBox;
      final sourceFinder = find.byElementPredicate(
        (element) => element == sourceElement,
      );
      const dataX = 4.4;
      final sourcePosition = source.plotToWidget(
        source.transform!.dataToPlot(
          dataX,
          (source.transform!.dataYMin + source.transform!.dataYMax) / 2,
        ),
      );
      final globalSourcePosition =
          tester.getTopLeft(sourceFinder) + sourcePosition;
      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(globalSourcePosition);
      await tester.pump();

      expect(group.cursorX, closeTo(dataX, .0001));
      final viewportBefore = (
        min: source.transform!.dataXMin,
        max: source.transform!.dataXMax,
      );

      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: globalSourcePosition,
          scrollDelta: const Offset(0, 60),
        ),
      );
      await tester.pump();

      expect(
        source.coordinator.isPanningOrZooming,
        isFalse,
        reason: 'host-page wheel scrolling is not a chart viewport gesture',
      );
      expect(source.transform!.dataXMin, closeTo(viewportBefore.min, .0001));
      expect(source.transform!.dataXMax, closeTo(viewportBefore.max, .0001));
      expect(group.cursorX, closeTo(dataX, .0001));
      for (final element in renderElements) {
        final renderBox = element.renderObject! as ChartRenderBox;
        expect(renderBox.debugSynchronizedCursorX, closeTo(dataX, .0001));
      }
    },
  );

  testWidgets('keeps shared X aligned while resolving nearest local samples', (
    tester,
  ) async {
    final group = ChartInteractionGroupController();
    addTearDown(group.dispose);

    await tester.pumpWidget(_host(group, interpolateValues: false));
    await tester.pumpAndSettle();
    final renderElements = _chartRenderFinder().evaluate().toList();
    final firstFinder = find.byElementPredicate(
      (element) => element == renderElements.first,
    );
    final first = renderElements[0].renderObject! as ChartRenderBox;
    final second = renderElements[1].renderObject! as ChartRenderBox;
    const dataX = 4.4;
    final local = first.plotToWidget(
      first.transform!.dataToPlot(
        dataX,
        (first.transform!.dataYMin + first.transform!.dataYMax) / 2,
      ),
    );
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(pointer.removePointer);
    await pointer.addPointer(location: Offset.zero);
    await pointer.moveTo(tester.getTopLeft(firstFinder) + local);
    await tester.pump();

    expect(group.cursorX, closeTo(dataX, 0.0001));
    final firstValue =
        first.debugSynchronizedTrackingState!.seriesValues.single;
    final secondValue =
        second.debugSynchronizedTrackingState!.seriesValues.single;
    expect(firstValue.isInterpolated, isFalse);
    expect(firstValue.dataPointIndex, 2);
    expect(firstValue.x, 4);
    expect(firstValue.y, 7);
    expect(secondValue.isInterpolated, isFalse);
    expect(secondValue.dataPointIndex, 1);
    expect(secondValue.x, 3);
    expect(secondValue.y, 420);

    final expectedSharedX = second
        .plotToWidget(
          second.transform!.dataToPlot(dataX, second.transform!.dataYMin),
        )
        .dx;
    expect(
      second.debugSynchronizedCursorPosition!.dx,
      closeTo(expectedSharedX, 0.0001),
    );
    final expectedLocalY = second
        .plotToWidget(
          second.transform!.dataToPlot(secondValue.x, secondValue.y),
        )
        .dy;
    expect(
      second.debugSynchronizedCursorPosition!.dy,
      closeTo(expectedLocalY, 0.0001),
    );
  });

  testWidgets('touch scrub publishes and clears the shared cursor', (
    tester,
  ) async {
    final group = ChartInteractionGroupController();
    addTearDown(group.dispose);
    await tester.pumpWidget(_host(group));
    await tester.pumpAndSettle();
    final firstElement = _chartRenderFinder().evaluate().first;
    final firstFinder = find.byElementPredicate(
      (element) => element == firstElement,
    );
    final first = firstElement.renderObject! as ChartRenderBox;
    final local = first.plotToWidget(
      first.transform!.dataToPlot(
        6,
        (first.transform!.dataYMin + first.transform!.dataYMax) / 2,
      ),
    );
    final position = tester.getTopLeft(firstFinder) + local;

    final touch = await tester.startGesture(
      position,
      kind: PointerDeviceKind.touch,
    );
    await tester.pump();
    expect(group.cursorX, closeTo(6, 0.0001));

    await touch.up();
    await tester.pump();
    expect(group.cursorX, isNull);
  });

  testWidgets('synchronizes only X viewport and retains local Y domains', (
    tester,
  ) async {
    final group = ChartInteractionGroupController();
    addTearDown(group.dispose);
    await tester.pumpWidget(_host(group));
    await tester.pumpAndSettle();
    final renderObjects = _chartRenderFinder()
        .evaluate()
        .map((element) => element.renderObject! as ChartRenderBox)
        .toList();
    final first = renderObjects[0];
    final second = renderObjects[1];
    final secondYMin = second.transform!.dataYMin;
    final secondYMax = second.transform!.dataYMax;

    first.zoomChart(1.8, animate: false);
    await tester.pump();

    expect(
      second.transform!.dataXMin,
      closeTo(first.transform!.dataXMin, 0.0001),
    );
    expect(
      second.transform!.dataXMax,
      closeTo(first.transform!.dataXMax, 0.0001),
    );
    expect(second.transform!.dataYMin, secondYMin);
    expect(second.transform!.dataYMax, secondYMax);
  });

  testWidgets('links durable selection by stable point key across reorder', (
    tester,
  ) async {
    final group = ChartInteractionGroupController();
    final firstController = BravenChartController();
    final secondController = BravenChartController();
    addTearDown(group.dispose);
    addTearDown(firstController.dispose);
    addTearDown(secondController.dispose);
    const options = ChartInteractionGroupOptions(
      synchronizeCursor: false,
      synchronizeViewport: false,
      synchronizeSelection: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            Expanded(
              child: BravenChartPlus(
                bravenChartController: firstController,
                interactionGroupController: group,
                interactionGroupOptions: options,
                showLegend: false,
                series: const [
                  LineChartSeries(
                    id: 'orders',
                    points: [
                      ChartDataPoint(x: 0, y: 10, pointKey: 'alpha'),
                      ChartDataPoint(x: 1, y: 20, pointKey: 'beta'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: BravenChartPlus(
                bravenChartController: secondController,
                interactionGroupController: group,
                interactionGroupOptions: options,
                showLegend: false,
                series: const [
                  BarChartSeries(
                    id: 'orders',
                    barWidthPercent: 0.6,
                    points: [
                      ChartDataPoint(x: 0, y: 200, pointKey: 'beta'),
                      ChartDataPoint(x: 1, y: 100, pointKey: 'alpha'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    firstController.selectPoint(
      const ChartPointRef(seriesId: 'orders', pointIndex: 0),
      revision: firstController.effectiveDocumentRevision.value!,
    );
    await tester.pump();

    expect(group.selection, {
      const ChartPointKeyRef(seriesId: 'orders', pointKey: 'alpha'),
    });
    expect(secondController.selectionSnapshot!.pointRefs, {
      const ChartPointRef(seriesId: 'orders', pointIndex: 1),
    });

    firstController.clearPointSelection();
    await tester.pump();
    expect(secondController.selectionSnapshot!.isEmpty, isTrue);
  });

  testWidgets('reports the complete two-dimensional viewport to callers', (
    tester,
  ) async {
    Map<String, double>? reportedBounds;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 640,
          height: 320,
          child: BravenChartPlus(
            showLegend: false,
            interactionConfig: InteractionConfig(
              onViewportChanged: (bounds) => reportedBounds = bounds,
            ),
            series: const [
              ScatterChartSeries(
                id: 'observations',
                points: [
                  ChartDataPoint(x: 0, y: 10),
                  ChartDataPoint(x: 5, y: 50),
                  ChartDataPoint(x: 10, y: 90),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final renderBox =
        _chartRenderFinder().evaluate().single.renderObject! as ChartRenderBox;
    renderBox.zoomChart(1.8, animate: false);
    await tester.pump();

    expect(reportedBounds, isNotNull);
    expect(reportedBounds!.keys, containsAll(['minX', 'minY', 'maxX', 'maxY']));
    expect(
      reportedBounds!['minX'],
      closeTo(renderBox.transform!.dataXMin, 1e-9),
    );
    expect(
      reportedBounds!['maxX'],
      closeTo(renderBox.transform!.dataXMax, 1e-9),
    );
    expect(
      reportedBounds!['minY'],
      closeTo(renderBox.transform!.dataYMin, 1e-9),
    );
    expect(
      reportedBounds!['maxY'],
      closeTo(renderBox.transform!.dataYMax, 1e-9),
    );
  });
}

Widget _host(
  ChartInteractionGroupController group, {
  bool interpolateValues = true,
  bool persistOnPointerExit = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 640,
              height: 240,
              child: BravenChartPlus(
                interactionGroupController: group,
                showLegend: false,
                interactionConfig: InteractionConfig(
                  crosshair: CrosshairConfig(
                    displayMode: CrosshairDisplayMode.tracking,
                    interpolateValues: interpolateValues,
                    persistOnPointerExit: persistOnPointerExit,
                  ),
                ),
                series: const [
                  LineChartSeries(
                    id: 'speed',
                    interpolation: LineInterpolation.monotone,
                    points: [
                      ChartDataPoint(x: 0, y: 4),
                      ChartDataPoint(x: 2, y: 8),
                      ChartDataPoint(x: 4, y: 7),
                      ChartDataPoint(x: 6, y: 11),
                      ChartDataPoint(x: 8, y: 9),
                      ChartDataPoint(x: 10, y: 12),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 460,
              height: 240,
              child: BravenChartPlus(
                interactionGroupController: group,
                showLegend: false,
                interactionConfig: InteractionConfig(
                  crosshair: CrosshairConfig(
                    displayMode: CrosshairDisplayMode.tracking,
                    interpolateValues: interpolateValues,
                    persistOnPointerExit: persistOnPointerExit,
                  ),
                ),
                series: const [
                  AreaChartSeries(
                    id: 'elevation',
                    interpolation: LineInterpolation.stepped,
                    points: [
                      ChartDataPoint(x: 0, y: 120),
                      ChartDataPoint(x: 3, y: 420),
                      ChartDataPoint(x: 7, y: 260),
                      ChartDataPoint(x: 10, y: 180),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Finder _chartRenderFinder() => find.byWidgetPredicate(
  (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
);
