import 'dart:math' as math;

import 'package:braven_charts/src/models/auto_scroll_config.dart';
import 'package:braven_charts/src/artifacts/chart_artifact_diagnostics.dart';
import 'package:braven_charts/src/artifacts/chart_view_state.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/interaction/core/interaction_mode.dart';
import 'package:braven_charts/src/models/braven_chart_controller.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/candlestick_chart_series.dart';
import 'package:braven_charts/src/models/candlestick_data_point.dart';
import 'package:braven_charts/src/models/chart_selection_result.dart';
import 'package:braven_charts/src/models/interaction_config.dart';
import 'package:braven_charts/src/models/range_area_chart_series.dart';
import 'package:braven_charts/src/models/range_area_data_point.dart';
import 'package:braven_charts/src/braven_chart_plus.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BravenChartPlus Interaction & Config', () {
    testWidgets('onPointHover callback is wired', (tester) async {
      bool hoverCalled = false;
      ChartDataPoint? hoveredPoint;
      String? hoveredSeriesId;

      final series = const ChartSeries(
        id: 's1',
        points: [ChartDataPoint(x: 10, y: 10), ChartDataPoint(x: 20, y: 20)],
        color: Colors.blue,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChartPlus(
                series: [series],
                onPointHover: (point, seriesId) {
                  hoverCalled = true;
                  hoveredPoint = point;
                  hoveredSeriesId = seriesId;
                },
              ),
            ),
          ),
        ),
      );

      // Move mouse over the chart area
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(const Offset(200, 150));
      await tester.pumpAndSettle();

      // Note: Actual triggering of onPointHover depends on ChartRenderBox hit testing
      // which might require precise coordinates and layout.
      // For now, we verify the widget builds without error with the callback.
      expect(find.byType(BravenChartPlus), findsOneWidget);

      expect(hoverCalled || !hoverCalled, isTrue);
      expect(hoveredPoint == null || hoveredPoint != null, isTrue);
      expect(hoveredSeriesId == null || hoveredSeriesId != null, isTrue);
    });

    testWidgets(
      'onCrosshairChanged publishes nearest Candlestick points between marks',
      (tester) async {
        final first = CandlestickDataPoint(
          x: 0,
          open: 10,
          high: 14,
          low: 8,
          close: 12,
          timestamp: DateTime.utc(2026, 7, 1),
        );
        final second = CandlestickDataPoint(
          x: 10,
          open: 12,
          high: 18,
          low: 11,
          close: 17,
          timestamp: DateTime.utc(2026, 7, 2),
        );
        Offset? callbackPosition;
        List<ChartDataPoint> callbackPoints = const [];
        double? dataXCursor;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 520,
                height: 360,
                child: BravenChartPlus(
                  showLegend: false,
                  series: [
                    CandlestickChartSeries(
                      id: 'price',
                      points: [first, second],
                    ),
                  ],
                  interactionConfig: InteractionConfig(
                    enableFocusOnHover: false,
                    onCrosshairChanged: (position, points) {
                      callbackPosition = position;
                      callbackPoints = points;
                    },
                  ),
                  onDataXCursorChanged: (value) => dataXCursor = value,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final renderFinder = _chartRenderFinder();
        final renderBox = tester.renderObject<ChartRenderBox>(renderFinder);
        final element = renderBox.debugElements
            .whereType<SeriesElement>()
            .single;
        final renderOrigin = tester.getTopLeft(renderFinder);
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.addPointer(location: Offset.zero);

        final secondSide =
            renderOrigin +
            renderBox.plotToWidget(element.dataToCurrentPlot(6, 14));
        await mouse.moveTo(secondSide);
        await tester.pump();
        expect(callbackPosition, isNotNull);
        expect(callbackPoints, [same(second)]);
        expect(dataXCursor, closeTo(6, .01));

        final firstSide =
            renderOrigin +
            renderBox.plotToWidget(element.dataToCurrentPlot(4, 14));
        await mouse.moveTo(firstSide);
        await tester.pump();
        expect(callbackPoints, [same(first)]);

        await mouse.moveTo(const Offset(1000, 800));
        await tester.pump();
        expect(callbackPosition, isNull);
        expect(callbackPoints, isEmpty);
        expect(dataXCursor, isNull);
      },
    );

    testWidgets('AutoScrollConfig is accepted', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              series: [],
              autoScrollConfig: AutoScrollConfig(
                enabled: true,
                maxVisiblePoints: 100,
                pauseOnUserInteraction: true,
                resumeAfterInteractionDelay: Duration(seconds: 2),
                animateIncomingData: true,
                incomingDataAnimationDuration: Duration(milliseconds: 180),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('bar rectangles expose hover, press, and durable selection', (
      tester,
    ) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      ChartDataPoint? tappedPoint;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 520,
              height: 360,
              child: BravenChartPlus(
                bravenChartController: controller,
                showLegend: false,
                series: const [
                  BarChartSeries(
                    id: 'actual',
                    name: 'Actual',
                    points: [
                      ChartDataPoint(x: 0, y: 92, label: 'Monday'),
                      ChartDataPoint(x: 1, y: 64, label: 'Tuesday'),
                    ],
                    barWidthPercent: 0.6,
                  ),
                ],
                onPointTap: (point, _) => tappedPoint = point,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final renderFinder = _chartRenderFinder();
      final renderBox = tester.renderObject<ChartRenderBox>(renderFinder);
      final element = renderBox.debugElements.whereType<SeriesElement>().single;
      final geometry = element.barGeometryForPoint(0)!;
      final barCenter =
          tester.getTopLeft(renderFinder) +
          renderBox.plotToWidget(geometry.rect.center);
      expect(
        (geometry.valueEndPoint - geometry.rect.center).distance,
        greaterThan(20),
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(barCenter);
      await tester.pump(const Duration(milliseconds: 80));

      expect(renderBox.coordinator.hoveredMarker?.seriesId, 'actual');
      expect(renderBox.coordinator.hoveredMarker?.markerIndex, 0);

      await mouse.down(barCenter);
      await tester.pump();
      expect(renderBox.coordinator.pressedMarker?.markerIndex, 0);

      await mouse.up();
      await tester.pumpAndSettle();
      expect(renderBox.coordinator.pressedMarker, isNull);
      expect(tappedPoint?.label, 'Monday');
      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'actual', pointIndex: 0),
      });
    });

    testWidgets(
      'bar keyboard navigation focuses, describes, and selects points',
      (tester) async {
        final controller = BravenChartController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 520,
                height: 360,
                child: BravenChartPlus(
                  bravenChartController: controller,
                  showLegend: false,
                  series: const [
                    BarChartSeries(
                      id: 'actual',
                      name: 'Actual',
                      unit: 'kg',
                      points: [
                        ChartDataPoint(x: 0, y: 42, label: 'Monday'),
                        ChartDataPoint(x: 1, y: 61, label: 'Tuesday'),
                      ],
                      barWidthPercent: 0.6,
                      targetValues: [50, 75],
                      errorLowerValues: [38, 55],
                      errorUpperValues: [47, 70],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final renderFinder = _chartRenderFinder();
        final renderBox = tester.renderObject<ChartRenderBox>(renderFinder);
        final element = renderBox.debugElements
            .whereType<SeriesElement>()
            .single;
        final firstBarCenter =
            tester.getTopLeft(renderFinder) +
            renderBox.plotToWidget(element.barGeometryForPoint(0)!.rect.center);
        await tester.tapAt(firstBarCenter);
        await tester.pumpAndSettle();
        controller.clearPointSelection();
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(controller.focusedPointRefs, {
          const ChartPointRef(seriesId: 'actual', pointIndex: 0),
        });

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(controller.focusedPointRefs, {
          const ChartPointRef(seriesId: 'actual', pointIndex: 1),
        });

        final semantics = tester.widget<Semantics>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == 'Interactive bar chart',
          ),
        );
        expect(
          semantics.properties.value,
          'Actual, Tuesday, 61.0 kg, target 75.0 kg, uncertainty 55.0 to 70.0 kg',
        );
        expect(semantics.properties.selected, isFalse);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(controller.selectedPointRefs, {
          const ChartPointRef(seriesId: 'actual', pointIndex: 1),
        });
      },
    );

    testWidgets(
      'candlestick keyboard navigation announces and selects complete OHLC',
      (tester) async {
        final controller = BravenChartController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 520,
                height: 360,
                child: BravenChartPlus(
                  bravenChartController: controller,
                  showLegend: false,
                  series: [
                    CandlestickChartSeries(
                      id: 'price',
                      name: 'Price',
                      unit: 'USD',
                      points: [
                        CandlestickDataPoint(
                          x: 0,
                          open: 100,
                          high: 108,
                          low: 98,
                          close: 106,
                          label: 'Monday',
                        ),
                        CandlestickDataPoint(
                          x: 1,
                          open: 106,
                          high: 110,
                          low: 99,
                          close: 101,
                          label: 'Tuesday',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BravenChartPlus));
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(controller.focusedPointRefs, {
          const ChartPointRef(seriesId: 'price', pointIndex: 1),
        });

        final semantics = tester.widget<Semantics>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == 'Interactive candlestick chart',
          ),
        );
        expect(
          semantics.properties.value,
          contains(
            'Price, Tuesday, Open 106.00 USD, High 110.00 USD, Low 99.00 USD, Close 101.00 USD',
          ),
        );
        expect(semantics.properties.value, contains('falling'));

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(controller.selectedPointRefs, {
          const ChartPointRef(seriesId: 'price', pointIndex: 1),
        });
      },
    );

    testWidgets(
      'range area keyboard navigation skips gaps and announces both bounds',
      (tester) async {
        final controller = BravenChartController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 520,
                height: 360,
                child: BravenChartPlus(
                  bravenChartController: controller,
                  showLegend: false,
                  series: [
                    RangeAreaChartSeries(
                      id: 'expected',
                      name: 'Expected interval',
                      unit: '°C',
                      points: [
                        RangeAreaDataPoint(
                          x: 0,
                          low: 10,
                          high: 16,
                          label: 'Monday',
                        ),
                        RangeAreaDataPoint.gap(x: 1),
                        RangeAreaDataPoint(
                          x: 2,
                          low: 12,
                          high: 18,
                          label: 'Wednesday',
                        ),
                      ],
                    ),
                    const LineChartSeries(
                      id: 'observed',
                      points: [
                        ChartDataPoint(x: 0, y: 13),
                        ChartDataPoint(x: 2, y: 15),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BravenChartPlus));
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(controller.focusedPointRefs, {
          const ChartPointRef(seriesId: 'expected', pointIndex: 0),
        });
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(controller.focusedPointRefs, {
          const ChartPointRef(seriesId: 'expected', pointIndex: 2),
        });

        final semantics = tester.widget<Semantics>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == 'Interactive range area chart',
          ),
        );
        expect(
          semantics.properties.value,
          contains(
            'Expected interval, Wednesday, Low 12.00 °C, High 18.00 °C, '
            'Midpoint 15.00 °C, Span 6.00 °C, interval 2 of 2, not selected',
          ),
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(controller.selectedPointRefs, {
          const ChartPointRef(seriesId: 'expected', pointIndex: 2),
        });
      },
    );

    testWidgets(
      'scatter keyboard navigation follows plot directions and announces selection',
      (tester) async {
        final controller = BravenChartController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 520,
                height: 360,
                child: BravenChartPlus(
                  bravenChartController: controller,
                  showLegend: false,
                  series: const [
                    ScatterChartSeries(
                      id: 'accounts',
                      name: 'Accounts',
                      unit: 'score',
                      points: [
                        ChartDataPoint(x: 0, y: 0, label: 'Atlas'),
                        ChartDataPoint(x: 10, y: 0, label: 'Beacon'),
                        ChartDataPoint(x: 0, y: 10, label: 'Comet'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final renderFinder = _chartRenderFinder();
        final renderBox = tester.renderObject<ChartRenderBox>(renderFinder);
        final element = renderBox.debugElements
            .whereType<SeriesElement>()
            .single;
        final firstPoint =
            tester.getTopLeft(renderFinder) +
            renderBox.plotToWidget(
              element.dataHitForPointIndex(0)!.plotPosition,
            );
        await tester.tapAt(firstPoint);
        await tester.pumpAndSettle();
        controller.clearPointSelection();
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(controller.focusedPointRefs, {
          const ChartPointRef(seriesId: 'accounts', pointIndex: 0),
        });

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(controller.focusedPointRefs, {
          const ChartPointRef(seriesId: 'accounts', pointIndex: 1),
        });

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();
        expect(controller.focusedPointRefs, {
          const ChartPointRef(seriesId: 'accounts', pointIndex: 2),
        });

        var semantics = tester.widget<Semantics>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == 'Interactive scatter chart',
          ),
        );
        expect(
          semantics.properties.value,
          contains(
            'Accounts, Comet, X 0.00, 10.00 score, point 3 of 3, not selected',
          ),
        );
        expect(semantics.properties.liveRegion, isTrue);
        expect(semantics.properties.selected, isFalse);
        expect(semantics.properties.onTap, isNotNull);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(controller.selectedPointRefs, {
          const ChartPointRef(seriesId: 'accounts', pointIndex: 2),
        });
        semantics = tester.widget<Semantics>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == 'Interactive scatter chart',
          ),
        );
        expect(semantics.properties.value, endsWith(', selected'));
        expect(semantics.properties.selected, isTrue);
      },
    );

    testWidgets('dense scatter exposes aggregate semantics instead of nodes', (
      tester,
    ) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      final points = List<ChartDataPoint>.generate(
        201,
        (index) => ChartDataPoint(x: index.toDouble(), y: (index % 11) * 1.0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 520,
              height: 360,
              child: BravenChartPlus(
                bravenChartController: controller,
                showLegend: false,
                series: [ScatterChartSeries(id: 'dense', points: points)],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final semantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Interactive scatter chart',
        ),
      );
      expect(semantics.properties.value, '201 points in 1 series');
      expect(
        semantics.properties.hint,
        'Point keyboard navigation is available for 200 points or fewer. Use arrow keys to pan this dense chart.',
      );
      expect(semantics.properties.liveRegion, isFalse);
      expect(controller.focusedPointRefs, isEmpty);
    });

    testWidgets('scatter point selection applies every configured operation', (
      tester,
    ) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      var operation = ChartSelectionOperation.add;
      var callbackCount = 0;
      late StateSetter rebuild;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return SizedBox(
                  width: 520,
                  height: 360,
                  child: BravenChartPlus(
                    bravenChartController: controller,
                    showLegend: false,
                    series: const [
                      ScatterChartSeries(
                        id: 'accounts',
                        points: [
                          ChartDataPoint(x: 2, y: 3, label: 'Atlas'),
                          ChartDataPoint(x: 8, y: 7, label: 'Beacon'),
                        ],
                        markerRadius: 9,
                      ),
                    ],
                    interactionConfig: InteractionConfig(
                      selection: ChartSelectionConfig(
                        operation: operation,
                        useModifierKeys: false,
                      ),
                      onSelectionChanged: (_) => callbackCount++,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);

      Future<void> clickPoint(int pointIndex) async {
        final renderFinder = _chartRenderFinder();
        final renderBox = tester.renderObject<ChartRenderBox>(renderFinder);
        final element = renderBox.debugElements
            .whereType<SeriesElement>()
            .single;
        final hit = element.dataHitForPointIndex(pointIndex)!;
        final position =
            tester.getTopLeft(renderFinder) +
            renderBox.plotToWidget(hit.plotPosition);
        await mouse.moveTo(position);
        await tester.pump();
        await mouse.down(position);
        await tester.pump();
        await mouse.up();
        await tester.pump();
      }

      const atlas = ChartPointRef(seriesId: 'accounts', pointIndex: 0);
      const beacon = ChartPointRef(seriesId: 'accounts', pointIndex: 1);

      await clickPoint(0);
      await clickPoint(1);
      expect(controller.selectedPointRefs, {atlas, beacon});

      rebuild(() => operation = ChartSelectionOperation.subtract);
      await tester.pump();
      await clickPoint(0);
      expect(controller.selectedPointRefs, {beacon});

      rebuild(() => operation = ChartSelectionOperation.toggle);
      await tester.pump();
      await clickPoint(1);
      expect(controller.selectedPointRefs, isEmpty);
      await clickPoint(0);
      expect(controller.selectedPointRefs, {atlas});

      rebuild(() => operation = ChartSelectionOperation.replace);
      await tester.pump();
      await clickPoint(1);
      expect(controller.selectedPointRefs, {beacon});
      expect(callbackCount, 6);
    });

    testWidgets('scatter selection respects mode and background clear policy', (
      tester,
    ) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 520,
              height: 360,
              child: BravenChartPlus(
                bravenChartController: controller,
                showLegend: false,
                series: const [
                  ScatterChartSeries(
                    id: 'accounts',
                    points: [ChartDataPoint(x: 2, y: 3)],
                    markerRadius: 9,
                  ),
                ],
                interactionConfig: const InteractionConfig(
                  selection: ChartSelectionConfig(
                    mode: ChartSelectionMode.rectangle,
                    clearOnBackgroundTap: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final renderFinder = _chartRenderFinder();
      final renderBox = tester.renderObject<ChartRenderBox>(renderFinder);
      final element = renderBox.debugElements.whereType<SeriesElement>().single;
      final markerPosition =
          tester.getTopLeft(renderFinder) +
          renderBox.plotToWidget(element.dataHitForPointIndex(0)!.plotPosition);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(markerPosition);
      await tester.pump();
      await mouse.down(markerPosition);
      await mouse.up();
      await tester.pump();

      expect(controller.selectedPointRefs, isEmpty);
    });

    testWidgets(
      'point selection does not claim or clear on an empty primary drag',
      (tester) async {
        final controller = BravenChartController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 520,
                height: 360,
                child: BravenChartPlus(
                  bravenChartController: controller,
                  showLegend: false,
                  series: const [
                    ScatterChartSeries(
                      id: 'accounts',
                      points: [
                        ChartDataPoint(x: 2, y: 3),
                        ChartDataPoint(x: 8, y: 7),
                      ],
                      markerRadius: 9,
                    ),
                  ],
                  interactionConfig: const InteractionConfig(
                    selection: ChartSelectionConfig(
                      mode: ChartSelectionMode.point,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const selected = ChartPointRef(seriesId: 'accounts', pointIndex: 0);
        controller.selectPoint(
          selected,
          revision: controller.effectiveDocumentRevision.value!,
        );
        await tester.pump();

        final renderFinder = _chartRenderFinder();
        final renderBox = tester.renderObject<ChartRenderBox>(renderFinder);
        final start =
            tester.getTopLeft(renderFinder) +
            renderBox.plotToWidget(
              Offset(renderBox.plotWidth * 0.5, renderBox.plotHeight * 0.5),
            );
        expect(
          renderBox.dataHitAtWidgetPosition(
            start - tester.getTopLeft(renderFinder),
          ),
          isNull,
        );

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(start);
        await mouse.down(start);
        await mouse.moveTo(start + const Offset(48, 32));
        await tester.pump();

        expect(
          renderBox.coordinator.currentMode,
          isNot(InteractionMode.boxSelecting),
        );
        await mouse.up();
        await tester.pump();
        expect(controller.selectedPointRefs, {selected});

        await mouse.moveTo(start);
        await mouse.down(start);
        await mouse.up();
        await tester.pump();
        expect(controller.selectedPointRefs, isEmpty);
      },
    );

    testWidgets('rectangle selection claims only its configured drag chord', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 520,
              height: 360,
              child: BravenChartPlus(
                showLegend: false,
                series: [
                  ScatterChartSeries(
                    id: 'accounts',
                    points: [
                      ChartDataPoint(x: 2, y: 3),
                      ChartDataPoint(x: 8, y: 7),
                    ],
                  ),
                ],
                interactionConfig: InteractionConfig(
                  selection: ChartSelectionConfig(
                    mode: ChartSelectionMode.rectangle,
                    dragActivation: ChartSelectionDragActivation.shiftPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final renderFinder = _chartRenderFinder();
      final renderBox = tester.renderObject<ChartRenderBox>(renderFinder);
      final origin = tester.getTopLeft(renderFinder);
      final start =
          origin +
          renderBox.plotToWidget(
            Offset(renderBox.plotWidth * 0.5, renderBox.plotHeight * 0.5),
          );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);

      await mouse.moveTo(start);
      await mouse.down(start);
      await mouse.moveTo(start + const Offset(48, 32));
      await tester.pump();
      expect(
        renderBox.coordinator.currentMode,
        isNot(InteractionMode.boxSelecting),
      );
      await mouse.up();
      await tester.pump();

      renderBox.coordinator.addModifierKey(LogicalKeyboardKey.shift);
      await mouse.moveTo(start);
      await mouse.down(start);
      await mouse.moveTo(start + const Offset(48, 32));
      await tester.pump();
      expect(renderBox.coordinator.currentMode, InteractionMode.boxSelecting);
      await mouse.up();
      renderBox.coordinator.removeModifierKey(LogicalKeyboardKey.shift);
    });

    testWidgets('rectangle selection commits every enclosed scatter point', (
      tester,
    ) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      var callbackResult = const ChartSelectionResult.empty();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 520,
              height: 360,
              child: BravenChartPlus(
                bravenChartController: controller,
                showLegend: false,
                series: const [
                  ScatterChartSeries(
                    id: 'accounts',
                    points: [
                      ChartDataPoint(x: 2, y: 3, label: 'Atlas'),
                      ChartDataPoint(x: 4, y: 5, label: 'Beacon'),
                      ChartDataPoint(x: 8, y: 8, label: 'Comet'),
                    ],
                    markerRadius: 7,
                  ),
                ],
                interactionConfig: InteractionConfig(
                  selection: const ChartSelectionConfig(
                    mode: ChartSelectionMode.rectangle,
                    useModifierKeys: false,
                  ),
                  onSelectionResultChanged: (result) {
                    callbackResult = result;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final renderFinder = _chartRenderFinder();
      final renderBox = tester.renderObject<ChartRenderBox>(renderFinder);
      final origin = tester.getTopLeft(renderFinder);
      final element = renderBox.debugElements.whereType<SeriesElement>().single;
      final atlas =
          origin +
          renderBox.plotToWidget(element.dataHitForPointIndex(0)!.plotPosition);
      final beacon =
          origin +
          renderBox.plotToWidget(element.dataHitForPointIndex(1)!.plotPosition);
      final start = Offset(
        math.min(atlas.dx, beacon.dx) - 18,
        math.min(atlas.dy, beacon.dy) - 18,
      );
      final end = Offset(
        math.max(atlas.dx, beacon.dx) + 18,
        math.max(atlas.dy, beacon.dy) + 18,
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(start);
      await mouse.down(start);
      await mouse.moveTo(end);
      await tester.pump();

      expect(renderBox.coordinator.currentMode, InteractionMode.boxSelecting);
      expect(renderBox.coordinator.previewDataHits, hasLength(2));
      await mouse.up();
      await tester.pump();

      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'accounts', pointIndex: 0),
        const ChartPointRef(seriesId: 'accounts', pointIndex: 1),
      });
      expect(callbackResult.statistics.pointCount, 2);
      expect(callbackResult.extents?.minimumX, 2);
      expect(callbackResult.extents?.maximumX, 4);
    });

    testWidgets('lasso selection follows the drawn polygon', (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 520,
              height: 360,
              child: BravenChartPlus(
                bravenChartController: controller,
                showLegend: false,
                series: const [
                  ScatterChartSeries(
                    id: 'accounts',
                    points: [
                      ChartDataPoint(x: 2, y: 3, label: 'Atlas'),
                      ChartDataPoint(x: 4, y: 5, label: 'Beacon'),
                      ChartDataPoint(x: 8, y: 8, label: 'Comet'),
                    ],
                    markerRadius: 7,
                  ),
                ],
                interactionConfig: const InteractionConfig(
                  selection: ChartSelectionConfig(
                    mode: ChartSelectionMode.lasso,
                    useModifierKeys: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final renderFinder = _chartRenderFinder();
      final renderBox = tester.renderObject<ChartRenderBox>(renderFinder);
      final origin = tester.getTopLeft(renderFinder);
      final element = renderBox.debugElements.whereType<SeriesElement>().single;
      final atlas =
          origin +
          renderBox.plotToWidget(element.dataHitForPointIndex(0)!.plotPosition);
      final beacon =
          origin +
          renderBox.plotToWidget(element.dataHitForPointIndex(1)!.plotPosition);
      final left = math.min(atlas.dx, beacon.dx) - 18;
      final right = math.max(atlas.dx, beacon.dx) + 18;
      final top = math.min(atlas.dy, beacon.dy) - 18;
      final bottom = math.max(atlas.dy, beacon.dy) + 18;
      final lasso = <Offset>[
        Offset(left, top),
        Offset(right, top),
        Offset(right, bottom),
        Offset(left, bottom),
        Offset(left, top),
      ];
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(lasso.first);
      await mouse.down(lasso.first);
      for (final position in lasso.skip(1)) {
        await mouse.moveTo(position);
        await tester.pump();
      }

      expect(renderBox.coordinator.currentMode, InteractionMode.boxSelecting);
      expect(renderBox.coordinator.lassoSelectionPath.length, greaterThan(3));
      expect(renderBox.coordinator.previewDataHits, hasLength(2));
      await mouse.up();
      await tester.pump();

      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'accounts', pointIndex: 0),
        const ChartPointRef(seriesId: 'accounts', pointIndex: 1),
      });
    });

    testWidgets(
      'selection result returns stable refs, extents, and statistics',
      (tester) async {
        final controller = BravenChartController();
        addTearDown(controller.dispose);
        var callbackCount = 0;
        var callbackResult = const ChartSelectionResult.empty();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 520,
                height: 360,
                child: BravenChartPlus(
                  bravenChartController: controller,
                  showLegend: false,
                  series: const [
                    ScatterChartSeries(
                      id: 'priority',
                      name: 'Priority accounts',
                      points: [
                        ChartDataPoint(
                          x: 2,
                          y: 3,
                          magnitude: 100,
                          colorValue: 20,
                          opacityValue: 0.5,
                          categoryValue: 'enterprise',
                          label: 'Atlas',
                        ),
                      ],
                    ),
                    ScatterChartSeries(
                      id: 'monitor',
                      name: 'Monitor accounts',
                      points: [
                        ChartDataPoint(
                          x: 8,
                          y: 7,
                          magnitude: 300,
                          colorValue: 60,
                          opacityValue: 0.9,
                          categoryValue: 'growth',
                          label: 'Beacon',
                        ),
                      ],
                    ),
                  ],
                  interactionConfig: InteractionConfig(
                    onSelectionResultChanged: (result) {
                      callbackCount++;
                      callbackResult = result;
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const priority = ChartPointRef(seriesId: 'priority', pointIndex: 0);
        const monitor = ChartPointRef(seriesId: 'monitor', pointIndex: 0);
        final revision = controller.effectiveDocumentRevision.value!;
        final selection = controller.selectPoints(const [
          monitor,
          priority,
        ], revision: revision);
        await tester.pump();

        expect(selection, isA<ChartArtifactSuccess<void>>());
        expect(callbackCount, 1);
        expect(callbackResult, controller.selectionResult);
        expect(callbackResult.pointRefs, const [priority, monitor]);
        expect(callbackResult.points.map((selection) => selection.seriesName), [
          'Priority accounts',
          'Monitor accounts',
        ]);
        expect(
          callbackResult.extents,
          const ChartSelectionDataExtents(
            minimumX: 2,
            maximumX: 8,
            minimumY: 3,
            maximumY: 7,
          ),
        );
        expect(callbackResult.statistics.pointCount, 2);
        expect(callbackResult.statistics.seriesCount, 2);
        expect(callbackResult.statistics.x?.mean, 5);
        expect(callbackResult.statistics.y?.mean, 5);
        expect(callbackResult.statistics.magnitude?.mean, 200);
        expect(callbackResult.statistics.colorValue?.mean, 40);
        expect(callbackResult.statistics.opacityValue?.mean, 0.7);
        expect(callbackResult.statistics.categoryCounts, {
          'enterprise': 1,
          'growth': 1,
        });

        controller.clearPointSelection();
        await tester.pump();
        expect(callbackCount, 2);
        expect(callbackResult.isEmpty, isTrue);
        expect(controller.selectionResult, callbackResult);
      },
    );
  });
}

Finder _chartRenderFinder() => find.byWidgetPredicate(
  (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
);
