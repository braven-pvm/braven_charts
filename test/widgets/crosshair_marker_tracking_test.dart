import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/interaction/core/crosshair_tracker.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tracking marker must follow the rendered curve continuously.
///
/// Snapshot identity suppression keys on `formattedY`: while the cursor moves
/// within one formatted-value quantum the previously published snapshot (and
/// its raw interpolated `y`) is retained. The marker painter must therefore
/// recompute the interpolated Y from the live cursor X at paint time — the
/// same discipline the tracking X label already follows — instead of reusing
/// the retained `value.y`, which stair-steps the marker in formatting quanta.
///
/// The host line rises 1 unit per X unit with values above 1000, so the
/// formatted display (`toStringAsFixed(0)`) quantizes a full data unit: many
/// cursor pixels share one `formattedY`, making the retained-Y bug visible.
void main() {
  testWidgets('interpolated tracking marker follows the curve within one '
      'formatted-value window (identity-suppressed snapshot retained)', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    final renderBox = _renderBox(tester);
    final transform = renderBox.transform!;
    final plotArea = renderBox.debugPlotArea;

    // Both hover positions sit in the x∈(4, 6) segment and format to
    // '1005' (1004.7 and 1005.1 round alike), so the second hover is
    // identity-suppressed.
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(pointer.removePointer);
    await pointer.addPointer(location: Offset.zero);
    await pointer.moveTo(_cursorFor(tester, renderBox, dataX: 4.7));
    await tester.pump();

    final snapshot = renderBox.debugTrackingSnapshot;
    expect(snapshot, isNotNull);
    expect(snapshot!.values.single.formattedY, '1005');
    final publishCount = renderBox.debugTrackingPublishCount;

    final firstMarkers = renderBox.debugPaintedIntersectionMarkers;
    expect(firstMarkers, hasLength(1));
    final firstCenter = firstMarkers.single.center;
    expect(
      firstCenter.dy,
      closeTo(_curveScreenY(plotArea, transform, dataX: 4.7), 0.5),
      reason: 'marker must sit on the curve at the live cursor X',
    );

    await pointer.moveTo(_cursorFor(tester, renderBox, dataX: 5.1));
    await tester.pump();

    // The move stayed within one formatted-value quantum: the snapshot is
    // the retained instance and nothing was republished.
    expect(renderBox.debugTrackingSnapshot, same(snapshot));
    expect(renderBox.debugTrackingPublishCount, publishCount);

    final secondMarkers = renderBox.debugPaintedIntersectionMarkers;
    expect(secondMarkers, hasLength(1));
    final secondCenter = secondMarkers.single.center;
    expect(
      secondCenter.dx,
      closeTo(plotArea.left + transform.dataToPlot(5.1, 1005.1).dx, 0.5),
      reason: 'marker X follows the cursor continuously',
    );
    expect(
      secondCenter.dy,
      closeTo(_curveScreenY(plotArea, transform, dataX: 5.1), 0.5),
      reason:
          'marker Y must be recomputed from the live cursor X at paint '
          'time, not reused from the identity-suppressed snapshot',
    );
    expect(
      (secondCenter.dy - firstCenter.dy).abs(),
      greaterThan(2.0),
      reason:
          'a 0.4-unit curve rise must move the marker visibly; identical '
          'Ys mean the retained snapshot Y was painted (stair-stepping)',
    );
  });

  testWidgets('non-interpolated tracking marker paints at the snapped datum', (
    tester,
  ) async {
    await tester.pumpWidget(_host(interpolateValues: false));
    await tester.pumpAndSettle();

    final renderBox = _renderBox(tester);
    final transform = renderBox.transform!;
    final plotArea = renderBox.debugPlotArea;

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(pointer.removePointer);
    await pointer.addPointer(location: Offset.zero);
    await pointer.moveTo(_cursorFor(tester, renderBox, dataX: 4.6));
    await tester.pump();

    // Nearest datum to 4.6 is (4, 1004): the marker snaps to the sample
    // instead of riding the cursor.
    final markers = renderBox.debugPaintedIntersectionMarkers;
    expect(markers, hasLength(1));
    final expected = plotArea.topLeft + transform.dataToPlot(4, 1004);
    expect(markers.single.center.dx, closeTo(expected.dx, 0.5));
    expect(markers.single.center.dy, closeTo(expected.dy, 0.5));
  });

  testWidgets('Range Area paints paired markers at the exact low and high', (
    tester,
  ) async {
    await tester.pumpWidget(_rangeHost());
    await tester.pumpAndSettle();

    final renderBox = _renderBox(tester);
    final transform = renderBox.transform!;
    final plotArea = renderBox.debugPlotArea;
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(pointer.removePointer);
    await pointer.addPointer(location: Offset.zero);
    await pointer.moveTo(
      tester.getTopLeft(find.byType(BravenChartPlus)) +
          renderBox.plotToWidget(transform.dataToPlot(5, 10)),
    );
    await tester.pump();

    final tracked = renderBox.debugTrackingSnapshot!.values.single;
    expect(tracked.rangeArea!.low, closeTo(5, 1e-9));
    expect(tracked.rangeArea!.high, closeTo(15, 1e-9));
    final markers = renderBox.debugPaintedIntersectionMarkers;
    expect(markers, hasLength(2));
    final markerYs = markers.map((marker) => marker.center.dy).toList()..sort();
    final expectedYs = [
      plotArea.top + transform.dataToPlot(5, 5).dy,
      plotArea.top + transform.dataToPlot(5, 15).dy,
    ]..sort();
    expect(markerYs[0], closeTo(expectedYs[0], 0.5));
    expect(markerYs[1], closeTo(expectedYs[1], 0.5));
  });
}

