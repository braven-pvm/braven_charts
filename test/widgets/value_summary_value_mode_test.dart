// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

// Task 17 — CartesianValueSummaryConfig.valueMode: an explicit choice between
// tracking the interpolated curve (default, the pre-existing behavior) and
// snapping the summary's rows to actual data points.
//
// The resolution-strategy contract under test:
//   - COMPATIBLE paths reuse the chart's shared pointer-path resolver with
//     zero extra resolutions: interpolated mode always; dataPoints mode while
//     the crosshair's interpolation is off or while the crosshair does not
//     consume the shared tracking resolution (disabled / non-tracking mode).
//   - The DIVERGENT path (crosshair actively tracking WITH interpolation
//     while the summary wants data points) runs exactly one dedicated,
//     memoized resolution per cursor change — never per repaint — and leaves
//     the shared resolver's memo untouched.

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('value mode behavior', () {
    testWidgets(
      'dataPoints mode shows the actual datum while hovering between samples',
      (tester) async {
        // Interpolated baseline: the crosshair interpolates and the summary
        // (default mode) rides the same resolution — curve values between
        // samples.
        await tester.pumpWidget(
          _host(
            interaction: _interaction(
              interpolateCrosshair: true,
              valueMode: CartesianValueSummaryValueMode.interpolated,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final renderBox = _renderBox(tester);

        final pointer = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(pointer.removePointer);
        await pointer.addPointer(location: Offset.zero);
        await pointer.moveTo(_plotTarget(tester, renderBox, 4.6, 6));
        await tester.pump();

        final interpolatedSnapshot = renderBox.debugValueSummarySnapshot;
        expect(interpolatedSnapshot, isNotNull);
        final interpolatedSpeed = interpolatedSnapshot!.values.firstWhere(
          (value) => value.seriesId == 'speed',
        );
        expect(interpolatedSpeed.isInterpolated, isTrue);
        // Linear segment (4, 7) -> (6, 11) sampled at x = 4.6.
        expect(interpolatedSpeed.y, closeTo(8.2, 1e-6));
        final interpolatedFormattedY = interpolatedSpeed.formattedY;

        // Same chart, same cursor, dataPoints mode: the summary snaps to the
        // real sample (4, 7) even though the crosshair keeps interpolating.
        await tester.pumpWidget(
          _host(
            interaction: _interaction(
              interpolateCrosshair: true,
              valueMode: CartesianValueSummaryValueMode.dataPoints,
            ),
          ),
        );
        await tester.pump();

        final snappedSnapshot = renderBox.debugValueSummarySnapshot;
        expect(snappedSnapshot, isNotNull);
        final snappedSpeed = snappedSnapshot!.values.firstWhere(
          (value) => value.seriesId == 'speed',
        );
        expect(snappedSpeed.isInterpolated, isFalse);
        expect(snappedSpeed.x, closeTo(4, 1e-6));
        expect(snappedSpeed.y, 7);
        expect(snappedSpeed.dataPointIndex, 2);
        expect(snappedSpeed.formattedY, isNot(interpolatedFormattedY));

        // Every non-trend row snaps, not just the primary series.
        final snappedPower = snappedSnapshot.values.firstWhere(
          (value) => value.seriesId == 'power',
        );
        expect(snappedPower.isInterpolated, isFalse);
        expect(snappedPower.y, 3);

        // The displayed rows carry the snapped values (tooltip parity: the
        // formatted string of the actual datum, not the curve sample).
        final model = renderBox.debugValueSummaryModel;
        expect(model, isNotNull);
        expect(
          model!.rows.map((row) => row.value),
          contains(snappedSpeed.formattedY),
        );
        expect(
          model.rows.map((row) => row.value),
          isNot(contains(interpolatedFormattedY)),
        );
      },
    );

    testWidgets(
      'dataPoints mode with a non-interpolating crosshair reuses the shared '
      'snapshot instance',
      (tester) async {
        await tester.pumpWidget(
          _host(
            interaction: _interaction(
              interpolateCrosshair: false,
              valueMode: CartesianValueSummaryValueMode.dataPoints,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final renderBox = _renderBox(tester);

        final pointer = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(pointer.removePointer);
        await pointer.addPointer(location: Offset.zero);
        await pointer.moveTo(_plotTarget(tester, renderBox, 4.6, 6));
        await tester.pump();

        // One shared resolution serves crosshair and summary; the dedicated
        // divergent-mode resolver is never touched.
        expect(renderBox.debugTrackingComputeCount, 1);
        expect(
          renderBox.debugValueSummarySnapshot,
          same(renderBox.debugTrackingSnapshot),
        );
        expect(renderBox.debugSummaryTrackingResolveCount, 0);
      },
    );
  });

  group('compatible path count guard', () {
    testWidgets(
      'crosshair disabled: dataPoints resolve counts match the interpolated '
      'baseline with zero dedicated resolutions',
      (tester) async {
        final pointer = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(pointer.removePointer);
        await pointer.addPointer(location: Offset.zero);

        Future<({int sharedComputes, int dedicatedResolves})> run(
          CartesianValueSummaryValueMode valueMode,
        ) async {
          await tester.pumpWidget(
            _host(
              interaction: _interaction(
                crosshairEnabled: false,
                interpolateCrosshair: true,
                valueMode: valueMode,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final renderBox = _renderBox(tester);
          final computeBefore = renderBox.debugTrackingComputeCount;
          final dedicatedBefore = renderBox.debugSummaryTrackingResolveCount;
          for (final dataX in const [3.4, 5.8, 7.6]) {
            await pointer.moveTo(_plotTarget(tester, renderBox, dataX, 6));
            await tester.pump();
          }
          final result = (
            sharedComputes:
                renderBox.debugTrackingComputeCount - computeBefore,
            dedicatedResolves:
                renderBox.debugSummaryTrackingResolveCount - dedicatedBefore,
          );
          // Park the pointer outside the plot between runs.
          await pointer.moveTo(const Offset(2, 2));
          await tester.pump();
          return result;
        }

        final baseline = await run(CartesianValueSummaryValueMode.interpolated);
        final snapped = await run(CartesianValueSummaryValueMode.dataPoints);

        // The summary owns the resolve either way; the mode only flips the
        // interpolation flag of the one shared resolution per cursor change.
        expect(snapped.sharedComputes, baseline.sharedComputes);
        expect(baseline.dedicatedResolves, 0);
        expect(snapped.dedicatedResolves, 0);

        // The snapped run really produced data-point rows.
        final renderBox = _renderBox(tester);
        await pointer.moveTo(_plotTarget(tester, renderBox, 4.6, 6));
        await tester.pump();
        final snapshot = renderBox.debugValueSummarySnapshot;
        expect(snapshot!.origin, CartesianTrackingOrigin.pointer);
        final speed = snapshot.values.firstWhere(
          (value) => value.seriesId == 'speed',
        );
        expect(speed.isInterpolated, isFalse);
        expect(speed.y, 7);
      },
    );
  });

  group('divergent path', () {
    testWidgets(
      'crosshair interpolates while the summary snaps — both correct, one '
      'memoized extra resolution per cursor change',
      (tester) async {
        await tester.pumpWidget(
          _host(
            interaction: _interaction(
              interpolateCrosshair: true,
              valueMode: CartesianValueSummaryValueMode.dataPoints,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final renderBox = _renderBox(tester);
        expect(renderBox.debugSummaryTrackingResolveCount, 0);

        final sharedComputeBefore = renderBox.debugTrackingComputeCount;
        final pointer = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(pointer.removePointer);
        await pointer.addPointer(location: Offset.zero);
        await pointer.moveTo(_plotTarget(tester, renderBox, 4.6, 6));
        await tester.pump();

        // The crosshair's shared snapshot stays interpolated (the tracking
        // tooltip keeps its curve value)...
        final crosshairSnapshot = renderBox.debugTrackingSnapshot;
        expect(crosshairSnapshot, isNotNull);
        final crosshairSpeed = crosshairSnapshot!.values.firstWhere(
          (value) => value.seriesId == 'speed',
        );
        expect(crosshairSpeed.isInterpolated, isTrue);
        expect(crosshairSpeed.y, closeTo(8.2, 1e-6));

        // ...while the summary displays the snapped datum from its dedicated
        // resolution.
        final summarySnapshot = renderBox.debugValueSummarySnapshot;
        expect(summarySnapshot, isNot(same(crosshairSnapshot)));
        final summarySpeed = summarySnapshot!.values.firstWhere(
          (value) => value.seriesId == 'speed',
        );
        expect(summarySpeed.isInterpolated, isFalse);
        expect(summarySpeed.y, 7);

        // Exactly one computation per resolver for the frame: the shared
        // memo was not thrashed by the divergent preference.
        expect(renderBox.debugTrackingComputeCount - sharedComputeBefore, 1);
        expect(renderBox.debugSummaryTrackingComputeCount, 1);
        expect(renderBox.debugSummaryTrackingPublishCount, 1);
        final reduceAfterHover = renderBox.debugValueSummaryReduceCount;

        // Stationary repaints: both resolvers memoize — zero recomputation,
        // zero re-reduction.
        for (var frame = 0; frame < 3; frame++) {
          renderBox.markNeedsPaint();
          await tester.pump();
        }
        expect(renderBox.debugTrackingComputeCount - sharedComputeBefore, 1);
        expect(renderBox.debugSummaryTrackingComputeCount, 1);
        expect(renderBox.debugSummaryTrackingPublishCount, 1);
        expect(renderBox.debugValueSummaryReduceCount, reduceAfterHover);

        // Cursor movement within the same snapped datum recomputes for the
        // new cursor but republishes nothing: same snapshot instance, no
        // re-reduction (+0 per frame, not +1).
        await pointer.moveTo(_plotTarget(tester, renderBox, 4.5, 6));
        await tester.pump();
        expect(renderBox.debugSummaryTrackingPublishCount, 1);
        expect(renderBox.debugValueSummarySnapshot, same(summarySnapshot));
        expect(renderBox.debugValueSummaryReduceCount, reduceAfterHover);

        // Crossing to the next datum publishes and reduces exactly once.
        await pointer.moveTo(_plotTarget(tester, renderBox, 5.8, 6));
        await tester.pump();
        expect(renderBox.debugSummaryTrackingPublishCount, 2);
        expect(renderBox.debugValueSummaryReduceCount, reduceAfterHover + 1);
        final nextSpeed = renderBox.debugValueSummarySnapshot!.values
            .firstWhere((value) => value.seriesId == 'speed');
        expect(nextSpeed.isInterpolated, isFalse);
        expect(nextSpeed.x, closeTo(6, 1e-6));
        expect(nextSpeed.y, 11);

        // Whole-sweep discipline: one computation per resolver per cursor
        // change (3 moves), never two shared computations per frame.
        expect(renderBox.debugTrackingComputeCount - sharedComputeBefore, 3);
        expect(renderBox.debugSummaryTrackingComputeCount, 3);
      },
    );

    testWidgets(
      'divergent summary adds nothing to the crosshair-only shared compute '
      'count',
      (tester) async {
        final pointer = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(pointer.removePointer);
        await pointer.addPointer(location: Offset.zero);

        Future<int> sweep({required bool withSummary}) async {
          await tester.pumpWidget(
            _host(
              interaction: _interaction(
                interpolateCrosshair: true,
                valueMode: CartesianValueSummaryValueMode.dataPoints,
                summaryEnabled: withSummary,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final renderBox = _renderBox(tester);
          final before = renderBox.debugTrackingComputeCount;
          for (final dataX in const [3.4, 5.8, 7.6]) {
            await pointer.moveTo(_plotTarget(tester, renderBox, dataX, 6));
            await tester.pump();
          }
          await pointer.moveTo(const Offset(2, 2));
          await tester.pump();
          return renderBox.debugTrackingComputeCount - before;
        }

        final crosshairOnly = await sweep(withSummary: false);
        final withSummary = await sweep(withSummary: true);
        expect(withSummary, crosshairOnly);
      },
    );
  });
}

InteractionConfig _interaction({
  bool crosshairEnabled = true,
  required bool interpolateCrosshair,
  CartesianValueSummaryValueMode valueMode =
      CartesianValueSummaryValueMode.interpolated,
  bool summaryEnabled = true,
}) {
  return InteractionConfig(
    crosshair: CrosshairConfig(
      enabled: crosshairEnabled,
      displayMode: CrosshairDisplayMode.tracking,
      interpolateValues: interpolateCrosshair,
    ),
    valueSummary: CartesianValueSummaryConfig(
      enabled: summaryEnabled,
      valueMode: valueMode,
    ),
  );
}

Widget _host({required InteractionConfig interaction}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 640,
          height: 300,
          child: BravenChartPlus(
            showLegend: false,
            interactionConfig: interaction,
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

ChartRenderBox _renderBox(WidgetTester tester) {
  final finder = find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
  );
  return finder.evaluate().single.renderObject! as ChartRenderBox;
}

Offset _plotTarget(
  WidgetTester tester,
  ChartRenderBox renderBox,
  double dataX,
  double dataY,
) {
  return tester.getTopLeft(find.byType(BravenChartPlus)) +
      renderBox.plotToWidget(renderBox.transform!.dataToPlot(dataX, dataY));
}
