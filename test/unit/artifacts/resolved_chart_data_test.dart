import 'package:braven_charts/src/artifacts/resolved_chart_data.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResolvedChartData', () {
    test('keeps hidden series in full data but removes them from views', () {
      final resolved = ResolvedChartData.resolve(
        baseSeries: const [
          LineChartSeries(
            id: 'visible',
            points: [ChartDataPoint(x: 1, y: 10)],
          ),
          LineChartSeries(
            id: 'hidden',
            points: [ChartDataPoint(x: 1, y: 20)],
          ),
        ],
        hiddenSeriesIds: const {'hidden'},
        controllerSeries: const {
          'hidden': [ChartDataPoint(x: 2, y: 21)],
        },
        controllerRevision: 7,
      );

      expect(resolved.allSeries.map((series) => series.id), [
        'visible',
        'hidden',
      ]);
      expect(resolved.allSeries.last.points, hasLength(2));
      expect(resolved.visibleSeries.single.id, 'visible');
      expect(resolved.renderSeries.single.id, 'visible');
      expect(resolved.hiddenSeriesIds, {'hidden'});
      expect(resolved.controllerRevision, 7);
    });

    test('controller presence suppresses the legacy streaming merge', () {
      const base = LineChartSeries(
        id: 'power',
        points: [ChartDataPoint(x: 1, y: 100)],
      );
      const legacyPoint = ChartDataPoint(x: 2, y: 110);

      final withoutController = ResolvedChartData.resolve(
        baseSeries: const [base],
        hiddenSeriesIds: const {},
        legacyStreamingPoints: const [legacyPoint],
      );
      final withController = ResolvedChartData.resolve(
        baseSeries: const [base],
        hiddenSeriesIds: const {},
        controllerSeries: const {},
        legacyStreamingPoints: const [legacyPoint],
      );

      expect(withoutController.renderSeries.single.points, hasLength(2));
      expect(withController.renderSeries.single.points, hasLength(1));
    });

    test('adds controller-only series in stable controller order', () {
      final resolved = ResolvedChartData.resolve(
        baseSeries: const [],
        hiddenSeriesIds: const {},
        controllerSeries: const {
          'heart-rate': [ChartDataPoint(x: 1, y: 140)],
          'power': [ChartDataPoint(x: 1, y: 280)],
        },
      );

      expect(resolved.allSeries.map((series) => series.id), [
        'heart-rate',
        'power',
      ]);
      expect(resolved.renderSeries, hasLength(2));
    });

    test('preserves concrete series configuration when merging points', () {
      const area = AreaChartSeries(
        id: 'balance',
        points: [ChartDataPoint(x: 1, y: -2)],
        baselineValue: 0,
        fillOpacity: 0.45,
      );

      final resolved = ResolvedChartData.resolve(
        baseSeries: const [area],
        hiddenSeriesIds: const {},
        controllerSeries: const {
          'balance': [ChartDataPoint(x: 2, y: 3)],
        },
      );

      final merged = resolved.allSeries.single;
      expect(merged, isA<AreaChartSeries>());
      expect((merged as AreaChartSeries).baselineValue, 0);
      expect(merged.fillOpacity, 0.45);
      expect(merged.points, hasLength(2));
    });

    test('includes committed direct stream data only in document views', () {
      final resolved = ResolvedChartData.resolve(
        baseSeries: const [
          LineChartSeries(id: 'sensor', points: [ChartDataPoint(x: 1, y: 10)]),
        ],
        hiddenSeriesIds: const {},
        liveSeries: const ResolvedLiveSeriesData(
          seriesId: 'sensor',
          points: [ChartDataPoint(x: 2, y: 11)],
          committedRevision: 12,
          pendingRevision: 3,
          pendingPointCount: 4,
        ),
      );

      expect(resolved.allSeries.single.points, hasLength(2));
      expect(resolved.visibleSeries.single.points, hasLength(2));
      expect(resolved.renderSeries.single.points, hasLength(1));
      expect(resolved.committedStreamRevision, 12);
      expect(resolved.pendingStreamRevision, 3);
      expect(resolved.pendingStreamPointCount, 4);
    });

    test('exposes unmodifiable projection collections', () {
      final resolved = ResolvedChartData.resolve(
        baseSeries: const [LineChartSeries(id: 'series', points: [])],
        hiddenSeriesIds: const {},
      );

      expect(
        () => resolved.allSeries.add(
          const LineChartSeries(id: 'other', points: []),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => resolved.hiddenSeriesIds.add('series'),
        throwsUnsupportedError,
      );
    });
  });
}
