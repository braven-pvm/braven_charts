import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/utils/data_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataConverter invalid points', () {
    test('ignores invalid bar points without producing NaN bounds', () {
      final bounds = DataConverter.computeDataBounds(const [
        BarChartSeries(
          id: 'bars',
          points: [
            ChartDataPoint(x: double.nan, y: 10),
            ChartDataPoint(x: 1, y: double.infinity),
            ChartDataPoint(x: 2, y: 20),
            ChartDataPoint(x: 3, y: 30),
          ],
          barWidthPercent: 0.8,
        ),
      ]);

      expect(bounds.xMin.isFinite, isTrue);
      expect(bounds.xMax.isFinite, isTrue);
      expect(bounds.yMin.isFinite, isTrue);
      expect(bounds.yMax.isFinite, isTrue);
      expect(bounds.xMin, lessThanOrEqualTo(2));
      expect(bounds.xMax, greaterThanOrEqualTo(3));
    });

    test('falls back to safe default bounds for all-invalid bar data', () {
      final bounds = DataConverter.computeDataBounds(const [
        BarChartSeries(
          id: 'invalid-bars',
          points: [ChartDataPoint(x: 0, y: double.nan)],
          barWidthPercent: 0.8,
        ),
      ]);

      expect(bounds.xMin, 0);
      expect(bounds.xMax, 1);
      expect(bounds.yMin, 0);
      expect(bounds.yMax, 1);
    });
  });
}
