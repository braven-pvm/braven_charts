import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'stationary hover keeps one published tracking resolution across repaints',
    (tester) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      final renderBox =
          _chartRenderFinder().evaluate().single.renderObject!
              as ChartRenderBox;
      expect(renderBox.debugTrackingSnapshot, isNull);
      expect(renderBox.debugTrackingPublishCount, 0);

      final target =
          tester.getTopLeft(find.byType(BravenChartPlus)) +
          renderBox.plotToWidget(renderBox.transform!.dataToPlot(4.4, 6));
      final pointer = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(target);
      await tester.pump();

      final snapshot = renderBox.debugTrackingSnapshot;
      expect(snapshot, isNotNull);
      expect(snapshot!.values, hasLength(2));
      expect(renderBox.debugTrackingPublishCount, 1);
      final resolveCountAfterHover = renderBox.debugTrackingResolveCount;
      expect(resolveCountAfterHover, greaterThan(0));
      final computeCountAfterHover = renderBox.debugTrackingComputeCount;
      expect(computeCountAfterHover, greaterThan(0));

      // Three extra frames without moving the cursor: paint consults the
      // resolver each repaint, but the memoized inputs short-circuit to the
      // identical published snapshot instance — nothing is recomputed or
      // republished.
      for (var frame = 0; frame < 3; frame++) {
        renderBox.markNeedsPaint();
        await tester.pump();
        expect(renderBox.debugTrackingSnapshot, same(snapshot));
        expect(renderBox.debugTrackingPublishCount, 1);
        expect(
          renderBox.debugTrackingComputeCount,
          computeCountAfterHover,
          reason: 'a stationary repaint must never recompute the snapshot',
        );
      }
      expect(
        renderBox.debugTrackingResolveCount,
        greaterThan(resolveCountAfterHover),
        reason: 'repaints consult the resolver (cache hits, not recomputes)',
      );

      // Accessing the sync/debug hooks must not add resolutions beyond the
      // cached path: without a synchronized cursor they resolve nothing, and
      // the snapshot getter is a pure read.
      final resolveCountBeforeHooks = renderBox.debugTrackingResolveCount;
      expect(renderBox.debugTrackingSnapshot, same(snapshot));
      expect(renderBox.debugSynchronizedCursorX, isNull);
      expect(renderBox.debugSynchronizedCursorPosition, isNull);
      expect(renderBox.debugSynchronizedTrackingState, isNull);
      expect(renderBox.debugTrackingResolveCount, resolveCountBeforeHooks);
      expect(renderBox.debugTrackingPublishCount, 1);
    },
  );

  testWidgets(
    'series color change while hovering the same datum republishes the '
    'fresh color',
    (tester) async {
      await tester.pumpWidget(_host(speedColor: const Color(0xFF2196F3)));
      await tester.pumpAndSettle();

      final renderBox =
          _chartRenderFinder().evaluate().single.renderObject!
              as ChartRenderBox;
      final target =
          tester.getTopLeft(find.byType(BravenChartPlus)) +
          renderBox.plotToWidget(renderBox.transform!.dataToPlot(4.4, 6));
      final pointer = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(target);
      await tester.pump();

      final before = renderBox.debugTrackingSnapshot;
      expect(before, isNotNull);
      expect(before!.values.first.seriesColor, const Color(0xFF2196F3));

      // Same hover, same snapped datum, changed series color. The forced
      // invalidation from the series change must republish the recomputed
      // snapshot even though its datum identity is unchanged.
      await tester.pumpWidget(_host(speedColor: const Color(0xFFFF5722)));
      await tester.pump();

      final after = renderBox.debugTrackingSnapshot;
      expect(after, isNotNull);
      expect(after!.values.first.seriesColor, const Color(0xFFFF5722));
    },
  );

  testWidgets('moving the cursor off the chart clears the published snapshot', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    final renderBox =
        _chartRenderFinder().evaluate().single.renderObject! as ChartRenderBox;
    final target =
        tester.getTopLeft(find.byType(BravenChartPlus)) +
        renderBox.plotToWidget(renderBox.transform!.dataToPlot(4.4, 6));
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(pointer.removePointer);
    await pointer.addPointer(location: Offset.zero);
    await pointer.moveTo(target);
    await tester.pump();

    expect(renderBox.debugTrackingSnapshot, isNotNull);
    final publishCountWhileHovering = renderBox.debugTrackingPublishCount;

    // Leaving the chart publishes a null snapshot exactly once, so future
    // consumers of the resolver never observe the stale hover state.
    await pointer.moveTo(const Offset(2, 2));
    await tester.pump();

    expect(renderBox.debugTrackingSnapshot, isNull);
    expect(
      renderBox.debugTrackingPublishCount,
      publishCountWhileHovering + 1,
    );
  });
}

Widget _host({Color? speedColor}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 640,
          height: 300,
          child: BravenChartPlus(
            showLegend: false,
            interactionConfig: const InteractionConfig(
              crosshair: CrosshairConfig(
                displayMode: CrosshairDisplayMode.tracking,
              ),
            ),
            series: [
              LineChartSeries(
                id: 'speed',
                color: speedColor,
                points: const [
                  ChartDataPoint(x: 0, y: 4),
                  ChartDataPoint(x: 2, y: 8),
                  ChartDataPoint(x: 4, y: 7),
                  ChartDataPoint(x: 6, y: 11),
                  ChartDataPoint(x: 8, y: 9),
                  ChartDataPoint(x: 10, y: 12),
                ],
              ),
              const LineChartSeries(
                id: 'power',
                points: [
                  ChartDataPoint(x: 0, y: 2),
                  ChartDataPoint(x: 2, y: 5),
                  ChartDataPoint(x: 4, y: 3),
                  ChartDataPoint(x: 6, y: 6),
                  ChartDataPoint(x: 8, y: 4),
                  ChartDataPoint(x: 10, y: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Finder _chartRenderFinder() => find.byWidgetPredicate(
  (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
);
