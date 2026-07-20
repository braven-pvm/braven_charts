// Copyright 2025 Braven Charts
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'synchronized frames resolve the receiving chart snapshot exactly once',
    (tester) async {
      final group = ChartInteractionGroupController();
      addTearDown(group.dispose);

      await tester.pumpWidget(_host(group));
      await tester.pumpAndSettle();

      final renderElements = _chartRenderFinder().evaluate().toList();
      final firstFinder = find.byElementPredicate(
        (element) => element == renderElements.first,
      );
      final first = renderElements[0].renderObject! as ChartRenderBox;
      final second = renderElements[1].renderObject! as ChartRenderBox;

      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);

      Offset chartOneTarget(double dataX) =>
          tester.getTopLeft(firstFinder) +
          first.plotToWidget(
            first.transform!.dataToPlot(
              dataX,
              (first.transform!.dataYMin + first.transform!.dataYMax) / 2,
            ),
          );

      // Drive the shared cursor across several data-X positions. The scatter
      // chart receiving the synchronized cursor is Y-sensitive: the mid-plot
      // pre-adjustment cursor and the Y-adjusted paint cursor resolve
      // different nearest scatter points, so a second per-frame resolution
      // would both double-compute and ping-pong publication. Each sync
      // change must compute exactly once and publish at most one change.
      var computeBefore = second.debugTrackingComputeCount;
      var publishBefore = second.debugTrackingPublishCount;
      for (final dataX in const [5.0, 6.2, 5.0]) {
        await pointer.moveTo(chartOneTarget(dataX));
        await tester.pump();
        expect(second.debugSynchronizedCursorX, closeTo(dataX, 0.0001));
        expect(
          second.debugTrackingComputeCount - computeBefore,
          1,
          reason: 'one snapshot compute per synchronized cursor change',
        );
        expect(
          second.debugTrackingPublishCount - publishBefore,
          lessThanOrEqualTo(1),
          reason: 'no publish ping-pong between pre- and post-adjust cursors',
        );
        computeBefore = second.debugTrackingComputeCount;
        publishBefore = second.debugTrackingPublishCount;
      }

      // A stationary synchronized cursor across forced repaints: the memoized
      // sync position and the retained resolution keep both counters flat.
      final snapshot = second.debugTrackingSnapshot;
      expect(snapshot, isNotNull);

      // Pin the resolution target itself: the single retained resolution is
      // the sync-position computation's (it runs at the mid-plot
      // pre-adjustment cursor and its first tracked value FEEDS the cursor's
      // Y adjustment; the paint path deliberately reuses it instead of
      // re-resolving at the adjusted cursor). At dataX 5.0 the scatter
      // series therefore resolves its mid-plot point (5, 50), never
      // ping-ponging to the near-baseline point (5.6, 4).
      final scatterValue = snapshot!.values.firstWhere(
        (value) => value.seriesId == 'bubbles',
      );
      expect(scatterValue.x, closeTo(5.0, 1e-6));
      expect(scatterValue.y, closeTo(50, 1e-6));
      for (var frame = 0; frame < 3; frame++) {
        second.markNeedsPaint();
        await tester.pump();
        expect(second.debugTrackingComputeCount, computeBefore);
        expect(second.debugTrackingPublishCount, publishBefore);
        expect(second.debugTrackingSnapshot, same(snapshot));
      }

      // The debug sync-tracking hook shares the same retained resolution
      // rather than adding one at the adjusted cursor.
      expect(second.debugSynchronizedTrackingState, isNotNull);
      expect(second.debugTrackingComputeCount, computeBefore);
      expect(second.debugTrackingPublishCount, publishBefore);
    },
  );
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
                ],
              ),
            ),
            SizedBox(
              width: 460,
              height: 240,
              child: BravenChartPlus(
                interactionGroupController: group,
                showLegend: false,
                interactionConfig: const InteractionConfig(
                  crosshair: CrosshairConfig(
                    displayMode: CrosshairDisplayMode.tracking,
                  ),
                ),
                series: const [
                  // A flat baseline keeps the first tracked value (and the
                  // synchronized cursor's Y adjustment) near the bottom of
                  // the plot, far from the mid-plot pre-adjustment cursor.
                  LineChartSeries(
                    id: 'baseline',
                    points: [
                      ChartDataPoint(x: 0, y: 2),
                      ChartDataPoint(x: 10, y: 2),
                    ],
                  ),
                  // One scatter point near mid-plot Y (nearest to the
                  // pre-adjustment cursor) and one near the baseline
                  // (nearest to the Y-adjusted cursor).
                  ScatterChartSeries(
                    id: 'bubbles',
                    points: [
                      ChartDataPoint(x: 5, y: 50),
                      ChartDataPoint(x: 5.6, y: 4),
                      ChartDataPoint(x: 2, y: 100),
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
