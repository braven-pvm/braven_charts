import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/utils/radial_series_transition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadialSeriesTransition', () {
    test('morphs stable category values and second metrics by identity', () {
      final from = PieChartSeries.fromMap(
        id: 'pie',
        values: const {'A': 20, 'B': 80},
        radiusValues: const {'A': 10, 'B': 20},
      );
      final to = PieChartSeries.fromMap(
        id: 'pie',
        values: const {'A': 40, 'B': 60},
        radiusValues: const {'A': 30, 'B': 40},
      );

      expect(RadialSeriesTransition.canMorph(from, to), isTrue);
      final halfway =
          RadialSeriesTransition.interpolate(
                from: from,
                to: to,
                progress: .5,
                effectiveOpacity: 1,
              )
              as PieChartSeries;
      expect(halfway.points.map((point) => point.y), [30, 70]);
      expect(halfway.points.map((point) => point.pointStyle?.size), [20, 30]);
    });

    test('structural changes fade without exposing moving labels', () {
      final from = DonutChartSeries.fromMap(
        id: 'donut',
        values: const {'A': 70, 'B': 30},
      );
      final to = DonutChartSeries.fromMap(
        id: 'donut',
        values: const {'B': 25, 'A': 50, 'C': 25},
      );

      expect(RadialSeriesTransition.canMorph(from, to), isFalse);
      final outgoing =
          RadialSeriesTransition.interpolate(
                from: from,
                to: to,
                progress: .25,
                effectiveOpacity: .8,
              )
              as DonutChartSeries;
      final incoming =
          RadialSeriesTransition.interpolate(
                from: from,
                to: to,
                progress: .75,
                effectiveOpacity: .8,
              )
              as DonutChartSeries;
      expect(outgoing.points.map((point) => point.label), ['A', 'B']);
      expect(outgoing.donutStyle.opacity, closeTo(.4, 1e-9));
      expect(outgoing.dataLabels.isVisible, isFalse);
      expect(incoming.points.map((point) => point.label), ['B', 'A', 'C']);
      expect(incoming.donutStyle.opacity, closeTo(.4, 1e-9));
      expect(incoming.dataLabels.isVisible, isFalse);
    });

    test('disambiguates valid duplicate labels with X and occurrence', () {
      const points = <ChartDataPoint>[
        ChartDataPoint(x: 1, y: 2, label: 'Same'),
        ChartDataPoint(x: 2, y: 3, label: 'Same'),
        ChartDataPoint(x: 2, y: 4, label: 'Same'),
      ];
      expect(RadialSeriesTransition.identityKeys(points), [
        'pair:Same\u00001.0',
        'pair:Same\u00002.0\u00000',
        'pair:Same\u00002.0\u00001',
      ]);
    });
  });
}
