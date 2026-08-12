import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/utils/radar_series_transition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadarSeriesTransition', () {
    final from = RadarChartSeries.fromMap(
      id: 'team',
      values: const {'Discovery': 20, 'Delivery': 40, 'Quality': 60},
    );

    test('interpolates by durable category identity after reorder', () {
      final to = RadarChartSeries.fromMap(
        id: 'team',
        values: const {'Quality': 80, 'Discovery': 60, 'Delivery': 20},
      );

      final frame = RadarSeriesTransition.interpolate(
        from: from,
        to: to,
        progress: 0.5,
      );

      expect(frame.categories, ['Quality', 'Discovery', 'Delivery']);
      expect(frame.points.map((point) => point.y), [70, 40, 30]);
    });

    test('rejects topology changes instead of cross-category morphing', () {
      final changed = RadarChartSeries.fromMap(
        id: 'team',
        values: const {'Discovery': 30, 'Delivery': 50, 'Security': 70},
      );

      expect(RadarSeriesTransition.isCompatible(from, changed), isFalse);
      expect(
        () => RadarSeriesTransition.interpolate(
          from: from,
          to: changed,
          progress: 0.5,
        ),
        throwsArgumentError,
      );
    });

    test('clamps progress to the authored value domain', () {
      final to = RadarChartSeries.fromMap(
        id: 'team',
        values: const {'Discovery': 80, 'Delivery': 20, 'Quality': 40},
      );

      expect(
        RadarSeriesTransition.interpolate(
          from: from,
          to: to,
          progress: -1,
        ).points.map((point) => point.y),
        [20, 40, 60],
      );
      expect(
        RadarSeriesTransition.interpolate(
          from: from,
          to: to,
          progress: 2,
        ).points.map((point) => point.y),
        [80, 20, 40],
      );
    });
  });
}
