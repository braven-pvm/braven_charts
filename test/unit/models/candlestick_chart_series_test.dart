import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CandlestickChartSeries', () {
    test(
      'is immutable, typed, ordered, and uses the candlestick style hint',
      () {
        final source = [_candle(1), _candle(2)];
        final series = CandlestickChartSeries(id: 'price', points: source);
        source.add(_candle(3));

        expect(series.length, 2);
        expect(series.candles, hasLength(2));
        expect(series.style, SeriesStyle.candlestick);
        expect(series.isXOrdered, isTrue);
        expect(() => series.points.add(_candle(4)), throwsUnsupportedError);
      },
    );

    test('accepts empty and single-point series', () {
      expect(
        CandlestickChartSeries(id: 'empty', points: const []).isEmpty,
        isTrue,
      );
      expect(
        CandlestickChartSeries(id: 'single', points: [_candle(1)]).length,
        1,
      );
    });

    test('rejects duplicate and descending X with an indexed diagnostic', () {
      for (final points in [
        [_candle(1), _candle(1)],
        [_candle(2), _candle(1)],
      ]) {
        expect(
          () => CandlestickChartSeries(id: 'invalid', points: points),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.name,
              'name',
              'points[1].x',
            ),
          ),
        );
      }
    });

    test('copyWith preserves the typed invariants', () {
      final source = CandlestickChartSeries(
        id: 'price',
        points: [_candle(1)],
        densityGrouping: const CandlestickDensityGrouping(
          enabled: true,
          targetGroupWidth: 6,
          minimumPointsPerGroup: 3,
        ),
      );

      final copy = source.copyWith(id: 'copy');
      expect(copy, isA<CandlestickChartSeries>());
      expect(copy.densityGrouping, source.densityGrouping);
      expect(
        () => source.copyWith(style: SeriesStyle.line),
        throwsArgumentError,
      );
      expect(() => source.copyWith(isXOrdered: false), throwsArgumentError);
      expect(
        () => source.copyWith(points: const [ChartDataPoint(x: 1, y: 2)]),
        throwsArgumentError,
      );
    });
  });
}

CandlestickDataPoint _candle(double x) =>
    CandlestickDataPoint(x: x, open: 10, high: 13, low: 9, close: 12);
