import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const points = [ChartDataPoint(x: 0, y: 1), ChartDataPoint(x: 1, y: 2)];

  group('path series dashPattern', () {
    test('defaults Line and Area outlines to solid', () {
      const line = LineChartSeries(id: 'line', points: points);
      const area = AreaChartSeries(id: 'area', points: points);

      expect(line.dashPattern, isEmpty);
      expect(area.dashPattern, isEmpty);
    });

    test('retains configured intervals and copies them', () {
      const line = LineChartSeries(
        id: 'line',
        points: points,
        dashPattern: [2, 6],
      );
      const area = AreaChartSeries(
        id: 'area',
        points: points,
        dashPattern: [8, 4, 2, 4],
      );

      expect(line.dashPattern, [2, 6]);
      expect(line.copyWith(dashPattern: const [8, 4]).dashPattern, [8, 4]);
      expect(area.dashPattern, [8, 4, 2, 4]);
      expect(area.copyWith(dashPattern: const []).dashPattern, isEmpty);
    });

    test('uses interval values in equality and hashing', () {
      const dottedA = LineChartSeries(
        id: 'line',
        points: points,
        dashPattern: [2, 6],
      );
      const dottedB = LineChartSeries(
        id: 'line',
        points: points,
        dashPattern: [2, 6],
      );
      const dashed = LineChartSeries(
        id: 'line',
        points: points,
        dashPattern: [8, 4],
      );

      expect(dottedA, dottedB);
      expect(dottedA.hashCode, dottedB.hashCode);
      expect(dottedA, isNot(dashed));
      expect(dottedA.toString(), contains('dashPattern: [2.0, 6.0]'));
    });
  });
}
