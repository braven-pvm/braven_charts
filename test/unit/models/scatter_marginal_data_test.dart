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

    test('estimates deterministic densities on both visible domains', () {
      final data = ScatterMarginalData(
        points: const [
          ChartDataPoint(x: 0, y: 10),
          ChartDataPoint(x: 1, y: 20),
          ChartDataPoint(x: 2, y: 30),
        ],
        xMinimum: -5,
        xMaximum: 7,
        yMinimum: 0,
        yMaximum: 40,
      );

      final xDensity = data.xDensityPoints(resolution: 241);
      expect(xDensity, hasLength(241));
      expect(xDensity.first.x, -5);
      expect(xDensity.last.x, 7);
      expect(xDensity.every((point) => point.y >= 0), isTrue);
      expect(xDensity[120].metadata?['sampleCount'], 3);

      var area = 0.0;
      for (var index = 1; index < xDensity.length; index++) {
        final left = xDensity[index - 1];
        final right = xDensity[index];
        area += (right.x - left.x) * (left.y + right.y) / 2;
      }
      expect(area, closeTo(1, 0.02));

      final invertedY = data.yDensityPoints(resolution: 41, invertDomain: true);
      expect(invertedY.first.x, -40);
      expect(invertedY.last.x, 0);
      expect(
        invertedY.map((point) => point.x),
        orderedEquals(invertedY.map((point) => point.x).toList()..sort()),
      );
    });

    test('preserves one rug identity per visible sample', () {
      final data = ScatterMarginalData(
        points: const [
          ChartDataPoint(x: 1, y: 10),
          ChartDataPoint(x: 1, y: 20),
          ChartDataPoint(x: 3, y: 30),
        ],
      );

      expect(data.xRugPoints().map((point) => point.x), [1, 1, 3]);
      expect(data.xRugPoints().every((point) => point.y == 0), isTrue);
      expect(data.yRugPoints(invertDomain: true).map((point) => point.x), [
        -30,
        -20,
        -10,
      ]);
    });

    test('validates density resolution and bandwidth', () {
      final data = ScatterMarginalData(
        points: const [ChartDataPoint(x: 1, y: 1)],
      );
      expect(() => data.xDensityPoints(resolution: 1), throwsArgumentError);
      expect(
        () => data.xDensityPoints(bandwidthMultiplier: 0),
        throwsArgumentError,
      );
    });
  });
}
