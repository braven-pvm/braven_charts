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

      // Three extra frames without moving the cursor: paint consults the
      // resolver each repaint, but the memoized inputs short-circuit to the
      // identical published snapshot instance — nothing is republished.
      for (var frame = 0; frame < 3; frame++) {
        renderBox.markNeedsPaint();
        await tester.pump();
        expect(renderBox.debugTrackingSnapshot, same(snapshot));
        expect(renderBox.debugTrackingPublishCount, 1);
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
}

Widget _host() {
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
            series: const [
              LineChartSeries(
                id: 'speed',
                points: [
                  ChartDataPoint(x: 0, y: 4),
                  ChartDataPoint(x: 2, y: 8),
                  ChartDataPoint(x: 4, y: 7),
                  ChartDataPoint(x: 6, y: 11),
                  ChartDataPoint(x: 8, y: 9),
                  ChartDataPoint(x: 10, y: 12),
                ],
              ),
              LineChartSeries(
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
