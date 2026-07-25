// Copyright (c) 2025 braven_charts. All rights reserved.
// Regression tests for ZoomAnimator: the interpolated transforms produced
// during an animated zoom (the DEFAULT zoom path, also used by keyboard and
// programmatic zoom) must preserve the per-axis scale type and log base of the
// source viewport. Before the fix, `_interpolateTransform` rebuilt a fresh
// ChartTransform carrying only invertY/transposed, silently reverting a
// log/time chart to LINEAR positioning mid-animation and at the final frame.

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/models/axis_scale_type.dart';
import 'package:braven_charts/src/rendering/modules/zoom_animator.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ZoomAnimator interpolation preserves scale type', () {
    test('every animated frame of a y-log zoom stays log with the log base', () {
      const from = ChartTransform(
        dataXMin: 0,
        dataXMax: 10,
        dataYMin: 1,
        dataYMax: 100,
        plotWidth: 100,
        plotHeight: 100,
        yScaleType: AxisScaleType.log,
        yLogBase: 2,
      );
      const to = ChartTransform(
        dataXMin: 0,
        dataXMax: 10,
        dataYMin: 2,
        dataYMax: 50,
        plotWidth: 100,
        plotHeight: 100,
        yScaleType: AxisScaleType.log,
        yLogBase: 2,
      );

      final frames = <ChartTransform>[];
      fakeAsync((async) {
        final animator = ZoomAnimator(
          onUpdate: frames.add,
          onComplete: () {},
          duration: const Duration(milliseconds: 250),
        );
        animator.animateTo(from, to);

        // Advance to roughly the middle of the animation and inspect a genuine
        // interpolated frame (this is the private `_interpolateTransform`
        // output, driven through the public entry point).
        async.elapse(const Duration(milliseconds: 120));
        expect(frames, isNotEmpty);
        final mid = frames.last;
        // A real interpolated frame: moved off the start, not yet the target.
        expect(mid.dataYMin, greaterThan(1));
        expect(mid.dataYMin, lessThan(2));
        expect(
          mid.yScaleType,
          AxisScaleType.log,
          reason: 'interpolated frame must keep the y scale log',
        );
        expect(mid.yLogBase, 2);

        // Finish the animation.
        async.elapse(const Duration(milliseconds: 200));
        animator.dispose();
      });

      // Not one frame (including the settled target frame) reverted to linear.
      expect(frames.length, greaterThan(1));
      for (final f in frames) {
        expect(f.yScaleType, AxisScaleType.log);
        expect(f.yLogBase, 2);
        expect(f.xScaleType, AxisScaleType.linear);
      }
    });

    test('an x-log zoom carries the x scale and base through interpolation', () {
      const from = ChartTransform(
        dataXMin: 1,
        dataXMax: 1000,
        dataYMin: 0,
        dataYMax: 10,
        plotWidth: 200,
        plotHeight: 100,
        xScaleType: AxisScaleType.log,
      );
      const to = ChartTransform(
        dataXMin: 10,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 10,
        plotWidth: 200,
        plotHeight: 100,
        xScaleType: AxisScaleType.log,
      );

      final frames = <ChartTransform>[];
      fakeAsync((async) {
        final animator = ZoomAnimator(
          onUpdate: frames.add,
          onComplete: () {},
        );
        animator.animateTo(from, to);
        async.elapse(const Duration(milliseconds: 500));
        animator.dispose();
      });

      expect(frames, isNotEmpty);
      for (final f in frames) {
        expect(f.xScaleType, AxisScaleType.log);
        expect(f.xLogBase, 10);
      }
    });

    test('linear zoom frames stay linear (regression, byte-identical arm)', () {
      const from = ChartTransform(
        dataXMin: 0,
        dataXMax: 10,
        dataYMin: 0,
        dataYMax: 100,
        plotWidth: 100,
        plotHeight: 100,
      );
      const to = ChartTransform(
        dataXMin: 2.5,
        dataXMax: 7.5,
        dataYMin: 25,
        dataYMax: 75,
        plotWidth: 100,
        plotHeight: 100,
      );

      final frames = <ChartTransform>[];
      fakeAsync((async) {
        final animator = ZoomAnimator(
          onUpdate: frames.add,
          onComplete: () {},
        );
        animator.animateTo(from, to);
        async.elapse(const Duration(milliseconds: 500));
        animator.dispose();
      });

      expect(frames, isNotEmpty);
      for (final f in frames) {
        expect(f.xScaleType, AxisScaleType.linear);
        expect(f.yScaleType, AxisScaleType.linear);
      }
    });
  });
}
