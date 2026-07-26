// Copyright (c) 2025 braven_charts. All rights reserved.
// Log-axis domain guard tests (log-space padding + positive floor).

import 'package:braven_charts/src/models/axis_scale_type.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_position.dart';
import 'package:braven_charts/src/rendering/modules/multi_axis_manager.dart';
import 'package:braven_charts/src/utils/data_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('log Y axis domain guards (multi-axis manager)', () {
    test('log Y axis pads in log-space and keeps the domain positive', () {
      final manager = MultiAxisManager();
      manager.setSeries([
        ChartSeries(
          id: 's1',
          name: 'Series 1',
          points: const [
            ChartDataPoint(x: 0, y: 1),
            ChartDataPoint(x: 1, y: 1000),
          ],
          yAxisConfig: YAxisConfig.withId(
            id: 'axis1',
            position: YAxisPosition.left,
            scaleType: AxisScaleType.log,
          ),
        ),
      ]);

      final range = manager.computeAxisBounds()['axis1']!;
      // Linear 5% padding would push min to 1 - (999 * 0.05) = -48.95 <= 0,
      // which is undefined on a log scale. The log-space padding must keep the
      // domain strictly positive.
      expect(range.min, greaterThan(0));
      // The padded domain must bracket the data.
      expect(range.min, lessThanOrEqualTo(1));
      expect(range.max, greaterThanOrEqualTo(1000));
    });

    test(
      'log Y axis floors a non-positive/degenerate domain to a positive finite '
      'range',
      () {
        final manager = MultiAxisManager();
        manager.setSeries([
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: const [
              ChartDataPoint(x: 0, y: 0),
              ChartDataPoint(x: 1, y: 0),
            ],
            yAxisConfig: YAxisConfig.withId(
              id: 'axis1',
              position: YAxisPosition.left,
              scaleType: AxisScaleType.log,
            ),
          ),
        ]);

        final range = manager.computeAxisBounds()['axis1']!;
        expect(range.min, greaterThan(0));
        expect(range.max, greaterThan(range.min));
        expect(range.min.isFinite, isTrue);
        expect(range.max.isFinite, isTrue);
      },
    );

    test('linear Y axis padding is unchanged (byte-identical regression)', () {
      final manager = MultiAxisManager();
      manager.setSeries([
        ChartSeries(
          id: 's1',
          name: 'Series 1',
          points: const [
            ChartDataPoint(x: 0, y: 10),
            ChartDataPoint(x: 1, y: 90),
          ],
          yAxisConfig: YAxisConfig.withId(
            id: 'axis1',
            position: YAxisPosition.left,
          ),
        ),
      ]);

      final range = manager.computeAxisBounds()['axis1']!;
      // Data range 10-90, 5% padding of 80 = 4 → 6..94 (unchanged).
      expect(range.min, closeTo(6.0, 0.001));
      expect(range.max, closeTo(94.0, 0.001));
    });
  });

  group('log axis domain guards (primary data-converter path)', () {
    test('log Y bounds stay positive and bracket the data', () {
      final bounds = DataConverter.computeDataBounds(
        [
          const ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: [
              ChartDataPoint(x: 0, y: 1),
              ChartDataPoint(x: 1, y: 1000),
            ],
          ),
        ],
        yScaleType: AxisScaleType.log,
      );
      expect(bounds.yMin, greaterThan(0));
      expect(bounds.yMin, lessThanOrEqualTo(1));
      expect(bounds.yMax, greaterThanOrEqualTo(1000));
    });

    test('default (linear) bounds are byte-identical to the original 5%', () {
      final bounds = DataConverter.computeDataBounds([
        const ChartSeries(
          id: 's1',
          name: 'Series 1',
          points: [
            ChartDataPoint(x: 0, y: 10),
            ChartDataPoint(x: 10, y: 90),
          ],
        ),
      ]);
      // x range 0-10, 5% padding of 10 = 0.5 → -0.5..10.5.
      expect(bounds.xMin, closeTo(-0.5, 0.001));
      expect(bounds.xMax, closeTo(10.5, 0.001));
      // y range 10-90, 5% padding of 80 = 4 → 6..94.
      expect(bounds.yMin, closeTo(6.0, 0.001));
      expect(bounds.yMax, closeTo(94.0, 0.001));
    });
  });
}
