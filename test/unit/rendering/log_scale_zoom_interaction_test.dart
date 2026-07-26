// Copyright (c) 2025 braven_charts. All rights reserved.
// Integration proof for the log/time scale interaction fix: a log-Y chart that
// is zoomed (the animated default path: zoom_animator + viewport_constraints)
// or whose data bounds are expanded (updateDataBounds, the streaming range
// path) must KEEP its log positioning. Before the fix these reconstruction
// sites rebuilt a fresh ChartTransform carrying only invertY/transposed and
// dropped the per-axis scale fields, so a known data point reverted to its
// LINEAR pixel instead of its LOG pixel. The linear arm must stay unchanged.

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/models/axis_scale_type.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ChartRenderBox _renderBox(WidgetTester tester) =>
    tester.firstRenderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );

Future<void> _pumpLogYChart(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: BravenChartPlus(
          width: 600,
          height: 400,
          xAxisConfig: const XAxisConfig(min: 0, max: 12),
          yAxis: YAxisConfig(
            position: YAxisPosition.left,
            scaleType: AxisScaleType.log,
            min: 1,
            max: 1000,
          ),
          series: const [
            LineChartSeries(
              id: 's',
              points: [
                ChartDataPoint(x: 0, y: 1),
                ChartDataPoint(x: 6, y: 100),
                ChartDataPoint(x: 12, y: 1000),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The plot-space dy value [y] WOULD land on if [t]'s Y axis were linear over
/// the same bounds/dims. Derived from the transform itself so there is no
/// coordinate-space guesswork: if the reconstruction fix regressed and dropped
/// the log scale, the render box would place the point exactly here.
double _linearDyOverSameBounds(ChartTransform t, double x, double y) =>
    t.copyWith(yScaleType: AxisScaleType.linear).dataToPlot(x, y).dy;

void main() {
  testWidgets('animated zoom keeps a log-Y chart positioned in log space', (
    tester,
  ) async {
    await _pumpLogYChart(tester);

    final box = _renderBox(tester);
    expect(box.transform!.yScaleType, AxisScaleType.log);

    // A known decade point sits at its LOG pixel (not its linear pixel) before
    // any interaction.
    const probeY = 10.0;
    final dyBefore = box.transform!.dataToPlot(6, probeY).dy;
    expect(
      dyBefore,
      isNot(closeTo(_linearDyOverSameBounds(box.transform!, 6, probeY), 1.0)),
    );

    // Kick off the DEFAULT animated zoom (routes through the zoom animator's
    // frame interpolation and the viewport-constraints clamp).
    box.zoomChart(2.0);

    // Mid-animation: an interpolated frame must still be log.
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      box.transform!.yScaleType,
      AxisScaleType.log,
      reason: 'interpolated zoom frame reverted to linear',
    );

    await tester.pumpAndSettle();

    // Settled: still log, and the probe point is at its LOG pixel for the new
    // viewport — provably NOT the linear pixel it would land on if the scale
    // fields had been dropped.
    final settled = box.transform!;
    expect(settled.yScaleType, AxisScaleType.log);
    final dyAfter = settled.dataToPlot(6, probeY).dy;
    expect(
      dyAfter,
      isNot(closeTo(_linearDyOverSameBounds(settled, 6, probeY), 2.0)),
      reason: 'zoomed log point landed on its linear pixel',
    );
  });

  testWidgets('updateDataBounds preserves the log scale (streaming expansion)', (
    tester,
  ) async {
    await _pumpLogYChart(tester);

    final box = _renderBox(tester);
    expect(box.transform!.yScaleType, AxisScaleType.log);

    // Streaming range expansion pushes new data bounds through updateDataBounds.
    box.updateDataBounds(0, 24, 1, 10000);

    final t = box.transform!;
    expect(t.dataYMax, 10000);
    expect(
      t.yScaleType,
      AxisScaleType.log,
      reason: 'updateDataBounds dropped the y scale type',
    );

    // The expanded bounds position a decade at its LOG pixel, not the linear.
    const probeY = 100.0;
    final dy = t.dataToPlot(6, probeY).dy;
    expect(dy, isNot(closeTo(_linearDyOverSameBounds(t, 6, probeY), 2.0)));
  });

  testWidgets('linear chart zoom stays linear (regression)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: BravenChartPlus(
            width: 600,
            height: 400,
            xAxisConfig: const XAxisConfig(min: 0, max: 100),
            yAxis: YAxisConfig(position: YAxisPosition.left, min: 0, max: 100),
            series: const [
              LineChartSeries(
                id: 's',
                points: [
                  ChartDataPoint(x: 0, y: 0),
                  ChartDataPoint(x: 100, y: 100),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final box = _renderBox(tester);
    expect(box.transform!.yScaleType, AxisScaleType.linear);

    box.zoomChart(2.0);
    await tester.pumpAndSettle();

    expect(box.transform!.xScaleType, AxisScaleType.linear);
    expect(box.transform!.yScaleType, AxisScaleType.linear);
  });
}