/// Screen Y of the hosted line (y = 1000 + x) at [dataX], mapped exactly as
/// the single-axis marker branch maps it.
double _curveScreenY(
  Rect plotArea,
  ChartTransform transform, {
  required double dataX,
}) {
  return CrosshairTracker.dataToScreenY(
    dataY: 1000 + dataX,
    chartBounds: plotArea,
    yMin: transform.dataYMin,
    yMax: transform.dataYMax,
  );
}

Offset _cursorFor(
  WidgetTester tester,
  ChartRenderBox renderBox, {
  required double dataX,
}) {
  return tester.getTopLeft(find.byType(BravenChartPlus)) +
      renderBox.plotToWidget(
        renderBox.transform!.dataToPlot(dataX, 1000 + dataX),
      );
}

ChartRenderBox _renderBox(WidgetTester tester) {
  final finder = find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
  );
  return finder.evaluate().single.renderObject! as ChartRenderBox;
}

Widget _host({bool interpolateValues = true}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 640,
          height: 300,
          child: BravenChartPlus(
            showLegend: false,
            interactionConfig: InteractionConfig(
              crosshair: CrosshairConfig(
                displayMode: CrosshairDisplayMode.tracking,
                interpolateValues: interpolateValues,
                showTrackingTooltip: false,
              ),
            ),
            series: const [
              LineChartSeries(
                id: 'speed',
                interpolation: LineInterpolation.linear,
                points: [
                  ChartDataPoint(x: 0, y: 1000),
                  ChartDataPoint(x: 2, y: 1002),
                  ChartDataPoint(x: 4, y: 1004),
                  ChartDataPoint(x: 6, y: 1006),
                  ChartDataPoint(x: 8, y: 1008),
                  ChartDataPoint(x: 10, y: 1010),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _rangeHost() => MaterialApp(
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
              showTrackingTooltip: false,
            ),
          ),
          series: [
            RangeAreaChartSeries(
              id: 'interval',
              interpolation: LineInterpolation.linear,
              points: [
                RangeAreaDataPoint(x: 0, low: 0, high: 10),
                RangeAreaDataPoint(x: 10, low: 10, high: 20),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);
