import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/utils/path_series_transition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fromPoints = [
    ChartDataPoint(x: 0, y: 10, label: 'A'),
    ChartDataPoint(x: 1, y: 20, label: 'B'),
  ];
  const toPoints = [
    ChartDataPoint(x: 0, y: 30, label: 'A'),
    ChartDataPoint(x: 1, y: 40, label: 'B'),
  ];

  group('PathSeriesTransition', () {
    test('interpolates compatible Line geometry at mid-frame', () {
      const from = LineChartSeries(id: 'line', points: fromPoints);
      const to = LineChartSeries(id: 'line', points: toPoints);

      expect(PathSeriesTransition.isCompatible(from, to), isTrue);
      final result =
          PathSeriesTransition.interpolate(from: from, to: to, progress: 0.5)
              as LineChartSeries;

      expect(result.points.map((point) => point.y), [20, 30]);
      expect(result.points.map((point) => point.label), ['A', 'B']);
    });

    test('matches timestamp identity before coordinates', () {
      final first = DateTime.utc(2026, 7, 18, 8);
      final second = DateTime.utc(2026, 7, 18, 9);
      final from = AreaChartSeries(
        id: 'area',
        points: [
          ChartDataPoint(x: 0, y: 10, timestamp: first),
          ChartDataPoint(x: 1, y: 30, timestamp: second),
        ],
      );
      final to = AreaChartSeries(
        id: 'area',
        points: [
          ChartDataPoint(x: 0, y: 50, timestamp: second),
          ChartDataPoint(x: 1, y: 20, timestamp: first),
        ],
      );

      final result =
          PathSeriesTransition.interpolate(from: from, to: to, progress: 0.5)
              as AreaChartSeries;

      expect(result.points.map((point) => point.y), [40, 15]);
    });

    test('rejects point-count and interpolation topology changes', () {
      const from = LineChartSeries(id: 'line', points: fromPoints);
      const addedPoint = LineChartSeries(
        id: 'line',
        points: [...toPoints, ChartDataPoint(x: 2, y: 50)],
      );
      const changedInterpolation = LineChartSeries(
        id: 'line',
        points: toPoints,
        interpolation: LineInterpolation.stepped,
      );

      expect(PathSeriesTransition.isCompatible(from, addedPoint), isFalse);
      expect(
        PathSeriesTransition.isCompatible(from, changedInterpolation),
        isFalse,
      );
    });

    test('retains the target series when types are incompatible', () {
      const from = LineChartSeries(id: 'series', points: fromPoints);
      const to = AreaChartSeries(id: 'series', points: toPoints);

      expect(
        PathSeriesTransition.interpolate(from: from, to: to, progress: 0.5),
        same(to),
      );
    });
  });
}
