import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/layout/chart_layout_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Range Area participates in normal Cartesian composition', () {
    final range = RangeAreaChartSeries(
      id: 'band',
      points: [RangeAreaDataPoint(x: 1, low: 8, high: 12)],
    );
    const line = LineChartSeries(
      id: 'mean',
      points: [ChartDataPoint(x: 1, y: 10)],
    );

    expect(
      ChartLayoutResolver.resolve([range, line]),
      ChartLayoutKind.cartesian,
    );
  });

  test('Range Area composes with every compatible Cartesian overlay', () {
    final range = RangeAreaChartSeries(
      id: 'band',
      points: [RangeAreaDataPoint(x: 1, low: 8, high: 12)],
    );
    final candle = CandlestickChartSeries(
      id: 'price',
      points: [
        CandlestickDataPoint(x: 1, open: 9, high: 12, low: 8, close: 11),
      ],
    );

    expect(
      ChartLayoutResolver.resolve([
        range,
        candle,
        const LineChartSeries(id: 'line', points: []),
        const AreaChartSeries(id: 'area', points: []),
        const ScatterChartSeries(id: 'scatter', points: []),
      ]),
      ChartLayoutKind.cartesian,
    );
  });

  test('rangeArea style hint requires the typed series', () {
    expect(
      () => ChartLayoutResolver.resolve(const [
        ChartSeries(
          id: 'invalid',
          points: [ChartDataPoint(x: 1, y: 10)],
          style: SeriesStyle.rangeArea,
        ),
      ]),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          'SeriesStyle.rangeArea requires a RangeAreaChartSeries',
        ),
      ),
    );
  });
}
