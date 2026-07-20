import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScatterMarginalData', () {
    test('builds numeric X and Y distributions from one finite viewport', () {
      final data = ScatterMarginalData(
        points: const [
          ChartDataPoint(x: 1, y: 10),
          ChartDataPoint(x: 2, y: 20),
          ChartDataPoint(x: 3, y: 30),
          ChartDataPoint(x: 4, y: 40),
          ChartDataPoint(x: double.nan, y: 50),
        ],
        method: HistogramBinningMethod.fixedCount,
        requestedBinCount: 2,
        xMinimum: 1.5,
        xMaximum: 4.5,
        yMinimum: 15,
        yMaximum: 35,
      );

      expect(data.sourcePointCount, 5);
      expect(data.visiblePointCount, 2);
      expect(data.xHistogram.bins.map((bin) => bin.count), [1, 1]);
      expect(data.yHistogram.bins.map((bin) => bin.count), [1, 1]);

      final xPoints = data.xPointsFor(HistogramValueMode.percentage);
      expect(xPoints.map((point) => point.x), [2.25, 2.75]);
      expect(xPoints.map((point) => point.y), [50, 50]);
      expect(xPoints.first.metadata?['count'], 1);

      final yPoints = data.yPointsFor(
        HistogramValueMode.count,
        invertDomain: true,
      );
      expect(yPoints.map((point) => point.x), [-22.5, -27.5]);
      expect(yPoints.map((point) => point.y), [1, 1]);
    });

    test('rejects inverted viewport bounds', () {
      expect(
        () => ScatterMarginalData(points: const [], xMinimum: 2, xMaximum: 1),
        throwsArgumentError,
      );
      expect(
        () => ScatterMarginalData(points: const [], yMinimum: 2, yMaximum: 1),
        throwsArgumentError,
      );
    });
  });
}
