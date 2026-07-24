import 'dart:math' as math;

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/models/axis_scale_type.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

double _log10(double v) => math.log(v) / math.ln10;

void main() {
  group('zoom is scale-aware (log)', () {
    test('zooming a y-log transform keeps the data value under the center '
        'fixed', () {
      const t = ChartTransform(
        dataXMin: 0,
        dataXMax: 10,
        dataYMin: 1,
        dataYMax: 100,
        plotWidth: 100,
        plotHeight: 100,
        yScaleType: AxisScaleType.log,
      );
      const center = Offset(40, 30);
      final before = t.plotToData(center.dx, center.dy);
      final zoomed = t.zoom(3.0, center);
      // The scale type must survive the zoom.
      expect(zoomed.yScaleType, AxisScaleType.log);
      final after = zoomed.plotToData(center.dx, center.dy);
      // The data value under the zoom center is unchanged (log-correct zoom).
      expect(after.dx, closeTo(before.dx, 1e-6));
      expect(after.dy, closeTo(before.dy, 1e-6));
    });

    test('zooming an x-log transform keeps the data value under the center '
        'fixed and carries the log base', () {
      const t = ChartTransform(
        dataXMin: 1,
        dataXMax: 1000,
        dataYMin: 0,
        dataYMax: 10,
        plotWidth: 200,
        plotHeight: 100,
        xScaleType: AxisScaleType.log,
        xLogBase: 2,
      );
      const center = Offset(120, 40);
      final before = t.plotToData(center.dx, center.dy);
      final zoomed = t.zoom(0.5, center);
      expect(zoomed.xScaleType, AxisScaleType.log);
      expect(zoomed.xLogBase, 2);
      final after = zoomed.plotToData(center.dx, center.dy);
      expect(after.dx, closeTo(before.dx, 1e-6));
      expect(after.dy, closeTo(before.dy, 1e-6));
    });
  });

  group('pan is scale-aware (log)', () {
    test('panning a y-log transform shifts by equal log-space steps and '
        'translates content by exactly the pixel delta', () {
      const t = ChartTransform(
        dataXMin: 0,
        dataXMax: 10,
        dataYMin: 1,
        dataYMax: 100,
        plotWidth: 100,
        plotHeight: 100,
        yScaleType: AxisScaleType.log,
      );
      final beforePlot = t.dataToPlot(5, 10);
      final panned = t.pan(0, 20);
      expect(panned.yScaleType, AxisScaleType.log);

      // Equal log-space steps: both endpoints shift by the same log delta and
      // the log-space width is preserved.
      final loShift = _log10(panned.dataYMin) - _log10(t.dataYMin);
      final hiShift = _log10(panned.dataYMax) - _log10(t.dataYMax);
      expect(loShift, closeTo(hiShift, 1e-9));
      expect(
        _log10(panned.dataYMax) - _log10(panned.dataYMin),
        closeTo(_log10(t.dataYMax) - _log10(t.dataYMin), 1e-9),
      );

      // A correct pan is a pure pixel translation: value 10's plot position
      // moves up by exactly the pan delta.
      final afterPlot = panned.dataToPlot(5, 10);
      expect(afterPlot.dy, closeTo(beforePlot.dy - 20, 1e-6));
      // Linear x is untouched.
      expect(afterPlot.dx, closeTo(beforePlot.dx, 1e-6));
    });

    test('panning an x-log transform translates content by exactly the pixel '
        'delta', () {
      const t = ChartTransform(
        dataXMin: 1,
        dataXMax: 1000,
        dataYMin: 0,
        dataYMax: 10,
        plotWidth: 300,
        plotHeight: 100,
        xScaleType: AxisScaleType.log,
      );
      final beforePlot = t.dataToPlot(100, 5);
      final panned = t.pan(30, 0);
      expect(panned.xScaleType, AxisScaleType.log);
      final afterPlot = panned.dataToPlot(100, 5);
      // Positive plotDx pans the viewport right, so content shifts left by dx.
      expect(afterPlot.dx, closeTo(beforePlot.dx - 30, 1e-6));
      expect(afterPlot.dy, closeTo(beforePlot.dy, 1e-6));
    });
  });

  group('linear zoom/pan stays byte-identical (regression)', () {
    test('linear zoom about the plot center', () {
      const t = ChartTransform(
        dataXMin: 0,
        dataXMax: 10,
        dataYMin: 0,
        dataYMax: 100,
        plotWidth: 100,
        plotHeight: 100,
      );
      final zoomed = t.zoom(2.0, const Offset(50, 50));
      expect(zoomed.dataXMin, 2.5);
      expect(zoomed.dataXMax, 7.5);
      expect(zoomed.dataYMin, 25);
      expect(zoomed.dataYMax, 75);
      expect(zoomed.xScaleType, AxisScaleType.linear);
      expect(zoomed.yScaleType, AxisScaleType.linear);
    });

    test('linear pan by a plot delta', () {
      const t = ChartTransform(
        dataXMin: 0,
        dataXMax: 10,
        dataYMin: 0,
        dataYMax: 100,
        plotWidth: 100,
        plotHeight: 100,
      );
      final panned = t.pan(10, 0);
      expect(panned.dataXMin, 1);
      expect(panned.dataXMax, 11);
      expect(panned.dataYMin, 0);
      expect(panned.dataYMax, 100);
    });
  });
}
