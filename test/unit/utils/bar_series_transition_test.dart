import 'package:braven_charts/src/models/bar_chart_style.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/segment_style.dart';
import 'package:braven_charts/src/utils/bar_series_transition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BarSeriesTransition', () {
    test('collapses ordinary and range bars to their own starts', () {
      const source = BarChartSeries(
        id: 'ranges',
        points: [ChartDataPoint(x: 0, y: 25), ChartDataPoint(x: 1, y: 31)],
        barWidthPercent: 0.7,
        baselineValue: 5,
        rangeStartValues: [14, null],
      );

      final collapsed = BarSeriesTransition.collapsed(source);

      expect(collapsed.points.map((point) => point.y), [14, 5]);
      expect(collapsed.rangeStartValues, source.rangeStartValues);
    });

    test(
      'interpolates values and range starts while preserving point style',
      () {
        const style = PointStyle(size: 0.8);
        const from = BarChartSeries(
          id: 'ranges',
          points: [ChartDataPoint(x: 0, y: 20, pointStyle: style)],
          barWidthPercent: 0.7,
          rangeStartValues: [10],
          targetValues: [24],
          errorLowerValues: [16],
          errorUpperValues: [25],
        );
        const to = BarChartSeries(
          id: 'ranges',
          points: [ChartDataPoint(x: 0, y: 32, pointStyle: style)],
          barWidthPercent: 0.7,
          rangeStartValues: [14],
          targetValues: [30],
          errorLowerValues: [22],
          errorUpperValues: [38],
        );

        final midpoint = BarSeriesTransition.interpolate(
          from: from,
          to: to,
          progress: 0.5,
        );

        expect(midpoint.points.single.y, 26);
        expect(midpoint.rangeStartValues.single, 12);
        expect(midpoint.targetValues.single, 27);
        expect(midpoint.errorLowerValues.single, 19);
        expect(midpoint.errorUpperValues.single, 31.5);
        expect(midpoint.points.single.pointStyle, style);
      },
    );

    test('collapses uncertainty intervals to the bar baseline', () {
      const source = BarChartSeries(
        id: 'uncertainty',
        points: [ChartDataPoint(x: 0, y: 30)],
        barWidthPercent: 0.7,
        baselineValue: 5,
        errorLowerValues: [24],
        errorUpperValues: [38],
      );

      final collapsed = BarSeriesTransition.collapsed(source);

      expect(collapsed.errorLowerValues, const [5]);
      expect(collapsed.errorUpperValues, const [5]);
    });

    test('collapses target markers to the bar baseline', () {
      const source = BarChartSeries(
        id: 'targets',
        points: [ChartDataPoint(x: 0, y: 30)],
        barWidthPercent: 0.7,
        baselineValue: 5,
        targetValues: [34],
      );

      final collapsed = BarSeriesTransition.collapsed(source);

      expect(collapsed.targetValues, const [5]);
    });

    test('keeps removed points in-order and collapses their full geometry', () {
      const previous = BarChartSeries(
        id: 'ranges',
        points: [
          ChartDataPoint(x: 0, y: 20, label: 'Old A'),
          ChartDataPoint(x: 1, y: 28, label: 'B'),
          ChartDataPoint(x: 2, y: 34, label: 'C'),
        ],
        barWidthPercent: 0.7,
        rangeStartValues: [8, 10, 12],
        targetValues: [22, 30, 36],
        errorLowerValues: [17, 24, 31],
        errorUpperValues: [24, 33, 39],
      );
      const next = BarChartSeries(
        id: 'ranges',
        points: [
          ChartDataPoint(x: 0, y: 30, label: 'Renamed A'),
          ChartDataPoint(x: 2, y: 40, label: 'C'),
        ],
        barWidthPercent: 0.7,
        rangeStartValues: [9, 14],
        targetValues: [32, 42],
        errorLowerValues: [26, 36],
        errorUpperValues: [35, 45],
      );

      final target = BarSeriesTransition.withExitingPoints(
        previous: previous,
        next: next,
      );
      final midpoint = BarSeriesTransition.interpolate(
        from: previous,
        to: target,
        progress: 0.5,
      );

      expect(target.points.map((point) => point.x), const [0, 1, 2]);
      expect(target.points.map((point) => point.y), const [30, 10, 40]);
      expect(target.rangeStartValues, const [9, 10, 14]);
      expect(target.targetValues, const [32, 10, 42]);
      expect(target.errorLowerValues, const [26, 10, 36]);
      expect(target.errorUpperValues, const [35, 10, 45]);
      expect(midpoint.points.map((point) => point.y), const [25, 19, 37]);
      expect(midpoint.points.first.label, 'Renamed A');
    });

    test('remaps waterfall totals around an exiting step', () {
      const previous = BarChartSeries(
        id: 'bridge',
        points: [
          ChartDataPoint(x: 0, y: 80),
          ChartDataPoint(x: 1, y: -20),
          ChartDataPoint(x: 2, y: 60),
        ],
        barWidthPercent: 0.7,
        layoutMode: BarLayoutMode.waterfall,
        waterfallTotalIndices: {2},
      );
      const next = BarChartSeries(
        id: 'bridge',
        points: [ChartDataPoint(x: 0, y: 80), ChartDataPoint(x: 2, y: 80)],
        barWidthPercent: 0.7,
        layoutMode: BarLayoutMode.waterfall,
        waterfallTotalIndices: {1},
      );

      final target = BarSeriesTransition.withExitingPoints(
        previous: previous,
        next: next,
      );

      expect(target.points.map((point) => point.x), const [0, 1, 2]);
      expect(target.points[1].y, 0);
      expect(target.waterfallTotalIndices, const {2});
    });

    test('grows new points from the target baseline', () {
      const from = BarChartSeries(
        id: 'values',
        points: [ChartDataPoint(x: 0, y: 20, label: 'A')],
        barWidthPercent: 0.7,
        baselineValue: 4,
      );
      const to = BarChartSeries(
        id: 'values',
        points: [
          ChartDataPoint(x: 0, y: 30, label: 'A'),
          ChartDataPoint(x: 1, y: 24, label: 'B'),
        ],
        barWidthPercent: 0.7,
        baselineValue: 4,
      );

      final midpoint = BarSeriesTransition.interpolate(
        from: from,
        to: to,
        progress: 0.5,
      );

      expect(midpoint.points[0].y, 25);
      expect(midpoint.points[1].y, 14);
    });

    for (final entry in <BarAnimationOrder, List<double>>{
      BarAnimationOrder.forward: [50, 0, 0],
      BarAnimationOrder.reverse: [0, 0, 50],
      BarAnimationOrder.centerOut: [0, 50, 0],
      BarAnimationOrder.edgesIn: [50, 0, 50],
    }.entries) {
      test('sequences ${entry.key.name} motion on one shared timeline', () {
        const from = BarChartSeries(
          id: 'sequenced',
          points: [
            ChartDataPoint(x: 0, y: 0),
            ChartDataPoint(x: 1, y: 0),
            ChartDataPoint(x: 2, y: 0),
          ],
          barWidthPercent: 0.7,
        );
        final to = BarChartSeries(
          id: 'sequenced',
          points: const [
            ChartDataPoint(x: 0, y: 100),
            ChartDataPoint(x: 1, y: 100),
            ChartDataPoint(x: 2, y: 100),
          ],
          barWidthPercent: 0.7,
          barStyle: BarChartStyle(
            motion: BarMotionStyle(order: entry.key, staggerFraction: 0.5),
          ),
        );

        final animated = BarSeriesTransition.interpolate(
          from: from,
          to: to,
          progress: 0.25,
        );

        expect(animated.points.map((point) => point.y), entry.value);
      });
    }

    test('keeps together motion synchronized when stagger is configured', () {
      const from = BarChartSeries(
        id: 'together',
        points: [ChartDataPoint(x: 0, y: 0), ChartDataPoint(x: 1, y: 0)],
        barWidthPercent: 0.7,
      );
      const to = BarChartSeries(
        id: 'together',
        points: [ChartDataPoint(x: 0, y: 100), ChartDataPoint(x: 1, y: 100)],
        barWidthPercent: 0.7,
        barStyle: BarChartStyle(
          motion: BarMotionStyle(
            order: BarAnimationOrder.together,
            staggerFraction: 0.5,
          ),
        ),
      );

      final animated = BarSeriesTransition.interpolate(
        from: from,
        to: to,
        progress: 0.25,
      );

      expect(animated.points.map((point) => point.y), [25, 25]);
    });

    test('collapses waterfall deltas to zero', () {
      const source = BarChartSeries(
        id: 'bridge',
        points: [ChartDataPoint(x: 0, y: 80), ChartDataPoint(x: 1, y: -20)],
        barWidthPercent: 0.7,
        layoutMode: BarLayoutMode.waterfall,
      );

      final collapsed = BarSeriesTransition.collapsed(source);

      expect(collapsed.points.map((point) => point.y), [0, 0]);
    });
  });
}
