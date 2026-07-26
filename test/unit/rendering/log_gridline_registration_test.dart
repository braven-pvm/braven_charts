// Copyright (c) 2025 braven_charts. All rights reserved.
// Grid-line pixel registration for log axes: the render box's grid lines must
// land on their own axis-painter tick marks / data marks (log fraction), not on
// the legacy LinearScale positions. The linear arm must stay byte-identical.

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/axis/log_ticks.dart';
import 'package:braven_charts/src/models/axis_scale_type.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:braven_charts/src/rendering/multi_axis_normalizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ChartRenderBox _renderBox(WidgetTester tester) =>
    tester.firstRenderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );

Future<void> _pumpChart(
  WidgetTester tester, {
  XAxisConfig? xAxisConfig,
  required YAxisConfig yAxis,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: BravenChartPlus(
          width: 600,
          height: 400,
          xAxisConfig: xAxisConfig,
          yAxis: yAxis,
          series: const [
            LineChartSeries(
              id: 's',
              points: [
                ChartDataPoint(x: 1, y: 1),
                ChartDataPoint(x: 1000, y: 1000),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'log Y grid lines land on the decades at the multi-axis painter positions',
    (tester) async {
      await _pumpChart(
        tester,
        xAxisConfig: const XAxisConfig(min: 1, max: 1000),
        yAxis: YAxisConfig(
          position: YAxisPosition.left,
          scaleType: AxisScaleType.log,
          min: 1,
          max: 1000,
        ),
      );

      final box = _renderBox(tester);
      final plot = box.debugPlotArea;
      final transform = box.transform!;
      final yGrid = box.debugGridLinePositions().yTicks;

      // The domain resolves to clean decades (1..1000 base 10).
      final decades = decadeTicks(
        transform.dataYMin,
        transform.dataYMax,
        base: transform.yLogBase,
      );
      expect(decades, [1, 10, 100, 1000]);

      // One grid line per decade, each registered with the Y painter's
      // log position (normalizeScaled), NOT the legacy linear nice-numbers.
      expect(yGrid.length, decades.length);
      for (var i = 0; i < decades.length; i++) {
        final expected = plot.bottom -
            MultiAxisNormalizer.normalizeScaled(
                  decades[i],
                  transform.dataYMin,
                  transform.dataYMax,
                  AxisScaleType.log,
                  transform.yLogBase,
                ) *
                plot.height;
        expect(yGrid[i], closeTo(expected, 1e-6));
      }

      // Decades are equally spaced in pixels on a log axis (the visual tell
      // that separates the log placement from a linear one).
      final gaps = [
        for (var i = 1; i < yGrid.length; i++) yGrid[i - 1] - yGrid[i],
      ];
      for (final gap in gaps) {
        expect(gap, closeTo(gaps.first, 1e-6));
      }
    },
  );

  testWidgets(
    'log X grid lines land on the decades at the X painter positions',
    (tester) async {
      await _pumpChart(
        tester,
        xAxisConfig: const XAxisConfig(
          scaleType: AxisScaleType.log,
          min: 1,
          max: 1000,
        ),
        yAxis: YAxisConfig(position: YAxisPosition.left, min: 1, max: 1000),
      );

      final box = _renderBox(tester);
      final plot = box.debugPlotArea;
      final transform = box.transform!;
      final xGrid = box.debugGridLinePositions().xTicks;

      final decades = decadeTicks(
        transform.dataXMin,
        transform.dataXMax,
        base: transform.xLogBase,
      );
      expect(decades, [1, 10, 100, 1000]);

      // Each vertical grid line lands on the X painter's log tick position
      // (plotArea.left + logFraction * width), NOT the linear scale pixel.
      expect(xGrid.length, decades.length);
      for (var i = 0; i < decades.length; i++) {
        final expected = plot.left +
            logFraction(
                  decades[i],
                  transform.dataXMin,
                  transform.dataXMax,
                  transform.xLogBase,
                ) *
                plot.width;
        expect(xGrid[i], closeTo(expected, 1e-6));
      }

      // Equal per-decade pixel spacing (log placement, not linear).
      final gaps = [
        for (var i = 1; i < xGrid.length; i++) xGrid[i] - xGrid[i - 1],
      ];
      for (final gap in gaps) {
        expect(gap, closeTo(gaps.first, 1e-6));
      }
    },
  );

  testWidgets(
    'linear grid lines stay on the linear scale positions (regression)',
    (tester) async {
      await _pumpChart(
        tester,
        xAxisConfig: const XAxisConfig(min: 0, max: 100),
        yAxis: YAxisConfig(position: YAxisPosition.left, min: 0, max: 100),
      );

      final box = _renderBox(tester);
      final plot = box.debugPlotArea;
      final transform = box.transform!;
      final yGrid = box.debugGridLinePositions().yTicks;

      expect(yGrid, isNotEmpty);
      // Linear nice-number ticks map through a purely linear scale, so every
      // grid line sits at plot.bottom - normalize(value) * height for the
      // legacy tick value it came from. Recover the implied value and confirm
      // it is an exact linear (affine) inverse — i.e. the log arm did not
      // touch the linear path.
      for (final y in yGrid) {
        expect(y, greaterThanOrEqualTo(plot.top - 1e-6));
        expect(y, lessThanOrEqualTo(plot.bottom + 1e-6));
        final normalized = (plot.bottom - y) / plot.height;
        final value = MultiAxisNormalizer.denormalize(
          normalized,
          transform.dataYMin,
          transform.dataYMax,
        );
        // Legacy linear ticks are whole nice-numbers within [0, 100].
        expect(value, closeTo(value.roundToDouble(), 1e-6));
        expect(value, greaterThanOrEqualTo(-1e-6));
        expect(value, lessThanOrEqualTo(100 + 1e-6));
      }
    },
  );
}
