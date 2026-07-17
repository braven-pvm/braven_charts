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
