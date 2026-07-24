// Copyright (c) 2025 braven_charts. All rights reserved.
// Calendar-nice time tick VALUES + auto date labels for the X painter (and the
// Y multi-axis painter mirror). Time positions use the LINEAR arm of
// ChartTransform (epoch-millis map linearly); only the tick spacing and labels
// are new. The linear/log arms must stay byte-identical.

import 'package:braven_charts/src/axis/time_ticks.dart';
import 'package:braven_charts/src/models/axis_scale_type.dart';
import 'package:braven_charts/src/models/data_range.dart';
import 'package:braven_charts/src/models/x_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_position.dart';
import 'package:braven_charts/src/rendering/multi_axis_painter.dart';
import 'package:braven_charts/src/rendering/x_axis_painter.dart';
import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final jan2024 = DateTime.utc(2024).millisecondsSinceEpoch.toDouble();
  final jan2026 = DateTime.utc(2026).millisecondsSinceEpoch.toDouble();
  final jan2027 = DateTime.utc(2027).millisecondsSinceEpoch.toDouble();
  final bounds = DataRange(min: jan2024, max: jan2027);

  group('X axis time ticks + auto date labels', () {
    final painter = XAxisPainter(
      config: const XAxisConfig(scaleType: AxisScaleType.time),
      axisBounds: bounds,
      labelStyle: const TextStyle(fontSize: 12),
    );

    test('generateTicks over a ~3-year span equals dateTicks', () {
      expect(painter.generateTicks(bounds), dateTicks(bounds.min, bounds.max));
    });

    test('resolveTickValues also yields the date ticks (time branch wins)', () {
      expect(painter.resolveTickValues(400), dateTicks(bounds.min, bounds.max));
    });

    test('formatTickLabel returns the auto date label for the span', () {
      final interval = intervalFor(bounds.min, bounds.max);
      expect(painter.formatTickLabel(jan2026), dateLabel(jan2026, interval));
      // A ~3-year span resolves to the year interval → the bare year.
      expect(painter.formatTickLabel(jan2026), '2026');
    });

    test('an explicit labelFormatter still wins over the date default', () {
      final custom = XAxisPainter(
        config: XAxisConfig(
          scaleType: AxisScaleType.time,
          labelFormatter: (_) => 'custom',
        ),
        axisBounds: bounds,
        labelStyle: const TextStyle(fontSize: 12),
      );
      expect(custom.formatTickLabel(jan2026), 'custom');
    });

    test('linear formatTickLabel stays byte-identical (regression)', () {
      final linear = XAxisPainter(
        config: const XAxisConfig(),
        axisBounds: const DataRange(min: 0, max: 100),
        labelStyle: const TextStyle(fontSize: 12),
      );
      expect(linear.formatTickLabel(50), '50');
    });
  });

  group('Y axis time ticks + auto date labels (mirror)', () {
    final painter = MultiAxisPainter(
      axes: [
        YAxisConfig.withId(
          id: 'y',
          position: YAxisPosition.left,
          scaleType: AxisScaleType.time,
        ),
      ],
      axisBounds: {'y': bounds},
    );

    test('generateTicks over a ~3-year span equals dateTicks', () {
      expect(
        painter.generateTicks(bounds, scaleType: AxisScaleType.time),
        dateTicks(bounds.min, bounds.max),
      );
    });

    test('formatTickLabel returns the auto date label', () {
      final axis = YAxisConfig.withId(
        id: 'y',
        position: YAxisPosition.left,
        scaleType: AxisScaleType.time,
      );
      final interval = intervalFor(bounds.min, bounds.max);
      expect(
        painter.formatTickLabel(jan2026, axis),
        dateLabel(jan2026, interval),
      );
    });
  });
}
