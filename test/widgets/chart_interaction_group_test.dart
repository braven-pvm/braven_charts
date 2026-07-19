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
}

Widget _host(ChartInteractionGroupController group) {
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
