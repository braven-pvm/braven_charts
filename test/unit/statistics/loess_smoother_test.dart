import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/statistics/loess_smoother.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoessSmoother', () {
    test('reproduces a fixed linear reference dataset', () {
      const smoother = LoessSmoother(
        span: 0.65,
        robustnessIterations: 2,
        sampleCount: 9,
      );
      const points = [
        ChartDataPoint(x: 4, y: 9),
        ChartDataPoint(x: 0, y: 1),
        ChartDataPoint(x: 3, y: 7),
        ChartDataPoint(x: 1, y: 3),
        ChartDataPoint(x: 2, y: 5),
        ChartDataPoint(x: double.nan, y: 99),
      ];

      final result = smoother.smooth(points);

      expect(result, hasLength(9));
      expect(result.first.x, 0);
      expect(result.last.x, 4);
      for (final point in result) {
        expect(point.y, closeTo(2 * point.x + 1, 1e-9));
      }
    });

    test('robust iterations suppress an isolated outlier', () {
      final points = [
        for (var x = 0; x <= 10; x++)
          ChartDataPoint(x: x.toDouble(), y: x == 5 ? 100 : x.toDouble()),
      ];
      const ordinary = LoessSmoother(
        span: 0.8,
        robustnessIterations: 0,
        sampleCount: 11,
      );
      const robust = LoessSmoother(
        span: 0.8,
        robustnessIterations: 2,
        sampleCount: 11,
      );

      final ordinaryAtFive = ordinary.smooth(points)[5].y;
      final robustAtFive = robust.smooth(points)[5].y;

      expect((robustAtFive - 5).abs(), lessThan((ordinaryAtFive - 5).abs()));
      expect(robustAtFive, closeTo(5, 0.2));
    });

    test('handles duplicate X values and rejects a vertical-only domain', () {
      const smoother = LoessSmoother(sampleCount: 7);

      final duplicateResult = smoother.smooth(const [
        ChartDataPoint(x: 0, y: 1),
        ChartDataPoint(x: 0, y: 2),
        ChartDataPoint(x: 1, y: 3),
        ChartDataPoint(x: 2, y: 5),
      ]);
      final verticalResult = smoother.smooth(const [
        ChartDataPoint(x: 2, y: 1),
        ChartDataPoint(x: 2, y: 4),
        ChartDataPoint(x: 2, y: 8),
      ]);

      expect(duplicateResult, hasLength(7));
      expect(duplicateResult.every((point) => point.y.isFinite), isTrue);
      expect(verticalResult, isEmpty);
    });
  });
}
