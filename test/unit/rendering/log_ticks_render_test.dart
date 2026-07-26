// Copyright (c) 2025 braven_charts. All rights reserved.
// Log-decade tick VALUES + pixel/normalizer registration against ChartTransform
// (X painter + Y multi-axis painter). Linear arm must stay byte-identical.

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/models/axis_scale_type.dart';
import 'package:braven_charts/src/models/data_range.dart';
import 'package:braven_charts/src/models/x_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_position.dart';
import 'package:braven_charts/src/rendering/multi_axis_normalizer.dart';
import 'package:braven_charts/src/rendering/multi_axis_painter.dart';
import 'package:braven_charts/src/rendering/x_axis_painter.dart';
import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bounds = DataRange(min: 1, max: 1000);

  group('X axis log-decade ticks + registration', () {
    final painter = XAxisPainter(
      config: const XAxisConfig(scaleType: AxisScaleType.log),
      axisBounds: bounds,
      labelStyle: const TextStyle(fontSize: 12),
    );

    test('generateTicks over 1..1000 are the decades', () {
      expect(painter.generateTicks(bounds), [1, 10, 100, 1000]);
    });

    test('resolveTickValues also yields the decades (log branch wins)', () {
      expect(painter.resolveTickValues(400), [1, 10, 100, 1000]);
    });

    test('tick pixel ratios equal the ChartTransform x-log positions', () {
      const plotWidth = 300.0;
      const transform = ChartTransform(
        dataXMin: 1,
        dataXMax: 1000,
        dataYMin: 0,
        dataYMax: 10,
        plotWidth: plotWidth,
        plotHeight: 200,
        xScaleType: AxisScaleType.log,
      );
      for (final v in const [1.0, 10.0, 100.0, 1000.0]) {
        expect(
          painter.tickRatio(v) * plotWidth,
          closeTo(transform.dataToPlot(v, 0).dx, 1e-9),
        );
      }
    });

    test('linear tickRatio stays byte-identical to the original expression', () {
      final linear = XAxisPainter(
        config: const XAxisConfig(),
        axisBounds: const DataRange(min: 0, max: 100),
        labelStyle: const TextStyle(fontSize: 12),
      );
      expect(linear.tickRatio(25), 0.25);
      // zero-span edge case → 0.0 (original guard)
      final degenerate = XAxisPainter(
        config: const XAxisConfig(),
        axisBounds: const DataRange(min: 5, max: 5),
        labelStyle: const TextStyle(fontSize: 12),
      );
      expect(degenerate.tickRatio(5), 0.0);
    });

    test('decade labels format plainly', () {
      expect(painter.formatTickLabel(1000), '1000');
      expect(painter.formatTickLabel(1), '1');
    });
  });

  group('Y axis log-decade ticks + registration', () {
    final painter = MultiAxisPainter(
      axes: [
        YAxisConfig.withId(
          id: 'y',
          position: YAxisPosition.left,
          scaleType: AxisScaleType.log,
        ),
      ],
      axisBounds: const {'y': bounds},
    );

    test('generateTicks over 1..1000 are the decades', () {
      expect(
        painter.generateTicks(
          bounds,
          scaleType: AxisScaleType.log,
          logBase: 10,
        ),
        [1, 10, 100, 1000],
      );
    });

    test('normalizeScaled equals the ChartTransform y-log positions', () {
      const plotHeight = 200.0;
      const transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 10,
        dataYMin: 1,
        dataYMax: 1000,
        plotWidth: 300,
        plotHeight: plotHeight,
        yScaleType: AxisScaleType.log,
      );
      for (final v in const [1.0, 10.0, 100.0, 1000.0]) {
        final normalized = MultiAxisNormalizer.normalizeScaled(
          v,
          1,
          1000,
          AxisScaleType.log,
          10,
        );
        // invertY: dataToPlot.dy == (1 - relativeY) * plotHeight.
        final relativeY = 1 - transform.dataToPlot(0, v).dy / plotHeight;
        expect(normalized, closeTo(relativeY, 1e-9));
      }
    });

    test('linear normalizeScaled is byte-identical to normalize', () {
      expect(
        MultiAxisNormalizer.normalizeScaled(
          50,
          0,
          100,
          AxisScaleType.linear,
          10,
        ),
        MultiAxisNormalizer.normalize(50, 0, 100),
      );
      // zero-range edge case preserved (normalize → 0.5).
      expect(
        MultiAxisNormalizer.normalizeScaled(5, 5, 5, AxisScaleType.linear, 10),
        0.5,
      );
    });

    test('decade labels format plainly', () {
      final axis = YAxisConfig.withId(
        id: 'y',
        position: YAxisPosition.left,
        scaleType: AxisScaleType.log,
      );
      expect(painter.formatTickLabel(1000, axis), '1000');
    });
  });
}
