import 'package:braven_charts/src/braven_chart_plus.dart';
import 'package:braven_charts/src/artifacts/chart_view_state.dart';
import 'package:braven_charts/src/interaction/core/interaction_mode.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/braven_chart_controller.dart';
import 'package:braven_charts/src/models/interaction_config.dart';
import 'package:braven_charts/src/models/interaction_callbacks.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'browse profile leaves one-finger dragging to the parent scrollable',
    (tester) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      await tester.pumpWidget(
        _TouchHarness(
          scrollController: scrollController,
          touch: const TouchInteractionConfig(),
        ),
      );

      final chartCenter = tester.getCenter(find.byType(BravenChartPlus));
      final gesture = await tester.createGesture(
        pointer: 1,
        kind: PointerDeviceKind.touch,
      );
      await gesture.down(chartCenter);
      await tester.pump();
      await gesture.moveBy(const Offset(0, -40));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -100));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(scrollController.offset, greaterThan(0));
    },
  );

  testWidgets('browse profile pinches without scrolling the parent', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    await tester.pumpWidget(
      _TouchHarness(
        scrollController: scrollController,
        touch: const TouchInteractionConfig(),
      ),
    );

    final renderBox = tester.renderObject<ChartRenderBox>(_chartRenderFinder());
    final initialSpan =
        renderBox.transform!.dataXMax - renderBox.transform!.dataXMin;
    final chartCenter = tester.getCenter(find.byType(BravenChartPlus));
    final first = await tester.createGesture(
      pointer: 1,
      kind: PointerDeviceKind.touch,
    );
    final second = await tester.createGesture(
      pointer: 2,
      kind: PointerDeviceKind.touch,
    );
    await first.down(chartCenter - const Offset(35, 0));
    await second.down(chartCenter + const Offset(35, 0));
    await tester.pump();
    await first.moveTo(chartCenter - const Offset(85, 0));
    await second.moveTo(chartCenter + const Offset(85, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pumpAndSettle();

    final zoomedSpan =
        renderBox.transform!.dataXMax - renderBox.transform!.dataXMin;
    expect(zoomedSpan, lessThan(initialSpan));
    expect(scrollController.offset, 0);
  });

  testWidgets('explore profile pans with one finger after drag slop', (
    tester,
  ) async {
    final scrollController = ScrollController();
    final chartController = BravenChartController();
    addTearDown(scrollController.dispose);
    addTearDown(chartController.dispose);
    await tester.pumpWidget(
      _TouchHarness(
        scrollController: scrollController,
        chartController: chartController,
        touch: const TouchInteractionConfig(
          profile: TouchInteractionProfile.explore,
        ),
      ),
    );

    final renderBox = tester.renderObject<ChartRenderBox>(_chartRenderFinder());
    expect(chartController.zoomViewport(2), isTrue);
    await tester.pumpAndSettle();
    final initialMin = renderBox.transform!.dataXMin;
    final chartCenter = tester.getCenter(find.byType(BravenChartPlus));
    final gesture = await tester.createGesture(
      pointer: 1,
      kind: PointerDeviceKind.touch,
    );
    await gesture.down(chartCenter);
    await tester.pump();
    await gesture.moveBy(const Offset(-90, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(renderBox.transform!.dataXMin, isNot(initialMin));
    expect(scrollController.offset, 0);

    expect(chartController.fitData(), isTrue);
    await tester.pump();
    expect(renderBox.transform!.dataXMin, lessThan(initialMin));
  });

  testWidgets('explore profile transitions from one-finger pan to pinch zoom', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    await tester.pumpWidget(
      _TouchHarness(
        scrollController: scrollController,
        touch: const TouchInteractionConfig(
          profile: TouchInteractionProfile.explore,
        ),
      ),
    );

    final renderBox = tester.renderObject<ChartRenderBox>(_chartRenderFinder());
    final chartCenter = tester.getCenter(find.byType(BravenChartPlus));
    final first = await tester.createGesture(
      pointer: 21,
      kind: PointerDeviceKind.touch,
    );
    final second = await tester.createGesture(
      pointer: 22,
      kind: PointerDeviceKind.touch,
    );

    await first.down(chartCenter - const Offset(35, 0));
    await tester.pump();
    await first.moveBy(const Offset(12, 0));
    await tester.pump();
    final spanAfterOneFingerMove =
        renderBox.transform!.dataXMax - renderBox.transform!.dataXMin;

    await second.down(chartCenter + const Offset(35, 0));
    await tester.pump();
    await first.moveTo(chartCenter - const Offset(90, 0));
    await second.moveTo(chartCenter + const Offset(90, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pumpAndSettle();

    final zoomedSpan =
        renderBox.transform!.dataXMax - renderBox.transform!.dataXMin;
    expect(zoomedSpan, lessThan(spanAfterOneFingerMove));
    expect(scrollController.offset, 0);
  });

  testWidgets('browse profile preserves touch point selection', (tester) async {
    final scrollController = ScrollController();
    final chartController = BravenChartController();
    addTearDown(scrollController.dispose);
    addTearDown(chartController.dispose);
    await tester.pumpWidget(
      _TouchHarness(
        scrollController: scrollController,
        chartController: chartController,
        touch: const TouchInteractionConfig(),
      ),
    );
    await tester.pumpAndSettle();

    final renderBox = tester.renderObject<ChartRenderBox>(_chartRenderFinder());
    final localPoint = renderBox.plotToWidget(
      renderBox.transform!.dataToPlot(2, 3),
    );
    expect(
      renderBox.dataHitAtWidgetPosition(localPoint)?.pointIndex,
      2,
      reason: 'the test tap must resolve the intended marker',
    );
    final touch = await tester.createGesture(
      pointer: 7,
      kind: PointerDeviceKind.touch,
    );
    await touch.down(renderBox.localToGlobal(localPoint));
    await tester.pump();
    await touch.up();
    await tester.pumpAndSettle();

    expect(chartController.selectedPointRefs, {
      const ChartPointRef(seriesId: 'mobile-signal', pointIndex: 2),
    });
    expect(scrollController.offset, 0);
  });

  testWidgets(
    'long press scrubs the shared tracking cursor and clears on lift',
    (tester) async {
      final scrollController = ScrollController();
      final trackedX = <double?>[];
      ChartDataPoint? longPressedPoint;
      addTearDown(scrollController.dispose);
      await tester.pumpWidget(
        _TouchHarness(
          scrollController: scrollController,
          touch: const TouchInteractionConfig(enableHapticFeedback: false),
          gesture: const GestureConfig(
            longPressTimeout: Duration(milliseconds: 100),
          ),
          onCrosshairChanged: (position, points) {
            trackedX.add(
              position == null || points.isEmpty ? null : points.first.x,
            );
          },
          onDataPointLongPress: (point, position) {
            longPressedPoint = point;
          },
        ),
      );
      await tester.pumpAndSettle();

      final renderBox = tester.renderObject<ChartRenderBox>(
        _chartRenderFinder(),
      );
      final start = renderBox.localToGlobal(
        renderBox.plotToWidget(renderBox.transform!.dataToPlot(2, 3)),
      );
      final end = renderBox.localToGlobal(
        renderBox.plotToWidget(renderBox.transform!.dataToPlot(4, 6)),
      );
      final touch = await tester.createGesture(
        pointer: 9,
        kind: PointerDeviceKind.touch,
      );
      await touch.down(start);
      await tester.pump(const Duration(milliseconds: 120));

      expect(renderBox.coordinator.currentMode, InteractionMode.trackingScrub);
      expect(trackedX, contains(2));
      expect(longPressedPoint, const ChartDataPoint(x: 2, y: 3));

      await touch.moveTo(end);
      await tester.pump();
      expect(trackedX, contains(4));

      await touch.up();
      await tester.pump();
      expect(renderBox.coordinator.currentMode, InteractionMode.idle);
      expect(trackedX.last, isNull);
      expect(scrollController.offset, 0);
    },
  );

  testWidgets('touch tracking can be disabled without changing tap behavior', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    await tester.pumpWidget(
      _TouchHarness(
        scrollController: scrollController,
        touch: const TouchInteractionConfig(enableLongPressTracking: false),
        gesture: const GestureConfig(
          longPressTimeout: Duration(milliseconds: 100),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final renderBox = tester.renderObject<ChartRenderBox>(_chartRenderFinder());
    final point = renderBox.localToGlobal(
      renderBox.plotToWidget(renderBox.transform!.dataToPlot(2, 3)),
    );
    final touch = await tester.createGesture(
      pointer: 10,
      kind: PointerDeviceKind.touch,
    );
    await touch.down(point);
    await tester.pump(const Duration(milliseconds: 120));

    expect(
      renderBox.coordinator.currentMode,
      isNot(InteractionMode.trackingScrub),
    );

    await touch.up();
    await tester.pumpAndSettle();
  });
}

class _TouchHarness extends StatelessWidget {
  const _TouchHarness({
    required this.scrollController,
    required this.touch,
    this.chartController,
    this.gesture = const GestureConfig(),
    this.onCrosshairChanged,
    this.onDataPointLongPress,
  });

  final ScrollController scrollController;
  final TouchInteractionConfig touch;
  final BravenChartController? chartController;
  final GestureConfig gesture;
  final CrosshairChangeCallback? onCrosshairChanged;
  final DataPointLongPressCallback? onDataPointLongPress;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          controller: scrollController,
          children: [
            const SizedBox(height: 200),
            SizedBox(
              height: 320,
              child: BravenChartPlus(
                bravenChartController: chartController,
                showLegend: false,
                interactionConfig: InteractionConfig(
                  touch: touch,
                  gesture: gesture,
                  tooltip: const TooltipConfig(
                    triggerMode: TooltipTriggerMode.tap,
                  ),
                  onCrosshairChanged: onCrosshairChanged,
                  onDataPointLongPress: onDataPointLongPress,
                ),
                series: const [
                  LineChartSeries(
                    id: 'mobile-signal',
                    showDataPointMarkers: true,
                    points: [
                      ChartDataPoint(x: 0, y: 2),
                      ChartDataPoint(x: 1, y: 5),
                      ChartDataPoint(x: 2, y: 3),
                      ChartDataPoint(x: 3, y: 8),
                      ChartDataPoint(x: 4, y: 6),
                      ChartDataPoint(x: 5, y: 10),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 900),
          ],
        ),
      ),
    );
  }
}

Finder _chartRenderFinder() => find.byWidgetPredicate(
  (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
);
